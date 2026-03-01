extends CanvasLayer
## Full-screen UI for reading the Explorer's Journal found in the desert sinkhole.

signal journal_closed(was_first_read: bool)

var _is_first_read: bool = false
var _is_open: bool = false

# UI nodes (created programmatically)
var background: ColorRect
var panel: PanelContainer

const JOURNAL_TEXT: String = """Day 47. I've mapped every oasis in this forsaken desert
ring — three in all, each hiding gemstones beneath the
water. Diamonds in two of them, opals in the third. The
opal pool has a river that flows to it from the east.

The caves in the rocky highlands hold crystals and rare
ore. I've marked four entrances. Bring light — the
darkness in those tunnels will kill you faster than any
beast.

I spent weeks perfecting a design for a glider — fabric
stretched across a frame of branches and rope. From the
mountain peaks, you can see the whole world. The plans
are sketched on the last page.

If you've found this, you've earned what I've left
behind. The wilderness gives its secrets to those willing
to go deep."""


func _ready() -> void:
	# Process even when tree is paused (we pause the tree while journal is open)
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 80


func open_journal(is_first_read: bool) -> void:
	_is_first_read = is_first_read
	_is_open = true
	_build_ui()

	# Pause the game tree
	get_tree().paused = true


func _build_ui() -> void:
	var font: Font = load("res://resources/hud_font.tres")
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	if vp_size == Vector2.ZERO:
		vp_size = Vector2(1920, 1080)

	# Full-screen dark background
	background = ColorRect.new()
	background.color = Color(0.0, 0.0, 0.0, 0.7)
	background.anchors_preset = Control.PRESET_FULL_RECT
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	# Centered panel
	panel = PanelContainer.new()
	panel.process_mode = Node.PROCESS_MODE_ALWAYS

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12, 0.9)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 25
	style.content_margin_bottom = 25
	panel.add_theme_stylebox_override("panel", style)

	# Center the panel with max width ~800px
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -400
	panel.offset_top = -320
	panel.offset_right = 400
	panel.offset_bottom = 320
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	# Title
	var title_label: Label = Label.new()
	title_label.text = "Explorer's Journal"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_override("font", font)
	title_label.add_theme_font_size_override("font_size", 56)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))
	vbox.add_child(title_label)

	# Separator
	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)

	# Journal body text
	var body_label: Label = Label.new()
	body_label.text = JOURNAL_TEXT
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_override("font", font)
	body_label.add_theme_font_size_override("font_size", 28)
	body_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(body_label)

	# Spacer
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	# Hint at bottom
	var hint_label: Label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_override("font", font)
	hint_label.add_theme_font_size_override("font_size", 28)
	hint_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65, 1))

	# Detect controller vs keyboard
	var input_mgr: Node = get_node_or_null("/root/InputManager")
	if input_mgr and input_mgr.has_method("is_using_controller") and input_mgr.is_using_controller():
		hint_label.text = "[Circle to close]"
	else:
		hint_label.text = "[ESC or B to close]"

	vbox.add_child(hint_label)

	add_child(panel)


func _input(event: InputEvent) -> void:
	if not is_inside_tree():
		return
	if not _is_open:
		return

	# Close on ESC, ui_cancel (Circle on controller), or B key
	var close: bool = false
	if event.is_action_pressed("pause"):
		close = true
	elif event.is_action_pressed("ui_cancel"):
		close = true
	elif event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.physical_keycode == KEY_B:
			close = true

	if close:
		_close_journal()
		var vp: Viewport = get_viewport()
		if vp:
			vp.set_input_as_handled()


func _close_journal() -> void:
	if not _is_open:
		return
	_is_open = false

	# Unpause the game tree
	get_tree().paused = false

	journal_closed.emit(_is_first_read)
