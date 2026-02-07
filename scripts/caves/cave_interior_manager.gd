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
var _setup_complete: bool = false


func _ready() -> void:
	# Defer setup to let the scene tree settle (no await - avoids race conditions
	# with CaveTransition adding the player)
	call_deferred("_setup_references")


func _setup_references() -> void:
	# Find darkness overlay
	var canvas: CanvasLayer = get_node_or_null("../DarknessOverlay")
	if canvas:
		darkness_overlay = canvas.get_node_or_null("ColorRect")

	if not darkness_overlay:
		var parent: Node = get_parent()
		if parent:
			for child in parent.get_children():
				if child is CanvasLayer and child.name == "DarknessOverlay":
					darkness_overlay = child.get_node_or_null("ColorRect")
					break

	# Find exit area
	exit_area = get_node_or_null("../ExitArea")
	if exit_area and not exit_area.body_entered.is_connected(_on_exit_area_entered):
		exit_area.body_entered.connect(_on_exit_area_entered)

	# Build natural rock formations around the exit
	_build_exit_formation()
	# Add rock detail along the cave walls
	_build_wall_details()

	# Apply saved cave resource state and track new depletions
	_setup_cave_resources()

	# Initial state
	_update_darkness_state()

	_setup_complete = true
	print("[CaveManager] Setup complete. Overlay: %s, Exit: %s" % [
		darkness_overlay != null, exit_area != null
	])


func _process(delta: float) -> void:
	if not _setup_complete:
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

	# Also check for placed light sources (torches, campfires) in the scene
	if not has_light:
		has_light = _has_placed_light_nearby()

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


## Apply saved depleted state and connect to resource signals for tracking.
func _setup_cave_resources() -> void:
	var cave_transition: Node = get_node_or_null("/root/CaveTransition")
	if not cave_transition:
		return

	var cave_id: int = cave_transition.current_cave_id
	if cave_id < 0:
		return

	# Use the time snapshot taken by CaveTransition at cave entry
	var current_day: int = cave_transition.entry_game_day
	var current_hour: int = cave_transition.entry_game_hour
	var current_minute: int = cave_transition.entry_game_minute

	# Get list of resource names that are still depleted
	var depleted_names: Array[String] = []
	if cave_transition.has_method("get_depleted_cave_resources"):
		depleted_names = cave_transition.get_depleted_cave_resources(cave_id, current_day, current_hour, current_minute)

	# Find the Resources container in the cave scene
	var resources_node: Node = get_node_or_null("../Resources")
	if not resources_node:
		return

	var depleted_count: int = 0
	for child in resources_node.get_children():
		if child is ResourceNode:
			# Apply depleted state if tracked
			if child.name in depleted_names:
				child._set_depleted_state(true)
				depleted_count += 1

			# Connect to depleted signal to track new depletions
			if not child.depleted.is_connected(_on_cave_resource_depleted.bind(child)):
				child.depleted.connect(_on_cave_resource_depleted.bind(child))

	if depleted_count > 0:
		print("[CaveManager] Restored %d depleted cave resources" % depleted_count)


func _on_cave_resource_depleted(resource: ResourceNode) -> void:
	var cave_transition: Node = get_node_or_null("/root/CaveTransition")
	if not cave_transition or not cave_transition.has_method("track_cave_resource_depleted"):
		return

	var cave_id: int = cave_transition.current_cave_id
	if cave_id < 0:
		return

	# Use the entry time snapshot (time is frozen while in cave)
	var current_day: int = cave_transition.entry_game_day
	var current_hour: int = cave_transition.entry_game_hour
	var current_minute: int = cave_transition.entry_game_minute

	cave_transition.track_cave_resource_depleted(cave_id, resource.name, current_day, current_hour, current_minute)


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


func _make_rock_mat(r: float, g: float, b: float) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(r, g, b)
	mat.roughness = 0.95
	return mat


func _add_rock_to(parent: Node3D, pos: Vector3, size: Vector3, rot: Vector3, color: Color) -> void:
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.material_override = _make_rock_mat(color.r, color.g, color.b)
	mesh_inst.position = pos
	mesh_inst.rotation_degrees = rot
	parent.add_child(mesh_inst)


func _add_collision_to(parent: StaticBody3D, pos: Vector3, size: Vector3) -> void:
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = pos
	parent.add_child(col)


func _build_exit_formation() -> void:
	## Build a natural rock wall at the +Z end of the cave with an opening
	## for the exit. The cave is 30 wide (x=-15 to +15), 8 tall, exit at z=20.
	var terrain: StaticBody3D = get_node_or_null("../Terrain") as StaticBody3D
	if not terrain:
		return

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7777

	var exit_z: float = 20.0
	var base_color := Color(0.20, 0.18, 0.16)  # Match cave wall color

	# -- Left wall section (x=-15 to x=-2.5) --
	_add_rock_to(terrain, Vector3(-8.5, 4.0, exit_z), Vector3(13.0, 8.0, 1.0), Vector3.ZERO, base_color)
	# -- Right wall section (x=+2.5 to x=+15) --
	_add_rock_to(terrain, Vector3(8.5, 4.0, exit_z), Vector3(13.0, 8.0, 1.0), Vector3.ZERO, base_color)
	# -- Top section above opening (x=-2.5 to x=+2.5, y=4.5 to y=8) --
	_add_rock_to(terrain, Vector3(0, 6.25, exit_z), Vector3(5.0, 3.5, 1.0), Vector3.ZERO, base_color)

	# Collision for the wall sections
	_add_collision_to(terrain, Vector3(-8.5, 4.0, exit_z), Vector3(13.0, 8.0, 1.0))
	_add_collision_to(terrain, Vector3(8.5, 4.0, exit_z), Vector3(13.0, 8.0, 1.0))
	_add_collision_to(terrain, Vector3(0, 6.25, exit_z), Vector3(5.0, 3.5, 1.0))

	# -- Rock formations framing the 5x4.5 opening --
	# Opening goes from x=-2.5 to x=+2.5, y=0 to y=4.5

	# Left pillar rocks (stacked irregular blocks)
	var lc := Color(base_color.r + 0.03, base_color.g + 0.02, base_color.b + 0.01)
	_add_rock_to(terrain, Vector3(-2.8, 1.2, exit_z + 0.3), Vector3(1.8, 2.4, 1.5),
		Vector3(0, rng.randf_range(-4, 4), rng.randf_range(-3, 3)), lc)
	_add_rock_to(terrain, Vector3(-2.5, 3.2, exit_z + 0.2), Vector3(1.4, 1.6, 1.2),
		Vector3(rng.randf_range(-3, 3), rng.randf_range(-5, 5), rng.randf_range(-3, 3)),
		Color(lc.r + 0.02, lc.g + 0.01, lc.b))

	# Right pillar rocks
	var rc := Color(base_color.r + 0.02, base_color.g + 0.01, base_color.b + 0.02)
	_add_rock_to(terrain, Vector3(2.8, 1.0, exit_z + 0.3), Vector3(1.6, 2.0, 1.5),
		Vector3(0, rng.randf_range(-4, 4), rng.randf_range(-3, 3)), rc)
	_add_rock_to(terrain, Vector3(2.6, 3.0, exit_z + 0.2), Vector3(1.3, 1.4, 1.2),
		Vector3(rng.randf_range(-3, 3), rng.randf_range(-5, 5), rng.randf_range(-3, 3)),
		Color(rc.r + 0.02, rc.g + 0.01, rc.b))

	# Top rocks spanning the opening (lintel)
	_add_rock_to(terrain, Vector3(0, 4.8, exit_z + 0.3), Vector3(4.5, 1.2, 1.8),
		Vector3(rng.randf_range(-3, 3), 0, rng.randf_range(-2, 2)),
		Color(base_color.r + 0.04, base_color.g + 0.03, base_color.b + 0.02))
	# Cap rock
	_add_rock_to(terrain, Vector3(rng.randf_range(-0.3, 0.3), 5.6, exit_z + 0.1),
		Vector3(3.0, 0.8, 1.4),
		Vector3(rng.randf_range(-4, 4), rng.randf_range(-5, 5), rng.randf_range(-3, 3)),
		Color(base_color.r + 0.05, base_color.g + 0.04, base_color.b + 0.03))

	# Overhang jutting inward
	_add_rock_to(terrain, Vector3(0, 4.3, exit_z - 0.8), Vector3(3.0, 0.6, 1.5),
		Vector3(-10, 0, rng.randf_range(-3, 3)),
		Color(base_color.r + 0.02, base_color.g + 0.02, base_color.b + 0.01))

	# Rubble at the base of the exit
	_add_rock_to(terrain, Vector3(-1.8, 0.3, exit_z + 0.5), Vector3(1.2, 0.6, 0.8),
		Vector3(rng.randf_range(-5, 5), rng.randf_range(0, 20), 0),
		Color(base_color.r + 0.01, base_color.g, base_color.b))
	_add_rock_to(terrain, Vector3(2.0, 0.25, exit_z + 0.3), Vector3(1.0, 0.5, 0.7),
		Vector3(rng.randf_range(-5, 5), rng.randf_range(0, 25), 0),
		Color(base_color.r, base_color.g + 0.01, base_color.b))

	# Stalactites hanging from the top of the opening
	for i: int in range(3):
		var s_h: float = rng.randf_range(0.3, 0.8)
		_add_rock_to(terrain,
			Vector3(rng.randf_range(-1.2, 1.2), 4.5 - s_h * 0.5, exit_z - rng.randf_range(0.0, 0.5)),
			Vector3(0.15, s_h, 0.15),
			Vector3(rng.randf_range(-5, 5), 0, rng.randf_range(-5, 5)),
			Color(0.18, 0.16, 0.14))


func _build_wall_details() -> void:
	## Add irregular rock formations along the cave walls to break up flat surfaces.
	var terrain: StaticBody3D = get_node_or_null("../Terrain") as StaticBody3D
	if not terrain:
		return

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 8888
	var base := Color(0.22, 0.20, 0.17)

	# Rock outcrops along left wall (x ~ -14)
	for i: int in range(6):
		var z_pos: float = rng.randf_range(-18.0, 18.0)
		var y_pos: float = rng.randf_range(0.5, 5.0)
		var w: float = rng.randf_range(1.0, 2.5)
		var h: float = rng.randf_range(1.0, 3.0)
		var d: float = rng.randf_range(0.8, 2.0)
		var tint: float = rng.randf_range(-0.03, 0.03)
		_add_rock_to(terrain,
			Vector3(-14.0 + rng.randf_range(0.0, 0.5), y_pos, z_pos),
			Vector3(w, h, d),
			Vector3(rng.randf_range(-5, 5), rng.randf_range(-5, 5), rng.randf_range(-3, 3)),
			Color(base.r + tint, base.g + tint * 0.8, base.b + tint * 0.6))

	# Rock outcrops along right wall (x ~ +14)
	for i: int in range(6):
		var z_pos: float = rng.randf_range(-18.0, 18.0)
		var y_pos: float = rng.randf_range(0.5, 5.0)
		var w: float = rng.randf_range(1.0, 2.5)
		var h: float = rng.randf_range(1.0, 3.0)
		var d: float = rng.randf_range(0.8, 2.0)
		var tint: float = rng.randf_range(-0.03, 0.03)
		_add_rock_to(terrain,
			Vector3(14.0 - rng.randf_range(0.0, 0.5), y_pos, z_pos),
			Vector3(w, h, d),
			Vector3(rng.randf_range(-5, 5), rng.randf_range(-5, 5), rng.randf_range(-3, 3)),
			Color(base.r + tint, base.g + tint * 0.8, base.b + tint * 0.6))

	# Floor rocks/rubble scattered around
	for i: int in range(8):
		var bsize: float = rng.randf_range(0.3, 0.9)
		_add_rock_to(terrain,
			Vector3(rng.randf_range(-12.0, 12.0), bsize * 0.25, rng.randf_range(-18.0, 16.0)),
			Vector3(bsize, bsize * 0.5, bsize * 0.7),
			Vector3(rng.randf_range(-8, 8), rng.randf_range(0, 45), rng.randf_range(-5, 5)),
			Color(base.r + rng.randf_range(-0.03, 0.03), base.g + rng.randf_range(-0.02, 0.02), base.b))

	# Ceiling stalactites
	for i: int in range(6):
		var s_h: float = rng.randf_range(0.4, 1.5)
		_add_rock_to(terrain,
			Vector3(rng.randf_range(-10.0, 10.0), 7.5 - s_h * 0.5, rng.randf_range(-15.0, 15.0)),
			Vector3(rng.randf_range(0.15, 0.3), s_h, rng.randf_range(0.15, 0.3)),
			Vector3(rng.randf_range(-5, 5), 0, rng.randf_range(-5, 5)),
			Color(0.17, 0.15, 0.13))


func _has_placed_light_nearby() -> bool:
	## Check if any placed light sources (torches, campfires) exist in the cave scene.
	var scene_root: Node = get_parent()
	if not scene_root:
		return false
	for node in scene_root.get_children():
		if node is StaticBody3D:
			var light: OmniLight3D = node.get_node_or_null("TorchLight")
			if light and light.light_energy > 0.0:
				return true
	return false


func _get_player_equipment(player_node: Node) -> Equipment:
	if player_node.has_node("Equipment"):
		return player_node.get_node("Equipment") as Equipment
	if player_node.has_method("get_equipment"):
		return player_node.get_equipment()
	return null


func _show_notification(message: String, color: Color) -> void:
	# Find HUD as child of current scene (CaveTransition adds it there)
	var scene_root: Node = get_tree().current_scene
	if scene_root:
		var hud: Node = scene_root.get_node_or_null("HUD")
		if hud and hud.has_method("show_notification"):
			hud.show_notification(message, color)


## Force light state (for testing or special events).
func set_forced_light(enabled: bool) -> void:
	is_dark = not enabled
	_update_darkness_state()
