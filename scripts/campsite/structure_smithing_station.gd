extends StructureBase
class_name StructureSmithingStation
## Smithing station for smelting ore into metal ingots.

signal smelting_complete(output_type: String, output_amount: int)

# Smelting configuration
const SMELT_TIME: float = 120.0  # Seconds (2 game hours at default speed)
const FUEL_REQUIRED: int = 2  # Wood per smelt

# Smelting recipes: input -> output
const SMELT_RECIPES: Dictionary = {
	"iron_ore": "metal_ingot"
}

# State
var is_smelting: bool = false
var current_ore: String = ""
var smelt_progress: float = 0.0
var has_fuel: bool = false
var player_inventory: Node = null


func _ready() -> void:
	super._ready()
	structure_type = "smithing_station"
	structure_name = "Smithing Station"
	interaction_text = "Use Smithing Station"


func _process(delta: float) -> void:
	if is_smelting and has_fuel:
		smelt_progress += delta
		if smelt_progress >= SMELT_TIME:
			_complete_smelting()


func interact(player: Node) -> bool:
	if not is_active:
		return false

	player_inventory = null
	if player.has_method("get_inventory"):
		player_inventory = player.get_inventory()

	if is_smelting:
		# Show smelting progress
		var percent: int = int((smelt_progress / SMELT_TIME) * 100)
		print("[SmithingStation] Smelting %s... %d%%" % [current_ore, percent])
		return true

	# Try to smelt ore from player inventory
	if player_inventory:
		# First check if we have fuel
		if not player_inventory.has_item("wood", FUEL_REQUIRED):
			print("[SmithingStation] Need %d wood as fuel to smelt." % FUEL_REQUIRED)
			return true

		for ore_type: String in SMELT_RECIPES:
			if player_inventory.has_item(ore_type):
				_start_smelting(ore_type)
				return true
		print("[SmithingStation] No ore to smelt. Need: iron_ore.")
	return true


func _start_smelting(ore_type: String) -> void:
	if not player_inventory:
		return
	if not player_inventory.has_item(ore_type):
		return
	if not player_inventory.has_item("wood", FUEL_REQUIRED):
		return

	# Consume ore and fuel
	player_inventory.remove_item(ore_type, 1)
	player_inventory.remove_item("wood", FUEL_REQUIRED)

	current_ore = ore_type
	is_smelting = true
	has_fuel = true
	smelt_progress = 0.0
	interaction_text = "Check Smelting Progress"
	print("[SmithingStation] Started smelting %s (using %d wood)" % [ore_type, FUEL_REQUIRED])


func _complete_smelting() -> void:
	var output_type: String = SMELT_RECIPES.get(current_ore, "metal_ingot")

	# Add output to player inventory if available
	if player_inventory:
		player_inventory.add_item(output_type, 1)
		print("[SmithingStation] Smelting complete! +1 %s" % output_type)
	else:
		print("[SmithingStation] Smelting complete! %s ready for pickup" % output_type)

	smelting_complete.emit(output_type, 1)

	# Reset state
	is_smelting = false
	has_fuel = false
	current_ore = ""
	smelt_progress = 0.0
	interaction_text = "Use Smithing Station"


func get_interaction_text() -> String:
	if is_smelting:
		var percent: int = int((smelt_progress / SMELT_TIME) * 100)
		return "Smelting %s (%d%%)" % [current_ore.capitalize().replace("_", " "), percent]
	return "Smelt Ore"
