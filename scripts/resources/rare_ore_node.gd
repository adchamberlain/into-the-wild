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
	# Main ore body - irregular rock shape
	ore_mesh = MeshInstance3D.new()
	ore_mesh.name = "OreMesh"

	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.9, 0.7, 0.8)
	ore_mesh.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = ore_color
	mat.roughness = 0.9
	ore_mesh.material_override = mat
	ore_mesh.position = Vector3(0, 0.35, 0)
	ore_mesh.rotation_degrees = Vector3(randf_range(-5, 5), randf_range(0, 45), randf_range(-5, 5))

	add_child(ore_mesh)

	# Add golden emissive veins
	var vein_mat := StandardMaterial3D.new()
	vein_mat.albedo_color = vein_color
	vein_mat.emission_enabled = true
	vein_mat.emission = vein_color
	vein_mat.emission_energy_multiplier = 2.0
	vein_mat.metallic = 0.8
	vein_mat.roughness = 0.2

	for i in range(4):
		var vein := MeshInstance3D.new()
		var vein_mesh := BoxMesh.new()
		vein_mesh.size = Vector3(randf_range(0.05, 0.1), randf_range(0.3, 0.5), randf_range(0.02, 0.04))
		vein.mesh = vein_mesh
		vein.material_override = vein_mat

		# Position veins on surface of ore
		var angle: float = randf_range(0, TAU)
		var y_pos: float = randf_range(0.15, 0.55)
		vein.position = Vector3(cos(angle) * 0.4, y_pos, sin(angle) * 0.35)
		vein.rotation_degrees = Vector3(randf_range(-20, 20), randf_range(0, 360), randf_range(-30, 30))

		add_child(vein)
		vein_meshes.append(vein)

	# Add subtle glow from the veins
	var glow := OmniLight3D.new()
	glow.light_color = vein_color
	glow.light_energy = 1.0
	glow.omni_range = 3.0
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
