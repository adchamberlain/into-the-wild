extends CanvasLayer

## Touch controls overlay for iPad. Only instantiated on iOS.
## Provides virtual joystick, swipe-to-look, and action buttons.

# Joystick config
const JOYSTICK_RADIUS: float = 75.0  # Outer radius (150px diameter)
const JOYSTICK_DEADZONE: float = 0.15

# Swipe look config
const TOUCH_LOOK_SENSITIVITY: float = 0.003

# Button config
const BUTTON_RADIUS: float = 36.0  # 72px diameter (larger for iPad touch targets)
const BUTTON_ALPHA_BG: float = 0.35
const BUTTON_ALPHA_BORDER: float = 0.6
const BUTTON_ALPHA_TEXT: float = 0.85

# State
var joystick_touch_index: int = -1
var joystick_center: Vector2 = Vector2.ZERO
var joystick_current: Vector2 = Vector2.ZERO
var look_touch_index: int = -1
var look_previous_position: Vector2 = Vector2.ZERO

# Node references
var joystick_bg: Sprite2D
var joystick_thumb: Sprite2D
var player_controller: Node = null

# All touchable button nodes (for hit testing)
var all_buttons: Array[TouchScreenButton] = []

# Context button references
var use_button: TouchScreenButton = null
var eat_button: TouchScreenButton = null
var crouch_button: TouchScreenButton = null

var safe_margin: Dictionary = {"left": 0, "top": 0, "right": 0, "bottom": 0}


func _ready() -> void:
	layer = 61
	_calculate_safe_area()
	_setup_joystick()
	_setup_action_buttons()
	_setup_menu_buttons()
	# Hide/show touch controls when input device changes
	InputManager.input_device_changed.connect(_on_input_device_changed)
	# Find player controller for touch look and context signals
	await get_tree().process_frame
	player_controller = get_tree().get_first_node_in_group("player")
	# Connect to equipment and inventory signals via player controller children
	if player_controller:
		var equipment: Node = player_controller.get_node_or_null("Equipment")
		if equipment:
			if equipment.has_signal("item_equipped"):
				equipment.item_equipped.connect(_on_item_equipped)
			if equipment.has_signal("item_unequipped"):
				equipment.item_unequipped.connect(_on_item_unequipped)
		var inventory: Node = player_controller.get_node_or_null("Inventory")
		if inventory:
			if inventory.has_signal("inventory_changed"):
				inventory.inventory_changed.connect(_on_inventory_changed)


func _calculate_safe_area() -> void:
	var screen_size: Vector2i = DisplayServer.screen_get_size()
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	safe_margin["left"] = safe_area.position.x
	safe_margin["top"] = safe_area.position.y
	safe_margin["right"] = screen_size.x - (safe_area.position.x + safe_area.size.x)
	safe_margin["bottom"] = screen_size.y - (safe_area.position.y + safe_area.size.y)


func _setup_joystick() -> void:
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	joystick_center = Vector2(24 + safe_margin["left"] + JOYSTICK_RADIUS, screen_size.y - JOYSTICK_RADIUS - 40 - safe_margin["bottom"])

	# Joystick background circle
	joystick_bg = Sprite2D.new()
	joystick_bg.texture = _create_circle_texture(int(JOYSTICK_RADIUS * 2), Color(1, 1, 1, 0.2), Color(1, 1, 1, 0.45))
	joystick_bg.position = joystick_center
	add_child(joystick_bg)

	# Joystick thumb (inner knob)
	joystick_thumb = Sprite2D.new()
	joystick_thumb.texture = _create_circle_texture(56, Color(1, 1, 1, 0.4), Color(1, 1, 1, 0.65))
	joystick_thumb.position = joystick_center
	add_child(joystick_thumb)


func _create_circle_texture(diameter: int, fill_color: Color, border_color: Color) -> ImageTexture:
	var img: Image = Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var radius: float = diameter / 2.0
	var center: Vector2 = Vector2(radius, radius)
	for x: int in range(diameter):
		for y: int in range(diameter):
			var dist: float = Vector2(x, y).distance_to(center)
			if dist <= radius:
				if dist >= radius - 2.5:
					img.set_pixel(x, y, border_color)
				else:
					img.set_pixel(x, y, fill_color)
	return ImageTexture.create_from_image(img)


func _setup_action_buttons() -> void:
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	var right_x: float = screen_size.x - 60 - safe_margin["right"]
	var bottom_y: float = screen_size.y - 60 - safe_margin["bottom"]

	# Core buttons: JUMP, SPRINT, ACT (bottom-right, vertical stack)
	var core_buttons: Array = [
		{"name": "JUMP", "action": "jump", "color": Color(1, 1, 1), "y_offset": 0},
		{"name": "SPRINT", "action": "sprint", "color": Color(0.4, 0.8, 1), "y_offset": 84},
		{"name": "ACT", "action": "interact", "color": Color(1, 0.85, 0.3), "y_offset": 168},
	]

	for btn_data in core_buttons:
		var _btn: TouchScreenButton = _create_action_button(
			btn_data["name"],
			Vector2(right_x, bottom_y - btn_data["y_offset"]),
			btn_data["color"],
			btn_data["action"],
			false
		)

	# Context-sensitive buttons
	var screen_size_ctx: Vector2 = get_viewport().get_visible_rect().size

	# USE — below equipped item panel (top-right)
	use_button = _create_action_button(
		"USE",
		Vector2(screen_size_ctx.x - 70 - safe_margin["right"], 110 + safe_margin["top"]),
		Color(0.4, 1, 0.4),  # Green
		"use_equipped",
		true  # Dashed border
	)
	use_button.visible = false

	# EAT — beside health/hunger bars (top-left)
	eat_button = _create_action_button(
		"EAT",
		Vector2(190 + safe_margin["left"], 55 + safe_margin["top"]),
		Color(1, 0.6, 0.2),  # Orange
		"eat",
		true
	)
	eat_button.visible = false

	# CROUCH — near core buttons, above ACT
	crouch_button = _create_action_button(
		"CROUCH",
		Vector2(right_x, bottom_y - 252),
		Color(0.7, 0.7, 0.7),  # Grey
		"crouch",
		true
	)
	crouch_button.visible = false


func _setup_menu_buttons() -> void:
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	var center_x: float = screen_size.x / 2.0
	var menu_items: Array = [
		{"icon": "🎒", "action": "open_inventory"},
		{"icon": "⚒️", "action": "open_crafting"},
		{"icon": "⏸️", "action": "pause"},
	]

	# Position right of center, below the compass widget
	var start_x: float = center_x + 100
	for i: int in range(menu_items.size()):
		var _btn: TouchScreenButton = _create_menu_button(
			menu_items[i]["icon"],
			Vector2(start_x + i * 56, 12 + safe_margin["top"]),
			menu_items[i]["action"]
		)


func _create_action_button(label_text: String, pos: Vector2, color: Color, action: String, _dashed: bool) -> TouchScreenButton:
	# Creates a circular semi-transparent touch button
	var btn: TouchScreenButton = TouchScreenButton.new()
	btn.position = pos - Vector2(BUTTON_RADIUS, BUTTON_RADIUS)
	btn.action = action
	btn.passby_press = false

	# Create circle shape texture with visible alpha
	var img: Image = Image.create(int(BUTTON_RADIUS * 2), int(BUTTON_RADIUS * 2), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center: Vector2i = Vector2i(int(BUTTON_RADIUS), int(BUTTON_RADIUS))
	for x: int in range(img.get_width()):
		for y: int in range(img.get_height()):
			var dist: float = Vector2(x, y).distance_to(Vector2(center))
			if dist <= BUTTON_RADIUS:
				if dist >= BUTTON_RADIUS - 2.5:
					img.set_pixel(x, y, Color(color.r, color.g, color.b, BUTTON_ALPHA_BORDER))
				else:
					img.set_pixel(x, y, Color(color.r, color.g, color.b, BUTTON_ALPHA_BG))

	var tex: ImageTexture = ImageTexture.create_from_image(img)
	btn.texture_normal = tex

	add_child(btn)
	all_buttons.append(btn)

	# Add label
	var lbl: Label = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 18)
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

	var size_px: int = 48
	var img: Image = Image.create(size_px, size_px, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.1, 0.1, 0.12, 0.75))
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	btn.texture_normal = tex

	add_child(btn)
	all_buttons.append(btn)

	var lbl: Label = Label.new()
	lbl.text = icon
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size = Vector2(size_px, size_px)
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
		# Let TouchScreenButton handle its own touches — don't consume them
		if _is_on_any_button(event.position):
			return

		# Check if touch is in joystick zone (left side of screen)
		if _is_in_joystick_zone(event.position) and joystick_touch_index == -1:
			joystick_touch_index = event.index
			_update_joystick(event.position)
			get_viewport().set_input_as_handled()
		else:
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

	# Update thumb visual position
	joystick_thumb.position = joystick_center + diff

	# Map to movement actions
	_apply_joystick_to_actions(joystick_current)


func _reset_joystick() -> void:
	joystick_current = Vector2.ZERO
	joystick_thumb.position = joystick_center
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


func _is_on_any_button(pos: Vector2) -> bool:
	# Check ALL touch buttons (core, context, and menu)
	for btn: TouchScreenButton in all_buttons:
		if not btn.visible:
			continue
		var btn_rect: Rect2 = Rect2(btn.position, btn.texture_normal.get_size())
		if btn_rect.grow(8.0).has_point(pos):
			return true
	return false


func _process(_delta: float) -> void:
	if crouch_button and player_controller:
		if player_controller.has_method("is_near_cliff_edge"):
			crouch_button.visible = player_controller.is_near_cliff_edge()


func _on_item_equipped(item_type: String) -> void:
	if use_button:
		use_button.visible = (item_type != "")


func _on_item_unequipped(_item_type: String) -> void:
	if use_button:
		use_button.visible = false


func _on_inventory_changed() -> void:
	if eat_button and player_controller:
		if player_controller.has_method("has_consumable"):
			eat_button.visible = player_controller.has_consumable()


## Show/hide context-sensitive buttons based on game state
func update_context_buttons(has_equipped: bool, has_food: bool, near_cliff: bool) -> void:
	if use_button:
		use_button.visible = has_equipped
	if eat_button:
		eat_button.visible = has_food
	if crouch_button:
		crouch_button.visible = near_cliff


## Hide touch controls when a controller is connected, show when returning to touch
func _on_input_device_changed(_is_controller: bool) -> void:
	var show_touch: bool = InputManager.is_using_touch()
	visible = show_touch
	# Reset joystick state when hiding to prevent stuck movement
	if not show_touch and joystick_touch_index != -1:
		joystick_touch_index = -1
		_reset_joystick()
