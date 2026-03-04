extends Control
## Always-visible rotating compass widget for the HUD.
## Shows cardinal directions relative to the player's facing direction.
## The ring rotates so the direction you face points "up" (12 o'clock).

const HUD_FONT: Font = preload("res://resources/hud_font.tres")

# Layout
const RADIUS: float = 45.0
const TICK_OUTER: float = 43.0
const TICK_INNER_CARDINAL: float = 33.0
const TICK_INNER_INTER: float = 37.0
const LABEL_RADIUS: float = 27.0
const CENTER_DOT_RADIUS: float = 3.0
const CHEVRON_SIZE: float = 7.0

# Colors
const BG_COLOR: Color = Color(0.1, 0.1, 0.12, 0.8)
const RING_COLOR: Color = Color(0.5, 0.5, 0.5, 0.8)
const TICK_COLOR: Color = Color(0.7, 0.7, 0.7, 0.9)
const NORTH_COLOR: Color = Color(1.0, 0.85, 0.3, 1.0)
const LABEL_COLOR: Color = Color(0.9, 0.9, 0.9, 1.0)
const CENTER_COLOR: Color = Color(0.9, 0.9, 0.9, 0.9)
const CHEVRON_COLOR: Color = Color(1.0, 0.85, 0.3, 1.0)

# Cardinal directions: name, base angle (world space, N = -Z = 0)
# Clockwise from 12 o'clock: N(0), E(PI/2), S(PI), W(-PI/2)
const CARDINALS: Array = [
	{"label": "N", "angle": 0.0},
	{"label": "E", "angle": PI / 2.0},
	{"label": "S", "angle": PI},
	{"label": "W", "angle": -PI / 2.0},
]

# Intercardinal base angles
const INTERCARDINALS: Array = [-PI / 4.0, -3.0 * PI / 4.0, 3.0 * PI / 4.0, PI / 4.0]

var player: Node3D = null


func _ready() -> void:
	custom_minimum_size = Vector2(RADIUS * 2 + 20, RADIUS * 2 + 20)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size / 2.0
	var player_yaw: float = 0.0
	if player and is_instance_valid(player):
		player_yaw = player.rotation.y

	# 1. Background disc
	draw_circle(center, RADIUS + 5, BG_COLOR)

	# 2. Outer ring
	_draw_ring(center, RADIUS, RING_COLOR, 2.0)

	# 3. Tick marks (cardinal = longer, intercardinal = shorter)
	for card: Dictionary in CARDINALS:
		var angle: float = card.angle + player_yaw
		var outer: Vector2 = center + Vector2(sin(angle), -cos(angle)) * TICK_OUTER
		var inner: Vector2 = center + Vector2(sin(angle), -cos(angle)) * TICK_INNER_CARDINAL
		var color: Color = NORTH_COLOR if card.label == "N" else TICK_COLOR
		draw_line(inner, outer, color, 2.0)

	for inter_angle: float in INTERCARDINALS:
		var angle: float = inter_angle + player_yaw
		var outer: Vector2 = center + Vector2(sin(angle), -cos(angle)) * TICK_OUTER
		var inner: Vector2 = center + Vector2(sin(angle), -cos(angle)) * TICK_INNER_INTER
		draw_line(inner, outer, TICK_COLOR, 1.5)

	# 4. Cardinal labels (N/E/S/W) at rotated positions
	for card: Dictionary in CARDINALS:
		var angle: float = card.angle + player_yaw
		var label_pos: Vector2 = center + Vector2(sin(angle), -cos(angle)) * LABEL_RADIUS
		var color: Color = NORTH_COLOR if card.label == "N" else LABEL_COLOR
		var font_size: int = 16 if card.label == "N" else 14
		var text_size: Vector2 = HUD_FONT.get_string_size(card.label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		draw_string(HUD_FONT, label_pos - Vector2(text_size.x / 2.0, -text_size.y / 3.0), card.label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, color)

	# 5. Center dot
	draw_circle(center, CENTER_DOT_RADIUS, CENTER_COLOR)

	# 6. Fixed gold chevron at 12 o'clock (direction indicator, does NOT rotate)
	var chev_top: Vector2 = center + Vector2(0, -(RADIUS + 2))
	var chev_left: Vector2 = chev_top + Vector2(-CHEVRON_SIZE, -CHEVRON_SIZE)
	var chev_right: Vector2 = chev_top + Vector2(CHEVRON_SIZE, -CHEVRON_SIZE)
	draw_colored_polygon(PackedVector2Array([chev_top, chev_left, chev_right]), CHEVRON_COLOR)


func _draw_ring(center: Vector2, radius: float, color: Color, width: float) -> void:
	var segments: int = 64
	var prev: Vector2 = center + Vector2(0, -radius)
	for i: int in range(1, segments + 1):
		var a: float = TAU * float(i) / float(segments) - PI / 2.0
		var next: Vector2 = center + Vector2(cos(a), sin(a)) * radius
		draw_line(prev, next, color, width)
		prev = next
