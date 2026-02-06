extends Node
class_name GrapplingHook
## Handles grappling hook target detection, validation, and ascent mechanics.

signal grapple_started(anchor: Vector3, landing: Vector3)
signal grapple_completed()
signal grapple_cancelled()
signal target_validity_changed(is_valid: bool, reason: String)

# Grapple range limits
const MAX_VERTICAL_RANGE: float = 20.0  # Maximum height to grapple
const MAX_HORIZONTAL_RANGE: float = 15.0  # Maximum horizontal distance (increased due to terrain collision slopes)
const MAX_TOTAL_RANGE: float = 25.0  # Pythagorean limit
const MIN_HEIGHT_DIFFERENCE: float = 1.5  # Minimum cliff height to grapple

# Ascent settings
const BASE_ASCENT_TIME: float = 0.4  # Base time for ascent
const ASCENT_TIME_PER_UNIT: float = 0.06  # Additional time per unit distance
const DISMOUNT_FORWARD_VELOCITY: float = 2.0  # Forward push on landing
const DISMOUNT_FORWARD_OFFSET: float = 1.5  # How far forward to land from anchor

# Detection settings
const DETECTION_RAY_LENGTH: float = 20.0  # How far to cast ray for targets
const CELL_SIZE: float = 3.0  # Terrain cell size (matches chunk_manager)

# References
var player: CharacterBody3D
var camera: Camera3D
var chunk_manager: Node

# State
var is_grappling: bool = false
var grapple_tween: Tween
var current_anchor: Vector3
var current_landing: Vector3
var grapple_start_position: Vector3

# Visuals
var rope_mesh: MeshInstance3D
var hook_mesh: Node3D

# Target tracking for reticle
var current_target_valid: bool = false
var current_target_reason: String = ""


func _ready() -> void:
	call_deferred("_setup_references")


func _setup_references() -> void:
	player = get_parent() as CharacterBody3D
	if player:
		camera = player.get_node_or_null("Camera3D")

	# Find chunk manager
	chunk_manager = get_tree().get_first_node_in_group("chunk_manager")
	if not chunk_manager:
		# Try alternate path
		var main: Node = get_tree().current_scene
		if main:
			chunk_manager = main.get_node_or_null("ChunkManager")


func _process(_delta: float) -> void:
	# Update target validity for reticle feedback
	if player and _is_grappling_hook_equipped() and not is_grappling:
		var target: Dictionary = get_grapple_target()
		var new_valid: bool = target.get("valid", false)
		var new_reason: String = target.get("reason", "")

		if new_valid != current_target_valid or new_reason != current_target_reason:
			current_target_valid = new_valid
			current_target_reason = new_reason
			target_validity_changed.emit(current_target_valid, current_target_reason)


func _input(event: InputEvent) -> void:
	# Handle grapple cancel (ESC or Circle button)
	if is_grappling and event.is_action_pressed("unequip"):
		cancel_grapple()


func _is_grappling_hook_equipped() -> bool:
	if not player:
		return false
	var equipment: Node = player.get_node_or_null("Equipment")
	if equipment:
		return equipment.get_equipped() == "grappling_hook"
	return false


## Get the current grapple target. Returns dictionary with:
## - valid: bool - whether target is valid
## - anchor: Vector3 - point where hook attaches
## - landing: Vector3 - where player will land
## - reason: String - why invalid (if not valid)
func get_grapple_target() -> Dictionary:
	if not camera or not chunk_manager:
		return {"valid": false, "reason": "No camera or terrain"}

	# Can't grapple while swimming
	if "is_in_water" in player and player.is_in_water:
		if player.global_position.y < 0.15:  # Below water surface
			return {"valid": false, "reason": "Can't grapple underwater"}

	# Cast ray from camera forward
	var space_state: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	var ray_origin: Vector3 = camera.global_position
	var ray_direction: Vector3 = -camera.global_transform.basis.z
	var ray_end: Vector3 = ray_origin + ray_direction * DETECTION_RAY_LENGTH

	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.exclude = [player.get_rid()]
	query.collision_mask = 1  # Default collision layer (terrain)

	var result: Dictionary = space_state.intersect_ray(query)

	if result.is_empty():
		return {"valid": false, "reason": "No target"}

	var hit_position: Vector3 = result.position
	var hit_normal: Vector3 = result.normal

	# Check if terrain ahead of the hit point is significantly higher than player.
	# Nudge hit position slightly into the collider to avoid cell boundary snapping
	# (ray hits land right at box edges; floor() can snap to the wrong cell).
	var nudged_hit: Vector3 = hit_position + ray_direction.normalized() * 0.15
	hit_position = nudged_hit  # Use nudged position for all subsequent lookups
	var terrain_height_at_hit: float = chunk_manager.get_height_at(hit_position.x, hit_position.z)
	var player_height: float = player.global_position.y
	var height_diff: float = terrain_height_at_hit - player_height

	# If the nudged hit didn't find higher terrain, scan forward along the
	# horizontal look direction to find nearby cliffs (up to 5 cells ahead).
	if height_diff < MIN_HEIGHT_DIFFERENCE:
		var forward_2d: Vector2 = Vector2(ray_direction.x, ray_direction.z).normalized()
		var found_cliff: bool = false
		for i in range(1, 6):
			var sample_x: float = hit_position.x + forward_2d.x * CELL_SIZE * i
			var sample_z: float = hit_position.z + forward_2d.y * CELL_SIZE * i
			var sample_height: float = chunk_manager.get_height_at(sample_x, sample_z)
			if sample_height - player_height >= MIN_HEIGHT_DIFFERENCE:
				terrain_height_at_hit = sample_height
				hit_position = Vector3(sample_x, sample_height, sample_z)
				height_diff = sample_height - player_height
				found_cliff = true
				break
		if not found_cliff:
			return {"valid": false, "reason": "Too short"}

	# Find the top of the cliff - sample forward to find the highest nearby point
	var best_height: float = terrain_height_at_hit
	var best_x: float = hit_position.x
	var best_z: float = hit_position.z
	var forward_2d: Vector2 = Vector2(ray_direction.x, ray_direction.z).normalized()

	for i in range(1, 5):
		var sample_x: float = hit_position.x + forward_2d.x * CELL_SIZE * i
		var sample_z: float = hit_position.z + forward_2d.y * CELL_SIZE * i
		var sample_height: float = chunk_manager.get_height_at(sample_x, sample_z)
		if sample_height > best_height:
			best_height = sample_height
			best_x = sample_x
			best_z = sample_z
		elif sample_height < best_height - 1.0:
			# Height dropped, we've passed the cliff top
			break

	var top_height: float = best_height
	height_diff = top_height - player_height

	# Check maximum vertical range
	if height_diff > MAX_VERTICAL_RANGE:
		return {"valid": false, "reason": "Too high"}

	# Calculate anchor point (center of top surface)
	var anchor: Vector3 = Vector3(best_x, top_height, best_z)

	# Check horizontal distance
	var horizontal_dist: float = Vector2(
		anchor.x - player.global_position.x,
		anchor.z - player.global_position.z
	).length()

	if horizontal_dist > MAX_HORIZONTAL_RANGE:
		return {"valid": false, "reason": "Too far"}

	# Check total distance
	var total_dist: float = player.global_position.distance_to(anchor)
	if total_dist > MAX_TOTAL_RANGE:
		return {"valid": false, "reason": "Out of range"}

	# Check line of sight to anchor.
	# The LOS ray will inevitably hit the cliff's own collision geometry on its
	# way to the top, so we check whether the hit is the cliff face itself
	# (near the anchor horizontally) vs a genuine obstruction between player and cliff.
	var los_query := PhysicsRayQueryParameters3D.create(
		player.global_position + Vector3(0, 1.0, 0),  # From player's chest
		anchor + Vector3(0, 0.5, 0)  # To slightly above anchor
	)
	los_query.exclude = [player.get_rid()]
	los_query.collision_mask = 1

	var los_result: Dictionary = space_state.intersect_ray(los_query)

	if not los_result.is_empty():
		var los_hit: Vector3 = los_result.position
		# Check if the hit is near the anchor horizontally — if so, it's the
		# cliff face itself, not an intervening obstruction.
		var horiz_dist_to_anchor: float = Vector2(
			los_hit.x - anchor.x, los_hit.z - anchor.z
		).length()
		if horiz_dist_to_anchor > CELL_SIZE * 1.5:
			return {"valid": false, "reason": "Obstructed"}

	# Check that landing zone isn't water
	if _is_position_water(anchor.x, anchor.z):
		return {"valid": false, "reason": "Water landing"}

	# Use best_height directly for anchor — do NOT re-query get_height_at here,
	# because best_x/best_z can sit on cell boundaries that snap to the wrong cell.
	# best_height was already computed correctly from get_height_at during the search.
	anchor = Vector3(best_x, top_height + 0.5, best_z)

	# Landing is on the cliff top, offset AWAY from the cliff edge (deeper onto top).
	# "to_player" points toward the cliff edge, so we go the opposite direction.
	var to_player: Vector3 = (player.global_position - anchor).normalized()
	to_player.y = 0
	if to_player.length() > 0.1:
		to_player = to_player.normalized()
	else:
		to_player = Vector3(0, 0, 1)

	var landing: Vector3 = Vector3(best_x, top_height + 0.1, best_z) - to_player * DISMOUNT_FORWARD_OFFSET

	# Query landing height, but never go below the cliff top (prevents
	# cell boundary snapping from pulling the player back down the cliff).
	var final_landing_height: float = chunk_manager.get_height_at(landing.x, landing.z)
	landing.y = max(final_landing_height, top_height) + 0.1

	print("[GrapplingHook] VALID TARGET! Anchor: %s, Landing: %s, cliff_top: %.1f" % [anchor, landing, top_height])

	return {
		"valid": true,
		"anchor": anchor,
		"landing": landing,
		"reason": ""
	}


func _is_position_water(x: float, z: float) -> bool:
	if not chunk_manager:
		return false
	if chunk_manager.has_method("is_in_water"):
		return chunk_manager.is_in_water(x, z, 1.0)
	return false


## Attempt to fire the grappling hook. Returns true if successful.
func try_grapple() -> bool:
	if is_grappling:
		return false

	var target: Dictionary = get_grapple_target()
	if not target.get("valid", false):
		# Play fail sound
		SFXManager.play_sfx("swing")
		return false

	# Start grapple
	_start_grapple(target.anchor, target.landing)
	return true


func _start_grapple(anchor: Vector3, landing: Vector3) -> void:
	is_grappling = true
	current_anchor = anchor
	current_landing = landing
	grapple_start_position = player.global_position

	# Play fire sound
	SFXManager.play_sfx("grapple_fire")

	# Create rope visual
	_create_rope_visual(player.global_position + Vector3(0, 1.2, 0), anchor)

	# Create hook at anchor
	_create_hook_visual(anchor)

	# Play attach sound after short delay
	get_tree().create_timer(0.15).timeout.connect(func():
		SFXManager.play_sfx("grapple_attach")
	)

	# Calculate ascent time
	var distance: float = player.global_position.distance_to(anchor)
	var ascent_time: float = BASE_ASCENT_TIME + distance * ASCENT_TIME_PER_UNIT

	# Disable player gravity and movement
	player.velocity = Vector3.ZERO

	# Set player grappling state
	if player.has_method("set_grappling"):
		player.set_grappling(true)

	# Emit signal
	grapple_started.emit(anchor, landing)

	# Tween player position to anchor
	if grapple_tween and grapple_tween.is_valid():
		grapple_tween.kill()

	grapple_tween = create_tween()

	# Move to landing point using method for smooth interpolation and rope update
	grapple_tween.tween_method(_interpolate_grapple, 0.0, 1.0, ascent_time)
	grapple_tween.tween_callback(_on_grapple_complete)


func _interpolate_grapple(progress: float) -> void:
	if not is_grappling or not player:
		return

	# Smooth ascent curve (ease out quad)
	var eased_progress: float = 1.0 - pow(1.0 - progress, 2)

	# Calculate target (go to landing position, slightly above anchor height)
	var target: Vector3 = current_landing
	target.y = current_anchor.y + 0.5

	# Arc path: go up first, then over to the target.
	# The apex is above the highest point (start or target) to clear terrain.
	var apex_y: float = max(grapple_start_position.y, target.y) + 3.0

	# Horizontal position: straight lerp
	var new_pos: Vector3 = grapple_start_position.lerp(target, eased_progress)

	# Vertical position: parabolic arc (peaks at midpoint)
	# At progress 0 -> start.y, at progress 0.5 -> apex_y, at progress 1 -> target.y
	var base_y: float = lerpf(grapple_start_position.y, target.y, eased_progress)
	var arc_offset: float = 4.0 * (apex_y - max(grapple_start_position.y, target.y)) * eased_progress * (1.0 - eased_progress)
	new_pos.y = base_y + arc_offset

	# Safety: never go below the terrain surface at current position
	if chunk_manager:
		var terrain_y: float = chunk_manager.get_height_at(new_pos.x, new_pos.z)
		new_pos.y = max(new_pos.y, terrain_y + 0.5)

	player.global_position = new_pos

	# Update rope visual to follow player
	if rope_mesh:
		_update_rope_visual(player.global_position + Vector3(0, 1.0, 0), current_anchor)


func _on_grapple_complete() -> void:
	# Play landing sound
	SFXManager.play_sfx("grapple_land")

	# Position player at landing spot. Use the pre-computed landing height
	# (which already accounts for cliff top), but verify against actual terrain
	# to prevent clipping underground.
	var final_y: float = current_landing.y + 0.4
	if chunk_manager:
		var terrain_y: float = chunk_manager.get_height_at(current_landing.x, current_landing.z)
		final_y = max(final_y, terrain_y + 0.5)
	player.global_position = Vector3(current_landing.x, final_y, current_landing.z)

	print("[GrapplingHook] Landed at %s" % [player.global_position])

	# Give small forward velocity
	var forward: Vector3 = -player.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	player.velocity = forward * DISMOUNT_FORWARD_VELOCITY

	# Clean up visuals
	_remove_rope_visual()
	_remove_hook_visual()

	# Use durability
	var equipment: Node = player.get_node_or_null("Equipment")
	if equipment:
		equipment.use_durability(1)

	# Clear player grappling state
	if player.has_method("set_grappling"):
		player.set_grappling(false)

	is_grappling = false
	grapple_completed.emit()


## Cancel grapple mid-ascent (player falls)
func cancel_grapple() -> void:
	if not is_grappling:
		return

	if grapple_tween and grapple_tween.is_valid():
		grapple_tween.kill()

	# Clean up visuals
	_remove_rope_visual()
	_remove_hook_visual()

	# Clear player grappling state
	if player and player.has_method("set_grappling"):
		player.set_grappling(false)

	is_grappling = false
	grapple_cancelled.emit()


func _create_rope_visual(from: Vector3, to: Vector3) -> void:
	if rope_mesh:
		_remove_rope_visual()

	rope_mesh = MeshInstance3D.new()
	rope_mesh.name = "GrappleRope"

	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.03
	cylinder.bottom_radius = 0.03
	cylinder.height = 1.0  # Will be scaled
	rope_mesh.mesh = cylinder

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.5, 0.35)  # Tan rope color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rope_mesh.material_override = mat

	get_tree().current_scene.add_child(rope_mesh)
	_update_rope_visual(from, to)


func _update_rope_visual(from: Vector3, to: Vector3) -> void:
	if not rope_mesh:
		return

	var length: float = from.distance_to(to)
	var midpoint: Vector3 = (from + to) / 2.0

	# Scale cylinder to match distance
	rope_mesh.scale = Vector3(1, length, 1)
	rope_mesh.global_position = midpoint

	# Point the cylinder from start to end
	# Cylinder is oriented along Y by default, so we need to rotate it
	var direction: Vector3 = (to - from).normalized()
	if direction.length() > 0.001:
		# Look at the target, then rotate to align cylinder
		rope_mesh.look_at(to, Vector3.UP)
		rope_mesh.rotate_object_local(Vector3.RIGHT, PI / 2)


func _remove_rope_visual() -> void:
	if rope_mesh:
		rope_mesh.queue_free()
		rope_mesh = null


func _create_hook_visual(position: Vector3) -> void:
	if hook_mesh:
		_remove_hook_visual()

	hook_mesh = Node3D.new()
	hook_mesh.name = "GrappleHookAnchor"

	# Simple hook shape
	var hook_head := MeshInstance3D.new()
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.15, 0.1, 0.15)
	hook_head.mesh = head_mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.5, 0.52)
	mat.metallic = 0.7
	hook_head.material_override = mat

	hook_mesh.add_child(hook_head)

	# Prongs
	for i in range(4):
		var prong := MeshInstance3D.new()
		var prong_mesh := BoxMesh.new()
		prong_mesh.size = Vector3(0.04, 0.12, 0.04)
		prong.mesh = prong_mesh
		prong.material_override = mat

		var angle: float = i * PI / 2
		prong.position = Vector3(cos(angle) * 0.08, 0.06, sin(angle) * 0.08)
		prong.rotation.x = -0.5 if i % 2 == 0 else 0.5
		prong.rotation.z = 0.5 if i < 2 else -0.5

		hook_mesh.add_child(prong)

	hook_mesh.global_position = position
	get_tree().current_scene.add_child(hook_mesh)


func _remove_hook_visual() -> void:
	if hook_mesh:
		hook_mesh.queue_free()
		hook_mesh = null
