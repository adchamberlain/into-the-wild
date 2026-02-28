extends Node
class_name BowSystem
## Handles bow draw/fire mechanics, spawns ArrowProjectile nodes,
## builds the procedural bow visual, and consumes arrows/durability.

signal arrow_count_changed(count: int)
signal arrow_type_changed(arrow_type: String)
signal bow_drawn()
signal bow_fired()

const DRAW_TIME: float = 0.5  # Seconds to fully draw
const ARROW_SPEED: float = 40.0  # Initial arrow velocity
const ARROW_LAUNCH_ANGLE: float = 2.0  # Slight upward angle in degrees

# References (set up via call_deferred in _ready)
var player: CharacterBody3D = null
var camera: Camera3D = null
var equipment: Equipment = null
var inventory: Inventory = null

# State
var is_drawing: bool = false
var draw_progress: float = 0.0
var _using_diamond_arrow: bool = false
var preferred_arrow: String = "arrows"  # "arrows" or "diamond_arrows"
var bow_model: Node3D = null
# String is two segments (upper + lower) meeting at a pull point
var string_upper: MeshInstance3D = null
var string_lower: MeshInstance3D = null
var string_nock_y: float = 0.245  # Y position of nock tips (set during build)
var string_nock_z: float = 0.0  # Z position of nock tips (set during build)
var string_pull_max_z: float = 0.06  # How far back the pull point moves at full draw


func _ready() -> void:
	call_deferred("_setup_references")


func _setup_references() -> void:
	var parent: Node = get_parent()
	if parent is CharacterBody3D:
		player = parent
		camera = player.get_node_or_null("Camera3D")
		equipment = player.get_node_or_null("Equipment")
		# Inventory is a child node accessed via @onready on player
		if player.has_method("get_inventory"):
			inventory = player.get_inventory()
		if not inventory:
			inventory = player.get_node_or_null("Inventory")
		if not inventory and "inventory" in player:
			inventory = player.inventory
		print("[BowSystem] Setup complete, equipment: %s, inventory: %s, camera: %s" % [equipment, inventory, camera])


func _input(event: InputEvent) -> void:
	# Guard: bow must be equipped
	if not _is_bow_equipped():
		return

	# Guard: UI blocking input
	if player and player.has_method("_is_ui_blocking_input") and player._is_ui_blocking_input():
		return

	# Guard: player resting
	if player and "is_resting" in player and player.is_resting:
		return

	# Cycle ammo type
	if event.is_action_pressed("cycle_ammo"):
		_cycle_arrow_type()
		return

	# Right mouse button: hold to draw, release to fire
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			if mouse_event.pressed:
				_start_draw()
			elif is_drawing:
				_fire()
			return

	# Controller: use_equipped action
	if event.is_action_pressed("use_equipped"):
		_start_draw()
		return
	if event.is_action_released("use_equipped"):
		if is_drawing:
			_fire()
		return


func _process(delta: float) -> void:
	if is_drawing:
		# Cancel if bow was unequipped while drawing
		if not _is_bow_equipped():
			_cancel_draw()
			return

		# Increment draw progress toward 1.0
		# Enchanted bow draws ~1.67x faster (0.6x draw time)
		var draw_rate: float = delta / DRAW_TIME
		if equipment and equipment.get_equipped() == "enchanted_bow":
			draw_rate *= 1.0 / 0.6
		draw_progress = minf(draw_progress + draw_rate, 1.0)

		# Animate string V-pull
		_update_string(draw_progress)


func _start_draw() -> void:
	if is_drawing:
		return

	if not _has_arrows():
		var hud: Node = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_notification"):
			hud.show_notification("No arrows!", Color(1.0, 0.5, 0.5, 1))
		return

	is_drawing = true
	draw_progress = 0.0
	bow_drawn.emit()
	SFXManager.play_sfx("bow_draw")


func _fire() -> void:
	# Too short a draw — cancel
	if draw_progress < 0.3:
		_cancel_draw()
		return

	# Double-check arrows
	if not _has_arrows():
		_cancel_draw()
		return

	# Consume 1 arrow (use preferred type, fallback to other if empty)
	if inventory:
		if preferred_arrow == "diamond_arrows" and inventory.has_item("diamond_arrows", 1):
			_using_diamond_arrow = true
			inventory.remove_item("diamond_arrows", 1)
		elif preferred_arrow == "arrows" and inventory.has_item("arrows", 1):
			_using_diamond_arrow = false
			inventory.remove_item("arrows", 1)
		elif inventory.has_item("diamond_arrows", 1):
			_using_diamond_arrow = true
			inventory.remove_item("diamond_arrows", 1)
		else:
			_using_diamond_arrow = false
			inventory.remove_item("arrows", 1)
	arrow_count_changed.emit(get_arrow_count())

	# Use equipment durability
	if equipment:
		equipment.use_durability(1)

	# Spawn the arrow projectile
	_spawn_arrow()

	# SFX and signal
	SFXManager.play_sfx("bow_fire")
	bow_fired.emit()

	# Reset state
	is_drawing = false
	draw_progress = 0.0
	_update_string(0.0)


func _cancel_draw() -> void:
	is_drawing = false
	draw_progress = 0.0
	_update_string(0.0)


func _spawn_arrow() -> void:
	if not camera:
		return

	# Calculate spawn position and velocity before creating the arrow
	var forward: Vector3 = -camera.global_basis.z
	var spawn_pos: Vector3 = camera.global_position + forward * 1.5
	var up_angle_rad: float = deg_to_rad(ARROW_LAUNCH_ANGLE)
	var launch_dir: Vector3 = (forward + camera.global_basis.y * tan(up_angle_rad)).normalized()
	var speed: float = lerpf(0.6, 1.0, draw_progress) * ARROW_SPEED

	# Enchanted bow fires 50% faster arrows
	if equipment and equipment.get_equipped() == "enchanted_bow":
		speed *= 1.5

	# Use diamond or regular arrow projectile
	var arrow: RigidBody3D
	if _using_diamond_arrow:
		arrow = DiamondArrowProjectile.new()
	else:
		arrow = ArrowProjectile.new()

	# Add to scene tree first, then set position and velocity
	var scene_root: Node = get_tree().current_scene
	if scene_root:
		scene_root.add_child(arrow)
		arrow.global_position = spawn_pos
		arrow.linear_velocity = launch_dir * speed


## Returns true when any bow (regular or enchanted) is the currently equipped item.
func _is_bow_equipped() -> bool:
	if equipment == null:
		return false
	var equipped: String = equipment.get_equipped()
	return equipped == "bow" or equipped == "enchanted_bow"


## Returns true when the player has at least 1 arrow (regular or diamond) in inventory.
func _has_arrows() -> bool:
	if not inventory:
		return false
	return inventory.has_item("diamond_arrows", 1) or inventory.has_item("arrows", 1)


## Get current arrow count from inventory (regular + diamond).
func get_arrow_count() -> int:
	if not inventory:
		return 0
	return inventory.get_item_count("arrows") + inventory.get_item_count("diamond_arrows")


## Get count for the currently preferred arrow type.
func get_preferred_arrow_count() -> int:
	if not inventory:
		return 0
	return inventory.get_item_count(preferred_arrow)


## Get display name for the preferred arrow type.
func get_preferred_arrow_name() -> String:
	if preferred_arrow == "diamond_arrows":
		return "diamond"
	return "regular"


## Cycle between regular and diamond arrows.
func _cycle_arrow_type() -> void:
	if not inventory:
		return
	if preferred_arrow == "arrows":
		if inventory.has_item("diamond_arrows", 1):
			preferred_arrow = "diamond_arrows"
		else:
			var hud: Node = get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("show_notification"):
				hud.show_notification("No diamond arrows!", Color(1.0, 0.5, 0.5, 1))
			return
	else:
		if inventory.has_item("arrows", 1):
			preferred_arrow = "arrows"
		else:
			var hud: Node = get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("show_notification"):
				hud.show_notification("No regular arrows!", Color(1.0, 0.5, 0.5, 1))
			return
	arrow_type_changed.emit(preferred_arrow)
	var hud: Node = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_notification"):
		var name: String = "Diamond arrows" if preferred_arrow == "diamond_arrows" else "Regular arrows"
		hud.show_notification("Switched to %s" % name, Color(0.6, 0.8, 1.0, 1))


## Returns true when the bow is equipped, so player_controller can skip
## its own use_equipped handling.
func is_bow_active() -> bool:
	return _is_bow_equipped()


## Build the procedural bow visual model (called by equipment system when bow is equipped).
## Returns the bow_model Node3D to be attached to the camera.
## Limbs curve TOWARD the player (+Z), string is on the player-facing side.
func build_bow_model(bow_type: String = "bow") -> Node3D:
	bow_model = Node3D.new()
	bow_model.name = "BowModel"

	var is_enchanted: bool = bow_type == "enchanted_bow"

	# Shared materials
	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	if is_enchanted:
		wood_mat.albedo_color = Color(0.35, 0.22, 0.45)  # Dark purple-wood
		wood_mat.metallic = 0.15
		wood_mat.roughness = 0.5
	else:
		wood_mat.albedo_color = Color(0.5, 0.35, 0.18)

	var dark_wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	if is_enchanted:
		dark_wood_mat.albedo_color = Color(0.28, 0.16, 0.38)  # Deeper purple-wood
		dark_wood_mat.metallic = 0.2
		dark_wood_mat.roughness = 0.45
	else:
		dark_wood_mat.albedo_color = Color(0.38, 0.24, 0.12)

	var tip_mat: StandardMaterial3D = StandardMaterial3D.new()
	if is_enchanted:
		tip_mat.albedo_color = Color(0.6, 0.5, 0.8)  # Opal-tinted tips
		tip_mat.metallic = 0.4
		tip_mat.roughness = 0.2
		tip_mat.emission_enabled = true
		tip_mat.emission = Color(0.5, 0.35, 0.7)
		tip_mat.emission_energy_multiplier = 1.5
	else:
		tip_mat.albedo_color = Color(0.42, 0.30, 0.15)

	# Opal inlay material (enchanted only)
	var opal_mat: StandardMaterial3D = null
	if is_enchanted:
		opal_mat = StandardMaterial3D.new()
		opal_mat.albedo_color = Color(0.6, 0.45, 0.85)  # Opal purple
		opal_mat.metallic = 0.35
		opal_mat.roughness = 0.1
		opal_mat.emission_enabled = true
		opal_mat.emission = Color(0.5, 0.35, 0.75)
		opal_mat.emission_energy_multiplier = 1.8

	# --- Curved limbs (4 segments each, curving toward player = +Z) ---
	var seg_height: float = 0.05
	var seg_depths: Array[float] = [0.025, 0.022, 0.018, 0.014]  # Tapering
	var seg_widths: Array[float] = [0.018, 0.016, 0.013, 0.010]
	# Positive Z = toward player (bow curves back like a recurve)
	var seg_z_offsets: Array[float] = [0.0, 0.006, 0.014, 0.024]
	var seg_x_tilts: Array[float] = [0.0, -4.0, -9.0, -15.0]  # Tilt back toward player

	# Upper limb (start from inside grip to avoid gaps)
	var limb_start: float = 0.02
	for i: int in range(4):
		var seg: MeshInstance3D = MeshInstance3D.new()
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = Vector3(seg_widths[i], seg_height, seg_depths[i])
		mesh.material = wood_mat
		seg.mesh = mesh
		seg.position = Vector3(0, limb_start + seg_height * (float(i) + 0.5), seg_z_offsets[i])
		seg.rotation_degrees.x = seg_x_tilts[i]
		bow_model.add_child(seg)

		# Add opal inlay strip on segments 1 and 3 (enchanted only)
		if is_enchanted and (i == 1 or i == 3):
			var inlay: MeshInstance3D = MeshInstance3D.new()
			var inlay_mesh: BoxMesh = BoxMesh.new()
			inlay_mesh.size = Vector3(seg_widths[i] + 0.004, 0.015, seg_depths[i] + 0.004)
			inlay_mesh.material = opal_mat
			inlay.mesh = inlay_mesh
			inlay.position = seg.position
			inlay.rotation_degrees.x = seg_x_tilts[i]
			bow_model.add_child(inlay)

	# Lower limb (mirror)
	for i: int in range(4):
		var seg: MeshInstance3D = MeshInstance3D.new()
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = Vector3(seg_widths[i], seg_height, seg_depths[i])
		mesh.material = wood_mat
		seg.mesh = mesh
		seg.position = Vector3(0, -(limb_start + seg_height * (float(i) + 0.5)), seg_z_offsets[i])
		seg.rotation_degrees.x = -seg_x_tilts[i]
		bow_model.add_child(seg)

		# Add opal inlay strip on segments 1 and 3 (enchanted only)
		if is_enchanted and (i == 1 or i == 3):
			var inlay: MeshInstance3D = MeshInstance3D.new()
			var inlay_mesh: BoxMesh = BoxMesh.new()
			inlay_mesh.size = Vector3(seg_widths[i] + 0.004, 0.015, seg_depths[i] + 0.004)
			inlay_mesh.material = opal_mat
			inlay.mesh = inlay_mesh
			inlay.position = Vector3(0, -(limb_start + seg_height * (float(i) + 0.5)), seg_z_offsets[i])
			inlay.rotation_degrees.x = -seg_x_tilts[i]
			bow_model.add_child(inlay)

	# --- Tip nocks ---
	var nock_mesh: BoxMesh = BoxMesh.new()
	nock_mesh.size = Vector3(0.008, 0.012, 0.008)
	nock_mesh.material = tip_mat

	# Store nock positions for string attachment (limb_start + 4 segments * seg_height + small gap)
	string_nock_y = 0.225
	string_nock_z = seg_z_offsets[3] + 0.005  # Slightly past last segment toward player

	var upper_nock: MeshInstance3D = MeshInstance3D.new()
	upper_nock.mesh = nock_mesh
	upper_nock.position = Vector3(0, string_nock_y, string_nock_z)
	bow_model.add_child(upper_nock)

	var lower_nock: MeshInstance3D = MeshInstance3D.new()
	lower_nock.mesh = nock_mesh
	lower_nock.position = Vector3(0, -string_nock_y, string_nock_z)
	bow_model.add_child(lower_nock)

	# --- Grip wrap ---
	var grip: MeshInstance3D = MeshInstance3D.new()
	grip.name = "Grip"
	var grip_mesh: BoxMesh = BoxMesh.new()
	grip_mesh.size = Vector3(0.022, 0.06, 0.028)
	grip_mesh.material = dark_wood_mat
	grip.mesh = grip_mesh
	grip.position = Vector3.ZERO
	bow_model.add_child(grip)

	# Grip accent strips
	var wrap_mat: StandardMaterial3D = StandardMaterial3D.new()
	if is_enchanted:
		wrap_mat.albedo_color = Color(0.5, 0.35, 0.7)  # Purple accent wraps
		wrap_mat.metallic = 0.3
		wrap_mat.roughness = 0.3
		wrap_mat.emission_enabled = true
		wrap_mat.emission = Color(0.4, 0.25, 0.6)
		wrap_mat.emission_energy_multiplier = 1.0
	else:
		wrap_mat.albedo_color = Color(0.3, 0.18, 0.08)
	for j: int in range(3):
		var wrap: MeshInstance3D = MeshInstance3D.new()
		var wrap_mesh: BoxMesh = BoxMesh.new()
		wrap_mesh.size = Vector3(0.024, 0.005, 0.030)
		wrap_mesh.material = wrap_mat
		wrap.mesh = wrap_mesh
		wrap.position = Vector3(0, -0.02 + 0.02 * j, 0)
		bow_model.add_child(wrap)

	# Opal gem inset on grip (enchanted only)
	if is_enchanted:
		var gem: MeshInstance3D = MeshInstance3D.new()
		gem.name = "OpalGem"
		var gem_mesh: BoxMesh = BoxMesh.new()
		gem_mesh.size = Vector3(0.012, 0.012, 0.032)
		var gem_mat: StandardMaterial3D = StandardMaterial3D.new()
		gem_mat.albedo_color = Color(0.7, 0.5, 0.95)  # Bright opal
		gem_mat.metallic = 0.5
		gem_mat.roughness = 0.05
		gem_mat.emission_enabled = true
		gem_mat.emission = Color(0.6, 0.4, 0.9)
		gem_mat.emission_energy_multiplier = 2.5
		gem_mesh.material = gem_mat
		gem.mesh = gem_mesh
		gem.position = Vector3(0, 0, 0)
		bow_model.add_child(gem)

	# --- V-String (two segments: upper nock→pull point, lower nock→pull point) ---
	var string_mat: StandardMaterial3D = StandardMaterial3D.new()
	if is_enchanted:
		string_mat.albedo_color = Color(0.75, 0.65, 0.9)  # Faint purple-tinged string
		string_mat.emission_enabled = true
		string_mat.emission = Color(0.5, 0.35, 0.7)
		string_mat.emission_energy_multiplier = 0.6
	else:
		string_mat.albedo_color = Color(0.82, 0.78, 0.70)

	# Upper string half (nock to center)
	string_upper = MeshInstance3D.new()
	string_upper.name = "StringUpper"
	var upper_str_mesh: BoxMesh = BoxMesh.new()
	upper_str_mesh.size = Vector3(0.004, 1.0, 0.004)  # Unit size, scaled dynamically
	upper_str_mesh.material = string_mat
	string_upper.mesh = upper_str_mesh
	bow_model.add_child(string_upper)

	# Lower string half (nock to center)
	string_lower = MeshInstance3D.new()
	string_lower.name = "StringLower"
	var lower_str_mesh: BoxMesh = BoxMesh.new()
	lower_str_mesh.size = Vector3(0.004, 1.0, 0.004)
	lower_str_mesh.material = string_mat
	string_lower.mesh = lower_str_mesh
	bow_model.add_child(string_lower)

	# Set initial string position (no draw)
	_update_string(0.0)

	return bow_model


## Update the V-string segments based on draw progress (0.0 = at rest, 1.0 = full draw).
## Each half stretches from its nock point to the center pull point.
func _update_string(progress: float) -> void:
	if not string_upper or not string_lower:
		return

	# Pull point: center (y=0), pulled back toward player by progress
	var pull_z: float = string_nock_z + progress * string_pull_max_z

	# Upper half: from upper nock (0, +nock_y, nock_z) to pull point (0, 0, pull_z)
	var upper_start: Vector3 = Vector3(0, string_nock_y, string_nock_z)
	var upper_end: Vector3 = Vector3(0, 0, pull_z)
	_position_string_segment(string_upper, upper_start, upper_end)

	# Lower half: from lower nock (0, -nock_y, nock_z) to pull point (0, 0, pull_z)
	var lower_start: Vector3 = Vector3(0, -string_nock_y, string_nock_z)
	var lower_end: Vector3 = Vector3(0, 0, pull_z)
	_position_string_segment(string_lower, lower_start, lower_end)


## Position and scale a string segment mesh to stretch between two points.
func _position_string_segment(seg: MeshInstance3D, from: Vector3, to: Vector3) -> void:
	var midpoint: Vector3 = (from + to) * 0.5
	var diff: Vector3 = to - from
	var length: float = diff.length()

	seg.position = midpoint
	seg.scale = Vector3(1, length, 1)

	# Orient the segment along the from→to direction
	if length > 0.001:
		# Calculate rotation to align Y-axis with the segment direction
		var dir: Vector3 = diff.normalized()
		# Angle from Y-axis in the YZ plane
		var angle: float = atan2(dir.z, dir.y)
		seg.rotation = Vector3(angle, 0, 0)


## Remove and clean up the bow visual model.
func clear_bow_model() -> void:
	if bow_model and is_instance_valid(bow_model):
		bow_model.queue_free()
	bow_model = null
	string_upper = null
	string_lower = null
	_cancel_draw()
