extends StructureBase
class_name StructureShelter
## Shelter structure that provides weather protection.

signal player_entered()
signal player_exited()

# Shelter properties
@export var protection_radius: float = 3.0

# State
var player_inside: bool = false

# Node references
var protection_area: Area3D


func _ready() -> void:
	super._ready()
	structure_type = "basic_shelter"
	structure_name = "Basic Shelter"
	interaction_text = "Rest"

	# Find child nodes
	protection_area = get_node_or_null("ProtectionArea")

	# Connect area signals if present
	if protection_area:
		protection_area.body_entered.connect(_on_body_entered)
		protection_area.body_exited.connect(_on_body_exited)


func interact(player: Node) -> bool:
	if not super.interact(player):
		return false

	# Rest in the shelter - restore some stats
	if player.has_node("PlayerStats"):
		var stats: Node = player.get_node("PlayerStats")
		if stats.has_method("heal"):
			stats.heal(10.0)
			print("[Shelter] You rest in the shelter and recover some health (+10)")
		if stats.has_method("restore_hunger"):
			# Resting doesn't restore hunger, but slows its drain
			pass
	else:
		print("[Shelter] You rest in the shelter, sheltered from the elements")

	return true


func get_interaction_text() -> String:
	return "Rest in Shelter"


## Check if a position is within protection radius.
func is_in_protection_range(pos: Vector3) -> bool:
	return global_position.distance_to(pos) <= protection_radius


## Check if player is currently inside shelter.
func is_player_protected() -> bool:
	return player_inside


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		player_inside = true
		player_entered.emit()
		print("[Shelter] Player entered shelter")


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		player_inside = false
		player_exited.emit()
		print("[Shelter] Player left shelter")
