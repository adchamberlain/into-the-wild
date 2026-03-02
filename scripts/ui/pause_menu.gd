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
@onready var return_to_camp_button: Button = $Panel/VBoxContainer/ReturnToCampButton
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

# Confirmation dialog
var confirm_panel: PanelContainer
var confirm_label: Label
var confirm_buttons: Array[Button] = []
var showing_confirm: bool = false
var confirm_action: String = ""  # "overwrite" or "delete"
var confirm_slot: int = 0
var focused_confirm_index: int = 0
var delete_buttons: Array[Button] = []


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
	return_to_camp_button.pressed.connect(_on_return_to_camp_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	back_button.pressed.connect(_on_back_pressed)

	# Set up button list for controller navigation
	button_list = [resume_button, save_button, load_button, settings_button, return_to_camp_button, credits_button, quit_button]

	# Create slot selection panel and confirmation dialog
	_create_slot_panel()
	_create_confirm_panel()


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
	# Skip if the journal is open — let it handle its own close
	if event.is_action_pressed("pause"):
		if not is_paused and _is_journal_open():
			return
		if showing_credits:
			_on_back_pressed()
		else:
			toggle_pause()
		_handle_input()
		return

	# Handle ui_cancel (Circle button) - only when already paused AND panel visible
	# (not when config menu is open), to avoid conflicting with other menus
	if event.is_action_pressed("ui_cancel") and is_paused and showing_confirm:
		_hide_confirm_panel()
		_handle_input()
		return

	if event.is_action_pressed("ui_cancel") and is_paused and panel.visible:
		if showing_slots:
			_hide_slot_panel()
		elif showing_credits:
			_on_back_pressed()
		else:
			resume_game()
		_handle_input()
		return

	# D-pad navigation for confirmation dialog
	if is_paused and showing_confirm:
		if event.is_action_pressed("ui_down"):
			_navigate_confirm_buttons(1)
			_handle_input()
			return
		if event.is_action_pressed("ui_up"):
			_navigate_confirm_buttons(-1)
			_handle_input()
			return
		if event.is_action_pressed("ui_accept"):
			_activate_focused_confirm_button()
			_handle_input()
			return
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


func _is_journal_open() -> bool:
	for node in get_tree().get_nodes_in_group("journal_ui"):
		if "_is_open" in node and node._is_open:
			return true
	return false


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
		hint_label.text = "[✕ to resume]"
	else:
		hint_label.text = "[ESC to resume]"


func resume_game() -> void:
	if not is_inside_tree():
		return
	is_paused = false
	showing_credits = false
	showing_slots = false
	showing_confirm = false
	get_tree().paused = false
	panel.visible = false
	credits_panel.visible = false
	if slot_panel:
		slot_panel.visible = false
	if confirm_panel:
		confirm_panel.visible = false
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


func _on_return_to_camp_pressed() -> void:
	# Teleport the player back to camp (spawn point) instead of loading a save.
	# This avoids crashes from loading a different world's save slot.
	var player: Node3D = get_tree().get_first_node_in_group("player") as Node3D
	if not player:
		_show_notification("Player not found!", Color(1.0, 0.5, 0.5))
		return

	# Exit cave if the player is in one
	var cave_transition: Node = get_node_or_null("/root/CaveTransition")
	if cave_transition and cave_transition.is_in_cave:
		cave_transition.player_exited_cave()

	# Teleport to shelter respawn point (highest-priority shelter), or origin if none
	var camp_pos: Vector3 = Vector3.ZERO
	if "respawn_position" in player and "has_respawn_shelter" in player and player.has_respawn_shelter:
		camp_pos = player.respawn_position
	else:
		var chunk_mgr: Node = get_tree().root.get_node_or_null("Main/World/Terrain")
		if chunk_mgr and chunk_mgr.has_method("get_height_at"):
			camp_pos.y = chunk_mgr.get_height_at(0.0, 0.0) + 1.0
		else:
			camp_pos.y = 1.0
	player.global_position = camp_pos

	_show_notification("Returned to camp", Color(0.6, 1.0, 0.6))
	resume_game()


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
	if not is_inside_tree():
		return null
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

	# Create 5 slot buttons with delete buttons
	for i: int in range(5):
		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		vbox.add_child(hbox)

		var btn: Button = Button.new()
		btn.name = "Slot%dButton" % (i + 1)
		btn.text = "Slot %d: Empty" % (i + 1)
		btn.add_theme_font_override("font", font)
		btn.add_theme_font_size_override("font_size", 32)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.focus_mode = Control.FOCUS_ALL
		btn.pressed.connect(_on_slot_button_pressed.bind(i + 1))
		hbox.add_child(btn)
		slot_buttons.append(btn)

		var del_btn: Button = Button.new()
		del_btn.name = "Del%dButton" % (i + 1)
		del_btn.text = "Del"
		del_btn.add_theme_font_override("font", font)
		del_btn.add_theme_font_size_override("font_size", 24)
		del_btn.custom_minimum_size = Vector2(60, 0)
		del_btn.focus_mode = Control.FOCUS_ALL
		del_btn.pressed.connect(_show_confirm.bind("delete", i + 1))
		del_btn.visible = false
		hbox.add_child(del_btn)
		delete_buttons.append(del_btn)

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
	for i: int in range(min(5, slot_buttons.size() - 1)):  # -1 to exclude cancel button
		var btn: Button = slot_buttons[i]
		var info: Dictionary = slots_info[i]
		if info["empty"]:
			btn.text = "Slot %d: Empty" % (i + 1)
			btn.disabled = not is_saving  # Can't load empty slots
			if i < delete_buttons.size():
				delete_buttons[i].visible = false
		else:
			btn.text = "Slot %d: Level %d - %s" % [i + 1, info["campsite_level"], info["formatted_time"]]
			btn.disabled = false
			if i < delete_buttons.size():
				delete_buttons[i].visible = true


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
		# Check if slot is occupied — confirm before overwriting
		if save_load and save_load.has_method("has_save_slot") and save_load.has_save_slot(slot):
			_show_confirm("overwrite", slot)
			return
		# Empty slot — save directly
		if save_load and save_load.has_method("save_game_slot"):
			var success: bool = save_load.save_game_slot(slot)
			if success:
				_show_notification("Saved to Slot %d!" % slot, Color(0.6, 1.0, 0.6))
			else:
				_show_notification("Save Failed!", Color(1.0, 0.5, 0.5))
		_hide_slot_panel()
	else:
		if save_load and save_load.has_method("load_game_slot"):
			# Close menu and load - resume AFTER load so game stays paused if load fails
			_hide_slot_panel()
			var success: bool = await save_load.load_game_slot(slot)
			if success:
				resume_game()
			else:
				_show_notification("Load Failed!", Color(1.0, 0.5, 0.5))
				panel.visible = true


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


# ============================================================================
# Confirmation Dialog
# ============================================================================

## Create the confirmation dialog panel programmatically.
func _create_confirm_panel() -> void:
	confirm_panel = PanelContainer.new()
	confirm_panel.name = "ConfirmPanel"
	confirm_panel.process_mode = Node.PROCESS_MODE_ALWAYS

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
	confirm_panel.add_theme_stylebox_override("panel", style)

	# Center the panel
	confirm_panel.anchors_preset = Control.PRESET_CENTER
	confirm_panel.anchor_left = 0.5
	confirm_panel.anchor_top = 0.5
	confirm_panel.anchor_right = 0.5
	confirm_panel.anchor_bottom = 0.5
	confirm_panel.offset_left = -180
	confirm_panel.offset_top = -100
	confirm_panel.offset_right = 180
	confirm_panel.offset_bottom = 100
	confirm_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	confirm_panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	confirm_panel.add_child(vbox)

	var font: Font = load("res://resources/hud_font.tres")

	# Title label
	confirm_label = Label.new()
	confirm_label.name = "ConfirmTitle"
	confirm_label.text = "Overwrite Slot?"
	confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_label.add_theme_font_override("font", font)
	confirm_label.add_theme_font_size_override("font_size", 40)
	confirm_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))
	vbox.add_child(confirm_label)

	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)

	# Yes button
	var yes_btn: Button = Button.new()
	yes_btn.name = "YesButton"
	yes_btn.text = "Yes"
	yes_btn.add_theme_font_override("font", font)
	yes_btn.add_theme_font_size_override("font_size", 32)
	yes_btn.focus_mode = Control.FOCUS_ALL
	yes_btn.pressed.connect(_on_confirm_yes)
	vbox.add_child(yes_btn)
	confirm_buttons.append(yes_btn)

	# No button
	var no_btn: Button = Button.new()
	no_btn.name = "NoButton"
	no_btn.text = "No"
	no_btn.add_theme_font_override("font", font)
	no_btn.add_theme_font_size_override("font_size", 32)
	no_btn.focus_mode = Control.FOCUS_ALL
	no_btn.pressed.connect(_on_confirm_no)
	vbox.add_child(no_btn)
	confirm_buttons.append(no_btn)

	add_child(confirm_panel)
	confirm_panel.visible = false


## Show the confirmation dialog.
func _show_confirm(action: String, slot: int) -> void:
	confirm_action = action
	confirm_slot = slot
	showing_confirm = true

	if action == "overwrite":
		confirm_label.text = "Overwrite Slot %d?" % slot
	else:
		confirm_label.text = "Delete Slot %d save?" % slot

	slot_panel.visible = false
	confirm_panel.visible = true

	# Default focus on "No" for safety
	focused_confirm_index = 1
	confirm_buttons[1].grab_focus()


## Hide the confirmation dialog and return to slot panel.
func _hide_confirm_panel() -> void:
	showing_confirm = false
	confirm_panel.visible = false
	slot_panel.visible = true
	# Restore focus to the slot that was selected
	var idx: int = confirm_slot - 1
	if idx >= 0 and idx < slot_buttons.size():
		focused_slot_index = idx
		slot_buttons[idx].grab_focus()


## Handle confirm "Yes" press.
func _on_confirm_yes() -> void:
	if confirm_action == "overwrite":
		if save_load and save_load.has_method("save_game_slot"):
			var success: bool = save_load.save_game_slot(confirm_slot)
			if success:
				_show_notification("Saved to Slot %d!" % confirm_slot, Color(0.6, 1.0, 0.6))
			else:
				_show_notification("Save Failed!", Color(1.0, 0.5, 0.5))
		showing_confirm = false
		confirm_panel.visible = false
		_hide_slot_panel()
	elif confirm_action == "delete":
		if save_load and save_load.has_method("delete_save_slot"):
			var success: bool = save_load.delete_save_slot(confirm_slot)
			if success:
				_show_notification("Slot %d deleted" % confirm_slot, Color(0.6, 1.0, 0.6))
			else:
				_show_notification("Delete Failed!", Color(1.0, 0.5, 0.5))
		showing_confirm = false
		confirm_panel.visible = false
		_update_slot_panel()
		slot_panel.visible = true
		# Re-focus the slot
		var idx: int = confirm_slot - 1
		if idx >= 0 and idx < slot_buttons.size():
			focused_slot_index = idx
			slot_buttons[idx].grab_focus()


## Handle confirm "No" press.
func _on_confirm_no() -> void:
	_hide_confirm_panel()


## Navigate confirm buttons with D-pad.
func _navigate_confirm_buttons(direction: int) -> void:
	if confirm_buttons.is_empty():
		return
	focused_confirm_index = (focused_confirm_index + direction) % confirm_buttons.size()
	if focused_confirm_index < 0:
		focused_confirm_index = confirm_buttons.size() - 1
	confirm_buttons[focused_confirm_index].grab_focus()


## Activate the focused confirm button.
func _activate_focused_confirm_button() -> void:
	if focused_confirm_index >= 0 and focused_confirm_index < confirm_buttons.size():
		confirm_buttons[focused_confirm_index].pressed.emit()
