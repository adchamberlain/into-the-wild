extends Node3D
class_name AmbientAnimalBase
## Base class for ambient wildlife that provides atmospheric life to the wilderness.
## Animals flee when the player approaches but cannot be directly hunted.

# State machine
enum State { IDLE, MOVING, FLEEING }
var current_state: State = State.IDLE

# Configuration (override in subclasses)
var flee_distance: float = 8.0  # Distance at which animal starts fleeing
var awareness_distance: float = 15.0  # Distance at which animal notices player
var move_speed: float = 3.0
var flee_speed: float = 6.0

# State timers
var state_timer: float = 0.0
var idle_duration: float = 3.0  # Will be randomized
var move_duration: float = 2.0  # Will be randomized

# Player proximity check (throttled for performance)
var proximity_check_timer: float = 0.0
const PROXIMITY_CHECK_INTERVAL: float = 0.25  # Check 4 times per second
var player: Node3D = null
var chunk_manager: Node = null
var sfx_manager: Node = null  # Cached for performance

# Distance-based culling
const PROCESSING_DISTANCE: float = 50.0  # Don't process animals beyond this
const ROTATION_UPDATE_INTERVAL: float = 0.1  # Throttle look_at() calls
var rotation_timer: float = 0.0
var is_too_far: bool = false  # Skip processing when far from player

# Movement
var move_direction: Vector3 = Vector3.ZERO
var target_position: Vector3 = Vector3.ZERO

# Visual
var mesh_container: Node3D  # Container for animal mesh (for rotation)

# RNG for behavior
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	# Unique seed per animal for varied behavior
	rng.seed = hash(global_position) + randi()

	# Find player, chunk manager, and SFX manager (cache for performance)
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	chunk_manager = get_tree().get_first_node_in_group("chunk_manager")
	sfx_manager = get_node_or_null("/root/SFXManager")

	# Create mesh container for rotation
	mesh_container = Node3D.new()
	mesh_container.name = "MeshContainer"
	add_child(mesh_container)

	# Build the animal mesh (override in subclass)
	_build_mesh()

	# Start in idle state
	_enter_state(State.IDLE)


func _process(delta: float) -> void:
	# Throttled player proximity check (also updates distance culling)
	proximity_check_timer += delta
	if proximity_check_timer >= PROXIMITY_CHECK_INTERVAL:
		proximity_check_timer = 0.0
		_check_player_proximity()

	# Skip processing if too far from player (performance optimization)
	if is_too_far:
		return

	# Update rotation timer
	rotation_timer += delta

	# Update state
	state_timer -= delta

	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.MOVING:
			_process_moving(delta)
		State.FLEEING:
			_process_fleeing(delta)


func _check_player_proximity() -> void:
	if not player or not is_instance_valid(player):
		return

	var distance_to_player: float = global_position.distance_to(player.global_position)

	# Distance-based culling - skip processing for far away animals
	is_too_far = distance_to_player > PROCESSING_DISTANCE

	# Flee if player is too close
	if distance_to_player < flee_distance and current_state != State.FLEEING:
		_start_fleeing()
	# Become alert if player is within awareness range (might affect idle behavior)
	elif distance_to_player < awareness_distance:
		# Subclasses can override to add alert behavior
		pass


func _start_fleeing() -> void:
	if not player:
		return

	# Calculate flee direction (directly away from player)
	var flee_dir: Vector3 = (global_position - player.global_position).normalized()
	flee_dir.y = 0  # Keep horizontal

	if flee_dir.length() < 0.1:
		flee_dir = Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized()

	move_direction = flee_dir
	_enter_state(State.FLEEING)


func _enter_state(new_state: State) -> void:
	current_state = new_state

	match new_state:
		State.IDLE:
			idle_duration = rng.randf_range(2.0, 8.0)
			state_timer = idle_duration
			_on_enter_idle()
		State.MOVING:
			# Pick random move direction
			var angle: float = rng.randf() * TAU
			move_direction = Vector3(cos(angle), 0, sin(angle))
			move_duration = rng.randf_range(1.0, 3.0)
			state_timer = move_duration
			_on_enter_moving()
		State.FLEEING:
			state_timer = _get_flee_duration()
			_on_enter_fleeing()


func _process_idle(_delta: float) -> void:
	if state_timer <= 0:
		_enter_state(State.MOVING)


func _process_moving(delta: float) -> void:
	_move_animal(delta, move_speed)

	if state_timer <= 0:
		_enter_state(State.IDLE)


func _process_fleeing(delta: float) -> void:
	_move_animal(delta, flee_speed)

	if state_timer <= 0:
		# Check if still need to flee
		if player and global_position.distance_to(player.global_position) < flee_distance:
			_start_fleeing()  # Continue fleeing
		else:
			_enter_state(State.IDLE)


func _move_animal(delta: float, speed: float) -> void:
	# Calculate new position
	var movement: Vector3 = move_direction * speed * delta
	var new_pos: Vector3 = global_position + movement

	# Sample terrain height at new position
	if chunk_manager and chunk_manager.has_method("get_height_at"):
		var terrain_height: float = chunk_manager.get_height_at(new_pos.x, new_pos.z)
		# Skip water (negative height)
		if terrain_height < 0:
			# Turn around
			move_direction = -move_direction
			return
		new_pos.y = terrain_height

	global_position = new_pos

	# Face movement direction (throttled for performance)
	if move_direction.length() > 0.1 and rotation_timer >= ROTATION_UPDATE_INTERVAL:
		rotation_timer = 0.0
		var look_target: Vector3 = global_position + move_direction
		mesh_container.look_at(look_target, Vector3.UP)


## Override in subclasses to build animal-specific mesh
func _build_mesh() -> void:
	pass


## Override in subclasses for custom idle behavior
func _on_enter_idle() -> void:
	pass


## Override in subclasses for custom movement behavior
func _on_enter_moving() -> void:
	pass


## Override in subclasses for custom flee behavior
func _on_enter_fleeing() -> void:
	pass


## Override to return flee duration (number of seconds to flee)
func _get_flee_duration() -> float:
	return 2.0


## Called by terrain chunk when unloading
func despawn() -> void:
	queue_free()


## Get a random position near this animal for movement targets
func _get_random_nearby_position(max_distance: float) -> Vector3:
	var angle: float = rng.randf() * TAU
	var distance: float = rng.randf_range(max_distance * 0.3, max_distance)
	var offset: Vector3 = Vector3(cos(angle) * distance, 0, sin(angle) * distance)
	return global_position + offset
