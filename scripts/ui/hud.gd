extends CanvasLayer
## Heads-up display showing time, stats, interaction prompts, inventory, equipment, and other info.

# Preload the HUD font
const HUD_FONT: Font = preload("res://resources/hud_font.tres")

@export var time_manager_path: NodePath
@export var player_path: NodePath
@export var campsite_manager_path: NodePath
@export var weather_manager_path: NodePath
@export var save_load_path: NodePath

# Time display
@onready var time_label: Label = $TimePanel/TimeContainer/TimeLabel
@onready var period_label: Label = $TimePanel/TimeContainer/PeriodLabel
@onready var campsite_level_label: Label = $TimePanel/TimeContainer/CampsiteLevelLabel
@onready var weather_label: Label = $TimePanel/TimeContainer/WeatherLabel
@onready var protection_label: Label = $TimePanel/TimeContainer/ProtectionLabel

# Interaction
@onready var interaction_prompt_panel: PanelContainer = $InteractionPromptPanel
@onready var interaction_prompt: Label = $InteractionPromptPanel/InteractionPrompt

# Stats bars
@onready var health_bar: ProgressBar = $StatsPanel/StatsContainer/HealthContainer/HealthBar
@onready var hunger_bar: ProgressBar = $StatsPanel/StatsContainer/HungerContainer/HungerBar

# Inventory
@onready var inventory_panel: PanelContainer = $InventoryPanel
@onready var item_list: VBoxContainer = $InventoryPanel/VBoxContainer/ItemList
@onready var empty_label: Label = $InventoryPanel/VBoxContainer/ItemList/EmptyLabel

# Equipment
@onready var equipped_label: Label = $EquippedPanel/EquippedContainer/EquippedLabel
@onready var durability_bar: ProgressBar = $EquippedPanel/EquippedContainer/DurabilityBar
@onready var equip_hint_label: Label = $EquippedPanel/EquippedContainer/EquipHintLabel

# Notification
@onready var notification_panel: PanelContainer = $NotificationPanel
@onready var notification_label: Label = $NotificationPanel/NotificationLabel

# Screen fade overlay
@onready var fade_overlay: ColorRect = $FadeOverlay

# Coordinates display
@onready var coordinates_label: Label = $StatsPanel/StatsContainer/CoordinatesLabel

# Celebration UI
@onready var celebration_overlay: ColorRect = $CelebrationOverlay
@onready var celebration_panel: PanelContainer = $CelebrationPanel
@onready var celebration_title: Label = $CelebrationPanel/CelebrationVBox/CelebrationTitle
@onready var celebration_level_name: Label = $CelebrationPanel/CelebrationVBox/CelebrationLevelName
@onready var celebration_description: Label = $CelebrationPanel/CelebrationVBox/CelebrationDescription
@onready var celebration_unlocks: Label = $CelebrationPanel/CelebrationVBox/CelebrationUnlocks
@onready var celebration_prompt: Label = $CelebrationPanel/CelebrationVBox/CelebrationPrompt

# Config for coordinates visibility
var show_coordinates: bool = true

# Celebration state
var is_celebrating: bool = false
var celebration_tween: Tween = null

var time_manager: Node
var player: Node
var inventory: Node
var stats: Node
var equipment: Node
var campsite_manager: Node
var weather_manager: Node
var save_load: Node
var input_manager: Node
var placement_system: Node

# Resting state tracking
var is_player_resting: bool = false

# Weather damage flash
var weather_damage_flash_timer: float = 0.0
var last_player_health: float = 100.0

# Cache of item labels for quick updates
var item_labels: Dictionary = {}

# Performance: throttle expensive updates
const HUD_UPDATE_INTERVAL: float = 0.1  # Update coordinates/protection every 100ms
var hud_update_timer: float = 0.0


func _ready() -> void:
	# Connect to time manager
	if time_manager_path:
		time_manager = get_node(time_manager_path)
		time_manager.time_changed.connect(_on_time_changed)
		time_manager.period_changed.connect(_on_period_changed)
		if time_manager.has_signal("day_changed"):
			time_manager.day_changed.connect(_on_day_changed)
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
			print("[HUD] Got inventory from player: %s" % inventory)
			if inventory:
				inventory.inventory_changed.connect(_on_inventory_changed)
				print("[HUD] Connected to inventory.inventory_changed signal")

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
				equipment.durability_changed.connect(_on_durability_changed)
				equipment.tool_broken.connect(_on_tool_broken)

	# Connect to campsite manager
	if campsite_manager_path:
		campsite_manager = get_node_or_null(campsite_manager_path)
	if not campsite_manager and player:
		# Try to find campsite manager as sibling of player
		campsite_manager = player.get_parent().get_node_or_null("CampsiteManager")
	if campsite_manager:
		if campsite_manager.has_signal("campsite_level_changed"):
			campsite_manager.campsite_level_changed.connect(_on_campsite_level_changed)
		_update_campsite_level_display()

	# Connect to weather manager
	if weather_manager_path:
		weather_manager = get_node_or_null(weather_manager_path)
	if not weather_manager and player:
		weather_manager = player.get_parent().get_node_or_null("WeatherManager")
	if weather_manager:
		if weather_manager.has_signal("weather_changed"):
			weather_manager.weather_changed.connect(_on_weather_changed)
		_update_weather_display()

	# Connect to save/load system
	if save_load_path:
		save_load = get_node_or_null(save_load_path)
	if not save_load and player:
		save_load = player.get_parent().get_node_or_null("SaveLoad")
	if save_load:
		save_load.game_saved.connect(_on_game_saved)
		save_load.game_loaded.connect(_on_game_loaded)

	# Connect to input manager for dynamic button prompts
	input_manager = get_node_or_null("/root/InputManager")
	if input_manager:
		input_manager.input_device_changed.connect(_on_input_device_changed)

	# Connect to placement system for placement/move mode prompts
	call_deferred("_connect_to_placement_system")

	# Hide interaction prompt initially
	if interaction_prompt_panel:
		interaction_prompt_panel.visible = false

	# Hide notification panel initially
	if notification_panel:
		notification_panel.visible = false

	# Initialize displays
	_update_inventory_display()
	_update_equipped_display()
	_update_campsite_level_display()
	_update_weather_display()


func _update_time_display() -> void:
	if time_manager:
		time_label.text = time_manager.get_time_string()
		period_label.text = time_manager.get_period_name()


func _on_time_changed(_hour: int, _minute: int) -> void:
	_update_time_display()


func _on_period_changed(period: String) -> void:
	period_label.text = period


func _on_day_changed(_day: int) -> void:
	# Update campsite level display to show new day progress
	_update_campsite_level_display()


func _on_interaction_target_changed(target: Node, interaction_text: String) -> void:
	# Hide prompt if interaction text is empty
	if interaction_text.is_empty():
		if interaction_prompt_panel:
			interaction_prompt_panel.visible = false
		return

	if interaction_prompt:
		var prompt_text: String = _get_interact_prompt() + " " + interaction_text
		# Add move hint if target is a structure
		if target and target.is_in_group("structure"):
			var move_key: String = _get_button_prompt("move_structure")
			prompt_text += "  [%s] Move" % move_key
		interaction_prompt.text = prompt_text
	if interaction_prompt_panel:
		interaction_prompt_panel.visible = true


## Get the interact button prompt based on current input device.
func _get_interact_prompt() -> String:
	if input_manager and input_manager.has_method("get_prompt"):
		return "[%s]" % input_manager.get_prompt("interact")
	return "[E]"


## Called when input device changes between keyboard/mouse and controller.
func _on_input_device_changed(_is_controller: bool) -> void:
	# Update any visible prompts
	_update_equipped_display()
	_update_resting_prompt()


func _on_interaction_cleared() -> void:
	if interaction_prompt_panel:
		interaction_prompt_panel.visible = false


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

		# Add usage hint based on item type and input device
		var equipped_type: String = equipment.get_equipped()
		var use_key: String = _get_button_prompt("use_equipped")
		var unequip_key: String = _get_button_prompt("unequip")

		if StructureData.is_placeable_item(equipped_type):
			equipped_label.text += " [%s place, %s unequip]" % [use_key, unequip_key]
		elif equipped_type == "fishing_rod":
			# Fishing is done by interacting with fishing spots, not use_equipped
			var interact_key: String = _get_button_prompt("interact")
			equipped_label.text += " [%s fish, %s unequip]" % [interact_key, unequip_key]
		else:
			equipped_label.text += " [%s unequip]" % unequip_key

		# Update durability bar
		_update_durability_bar()
	else:
		equipped_label.text = "Equipped: None"
		# Hide durability bar when nothing equipped
		if durability_bar:
			durability_bar.visible = false

	# Update control hints based on input device
	_update_control_hints()


## Update the control hints label based on current input device.
func _update_control_hints() -> void:
	if not equip_hint_label:
		return

	var using_controller: bool = input_manager and input_manager.is_using_controller()

	if using_controller:
		# Controller prompts (Share=left button, Pad=touchpad, Menu=right button)
		equip_hint_label.text = "Share-Equip  Pad-Craft  Menu-Pause"
	else:
		# Keyboard prompts
		equip_hint_label.text = "I-Equip C-Craft Tab-Config K-Save L-Load"


## Get button prompt for an action based on current input device.
func _get_button_prompt(action: String) -> String:
	if input_manager and input_manager.has_method("get_prompt"):
		return input_manager.get_prompt(action)
	# Fallback to keyboard defaults
	match action:
		"use_equipped": return "R"
		"unequip": return "Q"
		"interact": return "E"
		"eat": return "F"
		_: return "?"


func _update_durability_bar() -> void:
	if not durability_bar or not equipment:
		return

	var current: int = equipment.get_equipped_durability()
	var max_dur: int = equipment.get_equipped_max_durability()

	if current < 0 or max_dur < 0:
		# No durability for this item
		durability_bar.visible = false
	else:
		durability_bar.visible = true
		durability_bar.max_value = max_dur
		durability_bar.value = current


func _on_durability_changed(item_type: String, current: int, max_durability: int) -> void:
	_update_durability_bar()


func _on_tool_broken(item_type: String) -> void:
	var display_name: String = item_type.capitalize().replace("_", " ")
	show_notification("%s broke!" % display_name, Color(1.0, 0.4, 0.4))
	_update_equipped_display()


func _on_inventory_changed() -> void:
	print("[HUD] Inventory changed signal received, updating display")
	_update_inventory_display()


func _update_inventory_display() -> void:
	if not inventory or not item_list:
		print("[HUD] Cannot update inventory display: inventory=%s, item_list=%s" % [inventory, item_list])
		return

	var items: Dictionary = inventory.get_all_items()
	print("[HUD] Updating inventory display with items: %s" % items)

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
			label.add_theme_font_override("font", HUD_FONT)
			label.add_theme_font_size_override("font_size", 40)
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


func _on_campsite_level_changed(new_level: int) -> void:
	_update_campsite_level_display()
	_show_level_celebration(new_level)


func _update_campsite_level_display() -> void:
	if not campsite_level_label:
		return

	if campsite_manager:
		var level: int = campsite_manager.get_level()
		var description: String = campsite_manager.get_level_description()
		var display_text: String = "Camp Lvl %d: %s" % [level, description]

		# Show day progress when at level 2
		if level == 2 and "days_at_level_2" in campsite_manager:
			var days: int = campsite_manager.days_at_level_2
			display_text += " (Day %d/3)" % min(days + 1, 3)

		campsite_level_label.text = display_text
	else:
		campsite_level_label.text = "Camp Lvl 1"


func _update_coordinates_display() -> void:
	if not coordinates_label:
		return

	coordinates_label.visible = show_coordinates

	if show_coordinates and player:
		var pos: Vector3 = player.global_position
		coordinates_label.text = "X: %.1f  Y: %.1f  Z: %.1f" % [pos.x, pos.y, pos.z]


func _process(delta: float) -> void:
	# Throttle expensive HUD updates (coordinates, protection status)
	hud_update_timer += delta
	if hud_update_timer >= HUD_UPDATE_INTERVAL:
		hud_update_timer = 0.0
		_update_coordinates_display()
		_update_protection_display()

	# Handle weather damage flash
	if weather_damage_flash_timer > 0:
		weather_damage_flash_timer -= delta
		if weather_damage_flash_timer <= 0:
			_reset_damage_flash()

	# Check for weather damage (health decreased)
	if stats:
		if stats.health < last_player_health:
			# Player took damage, check if from weather
			if weather_manager and weather_manager.is_dangerous_weather() and not weather_manager.is_player_protected():
				_trigger_damage_flash()
		last_player_health = stats.health

	# Check if player is resting and show prompt
	_update_resting_prompt()


func _on_weather_changed(weather_type: String) -> void:
	_update_weather_display()


func _update_weather_display() -> void:
	if not weather_label:
		return

	if weather_manager:
		var weather_name: String = weather_manager.get_weather_name()
		var is_dangerous: bool = weather_manager.is_dangerous_weather()

		weather_label.text = "Weather: " + weather_name

		# Color code dangerous weather
		if is_dangerous:
			weather_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.4, 1))
		else:
			weather_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0, 1))
	else:
		weather_label.text = "Weather: Clear"


func _update_protection_display() -> void:
	if not protection_label:
		return

	if weather_manager:
		var status: String = weather_manager.get_protection_status()
		var is_protected: bool = weather_manager.is_player_protected()
		var is_dangerous: bool = weather_manager.is_dangerous_weather()

		protection_label.text = status

		# Color based on danger level
		if is_dangerous and not is_protected:
			protection_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1))
		elif is_protected:
			protection_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4, 1))
		else:
			protection_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	else:
		protection_label.text = ""


func _trigger_damage_flash() -> void:
	weather_damage_flash_timer = 0.3
	if protection_label:
		protection_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0, 1))


func _reset_damage_flash() -> void:
	_update_protection_display()


## Show a notification message.
func show_notification(message: String, color: Color = Color.WHITE) -> void:
	if notification_label and notification_panel:
		notification_label.text = message
		notification_label.add_theme_color_override("font_color", color)
		notification_panel.visible = true
		# Hide after 3 seconds
		get_tree().create_timer(3.0).timeout.connect(func(): notification_panel.visible = false)


func _on_game_saved(_filepath: String, slot: int) -> void:
	show_notification("Saved to Slot %d!" % slot, Color(0.4, 1.0, 0.4, 1))


func _on_game_loaded(_filepath: String, slot: int) -> void:
	show_notification("Loaded Slot %d!" % slot, Color(0.4, 1.0, 0.4, 1))
	# Update campsite level display (without showing celebration)
	_update_campsite_level_display()


func _connect_to_placement_system() -> void:
	if player:
		placement_system = player.get_node_or_null("PlacementSystem")
		if placement_system:
			placement_system.placement_started.connect(_on_placement_started)
			placement_system.placement_confirmed.connect(_on_placement_ended)
			placement_system.placement_cancelled.connect(_on_placement_ended)
			placement_system.structure_move_started.connect(_on_move_started)
			placement_system.structure_move_confirmed.connect(_on_move_ended)
			placement_system.structure_move_cancelled.connect(_on_move_ended)


func _on_placement_started(_structure_type: String) -> void:
	_show_placement_prompt(false)


func _on_placement_ended(_arg1 = null, _arg2 = null) -> void:
	_hide_placement_prompt()


func _on_move_started(_structure: Node3D) -> void:
	_show_placement_prompt(true)


func _on_move_ended(_arg1 = null, _arg2 = null, _arg3 = null) -> void:
	_hide_placement_prompt()


func _show_placement_prompt(is_move: bool) -> void:
	if not interaction_prompt or not interaction_prompt_panel:
		return

	var confirm_key: String = _get_button_prompt("use_equipped")
	var cancel_key: String = _get_button_prompt("unequip")

	if is_move:
		interaction_prompt.text = "[%s] Confirm Move  [%s] Cancel" % [confirm_key, cancel_key]
	else:
		interaction_prompt.text = "[%s] Place  [%s] Cancel" % [confirm_key, cancel_key]

	interaction_prompt_panel.visible = true


func _hide_placement_prompt() -> void:
	if interaction_prompt_panel:
		interaction_prompt_panel.visible = false


func _update_resting_prompt() -> void:
	if not player or not interaction_prompt:
		return

	# Check if player is resting
	var player_resting: bool = false
	if "is_resting" in player:
		player_resting = player.is_resting

	if player_resting and not is_player_resting:
		# Just started resting - show get up prompt
		if interaction_prompt:
			interaction_prompt.text = "%s Get Up" % _get_interact_prompt()
		if interaction_prompt_panel:
			interaction_prompt_panel.visible = true
		is_player_resting = true
	elif not player_resting and is_player_resting:
		# Just stopped resting - hide prompt (will be updated by normal interaction system)
		if interaction_prompt_panel:
			interaction_prompt_panel.visible = false
		is_player_resting = false


## Show level-up celebration UI.
func _show_level_celebration(level: int) -> void:
	if not celebration_overlay or not celebration_panel:
		print("[HUD] Celebration UI not found")
		return

	# Get level info from campsite manager
	var level_info: Dictionary = {}
	if campsite_manager and campsite_manager.has_method("get_level_info"):
		level_info = campsite_manager.get_level_info(level)

	var level_name: String = level_info.get("name", "Level %d" % level)
	var description: String = level_info.get("description", "")
	var unlocks: Array = level_info.get("unlocks", [])

	# Set celebration text
	if celebration_title:
		celebration_title.text = "CAMP LEVEL UP!"
	if celebration_level_name:
		celebration_level_name.text = "Level %d: %s" % [level, level_name]
	if celebration_description:
		celebration_description.text = description
	if celebration_unlocks:
		if unlocks.size() > 0:
			var unlocks_text: String = "New structures unlocked:\n"
			for unlock: String in unlocks:
				unlocks_text += "  - %s\n" % unlock
			celebration_unlocks.text = unlocks_text.strip_edges()
			celebration_unlocks.visible = true
		else:
			celebration_unlocks.visible = false
	if celebration_prompt:
		var using_controller: bool = input_manager and input_manager.is_using_controller()
		if using_controller:
			celebration_prompt.text = "[Press any button to continue]"
		else:
			celebration_prompt.text = "[Press any key to continue]"

	# Show celebration UI with animation
	is_celebrating = true
	celebration_overlay.visible = true
	celebration_panel.visible = true
	celebration_overlay.color = Color(0, 0, 0, 0)
	celebration_panel.modulate.a = 0.0

	# Animate in
	if celebration_tween:
		celebration_tween.kill()
	celebration_tween = create_tween()
	celebration_tween.set_parallel(true)
	celebration_tween.tween_property(celebration_overlay, "color:a", 0.6, 0.4)
	celebration_tween.tween_property(celebration_panel, "modulate:a", 1.0, 0.6)

	# Auto-dismiss after 8 seconds if no key pressed
	celebration_tween.set_parallel(false)
	celebration_tween.tween_interval(8.0)
	celebration_tween.tween_callback(_hide_celebration)

	print("[HUD] Showing celebration for level %d" % level)


## Hide level-up celebration UI.
func _hide_celebration() -> void:
	if not is_celebrating:
		return

	is_celebrating = false

	if celebration_tween:
		celebration_tween.kill()

	# Animate out
	celebration_tween = create_tween()
	celebration_tween.set_parallel(true)
	celebration_tween.tween_property(celebration_overlay, "color:a", 0.0, 0.3)
	celebration_tween.tween_property(celebration_panel, "modulate:a", 0.0, 0.3)
	celebration_tween.set_parallel(false)
	celebration_tween.tween_callback(func():
		celebration_overlay.visible = false
		celebration_panel.visible = false
	)


func _input(event: InputEvent) -> void:
	# Dismiss celebration on any key or button press
	if is_celebrating:
		if (event is InputEventKey and event.pressed) or (event is InputEventJoypadButton and event.pressed):
			_hide_celebration()


## Fade the screen to black and back. Calls callback after fade out completes.
func fade_to_black_and_back(fade_out_duration: float, hold_duration: float, fade_in_duration: float, callback: Callable = Callable()) -> void:
	if not fade_overlay:
		if callback.is_valid():
			callback.call()
		return

	fade_overlay.visible = true
	fade_overlay.color = Color(0, 0, 0, 0)

	var tween: Tween = create_tween()

	# Fade to black
	tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 1), fade_out_duration)

	# Call the callback after fade out (e.g., to skip time)
	if callback.is_valid():
		tween.tween_callback(callback)

	# Hold black
	tween.tween_interval(hold_duration)

	# Fade back in
	tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 0), fade_in_duration)

	# Hide overlay when done
	tween.tween_callback(func(): fade_overlay.visible = false)
