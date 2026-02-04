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
	top_line.offset_top = 50
	top_line.offset_bottom = 52
	top_line.offset_left = 100
	top_line.offset_right = -100
	root_control.add_child(top_line)

	# Game title
	title_label = Label.new()
	title_label.text = "INTO THE WILD"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title_label.offset_top = 70
	title_label.offset_bottom = 150
	title_label.add_theme_font_size_override("font_size", 72)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	root_control.add_child(title_label)

	# Subtitle
	subtitle_label = Label.new()
	subtitle_label.text = "A Wilderness Survival Adventure"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	subtitle_label.offset_top = 145
	subtitle_label.offset_bottom = 180
	subtitle_label.add_theme_font_size_override("font_size", 20)
	subtitle_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45))
	root_control.add_child(subtitle_label)

	# Bottom decorative line (matches top)
	var top_line2 := ColorRect.new()
	top_line2.color = Color(0.6, 0.5, 0.3, 0.4)
	top_line2.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_line2.offset_top = 190
	top_line2.offset_bottom = 192
	top_line2.offset_left = 100
	top_line2.offset_right = -100
	root_control.add_child(top_line2)

	# Artwork glow (behind frame)
	artwork_glow = ColorRect.new()
	artwork_glow.color = Color(1.0, 0.7, 0.3, 0.15)
	artwork_glow.set_anchors_preset(Control.PRESET_CENTER)
	artwork_glow.offset_left = -220
	artwork_glow.offset_right = 220
	artwork_glow.offset_top = -180
	artwork_glow.offset_bottom = 180
	root_control.add_child(artwork_glow)

	# Artwork frame (border)
	artwork_frame = ColorRect.new()
	artwork_frame.color = Color(0.4, 0.35, 0.25, 0.8)
	artwork_frame.set_anchors_preset(Control.PRESET_CENTER)
	artwork_frame.offset_left = -205
	artwork_frame.offset_right = 205
	artwork_frame.offset_top = -165
	artwork_frame.offset_bottom = 165
	root_control.add_child(artwork_frame)

	# Artwork background (inside frame)
	var artwork_bg := ColorRect.new()
	artwork_bg.color = Color(0.05, 0.06, 0.08, 1.0)
	artwork_bg.set_anchors_preset(Control.PRESET_CENTER)
	artwork_bg.offset_left = -195
	artwork_bg.offset_right = 195
	artwork_bg.offset_top = -155
	artwork_bg.offset_bottom = 155
	root_control.add_child(artwork_bg)

	# Artwork container
	artwork_container = Control.new()
	artwork_container.set_anchors_preset(Control.PRESET_CENTER)
	artwork_container.offset_left = -175
	artwork_container.offset_right = 175
	artwork_container.offset_top = -135
	artwork_container.offset_bottom = 135
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
	progress_label.offset_top = -100
	progress_label.offset_bottom = -65
	progress_label.add_theme_font_size_override("font_size", 18)
	progress_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
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

		# Skip if too close to center
		if abs(pos_x - 960) < 250 and abs(pos_y - 540) < 200:
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
		# Center the artwork in the container
		current_artwork.position = Vector2(25, 0)
		artwork_container.add_child(current_artwork)
		current_artwork.modulate.a = 0.0
		var tween: Tween = create_tween()
		tween.tween_property(current_artwork, "modulate:a", 1.0, 0.4)


func _create_campfire() -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(300, 270)

	# Larger fire glow
	var glow := ColorRect.new()
	glow.color = Color(1.0, 0.4, 0.1, 0.25)
	glow.size = Vector2(200, 180)
	glow.position = Vector2(50, 30)
	container.add_child(glow)

	# Stone ring (left)
	var stone1 := ColorRect.new()
	stone1.color = Color(0.35, 0.33, 0.3)
	stone1.size = Vector2(35, 25)
	stone1.position = Vector2(45, 210)
	container.add_child(stone1)

	# Stone ring (right)
	var stone2 := ColorRect.new()
	stone2.color = Color(0.4, 0.38, 0.35)
	stone2.size = Vector2(35, 25)
	stone2.position = Vector2(220, 210)
	container.add_child(stone2)

	# Log 1
	var log1 := ColorRect.new()
	log1.color = Color(0.4, 0.25, 0.1)
	log1.size = Vector2(160, 28)
	log1.position = Vector2(70, 215)
	log1.rotation = -0.15
	container.add_child(log1)

	# Log 2
	var log2 := ColorRect.new()
	log2.color = Color(0.35, 0.22, 0.08)
	log2.size = Vector2(160, 25)
	log2.position = Vector2(70, 205)
	log2.rotation = 0.18
	container.add_child(log2)

	# Fire layers
	var fire_base := ColorRect.new()
	fire_base.color = Color(0.9, 0.3, 0.0)
	fire_base.size = Vector2(100, 70)
	fire_base.position = Vector2(100, 150)
	container.add_child(fire_base)

	var fire_mid := ColorRect.new()
	fire_mid.color = Color(1.0, 0.5, 0.0)
	fire_mid.size = Vector2(80, 80)
	fire_mid.position = Vector2(110, 90)
	container.add_child(fire_mid)

	var fire_top := ColorRect.new()
	fire_top.color = Color(1.0, 0.75, 0.2)
	fire_top.size = Vector2(50, 70)
	fire_top.position = Vector2(125, 50)
	container.add_child(fire_top)

	var flame_tip := ColorRect.new()
	flame_tip.color = Color(1.0, 0.95, 0.5)
	flame_tip.size = Vector2(25, 45)
	flame_tip.position = Vector2(137, 20)
	container.add_child(flame_tip)

	# Sparks
	for i in range(5):
		var spark := ColorRect.new()
		spark.color = Color(1.0, 0.8, 0.3, 0.8)
		spark.size = Vector2(4, 4)
		spark.position = Vector2(130 + (i - 2) * 20, 15 - i * 8)
		container.add_child(spark)

	return container


func _create_axe() -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(300, 270)

	# Wood stump base
	var stump := ColorRect.new()
	stump.color = Color(0.45, 0.32, 0.18)
	stump.size = Vector2(120, 60)
	stump.position = Vector2(90, 200)
	container.add_child(stump)

	var stump_top := ColorRect.new()
	stump_top.color = Color(0.55, 0.4, 0.25)
	stump_top.size = Vector2(120, 15)
	stump_top.position = Vector2(90, 185)
	container.add_child(stump_top)

	# Handle
	var handle := ColorRect.new()
	handle.color = Color(0.5, 0.35, 0.2)
	handle.size = Vector2(25, 180)
	handle.position = Vector2(138, 30)
	handle.rotation = 0.15
	container.add_child(handle)

	var handle_detail := ColorRect.new()
	handle_detail.color = Color(0.4, 0.28, 0.15)
	handle_detail.size = Vector2(8, 180)
	handle_detail.position = Vector2(150, 30)
	handle_detail.rotation = 0.15
	container.add_child(handle_detail)

	# Axe head
	var head_back := ColorRect.new()
	head_back.color = Color(0.35, 0.35, 0.38)
	head_back.size = Vector2(70, 50)
	head_back.position = Vector2(165, 25)
	container.add_child(head_back)

	var head_front := ColorRect.new()
	head_front.color = Color(0.5, 0.5, 0.55)
	head_front.size = Vector2(60, 42)
	head_front.position = Vector2(175, 30)
	container.add_child(head_front)

	var blade := ColorRect.new()
	blade.color = Color(0.75, 0.75, 0.8)
	blade.size = Vector2(10, 40)
	blade.position = Vector2(228, 31)
	container.add_child(blade)

	# Binding
	var binding := ColorRect.new()
	binding.color = Color(0.4, 0.3, 0.2)
	binding.size = Vector2(35, 18)
	binding.position = Vector2(142, 55)
	binding.rotation = 0.15
	container.add_child(binding)

	return container


func _create_fishing_rod() -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(300, 270)

	# Water at bottom
	var water := ColorRect.new()
	water.color = Color(0.2, 0.35, 0.5, 0.6)
	water.size = Vector2(300, 50)
	water.position = Vector2(0, 220)
	container.add_child(water)

	# Rod
	var grip := ColorRect.new()
	grip.color = Color(0.6, 0.45, 0.3)
	grip.size = Vector2(22, 65)
	grip.position = Vector2(30, 180)
	container.add_child(grip)

	var reel := ColorRect.new()
	reel.color = Color(0.3, 0.3, 0.3)
	reel.size = Vector2(18, 25)
	reel.position = Vector2(32, 160)
	container.add_child(reel)

	var rod := ColorRect.new()
	rod.color = Color(0.4, 0.3, 0.2)
	rod.size = Vector2(12, 140)
	rod.position = Vector2(35, 25)
	container.add_child(rod)

	var tip := ColorRect.new()
	tip.color = Color(0.35, 0.25, 0.15)
	tip.size = Vector2(6, 30)
	tip.position = Vector2(38, 0)
	container.add_child(tip)

	# Line (curved appearance with multiple segments)
	var line1 := ColorRect.new()
	line1.color = Color(0.7, 0.7, 0.7, 0.6)
	line1.size = Vector2(2, 80)
	line1.position = Vector2(40, 5)
	line1.rotation = 0.5
	container.add_child(line1)

	var line2 := ColorRect.new()
	line2.color = Color(0.7, 0.7, 0.7, 0.6)
	line2.size = Vector2(2, 60)
	line2.position = Vector2(80, 65)
	line2.rotation = 0.2
	container.add_child(line2)

	# Bobber
	var bobber_white := ColorRect.new()
	bobber_white.color = Color(0.9, 0.9, 0.9)
	bobber_white.size = Vector2(14, 14)
	bobber_white.position = Vector2(140, 195)
	container.add_child(bobber_white)

	var bobber_red := ColorRect.new()
	bobber_red.color = Color(0.9, 0.2, 0.2)
	bobber_red.size = Vector2(14, 10)
	bobber_red.position = Vector2(140, 185)
	container.add_child(bobber_red)

	# Fish jumping
	var fish := ColorRect.new()
	fish.color = Color(0.45, 0.55, 0.65)
	fish.size = Vector2(55, 25)
	fish.position = Vector2(190, 150)
	fish.rotation = -0.4
	container.add_child(fish)

	var fish_tail := ColorRect.new()
	fish_tail.color = Color(0.4, 0.5, 0.6)
	fish_tail.size = Vector2(18, 30)
	fish_tail.position = Vector2(238, 158)
	fish_tail.rotation = -0.4
	container.add_child(fish_tail)

	# Water splashes
	for i in range(4):
		var splash := ColorRect.new()
		splash.color = Color(0.6, 0.7, 0.85, 0.7)
		splash.size = Vector2(8, 8)
		splash.position = Vector2(195 + i * 12, 175 + (i % 2) * 5)
		container.add_child(splash)

	return container


func _create_tent() -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(300, 270)

	# Ground
	var ground := ColorRect.new()
	ground.color = Color(0.25, 0.2, 0.12)
	ground.size = Vector2(300, 35)
	ground.position = Vector2(0, 235)
	container.add_child(ground)

	# Grass tufts
	for i in range(8):
		var grass := ColorRect.new()
		grass.color = Color(0.25, 0.4, 0.2)
		grass.size = Vector2(15, 12)
		grass.position = Vector2(20 + i * 35, 228)
		container.add_child(grass)

	# Tent body
	var tent_back := ColorRect.new()
	tent_back.color = Color(0.3, 0.42, 0.28)
	tent_back.size = Vector2(200, 140)
	tent_back.position = Vector2(50, 95)
	container.add_child(tent_back)

	var tent_left := ColorRect.new()
	tent_left.color = Color(0.38, 0.52, 0.35)
	tent_left.size = Vector2(100, 140)
	tent_left.position = Vector2(50, 95)
	container.add_child(tent_left)

	var tent_right := ColorRect.new()
	tent_right.color = Color(0.42, 0.58, 0.38)
	tent_right.size = Vector2(100, 140)
	tent_right.position = Vector2(150, 95)
	container.add_child(tent_right)

	# Peak
	var peak := ColorRect.new()
	peak.color = Color(0.48, 0.62, 0.42)
	peak.size = Vector2(50, 35)
	peak.position = Vector2(125, 65)
	container.add_child(peak)

	# Opening
	var opening := ColorRect.new()
	opening.color = Color(0.08, 0.08, 0.1)
	opening.size = Vector2(50, 85)
	opening.position = Vector2(125, 150)
	container.add_child(opening)

	# Pole
	var pole := ColorRect.new()
	pole.color = Color(0.5, 0.4, 0.3)
	pole.size = Vector2(8, 175)
	pole.position = Vector2(146, 60)
	container.add_child(pole)

	# Guy ropes
	var rope1 := ColorRect.new()
	rope1.color = Color(0.5, 0.45, 0.35, 0.7)
	rope1.size = Vector2(2, 50)
	rope1.position = Vector2(50, 95)
	rope1.rotation = -0.6
	container.add_child(rope1)

	var rope2 := ColorRect.new()
	rope2.color = Color(0.5, 0.45, 0.35, 0.7)
	rope2.size = Vector2(2, 50)
	rope2.position = Vector2(250, 95)
	rope2.rotation = 0.6
	container.add_child(rope2)

	return container


func _create_tree() -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(300, 270)

	# Ground
	var ground := ColorRect.new()
	ground.color = Color(0.25, 0.2, 0.12)
	ground.size = Vector2(300, 25)
	ground.position = Vector2(0, 245)
	container.add_child(ground)

	# Trunk
	var trunk := ColorRect.new()
	trunk.color = Color(0.4, 0.28, 0.15)
	trunk.size = Vector2(40, 110)
	trunk.position = Vector2(130, 140)
	container.add_child(trunk)

	var trunk_detail := ColorRect.new()
	trunk_detail.color = Color(0.35, 0.24, 0.12)
	trunk_detail.size = Vector2(12, 110)
	trunk_detail.position = Vector2(145, 140)
	container.add_child(trunk_detail)

	# Roots
	var root1 := ColorRect.new()
	root1.color = Color(0.38, 0.26, 0.14)
	root1.size = Vector2(25, 15)
	root1.position = Vector2(115, 240)
	container.add_child(root1)

	var root2 := ColorRect.new()
	root2.color = Color(0.38, 0.26, 0.14)
	root2.size = Vector2(25, 15)
	root2.position = Vector2(160, 240)
	container.add_child(root2)

	# Foliage layers (larger, more detailed)
	var leaves1 := ColorRect.new()
	leaves1.color = Color(0.18, 0.4, 0.18)
	leaves1.size = Vector2(160, 65)
	leaves1.position = Vector2(70, 100)
	container.add_child(leaves1)

	var leaves2 := ColorRect.new()
	leaves2.color = Color(0.22, 0.48, 0.22)
	leaves2.size = Vector2(130, 60)
	leaves2.position = Vector2(85, 55)
	container.add_child(leaves2)

	var leaves3 := ColorRect.new()
	leaves3.color = Color(0.28, 0.52, 0.28)
	leaves3.size = Vector2(90, 50)
	leaves3.position = Vector2(105, 20)
	container.add_child(leaves3)

	var leaves4 := ColorRect.new()
	leaves4.color = Color(0.32, 0.58, 0.32)
	leaves4.size = Vector2(45, 35)
	leaves4.position = Vector2(127, 0)
	container.add_child(leaves4)

	# Small bird on branch
	var bird := ColorRect.new()
	bird.color = Color(0.5, 0.4, 0.35)
	bird.size = Vector2(12, 10)
	bird.position = Vector2(200, 108)
	container.add_child(bird)

	return container


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
