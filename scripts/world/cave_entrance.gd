extends StaticBody3D
class_name CaveEntrance
## Cave entrance - low-profile hillside mound with walkable opening at ground level.
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
static var _mound_body_mesh: BoxMesh = null
static var _shoulder_mesh: BoxMesh = null
static var _cap_mesh: BoxMesh = null
static var _dark_mesh: BoxMesh = null


static func _get_rock_material() -> StandardMaterial3D:
	if not _rock_mat:
		_rock_mat = StandardMaterial3D.new()
		_rock_mat.albedo_color = Color(0.45, 0.42, 0.38)
		_rock_mat.roughness = 0.95
		_rock_mat.vertex_color_use_as_albedo = true
	return _rock_mat


static func _get_dark_material() -> StandardMaterial3D:
	if not _dark_mat:
		_dark_mat = StandardMaterial3D.new()
		_dark_mat.albedo_color = Color(0.02, 0.02, 0.02)
		_dark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return _dark_mat


static func _get_mound_body_mesh() -> BoxMesh:
	if not _mound_body_mesh:
		_mound_body_mesh = BoxMesh.new()
		_mound_body_mesh.size = Vector3(12.0, 6.0, 10.0)
	return _mound_body_mesh


static func _get_shoulder_mesh() -> BoxMesh:
	if not _shoulder_mesh:
		_shoulder_mesh = BoxMesh.new()
		_shoulder_mesh.size = Vector3(4.0, 4.5, 6.0)
	return _shoulder_mesh


static func _get_cap_mesh() -> BoxMesh:
	if not _cap_mesh:
		_cap_mesh = BoxMesh.new()
		_cap_mesh.size = Vector3(7.0, 3.0, 6.0)
	return _cap_mesh


static func _get_dark_mesh() -> BoxMesh:
	if not _dark_mesh:
		_dark_mesh = BoxMesh.new()
		_dark_mesh.size = Vector3(4.0, 4.0, 0.5)
	return _dark_mesh


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("cave_entrance")

	# Create visual representation
	call_deferred("_setup_visuals")


func _create_tinted_rock_material(tint: float) -> StandardMaterial3D:
	## Create a slightly tinted version of the rock material for visual variation
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

	# Main mound body - wide, low hillside shape sitting on ground
	var mound := MeshInstance3D.new()
	mound.mesh = _get_mound_body_mesh()
	mound.material_override = _create_tinted_rock_material(rng.randf_range(-0.04, -0.02))
	mound.position = Vector3(0, 3.0, -2.0)
	add_child(mound)
	arch_meshes.append(mound)

	# Left shoulder - flanking the entrance, angled outward
	var left_shoulder := MeshInstance3D.new()
	left_shoulder.mesh = _get_shoulder_mesh()
	left_shoulder.material_override = _create_tinted_rock_material(rng.randf_range(-0.02, 0.02))
	left_shoulder.position = Vector3(-5.5, 2.25, 1.5)
	left_shoulder.rotation_degrees = Vector3(0, -15, 5)
	add_child(left_shoulder)
	arch_meshes.append(left_shoulder)

	# Right shoulder - flanking the entrance, angled outward
	var right_shoulder := MeshInstance3D.new()
	right_shoulder.mesh = _get_shoulder_mesh()
	right_shoulder.material_override = _create_tinted_rock_material(rng.randf_range(-0.02, 0.02))
	right_shoulder.position = Vector3(5.5, 2.25, 1.5)
	right_shoulder.rotation_degrees = Vector3(0, 15, -5)
	add_child(right_shoulder)
	arch_meshes.append(right_shoulder)

	# Cap/peak - small angled box on top for natural rock look
	var cap := MeshInstance3D.new()
	cap.mesh = _get_cap_mesh()
	cap.material_override = _create_tinted_rock_material(rng.randf_range(0.02, 0.05))
	cap.position = Vector3(0, 7.0, -2.5)
	cap.rotation_degrees = Vector3(8, rng.randf_range(-10, 10), 5)
	add_child(cap)
	arch_meshes.append(cap)

	# Rock ledge above entrance (overhanging brow)
	var ledge := MeshInstance3D.new()
	var ledge_mesh := BoxMesh.new()
	ledge_mesh.size = Vector3(5.5, 1.0, 2.0)
	ledge.mesh = ledge_mesh
	ledge.material_override = _create_tinted_rock_material(rng.randf_range(0.01, 0.04))
	ledge.position = Vector3(0, 4.5, 2.0)
	ledge.rotation_degrees.x = -8
	add_child(ledge)
	arch_meshes.append(ledge)

	# Scattered boulders near entrance base
	for i: int in range(4):
		var boulder := MeshInstance3D.new()
		var b_mesh := BoxMesh.new()
		var bsize: float = rng.randf_range(0.6, 1.4)
		b_mesh.size = Vector3(bsize, bsize * 0.6, bsize * 0.8)
		boulder.mesh = b_mesh
		boulder.material_override = _create_tinted_rock_material(rng.randf_range(-0.03, 0.03))
		var bx: float = rng.randf_range(-4.5, 4.5)
		var bz: float = rng.randf_range(3.0, 5.5)
		boulder.position = Vector3(bx, bsize * 0.25, bz)
		boulder.rotation_degrees = Vector3(rng.randf_range(-8, 8), rng.randf_range(0, 45), rng.randf_range(-5, 5))
		add_child(boulder)
		arch_meshes.append(boulder)

	# Stalactites hanging above entrance
	var stalac_mat := _create_tinted_rock_material(rng.randf_range(-0.02, 0.0))
	for i: int in range(4):
		var stalac := MeshInstance3D.new()
		var s_mesh := BoxMesh.new()
		var s_height: float = rng.randf_range(0.4, 1.0)
		s_mesh.size = Vector3(0.25, s_height, 0.25)
		stalac.mesh = s_mesh
		stalac.material_override = stalac_mat
		stalac.position = Vector3(
			rng.randf_range(-1.8, 1.8),
			4.2 - s_height / 2.0,
			rng.randf_range(1.5, 2.5)
		)
		add_child(stalac)
		arch_meshes.append(stalac)

	# Moss patches on rocks
	var moss_mat := StandardMaterial3D.new()
	moss_mat.albedo_color = Color(0.28, 0.38, 0.22, 0.7)
	moss_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	moss_mat.roughness = 0.95
	for i: int in range(3):
		var moss := MeshInstance3D.new()
		var m_mesh := BoxMesh.new()
		m_mesh.size = Vector3(rng.randf_range(0.8, 2.0), 0.05, rng.randf_range(0.6, 1.5))
		moss.mesh = m_mesh
		moss.material_override = moss_mat
		moss.position = Vector3(
			rng.randf_range(-4.5, 4.5),
			rng.randf_range(0.5, 3.0),
			rng.randf_range(-1.5, 1.5)
		)
		moss.rotation_degrees = Vector3(rng.randf_range(-15, 15), rng.randf_range(0, 90), 0)
		add_child(moss)
		arch_meshes.append(moss)

	# --- Collision shapes with entrance gap ---

	# Back mass - behind the entrance opening
	var back_col := CollisionShape3D.new()
	var back_shape := BoxShape3D.new()
	back_shape.size = Vector3(12.0, 8.0, 8.0)
	back_col.shape = back_shape
	back_col.position = Vector3(0, 4.0, -4.0)
	add_child(back_col)

	# Left wall - to left of entrance
	var left_col := CollisionShape3D.new()
	var left_shape := BoxShape3D.new()
	left_shape.size = Vector3(4.0, 8.0, 4.0)
	left_col.shape = left_shape
	left_col.position = Vector3(-4.0, 4.0, 1.0)
	add_child(left_col)

	# Right wall - to right of entrance
	var right_col := CollisionShape3D.new()
	var right_shape := BoxShape3D.new()
	right_shape.size = Vector3(4.0, 8.0, 4.0)
	right_col.shape = right_shape
	right_col.position = Vector3(4.0, 4.0, 1.0)
	add_child(right_col)

	# Top cap - above the entrance opening
	var top_col := CollisionShape3D.new()
	var top_shape := BoxShape3D.new()
	top_shape.size = Vector3(4.0, 4.0, 4.0)
	top_col.shape = top_shape
	top_col.position = Vector3(0, 6.0, 1.0)
	add_child(top_col)

	# Dark opening (cave mouth) at ground level
	darkness_mesh = MeshInstance3D.new()
	darkness_mesh.name = "DarkOpening"
	darkness_mesh.mesh = _get_dark_mesh()
	darkness_mesh.material_override = dark_mat
	darkness_mesh.position = Vector3(0, 2.0, 1.5)
	add_child(darkness_mesh)

	# Deeper darkness (interior fade)
	var inner_dark := MeshInstance3D.new()
	var id_mesh := BoxMesh.new()
	id_mesh.size = Vector3(3.5, 3.5, 0.3)
	inner_dark.mesh = id_mesh
	var inner_mat := StandardMaterial3D.new()
	inner_mat.albedo_color = Color(0.01, 0.01, 0.01)
	inner_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	inner_dark.material_override = inner_mat
	inner_dark.position = Vector3(0, 2.0, 0.8)
	add_child(inner_dark)
	arch_meshes.append(inner_dark)


## Check if a player is near the cave mouth opening AND facing it.
## The dark opening is at local +Z side, centered at ground level.
func _is_near_cave_mouth(player_node: Node3D) -> bool:
	var local_pos: Vector3 = to_local(player_node.global_position)
	var horizontal_dist: float = abs(local_pos.x)
	# Must be within 2.5 units horizontally, in front of mouth (z 0.5-4.0), below top (y < 4.0)
	if horizontal_dist > 2.5 or local_pos.z < 0.5 or local_pos.z > 4.0 or local_pos.y > 4.0:
		return false

	# Must be roughly facing the entrance (looking toward -Z in local space)
	var player_forward: Vector3 = -player_node.global_transform.basis.z.normalized()
	var to_entrance: Vector3 = (global_position - player_node.global_position).normalized()
	var dot: float = player_forward.dot(to_entrance)
	return dot > 0.3  # Within ~73 degrees of facing the entrance


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
	# Must be near the cave mouth opening, not the side walls
	if not _is_near_cave_mouth(player):
		return false

	# Check for light source
	var equipment: Equipment = _get_player_equipment(player)
	if not equipment:
		_show_notification("Cannot enter cave!", Color(1.0, 0.5, 0.5))
		return true

	var equipped: String = equipment.get_equipped()
	var item_data: Dictionary = equipment.EQUIPPABLE_ITEMS.get(equipped, {})

	if not item_data.get("has_light", false):
		_show_notification("It's pitch black! You need a torch or lantern.", Color(1.0, 0.6, 0.4))
		return true

	# Player has light - enter cave
	_enter_cave(player)
	return true


func _enter_cave(player: Node) -> void:
	print("[CaveEntrance] Entering %s cave #%d" % [cave_type, cave_id])

	# Try to use CaveTransition autoload
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
