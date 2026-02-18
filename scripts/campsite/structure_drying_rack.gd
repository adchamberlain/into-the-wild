extends StructureBase
class_name StructureDryingRack
## Food drying rack for preserving food.

signal food_dried(food_type: String, dried_type: String)

# Drying configuration
const DRYING_RECIPES: Dictionary = {
	"fish": "dried_fish",
	"berry": "dried_berries",
	"mushroom": "dried_mushroom",
	"herb": "dried_herb"
}
const DRYING_TIME: float = 60.0  # Seconds (1 game hour at default speed)

# State
var is_drying: bool = false
var current_food: String = ""
var drying_progress: float = 0.0
var player_inventory: Node = null
var pending_output: String = ""  # Product awaiting player pickup


func _ready() -> void:
	super._ready()
	structure_type = "drying_rack"
	structure_name = "Drying Rack"
	interaction_text = "Use Drying Rack"


func _process(delta: float) -> void:
	if is_drying:
		drying_progress += delta
		if drying_progress >= DRYING_TIME:
			_complete_drying()


func interact(player: Node) -> bool:
	if not is_active:
		return false

	player_inventory = null
	if player.has_method("get_inventory"):
		player_inventory = player.get_inventory()

	# Deliver pending output first
	if pending_output != "" and player_inventory:
		player_inventory.add_item(pending_output, 1)
		print("[DryingRack] Collected: +1 %s" % pending_output)
		pending_output = ""
		interaction_text = "Use Drying Rack"
		return true

	if is_drying:
		# Show drying progress
		var percent: int = int((drying_progress / DRYING_TIME) * 100)
		print("[DryingRack] Drying %s... %d%%" % [current_food, percent])
		return true

	# Try to dry food from player inventory
	if player_inventory:
		for food_type: String in DRYING_RECIPES:
			if player_inventory.has_item(food_type):
				_start_drying(food_type)
				return true
		print("[DryingRack] No food to dry. Need: fish, berries, mushrooms, or herbs.")
	return true


func _start_drying(food_type: String) -> void:
	if not player_inventory or not player_inventory.has_item(food_type):
		return

	var removed: bool = player_inventory.remove_item(food_type, 1)
	if not removed:
		return
	current_food = food_type
	is_drying = true
	drying_progress = 0.0
	interaction_text = "Check Drying Progress"
	print("[DryingRack] Started drying %s" % food_type)


func _complete_drying() -> void:
	var dried_type: String = DRYING_RECIPES.get(current_food, "dried_food")

	# Find player inventory fresh (cached reference may be stale after save/load)
	if not is_instance_valid(player_inventory):
		var p: Node = get_tree().get_first_node_in_group("player")
		if p and p.has_method("get_inventory"):
			player_inventory = p.get_inventory()

	# Add dried food to player inventory
	if is_instance_valid(player_inventory):
		player_inventory.add_item(dried_type, 1)
		print("[DryingRack] Drying complete! +1 %s" % dried_type)
	else:
		# Store product for later pickup instead of losing it
		pending_output = dried_type
		print("[DryingRack] Drying complete! %s stored for pickup" % dried_type)

	food_dried.emit(current_food, dried_type)

	# Reset state
	is_drying = false
	current_food = ""
	drying_progress = 0.0
	interaction_text = "Collect Dried Food" if pending_output != "" else "Use Drying Rack"


func get_save_data() -> Dictionary:
	var data: Dictionary = super.get_save_data()
	data["is_drying"] = is_drying
	data["current_food"] = current_food
	data["drying_progress"] = drying_progress
	data["pending_output"] = pending_output
	return data


func load_save_data(data: Dictionary) -> void:
	super.load_save_data(data)
	is_drying = data.get("is_drying", false)
	current_food = data.get("current_food", "")
	drying_progress = data.get("drying_progress", 0.0)
	pending_output = data.get("pending_output", "")
	if pending_output != "":
		interaction_text = "Collect Dried Food"
	elif is_drying:
		interaction_text = "Check Drying Progress"


func get_interaction_text() -> String:
	if is_drying:
		var percent: int = int((drying_progress / DRYING_TIME) * 100)
		return "Drying %s (%d%%)" % [current_food.capitalize(), percent]
	return "Dry Food"
