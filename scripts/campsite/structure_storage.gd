extends StructureBase
class_name StructureStorage
## Storage container structure with its own inventory.

signal storage_opened()
signal storage_closed()

# Storage properties
@export var max_slots: int = 20

# Storage inventory
var storage_inventory: Inventory

# State
var is_open: bool = false


func _ready() -> void:
	super._ready()
	structure_type = "storage_container"
	structure_name = "Storage Box"
	interaction_text = "Open Storage"

	# Create storage inventory
	storage_inventory = Inventory.new()
	storage_inventory.name = "StorageInventory"
	add_child(storage_inventory)


func interact(player: Node) -> bool:
	if not super.interact(player):
		return false

	# Toggle storage open/closed
	if is_open:
		close_storage()
	else:
		open_storage(player)

	return true


func get_interaction_text() -> String:
	if is_open:
		return "Close Storage"
	else:
		return "Open Storage"


## Open storage and show contents.
func open_storage(player: Node) -> void:
	is_open = true
	storage_opened.emit()

	# Try to find and open the storage UI
	var storage_ui: Node = _find_storage_ui()
	if storage_ui and storage_ui.has_method("open_storage"):
		storage_ui.open_storage(self)
	else:
		# Fallback to console output
		print("[Storage] === Storage Contents ===")
		var items: Dictionary = storage_inventory.get_all_items()
		if items.is_empty():
			print("[Storage] (empty)")
		else:
			for item_type: String in items:
				print("[Storage] %s: %d" % [item_type.capitalize(), items[item_type]])


func _find_storage_ui() -> Node:
	# Look for StorageUI in the scene tree
	var root: Node = get_tree().root
	if root.has_node("Main/StorageUI"):
		return root.get_node("Main/StorageUI")
	# Try to find it elsewhere
	var storage_uis: Array = get_tree().get_nodes_in_group("storage_ui")
	if not storage_uis.is_empty():
		return storage_uis[0]
	return null


## Close storage.
func close_storage() -> void:
	is_open = false
	storage_closed.emit()
	print("[Storage] Closed storage")


## Add item to storage.
func add_item(item_type: String, amount: int = 1) -> int:
	return storage_inventory.add_item(item_type, amount)


## Remove item from storage.
func remove_item(item_type: String, amount: int = 1) -> bool:
	return storage_inventory.remove_item(item_type, amount)


## Check if storage has an item.
func has_item(item_type: String, amount: int = 1) -> bool:
	return storage_inventory.has_item(item_type, amount)


## Get all items in storage.
func get_all_items() -> Dictionary:
	return storage_inventory.get_all_items()
