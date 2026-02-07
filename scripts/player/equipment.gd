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
		"light_energy": 8.0,
		"light_range": 15.0,
		"placeable": true
	},
	"primitive_axe": {
		"name": "Primitive Axe",
		"slot": 22,
		"has_light": false,
		"tool_type": "axe",
		"effectiveness": 0.5
	},
	"stone_axe": {
		"name": "Stone Axe",
		"slot": 2,
		"has_light": false,
		"tool_type": "axe",
		"effectiveness": 1.0
	},
	"metal_axe": {
		"name": "Metal Axe",
		"slot": 15,
		"has_light": false,
		"tool_type": "axe",
		"effectiveness": 2.0
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
	},
	"drying_rack_kit": {
		"name": "Drying Rack Kit",
		"slot": 9,
		"has_light": false,
		"placeable": true
	},
	"garden_plot_kit": {
		"name": "Garden Plot Kit",
		"slot": 10,
		"has_light": false,
		"placeable": true
	},
	"canvas_tent_kit": {
		"name": "Canvas Tent Kit",
		"slot": 11,
		"has_light": false,
		"placeable": true
	},
	"cabin_kit": {
		"name": "Cabin Kit",
		"slot": 12,
		"has_light": false,
		"placeable": true
	},
	"rope_ladder_kit": {
		"name": "Rope Ladder Kit",
		"slot": 13,
		"has_light": false,
		"placeable": true
	},
	"snare_trap_kit": {
		"name": "Snare Trap Kit",
		"slot": 16,
		"has_light": false,
		"placeable": true
	},
	"smithing_station_kit": {
		"name": "Smithing Station Kit",
		"slot": 17,
		"has_light": false,
		"placeable": true
	},
	"smoker_kit": {
		"name": "Smoker Kit",
		"slot": 18,
		"has_light": false,
		"placeable": true
	},
	"weather_vane_kit": {
		"name": "Weather Vane Kit",
		"slot": 19,
		"has_light": false,
		"placeable": true
	},
	"machete": {
		"name": "Machete",
		"slot": 20,
		"has_light": false,
		"tool_type": "machete",
		"effectiveness": 1.0
	},
	"lantern": {
		"name": "Lantern",
		"slot": 21,
		"has_light": true,
		"light_color": Color(0.9, 0.95, 1.0),
		"light_energy": 16.0,
		"light_range": 30.0,
		"placeable": true
	},
	"grappling_hook": {
		"name": "Grappling Hook",
		"slot": 14,
		"has_light": false,
		"tool_type": "grappling_hook"
	},
	"lodestone": {
		"name": "Lodestone",
		"slot": 23,
		"has_light": false,
		"placeable": true
	}
}

# Tool durability settings
const TOOL_MAX_DURABILITY: Dictionary = {
	"primitive_axe": 50,
	"stone_axe": 150,
	"metal_axe": 300,
	"fishing_rod": 50,
	"machete": 200,
	"grappling_hook": 100
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

# Stone axe visual
var stone_axe_model: Node3D = null
var axe_swing_tween: Tween = null  # Track swing animation to prevent conflicts
# Position further from camera to avoid near-plane clipping (was -0.5, shadow visible but model clipped)
const AXE_REST_POSITION: Vector3 = Vector3(0.35, -0.3, -0.7)
const AXE_REST_ROTATION: Vector3 = Vector3(10, 0, -18)

# Fishing rod visual
var fishing_rod_model: Node3D = null
var fishing_line: MeshInstance3D = null
var line_pivot: Node3D = null  # Pivot at rod tip for line attachment
var caught_fish_model: Node3D = null
var is_line_cast: bool = false


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


# Track current slot for controller cycling
var current_slot: int = 1

func _input(event: InputEvent) -> void:
	# Handle controller slot cycling (L1/R1)
	if event.is_action_pressed("next_slot"):
		_cycle_slot(1)
		return
	if event.is_action_pressed("prev_slot"):
		_cycle_slot(-1)
		return

	# Handle unequip action (Q key or Circle button)
	if event.is_action_pressed("unequip"):
		unequip()
		return

	# Number keys to equip items (keyboard only)
	if not event is InputEventKey or not event.pressed or event.echo:
		return

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
	elif event.physical_keycode == KEY_9:
		_try_equip_slot(9)
	elif event.physical_keycode == KEY_0:
		_try_equip_slot(10)
	elif event.physical_keycode == KEY_MINUS:
		_try_equip_slot(11)
	elif event.physical_keycode == KEY_EQUAL:
		_try_equip_slot(12)
	elif event.physical_keycode == KEY_BRACKETLEFT:
		_try_equip_slot(13)
	elif event.physical_keycode == KEY_BRACKETRIGHT:
		_try_equip_slot(14)


## Cycle through equipment slots (for controller L1/R1).
func _cycle_slot(direction: int) -> void:
	# Ensure we have inventory reference
	if not inventory:
		_setup_references()
	if not inventory:
		return

	# Find available equippable items in inventory
	var available_slots: Array[int] = []
	for item_type: String in EQUIPPABLE_ITEMS:
		if inventory.has_item(item_type):
			var slot: int = EQUIPPABLE_ITEMS[item_type].get("slot", 0)
			if slot > 0:
				available_slots.append(slot)

	if available_slots.is_empty():
		print("[Equipment] No items to equip")
		return

	available_slots.sort()

	# Find current position in available slots
	var current_index: int = -1
	for i: int in range(available_slots.size()):
		if available_slots[i] == current_slot:
			current_index = i
			break

	# Calculate next slot
	var next_index: int
	if current_index == -1:
		# Current slot not in available items, start from beginning or end
		next_index = 0 if direction > 0 else available_slots.size() - 1
	else:
		next_index = (current_index + direction) % available_slots.size()
		if next_index < 0:
			next_index = available_slots.size() - 1

	current_slot = available_slots[next_index]
	_try_equip_slot(current_slot)


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

	# Show tool models
	var tool_type: String = item_data.get("tool_type", "")
	if tool_type == "fishing":
		_create_fishing_rod()
	elif tool_type == "axe":
		_create_axe_model(item_type)
	elif tool_type == "machete":
		_create_machete_model()
	elif tool_type == "grappling_hook":
		_create_grappling_hook_model()
		_ensure_grappling_hook_controller()

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
	_remove_stone_axe()
	_remove_machete()
	_remove_fishing_rod()
	_remove_grappling_hook()

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
		elif tool_type == "grappling_hook":
			return _use_grappling_hook()
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

	# Check for valid targets: resource_node or obstacle groups
	var valid_target: bool = false
	if target:
		valid_target = target.is_in_group("resource_node") or target.is_in_group("obstacle")

	if not target or not valid_target:
		_play_swing_animation()
		print("[Equipment] Can't chop that")
		return false

	# Try to chop the resource or obstacle
	if target.has_method("receive_chop"):
		_play_swing_animation()
		var success: bool = target.receive_chop(player)
		if success:
			# Play appropriate sound based on target type
			if target.is_in_group("obstacle"):
				SFXManager.play_sfx("swing")  # Use swing sound for clearing
			else:
				SFXManager.play_sfx("chop")
			item_used.emit(equipped_item)
			# Use durability on successful chop
			use_durability(1)
		return success

	return false


func _ensure_grappling_hook_controller() -> Node:
	if not player:
		return null

	var grappling_hook: Node = player.get_node_or_null("GrapplingHook")
	if not grappling_hook:
		# Create grappling hook controller dynamically
		grappling_hook = GrapplingHook.new()
		grappling_hook.name = "GrapplingHook"
		player.add_child(grappling_hook)
		print("[Equipment] Created GrapplingHook controller")

	return grappling_hook


func _use_grappling_hook() -> bool:
	var grappling_hook: Node = _ensure_grappling_hook_controller()
	if not grappling_hook:
		return false

	# Try to grapple
	if grappling_hook.has_method("try_grapple"):
		var success: bool = grappling_hook.try_grapple()
		if success:
			item_used.emit(equipped_item)
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
	if not player:
		return

	var camera: Camera3D = player.get_node_or_null("Camera3D")
	if not camera:
		return

	# Play swing sound
	SFXManager.play_sfx("swing")

	# Animate the stone axe model if equipped
	if stone_axe_model:
		# Kill any existing swing animation to prevent conflicts when chopping rapidly
		if axe_swing_tween and axe_swing_tween.is_valid():
			axe_swing_tween.kill()
			# Reset to rest position before starting new animation
			stone_axe_model.position = AXE_REST_POSITION
			stone_axe_model.rotation_degrees = AXE_REST_ROTATION

		axe_swing_tween = player.create_tween()
		axe_swing_tween.set_trans(Tween.TRANS_QUAD)
		axe_swing_tween.set_ease(Tween.EASE_OUT)

		# Wind up: raise axe up and tilt head back (away from target)
		axe_swing_tween.tween_property(stone_axe_model, "rotation_degrees",
			Vector3(AXE_REST_ROTATION.x + 45, AXE_REST_ROTATION.y, AXE_REST_ROTATION.z - 10), 0.1)
		axe_swing_tween.parallel().tween_property(stone_axe_model, "position",
			Vector3(AXE_REST_POSITION.x, AXE_REST_POSITION.y + 0.15, AXE_REST_POSITION.z + 0.1), 0.1)

		# Swing down: bring head forward into target
		axe_swing_tween.tween_property(stone_axe_model, "rotation_degrees",
			Vector3(AXE_REST_ROTATION.x - 35, AXE_REST_ROTATION.y, AXE_REST_ROTATION.z + 5), 0.08)
		axe_swing_tween.parallel().tween_property(stone_axe_model, "position",
			Vector3(AXE_REST_POSITION.x, AXE_REST_POSITION.y - 0.1, AXE_REST_POSITION.z - 0.15), 0.08)

		# Return to rest position (always use constants to prevent drift)
		axe_swing_tween.tween_property(stone_axe_model, "rotation_degrees", AXE_REST_ROTATION, 0.12)
		axe_swing_tween.parallel().tween_property(stone_axe_model, "position", AXE_REST_POSITION, 0.12)

		print("[Equipment] *chop*")
	elif machete_model:
		# Animate machete swing (horizontal slash motion)
		if axe_swing_tween and axe_swing_tween.is_valid():
			axe_swing_tween.kill()
			machete_model.position = MACHETE_REST_POSITION
			machete_model.rotation_degrees = MACHETE_REST_ROTATION

		axe_swing_tween = player.create_tween()
		axe_swing_tween.set_trans(Tween.TRANS_QUAD)
		axe_swing_tween.set_ease(Tween.EASE_OUT)

		# Wind up: pull back to the right
		axe_swing_tween.tween_property(machete_model, "rotation_degrees",
			Vector3(MACHETE_REST_ROTATION.x, MACHETE_REST_ROTATION.y + 40, MACHETE_REST_ROTATION.z + 15), 0.1)
		axe_swing_tween.parallel().tween_property(machete_model, "position",
			Vector3(MACHETE_REST_POSITION.x + 0.1, MACHETE_REST_POSITION.y, MACHETE_REST_POSITION.z + 0.1), 0.1)

		# Slash left: horizontal swing across
		axe_swing_tween.tween_property(machete_model, "rotation_degrees",
			Vector3(MACHETE_REST_ROTATION.x, MACHETE_REST_ROTATION.y - 50, MACHETE_REST_ROTATION.z - 10), 0.08)
		axe_swing_tween.parallel().tween_property(machete_model, "position",
			Vector3(MACHETE_REST_POSITION.x - 0.15, MACHETE_REST_POSITION.y, MACHETE_REST_POSITION.z - 0.1), 0.08)

		# Return to rest position
		axe_swing_tween.tween_property(machete_model, "rotation_degrees", MACHETE_REST_ROTATION, 0.12)
		axe_swing_tween.parallel().tween_property(machete_model, "position", MACHETE_REST_POSITION, 0.12)

		print("[Equipment] *slash*")
	else:
		# Fallback camera punch for other tools
		var original_rot: Vector3 = camera.rotation

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


## Get the effectiveness multiplier for the currently equipped tool.
## Returns 1.0 if no tool or tool has no effectiveness defined.
func get_tool_effectiveness() -> float:
	if equipped_item == "":
		return 1.0
	var item_data: Dictionary = EQUIPPABLE_ITEMS.get(equipped_item, {})
	return item_data.get("effectiveness", 1.0)


func _create_torch_light(item_data: Dictionary) -> void:
	if torch_light:
		return

	# Ensure player reference exists
	if not player:
		_setup_references()
	if not player:
		print("[Equipment] ERROR: Cannot create torch light - no player reference")
		return

	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = item_data.get("light_color", Color(1.0, 0.8, 0.4))
	light.light_energy = item_data.get("light_energy", 2.0)
	light.omni_range = item_data.get("light_range", 10.0)
	light.shadow_enabled = true

	# Position slightly in front and to the side of player
	light.position = Vector3(0.5, 1.2, -0.5)

	player.add_child(light)
	torch_light = light
	print("[Equipment] Torch light created")


func _remove_torch_light() -> void:
	if torch_light:
		torch_light.queue_free()
		torch_light = null


## Create an axe model based on the axe type.
func _create_axe_model(axe_type: String) -> void:
	if stone_axe_model:
		return

	stone_axe_model = Node3D.new()
	stone_axe_model.name = "AxeModel"

	# Handle (wooden stick) - blocky
	var handle := MeshInstance3D.new()
	handle.name = "Handle"
	var handle_mesh := BoxMesh.new()
	handle_mesh.size = Vector3(0.06, 0.5, 0.06)
	handle.mesh = handle_mesh

	var handle_mat := StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.45, 0.35, 0.2)  # Wood brown
	handle.material_override = handle_mat
	handle.position = Vector3(0, 0, 0)

	stone_axe_model.add_child(handle)

	# Create head based on axe type
	match axe_type:
		"primitive_axe":
			_add_primitive_axe_head(stone_axe_model)
		"stone_axe":
			_add_stone_axe_head(stone_axe_model)
		"metal_axe":
			_add_metal_axe_head(stone_axe_model)
		_:
			_add_stone_axe_head(stone_axe_model)  # Default to stone

	# Position: held in right hand, vertical with natural 18 degree clockwise tilt
	stone_axe_model.position = AXE_REST_POSITION
	stone_axe_model.rotation_degrees = AXE_REST_ROTATION

	# Attach to camera
	if player:
		var camera: Camera3D = player.get_node_or_null("Camera3D")
		if camera:
			camera.add_child(stone_axe_model)


func _add_primitive_axe_head(axe_model: Node3D) -> void:
	# Very crude stone head - irregular, smaller
	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.05, 0.10, 0.12)  # Smaller than stone axe
	head.mesh = head_mesh

	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.45, 0.42, 0.38)  # Rough greyish stone
	head.material_override = head_mat
	head.position = Vector3(0, 0.22, -0.04)

	axe_model.add_child(head)

	# Crude blade edge
	var blade := MeshInstance3D.new()
	blade.name = "Blade"
	var blade_mesh := BoxMesh.new()
	blade_mesh.size = Vector3(0.04, 0.08, 0.02)
	blade.mesh = blade_mesh

	var blade_mat := StandardMaterial3D.new()
	blade_mat.albedo_color = Color(0.38, 0.36, 0.34)
	blade.material_override = blade_mat
	blade.position = Vector3(0, 0.22, -0.11)

	axe_model.add_child(blade)

	# Simple vine binding (thinner, more crude)
	var binding := MeshInstance3D.new()
	binding.name = "Binding"
	var binding_mesh := BoxMesh.new()
	binding_mesh.size = Vector3(0.06, 0.04, 0.06)
	binding.mesh = binding_mesh

	var binding_mat := StandardMaterial3D.new()
	binding_mat.albedo_color = Color(0.35, 0.45, 0.25)  # Green vine
	binding.material_override = binding_mat
	binding.position = Vector3(0, 0.2, 0)

	axe_model.add_child(binding)


func _add_stone_axe_head(axe_model: Node3D) -> void:
	# Stone head - blocky wedge shape
	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.06, 0.12, 0.18)
	head.mesh = head_mesh

	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.5, 0.5, 0.5)  # Stone grey
	head.material_override = head_mat
	head.position = Vector3(0, 0.22, -0.06)

	axe_model.add_child(head)

	# Blade edge
	var blade := MeshInstance3D.new()
	blade.name = "Blade"
	var blade_mesh := BoxMesh.new()
	blade_mesh.size = Vector3(0.05, 0.1, 0.02)
	blade.mesh = blade_mesh

	var blade_mat := StandardMaterial3D.new()
	blade_mat.albedo_color = Color(0.4, 0.4, 0.42)
	blade.material_override = blade_mat
	blade.position = Vector3(0, 0.22, -0.16)

	axe_model.add_child(blade)

	# Binding
	var binding := MeshInstance3D.new()
	binding.name = "Binding"
	var binding_mesh := BoxMesh.new()
	binding_mesh.size = Vector3(0.08, 0.06, 0.08)
	binding.mesh = binding_mesh

	var binding_mat := StandardMaterial3D.new()
	binding_mat.albedo_color = Color(0.55, 0.45, 0.3)
	binding.material_override = binding_mat
	binding.position = Vector3(0, 0.2, 0)

	axe_model.add_child(binding)


func _add_metal_axe_head(axe_model: Node3D) -> void:
	# Metal head - larger, more refined shape
	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.06, 0.14, 0.22)  # Larger than stone
	head.mesh = head_mesh

	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.55, 0.55, 0.58)  # Light metal grey
	head_mat.metallic = 0.7
	head_mat.roughness = 0.3
	head.material_override = head_mat
	head.position = Vector3(0, 0.24, -0.08)

	axe_model.add_child(head)

	# Sharp metal blade edge
	var blade := MeshInstance3D.new()
	blade.name = "Blade"
	var blade_mesh := BoxMesh.new()
	blade_mesh.size = Vector3(0.04, 0.12, 0.02)
	blade.mesh = blade_mesh

	var blade_mat := StandardMaterial3D.new()
	blade_mat.albedo_color = Color(0.7, 0.7, 0.72)  # Shiny edge
	blade_mat.metallic = 0.9
	blade_mat.roughness = 0.1
	blade.material_override = blade_mat
	blade.position = Vector3(0, 0.24, -0.20)

	axe_model.add_child(blade)

	# Metal collar (instead of binding)
	var collar := MeshInstance3D.new()
	collar.name = "Collar"
	var collar_mesh := BoxMesh.new()
	collar_mesh.size = Vector3(0.08, 0.04, 0.08)
	collar.mesh = collar_mesh

	var collar_mat := StandardMaterial3D.new()
	collar_mat.albedo_color = Color(0.4, 0.38, 0.36)  # Dark metal
	collar_mat.metallic = 0.5
	collar_mat.roughness = 0.5
	collar.material_override = collar_mat
	collar.position = Vector3(0, 0.22, 0)

	axe_model.add_child(collar)


func _remove_stone_axe() -> void:
	if stone_axe_model:
		stone_axe_model.queue_free()
		stone_axe_model = null


# Machete visual
var machete_model: Node3D = null
const MACHETE_REST_POSITION: Vector3 = Vector3(0.35, -0.25, -0.65)
const MACHETE_REST_ROTATION: Vector3 = Vector3(15, -10, -25)


func _create_machete_model() -> void:
	if machete_model:
		return

	machete_model = Node3D.new()
	machete_model.name = "MacheteModel"

	# Handle (wooden grip)
	var handle := MeshInstance3D.new()
	handle.name = "Handle"
	var handle_mesh := BoxMesh.new()
	handle_mesh.size = Vector3(0.04, 0.18, 0.03)
	handle.mesh = handle_mesh

	var handle_mat := StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.4, 0.3, 0.2)  # Dark wood
	handle.material_override = handle_mat
	handle.position = Vector3(0, 0, 0)

	machete_model.add_child(handle)

	# Guard (small crosspiece)
	var guard := MeshInstance3D.new()
	guard.name = "Guard"
	var guard_mesh := BoxMesh.new()
	guard_mesh.size = Vector3(0.06, 0.02, 0.04)
	guard.mesh = guard_mesh

	var guard_mat := StandardMaterial3D.new()
	guard_mat.albedo_color = Color(0.35, 0.35, 0.38)
	guard_mat.metallic = 0.6
	guard.material_override = guard_mat
	guard.position = Vector3(0, 0.1, 0)

	machete_model.add_child(guard)

	# Blade (long, slightly curved looking via offset)
	var blade := MeshInstance3D.new()
	blade.name = "Blade"
	var blade_mesh := BoxMesh.new()
	blade_mesh.size = Vector3(0.03, 0.4, 0.08)  # Long, flat blade
	blade.mesh = blade_mesh

	var blade_mat := StandardMaterial3D.new()
	blade_mat.albedo_color = Color(0.6, 0.6, 0.62)
	blade_mat.metallic = 0.8
	blade_mat.roughness = 0.2
	blade.material_override = blade_mat
	blade.position = Vector3(0, 0.31, 0.01)  # Slightly offset for curved look

	machete_model.add_child(blade)

	# Sharp edge (thinner strip on one side)
	var edge := MeshInstance3D.new()
	edge.name = "Edge"
	var edge_mesh := BoxMesh.new()
	edge_mesh.size = Vector3(0.02, 0.38, 0.01)
	edge.mesh = edge_mesh

	var edge_mat := StandardMaterial3D.new()
	edge_mat.albedo_color = Color(0.75, 0.75, 0.78)
	edge_mat.metallic = 0.9
	edge_mat.roughness = 0.1
	edge.material_override = edge_mat
	edge.position = Vector3(0, 0.31, 0.045)

	machete_model.add_child(edge)

	# Position: held in right hand, angled for slashing
	machete_model.position = MACHETE_REST_POSITION
	machete_model.rotation_degrees = MACHETE_REST_ROTATION

	# Attach to camera
	if player:
		var camera: Camera3D = player.get_node_or_null("Camera3D")
		if camera:
			camera.add_child(machete_model)


func _remove_machete() -> void:
	if machete_model:
		machete_model.queue_free()
		machete_model = null


func _create_fishing_rod() -> void:
	if fishing_rod_model:
		return

	fishing_rod_model = Node3D.new()
	fishing_rod_model.name = "FishingRodModel"

	# Cork/grip handle (bottom part you hold) - blocky
	var grip := MeshInstance3D.new()
	grip.name = "Grip"
	var grip_mesh := BoxMesh.new()
	grip_mesh.size = Vector3(0.04, 0.15, 0.04)
	grip.mesh = grip_mesh

	var grip_mat := StandardMaterial3D.new()
	grip_mat.albedo_color = Color(0.6, 0.45, 0.3)  # Cork color
	grip.material_override = grip_mat
	grip.position = Vector3(0, 0, 0)

	fishing_rod_model.add_child(grip)

	# Reel seat (small dark section above grip) - blocky
	var reel_seat := MeshInstance3D.new()
	reel_seat.name = "ReelSeat"
	var reel_mesh := BoxMesh.new()
	reel_mesh.size = Vector3(0.03, 0.05, 0.03)
	reel_seat.mesh = reel_mesh

	var reel_mat := StandardMaterial3D.new()
	reel_mat.albedo_color = Color(0.2, 0.2, 0.2)  # Dark
	reel_seat.material_override = reel_mat
	reel_seat.position = Vector3(0, 0.1, 0)

	fishing_rod_model.add_child(reel_seat)

	# Main rod blank (extends from handle) - thin box
	var rod := MeshInstance3D.new()
	rod.name = "Rod"
	var rod_mesh := BoxMesh.new()
	rod_mesh.size = Vector3(0.02, 0.8, 0.02)
	rod.mesh = rod_mesh

	var rod_mat := StandardMaterial3D.new()
	rod_mat.albedo_color = Color(0.35, 0.25, 0.15)  # Dark wood/bamboo
	rod.material_override = rod_mat
	rod.position = Vector3(0, 0.52, 0)  # Positioned above handle

	fishing_rod_model.add_child(rod)

	# Rod tip (thinner box)
	var tip := MeshInstance3D.new()
	tip.name = "Tip"
	var tip_mesh := BoxMesh.new()
	tip_mesh.size = Vector3(0.01, 0.4, 0.01)
	tip.mesh = tip_mesh
	tip.material_override = rod_mat
	tip.position = Vector3(0, 1.12, 0)

	fishing_rod_model.add_child(tip)

	# Position: held in right hand, angled forward and up
	# The rod extends upward in local Y, so we rotate to point forward
	fishing_rod_model.position = Vector3(0.25, -0.35, -0.3)
	fishing_rod_model.rotation_degrees = Vector3(-70, 15, 10)  # Tilted forward and slightly right

	# Attach to camera
	if player:
		var camera: Camera3D = player.get_node_or_null("Camera3D")
		if camera:
			camera.add_child(fishing_rod_model)


func _remove_fishing_rod() -> void:
	if fishing_rod_model:
		fishing_rod_model.queue_free()
		fishing_rod_model = null
	if line_pivot:
		line_pivot.queue_free()
		line_pivot = null
	if fishing_line:
		# Line is child of pivot, but clear reference anyway
		fishing_line = null
	if caught_fish_model:
		caught_fish_model.queue_free()
		caught_fish_model = null
	is_line_cast = false


## Show casting animation when starting to fish.
func show_fishing_cast() -> void:
	if not fishing_rod_model or not player:
		return

	# Play cast sound
	SFXManager.play_sfx("cast")

	is_line_cast = true

	# Create pivot at rod tip and line as child
	if not line_pivot:
		# Pivot positioned at the rod tip in rod's local space
		line_pivot = Node3D.new()
		line_pivot.name = "LinePivot"
		line_pivot.position = Vector3(0, 1.32, 0)  # At rod tip
		fishing_rod_model.add_child(line_pivot)

		# Line hangs from pivot - mesh centered, so offset down by half length
		fishing_line = MeshInstance3D.new()
		fishing_line.name = "FishingLine"
		var line_mesh := BoxMesh.new()
		line_mesh.size = Vector3(0.01, 3.0, 0.01)  # Thin line, 3 units long
		fishing_line.mesh = line_mesh
		fishing_line.position = Vector3(0, -1.5, 0)  # Offset down so top is at pivot

		var line_mat := StandardMaterial3D.new()
		line_mat.albedo_color = Color(0.85, 0.85, 0.85, 0.7)
		line_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fishing_line.material_override = line_mat

		line_pivot.add_child(fishing_line)

	# Force the pivot to point straight down in world space
	# This overrides the parent rod's rotation for the line
	line_pivot.global_rotation = Vector3(0, 0, 0)  # Line's local -Y points to world -Y (down)
	line_pivot.visible = true
	fishing_line.visible = true

	# Casting animation - rod swings forward (rotate around X in degrees)
	var original_rot: Vector3 = fishing_rod_model.rotation_degrees
	var tween: Tween = player.create_tween()
	tween.tween_property(fishing_rod_model, "rotation_degrees:x", original_rot.x - 25, 0.15)
	tween.tween_property(fishing_rod_model, "rotation_degrees:x", original_rot.x, 0.3)


## Show caught fish animation.
func show_fish_caught() -> void:
	if not fishing_rod_model or not player:
		return

	# Play fish caught sound
	SFXManager.play_sfx("fish_caught")

	# Create caught fish model if needed
	if not caught_fish_model:
		caught_fish_model = _create_caught_fish()
		fishing_rod_model.add_child(caught_fish_model)

	caught_fish_model.visible = true
	caught_fish_model.position = Vector3(0, 2.5, 0)  # Start at end of line (rod tip area)

	# Animate fish being reeled in
	var original_rot: Vector3 = fishing_rod_model.rotation_degrees
	var tween: Tween = player.create_tween()

	# Pull rod up while reeling fish closer
	tween.tween_property(fishing_rod_model, "rotation_degrees:x", original_rot.x + 20, 0.3)
	tween.parallel().tween_property(caught_fish_model, "position", Vector3(0, 0.8, 0), 0.5)
	tween.parallel().tween_property(caught_fish_model, "rotation:y", TAU, 0.5)  # Fish spins

	# Hide fish and line after animation
	tween.tween_callback(_hide_fishing_visuals)
	tween.tween_property(fishing_rod_model, "rotation_degrees:x", original_rot.x, 0.2)


func _create_caught_fish() -> Node3D:
	var fish_root := Node3D.new()
	fish_root.name = "CaughtFish"

	# Fish body (blocky box)
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.15, 0.06, 0.04)
	body.mesh = body_mesh

	var fish_mat := StandardMaterial3D.new()
	fish_mat.albedo_color = Color(0.6, 0.55, 0.4)
	body.material_override = fish_mat

	fish_root.add_child(body)

	# Tail (small box)
	var tail := MeshInstance3D.new()
	var tail_mesh := BoxMesh.new()
	tail_mesh.size = Vector3(0.03, 0.08, 0.02)
	tail.mesh = tail_mesh
	tail.position = Vector3(-0.09, 0, 0)
	tail.material_override = fish_mat

	fish_root.add_child(tail)

	fish_root.visible = false
	return fish_root


func _hide_fishing_visuals() -> void:
	if caught_fish_model:
		caught_fish_model.visible = false
	if line_pivot:
		line_pivot.visible = false
	is_line_cast = false


## Hide the fishing line (called when fish gets away or fishing is cancelled).
func hide_fishing_line() -> void:
	if line_pivot:
		line_pivot.visible = false
	is_line_cast = false
	print("[Equipment] Fishing line retracted")


# Grappling hook visual
var grappling_hook_model: Node3D = null
const GRAPPLING_HOOK_REST_POSITION: Vector3 = Vector3(0.3, -0.25, -0.6)
const GRAPPLING_HOOK_REST_ROTATION: Vector3 = Vector3(15, -15, -20)


func _create_grappling_hook_model() -> void:
	if grappling_hook_model:
		return

	grappling_hook_model = Node3D.new()
	grappling_hook_model.name = "GrapplingHookModel"

	# Handle (wooden grip)
	var handle := MeshInstance3D.new()
	handle.name = "Handle"
	var handle_mesh := BoxMesh.new()
	handle_mesh.size = Vector3(0.04, 0.2, 0.04)
	handle.mesh = handle_mesh

	var handle_mat := StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.45, 0.35, 0.2)  # Wood brown
	handle.material_override = handle_mat
	handle.position = Vector3(0, 0, 0)

	grappling_hook_model.add_child(handle)

	# Rope coil around handle
	var coil := MeshInstance3D.new()
	coil.name = "RopeCoil"
	var coil_mesh := BoxMesh.new()
	coil_mesh.size = Vector3(0.06, 0.08, 0.06)
	coil.mesh = coil_mesh

	var rope_mat := StandardMaterial3D.new()
	rope_mat.albedo_color = Color(0.6, 0.5, 0.35)  # Tan rope color
	coil.material_override = rope_mat
	coil.position = Vector3(0, -0.06, 0)

	grappling_hook_model.add_child(coil)

	# Hook head (metal)
	var hook_head := MeshInstance3D.new()
	hook_head.name = "HookHead"
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.08, 0.06, 0.06)
	hook_head.mesh = head_mesh

	var metal_mat := StandardMaterial3D.new()
	metal_mat.albedo_color = Color(0.5, 0.5, 0.52)
	metal_mat.metallic = 0.7
	metal_mat.roughness = 0.3
	hook_head.material_override = metal_mat
	hook_head.position = Vector3(0, 0.13, 0)

	grappling_hook_model.add_child(hook_head)

	# Hook prong 1
	var prong1 := MeshInstance3D.new()
	prong1.name = "Prong1"
	var prong_mesh := BoxMesh.new()
	prong_mesh.size = Vector3(0.02, 0.08, 0.02)
	prong1.mesh = prong_mesh
	prong1.material_override = metal_mat
	prong1.position = Vector3(0.04, 0.17, 0)
	prong1.rotation_degrees = Vector3(0, 0, -30)

	grappling_hook_model.add_child(prong1)

	# Hook prong 2
	var prong2 := MeshInstance3D.new()
	prong2.name = "Prong2"
	prong2.mesh = prong_mesh
	prong2.material_override = metal_mat
	prong2.position = Vector3(-0.04, 0.17, 0)
	prong2.rotation_degrees = Vector3(0, 0, 30)

	grappling_hook_model.add_child(prong2)

	# Hook prong 3 (front)
	var prong3 := MeshInstance3D.new()
	prong3.name = "Prong3"
	prong3.mesh = prong_mesh
	prong3.material_override = metal_mat
	prong3.position = Vector3(0, 0.17, 0.04)
	prong3.rotation_degrees = Vector3(30, 0, 0)

	grappling_hook_model.add_child(prong3)

	# Position: held in right hand
	grappling_hook_model.position = GRAPPLING_HOOK_REST_POSITION
	grappling_hook_model.rotation_degrees = GRAPPLING_HOOK_REST_ROTATION

	# Attach to camera
	if player:
		var camera: Camera3D = player.get_node_or_null("Camera3D")
		if camera:
			camera.add_child(grappling_hook_model)


func _remove_grappling_hook() -> void:
	if grappling_hook_model:
		grappling_hook_model.queue_free()
		grappling_hook_model = null


func _place_item() -> bool:
	if not player or not inventory:
		return false

	# Torch: instant placement without preview mode
	if equipped_item == "torch":
		if placement_system and placement_system.has_method("place_torch_instant"):
			if placement_system.place_torch_instant():
				unequip()
				return true
		return false

	# Lodestone: instant placement without preview mode
	if equipped_item == "lodestone":
		if placement_system and placement_system.has_method("place_lodestone_instant"):
			if placement_system.place_lodestone_instant():
				unequip()
				return true
		return false

	# Delegate to PlacementSystem for all other placeable items
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

	# Base rocks (visual) - blocky
	var rocks_mesh: MeshInstance3D = MeshInstance3D.new()
	var rocks_box: BoxMesh = BoxMesh.new()
	rocks_box.size = Vector3(1.2, 0.3, 1.2)
	rocks_mesh.mesh = rocks_box

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

	# Fire visual (blocky box)
	var fire_mesh: MeshInstance3D = MeshInstance3D.new()
	var fire_box: BoxMesh = BoxMesh.new()
	fire_box.size = Vector3(0.5, 0.7, 0.5)
	fire_mesh.mesh = fire_box

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

	# Play tool break sound
	SFXManager.play_sfx("tool_break")

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
