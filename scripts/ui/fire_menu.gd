extends CanvasLayer
## UI menu for fire pit interactions: Warm Up, Cook Food, Add Fuel.

signal action_selected(action: String)

@export var player_path: NodePath

var player: Node
var player_inventory: Inventory
var player_stats: Node
var current_fire: Node = null

# Cooking recipes: input -> {output, hunger_value}
const COOKING_RECIPES: Dictionary = {
	"berry": {"output": "cooked_berries", "hunger": 25},
	"mushroom": {"output": "cooked_mushroom", "hunger": 20},
	"fish": {"output": "cooked_fish", "hunger": 40},
}

# UI References
@onready var panel: PanelContainer = $Panel
@onready var warm_up_button: Button = $Panel/VBoxContainer/WarmUpButton
@onready var cook_button: Button = $Panel/VBoxContainer/CookButton
@onready var cook_label: Label = $Panel/VBoxContainer/CookLabel
@onready var add_fuel_button: Button = $Panel/VBoxContainer/AddFuelButton
@onready var fuel_label: Label = $Panel/VBoxContainer/FuelLabel
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

var is_open: bool = false


func _ready() -> void:
	add_to_group("fire_menu")

	# Get player reference
	if player_path:
		player = get_node_or_null(player_path)
		if player:
			if player.has_method("get_inventory"):
				player_inventory = player.get_inventory()
			if player.has_method("get_stats"):
				player_stats = player.get_stats()

	# Connect buttons
	if warm_up_button:
		warm_up_button.pressed.connect(_on_warm_up_pressed)
	if cook_button:
		cook_button.pressed.connect(_on_cook_pressed)
	if add_fuel_button:
		add_fuel_button.pressed.connect(_on_add_fuel_pressed)
	if close_button:
		close_button.pressed.connect(close_menu)

	# Start closed
	panel.visible = false
	is_open = false


func _input(event: InputEvent) -> void:
	if is_open and event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE or event.physical_keycode == KEY_E:
			close_menu()
			get_viewport().set_input_as_handled()


## Open the fire menu for a specific fire pit.
func open_menu(fire: Node) -> void:
	current_fire = fire
	is_open = true
	panel.visible = true

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	_refresh_menu()


## Close the fire menu.
func close_menu() -> void:
	is_open = false
	panel.visible = false
	current_fire = null

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


## Refresh menu state based on inventory.
func _refresh_menu() -> void:
	if not player_inventory:
		return

	# Check for cookable items
	var cookable_item: String = _get_cookable_item()
	if cookable_item != "":
		var recipe: Dictionary = COOKING_RECIPES[cookable_item]
		var count: int = player_inventory.get_item_count(cookable_item)
		cook_button.disabled = false
		cook_label.text = "Cook %s (%d available) → +%d hunger" % [cookable_item.capitalize(), count, recipe["hunger"]]
		cook_label.modulate = Color(1, 1, 1, 1)
	else:
		cook_button.disabled = true
		cook_label.text = "No cookable food (berries, mushrooms, fish)"
		cook_label.modulate = Color(0.6, 0.6, 0.6, 1)

	# Check for fuel (wood)
	var wood_count: int = player_inventory.get_item_count("wood")
	if wood_count > 0:
		add_fuel_button.disabled = false
		fuel_label.text = "Add 1 wood (%d available) - adds 1 day" % wood_count
		fuel_label.modulate = Color(1, 1, 1, 1)
	else:
		add_fuel_button.disabled = true
		fuel_label.text = "No wood to add as fuel"
		fuel_label.modulate = Color(0.6, 0.6, 0.6, 1)

	# Update fuel status display
	if current_fire and "fuel_remaining" in current_fire and "max_fuel" in current_fire:
		if current_fire.unlimited_fuel:
			fuel_label.text += " (Unlimited)"
		else:
			var days_remaining: float = current_fire.fuel_remaining / current_fire.max_fuel
			fuel_label.text += " (%.1f days left)" % days_remaining


## Get the first cookable item in player inventory.
func _get_cookable_item() -> String:
	if not player_inventory:
		return ""

	for item: String in COOKING_RECIPES:
		if player_inventory.has_item(item):
			return item

	return ""


func _on_warm_up_pressed() -> void:
	if not current_fire or not player_stats:
		return

	# Heal player
	if player_stats.has_method("heal"):
		player_stats.heal(15.0)

	# Visual flare effect
	if current_fire.has_method("flare"):
		current_fire.flare()

	# Show notification
	_show_notification("Warmed up! +15 Health", Color(1.0, 0.8, 0.4))

	action_selected.emit("warm_up")
	close_menu()


func _on_cook_pressed() -> void:
	if not current_fire or not player_inventory or not player_stats:
		return

	var cookable_item: String = _get_cookable_item()
	if cookable_item == "":
		return

	var recipe: Dictionary = COOKING_RECIPES[cookable_item]

	# Remove raw ingredient
	player_inventory.remove_item(cookable_item, 1)

	# Restore hunger directly (cooked food gives more)
	if player_stats.has_method("eat"):
		player_stats.eat(recipe["hunger"])

	# Visual flare effect
	if current_fire.has_method("flare"):
		current_fire.flare()

	# Show notification
	var output_name: String = recipe["output"].capitalize().replace("_", " ")
	_show_notification("Cooked %s! +%d Hunger" % [cookable_item.capitalize(), recipe["hunger"]], Color(1.0, 0.6, 0.2))

	action_selected.emit("cook")

	# Refresh menu to update counts
	_refresh_menu()


func _on_add_fuel_pressed() -> void:
	if not current_fire or not player_inventory:
		return

	if not player_inventory.has_item("wood"):
		return

	# Remove wood
	player_inventory.remove_item("wood", 1)

	# Add fuel to fire (1 day worth)
	if current_fire.has_method("add_fuel"):
		current_fire.add_fuel()

	# Visual flare effect
	if current_fire.has_method("flare"):
		current_fire.flare()

	# Show notification
	_show_notification("Added wood - fire burns 1 more day!", Color(1.0, 0.5, 0.2))

	action_selected.emit("add_fuel")

	# Refresh menu
	_refresh_menu()


func _show_notification(message: String, color: Color) -> void:
	var hud: Node = _find_hud()
	if hud and hud.has_method("show_notification"):
		hud.show_notification(message, color)


func _find_hud() -> Node:
	var root: Node = get_tree().root
	if root.has_node("Main/HUD"):
		return root.get_node("Main/HUD")
	return null
