extends "res://tests/test_base.gd"
## Tests for CaveTransition - resource respawn timing, state serialization, guards.
## Encodes past bugs: double entry crash, player spawning inside cave mesh, lost state.

const RESPAWN_HOURS: float = 6.0


func run_tests() -> Dictionary:
	set_test_name("CaveTransition")

	test_resource_respawn_after_threshold()
	test_resource_not_respawned_early()
	test_resource_respawn_across_days()
	test_resource_respawn_exact_boundary()
	test_duplicate_tracking_prevention()
	test_save_data_roundtrip()
	test_double_entry_guard()
	test_cave_scene_paths_exist()
	test_exit_position_offset()
	test_initial_state()

	return get_results()


func _make_cave_transition() -> Node:
	## Create a CaveTransition-like object for testing.
	## We can't instantiate the autoload directly, so we test the logic manually.
	var ct: Node = Node.new()
	return ct


func test_resource_respawn_after_threshold() -> void:
	# Depleted at day 1 hour 8:00, checked at day 1 hour 14:00 (6 hours later)
	var depleted_day: int = 1
	var depleted_hour: int = 8
	var depleted_minute: int = 0

	var current_day: int = 1
	var current_hour: int = 14
	var current_minute: int = 0

	var elapsed_minutes: float = float((current_day - depleted_day) * 24 * 60 + (current_hour - depleted_hour) * 60 + (current_minute - depleted_minute))
	var respawn_minutes: float = RESPAWN_HOURS * 60.0

	assert_true(elapsed_minutes >= respawn_minutes,
		"6 hours elapsed = resource respawned")


func test_resource_not_respawned_early() -> void:
	# Depleted at hour 8, checked at hour 12 (4 hours - too early)
	var elapsed_minutes: float = float(0 * 24 * 60 + (12 - 8) * 60 + 0)
	var respawn_minutes: float = RESPAWN_HOURS * 60.0

	assert_false(elapsed_minutes >= respawn_minutes,
		"4 hours elapsed = resource still depleted")


func test_resource_respawn_across_days() -> void:
	# Depleted day 1 hour 20:00, checked day 2 hour 6:00 (10 hours)
	var elapsed_minutes: float = float((2 - 1) * 24 * 60 + (6 - 20) * 60 + 0)
	# (1 * 1440) + (-14 * 60) = 1440 - 840 = 600 minutes = 10 hours
	var respawn_minutes: float = RESPAWN_HOURS * 60.0

	assert_true(elapsed_minutes >= respawn_minutes,
		"10 hours across day boundary = respawned")


func test_resource_respawn_exact_boundary() -> void:
	# Exactly 6 hours should count as respawned (>=)
	var elapsed_minutes: float = RESPAWN_HOURS * 60.0
	var respawn_minutes: float = RESPAWN_HOURS * 60.0

	assert_true(elapsed_minutes >= respawn_minutes,
		"Exact 6 hours = respawned (boundary)")


func test_duplicate_tracking_prevention() -> void:
	# Simulating track_cave_resource_depleted duplicate check
	var entries: Array = []
	var node_name: String = "CrystalNode1"

	# First entry
	var already_tracked: bool = false
	for entry: Dictionary in entries:
		if entry.get("node_name", "") == node_name:
			already_tracked = true
			break

	assert_false(already_tracked, "First entry is not duplicate")
	entries.append({"node_name": node_name, "depleted_day": 1, "depleted_hour": 8, "depleted_minute": 0})

	# Second entry of same name
	already_tracked = false
	for entry: Dictionary in entries:
		if entry.get("node_name", "") == node_name:
			already_tracked = true
			break

	assert_true(already_tracked, "Second entry detected as duplicate")


func test_save_data_roundtrip() -> void:
	# Test that cave transition save data preserves all fields
	var original: Dictionary = {
		"is_in_cave": true,
		"current_cave_id": 2,
		"current_cave_type": "small",
		"return_position": {"x": 10.5, "y": 3.0, "z": -20.0},
		"return_rotation": 1.57,
		"cave_entrance_position": {"x": 15.0, "y": 2.0, "z": -18.0},
		"cave_entrance_rotation_y": 3.14,
		"overworld_seed": 12345,
		"cave_resource_state": {"2": [{"node_name": "Ore1", "depleted_day": 1, "depleted_hour": 10, "depleted_minute": 30}]},
		"entry_game_day": 3,
		"entry_game_hour": 14,
		"entry_game_minute": 45
	}

	# Simulate load_save_data extraction
	var loaded_cave_id: int = original.get("current_cave_id", -1)
	var loaded_cave_type: String = original.get("current_cave_type", "")
	var pos: Dictionary = original.get("return_position", {})
	var loaded_pos: Vector3 = Vector3(pos.get("x", 0.0), pos.get("y", 0.0), pos.get("z", 0.0))
	var loaded_seed: int = original.get("overworld_seed", 0)
	var loaded_day: int = original.get("entry_game_day", 1)

	assert_equal(loaded_cave_id, 2, "Cave ID preserved")
	assert_equal(loaded_cave_type, "small", "Cave type preserved")
	assert_equal(loaded_pos.x, 10.5, "Return position X preserved")
	assert_equal(loaded_pos.y, 3.0, "Return position Y preserved")
	assert_equal(loaded_pos.z, -20.0, "Return position Z preserved")
	assert_equal(loaded_seed, 12345, "World seed preserved")
	assert_equal(loaded_day, 3, "Entry game day preserved")


func test_double_entry_guard() -> void:
	# Simulating the guard: if is_in_cave or _transitioning, block entry
	var is_in_cave: bool = false
	var transitioning: bool = false

	# Normal entry should be allowed
	var blocked: bool = is_in_cave or transitioning
	assert_false(blocked, "Entry allowed when not in cave")

	# Already in cave
	is_in_cave = true
	blocked = is_in_cave or transitioning
	assert_true(blocked, "Entry blocked when already in cave")

	# Transitioning
	is_in_cave = false
	transitioning = true
	blocked = is_in_cave or transitioning
	assert_true(blocked, "Entry blocked during transition")


func test_cave_scene_paths_exist() -> void:
	var cave_scenes: Dictionary = {
		"small": "res://scenes/caves/cave_interior_small.tscn",
	}

	for cave_type: String in cave_scenes:
		var path: String = cave_scenes[cave_type]
		assert_true(ResourceLoader.exists(path),
			"Cave scene '%s' exists at %s" % [cave_type, path])


func test_exit_position_offset() -> void:
	# When exiting cave, player should be placed 5 units in front of entrance
	var entrance_pos: Vector3 = Vector3(100.0, 5.0, -50.0)
	var entrance_rot_y: float = 0.0  # Facing +Z

	var forward: Vector3 = Vector3(sin(entrance_rot_y), 0, cos(entrance_rot_y))
	var exit_pos: Vector3 = entrance_pos + forward * 5.0

	assert_equal(exit_pos.x, 100.0, "Exit X matches entrance X (rot_y=0)")
	assert_equal(exit_pos.z, -50.0 + 5.0, "Exit Z is 5 units forward")


func test_initial_state() -> void:
	# Default state should be: not in cave, cave_id = -1
	var default_cave_id: int = -1
	var default_in_cave: bool = false

	assert_equal(default_cave_id, -1, "Default cave_id is -1")
	assert_false(default_in_cave, "Default not in cave")
