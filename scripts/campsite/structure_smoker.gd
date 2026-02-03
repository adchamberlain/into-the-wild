extends StructureBase
class_name StructureSmoker
## Smoker structure for preserving meat into smoked meat.

signal smoking_complete(output_type: String, output_amount: int)

# Smoking configuration
const SMOKE_TIME: float = 180.0  # Seconds (3 game hours at default speed)
const FUEL_REQUIRED: int = 1  # Wood per smoke cycle

# Smoking recipes: input -> output
const SMOKE_RECIPES: Dictionary = {
	"raw_meat": "smoked_meat",
	"fish": "smoked_fish"
}

# State
var is_smoking: bool = false
var current_meat: String = ""
var smoke_progress: float = 0.0
var has_fuel: bool = false
var player_inventory: Node = null


func _ready() -> void:
	super._ready()
	structure_type = "smoker"
	structure_name = "Smoker"
	interaction_text = "Use Smoker"


func _process(delta: float) -> void:
	if is_smoking and has_fuel:
		smoke_progress += delta
		if smoke_progress >= SMOKE_TIME:
			_complete_smoking()


func interact(player: Node) -> bool:
	if not is_active:
		return false

	player_inventory = null
	if player.has_method("get_inventory"):
		player_inventory = player.get_inventory()

	if is_smoking:
		# Show smoking progress
		var percent: int = int((smoke_progress / SMOKE_TIME) * 100)
		print("[Smoker] Smoking %s... %d%%" % [current_meat, percent])
		return true

	# Try to smoke meat from player inventory
	if player_inventory:
		# First check if we have fuel
		if not player_inventory.has_item("wood", FUEL_REQUIRED):
			print("[Smoker] Need %d wood as fuel to smoke." % FUEL_REQUIRED)
			return true

		for meat_type: String in SMOKE_RECIPES:
			if player_inventory.has_item(meat_type):
				_start_smoking(meat_type)
				return true
		print("[Smoker] No meat to smoke. Need: raw_meat or fish.")
	return true


func _start_smoking(meat_type: String) -> void:
	if not player_inventory:
		return
	if not player_inventory.has_item(meat_type):
		return
	if not player_inventory.has_item("wood", FUEL_REQUIRED):
		return

	# Consume meat and fuel
	player_inventory.remove_item(meat_type, 1)
	player_inventory.remove_item("wood", FUEL_REQUIRED)

	current_meat = meat_type
	is_smoking = true
	has_fuel = true
	smoke_progress = 0.0
	interaction_text = "Check Smoking Progress"
	print("[Smoker] Started smoking %s (using %d wood)" % [meat_type, FUEL_REQUIRED])


func _complete_smoking() -> void:
	var output_type: String = SMOKE_RECIPES.get(current_meat, "smoked_meat")

	# Add output to player inventory if available
	if player_inventory:
		player_inventory.add_item(output_type, 1)
		print("[Smoker] Smoking complete! +1 %s" % output_type)
	else:
		print("[Smoker] Smoking complete! %s ready for pickup" % output_type)

	smoking_complete.emit(output_type, 1)

	# Reset state
	is_smoking = false
	has_fuel = false
	current_meat = ""
	smoke_progress = 0.0
	interaction_text = "Use Smoker"


func get_interaction_text() -> String:
	if is_smoking:
		var percent: int = int((smoke_progress / SMOKE_TIME) * 100)
		return "Smoking %s (%d%%)" % [current_meat.capitalize().replace("_", " "), percent]
	return "Smoke Meat"
