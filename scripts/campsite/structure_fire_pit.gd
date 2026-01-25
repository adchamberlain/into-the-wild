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

# Fuel system (1 day = 1200 seconds at default 20min day length)
@export var max_fuel: float = 1200.0  # 1 game day of burn time
@export var fuel_burn_rate: float = 1.0  # Fuel units per second
var fuel_remaining: float = 1200.0
var unlimited_fuel: bool = false  # Set by config menu

# State
var is_lit: bool = true
var effectiveness: float = 1.0  # Reduced by rain/storm
var base_light_energy: float = 3.0

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

	# Store base light energy
	base_light_energy = light_energy

	# Start lit with full fuel
	fuel_remaining = max_fuel
	_set_fire_state(true)


func _process(delta: float) -> void:
	# Skip fuel burning if unlimited
	if unlimited_fuel:
		return

	# Burn fuel if lit
	if is_lit and fuel_remaining > 0:
		fuel_remaining -= fuel_burn_rate * delta

		# Fire dims as fuel runs low (below 30%)
		if fuel_remaining < max_fuel * 0.3 and fire_light:
			var dim_factor: float = fuel_remaining / (max_fuel * 0.3)
			fire_light.light_energy = base_light_energy * effectiveness * (0.5 + 0.5 * dim_factor)

		# Fire goes out when no fuel
		if fuel_remaining <= 0:
			fuel_remaining = 0
			extinguish()
			print("[FirePit] The fire has burned out - add wood!")


func interact(player: Node) -> bool:
	if not is_active:
		return false

	if not is_lit:
		# Light the fire (requires some fuel or wood)
		if fuel_remaining > 0 or unlimited_fuel:
			_set_fire_state(true)
			flare()
			_show_notification("Fire lit!", Color(1.0, 0.7, 0.3))
			return true
		else:
			# Need wood to light
			var inventory: Node = null
			if player.has_method("get_inventory"):
				inventory = player.get_inventory()
			if inventory and inventory.has_item("wood"):
				inventory.remove_item("wood", 1)
				fuel_remaining = max_fuel  # 1 day of fuel
				_set_fire_state(true)
				flare()
				_show_notification("Fire lit with wood!", Color(1.0, 0.7, 0.3))
				return true
			else:
				_show_notification("Need wood to light fire!", Color(1.0, 0.4, 0.4))
				return false

	# Open fire menu
	var fire_menu: Node = _find_fire_menu()
	if fire_menu and fire_menu.has_method("open_menu"):
		fire_menu.open_menu(self)
	else:
		# Fallback to basic warm up
		if player.has_node("PlayerStats"):
			var stats: Node = player.get_node("PlayerStats")
			if stats.has_method("heal"):
				stats.heal(15.0)
				flare()
				_show_notification("Warmed up! +15 Health", Color(1.0, 0.8, 0.4))

	return true


func get_interaction_text() -> String:
	if is_lit:
		return "Use Fire"
	else:
		return "Light Fire"


func _find_fire_menu() -> Node:
	var root: Node = get_tree().root
	if root.has_node("Main/FireMenu"):
		return root.get_node("Main/FireMenu")
	var menus: Array = get_tree().get_nodes_in_group("fire_menu")
	if not menus.is_empty():
		return menus[0]
	return null


func _show_notification(message: String, color: Color) -> void:
	var hud: Node = _find_hud()
	if hud and hud.has_method("show_notification"):
		hud.show_notification(message, color)


func _find_hud() -> Node:
	var root: Node = get_tree().root
	if root.has_node("Main/HUD"):
		return root.get_node("Main/HUD")
	return null


## Add fuel to the fire (1 wood = 1 day of burn time).
func add_fuel(amount: float = -1.0) -> void:
	if amount < 0:
		amount = max_fuel  # Default to 1 day
	fuel_remaining = min(fuel_remaining + amount, max_fuel * 2)  # Allow up to 2 days stockpile
	var days_remaining: float = fuel_remaining / max_fuel
	print("[FirePit] Fuel added. Remaining: %.1f days" % days_remaining)


## Visual flare effect - briefly increases light intensity.
func flare() -> void:
	if not fire_light or not is_lit:
		return

	var original_energy: float = fire_light.light_energy
	var flare_energy: float = original_energy * 2.0

	var tween: Tween = create_tween()
	tween.tween_property(fire_light, "light_energy", flare_energy, 0.1)
	tween.tween_property(fire_light, "light_energy", original_energy, 0.4)


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
