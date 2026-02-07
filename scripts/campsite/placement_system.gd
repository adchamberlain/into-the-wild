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
var chunk_manager: Node  # For authoritative terrain height lookups


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
		# Find ChunkManager for terrain height lookups
		var main: Node = parent.get_parent()
		if main:
			chunk_manager = main.get_node_or_null("ChunkManager")
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


## Instantly place a torch without preview mode.
## Returns true if placement succeeded.
func place_torch_instant() -> bool:
	if not player or not camera or not inventory:
		return false

	if not inventory.has_item("torch"):
		return false

	# Calculate position 3m in front of player (same as _update_preview_position)
	var forward: Vector3 = -camera.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()

	var target_pos: Vector3 = player.global_position + forward * placement_distance

	# Check if we're in a cave (ChunkManager doesn't exist there)
	var in_overworld: bool = is_instance_valid(chunk_manager) and chunk_manager.has_method("get_height_at")

	if in_overworld:
		# Overworld: snap to terrain cell center to place on block tops
		var cell_sz: float = chunk_manager.cell_size
		target_pos.x = (floor(target_pos.x / cell_sz) + 0.5) * cell_sz
		target_pos.z = (floor(target_pos.z / cell_sz) + 0.5) * cell_sz

		# Use authoritative terrain height (avoids raycast edge issues at steps)
		var terrain_height: float = chunk_manager.get_height_at(target_pos.x, target_pos.z)

		# Reject placement unless target is at the same elevation as the player
		var player_terrain: float = chunk_manager.get_height_at(player.global_position.x, player.global_position.z)
		if absf(terrain_height - player_terrain) > 0.5:
			print("[PlacementSystem] Torch placement rejected: target height %.1f != player ground %.1f" % [terrain_height, player_terrain])
			return false

		target_pos.y = terrain_height - 0.04
	else:
		# Cave/interior: use simple grid snap and raycast from player height (avoids hitting ceiling)
		target_pos.x = round(target_pos.x / grid_size) * grid_size
		target_pos.z = round(target_pos.z / grid_size) * grid_size
		target_pos.y = _get_ground_height(target_pos.x, target_pos.z, player.global_position.y + 2.0) - 0.04

	# Create the torch structure
	var structure: Node3D = _create_placed_torch()
	if not structure:
		print("[PlacementSystem] Failed to create torch")
		return false

	# Position and orient toward player
	structure.global_position = target_pos
	var look_target: Vector3 = Vector3(player.global_position.x, target_pos.y, player.global_position.z)
	if target_pos.distance_squared_to(look_target) > 0.001:
		structure.look_at(look_target, Vector3.UP)
		structure.rotate_y(PI)

	# Add to Structures container
	var structures_container: Node = player.get_parent().get_node_or_null("Structures")
	if structures_container:
		structures_container.add_child(structure)
	else:
		player.get_parent().add_child(structure)

	# Activate the torch
	if structure.has_method("on_placed"):
		structure.on_placed()

	# Consume from inventory
	inventory.remove_item("torch", 1)

	# Register with campsite manager
	if campsite_manager and campsite_manager.has_method("register_structure"):
		campsite_manager.register_structure(structure, "placed_torch")

	# SFX and signal
	SFXManager.play_sfx("place_confirm")
	placement_confirmed.emit("placed_torch", target_pos)
	print("[PlacementSystem] Instantly placed torch at %s" % target_pos)
	return true


## Instantly place a lodestone without preview mode.
## Returns true if placement succeeded.
func place_lodestone_instant() -> bool:
	if not player or not camera or not inventory:
		return false

	if not inventory.has_item("lodestone"):
		return false

	# Calculate position 3m in front of player
	var forward: Vector3 = -camera.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()

	var target_pos: Vector3 = player.global_position + forward * placement_distance

	# Check if we're in a cave (ChunkManager doesn't exist there)
	var in_overworld: bool = is_instance_valid(chunk_manager) and chunk_manager.has_method("get_height_at")

	if in_overworld:
		# Overworld: snap to terrain cell center, use ChunkManager height
		var cell_sz: float = chunk_manager.cell_size
		target_pos.x = (floor(target_pos.x / cell_sz) + 0.5) * cell_sz
		target_pos.z = (floor(target_pos.z / cell_sz) + 0.5) * cell_sz

		var terrain_height: float = chunk_manager.get_height_at(target_pos.x, target_pos.z)

		# Reject placement if terrain is too far above or below the player
		var height_diff: float = absf(terrain_height - player.global_position.y)
		if height_diff > 4.0:
			print("[PlacementSystem] Lodestone placement rejected: terrain height %.1f too far from player %.1f (diff %.1f)" % [terrain_height, player.global_position.y, height_diff])
			return false

		target_pos.y = terrain_height - 0.04
	else:
		# Cave/interior: use simple grid snap and raycast from player height
		target_pos.x = round(target_pos.x / grid_size) * grid_size
		target_pos.z = round(target_pos.z / grid_size) * grid_size
		target_pos.y = _get_ground_height(target_pos.x, target_pos.z, player.global_position.y + 2.0) - 0.04

	# Create the lodestone structure
	var structure: Node3D = _create_lodestone()
	if not structure:
		print("[PlacementSystem] Failed to create lodestone")
		return false

	# Position and orient toward player
	structure.global_position = target_pos
	var look_target: Vector3 = Vector3(player.global_position.x, target_pos.y, player.global_position.z)
	if target_pos.distance_squared_to(look_target) > 0.001:
		structure.look_at(look_target, Vector3.UP)
		structure.rotate_y(PI)

	# Add to Structures container
	var structures_container: Node = player.get_parent().get_node_or_null("Structures")
	if structures_container:
		structures_container.add_child(structure)
	else:
		player.get_parent().add_child(structure)

	# Activate the lodestone
	if structure.has_method("on_placed"):
		structure.on_placed()

	# Consume from inventory
	inventory.remove_item("lodestone", 1)

	# Register with campsite manager
	if campsite_manager and campsite_manager.has_method("register_structure"):
		campsite_manager.register_structure(structure, "lodestone")

	# SFX and signal
	SFXManager.play_sfx("place_confirm")
	placement_confirmed.emit("lodestone", target_pos)
	print("[PlacementSystem] Instantly placed lodestone at %s" % target_pos)
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
func _get_ground_height(x: float, z: float, from_y: float = 50.0) -> float:
	if not player:
		return 0.0

	var space_state: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	if not space_state:
		return 0.0

	# Raycast downward to find ground
	var ray_origin: Vector3 = Vector3(x, from_y, z)
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

	# Check at multiple heights to detect both short (2-block) and tall cliffs.
	# A single ray at y+1.0 can miss short obstacles entirely.
	for check_height: float in [0.3, 0.8, 1.5]:
		var ray_origin: Vector3 = pos - forward_dir * 0.5 + Vector3(0, check_height, 0)
		var ray_end: Vector3 = pos + forward_dir * 3.0 + Vector3(0, check_height, 0)

		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
		query.from = ray_origin
		query.to = ray_end
		query.collision_mask = 1  # Terrain layer

		var result: Dictionary = space_state.intersect_ray(query)
		if not result.is_empty():
			return true

	return false


## Snap a position to the nearest cliff face in the given direction.
## Returns the position right against the cliff, or original position if no cliff found.
func _snap_to_cliff_face(pos: Vector3, forward_dir: Vector3) -> Vector3:
	if not player:
		return pos

	var space_state: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	if not space_state:
		return pos

	# Raycast forward from the position to find the cliff face.
	# Try multiple heights to handle both short (2-block) and tall cliffs.
	for check_height: float in [0.5, 1.0, 1.5]:
		var ray_origin: Vector3 = pos - forward_dir * 1.0 + Vector3(0, check_height, 0)
		var ray_end: Vector3 = pos + forward_dir * 5.0 + Vector3(0, check_height, 0)

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

	# Check if there's terrain directly behind/above by raycasting horizontally
	# into the cliff at regular 1-unit intervals (no gaps that miss short cliffs).
	var cliff_top_height: float = base_height

	# Sample every 1.0 unit up to 15 units - consistent spacing ensures
	# 2-block and other short cliffs aren't missed by sampling gaps.
	var test_height: float = 1.0
	while test_height <= 15.0:
		var test_y: float = base_height + test_height
		var horizontal_origin: Vector3 = Vector3(pos.x - forward_dir.x * 0.5, test_y, pos.z - forward_dir.z * 0.5)
		var horizontal_end: Vector3 = Vector3(pos.x + forward_dir.x * 3.0, test_y, pos.z + forward_dir.z * 3.0)

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

		test_height += 1.0

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
	# Sink slightly into ground (-0.04) to prevent visual floating seam
	target_pos.y = _get_ground_height(target_pos.x, target_pos.z) - 0.04

	# Rope ladders must be placed at the cliff BASE, not on top.
	# If the preview ground is higher than the player's ground, snap down to the lower height.
	if current_structure_type == "rope_ladder":
		var player_ground_y: float = _get_ground_height(player.global_position.x, player.global_position.z)
		if target_pos.y > player_ground_y + 0.5:
			target_pos.y = player_ground_y - 0.04

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
		"snare_trap":
			return _create_snare_trap()
		"smithing_station":
			return _create_smithing_station()
		"smoker":
			return _create_smoker()
		"weather_vane":
			return _create_weather_vane()
		"placed_torch":
			return _create_placed_torch()
	return null


func _create_fire_pit() -> StaticBody3D:
	var fire_pit: StaticBody3D = StaticBody3D.new()
	fire_pit.name = "FirePit"
	fire_pit.set_script(load("res://scripts/campsite/structure_fire_pit.gd"))

	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(1.2, 0.4, 1.2)
	collision.shape = box_shape
	collision.position.y = 0.2
	fire_pit.add_child(collision)

	# --- Stone ring: 6 stones in a neat circle ---
	var stone_mat: StandardMaterial3D = StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.40, 0.38, 0.35)
	stone_mat.roughness = 0.95
	var stone_dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	stone_dark_mat.albedo_color = Color(0.34, 0.32, 0.29)
	stone_dark_mat.roughness = 0.95
	for i: int in range(6):
		var stone: MeshInstance3D = MeshInstance3D.new()
		var stone_mesh: BoxMesh = BoxMesh.new()
		stone_mesh.size = Vector3(0.22, 0.12, 0.18)
		stone.mesh = stone_mesh
		var angle: float = i * TAU / 6.0
		stone.position = Vector3(cos(angle) * 0.42, 0.06, sin(angle) * 0.42)
		stone.rotation.y = angle + 0.3
		stone.material_override = stone_mat if i % 2 == 0 else stone_dark_mat
		fire_pit.add_child(stone)

	# --- Two crossed logs ---
	var log_mat: StandardMaterial3D = StandardMaterial3D.new()
	log_mat.albedo_color = Color(0.36, 0.22, 0.10)
	log_mat.roughness = 0.92
	var log1: MeshInstance3D = MeshInstance3D.new()
	var log1_mesh: BoxMesh = BoxMesh.new()
	log1_mesh.size = Vector3(0.7, 0.10, 0.10)
	log1.mesh = log1_mesh
	log1.position = Vector3(0, 0.10, 0)
	log1.rotation.y = -0.3
	log1.material_override = log_mat
	fire_pit.add_child(log1)
	var log2: MeshInstance3D = MeshInstance3D.new()
	var log2_mesh: BoxMesh = BoxMesh.new()
	log2_mesh.size = Vector3(0.65, 0.09, 0.09)
	log2.mesh = log2_mesh
	log2.position = Vector3(0, 0.14, 0)
	log2.rotation.y = 0.8
	log2.material_override = log_mat
	fire_pit.add_child(log2)

	# --- Fire: 3 layers (base, mid, tip) ---
	var base_flame_mat: StandardMaterial3D = StandardMaterial3D.new()
	base_flame_mat.albedo_color = Color(1.0, 0.35, 0.0)
	base_flame_mat.emission_enabled = true
	base_flame_mat.emission = Color(0.95, 0.3, 0.0)
	base_flame_mat.emission_energy_multiplier = 2.5
	var base_flame: MeshInstance3D = MeshInstance3D.new()
	base_flame.name = "FireMesh"
	var bf_mesh: BoxMesh = BoxMesh.new()
	bf_mesh.size = Vector3(0.28, 0.22, 0.24)
	base_flame.mesh = bf_mesh
	base_flame.position = Vector3(0, 0.30, 0)
	base_flame.material_override = base_flame_mat
	fire_pit.add_child(base_flame)

	var mid_mat: StandardMaterial3D = StandardMaterial3D.new()
	mid_mat.albedo_color = Color(1.0, 0.55, 0.05)
	mid_mat.emission_enabled = true
	mid_mat.emission = Color(1.0, 0.5, 0.0)
	mid_mat.emission_energy_multiplier = 3.0
	var mid_flame: MeshInstance3D = MeshInstance3D.new()
	var mf_mesh: BoxMesh = BoxMesh.new()
	mf_mesh.size = Vector3(0.18, 0.18, 0.16)
	mid_flame.mesh = mf_mesh
	mid_flame.position = Vector3(0, 0.48, 0)
	mid_flame.material_override = mid_mat
	fire_pit.add_child(mid_flame)

	var tip_mat: StandardMaterial3D = StandardMaterial3D.new()
	tip_mat.albedo_color = Color(1.0, 0.82, 0.25)
	tip_mat.emission_enabled = true
	tip_mat.emission = Color(1.0, 0.75, 0.15)
	tip_mat.emission_energy_multiplier = 3.5
	var tip_flame: MeshInstance3D = MeshInstance3D.new()
	var tf_mesh: BoxMesh = BoxMesh.new()
	tf_mesh.size = Vector3(0.10, 0.12, 0.08)
	tip_flame.mesh = tf_mesh
	tip_flame.position = Vector3(0, 0.62, 0)
	tip_flame.material_override = tip_mat
	fire_pit.add_child(tip_flame)

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

	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(2.0, 1.5, 2.0)
	collision.shape = box_shape
	collision.position.y = 0.75
	shelter.add_child(collision)

	# Wood materials with variation
	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.50, 0.33, 0.18)
	wood_mat.roughness = 0.92

	var wood_dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_dark_mat.albedo_color = Color(0.40, 0.26, 0.13)
	wood_dark_mat.roughness = 0.92

	var wood_light_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_light_mat.albedo_color = Color(0.58, 0.40, 0.24)
	wood_light_mat.roughness = 0.90

	# Canvas cover - main panel
	var canvas_mat: StandardMaterial3D = StandardMaterial3D.new()
	canvas_mat.albedo_color = Color(0.62, 0.57, 0.42)
	canvas_mat.roughness = 0.85

	var cover: MeshInstance3D = MeshInstance3D.new()
	var cover_mesh: BoxMesh = BoxMesh.new()
	cover_mesh.size = Vector3(2.4, 0.05, 2.2)
	cover.mesh = cover_mesh
	cover.position = Vector3(0, 0.9, 0)
	cover.rotation.x = 0.5
	cover.material_override = canvas_mat
	shelter.add_child(cover)

	# Canvas shadow underside
	var canvas_shadow_mat: StandardMaterial3D = StandardMaterial3D.new()
	canvas_shadow_mat.albedo_color = Color(0.48, 0.44, 0.32)
	var cover_under: MeshInstance3D = MeshInstance3D.new()
	var cu_mesh: BoxMesh = BoxMesh.new()
	cu_mesh.size = Vector3(2.3, 0.02, 2.1)
	cover_under.mesh = cu_mesh
	cover_under.position = Vector3(0, 0.87, 0)
	cover_under.rotation.x = 0.5
	cover_under.material_override = canvas_shadow_mat
	shelter.add_child(cover_under)

	# Canvas seam lines (stitching detail)
	var seam_mat: StandardMaterial3D = StandardMaterial3D.new()
	seam_mat.albedo_color = Color(0.52, 0.48, 0.35)
	for i: int in range(3):
		var seam: MeshInstance3D = MeshInstance3D.new()
		var seam_mesh: BoxMesh = BoxMesh.new()
		seam_mesh.size = Vector3(2.3, 0.015, 0.03)
		seam.mesh = seam_mesh
		seam.position = Vector3(0, 0.92, -0.6 + i * 0.6)
		seam.rotation.x = 0.5
		seam.material_override = seam_mat
		shelter.add_child(seam)

	# Frame beams (back and front)
	var frame_mesh: BoxMesh = BoxMesh.new()
	frame_mesh.size = Vector3(2.5, 0.1, 0.1)

	var frame_back: MeshInstance3D = MeshInstance3D.new()
	frame_back.mesh = frame_mesh
	frame_back.position = Vector3(0, 1.5, -0.8)
	frame_back.material_override = wood_mat
	shelter.add_child(frame_back)

	var frame_front: MeshInstance3D = MeshInstance3D.new()
	frame_front.mesh = frame_mesh
	frame_front.position = Vector3(0, 0.15, 1.0)
	frame_front.material_override = wood_mat
	shelter.add_child(frame_front)

	# Support poles with bark detail
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

	# Bark texture strips on poles
	var bark_strip_mesh: BoxMesh = BoxMesh.new()
	bark_strip_mesh.size = Vector3(0.04, 1.48, 0.11)
	for side_x: float in [-1.1, 1.1]:
		var strip: MeshInstance3D = MeshInstance3D.new()
		strip.mesh = bark_strip_mesh
		strip.position = Vector3(side_x + 0.02, 0.75, -0.8)
		strip.material_override = wood_dark_mat
		shelter.add_child(strip)

	# Lashing at pole-beam joints (rope wraps)
	var lash_mat: StandardMaterial3D = StandardMaterial3D.new()
	lash_mat.albedo_color = Color(0.55, 0.48, 0.35)
	var lash_mesh: BoxMesh = BoxMesh.new()
	lash_mesh.size = Vector3(0.16, 0.08, 0.16)
	for side_x: float in [-1.1, 1.1]:
		var lash: MeshInstance3D = MeshInstance3D.new()
		lash.mesh = lash_mesh
		lash.position = Vector3(side_x, 1.5, -0.8)
		lash.material_override = lash_mat
		shelter.add_child(lash)

	# Front low support sticks (forked)
	var stick_mesh: BoxMesh = BoxMesh.new()
	stick_mesh.size = Vector3(0.06, 0.6, 0.06)
	for side_x: float in [-1.1, 1.1]:
		var stick: MeshInstance3D = MeshInstance3D.new()
		stick.mesh = stick_mesh
		stick.position = Vector3(side_x, 0.3, 1.0)
		stick.rotation.z = 0.05 if side_x < 0 else -0.05
		stick.material_override = wood_dark_mat
		shelter.add_child(stick)

	# Ground leaf bed (inside shelter)
	var leaf_mat: StandardMaterial3D = StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.35, 0.28, 0.15)
	var leaf_bed: MeshInstance3D = MeshInstance3D.new()
	var lb_mesh: BoxMesh = BoxMesh.new()
	lb_mesh.size = Vector3(1.6, 0.06, 1.4)
	leaf_bed.mesh = lb_mesh
	leaf_bed.position = Vector3(0, 0.03, -0.1)
	leaf_bed.material_override = leaf_mat
	shelter.add_child(leaf_bed)

	# Scattered leaf patches
	var leaf_green_mat: StandardMaterial3D = StandardMaterial3D.new()
	leaf_green_mat.albedo_color = Color(0.28, 0.35, 0.18)
	for i: int in range(4):
		var patch: MeshInstance3D = MeshInstance3D.new()
		var p_mesh: BoxMesh = BoxMesh.new()
		p_mesh.size = Vector3(0.4, 0.03, 0.3)
		patch.mesh = p_mesh
		patch.position = Vector3(-0.5 + i * 0.35, 0.05, -0.3 + (i % 2) * 0.3)
		patch.rotation.y = i * 0.7
		patch.material_override = leaf_green_mat if i % 2 == 0 else leaf_mat
		shelter.add_child(patch)

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

	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(1.0, 0.6, 0.6)
	collision.shape = box_shape
	collision.position.y = 0.3
	storage.add_child(collision)

	# Materials
	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.58, 0.40, 0.24)
	wood_mat.roughness = 0.88

	var wood_dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_dark_mat.albedo_color = Color(0.45, 0.30, 0.16)
	wood_dark_mat.roughness = 0.90

	var wood_light_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_light_mat.albedo_color = Color(0.65, 0.48, 0.30)
	wood_light_mat.roughness = 0.85

	var metal_mat: StandardMaterial3D = StandardMaterial3D.new()
	metal_mat.albedo_color = Color(0.30, 0.28, 0.26)
	metal_mat.metallic = 0.6
	metal_mat.roughness = 0.55

	# Box body
	var box_inst: MeshInstance3D = MeshInstance3D.new()
	var bm: BoxMesh = BoxMesh.new()
	bm.size = Vector3(1.0, 0.6, 0.6)
	box_inst.mesh = bm
	box_inst.position.y = 0.3
	box_inst.material_override = wood_mat
	storage.add_child(box_inst)

	# Plank lines (vertical grain on front)
	for i: int in range(5):
		var plank: MeshInstance3D = MeshInstance3D.new()
		var pm: BoxMesh = BoxMesh.new()
		pm.size = Vector3(0.015, 0.56, 0.61)
		plank.mesh = pm
		plank.position = Vector3(-0.4 + i * 0.2, 0.3, 0)
		plank.material_override = wood_dark_mat
		storage.add_child(plank)

	# Side plank lines
	for i: int in range(3):
		var s_plank: MeshInstance3D = MeshInstance3D.new()
		var sp_m: BoxMesh = BoxMesh.new()
		sp_m.size = Vector3(1.01, 0.56, 0.015)
		s_plank.mesh = sp_m
		s_plank.position = Vector3(0, 0.3, -0.2 + i * 0.2)
		s_plank.material_override = wood_dark_mat
		storage.add_child(s_plank)

	# Metal corner bands
	var band_mesh_h: BoxMesh = BoxMesh.new()
	band_mesh_h.size = Vector3(1.04, 0.04, 0.64)
	for y_pos: float in [0.04, 0.58]:
		var band: MeshInstance3D = MeshInstance3D.new()
		band.mesh = band_mesh_h
		band.position = Vector3(0, y_pos, 0)
		band.material_override = metal_mat
		storage.add_child(band)

	# Metal side bands (vertical reinforcements)
	var band_mesh_v: BoxMesh = BoxMesh.new()
	band_mesh_v.size = Vector3(0.04, 0.60, 0.64)
	for x_pos: float in [-0.50, 0.50]:
		var vband: MeshInstance3D = MeshInstance3D.new()
		vband.mesh = band_mesh_v
		vband.position = Vector3(x_pos, 0.3, 0)
		vband.material_override = metal_mat
		storage.add_child(vband)

	# Lid
	var lid: MeshInstance3D = MeshInstance3D.new()
	var lid_mesh: BoxMesh = BoxMesh.new()
	lid_mesh.size = Vector3(1.04, 0.08, 0.64)
	lid.mesh = lid_mesh
	lid.position.y = 0.64
	lid.material_override = wood_dark_mat
	storage.add_child(lid)

	# Lid edge highlight
	var lid_top: MeshInstance3D = MeshInstance3D.new()
	var lt_m: BoxMesh = BoxMesh.new()
	lt_m.size = Vector3(0.96, 0.02, 0.56)
	lid_top.mesh = lt_m
	lid_top.position.y = 0.69
	lid_top.material_override = wood_light_mat
	storage.add_child(lid_top)

	# Handle on front
	var handle_base: MeshInstance3D = MeshInstance3D.new()
	var hb_m: BoxMesh = BoxMesh.new()
	hb_m.size = Vector3(0.2, 0.04, 0.04)
	handle_base.mesh = hb_m
	handle_base.position = Vector3(0, 0.40, 0.32)
	handle_base.material_override = metal_mat
	storage.add_child(handle_base)

	# Handle brackets
	for hx: float in [-0.08, 0.08]:
		var bracket: MeshInstance3D = MeshInstance3D.new()
		var br_m: BoxMesh = BoxMesh.new()
		br_m.size = Vector3(0.03, 0.06, 0.03)
		bracket.mesh = br_m
		bracket.position = Vector3(hx, 0.38, 0.32)
		bracket.material_override = metal_mat
		storage.add_child(bracket)

	# Latch on front
	var latch: MeshInstance3D = MeshInstance3D.new()
	var la_m: BoxMesh = BoxMesh.new()
	la_m.size = Vector3(0.08, 0.10, 0.02)
	latch.mesh = la_m
	latch.position = Vector3(0, 0.60, 0.32)
	latch.material_override = metal_mat
	storage.add_child(latch)

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

	# Materials with variation
	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.52, 0.37, 0.22)
	wood_mat.roughness = 0.88

	var wood_dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_dark_mat.albedo_color = Color(0.40, 0.26, 0.14)
	wood_dark_mat.roughness = 0.90

	var wood_light_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_light_mat.albedo_color = Color(0.60, 0.45, 0.28)
	wood_light_mat.roughness = 0.85

	var leg_mat: StandardMaterial3D = StandardMaterial3D.new()
	leg_mat.albedo_color = Color(0.42, 0.28, 0.15)
	leg_mat.roughness = 0.92

	var metal_mat: StandardMaterial3D = StandardMaterial3D.new()
	metal_mat.albedo_color = Color(0.35, 0.33, 0.30)
	metal_mat.metallic = 0.5
	metal_mat.roughness = 0.6

	# Thick tabletop
	var top: MeshInstance3D = MeshInstance3D.new()
	var top_mesh: BoxMesh = BoxMesh.new()
	top_mesh.size = Vector3(1.2, 0.1, 0.8)
	top.mesh = top_mesh
	top.position.y = 0.75
	top.material_override = wood_mat
	bench.add_child(top)

	# Wood grain lines on tabletop
	for i: int in range(4):
		var grain: MeshInstance3D = MeshInstance3D.new()
		var g_mesh: BoxMesh = BoxMesh.new()
		g_mesh.size = Vector3(1.18, 0.012, 0.03)
		grain.mesh = g_mesh
		grain.position = Vector3(0, 0.806, -0.25 + i * 0.18)
		grain.material_override = wood_dark_mat
		bench.add_child(grain)

	# Edge banding (slightly darker lip around tabletop)
	var edge_mat: StandardMaterial3D = StandardMaterial3D.new()
	edge_mat.albedo_color = Color(0.45, 0.30, 0.17)
	# Front edge
	var front_edge: MeshInstance3D = MeshInstance3D.new()
	var fe_mesh: BoxMesh = BoxMesh.new()
	fe_mesh.size = Vector3(1.22, 0.1, 0.03)
	front_edge.mesh = fe_mesh
	front_edge.position = Vector3(0, 0.75, 0.41)
	front_edge.material_override = edge_mat
	bench.add_child(front_edge)
	# Back edge
	var back_edge: MeshInstance3D = MeshInstance3D.new()
	back_edge.mesh = fe_mesh
	back_edge.position = Vector3(0, 0.75, -0.41)
	back_edge.material_override = edge_mat
	bench.add_child(back_edge)

	# Table legs
	var leg_mesh: BoxMesh = BoxMesh.new()
	leg_mesh.size = Vector3(0.1, 0.65, 0.1)

	var leg_positions: Array[Vector3] = [
		Vector3(-0.5, 0.325, -0.3), Vector3(0.5, 0.325, -0.3),
		Vector3(-0.5, 0.325, 0.3), Vector3(0.5, 0.325, 0.3)
	]
	for pos: Vector3 in leg_positions:
		var leg: MeshInstance3D = MeshInstance3D.new()
		leg.mesh = leg_mesh
		leg.position = pos
		leg.material_override = leg_mat
		bench.add_child(leg)

	# Cross-braces for stability
	var brace_mesh: BoxMesh = BoxMesh.new()
	brace_mesh.size = Vector3(0.9, 0.05, 0.06)
	# Front brace
	var f_brace: MeshInstance3D = MeshInstance3D.new()
	f_brace.mesh = brace_mesh
	f_brace.position = Vector3(0, 0.2, 0.3)
	f_brace.material_override = wood_dark_mat
	bench.add_child(f_brace)
	# Back brace
	var b_brace: MeshInstance3D = MeshInstance3D.new()
	b_brace.mesh = brace_mesh
	b_brace.position = Vector3(0, 0.2, -0.3)
	b_brace.material_override = wood_dark_mat
	bench.add_child(b_brace)

	# Side brace
	var s_brace_mesh: BoxMesh = BoxMesh.new()
	s_brace_mesh.size = Vector3(0.06, 0.05, 0.5)
	var side_brace: MeshInstance3D = MeshInstance3D.new()
	side_brace.mesh = s_brace_mesh
	side_brace.position = Vector3(0, 0.35, 0)
	side_brace.material_override = wood_dark_mat
	bench.add_child(side_brace)

	# Tools on surface: small hammer head
	var hammer_head: MeshInstance3D = MeshInstance3D.new()
	var hh_mesh: BoxMesh = BoxMesh.new()
	hh_mesh.size = Vector3(0.06, 0.04, 0.12)
	hammer_head.mesh = hh_mesh
	hammer_head.position = Vector3(-0.35, 0.82, 0.1)
	hammer_head.material_override = metal_mat
	bench.add_child(hammer_head)
	# Hammer handle
	var hammer_handle: MeshInstance3D = MeshInstance3D.new()
	var hh2_mesh: BoxMesh = BoxMesh.new()
	hh2_mesh.size = Vector3(0.03, 0.03, 0.2)
	hammer_handle.mesh = hh2_mesh
	hammer_handle.position = Vector3(-0.35, 0.82, 0.22)
	hammer_handle.material_override = wood_light_mat
	bench.add_child(hammer_handle)

	# Small knife on surface
	var knife_blade: MeshInstance3D = MeshInstance3D.new()
	var kb_mesh: BoxMesh = BoxMesh.new()
	kb_mesh.size = Vector3(0.15, 0.01, 0.03)
	knife_blade.mesh = kb_mesh
	knife_blade.position = Vector3(0.3, 0.812, -0.15)
	knife_blade.rotation.y = 0.3
	knife_blade.material_override = metal_mat
	bench.add_child(knife_blade)
	var knife_grip: MeshInstance3D = MeshInstance3D.new()
	var kg_mesh: BoxMesh = BoxMesh.new()
	kg_mesh.size = Vector3(0.08, 0.02, 0.04)
	knife_grip.mesh = kg_mesh
	knife_grip.position = Vector3(0.38, 0.815, -0.14)
	knife_grip.rotation.y = 0.3
	knife_grip.material_override = wood_dark_mat
	bench.add_child(knife_grip)

	# Wear marks on tabletop (lighter scratched areas)
	var wear_mat: StandardMaterial3D = StandardMaterial3D.new()
	wear_mat.albedo_color = Color(0.58, 0.44, 0.28, 0.4)
	wear_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var wear: MeshInstance3D = MeshInstance3D.new()
	var w_mesh: BoxMesh = BoxMesh.new()
	w_mesh.size = Vector3(0.4, 0.012, 0.3)
	wear.mesh = w_mesh
	wear.position = Vector3(0, 0.808, 0.05)
	wear.material_override = wear_mat
	bench.add_child(wear)

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

	# Materials
	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.50, 0.35, 0.20)
	wood_mat.roughness = 0.90

	var wood_dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_dark_mat.albedo_color = Color(0.38, 0.25, 0.13)
	wood_dark_mat.roughness = 0.92

	var rope_mat: StandardMaterial3D = StandardMaterial3D.new()
	rope_mat.albedo_color = Color(0.55, 0.48, 0.35)
	rope_mat.roughness = 0.85

	var meat_mat: StandardMaterial3D = StandardMaterial3D.new()
	meat_mat.albedo_color = Color(0.55, 0.28, 0.22)

	var herb_mat: StandardMaterial3D = StandardMaterial3D.new()
	herb_mat.albedo_color = Color(0.30, 0.45, 0.22)

	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(1.5, 1.2, 0.4)
	collision.shape = box_shape
	collision.position.y = 0.6
	rack.add_child(collision)

	# Posts with bark texture
	var post_mesh: BoxMesh = BoxMesh.new()
	post_mesh.size = Vector3(0.1, 1.2, 0.1)
	var bark_mesh: BoxMesh = BoxMesh.new()
	bark_mesh.size = Vector3(0.04, 1.18, 0.11)

	for side_x: float in [-0.6, 0.6]:
		var post: MeshInstance3D = MeshInstance3D.new()
		post.mesh = post_mesh
		post.position = Vector3(side_x, 0.6, 0)
		post.material_override = wood_mat
		rack.add_child(post)
		# Bark detail
		var bark: MeshInstance3D = MeshInstance3D.new()
		bark.mesh = bark_mesh
		bark.position = Vector3(side_x + 0.02, 0.6, 0)
		bark.material_override = wood_dark_mat
		rack.add_child(bark)

	# Forked tops on posts (Y-shape support)
	var fork_mesh: BoxMesh = BoxMesh.new()
	fork_mesh.size = Vector3(0.06, 0.15, 0.04)
	for side_x: float in [-0.6, 0.6]:
		for fork_off: float in [-0.06, 0.06]:
			var fork: MeshInstance3D = MeshInstance3D.new()
			fork.mesh = fork_mesh
			fork.position = Vector3(side_x + fork_off, 1.25, 0)
			fork.rotation.z = fork_off * 5.0
			fork.material_override = wood_mat
			rack.add_child(fork)

	# Horizontal bars
	var bar_mesh: BoxMesh = BoxMesh.new()
	bar_mesh.size = Vector3(1.3, 0.06, 0.06)

	for i: int in range(3):
		var bar_y: float = 0.4 + i * 0.35
		var bar: MeshInstance3D = MeshInstance3D.new()
		bar.mesh = bar_mesh
		bar.position = Vector3(0, bar_y, 0)
		bar.material_override = wood_mat
		rack.add_child(bar)

	# Lashing at bar-post joints
	var lash_mesh: BoxMesh = BoxMesh.new()
	lash_mesh.size = Vector3(0.14, 0.04, 0.14)
	for i: int in range(3):
		for side_x: float in [-0.6, 0.6]:
			var lash: MeshInstance3D = MeshInstance3D.new()
			lash.mesh = lash_mesh
			lash.position = Vector3(side_x, 0.4 + i * 0.35, 0)
			lash.material_override = rope_mat
			rack.add_child(lash)

	# Hanging items: strips of meat/fish and herb bundles
	var strip_mesh: BoxMesh = BoxMesh.new()
	strip_mesh.size = Vector3(0.08, 0.18, 0.03)
	var herb_bundle_mesh: BoxMesh = BoxMesh.new()
	herb_bundle_mesh.size = Vector3(0.06, 0.14, 0.06)

	# Items on top bar
	for i: int in range(4):
		var item: MeshInstance3D = MeshInstance3D.new()
		if i % 2 == 0:
			item.mesh = strip_mesh
			item.material_override = meat_mat
		else:
			item.mesh = herb_bundle_mesh
			item.material_override = herb_mat
		item.position = Vector3(-0.35 + i * 0.25, 1.0, 0)
		rack.add_child(item)

	# Items on middle bar
	for i: int in range(3):
		var item: MeshInstance3D = MeshInstance3D.new()
		item.mesh = strip_mesh
		item.material_override = meat_mat if i != 1 else herb_mat
		item.position = Vector3(-0.25 + i * 0.25, 0.58, 0)
		rack.add_child(item)

	# Hanging cord details (small vertical ropes)
	var cord_mesh: BoxMesh = BoxMesh.new()
	cord_mesh.size = Vector3(0.015, 0.08, 0.015)
	for i: int in range(5):
		var cord: MeshInstance3D = MeshInstance3D.new()
		cord.mesh = cord_mesh
		cord.position = Vector3(-0.4 + i * 0.2, 1.06, 0)
		cord.material_override = rope_mat
		rack.add_child(cord)

	return rack


func _create_herb_garden() -> StaticBody3D:
	var garden: StaticBody3D = StaticBody3D.new()
	garden.name = "HerbGarden"
	garden.set_script(load("res://scripts/campsite/structure_garden.gd"))

	# Materials
	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.50, 0.35, 0.20)
	wood_mat.roughness = 0.90

	var wood_dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_dark_mat.albedo_color = Color(0.40, 0.27, 0.14)
	wood_dark_mat.roughness = 0.92

	var dirt_mat: StandardMaterial3D = StandardMaterial3D.new()
	dirt_mat.albedo_color = Color(0.38, 0.26, 0.16)
	dirt_mat.roughness = 0.95

	var dirt_dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	dirt_dark_mat.albedo_color = Color(0.30, 0.20, 0.12)
	dirt_dark_mat.roughness = 0.95

	# Plant colors - varied greens for different herbs
	var herb_green: StandardMaterial3D = StandardMaterial3D.new()
	herb_green.albedo_color = Color(0.25, 0.55, 0.20)

	var herb_dark_green: StandardMaterial3D = StandardMaterial3D.new()
	herb_dark_green.albedo_color = Color(0.18, 0.42, 0.15)

	var herb_light_green: StandardMaterial3D = StandardMaterial3D.new()
	herb_light_green.albedo_color = Color(0.35, 0.62, 0.28)

	var herb_sage: StandardMaterial3D = StandardMaterial3D.new()
	herb_sage.albedo_color = Color(0.40, 0.52, 0.38)

	var flower_mat: StandardMaterial3D = StandardMaterial3D.new()
	flower_mat.albedo_color = Color(0.75, 0.55, 0.80)

	var flower_yellow_mat: StandardMaterial3D = StandardMaterial3D.new()
	flower_yellow_mat.albedo_color = Color(0.90, 0.80, 0.30)

	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(2.0, 0.4, 1.5)
	collision.shape = box_shape
	collision.position.y = 0.2
	garden.add_child(collision)

	# Wooden border with plank detail
	var border_mesh: BoxMesh = BoxMesh.new()
	border_mesh.size = Vector3(2.0, 0.3, 0.1)
	var side_mesh: BoxMesh = BoxMesh.new()
	side_mesh.size = Vector3(0.1, 0.3, 1.5)

	# Front/back borders with plank lines
	for z_pos: float in [0.7, -0.7]:
		var border: MeshInstance3D = MeshInstance3D.new()
		border.mesh = border_mesh
		border.position = Vector3(0, 0.15, z_pos)
		border.material_override = wood_mat
		garden.add_child(border)
		# Plank lines
		for i: int in range(3):
			var p_line: MeshInstance3D = MeshInstance3D.new()
			var pl_m: BoxMesh = BoxMesh.new()
			pl_m.size = Vector3(0.015, 0.28, 0.101)
			p_line.mesh = pl_m
			p_line.position = Vector3(-0.5 + i * 0.5, 0.15, z_pos)
			p_line.material_override = wood_dark_mat
			garden.add_child(p_line)

	# Side borders
	for x_pos: float in [-0.95, 0.95]:
		var side: MeshInstance3D = MeshInstance3D.new()
		side.mesh = side_mesh
		side.position = Vector3(x_pos, 0.15, 0)
		side.material_override = wood_mat
		garden.add_child(side)

	# Corner posts (slightly taller)
	var corner_mesh: BoxMesh = BoxMesh.new()
	corner_mesh.size = Vector3(0.08, 0.36, 0.08)
	for cx: float in [-0.95, 0.95]:
		for cz: float in [-0.7, 0.7]:
			var corner: MeshInstance3D = MeshInstance3D.new()
			corner.mesh = corner_mesh
			corner.position = Vector3(cx, 0.18, cz)
			corner.material_override = wood_dark_mat
			garden.add_child(corner)

	# Dirt bed with texture
	var dirt: MeshInstance3D = MeshInstance3D.new()
	var dirt_mesh: BoxMesh = BoxMesh.new()
	dirt_mesh.size = Vector3(1.8, 0.2, 1.3)
	dirt.mesh = dirt_mesh
	dirt.position.y = 0.1
	dirt.material_override = dirt_mat
	garden.add_child(dirt)

	# Furrow rows (darker dirt lines)
	for i: int in range(3):
		var furrow: MeshInstance3D = MeshInstance3D.new()
		var f_mesh: BoxMesh = BoxMesh.new()
		f_mesh.size = Vector3(1.7, 0.015, 0.06)
		furrow.mesh = f_mesh
		furrow.position = Vector3(0, 0.21, -0.4 + i * 0.4)
		furrow.material_override = dirt_dark_mat
		garden.add_child(furrow)

	# Plants - 8 varied herb types in 2x4 grid
	var herb_materials: Array = [herb_green, herb_dark_green, herb_light_green, herb_sage,
		herb_green, herb_light_green, herb_dark_green, herb_sage]

	for row: int in range(2):
		for col: int in range(4):
			var idx: int = row * 4 + col
			var px: float = -0.6 + col * 0.4
			var pz: float = -0.3 + row * 0.6

			# Main plant body (varied heights)
			var plant: MeshInstance3D = MeshInstance3D.new()
			var p_mesh: BoxMesh = BoxMesh.new()
			var height: float = 0.22 + (idx % 3) * 0.06
			p_mesh.size = Vector3(0.2, height, 0.2)
			plant.mesh = p_mesh
			plant.position = Vector3(px, 0.2 + height / 2.0, pz)
			plant.material_override = herb_materials[idx]
			garden.add_child(plant)

			# Leaf clusters (smaller boxes around main plant)
			for leaf_i: int in range(3):
				var leaf: MeshInstance3D = MeshInstance3D.new()
				var l_mesh: BoxMesh = BoxMesh.new()
				l_mesh.size = Vector3(0.1, 0.08, 0.1)
				leaf.mesh = l_mesh
				var lx: float = px + [-0.1, 0.1, 0.0][leaf_i]
				var lz: float = pz + [0.05, -0.05, 0.1][leaf_i]
				leaf.position = Vector3(lx, 0.28 + leaf_i * 0.04, lz)
				leaf.material_override = herb_materials[idx]
				garden.add_child(leaf)

			# Some plants get flowers (small colored dots on top)
			if idx == 2 or idx == 5:
				var flower: MeshInstance3D = MeshInstance3D.new()
				var fl_mesh: BoxMesh = BoxMesh.new()
				fl_mesh.size = Vector3(0.06, 0.06, 0.06)
				flower.mesh = fl_mesh
				flower.position = Vector3(px, 0.2 + height + 0.05, pz)
				flower.material_override = flower_mat if idx == 2 else flower_yellow_mat
				garden.add_child(flower)

	# Mulch/bark chips scattered on soil
	var mulch_mat: StandardMaterial3D = StandardMaterial3D.new()
	mulch_mat.albedo_color = Color(0.42, 0.30, 0.18)
	for i: int in range(6):
		var mulch: MeshInstance3D = MeshInstance3D.new()
		var m_mesh: BoxMesh = BoxMesh.new()
		m_mesh.size = Vector3(0.08, 0.02, 0.05)
		mulch.mesh = m_mesh
		mulch.position = Vector3(-0.7 + i * 0.28, 0.21, 0.15 - (i % 2) * 0.3)
		mulch.rotation.y = i * 0.8
		mulch.material_override = mulch_mat
		garden.add_child(mulch)

	return garden


func _create_canvas_tent() -> StaticBody3D:
	var tent: StaticBody3D = StaticBody3D.new()
	tent.name = "CanvasTent"
	tent.set_script(load("res://scripts/campsite/structure_canvas_tent.gd"))

	# Materials
	var canvas_mat: StandardMaterial3D = StandardMaterial3D.new()
	canvas_mat.albedo_color = Color(0.72, 0.66, 0.52)
	canvas_mat.roughness = 0.85

	var canvas_shadow_mat: StandardMaterial3D = StandardMaterial3D.new()
	canvas_shadow_mat.albedo_color = Color(0.60, 0.55, 0.42)

	var canvas_light_mat: StandardMaterial3D = StandardMaterial3D.new()
	canvas_light_mat.albedo_color = Color(0.78, 0.72, 0.58)

	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.50, 0.35, 0.20)
	wood_mat.roughness = 0.90

	var wood_dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_dark_mat.albedo_color = Color(0.38, 0.25, 0.13)

	var rope_mat: StandardMaterial3D = StandardMaterial3D.new()
	rope_mat.albedo_color = Color(0.55, 0.48, 0.35)

	var interior_mat: StandardMaterial3D = StandardMaterial3D.new()
	interior_mat.albedo_color = Color(0.08, 0.07, 0.06)

	# Interaction collision - tall enough for raycast to hit from standing position
	# Player can still walk through the open front doorway
	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(3.0, 1.8, 2.5)
	collision.shape = box_shape
	collision.position.y = 0.9
	tent.add_child(collision)

	# Canvas panels (A-frame)
	var panel_mesh: BoxMesh = BoxMesh.new()
	panel_mesh.size = Vector3(3.0, 0.05, 2.0)

	# Left panel (slightly darker - shadow side)
	var panel_left: MeshInstance3D = MeshInstance3D.new()
	panel_left.mesh = panel_mesh
	panel_left.position = Vector3(-0.7, 1.2, 0)
	panel_left.rotation_degrees.z = 45
	panel_left.material_override = canvas_shadow_mat
	tent.add_child(panel_left)

	# Right panel (lighter - catching light)
	var panel_right: MeshInstance3D = MeshInstance3D.new()
	panel_right.mesh = panel_mesh
	panel_right.position = Vector3(0.7, 1.2, 0)
	panel_right.rotation_degrees.z = -45
	panel_right.material_override = canvas_light_mat
	tent.add_child(panel_right)

	# Canvas seam lines on panels
	var seam_mesh: BoxMesh = BoxMesh.new()
	seam_mesh.size = Vector3(2.9, 0.015, 0.03)
	for i: int in range(3):
		# Left panel seams
		var seam_l: MeshInstance3D = MeshInstance3D.new()
		seam_l.mesh = seam_mesh
		seam_l.position = Vector3(-0.7, 1.22, -0.5 + i * 0.5)
		seam_l.rotation_degrees.z = 45
		seam_l.material_override = canvas_mat
		tent.add_child(seam_l)
		# Right panel seams
		var seam_r: MeshInstance3D = MeshInstance3D.new()
		seam_r.mesh = seam_mesh
		seam_r.position = Vector3(0.7, 1.22, -0.5 + i * 0.5)
		seam_r.rotation_degrees.z = -45
		seam_r.material_override = canvas_mat
		tent.add_child(seam_r)

	# Back wall
	var back_mesh: BoxMesh = BoxMesh.new()
	back_mesh.size = Vector3(2.0, 1.8, 0.05)
	var back: MeshInstance3D = MeshInstance3D.new()
	back.mesh = back_mesh
	back.position = Vector3(0, 0.9, -0.95)
	back.material_override = canvas_mat
	tent.add_child(back)

	# Front opening flaps
	var flap_mesh: BoxMesh = BoxMesh.new()
	flap_mesh.size = Vector3(0.4, 1.6, 0.04)
	# Left flap (slightly open/angled)
	var flap_l: MeshInstance3D = MeshInstance3D.new()
	flap_l.mesh = flap_mesh
	flap_l.position = Vector3(-0.5, 0.85, 0.97)
	flap_l.rotation.y = -0.2
	flap_l.material_override = canvas_shadow_mat
	tent.add_child(flap_l)
	# Right flap
	var flap_r: MeshInstance3D = MeshInstance3D.new()
	flap_r.mesh = flap_mesh
	flap_r.position = Vector3(0.5, 0.85, 0.97)
	flap_r.rotation.y = 0.2
	flap_r.material_override = canvas_light_mat
	tent.add_child(flap_r)

	# Dark interior visible through opening
	var interior: MeshInstance3D = MeshInstance3D.new()
	var int_mesh: BoxMesh = BoxMesh.new()
	int_mesh.size = Vector3(0.8, 1.4, 0.02)
	interior.mesh = int_mesh
	interior.position = Vector3(0, 0.8, 0.90)
	interior.material_override = interior_mat
	tent.add_child(interior)

	# Ridge pole
	var ridge: MeshInstance3D = MeshInstance3D.new()
	var ridge_mesh: BoxMesh = BoxMesh.new()
	ridge_mesh.size = Vector3(0.08, 0.08, 2.3)
	ridge.mesh = ridge_mesh
	ridge.position = Vector3(0, 1.8, 0)
	ridge.material_override = wood_mat
	tent.add_child(ridge)

	# Ridge pole bark detail
	var ridge_bark: MeshInstance3D = MeshInstance3D.new()
	var rb_mesh: BoxMesh = BoxMesh.new()
	rb_mesh.size = Vector3(0.03, 0.085, 2.28)
	ridge_bark.mesh = rb_mesh
	ridge_bark.position = Vector3(0.02, 1.8, 0)
	ridge_bark.material_override = wood_dark_mat
	tent.add_child(ridge_bark)

	# Support poles at front (visible through opening)
	var front_pole_mesh: BoxMesh = BoxMesh.new()
	front_pole_mesh.size = Vector3(0.07, 1.8, 0.07)
	for fp_x: float in [-0.9, 0.9]:
		var fp: MeshInstance3D = MeshInstance3D.new()
		fp.mesh = front_pole_mesh
		fp.position = Vector3(fp_x, 0.9, 0.95)
		fp.material_override = wood_mat
		tent.add_child(fp)

	# Guy ropes (angled lines from ridge to ground)
	var guy_mesh: BoxMesh = BoxMesh.new()
	guy_mesh.size = Vector3(0.02, 1.2, 0.02)
	for side_x: float in [-1.8, 1.8]:
		var guy: MeshInstance3D = MeshInstance3D.new()
		guy.mesh = guy_mesh
		guy.position = Vector3(side_x * 0.6, 1.0, 0)
		guy.rotation.z = 0.6 if side_x < 0 else -0.6
		guy.material_override = rope_mat
		tent.add_child(guy)

	# Tent stakes
	var stake_mesh: BoxMesh = BoxMesh.new()
	stake_mesh.size = Vector3(0.04, 0.2, 0.04)
	for sx: float in [-1.6, 1.6]:
		var stake: MeshInstance3D = MeshInstance3D.new()
		stake.mesh = stake_mesh
		stake.position = Vector3(sx, 0.08, 0)
		stake.rotation.z = 0.3 if sx < 0 else -0.3
		stake.material_override = wood_dark_mat
		tent.add_child(stake)

	# Ground cloth visible at entrance
	var ground_mat: StandardMaterial3D = StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.48, 0.44, 0.36)
	var ground_cloth: MeshInstance3D = MeshInstance3D.new()
	var gc_mesh: BoxMesh = BoxMesh.new()
	gc_mesh.size = Vector3(1.6, 0.02, 1.8)
	ground_cloth.mesh = gc_mesh
	ground_cloth.position = Vector3(0, 0.01, 0)
	ground_cloth.material_override = ground_mat
	tent.add_child(ground_cloth)

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
	# Austrian A-frame cabin design
	# The roof extends from near ground level to a high peak
	# Front and back have stepped triangular walls (blocky style)
	var cabin: StaticBody3D = StaticBody3D.new()
	cabin.name = "LogCabin"
	cabin.set_script(load("res://scripts/campsite/structure_cabin.gd"))

	var log_mat: StandardMaterial3D = StandardMaterial3D.new()
	log_mat.albedo_color = Color(0.45, 0.30, 0.18)  # Dark brown logs

	var roof_mat: StandardMaterial3D = StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.30, 0.18, 0.10)  # Dark brown roof shingles

	var floor_mat: StandardMaterial3D = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.5, 0.38, 0.25)  # Lighter wood floor

	# A-frame dimensions
	var base_width: float = 6.0      # Width at base
	var depth: float = 6.0           # Length front to back
	var peak_height: float = 5.5     # Height at peak
	var wall_thick: float = 0.25
	var knee_wall_height: float = 0.8  # Short vertical wall at base
	var door_width: float = 1.4
	var door_height: float = 2.2

	# Calculate roof panel dimensions
	# Roof goes from knee wall top to peak
	var roof_rise: float = peak_height - knee_wall_height
	var roof_run: float = base_width / 2.0
	var roof_length: float = sqrt(roof_rise * roof_rise + roof_run * roof_run)
	var roof_angle: float = rad_to_deg(atan2(roof_rise, roof_run))

	# Floor
	var floor_mesh: MeshInstance3D = MeshInstance3D.new()
	var floor_box: BoxMesh = BoxMesh.new()
	floor_box.size = Vector3(base_width - 0.2, 0.1, depth - 0.2)
	floor_mesh.mesh = floor_box
	floor_mesh.position.y = 0.05
	floor_mesh.material_override = floor_mat
	cabin.add_child(floor_mesh)

	# Short knee walls on left and right (base of A-frame)
	var knee_mesh: BoxMesh = BoxMesh.new()
	knee_mesh.size = Vector3(wall_thick, knee_wall_height, depth)

	var left_knee: MeshInstance3D = MeshInstance3D.new()
	left_knee.mesh = knee_mesh
	left_knee.position = Vector3(-base_width / 2 + wall_thick / 2, knee_wall_height / 2, 0)
	left_knee.material_override = log_mat
	cabin.add_child(left_knee)

	var left_knee_col: CollisionShape3D = CollisionShape3D.new()
	left_knee_col.shape = BoxShape3D.new()
	(left_knee_col.shape as BoxShape3D).size = knee_mesh.size
	left_knee_col.position = left_knee.position
	cabin.add_child(left_knee_col)

	var right_knee: MeshInstance3D = MeshInstance3D.new()
	right_knee.mesh = knee_mesh
	right_knee.position = Vector3(base_width / 2 - wall_thick / 2, knee_wall_height / 2, 0)
	right_knee.material_override = log_mat
	cabin.add_child(right_knee)

	var right_knee_col: CollisionShape3D = CollisionShape3D.new()
	right_knee_col.shape = BoxShape3D.new()
	(right_knee_col.shape as BoxShape3D).size = knee_mesh.size
	right_knee_col.position = right_knee.position
	cabin.add_child(right_knee_col)

	# A-frame roof panels (the main visual element)
	# Shorten panels so corners don't extend past the peak, then add a ridge cap
	var roof_thickness: float = 0.2
	# Shorten the roof to stop before the peak (account for the corner extension)
	var corner_extension: float = roof_thickness / (2.0 * sin(deg_to_rad(roof_angle)))
	var shortened_roof_length: float = roof_length - corner_extension

	var roof_mesh: BoxMesh = BoxMesh.new()
	roof_mesh.size = Vector3(shortened_roof_length, roof_thickness, depth + 0.5)

	# Left roof panel - starts at knee wall, stops short of peak
	var roof_left: MeshInstance3D = MeshInstance3D.new()
	roof_left.mesh = roof_mesh
	var half_length: float = shortened_roof_length / 2.0
	var roof_center_x: float = -roof_run + half_length * cos(deg_to_rad(roof_angle))
	var roof_center_y: float = knee_wall_height + half_length * sin(deg_to_rad(roof_angle))
	roof_left.position = Vector3(roof_center_x, roof_center_y, 0)
	roof_left.rotation_degrees.z = roof_angle
	roof_left.material_override = roof_mat
	cabin.add_child(roof_left)

	# Right roof panel - mirror of left
	var roof_right: MeshInstance3D = MeshInstance3D.new()
	roof_right.mesh = roof_mesh
	roof_right.position = Vector3(-roof_center_x, roof_center_y, 0)
	roof_right.rotation_degrees.z = -roof_angle
	roof_right.material_override = roof_mat
	cabin.add_child(roof_right)

	# Ridge cap - a box at the peak to cover the gap and create a clean ridge line
	var ridge_cap: MeshInstance3D = MeshInstance3D.new()
	var ridge_mesh: BoxMesh = BoxMesh.new()
	var ridge_width: float = corner_extension * 2.5  # Wide enough to cover the gap
	ridge_mesh.size = Vector3(ridge_width, roof_thickness, depth + 0.5)
	ridge_cap.mesh = ridge_mesh
	ridge_cap.position = Vector3(0, peak_height + roof_thickness / 2, 0)
	ridge_cap.material_override = roof_mat
	cabin.add_child(ridge_cap)

	# Roof collision
	var roof_col_left: CollisionShape3D = CollisionShape3D.new()
	roof_col_left.shape = BoxShape3D.new()
	(roof_col_left.shape as BoxShape3D).size = Vector3(shortened_roof_length, 0.25, depth)
	roof_col_left.position = Vector3(roof_center_x, roof_center_y, 0)
	roof_col_left.rotation_degrees.z = roof_angle
	cabin.add_child(roof_col_left)

	var roof_col_right: CollisionShape3D = CollisionShape3D.new()
	roof_col_right.shape = BoxShape3D.new()
	(roof_col_right.shape as BoxShape3D).size = Vector3(shortened_roof_length, 0.25, depth)
	roof_col_right.position = Vector3(-roof_center_x, roof_center_y, 0)
	roof_col_right.rotation_degrees.z = -roof_angle
	cabin.add_child(roof_col_right)

	# Front wall - stepped triangle (blocky Minecraft style)
	# Build as stacked boxes that get narrower toward peak
	var step_height: float = 1.0
	var num_steps: int = int(peak_height / step_height)
	var front_z: float = depth / 2 - wall_thick / 2
	var back_z: float = -depth / 2 + wall_thick / 2

	for i: int in range(num_steps):
		var y_pos: float = i * step_height + step_height / 2
		# Calculate width at this height (linear taper)
		var height_ratio: float = float(i * step_height) / peak_height
		var width_at_height: float = base_width * (1.0 - height_ratio * 0.95)
		width_at_height = max(width_at_height, 0.5)  # Minimum width at top

		# Skip the doorway area in the bottom section of the front
		if i == 0 or i == 1:
			# Bottom two rows - create with doorway gap
			var side_width: float = (width_at_height - door_width) / 2
			if side_width > 0.2:
				# Left side of door
				var front_left: MeshInstance3D = MeshInstance3D.new()
				var fl_box: BoxMesh = BoxMesh.new()
				fl_box.size = Vector3(side_width, step_height, wall_thick)
				front_left.mesh = fl_box
				front_left.position = Vector3(-width_at_height / 2 + side_width / 2, y_pos, front_z)
				front_left.material_override = log_mat
				cabin.add_child(front_left)

				# Right side of door
				var front_right: MeshInstance3D = MeshInstance3D.new()
				var fr_box: BoxMesh = BoxMesh.new()
				fr_box.size = Vector3(side_width, step_height, wall_thick)
				front_right.mesh = fr_box
				front_right.position = Vector3(width_at_height / 2 - side_width / 2, y_pos, front_z)
				front_right.material_override = log_mat
				cabin.add_child(front_right)

			# Above door (row 1 only, partial)
			if i == 1:
				var above_height: float = step_height - (door_height - step_height)
				if above_height > 0:
					var above_door: MeshInstance3D = MeshInstance3D.new()
					var ad_box: BoxMesh = BoxMesh.new()
					ad_box.size = Vector3(door_width, above_height, wall_thick)
					above_door.mesh = ad_box
					above_door.position = Vector3(0, door_height + above_height / 2, front_z)
					above_door.material_override = log_mat
					cabin.add_child(above_door)
		else:
			# Full width row (above door)
			var front_row: MeshInstance3D = MeshInstance3D.new()
			var row_box: BoxMesh = BoxMesh.new()
			row_box.size = Vector3(width_at_height, step_height, wall_thick)
			front_row.mesh = row_box
			front_row.position = Vector3(0, y_pos, front_z)
			front_row.material_override = log_mat
			cabin.add_child(front_row)

		# Back wall - solid stepped triangle (no doorway)
		var back_row: MeshInstance3D = MeshInstance3D.new()
		var back_box: BoxMesh = BoxMesh.new()
		back_box.size = Vector3(width_at_height, step_height, wall_thick)
		back_row.mesh = back_box
		back_row.position = Vector3(0, y_pos, back_z)
		back_row.material_override = log_mat
		cabin.add_child(back_row)

	# Front wall collisions - split to leave doorway gap
	var front_side_col_width: float = (base_width - door_width) / 2.0

	# Left side of doorway
	var front_col_left: CollisionShape3D = CollisionShape3D.new()
	front_col_left.shape = BoxShape3D.new()
	(front_col_left.shape as BoxShape3D).size = Vector3(front_side_col_width, peak_height, wall_thick)
	front_col_left.position = Vector3(-base_width / 2 + front_side_col_width / 2, peak_height / 2, front_z)
	cabin.add_child(front_col_left)

	# Right side of doorway
	var front_col_right: CollisionShape3D = CollisionShape3D.new()
	front_col_right.shape = BoxShape3D.new()
	(front_col_right.shape as BoxShape3D).size = Vector3(front_side_col_width, peak_height, wall_thick)
	front_col_right.position = Vector3(base_width / 2 - front_side_col_width / 2, peak_height / 2, front_z)
	cabin.add_child(front_col_right)

	# Above doorway
	var front_col_above: CollisionShape3D = CollisionShape3D.new()
	front_col_above.shape = BoxShape3D.new()
	var above_door_height: float = peak_height - door_height
	(front_col_above.shape as BoxShape3D).size = Vector3(door_width, above_door_height, wall_thick)
	front_col_above.position = Vector3(0, door_height + above_door_height / 2, front_z)
	cabin.add_child(front_col_above)

	# Back wall collision (solid - no door)
	var back_col: CollisionShape3D = CollisionShape3D.new()
	back_col.shape = BoxShape3D.new()
	(back_col.shape as BoxShape3D).size = Vector3(base_width, peak_height, wall_thick)
	back_col.position = Vector3(0, peak_height / 2, back_z)
	cabin.add_child(back_col)

	# Interior: Bed (back right corner)
	var bed: StaticBody3D = _create_cabin_bed()
	bed.position = Vector3(base_width / 2 - 1.5, 0, -depth / 2 + 1.5)
	cabin.add_child(bed)

	# Interior: Kitchen (back left corner)
	var kitchen: StaticBody3D = _create_cabin_kitchen()
	kitchen.position = Vector3(-base_width / 2 + 1.5, 0, -depth / 2 + 1.2)
	cabin.add_child(kitchen)

	# Protection area (covers entire cabin interior)
	var area: Area3D = Area3D.new()
	area.name = "ProtectionArea"
	var area_collision: CollisionShape3D = CollisionShape3D.new()
	var box_area: BoxShape3D = BoxShape3D.new()
	box_area.size = Vector3(base_width, peak_height, depth)
	area_collision.shape = box_area
	area_collision.position.y = peak_height / 2
	area.add_child(area_collision)
	area.body_entered.connect(cabin._on_protection_area_body_entered)
	area.body_exited.connect(cabin._on_protection_area_body_exited)
	cabin.add_child(area)

	return cabin


func _create_cabin_bed() -> StaticBody3D:
	var bed: StaticBody3D = StaticBody3D.new()
	bed.name = "CabinBed"
	bed.set_script(load("res://scripts/campsite/cabin_bed.gd"))

	# Materials
	var frame_mat: StandardMaterial3D = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.45, 0.32, 0.20)
	frame_mat.roughness = 0.88

	var frame_dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	frame_dark_mat.albedo_color = Color(0.36, 0.24, 0.14)
	frame_dark_mat.roughness = 0.90

	var frame_light_mat: StandardMaterial3D = StandardMaterial3D.new()
	frame_light_mat.albedo_color = Color(0.52, 0.38, 0.24)

	var blanket_mat: StandardMaterial3D = StandardMaterial3D.new()
	blanket_mat.albedo_color = Color(0.28, 0.42, 0.58)

	var blanket_dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	blanket_dark_mat.albedo_color = Color(0.22, 0.35, 0.50)

	var blanket_fold_mat: StandardMaterial3D = StandardMaterial3D.new()
	blanket_fold_mat.albedo_color = Color(0.32, 0.48, 0.62)

	var sheet_mat: StandardMaterial3D = StandardMaterial3D.new()
	sheet_mat.albedo_color = Color(0.88, 0.85, 0.78)

	var pillow_mat: StandardMaterial3D = StandardMaterial3D.new()
	pillow_mat.albedo_color = Color(0.92, 0.90, 0.84)

	var pillow_shadow_mat: StandardMaterial3D = StandardMaterial3D.new()
	pillow_shadow_mat.albedo_color = Color(0.82, 0.80, 0.74)

	# Bed frame base
	var frame: MeshInstance3D = MeshInstance3D.new()
	var frame_mesh: BoxMesh = BoxMesh.new()
	frame_mesh.size = Vector3(1.8, 0.25, 1.0)
	frame.mesh = frame_mesh
	frame.position.y = 0.125
	frame.material_override = frame_mat
	bed.add_child(frame)

	# Headboard (tall back panel)
	var headboard: MeshInstance3D = MeshInstance3D.new()
	var hb_mesh: BoxMesh = BoxMesh.new()
	hb_mesh.size = Vector3(0.08, 0.6, 1.0)
	headboard.mesh = hb_mesh
	headboard.position = Vector3(-0.86, 0.42, 0)
	headboard.material_override = frame_dark_mat
	bed.add_child(headboard)

	# Headboard cap (decorative top)
	var hb_cap: MeshInstance3D = MeshInstance3D.new()
	var hbc_mesh: BoxMesh = BoxMesh.new()
	hbc_mesh.size = Vector3(0.10, 0.04, 1.04)
	hb_cap.mesh = hbc_mesh
	hb_cap.position = Vector3(-0.86, 0.74, 0)
	hb_cap.material_override = frame_light_mat
	bed.add_child(hb_cap)

	# Headboard vertical slats
	for i: int in range(4):
		var slat: MeshInstance3D = MeshInstance3D.new()
		var sl_mesh: BoxMesh = BoxMesh.new()
		sl_mesh.size = Vector3(0.085, 0.58, 0.06)
		slat.mesh = sl_mesh
		slat.position = Vector3(-0.86, 0.42, -0.32 + i * 0.22)
		slat.material_override = frame_light_mat
		bed.add_child(slat)

	# Footboard (shorter)
	var footboard: MeshInstance3D = MeshInstance3D.new()
	var fb_mesh: BoxMesh = BoxMesh.new()
	fb_mesh.size = Vector3(0.08, 0.38, 1.0)
	footboard.mesh = fb_mesh
	footboard.position = Vector3(0.86, 0.32, 0)
	footboard.material_override = frame_dark_mat
	bed.add_child(footboard)

	# Side rails
	var rail_mesh: BoxMesh = BoxMesh.new()
	rail_mesh.size = Vector3(1.7, 0.06, 0.06)
	for rz: float in [-0.47, 0.47]:
		var rail: MeshInstance3D = MeshInstance3D.new()
		rail.mesh = rail_mesh
		rail.position = Vector3(0, 0.28, rz)
		rail.material_override = frame_dark_mat
		bed.add_child(rail)

	# Sheet layer (white, visible at head)
	var sheet: MeshInstance3D = MeshInstance3D.new()
	var sh_mesh: BoxMesh = BoxMesh.new()
	sh_mesh.size = Vector3(1.6, 0.04, 0.88)
	sheet.mesh = sh_mesh
	sheet.position = Vector3(0, 0.3, 0)
	sheet.material_override = sheet_mat
	bed.add_child(sheet)

	# Blanket/bedspread (main covering)
	var blanket: MeshInstance3D = MeshInstance3D.new()
	var blanket_mesh: BoxMesh = BoxMesh.new()
	blanket_mesh.size = Vector3(1.2, 0.12, 0.9)
	blanket.mesh = blanket_mesh
	blanket.position = Vector3(0.15, 0.36, 0)
	blanket.material_override = blanket_mat
	bed.add_child(blanket)

	# Blanket fold at top (turned-down edge)
	var fold: MeshInstance3D = MeshInstance3D.new()
	var fold_mesh: BoxMesh = BoxMesh.new()
	fold_mesh.size = Vector3(0.15, 0.14, 0.88)
	fold.mesh = fold_mesh
	fold.position = Vector3(-0.38, 0.37, 0)
	fold.material_override = blanket_fold_mat
	bed.add_child(fold)

	# Blanket wrinkle lines
	for i: int in range(3):
		var wrinkle: MeshInstance3D = MeshInstance3D.new()
		var wr_mesh: BoxMesh = BoxMesh.new()
		wr_mesh.size = Vector3(1.1, 0.015, 0.04)
		wrinkle.mesh = wr_mesh
		wrinkle.position = Vector3(0.15, 0.425, -0.2 + i * 0.2)
		wrinkle.material_override = blanket_dark_mat
		bed.add_child(wrinkle)

	# Pillow (with indent)
	var pillow: MeshInstance3D = MeshInstance3D.new()
	var pillow_mesh: BoxMesh = BoxMesh.new()
	pillow_mesh.size = Vector3(0.45, 0.14, 0.38)
	pillow.mesh = pillow_mesh
	pillow.position = Vector3(-0.58, 0.44, 0)
	pillow.material_override = pillow_mat
	bed.add_child(pillow)

	# Pillow shadow/indent
	var indent: MeshInstance3D = MeshInstance3D.new()
	var ind_mesh: BoxMesh = BoxMesh.new()
	ind_mesh.size = Vector3(0.25, 0.01, 0.2)
	indent.mesh = ind_mesh
	indent.position = Vector3(-0.58, 0.515, 0)
	indent.material_override = pillow_shadow_mat
	bed.add_child(indent)

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

	# Materials
	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.50, 0.38, 0.25)
	wood_mat.roughness = 0.88

	var wood_dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_dark_mat.albedo_color = Color(0.38, 0.26, 0.15)
	wood_dark_mat.roughness = 0.90

	var stone_mat: StandardMaterial3D = StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.50, 0.50, 0.52)
	stone_mat.roughness = 0.92

	var stone_dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	stone_dark_mat.albedo_color = Color(0.40, 0.40, 0.42)
	stone_dark_mat.roughness = 0.95

	var metal_mat: StandardMaterial3D = StandardMaterial3D.new()
	metal_mat.albedo_color = Color(0.30, 0.28, 0.26)
	metal_mat.metallic = 0.6
	metal_mat.roughness = 0.5

	var ember_mat: StandardMaterial3D = StandardMaterial3D.new()
	ember_mat.albedo_color = Color(0.8, 0.2, 0.0)
	ember_mat.emission_enabled = true
	ember_mat.emission = Color(0.7, 0.15, 0.0)
	ember_mat.emission_energy_multiplier = 1.5

	var fire_mat: StandardMaterial3D = StandardMaterial3D.new()
	fire_mat.albedo_color = Color(1.0, 0.5, 0.1)
	fire_mat.emission_enabled = true
	fire_mat.emission = Color(1.0, 0.4, 0.0)
	fire_mat.emission_energy_multiplier = 2.0

	var fire_tip_mat: StandardMaterial3D = StandardMaterial3D.new()
	fire_tip_mat.albedo_color = Color(1.0, 0.8, 0.3)
	fire_tip_mat.emission_enabled = true
	fire_tip_mat.emission = Color(1.0, 0.75, 0.2)
	fire_tip_mat.emission_energy_multiplier = 2.5

	# Counter/cabinet base
	var counter: MeshInstance3D = MeshInstance3D.new()
	var counter_mesh: BoxMesh = BoxMesh.new()
	counter_mesh.size = Vector3(1.5, 0.8, 0.8)
	counter.mesh = counter_mesh
	counter.position.y = 0.4
	counter.material_override = wood_mat
	kitchen.add_child(counter)

	# Cabinet door lines (panel detail)
	for i: int in range(3):
		var door_line: MeshInstance3D = MeshInstance3D.new()
		var dl_mesh: BoxMesh = BoxMesh.new()
		dl_mesh.size = Vector3(0.015, 0.7, 0.81)
		door_line.mesh = dl_mesh
		door_line.position = Vector3(-0.5 + i * 0.5, 0.4, 0)
		door_line.material_override = wood_dark_mat
		kitchen.add_child(door_line)

	# Cabinet handles
	for i: int in range(2):
		var handle: MeshInstance3D = MeshInstance3D.new()
		var h_mesh: BoxMesh = BoxMesh.new()
		h_mesh.size = Vector3(0.03, 0.08, 0.03)
		handle.mesh = h_mesh
		handle.position = Vector3(-0.22 + i * 0.5, 0.45, 0.41)
		handle.material_override = metal_mat
		kitchen.add_child(handle)

	# Stone cooking surface with individual stone blocks
	var surface: MeshInstance3D = MeshInstance3D.new()
	var surface_mesh: BoxMesh = BoxMesh.new()
	surface_mesh.size = Vector3(1.5, 0.1, 0.8)
	surface.mesh = surface_mesh
	surface.position.y = 0.85
	surface.material_override = stone_mat
	kitchen.add_child(surface)

	# Stone block lines on surface
	for i: int in range(4):
		var s_line: MeshInstance3D = MeshInstance3D.new()
		var sl_mesh: BoxMesh = BoxMesh.new()
		sl_mesh.size = Vector3(0.02, 0.101, 0.78)
		s_line.mesh = sl_mesh
		s_line.position = Vector3(-0.55 + i * 0.38, 0.85, 0)
		s_line.material_override = stone_dark_mat
		kitchen.add_child(s_line)

	# Stone hearth/firebox (raised stone area for fire)
	var hearth: MeshInstance3D = MeshInstance3D.new()
	var hearth_mesh: BoxMesh = BoxMesh.new()
	hearth_mesh.size = Vector3(0.5, 0.06, 0.5)
	hearth.mesh = hearth_mesh
	hearth.position = Vector3(0.4, 0.93, 0)
	hearth.material_override = stone_dark_mat
	kitchen.add_child(hearth)

	# Layered cooking fire
	# Embers
	var fire_ember: MeshInstance3D = MeshInstance3D.new()
	var fe_mesh: BoxMesh = BoxMesh.new()
	fe_mesh.size = Vector3(0.28, 0.04, 0.28)
	fire_ember.mesh = fe_mesh
	fire_ember.position = Vector3(0.4, 0.97, 0)
	fire_ember.material_override = ember_mat
	kitchen.add_child(fire_ember)

	# Main flame
	var fire: MeshInstance3D = MeshInstance3D.new()
	var fire_mesh: BoxMesh = BoxMesh.new()
	fire_mesh.size = Vector3(0.2, 0.18, 0.2)
	fire.mesh = fire_mesh
	fire.position = Vector3(0.4, 1.06, 0)
	fire.material_override = fire_mat
	kitchen.add_child(fire)

	# Flame tip
	var fire_top: MeshInstance3D = MeshInstance3D.new()
	var ft_mesh: BoxMesh = BoxMesh.new()
	ft_mesh.size = Vector3(0.1, 0.12, 0.1)
	fire_top.mesh = ft_mesh
	fire_top.position = Vector3(0.4, 1.18, 0)
	fire_top.material_override = fire_tip_mat
	kitchen.add_child(fire_top)

	# Cooking pot on the fire
	var pot_mat: StandardMaterial3D = StandardMaterial3D.new()
	pot_mat.albedo_color = Color(0.18, 0.18, 0.20)
	pot_mat.metallic = 0.5
	pot_mat.roughness = 0.6
	var pot: MeshInstance3D = MeshInstance3D.new()
	var pot_mesh: BoxMesh = BoxMesh.new()
	pot_mesh.size = Vector3(0.22, 0.18, 0.22)
	pot.mesh = pot_mesh
	pot.position = Vector3(0.4, 1.05, 0)
	pot.material_override = pot_mat
	kitchen.add_child(pot)

	# Pot handle (arching over)
	var pot_handle: MeshInstance3D = MeshInstance3D.new()
	var ph_mesh: BoxMesh = BoxMesh.new()
	ph_mesh.size = Vector3(0.18, 0.02, 0.02)
	pot_handle.mesh = ph_mesh
	pot_handle.position = Vector3(0.4, 1.18, 0)
	pot_handle.material_override = metal_mat
	kitchen.add_child(pot_handle)

	# Small shelf above counter
	var shelf: MeshInstance3D = MeshInstance3D.new()
	var sh_mesh: BoxMesh = BoxMesh.new()
	sh_mesh.size = Vector3(0.8, 0.04, 0.25)
	shelf.mesh = sh_mesh
	shelf.position = Vector3(-0.3, 1.3, -0.28)
	shelf.material_override = wood_dark_mat
	kitchen.add_child(shelf)

	# Shelf brackets
	var bracket_mesh: BoxMesh = BoxMesh.new()
	bracket_mesh.size = Vector3(0.04, 0.15, 0.04)
	for bx: float in [-0.6, 0.0]:
		var bracket: MeshInstance3D = MeshInstance3D.new()
		bracket.mesh = bracket_mesh
		bracket.position = Vector3(bx, 1.22, -0.28)
		bracket.material_override = wood_dark_mat
		kitchen.add_child(bracket)

	# Items on shelf (small jars/bowls)
	var jar_mat: StandardMaterial3D = StandardMaterial3D.new()
	jar_mat.albedo_color = Color(0.55, 0.45, 0.35)
	var jar: MeshInstance3D = MeshInstance3D.new()
	var j_mesh: BoxMesh = BoxMesh.new()
	j_mesh.size = Vector3(0.08, 0.12, 0.08)
	jar.mesh = j_mesh
	jar.position = Vector3(-0.5, 1.38, -0.28)
	jar.material_override = jar_mat
	kitchen.add_child(jar)

	var bowl_mat: StandardMaterial3D = StandardMaterial3D.new()
	bowl_mat.albedo_color = Color(0.50, 0.42, 0.30)
	var bowl: MeshInstance3D = MeshInstance3D.new()
	var b_mesh: BoxMesh = BoxMesh.new()
	b_mesh.size = Vector3(0.12, 0.06, 0.12)
	bowl.mesh = b_mesh
	bowl.position = Vector3(-0.2, 1.35, -0.28)
	bowl.material_override = bowl_mat
	kitchen.add_child(bowl)

	# Knife on counter surface
	var knife_blade: MeshInstance3D = MeshInstance3D.new()
	var kb_mesh: BoxMesh = BoxMesh.new()
	kb_mesh.size = Vector3(0.12, 0.01, 0.025)
	knife_blade.mesh = kb_mesh
	knife_blade.position = Vector3(-0.3, 0.91, 0.15)
	knife_blade.rotation.y = 0.4
	knife_blade.material_override = metal_mat
	kitchen.add_child(knife_blade)

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


func _create_snare_trap() -> StaticBody3D:
	var trap: StaticBody3D = StaticBody3D.new()
	trap.name = "SnareTrap"
	trap.set_script(load("res://scripts/campsite/structure_snare_trap.gd"))

	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.5, 0.35, 0.2)

	var rope_mat: StandardMaterial3D = StandardMaterial3D.new()
	rope_mat.albedo_color = Color(0.55, 0.45, 0.3)

	# Collision
	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(0.8, 0.5, 0.8)
	collision.shape = box_shape
	collision.position.y = 0.25
	trap.add_child(collision)

	# Base stakes (forked sticks)
	var stake_mesh: BoxMesh = BoxMesh.new()
	stake_mesh.size = Vector3(0.08, 0.4, 0.08)

	var stake1: MeshInstance3D = MeshInstance3D.new()
	stake1.mesh = stake_mesh
	stake1.position = Vector3(-0.25, 0.2, -0.2)
	stake1.rotation_degrees.z = -10
	stake1.material_override = wood_mat
	trap.add_child(stake1)

	var stake2: MeshInstance3D = MeshInstance3D.new()
	stake2.mesh = stake_mesh
	stake2.position = Vector3(0.25, 0.2, -0.2)
	stake2.rotation_degrees.z = 10
	trap.add_child(stake2)
	stake2.material_override = wood_mat

	# Crossbar
	var crossbar: MeshInstance3D = MeshInstance3D.new()
	var crossbar_mesh: BoxMesh = BoxMesh.new()
	crossbar_mesh.size = Vector3(0.6, 0.06, 0.06)
	crossbar.mesh = crossbar_mesh
	crossbar.position = Vector3(0, 0.38, -0.2)
	crossbar.material_override = wood_mat
	trap.add_child(crossbar)

	# Snare loop - open state (visible when empty or baited)
	var loop_open: MeshInstance3D = MeshInstance3D.new()
	loop_open.name = "SnareLoopOpen"
	var loop_mesh: BoxMesh = BoxMesh.new()
	loop_mesh.size = Vector3(0.4, 0.03, 0.4)
	loop_open.mesh = loop_mesh
	loop_open.position = Vector3(0, 0.02, 0.1)
	loop_open.material_override = rope_mat
	trap.add_child(loop_open)

	# Snare loop - closed/tightened state (visible when caught)
	var loop_closed: MeshInstance3D = MeshInstance3D.new()
	loop_closed.name = "SnareLoopClosed"
	var loop_closed_mesh: BoxMesh = BoxMesh.new()
	loop_closed_mesh.size = Vector3(0.15, 0.03, 0.15)
	loop_closed.mesh = loop_closed_mesh
	loop_closed.position = Vector3(0, 0.15, 0.1)
	loop_closed.material_override = rope_mat
	loop_closed.visible = false
	trap.add_child(loop_closed)

	# Trigger stick - upright (visible when not sprung)
	var trigger_upright: MeshInstance3D = MeshInstance3D.new()
	trigger_upright.name = "TriggerUpright"
	var trigger_mesh: BoxMesh = BoxMesh.new()
	trigger_mesh.size = Vector3(0.04, 0.2, 0.04)
	trigger_upright.mesh = trigger_mesh
	trigger_upright.position = Vector3(0, 0.1, 0.1)
	trigger_upright.material_override = wood_mat
	trap.add_child(trigger_upright)

	# Trigger stick - fallen (visible when sprung/caught)
	var trigger_fallen: MeshInstance3D = MeshInstance3D.new()
	trigger_fallen.name = "TriggerFallen"
	var trigger_fallen_mesh: BoxMesh = BoxMesh.new()
	trigger_fallen_mesh.size = Vector3(0.04, 0.2, 0.04)
	trigger_fallen.mesh = trigger_fallen_mesh
	trigger_fallen.position = Vector3(0, 0.03, 0.2)
	trigger_fallen.rotation_degrees.x = -80
	trigger_fallen.material_override = wood_mat
	trigger_fallen.visible = false
	trap.add_child(trigger_fallen)

	# === BAIT VISUALS (initially hidden) ===

	# Berry bait
	var berry_mat: StandardMaterial3D = StandardMaterial3D.new()
	berry_mat.albedo_color = Color(0.8, 0.2, 0.3)  # Red berry color

	var bait_berry: MeshInstance3D = MeshInstance3D.new()
	bait_berry.name = "BaitBerry"
	var berry_mesh: SphereMesh = SphereMesh.new()
	berry_mesh.radius = 0.06
	berry_mesh.height = 0.12
	bait_berry.mesh = berry_mesh
	bait_berry.position = Vector3(0, 0.08, 0.1)
	bait_berry.material_override = berry_mat
	bait_berry.visible = false
	trap.add_child(bait_berry)

	# Mushroom bait
	var mushroom_cap_mat: StandardMaterial3D = StandardMaterial3D.new()
	mushroom_cap_mat.albedo_color = Color(0.7, 0.5, 0.3)  # Brown cap
	var mushroom_stem_mat: StandardMaterial3D = StandardMaterial3D.new()
	mushroom_stem_mat.albedo_color = Color(0.9, 0.85, 0.75)  # Light stem

	var bait_mushroom: Node3D = Node3D.new()
	bait_mushroom.name = "BaitMushroom"
	bait_mushroom.position = Vector3(0, 0, 0.1)
	bait_mushroom.visible = false

	var mushroom_stem: MeshInstance3D = MeshInstance3D.new()
	var stem_mesh: CylinderMesh = CylinderMesh.new()
	stem_mesh.top_radius = 0.02
	stem_mesh.bottom_radius = 0.025
	stem_mesh.height = 0.06
	mushroom_stem.mesh = stem_mesh
	mushroom_stem.position = Vector3(0, 0.03, 0)
	mushroom_stem.material_override = mushroom_stem_mat
	bait_mushroom.add_child(mushroom_stem)

	var mushroom_cap: MeshInstance3D = MeshInstance3D.new()
	var cap_mesh: CylinderMesh = CylinderMesh.new()
	cap_mesh.top_radius = 0.01
	cap_mesh.bottom_radius = 0.05
	cap_mesh.height = 0.04
	mushroom_cap.mesh = cap_mesh
	mushroom_cap.position = Vector3(0, 0.08, 0)
	mushroom_cap.material_override = mushroom_cap_mat
	bait_mushroom.add_child(mushroom_cap)

	trap.add_child(bait_mushroom)

	# Herb bait
	var herb_mat: StandardMaterial3D = StandardMaterial3D.new()
	herb_mat.albedo_color = Color(0.3, 0.6, 0.25)  # Green herb color

	var bait_herb: MeshInstance3D = MeshInstance3D.new()
	bait_herb.name = "BaitHerb"
	var herb_mesh: BoxMesh = BoxMesh.new()
	herb_mesh.size = Vector3(0.08, 0.04, 0.06)
	bait_herb.mesh = herb_mesh
	bait_herb.position = Vector3(0, 0.05, 0.1)
	bait_herb.material_override = herb_mat
	bait_herb.visible = false
	trap.add_child(bait_herb)

	# === CAUGHT ANIMAL VISUALS (initially hidden) ===

	# Rabbit (simple body shape)
	var rabbit_mat: StandardMaterial3D = StandardMaterial3D.new()
	rabbit_mat.albedo_color = Color(0.6, 0.5, 0.4)  # Brown/grey fur

	var caught_rabbit: Node3D = Node3D.new()
	caught_rabbit.name = "CaughtRabbit"
	caught_rabbit.position = Vector3(0, 0.1, 0.1)
	caught_rabbit.visible = false

	# Rabbit body
	var rabbit_body: MeshInstance3D = MeshInstance3D.new()
	var body_mesh: SphereMesh = SphereMesh.new()
	body_mesh.radius = 0.1
	body_mesh.height = 0.15
	rabbit_body.mesh = body_mesh
	rabbit_body.rotation_degrees.x = 90
	rabbit_body.material_override = rabbit_mat
	caught_rabbit.add_child(rabbit_body)

	# Rabbit head
	var rabbit_head: MeshInstance3D = MeshInstance3D.new()
	var head_mesh: SphereMesh = SphereMesh.new()
	head_mesh.radius = 0.06
	head_mesh.height = 0.1
	rabbit_head.mesh = head_mesh
	rabbit_head.position = Vector3(0, 0.02, 0.12)
	rabbit_head.material_override = rabbit_mat
	caught_rabbit.add_child(rabbit_head)

	# Rabbit ears
	var ear_mesh: BoxMesh = BoxMesh.new()
	ear_mesh.size = Vector3(0.02, 0.08, 0.015)

	var rabbit_ear1: MeshInstance3D = MeshInstance3D.new()
	rabbit_ear1.mesh = ear_mesh
	rabbit_ear1.position = Vector3(-0.025, 0.08, 0.12)
	rabbit_ear1.rotation_degrees.z = 10
	rabbit_ear1.material_override = rabbit_mat
	caught_rabbit.add_child(rabbit_ear1)

	var rabbit_ear2: MeshInstance3D = MeshInstance3D.new()
	rabbit_ear2.mesh = ear_mesh
	rabbit_ear2.position = Vector3(0.025, 0.08, 0.12)
	rabbit_ear2.rotation_degrees.z = -10
	rabbit_ear2.material_override = rabbit_mat
	caught_rabbit.add_child(rabbit_ear2)

	trap.add_child(caught_rabbit)

	# Bird (simple shape with wings)
	var bird_body_mat: StandardMaterial3D = StandardMaterial3D.new()
	bird_body_mat.albedo_color = Color(0.45, 0.35, 0.3)  # Brown bird
	var bird_wing_mat: StandardMaterial3D = StandardMaterial3D.new()
	bird_wing_mat.albedo_color = Color(0.35, 0.28, 0.22)  # Darker wings

	var caught_bird: Node3D = Node3D.new()
	caught_bird.name = "CaughtBird"
	caught_bird.position = Vector3(0, 0.08, 0.1)
	caught_bird.visible = false

	# Bird body
	var bird_body: MeshInstance3D = MeshInstance3D.new()
	var bird_body_mesh: SphereMesh = SphereMesh.new()
	bird_body_mesh.radius = 0.07
	bird_body_mesh.height = 0.12
	bird_body.mesh = bird_body_mesh
	bird_body.rotation_degrees.x = 70
	bird_body.material_override = bird_body_mat
	caught_bird.add_child(bird_body)

	# Bird head
	var bird_head: MeshInstance3D = MeshInstance3D.new()
	var bird_head_mesh: SphereMesh = SphereMesh.new()
	bird_head_mesh.radius = 0.04
	bird_head_mesh.height = 0.06
	bird_head.mesh = bird_head_mesh
	bird_head.position = Vector3(0, 0.04, 0.08)
	bird_head.material_override = bird_body_mat
	caught_bird.add_child(bird_head)

	# Bird wings (folded, lying on ground)
	var wing_mesh: BoxMesh = BoxMesh.new()
	wing_mesh.size = Vector3(0.12, 0.01, 0.08)

	var bird_wing1: MeshInstance3D = MeshInstance3D.new()
	bird_wing1.mesh = wing_mesh
	bird_wing1.position = Vector3(-0.08, -0.02, 0)
	bird_wing1.rotation_degrees.z = 20
	bird_wing1.material_override = bird_wing_mat
	caught_bird.add_child(bird_wing1)

	var bird_wing2: MeshInstance3D = MeshInstance3D.new()
	bird_wing2.mesh = wing_mesh
	bird_wing2.position = Vector3(0.08, -0.02, 0)
	bird_wing2.rotation_degrees.z = -20
	bird_wing2.material_override = bird_wing_mat
	caught_bird.add_child(bird_wing2)

	# Scattered feathers (for visual interest)
	var feather_mat: StandardMaterial3D = StandardMaterial3D.new()
	feather_mat.albedo_color = Color(0.5, 0.4, 0.35)

	var feather_mesh: BoxMesh = BoxMesh.new()
	feather_mesh.size = Vector3(0.04, 0.005, 0.015)

	for i: int in range(3):
		var feather: MeshInstance3D = MeshInstance3D.new()
		feather.mesh = feather_mesh
		feather.position = Vector3(randf_range(-0.2, 0.2), 0.01, randf_range(-0.1, 0.2))
		feather.rotation_degrees.y = randf_range(0, 360)
		feather.material_override = feather_mat
		caught_bird.add_child(feather)

	trap.add_child(caught_bird)

	return trap


func _create_smithing_station() -> StaticBody3D:
	var station: StaticBody3D = StaticBody3D.new()
	station.name = "SmithingStation"
	station.set_script(load("res://scripts/campsite/structure_smithing_station.gd"))

	var stone_mat: StandardMaterial3D = StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.45, 0.45, 0.48)

	var dark_stone_mat: StandardMaterial3D = StandardMaterial3D.new()
	dark_stone_mat.albedo_color = Color(0.3, 0.3, 0.32)

	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.5, 0.35, 0.2)

	var coal_mat: StandardMaterial3D = StandardMaterial3D.new()
	coal_mat.albedo_color = Color(0.15, 0.15, 0.15)

	var fire_mat: StandardMaterial3D = StandardMaterial3D.new()
	fire_mat.albedo_color = Color(1.0, 0.5, 0.1)
	fire_mat.emission_enabled = true
	fire_mat.emission = Color(1.0, 0.4, 0.0)
	fire_mat.emission_energy_multiplier = 1.5

	# Collision
	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(1.8, 1.0, 1.2)
	collision.shape = box_shape
	collision.position.y = 0.5
	station.add_child(collision)

	# Stone forge base
	var base: MeshInstance3D = MeshInstance3D.new()
	var base_mesh: BoxMesh = BoxMesh.new()
	base_mesh.size = Vector3(1.2, 0.8, 1.0)
	base.mesh = base_mesh
	base.position = Vector3(0, 0.4, 0)
	base.material_override = stone_mat
	station.add_child(base)

	# Forge pit (darker, recessed area)
	var pit: MeshInstance3D = MeshInstance3D.new()
	var pit_mesh: BoxMesh = BoxMesh.new()
	pit_mesh.size = Vector3(0.6, 0.1, 0.6)
	pit.mesh = pit_mesh
	pit.position = Vector3(0, 0.85, 0)
	pit.material_override = dark_stone_mat
	station.add_child(pit)

	# Coal bed
	var coal: MeshInstance3D = MeshInstance3D.new()
	var coal_mesh: BoxMesh = BoxMesh.new()
	coal_mesh.size = Vector3(0.5, 0.08, 0.5)
	coal.mesh = coal_mesh
	coal.position = Vector3(0, 0.84, 0)
	coal.material_override = coal_mat
	station.add_child(coal)

	# Fire glow (small)
	var fire: MeshInstance3D = MeshInstance3D.new()
	var fire_mesh: BoxMesh = BoxMesh.new()
	fire_mesh.size = Vector3(0.3, 0.15, 0.3)
	fire.mesh = fire_mesh
	fire.position = Vector3(0, 0.95, 0)
	fire.material_override = fire_mat
	station.add_child(fire)

	# Bellows (to the side)
	var bellows: MeshInstance3D = MeshInstance3D.new()
	var bellows_mesh: BoxMesh = BoxMesh.new()
	bellows_mesh.size = Vector3(0.35, 0.25, 0.5)
	bellows.mesh = bellows_mesh
	bellows.position = Vector3(0.6, 0.6, 0.3)
	bellows.material_override = wood_mat
	station.add_child(bellows)

	# Anvil (separate block)
	var anvil: MeshInstance3D = MeshInstance3D.new()
	var anvil_mesh: BoxMesh = BoxMesh.new()
	anvil_mesh.size = Vector3(0.5, 0.4, 0.3)
	anvil.mesh = anvil_mesh
	anvil.position = Vector3(-0.9, 0.2, 0)
	anvil.material_override = dark_stone_mat
	station.add_child(anvil)

	# Light from forge
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = Color(1.0, 0.5, 0.2)
	light.light_energy = 2.0
	light.omni_range = 5.0
	light.position = Vector3(0, 1.0, 0)
	station.add_child(light)

	return station


func _create_smoker() -> StaticBody3D:
	var smoker: StaticBody3D = StaticBody3D.new()
	smoker.name = "Smoker"
	smoker.set_script(load("res://scripts/campsite/structure_smoker.gd"))

	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.45, 0.32, 0.2)

	var dark_wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	dark_wood_mat.albedo_color = Color(0.3, 0.22, 0.15)

	var stone_mat: StandardMaterial3D = StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.4, 0.4, 0.42)

	# Collision
	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(1.0, 1.5, 1.0)
	collision.shape = box_shape
	collision.position.y = 0.75
	smoker.add_child(collision)

	# Stone fire pit base
	var base: MeshInstance3D = MeshInstance3D.new()
	var base_mesh: BoxMesh = BoxMesh.new()
	base_mesh.size = Vector3(0.8, 0.3, 0.8)
	base.mesh = base_mesh
	base.position = Vector3(0, 0.15, 0)
	base.material_override = stone_mat
	smoker.add_child(base)

	# Wooden frame (box structure around the smoking area)
	var frame_post_mesh: BoxMesh = BoxMesh.new()
	frame_post_mesh.size = Vector3(0.1, 1.2, 0.1)

	var corners: Array[Vector3] = [
		Vector3(-0.4, 0.9, -0.4),
		Vector3(0.4, 0.9, -0.4),
		Vector3(-0.4, 0.9, 0.4),
		Vector3(0.4, 0.9, 0.4)
	]

	for i: int in range(4):
		var post: MeshInstance3D = MeshInstance3D.new()
		post.mesh = frame_post_mesh
		post.position = corners[i]
		post.material_override = wood_mat
		smoker.add_child(post)

	# Roof/cover (keeps smoke in)
	var roof: MeshInstance3D = MeshInstance3D.new()
	var roof_mesh: BoxMesh = BoxMesh.new()
	roof_mesh.size = Vector3(1.0, 0.1, 1.0)
	roof.mesh = roof_mesh
	roof.position = Vector3(0, 1.55, 0)
	roof.material_override = dark_wood_mat
	smoker.add_child(roof)

	# Smoking racks (horizontal bars for hanging meat)
	var rack_mesh: BoxMesh = BoxMesh.new()
	rack_mesh.size = Vector3(0.7, 0.04, 0.04)

	for i: int in range(2):
		var rack: MeshInstance3D = MeshInstance3D.new()
		rack.mesh = rack_mesh
		rack.position = Vector3(0, 0.8 + i * 0.35, 0)
		rack.material_override = wood_mat
		smoker.add_child(rack)

	# Cross rack
	var cross_rack: MeshInstance3D = MeshInstance3D.new()
	var cross_mesh: BoxMesh = BoxMesh.new()
	cross_mesh.size = Vector3(0.04, 0.04, 0.7)
	cross_rack.mesh = cross_mesh
	cross_rack.position = Vector3(0, 0.8, 0)
	cross_rack.material_override = wood_mat
	smoker.add_child(cross_rack)

	return smoker


func _create_weather_vane() -> StaticBody3D:
	var vane: StaticBody3D = StaticBody3D.new()
	vane.name = "WeatherVane"
	vane.set_script(load("res://scripts/campsite/structure_weather_vane.gd"))

	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.5, 0.35, 0.2)

	var metal_mat: StandardMaterial3D = StandardMaterial3D.new()
	metal_mat.albedo_color = Color(0.55, 0.55, 0.58)
	metal_mat.metallic = 0.7
	metal_mat.roughness = 0.3

	var arrow_mat: StandardMaterial3D = StandardMaterial3D.new()
	arrow_mat.albedo_color = Color(0.6, 0.58, 0.55)
	arrow_mat.metallic = 0.6
	arrow_mat.roughness = 0.4

	# Collision
	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(0.4, 2.5, 0.4)
	collision.shape = box_shape
	collision.position.y = 1.25
	vane.add_child(collision)

	# Wooden post
	var post: MeshInstance3D = MeshInstance3D.new()
	var post_mesh: BoxMesh = BoxMesh.new()
	post_mesh.size = Vector3(0.15, 2.0, 0.15)
	post.mesh = post_mesh
	post.position = Vector3(0, 1.0, 0)
	post.material_override = wood_mat
	vane.add_child(post)

	# Metal cap/pivot point
	var pivot: MeshInstance3D = MeshInstance3D.new()
	var pivot_mesh: BoxMesh = BoxMesh.new()
	pivot_mesh.size = Vector3(0.1, 0.15, 0.1)
	pivot.mesh = pivot_mesh
	pivot.position = Vector3(0, 2.1, 0)
	pivot.material_override = metal_mat
	vane.add_child(pivot)

	# Arrow/pointer (rotates with wind)
	var arrow_parent: Node3D = Node3D.new()
	arrow_parent.name = "ArrowPivot"
	arrow_parent.position = Vector3(0, 2.2, 0)
	vane.add_child(arrow_parent)

	# Arrow shaft
	var shaft: MeshInstance3D = MeshInstance3D.new()
	var shaft_mesh: BoxMesh = BoxMesh.new()
	shaft_mesh.size = Vector3(0.8, 0.04, 0.04)
	shaft.mesh = shaft_mesh
	shaft.material_override = arrow_mat
	arrow_parent.add_child(shaft)

	# Arrow head (triangular, simplified as box)
	var head: MeshInstance3D = MeshInstance3D.new()
	var head_mesh: BoxMesh = BoxMesh.new()
	head_mesh.size = Vector3(0.2, 0.08, 0.15)
	head.mesh = head_mesh
	head.position = Vector3(0.5, 0, 0)
	head.material_override = arrow_mat
	arrow_parent.add_child(head)

	# Arrow tail (feather/fin shape)
	var tail: MeshInstance3D = MeshInstance3D.new()
	var tail_mesh: BoxMesh = BoxMesh.new()
	tail_mesh.size = Vector3(0.15, 0.12, 0.02)
	tail.mesh = tail_mesh
	tail.position = Vector3(-0.45, 0, 0)
	tail.material_override = arrow_mat
	arrow_parent.add_child(tail)

	# Cardinal direction letters (N, S, E, W) - simplified as small blocks
	var letter_mesh: BoxMesh = BoxMesh.new()
	letter_mesh.size = Vector3(0.08, 0.12, 0.02)

	var directions: Array[Dictionary] = [
		{"pos": Vector3(0, 1.9, -0.2), "label": "N"},
		{"pos": Vector3(0, 1.9, 0.2), "label": "S"},
		{"pos": Vector3(0.2, 1.9, 0), "label": "E", "rot": 90},
		{"pos": Vector3(-0.2, 1.9, 0), "label": "W", "rot": 90}
	]

	for dir: Dictionary in directions:
		var marker: MeshInstance3D = MeshInstance3D.new()
		marker.mesh = letter_mesh
		marker.position = dir["pos"]
		if dir.has("rot"):
			marker.rotation_degrees.y = dir["rot"]
		marker.material_override = metal_mat
		vane.add_child(marker)

	return vane


func _create_placed_torch() -> StaticBody3D:
	var torch: StaticBody3D = StaticBody3D.new()
	torch.name = "PlacedTorch"
	torch.set_script(load("res://scripts/campsite/structure_placed_torch.gd"))

	# Materials
	var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.45, 0.32, 0.18)

	var wrap_mat: StandardMaterial3D = StandardMaterial3D.new()
	wrap_mat.albedo_color = Color(0.6, 0.55, 0.4)

	var fire_mat: StandardMaterial3D = StandardMaterial3D.new()
	fire_mat.albedo_color = Color(1.0, 0.6, 0.2)
	fire_mat.emission_enabled = true
	fire_mat.emission = Color(1.0, 0.5, 0.1)
	fire_mat.emission_energy_multiplier = 2.0

	# Collision (thin cylinder approximated as box)
	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(0.15, 1.0, 0.15)
	collision.shape = box_shape
	collision.position.y = 0.5
	torch.add_child(collision)

	# Wooden handle/stick
	var handle: MeshInstance3D = MeshInstance3D.new()
	var handle_mesh: BoxMesh = BoxMesh.new()
	handle_mesh.size = Vector3(0.08, 0.8, 0.08)
	handle.mesh = handle_mesh
	handle.position = Vector3(0, 0.4, 0)
	handle.material_override = wood_mat
	torch.add_child(handle)

	# Cloth/wrap at top
	var wrap: MeshInstance3D = MeshInstance3D.new()
	var wrap_mesh: BoxMesh = BoxMesh.new()
	wrap_mesh.size = Vector3(0.12, 0.15, 0.12)
	wrap.mesh = wrap_mesh
	wrap.position = Vector3(0, 0.85, 0)
	wrap.material_override = wrap_mat
	torch.add_child(wrap)

	# Fire visual (blocky flame)
	var flame: MeshInstance3D = MeshInstance3D.new()
	flame.name = "Flame"
	var flame_mesh: BoxMesh = BoxMesh.new()
	flame_mesh.size = Vector3(0.1, 0.25, 0.1)
	flame.mesh = flame_mesh
	flame.position = Vector3(0, 1.05, 0)
	flame.material_override = fire_mat
	torch.add_child(flame)

	# Inner flame (brighter, smaller)
	var inner_flame: MeshInstance3D = MeshInstance3D.new()
	var inner_mesh: BoxMesh = BoxMesh.new()
	inner_mesh.size = Vector3(0.06, 0.18, 0.06)
	inner_flame.mesh = inner_mesh
	inner_flame.position = Vector3(0, 1.08, 0)

	var inner_mat: StandardMaterial3D = StandardMaterial3D.new()
	inner_mat.albedo_color = Color(1.0, 0.9, 0.5)
	inner_mat.emission_enabled = true
	inner_mat.emission = Color(1.0, 0.8, 0.3)
	inner_mat.emission_energy_multiplier = 3.0
	inner_flame.material_override = inner_mat
	torch.add_child(inner_flame)

	# Light source
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "TorchLight"
	light.light_color = Color(1.0, 0.8, 0.4)
	light.light_energy = 8.0
	light.omni_range = 15.0
	light.shadow_enabled = true
	light.position = Vector3(0, 1.0, 0)
	torch.add_child(light)

	return torch


func _create_lodestone() -> StaticBody3D:
	var lodestone: StaticBody3D = StaticBody3D.new()
	lodestone.name = "Lodestone"
	lodestone.set_script(load("res://scripts/campsite/structure_lodestone.gd"))

	# Dark stone material
	var stone_mat: StandardMaterial3D = StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.18, 0.16, 0.20)
	stone_mat.roughness = 0.9

	var stone_dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	stone_dark_mat.albedo_color = Color(0.14, 0.12, 0.16)
	stone_dark_mat.roughness = 0.95

	# Gold vein material with emission
	var vein_mat: StandardMaterial3D = StandardMaterial3D.new()
	vein_mat.albedo_color = Color(0.85, 0.65, 0.15)
	vein_mat.emission_enabled = true
	vein_mat.emission = Color(0.9, 0.7, 0.1)
	vein_mat.emission_energy_multiplier = 1.5
	vein_mat.metallic = 0.6
	vein_mat.roughness = 0.3

	# Bright gold accent
	var gold_mat: StandardMaterial3D = StandardMaterial3D.new()
	gold_mat.albedo_color = Color(1.0, 0.8, 0.2)
	gold_mat.emission_enabled = true
	gold_mat.emission = Color(1.0, 0.75, 0.15)
	gold_mat.emission_energy_multiplier = 2.0
	gold_mat.metallic = 0.8
	gold_mat.roughness = 0.2

	# Collision
	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(0.4, 0.5, 0.4)
	collision.shape = box_shape
	collision.position.y = 0.25
	lodestone.add_child(collision)

	# Main stone body
	var body: MeshInstance3D = MeshInstance3D.new()
	var body_mesh: BoxMesh = BoxMesh.new()
	body_mesh.size = Vector3(0.35, 0.3, 0.30)
	body.mesh = body_mesh
	body.position = Vector3(0, 0.15, 0)
	body.material_override = stone_mat
	lodestone.add_child(body)

	# Upper stone mass
	var upper: MeshInstance3D = MeshInstance3D.new()
	var upper_mesh: BoxMesh = BoxMesh.new()
	upper_mesh.size = Vector3(0.28, 0.2, 0.25)
	upper.mesh = upper_mesh
	upper.position = Vector3(0.02, 0.35, -0.01)
	upper.material_override = stone_dark_mat
	lodestone.add_child(upper)

	# Small stone bump on top
	var bump: MeshInstance3D = MeshInstance3D.new()
	var bump_mesh: BoxMesh = BoxMesh.new()
	bump_mesh.size = Vector3(0.15, 0.08, 0.14)
	bump.mesh = bump_mesh
	bump.position = Vector3(-0.02, 0.48, 0.01)
	bump.material_override = stone_mat
	lodestone.add_child(bump)

	# Gold vein strip 1
	var vein1: MeshInstance3D = MeshInstance3D.new()
	var vein1_mesh: BoxMesh = BoxMesh.new()
	vein1_mesh.size = Vector3(0.03, 0.22, 0.02)
	vein1.mesh = vein1_mesh
	vein1.position = Vector3(0.08, 0.22, 0.16)
	vein1.rotation.z = 0.3
	vein1.material_override = vein_mat
	lodestone.add_child(vein1)

	# Gold vein strip 2
	var vein2: MeshInstance3D = MeshInstance3D.new()
	var vein2_mesh: BoxMesh = BoxMesh.new()
	vein2_mesh.size = Vector3(0.02, 0.18, 0.03)
	vein2.mesh = vein2_mesh
	vein2.position = Vector3(-0.17, 0.28, 0.04)
	vein2.rotation.z = -0.4
	vein2.material_override = vein_mat
	lodestone.add_child(vein2)

	# Gold vein strip 3
	var vein3: MeshInstance3D = MeshInstance3D.new()
	var vein3_mesh: BoxMesh = BoxMesh.new()
	vein3_mesh.size = Vector3(0.15, 0.02, 0.02)
	vein3.mesh = vein3_mesh
	vein3.position = Vector3(0, 0.38, -0.13)
	vein3.material_override = vein_mat
	lodestone.add_child(vein3)

	# Gold accent nugget on top
	var nugget1: MeshInstance3D = MeshInstance3D.new()
	var nugget1_mesh: BoxMesh = BoxMesh.new()
	nugget1_mesh.size = Vector3(0.06, 0.04, 0.05)
	nugget1.mesh = nugget1_mesh
	nugget1.position = Vector3(0.04, 0.46, 0.03)
	nugget1.material_override = gold_mat
	lodestone.add_child(nugget1)

	# Gold accent nugget on side
	var nugget2: MeshInstance3D = MeshInstance3D.new()
	var nugget2_mesh: BoxMesh = BoxMesh.new()
	nugget2_mesh.size = Vector3(0.04, 0.05, 0.04)
	nugget2.mesh = nugget2_mesh
	nugget2.position = Vector3(0.16, 0.2, 0.08)
	nugget2.material_override = gold_mat
	lodestone.add_child(nugget2)

	# Warm glow light
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "LodestoneLight"
	light.light_color = Color(1.0, 0.85, 0.4)
	light.light_energy = 2.0
	light.omni_range = 4.0
	light.shadow_enabled = false
	light.position = Vector3(0, 0.35, 0)
	lodestone.add_child(light)

	return lodestone
