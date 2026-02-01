extends StructureShelter
class_name StructureCanvasTent
## Upgraded canvas tent with better protection and comfort.

# Canvas tent provides better bonuses than basic shelter
const CANVAS_TENT_PROTECTION_RADIUS: float = 4.0
const CANVAS_TENT_WEATHER_REDUCTION: float = 0.5  # 50% weather damage reduction
const SLEEP_HUNGER_RESTORE: float = 50.0  # More hunger restored than basic shelter


func _ready() -> void:
	super._ready()
	structure_type = "canvas_tent"
	structure_name = "Canvas Tent"
	interaction_text = "Rest in Tent"
	protection_radius = CANVAS_TENT_PROTECTION_RADIUS


func _skip_to_dawn(player: Node, time_manager: Node) -> void:
	# Set time to 6 AM (dawn)
	time_manager.current_hour = 6
	time_manager.current_minute = 0
	time_manager._update_period()
	time_manager.time_changed.emit(time_manager.current_hour, time_manager.current_minute)

	# Full heal and better hunger restore in canvas tent
	if player.has_node("PlayerStats"):
		var stats: Node = player.get_node("PlayerStats")
		if stats.has_method("heal"):
			stats.heal(stats.max_health)  # Full health restore
		if "hunger" in stats and "max_hunger" in stats:
			stats.hunger = min(stats.hunger + SLEEP_HUNGER_RESTORE, stats.max_hunger)
			stats.hunger_changed.emit(stats.hunger, stats.max_hunger)

	resting_started.emit(player)
	print("[CanvasTent] You wake at dawn, fully rested (+100% health, +50 hunger)")


func get_interaction_text() -> String:
	if is_player_resting:
		return "Get Up"
	return "Rest in Tent"


## Get weather damage reduction factor.
func get_weather_protection() -> float:
	return CANVAS_TENT_WEATHER_REDUCTION
