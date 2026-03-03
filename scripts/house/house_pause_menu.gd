extends CanvasLayer
## Pause menu for the house scene.
## Resume, Save Game, and Quit to Desktop.

const HUD_FONT: Font = preload("res://resources/hud_font.tres")
const SAVE_DIR: String = "user://saves/"
const SAVE_VERSION: int = 1

var is_paused: bool = false
var panel: PanelContainer
var button_list: Array[Button] = []
var focused_index: int = 0
var save_confirmation_label: Label
var vbox: VBoxContainer


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

	# Quit button
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

	# Hint label
	var hint: Label = Label.new()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_override("font", HUD_FONT)
	hint.add_theme_font_size_override("font_size", 28)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	hint.text = "[ESC to resume]"
	vbox.add_child(hint)


func _input(event: InputEvent) -> void:
	if not is_inside_tree():
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
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		SFXManager.play_sfx("menu_open")
		focused_index = 0
		button_list[0].grab_focus()


func _on_resume() -> void:
	SFXManager.play_sfx("menu_close")
	is_paused = false
	get_tree().paused = false
	panel.visible = false
	save_confirmation_label.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_save_game() -> void:
	var success: bool = _save_house_state()
	if success:
		_show_save_confirmation()
		SFXManager.play_sfx("select")
	else:
		# Show error briefly
		save_confirmation_label.text = "Save Failed!"
		save_confirmation_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5, 1))
		save_confirmation_label.visible = true
		_start_confirmation_timer()


func _on_quit() -> void:
	get_tree().paused = false
	get_tree().quit()


# ============================================================================
# House Save System
# ============================================================================

## Save the house state to slot 1 (the default save slot).
## This writes a save file that marks the player as being in the house,
## so loading this save will transition directly to the house scene.
func _save_house_state() -> bool:
	# Ensure save directory exists
	var dir: DirAccess = DirAccess.open("user://")
	if dir and not dir.dir_exists("saves"):
		dir.make_dir("saves")

	var save_data: Dictionary = _collect_house_save_data()
	var filepath: String = SAVE_DIR + "save_slot_1.json"
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

	# Preserve trail progression state from GameState
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state:
		data["trail"] = {
			"carved_tree_found": game_state.trail_carved_tree_found,
			"stone_cairn_found": game_state.trail_stone_cairn_found,
			"signpost_found": game_state.trail_signpost_found,
		}

	return data


## Show the "Game Saved!" confirmation and auto-hide after 2 seconds.
func _show_save_confirmation() -> void:
	save_confirmation_label.text = "Game Saved!"
	save_confirmation_label.add_theme_color_override("font_color", Color(0.6, 1, 0.6, 1))
	save_confirmation_label.visible = true
	_start_confirmation_timer()


## Start a 2-second timer to hide the confirmation label.
func _start_confirmation_timer() -> void:
	# Use a SceneTreeTimer so it works while paused (process_mode handled by PROCESS_MODE_ALWAYS)
	var timer: SceneTreeTimer = get_tree().create_timer(2.0, true, false, true)
	timer.timeout.connect(_hide_save_confirmation)


## Hide the save confirmation label.
func _hide_save_confirmation() -> void:
	if is_instance_valid(save_confirmation_label):
		save_confirmation_label.visible = false
