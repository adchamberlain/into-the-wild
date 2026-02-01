extends CanvasLayer
## Pause menu that freezes the game and shows pause UI.

signal game_resumed()
signal game_quit()

@onready var panel: PanelContainer = $Panel
@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton

var is_paused: bool = false


func _ready() -> void:
	# This node must process even when the tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Start hidden
	panel.visible = false

	# Connect button signals
	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action("ui_cancel"):
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
	get_tree().paused = false
	panel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	game_resumed.emit()


func _on_resume_pressed() -> void:
	resume_game()


func _on_quit_pressed() -> void:
	# Unpause before quitting so cleanup can happen
	get_tree().paused = false
	game_quit.emit()
	get_tree().quit()
