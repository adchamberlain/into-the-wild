extends Node3D
class_name DesertOasis
## A desert oasis with a swimmable pool, palm trees, and underwater gem deposits.
## Found in the desert ring biome at ~200 units from spawn.

# Oasis properties
var oasis_radius: float = 6.0
var oasis_depth: float = 4.0
var gem_type: String = "diamond"
var gem_count: int = 3


func build(rng: RandomNumberGenerator) -> void:
	# Water visual: blue-tinted disc at surface level
	_create_water_visual()

	# Water Area3D for swimming detection
	_create_water_area()

	# 4-6 palm trees around the pool
	var palm_count: int = rng.randi_range(4, 6)
	for i: int in range(palm_count):
		var angle: float = TAU * i / palm_count + rng.randf_range(-0.3, 0.3)
		var dist: float = oasis_radius + rng.randf_range(1.0, 3.0)
		var palm: PalmTree = PalmTree.new()
		palm.position = Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		palm.rotation.y = rng.randf() * TAU
		add_child(palm)
		palm.build(rng)

	# Gem deposits on pool floor
	for i: int in range(gem_count):
		var gem: GemNode = GemNode.new()
		gem.gem_type = gem_type
		# Spread gems across the pool floor
		var gem_angle: float = TAU * i / gem_count + rng.randf_range(-0.3, 0.3)
		var gem_dist: float = rng.randf_range(0.5, oasis_radius * 0.6)
		gem.position = Vector3(
			cos(gem_angle) * gem_dist,
			-oasis_depth + 0.1,  # Sit on pool floor
			sin(gem_angle) * gem_dist
		)
		gem.rotation.y = rng.randf() * TAU
		add_child(gem)

	print("[DesertOasis] Built oasis with %d palms, %d %s gems at (%.0f, %.0f)" % [
		palm_count, gem_count, gem_type, global_position.x, global_position.z
	])


func _create_water_visual() -> void:
	# Main water surface - large blue-tinted disc
	var water_mesh: MeshInstance3D = MeshInstance3D.new()
	water_mesh.name = "WaterSurface"
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = Vector3(oasis_radius * 2.0, 0.15, oasis_radius * 2.0)
	water_mesh.mesh = box_mesh

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.15, 0.45, 0.65, 0.7)
	mat.roughness = 0.05
	mat.metallic = 0.1
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	water_mesh.material_override = mat
	water_mesh.position = Vector3(0, 0, 0)
	add_child(water_mesh)

	# Deeper water center (darker patch beneath surface)
	var deep_mesh: MeshInstance3D = MeshInstance3D.new()
	deep_mesh.name = "DeepWater"
	var deep_box: BoxMesh = BoxMesh.new()
	deep_box.size = Vector3(oasis_radius * 1.2, 0.12, oasis_radius * 1.2)
	deep_mesh.mesh = deep_box

	var deep_mat: StandardMaterial3D = StandardMaterial3D.new()
	deep_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	deep_mat.albedo_color = Color(0.08, 0.30, 0.45, 0.5)
	deep_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	deep_mesh.material_override = deep_mat
	deep_mesh.position = Vector3(0, -0.02, 0)
	add_child(deep_mesh)


func _create_water_area() -> void:
	# Water area for swimming detection - matches fishing_spot.gd pattern
	var water_area: Area3D = Area3D.new()
	water_area.name = "WaterArea"

	var area_shape: CollisionShape3D = CollisionShape3D.new()
	var area_box: BoxShape3D = BoxShape3D.new()
	# Match the water volume, slightly larger to catch player entering
	area_box.size = Vector3(oasis_radius * 2.0 + 1.0, oasis_depth + 1.0, oasis_radius * 2.0 + 1.0)
	area_shape.shape = area_box
	# Position: surface at y=0, extends down to pool floor
	area_shape.position = Vector3(0, -oasis_depth / 2.0, 0)
	water_area.add_child(area_shape)

	# Connect signals for swimming detection
	water_area.body_entered.connect(_on_water_body_entered)
	water_area.body_exited.connect(_on_water_body_exited)

	add_child(water_area)


func _on_water_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if body.has_method("set_in_water"):
			body.set_in_water(true)
		print("[DesertOasis] Player entered water")


func _on_water_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		if body.has_method("set_in_water"):
			body.set_in_water(false)
		print("[DesertOasis] Player exited water")
