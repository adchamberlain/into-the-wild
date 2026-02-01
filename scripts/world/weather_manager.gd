extends Node
class_name WeatherManager
## Manages dynamic weather that affects gameplay and integrates with shelter/fire protection.

signal weather_changed(weather_type: String)

enum Weather { CLEAR, RAIN, STORM, FOG, HEAT_WAVE, COLD_SNAP }

# Weather state
var current_weather: Weather = Weather.CLEAR
var weather_duration_remaining: float = 0.0
var weather_enabled: bool = true  # Can be toggled by ConfigMenu

# Damage rates (per second)
@export var storm_damage_rate: float = 2.0
@export var cold_damage_rate: float = 1.5
@export var heat_wave_hunger_multiplier: float = 2.0

# Weather duration (in game hours, converted to real seconds)
@export var min_weather_duration_hours: float = 6.0
@export var max_weather_duration_hours: float = 18.0

# Weather transition probabilities (daily roll at dawn)
# Real-world inspired: clear weather dominates, bad weather is less common
@export var rain_chance: float = 0.15
@export var fog_chance: float = 0.08
@export var heat_wave_chance: float = 0.05
@export var cold_snap_chance: float = 0.05

# Weather persistence - chance weather continues to next day
@export var weather_persistence_chance: float = 0.4

# Track if we've rolled for weather today
var _rolled_today: bool = false

# Fire effectiveness reduction during rain
@export var rain_fire_effectiveness: float = 0.5
@export var storm_fire_extinguish_time: float = 30.0  # Seconds before fire goes out in storm

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
var fire_storm_timers: Dictionary = {}  # fire_pit -> time_exposed

# Performance: throttle storm fire checks
const STORM_FIRE_CHECK_INTERVAL: float = 0.5  # Check twice per second, not every frame
var storm_fire_check_timer: float = 0.0


func _ready() -> void:
	# Get node references
	if time_manager_path:
		time_manager = get_node_or_null(time_manager_path)
		if time_manager:
			time_manager.period_changed.connect(_on_period_changed)

	if player_path:
		player = get_node_or_null(player_path)
		if player:
			player_stats = player.get_node_or_null("PlayerStats")

	if campsite_manager_path:
		campsite_manager = get_node_or_null(campsite_manager_path)

	if environment_manager_path:
		environment_manager = get_node_or_null(environment_manager_path)

	# Start with clear weather
	_set_weather(Weather.CLEAR)
	print("[WeatherManager] Initialized with clear weather")


func _process(delta: float) -> void:
	# Update weather duration
	if weather_duration_remaining > 0:
		weather_duration_remaining -= delta
		if weather_duration_remaining <= 0:
			# Weather expired, return to clear
			_transition_to_clear()

	# Apply weather effects
	damage_check_timer += delta
	if damage_check_timer >= DAMAGE_CHECK_INTERVAL:
		damage_check_timer = 0.0
		_apply_weather_effects(DAMAGE_CHECK_INTERVAL)

	# Handle storm fire extinguishing (throttled for performance)
	if current_weather == Weather.STORM:
		storm_fire_check_timer += delta
		if storm_fire_check_timer >= STORM_FIRE_CHECK_INTERVAL:
			_update_storm_fire_effects(storm_fire_check_timer)
			storm_fire_check_timer = 0.0


func _apply_weather_effects(delta: float) -> void:
	if not player or not player_stats:
		return

	# Don't apply damage effects if weather is disabled
	if not weather_enabled:
		return

	# Check if weather damage is enabled in player stats
	var weather_damage_enabled: bool = true
	if "weather_damage_enabled" in player_stats:
		weather_damage_enabled = player_stats.weather_damage_enabled

	var player_pos: Vector3 = player.global_position

	match current_weather:
		Weather.STORM:
			# Damage if not in shelter (and weather damage enabled)
			if weather_damage_enabled and campsite_manager and not campsite_manager.is_in_shelter(player_pos):
				player_stats.take_damage(storm_damage_rate * delta)

		Weather.COLD_SNAP:
			# Damage if not near fire (and weather damage enabled)
			if weather_damage_enabled and campsite_manager and not campsite_manager.is_near_fire(player_pos):
				player_stats.take_damage(cold_damage_rate * delta)

		Weather.HEAT_WAVE:
			# Hunger multiplier is set when weather changes
			pass


func _update_storm_fire_effects(delta: float) -> void:
	if not campsite_manager:
		return

	var fire_pits: Array[Node] = campsite_manager.get_fire_pits()
	var player_pos: Vector3 = player.global_position if player else Vector3.ZERO

	for fire: Node in fire_pits:
		if not fire.has_method("is_lit") or not fire.is_lit:
			continue

		# Check if player is tending the fire (within interaction range)
		var is_tending: bool = player and fire.global_position.distance_to(player_pos) < 3.0

		if is_tending:
			# Reset extinguish timer
			fire_storm_timers[fire] = 0.0
		else:
			# Increment timer
			if not fire_storm_timers.has(fire):
				fire_storm_timers[fire] = 0.0
			fire_storm_timers[fire] += delta

			# Check if fire should extinguish
			if fire_storm_timers[fire] >= storm_fire_extinguish_time:
				if fire.has_method("extinguish"):
					fire.extinguish()
					print("[WeatherManager] Fire extinguished by storm!")
				fire_storm_timers.erase(fire)


func _on_period_changed(period: String) -> void:
	# Don't change weather if disabled
	if not weather_enabled:
		return

	# Reset daily roll flag at night (so we can roll again at next dawn)
	if period == "Night":
		_rolled_today = false
		return

	# Only roll for weather change once per day at dawn
	if period == "Dawn" and not _rolled_today:
		_rolled_today = true
		_daily_weather_roll()

	# Rain can escalate to storm during afternoon (building pressure)
	if current_weather == Weather.RAIN and period == "Afternoon":
		if randf() < 0.25:
			_set_weather(Weather.STORM)
			print("[WeatherManager] Rain escalated to storm!")


func _daily_weather_roll() -> void:
	# If we have active weather, check for persistence
	if current_weather != Weather.CLEAR:
		if randf() < weather_persistence_chance:
			# Weather persists - extend duration
			var hours: float = randf_range(min_weather_duration_hours, max_weather_duration_hours)
			if time_manager and "day_length_minutes" in time_manager:
				var seconds_per_hour: float = (time_manager.day_length_minutes * 60.0) / 24.0
				weather_duration_remaining = hours * seconds_per_hour
			else:
				weather_duration_remaining = hours * 50.0
			print("[WeatherManager] Weather persists: %s for another %.1f hours" % [get_weather_name(), hours])
			return
		else:
			# Weather clears
			_set_weather(Weather.CLEAR)
			print("[WeatherManager] Weather cleared after multi-day pattern")
			return

	# Roll for new weather (from clear)
	_roll_for_new_weather()


func _roll_for_new_weather() -> void:
	var roll: float = randf()
	var cumulative: float = 0.0

	# Get current season hint from time_manager if available
	var day: int = 1
	if time_manager and time_manager.has_method("get_current_day"):
		day = time_manager.get_current_day()

	# Rain - most common bad weather
	cumulative += rain_chance
	if roll < cumulative:
		_set_weather(Weather.RAIN)
		return

	# Fog - more common in early game (spring-like)
	cumulative += fog_chance
	if roll < cumulative:
		_set_weather(Weather.FOG)
		return

	# Heat wave - rare
	cumulative += heat_wave_chance
	if roll < cumulative:
		_set_weather(Weather.HEAT_WAVE)
		return

	# Cold snap - rare
	cumulative += cold_snap_chance
	if roll < cumulative:
		_set_weather(Weather.COLD_SNAP)
		return

	# Otherwise stays clear (most likely outcome ~67% chance)
	print("[WeatherManager] Weather check: staying clear")


func _set_weather(weather: Weather) -> void:
	var old_weather: Weather = current_weather
	current_weather = weather

	# Calculate duration in real seconds
	if weather != Weather.CLEAR:
		var hours: float = randf_range(min_weather_duration_hours, max_weather_duration_hours)
		# Convert game hours to real seconds (based on day_length_minutes)
		if time_manager and "day_length_minutes" in time_manager:
			var seconds_per_hour: float = (time_manager.day_length_minutes * 60.0) / 24.0
			weather_duration_remaining = hours * seconds_per_hour
		else:
			# Default: 20 min day = 50 seconds per game hour
			weather_duration_remaining = hours * 50.0

	# Update hunger multiplier
	if player_stats:
		if weather == Weather.HEAT_WAVE:
			player_stats.hunger_multiplier = heat_wave_hunger_multiplier
		else:
			player_stats.hunger_multiplier = 1.0

	# Update fire effectiveness
	_update_fire_effectiveness()

	# Update environment visuals
	if environment_manager and environment_manager.has_method("set_weather_overlay"):
		environment_manager.set_weather_overlay(get_weather_name())

	# Emit signal
	weather_changed.emit(get_weather_name())

	# Calculate hours for logging
	var duration_hours: float = 0.0
	if time_manager and "day_length_minutes" in time_manager:
		var seconds_per_hour: float = (time_manager.day_length_minutes * 60.0) / 24.0
		duration_hours = weather_duration_remaining / seconds_per_hour
	else:
		duration_hours = weather_duration_remaining / 50.0
	print("[WeatherManager] Weather changed to: %s (duration: %.1f game hours)" % [get_weather_name(), duration_hours])


func _transition_to_clear() -> void:
	_set_weather(Weather.CLEAR)
	fire_storm_timers.clear()


func _update_fire_effectiveness() -> void:
	if not campsite_manager:
		return

	var fire_pits: Array[Node] = campsite_manager.get_fire_pits()
	for fire: Node in fire_pits:
		if fire.has_method("set_effectiveness"):
			match current_weather:
				Weather.RAIN:
					fire.set_effectiveness(rain_fire_effectiveness)
				Weather.STORM:
					fire.set_effectiveness(rain_fire_effectiveness)
				_:
					fire.set_effectiveness(1.0)


## Get current weather as string.
func get_weather_name() -> String:
	match current_weather:
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


## Get weather icon (text-based for now).
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
	if not player or not campsite_manager:
		return false

	var player_pos: Vector3 = player.global_position

	match current_weather:
		Weather.STORM:
			return campsite_manager.is_in_shelter(player_pos)
		Weather.COLD_SNAP:
			return campsite_manager.is_near_fire(player_pos)
		_:
			return true  # No protection needed


## Get protection status text for HUD.
func get_protection_status() -> String:
	if not player or not campsite_manager:
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


## Force a specific weather (for testing).
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
