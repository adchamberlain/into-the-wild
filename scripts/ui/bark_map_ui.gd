extends CanvasLayer
class_name BarkMapUI
## Fullscreen wilderness map overlay showing terrain, water, caves, campsite, and player position.

const HUD_FONT: Font = preload("res://resources/hud_font.tres")

# Map sampling extent (world units from center in each direction)
const MAP_EXTENT: float = 150.0
# Sample interval (world units between each terrain sample)
const SAMPLE_INTERVAL: float = 6.0
# Map display size (pixels)
const MAP_SIZE: float = 2100.0
# Map padding from edges
const MAP_PADDING: float = 40.0

# Cached map data
var region_grid: Array = []  # Array of {x, z, region}
var water_bodies_data: Array = []
var rivers_data: Array = []
var cave_entrances_data: Array = []
var player_pos: Vector3 = Vector3.ZERO

# UI nodes
var map_control: Control
var background: ColorRect

# Region colors for the map
const REGION_COLORS: Dictionary = {
	0: Color(0.55, 0.78, 0.4, 1),   # MEADOW - light green
	1: Color(0.2, 0.5, 0.2, 1),     # FOREST - dark green
	2: Color(0.55, 0.55, 0.3, 1),   # HILLS - olive
	3: Color(0.5, 0.45, 0.35, 1),   # ROCKY - grey-brown
	4: Color(0.55, 0.55, 0.55, 1),  # MOUNTAIN - grey
}


func _ready() -> void:
	layer = 100
	add_to_group("map_ui")
	_build_ui()
	_gather_map_data()
	map_control.queue_redraw()


func _build_ui() -> void:
	# Dark semi-transparent fullscreen background
	background = ColorRect.new()
	background.color = Color(0.05, 0.05, 0.08, 0.85)
	background.anchors_preset = Control.PRESET_FULL_RECT
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background)

	# Title label
	var title: Label = Label.new()
	title.text = "WILDERNESS MAP"
	title.add_theme_font_override("font", HUD_FONT)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchors_preset = Control.PRESET_TOP_WIDE
	title.offset_top = 30.0
	title.offset_bottom = 90.0
	add_child(title)

	# Close hint
	var hint: Label = Label.new()
	hint.text = "[R] Close Map"
	hint.add_theme_font_override("font", HUD_FONT)
	hint.add_theme_font_size_override("font_size", 28)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.anchors_preset = Control.PRESET_BOTTOM_WIDE
	hint.offset_top = -60.0
	hint.offset_bottom = -20.0
	add_child(hint)

	# North indicator
	var north_label: Label = Label.new()
	north_label.text = "N"
	north_label.add_theme_font_override("font", HUD_FONT)
	north_label.add_theme_font_size_override("font_size", 36)
	north_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1))
	north_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	north_label.anchors_preset = Control.PRESET_TOP_WIDE
	north_label.offset_top = 85.0
	north_label.offset_bottom = 125.0
	add_child(north_label)

	# Map drawing control (centered square)
	map_control = Control.new()
	map_control.custom_minimum_size = Vector2(MAP_SIZE, MAP_SIZE)
	map_control.anchors_preset = Control.PRESET_CENTER
	map_control.offset_left = -MAP_SIZE / 2.0
	map_control.offset_top = -MAP_SIZE / 2.0 + 20.0
	map_control.offset_right = MAP_SIZE / 2.0
	map_control.offset_bottom = MAP_SIZE / 2.0 + 20.0
	map_control.draw.connect(_on_map_draw)
	add_child(map_control)


func _gather_map_data() -> void:
	var tree: SceneTree = get_tree()
	if not tree:
		return

	# Get chunk manager for terrain data
	var chunk_manager: Node = tree.get_first_node_in_group("chunk_manager")

	# Get player position
	var player_node: Node = tree.get_first_node_in_group("player")
	if player_node:
		player_pos = player_node.global_position

	# Sample terrain regions
	region_grid.clear()
	if chunk_manager and chunk_manager.has_method("get_region_at"):
		var half: float = MAP_EXTENT
		var x: float = -half
		while x <= half:
			var z: float = -half
			while z <= half:
				var region: int = chunk_manager.get_region_at(x, z)
				region_grid.append({"x": x, "z": z, "region": region})
				z += SAMPLE_INTERVAL
			x += SAMPLE_INTERVAL

	# Copy water bodies
	if chunk_manager and "water_bodies" in chunk_manager:
		for body in chunk_manager.water_bodies:
			water_bodies_data.append(body.duplicate())

	# Copy rivers
	if chunk_manager and "rivers" in chunk_manager:
		for river in chunk_manager.rivers:
			rivers_data.append(river.duplicate())

	# Copy cave entrances
	if chunk_manager and "cave_entrances" in chunk_manager:
		for cave in chunk_manager.cave_entrances:
			cave_entrances_data.append(cave.duplicate())


func _world_to_map(world_x: float, world_z: float) -> Vector2:
	## Convert world XZ coordinates to pixel position on the map control.
	var norm_x: float = (world_x + MAP_EXTENT) / (MAP_EXTENT * 2.0)
	var norm_z: float = (world_z + MAP_EXTENT) / (MAP_EXTENT * 2.0)
	return Vector2(
		MAP_PADDING + norm_x * (MAP_SIZE - MAP_PADDING * 2.0),
		MAP_PADDING + norm_z * (MAP_SIZE - MAP_PADDING * 2.0)
	)


func _on_map_draw() -> void:
	# Draw map border
	var border_rect: Rect2 = Rect2(MAP_PADDING - 2, MAP_PADDING - 2,
		MAP_SIZE - MAP_PADDING * 2.0 + 4, MAP_SIZE - MAP_PADDING * 2.0 + 4)
	map_control.draw_rect(border_rect, Color(0.3, 0.3, 0.3, 1), false, 2.0)

	# Draw terrain grid cells
	var cell_size: float = (MAP_SIZE - MAP_PADDING * 2.0) / (MAP_EXTENT * 2.0) * SAMPLE_INTERVAL
	for sample in region_grid:
		var pos: Vector2 = _world_to_map(sample["x"], sample["z"])
		var color: Color = REGION_COLORS.get(sample["region"], Color(0.3, 0.3, 0.3, 1))
		var rect: Rect2 = Rect2(pos.x - cell_size / 2.0, pos.y - cell_size / 2.0, cell_size, cell_size)
		map_control.draw_rect(rect, color)

	# Draw water bodies
	var map_scale: float = (MAP_SIZE - MAP_PADDING * 2.0) / (MAP_EXTENT * 2.0)
	for body in water_bodies_data:
		var center: Vector2 = body.get("center", Vector2.ZERO)
		var radius: float = body.get("radius", 5.0)
		var map_pos: Vector2 = _world_to_map(center.x, center.y)
		var map_radius: float = max(radius * map_scale, 3.0)
		map_control.draw_circle(map_pos, map_radius, Color(0.2, 0.45, 0.75, 0.9))

	# Draw rivers
	for river in rivers_data:
		var path: Array = river.get("path", [])
		for i in range(1, path.size()):
			var seg_start: Vector2 = path[i - 1]
			var seg_end: Vector2 = path[i]
			var map_start: Vector2 = _world_to_map(seg_start.x, seg_start.y)
			var map_end: Vector2 = _world_to_map(seg_end.x, seg_end.y)
			map_control.draw_line(map_start, map_end, Color(0.2, 0.45, 0.75, 0.9), 3.0)

	# Draw cave entrances
	for cave in cave_entrances_data:
		var center: Vector2 = cave.get("center", Vector2.ZERO)
		var map_pos: Vector2 = _world_to_map(center.x, center.y)
		var cave_rect: Rect2 = Rect2(map_pos.x - 5, map_pos.y - 5, 10, 10)
		map_control.draw_rect(cave_rect, Color(0.15, 0.1, 0.1, 1))
		map_control.draw_rect(cave_rect, Color(0.4, 0.3, 0.3, 1), false, 1.0)

	# Draw campsite at (0,0)
	var camp_pos: Vector2 = _world_to_map(0.0, 0.0)
	map_control.draw_circle(camp_pos, 7.0, Color(1.0, 0.85, 0.3, 1))
	map_control.draw_circle(camp_pos, 7.0, Color(0.8, 0.65, 0.1, 1), false, 2.0)

	# Draw player position as detailed marker with edge clamping
	var raw_player_pos: Vector2 = _world_to_map(player_pos.x, player_pos.z)
	var map_min: float = MAP_PADDING
	var map_max: float = MAP_SIZE - MAP_PADDING

	# Check if player is within map bounds
	var is_off_map: bool = (player_pos.x < -MAP_EXTENT or player_pos.x > MAP_EXTENT
		or player_pos.z < -MAP_EXTENT or player_pos.z > MAP_EXTENT)

	# Clamp marker position to map edges
	var player_map_pos: Vector2 = Vector2(
		clamp(raw_player_pos.x, map_min, map_max),
		clamp(raw_player_pos.y, map_min, map_max)
	)

	var x_size: float = 12.0
	var x_width: float = 4.0
	var x_color: Color = Color(1, 0.3, 0.3, 1) if is_off_map else Color(1, 1, 1, 1)
	var x_outline: Color = Color(0.1, 0.1, 0.1, 1)

	# Draw filled circle behind the X for visibility
	map_control.draw_circle(player_map_pos, x_size + 3.0, Color(0.1, 0.1, 0.1, 0.7))

	# Draw X outline (thicker for contrast)
	map_control.draw_line(player_map_pos + Vector2(-x_size, -x_size), player_map_pos + Vector2(x_size, x_size), x_outline, x_width + 3.0)
	map_control.draw_line(player_map_pos + Vector2(x_size, -x_size), player_map_pos + Vector2(-x_size, x_size), x_outline, x_width + 3.0)
	# Draw X in color
	map_control.draw_line(player_map_pos + Vector2(-x_size, -x_size), player_map_pos + Vector2(x_size, x_size), x_color, x_width)
	map_control.draw_line(player_map_pos + Vector2(x_size, -x_size), player_map_pos + Vector2(-x_size, x_size), x_color, x_width)

	# Draw pulsing ring around marker for extra visibility
	map_control.draw_circle(player_map_pos, x_size + 3.0, x_color, false, 2.0)

	# Draw legend
	_draw_legend()


func _draw_legend() -> void:
	var legend_x: float = MAP_SIZE - MAP_PADDING - 130.0
	var legend_y: float = MAP_PADDING + 10.0
	var swatch_size: float = 12.0
	var line_height: float = 18.0

	var entries: Array = [
		{"color": REGION_COLORS[0], "label": "Meadow"},
		{"color": REGION_COLORS[1], "label": "Forest"},
		{"color": REGION_COLORS[2], "label": "Hills"},
		{"color": REGION_COLORS[3], "label": "Rocky"},
		{"color": REGION_COLORS[4], "label": "Mountain"},
		{"color": Color(0.2, 0.45, 0.75, 0.9), "label": "Water"},
		{"color": Color(0.15, 0.1, 0.1, 1), "label": "Cave"},
		{"color": Color(1.0, 0.85, 0.3, 1), "label": "Camp"},
		{"color": Color(1, 1, 1, 1), "label": "You (on map)"},
		{"color": Color(1, 0.3, 0.3, 1), "label": "You (off map)"},
	]

	for i: int in range(entries.size()):
		var entry: Dictionary = entries[i]
		var y: float = legend_y + i * line_height
		if entry["label"].begins_with("You"):
			# Draw X marker in legend
			var cx: float = legend_x + swatch_size / 2.0
			var cy: float = y + swatch_size / 2.0
			var s: float = swatch_size / 2.0 - 1.0
			map_control.draw_line(Vector2(cx - s, cy - s), Vector2(cx + s, cy + s), entry["color"], 2.0)
			map_control.draw_line(Vector2(cx + s, cy - s), Vector2(cx - s, cy + s), entry["color"], 2.0)
		else:
			var swatch_rect: Rect2 = Rect2(legend_x, y, swatch_size, swatch_size)
			map_control.draw_rect(swatch_rect, entry["color"])
		map_control.draw_string(HUD_FONT, Vector2(legend_x + swatch_size + 6, y + swatch_size),
			entry["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
			Color(0.8, 0.8, 0.8, 1))


func _input(event: InputEvent) -> void:
	# Close map on use_equipped action (R key / R2 trigger)
	if event.is_action_pressed("use_equipped"):
		close_map()
		get_viewport().set_input_as_handled()


func close_map() -> void:
	queue_free()
