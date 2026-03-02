extends Node3D
## Oakland Hills house interior — the player's home after completing the wilderness journey.
## Colonial style: dark hardwood floors, white walls, crown molding, six-pane windows.
## Everything is built programmatically in _ready() using BoxMesh primitives.

const HUD_FONT: Font = preload("res://resources/hud_font.tres")
const HousePlayer: GDScript = preload("res://scripts/house/house_player.gd")

# House dimensions (meters)
const HOUSE_WIDTH: float = 12.0  # X axis
const HOUSE_DEPTH: float = 10.0  # Z axis
const CEILING_HEIGHT: float = 3.0
const WALL_THICKNESS: float = 0.15
const FLOOR_THICKNESS: float = 0.1

# Room dividers
const LIVING_ROOM_WIDTH: float = 6.0   # Left half width
const LIVING_ROOM_DEPTH: float = 5.0   # South half depth
const KITCHEN_DEPTH: float = 5.0       # North half of left side
const DINING_ROOM_WIDTH: float = 6.0   # Right half width (full depth)

# --- Shared static materials ---
static var _mat_floor: StandardMaterial3D
static var _mat_wall: StandardMaterial3D
static var _mat_ceiling: StandardMaterial3D
static var _mat_molding: StandardMaterial3D
static var _mat_furniture_wood: StandardMaterial3D
static var _mat_upholstery: StandardMaterial3D
static var _mat_rug: StandardMaterial3D
static var _mat_door: StandardMaterial3D
static var _mat_window_frame: StandardMaterial3D
static var _mat_window_glass: StandardMaterial3D
static var _mat_window_sky: StandardMaterial3D
static var _mat_window_hills: StandardMaterial3D
static var _mat_window_houses: StandardMaterial3D
static var _mat_stove: StandardMaterial3D
static var _mat_kettle: StandardMaterial3D
static var _mat_fridge: StandardMaterial3D
static var _mat_cabinet_face: StandardMaterial3D
static var _mat_plate: StandardMaterial3D
static var _mat_sandwich: StandardMaterial3D
static var _mat_portrait_frame: StandardMaterial3D
static var _mat_portrait_bg: StandardMaterial3D
static var _mat_cat_black: StandardMaterial3D
static var _mat_cat_white: StandardMaterial3D
static var _mat_cat_eyes: StandardMaterial3D
static var _mat_chandelier: StandardMaterial3D
static var _mat_handle: StandardMaterial3D
static var _mat_storage_box: StandardMaterial3D
static var _materials_initialized: bool = false

# Text overlay for interactables
var _text_overlay_canvas: CanvasLayer
var _text_overlay_label: Label
var _text_overlay_panel: PanelContainer
var _text_overlay_timer: float = 0.0
var _text_overlay_active: bool = false


func _ready() -> void:
	_init_materials()
	_build_floor_and_ceiling()
	_build_exterior_walls()
	_build_interior_walls()
	_build_crown_molding()
	_build_windows()
	_build_front_door()
	_build_living_room_furniture()
	_build_kitchen_furniture()
	_build_dining_room_furniture()
	_build_cat_portraits()
	_setup_lighting()
	_setup_environment()
	_create_player()
	_build_text_overlay()
	_start_fade_in()


func _process(delta: float) -> void:
	# Auto-dismiss text overlay
	if _text_overlay_active:
		_text_overlay_timer -= delta
		if _text_overlay_timer <= 0.0:
			_hide_text_overlay()


func _input(event: InputEvent) -> void:
	# Dismiss text overlay on any key/button press
	if _text_overlay_active:
		if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
			if event.is_pressed():
				_hide_text_overlay()


# =============================================================================
# MATERIALS
# =============================================================================

static func _init_materials() -> void:
	if _materials_initialized:
		return
	_materials_initialized = true

	# Floor: dark hardwood
	_mat_floor = StandardMaterial3D.new()
	_mat_floor.albedo_color = Color(0.25, 0.15, 0.08)
	_mat_floor.roughness = 0.7

	# Walls: classic white
	_mat_wall = StandardMaterial3D.new()
	_mat_wall.albedo_color = Color(0.92, 0.90, 0.88)
	_mat_wall.roughness = 0.9

	# Ceiling: slightly off-white
	_mat_ceiling = StandardMaterial3D.new()
	_mat_ceiling.albedo_color = Color(0.90, 0.88, 0.86)
	_mat_ceiling.roughness = 0.9

	# Crown molding
	_mat_molding = StandardMaterial3D.new()
	_mat_molding.albedo_color = Color(0.88, 0.86, 0.84)
	_mat_molding.roughness = 0.85

	# Furniture wood: medium brown
	_mat_furniture_wood = StandardMaterial3D.new()
	_mat_furniture_wood.albedo_color = Color(0.4, 0.25, 0.12)
	_mat_furniture_wood.roughness = 0.75

	# Upholstery: muted blue-grey
	_mat_upholstery = StandardMaterial3D.new()
	_mat_upholstery.albedo_color = Color(0.35, 0.4, 0.5)
	_mat_upholstery.roughness = 0.85

	# Rug: muted red-brown
	_mat_rug = StandardMaterial3D.new()
	_mat_rug.albedo_color = Color(0.5, 0.25, 0.2)
	_mat_rug.roughness = 0.9

	# Door: dark wood
	_mat_door = StandardMaterial3D.new()
	_mat_door.albedo_color = Color(0.3, 0.2, 0.1)
	_mat_door.roughness = 0.75

	# Window frame
	_mat_window_frame = StandardMaterial3D.new()
	_mat_window_frame.albedo_color = Color(0.88, 0.86, 0.84)
	_mat_window_frame.roughness = 0.8

	# Window glass: light blue tint with transparency
	_mat_window_glass = StandardMaterial3D.new()
	_mat_window_glass.albedo_color = Color(0.7, 0.8, 0.9, 0.3)
	_mat_window_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_window_glass.roughness = 0.1

	# Window backdrop: sky
	_mat_window_sky = StandardMaterial3D.new()
	_mat_window_sky.albedo_color = Color(0.5, 0.65, 0.8)
	_mat_window_sky.roughness = 0.9

	# Window backdrop: hills
	_mat_window_hills = StandardMaterial3D.new()
	_mat_window_hills.albedo_color = Color(0.3, 0.5, 0.25)
	_mat_window_hills.roughness = 0.9

	# Window backdrop: distant houses
	_mat_window_houses = StandardMaterial3D.new()
	_mat_window_houses.albedo_color = Color(0.6, 0.5, 0.4)
	_mat_window_houses.roughness = 0.9

	# Stove: dark
	_mat_stove = StandardMaterial3D.new()
	_mat_stove.albedo_color = Color(0.15, 0.15, 0.15)
	_mat_stove.roughness = 0.6

	# Kettle: metallic grey
	_mat_kettle = StandardMaterial3D.new()
	_mat_kettle.albedo_color = Color(0.6, 0.6, 0.65)
	_mat_kettle.roughness = 0.3
	_mat_kettle.metallic = 0.6

	# Fridge: white
	_mat_fridge = StandardMaterial3D.new()
	_mat_fridge.albedo_color = Color(0.92, 0.92, 0.92)
	_mat_fridge.roughness = 0.4

	# Cabinet face: white
	_mat_cabinet_face = StandardMaterial3D.new()
	_mat_cabinet_face.albedo_color = Color(0.90, 0.90, 0.90)
	_mat_cabinet_face.roughness = 0.7

	# Plate: off-white ceramic
	_mat_plate = StandardMaterial3D.new()
	_mat_plate.albedo_color = Color(0.92, 0.90, 0.86)
	_mat_plate.roughness = 0.5

	# Sandwich: tan bread
	_mat_sandwich = StandardMaterial3D.new()
	_mat_sandwich.albedo_color = Color(0.75, 0.6, 0.35)
	_mat_sandwich.roughness = 0.9

	# Portrait frame: dark wood
	_mat_portrait_frame = StandardMaterial3D.new()
	_mat_portrait_frame.albedo_color = Color(0.3, 0.2, 0.1)
	_mat_portrait_frame.roughness = 0.75

	# Portrait background: cream
	_mat_portrait_bg = StandardMaterial3D.new()
	_mat_portrait_bg.albedo_color = Color(0.9, 0.85, 0.78)
	_mat_portrait_bg.roughness = 0.9

	# Cat black
	_mat_cat_black = StandardMaterial3D.new()
	_mat_cat_black.albedo_color = Color(0.1, 0.1, 0.1)
	_mat_cat_black.roughness = 0.9

	# Cat white
	_mat_cat_white = StandardMaterial3D.new()
	_mat_cat_white.albedo_color = Color(0.95, 0.95, 0.95)
	_mat_cat_white.roughness = 0.9

	# Cat eyes: yellow
	_mat_cat_eyes = StandardMaterial3D.new()
	_mat_cat_eyes.albedo_color = Color(0.9, 0.8, 0.1)
	_mat_cat_eyes.roughness = 0.5

	# Chandelier metal
	_mat_chandelier = StandardMaterial3D.new()
	_mat_chandelier.albedo_color = Color(0.45, 0.35, 0.2)
	_mat_chandelier.roughness = 0.4
	_mat_chandelier.metallic = 0.5

	# Handle: dark metal
	_mat_handle = StandardMaterial3D.new()
	_mat_handle.albedo_color = Color(0.3, 0.28, 0.25)
	_mat_handle.roughness = 0.3
	_mat_handle.metallic = 0.7

	# Storage box: brown wood (same as campsite)
	_mat_storage_box = StandardMaterial3D.new()
	_mat_storage_box.albedo_color = Color(0.45, 0.3, 0.15)
	_mat_storage_box.roughness = 0.8


# =============================================================================
# HELPER: create a BoxMesh MeshInstance3D
# =============================================================================

func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: StandardMaterial3D, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var bm: BoxMesh = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	if rot != Vector3.ZERO:
		mi.rotation = rot
	parent.add_child(mi)
	return mi


# =============================================================================
# FLOOR & CEILING
# =============================================================================

func _build_floor_and_ceiling() -> void:
	# Floor
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.name = "Floor"
	add_child(floor_body)
	_box(floor_body, Vector3(HOUSE_WIDTH, FLOOR_THICKNESS, HOUSE_DEPTH),
		Vector3(HOUSE_WIDTH / 2.0, -FLOOR_THICKNESS / 2.0, HOUSE_DEPTH / 2.0), _mat_floor)
	var floor_col: CollisionShape3D = CollisionShape3D.new()
	var floor_shape: BoxShape3D = BoxShape3D.new()
	floor_shape.size = Vector3(HOUSE_WIDTH, FLOOR_THICKNESS, HOUSE_DEPTH)
	floor_col.shape = floor_shape
	floor_col.position = Vector3(HOUSE_WIDTH / 2.0, -FLOOR_THICKNESS / 2.0, HOUSE_DEPTH / 2.0)
	floor_body.add_child(floor_col)

	# Ceiling
	_box(self, Vector3(HOUSE_WIDTH, FLOOR_THICKNESS, HOUSE_DEPTH),
		Vector3(HOUSE_WIDTH / 2.0, CEILING_HEIGHT + FLOOR_THICKNESS / 2.0, HOUSE_DEPTH / 2.0), _mat_ceiling)


# =============================================================================
# EXTERIOR WALLS (with collision)
# =============================================================================

func _build_exterior_walls() -> void:
	# South wall (front, Z=0) — with gap for front door
	var south_wall: StaticBody3D = StaticBody3D.new()
	south_wall.name = "SouthWall"
	add_child(south_wall)
	# Left section (to the left of front door)
	# Door is at X ~2.0 in the living room (south wall of living room)
	var door_x: float = 2.0
	var door_width: float = 1.0
	# Left of door
	var left_w: float = door_x - door_width / 2.0
	if left_w > 0:
		_box(south_wall, Vector3(left_w, CEILING_HEIGHT, WALL_THICKNESS),
			Vector3(left_w / 2.0, CEILING_HEIGHT / 2.0, WALL_THICKNESS / 2.0), _mat_wall)
		_add_wall_collision(south_wall, Vector3(left_w, CEILING_HEIGHT, WALL_THICKNESS),
			Vector3(left_w / 2.0, CEILING_HEIGHT / 2.0, WALL_THICKNESS / 2.0))
	# Above door
	_box(south_wall, Vector3(door_width, CEILING_HEIGHT - 2.2, WALL_THICKNESS),
		Vector3(door_x, 2.2 + (CEILING_HEIGHT - 2.2) / 2.0, WALL_THICKNESS / 2.0), _mat_wall)
	# Right of door
	var right_start: float = door_x + door_width / 2.0
	var right_w: float = HOUSE_WIDTH - right_start
	_box(south_wall, Vector3(right_w, CEILING_HEIGHT, WALL_THICKNESS),
		Vector3(right_start + right_w / 2.0, CEILING_HEIGHT / 2.0, WALL_THICKNESS / 2.0), _mat_wall)
	_add_wall_collision(south_wall, Vector3(right_w, CEILING_HEIGHT, WALL_THICKNESS),
		Vector3(right_start + right_w / 2.0, CEILING_HEIGHT / 2.0, WALL_THICKNESS / 2.0))
	# Door frame collision (above door only, sides are wall collision)
	_add_wall_collision(south_wall, Vector3(door_width, CEILING_HEIGHT - 2.2, WALL_THICKNESS),
		Vector3(door_x, 2.2 + (CEILING_HEIGHT - 2.2) / 2.0, WALL_THICKNESS / 2.0))

	# North wall (Z = HOUSE_DEPTH)
	_add_wall_with_collision("NorthWall", Vector3(HOUSE_WIDTH, CEILING_HEIGHT, WALL_THICKNESS),
		Vector3(HOUSE_WIDTH / 2.0, CEILING_HEIGHT / 2.0, HOUSE_DEPTH - WALL_THICKNESS / 2.0))

	# West wall (X = 0)
	_add_wall_with_collision("WestWall", Vector3(WALL_THICKNESS, CEILING_HEIGHT, HOUSE_DEPTH),
		Vector3(WALL_THICKNESS / 2.0, CEILING_HEIGHT / 2.0, HOUSE_DEPTH / 2.0))

	# East wall (X = HOUSE_WIDTH)
	_add_wall_with_collision("EastWall", Vector3(WALL_THICKNESS, CEILING_HEIGHT, HOUSE_DEPTH),
		Vector3(HOUSE_WIDTH - WALL_THICKNESS / 2.0, CEILING_HEIGHT / 2.0, HOUSE_DEPTH / 2.0))


func _add_wall_with_collision(wall_name: String, size: Vector3, pos: Vector3) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = wall_name
	add_child(body)
	_box(body, size, pos, _mat_wall)
	_add_wall_collision(body, size, pos)


func _add_wall_collision(body: StaticBody3D, size: Vector3, pos: Vector3) -> void:
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = pos
	body.add_child(col)


# =============================================================================
# INTERIOR WALLS
# =============================================================================

func _build_interior_walls() -> void:
	# Center divider: separates living room/kitchen (left) from dining room (right)
	# Runs along X = LIVING_ROOM_WIDTH from Z=0 to Z=HOUSE_DEPTH
	_add_wall_with_collision("CenterDivider",
		Vector3(WALL_THICKNESS, CEILING_HEIGHT, HOUSE_DEPTH),
		Vector3(LIVING_ROOM_WIDTH, CEILING_HEIGHT / 2.0, HOUSE_DEPTH / 2.0))

	# Horizontal divider: separates living room (south) from kitchen (north)
	# Runs along Z = LIVING_ROOM_DEPTH from X=0 to X=LIVING_ROOM_WIDTH
	# Leave a doorway opening (2 units wide centered in the wall)
	var doorway_width: float = 2.0
	var wall_center_x: float = LIVING_ROOM_WIDTH / 2.0
	var left_section_w: float = wall_center_x - doorway_width / 2.0
	var right_section_w: float = LIVING_ROOM_WIDTH - (wall_center_x + doorway_width / 2.0)

	# Left section of horizontal divider
	if left_section_w > 0:
		_add_wall_with_collision("KitchenDividerLeft",
			Vector3(left_section_w, CEILING_HEIGHT, WALL_THICKNESS),
			Vector3(left_section_w / 2.0, CEILING_HEIGHT / 2.0, LIVING_ROOM_DEPTH))

	# Right section of horizontal divider
	if right_section_w > 0:
		_add_wall_with_collision("KitchenDividerRight",
			Vector3(right_section_w, CEILING_HEIGHT, WALL_THICKNESS),
			Vector3(wall_center_x + doorway_width / 2.0 + right_section_w / 2.0, CEILING_HEIGHT / 2.0, LIVING_ROOM_DEPTH))

	# Above doorway
	_add_wall_with_collision("KitchenDividerTop",
		Vector3(doorway_width, CEILING_HEIGHT - 2.2, WALL_THICKNESS),
		Vector3(wall_center_x, 2.2 + (CEILING_HEIGHT - 2.2) / 2.0, LIVING_ROOM_DEPTH))


# =============================================================================
# CROWN MOLDING
# =============================================================================

func _build_crown_molding() -> void:
	var molding_height: float = 0.06
	var molding_depth: float = 0.04
	var y: float = CEILING_HEIGHT - molding_height / 2.0

	# Living room molding (X: 0 to LIVING_ROOM_WIDTH, Z: 0 to LIVING_ROOM_DEPTH)
	# South wall
	_box(self, Vector3(LIVING_ROOM_WIDTH, molding_height, molding_depth),
		Vector3(LIVING_ROOM_WIDTH / 2.0, y, molding_depth / 2.0 + WALL_THICKNESS), _mat_molding)
	# West wall
	_box(self, Vector3(molding_depth, molding_height, LIVING_ROOM_DEPTH),
		Vector3(WALL_THICKNESS + molding_depth / 2.0, y, LIVING_ROOM_DEPTH / 2.0), _mat_molding)
	# North wall (kitchen divider)
	_box(self, Vector3(LIVING_ROOM_WIDTH, molding_height, molding_depth),
		Vector3(LIVING_ROOM_WIDTH / 2.0, y, LIVING_ROOM_DEPTH - molding_depth / 2.0), _mat_molding)
	# East wall (center divider)
	_box(self, Vector3(molding_depth, molding_height, LIVING_ROOM_DEPTH),
		Vector3(LIVING_ROOM_WIDTH - molding_depth / 2.0, y, LIVING_ROOM_DEPTH / 2.0), _mat_molding)

	# Kitchen molding (X: 0 to LIVING_ROOM_WIDTH, Z: LIVING_ROOM_DEPTH to HOUSE_DEPTH)
	# West wall
	_box(self, Vector3(molding_depth, molding_height, KITCHEN_DEPTH),
		Vector3(WALL_THICKNESS + molding_depth / 2.0, y, LIVING_ROOM_DEPTH + KITCHEN_DEPTH / 2.0), _mat_molding)
	# North wall
	_box(self, Vector3(LIVING_ROOM_WIDTH, molding_height, molding_depth),
		Vector3(LIVING_ROOM_WIDTH / 2.0, y, HOUSE_DEPTH - WALL_THICKNESS - molding_depth / 2.0), _mat_molding)
	# East wall (center divider, kitchen side)
	_box(self, Vector3(molding_depth, molding_height, KITCHEN_DEPTH),
		Vector3(LIVING_ROOM_WIDTH - molding_depth / 2.0, y, LIVING_ROOM_DEPTH + KITCHEN_DEPTH / 2.0), _mat_molding)

	# Dining room molding (X: LIVING_ROOM_WIDTH to HOUSE_WIDTH, Z: 0 to HOUSE_DEPTH)
	# South wall
	_box(self, Vector3(DINING_ROOM_WIDTH, molding_height, molding_depth),
		Vector3(LIVING_ROOM_WIDTH + DINING_ROOM_WIDTH / 2.0, y, molding_depth / 2.0 + WALL_THICKNESS), _mat_molding)
	# East wall
	_box(self, Vector3(molding_depth, molding_height, HOUSE_DEPTH),
		Vector3(HOUSE_WIDTH - WALL_THICKNESS - molding_depth / 2.0, y, HOUSE_DEPTH / 2.0), _mat_molding)
	# North wall
	_box(self, Vector3(DINING_ROOM_WIDTH, molding_height, molding_depth),
		Vector3(LIVING_ROOM_WIDTH + DINING_ROOM_WIDTH / 2.0, y, HOUSE_DEPTH - WALL_THICKNESS - molding_depth / 2.0), _mat_molding)
	# West wall (center divider, dining side)
	_box(self, Vector3(molding_depth, molding_height, HOUSE_DEPTH),
		Vector3(LIVING_ROOM_WIDTH + molding_depth / 2.0, y, HOUSE_DEPTH / 2.0), _mat_molding)


# =============================================================================
# WINDOWS (six-pane colonial)
# =============================================================================

func _build_windows() -> void:
	# Living room: 1 window on south wall (right of door), 1 on west wall
	_build_window_on_wall("south", Vector3(4.5, 1.2, 0.0))  # South wall, right of door
	_build_window_on_wall("west", Vector3(0.0, 1.2, 2.0))   # West wall

	# Kitchen: 1 window on north wall, 1 on west wall
	_build_window_on_wall("north", Vector3(3.0, 1.2, HOUSE_DEPTH))   # North wall
	_build_window_on_wall("west", Vector3(0.0, 1.2, 7.5))   # West wall

	# Dining room: 2 windows on east wall, 1 on south wall
	_build_window_on_wall("east", Vector3(HOUSE_WIDTH, 1.2, 2.5))  # East wall
	_build_window_on_wall("east", Vector3(HOUSE_WIDTH, 1.2, 7.0))  # East wall
	_build_window_on_wall("south", Vector3(9.0, 1.2, 0.0))         # South wall


func _build_window_on_wall(wall: String, base_pos: Vector3) -> void:
	var window_container: Node3D = Node3D.new()
	window_container.name = "Window"
	add_child(window_container)

	var win_width: float = 1.0
	var win_height: float = 1.4
	var frame_thickness: float = 0.04
	var mullion_width: float = 0.03

	# Determine orientation and position
	var frame_pos: Vector3 = base_pos
	var frame_size: Vector3
	var glass_size: Vector3
	var backdrop_offset: Vector3
	var is_ns: bool = (wall == "south" or wall == "north")

	if is_ns:
		frame_size = Vector3(win_width, win_height, frame_thickness)
		glass_size = Vector3(win_width - frame_thickness * 2, win_height - frame_thickness * 2, 0.01)
		if wall == "south":
			backdrop_offset = Vector3(0, 0, -0.02)
		else:
			backdrop_offset = Vector3(0, 0, 0.02)
	else:
		frame_size = Vector3(frame_thickness, win_height, win_width)
		glass_size = Vector3(0.01, win_height - frame_thickness * 2, win_width - frame_thickness * 2)
		if wall == "west":
			backdrop_offset = Vector3(-0.02, 0, 0)
		else:
			backdrop_offset = Vector3(0.02, 0, 0)

	# Outer frame
	_box(window_container, frame_size, frame_pos, _mat_window_frame)

	# Backdrop: sky (upper half)
	var sky_center: Vector3 = frame_pos + backdrop_offset
	sky_center.y += win_height * 0.25
	if is_ns:
		_box(window_container, Vector3(win_width - 0.1, win_height * 0.5, 0.01), sky_center, _mat_window_sky)
	else:
		_box(window_container, Vector3(0.01, win_height * 0.5, win_width - 0.1), sky_center, _mat_window_sky)

	# Backdrop: green hills (lower half)
	var hills_center: Vector3 = frame_pos + backdrop_offset
	hills_center.y -= win_height * 0.15
	if is_ns:
		_box(window_container, Vector3(win_width - 0.1, win_height * 0.35, 0.01), hills_center, _mat_window_hills)
	else:
		_box(window_container, Vector3(0.01, win_height * 0.35, win_width - 0.1), hills_center, _mat_window_hills)

	# Distant houses (small brown boxes on hills)
	for i: int in range(3):
		var house_pos: Vector3 = hills_center + backdrop_offset * 0.5
		house_pos.y += 0.08
		if is_ns:
			house_pos.x += (float(i) - 1.0) * 0.2
			_box(window_container, Vector3(0.08, 0.06, 0.01), house_pos, _mat_window_houses)
		else:
			house_pos.z += (float(i) - 1.0) * 0.2
			_box(window_container, Vector3(0.01, 0.06, 0.08), house_pos, _mat_window_houses)

	# Glass pane (semi-transparent, in front of backdrop)
	var glass_pos: Vector3 = frame_pos
	if wall == "south":
		glass_pos.z += 0.01
	elif wall == "north":
		glass_pos.z -= 0.01
	elif wall == "west":
		glass_pos.x += 0.01
	else:
		glass_pos.x -= 0.01
	_box(window_container, glass_size, glass_pos, _mat_window_glass)

	# Mullions (6-pane: 2 vertical + 1 horizontal)
	var mullion_offset: Vector3 = glass_pos
	if is_ns:
		# Horizontal mullion (center)
		_box(window_container, Vector3(win_width - 0.06, mullion_width, 0.02), mullion_offset, _mat_window_frame)
		# Vertical mullion left
		var v_left: Vector3 = mullion_offset
		v_left.x -= win_width / 6.0
		_box(window_container, Vector3(mullion_width, win_height - 0.06, 0.02), v_left, _mat_window_frame)
		# Vertical mullion right
		var v_right: Vector3 = mullion_offset
		v_right.x += win_width / 6.0
		_box(window_container, Vector3(mullion_width, win_height - 0.06, 0.02), v_right, _mat_window_frame)
	else:
		# Horizontal mullion (center)
		_box(window_container, Vector3(0.02, mullion_width, win_width - 0.06), mullion_offset, _mat_window_frame)
		# Vertical mullion top
		var v_top: Vector3 = mullion_offset
		v_top.z -= win_width / 6.0
		_box(window_container, Vector3(0.02, win_height - 0.06, mullion_width), v_top, _mat_window_frame)
		# Vertical mullion bottom
		var v_bot: Vector3 = mullion_offset
		v_bot.z += win_width / 6.0
		_box(window_container, Vector3(0.02, win_height - 0.06, mullion_width), v_bot, _mat_window_frame)


# =============================================================================
# FRONT DOOR
# =============================================================================

func _build_front_door() -> void:
	var door_x: float = 2.0
	var door_body: StaticBody3D = StaticBody3D.new()
	door_body.name = "FrontDoor"
	door_body.set_script(_create_interactable_script(
		"Open Front Door",
		"front_door"
	))

	# Door panel
	_box(door_body, Vector3(1.0, 2.2, 0.08),
		Vector3(door_x, 1.1, WALL_THICKNESS / 2.0), _mat_door)

	# Door handle
	_box(door_body, Vector3(0.04, 0.12, 0.05),
		Vector3(door_x + 0.35, 1.0, WALL_THICKNESS / 2.0 + 0.04), _mat_handle)

	# Collision for interaction raycast
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(1.0, 2.2, 0.15)
	col.shape = shape
	col.position = Vector3(door_x, 1.1, WALL_THICKNESS / 2.0)
	door_body.add_child(col)

	add_child(door_body)


# =============================================================================
# LIVING ROOM FURNITURE
# =============================================================================

func _build_living_room_furniture() -> void:
	# Room bounds: X 0..6, Z 0..5
	var room_cx: float = LIVING_ROOM_WIDTH / 2.0  # 3.0
	var room_cz: float = LIVING_ROOM_DEPTH / 2.0  # 2.5

	# --- Rug ---
	_box(self, Vector3(2.5, 0.02, 1.8),
		Vector3(room_cx, 0.01, room_cz), _mat_rug)

	# --- Couch (against west wall, facing east) ---
	var couch_container: Node3D = Node3D.new()
	couch_container.name = "Couch"
	add_child(couch_container)
	var couch_x: float = 1.5
	var couch_z: float = room_cz
	# Seat
	_box(couch_container, Vector3(2.0, 0.4, 0.8),
		Vector3(couch_x, 0.4, couch_z), _mat_upholstery)
	# Back
	_box(couch_container, Vector3(2.0, 0.5, 0.15),
		Vector3(couch_x, 0.65, couch_z - 0.4 + 0.075), _mat_upholstery)
	# Left arm
	_box(couch_container, Vector3(0.15, 0.5, 0.8),
		Vector3(couch_x - 1.0 + 0.075, 0.55, couch_z), _mat_upholstery)
	# Right arm
	_box(couch_container, Vector3(0.15, 0.5, 0.8),
		Vector3(couch_x + 1.0 - 0.075, 0.55, couch_z), _mat_upholstery)

	# --- Coffee Table (in front of couch) ---
	var table_container: Node3D = Node3D.new()
	table_container.name = "CoffeeTable"
	add_child(table_container)
	var table_x: float = room_cx + 0.5
	var table_z: float = room_cz
	# Table top
	_box(table_container, Vector3(1.2, 0.05, 0.6),
		Vector3(table_x, 0.4, table_z), _mat_furniture_wood)
	# 4 legs
	for lx: float in [-0.5, 0.5]:
		for lz: float in [-0.22, 0.22]:
			_box(table_container, Vector3(0.05, 0.35, 0.05),
				Vector3(table_x + lx, 0.175, table_z + lz), _mat_furniture_wood)

	# --- Bookshelves (against kitchen divider wall, north side of living room) ---
	_build_bookshelf(Vector3(2.0, 0.0, LIVING_ROOM_DEPTH - 0.5))

	# --- Wilderness Storage Box ---
	_build_storage_box(Vector3(4.8, 0.0, 1.0))


func _build_bookshelf(pos: Vector3) -> void:
	var shelf_body: StaticBody3D = StaticBody3D.new()
	shelf_body.name = "Bookshelves"
	shelf_body.set_script(_create_interactable_script(
		"Browse Books",
		"bookshelves"
	))

	# Back panel
	_box(shelf_body, Vector3(1.5, 2.0, 0.05),
		Vector3(pos.x, 1.0, pos.z), _mat_furniture_wood)

	# 4 shelf boards
	for i: int in range(4):
		var shelf_y: float = 0.05 + float(i) * 0.5
		_box(shelf_body, Vector3(1.5, 0.04, 0.3),
			Vector3(pos.x, shelf_y, pos.z + 0.15), _mat_furniture_wood)

	# Colored book spines on each shelf
	var book_colors: Array[Color] = [
		Color(0.6, 0.15, 0.15),  # Red
		Color(0.15, 0.4, 0.15),  # Green
		Color(0.15, 0.2, 0.5),   # Blue
		Color(0.55, 0.45, 0.1),  # Gold
		Color(0.4, 0.15, 0.4),   # Purple
		Color(0.5, 0.3, 0.15),   # Brown
		Color(0.2, 0.35, 0.35),  # Teal
		Color(0.6, 0.3, 0.1),    # Orange
	]

	var book_mat_cache: Dictionary = {}
	for shelf_i: int in range(4):
		var shelf_y: float = 0.05 + float(shelf_i) * 0.5 + 0.02
		var book_x: float = pos.x - 0.6
		for book_i: int in range(6):
			var color_idx: int = (shelf_i * 6 + book_i) % book_colors.size()
			var book_color: Color = book_colors[color_idx]
			var color_key: String = str(color_idx)
			if not book_mat_cache.has(color_key):
				var bmat: StandardMaterial3D = StandardMaterial3D.new()
				bmat.albedo_color = book_color
				bmat.roughness = 0.9
				book_mat_cache[color_key] = bmat
			var book_height: float = 0.35 + randf() * 0.1  # Slight height variation
			var book_width: float = 0.06 + randf() * 0.04
			_box(shelf_body, Vector3(book_width, book_height, 0.2),
				Vector3(book_x, shelf_y + book_height / 2.0, pos.z + 0.15), book_mat_cache[color_key])
			book_x += book_width + 0.02

	# Collision for interaction
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(1.5, 2.0, 0.4)
	col.shape = shape
	col.position = Vector3(pos.x, 1.0, pos.z + 0.1)
	shelf_body.add_child(col)

	add_child(shelf_body)


func _build_storage_box(pos: Vector3) -> void:
	var box_body: StaticBody3D = StaticBody3D.new()
	box_body.name = "StorageBox"
	box_body.set_script(_create_interactable_script(
		"View Wilderness Inventory",
		"storage_box"
	))

	# Main box
	_box(box_body, Vector3(0.6, 0.5, 0.6),
		Vector3(pos.x, 0.25, pos.z), _mat_storage_box)
	# Lid (slightly wider)
	_box(box_body, Vector3(0.64, 0.04, 0.64),
		Vector3(pos.x, 0.52, pos.z), _mat_furniture_wood)
	# Lid handle
	_box(box_body, Vector3(0.15, 0.03, 0.04),
		Vector3(pos.x, 0.56, pos.z), _mat_handle)

	# Collision
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(0.64, 0.56, 0.64)
	col.shape = shape
	col.position = Vector3(pos.x, 0.28, pos.z)
	box_body.add_child(col)

	add_child(box_body)


# =============================================================================
# KITCHEN FURNITURE
# =============================================================================

func _build_kitchen_furniture() -> void:
	# Kitchen bounds: X 0..6, Z 5..10
	var kitchen_z_start: float = LIVING_ROOM_DEPTH

	# --- Counter (against north wall) ---
	var counter_x: float = 2.5
	var counter_z: float = HOUSE_DEPTH - 0.6
	# Counter top (wood)
	_box(self, Vector3(2.5, 0.05, 0.6),
		Vector3(counter_x, 0.9, counter_z), _mat_furniture_wood)
	# Counter base
	_box(self, Vector3(2.5, 0.85, 0.6),
		Vector3(counter_x, 0.425, counter_z), _mat_cabinet_face)
	# Cabinet face details (2 doors)
	_box(self, Vector3(1.1, 0.7, 0.02),
		Vector3(counter_x - 0.55, 0.4, counter_z + 0.31), _mat_cabinet_face)
	_box(self, Vector3(1.1, 0.7, 0.02),
		Vector3(counter_x + 0.55, 0.4, counter_z + 0.31), _mat_cabinet_face)
	# Cabinet handles
	_box(self, Vector3(0.12, 0.02, 0.03),
		Vector3(counter_x - 0.15, 0.5, counter_z + 0.33), _mat_handle)
	_box(self, Vector3(0.12, 0.02, 0.03),
		Vector3(counter_x + 0.15, 0.5, counter_z + 0.33), _mat_handle)

	# --- Stove (next to counter, against north wall) ---
	var stove_x: float = 4.3
	var stove_z: float = HOUSE_DEPTH - 0.6
	_box(self, Vector3(0.6, 0.9, 0.6),
		Vector3(stove_x, 0.45, stove_z), _mat_stove)
	# 4 burners on top
	for bx: float in [-0.12, 0.12]:
		for bz: float in [-0.12, 0.12]:
			_box(self, Vector3(0.12, 0.02, 0.12),
				Vector3(stove_x + bx, 0.91, stove_z + bz), _mat_handle)

	# --- Kettle (on stove) ---
	var kettle_body: StaticBody3D = StaticBody3D.new()
	kettle_body.name = "Kettle"
	kettle_body.set_script(_create_interactable_script(
		"Make Tea",
		"kettle"
	))
	_box(kettle_body, Vector3(0.15, 0.2, 0.1),
		Vector3(stove_x + 0.1, 1.02, stove_z - 0.1), _mat_kettle)
	# Kettle handle (small arc = thin box on top)
	_box(kettle_body, Vector3(0.08, 0.02, 0.06),
		Vector3(stove_x + 0.1, 1.13, stove_z - 0.1), _mat_handle)
	# Kettle spout
	_box(kettle_body, Vector3(0.03, 0.04, 0.06),
		Vector3(stove_x + 0.1 + 0.08, 1.08, stove_z - 0.1), _mat_kettle)
	# Collision
	var kettle_col: CollisionShape3D = CollisionShape3D.new()
	var kettle_shape: BoxShape3D = BoxShape3D.new()
	kettle_shape.size = Vector3(0.2, 0.25, 0.15)
	kettle_col.shape = kettle_shape
	kettle_col.position = Vector3(stove_x + 0.1, 1.05, stove_z - 0.1)
	kettle_body.add_child(kettle_col)
	add_child(kettle_body)

	# --- Fridge (against west wall) ---
	var fridge_x: float = 0.55
	var fridge_z: float = kitchen_z_start + 1.5
	_box(self, Vector3(0.8, 1.8, 0.7),
		Vector3(fridge_x, 0.9, fridge_z), _mat_fridge)
	# Fridge handle
	_box(self, Vector3(0.02, 0.3, 0.04),
		Vector3(fridge_x + 0.38, 1.2, fridge_z + 0.36), _mat_handle)


# =============================================================================
# DINING ROOM FURNITURE
# =============================================================================

func _build_dining_room_furniture() -> void:
	# Dining room bounds: X 6..12, Z 0..10
	var dining_cx: float = LIVING_ROOM_WIDTH + DINING_ROOM_WIDTH / 2.0  # 9.0
	var dining_cz: float = HOUSE_DEPTH / 2.0  # 5.0

	# --- Dining Table ---
	var table_x: float = dining_cx
	var table_z: float = dining_cz
	# Table top
	_box(self, Vector3(1.8, 0.05, 1.0),
		Vector3(table_x, 0.75, table_z), _mat_furniture_wood)
	# 4 legs
	for lx: float in [-0.8, 0.8]:
		for lz: float in [-0.4, 0.4]:
			_box(self, Vector3(0.06, 0.7, 0.06),
				Vector3(table_x + lx, 0.35, table_z + lz), _mat_furniture_wood)

	# --- 4 Chairs ---
	_build_chair(Vector3(table_x - 0.5, 0.0, table_z + 0.8), 0.0)      # South side
	_build_chair(Vector3(table_x + 0.5, 0.0, table_z + 0.8), 0.0)      # South side
	_build_chair(Vector3(table_x - 0.5, 0.0, table_z - 0.8), PI)       # North side (rotated)
	_build_chair(Vector3(table_x + 0.5, 0.0, table_z - 0.8), PI)       # North side (rotated)

	# --- Sandwich Plate on Table ---
	_build_sandwich(Vector3(table_x + 0.3, 0.78, table_z - 0.1))

	# --- Chandelier ---
	_build_chandelier(Vector3(dining_cx, CEILING_HEIGHT, dining_cz))


func _build_chair(pos: Vector3, rot_y: float) -> void:
	var chair: Node3D = Node3D.new()
	chair.position = pos
	chair.rotation.y = rot_y
	add_child(chair)

	# Seat
	_box(chair, Vector3(0.4, 0.05, 0.4),
		Vector3(0, 0.45, 0), _mat_furniture_wood)
	# Back
	_box(chair, Vector3(0.4, 0.5, 0.05),
		Vector3(0, 0.7, -0.175), _mat_furniture_wood)
	# 4 legs
	for lx: float in [-0.15, 0.15]:
		for lz: float in [-0.15, 0.15]:
			_box(chair, Vector3(0.04, 0.42, 0.04),
				Vector3(lx, 0.21, lz), _mat_furniture_wood)


func _build_sandwich(pos: Vector3) -> void:
	var sandwich_body: StaticBody3D = StaticBody3D.new()
	sandwich_body.name = "Sandwich"
	sandwich_body.set_script(_create_interactable_script(
		"Eat Sandwich",
		"sandwich"
	))

	# Plate
	_box(sandwich_body, Vector3(0.25, 0.02, 0.25),
		Vector3(pos.x, pos.y, pos.z), _mat_plate)
	# Sandwich
	_box(sandwich_body, Vector3(0.12, 0.06, 0.1),
		Vector3(pos.x, pos.y + 0.04, pos.z), _mat_sandwich)
	# Lettuce peeking out (thin green strip)
	var mat_lettuce: StandardMaterial3D = StandardMaterial3D.new()
	mat_lettuce.albedo_color = Color(0.3, 0.55, 0.2)
	mat_lettuce.roughness = 0.9
	_box(sandwich_body, Vector3(0.13, 0.01, 0.11),
		Vector3(pos.x, pos.y + 0.04, pos.z), mat_lettuce)

	# Collision
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(0.25, 0.1, 0.25)
	col.shape = shape
	col.position = Vector3(pos.x, pos.y + 0.03, pos.z)
	sandwich_body.add_child(col)

	add_child(sandwich_body)


func _build_chandelier(pos: Vector3) -> void:
	var chandelier: Node3D = Node3D.new()
	chandelier.name = "Chandelier"
	add_child(chandelier)

	# Central rod from ceiling
	_box(chandelier, Vector3(0.03, 0.4, 0.03),
		Vector3(pos.x, pos.y - 0.2, pos.z), _mat_chandelier)

	# Horizontal arms (cross shape)
	_box(chandelier, Vector3(0.6, 0.03, 0.03),
		Vector3(pos.x, pos.y - 0.4, pos.z), _mat_chandelier)
	_box(chandelier, Vector3(0.03, 0.03, 0.6),
		Vector3(pos.x, pos.y - 0.4, pos.z), _mat_chandelier)

	# 4 light holder boxes at arm ends
	var light_offsets: Array[Vector3] = [
		Vector3(0.28, -0.45, 0),
		Vector3(-0.28, -0.45, 0),
		Vector3(0, -0.45, 0.28),
		Vector3(0, -0.45, -0.28),
	]
	var mat_light_bulb: StandardMaterial3D = StandardMaterial3D.new()
	mat_light_bulb.albedo_color = Color(1.0, 0.95, 0.8)
	mat_light_bulb.emission_enabled = true
	mat_light_bulb.emission = Color(1.0, 0.92, 0.75)
	mat_light_bulb.emission_energy_multiplier = 2.0

	for offset: Vector3 in light_offsets:
		_box(chandelier, Vector3(0.06, 0.06, 0.06),
			Vector3(pos.x + offset.x, pos.y + offset.y, pos.z + offset.z), mat_light_bulb)


# =============================================================================
# CAT PORTRAITS
# =============================================================================

func _build_cat_portraits() -> void:
	# On the west wall of the living room, at eye height
	var wall_x: float = WALL_THICKNESS + 0.03  # Slightly off wall

	# Portrait 1: All-black cat — position on west wall
	_build_cat_portrait_black(Vector3(wall_x, 1.6, 1.2))

	# Portrait 2: Tuxedo cat — next to first
	_build_cat_portrait_tuxedo(Vector3(wall_x, 1.6, 2.0))


func _build_cat_portrait_black(pos: Vector3) -> void:
	var portrait: Node3D = Node3D.new()
	portrait.name = "BlackCatPortrait"
	add_child(portrait)

	# Frame (oriented on west wall, facing +X)
	_box(portrait, Vector3(0.03, 0.6, 0.5), pos, _mat_portrait_frame)
	# Background
	_box(portrait, Vector3(0.02, 0.54, 0.44),
		Vector3(pos.x + 0.01, pos.y, pos.z), _mat_portrait_bg)

	# Cat body (centered on background)
	_box(portrait, Vector3(0.02, 0.15, 0.2),
		Vector3(pos.x + 0.02, pos.y - 0.1, pos.z), _mat_cat_black)
	# Cat head
	_box(portrait, Vector3(0.02, 0.12, 0.12),
		Vector3(pos.x + 0.02, pos.y + 0.04, pos.z), _mat_cat_black)
	# Left ear
	_box(portrait, Vector3(0.02, 0.05, 0.04),
		Vector3(pos.x + 0.02, pos.y + 0.12, pos.z - 0.05), _mat_cat_black)
	# Right ear
	_box(portrait, Vector3(0.02, 0.05, 0.04),
		Vector3(pos.x + 0.02, pos.y + 0.12, pos.z + 0.05), _mat_cat_black)
	# Left eye
	_box(portrait, Vector3(0.025, 0.025, 0.025),
		Vector3(pos.x + 0.025, pos.y + 0.05, pos.z - 0.025), _mat_cat_eyes)
	# Right eye
	_box(portrait, Vector3(0.025, 0.025, 0.025),
		Vector3(pos.x + 0.025, pos.y + 0.05, pos.z + 0.025), _mat_cat_eyes)

	# Tail (small curved box)
	_box(portrait, Vector3(0.02, 0.04, 0.15),
		Vector3(pos.x + 0.02, pos.y - 0.12, pos.z + 0.12), _mat_cat_black)


func _build_cat_portrait_tuxedo(pos: Vector3) -> void:
	var portrait: Node3D = Node3D.new()
	portrait.name = "TuxedoCatPortrait"
	add_child(portrait)

	# Frame
	_box(portrait, Vector3(0.03, 0.6, 0.5), pos, _mat_portrait_frame)
	# Background
	_box(portrait, Vector3(0.02, 0.54, 0.44),
		Vector3(pos.x + 0.01, pos.y, pos.z), _mat_portrait_bg)

	# Cat body (black)
	_box(portrait, Vector3(0.02, 0.15, 0.2),
		Vector3(pos.x + 0.02, pos.y - 0.1, pos.z), _mat_cat_black)
	# White chest overlay
	_box(portrait, Vector3(0.025, 0.1, 0.1),
		Vector3(pos.x + 0.025, pos.y - 0.08, pos.z), _mat_cat_white)
	# Cat head (black)
	_box(portrait, Vector3(0.02, 0.12, 0.12),
		Vector3(pos.x + 0.02, pos.y + 0.04, pos.z), _mat_cat_black)
	# White chin
	_box(portrait, Vector3(0.025, 0.04, 0.06),
		Vector3(pos.x + 0.025, pos.y + 0.0, pos.z), _mat_cat_white)
	# Left ear
	_box(portrait, Vector3(0.02, 0.05, 0.04),
		Vector3(pos.x + 0.02, pos.y + 0.12, pos.z - 0.05), _mat_cat_black)
	# Right ear
	_box(portrait, Vector3(0.02, 0.05, 0.04),
		Vector3(pos.x + 0.02, pos.y + 0.12, pos.z + 0.05), _mat_cat_black)
	# Left eye
	_box(portrait, Vector3(0.025, 0.025, 0.025),
		Vector3(pos.x + 0.025, pos.y + 0.05, pos.z - 0.025), _mat_cat_eyes)
	# Right eye
	_box(portrait, Vector3(0.025, 0.025, 0.025),
		Vector3(pos.x + 0.025, pos.y + 0.05, pos.z + 0.025), _mat_cat_eyes)

	# Tail
	_box(portrait, Vector3(0.02, 0.04, 0.15),
		Vector3(pos.x + 0.02, pos.y - 0.12, pos.z + 0.12), _mat_cat_black)


# =============================================================================
# LIGHTING
# =============================================================================

func _setup_lighting() -> void:
	# Living room lights (2 warm lamps)
	_add_light("LivingLight1", Vector3(2.0, 2.5, 1.5),
		Color(1.0, 0.9, 0.7), 0.8, 6.0)
	_add_light("LivingLight2", Vector3(4.0, 2.5, 3.5),
		Color(1.0, 0.9, 0.7), 0.8, 6.0)

	# Kitchen light
	_add_light("KitchenLight", Vector3(3.0, 2.5, 7.5),
		Color(1.0, 0.9, 0.7), 1.0, 5.0)

	# Dining room light (from chandelier)
	var dining_cx: float = LIVING_ROOM_WIDTH + DINING_ROOM_WIDTH / 2.0
	_add_light("DiningLight", Vector3(dining_cx, 2.4, HOUSE_DEPTH / 2.0),
		Color(1.0, 0.92, 0.75), 0.9, 6.0)

	# Extra fill light for dining room south end
	_add_light("DiningFill", Vector3(dining_cx, 2.5, 2.0),
		Color(1.0, 0.9, 0.7), 0.5, 5.0)


func _add_light(light_name: String, pos: Vector3, color: Color, energy: float, light_range: float) -> void:
	var light: OmniLight3D = OmniLight3D.new()
	light.name = light_name
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	light.shadow_enabled = false  # No shadows for indoor lamps (performance)
	add_child(light)


# =============================================================================
# ENVIRONMENT
# =============================================================================

func _setup_environment() -> void:
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.05, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.25, 0.2)
	env.ambient_light_energy = 0.3
	env.fog_enabled = false

	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = env
	add_child(world_env)


# =============================================================================
# PLAYER
# =============================================================================

func _create_player() -> void:
	var player: CharacterBody3D = CharacterBody3D.new()
	player.name = "HousePlayer"
	player.set_script(HousePlayer)
	# Spawn in the living room, facing into the room
	player.position = Vector3(2.0, 0.0, 2.0)
	add_child(player)


# =============================================================================
# TEXT OVERLAY (reusable for interactable messages)
# =============================================================================

func _build_text_overlay() -> void:
	_text_overlay_canvas = CanvasLayer.new()
	_text_overlay_canvas.layer = 100
	_text_overlay_canvas.visible = false
	add_child(_text_overlay_canvas)

	# Semi-transparent background
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.4)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_text_overlay_canvas.add_child(bg)

	# Centered panel
	_text_overlay_panel = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.75)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 30.0
	style.content_margin_right = 30.0
	style.content_margin_top = 20.0
	style.content_margin_bottom = 20.0
	_text_overlay_panel.add_theme_stylebox_override("panel", style)
	_text_overlay_panel.anchor_left = 0.25
	_text_overlay_panel.anchor_right = 0.75
	_text_overlay_panel.anchor_top = 0.4
	_text_overlay_panel.anchor_bottom = 0.6
	_text_overlay_panel.offset_left = 0.0
	_text_overlay_panel.offset_right = 0.0
	_text_overlay_panel.offset_top = 0.0
	_text_overlay_panel.offset_bottom = 0.0
	_text_overlay_canvas.add_child(_text_overlay_panel)

	_text_overlay_label = Label.new()
	_text_overlay_label.add_theme_font_override("font", HUD_FONT)
	_text_overlay_label.add_theme_font_size_override("font_size", 36)
	_text_overlay_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	_text_overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text_overlay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text_overlay_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_overlay_panel.add_child(_text_overlay_label)


func show_text_overlay(text: String, duration: float = 2.0) -> void:
	_text_overlay_label.text = text
	_text_overlay_canvas.visible = true
	_text_overlay_timer = duration
	_text_overlay_active = true

	# Freeze the player
	var player: Node = get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_resting"):
		player.set_resting(true, self)


func _hide_text_overlay() -> void:
	_text_overlay_canvas.visible = false
	_text_overlay_active = false

	# Unfreeze the player
	var player: Node = get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_resting"):
		player.set_resting(false)


# =============================================================================
# FADE-IN
# =============================================================================

func _start_fade_in() -> void:
	var fade_canvas: CanvasLayer = CanvasLayer.new()
	fade_canvas.layer = 200
	add_child(fade_canvas)
	var fade_rect: ColorRect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 1)  # Start fully black
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_canvas.add_child(fade_rect)
	var tween: Tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 2.0)
	tween.tween_callback(fade_rect.queue_free)
	tween.tween_callback(fade_canvas.queue_free)


# =============================================================================
# JOURNEY INVENTORY & NEW GAME+ UI
# =============================================================================

var _journey_inventory_ui: Node = null
var _new_game_plus_ui: Node = null


func open_journey_inventory(player: Node) -> void:
	## Opens the read-only wilderness inventory viewer.
	if _journey_inventory_ui and is_instance_valid(_journey_inventory_ui):
		return  # Already open
	var script: GDScript = load("res://scripts/house/journey_inventory_ui.gd")
	_journey_inventory_ui = CanvasLayer.new()
	_journey_inventory_ui.set_script(script)
	add_child(_journey_inventory_ui)
	_journey_inventory_ui.open(player)


func open_new_game_plus(player: Node) -> void:
	## Opens the New Game+ item selection UI.
	if _new_game_plus_ui and is_instance_valid(_new_game_plus_ui):
		return  # Already open
	var script: GDScript = load("res://scripts/house/new_game_plus_ui.gd")
	_new_game_plus_ui = CanvasLayer.new()
	_new_game_plus_ui.set_script(script)
	add_child(_new_game_plus_ui)
	_new_game_plus_ui.open(player)


# =============================================================================
# INTERACTABLE SCRIPT FACTORY
# =============================================================================

func _create_interactable_script(interaction_label: String, object_type: String) -> GDScript:
	## Creates a GDScript for an interactable StaticBody3D.
	## The script adds the node to the "interactable" group, and implements
	## interact() and get_interaction_text().
	var src: String = """extends StaticBody3D

var _interaction_text: String = "%s"
var _object_type: String = "%s"

func _ready() -> void:
	add_to_group("interactable")

func get_interaction_text() -> String:
	return _interaction_text

func interact(player: Node) -> bool:
	var house: Node = get_tree().current_scene
	if not house:
		return false
	match _object_type:
		"kettle":
			if house.has_method("show_text_overlay"):
				house.show_text_overlay("Warm. Familiar.", 2.0)
			var sfx: Node = player.get_node_or_null("/root/SFXManager")
			if sfx and sfx.has_method("play_sfx"):
				sfx.play_sfx("pickup")
		"sandwich":
			if house.has_method("show_text_overlay"):
				house.show_text_overlay("A good sandwich.", 2.0)
		"bookshelves":
			if house.has_method("show_text_overlay"):
				house.show_text_overlay("Your old field guides. You smile.", 2.0)
		"storage_box":
			if house.has_method("open_journey_inventory"):
				house.open_journey_inventory(player)
		"front_door":
			if house.has_method("open_new_game_plus"):
				house.open_new_game_plus(player)
	return true
""" % [interaction_label, object_type]

	var script: GDScript = GDScript.new()
	script.source_code = src
	script.reload()
	return script
