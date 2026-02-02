extends CanvasLayer
## UI for the crafting system. Toggle with C key.

# Standard HUD font
const HUD_FONT: Font = preload("res://resources/hud_font.tres")

@export var player_path: NodePath
@export var campsite_manager_path: NodePath

@onready var panel: PanelContainer = $Panel
@onready var scroll_container: ScrollContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer
@onready var recipe_list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/RecipeList
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var hint_label: Label = $Panel/MarginContainer/VBoxContainer/HintLabel

var player: Node
var campsite_manager: Node
var crafting_system: CraftingSystem
var is_open: bool = false

# Track whether crafting menu was opened from a bench
var at_bench: bool = false

# Track recipe buttons for updates
var recipe_buttons: Dictionary = {}

# Track focused recipe for controller navigation
var focused_recipe_index: int = 0
var recipe_button_list: Array[Button] = []  # Ordered list for navigation


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

	# Get campsite manager reference
	if campsite_manager_path:
		campsite_manager = get_node_or_null(campsite_manager_path)
	if not campsite_manager and player:
		campsite_manager = player.get_parent().get_node_or_null("CampsiteManager")


func _input(event: InputEvent) -> void:
	# Handle crafting menu toggle (C key or Touchpad button)
	if event.is_action_pressed("open_crafting"):
		_toggle_crafting()
		return

	# Only handle other inputs when menu is open
	if not is_open:
		return

	# Close crafting menu with cancel action when open
	if event.is_action_pressed("ui_cancel"):
		toggle_crafting_menu(false)
		get_viewport().set_input_as_handled()
		return

	# D-pad navigation
	if event.is_action_pressed("ui_down"):
		_navigate_recipes(1)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_up"):
		_navigate_recipes(-1)
		get_viewport().set_input_as_handled()
		return

	# Cross button (ui_accept) to craft focused recipe
	if event.is_action_pressed("ui_accept"):
		_craft_focused_recipe()
		get_viewport().set_input_as_handled()
		return


func _toggle_crafting() -> void:
	# C key always opens without bench context
	toggle_crafting_menu(false)


## Public method to toggle crafting menu.
## from_bench: true if opened from crafting bench interaction.
func toggle_crafting_menu(from_bench: bool = false) -> void:
	is_open = not is_open
	panel.visible = is_open

	if is_open:
		at_bench = from_bench
		# Update title based on context
		if at_bench:
			title_label.text = "Crafting Bench"
		else:
			title_label.text = "Crafting"
		# Update hint label based on input device
		_update_hint_label()
		# Show cursor for clicking
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_refresh_recipe_list()
		# Focus first recipe button for controller navigation
		_focus_first_recipe()
	else:
		at_bench = false
		# Re-capture mouse for gameplay
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _refresh_recipe_list(preserve_focus: bool = false) -> void:
	# Save current focus index if preserving
	var saved_focus_index: int = focused_recipe_index

	# Clear existing buttons
	for child in recipe_list.get_children():
		child.queue_free()
	recipe_buttons.clear()
	recipe_button_list.clear()
	focused_recipe_index = 0 if not preserve_focus else saved_focus_index

	if not crafting_system:
		return

	# Get current campsite level
	var camp_level: int = 1
	if campsite_manager and campsite_manager.has_method("get_level"):
		camp_level = campsite_manager.get_level()

	var recipes: Array[Dictionary] = crafting_system.get_all_recipes_status(at_bench, camp_level)

	for recipe: Dictionary in recipes:
		var recipe_id: String = recipe.get("id", "")
		var recipe_name: String = recipe.get("name", "Unknown")
		var can_craft_recipe: bool = recipe.get("can_craft", false)
		var inputs: Dictionary = recipe.get("inputs", {})
		var description: String = recipe.get("description", "")
		var requires_bench: bool = recipe.get("requires_bench", false)

		# Skip advanced recipes entirely when not at bench - only show basic recipes
		if requires_bench and not at_bench:
			continue

		# Create outer panel for each recipe item with darker background
		var item_panel: PanelContainer = PanelContainer.new()
		var item_style: StyleBoxFlat = StyleBoxFlat.new()
		item_style.bg_color = Color(0.08, 0.08, 0.1, 0.9)
		item_style.corner_radius_top_left = 8
		item_style.corner_radius_top_right = 8
		item_style.corner_radius_bottom_left = 8
		item_style.corner_radius_bottom_right = 8
		item_style.content_margin_left = 12
		item_style.content_margin_right = 12
		item_style.content_margin_top = 10
		item_style.content_margin_bottom = 10
		item_panel.add_theme_stylebox_override("panel", item_style)

		# Create recipe container inside the panel
		var container: VBoxContainer = VBoxContainer.new()
		container.add_theme_constant_override("separation", 6)

		# Recipe button
		var button: Button = Button.new()
		button.text = recipe_name
		button.disabled = not can_craft_recipe
		button.add_theme_font_override("font", HUD_FONT)
		button.add_theme_font_size_override("font_size", 40)
		button.pressed.connect(_on_craft_pressed.bind(recipe_id))
		button.focus_mode = Control.FOCUS_ALL  # Allow focus for controller navigation
		container.add_child(button)
		recipe_buttons[recipe_id] = button
		recipe_button_list.append(button)

		# Ingredients label
		var ingredients_text: String = "Requires: "
		var ingredient_parts: Array[String] = []
		for resource: String in inputs:
			var amount: int = inputs[resource]
			var display_name: String = resource.capitalize().replace("_", " ")
			ingredient_parts.append("%d %s" % [amount, display_name])
		ingredients_text += ", ".join(ingredient_parts)

		var ingredients_label: Label = Label.new()
		ingredients_label.text = ingredients_text
		ingredients_label.add_theme_font_override("font", HUD_FONT)
		ingredients_label.add_theme_font_size_override("font_size", 30)
		ingredients_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1) if can_craft_recipe else Color(0.5, 0.4, 0.4, 1))
		container.add_child(ingredients_label)

		# Description
		var desc_label: Label = Label.new()
		desc_label.text = description
		desc_label.add_theme_font_override("font", HUD_FONT)
		desc_label.add_theme_font_size_override("font_size", 28)
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
		container.add_child(desc_label)

		item_panel.add_child(container)
		recipe_list.add_child(item_panel)

		# Spacer between items
		var spacer: Control = Control.new()
		spacer.custom_minimum_size = Vector2(0, 6)
		recipe_list.add_child(spacer)


func _on_craft_pressed(recipe_id: String) -> void:
	# Get current campsite level
	var camp_level: int = 1
	if campsite_manager and campsite_manager.has_method("get_level"):
		camp_level = campsite_manager.get_level()

	# Just call craft - the inventory_changed signal will trigger _on_inventory_changed
	# which handles refreshing the list and restoring focus
	crafting_system.craft(recipe_id, at_bench, camp_level)


func _on_inventory_changed() -> void:
	if is_open:
		_refresh_recipe_list(true)  # Preserve focus when inventory changes while menu is open
		_restore_focus()


## Focus the first recipe button (called when menu opens).
func _focus_first_recipe() -> void:
	# Use call_deferred since buttons were just created
	call_deferred("_do_focus_first_recipe")


func _do_focus_first_recipe() -> void:
	if not recipe_button_list.is_empty():
		focused_recipe_index = 0
		recipe_button_list[0].grab_focus()
		# Reset scroll to top when opening menu
		scroll_container.scroll_vertical = 0


## Restore focus to the previously focused recipe after refresh.
func _restore_focus() -> void:
	# Wait two frames to ensure buttons are fully created and old ones removed
	await get_tree().process_frame
	await get_tree().process_frame
	_do_restore_focus()


func _do_restore_focus() -> void:
	if recipe_button_list.is_empty():
		return

	# Clamp focus index to valid range (in case list got shorter)
	if focused_recipe_index >= recipe_button_list.size():
		focused_recipe_index = recipe_button_list.size() - 1
	if focused_recipe_index < 0:
		focused_recipe_index = 0

	var button: Button = recipe_button_list[focused_recipe_index]
	button.grab_focus()
	# Scroll to keep the focused item visible
	var item_panel: Control = button.get_parent().get_parent()
	scroll_container.ensure_control_visible(item_panel)


## Navigate through recipe list with D-pad.
func _navigate_recipes(direction: int) -> void:
	if recipe_button_list.is_empty():
		return

	focused_recipe_index = (focused_recipe_index + direction) % recipe_button_list.size()
	if focused_recipe_index < 0:
		focused_recipe_index = recipe_button_list.size() - 1

	# Focus the button and scroll it into view
	var button: Button = recipe_button_list[focused_recipe_index]
	button.grab_focus()
	# Manually scroll to the button's parent panel since button is nested
	var item_panel: Control = button.get_parent().get_parent()
	scroll_container.ensure_control_visible(item_panel)


## Craft the currently focused recipe.
func _craft_focused_recipe() -> void:
	if recipe_button_list.is_empty():
		return

	if focused_recipe_index >= 0 and focused_recipe_index < recipe_button_list.size():
		var button: Button = recipe_button_list[focused_recipe_index]
		if not button.disabled:
			# Emit the pressed signal to trigger crafting
			button.pressed.emit()


## Update hint label based on input device.
func _update_hint_label() -> void:
	if not hint_label:
		return
	var input_mgr: Node = get_node_or_null("/root/InputManager")
	if input_mgr and input_mgr.is_using_controller():
		hint_label.text = "Touchpad or ○ to close"
	else:
		hint_label.text = "Press C to close"


## Get the internal CraftingSystem for signal connections.
func get_crafting_system() -> CraftingSystem:
	return crafting_system
