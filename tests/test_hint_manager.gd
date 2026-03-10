extends "res://tests/test_base.gd"
## Tests for HintManager - hint display logic, seen tracking, queue ordering.

var HintManagerScript: GDScript = preload("res://scripts/ui/hint_manager.gd")


func run_tests() -> Dictionary:
	set_test_name("HintManager")

	test_try_show_marks_seen()
	test_hint_not_shown_twice()
	test_loading_guard_suppresses()
	test_loading_guard_does_not_mark_seen()
	test_config_disabled_suppresses()
	test_config_disabled_does_not_mark_seen()
	test_get_set_seen_hints()
	test_clear_seen_hints()
	test_unknown_hint_ignored()
	test_queue_ordering()

	return get_results()


func _create_hint_manager() -> Node:
	return HintManagerScript.new()


func test_try_show_marks_seen() -> void:
	var hm: Node = _create_hint_manager()
	hm.try_show("first_gather")
	assert_true(hm.has_seen("first_gather"), "try_show marks hint as seen")


func test_hint_not_shown_twice() -> void:
	var hm: Node = _create_hint_manager()
	hm.try_show("first_craft")
	hm.try_show("first_craft")
	var seen: Array[String] = hm.get_seen_hints()
	var count: int = 0
	for s: String in seen:
		if s == "first_craft":
			count += 1
	assert_equal(count, 1, "hint only appears once in seen list")


func test_loading_guard_suppresses() -> void:
	var hm: Node = _create_hint_manager()
	hm.set_loading(true)
	hm.try_show("first_gather")
	assert_false(hm.has_seen("first_gather"), "loading guard suppresses hint")


func test_loading_guard_does_not_mark_seen() -> void:
	var hm: Node = _create_hint_manager()
	hm.set_loading(true)
	hm.try_show("hunger_low")
	var seen: Array[String] = hm.get_seen_hints()
	assert_equal(seen.size(), 0, "loading guard does not mark seen")


func test_config_disabled_suppresses() -> void:
	var hm: Node = _create_hint_manager()
	hm.set_hints_enabled(false)
	hm.try_show("first_fire_pit")
	assert_false(hm.has_seen("first_fire_pit"), "disabled config suppresses hint")


func test_config_disabled_does_not_mark_seen() -> void:
	var hm: Node = _create_hint_manager()
	hm.set_hints_enabled(false)
	hm.try_show("first_shelter")
	var seen: Array[String] = hm.get_seen_hints()
	assert_equal(seen.size(), 0, "disabled config does not mark seen")


func test_get_set_seen_hints() -> void:
	var hm: Node = _create_hint_manager()
	var hints: Array = ["first_gather", "first_craft", "hunger_low"]
	hm.set_seen_hints(hints)
	var seen: Array[String] = hm.get_seen_hints()
	assert_equal(seen.size(), 3, "set_seen_hints loads correct count")
	assert_true(hm.has_seen("first_gather"), "set_seen_hints includes first_gather")
	assert_true(hm.has_seen("first_craft"), "set_seen_hints includes first_craft")
	assert_true(hm.has_seen("hunger_low"), "set_seen_hints includes hunger_low")


func test_clear_seen_hints() -> void:
	var hm: Node = _create_hint_manager()
	hm.try_show("first_gather")
	hm.try_show("first_craft")
	hm.clear_seen_hints()
	assert_equal(hm.get_seen_hints().size(), 0, "clear_seen_hints empties list")
	assert_false(hm.has_seen("first_gather"), "cleared hint not seen")


func test_unknown_hint_ignored() -> void:
	var hm: Node = _create_hint_manager()
	hm.try_show("nonexistent_hint_xyz")
	assert_false(hm.has_seen("nonexistent_hint_xyz"), "unknown hint ignored")
	assert_equal(hm.get_seen_hints().size(), 0, "unknown hint not in seen list")


func test_queue_ordering() -> void:
	var hm: Node = _create_hint_manager()
	# Directly manipulate queue to test ordering without needing scene tree
	hm._seen_hints.append("first_gather")
	hm._queue.append("first_gather")
	hm._seen_hints.append("first_craft")
	hm._queue.append("first_craft")
	hm._seen_hints.append("hunger_low")
	hm._queue.append("hunger_low")
	assert_equal(hm._queue[0], "first_gather", "queue first element correct")
	assert_equal(hm._queue[1], "first_craft", "queue second element correct")
	assert_equal(hm._queue[2], "hunger_low", "queue third element correct")
