extends StaticBody3D
class_name CaveEntrance
## Underground cave entrance - a natural sinkhole/crater the player descends into.
## 5 steps lead from the surface (y=0) down to the tunnel floor (y=-5.5).
## All geometry tops are at y<=-0.3 to stay below terrain and avoid z-fighting.
## Darkness is handled by CaveTransition when player enters the Area3D.

signal resource_depleted(cave_id: int, node_name: String)

# Cave properties
@export var cave_id: int = 0
@export var cave_type: String = "small"

# Visual nodes
var arch_meshes: Array[MeshInstance3D] = []
var darkness_mesh: MeshInstance3D = null

# Interior nodes
var cave_area: Area3D = null
var resource_nodes: Array[Node] = []

# Shared materials (static to avoid shader compilation per instance)
static var _dark_mat: StandardMaterial3D = null
static var _floor_mat: StandardMaterial3D = null
static var _wall_mat: StandardMaterial3D = null
static var _ceiling_mat: StandardMaterial3D = null
static var _moss_mat: StandardMaterial3D = null
static var _earth_mat: StandardMaterial3D = null
static var _step_mat: StandardMaterial3D = null
# Rock material palette: 6 shared tints from lightest to darkest
static var _rock_palette: Array = []  # Array[StandardMaterial3D]


static func _get_dark_material() -> StandardMaterial3D:
	if not _dark_mat:
		_dark_mat = StandardMaterial3D.new()
		_dark_mat.albedo_color = Color(0.02, 0.02, 0.02)
		_dark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return _dark_mat


static func _get_floor_material() -> StandardMaterial3D:
	if not _floor_mat:
		_floor_mat = StandardMaterial3D.new()
		_floor_mat.albedo_color = Color(0.18, 0.16, 0.14)
		_floor_mat.roughness = 0.95
	return _floor_mat


static func _get_wall_material() -> StandardMaterial3D:
	if not _wall_mat:
		_wall_mat = StandardMaterial3D.new()
		_wall_mat.albedo_color = Color(0.22, 0.20, 0.17)
		_wall_mat.roughness = 0.95
	return _wall_mat


static func _get_ceiling_material() -> StandardMaterial3D:
	if not _ceiling_mat:
		_ceiling_mat = StandardMaterial3D.new()
		_ceiling_mat.albedo_color = Color(0.15, 0.14, 0.12)
		_ceiling_mat.roughness = 0.95
	return _ceiling_mat


static func _get_moss_material() -> StandardMaterial3D:
	if not _moss_mat:
		_moss_mat = StandardMaterial3D.new()
		_moss_mat.albedo_color = Color(0.25, 0.35, 0.20, 0.65)
		_moss_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_moss_mat.roughness = 0.95
	return _moss_mat


static func _get_earth_material() -> StandardMaterial3D:
	if not _earth_mat:
		_earth_mat = StandardMaterial3D.new()
		_earth_mat.albedo_color = Color(0.28, 0.22, 0.16)
		_earth_mat.roughness = 0.95
	return _earth_mat


static func _get_step_material() -> StandardMaterial3D:
	if not _step_mat:
		_step_mat = StandardMaterial3D.new()
		_step_mat.albedo_color = Color(0.32, 0.28, 0.22)
		_step_mat.roughness = 0.95
	return _step_mat



static func _get_rock_palette() -> Array:
	if _rock_palette.size() == 0:
		var colors: Array[Color] = [
			Color(0.46, 0.44, 0.40),  # 0: lightest entrance rock
			Color(0.42, 0.40, 0.36),  # 1: medium entrance rock
			Color(0.38, 0.36, 0.32),  # 2: dark entrance rock / stalactites
			Color(0.30, 0.28, 0.25),  # 3: transition rock
			Color(0.22, 0.20, 0.17),  # 4: interior outcrops / rubble
			Color(0.17, 0.15, 0.13),  # 5: darkest interior stalactites
		]
		for c: Color in colors:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = c
			mat.roughness = 0.95
			_rock_palette.append(mat)
	return _rock_palette


func _ready() -> void:
	add_to_group("cave_entrance")
	call_deferred("_setup_visuals")


func _add_rock(pos: Vector3, size: Vector3, rot: Vector3, tint: float, rng: RandomNumberGenerator) -> MeshInstance3D:
	## Helper: create a rock block with position, size, rotation, and color tint.
	## Uses shared palette materials instead of per-rock material creation.
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	# Consume 3 RNG values to preserve deterministic sequence
	rng.randf_range(-0.02, 0.02)
	rng.randf_range(-0.02, 0.02)
	rng.randf_range(-0.02, 0.02)
	# Map tint to shared palette index (0=lightest, 2=darkest entrance rock)
	var palette: Array = _get_rock_palette()
	var idx: int
	if tint >= 0.03:
		idx = 0  # lightest
	elif tint >= 0.0:
		idx = 1  # medium
	elif tint >= -0.03:
		idx = 2  # medium-dark
	else:
		idx = 3  # darker
	mesh_inst.material_override = palette[idx]
	mesh_inst.position = pos
	mesh_inst.rotation_degrees = rot
	add_child(mesh_inst)
	arch_meshes.append(mesh_inst)
	return mesh_inst


func _add_interior_rock(pos: Vector3, size: Vector3, rot: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	## Helper: create an interior rock block with a shared material
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.material_override = mat
	mesh_inst.position = pos
	mesh_inst.rotation_degrees = rot
	add_child(mesh_inst)
	return mesh_inst


func _setup_visuals() -> void:
	var dark_mat: StandardMaterial3D = _get_dark_material()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = cave_id * 12345

	# Entrance faces +Z. Player approaches from +Z, walks into -Z.
	# Crater rim at y=0, stairway descends to y=-3.0, tunnel at y=-3 to y=0.

	# ===== CRATER RIM AND SINKHOLE =====
	_build_crater_rim(dark_mat, rng)

	# ===== STAIRWAY DESCENT =====
	_build_stairway(rng)

	# ===== TUNNEL STRUCTURE =====
	_build_tunnel(rng)

	# ===== INTERIOR DETAILS =====
	_build_interior_details(rng)

	# ===== CAVE AREA3D (player detection) =====
	_build_cave_area()

	# ===== COLLISION =====
	_build_collision()

	# ===== RESOURCES =====
	_spawn_resources()

	# ===== APPLY SAVED RESOURCE STATE =====
	_apply_saved_resource_state()


func _build_crater_rim(dark_mat: StandardMaterial3D, _rng: RandomNumberGenerator) -> void:
	# ===== DARK PIT BOTTOM (visible from above as depth cue) =====
	darkness_mesh = MeshInstance3D.new()
	darkness_mesh.name = "DarkOpening"
	var dark_box := BoxMesh.new()
	dark_box.size = Vector3(5.0, 0.1, 6.0)
	darkness_mesh.mesh = dark_box
	darkness_mesh.material_override = dark_mat
	darkness_mesh.position = Vector3(0, -4.9, -0.5)
	add_child(darkness_mesh)

	# Depth layers descending into pit (give visual depth from above)
	for depth_i: int in range(3):
		var depth_dark := MeshInstance3D.new()
		var dd_mesh := BoxMesh.new()
		var shrink: float = float(depth_i) * 0.3
		dd_mesh.size = Vector3(4.5 - shrink, 0.1, 5.5 - shrink)
		depth_dark.mesh = dd_mesh
		depth_dark.material_override = dark_mat
		depth_dark.position = Vector3(0, -4.5 + float(depth_i) * 0.4, -0.5)
		add_child(depth_dark)
		arch_meshes.append(depth_dark)

	# ===== INNER CRATER WALLS (earth/rock sides, tops at y=-0.3 to stay below terrain) =====
	# No rim boulders or surface decorations — terrain generates naturally on top.
	var earth_mat: StandardMaterial3D = _get_earth_material()
	# Left crater wall (top at y=-0.3, bottom at y=-5.3)
	_add_interior_rock(
		Vector3(-2.8, -2.8, 0.0), Vector3(1.0, 5.0, 8.0), Vector3(0, 0, 0), earth_mat)
	# Right crater wall
	_add_interior_rock(
		Vector3(2.8, -2.8, 0.0), Vector3(1.0, 5.0, 8.0), Vector3(0, 0, 0), earth_mat)
	# Front crater wall (at +Z edge of skip zone)
	_add_interior_rock(
		Vector3(0, -2.8, 3.8), Vector3(6.6, 5.0, 1.0), Vector3(0, 0, 0), earth_mat)


func _build_stairway(rng: RandomNumberGenerator) -> void:
	## Build 5 steps descending from y=-0.5 to y=-5.0 (1.0 drop per step).
	## Each step is a filled box from its tread height down to y=-5.5 (the tunnel floor).
	var step_mat: StandardMaterial3D = _get_step_material()
	var earth_mat: StandardMaterial3D = _get_earth_material()

	# Each step: 1.0 unit drop, 1.5 units deep in Z
	var steps: Array[Dictionary] = [
		{"top": -1.0, "z": 2.25},   # Step 1: y=-1.0
		{"top": -2.0, "z": 0.75},   # Step 2: y=-2.0
		{"top": -3.0, "z": -0.75},  # Step 3: y=-3.0
		{"top": -4.0, "z": -2.25},  # Step 4: y=-4.0
		{"top": -5.0, "z": -3.75},  # Step 5: y=-5.0
	]

	for step: Dictionary in steps:
		var top_y: float = step["top"]
		var z_center: float = step["z"]
		# Box extends from top_y down to -5.5 (tunnel floor)
		var height: float = top_y - (-5.5)  # positive value
		var y_center: float = top_y - height * 0.5
		_add_interior_rock(
			Vector3(0, y_center, z_center),
			Vector3(4.6, height, 1.5),
			Vector3(0, 0, 0),
			step_mat
		)

	# Side earth walls along stairway (tops at y=-0.3, below terrain)
	# Z-size 9.5 (center -1.75) covers Z:[-6.5,+3.0] to close visual gap with tunnel walls at Z:-6.
	_add_interior_rock(
		Vector3(-2.8, -2.8, -1.75), Vector3(1.0, 5.0, 9.5), Vector3(0, 0, 0), earth_mat)
	_add_interior_rock(
		Vector3(2.8, -2.8, -1.75), Vector3(1.0, 5.0, 9.5), Vector3(0, 0, 0), earth_mat)

	# Earth/rock overhang where tunnel begins (below terrain surface)
	var ceiling_mat: StandardMaterial3D = _get_ceiling_material()
	_add_interior_rock(
		Vector3(0, -0.5, -4.0), Vector3(6.6, 0.6, 2.0), Vector3(0, 0, 0), ceiling_mat)


func _build_tunnel(rng: RandomNumberGenerator) -> void:
	## Build the underground tunnel from z=-6 to z=-24.
	## Floor at y=-5.75, ceiling at y=-1.0, walls from floor to ceiling.
	## All tops well below y=0 (terrain surface) to prevent z-fighting.
	var wall_mat: StandardMaterial3D = _get_wall_material()
	var floor_mat: StandardMaterial3D = _get_floor_material()
	var ceiling_mat: StandardMaterial3D = _get_ceiling_material()

	# Tunnel: 5 wide (x=-2.5 to +2.5), ~5 tall (y=-5.5 to y=-0.5), 18 deep (z=-6 to -24)

	# -- LEFT WALL: segmented for visual interest --
	for seg: int in range(6):
		var z_start: float = -6.0 - float(seg) * 3.0
		var width_var: float = rng.randf_range(-0.15, 0.15)
		_add_interior_rock(
			Vector3(-2.8 - width_var, -3.0, z_start - 1.5),
			Vector3(1.0 + width_var * 2.0, 5.0, 3.0),
			Vector3(0, 0, 0),
			wall_mat
		)

	# -- RIGHT WALL: segmented --
	for seg: int in range(6):
		var z_start: float = -6.0 - float(seg) * 3.0
		var width_var: float = rng.randf_range(-0.15, 0.15)
		_add_interior_rock(
			Vector3(2.8 + width_var, -3.0, z_start - 1.5),
			Vector3(1.0 + width_var * 2.0, 5.0, 3.0),
			Vector3(0, 0, 0),
			wall_mat
		)

	# -- CEILING: well below terrain (y=-0.8, tops at ~y=-0.2) --
	for seg: int in range(6):
		var z_start: float = -6.0 - float(seg) * 3.0
		var height_var: float = rng.randf_range(-0.15, 0.15)
		_add_interior_rock(
			Vector3(0, -0.8 + height_var, z_start - 1.5),
			Vector3(6.6, 0.8, 3.0),
			Vector3(0, 0, 0),
			ceiling_mat
		)

	# -- FLOOR: continuous slab --
	_add_interior_rock(
		Vector3(0, -5.75, -15.0),
		Vector3(5.0, 0.5, 18.0),
		Vector3(0, 0, 0),
		floor_mat
	)

	# -- BACK WALL: seals the end of the tunnel --
	_add_interior_rock(
		Vector3(0, -3.0, -24.5),
		Vector3(6.6, 5.0, 1.0),
		Vector3(0, 0, 0),
		wall_mat
	)


func _build_interior_details(rng: RandomNumberGenerator) -> void:
	## Add stalactites, wall outcrops, and rubble inside the deeper tunnel.
	## Tunnel floor at y=-5.5, ceiling at y=-0.8.
	var palette: Array = _get_rock_palette()
	var interior_stalac_mat: StandardMaterial3D = palette[5]  # darkest
	var outcrop_mat: StandardMaterial3D = palette[4]  # interior outcrops
	var rubble_mat: StandardMaterial3D = palette[4]  # interior rubble

	# -- Stalactites hanging from ceiling (y=-0.8) --
	for i: int in range(8):
		var s_h: float = rng.randf_range(0.3, 1.0)
		rng.randf_range(-0.02, 0.02)
		rng.randf_range(-0.02, 0.02)
		rng.randf_range(-0.02, 0.02)
		_add_interior_rock(
			Vector3(rng.randf_range(-2.0, 2.0), -0.8 - s_h * 0.5, rng.randf_range(-22.0, -8.0)),
			Vector3(rng.randf_range(0.12, 0.25), s_h, rng.randf_range(0.12, 0.25)),
			Vector3(rng.randf_range(-5, 5), 0, rng.randf_range(-5, 5)),
			interior_stalac_mat
		)

	# -- Wall outcrops (bulges from walls) --
	for i: int in range(4):
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var outcrop_z: float = rng.randf_range(-21.0, -8.0)
		var outcrop_y: float = rng.randf_range(-4.5, -1.5)
		rng.randf_range(-0.03, 0.03)
		_add_interior_rock(
			Vector3(side * (2.2 + rng.randf_range(0.0, 0.3)), outcrop_y, outcrop_z),
			Vector3(rng.randf_range(0.8, 1.5), rng.randf_range(0.8, 1.5), rng.randf_range(0.8, 1.5)),
			Vector3(rng.randf_range(-5, 5), rng.randf_range(-5, 5), rng.randf_range(-3, 3)),
			outcrop_mat
		)

	# -- Floor rubble (small rocks on floor at y=-5.5) --
	for i: int in range(6):
		var bsize: float = rng.randf_range(0.25, 0.7)
		rng.randf_range(-0.03, 0.03)
		rng.randf_range(-0.02, 0.02)
		rng.randf_range(-0.02, 0.02)
		_add_interior_rock(
			Vector3(rng.randf_range(-1.8, 1.8), -5.5 + bsize * 0.25, rng.randf_range(-22.0, -8.0)),
			Vector3(bsize, bsize * 0.5, bsize * 0.65),
			Vector3(rng.randf_range(-8, 8), rng.randf_range(0, 45), rng.randf_range(-5, 5)),
			rubble_mat
		)

	# -- Stalagmites rising from floor (y=-5.5) --
	for i: int in range(3):
		var s_h: float = rng.randf_range(0.4, 1.0)
		_add_interior_rock(
			Vector3(rng.randf_range(-1.8, 1.8), -5.5 + s_h * 0.5, rng.randf_range(-21.0, -9.0)),
			Vector3(rng.randf_range(0.2, 0.4), s_h, rng.randf_range(0.2, 0.4)),
			Vector3(rng.randf_range(-3, 3), 0, rng.randf_range(-3, 3)),
			rubble_mat
		)



func _build_cave_area() -> void:
	## Create an Area3D covering the underground section for player detection.
	## Starts at z=-3 (after descending stairs, when player is actually underground).
	cave_area = Area3D.new()
	cave_area.name = "CaveInterior"

	var col_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	# Cover underground volume: x=[-2.5,+2.5], y=[-5.5,-0.5], z=[-24,-3]
	box_shape.size = Vector3(5.0, 5.0, 21.0)
	col_shape.shape = box_shape
	col_shape.position = Vector3(0, -3.0, -13.5)
	cave_area.add_child(col_shape)

	cave_area.body_entered.connect(_on_body_entered)
	cave_area.body_exited.connect(_on_body_exited)

	add_child(cave_area)


func _build_collision() -> void:
	# -- Stairway step collision (5 solid fills, 1.0 drop per step) --
	# Each step: width 4.6, from step top down to y=-5.5
	_add_collision(Vector3(0, -3.25, 2.25), Vector3(4.6, 4.5, 1.5))   # Step 1: top=-1.0
	_add_collision(Vector3(0, -3.75, 0.75), Vector3(4.6, 3.5, 1.5))   # Step 2: top=-2.0
	_add_collision(Vector3(0, -4.25, -0.75), Vector3(4.6, 2.5, 1.5))  # Step 3: top=-3.0
	_add_collision(Vector3(0, -4.75, -2.25), Vector3(4.6, 1.5, 1.5))  # Step 4: top=-4.0
	_add_collision(Vector3(0, -5.25, -3.75), Vector3(4.6, 0.5, 1.5))  # Step 5: top=-5.0

	# -- Crater/stair side walls --
	# Extended wide (2.8 units) to guarantee overlap with terrain cells regardless
	# of grid alignment. The terrain skip zone is X:[-3,+3] but cell boundaries
	# don't align to cave center, so walls must extend well past the skip zone edge.
	# Center shifted outward; inner edge stays at ~±2.4 (stairway is 4.6 wide).
	# Z-size 11.0 (center -1.5) covers Z:[-7,+4] to close gap with tunnel walls at Z:-6.
	_add_collision(Vector3(-3.8, -2.55, -1.5), Vector3(2.8, 5.5, 11.0))
	_add_collision(Vector3(3.8, -2.55, -1.5), Vector3(2.8, 5.5, 11.0))
	# Front wall - widened to match side walls, extended forward to overlap terrain
	_add_collision(Vector3(0, -2.55, 4.5), Vector3(10.4, 5.5, 2.2))

	# -- Tunnel collision --
	_add_collision(Vector3(-2.8, -3.0, -15.0), Vector3(0.8, 5.0, 18.0))
	_add_collision(Vector3(2.8, -3.0, -15.0), Vector3(0.8, 5.0, 18.0))
	# Ceiling (below terrain surface)
	_add_collision(Vector3(0, -0.2, -15.0), Vector3(6.4, 0.8, 18.0))
	# Back wall
	_add_collision(Vector3(0, -3.0, -24.5), Vector3(6.4, 5.0, 1.0))

	# -- Floor slab covering crater area --
	_add_collision(Vector3(0, -5.75, -1.0), Vector3(8.0, 0.5, 11.0))


func _add_collision(pos: Vector3, size: Vector3) -> void:
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = pos
	add_child(col)


func _spawn_resources() -> void:
	## Spawn 2 CrystalNodes and 1 RareOreNode inside the underground tunnel
	var crystal_script: GDScript = load("res://scripts/resources/crystal_node.gd")
	var ore_script: GDScript = load("res://scripts/resources/rare_ore_node.gd")

	if not crystal_script or not ore_script:
		push_warning("[CaveEntrance] Failed to load resource scripts")
		return

	# Crystal 1: left side, midway through tunnel (on the floor at y=-5.5)
	var crystal1: StaticBody3D = StaticBody3D.new()
	crystal1.set_script(crystal_script)
	crystal1.name = "CrystalNode_0"
	crystal1.position = Vector3(-1.8, -5.5, -12.0)
	crystal1.rotation_degrees = Vector3(0, 15, 0)
	add_child(crystal1)
	resource_nodes.append(crystal1)

	# Crystal 2: right side, deeper in tunnel (on the floor)
	var crystal2: StaticBody3D = StaticBody3D.new()
	crystal2.set_script(crystal_script)
	crystal2.name = "CrystalNode_1"
	crystal2.position = Vector3(1.8, -5.5, -19.0)
	crystal2.rotation_degrees = Vector3(0, -20, 0)
	add_child(crystal2)
	resource_nodes.append(crystal2)

	# Rare ore: back of cave on floor
	var ore: StaticBody3D = StaticBody3D.new()
	ore.set_script(ore_script)
	ore.name = "RareOreNode_0"
	ore.position = Vector3(0.5, -5.0, -22.0)
	add_child(ore)
	resource_nodes.append(ore)

	# Connect depleted signals for tracking
	for res_node: Node in resource_nodes:
		if res_node.has_signal("depleted"):
			res_node.depleted.connect(_on_resource_depleted.bind(res_node))


func _apply_saved_resource_state() -> void:
	## Check CaveTransition for depleted resources and apply state
	var cave_transition: Node = get_node_or_null("/root/CaveTransition")
	if not cave_transition or not cave_transition.has_method("get_depleted_cave_resources"):
		return

	# Get current game time from TimeManager
	var time_manager: Node = _find_time_manager()
	if not time_manager:
		return

	var current_day: int = time_manager.current_day if "current_day" in time_manager else 1
	var current_hour: int = time_manager.current_hour if "current_hour" in time_manager else 8
	var current_minute: int = time_manager.current_minute if "current_minute" in time_manager else 0

	var depleted_names: Array[String] = cave_transition.get_depleted_cave_resources(
		cave_id, current_day, current_hour, current_minute
	)

	for res_node: Node in resource_nodes:
		if res_node.name in depleted_names and res_node.has_method("_set_depleted_state"):
			res_node._set_depleted_state(true)


func _on_resource_depleted(res_node: Node) -> void:
	## Track resource depletion in CaveTransition
	var cave_transition: Node = get_node_or_null("/root/CaveTransition")
	if not cave_transition or not cave_transition.has_method("track_cave_resource_depleted"):
		return

	var time_manager: Node = _find_time_manager()
	var day: int = 1
	var hour: int = 8
	var minute: int = 0
	if time_manager:
		day = time_manager.current_day if "current_day" in time_manager else 1
		hour = time_manager.current_hour if "current_hour" in time_manager else 8
		minute = time_manager.current_minute if "current_minute" in time_manager else 0

	cave_transition.track_cave_resource_depleted(cave_id, res_node.name, day, hour, minute)
	resource_depleted.emit(cave_id, res_node.name)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var cave_transition: Node = get_node_or_null("/root/CaveTransition")
		if cave_transition and cave_transition.has_method("player_entered_cave"):
			cave_transition.player_entered_cave(cave_id)


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		var cave_transition: Node = get_node_or_null("/root/CaveTransition")
		if cave_transition and cave_transition.has_method("player_exited_cave"):
			cave_transition.player_exited_cave()


func _find_time_manager() -> Node:
	var root: Node = get_tree().root
	if root.has_node("Main/TimeManager"):
		return root.get_node("Main/TimeManager")
	return null
