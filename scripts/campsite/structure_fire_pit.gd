extends StructureBase
class_name StructureFirePit
## Fire pit structure that provides warmth and light.

signal fire_lit()
signal fire_extinguished()

# Fire properties
@export var warmth_radius: float = 5.0
@export var base_warmth_radius: float = 5.0
@export var light_energy: float = 3.0
@export var light_range: float = 8.0

# State
var is_lit: bool = true
var effectiveness: float = 1.0  # Reduced by rain/storm

# Node references (set after scene instantiation)
var fire_light: OmniLight3D
var fire_mesh: MeshInstance3D
var warmth_area: Area3D


func _ready() -> void:
	super._ready()
	structure_type = "fire_pit"
	structure_name = "Fire Pit"
	interaction_text = "Tend Fire"

	# Find child nodes
	fire_light = get_node_or_null("FireLight")
	fire_mesh = get_node_or_null("FireMesh")
	warmth_area = get_node_or_null("WarmthArea")

	# Start lit
	_set_fire_state(true)


func interact(player: Node) -> bool:
	if not super.interact(player):
		return false

	if not is_lit:
		# Light the fire
		_set_fire_state(true)
		print("[FirePit] You light the fire")
		return true

	# Warm up by the fire - restore health
	if player.has_node("PlayerStats"):
		var stats: Node = player.get_node("PlayerStats")
		if stats.has_method("heal"):
			stats.heal(15.0)
			print("[FirePit] You warm yourself by the fire (+15 health)")
	else:
		print("[FirePit] The fire crackles warmly")

	return true


func get_interaction_text() -> String:
	if is_lit:
		return "Tend Fire"
	else:
		return "Light Fire"


func _set_fire_state(lit: bool) -> void:
	is_lit = lit

	if fire_light:
		fire_light.visible = lit
	if fire_mesh:
		fire_mesh.visible = lit

	if lit:
		fire_lit.emit()
	else:
		fire_extinguished.emit()


## Check if a position is within warmth radius.
func is_in_warmth_range(pos: Vector3) -> bool:
	return global_position.distance_to(pos) <= warmth_radius


## Get warmth value at a position (1.0 at center, 0.0 at edge).
func get_warmth_at(pos: Vector3) -> float:
	if not is_lit:
		return 0.0
	var distance: float = global_position.distance_to(pos)
	if distance > warmth_radius:
		return 0.0
	return (1.0 - (distance / warmth_radius)) * effectiveness


## Set fire effectiveness (reduced by rain/weather).
func set_effectiveness(value: float) -> void:
	effectiveness = clampf(value, 0.0, 1.0)
	warmth_radius = base_warmth_radius * effectiveness

	# Adjust light intensity based on effectiveness
	if fire_light and is_lit:
		fire_light.light_energy = light_energy * effectiveness

	print("[FirePit] Effectiveness set to %.0f%%" % (effectiveness * 100))


## Extinguish the fire (called by storm).
func extinguish() -> void:
	if is_lit:
		_set_fire_state(false)
		print("[FirePit] Fire has been extinguished!")


## Tend the fire - resets storm timer and relights if needed.
func tend_fire() -> void:
	if not is_lit:
		_set_fire_state(true)
		print("[FirePit] You relight the fire")
	else:
		print("[FirePit] You tend the fire, keeping it alive")
