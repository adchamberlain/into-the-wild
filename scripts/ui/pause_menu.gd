extends CanvasLayer
## Pause menu that freezes the game and shows pause UI.

signal game_resumed()
signal game_quit()

@export var save_load_path: NodePath

@onready var panel: PanelContainer = $Panel
@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var save_button: Button = $Panel/VBoxContainer/SaveButton
@onready var load_button: Button = $Panel/VBoxContainer/LoadButton
@onready var settings_button: Button = $Panel/VBoxContainer/SettingsButton
@onready var credits_button: Button = $Panel/VBoxContainer/CreditsButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton
@onready var hint_label: Label = $Panel/VBoxContainer/HintLabel
@onready var credits_panel: PanelContainer = $CreditsPanel
@onready var back_button: Button = $CreditsPanel/VBoxContainer/BackButton

var save_load: Node
var config_menu: Node

var is_paused: bool = false
var showing_credits: bool = false
var showing_slots: bool = false

# Controller navigation
var focused_button_index: int = 0
var button_list: Array[Button] = []

# Slot selection panel
var slot_panel: PanelContainer
var slot_buttons: Array[Button] = []
var focused_slot_index: int = 0
var is_saving: bool = true  # true = save mode, false = load mode


func _ready() -> void:
	# This node must process even when the tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Resolve references
	_resolve_references()

	# Start hidden
	panel.visible = false
	credits_panel.visible = false

	# Connect button signals
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	back_button.pressed.connect(_on_back_pressed)

	# Set up button list for controller navigation
	button_list = [resume_button, save_button, load_button, settings_button, credits_button, quit_button]

	# Create slot selection panel
	_create_slot_panel()


func _enter_tree() -> void:
	# Re-resolve references when re-added to the tree (e.g., after cave transitions
	# preserve and re-add this node — _ready() only runs once).
	call_deferred("_resolve_references")


func _resolve_references() -> void:
	if save_load_path:
		save_load = get_node_or_null(save_load_path)
	if not save_load:
		var root: Node = get_tree().root
		if root.has_node("Main/SaveLoad"):
			save_load = root.get_node("Main/SaveLoad")

	var root: Node = get_tree().root
	if root.has_node("Main/ConfigMenu"):
		config_menu = root.get_node("Main/ConfigMenu")


func _input(event: InputEvent) -> void:
	# Don't process input if not in tree (prevents null viewport errors during scene transitions)
	if not is_inside_tree():
		return

	# Handle pause action (Escape key or Options button) - can pause/unpause anytime
	if event.is_action_pressed("pause"):
		if showing_credits:
			_on_back_pressed()
		else:
			toggle_pause()
		_handle_input()
		return

	# Handle ui_cancel (Circle button) - only when already paused AND panel visible
	# (not when config menu is open), to avoid conflicting with other menus
	if event.is_action_pressed("ui_cancel") and is_paused and panel.visible:
		if showing_slots:
			_hide_slot_panel()
		elif showing_credits:
			_on_back_pressed()
		else:
			resume_game()
		_handle_input()
		return

	# D-pad navigation for slot panel
	if is_paused and showing_slots:
		if event.is_action_pressed("ui_down"):
			_navigate_slot_buttons(1)
			_handle_input()
			return
		if event.is_action_pressed("ui_up"):
			_navigate_slot_buttons(-1)
			_handle_input()
			return
		if event.is_action_pressed("ui_accept"):
			_activate_focused_slot_button()
			_handle_input()
			return
		return

	# D-pad navigation when paused (only when pause panel is visible, not when settings open)
	if is_paused and not showing_credits and not showing_slots and panel.visible:
		if event.is_action_pressed("ui_down"):
			_navigate_buttons(1)
			_handle_input()
			return
		if event.is_action_pressed("ui_up"):
			_navigate_buttons(-1)
			_handle_input()
			return
		if event.is_action_pressed("ui_accept"):
			_activate_focused_button()
			_handle_input()
			return


func _handle_input() -> void:
	var vp: Viewport = get_viewport()
	if vp:
		vp.set_input_as_handled()


func toggle_pause() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()


func pause_game() -> void:
	is_paused = true
	get_tree().paused = true
	panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Update hint label based on input device
	_update_hint_label()

	# Focus first button for controller navigation
	focused_button_index = 0
	resume_button.grab_focus()


func _update_hint_label() -> void:
	if not hint_label:
		return
	var input_mgr: Node = get_node_or_null("/root/InputManager")
	if input_mgr and input_mgr.is_using_controller():
		hint_label.text = "[○ to resume]"
	else:
		hint_label.text = "[ESC to resume]"


func resume_game() -> void:
	is_paused = false
	showing_credits = false
	showing_slots = false
	get_tree().paused = false
	panel.visible = false
	credits_panel.visible = false
	if slot_panel:
		slot_panel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	game_resumed.emit()


func _on_resume_pressed() -> void:
	resume_game()


func _on_credits_pressed() -> void:
	showing_credits = true
	panel.visible = false
	credits_panel.visible = true
	back_button.grab_focus()


func _on_back_pressed() -> void:
	showing_credits = false
	credits_panel.visible = false
	panel.visible = true
	resume_button.grab_focus()


func _on_settings_pressed() -> void:
	if config_menu:
		# Hide pause menu and show config menu
		panel.visible = false
		if config_menu.has_method("show_menu"):
			config_menu.show_menu(true)  # true = opened from pause menu
		elif "panel" in config_menu:
			config_menu.panel.visible = true
			config_menu.is_visible = true


func _on_quit_pressed() -> void:
	# Unpause before quitting so cleanup can happen
	get_tree().paused = false
	game_quit.emit()
	get_tree().quit()


func _on_save_pressed() -> void:
	if not save_load:
		_show_notification("Save system not found!", Color(1.0, 0.5, 0.5))
		return

	is_saving = true
	_update_slot_panel()
	_show_slot_panel()


func _on_load_pressed() -> void:
	if not save_load:
		_show_notification("Save system not found!", Color(1.0, 0.5, 0.5))
		return

	is_saving = false
	_update_slot_panel()
	_show_slot_panel()


func _show_notification(message: String, color: Color) -> void:
	var hud: Node = _find_hud()
	if hud and hud.has_method("show_notification"):
		hud.show_notification(message, color)


func _find_hud() -> Node:
	var root: Node = get_tree().root
	if root.has_node("Main/HUD"):
		return root.get_node("Main/HUD")
	return null


## Navigate through buttons with D-pad.
func _navigate_buttons(direction: int) -> void:
	if button_list.is_empty():
		return

	focused_button_index = (focused_button_index + direction) % button_list.size()
	if focused_button_index < 0:
		focused_button_index = button_list.size() - 1

	var button: Button = button_list[focused_button_index]
	button.grab_focus()


## Activate the currently focused button.
func _activate_focused_button() -> void:
	if button_list.is_empty():
		return

	if focused_button_index >= 0 and focused_button_index < button_list.size():
		var button: Button = button_list[focused_button_index]
		if not button.disabled:
			button.pressed.emit()


# ============================================================================
# Slot Selection Panel
# ============================================================================

## Create the slot selection panel programmatically.
func _create_slot_panel() -> void:
	slot_panel = PanelContainer.new()
	slot_panel.name = "SlotPanel"
	slot_panel.process_mode = Node.PROCESS_MODE_ALWAYS

	# Match main panel styling
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12, 0.95)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 25
	style.content_margin_bottom = 25
	slot_panel.add_theme_stylebox_override("panel", style)

	# Center the panel
	slot_panel.anchors_preset = Control.PRESET_CENTER
	slot_panel.anchor_left = 0.5
	slot_panel.anchor_top = 0.5
	slot_panel.anchor_right = 0.5
	slot_panel.anchor_bottom = 0.5
	slot_panel.offset_left = -200
	slot_panel.offset_top = -180
	slot_panel.offset_right = 200
	slot_panel.offset_bottom = 180
	slot_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	slot_panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	slot_panel.add_child(vbox)

	# Title label
	var title_label: Label = Label.new()
	title_label.name = "SlotTitle"
	title_label.text = "Save to Slot"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var font: Font = load("res://resources/hud_font.tres")
	title_label.add_theme_font_override("font", font)
	title_label.add_theme_font_size_override("font_size", 40)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))
	vbox.add_child(title_label)

	# Separator
	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)

	# Create 3 slot buttons
	for i: int in range(3):
		var btn: Button = Button.new()
		btn.name = "Slot%dButton" % (i + 1)
		btn.text = "Slot %d: Empty" % (i + 1)
		btn.add_theme_font_override("font", font)
		btn.add_theme_font_size_override("font_size", 32)
		btn.focus_mode = Control.FOCUS_ALL
		btn.pressed.connect(_on_slot_button_pressed.bind(i + 1))
		vbox.add_child(btn)
		slot_buttons.append(btn)

	# Spacer
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	# Cancel button
	var cancel_btn: Button = Button.new()
	cancel_btn.name = "CancelButton"
	cancel_btn.text = "Cancel"
	cancel_btn.add_theme_font_override("font", font)
	cancel_btn.add_theme_font_size_override("font_size", 28)
	cancel_btn.focus_mode = Control.FOCUS_ALL
	cancel_btn.pressed.connect(_hide_slot_panel)
	vbox.add_child(cancel_btn)
	slot_buttons.append(cancel_btn)

	add_child(slot_panel)
	slot_panel.visible = false


## Update slot panel buttons with current save info.
func _update_slot_panel() -> void:
	if not slot_panel or not save_load:
		return

	# Update title based on mode
	var title: Label = slot_panel.get_node_or_null("VBoxContainer/SlotTitle")
	if title:
		title.text = "Save to Slot" if is_saving else "Load from Slot"

	var slots_info: Array[Dictionary] = save_load.get_all_slots_info()
	for i: int in range(min(3, slot_buttons.size() - 1)):  # -1 to exclude cancel button
		var btn: Button = slot_buttons[i]
		var info: Dictionary = slots_info[i]
		if info["empty"]:
			btn.text = "Slot %d: Empty" % (i + 1)
			btn.disabled = not is_saving  # Can't load empty slots
		else:
			btn.text = "Slot %d: Level %d - %s" % [i + 1, info["campsite_level"], info["formatted_time"]]
			btn.disabled = false


## Show the slot selection panel.
func _show_slot_panel() -> void:
	if slot_panel:
		showing_slots = true
		panel.visible = false
		slot_panel.visible = true
		# Focus first slot button (deferred to ensure visibility)
		focused_slot_index = 0
		call_deferred("_focus_first_slot")


## Hide the slot selection panel.
func _hide_slot_panel() -> void:
	if slot_panel:
		showing_slots = false
		slot_panel.visible = false
		panel.visible = true
		# Restore focus to save button
		focused_button_index = 1  # Save button index
		save_button.grab_focus()


## Handle slot button press.
func _on_slot_button_pressed(slot: int) -> void:
	if is_saving:
		if save_load and save_load.has_method("save_game_slot"):
			var success: bool = save_load.save_game_slot(slot)
			if success:
				_show_notification("Saved to Slot %d!" % slot, Color(0.6, 1.0, 0.6))
			else:
				_show_notification("Save Failed!", Color(1.0, 0.5, 0.5))
		_hide_slot_panel()
	else:
		if save_load and save_load.has_method("load_game_slot"):
			# Close menu before loading (loading will reset the game state)
			_hide_slot_panel()
			resume_game()
			save_load.load_game_slot(slot)


## Focus the first slot button (called deferred).
func _focus_first_slot() -> void:
	if not slot_buttons.is_empty():
		slot_buttons[0].grab_focus()


## Navigate slot buttons with D-pad.
func _navigate_slot_buttons(direction: int) -> void:
	if slot_buttons.is_empty():
		return

	focused_slot_index = (focused_slot_index + direction) % slot_buttons.size()
	if focused_slot_index < 0:
		focused_slot_index = slot_buttons.size() - 1

	slot_buttons[focused_slot_index].grab_focus()


## Activate the focused slot button.
func _activate_focused_slot_button() -> void:
	if slot_buttons.is_empty():
		return

	if focused_slot_index >= 0 and focused_slot_index < slot_buttons.size():
		var button: Button = slot_buttons[focused_slot_index]
		if not button.disabled:
			button.pressed.emit()
