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

	# Collect stored herbs
	if stored_herbs > 0 and player_inventory:
		player_inventory.add_item("herb", stored_herbs)
		print("[Garden] Collected %d herbs" % stored_herbs)
		stored_herbs = 0

	# Tend the garden for bonus herbs
	if can_tend and player_inventory:
		player_inventory.add_item("herb", TEND_BONUS)
		can_tend = false
		tend_cooldown = TEND_COOLDOWN_TIME
		print("[Garden] Tended garden! +%d bonus herb" % TEND_BONUS)
		return true
	elif not can_tend:
		var minutes_left: int = int(tend_cooldown / 60)
		print("[Garden] Garden recently tended. Wait %d more minutes." % minutes_left)
		return true

	return true


func get_interaction_text() -> String:
	if stored_herbs > 0:
		return "Collect %d Herbs" % stored_herbs
	elif can_tend:
		return "Tend Garden"
	else:
		var minutes_left: int = int(tend_cooldown / 60) + 1
		return "Garden (wait %dm)" % minutes_left
