extends Node
class_name SaveLoad
## Handles saving and loading game state to/from JSON files.

signal game_saved(filepath: String, slot: int)
signal game_loaded(filepath: String, slot: int)
signal save_failed(error: String)
signal load_failed(error: String)

const SAVE_DIR: String = "user://saves/"
const SAVE_FILE: String = "save.json"  # Legacy single save file (backward compatibility)
const SAVE_VERSION: int = 1
const NUM_SLOTS: int = 3

# Node references (set in _ready or via exported paths)
@export var player_path: NodePath
@export var time_manager_path: NodePath
@export var weather_manager_path: NodePath
@export var campsite_manager_path: NodePath
@export var resource_manager_path: NodePath
@export var crafting_system_path: NodePath
@export var chunk_manager_path: NodePath

var player: Node
var time_manager: Node
var weather_manager: Node
var campsite_manager: Node
var resource_manager: Node
var crafting_system: Node
var chunk_manager: Node


func _ready() -> void:
	# Ensure SaveLoad works even if the game is paused (e.g., during scene reload)
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Get references (some may need deferred lookup)
	if player_path:
		player = get_node_or_null(player_path)
	if time_manager_path:
		time_manager = get_node_or_null(time_manager_path)
	if weather_manager_path:
		weather_manager = get_node_or_null(weather_manager_path)
	if campsite_manager_path:
		campsite_manager = get_node_or_null(campsite_manager_path)
	if resource_manager_path:
		resource_manager = get_node_or_null(resource_manager_path)
	if chunk_manager_path:
		chunk_manager = get_node_or_null(chunk_manager_path)

	# Log if any critical references are missing
	if not player:
		push_warning("[SaveLoad] Player reference not found!")
	if not chunk_manager:
		push_warning("[SaveLoad] ChunkManager reference not found!")

	# CraftingSystem is created dynamically by CraftingUI, so defer lookup
	call_deferred("_get_crafting_system")

	# Ensure save directory exists
	_ensure_save_directory()

	# Check for pending load after scene reload (world seed was changed)
	call_deferred("_check_pending_load")


func _get_crafting_system() -> void:
	if crafting_system_path:
		var crafting_ui: Node = get_node_or_null(crafting_system_path)
		if crafting_ui and "crafting_system" in crafting_ui:
			crafting_system = crafting_ui.crafting_system


func _check_pending_load() -> void:
	# Check if there's a pending save to load (after scene reload for world seed change)
	var game_state: Node = get_node_or_null("/root/GameState")
	if not game_state:
		push_warning("[SaveLoad] GameState autoload not found!")
		return

	var pending_slot: int = game_state.consume_pending_load_slot()
	if pending_slot > 0:
		print("[SaveLoad] Loading pending save from slot %d after scene reload" % pending_slot)

		# Wait for terrain to be ready (chunk_manager needs time to initialize)
		# Wait multiple frames to ensure all nodes are ready
		for i: int in range(3):
			await get_tree().process_frame

		# Re-acquire references in case they weren't available initially
		if not player and player_path:
			player = get_node_or_null(player_path)
		if not chunk_manager and chunk_manager_path:
			chunk_manager = get_node_or_null(chunk_manager_path)

		if not player:
			push_error("[SaveLoad] Cannot load: Player reference not found!")
			load_failed.emit("Player not found")
			return

		print("[SaveLoad] References after wait - Player: %s, ChunkManager: %s" % [player != null, chunk_manager != null])
		load_game_slot(pending_slot)


func _ensure_save_directory() -> void:
	var dir: DirAccess = DirAccess.open("user://")
	if dir and not dir.dir_exists("saves"):
		dir.make_dir("saves")


## Get the filename for a given slot (1-indexed).
func _get_slot_filename(slot: int) -> String:
	return "save_slot_%d.json" % slot


## Save the current game state (backward compatibility wrapper for slot 1).
func save_game() -> bool:
	return save_game_slot(1)


## Save the current game state to a specific slot.
func save_game_slot(slot: int) -> bool:
	if slot < 1 or slot > NUM_SLOTS:
		var error: String = "Invalid slot number: %d" % slot
		push_error(error)
		save_failed.emit(error)
		return false

	var save_data: Dictionary = _collect_save_data()

	var filepath: String = SAVE_DIR + _get_slot_filename(slot)
	var file: FileAccess = FileAccess.open(filepath, FileAccess.WRITE)

	if not file:
		var error: String = "Failed to open save file: %s" % filepath
		push_error(error)
		save_failed.emit(error)
		return false

	var json_string: String = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()

	print("[SaveLoad] Game saved to %s (slot %d)" % [filepath, slot])
	game_saved.emit(filepath, slot)
	return true


## Load the game state from file (backward compatibility wrapper for slot 1).
func load_game() -> bool:
	return load_game_slot(1)


## Load the game state from a specific slot.
func load_game_slot(slot: int) -> bool:
	if slot < 1 or slot > NUM_SLOTS:
		var error: String = "Invalid slot number: %d" % slot
		push_error(error)
		load_failed.emit(error)
		return false

	var filepath: String = SAVE_DIR + _get_slot_filename(slot)

	if not FileAccess.file_exists(filepath):
		var error: String = "No save file found in slot %d" % slot
		push_warning(error)
		load_failed.emit(error)
		return false

	var file: FileAccess = FileAccess.open(filepath, FileAccess.READ)
	if not file:
		var error: String = "Failed to open save file: %s" % filepath
		push_error(error)
		load_failed.emit(error)
		return false

	var json_string: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var parse_result: int = json.parse(json_string)

	if parse_result != OK:
		var error: String = "Failed to parse save file: %s" % json.get_error_message()
		push_error(error)
		load_failed.emit(error)
		return false

	var save_data: Dictionary = json.data

	# Verify save version
	var version: int = save_data.get("version", 0)
	if version != SAVE_VERSION:
		push_warning("[SaveLoad] Save version mismatch (expected %d, got %d)" % [SAVE_VERSION, version])

	# Check if world seed matches - if not, we need to reload the scene with correct seed
	var saved_seed: int = save_data.get("world_seed", 0)
	var current_seed: int = 0
	if chunk_manager and chunk_manager.has_method("get_world_seed"):
		current_seed = chunk_manager.get_world_seed()

	if saved_seed != 0 and saved_seed != current_seed:
		print("[SaveLoad] World seed mismatch (saved: %d, current: %d) - reloading scene" % [saved_seed, current_seed])
		var game_state: Node = get_node_or_null("/root/GameState")
		if game_state:
			game_state.set_pending_world_seed(saved_seed)
			game_state.set_pending_load_slot(slot)
			# Reload the main scene - terrain will regenerate with correct seed
			get_tree().reload_current_scene()
			return true

	_apply_save_data(save_data)

	# Ensure game is unpaused after loading (in case we loaded from pause menu)
	get_tree().paused = false

	print("[SaveLoad] Game loaded from %s (slot %d)" % [filepath, slot])
	game_loaded.emit(filepath, slot)
	return true


## Check if a save file exists (backward compatibility for slot 1).
func has_save_file() -> bool:
	return has_save_slot(1)


## Check if a specific slot has a save file.
func has_save_slot(slot: int) -> bool:
	if slot < 1 or slot > NUM_SLOTS:
		return false
	return FileAccess.file_exists(SAVE_DIR + _get_slot_filename(slot))


## Delete the save file (backward compatibility for slot 1).
func delete_save() -> bool:
	return delete_save_slot(1)


## Delete a specific save slot.
func delete_save_slot(slot: int) -> bool:
	if slot < 1 or slot > NUM_SLOTS:
		return false
	var filename: String = _get_slot_filename(slot)
	var filepath: String = SAVE_DIR + filename
	if FileAccess.file_exists(filepath):
		var dir: DirAccess = DirAccess.open(SAVE_DIR)
		if dir:
			dir.remove(filename)
			print("[SaveLoad] Save slot %d deleted" % slot)
			return true
	return false


## Get metadata about a specific save slot.
## Returns Dictionary with: empty, timestamp, campsite_level, formatted_time
func get_slot_info(slot: int) -> Dictionary:
	if slot < 1 or slot > NUM_SLOTS:
		return {"empty": true, "slot": slot}

	var filepath: String = SAVE_DIR + _get_slot_filename(slot)

	if not FileAccess.file_exists(filepath):
		return {"empty": true, "slot": slot}

	var file: FileAccess = FileAccess.open(filepath, FileAccess.READ)
	if not file:
		return {"empty": true, "slot": slot}

	var json_string: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	if json.parse(json_string) != OK:
		return {"empty": true, "slot": slot}

	var save_data: Dictionary = json.data

	# Extract useful metadata
	var campsite_level: int = 1
	if save_data.has("campsite") and save_data["campsite"].has("level"):
		campsite_level = int(save_data["campsite"]["level"])

	var timestamp: String = save_data.get("timestamp", "")
	var formatted_time: String = _format_timestamp(timestamp)

	return {
		"empty": false,
		"slot": slot,
		"timestamp": timestamp,
		"campsite_level": campsite_level,
		"formatted_time": formatted_time
	}


## Get info for all save slots.
func get_all_slots_info() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	for i: int in range(1, NUM_SLOTS + 1):
		slots.append(get_slot_info(i))
	return slots


## Format a timestamp string for display.
func _format_timestamp(timestamp: String) -> String:
	if timestamp.is_empty():
		return "Unknown"

	# Timestamp format: "YYYY-MM-DDTHH:MM:SS"
	var parts: PackedStringArray = timestamp.split("T")
	if parts.size() < 2:
		return timestamp

	var date_parts: PackedStringArray = parts[0].split("-")
	var time_parts: PackedStringArray = parts[1].split(":")

	if date_parts.size() < 3 or time_parts.size() < 2:
		return timestamp

	var month_names: Array[String] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	var month_idx: int = int(date_parts[1]) - 1
	if month_idx < 0 or month_idx >= 12:
		month_idx = 0

	var day: int = int(date_parts[2])
	var hour: int = int(time_parts[0])
	var minute: int = int(time_parts[1])

	var period: String = "AM"
	var display_hour: int = hour
	if hour >= 12:
		period = "PM"
		if hour > 12:
			display_hour = hour - 12
	elif hour == 0:
		display_hour = 12

	return "%s %d, %d:%02d %s" % [month_names[month_idx], day, display_hour, minute, period]


## Collect all game data into a dictionary for saving.
func _collect_save_data() -> Dictionary:
	var data: Dictionary = {
		"version": SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system()
	}

	# Player data
	if player:
		data["player"] = _collect_player_data()

	# Time data
	if time_manager:
		data["time"] = _collect_time_data()

	# Weather data
	if weather_manager:
		data["weather"] = _collect_weather_data()

	# Campsite data
	if campsite_manager:
		data["campsite"] = _collect_campsite_data()

	# Resource data
	if resource_manager:
		data["resources"] = _collect_resource_data()

	# Crafting data
	if crafting_system:
		data["crafting"] = _collect_crafting_data()

	# World seed (critical for consistent terrain generation on load)
	if chunk_manager and chunk_manager.has_method("get_world_seed"):
		data["world_seed"] = chunk_manager.get_world_seed()
		print("[SaveLoad] Saved world seed: %d" % data["world_seed"])

	return data


func _collect_player_data() -> Dictionary:
	var data: Dictionary = {
		"position": {
			"x": player.global_position.x,
			"y": player.global_position.y,
			"z": player.global_position.z
		}
	}

	# Player stats
	var stats: Node = player.get_node_or_null("PlayerStats")
	if stats:
		data["health"] = stats.health
		data["hunger"] = stats.hunger

	# Inventory
	var inventory: Node = player.get_node_or_null("Inventory")
	if inventory:
		data["inventory"] = inventory.get_all_items()

	# Equipment
	var equipment: Node = player.get_node_or_null("Equipment")
	if equipment:
		if "equipped_item" in equipment:
			data["equipped_item"] = equipment.equipped_item
		# Save tool durability
		if equipment.has_method("get_durability_data"):
			data["tool_durability"] = equipment.get_durability_data()

	return data


func _collect_time_data() -> Dictionary:
	return {
		"hour": time_manager.current_hour,
		"minute": time_manager.current_minute
	}


func _collect_weather_data() -> Dictionary:
	return {
		"weather_type": weather_manager.current_weather,
		"duration_remaining": weather_manager.weather_duration_remaining
	}


func _collect_campsite_data() -> Dictionary:
	var data: Dictionary = {
		"level": campsite_manager.campsite_level,
		"has_crafted_tool": campsite_manager.has_crafted_tool,
		"has_crafted_fishing_rod": campsite_manager.has_crafted_fishing_rod,
		"days_at_level_2": campsite_manager.days_at_level_2,
		"level_2_start_day": campsite_manager.level_2_start_day,
		"structures": []
	}

	# Collect placed structures
	for structure: Node in campsite_manager.placed_structures:
		if is_instance_valid(structure):
			var struct_data: Dictionary = {
				"type": structure.structure_type if "structure_type" in structure else "unknown",
				"position": {
					"x": structure.global_position.x,
					"y": structure.global_position.y,
					"z": structure.global_position.z
				}
			}

			# Save fire state if it's a fire pit
			if structure.has_method("is_lit"):
				struct_data["is_lit"] = structure.is_lit

			data["structures"].append(struct_data)

	return data


func _collect_resource_data() -> Dictionary:
	return {
		"depleted": resource_manager.get_depleted_data()
	}


func _collect_crafting_data() -> Dictionary:
	return {
		"discovered_recipes": crafting_system.discovered_recipes.duplicate()
	}


## Apply loaded data to the game.
func _apply_save_data(data: Dictionary) -> void:
	print("[SaveLoad] Applying save data...")
	print("[SaveLoad] References: player=%s time_manager=%s weather_manager=%s campsite_manager=%s chunk_manager=%s" % [
		player != null, time_manager != null, weather_manager != null, campsite_manager != null, chunk_manager != null
	])

	# Apply in reverse order of dependencies

	# Time first (weather depends on it)
	if data.has("time") and time_manager:
		print("[SaveLoad] Applying time data...")
		_apply_time_data(data["time"])
	elif data.has("time"):
		push_warning("[SaveLoad] Skipping time data - time_manager is null")

	# Weather
	if data.has("weather") and weather_manager:
		print("[SaveLoad] Applying weather data...")
		_apply_weather_data(data["weather"])
	elif data.has("weather"):
		push_warning("[SaveLoad] Skipping weather data - weather_manager is null")

	# Resources (before player loads in)
	if data.has("resources") and resource_manager:
		print("[SaveLoad] Applying resource data...")
		_apply_resource_data(data["resources"])

	# Crafting
	if data.has("crafting") and crafting_system:
		print("[SaveLoad] Applying crafting data...")
		_apply_crafting_data(data["crafting"])

	# Campsite (structures)
	if data.has("campsite") and campsite_manager:
		print("[SaveLoad] Applying campsite data...")
		_apply_campsite_data(data["campsite"])
	elif data.has("campsite"):
		push_warning("[SaveLoad] Skipping campsite data - campsite_manager is null")

	# Player last (position, stats, inventory)
	if data.has("player") and player:
		_apply_player_data(data["player"])
	elif data.has("player"):
		push_error("[SaveLoad] Cannot apply player data - player is null!")

	# Post-load: Verify crafting flags based on inventory (for backward compatibility)
	_verify_crafting_flags_from_inventory()

	# Re-check campsite level progression in case flags were updated
	if campsite_manager and campsite_manager.has_method("_check_level_progression"):
		campsite_manager._check_level_progression()


## Verify crafting flags based on player inventory (for backward compatibility with old saves).
func _verify_crafting_flags_from_inventory() -> void:
	if not player or not campsite_manager:
		return

	var inventory: Node = player.get_node_or_null("Inventory")
	if not inventory:
		return

	# If player has fishing rod in inventory, they must have crafted it
	if not campsite_manager.has_crafted_fishing_rod:
		if inventory.has_method("has_item") and inventory.has_item("Fishing Rod"):
			campsite_manager.has_crafted_fishing_rod = true
			print("[SaveLoad] Set has_crafted_fishing_rod from inventory")
		elif inventory.has_method("get_all_items"):
			var items: Dictionary = inventory.get_all_items()
			if items.has("Fishing Rod") and items["Fishing Rod"] > 0:
				campsite_manager.has_crafted_fishing_rod = true
				print("[SaveLoad] Set has_crafted_fishing_rod from inventory")

	# If player has stone axe in inventory, they must have crafted it
	if not campsite_manager.has_crafted_tool:
		if inventory.has_method("has_item") and inventory.has_item("Stone Axe"):
			campsite_manager.has_crafted_tool = true
			print("[SaveLoad] Set has_crafted_tool from inventory")
		elif inventory.has_method("get_all_items"):
			var items: Dictionary = inventory.get_all_items()
			if items.has("Stone Axe") and items["Stone Axe"] > 0:
				campsite_manager.has_crafted_tool = true
				print("[SaveLoad] Set has_crafted_tool from inventory")


func _apply_player_data(data: Dictionary) -> void:
	if not player:
		push_error("[SaveLoad] Cannot apply player data: player is null!")
		return

	print("[SaveLoad] Applying player data...")

	# Position
	if data.has("position"):
		var pos: Dictionary = data["position"]
		var load_x: float = pos["x"]
		var load_z: float = pos["z"]

		# Calculate correct Y position based on terrain height
		# This prevents spawning below terrain when loading
		var terrain_y: float = 0.0
		if chunk_manager and chunk_manager.has_method("get_height_at"):
			terrain_y = chunk_manager.get_height_at(load_x, load_z)

		# Player height offset (spawn slightly above terrain)
		var player_height_offset: float = 2.0
		var final_y: float = terrain_y + player_height_offset

		player.global_position = Vector3(load_x, final_y, load_z)
		print("[SaveLoad] Player positioned at (%.1f, %.1f, %.1f) - terrain height: %.1f" % [load_x, final_y, load_z, terrain_y])

	# Stats
	var stats: Node = player.get_node_or_null("PlayerStats")
	if stats:
		if data.has("health"):
			stats.health = data["health"]
			stats.health_changed.emit(stats.health, stats.max_health)
		if data.has("hunger"):
			stats.hunger = data["hunger"]
			stats.hunger_changed.emit(stats.hunger, stats.max_hunger)

	# Inventory
	var inventory: Node = player.get_node_or_null("Inventory")
	if inventory and data.has("inventory"):
		inventory.clear()
		var items: Dictionary = data["inventory"]
		for item_type: String in items:
			inventory.add_item(item_type, int(items[item_type]))

	# Equipment
	var equipment: Node = player.get_node_or_null("Equipment")
	if equipment:
		# Load tool durability first
		if data.has("tool_durability") and equipment.has_method("load_durability_data"):
			equipment.load_durability_data(data["tool_durability"])
		# Then equip item
		if data.has("equipped_item"):
			var item: String = data["equipped_item"]
			if item != "" and equipment.has_method("equip"):
				equipment.equip(item)


func _apply_time_data(data: Dictionary) -> void:
	time_manager.current_hour = int(data.get("hour", 8))
	time_manager.current_minute = int(data.get("minute", 0))
	time_manager._update_period()


func _apply_weather_data(data: Dictionary) -> void:
	var weather_type: int = int(data.get("weather_type", 0))
	weather_manager.current_weather = weather_type
	weather_manager.weather_duration_remaining = data.get("duration_remaining", 0.0)

	# Update visuals
	if weather_manager.environment_manager:
		weather_manager.environment_manager.set_weather_overlay(weather_manager.get_weather_name())


func _apply_resource_data(data: Dictionary) -> void:
	if data.has("depleted"):
		resource_manager.load_depleted_data(data["depleted"])


func _apply_crafting_data(data: Dictionary) -> void:
	if data.has("discovered_recipes"):
		crafting_system.discovered_recipes.clear()
		for recipe: String in data["discovered_recipes"]:
			crafting_system.discovered_recipes.append(recipe)
		# Also add any new recipes that weren't in the save file
		# This ensures new recipes are available after game updates
		for recipe_id: String in crafting_system.recipes:
			if recipe_id not in crafting_system.discovered_recipes:
				crafting_system.discovered_recipes.append(recipe_id)


func _apply_campsite_data(data: Dictionary) -> void:
	# Set flags
	campsite_manager.campsite_level = int(data.get("level", 1))
	campsite_manager.has_crafted_tool = data.get("has_crafted_tool", false)
	campsite_manager.has_crafted_fishing_rod = data.get("has_crafted_fishing_rod", false)
	campsite_manager.days_at_level_2 = int(data.get("days_at_level_2", 0))
	campsite_manager.level_2_start_day = int(data.get("level_2_start_day", -1))

	# Clear existing structures first
	var structures_container: Node = get_parent().get_node_or_null("Structures")
	if structures_container:
		for child in structures_container.get_children():
			child.queue_free()

	campsite_manager.placed_structures.clear()
	campsite_manager.structure_counts.clear()

	# Wait a frame for cleanup
	await get_tree().process_frame

	# Recreate structures
	if data.has("structures"):
		for struct_data: Dictionary in data["structures"]:
			_recreate_structure(struct_data, structures_container)

	# Remove any trees that spawned on top of the loaded structures
	# (trees spawn during terrain generation before structures are loaded)
	if chunk_manager and chunk_manager.has_method("remove_trees_overlapping_structures"):
		chunk_manager.remove_trees_overlapping_structures()

	# NOTE: We intentionally do NOT emit campsite_level_changed here
	# to avoid showing the level-up celebration when loading a saved game.
	# The HUD will update its display when it receives game_loaded signal.


func _recreate_structure(struct_data: Dictionary, container: Node) -> void:
	var structure_type: String = struct_data.get("type", "")
	var pos_data: Dictionary = struct_data.get("position", {})
	var pos: Vector3 = Vector3(
		pos_data.get("x", 0),
		pos_data.get("y", 0),
		pos_data.get("z", 0)
	)

	# Get scene path from StructureData
	var scene_path: String = StructureData.get_scene_path(structure_type)
	var structure: Node3D = null

	# Try loading from scene file first
	if not scene_path.is_empty() and ResourceLoader.exists(scene_path):
		var scene: PackedScene = load(scene_path)
		if scene:
			structure = scene.instantiate()

	# Fallback to programmatic creation if scene doesn't exist
	if not structure:
		structure = _create_structure_programmatically(structure_type)

	if not structure:
		push_warning("[SaveLoad] Failed to recreate structure: %s" % structure_type)
		return
	structure.global_position = pos

	if container:
		container.add_child(structure)

	# Register with campsite manager
	campsite_manager.register_structure(structure, structure_type)

	# Restore state
	if struct_data.has("is_lit") and structure.has_method("_set_fire_state"):
		structure._set_fire_state(struct_data["is_lit"])

	print("[SaveLoad] Recreated structure: %s at %s" % [structure_type, pos])


## Create structure programmatically when scene file doesn't exist.
func _create_structure_programmatically(structure_type: String) -> Node3D:
	match structure_type:
		"fire_pit":
			return _create_fire_pit()
		"basic_shelter":
			return _create_basic_shelter()
		"storage_container":
			return _create_storage_container()
		"crafting_bench":
			return _create_crafting_bench()
		"drying_rack":
			return _create_drying_rack()
		"herb_garden":
			return _create_herb_garden()
		"canvas_tent":
			return _create_canvas_tent()
		"cabin":
			return _create_cabin()
	return null


func _create_fire_pit() -> StaticBody3D:
	var fire_pit: StaticBody3D = StaticBody3D.new()
	fire_pit.name = "FirePit"
	fire_pit.set_script(load("res://scripts/campsite/structure_fire_pit.gd"))

	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(1.2, 0.4, 1.2)
	collision.shape = box_shape
	collision.position.y = 0.2
	fire_pit.add_child(collision)

	var rocks: MeshInstance3D = MeshInstance3D.new()
	var rocks_box: BoxMesh = BoxMesh.new()
	rocks_box.size = Vector3(1.2, 0.3, 1.2)
	rocks.mesh = rocks_box
	rocks.position.y = 0.15
	var rock_mat: StandardMaterial3D = StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.4, 0.4, 0.4)
	rocks.material_override = rock_mat
	fire_pit.add_child(rocks)

	var fire_mesh: MeshInstance3D = MeshInstance3D.new()
	fire_mesh.name = "FireMesh"
	var fire_box: BoxMesh = BoxMesh.new()
	fire_box.size = Vector3(0.5, 0.7, 0.5)
	fire_mesh.mesh = fire_box
	fire_mesh.position.y = 0.5
	var fire_mat: StandardMaterial3D = StandardMaterial3D.new()
	fire_mat.albedo_color = Color(1.0, 0.5, 0.1)
	fire_mat.emission_enabled = true
	fire_mat.emission = Color(1.0, 0.4, 0.0)
	fire_mat.emission_energy_multiplier = 2.0
	fire_mesh.material_override = fire_mat
	fire_pit.add_child(fire_mesh)

	var light: OmniLight3D = OmniLight3D.new()
	light.name = "FireLight"
	light.light_color = Color(1.0, 0.6, 0.2)
	light.light_energy = 3.0
	light.omni_range = 8.0
	light.position.y = 0.5
	fire_pit.add_child(light)

	return fire_pit


func _create_basic_shelter() -> StaticBody3D:
	var shelter: StaticBody3D = StaticBody3D.new()
	shelter.name = "BasicShelter"
	shelter.set_script(load("res://scripts/campsite/structure_shelter.gd"))

	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(2.0, 1.5, 2.0)
	collision.shape = box_shape
	collision.position.y = 0.75
	shelter.add_child(collision)

	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.55, 0.35, 0.2)

	var cover: MeshInstance3D = MeshInstance3D.new()
	var cover_mesh: BoxMesh = BoxMesh.new()
	cover_mesh.size = Vector3(2.4, 0.05, 2.2)
	cover.mesh = cover_mesh
	cover.position = Vector3(0, 0.9, 0)
	cover.rotation.x = 0.5
	var canvas_mat: StandardMaterial3D = StandardMaterial3D.new()
	canvas_mat.albedo_color = Color(0.6, 0.55, 0.4)
	cover.material_override = canvas_mat
	shelter.add_child(cover)

	var frame_mesh: BoxMesh = BoxMesh.new()
	frame_mesh.size = Vector3(2.5, 0.1, 0.1)

	var frame_back: MeshInstance3D = MeshInstance3D.new()
	frame_back.mesh = frame_mesh
	frame_back.position = Vector3(0, 1.5, -0.8)
	frame_back.material_override = wood_mat
	shelter.add_child(frame_back)

	var frame_front: MeshInstance3D = MeshInstance3D.new()
	frame_front.mesh = frame_mesh
	frame_front.position = Vector3(0, 0.15, 1.0)
	frame_front.material_override = wood_mat
	shelter.add_child(frame_front)

	var pole_mesh: BoxMesh = BoxMesh.new()
	pole_mesh.size = Vector3(0.1, 1.5, 0.1)

	var pole_left: MeshInstance3D = MeshInstance3D.new()
	pole_left.mesh = pole_mesh
	pole_left.position = Vector3(-1.1, 0.75, -0.8)
	pole_left.material_override = wood_mat
	shelter.add_child(pole_left)

	var pole_right: MeshInstance3D = MeshInstance3D.new()
	pole_right.mesh = pole_mesh
	pole_right.position = Vector3(1.1, 0.75, -0.8)
	pole_right.material_override = wood_mat
	shelter.add_child(pole_right)

	var area: Area3D = Area3D.new()
	area.name = "ProtectionArea"
	var area_collision: CollisionShape3D = CollisionShape3D.new()
	var box_area: BoxShape3D = BoxShape3D.new()
	box_area.size = Vector3(4.0, 3.0, 4.0)
	area_collision.shape = box_area
	area_collision.position.y = 1.0
	area.add_child(area_collision)
	shelter.add_child(area)

	return shelter


func _create_storage_container() -> StaticBody3D:
	var storage: StaticBody3D = StaticBody3D.new()
	storage.name = "StorageContainer"
	storage.set_script(load("res://scripts/campsite/structure_storage.gd"))

	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(1.0, 0.6, 0.6)
	collision.shape = box_shape
	collision.position.y = 0.3
	storage.add_child(collision)

	var box_inst: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = Vector3(1.0, 0.6, 0.6)
	box_inst.mesh = box_mesh
	box_inst.position.y = 0.3
	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.6, 0.4, 0.25)
	box_inst.material_override = wood_mat
	storage.add_child(box_inst)

	var lid: MeshInstance3D = MeshInstance3D.new()
	var lid_mesh: BoxMesh = BoxMesh.new()
	lid_mesh.size = Vector3(1.02, 0.08, 0.62)
	lid.mesh = lid_mesh
	lid.position.y = 0.64
	var lid_mat: StandardMaterial3D = StandardMaterial3D.new()
	lid_mat.albedo_color = Color(0.5, 0.35, 0.2)
	lid.material_override = lid_mat
	storage.add_child(lid)

	return storage


func _create_crafting_bench() -> StaticBody3D:
	var bench: StaticBody3D = StaticBody3D.new()
	bench.name = "CraftingBench"
	bench.set_script(load("res://scripts/campsite/structure_crafting_bench.gd"))

	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(1.2, 0.8, 0.8)
	collision.shape = box_shape
	collision.position.y = 0.4
	bench.add_child(collision)

	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.5, 0.35, 0.2)

	var leg_mat: StandardMaterial3D = StandardMaterial3D.new()
	leg_mat.albedo_color = Color(0.4, 0.28, 0.15)

	var top: MeshInstance3D = MeshInstance3D.new()
	var top_mesh: BoxMesh = BoxMesh.new()
	top_mesh.size = Vector3(1.2, 0.1, 0.8)
	top.mesh = top_mesh
	top.position.y = 0.75
	top.material_override = wood_mat
	bench.add_child(top)

	var leg_mesh: BoxMesh = BoxMesh.new()
	leg_mesh.size = Vector3(0.1, 0.65, 0.1)

	var leg1: MeshInstance3D = MeshInstance3D.new()
	leg1.mesh = leg_mesh
	leg1.position = Vector3(-0.5, 0.325, -0.3)
	leg1.material_override = leg_mat
	bench.add_child(leg1)

	var leg2: MeshInstance3D = MeshInstance3D.new()
	leg2.mesh = leg_mesh
	leg2.position = Vector3(0.5, 0.325, -0.3)
	leg2.material_override = leg_mat
	bench.add_child(leg2)

	var leg3: MeshInstance3D = MeshInstance3D.new()
	leg3.mesh = leg_mesh
	leg3.position = Vector3(-0.5, 0.325, 0.3)
	leg3.material_override = leg_mat
	bench.add_child(leg3)

	var leg4: MeshInstance3D = MeshInstance3D.new()
	leg4.mesh = leg_mesh
	leg4.position = Vector3(0.5, 0.325, 0.3)
	leg4.material_override = leg_mat
	bench.add_child(leg4)

	return bench


func _create_drying_rack() -> StaticBody3D:
	var rack: StaticBody3D = StaticBody3D.new()
	rack.name = "DryingRack"
	rack.set_script(load("res://scripts/campsite/structure_drying_rack.gd"))

	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.5, 0.35, 0.2)

	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(1.5, 1.2, 0.4)
	collision.shape = box_shape
	collision.position.y = 0.6
	rack.add_child(collision)

	var post_mesh: BoxMesh = BoxMesh.new()
	post_mesh.size = Vector3(0.1, 1.2, 0.1)

	var post_left: MeshInstance3D = MeshInstance3D.new()
	post_left.mesh = post_mesh
	post_left.position = Vector3(-0.6, 0.6, 0)
	post_left.material_override = wood_mat
	rack.add_child(post_left)

	var post_right: MeshInstance3D = MeshInstance3D.new()
	post_right.mesh = post_mesh
	post_right.position = Vector3(0.6, 0.6, 0)
	post_right.material_override = wood_mat
	rack.add_child(post_right)

	var bar_mesh: BoxMesh = BoxMesh.new()
	bar_mesh.size = Vector3(1.2, 0.06, 0.06)

	for i: int in range(3):
		var bar: MeshInstance3D = MeshInstance3D.new()
		bar.mesh = bar_mesh
		bar.position = Vector3(0, 0.4 + i * 0.35, 0)
		bar.material_override = wood_mat
		rack.add_child(bar)

	return rack


func _create_herb_garden() -> StaticBody3D:
	var garden: StaticBody3D = StaticBody3D.new()
	garden.name = "HerbGarden"
	garden.set_script(load("res://scripts/campsite/structure_garden.gd"))

	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.5, 0.35, 0.2)

	var dirt_mat: StandardMaterial3D = StandardMaterial3D.new()
	dirt_mat.albedo_color = Color(0.4, 0.28, 0.18)

	var plant_mat: StandardMaterial3D = StandardMaterial3D.new()
	plant_mat.albedo_color = Color(0.25, 0.55, 0.2)

	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(2.0, 0.4, 1.5)
	collision.shape = box_shape
	collision.position.y = 0.2
	garden.add_child(collision)

	var border_mesh: BoxMesh = BoxMesh.new()
	border_mesh.size = Vector3(2.0, 0.3, 0.1)

	var border_front: MeshInstance3D = MeshInstance3D.new()
	border_front.mesh = border_mesh
	border_front.position = Vector3(0, 0.15, 0.7)
	border_front.material_override = wood_mat
	garden.add_child(border_front)

	var border_back: MeshInstance3D = MeshInstance3D.new()
	border_back.mesh = border_mesh
	border_back.position = Vector3(0, 0.15, -0.7)
	border_back.material_override = wood_mat
	garden.add_child(border_back)

	var side_mesh: BoxMesh = BoxMesh.new()
	side_mesh.size = Vector3(0.1, 0.3, 1.5)

	var border_left: MeshInstance3D = MeshInstance3D.new()
	border_left.mesh = side_mesh
	border_left.position = Vector3(-0.95, 0.15, 0)
	border_left.material_override = wood_mat
	garden.add_child(border_left)

	var border_right: MeshInstance3D = MeshInstance3D.new()
	border_right.mesh = side_mesh
	border_right.position = Vector3(0.95, 0.15, 0)
	border_right.material_override = wood_mat
	garden.add_child(border_right)

	var dirt: MeshInstance3D = MeshInstance3D.new()
	var dirt_mesh: BoxMesh = BoxMesh.new()
	dirt_mesh.size = Vector3(1.8, 0.2, 1.3)
	dirt.mesh = dirt_mesh
	dirt.position.y = 0.1
	dirt.material_override = dirt_mat
	garden.add_child(dirt)

	var plant_mesh: BoxMesh = BoxMesh.new()
	plant_mesh.size = Vector3(0.25, 0.3, 0.25)

	for row: int in range(2):
		for col: int in range(4):
			var plant: MeshInstance3D = MeshInstance3D.new()
			plant.mesh = plant_mesh
			plant.position = Vector3(-0.6 + col * 0.4, 0.35, -0.3 + row * 0.6)
			plant.material_override = plant_mat
			garden.add_child(plant)

	return garden


func _create_canvas_tent() -> StaticBody3D:
	var tent: StaticBody3D = StaticBody3D.new()
	tent.name = "CanvasTent"
	tent.set_script(load("res://scripts/campsite/structure_canvas_tent.gd"))

	var canvas_mat: StandardMaterial3D = StandardMaterial3D.new()
	canvas_mat.albedo_color = Color(0.75, 0.68, 0.55)

	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.5, 0.35, 0.2)

	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(3.0, 0.1, 2.5)
	collision.shape = box_shape
	collision.position.y = 0.05
	tent.add_child(collision)

	var panel_mesh: BoxMesh = BoxMesh.new()
	panel_mesh.size = Vector3(3.0, 0.05, 2.0)

	var panel_left: MeshInstance3D = MeshInstance3D.new()
	panel_left.mesh = panel_mesh
	panel_left.position = Vector3(-0.7, 1.2, 0)
	panel_left.rotation_degrees.z = 45
	panel_left.material_override = canvas_mat
	tent.add_child(panel_left)

	var panel_right: MeshInstance3D = MeshInstance3D.new()
	panel_right.mesh = panel_mesh
	panel_right.position = Vector3(0.7, 1.2, 0)
	panel_right.rotation_degrees.z = -45
	panel_right.material_override = canvas_mat
	tent.add_child(panel_right)

	var back_mesh: BoxMesh = BoxMesh.new()
	back_mesh.size = Vector3(2.0, 1.8, 0.05)
	var back: MeshInstance3D = MeshInstance3D.new()
	back.mesh = back_mesh
	back.position = Vector3(0, 0.9, -0.95)
	back.material_override = canvas_mat
	tent.add_child(back)

	var ridge: MeshInstance3D = MeshInstance3D.new()
	var ridge_mesh: BoxMesh = BoxMesh.new()
	ridge_mesh.size = Vector3(0.08, 0.08, 2.1)
	ridge.mesh = ridge_mesh
	ridge.position = Vector3(0, 1.8, 0)
	ridge.material_override = wood_mat
	tent.add_child(ridge)

	var area: Area3D = Area3D.new()
	area.name = "ProtectionArea"
	var area_collision: CollisionShape3D = CollisionShape3D.new()
	var box_area: BoxShape3D = BoxShape3D.new()
	box_area.size = Vector3(4.0, 3.0, 3.0)
	area_collision.shape = box_area
	area_collision.position.y = 1.0
	area.add_child(area_collision)
	tent.add_child(area)

	return tent


func _create_cabin() -> StaticBody3D:
	# Austrian A-frame cabin design
	var cabin: StaticBody3D = StaticBody3D.new()
	cabin.name = "LogCabin"
	cabin.set_script(load("res://scripts/campsite/structure_cabin.gd"))

	var log_mat: StandardMaterial3D = StandardMaterial3D.new()
	log_mat.albedo_color = Color(0.45, 0.30, 0.18)

	var roof_mat: StandardMaterial3D = StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.30, 0.18, 0.10)

	var floor_mat: StandardMaterial3D = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.5, 0.38, 0.25)

	# A-frame dimensions
	var base_width: float = 6.0
	var depth: float = 6.0
	var peak_height: float = 5.5
	var wall_thick: float = 0.25
	var knee_wall_height: float = 0.8
	var door_width: float = 1.4
	var door_height: float = 2.2

	# Calculate roof panel dimensions
	var roof_rise: float = peak_height - knee_wall_height
	var roof_run: float = base_width / 2.0
	var roof_length: float = sqrt(roof_rise * roof_rise + roof_run * roof_run)
	var roof_angle: float = rad_to_deg(atan2(roof_rise, roof_run))

	# Floor
	var floor_mesh: MeshInstance3D = MeshInstance3D.new()
	var floor_box: BoxMesh = BoxMesh.new()
	floor_box.size = Vector3(base_width - 0.2, 0.1, depth - 0.2)
	floor_mesh.mesh = floor_box
	floor_mesh.position.y = 0.05
	floor_mesh.material_override = floor_mat
	cabin.add_child(floor_mesh)

	# Short knee walls on left and right
	var knee_mesh: BoxMesh = BoxMesh.new()
	knee_mesh.size = Vector3(wall_thick, knee_wall_height, depth)

	var left_knee: MeshInstance3D = MeshInstance3D.new()
	left_knee.mesh = knee_mesh
	left_knee.position = Vector3(-base_width / 2 + wall_thick / 2, knee_wall_height / 2, 0)
	left_knee.material_override = log_mat
	cabin.add_child(left_knee)

	var left_knee_col: CollisionShape3D = CollisionShape3D.new()
	left_knee_col.shape = BoxShape3D.new()
	(left_knee_col.shape as BoxShape3D).size = knee_mesh.size
	left_knee_col.position = left_knee.position
	cabin.add_child(left_knee_col)

	var right_knee: MeshInstance3D = MeshInstance3D.new()
	right_knee.mesh = knee_mesh
	right_knee.position = Vector3(base_width / 2 - wall_thick / 2, knee_wall_height / 2, 0)
	right_knee.material_override = log_mat
	cabin.add_child(right_knee)

	var right_knee_col: CollisionShape3D = CollisionShape3D.new()
	right_knee_col.shape = BoxShape3D.new()
	(right_knee_col.shape as BoxShape3D).size = knee_mesh.size
	right_knee_col.position = right_knee.position
	cabin.add_child(right_knee_col)

	# A-frame roof panels - shorten so corners don't extend past peak
	var roof_thickness: float = 0.2
	var corner_extension: float = roof_thickness / (2.0 * sin(deg_to_rad(roof_angle)))
	var shortened_roof_length: float = roof_length - corner_extension

	var roof_mesh: BoxMesh = BoxMesh.new()
	roof_mesh.size = Vector3(shortened_roof_length, roof_thickness, depth + 0.5)

	var half_length: float = shortened_roof_length / 2.0
	var roof_center_x: float = -roof_run + half_length * cos(deg_to_rad(roof_angle))
	var roof_center_y: float = knee_wall_height + half_length * sin(deg_to_rad(roof_angle))

	var roof_left: MeshInstance3D = MeshInstance3D.new()
	roof_left.mesh = roof_mesh
	roof_left.position = Vector3(roof_center_x, roof_center_y, 0)
	roof_left.rotation_degrees.z = roof_angle
	roof_left.material_override = roof_mat
	cabin.add_child(roof_left)

	var roof_right: MeshInstance3D = MeshInstance3D.new()
	roof_right.mesh = roof_mesh
	roof_right.position = Vector3(-roof_center_x, roof_center_y, 0)
	roof_right.rotation_degrees.z = -roof_angle
	roof_right.material_override = roof_mat
	cabin.add_child(roof_right)

	# Ridge cap at the peak
	var ridge_cap: MeshInstance3D = MeshInstance3D.new()
	var ridge_mesh: BoxMesh = BoxMesh.new()
	var ridge_width: float = corner_extension * 2.5
	ridge_mesh.size = Vector3(ridge_width, roof_thickness, depth + 0.5)
	ridge_cap.mesh = ridge_mesh
	ridge_cap.position = Vector3(0, peak_height + roof_thickness / 2, 0)
	ridge_cap.material_override = roof_mat
	cabin.add_child(ridge_cap)

	# Roof collision
	var roof_col_left: CollisionShape3D = CollisionShape3D.new()
	roof_col_left.shape = BoxShape3D.new()
	(roof_col_left.shape as BoxShape3D).size = Vector3(shortened_roof_length, 0.25, depth)
	roof_col_left.position = Vector3(roof_center_x, roof_center_y, 0)
	roof_col_left.rotation_degrees.z = roof_angle
	cabin.add_child(roof_col_left)

	var roof_col_right: CollisionShape3D = CollisionShape3D.new()
	roof_col_right.shape = BoxShape3D.new()
	(roof_col_right.shape as BoxShape3D).size = Vector3(shortened_roof_length, 0.25, depth)
	roof_col_right.position = Vector3(-roof_center_x, roof_center_y, 0)
	roof_col_right.rotation_degrees.z = -roof_angle
	cabin.add_child(roof_col_right)

	# Front and back walls - stepped triangle (blocky style)
	var step_height: float = 1.0
	var num_steps: int = int(peak_height / step_height)
	var front_z: float = depth / 2 - wall_thick / 2
	var back_z: float = -depth / 2 + wall_thick / 2

	for i: int in range(num_steps):
		var y_pos: float = i * step_height + step_height / 2
		var height_ratio: float = float(i * step_height) / peak_height
		var width_at_height: float = base_width * (1.0 - height_ratio * 0.95)
		width_at_height = max(width_at_height, 0.5)

		if i == 0 or i == 1:
			var side_width: float = (width_at_height - door_width) / 2
			if side_width > 0.2:
				var front_left: MeshInstance3D = MeshInstance3D.new()
				var fl_box: BoxMesh = BoxMesh.new()
				fl_box.size = Vector3(side_width, step_height, wall_thick)
				front_left.mesh = fl_box
				front_left.position = Vector3(-width_at_height / 2 + side_width / 2, y_pos, front_z)
				front_left.material_override = log_mat
				cabin.add_child(front_left)

				var front_right: MeshInstance3D = MeshInstance3D.new()
				var fr_box: BoxMesh = BoxMesh.new()
				fr_box.size = Vector3(side_width, step_height, wall_thick)
				front_right.mesh = fr_box
				front_right.position = Vector3(width_at_height / 2 - side_width / 2, y_pos, front_z)
				front_right.material_override = log_mat
				cabin.add_child(front_right)

			if i == 1:
				var above_height: float = step_height - (door_height - step_height)
				if above_height > 0:
					var above_door: MeshInstance3D = MeshInstance3D.new()
					var ad_box: BoxMesh = BoxMesh.new()
					ad_box.size = Vector3(door_width, above_height, wall_thick)
					above_door.mesh = ad_box
					above_door.position = Vector3(0, door_height + above_height / 2, front_z)
					above_door.material_override = log_mat
					cabin.add_child(above_door)
		else:
			var front_row: MeshInstance3D = MeshInstance3D.new()
			var row_box: BoxMesh = BoxMesh.new()
			row_box.size = Vector3(width_at_height, step_height, wall_thick)
			front_row.mesh = row_box
			front_row.position = Vector3(0, y_pos, front_z)
			front_row.material_override = log_mat
			cabin.add_child(front_row)

		var back_row: MeshInstance3D = MeshInstance3D.new()
		var back_box: BoxMesh = BoxMesh.new()
		back_box.size = Vector3(width_at_height, step_height, wall_thick)
		back_row.mesh = back_box
		back_row.position = Vector3(0, y_pos, back_z)
		back_row.material_override = log_mat
		cabin.add_child(back_row)

	# Front wall collisions - split to leave doorway gap
	var front_side_col_width: float = (base_width - door_width) / 2.0

	# Left side of doorway
	var front_col_left: CollisionShape3D = CollisionShape3D.new()
	front_col_left.shape = BoxShape3D.new()
	(front_col_left.shape as BoxShape3D).size = Vector3(front_side_col_width, peak_height, wall_thick)
	front_col_left.position = Vector3(-base_width / 2 + front_side_col_width / 2, peak_height / 2, front_z)
	cabin.add_child(front_col_left)

	# Right side of doorway
	var front_col_right: CollisionShape3D = CollisionShape3D.new()
	front_col_right.shape = BoxShape3D.new()
	(front_col_right.shape as BoxShape3D).size = Vector3(front_side_col_width, peak_height, wall_thick)
	front_col_right.position = Vector3(base_width / 2 - front_side_col_width / 2, peak_height / 2, front_z)
	cabin.add_child(front_col_right)

	# Above doorway
	var front_col_above: CollisionShape3D = CollisionShape3D.new()
	front_col_above.shape = BoxShape3D.new()
	var above_door_height: float = peak_height - door_height
	(front_col_above.shape as BoxShape3D).size = Vector3(door_width, above_door_height, wall_thick)
	front_col_above.position = Vector3(0, door_height + above_door_height / 2, front_z)
	cabin.add_child(front_col_above)

	# Back wall collision (solid - no door)
	var back_col: CollisionShape3D = CollisionShape3D.new()
	back_col.shape = BoxShape3D.new()
	(back_col.shape as BoxShape3D).size = Vector3(base_width, peak_height, wall_thick)
	back_col.position = Vector3(0, peak_height / 2, back_z)
	cabin.add_child(back_col)

	# Interior: Bed
	var bed: StaticBody3D = _create_cabin_bed()
	bed.position = Vector3(base_width / 2 - 1.5, 0, -depth / 2 + 1.5)
	cabin.add_child(bed)

	# Interior: Kitchen
	var kitchen: StaticBody3D = _create_cabin_kitchen()
	kitchen.position = Vector3(-base_width / 2 + 1.5, 0, -depth / 2 + 1.2)
	cabin.add_child(kitchen)

	# Protection area
	var area: Area3D = Area3D.new()
	area.name = "ProtectionArea"
	var area_collision: CollisionShape3D = CollisionShape3D.new()
	var box_area: BoxShape3D = BoxShape3D.new()
	box_area.size = Vector3(base_width, peak_height, depth)
	area_collision.shape = box_area
	area_collision.position.y = peak_height / 2
	area.add_child(area_collision)
	area.body_entered.connect(cabin._on_protection_area_body_entered)
	area.body_exited.connect(cabin._on_protection_area_body_exited)
	cabin.add_child(area)

	return cabin


func _create_cabin_bed() -> StaticBody3D:
	var bed: StaticBody3D = StaticBody3D.new()
	bed.name = "CabinBed"
	bed.set_script(load("res://scripts/campsite/cabin_bed.gd"))

	var frame_mat: StandardMaterial3D = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.45, 0.32, 0.2)

	var blanket_mat: StandardMaterial3D = StandardMaterial3D.new()
	blanket_mat.albedo_color = Color(0.3, 0.45, 0.6)  # Blue blanket

	var pillow_mat: StandardMaterial3D = StandardMaterial3D.new()
	pillow_mat.albedo_color = Color(0.9, 0.88, 0.82)  # White pillow

	# Bed frame
	var frame: MeshInstance3D = MeshInstance3D.new()
	var frame_mesh: BoxMesh = BoxMesh.new()
	frame_mesh.size = Vector3(1.8, 0.3, 1.0)
	frame.mesh = frame_mesh
	frame.position.y = 0.15
	frame.material_override = frame_mat
	bed.add_child(frame)

	# Mattress/blanket
	var blanket: MeshInstance3D = MeshInstance3D.new()
	var blanket_mesh: BoxMesh = BoxMesh.new()
	blanket_mesh.size = Vector3(1.6, 0.15, 0.9)
	blanket.mesh = blanket_mesh
	blanket.position = Vector3(0, 0.375, 0)
	blanket.material_override = blanket_mat
	bed.add_child(blanket)

	# Pillow
	var pillow: MeshInstance3D = MeshInstance3D.new()
	var pillow_mesh: BoxMesh = BoxMesh.new()
	pillow_mesh.size = Vector3(0.5, 0.12, 0.35)
	pillow.mesh = pillow_mesh
	pillow.position = Vector3(-0.5, 0.5, 0)
	pillow.material_override = pillow_mat
	bed.add_child(pillow)

	# Collision for interaction
	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(1.8, 0.5, 1.0)
	collision.shape = box_shape
	collision.position.y = 0.25
	bed.add_child(collision)

	return bed


func _create_cabin_kitchen() -> StaticBody3D:
	var kitchen: StaticBody3D = StaticBody3D.new()
	kitchen.name = "CabinKitchen"
	kitchen.set_script(load("res://scripts/campsite/cabin_kitchen.gd"))

	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.5, 0.38, 0.25)

	var stone_mat: StandardMaterial3D = StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.5, 0.5, 0.52)

	var fire_mat: StandardMaterial3D = StandardMaterial3D.new()
	fire_mat.albedo_color = Color(1.0, 0.5, 0.1)
	fire_mat.emission_enabled = true
	fire_mat.emission = Color(1.0, 0.4, 0.0)
	fire_mat.emission_energy_multiplier = 1.5

	# Counter/cabinet base
	var counter: MeshInstance3D = MeshInstance3D.new()
	var counter_mesh: BoxMesh = BoxMesh.new()
	counter_mesh.size = Vector3(1.5, 0.8, 0.8)
	counter.mesh = counter_mesh
	counter.position.y = 0.4
	counter.material_override = wood_mat
	kitchen.add_child(counter)

	# Stone cooking surface
	var surface: MeshInstance3D = MeshInstance3D.new()
	var surface_mesh: BoxMesh = BoxMesh.new()
	surface_mesh.size = Vector3(1.5, 0.1, 0.8)
	surface.mesh = surface_mesh
	surface.position.y = 0.85
	surface.material_override = stone_mat
	kitchen.add_child(surface)

	# Small cooking fire (always lit)
	var fire: MeshInstance3D = MeshInstance3D.new()
	var fire_mesh: BoxMesh = BoxMesh.new()
	fire_mesh.size = Vector3(0.3, 0.25, 0.3)
	fire.mesh = fire_mesh
	fire.position = Vector3(0.4, 1.025, 0)
	fire.material_override = fire_mat
	kitchen.add_child(fire)

	# Light from fire
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.2)
	light.light_energy = 1.5
	light.omni_range = 4.0
	light.position = Vector3(0.4, 1.2, 0)
	kitchen.add_child(light)

	# Collision for interaction
	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(1.5, 0.9, 0.8)
	collision.shape = box_shape
	collision.position.y = 0.45
	kitchen.add_child(collision)

	return kitchen
