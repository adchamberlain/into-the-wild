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
	# Main crystal body - elongated prism-like shape using multiple boxes
	crystal_mesh = MeshInstance3D.new()
	crystal_mesh.name = "CrystalMesh"

	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.3, 0.8, 0.3)
	crystal_mesh.mesh = mesh

	# Emissive material for glow effect
	var mat := StandardMaterial3D.new()
	mat.albedo_color = crystal_color
	mat.emission_enabled = true
	mat.emission = crystal_color
	mat.emission_energy_multiplier = 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.85
	mat.roughness = 0.1
	mat.metallic = 0.3
	crystal_mesh.material_override = mat

	# Tilt crystal for natural look
	crystal_mesh.rotation_degrees = Vector3(randf_range(-15, 15), randf_range(0, 360), randf_range(-15, 15))
	crystal_mesh.position = Vector3(0, 0.4, 0)

	add_child(crystal_mesh)

	# Add smaller secondary crystals
	for i in range(2):
		var secondary := MeshInstance3D.new()
		var sec_mesh := BoxMesh.new()
		sec_mesh.size = Vector3(0.15, 0.4, 0.15)
		secondary.mesh = sec_mesh
		secondary.material_override = mat

		var angle: float = randf_range(0, TAU)
		var dist: float = randf_range(0.2, 0.35)
		secondary.position = Vector3(cos(angle) * dist, 0.2, sin(angle) * dist)
		secondary.rotation_degrees = Vector3(randf_range(-25, 25), randf_range(0, 360), randf_range(-25, 25))

		add_child(secondary)

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
