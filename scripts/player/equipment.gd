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

# Stone axe visual
var stone_axe_model: Node3D = null

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

	# Show tool models
	var tool_type: String = item_data.get("tool_type", "")
	if tool_type == "fishing":
		_create_fishing_rod()
	elif tool_type == "axe":
		_create_stone_axe()

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
	_remove_fishing_rod()

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
	if not player:
		return

	var camera: Camera3D = player.get_node_or_null("Camera3D")
	if not camera:
		return

	# Animate the stone axe model if equipped
	if stone_axe_model:
		var original_rot: Vector3 = stone_axe_model.rotation_degrees
		var original_pos: Vector3 = stone_axe_model.position

		var tween: Tween = player.create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)

		# Wind up (raise axe back and to the right)
		tween.tween_property(stone_axe_model, "rotation_degrees",
			Vector3(original_rot.x + 30, original_rot.y + 20, original_rot.z + 25), 0.08)
		tween.parallel().tween_property(stone_axe_model, "position",
			Vector3(original_pos.x + 0.1, original_pos.y + 0.15, original_pos.z + 0.05), 0.08)

		# Swing down (chop motion - blade leads into target)
		tween.tween_property(stone_axe_model, "rotation_degrees",
			Vector3(original_rot.x - 40, original_rot.y - 15, original_rot.z - 35), 0.1)
		tween.parallel().tween_property(stone_axe_model, "position",
			Vector3(original_pos.x - 0.1, original_pos.y - 0.15, original_pos.z - 0.2), 0.1)

		# Return to rest position
		tween.tween_property(stone_axe_model, "rotation_degrees", original_rot, 0.15)
		tween.parallel().tween_property(stone_axe_model, "position", original_pos, 0.15)

		print("[Equipment] *chop*")
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


func _create_stone_axe() -> void:
	if stone_axe_model:
		return

	stone_axe_model = Node3D.new()
	stone_axe_model.name = "StoneAxeModel"

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

	# Stone head - blocky wedge shape (offset to -X so blade faces forward when swinging)
	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.18, 0.12, 0.06)  # Wide, short, thin
	head.mesh = head_mesh

	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.5, 0.5, 0.5)  # Stone grey
	head.material_override = head_mat
	head.position = Vector3(-0.06, 0.22, 0)  # At top of handle, offset to LEFT

	stone_axe_model.add_child(head)

	# Blade edge (slightly darker to show the cutting edge)
	var blade := MeshInstance3D.new()
	blade.name = "Blade"
	var blade_mesh := BoxMesh.new()
	blade_mesh.size = Vector3(0.02, 0.1, 0.05)
	blade.mesh = blade_mesh

	var blade_mat := StandardMaterial3D.new()
	blade_mat.albedo_color = Color(0.4, 0.4, 0.42)  # Darker stone
	blade.material_override = blade_mat
	blade.position = Vector3(-0.16, 0.22, 0)  # At edge of head (LEFT side)

	stone_axe_model.add_child(blade)

	# Binding (rope/vine wrapping where head meets handle)
	var binding := MeshInstance3D.new()
	binding.name = "Binding"
	var binding_mesh := BoxMesh.new()
	binding_mesh.size = Vector3(0.08, 0.06, 0.08)
	binding.mesh = binding_mesh

	var binding_mat := StandardMaterial3D.new()
	binding_mat.albedo_color = Color(0.55, 0.45, 0.3)  # Rope/leather tan
	binding.material_override = binding_mat
	binding.position = Vector3(0, 0.2, 0)  # Where head meets handle

	stone_axe_model.add_child(binding)

	# Position: held in right hand, ready to swing
	# Axe head should be up and to the right
	stone_axe_model.position = Vector3(0.35, -0.3, -0.4)
	stone_axe_model.rotation_degrees = Vector3(-20, -30, -45)  # Angled for holding

	# Attach to camera
	if player:
		var camera: Camera3D = player.get_node_or_null("Camera3D")
		if camera:
			camera.add_child(stone_axe_model)


func _remove_stone_axe() -> void:
	if stone_axe_model:
		stone_axe_model.queue_free()
		stone_axe_model = null


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
