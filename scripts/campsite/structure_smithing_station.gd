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

# Visual references (found in _ready from placement_system children)
var fire_mesh: MeshInstance3D
var forge_light: OmniLight3D
var ore_mesh: MeshInstance3D
var ore_material: StandardMaterial3D
var fire_material: StandardMaterial3D


func _ready() -> void:
	super._ready()
	structure_type = "smithing_station"
	structure_name = "Smithing Station"
	interaction_text = "Use Smithing Station"
	call_deferred("_setup_visuals")


func _setup_visuals() -> void:
	# Find the fire mesh and light created by placement_system
	for child: Node in get_children():
		if child is OmniLight3D:
			forge_light = child as OmniLight3D
		elif child is MeshInstance3D:
			var mi: MeshInstance3D = child as MeshInstance3D
			if mi.material_override and mi.material_override is StandardMaterial3D:
				var mat: StandardMaterial3D = mi.material_override as StandardMaterial3D
				if mat.emission_enabled:
					fire_mesh = mi
					fire_material = mat

	# Create ore/ingot mesh that sits on the forge
	ore_material = StandardMaterial3D.new()
	ore_material.albedo_color = Color(0.5, 0.35, 0.3)

	ore_mesh = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(0.2, 0.15, 0.2)
	ore_mesh.mesh = mesh
	ore_mesh.position = Vector3(0, 0.98, 0)
	ore_mesh.material_override = ore_material
	ore_mesh.visible = false
	add_child(ore_mesh)

	# Set initial visual state
	_update_forge_visuals()


func _process(delta: float) -> void:
	if is_smelting and has_fuel:
		smelt_progress += delta
		if smelt_progress >= SMELT_TIME:
			_complete_smelting()
		else:
			_update_smelting_visuals()


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
		_update_forge_visuals()
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
	_update_forge_visuals()
	print("[SmithingStation] Started smelting %s (using %d wood)" % [ore_type, FUEL_REQUIRED])


func _complete_smelting() -> void:
	var output_type: String = SMELT_RECIPES.get(current_ore, "metal_ingot")

	# Store for player pickup (matching smoker/drying rack pattern)
	pending_output = output_type
	print("[SmithingStation] Smelting complete! %s ready for pickup" % output_type)

	smelting_complete.emit(output_type, 1)

	# Reset smelting state but keep pending_output
	is_smelting = false
	has_fuel = false
	current_ore = ""
	smelt_progress = 0.0
	interaction_text = "Collect Ingot"
	_update_forge_visuals()

	# Notify player via HUD
	var hud: Node = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_notification"):
		hud.show_notification("Smelting complete! Collect your ingot.", Color(1, 0.85, 0.3, 1))


## Update visuals based on current state (idle, smelting, or output ready).
func _update_forge_visuals() -> void:
	if is_smelting:
		# Active smelting: bright fire, show ore
		if fire_material:
			fire_material.emission_energy_multiplier = 3.0
			fire_material.albedo_color = Color(1.0, 0.6, 0.1)
			fire_material.emission = Color(1.0, 0.5, 0.0)
		if forge_light:
			forge_light.light_energy = 4.0
		if ore_mesh:
			ore_mesh.visible = true
			ore_material.albedo_color = Color(0.5, 0.35, 0.3)  # Raw ore color
			ore_material.emission_enabled = false
	elif pending_output != "":
		# Finished: show glowing ingot, moderate fire
		if fire_material:
			fire_material.emission_energy_multiplier = 2.0
			fire_material.albedo_color = Color(1.0, 0.5, 0.1)
			fire_material.emission = Color(1.0, 0.4, 0.0)
		if forge_light:
			forge_light.light_energy = 3.0
		if ore_mesh:
			ore_mesh.visible = true
			ore_material.albedo_color = Color(0.75, 0.7, 0.65)  # Silver ingot
			ore_material.emission_enabled = true
			ore_material.emission = Color(0.9, 0.6, 0.2)
			ore_material.emission_energy_multiplier = 1.5
	else:
		# Idle: dim fire, hide ore
		if fire_material:
			fire_material.emission_energy_multiplier = 1.5
			fire_material.albedo_color = Color(1.0, 0.5, 0.1)
			fire_material.emission = Color(1.0, 0.4, 0.0)
		if forge_light:
			forge_light.light_energy = 2.0
		if ore_mesh:
			ore_mesh.visible = false
			ore_material.emission_enabled = false


## Gradually change ore color from raw to glowing hot during smelting.
func _update_smelting_visuals() -> void:
	if not ore_mesh or not ore_material:
		return
	var progress: float = smelt_progress / SMELT_TIME
	# Ore transitions from raw brownish to glowing orange-hot
	var raw_color: Color = Color(0.5, 0.35, 0.3)
	var hot_color: Color = Color(1.0, 0.55, 0.15)
	ore_material.albedo_color = raw_color.lerp(hot_color, progress)
	# Start emitting once past 30% progress
	if progress > 0.3:
		ore_material.emission_enabled = true
		ore_material.emission = Color(1.0, 0.4, 0.0)
		ore_material.emission_energy_multiplier = (progress - 0.3) * 3.0
	# Pulse the fire light slightly for visual interest
	if forge_light:
		forge_light.light_energy = 4.0 + sin(smelt_progress * 3.0) * 0.5


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
	call_deferred("_update_forge_visuals")


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
