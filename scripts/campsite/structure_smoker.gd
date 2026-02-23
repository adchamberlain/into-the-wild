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
var pending_output: String = ""  # Product awaiting player pickup

# Visual food on racks
var food_meshes: Array[MeshInstance3D] = []


func _ready() -> void:
	super._ready()
	structure_type = "smoker"
	structure_name = "Smoker"
	interaction_text = "Use Smoker"
	call_deferred("_create_food_visuals")


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

	# Deliver pending output first
	if pending_output != "" and player_inventory:
		player_inventory.add_item(pending_output, 1)
		print("[Smoker] Collected: +1 %s" % pending_output)
		pending_output = ""
		interaction_text = "Use Smoker"
		_update_food_visuals()
		return true

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

	# Consume meat and fuel - verify both succeed
	var removed_meat: bool = player_inventory.remove_item(meat_type, 1)
	if not removed_meat:
		return
	var removed_fuel: bool = player_inventory.remove_item("wood", FUEL_REQUIRED)
	if not removed_fuel:
		# Refund the meat if fuel removal failed
		player_inventory.add_item(meat_type, 1)
		return

	current_meat = meat_type
	is_smoking = true
	has_fuel = true
	smoke_progress = 0.0
	interaction_text = "Check Smoking Progress"
	_update_food_visuals()
	print("[Smoker] Started smoking %s (using %d wood)" % [meat_type, FUEL_REQUIRED])


func _complete_smoking() -> void:
	var output_type: String = SMOKE_RECIPES.get(current_meat, "smoked_meat")
	pending_output = output_type
	smoking_complete.emit(output_type, 1)
	# Reset smoking state but keep pending_output
	is_smoking = false
	has_fuel = false
	current_meat = ""
	smoke_progress = 0.0
	interaction_text = "Collect Smoked Food"
	_update_food_visuals()
	# Notify player via HUD
	var hud: Node = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_notification"):
		hud.show_notification("Smoker finished! Collect your food.", Color(1, 0.85, 0.3, 1))


func get_save_data() -> Dictionary:
	var data: Dictionary = super.get_save_data()
	data["is_smoking"] = is_smoking
	data["current_meat"] = current_meat
	data["smoke_progress"] = smoke_progress
	data["has_fuel"] = has_fuel
	data["pending_output"] = pending_output
	return data


func load_save_data(data: Dictionary) -> void:
	super.load_save_data(data)
	is_smoking = data.get("is_smoking", false)
	current_meat = data.get("current_meat", "")
	smoke_progress = data.get("smoke_progress", 0.0)
	has_fuel = data.get("has_fuel", false)
	pending_output = data.get("pending_output", "")
	if pending_output != "":
		interaction_text = "Collect Smoked Food"
	elif is_smoking:
		interaction_text = "Check Smoking Progress"
	call_deferred("_update_food_visuals")


func get_interaction_text() -> String:
	if pending_output != "":
		return "Collect Smoked Food"
	if is_smoking:
		var percent: int = int((smoke_progress / SMOKE_TIME) * 100)
		return "Smoking %s (%d%%)" % [current_meat.capitalize().replace("_", " "), percent]
	# Check if player has meat to smoke
	var p: Node = get_tree().get_first_node_in_group("player")
	if p and p.has_method("get_inventory"):
		var inv: Node = p.get_inventory()
		if inv:
			var has_meat: bool = false
			for meat_type: String in SMOKE_RECIPES:
				if inv.has_item(meat_type):
					has_meat = true
					break
			if not has_meat:
				return "Need Meat to Smoke"
			if not inv.has_item("wood", FUEL_REQUIRED):
				return "Need Wood to Smoke"
	return "Smoke Meat"


func _create_food_visuals() -> void:
	# Create meat/fish pieces on both racks, hidden by default
	# Rack positions match placement_system: y=0.8 and y=1.15
	var food_mat: StandardMaterial3D = StandardMaterial3D.new()
	food_mat.albedo_color = Color(0.6, 0.25, 0.2)  # Default raw meat color

	# Positions for food pieces on the racks (offset from center)
	var rack_ys: Array[float] = [0.85, 1.2]
	var offsets: Array[float] = [-0.2, 0.0, 0.2]

	for rack_y: float in rack_ys:
		for off_x: float in offsets:
			# Food piece (flat slab hanging below rack)
			var piece: MeshInstance3D = MeshInstance3D.new()
			var piece_mesh: BoxMesh = BoxMesh.new()
			piece_mesh.size = Vector3(0.12, 0.15, 0.08)
			piece.mesh = piece_mesh
			piece.position = Vector3(off_x, rack_y - 0.08, 0)
			piece.material_override = food_mat
			piece.visible = false
			piece.name = "FoodPiece"
			add_child(piece)
			food_meshes.append(piece)


func _update_food_visuals() -> void:
	var show_food: bool = is_smoking or pending_output != ""
	# Pick color based on what's being smoked
	var is_fish: bool = current_meat == "fish" or pending_output == "smoked_fish"
	var target_color: Color
	if pending_output != "":
		# Finished product - darker smoked color
		target_color = Color(0.35, 0.22, 0.15) if not is_fish else Color(0.4, 0.35, 0.25)
	elif is_fish:
		target_color = Color(0.55, 0.6, 0.65)  # Silvery fish
	else:
		target_color = Color(0.6, 0.25, 0.2)  # Raw reddish meat

	for piece: MeshInstance3D in food_meshes:
		if not is_instance_valid(piece):
			continue
		piece.visible = show_food
		if show_food and piece.material_override:
			piece.material_override.albedo_color = target_color
