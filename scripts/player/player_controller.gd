extends CharacterBody3D
## First-person player controller with WASD movement, mouse look, jumping, sprinting, and interaction.

signal interaction_target_changed(target: Node, interaction_text: String)
signal interaction_cleared()

# Developer mode: set to true to spawn with all items for testing
var dev_mode: bool = false
var _pre_dev_inventory: Dictionary = {}  # Snapshot of inventory before dev mode populate

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
var is_crouching: bool = false  # Whether player is crouching (toggle)
var is_gliding: bool = false  # Whether player is gliding with hang glider
var glide_speed: float = 8.0  # Horizontal speed while gliding (faster than sprint)
var glide_descent_rate: float = 1.0  # Slow constant descent rate
var glide_max_height_above_terrain: float = 50.0  # Max height ceiling above terrain
var glide_boost_speed: float = 5.0  # Upward speed during boost
var glide_boost_duration: float = 2.0  # How long each boost lasts (seconds)
var _glide_boost_timer: float = 0.0  # Time remaining on current boost
var _glide_boosting: bool = false  # Currently boosting

# Crouch settings
const CROUCH_SPEED: float = 2.5  # Half walk speed
const CROUCH_HEIGHT: float = 0.9  # Half the normal collision box height
const STAND_HEIGHT: float = 1.8
const CROUCH_CAMERA_Y: float = 0.8  # Camera target when crouching
const CROUCH_EDGE_CHECK_DEPTH: float = 2.0  # Ray length to check for ground below

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
var _spawn_landing: bool = true  # Skip fall damage on first landing (spawn drop)
const FALL_DAMAGE_THRESHOLD: float = 4.0  # Minimum fall distance before damage (units)
const FALL_DAMAGE_PER_UNIT: float = 8.0  # HP damage per unit fallen beyond threshold
const FALL_DAMAGE_MAX: float = 80.0  # Maximum fall damage cap

# Death/respawn
var respawn_position: Vector3 = Vector3(0, 5, 0)  # Default spawn, updated when shelter is built
var has_respawn_shelter: bool = false  # Whether player has a shelter to respawn at

# Explorer's Journal (desert sinkhole easter egg)
var _journal_ui: Node = null
var has_read_journal: bool = false
var map_markers_unlocked: bool = false

# Desert environment check
var _desert_check_timer: float = 0.0
var _is_in_desert: bool = false
var _sandstorm: Sandstorm = null

# Footstep sound timing
var footstep_timer: float = 0.0
const FOOTSTEP_INTERVAL: float = 0.4  # Time between footstep sounds

# Swimming settings
var swim_sink_speed: float = 3.0  # How fast player sinks in water
var swim_rise_speed: float = 2.5  # How fast player rises when pressing space
var swim_move_speed: float = 2.5  # Movement speed while swimming
var water_surface_y: float = 0.15  # Y position of water surface (matches pond_height in fishing_spot)

# Breath / drowning
var air_bubbles: int = 5  # Current bubbles remaining (5 = full breath)
var breath_timer: float = 0.0  # Time since last bubble lost
var is_camera_submerged: bool = false  # Camera below water surface
var BREATH_BUBBLE_INTERVAL: float = 4.0  # Can be modified by coca leaf buff
const MAX_AIR_BUBBLES: int = 5
var coca_leaf_timer: float = 0.0
var _base_breath_interval: float = 4.0

# Food values (hunger restored per item)
const FOOD_VALUES: Dictionary = {
	# Raw foods
	"cactus_fruit": 15.0,
	"berry": 15.0,
	"mushroom": 10.0,
	"herb": 5.0,
	"fish": 25.0,
	"osha_root": 20.0,  # Alpine medicinal plant - also restores hunger
	# Processed
	"berry_pouch": 40.0,
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
	# Kitchen (cabin)
	"hearty_stew": 100.0,
	"preserved_meal": 80.0,
	"herb_tea": 10.0,
	"fish_dinner": 40.0,
	"mushroom_soup": 50.0,
	# Special
	"coca_leaf": 5.0,
}

# Healing items (instant health restore)
const HEALING_ITEMS: Dictionary = {
	"healing_salve": 30.0,
	"osha_root": 25.0,  # Alpine medicinal plant - potent healer
	# Kitchen (cabin) - items that also restore health
	"hearty_stew": 20.0,
	"herb_tea": 30.0,
	"mushroom_soup": 10.0,
}


## Returns true if the player has any food or healing items in inventory.
func has_consumable() -> bool:
	if not inventory:
		return false
	for food_type: String in FOOD_VALUES:
		if inventory.has_item(food_type):
			return true
	for heal_type: String in HEALING_ITEMS:
		if inventory.has_item(heal_type):
			return true
	return false


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

	# Create bow system
	var bow_system: BowSystem = BowSystem.new()
	bow_system.name = "BowSystem"
	add_child(bow_system)

	# Create sandstorm system (follows player, activates in desert)
	_sandstorm = Sandstorm.new()
	_sandstorm.name = "Sandstorm"
	add_child(_sandstorm)
	_sandstorm.sandstorm_started.connect(_on_sandstorm_started)
	_sandstorm.sandstorm_ended.connect(_on_sandstorm_ended)

	# Connect death signal for respawn
	if stats:
		stats.player_died.connect(_on_player_died)

	# Enable stack limits on player inventory
	if inventory:
		inventory.enforce_limits = true
		inventory.item_add_refused.connect(_on_item_add_refused)

	# Dev mode: populate inventory with all items
	if dev_mode:
		call_deferred("_dev_populate_inventory")

	# Starting equipment based on config
	if inventory:
		var config_node: Node = get_tree().get_first_node_in_group("config_menu")
		var give_bow_map: bool = true
		if config_node and "start_with_bow_map" in config_node:
			give_bow_map = config_node.start_with_bow_map
		if give_bow_map:
			inventory.add_item("bow", 1)
			inventory.add_item("arrows", 10)
			inventory.add_item("map", 1)




func _dev_populate_inventory() -> void:
	## Gives one of every item in the game for dev testing.
	# Snapshot current inventory so we can restore it when dev mode is toggled off
	_pre_dev_inventory = inventory.get_all_items()
	var all_items: Array[String] = [
		# Raw resources
		"wood", "branch", "river_rock", "iron_ore",
		"crystal", "diamond", "opal", "rare_ore", "metal_ingot",
		"feathers", "hide", "birch_bark", "raw_meat",
		# Tools & kits
		"torch", "primitive_axe", "stone_axe", "metal_axe", "diamond_axe",
		"machete", "fishing_rod", "grappling_hook", "bow", "enchanted_bow",
		"lantern", "compass", "lodestone", "map", "hang_glider",
		"rope", "leather_axe_wrap", "leather_hook_wrap", "leather_bow_wrap",
		"arrows", "diamond_arrows",
		"campfire_kit", "shelter_kit", "storage_box", "crafting_bench_kit",
		"drying_rack_kit", "garden_plot_kit", "canvas_tent_kit", "cabin_kit",
		"snare_trap_kit", "smithing_station_kit", "smoker_kit", "weather_vane_kit",
		# Raw food
		"berry", "mushroom", "herb", "fish", "osha_root", "cactus_fruit", "coca_leaf",
		# Processed food
		"berry_pouch",
		"cooked_berries", "cooked_mushroom", "cooked_fish", "cooked_meat",
		"dried_fish", "dried_berries", "dried_mushroom", "dried_herb",
		"smoked_meat", "smoked_fish",
		"hearty_stew", "preserved_meal", "herb_tea", "fish_dinner", "mushroom_soup",
		# Healing & rest
		"healing_salve",
		# Special
		"explorers_journal",
	]
	for item: String in all_items:
		if inventory.can_add_item(item, 1):
			inventory.add_item(item, 1)
	# Give extra arrows since they're consumable
	inventory.add_item("arrows", 19)  # 20 total
	inventory.add_item("diamond_arrows", 9)  # 10 total
	print("[DEV] Populated inventory with all items")


func _dev_clear_inventory() -> void:
	## Restores inventory to the snapshot taken before dev mode was enabled.
	inventory.clear()
	for item: String in _pre_dev_inventory:
		inventory.add_item(item, _pre_dev_inventory[item])
	_pre_dev_inventory.clear()
	print("[DEV] Restored pre-dev-mode inventory")


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
		# Check for hang glider deployment (must be airborne, not in another state)
		if equipment and equipment.get_equipped() == "hang_glider" and not is_on_floor() and not is_in_water and not is_grappling and not is_gliding:
			is_gliding = true
			_glide_boosting = false
			_glide_boost_timer = 0.0
			velocity = Vector3.ZERO  # Reset velocity on deploy
			is_falling = false  # Cancel fall tracking (no fall damage from gliding)
			# Reset any accumulated roll on deploy
			rotation.x = 0.0
			rotation.z = 0.0
			camera.rotation.z = 0.0
			return
		# Let BowSystem handle input when bow is equipped
		var bow: Node = get_node_or_null("BowSystem")
		if bow and bow.has_method("is_bow_active") and bow.is_bow_active():
			return
		var placement: Node = get_node_or_null("PlacementSystem")
		if placement and ("is_placing" in placement and placement.is_placing or "is_moving" in placement and placement.is_moving):
			return  # Let PlacementSystem handle this input
		_try_use_equipped()
		return

	# Handle crouch toggle (C key or X button) - disabled while resting or gliding
	if event.is_action_pressed("crouch") and not is_resting and not is_gliding:
		_toggle_crouch()
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
	camera.rotation.z = 0.0  # Prevent roll drift from local rotation


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

	# Desert environment check (every 2 seconds)
	_desert_check_timer += delta
	if _desert_check_timer >= 2.0:
		_desert_check_timer = 0.0
		_check_desert_status()

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

	# Handle gliding (hang glider flight) - takes priority over swimming/normal movement
	if is_gliding:
		_process_gliding(delta)
		return

	# Handle swimming vs normal movement
	var actually_swimming: bool = is_in_water and global_position.y < water_surface_y
	if actually_swimming:
		_process_swimming(delta)
	else:
		_process_normal_movement(delta)

	# Auto step-up: walk over 1-unit terrain height differences without jumping
	if is_on_floor() and not actually_swimming:
		_try_step_up(delta)

	# Crouch edge prevention (Minecraft sneak): stop at ledges
	if is_crouching and is_on_floor() and not actually_swimming:
		_crouch_edge_prevent()

	move_and_slide()

	# Breath / drowning check
	_update_breath(delta)

	# Coca leaf buff timer
	if coca_leaf_timer > 0.0:
		coca_leaf_timer -= delta
		if coca_leaf_timer <= 0.0:
			coca_leaf_timer = 0.0
			BREATH_BUBBLE_INTERVAL = _base_breath_interval
			get_tree().call_group("hud", "update_coca_leaf_timer", 0.0)
			get_tree().call_group("hud", "show_notification", "The coca leaf effect fades", Color(1, 0.85, 0.3, 1))
		else:
			get_tree().call_group("hud", "update_coca_leaf_timer", coca_leaf_timer)

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
		camera.rotation.z = 0.0  # Prevent roll drift from local rotation


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
			if _spawn_landing:
				_spawn_landing = false
			else:
				_apply_fall_damage()
			is_falling = false

	# Handle jump (works with both keyboard and controller via action)
	# Using is_action_pressed allows holding the button to jump repeatedly when landing
	# Don't jump if a UI menu is open (X button used for ui_accept)
	if Input.is_action_pressed("jump") and is_on_floor() and not _is_ui_blocking_input():
		# Stand up from crouch first; if can't stand, don't jump
		var can_jump: bool = true
		if is_crouching:
			if _can_stand_up():
				is_crouching = false
				_update_crouch_collision()
			else:
				can_jump = false
		if can_jump:
			velocity.y = jump_velocity
			# Record jump start for fall damage calculation
			fall_start_y = global_position.y
			is_falling = false  # Will be set when actually falling

	# Handle sprint (works with both keyboard and controller via action)
	is_sprinting = Input.is_action_pressed("sprint") and is_on_floor() and not _is_ui_blocking_input() and not is_crouching
	if is_crouching:
		current_speed = CROUCH_SPEED
	else:
		current_speed = sprint_speed if is_sprinting else walk_speed

	# Apply sandstorm speed reduction (30% slower during sandstorms)
	if _sandstorm and _sandstorm.is_active:
		current_speed *= Sandstorm.SPEED_MULTIPLIER

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

	if swim_up_held:
		if at_surface:
			# At water surface - boost out of water
			velocity.y = jump_velocity * 0.8
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


## Process hang glider flight. Slow constant descent with boost (jump) to gain altitude.
func _process_gliding(delta: float) -> void:
	if not camera:
		_stop_gliding()
		return

	# Prevent roll accumulation: force player body and camera to have zero roll every frame
	rotation.x = 0.0
	rotation.z = 0.0
	camera.rotation.z = 0.0

	# Check for retract (crouch retracts the glider)
	if Input.is_action_just_pressed("crouch"):
		_stop_gliding()
		return

	# Check for boost (jump = Circle on controller, Space on keyboard)
	# Can be pressed repeatedly to keep climbing
	if Input.is_action_just_pressed("jump"):
		_glide_boosting = true
		_glide_boost_timer = glide_boost_duration

	# Tick active boost
	if _glide_boosting:
		_glide_boost_timer -= delta
		if _glide_boost_timer <= 0.0:
			_glide_boosting = false

	# Vertical movement: boost rises, otherwise slow constant descent
	var vertical_speed: float = 0.0
	if _glide_boosting:
		vertical_speed = glide_boost_speed
	else:
		vertical_speed = -glide_descent_rate

	# Enforce max height above terrain
	var terrain_height: float = 0.0
	var chunk_mgr: Node = _find_chunk_manager()
	if chunk_mgr and chunk_mgr.has_method("get_height_at"):
		terrain_height = chunk_mgr.get_height_at(global_position.x, global_position.z)
	var height_above_terrain: float = global_position.y - terrain_height
	if height_above_terrain >= glide_max_height_above_terrain and vertical_speed > 0:
		vertical_speed = 0.0

	velocity.y = vertical_speed

	# Horizontal movement: use player yaw to get a clean forward direction
	var yaw: float = rotation.y
	var forward: Vector3 = Vector3(-sin(yaw), 0.0, -cos(yaw))

	# Allow steering with WASD / left stick
	var input_dir: Vector2 = _get_movement_input()
	var move_dir: Vector3 = forward
	if input_dir.length() > 0.1:
		var right: Vector3 = Vector3(cos(yaw), 0.0, -sin(yaw))
		move_dir = (forward * (-input_dir.y) + right * input_dir.x).normalized()
		if move_dir.length() < 0.1:
			move_dir = forward

	velocity.x = move_dir.x * glide_speed
	velocity.z = move_dir.z * glide_speed

	move_and_slide()

	# Force roll zero again after move_and_slide (collisions can introduce rotation)
	rotation.x = 0.0
	rotation.z = 0.0
	camera.rotation.z = 0.0

	# Auto-land if touching ground
	if is_on_floor():
		_stop_gliding()

	# Retract if entering water
	if is_in_water:
		_stop_gliding()


func _stop_gliding() -> void:
	is_gliding = false
	_glide_boosting = false
	_glide_boost_timer = 0.0


## Track breath while camera is submerged. Lose 1 bubble every 4 seconds; die at 0.
func _update_breath(delta: float) -> void:
	var was_submerged: bool = is_camera_submerged
	is_camera_submerged = is_in_water and camera and camera.global_position.y < water_surface_y

	if is_camera_submerged:
		if not was_submerged:
			# Just went under — reset timer, show bubbles
			breath_timer = 0.0
			get_tree().call_group("hud", "update_air_bubbles", air_bubbles, true)
		else:
			breath_timer += delta
			if breath_timer >= BREATH_BUBBLE_INTERVAL:
				breath_timer -= BREATH_BUBBLE_INTERVAL
				air_bubbles -= 1
				if air_bubbles < 0:
					air_bubbles = 0
				SFXManager.play_sfx("bubble_pop")
				get_tree().call_group("hud", "update_air_bubbles", air_bubbles, true)
				if air_bubbles <= 0 and stats:
					# Drown — instant death
					stats.take_damage(stats.health)
	elif was_submerged:
		# Surfaced — replenish and hide bubbles
		air_bubbles = MAX_AIR_BUBBLES
		breath_timer = 0.0
		get_tree().call_group("hud", "update_air_bubbles", air_bubbles, false)


func _update_interaction_target() -> void:
	if not interaction_ray:
		return

	var new_target: Node = null

	if interaction_ray.is_colliding():
		var collider: Node = interaction_ray.get_collider()
		# Check if collider is interactable and not queued for deletion (e.g., just picked up)
		if collider and collider.is_in_group("interactable") and not collider.is_queued_for_deletion():
			new_target = collider

	# Clear stale reference to freed or deletion-queued node (e.g., after cave transition or pickup)
	if current_interaction_target and (not is_instance_valid(current_interaction_target) or current_interaction_target.is_queued_for_deletion()):
		current_interaction_target = null
		interaction_cleared.emit()

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
	# L2/interact should only pick up/interact - placement is handled by R2/use_equipped


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

	var hud: Node = get_tree().get_first_node_in_group("hud")

	# Don't consume anything if both health and hunger are full
	if stats.health >= stats.get_max_health() and stats.hunger >= stats.max_hunger:
		if hud and hud.has_method("show_notification"):
			hud.show_notification("Health and food are full!", Color(0.6, 1.0, 0.6, 1))
		return

	# First check for healing items if health is not full
	if stats.health < stats.get_max_health():
		for heal_type: String in HEALING_ITEMS:
			if inventory.has_item(heal_type):
				var removed: bool = inventory.remove_item(heal_type, 1)
				if not removed:
					continue
				var healed: float = HEALING_ITEMS[heal_type]
				stats.heal(healed)
				var item_name: String = heal_type.capitalize().replace("_", " ")
				var msg: String = "Used %s! +%.0f health" % [item_name, healed]
				# If item is also food, restore hunger too
				if FOOD_VALUES.has(heal_type) and stats.hunger < stats.max_hunger:
					var fed: float = stats.eat(FOOD_VALUES[heal_type])
					msg += ", +%.0f hunger" % fed
				if hud and hud.has_method("show_notification"):
					hud.show_notification(msg, Color(0.6, 1.0, 0.6, 1))
				return

	# Check if hunger is full before trying to eat food
	if stats.hunger >= stats.max_hunger:
		if hud and hud.has_method("show_notification"):
			hud.show_notification("Food meter is full!", Color(0.6, 1.0, 0.6, 1))
		return

	# Try to eat any available food, prioritizing items with most hunger restore
	var best_food: String = ""
	var best_value: float = 0.0

	for food_type: String in FOOD_VALUES:
		if inventory.has_item(food_type) and FOOD_VALUES[food_type] > best_value:
			best_food = food_type
			best_value = FOOD_VALUES[food_type]

	if best_food != "":
		var removed: bool = inventory.remove_item(best_food, 1)
		if removed:
			var fed: float = stats.eat(best_value)
			var item_name: String = best_food.capitalize().replace("_", " ")
			if hud and hud.has_method("show_notification"):
				hud.show_notification("Ate %s! +%.0f hunger" % [item_name, fed], Color(0.6, 1.0, 0.6, 1))
			# Coca leaf breath buff
			if best_food == "coca_leaf":
				coca_leaf_timer = 300.0  # 5 minutes
				_base_breath_interval = 4.0
				BREATH_BUBBLE_INTERVAL = _base_breath_interval * 2.0  # 4s -> 8s
				SFXManager.play_sfx("coca_leaf")
				get_tree().call_group("hud", "show_notification", "Your breathing slows... lungs feel stronger", Color(0.6, 1, 0.6, 1))
	else:
		if hud and hud.has_method("show_notification"):
			hud.show_notification("No food in inventory!", Color(1.0, 0.5, 0.5, 1))


func _open_journal() -> void:
	if _journal_ui and is_instance_valid(_journal_ui):
		return  # Already open
	var journal_script: GDScript = load("res://scripts/ui/journal_ui.gd")
	_journal_ui = CanvasLayer.new()
	_journal_ui.set_script(journal_script)
	_journal_ui.layer = 80
	add_child(_journal_ui)
	_journal_ui.journal_closed.connect(_on_journal_closed)
	_journal_ui.open_journal(not has_read_journal)


func _on_journal_closed(was_first_read: bool) -> void:
	if _journal_ui and is_instance_valid(_journal_ui):
		_journal_ui.queue_free()
		_journal_ui = null
	if was_first_read and not has_read_journal:
		has_read_journal = true
		_apply_journal_rewards()


func _apply_journal_rewards() -> void:
	# Reward 1: Stat boost — +25 max health and 20% slower hunger
	if stats:
		stats.max_health_bonus = 25
		stats.hunger_depletion_rate = 0.04  # -20% from 0.05
		stats.health = stats.get_max_health()  # Heal to new max
	get_tree().call_group("hud", "show_notification", "Ancient survival wisdom flows through you...", Color(0.6, 1, 0.6, 1))

	# Small delay between notifications
	await get_tree().create_timer(2.0).timeout

	# Reward 2: Recipe unlock (crafting system will check has_read_journal)
	get_tree().call_group("hud", "show_notification", "You've learned to craft a Hang Glider", Color(0.6, 1, 0.6, 1))

	await get_tree().create_timer(2.0).timeout

	# Reward 3: Map markers on compass
	map_markers_unlocked = true
	get_tree().call_group("hud", "show_notification", "The journal reveals hidden locations...", Color(0.6, 1, 0.6, 1))


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
	# Skip when swimming — deep water bodies (sinkhole) legitimately go far below terrain
	if global_position.y < fall_warning_y and not is_in_water:
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
	if damage < 1.0:
		return  # Too small to matter, skip sound and notification

	if stats:
		stats.take_damage(damage)
		SFXManager.play_sfx("fall_hurt")
		# Show damage notification via HUD
		var hud: Node = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_notification"):
			hud.show_notification("Ouch! -%.0f health" % damage, Color(1.0, 0.4, 0.4, 1))
		print("[Player] Fall damage: %.1f health (fell %.1f units)" % [damage, fall_distance])


## Handle player death: auto-save and respawn at latest shelter.
func _on_item_add_refused(resource_type: String, attempted: int, current: int, limit: int) -> void:
	var display_name: String = resource_type.capitalize().replace("_", " ").replace("River Rock", "Rock")
	var message: String = "Can't carry more %s (%d/%d). Store items first." % [display_name, current, limit]
	var hud: Node = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_notification"):
		hud.show_notification(message, Color(1.0, 0.5, 0.5))


func _on_player_died() -> void:
	print("[Player] Player died! Respawning...")

	# Find the latest shelter/bed to respawn at
	_update_respawn_from_structures()

	# Restore health and hunger to partial values
	if stats:
		stats.is_dead = false
		stats.health = stats.get_max_health() * 0.5
		stats.health_changed.emit(stats.health, stats.get_max_health())
		stats.hunger = stats.max_hunger * 0.5
		stats.hunger_changed.emit(stats.hunger, stats.max_hunger)

	# Reset structure resting state before clearing player reference
	# (prevents phantom time skips from shelter/bed _on_period_changed)
	if is_instance_valid(resting_in_structure):
		if "is_player_resting" in resting_in_structure:
			resting_in_structure.is_player_resting = false
			resting_in_structure.resting_player = null
		if "is_player_sleeping" in resting_in_structure:
			resting_in_structure.is_player_sleeping = false
			resting_in_structure.sleeping_player = null

	# Reset movement state flags (player may die while resting, climbing, gliding, or grappling)
	is_resting = false
	is_climbing = false
	_stop_gliding()
	resting_in_structure = null
	climbing_structure = null

	# Reset breath state
	air_bubbles = MAX_AIR_BUBBLES
	breath_timer = 0.0
	is_camera_submerged = false
	get_tree().call_group("hud", "update_air_bubbles", air_bubbles, false)

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

	# Cancel active placement to remove ghost preview mesh
	var placement: Node = get_node_or_null("PlacementSystem")
	if placement and "is_placing" in placement and placement.is_placing:
		if placement.has_method("cancel_placement"):
			placement.cancel_placement()

	# Close any open UI menus and restore mouse capture
	_close_all_menus()

	# Fade to black, then respawn while screen is dark
	var hud: Node = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("fade_to_black_and_back"):
		hud.fade_to_black_and_back(1.0, 1.0, 1.0, _respawn_after_fade)
	else:
		# Fallback if HUD not available
		_respawn_after_fade()


## Phase 2 of death: runs while screen is black during fade.
func _respawn_after_fade() -> void:
	# Teleport player to respawn point
	velocity = Vector3.ZERO
	is_falling = false
	_spawn_landing = true
	fall_start_y = respawn_position.y
	global_position = respawn_position

	# Show respawn notification
	var hud: Node = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_notification"):
		if has_respawn_shelter:
			hud.show_notification("You blacked out and woke up at your shelter", Color(1.0, 0.85, 0.3, 1))
		else:
			hud.show_notification("You blacked out and woke up at camp", Color(1.0, 0.85, 0.3, 1))

	# Silent auto-save after respawn (no HUD notification)
	var save_load: Node = get_node_or_null("/root/Main/SaveLoad")
	if save_load and save_load.has_method("save_game_slot"):
		save_load.call_deferred("save_game_slot", 5, true)
		print("[Player] Auto-saved after respawn to slot 5")


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

	var target_y: float = CROUCH_CAMERA_Y if is_crouching else CAMERA_DEFAULT_Y

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


## Check if player is in the desert region and update hunger/sandstorm/HUD accordingly.
func _check_desert_status() -> void:
	var chunk_mgr: Node = get_tree().get_first_node_in_group("chunk_manager")
	if not chunk_mgr or not chunk_mgr.has_method("get_region_at"):
		return
	var region: int = chunk_mgr.get_region_at(global_position.x, global_position.z)
	_is_in_desert = (region == ChunkManager.RegionType.DESERT)

	# Update hunger multiplier on PlayerStats
	if stats:
		stats.desert_hunger_multiplier = 1.5 if _is_in_desert else 1.0

	# Update sandstorm system
	if _sandstorm:
		_sandstorm.set_in_desert(_is_in_desert)

	# Notify HUD for heat indicator
	var hud_nodes: Array[Node] = get_tree().get_nodes_in_group("hud")
	if hud_nodes.size() > 0 and hud_nodes[0].has_method("set_desert_heat_active"):
		hud_nodes[0].set_desert_heat_active(_is_in_desert)


## Called when a sandstorm starts - notify HUD to show overlay.
func _on_sandstorm_started() -> void:
	var hud_nodes: Array[Node] = get_tree().get_nodes_in_group("hud")
	if hud_nodes.size() > 0 and hud_nodes[0].has_method("show_sandstorm_overlay"):
		hud_nodes[0].show_sandstorm_overlay()
	show_notification("A sandstorm is approaching!", Color(1.0, 0.7, 0.3, 1))


## Called when a sandstorm ends - notify HUD to hide overlay.
func _on_sandstorm_ended() -> void:
	var hud_nodes: Array[Node] = get_tree().get_nodes_in_group("hud")
	if hud_nodes.size() > 0 and hud_nodes[0].has_method("hide_sandstorm_overlay"):
		hud_nodes[0].hide_sandstorm_overlay()


## Show a notification via HUD.
func show_notification(message: String, color: Color) -> void:
	var hud: Node = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_notification"):
		hud.show_notification(message, color)


## Toggle crouch on/off. When uncrouching, check for ceiling clearance first.
func _toggle_crouch() -> void:
	if is_crouching:
		# Try to stand up — check for ceiling clearance
		if _can_stand_up():
			is_crouching = false
			_update_crouch_collision()
		# else: stay crouched (ceiling above)
	else:
		is_crouching = true
		_update_crouch_collision()


## Update collision shape height and position for crouch state.
func _update_crouch_collision() -> void:
	var col_shape: CollisionShape3D = get_node_or_null("CollisionShape3D")
	if not col_shape or not col_shape.shape is BoxShape3D:
		return
	var box: BoxShape3D = col_shape.shape as BoxShape3D
	if is_crouching:
		box.size.y = CROUCH_HEIGHT
		col_shape.position.y = CROUCH_HEIGHT / 2.0
	else:
		box.size.y = STAND_HEIGHT
		col_shape.position.y = STAND_HEIGHT / 2.0


## Check if there's enough room above to stand up from crouch.
func _can_stand_up() -> bool:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	if not space_state:
		return true
	# Ray from current crouch top to standing top
	var ray_start: Vector3 = global_position + Vector3(0, CROUCH_HEIGHT, 0)
	var ray_end: Vector3 = global_position + Vector3(0, STAND_HEIGHT + 0.1, 0)
	var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	var result: Dictionary = space_state.intersect_ray(query)
	return result.size() == 0


## Crouch edge prevention: cancel horizontal velocity if it would move the player off a ledge.
func _crouch_edge_prevent() -> void:
	if velocity.x == 0.0 and velocity.z == 0.0:
		return
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	if not space_state:
		return
	# Project next position based on velocity
	var step: Vector3 = Vector3(velocity.x, 0, velocity.z).normalized() * 0.4
	var test_pos: Vector3 = global_position + step
	# Cast ray downward from the test position
	var ray_start: Vector3 = test_pos + Vector3(0, 0.5, 0)
	var ray_end: Vector3 = test_pos + Vector3(0, -CROUCH_EDGE_CHECK_DEPTH, 0)
	var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	var result: Dictionary = space_state.intersect_ray(query)
	if result.size() == 0:
		# No ground ahead — stop horizontal movement
		velocity.x = 0.0
		velocity.z = 0.0
