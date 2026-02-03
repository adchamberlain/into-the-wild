extends Node
class_name PlacementSystem
## Handles structure placement with preview, validation, and confirmation.

signal placement_started(structure_type: String)
signal placement_confirmed(structure_type: String, position: Vector3)
signal placement_cancelled()
signal structure_move_started(structure: Node3D)
signal structure_move_confirmed(structure: Node3D, old_pos: Vector3, new_pos: Vector3)
signal structure_move_cancelled(structure: Node3D)

# Placement settings
@export var grid_size: float = 1.0  # 1 meter grid
@export var placement_distance: float = 3.0  # How far in front of player
@export var valid_color: Color = Color(0.2, 1.0, 0.2, 0.5)  # Green
@export var invalid_color: Color = Color(1.0, 0.2, 0.2, 0.5)  # Red
@export var min_structure_spacing: float = 1.0  # Minimum gap between structures

# State
var is_placing: bool = false
var current_structure_type: String = ""
var current_item_type: String = ""
var is_valid_placement: bool = false

# Move mode state
var is_moving: bool = false
var moving_structure: Node3D = null
var moving_structure_original_pos: Vector3 = Vector3.ZERO
var moving_structure_original_rot: Vector3 = Vector3.ZERO
var moving_structure_type: String = ""
var original_materials: Dictionary = {}  # Stores original materials for transparency restoration

# Cooldown to prevent R2 trigger from immediately confirming placement
const PLACEMENT_COOLDOWN: float = 0.4  # Seconds to wait before allowing confirm
var placement_cooldown_timer: float = 0.0

# Performance: throttle validation checks
const VALIDATION_INTERVAL: float = 0.1  # Check 10x/sec instead of every frame
var validation_timer: float = 0.0
var last_preview_pos: Vector3 = Vector3.ZERO

# Calculated rope ladder height (set during placement)
var calculated_ladder_height: float = 4.0

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
	# Update placement cooldown timer
	if placement_cooldown_timer > 0:
		placement_cooldown_timer -= delta

	if (is_placing or is_moving) and preview_instance:
		_update_preview_position(delta)


func _input(event: InputEvent) -> void:
	# Handle move mode input
	if is_moving:
		# Handle keyboard input for move mode
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode == KEY_R:
				if is_valid_placement:
					_confirm_move()
				else:
					print("[PlacementSystem] Cannot move here - invalid location")
				return
			elif event.physical_keycode == KEY_Q:
				cancel_move()
				return

		# Handle action-based input for move mode (controller support)
		if event.is_action_pressed("use_equipped"):
			if placement_cooldown_timer > 0:
				return
			if is_valid_placement:
				_confirm_move()
			else:
				print("[PlacementSystem] Cannot move here - invalid location")
			return
		elif event.is_action_pressed("unequip"):
			cancel_move()
			return
		return

	if not is_placing:
		return

	# Handle keyboard input
	if event is InputEventKey and event.pressed and not event.echo:
		# R to confirm placement
		if event.physical_keycode == KEY_R:
			if is_valid_placement:
				_confirm_placement()
			else:
				print("[PlacementSystem] Cannot place here - invalid location")
		# Q to cancel
		elif event.physical_keycode == KEY_Q:
			cancel_placement()

	# Handle action-based input (controller support)
	if event.is_action_pressed("use_equipped"):
		# Ignore R2 presses during cooldown (prevents trigger from immediately confirming)
		if placement_cooldown_timer > 0:
			return
		if is_valid_placement:
			_confirm_placement()
		else:
			print("[PlacementSystem] Cannot place here - invalid location")
	elif event.is_action_pressed("unequip"):
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
	placement_cooldown_timer = PLACEMENT_COOLDOWN  # Prevent immediate confirm from R2 trigger
	placement_started.emit(structure_type)
	print("[PlacementSystem] Started placement mode for %s" % structure_type)
	print("[PlacementSystem] Press R to place, Q to cancel")
	return true


## Cancel placement mode.
func cancel_placement() -> void:
	if not is_placing:
		return

	# Play cancel sound
	SFXManager.play_sfx("place_cancel")

	_destroy_preview()
	is_placing = false
	placement_cooldown_timer = 0.0
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


## Get ground height at a position using raycast.
func _get_ground_height(x: float, z: float) -> float:
	if not player:
		return 0.0

	var space_state: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	if not space_state:
		return 0.0

	# Raycast from high above down to find ground
	var ray_origin: Vector3 = Vector3(x, 50.0, z)
	var ray_end: Vector3 = Vector3(x, -10.0, z)

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	query.from = ray_origin
	query.to = ray_end
	query.collision_mask = 1  # Terrain layer

	var result: Dictionary = space_state.intersect_ray(query)
	if result:
		return result.position.y
	return 0.0


## Check if there's a cliff face in front of the placement position.
func _has_cliff_face(pos: Vector3) -> bool:
	if not player or not preview_instance:
		return false

	var space_state: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	if not space_state:
		return false

	# Get forward direction (toward where the ladder would face)
	var forward_dir: Vector3 = -preview_instance.global_transform.basis.z
	forward_dir.y = 0
	forward_dir = forward_dir.normalized()

	# Raycast forward to find cliff face
	var ray_origin: Vector3 = pos - forward_dir * 0.5 + Vector3(0, 1.0, 0)
	var ray_end: Vector3 = pos + forward_dir * 3.0 + Vector3(0, 1.0, 0)

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	query.from = ray_origin
	query.to = ray_end
	query.collision_mask = 1  # Terrain layer

	var result: Dictionary = space_state.intersect_ray(query)
	return not result.is_empty()


## Snap a position to the nearest cliff face in the given direction.
## Returns the position right against the cliff, or original position if no cliff found.
func _snap_to_cliff_face(pos: Vector3, forward_dir: Vector3) -> Vector3:
	if not player:
		return pos

	var space_state: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	if not space_state:
		return pos

	# Raycast forward from the position to find the cliff face
	# Start slightly behind the placement position and cast forward
	var ray_origin: Vector3 = pos - forward_dir * 1.0 + Vector3(0, 1.0, 0)  # Slightly back and up
	var ray_end: Vector3 = pos + forward_dir * 5.0 + Vector3(0, 1.0, 0)  # Forward up to 5 units

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	query.from = ray_origin
	query.to = ray_end
	query.collision_mask = 1  # Terrain layer

	var result: Dictionary = space_state.intersect_ray(query)
	if result:
		# Found cliff face - position ladder right against it (with small offset)
		var cliff_pos: Vector3 = result.position
		var snapped_pos: Vector3 = cliff_pos - forward_dir * 0.15  # Small offset from cliff
		snapped_pos.y = pos.y  # Keep original ground height
		return snapped_pos

	# No cliff found, return original position
	return pos


## Calculate the cliff height behind a position (for rope ladder sizing).
## Returns the height difference between the placement position and the terrain above/behind it.
func _calculate_cliff_height(pos: Vector3, forward_dir: Vector3) -> float:
	if not player:
		return 4.0  # Default fallback

	var space_state: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	if not space_state:
		return 4.0

	# The ladder faces away from player, so "behind" the ladder is toward the cliff
	# forward_dir points away from player (toward cliff)
	var check_pos: Vector3 = pos + forward_dir * 0.5  # Slightly into the cliff

	# Find ground height at ladder base
	var base_height: float = pos.y

	# Raycast up from behind the ladder to find cliff top
	# Start from the placement position and go up
	var ray_origin: Vector3 = Vector3(check_pos.x, base_height + 0.5, check_pos.z)
	var ray_end: Vector3 = Vector3(check_pos.x, base_height + 20.0, check_pos.z)

	# First, check if there's terrain directly behind/above by raycasting horizontally into the cliff at various heights
	var cliff_top_height: float = base_height

	# Sample heights going up to find where the cliff ends
	for test_height: float in [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0, 12.0, 15.0]:
		var test_y: float = base_height + test_height
		var horizontal_origin: Vector3 = Vector3(pos.x - forward_dir.x * 0.5, test_y, pos.z - forward_dir.z * 0.5)
		var horizontal_end: Vector3 = Vector3(pos.x + forward_dir.x * 2.0, test_y, pos.z + forward_dir.z * 2.0)

		var h_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
		h_query.from = horizontal_origin
		h_query.to = horizontal_end
		h_query.collision_mask = 1

		var h_result: Dictionary = space_state.intersect_ray(h_query)
		if h_result:
			# There's terrain at this height, cliff continues
			cliff_top_height = test_y
		else:
			# No terrain at this height - we've found the top
			break

	# Calculate ladder height (from base to just above cliff top)
	var ladder_height: float = cliff_top_height - base_height + 1.0  # +1 to reach over the top

	# Clamp to reasonable values
	ladder_height = clampf(ladder_height, 2.0, 15.0)

	return ladder_height


## Update preview position based on player aim.
func _update_preview_position(delta: float) -> void:
	if not player or not camera or not preview_instance:
		return

	# Get position in front of player
	var forward: Vector3 = -camera.global_transform.basis.z
	forward.y = 0  # Keep horizontal
	forward = forward.normalized()

	# Adjust placement distance for large structures (cabin, etc.)
	var footprint: float = StructureData.get_footprint_radius(current_structure_type)
	var effective_distance: float = placement_distance
	if footprint > 2.0:
		# For large structures, place them farther away so player isn't inside
		effective_distance = max(placement_distance, footprint + 1.5)

	var target_pos: Vector3 = player.global_position + forward * effective_distance

	# Snap to grid
	target_pos.x = round(target_pos.x / grid_size) * grid_size
	target_pos.z = round(target_pos.z / grid_size) * grid_size

	# Get terrain height at this position using raycast
	target_pos.y = _get_ground_height(target_pos.x, target_pos.z)

	preview_instance.global_position = target_pos

	# Face the structure so openings (at +Z) face the player
	# First look at player (makes -Z face player), then rotate 180° so +Z faces player
	var look_target: Vector3 = Vector3(player.global_position.x, target_pos.y, player.global_position.z)
	if target_pos.distance_squared_to(look_target) > 0.001:
		preview_instance.look_at(look_target, Vector3.UP)
		preview_instance.rotate_y(PI)  # Flip so +Z (door/opening) faces player

	# Throttle validation - only run expensive physics query periodically or when position changes
	validation_timer += delta
	var pos_changed: bool = target_pos.distance_squared_to(last_preview_pos) > 0.01
	if validation_timer >= VALIDATION_INTERVAL or pos_changed:
		validation_timer = 0.0
		last_preview_pos = target_pos
		is_valid_placement = _validate_placement(target_pos)

		# Update color
		if preview_material:
			preview_material.albedo_color = valid_color if is_valid_placement else invalid_color


## Validate if the current position is valid for placement.
func _validate_placement(pos: Vector3) -> bool:
	if not player:
		return false

	# Get structure's footprint for distance calculations
	var footprint: float = StructureData.get_footprint_radius(current_structure_type)

	# Calculate max allowed distance (farther for large structures)
	var max_distance: float = placement_distance + 1.0
	if footprint > 2.0:
		max_distance = footprint + 3.0  # Allow placement up to footprint + 3m away

	# Check distance from player (not too close, not too far)
	var distance: float = player.global_position.distance_to(pos)
	if distance < 1.5 or distance > max_distance:
		return false

	# Prevent placing structures where the player would be trapped inside walls
	# Use the structure's footprint to check if player is too close to center
	var player_dist_2d: float = Vector2(player.global_position.x - pos.x, player.global_position.z - pos.z).length()
	# For large structures (footprint > 2), player must be outside footprint or at the doorway
	if footprint > 2.0 and player_dist_2d < footprint - 0.5:
		return false

	# Rope ladders require a cliff face
	if current_structure_type == "rope_ladder":
		if not _has_cliff_face(pos):
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

	# Check spacing from other structures
	var preview_footprint: float = _get_current_preview_footprint()
	if not _check_structure_spacing(pos, preview_footprint):
		return false

	return true


## Get footprint radius for a structure node.
func _get_structure_footprint(structure: Node) -> float:
	var structure_type: String = ""
	# Try to get structure_type from the structure's exported property
	if "structure_type" in structure:
		structure_type = structure.structure_type
	# Or from metadata
	elif structure.has_meta("structure_type"):
		structure_type = structure.get_meta("structure_type")

	if not structure_type.is_empty():
		var data: Dictionary = StructureData.get_structure(structure_type)
		return data.get("footprint_radius", 1.0)
	# Default fallback
	return 1.0


## Get footprint radius for the structure currently being placed/moved.
func _get_current_preview_footprint() -> float:
	var data: Dictionary = StructureData.get_structure(current_structure_type)
	return data.get("footprint_radius", 1.0)


## Check if position has adequate spacing from existing structures.
func _check_structure_spacing(pos: Vector3, preview_footprint: float) -> bool:
	if not campsite_manager:
		return true  # Allow if no manager to check

	# Get list of placed structures
	var placed_structures: Array = []
	if campsite_manager.has_method("get_placed_structures"):
		placed_structures = campsite_manager.get_placed_structures()
	elif "placed_structures" in campsite_manager:
		placed_structures = campsite_manager.placed_structures

	for structure: Node in placed_structures:
		if not structure is Node3D:
			continue
		var structure_3d: Node3D = structure as Node3D

		# Skip structure being moved (will be added in move mode)
		if is_moving and structure == moving_structure:
			continue

		var structure_footprint: float = _get_structure_footprint(structure)
		var structure_pos: Vector3 = structure_3d.global_position

		# Calculate edge-to-edge distance (center distance minus both radii)
		var center_distance: float = pos.distance_to(Vector3(structure_pos.x, pos.y, structure_pos.z))
		var edge_distance: float = center_distance - preview_footprint - structure_footprint

		if edge_distance < min_structure_spacing:
			return false

	return true


## Confirm and place the structure.
func _confirm_placement() -> void:
	if not is_valid_placement or not preview_instance:
		return

	var place_pos: Vector3 = preview_instance.global_position
	var place_rotation: Vector3 = preview_instance.rotation

	# For rope ladders, calculate cliff height and snap to cliff face
	if current_structure_type == "rope_ladder":
		var forward_dir: Vector3 = -preview_instance.global_transform.basis.z
		forward_dir.y = 0
		forward_dir = forward_dir.normalized()

		# Snap position to cliff face
		place_pos = _snap_to_cliff_face(place_pos, forward_dir)

		# Calculate height based on snapped position
		calculated_ladder_height = _calculate_cliff_height(place_pos, forward_dir)
		print("[PlacementSystem] Ladder snapped to cliff, height: %.1f" % calculated_ladder_height)

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

	# Play placement confirm sound
	SFXManager.play_sfx("place_confirm")

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
		"drying_rack":
			return _create_drying_rack()
		"herb_garden":
			return _create_herb_garden()
		"canvas_tent":
			return _create_canvas_tent()
		"cabin":
			return _create_cabin()
		"rope_ladder":
			return _create_rope_ladder(calculated_ladder_height)
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


## Start move mode for an existing structure.
func start_move(structure: Node3D) -> bool:
	if is_placing:
		cancel_placement()
	if is_moving:
		cancel_move()

	if not structure:
		return false

	# Get structure type from exported property or metadata
	if "structure_type" in structure and not structure.structure_type.is_empty():
		moving_structure_type = structure.structure_type
	elif structure.has_meta("structure_type"):
		moving_structure_type = structure.get_meta("structure_type")
	else:
		print("[PlacementSystem] Structure has no structure_type")
		return false

	moving_structure = structure
	moving_structure_original_pos = structure.global_position
	moving_structure_original_rot = structure.rotation
	current_structure_type = moving_structure_type

	# Make original structure semi-transparent
	_set_structure_transparency(moving_structure, 0.5)

	# Create preview at current position
	if not _create_preview():
		_set_structure_transparency(moving_structure, 1.0)
		return false

	# Position preview at structure's current location
	if preview_instance:
		preview_instance.global_position = moving_structure_original_pos
		preview_instance.rotation = moving_structure_original_rot

	is_moving = true
	placement_cooldown_timer = PLACEMENT_COOLDOWN
	structure_move_started.emit(structure)
	print("[PlacementSystem] Started move mode for %s" % moving_structure_type)
	print("[PlacementSystem] Press R to confirm, Q to cancel")
	return true


## Set transparency on a structure's meshes.
func _set_structure_transparency(structure: Node3D, alpha: float) -> void:
	if alpha < 1.0:
		# Store original materials and apply transparent versions
		_apply_transparency_recursive(structure, alpha, true)
	else:
		# Restore original materials
		_restore_materials_recursive(structure)
		original_materials.clear()


func _apply_transparency_recursive(node: Node, alpha: float, is_root: bool = false) -> void:
	if node is MeshInstance3D:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		var node_id: int = mesh_instance.get_instance_id()

		# Store original material
		if not original_materials.has(node_id):
			original_materials[node_id] = mesh_instance.material_override

		# Create transparent material
		var trans_mat: StandardMaterial3D = StandardMaterial3D.new()
		trans_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		trans_mat.albedo_color = Color(0.5, 0.5, 0.5, alpha)
		mesh_instance.material_override = trans_mat

	for child: Node in node.get_children():
		_apply_transparency_recursive(child, alpha, false)


func _restore_materials_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		var node_id: int = mesh_instance.get_instance_id()

		if original_materials.has(node_id):
			mesh_instance.material_override = original_materials[node_id]

	for child: Node in node.get_children():
		_restore_materials_recursive(child)


## Confirm move and relocate structure.
func _confirm_move() -> void:
	if not is_moving or not moving_structure or not preview_instance:
		return

	if not is_valid_placement:
		print("[PlacementSystem] Cannot move here - invalid location")
		return

	var old_pos: Vector3 = moving_structure_original_pos
	var new_pos: Vector3 = preview_instance.global_position
	var new_rot: Vector3 = preview_instance.rotation

	# Move structure to new position
	moving_structure.global_position = new_pos
	moving_structure.rotation = new_rot

	# Restore transparency
	_set_structure_transparency(moving_structure, 1.0)

	# Play placement confirm sound
	SFXManager.play_sfx("place_confirm")

	# Emit signal
	structure_move_confirmed.emit(moving_structure, old_pos, new_pos)
	print("[PlacementSystem] Moved %s from %s to %s" % [moving_structure_type, old_pos, new_pos])

	# Clean up
	_end_move_mode()


## Cancel move and keep structure at original position.
func cancel_move() -> void:
	if not is_moving:
		return

	# Play cancel sound
	SFXManager.play_sfx("place_cancel")

	# Restore transparency (structure stays at original position)
	if moving_structure:
		_set_structure_transparency(moving_structure, 1.0)
		structure_move_cancelled.emit(moving_structure)

	print("[PlacementSystem] Move cancelled")

	# Clean up
	_end_move_mode()


## Clean up move mode state.
func _end_move_mode() -> void:
	_destroy_preview()
	is_moving = false
	moving_structure = null
	moving_structure_original_pos = Vector3.ZERO
	moving_structure_original_rot = Vector3.ZERO
	moving_structure_type = ""
	current_structure_type = ""
	placement_cooldown_timer = 0.0


func _create_drying_rack() -> StaticBody3D:
	var rack: StaticBody3D = StaticBody3D.new()
	rack.name = "DryingRack"
	rack.set_script(load("res://scripts/campsite/structure_drying_rack.gd"))

	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.5, 0.35, 0.2)

	# Collision
	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(1.5, 1.2, 0.4)
	collision.shape = box_shape
	collision.position.y = 0.6
	rack.add_child(collision)

	# Vertical posts
	var post_mesh: BoxMesh = BoxMesh.new()
	post_mesh.size = Vector3(0.1, 1.2, 0.1)

	var post_left: MeshInstance3D = MeshInstance3D.new()
	post_left.mesh = post_mesh
	post_left.position = Vector3(-0.6, 0.6, 0)
	post_left.material_override = wood_mat
	rack.add_child(post_left)

	var post_right: MeshInstance3D = MeshInstance3D.new()
	post_right.mesh = post_mesh
	post_right.position = Vector3(0.6, 0.6, 0)
	post_right.material_override = wood_mat
	rack.add_child(post_right)

	# Horizontal bars for hanging
	var bar_mesh: BoxMesh = BoxMesh.new()
	bar_mesh.size = Vector3(1.2, 0.06, 0.06)

	for i: int in range(3):
		var bar: MeshInstance3D = MeshInstance3D.new()
		bar.mesh = bar_mesh
		bar.position = Vector3(0, 0.4 + i * 0.35, 0)
		bar.material_override = wood_mat
		rack.add_child(bar)

	# Hanging "food" strips (visual)
	var strip_mat: StandardMaterial3D = StandardMaterial3D.new()
	strip_mat.albedo_color = Color(0.6, 0.4, 0.3)  # Dried food color

	var strip_mesh: BoxMesh = BoxMesh.new()
	strip_mesh.size = Vector3(0.08, 0.25, 0.02)

	for j: int in range(3):
		for i: int in range(4):
			var strip: MeshInstance3D = MeshInstance3D.new()
			strip.mesh = strip_mesh
			strip.position = Vector3(-0.4 + i * 0.25, 0.25 + j * 0.35, 0.04)
			strip.material_override = strip_mat
			rack.add_child(strip)

	return rack


func _create_herb_garden() -> StaticBody3D:
	var garden: StaticBody3D = StaticBody3D.new()
	garden.name = "HerbGarden"
	garden.set_script(load("res://scripts/campsite/structure_garden.gd"))

	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.5, 0.35, 0.2)

	var dirt_mat: StandardMaterial3D = StandardMaterial3D.new()
	dirt_mat.albedo_color = Color(0.4, 0.28, 0.18)

	var plant_mat: StandardMaterial3D = StandardMaterial3D.new()
	plant_mat.albedo_color = Color(0.25, 0.55, 0.2)

	# Collision
	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(2.0, 0.4, 1.5)
	collision.shape = box_shape
	collision.position.y = 0.2
	garden.add_child(collision)

	# Wooden border
	var border_mesh: BoxMesh = BoxMesh.new()
	border_mesh.size = Vector3(2.0, 0.3, 0.1)

	var border_front: MeshInstance3D = MeshInstance3D.new()
	border_front.mesh = border_mesh
	border_front.position = Vector3(0, 0.15, 0.7)
	border_front.material_override = wood_mat
	garden.add_child(border_front)

	var border_back: MeshInstance3D = MeshInstance3D.new()
	border_back.mesh = border_mesh
	border_back.position = Vector3(0, 0.15, -0.7)
	border_back.material_override = wood_mat
	garden.add_child(border_back)

	var side_mesh: BoxMesh = BoxMesh.new()
	side_mesh.size = Vector3(0.1, 0.3, 1.5)

	var border_left: MeshInstance3D = MeshInstance3D.new()
	border_left.mesh = side_mesh
	border_left.position = Vector3(-0.95, 0.15, 0)
	border_left.material_override = wood_mat
	garden.add_child(border_left)

	var border_right: MeshInstance3D = MeshInstance3D.new()
	border_right.mesh = side_mesh
	border_right.position = Vector3(0.95, 0.15, 0)
	border_right.material_override = wood_mat
	garden.add_child(border_right)

	# Dirt fill
	var dirt: MeshInstance3D = MeshInstance3D.new()
	var dirt_mesh: BoxMesh = BoxMesh.new()
	dirt_mesh.size = Vector3(1.8, 0.2, 1.3)
	dirt.mesh = dirt_mesh
	dirt.position.y = 0.1
	dirt.material_override = dirt_mat
	garden.add_child(dirt)

	# Plants (herb-looking green blocks)
	var plant_mesh: BoxMesh = BoxMesh.new()
	plant_mesh.size = Vector3(0.25, 0.3, 0.25)

	for row: int in range(2):
		for col: int in range(4):
			var plant: MeshInstance3D = MeshInstance3D.new()
			plant.mesh = plant_mesh
			plant.position = Vector3(-0.6 + col * 0.4, 0.35, -0.3 + row * 0.6)
			plant.material_override = plant_mat
			garden.add_child(plant)

	return garden


func _create_canvas_tent() -> StaticBody3D:
	var tent: StaticBody3D = StaticBody3D.new()
	tent.name = "CanvasTent"
	tent.set_script(load("res://scripts/campsite/structure_canvas_tent.gd"))

	var canvas_mat: StandardMaterial3D = StandardMaterial3D.new()
	canvas_mat.albedo_color = Color(0.75, 0.68, 0.55)  # Tan canvas

	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.5, 0.35, 0.2)

	# Interaction collision - tall enough for raycast to hit from standing position
	# Player can still walk through the open front doorway
	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(3.0, 1.8, 2.5)
	collision.shape = box_shape
	collision.position.y = 0.9
	tent.add_child(collision)

	# A-frame tent - two angled canvas panels
	var panel_mesh: BoxMesh = BoxMesh.new()
	panel_mesh.size = Vector3(3.0, 0.05, 2.0)

	var panel_left: MeshInstance3D = MeshInstance3D.new()
	panel_left.mesh = panel_mesh
	panel_left.position = Vector3(-0.7, 1.2, 0)
	panel_left.rotation_degrees.z = 45
	panel_left.material_override = canvas_mat
	tent.add_child(panel_left)

	var panel_right: MeshInstance3D = MeshInstance3D.new()
	panel_right.mesh = panel_mesh
	panel_right.position = Vector3(0.7, 1.2, 0)
	panel_right.rotation_degrees.z = -45
	panel_right.material_override = canvas_mat
	tent.add_child(panel_right)

	# Back wall triangle (simplified as a box)
	var back_mesh: BoxMesh = BoxMesh.new()
	back_mesh.size = Vector3(2.0, 1.8, 0.05)
	var back: MeshInstance3D = MeshInstance3D.new()
	back.mesh = back_mesh
	back.position = Vector3(0, 0.9, -0.95)
	back.material_override = canvas_mat
	tent.add_child(back)

	# Ridge pole (at peak)
	var ridge: MeshInstance3D = MeshInstance3D.new()
	var ridge_mesh: BoxMesh = BoxMesh.new()
	ridge_mesh.size = Vector3(0.08, 0.08, 2.1)
	ridge.mesh = ridge_mesh
	ridge.position = Vector3(0, 1.8, 0)
	ridge.material_override = wood_mat
	tent.add_child(ridge)

	# Protection area
	var area: Area3D = Area3D.new()
	area.name = "ProtectionArea"
	var area_collision: CollisionShape3D = CollisionShape3D.new()
	var box_area: BoxShape3D = BoxShape3D.new()
	box_area.size = Vector3(4.0, 3.0, 3.0)
	area_collision.shape = box_area
	area_collision.position.y = 1.0
	area.add_child(area_collision)
	tent.add_child(area)

	return tent


func _create_cabin() -> StaticBody3D:
	var cabin: StaticBody3D = StaticBody3D.new()
	cabin.name = "LogCabin"
	cabin.set_script(load("res://scripts/campsite/structure_cabin.gd"))

	var log_mat: StandardMaterial3D = StandardMaterial3D.new()
	log_mat.albedo_color = Color(0.45, 0.30, 0.18)  # Dark brown logs

	var roof_mat: StandardMaterial3D = StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.35, 0.22, 0.12)  # Darker roof

	var floor_mat: StandardMaterial3D = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.5, 0.38, 0.25)  # Lighter wood floor

	# Cabin dimensions
	var width: float = 6.0
	var height: float = 3.0
	var depth: float = 5.0
	var wall_thick: float = 0.3
	var door_width: float = 1.2
	var door_height: float = 2.2

	# Floor (visible inside)
	var floor_mesh: MeshInstance3D = MeshInstance3D.new()
	var floor_box: BoxMesh = BoxMesh.new()
	floor_box.size = Vector3(width - wall_thick * 2, 0.1, depth - wall_thick * 2)
	floor_mesh.mesh = floor_box
	floor_mesh.position.y = 0.05
	floor_mesh.material_override = floor_mat
	cabin.add_child(floor_mesh)

	# Back wall (solid)
	var back_wall: MeshInstance3D = MeshInstance3D.new()
	var back_mesh: BoxMesh = BoxMesh.new()
	back_mesh.size = Vector3(width, height, wall_thick)
	back_wall.mesh = back_mesh
	back_wall.position = Vector3(0, height / 2, -depth / 2 + wall_thick / 2)
	back_wall.material_override = log_mat
	cabin.add_child(back_wall)

	# Back wall collision
	var back_col: CollisionShape3D = CollisionShape3D.new()
	var back_shape: BoxShape3D = BoxShape3D.new()
	back_shape.size = Vector3(width, height, wall_thick)
	back_col.shape = back_shape
	back_col.position = back_wall.position
	cabin.add_child(back_col)

	# Side walls
	var side_mesh: BoxMesh = BoxMesh.new()
	side_mesh.size = Vector3(wall_thick, height, depth)

	var left_wall: MeshInstance3D = MeshInstance3D.new()
	left_wall.mesh = side_mesh
	left_wall.position = Vector3(-width / 2 + wall_thick / 2, height / 2, 0)
	left_wall.material_override = log_mat
	cabin.add_child(left_wall)

	var left_col: CollisionShape3D = CollisionShape3D.new()
	left_col.shape = BoxShape3D.new()
	(left_col.shape as BoxShape3D).size = Vector3(wall_thick, height, depth)
	left_col.position = left_wall.position
	cabin.add_child(left_col)

	var right_wall: MeshInstance3D = MeshInstance3D.new()
	right_wall.mesh = side_mesh
	right_wall.position = Vector3(width / 2 - wall_thick / 2, height / 2, 0)
	right_wall.material_override = log_mat
	cabin.add_child(right_wall)

	var right_col: CollisionShape3D = CollisionShape3D.new()
	right_col.shape = BoxShape3D.new()
	(right_col.shape as BoxShape3D).size = Vector3(wall_thick, height, depth)
	right_col.position = right_wall.position
	cabin.add_child(right_col)

	# Front wall with doorway
	var front_side_width: float = (width - door_width) / 2
	var front_mesh: BoxMesh = BoxMesh.new()
	front_mesh.size = Vector3(front_side_width, height, wall_thick)

	var front_left: MeshInstance3D = MeshInstance3D.new()
	front_left.mesh = front_mesh
	front_left.position = Vector3(-width / 2 + front_side_width / 2 + wall_thick / 2, height / 2, depth / 2 - wall_thick / 2)
	front_left.material_override = log_mat
	cabin.add_child(front_left)

	var fl_col: CollisionShape3D = CollisionShape3D.new()
	fl_col.shape = BoxShape3D.new()
	(fl_col.shape as BoxShape3D).size = Vector3(front_side_width, height, wall_thick)
	fl_col.position = front_left.position
	cabin.add_child(fl_col)

	var front_right: MeshInstance3D = MeshInstance3D.new()
	front_right.mesh = front_mesh
	front_right.position = Vector3(width / 2 - front_side_width / 2 - wall_thick / 2, height / 2, depth / 2 - wall_thick / 2)
	front_right.material_override = log_mat
	cabin.add_child(front_right)

	var fr_col: CollisionShape3D = CollisionShape3D.new()
	fr_col.shape = BoxShape3D.new()
	(fr_col.shape as BoxShape3D).size = Vector3(front_side_width, height, wall_thick)
	fr_col.position = front_right.position
	cabin.add_child(fr_col)

	# Above door
	var above_door: MeshInstance3D = MeshInstance3D.new()
	var above_mesh: BoxMesh = BoxMesh.new()
	above_mesh.size = Vector3(door_width, height - door_height, wall_thick)
	above_door.mesh = above_mesh
	above_door.position = Vector3(0, door_height + (height - door_height) / 2, depth / 2 - wall_thick / 2)
	above_door.material_override = log_mat
	cabin.add_child(above_door)

	var ad_col: CollisionShape3D = CollisionShape3D.new()
	ad_col.shape = BoxShape3D.new()
	(ad_col.shape as BoxShape3D).size = Vector3(door_width, height - door_height, wall_thick)
	ad_col.position = above_door.position
	cabin.add_child(ad_col)

	# Peaked roof (two angled panels)
	var roof_mesh: BoxMesh = BoxMesh.new()
	roof_mesh.size = Vector3(width / 2 + 0.5, 0.15, depth + 0.6)

	var roof_left: MeshInstance3D = MeshInstance3D.new()
	roof_left.mesh = roof_mesh
	roof_left.position = Vector3(-width / 4, height + 0.6, 0)
	roof_left.rotation_degrees.z = 25
	roof_left.material_override = roof_mat
	cabin.add_child(roof_left)

	var roof_right: MeshInstance3D = MeshInstance3D.new()
	roof_right.mesh = roof_mesh
	roof_right.position = Vector3(width / 4, height + 0.6, 0)
	roof_right.rotation_degrees.z = -25
	roof_right.material_override = roof_mat
	cabin.add_child(roof_right)

	# Interior: Bed (back right corner)
	var bed: StaticBody3D = _create_cabin_bed()
	bed.position = Vector3(width / 2 - 1.2, 0, -depth / 2 + 1.2)
	cabin.add_child(bed)

	# Interior: Kitchen (back left corner)
	var kitchen: StaticBody3D = _create_cabin_kitchen()
	kitchen.position = Vector3(-width / 2 + 1.2, 0, -depth / 2 + 1.0)
	cabin.add_child(kitchen)

	# Protection area (covers entire cabin interior)
	var area: Area3D = Area3D.new()
	area.name = "ProtectionArea"
	var area_collision: CollisionShape3D = CollisionShape3D.new()
	var box_area: BoxShape3D = BoxShape3D.new()
	box_area.size = Vector3(width, height + 2, depth)
	area_collision.shape = box_area
	area_collision.position.y = height / 2
	area.add_child(area_collision)
	area.body_entered.connect(cabin._on_protection_area_body_entered)
	area.body_exited.connect(cabin._on_protection_area_body_exited)
	cabin.add_child(area)

	return cabin


func _create_cabin_bed() -> StaticBody3D:
	var bed: StaticBody3D = StaticBody3D.new()
	bed.name = "CabinBed"
	bed.set_script(load("res://scripts/campsite/cabin_bed.gd"))

	var frame_mat: StandardMaterial3D = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.45, 0.32, 0.2)

	var blanket_mat: StandardMaterial3D = StandardMaterial3D.new()
	blanket_mat.albedo_color = Color(0.3, 0.45, 0.6)  # Blue blanket

	var pillow_mat: StandardMaterial3D = StandardMaterial3D.new()
	pillow_mat.albedo_color = Color(0.9, 0.88, 0.82)  # White pillow

	# Bed frame
	var frame: MeshInstance3D = MeshInstance3D.new()
	var frame_mesh: BoxMesh = BoxMesh.new()
	frame_mesh.size = Vector3(1.8, 0.3, 1.0)
	frame.mesh = frame_mesh
	frame.position.y = 0.15
	frame.material_override = frame_mat
	bed.add_child(frame)

	# Mattress/blanket
	var blanket: MeshInstance3D = MeshInstance3D.new()
	var blanket_mesh: BoxMesh = BoxMesh.new()
	blanket_mesh.size = Vector3(1.6, 0.15, 0.9)
	blanket.mesh = blanket_mesh
	blanket.position = Vector3(0, 0.375, 0)
	blanket.material_override = blanket_mat
	bed.add_child(blanket)

	# Pillow
	var pillow: MeshInstance3D = MeshInstance3D.new()
	var pillow_mesh: BoxMesh = BoxMesh.new()
	pillow_mesh.size = Vector3(0.5, 0.12, 0.35)
	pillow.mesh = pillow_mesh
	pillow.position = Vector3(-0.5, 0.5, 0)
	pillow.material_override = pillow_mat
	bed.add_child(pillow)

	# Collision for interaction
	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(1.8, 0.5, 1.0)
	collision.shape = box_shape
	collision.position.y = 0.25
	bed.add_child(collision)

	return bed


func _create_cabin_kitchen() -> StaticBody3D:
	var kitchen: StaticBody3D = StaticBody3D.new()
	kitchen.name = "CabinKitchen"
	kitchen.set_script(load("res://scripts/campsite/cabin_kitchen.gd"))

	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.5, 0.38, 0.25)

	var stone_mat: StandardMaterial3D = StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.5, 0.5, 0.52)

	var fire_mat: StandardMaterial3D = StandardMaterial3D.new()
	fire_mat.albedo_color = Color(1.0, 0.5, 0.1)
	fire_mat.emission_enabled = true
	fire_mat.emission = Color(1.0, 0.4, 0.0)
	fire_mat.emission_energy_multiplier = 1.5

	# Counter/cabinet base
	var counter: MeshInstance3D = MeshInstance3D.new()
	var counter_mesh: BoxMesh = BoxMesh.new()
	counter_mesh.size = Vector3(1.5, 0.8, 0.8)
	counter.mesh = counter_mesh
	counter.position.y = 0.4
	counter.material_override = wood_mat
	kitchen.add_child(counter)

	# Stone cooking surface
	var surface: MeshInstance3D = MeshInstance3D.new()
	var surface_mesh: BoxMesh = BoxMesh.new()
	surface_mesh.size = Vector3(1.5, 0.1, 0.8)
	surface.mesh = surface_mesh
	surface.position.y = 0.85
	surface.material_override = stone_mat
	kitchen.add_child(surface)

	# Small cooking fire (always lit)
	var fire: MeshInstance3D = MeshInstance3D.new()
	var fire_mesh: BoxMesh = BoxMesh.new()
	fire_mesh.size = Vector3(0.3, 0.25, 0.3)
	fire.mesh = fire_mesh
	fire.position = Vector3(0.4, 1.025, 0)
	fire.material_override = fire_mat
	kitchen.add_child(fire)

	# Light from fire
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.2)
	light.light_energy = 1.5
	light.omni_range = 4.0
	light.position = Vector3(0.4, 1.2, 0)
	kitchen.add_child(light)

	# Collision for interaction
	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(1.5, 0.9, 0.8)
	collision.shape = box_shape
	collision.position.y = 0.45
	kitchen.add_child(collision)

	return kitchen


func _create_rope_ladder(custom_height: float = -1.0) -> StaticBody3D:
	var ladder: StaticBody3D = StaticBody3D.new()
	ladder.name = "RopeLadder"
	ladder.set_script(load("res://scripts/campsite/structure_rope_ladder.gd"))

	var rope_mat: StandardMaterial3D = StandardMaterial3D.new()
	rope_mat.albedo_color = Color(0.55, 0.45, 0.3)  # Tan rope color

	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.5, 0.35, 0.2)  # Wood rungs

	# Use custom height if provided, otherwise default
	var ladder_height: float = custom_height if custom_height > 0 else 8.0
	var rung_spacing: float = 0.5
	var ladder_width: float = 0.6

	# Collision (thin box along the ladder)
	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(ladder_width + 0.2, ladder_height, 0.3)
	collision.shape = box_shape
	collision.position.y = ladder_height / 2
	ladder.add_child(collision)

	# Left rope
	var rope_left: MeshInstance3D = MeshInstance3D.new()
	var rope_mesh: BoxMesh = BoxMesh.new()
	rope_mesh.size = Vector3(0.05, ladder_height, 0.05)
	rope_left.mesh = rope_mesh
	rope_left.position = Vector3(-ladder_width / 2, ladder_height / 2, 0)
	rope_left.material_override = rope_mat
	ladder.add_child(rope_left)

	# Right rope
	var rope_right: MeshInstance3D = MeshInstance3D.new()
	rope_right.mesh = rope_mesh
	rope_right.position = Vector3(ladder_width / 2, ladder_height / 2, 0)
	rope_right.material_override = rope_mat
	ladder.add_child(rope_right)

	# Rungs
	var rung_mesh: BoxMesh = BoxMesh.new()
	rung_mesh.size = Vector3(ladder_width, 0.06, 0.08)

	var num_rungs: int = int(ladder_height / rung_spacing)
	for i: int in range(num_rungs):
		var rung: MeshInstance3D = MeshInstance3D.new()
		rung.mesh = rung_mesh
		rung.position = Vector3(0, 0.25 + i * rung_spacing, 0)
		rung.material_override = wood_mat
		ladder.add_child(rung)

	# Top anchor (hook/knot visual)
	var anchor: MeshInstance3D = MeshInstance3D.new()
	var anchor_mesh: BoxMesh = BoxMesh.new()
	anchor_mesh.size = Vector3(0.2, 0.15, 0.15)
	anchor.mesh = anchor_mesh
	anchor.position = Vector3(0, ladder_height + 0.1, 0)
	anchor.material_override = rope_mat
	ladder.add_child(anchor)

	# Climb detection area - larger than collision so player can grab it
	var climb_area: Area3D = Area3D.new()
	climb_area.name = "ClimbArea"
	var area_collision: CollisionShape3D = CollisionShape3D.new()
	var area_shape: BoxShape3D = BoxShape3D.new()
	area_shape.size = Vector3(ladder_width + 0.8, ladder_height + 1.0, 0.8)
	area_collision.shape = area_shape
	area_collision.position.y = ladder_height / 2
	climb_area.add_child(area_collision)
	ladder.add_child(climb_area)

	# Set the ladder_height on the script so climbing logic uses correct height
	ladder.set("ladder_height", ladder_height)

	return ladder
