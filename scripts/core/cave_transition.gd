extends Node
## Autoload singleton for managing cave scene transitions.

signal cave_entered(cave_id: int, cave_type: String)
signal cave_exited()
signal transition_started()
signal transition_completed()

# State tracking
var return_position: Vector3 = Vector3.ZERO
var return_rotation: float = 0.0
var cave_entrance_position: Vector3 = Vector3.ZERO
var cave_entrance_rotation_y: float = 0.0
var overworld_seed: int = 0
var current_cave_id: int = -1
var current_cave_type: String = ""
var is_in_cave: bool = false

# Player, HUD, and PauseMenu preserved across scene transitions
var stored_player: Node = null
var stored_hud: Node = null
var stored_pause_menu: Node = null

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
func enter_cave(cave_id: int, cave_type: String, player: Node, entrance_pos: Vector3 = Vector3.ZERO, entrance_rot_y: float = 0.0) -> void:
	if is_in_cave:
		print("[CaveTransition] Already in a cave!")
		return

	print("[CaveTransition] Entering %s cave #%d" % [cave_type, cave_id])

	# Store return position (player pos as fallback) and cave entrance position
	return_position = player.global_position
	return_rotation = player.rotation.y
	cave_entrance_position = entrance_pos
	cave_entrance_rotation_y = entrance_rot_y
	current_cave_id = cave_id
	current_cave_type = cave_type

	# Store the overworld seed so we can restore it when exiting the cave
	var chunk_manager: Node = get_tree().current_scene.get_node_or_null("World/Terrain")
	if chunk_manager and "noise_seed" in chunk_manager:
		overworld_seed = chunk_manager.noise_seed
		print("[CaveTransition] Stored overworld seed: %d" % overworld_seed)

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

	var tree: SceneTree = get_tree()

	var main_root: Node = tree.current_scene

	# Auto-save to a temporary file BEFORE removing anything so SaveLoad reads
	# correct state. This does NOT touch the player's save slots.
	if main_root:
		var save_load: Node = main_root.get_node_or_null("SaveLoad")
		if save_load and save_load.has_method("save_cave_autosave"):
			save_load.save_cave_autosave()
			print("[CaveTransition] Cave autosave created")

	# Remove player and HUD from current scene before scene change so they
	# aren't freed. This preserves inventory, stats, equipment, and UI state.
	var player: Node = tree.get_first_node_in_group("player")
	if player:
		player.get_parent().remove_child(player)
		stored_player = player
		print("[CaveTransition] Player preserved for cave transition")

	if main_root:
		var hud: Node = main_root.get_node_or_null("HUD")
		if hud:
			hud.get_parent().remove_child(hud)
			stored_hud = hud
			print("[CaveTransition] HUD preserved for cave transition")

		var pause_menu: Node = main_root.get_node_or_null("PauseMenu")
		if pause_menu:
			pause_menu.get_parent().remove_child(pause_menu)
			stored_pause_menu = pause_menu
			print("[CaveTransition] PauseMenu preserved for cave transition")

	# Change scene (player/HUD/PauseMenu won't be freed since they're no longer in the tree)
	var error: Error = tree.change_scene_to_packed(cave_scene)
	if error != OK:
		print("[CaveTransition] Failed to change scene: %d" % error)
		_fade_back()
		return

	is_in_cave = true
	cave_entered.emit(cave_id, cave_type)

	# Wait for cave scene to fully load (change_scene_to_packed is deferred,
	# needs two frames for current_scene to be valid)
	await tree.process_frame
	await tree.process_frame

	# Add preserved player and HUD to cave scene
	var cave_root: Node = tree.current_scene
	if cave_root:
		if stored_player:
			var spawn: Marker3D = cave_root.get_node_or_null("PlayerSpawn") as Marker3D
			if spawn:
				stored_player.global_position = spawn.global_position
			else:
				stored_player.global_position = Vector3(0, 1, 15)
			cave_root.add_child(stored_player)
			print("[CaveTransition] Player added to cave at %s" % stored_player.global_position)
			stored_player = null

		if stored_hud:
			cave_root.add_child(stored_hud)
			print("[CaveTransition] HUD added to cave scene")
			stored_hud = null

		if stored_pause_menu:
			cave_root.add_child(stored_pause_menu)
			print("[CaveTransition] PauseMenu added to cave scene")
			stored_pause_menu = null
	else:
		print("[CaveTransition] ERROR: cave scene not ready")
		if stored_player:
			stored_player.queue_free()
			stored_player = null
		if stored_hud:
			stored_hud.queue_free()
			stored_hud = null
		if stored_pause_menu:
			stored_pause_menu.queue_free()
			stored_pause_menu = null

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
	var main_scene_path: String = "res://scenes/main.tscn"
	var tree: SceneTree = get_tree()

	# Remove player and HUD from cave scene to preserve state
	var player: Node = tree.get_first_node_in_group("player")
	if player:
		player.get_parent().remove_child(player)
		stored_player = player
		print("[CaveTransition] Player preserved for overworld return")

	var cave_root: Node = tree.current_scene
	if cave_root:
		var hud: Node = cave_root.get_node_or_null("HUD")
		if hud:
			hud.get_parent().remove_child(hud)
			stored_hud = hud
			print("[CaveTransition] HUD preserved for overworld return")

		var pause_menu: Node = cave_root.get_node_or_null("PauseMenu")
		if pause_menu:
			pause_menu.get_parent().remove_child(pause_menu)
			stored_pause_menu = pause_menu
			print("[CaveTransition] PauseMenu preserved for overworld return")

	# Tell SaveLoad to load the cave autosave (temp file, not a user slot)
	# when the main scene initializes. This restores world state (campsite level,
	# structures, time, weather) while skipping player data so the preserved
	# player keeps any items gained in the cave.
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state:
		game_state.pending_cave_autosave = true
		game_state.skip_player_data_on_load = true
		# Restore the overworld seed so ChunkManager generates the same world
		if overworld_seed != 0:
			game_state.set_pending_world_seed(overworld_seed)
			print("[CaveTransition] Restoring overworld seed: %d" % overworld_seed)
		print("[CaveTransition] Set pending cave autosave load for world state restore")

	var error: Error = tree.change_scene_to_file(main_scene_path)
	if error != OK:
		print("[CaveTransition] Failed to return to main scene: %d" % error)
		_fade_back()
		return

	is_in_cave = false
	current_cave_id = -1
	current_cave_type = ""

	cave_exited.emit()

	# Wait for scene to load, then restore player
	await tree.process_frame
	await tree.process_frame
	_restore_player_position()
	_fade_back()


func _restore_player_position() -> void:
	var tree: SceneTree = get_tree()
	var main_root: Node = tree.current_scene
	if not main_root:
		print("[CaveTransition] ERROR: main scene not ready")
		return

	# Calculate safe spawn position: in front of cave entrance, on top of terrain
	var safe_pos: Vector3 = _get_safe_return_position()

	# Face the player away from the cave entrance (+Z direction of entrance)
	var exit_rotation: float = cave_entrance_rotation_y if cave_entrance_position != Vector3.ZERO else return_rotation

	if stored_player:
		# Replace the fresh player from main.tscn with our preserved one
		# (keeps cave-gained inventory/stats intact)
		var fresh_player: Node = tree.get_first_node_in_group("player")
		if fresh_player:
			fresh_player.get_parent().remove_child(fresh_player)
			fresh_player.queue_free()

		stored_player.global_position = safe_pos
		stored_player.rotation.y = exit_rotation
		main_root.add_child(stored_player)
		print("[CaveTransition] Preserved player restored at %s facing away from cave" % stored_player.global_position)
		stored_player = null
	else:
		# Fallback: just reposition existing player
		var player: Node = tree.get_first_node_in_group("player")
		if player:
			player.global_position = safe_pos
			player.rotation.y = exit_rotation
			print("[CaveTransition] Player position restored")

	if stored_hud:
		# Replace the fresh HUD from main.tscn with our preserved one
		var fresh_hud: Node = main_root.get_node_or_null("HUD")
		if fresh_hud:
			fresh_hud.get_parent().remove_child(fresh_hud)
			fresh_hud.queue_free()

		main_root.add_child(stored_hud)
		print("[CaveTransition] Preserved HUD restored")
		stored_hud = null

	if stored_pause_menu:
		var fresh_pause: Node = main_root.get_node_or_null("PauseMenu")
		if fresh_pause:
			fresh_pause.get_parent().remove_child(fresh_pause)
			fresh_pause.queue_free()

		main_root.add_child(stored_pause_menu)
		print("[CaveTransition] Preserved PauseMenu restored")
		stored_pause_menu = null


func _get_safe_return_position() -> Vector3:
	## Place the player right in front of the cave entrance, facing away.
	## The cave entrance faces +Z in local space, so we offset in its forward
	## direction to place the player outside the mouth.
	var pos: Vector3

	if cave_entrance_position != Vector3.ZERO:
		# Calculate the cave entrance's forward direction (+Z in local space)
		var forward: Vector3 = Vector3(sin(cave_entrance_rotation_y), 0, cos(cave_entrance_rotation_y))
		# Place player 5 units in front of the cave mouth
		pos = cave_entrance_position + forward * 5.0
		print("[CaveTransition] Spawning in front of cave entrance at (%.1f, %.1f, %.1f)" % [pos.x, pos.y, pos.z])
	else:
		# Fallback to stored player position
		pos = return_position
		print("[CaveTransition] No cave entrance pos stored, using return_position")

	# Query ChunkManager for the real terrain height at this position
	var chunk_manager: Node = get_tree().current_scene.get_node_or_null("World/Terrain")
	if chunk_manager and chunk_manager.has_method("get_height_at"):
		var terrain_y: float = chunk_manager.get_height_at(pos.x, pos.z)
		pos.y = terrain_y + 1.5
		print("[CaveTransition] Terrain height at return pos: %.1f, placing player at y=%.1f" % [terrain_y, pos.y])
	else:
		pos.y = return_position.y + 3.0
		print("[CaveTransition] No ChunkManager found, using fallback y=%.1f" % pos.y)

	return pos


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
		"return_rotation": return_rotation,
		"cave_entrance_position": {"x": cave_entrance_position.x, "y": cave_entrance_position.y, "z": cave_entrance_position.z},
		"cave_entrance_rotation_y": cave_entrance_rotation_y,
		"overworld_seed": overworld_seed
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

	var epos: Dictionary = data.get("cave_entrance_position", {})
	cave_entrance_position = Vector3(
		epos.get("x", 0.0),
		epos.get("y", 0.0),
		epos.get("z", 0.0)
	)
	cave_entrance_rotation_y = data.get("cave_entrance_rotation_y", 0.0)
	overworld_seed = data.get("overworld_seed", 0)
