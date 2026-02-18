extends CharacterBody3D
## First-person player controller with WASD movement, mouse look, jumping, sprinting, and interaction.

signal interaction_target_changed(target: Node, interaction_text: String)
signal interaction_cleared()

# Movement settings
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 5.5  # Allows comfortable 1-block jumps (~1.5 blocks max height)
@export var mouse_sensitivity: float = 0.002

# Step-up: automatically walk over tiny terrain height differences (campsite transitions, cave ramps)
const STEP_HEIGHT: float = 0.4  # Max step-up height (fractional differences only, not full blocks)
const STEP_TEST_INCREMENT: float = 0.1  # Test in small increments to find minimum step needed
@export var controller_sensitivity: float = 3.0  # Sensitivity for right stick camera control

# Camera settings
@export var camera_pitch_min: float = -89.0
@export var camera_pitch_max: float = 89.0

# Camera collision - prevents clipping into terrain/ceilings/roofs
const CAMERA_DEFAULT_Y: float = 1.6  # Default eye height (matches scene)
const CAMERA_MIN_Y: float = 0.6  # Lowest the camera can go (crouch level)
const CAMERA_COLLISION_MARGIN: float = 0.15  # Buffer below ceiling hit point
const CAMERA_COLLISION_LERP_SPEED: float = 12.0  # Smoothing speed

# Interaction settings
@export var interaction_distance: float = 3.0

# Node references
@onready var camera: Camera3D = $Camera3D
@onready var head: Node3D = $Camera3D
@onready var interaction_ray: RayCast3D = $Camera3D/InteractionRay
@onready var inventory: Inventory = $Inventory
@onready var stats: PlayerStats = $PlayerStats
@onready var equipment: Equipment = $Equipment

# State
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_speed: float = walk_speed
var is_sprinting: bool = false
var current_interaction_target: Node = null
var is_resting: bool = false
var resting_in_structure: Node = null  # The shelter we're resting in
var is_in_water: bool = false
var is_climbing: bool = false
var climbing_structure: Node = null  # The ladder we're climbing
var is_grappling: bool = false  # Whether player is being pulled by grappling hook

# Performance: throttle raycast checks
const INTERACTION_CHECK_INTERVAL: float = 0.1  # Check 10x/sec instead of 60x/sec
var interaction_check_timer: float = 0.0

# Interaction text refresh for dynamic objects (e.g., drying rack percentage)
const INTERACTION_TEXT_REFRESH_INTERVAL: float = 1.0  # Refresh text every 1 second
var interaction_text_refresh_timer: float = 0.0

# Interact cooldown (prevents analog trigger jitter on L2)
const INTERACT_COOLDOWN: float = 0.15
var interact_cooldown_timer: float = 0.0

# Fall-through protection (safety net - shouldn't trigger with BoxShape3D collision)
var fall_warning_y: float = -15.0  # Emergency recovery if player somehow falls this low
var last_safe_position: Vector3 = Vector3.ZERO  # Last known position on solid ground
var _has_safe_position: bool = false  # Whether last_safe_position has been set (avoids Vector3.ZERO sentinel issue)
var safe_position_update_timer: float = 0.0
const SAFE_POSITION_UPDATE_INTERVAL: float = 0.5  # Update safe position every 0.5 seconds

# Fall damage
var fall_start_y: float = 0.0  # Y position when player started falling
var is_falling: bool = false  # Whether player is currently in a fall
const FALL_DAMAGE_THRESHOLD: float = 4.0  # Minimum fall distance before damage (units)
const FALL_DAMAGE_PER_UNIT: float = 8.0  # HP damage per unit fallen beyond threshold
const FALL_DAMAGE_MAX: float = 80.0  # Maximum fall damage cap

# Death/respawn
var respawn_position: Vector3 = Vector3(0, 5, 0)  # Default spawn, updated when shelter is built
var has_respawn_shelter: bool = false  # Whether player has a shelter to respawn at


# Footstep sound timing
var footstep_timer: float = 0.0
const FOOTSTEP_INTERVAL: float = 0.4  # Time between footstep sounds

# Swimming settings
var swim_sink_speed: float = 3.0  # How fast player sinks in water
var swim_rise_speed: float = 2.5  # How fast player rises when pressing space
var swim_move_speed: float = 2.5  # Movement speed while swimming
var water_surface_y: float = 0.15  # Y position of water surface (matches pond_height in fishing_spot)

# Food values (hunger restored per item)
const FOOD_VALUES: Dictionary = {
	# Raw foods
	"berry": 15.0,
	"mushroom": 10.0,
	"herb": 5.0,
	"fish": 25.0,
	"raw_meat": 20.0,
	"osha_root": 20.0,  # Alpine medicinal plant - also restores hunger
	# Processed
	"berry_pouch": 40.0,
	"waterskin": 35.0,  # Carries water, restores hunger/thirst
	# Cooked (fire pit)
	"cooked_berries": 25.0,
	"cooked_mushroom": 20.0,
	"cooked_fish": 40.0,
	"cooked_meat": 35.0,
	# Preserved (drying rack)
	"dried_fish": 30.0,
	"dried_berries": 20.0,
	"dried_mushroom": 15.0,
	"dried_herb": 8.0,
	# Smoked (smoker - Level 3)
	"smoked_meat": 45.0,
	"smoked_fish": 50.0,
}

# Healing items (instant health restore)
const HEALING_ITEMS: Dictionary = {
	"healing_salve": 30.0,
	"osha_root": 25.0,  # Alpine medicinal plant - potent healer
	"hide_bedroll": 40.0,  # Portable bedroll for resting
}


func _ready() -> void:
	# Add to player group for identification
	add_to_group("player")
	# Capture mouse for first-person control
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Ensure camera is active
	if camera:
		camera.current = true
	# Setup interaction raycast
	if interaction_ray:
		interaction_ray.target_position = Vector3(0, 0, -interaction_distance)
		interaction_ray.enabled = true

	# Initialize fall-through protection with spawn position
	call_deferred("_init_safe_position")

	# Connect death signal for respawn
	if stats:
		stats.player_died.connect(_on_player_died)



func _init_safe_position() -> void:
	last_safe_position = global_position
	_has_safe_position = true
	respawn_position = global_position  # Default to spawn position
	# Try to find an existing shelter for respawn
	_update_respawn_from_structures()
	print("[Player] Initial safe position: %s" % last_safe_position)


func _is_loading_screen_active() -> bool:
	## Check if loading screen is currently displayed
	var loading_screen: Node = get_tree().get_first_node_in_group("loading_screen")
	if loading_screen:
		return true
	# Also check by class name in case group not set
	for child in get_tree().root.get_children():
		if child is CanvasLayer and child.has_method("skip_loading"):
			return true
	return false


func _input(event: InputEvent) -> void:
	# Block all input while loading screen is active
	if _is_loading_screen_active():
		return
	# Handle mouse look (disabled while resting)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if not is_resting:
			_handle_mouse_look(event)
		return

	# Block gameplay actions when a UI menu is open
	if _is_ui_blocking_input():
		return

	# Handle interaction (E key or L2 trigger)
	if event.is_action_pressed("interact"):
		# Skip if cooldown active (prevents analog trigger jitter)
		if interact_cooldown_timer > 0:
			return
		interact_cooldown_timer = INTERACT_COOLDOWN

		# If resting, interact exits rest mode
		if is_resting and is_instance_valid(resting_in_structure):
			resting_in_structure.interact(self)
		else:
			_try_interact()
		return

	# Handle eating (F key or Triangle button) - disabled while resting
	if event.is_action_pressed("eat") and not is_resting:
		_try_eat()
		return

	# Handle using equipped item (R key or R2 trigger) - disabled while resting or placing
	if event.is_action_pressed("use_equipped") and not is_resting:
		var placement: Node = get_node_or_null("PlacementSystem")
		if placement and ("is_placing" in placement and placement.is_placing or "is_moving" in placement and placement.is_moving):
			return  # Let PlacementSystem handle this input
		_try_use_equipped()
		return

	# Handle moving structures (M key or D-pad Up) - disabled while resting
	if event.is_action_pressed("move_structure") and not is_resting:
		_try_move_structure()
		return


func _handle_mouse_look(event: InputEventMouseMotion) -> void:
	# Rotate player body horizontally (yaw)
	rotate_y(-event.relative.x * mouse_sensitivity)

	# Rotate camera vertically (pitch) with clamping
	camera.rotate_x(-event.relative.y * mouse_sensitivity)
	camera.rotation.x = clamp(
		camera.rotation.x,
		deg_to_rad(camera_pitch_min),
		deg_to_rad(camera_pitch_max)
	)


func _physics_process(delta: float) -> void:
	# Block all processing while loading screen is active
	if _is_loading_screen_active():
		velocity = Vector3.ZERO
		return

	# Update interact cooldown (must tick even while resting)
	if interact_cooldown_timer > 0:
		interact_cooldown_timer -= delta

	# Interaction checks must run even while resting/climbing/grappling
	# so that current_interaction_target stays updated
	interaction_check_timer += delta
	if interaction_check_timer >= INTERACTION_CHECK_INTERVAL:
		interaction_check_timer = 0.0
		_update_interaction_target()

	# Periodically refresh interaction text for dynamic objects
	if is_instance_valid(current_interaction_target):
		interaction_text_refresh_timer += delta
		if interaction_text_refresh_timer >= INTERACTION_TEXT_REFRESH_INTERVAL:
			interaction_text_refresh_timer = 0.0
			var interaction_text: String = _get_interaction_text(current_interaction_target)
			interaction_target_changed.emit(current_interaction_target, interaction_text)
	else:
		interaction_text_refresh_timer = 0.0

	# Fall-through protection: track safe position and recover if fallen
	_update_fall_protection(delta)

	# Camera collision: prevent clipping into ceilings/terrain (runs every frame)
	_update_camera_collision(delta)

	# Skip movement processing while resting, climbing, or grappling
	if is_resting:
		if not is_instance_valid(resting_in_structure):
			is_resting = false
		else:
			velocity = Vector3.ZERO
			return
	if is_climbing or is_grappling:
		velocity = Vector3.ZERO
		return

	# Block controller look and movement when UI menus are open
	var ui_blocking: bool = _is_ui_blocking_input()

	# Handle right stick camera look (controller) - disabled when menus are open
	if not ui_blocking:
		_handle_controller_look(delta)

	# Handle swimming vs normal movement
	var actually_swimming: bool = is_in_water and global_position.y < water_surface_y
	if actually_swimming:
		_process_swimming(delta)
	else:
		_process_normal_movement(delta)

	# Auto step-up: walk over 1-unit terrain height differences without jumping
	if is_on_floor() and not actually_swimming:
		_try_step_up(delta)

	move_and_slide()

	# Play footstep/splash sounds based on actual movement (after collision resolution)
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	if horizontal_speed > 0.5 and (is_on_floor() or actually_swimming):
		_update_footsteps(delta)
	elif horizontal_speed <= 0.5:
		footstep_timer = 0.0


func _handle_controller_look(delta: float) -> void:
	# Get right stick input for camera look
	var look_x: float = Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
	var look_y: float = Input.get_action_strength("look_down") - Input.get_action_strength("look_up")

	# Apply deadzone (already handled in project settings, but add slight curve)
	if abs(look_x) < 0.1:
		look_x = 0.0
	if abs(look_y) < 0.1:
		look_y = 0.0

	# Apply controller sensitivity
	if look_x != 0.0 or look_y != 0.0:
		# Rotate player body horizontally (yaw)
		rotate_y(-look_x * controller_sensitivity * delta)

		# Rotate camera vertically (pitch) with clamping
		camera.rotate_x(-look_y * controller_sensitivity * delta)
		camera.rotation.x = clamp(
			camera.rotation.x,
			deg_to_rad(camera_pitch_min),
			deg_to_rad(camera_pitch_max)
		)


func _process_normal_movement(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
		# Track fall start position
		if not is_falling and velocity.y < -1.0:
			is_falling = true
			fall_start_y = global_position.y
	else:
		# Just landed — check for fall damage
		if is_falling:
			_apply_fall_damage()
			is_falling = false

	# Handle jump (works with both keyboard and controller via action)
	# Using is_action_pressed allows holding the button to jump repeatedly when landing
	# Don't jump if a UI menu is open (X button used for ui_accept)
	if Input.is_action_pressed("jump") and is_on_floor() and not _is_ui_blocking_input():
		velocity.y = jump_velocity
		# Record jump start for fall damage calculation
		fall_start_y = global_position.y
		is_falling = false  # Will be set when actually falling

	# Handle sprint (works with both keyboard and controller via action)
	is_sprinting = Input.is_action_pressed("sprint") and is_on_floor() and not _is_ui_blocking_input()
	current_speed = sprint_speed if is_sprinting else walk_speed

	# Get input direction from actions (supports both keyboard and controller)
	# Block movement when UI menus are open
	var input_dir: Vector2 = Vector2.ZERO if _is_ui_blocking_input() else _get_movement_input()

	var direction: Vector3 = Vector3.ZERO
	if input_dir.length() > 0:
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Apply movement
	if direction.length() > 0:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		# Decelerate smoothly
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
		# Reset footstep timer when stopped
		footstep_timer = 0.0


## Auto step-up: walk over tiny terrain height differences.
## Tests incrementally higher positions until forward movement is unblocked,
## then teleports the player up. move_and_slide() floor snapping handles the rest.
## Only handles small fractional differences (campsite transitions, cave ramps).
## Full 1-block terrain steps always require jumping.
func _try_step_up(delta: float) -> void:
	var h_velocity: Vector3 = Vector3(velocity.x, 0, velocity.z)
	if h_velocity.length() < 0.1:
		return

	var motion: Vector3 = h_velocity * delta

	# Check if we'd collide moving forward at current height
	if not test_move(global_transform, motion):
		return  # No obstacle ahead, no step needed

	# Try stepping up in small increments to find the minimum height needed
	var test_height: float = STEP_TEST_INCREMENT
	while test_height <= STEP_HEIGHT:
		# Check if there's room above (no ceiling)
		if test_move(global_transform, Vector3(0, test_height, 0)):
			return  # Ceiling above, can't step up at all

		# Check if we can move forward at this elevated height
		var elevated: Transform3D = global_transform
		elevated.origin.y += test_height
		if not test_move(elevated, motion):
			# Can move forward at this height - step up
			global_position.y += test_height
			return

		test_height += STEP_TEST_INCREMENT


## Get movement input from both keyboard and controller.
func _get_movement_input() -> Vector2:
	var input_dir: Vector2 = Vector2.ZERO

	# Get input from actions (works with keyboard WASD and left stick)
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.y = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")

	# Apply deadzone to prevent joystick drift from triggering movement/footsteps
	if input_dir.length() < 0.15:
		return Vector2.ZERO

	# Clamp for analog stick diagonal movement
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()

	return input_dir


func _process_swimming(delta: float) -> void:
	# Swimming: player sinks slowly, pressing jump makes them rise
	# Must repeatedly press jump to stay afloat

	# Apply sinking (like gravity but slower)
	velocity.y -= swim_sink_speed * delta

	# Handle swim up (jump action - works with spacebar or Cross button)
	var swim_up_held: bool = Input.is_action_pressed("jump")
	var at_surface: bool = global_position.y >= water_surface_y - 0.3
	var at_edge: bool = is_on_wall()  # Touching terrain wall at pond edge

	if swim_up_held:
		if at_surface and at_edge:
			# At water surface AND at edge - allow jumping out of water
			velocity.y = jump_velocity * 0.8  # Slightly weaker than normal jump
		else:
			velocity.y = swim_rise_speed  # Push upward when holding jump

	# Clamp vertical velocity to prevent too fast sinking (but allow jump out)
	if velocity.y < -swim_sink_speed * 2:
		velocity.y = -swim_sink_speed * 2

	# Slower horizontal movement while swimming (use shared input function)
	# Block movement when UI menus are open
	var input_dir: Vector2 = Vector2.ZERO if _is_ui_blocking_input() else _get_movement_input()

	var direction: Vector3 = Vector3.ZERO
	if input_dir.length() > 0:
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Apply slower movement in water
	if direction.length() > 0:
		velocity.x = direction.x * swim_move_speed
		velocity.z = direction.z * swim_move_speed
	else:
		# Decelerate smoothly (faster in water - more drag)
		velocity.x = move_toward(velocity.x, 0, swim_move_speed * 2)
		velocity.z = move_toward(velocity.z, 0, swim_move_speed * 2)


func _update_interaction_target() -> void:
	if not interaction_ray:
		return

	var new_target: Node = null

	if interaction_ray.is_colliding():
		var collider: Node = interaction_ray.get_collider()
		# Check if collider is interactable
		if collider and collider.is_in_group("interactable"):
			new_target = collider

	# Clear stale reference to freed or deletion-queued node (e.g., after cave transition or pickup)
	if current_interaction_target and (not is_instance_valid(current_interaction_target) or current_interaction_target.is_queued_for_deletion()):
		current_interaction_target = null

	# Only emit signals if target changed
	if new_target != current_interaction_target:
		current_interaction_target = new_target
		if current_interaction_target:
			var interaction_text: String = _get_interaction_text(current_interaction_target)
			interaction_target_changed.emit(current_interaction_target, interaction_text)
		else:
			interaction_cleared.emit()


func _get_interaction_text(target: Node) -> String:
	if target.has_method("get_interaction_text"):
		return target.get_interaction_text()
	return "Interact"


func _try_interact() -> void:
	if is_instance_valid(current_interaction_target) and current_interaction_target.has_method("interact"):
		current_interaction_target.interact(self)
		# Check if target was freed or queued for deletion (e.g., picked up torch) and clear HUD
		if not is_instance_valid(current_interaction_target) or current_interaction_target.is_queued_for_deletion():
			current_interaction_target = null
			interaction_cleared.emit()
		elif current_interaction_target:
			# Refresh interaction text in case it changed (e.g., drying rack progress)
			var interaction_text: String = _get_interaction_text(current_interaction_target)
			interaction_target_changed.emit(current_interaction_target, interaction_text)
	else:
		# No interaction target - try instant placement if torch/lodestone is equipped
		if equipment and equipment.get_equipped() == "torch":
			var placement_system: Node = get_node_or_null("PlacementSystem")
			if placement_system and placement_system.has_method("place_torch_instant"):
				if placement_system.place_torch_instant():
					equipment.unequip()
		elif equipment and equipment.get_equipped() == "lodestone":
			var placement_system: Node = get_node_or_null("PlacementSystem")
			if placement_system and placement_system.has_method("place_lodestone_instant"):
				if placement_system.place_lodestone_instant():
					equipment.unequip()


func get_inventory() -> Inventory:
	return inventory


func get_stats() -> PlayerStats:
	return stats


func get_equipment() -> Equipment:
	return equipment


## Set whether player is in resting state (in a shelter).
func set_resting(resting: bool, structure: Node = null) -> void:
	is_resting = resting
	resting_in_structure = structure if resting else null

	if resting:
		# Clear interaction target while resting
		current_interaction_target = null
		interaction_cleared.emit()


## Set whether player is climbing a ladder.
func set_climbing(climbing: bool, structure: Node = null) -> void:
	is_climbing = climbing
	climbing_structure = structure if climbing else null

	if climbing:
		# Clear interaction target while climbing
		current_interaction_target = null
		interaction_cleared.emit()


## Set whether player is grappling (being pulled by grappling hook).
func set_grappling(grappling: bool) -> void:
	is_grappling = grappling

	if grappling:
		# Clear interaction target while grappling
		current_interaction_target = null
		interaction_cleared.emit()
	else:
		# Reset fall tracking so pre-grapple fall_start_y doesn't cause false fall damage
		is_falling = false


## Set whether player is in water (swimming). Uses ref-counting to handle
## overlapping water areas (e.g., fishing pond + river).
var _water_area_count: int = 0

func set_in_water(in_water: bool) -> void:
	if in_water:
		_water_area_count += 1
	else:
		_water_area_count = maxi(_water_area_count - 1, 0)

	var was_in_water: bool = is_in_water
	is_in_water = _water_area_count > 0

	# Update underwater visual effect
	if is_in_water and not was_in_water:
		_show_underwater_effect()
	elif not is_in_water and was_in_water:
		_hide_underwater_effect()


func _show_underwater_effect() -> void:
	# Create underwater overlay if it doesn't exist
	if not has_node("UnderwaterCanvas"):
		var overlay := ColorRect.new()
		overlay.name = "UnderwaterOverlay"
		overlay.color = Color(0.1, 0.3, 0.5, 0.4)  # Blue tint
		overlay.anchors_preset = Control.PRESET_FULL_RECT
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Add to a CanvasLayer so it renders on top
		var canvas := CanvasLayer.new()
		canvas.name = "UnderwaterCanvas"
		canvas.layer = 10  # Above most UI
		canvas.add_child(overlay)
		add_child(canvas)
	else:
		var canvas: Node = get_node("UnderwaterCanvas")
		if canvas:
			canvas.visible = true


func _hide_underwater_effect() -> void:
	var canvas: Node = get_node_or_null("UnderwaterCanvas")
	if canvas:
		canvas.visible = false


func _try_use_equipped() -> void:
	if equipment:
		equipment.use_equipped()


func _try_move_structure() -> void:
	# Check if we're looking at a structure
	if is_instance_valid(current_interaction_target) and current_interaction_target.is_in_group("structure"):
		# Torches and lodestones can only be picked up, not moved
		var stype: String = current_interaction_target.get("structure_type") if current_interaction_target.get("structure_type") else ""
		if stype == "placed_torch" or stype == "lodestone" or stype == "placed_lantern":
			return
		var placement_system: Node = get_node_or_null("PlacementSystem")
		if placement_system and placement_system.has_method("start_move"):
			placement_system.start_move(current_interaction_target)


func _try_eat() -> void:
	if not inventory or not stats:
		return

	# First check for healing items if health is not full
	if stats.health < stats.max_health:
		for heal_type: String in HEALING_ITEMS:
			if inventory.has_item(heal_type):
				var removed: bool = inventory.remove_item(heal_type, 1)
				if not removed:
					continue
				stats.heal(HEALING_ITEMS[heal_type])
				# If item is also food, restore hunger too
				if FOOD_VALUES.has(heal_type) and stats.hunger < stats.max_hunger:
					stats.eat(FOOD_VALUES[heal_type])
				return

	# Try to eat any available food, prioritizing items with most hunger restore
	var best_food: String = ""
	var best_value: float = 0.0

	for food_type: String in FOOD_VALUES:
		if inventory.has_item(food_type) and FOOD_VALUES[food_type] > best_value:
			best_food = food_type
			best_value = FOOD_VALUES[food_type]

	if best_food != "":
		# Only eat if not already full
		if stats.hunger < stats.max_hunger:
			var removed: bool = inventory.remove_item(best_food, 1)
			if removed:
				stats.eat(best_value)


func _notification(what: int) -> void:
	# Release mouse when window loses focus
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# Re-capture mouse when window regains focus (only if no UI menu is open)
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		if not _is_ui_blocking_input():
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


## Fall-through protection: safety net in case player somehow falls below world.
## With BoxShape3D collision matching visual terrain, this should rarely trigger.
func _update_fall_protection(delta: float) -> void:
	# Update safe position periodically when on solid ground
	safe_position_update_timer += delta
	if safe_position_update_timer >= SAFE_POSITION_UPDATE_INTERVAL:
		safe_position_update_timer = 0.0
		if is_on_floor() and not is_grappling:
			last_safe_position = global_position
			_has_safe_position = true

	# Emergency recovery if player falls extremely low (shouldn't happen with proper collision)
	if global_position.y < fall_warning_y:
		push_warning("[Player] Emergency fall recovery triggered (y=%.1f)." % global_position.y)
		_recover_from_fall()


func _recover_from_fall() -> void:
	velocity = Vector3.ZERO
	is_falling = false

	# Determine recovery XZ from last safe position or current position
	var recover_x: float = last_safe_position.x if _has_safe_position else global_position.x
	var recover_z: float = last_safe_position.z if _has_safe_position else global_position.z

	# Use chunk_manager.get_height_at() to find actual terrain surface height,
	# so we always recover ABOVE terrain even if last safe position was underground
	var chunk_manager: Node = _find_chunk_manager()
	if chunk_manager and chunk_manager.has_method("get_height_at"):
		var terrain_y: float = chunk_manager.get_height_at(recover_x, recover_z)
		global_position = Vector3(recover_x, terrain_y + 1.0, recover_z)
		last_safe_position = global_position
		_has_safe_position = true
		print("[Player] Recovered to terrain surface: %s (terrain_y=%.1f)" % [global_position, terrain_y])
	elif _has_safe_position and last_safe_position.y > -10:
		global_position = last_safe_position + Vector3(0, 0.5, 0)
		print("[Player] Recovered to last safe position: %s" % global_position)
	else:
		# Fallback: teleport to spawn
		global_position = Vector3(0, 5, 0)
		last_safe_position = global_position
		_has_safe_position = true
		print("[Player] Recovered to spawn point.")

	# Reset fall tracking to prevent false fall damage after recovery
	fall_start_y = global_position.y


## Apply fall damage based on distance fallen.
func _apply_fall_damage() -> void:
	var fall_distance: float = fall_start_y - global_position.y
	if fall_distance <= FALL_DAMAGE_THRESHOLD:
		return  # Short fall, no damage

	var damage: float = (fall_distance - FALL_DAMAGE_THRESHOLD) * FALL_DAMAGE_PER_UNIT
	damage = minf(damage, FALL_DAMAGE_MAX)

	if stats:
		stats.take_damage(damage)
		# Show damage notification via HUD
		var hud: Node = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_notification"):
			hud.show_notification("Fall damage! -%.0f HP" % damage, Color(1.0, 0.4, 0.4, 1))
		print("[Player] Fall damage: %.1f HP (fell %.1f units)" % [damage, fall_distance])


## Handle player death: auto-save and respawn at latest shelter.
func _on_player_died() -> void:
	print("[Player] Player died! Respawning...")

	# Find the latest shelter/bed to respawn at
	_update_respawn_from_structures()

	# Restore health and hunger to partial values
	if stats:
		stats.is_dead = false
		stats.health = stats.max_health * 0.5
		stats.health_changed.emit(stats.health, stats.max_health)
		stats.hunger = stats.max_hunger * 0.5
		stats.hunger_changed.emit(stats.hunger, stats.max_hunger)

	# Reset movement state flags (player may die while resting, climbing, or grappling)
	is_resting = false
	is_climbing = false
	resting_in_structure = null
	climbing_structure = null

	# Reset water state (player may die while swimming)
	if is_in_water:
		is_in_water = false
		_water_area_count = 0
		_hide_underwater_effect()

	# Cancel active grapple to clean up rope/hook visuals
	var grapple_node: Node = get_node_or_null("GrapplingHook")
	if is_grappling and grapple_node and grapple_node.has_method("cancel_grapple"):
		grapple_node.cancel_grapple()
	is_grappling = false

	# Close any open UI menus and restore mouse capture
	_close_all_menus()

	# Teleport player to respawn point
	velocity = Vector3.ZERO
	is_falling = false
	fall_start_y = respawn_position.y
	global_position = respawn_position

	# Show respawn notification
	var hud: Node = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_notification"):
		if has_respawn_shelter:
			hud.show_notification("You blacked out and woke up at your shelter", Color(1.0, 0.85, 0.3, 1))
		else:
			hud.show_notification("You blacked out and woke up at camp", Color(1.0, 0.85, 0.3, 1))

	# Auto-save after respawn
	var save_load: Node = get_node_or_null("/root/Main/SaveLoad")
	if save_load and save_load.has_method("save_game"):
		# Defer to let position update first
		save_load.call_deferred("save_game")
		print("[Player] Auto-saved after respawn")


## Update respawn position from the latest shelter/bed structure.
func _update_respawn_from_structures() -> void:
	var campsite_mgr: Node = get_node_or_null("/root/Main/CampsiteManager")
	if not campsite_mgr:
		return

	# Check structures in priority order: cabin > canvas_tent > basic_shelter
	for shelter_type: String in ["cabin", "canvas_tent", "basic_shelter"]:
		if campsite_mgr.has_method("get_structures_of_type"):
			var shelters: Array = campsite_mgr.get_structures_of_type(shelter_type)
			if not shelters.is_empty():
				var shelter: Node = shelters.back()  # Latest built
				if is_instance_valid(shelter):
					# Position next to the shelter, slightly offset
					respawn_position = shelter.global_position + Vector3(1.5, 1.0, 0)
					has_respawn_shelter = true
					print("[Player] Respawn point set to %s at %s" % [shelter_type, respawn_position])
					return


## Set respawn position directly (called when structures are built).
func set_respawn_point(pos: Vector3) -> void:
	respawn_position = pos + Vector3(1.5, 1.0, 0)
	has_respawn_shelter = true
	print("[Player] Respawn point updated: %s" % respawn_position)


func _find_chunk_manager() -> Node:
	var terrain: Node = get_node_or_null("/root/Main/Terrain")
	if terrain and terrain.has_method("get_height_at"):
		return terrain
	return null


## Update footstep sounds based on movement.
func _update_footsteps(delta: float) -> void:
	footstep_timer += delta
	if footstep_timer >= FOOTSTEP_INTERVAL:
		footstep_timer = 0.0
		var surface: String = _get_surface_type()
		SFXManager.play_footstep(surface)


## Get the surface type at the player's current position for footstep sounds.
func _get_surface_type() -> String:
	# Only play water sounds if actually submerged (below water surface)
	if is_in_water and global_position.y < water_surface_y:
		return "water"

	# Try to detect terrain region via ChunkManager
	var chunk_manager: Node = get_tree().get_first_node_in_group("chunk_manager")
	if chunk_manager and chunk_manager.has_method("get_region_at"):
		var region: int = chunk_manager.get_region_at(global_position.x, global_position.z)
		# ChunkManager.RegionType: MEADOW=0, FOREST=1, HILLS=2, ROCKY=3, MOUNTAIN=4
		if region == 2 or region == 3 or region == 4:  # HILLS, ROCKY, or MOUNTAIN
			return "stone"

	# Default to grass for forest, plains, meadow
	return "grass"



## Prevent camera from clipping into ceilings, terrain, and roofs.
## Casts a ray from waist height upward to detect overhead obstructions,
## then smoothly lowers the camera to avoid clipping.
func _update_camera_collision(delta: float) -> void:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	if not space_state:
		return

	var target_y: float = CAMERA_DEFAULT_Y

	# Cast ray from waist height upward past default camera position
	# to detect ceilings, sloped roofs, and overhanging terrain
	var ray_start: Vector3 = global_position + Vector3(0, CAMERA_MIN_Y, 0)
	var ray_end: Vector3 = global_position + Vector3(0, CAMERA_DEFAULT_Y + CAMERA_COLLISION_MARGIN, 0)

	var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collision_mask = 1  # Terrain and structures only
	query.exclude = [get_rid()]  # Exclude player body

	var result: Dictionary = space_state.intersect_ray(query)
	if result.size() > 0:
		# Ceiling hit - position camera below the obstruction
		var hit_local_y: float = result.position.y - global_position.y
		target_y = hit_local_y - CAMERA_COLLISION_MARGIN
		target_y = clampf(target_y, CAMERA_MIN_Y, CAMERA_DEFAULT_Y)

	# Smoothly interpolate to target height for natural feel
	camera.position.y = lerpf(camera.position.y, target_y, minf(CAMERA_COLLISION_LERP_SPEED * delta, 1.0))


## Check if any UI menu is open and blocking player input.
## This prevents actions like jump from triggering when X is used for ui_accept.
func _is_ui_blocking_input() -> bool:
	# Check if game is paused (pause menu open)
	if get_tree().paused:
		return true

	# Check for open menus by looking for nodes with is_open or is_visible properties
	for node in get_tree().get_nodes_in_group("crafting_ui"):
		if "is_open" in node and node.is_open:
			return true

	for node in get_tree().get_nodes_in_group("equipment_menu"):
		if "is_visible" in node and node.is_visible:
			return true

	for node in get_tree().get_nodes_in_group("config_menu"):
		if "is_visible" in node and node.is_visible:
			return true

	for node in get_tree().get_nodes_in_group("storage_ui"):
		if "is_open" in node and node.is_open:
			return true

	for node in get_tree().get_nodes_in_group("fire_menu"):
		if "is_open" in node and node.is_open:
			return true

	for node in get_tree().get_nodes_in_group("map_ui"):
		if is_instance_valid(node):
			return true

	return false


## Close all open UI menus and restore mouse capture. Used on death/respawn.
func _close_all_menus() -> void:
	for node in get_tree().get_nodes_in_group("crafting_ui"):
		if "is_open" in node and node.is_open and node.has_method("toggle_crafting_menu"):
			node.toggle_crafting_menu(false)
	for node in get_tree().get_nodes_in_group("equipment_menu"):
		if "is_visible" in node and node.is_visible and node.has_method("toggle_menu"):
			node.toggle_menu()
	for node in get_tree().get_nodes_in_group("config_menu"):
		if "is_visible" in node and node.is_visible and node.has_method("toggle_menu"):
			node.toggle_menu()
	for node in get_tree().get_nodes_in_group("storage_ui"):
		if "is_open" in node and node.is_open and node.has_method("close_storage"):
			node.close_storage()
	for node in get_tree().get_nodes_in_group("fire_menu"):
		if "is_open" in node and node.is_open and node.has_method("close_menu"):
			node.close_menu()
	for node in get_tree().get_nodes_in_group("map_ui"):
		if is_instance_valid(node) and node.has_method("close_map"):
			node.close_map()
	# Ensure mouse is recaptured for gameplay
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
