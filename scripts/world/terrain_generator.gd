extends Node3D
## Generates a blocky Minecraft-style terrain with stepped hills and forest.

@export var terrain_size: int = 100
@export var cell_size: float = 3.0  # Larger cells for gentler terrain
@export var height_scale: float = 6.0  # Lower hills
@export var height_step: float = 0.5  # Smaller steps for smoother transitions
@export var noise_scale: float = 0.02  # Broader noise for rolling hills

# Tree spawning settings
@export var tree_density: float = 0.15  # Base probability of tree per cell
@export var tree_min_distance: float = 14.0  # Minimum distance from campsite center
@export var tree_max_distance: float = 48.0  # Maximum distance for tree spawning
@export var tree_grid_size: float = 3.0  # Grid cell size for placement

var noise: FastNoiseLite
var terrain_mesh: MeshInstance3D
var terrain_collision: StaticBody3D

# Cache heights for collision
var height_cache: Dictionary = {}

# Tree scene
var tree_scene: PackedScene
var spawned_trees: Array[Node3D] = []
var forest_noise: FastNoiseLite  # Separate noise for forest density


func _ready() -> void:
	_setup_noise()
	_generate_blocky_terrain()
	_load_tree_scene()
	# Defer tree spawning to ensure Resources node exists
	call_deferred("_spawn_forest")


func _setup_noise() -> void:
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = randi()
	noise.fractal_octaves = 2  # Fewer octaves for broader, more plateau-like hills
	noise.frequency = noise_scale


func _generate_blocky_terrain() -> void:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_size: float = terrain_size / 2.0
	var cells_per_side: int = int(terrain_size / cell_size)

	# Generate each cell as a flat quad at its quantized height
	for cz in range(cells_per_side):
		for cx in range(cells_per_side):
			var world_x: float = (cx * cell_size) - half_size
			var world_z: float = (cz * cell_size) - half_size

			# Get quantized height for this cell's center
			var center_x: float = world_x + cell_size / 2.0
			var center_z: float = world_z + cell_size / 2.0
			var height: float = _get_blocky_height(center_x, center_z)

			# Cache for collision
			height_cache[Vector2i(cx, cz)] = height

			# Create top face of this cell (flat quad)
			_add_top_face(surface_tool, world_x, world_z, cell_size, height)

			# Create side faces where there's a height difference with neighbors
			_add_side_faces(surface_tool, cx, cz, world_x, world_z, cell_size, height, cells_per_side)

	# Commit mesh (no generate_normals - we set them manually for flat shading)
	var mesh: ArrayMesh = surface_tool.commit()

	terrain_mesh = MeshInstance3D.new()
	terrain_mesh.mesh = mesh
	terrain_mesh.material_override = _create_terrain_material()
	add_child(terrain_mesh)

	# Create collision
	_create_collision(mesh)


func _add_top_face(st: SurfaceTool, x: float, z: float, size: float, height: float) -> void:
	# Four corners of the top face
	var v0 := Vector3(x, height, z)
	var v1 := Vector3(x + size, height, z)
	var v2 := Vector3(x + size, height, z + size)
	var v3 := Vector3(x, height, z + size)

	var normal := Vector3.UP

	# Triangle 1
	st.set_normal(normal)
	st.add_vertex(v0)
	st.set_normal(normal)
	st.add_vertex(v2)
	st.set_normal(normal)
	st.add_vertex(v1)

	# Triangle 2
	st.set_normal(normal)
	st.add_vertex(v0)
	st.set_normal(normal)
	st.add_vertex(v3)
	st.set_normal(normal)
	st.add_vertex(v2)


func _add_side_faces(st: SurfaceTool, cx: int, cz: int, x: float, z: float, size: float, height: float, cells_per_side: int) -> void:
	# Check each neighbor and add side face if there's a drop
	var half_size: float = terrain_size / 2.0

	# North side (z-)
	if cz > 0:
		var neighbor_height: float = height_cache.get(Vector2i(cx, cz - 1), 0.0)
		if height > neighbor_height:
			_add_side_quad(st, Vector3(x, height, z), Vector3(x + size, height, z),
						   Vector3(x + size, neighbor_height, z), Vector3(x, neighbor_height, z),
						   Vector3(0, 0, -1))

	# South side (z+)
	if cz < cells_per_side - 1:
		var nz: float = ((cz + 1) * size) - half_size + size / 2.0
		var nx: float = x + size / 2.0
		var neighbor_height: float = _get_blocky_height(nx, nz)
		if height > neighbor_height:
			_add_side_quad(st, Vector3(x + size, height, z + size), Vector3(x, height, z + size),
						   Vector3(x, neighbor_height, z + size), Vector3(x + size, neighbor_height, z + size),
						   Vector3(0, 0, 1))

	# West side (x-)
	if cx > 0:
		var neighbor_height: float = height_cache.get(Vector2i(cx - 1, cz), 0.0)
		if height > neighbor_height:
			_add_side_quad(st, Vector3(x, height, z + size), Vector3(x, height, z),
						   Vector3(x, neighbor_height, z), Vector3(x, neighbor_height, z + size),
						   Vector3(-1, 0, 0))

	# East side (x+)
	if cx < cells_per_side - 1:
		var nx: float = ((cx + 1) * size) - half_size + size / 2.0
		var nz: float = z + size / 2.0
		var neighbor_height: float = _get_blocky_height(nx, nz)
		if height > neighbor_height:
			_add_side_quad(st, Vector3(x + size, height, z), Vector3(x + size, height, z + size),
						   Vector3(x + size, neighbor_height, z + size), Vector3(x + size, neighbor_height, z),
						   Vector3(1, 0, 0))


func _add_side_quad(st: SurfaceTool, v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3, normal: Vector3) -> void:
	# Triangle 1
	st.set_normal(normal)
	st.add_vertex(v0)
	st.set_normal(normal)
	st.add_vertex(v1)
	st.set_normal(normal)
	st.add_vertex(v2)

	# Triangle 2
	st.set_normal(normal)
	st.add_vertex(v0)
	st.set_normal(normal)
	st.add_vertex(v2)
	st.set_normal(normal)
	st.add_vertex(v3)


func _get_blocky_height(x: float, z: float) -> float:
	# Flatten area around spawn point (campsite)
	var distance_from_center: float = Vector2(x, z).length()
	var flatten_radius: float = 12.0
	var flatten_falloff: float = 10.0

	if distance_from_center < flatten_radius:
		# Completely flat at y=0 in the campsite area
		return 0.0

	# Base terrain height from noise
	var raw_height: float = noise.get_noise_2d(x, z)

	# Convert noise (-1 to 1) to positive height
	var height: float = (raw_height + 1.0) * 0.5 * height_scale

	# Quantize to blocky steps - this creates the Minecraft-style terraces
	height = floor(height / height_step) * height_step

	# Ensure minimum ground level
	height = max(height_step, height)

	# Gradual transition from campsite - use stepped transition
	if distance_from_center < flatten_radius + flatten_falloff:
		var t: float = (distance_from_center - flatten_radius) / flatten_falloff
		t = clamp(t, 0.0, 1.0)
		# Quantize the transition factor too for blocky edges
		t = floor(t * 4.0) / 4.0
		height *= t

	return height


func _create_terrain_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.45, 0.62, 0.35)  # Brighter grass green
	material.roughness = 0.9
	material.metallic = 0.0
	# Disable backface culling
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _create_collision(_mesh: Mesh) -> void:
	terrain_collision = StaticBody3D.new()

	# Use HeightMapShape3D for terrain collision
	var collision_shape: CollisionShape3D = CollisionShape3D.new()
	var heightmap: HeightMapShape3D = HeightMapShape3D.new()

	# Create height data array - sample at 1 unit intervals for accurate collision
	var map_width: int = terrain_size + 1
	var map_depth: int = terrain_size + 1
	var height_data: PackedFloat32Array = PackedFloat32Array()
	height_data.resize(map_width * map_depth)

	var half_size: float = terrain_size / 2.0

	for z in range(map_depth):
		for x in range(map_width):
			var world_x: float = x - half_size
			var world_z: float = z - half_size
			var height: float = _get_blocky_height(world_x, world_z)
			height_data[z * map_width + x] = height

	heightmap.map_width = map_width
	heightmap.map_depth = map_depth
	heightmap.map_data = height_data

	collision_shape.shape = heightmap
	collision_shape.position = Vector3(0, 0, 0)
	terrain_collision.add_child(collision_shape)

	add_child(terrain_collision)


func get_height_at(x: float, z: float) -> float:
	return _get_blocky_height(x, z)


func _load_tree_scene() -> void:
	tree_scene = load("res://scenes/resources/tree_resource.tscn")
	if not tree_scene:
		push_warning("[TerrainGenerator] Failed to load tree scene")

	# Setup forest density noise (different from terrain noise)
	forest_noise = FastNoiseLite.new()
	forest_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	forest_noise.seed = randi()  # Different seed for variety
	forest_noise.frequency = 0.08  # Creates medium-sized patches
	forest_noise.fractal_octaves = 2


func _spawn_forest() -> void:
	if not tree_scene or not forest_noise:
		return

	# Find or create Resources container
	var resources_container: Node3D = get_parent().get_node_or_null("Resources")
	if not resources_container:
		resources_container = Node3D.new()
		resources_container.name = "Resources"
		get_parent().add_child(resources_container)

	var tree_index: int = 0

	# Iterate over a grid covering the forest area
	var grid_start: float = -tree_max_distance
	var grid_end: float = tree_max_distance

	var x: float = grid_start
	while x < grid_end:
		var z: float = grid_start
		while z < grid_end:
			# Check distance from campsite center
			var distance: float = Vector2(x, z).length()

			if distance >= tree_min_distance and distance <= tree_max_distance:
				# Get forest density at this location (0 to 1)
				var density_value: float = (forest_noise.get_noise_2d(x, z) + 1.0) * 0.5

				# Apply density curve - creates more contrast between thick and thin areas
				# Values below 0.3 = sparse, above 0.6 = dense
				var spawn_chance: float = 0.0
				if density_value > 0.35:
					# Scale density to spawn probability
					spawn_chance = tree_density * (density_value - 0.35) / 0.65 * 2.5

				# Reduce density at edges for natural fade
				var edge_factor: float = 1.0 - (distance - tree_min_distance) / (tree_max_distance - tree_min_distance)
				edge_factor = clamp(edge_factor * 1.5, 0.3, 1.0)
				spawn_chance *= edge_factor

				# Random check for this cell
				if randf() < spawn_chance:
					# Add jitter within the cell for natural placement
					var jitter_x: float = randf_range(-tree_grid_size * 0.4, tree_grid_size * 0.4)
					var jitter_z: float = randf_range(-tree_grid_size * 0.4, tree_grid_size * 0.4)
					var tree_x: float = x + jitter_x
					var tree_z: float = z + jitter_z

					# Get terrain height
					var tree_y: float = _get_blocky_height(tree_x, tree_z)

					# Spawn tree
					var tree: Node3D = tree_scene.instantiate()
					tree.name = "Tree_Gen_%d" % tree_index
					tree.position = Vector3(tree_x, tree_y, tree_z)

					# Random Y rotation
					tree.rotation.y = randf() * TAU

					# Scale variation (0.7 to 1.3) - more variety
					var scale_factor: float = randf_range(0.7, 1.3)
					tree.scale = Vector3(scale_factor, scale_factor, scale_factor)

					resources_container.add_child(tree)
					spawned_trees.append(tree)
					tree_index += 1

			z += tree_grid_size
		x += tree_grid_size

	print("[TerrainGenerator] Spawned %d trees with natural clustering" % spawned_trees.size())
