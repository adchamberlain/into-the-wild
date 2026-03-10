# Procedural Water Generation Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate ponds, lakes, and rivers procedurally as the player explores, so water features appear at any distance from origin.

**Architecture:** Grid-based deterministic placement. The world is divided into 80x80 water cells (ponds/lakes) and 200x200 river cells. Each cell uses a hash of its coordinates + world seed to decide whether it spawns a water feature. Cells are evaluated synchronously in `_load_chunk()` before terrain generation, so depressions are carved correctly.

**Tech Stack:** GDScript (Godot 4.5), existing `chunk_manager.gd` water systems

**Spec:** `docs/superpowers/specs/2026-03-09-procedural-water-generation-design.md`

**Testing:** SUSPENDED per CLAUDE.md — no automated tests. Verify manually by exploring beyond 300 units from origin and confirming water features appear.

---

## Chunk 1: Water Cell Grid for Ponds & Lakes

### Task 1: Add water cell grid data structures and constants

**Files:**
- Modify: `scripts/world/chunk_manager.gd` (add variables near line 36-50, after existing water body settings)

- [ ] **Step 1: Add water cell constants and tracking dictionary**

Add these variables after the existing `lake_pond_spacing` declaration (around line 46):

```gdscript
# Procedural water cell grid (80x80 units per cell)
const WATER_CELL_SIZE: float = 80.0
var evaluated_water_cells: Dictionary = {}  # Vector2i -> bool (true if evaluated)

# Biome-based water feature probabilities {RegionType -> {pond_chance, lake_chance}}
var water_cell_probabilities: Dictionary = {
	RegionType.MEADOW: {"pond": 0.40, "lake": 0.15},
	RegionType.FOREST: {"pond": 0.35, "lake": 0.0},
	RegionType.HILLS: {"pond": 0.25, "lake": 0.0},
	RegionType.ROCKY: {"pond": 0.25, "lake": 0.0},
	RegionType.MOUNTAIN: {"pond": 0.20, "lake": 0.10},
	RegionType.DESERT: {"pond": 0.0, "lake": 0.0},
}
```

- [ ] **Step 2: Commit**

```bash
git add scripts/world/chunk_manager.gd
git commit -m "Add water cell grid data structures for procedural water generation"
```

---

### Task 2: Implement water cell evaluation function

**Files:**
- Modify: `scripts/world/chunk_manager.gd` (add new function after `_generate_alpine_lakes`, around line 583)

- [ ] **Step 1: Write `_evaluate_water_cell` function**

Add after the `_generate_alpine_lakes` function:

```gdscript
func _evaluate_water_cell(cell_coord: Vector2i) -> void:
	## Evaluate a single water cell and potentially add a pond or lake.
	## Deterministic from (cell_coord, noise_seed).
	if evaluated_water_cells.has(cell_coord):
		return
	evaluated_water_cells[cell_coord] = true

	# Deterministic RNG from cell coordinates and world seed
	var cell_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	cell_rng.seed = noise_seed + cell_coord.x * 73856093 + cell_coord.y * 19349663

	# Cell center in world coordinates
	var cell_center_x: float = (cell_coord.x + 0.5) * WATER_CELL_SIZE
	var cell_center_z: float = (cell_coord.y + 0.5) * WATER_CELL_SIZE

	# Check biome at cell center
	var region: RegionType = get_region_at(cell_center_x, cell_center_z)
	var probs: Dictionary = water_cell_probabilities.get(region, {"pond": 0.0, "lake": 0.0})

	# Roll for feature type
	var roll: float = cell_rng.randf()
	var feature_type: String = ""
	if roll < probs["lake"]:
		feature_type = "lake"
	elif roll < probs["lake"] + probs["pond"]:
		feature_type = "pond"
	else:
		return  # No water feature in this cell

	# Jitter position within cell (+/- 30 units from center)
	var jitter_x: float = cell_rng.randf_range(-30.0, 30.0)
	var jitter_z: float = cell_rng.randf_range(-30.0, 30.0)
	var feature_x: float = cell_center_x + jitter_x
	var feature_z: float = cell_center_z + jitter_z

	# Re-check biome at jittered position
	var jittered_region: RegionType = get_region_at(feature_x, feature_z)
	if jittered_region == RegionType.DESERT:
		return  # Landed in desert after jitter

	# Don't place in spawn-safe zone
	if Vector2(feature_x, feature_z).length() < 60.0:
		return

	# Alpine lake check: must be in MOUNTAIN with sufficient elevation
	if feature_type == "lake" and jittered_region == RegionType.MOUNTAIN:
		var elevation: float = _get_base_terrain_height(feature_x, feature_z)
		if elevation < alpine_lake_min_elevation:
			feature_type = "pond"  # Downgrade to pond if not high enough

	# Lake only in MEADOW (or MOUNTAIN for alpine)
	if feature_type == "lake" and jittered_region != RegionType.MEADOW and jittered_region != RegionType.MOUNTAIN:
		feature_type = "pond"  # Downgrade to pond

	# Get region-appropriate parameters
	var params: Dictionary = region_pond_params.get(jittered_region, region_pond_params[RegionType.FOREST])

	var feature_radius: float
	var feature_depth: float
	var wb_type: WaterBodyType

	if feature_type == "lake":
		feature_radius = cell_rng.randf_range(lake_min_radius, lake_max_radius)
		feature_depth = lake_depth
		wb_type = WaterBodyType.LAKE
		if jittered_region == RegionType.MOUNTAIN:
			feature_radius = cell_rng.randf_range(alpine_lake_min_radius, alpine_lake_max_radius)
			feature_depth = alpine_lake_depth
	else:
		feature_radius = cell_rng.randf_range(params["radius_min"], params["radius_max"])
		feature_depth = params["depth"]
		wb_type = WaterBodyType.POND

	water_bodies.append({
		"type": wb_type,
		"center": Vector2(feature_x, feature_z),
		"radius": feature_radius,
		"depth": feature_depth
	})
```

- [ ] **Step 2: Commit**

```bash
git add scripts/world/chunk_manager.gd
git commit -m "Implement water cell evaluation for procedural pond/lake placement"
```

---

### Task 3: Pre-mark inner zone water cells

**Files:**
- Modify: `scripts/world/chunk_manager.gd` (add to `_generate_water_bodies` function, around line 396)

- [ ] **Step 1: Add inner zone marking at end of `_generate_water_bodies`**

Add before the final print statement in `_generate_water_bodies` (before the `print("[ChunkManager] Water features generated..."` line):

```gdscript
	# Pre-mark water cells in the inner zone to prevent procedural duplicates
	_mark_inner_zone_water_cells()
```

- [ ] **Step 2: Write `_mark_inner_zone_water_cells` function**

Add after the `_evaluate_water_cell` function:

```gdscript
func _mark_inner_zone_water_cells() -> void:
	## Mark all water cells within the startup generation bounds as evaluated,
	## so the procedural system doesn't duplicate features in the inner zone.
	## Pond/lake extent: 150 units, alpine lake extent: 180 units.
	var mark_extent: float = 180.0  # Covers the largest startup extent (alpine lakes)
	var cell_min: int = int(floor(-mark_extent / WATER_CELL_SIZE))
	var cell_max: int = int(ceil(mark_extent / WATER_CELL_SIZE))

	for cx: int in range(cell_min, cell_max + 1):
		for cz: int in range(cell_min, cell_max + 1):
			var cell_center_x: float = (cx + 0.5) * WATER_CELL_SIZE
			var cell_center_z: float = (cz + 0.5) * WATER_CELL_SIZE
			if Vector2(cell_center_x, cell_center_z).length() <= mark_extent:
				evaluated_water_cells[Vector2i(cx, cz)] = true

	print("[ChunkManager] Pre-marked %d inner zone water cells" % evaluated_water_cells.size())
```

- [ ] **Step 3: Commit**

```bash
git add scripts/world/chunk_manager.gd
git commit -m "Pre-mark inner zone water cells to prevent duplicate generation"
```

---

### Task 4: Integrate water cell evaluation into chunk loading

**Files:**
- Modify: `scripts/world/chunk_manager.gd:1992` (`_load_chunk` function)

- [ ] **Step 1: Add water cell evaluation call at the start of `_load_chunk`**

In `_load_chunk`, insert the water cell evaluation **before** `chunk.generate()` is called (after `chunk.setup` but before `chunk.generate`). Find this section (around line 2000-2004):

```gdscript
	var chunk: TerrainChunk = TerrainChunk.new()
	chunk.setup(chunk_coord, self)
	chunk.name = "Chunk_%d_%d" % [chunk_coord.x, chunk_coord.y]
	add_child(chunk)
	chunk.generate(is_player_chunk)
```

Replace with:

```gdscript
	var chunk: TerrainChunk = TerrainChunk.new()
	chunk.setup(chunk_coord, self)
	chunk.name = "Chunk_%d_%d" % [chunk_coord.x, chunk_coord.y]
	add_child(chunk)

	# Evaluate procedural water cells overlapping this chunk BEFORE terrain generation
	# so that water body depressions are carved into the height cache correctly.
	_evaluate_water_cells_for_chunk(chunk_coord)

	chunk.generate(is_player_chunk)
```

- [ ] **Step 2: Write `_evaluate_water_cells_for_chunk` function**

Add near `_evaluate_water_cell`:

```gdscript
func _evaluate_water_cells_for_chunk(chunk_coord: Vector2i) -> void:
	## Find all water cells that overlap with this chunk and evaluate them.
	var chunk_world_size: float = chunk_size_cells * cell_size  # 48.0
	var chunk_min_x: float = chunk_coord.x * chunk_world_size
	var chunk_max_x: float = chunk_min_x + chunk_world_size
	var chunk_min_z: float = chunk_coord.y * chunk_world_size
	var chunk_max_z: float = chunk_min_z + chunk_world_size

	# Find water cell range that overlaps this chunk
	var cell_min_x: int = int(floor(chunk_min_x / WATER_CELL_SIZE))
	var cell_max_x: int = int(floor(chunk_max_x / WATER_CELL_SIZE))
	var cell_min_z: int = int(floor(chunk_min_z / WATER_CELL_SIZE))
	var cell_max_z: int = int(floor(chunk_max_z / WATER_CELL_SIZE))

	for cx: int in range(cell_min_x, cell_max_x + 1):
		for cz: int in range(cell_min_z, cell_max_z + 1):
			_evaluate_water_cell(Vector2i(cx, cz))
```

- [ ] **Step 3: Commit**

```bash
git add scripts/world/chunk_manager.gd
git commit -m "Integrate procedural water cell evaluation into chunk loading pipeline"
```

---

### Task 5: Manual verification of ponds and lakes

- [ ] **Step 1: Launch the game and verify**

Run the game in Godot. Walk or teleport beyond 300 units from origin in any non-desert direction. Verify:
- Ponds appear in forest/meadow/hills biomes
- Lakes appear in meadow biomes
- No water features appear in the desert ring (300-360 units)
- The camp pond and inner zone water features still work correctly
- No stuttering when loading new chunks with water features

- [ ] **Step 2: Commit any fixes if needed**

---

## Chunk 2: Spatial Hash for Water Body Lookups

### Task 6: Add spatial hash for `water_bodies` in `get_height_at`

**Files:**
- Modify: `scripts/world/chunk_manager.gd` (add spatial hash data structure and update `get_height_at`)

- [ ] **Step 1: Add spatial hash data structure**

Add near the water cell constants (after `evaluated_water_cells`):

```gdscript
# Spatial hash for efficient water body lookups in get_height_at()
# Keyed by Vector2i bucket coords (bucket_size = WATER_CELL_SIZE = 80 units)
var water_body_spatial_hash: Dictionary = {}  # Vector2i -> Array[int] (indices into water_bodies)
```

- [ ] **Step 2: Write function to register a water body in the spatial hash**

```gdscript
func _register_water_body_in_hash(body_index: int) -> void:
	## Add a water body to the spatial hash buckets it overlaps.
	var body: Dictionary = water_bodies[body_index]
	var center: Vector2 = body["center"]
	var radius: float = body["radius"]

	# Find all buckets this body overlaps (center +/- radius)
	var min_bx: int = int(floor((center.x - radius) / WATER_CELL_SIZE))
	var max_bx: int = int(floor((center.x + radius) / WATER_CELL_SIZE))
	var min_bz: int = int(floor((center.y - radius) / WATER_CELL_SIZE))
	var max_bz: int = int(floor((center.y + radius) / WATER_CELL_SIZE))

	for bx: int in range(min_bx, max_bx + 1):
		for bz: int in range(min_bz, max_bz + 1):
			var key: Vector2i = Vector2i(bx, bz)
			if not water_body_spatial_hash.has(key):
				water_body_spatial_hash[key] = []
			water_body_spatial_hash[key].append(body_index)
```

- [ ] **Step 3: Register startup water bodies after generation**

At the end of `_generate_water_bodies`, before the print statement, add:

```gdscript
	# Build spatial hash for all startup water bodies
	_rebuild_water_body_spatial_hash()
```

And add the rebuild function:

```gdscript
func _rebuild_water_body_spatial_hash() -> void:
	## Rebuild spatial hash from scratch for all current water bodies.
	water_body_spatial_hash.clear()
	for i: int in range(water_bodies.size()):
		_register_water_body_in_hash(i)
```

- [ ] **Step 4: Register procedural water bodies when created**

In `_evaluate_water_cell`, after the `water_bodies.append(...)` call, add:

```gdscript
	_register_water_body_in_hash(water_bodies.size() - 1)
```

- [ ] **Step 5: Write spatial hash lookup function**

```gdscript
func _get_nearby_water_bodies(x: float, z: float) -> Array:
	## Return indices of water bodies that could affect the given position.
	var bx: int = int(floor(x / WATER_CELL_SIZE))
	var bz: int = int(floor(z / WATER_CELL_SIZE))
	var key: Vector2i = Vector2i(bx, bz)
	if water_body_spatial_hash.has(key):
		return water_body_spatial_hash[key]
	return []
```

- [ ] **Step 6: Update `get_height_at` to use spatial hash**

Replace the water body loop in `get_height_at` (around line 1628). Find:

```gdscript
	# Check all water bodies (ponds and lakes) for terrain depression
	for body in water_bodies:
		var body_center: Vector2 = body["center"]
		var body_radius: float = body["radius"]
		var body_depth: float = body["depth"]

		var distance_from_body: float = Vector2(snapped_x - body_center.x, snapped_z - body_center.y).length()
		if distance_from_body < body_radius:
			var pond_factor: float = distance_from_body / body_radius
			var pond_floor_y: float = -body_depth  # Deep enough for swimming
			# Pond floor is deep, edges ramp up to normal terrain
			if pond_factor < 0.7:
				return pond_floor_y  # Flat pond floor (deep)
			else:
				# Gradual slope from pond floor to terrain edge
				var edge_factor: float = (pond_factor - 0.7) / 0.3
				return pond_floor_y + (height_step - pond_floor_y) * edge_factor
```

Replace with:

```gdscript
	# Check nearby water bodies (ponds and lakes) for terrain depression
	var nearby_body_indices: Array = _get_nearby_water_bodies(snapped_x, snapped_z)
	for body_idx: int in nearby_body_indices:
		var body: Dictionary = water_bodies[body_idx]
		var body_center: Vector2 = body["center"]
		var body_radius: float = body["radius"]
		var body_depth: float = body["depth"]

		var distance_from_body: float = Vector2(snapped_x - body_center.x, snapped_z - body_center.y).length()
		if distance_from_body < body_radius:
			var pond_factor: float = distance_from_body / body_radius
			var pond_floor_y: float = -body_depth  # Deep enough for swimming
			# Pond floor is deep, edges ramp up to normal terrain
			if pond_factor < 0.7:
				return pond_floor_y  # Flat pond floor (deep)
			else:
				# Gradual slope from pond floor to terrain edge
				var edge_factor: float = (pond_factor - 0.7) / 0.3
				return pond_floor_y + (height_step - pond_floor_y) * edge_factor
```

- [ ] **Step 7: Commit**

```bash
git add scripts/world/chunk_manager.gd
git commit -m "Add spatial hash for water body lookups in get_height_at for O(1) performance"
```

---

## Chunk 3: Procedural River Grid

### Task 7: Add river cell grid data structures

**Files:**
- Modify: `scripts/world/chunk_manager.gd` (add near water cell constants)

- [ ] **Step 1: Add river cell constants**

Add after the water cell constants:

```gdscript
# Procedural river cell grid (200x200 units per cell)
const RIVER_CELL_SIZE: float = 200.0
const RIVER_CELL_PROBABILITY: float = 0.25  # 25% chance per valid cell
const PROCEDURAL_RIVER_MAX_SEGMENTS: int = 12  # Shorter than startup rivers
var evaluated_river_cells: Dictionary = {}  # Vector2i -> bool
```

- [ ] **Step 2: Commit**

```bash
git add scripts/world/chunk_manager.gd
git commit -m "Add river cell grid constants for procedural river generation"
```

---

### Task 8: Implement river cell evaluation function

**Files:**
- Modify: `scripts/world/chunk_manager.gd`

- [ ] **Step 1: Write `_evaluate_river_cell` function**

```gdscript
func _evaluate_river_cell(cell_coord: Vector2i) -> void:
	## Evaluate a single river cell and potentially generate a river.
	## Deterministic from (cell_coord, noise_seed).
	if evaluated_river_cells.has(cell_coord):
		return
	evaluated_river_cells[cell_coord] = true

	# Deterministic RNG from cell coordinates and world seed
	var cell_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	cell_rng.seed = noise_seed + 7000 + cell_coord.x * 48611 + cell_coord.y * 29423

	# Roll probability
	if cell_rng.randf() > RIVER_CELL_PROBABILITY:
		return

	# Candidate source position (jittered within cell)
	var cell_center_x: float = (cell_coord.x + 0.5) * RIVER_CELL_SIZE
	var cell_center_z: float = (cell_coord.y + 0.5) * RIVER_CELL_SIZE
	var source_x: float = cell_center_x + cell_rng.randf_range(-80.0, 80.0)
	var source_z: float = cell_center_z + cell_rng.randf_range(-80.0, 80.0)

	# Must be in HILLS or ROCKY biome
	var region: RegionType = get_region_at(source_x, source_z)
	if region != RegionType.HILLS and region != RegionType.ROCKY:
		return

	# Don't place in spawn-safe zone
	if Vector2(source_x, source_z).length() < 60.0:
		return

	# Check distance from existing rivers
	var source: Vector2 = Vector2(source_x, source_z)
	for existing_river: Dictionary in rivers:
		if existing_river["path"].size() > 0:
			if source.distance_to(existing_river["path"][0]) < 60.0:
				return

	# Generate river path (shorter than startup rivers)
	var saved_max_segments: int = 20  # Save the default used by _generate_river_path
	var river_path: Array[Vector2] = _generate_river_path(source, cell_rng)

	# Filter to max length from source
	var capped_path: Array[Vector2] = [river_path[0]]
	for i: int in range(1, river_path.size()):
		if river_path[i].distance_to(source) > 200.0:
			break
		capped_path.append(river_path[i])
		if capped_path.size() >= PROCEDURAL_RIVER_MAX_SEGMENTS:
			break

	if capped_path.size() < 4:
		return  # Too short

	# Smooth and add fishing pools
	capped_path = _smooth_river_path(capped_path)
	var fishing_pools: Array[Vector2] = _place_fishing_pools(capped_path)

	rivers.append({
		"path": capped_path,
		"width": river_base_width,
		"fishing_pools": fishing_pools
	})
```

- [ ] **Step 2: Commit**

```bash
git add scripts/world/chunk_manager.gd
git commit -m "Implement river cell evaluation for procedural river generation"
```

---

### Task 9: Pre-mark inner zone river cells and integrate with chunk loading

**Files:**
- Modify: `scripts/world/chunk_manager.gd`

- [ ] **Step 1: Add river cell marking to `_mark_inner_zone_water_cells`**

Append to the end of `_mark_inner_zone_water_cells`:

```gdscript
	# Also mark river cells in the inner zone (river source extent: 120 units)
	var river_mark_extent: float = 120.0
	var river_cell_min: int = int(floor(-river_mark_extent / RIVER_CELL_SIZE))
	var river_cell_max: int = int(ceil(river_mark_extent / RIVER_CELL_SIZE))

	for cx: int in range(river_cell_min, river_cell_max + 1):
		for cz: int in range(river_cell_min, river_cell_max + 1):
			var cell_center_x: float = (cx + 0.5) * RIVER_CELL_SIZE
			var cell_center_z: float = (cz + 0.5) * RIVER_CELL_SIZE
			if Vector2(cell_center_x, cell_center_z).length() <= river_mark_extent:
				evaluated_river_cells[Vector2i(cx, cz)] = true

	print("[ChunkManager] Pre-marked %d inner zone river cells" % evaluated_river_cells.size())
```

- [ ] **Step 2: Add river cell evaluation to `_evaluate_water_cells_for_chunk`**

Append to the end of `_evaluate_water_cells_for_chunk`:

```gdscript
	# Also evaluate river cells (larger grid: 200x200)
	var river_cell_min_x: int = int(floor(chunk_min_x / RIVER_CELL_SIZE))
	var river_cell_max_x: int = int(floor(chunk_max_x / RIVER_CELL_SIZE))
	var river_cell_min_z: int = int(floor(chunk_min_z / RIVER_CELL_SIZE))
	var river_cell_max_z: int = int(floor(chunk_max_z / RIVER_CELL_SIZE))

	for cx: int in range(river_cell_min_x, river_cell_max_x + 1):
		for cz: int in range(river_cell_min_z, river_cell_max_z + 1):
			_evaluate_river_cell(Vector2i(cx, cz))
```

- [ ] **Step 3: Commit**

```bash
git add scripts/world/chunk_manager.gd
git commit -m "Pre-mark inner river cells and integrate river evaluation into chunk loading"
```

---

### Task 10: Final verification and cleanup

- [ ] **Step 1: Launch game and verify full system**

Run the game in Godot. Explore in all directions beyond the desert ring (>360 units). Verify:
- Ponds appear in appropriate biomes (forest, meadow, hills, mountain)
- Lakes appear in meadow and mountain biomes
- Rivers appear in hills/rocky biomes, flowing downhill
- No water features in desert ring or pocket desert
- Inner zone water features unchanged
- No stuttering or frame drops when exploring new areas
- Fishing spots appear at procedural ponds

- [ ] **Step 2: Push all changes**

```bash
git push origin main
```

- [ ] **Step 3: Update DEV_LOG.md**

Add a new session entry documenting the procedural water generation feature.
