extends StructureBase
class_name StructureSnareTrap
## Snare trap for catching small game (rabbits, birds).

signal animal_caught(animal_type: String, loot: Dictionary)

# Bait items that can be used
const VALID_BAIT: Array[String] = ["berry", "mushroom", "herb"]

# Catch chances and loot tables
const CATCH_CHANCE: float = 0.15  # 15% chance per check
const CHECK_INTERVAL: float = 60.0  # Check every game hour (60 seconds at default speed)

# Catch table: type -> {weight, loot: {item: amount}}
const CATCH_TABLE: Dictionary = {
	"rabbit": {
		"weight": 70,  # 70% of catches
		"loot": {
			"raw_meat": 2,
			"hide": 1
		}
	},
	"bird": {
		"weight": 30,  # 30% of catches
		"loot": {
			"raw_meat": 1,
			"feathers": 2
		}
	}
}

# State
var is_baited: bool = false
var bait_type: String = ""
var has_catch: bool = false
var catch_type: String = ""
var catch_loot: Dictionary = {}
var check_timer: float = 0.0
var player_inventory: Node = null


func _ready() -> void:
	super._ready()
	structure_type = "snare_trap"
	structure_name = "Snare Trap"
	interaction_text = "Check Trap"


func _process(delta: float) -> void:
	# Only check for catches when baited and no catch yet
	if is_baited and not has_catch:
		check_timer += delta
		if check_timer >= CHECK_INTERVAL:
			check_timer = 0.0
			_check_for_catch()


func interact(player: Node) -> bool:
	if not is_active:
		return false

	player_inventory = null
	if player.has_method("get_inventory"):
		player_inventory = player.get_inventory()

	# If there's a catch, collect it
	if has_catch:
		_collect_catch()
		return true

	# If baited, just show status
	if is_baited:
		print("[SnareTrap] Trap is baited with %s. Waiting for prey..." % bait_type)
		return true

	# Try to bait the trap
	if player_inventory:
		for bait: String in VALID_BAIT:
			if player_inventory.has_item(bait):
				_set_bait(bait)
				return true
		print("[SnareTrap] Need bait to set trap. Use: berries, mushrooms, or herbs.")
	return true


func _set_bait(bait: String) -> void:
	if not player_inventory or not player_inventory.has_item(bait):
		return

	player_inventory.remove_item(bait, 1)
	bait_type = bait
	is_baited = true
	check_timer = 0.0
	interaction_text = "Check Trap"
	print("[SnareTrap] Trap baited with %s" % bait)


func _check_for_catch() -> void:
	if not is_baited or has_catch:
		return

	var roll: float = randf()
	if roll < CATCH_CHANCE:
		# Success! Determine what we caught
		_make_catch()


func _make_catch() -> void:
	# Roll for catch type based on weights
	var total_weight: int = 0
	for animal: String in CATCH_TABLE:
		total_weight += CATCH_TABLE[animal]["weight"]

	var roll: int = randi() % total_weight
	var cumulative: int = 0

	for animal: String in CATCH_TABLE:
		cumulative += CATCH_TABLE[animal]["weight"]
		if roll < cumulative:
			catch_type = animal
			catch_loot = CATCH_TABLE[animal]["loot"].duplicate()
			break

	has_catch = true
	is_baited = false  # Bait consumed
	bait_type = ""
	interaction_text = "Collect Catch"
	print("[SnareTrap] Caught a %s!" % catch_type)


func _collect_catch() -> void:
	if not has_catch:
		return

	# Add loot to player inventory
	if player_inventory:
		for item: String in catch_loot:
			var amount: int = catch_loot[item]
			player_inventory.add_item(item, amount)
			print("[SnareTrap] +%d %s" % [amount, item])

	animal_caught.emit(catch_type, catch_loot)

	# Reset state
	has_catch = false
	catch_type = ""
	catch_loot = {}
	interaction_text = "Bait Trap"
	print("[SnareTrap] Trap reset. Add bait to catch more.")


func get_interaction_text() -> String:
	if has_catch:
		return "Collect %s" % catch_type.capitalize()
	elif is_baited:
		return "Trap baited (%s)" % bait_type.capitalize()
	return "Bait Trap"
