extends CanvasLayer
## Food selection menu showing all consumable items with hunger/health restore values.

const HUD_FONT: Font = preload("res://resources/hud_font.tres")

var player: Node
var inventory: Node
var stats: Node

var is_open: bool = false
var focused_index: int = 0

# Parallel arrays tracking the displayed item rows
var item_panels: Array[PanelContainer] = []
var item_types: Array[String] = []

# UI references (built in code)
var main_panel: PanelContainer
var title_label: Label
var hunger_label: Label
var health_label: Label
var scroll_container: ScrollContainer
var item_container: VBoxContainer
var hint_label: Label

# Jump release guard (prevents jump when closing with X/Circle)
var waiting_for_jump_release: bool = false

# Input manager for dynamic button prompts
var input_manager: Node

# Reference to FOOD_VALUES and HEALING_ITEMS on the player
var FOOD_VALUES: Dictionary
var HEALING_ITEMS: Dictionary


func _ready() -> void:
	add_to_group("food_menu")
	layer = 80

	input_manager = get_node_or_null("/root/InputManager")
	if input_manager and input_manager.has_signal("input_device_changed"):
		input_manager.input_device_changed.connect(_on_input_device_changed)

	_build_ui()

	if OS.get_name() == "iOS":
		_apply_mobile_menu_style()


func _build_ui() -> void:
	# Main panel container (centered on screen)
	main_panel = PanelContainer.new()
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.12, 0.8)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.content_margin_left = 20
	panel_style.content_margin_right = 20
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 16
	main_panel.add_theme_stylebox_override("panel", panel_style)

	main_panel.custom_minimum_size = Vector2(700, 0)

	# Vertical layout inside panel
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	main_panel.add_child(vbox)

	# Title
	title_label = Label.new()
	title_label.text = "C O N S U M E"
	title_label.add_theme_font_override("font", HUD_FONT)
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	# Stats row (hunger + health)
	var stats_hbox: HBoxContainer = HBoxContainer.new()
	stats_hbox.add_theme_constant_override("separation", 24)
	stats_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(stats_hbox)

	hunger_label = Label.new()
	hunger_label.add_theme_font_override("font", HUD_FONT)
	hunger_label.add_theme_font_size_override("font_size", 32)
	stats_hbox.add_child(hunger_label)

	health_label = Label.new()
	health_label.add_theme_font_override("font", HUD_FONT)
	health_label.add_theme_font_size_override("font_size", 32)
	stats_hbox.add_child(health_label)

	# Separator
	var sep: HSeparator = HSeparator.new()
	sep.add_theme_constant_override("separation", 4)
	vbox.add_child(sep)

	# Scroll container for item list
	scroll_container = ScrollContainer.new()
	scroll_container.custom_minimum_size = Vector2(0, 0)
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Max height ~480px, variable otherwise
	scroll_container.custom_minimum_size.y = 60
	if OS.get_name() == "iOS":
		scroll_container.scroll_deadzone = 30
	vbox.add_child(scroll_container)

	item_container = VBoxContainer.new()
	item_container.add_theme_constant_override("separation", 4)
	item_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(item_container)

	# Bottom separator
	var sep2: HSeparator = HSeparator.new()
	sep2.add_theme_constant_override("separation", 4)
	vbox.add_child(sep2)

	# Hint label
	hint_label = Label.new()
	hint_label.add_theme_font_override("font", HUD_FONT)
	hint_label.add_theme_font_size_override("font_size", 28)
	hint_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint_label)

	# Full-screen CenterContainer ensures the panel is centered
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(main_panel)
	add_child(center)
	main_panel.visible = false


func open_menu() -> void:
	if not player:
		return

	# Cache the dictionaries from the player
	FOOD_VALUES = player.FOOD_VALUES
	HEALING_ITEMS = player.HEALING_ITEMS

	is_open = true
	waiting_for_jump_release = false
	main_panel.visible = true
	var close_btn: Button = get_node_or_null("MobileCloseButton") as Button
	if close_btn:
		close_btn.visible = true
		call_deferred("_position_close_button")
	if OS.get_name() != "iOS":
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	TouchControls.menu_open = true

	focused_index = 0
	_refresh_item_list()
	_update_stats_display()
	_update_button_prompts()
	SFXManager.play_sfx("menu_open")


func close_menu() -> void:
	SFXManager.play_sfx("menu_close")
	main_panel.visible = false
	var close_btn: Button = get_node_or_null("MobileCloseButton") as Button
	if close_btn:
		close_btn.visible = false
	if OS.get_name() != "iOS":
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	TouchControls.menu_open = false

	# Keep is_open true until jump action is released to prevent jumping
	if Input.is_action_pressed("jump") or Input.is_action_pressed("ui_accept"):
		waiting_for_jump_release = true
	else:
		is_open = false


func _process(_delta: float) -> void:
	if waiting_for_jump_release:
		if not Input.is_action_pressed("jump") and not Input.is_action_pressed("ui_accept"):
			waiting_for_jump_release = false
			is_open = false


func _refresh_item_list() -> void:
	# Clear existing rows
	for child: Node in item_container.get_children():
		child.queue_free()
	item_panels.clear()
	item_types.clear()

	if not inventory:
		return

	# Collect all consumable items the player has
	var seen: Dictionary = {}

	# Food items first
	for food_type: String in FOOD_VALUES:
		if seen.has(food_type):
			continue
		if not inventory.has_item(food_type):
			continue
		seen[food_type] = true
		_add_item_row(food_type)

	# Healing items (skip already-seen ones that are also food)
	for heal_type: String in HEALING_ITEMS:
		if seen.has(heal_type):
			continue
		if not inventory.has_item(heal_type):
			continue
		seen[heal_type] = true
		_add_item_row(heal_type)

	# Update highlight
	if item_panels.size() > 0:
		focused_index = clampi(focused_index, 0, item_panels.size() - 1)
		_update_focus_highlight()

	# Set scroll container height — show up to 8 rows, scrollable beyond that
	var max_visible_rows: int = 8
	var row_count: int = mini(item_panels.size(), max_visible_rows)
	scroll_container.custom_minimum_size.y = row_count * 56.0 if row_count > 0 else 60


func _add_item_row(item_type: String) -> void:
	var count: int = inventory.get_item_count(item_type)
	var item_name: String = item_type.capitalize().replace("_", " ")

	# Build restore text
	var restore_parts: Array[String] = []
	if FOOD_VALUES.has(item_type):
		if item_type == "coca_leaf":
			restore_parts.append("+5, 5min breath")
		else:
			restore_parts.append("+%.0f hunger" % FOOD_VALUES[item_type])
	if HEALING_ITEMS.has(item_type):
		restore_parts.append("+%.0f HP" % HEALING_ITEMS[item_type])
	var restore_text: String = ", ".join(restore_parts) if restore_parts.size() > 0 else ""

	# Create row panel
	var row_panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	row_panel.add_theme_stylebox_override("panel", style)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	row_panel.add_child(hbox)

	# Item name
	var name_label: Label = Label.new()
	name_label.text = item_name
	name_label.add_theme_font_override("font", HUD_FONT)
	name_label.add_theme_font_size_override("font_size", 36)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	hbox.add_child(name_label)

	# Count
	var count_label: Label = Label.new()
	count_label.text = "x%d" % count
	count_label.add_theme_font_override("font", HUD_FONT)
	count_label.add_theme_font_size_override("font_size", 32)
	count_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	hbox.add_child(count_label)

	# Spacer
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	# Restore value
	var restore_label: Label = Label.new()
	restore_label.text = restore_text
	restore_label.add_theme_font_override("font", HUD_FONT)
	restore_label.add_theme_font_size_override("font_size", 32)
	restore_label.add_theme_color_override("font_color", Color(0.6, 1, 0.6, 1))
	hbox.add_child(restore_label)

	# Make rows tappable on mobile
	if OS.get_name() == "iOS":
		row_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		row_panel.gui_input.connect(_on_row_tapped.bind(item_panels.size()))

	item_container.add_child(row_panel)
	item_panels.append(row_panel)
	item_types.append(item_type)


func _update_stats_display() -> void:
	if not stats:
		return

	var hunger: float = stats.hunger
	var max_hunger: float = stats.max_hunger
	var health: float = stats.health
	var max_health: float = stats.get_max_health()

	hunger_label.text = "Hunger: %.0f/%.0f" % [hunger, max_hunger]
	hunger_label.add_theme_color_override("font_color", _get_stat_color(hunger / max_hunger))

	health_label.text = "Health: %.0f/%.0f" % [health, max_health]
	health_label.add_theme_color_override("font_color", _get_stat_color(health / max_health))


func _get_stat_color(ratio: float) -> Color:
	if ratio > 0.5:
		return Color(0.6, 1, 0.6, 1)  # Green
	elif ratio > 0.25:
		return Color(1, 0.85, 0.3, 1)  # Yellow
	else:
		return Color(1, 0.5, 0.5, 1)  # Red


func _update_focus_highlight() -> void:
	for i: int in range(item_panels.size()):
		var panel: PanelContainer = item_panels[i]
		var style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate()
		if i == focused_index:
			style.bg_color = Color(0.3, 0.3, 0.4, 0.8)
		else:
			style.bg_color = Color(0, 0, 0, 0)
		panel.add_theme_stylebox_override("panel", style)


func _navigate_items(direction: int) -> void:
	if item_panels.is_empty():
		return

	focused_index = (focused_index + direction) % item_panels.size()
	if focused_index < 0:
		focused_index = item_panels.size() - 1

	_update_focus_highlight()
	_ensure_focused_visible()
	SFXManager.play_sfx("select")


func _ensure_focused_visible() -> void:
	if focused_index < 0 or focused_index >= item_panels.size():
		return
	var panel: PanelContainer = item_panels[focused_index]
	scroll_container.ensure_control_visible(panel)


func _consume_focused_item() -> void:
	if item_types.is_empty() or focused_index < 0 or focused_index >= item_types.size():
		return

	var item_type: String = item_types[focused_index]
	if player and player.has_method("consume_item"):
		player.consume_item(item_type)

	# Refresh the list after consuming
	_refresh_item_list()
	_update_stats_display()

	# Auto-close if no items left
	if item_types.is_empty():
		close_menu()
		return

	# Clamp focused index if it overflowed
	focused_index = clampi(focused_index, 0, item_panels.size() - 1)
	_update_focus_highlight()


func _input(event: InputEvent) -> void:
	if not is_inside_tree():
		return

	if not is_open:
		return

	# Toggle close with eat action (F / Triangle)
	if event.is_action_pressed("eat"):
		close_menu()
		_handle_input()
		return

	# Close with cancel
	if event.is_action_pressed("ui_cancel"):
		close_menu()
		_handle_input()
		return

	# D-pad navigation (disabled when using touch — touch handles selection)
	if not InputManager.is_using_touch():
		if event.is_action_pressed("ui_down"):
			_navigate_items(1)
			_handle_input()
			return
		if event.is_action_pressed("ui_up"):
			_navigate_items(-1)
			_handle_input()
			return

		# Consume with accept (Circle / Enter)
		if event.is_action_pressed("ui_accept"):
			_consume_focused_item()
			_handle_input()
			return

	# Also consume jump to prevent it from leaking through
	if event.is_action_pressed("jump"):
		_handle_input()
		return


func _handle_input() -> void:
	var vp: Viewport = get_viewport()
	if vp:
		vp.set_input_as_handled()


func _on_row_tapped(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			focused_index = index
			_update_focus_highlight()
			_consume_focused_item()


func _update_button_prompts() -> void:
	if OS.get_name() == "iOS":
		hint_label.text = "Tap item to eat"
		return

	var consume_prompt: String = "Enter"
	var close_prompt: String = "F"

	if input_manager and input_manager.has_method("get_prompt"):
		consume_prompt = input_manager.get_prompt("ui_accept")
		close_prompt = input_manager.get_prompt("eat")

	hint_label.text = "[%s] Consume   [%s] Close" % [consume_prompt, close_prompt]


func _on_input_device_changed(_is_controller: bool) -> void:
	if is_open:
		_update_button_prompts()


func _apply_mobile_menu_style() -> void:
	# Enforce minimum button sizes for touch BEFORE adding close button
	_enforce_min_button_size(main_panel, 44)

	# Add close button as CanvasLayer child (NOT panel child, which would
	# stretch to fill the PanelContainer and intercept all taps)
	var close_btn: Button = Button.new()
	close_btn.name = "MobileCloseButton"
	close_btn.text = "✕"
	close_btn.add_theme_font_size_override("font_size", 32)
	close_btn.custom_minimum_size = Vector2(48, 48)
	close_btn.visible = false
	close_btn.pressed.connect(close_menu)
	add_child(close_btn)


func _position_close_button() -> void:
	var close_btn: Button = get_node_or_null("MobileCloseButton") as Button
	if not close_btn or not main_panel:
		return
	var rect: Rect2 = main_panel.get_global_rect()
	close_btn.anchor_left = 0.0
	close_btn.anchor_right = 0.0
	close_btn.anchor_top = 0.0
	close_btn.anchor_bottom = 0.0
	close_btn.offset_left = rect.position.x + rect.size.x - 56
	close_btn.offset_top = rect.position.y + 8
	close_btn.offset_right = rect.position.x + rect.size.x - 8
	close_btn.offset_bottom = rect.position.y + 56


static func _enforce_min_button_size(node: Node, min_size: int) -> void:
	for child: Node in node.get_children():
		if child is Button:
			if child.custom_minimum_size.x < min_size:
				child.custom_minimum_size.x = min_size
			if child.custom_minimum_size.y < min_size:
				child.custom_minimum_size.y = min_size
		_enforce_min_button_size(child, min_size)
