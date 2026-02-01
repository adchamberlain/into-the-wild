extends StaticBody3D
class_name FishingSpot
## A fishing spot where players can catch fish with a fishing rod.
## Features organic pond shape and visible swimming fish.

signal fish_caught(fish_type: String, amount: int)
signal spot_depleted()
signal spot_respawned()

# Fishing properties
@export var fish_type: String = "fish"
@export var respawn_time_hours: float = 6.0
@export var fish_count: int = 3  # Number of visible fish

# Pond shape properties
@export var pond_width: float = 4.0
@export var pond_depth: float = 3.0
@export var pond_height: float = 0.15

# Fishing timing
@export var min_wait_time: float = 3.0
@export var max_wait_time: float = 8.0
@export var catch_window: float = 2.0

# State
var is_depleted: bool = false
var is_fishing: bool = false
var waiting_for_catch: bool = false
var current_player: Node = null
var catch_timer: float = 0.0
var catch_window_timer: float = 0.0

# Respawn tracking
var depleted_hour: int = 0
var depleted_minute: int = 0

# Visual elements
var water_mesh: MeshInstance3D
var fish_nodes: Array[Node3D] = []
var fish_targets: Array[Vector3] = []  # Swimming targets
var caught_fish_mesh: MeshInstance3D  # Fish being caught


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("fishing_spot")

	# Put on layer 2 only - raycast detects this, but player (layer 1 mask) won't collide
	collision_layer = 2
	collision_mask = 0

	# Create organic pond shape
	_create_pond_mesh()

	# Create swimming fish
	_create_swimming_fish()


func _process(delta: float) -> void:
	# Animate swimming fish
	_update_fish_swimming(delta)

	if not is_fishing:
		return

	if waiting_for_catch:
		catch_window_timer -= delta
		if catch_window_timer <= 0:
			_fail_catch()
	else:
		catch_timer -= delta
		if catch_timer <= 0:
			_fish_bite()


func _create_pond_mesh() -> void:
	# Remove existing elements
	for child_name in ["WaterMesh", "CollisionShape3D"]:
		var existing: Node = get_node_or_null(child_name)
		if existing:
			existing.queue_free()

	# Create water as a thin surface plane (not a box) to avoid side walls
	# clipping through terrain at pond edges
	water_mesh = MeshInstance3D.new()
	water_mesh.name = "WaterMesh"

	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(pond_width, pond_depth)
	water_mesh.mesh = plane_mesh

	# Position at water surface level
	water_mesh.position = Vector3(0, pond_height, 0)

	# Semi-transparent water material (render both sides)
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.2, 0.5, 0.65, 0.7)
	mat.roughness = 0.1
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	water_mesh.material_override = mat

	add_child(water_mesh)

	# Create water area for swimming detection
	_create_water_area()

	# Collision shape for raycast interaction - covers entire water surface
	# Player can fish from any edge of the pond
	var col_shape := CollisionShape3D.new()
	col_shape.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = Vector3(pond_width, 1.0, pond_depth)
	col_shape.shape = box
	col_shape.position = Vector3(0, pond_height, 0)
	add_child(col_shape)


func _create_water_area() -> void:
	# Water area for swimming detection - matches the water visual volume
	var water_depth: float = 3.0

	var water_area := Area3D.new()
	water_area.name = "WaterArea"

	var area_shape := CollisionShape3D.new()
	var area_box := BoxShape3D.new()
	# Match the water volume size, slightly larger to catch player entering
	area_box.size = Vector3(pond_width + 1.0, water_depth + 1.0, pond_depth + 1.0)
	area_shape.shape = area_box
	# Position to match water volume (surface at pond_height, extends down)
	area_shape.position = Vector3(0, pond_height - water_depth / 2.0, 0)
	water_area.add_child(area_shape)

	# Connect signals for swimming detection
	water_area.body_entered.connect(_on_water_body_entered)
	water_area.body_exited.connect(_on_water_body_exited)

	add_child(water_area)

	# No pond floor needed - terrain provides the floor!


func _on_water_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if body.has_method("set_in_water"):
			body.set_in_water(true)
		print("[FishingSpot] Player entered water")


func _on_water_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		if body.has_method("set_in_water"):
			body.set_in_water(false)
		print("[FishingSpot] Player exited water")


func _add_shore_rocks(points: Array[Vector2]) -> void:
	var rock_positions: Array[int] = [0, 3, 7, 10]  # Which edge points get rocks

	for idx in rock_positions:
		if idx >= points.size():
			continue

		var rock := MeshInstance3D.new()
		rock.name = "Rock%d" % idx

		var rock_size: float = randf_range(0.2, 0.4)
		var rock_mesh := BoxMesh.new()
		rock_mesh.size = Vector3(rock_size, rock_size * 0.7, rock_size)
		rock.mesh = rock_mesh

		var rock_mat := StandardMaterial3D.new()
		rock_mat.albedo_color = Color(0.4, 0.38, 0.35)
		rock.material_override = rock_mat

		# Position on shore edge
		var pos := Vector3(points[idx].x * 1.1, rock_size * 0.25, points[idx].y * 1.1)
		rock.position = pos
		rock.rotation.y = randf() * TAU  # Random Y rotation for variety

		add_child(rock)


func _create_swimming_fish() -> void:
	fish_nodes.clear()
	fish_targets.clear()

	for i in range(fish_count):
		var fish := _create_fish_mesh()
		fish.name = "Fish%d" % i

		# Random starting position in pond
		var start_pos := _get_random_pond_position()
		start_pos.y = pond_height - 0.08  # Just below water surface
		fish.position = start_pos
		fish.rotation.y = randf() * TAU

		add_child(fish)
		fish_nodes.append(fish)
		fish_targets.append(_get_random_pond_position())


func _create_fish_mesh() -> Node3D:
	var fish_root := Node3D.new()

	# Fish body (blocky box)
	var body := MeshInstance3D.new()
	body.name = "Body"
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.2, 0.08, 0.06)  # Long, flat, thin
	body.mesh = body_mesh

	var fish_mat := StandardMaterial3D.new()
	fish_mat.albedo_color = Color(0.6, 0.55, 0.4)  # Brownish fish color
	body.material_override = fish_mat

	fish_root.add_child(body)

	# Tail fin (small box)
	var tail := MeshInstance3D.new()
	tail.name = "Tail"
	var tail_mesh := BoxMesh.new()
	tail_mesh.size = Vector3(0.04, 0.1, 0.02)
	tail.mesh = tail_mesh
	tail.position = Vector3(-0.12, 0, 0)
	tail.material_override = fish_mat

	fish_root.add_child(tail)

	return fish_root


func _get_random_pond_position() -> Vector3:
	# Get random position within the pond bounds
	var angle: float = randf() * TAU
	var dist: float = randf() * 0.7  # Stay away from edges
	var x: float = cos(angle) * (pond_width / 2.0 - 0.3) * dist
	var z: float = sin(angle) * (pond_depth / 2.0 - 0.3) * dist
	return Vector3(x, pond_height - 0.08, z)


func _update_fish_swimming(delta: float) -> void:
	if is_depleted:
		return

	for i in range(fish_nodes.size()):
		var fish: Node3D = fish_nodes[i]
		var target: Vector3 = fish_targets[i]

		# Move towards target
		var direction: Vector3 = (target - fish.position)
		direction.y = 0  # Keep fish at same depth
		var distance: float = direction.length()

		if distance < 0.2:
			# Reached target, pick new one
			fish_targets[i] = _get_random_pond_position()
		else:
			# Swim towards target
			direction = direction.normalized()
			fish.position += direction * delta * 0.3  # Slow swimming

			# Face movement direction
			fish.rotation.y = atan2(direction.x, direction.z)

		# Subtle bobbing
		var bob: float = sin(Time.get_ticks_msec() * 0.003 + i * 2.0) * 0.005
		fish.position.y = pond_height - 0.08 + bob


func interact(player: Node) -> bool:
	if is_depleted:
		return false

	var equipment: Node = _get_player_equipment(player)
	if not equipment or not equipment.has_tool_equipped("fishing"):
		print("[FishingSpot] Need a fishing rod equipped!")
		return false

	if not is_fishing:
		_start_fishing(player)
		return true
	elif waiting_for_catch:
		_attempt_catch()
		return true

	return false


func get_interaction_text() -> String:
	if is_depleted:
		return "Depleted"
	if waiting_for_catch:
		return "Reel In!"
	if is_fishing:
		return "Waiting for bite..."

	# Only show "Cast Line" if player has fishing rod equipped
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var equipment: Node = _get_player_equipment(players[0])
		if equipment and equipment.has_tool_equipped("fishing"):
			return "Cast Line"

	return ""


func _start_fishing(player: Node) -> void:
	is_fishing = true
	waiting_for_catch = false
	current_player = player
	catch_timer = randf_range(min_wait_time, max_wait_time)

	# Tell player's equipment to show casting animation
	var equipment: Node = _get_player_equipment(player)
	if equipment and equipment.has_method("show_fishing_cast"):
		equipment.show_fishing_cast()

	print("[FishingSpot] Line cast... waiting for a bite")


func _fish_bite() -> void:
	waiting_for_catch = true
	catch_window_timer = catch_window

	# Make one fish swim excitedly near the line
	if fish_nodes.size() > 0:
		var biting_fish: Node3D = fish_nodes[0]
		var line_pos := Vector3(0, pond_height - 0.1, -0.5)  # Near where line would be
		fish_targets[0] = line_pos

	print("[FishingSpot] A fish is biting! Press E quickly!")
	_show_notification("Fish on the line! Press E!", Color(0.4, 0.8, 1.0))


func _attempt_catch() -> void:
	if not waiting_for_catch:
		return

	is_fishing = false
	waiting_for_catch = false

	if current_player:
		var inventory: Node = _get_player_inventory(current_player)
		if inventory:
			inventory.add_item(fish_type, 1)
			print("[FishingSpot] Caught a %s!" % fish_type)
			_show_notification("Caught a fish!", Color(0.4, 1.0, 0.4))

		# Show catch animation on equipment
		var equipment: Node = _get_player_equipment(current_player)
		if equipment:
			if equipment.has_method("show_fish_caught"):
				equipment.show_fish_caught()
			if equipment.has_method("use_durability"):
				equipment.use_durability(1)

	_deplete()
	fish_caught.emit(fish_type, 1)


func _fail_catch() -> void:
	is_fishing = false
	waiting_for_catch = false

	# Hide the fishing line so player must cast again
	if current_player:
		var equipment: Node = _get_player_equipment(current_player)
		if equipment and equipment.has_method("hide_fishing_line"):
			equipment.hide_fishing_line()

	print("[FishingSpot] The fish got away...")
	_show_notification("The fish got away!", Color(1.0, 0.6, 0.4))


func _deplete() -> void:
	is_depleted = true
	spot_depleted.emit()

	var time_manager: Node = _find_time_manager()
	if time_manager:
		depleted_hour = time_manager.current_hour
		depleted_minute = time_manager.current_minute

	# Darken the water
	if water_mesh and water_mesh.material_override:
		var mat: StandardMaterial3D = water_mesh.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(0.2, 0.25, 0.3, 0.7)

	# Hide fish
	for fish in fish_nodes:
		fish.visible = false

	print("[FishingSpot] Fishing spot depleted, will respawn later")


func respawn() -> void:
	is_depleted = false
	is_fishing = false
	waiting_for_catch = false
	current_player = null

	# Restore water color
	if water_mesh and water_mesh.material_override:
		var mat: StandardMaterial3D = water_mesh.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(0.15, 0.35, 0.45, 0.75)

	# Show fish again
	for fish in fish_nodes:
		fish.visible = true
		fish.position = _get_random_pond_position()

	spot_respawned.emit()
	print("[FishingSpot] Fishing spot respawned")


func _get_player_inventory(player: Node) -> Node:
	if player.has_method("get_inventory"):
		return player.get_inventory()
	if player.has_node("Inventory"):
		return player.get_node("Inventory")
	return null


func _get_player_equipment(player: Node) -> Node:
	if player.has_method("get_equipment"):
		return player.get_equipment()
	if player.has_node("Equipment"):
		return player.get_node("Equipment")
	return null


func _find_time_manager() -> Node:
	var root: Node = get_tree().root
	if root.has_node("Main/TimeManager"):
		return root.get_node("Main/TimeManager")
	return null


func _show_notification(message: String, color: Color) -> void:
	var hud: Node = _find_hud()
	if hud and hud.has_method("show_notification"):
		hud.show_notification(message, color)


func _find_hud() -> Node:
	var root: Node = get_tree().root
	if root.has_node("Main/HUD"):
		return root.get_node("Main/HUD")
	return null
