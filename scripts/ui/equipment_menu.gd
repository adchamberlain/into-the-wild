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
	{"key": "", "type": "rope_ladder_kit", "name": "Rope Ladder Kit"},
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


func _build_slot_list() -> void:
	# Clear existing children except template
	for child in item_list.get_children():
		child.queue_free()
	slot_labels.clear()
	slot_panels.clear()

	# Create a panel with label for each slot (panel allows highlight for controller nav)
	for slot in EQUIPMENT_SLOTS:
		var item_panel: PanelContainer = PanelContainer.new()
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)  # Transparent by default
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		item_panel.add_theme_stylebox_override("panel", style)

		var label: Label = Label.new()
		label.add_theme_font_override("font", HUD_FONT)
		label.add_theme_font_size_override("font_size", 28)
		item_panel.add_child(label)

		item_list.add_child(item_panel)
		slot_labels[slot["type"]] = label
		slot_panels.append(item_panel)

	# Update display
	_update_display()


func _update_display() -> void:
	if inventory:
		print("[EquipmentMenu] Inventory contents: ", inventory.get_all_items())
	else:
		print("[EquipmentMenu] WARNING: No inventory reference!")

	# Check if using controller for different display format
	var using_controller: bool = false
	var input_mgr: Node = get_node_or_null("/root/InputManager")
	if input_mgr and input_mgr.has_method("is_using_controller"):
		using_controller = input_mgr.is_using_controller()

	for slot in EQUIPMENT_SLOTS:
		var slot_type: String = slot["type"]
		var label: Label = slot_labels.get(slot_type)
		if not label:
			continue

		var key: String = slot["key"]
		var name: String = slot["name"]
		var count: int = 0
		var is_equipped: bool = false

		# Check inventory count
		if inventory:
			count = inventory.get_item_count(slot_type)

		# Check if equipped
		if equipment:
			is_equipped = equipment.get_equipped() == slot_type

		# Build display text - show keyboard keys or controller cycle hint
		var text: String
		if using_controller:
			text = name  # No key hints for controller (use L1/R1 to cycle)
		else:
			text = "[%s] %s" % [key, name]

		if count > 0:
			text += " (x%d)" % count
		else:
			text += " (none)"

		if is_equipped:
			text += " [EQUIPPED]"
			label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4, 1))
		elif count > 0:
			label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1))
		else:
			label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))

		label.text = text


func _input(event: InputEvent) -> void:
	# Don't process input if not in tree (prevents null viewport errors during scene transitions)
	if not is_inside_tree():
		return

	# Toggle menu with I key or Create button
	if event.is_action_pressed("open_inventory"):
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

	# D-pad navigation
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


func toggle_menu() -> void:
	is_visible = not is_visible
	panel.visible = is_visible

	if is_visible:
		focused_slot_index = 0
		_update_display()
		_update_focus_highlight()


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
			_update_display()
