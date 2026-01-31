extends Node
class_name PlacementSystem
## Handles structure placement with preview, validation, and confirmation.

signal placement_started(structure_type: String)
signal placement_confirmed(structure_type: String, position: Vector3)
signal placement_cancelled()

# Placement settings
@export var grid_size: float = 1.0  # 1 meter grid
@export var placement_distance: float = 3.0  # How far in front of player
@export var valid_color: Color = Color(0.2, 1.0, 0.2, 0.5)  # Green
@export var invalid_color: Color = Color(1.0, 0.2, 0.2, 0.5)  # Red

# State
var is_placing: bool = false
var current_structure_type: String = ""
var current_item_type: String = ""
var is_valid_placement: bool = false

# Preview instance
var preview_instance: Node3D = null
var preview_material: StandardMaterial3D = null

# References
var player: CharacterBody3D
var camera: Camera3D
var inventory: Inventory
var campsite_manager: Node  # Will be set by player


func _ready() -> void:
	# Get references from parent (player)
	call_deferred("_setup_references")


func _setup_references() -> void:
	var parent: Node = get_parent()
	if parent is CharacterBody3D:
		player = parent
		camera = parent.get_node_or_null("Camera3D")
		if parent.has_method("get_inventory"):
			inventory = parent.get_inventory()
		print("[PlacementSystem] Setup complete")


func _process(delta: float) -> void:
	if is_placing and preview_instance:
		_update_preview_position()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	if is_placing:
		# R to confirm placement
		if event.physical_keycode == KEY_R:
			if is_valid_placement:
				_confirm_placement()
			else:
				print("[PlacementSystem] Cannot place here - invalid location")
		# Q to cancel
		elif event.physical_keycode == KEY_Q:
			cancel_placement()


## Start placement mode for a structure.
func start_placement(item_type: String) -> bool:
	if is_placing:
		cancel_placement()

	# Get structure type for this item
	var structure_type: String = StructureData.get_structure_for_item(item_type)
	if structure_type.is_empty():
		print("[PlacementSystem] No structure for item: %s" % item_type)
		return false

	# Check if player has the item
	if not inventory or not inventory.has_item(item_type):
		print("[PlacementSystem] Missing required item: %s" % item_type)
		return false

	current_structure_type = structure_type
	current_item_type = item_type

	# Create preview
	if not _create_preview():
		print("[PlacementSystem] Failed to create preview")
		return false

	is_placing = true
	placement_started.emit(structure_type)
	print("[PlacementSystem] Started placement mode for %s" % structure_type)
	print("[PlacementSystem] Press R to place, Q to cancel")
	return true


## Cancel placement mode.
func cancel_placement() -> void:
	if not is_placing:
		return

	_destroy_preview()
	is_placing = false
	current_structure_type = ""
	current_item_type = ""

	placement_cancelled.emit()
	print("[PlacementSystem] Placement cancelled")


## Create preview mesh for the structure.
func _create_preview() -> bool:
	var scene_path: String = StructureData.get_scene_path(current_structure_type)

	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		# Create a fallback preview if scene doesn't exist yet
		preview_instance = _create_fallback_preview()
	else:
		var scene: PackedScene = load(scene_path)
		if not scene:
			preview_instance = _create_fallback_preview()
		else:
			preview_instance = scene.instantiate()

	if not preview_instance:
		return false

	# Remove scripts and collision from preview
	_disable_preview_functionality(preview_instance)

	# Create transparent material for preview
	preview_material = StandardMaterial3D.new()
	preview_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	preview_material.albedo_color = valid_color

	# Apply material to all meshes
	_apply_preview_material(preview_instance)

	# Add to scene
	if player:
		player.get_parent().add_child(preview_instance)

	return true


## Create fallback preview mesh if scene doesn't exist.
func _create_fallback_preview() -> Node3D:
	var preview: Node3D = Node3D.new()
	preview.name = "PlacementPreview"

	# Simple box mesh as fallback
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = Vector3(1.0, 0.5, 1.0)
	mesh_instance.mesh = box_mesh
	mesh_instance.position.y = 0.25
	preview.add_child(mesh_instance)

	return preview


## Disable scripts and collision on preview.
func _disable_preview_functionality(node: Node) -> void:
	# Remove script
	if node.get_script():
		node.set_script(null)

	# Disable collision
	if node is CollisionShape3D:
		node.disabled = true
	if node is CollisionObject3D:
		node.set_collision_layer_value(1, false)
		node.set_collision_mask_value(1, false)

	# Disable physics
	if node is StaticBody3D or node is RigidBody3D:
		if node.has_method("set_physics_process"):
			node.set_physics_process(false)

	# Disable lights
	if node is Light3D:
		node.visible = false

	# Disable areas
	if node is Area3D:
		node.monitoring = false
		node.monitorable = false

	# Process children
	for child: Node in node.get_children():
		_disable_preview_functionality(child)


## Apply transparent material to all meshes in preview.
func _apply_preview_material(node: Node) -> void:
	if node is MeshInstance3D:
		node.material_override = preview_material

	for child: Node in node.get_children():
		_apply_preview_material(child)


## Update preview position based on player aim.
func _update_preview_position() -> void:
	if not player or not camera or not preview_instance:
		return

	# Get position in front of player
	var forward: Vector3 = -camera.global_transform.basis.z
	forward.y = 0  # Keep horizontal
	forward = forward.normalized()

	var target_pos: Vector3 = player.global_position + forward * placement_distance

	# Snap to grid
	target_pos.x = round(target_pos.x / grid_size) * grid_size
	target_pos.z = round(target_pos.z / grid_size) * grid_size
	target_pos.y = 0  # Place on ground

	preview_instance.global_position = target_pos

	# Face the player (for shelters)
	var look_dir: Vector3 = player.global_position - target_pos
	look_dir.y = 0
	if look_dir.length_squared() > 0.001:
		preview_instance.look_at(target_pos + look_dir, Vector3.UP)

	# Validate placement
	is_valid_placement = _validate_placement(target_pos)

	# Update color
	if preview_material:
		preview_material.albedo_color = valid_color if is_valid_placement else invalid_color


## Validate if the current position is valid for placement.
func _validate_placement(pos: Vector3) -> bool:
	if not player:
		return false

	# Check distance from player (not too close, not too far)
	var distance: float = player.global_position.distance_to(pos)
	if distance < 1.5 or distance > placement_distance + 1.0:
		return false

	# Check for collisions with existing objects
	var space_state: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	if not space_state:
		return true  # Allow if can't check

	# Create shape query - check above ground level to avoid terrain collision
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(0.8, 0.5, 0.8)  # Slightly smaller than 1m grid
	query.shape = box_shape
	# Position box well above ground (at 1m height) to avoid floor collision
	query.transform = Transform3D(Basis.IDENTITY, pos + Vector3(0, 1.0, 0))
	query.collision_mask = 1  # Check layer 1

	# Exclude player from check
	if player:
		query.exclude = [player.get_rid()]

	var results: Array[Dictionary] = space_state.intersect_shape(query)

	# Check each collision - ignore ground/terrain
	for result: Dictionary in results:
		var collider: Object = result.get("collider")
		if not collider is Node:
			continue
		var collider_node: Node = collider as Node
		# Skip terrain and ground
		if collider_node.is_in_group("terrain"):
			continue
		# Skip if it's a floor/ground (named Floor or Ground, or at y=0)
		if collider_node.name == "Floor" or collider_node.name == "Ground":
			continue
		# Skip if collider is below placement height (likely ground)
		if collider_node is Node3D:
			var collider_3d: Node3D = collider_node as Node3D
			if collider_3d.global_position.y < 0.1:
				continue
		# This is an actual obstacle
		return false

	return true


## Confirm and place the structure.
func _confirm_placement() -> void:
	if not is_valid_placement or not preview_instance:
		return

	var place_pos: Vector3 = preview_instance.global_position
	var place_rotation: Vector3 = preview_instance.rotation

	# Get the actual scene
	var scene_path: String = StructureData.get_scene_path(current_structure_type)
	var structure: Node3D = null

	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		# Create structure programmatically if no scene
		structure = _create_structure_programmatically()
	else:
		var scene: PackedScene = load(scene_path)
		if scene:
			structure = scene.instantiate()

	if not structure:
		print("[PlacementSystem] Failed to create structure")
		return

	# Position the structure
	structure.global_position = place_pos
	structure.rotation = place_rotation

	# Add to scene (to Structures container if exists, otherwise main)
	var structures_container: Node = player.get_parent().get_node_or_null("Structures")
	if structures_container:
		structures_container.add_child(structure)
	else:
		player.get_parent().add_child(structure)

	# Call on_placed if structure has it
	if structure.has_method("on_placed"):
		structure.on_placed()

	# Consume item from inventory
	if inventory:
		inventory.remove_item(current_item_type, 1)

	# Notify campsite manager
	if campsite_manager and campsite_manager.has_method("register_structure"):
		campsite_manager.register_structure(structure, current_structure_type)

	# Emit signal
	placement_confirmed.emit(current_structure_type, place_pos)
	print("[PlacementSystem] Placed %s at %s" % [current_structure_type, place_pos])

	# Clean up
	_destroy_preview()
	is_placing = false
	current_structure_type = ""
	current_item_type = ""


## Create structure programmatically if scene file doesn't exist.
func _create_structure_programmatically() -> Node3D:
	match current_structure_type:
		"fire_pit":
			return _create_fire_pit()
		"basic_shelter":
			return _create_basic_shelter()
		"storage_container":
			return _create_storage_container()
		"crafting_bench":
			return _create_crafting_bench()
	return null


func _create_fire_pit() -> StaticBody3D:
	var fire_pit: StaticBody3D = StaticBody3D.new()
	fire_pit.name = "FirePit"
	fire_pit.set_script(load("res://scripts/campsite/structure_fire_pit.gd"))

	# Collision
	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(1.2, 0.4, 1.2)
	collision.shape = box_shape
	collision.position.y = 0.2
	fire_pit.add_child(collision)

	# Rock ring (blocky)
	var rocks: MeshInstance3D = MeshInstance3D.new()
	var rocks_box: BoxMesh = BoxMesh.new()
	rocks_box.size = Vector3(1.2, 0.3, 1.2)
	rocks.mesh = rocks_box
	rocks.position.y = 0.15
	var rock_mat: StandardMaterial3D = StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.4, 0.4, 0.4)
	rocks.material_override = rock_mat
	fire_pit.add_child(rocks)

	# Fire mesh (blocky)
	var fire_mesh: MeshInstance3D = MeshInstance3D.new()
	fire_mesh.name = "FireMesh"
	var fire_box: BoxMesh = BoxMesh.new()
	fire_box.size = Vector3(0.5, 0.7, 0.5)
	fire_mesh.mesh = fire_box
	fire_mesh.position.y = 0.5
	var fire_mat: StandardMaterial3D = StandardMaterial3D.new()
	fire_mat.albedo_color = Color(1.0, 0.5, 0.1)
	fire_mat.emission_enabled = true
	fire_mat.emission = Color(1.0, 0.4, 0.0)
	fire_mat.emission_energy_multiplier = 2.0
	fire_mesh.material_override = fire_mat
	fire_pit.add_child(fire_mesh)

	# Light
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "FireLight"
	light.light_color = Color(1.0, 0.6, 0.2)
	light.light_energy = 3.0
	light.omni_range = 8.0
	light.position.y = 0.5
	fire_pit.add_child(light)

	return fire_pit


func _create_basic_shelter() -> StaticBody3D:
	var shelter: StaticBody3D = StaticBody3D.new()
	shelter.name = "BasicShelter"
	shelter.set_script(load("res://scripts/campsite/structure_shelter.gd"))

	# Collision
	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(2.0, 1.5, 2.0)
	collision.shape = box_shape
	collision.position.y = 0.75
	shelter.add_child(collision)

	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.55, 0.35, 0.2)

	# Lean-to canvas/cover (angled from high back to low front)
	var cover: MeshInstance3D = MeshInstance3D.new()
	var cover_mesh: BoxMesh = BoxMesh.new()
	cover_mesh.size = Vector3(2.4, 0.05, 2.2)
	cover.mesh = cover_mesh
	cover.position = Vector3(0, 0.9, 0)
	cover.rotation.x = 0.5  # Angle: high at back (z-), low at front (z+)
	var canvas_mat: StandardMaterial3D = StandardMaterial3D.new()
	canvas_mat.albedo_color = Color(0.6, 0.55, 0.4)
	cover.material_override = canvas_mat
	shelter.add_child(cover)

	# Back frame (at top, supporting the high end)
	var frame_back: MeshInstance3D = MeshInstance3D.new()
	var frame_mesh: BoxMesh = BoxMesh.new()
	frame_mesh.size = Vector3(2.5, 0.1, 0.1)
	frame_back.mesh = frame_mesh
	frame_back.position = Vector3(0, 1.5, -0.8)
	frame_back.material_override = wood_mat
	shelter.add_child(frame_back)

	# Front frame (at ground level, low end of lean-to)
	var frame_front: MeshInstance3D = MeshInstance3D.new()
	frame_front.mesh = frame_mesh
	frame_front.position = Vector3(0, 0.15, 1.0)
	frame_front.material_override = wood_mat
	shelter.add_child(frame_front)

	# Back support poles (vertical, supporting the high end) - blocky
	var pole_mesh: BoxMesh = BoxMesh.new()
	pole_mesh.size = Vector3(0.1, 1.5, 0.1)

	var pole_left: MeshInstance3D = MeshInstance3D.new()
	pole_left.mesh = pole_mesh
	pole_left.position = Vector3(-1.1, 0.75, -0.8)
	pole_left.material_override = wood_mat
	shelter.add_child(pole_left)

	var pole_right: MeshInstance3D = MeshInstance3D.new()
	pole_right.mesh = pole_mesh
	pole_right.position = Vector3(1.1, 0.75, -0.8)
	pole_right.material_override = wood_mat
	shelter.add_child(pole_right)

	# Protection area (box shape)
	var area: Area3D = Area3D.new()
	area.name = "ProtectionArea"
	var area_collision: CollisionShape3D = CollisionShape3D.new()
	var box_area: BoxShape3D = BoxShape3D.new()
	box_area.size = Vector3(4.0, 3.0, 4.0)
	area_collision.shape = box_area
	area_collision.position.y = 1.0
	area.add_child(area_collision)
	shelter.add_child(area)

	return shelter


func _create_storage_container() -> StaticBody3D:
	var storage: StaticBody3D = StaticBody3D.new()
	storage.name = "StorageContainer"
	storage.set_script(load("res://scripts/campsite/structure_storage.gd"))

	# Collision
	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(1.0, 0.6, 0.6)
	collision.shape = box_shape
	collision.position.y = 0.3
	storage.add_child(collision)

	# Box mesh
	var box: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = Vector3(1.0, 0.6, 0.6)
	box.mesh = box_mesh
	box.position.y = 0.3
	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.6, 0.4, 0.25)
	box.material_override = wood_mat
	storage.add_child(box)

	# Lid detail
	var lid: MeshInstance3D = MeshInstance3D.new()
	var lid_mesh: BoxMesh = BoxMesh.new()
	lid_mesh.size = Vector3(1.02, 0.08, 0.62)
	lid.mesh = lid_mesh
	lid.position.y = 0.64
	var lid_mat: StandardMaterial3D = StandardMaterial3D.new()
	lid_mat.albedo_color = Color(0.5, 0.35, 0.2)
	lid.material_override = lid_mat
	storage.add_child(lid)

	return storage


func _create_crafting_bench() -> StaticBody3D:
	var bench: StaticBody3D = StaticBody3D.new()
	bench.name = "CraftingBench"
	bench.set_script(load("res://scripts/campsite/structure_crafting_bench.gd"))

	# Collision
	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(1.2, 0.8, 0.8)
	collision.shape = box_shape
	collision.position.y = 0.4
	bench.add_child(collision)

	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.5, 0.35, 0.2)

	var leg_mat: StandardMaterial3D = StandardMaterial3D.new()
	leg_mat.albedo_color = Color(0.4, 0.28, 0.15)

	# Table top
	var top: MeshInstance3D = MeshInstance3D.new()
	var top_mesh: BoxMesh = BoxMesh.new()
	top_mesh.size = Vector3(1.2, 0.1, 0.8)
	top.mesh = top_mesh
	top.position.y = 0.75
	top.material_override = wood_mat
	bench.add_child(top)

	# Legs
	var leg_mesh: BoxMesh = BoxMesh.new()
	leg_mesh.size = Vector3(0.1, 0.65, 0.1)

	var leg1: MeshInstance3D = MeshInstance3D.new()
	leg1.mesh = leg_mesh
	leg1.position = Vector3(-0.5, 0.325, -0.3)
	leg1.material_override = leg_mat
	bench.add_child(leg1)

	var leg2: MeshInstance3D = MeshInstance3D.new()
	leg2.mesh = leg_mesh
	leg2.position = Vector3(0.5, 0.325, -0.3)
	leg2.material_override = leg_mat
	bench.add_child(leg2)

	var leg3: MeshInstance3D = MeshInstance3D.new()
	leg3.mesh = leg_mesh
	leg3.position = Vector3(-0.5, 0.325, 0.3)
	leg3.material_override = leg_mat
	bench.add_child(leg3)

	var leg4: MeshInstance3D = MeshInstance3D.new()
	leg4.mesh = leg_mesh
	leg4.position = Vector3(0.5, 0.325, 0.3)
	leg4.material_override = leg_mat
	bench.add_child(leg4)

	return bench


## Destroy preview instance.
func _destroy_preview() -> void:
	if preview_instance:
		preview_instance.queue_free()
		preview_instance = null
	preview_material = null


## Set reference to campsite manager.
func set_campsite_manager(manager: Node) -> void:
	campsite_manager = manager
