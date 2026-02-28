extends AmbientAnimalBase
class_name AmbientLizard
## Ambient desert lizard that darts around and flees quickly when player approaches.
## Non-huntable — purely decorative desert wildlife.

# Lizard-specific settings
var dart_pause_min: float = 0.5  # Short pauses between darting movements
var dart_pause_max: float = 2.0

# Body parts for animation
var body_mesh: MeshInstance3D
var tail_mesh: MeshInstance3D

# Color variation (sandy brown to olive green)
var base_hue: float = 0.12
var body_color: Color
var belly_color: Color
var dark_color: Color
var eye_color: Color = Color(0.05, 0.05, 0.05)


func _ready() -> void:
	# Lizard-specific configuration - fast and darting
	flee_distance = 6.0
	awareness_distance = 10.0
	move_speed = 3.75
	flee_speed = 6.75

	super._ready()


func _build_mesh() -> void:
	# Non-huntable: empty loot table
	loot_table = {}

	# Randomize color using HSV: hue 0.08 (sandy brown) to 0.18 (olive green)
	base_hue = rng.randf_range(0.08, 0.18)
	var sat: float = rng.randf_range(0.35, 0.55)
	var val: float = rng.randf_range(0.45, 0.60)
	body_color = Color.from_hsv(base_hue, sat, val)
	belly_color = Color.from_hsv(base_hue, sat * 0.5, val + 0.15)
	dark_color = Color.from_hsv(base_hue, sat + 0.1, val - 0.1)

	# Materials
	var body_mat: StandardMaterial3D = StandardMaterial3D.new()
	body_mat.albedo_color = body_color

	var belly_mat: StandardMaterial3D = StandardMaterial3D.new()
	belly_mat.albedo_color = belly_color

	var dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	dark_mat.albedo_color = dark_color

	var eye_mat: StandardMaterial3D = StandardMaterial3D.new()
	eye_mat.albedo_color = eye_color

	var eye_shine_mat: StandardMaterial3D = StandardMaterial3D.new()
	eye_shine_mat.albedo_color = Color(0.85, 0.80, 0.65)

	# Body - flat elongated shape
	body_mesh = MeshInstance3D.new()
	var body_box: BoxMesh = BoxMesh.new()
	body_box.size = Vector3(0.12, 0.06, 0.30)
	body_mesh.mesh = body_box
	body_mesh.position = Vector3(0, 0.04, 0)
	body_mesh.material_override = body_mat
	mesh_container.add_child(body_mesh)

	# Belly (lighter underside)
	var belly: MeshInstance3D = MeshInstance3D.new()
	var belly_box: BoxMesh = BoxMesh.new()
	belly_box.size = Vector3(0.10, 0.02, 0.26)
	belly.mesh = belly_box
	belly.position = Vector3(0, 0.015, 0)
	belly.material_override = belly_mat
	mesh_container.add_child(belly)

	# Head (slightly wider than body, protruding forward)
	var head: MeshInstance3D = MeshInstance3D.new()
	var head_box: BoxMesh = BoxMesh.new()
	head_box.size = Vector3(0.10, 0.05, 0.10)
	head.mesh = head_box
	head.position = Vector3(0, 0.045, 0.18)
	head.material_override = body_mat
	mesh_container.add_child(head)

	# Eyes (on sides of head, slightly bulging)
	for side: float in [-1.0, 1.0]:
		var eye_white: MeshInstance3D = MeshInstance3D.new()
		var ew_box: BoxMesh = BoxMesh.new()
		ew_box.size = Vector3(0.025, 0.025, 0.025)
		eye_white.mesh = ew_box
		eye_white.position = Vector3(side * 0.055, 0.06, 0.20)
		eye_white.material_override = eye_shine_mat
		mesh_container.add_child(eye_white)

		var pupil: MeshInstance3D = MeshInstance3D.new()
		var p_box: BoxMesh = BoxMesh.new()
		p_box.size = Vector3(0.015, 0.015, 0.015)
		pupil.mesh = p_box
		pupil.position = Vector3(side * 0.06, 0.06, 0.21)
		pupil.material_override = eye_mat
		mesh_container.add_child(pupil)

	# Legs - 4 splayed legs (front pair and rear pair)
	var leg_mat: StandardMaterial3D = StandardMaterial3D.new()
	leg_mat.albedo_color = Color(body_color.r - 0.05, body_color.g - 0.05, body_color.b - 0.03)

	# Front legs (splayed outward and forward)
	for side: float in [-1.0, 1.0]:
		var front_leg: MeshInstance3D = MeshInstance3D.new()
		var fl_box: BoxMesh = BoxMesh.new()
		fl_box.size = Vector3(0.10, 0.02, 0.03)
		front_leg.mesh = fl_box
		front_leg.position = Vector3(side * 0.08, 0.02, 0.10)
		front_leg.rotation.y = side * deg_to_rad(25)
		front_leg.material_override = leg_mat
		mesh_container.add_child(front_leg)

	# Rear legs (splayed outward and backward)
	for side: float in [-1.0, 1.0]:
		var rear_leg: MeshInstance3D = MeshInstance3D.new()
		var rl_box: BoxMesh = BoxMesh.new()
		rl_box.size = Vector3(0.10, 0.02, 0.03)
		rear_leg.mesh = rl_box
		rear_leg.position = Vector3(side * 0.08, 0.02, -0.10)
		rear_leg.rotation.y = side * deg_to_rad(-25)
		rear_leg.material_override = leg_mat
		mesh_container.add_child(rear_leg)

	# Tail - long tapered section
	tail_mesh = MeshInstance3D.new()
	var tail_box: BoxMesh = BoxMesh.new()
	tail_box.size = Vector3(0.06, 0.04, 0.22)
	tail_mesh.mesh = tail_box
	tail_mesh.position = Vector3(0, 0.035, -0.24)
	tail_mesh.material_override = dark_mat
	mesh_container.add_child(tail_mesh)

	# Tail tip (thinner end)
	var tail_tip: MeshInstance3D = MeshInstance3D.new()
	var tt_box: BoxMesh = BoxMesh.new()
	tt_box.size = Vector3(0.03, 0.02, 0.12)
	tail_tip.mesh = tt_box
	tail_tip.position = Vector3(0, 0.025, -0.40)
	tail_tip.material_override = dark_mat
	mesh_container.add_child(tail_tip)


## Non-huntable: override take_hit to do nothing.
func take_hit(_damage: float) -> void:
	return


func _on_enter_idle() -> void:
	# Short pauses between darting movements
	idle_duration = rng.randf_range(dart_pause_min, dart_pause_max)
	state_timer = idle_duration


func _on_enter_moving() -> void:
	# Short, quick darts
	move_duration = rng.randf_range(0.3, 0.8)
	state_timer = move_duration


func _get_flee_duration() -> float:
	return 1.5  # Quick burst flee
