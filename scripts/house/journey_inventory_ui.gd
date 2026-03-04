extends CanvasLayer
## Read-only viewer for the wilderness inventory stored in the house.
## Shows all items the player had when they completed their journey.
## Opened from the storage box in the Oakland Hills house.

const HUD_FONT: Font = preload("res://resources/hud_font.tres")

var is_open: bool = false
var _player_ref: Node = null
var _scroll_container: ScrollContainer = null

# Input manager for dynamic button prompts
var _input_manager: Node

const SCROLL_SPEED: float = 400.0


func _ready() -> void:
	layer = 100
	visible = false
	_input_manager = get_node_or_null("/root/InputManager")


func open(player: Node) -> void:
	_player_ref = player
	_build_ui()
	visible = true
	is_open = true

	# Freeze player
	if player and player.has_method("set_resting"):
		player.set_resting(true, self)


func close() -> void:
	visible = false
	is_open = false

	# Unfreeze player
	if _player_ref and is_instance_valid(_player_ref) and _player_ref.has_method("set_resting"):
		_player_ref.set_resting(false)
	_player_ref = null

	# Clean up UI children
	_scroll_container = null
	for child: Node in get_children():
		child.queue_free()


func _process(delta: float) -> void:
	if not is_open or not _scroll_container:
		return
	# Controller right stick or D-pad scrolling
	var scroll_input: float = Input.get_axis("ui_up", "ui_down")
	if abs(scroll_input) > 0.1:
		_scroll_container.scroll_vertical += int(scroll_input * SCROLL_SPEED * delta)


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _get_journey_inventory() -> Dictionary:
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state and "journey_inventory" in game_state:
		return game_state.journey_inventory
	return {}


func _get_display_name(item_type: String) -> String:
	return item_type.capitalize().replace("_", " ")


func _build_ui() -> void:
	# Full-screen dark background
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Centered panel
	var panel: PanelContainer = PanelContainer.new()
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.12, 0.85)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.content_margin_left = 20
	panel_style.content_margin_right = 20
	panel_style.content_margin_top = 20
	panel_style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", panel_style)

	# Anchor to center region of screen (compact width)
	panel.anchor_left = 0.3
	panel.anchor_right = 0.7
	panel.anchor_top = 0.1
	panel.anchor_bottom = 0.9
	panel.offset_left = 0.0
	panel.offset_right = 0.0
	panel.offset_top = 0.0
	panel.offset_bottom = 0.0
	add_child(panel)

	# Main vertical layout
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	# Title
	var title_label: Label = Label.new()
	title_label.text = "W I L D E R N E S S   I N V E N T O R Y"
	title_label.add_theme_font_override("font", HUD_FONT)
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	# Subtitle
	var subtitle_label: Label = Label.new()
	subtitle_label.text = "From your journey in the Carlston Wilderness"
	subtitle_label.add_theme_font_override("font", HUD_FONT)
	subtitle_label.add_theme_font_size_override("font_size", 28)
	subtitle_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle_label)

	# Separator
	var sep: HSeparator = HSeparator.new()
	sep.add_theme_constant_override("separation", 8)
	vbox.add_child(sep)

	# Get inventory data
	var inventory: Dictionary = _get_journey_inventory()

	if inventory.is_empty():
		# Empty state
		var empty_label: Label = Label.new()
		empty_label.text = "No items from the wilderness."
		empty_label.add_theme_font_override("font", HUD_FONT)
		empty_label.add_theme_font_size_override("font_size", 32)
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		vbox.add_child(empty_label)
	else:
		# Scroll container for item list
		var scroll: ScrollContainer = ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_scroll_container = scroll
		vbox.add_child(scroll)

		var item_vbox: VBoxContainer = VBoxContainer.new()
		item_vbox.add_theme_constant_override("separation", 4)
		item_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(item_vbox)

		# Sort items alphabetically by display name
		var sorted_items: Array[Dictionary] = []
		for item_type: String in inventory:
			var count: int = inventory[item_type] as int
			sorted_items.append({
				"type": item_type,
				"name": _get_display_name(item_type),
				"count": count,
			})
		sorted_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return (a["name"] as String) < (b["name"] as String)
		)

		# Build item rows with alternating backgrounds
		for i: int in range(sorted_items.size()):
			var item: Dictionary = sorted_items[i]
			_add_item_row(item_vbox, item["name"] as String, item["count"] as int, i % 2 == 1)

	# Small spacer before close hint
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	# Close hint
	var close_label: Label = Label.new()
	var close_prompt: String = "Esc"
	if _input_manager and _input_manager.has_method("get_prompt"):
		close_prompt = _input_manager.get_prompt("ui_cancel")
	close_label.text = "[%s] Close" % close_prompt
	close_label.add_theme_font_override("font", HUD_FONT)
	close_label.add_theme_font_size_override("font_size", 28)
	close_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	close_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(close_label)


func _add_item_row(parent: VBoxContainer, display_name: String, count: int, alt_bg: bool) -> void:
	# Row panel with optional alternating background
	var row_panel: PanelContainer = PanelContainer.new()
	var row_style: StyleBoxFlat = StyleBoxFlat.new()
	if alt_bg:
		row_style.bg_color = Color(0.15, 0.15, 0.18, 0.4)
	else:
		row_style.bg_color = Color(0, 0, 0, 0)
	row_style.content_margin_left = 12
	row_style.content_margin_right = 12
	row_style.content_margin_top = 6
	row_style.content_margin_bottom = 6
	row_style.corner_radius_top_left = 4
	row_style.corner_radius_top_right = 4
	row_style.corner_radius_bottom_left = 4
	row_style.corner_radius_bottom_right = 4
	row_panel.add_theme_stylebox_override("panel", row_style)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	row_panel.add_child(hbox)

	# Item name (left-aligned)
	var name_label: Label = Label.new()
	name_label.text = display_name
	name_label.add_theme_font_override("font", HUD_FONT)
	name_label.add_theme_font_size_override("font_size", 40)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	hbox.add_child(name_label)

	# Item count (green, with spacing gap)
	var count_label: Label = Label.new()
	count_label.text = "     x%d" % count
	count_label.add_theme_font_override("font", HUD_FONT)
	count_label.add_theme_font_size_override("font_size", 40)
	count_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6, 1))
	hbox.add_child(count_label)

	parent.add_child(row_panel)
