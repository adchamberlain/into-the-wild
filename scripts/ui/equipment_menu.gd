extends CanvasLayer
## Equipment menu showing available items and their hotkeys.

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
		label.add_theme_font_size_override("font_size", 28)
		item_list.add_child(label)
		slot_labels[slot["type"]] = label

	# Update display
	_update_display()


func _update_display() -> void:
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

		# Build display text
		var text: String = "[%s] %s" % [key, name]
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
	# Toggle menu with I key
	if event is InputEventKey and event.pressed:
		if event.physical_keycode == KEY_I:
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
