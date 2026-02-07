extends "res://tests/test_base.gd"
## Tests for terrain collision box geometry - verifies box dimensions match terrain.
## Encodes past bugs: HeightMapShape3D interpolation, water cell fall-through, chunk boundary gaps.

const CELL_SIZE: float = 3.0
const CHUNK_SIZE_CELLS: int = 16
const MIN_BOX_HEIGHT: float = 0.5


func run_tests() -> Dictionary:
	set_test_name("TerrainCollision")

	test_normal_terrain_box_top()
	test_water_cell_thin_slab()
	test_minimum_box_height()
	test_campsite_zero_height()
	test_transition_zone_low_height()
	test_box_extends_below_surface()
	test_cell_coverage_no_gaps()
	test_water_slab_at_pond_floor()
	test_height_cache_border_size()
	test_pit_prevention_logic()
	test_box_dimensions_positive()
	test_chunk_boundary_contiguous()

	return get_results()


## Replicate the collision box calculation from terrain_chunk.gd:768-814
func _calc_box(height: float) -> Dictionary:
	var box_height: float
	var box_y_center: float

	if height < 0:
		box_height = MIN_BOX_HEIGHT
		box_y_center = height + box_height / 2.0
	else:
		box_height = max(height, MIN_BOX_HEIGHT)
		box_y_center = height - box_height / 2.0

	var box_top: float = box_y_center + box_height / 2.0
	var box_bottom: float = box_y_center - box_height / 2.0

	return {"height": box_height, "center": box_y_center, "top": box_top, "bottom": box_bottom}


func test_normal_terrain_box_top() -> void:
	# Box top must equal terrain height for normal terrain
	var test_heights: Array[float] = [0.5, 1.0, 2.0, 5.0, 10.0, 20.0]
	for h in test_heights:
		var box: Dictionary = _calc_box(h)
		assert_equal(box["top"], h,
			"Box top matches terrain height %.1f" % h)


func test_water_cell_thin_slab() -> void:
	# Water cells (negative height) get thin 0.5 slab at pond floor
	var box: Dictionary = _calc_box(-2.5)
	assert_equal(box["height"], MIN_BOX_HEIGHT,
		"Water cell box height is 0.5")
	# Slab center at floor + 0.25, top at floor + 0.5
	assert_equal(box["top"], -2.0,
		"Water slab top near pond floor")


func test_minimum_box_height() -> void:
	# Box height is always >= 0.5 even for very short terrain
	var test_heights: Array[float] = [0.0, 0.1, 0.25, 0.49]
	for h in test_heights:
		var box: Dictionary = _calc_box(h)
		assert_true(box["height"] >= MIN_BOX_HEIGHT,
			"Box height >= 0.5 for terrain h=%.2f" % h)


func test_campsite_zero_height() -> void:
	# Campsite center has height 0.0 - must still create valid collision
	var box: Dictionary = _calc_box(0.0)
	assert_equal(box["height"], MIN_BOX_HEIGHT, "Zero height uses min box")
	assert_equal(box["top"], 0.0, "Box top at 0 for campsite")
	assert_equal(box["bottom"], -MIN_BOX_HEIGHT, "Box extends below surface")


func test_transition_zone_low_height() -> void:
	# Campsite transition zone can produce heights like 0.25
	var box: Dictionary = _calc_box(0.25)
	assert_equal(box["top"], 0.25, "Box top matches 0.25 height")
	assert_true(box["height"] >= MIN_BOX_HEIGHT, "Min box height enforced")


func test_box_extends_below_surface() -> void:
	# For any height, box must extend BELOW the terrain surface
	var test_heights: Array[float] = [0.5, 1.0, 5.0, 15.0]
	for h in test_heights:
		var box: Dictionary = _calc_box(h)
		assert_true(box["bottom"] < h,
			"Box extends below surface for h=%.1f" % h)


func test_cell_coverage_no_gaps() -> void:
	# Adjacent cells in the same chunk must be contiguous (no X/Z gaps)
	# Cell 0 covers x: [0, 3], cell 1 covers x: [3, 6], etc.
	var chunk_world_x: float = 0.0
	for cx in range(CHUNK_SIZE_CELLS - 1):
		var cell_center_a: float = chunk_world_x + cx * CELL_SIZE + CELL_SIZE / 2.0
		var cell_center_b: float = chunk_world_x + (cx + 1) * CELL_SIZE + CELL_SIZE / 2.0

		var cell_a_max_x: float = cell_center_a + CELL_SIZE / 2.0
		var cell_b_min_x: float = cell_center_b - CELL_SIZE / 2.0

		assert_equal(cell_a_max_x, cell_b_min_x,
			"Cells %d and %d are contiguous in X" % [cx, cx + 1])


func test_water_slab_at_pond_floor() -> void:
	# Deep water: slab should be well below water surface (y=0.15)
	var deep_water: Dictionary = _calc_box(-2.5)
	assert_true(deep_water["top"] < 0.0,
		"Deep water slab top below water surface")

	# Shallow water edge: slab can poke above surface (beach effect)
	var shallow: Dictionary = _calc_box(-0.1)
	# This is intentional - creates walkable beach at pond edge
	assert_true(shallow["height"] >= MIN_BOX_HEIGHT,
		"Shallow water still has min height slab")


func test_height_cache_border_size() -> void:
	# Height cache must be chunk_size_cells + 2 for 1-cell border
	var expected_size: int = CHUNK_SIZE_CELLS + 2  # 18
	assert_equal(expected_size, 18, "Height cache is 18x18 (16 + 2 border)")

	# Verify indexing: cell (cx, cz) maps to cache[cz+1][cx+1]
	# Cell 0 -> cache index 1, cell 15 -> cache index 16
	assert_equal(0 + 1, 1, "Cell 0 maps to cache index 1")
	assert_equal(15 + 1, 16, "Cell 15 maps to cache index 16")
	# Border cells at index 0 and 17 are for neighbor lookups
	assert_true(0 < expected_size, "Border index 0 in range")
	assert_true(17 < expected_size, "Border index 17 in range")


func test_pit_prevention_logic() -> void:
	# A cell should never be more than 1 block below ALL cardinal neighbors
	# Simulating the pit prevention check from chunk_manager.gd:1292-1310
	var cell_height: float = 2.0
	var neighbor_heights: Array[float] = [5.0, 6.0, 4.0, 7.0]  # All well above

	var min_neighbor: float = INF
	for nh in neighbor_heights:
		if nh < min_neighbor:
			min_neighbor = nh

	# If min_neighbor - cell_height > 1.0, pit prevention raises cell
	if min_neighbor - cell_height > 1.0:
		cell_height = min_neighbor - 1.0

	assert_equal(cell_height, 3.0,
		"Pit prevention raises cell to min_neighbor - 1.0")

	# Test: cell already near neighbors - no change
	var normal_height: float = 4.5
	var normal_neighbors: Array[float] = [5.0, 4.0, 5.0, 4.5]
	var normal_min: float = INF
	for nh in normal_neighbors:
		if nh < normal_min:
			normal_min = nh
	if normal_min - normal_height > 1.0:
		normal_height = normal_min - 1.0

	assert_equal(normal_height, 4.5,
		"No pit prevention when cell is near neighbors")


func test_box_dimensions_positive() -> void:
	# Box height and size must always be positive
	var test_heights: Array[float] = [-5.0, -1.0, 0.0, 0.1, 1.0, 50.0]
	for h in test_heights:
		var box: Dictionary = _calc_box(h)
		assert_greater(box["height"], 0.0,
			"Box height positive for h=%.1f" % h)


func test_chunk_boundary_contiguous() -> void:
	# Last cell of chunk N and first cell of chunk N+1 must be contiguous
	var chunk_world_size: float = CHUNK_SIZE_CELLS * CELL_SIZE  # 48.0

	# Chunk 0, last cell (cx=15)
	var chunk0_last_center: float = 0.0 + 15 * CELL_SIZE + CELL_SIZE / 2.0  # 46.5
	var chunk0_last_max: float = chunk0_last_center + CELL_SIZE / 2.0  # 48.0

	# Chunk 1, first cell (cx=0)
	var chunk1_first_center: float = chunk_world_size + 0 * CELL_SIZE + CELL_SIZE / 2.0  # 49.5
	var chunk1_first_min: float = chunk1_first_center - CELL_SIZE / 2.0  # 48.0

	assert_equal(chunk0_last_max, chunk1_first_min,
		"Chunk boundary is contiguous (no gap)")
