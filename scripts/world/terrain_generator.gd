extends Node3D
## Generates a simple terrain with procedural hills using noise.

@export var terrain_size: int = 100
@export var terrain_resolution: int = 2  # Vertices per unit
@export var height_scale: float = 8.0
@export var noise_scale: float = 0.05

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
	noise.fractal_octaves = 4
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

	# Disable terrain collision - using simple floor instead
	# _create_collision(mesh)


func _add_vertex(st: SurfaceTool, vertices: Array[Vector3], uvs: Array[Vector2], index: int) -> void:
	st.set_uv(uvs[index])
	st.add_vertex(vertices[index])


func _get_height(x: float, z: float) -> float:
	# Base terrain height from noise
	var height: float = noise.get_noise_2d(x, z) * height_scale

	# Flatten area around spawn point (campsite)
	var distance_from_center: float = Vector2(x, z).length()
	var flatten_radius: float = 15.0
	var flatten_falloff: float = 10.0

	if distance_from_center < flatten_radius:
		height *= 0.1
	elif distance_from_center < flatten_radius + flatten_falloff:
		var t: float = (distance_from_center - flatten_radius) / flatten_falloff
		height *= lerpf(0.1, 1.0, t)

	return height


func _create_terrain_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.5, 0.2)  # Grass green
	material.roughness = 0.9
	return material


func _create_collision(mesh: Mesh) -> void:
	terrain_collision = StaticBody3D.new()
	var collision_shape: CollisionShape3D = CollisionShape3D.new()
	collision_shape.shape = mesh.create_trimesh_shape()
	terrain_collision.add_child(collision_shape)
	add_child(terrain_collision)


func get_height_at(x: float, z: float) -> float:
	return _get_height(x, z)
