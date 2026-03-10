extends CanvasLayer

## Touch controls overlay for iPad. Only instantiated on iOS.
## Provides virtual joystick, swipe-to-look, and action buttons.

# Joystick config
const JOYSTICK_RADIUS: float = 65.0  # Outer radius
const JOYSTICK_DEADZONE: float = 0.15
const JOYSTICK_POSITION: Vector2 = Vector2(90, -110)  # From bottom-left

# Swipe look config
const TOUCH_LOOK_SENSITIVITY: float = 0.003

# Button config
const BUTTON_RADIUS: float = 28.0  # 56px diameter
const BUTTON_ALPHA_BG: float = 0.06
const BUTTON_ALPHA_BORDER: float = 0.15
const BUTTON_ALPHA_TEXT: float = 0.4

# State
var joystick_touch_index: int = -1
var joystick_center: Vector2 = Vector2.ZERO
var joystick_current: Vector2 = Vector2.ZERO
var look_touch_index: int = -1
var look_previous_position: Vector2 = Vector2.ZERO

# Node references
var joystick_base: Control
var joystick_thumb: Control
var player_controller: Node = null

# Action button data: {name, action, color, position, node}
var action_buttons: Array = []

# Context button references
var use_button: Control = null
var eat_button: Control = null
var crouch_button: Control = null

var safe_margin: Dictionary = {"left": 0, "top": 0, "right": 0, "bottom": 0}


func _ready() -> void:
	layer = 61
	_calculate_safe_area()
	_setup_joystick()
	_setup_action_buttons()
	_setup_menu_buttons()
	# Find player controller for touch look
	await get_tree().process_frame
	player_controller = get_tree().get_first_node_in_group("player")


func _calculate_safe_area() -> void:
	var screen_size: Vector2i = DisplayServer.screen_get_size()
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	safe_margin["left"] = safe_area.position.x
	safe_margin["top"] = safe_area.position.y
	safe_margin["right"] = screen_size.x - (safe_area.position.x + safe_area.size.x)
	safe_margin["bottom"] = screen_size.y - (safe_area.position.y + safe_area.size.y)


func _setup_joystick() -> void:
	var screen_size: Vector2 = get_viewport().get_visible_rect().size

	joystick_base = Control.new()
	joystick_base.custom_minimum_size = Vector2(JOYSTICK_RADIUS * 2, JOYSTICK_RADIUS * 2)
	joystick_base.position = Vector2(24 + safe_margin["left"], screen_size.y - JOYSTICK_RADIUS * 2 - 40 - safe_margin["bottom"])
	joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(joystick_base)
	joystick_center = joystick_base.position + Vector2(JOYSTICK_RADIUS, JOYSTICK_RADIUS)

	joystick_thumb = Control.new()
	joystick_thumb.custom_minimum_size = Vector2(50, 50)
	joystick_thumb.position = Vector2(JOYSTICK_RADIUS - 25, JOYSTICK_RADIUS - 25)
	joystick_thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_base.add_child(joystick_thumb)


func _setup_action_buttons() -> void:
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	var right_x: float = screen_size.x - 48 - safe_margin["right"]
	var bottom_y: float = screen_size.y - 64 - safe_margin["bottom"]

	# Core buttons: JUMP, SPRINT, ACT (bottom-right, vertical stack)
	var core_buttons: Array = [
		{"name": "JUMP", "action": "jump", "color": Color(1, 1, 1), "y_offset": 0},
		{"name": "SPRINT", "action": "sprint", "color": Color(0.4, 0.8, 1), "y_offset": 68},
		{"name": "ACT", "action": "interact", "color": Color(1, 0.85, 0.3), "y_offset": 136},
	]

	for btn_data in core_buttons:
		var btn: TouchScreenButton = _create_action_button(
			btn_data["name"],
			Vector2(right_x, bottom_y - btn_data["y_offset"]),
			btn_data["color"],
			btn_data["action"],
			false
		)
		action_buttons.append({"node": btn, "action": btn_data["action"]})


func _setup_menu_buttons() -> void:
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	var center_x: float = screen_size.x / 2.0
	var menu_items: Array = [
		{"icon": "🎒", "action": "open_inventory"},
		{"icon": "⚒️", "action": "open_crafting"},
		{"icon": "⏸️", "action": "pause"},
	]

	var start_x: float = center_x + 80
	for i: int in range(menu_items.size()):
		var _btn: TouchScreenButton = _create_menu_button(
			menu_items[i]["icon"],
			Vector2(start_x + i * 44, 36 + safe_margin["top"]),
			menu_items[i]["action"]
		)


func _create_action_button(label_text: String, pos: Vector2, color: Color, action: String, _dashed: bool) -> TouchScreenButton:
	# Creates a circular semi-transparent touch button
	var btn: TouchScreenButton = TouchScreenButton.new()
	btn.position = pos - Vector2(BUTTON_RADIUS, BUTTON_RADIUS)
	btn.action = action
	btn.passby_press = false

	# Create circle shape texture
	var img: Image = Image.create(int(BUTTON_RADIUS * 2), int(BUTTON_RADIUS * 2), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Draw filled circle with low alpha
	var center: Vector2i = Vector2i(int(BUTTON_RADIUS), int(BUTTON_RADIUS))
	for x: int in range(img.get_width()):
		for y: int in range(img.get_height()):
			var dist: float = Vector2(x, y).distance_to(Vector2(center))
			if dist <= BUTTON_RADIUS:
				if dist >= BUTTON_RADIUS - 2:
					img.set_pixel(x, y, Color(color.r, color.g, color.b, BUTTON_ALPHA_BORDER))
				else:
					img.set_pixel(x, y, Color(color.r, color.g, color.b, BUTTON_ALPHA_BG))

	var tex: ImageTexture = ImageTexture.create_from_image(img)
	btn.texture_normal = tex

	add_child(btn)

	# Add label
	var lbl: Label = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(color.r, color.g, color.b, BUTTON_ALPHA_TEXT))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size = Vector2(BUTTON_RADIUS * 2, BUTTON_RADIUS * 2)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl)

	return btn


func _create_menu_button(icon: String, pos: Vector2, action: String) -> TouchScreenButton:
	var btn: TouchScreenButton = TouchScreenButton.new()
	btn.position = pos
	btn.action = action
	btn.passby_press = false

	var img: Image = Image.create(36, 36, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.1, 0.1, 0.12, 0.8))
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	btn.texture_normal = tex

	add_child(btn)

	var lbl: Label = Label.new()
	lbl.text = icon
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size = Vector2(36, 36)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl)

	return btn


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event as InputEventScreenDrag)


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# Check if touch is in joystick zone (left side of screen)
		if _is_in_joystick_zone(event.position) and joystick_touch_index == -1:
			joystick_touch_index = event.index
			_update_joystick(event.position)
			get_viewport().set_input_as_handled()
		elif not _is_on_button(event.position):
			# Swipe-to-look zone (anywhere not on joystick or buttons)
			look_touch_index = event.index
			look_previous_position = event.position
			get_viewport().set_input_as_handled()
	else:
		if event.index == joystick_touch_index:
			joystick_touch_index = -1
			_reset_joystick()
			get_viewport().set_input_as_handled()
		elif event.index == look_touch_index:
			look_touch_index = -1
			get_viewport().set_input_as_handled()


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if event.index == joystick_touch_index:
		_update_joystick(event.position)
		get_viewport().set_input_as_handled()
	elif event.index == look_touch_index:
		# Swipe-to-look
		var delta: Vector2 = event.position - look_previous_position
		look_previous_position = event.position
		if player_controller and player_controller.has_method("apply_touch_look"):
			player_controller.apply_touch_look(delta.x, delta.y)
		get_viewport().set_input_as_handled()


func _update_joystick(touch_pos: Vector2) -> void:
	var diff: Vector2 = touch_pos - joystick_center
	var dist: float = diff.length()

	if dist > JOYSTICK_RADIUS:
		diff = diff.normalized() * JOYSTICK_RADIUS

	joystick_current = diff / JOYSTICK_RADIUS  # Normalized -1 to 1

	# Update thumb visual
	joystick_thumb.position = Vector2(JOYSTICK_RADIUS - 25, JOYSTICK_RADIUS - 25) + diff

	# Map to movement actions
	_apply_joystick_to_actions(joystick_current)


func _reset_joystick() -> void:
	joystick_current = Vector2.ZERO
	joystick_thumb.position = Vector2(JOYSTICK_RADIUS - 25, JOYSTICK_RADIUS - 25)
	# Release all movement actions
	Input.action_release("move_forward")
	Input.action_release("move_back")
	Input.action_release("move_left")
	Input.action_release("move_right")


func _apply_joystick_to_actions(direction: Vector2) -> void:
	# Forward/back (negative Y = up = forward)
	if direction.y < -JOYSTICK_DEADZONE:
		Input.action_press("move_forward", -direction.y)
	else:
		Input.action_release("move_forward")

	if direction.y > JOYSTICK_DEADZONE:
		Input.action_press("move_back", direction.y)
	else:
		Input.action_release("move_back")

	# Left/right (strafe)
	if direction.x < -JOYSTICK_DEADZONE:
		Input.action_press("move_left", -direction.x)
	else:
		Input.action_release("move_left")

	if direction.x > JOYSTICK_DEADZONE:
		Input.action_press("move_right", direction.x)
	else:
		Input.action_release("move_right")


func _is_in_joystick_zone(pos: Vector2) -> bool:
	return pos.distance_to(joystick_center) <= JOYSTICK_RADIUS * 1.5


func _is_on_button(pos: Vector2) -> bool:
	# Check if position overlaps any action button
	for btn_data: Dictionary in action_buttons:
		var btn: TouchScreenButton = btn_data["node"]
		var btn_center: Vector2 = btn.position + Vector2(BUTTON_RADIUS, BUTTON_RADIUS)
		if pos.distance_to(btn_center) <= BUTTON_RADIUS * 1.2:
			return true
	return false


## Show/hide context-sensitive buttons based on game state
func update_context_buttons(has_equipped: bool, has_food: bool, near_cliff: bool) -> void:
	if use_button:
		use_button.visible = has_equipped
	if eat_button:
		eat_button.visible = has_food
	if crouch_button:
		crouch_button.visible = near_cliff
