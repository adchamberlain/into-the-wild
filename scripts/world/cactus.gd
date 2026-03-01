extends StaticBody3D
class_name Cactus
## A procedural cactus with two variants: prickly (contact damage) or fruit-bearing (harvestable).
## Built from BoxMesh primitives matching the game's voxel art style.

# Shared static materials for performance (one allocation across all cactus instances)
static var _materials_initialized: bool = false
static var _mat_body: StandardMaterial3D          # Main green body
static var _mat_body_dark: StandardMaterial3D      # Darker green for ridges
static var _mat_spine: StandardMaterial3D           # White spines
static var _mat_fruit: StandardMaterial3D           # Red cactus fruit
static var _mat_arm: StandardMaterial3D             # Slightly different green for arms

# Instance state
var is_fruit_variant: bool = false
var is_depleted: bool = false
var fruit_mesh: MeshInstance3D = null
var damage_cooldown: float = 0.0
const DAMAGE_AMOUNT: float = 8.0
const DAMAGE_COOLDOWN: float = 1.5

# Terrain positioning
var adjust_to_terrain: bool = false  # Chunk manager positions us directly


func _init() -> void:
	_ensure_shared_materials()


static func _ensure_shared_materials() -> void:
	if _materials_initialized:
		return
	_materials_initialized = true

	_mat_body = StandardMaterial3D.new()
	_mat_body.albedo_color = Color(0.25, 0.55, 0.22)

	_mat_body_dark = StandardMaterial3D.new()
	_mat_body_dark.albedo_color = Color(0.18, 0.42, 0.16)

	_mat_spine = StandardMaterial3D.new()
	_mat_spine.albedo_color = Color(0.92, 0.90, 0.85)

	_mat_fruit = StandardMaterial3D.new()
	_mat_fruit.albedo_color = Color(0.85, 0.18, 0.22)

	_mat_arm = StandardMaterial3D.new()
	_mat_arm.albedo_color = Color(0.22, 0.50, 0.20)


func _process(delta: float) -> void:
	if damage_cooldown > 0.0:
		damage_cooldown -= delta


## Build the cactus procedurally. Call once after instantiation.
## rng: seeded RNG for deterministic generation
## fruit: true for fruit-bearing variant, false for prickly (contact damage)
func build(rng: RandomNumberGenerator, fruit: bool) -> void:
	is_fruit_variant = fruit

	# Randomize dimensions
	var height: float = rng.randf_range(1.5, 3.0)
	var width: float = rng.randf_range(0.35, 0.50)

	# --- Main column ---
	var body: MeshInstance3D = MeshInstance3D.new()
	var body_box: BoxMesh = BoxMesh.new()
	body_box.size = Vector3(width, height, width)
	body_box.material = _mat_body
	body.mesh = body_box
	body.position = Vector3(0, height * 0.5, 0)
	add_child(body)

	# Collision shape for the main column (raycast + physics)
	var col_shape: CollisionShape3D = CollisionShape3D.new()
	var col_box: BoxShape3D = BoxShape3D.new()
	col_box.size = Vector3(width, height, width)
	col_shape.shape = col_box
	col_shape.position = Vector3(0, height * 0.5, 0)
	add_child(col_shape)

	# --- Vertical ridges (4 darker stripes flush on each face) ---
	var ridge_width: float = width * 0.12
	var ridge_depth: float = 0.015
	for i: int in range(4):
		var ridge: MeshInstance3D = MeshInstance3D.new()
		var ridge_box: BoxMesh = BoxMesh.new()
		ridge_box.size = Vector3(ridge_width, height * 0.9, ridge_depth)
		ridge_box.material = _mat_body_dark
		ridge.mesh = ridge_box
		# Position ridges flush on each face (front/back/left/right)
		var offset_x: float = 0.0
		var offset_z: float = 0.0
		var rot_y: float = 0.0
		match i:
			0:  # Front
				offset_z = -width * 0.5
			1:  # Back
				offset_z = width * 0.5
			2:  # Left
				offset_x = -width * 0.5
				rot_y = PI * 0.5
			3:  # Right
				offset_x = width * 0.5
				rot_y = PI * 0.5
		ridge.position = Vector3(offset_x, height * 0.5, offset_z)
		if rot_y != 0.0:
			ridge.rotation.y = rot_y
		add_child(ridge)

	# --- Arms (0-2 branching arms) ---
	var arm_count: int = rng.randi_range(0, 2)
	for i: int in range(arm_count):
		_build_arm(rng, height, width, i)

	# --- Spines (8 small white protrusions) ---
	for i: int in range(8):
		var spine: MeshInstance3D = MeshInstance3D.new()
		var spine_box: BoxMesh = BoxMesh.new()
		spine_box.size = Vector3(0.02, 0.08, 0.02)
		spine_box.material = _mat_spine
		spine.mesh = spine_box
		# Distribute spines around the column at varying heights
		var spine_angle: float = TAU * i / 8.0 + rng.randf_range(-0.2, 0.2)
		var spine_y: float = rng.randf_range(height * 0.2, height * 0.85)
		var spine_dist: float = width * 0.5 + 0.02
		spine.position = Vector3(
			cos(spine_angle) * spine_dist,
			spine_y,
			sin(spine_angle) * spine_dist
		)
		# Tilt spine outward
		spine.rotation.z = cos(spine_angle) * deg_to_rad(25.0)
		spine.rotation.x = -sin(spine_angle) * deg_to_rad(25.0)
		add_child(spine)

	# --- Variant-specific setup ---
	if fruit:
		_build_fruit(height, width)
		# Fruit variant is interactable
		add_to_group("interactable")
		add_to_group("resource_node")
	else:
		_build_damage_area(height, width)


## Build a branching arm segment.
func _build_arm(rng: RandomNumberGenerator, body_height: float, body_width: float, arm_index: int) -> void:
	# Arm attaches at a random height on the main column
	var attach_y: float = rng.randf_range(body_height * 0.35, body_height * 0.7)
	var arm_side: float = -1.0 if arm_index % 2 == 0 else 1.0
	var arm_length: float = rng.randf_range(0.4, 0.7)
	var arm_width: float = body_width * 0.65
	var tip_height: float = rng.randf_range(0.5, 1.0)

	# Horizontal segment
	var h_arm: MeshInstance3D = MeshInstance3D.new()
	var h_box: BoxMesh = BoxMesh.new()
	h_box.size = Vector3(arm_length, arm_width, arm_width)
	h_box.material = _mat_arm
	h_arm.mesh = h_box
	h_arm.position = Vector3(
		arm_side * (body_width * 0.5 + arm_length * 0.5),
		attach_y,
		0
	)
	add_child(h_arm)

	# Vertical tip segment (grows upward from end of horizontal)
	var v_tip: MeshInstance3D = MeshInstance3D.new()
	var v_box: BoxMesh = BoxMesh.new()
	v_box.size = Vector3(arm_width, tip_height, arm_width)
	v_box.material = _mat_arm
	v_tip.mesh = v_box
	v_tip.position = Vector3(
		arm_side * (body_width * 0.5 + arm_length),
		attach_y + tip_height * 0.5,
		0
	)
	add_child(v_tip)


## Build the harvestable fruit on top of the cactus.
func _build_fruit(body_height: float, body_width: float) -> void:
	fruit_mesh = MeshInstance3D.new()
	var fruit_box: BoxMesh = BoxMesh.new()
	fruit_box.size = Vector3(body_width * 0.6, 0.18, body_width * 0.6)
	fruit_box.material = _mat_fruit
	fruit_mesh.mesh = fruit_box
	fruit_mesh.position = Vector3(0, body_height + 0.09, 0)
	add_child(fruit_mesh)


## Build the Area3D that detects player contact for the prickly variant.
func _build_damage_area(body_height: float, body_width: float) -> void:
	var area: Area3D = Area3D.new()
	area.name = "DamageArea"
	area.collision_layer = 0
	area.collision_mask = 1  # Player is on layer 1

	var area_shape: CollisionShape3D = CollisionShape3D.new()
	var area_box: BoxShape3D = BoxShape3D.new()
	# Slightly larger than the visual body so player triggers it on contact
	area_box.size = Vector3(body_width + 0.3, body_height + 0.2, body_width + 0.3)
	area_shape.shape = area_box
	area_shape.position = Vector3(0, body_height * 0.5, 0)
	area.add_child(area_shape)

	area.body_entered.connect(_on_player_contact)
	add_child(area)


## Deal contact damage when a player touches a prickly cactus.
func _on_player_contact(body: Node) -> void:
	if damage_cooldown > 0.0:
		return
	if not body.is_in_group("player"):
		return

	damage_cooldown = DAMAGE_COOLDOWN

	# Apply damage via PlayerStats
	var player_stats: Node = body.get_node_or_null("PlayerStats")
	if player_stats and player_stats.has_method("take_damage"):
		player_stats.take_damage(DAMAGE_AMOUNT)

	SFXManager.play_sfx("fall_hurt")

	# Show damage notification via HUD
	var hud: Node = body.get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_notification"):
		hud.show_notification("Ouch! Cactus spines! -%.0f health" % DAMAGE_AMOUNT, Color(1.0, 0.4, 0.4, 1))

	print("[Cactus] Player took %.0f contact damage" % DAMAGE_AMOUNT)


## Interaction text for fruit-bearing variant.
func get_interaction_text() -> String:
	if is_fruit_variant and not is_depleted:
		return "Pick cactus fruit"
	return ""


## Harvest the cactus fruit when player interacts.
func interact(player: Node) -> bool:
	if not is_fruit_variant or is_depleted:
		return false

	# Add fruit to player inventory
	var inventory: Node = null
	if player.has_node("Inventory"):
		inventory = player.get_node("Inventory")
	elif player.has_method("get_inventory"):
		inventory = player.get_inventory()

	# Check capacity before harvesting
	if inventory and inventory.has_method("can_add_item") and not inventory.can_add_item("cactus_fruit", 1):
		return false

	if inventory and inventory.has_method("add_item"):
		inventory.add_item("cactus_fruit", 1)

	# Play pickup sound
	SFXManager.play_sfx("berry_pluck")

	# Show pickup notification
	var hud: Node = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_notification"):
		hud.show_notification("Picked cactus fruit!", Color(0.6, 1.0, 0.6, 1))

	# Remove the fruit mesh and mark depleted
	is_depleted = true
	if fruit_mesh:
		fruit_mesh.visible = false

	# Remove from interactable so prompt disappears
	remove_from_group("interactable")

	print("[Cactus] Player harvested cactus fruit")
	return true
