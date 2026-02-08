extends StaticBody3D
class_name CaveEntrance
## Inline cave structure - a walkable tunnel built directly in the overworld.
## Player walks in freely (no interaction needed). Contains crystal/ore resources.
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


func _ready() -> void:
	add_to_group("cave_entrance")
	call_deferred("_setup_visuals")


func _make_rock_mat(r: float, g: float, b: float) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(r, g, b)
	mat.roughness = 0.95
	return mat


func _add_rock(pos: Vector3, size: Vector3, rot: Vector3, tint: float, rng: RandomNumberGenerator) -> MeshInstance3D:
	## Helper: create a rock block with position, size, rotation, and color tint
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	# Base grey-brown with tint variation
	mesh_inst.material_override = _make_rock_mat(
		clamp(0.42 + tint + rng.randf_range(-0.02, 0.02), 0.28, 0.52),
		clamp(0.40 + tint * 0.8 + rng.randf_range(-0.02, 0.02), 0.26, 0.48),
		clamp(0.36 + tint * 0.6 + rng.randf_range(-0.02, 0.02), 0.24, 0.44)
	)
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
	# Tunnel extends from z=0 to z=-18.

	# ===== ENTRANCE ROCK FORMATION =====
	_build_entrance_rocks(dark_mat, rng)

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


func _build_entrance_rocks(dark_mat: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	# ===== DARK OPENING (the main visual landmark) =====
	darkness_mesh = MeshInstance3D.new()
	darkness_mesh.name = "DarkOpening"
	var dark_box := BoxMesh.new()
	dark_box.size = Vector3(3.2, 3.2, 0.4)
	darkness_mesh.mesh = dark_box
	darkness_mesh.material_override = dark_mat
	darkness_mesh.position = Vector3(0, 1.6, 0.5)
	add_child(darkness_mesh)

	# Upper dark extension (makes opening taller on one side)
	var dark_upper := MeshInstance3D.new()
	var du_mesh := BoxMesh.new()
	du_mesh.size = Vector3(2.0, 0.8, 0.4)
	dark_upper.mesh = du_mesh
	dark_upper.material_override = dark_mat
	dark_upper.position = Vector3(-0.4, 3.4, 0.5)
	add_child(dark_upper)
	arch_meshes.append(dark_upper)

	# Lower side dark extension (widens base irregularly)
	var dark_side := MeshInstance3D.new()
	var ds_mesh := BoxMesh.new()
	ds_mesh.size = Vector3(0.6, 1.5, 0.4)
	dark_side.mesh = ds_mesh
	dark_side.material_override = dark_mat
	dark_side.position = Vector3(1.8, 0.75, 0.5)
	add_child(dark_side)
	arch_meshes.append(dark_side)

	# Depth layers - dark planes going back to give sense of depth
	for depth_i: int in range(3):
		var depth_dark := MeshInstance3D.new()
		var dd_mesh := BoxMesh.new()
		var shrink: float = float(depth_i) * 0.15
		dd_mesh.size = Vector3(2.8 - shrink, 2.8 - shrink, 0.2)
		depth_dark.mesh = dd_mesh
		depth_dark.material_override = dark_mat
		depth_dark.position = Vector3(0, 1.6, 0.1 - float(depth_i) * 0.5)
		add_child(depth_dark)
		arch_meshes.append(depth_dark)

	# ===== ROCK FORMATION (layered blocks forming a natural outcrop) =====

	# -- Left rock mass: 3 stacked irregular blocks --
	_add_rock(Vector3(-2.8, 1.0, 0.2), Vector3(2.4, 2.0, 2.2), Vector3(0, rng.randf_range(-4, 4), rng.randf_range(-2, 2)), -0.04, rng)
	_add_rock(Vector3(-2.5, 2.6, 0.0), Vector3(2.0, 1.4, 2.0), Vector3(rng.randf_range(-3, 3), rng.randf_range(-6, 6), rng.randf_range(-3, 3)), -0.02, rng)
	_add_rock(Vector3(-2.3, 3.8, 0.1), Vector3(1.6, 1.0, 1.6), Vector3(rng.randf_range(-5, 5), rng.randf_range(-8, 8), rng.randf_range(-4, 4)), 0.02, rng)

	# -- Right rock mass: 3 stacked irregular blocks --
	_add_rock(Vector3(2.8, 1.0, 0.2), Vector3(2.2, 2.0, 2.4), Vector3(0, rng.randf_range(-4, 4), rng.randf_range(-2, 2)), -0.03, rng)
	_add_rock(Vector3(2.6, 2.5, 0.1), Vector3(1.8, 1.2, 2.0), Vector3(rng.randf_range(-3, 3), rng.randf_range(-6, 6), rng.randf_range(-3, 3)), 0.0, rng)
	_add_rock(Vector3(3.0, 3.5, 0.0), Vector3(1.4, 0.8, 1.4), Vector3(rng.randf_range(-5, 5), rng.randf_range(-8, 8), rng.randf_range(-4, 4)), 0.03, rng)

	# -- Top rock mass: spans across the opening --
	_add_rock(Vector3(0, 3.8, 0.3), Vector3(5.0, 1.4, 2.2), Vector3(rng.randf_range(-3, 3), 0, rng.randf_range(-2, 2)), 0.01, rng)
	_add_rock(Vector3(rng.randf_range(-0.5, 0.5), 4.8, -0.1), Vector3(3.5, 1.0, 2.0), Vector3(rng.randf_range(-4, 4), rng.randf_range(-5, 5), rng.randf_range(-3, 3)), 0.04, rng)

	# -- Overhang: juts forward above the opening --
	_add_rock(Vector3(rng.randf_range(-0.3, 0.3), 4.2, 1.2), Vector3(3.5, 0.7, 1.5), Vector3(-12, 0, rng.randf_range(-3, 3)), 0.02, rng)

	# ===== RUBBLE / BOULDERS at base =====
	_add_rock(Vector3(-2.0, 0.4, 1.8), Vector3(1.6, 0.8, 1.2), Vector3(rng.randf_range(-5, 5), rng.randf_range(0, 20), rng.randf_range(-5, 5)), -0.02, rng)
	_add_rock(Vector3(2.2, 0.35, 2.0), Vector3(1.4, 0.7, 1.0), Vector3(rng.randf_range(-5, 5), rng.randf_range(0, 30), rng.randf_range(-5, 5)), 0.0, rng)

	# Scattered smaller boulders
	for i: int in range(6):
		var bsize: float = rng.randf_range(0.4, 1.0)
		var angle: float = rng.randf_range(-1.3, 1.3)
		var dist: float = rng.randf_range(2.0, 4.5)
		_add_rock(
			Vector3(sin(angle) * dist, bsize * 0.25, cos(angle) * dist + 1.5),
			Vector3(bsize, bsize * 0.55, bsize * 0.7),
			Vector3(rng.randf_range(-10, 10), rng.randf_range(0, 45), rng.randf_range(-8, 8)),
			rng.randf_range(-0.05, 0.05), rng
		)

	# Ground rubble slabs leading to opening (flat rocks)
	for i: int in range(3):
		var sx: float = rng.randf_range(-1.5, 1.5)
		var sz: float = rng.randf_range(0.8, 2.5)
		_add_rock(
			Vector3(sx, 0.06, sz),
			Vector3(rng.randf_range(0.6, 1.2), 0.12, rng.randf_range(0.5, 1.0)),
			Vector3(0, rng.randf_range(0, 45), 0),
			rng.randf_range(-0.03, 0.03), rng
		)

	# ===== STALACTITES hanging from lintel =====
	for i: int in range(4):
		var s_h: float = rng.randf_range(0.3, 0.9)
		var stalac := MeshInstance3D.new()
		var s_mesh := BoxMesh.new()
		s_mesh.size = Vector3(0.18, s_h, 0.18)
		stalac.mesh = s_mesh
		stalac.material_override = _make_rock_mat(0.38, 0.36, 0.32)
		stalac.position = Vector3(
			rng.randf_range(-1.3, 1.3),
			3.3 - s_h * 0.5,
			rng.randf_range(0.2, 0.9)
		)
		stalac.rotation_degrees = Vector3(rng.randf_range(-5, 5), 0, rng.randf_range(-5, 5))
		add_child(stalac)
		arch_meshes.append(stalac)

	# ===== MOSS patches on rock surfaces =====
	var moss_mat := StandardMaterial3D.new()
	moss_mat.albedo_color = Color(0.25, 0.35, 0.20, 0.65)
	moss_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	moss_mat.roughness = 0.95
	for i: int in range(4):
		var moss := MeshInstance3D.new()
		var m_mesh := BoxMesh.new()
		m_mesh.size = Vector3(rng.randf_range(0.6, 1.8), 0.06, rng.randf_range(0.5, 1.2))
		moss.mesh = m_mesh
		moss.material_override = moss_mat
		var mx: float = rng.randf_range(-3.0, 3.0)
		var my: float = rng.randf_range(0.5, 3.5)
		moss.position = Vector3(mx, my, rng.randf_range(-0.2, 0.8))
		moss.rotation_degrees = Vector3(rng.randf_range(-20, 20), rng.randf_range(0, 90), rng.randf_range(-10, 10))
		add_child(moss)
		arch_meshes.append(moss)


func _build_tunnel(rng: RandomNumberGenerator) -> void:
	## Build the walkable tunnel extending from z=0 to z=-18
	var wall_mat: StandardMaterial3D = _get_wall_material()
	var floor_mat: StandardMaterial3D = _get_floor_material()
	var ceiling_mat: StandardMaterial3D = _get_ceiling_material()

	# Tunnel dimensions: 6 wide (x=-3 to +3), 5 tall (y=0 to 5), 18 deep (z=0 to -18)

	# -- LEFT WALL: segmented for visual interest --
	for seg: int in range(6):
		var z_start: float = -float(seg) * 3.0
		var width_var: float = rng.randf_range(-0.15, 0.15)
		_add_interior_rock(
			Vector3(-3.0 - width_var, 2.5, z_start - 1.5),
			Vector3(0.8 + width_var * 2.0, 5.0, 3.0),
			Vector3(0, 0, 0),
			wall_mat
		)

	# -- RIGHT WALL: segmented --
	for seg: int in range(6):
		var z_start: float = -float(seg) * 3.0
		var width_var: float = rng.randf_range(-0.15, 0.15)
		_add_interior_rock(
			Vector3(3.0 + width_var, 2.5, z_start - 1.5),
			Vector3(0.8 + width_var * 2.0, 5.0, 3.0),
			Vector3(0, 0, 0),
			wall_mat
		)

	# -- CEILING: spans the width, segmented --
	for seg: int in range(6):
		var z_start: float = -float(seg) * 3.0
		var height_var: float = rng.randf_range(-0.2, 0.2)
		_add_interior_rock(
			Vector3(0, 5.0 + height_var, z_start - 1.5),
			Vector3(7.6, 0.8, 3.0),
			Vector3(0, 0, 0),
			ceiling_mat
		)

	# -- FLOOR: continuous slab --
	_add_interior_rock(
		Vector3(0, -0.25, -9.0),
		Vector3(6.0, 0.5, 18.0),
		Vector3(0, 0, 0),
		floor_mat
	)

	# -- BACK WALL: seals the end of the tunnel --
	_add_interior_rock(
		Vector3(0, 2.5, -18.5),
		Vector3(7.6, 5.5, 1.0),
		Vector3(0, 0, 0),
		wall_mat
	)


func _build_interior_details(rng: RandomNumberGenerator) -> void:
	## Add stalactites, wall outcrops, and rubble inside the tunnel
	var wall_mat: StandardMaterial3D = _get_wall_material()

	# -- Stalactites hanging from ceiling --
	for i: int in range(8):
		var s_h: float = rng.randf_range(0.3, 1.2)
		var stalac_mat: StandardMaterial3D = _make_rock_mat(
			0.17 + rng.randf_range(-0.02, 0.02),
			0.15 + rng.randf_range(-0.02, 0.02),
			0.13 + rng.randf_range(-0.02, 0.02)
		)
		_add_interior_rock(
			Vector3(rng.randf_range(-2.2, 2.2), 5.0 - s_h * 0.5, rng.randf_range(-16.0, -1.0)),
			Vector3(rng.randf_range(0.12, 0.25), s_h, rng.randf_range(0.12, 0.25)),
			Vector3(rng.randf_range(-5, 5), 0, rng.randf_range(-5, 5)),
			stalac_mat
		)

	# -- Wall outcrops (bulges from walls) --
	for i: int in range(4):
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var outcrop_z: float = rng.randf_range(-15.0, -2.0)
		var outcrop_y: float = rng.randf_range(0.5, 3.5)
		var tint: float = rng.randf_range(-0.03, 0.03)
		_add_interior_rock(
			Vector3(side * (2.6 + rng.randf_range(0.0, 0.3)), outcrop_y, outcrop_z),
			Vector3(rng.randf_range(0.8, 1.5), rng.randf_range(0.8, 2.0), rng.randf_range(0.8, 1.5)),
			Vector3(rng.randf_range(-5, 5), rng.randf_range(-5, 5), rng.randf_range(-3, 3)),
			_make_rock_mat(0.22 + tint, 0.20 + tint * 0.8, 0.17 + tint * 0.6)
		)

	# -- Floor rubble (small rocks scattered on the floor) --
	for i: int in range(6):
		var bsize: float = rng.randf_range(0.25, 0.7)
		_add_interior_rock(
			Vector3(rng.randf_range(-2.0, 2.0), bsize * 0.25, rng.randf_range(-16.0, -1.0)),
			Vector3(bsize, bsize * 0.5, bsize * 0.65),
			Vector3(rng.randf_range(-8, 8), rng.randf_range(0, 45), rng.randf_range(-5, 5)),
			_make_rock_mat(
				0.20 + rng.randf_range(-0.03, 0.03),
				0.18 + rng.randf_range(-0.02, 0.02),
				0.15 + rng.randf_range(-0.02, 0.02)
			)
		)

	# -- Stalagmites rising from floor --
	for i: int in range(3):
		var s_h: float = rng.randf_range(0.4, 1.0)
		_add_interior_rock(
			Vector3(rng.randf_range(-2.0, 2.0), s_h * 0.5, rng.randf_range(-15.0, -3.0)),
			Vector3(rng.randf_range(0.2, 0.4), s_h, rng.randf_range(0.2, 0.4)),
			Vector3(rng.randf_range(-3, 3), 0, rng.randf_range(-3, 3)),
			_make_rock_mat(0.20, 0.18, 0.15)
		)


func _build_cave_area() -> void:
	## Create an Area3D covering the cave interior for player detection
	cave_area = Area3D.new()
	cave_area.name = "CaveInterior"

	var col_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	# Cover interior volume: x=-3 to +3, y=0 to 5, z=0 to -18
	box_shape.size = Vector3(6.0, 5.0, 18.0)
	col_shape.shape = box_shape
	col_shape.position = Vector3(0, 2.5, -9.0)
	cave_area.add_child(col_shape)

	cave_area.body_entered.connect(_on_body_entered)
	cave_area.body_exited.connect(_on_body_exited)

	add_child(cave_area)


func _build_collision() -> void:
	# -- Entrance rock collision --
	# Left rock mass
	_add_collision(Vector3(-2.8, 2.0, 0.1), Vector3(2.4, 4.0, 2.2))
	# Right rock mass
	_add_collision(Vector3(2.8, 2.0, 0.1), Vector3(2.2, 4.0, 2.4))
	# Top lintel
	_add_collision(Vector3(0, 4.2, 0.1), Vector3(5.5, 2.0, 2.2))

	# -- Tunnel collision --
	# Left wall
	_add_collision(Vector3(-3.4, 2.5, -9.0), Vector3(0.8, 5.0, 18.0))
	# Right wall
	_add_collision(Vector3(3.4, 2.5, -9.0), Vector3(0.8, 5.0, 18.0))
	# Ceiling
	_add_collision(Vector3(0, 5.4, -9.0), Vector3(7.6, 0.8, 18.0))
	# Floor
	_add_collision(Vector3(0, -0.25, -9.0), Vector3(6.0, 0.5, 18.0))
	# Back wall
	_add_collision(Vector3(0, 2.5, -18.5), Vector3(7.6, 5.5, 1.0))


func _add_collision(pos: Vector3, size: Vector3) -> void:
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = pos
	add_child(col)


func _spawn_resources() -> void:
	## Spawn 2 CrystalNodes and 1 RareOreNode inside the cave
	var crystal_script: GDScript = load("res://scripts/resources/crystal_node.gd")
	var ore_script: GDScript = load("res://scripts/resources/rare_ore_node.gd")

	if not crystal_script or not ore_script:
		push_warning("[CaveEntrance] Failed to load resource scripts")
		return

	# Crystal 1: left wall, midway through tunnel
	var crystal1: StaticBody3D = StaticBody3D.new()
	crystal1.set_script(crystal_script)
	crystal1.name = "CrystalNode_0"
	crystal1.position = Vector3(-2.2, 1.0, -6.0)
	crystal1.rotation_degrees = Vector3(0, 15, 10)
	add_child(crystal1)
	resource_nodes.append(crystal1)

	# Crystal 2: right wall, deeper in tunnel
	var crystal2: StaticBody3D = StaticBody3D.new()
	crystal2.set_script(crystal_script)
	crystal2.name = "CrystalNode_1"
	crystal2.position = Vector3(2.0, 1.5, -13.0)
	crystal2.rotation_degrees = Vector3(0, -20, -8)
	add_child(crystal2)
	resource_nodes.append(crystal2)

	# Rare ore: back of cave
	var ore: StaticBody3D = StaticBody3D.new()
	ore.set_script(ore_script)
	ore.name = "RareOreNode_0"
	ore.position = Vector3(0.5, 0.5, -16.0)
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
