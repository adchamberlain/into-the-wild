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
var background: ColorRect
var title_label: Label
var artwork_container: Control
var progress_label: Label

# Current artwork
var current_artwork: Node = null
var artwork_index: int = 0
var artwork_timer: float = 0.0
const ARTWORK_SWITCH_TIME: float = 1.5


func _ready() -> void:
	# Set to render on top of everything
	layer = 100

	# Create the loading screen UI
	_create_ui()

	# Show first artwork
	_show_artwork(0)

	# Start checking for load completion
	set_process(true)


func _create_ui() -> void:
	# Get viewport size for proper sizing (with fallback for safety)
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.x < 100 or viewport_size.y < 100:
		viewport_size = Vector2(1920, 1080)  # Fallback to common resolution

	# Dark background that covers entire screen
	background = ColorRect.new()
	background.color = Color(0.06, 0.07, 0.1, 1.0)
	background.position = Vector2.ZERO
	background.size = viewport_size
	# Use anchors to stretch with window
	background.anchor_left = 0.0
	background.anchor_top = 0.0
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.offset_left = 0
	background.offset_top = 0
	background.offset_right = 0
	background.offset_bottom = 0
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background)

	# Connect to viewport size changes to keep background covering full screen
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	# Also call once deferred to ensure proper sizing after scene is fully loaded
	call_deferred("_on_viewport_size_changed")

	# Game title at top
	title_label = Label.new()
	title_label.text = "INTO THE WILD"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.anchors_preset = Control.PRESET_CENTER_TOP
	title_label.anchor_top = 0.1
	title_label.anchor_bottom = 0.1
	title_label.offset_top = 0
	title_label.offset_bottom = 80
	title_label.offset_left = -300
	title_label.offset_right = 300
	title_label.add_theme_font_size_override("font_size", 64)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	add_child(title_label)

	# Artwork container (centered)
	artwork_container = Control.new()
	artwork_container.anchors_preset = Control.PRESET_CENTER
	artwork_container.anchor_left = 0.5
	artwork_container.anchor_right = 0.5
	artwork_container.anchor_top = 0.5
	artwork_container.anchor_bottom = 0.5
	artwork_container.offset_left = -150
	artwork_container.offset_right = 150
	artwork_container.offset_top = -100
	artwork_container.offset_bottom = 100
	add_child(artwork_container)

	# Progress label at bottom
	progress_label = Label.new()
	progress_label.text = "Preparing the wilderness..."
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.anchors_preset = Control.PRESET_CENTER_BOTTOM
	progress_label.anchor_top = 0.85
	progress_label.anchor_bottom = 0.85
	progress_label.offset_left = -300
	progress_label.offset_right = 300
	progress_label.add_theme_font_size_override("font_size", 24)
	progress_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	add_child(progress_label)

	# Try to apply custom font
	var font_path: String = "res://resources/hud_font.tres"
	if ResourceLoader.exists(font_path):
		var font: Font = load(font_path)
		if font:
			title_label.add_theme_font_override("font", font)
			progress_label.add_theme_font_override("font", font)


func _show_artwork(index: int) -> void:
	# Remove old artwork
	if current_artwork:
		current_artwork.queue_free()

	# Create new artwork based on index
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
		artwork_container.add_child(current_artwork)
		# Fade in animation
		current_artwork.modulate.a = 0.0
		var tween: Tween = create_tween()
		tween.tween_property(current_artwork, "modulate:a", 1.0, 0.3)


func _create_campfire() -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(200, 200)

	# Fire glow (background)
	var glow := ColorRect.new()
	glow.color = Color(1.0, 0.4, 0.1, 0.3)
	glow.size = Vector2(120, 100)
	glow.position = Vector2(40, 50)
	container.add_child(glow)

	# Log 1 (brown rectangle, angled)
	var log1 := ColorRect.new()
	log1.color = Color(0.4, 0.25, 0.1)
	log1.size = Vector2(100, 20)
	log1.position = Vector2(50, 160)
	log1.rotation = -0.2
	container.add_child(log1)

	# Log 2 (crossing)
	var log2 := ColorRect.new()
	log2.color = Color(0.35, 0.22, 0.08)
	log2.size = Vector2(100, 18)
	log2.position = Vector2(50, 155)
	log2.rotation = 0.25
	container.add_child(log2)

	# Fire base (orange)
	var fire_base := ColorRect.new()
	fire_base.color = Color(1.0, 0.5, 0.0)
	fire_base.size = Vector2(60, 50)
	fire_base.position = Vector2(70, 110)
	container.add_child(fire_base)

	# Fire middle (yellow-orange)
	var fire_mid := ColorRect.new()
	fire_mid.color = Color(1.0, 0.7, 0.1)
	fire_mid.size = Vector2(45, 55)
	fire_mid.position = Vector2(77, 70)
	container.add_child(fire_mid)

	# Fire top (yellow)
	var fire_top := ColorRect.new()
	fire_top.color = Color(1.0, 0.9, 0.3)
	fire_top.size = Vector2(25, 40)
	fire_top.position = Vector2(87, 50)
	container.add_child(fire_top)

	# Flame tip
	var flame_tip := ColorRect.new()
	flame_tip.color = Color(1.0, 1.0, 0.6)
	flame_tip.size = Vector2(12, 25)
	flame_tip.position = Vector2(94, 35)
	container.add_child(flame_tip)

	return container


func _create_axe() -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(200, 200)

	# Handle (wooden stick)
	var handle := ColorRect.new()
	handle.color = Color(0.5, 0.35, 0.2)
	handle.size = Vector2(20, 140)
	handle.position = Vector2(90, 50)
	container.add_child(handle)

	# Handle detail (darker stripe)
	var handle_detail := ColorRect.new()
	handle_detail.color = Color(0.4, 0.28, 0.15)
	handle_detail.size = Vector2(6, 140)
	handle_detail.position = Vector2(97, 50)
	container.add_child(handle_detail)

	# Axe head back (darker metal)
	var head_back := ColorRect.new()
	head_back.color = Color(0.4, 0.4, 0.42)
	head_back.size = Vector2(50, 35)
	head_back.position = Vector2(100, 50)
	container.add_child(head_back)

	# Axe head front (lighter metal)
	var head_front := ColorRect.new()
	head_front.color = Color(0.55, 0.55, 0.58)
	head_front.size = Vector2(45, 30)
	head_front.position = Vector2(105, 53)
	container.add_child(head_front)

	# Blade edge (shiny)
	var blade := ColorRect.new()
	blade.color = Color(0.75, 0.75, 0.8)
	blade.size = Vector2(8, 28)
	blade.position = Vector2(145, 54)
	container.add_child(blade)

	# Binding
	var binding := ColorRect.new()
	binding.color = Color(0.45, 0.35, 0.25)
	binding.size = Vector2(26, 15)
	binding.position = Vector2(87, 80)
	container.add_child(binding)

	return container


func _create_fishing_rod() -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(200, 200)

	# Rod handle (cork color)
	var grip := ColorRect.new()
	grip.color = Color(0.65, 0.5, 0.35)
	grip.size = Vector2(18, 50)
	grip.position = Vector2(40, 140)
	container.add_child(grip)

	# Reel seat
	var reel := ColorRect.new()
	reel.color = Color(0.25, 0.25, 0.25)
	reel.size = Vector2(14, 20)
	reel.position = Vector2(42, 125)
	container.add_child(reel)

	# Rod body
	var rod := ColorRect.new()
	rod.color = Color(0.4, 0.3, 0.2)
	rod.size = Vector2(10, 100)
	rod.position = Vector2(44, 30)
	container.add_child(rod)

	# Rod tip
	var tip := ColorRect.new()
	tip.color = Color(0.35, 0.28, 0.18)
	tip.size = Vector2(6, 30)
	tip.position = Vector2(46, 5)
	container.add_child(tip)

	# Fishing line
	var line := ColorRect.new()
	line.color = Color(0.8, 0.8, 0.8, 0.7)
	line.size = Vector2(2, 80)
	line.position = Vector2(48, 5)
	line.rotation = 0.4
	container.add_child(line)

	# Hook
	var hook := ColorRect.new()
	hook.color = Color(0.6, 0.6, 0.62)
	hook.size = Vector2(8, 15)
	hook.position = Vector2(95, 65)
	container.add_child(hook)

	# Fish!
	var fish_body := ColorRect.new()
	fish_body.color = Color(0.5, 0.6, 0.7)
	fish_body.size = Vector2(45, 20)
	fish_body.position = Vector2(110, 80)
	container.add_child(fish_body)

	var fish_tail := ColorRect.new()
	fish_tail.color = Color(0.45, 0.55, 0.65)
	fish_tail.size = Vector2(15, 25)
	fish_tail.position = Vector2(150, 77)
	container.add_child(fish_tail)

	return container


func _create_tent() -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(200, 200)

	# Ground
	var ground := ColorRect.new()
	ground.color = Color(0.3, 0.25, 0.15)
	ground.size = Vector2(200, 20)
	ground.position = Vector2(0, 170)
	container.add_child(ground)

	# Tent back (darker)
	var tent_back := ColorRect.new()
	tent_back.color = Color(0.35, 0.45, 0.3)
	tent_back.size = Vector2(140, 100)
	tent_back.position = Vector2(30, 70)
	container.add_child(tent_back)

	# Tent front left
	var tent_left := ColorRect.new()
	tent_left.color = Color(0.4, 0.55, 0.35)
	tent_left.size = Vector2(70, 100)
	tent_left.position = Vector2(30, 70)
	container.add_child(tent_left)

	# Tent front right
	var tent_right := ColorRect.new()
	tent_right.color = Color(0.45, 0.6, 0.4)
	tent_right.size = Vector2(70, 100)
	tent_right.position = Vector2(100, 70)
	container.add_child(tent_right)

	# Tent peak
	var peak := ColorRect.new()
	peak.color = Color(0.5, 0.65, 0.45)
	peak.size = Vector2(30, 20)
	peak.position = Vector2(85, 55)
	container.add_child(peak)

	# Tent opening (dark)
	var opening := ColorRect.new()
	opening.color = Color(0.1, 0.1, 0.12)
	opening.size = Vector2(35, 60)
	opening.position = Vector2(82, 110)
	container.add_child(opening)

	# Pole
	var pole := ColorRect.new()
	pole.color = Color(0.5, 0.4, 0.3)
	pole.size = Vector2(6, 120)
	pole.position = Vector2(97, 50)
	container.add_child(pole)

	return container


func _create_tree() -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(200, 200)

	# Trunk
	var trunk := ColorRect.new()
	trunk.color = Color(0.4, 0.28, 0.15)
	trunk.size = Vector2(30, 80)
	trunk.position = Vector2(85, 120)
	container.add_child(trunk)

	# Trunk detail
	var trunk_detail := ColorRect.new()
	trunk_detail.color = Color(0.35, 0.24, 0.12)
	trunk_detail.size = Vector2(8, 80)
	trunk_detail.position = Vector2(95, 120)
	container.add_child(trunk_detail)

	# Foliage bottom (largest)
	var leaves1 := ColorRect.new()
	leaves1.color = Color(0.2, 0.45, 0.2)
	leaves1.size = Vector2(100, 50)
	leaves1.position = Vector2(50, 85)
	container.add_child(leaves1)

	# Foliage middle
	var leaves2 := ColorRect.new()
	leaves2.color = Color(0.25, 0.5, 0.25)
	leaves2.size = Vector2(80, 45)
	leaves2.position = Vector2(60, 50)
	container.add_child(leaves2)

	# Foliage top
	var leaves3 := ColorRect.new()
	leaves3.color = Color(0.3, 0.55, 0.3)
	leaves3.size = Vector2(55, 40)
	leaves3.position = Vector2(72, 20)
	container.add_child(leaves3)

	# Tree top
	var leaves4 := ColorRect.new()
	leaves4.color = Color(0.35, 0.6, 0.35)
	leaves4.size = Vector2(25, 25)
	leaves4.position = Vector2(87, 5)
	container.add_child(leaves4)

	return container


func _process(delta: float) -> void:
	if not is_loading:
		return

	elapsed_time += delta
	artwork_timer += delta

	# Cycle artwork
	if artwork_timer >= ARTWORK_SWITCH_TIME:
		artwork_timer = 0.0
		artwork_index += 1
		_show_artwork(artwork_index)

	# Check if chunks are loaded
	if not chunks_ready:
		var chunk_manager: Node = get_tree().get_first_node_in_group("chunk_manager")
		if chunk_manager:
			var pending: int = 0
			if chunk_manager.has_method("get_pending_load_count"):
				pending = chunk_manager.get_pending_load_count()

			if pending > 0:
				progress_label.text = "Loading terrain... (%d)" % pending
			else:
				progress_label.text = "Almost ready..."
				chunks_ready = true

	# Check if we can hide the loading screen
	if chunks_ready and elapsed_time >= min_display_time:
		_finish_loading()


func _finish_loading() -> void:
	is_loading = false
	set_process(false)

	progress_label.text = "Ready!"

	# Brief pause then fade out
	await get_tree().create_timer(0.3).timeout

	var tween: Tween = create_tween()
	tween.tween_property(background, "color:a", 0.0, 0.5)
	tween.parallel().tween_property(title_label, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(artwork_container, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(progress_label, "modulate:a", 0.0, 0.5)

	tween.tween_callback(_on_fade_complete)


func _on_fade_complete() -> void:
	loading_complete.emit()
	queue_free()


## Force the loading screen to finish (for testing or skip).
func skip_loading() -> void:
	if is_loading:
		_finish_loading()


func _on_viewport_size_changed() -> void:
	if background and is_instance_valid(background):
		var viewport_size: Vector2 = get_viewport().get_visible_rect().size
		background.size = viewport_size
