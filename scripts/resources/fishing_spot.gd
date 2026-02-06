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

	# Semi-transparent water material with richer color
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.15, 0.42, 0.55, 0.72)
	mat.roughness = 0.05
	mat.metallic = 0.1
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	water_mesh.material_override = mat

	add_child(water_mesh)

	# Deeper water center (darker patch beneath surface)
	var deep_mesh := MeshInstance3D.new()
	deep_mesh.name = "DeepWater"
	var deep_plane := PlaneMesh.new()
	deep_plane.size = Vector2(pond_width * 0.6, pond_depth * 0.6)
	deep_mesh.mesh = deep_plane
	deep_mesh.position = Vector3(0, pond_height - 0.01, 0)
	var deep_mat := StandardMaterial3D.new()
	deep_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	deep_mat.albedo_color = Color(0.08, 0.28, 0.38, 0.5)
	deep_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	deep_mesh.material_override = deep_mat
	add_child(deep_mesh)

	# Shore rocks (8 rocks around edges with varied sizes and colors)
	var rock_colors: Array[Color] = [
		Color(0.42, 0.40, 0.36), Color(0.38, 0.36, 0.33),
		Color(0.45, 0.42, 0.38), Color(0.35, 0.33, 0.30),
		Color(0.40, 0.38, 0.35), Color(0.44, 0.41, 0.37),
		Color(0.36, 0.34, 0.31), Color(0.41, 0.39, 0.36)
	]
	for i: int in range(8):
		var rock := MeshInstance3D.new()
		rock.name = "Rock%d" % i
		var rock_size: float = randf_range(0.2, 0.45)
		var rock_mesh := BoxMesh.new()
		rock_mesh.size = Vector3(rock_size, rock_size * 0.6, rock_size * 0.8)
		rock.mesh = rock_mesh
		var rock_mat := StandardMaterial3D.new()
		rock_mat.albedo_color = rock_colors[i]
		rock_mat.roughness = 0.92
		rock.material_override = rock_mat
		var angle: float = i * TAU / 8.0 + randf_range(-0.3, 0.3)
		var dist: float = max(pond_width, pond_depth) / 2.0 * 0.9
		rock.position = Vector3(cos(angle) * dist, rock_size * 0.2, sin(angle) * dist)
		rock.rotation.y = randf() * TAU
		rock.rotation.x = randf_range(-0.15, 0.15)
		add_child(rock)

		# Rock highlight (lighter top face)
		if i % 2 == 0:
			var r_top := MeshInstance3D.new()
			var rt_mesh := BoxMesh.new()
			rt_mesh.size = Vector3(rock_size * 0.7, 0.03, rock_size * 0.6)
			r_top.mesh = rt_mesh
			r_top.position = rock.position + Vector3(0, rock_size * 0.35, 0)
			var rt_mat := StandardMaterial3D.new()
			rt_mat.albedo_color = Color(0.52, 0.50, 0.46, 0.5)
			rt_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			r_top.material_override = rt_mat
			add_child(r_top)

	# Lily pads (flat green discs on water surface)
	var lily_mat := StandardMaterial3D.new()
	lily_mat.albedo_color = Color(0.22, 0.45, 0.20)
	lily_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var lily_dark_mat := StandardMaterial3D.new()
	lily_dark_mat.albedo_color = Color(0.16, 0.35, 0.14)
	lily_dark_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	for i: int in range(4):
		var lily := MeshInstance3D.new()
		var l_mesh := BoxMesh.new()
		var lsize: float = randf_range(0.15, 0.3)
		l_mesh.size = Vector3(lsize, 0.01, lsize)
		lily.mesh = l_mesh
		var l_angle: float = randf() * TAU
		var l_dist: float = randf_range(0.3, 0.7) * min(pond_width, pond_depth) / 2.0
		lily.position = Vector3(cos(l_angle) * l_dist, pond_height + 0.01, sin(l_angle) * l_dist)
		lily.rotation.y = randf() * TAU
		lily.material_override = lily_mat if i % 2 == 0 else lily_dark_mat
		add_child(lily)

		# Some lily pads get a tiny flower
		if i == 1:
			var flower := MeshInstance3D.new()
			var fl_mesh := BoxMesh.new()
			fl_mesh.size = Vector3(0.05, 0.04, 0.05)
			flower.mesh = fl_mesh
			flower.position = lily.position + Vector3(0.02, 0.03, 0.02)
			var fl_mat := StandardMaterial3D.new()
			fl_mat.albedo_color = Color(0.95, 0.85, 0.90)  # Pale pink
			flower.material_override = fl_mat
			add_child(flower)

	# Reeds/cattails at edges (tall thin vertical boxes)
	var reed_mat := StandardMaterial3D.new()
	reed_mat.albedo_color = Color(0.35, 0.48, 0.25)

	var cattail_mat := StandardMaterial3D.new()
	cattail_mat.albedo_color = Color(0.40, 0.28, 0.18)

	for i: int in range(6):
		var reed := MeshInstance3D.new()
		var r_mesh := BoxMesh.new()
		var r_height: float = randf_range(0.4, 0.8)
		r_mesh.size = Vector3(0.02, r_height, 0.02)
		reed.mesh = r_mesh
		var r_angle: float = TAU * 0.6 + i * 0.15 + randf_range(-0.1, 0.1)
		var r_dist: float = max(pond_width, pond_depth) / 2.0 * 0.8
		reed.position = Vector3(cos(r_angle) * r_dist, r_height / 2.0, sin(r_angle) * r_dist)
		reed.rotation.z = randf_range(-0.1, 0.1)
		reed.material_override = reed_mat
		add_child(reed)

		# Cattail top on some reeds
		if i % 2 == 0:
			var cattail := MeshInstance3D.new()
			var ct_mesh := BoxMesh.new()
			ct_mesh.size = Vector3(0.04, 0.08, 0.04)
			cattail.mesh = ct_mesh
			cattail.position = reed.position + Vector3(0, r_height / 2.0 + 0.02, 0)
			cattail.material_override = cattail_mat
			add_child(cattail)

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

	# Materials
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.45, 0.52, 0.42)  # Olive-green back

	var belly_mat := StandardMaterial3D.new()
	belly_mat.albedo_color = Color(0.72, 0.70, 0.58)  # Pale belly

	var side_mat := StandardMaterial3D.new()
	side_mat.albedo_color = Color(0.55, 0.58, 0.48)  # Silvery-green sides

	var fin_mat := StandardMaterial3D.new()
	fin_mat.albedo_color = Color(0.50, 0.55, 0.42, 0.8)
	fin_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.08, 0.08, 0.06)

	var spot_mat := StandardMaterial3D.new()
	spot_mat.albedo_color = Color(0.60, 0.48, 0.35)  # Brown spots

	# Fish body (main shape)
	var body := MeshInstance3D.new()
	body.name = "Body"
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.22, 0.08, 0.06)
	body.mesh = body_mesh
	body.material_override = body_mat
	fish_root.add_child(body)

	# Belly (lighter underside)
	var belly := MeshInstance3D.new()
	var be_mesh := BoxMesh.new()
	be_mesh.size = Vector3(0.18, 0.025, 0.055)
	belly.mesh = be_mesh
	belly.position = Vector3(0, -0.03, 0)
	belly.material_override = belly_mat
	fish_root.add_child(belly)

	# Silvery side stripe
	var stripe := MeshInstance3D.new()
	var st_mesh := BoxMesh.new()
	st_mesh.size = Vector3(0.16, 0.02, 0.062)
	stripe.mesh = st_mesh
	stripe.position = Vector3(0, 0, 0)
	stripe.material_override = side_mat
	fish_root.add_child(stripe)

	# Head (slightly wider front)
	var head := MeshInstance3D.new()
	var hd_mesh := BoxMesh.new()
	hd_mesh.size = Vector3(0.06, 0.07, 0.055)
	head.mesh = hd_mesh
	head.position = Vector3(0.12, 0.005, 0)
	head.material_override = body_mat
	fish_root.add_child(head)

	# Eyes
	for side: float in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var eye_mesh := BoxMesh.new()
		eye_mesh.size = Vector3(0.015, 0.015, 0.01)
		eye.mesh = eye_mesh
		eye.position = Vector3(0.13, 0.015, side * 0.03)
		eye.material_override = eye_mat
		fish_root.add_child(eye)

	# Dorsal fin (top)
	var dorsal := MeshInstance3D.new()
	var df_mesh := BoxMesh.new()
	df_mesh.size = Vector3(0.08, 0.04, 0.01)
	dorsal.mesh = df_mesh
	dorsal.position = Vector3(-0.02, 0.06, 0)
	dorsal.material_override = fin_mat
	fish_root.add_child(dorsal)

	# Tail fin (forked V-shape from two boxes)
	var tail_top := MeshInstance3D.new()
	tail_top.name = "Tail"
	var tt_mesh := BoxMesh.new()
	tt_mesh.size = Vector3(0.04, 0.05, 0.015)
	tail_top.mesh = tt_mesh
	tail_top.position = Vector3(-0.13, 0.02, 0)
	tail_top.rotation.z = 0.3
	tail_top.material_override = fin_mat
	fish_root.add_child(tail_top)

	var tail_bot := MeshInstance3D.new()
	var tb_mesh := BoxMesh.new()
	tb_mesh.size = Vector3(0.04, 0.05, 0.015)
	tail_bot.mesh = tb_mesh
	tail_bot.position = Vector3(-0.13, -0.02, 0)
	tail_bot.rotation.z = -0.3
	tail_bot.material_override = fin_mat
	fish_root.add_child(tail_bot)

	# Pectoral fins (small side fins)
	for side: float in [-1.0, 1.0]:
		var pec := MeshInstance3D.new()
		var pec_mesh := BoxMesh.new()
		pec_mesh.size = Vector3(0.03, 0.01, 0.03)
		pec.mesh = pec_mesh
		pec.position = Vector3(0.06, -0.03, side * 0.035)
		pec.rotation.x = side * 0.4
		pec.material_override = fin_mat
		fish_root.add_child(pec)

	# Spots/markings on body
	for i: int in range(3):
		var spot := MeshInstance3D.new()
		var sp_mesh := BoxMesh.new()
		sp_mesh.size = Vector3(0.02, 0.02, 0.062)
		spot.mesh = sp_mesh
		spot.position = Vector3(-0.05 + i * 0.06, 0.01, 0)
		spot.material_override = spot_mat
		fish_root.add_child(spot)

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
		var _biting_fish: Node3D = fish_nodes[0]
		var line_pos := Vector3(0, pond_height - 0.1, -0.5)  # Near where line would be
		fish_targets[0] = line_pos

	var button_prompt: String = "E"
	if InputManager:
		button_prompt = InputManager.get_prompt("interact")
	print("[FishingSpot] A fish is biting! Press %s quickly!" % button_prompt)
	_show_notification("Fish on the line! Press %s!" % button_prompt, Color(0.4, 0.8, 1.0))


func _attempt_catch() -> void:
	if not waiting_for_catch:
		return

	is_fishing = false
	waiting_for_catch = false

	if current_player:
		var inventory: Node = _get_player_inventory(current_player)
		print("[FishingSpot] current_player: %s, inventory: %s" % [current_player, inventory])
		if inventory:
			var old_count: int = inventory.get_item_count(fish_type)
			inventory.add_item(fish_type, 1)
			var new_count: int = inventory.get_item_count(fish_type)
			print("[FishingSpot] Caught a %s! Inventory %s count: %d -> %d" % [fish_type, fish_type, old_count, new_count])
			_show_notification("Caught a fish!", Color(0.4, 1.0, 0.4))
		else:
			print("[FishingSpot] ERROR: Could not get player inventory!")

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
