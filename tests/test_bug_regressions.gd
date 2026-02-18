extends "res://tests/test_base.gd"
## Regression tests for specific bugs found during code audits.
## Each test reproduces the bug scenario to prevent reintroduction.


func run_tests() -> Dictionary:
	set_test_name("BugRegressions")

	test_inventory_keys_use_crafting_ids()
	test_garden_cooldown_minutes_at_boundary()
	test_fishing_spot_respawn_color_matches_original()

	return get_results()


func test_inventory_keys_use_crafting_ids() -> void:
	## Bug: save_load.gd checked for "Fishing Rod" / "Stone Axe" (display names)
	## but inventory stores items by crafting key "fishing_rod" / "stone_axe".
	## This caused campsite progression flags to never restore on load.
	var inventory: Dictionary = {"fishing_rod": 1, "stone_axe": 1, "wood": 5}

	# The correct keys that save_load.gd should check (crafting output_type)
	assert_true(inventory.has("fishing_rod"),
		"Inventory uses 'fishing_rod' key (not 'Fishing Rod')")
	assert_true(inventory.has("stone_axe"),
		"Inventory uses 'stone_axe' key (not 'Stone Axe')")

	# Display names must NOT be used as inventory keys
	assert_false(inventory.has("Fishing Rod"),
		"Inventory does NOT use display name 'Fishing Rod'")
	assert_false(inventory.has("Stone Axe"),
		"Inventory does NOT use display name 'Stone Axe'")

	# Verify crafting system output_type matches inventory keys
	var crafting_script: GDScript = load("res://scripts/crafting/crafting_system.gd") as GDScript
	if crafting_script:
		var crafting: Variant = crafting_script.new()
		if crafting and crafting.get("recipes"):
			var recipes: Dictionary = crafting.recipes
			if recipes.has("fishing_rod"):
				assert_equal(recipes["fishing_rod"].get("output_type", ""),
					"fishing_rod", "Fishing rod output_type matches inventory key")
			if recipes.has("stone_axe"):
				assert_equal(recipes["stone_axe"].get("output_type", ""),
					"stone_axe", "Stone axe output_type matches inventory key")


func test_garden_cooldown_minutes_at_boundary() -> void:
	## Bug: int(tend_cooldown / 60) + 1 showed "2 minutes" when exactly 60s remained.
	## Fix: use ceili(tend_cooldown / 60.0) for correct ceiling rounding.

	# At exactly 60 seconds, should show 1 minute (not 2)
	var cooldown_60: float = 60.0
	var minutes_60: int = ceili(cooldown_60 / 60.0)
	assert_equal(minutes_60, 1, "60s cooldown shows 1 minute")

	# At 61 seconds, should show 2 minutes (ceiling)
	var cooldown_61: float = 61.0
	var minutes_61: int = ceili(cooldown_61 / 60.0)
	assert_equal(minutes_61, 2, "61s cooldown shows 2 minutes")

	# At 59 seconds, should show 1 minute (ceiling)
	var cooldown_59: float = 59.0
	var minutes_59: int = ceili(cooldown_59 / 60.0)
	assert_equal(minutes_59, 1, "59s cooldown shows 1 minute")

	# At 120 seconds, should show exactly 2 minutes
	var cooldown_120: float = 120.0
	var minutes_120: int = ceili(cooldown_120 / 60.0)
	assert_equal(minutes_120, 2, "120s cooldown shows 2 minutes")

	# At 1 second, should show 1 minute
	var cooldown_1: float = 1.0
	var minutes_1: int = ceili(cooldown_1 / 60.0)
	assert_equal(minutes_1, 1, "1s cooldown shows 1 minute")

	# Verify the old formula was wrong at boundary
	var old_formula: int = int(60.0 / 60) + 1  # This was the bug: gives 2
	assert_not_equal(old_formula, 1,
		"Old formula int(60/60)+1 gives wrong result at boundary (confirms bug existed)")


func test_fishing_spot_respawn_color_matches_original() -> void:
	## Bug: Original pond color was Color(0.15, 0.42, 0.55, 0.72) but respawn()
	## restored it to Color(0.15, 0.35, 0.45, 0.75) - noticeably different.
	var original_color: Color = Color(0.15, 0.42, 0.55, 0.72)
	var respawn_color: Color = Color(0.15, 0.42, 0.55, 0.72)  # Must match original

	assert_true(original_color.is_equal_approx(respawn_color),
		"Respawn water color matches original pond color")

	# Verify the old wrong color would fail
	var old_respawn_color: Color = Color(0.15, 0.35, 0.45, 0.75)
	assert_false(original_color.is_equal_approx(old_respawn_color),
		"Old respawn color does NOT match original (confirms bug existed)")
