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
]

# Cached labels for each slot
var slot_labels: Dictionary = {}


func _ready() -> void:
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

	# Create a label for each slot
	for slot in EQUIPMENT_SLOTS:
		var label: Label = Label.new()
		label.add_theme_font_override("font", HUD_FONT)
		label.add_theme_font_size_override("font_size", 28)
		item_list.add_child(label)
		slot_labels[slot["type"]] = label

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
	# Toggle menu with I key or Create button
	if event.is_action_pressed("open_inventory"):
		toggle_menu()
		get_viewport().set_input_as_handled()
		return

	# Close menu with cancel action when open
	if is_visible and event.is_action_pressed("ui_cancel"):
		toggle_menu()
		get_viewport().set_input_as_handled()


func toggle_menu() -> void:
	is_visible = not is_visible
	panel.visible = is_visible

	if is_visible:
		_update_display()


func _on_inventory_changed() -> void:
	if is_visible:
		_update_display()


func _on_item_equipped(_item_type: String) -> void:
	if is_visible:
		_update_display()


func _on_item_unequipped(_item_type: String) -> void:
	if is_visible:
		_update_display()
