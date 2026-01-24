extends Node3D
## Generates a blocky terrain with procedural hills using noise.

@export var terrain_size: int = 100
@export var terrain_resolution: int = 1  # Lower = more blocky (1 vertex per unit)
@export var height_scale: float = 6.0
@export var noise_scale: float = 0.03

var noise: FastNoiseLite
var terrain_mesh: MeshInstance3D
var terrain_collision: StaticBody3D


func _ready() -> void:
	_setup_noise()
	_generate_terrain()


func _setup_noise() -> void:
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = randi()
	noise.fractal_octaves = 3  # Fewer octaves for smoother, more blocky hills
	noise.frequency = noise_scale


func _generate_terrain() -> void:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_size: float = terrain_size / 2.0
	var step: float = 1.0 / terrain_resolution

	# Generate vertices
	var vertices: Array[Vector3] = []
	var uvs: Array[Vector2] = []

	for z in range(terrain_size * terrain_resolution + 1):
		for x in range(terrain_size * terrain_resolution + 1):
			var world_x: float = (x * step) - half_size
			var world_z: float = (z * step) - half_size
			var height: float = _get_height(world_x, world_z)

			vertices.append(Vector3(world_x, height, world_z))
			uvs.append(Vector2(x * step / terrain_size, z * step / terrain_size))

	# Generate triangles
	var width: int = terrain_size * terrain_resolution + 1

	for z in range(terrain_size * terrain_resolution):
		for x in range(terrain_size * terrain_resolution):
			var i: int = z * width + x

			# First triangle
			_add_vertex(surface_tool, vertices, uvs, i)
			_add_vertex(surface_tool, vertices, uvs, i + width)
			_add_vertex(surface_tool, vertices, uvs, i + 1)

			# Second triangle
			_add_vertex(surface_tool, vertices, uvs, i + 1)
			_add_vertex(surface_tool, vertices, uvs, i + width)
			_add_vertex(surface_tool, vertices, uvs, i + width + 1)

	surface_tool.generate_normals()

	# Create mesh
	var mesh: ArrayMesh = surface_tool.commit()

	terrain_mesh = MeshInstance3D.new()
	terrain_mesh.mesh = mesh
	terrain_mesh.material_override = _create_terrain_material()
	add_child(terrain_mesh)

	# Enable terrain collision - use the actual terrain mesh
	_create_collision(mesh)


func _add_vertex(st: SurfaceTool, vertices: Array[Vector3], uvs: Array[Vector2], index: int) -> void:
	st.set_uv(uvs[index])
	st.add_vertex(vertices[index])


func _get_height(x: float, z: float) -> float:
	# Flatten area around spawn point (campsite)
	var distance_from_center: float = Vector2(x, z).length()
	var flatten_radius: float = 12.0
	var flatten_falloff: float = 8.0

	if distance_from_center < flatten_radius:
		# Completely flat at y=0 in the campsite area
		return 0.0

	# Base terrain height from noise (only outside campsite)
	var raw_height: float = noise.get_noise_2d(x, z)

	# Convert noise (-1 to 1) to positive height (0 to height_scale)
	# This ensures terrain is always above y=0 for walkability
	var height: float = (raw_height + 1.0) * 0.5 * height_scale

	# Ensure minimum ground level for walkable valleys
	height = max(0.5, height)

	# Gradual slope transition from campsite to terrain
	if distance_from_center < flatten_radius + flatten_falloff:
		var t: float = (distance_from_center - flatten_radius) / flatten_falloff
		# Use smoothstep for gentler transition
		t = t * t * (3.0 - 2.0 * t)
		height *= t

	return height


func _create_terrain_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.5, 0.2)  # Grass green
	material.roughness = 0.9
	# Disable backface culling so terrain isn't see-through
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _create_collision(_mesh: Mesh) -> void:
	terrain_collision = StaticBody3D.new()

	# Use HeightMapShape3D for proper terrain collision
	var collision_shape: CollisionShape3D = CollisionShape3D.new()
	var heightmap: HeightMapShape3D = HeightMapShape3D.new()

	# Create height data array
	var map_width: int = terrain_size + 1
	var map_depth: int = terrain_size + 1
	var height_data: PackedFloat32Array = PackedFloat32Array()
	height_data.resize(map_width * map_depth)

	var half_size: float = terrain_size / 2.0

	for z in range(map_depth):
		for x in range(map_width):
			var world_x: float = x - half_size
			var world_z: float = z - half_size
			var height: float = _get_height(world_x, world_z)
			height_data[z * map_width + x] = height

	heightmap.map_width = map_width
	heightmap.map_depth = map_depth
	heightmap.map_data = height_data

	collision_shape.shape = heightmap
	# Center the heightmap collision to match the visual mesh
	collision_shape.position = Vector3(0, 0, 0)
	terrain_collision.add_child(collision_shape)

	add_child(terrain_collision)


func get_height_at(x: float, z: float) -> float:
	return _get_height(x, z)
