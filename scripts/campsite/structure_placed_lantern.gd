extends StructureBase
class_name StructurePlacedLantern
## A lantern placed on the ground that provides bright light. Can be reclaimed.

# Light properties
@export var light_energy: float = 16.0
@export var light_range: float = 30.0
@export var light_color: Color = Color(0.9, 0.95, 1.0)

# Node references
var lantern_light: OmniLight3D


func _ready() -> void:
	super._ready()
	structure_type = "placed_lantern"
	structure_name = "Lantern"
	interaction_text = "Pick Up Lantern"

	# Find the light node
	lantern_light = get_node_or_null("LanternLight")

	# Add subtle flicker effect
	_start_flicker()


func _start_flicker() -> void:
	if not lantern_light:
		return

	var tween: Tween = create_tween()
	tween.set_loops()
	tween.tween_property(lantern_light, "light_energy", light_energy * 0.92, 0.2)
	tween.tween_property(lantern_light, "light_energy", light_energy * 1.05, 0.25)
	tween.tween_property(lantern_light, "light_energy", light_energy * 0.95, 0.18)
	tween.tween_property(lantern_light, "light_energy", light_energy, 0.22)


func interact(player: Node) -> bool:
	if not is_active:
		return false

	# Reclaim the lantern - add back to player inventory
	var inventory: Node = null
	if player.has_method("get_inventory"):
		inventory = player.get_inventory()

	# Check capacity before picking up
	if inventory and inventory.has_method("can_add_item") and not inventory.can_add_item("lantern", 1):
		_show_notification("Can't carry more lanterns. Store items first.", Color(1.0, 0.5, 0.5))
		return false

	if inventory and inventory.has_method("add_item"):
		inventory.add_item("lantern", 1)
		SFXManager.play_sfx("pickup")
		_show_notification("Picked up lantern", Color(0.9, 0.95, 1.0))

		# Destroy (triggers structure_destroyed signal -> campsite manager unregistration)
		destroy()
		return true

	return false


func get_interaction_text() -> String:
	return "Pick Up Lantern"


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
	var campsite_manager: Node = get_node_or_null("/root/Main/CampsiteManager")
	if campsite_manager and campsite_manager.has_method("unregister_structure"):
		campsite_manager.unregister_structure(self, structure_type)
