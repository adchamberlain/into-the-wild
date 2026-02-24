extends Node3D
class_name TerrainChunk
## Represents a single chunk of terrain that can be dynamically loaded/unloaded.

# Chunk identification
var chunk_coord: Vector2i  # Chunk coordinates (not world coordinates)
var chunk_manager: Node  # Reference to parent ChunkManager

# Chunk geometry
var terrain_mesh: MeshInstance3D
var terrain_collision: StaticBody3D
var decorations_container: Node3D
var trees_container: Node3D
var resources_container: Node3D

# Track what we've spawned for cleanup
var spawned_trees: Array[Node3D] = []
var spawned_resources: Array[Node3D] = []
var spawned_animals: Array[Node3D] = []
var is_generated: bool = false
var _local_resource_index: int = 0  # Deterministic naming counter for chunk resources

# Shared materials (static to avoid shader compilation per decoration)
static var _grass_mat: StandardMaterial3D = null
static var _flower_stem_mat: StandardMaterial3D = null
static var _flower_red_mat: StandardMaterial3D = null
static var _flower_yellow_mat: StandardMaterial3D = null
# Scatter decoration materials
static var _rock_gray_mat: StandardMaterial3D = null
static var _rock_brown_mat: StandardMaterial3D = null
static var _rock_dark_mat: StandardMaterial3D = null
static var _bush_dark_mat: StandardMaterial3D = null
static var _bush_mid_mat: StandardMaterial3D = null
static var _log_mat: StandardMaterial3D = null
static var _stump_mat: StandardMaterial3D = null
static var _stump_top_mat: StandardMaterial3D = null
static var _stump_ring_mat: StandardMaterial3D = null
static var _blossom_mat: StandardMaterial3D = null


static func _get_grass_material() -> StandardMaterial3D:
	if not _grass_mat:
		_grass_mat = StandardMaterial3D.new()
		_grass_mat.vertex_color_use_as_albedo = true
		_grass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _grass_mat


static func _get_flower_stem_material() -> StandardMaterial3D:
	if not _flower_stem_mat:
		_flower_stem_mat = StandardMaterial3D.new()
		_flower_stem_mat.albedo_color = Color(0.2, 0.5, 0.15)
	return _flower_stem_mat


static func _get_flower_material(color: Color) -> StandardMaterial3D:
	# Use red or yellow based on color
	if color.r > color.g:
		if not _flower_red_mat:
			_flower_red_mat = StandardMaterial3D.new()
			_flower_red_mat.albedo_color = Color(0.9, 0.2, 0.2)
		return _flower_red_mat
	else:
		if not _flower_yellow_mat:
			_flower_yellow_mat = StandardMaterial3D.new()
			_flower_yellow_mat.albedo_color = Color(0.95, 0.9, 0.2)
		return _flower_yellow_mat


static func _get_rock_material(variant: int) -> StandardMaterial3D:
	match variant:
		0:
			if not _rock_gray_mat:
				_rock_gray_mat = StandardMaterial3D.new()
				_rock_gray_mat.albedo_color = Color(0.62, 0.6, 0.55)
			return _rock_gray_mat
		1:
			if not _rock_brown_mat:
				_rock_brown_mat = StandardMaterial3D.new()
				_rock_brown_mat.albedo_color = Color(0.5, 0.48, 0.4)
			return _rock_brown_mat
		_:
			if not _rock_dark_mat:
				_rock_dark_mat = StandardMaterial3D.new()
				_rock_dark_mat.albedo_color = Color(0.45, 0.47, 0.4)
			return _rock_dark_mat


static func _get_bush_material(dark: bool) -> StandardMaterial3D:
	if dark:
		if not _bush_dark_mat:
			_bush_dark_mat = StandardMaterial3D.new()
			_bush_dark_mat.albedo_color = Color(0.2, 0.5, 0.18)
		return _bush_dark_mat
	else:
		if not _bush_mid_mat:
			_bush_mid_mat = StandardMaterial3D.new()
			_bush_mid_mat.albedo_color = Color(0.3, 0.6, 0.25)
		return _bush_mid_mat


static func _get_log_material() -> StandardMaterial3D:
	if not _log_mat:
		_log_mat = StandardMaterial3D.new()
		_log_mat.albedo_color = Color(0.4, 0.28, 0.15)
	return _log_mat


static func _get_stump_material() -> StandardMaterial3D:
	if not _stump_mat:
		_stump_mat = StandardMaterial3D.new()
		_stump_mat.albedo_color = Color(0.45, 0.32, 0.18)
	return _stump_mat


static func _get_stump_top_material() -> StandardMaterial3D:
	if not _stump_top_mat:
		_stump_top_mat = StandardMaterial3D.new()
		_stump_top_mat.albedo_color = Color(0.78, 0.65, 0.45)  # Light wood
	return _stump_top_mat


static func _get_stump_ring_material() -> StandardMaterial3D:
	if not _stump_ring_mat:
		_stump_ring_mat = StandardMaterial3D.new()
		_stump_ring_mat.albedo_color = Color(0.55, 0.42, 0.28)  # Darker ring
	return _stump_ring_mat


static func _get_blossom_material() -> StandardMaterial3D:
	if not _blossom_mat:
		_blossom_mat = StandardMaterial3D.new()
		_blossom_mat.albedo_color = Color(0.95, 0.85, 0.88)  # Soft pink-white
	return _blossom_mat


func setup(coord: Vector2i, manager: Node) -> void:
	chunk_coord = coord
	chunk_manager = manager


## Batching configuration - controls how many items spawn per frame to prevent stuttering
const TREES_PER_BATCH: int = 6  # Trees are expensive (collision, etc.)
const RESOURCES_PER_BATCH: int = 10
const DECORATIONS_PER_BATCH: int = 15
const MESH_ROWS_PER_BATCH: int = 2  # Terrain mesh rows per frame (reduced from 6 to ~8ms/batch)
const COLLISION_ROWS_PER_BATCH: int = 4  # Collision rows per frame (64 shapes/frame, completes in 4 frames)
const HEIGHTCACHE_ROWS_PER_BATCH: int = 4  # Height cache rows per frame (~72 get_height_at calls/batch)

# Concurrency slot tracking
var _holds_generation_slot: bool = false


func generate(sync_collision: bool = true) -> void:
	if is_generated:
		return
	is_generated = true  # Set early to prevent re-entry

	if sync_collision:
		# Player's chunk: fully synchronous height cache + collision
		_build_height_cache()
		_generate_collision_from_mesh(true)
		# Fire-and-forget async mesh + spawning (no slot needed for player chunk)
		_generate_terrain_async()
	else:
		# Distant chunks: full async pipeline with concurrency limiting
		_generate_async_full()


func _generate_async_full() -> void:
	## Full async pipeline with concurrency slot management.
	## Waits for a slot, then runs height cache + collision + mesh in batches.
	## Releases slot before lighter spawning work.

	# Wait for a generation slot
	while chunk_manager._active_heavy_generations >= chunk_manager.MAX_CONCURRENT_HEAVY_GENERATIONS:
		await chunk_manager.heavy_generation_slot_available
		if not is_inside_tree():
			return

	# Acquire slot
	chunk_manager._active_heavy_generations += 1
	_holds_generation_slot = true

	# Batched height cache (~5 frames)
	await _build_height_cache_batched()
	if not is_inside_tree():
		_release_generation_slot()
		return

	# Start batched collision (fire-and-forget coroutine)
	_generate_collision_from_mesh(false)

	# Separate collision start from mesh start
	await get_tree().process_frame
	if not is_inside_tree():
		_release_generation_slot()
		return

	# Batched mesh generation (~8 frames)
	await _generate_terrain_mesh_batched()
	if not is_inside_tree():
		_release_generation_slot()
		return

	# Release slot before lighter spawning work
	_release_generation_slot()

	# Continue with spawning (no slot needed - these are lightweight)
	await get_tree().process_frame
	if not is_inside_tree():
		return
	await _spawn_chunk_trees()

	if not is_inside_tree():
		return
	await get_tree().process_frame
	await _spawn_chunk_resources()

	if not is_inside_tree():
		return
	await get_tree().process_frame
	await _spawn_chunk_decorations()

	if not is_inside_tree():
		return
	await get_tree().process_frame
	_spawn_chunk_animals()


func _release_generation_slot() -> void:
	if _holds_generation_slot:
		chunk_manager._active_heavy_generations -= 1
		_holds_generation_slot = false
		chunk_manager.heavy_generation_slot_available.emit()


func _generate_terrain_async() -> void:
	## Async pipeline for player chunk: mesh generation spread across frames, then spawning.
	## No slot management needed - player chunk runs without concurrency limits.
	await _generate_terrain_mesh_batched()

	# Chain to tree spawning after mesh is complete
	if not is_inside_tree():
		return
	await get_tree().process_frame
	await _spawn_chunk_trees()

	if not is_inside_tree():
		return
	await get_tree().process_frame
	await _spawn_chunk_resources()

	if not is_inside_tree():
		return
	await get_tree().process_frame
	await _spawn_chunk_decorations()

	if not is_inside_tree():
		return
	await get_tree().process_frame
	_spawn_chunk_animals()


# Cached height values for this chunk (includes 1 cell border for neighbor lookups)
var _height_cache: Array = []
var _height_cache_size: int = 0


func _build_height_cache() -> void:
	## Pre-compute and cache all heights for this chunk (synchronous).
	## Used for player's chunk where we need immediate collision.
	## Pit prevention is done as post-processing on the cache instead of
	## recursive calls inside get_height_at() - saves ~80% of computation.
	var cell_size: float = chunk_manager.cell_size
	var chunk_size_cells: int = chunk_manager.chunk_size_cells
	var chunk_world_x: float = chunk_coord.x * chunk_size_cells * cell_size
	var chunk_world_z: float = chunk_coord.y * chunk_size_cells * cell_size

	_height_cache_size = chunk_size_cells + 2  # +2 for border cells
	_height_cache.resize(_height_cache_size)

	# Skip pit prevention during build (applied as post-processing below)
	for cz in range(_height_cache_size):
		_height_cache[cz] = []
		_height_cache[cz].resize(_height_cache_size)
		for cx in range(_height_cache_size):
			var world_x: float = chunk_world_x + ((cx - 1) * cell_size) + cell_size / 2.0
			var world_z: float = chunk_world_z + ((cz - 1) * cell_size) + cell_size / 2.0
			_height_cache[cz][cx] = chunk_manager.get_height_at(world_x, world_z, true)

	# Post-process: fix pits using cached neighbor heights (replaces recursive calls)
	_apply_pit_prevention()
	# Post-process: smooth isolated 1-block bumps in flat terrain
	_apply_flat_smoothing()


func _build_height_cache_batched() -> void:
	## Batched version of _build_height_cache() - yields every HEIGHTCACHE_ROWS_PER_BATCH rows.
	## Each batch: 4 rows x 18 cols = 72 get_height_at() calls.
	## Pit prevention skipped during build and applied as post-processing.
	var cell_size: float = chunk_manager.cell_size
	var chunk_size_cells: int = chunk_manager.chunk_size_cells
	var chunk_world_x: float = chunk_coord.x * chunk_size_cells * cell_size
	var chunk_world_z: float = chunk_coord.y * chunk_size_cells * cell_size

	_height_cache_size = chunk_size_cells + 2  # +2 for border cells
	_height_cache.resize(_height_cache_size)

	# Skip pit prevention during build (applied as post-processing below).
	# We pass skip_pit_check=true to get_height_at() instead of using the shared
	# _in_pit_check flag, which would stay set across yields and interfere with
	# other concurrent chunks' height calculations.
	var rows_this_batch: int = 0
	for cz in range(_height_cache_size):
		_height_cache[cz] = []
		_height_cache[cz].resize(_height_cache_size)
		for cx in range(_height_cache_size):
			var world_x: float = chunk_world_x + ((cx - 1) * cell_size) + cell_size / 2.0
			var world_z: float = chunk_world_z + ((cz - 1) * cell_size) + cell_size / 2.0
			_height_cache[cz][cx] = chunk_manager.get_height_at(world_x, world_z, true)

		rows_this_batch += 1
		if rows_this_batch >= HEIGHTCACHE_ROWS_PER_BATCH:
			rows_this_batch = 0
			await get_tree().process_frame
			if not is_inside_tree():
				return

	# Post-process: fix pits using cached neighbor heights
	_apply_pit_prevention()
	# Post-process: smooth isolated 1-block bumps in flat terrain
	_apply_flat_smoothing()


func _apply_pit_prevention() -> void:
	## Post-process height cache to prevent inescapable pits.
	## A cell is a "pit" if it's more than 1 block below ALL cardinal neighbors.
	## Uses cached neighbor heights instead of recursive get_height_at() calls,
	## eliminating ~1300 redundant height computations per chunk.
	for cz in range(1, _height_cache_size - 1):
		for cx in range(1, _height_cache_size - 1):
			var height: float = _height_cache[cz][cx]
			var min_neighbor: float = _height_cache[cz - 1][cx]  # North
			var south: float = _height_cache[cz + 1][cx]
			if south < min_neighbor:
				min_neighbor = south
			var west: float = _height_cache[cz][cx - 1]
			if west < min_neighbor:
				min_neighbor = west
			var east: float = _height_cache[cz][cx + 1]
			if east < min_neighbor:
				min_neighbor = east
			if min_neighbor - height > 1.0:
				_height_cache[cz][cx] = min_neighbor - 1.0


func _apply_flat_smoothing() -> void:
	## Smooth isolated 1-block bumps in flat terrain.
	## If a cell is exactly 1 height step above ALL 4 cardinal neighbors,
	## it's an isolated bump - snap it down to match the surrounding flat area.
	## This prevents annoying single-block bumps that catch the player in
	## otherwise flat terrain. Changes are collected first to avoid modifying
	## the cache during iteration.
	var smoothed: Array[Vector3] = []  # Vector3(cx, cz, new_height)

	for cz in range(1, _height_cache_size - 1):
		for cx in range(1, _height_cache_size - 1):
			var height: float = _height_cache[cz][cx]
			var north: float = _height_cache[cz - 1][cx]
			var south: float = _height_cache[cz + 1][cx]
			var west: float = _height_cache[cz][cx - 1]
			var east: float = _height_cache[cz][cx + 1]
			var max_neighbor: float = maxf(north, maxf(south, maxf(west, east)))

			# Cell is ~1 step above ALL neighbors - isolated bump
			var diff: float = height - max_neighbor
			if diff >= 0.9 and diff <= 1.5:
				smoothed.append(Vector3(cx, cz, max_neighbor))

	for v: Vector3 in smoothed:
		_height_cache[int(v.y)][int(v.x)] = v.z


func _get_cached_height_at(world_x: float, world_z: float) -> float:
	## Look up terrain height from the post-processed height cache.
	## Falls back to get_height_at() if position is outside this chunk's cache.
	if _height_cache.is_empty():
		return chunk_manager.get_height_at(world_x, world_z)
	var cell_size: float = chunk_manager.cell_size
	var chunk_size_cells: int = chunk_manager.chunk_size_cells
	var chunk_world_x: float = chunk_coord.x * chunk_size_cells * cell_size
	var chunk_world_z: float = chunk_coord.y * chunk_size_cells * cell_size
	var cx: int = int(floor((world_x - chunk_world_x) / cell_size))
	var cz: int = int(floor((world_z - chunk_world_z) / cell_size))
	# Cache indices have +1 offset for border cells
	var cache_x: int = cx + 1
	var cache_z: int = cz + 1
	if cache_x >= 0 and cache_x < _height_cache_size and cache_z >= 0 and cache_z < _height_cache_size:
		return _height_cache[cache_z][cache_x]
	return chunk_manager.get_height_at(world_x, world_z)


func _generate_terrain_mesh_batched() -> void:
	## Generate terrain mesh in batches across multiple frames to prevent stuttering.
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var cell_size: float = chunk_manager.cell_size
	var chunk_size_cells: int = chunk_manager.chunk_size_cells
	var chunk_world_x: float = chunk_coord.x * chunk_size_cells * cell_size
	var chunk_world_z: float = chunk_coord.y * chunk_size_cells * cell_size

	var rows_this_batch: int = 0

	# Generate each cell in this chunk, yielding every MESH_ROWS_PER_BATCH rows
	for cz in range(chunk_size_cells):
		for cx in range(chunk_size_cells):
			var world_x: float = chunk_world_x + (cx * cell_size)
			var world_z: float = chunk_world_z + (cz * cell_size)

			# Skip cells inside cave tunnels (cave has its own floor/walls)
			var cell_center_x: float = world_x + cell_size / 2.0
			var cell_center_z: float = world_z + cell_size / 2.0
			if chunk_manager.is_inside_cave_tunnel(cell_center_x, cell_center_z):
				continue

			# Get height from cache (offset by 1 for border)
			var height: float = _height_cache[cz + 1][cx + 1]

			# Create top face
			_add_top_face_cached(surface_tool, world_x, world_z, cell_size, height, cx, cz)

			# Create side faces where there's height difference
			_add_side_faces_cached(surface_tool, world_x, world_z, cell_size, height, cx, cz, chunk_size_cells)

		# Yield after each batch of rows to spread work across frames
		rows_this_batch += 1
		if rows_this_batch >= MESH_ROWS_PER_BATCH:
			rows_this_batch = 0
			await get_tree().process_frame
			if not is_inside_tree():
				return

	var mesh: ArrayMesh = surface_tool.commit()

	terrain_mesh = MeshInstance3D.new()
	terrain_mesh.mesh = mesh
	terrain_mesh.material_override = chunk_manager.get_terrain_material()
	add_child(terrain_mesh)
	# Note: Height cache is cleared in unload() to allow async box collision to complete


func _add_top_face_cached(st: SurfaceTool, x: float, z: float, size: float, height: float, cx: int, cz: int) -> void:
	# Use cached height values for AO calculations
	var v0 := Vector3(x, height, z)
	var v1 := Vector3(x + size, height, z)
	var v2 := Vector3(x + size, height, z + size)
	var v3 := Vector3(x, height, z + size)

	var normal := Vector3.UP

	# Get cell center for region lookup
	var center_x: float = x + size / 2.0
	var center_z: float = z + size / 2.0

	# Get region-specific colors
	var region: ChunkManager.RegionType = chunk_manager.get_region_at(center_x, center_z)
	var region_colors: Dictionary = chunk_manager.get_region_colors(region)
	var grass_color: Color = region_colors["grass"]

	# Desert transition zone blending (organic boundaries)
	var spawn_dist: float = Vector2(center_x, center_z).length()
	var desert_bounds: Vector2 = chunk_manager.get_desert_boundaries(center_x, center_z)
	var d_inner: float = desert_bounds.x
	var d_outer: float = desert_bounds.y
	if spawn_dist >= d_inner - 20.0 and spawn_dist < d_inner:
		# Inner transition: blend from normal region to desert
		var blend: float = (spawn_dist - (d_inner - 20.0)) / 20.0
		var desert_colors: Dictionary = chunk_manager.region_colors[ChunkManager.RegionType.DESERT]
		grass_color = grass_color.lerp(desert_colors["grass"], blend)
	elif spawn_dist > d_outer and spawn_dist <= d_outer + 20.0:
		# Outer transition: blend from desert to normal region
		var blend: float = 1.0 - (spawn_dist - d_outer) / 20.0
		var desert_colors: Dictionary = chunk_manager.region_colors[ChunkManager.RegionType.DESERT]
		grass_color = grass_color.lerp(desert_colors["grass"], blend)

	# Color variation based on world position for consistency across chunks
	var world_cx: int = chunk_coord.x * chunk_manager.chunk_size_cells + cx
	var world_cz: int = chunk_coord.y * chunk_manager.chunk_size_cells + cz
	var variation: float = sin(world_cx * 12.9898 + world_cz * 78.233) * 0.08

	var cell_grass: Color = Color(
		clamp(grass_color.r + variation, grass_color.r - 0.08, grass_color.r + 0.10),
		clamp(grass_color.g + variation * 0.5, grass_color.g - 0.07, grass_color.g + 0.10),
		clamp(grass_color.b + variation * 0.3, grass_color.b - 0.07, grass_color.b + 0.07)
	)

	# Calculate vertex AO using cached heights
	# Each corner samples its 3 adjacent neighbors for occlusion
	var ao0: float = _calculate_vertex_ao_cached(cx, cz, height, -1, -1)  # NW corner
	var ao1: float = _calculate_vertex_ao_cached(cx, cz, height, 1, -1)   # NE corner
	var ao2: float = _calculate_vertex_ao_cached(cx, cz, height, 1, 1)    # SE corner
	var ao3: float = _calculate_vertex_ao_cached(cx, cz, height, -1, 1)   # SW corner

	# Apply AO to colors
	var color0: Color = cell_grass * ao0
	var color1: Color = cell_grass * ao1
	var color2: Color = cell_grass * ao2
	var color3: Color = cell_grass * ao3

	# Get UV coordinates for top face
	var uvs: Array[Vector2]
	if region == ChunkManager.RegionType.ROCKY:
		uvs = TerrainTextures.get_stone_uvs()
	else:
		uvs = TerrainTextures.get_top_face_uvs()

	# Triangle 1: v0, v2, v1
	st.set_color(color0)
	st.set_normal(normal)
	st.set_uv(uvs[0])
	st.add_vertex(v0)
	st.set_color(color2)
	st.set_normal(normal)
	st.set_uv(uvs[2])
	st.add_vertex(v2)
	st.set_color(color1)
	st.set_normal(normal)
	st.set_uv(uvs[1])
	st.add_vertex(v1)

	# Triangle 2: v0, v3, v2
	st.set_color(color0)
	st.set_normal(normal)
	st.set_uv(uvs[0])
	st.add_vertex(v0)
	st.set_color(color3)
	st.set_normal(normal)
	st.set_uv(uvs[3])
	st.add_vertex(v3)
	st.set_color(color2)
	st.set_normal(normal)
	st.set_uv(uvs[2])
	st.add_vertex(v2)


func _calculate_vertex_ao_cached(cx: int, cz: int, current_height: float, dir_x: int, dir_z: int) -> float:
	# Use cached heights for AO calculation
	var ao_strength: float = 0.12

	# Cache indices (offset by 1 for border)
	var base_cx: int = cx + 1
	var base_cz: int = cz + 1

	# Sample the 3 neighbors that share this corner
	var neighbor_x_height: float = _height_cache[base_cz][base_cx + dir_x]
	var neighbor_z_height: float = _height_cache[base_cz + dir_z][base_cx]
	var neighbor_diag_height: float = _height_cache[base_cz + dir_z][base_cx + dir_x]

	# Count how many neighbors are higher
	var occlusion_count: int = 0
	if neighbor_x_height > current_height:
		occlusion_count += 1
	if neighbor_z_height > current_height:
		occlusion_count += 1
	if neighbor_diag_height > current_height:
		occlusion_count += 1

	var ao: float = 1.0 - (occlusion_count * ao_strength)
	return clamp(ao, 0.55, 1.0)


func _add_side_faces_cached(st: SurfaceTool, x: float, z: float, size: float, height: float, cx: int, cz: int, chunk_size_cells: int) -> void:
	# Use cached heights for neighbor lookups (offset by 1 for border)
	var base_cx: int = cx + 1
	var base_cz: int = cz + 1

	# Pre-fetch all cardinal neighbor heights from cache for AO computation
	var h_north: float = _height_cache[base_cz - 1][base_cx]
	var h_south: float = _height_cache[base_cz + 1][base_cx]
	var h_west: float = _height_cache[base_cz][base_cx - 1]
	var h_east: float = _height_cache[base_cz][base_cx + 1]

	# North side (z-): face normal=(0,0,-1), behind=south, front=north, perp=east/west
	if height > h_north:
		var ao_top: float = 1.0 if h_south <= height else 0.85
		var ao_bottom: float = _calc_side_ao_bottom_cached(h_north, h_north, h_east, h_west)
		_add_side_quad_ao(st, Vector3(x, height, z), Vector3(x + size, height, z),
					   Vector3(x + size, h_north, z), Vector3(x, h_north, z),
					   Vector3(0, 0, -1), ao_top, ao_bottom)

	# South side (z+): face normal=(0,0,1), behind=north, front=south, perp=west/east
	if height > h_south:
		var ao_top: float = 1.0 if h_north <= height else 0.85
		var ao_bottom: float = _calc_side_ao_bottom_cached(h_south, h_south, h_west, h_east)
		_add_side_quad_ao(st, Vector3(x + size, height, z + size), Vector3(x, height, z + size),
					   Vector3(x, h_south, z + size), Vector3(x + size, h_south, z + size),
					   Vector3(0, 0, 1), ao_top, ao_bottom)

	# West side (x-): face normal=(-1,0,0), behind=east, front=west, perp=south/north
	if height > h_west:
		var ao_top: float = 1.0 if h_east <= height else 0.85
		var ao_bottom: float = _calc_side_ao_bottom_cached(h_west, h_west, h_south, h_north)
		_add_side_quad_ao(st, Vector3(x, height, z + size), Vector3(x, height, z),
					   Vector3(x, h_west, z), Vector3(x, h_west, z + size),
					   Vector3(-1, 0, 0), ao_top, ao_bottom)

	# East side (x+): face normal=(1,0,0), behind=west, front=east, perp=north/south
	if height > h_east:
		var ao_top: float = 1.0 if h_west <= height else 0.85
		var ao_bottom: float = _calc_side_ao_bottom_cached(h_east, h_east, h_north, h_south)
		_add_side_quad_ao(st, Vector3(x + size, height, z), Vector3(x + size, height, z + size),
					   Vector3(x + size, h_east, z + size), Vector3(x + size, h_east, z),
					   Vector3(1, 0, 0), ao_top, ao_bottom)


func _calc_side_ao_bottom_cached(bottom_height: float, front_h: float, left_h: float, right_h: float) -> float:
	## Calculate AO for bottom vertices of a side face using cached heights.
	var ao_strength: float = 0.10
	var occlusion_count: int = 0
	if front_h > bottom_height:
		occlusion_count += 1
	if left_h > bottom_height:
		occlusion_count += 1
	if right_h > bottom_height:
		occlusion_count += 1
	var ao: float = 0.90 - (occlusion_count * ao_strength)
	return clamp(ao, 0.55, 0.95)






func _add_side_quad_ao(st: SurfaceTool, v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3, normal: Vector3, ao_top: float, ao_bottom: float) -> void:
	## Draw a side face quad with pre-computed AO values (avoids expensive get_height_at calls).
	# Get region-specific colors based on position
	var center_x: float = (v0.x + v1.x) / 2.0
	var center_z: float = (v0.z + v2.z) / 2.0
	var region: ChunkManager.RegionType = chunk_manager.get_region_at(center_x, center_z)
	var region_colors: Dictionary = chunk_manager.get_region_colors(region)
	var grass_color: Color = region_colors["grass"]
	var dirt_color: Color = region_colors["dirt"]

	# Desert transition zone blending (organic boundaries)
	var spawn_dist: float = Vector2(center_x, center_z).length()
	var desert_bounds: Vector2 = chunk_manager.get_desert_boundaries(center_x, center_z)
	var d_inner: float = desert_bounds.x
	var d_outer: float = desert_bounds.y
	if spawn_dist >= d_inner - 20.0 and spawn_dist < d_inner:
		# Inner transition: blend from normal region to desert
		var blend: float = (spawn_dist - (d_inner - 20.0)) / 20.0
		var desert_colors: Dictionary = chunk_manager.region_colors[ChunkManager.RegionType.DESERT]
		grass_color = grass_color.lerp(desert_colors["grass"], blend)
		dirt_color = dirt_color.lerp(desert_colors["dirt"], blend)
	elif spawn_dist > d_outer and spawn_dist <= d_outer + 20.0:
		# Outer transition: blend from desert to normal region
		var blend: float = 1.0 - (spawn_dist - d_outer) / 20.0
		var desert_colors: Dictionary = chunk_manager.region_colors[ChunkManager.RegionType.DESERT]
		grass_color = grass_color.lerp(desert_colors["grass"], blend)
		dirt_color = dirt_color.lerp(desert_colors["dirt"], blend)

	var grass_thickness: float = 0.25
	var total_height: float = v0.y - v2.y

	# Color variation based on position
	var variation: float = sin(v0.x * 12.9898 + v0.z * 78.233 + v0.y * 37.719) * 0.06
	var cell_grass: Color = Color(
		clamp(grass_color.r + variation, grass_color.r - 0.08, grass_color.r + 0.10),
		clamp(grass_color.g + variation * 0.5, grass_color.g - 0.07, grass_color.g + 0.10),
		clamp(grass_color.b + variation * 0.3, grass_color.b - 0.07, grass_color.b + 0.07)
	)
	var cell_dirt: Color = Color(
		clamp(dirt_color.r + variation, dirt_color.r - 0.08, dirt_color.r + 0.10),
		clamp(dirt_color.g + variation * 0.8, dirt_color.g - 0.08, dirt_color.g + 0.10),
		clamp(dirt_color.b + variation * 0.5, dirt_color.b - 0.08, dirt_color.b + 0.10)
	)

	# Get UV coordinates for side faces
	var side_uvs: Array[Vector2] = TerrainTextures.get_side_face_uvs(total_height > grass_thickness)
	var dirt_uvs: Array[Vector2] = TerrainTextures.get_side_face_uvs(false)  # Pure dirt UVs

	if total_height > grass_thickness:
		# Split into grass strip + dirt
		var grass_bottom_y: float = v0.y - grass_thickness
		var g2 := Vector3(v1.x, grass_bottom_y, v1.z)
		var g3 := Vector3(v0.x, grass_bottom_y, v0.z)

		# Grass strip (top vertices use top AO, grass-bottom uses interpolated AO)
		var ao_grass_bottom: float = lerp(ao_top, ao_bottom, grass_thickness / total_height)
		var grass_top_col: Color = cell_grass * ao_top
		var grass_bot_col: Color = cell_grass * ao_grass_bottom

		# UV interpolation for grass strip (top 25% of texture roughly)
		var uv_grass_top_l: Vector2 = side_uvs[0]
		var uv_grass_top_r: Vector2 = side_uvs[1]
		var grass_v_ratio: float = 0.25  # Grass covers top 25% of texture
		var uv_grass_bot_l: Vector2 = Vector2(side_uvs[0].x, lerp(side_uvs[0].y, side_uvs[3].y, grass_v_ratio))
		var uv_grass_bot_r: Vector2 = Vector2(side_uvs[1].x, lerp(side_uvs[1].y, side_uvs[2].y, grass_v_ratio))

		st.set_color(grass_top_col)
		st.set_normal(normal)
		st.set_uv(uv_grass_top_l)
		st.add_vertex(v0)
		st.set_color(grass_top_col)
		st.set_normal(normal)
		st.set_uv(uv_grass_top_r)
		st.add_vertex(v1)
		st.set_color(grass_bot_col)
		st.set_normal(normal)
		st.set_uv(uv_grass_bot_r)
		st.add_vertex(g2)

		st.set_color(grass_top_col)
		st.set_normal(normal)
		st.set_uv(uv_grass_top_l)
		st.add_vertex(v0)
		st.set_color(grass_bot_col)
		st.set_normal(normal)
		st.set_uv(uv_grass_bot_r)
		st.add_vertex(g2)
		st.set_color(grass_bot_col)
		st.set_normal(normal)
		st.set_uv(uv_grass_bot_l)
		st.add_vertex(g3)

		# Dirt section (interpolate AO from grass bottom to actual bottom)
		var dirt_top_col: Color = cell_dirt * ao_grass_bottom
		var dirt_bot_col: Color = cell_dirt * ao_bottom

		st.set_color(dirt_top_col)
		st.set_normal(normal)
		st.set_uv(dirt_uvs[0])
		st.add_vertex(g3)
		st.set_color(dirt_top_col)
		st.set_normal(normal)
		st.set_uv(dirt_uvs[1])
		st.add_vertex(g2)
		st.set_color(dirt_bot_col)
		st.set_normal(normal)
		st.set_uv(dirt_uvs[2])
		st.add_vertex(v2)

		st.set_color(dirt_top_col)
		st.set_normal(normal)
		st.set_uv(dirt_uvs[0])
		st.add_vertex(g3)
		st.set_color(dirt_bot_col)
		st.set_normal(normal)
		st.set_uv(dirt_uvs[2])
		st.add_vertex(v2)
		st.set_color(dirt_bot_col)
		st.set_normal(normal)
		st.set_uv(dirt_uvs[3])
		st.add_vertex(v3)
	else:
		# All grass for short sides (use grass_side texture)
		var grass_top_col: Color = cell_grass * ao_top
		var grass_bot_col: Color = cell_grass * ao_bottom

		st.set_color(grass_top_col)
		st.set_normal(normal)
		st.set_uv(side_uvs[0])
		st.add_vertex(v0)
		st.set_color(grass_top_col)
		st.set_normal(normal)
		st.set_uv(side_uvs[1])
		st.add_vertex(v1)
		st.set_color(grass_bot_col)
		st.set_normal(normal)
		st.set_uv(side_uvs[2])
		st.add_vertex(v2)

		st.set_color(grass_top_col)
		st.set_normal(normal)
		st.set_uv(side_uvs[0])
		st.add_vertex(v0)
		st.set_color(grass_bot_col)
		st.set_normal(normal)
		st.set_uv(side_uvs[2])
		st.add_vertex(v2)
		st.set_color(grass_bot_col)
		st.set_normal(normal)
		st.set_uv(side_uvs[3])
		st.add_vertex(v3)


func _generate_collision_from_mesh(sync: bool = true) -> void:
	terrain_collision = StaticBody3D.new()
	terrain_collision.name = "TerrainCollision"
	add_child(terrain_collision)

	# Minecraft-style per-cell AABB collision matching visual terrain exactly
	if sync:
		_generate_box_collision()
	else:
		_generate_box_collision_batched()


func _generate_box_collision() -> void:
	## Generate per-cell BoxShape3D collision (Minecraft-style).
	## One box per cell with exact heights - no merging, no rounding.
	## This is the most reliable approach that exactly matches visual terrain.
	##
	## MUST run synchronously - async collision causes fall-through when player
	## reaches chunk before collision is ready.
	var cell_size: float = chunk_manager.cell_size
	var chunk_size_cells: int = chunk_manager.chunk_size_cells
	var chunk_world_x: float = chunk_coord.x * chunk_size_cells * cell_size
	var chunk_world_z: float = chunk_coord.y * chunk_size_cells * cell_size

	for cz in range(chunk_size_cells):
		for cx in range(chunk_size_cells):
			# Skip cells inside cave tunnels (cave has its own collision)
			var cell_cx: float = chunk_world_x + cx * cell_size + cell_size / 2.0
			var cell_cz: float = chunk_world_z + cz * cell_size + cell_size / 2.0
			if chunk_manager.is_inside_cave_tunnel(cell_cx, cell_cz):
				continue

			var height: float = _height_cache[cz + 1][cx + 1]

			# For water cells (negative height), create collision at water bottom
			# This allows swimming while preventing fall-through
			# Use absolute value to get depth, minimum 0.5 for thin collision
			var box_height: float
			var box_y_center: float

			if height < 0:
				# Water cell: thin collision slab at pond floor only.
				# No collision at water surface so the player falls through
				# and triggers swimming via Area3D detection.
				box_height = 0.5
				box_y_center = height + box_height / 2.0  # Sits at the pond floor
			else:
				# Normal terrain: box TOP at terrain height, extending downward
				# Minimum thickness of 0.5 ensures reliable collision
				box_height = max(height, 0.5)
				box_y_center = height - box_height / 2.0

			# Calculate world position (cell center)
			var world_x: float = chunk_world_x + cx * cell_size + cell_size / 2.0
			var world_z: float = chunk_world_z + cz * cell_size + cell_size / 2.0

			# Create box collision
			var box: BoxShape3D = BoxShape3D.new()
			box.size = Vector3(cell_size, box_height, cell_size)

			var collision_shape: CollisionShape3D = CollisionShape3D.new()
			collision_shape.shape = box
			collision_shape.position = Vector3(world_x, box_y_center, world_z)

			terrain_collision.add_child(collision_shape)


func _generate_box_collision_batched() -> void:
	## Batched version of _generate_box_collision() - spreads work across multiple frames.
	## Used for distant chunks where collision isn't needed immediately.
	var cell_size: float = chunk_manager.cell_size
	var chunk_size_cells: int = chunk_manager.chunk_size_cells
	var chunk_world_x: float = chunk_coord.x * chunk_size_cells * cell_size
	var chunk_world_z: float = chunk_coord.y * chunk_size_cells * cell_size

	var rows_this_batch: int = 0

	for cz in range(chunk_size_cells):
		# Safety: if chunk was unloaded while we're still generating, stop
		if _height_cache.is_empty() or not is_instance_valid(terrain_collision):
			return

		for cx in range(chunk_size_cells):
			# Skip cells inside cave tunnels (cave has its own collision)
			var cell_cx: float = chunk_world_x + cx * cell_size + cell_size / 2.0
			var cell_cz: float = chunk_world_z + cz * cell_size + cell_size / 2.0
			if chunk_manager.is_inside_cave_tunnel(cell_cx, cell_cz):
				continue

			var height: float = _height_cache[cz + 1][cx + 1]

			var box_height: float
			var box_y_center: float

			if height < 0:
				# Water cell: thin slab at pond floor only (matches sync version)
				box_height = 0.5
				box_y_center = height + box_height / 2.0
			else:
				# Normal terrain: box TOP at terrain height, extending downward
				box_height = max(height, 0.5)
				box_y_center = height - box_height / 2.0

			var world_x: float = chunk_world_x + cx * cell_size + cell_size / 2.0
			var world_z: float = chunk_world_z + cz * cell_size + cell_size / 2.0

			var box: BoxShape3D = BoxShape3D.new()
			box.size = Vector3(cell_size, box_height, cell_size)

			var collision_shape: CollisionShape3D = CollisionShape3D.new()
			collision_shape.shape = box
			collision_shape.position = Vector3(world_x, box_y_center, world_z)

			terrain_collision.add_child(collision_shape)

		rows_this_batch += 1
		if rows_this_batch >= COLLISION_ROWS_PER_BATCH:
			rows_this_batch = 0
			if not is_inside_tree():
				return
			await get_tree().process_frame
			if not is_inside_tree():
				return


func _spawn_chunk_trees() -> void:
	## Spawns trees with batching - yields every TREES_PER_BATCH to prevent frame stuttering
	var tree_scene: PackedScene = chunk_manager.tree_scene
	var big_tree_scene: PackedScene = chunk_manager.big_tree_scene
	var birch_tree_scene: PackedScene = chunk_manager.birch_tree_scene

	if not tree_scene:
		return

	trees_container = Node3D.new()
	trees_container.name = "Trees"
	add_child(trees_container)

	var cell_size: float = chunk_manager.cell_size
	var chunk_size_cells: int = chunk_manager.chunk_size_cells
	var chunk_world_size: float = chunk_size_cells * cell_size
	var tree_grid_size: float = chunk_manager.tree_grid_size
	var tree_density: float = chunk_manager.tree_density

	var chunk_world_x: float = chunk_coord.x * chunk_world_size
	var chunk_world_z: float = chunk_coord.y * chunk_world_size

	# Use deterministic random based on chunk coordinates
	var chunk_seed: int = chunk_coord.x * 73856093 ^ chunk_coord.y * 19349663
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = chunk_seed

	var trees_spawned_this_batch: int = 0
	var local_tree_index: int = 0

	var x: float = 0.0
	while x < chunk_world_size:
		var z: float = 0.0
		while z < chunk_world_size:
			var world_x: float = chunk_world_x + x
			var world_z: float = chunk_world_z + z

			# Check distance from campsite (origin)
			var distance_from_camp: float = Vector2(world_x, world_z).length()

			# Skip if too close to campsite
			if distance_from_camp < chunk_manager.tree_min_distance:
				z += tree_grid_size
				continue

			# Skip if in any pond area
			if chunk_manager.is_near_any_pond(world_x, world_z, 2.0):
				z += tree_grid_size
				continue

			# Skip if there's a player structure at this location
			if chunk_manager.is_position_blocked_by_structure(world_x, world_z, 1.5):
				z += tree_grid_size
				continue

			# Skip if inside or near a cave entrance
			if chunk_manager.is_near_cave_entrance(world_x, world_z):
				z += tree_grid_size
				continue

			# Get region type and tree multiplier
			var region: ChunkManager.RegionType = chunk_manager.get_region_at(world_x, world_z)
			var tree_multiplier: float = chunk_manager.get_vegetation_multiplier(region, "tree")

			# Desert region: spawn cactuses and palms instead of normal trees
			if region == ChunkManager.RegionType.DESERT:
				# Skip oasis areas - don't spawn vegetation on top of oases
				var skip_oasis: bool = false
				for oasis: Dictionary in chunk_manager.desert_oases:
					var oasis_center: Vector2 = oasis["center"]
					if Vector2(world_x, world_z).distance_to(oasis_center) < 10.0:
						skip_oasis = true
						break
				if skip_oasis:
					z += tree_grid_size
					continue

				var vegetation: Dictionary = chunk_manager.region_vegetation[ChunkManager.RegionType.DESERT]
				var cactus_chance: float = vegetation.get("cactus", 0.0)
				var palm_chance: float = vegetation.get("palm", 0.0)

				# Use density noise to modulate spawn chance (same as trees)
				var density_value_desert: float = (chunk_manager.forest_noise.get_noise_2d(world_x, world_z) + 1.0) * 0.5
				if density_value_desert > 0.35:
					var base_chance: float = tree_density * (density_value_desert - 0.35) / 0.65 * 2.5
					if rng.randf() < base_chance * 0.35 * cactus_chance:
						var jitter_x: float = rng.randf_range(-tree_grid_size * 0.4, tree_grid_size * 0.4)
						var jitter_z: float = rng.randf_range(-tree_grid_size * 0.4, tree_grid_size * 0.4)
						var cactus_x: float = world_x + jitter_x
						var cactus_z: float = world_z + jitter_z
						var cactus_y: float = _get_cached_height_at(cactus_x, cactus_z)
						if cactus_y >= 0:
							var cactus: Cactus = Cactus.new()
							cactus.build(rng, rng.randf() < 0.1)  # 10% fruit-bearing
							cactus.position = Vector3(cactus_x, cactus_y, cactus_z)
							cactus.name = "Cactus_C%d_%d_%d" % [chunk_coord.x, chunk_coord.y, local_tree_index]
							local_tree_index += 1
							trees_container.add_child(cactus)
							spawned_trees.append(cactus)
							trees_spawned_this_batch += 1
							if trees_spawned_this_batch >= TREES_PER_BATCH:
								trees_spawned_this_batch = 0
								if not is_inside_tree():
									return
								await get_tree().process_frame
								if not is_inside_tree():
									return
					elif rng.randf() < base_chance * 0.3 * palm_chance:
						var jitter_x: float = rng.randf_range(-tree_grid_size * 0.4, tree_grid_size * 0.4)
						var jitter_z: float = rng.randf_range(-tree_grid_size * 0.4, tree_grid_size * 0.4)
						var palm_x: float = world_x + jitter_x
						var palm_z: float = world_z + jitter_z
						var palm_y: float = _get_cached_height_at(palm_x, palm_z)
						if palm_y >= 0:
							var palm: PalmTree = PalmTree.new()
							palm.build(rng)
							palm.position = Vector3(palm_x, palm_y, palm_z)
							palm.rotation.y = rng.randf() * TAU
							palm.name = "Palm_C%d_%d_%d" % [chunk_coord.x, chunk_coord.y, local_tree_index]
							local_tree_index += 1
							trees_container.add_child(palm)
							spawned_trees.append(palm)
							trees_spawned_this_batch += 1
							if trees_spawned_this_batch >= TREES_PER_BATCH:
								trees_spawned_this_batch = 0
								if not is_inside_tree():
									return
								await get_tree().process_frame
								if not is_inside_tree():
									return
				z += tree_grid_size
				continue  # Skip normal tree logic

			# Get forest density from noise
			var density_value: float = (chunk_manager.forest_noise.get_noise_2d(world_x, world_z) + 1.0) * 0.5

			var spawn_chance: float = 0.0
			if density_value > 0.35:
				spawn_chance = tree_density * (density_value - 0.35) / 0.65 * 2.5 * tree_multiplier

			if rng.randf() < spawn_chance:
				# Add jitter
				var jitter_x: float = rng.randf_range(-tree_grid_size * 0.4, tree_grid_size * 0.4)
				var jitter_z: float = rng.randf_range(-tree_grid_size * 0.4, tree_grid_size * 0.4)
				var tree_x: float = world_x + jitter_x
				var tree_z: float = world_z + jitter_z

				var tree_y: float = _get_cached_height_at(tree_x, tree_z)

				# Skip trees in water (negative height = inside water body)
				if tree_y < 0:
					z += tree_grid_size
					continue

				# Choose tree type based on region and elevation
				var tree: Node3D
				var tree_type_roll: float = rng.randf()
				var ponderosa_scene: PackedScene = chunk_manager.ponderosa_pine_scene

				# Ponderosa pines dominate in MOUNTAIN region and at higher elevations
				var use_ponderosa: bool = false
				if ponderosa_scene:
					if region == ChunkManager.RegionType.MOUNTAIN:
						# In mountains: 85% ponderosa below treeline (45 units), no trees above
						if tree_y < 45.0:
							use_ponderosa = tree_type_roll < 0.85
						else:
							# Above treeline - no trees spawn (skip)
							z += tree_grid_size
							continue
					elif tree_y > 15.0:
						# At elevation in other biomes: use pine grove noise for clustering
						var pine_grove_value: float = chunk_manager.pine_grove_noise.get_noise_2d(tree_x, tree_z)
						if pine_grove_value > 0.2:
							# In a pine grove cluster - higher chance of ponderosa
							use_ponderosa = tree_type_roll < 0.7
						elif tree_y > 25.0:
							# High elevation even outside groves - some ponderosa
							use_ponderosa = tree_type_roll < 0.5

				if use_ponderosa:
					tree = ponderosa_scene.instantiate()
				elif tree_type_roll < 0.60:
					tree = tree_scene.instantiate()
				elif tree_type_roll < 0.90 and big_tree_scene:
					tree = big_tree_scene.instantiate()
				elif birch_tree_scene:
					tree = birch_tree_scene.instantiate()
				else:
					tree = tree_scene.instantiate()

				tree.position = Vector3(tree_x, tree_y, tree_z)
				tree.rotation.y = rng.randf() * TAU

				var scale_factor: float = rng.randf_range(0.7, 1.2)
				tree.scale = Vector3(scale_factor, scale_factor, scale_factor)

				# Deterministic name for save/load identification
				tree.name = "Tree_C%d_%d_%d" % [chunk_coord.x, chunk_coord.y, local_tree_index]
				local_tree_index += 1

				trees_container.add_child(tree)
				spawned_trees.append(tree)

				# Register with ResourceManager for depletion tracking
				if chunk_manager.resource_manager:
					chunk_manager.resource_manager.register_chunk_resource(tree)

				# Apply bark strip visual to birch trees that have been harvested
				if tree.scene_file_path.ends_with("birch_tree_resource.tscn"):
					_try_apply_bark_strip(tree)

				# Register tree for wind sway animation
				if chunk_manager.tree_sway:
					chunk_manager.tree_sway.register_tree(tree, rng.randf() * TAU)

				# Batch yielding - pause every N trees to prevent frame stuttering
				trees_spawned_this_batch += 1
				if trees_spawned_this_batch >= TREES_PER_BATCH:
					trees_spawned_this_batch = 0
					if not is_inside_tree():
						return
					await get_tree().process_frame
					if not is_inside_tree():
						return

			z += tree_grid_size
		x += tree_grid_size


func _try_apply_bark_strip(tree: Node) -> void:
	## Check if a birch tree has been bark-stripped and apply the visual band.
	var player_node: Node = get_tree().get_first_node_in_group("player") if is_inside_tree() else null
	if not player_node:
		return
	var equipment: Node = player_node.get_node_or_null("Equipment")
	if not equipment or not "bark_harvest_tracker" in equipment:
		return
	var tracker: Dictionary = equipment.bark_harvest_tracker
	var pos: Vector3 = tree.position
	var pos_key: String = "%d_%d" % [int(pos.x * 10), int(pos.z * 10)]
	if tracker.has(pos_key):
		Equipment.add_bark_strip(tree)


func _spawn_chunk_resources() -> void:
	## Spawns resources with batching - yields every RESOURCES_PER_BATCH to prevent frame stuttering
	resources_container = Node3D.new()
	resources_container.name = "Resources"
	add_child(resources_container)

	var cell_size: float = chunk_manager.cell_size
	var chunk_size_cells: int = chunk_manager.chunk_size_cells
	var chunk_world_size: float = chunk_size_cells * cell_size

	var chunk_world_x: float = chunk_coord.x * chunk_world_size
	var chunk_world_z: float = chunk_coord.y * chunk_world_size

	# Use deterministic random based on chunk coordinates (different seed than trees)
	var chunk_seed: int = chunk_coord.x * 31337 ^ chunk_coord.y * 65537
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = chunk_seed

	# Resource noise for clustering
	var resource_noise: FastNoiseLite = FastNoiseLite.new()
	resource_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	resource_noise.seed = chunk_manager.noise_seed + 2000
	resource_noise.frequency = 0.1

	var resource_grid_size: float = 5.0  # Larger grid for resources - fewer checks, better performance
	var resources_spawned_this_batch: int = 0
	_local_resource_index = 0

	var x: float = 0.0
	while x < chunk_world_size:
		var z: float = 0.0
		while z < chunk_world_size:
			var world_x: float = chunk_world_x + x
			var world_z: float = chunk_world_z + z

			# Get noise value for clustering
			var noise_value: float = (resource_noise.get_noise_2d(world_x, world_z) + 1.0) * 0.5

			# Add jitter to position FIRST
			var jitter_x: float = rng.randf_range(-resource_grid_size * 0.4, resource_grid_size * 0.4)
			var jitter_z: float = rng.randf_range(-resource_grid_size * 0.4, resource_grid_size * 0.4)
			var res_x: float = world_x + jitter_x
			var res_z: float = world_z + jitter_z

			# Skip if inside any pond area (check AFTER jitter is applied)
			if chunk_manager.is_near_any_pond(res_x, res_z, 2.0):
				z += resource_grid_size
				continue

			# Skip if there's a player structure at this location
			if chunk_manager.is_position_blocked_by_structure(res_x, res_z, 0.5):
				z += resource_grid_size
				continue

			# Skip if inside or near a cave entrance
			if chunk_manager.is_near_cave_entrance(res_x, res_z):
				z += resource_grid_size
				continue

			var res_y: float = _get_cached_height_at(res_x, res_z)

			# Skip if in water (negative height = pond)
			if res_y < 0:
				z += resource_grid_size
				continue

			# Distance from campsite affects spawn rates
			var dist_from_camp: float = Vector2(res_x, res_z).length()

			# Get region type and multipliers for this position
			var region: ChunkManager.RegionType = chunk_manager.get_region_at(res_x, res_z)
			var rock_mult: float = chunk_manager.get_vegetation_multiplier(region, "rock")
			var berry_mult: float = chunk_manager.get_vegetation_multiplier(region, "berry")
			var herb_mult: float = chunk_manager.get_vegetation_multiplier(region, "herb")

			# Track if we spawned something this iteration
			var spawned: bool = false

			# Try spawning different resource types
			var resource_roll: float = rng.randf()

			# Branches - more common near trees (use forest noise)
			var forest_value: float = (chunk_manager.forest_noise.get_noise_2d(res_x, res_z) + 1.0) * 0.5
			var branch_chance: float = chunk_manager.branch_density * (0.5 + forest_value)
			if resource_roll < branch_chance and chunk_manager.branch_scene:
				_spawn_resource(chunk_manager.branch_scene, res_x, res_y, res_z, rng)
				spawned = true
			else:
				# Rocks - spawn near water pools (shoreline rocks) + region-based
				resource_roll = rng.randf()
				var dist_to_pond: float = chunk_manager.get_distance_to_nearest_pond(res_x, res_z)
				var pond_radius: float = chunk_manager.pond_radius
				var rock_chance: float = 0.0

				# Rocks spawn in a band around ponds (from pond edge to ~15 units out)
				var dist_from_pond_edge: float = dist_to_pond - pond_radius
				if dist_from_pond_edge > 0.0 and dist_from_pond_edge < 15.0:
					var proximity_factor: float = 1.0 - (dist_from_pond_edge / 15.0)
					rock_chance = chunk_manager.rock_density * 8.0 * proximity_factor * rock_mult
				else:
					rock_chance = chunk_manager.rock_density * rock_mult

				if resource_roll < rock_chance and chunk_manager.rock_scene:
					_spawn_resource(chunk_manager.rock_scene, res_x, res_y, res_z, rng)
					spawned = true
				else:
					# Berry bushes - clustered in clearings (inverse of forest), region-adjusted
					resource_roll = rng.randf()
					var berry_chance: float = chunk_manager.berry_density * (1.5 - forest_value) * berry_mult
					if resource_roll < berry_chance and chunk_manager.berry_bush_scene:
						_spawn_resource(chunk_manager.berry_bush_scene, res_x, res_y, res_z, rng)
						spawned = true
					else:
						# Mushrooms - more common in forests
						resource_roll = rng.randf()
						var mushroom_chance: float = chunk_manager.mushroom_density * (0.5 + forest_value)
						if resource_roll < mushroom_chance and chunk_manager.mushroom_scene:
							_spawn_resource(chunk_manager.mushroom_scene, res_x, res_y, res_z, rng)
							spawned = true
						else:
							# Herbs - scattered everywhere, region-adjusted
							resource_roll = rng.randf()
							if resource_roll < chunk_manager.herb_density * herb_mult and chunk_manager.herb_scene:
								_spawn_resource(chunk_manager.herb_scene, res_x, res_y, res_z, rng)
								spawned = true
							else:
								# Ore deposits - spawn in ROCKY (4.5%) and HILLS (1.5%) regions
								resource_roll = rng.randf()
								var ore_chance: float = 0.0
								if region == ChunkManager.RegionType.ROCKY:
									ore_chance = 0.045
								elif region == ChunkManager.RegionType.HILLS:
									ore_chance = 0.015
								elif region == ChunkManager.RegionType.MOUNTAIN:
									ore_chance = 0.03
								if resource_roll < ore_chance and chunk_manager.ore_scene:
									_spawn_resource(chunk_manager.ore_scene, res_x, res_y, res_z, rng)
									spawned = true
								else:
									# Osha root - alpine medicinal plant (higher elevation herb)
									resource_roll = rng.randf()
									var osha_mult: float = chunk_manager.get_vegetation_multiplier(region, "osha")
									var osha_base_chance: float = 0.02
									var osha_chance: float = 0.0

									if region == ChunkManager.RegionType.MOUNTAIN:
										if res_y > 8.0:
											osha_chance = osha_base_chance * osha_mult
									elif region == ChunkManager.RegionType.ROCKY:
										if res_y > 6.0:
											osha_chance = osha_base_chance * osha_mult
									elif region == ChunkManager.RegionType.HILLS:
										if res_y > 5.0:
											osha_chance = osha_base_chance * osha_mult

									if resource_roll < osha_chance and chunk_manager.osha_root_scene:
										_spawn_resource(chunk_manager.osha_root_scene, res_x, res_y, res_z, rng)
										spawned = true

			# Batch yielding - pause every N resources to prevent frame stuttering
			if spawned:
				resources_spawned_this_batch += 1
				if resources_spawned_this_batch >= RESOURCES_PER_BATCH:
					resources_spawned_this_batch = 0
					if not is_inside_tree():
						return
					await get_tree().process_frame
					if not is_inside_tree():
						return

			z += resource_grid_size
		x += resource_grid_size


func _spawn_resource(scene: PackedScene, x: float, y: float, z: float, rng: RandomNumberGenerator) -> void:
	var resource: Node3D = scene.instantiate()

	# Deterministic name for save/load identification
	resource.name = "Res_C%d_%d_%d" % [chunk_coord.x, chunk_coord.y, _local_resource_index]
	_local_resource_index += 1

	# Place resource at the terrain height of its own cell position.
	# The y parameter is already get_height_at(x, z) which snaps to cell centers internally,
	# so it gives the correct height for the cell the resource is actually on.
	# A small offset prevents z-fighting with the terrain surface.
	var height_offset: float = 0.05

	resource.position = Vector3(x, y + height_offset, z)
	resource.rotation.y = rng.randf() * TAU
	resources_container.add_child(resource)
	spawned_resources.append(resource)

	# Register with ResourceManager for depletion tracking
	if resource is ResourceNode and chunk_manager.resource_manager:
		chunk_manager.resource_manager.register_chunk_resource(resource)


func _spawn_chunk_decorations() -> void:
	## Spawns decorations with batching - yields every DECORATIONS_PER_BATCH to prevent frame stuttering
	decorations_container = Node3D.new()
	decorations_container.name = "Decorations"
	add_child(decorations_container)

	var cell_size: float = chunk_manager.cell_size
	var chunk_size_cells: int = chunk_manager.chunk_size_cells
	var chunk_world_size: float = chunk_size_cells * cell_size

	var chunk_world_x: float = chunk_coord.x * chunk_world_size
	var chunk_world_z: float = chunk_coord.y * chunk_world_size

	# Deterministic random for this chunk
	var chunk_seed: int = chunk_coord.x * 48611 ^ chunk_coord.y * 27644437
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = chunk_seed

	# Decoration noise for clustering
	var decoration_noise: FastNoiseLite = FastNoiseLite.new()
	decoration_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	decoration_noise.seed = chunk_manager.noise_seed + 1000
	decoration_noise.frequency = 0.15

	# Calculate how many decorations for this chunk (scaled by chunk area)
	# Reduced counts significantly for performance
	var chunk_area: float = chunk_world_size * chunk_world_size
	var world_area: float = 110.0 * 110.0  # Original decoration area (55 radius * 2)
	var area_ratio: float = chunk_area / world_area

	var target_grass: int = int(40 * area_ratio)  # Reduced from 60
	var target_red_flowers: int = int(6 * area_ratio)  # Reduced from 10
	var target_yellow_flowers: int = int(6 * area_ratio)  # Reduced from 10

	var decorations_spawned_this_batch: int = 0
	var grass_count: int = 0
	var attempts: int = 0
	var max_attempts: int = target_grass * 8  # Reduced max attempts

	# Spawn grass
	while grass_count < target_grass and attempts < max_attempts:
		var x: float = rng.randf_range(0, chunk_world_size)
		var z: float = rng.randf_range(0, chunk_world_size)
		var world_x: float = chunk_world_x + x
		var world_z: float = chunk_world_z + z

		# Skip if in any pond area
		if chunk_manager.is_near_any_pond(world_x, world_z, 1.0):
			attempts += 1
			continue

		# Skip if over cave entrance/tunnel
		if chunk_manager.is_near_cave_entrance(world_x, world_z):
			attempts += 1
			continue

		# Skip if too close to campsite center
		var dist_from_camp: float = Vector2(world_x, world_z).length()
		if dist_from_camp < 8.0:
			attempts += 1
			continue

		var noise_value: float = (decoration_noise.get_noise_2d(world_x, world_z) + 1.0) * 0.5
		if noise_value > 0.3:
			var y: float = _get_cached_height_at(world_x, world_z)
			_create_grass_tuft(Vector3(world_x, y + 0.01, world_z), rng)
			grass_count += 1

			# Batch yielding
			decorations_spawned_this_batch += 1
			if decorations_spawned_this_batch >= DECORATIONS_PER_BATCH:
				decorations_spawned_this_batch = 0
				if not is_inside_tree():
					return
				await get_tree().process_frame
				if not is_inside_tree():
					return

		attempts += 1

	# Spawn flowers
	var flower_count: int = 0
	attempts = 0
	max_attempts = (target_red_flowers + target_yellow_flowers) * 8  # Reduced max attempts

	while flower_count < target_red_flowers + target_yellow_flowers and attempts < max_attempts:
		var x: float = rng.randf_range(0, chunk_world_size)
		var z: float = rng.randf_range(0, chunk_world_size)
		var world_x: float = chunk_world_x + x
		var world_z: float = chunk_world_z + z

		# Skip if in any pond area
		if chunk_manager.is_near_any_pond(world_x, world_z, 1.0):
			attempts += 1
			continue

		# Skip if over cave entrance/tunnel
		if chunk_manager.is_near_cave_entrance(world_x, world_z):
			attempts += 1
			continue

		var dist_from_camp: float = Vector2(world_x, world_z).length()
		if dist_from_camp < 8.0:
			attempts += 1
			continue

		var noise_value: float = (decoration_noise.get_noise_2d(world_x * 1.5, world_z * 1.5) + 1.0) * 0.5
		if noise_value > 0.5:
			var y: float = _get_cached_height_at(world_x, world_z)
			var color: Color
			if flower_count < target_red_flowers:
				color = Color(0.85, 0.15, 0.15)  # Red
			else:
				color = Color(0.95, 0.85, 0.15)  # Yellow
			_create_flower(Vector3(world_x, y + 0.01, world_z), color, rng)
			flower_count += 1

			# Batch yielding
			decorations_spawned_this_batch += 1
			if decorations_spawned_this_batch >= DECORATIONS_PER_BATCH:
				decorations_spawned_this_batch = 0
				if not is_inside_tree():
					return
				await get_tree().process_frame
				if not is_inside_tree():
					return

		attempts += 1

	# Spawn scatter rocks (all regions, denser on rocky/mountain)
	var target_rocks: int = int(6 * area_ratio)
	var region_sample_x: float = chunk_world_x + chunk_world_size * 0.5
	var region_sample_z: float = chunk_world_z + chunk_world_size * 0.5
	var chunk_region: ChunkManager.RegionType = chunk_manager.get_region_at(region_sample_x, region_sample_z)
	# Density multiplier: ROCKY=3x, MOUNTAIN=4x, HILLS=2x, others=1x
	var rock_multiplier: float = 1.0
	if chunk_region == ChunkManager.RegionType.ROCKY:
		rock_multiplier = 3.0
	elif chunk_region == ChunkManager.RegionType.MOUNTAIN:
		rock_multiplier = 4.0
	elif chunk_region == ChunkManager.RegionType.HILLS:
		rock_multiplier = 2.0
	target_rocks = int(float(target_rocks) * rock_multiplier)

	var rock_count: int = 0
	attempts = 0
	max_attempts = target_rocks * 6

	while rock_count < target_rocks and attempts < max_attempts:
		var x: float = rng.randf_range(0, chunk_world_size)
		var z: float = rng.randf_range(0, chunk_world_size)
		var world_x: float = chunk_world_x + x
		var world_z: float = chunk_world_z + z

		if chunk_manager.is_near_any_pond(world_x, world_z, 1.5):
			attempts += 1
			continue
		if chunk_manager.is_near_cave_entrance(world_x, world_z):
			attempts += 1
			continue
		var dist_from_camp2: float = Vector2(world_x, world_z).length()
		if dist_from_camp2 < 10.0:
			attempts += 1
			continue

		var noise_val: float = (decoration_noise.get_noise_2d(world_x * 0.8, world_z * 0.8) + 1.0) * 0.5
		if noise_val > 0.35:
			var y: float = _get_cached_height_at(world_x, world_z)
			# Skip steep slopes to prevent clipping into terrain edges
			if _is_steep_slope(world_x, world_z, y, 1.5):
				attempts += 1
				continue
			_create_scatter_rock(Vector3(world_x, y, world_z), rng)
			rock_count += 1

			decorations_spawned_this_batch += 1
			if decorations_spawned_this_batch >= DECORATIONS_PER_BATCH:
				decorations_spawned_this_batch = 0
				if not is_inside_tree():
					return
				await get_tree().process_frame
				if not is_inside_tree():
					return

		attempts += 1

	# Spawn bushes (forest regions only)
	var is_forest: bool = chunk_region == ChunkManager.RegionType.FOREST
	if is_forest:
		var target_bushes: int = int(5 * area_ratio)
		var bush_count: int = 0
		attempts = 0
		max_attempts = target_bushes * 6

		while bush_count < target_bushes and attempts < max_attempts:
			var x: float = rng.randf_range(0, chunk_world_size)
			var z: float = rng.randf_range(0, chunk_world_size)
			var world_x: float = chunk_world_x + x
			var world_z: float = chunk_world_z + z

			if chunk_manager.is_near_any_pond(world_x, world_z, 1.5):
				attempts += 1
				continue
			if chunk_manager.is_near_cave_entrance(world_x, world_z):
				attempts += 1
				continue
			var dist_from_camp3: float = Vector2(world_x, world_z).length()
			if dist_from_camp3 < 10.0:
				attempts += 1
				continue

			var noise_val: float = (decoration_noise.get_noise_2d(world_x * 1.2, world_z * 1.2) + 1.0) * 0.5
			if noise_val > 0.45:
				var y: float = _get_cached_height_at(world_x, world_z)
				_create_scatter_bush(Vector3(world_x, y, world_z), rng)
				bush_count += 1

				decorations_spawned_this_batch += 1
				if decorations_spawned_this_batch >= DECORATIONS_PER_BATCH:
					decorations_spawned_this_batch = 0
					if not is_inside_tree():
						return
					await get_tree().process_frame
					if not is_inside_tree():
						return

			attempts += 1

	# Spawn logs and stumps (forest regions, sparse)
	if is_forest:
		var target_logs: int = int(3 * area_ratio)
		var log_count: int = 0
		attempts = 0
		max_attempts = target_logs * 8

		while log_count < target_logs and attempts < max_attempts:
			var x: float = rng.randf_range(0, chunk_world_size)
			var z: float = rng.randf_range(0, chunk_world_size)
			var world_x: float = chunk_world_x + x
			var world_z: float = chunk_world_z + z

			if chunk_manager.is_near_any_pond(world_x, world_z, 2.0):
				attempts += 1
				continue
			if chunk_manager.is_near_cave_entrance(world_x, world_z):
				attempts += 1
				continue
			var dist_from_camp4: float = Vector2(world_x, world_z).length()
			if dist_from_camp4 < 12.0:
				attempts += 1
				continue

			var noise_val: float = (decoration_noise.get_noise_2d(world_x * 0.5, world_z * 0.5) + 1.0) * 0.5
			if noise_val > 0.55:
				var y: float = _get_cached_height_at(world_x, world_z)
				if _is_steep_slope(world_x, world_z, y, 2.0):
					attempts += 1
					continue
				_create_scatter_log(Vector3(world_x, y, world_z), rng)
				log_count += 1

				decorations_spawned_this_batch += 1
				if decorations_spawned_this_batch >= DECORATIONS_PER_BATCH:
					decorations_spawned_this_batch = 0
					if not is_inside_tree():
						return
					await get_tree().process_frame
					if not is_inside_tree():
						return

			attempts += 1


func _create_grass_tuft(pos: Vector3, rng: RandomNumberGenerator) -> void:
	var grass: MeshInstance3D = MeshInstance3D.new()

	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var height: float = rng.randf_range(0.25, 0.4)
	var width: float = 0.15
	var grass_green: Color = Color(0.3, 0.65, 0.25)

	# Two crossed quads
	_add_grass_quad(st, Vector3(-width, 0, 0), Vector3(width, 0, 0),
					Vector3(width, height, 0), Vector3(-width, height, 0), grass_green)
	_add_grass_quad(st, Vector3(0, 0, -width), Vector3(0, 0, width),
					Vector3(0, height, width), Vector3(0, height, -width), grass_green)

	var mesh: ArrayMesh = st.commit()
	grass.mesh = mesh
	grass.material_override = _get_grass_material()

	grass.position = pos
	grass.rotation.y = rng.randf() * TAU
	decorations_container.add_child(grass)


func _add_grass_quad(st: SurfaceTool, v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3, color: Color) -> void:
	st.set_color(color)
	st.set_normal(Vector3.UP)
	st.add_vertex(v0)
	st.add_vertex(v1)
	st.add_vertex(v2)
	st.add_vertex(v0)
	st.add_vertex(v2)
	st.add_vertex(v3)


func _is_steep_slope(world_x: float, world_z: float, center_y: float, check_radius: float) -> bool:
	## Returns true if terrain around (world_x, world_z) has height differences exceeding one cell step.
	var y_px: float = _get_cached_height_at(world_x + check_radius, world_z)
	var y_nx: float = _get_cached_height_at(world_x - check_radius, world_z)
	var y_pz: float = _get_cached_height_at(world_x, world_z + check_radius)
	var y_nz: float = _get_cached_height_at(world_x, world_z - check_radius)
	var max_diff: float = maxf(maxf(absf(y_px - center_y), absf(y_nx - center_y)),
							   maxf(absf(y_pz - center_y), absf(y_nz - center_y)))
	return max_diff > 0.5


func _create_flower(pos: Vector3, petal_color: Color, rng: RandomNumberGenerator) -> void:
	var flower: Node3D = Node3D.new()

	# Stem
	var stem: MeshInstance3D = MeshInstance3D.new()
	var stem_mesh: BoxMesh = BoxMesh.new()
	stem_mesh.size = Vector3(0.05, 0.3, 0.05)
	stem.mesh = stem_mesh
	stem.material_override = _get_flower_stem_material()
	stem.position.y = 0.15
	flower.add_child(stem)

	# Flower head
	var head: MeshInstance3D = MeshInstance3D.new()
	var head_mesh: BoxMesh = BoxMesh.new()
	head_mesh.size = Vector3(0.15, 0.12, 0.15)
	head.mesh = head_mesh
	head.material_override = _get_flower_material(petal_color)
	head.position.y = 0.35
	flower.add_child(head)

	flower.position = pos
	flower.rotation.y = rng.randf() * TAU
	decorations_container.add_child(flower)


func _create_scatter_rock(pos: Vector3, rng: RandomNumberGenerator) -> void:
	## Creates a flat, wide boulder (2-4 overlapping slabs) — visually distinct from collectible rocks
	var boulder: Node3D = Node3D.new()
	var num_slabs: int = rng.randi_range(2, 4)
	var mat_variant: int = rng.randi_range(0, 2)
	var base_width: float = rng.randf_range(0.6, 1.2)

	# Main slab — wide and flat
	for i: int in range(num_slabs):
		var slab: MeshInstance3D = MeshInstance3D.new()
		var mesh: BoxMesh = BoxMesh.new()
		var width: float = base_width * rng.randf_range(0.5, 1.0)
		var height: float = base_width * rng.randf_range(0.1, 0.25)  # Very flat
		var depth: float = base_width * rng.randf_range(0.5, 0.9)
		mesh.size = Vector3(width, height, depth)
		slab.mesh = mesh
		slab.material_override = _get_rock_material(mat_variant if i == 0 else rng.randi_range(0, 2))
		# Stack slabs slightly with offsets for irregularity
		slab.position = Vector3(
			rng.randf_range(-0.15, 0.15),
			float(i) * base_width * 0.12 + height * 0.5,
			rng.randf_range(-0.15, 0.15)
		)
		slab.rotation.y = rng.randf_range(-0.3, 0.3)
		slab.rotation.x = rng.randf_range(-0.08, 0.08)
		boulder.add_child(slab)

	boulder.position = pos
	boulder.rotation.y = rng.randf() * TAU
	decorations_container.add_child(boulder)


func _create_scatter_bush(pos: Vector3, rng: RandomNumberGenerator) -> void:
	var bush: Node3D = Node3D.new()
	var base_size: float = rng.randf_range(0.6, 1.0)

	# Core body — large rounded mass
	var core: MeshInstance3D = MeshInstance3D.new()
	var core_mesh: BoxMesh = BoxMesh.new()
	core_mesh.size = Vector3(base_size, base_size * 0.7, base_size)
	core.mesh = core_mesh
	core.material_override = _get_bush_material(true)
	core.position.y = base_size * 0.35
	bush.add_child(core)

	# 3-5 overlapping leaf clusters at different angles for volume
	var num_clusters: int = rng.randi_range(3, 5)
	for i: int in range(num_clusters):
		var cluster: MeshInstance3D = MeshInstance3D.new()
		var cluster_mesh: BoxMesh = BoxMesh.new()
		var cw: float = base_size * rng.randf_range(0.4, 0.8)
		var ch: float = base_size * rng.randf_range(0.3, 0.6)
		var cd: float = base_size * rng.randf_range(0.4, 0.8)
		cluster_mesh.size = Vector3(cw, ch, cd)
		cluster.mesh = cluster_mesh
		cluster.material_override = _get_bush_material(rng.randf() > 0.4)
		var c_angle: float = rng.randf() * TAU
		var c_radius: float = base_size * rng.randf_range(0.15, 0.35)
		cluster.position = Vector3(
			cos(c_angle) * c_radius,
			base_size * rng.randf_range(0.2, 0.55),
			sin(c_angle) * c_radius
		)
		cluster.rotation.y = rng.randf() * TAU
		bush.add_child(cluster)

	# Top tuft — lighter green, slightly above core
	var top_tuft: MeshInstance3D = MeshInstance3D.new()
	var top_mesh: BoxMesh = BoxMesh.new()
	top_mesh.size = Vector3(base_size * 0.6, base_size * 0.35, base_size * 0.6)
	top_tuft.mesh = top_mesh
	top_tuft.material_override = _get_bush_material(false)
	top_tuft.position = Vector3(rng.randf_range(-0.1, 0.1), base_size * 0.6, rng.randf_range(-0.1, 0.1))
	top_tuft.rotation.y = rng.randf_range(-0.3, 0.3)
	bush.add_child(top_tuft)

	bush.position = pos
	bush.rotation.y = rng.randf() * TAU
	decorations_container.add_child(bush)


func _create_scatter_log(pos: Vector3, rng: RandomNumberGenerator) -> void:
	## Creates either a fallen log (horizontal) or a stump (short vertical stack)
	var obj: Node3D = Node3D.new()
	var is_stump: bool = rng.randf() > 0.5

	if is_stump:
		var stump_radius: float = rng.randf_range(0.4, 0.6)
		var stump_height: float = rng.randf_range(0.5, 0.8)
		var diameter: float = stump_radius * 2.0

		# Single solid bark body
		var bark: MeshInstance3D = MeshInstance3D.new()
		var bark_mesh: BoxMesh = BoxMesh.new()
		bark_mesh.size = Vector3(diameter, stump_height, diameter)
		bark.mesh = bark_mesh
		bark.material_override = _get_stump_material()
		bark.position.y = stump_height * 0.5
		obj.add_child(bark)

		# Light wood top face — inset slightly inside the bark edges
		var inset: float = 0.06
		var top: MeshInstance3D = MeshInstance3D.new()
		var top_mesh: BoxMesh = BoxMesh.new()
		var top_w: float = diameter - inset * 2.0
		top_mesh.size = Vector3(top_w, stump_height + 0.01, top_w)
		top.mesh = top_mesh
		top.material_override = _get_stump_top_material()
		top.position.y = stump_height * 0.5
		obj.add_child(top)

		# Ring detail — inset further, same height so it shows on top face only
		var ring: MeshInstance3D = MeshInstance3D.new()
		var ring_mesh: BoxMesh = BoxMesh.new()
		var ring_w: float = (diameter - inset * 2.0) * rng.randf_range(0.55, 0.7)
		var ring_d: float = (diameter - inset * 2.0) * rng.randf_range(0.55, 0.7)
		ring_mesh.size = Vector3(ring_w, stump_height + 0.02, ring_d)
		ring.mesh = ring_mesh
		ring.material_override = _get_stump_ring_material()
		ring.position = Vector3(rng.randf_range(-0.03, 0.03), stump_height * 0.5, rng.randf_range(-0.03, 0.03))
		ring.rotation.y = rng.randf_range(-0.3, 0.3)
		obj.add_child(ring)

		# Inner heartwood — smallest, shows on top
		var heart: MeshInstance3D = MeshInstance3D.new()
		var heart_mesh: BoxMesh = BoxMesh.new()
		var heart_w: float = (diameter - inset * 2.0) * rng.randf_range(0.2, 0.35)
		heart_mesh.size = Vector3(heart_w, stump_height + 0.03, heart_w)
		heart.mesh = heart_mesh
		heart.material_override = _get_stump_top_material()
		heart.position = Vector3(rng.randf_range(-0.03, 0.03), stump_height * 0.5, rng.randf_range(-0.03, 0.03))
		heart.rotation.y = rng.randf_range(-0.4, 0.4)
		obj.add_child(heart)

		# Small grass tufts around base
		var num_grass: int = rng.randi_range(4, 7)
		for g: int in range(num_grass):
			var tuft: MeshInstance3D = MeshInstance3D.new()
			var tuft_mesh: BoxMesh = BoxMesh.new()
			var gh: float = rng.randf_range(0.15, 0.3)
			var gw: float = rng.randf_range(0.08, 0.15)
			tuft_mesh.size = Vector3(gw, gh, gw)
			tuft.mesh = tuft_mesh
			tuft.material_override = _get_flower_stem_material()
			var g_angle: float = rng.randf() * TAU
			var g_radius: float = stump_radius + rng.randf_range(0.05, 0.15)
			tuft.position = Vector3(
				cos(g_angle) * g_radius,
				gh * 0.5,
				sin(g_angle) * g_radius
			)
			tuft.rotation.y = rng.randf() * TAU
			obj.add_child(tuft)
	else:
		# Horizontal fallen log - thick trunk with taper
		var log_length: float = rng.randf_range(3.0, 5.0)
		var log_thickness: float = rng.randf_range(0.5, 0.75)
		var segments: int = rng.randi_range(3, 4)
		for i: int in range(segments):
			var box: MeshInstance3D = MeshInstance3D.new()
			var mesh: BoxMesh = BoxMesh.new()
			var seg_len: float = log_length / float(segments) * rng.randf_range(0.9, 1.1)
			# Taper from thick base to thinner end
			var taper: float = 1.0 - float(i) / float(segments) * 0.35
			var thick: float = log_thickness * taper * rng.randf_range(0.9, 1.1)
			mesh.size = Vector3(seg_len, thick, thick)
			box.mesh = mesh
			box.material_override = _get_log_material()
			box.position = Vector3(
				(float(i) - float(segments) * 0.5) * (log_length / float(segments)),
				thick * 0.5,
				rng.randf_range(-0.08, 0.08)
			)
			box.rotation.y = rng.randf_range(-0.05, 0.05)
			obj.add_child(box)

	obj.position = pos
	obj.rotation.y = rng.randf() * TAU
	decorations_container.add_child(obj)


func _spawn_chunk_animals() -> void:
	## Spawn ambient wildlife based on region type
	var cell_size: float = chunk_manager.cell_size
	var chunk_size_cells: int = chunk_manager.chunk_size_cells
	var chunk_world_size: float = chunk_size_cells * cell_size

	var chunk_world_x: float = chunk_coord.x * chunk_world_size
	var chunk_world_z: float = chunk_coord.y * chunk_world_size

	# Use deterministic random for consistent animal placement
	var chunk_seed: int = chunk_coord.x * 91939 ^ chunk_coord.y * 37573
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = chunk_seed

	# 65% of chunks have animals
	if rng.randf() > 0.65:
		return

	# Get the dominant region for this chunk (sample center)
	var center_x: float = chunk_world_x + chunk_world_size / 2.0
	var center_z: float = chunk_world_z + chunk_world_size / 2.0
	var region: ChunkManager.RegionType = chunk_manager.get_region_at(center_x, center_z)

	# Determine spawn counts based on region
	var rabbit_count: int = 0
	var bird_count: int = 0

	match region:
		ChunkManager.RegionType.MEADOW:
			rabbit_count = rng.randi_range(1, 2)
			bird_count = rng.randi_range(2, 3)
		ChunkManager.RegionType.FOREST:
			rabbit_count = rng.randi_range(1, 2)
			bird_count = rng.randi_range(1, 3)
		ChunkManager.RegionType.HILLS:
			rabbit_count = rng.randi_range(0, 1)
			bird_count = rng.randi_range(2, 3)
		ChunkManager.RegionType.ROCKY:
			rabbit_count = 0
			bird_count = rng.randi_range(1, 2)
		ChunkManager.RegionType.MOUNTAIN:
			rabbit_count = 0
			bird_count = rng.randi_range(2, 3)
		ChunkManager.RegionType.DESERT:
			rabbit_count = 0
			bird_count = 0

	# Cap total animals per chunk for performance
	var max_animals: int = 5
	var total_requested: int = rabbit_count + bird_count
	if total_requested > max_animals:
		# Scale down proportionally
		var scale: float = float(max_animals) / float(total_requested)
		rabbit_count = int(rabbit_count * scale)
		bird_count = max_animals - rabbit_count

	# Spawn rabbits
	for _i in range(rabbit_count):
		var spawn_pos: Vector3 = _find_animal_spawn_position(rng, chunk_world_x, chunk_world_z, chunk_world_size)
		if spawn_pos != Vector3.ZERO:
			_spawn_rabbit(spawn_pos)

	# Spawn birds
	for _i in range(bird_count):
		var spawn_pos: Vector3 = _find_animal_spawn_position(rng, chunk_world_x, chunk_world_z, chunk_world_size)
		if spawn_pos != Vector3.ZERO:
			_spawn_bird(spawn_pos)

	# Spawn desert creatures (lizards and tortoises)
	if region == ChunkManager.RegionType.DESERT:
		var lizard_count: int = rng.randi_range(1, 3)
		var tortoise_count: int = rng.randi_range(0, 1)
		for _i in range(lizard_count):
			var spawn_pos: Vector3 = _find_animal_spawn_position(rng, chunk_world_x, chunk_world_z, chunk_world_size)
			if spawn_pos != Vector3.ZERO:
				_spawn_lizard(spawn_pos)
		for _i in range(tortoise_count):
			var spawn_pos: Vector3 = _find_animal_spawn_position(rng, chunk_world_x, chunk_world_z, chunk_world_size)
			if spawn_pos != Vector3.ZERO:
				_spawn_tortoise(spawn_pos)


func _find_animal_spawn_position(rng: RandomNumberGenerator, chunk_x: float, chunk_z: float, chunk_size: float) -> Vector3:
	## Find a valid spawn position for an animal within this chunk
	var max_attempts: int = 10

	for _attempt in range(max_attempts):
		var x: float = chunk_x + rng.randf() * chunk_size
		var z: float = chunk_z + rng.randf() * chunk_size

		# Skip if too close to spawn/campsite
		var dist_from_camp: float = Vector2(x, z).length()
		if dist_from_camp < 15.0:
			continue

		# Skip water areas
		if chunk_manager.is_near_any_pond(x, z, 3.0):
			continue

		# Get terrain height
		var y: float = chunk_manager.get_height_at(x, z)
		if y < 0:
			continue  # Water

		return Vector3(x, y, z)

	return Vector3.ZERO  # No valid position found


func _spawn_rabbit(pos: Vector3) -> void:
	var rabbit: AmbientRabbit = AmbientRabbit.new()
	rabbit.position = pos
	add_child(rabbit)
	spawned_animals.append(rabbit)


func _spawn_bird(pos: Vector3) -> void:
	var bird: AmbientBird = AmbientBird.new()
	bird.position = pos
	add_child(bird)
	spawned_animals.append(bird)


func _spawn_lizard(pos: Vector3) -> void:
	var lizard: AmbientLizard = AmbientLizard.new()
	lizard.position = pos
	add_child(lizard)
	spawned_animals.append(lizard)


func _spawn_tortoise(pos: Vector3) -> void:
	var tortoise: AmbientTortoise = AmbientTortoise.new()
	tortoise.position = pos
	add_child(tortoise)
	spawned_animals.append(tortoise)


func unload() -> void:
	# Release generation slot if held (prevents deadlock on mid-generation unload)
	_release_generation_slot()

	# Clear height cache first - this signals async box collision to stop if still running
	_height_cache.clear()

	# Unregister trees from ResourceManager before freeing (preserves depleted state)
	if chunk_manager and chunk_manager.resource_manager:
		for tree in spawned_trees:
			if is_instance_valid(tree) and tree is ResourceNode:
				chunk_manager.resource_manager.unregister_chunk_resource(tree)

	# Clean up all children
	for tree in spawned_trees:
		if is_instance_valid(tree):
			tree.queue_free()
	spawned_trees.clear()

	# Unregister resources from ResourceManager before freeing
	if chunk_manager and chunk_manager.resource_manager:
		for resource in spawned_resources:
			if is_instance_valid(resource) and resource is ResourceNode:
				chunk_manager.resource_manager.unregister_chunk_resource(resource)

	for resource in spawned_resources:
		if is_instance_valid(resource):
			resource.queue_free()
	spawned_resources.clear()

	# Clean up animals with despawn method
	for animal in spawned_animals:
		if is_instance_valid(animal):
			if animal.has_method("despawn"):
				animal.despawn()
			else:
				animal.queue_free()
	spawned_animals.clear()

	if terrain_mesh:
		terrain_mesh.queue_free()
	if terrain_collision:
		terrain_collision.queue_free()
	if decorations_container:
		decorations_container.queue_free()
	if trees_container:
		trees_container.queue_free()
	if resources_container:
		resources_container.queue_free()

	queue_free()
