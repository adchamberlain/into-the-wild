extends CanvasLayer
## UI for transferring items between player inventory and storage containers.

# Standard HUD font
const HUD_FONT: Font = preload("res://resources/hud_font.tres")

@export var player_path: NodePath

var player: Node
var player_inventory: Inventory
var current_storage: Node = null  # The storage structure we're interacting with

# UI References
@onready var panel: PanelContainer = $Panel
@onready var player_scroll: ScrollContainer = $Panel/MarginContainer/VBoxContainer/HBoxContainer/PlayerPanel/VBoxContainer/ScrollContainer
@onready var storage_scroll: ScrollContainer = $Panel/MarginContainer/VBoxContainer/HBoxContainer/StoragePanel/VBoxContainer/ScrollContainer
@onready var player_items_list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/HBoxContainer/PlayerPanel/VBoxContainer/ScrollContainer/PlayerItemsList
@onready var storage_items_list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/HBoxContainer/StoragePanel/VBoxContainer/ScrollContainer/StorageItemsList
@onready var player_empty_label: Label = $Panel/MarginContainer/VBoxContainer/HBoxContainer/PlayerPanel/VBoxContainer/ScrollContainer/PlayerItemsList/EmptyLabel
@onready var storage_empty_label: Label = $Panel/MarginContainer/VBoxContainer/HBoxContainer/StoragePanel/VBoxContainer/ScrollContainer/StorageItemsList/EmptyLabel
@onready var hint_label: Label = $Panel/MarginContainer/VBoxContainer/HintLabel

var is_open: bool = false

# Controller navigation - 2D grid: rows of [transfer_button, all_button]
var focused_panel: int = 0  # 0 = player, 1 = storage
var focused_row_index: int = 0
var focused_col_index: int = 0  # 0 = transfer button, 1 = all button
var player_button_rows: Array = []  # Array of [Button, Button] pairs
var storage_button_rows: Array = []

# Cooldown to prevent L2 from immediately closing menu after opening
const OPEN_COOLDOWN: float = 0.3
var open_cooldown_timer: float = 0.0


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


func _process(delta: float) -> void:
	if open_cooldown_timer > 0:
		open_cooldown_timer -= delta


func _input(event: InputEvent) -> void:
	# Don't process input if not in tree (prevents null viewport errors during scene transitions)
	if not is_inside_tree():
		return

	if not is_open:
		return

	# Close with Escape or E when open
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE or event.physical_keycode == KEY_E:
			close_storage()
			_handle_input()
			return

	# Close with interact action (L2 on controller) - but not immediately after opening
	if event.is_action_pressed("interact") and open_cooldown_timer <= 0:
		close_storage()
		_handle_input()
		return

	# Controller cancel to close
	if event.is_action_pressed("ui_cancel"):
		close_storage()
		_handle_input()
		return

	# D-pad up/down to navigate items
	if event.is_action_pressed("ui_down"):
		_navigate_items(1)
		_handle_input()
		return
	if event.is_action_pressed("ui_up"):
		_navigate_items(-1)
		_handle_input()
		return

	# D-pad left/right to navigate within row or switch panels
	if event.is_action_pressed("ui_left"):
		_navigate_horizontal(-1)
		_handle_input()
		return
	if event.is_action_pressed("ui_right"):
		_navigate_horizontal(1)
		_handle_input()
		return

	# Cross button to transfer focused item
	if event.is_action_pressed("ui_accept"):
		_transfer_focused_item()
		_handle_input()
		return


func _handle_input() -> void:
	var vp: Viewport = get_viewport()
	if vp:
		vp.set_input_as_handled()


## Open storage UI for a specific storage container.
func open_storage(storage: Node) -> void:
	if not storage or not storage.has_method("get_all_items"):
		return

	current_storage = storage
	is_open = true
	panel.visible = true

	# Set cooldown to prevent L2 from immediately closing
	open_cooldown_timer = OPEN_COOLDOWN

	# Reset controller navigation state
	focused_panel = 0
	focused_row_index = 0
	focused_col_index = 0

	# Show cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Connect to storage inventory changes
	if storage.storage_inventory and not storage.storage_inventory.inventory_changed.is_connected(_refresh_lists):
		storage.storage_inventory.inventory_changed.connect(_refresh_lists)

	# Connect to player inventory changes
	if player_inventory and not player_inventory.inventory_changed.is_connected(_refresh_lists):
		player_inventory.inventory_changed.connect(_refresh_lists)

	_refresh_lists()
	_update_focus_highlight()
	_update_hint_label()
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
	player_button_rows.clear()

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
	storage_button_rows.clear()

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
	label.add_theme_font_override("font", HUD_FONT)
	label.add_theme_font_size_override("font_size", 28)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(label)

	# Transfer button (move one)
	var button: Button = Button.new()
	button.text = ">>" if is_player_item else "<<"
	button.add_theme_font_override("font", HUD_FONT)
	button.add_theme_font_size_override("font_size", 24)
	button.tooltip_text = "Move to Storage" if is_player_item else "Take from Storage"
	button.pressed.connect(_on_transfer_pressed.bind(item_type, is_player_item))
	button.focus_mode = Control.FOCUS_ALL
	container.add_child(button)

	# Transfer all button
	var all_button: Button = Button.new()
	all_button.text = "All"
	all_button.add_theme_font_override("font", HUD_FONT)
	all_button.add_theme_font_size_override("font_size", 20)
	all_button.tooltip_text = "Move all to Storage" if is_player_item else "Take all from Storage"
	all_button.pressed.connect(_on_transfer_all_pressed.bind(item_type, is_player_item))
	all_button.focus_mode = Control.FOCUS_ALL
	container.add_child(all_button)

	# Track both buttons as a row for controller navigation
	var button_row: Array[Button] = [button, all_button]
	if is_player_item:
		player_button_rows.append(button_row)
	else:
		storage_button_rows.append(button_row)

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


## Navigate items with D-pad up/down.
func _navigate_items(direction: int) -> void:
	var current_rows: Array = player_button_rows if focused_panel == 0 else storage_button_rows
	if current_rows.is_empty():
		return

	focused_row_index = (focused_row_index + direction) % current_rows.size()
	if focused_row_index < 0:
		focused_row_index = current_rows.size() - 1

	_update_focus_highlight()


## Navigate horizontally within a row, or switch panels at edges.
func _navigate_horizontal(direction: int) -> void:
	var current_rows: Array = player_button_rows if focused_panel == 0 else storage_button_rows

	# Calculate new column
	var new_col: int = focused_col_index + direction

	if new_col < 0:
		# At left edge - switch to player panel if on storage, or stay put
		if focused_panel == 1:
			focused_panel = 0
			focused_col_index = 1  # Start at rightmost column of player panel
			focused_row_index = mini(focused_row_index, player_button_rows.size() - 1)
			if focused_row_index < 0:
				focused_row_index = 0
		# else: already on player panel, stay at column 0
	elif new_col > 1:
		# At right edge - switch to storage panel if on player, or stay put
		if focused_panel == 0:
			focused_panel = 1
			focused_col_index = 0  # Start at leftmost column of storage panel
			focused_row_index = mini(focused_row_index, storage_button_rows.size() - 1)
			if focused_row_index < 0:
				focused_row_index = 0
		# else: already on storage panel, stay at column 1
	else:
		# Normal movement within row
		focused_col_index = new_col

	_update_focus_highlight()


## Update visual focus on the current button.
func _update_focus_highlight() -> void:
	var current_rows: Array = player_button_rows if focused_panel == 0 else storage_button_rows
	if current_rows.is_empty():
		return

	# Clamp row index to valid range
	if focused_row_index >= current_rows.size():
		focused_row_index = current_rows.size() - 1
	if focused_row_index < 0:
		focused_row_index = 0

	# Clamp column index
	if focused_col_index < 0:
		focused_col_index = 0
	if focused_col_index > 1:
		focused_col_index = 1

	# Get the button at current position
	var row: Array = current_rows[focused_row_index]
	if focused_col_index < row.size():
		var button: Button = row[focused_col_index]
		button.grab_focus()
		# Scroll the button's container into view
		var scroll: ScrollContainer = player_scroll if focused_panel == 0 else storage_scroll
		var item_container: Control = button.get_parent()  # The HBoxContainer holding the button
		scroll.ensure_control_visible(item_container)


## Transfer the focused item.
func _transfer_focused_item() -> void:
	var current_rows: Array = player_button_rows if focused_panel == 0 else storage_button_rows
	if current_rows.is_empty():
		return

	if focused_row_index >= 0 and focused_row_index < current_rows.size():
		var row: Array = current_rows[focused_row_index]
		if focused_col_index < row.size():
			row[focused_col_index].pressed.emit()


## Update hint label based on input device.
func _update_hint_label() -> void:
	if not hint_label:
		return
	var input_mgr: Node = get_node_or_null("/root/InputManager")
	if input_mgr and input_mgr.is_using_controller():
		hint_label.text = "D-pad: ↑↓ items, ←→ One/All. ✕ transfer. ○ close."
	else:
		hint_label.text = "Click >> to move items to storage, << to take items. Press E or Escape to close."
