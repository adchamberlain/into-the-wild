extends CanvasLayer
## UI for the crafting system. Toggle with C key.

@export var player_path: NodePath

@onready var panel: PanelContainer = $Panel
@onready var recipe_list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/RecipeList
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel

var player: Node
var crafting_system: CraftingSystem
var is_open: bool = false

# Track recipe buttons for updates
var recipe_buttons: Dictionary = {}


func _ready() -> void:
	# Add to group for crafting bench to find us
	add_to_group("crafting_ui")

	# Start closed
	panel.visible = false
	is_open = false

	# Get player reference
	if player_path:
		player = get_node(player_path)

		# Create crafting system
		crafting_system = CraftingSystem.new()
		add_child(crafting_system)

		# Connect crafting system to player's inventory
		if player.has_method("get_inventory"):
			var inventory: Inventory = player.get_inventory()
			crafting_system.set_inventory(inventory)
			# Update UI when inventory changes
			inventory.inventory_changed.connect(_on_inventory_changed)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_C:
			_toggle_crafting()


func _toggle_crafting() -> void:
	toggle_crafting_menu()


## Public method to toggle crafting menu (called by crafting bench interaction).
func toggle_crafting_menu() -> void:
	is_open = not is_open
	panel.visible = is_open

	if is_open:
		# Show cursor for clicking
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_refresh_recipe_list()
	else:
		# Re-capture mouse for gameplay
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _refresh_recipe_list() -> void:
	# Clear existing buttons
	for child in recipe_list.get_children():
		child.queue_free()
	recipe_buttons.clear()

	if not crafting_system:
		return

	var recipes: Array[Dictionary] = crafting_system.get_all_recipes_status()

	for recipe: Dictionary in recipes:
		var recipe_id: String = recipe.get("id", "")
		var recipe_name: String = recipe.get("name", "Unknown")
		var can_craft: bool = recipe.get("can_craft", false)
		var inputs: Dictionary = recipe.get("inputs", {})
		var description: String = recipe.get("description", "")

		# Create recipe container
		var container: VBoxContainer = VBoxContainer.new()
		container.add_theme_constant_override("separation", 4)

		# Recipe button
		var button: Button = Button.new()
		button.text = recipe_name
		button.disabled = not can_craft
		button.add_theme_font_size_override("font_size", 36)
		button.pressed.connect(_on_craft_pressed.bind(recipe_id))
		container.add_child(button)
		recipe_buttons[recipe_id] = button

		# Ingredients label
		var ingredients_text: String = "  Requires: "
		var ingredient_parts: Array[String] = []
		for resource: String in inputs:
			var amount: int = inputs[resource]
			var display_name: String = resource.capitalize().replace("_", " ")
			ingredient_parts.append("%d %s" % [amount, display_name])
		ingredients_text += ", ".join(ingredient_parts)

		var ingredients_label: Label = Label.new()
		ingredients_label.text = ingredients_text
		ingredients_label.add_theme_font_size_override("font_size", 28)
		ingredients_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1) if can_craft else Color(0.5, 0.4, 0.4, 1))
		container.add_child(ingredients_label)

		# Description
		var desc_label: Label = Label.new()
		desc_label.text = "  " + description
		desc_label.add_theme_font_size_override("font_size", 26)
		desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
		container.add_child(desc_label)

		# Spacer
		var spacer: Control = Control.new()
		spacer.custom_minimum_size = Vector2(0, 10)
		container.add_child(spacer)

		recipe_list.add_child(container)


func _on_craft_pressed(recipe_id: String) -> void:
	if crafting_system and crafting_system.craft(recipe_id):
		_refresh_recipe_list()


func _on_inventory_changed() -> void:
	if is_open:
		_refresh_recipe_list()
