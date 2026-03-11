extends CanvasLayer
class_name TouchControls

## Touch controls overlay for iPad. Only instantiated on iOS.
## Provides virtual joystick, swipe-to-look, and action buttons.

# Joystick config
const JOYSTICK_RADIUS: float = 160.0  # Outer radius (320px diameter)
const JOYSTICK_DEADZONE: float = 0.15

# Swipe look config
const TOUCH_LOOK_SENSITIVITY: float = 0.003

# Button config
const BUTTON_RADIUS: float = 60.0  # 120px diameter action buttons
const BUTTON_ALPHA_BG: float = 0.75
const BUTTON_ALPHA_BORDER: float = 0.9
const BUTTON_ALPHA_TEXT: float = 1.0

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
var _last_menu_open_state: bool = false  # Cache to avoid per-frame updates


func _ready() -> void:
	layer = 61
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Reset static menu_open flag — scene reload preserves static vars,
	# so saving from pause menu would leave controls permanently hidden
	menu_open = false
	_calculate_safe_area()
	_setup_joystick()
	_setup_action_buttons()
	_setup_menu_buttons()
	# Hide/show touch controls when input device changes
	InputManager.input_device_changed.connect(_on_input_device_changed)
	# Find player controller for touch look and context signals (deferred to ensure player exists)
	_find_player_deferred()


## Find the player controller, retrying each frame until found (handles save load timing).
func _find_player_deferred() -> void:
	# Wait a frame first to let the scene tree settle
	await get_tree().process_frame
	# Try up to 60 frames (~1 second) to find the player
	var attempts: int = 0
	while not player_controller and attempts < 60:
		player_controller = get_tree().get_first_node_in_group("player")
		if player_controller:
			break
		attempts += 1
		await get_tree().process_frame

	if not player_controller:
		push_warning("[TouchControls] Could not find player controller")
		return

	# Connect to equipment and inventory signals
	var equipment_node: Node = player_controller.get_node_or_null("Equipment")
	if equipment_node:
		if equipment_node.has_signal("item_equipped"):
			equipment_node.item_equipped.connect(_on_item_equipped)
		if equipment_node.has_signal("item_unequipped"):
			equipment_node.item_unequipped.connect(_on_item_unequipped)
	var inventory_node: Node = player_controller.get_node_or_null("Inventory")
	if inventory_node:
		if inventory_node.has_signal("inventory_changed"):
			inventory_node.inventory_changed.connect(_on_inventory_changed)

	# Set initial button visibility based on current state
	if equipment_node and equipment_node.has_method("get_equipped"):
		var equipped: String = equipment_node.get_equipped()
		if eat_button:
			eat_button.visible = player_controller.has_consumable() if player_controller.has_method("has_consumable") else false
		# use_button is managed by HUD TouchSlotArrows, not here


func _calculate_safe_area() -> void:
	var screen_size: Vector2i = DisplayServer.screen_get_size()
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	safe_margin["left"] = safe_area.position.x
	safe_margin["top"] = safe_area.position.y
	safe_margin["right"] = screen_size.x - (safe_area.position.x + safe_area.size.x)
	safe_margin["bottom"] = screen_size.y - (safe_area.position.y + safe_area.size.y)


func _setup_joystick() -> void:
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	# Position joystick higher to keep downward drag away from iPad home indicator zone
	joystick_center = Vector2(32 + safe_margin["left"] + JOYSTICK_RADIUS, screen_size.y - JOYSTICK_RADIUS - 100 - safe_margin["bottom"])

	# Joystick background circle
	joystick_bg = Sprite2D.new()
	joystick_bg.texture = _create_circle_texture(int(JOYSTICK_RADIUS * 2), Color(1, 1, 1, 0.15), Color(1, 1, 1, 0.35))
	joystick_bg.position = joystick_center
	add_child(joystick_bg)

	# Joystick thumb (inner knob)
	joystick_thumb = Sprite2D.new()
	joystick_thumb.texture = _create_circle_texture(120, Color(1, 1, 1, 0.35), Color(1, 1, 1, 0.55))
	joystick_thumb.position = joystick_center
	add_child(joystick_thumb)

	# "MOVE" label below joystick
	var move_label: Label = Label.new()
	move_label.text = "MOVE"
	move_label.add_theme_font_size_override("font_size", 16)
	move_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
	move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_label.position = Vector2(joystick_center.x - 30, joystick_center.y + JOYSTICK_RADIUS + 6)
	move_label.size = Vector2(60, 20)
	add_child(move_label)


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
	var right_x: float = screen_size.x - 52 - safe_margin["right"] - BUTTON_RADIUS
	var bottom_y: float = screen_size.y - 48 - safe_margin["bottom"] - BUTTON_RADIUS

	# Core buttons from bottom: SPRINT, JUMP, ACT (top)
	var core_buttons: Array = [
		{"name": "SPRINT", "action": "sprint", "color": Color(0.4, 0.85, 0.5), "y_offset": 0},
		{"name": "JUMP", "action": "jump", "color": Color(0.75, 0.75, 0.75), "y_offset": 140},
		{"name": "ACT", "action": "interact", "color": Color(1, 0.85, 0.3), "y_offset": 280},
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

	# USE button is now a compact HUD button in TouchSlotArrows (hud.gd)
	# instead of a large circular TouchScreenButton here

	# EAT is now a menu-style button created in _setup_menu_buttons()

	# CROUCH — near core buttons, above ACT
	crouch_button = _create_action_button(
		"CROUCH",
		Vector2(right_x, bottom_y - 420),
		Color(0.7, 0.7, 0.7),  # Grey
		"crouch",
		true
	)
	crouch_button.visible = false


func _setup_menu_buttons() -> void:
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	var center_x: float = screen_size.x / 2.0
	# Menu buttons with text labels (emoji don't render in Godot iOS with monospace fonts)
	var menu_items: Array = [
		{"icon": "BAG", "action": "open_inventory", "color": Color(0.45, 0.5, 0.55, 0.85)},
		{"icon": "CRAFT", "action": "open_crafting", "color": Color(0.45, 0.5, 0.55, 0.85)},
		{"icon": "MENU", "action": "pause", "color": Color(0.45, 0.5, 0.55, 0.85)},
	]

	# EAT button: left side, right of stats panel + air bubbles (moved right to avoid bubble overlap)
	eat_button = _create_menu_button(
		"EAT",
		Vector2(380 + safe_margin["left"], 56 + safe_margin["top"]),
		"eat",
		Color(0.45, 0.5, 0.55, 0.85)
	)
	# Set orange text for EAT label
	var eat_lbl: Label = eat_button.get_child(0) as Label
	if eat_lbl:
		eat_lbl.add_theme_color_override("font_color", Color(1, 0.7, 0.2, 0.95))

	# Position clearly right of time panel with good spacing (time panel is ±130 from center)
	var start_x: float = center_x + 200
	for i: int in range(menu_items.size()):
		var _btn: TouchScreenButton = _create_menu_button(
			menu_items[i]["icon"],
			Vector2(start_x + i * 96, 56 + safe_margin["top"]),
			menu_items[i]["action"],
			menu_items[i]["color"]
		)


func _create_action_button(label_text: String, pos: Vector2, color: Color, action: String, _dashed: bool) -> TouchScreenButton:
	# Creates a circular semi-transparent touch button
	var btn: TouchScreenButton = TouchScreenButton.new()
	btn.position = pos - Vector2(BUTTON_RADIUS, BUTTON_RADIUS)
	# Don't use btn.action on iOS — TouchScreenButton fails to release actions reliably.
	# Instead, use button_down/button_up signals with Input.parse_input_event().
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

	# Explicit action press/release via signals — iOS TouchScreenButton doesn't reliably release actions
	# Note: TouchScreenButton extends Node2D, not BaseButton — uses pressed/released, not button_down/button_up
	var captured_action: String = action
	btn.pressed.connect(func() -> void:
		var ev: InputEventAction = InputEventAction.new()
		ev.action = captured_action
		ev.pressed = true
		Input.parse_input_event(ev)
	)
	btn.released.connect(func() -> void:
		var ev: InputEventAction = InputEventAction.new()
		ev.action = captured_action
		ev.pressed = false
		Input.parse_input_event(ev)
	)

	# Add label
	var lbl: Label = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1.0))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size = Vector2(BUTTON_RADIUS * 2, BUTTON_RADIUS * 2)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl)

	return btn


func _create_menu_button(label_text: String, pos: Vector2, action: String, bg_color: Color = Color(0.1, 0.1, 0.12, 0.85)) -> TouchScreenButton:
	var btn: TouchScreenButton = TouchScreenButton.new()
	var btn_w: int = 84
	var btn_h: int = 88
	btn.position = pos - Vector2(btn_w / 2.0, btn_h / 2.0)
	btn.passby_press = false

	# Create rounded rectangle menu button texture with border
	var img: Image = Image.create(btn_w, btn_h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var corner_r: int = 10
	var border_w: int = 2
	var border_color: Color = Color(0.3, 0.3, 0.35, 0.9)
	for x: int in range(btn_w):
		for y: int in range(btn_h):
			# Rounded rectangle check
			var inside: bool = false
			if x >= corner_r and x < btn_w - corner_r:
				inside = true
			elif y >= corner_r and y < btn_h - corner_r:
				inside = true
			else:
				# Check corner circles
				var cx: int = corner_r if x < corner_r else btn_w - corner_r - 1
				var cy: int = corner_r if y < corner_r else btn_h - corner_r - 1
				if Vector2(x, y).distance_to(Vector2(cx, cy)) <= corner_r:
					inside = true
			if inside:
				# Check if on border edge
				var on_border: bool = (x < border_w or x >= btn_w - border_w
					or y < border_w or y >= btn_h - border_w)
				if not on_border:
					# Also check inner corner radius for border
					var inner_r: int = corner_r - border_w
					if inner_r > 0:
						var in_inner: bool = false
						if x >= corner_r and x < btn_w - corner_r:
							in_inner = true
						elif y >= corner_r and y < btn_h - corner_r:
							in_inner = true
						else:
							var icx: int = corner_r if x < corner_r else btn_w - corner_r - 1
							var icy: int = corner_r if y < corner_r else btn_h - corner_r - 1
							if Vector2(x, y).distance_to(Vector2(icx, icy)) <= inner_r:
								in_inner = true
						if in_inner:
							img.set_pixel(x, y, bg_color)
						else:
							img.set_pixel(x, y, border_color)
					else:
						img.set_pixel(x, y, bg_color)
				else:
					img.set_pixel(x, y, border_color)
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	btn.texture_normal = tex

	add_child(btn)
	all_buttons.append(btn)

	# Explicit action press/release — same iOS reliability fix as action buttons
	var captured_action: String = action
	btn.pressed.connect(func() -> void:
		var ev: InputEventAction = InputEventAction.new()
		ev.action = captured_action
		ev.pressed = true
		Input.parse_input_event(ev)
	)
	btn.released.connect(func() -> void:
		var ev: InputEventAction = InputEventAction.new()
		ev.action = captured_action
		ev.pressed = false
		Input.parse_input_event(ev)
	)

	var lbl: Label = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 0.95))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size = Vector2(btn_w, btn_h)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl)

	return btn


## Static flag — menus set this to prevent touch controls from consuming input
static var menu_open: bool = false


func _input(event: InputEvent) -> void:
	# Don't intercept touch when menus/overlays are open
	if menu_open:
		if joystick_touch_index != -1:
			joystick_touch_index = -1
			_reset_joystick()
		look_touch_index = -1
		return
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
	Input.action_release("move_backward")
	Input.action_release("move_left")
	Input.action_release("move_right")


func _apply_joystick_to_actions(direction: Vector2) -> void:
	# Forward/back (negative Y = up = forward)
	if direction.y < -JOYSTICK_DEADZONE:
		Input.action_press("move_forward", -direction.y)
	else:
		Input.action_release("move_forward")

	if direction.y > JOYSTICK_DEADZONE:
		Input.action_press("move_backward", direction.y)
	else:
		Input.action_release("move_backward")

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
	# Only update visibility when menu_open state changes (avoid per-frame iteration)
	if menu_open != _last_menu_open_state:
		_last_menu_open_state = menu_open
		if menu_open:
			for btn: TouchScreenButton in all_buttons:
				btn.visible = false
			joystick_bg.visible = false
			joystick_thumb.visible = false
		else:
			# Restore core button visibility (context buttons handled separately)
			for btn: TouchScreenButton in all_buttons:
				if btn == use_button or btn == eat_button or btn == crouch_button:
					continue  # Context buttons managed by their own logic
				btn.visible = true
			joystick_bg.visible = true
			joystick_thumb.visible = true

	if not menu_open and crouch_button and player_controller:
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
