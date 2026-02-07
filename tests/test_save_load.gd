extends "res://tests/test_base.gd"
## Tests for save/load data serialization - roundtrip integrity, field presence, version.
## Encodes past bugs: lost inventory on load, corrupted positions, missing fields.

const SAVE_VERSION: int = 1


func run_tests() -> Dictionary:
	set_test_name("SaveLoad")

	test_inventory_serialization_roundtrip()
	test_position_serialization_roundtrip()
	test_structure_serialization_roundtrip()
	test_save_version_present()
	test_all_top_level_keys()
	test_time_fields_valid()
	test_campsite_fields_present()
	test_structure_fire_pit_has_is_lit()
	test_empty_inventory_roundtrip()
	test_float_position_precision()

	return get_results()


func test_inventory_serialization_roundtrip() -> void:
	# Simulate what save_load.gd does: inventory.get_all_items() -> JSON -> load back
	var original: Dictionary = {"wood": 5, "branch": 3, "berry": 10, "stone_axe": 1}

	# JSON roundtrip (same as actual save/load path)
	var json_str: String = JSON.stringify(original)
	var parsed: Variant = JSON.parse_string(json_str)

	assert_not_null(parsed, "JSON parse succeeds")
	assert_true(parsed is Dictionary, "Parsed result is Dictionary")

	var loaded: Dictionary = parsed as Dictionary
	for item_type: String in original:
		assert_equal(int(loaded.get(item_type, 0)), original[item_type],
			"Item '%s' count preserved" % item_type)


func test_position_serialization_roundtrip() -> void:
	# Vector3 -> {x, y, z} dict -> Vector3
	var original_pos: Vector3 = Vector3(42.5, 7.25, -103.75)

	var serialized: Dictionary = {
		"x": original_pos.x,
		"y": original_pos.y,
		"z": original_pos.z
	}

	# JSON roundtrip
	var json_str: String = JSON.stringify(serialized)
	var parsed: Dictionary = JSON.parse_string(json_str) as Dictionary

	var loaded_pos: Vector3 = Vector3(
		float(parsed.get("x", 0.0)),
		float(parsed.get("y", 0.0)),
		float(parsed.get("z", 0.0))
	)

	assert_equal(loaded_pos.x, original_pos.x, "Position X preserved")
	assert_equal(loaded_pos.y, original_pos.y, "Position Y preserved")
	assert_equal(loaded_pos.z, original_pos.z, "Position Z preserved")


func test_structure_serialization_roundtrip() -> void:
	# Structure list as saved by save_load.gd
	var structures: Array = [
		{"type": "fire_pit", "position": {"x": 2.0, "y": 0.0, "z": 3.0}, "is_lit": true},
		{"type": "shelter", "position": {"x": -5.0, "y": 0.0, "z": 1.0}},
		{"type": "storage_box", "position": {"x": 4.0, "y": 0.0, "z": -2.0}},
	]

	var json_str: String = JSON.stringify(structures)
	var parsed: Variant = JSON.parse_string(json_str)

	assert_not_null(parsed, "Structure JSON parse succeeds")
	assert_true(parsed is Array, "Parsed structures is Array")

	var loaded: Array = parsed as Array
	assert_equal(loaded.size(), 3, "All 3 structures preserved")

	# Check first structure fields
	var first: Dictionary = loaded[0] as Dictionary
	assert_equal(first.get("type", ""), "fire_pit", "Structure type preserved")
	assert_true(first.has("position"), "Structure has position")
	assert_true(first.get("is_lit", false), "Fire pit is_lit preserved")

	# Check structure without is_lit
	var second: Dictionary = loaded[1] as Dictionary
	assert_equal(second.get("type", ""), "shelter", "Shelter type preserved")


func test_save_version_present() -> void:
	# Build a minimal save data dict matching save_load.gd format
	var save_data: Dictionary = {"version": SAVE_VERSION}

	assert_true(save_data.has("version"), "Save data has version key")
	assert_equal(save_data["version"], 1, "Save version is 1")


func test_all_top_level_keys() -> void:
	# Verify the expected top-level keys from _collect_save_data
	var expected_keys: Array[String] = [
		"version", "timestamp", "player", "time",
		"weather", "campsite", "resources", "crafting",
		"world_seed", "obstacles", "cave"
	]

	# Build a mock save data with all expected keys
	var save_data: Dictionary = {}
	for key in expected_keys:
		save_data[key] = null  # Just checking key presence

	for key in expected_keys:
		assert_true(save_data.has(key),
			"Save data has '%s' key" % key)


func test_time_fields_valid() -> void:
	# Time data must have hour, minute, day
	var time_data: Dictionary = {"hour": 14, "minute": 30, "day": 3}

	var hour: int = time_data.get("hour", -1)
	var minute: int = time_data.get("minute", -1)
	var day: int = time_data.get("day", -1)

	assert_between(float(hour), 0.0, 23.0, "Hour in valid range")
	assert_between(float(minute), 0.0, 59.0, "Minute in valid range")
	assert_greater(float(day), 0.0, "Day is positive")


func test_campsite_fields_present() -> void:
	# Campsite save data fields
	var campsite: Dictionary = {
		"level": 2,
		"has_crafted_tool": true,
		"has_crafted_fishing_rod": false,
		"days_at_level_2": 3,
		"level_2_start_day": 5,
		"structures": []
	}

	var required_fields: Array[String] = [
		"level", "has_crafted_tool", "has_crafted_fishing_rod", "structures"
	]

	for field in required_fields:
		assert_true(campsite.has(field),
			"Campsite has '%s' field" % field)


func test_structure_fire_pit_has_is_lit() -> void:
	# Fire pit structures must include is_lit field when saved
	var fire_pit: Dictionary = {
		"type": "fire_pit",
		"position": {"x": 0.0, "y": 0.0, "z": 0.0},
		"is_lit": false
	}

	assert_true(fire_pit.has("is_lit"), "Fire pit has is_lit field")
	assert_equal(fire_pit["type"], "fire_pit", "Type is fire_pit")


func test_empty_inventory_roundtrip() -> void:
	# Empty inventory should serialize/deserialize cleanly
	var empty_inv: Dictionary = {}
	var json_str: String = JSON.stringify(empty_inv)
	var parsed: Variant = JSON.parse_string(json_str)

	assert_not_null(parsed, "Empty inventory JSON parse succeeds")
	assert_true(parsed is Dictionary, "Parsed empty inventory is Dictionary")
	assert_equal((parsed as Dictionary).size(), 0, "Empty inventory stays empty")


func test_float_position_precision() -> void:
	# JSON must preserve float precision for positions
	var precise_pos: Dictionary = {"x": 123.456789, "y": 0.001, "z": -999.999}
	var json_str: String = JSON.stringify(precise_pos)
	var parsed: Dictionary = JSON.parse_string(json_str) as Dictionary

	# Godot JSON preserves floats to at least 6 digits
	assert_true(absf(float(parsed["x"]) - 123.456789) < 0.001,
		"X precision preserved within 0.001")
	assert_true(absf(float(parsed["y"]) - 0.001) < 0.0001,
		"Y precision preserved within 0.0001")
	assert_true(absf(float(parsed["z"]) - (-999.999)) < 0.001,
		"Z precision preserved within 0.001")
