extends CanvasLayer
## Full-screen UI for reading the Explorer's Journal found in the desert sinkhole.

signal journal_closed(was_first_read: bool)

var _is_first_read: bool = false
var _is_open: bool = false
var _current_page: int = 0
var _total_pages: int = 0

# Page content containers (rebuilt on page turn)
var _left_vbox: VBoxContainer
var _right_vbox: VBoxContainer

# UI nodes (created programmatically)
var background: ColorRect
var panel: PanelContainer


func _get_pages() -> Array[Dictionary]:
	var pages: Array[Dictionary] = []

	# Spread 1: Title page
	pages.append({
		"left_title": "Explorer's Journal",
		"left_text": "A Record of the Carlston Wilderness\n\n~ ~ ~\n\nProperty of E.W. Carlston",
		"right_text": "Day 1\n\nI arrived at the edge of the Carlston Wilderness this morning with little more than my boots and a good feeling. The forest here is beautiful — birch and pine standing so close together they form a kind of cathedral. Found a clear pond not far from where I set up camp. Fish rising at dusk. If I can rig a fishing rod, dinner is sorted.\n\nRabbits everywhere. Birds calling from every direction. The air smells like pine needles after rain. I've decided to map this whole place, every last corner of it. Something tells me it's worth the effort.",
		"is_title_page": true,
		"is_recipe_page": false,
	})

	# Spread 2: Day 5
	pages.append({
		"left_title": "Day 5",
		"left_text": "[CONTENT TODO]",
		"right_text": "[CONTENT TODO]",
		"is_title_page": false,
		"is_recipe_page": false,
	})

	# Spread 3: Day 12
	pages.append({
		"left_title": "Day 12",
		"left_text": "[CONTENT TODO]",
		"right_text": "[CONTENT TODO]",
		"is_title_page": false,
		"is_recipe_page": false,
	})

	# Spread 4: Day 20
	pages.append({
		"left_title": "Day 20",
		"left_text": "[CONTENT TODO]",
		"right_text": "[CONTENT TODO]",
		"is_title_page": false,
		"is_recipe_page": false,
	})

	# Spread 5: Day 31
	pages.append({
		"left_title": "Day 31",
		"left_text": "[CONTENT TODO]",
		"right_text": "[CONTENT TODO]",
		"is_title_page": false,
		"is_recipe_page": false,
	})

	# Spread 6: Day 47
	pages.append({
		"left_title": "Day 47",
		"left_text": "[CONTENT TODO]",
		"right_text": "[CONTENT TODO]",
		"is_title_page": false,
		"is_recipe_page": false,
	})

	# Spread 7: Hand Crafting recipes
	pages.append({
		"left_title": "Field Notes: Hand Crafting",
		"left_text": "[CONTENT TODO]",
		"right_text": "[CONTENT TODO]",
		"is_title_page": false,
		"is_recipe_page": true,
	})

	# Spread 8: Getting Established recipes
	pages.append({
		"left_title": "Getting Established",
		"left_text": "[CONTENT TODO]",
		"right_text": "[CONTENT TODO]",
		"is_title_page": false,
		"is_recipe_page": true,
	})

	# Spread 9: Expanding Your Range recipes
	pages.append({
		"left_title": "Expanding Your Range",
		"left_text": "[CONTENT TODO]",
		"right_text": "[CONTENT TODO]",
		"is_title_page": false,
		"is_recipe_page": true,
	})

	# Spread 10: Advanced Crafting recipes
	pages.append({
		"left_title": "Advanced Crafting",
		"left_text": "[CONTENT TODO]",
		"right_text": "[CONTENT TODO]",
		"is_title_page": false,
		"is_recipe_page": true,
	})

	# Spread 11: Rare & Extraordinary recipes
	pages.append({
		"left_title": "Rare & Extraordinary",
		"left_text": "[CONTENT TODO]",
		"right_text": "[CONTENT TODO]",
		"is_title_page": false,
		"is_recipe_page": true,
	})

	return pages


func _ready() -> void:
	# Process even when tree is paused (we pause the tree while journal is open)
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 80


func open_journal(is_first_read: bool) -> void:
	_is_first_read = is_first_read
	_is_open = true
	_current_page = 0
	_total_pages = _get_pages().size()
	_build_ui()

	# Pause the game tree
	get_tree().paused = true


func _build_ui() -> void:
	var font: Font = load("res://resources/hud_font.tres")
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	if vp_size == Vector2.ZERO:
		vp_size = Vector2(1920, 1080)
	var sf: float = vp_size.y / 1080.0

	var ink_color: Color = Color(0.18, 0.12, 0.06)
	var parchment_color: Color = Color(0.88, 0.82, 0.68)
	var leather_color: Color = Color(0.38, 0.24, 0.10)
	var spine_color: Color = Color(0.28, 0.16, 0.06)

	# Full-screen dark overlay
	background = ColorRect.new()
	background.color = Color(0.0, 0.0, 0.0, 0.75)
	background.anchors_preset = Control.PRESET_FULL_RECT
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	# Drop shadow behind book
	var shadow: PanelContainer = PanelContainer.new()
	shadow.process_mode = Node.PROCESS_MODE_ALWAYS
	var shadow_style: StyleBoxFlat = StyleBoxFlat.new()
	shadow_style.bg_color = Color(0.0, 0.0, 0.0, 0.4)
	shadow_style.corner_radius_top_left = int(14 * sf)
	shadow_style.corner_radius_top_right = int(14 * sf)
	shadow_style.corner_radius_bottom_left = int(14 * sf)
	shadow_style.corner_radius_bottom_right = int(14 * sf)
	shadow.add_theme_stylebox_override("panel", shadow_style)
	shadow.anchor_left = 0.5
	shadow.anchor_top = 0.5
	shadow.anchor_right = 0.5
	shadow.anchor_bottom = 0.5
	var book_w: float = 860 * sf
	var book_h: float = 560 * sf
	shadow.offset_left = -book_w / 2.0 + 4 * sf
	shadow.offset_top = -book_h / 2.0 + 4 * sf
	shadow.offset_right = book_w / 2.0 + 4 * sf
	shadow.offset_bottom = book_h / 2.0 + 4 * sf
	add_child(shadow)

	# Leather cover panel (the book itself)
	panel = PanelContainer.new()
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	var cover_style: StyleBoxFlat = StyleBoxFlat.new()
	cover_style.bg_color = leather_color
	cover_style.corner_radius_top_left = int(12 * sf)
	cover_style.corner_radius_top_right = int(12 * sf)
	cover_style.corner_radius_bottom_left = int(12 * sf)
	cover_style.corner_radius_bottom_right = int(12 * sf)
	cover_style.content_margin_left = int(10 * sf)
	cover_style.content_margin_right = int(10 * sf)
	cover_style.content_margin_top = int(10 * sf)
	cover_style.content_margin_bottom = int(10 * sf)
	panel.add_theme_stylebox_override("panel", cover_style)

	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -book_w / 2.0
	panel.offset_top = -book_h / 2.0
	panel.offset_right = book_w / 2.0
	panel.offset_bottom = book_h / 2.0

	# HBox: left page | spine | right page
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(hbox)

	# --- Left page ---
	var left_page: PanelContainer = PanelContainer.new()
	var left_style: StyleBoxFlat = StyleBoxFlat.new()
	left_style.bg_color = parchment_color
	left_style.corner_radius_top_left = int(6 * sf)
	left_style.corner_radius_bottom_left = int(6 * sf)
	left_style.content_margin_left = int(30 * sf)
	left_style.content_margin_right = int(24 * sf)
	left_style.content_margin_top = int(30 * sf)
	left_style.content_margin_bottom = int(24 * sf)
	left_page.add_theme_stylebox_override("panel", left_style)
	left_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var left_vbox: VBoxContainer = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", int(12 * sf))
	left_page.add_child(left_vbox)

	# Title
	var title_label: Label = Label.new()
	title_label.text = "Explorer's Journal"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_override("font", font)
	title_label.add_theme_font_size_override("font_size", int(40 * sf))
	title_label.add_theme_color_override("font_color", Color(0.30, 0.18, 0.06))
	left_vbox.add_child(title_label)

	# Horizontal rule (drawn as a colored separator line)
	var rule: ColorRect = ColorRect.new()
	rule.color = Color(0.45, 0.32, 0.15, 0.6)
	rule.custom_minimum_size = Vector2(0, 2 * sf)
	left_vbox.add_child(rule)

	# Decorative element — small flourish text
	var flourish: Label = Label.new()
	flourish.text = "~ ~ ~"
	flourish.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flourish.add_theme_font_override("font", font)
	flourish.add_theme_font_size_override("font_size", int(24 * sf))
	flourish.add_theme_color_override("font_color", Color(0.45, 0.32, 0.15, 0.5))
	left_vbox.add_child(flourish)

	# "Day 47" heading
	var day_label: Label = Label.new()
	day_label.text = "Day 47"
	day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_label.add_theme_font_override("font", font)
	day_label.add_theme_font_size_override("font_size", int(32 * sf))
	day_label.add_theme_color_override("font_color", ink_color)
	left_vbox.add_child(day_label)

	# Left page body — first half of journal text
	var left_body: Label = Label.new()
	left_body.text = "I've mapped every oasis in this\nforsaken desert ring — three in\nall, each hiding gemstones\nbeneath the water. Diamonds in\ntwo of them, opals in the third.\nThe opal pool has a river that\nflows to it from the east.\n\nThe caves in the rocky highlands\nhold crystals and rare ore. I've\nmarked four entrances. Bring\nlight — the darkness will kill\nyou faster than any beast."
	left_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_body.add_theme_font_override("font", font)
	left_body.add_theme_font_size_override("font_size", int(22 * sf))
	left_body.add_theme_color_override("font_color", ink_color)
	left_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_child(left_body)

	hbox.add_child(left_page)

	# --- Spine ---
	var spine_panel: PanelContainer = PanelContainer.new()
	var spine_style: StyleBoxFlat = StyleBoxFlat.new()
	spine_style.bg_color = spine_color
	spine_panel.add_theme_stylebox_override("panel", spine_style)
	spine_panel.custom_minimum_size = Vector2(20 * sf, 0)
	# Empty content to hold the minimum width
	var spine_spacer: Control = Control.new()
	spine_panel.add_child(spine_spacer)
	hbox.add_child(spine_panel)

	# --- Right page ---
	var right_page: PanelContainer = PanelContainer.new()
	var right_style: StyleBoxFlat = StyleBoxFlat.new()
	right_style.bg_color = parchment_color
	right_style.corner_radius_top_right = int(6 * sf)
	right_style.corner_radius_bottom_right = int(6 * sf)
	right_style.content_margin_left = int(24 * sf)
	right_style.content_margin_right = int(30 * sf)
	right_style.content_margin_top = int(30 * sf)
	right_style.content_margin_bottom = int(24 * sf)
	right_page.add_theme_stylebox_override("panel", right_style)
	right_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var right_vbox: VBoxContainer = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", int(12 * sf))
	right_page.add_child(right_vbox)

	# Right page body — second half
	var right_body: Label = Label.new()
	right_body.text = "I spent weeks perfecting a design\nfor a glider — fabric stretched\nacross a frame of branches and\nrope. From the mountain peaks,\nyou can see the whole world. The\nplans are sketched on the last\npage.\n\nIf you've found this, you've\nearned what I've left behind.\nThe wilderness gives its secrets\nto those willing to go deep."
	right_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_body.add_theme_font_override("font", font)
	right_body.add_theme_font_size_override("font_size", int(22 * sf))
	right_body.add_theme_color_override("font_color", ink_color)
	right_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(right_body)

	# Close hint at bottom of right page
	var hint_label: Label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint_label.add_theme_font_override("font", font)
	hint_label.add_theme_font_size_override("font_size", int(20 * sf))
	hint_label.add_theme_color_override("font_color", Color(0.45, 0.32, 0.15, 0.5))

	var input_mgr: Node = get_node_or_null("/root/InputManager")
	if input_mgr and input_mgr.has_method("is_using_controller") and input_mgr.is_using_controller():
		hint_label.text = "X to close"
	else:
		hint_label.text = "ESC or B to close"

	right_vbox.add_child(hint_label)
	hbox.add_child(right_page)

	add_child(panel)


func _input(event: InputEvent) -> void:
	if not is_inside_tree():
		return
	if not _is_open:
		return

	# Close on ESC, ui_cancel, or B key
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
