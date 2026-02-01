extends Node
class_name CraftingSystem
## Manages crafting recipes, discovery, and crafting execution.

signal recipe_crafted(recipe_id: String, output_type: String, output_amount: int)
signal recipe_discovered(recipe_id: String)

# All recipes loaded from data
var recipes: Dictionary = {}

# Recipes the player has discovered
var discovered_recipes: Array[String] = []

# Reference to player's inventory
var inventory: Inventory


func _ready() -> void:
	_load_recipes()


func _load_recipes() -> void:
	# Define recipes in code for simplicity
	# Format: recipe_id -> {name, inputs: {resource: amount}, output_type, output_amount, description}

	# Basic recipes (hand-craftable with C key)
	# Advanced recipes require crafting bench (requires_bench: true)
	recipes = {
		"stone_axe": {
			"name": "Stone Axe",
			"inputs": {"river_rock": 2, "branch": 1},
			"output_type": "stone_axe",
			"output_amount": 1,
			"description": "A crude axe for chopping wood.",
			"requires_bench": false
		},
		"torch": {
			"name": "Torch",
			"inputs": {"branch": 2},
			"output_type": "torch",
			"output_amount": 1,
			"description": "Provides light in dark areas.",
			"requires_bench": false
		},
		"campfire_kit": {
			"name": "Campfire Kit",
			"inputs": {"branch": 4, "river_rock": 3},
			"output_type": "campfire_kit",
			"output_amount": 1,
			"description": "Materials to build a campfire.",
			"requires_bench": false
		},
		"rope": {
			"name": "Plant Rope",
			"inputs": {"branch": 3},
			"output_type": "rope",
			"output_amount": 1,
			"description": "Useful for building and crafting.",
			"requires_bench": false
		},
		"crafting_bench_kit": {
			"name": "Crafting Bench Kit",
			"inputs": {"wood": 6, "branch": 4},
			"output_type": "crafting_bench_kit",
			"output_amount": 1,
			"description": "Materials to build a crafting workbench.",
			"requires_bench": false
		},
		"berry_pouch": {
			"name": "Berry Pouch",
			"inputs": {"berry": 5},
			"output_type": "berry_pouch",
			"output_amount": 1,
			"description": "Concentrated berries. Restores more hunger.",
			"requires_bench": true
		},
		"shelter_kit": {
			"name": "Shelter Kit",
			"inputs": {"branch": 6, "rope": 2},
			"output_type": "shelter_kit",
			"output_amount": 1,
			"description": "Materials to build a basic lean-to shelter.",
			"requires_bench": true
		},
		"storage_box": {
			"name": "Storage Box",
			"inputs": {"wood": 4, "rope": 1},
			"output_type": "storage_box",
			"output_amount": 1,
			"description": "A wooden box to store extra items.",
			"requires_bench": true
		},
		"fishing_rod": {
			"name": "Fishing Rod",
			"inputs": {"branch": 3, "rope": 1},
			"output_type": "fishing_rod",
			"output_amount": 1,
			"description": "A simple rod for catching fish.",
			"requires_bench": true
		},
		"healing_salve": {
			"name": "Healing Salve",
			"inputs": {"herb": 3},
			"output_type": "healing_salve",
			"output_amount": 1,
			"description": "Instantly restores health when used.",
			"requires_bench": true
		},
		"drying_rack_kit": {
			"name": "Drying Rack Kit",
			"inputs": {"branch": 6, "rope": 2},
			"output_type": "drying_rack_kit",
			"output_amount": 1,
			"description": "Materials to build a food drying rack.",
			"requires_bench": true
		},
		"garden_plot_kit": {
			"name": "Garden Plot Kit",
			"inputs": {"wood": 4, "herb": 2},
			"output_type": "garden_plot_kit",
			"output_amount": 1,
			"description": "Materials to build an herb garden.",
			"requires_bench": true
		},
		"canvas_tent_kit": {
			"name": "Canvas Tent Kit",
			"inputs": {"branch": 8, "rope": 4, "wood": 4},
			"output_type": "canvas_tent_kit",
			"output_amount": 1,
			"description": "Materials for a sturdy canvas tent.",
			"requires_bench": true,
			"min_camp_level": 2
		},
		"cabin_kit": {
			"name": "Cabin Kit",
			"inputs": {"wood": 30, "branch": 20, "river_rock": 10, "rope": 6},
			"output_type": "cabin_kit",
			"output_amount": 1,
			"description": "Everything needed to build a log cabin!",
			"requires_bench": true,
			"min_camp_level": 3
		}
	}

	# For now, all recipes are discovered by default (can change to discovery-based later)
	for recipe_id: String in recipes:
		discovered_recipes.append(recipe_id)


## Set the inventory reference for crafting operations.
func set_inventory(inv: Inventory) -> void:
	inventory = inv


## Get all discovered recipes.
func get_discovered_recipes() -> Array[String]:
	return discovered_recipes


## Get recipe data by ID.
func get_recipe(recipe_id: String) -> Dictionary:
	return recipes.get(recipe_id, {})


## Check if player can craft a recipe (has all required materials and bench if needed).
func can_craft(recipe_id: String, at_bench: bool = false, campsite_level: int = 1) -> bool:
	if not inventory:
		return false

	if not recipes.has(recipe_id):
		return false

	var recipe: Dictionary = recipes[recipe_id]

	# Check if bench is required but player is not at bench
	var requires_bench: bool = recipe.get("requires_bench", false)
	if requires_bench and not at_bench:
		return false

	# Check camp level requirement
	var min_level: int = recipe.get("min_camp_level", 1)
	if campsite_level < min_level:
		return false

	var inputs: Dictionary = recipe.get("inputs", {})

	for resource_type: String in inputs:
		var required: int = inputs[resource_type]
		if not inventory.has_item(resource_type, required):
			return false

	return true


## Get the minimum camp level required for a recipe.
func get_min_camp_level(recipe_id: String) -> int:
	if not recipes.has(recipe_id):
		return 1
	return recipes[recipe_id].get("min_camp_level", 1)


## Check if a recipe requires a crafting bench.
func requires_bench(recipe_id: String) -> bool:
	if not recipes.has(recipe_id):
		return false
	return recipes[recipe_id].get("requires_bench", false)


## Attempt to craft a recipe. Returns true if successful.
func craft(recipe_id: String, at_bench: bool = false, campsite_level: int = 1) -> bool:
	if not can_craft(recipe_id, at_bench, campsite_level):
		return false

	var recipe: Dictionary = recipes[recipe_id]
	var inputs: Dictionary = recipe.get("inputs", {})
	var output_type: String = recipe.get("output_type", "")
	var output_amount: int = recipe.get("output_amount", 1)

	# Remove input materials
	for resource_type: String in inputs:
		var required: int = inputs[resource_type]
		inventory.remove_item(resource_type, required)

	# Add output
	inventory.add_item(output_type, output_amount)

	print("[Crafting] Crafted %s x%d" % [output_type, output_amount])
	recipe_crafted.emit(recipe_id, output_type, output_amount)

	return true


## Discover a new recipe.
func discover_recipe(recipe_id: String) -> void:
	if recipes.has(recipe_id) and recipe_id not in discovered_recipes:
		discovered_recipes.append(recipe_id)
		recipe_discovered.emit(recipe_id)
		print("[Crafting] Discovered recipe: %s" % recipe_id)


## Check if a recipe is discovered.
func is_discovered(recipe_id: String) -> bool:
	return recipe_id in discovered_recipes


## Get a list of all recipes with their craftability status.
func get_all_recipes_status(at_bench: bool = false, campsite_level: int = 1) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for recipe_id: String in discovered_recipes:
		var recipe: Dictionary = recipes[recipe_id].duplicate()
		recipe["id"] = recipe_id
		recipe["can_craft"] = can_craft(recipe_id, at_bench, campsite_level)
		result.append(recipe)

	return result
