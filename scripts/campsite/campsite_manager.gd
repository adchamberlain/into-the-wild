extends Node
class_name CampsiteManager
## Manages campsite state, placed structures, and progression.

signal structure_added(structure: Node, structure_type: String)
signal structure_removed(structure: Node, structure_type: String)
signal campsite_level_changed(new_level: int)

# Campsite level requirements
const LEVEL_REQUIREMENTS: Dictionary = {
	1: {
		"name": "Survival Camp",
		"description": "Basic survival - you just arrived",
		"requirements": [],  # Start at level 1
		"unlocks": []
	},
	2: {
		"name": "Functional Camp",
		"description": "Ready for a longer stay",
		"requirements": ["has_fire_pit", "has_shelter", "has_crafting_bench", "has_drying_rack", "has_crafted_fishing_rod"],
		"unlocks": ["Canvas Tent", "Herb Garden Plot"]
	},
	3: {
		"name": "Wilderness Basecamp",
		"description": "A true home in the wild",
		"requirements": ["has_canvas_tent", "has_storage", "has_garden", "has_six_structures", "survived_three_days_at_level_2"],
		"unlocks": ["LOG CABIN - Walk-in home with bed and kitchen!"]
	}
}

# Current campsite state
var campsite_level: int = 1
var placed_structures: Array[Node] = []
var structure_counts: Dictionary = {}  # structure_type -> count

# Performance: cached arrays for frequently-queried structure types
var _cached_fire_pits: Array[Node] = []
var _cached_shelters: Array[Node] = []

# Progress flags
var has_crafted_tool: bool = false
var has_crafted_fishing_rod: bool = false
var days_at_level_2: int = 0
var level_2_start_day: int = -1

# References
@export var player_path: NodePath
@export var crafting_system_path: NodePath
@export var time_manager_path: NodePath

var player: Node
var crafting_system: Node
var time_manager: Node


func _ready() -> void:
	# Get references
	if player_path:
		player = get_node_or_null(player_path)
	if crafting_system_path:
		crafting_system = get_node_or_null(crafting_system_path)
	elif player:
		# Try to find crafting system as sibling
		crafting_system = get_parent().get_node_or_null("CraftingUI")

	# Connect to crafting system signals
	if crafting_system and crafting_system.has_signal("recipe_crafted"):
		crafting_system.recipe_crafted.connect(_on_recipe_crafted)

	# Connect to player's placement system
	call_deferred("_connect_to_placement_system")

	# Connect to time manager for day tracking
	call_deferred("_connect_to_time_manager")

	print("[CampsiteManager] Initialized at level %d" % campsite_level)


func _connect_to_placement_system() -> void:
	if not player:
		if player_path:
			player = get_node_or_null(player_path)
		if not player:
			# Try to find player in parent
			player = get_parent().get_node_or_null("Player")

	if player:
		var placement_system: Node = player.get_node_or_null("PlacementSystem")
		if placement_system:
			placement_system.set_campsite_manager(self)
			print("[CampsiteManager] Connected to PlacementSystem")


func _connect_to_time_manager() -> void:
	if time_manager_path:
		time_manager = get_node_or_null(time_manager_path)
	if not time_manager:
		time_manager = get_parent().get_node_or_null("TimeManager")

	if time_manager and time_manager.has_signal("day_changed"):
		time_manager.day_changed.connect(_on_day_changed)
		print("[CampsiteManager] Connected to TimeManager")


func _on_day_changed(new_day: int) -> void:
	# Track days spent at level 2
	if campsite_level == 2:
		if level_2_start_day < 0:
			level_2_start_day = new_day
		days_at_level_2 = new_day - level_2_start_day
		print("[CampsiteManager] Days at Level 2: %d" % days_at_level_2)
		_check_level_progression()


## Register a newly placed structure.
func register_structure(structure: Node, structure_type: String) -> void:
	if structure in placed_structures:
		return

	placed_structures.append(structure)

	# Update counts
	if not structure_counts.has(structure_type):
		structure_counts[structure_type] = 0
	structure_counts[structure_type] += 1

	# Update cached arrays for performance
	if structure_type == "fire_pit":
		_cached_fire_pits.append(structure)
	if structure.has_method("is_in_protection_range"):
		_cached_shelters.append(structure)

	# Connect to destruction signal
	if structure.has_signal("structure_destroyed"):
		structure.structure_destroyed.connect(_on_structure_destroyed.bind(structure, structure_type))

	structure_added.emit(structure, structure_type)
	print("[CampsiteManager] Registered %s (total: %d structures)" % [structure_type, placed_structures.size()])

	# Check for level up
	_check_level_progression()


## Unregister a removed structure.
func unregister_structure(structure: Node, structure_type: String) -> void:
	var idx: int = placed_structures.find(structure)
	if idx != -1:
		placed_structures.remove_at(idx)

	if structure_counts.has(structure_type):
		structure_counts[structure_type] -= 1
		if structure_counts[structure_type] <= 0:
			structure_counts.erase(structure_type)

	# Update cached arrays
	var fire_idx: int = _cached_fire_pits.find(structure)
	if fire_idx != -1:
		_cached_fire_pits.remove_at(fire_idx)
	var shelter_idx: int = _cached_shelters.find(structure)
	if shelter_idx != -1:
		_cached_shelters.remove_at(shelter_idx)

	structure_removed.emit(structure, structure_type)
	print("[CampsiteManager] Removed %s" % structure_type)


## Get current campsite level.
func get_level() -> int:
	return campsite_level


## Get level description.
func get_level_description() -> String:
	var level_data: Dictionary = LEVEL_REQUIREMENTS.get(campsite_level, {})
	return level_data.get("name", "Camp Level %d" % campsite_level)


## Get full level info for celebrations.
func get_level_info(level: int) -> Dictionary:
	return LEVEL_REQUIREMENTS.get(level, {})


## Get count of a specific structure type.
func get_structure_count(structure_type: String) -> int:
	return structure_counts.get(structure_type, 0)


## Check if campsite has a structure of a specific type.
func has_structure(structure_type: String) -> bool:
	return get_structure_count(structure_type) > 0


## Get all structures of a specific type.
func get_structures_of_type(structure_type: String) -> Array[Node]:
	var result: Array[Node] = []
	for structure: Node in placed_structures:
		if structure.has_method("get") and structure.get("structure_type") == structure_type:
			result.append(structure)
		elif structure.name.to_lower().contains(structure_type.replace("_", "")):
			result.append(structure)
	return result


## Get total number of placed structures.
func get_total_structure_count() -> int:
	return placed_structures.size()


## Check level progression and level up if requirements met.
func _check_level_progression() -> void:
	var next_level: int = campsite_level + 1

	if not LEVEL_REQUIREMENTS.has(next_level):
		return  # Already at max level

	var requirements: Array = LEVEL_REQUIREMENTS[next_level].get("requirements", [])
	var all_met: bool = true

	for req: String in requirements:
		if not _check_requirement(req):
			all_met = false
			break

	if all_met:
		var old_level: int = campsite_level
		campsite_level = next_level
		campsite_level_changed.emit(campsite_level)
		print("[CampsiteManager] *** LEVEL UP! Now at level %d: %s ***" % [campsite_level, get_level_description()])

		# Start tracking days at level 2
		if campsite_level == 2 and old_level == 1:
			if time_manager and "current_day" in time_manager:
				level_2_start_day = time_manager.current_day
				days_at_level_2 = 0
				print("[CampsiteManager] Started tracking days at Level 2")

		# Check for further level ups
		_check_level_progression()


## Check if a specific requirement is met.
func _check_requirement(requirement: String) -> bool:
	match requirement:
		"has_fire_pit":
			return has_structure("fire_pit")
		"has_shelter":
			return has_structure("basic_shelter") or has_structure("canvas_tent")
		"has_crafting_bench":
			return has_structure("crafting_bench")
		"has_drying_rack":
			return has_structure("drying_rack")
		"has_crafted_tool":
			return has_crafted_tool
		"has_crafted_fishing_rod":
			return has_crafted_fishing_rod
		"has_canvas_tent":
			return has_structure("canvas_tent")
		"has_storage":
			return has_structure("storage_container")
		"has_garden":
			return has_structure("herb_garden")
		"has_six_structures":
			return get_total_structure_count() >= 6
		"has_multiple_structures":
			return get_total_structure_count() >= 3
		"survived_three_days_at_level_2":
			return days_at_level_2 >= 3
	return false


## Called when a recipe is crafted.
func _on_recipe_crafted(recipe_id: String, _output_type: String, _output_amount: int) -> void:
	var progression_check_needed: bool = false

	# Check for tool crafting
	if recipe_id == "stone_axe" and not has_crafted_tool:
		has_crafted_tool = true
		print("[CampsiteManager] Tool crafted - progression flag set")
		progression_check_needed = true

	# Check for fishing rod crafting
	if recipe_id == "fishing_rod" and not has_crafted_fishing_rod:
		has_crafted_fishing_rod = true
		print("[CampsiteManager] Fishing rod crafted - progression flag set")
		progression_check_needed = true

	if progression_check_needed:
		_check_level_progression()


## Called when a structure is destroyed.
func _on_structure_destroyed(structure: Node, structure_type: String) -> void:
	unregister_structure(structure, structure_type)


## Get all fire pits (for warmth checking).
func get_fire_pits() -> Array[Node]:
	return get_structures_of_type("fire_pit")


## Get all shelters (for protection checking).
func get_shelters() -> Array[Node]:
	return get_structures_of_type("basic_shelter")


## Check if player is near any fire (for warmth).
## Uses cached fire pit array for performance.
func is_near_fire(player_pos: Vector3, max_distance: float = 5.0) -> bool:
	for structure: Node in _cached_fire_pits:
		if not is_instance_valid(structure):
			continue
		if structure.has_method("is_in_warmth_range"):
			if structure.is_in_warmth_range(player_pos):
				return true
		elif structure.global_position.distance_to(player_pos) <= max_distance:
			return true
	return false


## Check if player is in any shelter.
## Uses cached shelter array for performance.
func is_in_shelter(player_pos: Vector3) -> bool:
	for structure: Node in _cached_shelters:
		if not is_instance_valid(structure):
			continue
		if structure.is_in_protection_range(player_pos):
			return true
	return false
