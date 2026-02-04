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

# Shared materials (static to avoid shader compilation per decoration)
static var _grass_mat: StandardMaterial3D = null
static var _flower_stem_mat: StandardMaterial3D = null
static var _flower_red_mat: StandardMaterial3D = null
static var _flower_yellow_mat: StandardMaterial3D = null


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


func setup(coord: Vector2i, manager: Node) -> void:
	chunk_coord = coord
	chunk_manager = manager


func generate() -> void:
	if is_generated:
		return

	# Generate terrain mesh and collision immediately (required for player to walk)
	_generate_terrain_mesh()
	_generate_collision_from_mesh()  # Uses height cache from mesh generation

	# Defer spawning to spread work across frames
	call_deferred("_spawn_chunk_trees")
	call_deferred("_deferred_spawn_resources")
	call_deferred("_deferred_spawn_decorations")
	call_deferred("_deferred_spawn_animals")

	is_generated = true


func _deferred_spawn_resources() -> void:
	# Extra frame delay to spread load
	await get_tree().process_frame
	_spawn_chunk_resources()


func _deferred_spawn_decorations() -> void:
	# Extra frame delay to spread load
	await get_tree().process_frame
	await get_tree().process_frame
	_spawn_chunk_decorations()


func _deferred_spawn_animals() -> void:
	# Extra frame delay to spread load
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_spawn_chunk_animals()


# Cached height values for this chunk (includes 1 cell border for neighbor lookups)
var _height_cache: Array = []
var _height_cache_size: int = 0


func _generate_terrain_mesh() -> void:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var cell_size: float = chunk_manager.cell_size
	var chunk_size_cells: int = chunk_manager.chunk_size_cells

	# Calculate world position of this chunk's origin
	var chunk_world_x: float = chunk_coord.x * chunk_size_cells * cell_size
	var chunk_world_z: float = chunk_coord.y * chunk_size_cells * cell_size

	# Pre-compute and cache all heights (including 1 cell border for neighbor lookups)
	# This dramatically reduces noise sampling calls
	_height_cache_size = chunk_size_cells + 2  # +2 for border cells
	_height_cache.resize(_height_cache_size)
	for cz in range(_height_cache_size):
		_height_cache[cz] = []
		_height_cache[cz].resize(_height_cache_size)
		for cx in range(_height_cache_size):
			var world_x: float = chunk_world_x + ((cx - 1) * cell_size) + cell_size / 2.0
			var world_z: float = chunk_world_z + ((cz - 1) * cell_size) + cell_size / 2.0
			_height_cache[cz][cx] = chunk_manager.get_height_at(world_x, world_z)

	# Generate each cell in this chunk
	for cz in range(chunk_size_cells):
		for cx in range(chunk_size_cells):
			var world_x: float = chunk_world_x + (cx * cell_size)
			var world_z: float = chunk_world_z + (cz * cell_size)

			# Get height from cache (offset by 1 for border)
			var height: float = _height_cache[cz + 1][cx + 1]

			# Create top face
			_add_top_face_cached(surface_tool, world_x, world_z, cell_size, height, cx, cz)

			# Create side faces where there's height difference
			_add_side_faces_cached(surface_tool, world_x, world_z, cell_size, height, cx, cz, chunk_size_cells)

	var mesh: ArrayMesh = surface_tool.commit()

	terrain_mesh = MeshInstance3D.new()
	terrain_mesh.mesh = mesh
	terrain_mesh.material_override = chunk_manager.get_terrain_material()
	add_child(terrain_mesh)
	# NOTE: Don't clear height cache here - collision generation needs it


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

	# North side (z-)
	var north_height: float = _height_cache[base_cz - 1][base_cx]
	if height > north_height:
		_add_side_quad(st, Vector3(x, height, z), Vector3(x + size, height, z),
					   Vector3(x + size, north_height, z), Vector3(x, north_height, z),
					   Vector3(0, 0, -1))

	# South side (z+)
	var south_height: float = _height_cache[base_cz + 1][base_cx]
	if height > south_height:
		_add_side_quad(st, Vector3(x + size, height, z + size), Vector3(x, height, z + size),
					   Vector3(x, south_height, z + size), Vector3(x + size, south_height, z + size),
					   Vector3(0, 0, 1))

	# West side (x-)
	var west_height: float = _height_cache[base_cz][base_cx - 1]
	if height > west_height:
		_add_side_quad(st, Vector3(x, height, z + size), Vector3(x, height, z),
					   Vector3(x, west_height, z), Vector3(x, west_height, z + size),
					   Vector3(-1, 0, 0))

	# East side (x+)
	var east_height: float = _height_cache[base_cz][base_cx + 1]
	if height > east_height:
		_add_side_quad(st, Vector3(x + size, height, z), Vector3(x + size, height, z + size),
					   Vector3(x + size, east_height, z + size), Vector3(x + size, east_height, z),
					   Vector3(1, 0, 0))


func _add_top_face(st: SurfaceTool, x: float, z: float, size: float, height: float, cx: int, cz: int) -> void:
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

	# Color variation based on world position for consistency across chunks
	var world_cx: int = chunk_coord.x * chunk_manager.chunk_size_cells + cx
	var world_cz: int = chunk_coord.y * chunk_manager.chunk_size_cells + cz
	var variation: float = sin(world_cx * 12.9898 + world_cz * 78.233) * 0.08

	var cell_grass: Color = Color(
		clamp(grass_color.r + variation, grass_color.r - 0.08, grass_color.r + 0.10),
		clamp(grass_color.g + variation * 0.5, grass_color.g - 0.07, grass_color.g + 0.10),
		clamp(grass_color.b + variation * 0.3, grass_color.b - 0.07, grass_color.b + 0.07)
	)

	# Calculate vertex AO for each corner
	# Sample heights at the 3 diagonal neighbors that share each corner
	var ao0: float = _calculate_vertex_ao(x, z, height, -1, -1)  # NW corner (v0)
	var ao1: float = _calculate_vertex_ao(x + size, z, height, 1, -1)  # NE corner (v1)
	var ao2: float = _calculate_vertex_ao(x + size, z + size, height, 1, 1)  # SE corner (v2)
	var ao3: float = _calculate_vertex_ao(x, z + size, height, -1, 1)  # SW corner (v3)

	# Apply AO to colors
	var color0: Color = cell_grass * ao0
	var color1: Color = cell_grass * ao1
	var color2: Color = cell_grass * ao2
	var color3: Color = cell_grass * ao3

	# Get UV coordinates for top face (grass_top texture or stone for rocky)
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


## Calculate ambient occlusion factor for a vertex corner.
## dir_x/dir_z indicate which corner (-1,-1 = NW, 1,-1 = NE, 1,1 = SE, -1,1 = SW)
func _calculate_vertex_ao(vertex_x: float, vertex_z: float, current_height: float, dir_x: int, dir_z: int) -> float:
	var cell_size: float = chunk_manager.cell_size
	var ao_strength: float = 0.12  # How much each occluding neighbor darkens

	# Sample the 3 neighbors that share this corner
	# Cardinal neighbors (share an edge)
	var neighbor_x_height: float = chunk_manager.get_height_at(vertex_x + dir_x * cell_size, vertex_z)
	var neighbor_z_height: float = chunk_manager.get_height_at(vertex_x, vertex_z + dir_z * cell_size)
	# Diagonal neighbor (share just the corner)
	var neighbor_diag_height: float = chunk_manager.get_height_at(vertex_x + dir_x * cell_size, vertex_z + dir_z * cell_size)

	# Count how many neighbors are higher (would cast shadow on this corner)
	var occlusion_count: int = 0
	if neighbor_x_height > current_height:
		occlusion_count += 1
	if neighbor_z_height > current_height:
		occlusion_count += 1
	if neighbor_diag_height > current_height:
		# Diagonal counts less (further away)
		occlusion_count += 1

	# AO factor: 1.0 = no occlusion, lower = darker
	var ao: float = 1.0 - (occlusion_count * ao_strength)
	return clamp(ao, 0.55, 1.0)  # Don't go too dark


func _add_side_faces(st: SurfaceTool, x: float, z: float, size: float, height: float, cx: int, cz: int, chunk_size_cells: int) -> void:
	var cell_size: float = chunk_manager.cell_size

	# Calculate world position for neighbor lookups
	var chunk_world_x: float = chunk_coord.x * chunk_size_cells * cell_size
	var chunk_world_z: float = chunk_coord.y * chunk_size_cells * cell_size

	# North side (z-)
	var north_x: float = x + size / 2.0
	var north_z: float = z - size / 2.0
	var north_height: float = chunk_manager.get_height_at(north_x, north_z)
	if height > north_height:
		_add_side_quad(st, Vector3(x, height, z), Vector3(x + size, height, z),
					   Vector3(x + size, north_height, z), Vector3(x, north_height, z),
					   Vector3(0, 0, -1))

	# South side (z+)
	var south_x: float = x + size / 2.0
	var south_z: float = z + size + size / 2.0
	var south_height: float = chunk_manager.get_height_at(south_x, south_z)
	if height > south_height:
		_add_side_quad(st, Vector3(x + size, height, z + size), Vector3(x, height, z + size),
					   Vector3(x, south_height, z + size), Vector3(x + size, south_height, z + size),
					   Vector3(0, 0, 1))

	# West side (x-)
	var west_x: float = x - size / 2.0
	var west_z: float = z + size / 2.0
	var west_height: float = chunk_manager.get_height_at(west_x, west_z)
	if height > west_height:
		_add_side_quad(st, Vector3(x, height, z + size), Vector3(x, height, z),
					   Vector3(x, west_height, z), Vector3(x, west_height, z + size),
					   Vector3(-1, 0, 0))

	# East side (x+)
	var east_x: float = x + size + size / 2.0
	var east_z: float = z + size / 2.0
	var east_height: float = chunk_manager.get_height_at(east_x, east_z)
	if height > east_height:
		_add_side_quad(st, Vector3(x + size, height, z), Vector3(x + size, height, z + size),
					   Vector3(x + size, east_height, z + size), Vector3(x + size, east_height, z),
					   Vector3(1, 0, 0))


func _add_side_quad(st: SurfaceTool, v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3, normal: Vector3) -> void:
	# Get region-specific colors based on position
	var center_x: float = (v0.x + v1.x) / 2.0
	var center_z: float = (v0.z + v2.z) / 2.0
	var region: ChunkManager.RegionType = chunk_manager.get_region_at(center_x, center_z)
	var region_colors: Dictionary = chunk_manager.get_region_colors(region)
	var grass_color: Color = region_colors["grass"]
	var dirt_color: Color = region_colors["dirt"]

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

	# Calculate AO for side face vertices
	# Top vertices (v0, v1) are at the cliff edge - check if there's terrain above (overhang)
	# Bottom vertices (v2, v3) are in a corner - darker due to surrounding terrain
	var ao_top: float = _calculate_side_ao_top(center_x, center_z, v0.y, normal)
	var ao_bottom: float = _calculate_side_ao_bottom(center_x, center_z, v2.y, normal)

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


## Calculate AO for top vertices of a side face (cliff edge).
func _calculate_side_ao_top(x: float, z: float, height: float, face_normal: Vector3) -> float:
	var cell_size: float = chunk_manager.cell_size

	# Check if there's terrain directly above this face (overhang effect)
	# Sample behind the face (opposite to normal direction) and above
	var behind_x: float = x - face_normal.x * cell_size
	var behind_z: float = z - face_normal.z * cell_size
	var behind_height: float = chunk_manager.get_height_at(behind_x, behind_z)

	# If the terrain behind is higher, this edge is in shadow
	if behind_height > height:
		return 0.85  # Subtle darkening at cliff edge
	return 1.0


## Calculate AO for bottom vertices of a side face (in corner/crevice).
func _calculate_side_ao_bottom(x: float, z: float, height: float, face_normal: Vector3) -> float:
	var cell_size: float = chunk_manager.cell_size
	var ao_strength: float = 0.10

	# Bottom vertices are recessed - check surrounding terrain heights
	# Sample in front of the face and to the sides
	var front_x: float = x + face_normal.x * cell_size
	var front_z: float = z + face_normal.z * cell_size
	var front_height: float = chunk_manager.get_height_at(front_x, front_z)

	# Also check perpendicular directions
	var perp_x: float = -face_normal.z  # Perpendicular direction
	var perp_z: float = face_normal.x
	var left_height: float = chunk_manager.get_height_at(x + perp_x * cell_size, z + perp_z * cell_size)
	var right_height: float = chunk_manager.get_height_at(x - perp_x * cell_size, z - perp_z * cell_size)

	var occlusion_count: int = 0
	if front_height > height:
		occlusion_count += 1
	if left_height > height:
		occlusion_count += 1
	if right_height > height:
		occlusion_count += 1

	# Bottom of cliffs/walls are naturally darker
	var base_darkness: float = 0.90  # 10% darker as base
	var ao: float = base_darkness - (occlusion_count * ao_strength)
	return clamp(ao, 0.55, 0.95)


func _generate_collision_from_mesh() -> void:
	# Use box collision for each cell - required for CharacterBody3D movement
	# ConcavePolygonShape3D doesn't work well with move_and_slide()
	terrain_collision = StaticBody3D.new()
	terrain_collision.name = "TerrainCollision"

	var cell_size: float = chunk_manager.cell_size
	var chunk_size_cells: int = chunk_manager.chunk_size_cells
	var chunk_world_size: float = chunk_size_cells * cell_size

	var chunk_world_x: float = chunk_coord.x * chunk_world_size
	var chunk_world_z: float = chunk_coord.y * chunk_world_size

	# Create a box collision for each terrain cell
	# Use height cache if available, otherwise call get_height_at
	for cz in range(chunk_size_cells):
		for cx in range(chunk_size_cells):
			var center_x: float = chunk_world_x + cx * cell_size + cell_size / 2.0
			var center_z: float = chunk_world_z + cz * cell_size + cell_size / 2.0

			# Use cached height if available
			var height: float
			if _height_cache.size() > 0:
				height = _height_cache[cz + 1][cx + 1]
			else:
				height = chunk_manager.get_height_at(center_x, center_z)

			# Create box from y=height going down to y=-10
			var box_bottom: float = -10.0
			var box_height: float = height - box_bottom
			if box_height <= 0:
				continue

			var collision_shape: CollisionShape3D = CollisionShape3D.new()
			var box: BoxShape3D = BoxShape3D.new()
			box.size = Vector3(cell_size, box_height, cell_size)

			collision_shape.shape = box
			collision_shape.position = Vector3(center_x, height - box_height / 2.0, center_z)

			terrain_collision.add_child(collision_shape)

	add_child(terrain_collision)

	# Clear height cache to free memory (no longer needed after collision generated)
	_height_cache.clear()


func _generate_collision() -> void:
	_generate_collision_from_mesh()


func _spawn_chunk_trees() -> void:
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

			# Get region type and tree multiplier
			var region: ChunkManager.RegionType = chunk_manager.get_region_at(world_x, world_z)
			var tree_multiplier: float = chunk_manager.get_vegetation_multiplier(region, "tree")

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

				var tree_y: float = chunk_manager.get_height_at(tree_x, tree_z)

				# Choose tree type
				var tree: Node3D
				var tree_type_roll: float = rng.randf()

				if tree_type_roll < 0.60:
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

				trees_container.add_child(tree)
				spawned_trees.append(tree)

			z += tree_grid_size
		x += tree_grid_size


func _spawn_chunk_resources() -> void:
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

	var resource_grid_size: float = 4.0  # Larger grid for resources

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

			var res_y: float = chunk_manager.get_height_at(res_x, res_z)

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

			# Try spawning different resource types
			var resource_roll: float = rng.randf()

			# Branches - more common near trees (use forest noise)
			var forest_value: float = (chunk_manager.forest_noise.get_noise_2d(res_x, res_z) + 1.0) * 0.5
			var branch_chance: float = chunk_manager.branch_density * (0.5 + forest_value)
			if resource_roll < branch_chance and chunk_manager.branch_scene:
				_spawn_resource(chunk_manager.branch_scene, res_x, res_y, res_z, rng)
				z += resource_grid_size
				continue

			# Rocks - spawn near water pools (shoreline rocks) + region-based
			resource_roll = rng.randf()
			var dist_to_pond: float = chunk_manager.get_distance_to_nearest_pond(res_x, res_z)
			var pond_radius: float = chunk_manager.pond_radius
			var rock_chance: float = 0.0

			# Rocks spawn in a band around ponds (from pond edge to ~15 units out)
			var dist_from_pond_edge: float = dist_to_pond - pond_radius
			if dist_from_pond_edge > 0.0 and dist_from_pond_edge < 15.0:
				# Higher chance closer to water edge, tapering off with distance
				var proximity_factor: float = 1.0 - (dist_from_pond_edge / 15.0)
				rock_chance = chunk_manager.rock_density * 8.0 * proximity_factor * rock_mult
			else:
				# Region-based rock spawning (rocky areas have many more rocks)
				rock_chance = chunk_manager.rock_density * rock_mult

			if resource_roll < rock_chance and chunk_manager.rock_scene:
				_spawn_resource(chunk_manager.rock_scene, res_x, res_y, res_z, rng)
				z += resource_grid_size
				continue

			# Berry bushes - clustered in clearings (inverse of forest), region-adjusted
			resource_roll = rng.randf()
			var berry_chance: float = chunk_manager.berry_density * (1.5 - forest_value) * berry_mult
			if resource_roll < berry_chance and chunk_manager.berry_bush_scene:
				_spawn_resource(chunk_manager.berry_bush_scene, res_x, res_y, res_z, rng)
				z += resource_grid_size
				continue

			# Mushrooms - more common in forests
			resource_roll = rng.randf()
			var mushroom_chance: float = chunk_manager.mushroom_density * (0.5 + forest_value)
			if resource_roll < mushroom_chance and chunk_manager.mushroom_scene:
				_spawn_resource(chunk_manager.mushroom_scene, res_x, res_y, res_z, rng)
				z += resource_grid_size
				continue

			# Herbs - scattered everywhere, region-adjusted
			resource_roll = rng.randf()
			if resource_roll < chunk_manager.herb_density * herb_mult and chunk_manager.herb_scene:
				_spawn_resource(chunk_manager.herb_scene, res_x, res_y, res_z, rng)
				z += resource_grid_size
				continue

			# Ore deposits - spawn in ROCKY (4.5%) and HILLS (1.5%) regions
			resource_roll = rng.randf()
			var ore_chance: float = 0.0
			if region == ChunkManager.RegionType.ROCKY:
				ore_chance = 0.045  # 4.5% chance in rocky
			elif region == ChunkManager.RegionType.HILLS:
				ore_chance = 0.015  # 1.5% chance in hills
			if resource_roll < ore_chance and chunk_manager.ore_scene:
				_spawn_resource(chunk_manager.ore_scene, res_x, res_y, res_z, rng)

			z += resource_grid_size
		x += resource_grid_size


func _spawn_resource(scene: PackedScene, x: float, y: float, z: float, rng: RandomNumberGenerator) -> void:
	var resource: Node3D = scene.instantiate()

	# Sample terrain heights at multiple points around the resource to handle cell boundaries
	# Resource could extend up to 0.5 units in any direction, so check those points
	var sample_offsets: Array[Vector2] = [
		Vector2(0.0, 0.0),    # Center
		Vector2(0.5, 0.0),    # East
		Vector2(-0.5, 0.0),   # West
		Vector2(0.0, 0.5),    # South
		Vector2(0.0, -0.5),   # North
	]

	var max_height: float = y
	for offset in sample_offsets:
		var sample_height: float = chunk_manager.get_height_at(x + offset.x, z + offset.y)
		if sample_height > max_height:
			max_height = sample_height

	# Add small offset so resource sits on TOP of terrain, not half-buried
	var height_offset: float = 0.1  # Half the resource height (0.2)

	resource.position = Vector3(x, max_height + height_offset, z)
	resource.rotation.y = rng.randf() * TAU
	resources_container.add_child(resource)
	spawned_resources.append(resource)


func _spawn_chunk_decorations() -> void:
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

	var target_grass: int = int(60 * area_ratio)  # Reduced from 250
	var target_red_flowers: int = int(10 * area_ratio)  # Reduced from 35
	var target_yellow_flowers: int = int(10 * area_ratio)  # Reduced from 35

	var grass_count: int = 0
	var attempts: int = 0
	var max_attempts: int = target_grass * 10

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

		# Skip if too close to campsite center
		var dist_from_camp: float = Vector2(world_x, world_z).length()
		if dist_from_camp < 8.0:
			attempts += 1
			continue

		var noise_value: float = (decoration_noise.get_noise_2d(world_x, world_z) + 1.0) * 0.5
		if noise_value > 0.3:
			var y: float = chunk_manager.get_height_at(world_x, world_z)
			_create_grass_tuft(Vector3(world_x, y + 0.01, world_z), rng)
			grass_count += 1

		attempts += 1

	# Spawn flowers
	var flower_count: int = 0
	attempts = 0
	max_attempts = (target_red_flowers + target_yellow_flowers) * 10

	while flower_count < target_red_flowers + target_yellow_flowers and attempts < max_attempts:
		var x: float = rng.randf_range(0, chunk_world_size)
		var z: float = rng.randf_range(0, chunk_world_size)
		var world_x: float = chunk_world_x + x
		var world_z: float = chunk_world_z + z

		# Skip if in any pond area
		if chunk_manager.is_near_any_pond(world_x, world_z, 1.0):
			attempts += 1
			continue

		var dist_from_camp: float = Vector2(world_x, world_z).length()
		if dist_from_camp < 8.0:
			attempts += 1
			continue

		var noise_value: float = (decoration_noise.get_noise_2d(world_x * 1.5, world_z * 1.5) + 1.0) * 0.5
		if noise_value > 0.5:
			var y: float = chunk_manager.get_height_at(world_x, world_z)
			var color: Color
			if flower_count < target_red_flowers:
				color = Color(0.85, 0.15, 0.15)  # Red
			else:
				color = Color(0.95, 0.85, 0.15)  # Yellow
			_create_flower(Vector3(world_x, y + 0.01, world_z), color, rng)
			flower_count += 1

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


func _spawn_chunk_animals() -> void:
	## Spawn ambient wildlife based on region type
	## Animals are sparse - only ~30% of chunks have any animals
	var cell_size: float = chunk_manager.cell_size
	var chunk_size_cells: int = chunk_manager.chunk_size_cells
	var chunk_world_size: float = chunk_size_cells * cell_size

	var chunk_world_x: float = chunk_coord.x * chunk_world_size
	var chunk_world_z: float = chunk_coord.y * chunk_world_size

	# Use deterministic random for consistent animal placement
	var chunk_seed: int = chunk_coord.x * 91939 ^ chunk_coord.y * 37573
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = chunk_seed

	# Only 15% of chunks have any animals - reduced for performance
	if rng.randf() > 0.15:
		return

	# Get the dominant region for this chunk (sample center)
	var center_x: float = chunk_world_x + chunk_world_size / 2.0
	var center_z: float = chunk_world_z + chunk_world_size / 2.0
	var region: ChunkManager.RegionType = chunk_manager.get_region_at(center_x, center_z)

	# Determine spawn counts based on region (reduced counts)
	var rabbit_count: int = 0
	var bird_count: int = 0

	match region:
		ChunkManager.RegionType.MEADOW:
			rabbit_count = rng.randi_range(0, 1)
			bird_count = rng.randi_range(0, 1)
		ChunkManager.RegionType.FOREST:
			rabbit_count = rng.randi_range(0, 1)
			bird_count = rng.randi_range(0, 1)
		ChunkManager.RegionType.HILLS:
			rabbit_count = 0
			bird_count = rng.randi_range(0, 1)
		ChunkManager.RegionType.ROCKY:
			rabbit_count = 0
			bird_count = rng.randi_range(0, 1)

	# Cap total animals per chunk for performance
	var max_animals: int = 2
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


func unload() -> void:
	# Clean up all children
	for tree in spawned_trees:
		if is_instance_valid(tree):
			tree.queue_free()
	spawned_trees.clear()

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
