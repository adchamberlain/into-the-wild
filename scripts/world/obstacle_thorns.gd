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

# Shared materials (static to avoid shader compilation per instance)
static var _base_mat: StandardMaterial3D = null
static var _thorn_mat: StandardMaterial3D = null
static var _spike_mat: StandardMaterial3D = null


static func _get_base_material() -> StandardMaterial3D:
	if not _base_mat:
		_base_mat = StandardMaterial3D.new()
		_base_mat.albedo_color = Color(0.25, 0.35, 0.15)  # Dark green
		_base_mat.roughness = 0.9
	return _base_mat


static func _get_thorn_material() -> StandardMaterial3D:
	if not _thorn_mat:
		_thorn_mat = StandardMaterial3D.new()
		_thorn_mat.albedo_color = Color(0.35, 0.25, 0.15)  # Brown
		_thorn_mat.roughness = 0.9
	return _thorn_mat


static func _get_spike_material() -> StandardMaterial3D:
	if not _spike_mat:
		_spike_mat = StandardMaterial3D.new()
		_spike_mat.albedo_color = Color(0.4, 0.3, 0.2)
	return _spike_mat


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

	# Get shared materials (avoids shader compilation per obstacle)
	var base_mat: StandardMaterial3D = _get_base_material()
	var thorn_mat: StandardMaterial3D = _get_thorn_material()
	var spike_mat: StandardMaterial3D = _get_spike_material()

	# Leaf material (lighter green)
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.20, 0.38, 0.12)
	leaf_mat.roughness = 0.85

	# Berry material (dark red-purple)
	var berry_mat := StandardMaterial3D.new()
	berry_mat.albedo_color = Color(0.35, 0.10, 0.15)

	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x * 1000 + global_position.z * 100)

	# 6 main bramble clusters (keep performance-friendly count)
	for i: int in range(6):
		var cluster := MeshInstance3D.new()
		var mesh := BoxMesh.new()

		var size_x: float = rng.randf_range(2.0, 3.5)
		var size_y: float = rng.randf_range(2.0, 3.5)
		var size_z: float = rng.randf_range(1.5, 2.5)
		mesh.size = Vector3(size_x, size_y, size_z)
		cluster.mesh = mesh

		var pos_x: float = (i - 2.5) * 2.5 + rng.randf_range(-0.5, 0.5)
		var pos_z: float = rng.randf_range(-0.8, 0.8)
		var pos_y: float = size_y / 2.0 + rng.randf_range(-0.1, 0.2)
		cluster.position = Vector3(pos_x, pos_y, pos_z)

		cluster.rotation_degrees = Vector3(
			rng.randf_range(-10, 10),
			rng.randf_range(-20, 20),
			rng.randf_range(-8, 8)
		)

		cluster.material_override = thorn_mat if i % 2 == 0 else base_mat

		add_child(cluster)
		thorn_meshes.append(cluster)

		# Leaf clusters on each bramble (2-3 per cluster)
		for j: int in range(rng.randi_range(2, 3)):
			var leaf := MeshInstance3D.new()
			var l_mesh := BoxMesh.new()
			l_mesh.size = Vector3(
				rng.randf_range(0.8, 1.5),
				rng.randf_range(0.6, 1.2),
				rng.randf_range(0.8, 1.3)
			)
			leaf.mesh = l_mesh
			leaf.position = Vector3(
				pos_x + rng.randf_range(-0.6, 0.6),
				pos_y + rng.randf_range(-0.3, 0.5),
				pos_z + rng.randf_range(-0.4, 0.4)
			)
			leaf.rotation_degrees = Vector3(
				rng.randf_range(-15, 15),
				rng.randf_range(-30, 30),
				rng.randf_range(-10, 10)
			)
			leaf.material_override = leaf_mat if j % 2 == 0 else base_mat
			add_child(leaf)
			thorn_meshes.append(leaf)

		# Thorn spikes protruding from each cluster
		for j: int in range(rng.randi_range(3, 5)):
			var spike := MeshInstance3D.new()
			var sp_mesh := BoxMesh.new()
			sp_mesh.size = Vector3(0.06, rng.randf_range(0.3, 0.6), 0.06)
			spike.mesh = sp_mesh
			spike.position = Vector3(
				pos_x + rng.randf_range(-size_x / 2.0, size_x / 2.0),
				pos_y + rng.randf_range(-0.2, size_y / 2.0),
				pos_z + rng.randf_range(-size_z / 2.0, size_z / 2.0)
			)
			spike.rotation_degrees = Vector3(
				rng.randf_range(-40, 40),
				rng.randf_range(0, 360),
				rng.randf_range(-40, 40)
			)
			spike.material_override = spike_mat
			add_child(spike)
			thorn_meshes.append(spike)

	# Scattered berries (small dark orbs)
	for i: int in range(8):
		var berry := MeshInstance3D.new()
		var b_mesh := BoxMesh.new()
		b_mesh.size = Vector3(0.08, 0.08, 0.08)
		berry.mesh = b_mesh
		berry.position = Vector3(
			rng.randf_range(-5.0, 5.0),
			rng.randf_range(0.8, 2.5),
			rng.randf_range(-1.0, 1.0)
		)
		berry.material_override = berry_mat
		add_child(berry)
		thorn_meshes.append(berry)

	# Tangled vine/branch details weaving between clusters
	for i: int in range(4):
		var vine := MeshInstance3D.new()
		var v_mesh := BoxMesh.new()
		v_mesh.size = Vector3(rng.randf_range(2.0, 4.0), 0.08, 0.08)
		vine.mesh = v_mesh
		vine.position = Vector3(
			rng.randf_range(-4.0, 4.0),
			rng.randf_range(0.5, 2.0),
			rng.randf_range(-0.5, 0.5)
		)
		vine.rotation_degrees = Vector3(
			rng.randf_range(-15, 15),
			rng.randf_range(-20, 20),
			rng.randf_range(-10, 10)
		)
		vine.material_override = thorn_mat
		add_child(vine)
		thorn_meshes.append(vine)


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
