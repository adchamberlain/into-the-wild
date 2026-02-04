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
var root_control: Control  # Root container that fills the screen
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
	# Create a root Control that fills the entire viewport
	# This is necessary because CanvasLayer doesn't have a size for anchors to work
	root_control = Control.new()
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root_control)

	# Dark background that covers entire screen
	background = ColorRect.new()
	background.color = Color(0.06, 0.07, 0.1, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(background)

	# Game title at top (centered horizontally, 10% from top)
	title_label = Label.new()
	title_label.text = "INTO THE WILD"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title_label.offset_top = 80
	title_label.offset_bottom = 160
	title_label.add_theme_font_size_override("font_size", 64)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	root_control.add_child(title_label)

	# Artwork container (centered in screen)
	artwork_container = Control.new()
	artwork_container.set_anchors_preset(Control.PRESET_CENTER)
	artwork_container.offset_left = -150
	artwork_container.offset_right = 150
	artwork_container.offset_top = -150
	artwork_container.offset_bottom = 150
	root_control.add_child(artwork_container)

	# Progress label at bottom (centered horizontally, 85% from top)
	progress_label = Label.new()
	progress_label.text = "Preparing the wilderness..."
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	progress_label.offset_top = -100
	progress_label.offset_bottom = -40
	progress_label.add_theme_font_size_override("font_size", 24)
	progress_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	root_control.add_child(progress_label)

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
	container.custom_minimum_size = Vector2(300, 300)

	# Fire glow (background)
	var glow := ColorRect.new()
	glow.color = Color(1.0, 0.4, 0.1, 0.3)
	glow.size = Vector2(180, 150)
	glow.position = Vector2(60, 75)
	container.add_child(glow)

	# Log 1 (brown rectangle, angled)
	var log1 := ColorRect.new()
	log1.color = Color(0.4, 0.25, 0.1)
	log1.size = Vector2(150, 30)
	log1.position = Vector2(75, 240)
	log1.rotation = -0.2
	container.add_child(log1)

	# Log 2 (crossing)
	var log2 := ColorRect.new()
	log2.color = Color(0.35, 0.22, 0.08)
	log2.size = Vector2(150, 27)
	log2.position = Vector2(75, 232)
	log2.rotation = 0.25
	container.add_child(log2)

	# Fire base (orange)
	var fire_base := ColorRect.new()
	fire_base.color = Color(1.0, 0.5, 0.0)
	fire_base.size = Vector2(90, 75)
	fire_base.position = Vector2(105, 165)
	container.add_child(fire_base)

	# Fire middle (yellow-orange)
	var fire_mid := ColorRect.new()
	fire_mid.color = Color(1.0, 0.7, 0.1)
	fire_mid.size = Vector2(68, 82)
	fire_mid.position = Vector2(116, 105)
	container.add_child(fire_mid)

	# Fire top (yellow)
	var fire_top := ColorRect.new()
	fire_top.color = Color(1.0, 0.9, 0.3)
	fire_top.size = Vector2(38, 60)
	fire_top.position = Vector2(131, 75)
	container.add_child(fire_top)

	# Flame tip
	var flame_tip := ColorRect.new()
	flame_tip.color = Color(1.0, 1.0, 0.6)
	flame_tip.size = Vector2(18, 38)
	flame_tip.position = Vector2(141, 52)
	container.add_child(flame_tip)

	return container


func _create_axe() -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(300, 300)

	# Handle (wooden stick)
	var handle := ColorRect.new()
	handle.color = Color(0.5, 0.35, 0.2)
	handle.size = Vector2(30, 210)
	handle.position = Vector2(135, 75)
	container.add_child(handle)

	# Handle detail (darker stripe)
	var handle_detail := ColorRect.new()
	handle_detail.color = Color(0.4, 0.28, 0.15)
	handle_detail.size = Vector2(9, 210)
	handle_detail.position = Vector2(146, 75)
	container.add_child(handle_detail)

	# Axe head back (darker metal)
	var head_back := ColorRect.new()
	head_back.color = Color(0.4, 0.4, 0.42)
	head_back.size = Vector2(75, 52)
	head_back.position = Vector2(150, 75)
	container.add_child(head_back)

	# Axe head front (lighter metal)
	var head_front := ColorRect.new()
	head_front.color = Color(0.55, 0.55, 0.58)
	head_front.size = Vector2(68, 45)
	head_front.position = Vector2(158, 80)
	container.add_child(head_front)

	# Blade edge (shiny)
	var blade := ColorRect.new()
	blade.color = Color(0.75, 0.75, 0.8)
	blade.size = Vector2(12, 42)
	blade.position = Vector2(218, 81)
	container.add_child(blade)

	# Binding
	var binding := ColorRect.new()
	binding.color = Color(0.45, 0.35, 0.25)
	binding.size = Vector2(39, 22)
	binding.position = Vector2(130, 120)
	container.add_child(binding)

	return container


func _create_fishing_rod() -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(300, 300)

	# Rod handle (cork color)
	var grip := ColorRect.new()
	grip.color = Color(0.65, 0.5, 0.35)
	grip.size = Vector2(27, 75)
	grip.position = Vector2(60, 210)
	container.add_child(grip)

	# Reel seat
	var reel := ColorRect.new()
	reel.color = Color(0.25, 0.25, 0.25)
	reel.size = Vector2(21, 30)
	reel.position = Vector2(63, 188)
	container.add_child(reel)

	# Rod body
	var rod := ColorRect.new()
	rod.color = Color(0.4, 0.3, 0.2)
	rod.size = Vector2(15, 150)
	rod.position = Vector2(66, 45)
	container.add_child(rod)

	# Rod tip
	var tip := ColorRect.new()
	tip.color = Color(0.35, 0.28, 0.18)
	tip.size = Vector2(9, 45)
	tip.position = Vector2(69, 8)
	container.add_child(tip)

	# Fishing line
	var line := ColorRect.new()
	line.color = Color(0.8, 0.8, 0.8, 0.7)
	line.size = Vector2(3, 120)
	line.position = Vector2(72, 8)
	line.rotation = 0.4
	container.add_child(line)

	# Hook
	var hook := ColorRect.new()
	hook.color = Color(0.6, 0.6, 0.62)
	hook.size = Vector2(12, 22)
	hook.position = Vector2(142, 98)
	container.add_child(hook)

	# Fish!
	var fish_body := ColorRect.new()
	fish_body.color = Color(0.5, 0.6, 0.7)
	fish_body.size = Vector2(68, 30)
	fish_body.position = Vector2(165, 120)
	container.add_child(fish_body)

	var fish_tail := ColorRect.new()
	fish_tail.color = Color(0.45, 0.55, 0.65)
	fish_tail.size = Vector2(22, 38)
	fish_tail.position = Vector2(225, 116)
	container.add_child(fish_tail)

	return container


func _create_tent() -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(300, 300)

	# Ground
	var ground := ColorRect.new()
	ground.color = Color(0.3, 0.25, 0.15)
	ground.size = Vector2(300, 30)
	ground.position = Vector2(0, 255)
	container.add_child(ground)

	# Tent back (darker)
	var tent_back := ColorRect.new()
	tent_back.color = Color(0.35, 0.45, 0.3)
	tent_back.size = Vector2(210, 150)
	tent_back.position = Vector2(45, 105)
	container.add_child(tent_back)

	# Tent front left
	var tent_left := ColorRect.new()
	tent_left.color = Color(0.4, 0.55, 0.35)
	tent_left.size = Vector2(105, 150)
	tent_left.position = Vector2(45, 105)
	container.add_child(tent_left)

	# Tent front right
	var tent_right := ColorRect.new()
	tent_right.color = Color(0.45, 0.6, 0.4)
	tent_right.size = Vector2(105, 150)
	tent_right.position = Vector2(150, 105)
	container.add_child(tent_right)

	# Tent peak
	var peak := ColorRect.new()
	peak.color = Color(0.5, 0.65, 0.45)
	peak.size = Vector2(45, 30)
	peak.position = Vector2(128, 82)
	container.add_child(peak)

	# Tent opening (dark)
	var opening := ColorRect.new()
	opening.color = Color(0.1, 0.1, 0.12)
	opening.size = Vector2(52, 90)
	opening.position = Vector2(123, 165)
	container.add_child(opening)

	# Pole
	var pole := ColorRect.new()
	pole.color = Color(0.5, 0.4, 0.3)
	pole.size = Vector2(9, 180)
	pole.position = Vector2(146, 75)
	container.add_child(pole)

	return container


func _create_tree() -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(300, 300)

	# Trunk
	var trunk := ColorRect.new()
	trunk.color = Color(0.4, 0.28, 0.15)
	trunk.size = Vector2(45, 120)
	trunk.position = Vector2(128, 180)
	container.add_child(trunk)

	# Trunk detail
	var trunk_detail := ColorRect.new()
	trunk_detail.color = Color(0.35, 0.24, 0.12)
	trunk_detail.size = Vector2(12, 120)
	trunk_detail.position = Vector2(143, 180)
	container.add_child(trunk_detail)

	# Foliage bottom (largest)
	var leaves1 := ColorRect.new()
	leaves1.color = Color(0.2, 0.45, 0.2)
	leaves1.size = Vector2(150, 75)
	leaves1.position = Vector2(75, 128)
	container.add_child(leaves1)

	# Foliage middle
	var leaves2 := ColorRect.new()
	leaves2.color = Color(0.25, 0.5, 0.25)
	leaves2.size = Vector2(120, 68)
	leaves2.position = Vector2(90, 75)
	container.add_child(leaves2)

	# Foliage top
	var leaves3 := ColorRect.new()
	leaves3.color = Color(0.3, 0.55, 0.3)
	leaves3.size = Vector2(82, 60)
	leaves3.position = Vector2(108, 30)
	container.add_child(leaves3)

	# Tree top
	var leaves4 := ColorRect.new()
	leaves4.color = Color(0.35, 0.6, 0.35)
	leaves4.size = Vector2(38, 38)
	leaves4.position = Vector2(131, 8)
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
	tween.tween_property(root_control, "modulate:a", 0.0, 0.5)

	tween.tween_callback(_on_fade_complete)


func _on_fade_complete() -> void:
	loading_complete.emit()
	queue_free()


## Force the loading screen to finish (for testing or skip).
func skip_loading() -> void:
	if is_loading:
		_finish_loading()
