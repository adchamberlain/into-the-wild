extends Node
class_name CaveInteriorManager
## Manages cave interior mechanics: darkness, lighting, damage, and exit.

signal darkness_changed(is_dark: bool)
signal player_damaged(amount: int)

# Darkness settings
const DARKNESS_CHECK_INTERVAL: float = 0.5
const DARKNESS_DAMAGE_DELAY: float = 60.0  # Seconds before damage starts
const DARKNESS_DAMAGE_INTERVAL: float = 10.0
const DARKNESS_DAMAGE_AMOUNT: int = 2

# State
var is_dark: bool = true
var time_in_darkness: float = 0.0
var darkness_damage_timer: float = 0.0
var light_check_timer: float = 0.0

# References
var darkness_overlay: ColorRect = null
var player: Node = null
var exit_area: Area3D = null


func _ready() -> void:
	# Find darkness overlay in scene
	await get_tree().process_frame
	_setup_references()


func _setup_references() -> void:
	# Find darkness overlay
	var canvas: CanvasLayer = get_node_or_null("../DarknessOverlay")
	if canvas:
		darkness_overlay = canvas.get_node_or_null("ColorRect")

	# If not found directly, search children
	if not darkness_overlay:
		var parent: Node = get_parent()
		for child in parent.get_children():
			if child is CanvasLayer and child.name == "DarknessOverlay":
				darkness_overlay = child.get_node_or_null("ColorRect")
				break

	# Find player
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

	# Find exit area
	exit_area = get_node_or_null("../ExitArea")
	if exit_area:
		exit_area.body_entered.connect(_on_exit_area_entered)

	# Initial state
	_update_darkness_state()

	print("[CaveManager] Setup complete. Overlay: %s, Player: %s, Exit: %s" % [
		darkness_overlay != null, player != null, exit_area != null
	])


func _process(delta: float) -> void:
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


func _check_player_light() -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if not player:
			return

	# Check if player has light source equipped
	var has_light: bool = false

	var equipment: Equipment = _get_player_equipment(player)
	if equipment:
		var equipped: String = equipment.get_equipped()
		var item_data: Dictionary = equipment.EQUIPPABLE_ITEMS.get(equipped, {})
		has_light = item_data.get("has_light", false)

	# Update darkness state
	var was_dark: bool = is_dark
	is_dark = not has_light

	if is_dark != was_dark:
		_update_darkness_state()
		darkness_changed.emit(is_dark)

		if is_dark:
			_show_notification("It's pitch black! Equip a light source!", Color(1.0, 0.5, 0.5))
			time_in_darkness = 0.0
			darkness_damage_timer = 0.0
		else:
			_show_notification("You can see now.", Color(0.7, 0.9, 0.7))


func _update_darkness_state() -> void:
	if darkness_overlay:
		var target_alpha: float = 0.95 if is_dark else 0.0

		var tween: Tween = create_tween()
		tween.tween_property(darkness_overlay, "color:a", target_alpha, 0.3)


func _apply_darkness_damage() -> void:
	if not player:
		return

	# Show warning before first damage
	if time_in_darkness < DARKNESS_DAMAGE_DELAY + DARKNESS_DAMAGE_INTERVAL * 0.5:
		_show_notification("You stumble in the darkness!", Color(1.0, 0.6, 0.4))

	# Apply damage to player
	if player.has_method("take_damage"):
		player.take_damage(DARKNESS_DAMAGE_AMOUNT)
		player_damaged.emit(DARKNESS_DAMAGE_AMOUNT)
	elif "health" in player:
		player.health -= DARKNESS_DAMAGE_AMOUNT
		player_damaged.emit(DARKNESS_DAMAGE_AMOUNT)

	print("[CaveManager] Darkness damage: %d HP" % DARKNESS_DAMAGE_AMOUNT)


func _on_exit_area_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_exit_cave()


func _exit_cave() -> void:
	print("[CaveManager] Player reached exit")

	# Use CaveTransition autoload to exit
	var cave_transition: Node = get_node_or_null("/root/CaveTransition")
	if cave_transition and cave_transition.has_method("exit_cave"):
		cave_transition.exit_cave()
	else:
		_show_notification("Exiting cave...", Color(0.7, 0.7, 0.9))
		# Fallback: just change scene directly
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://scenes/main.tscn")


func _get_player_equipment(player_node: Node) -> Equipment:
	if player_node.has_node("Equipment"):
		return player_node.get_node("Equipment") as Equipment
	if player_node.has_method("get_equipment"):
		return player_node.get_equipment()
	return null


func _show_notification(message: String, color: Color) -> void:
	# Try to find HUD in cave scene
	var hud: Node = get_tree().root.get_node_or_null("CaveInterior/HUD")
	if not hud:
		# Try main scene HUD path as fallback
		hud = get_tree().root.get_node_or_null("Main/HUD")
	if hud and hud.has_method("show_notification"):
		hud.show_notification(message, color)


## Force light state (for testing or special events).
func set_forced_light(enabled: bool) -> void:
	is_dark = not enabled
	_update_darkness_state()
