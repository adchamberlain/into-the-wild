extends StructureBase
class_name StructureCabin
## Log cabin - the ultimate shelter with walkable interior, bed, and kitchen.

signal player_entered_cabin()
signal player_exited_cabin()

# Cabin configuration
const CABIN_SIZE: Vector3 = Vector3(6.0, 4.0, 5.0)  # Width x Height x Depth
const WALL_THICKNESS: float = 0.3
const DOOR_WIDTH: float = 1.2
const DOOR_HEIGHT: float = 2.2

# Interior components
var bed: Node3D = null
var kitchen: Node3D = null
var player_inside: bool = false

# Protection
var protection_area: Area3D = null


func _ready() -> void:
	super._ready()
	structure_type = "cabin"
	structure_name = "Log Cabin"
	interaction_text = "Enter Cabin"


func interact(player: Node) -> bool:
	if not is_active:
		return false

	# Cabin itself doesn't have direct interaction -
	# player walks in through the door
	# Interior objects (bed, kitchen) handle their own interactions
	print("[Cabin] Welcome to your cabin!")
	return true


func get_interaction_text() -> String:
	return "Your Cabin"


## Check if player is inside the cabin.
func is_player_in_cabin() -> bool:
	return player_inside


## Get the bed component.
func get_bed() -> Node3D:
	return bed


## Get the kitchen component.
func get_kitchen() -> Node3D:
	return kitchen


func _on_protection_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		player_inside = true
		player_entered_cabin.emit()
		print("[Cabin] Player entered cabin")


func _on_protection_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		player_inside = false
		player_exited_cabin.emit()
		print("[Cabin] Player left cabin")


## Check if a position is within the cabin's protection.
func is_in_protection_range(pos: Vector3) -> bool:
	# Check if position is inside cabin bounds
	var local_pos: Vector3 = to_local(pos)
	var half_size: Vector3 = CABIN_SIZE / 2.0
	return (abs(local_pos.x) < half_size.x and
			abs(local_pos.z) < half_size.z and
			local_pos.y >= 0 and local_pos.y < CABIN_SIZE.y)
