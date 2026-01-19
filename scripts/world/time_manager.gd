extends Node
## Manages the day/night cycle and emits signals when time periods change.

signal time_changed(hour: int, minute: int)
signal period_changed(period: String)

enum TimePeriod { DAWN, MORNING, AFTERNOON, EVENING, DUSK, NIGHT }

# Time settings
@export var day_length_minutes: float = 20.0  # Real minutes per game day
@export var start_hour: int = 8  # Game starts at 8 AM

# Current time state
var current_hour: int = 8
var current_minute: int = 0
var current_period: TimePeriod = TimePeriod.MORNING

# Internal tracking
var _time_accumulator: float = 0.0
var _seconds_per_game_minute: float


func _ready() -> void:
	current_hour = start_hour
	_seconds_per_game_minute = (day_length_minutes * 60.0) / (24.0 * 60.0)
	_update_period()


func _process(delta: float) -> void:
	_time_accumulator += delta

	if _time_accumulator >= _seconds_per_game_minute:
		_time_accumulator -= _seconds_per_game_minute
		_advance_minute()


func _advance_minute() -> void:
	current_minute += 1

	if current_minute >= 60:
		current_minute = 0
		current_hour += 1

		if current_hour >= 24:
			current_hour = 0

	time_changed.emit(current_hour, current_minute)
	_update_period()


func _update_period() -> void:
	var old_period: TimePeriod = current_period

	# Determine time period based on hour
	if current_hour >= 5 and current_hour < 7:
		current_period = TimePeriod.DAWN
	elif current_hour >= 7 and current_hour < 12:
		current_period = TimePeriod.MORNING
	elif current_hour >= 12 and current_hour < 17:
		current_period = TimePeriod.AFTERNOON
	elif current_hour >= 17 and current_hour < 19:
		current_period = TimePeriod.EVENING
	elif current_hour >= 19 and current_hour < 21:
		current_period = TimePeriod.DUSK
	else:
		current_period = TimePeriod.NIGHT

	if current_period != old_period:
		period_changed.emit(get_period_name())


func get_period_name() -> String:
	match current_period:
		TimePeriod.DAWN:
			return "Dawn"
		TimePeriod.MORNING:
			return "Morning"
		TimePeriod.AFTERNOON:
			return "Afternoon"
		TimePeriod.EVENING:
			return "Evening"
		TimePeriod.DUSK:
			return "Dusk"
		TimePeriod.NIGHT:
			return "Night"
	return "Unknown"


func get_time_string() -> String:
	var hour_12: int = current_hour % 12
	if hour_12 == 0:
		hour_12 = 12
	var am_pm: String = "AM" if current_hour < 12 else "PM"
	return "%d:%02d %s" % [hour_12, current_minute, am_pm]


func get_day_progress() -> float:
	## Returns 0.0 at midnight, 0.5 at noon, 1.0 at next midnight
	return (current_hour * 60.0 + current_minute) / (24.0 * 60.0)


func get_sun_angle() -> float:
	## Returns sun angle in radians. 0 at sunrise, PI/2 at noon, PI at sunset
	var progress: float = get_day_progress()
	# Sun rises at 6 AM (0.25) and sets at 18 PM (0.75)
	var sun_progress: float = clampf((progress - 0.25) / 0.5, 0.0, 1.0)
	return sun_progress * PI


func is_daytime() -> bool:
	return current_hour >= 6 and current_hour < 20
