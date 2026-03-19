extends CanvasLayer
## Pause menu for the house scene.
## Resume, Save Game (with slot selection), and Quit to Desktop.

const HUD_FONT: Font = preload("res://resources/hud_font.tres")
const SAVE_DIR: String = "user://saves/"
const SAVE_VERSION: int = 1
const NUM_SLOTS: int = 5

var is_paused: bool = false
var panel: PanelContainer
var button_list: Array[Button] = []
var focused_index: int = 0
var save_confirmation_label: Label
var vbox: VBoxContainer

# Slot picker state
var _showing_slot_picker: bool = false
var _slot_picker_panel: PanelContainer = null
var _slot_cursor: int = 0
var _slot_labels: Array[Label] = []
var _hint_label: Label
var _input_manager: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 150

	panel = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12, 0.95)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	panel.add_theme_stylebox_override("panel", style)
	panel.anchors_preset = Control.PRESET_CENTER
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -160
	panel.offset_top = -150
	panel.offset_right = 160
	panel.offset_bottom = 150
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.visible = false
	add_child(panel)

	vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)

	var title: Label = Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", HUD_FONT)
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))
	vbox.add_child(title)

	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)

	# Resume button
	var resume_btn: Button = Button.new()
	resume_btn.text = "Resume"
	resume_btn.add_theme_font_override("font", HUD_FONT)
	resume_btn.add_theme_font_size_override("font_size", 36)
	resume_btn.focus_mode = Control.FOCUS_ALL
	resume_btn.pressed.connect(_on_resume)
	vbox.add_child(resume_btn)
	button_list.append(resume_btn)

	# Save Game button
	var save_btn: Button = Button.new()
	save_btn.text = "Save Game"
	save_btn.add_theme_font_override("font", HUD_FONT)
	save_btn.add_theme_font_size_override("font_size", 36)
	save_btn.focus_mode = Control.FOCUS_ALL
	save_btn.pressed.connect(_on_save_game)
	vbox.add_child(save_btn)
	button_list.append(save_btn)

	# Quit button (hidden on iOS per Apple policy)
	if OS.get_name() != "iOS":
		var quit_btn: Button = Button.new()
		quit_btn.text = "Quit to Desktop"
		quit_btn.add_theme_font_override("font", HUD_FONT)
		quit_btn.add_theme_font_size_override("font_size", 36)
		quit_btn.focus_mode = Control.FOCUS_ALL
		quit_btn.pressed.connect(_on_quit)
		vbox.add_child(quit_btn)
		button_list.append(quit_btn)

	# Save confirmation label (hidden by default)
	save_confirmation_label = Label.new()
	save_confirmation_label.text = "Game Saved!"
	save_confirmation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	save_confirmation_label.add_theme_font_override("font", HUD_FONT)
	save_confirmation_label.add_theme_font_size_override("font_size", 32)
	save_confirmation_label.add_theme_color_override("font_color", Color(0.6, 1, 0.6, 1))
	save_confirmation_label.visible = false
	vbox.add_child(save_confirmation_label)

	# Hint label (dynamic based on input device)
	_hint_label = Label.new()
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_override("font", HUD_FONT)
	_hint_label.add_theme_font_size_override("font_size", 28)
	_hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	vbox.add_child(_hint_label)

	# Get InputManager for dynamic prompts
	_input_manager = get_node_or_null("/root/InputManager")
	_update_hint_text()
	if _input_manager and _input_manager.has_signal("input_device_changed"):
		_input_manager.input_device_changed.connect(_on_input_device_changed)


func _input(event: InputEvent) -> void:
	if not is_inside_tree():
		return

	# Handle slot picker input first
	if _showing_slot_picker:
		if event.is_action_pressed("ui_cancel"):
			_dismiss_slot_picker()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("ui_down"):
			_slot_cursor = (_slot_cursor + 1) % NUM_SLOTS
			_update_slot_highlight()
			SFXManager.play_sfx("select")
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("ui_up"):
			_slot_cursor = (_slot_cursor - 1 + NUM_SLOTS) % NUM_SLOTS
			_update_slot_highlight()
			SFXManager.play_sfx("select")
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("ui_accept"):
			_save_to_slot(_slot_cursor + 1)
			get_viewport().set_input_as_handled()
			return
		# Consume all other input while slot picker is open
		if event is InputEventKey or event is InputEventJoypadButton:
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_cancel") and is_paused and panel.visible:
		_on_resume()
		get_viewport().set_input_as_handled()
		return

	if is_paused and panel.visible:
		if event.is_action_pressed("ui_down"):
			focused_index = (focused_index + 1) % button_list.size()
			button_list[focused_index].grab_focus()
			SFXManager.play_sfx("select")
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("ui_up"):
			focused_index = (focused_index - 1 + button_list.size()) % button_list.size()
			button_list[focused_index].grab_focus()
			SFXManager.play_sfx("select")
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("ui_accept"):
			if focused_index >= 0 and focused_index < button_list.size():
				button_list[focused_index].pressed.emit()
			get_viewport().set_input_as_handled()
			return


func toggle_pause() -> void:
	if is_paused:
		_on_resume()
	else:
		is_paused = true
		get_tree().paused = true
		panel.visible = true
		if OS.get_name() != "iOS":
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		SFXManager.play_sfx("menu_open")
		focused_index = 0
		button_list[0].grab_focus()


func _on_resume() -> void:
	if _showing_slot_picker:
		_dismiss_slot_picker()
	SFXManager.play_sfx("menu_close")
	is_paused = false
	get_tree().paused = false
	panel.visible = false
	save_confirmation_label.visible = false
	if OS.get_name() != "iOS":
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_save_game() -> void:
	_show_slot_picker()


func _on_quit() -> void:
	get_tree().paused = false
	get_tree().quit()


# ============================================================================
# Slot Picker
# ============================================================================

func _show_slot_picker() -> void:
	if _showing_slot_picker:
		return
	_showing_slot_picker = true
	_slot_cursor = 0
	_slot_labels.clear()

	_slot_picker_panel = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 0.95)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(1, 0.85, 0.3, 0.6)
	_slot_picker_panel.add_theme_stylebox_override("panel", style)
	_slot_picker_panel.anchor_left = 0.3
	_slot_picker_panel.anchor_right = 0.7
	_slot_picker_panel.anchor_top = 0.25
	_slot_picker_panel.anchor_bottom = 0.75
	_slot_picker_panel.offset_left = 0
	_slot_picker_panel.offset_right = 0
	_slot_picker_panel.offset_top = 0
	_slot_picker_panel.offset_bottom = 0
	add_child(_slot_picker_panel)

	var slot_vbox: VBoxContainer = VBoxContainer.new()
	slot_vbox.add_theme_constant_override("separation", 12)
	_slot_picker_panel.add_child(slot_vbox)

	# Title
	var picker_title: Label = Label.new()
	picker_title.text = "Choose Save Slot"
	picker_title.add_theme_font_override("font", HUD_FONT)
	picker_title.add_theme_font_size_override("font_size", 40)
	picker_title.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))
	picker_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_vbox.add_child(picker_title)

	var sep: HSeparator = HSeparator.new()
	slot_vbox.add_child(sep)

	# Build slot rows
	for i: int in range(NUM_SLOTS):
		var slot_num: int = i + 1
		var info: String = _get_slot_info_text(slot_num)
		var slot_label: Label = Label.new()
		slot_label.text = "  Slot %d  -  %s" % [slot_num, info]
		slot_label.add_theme_font_override("font", HUD_FONT)
		slot_label.add_theme_font_size_override("font_size", 32)
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		if OS.get_name() == "iOS":
			slot_label.mouse_filter = Control.MOUSE_FILTER_STOP
			var captured_slot: int = slot_num
			var captured_idx: int = i
			slot_label.gui_input.connect(func(event: InputEvent) -> void:
				if event is InputEventMouseButton and event.pressed:
					_slot_cursor = captured_idx
					_update_slot_highlight()
					_save_to_slot(captured_slot)
			)
		slot_vbox.add_child(slot_label)
		_slot_labels.append(slot_label)

	# Hint
	var hint: Label = Label.new()
	if OS.get_name() == "iOS":
		hint.text = "Tap a slot to save"
	else:
		hint.text = "[Esc] Cancel"
	hint.add_theme_font_override("font", HUD_FONT)
	hint.add_theme_font_size_override("font_size", 24)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_vbox.add_child(hint)

	# Cancel button for iOS
	if OS.get_name() == "iOS":
		var cancel_btn: Button = Button.new()
		cancel_btn.text = "Cancel"
		cancel_btn.add_theme_font_override("font", HUD_FONT)
		cancel_btn.add_theme_font_size_override("font_size", 32)
		cancel_btn.custom_minimum_size = Vector2(200, 48)
		cancel_btn.pressed.connect(_dismiss_slot_picker)
		slot_vbox.add_child(cancel_btn)

	_update_slot_highlight()
	SFXManager.play_sfx("menu_open")


func _dismiss_slot_picker() -> void:
	_showing_slot_picker = false
	_slot_labels.clear()
	if is_instance_valid(_slot_picker_panel):
		_slot_picker_panel.queue_free()
	_slot_picker_panel = null
	SFXManager.play_sfx("menu_close")


func _update_slot_highlight() -> void:
	for i: int in range(_slot_labels.size()):
		if i == _slot_cursor:
			_slot_labels[i].add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))
			_slot_labels[i].text = "> Slot %d  -  %s" % [i + 1, _get_slot_info_text(i + 1)]
		else:
			_slot_labels[i].add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
			_slot_labels[i].text = "  Slot %d  -  %s" % [i + 1, _get_slot_info_text(i + 1)]


func _save_to_slot(slot_num: int) -> void:
	var success: bool = _save_house_state(slot_num)
	_dismiss_slot_picker()
	if success:
		_show_save_confirmation(slot_num)
		SFXManager.play_sfx("select")
	else:
		save_confirmation_label.text = "Save Failed!"
		save_confirmation_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5, 1))
		save_confirmation_label.visible = true
		_start_confirmation_timer()


func _get_slot_info_text(slot_num: int) -> String:
	var filepath: String = SAVE_DIR + "save_slot_%d.json" % slot_num
	if not FileAccess.file_exists(filepath):
		return "Empty"
	var file: FileAccess = FileAccess.open(filepath, FileAccess.READ)
	if not file:
		return "Empty"
	var json: JSON = JSON.new()
	var err: Error = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return "Corrupt"
	var data: Dictionary = json.data as Dictionary
	if not data:
		return "Corrupt"
	var location: String = data.get("player_location", "wilderness")
	var timestamp: String = data.get("timestamp", "")
	var display_loc: String = "House" if location == "house" else "Wilderness"
	if timestamp.length() >= 10:
		return "%s  (%s)" % [display_loc, timestamp.left(10)]
	return display_loc


# ============================================================================
# House Save System
# ============================================================================

## Save the house state to the specified slot.
func _save_house_state(slot_num: int = 1) -> bool:
	# Ensure save directory exists
	var dir: DirAccess = DirAccess.open("user://")
	if dir and not dir.dir_exists("saves"):
		dir.make_dir("saves")

	var save_data: Dictionary = _collect_house_save_data()
	var filepath: String = SAVE_DIR + "save_slot_%d.json" % slot_num
	var file: FileAccess = FileAccess.open(filepath, FileAccess.WRITE)

	if not file:
		push_error("[HousePauseMenu] Failed to open save file: %s" % filepath)
		return false

	var json_string: String = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()

	print("[HousePauseMenu] Game saved to %s (house state)" % filepath)
	return true


## Collect save data for the house scene.
func _collect_house_save_data() -> Dictionary:
	var data: Dictionary = {
		"version": SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"player_location": "house",
		"journey_completed": true,
	}

	# Preserve trail progression state and journey inventory from GameState
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state:
		data["trail"] = {
			"carved_tree_found": game_state.trail_carved_tree_found,
			"stone_cairn_found": game_state.trail_stone_cairn_found,
			"signpost_found": game_state.trail_signpost_found,
		}
		if game_state.journey_inventory.size() > 0:
			data["journey_inventory"] = game_state.journey_inventory.duplicate()

	return data


## Show the "Game Saved!" confirmation and auto-hide after 2 seconds.
func _show_save_confirmation(slot_num: int = 1) -> void:
	save_confirmation_label.text = "Saved to Slot %d!" % slot_num
	save_confirmation_label.add_theme_color_override("font_color", Color(0.6, 1, 0.6, 1))
	save_confirmation_label.visible = true
	_start_confirmation_timer()


## Start a 2-second timer to hide the confirmation label.
func _start_confirmation_timer() -> void:
	if not is_inside_tree():
		return
	# Use a SceneTreeTimer so it works while paused (process_mode handled by PROCESS_MODE_ALWAYS)
	var timer: SceneTreeTimer = get_tree().create_timer(2.0, true, false, true)
	timer.timeout.connect(_hide_save_confirmation)


## Hide the save confirmation label.
func _hide_save_confirmation() -> void:
	if is_instance_valid(save_confirmation_label):
		save_confirmation_label.visible = false


## Update the hint text based on current input device.
func _update_hint_text() -> void:
	if not is_instance_valid(_hint_label):
		return
	if OS.get_name() == "iOS":
		_hint_label.text = "Tap a button above"
		return
	var prompt: String = "ESC"
	if _input_manager and _input_manager.has_method("get_prompt"):
		prompt = _input_manager.get_prompt("ui_cancel")
	_hint_label.text = "[%s to resume]" % prompt


## Called when input device changes (keyboard <-> controller).
func _on_input_device_changed(_is_controller: bool) -> void:
	_update_hint_text()
