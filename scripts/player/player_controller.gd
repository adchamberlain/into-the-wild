extends CharacterBody3D
## First-person player controller with WASD movement, mouse look, jumping, sprinting, and interaction.

signal interaction_target_changed(target: Node, interaction_text: String)
signal interaction_cleared()

# Movement settings
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002

# Camera settings
@export var camera_pitch_min: float = -89.0
@export var camera_pitch_max: float = 89.0

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

# Swimming settings
var swim_sink_speed: float = 3.0  # How fast player sinks in water
var swim_rise_speed: float = 2.5  # How fast player rises when pressing space
var swim_move_speed: float = 2.5  # Movement speed while swimming
var water_surface_y: float = 0.15  # Y position of water surface (matches pond_height in fishing_spot)

# Food values (hunger restored per item)
const FOOD_VALUES: Dictionary = {
	"berry": 15.0,
	"mushroom": 10.0,
	"herb": 5.0,
	"fish": 25.0,
	"berry_pouch": 40.0,
	"cooked_berries": 25.0,
	"cooked_mushroom": 20.0,
	"cooked_fish": 40.0,
}

# Healing items (instant health restore)
const HEALING_ITEMS: Dictionary = {
	"healing_salve": 30.0,
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


func _input(event: InputEvent) -> void:
	# Handle mouse look (disabled while resting)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if not is_resting:
			_handle_mouse_look(event)
		return

	# Toggle mouse capture with Escape
	if event is InputEventKey and event.pressed and not event.echo and event.is_action("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Handle interaction (E key)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action("interact") or event.physical_keycode == KEY_E:
			# If resting, E key exits rest mode
			if is_resting and resting_in_structure:
				resting_in_structure.interact(self)
			else:
				_try_interact()
		# Handle eating (F key) - disabled while resting
		if event.physical_keycode == KEY_F and not is_resting:
			_try_eat()
		# Handle using equipped item (R key) - disabled while resting
		if event.physical_keycode == KEY_R and not is_resting:
			_try_use_equipped()


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
	# Skip movement processing while resting
	if is_resting:
		velocity = Vector3.ZERO
		return

	# Handle swimming vs normal movement
	if is_in_water:
		_process_swimming(delta)
	else:
		_process_normal_movement(delta)

	move_and_slide()

	# Update interaction target
	_update_interaction_target()


func _process_normal_movement(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump (check both action and direct key)
	var jump_pressed: bool = Input.is_action_just_pressed("jump") or Input.is_key_pressed(KEY_SPACE)
	if jump_pressed and is_on_floor():
		velocity.y = jump_velocity

	# Handle sprint
	var sprint_held: bool = Input.is_action_pressed("sprint") or Input.is_key_pressed(KEY_SHIFT)
	is_sprinting = sprint_held and is_on_floor()
	current_speed = sprint_speed if is_sprinting else walk_speed

	# Get input direction (use physical key checking for Mac compatibility)
	var input_dir: Vector2 = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		input_dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S):
		input_dir.y += 1
	if Input.is_physical_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D):
		input_dir.x += 1
	input_dir = input_dir.normalized()

	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Apply movement
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		# Decelerate smoothly
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)


func _process_swimming(delta: float) -> void:
	# Swimming: player sinks slowly, pressing space makes them rise
	# Must repeatedly press space to stay afloat

	# Apply sinking (like gravity but slower)
	velocity.y -= swim_sink_speed * delta

	# Handle swim up (space bar - check if held, not just pressed)
	var swim_up_held: bool = Input.is_key_pressed(KEY_SPACE)
	var at_surface: bool = global_position.y >= water_surface_y - 0.3

	if swim_up_held:
		if at_surface:
			# At water surface - allow jumping out of water
			velocity.y = jump_velocity * 0.8  # Slightly weaker than normal jump
		else:
			velocity.y = swim_rise_speed  # Push upward when holding space

	# Clamp vertical velocity to prevent too fast sinking (but allow jump out)
	if velocity.y < -swim_sink_speed * 2:
		velocity.y = -swim_sink_speed * 2

	# Slower horizontal movement while swimming
	var input_dir: Vector2 = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		input_dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S):
		input_dir.y += 1
	if Input.is_physical_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D):
		input_dir.x += 1
	input_dir = input_dir.normalized()

	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Apply slower movement in water
	if direction:
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
	if current_interaction_target and current_interaction_target.has_method("interact"):
		current_interaction_target.interact(self)


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


## Set whether player is in water (swimming).
func set_in_water(in_water: bool) -> void:
	var was_in_water: bool = is_in_water
	is_in_water = in_water

	# Update underwater visual effect
	if is_in_water and not was_in_water:
		_show_underwater_effect()
	elif not is_in_water and was_in_water:
		_hide_underwater_effect()


func _show_underwater_effect() -> void:
	# Create underwater overlay if it doesn't exist
	if not has_node("UnderwaterOverlay"):
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


func _try_eat() -> void:
	if not inventory or not stats:
		return

	# First check for healing items if health is not full
	if stats.health < stats.max_health:
		for heal_type: String in HEALING_ITEMS:
			if inventory.has_item(heal_type):
				inventory.remove_item(heal_type, 1)
				stats.heal(HEALING_ITEMS[heal_type])
				print("[Player] Used 1 %s, +%.0f health" % [heal_type, HEALING_ITEMS[heal_type]])
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
			inventory.remove_item(best_food, 1)
			stats.eat(best_value)
			print("[Player] Ate 1 %s" % best_food)
		else:
			print("[Player] Already full, can't eat")
	else:
		print("[Player] No food in inventory")


func _notification(what: int) -> void:
	# Release mouse when window loses focus
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
