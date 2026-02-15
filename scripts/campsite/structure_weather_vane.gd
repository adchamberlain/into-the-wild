extends StructureBase
class_name StructureWeatherVane
## Weather vane that shows current weather and forecast.

# Animation settings
var arrow_pivot: Node3D = null
var wobble_speed: float = 2.0
var wobble_amount: float = 0.1  # Radians
var base_rotation: float = 0.0
var time_offset: float = 0.0

# Reference to weather manager
var weather_manager: Node = null


func _ready() -> void:
	super._ready()
	structure_type = "weather_vane"
	structure_name = "Weather Vane"
	interaction_text = "Check Weather"

	# Random start offset for wind wobble
	time_offset = randf() * TAU

	# Find arrow pivot for animation
	call_deferred("_find_arrow_pivot")
	call_deferred("_find_weather_manager")


func _find_arrow_pivot() -> void:
	arrow_pivot = get_node_or_null("ArrowPivot")


func _find_weather_manager() -> void:
	weather_manager = get_node_or_null("/root/Main/WeatherManager")


func _process(delta: float) -> void:
	# Animate the arrow with wind-like wobble
	if arrow_pivot:
		var wobble: float = sin(Time.get_ticks_msec() * 0.001 * wobble_speed + time_offset) * wobble_amount
		arrow_pivot.rotation.y = base_rotation + wobble


func interact(player: Node) -> bool:
	if not is_active:
		return false

	# Try to find weather manager if not cached
	if not weather_manager:
		_find_weather_manager()

	var current: String = "Unknown"
	if weather_manager and weather_manager.has_method("get_current_weather_name"):
		current = weather_manager.get_current_weather_name()

	# Build forecast display as vertical table (one row per day)
	var forecast_lines: Array[String] = []
	forecast_lines.append("Today:    %s" % current)

	if weather_manager and weather_manager.has_method("get_forecast"):
		var forecast: Array[String] = weather_manager.get_forecast(5)
		for i: int in range(forecast.size()):
			forecast_lines.append("Day +%d:   %s" % [i + 1, forecast[i]])
	elif weather_manager and weather_manager.has_method("get_next_weather"):
		forecast_lines.append("Tomorrow: %s" % weather_manager.get_next_weather())

	var forecast_text: String = "\n".join(forecast_lines)
	_show_notification(forecast_text, Color(0.7, 0.85, 1.0))

	print("[WeatherVane] Forecast: %s" % forecast_text)

	# Point the arrow based on weather (visual feedback)
	_point_to_weather(current)

	return true


func _point_to_weather(weather: String) -> void:
	# Rotate arrow based on weather type for visual feedback
	# Each weather gets a cardinal direction
	match weather.to_lower():
		"clear":
			base_rotation = 0  # North - sunny
		"rain":
			base_rotation = PI / 2  # East
		"storm":
			base_rotation = PI  # South - bad weather
		"fog":
			base_rotation = -PI / 2  # West
		"heat wave":
			base_rotation = PI / 4  # NE
		"cold snap":
			base_rotation = -3 * PI / 4  # SW
		_:
			base_rotation = 0


func get_interaction_text() -> String:
	return "Check Weather"


func _show_notification(message: String, color: Color) -> void:
	var hud: Node = _find_hud()
	if hud and hud.has_method("show_notification"):
		hud.show_notification(message, color)


func _find_hud() -> Node:
	var root: Node = get_tree().root
	if root.has_node("Main/HUD"):
		return root.get_node("Main/HUD")
	return null
