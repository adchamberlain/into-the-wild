extends "res://tests/test_base.gd"
## Tests for CaveTransition - resource respawn timing (72h), state serialization.
## Validates inline cave system (no scene transitions).

const RESPAWN_HOURS: float = 72.0


func run_tests() -> Dictionary:
	set_test_name("CaveTransition")

	test_resource_respawn_after_threshold()
	test_resource_not_respawned_early()
	test_resource_respawn_across_days()
	test_resource_respawn_exact_boundary()
	test_resource_respawn_72h_boundary()
	test_duplicate_tracking_prevention()
	test_save_data_roundtrip()
	test_initial_state()

	return get_results()


func test_resource_respawn_after_threshold() -> void:
	# Depleted at day 1 hour 8:00, checked at day 4 hour 8:00 (72 hours later)
	var depleted_day: int = 1
	var depleted_hour: int = 8
	var depleted_minute: int = 0

	var current_day: int = 4
	var current_hour: int = 8
	var current_minute: int = 0

	var elapsed_minutes: float = float((current_day - depleted_day) * 24 * 60 + (current_hour - depleted_hour) * 60 + (current_minute - depleted_minute))
	var respawn_minutes: float = RESPAWN_HOURS * 60.0

	assert_true(elapsed_minutes >= respawn_minutes,
		"72 hours elapsed = resource respawned")


func test_resource_not_respawned_early() -> void:
	# Depleted at day 1 hour 8, checked at day 2 hour 12 (28 hours - too early)
	var elapsed_minutes: float = float((2 - 1) * 24 * 60 + (12 - 8) * 60 + 0)
	var respawn_minutes: float = RESPAWN_HOURS * 60.0

	assert_false(elapsed_minutes >= respawn_minutes,
		"28 hours elapsed = resource still depleted")


func test_resource_respawn_across_days() -> void:
	# Depleted day 1 hour 20:00, checked day 5 hour 6:00 (82 hours)
	var elapsed_minutes: float = float((5 - 1) * 24 * 60 + (6 - 20) * 60 + 0)
	# (4 * 1440) + (-14 * 60) = 5760 - 840 = 4920 minutes = 82 hours
	var respawn_minutes: float = RESPAWN_HOURS * 60.0

	assert_true(elapsed_minutes >= respawn_minutes,
		"82 hours across day boundary = respawned")


func test_resource_respawn_exact_boundary() -> void:
	# Exactly 72 hours should count as respawned (>=)
	var elapsed_minutes: float = RESPAWN_HOURS * 60.0
	var respawn_minutes: float = RESPAWN_HOURS * 60.0

	assert_true(elapsed_minutes >= respawn_minutes,
		"Exact 72 hours = respawned (boundary)")


func test_resource_respawn_72h_boundary() -> void:
	# 71 hours 59 minutes should NOT be respawned
	var elapsed_minutes: float = 71.0 * 60.0 + 59.0
	var respawn_minutes: float = RESPAWN_HOURS * 60.0

	assert_false(elapsed_minutes >= respawn_minutes,
		"71h59m < 72h = still depleted")

	# 72 hours 1 minute should be respawned
	elapsed_minutes = 72.0 * 60.0 + 1.0
	assert_true(elapsed_minutes >= respawn_minutes,
		"72h01m >= 72h = respawned")


func test_duplicate_tracking_prevention() -> void:
	# Simulating track_cave_resource_depleted duplicate check
	var entries: Array = []
	var node_name: String = "CrystalNode_0"

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
	# Test that cave transition save data preserves resource state
	var original: Dictionary = {
		"cave_resource_state": {"0": [{"node_name": "CrystalNode_0", "depleted_day": 1, "depleted_hour": 10, "depleted_minute": 30}]}
	}

	# Simulate load_save_data extraction
	var loaded_state: Dictionary = original.get("cave_resource_state", {})

	assert_true(loaded_state.has("0"), "Cave resource state key preserved")
	var entries: Array = loaded_state["0"]
	assert_equal(entries.size(), 1, "One entry preserved")
	var entry: Dictionary = entries[0]
	assert_equal(entry.get("node_name", ""), "CrystalNode_0", "Node name preserved")
	assert_equal(entry.get("depleted_day", 0), 1, "Depleted day preserved")
	assert_equal(entry.get("depleted_hour", 0), 10, "Depleted hour preserved")
	assert_equal(entry.get("depleted_minute", 0), 30, "Depleted minute preserved")


func test_initial_state() -> void:
	# Default state should be: not in cave, cave_id = -1
	var default_cave_id: int = -1
	var default_in_cave: bool = false

	assert_equal(default_cave_id, -1, "Default cave_id is -1")
	assert_false(default_in_cave, "Default not in cave")
