extends "res://tests/test_base.gd"
## Tests for CraftingSystem - recipe validation, bench/level requirements, crafting logic.

func run_tests() -> Dictionary:
	set_test_name("Crafting")

	test_all_recipes_have_required_fields()
	test_can_craft_with_materials()
	test_cannot_craft_without_materials()
	test_bench_requirement_enforced()
	test_hand_craftable_recipes()
	test_camp_level_requirement()
	test_craft_consumes_inputs()
	test_craft_produces_output()
	test_compass_produces_lodestone()
	test_cannot_craft_without_inventory()
	test_invalid_recipe_id()
	test_all_recipes_discoverable()
	test_get_min_camp_level()

	return get_results()


func _make_crafting_system() -> CraftingSystem:
	var cs: CraftingSystem = CraftingSystem.new()
	# Manually call _load_recipes since _ready won't fire in headless tests
	cs._load_recipes()
	return cs


func _give_materials(inv: Inventory, materials: Dictionary) -> void:
	for resource_type: String in materials:
		inv.add_item(resource_type, materials[resource_type])


func test_all_recipes_have_required_fields() -> void:
	var cs: CraftingSystem = _make_crafting_system()
	var required_fields: Array[String] = ["name", "inputs", "output_type", "output_amount"]

	for recipe_id: String in cs.recipes:
		var recipe: Dictionary = cs.recipes[recipe_id]
		for field in required_fields:
			assert_true(recipe.has(field),
				"Recipe '%s' has field '%s'" % [recipe_id, field])
		# Verify inputs is a non-empty dictionary
		var inputs: Dictionary = recipe.get("inputs", {})
		assert_true(inputs.size() > 0,
			"Recipe '%s' has at least one input" % recipe_id)


func test_can_craft_with_materials() -> void:
	var cs: CraftingSystem = _make_crafting_system()
	var inv: Inventory = Inventory.new()
	cs.set_inventory(inv)

	# Test primitive_axe (hand-craftable, no bench needed)
	_give_materials(inv, {"river_rock": 1, "branch": 1})
	assert_true(cs.can_craft("primitive_axe", false, 1),
		"can_craft primitive_axe with materials")


func test_cannot_craft_without_materials() -> void:
	var cs: CraftingSystem = _make_crafting_system()
	var inv: Inventory = Inventory.new()
	cs.set_inventory(inv)

	assert_false(cs.can_craft("primitive_axe", false, 1),
		"cannot craft without materials")


func test_bench_requirement_enforced() -> void:
	var cs: CraftingSystem = _make_crafting_system()
	var inv: Inventory = Inventory.new()
	cs.set_inventory(inv)

	# berry_pouch requires bench
	_give_materials(inv, {"berry": 5})
	assert_false(cs.can_craft("berry_pouch", false, 1),
		"bench recipe fails without bench")
	assert_true(cs.can_craft("berry_pouch", true, 1),
		"bench recipe passes with bench")


func test_hand_craftable_recipes() -> void:
	var cs: CraftingSystem = _make_crafting_system()
	var hand_recipes: Array[String] = [
		"primitive_axe", "stone_axe", "torch", "campfire_kit", "rope", "crafting_bench_kit"
	]

	for recipe_id in hand_recipes:
		assert_false(cs.requires_bench(recipe_id),
			"'%s' is hand-craftable (no bench)" % recipe_id)


func test_camp_level_requirement() -> void:
	var cs: CraftingSystem = _make_crafting_system()
	var inv: Inventory = Inventory.new()
	cs.set_inventory(inv)

	# garden_plot_kit requires camp level 2
	_give_materials(inv, {"wood": 4, "herb": 2})
	assert_false(cs.can_craft("garden_plot_kit", true, 1),
		"level 2 recipe fails at level 1")
	assert_true(cs.can_craft("garden_plot_kit", true, 2),
		"level 2 recipe passes at level 2")

	# cabin_kit requires camp level 3
	inv.clear()
	_give_materials(inv, {"wood": 30, "branch": 20, "river_rock": 10, "rope": 6})
	assert_false(cs.can_craft("cabin_kit", true, 2),
		"level 3 recipe fails at level 2")
	assert_true(cs.can_craft("cabin_kit", true, 3),
		"level 3 recipe passes at level 3")


func test_craft_consumes_inputs() -> void:
	var cs: CraftingSystem = _make_crafting_system()
	var inv: Inventory = Inventory.new()
	cs.set_inventory(inv)

	_give_materials(inv, {"river_rock": 3, "branch": 3})
	cs.craft("primitive_axe", false, 1)

	assert_equal(inv.get_item_count("river_rock"), 2, "crafting consumed 1 river_rock")
	assert_equal(inv.get_item_count("branch"), 2, "crafting consumed 1 branch")


func test_craft_produces_output() -> void:
	var cs: CraftingSystem = _make_crafting_system()
	var inv: Inventory = Inventory.new()
	cs.set_inventory(inv)

	_give_materials(inv, {"branch": 2})
	var success: bool = cs.craft("torch", false, 1)

	assert_true(success, "craft returns true on success")
	assert_equal(inv.get_item_count("torch"), 1, "torch added to inventory")


func test_compass_produces_lodestone() -> void:
	var cs: CraftingSystem = _make_crafting_system()
	var inv: Inventory = Inventory.new()
	cs.set_inventory(inv)

	_give_materials(inv, {"rare_ore": 2, "metal_ingot": 1, "crystal": 1})
	cs.craft("compass", true, 3)

	assert_true(inv.has_item("compass"), "compass in inventory")
	assert_true(inv.has_item("lodestone"), "lodestone also produced")


func test_cannot_craft_without_inventory() -> void:
	var cs: CraftingSystem = _make_crafting_system()
	# No inventory set
	assert_false(cs.can_craft("torch", false, 1),
		"can_craft returns false with no inventory")


func test_invalid_recipe_id() -> void:
	var cs: CraftingSystem = _make_crafting_system()
	var inv: Inventory = Inventory.new()
	cs.set_inventory(inv)

	assert_false(cs.can_craft("nonexistent_recipe", false, 1),
		"invalid recipe returns false")
	assert_false(cs.craft("nonexistent_recipe", false, 1),
		"crafting invalid recipe returns false")


func test_all_recipes_discoverable() -> void:
	var cs: CraftingSystem = _make_crafting_system()
	for recipe_id: String in cs.recipes:
		assert_true(cs.is_discovered(recipe_id),
			"Recipe '%s' is discovered by default" % recipe_id)


func test_get_min_camp_level() -> void:
	var cs: CraftingSystem = _make_crafting_system()
	assert_equal(cs.get_min_camp_level("torch"), 1, "torch is level 1")
	assert_equal(cs.get_min_camp_level("garden_plot_kit"), 2, "garden is level 2")
	assert_equal(cs.get_min_camp_level("cabin_kit"), 3, "cabin is level 3")
	assert_equal(cs.get_min_camp_level("nonexistent"), 1, "unknown defaults to 1")
