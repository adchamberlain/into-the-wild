extends StaticBody3D
class_name CaveEntrance
## Cave entrance - a rocky outcrop with a dark opening. Built from layered
## rock blocks to look like a natural hillside formation.
## Requires torch/lantern to enter.

signal entered(cave_id: int)

# Cave properties
@export var cave_id: int = 0
@export var cave_type: String = "small"  # "small", "medium", "large"

# Visual nodes
var arch_meshes: Array[MeshInstance3D] = []
var darkness_mesh: MeshInstance3D = null

# Shared materials (static to avoid shader compilation per instance)
static var _dark_mat: StandardMaterial3D = null


static func _get_dark_material() -> StandardMaterial3D:
	if not _dark_mat:
		_dark_mat = StandardMaterial3D.new()
		_dark_mat.albedo_color = Color(0.02, 0.02, 0.02)
		_dark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return _dark_mat


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("cave_entrance")
	call_deferred("_setup_visuals")


func _make_rock_mat(r: float, g: float, b: float) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(r, g, b)
	mat.roughness = 0.95
	return mat


func _add_rock(pos: Vector3, size: Vector3, rot: Vector3, tint: float, rng: RandomNumberGenerator) -> MeshInstance3D:
	## Helper: create a rock block with position, size, rotation, and color tint
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	# Base grey-brown with tint variation
	mesh_inst.material_override = _make_rock_mat(
		clamp(0.42 + tint + rng.randf_range(-0.02, 0.02), 0.28, 0.52),
		clamp(0.40 + tint * 0.8 + rng.randf_range(-0.02, 0.02), 0.26, 0.48),
		clamp(0.36 + tint * 0.6 + rng.randf_range(-0.02, 0.02), 0.24, 0.44)
	)
	mesh_inst.position = pos
	mesh_inst.rotation_degrees = rot
	add_child(mesh_inst)
	arch_meshes.append(mesh_inst)
	return mesh_inst


func _setup_visuals() -> void:
	var dark_mat: StandardMaterial3D = _get_dark_material()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = cave_id * 12345

	# Entrance faces +Z. Player approaches from +Z, walks into -Z.

	# ===== DARK OPENING (the main visual landmark) =====
	# Irregular shape: main rectangle + offset pieces to break up the edge
	darkness_mesh = MeshInstance3D.new()
	darkness_mesh.name = "DarkOpening"
	var dark_box := BoxMesh.new()
	dark_box.size = Vector3(3.2, 3.2, 0.4)
	darkness_mesh.mesh = dark_box
	darkness_mesh.material_override = dark_mat
	darkness_mesh.position = Vector3(0, 1.6, 0.5)
	add_child(darkness_mesh)

	# Upper dark extension (makes opening taller on one side)
	var dark_upper := MeshInstance3D.new()
	var du_mesh := BoxMesh.new()
	du_mesh.size = Vector3(2.0, 0.8, 0.4)
	dark_upper.mesh = du_mesh
	dark_upper.material_override = dark_mat
	dark_upper.position = Vector3(-0.4, 3.4, 0.5)
	add_child(dark_upper)
	arch_meshes.append(dark_upper)

	# Lower side dark extension (widens base irregularly)
	var dark_side := MeshInstance3D.new()
	var ds_mesh := BoxMesh.new()
	ds_mesh.size = Vector3(0.6, 1.5, 0.4)
	dark_side.mesh = ds_mesh
	dark_side.material_override = dark_mat
	dark_side.position = Vector3(1.8, 0.75, 0.5)
	add_child(dark_side)
	arch_meshes.append(dark_side)

	# Depth layers - dark planes going back to give sense of depth
	for depth_i: int in range(3):
		var depth_dark := MeshInstance3D.new()
		var dd_mesh := BoxMesh.new()
		var shrink: float = float(depth_i) * 0.15
		dd_mesh.size = Vector3(2.8 - shrink, 2.8 - shrink, 0.2)
		depth_dark.mesh = dd_mesh
		depth_dark.material_override = dark_mat
		depth_dark.position = Vector3(0, 1.6, 0.1 - float(depth_i) * 0.5)
		add_child(depth_dark)
		arch_meshes.append(depth_dark)

	# ===== ROCK FORMATION (layered blocks forming a natural outcrop) =====

	# -- Left rock mass: 3 stacked irregular blocks --
	# Base block (widest, sits on ground)
	_add_rock(Vector3(-2.8, 1.0, 0.2), Vector3(2.4, 2.0, 2.2), Vector3(0, rng.randf_range(-4, 4), rng.randf_range(-2, 2)), -0.04, rng)
	# Middle block (slightly offset)
	_add_rock(Vector3(-2.5, 2.6, 0.0), Vector3(2.0, 1.4, 2.0), Vector3(rng.randf_range(-3, 3), rng.randf_range(-6, 6), rng.randf_range(-3, 3)), -0.02, rng)
	# Top piece (smaller, capping)
	_add_rock(Vector3(-2.3, 3.8, 0.1), Vector3(1.6, 1.0, 1.6), Vector3(rng.randf_range(-5, 5), rng.randf_range(-8, 8), rng.randf_range(-4, 4)), 0.02, rng)

	# -- Right rock mass: 3 stacked irregular blocks --
	_add_rock(Vector3(2.8, 1.0, 0.2), Vector3(2.2, 2.0, 2.4), Vector3(0, rng.randf_range(-4, 4), rng.randf_range(-2, 2)), -0.03, rng)
	_add_rock(Vector3(2.6, 2.5, 0.1), Vector3(1.8, 1.2, 2.0), Vector3(rng.randf_range(-3, 3), rng.randf_range(-6, 6), rng.randf_range(-3, 3)), 0.0, rng)
	_add_rock(Vector3(3.0, 3.5, 0.0), Vector3(1.4, 0.8, 1.4), Vector3(rng.randf_range(-5, 5), rng.randf_range(-8, 8), rng.randf_range(-4, 4)), 0.03, rng)

	# -- Top rock mass: spans across the opening --
	# Main lintel (heavy, irregular)
	_add_rock(Vector3(0, 3.8, 0.3), Vector3(5.0, 1.4, 2.2), Vector3(rng.randf_range(-3, 3), 0, rng.randf_range(-2, 2)), 0.01, rng)
	# Upper cap (sits on the lintel, offset)
	_add_rock(Vector3(rng.randf_range(-0.5, 0.5), 4.8, -0.1), Vector3(3.5, 1.0, 2.0), Vector3(rng.randf_range(-4, 4), rng.randf_range(-5, 5), rng.randf_range(-3, 3)), 0.04, rng)

	# -- Back rock face: fills in behind the opening so you don't see through --
	_add_rock(Vector3(0, 2.2, -1.0), Vector3(5.5, 5.0, 1.0), Vector3(0, 0, 0), -0.06, rng)
	# Extra back block for width
	_add_rock(Vector3(-2.0, 1.5, -1.5), Vector3(2.5, 3.0, 1.5), Vector3(0, rng.randf_range(-5, 5), 0), -0.08, rng)
	_add_rock(Vector3(2.0, 1.5, -1.5), Vector3(2.5, 3.0, 1.5), Vector3(0, rng.randf_range(-5, 5), 0), -0.07, rng)

	# -- Overhang: juts forward above the opening --
	_add_rock(Vector3(rng.randf_range(-0.3, 0.3), 4.2, 1.2), Vector3(3.5, 0.7, 1.5), Vector3(-12, 0, rng.randf_range(-3, 3)), 0.02, rng)

	# ===== RUBBLE / BOULDERS at base =====
	# Large rubble flanking the opening
	_add_rock(Vector3(-2.0, 0.4, 1.8), Vector3(1.6, 0.8, 1.2), Vector3(rng.randf_range(-5, 5), rng.randf_range(0, 20), rng.randf_range(-5, 5)), -0.02, rng)
	_add_rock(Vector3(2.2, 0.35, 2.0), Vector3(1.4, 0.7, 1.0), Vector3(rng.randf_range(-5, 5), rng.randf_range(0, 30), rng.randf_range(-5, 5)), 0.0, rng)

	# Scattered smaller boulders
	for i: int in range(6):
		var bsize: float = rng.randf_range(0.4, 1.0)
		var angle: float = rng.randf_range(-1.3, 1.3)
		var dist: float = rng.randf_range(2.0, 4.5)
		_add_rock(
			Vector3(sin(angle) * dist, bsize * 0.25, cos(angle) * dist + 1.5),
			Vector3(bsize, bsize * 0.55, bsize * 0.7),
			Vector3(rng.randf_range(-10, 10), rng.randf_range(0, 45), rng.randf_range(-8, 8)),
			rng.randf_range(-0.05, 0.05), rng
		)

	# Ground rubble slabs leading to opening (flat rocks)
	for i: int in range(3):
		var sx: float = rng.randf_range(-1.5, 1.5)
		var sz: float = rng.randf_range(0.8, 2.5)
		_add_rock(
			Vector3(sx, 0.06, sz),
			Vector3(rng.randf_range(0.6, 1.2), 0.12, rng.randf_range(0.5, 1.0)),
			Vector3(0, rng.randf_range(0, 45), 0),
			rng.randf_range(-0.03, 0.03), rng
		)

	# ===== STALACTITES hanging from lintel =====
	for i: int in range(4):
		var s_h: float = rng.randf_range(0.3, 0.9)
		var stalac := MeshInstance3D.new()
		var s_mesh := BoxMesh.new()
		s_mesh.size = Vector3(0.18, s_h, 0.18)
		stalac.mesh = s_mesh
		stalac.material_override = _make_rock_mat(0.38, 0.36, 0.32)
		stalac.position = Vector3(
			rng.randf_range(-1.3, 1.3),
			3.3 - s_h * 0.5,
			rng.randf_range(0.2, 0.9)
		)
		stalac.rotation_degrees = Vector3(rng.randf_range(-5, 5), 0, rng.randf_range(-5, 5))
		add_child(stalac)
		arch_meshes.append(stalac)

	# ===== MOSS patches on rock surfaces =====
	var moss_mat := StandardMaterial3D.new()
	moss_mat.albedo_color = Color(0.25, 0.35, 0.20, 0.65)
	moss_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	moss_mat.roughness = 0.95
	for i: int in range(4):
		var moss := MeshInstance3D.new()
		var m_mesh := BoxMesh.new()
		m_mesh.size = Vector3(rng.randf_range(0.6, 1.8), 0.06, rng.randf_range(0.5, 1.2))
		moss.mesh = m_mesh
		moss.material_override = moss_mat
		var mx: float = rng.randf_range(-3.0, 3.0)
		var my: float = rng.randf_range(0.5, 3.5)
		moss.position = Vector3(mx, my, rng.randf_range(-0.2, 0.8))
		moss.rotation_degrees = Vector3(rng.randf_range(-20, 20), rng.randf_range(0, 90), rng.randf_range(-10, 10))
		add_child(moss)
		arch_meshes.append(moss)

	# ===== COLLISION =====
	# Left rock mass
	_add_collision(Vector3(-2.8, 2.0, 0.1), Vector3(2.4, 4.0, 2.2))
	# Right rock mass
	_add_collision(Vector3(2.8, 2.0, 0.1), Vector3(2.2, 4.0, 2.4))
	# Top lintel
	_add_collision(Vector3(0, 4.2, 0.1), Vector3(5.5, 2.0, 2.2))
	# Back wall
	_add_collision(Vector3(0, 2.5, -1.2), Vector3(6.0, 5.0, 1.5))


func _add_collision(pos: Vector3, size: Vector3) -> void:
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = pos
	add_child(col)


## Check if a player is near the cave mouth opening AND facing it.
func _is_near_cave_mouth(player_node: Node3D) -> bool:
	var local_pos: Vector3 = to_local(player_node.global_position)
	var horizontal_dist: float = abs(local_pos.x)
	if horizontal_dist > 2.0 or local_pos.z < 0.5 or local_pos.z > 4.0 or local_pos.y > 4.0:
		return false
	var player_forward: Vector3 = -player_node.global_transform.basis.z.normalized()
	var to_entrance: Vector3 = (global_position - player_node.global_position).normalized()
	return player_forward.dot(to_entrance) > 0.3


func get_interaction_text() -> String:
	var player: Node = get_tree().get_first_node_in_group("player")
	if not player or not _is_near_cave_mouth(player):
		return ""
	var equipment: Equipment = _get_player_equipment(player)
	if equipment:
		var equipped: String = equipment.get_equipped()
		var item_data: Dictionary = equipment.EQUIPPABLE_ITEMS.get(equipped, {})
		if item_data.get("has_light", false):
			return "Enter Cave"
	return "Too dark! Need a torch."


func interact(player: Node) -> bool:
	if not _is_near_cave_mouth(player):
		return false
	var equipment: Equipment = _get_player_equipment(player)
	if not equipment:
		_show_notification("Cannot enter cave!", Color(1.0, 0.5, 0.5))
		return true
	var equipped: String = equipment.get_equipped()
	var item_data: Dictionary = equipment.EQUIPPABLE_ITEMS.get(equipped, {})
	if not item_data.get("has_light", false):
		_show_notification("It's pitch black! You need a torch or lantern.", Color(1.0, 0.6, 0.4))
		return true
	_enter_cave(player)
	return true


func _enter_cave(player: Node) -> void:
	print("[CaveEntrance] Entering %s cave #%d" % [cave_type, cave_id])
	var cave_transition: Node = get_node_or_null("/root/CaveTransition")
	if cave_transition and cave_transition.has_method("enter_cave"):
		cave_transition.enter_cave(cave_id, cave_type, player, global_position, rotation.y)
		entered.emit(cave_id)
	else:
		_show_notification("Entering %s cave..." % cave_type, Color(0.7, 0.7, 0.9))
		entered.emit(cave_id)


func _get_player_equipment(player: Node) -> Equipment:
	if player.has_node("Equipment"):
		return player.get_node("Equipment") as Equipment
	if player.has_method("get_equipment"):
		return player.get_equipment()
	return null


func _show_notification(message: String, color: Color) -> void:
	var hud: Node = _find_hud()
	if hud and hud.has_method("show_notification"):
		hud.show_notification(message, color)


func _find_hud() -> Node:
	var root: Node = get_tree().root
	if root.has_node("Main/HUD"):
		return root.get_node("Main/HUD")
	return null
