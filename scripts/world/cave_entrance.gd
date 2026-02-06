extends StaticBody3D
class_name CaveEntrance
## Cave entrance in rocky regions. Requires torch/lantern to enter.

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
static var _main_mass_mesh: BoxMesh = null
static var _peak_mesh: BoxMesh = null
static var _front_side_mesh: BoxMesh = null
static var _front_top_mesh: BoxMesh = null
static var _dark_mesh: BoxMesh = null


static func _get_rock_material() -> StandardMaterial3D:
	if not _rock_mat:
		_rock_mat = StandardMaterial3D.new()
		# Match ROCKY region terrain colors for visual consistency
		_rock_mat.albedo_color = Color(0.45, 0.42, 0.38)  # ROCKY grass color
		_rock_mat.roughness = 0.95
		_rock_mat.vertex_color_use_as_albedo = true  # Allow vertex color tinting
	return _rock_mat


static func _get_dark_material() -> StandardMaterial3D:
	if not _dark_mat:
		_dark_mat = StandardMaterial3D.new()
		_dark_mat.albedo_color = Color(0.02, 0.02, 0.02)  # Nearly black
		_dark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return _dark_mat


static func _get_main_mass_mesh() -> BoxMesh:
	if not _main_mass_mesh:
		_main_mass_mesh = BoxMesh.new()
		_main_mass_mesh.size = Vector3(14.0, 12.0, 12.0)
	return _main_mass_mesh


static func _get_peak_mesh() -> BoxMesh:
	if not _peak_mesh:
		_peak_mesh = BoxMesh.new()
		_peak_mesh.size = Vector3(8.0, 6.0, 8.0)
	return _peak_mesh


static func _get_front_side_mesh() -> BoxMesh:
	if not _front_side_mesh:
		_front_side_mesh = BoxMesh.new()
		_front_side_mesh.size = Vector3(4.5, 8.0, 4.0)
	return _front_side_mesh


static func _get_front_top_mesh() -> BoxMesh:
	if not _front_top_mesh:
		_front_top_mesh = BoxMesh.new()
		_front_top_mesh.size = Vector3(10.0, 4.0, 4.0)
	return _front_top_mesh


static func _get_dark_mesh() -> BoxMesh:
	if not _dark_mesh:
		_dark_mesh = BoxMesh.new()
		_dark_mesh.size = Vector3(4.5, 5.0, 0.5)
	return _dark_mesh


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("cave_entrance")

	# Create visual representation
	call_deferred("_setup_visuals")


func _create_tinted_rock_material(tint: float) -> StandardMaterial3D:
	## Create a slightly tinted version of the rock material for visual variation
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	var base_color: Color = Color(0.45, 0.42, 0.38)  # ROCKY terrain color
	# Apply tint variation (-0.05 to +0.05 range)
	mat.albedo_color = Color(
		clamp(base_color.r + tint, 0.3, 0.5),
		clamp(base_color.g + tint * 0.8, 0.3, 0.5),
		clamp(base_color.b + tint * 0.6, 0.3, 0.45)
	)
	mat.roughness = 0.95
	return mat


func _setup_visuals() -> void:
	# Get shared meshes (avoids mesh creation per cave)
	var dark_mat: StandardMaterial3D = _get_dark_material()

	# Create varied materials for each piece
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = cave_id * 12345

	# The entrance faces +Z direction (player approaches from +Z)

	# Main rock mass - the mountain body (slightly darker base)
	var main_mass := MeshInstance3D.new()
	main_mass.mesh = _get_main_mass_mesh()
	main_mass.material_override = _create_tinted_rock_material(rng.randf_range(-0.04, -0.02))
	main_mass.position = Vector3(0, 6.0, -4.0)
	add_child(main_mass)
	arch_meshes.append(main_mass)

	# Upper peak for mountain shape (lighter, catching light)
	var peak := MeshInstance3D.new()
	peak.mesh = _get_peak_mesh()
	peak.material_override = _create_tinted_rock_material(rng.randf_range(0.02, 0.05))
	peak.position = Vector3(0, 13.0, -3.0)
	peak.rotation_degrees = Vector3(8, 15, 5)
	add_child(peak)
	arch_meshes.append(peak)

	# Front face with entrance carved out (left and right of opening)
	var front_left := MeshInstance3D.new()
	front_left.mesh = _get_front_side_mesh()
	front_left.material_override = _create_tinted_rock_material(rng.randf_range(-0.02, 0.02))
	front_left.position = Vector3(-4.75, 4.0, 1.0)
	add_child(front_left)
	arch_meshes.append(front_left)

	var front_right := MeshInstance3D.new()
	front_right.mesh = _get_front_side_mesh()
	front_right.material_override = _create_tinted_rock_material(rng.randf_range(-0.02, 0.02))
	front_right.position = Vector3(4.75, 4.0, 1.0)
	add_child(front_right)
	arch_meshes.append(front_right)

	# Above entrance (slightly different tone)
	var front_top := MeshInstance3D.new()
	front_top.mesh = _get_front_top_mesh()
	front_top.material_override = _create_tinted_rock_material(rng.randf_range(-0.01, 0.03))
	front_top.position = Vector3(0, 9.0, 1.0)
	add_child(front_top)
	arch_meshes.append(front_top)

	# Rock ledge above entrance (overhanging brow)
	var ledge := MeshInstance3D.new()
	var ledge_mesh := BoxMesh.new()
	ledge_mesh.size = Vector3(6.0, 1.0, 2.0)
	ledge.mesh = ledge_mesh
	ledge.material_override = _create_tinted_rock_material(rng.randf_range(0.01, 0.04))
	ledge.position = Vector3(0, 5.5, 2.5)
	ledge.rotation_degrees.x = -8
	add_child(ledge)
	arch_meshes.append(ledge)

	# Scattered boulders near entrance base
	for i: int in range(4):
		var boulder := MeshInstance3D.new()
		var b_mesh := BoxMesh.new()
		var bsize: float = rng.randf_range(0.8, 1.8)
		b_mesh.size = Vector3(bsize, bsize * 0.7, bsize * 0.9)
		boulder.mesh = b_mesh
		boulder.material_override = _create_tinted_rock_material(rng.randf_range(-0.03, 0.03))
		var bx: float = rng.randf_range(-5.0, 5.0)
		var bz: float = rng.randf_range(2.5, 5.0)
		boulder.position = Vector3(bx, bsize * 0.3, bz)
		boulder.rotation_degrees = Vector3(rng.randf_range(-8, 8), rng.randf_range(0, 45), rng.randf_range(-5, 5))
		add_child(boulder)
		arch_meshes.append(boulder)

	# Stalactites hanging above entrance
	var stalac_mat := _create_tinted_rock_material(rng.randf_range(-0.02, 0.0))
	for i: int in range(5):
		var stalac := MeshInstance3D.new()
		var s_mesh := BoxMesh.new()
		var s_height: float = rng.randf_range(0.5, 1.5)
		s_mesh.size = Vector3(0.3, s_height, 0.3)
		stalac.mesh = s_mesh
		stalac.material_override = stalac_mat
		stalac.position = Vector3(
			rng.randf_range(-2.0, 2.0),
			5.5 - s_height / 2.0,
			rng.randf_range(1.0, 2.0)
		)
		add_child(stalac)
		arch_meshes.append(stalac)

	# Moss patches on rocks (green-grey patches)
	var moss_mat := StandardMaterial3D.new()
	moss_mat.albedo_color = Color(0.28, 0.38, 0.22, 0.7)
	moss_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	moss_mat.roughness = 0.95
	for i: int in range(4):
		var moss := MeshInstance3D.new()
		var m_mesh := BoxMesh.new()
		m_mesh.size = Vector3(rng.randf_range(1.0, 2.5), 0.05, rng.randf_range(0.8, 2.0))
		moss.mesh = m_mesh
		moss.material_override = moss_mat
		moss.position = Vector3(
			rng.randf_range(-5.0, 5.0),
			rng.randf_range(0.5, 4.0),
			rng.randf_range(-2.0, 2.0)
		)
		moss.rotation_degrees = Vector3(rng.randf_range(-15, 15), rng.randf_range(0, 90), 0)
		add_child(moss)
		arch_meshes.append(moss)

	# Single collision shape for the entire mountain (simpler physics)
	var mass_collision := CollisionShape3D.new()
	var mass_shape := BoxShape3D.new()
	mass_shape.size = Vector3(14.0, 14.0, 14.0)
	mass_collision.shape = mass_shape
	mass_collision.position = Vector3(0, 7.0, -3.0)
	add_child(mass_collision)

	# Collision for front walls (around entrance)
	var front_collision := CollisionShape3D.new()
	var front_shape := BoxShape3D.new()
	front_shape.size = Vector3(14.0, 10.0, 4.0)
	front_collision.shape = front_shape
	front_collision.position = Vector3(0, 5.0, 1.0)
	add_child(front_collision)

	# Dark opening (the cave mouth) - positioned at front
	darkness_mesh = MeshInstance3D.new()
	darkness_mesh.name = "DarkOpening"
	darkness_mesh.mesh = _get_dark_mesh()
	darkness_mesh.material_override = dark_mat
	darkness_mesh.position = Vector3(0, 2.5, 1.5)
	add_child(darkness_mesh)

	# Deeper darkness (interior fade)
	var inner_dark := MeshInstance3D.new()
	var id_mesh := BoxMesh.new()
	id_mesh.size = Vector3(4.0, 4.5, 0.3)
	inner_dark.mesh = id_mesh
	var inner_mat := StandardMaterial3D.new()
	inner_mat.albedo_color = Color(0.01, 0.01, 0.01)
	inner_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	inner_dark.material_override = inner_mat
	inner_dark.position = Vector3(0, 2.5, 0.8)
	add_child(inner_dark)
	arch_meshes.append(inner_dark)

	# NOTE: Removed OmniLight3D for performance - caves are visible via dark opening contrast


## Get interaction text for HUD prompt.
func get_interaction_text() -> String:
	# Check if player has a light source equipped
	var player: Node = get_tree().get_first_node_in_group("player")
	if player:
		var equipment: Equipment = _get_player_equipment(player)
		if equipment:
			var equipped: String = equipment.get_equipped()
			var item_data: Dictionary = equipment.EQUIPPABLE_ITEMS.get(equipped, {})
			if item_data.get("has_light", false):
				return "Enter Cave"

	return "Too dark! Need a torch."


## Called when player interacts with this entrance.
func interact(player: Node) -> bool:
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
		# Fallback: just emit signal, actual transition handled elsewhere
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
