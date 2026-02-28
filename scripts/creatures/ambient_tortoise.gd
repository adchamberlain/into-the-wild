extends AmbientAnimalBase
class_name AmbientTortoise
## Ambient desert tortoise that slowly plods around the landscape.
## Non-huntable — purely decorative desert wildlife.

# Body parts for animation
var shell_top: MeshInstance3D

# Colors
var shell_color: Color = Color(0.42, 0.38, 0.28)  # Brown-olive shell
var shell_dark: Color = Color(0.30, 0.27, 0.20)  # Darker shell segments
var skin_color: Color = Color(0.55, 0.48, 0.35)  # Tan skin
var eye_color: Color = Color(0.08, 0.06, 0.05)


func _ready() -> void:
	# Tortoise-specific configuration - very slow
	flee_distance = 4.0
	awareness_distance = 8.0
	move_speed = 0.25
	flee_speed = 0.5

	super._ready()


func _build_mesh() -> void:
	# Non-huntable: empty loot table
	loot_table = {}

	# Materials
	var shell_mat: StandardMaterial3D = StandardMaterial3D.new()
	shell_mat.albedo_color = shell_color

	var shell_dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	shell_dark_mat.albedo_color = shell_dark

	var skin_mat: StandardMaterial3D = StandardMaterial3D.new()
	skin_mat.albedo_color = skin_color

	var eye_mat: StandardMaterial3D = StandardMaterial3D.new()
	eye_mat.albedo_color = eye_color

	var eye_shine_mat: StandardMaterial3D = StandardMaterial3D.new()
	eye_shine_mat.albedo_color = Color(0.80, 0.75, 0.60)

	# Shell - dome shape from 4 layered boxes (decreasing size, stacked)
	# Layer 1 (bottom/widest)
	var shell_l1: MeshInstance3D = MeshInstance3D.new()
	var s1_box: BoxMesh = BoxMesh.new()
	s1_box.size = Vector3(0.32, 0.06, 0.38)
	shell_l1.mesh = s1_box
	shell_l1.position = Vector3(0, 0.10, 0)
	shell_l1.material_override = shell_mat
	mesh_container.add_child(shell_l1)

	# Layer 2
	var shell_l2: MeshInstance3D = MeshInstance3D.new()
	var s2_box: BoxMesh = BoxMesh.new()
	s2_box.size = Vector3(0.28, 0.06, 0.34)
	shell_l2.mesh = s2_box
	shell_l2.position = Vector3(0, 0.16, 0)
	shell_l2.material_override = shell_mat
	mesh_container.add_child(shell_l2)

	# Layer 3
	var shell_l3: MeshInstance3D = MeshInstance3D.new()
	var s3_box: BoxMesh = BoxMesh.new()
	s3_box.size = Vector3(0.22, 0.05, 0.28)
	shell_l3.mesh = s3_box
	shell_l3.position = Vector3(0, 0.21, 0)
	shell_l3.material_override = shell_mat
	mesh_container.add_child(shell_l3)

	# Layer 4 (top/smallest)
	shell_top = MeshInstance3D.new()
	var s4_box: BoxMesh = BoxMesh.new()
	s4_box.size = Vector3(0.16, 0.04, 0.20)
	shell_top.mesh = s4_box
	shell_top.position = Vector3(0, 0.25, 0)
	shell_top.material_override = shell_mat
	mesh_container.add_child(shell_top)

	# Shell pattern - 3 darker segments across the shell top
	for i: int in range(3):
		var segment: MeshInstance3D = MeshInstance3D.new()
		var seg_box: BoxMesh = BoxMesh.new()
		seg_box.size = Vector3(0.20, 0.015, 0.08)
		segment.mesh = seg_box
		var z_offset: float = -0.10 + i * 0.10
		segment.position = Vector3(0, 0.275, z_offset)
		segment.material_override = shell_dark_mat
		mesh_container.add_child(segment)

	# Underbelly (flat bottom plate)
	var underbelly: MeshInstance3D = MeshInstance3D.new()
	var ub_box: BoxMesh = BoxMesh.new()
	ub_box.size = Vector3(0.28, 0.03, 0.34)
	underbelly.mesh = ub_box
	underbelly.position = Vector3(0, 0.065, 0)
	var ub_mat: StandardMaterial3D = StandardMaterial3D.new()
	ub_mat.albedo_color = Color(0.50, 0.45, 0.32)  # Lighter than shell
	underbelly.material_override = ub_mat
	mesh_container.add_child(underbelly)

	# Head (protruding from front of shell on a slight neck)
	var neck: MeshInstance3D = MeshInstance3D.new()
	var neck_box: BoxMesh = BoxMesh.new()
	neck_box.size = Vector3(0.08, 0.07, 0.08)
	neck.mesh = neck_box
	neck.position = Vector3(0, 0.10, 0.20)
	neck.material_override = skin_mat
	mesh_container.add_child(neck)

	var head: MeshInstance3D = MeshInstance3D.new()
	var head_box: BoxMesh = BoxMesh.new()
	head_box.size = Vector3(0.10, 0.08, 0.10)
	head.mesh = head_box
	head.position = Vector3(0, 0.12, 0.26)
	head.material_override = skin_mat
	mesh_container.add_child(head)

	# Eyes (small, on sides of head)
	for side: float in [-1.0, 1.0]:
		var eye_white: MeshInstance3D = MeshInstance3D.new()
		var ew_box: BoxMesh = BoxMesh.new()
		ew_box.size = Vector3(0.02, 0.02, 0.02)
		eye_white.mesh = ew_box
		eye_white.position = Vector3(side * 0.05, 0.14, 0.29)
		eye_white.material_override = eye_shine_mat
		mesh_container.add_child(eye_white)

		var pupil: MeshInstance3D = MeshInstance3D.new()
		var p_box: BoxMesh = BoxMesh.new()
		p_box.size = Vector3(0.012, 0.012, 0.012)
		pupil.mesh = p_box
		pupil.position = Vector3(side * 0.054, 0.14, 0.295)
		pupil.material_override = eye_mat
		mesh_container.add_child(pupil)

	# Legs - 4 stubby legs poking out from under the shell
	var leg_mat: StandardMaterial3D = StandardMaterial3D.new()
	leg_mat.albedo_color = Color(skin_color.r - 0.05, skin_color.g - 0.05, skin_color.b - 0.03)

	# Front left leg
	var fl_leg: MeshInstance3D = MeshInstance3D.new()
	var fl_box: BoxMesh = BoxMesh.new()
	fl_box.size = Vector3(0.06, 0.07, 0.06)
	fl_leg.mesh = fl_box
	fl_leg.position = Vector3(-0.14, 0.045, 0.12)
	fl_leg.material_override = leg_mat
	mesh_container.add_child(fl_leg)

	# Front right leg
	var fr_leg: MeshInstance3D = MeshInstance3D.new()
	fr_leg.mesh = fl_box
	fr_leg.position = Vector3(0.14, 0.045, 0.12)
	fr_leg.material_override = leg_mat
	mesh_container.add_child(fr_leg)

	# Rear left leg
	var rl_leg: MeshInstance3D = MeshInstance3D.new()
	rl_leg.mesh = fl_box
	rl_leg.position = Vector3(-0.14, 0.045, -0.12)
	rl_leg.material_override = leg_mat
	mesh_container.add_child(rl_leg)

	# Rear right leg
	var rr_leg: MeshInstance3D = MeshInstance3D.new()
	rr_leg.mesh = fl_box
	rr_leg.position = Vector3(0.14, 0.045, -0.12)
	rr_leg.material_override = leg_mat
	mesh_container.add_child(rr_leg)

	# Short tail (poking out back of shell)
	var tail: MeshInstance3D = MeshInstance3D.new()
	var tail_box: BoxMesh = BoxMesh.new()
	tail_box.size = Vector3(0.04, 0.03, 0.06)
	tail.mesh = tail_box
	tail.position = Vector3(0, 0.08, -0.21)
	tail.material_override = skin_mat
	mesh_container.add_child(tail)


## Non-huntable: override take_hit to do nothing.
func take_hit(_damage: float) -> void:
	return


func _on_enter_idle() -> void:
	# Tortoises rest for a long time
	idle_duration = rng.randf_range(5.0, 15.0)
	state_timer = idle_duration


func _on_enter_moving() -> void:
	# Slow, deliberate movements
	move_duration = rng.randf_range(3.0, 6.0)
	state_timer = move_duration


func _get_flee_duration() -> float:
	return 3.0  # Slow retreat
