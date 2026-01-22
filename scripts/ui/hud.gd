extends CanvasLayer
## Heads-up display showing time, stats, interaction prompts, inventory, equipment, and other info.

@export var time_manager_path: NodePath
@export var player_path: NodePath

# Time display
@onready var time_label: Label = $TimeContainer/TimeLabel
@onready var period_label: Label = $TimeContainer/PeriodLabel

# Interaction
@onready var interaction_prompt: Label = $InteractionPrompt

# Stats bars
@onready var health_bar: ProgressBar = $StatsContainer/HealthContainer/HealthBar
@onready var hunger_bar: ProgressBar = $StatsContainer/HungerContainer/HungerBar

# Inventory
@onready var inventory_panel: PanelContainer = $InventoryPanel
@onready var item_list: VBoxContainer = $InventoryPanel/VBoxContainer/ItemList
@onready var empty_label: Label = $InventoryPanel/VBoxContainer/ItemList/EmptyLabel

# Equipment
@onready var equipped_label: Label = $EquippedContainer/EquippedLabel

var time_manager: Node
var player: Node
var inventory: Node
var stats: Node
var equipment: Node

# Cache of item labels for quick updates
var item_labels: Dictionary = {}


func _ready() -> void:
	# Connect to time manager
	if time_manager_path:
		time_manager = get_node(time_manager_path)
		time_manager.time_changed.connect(_on_time_changed)
		time_manager.period_changed.connect(_on_period_changed)
		_update_time_display()

	# Connect to player for interaction prompts, inventory, stats, and equipment
	if player_path:
		player = get_node(player_path)
		if player.has_signal("interaction_target_changed"):
			player.interaction_target_changed.connect(_on_interaction_target_changed)
		if player.has_signal("interaction_cleared"):
			player.interaction_cleared.connect(_on_interaction_cleared)

		# Connect to player's inventory
		if player.has_method("get_inventory"):
			inventory = player.get_inventory()
			if inventory:
				inventory.inventory_changed.connect(_on_inventory_changed)

		# Connect to player's stats
		if player.has_method("get_stats"):
			stats = player.get_stats()
			if stats:
				stats.health_changed.connect(_on_health_changed)
				stats.hunger_changed.connect(_on_hunger_changed)
				# Initialize bars
				_update_health_bar(stats.health, stats.max_health)
				_update_hunger_bar(stats.hunger, stats.max_hunger)

		# Connect to player's equipment
		if player.has_method("get_equipment"):
			equipment = player.get_equipment()
			if equipment:
				equipment.item_equipped.connect(_on_item_equipped)
				equipment.item_unequipped.connect(_on_item_unequipped)

	# Hide interaction prompt initially
	if interaction_prompt:
		interaction_prompt.visible = false

	# Initialize displays
	_update_inventory_display()
	_update_equipped_display()


func _update_time_display() -> void:
	if time_manager:
		time_label.text = time_manager.get_time_string()
		period_label.text = time_manager.get_period_name()


func _on_time_changed(_hour: int, _minute: int) -> void:
	_update_time_display()


func _on_period_changed(period: String) -> void:
	period_label.text = period


func _on_interaction_target_changed(_target: Node, interaction_text: String) -> void:
	if interaction_prompt:
		interaction_prompt.text = "[E] " + interaction_text
		interaction_prompt.visible = true


func _on_interaction_cleared() -> void:
	if interaction_prompt:
		interaction_prompt.visible = false


func _on_health_changed(new_value: float, max_value: float) -> void:
	_update_health_bar(new_value, max_value)


func _on_hunger_changed(new_value: float, max_value: float) -> void:
	_update_hunger_bar(new_value, max_value)


func _update_health_bar(value: float, max_value: float) -> void:
	if health_bar:
		health_bar.max_value = max_value
		health_bar.value = value


func _update_hunger_bar(value: float, max_value: float) -> void:
	if hunger_bar:
		hunger_bar.max_value = max_value
		hunger_bar.value = value


func _on_item_equipped(item_type: String) -> void:
	_update_equipped_display()


func _on_item_unequipped(item_type: String) -> void:
	_update_equipped_display()


func _update_equipped_display() -> void:
	if not equipped_label:
		return

	if equipment and equipment.get_equipped() != "":
		var item_name: String = equipment.get_equipped_name()
		equipped_label.text = "Equipped: " + item_name

		# Add hint for placeable items
		if equipment.get_equipped() == "campfire_kit":
			equipped_label.text += " [R to place]"
	else:
		equipped_label.text = "Equipped: None"


func _on_inventory_changed() -> void:
	_update_inventory_display()


func _update_inventory_display() -> void:
	if not inventory or not item_list:
		return

	var items: Dictionary = inventory.get_all_items()

	# Show/hide empty label
	if empty_label:
		empty_label.visible = items.is_empty()

	# Track which items we've seen this update
	var seen_items: Array = []

	# Update or create labels for each item
	for resource_type: String in items:
		seen_items.append(resource_type)
		var count: int = items[resource_type]
		var display_name: String = resource_type.capitalize().replace("_", " ")

		if item_labels.has(resource_type):
			# Update existing label
			var label: Label = item_labels[resource_type]
			label.text = "%s: %d" % [display_name, count]
		else:
			# Create new label
			var label: Label = Label.new()
			label.text = "%s: %d" % [display_name, count]
			label.add_theme_font_size_override("font_size", 36)
			label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			item_list.add_child(label)
			item_labels[resource_type] = label

	# Remove labels for items no longer in inventory
	var to_remove: Array = []
	for resource_type: String in item_labels:
		if resource_type not in seen_items:
			to_remove.append(resource_type)

	for resource_type: String in to_remove:
		var label: Label = item_labels[resource_type]
		label.queue_free()
		item_labels.erase(resource_type)
