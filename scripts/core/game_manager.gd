extends Node
## Global game state manager. Autoload singleton.

signal game_started
signal game_paused
signal game_resumed

var is_paused: bool = false


func _ready() -> void:
	pass


func pause_game() -> void:
	is_paused = true
	get_tree().paused = true
	game_paused.emit()


func resume_game() -> void:
	is_paused = false
	get_tree().paused = false
	game_resumed.emit()


func toggle_pause() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()
