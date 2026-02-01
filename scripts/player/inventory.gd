extends Node
class_name Inventory
## Simple inventory system that tracks collected resources by type and quantity.

signal item_added(resource_type: String, amount: int, new_total: int)
signal item_removed(resource_type: String, amount: int, new_total: int)
signal inventory_changed()

# Dictionary mapping resource_type (String) -> quantity (int)
var items: Dictionary = {}


func _ready() -> void:
	pass


## Add items to the inventory. Returns the new total for that resource type.
func add_item(resource_type: String, amount: int = 1) -> int:
	if amount <= 0:
		return get_item_count(resource_type)

	if not items.has(resource_type):
		items[resource_type] = 0

	items[resource_type] += amount
	var new_total: int = items[resource_type]

	item_added.emit(resource_type, amount, new_total)
	inventory_changed.emit()

	return new_total


## Remove items from inventory. Returns true if successful, false if not enough.
func remove_item(resource_type: String, amount: int = 1) -> bool:
	if amount <= 0:
		return true

	if not has_item(resource_type, amount):
		return false

	items[resource_type] -= amount
	var new_total: int = items[resource_type]

	# Clean up empty entries
	if new_total <= 0:
		items.erase(resource_type)
		new_total = 0

	item_removed.emit(resource_type, amount, new_total)
	inventory_changed.emit()

	return true


## Check if inventory has at least the specified amount of a resource.
func has_item(resource_type: String, amount: int = 1) -> bool:
	return get_item_count(resource_type) >= amount


## Get the current count of a specific resource type.
func get_item_count(resource_type: String) -> int:
	return items.get(resource_type, 0)


## Get all items as a dictionary (for UI display).
func get_all_items() -> Dictionary:
	return items.duplicate()


## Get total number of unique resource types in inventory.
func get_unique_item_count() -> int:
	return items.size()


## Get total number of all items combined.
func get_total_item_count() -> int:
	var total: int = 0
	for count: int in items.values():
		total += count
	return total


## Clear the entire inventory.
func clear() -> void:
	items.clear()
	inventory_changed.emit()
	print("[Inventory] Cleared")


## Debug: Print current inventory contents.
func debug_print() -> void:
	print("[Inventory] Contents:")
	if items.is_empty():
		print("  (empty)")
	else:
		for resource_type: String in items:
			print("  %s: %d" % [resource_type, items[resource_type]])
