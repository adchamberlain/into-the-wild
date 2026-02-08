extends Node
## Autoload singleton for managing inline cave state: darkness overlay,
## resource respawn tracking, and damage in darkness.
## No scene transitions - caves are built directly in the overworld.

signal cave_entered(cave_id: int)
signal cave_exited()
signal darkness_changed(is_dark: bool)

# State tracking
var current_cave_id: int = -1
var is_in_cave: bool = false

# Darkness settings
const DARKNESS_CHECK_INTERVAL: float = 0.5
const DARKNESS_DAMAGE_DELAY: float = 60.0  # Seconds before damage starts
const DARKNESS_DAMAGE_INTERVAL: float = 10.0
const DARKNESS_DAMAGE_AMOUNT: int = 2
const DARKNESS_ALPHA: float = 0.95

# Darkness state
var is_dark: bool = false
var time_in_darkness: float = 0.0
var darkness_damage_timer: float = 0.0
var light_check_timer: float = 0.0

# Cave resource respawn settings (in game hours) - 72 hours = 3 game days
const CAVE_RESOURCE_RESPAWN_HOURS: float = 72.0

# Tracks depleted cave resources.
# Key: cave_id (String) → Value: Array of Dictionaries
# Each dict: {node_name: String, depleted_day: int, depleted_hour: int, depleted_minute: int}
var cave_resource_state: Dictionary = {}

# Darkness overlay
var darkness_overlay: ColorRect = null
var darkness_canvas: CanvasLayer = null


func _ready() -> void:
	_create_darkness_overlay()


func _create_darkness_overlay() -> void:
	darkness_canvas = CanvasLayer.new()
	darkness_canvas.layer = 100  # On top of everything
	add_child(darkness_canvas)

	darkness_overlay = ColorRect.new()
	darkness_overlay.color = Color(0, 0, 0, 0)  # Start transparent
	darkness_overlay.anchors_preset = Control.PRESET_FULL_RECT
	darkness_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	darkness_canvas.add_child(darkness_overlay)


func _process(delta: float) -> void:
	if not is_in_cave:
		return

	# Periodic light check
	light_check_timer += delta
	if light_check_timer >= DARKNESS_CHECK_INTERVAL:
		light_check_timer = 0.0
		_check_player_light()

	# Darkness damage
	if is_dark:
		time_in_darkness += delta
		if time_in_darkness >= DARKNESS_DAMAGE_DELAY:
			darkness_damage_timer += delta
			if darkness_damage_timer >= DARKNESS_DAMAGE_INTERVAL:
				darkness_damage_timer = 0.0
				_apply_darkness_damage()


## Called by CaveEntrance Area3D when player enters.
func player_entered_cave(cave_id: int) -> void:
	if is_in_cave:
		return

	current_cave_id = cave_id
	is_in_cave = true

	# Reset darkness timers
	time_in_darkness = 0.0
	darkness_damage_timer = 0.0
	light_check_timer = 0.0

	# Immediately check for light
	_check_player_light()

	cave_entered.emit(cave_id)
	print("[CaveTransition] Player entered cave #%d" % cave_id)


## Called by CaveEntrance Area3D when player exits.
func player_exited_cave() -> void:
	if not is_in_cave:
		return

	is_in_cave = false
	current_cave_id = -1

	# Clear darkness
	if is_dark:
		is_dark = false
		_update_darkness_overlay(false)
		darkness_changed.emit(false)

	time_in_darkness = 0.0
	darkness_damage_timer = 0.0

	cave_exited.emit()
	print("[CaveTransition] Player exited cave")


func _check_player_light() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if not player:
		return

	var has_light: bool = false

	var equipment: Node = _get_player_equipment(player)
	if equipment and equipment.has_method("get_equipped"):
		var equipped: String = equipment.get_equipped()
		var item_data: Dictionary = equipment.EQUIPPABLE_ITEMS.get(equipped, {})
		has_light = item_data.get("has_light", false)

	var was_dark: bool = is_dark
	is_dark = not has_light

	if is_dark != was_dark:
		_update_darkness_overlay(is_dark)
		darkness_changed.emit(is_dark)

		if is_dark:
			_show_notification("It's pitch black! Equip a light source!", Color(1.0, 0.5, 0.5))
			time_in_darkness = 0.0
			darkness_damage_timer = 0.0
		else:
			_show_notification("You can see now.", Color(0.7, 0.9, 0.7))


func _update_darkness_overlay(dark: bool) -> void:
	if not darkness_overlay:
		return
	var target_alpha: float = DARKNESS_ALPHA if dark else 0.0
	var tween: Tween = create_tween()
	tween.tween_property(darkness_overlay, "color:a", target_alpha, 0.3)


func _apply_darkness_damage() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if not player:
		return

	if time_in_darkness < DARKNESS_DAMAGE_DELAY + DARKNESS_DAMAGE_INTERVAL * 0.5:
		_show_notification("You stumble in the darkness!", Color(1.0, 0.6, 0.4))

	if player.has_method("take_damage"):
		player.take_damage(DARKNESS_DAMAGE_AMOUNT)
	elif "health" in player:
		player.health -= DARKNESS_DAMAGE_AMOUNT

	print("[CaveTransition] Darkness damage: %d HP" % DARKNESS_DAMAGE_AMOUNT)


func _get_player_equipment(player: Node) -> Node:
	if player.has_node("Equipment"):
		return player.get_node("Equipment")
	if player.has_method("get_equipment"):
		return player.get_equipment()
	return null


## Check if player is currently in a cave.
func is_player_in_cave() -> bool:
	return is_in_cave


## Get current cave ID (-1 if not in cave).
func get_current_cave_id() -> int:
	return current_cave_id


## Record a cave resource as depleted.
func track_cave_resource_depleted(cave_id: int, node_name: String, day: int, hour: int, minute: int) -> void:
	var key: String = str(cave_id)
	if not cave_resource_state.has(key):
		cave_resource_state[key] = []

	# Avoid duplicates
	var entries: Array = cave_resource_state[key]
	for entry: Dictionary in entries:
		if entry.get("node_name", "") == node_name:
			return

	entries.append({
		"node_name": node_name,
		"depleted_day": day,
		"depleted_hour": hour,
		"depleted_minute": minute
	})
	print("[CaveTransition] Tracked depleted cave resource: cave %d, %s at day %d %d:%02d" % [cave_id, node_name, day, hour, minute])


## Get depleted resources for a cave, removing any that have respawned.
func get_depleted_cave_resources(cave_id: int, current_day: int, current_hour: int, current_minute: int) -> Array[String]:
	var key: String = str(cave_id)
	if not cave_resource_state.has(key):
		return []

	var still_depleted: Array[String] = []
	var entries: Array = cave_resource_state[key]
	var remaining: Array = []

	for entry: Dictionary in entries:
		var d_day: int = entry.get("depleted_day", 1)
		var d_hour: int = entry.get("depleted_hour", 0)
		var d_minute: int = entry.get("depleted_minute", 0)

		# Calculate elapsed game time in minutes
		var elapsed_minutes: float = float((current_day - d_day) * 24 * 60 + (current_hour - d_hour) * 60 + (current_minute - d_minute))
		var respawn_minutes: float = CAVE_RESOURCE_RESPAWN_HOURS * 60.0

		if elapsed_minutes < respawn_minutes:
			still_depleted.append(entry.get("node_name", ""))
			remaining.append(entry)
		else:
			print("[CaveTransition] Cave resource respawned: %s (%.0f min elapsed)" % [entry.get("node_name", ""), elapsed_minutes])

	cave_resource_state[key] = remaining
	return still_depleted


## Get save data for persistence.
func get_save_data() -> Dictionary:
	return {
		"cave_resource_state": cave_resource_state
	}


## Load save data.
func load_save_data(data: Dictionary) -> void:
	cave_resource_state = data.get("cave_resource_state", {})


func _show_notification(message: String, color: Color) -> void:
	var hud: Node = get_tree().root.get_node_or_null("Main/HUD")
	if hud and hud.has_method("show_notification"):
		hud.show_notification(message, color)
