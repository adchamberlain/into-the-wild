extends CharacterBody3D
## First-person player controller with WASD movement, mouse look, jumping, and sprinting.

# Movement settings
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002

# Camera settings
@export var camera_pitch_min: float = -89.0
@export var camera_pitch_max: float = 89.0

# Node references
@onready var camera: Camera3D = $Camera3D
@onready var head: Node3D = $Camera3D

# State
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_speed: float = walk_speed
var is_sprinting: bool = false


func _ready() -> void:
	# Capture mouse for first-person control
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Ensure camera is active
	if camera:
		camera.current = true


func _input(event: InputEvent) -> void:
	# Handle mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_handle_mouse_look(event)

	# Toggle mouse capture with Escape
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _handle_mouse_look(event: InputEventMouseMotion) -> void:
	# Rotate player body horizontally (yaw)
	rotate_y(-event.relative.x * mouse_sensitivity)

	# Rotate camera vertically (pitch) with clamping
	camera.rotate_x(-event.relative.y * mouse_sensitivity)
	camera.rotation.x = clamp(
		camera.rotation.x,
		deg_to_rad(camera_pitch_min),
		deg_to_rad(camera_pitch_max)
	)


func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump (check both action and direct key)
	var jump_pressed: bool = Input.is_action_just_pressed("jump") or Input.is_key_pressed(KEY_SPACE)
	if jump_pressed and is_on_floor():
		velocity.y = jump_velocity

	# Handle sprint
	var sprint_held: bool = Input.is_action_pressed("sprint") or Input.is_key_pressed(KEY_SHIFT)
	is_sprinting = sprint_held and is_on_floor()
	current_speed = sprint_speed if is_sprinting else walk_speed

	# Get input direction (use physical key checking for Mac compatibility)
	var input_dir: Vector2 = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		input_dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S):
		input_dir.y += 1
	if Input.is_physical_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D):
		input_dir.x += 1
	input_dir = input_dir.normalized()

	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Apply movement
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		# Decelerate smoothly
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()


func _notification(what: int) -> void:
	# Release mouse when window loses focus
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
