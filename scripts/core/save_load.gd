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

	# Obstacle states (cleared thorns)
	if chunk_manager and chunk_manager.has_method("get_obstacles_save_data"):
		data["obstacles"] = chunk_manager.get_obstacles_save_data()

	# Cave state (if player is in a cave)
	var cave_transition: Node = get_node_or_null("/root/CaveTransition")
	if cave_transition and cave_transition.has_method("get_save_data"):
		data["cave"] = cave_transition.get_save_data()

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

	# Obstacle states (cleared thorns)
	if data.has("obstacles") and chunk_manager and chunk_manager.has_method("load_obstacles_save_data"):
		chunk_manager.load_obstacles_save_data(data["obstacles"])

	# Cave state
	if data.has("cave"):
		var cave_transition: Node = get_node_or_null("/root/CaveTransition")
		if cave_transition and cave_transition.has_method("load_save_data"):
			cave_transition.load_save_data(data["cave"])

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

	# --- Stone ring: 6 stones in a neat circle ---
	var stone_mat: StandardMaterial3D = StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.40, 0.38, 0.35)
	stone_mat.roughness = 0.95
	var stone_dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	stone_dark_mat.albedo_color = Color(0.34, 0.32, 0.29)
	stone_dark_mat.roughness = 0.95
	for i: int in range(6):
		var stone: MeshInstance3D = MeshInstance3D.new()
		var stone_mesh: BoxMesh = BoxMesh.new()
		stone_mesh.size = Vector3(0.22, 0.12, 0.18)
		stone.mesh = stone_mesh
		var angle: float = i * TAU / 6.0
		stone.position = Vector3(cos(angle) * 0.42, 0.06, sin(angle) * 0.42)
		stone.rotation.y = angle + 0.3
		stone.material_override = stone_mat if i % 2 == 0 else stone_dark_mat
		fire_pit.add_child(stone)

	# --- Two crossed logs ---
	var log_mat: StandardMaterial3D = StandardMaterial3D.new()
	log_mat.albedo_color = Color(0.36, 0.22, 0.10)
	log_mat.roughness = 0.92
	var log1: MeshInstance3D = MeshInstance3D.new()
	var log1_mesh: BoxMesh = BoxMesh.new()
	log1_mesh.size = Vector3(0.7, 0.10, 0.10)
	log1.mesh = log1_mesh
	log1.position = Vector3(0, 0.10, 0)
	log1.rotation.y = -0.3
	log1.material_override = log_mat
	fire_pit.add_child(log1)
	var log2: MeshInstance3D = MeshInstance3D.new()
	var log2_mesh: BoxMesh = BoxMesh.new()
	log2_mesh.size = Vector3(0.65, 0.09, 0.09)
	log2.mesh = log2_mesh
	log2.position = Vector3(0, 0.14, 0)
	log2.rotation.y = 0.8
	log2.material_override = log_mat
	fire_pit.add_child(log2)

	# --- Fire: 3 layers (base, mid, tip) ---
	var base_flame_mat: StandardMaterial3D = StandardMaterial3D.new()
	base_flame_mat.albedo_color = Color(1.0, 0.35, 0.0)
	base_flame_mat.emission_enabled = true
	base_flame_mat.emission = Color(0.95, 0.3, 0.0)
	base_flame_mat.emission_energy_multiplier = 2.5
	var base_flame: MeshInstance3D = MeshInstance3D.new()
	base_flame.name = "FireMesh"
	var bf_mesh: BoxMesh = BoxMesh.new()
	bf_mesh.size = Vector3(0.28, 0.22, 0.24)
	base_flame.mesh = bf_mesh
	base_flame.position = Vector3(0, 0.30, 0)
	base_flame.material_override = base_flame_mat
	fire_pit.add_child(base_flame)

	var mid_mat: StandardMaterial3D = StandardMaterial3D.new()
	mid_mat.albedo_color = Color(1.0, 0.55, 0.05)
	mid_mat.emission_enabled = true
	mid_mat.emission = Color(1.0, 0.5, 0.0)
	mid_mat.emission_energy_multiplier = 3.0
	var mid_flame: MeshInstance3D = MeshInstance3D.new()
	var mf_mesh: BoxMesh = BoxMesh.new()
	mf_mesh.size = Vector3(0.18, 0.18, 0.16)
	mid_flame.mesh = mf_mesh
	mid_flame.position = Vector3(0, 0.48, 0)
	mid_flame.material_override = mid_mat
	fire_pit.add_child(mid_flame)

	var tip_mat: StandardMaterial3D = StandardMaterial3D.new()
	tip_mat.albedo_color = Color(1.0, 0.82, 0.25)
	tip_mat.emission_enabled = true
	tip_mat.emission = Color(1.0, 0.75, 0.15)
	tip_mat.emission_energy_multiplier = 3.5
	var tip_flame: MeshInstance3D = MeshInstance3D.new()
	var tf_mesh: BoxMesh = BoxMesh.new()
	tf_mesh.size = Vector3(0.10, 0.12, 0.08)
	tip_flame.mesh = tf_mesh
	tip_flame.position = Vector3(0, 0.62, 0)
	tip_flame.material_override = tip_mat
	fire_pit.add_child(tip_flame)

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

	# Wood materials with variation
	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.50, 0.33, 0.18)
	wood_mat.roughness = 0.92

	var wood_dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_dark_mat.albedo_color = Color(0.40, 0.26, 0.13)
	wood_dark_mat.roughness = 0.92

	var wood_light_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_light_mat.albedo_color = Color(0.58, 0.40, 0.24)
	wood_light_mat.roughness = 0.90

	# Canvas cover - main panel
	var canvas_mat: StandardMaterial3D = StandardMaterial3D.new()
	canvas_mat.albedo_color = Color(0.62, 0.57, 0.42)
	canvas_mat.roughness = 0.85

	var cover: MeshInstance3D = MeshInstance3D.new()
	var cover_mesh: BoxMesh = BoxMesh.new()
	cover_mesh.size = Vector3(2.4, 0.05, 2.2)
	cover.mesh = cover_mesh
	cover.position = Vector3(0, 0.9, 0)
	cover.rotation.x = 0.5
	cover.material_override = canvas_mat
	shelter.add_child(cover)

	# Canvas shadow underside
	var canvas_shadow_mat: StandardMaterial3D = StandardMaterial3D.new()
	canvas_shadow_mat.albedo_color = Color(0.48, 0.44, 0.32)
	var cover_under: MeshInstance3D = MeshInstance3D.new()
	var cu_mesh: BoxMesh = BoxMesh.new()
	cu_mesh.size = Vector3(2.3, 0.02, 2.1)
	cover_under.mesh = cu_mesh
	cover_under.position = Vector3(0, 0.87, 0)
	cover_under.rotation.x = 0.5
	cover_under.material_override = canvas_shadow_mat
	shelter.add_child(cover_under)

	# Canvas seam lines (stitching detail)
	var seam_mat: StandardMaterial3D = StandardMaterial3D.new()
	seam_mat.albedo_color = Color(0.52, 0.48, 0.35)
	for i: int in range(3):
		var seam: MeshInstance3D = MeshInstance3D.new()
		var seam_mesh: BoxMesh = BoxMesh.new()
		seam_mesh.size = Vector3(2.3, 0.015, 0.03)
		seam.mesh = seam_mesh
		seam.position = Vector3(0, 0.92, -0.6 + i * 0.6)
		seam.rotation.x = 0.5
		seam.material_override = seam_mat
		shelter.add_child(seam)

	# Frame beams (back and front)
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

	# Support poles with bark detail
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

	# Bark texture strips on poles
	var bark_strip_mesh: BoxMesh = BoxMesh.new()
	bark_strip_mesh.size = Vector3(0.04, 1.48, 0.11)
	for side_x: float in [-1.1, 1.1]:
		var strip: MeshInstance3D = MeshInstance3D.new()
		strip.mesh = bark_strip_mesh
		strip.position = Vector3(side_x + 0.02, 0.75, -0.8)
		strip.material_override = wood_dark_mat
		shelter.add_child(strip)

	# Lashing at pole-beam joints (rope wraps)
	var lash_mat: StandardMaterial3D = StandardMaterial3D.new()
	lash_mat.albedo_color = Color(0.55, 0.48, 0.35)
	var lash_mesh: BoxMesh = BoxMesh.new()
	lash_mesh.size = Vector3(0.16, 0.08, 0.16)
	for side_x: float in [-1.1, 1.1]:
		var lash: MeshInstance3D = MeshInstance3D.new()
		lash.mesh = lash_mesh
		lash.position = Vector3(side_x, 1.5, -0.8)
		lash.material_override = lash_mat
		shelter.add_child(lash)

	# Front low support sticks (forked)
	var stick_mesh: BoxMesh = BoxMesh.new()
	stick_mesh.size = Vector3(0.06, 0.6, 0.06)
	for side_x: float in [-1.1, 1.1]:
		var stick: MeshInstance3D = MeshInstance3D.new()
		stick.mesh = stick_mesh
		stick.position = Vector3(side_x, 0.3, 1.0)
		stick.rotation.z = 0.05 if side_x < 0 else -0.05
		stick.material_override = wood_dark_mat
		shelter.add_child(stick)

	# Ground leaf bed (inside shelter)
	var leaf_mat: StandardMaterial3D = StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.35, 0.28, 0.15)
	var leaf_bed: MeshInstance3D = MeshInstance3D.new()
	var lb_mesh: BoxMesh = BoxMesh.new()
	lb_mesh.size = Vector3(1.6, 0.06, 1.4)
	leaf_bed.mesh = lb_mesh
	leaf_bed.position = Vector3(0, 0.03, -0.1)
	leaf_bed.material_override = leaf_mat
	shelter.add_child(leaf_bed)

	# Scattered leaf patches
	var leaf_green_mat: StandardMaterial3D = StandardMaterial3D.new()
	leaf_green_mat.albedo_color = Color(0.28, 0.35, 0.18)
	for i: int in range(4):
		var patch: MeshInstance3D = MeshInstance3D.new()
		var p_mesh: BoxMesh = BoxMesh.new()
		p_mesh.size = Vector3(0.4, 0.03, 0.3)
		patch.mesh = p_mesh
		patch.position = Vector3(-0.5 + i * 0.35, 0.05, -0.3 + (i % 2) * 0.3)
		patch.rotation.y = i * 0.7
		patch.material_override = leaf_green_mat if i % 2 == 0 else leaf_mat
		shelter.add_child(patch)

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

	# Materials
	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.58, 0.40, 0.24)
	wood_mat.roughness = 0.88

	var wood_dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_dark_mat.albedo_color = Color(0.45, 0.30, 0.16)
	wood_dark_mat.roughness = 0.90

	var wood_light_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_light_mat.albedo_color = Color(0.65, 0.48, 0.30)
	wood_light_mat.roughness = 0.85

	var metal_mat: StandardMaterial3D = StandardMaterial3D.new()
	metal_mat.albedo_color = Color(0.30, 0.28, 0.26)
	metal_mat.metallic = 0.6
	metal_mat.roughness = 0.55

	# Box body
	var box_inst: MeshInstance3D = MeshInstance3D.new()
	var bm: BoxMesh = BoxMesh.new()
	bm.size = Vector3(1.0, 0.6, 0.6)
	box_inst.mesh = bm
	box_inst.position.y = 0.3
	box_inst.material_override = wood_mat
	storage.add_child(box_inst)

	# Plank lines (vertical grain on front)
	for i: int in range(5):
		var plank: MeshInstance3D = MeshInstance3D.new()
		var pm: BoxMesh = BoxMesh.new()
		pm.size = Vector3(0.015, 0.56, 0.61)
		plank.mesh = pm
		plank.position = Vector3(-0.4 + i * 0.2, 0.3, 0)
		plank.material_override = wood_dark_mat
		storage.add_child(plank)

	# Side plank lines
	for i: int in range(3):
		var s_plank: MeshInstance3D = MeshInstance3D.new()
		var sp_m: BoxMesh = BoxMesh.new()
		sp_m.size = Vector3(1.01, 0.56, 0.015)
		s_plank.mesh = sp_m
		s_plank.position = Vector3(0, 0.3, -0.2 + i * 0.2)
		s_plank.material_override = wood_dark_mat
		storage.add_child(s_plank)

	# Metal corner bands
	var band_mesh_h: BoxMesh = BoxMesh.new()
	band_mesh_h.size = Vector3(1.04, 0.04, 0.64)
	for y_pos: float in [0.04, 0.58]:
		var band: MeshInstance3D = MeshInstance3D.new()
		band.mesh = band_mesh_h
		band.position = Vector3(0, y_pos, 0)
		band.material_override = metal_mat
		storage.add_child(band)

	# Metal side bands (vertical reinforcements)
	var band_mesh_v: BoxMesh = BoxMesh.new()
	band_mesh_v.size = Vector3(0.04, 0.60, 0.64)
	for x_pos: float in [-0.50, 0.50]:
		var vband: MeshInstance3D = MeshInstance3D.new()
		vband.mesh = band_mesh_v
		vband.position = Vector3(x_pos, 0.3, 0)
		vband.material_override = metal_mat
		storage.add_child(vband)

	# Lid
	var lid: MeshInstance3D = MeshInstance3D.new()
	var lid_mesh: BoxMesh = BoxMesh.new()
	lid_mesh.size = Vector3(1.04, 0.08, 0.64)
	lid.mesh = lid_mesh
	lid.position.y = 0.64
	lid.material_override = wood_dark_mat
	storage.add_child(lid)

	# Lid edge highlight
	var lid_top: MeshInstance3D = MeshInstance3D.new()
	var lt_m: BoxMesh = BoxMesh.new()
	lt_m.size = Vector3(0.96, 0.02, 0.56)
	lid_top.mesh = lt_m
	lid_top.position.y = 0.69
	lid_top.material_override = wood_light_mat
	storage.add_child(lid_top)

	# Handle on front
	var handle_base: MeshInstance3D = MeshInstance3D.new()
	var hb_m: BoxMesh = BoxMesh.new()
	hb_m.size = Vector3(0.2, 0.04, 0.04)
	handle_base.mesh = hb_m
	handle_base.position = Vector3(0, 0.40, 0.32)
	handle_base.material_override = metal_mat
	storage.add_child(handle_base)

	# Handle brackets
	for hx: float in [-0.08, 0.08]:
		var bracket: MeshInstance3D = MeshInstance3D.new()
		var br_m: BoxMesh = BoxMesh.new()
		br_m.size = Vector3(0.03, 0.06, 0.03)
		bracket.mesh = br_m
		bracket.position = Vector3(hx, 0.38, 0.32)
		bracket.material_override = metal_mat
		storage.add_child(bracket)

	# Latch on front
	var latch: MeshInstance3D = MeshInstance3D.new()
	var la_m: BoxMesh = BoxMesh.new()
	la_m.size = Vector3(0.08, 0.10, 0.02)
	latch.mesh = la_m
	latch.position = Vector3(0, 0.60, 0.32)
	latch.material_override = metal_mat
	storage.add_child(latch)

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

	# Materials with variation
	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.52, 0.37, 0.22)
	wood_mat.roughness = 0.88

	var wood_dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_dark_mat.albedo_color = Color(0.40, 0.26, 0.14)
	wood_dark_mat.roughness = 0.90

	var wood_light_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_light_mat.albedo_color = Color(0.60, 0.45, 0.28)
	wood_light_mat.roughness = 0.85

	var leg_mat: StandardMaterial3D = StandardMaterial3D.new()
	leg_mat.albedo_color = Color(0.42, 0.28, 0.15)
	leg_mat.roughness = 0.92

	var metal_mat: StandardMaterial3D = StandardMaterial3D.new()
	metal_mat.albedo_color = Color(0.35, 0.33, 0.30)
	metal_mat.metallic = 0.5
	metal_mat.roughness = 0.6

	# Thick tabletop
	var top: MeshInstance3D = MeshInstance3D.new()
	var top_mesh: BoxMesh = BoxMesh.new()
	top_mesh.size = Vector3(1.2, 0.1, 0.8)
	top.mesh = top_mesh
	top.position.y = 0.75
	top.material_override = wood_mat
	bench.add_child(top)

	# Wood grain lines on tabletop
	for i: int in range(4):
		var grain: MeshInstance3D = MeshInstance3D.new()
		var g_mesh: BoxMesh = BoxMesh.new()
		g_mesh.size = Vector3(1.18, 0.012, 0.03)
		grain.mesh = g_mesh
		grain.position = Vector3(0, 0.806, -0.25 + i * 0.18)
		grain.material_override = wood_dark_mat
		bench.add_child(grain)

	# Edge banding (slightly darker lip around tabletop)
	var edge_mat: StandardMaterial3D = StandardMaterial3D.new()
	edge_mat.albedo_color = Color(0.45, 0.30, 0.17)
	# Front edge
	var front_edge: MeshInstance3D = MeshInstance3D.new()
	var fe_mesh: BoxMesh = BoxMesh.new()
	fe_mesh.size = Vector3(1.22, 0.1, 0.03)
	front_edge.mesh = fe_mesh
	front_edge.position = Vector3(0, 0.75, 0.41)
	front_edge.material_override = edge_mat
	bench.add_child(front_edge)
	# Back edge
	var back_edge: MeshInstance3D = MeshInstance3D.new()
	back_edge.mesh = fe_mesh
	back_edge.position = Vector3(0, 0.75, -0.41)
	back_edge.material_override = edge_mat
	bench.add_child(back_edge)

	# Table legs with slight taper
	var leg_mesh: BoxMesh = BoxMesh.new()
	leg_mesh.size = Vector3(0.1, 0.65, 0.1)

	var leg_positions: Array[Vector3] = [
		Vector3(-0.5, 0.325, -0.3), Vector3(0.5, 0.325, -0.3),
		Vector3(-0.5, 0.325, 0.3), Vector3(0.5, 0.325, 0.3)
	]
	for pos: Vector3 in leg_positions:
		var leg: MeshInstance3D = MeshInstance3D.new()
		leg.mesh = leg_mesh
		leg.position = pos
		leg.material_override = leg_mat
		bench.add_child(leg)

	# Cross-braces for stability
	var brace_mesh: BoxMesh = BoxMesh.new()
	brace_mesh.size = Vector3(0.9, 0.05, 0.06)
	# Front brace
	var f_brace: MeshInstance3D = MeshInstance3D.new()
	f_brace.mesh = brace_mesh
	f_brace.position = Vector3(0, 0.2, 0.3)
	f_brace.material_override = wood_dark_mat
	bench.add_child(f_brace)
	# Back brace
	var b_brace: MeshInstance3D = MeshInstance3D.new()
	b_brace.mesh = brace_mesh
	b_brace.position = Vector3(0, 0.2, -0.3)
	b_brace.material_override = wood_dark_mat
	bench.add_child(b_brace)

	# Side brace
	var s_brace_mesh: BoxMesh = BoxMesh.new()
	s_brace_mesh.size = Vector3(0.06, 0.05, 0.5)
	var side_brace: MeshInstance3D = MeshInstance3D.new()
	side_brace.mesh = s_brace_mesh
	side_brace.position = Vector3(0, 0.35, 0)
	side_brace.material_override = wood_dark_mat
	bench.add_child(side_brace)

	# Tools on surface: small hammer head
	var hammer_head: MeshInstance3D = MeshInstance3D.new()
	var hh_mesh: BoxMesh = BoxMesh.new()
	hh_mesh.size = Vector3(0.06, 0.04, 0.12)
	hammer_head.mesh = hh_mesh
	hammer_head.position = Vector3(-0.35, 0.82, 0.1)
	hammer_head.material_override = metal_mat
	bench.add_child(hammer_head)
	# Hammer handle
	var hammer_handle: MeshInstance3D = MeshInstance3D.new()
	var hh2_mesh: BoxMesh = BoxMesh.new()
	hh2_mesh.size = Vector3(0.03, 0.03, 0.2)
	hammer_handle.mesh = hh2_mesh
	hammer_handle.position = Vector3(-0.35, 0.82, 0.22)
	hammer_handle.material_override = wood_light_mat
	bench.add_child(hammer_handle)

	# Small knife on surface
	var knife_blade: MeshInstance3D = MeshInstance3D.new()
	var kb_mesh: BoxMesh = BoxMesh.new()
	kb_mesh.size = Vector3(0.15, 0.01, 0.03)
	knife_blade.mesh = kb_mesh
	knife_blade.position = Vector3(0.3, 0.812, -0.15)
	knife_blade.rotation.y = 0.3
	knife_blade.material_override = metal_mat
	bench.add_child(knife_blade)
	var knife_grip: MeshInstance3D = MeshInstance3D.new()
	var kg_mesh: BoxMesh = BoxMesh.new()
	kg_mesh.size = Vector3(0.08, 0.02, 0.04)
	knife_grip.mesh = kg_mesh
	knife_grip.position = Vector3(0.38, 0.815, -0.14)
	knife_grip.rotation.y = 0.3
	knife_grip.material_override = wood_dark_mat
	bench.add_child(knife_grip)

	# Wear marks on tabletop (lighter scratched areas)
	var wear_mat: StandardMaterial3D = StandardMaterial3D.new()
	wear_mat.albedo_color = Color(0.58, 0.44, 0.28, 0.4)
	wear_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var wear: MeshInstance3D = MeshInstance3D.new()
	var w_mesh: BoxMesh = BoxMesh.new()
	w_mesh.size = Vector3(0.4, 0.012, 0.3)
	wear.mesh = w_mesh
	wear.position = Vector3(0, 0.808, 0.05)
	wear.material_override = wear_mat
	bench.add_child(wear)

	return bench


func _create_drying_rack() -> StaticBody3D:
	var rack: StaticBody3D = StaticBody3D.new()
	rack.name = "DryingRack"
	rack.set_script(load("res://scripts/campsite/structure_drying_rack.gd"))

	# Materials
	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.50, 0.35, 0.20)
	wood_mat.roughness = 0.90

	var wood_dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_dark_mat.albedo_color = Color(0.38, 0.25, 0.13)
	wood_dark_mat.roughness = 0.92

	var rope_mat: StandardMaterial3D = StandardMaterial3D.new()
	rope_mat.albedo_color = Color(0.55, 0.48, 0.35)
	rope_mat.roughness = 0.85

	var meat_mat: StandardMaterial3D = StandardMaterial3D.new()
	meat_mat.albedo_color = Color(0.55, 0.28, 0.22)

	var herb_mat: StandardMaterial3D = StandardMaterial3D.new()
	herb_mat.albedo_color = Color(0.30, 0.45, 0.22)

	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(1.5, 1.2, 0.4)
	collision.shape = box_shape
	collision.position.y = 0.6
	rack.add_child(collision)

	# Posts with bark texture
	var post_mesh: BoxMesh = BoxMesh.new()
	post_mesh.size = Vector3(0.1, 1.2, 0.1)
	var bark_mesh: BoxMesh = BoxMesh.new()
	bark_mesh.size = Vector3(0.04, 1.18, 0.11)

	for side_x: float in [-0.6, 0.6]:
		var post: MeshInstance3D = MeshInstance3D.new()
		post.mesh = post_mesh
		post.position = Vector3(side_x, 0.6, 0)
		post.material_override = wood_mat
		rack.add_child(post)
		# Bark detail
		var bark: MeshInstance3D = MeshInstance3D.new()
		bark.mesh = bark_mesh
		bark.position = Vector3(side_x + 0.02, 0.6, 0)
		bark.material_override = wood_dark_mat
		rack.add_child(bark)

	# Forked tops on posts (Y-shape support)
	var fork_mesh: BoxMesh = BoxMesh.new()
	fork_mesh.size = Vector3(0.06, 0.15, 0.04)
	for side_x: float in [-0.6, 0.6]:
		for fork_off: float in [-0.06, 0.06]:
			var fork: MeshInstance3D = MeshInstance3D.new()
			fork.mesh = fork_mesh
			fork.position = Vector3(side_x + fork_off, 1.25, 0)
			fork.rotation.z = fork_off * 5.0
			fork.material_override = wood_mat
			rack.add_child(fork)

	# Horizontal bars with notch detail
	var bar_mesh: BoxMesh = BoxMesh.new()
	bar_mesh.size = Vector3(1.3, 0.06, 0.06)

	for i: int in range(3):
		var bar_y: float = 0.4 + i * 0.35
		var bar: MeshInstance3D = MeshInstance3D.new()
		bar.mesh = bar_mesh
		bar.position = Vector3(0, bar_y, 0)
		bar.material_override = wood_mat
		rack.add_child(bar)

	# Lashing at bar-post joints
	var lash_mesh: BoxMesh = BoxMesh.new()
	lash_mesh.size = Vector3(0.14, 0.04, 0.14)
	for i: int in range(3):
		for side_x: float in [-0.6, 0.6]:
			var lash: MeshInstance3D = MeshInstance3D.new()
			lash.mesh = lash_mesh
			lash.position = Vector3(side_x, 0.4 + i * 0.35, 0)
			lash.material_override = rope_mat
			rack.add_child(lash)

	# Hanging items: strips of meat/fish and herb bundles
	var strip_mesh: BoxMesh = BoxMesh.new()
	strip_mesh.size = Vector3(0.08, 0.18, 0.03)
	var herb_bundle_mesh: BoxMesh = BoxMesh.new()
	herb_bundle_mesh.size = Vector3(0.06, 0.14, 0.06)

	# Items on top bar
	for i: int in range(4):
		var item: MeshInstance3D = MeshInstance3D.new()
		if i % 2 == 0:
			item.mesh = strip_mesh
			item.material_override = meat_mat
		else:
			item.mesh = herb_bundle_mesh
			item.material_override = herb_mat
		item.position = Vector3(-0.35 + i * 0.25, 1.0, 0)
		rack.add_child(item)

	# Items on middle bar
	for i: int in range(3):
		var item: MeshInstance3D = MeshInstance3D.new()
		item.mesh = strip_mesh
		item.material_override = meat_mat if i != 1 else herb_mat
		item.position = Vector3(-0.25 + i * 0.25, 0.58, 0)
		rack.add_child(item)

	# Hanging cord details (small vertical ropes)
	var cord_mesh: BoxMesh = BoxMesh.new()
	cord_mesh.size = Vector3(0.015, 0.08, 0.015)
	for i: int in range(5):
		var cord: MeshInstance3D = MeshInstance3D.new()
		cord.mesh = cord_mesh
		cord.position = Vector3(-0.4 + i * 0.2, 1.06, 0)
		cord.material_override = rope_mat
		rack.add_child(cord)

	return rack


func _create_herb_garden() -> StaticBody3D:
	var garden: StaticBody3D = StaticBody3D.new()
	garden.name = "HerbGarden"
	garden.set_script(load("res://scripts/campsite/structure_garden.gd"))

	# Materials
	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.50, 0.35, 0.20)
	wood_mat.roughness = 0.90

	var wood_dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_dark_mat.albedo_color = Color(0.40, 0.27, 0.14)
	wood_dark_mat.roughness = 0.92

	var dirt_mat: StandardMaterial3D = StandardMaterial3D.new()
	dirt_mat.albedo_color = Color(0.38, 0.26, 0.16)
	dirt_mat.roughness = 0.95

	var dirt_dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	dirt_dark_mat.albedo_color = Color(0.30, 0.20, 0.12)
	dirt_dark_mat.roughness = 0.95

	# Plant colors - varied greens for different herbs
	var herb_green: StandardMaterial3D = StandardMaterial3D.new()
	herb_green.albedo_color = Color(0.25, 0.55, 0.20)

	var herb_dark_green: StandardMaterial3D = StandardMaterial3D.new()
	herb_dark_green.albedo_color = Color(0.18, 0.42, 0.15)

	var herb_light_green: StandardMaterial3D = StandardMaterial3D.new()
	herb_light_green.albedo_color = Color(0.35, 0.62, 0.28)

	var herb_sage: StandardMaterial3D = StandardMaterial3D.new()
	herb_sage.albedo_color = Color(0.40, 0.52, 0.38)

	var flower_mat: StandardMaterial3D = StandardMaterial3D.new()
	flower_mat.albedo_color = Color(0.75, 0.55, 0.80)

	var flower_yellow_mat: StandardMaterial3D = StandardMaterial3D.new()
	flower_yellow_mat.albedo_color = Color(0.90, 0.80, 0.30)

	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(2.0, 0.4, 1.5)
	collision.shape = box_shape
	collision.position.y = 0.2
	garden.add_child(collision)

	# Wooden border with plank detail
	var border_mesh: BoxMesh = BoxMesh.new()
	border_mesh.size = Vector3(2.0, 0.3, 0.1)
	var side_mesh: BoxMesh = BoxMesh.new()
	side_mesh.size = Vector3(0.1, 0.3, 1.5)

	# Front/back borders with nail detail
	for z_pos: float in [0.7, -0.7]:
		var border: MeshInstance3D = MeshInstance3D.new()
		border.mesh = border_mesh
		border.position = Vector3(0, 0.15, z_pos)
		border.material_override = wood_mat
		garden.add_child(border)
		# Plank lines
		for i: int in range(3):
			var p_line: MeshInstance3D = MeshInstance3D.new()
			var pl_m: BoxMesh = BoxMesh.new()
			pl_m.size = Vector3(0.015, 0.28, 0.101)
			p_line.mesh = pl_m
			p_line.position = Vector3(-0.5 + i * 0.5, 0.15, z_pos)
			p_line.material_override = wood_dark_mat
			garden.add_child(p_line)

	# Side borders
	for x_pos: float in [-0.95, 0.95]:
		var side: MeshInstance3D = MeshInstance3D.new()
		side.mesh = side_mesh
		side.position = Vector3(x_pos, 0.15, 0)
		side.material_override = wood_mat
		garden.add_child(side)

	# Corner posts (slightly taller)
	var corner_mesh: BoxMesh = BoxMesh.new()
	corner_mesh.size = Vector3(0.08, 0.36, 0.08)
	for cx: float in [-0.95, 0.95]:
		for cz: float in [-0.7, 0.7]:
			var corner: MeshInstance3D = MeshInstance3D.new()
			corner.mesh = corner_mesh
			corner.position = Vector3(cx, 0.18, cz)
			corner.material_override = wood_dark_mat
			garden.add_child(corner)

	# Dirt bed with texture
	var dirt: MeshInstance3D = MeshInstance3D.new()
	var dirt_mesh: BoxMesh = BoxMesh.new()
	dirt_mesh.size = Vector3(1.8, 0.2, 1.3)
	dirt.mesh = dirt_mesh
	dirt.position.y = 0.1
	dirt.material_override = dirt_mat
	garden.add_child(dirt)

	# Furrow rows (darker dirt lines)
	for i: int in range(3):
		var furrow: MeshInstance3D = MeshInstance3D.new()
		var f_mesh: BoxMesh = BoxMesh.new()
		f_mesh.size = Vector3(1.7, 0.015, 0.06)
		furrow.mesh = f_mesh
		furrow.position = Vector3(0, 0.21, -0.4 + i * 0.4)
		furrow.material_override = dirt_dark_mat
		garden.add_child(furrow)

	# Plants - 8 varied herb types in 2x4 grid
	var herb_materials: Array = [herb_green, herb_dark_green, herb_light_green, herb_sage,
		herb_green, herb_light_green, herb_dark_green, herb_sage]

	for row: int in range(2):
		for col: int in range(4):
			var idx: int = row * 4 + col
			var px: float = -0.6 + col * 0.4
			var pz: float = -0.3 + row * 0.6

			# Main plant body (varied heights)
			var plant: MeshInstance3D = MeshInstance3D.new()
			var p_mesh: BoxMesh = BoxMesh.new()
			var height: float = 0.22 + (idx % 3) * 0.06
			p_mesh.size = Vector3(0.2, height, 0.2)
			plant.mesh = p_mesh
			plant.position = Vector3(px, 0.2 + height / 2.0, pz)
			plant.material_override = herb_materials[idx]
			garden.add_child(plant)

			# Leaf clusters (smaller boxes around main plant)
			for leaf_i: int in range(3):
				var leaf: MeshInstance3D = MeshInstance3D.new()
				var l_mesh: BoxMesh = BoxMesh.new()
				l_mesh.size = Vector3(0.1, 0.08, 0.1)
				leaf.mesh = l_mesh
				var lx: float = px + [-0.1, 0.1, 0.0][leaf_i]
				var lz: float = pz + [0.05, -0.05, 0.1][leaf_i]
				leaf.position = Vector3(lx, 0.28 + leaf_i * 0.04, lz)
				leaf.material_override = herb_materials[idx]
				garden.add_child(leaf)

			# Some plants get flowers (small colored dots on top)
			if idx == 2 or idx == 5:
				var flower: MeshInstance3D = MeshInstance3D.new()
				var fl_mesh: BoxMesh = BoxMesh.new()
				fl_mesh.size = Vector3(0.06, 0.06, 0.06)
				flower.mesh = fl_mesh
				flower.position = Vector3(px, 0.2 + height + 0.05, pz)
				flower.material_override = flower_mat if idx == 2 else flower_yellow_mat
				garden.add_child(flower)

	# Mulch/bark chips scattered on soil
	var mulch_mat: StandardMaterial3D = StandardMaterial3D.new()
	mulch_mat.albedo_color = Color(0.42, 0.30, 0.18)
	for i: int in range(6):
		var mulch: MeshInstance3D = MeshInstance3D.new()
		var m_mesh: BoxMesh = BoxMesh.new()
		m_mesh.size = Vector3(0.08, 0.02, 0.05)
		mulch.mesh = m_mesh
		mulch.position = Vector3(-0.7 + i * 0.28, 0.21, 0.15 - (i % 2) * 0.3)
		mulch.rotation.y = i * 0.8
		mulch.material_override = mulch_mat
		garden.add_child(mulch)

	return garden


func _create_canvas_tent() -> StaticBody3D:
	var tent: StaticBody3D = StaticBody3D.new()
	tent.name = "CanvasTent"
	tent.set_script(load("res://scripts/campsite/structure_canvas_tent.gd"))

	# Materials
	var canvas_mat: StandardMaterial3D = StandardMaterial3D.new()
	canvas_mat.albedo_color = Color(0.72, 0.66, 0.52)
	canvas_mat.roughness = 0.85

	var canvas_shadow_mat: StandardMaterial3D = StandardMaterial3D.new()
	canvas_shadow_mat.albedo_color = Color(0.60, 0.55, 0.42)

	var canvas_light_mat: StandardMaterial3D = StandardMaterial3D.new()
	canvas_light_mat.albedo_color = Color(0.78, 0.72, 0.58)

	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.50, 0.35, 0.20)
	wood_mat.roughness = 0.90

	var wood_dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_dark_mat.albedo_color = Color(0.38, 0.25, 0.13)

	var rope_mat: StandardMaterial3D = StandardMaterial3D.new()
	rope_mat.albedo_color = Color(0.55, 0.48, 0.35)

	var interior_mat: StandardMaterial3D = StandardMaterial3D.new()
	interior_mat.albedo_color = Color(0.08, 0.07, 0.06)

	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(3.0, 0.1, 2.5)
	collision.shape = box_shape
	collision.position.y = 0.05
	tent.add_child(collision)

	# Canvas panels (A-frame)
	var panel_mesh: BoxMesh = BoxMesh.new()
	panel_mesh.size = Vector3(3.0, 0.05, 2.0)

	# Left panel (slightly darker - shadow side)
	var panel_left: MeshInstance3D = MeshInstance3D.new()
	panel_left.mesh = panel_mesh
	panel_left.position = Vector3(-0.7, 1.2, 0)
	panel_left.rotation_degrees.z = 45
	panel_left.material_override = canvas_shadow_mat
	tent.add_child(panel_left)

	# Right panel (lighter - catching light)
	var panel_right: MeshInstance3D = MeshInstance3D.new()
	panel_right.mesh = panel_mesh
	panel_right.position = Vector3(0.7, 1.2, 0)
	panel_right.rotation_degrees.z = -45
	panel_right.material_override = canvas_light_mat
	tent.add_child(panel_right)

	# Canvas seam lines on panels
	var seam_mesh: BoxMesh = BoxMesh.new()
	seam_mesh.size = Vector3(2.9, 0.015, 0.03)
	for i: int in range(3):
		# Left panel seams
		var seam_l: MeshInstance3D = MeshInstance3D.new()
		seam_l.mesh = seam_mesh
		seam_l.position = Vector3(-0.7, 1.22, -0.5 + i * 0.5)
		seam_l.rotation_degrees.z = 45
		seam_l.material_override = canvas_mat
		tent.add_child(seam_l)
		# Right panel seams
		var seam_r: MeshInstance3D = MeshInstance3D.new()
		seam_r.mesh = seam_mesh
		seam_r.position = Vector3(0.7, 1.22, -0.5 + i * 0.5)
		seam_r.rotation_degrees.z = -45
		seam_r.material_override = canvas_mat
		tent.add_child(seam_r)

	# Back wall
	var back_mesh: BoxMesh = BoxMesh.new()
	back_mesh.size = Vector3(2.0, 1.8, 0.05)
	var back: MeshInstance3D = MeshInstance3D.new()
	back.mesh = back_mesh
	back.position = Vector3(0, 0.9, -0.95)
	back.material_override = canvas_mat
	tent.add_child(back)

	# Front opening flaps
	var flap_mesh: BoxMesh = BoxMesh.new()
	flap_mesh.size = Vector3(0.4, 1.6, 0.04)
	# Left flap (slightly open/angled)
	var flap_l: MeshInstance3D = MeshInstance3D.new()
	flap_l.mesh = flap_mesh
	flap_l.position = Vector3(-0.5, 0.85, 0.97)
	flap_l.rotation.y = -0.2
	flap_l.material_override = canvas_shadow_mat
	tent.add_child(flap_l)
	# Right flap
	var flap_r: MeshInstance3D = MeshInstance3D.new()
	flap_r.mesh = flap_mesh
	flap_r.position = Vector3(0.5, 0.85, 0.97)
	flap_r.rotation.y = 0.2
	flap_r.material_override = canvas_light_mat
	tent.add_child(flap_r)

	# Dark interior visible through opening
	var interior: MeshInstance3D = MeshInstance3D.new()
	var int_mesh: BoxMesh = BoxMesh.new()
	int_mesh.size = Vector3(0.8, 1.4, 0.02)
	interior.mesh = int_mesh
	interior.position = Vector3(0, 0.8, 0.90)
	interior.material_override = interior_mat
	tent.add_child(interior)

	# Ridge pole
	var ridge: MeshInstance3D = MeshInstance3D.new()
	var ridge_mesh: BoxMesh = BoxMesh.new()
	ridge_mesh.size = Vector3(0.08, 0.08, 2.3)
	ridge.mesh = ridge_mesh
	ridge.position = Vector3(0, 1.8, 0)
	ridge.material_override = wood_mat
	tent.add_child(ridge)

	# Ridge pole bark detail
	var ridge_bark: MeshInstance3D = MeshInstance3D.new()
	var rb_mesh: BoxMesh = BoxMesh.new()
	rb_mesh.size = Vector3(0.03, 0.085, 2.28)
	ridge_bark.mesh = rb_mesh
	ridge_bark.position = Vector3(0.02, 1.8, 0)
	ridge_bark.material_override = wood_dark_mat
	tent.add_child(ridge_bark)

	# Support poles at front (visible through opening)
	var front_pole_mesh: BoxMesh = BoxMesh.new()
	front_pole_mesh.size = Vector3(0.07, 1.8, 0.07)
	for fp_x: float in [-0.9, 0.9]:
		var fp: MeshInstance3D = MeshInstance3D.new()
		fp.mesh = front_pole_mesh
		fp.position = Vector3(fp_x, 0.9, 0.95)
		fp.material_override = wood_mat
		tent.add_child(fp)

	# Guy ropes (angled lines from ridge to ground)
	var guy_mesh: BoxMesh = BoxMesh.new()
	guy_mesh.size = Vector3(0.02, 1.2, 0.02)
	for side_x: float in [-1.8, 1.8]:
		var guy: MeshInstance3D = MeshInstance3D.new()
		guy.mesh = guy_mesh
		guy.position = Vector3(side_x * 0.6, 1.0, 0)
		guy.rotation.z = 0.6 if side_x < 0 else -0.6
		guy.material_override = rope_mat
		tent.add_child(guy)

	# Tent stakes
	var stake_mesh: BoxMesh = BoxMesh.new()
	stake_mesh.size = Vector3(0.04, 0.2, 0.04)
	for sx: float in [-1.6, 1.6]:
		var stake: MeshInstance3D = MeshInstance3D.new()
		stake.mesh = stake_mesh
		stake.position = Vector3(sx, 0.08, 0)
		stake.rotation.z = 0.3 if sx < 0 else -0.3
		stake.material_override = wood_dark_mat
		tent.add_child(stake)

	# Ground cloth visible at entrance
	var ground_mat: StandardMaterial3D = StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.48, 0.44, 0.36)
	var ground_cloth: MeshInstance3D = MeshInstance3D.new()
	var gc_mesh: BoxMesh = BoxMesh.new()
	gc_mesh.size = Vector3(1.6, 0.02, 1.8)
	ground_cloth.mesh = gc_mesh
	ground_cloth.position = Vector3(0, 0.01, 0)
	ground_cloth.material_override = ground_mat
	tent.add_child(ground_cloth)

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

	# Materials
	var frame_mat: StandardMaterial3D = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.45, 0.32, 0.20)
	frame_mat.roughness = 0.88

	var frame_dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	frame_dark_mat.albedo_color = Color(0.36, 0.24, 0.14)
	frame_dark_mat.roughness = 0.90

	var frame_light_mat: StandardMaterial3D = StandardMaterial3D.new()
	frame_light_mat.albedo_color = Color(0.52, 0.38, 0.24)

	var blanket_mat: StandardMaterial3D = StandardMaterial3D.new()
	blanket_mat.albedo_color = Color(0.28, 0.42, 0.58)

	var blanket_dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	blanket_dark_mat.albedo_color = Color(0.22, 0.35, 0.50)

	var blanket_fold_mat: StandardMaterial3D = StandardMaterial3D.new()
	blanket_fold_mat.albedo_color = Color(0.32, 0.48, 0.62)

	var sheet_mat: StandardMaterial3D = StandardMaterial3D.new()
	sheet_mat.albedo_color = Color(0.88, 0.85, 0.78)

	var pillow_mat: StandardMaterial3D = StandardMaterial3D.new()
	pillow_mat.albedo_color = Color(0.92, 0.90, 0.84)

	var pillow_shadow_mat: StandardMaterial3D = StandardMaterial3D.new()
	pillow_shadow_mat.albedo_color = Color(0.82, 0.80, 0.74)

	# Bed frame base
	var frame: MeshInstance3D = MeshInstance3D.new()
	var frame_mesh: BoxMesh = BoxMesh.new()
	frame_mesh.size = Vector3(1.8, 0.25, 1.0)
	frame.mesh = frame_mesh
	frame.position.y = 0.125
	frame.material_override = frame_mat
	bed.add_child(frame)

	# Headboard (tall back panel)
	var headboard: MeshInstance3D = MeshInstance3D.new()
	var hb_mesh: BoxMesh = BoxMesh.new()
	hb_mesh.size = Vector3(0.08, 0.6, 1.0)
	headboard.mesh = hb_mesh
	headboard.position = Vector3(-0.86, 0.42, 0)
	headboard.material_override = frame_dark_mat
	bed.add_child(headboard)

	# Headboard cap (decorative top)
	var hb_cap: MeshInstance3D = MeshInstance3D.new()
	var hbc_mesh: BoxMesh = BoxMesh.new()
	hbc_mesh.size = Vector3(0.10, 0.04, 1.04)
	hb_cap.mesh = hbc_mesh
	hb_cap.position = Vector3(-0.86, 0.74, 0)
	hb_cap.material_override = frame_light_mat
	bed.add_child(hb_cap)

	# Headboard vertical slats
	for i: int in range(4):
		var slat: MeshInstance3D = MeshInstance3D.new()
		var sl_mesh: BoxMesh = BoxMesh.new()
		sl_mesh.size = Vector3(0.085, 0.58, 0.06)
		slat.mesh = sl_mesh
		slat.position = Vector3(-0.86, 0.42, -0.32 + i * 0.22)
		slat.material_override = frame_light_mat
		bed.add_child(slat)

	# Footboard (shorter)
	var footboard: MeshInstance3D = MeshInstance3D.new()
	var fb_mesh: BoxMesh = BoxMesh.new()
	fb_mesh.size = Vector3(0.08, 0.38, 1.0)
	footboard.mesh = fb_mesh
	footboard.position = Vector3(0.86, 0.32, 0)
	footboard.material_override = frame_dark_mat
	bed.add_child(footboard)

	# Side rails
	var rail_mesh: BoxMesh = BoxMesh.new()
	rail_mesh.size = Vector3(1.7, 0.06, 0.06)
	for rz: float in [-0.47, 0.47]:
		var rail: MeshInstance3D = MeshInstance3D.new()
		rail.mesh = rail_mesh
		rail.position = Vector3(0, 0.28, rz)
		rail.material_override = frame_dark_mat
		bed.add_child(rail)

	# Sheet layer (white, visible at head)
	var sheet: MeshInstance3D = MeshInstance3D.new()
	var sh_mesh: BoxMesh = BoxMesh.new()
	sh_mesh.size = Vector3(1.6, 0.04, 0.88)
	sheet.mesh = sh_mesh
	sheet.position = Vector3(0, 0.3, 0)
	sheet.material_override = sheet_mat
	bed.add_child(sheet)

	# Blanket/bedspread (main covering)
	var blanket: MeshInstance3D = MeshInstance3D.new()
	var blanket_mesh: BoxMesh = BoxMesh.new()
	blanket_mesh.size = Vector3(1.2, 0.12, 0.9)
	blanket.mesh = blanket_mesh
	blanket.position = Vector3(0.15, 0.36, 0)
	blanket.material_override = blanket_mat
	bed.add_child(blanket)

	# Blanket fold at top (turned-down edge)
	var fold: MeshInstance3D = MeshInstance3D.new()
	var fold_mesh: BoxMesh = BoxMesh.new()
	fold_mesh.size = Vector3(0.15, 0.14, 0.88)
	fold.mesh = fold_mesh
	fold.position = Vector3(-0.38, 0.37, 0)
	fold.material_override = blanket_fold_mat
	bed.add_child(fold)

	# Blanket wrinkle lines
	for i: int in range(3):
		var wrinkle: MeshInstance3D = MeshInstance3D.new()
		var wr_mesh: BoxMesh = BoxMesh.new()
		wr_mesh.size = Vector3(1.1, 0.015, 0.04)
		wrinkle.mesh = wr_mesh
		wrinkle.position = Vector3(0.15, 0.425, -0.2 + i * 0.2)
		wrinkle.material_override = blanket_dark_mat
		bed.add_child(wrinkle)

	# Pillow (with indent)
	var pillow: MeshInstance3D = MeshInstance3D.new()
	var pillow_mesh: BoxMesh = BoxMesh.new()
	pillow_mesh.size = Vector3(0.45, 0.14, 0.38)
	pillow.mesh = pillow_mesh
	pillow.position = Vector3(-0.58, 0.44, 0)
	pillow.material_override = pillow_mat
	bed.add_child(pillow)

	# Pillow shadow/indent
	var indent: MeshInstance3D = MeshInstance3D.new()
	var ind_mesh: BoxMesh = BoxMesh.new()
	ind_mesh.size = Vector3(0.25, 0.01, 0.2)
	indent.mesh = ind_mesh
	indent.position = Vector3(-0.58, 0.515, 0)
	indent.material_override = pillow_shadow_mat
	bed.add_child(indent)

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

	# Materials
	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.50, 0.38, 0.25)
	wood_mat.roughness = 0.88

	var wood_dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_dark_mat.albedo_color = Color(0.38, 0.26, 0.15)
	wood_dark_mat.roughness = 0.90

	var stone_mat: StandardMaterial3D = StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.50, 0.50, 0.52)
	stone_mat.roughness = 0.92

	var stone_dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	stone_dark_mat.albedo_color = Color(0.40, 0.40, 0.42)
	stone_dark_mat.roughness = 0.95

	var metal_mat: StandardMaterial3D = StandardMaterial3D.new()
	metal_mat.albedo_color = Color(0.30, 0.28, 0.26)
	metal_mat.metallic = 0.6
	metal_mat.roughness = 0.5

	var ember_mat: StandardMaterial3D = StandardMaterial3D.new()
	ember_mat.albedo_color = Color(0.8, 0.2, 0.0)
	ember_mat.emission_enabled = true
	ember_mat.emission = Color(0.7, 0.15, 0.0)
	ember_mat.emission_energy_multiplier = 1.5

	var fire_mat: StandardMaterial3D = StandardMaterial3D.new()
	fire_mat.albedo_color = Color(1.0, 0.5, 0.1)
	fire_mat.emission_enabled = true
	fire_mat.emission = Color(1.0, 0.4, 0.0)
	fire_mat.emission_energy_multiplier = 2.0

	var fire_tip_mat: StandardMaterial3D = StandardMaterial3D.new()
	fire_tip_mat.albedo_color = Color(1.0, 0.8, 0.3)
	fire_tip_mat.emission_enabled = true
	fire_tip_mat.emission = Color(1.0, 0.75, 0.2)
	fire_tip_mat.emission_energy_multiplier = 2.5

	# Counter/cabinet base
	var counter: MeshInstance3D = MeshInstance3D.new()
	var counter_mesh: BoxMesh = BoxMesh.new()
	counter_mesh.size = Vector3(1.5, 0.8, 0.8)
	counter.mesh = counter_mesh
	counter.position.y = 0.4
	counter.material_override = wood_mat
	kitchen.add_child(counter)

	# Cabinet door lines (panel detail)
	for i: int in range(3):
		var door_line: MeshInstance3D = MeshInstance3D.new()
		var dl_mesh: BoxMesh = BoxMesh.new()
		dl_mesh.size = Vector3(0.015, 0.7, 0.81)
		door_line.mesh = dl_mesh
		door_line.position = Vector3(-0.5 + i * 0.5, 0.4, 0)
		door_line.material_override = wood_dark_mat
		kitchen.add_child(door_line)

	# Cabinet handles
	for i: int in range(2):
		var handle: MeshInstance3D = MeshInstance3D.new()
		var h_mesh: BoxMesh = BoxMesh.new()
		h_mesh.size = Vector3(0.03, 0.08, 0.03)
		handle.mesh = h_mesh
		handle.position = Vector3(-0.22 + i * 0.5, 0.45, 0.41)
		handle.material_override = metal_mat
		kitchen.add_child(handle)

	# Stone cooking surface with individual stone blocks
	var surface: MeshInstance3D = MeshInstance3D.new()
	var surface_mesh: BoxMesh = BoxMesh.new()
	surface_mesh.size = Vector3(1.5, 0.1, 0.8)
	surface.mesh = surface_mesh
	surface.position.y = 0.85
	surface.material_override = stone_mat
	kitchen.add_child(surface)

	# Stone block lines on surface
	for i: int in range(4):
		var s_line: MeshInstance3D = MeshInstance3D.new()
		var sl_mesh: BoxMesh = BoxMesh.new()
		sl_mesh.size = Vector3(0.02, 0.101, 0.78)
		s_line.mesh = sl_mesh
		s_line.position = Vector3(-0.55 + i * 0.38, 0.85, 0)
		s_line.material_override = stone_dark_mat
		kitchen.add_child(s_line)

	# Stone hearth/firebox (raised stone area for fire)
	var hearth: MeshInstance3D = MeshInstance3D.new()
	var h_mesh: BoxMesh = BoxMesh.new()
	h_mesh.size = Vector3(0.5, 0.06, 0.5)
	hearth.mesh = h_mesh
	hearth.position = Vector3(0.4, 0.93, 0)
	hearth.material_override = stone_dark_mat
	kitchen.add_child(hearth)

	# Layered cooking fire
	# Embers
	var fire_ember: MeshInstance3D = MeshInstance3D.new()
	var fe_mesh: BoxMesh = BoxMesh.new()
	fe_mesh.size = Vector3(0.28, 0.04, 0.28)
	fire_ember.mesh = fe_mesh
	fire_ember.position = Vector3(0.4, 0.97, 0)
	fire_ember.material_override = ember_mat
	kitchen.add_child(fire_ember)

	# Main flame
	var fire: MeshInstance3D = MeshInstance3D.new()
	var fire_mesh: BoxMesh = BoxMesh.new()
	fire_mesh.size = Vector3(0.2, 0.18, 0.2)
	fire.mesh = fire_mesh
	fire.position = Vector3(0.4, 1.06, 0)
	fire.material_override = fire_mat
	kitchen.add_child(fire)

	# Flame tip
	var fire_top: MeshInstance3D = MeshInstance3D.new()
	var ft_mesh: BoxMesh = BoxMesh.new()
	ft_mesh.size = Vector3(0.1, 0.12, 0.1)
	fire_top.mesh = ft_mesh
	fire_top.position = Vector3(0.4, 1.18, 0)
	fire_top.material_override = fire_tip_mat
	kitchen.add_child(fire_top)

	# Cooking pot on the fire
	var pot_mat: StandardMaterial3D = StandardMaterial3D.new()
	pot_mat.albedo_color = Color(0.18, 0.18, 0.20)
	pot_mat.metallic = 0.5
	pot_mat.roughness = 0.6
	var pot: MeshInstance3D = MeshInstance3D.new()
	var pot_mesh: BoxMesh = BoxMesh.new()
	pot_mesh.size = Vector3(0.22, 0.18, 0.22)
	pot.mesh = pot_mesh
	pot.position = Vector3(0.4, 1.05, 0)
	pot.material_override = pot_mat
	kitchen.add_child(pot)

	# Pot handle (arching over)
	var pot_handle: MeshInstance3D = MeshInstance3D.new()
	var ph_mesh: BoxMesh = BoxMesh.new()
	ph_mesh.size = Vector3(0.18, 0.02, 0.02)
	pot_handle.mesh = ph_mesh
	pot_handle.position = Vector3(0.4, 1.18, 0)
	pot_handle.material_override = metal_mat
	kitchen.add_child(pot_handle)

	# Small shelf above counter
	var shelf: MeshInstance3D = MeshInstance3D.new()
	var sh_mesh: BoxMesh = BoxMesh.new()
	sh_mesh.size = Vector3(0.8, 0.04, 0.25)
	shelf.mesh = sh_mesh
	shelf.position = Vector3(-0.3, 1.3, -0.28)
	shelf.material_override = wood_dark_mat
	kitchen.add_child(shelf)

	# Shelf brackets
	var bracket_mesh: BoxMesh = BoxMesh.new()
	bracket_mesh.size = Vector3(0.04, 0.15, 0.04)
	for bx: float in [-0.6, 0.0]:
		var bracket: MeshInstance3D = MeshInstance3D.new()
		bracket.mesh = bracket_mesh
		bracket.position = Vector3(bx, 1.22, -0.28)
		bracket.material_override = wood_dark_mat
		kitchen.add_child(bracket)

	# Items on shelf (small jars/bowls)
	var jar_mat: StandardMaterial3D = StandardMaterial3D.new()
	jar_mat.albedo_color = Color(0.55, 0.45, 0.35)
	var jar: MeshInstance3D = MeshInstance3D.new()
	var j_mesh: BoxMesh = BoxMesh.new()
	j_mesh.size = Vector3(0.08, 0.12, 0.08)
	jar.mesh = j_mesh
	jar.position = Vector3(-0.5, 1.38, -0.28)
	jar.material_override = jar_mat
	kitchen.add_child(jar)

	var bowl_mat: StandardMaterial3D = StandardMaterial3D.new()
	bowl_mat.albedo_color = Color(0.50, 0.42, 0.30)
	var bowl: MeshInstance3D = MeshInstance3D.new()
	var b_mesh: BoxMesh = BoxMesh.new()
	b_mesh.size = Vector3(0.12, 0.06, 0.12)
	bowl.mesh = b_mesh
	bowl.position = Vector3(-0.2, 1.35, -0.28)
	bowl.material_override = bowl_mat
	kitchen.add_child(bowl)

	# Knife on counter surface
	var knife_blade: MeshInstance3D = MeshInstance3D.new()
	var kb_mesh: BoxMesh = BoxMesh.new()
	kb_mesh.size = Vector3(0.12, 0.01, 0.025)
	knife_blade.mesh = kb_mesh
	knife_blade.position = Vector3(-0.3, 0.91, 0.15)
	knife_blade.rotation.y = 0.4
	knife_blade.material_override = metal_mat
	kitchen.add_child(knife_blade)

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
