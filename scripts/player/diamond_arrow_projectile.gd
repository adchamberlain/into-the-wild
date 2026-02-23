extends RigidBody3D
class_name DiamondArrowProjectile
## A diamond-tipped arrow projectile that deals damage like a regular arrow
## but persists after landing and can be picked up by the player.

const MAX_FLIGHT_TIME: float = 5.0
const ARROW_DAMAGE: float = 100.0

var flight_timer: float = 0.0
var is_stuck: bool = false
var has_hit: bool = false
var is_pickable: bool = false


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
	area_box.size = Vector3(0.15, 0.15, 0.6)
	area_shape.shape = area_box
	hit_area.add_child(area_shape)

	hit_area.body_entered.connect(_on_area_body_entered)
	add_child(hit_area)


func _physics_process(delta: float) -> void:
	if is_stuck:
		return

	flight_timer += delta
	if flight_timer >= MAX_FLIGHT_TIME:
		# Flight time expired - become pickable at current position
		_become_pickable()
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
		# Become pickable at the hit position instead of being destroyed
		_become_pickable()


func _stick_in_place() -> void:
	has_hit = true
	freeze = true
	SFXManager.play_sfx("arrow_hit")
	_become_pickable()


## Convert the arrow from a projectile into a persistent pickable item.
func _become_pickable() -> void:
	if is_pickable:
		return
	is_pickable = true
	is_stuck = true
	freeze = true

	# Stop physics interactions
	collision_layer = 0
	collision_mask = 0

	# Remove the animal-detection HitArea so it doesn't re-trigger
	var hit_area: Node = get_node_or_null("HitArea")
	if hit_area:
		hit_area.queue_free()

	# Add to interactable group so the player raycast can detect us
	add_to_group("interactable")
	add_to_group("resource_node")

	# Create a pickup collision shape on layer 1 so the interaction raycast hits us
	# The interaction ray collides with layer 1 (terrain/structures)
	collision_layer = 1
	collision_mask = 0

	# Add a larger collision shape for easier pickup detection
	var pickup_col: CollisionShape3D = CollisionShape3D.new()
	pickup_col.name = "PickupShape"
	var pickup_box: BoxShape3D = BoxShape3D.new()
	pickup_box.size = Vector3(0.4, 0.4, 0.6)
	pickup_col.shape = pickup_box
	add_child(pickup_col)


func get_interaction_text() -> String:
	if is_pickable:
		return "Pick up diamond arrow"
	return ""


func interact(player_node: Node) -> bool:
	if not is_pickable:
		return false
	var inv: Node = player_node.get_node_or_null("Inventory")
	if not inv:
		return false

	inv.add_item("diamond_arrows", 1)

	var hud: Node = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_notification"):
		hud.show_notification("Recovered diamond arrow", Color(0.6, 0.8, 1.0, 1))

	SFXManager.play_sfx("pickup")
	queue_free()
	return true


func _build_mesh() -> void:
	# Shaft - slightly lighter wood than regular arrow
	var shaft_mesh: MeshInstance3D = MeshInstance3D.new()
	var shaft_box: BoxMesh = BoxMesh.new()
	shaft_box.size = Vector3(0.03, 0.03, 0.5)
	var shaft_mat: StandardMaterial3D = StandardMaterial3D.new()
	shaft_mat.albedo_color = Color(0.50, 0.35, 0.18)
	shaft_box.material = shaft_mat
	shaft_mesh.mesh = shaft_box
	add_child(shaft_mesh)

	# Arrowhead - blue-tinted diamond with emission glow
	var head_mesh: MeshInstance3D = MeshInstance3D.new()
	var head_box: BoxMesh = BoxMesh.new()
	head_box.size = Vector3(0.06, 0.06, 0.08)
	var head_mat: StandardMaterial3D = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.6, 0.8, 1.0)
	head_mat.emission_enabled = true
	head_mat.emission = Color(0.3, 0.5, 0.8)
	head_mat.emission_energy_multiplier = 0.4
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
