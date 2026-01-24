extends CanvasLayer
## Simple config menu for toggling game features during development/testing.

signal config_changed()

# Node references
@export var time_manager_path: NodePath
@export var weather_manager_path: NodePath
@export var player_path: NodePath

var time_manager: Node
var weather_manager: Node
var player: Node
var player_stats: Node

# Config state (defaults)
var hunger_enabled: bool = false
var health_drain_enabled: bool = false
var weather_damage_enabled: bool = false
var weather_enabled: bool = true
var day_length_minutes: float = 20.0

# UI References
@onready var panel: PanelContainer = $Panel
@onready var hunger_toggle: CheckButton = $Panel/VBoxContainer/HungerToggle
@onready var health_toggle: CheckButton = $Panel/VBoxContainer/HealthToggle
@onready var weather_damage_toggle: CheckButton = $Panel/VBoxContainer/WeatherDamageToggle
@onready var weather_toggle: CheckButton = $Panel/VBoxContainer/WeatherToggle
@onready var day_length_slider: HSlider = $Panel/VBoxContainer/DayLengthContainer/DayLengthSlider
@onready var day_length_label: Label = $Panel/VBoxContainer/DayLengthContainer/DayLengthValue

var is_visible: bool = false


func _ready() -> void:
	# Get node references
	if time_manager_path:
		time_manager = get_node_or_null(time_manager_path)
	if weather_manager_path:
		weather_manager = get_node_or_null(weather_manager_path)
	if player_path:
		player = get_node_or_null(player_path)
		if player:
			player_stats = player.get_node_or_null("PlayerStats")

	# Initialize UI state
	_init_ui()

	# Start hidden
	panel.visible = false
	is_visible = false


func _init_ui() -> void:
	# Set initial toggle states
	hunger_toggle.button_pressed = hunger_enabled
	health_toggle.button_pressed = health_drain_enabled
	weather_damage_toggle.button_pressed = weather_damage_enabled
	weather_toggle.button_pressed = weather_enabled

	# Set day length slider
	if time_manager and "day_length_minutes" in time_manager:
		day_length_minutes = time_manager.day_length_minutes
	day_length_slider.value = day_length_minutes
	day_length_label.text = "%.0f min" % day_length_minutes

	# Connect signals
	hunger_toggle.toggled.connect(_on_hunger_toggled)
	health_toggle.toggled.connect(_on_health_toggled)
	weather_damage_toggle.toggled.connect(_on_weather_damage_toggled)
	weather_toggle.toggled.connect(_on_weather_toggled)
	day_length_slider.value_changed.connect(_on_day_length_changed)

	# Apply initial config
	_apply_config()


func _input(event: InputEvent) -> void:
	# Toggle menu with Tab key
	if event is InputEventKey and event.pressed:
		if event.physical_keycode == KEY_TAB:
			toggle_menu()
			get_viewport().set_input_as_handled()


func toggle_menu() -> void:
	is_visible = not is_visible
	panel.visible = is_visible

	# Handle mouse capture
	if is_visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_hunger_toggled(pressed: bool) -> void:
	hunger_enabled = pressed
	_apply_config()
	print("[ConfigMenu] Hunger depletion: %s" % ("ON" if pressed else "OFF"))


func _on_health_toggled(pressed: bool) -> void:
	health_drain_enabled = pressed
	_apply_config()
	print("[ConfigMenu] Health drain (starvation): %s" % ("ON" if pressed else "OFF"))


func _on_weather_damage_toggled(pressed: bool) -> void:
	weather_damage_enabled = pressed
	_apply_config()
	print("[ConfigMenu] Weather damage (storms/cold): %s" % ("ON" if pressed else "OFF"))


func _on_weather_toggled(pressed: bool) -> void:
	weather_enabled = pressed
	_apply_config()
	print("[ConfigMenu] Weather system: %s" % ("ON" if pressed else "OFF"))


func _on_day_length_changed(value: float) -> void:
	day_length_minutes = value
	day_length_label.text = "%.0f min" % value
	_apply_config()
	print("[ConfigMenu] Day length: %.0f minutes" % value)


func _apply_config() -> void:
	# Apply hunger setting
	if player_stats:
		player_stats.hunger_depletion_enabled = hunger_enabled
		player_stats.health_drain_enabled = health_drain_enabled
		player_stats.weather_damage_enabled = weather_damage_enabled

	# Apply weather setting
	if weather_manager:
		weather_manager.weather_enabled = weather_enabled
		if not weather_enabled:
			# Force clear weather when disabled
			weather_manager.set_weather_debug("clear")

	# Apply day length
	if time_manager and "day_length_minutes" in time_manager:
		time_manager.day_length_minutes = day_length_minutes
		# Recalculate seconds per minute
		if time_manager.has_method("_recalculate_time_scale"):
			time_manager._recalculate_time_scale()
		elif "_seconds_per_game_minute" in time_manager:
			time_manager._seconds_per_game_minute = (day_length_minutes * 60.0) / (24.0 * 60.0)

	config_changed.emit()


## Get current config as dictionary.
func get_config() -> Dictionary:
	return {
		"hunger_enabled": hunger_enabled,
		"health_drain_enabled": health_drain_enabled,
		"weather_damage_enabled": weather_damage_enabled,
		"weather_enabled": weather_enabled,
		"day_length_minutes": day_length_minutes
	}
