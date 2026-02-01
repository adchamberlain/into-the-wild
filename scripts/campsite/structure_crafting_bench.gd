extends StructureBase
class_name StructureCraftingBench
## Crafting bench structure that opens the crafting UI when interacted with.


func _ready() -> void:
	super._ready()
	structure_type = "crafting_bench"
	structure_name = "Crafting Bench"
	interaction_text = "Use Bench"


func interact(player: Node) -> bool:
	if not is_active:
		return false

	# Open crafting UI with bench context (enables advanced recipes)
	var crafting_ui: Node = _find_crafting_ui()
	if crafting_ui and crafting_ui.has_method("toggle_crafting_menu"):
		crafting_ui.toggle_crafting_menu(true)  # true = at bench
		return true
	elif crafting_ui and crafting_ui.has_method("show"):
		crafting_ui.show()
		return true

	print("[CraftingBench] Could not find crafting UI")
	return false


func get_interaction_text() -> String:
	return "Open Crafting"


func _find_crafting_ui() -> Node:
	var root: Node = get_tree().root
	if root.has_node("Main/CraftingUI"):
		return root.get_node("Main/CraftingUI")
	var uis: Array = get_tree().get_nodes_in_group("crafting_ui")
	if not uis.is_empty():
		return uis[0]
	return null
