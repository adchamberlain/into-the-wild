extends CanvasLayer
class_name LoadingScreen
## Shows a loading screen with camping artwork while the world initializes.

signal loading_complete

# Loading state
var is_loading: bool = true
var chunks_ready: bool = false
var min_display_time: float = 2.5  # Minimum time to show loading screen
var elapsed_time: float = 0.0

# UI references
var root_control: Control
var background: ColorRect
var vignette: ColorRect
var title_label: Label
var subtitle_label: Label
var artwork_container: Control
var artwork_frame: ColorRect
var artwork_glow: ColorRect
var progress_bar_bg: ColorRect
var progress_bar_fill: ColorRect
var progress_label: Label
var stars: Array[ColorRect] = []

# Current artwork
var current_artwork: Node = null
var artwork_index: int = 0
var artwork_timer: float = 0.0
const ARTWORK_SWITCH_TIME: float = 2.5

# Animation
var star_timer: float = 0.0

# Artwork size constants
const ART_W: int = 500
const ART_H: int = 420


func _ready() -> void:
	layer = 100
	add_to_group("loading_screen")
	_create_ui()
	_show_artwork(0)
	set_process(true)


func _create_ui() -> void:
	root_control = Control.new()
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root_control)

	# Gradient-style background (darker at edges)
	background = ColorRect.new()
	background.color = Color(0.08, 0.09, 0.12, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(background)

	# Add decorative stars in background
	_create_background_stars()

	# Vignette overlay (darker edges)
	vignette = ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0, 0, 0, 0.3)
	root_control.add_child(vignette)

	# Top decorative line
	var top_line := ColorRect.new()
	top_line.color = Color(0.6, 0.5, 0.3, 0.4)
	top_line.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_line.offset_top = 140
	top_line.offset_bottom = 142
	top_line.offset_left = 100
	top_line.offset_right = -100
	root_control.add_child(top_line)

	# Game title
	title_label = Label.new()
	title_label.text = "INTO THE WILD"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title_label.offset_top = 160
	title_label.offset_bottom = 250
	title_label.add_theme_font_size_override("font_size", 72)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	root_control.add_child(title_label)

	# Subtitle
	subtitle_label = Label.new()
	subtitle_label.text = "A Wilderness Survival Adventure"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	subtitle_label.offset_top = 250
	subtitle_label.offset_bottom = 310
	subtitle_label.add_theme_font_size_override("font_size", 42)
	subtitle_label.add_theme_color_override("font_color", Color(0.65, 0.6, 0.5))
	root_control.add_child(subtitle_label)

	# Bottom decorative line (matches top)
	var top_line2 := ColorRect.new()
	top_line2.color = Color(0.6, 0.5, 0.3, 0.4)
	top_line2.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_line2.offset_top = 320
	top_line2.offset_bottom = 322
	top_line2.offset_left = 100
	top_line2.offset_right = -100
	root_control.add_child(top_line2)

	# Artwork area is centered between title bottom (322) and progress top (~965)
	# Midpoint is ~644, which is 104px below screen center (540)
	# We shift the artwork down by 100px from center
	var v_shift: int = 100

	# Artwork glow (behind frame)
	artwork_glow = ColorRect.new()
	artwork_glow.color = Color(1.0, 0.7, 0.3, 0.12)
	artwork_glow.set_anchors_preset(Control.PRESET_CENTER)
	artwork_glow.offset_left = -300
	artwork_glow.offset_right = 300
	artwork_glow.offset_top = -250 + v_shift
	artwork_glow.offset_bottom = 250 + v_shift
	root_control.add_child(artwork_glow)

	# Artwork frame (border)
	artwork_frame = ColorRect.new()
	artwork_frame.color = Color(0.4, 0.35, 0.25, 0.8)
	artwork_frame.set_anchors_preset(Control.PRESET_CENTER)
	artwork_frame.offset_left = -270
	artwork_frame.offset_right = 270
	artwork_frame.offset_top = -225 + v_shift
	artwork_frame.offset_bottom = 225 + v_shift
	root_control.add_child(artwork_frame)

	# Artwork background (inside frame)
	var artwork_bg := ColorRect.new()
	artwork_bg.color = Color(0.05, 0.06, 0.08, 1.0)
	artwork_bg.set_anchors_preset(Control.PRESET_CENTER)
	artwork_bg.offset_left = -260
	artwork_bg.offset_right = 260
	artwork_bg.offset_top = -215 + v_shift
	artwork_bg.offset_bottom = 215 + v_shift
	root_control.add_child(artwork_bg)

	# Artwork container (where art is drawn)
	artwork_container = Control.new()
	artwork_container.set_anchors_preset(Control.PRESET_CENTER)
	artwork_container.offset_left = -ART_W / 2
	artwork_container.offset_right = ART_W / 2
	artwork_container.offset_top = -ART_H / 2 + v_shift
	artwork_container.offset_bottom = ART_H / 2 + v_shift
	root_control.add_child(artwork_container)

	# Progress bar background
	progress_bar_bg = ColorRect.new()
	progress_bar_bg.color = Color(0.15, 0.15, 0.18, 1.0)
	progress_bar_bg.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	progress_bar_bg.offset_top = -60
	progress_bar_bg.offset_bottom = -45
	progress_bar_bg.offset_left = 200
	progress_bar_bg.offset_right = -200
	root_control.add_child(progress_bar_bg)

	# Progress bar fill
	progress_bar_fill = ColorRect.new()
	progress_bar_fill.color = Color(0.8, 0.65, 0.3, 1.0)
	progress_bar_fill.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	progress_bar_fill.offset_top = -58
	progress_bar_fill.offset_bottom = -47
	progress_bar_fill.offset_left = 202
	progress_bar_fill.offset_right = 202  # Start with no width
	root_control.add_child(progress_bar_fill)

	# Progress label
	progress_label = Label.new()
	progress_label.text = "Preparing the wilderness..."
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	progress_label.offset_top = -115
	progress_label.offset_bottom = -65
	progress_label.add_theme_font_size_override("font_size", 36)
	progress_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	root_control.add_child(progress_label)

	# Apply custom font
	var font_path: String = "res://resources/hud_font.tres"
	if ResourceLoader.exists(font_path):
		var font: Font = load(font_path)
		if font:
			title_label.add_theme_font_override("font", font)
			subtitle_label.add_theme_font_override("font", font)
			progress_label.add_theme_font_override("font", font)


func _create_background_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345

	for i in range(40):
		var star := ColorRect.new()
		var brightness: float = rng.randf_range(0.2, 0.6)
		star.color = Color(brightness, brightness, brightness * 0.9, brightness)

		var size: float = rng.randf_range(2, 4)
		star.custom_minimum_size = Vector2(size, size)
		star.size = Vector2(size, size)

		# Position randomly but avoid center area where artwork is
		var pos_x: float = rng.randf_range(50, 1870)
		var pos_y: float = rng.randf_range(50, 1030)

		# Skip if too close to center (enlarged for bigger artwork)
		if abs(pos_x - 960) < 320 and abs(pos_y - 640) < 260:
			pos_x = rng.randf_range(50, 300) if rng.randf() > 0.5 else rng.randf_range(1620, 1870)

		star.position = Vector2(pos_x, pos_y)
		root_control.add_child(star)
		stars.append(star)


func _show_artwork(index: int) -> void:
	if current_artwork:
		current_artwork.queue_free()

	match index % 5:
		0:
			current_artwork = _create_campfire()
		1:
			current_artwork = _create_axe()
		2:
			current_artwork = _create_fishing_rod()
		3:
			current_artwork = _create_tent()
		4:
			current_artwork = _create_tree()

	if current_artwork:
		current_artwork.position = Vector2(0, 0)
		artwork_container.add_child(current_artwork)
		current_artwork.modulate.a = 0.0
		var tween: Tween = create_tween()
		tween.tween_property(current_artwork, "modulate:a", 1.0, 0.4)


# --- Helper to add a colored rect ---
func _rect(parent: Control, x: float, y: float, w: float, h: float, color: Color, rot: float = 0.0) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.size = Vector2(w, h)
	r.position = Vector2(x, y)
	if rot != 0.0:
		r.rotation = rot
	parent.add_child(r)
	return r


func _create_campfire() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(ART_W, ART_H)

	# Fire glow (large soft area)
	_rect(c, 100, 50, 300, 300, Color(1.0, 0.4, 0.1, 0.2))

	# Stone ring - 6 stones around the fire base
	_rect(c, 70, 340, 55, 40, Color(0.35, 0.33, 0.3))
	_rect(c, 130, 355, 50, 35, Color(0.38, 0.36, 0.33))
	_rect(c, 185, 355, 55, 35, Color(0.32, 0.3, 0.28))
	_rect(c, 245, 355, 50, 35, Color(0.36, 0.34, 0.31))
	_rect(c, 310, 340, 55, 40, Color(0.4, 0.38, 0.35))
	_rect(c, 375, 350, 50, 35, Color(0.34, 0.32, 0.29))

	# Crossed logs
	_rect(c, 100, 345, 280, 35, Color(0.4, 0.25, 0.1), -0.12)
	_rect(c, 110, 330, 270, 30, Color(0.35, 0.22, 0.08), 0.14)

	# Log ends (round cross-sections)
	_rect(c, 80, 330, 35, 35, Color(0.5, 0.38, 0.22))
	_rect(c, 380, 340, 35, 35, Color(0.48, 0.36, 0.2))

	# Fire - layered from wide base to narrow tip
	# Embers at base
	_rect(c, 150, 310, 180, 40, Color(0.7, 0.15, 0.0))
	# Base flame - wide, deep orange-red
	_rect(c, 140, 260, 200, 70, Color(0.9, 0.25, 0.0))
	# Left tongue
	_rect(c, 130, 220, 60, 80, Color(0.95, 0.35, 0.0))
	# Right tongue
	_rect(c, 290, 230, 55, 70, Color(0.92, 0.3, 0.0))
	# Mid flame - bright orange
	_rect(c, 165, 180, 150, 100, Color(1.0, 0.5, 0.0))
	# Upper mid - yellow-orange
	_rect(c, 180, 120, 120, 90, Color(1.0, 0.65, 0.1))
	# Upper flame - bright yellow
	_rect(c, 200, 70, 80, 80, Color(1.0, 0.8, 0.2))
	# Flame tip - white-yellow
	_rect(c, 215, 25, 50, 65, Color(1.0, 0.95, 0.5))
	# Hot core
	_rect(c, 205, 240, 70, 60, Color(1.0, 0.9, 0.6, 0.8))

	# Sparks rising
	for i in range(8):
		var sx: float = 210 + (i - 4) * 25 + (i % 3) * 10
		var sy: float = 15 - i * 12
		_rect(c, sx, sy, 5, 5, Color(1.0, 0.8, 0.3, 0.9 - i * 0.08))

	return c


func _create_axe() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(ART_W, ART_H)

	# Ground
	_rect(c, 0, 385, ART_W, 35, Color(0.2, 0.16, 0.1))

	# Wood stump - wide and solid
	_rect(c, 140, 300, 220, 90, Color(0.42, 0.3, 0.16))
	# Bark edges (darker sides)
	_rect(c, 135, 295, 15, 95, Color(0.3, 0.2, 0.1))
	_rect(c, 350, 295, 15, 95, Color(0.32, 0.22, 0.12))
	# Stump top (cut surface - lighter)
	_rect(c, 145, 280, 210, 25, Color(0.6, 0.48, 0.32))
	# Tree rings on cut surface
	_rect(c, 190, 285, 120, 14, Color(0.55, 0.42, 0.28))
	_rect(c, 215, 287, 70, 10, Color(0.5, 0.38, 0.24))
	_rect(c, 235, 289, 30, 6, Color(0.45, 0.34, 0.2))

	# A few wood chips on the ground
	_rect(c, 120, 380, 18, 8, Color(0.55, 0.4, 0.22), 0.3)
	_rect(c, 370, 375, 15, 7, Color(0.5, 0.38, 0.2), -0.5)
	_rect(c, 310, 382, 12, 6, Color(0.52, 0.39, 0.21), 0.8)

	# Axe handle - coming up from the stump, slight lean
	# Main handle shaft
	_rect(c, 232, 80, 28, 220, Color(0.52, 0.37, 0.22), 0.08)
	# Wood grain line on handle
	_rect(c, 243, 82, 8, 218, Color(0.42, 0.28, 0.15), 0.08)
	# Grip wrapping at bottom of handle (leather strips)
	_rect(c, 230, 240, 32, 12, Color(0.3, 0.2, 0.1), 0.08)
	_rect(c, 230, 258, 32, 12, Color(0.28, 0.18, 0.09), 0.08)
	_rect(c, 230, 276, 32, 10, Color(0.3, 0.2, 0.1), 0.08)

	# Axe head - wedge shape built from overlapping rects
	# The head sits at the top of the handle, blade extends to the right
	# Poll (back/hammer side of head - left of handle)
	_rect(c, 195, 68, 45, 55, Color(0.32, 0.32, 0.36))
	# Eye area (where handle passes through)
	_rect(c, 228, 60, 40, 70, Color(0.35, 0.35, 0.38))
	# Cheek - widens toward blade
	_rect(c, 268, 52, 30, 86, Color(0.4, 0.4, 0.44))
	# Cheek 2 - wider still
	_rect(c, 298, 44, 28, 102, Color(0.45, 0.45, 0.5))
	# Blade face
	_rect(c, 326, 36, 22, 118, Color(0.55, 0.55, 0.6))
	# Cutting edge - bright steel highlight
	_rect(c, 348, 32, 10, 126, Color(0.78, 0.78, 0.85))
	# Edge bevel highlight
	_rect(c, 356, 36, 4, 118, Color(0.88, 0.88, 0.92))

	# Beard (lower curve of blade - extends below the cheek)
	_rect(c, 308, 142, 40, 22, Color(0.5, 0.5, 0.55))
	_rect(c, 338, 148, 18, 16, Color(0.65, 0.65, 0.72))

	# Toe (upper curve of blade)
	_rect(c, 308, 30, 40, 18, Color(0.5, 0.5, 0.55))
	_rect(c, 338, 26, 18, 14, Color(0.65, 0.65, 0.72))

	# Head highlights and detail
	_rect(c, 275, 58, 50, 6, Color(0.55, 0.55, 0.6, 0.5))
	_rect(c, 240, 90, 80, 4, Color(0.3, 0.3, 0.34, 0.6))

	return c


func _create_fishing_rod() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(ART_W, ART_H)

	# Water at bottom
	_rect(c, 0, 340, ART_W, 80, Color(0.15, 0.3, 0.45, 0.5))
	# Water surface highlight
	_rect(c, 0, 335, ART_W, 10, Color(0.25, 0.4, 0.55, 0.4))
	# Deeper water
	_rect(c, 0, 380, ART_W, 40, Color(0.1, 0.22, 0.35, 0.6))

	# Rod grip (cork)
	_rect(c, 40, 280, 30, 100, Color(0.6, 0.48, 0.32))
	_rect(c, 42, 290, 26, 15, Color(0.55, 0.42, 0.28))
	_rect(c, 42, 320, 26, 15, Color(0.55, 0.42, 0.28))
	_rect(c, 42, 350, 26, 15, Color(0.55, 0.42, 0.28))

	# Reel seat
	_rect(c, 44, 260, 24, 25, Color(0.25, 0.25, 0.28))
	# Reel body
	_rect(c, 35, 255, 18, 35, Color(0.35, 0.35, 0.38))
	_rect(c, 30, 265, 10, 15, Color(0.4, 0.4, 0.42))

	# Rod blank (tapers from thick to thin)
	_rect(c, 48, 120, 16, 145, Color(0.4, 0.32, 0.22))
	_rect(c, 50, 40, 12, 85, Color(0.38, 0.28, 0.18))
	_rect(c, 52, 5, 8, 40, Color(0.35, 0.25, 0.15))
	# Tip-top guide
	_rect(c, 53, 0, 6, 8, Color(0.5, 0.5, 0.52))

	# Line guides (small rings on rod)
	_rect(c, 46, 130, 5, 5, Color(0.5, 0.5, 0.52))
	_rect(c, 48, 200, 5, 5, Color(0.5, 0.5, 0.52))

	# Fishing line - multiple segments for curve
	_rect(c, 55, 5, 2, 100, Color(0.7, 0.7, 0.7, 0.5), 0.45)
	_rect(c, 98, 80, 2, 80, Color(0.7, 0.7, 0.7, 0.5), 0.3)
	_rect(c, 128, 140, 2, 80, Color(0.7, 0.7, 0.7, 0.5), 0.15)
	_rect(c, 142, 210, 2, 80, Color(0.7, 0.7, 0.7, 0.5), 0.05)

	# Bobber
	_rect(c, 200, 305, 22, 22, Color(0.9, 0.9, 0.9))
	_rect(c, 200, 288, 22, 20, Color(0.9, 0.15, 0.15))
	# Bobber stem
	_rect(c, 209, 280, 4, 10, Color(0.3, 0.3, 0.3))

	# Fish jumping out of water
	_rect(c, 300, 240, 90, 40, Color(0.45, 0.55, 0.65), -0.35)
	# Fish belly (lighter underside)
	_rect(c, 310, 262, 70, 15, Color(0.65, 0.7, 0.75), -0.35)
	# Fish tail
	_rect(c, 385, 260, 30, 50, Color(0.4, 0.5, 0.6), -0.35)
	# Fish eye
	_rect(c, 310, 248, 8, 8, Color(0.1, 0.1, 0.1))
	# Dorsal fin
	_rect(c, 340, 232, 25, 14, Color(0.38, 0.48, 0.58), -0.35)

	# Water splashes around fish
	for i in range(6):
		var sx: float = 310 + i * 18
		var sy: float = 290 + (i % 3) * 8
		_rect(c, sx, sy, 10, 10, Color(0.6, 0.72, 0.85, 0.7 - i * 0.06))

	# Water ripples
	_rect(c, 190, 338, 60, 3, Color(0.35, 0.5, 0.6, 0.4))
	_rect(c, 300, 342, 80, 3, Color(0.35, 0.5, 0.6, 0.3))

	return c


func _create_tent() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(ART_W, ART_H)

	# Night sky hint at top
	_rect(c, 0, 0, ART_W, 100, Color(0.06, 0.07, 0.12))
	# Moon
	_rect(c, 400, 20, 30, 30, Color(0.9, 0.88, 0.75, 0.8))
	_rect(c, 405, 18, 22, 22, Color(0.95, 0.93, 0.82, 0.6))

	# Ground
	_rect(c, 0, 365, ART_W, 55, Color(0.22, 0.18, 0.1))
	# Grass layer
	_rect(c, 0, 358, ART_W, 12, Color(0.2, 0.32, 0.15))

	# Grass tufts
	for i in range(14):
		var gx: float = 10 + i * 35
		_rect(c, gx, 348, 20, 16, Color(0.22 + (i % 3) * 0.03, 0.38 + (i % 2) * 0.05, 0.18))

	# Tent body - A-frame style
	# Back panel (shadow)
	_rect(c, 80, 150, 340, 215, Color(0.25, 0.36, 0.22))
	# Left panel (darker side)
	_rect(c, 80, 150, 170, 215, Color(0.32, 0.45, 0.28))
	# Right panel (lighter, catches light)
	_rect(c, 250, 150, 170, 215, Color(0.38, 0.52, 0.34))

	# Ridge/peak area
	_rect(c, 200, 110, 100, 50, Color(0.42, 0.56, 0.38))
	_rect(c, 225, 90, 50, 30, Color(0.45, 0.6, 0.4))

	# Tent opening (dark interior)
	_rect(c, 205, 235, 90, 130, Color(0.06, 0.06, 0.08))
	# Opening flaps
	_rect(c, 195, 230, 15, 135, Color(0.35, 0.48, 0.32))
	_rect(c, 290, 230, 15, 135, Color(0.4, 0.54, 0.36))

	# Ridge pole
	_rect(c, 245, 85, 10, 285, Color(0.5, 0.4, 0.3))

	# Guy ropes
	_rect(c, 80, 150, 3, 85, Color(0.5, 0.45, 0.35, 0.6), -0.7)
	_rect(c, 420, 150, 3, 85, Color(0.5, 0.45, 0.35, 0.6), 0.7)

	# Tent stakes
	_rect(c, 42, 352, 6, 18, Color(0.5, 0.4, 0.3), -0.3)
	_rect(c, 452, 352, 6, 18, Color(0.5, 0.4, 0.3), 0.3)

	# Small campfire glow nearby (right side)
	_rect(c, 430, 330, 40, 30, Color(1.0, 0.4, 0.1, 0.3))
	_rect(c, 438, 320, 24, 20, Color(1.0, 0.6, 0.15, 0.5))
	_rect(c, 443, 310, 14, 15, Color(1.0, 0.85, 0.3, 0.6))

	return c


func _create_tree() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(ART_W, ART_H)

	# Ground
	_rect(c, 0, 385, ART_W, 35, Color(0.22, 0.18, 0.1))
	_rect(c, 0, 378, ART_W, 12, Color(0.2, 0.3, 0.14))

	# Trunk - thick and textured
	_rect(c, 215, 200, 60, 190, Color(0.4, 0.28, 0.15))
	# Bark texture lines
	_rect(c, 225, 205, 12, 185, Color(0.35, 0.24, 0.12))
	_rect(c, 255, 210, 10, 180, Color(0.36, 0.25, 0.13))
	# Bark highlight
	_rect(c, 242, 200, 8, 190, Color(0.45, 0.33, 0.2, 0.5))

	# Roots
	_rect(c, 190, 375, 40, 18, Color(0.38, 0.26, 0.14))
	_rect(c, 260, 375, 45, 18, Color(0.36, 0.25, 0.13))
	_rect(c, 175, 380, 20, 12, Color(0.35, 0.24, 0.12))
	_rect(c, 295, 378, 22, 14, Color(0.37, 0.26, 0.14))

	# Foliage - build a large rounded canopy from overlapping rects
	# Bottom layer (widest)
	_rect(c, 80, 170, 330, 60, Color(0.15, 0.35, 0.15))
	# Second layer
	_rect(c, 95, 130, 300, 55, Color(0.18, 0.4, 0.18))
	# Third layer
	_rect(c, 110, 95, 270, 50, Color(0.2, 0.44, 0.2))
	# Fourth layer
	_rect(c, 130, 60, 230, 50, Color(0.24, 0.48, 0.24))
	# Fifth layer
	_rect(c, 155, 30, 180, 45, Color(0.28, 0.52, 0.28))
	# Top layer
	_rect(c, 185, 8, 120, 35, Color(0.32, 0.56, 0.32))
	# Crown
	_rect(c, 215, 0, 60, 20, Color(0.35, 0.6, 0.35))

	# Highlight patches on foliage (sunlit side)
	_rect(c, 290, 100, 70, 35, Color(0.3, 0.55, 0.3, 0.5))
	_rect(c, 260, 50, 60, 30, Color(0.32, 0.56, 0.32, 0.4))
	_rect(c, 310, 155, 55, 30, Color(0.28, 0.5, 0.28, 0.4))

	# Shadow patches (deeper green)
	_rect(c, 110, 140, 60, 40, Color(0.12, 0.28, 0.12, 0.5))
	_rect(c, 140, 80, 50, 30, Color(0.14, 0.3, 0.14, 0.4))

	# Bird on a branch
	_rect(c, 365, 175, 20, 6, Color(0.38, 0.26, 0.14))  # Branch
	_rect(c, 375, 162, 16, 14, Color(0.55, 0.35, 0.25))  # Body
	_rect(c, 388, 159, 8, 8, Color(0.5, 0.32, 0.22))  # Head
	_rect(c, 394, 162, 5, 3, Color(0.7, 0.5, 0.2))  # Beak

	return c


func _process(delta: float) -> void:
	if not is_loading:
		return

	elapsed_time += delta
	artwork_timer += delta
	star_timer += delta

	# Twinkle stars
	if star_timer >= 0.1:
		star_timer = 0.0
		_twinkle_stars()

	# Cycle artwork
	if artwork_timer >= ARTWORK_SWITCH_TIME:
		artwork_timer = 0.0
		artwork_index += 1
		_show_artwork(artwork_index)

	# Check loading progress
	if not chunks_ready:
		var chunk_manager: Node = get_tree().get_first_node_in_group("chunk_manager")
		if chunk_manager:
			var pending: int = 0
			if chunk_manager.has_method("get_pending_load_count"):
				pending = chunk_manager.get_pending_load_count()

			if pending > 0:
				progress_label.text = "Loading terrain... %d chunks remaining" % pending
				# Update progress bar (estimate based on typical load of ~25 chunks)
				var progress: float = 1.0 - (float(pending) / 30.0)
				progress = clampf(progress, 0.0, 0.95)
				_update_progress_bar(progress)
			else:
				progress_label.text = "Initializing world..."
				_update_progress_bar(0.98)
				chunks_ready = true

	if chunks_ready and elapsed_time >= min_display_time:
		_update_progress_bar(1.0)
		_finish_loading()


func _twinkle_stars() -> void:
	if stars.size() == 0:
		return
	var idx: int = randi() % stars.size()
	var star: ColorRect = stars[idx]
	var new_alpha: float = randf_range(0.15, 0.7)
	star.color.a = new_alpha


func _update_progress_bar(progress: float) -> void:
	var bar_width: float = progress * 516  # Total bar width (offset_right - offset_left - 4)
	progress_bar_fill.offset_right = 202 + bar_width


func _finish_loading() -> void:
	is_loading = false
	set_process(false)
	progress_label.text = "Ready!"

	await get_tree().create_timer(0.4).timeout

	var tween: Tween = create_tween()
	tween.tween_property(root_control, "modulate:a", 0.0, 0.6)
	tween.tween_callback(_on_fade_complete)


func _on_fade_complete() -> void:
	loading_complete.emit()
	queue_free()


func skip_loading() -> void:
	if is_loading:
		_finish_loading()
