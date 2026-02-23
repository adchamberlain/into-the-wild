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

# Visual food on racks
var food_meshes: Array[MeshInstance3D] = []

# Food type colors
const FOOD_COLORS: Dictionary = {
	"fish": Color(0.55, 0.6, 0.65),       # Silvery
	"berry": Color(0.45, 0.15, 0.3),       # Dark berry purple
	"mushroom": Color(0.55, 0.45, 0.35),   # Tan-brown
	"herb": Color(0.3, 0.5, 0.25),         # Green
}
const DRIED_COLOR: Color = Color(0.4, 0.3, 0.2)  # Generic dried brown


func _ready() -> void:
	super._ready()
	structure_type = "drying_rack"
	structure_name = "Drying Rack"
	interaction_text = "Use Drying Rack"
	call_deferred("_create_food_visuals")


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
		_update_food_visuals()
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
	_update_food_visuals()
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
	_update_food_visuals()


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
	call_deferred("_update_food_visuals")


func get_interaction_text() -> String:
	if pending_output != "":
		return "Collect Dried Food"
	if is_drying:
		var percent: int = int((drying_progress / DRYING_TIME) * 100)
		return "Drying %s (%d%%)" % [current_food.capitalize(), percent]
	# Check if player has food to dry
	var p: Node = get_tree().get_first_node_in_group("player")
	if p and p.has_method("get_inventory"):
		var inv: Node = p.get_inventory()
		if inv:
			for food_type: String in DRYING_RECIPES:
				if inv.has_item(food_type):
					return "Dry Food"
			return "Need Food to Dry"
	return "Dry Food"


func _create_food_visuals() -> void:
	# Create food pieces on the rack bars, hidden by default
	# Bar positions from placement_system: y=0.4, y=0.75, y=1.1
	var food_mat: StandardMaterial3D = StandardMaterial3D.new()
	food_mat.albedo_color = Color(0.55, 0.28, 0.22)

	# Strips on top two bars (hanging below)
	var bar_ys: Array[float] = [1.1, 0.75]
	var strip_mesh: BoxMesh = BoxMesh.new()
	strip_mesh.size = Vector3(0.08, 0.18, 0.03)

	for bar_y: float in bar_ys:
		var count: int = 4 if bar_y > 1.0 else 3
		var spread: float = 0.25
		var start_x: float = -(count - 1) * spread / 2.0
		for i: int in range(count):
			var piece: MeshInstance3D = MeshInstance3D.new()
			piece.mesh = strip_mesh
			piece.position = Vector3(start_x + i * spread, bar_y - 0.1, 0)
			piece.material_override = food_mat
			piece.visible = false
			piece.name = "FoodPiece"
			add_child(piece)
			food_meshes.append(piece)


func _update_food_visuals() -> void:
	var show_food: bool = is_drying or pending_output != ""
	# Pick color based on food type
	var target_color: Color
	if pending_output != "":
		target_color = DRIED_COLOR
	elif FOOD_COLORS.has(current_food):
		target_color = FOOD_COLORS[current_food]
	else:
		target_color = Color(0.55, 0.28, 0.22)

	for piece: MeshInstance3D in food_meshes:
		if not is_instance_valid(piece):
			continue
		piece.visible = show_food
		if show_food and piece.material_override:
			piece.material_override.albedo_color = target_color
