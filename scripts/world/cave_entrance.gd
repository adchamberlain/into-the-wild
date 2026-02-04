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


static func _get_rock_material() -> StandardMaterial3D:
	if not _rock_mat:
		_rock_mat = StandardMaterial3D.new()
		_rock_mat.albedo_color = Color(0.4, 0.38, 0.35)
		_rock_mat.roughness = 0.95
	return _rock_mat


static func _get_dark_material() -> StandardMaterial3D:
	if not _dark_mat:
		_dark_mat = StandardMaterial3D.new()
		_dark_mat.albedo_color = Color(0.02, 0.02, 0.02)  # Nearly black
		_dark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return _dark_mat


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("cave_entrance")

	# Create visual representation
	call_deferred("_setup_visuals")


func _setup_visuals() -> void:
	# Get shared materials (avoids shader compilation per cave)
	var rock_mat: StandardMaterial3D = _get_rock_material()
	var dark_mat: StandardMaterial3D = _get_dark_material()

	# Create a rock mound/mountain that the cave goes into
	# Simplified version with fewer meshes for performance
	# The entrance faces +Z direction (player approaches from +Z)

	# Main rock mass - the mountain body (single large mesh)
	var main_mass := _create_rock_mesh(Vector3(14.0, 12.0, 12.0), rock_mat)
	main_mass.position = Vector3(0, 6.0, -4.0)
	add_child(main_mass)
	arch_meshes.append(main_mass)

	# Upper peak for mountain shape
	var peak := _create_rock_mesh(Vector3(8.0, 6.0, 8.0), rock_mat)
	peak.position = Vector3(0, 13.0, -3.0)
	peak.rotation_degrees = Vector3(8, 15, 5)
	add_child(peak)
	arch_meshes.append(peak)

	# Front face with entrance carved out (left and right of opening)
	var front_left := _create_rock_mesh(Vector3(4.5, 8.0, 4.0), rock_mat)
	front_left.position = Vector3(-4.75, 4.0, 1.0)
	add_child(front_left)
	arch_meshes.append(front_left)

	var front_right := _create_rock_mesh(Vector3(4.5, 8.0, 4.0), rock_mat)
	front_right.position = Vector3(4.75, 4.0, 1.0)
	add_child(front_right)
	arch_meshes.append(front_right)

	# Above entrance
	var front_top := _create_rock_mesh(Vector3(10.0, 4.0, 4.0), rock_mat)
	front_top.position = Vector3(0, 9.0, 1.0)
	add_child(front_top)
	arch_meshes.append(front_top)

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
	var dark_mesh := BoxMesh.new()
	dark_mesh.size = Vector3(4.5, 5.0, 0.5)
	darkness_mesh.mesh = dark_mesh
	darkness_mesh.material_override = dark_mat
	darkness_mesh.position = Vector3(0, 2.5, 1.5)

	add_child(darkness_mesh)

	# Add glow around entrance to make it visible
	var glow_light := OmniLight3D.new()
	glow_light.light_color = Color(0.3, 0.25, 0.2)
	glow_light.light_energy = 0.5
	glow_light.omni_range = 8.0
	glow_light.position = Vector3(0, 3.0, 4.0)
	add_child(glow_light)


func _create_rock_mesh(size: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.material_override = mat
	return mesh_inst


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
