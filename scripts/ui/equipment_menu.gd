extends CanvasLayer
## Equipment menu showing available items and their hotkeys.

# Standard HUD font
const HUD_FONT: Font = preload("res://resources/hud_font.tres")

@export var player_path: NodePath

var player: Node
var inventory: Node
var equipment: Node

# UI References
@onready var panel: PanelContainer = $Panel
@onready var item_list: VBoxContainer = $Panel/VBoxContainer/ItemList

var is_visible: bool = false

# Equipment slot definitions
const EQUIPMENT_SLOTS: Array = [
	{"key": "1", "type": "torch", "name": "Torch"},
	{"key": "2", "type": "stone_axe", "name": "Stone Axe"},
	{"key": "3", "type": "campfire_kit", "name": "Campfire Kit"},
	{"key": "4", "type": "rope", "name": "Rope"},
	{"key": "5", "type": "shelter_kit", "name": "Shelter Kit"},
	{"key": "6", "type": "storage_box", "name": "Storage Box"},
	{"key": "7", "type": "fishing_rod", "name": "Fishing Rod"},
	{"key": "8", "type": "crafting_bench_kit", "name": "Crafting Bench Kit"},
	{"key": "9", "type": "drying_rack_kit", "name": "Drying Rack Kit"},
	{"key": "0", "type": "garden_plot_kit", "name": "Garden Plot Kit"},
	{"key": "-", "type": "canvas_tent_kit", "name": "Canvas Tent Kit"},
	{"key": "=", "type": "cabin_kit", "name": "Cabin Kit"},
	{"key": "[", "type": "grappling_hook", "name": "Grappling Hook"},
	{"key": "]", "type": "map", "name": "Map"},
	{"key": "\\", "type": "bow", "name": "Bow"},
	{"key": "", "type": "metal_axe", "name": "Metal Axe"},
	{"key": "", "type": "snare_trap_kit", "name": "Snare Trap Kit"},
	{"key": "", "type": "smithing_station_kit", "name": "Smithing Station Kit"},
	{"key": "", "type": "smoker_kit", "name": "Smoker Kit"},
	{"key": "", "type": "weather_vane_kit", "name": "Weather Vane Kit"},
	{"key": "", "type": "machete", "name": "Machete"},
	{"key": "", "type": "lantern", "name": "Lantern"},
	{"key": "", "type": "primitive_axe", "name": "Primitive Axe"},
	{"key": "", "type": "lodestone", "name": "Lodestone"},
	{"key": "", "type": "leather_axe_wrap", "name": "Leather Axe Wrap"},
	{"key": "", "type": "leather_hook_wrap", "name": "Leather Hook Wrap"},
	{"key": "", "type": "leather_bow_wrap", "name": "Leather Bow Wrap"},
]

# Cached labels for each slot
var slot_labels: Dictionary = {}

# Controller navigation
var focused_slot_index: int = 0
var slot_panels: Array[PanelContainer] = []  # For highlighting focused item


func _ready() -> void:
	# Add to group for UI state detection
	add_to_group("equipment_menu")

	# Get player reference
	if player_path:
		player = get_node_or_null(player_path)
		if player:
			if player.has_method("get_inventory"):
				inventory = player.get_inventory()
				if inventory:
					inventory.inventory_changed.connect(_on_inventory_changed)
			if player.has_method("get_equipment"):
				equipment = player.get_equipment()
				if equipment:
					equipment.item_equipped.connect(_on_item_equipped)
					equipment.item_unequipped.connect(_on_item_unequipped)

	# Build the UI
	_build_slot_list()

	# Start hidden
	panel.visible = false
	is_visible = false

	if OS.get_name() == "iOS":
		_apply_mobile_menu_style()


func _build_slot_list() -> void:
	# Clear existing children except template
	for child in item_list.get_children():
		child.queue_free()
	slot_labels.clear()
	slot_panels.clear()

	var is_mobile: bool = OS.get_name() == "iOS"
	var font_size: int = 22 if is_mobile else 28

	# Create a panel with label for each slot (panel allows highlight for controller nav)
	for slot in EQUIPMENT_SLOTS:
		var item_panel: PanelContainer = PanelContainer.new()
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)  # Transparent by default
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 3 if is_mobile else 4
		style.content_margin_bottom = 3 if is_mobile else 4
		item_panel.add_theme_stylebox_override("panel", style)

		# On mobile, use a button for tap-to-equip; on desktop use a label
		if is_mobile:
			var btn: Button = Button.new()
			btn.add_theme_font_override("font", HUD_FONT)
			btn.add_theme_font_size_override("font_size", font_size)
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.custom_minimum_size = Vector2(0, 44)
			var slot_type: String = slot["type"]
			btn.pressed.connect(_on_mobile_slot_pressed.bind(slot_type))
			item_panel.add_child(btn)
			slot_labels[slot["type"]] = btn
		else:
			var label: Label = Label.new()
			label.add_theme_font_override("font", HUD_FONT)
			label.add_theme_font_size_override("font_size", font_size)
			item_panel.add_child(label)
			slot_labels[slot["type"]] = label

		item_list.add_child(item_panel)
		slot_panels.append(item_panel)

	# Update display
	_update_display()


func _update_display() -> void:
	var is_mobile: bool = OS.get_name() == "iOS"

	# Check if using controller for different display format
	var using_controller: bool = false
	var input_mgr: Node = get_node_or_null("/root/InputManager")
	if input_mgr and input_mgr.has_method("is_using_controller"):
		using_controller = input_mgr.is_using_controller()

	for i: int in range(EQUIPMENT_SLOTS.size()):
		var slot: Dictionary = EQUIPMENT_SLOTS[i]
		var slot_type: String = slot["type"]
		var node: Control = slot_labels.get(slot_type)
		if not node:
			continue

		var key: String = slot["key"]
		var item_name: String = slot["name"]
		var count: int = 0
		var is_equipped: bool = false

		# Check inventory count
		if inventory:
			count = inventory.get_item_count(slot_type)

		# Check if equipped
		if equipment:
			is_equipped = equipment.get_equipped() == slot_type

		# On mobile, hide items with 0 count (keeps list clean)
		if is_mobile:
			var parent_panel: Control = node.get_parent()
			if parent_panel:
				parent_panel.visible = count > 0 or is_equipped

		# Build display text
		var text: String
		if is_mobile:
			text = item_name
		elif using_controller:
			text = item_name
		elif key != "":
			text = "[%s] %s" % [key, item_name]
		else:
			text = "    %s" % item_name

		if count > 0:
			text += " (x%d)" % count
		elif not is_mobile:
			text += " (none)"

		if is_equipped:
			text += " [EQUIPPED]"
			node.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4, 1))
		elif count > 0:
			node.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1))
		else:
			node.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))

		node.text = text


func _input(event: InputEvent) -> void:
	# Don't process input if not in tree (prevents null viewport errors during scene transitions)
	if not is_inside_tree():
		return

	# Toggle menu with I key or Create button
	if event.is_action_pressed("open_inventory"):
		# Don't open if another menu is already open (unless closing this one)
		if not is_visible and _is_other_menu_open():
			return
		toggle_menu()
		_handle_input()
		return

	# Only handle other inputs when menu is open
	if not is_visible:
		return

	# Close menu with cancel action when open
	if event.is_action_pressed("ui_cancel"):
		toggle_menu()
		_handle_input()
		return

	# D-pad navigation (disabled when using touch — touch handles selection)
	if not InputManager.is_using_touch():
		if event.is_action_pressed("ui_down"):
			_navigate_slots(1)
			_handle_input()
			return
		if event.is_action_pressed("ui_up"):
			_navigate_slots(-1)
			_handle_input()
			return

		# Cross button (ui_accept) to equip focused item
		if event.is_action_pressed("ui_accept"):
			_equip_focused_slot()
			_handle_input()
			return


func _handle_input() -> void:
	var vp: Viewport = get_viewport()
	if vp:
		vp.set_input_as_handled()


## Check if another UI menu is open (prevents overlapping menus).
func _is_other_menu_open() -> bool:
	for node in get_tree().get_nodes_in_group("crafting_ui"):
		if "is_open" in node and node.is_open:
			return true
	for node in get_tree().get_nodes_in_group("config_menu"):
		if "is_visible" in node and node.is_visible:
			return true
	for node in get_tree().get_nodes_in_group("storage_ui"):
		if "is_open" in node and node.is_open:
			return true
	for node in get_tree().get_nodes_in_group("fire_menu"):
		if "is_open" in node and node.is_open:
			return true
	return false


## Handle tap-to-equip on mobile.
func _on_mobile_slot_pressed(slot_type: String) -> void:
	if not equipment:
		return
	# If already equipped, unequip; otherwise equip
	if equipment.get_equipped() == slot_type:
		equipment.unequip()
	else:
		if inventory and inventory.get_item_count(slot_type) > 0:
			equipment.equip(slot_type)
	_update_display()
	SFXManager.play_sfx("select")


func toggle_menu() -> void:
	is_visible = not is_visible
	panel.visible = is_visible
	var close_btn: Button = get_node_or_null("MobileCloseButton") as Button
	if close_btn:
		close_btn.visible = is_visible

	if is_visible:
		SFXManager.play_sfx("menu_open")
		if OS.get_name() != "iOS":
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		TouchControls.menu_open = true
		focused_slot_index = 0
		_update_display()
		_update_focus_highlight()
	else:
		SFXManager.play_sfx("menu_close")
		if OS.get_name() != "iOS":
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		TouchControls.menu_open = false


func _on_inventory_changed() -> void:
	if is_visible:
		_update_display()


func _on_item_equipped(_item_type: String) -> void:
	if is_visible:
		_update_display()


func _on_item_unequipped(_item_type: String) -> void:
	if is_visible:
		_update_display()


## Navigate through equipment slots with D-pad.
func _navigate_slots(direction: int) -> void:
	if slot_panels.is_empty():
		return

	focused_slot_index = (focused_slot_index + direction) % slot_panels.size()
	if focused_slot_index < 0:
		focused_slot_index = slot_panels.size() - 1

	_update_focus_highlight()
	SFXManager.play_sfx("select")


## Update visual highlight on focused slot.
func _update_focus_highlight() -> void:
	for i: int in range(slot_panels.size()):
		var panel: PanelContainer = slot_panels[i]
		var style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate()
		if i == focused_slot_index:
			style.bg_color = Color(0.3, 0.3, 0.4, 0.8)  # Highlighted
		else:
			style.bg_color = Color(0, 0, 0, 0)  # Transparent
		panel.add_theme_stylebox_override("panel", style)


func _apply_mobile_menu_style() -> void:
	# Reposition panel as a centered overlay — compact and clear of HUD elements
	panel.anchor_left = 0.2
	panel.anchor_right = 0.8
	panel.anchor_top = 0.12
	panel.anchor_bottom = 0.88
	panel.offset_left = 0
	panel.offset_right = 0
	panel.offset_top = 0
	panel.offset_bottom = 0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	# Wrap the ItemList in a ScrollContainer for touch scrolling
	var vbox: VBoxContainer = panel.get_node_or_null("VBoxContainer")
	if vbox and item_list:
		var scroll: ScrollContainer = ScrollContainer.new()
		scroll.name = "MobileScroll"
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		# Reparent item_list into scroll
		var idx: int = item_list.get_index()
		vbox.remove_child(item_list)
		scroll.add_child(item_list)
		vbox.add_child(scroll)
		vbox.move_child(scroll, idx)

	# Reduce font sizes for mobile
	var title: Label = panel.get_node_or_null("VBoxContainer/Title")
	if title:
		title.text = "Equipment"
		title.add_theme_font_size_override("font_size", 28)

	# Hide keyboard hint at bottom on mobile
	var hint: Label = panel.get_node_or_null("VBoxContainer/HintLabel")
	if hint:
		hint.text = "Tap to equip"
		hint.add_theme_font_size_override("font_size", 20)

	# Add close button as a CanvasLayer child (NOT inside PanelContainer,
	# which would stretch it to fill the entire panel and intercept all taps)
	var close_btn: Button = Button.new()
	close_btn.name = "MobileCloseButton"
	close_btn.text = "✕"
	close_btn.add_theme_font_size_override("font_size", 32)
	close_btn.custom_minimum_size = Vector2(48, 48)
	# Position at top-right of the panel (panel anchors 0.2-0.8 x 0.12-0.88)
	close_btn.anchor_left = 0.8
	close_btn.anchor_right = 0.8
	close_btn.anchor_top = 0.12
	close_btn.anchor_bottom = 0.12
	close_btn.offset_left = -56
	close_btn.offset_top = 4
	close_btn.offset_right = -8
	close_btn.offset_bottom = 52
	close_btn.visible = false
	close_btn.pressed.connect(toggle_menu)
	add_child(close_btn)


static func _enforce_min_button_size(node: Node, min_size: int) -> void:
	for child: Node in node.get_children():
		if child is Button:
			if child.custom_minimum_size.x < min_size:
				child.custom_minimum_size.x = min_size
			if child.custom_minimum_size.y < min_size:
				child.custom_minimum_size.y = min_size
		_enforce_min_button_size(child, min_size)


## Equip the currently focused item.
func _equip_focused_slot() -> void:
	if focused_slot_index < 0 or focused_slot_index >= EQUIPMENT_SLOTS.size():
		return

	var slot: Dictionary = EQUIPMENT_SLOTS[focused_slot_index]
	var slot_type: String = slot["type"]

	# Check if we have the item
	if inventory and inventory.get_item_count(slot_type) > 0:
		if equipment and equipment.has_method("equip"):
			equipment.equip(slot_type)
			SFXManager.play_sfx("select")
			_update_display()
