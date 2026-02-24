extends ResourceNode
class_name GemNode
## An underwater gem deposit found on desert oasis pool floors.
## Players dive underwater and mine these like ore.

# Gem variant - set before _ready() to configure
var gem_type: String = "diamond"

# Shared static materials (one set per variant, shared across all instances)
static var _diamond_mat: StandardMaterial3D = null
static var _diamond_glow_mat: StandardMaterial3D = null
static var _opal_mat: StandardMaterial3D = null
static var _opal_glow_mat: StandardMaterial3D = null
static var _halo_mat: StandardMaterial3D = null
static var _materials_initialized: bool = false


func _ready() -> void:
	_ensure_shared_materials()

	# Configure resource properties based on gem variant BEFORE super._ready()
	match gem_type:
		"opal":
			resource_type = "opal"
			resource_amount = 1
			interaction_text = "Mine Opal"
		_:  # default: diamond
			gem_type = "diamond"
			resource_type = "diamond"
			resource_amount = 1
			interaction_text = "Mine Diamond"

	required_tool = "axe"
	chops_required = 4
	adjust_to_terrain = false  # Placed at specific position on pool floor

	# Call super to set original_scale, node_name, and add to groups
	super._ready()

	add_to_group("gem")

	# Build the visual mesh
	call_deferred("_build_gem_mesh")


static func _ensure_shared_materials() -> void:
	if _materials_initialized:
		return
	_materials_initialized = true

	# Diamond material: blue-white with emission (opaque so it renders through water)
	_diamond_mat = StandardMaterial3D.new()
	_diamond_mat.albedo_color = Color(0.7, 0.85, 1.0)
	_diamond_mat.emission_enabled = true
	_diamond_mat.emission = Color(0.4, 0.6, 1.0)
	_diamond_mat.emission_energy_multiplier = 0.8
	_diamond_mat.roughness = 0.05
	_diamond_mat.metallic = 0.4

	# Diamond glow (brighter variant for tips/accents)
	_diamond_glow_mat = StandardMaterial3D.new()
	_diamond_glow_mat.albedo_color = Color(0.8, 0.92, 1.0)
	_diamond_glow_mat.emission_enabled = true
	_diamond_glow_mat.emission = Color(0.5, 0.7, 1.0)
	_diamond_glow_mat.emission_energy_multiplier = 1.2
	_diamond_glow_mat.roughness = 0.03
	_diamond_glow_mat.metallic = 0.5

	# Opal material: purple-white with emission (opaque so it renders through water)
	_opal_mat = StandardMaterial3D.new()
	_opal_mat.albedo_color = Color(0.85, 0.75, 1.0)
	_opal_mat.emission_enabled = true
	_opal_mat.emission = Color(0.6, 0.4, 0.9)
	_opal_mat.emission_energy_multiplier = 0.8
	_opal_mat.roughness = 0.05
	_opal_mat.metallic = 0.4

	# Opal glow (brighter variant for tips/accents)
	_opal_glow_mat = StandardMaterial3D.new()
	_opal_glow_mat.albedo_color = Color(0.92, 0.82, 1.0)
	_opal_glow_mat.emission_enabled = true
	_opal_glow_mat.emission = Color(0.7, 0.5, 1.0)
	_opal_glow_mat.emission_energy_multiplier = 1.2
	_opal_glow_mat.roughness = 0.03
	_opal_glow_mat.metallic = 0.5

	# Glow halo: semi-transparent white with strong emission
	_halo_mat = StandardMaterial3D.new()
	_halo_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.15)
	_halo_mat.emission_enabled = true
	_halo_mat.emission = Color(0.9, 0.95, 1.0)
	_halo_mat.emission_energy_multiplier = 1.5
	_halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_halo_mat.roughness = 0.1


func _build_gem_mesh() -> void:
	# Select materials based on gem type
	var crystal_mat: StandardMaterial3D
	var glow_mat: StandardMaterial3D
	if gem_type == "opal":
		crystal_mat = _opal_mat
		glow_mat = _opal_glow_mat
	else:
		crystal_mat = _diamond_mat
		glow_mat = _diamond_glow_mat

	# Crystal cluster: 4 angled BoxMesh columns of varying height
	var column_data: Array[Dictionary] = [
		{"height": 0.55, "width": 0.1, "offset": Vector3(0, 0, 0), "tilt": Vector3(-8, 0, 5)},
		{"height": 0.4, "width": 0.08, "offset": Vector3(0.12, 0, 0.06), "tilt": Vector3(10, 30, -12)},
		{"height": 0.6, "width": 0.09, "offset": Vector3(-0.08, 0, 0.1), "tilt": Vector3(6, -20, 15)},
		{"height": 0.3, "width": 0.07, "offset": Vector3(0.05, 0, -0.1), "tilt": Vector3(-12, 50, -8)},
	]

	for i: int in range(4):
		var data: Dictionary = column_data[i]
		var h: float = data["height"]
		var w: float = data["width"]
		var col_offset: Vector3 = data["offset"]
		var tilt: Vector3 = data["tilt"]

		# Main crystal column
		var column: MeshInstance3D = MeshInstance3D.new()
		var col_mesh: BoxMesh = BoxMesh.new()
		col_mesh.size = Vector3(w, h, w)
		column.mesh = col_mesh
		column.material_override = crystal_mat
		column.position = Vector3(col_offset.x, h / 2.0, col_offset.z)
		column.rotation_degrees = tilt
		add_child(column)

		# Bright tip on each column
		var tip: MeshInstance3D = MeshInstance3D.new()
		var tip_mesh: BoxMesh = BoxMesh.new()
		tip_mesh.size = Vector3(w * 0.6, h * 0.25, w * 0.6)
		tip.mesh = tip_mesh
		tip.material_override = glow_mat
		tip.position = Vector3(col_offset.x, h * 0.85, col_offset.z)
		tip.rotation_degrees = tilt
		add_child(tip)

	# Glow halo sphere (flat disc for underwater light effect)
	var halo: MeshInstance3D = MeshInstance3D.new()
	var halo_mesh: BoxMesh = BoxMesh.new()
	halo_mesh.size = Vector3(0.6, 0.05, 0.6)
	halo.mesh = halo_mesh
	halo.material_override = _halo_mat
	halo.position = Vector3(0, 0.25, 0)
	add_child(halo)

	# Omni light for underwater glow
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = _diamond_mat.emission if gem_type == "diamond" else _opal_mat.emission
	light.light_energy = 0.6
	light.omni_range = 2.5
	light.shadow_enabled = false
	light.position = Vector3(0, 0.3, 0)
	add_child(light)

	# Collision shape
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(0.4, 0.65, 0.4)
	collision.shape = shape
	collision.position = Vector3(0, 0.3, 0)
	add_child(collision)

	# If loaded as depleted, disable collision
	if is_depleted:
		collision.disabled = true


func get_interaction_text() -> String:
	if is_depleted:
		return ""

	# Check if player has required tool
	var player_node: Node = get_tree().get_first_node_in_group("player")
	if player_node:
		var equipment: Equipment = _get_player_equipment(player_node)
		if equipment and equipment.has_tool_equipped(required_tool):
			var display: String = gem_type.capitalize()
			return "Mine %s (%d/%d)" % [display, chop_progress, chops_required]

	return "%s (Need Axe)" % gem_type.capitalize()
