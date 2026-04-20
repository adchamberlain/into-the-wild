extends Node
class_name WeatherManager
## Manages daily weather via a rolling 7-day forecast queue.
##
## Each day's weather is pre-rolled into `forecast` and consumed on day_changed.
## No signal-order coupling: the only subscription needed for rolls is day_changed.

signal weather_changed(weather_type: String)

enum Weather { CLEAR, RAIN, STORM, FOG, HEAT_WAVE, COLD_SNAP }

const FORECAST_DAYS: int = 7

# Weather state
var current_weather: Weather = Weather.CLEAR
var forecast: Array[int] = []  # Next FORECAST_DAYS days (ints for JSON round-trip)
var weather_enabled: bool = true

# Guard against re-emits of day_changed (e.g. during save/load) applying weather twice
var _last_rolled_day: int = 0

# Damage rates (per second)
@export var storm_damage_rate: float = 2.0
@export var cold_damage_rate: float = 1.5
@export var heat_wave_hunger_multiplier: float = 2.0

# Daily roll probabilities
@export var rain_chance: float = 0.15
@export var fog_chance: float = 0.08
@export var heat_wave_chance: float = 0.03
@export var cold_snap_chance: float = 0.03

# Chance a rain/fog day repeats the following day. Heat waves and cold snaps
# are treated as one-day extreme events and never persist.
@export var weather_persistence_chance: float = 0.4

# Fire effectiveness reduction during rain
@export var rain_fire_effectiveness: float = 0.5
@export var storm_fire_extinguish_time: float = 30.0  # Seconds of neglect before fire extinguishes in a storm

# Node references
@export var time_manager_path: NodePath
@export var player_path: NodePath
@export var campsite_manager_path: NodePath
@export var environment_manager_path: NodePath

var time_manager: Node
var player: Node
var player_stats: Node
var campsite_manager: CampsiteManager
var environment_manager: Node

# Damage check timer
var damage_check_timer: float = 0.0
const DAMAGE_CHECK_INTERVAL: float = 0.5

# Fire extinguish tracking
var fire_storm_timers: Dictionary = {}

# Storm fire check throttle
const STORM_FIRE_CHECK_INTERVAL: float = 0.5
var storm_fire_check_timer: float = 0.0


func _ready() -> void:
	if time_manager_path:
		time_manager = get_node_or_null(time_manager_path)
		if time_manager:
			if time_manager.has_signal("day_changed") and not time_manager.day_changed.is_connected(_on_day_changed):
				time_manager.day_changed.connect(_on_day_changed)
			if time_manager.has_signal("period_changed") and not time_manager.period_changed.is_connected(_on_period_changed):
				time_manager.period_changed.connect(_on_period_changed)

	if player_path:
		player = get_node_or_null(player_path)
		if player:
			player_stats = player.get_node_or_null("PlayerStats")

	if campsite_manager_path:
		campsite_manager = get_node_or_null(campsite_manager_path)

	if environment_manager_path:
		environment_manager = get_node_or_null(environment_manager_path)

	# Fresh new game: fill the forecast queue and mark today as already handled.
	# SaveLoad overwrites both fields in _apply_weather_data when loading.
	if forecast.is_empty():
		_fill_forecast()
	if time_manager and "current_day" in time_manager:
		_last_rolled_day = time_manager.current_day

	_set_weather(Weather.CLEAR)
	print("[WeatherManager] Initialized with clear weather, forecast: %s" % _forecast_debug_string())


func _process(delta: float) -> void:
	damage_check_timer += delta
	if damage_check_timer >= DAMAGE_CHECK_INTERVAL:
		damage_check_timer = 0.0
		_apply_weather_effects(DAMAGE_CHECK_INTERVAL)

	if current_weather == Weather.STORM:
		storm_fire_check_timer += delta
		if storm_fire_check_timer >= STORM_FIRE_CHECK_INTERVAL:
			_update_storm_fire_effects(storm_fire_check_timer)
			storm_fire_check_timer = 0.0


func _apply_weather_effects(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(player_stats):
		return

	if not weather_enabled:
		return

	var weather_damage_enabled: bool = true
	if "weather_damage_enabled" in player_stats:
		weather_damage_enabled = player_stats.weather_damage_enabled

	var player_pos: Vector3 = player.global_position

	match current_weather:
		Weather.STORM:
			if weather_damage_enabled and campsite_manager and not campsite_manager.is_in_shelter(player_pos):
				player_stats.take_damage(storm_damage_rate * delta)

		Weather.COLD_SNAP:
			if weather_damage_enabled and campsite_manager and not campsite_manager.is_near_fire(player_pos):
				player_stats.take_damage(cold_damage_rate * delta)

		Weather.HEAT_WAVE:
			# Hunger multiplier is set when weather changes
			pass


func _update_storm_fire_effects(delta: float) -> void:
	if not campsite_manager:
		return

	var fire_pits: Array[Node] = campsite_manager.get_fire_pits()
	var player_pos: Vector3 = player.global_position if is_instance_valid(player) else Vector3.ZERO

	for key: Variant in fire_storm_timers.keys():
		if not is_instance_valid(key):
			fire_storm_timers.erase(key)

	for fire: Node in fire_pits:
		if not is_instance_valid(fire) or not "is_lit" in fire or not fire.is_lit:
			continue

		var is_tending: bool = is_instance_valid(player) and fire.global_position.distance_to(player_pos) < 3.0

		if is_tending:
			fire_storm_timers[fire] = 0.0
		else:
			if not fire_storm_timers.has(fire):
				fire_storm_timers[fire] = 0.0
			fire_storm_timers[fire] += delta

			if fire_storm_timers[fire] >= storm_fire_extinguish_time:
				if fire.has_method("extinguish"):
					fire.extinguish()
					print("[WeatherManager] Fire extinguished by storm!")
				fire_storm_timers.erase(fire)


func _on_day_changed(new_day: int) -> void:
	if not weather_enabled:
		return

	# Skip re-emits (save/load fires day_changed as a refresh after _apply_time_data)
	if new_day <= _last_rolled_day:
		return
	_last_rolled_day = new_day

	var next: int = int(Weather.CLEAR)
	if not forecast.is_empty():
		next = forecast.pop_front()

	# Keep the queue topped up to FORECAST_DAYS entries
	_fill_forecast()

	_set_weather(next)


func _on_period_changed(period: String) -> void:
	if not weather_enabled:
		return

	# Rain can escalate to storm during afternoon (building pressure)
	if current_weather == Weather.RAIN and period == "Afternoon":
		if randf() < 0.25:
			_set_weather(Weather.STORM)
			print("[WeatherManager] Rain escalated to storm!")


func _fill_forecast() -> void:
	while forecast.size() < FORECAST_DAYS:
		var prev: int = forecast.back() if not forecast.is_empty() else int(current_weather)
		forecast.append(_roll_next(prev))


func _roll_next(prev: int) -> int:
	# Persistence: rain and fog can linger into the next day. Heat waves and
	# cold snaps are one-day events — chaining them produces unrealistic
	# multi-day extreme-weather streaks.
	if prev == int(Weather.RAIN) or prev == int(Weather.FOG) or prev == int(Weather.STORM):
		if randf() < weather_persistence_chance:
			return prev

	var roll: float = randf()
	var cumulative: float = 0.0

	cumulative += rain_chance
	if roll < cumulative:
		return int(Weather.RAIN)

	cumulative += fog_chance
	if roll < cumulative:
		return int(Weather.FOG)

	cumulative += heat_wave_chance
	if roll < cumulative:
		return int(Weather.HEAT_WAVE)

	cumulative += cold_snap_chance
	if roll < cumulative:
		return int(Weather.COLD_SNAP)

	return int(Weather.CLEAR)


func _set_weather(weather: Variant) -> void:
	var weather_int: int = int(weather)
	current_weather = weather_int

	if player_stats:
		if weather_int == int(Weather.HEAT_WAVE):
			player_stats.hunger_multiplier = heat_wave_hunger_multiplier
		else:
			player_stats.hunger_multiplier = 1.0

	_update_fire_effectiveness()

	if environment_manager and environment_manager.has_method("set_weather_overlay"):
		environment_manager.set_weather_overlay(get_weather_name())

	weather_changed.emit(get_weather_name())

	if weather_int != int(Weather.CLEAR):
		var _hint_mgr: Node = get_node_or_null("/root/HintManager") if is_inside_tree() else null
		if _hint_mgr and _hint_mgr.has_method("try_show"):
			_hint_mgr.try_show("first_weather")

	# Storm timers are scoped to the current weather
	if weather_int != int(Weather.STORM):
		fire_storm_timers.clear()

	print("[WeatherManager] Weather: %s" % get_weather_name())


func _update_fire_effectiveness() -> void:
	if not campsite_manager:
		return

	var fire_pits: Array[Node] = campsite_manager.get_fire_pits()
	for fire: Node in fire_pits:
		if not is_instance_valid(fire):
			continue
		if fire.has_method("set_effectiveness"):
			match current_weather:
				Weather.RAIN:
					fire.set_effectiveness(rain_fire_effectiveness)
				Weather.STORM:
					fire.set_effectiveness(rain_fire_effectiveness)
				_:
					fire.set_effectiveness(1.0)


func _forecast_debug_string() -> String:
	var names: Array[String] = []
	for w: int in forecast:
		names.append(_weather_to_string(w))
	return "[%s]" % ", ".join(names)


## Get current weather as string.
func get_weather_name() -> String:
	return _weather_to_string(current_weather)


## Get weather icon (text-based).
func get_weather_icon() -> String:
	match current_weather:
		Weather.CLEAR:
			return "Sun"
		Weather.RAIN:
			return "Rain"
		Weather.STORM:
			return "Storm!"
		Weather.FOG:
			return "Fog"
		Weather.HEAT_WAVE:
			return "Hot!"
		Weather.COLD_SNAP:
			return "Cold!"
	return "?"


## Check if current weather is dangerous.
func is_dangerous_weather() -> bool:
	return current_weather in [Weather.STORM, Weather.COLD_SNAP, Weather.HEAT_WAVE]


## Check if player is currently protected from weather effects.
func is_player_protected() -> bool:
	if not is_instance_valid(player) or not is_instance_valid(campsite_manager):
		return false

	var player_pos: Vector3 = player.global_position

	match current_weather:
		Weather.STORM:
			return campsite_manager.is_in_shelter(player_pos)
		Weather.COLD_SNAP:
			return campsite_manager.is_near_fire(player_pos)
		_:
			return true


## Get protection status text for HUD.
func get_protection_status() -> String:
	if not is_instance_valid(player) or not is_instance_valid(campsite_manager):
		return ""

	var player_pos: Vector3 = player.global_position
	var in_shelter: bool = campsite_manager.is_in_shelter(player_pos)
	var near_fire: bool = campsite_manager.is_near_fire(player_pos)

	if in_shelter and near_fire:
		return "Sheltered + Fire"
	elif in_shelter:
		return "Sheltered"
	elif near_fire:
		return "Near Fire"
	else:
		return "Exposed"


## Force a specific weather (for testing/debug).
func set_weather_debug(weather_name: String) -> void:
	match weather_name.to_lower():
		"clear":
			_set_weather(Weather.CLEAR)
		"rain":
			_set_weather(Weather.RAIN)
		"storm":
			_set_weather(Weather.STORM)
		"fog":
			_set_weather(Weather.FOG)
		"heat", "heat_wave", "heatwave":
			_set_weather(Weather.HEAT_WAVE)
		"cold", "cold_snap", "coldsnap":
			_set_weather(Weather.COLD_SNAP)


## Get the current weather name (for weather vane display).
func get_current_weather_name() -> String:
	return get_weather_name()


## Get the forecast as an array of weather name strings (capped at queue length).
func get_forecast(days: int = 5) -> Array[String]:
	var result: Array[String] = []
	var count: int = min(days, forecast.size())
	for i: int in range(count):
		result.append(_weather_to_string(forecast[i]))
	return result


## Get tomorrow's weather (first entry of forecast). Kept for any legacy callers.
func get_next_weather() -> String:
	if forecast.is_empty():
		return _weather_to_string(Weather.CLEAR)
	return _weather_to_string(forecast[0])


## Convert Weather enum or int to string.
func _weather_to_string(weather: Variant) -> String:
	match int(weather):
		Weather.CLEAR:
			return "Clear"
		Weather.RAIN:
			return "Rain"
		Weather.STORM:
			return "Storm"
		Weather.FOG:
			return "Fog"
		Weather.HEAT_WAVE:
			return "Heat Wave"
		Weather.COLD_SNAP:
			return "Cold Snap"
	return "Unknown"
