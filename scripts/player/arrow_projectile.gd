extends RigidBody3D
class_name ArrowProjectile
## A physics-based arrow projectile that damages animals on contact
## and sticks into terrain.

const MAX_FLIGHT_TIME: float = 4.0
const STUCK_DURATION: float = 1.5
const ARROW_DAMAGE: float = 100.0

var flight_timer: float = 0.0
var is_stuck: bool = false
var stuck_timer: float = 0.0
var has_hit: bool = false
var enchanted: bool = false  # Fired from enchanted bow — larger hit radius


func _ready() -> void:
	_build_mesh()

	# Arrow doesn't block anything, collides with terrain (layer 1)
	collision_layer = 0
	collision_mask = 1

	# Enable contact monitoring for terrain hits
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_body_entered)

	# Physics collision shape
	var physics_shape: CollisionShape3D = CollisionShape3D.new()
	var physics_box: BoxShape3D = BoxShape3D.new()
	physics_box.size = Vector3(0.05, 0.05, 0.5)
	physics_shape.shape = physics_box
	add_child(physics_shape)

	# Area3D for animal detection
	var hit_area: Area3D = Area3D.new()
	hit_area.name = "HitArea"
	hit_area.collision_layer = 0
	hit_area.collision_mask = 2  # Layer 2 for animals

	var area_shape: CollisionShape3D = CollisionShape3D.new()
	var area_box: BoxShape3D = BoxShape3D.new()
	# Enchanted bow gives a much larger hit radius for easier targeting
	if enchanted:
		area_box.size = Vector3(1.2, 1.2, 1.0)
	else:
		area_box.size = Vector3(0.15, 0.15, 0.6)
	area_shape.shape = area_box
	hit_area.add_child(area_shape)

	hit_area.body_entered.connect(_on_area_body_entered)
	add_child(hit_area)


func _physics_process(delta: float) -> void:
	if is_stuck:
		stuck_timer += delta
		if stuck_timer >= STUCK_DURATION:
			queue_free()
		return

	flight_timer += delta
	if flight_timer >= MAX_FLIGHT_TIME:
		queue_free()
		return

	# Orient arrow along velocity, using alternate up vector when near-vertical
	var vel: Vector3 = linear_velocity
	if vel.length_squared() > 0.01:
		var vel_norm: Vector3 = vel.normalized()
		var up: Vector3 = Vector3.FORWARD if absf(vel_norm.dot(Vector3.UP)) > 0.9 else Vector3.UP
		look_at(global_position + vel, up)


func _on_body_entered(_body: Node) -> void:
	if has_hit:
		return
	_stick_in_place()


func _on_area_body_entered(body: Node) -> void:
	if has_hit:
		return
	# Check the body itself and its parent for take_hit
	var target: Node = null
	if body.has_method("take_hit"):
		target = body
	elif body.get_parent() and body.get_parent().has_method("take_hit"):
		target = body.get_parent()

	if target:
		has_hit = true
		target.take_hit(ARROW_DAMAGE)
		var sfx: Node = get_node_or_null("/root/SFXManager")
		if sfx and sfx.has_method("play_sfx"):
			sfx.play_sfx("arrow_hit")
		queue_free()


func _stick_in_place() -> void:
	is_stuck = true
	has_hit = true
	freeze = true
	SFXManager.play_sfx("arrow_hit")


func _build_mesh() -> void:
	# Shaft - brown wood
	var shaft_mesh: MeshInstance3D = MeshInstance3D.new()
	var shaft_box: BoxMesh = BoxMesh.new()
	shaft_box.size = Vector3(0.03, 0.03, 0.5)
	var shaft_mat: StandardMaterial3D = StandardMaterial3D.new()
	shaft_mat.albedo_color = Color(0.45, 0.3, 0.15)
	shaft_box.material = shaft_mat
	shaft_mesh.mesh = shaft_box
	add_child(shaft_mesh)

	# Arrowhead - dark metal
	var head_mesh: MeshInstance3D = MeshInstance3D.new()
	var head_box: BoxMesh = BoxMesh.new()
	head_box.size = Vector3(0.06, 0.06, 0.08)
	var head_mat: StandardMaterial3D = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.3, 0.3, 0.35)
	head_box.material = head_mat
	head_mesh.mesh = head_box
	head_mesh.position.z = -0.27
	head_mesh.rotation.z = deg_to_rad(45.0)
	add_child(head_mesh)

	# Tail fin 1 - feather
	var fin1_mesh: MeshInstance3D = MeshInstance3D.new()
	var fin1_box: BoxMesh = BoxMesh.new()
	fin1_box.size = Vector3(0.06, 0.005, 0.08)
	var fin_mat: StandardMaterial3D = StandardMaterial3D.new()
	fin_mat.albedo_color = Color(0.6, 0.55, 0.45)
	fin1_box.material = fin_mat
	fin1_mesh.mesh = fin1_box
	fin1_mesh.position.z = 0.22
	add_child(fin1_mesh)

	# Tail fin 2 - rotated 90 degrees on Z
	var fin2_mesh: MeshInstance3D = MeshInstance3D.new()
	var fin2_box: BoxMesh = BoxMesh.new()
	fin2_box.size = Vector3(0.06, 0.005, 0.08)
	fin2_box.material = fin_mat
	fin2_mesh.mesh = fin2_box
	fin2_mesh.position.z = 0.22
	fin2_mesh.rotation.z = deg_to_rad(90.0)
	add_child(fin2_mesh)
