extends CharacterBody3D
## Simplified player controller for the Oakland Hills house interior.
## Walking only — no survival mechanics, no inventory, no equipment.

const WALK_SPEED: float = 3.0
const MOUSE_SENSITIVITY: float = 0.002
const CONTROLLER_SENSITIVITY: float = 3.0
const INTERACTION_DISTANCE: float = 3.0
const INTERACTION_CHECK_INTERVAL: float = 0.1
const INTERACT_COOLDOWN: float = 0.15
const CAMERA_PITCH_MIN: float = -89.0
const CAMERA_PITCH_MAX: float = 89.0

const HUD_FONT: Font = preload("res://resources/hud_font.tres")

var _camera: Camera3D
var _interaction_raycast: RayCast3D
var _current_target: Node = null
var _is_resting: bool = false

# Interaction prompt UI
var _prompt_canvas: CanvasLayer
var _prompt_panel: PanelContainer
var _prompt_label: Label

# Timers
var _interaction_check_timer: float = 0.0
var _interact_cooldown_timer: float = 0.0

# Gravity
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	add_to_group("player")

	# Create collision shape (same as wilderness player)
	var col_shape: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(0.6, 1.8, 0.6)
	col_shape.shape = box_shape
	col_shape.position = Vector3(0, 0.9, 0)
	add_child(col_shape)

	# Create camera
	_camera = Camera3D.new()
	_camera.name = "Camera3D"
	_camera.position = Vector3(0, 1.6, 0)
	_camera.current = true
	_camera.fov = 75.0
	_camera.near = 0.05
	add_child(_camera)

	# Create interaction raycast (attached to camera)
	_interaction_raycast = RayCast3D.new()
	_interaction_raycast.name = "InteractionRay"
	_interaction_raycast.target_position = Vector3(0, 0, -INTERACTION_DISTANCE)
	_interaction_raycast.collision_mask = 3
	_interaction_raycast.enabled = true
	_camera.add_child(_interaction_raycast)

	# Create interaction prompt UI
	_build_prompt_ui()


func _build_prompt_ui() -> void:
	_prompt_canvas = CanvasLayer.new()
	_prompt_canvas.layer = 50
	add_child(_prompt_canvas)

	# Anchor container at bottom-center
	var anchor: Control = Control.new()
	anchor.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	anchor.offset_top = -80.0
	anchor.offset_bottom = -30.0
	anchor.offset_left = -200.0
	anchor.offset_right = 200.0
	_prompt_canvas.add_child(anchor)

	_prompt_panel = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.75)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	_prompt_panel.add_theme_stylebox_override("panel", style)
	_prompt_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_prompt_panel.visible = false
	anchor.add_child(_prompt_panel)

	_prompt_label = Label.new()
	_prompt_label.add_theme_font_override("font", HUD_FONT)
	_prompt_label.add_theme_font_size_override("font_size", 28)
	_prompt_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_panel.add_child(_prompt_label)


func _input(event: InputEvent) -> void:
	# Handle mouse capture on click
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Handle mouse look (disabled while resting)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if not _is_resting:
			_handle_mouse_look(event)
		return

	# Handle interact (E key or L2)
	if event.is_action_pressed("interact"):
		if _interact_cooldown_timer > 0:
			return
		_interact_cooldown_timer = INTERACT_COOLDOWN
		_try_interact()
		return

	# Handle escape to uncapture mouse
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _handle_mouse_look(event: InputEventMouseMotion) -> void:
	# Rotate player body horizontally (yaw)
	rotate_y(-event.relative.x * MOUSE_SENSITIVITY)

	# Rotate camera vertically (pitch) with clamping
	_camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
	_camera.rotation.x = clamp(
		_camera.rotation.x,
		deg_to_rad(CAMERA_PITCH_MIN),
		deg_to_rad(CAMERA_PITCH_MAX)
	)
	_camera.rotation.z = 0.0  # Prevent roll drift


func _physics_process(delta: float) -> void:
	# Update interact cooldown
	if _interact_cooldown_timer > 0:
		_interact_cooldown_timer -= delta

	# Interaction target check (throttled)
	_interaction_check_timer += delta
	if _interaction_check_timer >= INTERACTION_CHECK_INTERVAL:
		_interaction_check_timer = 0.0
		_update_interaction_target()

	# Skip movement if resting (overlay freeze)
	if _is_resting:
		velocity = Vector3.ZERO
		return

	# Handle right stick camera look (controller)
	_handle_controller_look(delta)

	# Apply gravity
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		if velocity.y < 0:
			velocity.y = 0

	# Get movement input (WASD only, no sprint, no jump)
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector3 = Vector3.ZERO
	if input_dir.length() > 0:
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction.length() > 0:
		velocity.x = direction.x * WALK_SPEED
		velocity.z = direction.z * WALK_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED)
		velocity.z = move_toward(velocity.z, 0, WALK_SPEED)

	move_and_slide()


func _handle_controller_look(delta: float) -> void:
	var look_x: float = Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
	var look_y: float = Input.get_action_strength("look_down") - Input.get_action_strength("look_up")

	if abs(look_x) < 0.1:
		look_x = 0.0
	if abs(look_y) < 0.1:
		look_y = 0.0

	if look_x != 0.0 or look_y != 0.0:
		rotate_y(-look_x * CONTROLLER_SENSITIVITY * delta)
		_camera.rotate_x(-look_y * CONTROLLER_SENSITIVITY * delta)
		_camera.rotation.x = clamp(
			_camera.rotation.x,
			deg_to_rad(CAMERA_PITCH_MIN),
			deg_to_rad(CAMERA_PITCH_MAX)
		)
		_camera.rotation.z = 0.0


func _update_interaction_target() -> void:
	if not _interaction_raycast:
		return

	var new_target: Node = null
	if _interaction_raycast.is_colliding():
		var collider: Node = _interaction_raycast.get_collider()
		if collider and collider.is_in_group("interactable") and not collider.is_queued_for_deletion():
			new_target = collider

	# Clear stale reference
	if _current_target and (not is_instance_valid(_current_target) or _current_target.is_queued_for_deletion()):
		_current_target = null

	if new_target != _current_target:
		_current_target = new_target
		_update_prompt_display()


func _update_prompt_display() -> void:
	if _current_target and _current_target.has_method("get_interaction_text"):
		var text: String = _current_target.get_interaction_text()
		# Get input prompt from InputManager
		var input_mgr: Node = get_node_or_null("/root/InputManager")
		var interact_key: String = "E"
		if input_mgr and input_mgr.has_method("get_prompt"):
			interact_key = input_mgr.get_prompt("interact")
		_prompt_label.text = "[%s] %s" % [interact_key, text]
		_prompt_panel.visible = true
	else:
		_prompt_panel.visible = false


func _try_interact() -> void:
	if is_instance_valid(_current_target) and _current_target.has_method("interact"):
		_current_target.interact(self)
		# Refresh prompt in case interaction changed the text
		if is_instance_valid(_current_target):
			_update_prompt_display()


## Set whether player is in resting state (frozen by overlay).
## Compatible with wilderness pattern: set_resting(true, source_node)
func set_resting(val: bool, _source: Node = null) -> void:
	_is_resting = val
	if val:
		_current_target = null
		_prompt_panel.visible = false
