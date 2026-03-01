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
		"slot": 13,
		"has_light": false,
		"tool_type": "grappling_hook"
	},
	"lodestone": {
		"name": "Lodestone",
		"slot": 23,
		"has_light": false,
		"placeable": true
	},
	"map": {
		"name": "Map",
		"slot": 24,
		"has_light": false,
		"tool_type": "map"
	},
	"leather_axe_wrap": {
		"name": "Leather Axe Wrap",
		"slot": 25,
		"has_light": false,
		"tool_type": "upgrade",
		"upgrade_target": "axe",
		"durability_multiplier": 2
	},
	"leather_hook_wrap": {
		"name": "Leather Hook Wrap",
		"slot": 26,
		"has_light": false,
		"tool_type": "upgrade",
		"upgrade_target": "grappling_hook",
		"durability_multiplier": 3
	},
	"bow": {
		"name": "Bow",
		"slot": 27,
		"has_light": false,
		"tool_type": "bow"
	},
	"diamond_axe": {
		"name": "Diamond Axe",
		"slot": 28,
		"has_light": false,
		"tool_type": "axe",
		"effectiveness": 3.0
	},
	"enchanted_bow": {
		"name": "Enchanted Bow",
		"slot": 29,
		"has_light": false,
		"tool_type": "bow"
	},
	"hang_glider": {
		"name": "Hang Glider",
		"slot": 30,
		"has_light": false,
		"tool_type": "glider",
		"effectiveness": 1.0,
		"placeable": false,
		"upgrade_target": ""
	},
	"explorers_journal": {
		"name": "Explorer's Journal",
		"slot": 31,
		"has_light": false,
		"tool_type": "journal"
	}
}

# Tool durability settings
const TOOL_MAX_DURABILITY: Dictionary = {
	"primitive_axe": 50,
	"stone_axe": 150,
	"metal_axe": 300,
	"fishing_rod": 50,
	"machete": 200,
	"grappling_hook": 100,
	"bow": 80,
	"diamond_axe": 900,
	"enchanted_bow": 200
}

# Current durability for each tool (item_type -> current durability)
var tool_durability: Dictionary = {}

# Birch bark harvesting
var bark_harvest_tracker: Dictionary = {}  # position_key -> harvest_day
const BARK_REGROW_DAYS: int = 3

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
var fishing_cast_tween: Tween = null
var fish_caught_tween: Tween = null

# Placement cooldown to prevent rapid-fire placement
const PLACEMENT_COOLDOWN: float = 0.5
var placement_cooldown_timer: float = 0.0

# Block map reopening until use_equipped is fully released
var _map_open_blocked: bool = false

func _ready() -> void:
	# Get references from parent (player)
	# Use call_deferred because parent's @onready vars aren't set when children's _ready runs
	call_deferred("_setup_references")


func _process(delta: float) -> void:
	if placement_cooldown_timer > 0.0:
		placement_cooldown_timer -= delta
	if _map_open_blocked and not Input.is_action_pressed("use_equipped"):
		_map_open_blocked = false
	if _journal_open_blocked and not Input.is_action_pressed("use_equipped"):
		_journal_open_blocked = false


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
	# Block equipment input when any UI menu is open or game is paused
	if _is_ui_blocking_input():
		return

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

	# Check both physical_keycode and keycode for Mac compatibility
	var pkey: int = event.physical_keycode
	var kkey: int = event.keycode

	if pkey == KEY_1 or kkey == KEY_1:
		_try_equip_slot(1)
	elif pkey == KEY_2 or kkey == KEY_2:
		_try_equip_slot(2)
	elif pkey == KEY_3 or kkey == KEY_3:
		_try_equip_slot(3)
	elif pkey == KEY_4 or kkey == KEY_4:
		_try_equip_slot(4)
	elif pkey == KEY_5 or kkey == KEY_5:
		_try_equip_slot(5)
	elif pkey == KEY_6 or kkey == KEY_6:
		_try_equip_slot(6)
	elif pkey == KEY_7 or kkey == KEY_7:
		_try_equip_slot(7)
	elif pkey == KEY_8 or kkey == KEY_8:
		_try_equip_slot(8)
	elif pkey == KEY_9 or kkey == KEY_9:
		_try_equip_slot(9)
	elif pkey == KEY_0 or kkey == KEY_0:
		_try_equip_slot(10)
	elif pkey == KEY_MINUS or kkey == KEY_MINUS:
		_try_equip_slot(11)
	elif pkey == KEY_EQUAL or kkey == KEY_EQUAL:
		_try_equip_slot(12)
	elif pkey == KEY_BRACKETLEFT or kkey == KEY_BRACKETLEFT:
		_try_equip_slot(13)
	elif pkey == KEY_BRACKETRIGHT or kkey == KEY_BRACKETRIGHT:
		_try_equip_slot(24)
	elif pkey == KEY_BACKSLASH or kkey == KEY_BACKSLASH:
		_try_equip_slot(27)


## Check if any UI menu is open that should block equipment input.
func _is_ui_blocking_input() -> bool:
	if get_tree().paused:
		return true
	var player: Node = get_parent()
	if player and player.has_method("_is_ui_blocking_input"):
		return player._is_ui_blocking_input()
	return false


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

	# Show held models for light items (torch/lantern)
	if item_type == "torch":
		_create_torch_model()
	elif item_type == "lantern":
		_create_lantern_model()
	elif item_type == "rope":
		_create_rope_model()

	# Show placeable kit models
	if item_data.get("placeable", false):
		_create_kit_model(item_type)

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
	elif tool_type == "bow":
		_create_bow_model(item_type)
	elif tool_type == "map":
		_create_map_model()
	elif tool_type == "journal":
		_create_journal_model()
	elif tool_type == "glider":
		_create_hang_glider_model()

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
	_remove_torch_model()
	_remove_lantern_model()
	_remove_rope_model()
	_remove_map_model()
	_remove_journal_model()
	_remove_stone_axe()
	_remove_machete()
	_remove_fishing_rod()
	_remove_grappling_hook()
	_remove_bow_model()
	_remove_hang_glider_model()
	_remove_kit_model()

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
		elif tool_type == "map":
			return _use_map()
		elif tool_type == "journal":
			return _use_journal()
		elif tool_type == "upgrade":
			return _use_upgrade(equipped_item, item_data)
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

	# Machete on birch tree: harvest birch bark instead of chopping
	var item_data: Dictionary = EQUIPPABLE_ITEMS.get(equipped_item, {})
	if item_data.get("tool_type", "") == "machete" and target:
		var scene_path: String = target.scene_file_path if target.scene_file_path else ""
		if scene_path.ends_with("birch_tree_resource.tscn"):
			return _harvest_birch_bark(target)

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
			# Obstacles and single-hit collectibles (branches, stones) just get swing sound
			# Multi-chop resources (trees, ore) get the wood chop impact sound
			if target.is_in_group("obstacle"):
				pass  # Swing sound already played by _play_swing_animation()
			elif target is ResourceNode and target.chops_required <= 1:
				pass  # Single-hit collectible — swing sound already played
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

		axe_swing_tween = create_tween()
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

		axe_swing_tween = create_tween()
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
	light.shadow_enabled = false

	# Position at hand/torch height for better ground illumination
	light.position = Vector3(0.4, 0.8, -0.4)
	light.omni_attenuation = 0.6

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
	handle_mesh.size = Vector3(0.06, 0.55, 0.06) if axe_type == "diamond_axe" else Vector3(0.06, 0.5, 0.06)
	handle.mesh = handle_mesh

	var handle_mat := StandardMaterial3D.new()
	if axe_type == "diamond_axe":
		handle_mat.albedo_color = Color(0.3, 0.25, 0.18)  # Dark refined hardwood
	else:
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
		"diamond_axe":
			_add_diamond_axe_head(stone_axe_model)
		_:
			_add_stone_axe_head(stone_axe_model)  # Default to stone

	# Add leather wrap visuals if upgraded
	if has_meta("durability_upgrades"):
		var upgrades: Dictionary = get_meta("durability_upgrades")
		if upgrades.has(axe_type):
			_add_leather_wrap_to_axe(stone_axe_model)

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


func _add_diamond_axe_head(axe_model: Node3D) -> void:
	# Silver pommel cap at handle bottom
	var pommel := MeshInstance3D.new()
	pommel.name = "Pommel"
	var pommel_mesh := BoxMesh.new()
	pommel_mesh.size = Vector3(0.08, 0.04, 0.08)
	pommel.mesh = pommel_mesh
	var pommel_mat := StandardMaterial3D.new()
	pommel_mat.albedo_color = Color(0.7, 0.72, 0.78)  # Silver-blue
	pommel_mat.metallic = 0.8
	pommel_mat.roughness = 0.2
	pommel.material_override = pommel_mat
	pommel.position = Vector3(0, -0.26, 0)
	axe_model.add_child(pommel)

	# Silver mount connecting handle to diamond head
	var mount := MeshInstance3D.new()
	mount.name = "Mount"
	var mount_mesh := BoxMesh.new()
	mount_mesh.size = Vector3(0.09, 0.06, 0.09)
	mount.mesh = mount_mesh
	var mount_mat := StandardMaterial3D.new()
	mount_mat.albedo_color = Color(0.65, 0.68, 0.75)  # Polished silver
	mount_mat.metallic = 0.85
	mount_mat.roughness = 0.15
	mount.material_override = mount_mat
	mount.position = Vector3(0, 0.22, 0)
	axe_model.add_child(mount)

	# Accent ring on mount
	var ring := MeshInstance3D.new()
	ring.name = "AccentRing"
	var ring_mesh := BoxMesh.new()
	ring_mesh.size = Vector3(0.10, 0.02, 0.10)
	ring.mesh = ring_mesh
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.5, 0.6, 0.85)  # Blue-tinted silver
	ring_mat.metallic = 0.9
	ring_mat.roughness = 0.1
	ring.material_override = ring_mat
	ring.position = Vector3(0, 0.24, 0)
	axe_model.add_child(ring)

	# Main diamond head body - deep blue with subtle glow
	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.07, 0.16, 0.22)
	head.mesh = head_mesh
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.35, 0.55, 0.9)  # Deep diamond blue
	head_mat.metallic = 0.4
	head_mat.roughness = 0.08
	head_mat.emission_enabled = true
	head_mat.emission = Color(0.25, 0.4, 0.8)
	head_mat.emission_energy_multiplier = 1.2
	head.material_override = head_mat
	head.position = Vector3(0, 0.26, -0.08)
	axe_model.add_child(head)

	# Left facet panel - lighter blue, angled to simulate cut diamond face
	var facet_left := MeshInstance3D.new()
	facet_left.name = "FacetLeft"
	var fl_mesh := BoxMesh.new()
	fl_mesh.size = Vector3(0.02, 0.13, 0.18)
	facet_left.mesh = fl_mesh
	var facet_mat := StandardMaterial3D.new()
	facet_mat.albedo_color = Color(0.45, 0.65, 0.95)  # Mid-blue facet
	facet_mat.metallic = 0.5
	facet_mat.roughness = 0.05
	facet_mat.emission_enabled = true
	facet_mat.emission = Color(0.3, 0.5, 0.85)
	facet_mat.emission_energy_multiplier = 0.8
	facet_left.material_override = facet_mat
	facet_left.position = Vector3(-0.04, 0.26, -0.08)
	facet_left.rotation_degrees = Vector3(0, 0, 8)
	axe_model.add_child(facet_left)

	# Right facet panel - mirror of left
	var facet_right := MeshInstance3D.new()
	facet_right.name = "FacetRight"
	var fr_mesh := BoxMesh.new()
	fr_mesh.size = Vector3(0.02, 0.13, 0.18)
	facet_right.mesh = fr_mesh
	facet_right.material_override = facet_mat  # Reuse same material
	facet_right.position = Vector3(0.04, 0.26, -0.08)
	facet_right.rotation_degrees = Vector3(0, 0, -8)
	axe_model.add_child(facet_right)

	# Inner core highlight - bright cyan sparkle inside the head
	var core := MeshInstance3D.new()
	core.name = "CoreHighlight"
	var core_mesh := BoxMesh.new()
	core_mesh.size = Vector3(0.02, 0.06, 0.08)
	core.mesh = core_mesh
	var core_mat := StandardMaterial3D.new()
	core_mat.albedo_color = Color(0.6, 0.85, 1.0)  # Bright cyan-white
	core_mat.metallic = 0.6
	core_mat.roughness = 0.02
	core_mat.emission_enabled = true
	core_mat.emission = Color(0.5, 0.8, 1.0)
	core_mat.emission_energy_multiplier = 2.0
	core_mat.render_priority = 1
	core.material_override = core_mat
	core.position = Vector3(0, 0.28, -0.08)
	axe_model.add_child(core)

	# Crystalline blade edge - bright blue-white, sharp and luminous
	var blade := MeshInstance3D.new()
	blade.name = "Blade"
	var blade_mesh := BoxMesh.new()
	blade_mesh.size = Vector3(0.04, 0.14, 0.02)
	blade.mesh = blade_mesh
	var blade_mat := StandardMaterial3D.new()
	blade_mat.albedo_color = Color(0.55, 0.78, 1.0)  # Blue-white crystal edge
	blade_mat.metallic = 0.7
	blade_mat.roughness = 0.03
	blade_mat.emission_enabled = true
	blade_mat.emission = Color(0.5, 0.75, 1.0)
	blade_mat.emission_energy_multiplier = 2.5
	blade.material_override = blade_mat
	blade.position = Vector3(0, 0.26, -0.20)
	axe_model.add_child(blade)


## Add leather wrapping strips to axe handle to show durability upgrade.
func _add_leather_wrap_to_axe(axe_model: Node3D) -> void:
	var leather_mat: StandardMaterial3D = StandardMaterial3D.new()
	leather_mat.albedo_color = Color(0.55, 0.30, 0.15)  # Rich leather brown
	leather_mat.roughness = 0.8

	# Three leather strips wrapped around the handle at different heights
	for i: int in range(3):
		var wrap: MeshInstance3D = MeshInstance3D.new()
		wrap.name = "LeatherWrap%d" % i
		var wrap_mesh: BoxMesh = BoxMesh.new()
		wrap_mesh.size = Vector3(0.075, 0.04, 0.075)
		wrap.mesh = wrap_mesh
		wrap.position = Vector3(0, -0.08 + i * 0.10, 0)
		wrap.material_override = leather_mat
		axe_model.add_child(wrap)

	# Leather guard piece near the axe head
	var guard: MeshInstance3D = MeshInstance3D.new()
	guard.name = "LeatherGuard"
	var guard_mesh: BoxMesh = BoxMesh.new()
	guard_mesh.size = Vector3(0.085, 0.06, 0.085)
	guard.mesh = guard_mesh
	guard.position = Vector3(0, 0.16, 0)
	guard.material_override = leather_mat
	axe_model.add_child(guard)


## Add leather wrapping strips to grappling hook handle to show durability upgrade.
func _add_leather_wrap_to_hook(hook_model: Node3D) -> void:
	var leather_mat: StandardMaterial3D = StandardMaterial3D.new()
	leather_mat.albedo_color = Color(0.55, 0.30, 0.15)  # Rich leather brown
	leather_mat.roughness = 0.8

	# Leather grip wrap around handle
	for i: int in range(3):
		var wrap: MeshInstance3D = MeshInstance3D.new()
		wrap.name = "LeatherWrap%d" % i
		var wrap_mesh: BoxMesh = BoxMesh.new()
		wrap_mesh.size = Vector3(0.055, 0.03, 0.055)
		wrap.mesh = wrap_mesh
		wrap.position = Vector3(0, -0.04 + i * 0.06, 0)
		wrap.material_override = leather_mat
		hook_model.add_child(wrap)

	# Leather pad where rope meets handle
	var pad: MeshInstance3D = MeshInstance3D.new()
	pad.name = "LeatherPad"
	var pad_mesh: BoxMesh = BoxMesh.new()
	pad_mesh.size = Vector3(0.07, 0.04, 0.07)
	pad.mesh = pad_mesh
	pad.position = Vector3(0, 0.08, 0)
	pad.material_override = leather_mat
	hook_model.add_child(pad)


func _remove_stone_axe() -> void:
	if axe_swing_tween and axe_swing_tween.is_valid():
		axe_swing_tween.kill()
	axe_swing_tween = null
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
	if axe_swing_tween and axe_swing_tween.is_valid():
		axe_swing_tween.kill()
	axe_swing_tween = null
	if machete_model:
		machete_model.queue_free()
		machete_model = null


func _create_torch_model() -> void:
	if torch_model:
		return

	torch_model = Node3D.new()
	torch_model.name = "TorchModel"

	# Wooden handle (short stick)
	var handle := MeshInstance3D.new()
	handle.name = "Handle"
	var handle_mesh := BoxMesh.new()
	handle_mesh.size = Vector3(0.05, 0.35, 0.05)
	handle.mesh = handle_mesh

	var handle_mat := StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.45, 0.35, 0.2)
	handle.material_override = handle_mat
	handle.position = Vector3(0, 0, 0)

	torch_model.add_child(handle)

	# Cloth wrap near top
	var wrap := MeshInstance3D.new()
	wrap.name = "ClothWrap"
	var wrap_mesh := BoxMesh.new()
	wrap_mesh.size = Vector3(0.065, 0.08, 0.065)
	wrap.mesh = wrap_mesh

	var wrap_mat := StandardMaterial3D.new()
	wrap_mat.albedo_color = Color(0.35, 0.25, 0.15)
	wrap.material_override = wrap_mat
	wrap.position = Vector3(0, 0.15, 0)

	torch_model.add_child(wrap)

	# Flame base (orange)
	var flame_base := MeshInstance3D.new()
	flame_base.name = "FlameBase"
	var flame_base_mesh := BoxMesh.new()
	flame_base_mesh.size = Vector3(0.08, 0.1, 0.08)
	flame_base.mesh = flame_base_mesh

	var flame_base_mat := StandardMaterial3D.new()
	flame_base_mat.albedo_color = Color(1.0, 0.5, 0.1)
	flame_base_mat.emission_enabled = true
	flame_base_mat.emission = Color(1.0, 0.4, 0.0)
	flame_base_mat.emission_energy_multiplier = 2.0
	flame_base.material_override = flame_base_mat
	flame_base.position = Vector3(0, 0.23, 0)

	torch_model.add_child(flame_base)

	# Flame tip (yellow, smaller)
	var flame_tip := MeshInstance3D.new()
	flame_tip.name = "FlameTip"
	var flame_tip_mesh := BoxMesh.new()
	flame_tip_mesh.size = Vector3(0.05, 0.08, 0.05)
	flame_tip.mesh = flame_tip_mesh

	var flame_tip_mat := StandardMaterial3D.new()
	flame_tip_mat.albedo_color = Color(1.0, 0.85, 0.3)
	flame_tip_mat.emission_enabled = true
	flame_tip_mat.emission = Color(1.0, 0.8, 0.2)
	flame_tip_mat.emission_energy_multiplier = 3.0
	flame_tip.material_override = flame_tip_mat
	flame_tip.position = Vector3(0, 0.31, 0)

	torch_model.add_child(flame_tip)

	# Position: right hand, angled slightly forward
	torch_model.position = TORCH_REST_POSITION
	torch_model.rotation_degrees = TORCH_REST_ROTATION

	# Attach to camera
	if player:
		var camera: Camera3D = player.get_node_or_null("Camera3D")
		if camera:
			camera.add_child(torch_model)


func _remove_torch_model() -> void:
	if torch_model:
		torch_model.queue_free()
		torch_model = null


func _create_lantern_model() -> void:
	if lantern_model:
		return

	lantern_model = Node3D.new()
	lantern_model.name = "LanternModel"

	var metal_mat := StandardMaterial3D.new()
	metal_mat.albedo_color = Color(0.5, 0.5, 0.52)
	metal_mat.metallic = 0.6
	metal_mat.roughness = 0.4

	# Base plate
	var base := MeshInstance3D.new()
	base.name = "Base"
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(0.1, 0.02, 0.1)
	base.mesh = base_mesh
	base.material_override = metal_mat
	base.position = Vector3(0, 0, 0)

	lantern_model.add_child(base)

	# Left frame post
	var post_left := MeshInstance3D.new()
	post_left.name = "PostLeft"
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.015, 0.2, 0.015)
	post_left.mesh = post_mesh
	post_left.material_override = metal_mat
	post_left.position = Vector3(-0.04, 0.11, 0)

	lantern_model.add_child(post_left)

	# Right frame post
	var post_right := MeshInstance3D.new()
	post_right.name = "PostRight"
	post_right.mesh = post_mesh
	post_right.material_override = metal_mat
	post_right.position = Vector3(0.04, 0.11, 0)

	lantern_model.add_child(post_right)

	# Top plate
	var top := MeshInstance3D.new()
	top.name = "Top"
	var top_mesh := BoxMesh.new()
	top_mesh.size = Vector3(0.1, 0.02, 0.1)
	top.mesh = top_mesh
	top.material_override = metal_mat
	top.position = Vector3(0, 0.22, 0)

	lantern_model.add_child(top)

	# Handle/bail on top
	var bail := MeshInstance3D.new()
	bail.name = "Bail"
	var bail_mesh := BoxMesh.new()
	bail_mesh.size = Vector3(0.06, 0.015, 0.015)
	bail.mesh = bail_mesh
	bail.material_override = metal_mat
	bail.position = Vector3(0, 0.27, 0)

	lantern_model.add_child(bail)

	# Bail vertical arms
	var bail_arm_l := MeshInstance3D.new()
	bail_arm_l.name = "BailArmL"
	var bail_arm_mesh := BoxMesh.new()
	bail_arm_mesh.size = Vector3(0.015, 0.05, 0.015)
	bail_arm_l.mesh = bail_arm_mesh
	bail_arm_l.material_override = metal_mat
	bail_arm_l.position = Vector3(-0.025, 0.25, 0)

	lantern_model.add_child(bail_arm_l)

	var bail_arm_r := MeshInstance3D.new()
	bail_arm_r.name = "BailArmR"
	bail_arm_r.mesh = bail_arm_mesh
	bail_arm_r.material_override = metal_mat
	bail_arm_r.position = Vector3(0.025, 0.25, 0)

	lantern_model.add_child(bail_arm_r)

	# Glass panel (translucent, emissive to look lit)
	var glass := MeshInstance3D.new()
	glass.name = "Glass"
	var glass_mesh := BoxMesh.new()
	glass_mesh.size = Vector3(0.07, 0.16, 0.07)
	glass.mesh = glass_mesh

	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.9, 0.95, 1.0, 0.4)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.emission_enabled = true
	glass_mat.emission = Color(0.9, 0.95, 1.0)
	glass_mat.emission_energy_multiplier = 1.5
	glass.material_override = glass_mat
	glass.position = Vector3(0, 0.11, 0)

	lantern_model.add_child(glass)

	# Position: held to the side, slightly lower
	lantern_model.position = LANTERN_REST_POSITION
	lantern_model.rotation_degrees = LANTERN_REST_ROTATION

	# Attach to camera
	if player:
		var camera: Camera3D = player.get_node_or_null("Camera3D")
		if camera:
			camera.add_child(lantern_model)


func _remove_lantern_model() -> void:
	if lantern_model:
		lantern_model.queue_free()
		lantern_model = null


func _create_map_model() -> void:
	if map_model:
		return

	map_model = Node3D.new()
	map_model.name = "MapModel"

	# Main parchment body (flat rectangle)
	var parchment := MeshInstance3D.new()
	parchment.name = "Parchment"
	var parchment_mesh := BoxMesh.new()
	parchment_mesh.size = Vector3(0.35, 0.25, 0.01)
	parchment.mesh = parchment_mesh

	var parchment_mat := StandardMaterial3D.new()
	parchment_mat.albedo_color = Color(0.85, 0.78, 0.6)  # Tan/cream
	parchment.material_override = parchment_mat
	parchment.position = Vector3(0, 0, 0)

	map_model.add_child(parchment)

	# Left curled edge
	var curl_left := MeshInstance3D.new()
	curl_left.name = "CurlLeft"
	var curl_mesh := BoxMesh.new()
	curl_mesh.size = Vector3(0.03, 0.25, 0.03)
	curl_left.mesh = curl_mesh

	var curl_mat := StandardMaterial3D.new()
	curl_mat.albedo_color = Color(0.8, 0.72, 0.55)  # Slightly darker
	curl_left.material_override = curl_mat
	curl_left.position = Vector3(-0.18, 0, 0.01)

	map_model.add_child(curl_left)

	# Right curled edge
	var curl_right := MeshInstance3D.new()
	curl_right.name = "CurlRight"
	curl_right.mesh = curl_mesh
	curl_right.material_override = curl_mat
	curl_right.position = Vector3(0.18, 0, 0.01)

	map_model.add_child(curl_right)

	var border_mat := StandardMaterial3D.new()
	border_mat.albedo_color = Color(0.3, 0.25, 0.2)  # Dark brown border

	# Top border line
	var border_top := MeshInstance3D.new()
	border_top.name = "BorderTop"
	var border_h_mesh := BoxMesh.new()
	border_h_mesh.size = Vector3(0.3, 0.008, 0.012)
	border_top.mesh = border_h_mesh
	border_top.material_override = border_mat
	border_top.position = Vector3(0, 0.11, 0.005)

	map_model.add_child(border_top)

	# Bottom border line
	var border_bottom := MeshInstance3D.new()
	border_bottom.name = "BorderBottom"
	border_bottom.mesh = border_h_mesh
	border_bottom.material_override = border_mat
	border_bottom.position = Vector3(0, -0.11, 0.005)

	map_model.add_child(border_bottom)

	# Left border line
	var border_left := MeshInstance3D.new()
	border_left.name = "BorderLeft"
	var border_v_mesh := BoxMesh.new()
	border_v_mesh.size = Vector3(0.008, 0.22, 0.012)
	border_left.mesh = border_v_mesh
	border_left.material_override = border_mat
	border_left.position = Vector3(-0.14, 0, 0.005)

	map_model.add_child(border_left)

	# Right border line
	var border_right := MeshInstance3D.new()
	border_right.name = "BorderRight"
	border_right.mesh = border_v_mesh
	border_right.material_override = border_mat
	border_right.position = Vector3(0.14, 0, 0.005)

	map_model.add_child(border_right)

	# Position: held in front, centered and lower
	map_model.position = MAP_REST_POSITION
	map_model.rotation_degrees = MAP_REST_ROTATION

	# Attach to camera
	if player:
		var camera: Camera3D = player.get_node_or_null("Camera3D")
		if camera:
			camera.add_child(map_model)


func _remove_map_model() -> void:
	if map_model:
		map_model.queue_free()
		map_model = null


func _create_journal_model() -> void:
	if journal_model:
		return

	journal_model = Node3D.new()
	journal_model.name = "JournalModel"

	# Leather cover (dark reddish-brown)
	var cover := MeshInstance3D.new()
	cover.name = "Cover"
	var cover_mesh := BoxMesh.new()
	cover_mesh.size = Vector3(0.22, 0.28, 0.045)
	cover.mesh = cover_mesh
	var cover_mat := StandardMaterial3D.new()
	cover_mat.albedo_color = Color(0.38, 0.18, 0.08)
	cover.material_override = cover_mat
	journal_model.add_child(cover)

	# Cream page block inset
	var pages := MeshInstance3D.new()
	pages.name = "Pages"
	var pages_mesh := BoxMesh.new()
	pages_mesh.size = Vector3(0.18, 0.24, 0.035)
	pages.mesh = pages_mesh
	var pages_mat := StandardMaterial3D.new()
	pages_mat.albedo_color = Color(0.88, 0.82, 0.68)
	pages.material_override = pages_mat
	pages.position = Vector3(0.01, 0, 0.002)
	journal_model.add_child(pages)

	# Darker spine strip on left edge
	var spine := MeshInstance3D.new()
	spine.name = "Spine"
	var spine_mesh := BoxMesh.new()
	spine_mesh.size = Vector3(0.025, 0.28, 0.048)
	spine.mesh = spine_mesh
	var spine_mat := StandardMaterial3D.new()
	spine_mat.albedo_color = Color(0.28, 0.12, 0.05)
	spine.material_override = spine_mat
	spine.position = Vector3(-0.1, 0, 0)
	journal_model.add_child(spine)

	# Leather strap across front
	var strap := MeshInstance3D.new()
	strap.name = "Strap"
	var strap_mesh := BoxMesh.new()
	strap_mesh.size = Vector3(0.22, 0.02, 0.05)
	strap.mesh = strap_mesh
	var strap_mat := StandardMaterial3D.new()
	strap_mat.albedo_color = Color(0.32, 0.15, 0.06)
	strap.material_override = strap_mat
	strap.position = Vector3(0, -0.02, 0)
	journal_model.add_child(strap)

	# Brass clasp accent on strap
	var clasp := MeshInstance3D.new()
	clasp.name = "Clasp"
	var clasp_mesh := BoxMesh.new()
	clasp_mesh.size = Vector3(0.025, 0.025, 0.055)
	clasp.mesh = clasp_mesh
	var clasp_mat := StandardMaterial3D.new()
	clasp_mat.albedo_color = Color(0.75, 0.6, 0.2)
	clasp_mat.metallic = 0.7
	clasp.material_override = clasp_mat
	clasp.position = Vector3(0.09, -0.02, 0)
	journal_model.add_child(clasp)

	# Position held in hand
	journal_model.position = JOURNAL_REST_POSITION
	journal_model.rotation_degrees = JOURNAL_REST_ROTATION

	# Attach to camera
	if player:
		var camera: Camera3D = player.get_node_or_null("Camera3D")
		if camera:
			camera.add_child(journal_model)


func _remove_journal_model() -> void:
	if journal_model:
		journal_model.queue_free()
		journal_model = null


func _use_journal() -> bool:
	if not player:
		return false

	# Block reopening until use_equipped is fully released
	if _journal_open_blocked:
		return true

	_journal_open_blocked = true

	# Delegate to player's existing _open_journal() method
	if player.has_method("_open_journal"):
		player._open_journal()
	return true


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
	if fishing_cast_tween and fishing_cast_tween.is_valid():
		fishing_cast_tween.kill()
	fishing_cast_tween = null
	if fish_caught_tween and fish_caught_tween.is_valid():
		fish_caught_tween.kill()
	fish_caught_tween = null
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
	if fishing_cast_tween and fishing_cast_tween.is_valid():
		fishing_cast_tween.kill()
	fishing_cast_tween = player.create_tween()
	fishing_cast_tween.tween_property(fishing_rod_model, "rotation_degrees:x", original_rot.x - 25, 0.15)
	fishing_cast_tween.tween_property(fishing_rod_model, "rotation_degrees:x", original_rot.x, 0.3)


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
	if fish_caught_tween and fish_caught_tween.is_valid():
		fish_caught_tween.kill()
	fish_caught_tween = player.create_tween()

	# Pull rod up while reeling fish closer
	fish_caught_tween.tween_property(fishing_rod_model, "rotation_degrees:x", original_rot.x + 20, 0.3)
	fish_caught_tween.parallel().tween_property(caught_fish_model, "position", Vector3(0, 0.8, 0), 0.5)
	fish_caught_tween.parallel().tween_property(caught_fish_model, "rotation:y", TAU, 0.5)  # Fish spins

	# Hide fish and line after animation
	fish_caught_tween.tween_callback(_hide_fishing_visuals)
	fish_caught_tween.tween_property(fishing_rod_model, "rotation_degrees:x", original_rot.x, 0.2)


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
	if is_instance_valid(caught_fish_model):
		caught_fish_model.visible = false
	if is_instance_valid(line_pivot):
		line_pivot.visible = false
	is_line_cast = false


## Hide the fishing line (called when fish gets away or fishing is cancelled).
func hide_fishing_line() -> void:
	if is_instance_valid(line_pivot):
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

	# Add leather wrap visuals if upgraded
	if has_meta("durability_upgrades"):
		var upgrades: Dictionary = get_meta("durability_upgrades")
		if upgrades.has("grappling_hook"):
			_add_leather_wrap_to_hook(grappling_hook_model)

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


# Torch held model
var torch_model: Node3D = null
const TORCH_REST_POSITION: Vector3 = Vector3(0.3, -0.3, -0.6)
const TORCH_REST_ROTATION: Vector3 = Vector3(15, 0, -15)

# Lantern held model
var lantern_model: Node3D = null
const LANTERN_REST_POSITION: Vector3 = Vector3(0.35, -0.35, -0.55)
const LANTERN_REST_ROTATION: Vector3 = Vector3(0, 0, -10)

# Map held model
var map_model: Node3D = null
const MAP_REST_POSITION: Vector3 = Vector3(0.0, -0.4, -0.5)
const MAP_REST_ROTATION: Vector3 = Vector3(-30, 0, 0)

# Journal held model
var journal_model: Node3D = null
const JOURNAL_REST_POSITION: Vector3 = Vector3(0.25, -0.35, -0.5)
const JOURNAL_REST_ROTATION: Vector3 = Vector3(-20, -10, 5)
var _journal_open_blocked: bool = false

# Rope held model
var rope_model: Node3D = null
const ROPE_REST_POSITION: Vector3 = Vector3(0.3, -0.28, -0.55)
const ROPE_REST_ROTATION: Vector3 = Vector3(10, 0, -15)

func _create_rope_model() -> void:
	if rope_model:
		return

	rope_model = Node3D.new()
	rope_model.name = "RopeModel"

	# Shared materials — two rope shades for visual variety
	var rope_mat := StandardMaterial3D.new()
	rope_mat.albedo_color = Color(0.6, 0.5, 0.35)  # Tan hemp
	var rope_dark := StandardMaterial3D.new()
	rope_dark.albedo_color = Color(0.52, 0.42, 0.3)  # Darker hemp

	# Build a round coil: small box segments arranged in a circle (torus shape).
	# 3 stacked loops give the coil thickness/height.
	var seg_mesh := BoxMesh.new()
	seg_mesh.size = Vector3(0.025, 0.025, 0.025)  # Each segment is a small cube
	var coil_radius: float = 0.055  # Radius of the coil ring
	var segments: int = 12  # Segments per ring
	var loops: int = 3  # Stacked loops

	for loop: int in range(loops):
		var y_offset: float = loop * 0.026  # Stack each loop upward
		for i: int in range(segments):
			var angle: float = (float(i) / segments) * TAU
			var seg := MeshInstance3D.new()
			seg.mesh = seg_mesh
			# Alternate materials for visual texture
			seg.material_override = rope_mat if (i + loop) % 2 == 0 else rope_dark
			seg.position = Vector3(
				cos(angle) * coil_radius,
				y_offset,
				sin(angle) * coil_radius
			)
			# Rotate each segment to follow the curve of the ring
			seg.rotation.y = -angle
			rope_model.add_child(seg)

	# Trailing rope end hanging down from the coil
	var tail := MeshInstance3D.new()
	tail.name = "RopeTail"
	var tail_mesh := BoxMesh.new()
	tail_mesh.size = Vector3(0.02, 0.12, 0.02)
	tail.mesh = tail_mesh
	tail.material_override = rope_mat
	tail.position = Vector3(coil_radius, -0.06, 0)
	tail.rotation_degrees = Vector3(5, 0, 10)
	rope_model.add_child(tail)

	rope_model.position = ROPE_REST_POSITION
	rope_model.rotation_degrees = ROPE_REST_ROTATION

	if player:
		var cam: Camera3D = player.get_node_or_null("Camera3D")
		if cam:
			cam.add_child(rope_model)


func _remove_rope_model() -> void:
	if rope_model:
		rope_model.queue_free()
		rope_model = null


# Bow visual
var bow_model: Node3D = null
const BOW_REST_POSITION: Vector3 = Vector3(0.25, -0.12, -0.45)
const BOW_REST_ROTATION: Vector3 = Vector3(5, 10, -10)


func _create_bow_model(bow_type: String = "bow") -> void:
	if bow_model:
		return
	var bow_system: Node = get_parent().get_node_or_null("BowSystem") if get_parent() else null
	if bow_system and bow_system.has_method("build_bow_model"):
		bow_model = bow_system.build_bow_model(bow_type)
		if bow_model:
			bow_model.position = BOW_REST_POSITION
			bow_model.rotation_degrees = BOW_REST_ROTATION
			if player:
				var camera: Camera3D = player.get_node_or_null("Camera3D")
				if camera:
					camera.add_child(bow_model)


func _remove_bow_model() -> void:
	var bow_system: Node = get_parent().get_node_or_null("BowSystem") if get_parent() else null
	if bow_system and bow_system.has_method("clear_bow_model"):
		bow_system.clear_bow_model()
	bow_model = null


# Hang glider visual
var hang_glider_model: Node3D = null
const GLIDER_REST_POSITION: Vector3 = Vector3(0.0, 0.15, -0.7)
const GLIDER_REST_ROTATION: Vector3 = Vector3(5, 0, 0)


func _create_hang_glider_model() -> void:
	if hang_glider_model:
		return

	hang_glider_model = Node3D.new()
	hang_glider_model.name = "HangGliderModel"

	# --- Materials ---
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.35, 0.28, 0.18)  # Dark wood for grip bar

	var strut_mat := StandardMaterial3D.new()
	strut_mat.albedo_color = Color(0.45, 0.35, 0.22)  # Branch-colored struts

	var fabric_mat := StandardMaterial3D.new()
	fabric_mat.albedo_color = Color(0.75, 0.68, 0.55)  # Canvas tan

	var fabric_dark_mat := StandardMaterial3D.new()
	fabric_dark_mat.albedo_color = Color(0.68, 0.60, 0.48)  # Slightly darker canvas for variation

	# --- Central grip bar (horizontal, held in front) ---
	var grip := MeshInstance3D.new()
	grip.name = "GripBar"
	var grip_mesh := BoxMesh.new()
	grip_mesh.size = Vector3(0.4, 0.04, 0.04)
	grip.mesh = grip_mesh
	grip.material_override = wood_mat
	grip.position = Vector3(0, 0, 0)
	hang_glider_model.add_child(grip)

	# Grip wrapping detail (lighter wood accent)
	var grip_wrap := MeshInstance3D.new()
	grip_wrap.name = "GripWrap"
	var wrap_mesh := BoxMesh.new()
	wrap_mesh.size = Vector3(0.12, 0.045, 0.045)
	grip_wrap.mesh = wrap_mesh
	var wrap_mat := StandardMaterial3D.new()
	wrap_mat.albedo_color = Color(0.55, 0.45, 0.3)  # Lighter leather wrap
	grip_wrap.material_override = wrap_mat
	grip_wrap.position = Vector3(0, 0, 0)
	hang_glider_model.add_child(grip_wrap)

	# --- Left wing strut (extends forward-left at ~30 degrees) ---
	var strut_left := MeshInstance3D.new()
	strut_left.name = "StrutLeft"
	var strut_mesh := BoxMesh.new()
	strut_mesh.size = Vector3(0.03, 0.03, 0.4)
	strut_left.mesh = strut_mesh
	strut_left.material_override = strut_mat
	strut_left.position = Vector3(-0.17, 0.01, -0.17)
	strut_left.rotation_degrees = Vector3(0, 30, 0)
	hang_glider_model.add_child(strut_left)

	# --- Right wing strut (extends forward-right at ~-30 degrees) ---
	var strut_right := MeshInstance3D.new()
	strut_right.name = "StrutRight"
	strut_right.mesh = strut_mesh
	strut_right.material_override = strut_mat
	strut_right.position = Vector3(0.17, 0.01, -0.17)
	strut_right.rotation_degrees = Vector3(0, -30, 0)
	hang_glider_model.add_child(strut_right)

	# --- Cross-strut connecting outer ends of wing struts ---
	var cross_strut := MeshInstance3D.new()
	cross_strut.name = "CrossStrut"
	var cross_mesh := BoxMesh.new()
	cross_mesh.size = Vector3(0.5, 0.025, 0.025)
	cross_strut.mesh = cross_mesh
	cross_strut.material_override = strut_mat
	cross_strut.position = Vector3(0, 0.01, -0.35)
	hang_glider_model.add_child(cross_strut)

	# --- Left fabric panel (fills triangle between grip, left strut, cross-strut) ---
	var fabric_left := MeshInstance3D.new()
	fabric_left.name = "FabricLeft"
	var fabric_mesh := BoxMesh.new()
	fabric_mesh.size = Vector3(0.28, 0.005, 0.25)
	fabric_left.mesh = fabric_mesh
	fabric_left.material_override = fabric_mat
	fabric_left.position = Vector3(-0.1, 0.005, -0.18)
	fabric_left.rotation_degrees = Vector3(0, 8, 0)
	hang_glider_model.add_child(fabric_left)

	# --- Right fabric panel ---
	var fabric_right := MeshInstance3D.new()
	fabric_right.name = "FabricRight"
	fabric_right.mesh = fabric_mesh
	fabric_right.material_override = fabric_dark_mat  # Slightly different shade for depth
	fabric_right.position = Vector3(0.1, 0.005, -0.18)
	fabric_right.rotation_degrees = Vector3(0, -8, 0)
	hang_glider_model.add_child(fabric_right)

	# --- Fabric stitching detail (thin strip along center seam) ---
	var seam := MeshInstance3D.new()
	seam.name = "CenterSeam"
	var seam_mesh := BoxMesh.new()
	seam_mesh.size = Vector3(0.015, 0.008, 0.22)
	seam.mesh = seam_mesh
	var seam_mat := StandardMaterial3D.new()
	seam_mat.albedo_color = Color(0.6, 0.52, 0.38)  # Stitching color
	seam.material_override = seam_mat
	seam.position = Vector3(0, 0.008, -0.2)
	hang_glider_model.add_child(seam)

	# --- Leading edge reinforcement (darker strip along cross-strut) ---
	var leading_edge := MeshInstance3D.new()
	leading_edge.name = "LeadingEdge"
	var edge_mesh := BoxMesh.new()
	edge_mesh.size = Vector3(0.46, 0.01, 0.03)
	leading_edge.mesh = edge_mesh
	leading_edge.material_override = fabric_dark_mat
	leading_edge.position = Vector3(0, 0.005, -0.33)
	hang_glider_model.add_child(leading_edge)

	# Position: held above and slightly in front of camera
	hang_glider_model.position = GLIDER_REST_POSITION
	hang_glider_model.rotation_degrees = GLIDER_REST_ROTATION

	# Attach to camera
	if player:
		var camera: Camera3D = player.get_node_or_null("Camera3D")
		if camera:
			camera.add_child(hang_glider_model)


func _remove_hang_glider_model() -> void:
	if hang_glider_model:
		hang_glider_model.queue_free()
		hang_glider_model = null


# Held kit/placeable model
var kit_model: Node3D = null
const KIT_REST_POSITION: Vector3 = Vector3(0.3, -0.35, -0.55)
const KIT_REST_ROTATION: Vector3 = Vector3(5, -10, -5)

# Accent colors for each placeable kit
const KIT_ACCENT_COLORS: Dictionary = {
	"campfire_kit": Color(0.9, 0.45, 0.15),       # Orange-red (fire)
	"shelter_kit": Color(0.55, 0.45, 0.3),         # Tan (wood/hide)
	"storage_box": Color(0.6, 0.5, 0.3),           # Warm brown (crate)
	"crafting_bench_kit": Color(0.5, 0.4, 0.25),   # Dark wood
	"drying_rack_kit": Color(0.7, 0.6, 0.4),       # Light wood/rope
	"garden_plot_kit": Color(0.35, 0.6, 0.3),      # Green (plants)
	"canvas_tent_kit": Color(0.75, 0.7, 0.6),      # Canvas off-white
	"cabin_kit": Color(0.45, 0.32, 0.18),          # Dark timber
	"snare_trap_kit": Color(0.6, 0.55, 0.45),      # Rope/twine tan
	"smithing_station_kit": Color(0.45, 0.45, 0.5), # Steel grey
	"smoker_kit": Color(0.5, 0.42, 0.35),          # Smoky brown
	"lodestone": Color(0.4, 0.6, 0.8),             # Magnetic blue
}


func _create_kit_model(item_type: String) -> void:
	if kit_model:
		return

	var is_lodestone: bool = item_type == "lodestone"

	if is_lodestone:
		_build_lodestone_model()
	else:
		_build_kit_bundle_model(item_type)

	if kit_model and player:
		var camera: Camera3D = player.get_node_or_null("Camera3D")
		if camera:
			camera.add_child(kit_model)


func _build_kit_bundle_model(item_type: String) -> void:
	kit_model = Node3D.new()
	kit_model.name = "KitModel"

	var accent_color: Color = KIT_ACCENT_COLORS.get(item_type, Color(0.5, 0.5, 0.5))

	# Base bundle - wrapped parcel shape
	var bundle := MeshInstance3D.new()
	bundle.name = "Bundle"
	var bundle_mesh := BoxMesh.new()
	bundle_mesh.size = Vector3(0.12, 0.10, 0.14)
	bundle.mesh = bundle_mesh
	var bundle_mat := StandardMaterial3D.new()
	bundle_mat.albedo_color = Color(0.45, 0.38, 0.28)  # Burlap/canvas wrap
	bundle.material_override = bundle_mat
	bundle.position = Vector3(0, 0, 0)
	kit_model.add_child(bundle)

	# Accent band - colored strap around the bundle
	var band := MeshInstance3D.new()
	band.name = "AccentBand"
	var band_mesh := BoxMesh.new()
	band_mesh.size = Vector3(0.13, 0.025, 0.15)
	band.mesh = band_mesh
	var band_mat := StandardMaterial3D.new()
	band_mat.albedo_color = accent_color
	band.material_override = band_mat
	band.position = Vector3(0, 0.02, 0)
	kit_model.add_child(band)

	# Vertical cross-strap for visual interest
	var cross := MeshInstance3D.new()
	cross.name = "CrossStrap"
	var cross_mesh := BoxMesh.new()
	cross_mesh.size = Vector3(0.025, 0.11, 0.15)
	cross.mesh = cross_mesh
	var cross_mat := StandardMaterial3D.new()
	cross_mat.albedo_color = accent_color * 0.85  # Slightly darker variant
	cross.material_override = cross_mat
	cross.position = Vector3(0, 0, 0)
	kit_model.add_child(cross)

	kit_model.position = KIT_REST_POSITION
	kit_model.rotation_degrees = KIT_REST_ROTATION


func _build_lodestone_model() -> void:
	kit_model = Node3D.new()
	kit_model.name = "LodestoneModel"

	# Main stone body - dark, slightly metallic rock
	var stone := MeshInstance3D.new()
	stone.name = "Stone"
	var stone_mesh := BoxMesh.new()
	stone_mesh.size = Vector3(0.09, 0.07, 0.09)
	stone.mesh = stone_mesh
	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.25, 0.25, 0.3)  # Dark iron-grey
	stone_mat.metallic = 0.5
	stone_mat.roughness = 0.4
	stone.material_override = stone_mat
	stone.position = Vector3(0, 0, 0)
	kit_model.add_child(stone)

	# Glowing vein - magnetic blue streak across the stone
	var vein := MeshInstance3D.new()
	vein.name = "MagneticVein"
	var vein_mesh := BoxMesh.new()
	vein_mesh.size = Vector3(0.10, 0.025, 0.04)
	vein.mesh = vein_mesh
	var vein_mat := StandardMaterial3D.new()
	vein_mat.albedo_color = Color(0.4, 0.6, 0.85)  # Magnetic blue
	vein_mat.metallic = 0.6
	vein_mat.roughness = 0.15
	vein_mat.emission_enabled = true
	vein_mat.emission = Color(0.3, 0.5, 0.75)
	vein_mat.emission_energy_multiplier = 1.5
	vein.material_override = vein_mat
	vein.position = Vector3(0, 0.01, 0)
	vein.rotation_degrees = Vector3(0, 15, 0)
	kit_model.add_child(vein)

	# Second smaller vein crossing at an angle
	var vein2 := MeshInstance3D.new()
	vein2.name = "MagneticVein2"
	var vein2_mesh := BoxMesh.new()
	vein2_mesh.size = Vector3(0.06, 0.02, 0.03)
	vein2.mesh = vein2_mesh
	var vein2_mat := StandardMaterial3D.new()
	vein2_mat.albedo_color = Color(0.45, 0.65, 0.9)  # Slightly brighter blue
	vein2_mat.metallic = 0.6
	vein2_mat.roughness = 0.15
	vein2_mat.emission_enabled = true
	vein2_mat.emission = Color(0.35, 0.55, 0.8)
	vein2_mat.emission_energy_multiplier = 1.2
	vein2.material_override = vein2_mat
	vein2.position = Vector3(0.01, -0.005, 0.01)
	vein2.rotation_degrees = Vector3(0, -40, 0)
	kit_model.add_child(vein2)

	kit_model.position = KIT_REST_POSITION
	kit_model.rotation_degrees = KIT_REST_ROTATION


func _remove_kit_model() -> void:
	if kit_model:
		kit_model.queue_free()
		kit_model = null


func _place_item() -> bool:
	if not player or not inventory:
		return false

	# Cooldown to prevent rapid-fire placement
	if placement_cooldown_timer > 0.0:
		return false

	# Torch: instant placement without preview mode
	if equipped_item == "torch":
		if placement_system and placement_system.has_method("place_torch_instant"):
			if placement_system.place_torch_instant():
				placement_cooldown_timer = PLACEMENT_COOLDOWN
				unequip()
				# Auto-equip next torch if player has more
				if inventory and inventory.has_item("torch"):
					equip("torch")
				return true
		return false

	# Lantern: instant placement without preview mode
	if equipped_item == "lantern":
		if placement_system and placement_system.has_method("place_lantern_instant"):
			if placement_system.place_lantern_instant():
				placement_cooldown_timer = PLACEMENT_COOLDOWN
				unequip()
				return true
		return false

	# Lodestone: instant placement without preview mode
	if equipped_item == "lodestone":
		if placement_system and placement_system.has_method("place_lodestone_instant"):
			if placement_system.place_lodestone_instant():
				placement_cooldown_timer = PLACEMENT_COOLDOWN
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
		var removed: bool = inventory.remove_item("campfire_kit", 1)
		if not removed:
			# Removal failed - clean up the placed campfire
			campfire.queue_free()
			return false
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

	# Reduce durability (clamp to 0 to prevent negative values in signal)
	tool_durability[equipped_item] = max(tool_durability[equipped_item] - amount, 0)
	var current: int = tool_durability[equipped_item]
	var max_dur: int = get_equipped_max_durability()

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
		var removed: bool = inventory.remove_item(broken_item, 1)
		if not removed:
			print("[Equipment] Warning: Could not remove broken %s from inventory" % broken_item)

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
## Respects leather wrap upgrades if applied.
func get_equipped_max_durability() -> int:
	if equipped_item == "" or not TOOL_MAX_DURABILITY.has(equipped_item):
		return -1
	# Check for upgrade
	if has_meta("durability_upgrades"):
		var upgrades: Dictionary = get_meta("durability_upgrades")
		if upgrades.has(equipped_item):
			return upgrades[equipped_item]
	return TOOL_MAX_DURABILITY[equipped_item]


## Get all tool durability data for saving (includes upgrade info).
func get_durability_data() -> Dictionary:
	var data: Dictionary = tool_durability.duplicate()
	# Include upgrade multipliers
	if has_meta("durability_upgrades"):
		data["_upgrades"] = get_meta("durability_upgrades").duplicate()
	return data


## Load tool durability data from save.
func load_durability_data(data: Dictionary) -> void:
	var data_copy: Dictionary = data.duplicate()
	# Extract and restore upgrades separately
	if data_copy.has("_upgrades"):
		set_meta("durability_upgrades", data_copy["_upgrades"].duplicate())
		data_copy.erase("_upgrades")
	tool_durability = data_copy


## Harvest birch bark from a birch tree using machete.
func _harvest_birch_bark(target: Node) -> bool:
	if not inventory:
		return false

	# Build position key from tree position (0.1-unit resolution)
	var pos: Vector3 = target.global_position
	var pos_key: String = "%d_%d" % [int(pos.x * 10), int(pos.z * 10)]

	# Check cooldown
	var time_mgr: Node = player.get_tree().get_first_node_in_group("time_manager") if player else null
	if not time_mgr:
		# Fallback: find via path
		time_mgr = player.get_node_or_null("/root/Main/TimeManager") if player else null

	var current_day: int = 1
	if time_mgr and "current_day" in time_mgr:
		current_day = time_mgr.current_day

	if bark_harvest_tracker.has(pos_key):
		var harvest_day: int = bark_harvest_tracker[pos_key]
		if current_day - harvest_day < BARK_REGROW_DAYS:
			# Show notification via HUD
			var hud: Node = player.get_tree().get_first_node_in_group("hud") if player else null
			if hud and hud.has_method("show_notification"):
				hud.show_notification("Bark hasn't regrown yet", Color(1.0, 0.85, 0.3, 1))
			print("[Equipment] Birch bark on cooldown (harvested day %d, now day %d)" % [harvest_day, current_day])
			_play_swing_animation()
			return false
		else:
			# Cooldown expired - remove old strip visual (bark regrew)
			_remove_bark_strip(target)
			bark_harvest_tracker.erase(pos_key)

	# Harvest bark
	_play_swing_animation()
	SFXManager.play_sfx("chop")
	inventory.add_item("birch_bark", 1)
	bark_harvest_tracker[pos_key] = current_day
	item_used.emit(equipped_item)
	use_durability(1)

	# Add stripped bark visual to the tree
	_add_bark_strip(target)

	# Show notification
	var hud: Node = player.get_tree().get_first_node_in_group("hud") if player else null
	if hud and hud.has_method("show_notification"):
		hud.show_notification("Harvested Birch Bark", Color(0.6, 1.0, 0.6, 1))
	print("[Equipment] Harvested birch bark from tree at %s" % pos)
	return true


## Shared material for bark strip visuals (avoids per-tree material allocation).
static var _bark_strip_material: StandardMaterial3D = null


## Add a brown stripped-bark band to a birch tree at eye level.
static func add_bark_strip(tree: Node) -> void:
	if not is_instance_valid(tree):
		return
	# Don't add a second strip
	if tree.has_node("BarkStrip"):
		return
	if not _bark_strip_material:
		_bark_strip_material = StandardMaterial3D.new()
		_bark_strip_material.albedo_color = Color(0.45, 0.30, 0.18)
	var strip: MeshInstance3D = MeshInstance3D.new()
	strip.name = "BarkStrip"
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(0.58, 0.6, 0.58)
	strip.mesh = box
	strip.position = Vector3(0, 2.0, 0)
	strip.material_override = _bark_strip_material
	tree.add_child(strip)


## Remove the stripped-bark band from a birch tree (bark regrew).
static func remove_bark_strip(tree: Node) -> void:
	if not is_instance_valid(tree):
		return
	var strip: Node = tree.get_node_or_null("BarkStrip")
	if strip:
		strip.queue_free()


func _add_bark_strip(target: Node) -> void:
	add_bark_strip(target)


func _remove_bark_strip(target: Node) -> void:
	remove_bark_strip(target)


## Toggle map overlay on/off.
func _use_map() -> bool:
	if not player:
		return false

	# Block reopening until use_equipped is fully released after last open/close
	if _map_open_blocked:
		return true

	# Block further calls until R2 is released, regardless of open or close
	_map_open_blocked = true

	# If map is already open, toggle it off
	var existing: Node = player.get_tree().get_first_node_in_group("map_ui")
	if existing and is_instance_valid(existing) and existing.has_method("close_map"):
		existing.close_map()
		return true

	# Open map overlay
	var map_ui: CanvasLayer = MapUI.new()
	player.get_tree().root.add_child(map_ui)
	return true


## Apply a leather upgrade to a matching tool in inventory.
## Finds the best matching tool, multiplies its max durability, and consumes the wrap.
func _use_upgrade(upgrade_item: String, upgrade_data: Dictionary) -> bool:
	if not inventory:
		return false

	var target_type: String = upgrade_data.get("upgrade_target", "")
	var multiplier: int = upgrade_data.get("durability_multiplier", 2)

	# Find the best matching tool in inventory
	var target_tool: String = ""
	if target_type == "axe":
		# Prefer better axes: metal > stone > primitive
		for axe_type: String in ["metal_axe", "stone_axe", "primitive_axe"]:
			if inventory.has_item(axe_type):
				target_tool = axe_type
				break
	elif target_type == "grappling_hook":
		if inventory.has_item("grappling_hook"):
			target_tool = "grappling_hook"

	if target_tool == "":
		# No matching tool found - notify player
		var hud: Node = player.get_tree().root.get_node_or_null("Main/HUD")
		if hud and hud.has_method("show_notification"):
			var tool_name: String = "an axe" if target_type == "axe" else "a grappling hook"
			hud.show_notification("Need %s in inventory to apply!" % tool_name, Color(1.0, 0.4, 0.4))
		return false

	# Apply the durability upgrade
	var base_max: int = TOOL_MAX_DURABILITY.get(target_tool, 100)
	var new_max: int = base_max * multiplier

	# Initialize durability if not yet tracked
	if not tool_durability.has(target_tool):
		tool_durability[target_tool] = base_max

	# Restore durability to full (new max) when wrap is applied
	var current: int = tool_durability[target_tool]
	tool_durability[target_tool] = new_max

	# Update the max durability reference (store in upgrade tracking)
	if not has_meta("durability_upgrades"):
		set_meta("durability_upgrades", {})
	var upgrades: Dictionary = get_meta("durability_upgrades")
	upgrades[target_tool] = new_max
	set_meta("durability_upgrades", upgrades)

	# Consume the upgrade item
	var removed: bool = inventory.remove_item(upgrade_item, 1)
	if not removed:
		# Revert the upgrade - restore original durability
		tool_durability[target_tool] = current
		upgrades.erase(target_tool)
		set_meta("durability_upgrades", upgrades)
		print("[Equipment] Warning: Could not consume %s - reverting upgrade" % upgrade_item)
		return false
	unequip()

	# Emit durability change signal
	durability_changed.emit(target_tool, tool_durability[target_tool], new_max)

	# Notify player
	var hud: Node = player.get_tree().root.get_node_or_null("Main/HUD")
	if hud and hud.has_method("show_notification"):
		var tool_display: String = target_tool.capitalize().replace("_", " ").replace("River Rock", "Rock")
		hud.show_notification("%s upgraded! Durability x%d" % [tool_display, multiplier], Color(0.6, 1.0, 0.6))

	print("[Equipment] Applied %s to %s: durability now %d/%d" % [upgrade_item, target_tool, tool_durability[target_tool], new_max])
	return true


## Close map overlay if it's open.
func _close_map_if_open() -> void:
	if not player:
		return
	var existing: Node = player.get_tree().get_first_node_in_group("map_ui")
	if existing and is_instance_valid(existing) and existing.has_method("close_map"):
		existing.close_map()


## Get bark harvest tracker data for saving.
func get_bark_harvest_data() -> Dictionary:
	return bark_harvest_tracker.duplicate()


## Load bark harvest tracker data from save.
func load_bark_harvest_data(data: Dictionary) -> void:
	bark_harvest_tracker = data.duplicate()
