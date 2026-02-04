extends StaticBody3D
class_name ObstacleThorns
## Thorny bush obstacle that blocks paths until cleared with a machete.

signal cleared()

# Obstacle properties
@export var chops_required: int = 3
@export var required_tool: String = "machete"

# State
var is_cleared: bool = false
var chop_progress: float = 0.0

# Visual nodes
var thorn_meshes: Array[MeshInstance3D] = []


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("obstacle")

	# Create visual representation
	call_deferred("_setup_visuals")


func _setup_visuals() -> void:
	# Create collision shape for blocking
	var collision := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(8.0, 3.0, 4.0)  # Wide obstacle to block paths
	collision.shape = box_shape
	collision.position = Vector3(0, 1.5, 0)
	add_child(collision)

	# Create tangled bramble visuals using multiple overlapping boxes
	var base_color := Color(0.25, 0.35, 0.15)  # Dark green
	var thorn_color := Color(0.35, 0.25, 0.15)  # Brown

	# Main bramble clusters - create a dense wall
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x * 1000 + global_position.z * 100)

	for i in range(12):
		var cluster := MeshInstance3D.new()
		var mesh := BoxMesh.new()

		# Varied sizes for organic look
		var size_x: float = rng.randf_range(1.0, 2.5)
		var size_y: float = rng.randf_range(1.5, 3.0)
		var size_z: float = rng.randf_range(0.8, 1.8)
		mesh.size = Vector3(size_x, size_y, size_z)
		cluster.mesh = mesh

		# Random position within obstacle footprint
		var pos_x: float = rng.randf_range(-3.0, 3.0)
		var pos_z: float = rng.randf_range(-1.5, 1.5)
		var pos_y: float = size_y / 2.0 + rng.randf_range(-0.2, 0.3)
		cluster.position = Vector3(pos_x, pos_y, pos_z)

		# Slight rotation for variety
		cluster.rotation_degrees = Vector3(
			rng.randf_range(-15, 15),
			rng.randf_range(-30, 30),
			rng.randf_range(-10, 10)
		)

		# Material - alternate between green brambles and brown thorns
		var mat := StandardMaterial3D.new()
		if i % 3 == 0:
			mat.albedo_color = thorn_color
		else:
			mat.albedo_color = base_color
		mat.roughness = 0.9
		cluster.material_override = mat

		add_child(cluster)
		thorn_meshes.append(cluster)

	# Add some thorn spikes sticking out
	for i in range(8):
		var spike := MeshInstance3D.new()
		var spike_mesh := BoxMesh.new()
		spike_mesh.size = Vector3(0.1, 0.4, 0.1)
		spike.mesh = spike_mesh

		var pos_x: float = rng.randf_range(-3.5, 3.5)
		var pos_z: float = rng.randf_range(-2.0, 2.0)
		var pos_y: float = rng.randf_range(0.5, 2.5)
		spike.position = Vector3(pos_x, pos_y, pos_z)
		spike.rotation_degrees = Vector3(
			rng.randf_range(-45, 45),
			rng.randf_range(0, 360),
			rng.randf_range(-45, 45)
		)

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.3, 0.2)
		spike.material_override = mat

		add_child(spike)
		thorn_meshes.append(spike)


## Get interaction text for HUD prompt.
func get_interaction_text() -> String:
	if is_cleared:
		return ""

	# Check if player has machete equipped
	var player: Node = get_tree().get_first_node_in_group("player")
	if player:
		var equipment: Equipment = _get_player_equipment(player)
		if equipment and equipment.has_tool_equipped(required_tool):
			return "Clear Thorns (%d/%d)" % [int(chop_progress), chops_required]

	return "Thorns (Need Machete)"


## Called when player interacts with this obstacle.
func interact(player: Node) -> bool:
	if is_cleared:
		return false

	# Check for machete
	var equipment: Equipment = _get_player_equipment(player)
	if not equipment or not equipment.has_tool_equipped(required_tool):
		_show_notification("Need a machete to clear these thorns!", Color(1.0, 0.6, 0.4))
		return true  # Consume interaction but don't clear

	# Clearing is done via receive_chop from equipment use
	_show_notification("Use swing (R) to clear thorns", Color(0.8, 0.8, 0.6))
	return true


## Called when player chops this obstacle with a machete.
func receive_chop(player: Node) -> bool:
	if is_cleared:
		return false

	# Check tool requirement
	var equipment: Equipment = _get_player_equipment(player)
	if not equipment or not equipment.has_tool_equipped(required_tool):
		return false

	# Apply tool effectiveness
	var effectiveness: float = equipment.get_tool_effectiveness()
	chop_progress += effectiveness
	print("[Thorns] Chop %.1f/%d" % [chop_progress, chops_required])

	# Play chop feedback
	_play_chop_animation()

	# Check if cleared
	if chop_progress >= float(chops_required):
		call_deferred("_clear_obstacle")

	return true


func _clear_obstacle() -> void:
	is_cleared = true

	# Play clear sound
	var sfx: Node = get_node_or_null("/root/SFXManager")
	if sfx and sfx.has_method("play_sfx"):
		sfx.play_sfx("thorns_clear")

	# Animate clearing - shrink and fade
	var tween: Tween = create_tween()
	tween.set_parallel(true)

	for mesh in thorn_meshes:
		if is_instance_valid(mesh):
			tween.tween_property(mesh, "scale", Vector3.ZERO, 0.5)

	tween.chain().tween_callback(_finish_clear)

	_show_notification("Thorns cleared!", Color(0.6, 1.0, 0.6))
	print("[Thorns] Obstacle cleared!")


func _finish_clear() -> void:
	# Disable collision so player can pass through
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = true

	# Remove from interactable group
	remove_from_group("interactable")

	# Hide all visuals
	for mesh in thorn_meshes:
		if is_instance_valid(mesh):
			mesh.visible = false

	cleared.emit()


func _play_chop_animation() -> void:
	# Shake animation when chopped
	var tween: Tween = create_tween()
	var shake_amount: float = 0.15

	tween.tween_property(self, "position:x", position.x + shake_amount, 0.04)
	tween.tween_property(self, "position:x", position.x - shake_amount, 0.04)
	tween.tween_property(self, "position:x", position.x + shake_amount * 0.5, 0.04)
	tween.tween_property(self, "position:x", position.x, 0.04)


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


## Get save data for persistence.
func get_save_data() -> Dictionary:
	return {
		"position": {"x": global_position.x, "y": global_position.y, "z": global_position.z},
		"is_cleared": is_cleared,
		"chop_progress": chop_progress
	}


## Load save data to restore state.
func load_save_data(data: Dictionary) -> void:
	is_cleared = data.get("is_cleared", false)
	chop_progress = data.get("chop_progress", 0.0)

	if is_cleared:
		call_deferred("_apply_cleared_state")


func _apply_cleared_state() -> void:
	# Apply cleared state visually
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = true

	remove_from_group("interactable")

	for mesh in thorn_meshes:
		if is_instance_valid(mesh):
			mesh.visible = false
