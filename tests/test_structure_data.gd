extends "res://tests/test_base.gd"
## Tests for StructureData - structure definitions, footprints, placement rules.
## Encodes past bugs: floating structures, overlapping footprints, missing item mappings.

const MIN_SPACING: float = 1.0  # Edge-to-edge minimum from placement_system.gd


func run_tests() -> Dictionary:
	set_test_name("StructureData")

	test_all_structures_have_footprint()
	test_all_structures_have_item_required()
	test_footprint_radii_positive()
	test_footprint_radii_reasonable()
	test_item_to_structure_roundtrip()
	test_all_placeable_items_map_to_structure()
	test_structure_for_missing_item()
	test_spacing_prevents_overlap()
	test_known_structure_count()
	test_cabin_is_largest()
	test_torch_is_smallest()
	test_camp_level_requirements()

	return get_results()


func test_all_structures_have_footprint() -> void:
	for structure_type: String in StructureData.STRUCTURES:
		var data: Dictionary = StructureData.STRUCTURES[structure_type]
		assert_true(data.has("footprint_radius"),
			"'%s' has footprint_radius" % structure_type)


func test_all_structures_have_item_required() -> void:
	for structure_type: String in StructureData.STRUCTURES:
		var data: Dictionary = StructureData.STRUCTURES[structure_type]
		assert_true(data.has("item_required"),
			"'%s' has item_required" % structure_type)
		assert_true(data["item_required"] != "",
			"'%s' item_required is not empty" % structure_type)


func test_footprint_radii_positive() -> void:
	for structure_type: String in StructureData.STRUCTURES:
		var radius: float = StructureData.get_footprint_radius(structure_type)
		assert_greater(radius, 0.0,
			"'%s' footprint > 0" % structure_type)


func test_footprint_radii_reasonable() -> void:
	for structure_type: String in StructureData.STRUCTURES:
		var radius: float = StructureData.get_footprint_radius(structure_type)
		assert_between(radius, 0.1, 10.0,
			"'%s' footprint %.1f in reasonable range" % [structure_type, radius])


func test_item_to_structure_roundtrip() -> void:
	# Every structure's item_required should map back to that structure type
	for structure_type: String in StructureData.STRUCTURES:
		var item: String = StructureData.STRUCTURES[structure_type]["item_required"]
		var resolved: String = StructureData.get_structure_for_item(item)
		assert_equal(resolved, structure_type,
			"Item '%s' maps back to '%s'" % [item, structure_type])


func test_all_placeable_items_map_to_structure() -> void:
	for item: String in StructureData.PLACEABLE_ITEMS:
		var structure: String = StructureData.get_structure_for_item(item)
		assert_not_equal(structure, "",
			"Placeable item '%s' has a structure mapping" % item)


func test_structure_for_missing_item() -> void:
	var result: String = StructureData.get_structure_for_item("nonexistent_item")
	assert_equal(result, "", "Missing item returns empty string")


func test_spacing_prevents_overlap() -> void:
	# Two fire_pits placed at minimum spacing should not overlap
	var fp_radius: float = StructureData.get_footprint_radius("fire_pit")
	var min_distance: float = fp_radius * 2 + MIN_SPACING
	assert_greater(min_distance, 0.0,
		"Min distance between fire pits is positive")

	# Cabin (largest) should require significant spacing
	var cabin_radius: float = StructureData.get_footprint_radius("cabin")
	var cabin_min_dist: float = cabin_radius * 2 + MIN_SPACING
	assert_greater(cabin_min_dist, 5.0,
		"Cabin spacing requires > 5m between centers")


func test_known_structure_count() -> void:
	# 15 structure types as of current build
	assert_equal(StructureData.STRUCTURES.size(), 15,
		"Expected 15 structure types")
	assert_equal(StructureData.PLACEABLE_ITEMS.size(), 15,
		"Expected 15 placeable items")


func test_cabin_is_largest() -> void:
	var cabin_fp: float = StructureData.get_footprint_radius("cabin")
	for structure_type: String in StructureData.STRUCTURES:
		var fp: float = StructureData.get_footprint_radius(structure_type)
		assert_true(fp <= cabin_fp,
			"'%s' (%.1f) <= cabin (%.1f)" % [structure_type, fp, cabin_fp])


func test_torch_is_smallest() -> void:
	var torch_fp: float = StructureData.get_footprint_radius("placed_torch")
	for structure_type: String in StructureData.STRUCTURES:
		var fp: float = StructureData.get_footprint_radius(structure_type)
		assert_true(fp >= torch_fp,
			"'%s' (%.1f) >= torch (%.1f)" % [structure_type, fp, torch_fp])


func test_camp_level_requirements() -> void:
	# canvas_tent and cabin require specific camp levels
	var tent_data: Dictionary = StructureData.get_structure("canvas_tent")
	assert_equal(tent_data.get("min_camp_level", 1), 2,
		"Canvas tent requires camp level 2")

	var cabin_data: Dictionary = StructureData.get_structure("cabin")
	assert_equal(cabin_data.get("min_camp_level", 1), 3,
		"Cabin requires camp level 3")

	# fire_pit has no level requirement (defaults to 1)
	var fire_data: Dictionary = StructureData.get_structure("fire_pit")
	assert_equal(fire_data.get("min_camp_level", 1), 1,
		"Fire pit has no level requirement")
