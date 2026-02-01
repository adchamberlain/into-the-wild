extends CanvasLayer
## Pause menu that freezes the game and shows pause UI.

signal game_resumed()
signal game_quit()

@export var save_load_path: NodePath

@onready var panel: PanelContainer = $Panel
@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var save_button: Button = $Panel/VBoxContainer/SaveButton
@onready var credits_button: Button = $Panel/VBoxContainer/CreditsButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton
@onready var credits_panel: PanelContainer = $CreditsPanel
@onready var back_button: Button = $CreditsPanel/VBoxContainer/BackButton

var save_load: Node

var is_paused: bool = false
var showing_credits: bool = false

# Controller navigation
var focused_button_index: int = 0
var button_list: Array[Button] = []


func _ready() -> void:
	# This node must process even when the tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Get save_load reference
	if save_load_path:
		save_load = get_node_or_null(save_load_path)
	if not save_load:
		# Try to find it in the scene
		var root: Node = get_tree().root
		if root.has_node("Main/SaveLoad"):
			save_load = root.get_node("Main/SaveLoad")

	# Start hidden
	panel.visible = false
	credits_panel.visible = false

	# Connect button signals
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	back_button.pressed.connect(_on_back_pressed)

	# Set up button list for controller navigation
	button_list = [resume_button, save_button, credits_button, quit_button]


func _input(event: InputEvent) -> void:
	# Handle pause action (Escape key or Options button) - can pause/unpause anytime
	if event.is_action_pressed("pause"):
		if showing_credits:
			_on_back_pressed()
		else:
			toggle_pause()
		get_viewport().set_input_as_handled()
		return

	# Handle ui_cancel (Circle button) - only when already paused, to avoid
	# conflicting with "unequip" action which also uses Circle
	if event.is_action_pressed("ui_cancel") and is_paused:
		if showing_credits:
			_on_back_pressed()
		else:
			resume_game()
		get_viewport().set_input_as_handled()
		return

	# D-pad navigation when paused
	if is_paused and not showing_credits:
		if event.is_action_pressed("ui_down"):
			_navigate_buttons(1)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("ui_up"):
			_navigate_buttons(-1)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("ui_accept"):
			_activate_focused_button()
			get_viewport().set_input_as_handled()
			return


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

	# Focus first button for controller navigation
	focused_button_index = 0
	resume_button.grab_focus()


func resume_game() -> void:
	is_paused = false
	showing_credits = false
	get_tree().paused = false
	panel.visible = false
	credits_panel.visible = false
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


func _on_quit_pressed() -> void:
	# Unpause before quitting so cleanup can happen
	get_tree().paused = false
	game_quit.emit()
	get_tree().quit()


func _on_save_pressed() -> void:
	if save_load and save_load.has_method("save_game"):
		var success: bool = save_load.save_game()
		if success:
			_show_notification("Game Saved!", Color(0.6, 1.0, 0.6))
		else:
			_show_notification("Save Failed!", Color(1.0, 0.5, 0.5))
	else:
		_show_notification("Save system not found!", Color(1.0, 0.5, 0.5))


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
