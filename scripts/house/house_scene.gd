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

# Window openings
const WIN_WIDTH: float = 1.2
const WIN_HEIGHT: float = 1.5
const WIN_SILL_Y: float = 1.0

# Bedroom extension (behind kitchen, extending north)
const BEDROOM_DEPTH: float = 7.0
const BEDROOM_Z_END: float = HOUSE_DEPTH + BEDROOM_DEPTH  # 17.0
const BEDROOM_DOOR_X: float = 5.0
const BEDROOM_DOOR_WIDTH: float = 1.0

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
static var _mat_granite: StandardMaterial3D
static var _mat_map_frame: StandardMaterial3D
static var _mat_bedding: StandardMaterial3D
static var _mat_pillow: StandardMaterial3D
static var _mat_brick: StandardMaterial3D
static var _mat_fireplace_interior: StandardMaterial3D
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
	_build_wall_maps()
	_build_bedroom_walls()
	_build_bedroom_furniture()
	_build_tree_pictures()
	_build_bedroom_molding()
	_setup_lighting()
	_setup_environment()
	_create_player()
	_build_pause_menu()
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

	# Crown molding (bright cream/ivory — stands out from warm white walls)
	_mat_molding = StandardMaterial3D.new()
	_mat_molding.albedo_color = Color(0.96, 0.94, 0.90)
	_mat_molding.roughness = 0.8

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

	# Granite countertop: light grey base
	_mat_granite = StandardMaterial3D.new()
	_mat_granite.albedo_color = Color(0.78, 0.76, 0.74)
	_mat_granite.roughness = 0.4

	# Map frame: dark walnut
	_mat_map_frame = StandardMaterial3D.new()
	_mat_map_frame.albedo_color = Color(0.28, 0.18, 0.10)
	_mat_map_frame.roughness = 0.75

	# Bedding: soft blue
	_mat_bedding = StandardMaterial3D.new()
	_mat_bedding.albedo_color = Color(0.35, 0.45, 0.6)
	_mat_bedding.roughness = 0.9

	# Pillow: white
	_mat_pillow = StandardMaterial3D.new()
	_mat_pillow.albedo_color = Color(0.92, 0.92, 0.92)
	_mat_pillow.roughness = 0.9

	# Brick: warm red-brown
	_mat_brick = StandardMaterial3D.new()
	_mat_brick.albedo_color = Color(0.55, 0.28, 0.18)
	_mat_brick.roughness = 0.95

	# Fireplace interior: dark charcoal
	_mat_fireplace_interior = StandardMaterial3D.new()
	_mat_fireplace_interior.albedo_color = Color(0.12, 0.1, 0.1)
	_mat_fireplace_interior.roughness = 1.0


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

	# Bedroom floor
	var br_floor: StaticBody3D = StaticBody3D.new()
	br_floor.name = "BedroomFloor"
	add_child(br_floor)
	_box(br_floor, Vector3(LIVING_ROOM_WIDTH, FLOOR_THICKNESS, BEDROOM_DEPTH),
		Vector3(LIVING_ROOM_WIDTH / 2.0, -FLOOR_THICKNESS / 2.0, HOUSE_DEPTH + BEDROOM_DEPTH / 2.0), _mat_floor)
	var br_floor_col: CollisionShape3D = CollisionShape3D.new()
	var br_floor_shape: BoxShape3D = BoxShape3D.new()
	br_floor_shape.size = Vector3(LIVING_ROOM_WIDTH, FLOOR_THICKNESS, BEDROOM_DEPTH)
	br_floor_col.shape = br_floor_shape
	br_floor_col.position = Vector3(LIVING_ROOM_WIDTH / 2.0, -FLOOR_THICKNESS / 2.0, HOUSE_DEPTH + BEDROOM_DEPTH / 2.0)
	br_floor.add_child(br_floor_col)

	# Bedroom ceiling
	_box(self, Vector3(LIVING_ROOM_WIDTH, FLOOR_THICKNESS, BEDROOM_DEPTH),
		Vector3(LIVING_ROOM_WIDTH / 2.0, CEILING_HEIGHT + FLOOR_THICKNESS / 2.0, HOUSE_DEPTH + BEDROOM_DEPTH / 2.0), _mat_ceiling)


# =============================================================================
# EXTERIOR WALLS (with collision)
# =============================================================================

func _build_exterior_walls() -> void:
	# South wall (Z=0) — door at X=2.0, windows at X=4.5 and X=9.0
	var south: StaticBody3D = StaticBody3D.new()
	south.name = "SouthWall"
	add_child(south)
	var door_x: float = 2.0
	var dls: float = door_x - 0.5   # 1.5 — left edge of door
	var drs: float = door_x + 0.5   # 2.5 — right edge of door
	var w1l: float = 4.5 - WIN_WIDTH / 2.0   # 3.9
	var w1r: float = 4.5 + WIN_WIDTH / 2.0   # 5.1
	var w2l: float = 9.0 - WIN_WIDTH / 2.0   # 8.4
	var w2r: float = 9.0 + WIN_WIDTH / 2.0   # 9.6
	_south_wall_section(south, 0.0, dls, 0.0, CEILING_HEIGHT)
	_south_wall_section(south, dls, drs, 2.2, CEILING_HEIGHT)  # Above door
	_south_wall_section(south, drs, w1l, 0.0, CEILING_HEIGHT)
	_south_wall_section(south, w1l, w1r, 0.0, WIN_SILL_Y)  # Below window 1
	_south_wall_section(south, w1l, w1r, WIN_SILL_Y + WIN_HEIGHT, CEILING_HEIGHT)  # Above window 1
	_south_wall_section(south, w1r, w2l, 0.0, CEILING_HEIGHT)
	_south_wall_section(south, w2l, w2r, 0.0, WIN_SILL_Y)  # Below window 2
	_south_wall_section(south, w2l, w2r, WIN_SILL_Y + WIN_HEIGHT, CEILING_HEIGHT)  # Above window 2
	_south_wall_section(south, w2r, HOUSE_WIDTH, 0.0, CEILING_HEIGHT)

	# North wall (Z=HOUSE_DEPTH) — now interior between kitchen and bedroom
	# Doorway at BEDROOM_DOOR_X; no window (was exterior, now interior)
	var north: StaticBody3D = StaticBody3D.new()
	north.name = "NorthWall"
	add_child(north)
	var bdl: float = BEDROOM_DOOR_X - BEDROOM_DOOR_WIDTH / 2.0
	var bdr: float = BEDROOM_DOOR_X + BEDROOM_DOOR_WIDTH / 2.0
	_north_wall_section(north, 0.0, bdl, 0.0, CEILING_HEIGHT)
	_north_wall_section(north, bdl, bdr, 2.2, CEILING_HEIGHT)  # Above doorway
	_north_wall_section(north, bdr, HOUSE_WIDTH, 0.0, CEILING_HEIGHT)

	# West wall (X=0) — windows at Z=2.5, Z=7.5
	var west: StaticBody3D = StaticBody3D.new()
	west.name = "WestWall"
	add_child(west)
	var ww1l: float = 2.5 - WIN_WIDTH / 2.0
	var ww1r: float = 2.5 + WIN_WIDTH / 2.0
	var ww2l: float = 7.5 - WIN_WIDTH / 2.0
	var ww2r: float = 7.5 + WIN_WIDTH / 2.0
	_west_wall_section(west, 0.0, ww1l, 0.0, CEILING_HEIGHT)
	_west_wall_section(west, ww1l, ww1r, 0.0, WIN_SILL_Y)
	_west_wall_section(west, ww1l, ww1r, WIN_SILL_Y + WIN_HEIGHT, CEILING_HEIGHT)
	_west_wall_section(west, ww1r, ww2l, 0.0, CEILING_HEIGHT)
	_west_wall_section(west, ww2l, ww2r, 0.0, WIN_SILL_Y)
	_west_wall_section(west, ww2l, ww2r, WIN_SILL_Y + WIN_HEIGHT, CEILING_HEIGHT)
	_west_wall_section(west, ww2r, HOUSE_DEPTH, 0.0, CEILING_HEIGHT)

	# East wall (X=HOUSE_WIDTH) — windows at Z=3.0, Z=7.0
	var east: StaticBody3D = StaticBody3D.new()
	east.name = "EastWall"
	add_child(east)
	var ew1l: float = 3.0 - WIN_WIDTH / 2.0
	var ew1r: float = 3.0 + WIN_WIDTH / 2.0
	var ew2l: float = 7.0 - WIN_WIDTH / 2.0
	var ew2r: float = 7.0 + WIN_WIDTH / 2.0
	_east_wall_section(east, 0.0, ew1l, 0.0, CEILING_HEIGHT)
	_east_wall_section(east, ew1l, ew1r, 0.0, WIN_SILL_Y)
	_east_wall_section(east, ew1l, ew1r, WIN_SILL_Y + WIN_HEIGHT, CEILING_HEIGHT)
	_east_wall_section(east, ew1r, ew2l, 0.0, CEILING_HEIGHT)
	_east_wall_section(east, ew2l, ew2r, 0.0, WIN_SILL_Y)
	_east_wall_section(east, ew2l, ew2r, WIN_SILL_Y + WIN_HEIGHT, CEILING_HEIGHT)
	_east_wall_section(east, ew2r, HOUSE_DEPTH, 0.0, CEILING_HEIGHT)


func _south_wall_section(body: StaticBody3D, x_start: float, x_end: float, y_min: float, y_max: float) -> void:
	var w: float = x_end - x_start
	var h: float = y_max - y_min
	if w < 0.001 or h < 0.001:
		return
	var size: Vector3 = Vector3(w, h, WALL_THICKNESS)
	var pos: Vector3 = Vector3(x_start + w / 2.0, y_min + h / 2.0, WALL_THICKNESS / 2.0)
	_box(body, size, pos, _mat_wall)
	_add_wall_collision(body, size, pos)


func _north_wall_section(body: StaticBody3D, x_start: float, x_end: float, y_min: float, y_max: float) -> void:
	var w: float = x_end - x_start
	var h: float = y_max - y_min
	if w < 0.001 or h < 0.001:
		return
	var size: Vector3 = Vector3(w, h, WALL_THICKNESS)
	var pos: Vector3 = Vector3(x_start + w / 2.0, y_min + h / 2.0, HOUSE_DEPTH - WALL_THICKNESS / 2.0)
	_box(body, size, pos, _mat_wall)
	_add_wall_collision(body, size, pos)


func _west_wall_section(body: StaticBody3D, z_start: float, z_end: float, y_min: float, y_max: float) -> void:
	var d: float = z_end - z_start
	var h: float = y_max - y_min
	if d < 0.001 or h < 0.001:
		return
	var size: Vector3 = Vector3(WALL_THICKNESS, h, d)
	var pos: Vector3 = Vector3(WALL_THICKNESS / 2.0, y_min + h / 2.0, z_start + d / 2.0)
	_box(body, size, pos, _mat_wall)
	_add_wall_collision(body, size, pos)


func _east_wall_section(body: StaticBody3D, z_start: float, z_end: float, y_min: float, y_max: float) -> void:
	var d: float = z_end - z_start
	var h: float = y_max - y_min
	if d < 0.001 or h < 0.001:
		return
	var size: Vector3 = Vector3(WALL_THICKNESS, h, d)
	var pos: Vector3 = Vector3(HOUSE_WIDTH - WALL_THICKNESS / 2.0, y_min + h / 2.0, z_start + d / 2.0)
	_box(body, size, pos, _mat_wall)
	_add_wall_collision(body, size, pos)


func _bedroom_west_section(body: StaticBody3D, z_start: float, z_end: float, y_min: float, y_max: float) -> void:
	var d: float = z_end - z_start
	var h: float = y_max - y_min
	if d < 0.001 or h < 0.001:
		return
	var size: Vector3 = Vector3(WALL_THICKNESS, h, d)
	var pos: Vector3 = Vector3(WALL_THICKNESS / 2.0, y_min + h / 2.0, z_start + d / 2.0)
	_box(body, size, pos, _mat_wall)
	_add_wall_collision(body, size, pos)


func _bedroom_north_section(body: StaticBody3D, x_start: float, x_end: float, y_min: float, y_max: float) -> void:
	var w: float = x_end - x_start
	var h: float = y_max - y_min
	if w < 0.001 or h < 0.001:
		return
	var size: Vector3 = Vector3(w, h, WALL_THICKNESS)
	var pos: Vector3 = Vector3(x_start + w / 2.0, y_min + h / 2.0, BEDROOM_Z_END - WALL_THICKNESS / 2.0)
	_box(body, size, pos, _mat_wall)
	_add_wall_collision(body, size, pos)


func _bedroom_east_section(body: StaticBody3D, z_start: float, z_end: float, y_min: float, y_max: float) -> void:
	var d: float = z_end - z_start
	var h: float = y_max - y_min
	if d < 0.001 or h < 0.001:
		return
	var size: Vector3 = Vector3(WALL_THICKNESS, h, d)
	var pos: Vector3 = Vector3(LIVING_ROOM_WIDTH - WALL_THICKNESS / 2.0, y_min + h / 2.0, z_start + d / 2.0)
	_box(body, size, pos, _mat_wall)
	_add_wall_collision(body, size, pos)


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
	# Center divider with doorway at Z=7.5 (connecting kitchen to dining room)
	var cd_door_z: float = 7.5
	var cd_door_w: float = 1.5
	var cd_dl: float = cd_door_z - cd_door_w / 2.0  # 6.75
	var cd_dr: float = cd_door_z + cd_door_w / 2.0  # 8.25

	# South section (Z=0 to doorway)
	_add_wall_with_collision("CenterDividerSouth",
		Vector3(WALL_THICKNESS, CEILING_HEIGHT, cd_dl),
		Vector3(LIVING_ROOM_WIDTH, CEILING_HEIGHT / 2.0, cd_dl / 2.0))

	# Above doorway
	_add_wall_with_collision("CenterDividerAbove",
		Vector3(WALL_THICKNESS, CEILING_HEIGHT - 2.2, cd_door_w),
		Vector3(LIVING_ROOM_WIDTH, 2.2 + (CEILING_HEIGHT - 2.2) / 2.0, cd_door_z))

	# North section (doorway to Z=10)
	var cd_north_len: float = HOUSE_DEPTH - cd_dr
	_add_wall_with_collision("CenterDividerNorth",
		Vector3(WALL_THICKNESS, CEILING_HEIGHT, cd_north_len),
		Vector3(LIVING_ROOM_WIDTH, CEILING_HEIGHT / 2.0, cd_dr + cd_north_len / 2.0))

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
	# Stepped crown molding profile:
	#   Upper piece (against ceiling): 0.10m tall, 0.06m deep
	#   Lower piece (step, wider):     0.05m tall, 0.10m deep
	var upper_h: float = 0.10
	var upper_d: float = 0.06
	var lower_h: float = 0.05
	var lower_d: float = 0.10
	var y_upper: float = CEILING_HEIGHT - upper_h / 2.0
	var y_lower: float = CEILING_HEIGHT - upper_h - lower_h / 2.0

	# --- Living room (X: WALL to LIVING_ROOM_WIDTH, Z: WALL to LIVING_ROOM_DEPTH) ---
	var lw: float = LIVING_ROOM_WIDTH - WALL_THICKNESS
	var ld: float = LIVING_ROOM_DEPTH
	var lx: float = WALL_THICKNESS + lw / 2.0
	var lz: float = ld / 2.0
	# South
	_box(self, Vector3(lw, upper_h, upper_d), Vector3(lx, y_upper, WALL_THICKNESS + upper_d / 2.0), _mat_molding)
	_box(self, Vector3(lw, lower_h, lower_d), Vector3(lx, y_lower, WALL_THICKNESS + lower_d / 2.0), _mat_molding)
	# West
	_box(self, Vector3(upper_d, upper_h, ld), Vector3(WALL_THICKNESS + upper_d / 2.0, y_upper, lz), _mat_molding)
	_box(self, Vector3(lower_d, lower_h, ld), Vector3(WALL_THICKNESS + lower_d / 2.0, y_lower, lz), _mat_molding)
	# North (kitchen divider)
	_box(self, Vector3(lw, upper_h, upper_d), Vector3(lx, y_upper, ld - upper_d / 2.0), _mat_molding)
	_box(self, Vector3(lw, lower_h, lower_d), Vector3(lx, y_lower, ld - lower_d / 2.0), _mat_molding)
	# East (center divider)
	_box(self, Vector3(upper_d, upper_h, ld), Vector3(LIVING_ROOM_WIDTH - upper_d / 2.0, y_upper, lz), _mat_molding)
	_box(self, Vector3(lower_d, lower_h, ld), Vector3(LIVING_ROOM_WIDTH - lower_d / 2.0, y_lower, lz), _mat_molding)

	# --- Kitchen (X: WALL to LIVING_ROOM_WIDTH, Z: LIVING_ROOM_DEPTH to HOUSE_DEPTH-WALL) ---
	var kd: float = KITCHEN_DEPTH - WALL_THICKNESS
	var kz: float = LIVING_ROOM_DEPTH + kd / 2.0
	# West
	_box(self, Vector3(upper_d, upper_h, kd), Vector3(WALL_THICKNESS + upper_d / 2.0, y_upper, kz), _mat_molding)
	_box(self, Vector3(lower_d, lower_h, kd), Vector3(WALL_THICKNESS + lower_d / 2.0, y_lower, kz), _mat_molding)
	# North
	_box(self, Vector3(lw, upper_h, upper_d), Vector3(lx, y_upper, HOUSE_DEPTH - WALL_THICKNESS - upper_d / 2.0), _mat_molding)
	_box(self, Vector3(lw, lower_h, lower_d), Vector3(lx, y_lower, HOUSE_DEPTH - WALL_THICKNESS - lower_d / 2.0), _mat_molding)
	# East (center divider, kitchen side)
	_box(self, Vector3(upper_d, upper_h, kd), Vector3(LIVING_ROOM_WIDTH - upper_d / 2.0, y_upper, kz), _mat_molding)
	_box(self, Vector3(lower_d, lower_h, kd), Vector3(LIVING_ROOM_WIDTH - lower_d / 2.0, y_lower, kz), _mat_molding)

	# --- Dining room (X: LIVING_ROOM_WIDTH to HOUSE_WIDTH-WALL, Z: WALL to HOUSE_DEPTH-WALL) ---
	var dw: float = DINING_ROOM_WIDTH - WALL_THICKNESS
	var dd: float = HOUSE_DEPTH - 2.0 * WALL_THICKNESS
	var dx: float = LIVING_ROOM_WIDTH + dw / 2.0
	var dz: float = WALL_THICKNESS + dd / 2.0
	# South
	_box(self, Vector3(dw, upper_h, upper_d), Vector3(dx, y_upper, WALL_THICKNESS + upper_d / 2.0), _mat_molding)
	_box(self, Vector3(dw, lower_h, lower_d), Vector3(dx, y_lower, WALL_THICKNESS + lower_d / 2.0), _mat_molding)
	# East
	_box(self, Vector3(upper_d, upper_h, dd), Vector3(HOUSE_WIDTH - WALL_THICKNESS - upper_d / 2.0, y_upper, dz), _mat_molding)
	_box(self, Vector3(lower_d, lower_h, dd), Vector3(HOUSE_WIDTH - WALL_THICKNESS - lower_d / 2.0, y_lower, dz), _mat_molding)
	# North
	_box(self, Vector3(dw, upper_h, upper_d), Vector3(dx, y_upper, HOUSE_DEPTH - WALL_THICKNESS - upper_d / 2.0), _mat_molding)
	_box(self, Vector3(dw, lower_h, lower_d), Vector3(dx, y_lower, HOUSE_DEPTH - WALL_THICKNESS - lower_d / 2.0), _mat_molding)
	# West (center divider, dining side)
	_box(self, Vector3(upper_d, upper_h, dd), Vector3(LIVING_ROOM_WIDTH + upper_d / 2.0, y_upper, dz), _mat_molding)
	_box(self, Vector3(lower_d, lower_h, dd), Vector3(LIVING_ROOM_WIDTH + lower_d / 2.0, y_lower, dz), _mat_molding)

	# --- Baseboards (all rooms, floor level) ---
	var bb_h: float = 0.10
	var bb_d: float = 0.03
	var bb_y: float = bb_h / 2.0
	# Living room
	_box(self, Vector3(lw, bb_h, bb_d), Vector3(lx, bb_y, WALL_THICKNESS + bb_d / 2.0), _mat_molding)
	_box(self, Vector3(bb_d, bb_h, ld), Vector3(WALL_THICKNESS + bb_d / 2.0, bb_y, lz), _mat_molding)
	_box(self, Vector3(lw, bb_h, bb_d), Vector3(lx, bb_y, ld - bb_d / 2.0), _mat_molding)
	_box(self, Vector3(bb_d, bb_h, ld), Vector3(LIVING_ROOM_WIDTH - bb_d / 2.0, bb_y, lz), _mat_molding)
	# Kitchen
	_box(self, Vector3(bb_d, bb_h, kd), Vector3(WALL_THICKNESS + bb_d / 2.0, bb_y, kz), _mat_molding)
	_box(self, Vector3(lw, bb_h, bb_d), Vector3(lx, bb_y, HOUSE_DEPTH - WALL_THICKNESS - bb_d / 2.0), _mat_molding)
	_box(self, Vector3(bb_d, bb_h, kd), Vector3(LIVING_ROOM_WIDTH - bb_d / 2.0, bb_y, kz), _mat_molding)
	# Dining room
	_box(self, Vector3(dw, bb_h, bb_d), Vector3(dx, bb_y, WALL_THICKNESS + bb_d / 2.0), _mat_molding)
	_box(self, Vector3(bb_d, bb_h, dd), Vector3(HOUSE_WIDTH - WALL_THICKNESS - bb_d / 2.0, bb_y, dz), _mat_molding)
	_box(self, Vector3(dw, bb_h, bb_d), Vector3(dx, bb_y, HOUSE_DEPTH - WALL_THICKNESS - bb_d / 2.0), _mat_molding)
	_box(self, Vector3(bb_d, bb_h, dd), Vector3(LIVING_ROOM_WIDTH + bb_d / 2.0, bb_y, dz), _mat_molding)


# =============================================================================
# WINDOWS (six-pane colonial)
# =============================================================================

func _build_windows() -> void:
	# Each window sits in the wall opening created by _build_exterior_walls
	# South wall windows (coord = X position)
	_build_six_pane_window("south", 4.5)   # Living room
	_build_six_pane_window("south", 9.0)   # Dining room
	# West wall windows (coord = Z position)
	_build_six_pane_window("west", 2.5)    # Living room
	_build_six_pane_window("west", 7.5)    # Kitchen
	# North wall — no kitchen window (now interior wall to bedroom)
	# East wall windows
	_build_six_pane_window("east", 3.0)    # Dining room
	_build_six_pane_window("east", 7.0)    # Dining room
	# Bedroom windows (many!)
	_build_six_pane_window("bedroom_west", 12.5)
	_build_six_pane_window("bedroom_west", 15.5)
	_build_six_pane_window("bedroom_east", 12.5)
	_build_six_pane_window("bedroom_east", 15.5)
	_build_six_pane_window("bedroom_north", 1.5)
	_build_six_pane_window("bedroom_north", 4.5)


func _build_six_pane_window(wall: String, coord: float) -> void:
	## Places a colonial six-pane window inside a wall opening.
	## coord is the X-position for south/north walls, Z-position for east/west walls.
	var wc: Node3D = Node3D.new()
	wc.name = "Window"
	add_child(wc)

	var cy: float = WIN_SILL_Y + WIN_HEIGHT / 2.0
	var is_ns: bool = (wall == "south" or wall == "north" or wall == "bedroom_north")

	# Base position = center of window in the wall
	var base: Vector3
	# Inward direction (points from wall into the room)
	var inward: Vector3

	match wall:
		"south":
			base = Vector3(coord, cy, WALL_THICKNESS / 2.0)
			inward = Vector3(0, 0, 1)
		"north":
			base = Vector3(coord, cy, HOUSE_DEPTH - WALL_THICKNESS / 2.0)
			inward = Vector3(0, 0, -1)
		"west":
			base = Vector3(WALL_THICKNESS / 2.0, cy, coord)
			inward = Vector3(1, 0, 0)
		"east":
			base = Vector3(HOUSE_WIDTH - WALL_THICKNESS / 2.0, cy, coord)
			inward = Vector3(-1, 0, 0)
		"bedroom_west":
			base = Vector3(WALL_THICKNESS / 2.0, cy, coord)
			inward = Vector3(1, 0, 0)
		"bedroom_east":
			base = Vector3(LIVING_ROOM_WIDTH - WALL_THICKNESS / 2.0, cy, coord)
			inward = Vector3(-1, 0, 0)
		"bedroom_north":
			base = Vector3(coord, cy, BEDROOM_Z_END - WALL_THICKNESS / 2.0)
			inward = Vector3(0, 0, -1)

	# Direction-based sky and hill colors for varied outdoor views
	var sky_color: Color
	var hill_color: Color
	match wall:
		"south":
			# Bay view — bluer sky, muted green hills
			sky_color = Color(0.45, 0.6, 0.85)
			hill_color = Color(0.25, 0.4, 0.3)
		"north", "bedroom_north":
			# Deeper green hills, slightly overcast
			sky_color = Color(0.5, 0.6, 0.72)
			hill_color = Color(0.22, 0.42, 0.2)
		"west", "bedroom_west":
			# Warm sunset tinge
			sky_color = Color(0.55, 0.6, 0.75)
			hill_color = Color(0.3, 0.48, 0.25)
		"east", "bedroom_east":
			# Morning light, crisp
			sky_color = Color(0.5, 0.65, 0.82)
			hill_color = Color(0.28, 0.5, 0.22)
		_:
			sky_color = Color(0.5, 0.65, 0.8)
			hill_color = Color(0.3, 0.5, 0.25)

	# Create local materials with direction-appropriate colors
	var mat_sky_local: StandardMaterial3D = StandardMaterial3D.new()
	mat_sky_local.albedo_color = sky_color
	mat_sky_local.roughness = 0.9
	var mat_hills_local: StandardMaterial3D = StandardMaterial3D.new()
	mat_hills_local.albedo_color = hill_color
	mat_hills_local.roughness = 0.9

	# Layer depths along inward normal (from wall center):
	#   backdrop: -0.05 (toward exterior)
	#   glass:     0.04 (toward interior)
	#   frame:     0.06 (at/past interior face)
	var backdrop_pos: Vector3 = base + inward * (-0.05)
	var glass_pos: Vector3 = base + inward * 0.04
	var frame_pos: Vector3 = base + inward * 0.06
	var sill_pos: Vector3 = base + inward * 0.10

	var thin: float = 0.02  # Thickness of flat panels

	if is_ns:
		# Window panes in XY plane, thin in Z
		# Sky backdrop (upper 60%)
		var sky_p: Vector3 = backdrop_pos
		sky_p.y += WIN_HEIGHT * 0.2
		_box(wc, Vector3(WIN_WIDTH - 0.06, WIN_HEIGHT * 0.55, thin), sky_p, mat_sky_local)
		# Hills backdrop (lower 40%)
		var hill_p: Vector3 = backdrop_pos
		hill_p.y -= WIN_HEIGHT * 0.25
		_box(wc, Vector3(WIN_WIDTH - 0.06, WIN_HEIGHT * 0.4, thin), hill_p, mat_hills_local)
		# Distant houses on hills
		for i: int in range(3):
			var hp: Vector3 = hill_p
			hp.y += 0.1
			hp.x += (float(i) - 1.0) * 0.25
			_box(wc, Vector3(0.1, 0.07, thin), hp, _mat_window_houses)
		# Glass pane
		_box(wc, Vector3(WIN_WIDTH - 0.06, WIN_HEIGHT - 0.06, thin), glass_pos, _mat_window_glass)
		# Frame borders (4 edges)
		_box(wc, Vector3(WIN_WIDTH + 0.04, 0.06, 0.04),
			Vector3(frame_pos.x, WIN_SILL_Y, frame_pos.z), _mat_window_frame)
		_box(wc, Vector3(WIN_WIDTH + 0.04, 0.06, 0.04),
			Vector3(frame_pos.x, WIN_SILL_Y + WIN_HEIGHT, frame_pos.z), _mat_window_frame)
		_box(wc, Vector3(0.06, WIN_HEIGHT + 0.04, 0.04),
			Vector3(frame_pos.x - WIN_WIDTH / 2.0, cy, frame_pos.z), _mat_window_frame)
		_box(wc, Vector3(0.06, WIN_HEIGHT + 0.04, 0.04),
			Vector3(frame_pos.x + WIN_WIDTH / 2.0, cy, frame_pos.z), _mat_window_frame)
		# Mullions (1 horizontal center, 2 vertical = 6 panes)
		_box(wc, Vector3(WIN_WIDTH - 0.08, 0.03, 0.04), frame_pos, _mat_window_frame)
		_box(wc, Vector3(0.03, WIN_HEIGHT - 0.08, 0.04),
			Vector3(frame_pos.x - WIN_WIDTH / 6.0, cy, frame_pos.z), _mat_window_frame)
		_box(wc, Vector3(0.03, WIN_HEIGHT - 0.08, 0.04),
			Vector3(frame_pos.x + WIN_WIDTH / 6.0, cy, frame_pos.z), _mat_window_frame)
		# Window sill (protruding ledge)
		_box(wc, Vector3(WIN_WIDTH + 0.12, 0.05, 0.14),
			Vector3(sill_pos.x, WIN_SILL_Y - 0.025, sill_pos.z), _mat_window_frame)
	else:
		# Window panes in YZ plane, thin in X
		# Sky backdrop
		var sky_p: Vector3 = backdrop_pos
		sky_p.y += WIN_HEIGHT * 0.2
		_box(wc, Vector3(thin, WIN_HEIGHT * 0.55, WIN_WIDTH - 0.06), sky_p, mat_sky_local)
		# Hills backdrop
		var hill_p: Vector3 = backdrop_pos
		hill_p.y -= WIN_HEIGHT * 0.25
		_box(wc, Vector3(thin, WIN_HEIGHT * 0.4, WIN_WIDTH - 0.06), hill_p, mat_hills_local)
		# Distant houses
		for i: int in range(3):
			var hp: Vector3 = hill_p
			hp.y += 0.1
			hp.z += (float(i) - 1.0) * 0.25
			_box(wc, Vector3(thin, 0.07, 0.1), hp, _mat_window_houses)
		# Glass pane
		_box(wc, Vector3(thin, WIN_HEIGHT - 0.06, WIN_WIDTH - 0.06), glass_pos, _mat_window_glass)
		# Frame borders
		_box(wc, Vector3(0.04, 0.06, WIN_WIDTH + 0.04),
			Vector3(frame_pos.x, WIN_SILL_Y, frame_pos.z), _mat_window_frame)
		_box(wc, Vector3(0.04, 0.06, WIN_WIDTH + 0.04),
			Vector3(frame_pos.x, WIN_SILL_Y + WIN_HEIGHT, frame_pos.z), _mat_window_frame)
		_box(wc, Vector3(0.04, WIN_HEIGHT + 0.04, 0.06),
			Vector3(frame_pos.x, cy, frame_pos.z - WIN_WIDTH / 2.0), _mat_window_frame)
		_box(wc, Vector3(0.04, WIN_HEIGHT + 0.04, 0.06),
			Vector3(frame_pos.x, cy, frame_pos.z + WIN_WIDTH / 2.0), _mat_window_frame)
		# Mullions
		_box(wc, Vector3(0.04, 0.03, WIN_WIDTH - 0.08), frame_pos, _mat_window_frame)
		_box(wc, Vector3(0.04, WIN_HEIGHT - 0.08, 0.03),
			Vector3(frame_pos.x, cy, frame_pos.z - WIN_WIDTH / 6.0), _mat_window_frame)
		_box(wc, Vector3(0.04, WIN_HEIGHT - 0.08, 0.03),
			Vector3(frame_pos.x, cy, frame_pos.z + WIN_WIDTH / 6.0), _mat_window_frame)
		# Window sill
		_box(wc, Vector3(0.14, 0.05, WIN_WIDTH + 0.12),
			Vector3(sill_pos.x, WIN_SILL_Y - 0.025, sill_pos.z), _mat_window_frame)


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
	# West wall window at Z=2.5 (opening Z=1.9-3.1)
	# Fireplace goes south of that window, centered at Z=0.95

	# --- Fireplace (against west wall, centered at Z=0.95) ---
	var fp: Node3D = Node3D.new()
	fp.name = "Fireplace"
	add_child(fp)
	# Brick back wall (against west wall)
	_box(fp, Vector3(0.15, 1.3, 1.1),
		Vector3(0.15, 0.65, 0.95), _mat_brick)
	# Brick left pilaster
	_box(fp, Vector3(0.4, 1.3, 0.15),
		Vector3(0.35, 0.65, 0.475), _mat_brick)
	# Brick right pilaster
	_box(fp, Vector3(0.4, 1.3, 0.15),
		Vector3(0.35, 0.65, 1.425), _mat_brick)
	# Firebox interior (dark charcoal recess)
	_box(fp, Vector3(0.2, 0.9, 0.8),
		Vector3(0.25, 0.45, 0.95), _mat_fireplace_interior)
	# Hearth (stone/brick slab on floor, protruding forward)
	_box(fp, Vector3(0.55, 0.08, 1.3),
		Vector3(0.425, 0.04, 0.95), _mat_brick)
	# Mantel shelf (wooden)
	_box(fp, Vector3(0.55, 0.08, 1.3),
		Vector3(0.425, 1.34, 0.95), _mat_furniture_wood)
	# Left candlestick
	_box(fp, Vector3(0.03, 0.12, 0.03),
		Vector3(0.5, 1.46, 0.5), _mat_chandelier)
	_box(fp, Vector3(0.02, 0.03, 0.02),
		Vector3(0.5, 1.535, 0.5), _mat_pillow)
	# Right candlestick
	_box(fp, Vector3(0.03, 0.12, 0.03),
		Vector3(0.5, 1.46, 1.4), _mat_chandelier)
	_box(fp, Vector3(0.02, 0.03, 0.02),
		Vector3(0.5, 1.535, 1.4), _mat_pillow)
	# Chimney breast above mantel to ceiling
	_box(fp, Vector3(0.15, CEILING_HEIGHT - 1.38, 1.3),
		Vector3(0.15, 1.38 + (CEILING_HEIGHT - 1.38) / 2.0, 0.95), _mat_brick)
	# Fireplace collision (hearth + surround)
	var fp_body: StaticBody3D = StaticBody3D.new()
	fp_body.name = "FireplaceCollision"
	add_child(fp_body)
	var fp_col: CollisionShape3D = CollisionShape3D.new()
	var fp_shape: BoxShape3D = BoxShape3D.new()
	fp_shape.size = Vector3(0.55, 1.4, 1.3)
	fp_col.shape = fp_shape
	fp_col.position = Vector3(0.425, 0.7, 0.95)
	fp_body.add_child(fp_col)

	# --- Couch (faces west toward fireplace, runs along Z axis) ---
	var couch_container: Node3D = Node3D.new()
	couch_container.name = "Couch"
	add_child(couch_container)
	var couch_x: float = 3.5
	var couch_z: float = 1.5
	# Seat (0.8m deep in X, 2.0m long in Z)
	_box(couch_container, Vector3(0.8, 0.4, 2.0),
		Vector3(couch_x, 0.4, couch_z), _mat_upholstery)
	# Back (on +X east side, facing -X west toward fireplace)
	_box(couch_container, Vector3(0.15, 0.5, 2.0),
		Vector3(couch_x + 0.4 - 0.075, 0.65, couch_z), _mat_upholstery)
	# South arm (at Z=0.5)
	_box(couch_container, Vector3(0.8, 0.5, 0.15),
		Vector3(couch_x, 0.55, couch_z - 1.0 + 0.075), _mat_upholstery)
	# North arm (at Z=2.5)
	_box(couch_container, Vector3(0.8, 0.5, 0.15),
		Vector3(couch_x, 0.55, couch_z + 1.0 - 0.075), _mat_upholstery)
	# Couch collision
	var couch_body: StaticBody3D = StaticBody3D.new()
	couch_body.name = "CouchCollision"
	add_child(couch_body)
	var couch_col: CollisionShape3D = CollisionShape3D.new()
	var couch_shape: BoxShape3D = BoxShape3D.new()
	couch_shape.size = Vector3(0.9, 0.7, 2.1)
	couch_col.shape = couch_shape
	couch_col.position = Vector3(couch_x, 0.4, couch_z)
	couch_body.add_child(couch_col)

	# --- Coffee Table (between couch and fireplace) ---
	var table_container: Node3D = Node3D.new()
	table_container.name = "CoffeeTable"
	add_child(table_container)
	var table_x: float = 2.0
	var table_z: float = 1.5
	_box(table_container, Vector3(0.5, 0.05, 1.0),
		Vector3(table_x, 0.4, table_z), _mat_furniture_wood)
	for lx: float in [-0.18, 0.18]:
		for lz: float in [-0.4, 0.4]:
			_box(table_container, Vector3(0.05, 0.35, 0.05),
				Vector3(table_x + lx, 0.175, table_z + lz), _mat_furniture_wood)

	# --- Armchair (near north side of living room, facing south) ---
	var chair: Node3D = Node3D.new()
	chair.name = "Armchair"
	add_child(chair)
	var chair_x: float = 2.0
	var chair_z: float = 3.8
	# Seat
	_box(chair, Vector3(0.7, 0.35, 0.7),
		Vector3(chair_x, 0.38, chair_z), _mat_upholstery)
	# Back (on +Z side, facing -Z toward seating area)
	_box(chair, Vector3(0.7, 0.5, 0.12),
		Vector3(chair_x, 0.6, chair_z + 0.35 - 0.06), _mat_upholstery)
	# Left arm
	_box(chair, Vector3(0.12, 0.4, 0.7),
		Vector3(chair_x - 0.35 + 0.06, 0.48, chair_z), _mat_upholstery)
	# Right arm
	_box(chair, Vector3(0.12, 0.4, 0.7),
		Vector3(chair_x + 0.35 - 0.06, 0.48, chair_z), _mat_upholstery)
	# 4 legs
	for lx: float in [-0.25, 0.25]:
		for lz: float in [-0.25, 0.25]:
			_box(chair, Vector3(0.05, 0.18, 0.05),
				Vector3(chair_x + lx, 0.09, chair_z + lz), _mat_furniture_wood)

	# --- End Table with Lamp (at north end of couch) ---
	var end_table: Node3D = Node3D.new()
	end_table.name = "EndTable"
	add_child(end_table)
	var et_x: float = 3.5
	var et_z: float = 2.8
	# Table body
	_box(end_table, Vector3(0.4, 0.5, 0.4),
		Vector3(et_x, 0.25, et_z), _mat_furniture_wood)
	# Table top (slightly wider)
	_box(end_table, Vector3(0.44, 0.04, 0.44),
		Vector3(et_x, 0.52, et_z), _mat_furniture_wood)
	# Lamp base (metallic)
	_box(end_table, Vector3(0.08, 0.15, 0.08),
		Vector3(et_x, 0.62, et_z), _mat_kettle)
	# Lamp shade (white)
	_box(end_table, Vector3(0.15, 0.12, 0.15),
		Vector3(et_x, 0.77, et_z), _mat_pillow)

	# --- Rug (under seating group) ---
	_box(self, Vector3(3.0, 0.02, 2.5),
		Vector3(2.5, 0.01, 1.8), _mat_rug)

	# --- Bookshelves (against kitchen divider wall, left of doorway, facing into room) ---
	_build_bookshelf(Vector3(1.0, 0.0, LIVING_ROOM_DEPTH - 0.1))

	# --- Wilderness Storage Box (tucked in southwest corner of kitchen divider area) ---
	_build_storage_box(Vector3(0.5, 0.0, 4.5))


func _build_bookshelf(pos: Vector3) -> void:
	## pos.z is the back panel (against the wall). Shelves/books extend in -Z (into room).
	var shelf_body: StaticBody3D = StaticBody3D.new()
	shelf_body.name = "Bookshelves"
	shelf_body.set_script(_create_interactable_script(
		"Browse Books",
		"bookshelves"
	))

	# Back panel (against wall)
	_box(shelf_body, Vector3(1.5, 2.0, 0.05),
		Vector3(pos.x, 1.0, pos.z), _mat_furniture_wood)

	# Side panels
	_box(shelf_body, Vector3(0.04, 2.0, 0.3),
		Vector3(pos.x - 0.73, 1.0, pos.z - 0.15), _mat_furniture_wood)
	_box(shelf_body, Vector3(0.04, 2.0, 0.3),
		Vector3(pos.x + 0.73, 1.0, pos.z - 0.15), _mat_furniture_wood)

	# 4 shelf boards (extending into room = -Z)
	for i: int in range(4):
		var shelf_y: float = 0.05 + float(i) * 0.5
		_box(shelf_body, Vector3(1.5, 0.04, 0.3),
			Vector3(pos.x, shelf_y, pos.z - 0.15), _mat_furniture_wood)

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
			var book_height: float = 0.35 + randf() * 0.1
			var book_width: float = 0.06 + randf() * 0.04
			_box(shelf_body, Vector3(book_width, book_height, 0.2),
				Vector3(book_x, shelf_y + book_height / 2.0, pos.z - 0.15), book_mat_cache[color_key])
			book_x += book_width + 0.02

	# Collision for interaction
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(1.5, 2.0, 0.4)
	col.shape = shape
	col.position = Vector3(pos.x, 1.0, pos.z - 0.1)
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

	# --- L-shaped Counter ---
	# Main run along north wall (X 1.5 to 4.0)
	var counter_x: float = 2.75
	var counter_z: float = HOUSE_DEPTH - 0.5
	# Counter top (granite)
	_box(self, Vector3(2.5, 0.05, 0.6),
		Vector3(counter_x, 0.9, counter_z), _mat_granite)
	# Granite speckle on main counter
	_add_granite_speckle(Vector3(counter_x, 0.926, counter_z), Vector3(2.4, 0.0, 0.55))
	# Counter base
	_box(self, Vector3(2.5, 0.85, 0.6),
		Vector3(counter_x, 0.425, counter_z), _mat_cabinet_face)
	# Cabinet doors (3 sections)
	for cx: float in [-0.7, 0.0, 0.7]:
		_box(self, Vector3(0.6, 0.65, 0.02),
			Vector3(counter_x + cx, 0.4, counter_z + 0.31), _mat_cabinet_face)
		_box(self, Vector3(0.1, 0.02, 0.03),
			Vector3(counter_x + cx, 0.5, counter_z + 0.33), _mat_handle)

	# (L-return counter removed to keep bedroom doorway clear)

	# --- Kitchen Sink (under window at X=3.0) ---
	var mat_sink: StandardMaterial3D = StandardMaterial3D.new()
	mat_sink.albedo_color = Color(0.6, 0.6, 0.62)
	mat_sink.roughness = 0.25
	mat_sink.metallic = 0.6
	# Sink basin (recessed into counter, deeper for visibility)
	_box(self, Vector3(0.55, 0.02, 0.38),
		Vector3(3.0, 0.84, counter_z), mat_sink)  # Basin bottom
	# Basin walls (4 thin sides rising to counter surface)
	_box(self, Vector3(0.55, 0.10, 0.02),
		Vector3(3.0, 0.89, counter_z + 0.19), mat_sink)  # Back (toward wall)
	_box(self, Vector3(0.55, 0.10, 0.02),
		Vector3(3.0, 0.89, counter_z - 0.19), mat_sink)  # Front (toward room)
	_box(self, Vector3(0.02, 0.10, 0.38),
		Vector3(2.73, 0.89, counter_z), mat_sink)  # Left
	_box(self, Vector3(0.02, 0.10, 0.38),
		Vector3(3.27, 0.89, counter_z), mat_sink)  # Right
	# Faucet base (against back/wall side of counter = +Z)
	_box(self, Vector3(0.04, 0.28, 0.04),
		Vector3(3.0, 1.07, counter_z + 0.2), _mat_kettle)
	# Faucet arch (from back over basin toward room = -Z)
	_box(self, Vector3(0.04, 0.04, 0.14),
		Vector3(3.0, 1.21, counter_z + 0.14), _mat_kettle)
	# Faucet spout (hanging down over basin center)
	_box(self, Vector3(0.03, 0.08, 0.03),
		Vector3(3.0, 1.15, counter_z + 0.08), _mat_kettle)

	# --- Upper Cabinets (above counter, avoiding window at X=3.0) ---
	# Left upper cabinet (X 1.5 to 2.3)
	_box(self, Vector3(0.8, 0.6, 0.35),
		Vector3(1.9, 1.85, counter_z), _mat_cabinet_face)
	_box(self, Vector3(0.35, 0.5, 0.02),
		Vector3(1.75, 1.85, counter_z + 0.18), _mat_cabinet_face)
	_box(self, Vector3(0.35, 0.5, 0.02),
		Vector3(2.05, 1.85, counter_z + 0.18), _mat_cabinet_face)
	# Right upper cabinet (X 3.7 to 4.0, above stove area)
	_box(self, Vector3(0.6, 0.6, 0.35),
		Vector3(4.3, 1.85, counter_z), _mat_cabinet_face)
	# Range hood above stove
	_box(self, Vector3(0.65, 0.15, 0.45),
		Vector3(4.3, 1.45, counter_z), _mat_stove)

	# --- Stove (next to counter, against north wall) ---
	var stove_x: float = 4.3
	var stove_z: float = HOUSE_DEPTH - 0.5
	_box(self, Vector3(0.6, 0.9, 0.6),
		Vector3(stove_x, 0.45, stove_z), _mat_stove)
	# Oven door
	_box(self, Vector3(0.5, 0.4, 0.02),
		Vector3(stove_x, 0.35, stove_z + 0.31), _mat_stove)
	_box(self, Vector3(0.2, 0.02, 0.03),
		Vector3(stove_x, 0.58, stove_z + 0.33), _mat_handle)
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
	_box(kettle_body, Vector3(0.08, 0.02, 0.06),
		Vector3(stove_x + 0.1, 1.13, stove_z - 0.1), _mat_handle)
	_box(kettle_body, Vector3(0.03, 0.04, 0.06),
		Vector3(stove_x + 0.1 + 0.08, 1.08, stove_z - 0.1), _mat_kettle)
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
	# Freezer line
	_box(self, Vector3(0.78, 0.02, 0.68),
		Vector3(fridge_x, 1.4, fridge_z), _mat_handle)
	# Freezer handle
	_box(self, Vector3(0.02, 0.15, 0.04),
		Vector3(fridge_x + 0.38, 1.55, fridge_z + 0.36), _mat_handle)

	# --- Small kitchen table (center of kitchen) ---
	var table_x: float = 2.8
	var table_z: float = 7.0
	_box(self, Vector3(0.9, 0.05, 0.7),
		Vector3(table_x, 0.75, table_z), _mat_furniture_wood)
	for lx: float in [-0.35, 0.35]:
		for lz: float in [-0.25, 0.25]:
			_box(self, Vector3(0.05, 0.7, 0.05),
				Vector3(table_x + lx, 0.35, table_z + lz), _mat_furniture_wood)

	# 2 chairs at kitchen table (on left/right sides, facing inward toward table)
	for sx: float in [-0.55, 0.55]:
		# Seat
		_box(self, Vector3(0.35, 0.04, 0.35),
			Vector3(table_x + sx, 0.5, table_z), _mat_furniture_wood)
		# Chair back (on outer side, away from table center)
		var back_offset_x: float = sign(sx) * 0.175
		_box(self, Vector3(0.05, 0.4, 0.35),
			Vector3(table_x + sx + back_offset_x, 0.72, table_z), _mat_furniture_wood)
		# 4 legs
		for slx: float in [-0.12, 0.12]:
			for slz: float in [-0.12, 0.12]:
				_box(self, Vector3(0.04, 0.48, 0.04),
					Vector3(table_x + sx + slx, 0.24, table_z + slz), _mat_furniture_wood)

	# --- Window herb planter (on kitchen west wall window sill at Z=7.5) ---
	var herb_planter: Node3D = Node3D.new()
	herb_planter.name = "HerbPlanter"
	add_child(herb_planter)
	var hp_x: float = 0.25
	var hp_z: float = 7.5
	var hp_y: float = WIN_SILL_Y + 0.05
	# Planter box (terracotta)
	var mat_herb_pot: StandardMaterial3D = StandardMaterial3D.new()
	mat_herb_pot.albedo_color = Color(0.65, 0.35, 0.2)
	mat_herb_pot.roughness = 0.85
	_box(herb_planter, Vector3(0.15, 0.1, 0.4),
		Vector3(hp_x, hp_y, hp_z), mat_herb_pot)
	# 3 small herb leaf clusters
	var mat_herb: StandardMaterial3D = StandardMaterial3D.new()
	mat_herb.albedo_color = Color(0.25, 0.5, 0.18)
	mat_herb.roughness = 0.85
	_box(herb_planter, Vector3(0.08, 0.08, 0.1),
		Vector3(hp_x, hp_y + 0.09, hp_z - 0.12), mat_herb)
	_box(herb_planter, Vector3(0.1, 0.1, 0.1),
		Vector3(hp_x, hp_y + 0.1, hp_z), mat_herb)
	_box(herb_planter, Vector3(0.08, 0.07, 0.1),
		Vector3(hp_x, hp_y + 0.085, hp_z + 0.12), mat_herb)

	# --- Table settings (plates, napkins, vase with flowers) ---
	var mat_napkin: StandardMaterial3D = StandardMaterial3D.new()
	mat_napkin.albedo_color = Color(0.85, 0.85, 0.82)
	mat_napkin.roughness = 0.9
	var mat_vase: StandardMaterial3D = StandardMaterial3D.new()
	mat_vase.albedo_color = Color(0.55, 0.6, 0.7)
	mat_vase.roughness = 0.4
	var mat_flower_petal: StandardMaterial3D = StandardMaterial3D.new()
	mat_flower_petal.albedo_color = Color(0.95, 0.85, 0.15)
	mat_flower_petal.roughness = 0.8
	var mat_stem: StandardMaterial3D = StandardMaterial3D.new()
	mat_stem.albedo_color = Color(0.2, 0.45, 0.15)
	mat_stem.roughness = 0.85

	# Place setting 1 (left side, near left stool)
	_box(self, Vector3(0.18, 0.01, 0.18),
		Vector3(table_x - 0.2, 0.785, table_z), _mat_plate)  # Plate
	_box(self, Vector3(0.08, 0.005, 0.12),
		Vector3(table_x - 0.2 + 0.16, 0.783, table_z), mat_napkin)  # Napkin

	# Place setting 2 (right side, near right stool)
	_box(self, Vector3(0.18, 0.01, 0.18),
		Vector3(table_x + 0.2, 0.785, table_z), _mat_plate)  # Plate
	_box(self, Vector3(0.08, 0.005, 0.12),
		Vector3(table_x + 0.2 - 0.16, 0.783, table_z), mat_napkin)  # Napkin

	# Vase with yellow flowers (center of table)
	_box(self, Vector3(0.06, 0.12, 0.06),
		Vector3(table_x, 0.84, table_z), mat_vase)  # Vase body
	_box(self, Vector3(0.07, 0.01, 0.07),
		Vector3(table_x, 0.9, table_z), mat_vase)  # Vase rim
	# 3 flower stems
	for fi: int in range(3):
		var foff: float = (float(fi) - 1.0) * 0.02
		_box(self, Vector3(0.01, 0.12, 0.01),
			Vector3(table_x + foff, 0.96, table_z + foff * 0.5), mat_stem)
		# Flower heads (small yellow boxes)
		_box(self, Vector3(0.04, 0.03, 0.04),
			Vector3(table_x + foff, 1.03, table_z + foff * 0.5), mat_flower_petal)

	# --- Counter-top items ---
	# Cutting board (on main counter)
	_box(self, Vector3(0.25, 0.02, 0.18),
		Vector3(2.0, 0.935, counter_z + 0.1), _mat_furniture_wood)
	# Fruit bowl (on L-return)
	var mat_bowl: StandardMaterial3D = StandardMaterial3D.new()
	mat_bowl.albedo_color = Color(0.85, 0.82, 0.75)
	mat_bowl.roughness = 0.5
	var bowl_x: float = 1.8  # On main counter near left end
	_box(self, Vector3(0.2, 0.1, 0.2),
		Vector3(bowl_x, 0.97, counter_z), mat_bowl)
	# Fruit (small colored boxes in bowl)
	var mat_apple: StandardMaterial3D = StandardMaterial3D.new()
	mat_apple.albedo_color = Color(0.7, 0.15, 0.1)
	mat_apple.roughness = 0.8
	var mat_banana: StandardMaterial3D = StandardMaterial3D.new()
	mat_banana.albedo_color = Color(0.9, 0.8, 0.2)
	mat_banana.roughness = 0.8
	_box(self, Vector3(0.06, 0.06, 0.06),
		Vector3(bowl_x - 0.03, 1.05, counter_z - 0.03), mat_apple)
	_box(self, Vector3(0.06, 0.06, 0.06),
		Vector3(bowl_x + 0.04, 1.05, counter_z + 0.02), mat_apple)
	_box(self, Vector3(0.04, 0.04, 0.12),
		Vector3(bowl_x, 1.04, counter_z), mat_banana)


func _add_granite_speckle(center: Vector3, area: Vector3) -> void:
	## Adds pixelated granite speckle boxes on a counter surface.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(center.x * 1000 + center.z * 100)  # Deterministic per counter
	var speckle_colors: Array[Color] = [
		Color(0.92, 0.90, 0.88),  # White
		Color(0.85, 0.83, 0.80),  # Light grey
		Color(0.55, 0.53, 0.51),  # Dark grey
		Color(0.65, 0.63, 0.60),  # Medium grey
		Color(0.95, 0.93, 0.91),  # Near-white
		Color(0.45, 0.43, 0.42),  # Charcoal
	]
	var speckle_mats: Array[StandardMaterial3D] = []
	for c: Color in speckle_colors:
		var m: StandardMaterial3D = StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.4
		speckle_mats.append(m)

	for i: int in range(25):
		var sx: float = center.x + rng.randf_range(-area.x / 2.0, area.x / 2.0)
		var sz: float = center.z + rng.randf_range(-area.z / 2.0, area.z / 2.0)
		var size: float = rng.randf_range(0.03, 0.07)
		var mat_idx: int = rng.randi_range(0, speckle_mats.size() - 1)
		_box(self, Vector3(size, 0.006, size),
			Vector3(sx, center.y, sz), speckle_mats[mat_idx])


# =============================================================================
# WALL MAPS (terrain captures from the wilderness)
# =============================================================================

func _build_wall_maps() -> void:
	## Hang procedural "terrain maps" on large open walls in the dining room.
	## Each map is a framed grid of colored boxes representing game biomes.

	# Large map on north section of east wall (dining room, between windows)
	# East wall interior face: X = HOUSE_WIDTH - WALL_THICKNESS - 0.03
	var wall_x: float = HOUSE_WIDTH - WALL_THICKNESS - 0.03
	_build_terrain_map(Vector3(wall_x, 1.6, 5.0), "east", 1.2, 0.9, 42)

	# Smaller map on south section of east wall
	_build_terrain_map(Vector3(wall_x, 1.6, 1.5), "east", 0.7, 0.5, 17)

	# Map on north wall of dining room (right of window)
	var north_z: float = HOUSE_DEPTH - WALL_THICKNESS - 0.03
	_build_terrain_map(Vector3(8.5, 1.6, north_z), "north", 0.8, 0.6, 89)


func _build_terrain_map(pos: Vector3, wall: String, map_w: float, map_h: float, seed_val: int) -> void:
	## Builds a framed terrain map on a wall. Uses colored grid to mimic game terrain.
	var map_node: Node3D = Node3D.new()
	map_node.name = "TerrainMap"
	add_child(map_node)

	var is_ew: bool = (wall == "east" or wall == "west")
	var frame_t: float = 0.04  # Frame border thickness

	# Frame (4 border pieces)
	if is_ew:
		# Map hangs on YZ plane, thin in X
		_box(map_node, Vector3(0.02, map_h + frame_t * 2, frame_t),
			Vector3(pos.x, pos.y, pos.z - map_w / 2.0 - frame_t / 2.0), _mat_map_frame)
		_box(map_node, Vector3(0.02, map_h + frame_t * 2, frame_t),
			Vector3(pos.x, pos.y, pos.z + map_w / 2.0 + frame_t / 2.0), _mat_map_frame)
		_box(map_node, Vector3(0.02, frame_t, map_w + frame_t * 2),
			Vector3(pos.x, pos.y + map_h / 2.0 + frame_t / 2.0, pos.z), _mat_map_frame)
		_box(map_node, Vector3(0.02, frame_t, map_w + frame_t * 2),
			Vector3(pos.x, pos.y - map_h / 2.0 - frame_t / 2.0, pos.z), _mat_map_frame)
	else:
		# Map hangs on XY plane, thin in Z
		_box(map_node, Vector3(frame_t, map_h + frame_t * 2, 0.02),
			Vector3(pos.x - map_w / 2.0 - frame_t / 2.0, pos.y, pos.z), _mat_map_frame)
		_box(map_node, Vector3(frame_t, map_h + frame_t * 2, 0.02),
			Vector3(pos.x + map_w / 2.0 + frame_t / 2.0, pos.y, pos.z), _mat_map_frame)
		_box(map_node, Vector3(map_w + frame_t * 2, frame_t, 0.02),
			Vector3(pos.x, pos.y + map_h / 2.0 + frame_t / 2.0, pos.z), _mat_map_frame)
		_box(map_node, Vector3(map_w + frame_t * 2, frame_t, 0.02),
			Vector3(pos.x, pos.y - map_h / 2.0 - frame_t / 2.0, pos.z), _mat_map_frame)

	# Background (parchment/paper)
	var mat_paper: StandardMaterial3D = StandardMaterial3D.new()
	mat_paper.albedo_color = Color(0.85, 0.80, 0.70)
	mat_paper.roughness = 0.9
	if is_ew:
		_box(map_node, Vector3(0.015, map_h, map_w), Vector3(pos.x, pos.y, pos.z), mat_paper)
	else:
		_box(map_node, Vector3(map_w, map_h, 0.015), Vector3(pos.x, pos.y, pos.z), mat_paper)

	# Terrain grid — colored cells representing game biomes
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val
	var cols: int = int(map_w / 0.08)
	var rows: int = int(map_h / 0.08)
	var cell_w: float = map_w / float(cols)
	var cell_h: float = map_h / float(rows)

	# Biome colors matching the game
	var biome_colors: Array[Color] = [
		Color(0.25, 0.45, 0.20),  # Forest (dark green)
		Color(0.35, 0.55, 0.25),  # Forest (lighter)
		Color(0.30, 0.50, 0.22),  # Forest (mid)
		Color(0.55, 0.50, 0.35),  # Rocky/mountain
		Color(0.45, 0.42, 0.30),  # Rocky darker
		Color(0.60, 0.55, 0.40),  # Plains/meadow
		Color(0.50, 0.47, 0.33),  # Dirt/trail
	]
	var water_color: Color = Color(0.25, 0.40, 0.55)
	var campsite_color: Color = Color(0.75, 0.45, 0.15)

	var biome_mats: Array[StandardMaterial3D] = []
	for c: Color in biome_colors:
		var m: StandardMaterial3D = StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.9
		biome_mats.append(m)
	var mat_water: StandardMaterial3D = StandardMaterial3D.new()
	mat_water.albedo_color = water_color
	mat_water.roughness = 0.5
	var mat_camp: StandardMaterial3D = StandardMaterial3D.new()
	mat_camp.albedo_color = campsite_color
	mat_camp.roughness = 0.8

	for row: int in range(rows):
		for col: int in range(cols):
			var cx: float = -map_w / 2.0 + (float(col) + 0.5) * cell_w
			var cy: float = -map_h / 2.0 + (float(row) + 0.5) * cell_h

			# Choose biome based on position + noise
			var mat: StandardMaterial3D
			var dist_from_center: float = sqrt(cx * cx + cy * cy)
			var r: float = rng.randf()
			if row == rows / 2 and col > cols / 3 and col < cols * 2 / 3:
				mat = mat_water  # River through middle
			elif row == rows / 2 + 1 and col > cols / 3 + 1 and col < cols * 2 / 3 - 1:
				mat = mat_water  # River width
			elif row == rows / 2 and col == cols / 2:
				mat = mat_camp  # Campsite marker
			elif dist_from_center < map_w * 0.2 and r < 0.7:
				mat = biome_mats[rng.randi_range(0, 2)]  # Dense forest center
			elif r < 0.15:
				mat = biome_mats[rng.randi_range(3, 4)]  # Rocky patches
			elif r < 0.25:
				mat = biome_mats[rng.randi_range(5, 6)]  # Plains
			else:
				mat = biome_mats[rng.randi_range(0, 2)]  # Forest (dominant)

			if is_ew:
				# Offset cells toward room interior so they sit on top of paper
				var cell_off_x: float = -0.01 if wall == "east" else 0.01
				_box(map_node, Vector3(0.012, cell_h * 0.9, cell_w * 0.9),
					Vector3(pos.x + cell_off_x, pos.y + cy, pos.z + cx), mat)
			else:
				var cell_off_z: float = -0.01 if wall == "north" else 0.01
				_box(map_node, Vector3(cell_w * 0.9, cell_h * 0.9, 0.012),
					Vector3(pos.x + cx, pos.y + cy, pos.z + cell_off_z), mat)


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
	_build_chair(Vector3(table_x - 0.5, 0.0, table_z + 0.8), PI)       # South side (back faces away from table)
	_build_chair(Vector3(table_x + 0.5, 0.0, table_z + 0.8), PI)       # South side
	_build_chair(Vector3(table_x - 0.5, 0.0, table_z - 0.8), 0.0)      # North side (back faces away from table)
	_build_chair(Vector3(table_x + 0.5, 0.0, table_z - 0.8), 0.0)      # North side

	# --- Sandwich Plate on Table ---
	_build_sandwich(Vector3(table_x + 0.3, 0.78, table_z - 0.1))

	# --- Chandelier ---
	_build_chandelier(Vector3(dining_cx, CEILING_HEIGHT, dining_cz))

	# --- Sideboard/Buffet (against east wall, between windows at Z=3.0 and Z=7.0) ---
	var sb: Node3D = Node3D.new()
	sb.name = "Sideboard"
	add_child(sb)
	var sb_x: float = HOUSE_WIDTH - WALL_THICKNESS - 0.25
	var sb_z: float = 5.0
	# Body
	_box(sb, Vector3(0.45, 0.8, 1.6),
		Vector3(sb_x, 0.4, sb_z), _mat_furniture_wood)
	# Top (slightly wider)
	_box(sb, Vector3(0.48, 0.04, 1.65),
		Vector3(sb_x, 0.82, sb_z), _mat_furniture_wood)
	# 4 cabinet doors on -X face (facing into room)
	for di: int in range(4):
		var dz: float = sb_z - 0.6 + float(di) * 0.4
		_box(sb, Vector3(0.02, 0.55, 0.35),
			Vector3(sb_x - 0.235, 0.38, dz), _mat_furniture_wood)
		# Handle on each door
		_box(sb, Vector3(0.03, 0.02, 0.06),
			Vector3(sb_x - 0.26, 0.45, dz), _mat_handle)
	# On top: 2 candlestick holders
	_box(sb, Vector3(0.04, 0.15, 0.04),
		Vector3(sb_x, 0.92, sb_z - 0.5), _mat_chandelier)
	_box(sb, Vector3(0.02, 0.03, 0.02),
		Vector3(sb_x, 1.005, sb_z - 0.5), _mat_pillow)
	_box(sb, Vector3(0.04, 0.15, 0.04),
		Vector3(sb_x, 0.92, sb_z + 0.5), _mat_chandelier)
	_box(sb, Vector3(0.02, 0.03, 0.02),
		Vector3(sb_x, 1.005, sb_z + 0.5), _mat_pillow)
	# Serving tray on top (center)
	_box(sb, Vector3(0.25, 0.02, 0.4),
		Vector3(sb_x, 0.85, sb_z), _mat_plate)
	# Sideboard collision
	var sb_body: StaticBody3D = StaticBody3D.new()
	sb_body.name = "SideboardCollision"
	add_child(sb_body)
	var sb_col: CollisionShape3D = CollisionShape3D.new()
	var sb_shape: BoxShape3D = BoxShape3D.new()
	sb_shape.size = Vector3(0.5, 0.85, 1.65)
	sb_col.shape = sb_shape
	sb_col.position = Vector3(sb_x, 0.42, sb_z)
	sb_body.add_child(sb_col)

	# --- Area Rug under dining table ---
	var mat_dining_rug: StandardMaterial3D = StandardMaterial3D.new()
	mat_dining_rug.albedo_color = Color(0.15, 0.15, 0.3)
	mat_dining_rug.roughness = 0.9
	_box(self, Vector3(2.5, 0.02, 1.8),
		Vector3(dining_cx, 0.01, dining_cz), mat_dining_rug)

	# --- Potted Plant (southeast corner of dining room) ---
	var plant: Node3D = Node3D.new()
	plant.name = "PottedPlant"
	add_child(plant)
	var plant_x: float = HOUSE_WIDTH - 0.6
	var plant_z: float = 0.6
	# Pot (terracotta)
	var mat_terracotta: StandardMaterial3D = StandardMaterial3D.new()
	mat_terracotta.albedo_color = Color(0.65, 0.35, 0.2)
	mat_terracotta.roughness = 0.85
	_box(plant, Vector3(0.25, 0.3, 0.25),
		Vector3(plant_x, 0.15, plant_z), mat_terracotta)
	# Soil
	var mat_soil: StandardMaterial3D = StandardMaterial3D.new()
	mat_soil.albedo_color = Color(0.2, 0.12, 0.05)
	mat_soil.roughness = 0.95
	_box(plant, Vector3(0.2, 0.03, 0.2),
		Vector3(plant_x, 0.31, plant_z), mat_soil)
	# Plant leaves (green boxes at various heights)
	var mat_plant_leaf: StandardMaterial3D = StandardMaterial3D.new()
	mat_plant_leaf.albedo_color = Color(0.2, 0.45, 0.15)
	mat_plant_leaf.roughness = 0.85
	_box(plant, Vector3(0.15, 0.2, 0.08),
		Vector3(plant_x - 0.05, 0.45, plant_z), mat_plant_leaf)
	_box(plant, Vector3(0.08, 0.25, 0.15),
		Vector3(plant_x + 0.05, 0.5, plant_z + 0.03), mat_plant_leaf)
	_box(plant, Vector3(0.12, 0.18, 0.1),
		Vector3(plant_x, 0.55, plant_z - 0.04), mat_plant_leaf)
	_box(plant, Vector3(0.06, 0.15, 0.12),
		Vector3(plant_x + 0.03, 0.6, plant_z + 0.05), mat_plant_leaf)


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

	# Portrait 1: All-black cat — on west wall, between window (Z≈2.5) and divider (Z=5.0)
	_build_cat_portrait_black(Vector3(wall_x, 1.6, 3.5))

	# Portrait 2: Tuxedo cat — next to first
	_build_cat_portrait_tuxedo(Vector3(wall_x, 1.6, 4.2))


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
# BEDROOM WALLS
# =============================================================================

func _build_bedroom_walls() -> void:
	## Build the three exterior walls of the bedroom extension (west, north, east).
	## The south side is the existing north house wall (with doorway).
	var bz_start: float = HOUSE_DEPTH
	var bz_end: float = BEDROOM_Z_END

	# West bedroom wall (X=0, Z=10 to 17) — 2 windows at Z=12.5 and Z=15.5
	var bw_west: StaticBody3D = StaticBody3D.new()
	bw_west.name = "BedroomWestWall"
	add_child(bw_west)
	var bww1l: float = 12.5 - WIN_WIDTH / 2.0
	var bww1r: float = 12.5 + WIN_WIDTH / 2.0
	var bww2l: float = 15.5 - WIN_WIDTH / 2.0
	var bww2r: float = 15.5 + WIN_WIDTH / 2.0
	_bedroom_west_section(bw_west, bz_start, bww1l, 0.0, CEILING_HEIGHT)
	_bedroom_west_section(bw_west, bww1l, bww1r, 0.0, WIN_SILL_Y)
	_bedroom_west_section(bw_west, bww1l, bww1r, WIN_SILL_Y + WIN_HEIGHT, CEILING_HEIGHT)
	_bedroom_west_section(bw_west, bww1r, bww2l, 0.0, CEILING_HEIGHT)
	_bedroom_west_section(bw_west, bww2l, bww2r, 0.0, WIN_SILL_Y)
	_bedroom_west_section(bw_west, bww2l, bww2r, WIN_SILL_Y + WIN_HEIGHT, CEILING_HEIGHT)
	_bedroom_west_section(bw_west, bww2r, bz_end, 0.0, CEILING_HEIGHT)

	# North bedroom wall (Z=17, X=0 to 6) — 2 windows at X=1.5 and X=4.5
	var bw_north: StaticBody3D = StaticBody3D.new()
	bw_north.name = "BedroomNorthWall"
	add_child(bw_north)
	var bnw1l: float = 1.5 - WIN_WIDTH / 2.0
	var bnw1r: float = 1.5 + WIN_WIDTH / 2.0
	var bnw2l: float = 4.5 - WIN_WIDTH / 2.0
	var bnw2r: float = 4.5 + WIN_WIDTH / 2.0
	_bedroom_north_section(bw_north, 0.0, bnw1l, 0.0, CEILING_HEIGHT)
	_bedroom_north_section(bw_north, bnw1l, bnw1r, 0.0, WIN_SILL_Y)
	_bedroom_north_section(bw_north, bnw1l, bnw1r, WIN_SILL_Y + WIN_HEIGHT, CEILING_HEIGHT)
	_bedroom_north_section(bw_north, bnw1r, bnw2l, 0.0, CEILING_HEIGHT)
	_bedroom_north_section(bw_north, bnw2l, bnw2r, 0.0, WIN_SILL_Y)
	_bedroom_north_section(bw_north, bnw2l, bnw2r, WIN_SILL_Y + WIN_HEIGHT, CEILING_HEIGHT)
	_bedroom_north_section(bw_north, bnw2r, LIVING_ROOM_WIDTH, 0.0, CEILING_HEIGHT)

	# East bedroom wall (X=6, Z=10 to 17) — 2 windows at Z=12.5 and Z=15.5
	var bw_east: StaticBody3D = StaticBody3D.new()
	bw_east.name = "BedroomEastWall"
	add_child(bw_east)
	var bew1l: float = 12.5 - WIN_WIDTH / 2.0
	var bew1r: float = 12.5 + WIN_WIDTH / 2.0
	var bew2l: float = 15.5 - WIN_WIDTH / 2.0
	var bew2r: float = 15.5 + WIN_WIDTH / 2.0
	_bedroom_east_section(bw_east, bz_start, bew1l, 0.0, CEILING_HEIGHT)
	_bedroom_east_section(bw_east, bew1l, bew1r, 0.0, WIN_SILL_Y)
	_bedroom_east_section(bw_east, bew1l, bew1r, WIN_SILL_Y + WIN_HEIGHT, CEILING_HEIGHT)
	_bedroom_east_section(bw_east, bew1r, bew2l, 0.0, CEILING_HEIGHT)
	_bedroom_east_section(bw_east, bew2l, bew2r, 0.0, WIN_SILL_Y)
	_bedroom_east_section(bw_east, bew2l, bew2r, WIN_SILL_Y + WIN_HEIGHT, CEILING_HEIGHT)
	_bedroom_east_section(bw_east, bew2r, bz_end, 0.0, CEILING_HEIGHT)


# =============================================================================
# BEDROOM FURNITURE
# =============================================================================

func _build_bedroom_furniture() -> void:
	## Bed against north wall (between windows), nightstand, dresser.

	# --- Bed (centered at X=3.0 between north wall windows at X=1.5 and X=4.5) ---
	var bed_x: float = 3.0
	var bed_z: float = 16.0  # Center of bed; headboard north (+Z), footboard south (-Z)
	var bed: Node3D = Node3D.new()
	bed.name = "Bed"
	add_child(bed)

	# Bed frame
	_box(bed, Vector3(1.6, 0.3, 2.0),
		Vector3(bed_x, 0.15, bed_z), _mat_furniture_wood)
	# Mattress
	_box(bed, Vector3(1.4, 0.2, 1.9),
		Vector3(bed_x, 0.4, bed_z), _mat_pillow)
	# Bedspread / duvet (toward footboard = south = -Z)
	_box(bed, Vector3(1.5, 0.1, 1.5),
		Vector3(bed_x, 0.55, bed_z - 0.15), _mat_bedding)
	# Pillows (near headboard = north = +Z)
	_box(bed, Vector3(0.5, 0.1, 0.3),
		Vector3(bed_x - 0.2, 0.55, bed_z + 0.75), _mat_pillow)
	_box(bed, Vector3(0.5, 0.1, 0.3),
		Vector3(bed_x + 0.2, 0.55, bed_z + 0.75), _mat_pillow)
	# Headboard (against north wall = +Z)
	_box(bed, Vector3(1.6, 0.8, 0.08),
		Vector3(bed_x, 0.7, bed_z + 1.0), _mat_furniture_wood)
	# Footboard (shorter, toward door = -Z)
	_box(bed, Vector3(1.6, 0.4, 0.08),
		Vector3(bed_x, 0.35, bed_z - 1.0), _mat_furniture_wood)

	# Bed collision (so player can't walk through it)
	var bed_body: StaticBody3D = StaticBody3D.new()
	bed_body.name = "BedCollision"
	add_child(bed_body)
	var bed_col: CollisionShape3D = CollisionShape3D.new()
	var bed_shape: BoxShape3D = BoxShape3D.new()
	bed_shape.size = Vector3(1.6, 0.6, 2.1)
	bed_col.shape = bed_shape
	bed_col.position = Vector3(bed_x, 0.3, bed_z)
	bed_body.add_child(bed_col)

	# --- Nightstand (right side of bed, near headboard = +Z end) ---
	var ns_x: float = bed_x + 1.1
	var ns_z: float = bed_z + 0.7
	var nightstand: Node3D = Node3D.new()
	nightstand.name = "Nightstand"
	add_child(nightstand)

	# Body
	_box(nightstand, Vector3(0.4, 0.5, 0.35),
		Vector3(ns_x, 0.27, ns_z), _mat_furniture_wood)
	# Top
	_box(nightstand, Vector3(0.44, 0.04, 0.38),
		Vector3(ns_x, 0.55, ns_z), _mat_furniture_wood)
	# Drawer face (facing south = -Z toward room)
	_box(nightstand, Vector3(0.32, 0.16, 0.02),
		Vector3(ns_x, 0.35, ns_z - 0.18), _mat_furniture_wood)
	# Handle
	_box(nightstand, Vector3(0.08, 0.02, 0.02),
		Vector3(ns_x, 0.35, ns_z - 0.20), _mat_handle)
	# Lamp on nightstand
	_box(nightstand, Vector3(0.08, 0.15, 0.08),
		Vector3(ns_x, 0.63, ns_z), _mat_kettle)
	_box(nightstand, Vector3(0.15, 0.12, 0.15),
		Vector3(ns_x, 0.78, ns_z), _mat_pillow)

	# --- Dresser (against east wall, between windows at Z=12.5 and Z=15.5) ---
	var dr_x: float = LIVING_ROOM_WIDTH - WALL_THICKNESS - 0.25
	var dr_z: float = 14.0
	var dresser: Node3D = Node3D.new()
	dresser.name = "Dresser"
	add_child(dresser)

	# Body
	_box(dresser, Vector3(0.45, 0.8, 0.9),
		Vector3(dr_x, 0.4, dr_z), _mat_furniture_wood)
	# Top surface
	_box(dresser, Vector3(0.48, 0.04, 0.95),
		Vector3(dr_x, 0.82, dr_z), _mat_furniture_wood)
	# 3 drawer faces (facing -X into room)
	for i: int in range(3):
		var dy: float = 0.2 + float(i) * 0.25
		_box(dresser, Vector3(0.02, 0.18, 0.75),
			Vector3(dr_x - 0.23, dy, dr_z), _mat_furniture_wood)
		_box(dresser, Vector3(0.03, 0.02, 0.12),
			Vector3(dr_x - 0.25, dy, dr_z), _mat_handle)

	# Mirror above dresser
	var mat_mirror: StandardMaterial3D = StandardMaterial3D.new()
	mat_mirror.albedo_color = Color(0.7, 0.75, 0.8, 0.5)
	mat_mirror.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_mirror.roughness = 0.05
	mat_mirror.metallic = 0.8
	_box(dresser, Vector3(0.03, 0.7, 0.65),
		Vector3(dr_x + 0.22, 1.35, dr_z), _mat_portrait_frame)
	_box(dresser, Vector3(0.02, 0.62, 0.57),
		Vector3(dr_x + 0.21, 1.35, dr_z), mat_mirror)

	# Dresser collision
	var dr_body: StaticBody3D = StaticBody3D.new()
	dr_body.name = "DresserCollision"
	add_child(dr_body)
	var dr_col: CollisionShape3D = CollisionShape3D.new()
	var dr_shape: BoxShape3D = BoxShape3D.new()
	dr_shape.size = Vector3(0.5, 0.85, 0.95)
	dr_col.shape = dr_shape
	dr_col.position = Vector3(dr_x, 0.42, dr_z)
	dr_body.add_child(dr_col)

	# --- Bedroom rug ---
	var mat_bedroom_rug: StandardMaterial3D = StandardMaterial3D.new()
	mat_bedroom_rug.albedo_color = Color(0.45, 0.35, 0.55)
	mat_bedroom_rug.roughness = 0.9
	_box(self, Vector3(1.8, 0.02, 1.2),
		Vector3(bed_x, 0.01, bed_z - 1.5), mat_bedroom_rug)

	# --- Reading Chair (near west wall, south of west wall window at Z=12.5) ---
	var rc: Node3D = Node3D.new()
	rc.name = "ReadingChair"
	add_child(rc)
	var rc_x: float = 0.8
	var rc_z: float = 11.0
	# Seat
	_box(rc, Vector3(0.7, 0.35, 0.7),
		Vector3(rc_x, 0.38, rc_z), _mat_upholstery)
	# Back (on +Z side, facing -Z)
	_box(rc, Vector3(0.7, 0.5, 0.12),
		Vector3(rc_x, 0.6, rc_z + 0.35 - 0.06), _mat_upholstery)
	# Left arm
	_box(rc, Vector3(0.12, 0.4, 0.7),
		Vector3(rc_x - 0.35 + 0.06, 0.48, rc_z), _mat_upholstery)
	# Right arm
	_box(rc, Vector3(0.12, 0.4, 0.7),
		Vector3(rc_x + 0.35 - 0.06, 0.48, rc_z), _mat_upholstery)
	# 4 legs
	for rlx: float in [-0.25, 0.25]:
		for rlz: float in [-0.25, 0.25]:
			_box(rc, Vector3(0.05, 0.18, 0.05),
				Vector3(rc_x + rlx, 0.09, rc_z + rlz), _mat_furniture_wood)
	# Small side table next to reading chair
	var rst: Node3D = Node3D.new()
	rst.name = "ReadingSideTable"
	add_child(rst)
	_box(rst, Vector3(0.35, 0.45, 0.35),
		Vector3(1.5, 0.225, rc_z), _mat_furniture_wood)
	_box(rst, Vector3(0.38, 0.04, 0.38),
		Vector3(1.5, 0.47, rc_z), _mat_furniture_wood)

	# --- Wardrobe/Armoire (against south wall near doorway, on west side) ---
	var ward: Node3D = Node3D.new()
	ward.name = "Wardrobe"
	add_child(ward)
	var ward_x: float = 1.0
	var ward_z: float = 10.25
	# Body
	_box(ward, Vector3(1.0, 2.0, 0.5),
		Vector3(ward_x, 1.0, ward_z), _mat_furniture_wood)
	# Two door panels on +Z face (facing into bedroom)
	_box(ward, Vector3(0.42, 1.6, 0.02),
		Vector3(ward_x - 0.24, 0.9, ward_z + 0.26), _mat_furniture_wood)
	_box(ward, Vector3(0.42, 1.6, 0.02),
		Vector3(ward_x + 0.24, 0.9, ward_z + 0.26), _mat_furniture_wood)
	# Door handles
	_box(ward, Vector3(0.02, 0.08, 0.03),
		Vector3(ward_x - 0.04, 1.0, ward_z + 0.28), _mat_handle)
	_box(ward, Vector3(0.02, 0.08, 0.03),
		Vector3(ward_x + 0.04, 1.0, ward_z + 0.28), _mat_handle)
	# Crown piece on top
	_box(ward, Vector3(1.06, 0.06, 0.54),
		Vector3(ward_x, 2.03, ward_z), _mat_furniture_wood)
	# Wardrobe collision
	var ward_body: StaticBody3D = StaticBody3D.new()
	ward_body.name = "WardrobeCollision"
	add_child(ward_body)
	var ward_col: CollisionShape3D = CollisionShape3D.new()
	var ward_shape: BoxShape3D = BoxShape3D.new()
	ward_shape.size = Vector3(1.1, 2.1, 0.55)
	ward_col.shape = ward_shape
	ward_col.position = Vector3(ward_x, 1.05, ward_z)
	ward_body.add_child(ward_col)

	# --- Console table (transition zone, against east wall) ---
	var ct: Node3D = Node3D.new()
	ct.name = "ConsoleTable"
	add_child(ct)
	var ct_x: float = 5.5
	var ct_z: float = 10.5
	# Body
	_box(ct, Vector3(0.4, 0.7, 0.8),
		Vector3(ct_x, 0.35, ct_z), _mat_furniture_wood)
	# Thin top
	_box(ct, Vector3(0.44, 0.04, 0.84),
		Vector3(ct_x, 0.72, ct_z), _mat_furniture_wood)
	# Small vase on top
	var mat_console_vase: StandardMaterial3D = StandardMaterial3D.new()
	mat_console_vase.albedo_color = Color(0.5, 0.55, 0.65)
	mat_console_vase.roughness = 0.4
	_box(ct, Vector3(0.06, 0.1, 0.06),
		Vector3(ct_x, 0.79, ct_z), mat_console_vase)
	_box(ct, Vector3(0.07, 0.01, 0.07),
		Vector3(ct_x, 0.84, ct_z), mat_console_vase)

	# --- Framed photo on west wall in transition zone ---
	var fp_node: Node3D = Node3D.new()
	fp_node.name = "HallwayPhoto"
	add_child(fp_node)
	var fp_wall_x: float = WALL_THICKNESS + 0.03
	var fp_z: float = 10.8
	# Frame (west wall, facing +X)
	_box(fp_node, Vector3(0.03, 0.4, 0.35), Vector3(fp_wall_x, 1.5, fp_z), _mat_portrait_frame)
	# Background
	_box(fp_node, Vector3(0.02, 0.34, 0.29),
		Vector3(fp_wall_x + 0.01, 1.5, fp_z), _mat_portrait_bg)


# =============================================================================
# TREE PICTURES (bedroom wall art)
# =============================================================================

func _build_tree_pictures() -> void:
	## Build 5 framed tree paintings on the bedroom walls.
	# Create shared tree art materials
	var mats: Dictionary = {
		"trunk": _make_mat(Color(0.4, 0.25, 0.12)),
		"pine_trunk": _make_mat(Color(0.55, 0.3, 0.15)),
		"dark_green": _make_mat(Color(0.15, 0.35, 0.12)),
		"green": _make_mat(Color(0.2, 0.42, 0.15)),
		"light_green": _make_mat(Color(0.35, 0.55, 0.2)),
		"birch_bark": _make_mat(Color(0.88, 0.85, 0.8)),
		"birch_marks": _make_mat(Color(0.2, 0.2, 0.2)),
		"cactus": _make_mat(Color(0.25, 0.5, 0.2)),
		"palm_trunk": _make_mat(Color(0.5, 0.35, 0.2)),
		"palm_frond": _make_mat(Color(0.2, 0.5, 0.15)),
	}

	# West wall interior face (between windows at Z=12.5 and Z=15.5)
	# Wall gaps: Z=10-11.9, Z=13.1-14.9, Z=16.1-17
	var wx: float = WALL_THICKNESS + 0.03
	_build_tree_picture(Vector3(wx, 1.6, 11.0), "west", "ponderosa_pine", mats)
	_build_tree_picture(Vector3(wx, 1.6, 14.0), "west", "oak", mats)

	# North wall interior face (above headboard, between windows at X=1.5 and X=4.5)
	var nz: float = BEDROOM_Z_END - WALL_THICKNESS - 0.03
	_build_tree_picture(Vector3(3.0, 1.9, nz), "north", "birch", mats)

	# East wall interior face (between windows at Z=12.5 and Z=15.5)
	var ex: float = LIVING_ROOM_WIDTH - WALL_THICKNESS - 0.03
	_build_tree_picture(Vector3(ex, 1.6, 11.0), "east", "cactus", mats)
	_build_tree_picture(Vector3(ex, 1.6, 16.5), "east", "palm", mats)


func _make_mat(color: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	return m


func _build_tree_picture(pos: Vector3, wall: String, tree_type: String, mats: Dictionary) -> void:
	## Build a framed tree painting at pos on the given wall.
	var p: Node3D = Node3D.new()
	p.name = tree_type.capitalize().replace(" ", "") + "Picture"
	add_child(p)

	var is_ew: bool = (wall == "east" or wall == "west")
	var dir: float = 1.0 if (wall == "west" or wall == "south") else -1.0

	# Frame & background
	if is_ew:
		_box(p, Vector3(0.03, 0.65, 0.55), pos, _mat_portrait_frame)
		_box(p, Vector3(0.02, 0.59, 0.49),
			Vector3(pos.x + dir * 0.01, pos.y, pos.z), _mat_portrait_bg)
	else:
		_box(p, Vector3(0.55, 0.65, 0.03), pos, _mat_portrait_frame)
		_box(p, Vector3(0.49, 0.59, 0.02),
			Vector3(pos.x, pos.y, pos.z + dir * 0.01), _mat_portrait_bg)

	# Get tree art description and place pieces
	var art: Array = _get_tree_art_data(tree_type, mats)
	var thin: float = 0.015
	for piece: Array in art:
		var h_off: float = piece[0]
		var v_off: float = piece[1]
		var h_sz: float = piece[2]
		var v_sz: float = piece[3]
		var mat: StandardMaterial3D = piece[4]
		if is_ew:
			_box(p, Vector3(thin, v_sz, h_sz),
				Vector3(pos.x + dir * 0.02, pos.y + v_off, pos.z + h_off), mat)
		else:
			_box(p, Vector3(h_sz, v_sz, thin),
				Vector3(pos.x + h_off, pos.y + v_off, pos.z + dir * 0.02), mat)

	# Nameplate below painting (small brass plate on dark wood backing)
	var mat_brass: StandardMaterial3D = StandardMaterial3D.new()
	mat_brass.albedo_color = Color(0.7, 0.6, 0.35)
	mat_brass.roughness = 0.4
	mat_brass.metallic = 0.5
	var np_y: float = pos.y - 0.4
	if is_ew:
		# Dark wood backing
		_box(p, Vector3(0.025, 0.06, 0.25),
			Vector3(pos.x + dir * 0.015, np_y, pos.z), _mat_furniture_wood)
		# Brass plate
		_box(p, Vector3(0.028, 0.04, 0.2),
			Vector3(pos.x + dir * 0.02, np_y, pos.z), mat_brass)
	else:
		# Dark wood backing
		_box(p, Vector3(0.25, 0.06, 0.025),
			Vector3(pos.x, np_y, pos.z + dir * 0.015), _mat_furniture_wood)
		# Brass plate
		_box(p, Vector3(0.2, 0.04, 0.028),
			Vector3(pos.x, np_y, pos.z + dir * 0.02), mat_brass)


func _get_tree_art_data(tree_type: String, m: Dictionary) -> Array:
	## Returns Array of [h_offset, v_offset, h_size, v_size, material] for each tree type.
	match tree_type:
		"ponderosa_pine":
			return [
				[0.0, -0.12, 0.05, 0.28, m["pine_trunk"]],    # Tall straight trunk
				[0.0, 0.06, 0.22, 0.14, m["dark_green"]],      # Lower canopy
				[0.0, 0.15, 0.16, 0.12, m["green"]],           # Mid canopy
				[0.0, 0.22, 0.10, 0.10, m["green"]],           # Upper canopy
				[0.0, 0.27, 0.05, 0.06, m["light_green"]],     # Tip
			]
		"oak":
			return [
				[0.0, -0.13, 0.07, 0.24, m["trunk"]],          # Thick trunk
				[-0.06, 0.02, 0.04, 0.06, m["trunk"]],         # Left branch
				[0.06, 0.04, 0.04, 0.06, m["trunk"]],          # Right branch
				[0.0, 0.06, 0.28, 0.14, m["dark_green"]],      # Wide lower crown
				[0.0, 0.15, 0.24, 0.12, m["green"]],           # Mid crown
				[0.0, 0.22, 0.16, 0.08, m["green"]],           # Upper crown
				[-0.06, 0.10, 0.08, 0.06, m["light_green"]],   # Crown accent
			]
		"birch":
			return [
				[0.0, -0.08, 0.035, 0.34, m["birch_bark"]],    # White trunk
				[0.0, -0.18, 0.03, 0.02, m["birch_marks"]],    # Bark mark
				[0.002, -0.08, 0.025, 0.018, m["birch_marks"]],
				[-0.002, 0.0, 0.028, 0.02, m["birch_marks"]],
				[0.001, 0.08, 0.025, 0.015, m["birch_marks"]],
				[0.0, 0.14, 0.2, 0.16, m["light_green"]],      # Light canopy
				[-0.04, 0.10, 0.12, 0.08, m["green"]],         # Canopy accent
				[0.04, 0.20, 0.12, 0.08, m["green"]],          # Upper accent
			]
		"cactus":
			return [
				[0.0, -0.04, 0.08, 0.36, m["cactus"]],         # Main column
				[-0.08, 0.0, 0.08, 0.04, m["cactus"]],         # Left arm horizontal
				[-0.10, 0.08, 0.04, 0.14, m["cactus"]],        # Left arm vertical
				[0.08, 0.06, 0.08, 0.04, m["cactus"]],         # Right arm horizontal
				[0.10, 0.16, 0.04, 0.18, m["cactus"]],         # Right arm vertical
			]
		"palm":
			return [
				[0.0, -0.10, 0.05, 0.32, m["palm_trunk"]],     # Trunk
				[0.0, 0.08, 0.018, 0.02, m["palm_trunk"]],     # Trunk ring
				[0.0, 0.04, 0.018, 0.02, m["palm_trunk"]],     # Trunk ring
				[-0.10, 0.10, 0.18, 0.04, m["palm_frond"]],    # Left frond
				[0.10, 0.10, 0.18, 0.04, m["palm_frond"]],     # Right frond
				[-0.06, 0.15, 0.14, 0.04, m["palm_frond"]],    # Upper left frond
				[0.06, 0.15, 0.14, 0.04, m["palm_frond"]],     # Upper right frond
				[0.0, 0.18, 0.06, 0.06, m["palm_frond"]],      # Top cluster
				[-0.14, 0.06, 0.10, 0.03, m["palm_frond"]],    # Drooping left
				[0.14, 0.06, 0.10, 0.03, m["palm_frond"]],     # Drooping right
			]
	return []


# =============================================================================
# BEDROOM CROWN MOLDING & BASEBOARDS
# =============================================================================

func _build_bedroom_molding() -> void:
	var upper_h: float = 0.10
	var upper_d: float = 0.06
	var lower_h: float = 0.05
	var lower_d: float = 0.10
	var bb_h: float = 0.08
	var bb_d: float = 0.04
	var bb_y: float = bb_h / 2.0

	var y_upper: float = CEILING_HEIGHT - upper_h / 2.0
	var y_lower: float = CEILING_HEIGHT - upper_h - lower_h / 2.0

	# Room interior bounds
	var x_min: float = WALL_THICKNESS
	var x_max: float = LIVING_ROOM_WIDTH - WALL_THICKNESS
	var z_min: float = HOUSE_DEPTH  # South wall (interior face)
	var z_max: float = BEDROOM_Z_END - WALL_THICKNESS
	var rw: float = x_max - x_min  # Room width (~5.7)
	var rd: float = z_max - z_min  # Room depth (~4.85)
	var rcx: float = x_min + rw / 2.0
	var rcz: float = z_min + rd / 2.0

	# South wall molding (split around doorway)
	var bdl: float = BEDROOM_DOOR_X - BEDROOM_DOOR_WIDTH / 2.0
	var bdr: float = BEDROOM_DOOR_X + BEDROOM_DOOR_WIDTH / 2.0
	var left_w: float = bdl - x_min
	var right_w: float = x_max - bdr
	if left_w > 0:
		var lcx: float = x_min + left_w / 2.0
		_box(self, Vector3(left_w, upper_h, upper_d), Vector3(lcx, y_upper, z_min + upper_d / 2.0), _mat_molding)
		_box(self, Vector3(left_w, lower_h, lower_d), Vector3(lcx, y_lower, z_min + lower_d / 2.0), _mat_molding)
		_box(self, Vector3(left_w, bb_h, bb_d), Vector3(lcx, bb_y, z_min + bb_d / 2.0), _mat_molding)
	if right_w > 0:
		var rrx: float = bdr + right_w / 2.0
		_box(self, Vector3(right_w, upper_h, upper_d), Vector3(rrx, y_upper, z_min + upper_d / 2.0), _mat_molding)
		_box(self, Vector3(right_w, lower_h, lower_d), Vector3(rrx, y_lower, z_min + lower_d / 2.0), _mat_molding)
		_box(self, Vector3(right_w, bb_h, bb_d), Vector3(rrx, bb_y, z_min + bb_d / 2.0), _mat_molding)

	# North wall molding
	_box(self, Vector3(rw, upper_h, upper_d), Vector3(rcx, y_upper, z_max - upper_d / 2.0), _mat_molding)
	_box(self, Vector3(rw, lower_h, lower_d), Vector3(rcx, y_lower, z_max - lower_d / 2.0), _mat_molding)
	_box(self, Vector3(rw, bb_h, bb_d), Vector3(rcx, bb_y, z_max - bb_d / 2.0), _mat_molding)

	# West wall molding
	_box(self, Vector3(upper_d, upper_h, rd), Vector3(x_min + upper_d / 2.0, y_upper, rcz), _mat_molding)
	_box(self, Vector3(lower_d, lower_h, rd), Vector3(x_min + lower_d / 2.0, y_lower, rcz), _mat_molding)
	_box(self, Vector3(bb_d, bb_h, rd), Vector3(x_min + bb_d / 2.0, bb_y, rcz), _mat_molding)

	# East wall molding
	_box(self, Vector3(upper_d, upper_h, rd), Vector3(x_max - upper_d / 2.0, y_upper, rcz), _mat_molding)
	_box(self, Vector3(lower_d, lower_h, rd), Vector3(x_max - lower_d / 2.0, y_lower, rcz), _mat_molding)
	_box(self, Vector3(bb_d, bb_h, rd), Vector3(x_max - bb_d / 2.0, bb_y, rcz), _mat_molding)


# =============================================================================
# LIGHTING
# =============================================================================

func _setup_lighting() -> void:
	# Living room — warm with fireplace accent
	_add_light("LivingLight1", Vector3(2.0, 2.5, 1.5),
		Color(1.0, 0.88, 0.65), 0.7, 6.0)  # Warm, slightly dimmer
	_add_light("LivingLight2", Vector3(4.0, 2.5, 3.5),
		Color(1.0, 0.9, 0.7), 0.6, 5.0)
	# Fireplace glow (low, warm orange near floor level)
	_add_light("FireplaceGlow", Vector3(0.5, 0.4, 0.95),
		Color(1.0, 0.6, 0.3), 0.5, 3.0)
	# End table lamp
	_add_light("EndTableLamp", Vector3(3.5, 1.0, 2.8),
		Color(1.0, 0.9, 0.7), 0.4, 3.0)

	# Kitchen — slightly cooler/brighter (task lighting)
	_add_light("KitchenLight", Vector3(3.0, 2.5, 7.5),
		Color(1.0, 0.95, 0.85), 1.1, 5.0)

	# Dining room — chandelier with shadow
	var dining_cx: float = LIVING_ROOM_WIDTH + DINING_ROOM_WIDTH / 2.0
	_add_light_with_shadow("DiningChandelier", Vector3(dining_cx, 2.4, HOUSE_DEPTH / 2.0),
		Color(1.0, 0.92, 0.75), 1.0, 7.0)
	_add_light("DiningFill", Vector3(dining_cx, 2.5, 2.0),
		Color(1.0, 0.9, 0.7), 0.4, 5.0)

	# Bedroom — warmer, dimmer, cozy
	_add_light("BedroomLight1", Vector3(3.0, 2.5, 13.5),
		Color(1.0, 0.85, 0.6), 0.6, 6.0)
	_add_light("BedroomLight2", Vector3(3.0, 2.5, 15.5),
		Color(1.0, 0.85, 0.65), 0.4, 5.0)
	# Nightstand lamp glow
	_add_light("NightstandLamp", Vector3(4.1, 0.9, 16.7),
		Color(1.0, 0.85, 0.6), 0.3, 2.5)


func _add_light(light_name: String, pos: Vector3, color: Color, energy: float, light_range: float) -> void:
	var light: OmniLight3D = OmniLight3D.new()
	light.name = light_name
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	light.shadow_enabled = false  # No shadows for indoor lamps (performance)
	add_child(light)


func _add_light_with_shadow(light_name: String, pos: Vector3, color: Color, energy: float, light_range: float) -> void:
	var light: OmniLight3D = OmniLight3D.new()
	light.name = light_name
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	light.shadow_enabled = true
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
# HOUSE PAUSE MENU
# =============================================================================

const HousePauseMenuScript: GDScript = preload("res://scripts/house/house_pause_menu.gd")

func _build_pause_menu() -> void:
	var pause_menu: CanvasLayer = CanvasLayer.new()
	pause_menu.name = "HousePauseMenu"
	pause_menu.set_script(HousePauseMenuScript)
	add_child(pause_menu)


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
