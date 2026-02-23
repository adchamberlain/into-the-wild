extends CanvasLayer
class_name MapUI
## HUD minimap overlay showing terrain, water, caves, structures, and player position.
## Displays on the right side below the time/camp level panel with transparency.

const HUD_FONT: Font = preload("res://resources/hud_font.tres")

# Map sampling extent (world units from center in each direction)
const MAP_EXTENT: float = 150.0
# Sample interval (world units between each terrain sample)
const SAMPLE_INTERVAL: float = 6.0
# Map display size (pixels)
const MAP_SIZE: float = 700.0
# Map padding from edges of the control
const MAP_PADDING: float = 8.0
# Position below TimePanel and weather info (pushed down to avoid overlap)
const MAP_TOP: float = 380.0
const MAP_RIGHT_MARGIN: float = 20.0

# Cached map data
var region_grid: Array = []  # Array of {x, z, region, in_water}
var cave_entrances_data: Array = []
var structure_positions: Array = []  # Array of {x, z, type}
var player_pos: Vector3 = Vector3.ZERO
var map_center: Vector2 = Vector2.ZERO  # World XZ center of map (tracks player)
var _last_gather_center: Vector2 = Vector2.ZERO  # Center when data was last sampled
const REGATHER_DISTANCE: float = 40.0  # Re-sample terrain when player moves this far

# UI nodes
var map_panel: PanelContainer
var map_control: Control

# Region colors for the map
const REGION_COLORS: Dictionary = {
	0: Color(0.55, 0.78, 0.4, 0.55),   # MEADOW - light green
	1: Color(0.2, 0.5, 0.2, 0.55),     # FOREST - dark green
	2: Color(0.55, 0.55, 0.3, 0.55),   # HILLS - olive
	3: Color(0.5, 0.45, 0.35, 0.55),   # ROCKY - grey-brown
	4: Color(0.55, 0.55, 0.55, 0.55),  # MOUNTAIN - grey
}

const WATER_COLOR: Color = Color(0.2, 0.45, 0.75, 0.55)


func _ready() -> void:
	layer = 90  # Below HUD (60) would hide it; above HUD so map renders on top
	add_to_group("map_ui")
	_build_ui()
	_gather_map_data()
	map_control.queue_redraw()


func _process(_delta: float) -> void:
	# Track player position and keep map centered on them
	var player_node: Node = get_tree().get_first_node_in_group("player")
	if player_node and is_instance_valid(player_node):
		var new_pos: Vector3 = player_node.global_position
		if new_pos != player_pos:
			player_pos = new_pos
			map_center = Vector2(player_pos.x, player_pos.z)
			# Re-sample terrain when player has moved far enough
			if map_center.distance_to(_last_gather_center) > REGATHER_DISTANCE:
				_gather_map_data()
			map_control.queue_redraw()


func _build_ui() -> void:
	# Panel background with transparency
	map_panel = PanelContainer.new()
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.1, 0.35)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.content_margin_left = 8
	panel_style.content_margin_top = 8
	panel_style.content_margin_right = 8
	panel_style.content_margin_bottom = 8
	map_panel.add_theme_stylebox_override("panel", panel_style)

	# Position at top-right, below TimePanel
	map_panel.anchor_left = 1.0
	map_panel.anchor_right = 1.0
	map_panel.anchor_top = 0.0
	map_panel.anchor_bottom = 0.0
	map_panel.offset_left = -(MAP_SIZE + MAP_RIGHT_MARGIN + 16)
	map_panel.offset_top = MAP_TOP
	map_panel.offset_right = -MAP_RIGHT_MARGIN
	map_panel.offset_bottom = MAP_TOP + MAP_SIZE + 16
	map_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	map_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(map_panel)

	# Map drawing control (square, inside panel)
	map_control = Control.new()
	map_control.custom_minimum_size = Vector2(MAP_SIZE, MAP_SIZE)
	map_control.clip_contents = true
	map_control.draw.connect(_on_map_draw)
	map_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_panel.add_child(map_control)


func _gather_map_data() -> void:
	var tree: SceneTree = get_tree()
	if not tree:
		return

	# Get chunk manager for terrain data
	var chunk_manager: Node = tree.get_first_node_in_group("chunk_manager")

	# Get player position and set map center
	var player_node: Node = tree.get_first_node_in_group("player")
	if player_node:
		player_pos = player_node.global_position
		map_center = Vector2(player_pos.x, player_pos.z)
	_last_gather_center = map_center

	# Build water body and river lookup data
	var water_bodies: Array = []
	var rivers: Array = []
	if chunk_manager:
		if "water_bodies" in chunk_manager:
			water_bodies = chunk_manager.water_bodies
		if "rivers" in chunk_manager:
			rivers = chunk_manager.rivers

	# Sample terrain regions and mark water cells centered on player position
	region_grid.clear()
	if chunk_manager and chunk_manager.has_method("get_region_at"):
		var half: float = MAP_EXTENT
		var x: float = map_center.x - half
		while x <= map_center.x + half:
			var z: float = map_center.y - half
			while z <= map_center.y + half:
				var region: int = chunk_manager.get_region_at(x, z)
				var in_water: bool = _is_in_water(x, z, water_bodies, rivers)
				region_grid.append({"x": x, "z": z, "region": region, "in_water": in_water})
				z += SAMPLE_INTERVAL
			x += SAMPLE_INTERVAL

	# Copy cave entrances
	cave_entrances_data.clear()
	if chunk_manager and "cave_entrances" in chunk_manager:
		for cave in chunk_manager.cave_entrances:
			cave_entrances_data.append(cave.duplicate())

	# Gather placed structures (cabins, tents, shelters)
	_gather_structures()


func _is_in_water(x: float, z: float, water_bodies: Array, rivers: Array) -> bool:
	## Check if a world position is inside a water body or river.
	for body in water_bodies:
		var center: Vector2 = body.get("center", Vector2.ZERO)
		var radius: float = body.get("radius", 5.0)
		if Vector2(x, z).distance_to(center) < radius:
			return true
	for river in rivers:
		var path: Array = river.get("path", [])
		var width: float = river.get("width", 6.0)
		var half_width: float = width / 2.0
		for i: int in range(1, path.size()):
			var seg_start: Vector2 = path[i - 1]
			var seg_end: Vector2 = path[i]
			var closest: Vector2 = _closest_point_on_segment(Vector2(x, z), seg_start, seg_end)
			if Vector2(x, z).distance_to(closest) < half_width:
				return true
	return false


func _closest_point_on_segment(point: Vector2, seg_start: Vector2, seg_end: Vector2) -> Vector2:
	var seg: Vector2 = seg_end - seg_start
	var len_sq: float = seg.length_squared()
	if len_sq < 0.001:
		return seg_start
	var t: float = clamp((point - seg_start).dot(seg) / len_sq, 0.0, 1.0)
	return seg_start + seg * t


func _gather_structures() -> void:
	structure_positions.clear()
	var campsite_manager: Node = get_tree().get_first_node_in_group("campsite_manager")
	if not campsite_manager:
		campsite_manager = get_node_or_null("/root/Main/CampsiteManager")
	if not campsite_manager or not campsite_manager.has_method("get_placed_structures"):
		return
	var structures: Array = campsite_manager.get_placed_structures()
	for structure: Node in structures:
		if not is_instance_valid(structure):
			continue
		var stype: String = ""
		if "structure_type" in structure:
			stype = structure.structure_type
		# Only show shelters (cabin, canvas_tent, basic_shelter) on map
		if stype in ["cabin", "canvas_tent", "basic_shelter"]:
			var pos: Vector3 = structure.global_position
			structure_positions.append({"x": pos.x, "z": pos.z, "type": stype})


func _world_to_map(world_x: float, world_z: float) -> Vector2:
	## Convert world XZ coordinates to pixel position on the map control.
	var norm_x: float = (world_x - map_center.x + MAP_EXTENT) / (MAP_EXTENT * 2.0)
	var norm_z: float = (world_z - map_center.y + MAP_EXTENT) / (MAP_EXTENT * 2.0)
	return Vector2(
		MAP_PADDING + norm_x * (MAP_SIZE - MAP_PADDING * 2.0),
		MAP_PADDING + norm_z * (MAP_SIZE - MAP_PADDING * 2.0)
	)


func _on_map_draw() -> void:
	# Draw map background (dark base)
	var bg_rect: Rect2 = Rect2(MAP_PADDING, MAP_PADDING,
		MAP_SIZE - MAP_PADDING * 2.0, MAP_SIZE - MAP_PADDING * 2.0)
	map_control.draw_rect(bg_rect, Color(0.12, 0.12, 0.14, 0.5))

	# Draw terrain grid cells (blocky - water included as cell color)
	var cell_size: float = (MAP_SIZE - MAP_PADDING * 2.0) / (MAP_EXTENT * 2.0) * SAMPLE_INTERVAL
	for sample in region_grid:
		var pos: Vector2 = _world_to_map(sample["x"], sample["z"])
		var color: Color
		if sample["in_water"]:
			color = WATER_COLOR
		else:
			color = REGION_COLORS.get(sample["region"], Color(0.3, 0.3, 0.3, 1))
		var rect: Rect2 = Rect2(pos.x - cell_size / 2.0, pos.y - cell_size / 2.0, cell_size, cell_size)
		map_control.draw_rect(rect, color)

	# Draw cave entrances as small dark squares with outline
	for cave in cave_entrances_data:
		var center: Vector2 = cave.get("center", Vector2.ZERO)
		var map_pos: Vector2 = _world_to_map(center.x, center.y)
		var cave_size: float = 12.0
		var cave_rect: Rect2 = Rect2(map_pos.x - cave_size / 2.0, map_pos.y - cave_size / 2.0, cave_size, cave_size)
		map_control.draw_rect(cave_rect, Color(0.15, 0.1, 0.1, 1))
		map_control.draw_rect(cave_rect, Color(0.5, 0.35, 0.35, 1), false, 1.0)

	# Draw structure icons
	for struct in structure_positions:
		var map_pos: Vector2 = _world_to_map(struct["x"], struct["z"])
		_draw_structure_icon(map_pos, struct["type"])

	# Draw campsite origin (0,0) if within map bounds
	var camp_offset_x: float = abs(0.0 - map_center.x)
	var camp_offset_z: float = abs(0.0 - map_center.y)
	if camp_offset_x <= MAP_EXTENT and camp_offset_z <= MAP_EXTENT:
		var camp_pos: Vector2 = _world_to_map(0.0, 0.0)
		map_control.draw_circle(camp_pos, 4.0, Color(1.0, 0.85, 0.3, 1))
		map_control.draw_circle(camp_pos, 4.0, Color(0.8, 0.65, 0.1, 1), false, 1.5)

	# Draw player position as X marker with edge clamping
	var raw_player_pos: Vector2 = _world_to_map(player_pos.x, player_pos.z)
	var map_min: float = MAP_PADDING
	var map_max: float = MAP_SIZE - MAP_PADDING

	var is_off_map: bool = (abs(player_pos.x - map_center.x) > MAP_EXTENT
		or abs(player_pos.z - map_center.y) > MAP_EXTENT)

	var player_map_pos: Vector2 = Vector2(
		clamp(raw_player_pos.x, map_min, map_max),
		clamp(raw_player_pos.y, map_min, map_max)
	)

	var x_size: float = 6.0
	var x_width: float = 2.5
	var x_color: Color = Color(1, 0.3, 0.3, 1) if is_off_map else Color(1, 1, 1, 1)
	var x_outline: Color = Color(0.1, 0.1, 0.1, 1)

	# Draw circle behind X for visibility
	map_control.draw_circle(player_map_pos, x_size + 2.0, Color(0.1, 0.1, 0.1, 0.7))
	# Draw X outline
	map_control.draw_line(player_map_pos + Vector2(-x_size, -x_size), player_map_pos + Vector2(x_size, x_size), x_outline, x_width + 2.0)
	map_control.draw_line(player_map_pos + Vector2(x_size, -x_size), player_map_pos + Vector2(-x_size, x_size), x_outline, x_width + 2.0)
	# Draw X
	map_control.draw_line(player_map_pos + Vector2(-x_size, -x_size), player_map_pos + Vector2(x_size, x_size), x_color, x_width)
	map_control.draw_line(player_map_pos + Vector2(x_size, -x_size), player_map_pos + Vector2(-x_size, x_size), x_color, x_width)

	# Draw border
	var border_rect: Rect2 = Rect2(MAP_PADDING - 1, MAP_PADDING - 1,
		MAP_SIZE - MAP_PADDING * 2.0 + 2, MAP_SIZE - MAP_PADDING * 2.0 + 2)
	map_control.draw_rect(border_rect, Color(0.4, 0.35, 0.25, 0.8), false, 1.5)

	# Draw "N" indicator at top center
	var north_pos: Vector2 = Vector2(MAP_SIZE / 2.0, MAP_PADDING - 2)
	map_control.draw_string(HUD_FONT, north_pos, "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(1.0, 0.4, 0.4, 0.9))


func _draw_structure_icon(pos: Vector2, structure_type: String) -> void:
	## Draw a small icon for a placed structure on the map.
	var icon_size: float = 4.0
	var icon_color: Color
	match structure_type:
		"cabin":
			icon_color = Color(0.65, 0.45, 0.25, 1)  # Wood brown
			icon_size = 5.0
		"canvas_tent":
			icon_color = Color(0.7, 0.65, 0.5, 1)  # Canvas tan
		"basic_shelter":
			icon_color = Color(0.5, 0.55, 0.35, 1)  # Shelter green
		_:
			icon_color = Color(0.6, 0.6, 0.6, 1)
	# Draw as small filled square with outline
	var rect: Rect2 = Rect2(pos.x - icon_size / 2.0, pos.y - icon_size / 2.0, icon_size, icon_size)
	map_control.draw_rect(rect, icon_color)
	map_control.draw_rect(rect, Color(1, 1, 1, 0.6), false, 1.0)


func close_map() -> void:
	queue_free()
