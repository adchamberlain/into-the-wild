extends CanvasLayer
## New Game+ item selection UI.
## Player picks 5 items from their wilderness journey to carry into a fresh wilderness.

const HUD_FONT: Font = preload("res://resources/hud_font.tres")

var is_open: bool = false
var _player_ref: Node = null
var _selected_items: Array[String] = []
var _available_items: Array[String] = []  # All unique item types from journey
var _cursor_index: int = 0
const MAX_SELECTIONS: int = 5

# UI references (built in code)
var _bg_rect: ColorRect
var _main_panel: PanelContainer
var _scroll_container: ScrollContainer
var _item_container: VBoxContainer
var _counter_label: Label
var _confirm_label: Label
var _hint_label: Label
var _flash_label: Label  # Brief "Already have 5 items selected" message

# Parallel arrays for item rows
var _row_panels: Array[PanelContainer] = []

# Track whether cursor is on the confirm button (one past the last item)
var _on_confirm: bool = false

# Flash message timer
var _flash_timer: float = 0.0

# Input manager for controller prompts
var _input_manager: Node

# Confirm pulse animation state
var _pulse_time: float = 0.0


func _ready() -> void:
	layer = 100
	_input_manager = get_node_or_null("/root/InputManager")
	if _input_manager and _input_manager.has_signal("input_device_changed"):
		_input_manager.input_device_changed.connect(_on_input_device_changed)


func _process(delta: float) -> void:
	if not is_open:
		return

	# Flash message countdown
	if _flash_timer > 0:
		_flash_timer -= delta
		if _flash_timer <= 0 and is_instance_valid(_flash_label):
			_flash_label.visible = false

	# Pulse animation on confirm button when 5 selected
	if _selected_items.size() == MAX_SELECTIONS and is_instance_valid(_confirm_label):
		_pulse_time += delta * 3.0
		var pulse_alpha: float = 0.7 + 0.3 * sin(_pulse_time)
		_confirm_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3, pulse_alpha))


func _input(event: InputEvent) -> void:
	if not is_inside_tree():
		return

	if not is_open:
		return

	if event.is_action_pressed("ui_cancel"):
		close()
		_handle_input()
		return

	if event.is_action_pressed("ui_up"):
		_move_cursor(-1)
		_handle_input()
	elif event.is_action_pressed("ui_down"):
		_move_cursor(1)
		_handle_input()
	elif event.is_action_pressed("ui_accept"):
		if _on_confirm:
			_confirm_departure()
		else:
			_toggle_selection()
		_handle_input()

	# Consume jump action to prevent it from leaking through
	if event.is_action_pressed("jump"):
		_handle_input()


func _handle_input() -> void:
	var vp: Viewport = get_viewport()
	if vp:
		vp.set_input_as_handled()


## Open the New Game+ selection UI.
func open(player: Node) -> void:
	_player_ref = player
	_selected_items.clear()
	_cursor_index = 0
	_on_confirm = false
	_pulse_time = 0.0

	# Build available items list from journey inventory
	var inventory: Dictionary = _get_journey_inventory()
	_available_items.clear()
	for item_type: String in inventory.keys():
		_available_items.append(item_type)
	_available_items.sort()

	_build_ui()
	visible = true
	is_open = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if player and player.has_method("set_resting"):
		player.set_resting(true, self)

	SFXManager.play_sfx("menu_open")


## Close the New Game+ selection UI.
func close() -> void:
	SFXManager.play_sfx("menu_close")
	visible = false
	is_open = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if _player_ref and is_instance_valid(_player_ref) and _player_ref.has_method("set_resting"):
		_player_ref.set_resting(false)
	_player_ref = null

	# Clean up all child nodes
	for child: Node in get_children():
		child.queue_free()

	_row_panels.clear()
	_bg_rect = null
	_main_panel = null
	_scroll_container = null
	_item_container = null
	_counter_label = null
	_confirm_label = null
	_hint_label = null
	_flash_label = null


## Build the full UI from scratch.
func _build_ui() -> void:
	# Clean up any previous UI
	for child: Node in get_children():
		child.queue_free()
	_row_panels.clear()

	# Full-screen darkened background
	_bg_rect = ColorRect.new()
	_bg_rect.color = Color(0.05, 0.05, 0.08, 0.75)
	_bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg_rect)

	# Main panel container
	_main_panel = PanelContainer.new()
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.12, 0.85)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.content_margin_left = 20
	panel_style.content_margin_right = 20
	panel_style.content_margin_top = 20
	panel_style.content_margin_bottom = 20
	_main_panel.add_theme_stylebox_override("panel", panel_style)

	# Position panel: anchors 0.15-0.85 horizontal, 0.08-0.92 vertical
	_main_panel.anchor_left = 0.15
	_main_panel.anchor_right = 0.85
	_main_panel.anchor_top = 0.08
	_main_panel.anchor_bottom = 0.92
	_main_panel.offset_left = 0
	_main_panel.offset_right = 0
	_main_panel.offset_top = 0
	_main_panel.offset_bottom = 0
	add_child(_main_panel)

	# Main vertical layout
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_main_panel.add_child(vbox)

	# Title
	var title_label: Label = Label.new()
	title_label.text = "R E T U R N   T O   T H E"
	title_label.add_theme_font_override("font", HUD_FONT)
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	var title_label2: Label = Label.new()
	title_label2.text = "W I L D E R N E S S"
	title_label2.add_theme_font_override("font", HUD_FONT)
	title_label2.add_theme_font_size_override("font_size", 48)
	title_label2.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))
	title_label2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label2)

	# Subtitle
	var subtitle_label: Label = Label.new()
	subtitle_label.text = "Choose 5 items to bring with you (1 of each)"
	subtitle_label.add_theme_font_override("font", HUD_FONT)
	subtitle_label.add_theme_font_size_override("font_size", 32)
	subtitle_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle_label)

	# Separator
	var sep: HSeparator = HSeparator.new()
	sep.add_theme_constant_override("separation", 4)
	vbox.add_child(sep)

	# Scroll container for item list
	_scroll_container = ScrollContainer.new()
	_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll_container.custom_minimum_size = Vector2(0, 100)
	vbox.add_child(_scroll_container)

	_item_container = VBoxContainer.new()
	_item_container.add_theme_constant_override("separation", 2)
	_item_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_container.add_child(_item_container)

	# Build item rows
	_rebuild_item_rows()

	# Bottom separator
	var sep2: HSeparator = HSeparator.new()
	sep2.add_theme_constant_override("separation", 4)
	vbox.add_child(sep2)

	# Counter label
	_counter_label = Label.new()
	_counter_label.add_theme_font_override("font", HUD_FONT)
	_counter_label.add_theme_font_size_override("font_size", 36)
	_counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_counter_label)

	# Flash label (hidden by default)
	_flash_label = Label.new()
	_flash_label.text = "Already have 5 items selected"
	_flash_label.add_theme_font_override("font", HUD_FONT)
	_flash_label.add_theme_font_size_override("font_size", 28)
	_flash_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5, 1))
	_flash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_flash_label.visible = false
	vbox.add_child(_flash_label)

	# Navigation hint
	_hint_label = Label.new()
	_hint_label.add_theme_font_override("font", HUD_FONT)
	_hint_label.add_theme_font_size_override("font_size", 24)
	_hint_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_hint_label)

	# Confirm button label
	_confirm_label = Label.new()
	_confirm_label.text = "[ Confirm and Depart ]"
	_confirm_label.add_theme_font_override("font", HUD_FONT)
	_confirm_label.add_theme_font_size_override("font_size", 36)
	_confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_confirm_label)

	# Update dynamic elements
	_update_counter()
	_update_confirm_style()
	_update_hint_label()


## Rebuild item rows in the scroll container.
func _rebuild_item_rows() -> void:
	# Clear existing rows
	for child: Node in _item_container.get_children():
		child.queue_free()
	_row_panels.clear()

	var inventory: Dictionary = _get_journey_inventory()

	for i: int in range(_available_items.size()):
		var item_type: String = _available_items[i]
		var count: int = inventory.get(item_type, 0)
		var is_focused: bool = (i == _cursor_index and not _on_confirm)
		var is_selected: bool = _selected_items.has(item_type)

		# Row panel with highlight background
		var row_panel: PanelContainer = PanelContainer.new()
		var row_style: StyleBoxFlat = StyleBoxFlat.new()
		if is_focused:
			row_style.bg_color = Color(0.25, 0.25, 0.35, 0.8)
		else:
			row_style.bg_color = Color(0, 0, 0, 0)
		row_style.content_margin_left = 8
		row_style.content_margin_right = 8
		row_style.content_margin_top = 4
		row_style.content_margin_bottom = 4
		row_style.corner_radius_top_left = 6
		row_style.corner_radius_top_right = 6
		row_style.corner_radius_bottom_left = 6
		row_style.corner_radius_bottom_right = 6
		row_panel.add_theme_stylebox_override("panel", row_style)

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		row_panel.add_child(hbox)

		# Cursor indicator
		var cursor_label: Label = Label.new()
		cursor_label.text = ">" if is_focused else " "
		cursor_label.add_theme_font_override("font", HUD_FONT)
		cursor_label.add_theme_font_size_override("font_size", 28)
		cursor_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))
		cursor_label.custom_minimum_size = Vector2(20, 0)
		hbox.add_child(cursor_label)

		# Item name
		var name_label: Label = Label.new()
		name_label.text = _get_display_name(item_type)
		name_label.add_theme_font_override("font", HUD_FONT)
		name_label.add_theme_font_size_override("font_size", 32)
		if is_selected:
			name_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))
		else:
			name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_label)

		# Item count
		var count_label: Label = Label.new()
		count_label.text = "x%d" % count
		count_label.add_theme_font_override("font", HUD_FONT)
		count_label.add_theme_font_size_override("font_size", 28)
		count_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6, 1))
		hbox.add_child(count_label)

		# Selection status
		var status_label: Label = Label.new()
		status_label.text = "[SELECTED]" if is_selected else ""
		status_label.add_theme_font_override("font", HUD_FONT)
		status_label.add_theme_font_size_override("font_size", 28)
		status_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))
		status_label.custom_minimum_size = Vector2(160, 0)
		hbox.add_child(status_label)

		_item_container.add_child(row_panel)
		_row_panels.append(row_panel)


## Refresh the list display after a state change.
func _refresh_list() -> void:
	_rebuild_item_rows()
	_update_counter()
	_update_confirm_style()
	_ensure_focused_visible()


## Move cursor up or down, wrapping around including the confirm button.
func _move_cursor(direction: int) -> void:
	# Total positions = items + 1 (confirm button)
	var total_positions: int = _available_items.size() + 1

	if total_positions <= 1:
		return

	# Convert current state to a linear index
	var current_pos: int = _available_items.size() if _on_confirm else _cursor_index

	# Move
	current_pos = (current_pos + direction) % total_positions
	if current_pos < 0:
		current_pos = total_positions - 1

	# Convert back to state
	if current_pos >= _available_items.size():
		_on_confirm = true
		_cursor_index = _available_items.size() - 1 if _available_items.size() > 0 else 0
	else:
		_on_confirm = false
		_cursor_index = current_pos

	_refresh_list()
	SFXManager.play_sfx("select")


## Toggle selection of the item at the current cursor.
func _toggle_selection() -> void:
	if _available_items.is_empty() or _cursor_index < 0 or _cursor_index >= _available_items.size():
		return

	var item_type: String = _available_items[_cursor_index]

	if _selected_items.has(item_type):
		# Deselect
		_selected_items.erase(item_type)
		SFXManager.play_sfx("select")
	elif _selected_items.size() < MAX_SELECTIONS:
		# Select
		_selected_items.append(item_type)
		SFXManager.play_sfx("select")
	else:
		# Already at max selections — show flash message
		_show_flash_message()
		return

	_refresh_list()


## Show the "Already have 5 items selected" flash message.
func _show_flash_message() -> void:
	if is_instance_valid(_flash_label):
		_flash_label.visible = true
		_flash_timer = 2.0


## Update the counter label text and color.
func _update_counter() -> void:
	if not is_instance_valid(_counter_label):
		return

	var count: int = _selected_items.size()
	_counter_label.text = "Selected: %d / %d" % [count, MAX_SELECTIONS]

	if count == MAX_SELECTIONS:
		_counter_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6, 1))
	else:
		_counter_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))


## Update the confirm button style based on selection count and focus.
func _update_confirm_style() -> void:
	if not is_instance_valid(_confirm_label):
		return

	if _selected_items.size() == MAX_SELECTIONS:
		if _on_confirm:
			# Active and focused — bright gold
			_confirm_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))
		else:
			# Active but not focused — dimmer gold (pulse will animate this)
			_confirm_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 0.8))
	else:
		# Inactive — grey
		_confirm_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1))
		_pulse_time = 0.0


## Ensure the focused item row is scrolled into view.
func _ensure_focused_visible() -> void:
	if _on_confirm or _row_panels.is_empty():
		return
	if _cursor_index < 0 or _cursor_index >= _row_panels.size():
		return
	var panel: PanelContainer = _row_panels[_cursor_index]
	if is_instance_valid(panel) and is_instance_valid(_scroll_container):
		_scroll_container.ensure_control_visible(panel)


## Confirm departure with selected items.
func _confirm_departure() -> void:
	if _selected_items.size() != MAX_SELECTIONS:
		return

	# Save to GameState
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state:
		game_state.set_new_game_plus_items(_selected_items)
		# Generate new world seed
		var new_seed: int = randi()
		game_state.set_pending_world_seed(new_seed)

	# Close UI state (but don't free children yet — we still need the visual)
	is_open = false

	# Fade to black then change scene
	_fade_and_transition()


## Fade screen to black and transition to the wilderness scene.
func _fade_and_transition() -> void:
	var fade_canvas: CanvasLayer = CanvasLayer.new()
	fade_canvas.layer = 200
	get_tree().root.add_child(fade_canvas)

	var fade_rect: ColorRect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_canvas.add_child(fade_rect)

	var tween: Tween = get_tree().create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 2.0)
	tween.tween_interval(1.0)
	tween.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	)


## Get the journey inventory from GameState.
func _get_journey_inventory() -> Dictionary:
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state and "journey_inventory" in game_state:
		return game_state.journey_inventory
	return {}


## Convert an item_type key to a human-readable display name.
func _get_display_name(item_type: String) -> String:
	return item_type.replace("_", " ").capitalize()


## Update hint label text based on input device.
func _update_hint_label() -> void:
	if not is_instance_valid(_hint_label):
		return

	var up_prompt: String = "Up/Down"
	var accept_prompt: String = "Enter"
	var cancel_prompt: String = "Esc"

	if _input_manager and _input_manager.has_method("is_using_controller") and _input_manager.is_using_controller():
		if _input_manager.has_method("get_prompt"):
			up_prompt = "D-pad"
			accept_prompt = _input_manager.get_prompt("ui_accept")
			cancel_prompt = _input_manager.get_prompt("ui_cancel")

	_hint_label.text = "[%s] Navigate  [%s] Toggle  [%s] Cancel" % [up_prompt, accept_prompt, cancel_prompt]


## Handle input device changes while the UI is open.
func _on_input_device_changed(_is_controller: bool) -> void:
	if is_open:
		_update_hint_label()
