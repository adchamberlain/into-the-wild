extends StaticBody3D
class_name StructureBase
## Base class for all placeable structures (campfires, shelters, storage).

signal structure_placed()
signal structure_destroyed()

# Structure properties
@export var structure_type: String = "generic"
@export var structure_name: String = "Structure"
@export var interaction_text: String = "Interact"

# State
var is_active: bool = true


func _ready() -> void:
	# Add to groups for raycast detection and tracking
	add_to_group("interactable")
	add_to_group("structure")


## Called when player interacts with this structure. Override in subclasses.
func interact(player: Node) -> bool:
	if not is_active:
		return false
	print("[Structure] Interacted with %s" % structure_name)
	return true


## Get the text to show in interaction prompt.
func get_interaction_text() -> String:
	return interaction_text


## Called when structure is first placed in the world.
func on_placed() -> void:
	print("[Structure] %s placed at %s" % [structure_name, global_position])
	structure_placed.emit()


## Destroy this structure.
func destroy() -> void:
	is_active = false
	structure_destroyed.emit()
	queue_free()


## Get save data for this structure. Override in subclasses to add custom data.
func get_save_data() -> Dictionary:
	return {
		"structure_type": structure_type,
		"position": {"x": global_position.x, "y": global_position.y, "z": global_position.z},
		"rotation_y": rotation.y,
		"is_active": is_active
	}


## Load save data for this structure. Override in subclasses to load custom data.
func load_save_data(data: Dictionary) -> void:
	is_active = data.get("is_active", true)
