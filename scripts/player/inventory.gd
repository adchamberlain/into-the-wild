extends Node
class_name Inventory
## Simple inventory system that tracks collected resources by type and quantity.

signal item_added(resource_type: String, amount: int, new_total: int)
signal item_removed(resource_type: String, amount: int, new_total: int)
signal inventory_changed()
signal item_add_refused(resource_type: String, attempted: int, current: int, limit: int)

# Per-item stack limits (only enforced when enforce_limits is true)
const DEFAULT_STACK_LIMIT: int = 20
const STACK_LIMITS: Dictionary = {
	# Bulk resources
	"wood": 50, "branch": 50, "river_rock": 50,
	# Rope
	"rope": 20,
	# Gathering materials
	"hide": 20, "feathers": 20, "birch_bark": 20, "raw_meat": 20,
	# Refined materials
	"metal_ingot": 15, "iron_ore": 15,
	# Rare materials
	"diamond": 10, "opal": 10, "crystal": 10, "rare_ore": 10,
	# Raw food
	"berry": 20, "mushroom": 20, "fish": 20, "herb": 20,
	"cactus_fruit": 20, "osha_root": 20, "coca_leaf": 20,
	# Cooked/processed food
	"cooked_berries": 10, "cooked_mushroom": 10, "cooked_fish": 10, "cooked_meat": 10,
	"dried_fish": 10, "dried_berries": 10, "dried_mushroom": 10, "dried_herb": 10,
	"smoked_meat": 10, "smoked_fish": 10,
	"hearty_stew": 10, "preserved_meal": 10, "herb_tea": 10,
	"fish_dinner": 10, "mushroom_soup": 10,
	# Torch
	"torch": 20,
	# Durable tools
	"primitive_axe": 3, "stone_axe": 3, "metal_axe": 3, "diamond_axe": 3,
	"machete": 5, "fishing_rod": 5, "bow": 3, "enchanted_bow": 3,
	# Utility items
	"grappling_hook": 5, "map": 1, "compass": 5, "lantern": 5, "hang_glider": 5,
	# Wraps
	"leather_axe_wrap": 3, "leather_hook_wrap": 3,
	# Placeable kits
	"campfire_kit": 5, "shelter_kit": 5, "storage_box": 5,
	"crafting_bench_kit": 5, "drying_rack_kit": 5, "garden_plot_kit": 5,
	"canvas_tent_kit": 5, "cabin_kit": 5, "snare_trap_kit": 5,
	"smithing_station_kit": 5, "smoker_kit": 5, "weather_vane_kit": 5,
	# Arrows
	"arrows": 50, "diamond_arrows": 20,
	# Healing
	"healing_salve": 10, "hide_bedroll": 10,
	# Pouches
	"berry_pouch": 5, "waterskin": 5,
	# Special
	"explorers_journal": 1, "lodestone": 1,
}

# When true, add_item() enforces stack limits (player inventory).
# Storage boxes leave this false for unlimited capacity.
var enforce_limits: bool = false

# Dictionary mapping resource_type (String) -> quantity (int)
var items: Dictionary = {}


func _ready() -> void:
	pass


## Get the stack limit for a resource type.
func get_stack_limit(resource_type: String) -> int:
	return STACK_LIMITS.get(resource_type, DEFAULT_STACK_LIMIT)


## Check if the given amount can be added without exceeding the stack limit.
func can_add_item(resource_type: String, amount: int = 1) -> bool:
	if not enforce_limits:
		return true
	var current: int = get_item_count(resource_type)
	var limit: int = get_stack_limit(resource_type)
	return current + amount <= limit


## Get how many more of this item can be added before hitting the limit.
func get_remaining_capacity(resource_type: String) -> int:
	if not enforce_limits:
		return 9999
	var current: int = get_item_count(resource_type)
	var limit: int = get_stack_limit(resource_type)
	return maxi(limit - current, 0)


## Add items to the inventory. Returns the new total for that resource type.
## When enforce_limits is true and adding would exceed the limit, the add is refused.
func add_item(resource_type: String, amount: int = 1) -> int:
	if amount <= 0:
		return get_item_count(resource_type)

	# Enforce stack limits when enabled
	if enforce_limits:
		var current: int = get_item_count(resource_type)
		var limit: int = get_stack_limit(resource_type)
		if current + amount > limit:
			item_add_refused.emit(resource_type, amount, current, limit)
			return current

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


## Debug: Print current inventory contents.
func debug_print() -> void:
	print("[Inventory] Contents:")
	if items.is_empty():
		print("  (empty)")
	else:
		for resource_type: String in items:
			print("  %s: %d" % [resource_type, items[resource_type]])
