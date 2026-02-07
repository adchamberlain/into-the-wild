extends "res://tests/test_base.gd"
## Tests for Inventory system - item add/remove/query logic.

func run_tests() -> Dictionary:
	set_test_name("Inventory")

	test_add_item()
	test_add_multiple()
	test_remove_item()
	test_remove_insufficient()
	test_remove_exact_amount()
	test_has_item()
	test_has_item_threshold()
	test_get_item_count_missing()
	test_clear()
	test_add_zero()
	test_add_negative()
	test_unique_and_total_counts()
	test_get_all_items_is_copy()

	return get_results()


func test_add_item() -> void:
	var inv: Inventory = Inventory.new()
	var result: int = inv.add_item("wood", 5)
	assert_equal(result, 5, "add_item returns new total")
	assert_equal(inv.get_item_count("wood"), 5, "item count after add")


func test_add_multiple() -> void:
	var inv: Inventory = Inventory.new()
	inv.add_item("wood", 3)
	inv.add_item("wood", 2)
	assert_equal(inv.get_item_count("wood"), 5, "stacking adds correctly")


func test_remove_item() -> void:
	var inv: Inventory = Inventory.new()
	inv.add_item("branch", 10)
	var success: bool = inv.remove_item("branch", 3)
	assert_true(success, "remove_item returns true on success")
	assert_equal(inv.get_item_count("branch"), 7, "count after partial remove")


func test_remove_insufficient() -> void:
	var inv: Inventory = Inventory.new()
	inv.add_item("rock", 2)
	var success: bool = inv.remove_item("rock", 5)
	assert_false(success, "remove_item returns false when insufficient")
	assert_equal(inv.get_item_count("rock"), 2, "count unchanged after failed remove")


func test_remove_exact_amount() -> void:
	var inv: Inventory = Inventory.new()
	inv.add_item("herb", 3)
	var success: bool = inv.remove_item("herb", 3)
	assert_true(success, "remove exact amount succeeds")
	assert_equal(inv.get_item_count("herb"), 0, "count is 0 after removing all")
	assert_false(inv.has_item("herb"), "has_item false after removing all")


func test_has_item() -> void:
	var inv: Inventory = Inventory.new()
	assert_false(inv.has_item("wood"), "has_item false for missing item")
	inv.add_item("wood", 1)
	assert_true(inv.has_item("wood"), "has_item true after adding")


func test_has_item_threshold() -> void:
	var inv: Inventory = Inventory.new()
	inv.add_item("berry", 3)
	assert_true(inv.has_item("berry", 3), "has_item exact threshold")
	assert_false(inv.has_item("berry", 4), "has_item above threshold")
	assert_true(inv.has_item("berry", 1), "has_item below threshold")


func test_get_item_count_missing() -> void:
	var inv: Inventory = Inventory.new()
	assert_equal(inv.get_item_count("nonexistent"), 0, "missing item returns 0")


func test_clear() -> void:
	var inv: Inventory = Inventory.new()
	inv.add_item("wood", 5)
	inv.add_item("rock", 3)
	inv.clear()
	assert_equal(inv.get_total_item_count(), 0, "total is 0 after clear")
	assert_equal(inv.get_unique_item_count(), 0, "unique is 0 after clear")


func test_add_zero() -> void:
	var inv: Inventory = Inventory.new()
	inv.add_item("wood", 0)
	assert_equal(inv.get_item_count("wood"), 0, "adding 0 does nothing")


func test_add_negative() -> void:
	var inv: Inventory = Inventory.new()
	inv.add_item("wood", -5)
	assert_equal(inv.get_item_count("wood"), 0, "adding negative does nothing")


func test_unique_and_total_counts() -> void:
	var inv: Inventory = Inventory.new()
	inv.add_item("wood", 3)
	inv.add_item("rock", 2)
	inv.add_item("berry", 5)
	assert_equal(inv.get_unique_item_count(), 3, "unique count")
	assert_equal(inv.get_total_item_count(), 10, "total count")


func test_get_all_items_is_copy() -> void:
	var inv: Inventory = Inventory.new()
	inv.add_item("wood", 5)
	var copy: Dictionary = inv.get_all_items()
	copy["wood"] = 999
	assert_equal(inv.get_item_count("wood"), 5, "get_all_items returns copy not reference")
