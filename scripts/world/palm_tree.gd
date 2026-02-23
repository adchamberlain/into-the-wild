extends Node3D
class_name PalmTree
## A procedural palm tree built from BoxMesh primitives.

static var shared_trunk_material: StandardMaterial3D
static var shared_frond_material: StandardMaterial3D
static var shared_frond_dark_material: StandardMaterial3D

var tree_height: float = 6.0


func _init() -> void:
	_ensure_shared_materials()


static func _ensure_shared_materials() -> void:
	if shared_trunk_material != null:
		return
	shared_trunk_material = StandardMaterial3D.new()
	shared_trunk_material.albedo_color = Color(0.55, 0.40, 0.25)
	shared_frond_material = StandardMaterial3D.new()
	shared_frond_material.albedo_color = Color(0.25, 0.55, 0.20)
	shared_frond_dark_material = StandardMaterial3D.new()
	shared_frond_dark_material.albedo_color = Color(0.18, 0.42, 0.15)


func build(rng: RandomNumberGenerator) -> void:
	tree_height = rng.randf_range(5.0, 8.0)

	# Trunk - slightly curved using 3-4 stacked segments
	var segments: int = 4
	var segment_height: float = tree_height / segments
	var sway_x: float = rng.randf_range(-0.3, 0.3)
	var sway_z: float = rng.randf_range(-0.3, 0.3)

	for i: int in range(segments):
		var trunk_seg: MeshInstance3D = MeshInstance3D.new()
		var seg_box: BoxMesh = BoxMesh.new()
		var width: float = lerpf(0.35, 0.20, float(i) / segments)
		seg_box.size = Vector3(width, segment_height, width)
		seg_box.material = shared_trunk_material
		trunk_seg.mesh = seg_box
		trunk_seg.position = Vector3(
			sway_x * float(i) / segments,
			segment_height * 0.5 + segment_height * i,
			sway_z * float(i) / segments
		)
		add_child(trunk_seg)

	# Trunk ring details (darker bands)
	var ring_mat: StandardMaterial3D = StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.42, 0.30, 0.18)
	for i: int in range(3):
		var ring: MeshInstance3D = MeshInstance3D.new()
		var ring_box: BoxMesh = BoxMesh.new()
		ring_box.size = Vector3(0.38, 0.06, 0.38)
		ring_box.material = ring_mat
		ring.mesh = ring_box
		ring.position.y = tree_height * 0.3 + i * tree_height * 0.25
		add_child(ring)

	# Crown position (top of trunk with sway offset)
	var crown_pos: Vector3 = Vector3(sway_x, tree_height, sway_z)

	# Fronds - 6 drooping leaf clusters radiating outward
	var frond_count: int = 6
	for i: int in range(frond_count):
		var angle: float = TAU * i / frond_count + rng.randf_range(-0.2, 0.2)
		var frond_len: float = rng.randf_range(2.0, 3.0)

		# Main frond leaf
		var frond: MeshInstance3D = MeshInstance3D.new()
		var frond_box: BoxMesh = BoxMesh.new()
		frond_box.size = Vector3(0.5, 0.05, frond_len)
		frond_box.material = shared_frond_material if i % 2 == 0 else shared_frond_dark_material
		frond.mesh = frond_box
		frond.position = crown_pos + Vector3(cos(angle) * frond_len * 0.4, -0.3, sin(angle) * frond_len * 0.4)
		frond.rotation.y = angle
		frond.rotation.x = deg_to_rad(25.0)  # Droop down
		add_child(frond)

	# Coconut cluster (2-3 small brown spheres near crown)
	var coconut_mat: StandardMaterial3D = StandardMaterial3D.new()
	coconut_mat.albedo_color = Color(0.45, 0.30, 0.15)
	var coconut_count: int = rng.randi_range(2, 3)
	for i: int in range(coconut_count):
		var coconut: MeshInstance3D = MeshInstance3D.new()
		var coconut_box: BoxMesh = BoxMesh.new()
		coconut_box.size = Vector3(0.18, 0.18, 0.18)
		coconut_box.material = coconut_mat
		coconut.mesh = coconut_box
		var c_angle: float = TAU * i / coconut_count
		coconut.position = crown_pos + Vector3(cos(c_angle) * 0.2, -0.4, sin(c_angle) * 0.2)
		add_child(coconut)
