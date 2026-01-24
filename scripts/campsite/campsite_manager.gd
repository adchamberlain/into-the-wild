extends Node
class_name CampsiteManager
## Manages campsite state, placed structures, and progression.

signal structure_added(structure: Node, structure_type: String)
signal structure_removed(structure: Node, structure_type: String)
signal campsite_level_changed(new_level: int)

# Campsite level requirements
const LEVEL_REQUIREMENTS: Dictionary = {
	1: {
		"description": "Survival Camp",
		"requirements": []  # Start at level 1
	},
	2: {
		"description": "Established Camp",
		"requirements": ["has_fire_pit", "has_shelter", "has_crafted_tool"]
	},
	3: {
		"description": "Homestead",
		"requirements": ["has_storage", "has_multiple_structures"]
	}
}

# Current campsite state
var campsite_level: int = 1
var placed_structures: Array[Node] = []
var structure_counts: Dictionary = {}  # structure_type -> count

# Progress flags
var has_crafted_tool: bool = false

# References
@export var player_path: NodePath
@export var crafting_system_path: NodePath

var player: Node
var crafting_system: Node


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


## Register a newly placed structure.
func register_structure(structure: Node, structure_type: String) -> void:
	if structure in placed_structures:
		return

	placed_structures.append(structure)

	# Update counts
	if not structure_counts.has(structure_type):
		structure_counts[structure_type] = 0
	structure_counts[structure_type] += 1

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

	structure_removed.emit(structure, structure_type)
	print("[CampsiteManager] Removed %s" % structure_type)


## Get current campsite level.
func get_level() -> int:
	return campsite_level


## Get level description.
func get_level_description() -> String:
	var level_data: Dictionary = LEVEL_REQUIREMENTS.get(campsite_level, {})
	return level_data.get("description", "Camp Level %d" % campsite_level)


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
		campsite_level = next_level
		campsite_level_changed.emit(campsite_level)
		print("[CampsiteManager] *** LEVEL UP! Now at level %d: %s ***" % [campsite_level, get_level_description()])

		# Check for further level ups
		_check_level_progression()


## Check if a specific requirement is met.
func _check_requirement(requirement: String) -> bool:
	match requirement:
		"has_fire_pit":
			return has_structure("fire_pit")
		"has_shelter":
			return has_structure("basic_shelter")
		"has_crafted_tool":
			return has_crafted_tool
		"has_storage":
			return has_structure("storage_container")
		"has_multiple_structures":
			return get_total_structure_count() >= 3
	return false


## Called when a recipe is crafted.
func _on_recipe_crafted(recipe_id: String, _output_type: String, _output_amount: int) -> void:
	# Check for tool crafting
	if recipe_id == "stone_axe" and not has_crafted_tool:
		has_crafted_tool = true
		print("[CampsiteManager] Tool crafted - progression flag set")
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
func is_near_fire(player_pos: Vector3, max_distance: float = 5.0) -> bool:
	for structure: Node in placed_structures:
		if structure.has_method("is_in_warmth_range"):
			if structure.is_in_warmth_range(player_pos):
				return true
		elif structure.has_method("get") and structure.get("structure_type") == "fire_pit":
			if structure.global_position.distance_to(player_pos) <= max_distance:
				return true
	return false


## Check if player is in any shelter.
func is_in_shelter(player_pos: Vector3) -> bool:
	for structure: Node in placed_structures:
		if structure.has_method("is_in_protection_range"):
			if structure.is_in_protection_range(player_pos):
				return true
	return false
