extends ResourceNode
class_name CrystalNode
## A glowing crystal found in caves. Hand-gatherable, provides faint light.

# Crystal-specific properties
@export var crystal_color: Color = Color(0.4, 0.6, 1.0)  # Blue-purple glow
@export var glow_intensity: float = 2.0
@export var glow_range: float = 5.0

# Visual nodes
var crystal_mesh: MeshInstance3D = null
var glow_light: OmniLight3D = null


func _ready() -> void:
	# Set resource properties
	resource_type = "crystal"
	resource_amount = 1
	interaction_text = "Gather"
	required_tool = ""  # Hand-gatherable
	chops_required = 1
	adjust_to_terrain = false  # Caves don't use terrain height

	# Store original scale
	original_scale = scale

	# Add to groups
	add_to_group("interactable")
	add_to_group("resource_node")
	add_to_group("crystal")

	# Create crystal visual
	call_deferred("_setup_crystal_visual")


func _setup_crystal_visual() -> void:
	# Main crystal material - emissive glow
	var mat := StandardMaterial3D.new()
	mat.albedo_color = crystal_color
	mat.emission_enabled = true
	mat.emission = crystal_color
	mat.emission_energy_multiplier = 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.85
	mat.roughness = 0.1
	mat.metallic = 0.3

	# Deeper/darker crystal material for variety
	var deep_mat := StandardMaterial3D.new()
	deep_mat.albedo_color = Color(crystal_color.r * 0.6, crystal_color.g * 0.6, crystal_color.b * 0.8)
	deep_mat.emission_enabled = true
	deep_mat.emission = Color(crystal_color.r * 0.5, crystal_color.g * 0.5, crystal_color.b * 0.7)
	deep_mat.emission_energy_multiplier = 2.0
	deep_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	deep_mat.albedo_color.a = 0.9
	deep_mat.roughness = 0.08
	deep_mat.metallic = 0.4

	# Bright highlight material
	var bright_mat := StandardMaterial3D.new()
	bright_mat.albedo_color = Color(
		min(crystal_color.r + 0.3, 1.0),
		min(crystal_color.g + 0.3, 1.0),
		min(crystal_color.b + 0.2, 1.0), 0.75
	)
	bright_mat.emission_enabled = true
	bright_mat.emission = Color(
		min(crystal_color.r + 0.3, 1.0),
		min(crystal_color.g + 0.3, 1.0),
		min(crystal_color.b + 0.2, 1.0)
	)
	bright_mat.emission_energy_multiplier = 4.0
	bright_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bright_mat.roughness = 0.05
	bright_mat.metallic = 0.5

	# Rock base material
	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.28, 0.26, 0.24)
	rock_mat.roughness = 0.92

	# Rock base cluster (crystals growing from rock)
	var base := MeshInstance3D.new()
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(0.5, 0.15, 0.45)
	base.mesh = base_mesh
	base.position = Vector3(0, 0.075, 0)
	base.rotation.y = randf_range(0, TAU)
	base.material_override = rock_mat
	add_child(base)

	# Rock detail (second overlapping rock)
	var base2 := MeshInstance3D.new()
	var b2_mesh := BoxMesh.new()
	b2_mesh.size = Vector3(0.35, 0.12, 0.4)
	base2.mesh = b2_mesh
	base2.position = Vector3(0.08, 0.06, 0.05)
	base2.rotation.y = 0.8
	var rock_light_mat := StandardMaterial3D.new()
	rock_light_mat.albedo_color = Color(0.32, 0.30, 0.28)
	rock_light_mat.roughness = 0.90
	base2.material_override = rock_light_mat
	add_child(base2)

	# Main crystal body - tall central spire
	crystal_mesh = MeshInstance3D.new()
	crystal_mesh.name = "CrystalMesh"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.22, 0.8, 0.22)
	crystal_mesh.mesh = mesh
	crystal_mesh.rotation_degrees = Vector3(randf_range(-12, 12), randf_range(0, 360), randf_range(-12, 12))
	crystal_mesh.position = Vector3(0, 0.5, 0)
	crystal_mesh.material_override = mat
	add_child(crystal_mesh)

	# Crystal tip (brighter, tapered top)
	var tip := MeshInstance3D.new()
	var tip_mesh := BoxMesh.new()
	tip_mesh.size = Vector3(0.12, 0.2, 0.12)
	tip.mesh = tip_mesh
	tip.position = Vector3(0, 0.95, 0)
	tip.rotation_degrees = crystal_mesh.rotation_degrees
	tip.material_override = bright_mat
	add_child(tip)

	# Internal refraction lines (lighter streaks inside crystal)
	for i: int in range(2):
		var streak := MeshInstance3D.new()
		var sr_mesh := BoxMesh.new()
		sr_mesh.size = Vector3(0.04, 0.6, 0.04)
		streak.mesh = sr_mesh
		streak.position = Vector3(-0.05 + i * 0.1, 0.5, -0.04 + i * 0.08)
		streak.rotation_degrees = crystal_mesh.rotation_degrees
		streak.material_override = bright_mat
		add_child(streak)

	# Secondary crystals (4 smaller ones around base, varied sizes)
	var secondary_data: Array[Dictionary] = [
		{"size": Vector3(0.12, 0.45, 0.12), "mat": mat},
		{"size": Vector3(0.10, 0.35, 0.10), "mat": deep_mat},
		{"size": Vector3(0.14, 0.5, 0.14), "mat": mat},
		{"size": Vector3(0.08, 0.25, 0.08), "mat": bright_mat},
	]

	for i: int in range(4):
		var secondary := MeshInstance3D.new()
		var sec_mesh := BoxMesh.new()
		sec_mesh.size = secondary_data[i]["size"]
		secondary.mesh = sec_mesh
		secondary.material_override = secondary_data[i]["mat"] as StandardMaterial3D

		var angle: float = randf_range(0, TAU)
		var dist: float = randf_range(0.18, 0.35)
		var height: float = secondary_data[i]["size"].y / 2.0 + 0.1
		secondary.position = Vector3(cos(angle) * dist, height, sin(angle) * dist)
		secondary.rotation_degrees = Vector3(randf_range(-25, 25), randf_range(0, 360), randf_range(-25, 25))
		add_child(secondary)

	# Tiny ground crystals (scattered shards at base)
	for i: int in range(5):
		var shard := MeshInstance3D.new()
		var sh_mesh := BoxMesh.new()
		sh_mesh.size = Vector3(0.04, 0.08, 0.04)
		shard.mesh = sh_mesh
		shard.material_override = deep_mat
		var sa: float = randf_range(0, TAU)
		var sd: float = randf_range(0.2, 0.4)
		shard.position = Vector3(cos(sa) * sd, 0.04, sin(sa) * sd)
		shard.rotation_degrees = Vector3(randf_range(-30, 30), randf_range(0, 360), randf_range(-30, 30))
		add_child(shard)

	# Add glow light
	glow_light = OmniLight3D.new()
	glow_light.name = "GlowLight"
	glow_light.light_color = crystal_color
	glow_light.light_energy = glow_intensity
	glow_light.omni_range = glow_range
	glow_light.shadow_enabled = false
	glow_light.position = Vector3(0, 0.5, 0)
	add_child(glow_light)

	# Add collision shape
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.5, 1.0, 0.5)
	collision.shape = shape
	collision.position = Vector3(0, 0.5, 0)
	add_child(collision)


## Override interaction for crystal-specific behavior.
func interact(player: Node) -> bool:
	if is_depleted or is_animating:
		return false

	# Crystals are hand-gatherable - no tool check needed
	_play_gather_animation()

	# Play pickup sound
	SFXManager.play_sfx("pickup")

	# Emit signal
	gathered.emit(resource_type, resource_amount)

	# Add to player inventory
	var inventory: Inventory = _get_player_inventory(player)
	if inventory:
		inventory.add_item(resource_type, resource_amount)
		print("[Crystal] +%d crystal" % resource_amount)

	# Mark as depleted
	is_depleted = true
	depleted.emit()

	return true


func get_interaction_text() -> String:
	if is_depleted:
		return ""
	return "Gather Crystal"


## Override gather animation for crystal-specific effect.
func _play_gather_animation() -> void:
	is_animating = true

	# Crystal-specific animation: pulse and fade
	var tween: Tween = create_tween()
	tween.set_parallel(true)

	# Pulse brighter
	if glow_light:
		tween.tween_property(glow_light, "light_energy", glow_intensity * 3.0, 0.15)

	# Scale up briefly
	tween.tween_property(self, "scale", original_scale * 1.2, 0.15)

	# Then shrink and fade
	tween.chain()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.3)
	if glow_light:
		tween.tween_property(glow_light, "light_energy", 0.0, 0.3)

	tween.chain().tween_callback(_on_gather_animation_complete)
