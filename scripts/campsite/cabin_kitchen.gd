extends StructureBase
class_name CabinKitchen
## Kitchen inside the cabin - advanced cooking station.

signal food_cooked(recipe_name: String)

# Kitchen cooking recipes (better than campfire)
const KITCHEN_RECIPES: Dictionary = {
	"hearty_stew": {
		"name": "Hearty Stew",
		"inputs": {"fish": 2, "herb": 1, "mushroom": 1},
		"hunger_restore": 100.0,
		"health_restore": 20.0
	},
	"preserved_meal": {
		"name": "Preserved Meal",
		"inputs": {"dried_fish": 2, "dried_berries": 1},
		"hunger_restore": 80.0,
		"health_restore": 0.0
	},
	"herb_tea": {
		"name": "Herb Tea",
		"inputs": {"herb": 2},
		"hunger_restore": 10.0,
		"health_restore": 30.0
	},
	"fish_dinner": {
		"name": "Cooked Fish",
		"inputs": {"fish": 1},
		"hunger_restore": 40.0,
		"health_restore": 0.0
	},
	"mushroom_soup": {
		"name": "Mushroom Soup",
		"inputs": {"mushroom": 2, "herb": 1},
		"hunger_restore": 50.0,
		"health_restore": 10.0
	}
}


func _ready() -> void:
	super._ready()
	structure_type = "cabin_kitchen"
	structure_name = "Kitchen"
	interaction_text = "Cook"
	# Kitchen is part of cabin, not a separate structure to track
	remove_from_group("structure")


func interact(player: Node) -> bool:
	if not is_active:
		return false

	var player_inventory: Node = null
	if player.has_method("get_inventory"):
		player_inventory = player.get_inventory()

	if not player_inventory:
		return false

	var player_stats: Node = null
	if player.has_node("PlayerStats"):
		player_stats = player.get_node("PlayerStats")

	# Try to cook the best recipe we can make
	var best_recipe: String = _find_best_recipe(player_inventory)

	if best_recipe.is_empty():
		# Give helpful message about what's missing
		var missing_msg: String = _get_missing_ingredients_message(player_inventory)
		_show_notification(missing_msg, Color(1.0, 0.6, 0.4))
		print("[Kitchen] %s" % missing_msg)
		return true

	# Cook the recipe
	var recipe: Dictionary = KITCHEN_RECIPES[best_recipe]
	var inputs: Dictionary = recipe.get("inputs", {})

	# Consume ingredients
	for item: String in inputs:
		player_inventory.remove_item(item, inputs[item])

	# Apply effects
	var hunger_restore: float = recipe.get("hunger_restore", 0.0)
	var health_restore: float = recipe.get("health_restore", 0.0)

	if player_stats:
		if health_restore > 0 and player_stats.has_method("heal"):
			player_stats.heal(health_restore)
		if hunger_restore > 0 and "hunger" in player_stats and "max_hunger" in player_stats:
			player_stats.hunger = min(player_stats.hunger + hunger_restore, player_stats.max_hunger)
			player_stats.hunger_changed.emit(player_stats.hunger, player_stats.max_hunger)

	# Show notification with what was cooked
	var msg: String = "Cooked %s!" % recipe.get("name")
	if hunger_restore > 0 and health_restore > 0:
		msg += " +%.0f hunger, +%.0f health" % [hunger_restore, health_restore]
	elif hunger_restore > 0:
		msg += " +%.0f hunger" % hunger_restore
	elif health_restore > 0:
		msg += " +%.0f health" % health_restore
	_show_notification(msg, Color(1.0, 0.85, 0.4))

	food_cooked.emit(recipe.get("name", best_recipe))
	print("[Kitchen] Cooked %s! (+%.0f hunger, +%.0f health)" % [recipe.get("name"), hunger_restore, health_restore])

	return true


## Get a helpful message about what ingredients are missing.
func _get_missing_ingredients_message(inventory: Node) -> String:
	# Find the recipe closest to completion and tell the player what's missing
	var closest_recipe: String = ""
	var closest_missing: Dictionary = {}
	var fewest_missing: int = 999

	for recipe_id: String in KITCHEN_RECIPES:
		var recipe: Dictionary = KITCHEN_RECIPES[recipe_id]
		var inputs: Dictionary = recipe.get("inputs", {})
		var missing: Dictionary = {}

		for item: String in inputs:
			var needed: int = inputs[item]
			var have: int = inventory.get_item_count(item) if inventory.has_method("get_item_count") else 0
			if have < needed:
				missing[item] = needed - have

		var total_missing: int = 0
		for item: String in missing:
			total_missing += missing[item]

		if total_missing > 0 and total_missing < fewest_missing:
			fewest_missing = total_missing
			closest_recipe = recipe_id
			closest_missing = missing

	if closest_recipe.is_empty():
		return "No cooking ingredients found."

	var recipe_name: String = KITCHEN_RECIPES[closest_recipe].get("name", closest_recipe)
	var missing_items: Array[String] = []
	for item: String in closest_missing:
		var count: int = closest_missing[item]
		if count == 1:
			missing_items.append("1 %s" % item)
		else:
			missing_items.append("%d %ss" % [count, item])

	if missing_items.size() == 1:
		return "Need %s for %s" % [missing_items[0], recipe_name]
	else:
		return "Need %s for %s" % [", ".join(missing_items), recipe_name]


func _find_best_recipe(inventory: Node) -> String:
	# Find the best recipe we can make (prioritize by hunger restore)
	var best_recipe: String = ""
	var best_hunger: float = 0.0

	for recipe_id: String in KITCHEN_RECIPES:
		var recipe: Dictionary = KITCHEN_RECIPES[recipe_id]
		var inputs: Dictionary = recipe.get("inputs", {})
		var can_make: bool = true

		for item: String in inputs:
			if not inventory.has_item(item, inputs[item]):
				can_make = false
				break

		if can_make:
			var hunger: float = recipe.get("hunger_restore", 0.0)
			if hunger > best_hunger:
				best_hunger = hunger
				best_recipe = recipe_id

	return best_recipe


func get_interaction_text() -> String:
	return "Cook at Kitchen"


func _find_hud() -> Node:
	var root: Node = get_tree().root
	if root.has_node("Main/HUD"):
		return root.get_node("Main/HUD")
	return null


func _show_notification(message: String, color: Color) -> void:
	var hud: Node = _find_hud()
	if hud and hud.has_method("show_notification"):
		hud.show_notification(message, color)


## Get available recipes as a list.
func get_available_recipes(inventory: Node) -> Array[String]:
	var available: Array[String] = []

	for recipe_id: String in KITCHEN_RECIPES:
		var recipe: Dictionary = KITCHEN_RECIPES[recipe_id]
		var inputs: Dictionary = recipe.get("inputs", {})
		var can_make: bool = true

		for item: String in inputs:
			if not inventory.has_item(item, inputs[item]):
				can_make = false
				break

		if can_make:
			available.append(recipe_id)

	return available
