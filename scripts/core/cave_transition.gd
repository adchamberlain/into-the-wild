extends Node
## Autoload singleton for managing cave scene transitions.

signal cave_entered(cave_id: int, cave_type: String)
signal cave_exited()
signal transition_started()
signal transition_completed()

# State tracking
var return_position: Vector3 = Vector3.ZERO
var return_rotation: float = 0.0
var current_cave_id: int = -1
var current_cave_type: String = ""
var is_in_cave: bool = false

# Transition settings
var fade_duration: float = 0.5

# Scene paths
const CAVE_SCENES: Dictionary = {
	"small": "res://scenes/caves/cave_interior_small.tscn",
	"medium": "res://scenes/caves/cave_interior_medium.tscn"
}

# Reference to fade overlay
var fade_overlay: ColorRect = null
var fade_canvas: CanvasLayer = null


func _ready() -> void:
	# Create fade overlay for transitions
	_create_fade_overlay()


func _create_fade_overlay() -> void:
	fade_canvas = CanvasLayer.new()
	fade_canvas.layer = 100  # On top of everything
	add_child(fade_canvas)

	fade_overlay = ColorRect.new()
	fade_overlay.color = Color(0, 0, 0, 0)  # Start transparent
	fade_overlay.anchors_preset = Control.PRESET_FULL_RECT
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_canvas.add_child(fade_overlay)


## Enter a cave from the overworld.
func enter_cave(cave_id: int, cave_type: String, player: Node) -> void:
	if is_in_cave:
		print("[CaveTransition] Already in a cave!")
		return

	print("[CaveTransition] Entering %s cave #%d" % [cave_type, cave_id])

	# Store return position
	return_position = player.global_position
	return_rotation = player.rotation.y
	current_cave_id = cave_id
	current_cave_type = cave_type

	# Check if cave scene exists
	var scene_path: String = CAVE_SCENES.get(cave_type, "")
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		print("[CaveTransition] Cave scene not found: %s" % scene_path)
		_show_placeholder_cave(player)
		return

	transition_started.emit()

	# Fade to black
	var tween: Tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, fade_duration)
	tween.tween_callback(_load_cave_scene.bind(cave_id, cave_type, scene_path))


func _load_cave_scene(cave_id: int, cave_type: String, scene_path: String) -> void:
	# Load and switch to cave scene
	var cave_scene: PackedScene = load(scene_path)
	if not cave_scene:
		print("[CaveTransition] Failed to load cave scene")
		_fade_back()
		return

	# Get current scene tree
	var tree: SceneTree = get_tree()
	var current_scene: Node = tree.current_scene

	# Store reference to main scene for returning
	# Note: The main scene will be freed, but we can recreate it

	# Change scene
	var error: Error = tree.change_scene_to_packed(cave_scene)
	if error != OK:
		print("[CaveTransition] Failed to change scene: %d" % error)
		_fade_back()
		return

	is_in_cave = true
	cave_entered.emit(cave_id, cave_type)

	# Fade back in after scene loads
	await tree.process_frame
	await tree.process_frame
	_fade_back()


func _fade_back() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, fade_duration)
	tween.tween_callback(func(): transition_completed.emit())


## Exit the current cave and return to overworld.
func exit_cave() -> void:
	if not is_in_cave:
		print("[CaveTransition] Not in a cave!")
		return

	print("[CaveTransition] Exiting cave, returning to (%.1f, %.1f, %.1f)" % [
		return_position.x, return_position.y, return_position.z
	])

	transition_started.emit()

	# Fade to black
	var tween: Tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, fade_duration)
	tween.tween_callback(_return_to_overworld)


func _return_to_overworld() -> void:
	# Load main scene
	var main_scene_path: String = "res://scenes/main.tscn"
	var tree: SceneTree = get_tree()

	var error: Error = tree.change_scene_to_file(main_scene_path)
	if error != OK:
		print("[CaveTransition] Failed to return to main scene: %d" % error)
		_fade_back()
		return

	is_in_cave = false
	current_cave_id = -1
	current_cave_type = ""

	cave_exited.emit()

	# Wait for scene to load, then restore player position
	await tree.process_frame
	await tree.process_frame
	_restore_player_position()
	_fade_back()


func _restore_player_position() -> void:
	# Find player in new scene and restore position
	var player: Node = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = return_position + Vector3(0, 0.5, 0)  # Slight offset to avoid clipping
		player.rotation.y = return_rotation
		print("[CaveTransition] Player position restored")


## Placeholder cave effect when scene doesn't exist yet.
func _show_placeholder_cave(player: Node) -> void:
	is_in_cave = true

	# Show a notification about entering the cave
	var hud: Node = get_tree().root.get_node_or_null("Main/HUD")
	if hud and hud.has_method("show_notification"):
		hud.show_notification("You enter the dark cave... (placeholder)", Color(0.6, 0.6, 0.8))

	cave_entered.emit(current_cave_id, current_cave_type)

	# For now, just darken the screen temporarily
	fade_overlay.color = Color(0, 0, 0, 0.85)

	# Auto-exit after a few seconds (placeholder behavior)
	await get_tree().create_timer(3.0).timeout

	if hud and hud.has_method("show_notification"):
		hud.show_notification("You find nothing and leave the cave.", Color(0.7, 0.7, 0.7))

	fade_overlay.color = Color(0, 0, 0, 0)
	is_in_cave = false
	current_cave_id = -1
	current_cave_type = ""
	cave_exited.emit()


## Check if player is currently in a cave.
func is_player_in_cave() -> bool:
	return is_in_cave


## Get current cave ID (-1 if not in cave).
func get_current_cave_id() -> int:
	return current_cave_id


## Get current cave type (empty if not in cave).
func get_current_cave_type() -> String:
	return current_cave_type


## Get save data for persistence.
func get_save_data() -> Dictionary:
	return {
		"is_in_cave": is_in_cave,
		"current_cave_id": current_cave_id,
		"current_cave_type": current_cave_type,
		"return_position": {"x": return_position.x, "y": return_position.y, "z": return_position.z},
		"return_rotation": return_rotation
	}


## Load save data.
func load_save_data(data: Dictionary) -> void:
	is_in_cave = data.get("is_in_cave", false)
	current_cave_id = data.get("current_cave_id", -1)
	current_cave_type = data.get("current_cave_type", "")

	var pos: Dictionary = data.get("return_position", {})
	return_position = Vector3(
		pos.get("x", 0.0),
		pos.get("y", 0.0),
		pos.get("z", 0.0)
	)
	return_rotation = data.get("return_rotation", 0.0)
