extends AmbientAnimalBase
class_name AmbientBird
## Ambient bird that perches, flies, and chirps. Flees when player approaches.

# Bird-specific sub-states
enum BirdState { PERCHED, FLYING, LANDING }
var bird_state: BirdState = BirdState.PERCHED

# Flight settings
var flight_height: float = 8.0  # Base flight altitude above terrain
var flight_speed: float = 5.0
var flee_flight_speed: float = 10.0
var landing_speed: float = 3.0

# Perch settings
var perch_height: float = 0.0  # Height above terrain when perched (can be on ground or in tree)
var chirp_interval_min: float = 12.0  # Longer intervals - many birds in world
var chirp_interval_max: float = 30.0
var chirp_timer: float = 0.0

# Wing animation
var wing_angle: float = 0.0
var wing_speed: float = 15.0  # Flaps per second
var is_wings_up: bool = false

# Flight state
var flight_target: Vector3 = Vector3.ZERO
var flight_timer: float = 0.0
var flight_duration: float = 5.0

# Body parts
var body_mesh: MeshInstance3D
var head_mesh: MeshInstance3D
var wing_left: MeshInstance3D
var wing_right: MeshInstance3D
var tail_mesh: MeshInstance3D
var beak_mesh: MeshInstance3D

# Colors
var body_color: Color = Color(0.45, 0.50, 0.58)  # Grey-blue
var wing_color: Color = Color(0.40, 0.45, 0.55)  # Slightly darker
var beak_color: Color = Color(0.75, 0.55, 0.30)  # Orange-brown


func _ready() -> void:
	# Bird-specific configuration
	flee_distance = 12.0
	awareness_distance = 18.0
	move_speed = 5.0
	flee_speed = 10.0

	super._ready()

	# Initialize chirp timer
	chirp_timer = rng.randf_range(chirp_interval_min, chirp_interval_max)

	# Decide initial perch height (ground or elevated)
	if rng.randf() < 0.3:
		# Perch on ground
		perch_height = 0.0
	else:
		# Perch elevated (simulating tree branch or rock)
		perch_height = rng.randf_range(2.0, 5.0)

	_update_perch_position()


func _build_mesh() -> void:
	# Materials
	var body_mat: StandardMaterial3D = StandardMaterial3D.new()
	body_mat.albedo_color = body_color

	var breast_mat: StandardMaterial3D = StandardMaterial3D.new()
	breast_mat.albedo_color = Color(0.60, 0.45, 0.38)  # Warm brownish breast

	var belly_mat: StandardMaterial3D = StandardMaterial3D.new()
	belly_mat.albedo_color = Color(0.72, 0.68, 0.62)  # Lighter belly

	var wing_mat: StandardMaterial3D = StandardMaterial3D.new()
	wing_mat.albedo_color = wing_color

	var wing_tip_mat: StandardMaterial3D = StandardMaterial3D.new()
	wing_tip_mat.albedo_color = Color(0.30, 0.35, 0.42)  # Darker wing tips

	var tail_mat: StandardMaterial3D = StandardMaterial3D.new()
	tail_mat.albedo_color = wing_color

	var beak_mat: StandardMaterial3D = StandardMaterial3D.new()
	beak_mat.albedo_color = beak_color

	var eye_mat: StandardMaterial3D = StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.05, 0.05, 0.05)

	var eye_ring_mat: StandardMaterial3D = StandardMaterial3D.new()
	eye_ring_mat.albedo_color = Color(0.9, 0.9, 0.85)

	# Body - elongated main shape
	body_mesh = MeshInstance3D.new()
	var body_box: BoxMesh = BoxMesh.new()
	body_box.size = Vector3(0.15, 0.12, 0.25)
	body_mesh.mesh = body_box
	body_mesh.position = Vector3(0, 0.08, 0)
	body_mesh.material_override = body_mat
	mesh_container.add_child(body_mesh)

	# Breast patch (warm color on front)
	var breast: MeshInstance3D = MeshInstance3D.new()
	var br_box: BoxMesh = BoxMesh.new()
	br_box.size = Vector3(0.12, 0.09, 0.10)
	breast.mesh = br_box
	breast.position = Vector3(0, 0.06, 0.08)
	breast.material_override = breast_mat
	mesh_container.add_child(breast)

	# Belly (lighter underside)
	var belly: MeshInstance3D = MeshInstance3D.new()
	var be_box: BoxMesh = BoxMesh.new()
	be_box.size = Vector3(0.12, 0.03, 0.18)
	belly.mesh = be_box
	belly.position = Vector3(0, 0.02, 0.02)
	belly.material_override = belly_mat
	mesh_container.add_child(belly)

	# Head
	head_mesh = MeshInstance3D.new()
	var head_box: BoxMesh = BoxMesh.new()
	head_box.size = Vector3(0.12, 0.11, 0.12)
	head_mesh.mesh = head_box
	head_mesh.position = Vector3(0, 0.12, 0.15)
	head_mesh.material_override = body_mat
	mesh_container.add_child(head_mesh)

	# Head cap (slightly darker crown)
	var crown: MeshInstance3D = MeshInstance3D.new()
	var cr_box: BoxMesh = BoxMesh.new()
	cr_box.size = Vector3(0.10, 0.03, 0.10)
	crown.mesh = cr_box
	crown.position = Vector3(0, 0.17, 0.15)
	crown.material_override = wing_mat
	mesh_container.add_child(crown)

	# Eyes (white ring + black pupil on each side)
	for side: float in [-1.0, 1.0]:
		var eye_white: MeshInstance3D = MeshInstance3D.new()
		var ew_box: BoxMesh = BoxMesh.new()
		ew_box.size = Vector3(0.025, 0.025, 0.025)
		eye_white.mesh = ew_box
		eye_white.position = Vector3(side * 0.062, 0.13, 0.19)
		eye_white.material_override = eye_ring_mat
		mesh_container.add_child(eye_white)

		var eye_pupil: MeshInstance3D = MeshInstance3D.new()
		var ep_box: BoxMesh = BoxMesh.new()
		ep_box.size = Vector3(0.015, 0.015, 0.015)
		eye_pupil.mesh = ep_box
		eye_pupil.position = Vector3(side * 0.065, 0.13, 0.20)
		eye_pupil.material_override = eye_mat
		mesh_container.add_child(eye_pupil)

	# Beak (two-tone: upper and lower mandible)
	beak_mesh = MeshInstance3D.new()
	var beak_box: BoxMesh = BoxMesh.new()
	beak_box.size = Vector3(0.04, 0.02, 0.08)
	beak_mesh.mesh = beak_box
	beak_mesh.position = Vector3(0, 0.11, 0.23)
	beak_mesh.material_override = beak_mat
	mesh_container.add_child(beak_mesh)

	# Lower mandible (slightly darker)
	var lower_beak: MeshInstance3D = MeshInstance3D.new()
	var lb_box: BoxMesh = BoxMesh.new()
	lb_box.size = Vector3(0.035, 0.015, 0.06)
	lower_beak.mesh = lb_box
	lower_beak.position = Vector3(0, 0.095, 0.22)
	var lb_mat: StandardMaterial3D = StandardMaterial3D.new()
	lb_mat.albedo_color = Color(0.65, 0.48, 0.25)
	lower_beak.material_override = lb_mat
	mesh_container.add_child(lower_beak)

	# Left wing (with feather layers)
	wing_left = MeshInstance3D.new()
	var wing_box: BoxMesh = BoxMesh.new()
	wing_box.size = Vector3(0.20, 0.02, 0.15)
	wing_left.mesh = wing_box
	wing_left.position = Vector3(-0.12, 0.10, 0)
	wing_left.material_override = wing_mat
	mesh_container.add_child(wing_left)

	# Left wing tip (darker)
	var lwt: MeshInstance3D = MeshInstance3D.new()
	var lwt_box: BoxMesh = BoxMesh.new()
	lwt_box.size = Vector3(0.06, 0.015, 0.12)
	lwt.mesh = lwt_box
	lwt.position = Vector3(-0.20, 0.10, -0.01)
	lwt.material_override = wing_tip_mat
	mesh_container.add_child(lwt)

	# Right wing
	wing_right = MeshInstance3D.new()
	wing_right.mesh = wing_box
	wing_right.position = Vector3(0.12, 0.10, 0)
	wing_right.material_override = wing_mat
	mesh_container.add_child(wing_right)

	# Right wing tip (darker)
	var rwt: MeshInstance3D = MeshInstance3D.new()
	rwt.mesh = lwt_box
	rwt.position = Vector3(0.20, 0.10, -0.01)
	rwt.material_override = wing_tip_mat
	mesh_container.add_child(rwt)

	# Wing bar (pale stripe across wing)
	var wing_bar_mat: StandardMaterial3D = StandardMaterial3D.new()
	wing_bar_mat.albedo_color = Color(0.58, 0.60, 0.62)
	for side: float in [-0.12, 0.12]:
		var bar: MeshInstance3D = MeshInstance3D.new()
		var bar_box: BoxMesh = BoxMesh.new()
		bar_box.size = Vector3(0.18, 0.022, 0.025)
		bar.mesh = bar_box
		bar.position = Vector3(side, 0.10, 0.03)
		bar.material_override = wing_bar_mat
		mesh_container.add_child(bar)

	# Tail - fan shape with feather detail
	tail_mesh = MeshInstance3D.new()
	var tail_box: BoxMesh = BoxMesh.new()
	tail_box.size = Vector3(0.10, 0.02, 0.12)
	tail_mesh.mesh = tail_box
	tail_mesh.position = Vector3(0, 0.06, -0.15)
	tail_mesh.material_override = tail_mat
	mesh_container.add_child(tail_mesh)

	# Tail tip (darker edge)
	var tail_tip: MeshInstance3D = MeshInstance3D.new()
	var tt_box: BoxMesh = BoxMesh.new()
	tt_box.size = Vector3(0.08, 0.015, 0.03)
	tail_tip.mesh = tt_box
	tail_tip.position = Vector3(0, 0.06, -0.20)
	tail_tip.material_override = wing_tip_mat
	mesh_container.add_child(tail_tip)

	# Feet (tiny legs when perched)
	var foot_mat: StandardMaterial3D = StandardMaterial3D.new()
	foot_mat.albedo_color = Color(0.55, 0.42, 0.30)
	for side: float in [-0.04, 0.04]:
		var leg: MeshInstance3D = MeshInstance3D.new()
		var leg_box: BoxMesh = BoxMesh.new()
		leg_box.size = Vector3(0.015, 0.05, 0.015)
		leg.mesh = leg_box
		leg.position = Vector3(side, -0.01, 0.02)
		leg.material_override = foot_mat
		mesh_container.add_child(leg)
		# Toes
		var toe: MeshInstance3D = MeshInstance3D.new()
		var toe_box: BoxMesh = BoxMesh.new()
		toe_box.size = Vector3(0.03, 0.01, 0.025)
		toe.mesh = toe_box
		toe.position = Vector3(side, -0.035, 0.02)
		toe.material_override = foot_mat
		mesh_container.add_child(toe)


func _process(delta: float) -> void:
	super._process(delta)

	# Skip bird-specific processing if too far (culled by base class)
	if is_too_far:
		return

	# Bird-specific state processing
	match bird_state:
		BirdState.PERCHED:
			_process_perched(delta)
		BirdState.FLYING:
			_process_flying(delta)
		BirdState.LANDING:
			_process_landing(delta)


func _process_perched(delta: float) -> void:
	# Wings folded
	_fold_wings()

	# Chirp timer
	chirp_timer -= delta
	if chirp_timer <= 0:
		_chirp()
		chirp_timer = rng.randf_range(chirp_interval_min, chirp_interval_max)


func _process_flying(delta: float) -> void:
	# Animate wings
	_flap_wings(delta)

	# Move toward target
	var direction: Vector3 = (flight_target - global_position).normalized()
	var current_speed: float = flee_flight_speed if current_state == State.FLEEING else flight_speed
	var movement: Vector3 = direction * current_speed * delta

	global_position += movement

	# Face flight direction (throttled for performance)
	if direction.length() > 0.1 and rotation_timer >= ROTATION_UPDATE_INTERVAL:
		rotation_timer = 0.0
		var look_target: Vector3 = global_position + direction
		mesh_container.look_at(look_target, Vector3.UP)
		# Tilt slightly in flight direction
		mesh_container.rotation.x = -0.2

	# Check if reached target or time expired
	flight_timer -= delta
	var distance_to_target: float = global_position.distance_to(flight_target)

	if distance_to_target < 1.0 or flight_timer <= 0:
		if current_state == State.FLEEING:
			# Keep fleeing until base state changes
			_pick_new_flight_target()
		else:
			# Start landing
			_start_landing()


func _process_landing(delta: float) -> void:
	# Slow wing flaps
	_flap_wings(delta * 0.5)

	# Descend to perch
	var terrain_height: float = _get_terrain_height()
	var target_y: float = terrain_height + perch_height

	var descent_speed: float = landing_speed
	var new_y: float = move_toward(global_position.y, target_y, descent_speed * delta)
	global_position.y = new_y

	# Straighten out
	mesh_container.rotation.x = move_toward(mesh_container.rotation.x, 0, delta * 2.0)

	# Check if landed
	if abs(global_position.y - target_y) < 0.1:
		global_position.y = target_y
		bird_state = BirdState.PERCHED
		_fold_wings()


func _flap_wings(delta: float) -> void:
	wing_angle += wing_speed * delta

	# Sinusoidal flapping
	var flap: float = sin(wing_angle * TAU) * 0.8

	if wing_left and wing_right:
		# Rotate wings around X axis for up/down flap
		wing_left.rotation.z = flap
		wing_right.rotation.z = -flap

		# Move wings up/down
		var y_offset: float = abs(flap) * 0.05
		wing_left.position.y = 0.10 + y_offset
		wing_right.position.y = 0.10 + y_offset

	# Track wing position for animation (sound removed - too frequent with many birds)
	if sin(wing_angle * TAU) > 0.9:
		is_wings_up = true
	elif sin(wing_angle * TAU) < 0:
		is_wings_up = false


func _fold_wings() -> void:
	if wing_left and wing_right:
		wing_left.rotation.z = 0.3  # Slightly tucked
		wing_right.rotation.z = -0.3
		wing_left.position.y = 0.10
		wing_right.position.y = 0.10


func _chirp() -> void:
	# Only chirp if player is nearby (sounds are 2D, not spatial)
	# Uses cached sfx_manager from base class for performance
	if player and global_position.distance_to(player.global_position) < 15.0:
		if sfx_manager and sfx_manager.has_method("play_sfx"):
			sfx_manager.play_sfx("bird_chirp")


func _start_flying() -> void:
	bird_state = BirdState.FLYING
	_pick_new_flight_target()


func _pick_new_flight_target() -> void:
	# Pick a random point in the air
	var angle: float = rng.randf() * TAU
	var distance: float = rng.randf_range(10.0, 25.0)
	var target_xz: Vector2 = Vector2(global_position.x, global_position.z) + Vector2(cos(angle), sin(angle)) * distance

	# Get terrain height at target
	var terrain_height: float = 0.0
	if chunk_manager and chunk_manager.has_method("get_height_at"):
		terrain_height = chunk_manager.get_height_at(target_xz.x, target_xz.y)
		if terrain_height < 0:
			terrain_height = 0

	var target_height: float = terrain_height + flight_height + rng.randf_range(-2.0, 2.0)

	flight_target = Vector3(target_xz.x, target_height, target_xz.y)
	flight_duration = rng.randf_range(3.0, 8.0)
	flight_timer = flight_duration


func _start_landing() -> void:
	bird_state = BirdState.LANDING

	# Pick new perch height
	if rng.randf() < 0.3:
		perch_height = 0.0
	else:
		perch_height = rng.randf_range(2.0, 5.0)


func _update_perch_position() -> void:
	var terrain_height: float = _get_terrain_height()
	global_position.y = terrain_height + perch_height


func _get_terrain_height() -> float:
	if chunk_manager and chunk_manager.has_method("get_height_at"):
		var h: float = chunk_manager.get_height_at(global_position.x, global_position.z)
		if h < 0:
			return 0
		return h
	return 0


func _on_enter_moving() -> void:
	# Birds fly instead of walking
	_start_flying()


func _on_enter_fleeing() -> void:
	# Take off vertically first, then fly away
	bird_state = BirdState.FLYING

	# Flee direction (away from player)
	if player:
		var flee_dir: Vector2 = Vector2(global_position.x - player.global_position.x,
										 global_position.z - player.global_position.z).normalized()

		var distance: float = rng.randf_range(20.0, 35.0)
		var target_xz: Vector2 = Vector2(global_position.x, global_position.z) + flee_dir * distance

		# Fly high when fleeing
		var terrain_height: float = _get_terrain_height()
		flight_target = Vector3(target_xz.x, terrain_height + flight_height + 5.0, target_xz.y)
	else:
		_pick_new_flight_target()

	flight_timer = 5.0


func _on_enter_idle() -> void:
	# Land if flying
	if bird_state == BirdState.FLYING:
		_start_landing()


func _get_flee_duration() -> float:
	return 5.0


# Override base process functions to use bird states
func _process_idle(_delta: float) -> void:
	if state_timer <= 0 and bird_state == BirdState.PERCHED:
		_enter_state(State.MOVING)


func _process_moving(delta: float) -> void:
	# Birds handle their own flying in _process_flying
	if state_timer <= 0 and bird_state == BirdState.PERCHED:
		_enter_state(State.IDLE)


func _process_fleeing(delta: float) -> void:
	# Continue fleeing until timer expires
	if state_timer <= 0:
		if player and global_position.distance_to(player.global_position) < flee_distance:
			_start_fleeing()
		else:
			_enter_state(State.IDLE)
