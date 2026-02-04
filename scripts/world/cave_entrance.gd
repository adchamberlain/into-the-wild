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


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("cave_entrance")

	# Create visual representation
	call_deferred("_setup_visuals")


func _setup_visuals() -> void:
	# Create collision shape
	var collision := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(6.0, 5.0, 4.0)
	collision.shape = box_shape
	collision.position = Vector3(0, 2.5, 0)
	add_child(collision)

	# Rocky arch entrance - create boulders forming an opening
	var rock_color := Color(0.4, 0.38, 0.35)
	var dark_rock := Color(0.25, 0.24, 0.22)

	# Left pillar
	var left_pillar := _create_rock_mesh(Vector3(1.8, 4.0, 1.5), rock_color)
	left_pillar.position = Vector3(-2.5, 2.0, 0)
	left_pillar.rotation_degrees = Vector3(0, 5, -8)
	add_child(left_pillar)
	arch_meshes.append(left_pillar)

	# Right pillar
	var right_pillar := _create_rock_mesh(Vector3(2.0, 4.5, 1.6), rock_color)
	right_pillar.position = Vector3(2.5, 2.25, 0)
	right_pillar.rotation_degrees = Vector3(0, -8, 6)
	add_child(right_pillar)
	arch_meshes.append(right_pillar)

	# Top arch boulder
	var top_arch := _create_rock_mesh(Vector3(6.0, 1.5, 2.0), rock_color)
	top_arch.position = Vector3(0, 4.5, 0)
	top_arch.rotation_degrees = Vector3(5, 0, 3)
	add_child(top_arch)
	arch_meshes.append(top_arch)

	# Additional detail rocks
	var detail1 := _create_rock_mesh(Vector3(1.2, 1.0, 0.8), rock_color)
	detail1.position = Vector3(-3.0, 0.5, 0.5)
	add_child(detail1)
	arch_meshes.append(detail1)

	var detail2 := _create_rock_mesh(Vector3(1.0, 0.8, 1.0), rock_color)
	detail2.position = Vector3(3.2, 0.4, 0.3)
	add_child(detail2)
	arch_meshes.append(detail2)

	# Dark opening (the cave mouth)
	darkness_mesh = MeshInstance3D.new()
	darkness_mesh.name = "DarkOpening"
	var dark_mesh := BoxMesh.new()
	dark_mesh.size = Vector3(3.5, 3.5, 0.5)
	darkness_mesh.mesh = dark_mesh

	var dark_mat := StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.02, 0.02, 0.02)  # Nearly black
	dark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	darkness_mesh.material_override = dark_mat
	darkness_mesh.position = Vector3(0, 2.0, 0.5)

	add_child(darkness_mesh)

	# Add some glow around entrance to make it visible
	var glow_light := OmniLight3D.new()
	glow_light.light_color = Color(0.3, 0.25, 0.2)  # Dim warm glow
	glow_light.light_energy = 0.5
	glow_light.omni_range = 8.0
	glow_light.position = Vector3(0, 3.0, 2.0)
	add_child(glow_light)


func _create_rock_mesh(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
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
