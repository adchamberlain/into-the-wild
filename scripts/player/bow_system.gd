extends Node
class_name BowSystem
## Handles bow draw/fire mechanics, spawns ArrowProjectile nodes,
## builds the procedural bow visual, and consumes arrows/durability.

signal arrow_count_changed(count: int)
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
var bow_model: Node3D = null
var string_mesh: MeshInstance3D = null
var string_rest_z: float = 0.0
var string_drawn_z: float = 0.04


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
		draw_progress = minf(draw_progress + delta / DRAW_TIME, 1.0)

		# Animate string pull-back
		if string_mesh:
			var target_z: float = lerpf(string_rest_z, string_drawn_z, draw_progress)
			string_mesh.position.z = target_z


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

	# Consume 1 arrow
	if inventory:
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
	if string_mesh:
		string_mesh.position.z = string_rest_z


func _cancel_draw() -> void:
	is_drawing = false
	draw_progress = 0.0
	if string_mesh:
		string_mesh.position.z = string_rest_z


func _spawn_arrow() -> void:
	if not camera:
		return

	# Calculate spawn position and velocity before creating the arrow
	var forward: Vector3 = -camera.global_basis.z
	var spawn_pos: Vector3 = camera.global_position + forward * 1.5
	var up_angle_rad: float = deg_to_rad(ARROW_LAUNCH_ANGLE)
	var launch_dir: Vector3 = (forward + camera.global_basis.y * tan(up_angle_rad)).normalized()
	var speed: float = lerpf(0.6, 1.0, draw_progress) * ARROW_SPEED

	var arrow: ArrowProjectile = ArrowProjectile.new()

	# Add to scene tree first, then set position and velocity
	var scene_root: Node = get_tree().current_scene
	if scene_root:
		scene_root.add_child(arrow)
		arrow.global_position = spawn_pos
		arrow.linear_velocity = launch_dir * speed


## Returns true when the bow is the currently equipped item.
func _is_bow_equipped() -> bool:
	return equipment != null and equipment.get_equipped() == "bow"


## Returns true when the player has at least 1 arrow in inventory.
func _has_arrows() -> bool:
	if not inventory:
		return false
	return inventory.has_item("arrows", 1)


## Get current arrow count from inventory.
func get_arrow_count() -> int:
	if not inventory:
		return 0
	return inventory.get_item_count("arrows")


## Returns true when the bow is equipped, so player_controller can skip
## its own use_equipped handling.
func is_bow_active() -> bool:
	return _is_bow_equipped()


## Build the procedural bow visual model (called by equipment system when bow is equipped).
## Returns the bow_model Node3D to be attached to the camera.
## Uses multiple segments per limb to create a curved bow shape.
func build_bow_model() -> Node3D:
	bow_model = Node3D.new()
	bow_model.name = "BowModel"

	# Shared materials
	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.5, 0.35, 0.18)

	var dark_wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	dark_wood_mat.albedo_color = Color(0.38, 0.24, 0.12)

	var tip_mat: StandardMaterial3D = StandardMaterial3D.new()
	tip_mat.albedo_color = Color(0.42, 0.30, 0.15)

	# --- Curved limbs (4 segments each, progressively angled for curve) ---
	# Each segment is placed end-to-end, with increasing forward curve (z offset)
	# Segments taper: thicker near grip, thinner at tips
	var seg_height: float = 0.05  # Height of each segment
	var seg_depths: Array[float] = [0.025, 0.022, 0.018, 0.014]  # Tapering depth
	var seg_widths: Array[float] = [0.018, 0.016, 0.013, 0.010]  # Tapering width
	# Cumulative z-offsets per segment to create the curve (bow bends forward)
	var seg_z_offsets: Array[float] = [0.0, -0.006, -0.014, -0.024]
	var seg_x_tilts: Array[float] = [0.0, 4.0, 9.0, 15.0]  # Progressive tilt outward

	# Upper limb (segments going upward from grip)
	for i: int in range(4):
		var seg: MeshInstance3D = MeshInstance3D.new()
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = Vector3(seg_widths[i], seg_height, seg_depths[i])
		mesh.material = wood_mat
		seg.mesh = mesh
		seg.position = Vector3(0, 0.04 + seg_height * (float(i) + 0.5), seg_z_offsets[i])
		seg.rotation_degrees.x = seg_x_tilts[i]
		bow_model.add_child(seg)

	# Lower limb (mirror of upper, going downward)
	for i: int in range(4):
		var seg: MeshInstance3D = MeshInstance3D.new()
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = Vector3(seg_widths[i], seg_height, seg_depths[i])
		mesh.material = wood_mat
		seg.mesh = mesh
		seg.position = Vector3(0, -(0.04 + seg_height * (float(i) + 0.5)), seg_z_offsets[i])
		seg.rotation_degrees.x = -seg_x_tilts[i]
		bow_model.add_child(seg)

	# --- Tip nocks (small knobs where string attaches) ---
	var nock_mesh: BoxMesh = BoxMesh.new()
	nock_mesh.size = Vector3(0.008, 0.012, 0.008)
	nock_mesh.material = tip_mat

	var upper_nock: MeshInstance3D = MeshInstance3D.new()
	upper_nock.mesh = nock_mesh
	upper_nock.position = Vector3(0, 0.245, seg_z_offsets[3] - 0.005)
	bow_model.add_child(upper_nock)

	var lower_nock: MeshInstance3D = MeshInstance3D.new()
	lower_nock.mesh = nock_mesh
	lower_nock.position = Vector3(0, -0.245, seg_z_offsets[3] - 0.005)
	bow_model.add_child(lower_nock)

	# --- Grip wrap (darker leather binding at center) ---
	var grip: MeshInstance3D = MeshInstance3D.new()
	grip.name = "Grip"
	var grip_mesh: BoxMesh = BoxMesh.new()
	grip_mesh.size = Vector3(0.022, 0.06, 0.028)
	grip_mesh.material = dark_wood_mat
	grip.mesh = grip_mesh
	grip.position = Vector3.ZERO
	bow_model.add_child(grip)

	# Grip accent strips (cord wrapping)
	var wrap_mat: StandardMaterial3D = StandardMaterial3D.new()
	wrap_mat.albedo_color = Color(0.3, 0.18, 0.08)
	for j: int in range(3):
		var wrap: MeshInstance3D = MeshInstance3D.new()
		var wrap_mesh: BoxMesh = BoxMesh.new()
		wrap_mesh.size = Vector3(0.024, 0.005, 0.030)
		wrap_mesh.material = wrap_mat
		wrap.mesh = wrap_mesh
		wrap.position = Vector3(0, -0.02 + 0.02 * j, 0)
		bow_model.add_child(wrap)

	# --- String (thin line from tip to tip) ---
	string_mesh = MeshInstance3D.new()
	string_mesh.name = "BowString"
	var string_box: BoxMesh = BoxMesh.new()
	string_box.size = Vector3(0.004, 0.49, 0.004)
	var string_mat: StandardMaterial3D = StandardMaterial3D.new()
	string_mat.albedo_color = Color(0.82, 0.78, 0.70)
	string_box.material = string_mat
	string_mesh.mesh = string_box
	string_mesh.position = Vector3(0, 0, string_rest_z)
	bow_model.add_child(string_mesh)

	return bow_model


## Remove and clean up the bow visual model.
func clear_bow_model() -> void:
	if bow_model and is_instance_valid(bow_model):
		bow_model.queue_free()
	bow_model = null
	string_mesh = null
	_cancel_draw()
