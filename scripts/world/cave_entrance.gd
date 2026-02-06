extends StaticBody3D
class_name CaveEntrance
## Cave entrance - a dark opening framed by a rock archway.
## Requires torch/lantern to enter.

signal entered(cave_id: int)

# Cave properties
@export var cave_id: int = 0
@export var cave_type: String = "small"  # "small", "medium", "large"

# Visual nodes
var arch_meshes: Array[MeshInstance3D] = []
var darkness_mesh: MeshInstance3D = null

# Shared materials (static to avoid shader compilation per instance)
static var _rock_mat: StandardMaterial3D = null
static var _dark_mat: StandardMaterial3D = null

# Shared meshes (static to avoid mesh creation per instance)
static var _left_pillar_mesh: BoxMesh = null
static var _right_pillar_mesh: BoxMesh = null
static var _lintel_mesh: BoxMesh = null
static var _dark_mesh: BoxMesh = null
static var _back_wall_mesh: BoxMesh = null


static func _get_rock_material() -> StandardMaterial3D:
	if not _rock_mat:
		_rock_mat = StandardMaterial3D.new()
		_rock_mat.albedo_color = Color(0.45, 0.42, 0.38)
		_rock_mat.roughness = 0.95
	return _rock_mat


static func _get_dark_material() -> StandardMaterial3D:
	if not _dark_mat:
		_dark_mat = StandardMaterial3D.new()
		_dark_mat.albedo_color = Color(0.02, 0.02, 0.02)
		_dark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return _dark_mat


static func _get_left_pillar_mesh() -> BoxMesh:
	if not _left_pillar_mesh:
		_left_pillar_mesh = BoxMesh.new()
		_left_pillar_mesh.size = Vector3(1.5, 3.5, 1.5)
	return _left_pillar_mesh


static func _get_right_pillar_mesh() -> BoxMesh:
	if not _right_pillar_mesh:
		_right_pillar_mesh = BoxMesh.new()
		_right_pillar_mesh.size = Vector3(1.5, 3.5, 1.5)
	return _right_pillar_mesh


static func _get_lintel_mesh() -> BoxMesh:
	if not _lintel_mesh:
		_lintel_mesh = BoxMesh.new()
		_lintel_mesh.size = Vector3(5.5, 1.5, 1.8)
	return _lintel_mesh


static func _get_dark_mesh() -> BoxMesh:
	if not _dark_mesh:
		_dark_mesh = BoxMesh.new()
		_dark_mesh.size = Vector3(3.5, 3.5, 0.3)
	return _dark_mesh


static func _get_back_wall_mesh() -> BoxMesh:
	if not _back_wall_mesh:
		_back_wall_mesh = BoxMesh.new()
		_back_wall_mesh.size = Vector3(5.0, 4.5, 0.5)
	return _back_wall_mesh


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("cave_entrance")
	call_deferred("_setup_visuals")


func _create_tinted_rock_material(tint: float) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	var base_color: Color = Color(0.45, 0.42, 0.38)
	mat.albedo_color = Color(
		clamp(base_color.r + tint, 0.3, 0.5),
		clamp(base_color.g + tint * 0.8, 0.3, 0.5),
		clamp(base_color.b + tint * 0.6, 0.3, 0.45)
	)
	mat.roughness = 0.95
	return mat


func _setup_visuals() -> void:
	var dark_mat: StandardMaterial3D = _get_dark_material()

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = cave_id * 12345

	# The entrance faces +Z direction (player approaches from +Z)
	# The dark opening is the dominant visual - everything else just frames it

	# --- Dark opening (the cave mouth) - this is what the player sees ---
	darkness_mesh = MeshInstance3D.new()
	darkness_mesh.name = "DarkOpening"
	darkness_mesh.mesh = _get_dark_mesh()
	darkness_mesh.material_override = dark_mat
	darkness_mesh.position = Vector3(0, 1.75, 0.3)
	add_child(darkness_mesh)

	# Deeper darkness layer for depth illusion
	var inner_dark := MeshInstance3D.new()
	var id_mesh := BoxMesh.new()
	id_mesh.size = Vector3(3.2, 3.2, 0.3)
	inner_dark.mesh = id_mesh
	inner_dark.material_override = dark_mat
	inner_dark.position = Vector3(0, 1.75, -0.1)
	add_child(inner_dark)
	arch_meshes.append(inner_dark)

	# Back wall - gives illusion of a cave going back (just behind the dark opening)
	var back_wall := MeshInstance3D.new()
	back_wall.mesh = _get_back_wall_mesh()
	back_wall.material_override = _create_tinted_rock_material(-0.08)
	back_wall.position = Vector3(0, 2.0, -1.0)
	add_child(back_wall)
	arch_meshes.append(back_wall)

	# --- Rock arch framing the opening ---

	# Left pillar
	var left_pillar := MeshInstance3D.new()
	left_pillar.mesh = _get_left_pillar_mesh()
	left_pillar.material_override = _create_tinted_rock_material(rng.randf_range(-0.03, 0.01))
	left_pillar.position = Vector3(-2.5, 1.75, 0.3)
	left_pillar.rotation_degrees = Vector3(0, rng.randf_range(-3, 3), rng.randf_range(-3, 3))
	add_child(left_pillar)
	arch_meshes.append(left_pillar)

	# Right pillar
	var right_pillar := MeshInstance3D.new()
	right_pillar.mesh = _get_right_pillar_mesh()
	right_pillar.material_override = _create_tinted_rock_material(rng.randf_range(-0.03, 0.01))
	right_pillar.position = Vector3(2.5, 1.75, 0.3)
	right_pillar.rotation_degrees = Vector3(0, rng.randf_range(-3, 3), rng.randf_range(-3, 3))
	add_child(right_pillar)
	arch_meshes.append(right_pillar)

	# Top lintel connecting the pillars
	var lintel := MeshInstance3D.new()
	lintel.mesh = _get_lintel_mesh()
	lintel.material_override = _create_tinted_rock_material(rng.randf_range(0.0, 0.04))
	lintel.position = Vector3(0, 4.0, 0.3)
	lintel.rotation_degrees = Vector3(rng.randf_range(-3, 3), 0, rng.randf_range(-2, 2))
	add_child(lintel)
	arch_meshes.append(lintel)

	# Small overhang ledge jutting forward above the opening
	var overhang := MeshInstance3D.new()
	var overhang_mesh := BoxMesh.new()
	overhang_mesh.size = Vector3(4.0, 0.6, 1.2)
	overhang.mesh = overhang_mesh
	overhang.material_override = _create_tinted_rock_material(rng.randf_range(0.01, 0.03))
	overhang.position = Vector3(0, 4.5, 1.0)
	overhang.rotation_degrees.x = -10
	add_child(overhang)
	arch_meshes.append(overhang)

	# --- Scattered boulders around the base ---
	for i: int in range(5):
		var boulder := MeshInstance3D.new()
		var b_mesh := BoxMesh.new()
		var bsize: float = rng.randf_range(0.4, 1.2)
		b_mesh.size = Vector3(bsize, bsize * 0.6, bsize * 0.7)
		boulder.mesh = b_mesh
		boulder.material_override = _create_tinted_rock_material(rng.randf_range(-0.04, 0.04))
		# Place boulders around the entrance, not blocking it
		var angle: float = rng.randf_range(-1.2, 1.2)
		var dist: float = rng.randf_range(2.5, 4.5)
		boulder.position = Vector3(sin(angle) * dist, bsize * 0.25, cos(angle) * dist + 1.0)
		boulder.rotation_degrees = Vector3(rng.randf_range(-10, 10), rng.randf_range(0, 45), rng.randf_range(-8, 8))
		add_child(boulder)
		arch_meshes.append(boulder)

	# Stalactites hanging from the lintel
	var stalac_mat := _create_tinted_rock_material(rng.randf_range(-0.03, -0.01))
	for i: int in range(3):
		var stalac := MeshInstance3D.new()
		var s_mesh := BoxMesh.new()
		var s_height: float = rng.randf_range(0.3, 0.8)
		s_mesh.size = Vector3(0.2, s_height, 0.2)
		stalac.mesh = s_mesh
		stalac.material_override = stalac_mat
		stalac.position = Vector3(
			rng.randf_range(-1.2, 1.2),
			3.5 - s_height * 0.5,
			rng.randf_range(0.2, 0.8)
		)
		add_child(stalac)
		arch_meshes.append(stalac)

	# Moss patches on the arch
	var moss_mat := StandardMaterial3D.new()
	moss_mat.albedo_color = Color(0.28, 0.38, 0.22, 0.7)
	moss_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	moss_mat.roughness = 0.95
	for i: int in range(2):
		var moss := MeshInstance3D.new()
		var m_mesh := BoxMesh.new()
		m_mesh.size = Vector3(rng.randf_range(0.5, 1.5), 0.05, rng.randf_range(0.4, 1.0))
		moss.mesh = m_mesh
		moss.material_override = moss_mat
		moss.position = Vector3(
			rng.randf_range(-2.5, 2.5),
			rng.randf_range(1.0, 3.5),
			rng.randf_range(0.0, 1.0)
		)
		moss.rotation_degrees = Vector3(rng.randf_range(-15, 15), rng.randf_range(0, 90), 0)
		add_child(moss)
		arch_meshes.append(moss)

	# --- Collision: just the arch frame + thin back wall ---

	# Left pillar collision
	var left_col := CollisionShape3D.new()
	var left_shape := BoxShape3D.new()
	left_shape.size = Vector3(1.5, 3.5, 1.5)
	left_col.shape = left_shape
	left_col.position = Vector3(-2.5, 1.75, 0.3)
	add_child(left_col)

	# Right pillar collision
	var right_col := CollisionShape3D.new()
	var right_shape := BoxShape3D.new()
	right_shape.size = Vector3(1.5, 3.5, 1.5)
	right_col.shape = right_shape
	right_col.position = Vector3(2.5, 1.75, 0.3)
	add_child(right_col)

	# Lintel collision
	var lintel_col := CollisionShape3D.new()
	var lintel_shape := BoxShape3D.new()
	lintel_shape.size = Vector3(5.5, 1.5, 1.8)
	lintel_col.shape = lintel_shape
	lintel_col.position = Vector3(0, 4.0, 0.3)
	add_child(lintel_col)

	# Back wall collision (prevents walking through)
	var back_col := CollisionShape3D.new()
	var back_shape := BoxShape3D.new()
	back_shape.size = Vector3(5.0, 4.5, 0.5)
	back_col.shape = back_shape
	back_col.position = Vector3(0, 2.0, -1.0)
	add_child(back_col)


## Check if a player is near the cave mouth opening AND facing it.
func _is_near_cave_mouth(player_node: Node3D) -> bool:
	var local_pos: Vector3 = to_local(player_node.global_position)
	var horizontal_dist: float = abs(local_pos.x)
	# Must be within 2.0 units horizontally, in front of mouth (z 0.5-4.0), below lintel
	if horizontal_dist > 2.0 or local_pos.z < 0.5 or local_pos.z > 4.0 or local_pos.y > 4.0:
		return false

	# Must be roughly facing the entrance
	var player_forward: Vector3 = -player_node.global_transform.basis.z.normalized()
	var to_entrance: Vector3 = (global_position - player_node.global_position).normalized()
	var dot: float = player_forward.dot(to_entrance)
	return dot > 0.3


## Get interaction text for HUD prompt.
func get_interaction_text() -> String:
	var player: Node = get_tree().get_first_node_in_group("player")
	if not player or not _is_near_cave_mouth(player):
		return ""

	# Check if player has a light source equipped
	var equipment: Equipment = _get_player_equipment(player)
	if equipment:
		var equipped: String = equipment.get_equipped()
		var item_data: Dictionary = equipment.EQUIPPABLE_ITEMS.get(equipped, {})
		if item_data.get("has_light", false):
			return "Enter Cave"

	return "Too dark! Need a torch."


## Called when player interacts with this entrance.
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
		cave_transition.enter_cave(cave_id, cave_type, player)
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
