extends ResourceNode
class_name RareOreNode
## A rare ore deposit found in caves. Requires pickaxe to mine, yields valuable ore.

# Rare ore specific properties
var ore_color: Color = Color(0.25, 0.22, 0.2)  # Dark stone
var vein_color: Color = Color(0.9, 0.75, 0.3)  # Golden veins

# Visual nodes
var ore_mesh: MeshInstance3D = null
var vein_meshes: Array[MeshInstance3D] = []


func _ready() -> void:
	# Set resource properties
	resource_type = "rare_ore"
	resource_amount = 1
	interaction_text = "Mine"
	required_tool = "axe"  # Use axe for mining (same as regular ore)
	chops_required = 5  # Harder to mine than regular ore
	secondary_resource_type = "crystal"
	secondary_resource_amount = 1
	adjust_to_terrain = false  # Caves don't use terrain height

	# Store original scale
	original_scale = scale

	# Add to groups
	add_to_group("interactable")
	add_to_group("resource_node")
	add_to_group("rare_ore")

	# Create ore visual
	call_deferred("_setup_ore_visual")


func _setup_ore_visual() -> void:
	# Rock materials with variation
	var rock_base_mat := StandardMaterial3D.new()
	rock_base_mat.albedo_color = ore_color
	rock_base_mat.roughness = 0.92

	var rock_dark_mat := StandardMaterial3D.new()
	rock_dark_mat.albedo_color = Color(ore_color.r - 0.06, ore_color.g - 0.06, ore_color.b - 0.05)
	rock_dark_mat.roughness = 0.95

	var rock_light_mat := StandardMaterial3D.new()
	rock_light_mat.albedo_color = Color(ore_color.r + 0.08, ore_color.g + 0.08, ore_color.b + 0.06)
	rock_light_mat.roughness = 0.88

	# Main ore body - large central rock
	ore_mesh = MeshInstance3D.new()
	ore_mesh.name = "OreMesh"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.85, 0.65, 0.75)
	ore_mesh.mesh = mesh
	ore_mesh.material_override = rock_base_mat
	ore_mesh.position = Vector3(0, 0.32, 0)
	ore_mesh.rotation_degrees = Vector3(randf_range(-5, 5), randf_range(0, 45), randf_range(-5, 5))
	add_child(ore_mesh)

	# Secondary rock mass (overlapping for irregular shape)
	var rock2 := MeshInstance3D.new()
	var r2_mesh := BoxMesh.new()
	r2_mesh.size = Vector3(0.55, 0.5, 0.6)
	rock2.mesh = r2_mesh
	rock2.material_override = rock_dark_mat
	rock2.position = Vector3(0.2, 0.28, 0.1)
	rock2.rotation_degrees = Vector3(8, 25, -5)
	add_child(rock2)

	# Top rock (lighter, catching light)
	var rock3 := MeshInstance3D.new()
	var r3_mesh := BoxMesh.new()
	r3_mesh.size = Vector3(0.5, 0.3, 0.45)
	rock3.mesh = r3_mesh
	rock3.material_override = rock_light_mat
	rock3.position = Vector3(-0.1, 0.55, -0.05)
	rock3.rotation_degrees = Vector3(-5, 15, 8)
	add_child(rock3)

	# Rock base (wider, anchoring to ground)
	var base := MeshInstance3D.new()
	var b_mesh := BoxMesh.new()
	b_mesh.size = Vector3(1.0, 0.15, 0.9)
	base.mesh = b_mesh
	base.material_override = rock_dark_mat
	base.position = Vector3(0, 0.075, 0)
	add_child(base)

	# Crack lines on rock surface (darker fissures)
	var crack_mat := StandardMaterial3D.new()
	crack_mat.albedo_color = Color(0.12, 0.10, 0.08)
	for i: int in range(3):
		var crack := MeshInstance3D.new()
		var cr_mesh := BoxMesh.new()
		cr_mesh.size = Vector3(randf_range(0.02, 0.03), randf_range(0.3, 0.5), randf_range(0.76, 0.82))
		crack.mesh = cr_mesh
		crack.material_override = crack_mat
		crack.position = Vector3(-0.2 + i * 0.2, 0.35, 0)
		crack.rotation_degrees = Vector3(0, randf_range(-15, 15), 0)
		add_child(crack)

	# Golden emissive veins (rich metallic streaks)
	var vein_mat := StandardMaterial3D.new()
	vein_mat.albedo_color = vein_color
	vein_mat.emission_enabled = true
	vein_mat.emission = vein_color
	vein_mat.emission_energy_multiplier = 2.5
	vein_mat.metallic = 0.85
	vein_mat.roughness = 0.15

	var vein_bright_mat := StandardMaterial3D.new()
	vein_bright_mat.albedo_color = Color(1.0, 0.88, 0.45)
	vein_bright_mat.emission_enabled = true
	vein_bright_mat.emission = Color(1.0, 0.85, 0.4)
	vein_bright_mat.emission_energy_multiplier = 3.5
	vein_bright_mat.metallic = 0.9
	vein_bright_mat.roughness = 0.1

	for i: int in range(6):
		var vein := MeshInstance3D.new()
		var vein_mesh := BoxMesh.new()
		vein_mesh.size = Vector3(randf_range(0.04, 0.09), randf_range(0.2, 0.45), randf_range(0.02, 0.04))
		vein.mesh = vein_mesh
		vein.material_override = vein_mat if i < 4 else vein_bright_mat

		var angle: float = randf_range(0, TAU)
		var y_pos: float = randf_range(0.12, 0.58)
		vein.position = Vector3(cos(angle) * 0.38, y_pos, sin(angle) * 0.33)
		vein.rotation_degrees = Vector3(randf_range(-20, 20), randf_range(0, 360), randf_range(-30, 30))

		add_child(vein)
		vein_meshes.append(vein)

	# Gold nugget spots (small bright spots where vein hits surface)
	for i: int in range(4):
		var nugget := MeshInstance3D.new()
		var n_mesh := BoxMesh.new()
		n_mesh.size = Vector3(0.05, 0.05, 0.05)
		nugget.mesh = n_mesh
		nugget.material_override = vein_bright_mat
		var na: float = randf_range(0, TAU)
		nugget.position = Vector3(cos(na) * 0.42, randf_range(0.15, 0.55), sin(na) * 0.38)
		add_child(nugget)

	# Subtle glow from the veins
	var glow := OmniLight3D.new()
	glow.light_color = vein_color
	glow.light_energy = 1.2
	glow.omni_range = 3.5
	glow.shadow_enabled = false
	glow.position = Vector3(0, 0.4, 0)
	add_child(glow)

	# Add collision shape
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, 0.8, 0.9)
	collision.shape = shape
	collision.position = Vector3(0, 0.4, 0)
	add_child(collision)


func get_interaction_text() -> String:
	if is_depleted:
		return ""

	# Check if player has required tool
	var player_node: Node = get_tree().get_first_node_in_group("player")
	if player_node:
		var equipment: Equipment = _get_player_equipment(player_node)
		if equipment and equipment.has_tool_equipped(required_tool):
			return "Mine Rare Ore (%d/%d)" % [chop_progress, chops_required]

	return "Rare Ore (Need Pickaxe)"
