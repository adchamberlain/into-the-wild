extends SceneTree
## Headless validation: checks that cave scripts parse, resources load,
## and deleted files are gone. Run with:
##   godot --headless --path . --script validation/check_scene.gd

var errors: int = 0


func _init() -> void:
	print("=== Cave System Validation ===\n")

	_check_script_loads()
	_check_deleted_files()
	_check_autoload_script()

	print("\n=== Validation Complete ===")
	if errors > 0:
		print("FAILED: %d error(s)" % errors)
	else:
		print("ALL CHECKS PASSED")

	quit(errors)


func _check_script_loads() -> void:
	print("--- Checking script loads ---")
	var scripts: Array[String] = [
		"res://scripts/world/cave_entrance.gd",
		"res://scripts/core/cave_transition.gd",
		"res://scripts/core/save_load.gd",
		"res://scripts/core/game_state.gd",
		"res://scripts/resources/crystal_node.gd",
		"res://scripts/resources/rare_ore_node.gd",
	]
	for path: String in scripts:
		if ResourceLoader.exists(path):
			var script: GDScript = load(path) as GDScript
			if script:
				print("  OK: %s" % path)
			else:
				print("  FAIL: %s (load returned null)" % path)
				errors += 1
		else:
			print("  FAIL: %s (does not exist)" % path)
			errors += 1


func _check_deleted_files() -> void:
	print("--- Checking deleted files are gone ---")
	var deleted: Array[String] = [
		"res://scripts/caves/cave_interior_manager.gd",
		"res://scenes/caves/cave_interior_small.tscn",
	]
	for path: String in deleted:
		if ResourceLoader.exists(path):
			print("  FAIL: %s still exists (should be deleted)" % path)
			errors += 1
		else:
			print("  OK: %s removed" % path)


func _check_autoload_script() -> void:
	print("--- Checking CaveTransition autoload script ---")
	var path: String = "res://scripts/core/cave_transition.gd"
	var script: GDScript = load(path) as GDScript
	if not script:
		print("  FAIL: CaveTransition script not loadable")
		errors += 1
		return

	# Check that scene transition methods are removed
	var source: String = script.source_code
	var removed_methods: Array[String] = [
		"func enter_cave(",
		"func exit_cave(",
		"func _load_cave_scene(",
		"func _return_to_overworld(",
		"func _restore_player_position(",
		"change_scene_to_packed",
		"change_scene_to_file",
	]
	for method: String in removed_methods:
		if source.find(method) >= 0:
			print("  FAIL: Found removed code '%s' in cave_transition.gd" % method)
			errors += 1
		else:
			print("  OK: '%s' not present" % method)

	# Check that new methods exist
	var required_methods: Array[String] = [
		"func player_entered_cave(",
		"func player_exited_cave(",
		"CAVE_RESOURCE_RESPAWN_HOURS",
	]
	for method: String in required_methods:
		if source.find(method) >= 0:
			print("  OK: '%s' present" % method)
		else:
			print("  FAIL: Required '%s' not found" % method)
			errors += 1

	# Check respawn hours is 72
	if source.find("72.0") >= 0:
		print("  OK: Respawn hours = 72.0")
	else:
		print("  FAIL: Respawn hours not set to 72.0")
		errors += 1
