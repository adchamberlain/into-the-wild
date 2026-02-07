extends StructureBase
class_name StructureLodestone
## A lodestone beacon placed in the world. Works with compass for navigation.
## Can be picked up like a torch.


func _ready() -> void:
	super._ready()
	structure_type = "lodestone"
	structure_name = "Lodestone"
	interaction_text = "Pick Up Lodestone"


func interact(player: Node) -> bool:
	if not is_active:
		return false

	# Reclaim the lodestone - add back to player inventory
	var inventory: Node = null
	if player.has_method("get_inventory"):
		inventory = player.get_inventory()

	if inventory and inventory.has_method("add_item"):
		inventory.add_item("lodestone", 1)
		SFXManager.play_sfx("pickup")
		_show_notification("Picked up lodestone", Color(1.0, 0.85, 0.3))

		# Remove from campsite manager
		_unregister_from_campsite()

		# Destroy the placed lodestone
		destroy()
		return true

	return false


func get_interaction_text() -> String:
	return "Pick Up Lodestone"


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
