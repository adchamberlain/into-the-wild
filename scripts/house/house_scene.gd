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

	# North wall (Z=HOUSE_DEPTH) — window at X=3.0
	var north: StaticBody3D = StaticBody3D.new()
	north.name = "NorthWall"
	add_child(north)
	var nwl: float = 3.0 - WIN_WIDTH / 2.0
	var nwr: float = 3.0 + WIN_WIDTH / 2.0
	_north_wall_section(north, 0.0, nwl, 0.0, CEILING_HEIGHT)
	_north_wall_section(north, nwl, nwr, 0.0, WIN_SILL_Y)
	_north_wall_section(north, nwl, nwr, WIN_SILL_Y + WIN_HEIGHT, CEILING_HEIGHT)
	_north_wall_section(north, nwr, HOUSE_WIDTH, 0.0, CEILING_HEIGHT)

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
	# North wall window
	_build_six_pane_window("north", 3.0)   # Kitchen
	# East wall windows
	_build_six_pane_window("east", 3.0)    # Dining room
	_build_six_pane_window("east", 7.0)    # Dining room


func _build_six_pane_window(wall: String, coord: float) -> void:
	## Places a colonial six-pane window inside a wall opening.
	## coord is the X-position for south/north walls, Z-position for east/west walls.
	var wc: Node3D = Node3D.new()
	wc.name = "Window"
	add_child(wc)

	var cy: float = WIN_SILL_Y + WIN_HEIGHT / 2.0
	var is_ns: bool = (wall == "south" or wall == "north")

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
		_box(wc, Vector3(WIN_WIDTH - 0.06, WIN_HEIGHT * 0.55, thin), sky_p, _mat_window_sky)
		# Hills backdrop (lower 40%)
		var hill_p: Vector3 = backdrop_pos
		hill_p.y -= WIN_HEIGHT * 0.25
		_box(wc, Vector3(WIN_WIDTH - 0.06, WIN_HEIGHT * 0.4, thin), hill_p, _mat_window_hills)
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
		_box(wc, Vector3(thin, WIN_HEIGHT * 0.55, WIN_WIDTH - 0.06), sky_p, _mat_window_sky)
		# Hills backdrop
		var hill_p: Vector3 = backdrop_pos
		hill_p.y -= WIN_HEIGHT * 0.25
		_box(wc, Vector3(thin, WIN_HEIGHT * 0.4, WIN_WIDTH - 0.06), hill_p, _mat_window_hills)
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

	# --- Bookshelves (against kitchen divider wall, left of doorway) ---
	_build_bookshelf(Vector3(1.0, 0.0, LIVING_ROOM_DEPTH - 0.4))

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

	# --- L-shaped Counter ---
	# Main run along north wall (X 1.5 to 4.0)
	var counter_x: float = 2.75
	var counter_z: float = HOUSE_DEPTH - 0.5
	# Counter top
	_box(self, Vector3(2.5, 0.05, 0.6),
		Vector3(counter_x, 0.9, counter_z), _mat_furniture_wood)
	# Counter base
	_box(self, Vector3(2.5, 0.85, 0.6),
		Vector3(counter_x, 0.425, counter_z), _mat_cabinet_face)
	# Cabinet doors (3 sections)
	for cx: float in [-0.7, 0.0, 0.7]:
		_box(self, Vector3(0.6, 0.65, 0.02),
			Vector3(counter_x + cx, 0.4, counter_z + 0.31), _mat_cabinet_face)
		_box(self, Vector3(0.1, 0.02, 0.03),
			Vector3(counter_x + cx, 0.5, counter_z + 0.33), _mat_handle)

	# L-return along center divider (Z 8.0 to 9.5)
	var return_x: float = LIVING_ROOM_WIDTH - 0.5
	var return_z: float = 8.75
	_box(self, Vector3(0.6, 0.05, 1.5),
		Vector3(return_x, 0.9, return_z), _mat_furniture_wood)
	_box(self, Vector3(0.6, 0.85, 1.5),
		Vector3(return_x, 0.425, return_z), _mat_cabinet_face)
	# Cabinet doors on return
	for cz: float in [-0.35, 0.35]:
		_box(self, Vector3(0.02, 0.65, 0.6),
			Vector3(return_x - 0.31, 0.4, return_z + cz), _mat_cabinet_face)
		_box(self, Vector3(0.03, 0.02, 0.1),
			Vector3(return_x - 0.33, 0.5, return_z + cz), _mat_handle)

	# --- Sink (dark recess in counter, under kitchen window at X=3.0) ---
	var mat_sink: StandardMaterial3D = StandardMaterial3D.new()
	mat_sink.albedo_color = Color(0.3, 0.3, 0.32)
	mat_sink.roughness = 0.3
	mat_sink.metallic = 0.5
	_box(self, Vector3(0.5, 0.04, 0.35),
		Vector3(3.0, 0.89, counter_z + 0.05), mat_sink)
	# Faucet
	_box(self, Vector3(0.03, 0.2, 0.03),
		Vector3(3.0, 1.02, counter_z - 0.15), _mat_kettle)
	_box(self, Vector3(0.03, 0.03, 0.1),
		Vector3(3.0, 1.12, counter_z - 0.10), _mat_kettle)

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

	# 2 stools at kitchen table
	for sx: float in [-0.55, 0.55]:
		_box(self, Vector3(0.3, 0.04, 0.3),
			Vector3(table_x + sx, 0.5, table_z), _mat_furniture_wood)
		for slx: float in [-0.1, 0.1]:
			for slz: float in [-0.1, 0.1]:
				_box(self, Vector3(0.04, 0.48, 0.04),
					Vector3(table_x + sx + slx, 0.24, table_z + slz), _mat_furniture_wood)

	# --- Counter-top items ---
	# Cutting board (on main counter)
	_box(self, Vector3(0.25, 0.02, 0.18),
		Vector3(2.0, 0.935, counter_z + 0.1), _mat_furniture_wood)
	# Fruit bowl (on L-return)
	var mat_bowl: StandardMaterial3D = StandardMaterial3D.new()
	mat_bowl.albedo_color = Color(0.85, 0.82, 0.75)
	mat_bowl.roughness = 0.5
	_box(self, Vector3(0.2, 0.1, 0.2),
		Vector3(return_x, 0.97, 8.3), mat_bowl)
	# Fruit (small colored boxes in bowl)
	var mat_apple: StandardMaterial3D = StandardMaterial3D.new()
	mat_apple.albedo_color = Color(0.7, 0.15, 0.1)
	mat_apple.roughness = 0.8
	var mat_banana: StandardMaterial3D = StandardMaterial3D.new()
	mat_banana.albedo_color = Color(0.9, 0.8, 0.2)
	mat_banana.roughness = 0.8
	_box(self, Vector3(0.06, 0.06, 0.06),
		Vector3(return_x - 0.03, 1.05, 8.27), mat_apple)
	_box(self, Vector3(0.06, 0.06, 0.06),
		Vector3(return_x + 0.04, 1.05, 8.32), mat_apple)
	_box(self, Vector3(0.04, 0.04, 0.12),
		Vector3(return_x, 1.04, 8.3), mat_banana)


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

	# Portrait 1: All-black cat — on west wall, between corner and window
	_build_cat_portrait_black(Vector3(wall_x, 1.6, 0.8))

	# Portrait 2: Tuxedo cat — next to first
	_build_cat_portrait_tuxedo(Vector3(wall_x, 1.6, 1.4))


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
