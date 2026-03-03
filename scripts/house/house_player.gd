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
const FOOTSTEP_INTERVAL: float = 0.45
const CROUCH_SPEED: float = 2.5
const CROUCH_HEIGHT: float = 0.9
const STAND_HEIGHT: float = 1.8
const CROUCH_CAMERA_Y: float = 0.8
const JUMP_VELOCITY: float = 5.5

const HUD_FONT: Font = preload("res://resources/hud_font.tres")

var _camera: Camera3D
var _interaction_raycast: RayCast3D
var _current_target: Node = null
var _is_resting: bool = false
var is_crouching: bool = false

# Interaction prompt UI
var _prompt_canvas: CanvasLayer
var _prompt_panel: PanelContainer
var _prompt_label: Label
var _crosshair_canvas: CanvasLayer
var _crosshair_label: Label
var _col_shape: CollisionShape3D

# Timers
var _interaction_check_timer: float = 0.0
var _interact_cooldown_timer: float = 0.0
var _footstep_timer: float = 0.0

# Gravity
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	add_to_group("player")

	# Create collision shape (same as wilderness player)
	_col_shape = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(0.6, 1.8, 0.6)
	_col_shape.shape = box_shape
	_col_shape.position = Vector3(0, 0.9, 0)
	add_child(_col_shape)

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

	# Create crosshair
	_build_crosshair()


func _build_prompt_ui() -> void:
	_prompt_canvas = CanvasLayer.new()
	_prompt_canvas.layer = 50
	add_child(_prompt_canvas)

	# Anchor container at bottom-center
	var anchor: Control = Control.new()
	anchor.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	anchor.offset_top = -100.0
	anchor.offset_bottom = -30.0
	anchor.offset_left = -300.0
	anchor.offset_right = 300.0
	_prompt_canvas.add_child(anchor)

	_prompt_panel = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.75)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	_prompt_panel.add_theme_stylebox_override("panel", style)
	_prompt_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_prompt_panel.visible = false
	anchor.add_child(_prompt_panel)

	_prompt_label = Label.new()
	_prompt_label.add_theme_font_override("font", HUD_FONT)
	_prompt_label.add_theme_font_size_override("font_size", 40)
	_prompt_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_panel.add_child(_prompt_label)


func _build_crosshair() -> void:
	_crosshair_canvas = CanvasLayer.new()
	_crosshair_canvas.layer = 50
	add_child(_crosshair_canvas)

	_crosshair_label = Label.new()
	_crosshair_label.text = "+"
	_crosshair_label.add_theme_font_override("font", HUD_FONT)
	_crosshair_label.add_theme_font_size_override("font_size", 24)
	_crosshair_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	_crosshair_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_crosshair_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_crosshair_label.set_anchors_preset(Control.PRESET_CENTER)
	_crosshair_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_crosshair_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	_crosshair_canvas.add_child(_crosshair_label)


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

	# Handle crouch toggle
	if event.is_action_pressed("crouch") and not _is_resting:
		_toggle_crouch()
		return

	# Handle jump
	if event.is_action_pressed("jump") and not _is_resting:
		if is_on_floor():
			if is_crouching:
				if _can_stand_up():
					_toggle_crouch()
					velocity.y = JUMP_VELOCITY
			else:
				velocity.y = JUMP_VELOCITY
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

	# Determine current movement speed
	var move_speed: float = CROUCH_SPEED if is_crouching else WALK_SPEED

	# Get movement input (WASD only, no sprint)
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector3 = Vector3.ZERO
	if input_dir.length() > 0:
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction.length() > 0:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

	move_and_slide()

	# Smoothly lerp camera Y for crouch/stand transitions
	var target_cam_y: float = CROUCH_CAMERA_Y if is_crouching else 1.6
	_camera.position.y = lerp(_camera.position.y, target_cam_y, 10.0 * delta)

	# Footstep sounds on hardwood floors
	var h_speed: float = Vector2(velocity.x, velocity.z).length()
	if h_speed > 0.5 and is_on_floor():
		_footstep_timer += delta
		if _footstep_timer >= FOOTSTEP_INTERVAL:
			_footstep_timer = 0.0
			SFXManager.play_footstep("stone")
	else:
		_footstep_timer = 0.0


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
		_crosshair_label.visible = false
	else:
		_crosshair_label.visible = true


func _toggle_crouch() -> void:
	if is_crouching:
		# Try to stand up — check clearance first
		if not _can_stand_up():
			return
		is_crouching = false
	else:
		is_crouching = true
	_update_crouch_collision()


func _update_crouch_collision() -> void:
	var box: BoxShape3D = _col_shape.shape as BoxShape3D
	if is_crouching:
		box.size = Vector3(0.6, CROUCH_HEIGHT, 0.6)
		_col_shape.position = Vector3(0, CROUCH_HEIGHT / 2.0, 0)
	else:
		box.size = Vector3(0.6, STAND_HEIGHT, 0.6)
		_col_shape.position = Vector3(0, STAND_HEIGHT / 2.0, 0)


func _can_stand_up() -> bool:
	# Raycast upward from current position to check if there is room to stand
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var ray_origin: Vector3 = global_position + Vector3(0, CROUCH_HEIGHT, 0)
	var ray_end: Vector3 = ray_origin + Vector3(0, STAND_HEIGHT - CROUCH_HEIGHT, 0)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.exclude = [get_rid()]
	var result: Dictionary = space_state.intersect_ray(query)
	return result.is_empty()
