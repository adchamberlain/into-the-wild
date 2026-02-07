extends SceneTree
## Test runner - executes all test files and reports results.
## Usage: godot --headless --script tests/run_all_tests.gd

var total_passed: int = 0
var total_failed: int = 0
var all_errors: Array[String] = []


func _init() -> void:
	print("")
	print("========================================")
	print("  INTO THE WILD - REGRESSION TESTS")
	print("========================================")
	print("")

	var test_files: Array[String] = [
		"res://tests/test_inventory.gd",
		"res://tests/test_crafting.gd",
		"res://tests/test_terrain_collision.gd",
		"res://tests/test_structure_data.gd",
		"res://tests/test_cave_transition.gd",
		"res://tests/test_save_load.gd",
		"res://tests/test_ui_constants.gd",
	]

	for test_path in test_files:
		_run_test_file(test_path)

	print("")
	print("========================================")
	print("  RESULTS: %d passed, %d failed" % [total_passed, total_failed])
	print("========================================")

	if total_failed > 0:
		print("")
		print("FAILURES:")
		for err in all_errors:
			print(err)
		print("")

	if total_failed > 0:
		print("TESTS FAILED")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _run_test_file(path: String) -> void:
	var script: GDScript = load(path) as GDScript
	if not script:
		print("[ERROR] Could not load: %s" % path)
		total_failed += 1
		all_errors.append("  Could not load: %s" % path)
		return

	var test_instance: Variant = script.new()
	if not test_instance or not test_instance.has_method("run_tests"):
		print("[ERROR] No run_tests() method in: %s" % path)
		total_failed += 1
		all_errors.append("  No run_tests() in: %s" % path)
		return

	var results: Dictionary = test_instance.run_tests()
	var name: String = results.get("name", path)
	var passed: int = results.get("passed", 0)
	var failed: int = results.get("failed", 0)
	var errors: Array = results.get("errors", [])

	total_passed += passed
	total_failed += failed

	var status: String = "PASS" if failed == 0 else "FAIL"
	print("[%s] %s (%d passed, %d failed)" % [status, name, passed, failed])

	for err: String in errors:
		all_errors.append("[%s] %s" % [name, err])
