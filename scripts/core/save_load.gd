extends Node
class_name SaveLoad
## Handles saving and loading game state to/from JSON files.

signal game_saved(filepath: String)
signal game_loaded(filepath: String)
signal save_failed(error: String)
signal load_failed(error: String)

const SAVE_DIR: String = "user://saves/"
const SAVE_FILE: String = "save.json"
const SAVE_VERSION: int = 1

# Node references (set in _ready or via exported paths)
@export var player_path: NodePath
@export var time_manager_path: NodePath
@export var weather_manager_path: NodePath
@export var campsite_manager_path: NodePath
@export var resource_manager_path: NodePath
@export var crafting_system_path: NodePath

var player: Node
var time_manager: Node
var weather_manager: Node
var campsite_manager: Node
var resource_manager: Node
var crafting_system: Node


func _ready() -> void:
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

	# CraftingSystem is created dynamically by CraftingUI, so defer lookup
	call_deferred("_get_crafting_system")

	# Ensure save directory exists
	_ensure_save_directory()


func _get_crafting_system() -> void:
	if crafting_system_path:
		var crafting_ui: Node = get_node_or_null(crafting_system_path)
		if crafting_ui and "crafting_system" in crafting_ui:
			crafting_system = crafting_ui.crafting_system


func _ensure_save_directory() -> void:
	var dir: DirAccess = DirAccess.open("user://")
	if dir and not dir.dir_exists("saves"):
		dir.make_dir("saves")


## Save the current game state.
func save_game() -> bool:
	var save_data: Dictionary = _collect_save_data()

	var filepath: String = SAVE_DIR + SAVE_FILE
	var file: FileAccess = FileAccess.open(filepath, FileAccess.WRITE)

	if not file:
		var error: String = "Failed to open save file: %s" % filepath
		push_error(error)
		save_failed.emit(error)
		return false

	var json_string: String = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()

	print("[SaveLoad] Game saved to %s" % filepath)
	game_saved.emit(filepath)
	return true


## Load the game state from file.
func load_game() -> bool:
	var filepath: String = SAVE_DIR + SAVE_FILE

	if not FileAccess.file_exists(filepath):
		var error: String = "No save file found at %s" % filepath
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

	_apply_save_data(save_data)

	print("[SaveLoad] Game loaded from %s" % filepath)
	game_loaded.emit(filepath)
	return true


## Check if a save file exists.
func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_DIR + SAVE_FILE)


## Delete the save file.
func delete_save() -> bool:
	var filepath: String = SAVE_DIR + SAVE_FILE
	if FileAccess.file_exists(filepath):
		var dir: DirAccess = DirAccess.open(SAVE_DIR)
		if dir:
			dir.remove(SAVE_FILE)
			print("[SaveLoad] Save file deleted")
			return true
	return false


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
	# Apply in reverse order of dependencies

	# Time first (weather depends on it)
	if data.has("time") and time_manager:
		_apply_time_data(data["time"])

	# Weather
	if data.has("weather") and weather_manager:
		_apply_weather_data(data["weather"])

	# Resources (before player loads in)
	if data.has("resources") and resource_manager:
		_apply_resource_data(data["resources"])

	# Crafting
	if data.has("crafting") and crafting_system:
		_apply_crafting_data(data["crafting"])

	# Campsite (structures)
	if data.has("campsite") and campsite_manager:
		_apply_campsite_data(data["campsite"])

	# Player last (position, stats, inventory)
	if data.has("player") and player:
		_apply_player_data(data["player"])


func _apply_player_data(data: Dictionary) -> void:
	# Position
	if data.has("position"):
		var pos: Dictionary = data["position"]
		player.global_position = Vector3(pos["x"], pos["y"], pos["z"])

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

	# NOTE: We intentionally do NOT emit campsite_level_changed here
	# to avoid showing the level-up celebration when loading a saved game.
	# The HUD will update its display when it receives game_loaded signal.


func _recreate_structure(struct_data: Dictionary, container: Node) -> void:
	var structure_type: String = struct_data.get("type", "")
	var pos_data: Dictionary = struct_data.get("position", {})
	var position: Vector3 = Vector3(
		pos_data.get("x", 0),
		pos_data.get("y", 0),
		pos_data.get("z", 0)
	)

	# Get scene path from StructureData
	var scene_path: String = ""
	match structure_type:
		"fire_pit":
			scene_path = "res://scenes/campsite/structures/fire_pit.tscn"
		"basic_shelter":
			scene_path = "res://scenes/campsite/structures/basic_shelter.tscn"
		"storage_container":
			scene_path = "res://scenes/campsite/structures/storage_container.tscn"
		"crafting_bench":
			scene_path = "res://scenes/campsite/structures/crafting_bench.tscn"

	if scene_path == "":
		push_warning("[SaveLoad] Unknown structure type: %s" % structure_type)
		return

	var scene: PackedScene = load(scene_path)
	if not scene:
		push_warning("[SaveLoad] Failed to load structure scene: %s" % scene_path)
		return

	var structure: Node3D = scene.instantiate()
	structure.global_position = position

	if container:
		container.add_child(structure)

	# Register with campsite manager
	campsite_manager.register_structure(structure, structure_type)

	# Restore state
	if struct_data.has("is_lit") and structure.has_method("_set_fire_state"):
		structure._set_fire_state(struct_data["is_lit"])

	print("[SaveLoad] Recreated structure: %s at %s" % [structure_type, position])
