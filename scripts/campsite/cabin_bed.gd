extends StructureBase
class_name CabinBed
## Comfortable bed inside the cabin for full rest and recovery.

signal player_slept()

# Bed bonuses (better than shelter or tent)
const FULL_HEALTH_RESTORE: bool = true
const FULL_HUNGER_RESTORE: bool = true

# Rest position and camera angle
@export var rest_position_offset: Vector3 = Vector3(0, 0.5, 0)  # Lying on bed
@export var rest_camera_rotation: float = 70.0  # Looking up at ceiling (positive pitch = look up)

# State
var is_player_sleeping: bool = false
var sleeping_player: Node = null
var player_original_position: Vector3
var player_original_rotation: Vector3


func _ready() -> void:
	super._ready()
	structure_type = "cabin_bed"
	structure_name = "Cabin Bed"
	interaction_text = "Sleep"
	# Bed is part of cabin, not a separate structure to track
	remove_from_group("structure")


func interact(player: Node) -> bool:
	if not is_active:
		return false

	if is_player_sleeping and sleeping_player == player:
		# Wake up
		_wake_up(player)
		return true
	elif not is_player_sleeping:
		# Go to sleep
		_go_to_sleep(player)
		return true

	return false


func _go_to_sleep(player: Node) -> void:
	is_player_sleeping = true
	sleeping_player = player

	# Store original transforms
	player_original_position = player.global_position
	player_original_rotation = player.rotation

	# Move player to bed position
	var rest_pos: Vector3 = global_position + rest_position_offset
	player.global_position = rest_pos

	# Rotate player to align with bed
	player.rotation = Vector3(0, rotation.y, 0)

	# Tilt camera to look up at the ceiling
	if player.has_node("Camera3D"):
		var camera: Node3D = player.get_node("Camera3D")
		camera.rotation = Vector3(deg_to_rad(rest_camera_rotation), 0, 0)

	# Disable player movement
	if player.has_method("set_resting"):
		player.set_resting(true, self)

	# Check if it's nighttime
	var time_manager: Node = _find_time_manager()
	if time_manager and _is_nighttime(time_manager):
		_trigger_sleep_sequence(player, time_manager)
	else:
		# Daytime rest - partial restore
		_do_rest(player)
		print("[CabinBed] You rest in the comfortable bed")


func _is_nighttime(time_manager: Node) -> bool:
	var hour: int = time_manager.current_hour
	return hour >= 19 or hour < 5


func _find_time_manager() -> Node:
	var root: Node = get_tree().root
	if root.has_node("Main/TimeManager"):
		return root.get_node("Main/TimeManager")
	return null


func _find_hud() -> Node:
	var root: Node = get_tree().root
	if root.has_node("Main/HUD"):
		return root.get_node("Main/HUD")
	return null


func _trigger_sleep_sequence(player: Node, time_manager: Node) -> void:
	var hud: Node = _find_hud()

	if hud and hud.has_method("fade_to_black_and_back"):
		hud.fade_to_black_and_back(1.0, 0.5, 1.0, _skip_to_dawn.bind(player, time_manager))
		print("[CabinBed] You fall into a deep, restful sleep...")
	else:
		_skip_to_dawn(player, time_manager)


func _skip_to_dawn(player: Node, time_manager: Node) -> void:
	# Advance to next day at 6 AM (dawn)
	time_manager.current_day += 1
	time_manager.current_hour = 6
	time_manager.current_minute = 0
	time_manager._update_period()
	time_manager.day_changed.emit(time_manager.current_day)
	time_manager.time_changed.emit(time_manager.current_hour, time_manager.current_minute)
	print("[CabinBed] Advanced to day %d" % time_manager.current_day)

	# Full restore in cabin bed!
	_do_full_restore(player)
	player_slept.emit()
	print("[CabinBed] You wake fully rested! (Full health and hunger)")


func _do_rest(player: Node) -> void:
	# Daytime rest - partial restore
	if player.has_node("PlayerStats"):
		var stats: Node = player.get_node("PlayerStats")
		if stats.has_method("heal"):
			stats.heal(30.0)
		if "hunger" in stats and "max_hunger" in stats:
			stats.hunger = min(stats.hunger + 20.0, stats.max_hunger)
			stats.hunger_changed.emit(stats.hunger, stats.max_hunger)


func _do_full_restore(player: Node) -> void:
	# Full restore - cabin bed bonus!
	if player.has_node("PlayerStats"):
		var stats: Node = player.get_node("PlayerStats")
		if stats.has_method("heal"):
			stats.heal(stats.max_health)
		if "hunger" in stats and "max_hunger" in stats:
			stats.hunger = stats.max_hunger
			stats.hunger_changed.emit(stats.hunger, stats.max_hunger)


func _wake_up(player: Node) -> void:
	is_player_sleeping = false
	sleeping_player = null

	# Position player standing next to the bed
	var exit_offset: Vector3 = Vector3(-1.0, 0, 0).rotated(Vector3.UP, rotation.y)
	player.global_position = global_position + exit_offset
	player.global_position.y = global_position.y + 1.0  # Stand height

	# Face the player toward the bed
	player.rotation.y = rotation.y + PI / 2

	# Reset camera to neutral
	if player.has_node("Camera3D"):
		var camera: Node3D = player.get_node("Camera3D")
		camera.rotation = Vector3(0, 0, 0)

	# Re-enable player movement
	if player.has_method("set_resting"):
		player.set_resting(false)

	print("[CabinBed] You get out of bed")


func get_interaction_text() -> String:
	if is_player_sleeping:
		return "Wake Up"
	return "Sleep in Bed"
