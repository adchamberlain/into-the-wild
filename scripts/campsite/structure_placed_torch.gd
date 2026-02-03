extends StructureBase
class_name StructurePlacedTorch
## A torch placed on the ground that provides light. Can be reclaimed.

# Light properties
@export var light_energy: float = 8.0
@export var light_range: float = 15.0
@export var light_color: Color = Color(1.0, 0.8, 0.4)

# Node references
var torch_light: OmniLight3D


func _ready() -> void:
	super._ready()
	structure_type = "placed_torch"
	structure_name = "Torch"
	interaction_text = "Pick Up Torch"

	# Find the light node
	torch_light = get_node_or_null("TorchLight")

	# Add subtle flicker effect
	_start_flicker()


func _start_flicker() -> void:
	if not torch_light:
		return

	# Create a looping flicker animation
	var tween: Tween = create_tween()
	tween.set_loops()
	tween.tween_property(torch_light, "light_energy", light_energy * 0.85, 0.1)
	tween.tween_property(torch_light, "light_energy", light_energy * 1.1, 0.15)
	tween.tween_property(torch_light, "light_energy", light_energy * 0.9, 0.12)
	tween.tween_property(torch_light, "light_energy", light_energy, 0.13)


func interact(player: Node) -> bool:
	if not is_active:
		return false

	# Reclaim the torch - add back to player inventory
	var inventory: Node = null
	if player.has_method("get_inventory"):
		inventory = player.get_inventory()

	if inventory and inventory.has_method("add_item"):
		inventory.add_item("torch", 1)
		SFXManager.play_sfx("pickup")
		_show_notification("Picked up torch", Color(1.0, 0.85, 0.5))

		# Remove from campsite manager
		_unregister_from_campsite()

		# Destroy the placed torch
		destroy()
		return true

	return false


func get_interaction_text() -> String:
	return "Pick Up Torch"


func _show_notification(message: String, color: Color) -> void:
	var hud: Node = _find_hud()
	if hud and hud.has_method("show_notification"):
		hud.show_notification(message, color)


func _find_hud() -> Node:
	var root: Node = get_tree().root
	if root.has_node("Main/HUD"):
		return root.get_node("Main/HUD")
	return null


func _unregister_from_campsite() -> void:
	# Remove from campsite manager's structure list
	var campsite_manager: Node = get_node_or_null("/root/Main/CampsiteManager")
	if campsite_manager and campsite_manager.has_method("unregister_structure"):
		campsite_manager.unregister_structure(self, structure_type)
