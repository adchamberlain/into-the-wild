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
var pending_output: String = ""  # Product awaiting player pickup


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

	# Deliver pending output first
	if pending_output != "" and player_inventory:
		player_inventory.add_item(pending_output, 1)
		print("[SmithingStation] Collected: +1 %s" % pending_output)
		pending_output = ""
		interaction_text = "Use Smithing Station"
		return true

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
	var removed_ore: bool = player_inventory.remove_item(ore_type, 1)
	if not removed_ore:
		return
	var removed_fuel: bool = player_inventory.remove_item("wood", FUEL_REQUIRED)
	if not removed_fuel:
		player_inventory.add_item(ore_type, 1)  # Refund ore
		return

	current_ore = ore_type
	is_smelting = true
	has_fuel = true
	smelt_progress = 0.0
	interaction_text = "Check Smelting Progress"
	print("[SmithingStation] Started smelting %s (using %d wood)" % [ore_type, FUEL_REQUIRED])


func _complete_smelting() -> void:
	var output_type: String = SMELT_RECIPES.get(current_ore, "metal_ingot")

	# Find player inventory fresh (cached reference may be stale after save/load)
	if not is_instance_valid(player_inventory):
		var p: Node = get_tree().get_first_node_in_group("player")
		if p and p.has_method("get_inventory"):
			player_inventory = p.get_inventory()

	# Add output to player inventory
	if is_instance_valid(player_inventory):
		player_inventory.add_item(output_type, 1)
		print("[SmithingStation] Smelting complete! +1 %s" % output_type)
	else:
		# Store product for later pickup instead of losing it
		pending_output = output_type
		print("[SmithingStation] Smelting complete! %s stored for pickup" % output_type)

	smelting_complete.emit(output_type, 1)

	# Reset state
	is_smelting = false
	has_fuel = false
	current_ore = ""
	smelt_progress = 0.0
	interaction_text = "Collect Ingot" if pending_output != "" else "Use Smithing Station"


func get_save_data() -> Dictionary:
	var data: Dictionary = super.get_save_data()
	data["is_smelting"] = is_smelting
	data["current_ore"] = current_ore
	data["smelt_progress"] = smelt_progress
	data["has_fuel"] = has_fuel
	data["pending_output"] = pending_output
	return data


func load_save_data(data: Dictionary) -> void:
	super.load_save_data(data)
	is_smelting = data.get("is_smelting", false)
	current_ore = data.get("current_ore", "")
	smelt_progress = data.get("smelt_progress", 0.0)
	has_fuel = data.get("has_fuel", false)
	pending_output = data.get("pending_output", "")
	if pending_output != "":
		interaction_text = "Collect Ingot"
	elif is_smelting:
		interaction_text = "Check Smelting Progress"


func get_interaction_text() -> String:
	if pending_output != "":
		return "Collect Ingot"
	if is_smelting:
		var percent: int = int((smelt_progress / SMELT_TIME) * 100)
		return "Smelting %s (%d%%)" % [current_ore.capitalize().replace("_", " "), percent]
	# Check if player has ore and fuel
	var p: Node = get_tree().get_first_node_in_group("player")
	if p and p.has_method("get_inventory"):
		var inv: Node = p.get_inventory()
		if inv:
			var has_ore: bool = false
			for ore_type: String in SMELT_RECIPES:
				if inv.has_item(ore_type):
					has_ore = true
					break
			if not has_ore:
				return "Need Ore to Smelt"
			if not inv.has_item("wood", FUEL_REQUIRED):
				return "Need Wood to Smelt"
	return "Smelt Ore"
