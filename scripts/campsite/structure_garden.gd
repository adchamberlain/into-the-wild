extends StructureBase
class_name StructureGarden
## Herb garden that passively produces herbs over time.

signal herb_produced(amount: int)

# Garden configuration
const PRODUCTION_INTERVAL: float = 240.0  # Seconds (4 game hours at default speed)
const TEND_BONUS: int = 1  # Extra herbs when tending

# State
var production_timer: float = 0.0
var stored_herbs: int = 0
var can_tend: bool = true
var tend_cooldown: float = 0.0
const TEND_COOLDOWN_TIME: float = 120.0  # 2 game hours


func _ready() -> void:
	super._ready()
	structure_type = "herb_garden"
	structure_name = "Herb Garden"
	interaction_text = "Tend Garden"


func _process(delta: float) -> void:
	# Passive herb production
	production_timer += delta
	if production_timer >= PRODUCTION_INTERVAL:
		production_timer -= PRODUCTION_INTERVAL
		stored_herbs += 1
		herb_produced.emit(1)
		print("[Garden] Produced 1 herb (stored: %d)" % stored_herbs)

	# Tend cooldown
	if not can_tend:
		tend_cooldown -= delta
		if tend_cooldown <= 0:
			can_tend = true


func interact(player: Node) -> bool:
	if not is_active:
		return false

	var player_inventory: Node = null
	if player.has_method("get_inventory"):
		player_inventory = player.get_inventory()

	var collected_count: int = 0

	# Collect stored herbs (partial harvest - take what fits)
	if stored_herbs > 0 and player_inventory:
		var capacity: int = player_inventory.get_remaining_capacity("herb") if player_inventory.has_method("get_remaining_capacity") else stored_herbs
		var to_collect: int = mini(stored_herbs, capacity)
		if to_collect > 0:
			player_inventory.add_item("herb", to_collect)
			collected_count = to_collect
			stored_herbs -= to_collect
			print("[Garden] Collected %d herbs (%d left)" % [to_collect, stored_herbs])
		elif capacity <= 0:
			_show_notification("Can't carry more herbs. Store items first.", Color(1.0, 0.5, 0.5))
			return true

	# Tend the garden for bonus herbs
	if can_tend and player_inventory:
		var capacity: int = player_inventory.get_remaining_capacity("herb") if player_inventory.has_method("get_remaining_capacity") else TEND_BONUS
		if capacity >= TEND_BONUS:
			player_inventory.add_item("herb", TEND_BONUS)
			can_tend = false
			tend_cooldown = TEND_COOLDOWN_TIME
			collected_count += TEND_BONUS
			print("[Garden] Tended garden! +%d bonus herb" % TEND_BONUS)
		else:
			# Can't fit tend bonus, skip tending this time
			pass

		if collected_count > 1:
			_show_notification("Tended garden! +%d herbs" % collected_count, Color(0.4, 0.9, 0.4))
		else:
			_show_notification("Tended garden! +1 herb", Color(0.4, 0.9, 0.4))
		return true
	elif not can_tend:
		var minutes_left: int = ceili(tend_cooldown / 60.0)
		print("[Garden] Garden recently tended. Wait %d more minutes." % minutes_left)
		if collected_count > 0:
			_show_notification("Collected %d herbs. Garden needs rest." % collected_count, Color(0.9, 0.8, 0.4))
		else:
			_show_notification("Garden needs rest (%dm)" % minutes_left, Color(0.8, 0.7, 0.5))
		return true

	return true


func _show_notification(message: String, color: Color) -> void:
	var hud: Node = _find_hud()
	if hud and hud.has_method("show_notification"):
		hud.show_notification(message, color)


func _find_hud() -> Node:
	var root: Node = get_tree().root
	if root.has_node("Main/HUD"):
		return root.get_node("Main/HUD")
	return null


func get_save_data() -> Dictionary:
	var data: Dictionary = super.get_save_data()
	data["production_timer"] = production_timer
	data["stored_herbs"] = stored_herbs
	data["can_tend"] = can_tend
	data["tend_cooldown"] = tend_cooldown
	return data


func load_save_data(data: Dictionary) -> void:
	super.load_save_data(data)
	production_timer = data.get("production_timer", 0.0)
	stored_herbs = data.get("stored_herbs", 0)
	can_tend = data.get("can_tend", true)
	tend_cooldown = data.get("tend_cooldown", 0.0)


func get_interaction_text() -> String:
	if stored_herbs > 0:
		return "Collect %d Herbs" % stored_herbs
	elif can_tend:
		return "Tend Garden"
	else:
		var minutes_left: int = ceili(tend_cooldown / 60.0)
		return "Garden (wait %dm)" % minutes_left
