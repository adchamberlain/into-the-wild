extends AmbientAnimalBase
class_name AmbientRabbit
## Ambient rabbit that hops around and flees when player approaches.

# Rabbit-specific settings
var hop_height: float = 0.5  # Height of hop arc
var hop_distance: float = 1.2  # Distance per hop
var hop_duration: float = 0.3  # Time per hop
var hops_per_move: int = 3  # Normal movement hops
var hops_when_fleeing: int = 8  # Flee hops

# Hop state
var is_hopping: bool = false
var hop_timer: float = 0.0
var hop_start_pos: Vector3 = Vector3.ZERO
var hop_end_pos: Vector3 = Vector3.ZERO
var hop_count: int = 0
var target_hop_count: int = 3

# Body parts for animation
var body_mesh: MeshInstance3D
var ear_left: MeshInstance3D
var ear_right: MeshInstance3D
var tail_mesh: MeshInstance3D

# Colors
var body_color: Color = Color(0.55, 0.45, 0.38)  # Brown-grey
var ear_inner_color: Color = Color(0.75, 0.60, 0.55)  # Pinkish inner ear


func _ready() -> void:
	# Rabbit-specific configuration
	flee_distance = 8.0
	awareness_distance = 12.0
	move_speed = 4.0
	flee_speed = 7.0

	super._ready()


func _build_mesh() -> void:
	# Body - slightly elongated box
	body_mesh = MeshInstance3D.new()
	var body_box: BoxMesh = BoxMesh.new()
	body_box.size = Vector3(0.3, 0.25, 0.45)
	body_mesh.mesh = body_box
	body_mesh.position = Vector3(0, 0.15, 0)

	var body_mat: StandardMaterial3D = StandardMaterial3D.new()
	body_mat.albedo_color = body_color
	body_mesh.material_override = body_mat
	mesh_container.add_child(body_mesh)

	# Head - smaller box attached to front
	var head_mesh: MeshInstance3D = MeshInstance3D.new()
	var head_box: BoxMesh = BoxMesh.new()
	head_box.size = Vector3(0.22, 0.2, 0.22)
	head_mesh.mesh = head_box
	head_mesh.position = Vector3(0, 0.22, 0.25)

	var head_mat: StandardMaterial3D = StandardMaterial3D.new()
	head_mat.albedo_color = body_color
	head_mesh.material_override = head_mat
	mesh_container.add_child(head_mesh)

	# Left ear
	ear_left = MeshInstance3D.new()
	var ear_box: BoxMesh = BoxMesh.new()
	ear_box.size = Vector3(0.06, 0.2, 0.04)
	ear_left.mesh = ear_box
	ear_left.position = Vector3(-0.06, 0.42, 0.25)
	ear_left.rotation.z = deg_to_rad(-10)

	var ear_mat: StandardMaterial3D = StandardMaterial3D.new()
	ear_mat.albedo_color = body_color
	ear_left.material_override = ear_mat
	mesh_container.add_child(ear_left)

	# Right ear
	ear_right = MeshInstance3D.new()
	ear_right.mesh = ear_box
	ear_right.position = Vector3(0.06, 0.42, 0.25)
	ear_right.rotation.z = deg_to_rad(10)
	ear_right.material_override = ear_mat
	mesh_container.add_child(ear_right)

	# Tail - small white puff
	tail_mesh = MeshInstance3D.new()
	var tail_box: BoxMesh = BoxMesh.new()
	tail_box.size = Vector3(0.12, 0.12, 0.1)
	tail_mesh.mesh = tail_box
	tail_mesh.position = Vector3(0, 0.18, -0.25)

	var tail_mat: StandardMaterial3D = StandardMaterial3D.new()
	tail_mat.albedo_color = Color(0.9, 0.88, 0.85)  # Off-white
	tail_mesh.material_override = tail_mat
	mesh_container.add_child(tail_mesh)


func _process(delta: float) -> void:
	super._process(delta)

	# Handle hop animation
	if is_hopping:
		_process_hop(delta)


func _process_hop(delta: float) -> void:
	hop_timer += delta
	var t: float = hop_timer / hop_duration

	if t >= 1.0:
		# Hop complete
		t = 1.0
		is_hopping = false
		global_position = hop_end_pos
		hop_count += 1

		# Play hop sound
		var sfx_manager: Node = get_node_or_null("/root/SFXManager")
		if sfx_manager and sfx_manager.has_method("play_sfx"):
			sfx_manager.play_sfx("rabbit_hop")

		# Start next hop if we have more
		if hop_count < target_hop_count:
			_start_single_hop()
		else:
			# Done hopping, reset body position
			if body_mesh:
				body_mesh.position.y = 0.15
	else:
		# Interpolate position with parabolic arc for Y
		var horizontal_pos: Vector3 = hop_start_pos.lerp(hop_end_pos, t)

		# Parabolic arc: y = 4h * t * (1-t) where h is max height
		var arc_height: float = 4.0 * hop_height * t * (1.0 - t)

		global_position = Vector3(horizontal_pos.x, hop_start_pos.y + arc_height, horizontal_pos.z)

		# Squash and stretch animation
		if body_mesh:
			var squash: float = 1.0 - 0.2 * sin(t * PI)
			body_mesh.scale = Vector3(1.0 + (1.0 - squash) * 0.3, squash, 1.0)


func _start_single_hop() -> void:
	is_hopping = true
	hop_timer = 0.0
	hop_start_pos = global_position

	# Calculate hop end position
	var hop_dir: Vector3 = move_direction.normalized()
	var target_pos: Vector3 = global_position + hop_dir * hop_distance

	# Sample terrain height at target
	if chunk_manager and chunk_manager.has_method("get_height_at"):
		var terrain_height: float = chunk_manager.get_height_at(target_pos.x, target_pos.z)
		# Avoid water
		if terrain_height < 0:
			move_direction = -move_direction
			hop_dir = move_direction.normalized()
			target_pos = global_position + hop_dir * hop_distance
			terrain_height = chunk_manager.get_height_at(target_pos.x, target_pos.z)
			if terrain_height < 0:
				terrain_height = 0
		target_pos.y = terrain_height

	hop_end_pos = target_pos

	# Face hop direction
	if hop_dir.length() > 0.1:
		var look_target: Vector3 = global_position + hop_dir
		mesh_container.look_at(look_target, Vector3.UP)


func _on_enter_moving() -> void:
	hop_count = 0
	target_hop_count = hops_per_move
	_start_single_hop()


func _on_enter_fleeing() -> void:
	hop_count = 0
	target_hop_count = hops_when_fleeing
	# Faster hops when fleeing
	hop_duration = 0.2
	_start_single_hop()


func _on_enter_idle() -> void:
	# Reset hop duration
	hop_duration = 0.3
	is_hopping = false

	# Reset body scale
	if body_mesh:
		body_mesh.scale = Vector3.ONE
		body_mesh.position.y = 0.15


func _get_flee_duration() -> float:
	# Flee duration is based on number of hops
	return hops_when_fleeing * hop_duration * 1.2


func _process_idle(_delta: float) -> void:
	# Only transition when timer expires AND not mid-hop
	if state_timer <= 0 and not is_hopping:
		_enter_state(State.MOVING)


func _process_moving(delta: float) -> void:
	# Don't use base movement - we hop instead
	if state_timer <= 0 and not is_hopping:
		_enter_state(State.IDLE)


func _process_fleeing(delta: float) -> void:
	# Don't use base movement - we hop instead
	if state_timer <= 0 and not is_hopping:
		# Check if still need to flee
		if player and global_position.distance_to(player.global_position) < flee_distance:
			_start_fleeing()
		else:
			_enter_state(State.IDLE)
