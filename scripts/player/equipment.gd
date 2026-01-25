extends Node
class_name Equipment
## Manages equipped items and their effects.

signal item_equipped(item_type: String)
signal item_unequipped(item_type: String)
signal item_used(item_type: String)
signal durability_changed(item_type: String, current: int, max_durability: int)
signal tool_broken(item_type: String)

# Items that can be equipped and their properties
const EQUIPPABLE_ITEMS: Dictionary = {
	"torch": {
		"name": "Torch",
		"slot": 1,
		"has_light": true,
		"light_color": Color(1.0, 0.8, 0.4),
		"light_energy": 2.0,
		"light_range": 10.0
	},
	"stone_axe": {
		"name": "Stone Axe",
		"slot": 2,
		"has_light": false,
		"tool_type": "axe"
	},
	"campfire_kit": {
		"name": "Campfire Kit",
		"slot": 3,
		"has_light": false,
		"placeable": true
	},
	"rope": {
		"name": "Rope",
		"slot": 4,
		"has_light": false
	},
	"shelter_kit": {
		"name": "Shelter Kit",
		"slot": 5,
		"has_light": false,
		"placeable": true
	},
	"storage_box": {
		"name": "Storage Box",
		"slot": 6,
		"has_light": false,
		"placeable": true
	},
	"fishing_rod": {
		"name": "Fishing Rod",
		"slot": 7,
		"has_light": false,
		"tool_type": "fishing"
	},
	"crafting_bench_kit": {
		"name": "Crafting Bench Kit",
		"slot": 8,
		"has_light": false,
		"placeable": true
	}
}

# Tool durability settings
const TOOL_MAX_DURABILITY: Dictionary = {
	"stone_axe": 150,
	"fishing_rod": 50
}

# Current durability for each tool (item_type -> current durability)
var tool_durability: Dictionary = {}

# Currently equipped item (empty string = nothing)
var equipped_item: String = ""

# References
var inventory: Inventory
var player: CharacterBody3D
var placement_system: Node  # PlacementSystem for placeable items

# Light node for torch
var torch_light: OmniLight3D = null


func _ready() -> void:
	# Get references from parent (player)
	# Use call_deferred because parent's @onready vars aren't set when children's _ready runs
	call_deferred("_setup_references")


func _setup_references() -> void:
	var parent: Node = get_parent()
	if parent is CharacterBody3D:
		player = parent
		# Try getting inventory via method first
		if parent.has_method("get_inventory"):
			inventory = parent.get_inventory()
		# Fallback: get sibling Inventory node directly
		if not inventory:
			var inv_node: Node = parent.get_node_or_null("Inventory")
			if inv_node is Inventory:
				inventory = inv_node
		# Get placement system
		placement_system = parent.get_node_or_null("PlacementSystem")
		print("[Equipment] Setup complete, inventory: ", inventory, ", placement: ", placement_system)
		if inventory:
			print("[Equipment] Inventory items: ", inventory.get_all_items())


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	# Number keys to equip items
	if event.physical_keycode == KEY_1:
		_try_equip_slot(1)
	elif event.physical_keycode == KEY_2:
		_try_equip_slot(2)
	elif event.physical_keycode == KEY_3:
		_try_equip_slot(3)
	elif event.physical_keycode == KEY_4:
		_try_equip_slot(4)
	elif event.physical_keycode == KEY_5:
		_try_equip_slot(5)
	elif event.physical_keycode == KEY_6:
		_try_equip_slot(6)
	elif event.physical_keycode == KEY_7:
		_try_equip_slot(7)
	elif event.physical_keycode == KEY_8:
		_try_equip_slot(8)
	elif event.physical_keycode == KEY_Q:
		unequip()


func _try_equip_slot(slot: int) -> void:
	# Ensure we have inventory reference
	if not inventory:
		_setup_references()
	if not inventory:
		print("[Equipment] ERROR: No inventory reference!")
		return

	# Find item for this slot
	for item_type: String in EQUIPPABLE_ITEMS:
		var item_data: Dictionary = EQUIPPABLE_ITEMS[item_type]
		if item_data.get("slot", 0) == slot:
			print("[Equipment] Checking for %s, inventory has: %s" % [item_type, inventory.get_all_items()])
			if inventory.has_item(item_type):
				equip(item_type)
			else:
				print("[Equipment] Don't have %s" % item_type)
			return


## Equip an item by type.
func equip(item_type: String) -> bool:
	if not EQUIPPABLE_ITEMS.has(item_type):
		print("[Equipment] %s is not equippable" % item_type)
		return false

	if not inventory or not inventory.has_item(item_type):
		print("[Equipment] Don't have %s in inventory" % item_type)
		return false

	# Unequip current item first
	if equipped_item != "":
		unequip()

	equipped_item = item_type
	var item_data: Dictionary = EQUIPPABLE_ITEMS[item_type]

	# Apply item effects
	if item_data.get("has_light", false):
		_create_torch_light(item_data)

	print("[Equipment] Equipped %s" % item_data.get("name", item_type))
	item_equipped.emit(item_type)
	return true


## Unequip current item.
func unequip() -> void:
	if equipped_item == "":
		return

	var old_item: String = equipped_item

	# Remove item effects
	_remove_torch_light()

	equipped_item = ""
	print("[Equipment] Unequipped %s" % old_item)
	item_unequipped.emit(old_item)


## Use the currently equipped item (for placeable items, tools, etc.)
func use_equipped() -> bool:
	if equipped_item == "":
		return false

	var item_data: Dictionary = EQUIPPABLE_ITEMS.get(equipped_item, {})

	if item_data.get("placeable", false):
		return _place_item()

	# Handle tool usage
	if item_data.has("tool_type"):
		var tool_type: String = item_data.get("tool_type", "")
		if tool_type == "fishing":
			return _use_fishing_rod()
		else:
			return _use_tool()

	return false


func _use_tool() -> bool:
	if not player:
		return false

	# Get the interaction ray from player's camera
	var camera: Camera3D = player.get_node_or_null("Camera3D")
	if not camera:
		return false

	var interaction_ray: RayCast3D = camera.get_node_or_null("InteractionRay")
	if not interaction_ray or not interaction_ray.is_colliding():
		_play_swing_animation()  # Swing anyway for feedback
		print("[Equipment] Nothing to chop")
		return false

	var target: Node = interaction_ray.get_collider()
	if not target or not target.is_in_group("resource_node"):
		_play_swing_animation()
		print("[Equipment] Can't chop that")
		return false

	# Try to chop the resource
	if target.has_method("receive_chop"):
		_play_swing_animation()
		var success: bool = target.receive_chop(player)
		if success:
			item_used.emit(equipped_item)
			# Use durability on successful chop
			use_durability(1)
		return success

	return false


func _use_fishing_rod() -> bool:
	if not player:
		return false

	# Get the interaction ray from player's camera
	var camera: Camera3D = player.get_node_or_null("Camera3D")
	if not camera:
		return false

	var interaction_ray: RayCast3D = camera.get_node_or_null("InteractionRay")
	if not interaction_ray or not interaction_ray.is_colliding():
		print("[Equipment] Look at a fishing spot to fish")
		return false

	var target: Node = interaction_ray.get_collider()
	if not target or not target.is_in_group("fishing_spot"):
		print("[Equipment] That's not a fishing spot")
		return false

	# Try to fish
	if target.has_method("interact"):
		var success: bool = target.interact(player)
		if success:
			item_used.emit(equipped_item)
		return success

	return false


func _play_swing_animation() -> void:
	# Camera punch effect for swinging the tool
	if not player:
		return

	var camera: Camera3D = player.get_node_or_null("Camera3D")
	if not camera:
		return

	# Store original rotation
	var original_rot: Vector3 = camera.rotation

	# Create swing animation - quick rotation punch
	var tween: Tween = player.create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	# Swing down and to the right
	tween.tween_property(camera, "rotation:x", original_rot.x + 0.15, 0.08)
	tween.parallel().tween_property(camera, "rotation:z", original_rot.z - 0.1, 0.08)
	# Return to original
	tween.tween_property(camera, "rotation:x", original_rot.x, 0.15)
	tween.parallel().tween_property(camera, "rotation:z", original_rot.z, 0.15)

	print("[Equipment] *swing*")


## Check if an item is currently equipped.
func is_equipped(item_type: String) -> bool:
	return equipped_item == item_type


## Get currently equipped item type.
func get_equipped() -> String:
	return equipped_item


## Get equipped item display name.
func get_equipped_name() -> String:
	if equipped_item == "":
		return ""
	var item_data: Dictionary = EQUIPPABLE_ITEMS.get(equipped_item, {})
	return item_data.get("name", equipped_item.capitalize())


## Check if player has a tool of a certain type equipped.
func has_tool_equipped(tool_type: String) -> bool:
	if equipped_item == "":
		return false
	var item_data: Dictionary = EQUIPPABLE_ITEMS.get(equipped_item, {})
	return item_data.get("tool_type", "") == tool_type


func _create_torch_light(item_data: Dictionary) -> void:
	if torch_light:
		return

	torch_light = OmniLight3D.new()
	torch_light.light_color = item_data.get("light_color", Color(1.0, 0.8, 0.4))
	torch_light.light_energy = item_data.get("light_energy", 2.0)
	torch_light.omni_range = item_data.get("light_range", 10.0)
	torch_light.shadow_enabled = true

	# Position slightly in front and to the side of player
	torch_light.position = Vector3(0.5, 1.2, -0.5)

	if player:
		player.add_child(torch_light)


func _remove_torch_light() -> void:
	if torch_light:
		torch_light.queue_free()
		torch_light = null


func _place_item() -> bool:
	if not player or not inventory:
		return false

	# Delegate to PlacementSystem for all placeable items
	if placement_system and placement_system.has_method("start_placement"):
		var success: bool = placement_system.start_placement(equipped_item)
		if success:
			# Unequip since we're now in placement mode
			unequip()
			return true

	# Fallback: Legacy campfire placement if no PlacementSystem
	if equipped_item == "campfire_kit" and not placement_system:
		return _legacy_place_campfire()

	return false


## Legacy campfire placement (fallback if PlacementSystem not available).
func _legacy_place_campfire() -> bool:
	# Get position in front of player
	var forward: Vector3 = -player.global_transform.basis.z
	var place_pos: Vector3 = player.global_position + forward * 2.0
	place_pos.y = 0  # Place on ground

	# Create campfire
	var campfire: Node3D = _create_legacy_campfire(place_pos)
	if campfire:
		# Add to scene
		player.get_parent().add_child(campfire)

		# Remove from inventory and unequip
		inventory.remove_item("campfire_kit", 1)
		unequip()

		print("[Equipment] Placed campfire at %s" % place_pos)
		item_used.emit("campfire_kit")
		return true

	return false


func _create_legacy_campfire(pos: Vector3) -> Node3D:
	# Create a simple campfire node (legacy version without structure system)
	var campfire: Node3D = Node3D.new()
	campfire.name = "Campfire"
	campfire.global_position = pos

	# Base rocks (visual)
	var rocks_mesh: MeshInstance3D = MeshInstance3D.new()
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = 0.6
	cylinder.bottom_radius = 0.7
	cylinder.height = 0.3
	rocks_mesh.mesh = cylinder

	var rock_material: StandardMaterial3D = StandardMaterial3D.new()
	rock_material.albedo_color = Color(0.4, 0.4, 0.4)
	rocks_mesh.material_override = rock_material
	rocks_mesh.position.y = 0.15
	campfire.add_child(rocks_mesh)

	# Fire glow (light)
	var fire_light: OmniLight3D = OmniLight3D.new()
	fire_light.light_color = Color(1.0, 0.6, 0.2)
	fire_light.light_energy = 3.0
	fire_light.omni_range = 8.0
	fire_light.position.y = 0.5
	campfire.add_child(fire_light)

	# Fire visual (simple orange cone)
	var fire_mesh: MeshInstance3D = MeshInstance3D.new()
	var cone: CylinderMesh = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.3
	cone.height = 0.8
	fire_mesh.mesh = cone

	var fire_material: StandardMaterial3D = StandardMaterial3D.new()
	fire_material.albedo_color = Color(1.0, 0.5, 0.1)
	fire_material.emission_enabled = true
	fire_material.emission = Color(1.0, 0.4, 0.0)
	fire_material.emission_energy_multiplier = 2.0
	fire_mesh.material_override = fire_material
	fire_mesh.position.y = 0.5
	campfire.add_child(fire_mesh)

	return campfire


## Initialize durability for a new tool (called when crafted or acquired).
func init_tool_durability(item_type: String) -> void:
	if TOOL_MAX_DURABILITY.has(item_type):
		tool_durability[item_type] = TOOL_MAX_DURABILITY[item_type]
		print("[Equipment] Initialized %s durability: %d" % [item_type, tool_durability[item_type]])


## Use durability on the currently equipped tool. Returns true if tool still usable.
func use_durability(amount: int = 1) -> bool:
	if equipped_item == "":
		return false

	if not TOOL_MAX_DURABILITY.has(equipped_item):
		return true  # Non-durability item, always usable

	# Initialize if not tracked yet
	if not tool_durability.has(equipped_item):
		tool_durability[equipped_item] = TOOL_MAX_DURABILITY[equipped_item]

	# Reduce durability
	tool_durability[equipped_item] -= amount
	var current: int = tool_durability[equipped_item]
	var max_dur: int = TOOL_MAX_DURABILITY[equipped_item]

	durability_changed.emit(equipped_item, current, max_dur)
	print("[Equipment] %s durability: %d/%d" % [equipped_item, current, max_dur])

	# Check if broken
	if current <= 0:
		_break_tool()
		return false

	return true


## Break the currently equipped tool.
func _break_tool() -> void:
	var broken_item: String = equipped_item

	# Remove from inventory
	if inventory:
		inventory.remove_item(broken_item, 1)

	# Remove durability tracking
	tool_durability.erase(broken_item)

	# Unequip
	unequip()

	# Emit signal
	tool_broken.emit(broken_item)
	print("[Equipment] %s broke!" % broken_item)


## Get current durability of equipped tool (returns -1 if no durability system).
func get_equipped_durability() -> int:
	if equipped_item == "" or not TOOL_MAX_DURABILITY.has(equipped_item):
		return -1
	if not tool_durability.has(equipped_item):
		return TOOL_MAX_DURABILITY[equipped_item]
	return tool_durability[equipped_item]


## Get max durability of equipped tool (returns -1 if no durability system).
func get_equipped_max_durability() -> int:
	if equipped_item == "" or not TOOL_MAX_DURABILITY.has(equipped_item):
		return -1
	return TOOL_MAX_DURABILITY[equipped_item]


## Get all tool durability data for saving.
func get_durability_data() -> Dictionary:
	return tool_durability.duplicate()


## Load tool durability data from save.
func load_durability_data(data: Dictionary) -> void:
	tool_durability = data.duplicate()
