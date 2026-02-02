extends StructureBase
class_name StructureShelter
## Shelter structure that provides weather protection.

signal player_entered()
signal player_exited()
signal resting_started(player: Node)
signal resting_ended(player: Node)

# Shelter properties
@export var protection_radius: float = 3.0

# Resting position offset (relative to shelter)
@export var rest_position_offset: Vector3 = Vector3(0, 0.3, 0.2)
@export var rest_camera_rotation: Vector3 = Vector3(-70, 0, 0)  # Looking up at canvas

# State
var player_inside: bool = false
var is_player_resting: bool = false
var resting_player: Node = null
var player_original_position: Vector3
var player_original_rotation: Vector3
var player_camera_original_rotation: Vector3

# Node references
var protection_area: Area3D


func _ready() -> void:
	super._ready()
	structure_type = "basic_shelter"
	structure_name = "Basic Shelter"
	interaction_text = "Rest"

	# Find child nodes
	protection_area = get_node_or_null("ProtectionArea")

	# Connect area signals if present
	if protection_area:
		protection_area.body_entered.connect(_on_body_entered)
		protection_area.body_exited.connect(_on_body_exited)

	# Connect to time manager to detect nightfall while resting
	call_deferred("_connect_to_time_manager")


func interact(player: Node) -> bool:
	if not is_active:
		return false

	if is_player_resting and resting_player == player:
		# Player is resting - exit rest mode
		_exit_rest_mode(player)
		return true
	elif not is_player_resting:
		# Player wants to rest - enter rest mode
		_enter_rest_mode(player)
		return true

	return false


func _enter_rest_mode(player: Node) -> void:
	is_player_resting = true
	resting_player = player

	# Store original transforms
	player_original_position = player.global_position
	player_original_rotation = player.rotation
	if player.has_node("Camera3D"):
		player_camera_original_rotation = player.get_node("Camera3D").rotation

	# Move player inside shelter
	var rest_pos: Vector3 = global_position + rest_position_offset
	player.global_position = rest_pos

	# Rotate player to face along shelter (looking towards open end)
	player.rotation = Vector3(0, rotation.y, 0)

	# Tilt camera to look up at the shelter canvas
	if player.has_node("Camera3D"):
		var camera: Node3D = player.get_node("Camera3D")
		camera.rotation = Vector3(deg_to_rad(rest_camera_rotation.x), 0, 0)

	# Disable player movement
	if player.has_method("set_resting"):
		player.set_resting(true, self)

	# Check if it's nighttime - if so, sleep until dawn
	var time_manager: Node = _find_time_manager()
	if time_manager and _is_nighttime(time_manager):
		_trigger_sleep_sequence(player, time_manager)
	else:
		# Daytime rest - just heal
		if player.has_node("PlayerStats"):
			var stats: Node = player.get_node("PlayerStats")
			if stats.has_method("heal"):
				stats.heal(10.0)
		resting_started.emit(player)
		print("[Shelter] You rest in the shelter (+10 health)")


func _is_nighttime(time_manager: Node) -> bool:
	# Night is from 9 PM (21:00) to 5 AM (05:00), also include Dusk and Evening for sleep
	var hour: int = time_manager.current_hour
	# Night: 21-23 and 0-4, Dusk: 19-20, Evening: 17-18
	return hour >= 19 or hour < 5


func _find_time_manager() -> Node:
	var root: Node = get_tree().root
	if root.has_node("Main/TimeManager"):
		return root.get_node("Main/TimeManager")
	return null


func _connect_to_time_manager() -> void:
	var time_manager: Node = _find_time_manager()
	if time_manager and time_manager.has_signal("period_changed"):
		time_manager.period_changed.connect(_on_period_changed)


func _on_period_changed(period: String) -> void:
	# If player is resting and night has arrived, trigger sleep sequence
	if is_player_resting and resting_player:
		var time_manager: Node = _find_time_manager()
		if time_manager and _is_nighttime(time_manager):
			print("[Shelter] Night has fallen while resting - sleeping until dawn...")
			_trigger_sleep_sequence(resting_player, time_manager)


func _find_hud() -> Node:
	var root: Node = get_tree().root
	if root.has_node("Main/HUD"):
		return root.get_node("Main/HUD")
	return null


func _trigger_sleep_sequence(player: Node, time_manager: Node) -> void:
	var hud: Node = _find_hud()

	if hud and hud.has_method("fade_to_black_and_back"):
		# Fade out, skip time, fade in
		hud.fade_to_black_and_back(1.0, 0.5, 1.0, _skip_to_dawn.bind(player, time_manager))
		print("[Shelter] You fall asleep...")
	else:
		# No HUD fade available, just skip time immediately
		_skip_to_dawn(player, time_manager)


func _skip_to_dawn(player: Node, time_manager: Node) -> void:
	# Advance to next day at 6 AM (dawn)
	time_manager.current_day += 1
	time_manager.current_hour = 6
	time_manager.current_minute = 0
	time_manager._update_period()
	time_manager.day_changed.emit(time_manager.current_day)
	time_manager.time_changed.emit(time_manager.current_hour, time_manager.current_minute)
	print("[Shelter] Advanced to day %d" % time_manager.current_day)

	# Full heal and hunger restore when sleeping through the night
	if player.has_node("PlayerStats"):
		var stats: Node = player.get_node("PlayerStats")
		if stats.has_method("heal"):
			stats.heal(stats.max_health)  # Full health restore
		if "hunger" in stats and "max_hunger" in stats:
			stats.hunger = min(stats.hunger + 30.0, stats.max_hunger)  # Partial hunger restore
			stats.hunger_changed.emit(stats.hunger, stats.max_hunger)

	resting_started.emit(player)
	print("[Shelter] You wake at dawn, fully rested (+100% health, +30 hunger)")


func _exit_rest_mode(player: Node) -> void:
	is_player_resting = false

	# Move player back outside (to the open/front side of shelter - positive local Z)
	# The lean-to has its open side at positive Z (where FrameFront is at z=1.0)
	var exit_offset: Vector3 = Vector3(0, 0, 2.5).rotated(Vector3.UP, rotation.y + PI)
	player.global_position = global_position + exit_offset
	player.global_position.y = global_position.y + 1.0  # Stand height

	# Face the player towards the shelter
	player.rotation.y = rotation.y + PI

	# Restore camera rotation
	if player.has_node("Camera3D"):
		var camera: Node3D = player.get_node("Camera3D")
		camera.rotation = Vector3(0, 0, 0)  # Reset to neutral

	# Re-enable player movement
	if player.has_method("set_resting"):
		player.set_resting(false)

	resting_player = null
	resting_ended.emit(player)
	print("[Shelter] You get up from resting")


func get_interaction_text() -> String:
	if is_player_resting:
		return "Get Up"
	return "Rest in Shelter"


## Check if a position is within protection radius.
func is_in_protection_range(pos: Vector3) -> bool:
	return global_position.distance_to(pos) <= protection_radius


## Check if player is currently inside shelter.
func is_player_protected() -> bool:
	return player_inside


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		player_inside = true
		player_entered.emit()
		print("[Shelter] Player entered shelter")


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		player_inside = false
		player_exited.emit()
		print("[Shelter] Player left shelter")
