extends CanvasLayer
## Simplified pause menu for the house scene.
## Only Resume and Quit — no save/load or return-to-camp.

const HUD_FONT: Font = preload("res://resources/hud_font.tres")

var is_paused: bool = false
var panel: PanelContainer
var button_list: Array[Button] = []
var focused_index: int = 0


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

	var vbox: VBoxContainer = VBoxContainer.new()
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

	# Quit button
	var quit_btn: Button = Button.new()
	quit_btn.text = "Quit to Desktop"
	quit_btn.add_theme_font_override("font", HUD_FONT)
	quit_btn.add_theme_font_size_override("font_size", 36)
	quit_btn.focus_mode = Control.FOCUS_ALL
	quit_btn.pressed.connect(_on_quit)
	vbox.add_child(quit_btn)
	button_list.append(quit_btn)

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
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_quit() -> void:
	get_tree().paused = false
	get_tree().quit()
