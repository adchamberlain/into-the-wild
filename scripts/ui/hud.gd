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
@onready var inventory_scroll: ScrollContainer = $InventoryPanel/VBoxContainer/ScrollContainer
@onready var item_list: VBoxContainer = $InventoryPanel/VBoxContainer/ScrollContainer/ItemList
@onready var empty_label: Label = $InventoryPanel/VBoxContainer/ScrollContainer/ItemList/EmptyLabel

# Equipment
@onready var equipped_label: Label = $EquippedPanel/EquippedContainer/EquippedLabel
@onready var durability_bar: ProgressBar = $EquippedPanel/EquippedContainer/DurabilityBar
@onready var equip_hint_label: Label = $EquippedPanel/EquippedContainer/EquipHintLabel

# Eat action hint
var eat_hint_label: Label

# Air bubble display (drowning)
var bubble_container: HBoxContainer
var bubble_labels: Array[Label] = []
var bubble_blink_timer: float = 0.0
var bubble_blink_visible: bool = true
var bubble_blink_active: bool = false
var bubble_count: int = 0
const BUBBLE_BLINK_RATE: float = 0.35  # seconds per toggle

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

# Compass HUD
var compass_panel: PanelContainer
var compass_label: Label
var camera: Camera3D

# Map marker POI cycling (unlocked by Explorer's Journal)
var _poi_entries: Array[Dictionary] = []  # [{label: String, position: Vector2}]
var _poi_index: int = 0
var _poi_cycle_timer: float = 0.0
const POI_CYCLE_INTERVAL: float = 3.0
var _poi_built: bool = false

# Desert heat indicator
var heat_panel: PanelContainer
var heat_label: Label

# Sandstorm overlay
var sandstorm_overlay: ColorRect
var sandstorm_tween: Tween

# Config for coordinates visibility
var show_coordinates: bool = true

# Celebration state
var is_celebrating: bool = false
var celebration_tween: Tween = null

# Notification timer tracking
var _notification_timer: SceneTreeTimer = null

# Overlay mode suppresses interaction prompt updates
var _overlay_active: bool = false

# Grapple reticle (uses existing Crosshair label)
@onready var crosshair: Label = $Crosshair
var default_crosshair_color: Color = Color(1, 1, 1, 0.8)

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

# Gliding state indicator
var gliding_panel: PanelContainer = null

# Weather damage flash
var weather_damage_flash_timer: float = 0.0
var last_player_health: float = 100.0

# Cache of item labels for quick updates
var item_labels: Dictionary = {}

# Category section header labels
var _section_labels: Dictionary = {}  # "Tools"/"Food"/"Resources" -> Label

# Items classified as tools (equippable items + crafting kits + upgrade wraps)
const TOOL_ITEMS: Array = [
	"torch", "primitive_axe", "stone_axe", "metal_axe", "campfire_kit",
	"rope", "shelter_kit", "storage_box", "fishing_rod", "crafting_bench_kit",
	"drying_rack_kit", "garden_plot_kit", "canvas_tent_kit", "cabin_kit",
	"snare_trap_kit", "smithing_station_kit", "smoker_kit", "weather_vane_kit",
	"machete", "lantern", "grappling_hook", "lodestone", "map",
	"leather_axe_wrap", "leather_hook_wrap", "compass", "bow", "arrows",
	"diamond_axe", "enchanted_bow", "diamond_arrows", "hang_glider"
]

# Items classified as food (edible + healing)
const FOOD_ITEMS: Array = [
	"berry", "mushroom", "herb", "fish", "osha_root", "cactus_fruit",
	"berry_pouch", "waterskin",
	"cooked_berries", "cooked_mushroom", "cooked_fish", "cooked_meat",
	"dried_fish", "dried_berries", "dried_mushroom", "dried_herb",
	"smoked_meat", "smoked_fish",
	"hearty_stew", "preserved_meal", "herb_tea", "fish_dinner", "mushroom_soup",
	"healing_salve", "hide_bedroll"
]

# Performance: throttle expensive updates
const HUD_UPDATE_INTERVAL: float = 0.1  # Update coordinates/protection every 100ms
var hud_update_timer: float = 0.0


func _ready() -> void:
	add_to_group("hud")

	# Connect to time manager
	if time_manager_path:
		time_manager = get_node_or_null(time_manager_path)
		if time_manager:
			time_manager.time_changed.connect(_on_time_changed)
			time_manager.period_changed.connect(_on_period_changed)
			if time_manager.has_signal("day_changed"):
				time_manager.day_changed.connect(_on_day_changed)
			_update_time_display()

	# Connect to player for interaction prompts, inventory, stats, and equipment
	if player_path:
		player = get_node_or_null(player_path)
	if player:
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
				_update_health_bar(stats.health, stats.get_max_health() if stats.has_method("get_max_health") else stats.max_health)
				_update_hunger_bar(stats.hunger, stats.max_hunger)

		# Connect to player's equipment
		if player.has_method("get_equipment"):
			equipment = player.get_equipment()
			if equipment:
				equipment.item_equipped.connect(_on_item_equipped)
				equipment.item_unequipped.connect(_on_item_unequipped)
				equipment.durability_changed.connect(_on_durability_changed)
				equipment.tool_broken.connect(_on_tool_broken)

		# Connect to bow system for arrow count updates (deferred to handle initialization order)
		call_deferred("_connect_bow_system")

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

	# Cache camera reference
	if player:
		camera = player.get_node_or_null("Camera3D")

	# Create compass panel programmatically
	_create_compass_panel()

	# Create eat hint label at the bottom of the inventory panel
	_create_eat_hint_label()

	# Create desert heat indicator (hidden by default)
	_create_heat_indicator()

	# Create sandstorm overlay (hidden by default)
	_create_sandstorm_overlay()

	# Create gliding state indicator (hidden by default)
	_create_gliding_indicator()

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
	# Defer update so campsite_manager processes the day change first
	call_deferred("_update_campsite_level_display")


func _on_interaction_target_changed(target: Node, interaction_text: String) -> void:
	# Hide prompt if interaction text is empty
	if interaction_text.is_empty():
		if interaction_prompt_panel:
			interaction_prompt_panel.visible = false
		return

	if interaction_prompt:
		var prompt_text: String = _get_interact_prompt() + " " + interaction_text
		# Add move hint if target is a structure (except torches/lodestones - pick up only)
		if is_instance_valid(target) and target.is_in_group("structure"):
			var stype: String = target.get("structure_type") if target.get("structure_type") else ""
			var is_pickup_only: bool = stype == "placed_torch" or stype == "lodestone" or stype == "placed_lantern"
			if not is_pickup_only:
				var move_key: String = _get_button_prompt("move_structure")
				prompt_text += "  [%s] Move" % move_key
		interaction_prompt.text = prompt_text
	if interaction_prompt_panel and not _overlay_active:
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
	_update_eat_hint()


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


func _connect_bow_system() -> void:
	if not player:
		return
	var bow: Node = player.get_node_or_null("BowSystem")
	if bow:
		if bow.has_signal("arrow_count_changed"):
			bow.arrow_count_changed.connect(func(_count: int) -> void: _update_equipped_display())
		if bow.has_signal("arrow_type_changed"):
			bow.arrow_type_changed.connect(func(_type: String) -> void: _update_equipped_display())


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

		if equipped_type == "torch" or equipped_type == "lodestone":
			equipped_label.text += " [%s place, %s unequip]" % [use_key, unequip_key]
		elif StructureData.is_placeable_item(equipped_type):
			equipped_label.text += " [%s place, %s unequip]" % [use_key, unequip_key]
		elif equipped_type == "fishing_rod":
			# Fishing is done by interacting with fishing spots, not use_equipped
			var interact_key: String = _get_button_prompt("interact")
			equipped_label.text += " [%s fish, %s unequip]" % [interact_key, unequip_key]
		elif equipped_type == "bow" or equipped_type == "enchanted_bow":
			var arrow_count: int = 0
			var arrow_type_name: String = "regular"
			var cycle_key: String = _get_button_prompt("cycle_ammo")
			var player_node: Node = get_tree().get_first_node_in_group("player")
			if player_node:
				var bow: Node = player_node.get_node_or_null("BowSystem")
				if bow:
					arrow_count = bow.get_preferred_arrow_count()
					arrow_type_name = bow.get_preferred_arrow_name()
			equipped_label.text += " (%d %s arrows) [R-click aim, %s switch, %s unequip]" % [arrow_count, arrow_type_name, cycle_key, unequip_key]
		elif equipped_type == "map":
			equipped_label.text += " [%s open map, %s unequip]" % [use_key, unequip_key]
		elif equipped_type == "hang_glider":
			var jump_key: String = _get_button_prompt("jump")
			var crouch_key: String = _get_button_prompt("crouch")
			equipped_label.text += " [%s deploy, %s boost, %s retract, %s unequip]" % [use_key, jump_key, crouch_key, unequip_key]
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
	var display_name: String = item_type.capitalize().replace("_", " ").replace("River Rock", "Rock")
	show_notification("%s broke!" % display_name, Color(1.0, 0.4, 0.4))
	_update_equipped_display()


func _on_inventory_changed() -> void:
	print("[HUD] Inventory changed signal received, updating display")
	_update_inventory_display()


func _get_display_name(item_type: String) -> String:
	return item_type.capitalize().replace("_", " ").replace("River Rock", "Rock")


func _get_item_category(item_type: String) -> String:
	if item_type in TOOL_ITEMS:
		return "Tools"
	elif item_type in FOOD_ITEMS:
		return "Food"
	else:
		return "Resources"


func _update_inventory_display() -> void:
	if not inventory or not item_list:
		return

	var items: Dictionary = inventory.get_all_items()

	# Show/hide empty label
	if empty_label:
		empty_label.visible = items.is_empty()

	# Clear all existing labels and section headers
	for resource_type: String in item_labels:
		var label: Label = item_labels[resource_type]
		if is_instance_valid(label):
			label.queue_free()
	item_labels.clear()

	for section_name: String in _section_labels:
		var label: Label = _section_labels[section_name]
		if is_instance_valid(label):
			label.queue_free()
	_section_labels.clear()

	if items.is_empty():
		_update_eat_hint()
		return

	# Sort items into categories
	var categorized: Dictionary = {"Tools": [], "Food": [], "Resources": []}
	for item_type: String in items:
		var category: String = _get_item_category(item_type)
		categorized[category].append(item_type)

	# Alphabetize within each category by display name
	for category: String in categorized:
		categorized[category].sort_custom(func(a: String, b: String) -> bool:
			return _get_display_name(a) < _get_display_name(b)
		)

	# Build the display in order: Tools, Food, Resources
	for category: String in ["Tools", "Food", "Resources"]:
		var category_items: Array = categorized[category]
		if category_items.is_empty():
			continue

		# Section header
		var header: Label = Label.new()
		header.text = "-- %s --" % category
		header.add_theme_font_override("font", HUD_FONT)
		header.add_theme_font_size_override("font_size", 32)
		header.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))
		item_list.add_child(header)
		_section_labels[category] = header

		# Item labels
		for item_type: String in category_items:
			var count: int = items[item_type]
			var display_name: String = _get_display_name(item_type)
			var limit: int = inventory.get_stack_limit(item_type) if inventory.has_method("get_stack_limit") else 0

			var label: Label = Label.new()
			if limit > 0 and inventory.enforce_limits:
				label.text = "%s: %d/%d" % [display_name, count, limit]
			else:
				label.text = "%s: %d" % [display_name, count]
			label.add_theme_font_override("font", HUD_FONT)
			label.add_theme_font_size_override("font_size", 40)
			# Color items near/at limit in yellow/red
			if inventory.enforce_limits and limit > 0 and count >= limit:
				label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5, 1))
			elif inventory.enforce_limits and limit > 0 and count >= limit * 0.8:
				label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1))
			else:
				label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			item_list.add_child(label)
			item_labels[item_type] = label

	# Update eat hint visibility
	_update_eat_hint()


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
		_update_compass_display()

	# POI cycle timer for map markers
	if not _poi_entries.is_empty():
		_poi_cycle_timer += delta
		if _poi_cycle_timer >= POI_CYCLE_INTERVAL:
			_poi_cycle_timer = 0.0
			_poi_index = (_poi_index + 1) % _poi_entries.size()

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

	# Update grapple reticle
	_update_grapple_reticle()

	# Update gliding indicator with boost status
	if gliding_panel and player:
		var player_gliding: bool = "is_gliding" in player and player.is_gliding
		if gliding_panel.visible != player_gliding:
			gliding_panel.visible = player_gliding
		if player_gliding:
			var glide_lbl: Label = gliding_panel.get_node_or_null("GlidingLabel")
			if glide_lbl:
				var boosting: bool = "_glide_boosting" in player and player._glide_boosting
				if boosting:
					glide_lbl.text = "BOOSTING"
					glide_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1))
				else:
					glide_lbl.text = "GLIDING"
					glide_lbl.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6, 1))

	# Blink remaining bubbles when low on air
	if bubble_blink_active:
		bubble_blink_timer += delta
		if bubble_blink_timer >= BUBBLE_BLINK_RATE:
			bubble_blink_timer -= BUBBLE_BLINK_RATE
			bubble_blink_visible = not bubble_blink_visible
			_update_bubble_blink()


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


## Show a notification message. Duration scales with line count unless overridden.
func show_notification(message: String, color: Color = Color.WHITE, override_duration: float = 0.0) -> void:
	if notification_label and notification_panel:
		notification_label.text = message
		notification_label.add_theme_color_override("font_color", color)
		notification_panel.visible = true
		# Cancel previous notification timer so it doesn't hide this one early
		if _notification_timer and _notification_timer.time_left > 0 and _notification_timer.timeout.is_connected(_hide_notification):
			_notification_timer.timeout.disconnect(_hide_notification)
		# Use override if provided, otherwise scale with content: 3s base + 1s per extra line
		var duration: float = override_duration
		if duration <= 0.0:
			var line_count: int = message.count("\n") + 1
			duration = 3.0 + max(0, line_count - 1) * 1.0
		_notification_timer = get_tree().create_timer(duration)
		_notification_timer.timeout.connect(_hide_notification)


func _hide_notification() -> void:
	if notification_panel:
		notification_panel.visible = false


func _on_game_saved(_filepath: String, slot: int) -> void:
	show_notification("Saved to Slot %d!" % slot, Color(0.4, 1.0, 0.4, 1))


func _on_game_loaded(_filepath: String, slot: int) -> void:
	show_notification("Loaded Slot %d!" % slot, Color(0.4, 1.0, 0.4, 1))
	# Update campsite level display (without showing celebration)
	_update_campsite_level_display()
	# Refresh weather display (weather_changed signal isn't emitted during load)
	if weather_manager and weather_manager.has_method("get_weather_name"):
		_on_weather_changed(weather_manager.get_weather_name())


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

	if not _overlay_active:
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
		# Just started resting - show get up prompt (unless overlay is active)
		if interaction_prompt:
			interaction_prompt.text = "%s Get Up" % _get_interact_prompt()
		if interaction_prompt_panel and not _overlay_active:
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
	if celebration_tween and celebration_tween.is_valid():
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

	if celebration_tween and celebration_tween.is_valid():
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
			get_viewport().set_input_as_handled()
			return


## Update crosshair color based on grapple target validity.
func _update_grapple_reticle() -> void:
	if not crosshair or not equipment:
		return

	# Only change color when grappling hook is equipped
	if equipment.get_equipped() == "grappling_hook":
		# Get grappling hook node to check target validity
		var grappling_hook: Node = player.get_node_or_null("GrapplingHook") if player else null
		if grappling_hook and "current_target_valid" in grappling_hook:
			var color: Color
			if grappling_hook.is_grappling:
				# During grapple, show blue
				color = Color(0.4, 0.7, 1.0, 1.0)
			elif grappling_hook.current_target_valid:
				# Valid target - green
				color = Color(0.4, 1.0, 0.4, 1.0)
			elif grappling_hook.current_target_reason != "" and grappling_hook.current_target_reason != "No target":
				# Invalid target with reason - red
				color = Color(1.0, 0.4, 0.4, 1.0)
			else:
				# No target - white
				color = default_crosshair_color
			crosshair.add_theme_color_override("font_color", color)
		else:
			crosshair.add_theme_color_override("font_color", default_crosshair_color)
	else:
		# Reset to default color when not using grappling hook
		crosshair.add_theme_color_override("font_color", default_crosshair_color)


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


func _update_eat_hint() -> void:
	if not eat_hint_label:
		return

	var has_food: bool = player and player.has_method("has_consumable") and player.has_consumable()
	eat_hint_label.visible = has_food
	if has_food:
		var eat_key: String = _get_button_prompt("eat")
		eat_hint_label.text = "[%s] Eat" % eat_key


func _create_eat_hint_label() -> void:
	var vbox: VBoxContainer = inventory_panel.get_node_or_null("VBoxContainer") if inventory_panel else null
	if not vbox:
		return

	eat_hint_label = Label.new()
	eat_hint_label.name = "EatHintLabel"
	eat_hint_label.add_theme_font_override("font", HUD_FONT)
	eat_hint_label.add_theme_font_size_override("font_size", 28)
	eat_hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	eat_hint_label.visible = false
	vbox.add_child(eat_hint_label)


func _create_compass_panel() -> void:
	# Create the compass HUD panel programmatically
	compass_panel = PanelContainer.new()
	compass_panel.name = "CompassPanel"

	# Style: semi-transparent dark background matching HUD style
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12, 0.8)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	compass_panel.add_theme_stylebox_override("panel", style)

	# Position below StatsPanel (left side)
	compass_panel.anchors_preset = Control.PRESET_TOP_LEFT
	compass_panel.offset_left = 20.0
	compass_panel.offset_top = 190.0
	compass_panel.offset_right = 320.0
	compass_panel.offset_bottom = 240.0

	# Label for compass text
	compass_label = Label.new()
	compass_label.name = "CompassLabel"
	compass_label.add_theme_font_override("font", HUD_FONT)
	compass_label.add_theme_font_size_override("font_size", 32)
	compass_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1))
	compass_label.text = ""
	compass_panel.add_child(compass_label)

	add_child(compass_panel)
	compass_panel.visible = false


## Show/hide air bubbles when player is submerged. Called via group by player_controller.
func update_air_bubbles(count: int, submerged: bool) -> void:
	# Lazily create the bubble container on first call
	if not bubble_container:
		_create_bubble_container()

	if not submerged:
		bubble_container.visible = false
		bubble_blink_active = false
		return

	bubble_container.visible = true
	for i: int in bubble_labels.size():
		if i < count:
			# Filled bubble — light blue
			bubble_labels[i].add_theme_color_override("font_color", Color(0.6, 0.85, 1.0, 1))
		else:
			# Lost bubble — dim grey
			bubble_labels[i].add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 0.3))

	bubble_count = count

	# Activate blinking when 2 or fewer bubbles remain
	if count <= 2 and count > 0:
		if not bubble_blink_active:
			bubble_blink_active = true
			bubble_blink_timer = 0.0
			bubble_blink_visible = true
	else:
		bubble_blink_active = false
		# Ensure all filled bubbles are fully visible when not blinking
		for i2: int in bubble_labels.size():
			if i2 < count:
				bubble_labels[i2].add_theme_color_override("font_color", Color(0.6, 0.85, 1.0, 1))


func _create_bubble_container() -> void:
	# Place bubbles to the right of the health bar inside HealthContainer
	var health_container: Node = null
	if health_bar:
		health_container = health_bar.get_parent()
	if not health_container:
		return

	bubble_container = HBoxContainer.new()
	bubble_container.name = "BubbleContainer"
	bubble_container.add_theme_constant_override("separation", 4)
	bubble_container.visible = false
	health_container.add_child(bubble_container)

	for i: int in 5:
		var lbl: Label = Label.new()
		lbl.text = "●"
		lbl.add_theme_font_override("font", HUD_FONT)
		lbl.add_theme_font_size_override("font_size", 40)
		lbl.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0, 1))
		bubble_container.add_child(lbl)
		bubble_labels.append(lbl)


## Toggle filled bubble visibility for the blink warning effect.
func _update_bubble_blink() -> void:
	for i: int in bubble_labels.size():
		if i < bubble_count:
			if bubble_blink_visible:
				bubble_labels[i].add_theme_color_override("font_color", Color(0.6, 0.85, 1.0, 1))
			else:
				bubble_labels[i].add_theme_color_override("font_color", Color(0.6, 0.85, 1.0, 0.15))


func _update_compass_display() -> void:
	if not compass_panel or not compass_label:
		return

	# Check if player has compass in inventory AND lodestone is placed
	var has_compass: bool = inventory and inventory.has_item("compass")
	var lodestone_placed: bool = campsite_manager and campsite_manager.has_method("has_structure") and campsite_manager.has_structure("lodestone")

	# Check if map markers are unlocked (from Explorer's Journal)
	var markers_unlocked: bool = player and "map_markers_unlocked" in player and player.map_markers_unlocked
	if markers_unlocked and not _poi_built:
		_build_poi_entries()

	# Need either compass+lodestone or map markers to show the panel
	if not has_compass and not markers_unlocked:
		compass_panel.visible = false
		return
	if has_compass and not lodestone_placed and not markers_unlocked:
		compass_panel.visible = false
		return

	if not player or not camera:
		compass_panel.visible = false
		return

	# Determine what to display this frame
	var show_poi: bool = false
	var lodestone_pos: Vector3 = Vector3.ZERO
	var has_lodestone_pos: bool = false

	if has_compass and lodestone_placed and campsite_manager.has_method("get_structures_of_type"):
		var lodestones: Array = campsite_manager.get_structures_of_type("lodestone")
		if not lodestones.is_empty():
			lodestone_pos = lodestones[0].global_position
			has_lodestone_pos = true

	if markers_unlocked and not _poi_entries.is_empty():
		if has_lodestone_pos:
			# Alternate: show POI every 3rd cycle (lodestone gets priority)
			show_poi = (_poi_index % 3 == 2)
		else:
			# No lodestone — always show POIs
			show_poi = true

	if show_poi and not _poi_entries.is_empty():
		var safe_idx: int = _poi_index % _poi_entries.size()
		var poi: Dictionary = _poi_entries[safe_idx]
		var poi_label: String = poi["label"]
		var poi_pos: Vector2 = poi["position"]
		_show_compass_direction(poi_label, Vector3(poi_pos.x, 0, poi_pos.y))
	elif has_lodestone_pos:
		_show_compass_direction("Lodestone", lodestone_pos)
	else:
		compass_panel.visible = false


## Show compass direction to a named target at a world position.
func _show_compass_direction(target_name: String, target_pos: Vector3) -> void:
	var to_target: Vector3 = target_pos - player.global_position
	to_target.y = 0  # XZ plane only
	var distance: float = to_target.length()

	if distance < 0.5:
		compass_label.text = "%s  here" % target_name
		compass_panel.visible = true
		return

	var cam_forward: Vector3 = -camera.global_transform.basis.z
	cam_forward.y = 0
	if cam_forward.length_squared() < 0.001:
		return
	cam_forward = cam_forward.normalized()

	var dx: float = to_target.x
	var dz: float = to_target.z
	var dot: float = cam_forward.x * dx + cam_forward.z * dz
	var cross_val: float = cam_forward.x * dz - cam_forward.z * dx
	var angle: float = atan2(cross_val, dot)

	# Map angle to 8-direction arrow
	var arrows: Array[String] = ["↑", "↗", "→", "↘", "↓", "↙", "←", "↖"]
	var index: int = int(round(fmod(angle + TAU, TAU) / (TAU / 8.0))) % 8
	compass_label.text = "%s  %s  %dm" % [target_name, arrows[index], int(distance)]
	compass_panel.visible = true


## Build the POI entries array from chunk_manager data.
func _build_poi_entries() -> void:
	_poi_entries.clear()
	_poi_built = true

	var chunk_manager: Node = null
	if get_tree() and get_tree().root.has_node("Main/World/Terrain"):
		chunk_manager = get_tree().root.get_node("Main/World/Terrain")
	if not chunk_manager:
		return

	# Add oases
	if "desert_oases" in chunk_manager:
		for oasis: Dictionary in chunk_manager.desert_oases:
			var gem_type: String = oasis.get("gem_type", "unknown")
			var label: String = "%s Oasis" % gem_type.capitalize()
			_poi_entries.append({"label": label, "position": oasis["center"]})

	# Add cave entrances
	if "cave_entrances" in chunk_manager:
		var cave_num: int = 1
		for cave: Dictionary in chunk_manager.cave_entrances:
			_poi_entries.append({"label": "Cave %d" % cave_num, "position": cave["center"]})
			cave_num += 1

	# Add the sinkhole
	if "desert_sinkhole" in chunk_manager and chunk_manager.desert_sinkhole.size() > 0:
		_poi_entries.append({"label": "Ancient Sinkhole", "position": chunk_manager.desert_sinkhole["center"]})


func set_overlay_mode(enabled: bool) -> void:
	## Hide or show persistent HUD panels for full-screen overlay display.
	_overlay_active = enabled
	var panels: Array[Control] = [
		get_node_or_null("TimePanel"),
		get_node_or_null("StatsPanel"),
		get_node_or_null("EquippedPanel"),
		inventory_panel,
	]
	var compass: Control = get_node_or_null("CompassPanel")
	if compass:
		panels.append(compass)
	for panel: Control in panels:
		if panel:
			panel.visible = not enabled
	# Heat panel visibility is driven by desert heat state, not overlay toggle
	if heat_panel and enabled:
		heat_panel.visible = false
	# Hide dynamic panels when entering overlay, but don't force-show on exit
	if enabled:
		if interaction_prompt_panel:
			interaction_prompt_panel.visible = false
		if notification_panel:
			notification_panel.visible = false
	if crosshair:
		crosshair.visible = not enabled


## Create the desert heat indicator panel (positioned near the hunger bar).
func _create_heat_indicator() -> void:
	heat_panel = PanelContainer.new()
	heat_panel.name = "HeatPanel"

	# Style: semi-transparent dark background matching HUD style
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12, 0.8)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	heat_panel.add_theme_stylebox_override("panel", style)

	# Position below compass panel (which is at top 190-240)
	heat_panel.anchors_preset = Control.PRESET_TOP_LEFT
	heat_panel.offset_left = 20.0
	heat_panel.offset_top = 245.0
	heat_panel.offset_right = 195.0
	heat_panel.offset_bottom = 290.0

	# Label for heat text
	heat_label = Label.new()
	heat_label.name = "HeatLabel"
	heat_label.add_theme_font_override("font", HUD_FONT)
	heat_label.add_theme_font_size_override("font_size", 28)
	heat_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5, 1))
	heat_label.text = "HEAT 1.5x"
	heat_panel.add_child(heat_label)

	add_child(heat_panel)
	heat_panel.visible = false


## Create the full-screen sandstorm overlay (sandy brown tint).
func _create_sandstorm_overlay() -> void:
	sandstorm_overlay = ColorRect.new()
	sandstorm_overlay.name = "SandstormOverlay"
	sandstorm_overlay.anchors_preset = Control.PRESET_FULL_RECT
	sandstorm_overlay.anchor_right = 1.0
	sandstorm_overlay.anchor_bottom = 1.0
	sandstorm_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sandstorm_overlay.color = Color(0.82, 0.72, 0.55, 0.0)
	sandstorm_overlay.visible = false
	add_child(sandstorm_overlay)


## Create the gliding state indicator (centered below crosshair).
func _create_gliding_indicator() -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "GlidingPanel"
	panel.anchors_preset = Control.PRESET_CENTER
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -60
	panel.offset_right = 60
	panel.offset_top = 30  # Below crosshair
	panel.offset_bottom = 70
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.75)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)

	var glide_lbl: Label = Label.new()
	glide_lbl.name = "GlidingLabel"
	glide_lbl.text = "GLIDING"
	glide_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glide_lbl.add_theme_font_override("font", HUD_FONT)
	glide_lbl.add_theme_font_size_override("font_size", 28)
	glide_lbl.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6, 1))
	panel.add_child(glide_lbl)

	panel.visible = false
	add_child(panel)
	gliding_panel = panel


## Show or hide the desert heat indicator.
func set_desert_heat_active(active: bool) -> void:
	if heat_panel:
		heat_panel.visible = active and not _overlay_active


## Fade in the sandstorm overlay.
func show_sandstorm_overlay() -> void:
	if not sandstorm_overlay:
		return
	sandstorm_overlay.visible = true
	if sandstorm_tween and sandstorm_tween.is_valid():
		sandstorm_tween.kill()
	sandstorm_tween = create_tween()
	sandstorm_tween.tween_property(sandstorm_overlay, "color:a", 0.3, 2.0)


## Fade out the sandstorm overlay.
func hide_sandstorm_overlay() -> void:
	if not sandstorm_overlay:
		return
	if sandstorm_tween and sandstorm_tween.is_valid():
		sandstorm_tween.kill()
	sandstorm_tween = create_tween()
	sandstorm_tween.tween_property(sandstorm_overlay, "color:a", 0.0, 2.0)
	sandstorm_tween.tween_callback(func() -> void: sandstorm_overlay.visible = false)
