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
var is_generated: bool = false


func setup(coord: Vector2i, manager: Node) -> void:
	chunk_coord = coord
	chunk_manager = manager


func generate() -> void:
	if is_generated:
		return

	_generate_terrain_mesh()
	_generate_collision()
	_spawn_chunk_trees()
	_spawn_chunk_resources()
	_spawn_chunk_decorations()

	is_generated = true


func _generate_terrain_mesh() -> void:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var cell_size: float = chunk_manager.cell_size
	var chunk_size_cells: int = chunk_manager.chunk_size_cells

	# Calculate world position of this chunk's origin
	var chunk_world_x: float = chunk_coord.x * chunk_size_cells * cell_size
	var chunk_world_z: float = chunk_coord.y * chunk_size_cells * cell_size

	# Generate each cell in this chunk
	for cz in range(chunk_size_cells):
		for cx in range(chunk_size_cells):
			var world_x: float = chunk_world_x + (cx * cell_size)
			var world_z: float = chunk_world_z + (cz * cell_size)

			# Get height at cell center
			var center_x: float = world_x + cell_size / 2.0
			var center_z: float = world_z + cell_size / 2.0
			var height: float = chunk_manager.get_height_at(center_x, center_z)

			# Create top face
			_add_top_face(surface_tool, world_x, world_z, cell_size, height, cx, cz)

			# Create side faces where there's height difference
			_add_side_faces(surface_tool, world_x, world_z, cell_size, height, cx, cz, chunk_size_cells)

	var mesh: ArrayMesh = surface_tool.commit()

	terrain_mesh = MeshInstance3D.new()
	terrain_mesh.mesh = mesh
	terrain_mesh.material_override = chunk_manager.get_terrain_material()
	add_child(terrain_mesh)


func _add_top_face(st: SurfaceTool, x: float, z: float, size: float, height: float, cx: int, cz: int) -> void:
	var v0 := Vector3(x, height, z)
	var v1 := Vector3(x + size, height, z)
	var v2 := Vector3(x + size, height, z + size)
	var v3 := Vector3(x, height, z + size)

	var normal := Vector3.UP

	# Color variation based on world position for consistency across chunks
	var world_cx: int = chunk_coord.x * chunk_manager.chunk_size_cells + cx
	var world_cz: int = chunk_coord.y * chunk_manager.chunk_size_cells + cz
	var variation: float = sin(world_cx * 12.9898 + world_cz * 78.233) * 0.08

	var grass_color: Color = chunk_manager.grass_color
	var cell_grass: Color = Color(
		clamp(grass_color.r + variation, 0.20, 0.38),
		clamp(grass_color.g + variation * 0.5, 0.45, 0.62),
		clamp(grass_color.b + variation * 0.3, 0.08, 0.22)
	)

	# Triangle 1
	st.set_color(cell_grass)
	st.set_normal(normal)
	st.add_vertex(v0)
	st.set_color(cell_grass)
	st.set_normal(normal)
	st.add_vertex(v2)
	st.set_color(cell_grass)
	st.set_normal(normal)
	st.add_vertex(v1)

	# Triangle 2
	st.set_color(cell_grass)
	st.set_normal(normal)
	st.add_vertex(v0)
	st.set_color(cell_grass)
	st.set_normal(normal)
	st.add_vertex(v3)
	st.set_color(cell_grass)
	st.set_normal(normal)
	st.add_vertex(v2)


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
	var grass_color: Color = chunk_manager.grass_color
	var dirt_color: Color = chunk_manager.dirt_color

	var grass_thickness: float = 0.25
	var total_height: float = v0.y - v2.y

	# Color variation based on position
	var variation: float = sin(v0.x * 12.9898 + v0.z * 78.233 + v0.y * 37.719) * 0.06
	var cell_grass: Color = Color(
		clamp(grass_color.r + variation, 0.20, 0.38),
		clamp(grass_color.g + variation * 0.5, 0.45, 0.62),
		clamp(grass_color.b + variation * 0.3, 0.08, 0.22)
	)
	var cell_dirt: Color = Color(
		clamp(dirt_color.r + variation, 0.32, 0.50),
		clamp(dirt_color.g + variation * 0.8, 0.18, 0.32),
		clamp(dirt_color.b + variation * 0.5, 0.06, 0.18)
	)

	if total_height > grass_thickness:
		# Split into grass strip + dirt
		var grass_bottom_y: float = v0.y - grass_thickness
		var g2 := Vector3(v1.x, grass_bottom_y, v1.z)
		var g3 := Vector3(v0.x, grass_bottom_y, v0.z)

		# Grass strip
		st.set_color(cell_grass)
		st.set_normal(normal)
		st.add_vertex(v0)
		st.set_color(cell_grass)
		st.set_normal(normal)
		st.add_vertex(v1)
		st.set_color(cell_grass)
		st.set_normal(normal)
		st.add_vertex(g2)

		st.set_color(cell_grass)
		st.set_normal(normal)
		st.add_vertex(v0)
		st.set_color(cell_grass)
		st.set_normal(normal)
		st.add_vertex(g2)
		st.set_color(cell_grass)
		st.set_normal(normal)
		st.add_vertex(g3)

		# Dirt section
		st.set_color(cell_dirt)
		st.set_normal(normal)
		st.add_vertex(g3)
		st.set_color(cell_dirt)
		st.set_normal(normal)
		st.add_vertex(g2)
		st.set_color(cell_dirt)
		st.set_normal(normal)
		st.add_vertex(v2)

		st.set_color(cell_dirt)
		st.set_normal(normal)
		st.add_vertex(g3)
		st.set_color(cell_dirt)
		st.set_normal(normal)
		st.add_vertex(v2)
		st.set_color(cell_dirt)
		st.set_normal(normal)
		st.add_vertex(v3)
	else:
		# All grass for short sides
		st.set_color(cell_grass)
		st.set_normal(normal)
		st.add_vertex(v0)
		st.set_color(cell_grass)
		st.set_normal(normal)
		st.add_vertex(v1)
		st.set_color(cell_grass)
		st.set_normal(normal)
		st.add_vertex(v2)

		st.set_color(cell_grass)
		st.set_normal(normal)
		st.add_vertex(v0)
		st.set_color(cell_grass)
		st.set_normal(normal)
		st.add_vertex(v2)
		st.set_color(cell_grass)
		st.set_normal(normal)
		st.add_vertex(v3)


func _generate_collision() -> void:
	# Use box collision for each cell to create true Minecraft-style blocky collision
	# This prevents walking up block edges - player must jump
	terrain_collision = StaticBody3D.new()
	terrain_collision.name = "TerrainCollision"

	var cell_size: float = chunk_manager.cell_size
	var chunk_size_cells: int = chunk_manager.chunk_size_cells
	var chunk_world_size: float = chunk_size_cells * cell_size

	var chunk_world_x: float = chunk_coord.x * chunk_world_size
	var chunk_world_z: float = chunk_coord.y * chunk_world_size

	# Create a box collision for each terrain cell
	for cz in range(chunk_size_cells):
		for cx in range(chunk_size_cells):
			var world_x: float = chunk_world_x + cx * cell_size
			var world_z: float = chunk_world_z + cz * cell_size
			var center_x: float = world_x + cell_size / 2.0
			var center_z: float = world_z + cell_size / 2.0

			var height: float = chunk_manager.get_height_at(center_x, center_z)

			# Create box from y=height going down to y=-10 (thick enough for pond floor too)
			# Pond floor is at -2.5, so we need boxes to extend below that
			var box_bottom: float = -10.0
			var box_height: float = height - box_bottom
			if box_height <= 0:
				continue

			var collision_shape: CollisionShape3D = CollisionShape3D.new()
			var box: BoxShape3D = BoxShape3D.new()
			box.size = Vector3(cell_size, box_height, cell_size)

			collision_shape.shape = box
			# Position box so top surface is at terrain height
			collision_shape.position = Vector3(center_x, height - box_height / 2.0, center_z)

			terrain_collision.add_child(collision_shape)

	add_child(terrain_collision)


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

			# Skip if in pond area
			var pond_center: Vector2 = chunk_manager.pond_center
			var pond_radius: float = chunk_manager.pond_radius
			var dist_to_pond: float = Vector2(world_x - pond_center.x, world_z - pond_center.y).length()
			if dist_to_pond < pond_radius + 2.0:
				z += tree_grid_size
				continue

			# Get forest density from noise
			var density_value: float = (chunk_manager.forest_noise.get_noise_2d(world_x, world_z) + 1.0) * 0.5

			var spawn_chance: float = 0.0
			if density_value > 0.35:
				spawn_chance = tree_density * (density_value - 0.35) / 0.65 * 2.5

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

			# Skip if in pond area (check AFTER jitter is applied)
			var pond_center: Vector2 = chunk_manager.pond_center
			var pond_radius: float = chunk_manager.pond_radius
			var dist_to_pond: float = Vector2(res_x - pond_center.x, res_z - pond_center.y).length()
			if dist_to_pond < pond_radius + 2.0:
				z += resource_grid_size
				continue

			var res_y: float = chunk_manager.get_height_at(res_x, res_z)

			# Skip if in water (negative height = pond)
			if res_y < 0:
				z += resource_grid_size
				continue

			# Distance from campsite affects spawn rates
			var dist_from_camp: float = Vector2(res_x, res_z).length()

			# Try spawning different resource types
			var resource_roll: float = rng.randf()

			# Branches - more common near trees (use forest noise)
			var forest_value: float = (chunk_manager.forest_noise.get_noise_2d(res_x, res_z) + 1.0) * 0.5
			var branch_chance: float = chunk_manager.branch_density * (0.5 + forest_value)
			if resource_roll < branch_chance and chunk_manager.branch_scene:
				_spawn_resource(chunk_manager.branch_scene, res_x, res_y, res_z, rng)
				z += resource_grid_size
				continue

			# Rocks - more common away from campsite
			resource_roll = rng.randf()
			var rock_chance: float = chunk_manager.rock_density
			if dist_from_camp > 10.0:
				rock_chance *= 1.5
			if resource_roll < rock_chance and chunk_manager.rock_scene:
				_spawn_resource(chunk_manager.rock_scene, res_x, res_y, res_z, rng)
				z += resource_grid_size
				continue

			# Berry bushes - clustered in clearings (inverse of forest)
			resource_roll = rng.randf()
			var berry_chance: float = chunk_manager.berry_density * (1.5 - forest_value)
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

			# Herbs - scattered everywhere
			resource_roll = rng.randf()
			if resource_roll < chunk_manager.herb_density and chunk_manager.herb_scene:
				_spawn_resource(chunk_manager.herb_scene, res_x, res_y, res_z, rng)

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
	var chunk_area: float = chunk_world_size * chunk_world_size
	var world_area: float = 110.0 * 110.0  # Original decoration area (55 radius * 2)
	var area_ratio: float = chunk_area / world_area

	var target_grass: int = int(250 * area_ratio)
	var target_red_flowers: int = int(35 * area_ratio)
	var target_yellow_flowers: int = int(35 * area_ratio)

	var grass_count: int = 0
	var attempts: int = 0
	var max_attempts: int = target_grass * 10

	# Spawn grass
	while grass_count < target_grass and attempts < max_attempts:
		var x: float = rng.randf_range(0, chunk_world_size)
		var z: float = rng.randf_range(0, chunk_world_size)
		var world_x: float = chunk_world_x + x
		var world_z: float = chunk_world_z + z

		# Skip if in pond area
		var pond_center: Vector2 = chunk_manager.pond_center
		var pond_radius: float = chunk_manager.pond_radius
		var dist_to_pond: float = Vector2(world_x - pond_center.x, world_z - pond_center.y).length()
		if dist_to_pond < pond_radius + 1.0:
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

		var pond_center: Vector2 = chunk_manager.pond_center
		var pond_radius: float = chunk_manager.pond_radius
		var dist_to_pond: float = Vector2(world_x - pond_center.x, world_z - pond_center.y).length()
		if dist_to_pond < pond_radius + 1.0:
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

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	grass.material_override = mat

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

	var stem_mat: StandardMaterial3D = StandardMaterial3D.new()
	stem_mat.albedo_color = Color(0.2, 0.5, 0.15)
	stem.material_override = stem_mat
	stem.position.y = 0.15
	flower.add_child(stem)

	# Flower head
	var head: MeshInstance3D = MeshInstance3D.new()
	var head_mesh: BoxMesh = BoxMesh.new()
	head_mesh.size = Vector3(0.15, 0.12, 0.15)
	head.mesh = head_mesh

	var head_mat: StandardMaterial3D = StandardMaterial3D.new()
	head_mat.albedo_color = petal_color
	head.material_override = head_mat
	head.position.y = 0.35
	flower.add_child(head)

	flower.position = pos
	flower.rotation.y = rng.randf() * TAU
	decorations_container.add_child(flower)


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
