extends Node
class_name PlayerStats
## Manages player survival stats: health and hunger.

signal health_changed(new_value: float, max_value: float)
signal hunger_changed(new_value: float, max_value: float)
signal player_died()

# Stat maximums
@export var max_health: float = 100.0
@export var max_hunger: float = 100.0

# Hunger depletion rates (per second)
@export var hunger_depletion_rate: float = 0.05  # Base rate when idle (~33 min to empty)
@export var hunger_sprint_multiplier: float = 2.0  # Multiplier when sprinting

# Health effects
@export var health_drain_rate: float = 1.0  # Per second when starving
@export var health_regen_rate: float = 0.5  # Per second when hunger is full

# Current values
var health: float = 100.0
var hunger: float = 100.0

# Config toggles (set by ConfigMenu)
var hunger_depletion_enabled: bool = false
var health_drain_enabled: bool = false
var weather_damage_enabled: bool = false

# Weather effects
var hunger_multiplier: float = 1.0

# Reference to player for checking sprint state
var player: CharacterBody3D


func _ready() -> void:
	health = max_health
	hunger = max_hunger

	# Try to get player reference from parent
	var parent: Node = get_parent()
	if parent is CharacterBody3D:
		player = parent


func _process(delta: float) -> void:
	_update_hunger(delta)
	_update_health(delta)


func _update_hunger(delta: float) -> void:
	if not hunger_depletion_enabled:
		return

	var depletion: float = hunger_depletion_rate

	# Apply weather multiplier (e.g., heat wave)
	depletion *= hunger_multiplier

	# Check if player is sprinting
	if player and "is_sprinting" in player and player.is_sprinting:
		depletion *= hunger_sprint_multiplier

	var old_hunger: float = hunger
	hunger = max(0.0, hunger - depletion * delta)

	if hunger != old_hunger:
		hunger_changed.emit(hunger, max_hunger)


func _update_health(delta: float) -> void:
	var old_health: float = health

	if hunger <= 0.0 and health_drain_enabled:
		# Starving: drain health (only if enabled)
		health = max(0.0, health - health_drain_rate * delta)
	elif hunger >= max_hunger:
		# Full: regenerate health
		health = min(max_health, health + health_regen_rate * delta)

	if health != old_health:
		health_changed.emit(health, max_health)

		if health <= 0.0:
			player_died.emit()


## Restore hunger by eating food. Returns actual amount restored.
func eat(amount: float) -> float:
	var old_hunger: float = hunger
	hunger = min(max_hunger, hunger + amount)
	var restored: float = hunger - old_hunger

	if restored > 0:
		hunger_changed.emit(hunger, max_hunger)
		print("[PlayerStats] Ate food, restored %.1f hunger (now %.1f)" % [restored, hunger])

	return restored


## Take damage to health. Returns actual damage taken.
func take_damage(amount: float) -> float:
	var old_health: float = health
	health = max(0.0, health - amount)
	var damage_taken: float = old_health - health

	if damage_taken > 0:
		health_changed.emit(health, max_health)
		print("[PlayerStats] Took %.1f damage (now %.1f)" % [damage_taken, health])

		if health <= 0.0:
			player_died.emit()

	return damage_taken


## Heal health directly. Returns actual amount healed.
func heal(amount: float) -> float:
	var old_health: float = health
	health = min(max_health, health + amount)
	var healed: float = health - old_health

	if healed > 0:
		health_changed.emit(health, max_health)
		print("[PlayerStats] Healed %.1f (now %.1f)" % [healed, health])

	return healed


## Get health as a percentage (0.0 - 1.0)
func get_health_percent() -> float:
	return health / max_health


## Get hunger as a percentage (0.0 - 1.0)
func get_hunger_percent() -> float:
	return hunger / max_hunger
