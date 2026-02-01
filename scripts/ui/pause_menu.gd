extends CanvasLayer
## Pause menu that freezes the game and shows pause UI.

signal game_resumed()
signal game_quit()

@onready var panel: PanelContainer = $Panel
@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var credits_button: Button = $Panel/VBoxContainer/CreditsButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton
@onready var credits_panel: PanelContainer = $CreditsPanel
@onready var back_button: Button = $CreditsPanel/VBoxContainer/BackButton

var is_paused: bool = false
var showing_credits: bool = false


func _ready() -> void:
	# This node must process even when the tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Start hidden
	panel.visible = false
	credits_panel.visible = false

	# Connect button signals
	resume_button.pressed.connect(_on_resume_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	back_button.pressed.connect(_on_back_pressed)


func _input(event: InputEvent) -> void:
	# Handle pause toggle (Escape key or Options button)
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		if showing_credits:
			# Go back to pause menu from credits
			_on_back_pressed()
		else:
			toggle_pause()
		get_viewport().set_input_as_handled()


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

	# Focus resume button for keyboard navigation
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
