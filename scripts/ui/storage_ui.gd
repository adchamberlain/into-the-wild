extends CanvasLayer
## UI for transferring items between player inventory and storage containers.

@export var player_path: NodePath

var player: Node
var player_inventory: Inventory
var current_storage: Node = null  # The storage structure we're interacting with

# UI References
@onready var panel: PanelContainer = $Panel
@onready var player_items_list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/HBoxContainer/PlayerPanel/VBoxContainer/ScrollContainer/PlayerItemsList
@onready var storage_items_list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/HBoxContainer/StoragePanel/VBoxContainer/ScrollContainer/StorageItemsList
@onready var player_empty_label: Label = $Panel/MarginContainer/VBoxContainer/HBoxContainer/PlayerPanel/VBoxContainer/ScrollContainer/PlayerItemsList/EmptyLabel
@onready var storage_empty_label: Label = $Panel/MarginContainer/VBoxContainer/HBoxContainer/StoragePanel/VBoxContainer/ScrollContainer/StorageItemsList/EmptyLabel

var is_open: bool = false


func _ready() -> void:
	# Add to group for easy lookup
	add_to_group("storage_ui")

	# Get player reference
	if player_path:
		player = get_node_or_null(player_path)
		if player and player.has_method("get_inventory"):
			player_inventory = player.get_inventory()

	# Start closed
	panel.visible = false
	is_open = false


func _input(event: InputEvent) -> void:
	# Close with Escape or E when open
	if is_open and event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE or event.physical_keycode == KEY_E:
			close_storage()
			get_viewport().set_input_as_handled()


## Open storage UI for a specific storage container.
func open_storage(storage: Node) -> void:
	if not storage or not storage.has_method("get_all_items"):
		return

	current_storage = storage
	is_open = true
	panel.visible = true

	# Show cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Connect to storage inventory changes
	if storage.storage_inventory and not storage.storage_inventory.inventory_changed.is_connected(_refresh_lists):
		storage.storage_inventory.inventory_changed.connect(_refresh_lists)

	# Connect to player inventory changes
	if player_inventory and not player_inventory.inventory_changed.is_connected(_refresh_lists):
		player_inventory.inventory_changed.connect(_refresh_lists)

	_refresh_lists()
	print("[StorageUI] Opened storage")


## Close the storage UI.
func close_storage() -> void:
	is_open = false
	panel.visible = false

	# Re-capture mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Disconnect signals
	if current_storage and current_storage.storage_inventory:
		if current_storage.storage_inventory.inventory_changed.is_connected(_refresh_lists):
			current_storage.storage_inventory.inventory_changed.disconnect(_refresh_lists)

	# Close the storage structure too
	if current_storage and current_storage.has_method("close_storage"):
		current_storage.is_open = false

	current_storage = null
	print("[StorageUI] Closed storage")


## Refresh both item lists.
func _refresh_lists() -> void:
	_refresh_player_list()
	_refresh_storage_list()


## Refresh the player inventory list.
func _refresh_player_list() -> void:
	# Clear existing items (except empty label)
	for child in player_items_list.get_children():
		if child != player_empty_label:
			child.queue_free()

	if not player_inventory:
		player_empty_label.visible = true
		return

	var items: Dictionary = player_inventory.get_all_items()
	player_empty_label.visible = items.is_empty()

	for item_type: String in items:
		var count: int = items[item_type]
		_create_item_button(player_items_list, item_type, count, true)


## Refresh the storage inventory list.
func _refresh_storage_list() -> void:
	# Clear existing items (except empty label)
	for child in storage_items_list.get_children():
		if child != storage_empty_label:
			child.queue_free()

	if not current_storage:
		storage_empty_label.visible = true
		return

	var items: Dictionary = current_storage.get_all_items()
	storage_empty_label.visible = items.is_empty()

	for item_type: String in items:
		var count: int = items[item_type]
		_create_item_button(storage_items_list, item_type, count, false)


## Create a button for an item that transfers it when clicked.
func _create_item_button(parent: VBoxContainer, item_type: String, count: int, is_player_item: bool) -> void:
	var container: HBoxContainer = HBoxContainer.new()
	container.add_theme_constant_override("separation", 10)

	var display_name: String = item_type.capitalize().replace("_", " ")

	# Item label
	var label: Label = Label.new()
	label.text = "%s x%d" % [display_name, count]
	label.add_theme_font_size_override("font_size", 28)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(label)

	# Transfer button
	var button: Button = Button.new()
	button.text = ">>" if is_player_item else "<<"
	button.add_theme_font_size_override("font_size", 24)
	button.tooltip_text = "Move to Storage" if is_player_item else "Take from Storage"
	button.pressed.connect(_on_transfer_pressed.bind(item_type, is_player_item))
	container.add_child(button)

	# Transfer all button
	var all_button: Button = Button.new()
	all_button.text = "All"
	all_button.add_theme_font_size_override("font_size", 20)
	all_button.tooltip_text = "Move all to Storage" if is_player_item else "Take all from Storage"
	all_button.pressed.connect(_on_transfer_all_pressed.bind(item_type, is_player_item))
	container.add_child(all_button)

	parent.add_child(container)


## Transfer one item.
func _on_transfer_pressed(item_type: String, from_player: bool) -> void:
	if from_player:
		# Player -> Storage
		if player_inventory and player_inventory.has_item(item_type) and current_storage:
			player_inventory.remove_item(item_type, 1)
			current_storage.add_item(item_type, 1)
	else:
		# Storage -> Player
		if current_storage and current_storage.has_item(item_type) and player_inventory:
			current_storage.remove_item(item_type, 1)
			player_inventory.add_item(item_type, 1)


## Transfer all of an item type.
func _on_transfer_all_pressed(item_type: String, from_player: bool) -> void:
	if from_player:
		# Player -> Storage
		if player_inventory and current_storage:
			var count: int = player_inventory.get_item_count(item_type)
			if count > 0:
				player_inventory.remove_item(item_type, count)
				current_storage.add_item(item_type, count)
	else:
		# Storage -> Player
		if current_storage and player_inventory:
			var count: int = current_storage.storage_inventory.get_item_count(item_type)
			if count > 0:
				current_storage.remove_item(item_type, count)
				player_inventory.add_item(item_type, count)
