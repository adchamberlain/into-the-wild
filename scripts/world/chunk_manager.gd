extends Node3D
class_name ChunkManager
## Manages dynamic loading/unloading of terrain chunks around the player.

# Chunk configuration
@export var chunk_size_cells: int = 16  # Cells per chunk side (16x16 = 256 cells per chunk)
@export var render_distance: int = 3  # Chunks to load in each direction from player
@export var cell_size: float = 3.0  # Size of each terrain cell

# Terrain generation settings (shared with chunks)
@export var height_scale: float = 5.0  # Height variation for hills
@export var height_step: float = 1.0   # 1 block = 1 unit
@export var noise_scale: float = 0.018  # Moderate frequency for varied terrain

# Tree spawning settings
@export var tree_density: float = 0.25
@export var tree_min_distance: float = 14.0
@export var tree_grid_size: float = 2.5

# Pond settings
var pond_center: Vector2 = Vector2(15.0, 12.0)
var pond_radius: float = 8.0
var pond_depth: float = 3.0  # Deeper pond for swimming

# Colors
# Vibrant lawn green - distinct from herb (0.3, 0.6, 0.25) and berry bush (0.2, 0.45, 0.15)
var grass_color: Color = Color(0.28, 0.52, 0.15)
# Rich dark soil brown
var dirt_color: Color = Color(0.40, 0.26, 0.14)

# Noise generators
var noise: FastNoiseLite
var forest_noise: FastNoiseLite
var noise_seed: int

# Tree scenes
var tree_scene: PackedScene
var big_tree_scene: PackedScene
var birch_tree_scene: PackedScene

# Resource scenes
var branch_scene: PackedScene
var rock_scene: PackedScene
var berry_bush_scene: PackedScene
var mushroom_scene: PackedScene
var herb_scene: PackedScene

# Resource spawning settings
@export var branch_density: float = 0.08  # Branches per grid cell chance
@export var rock_density: float = 0.03
@export var berry_density: float = 0.02
@export var mushroom_density: float = 0.025
@export var herb_density: float = 0.02

# Fishing spot
var fishing_spot_scene: PackedScene
var fishing_spot_spawned: bool = false

# Shared material for all chunks
var terrain_material: StandardMaterial3D

# Chunk tracking
var loaded_chunks: Dictionary = {}  # Vector2i -> TerrainChunk
var player: Node3D
var last_player_chunk: Vector2i = Vector2i(999999, 999999)  # Invalid initial value

# Performance settings
@export var chunks_per_frame: int = 1  # How many chunks to generate per frame
var chunks_to_load: Array[Vector2i] = []
var chunks_to_unload: Array[Vector2i] = []


func _ready() -> void:
	_setup_noise()
	_setup_material()
	_setup_world_floor()
	_load_scenes()

	# Find player node
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_parent().get_node_or_null("Player")

	if player:
		# Initial chunk loading around player
		_update_chunks_around_player()
	else:
		push_warning("[ChunkManager] No player found, loading chunks around origin")
		_load_chunks_around(Vector2i(0, 0))


func _process(_delta: float) -> void:
	if not player:
		return

	# Check if player moved to a new chunk
	var player_chunk: Vector2i = _world_to_chunk(player.global_position)
	if player_chunk != last_player_chunk:
		last_player_chunk = player_chunk
		_update_chunks_around_player()

	# Process chunk loading/unloading queue
	_process_chunk_queues()


func _setup_noise() -> void:
	noise_seed = randi()

	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = noise_seed
	noise.fractal_octaves = 1  # Single octave for smoother terrain
	noise.frequency = noise_scale

	forest_noise = FastNoiseLite.new()
	forest_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	forest_noise.seed = noise_seed + 500
	forest_noise.frequency = 0.08
	forest_noise.fractal_octaves = 2


func _setup_material() -> void:
	terrain_material = StandardMaterial3D.new()
	terrain_material.vertex_color_use_as_albedo = true
	terrain_material.albedo_color = Color.WHITE
	terrain_material.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT
	terrain_material.roughness = 1.0
	terrain_material.metallic = 0.0
	terrain_material.cull_mode = BaseMaterial3D.CULL_DISABLED


func _setup_world_floor() -> void:
	# Create an impenetrable floor at the bottom of the world (like bedrock)
	# This ensures nothing can ever fall through the world
	var world_floor := StaticBody3D.new()
	world_floor.name = "WorldFloor"

	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	# Very large horizontal extent, thin vertically
	floor_box.size = Vector3(10000, 1, 10000)
	floor_shape.shape = floor_box
	# Position at y=-100 (deep enough for any future caves)
	floor_shape.position = Vector3(0, -100, 0)

	world_floor.add_child(floor_shape)
	add_child(world_floor)

	print("[ChunkManager] World floor created at y=-100")


func _load_scenes() -> void:
	tree_scene = load("res://scenes/resources/tree_resource.tscn")
	big_tree_scene = load("res://scenes/resources/big_tree_resource.tscn")
	birch_tree_scene = load("res://scenes/resources/birch_tree_resource.tscn")
	fishing_spot_scene = load("res://scenes/resources/fishing_spot.tscn")

	# Load resource scenes
	branch_scene = load("res://scenes/resources/branch.tscn")
	rock_scene = load("res://scenes/resources/rock.tscn")
	berry_bush_scene = load("res://scenes/resources/berry_bush.tscn")
	mushroom_scene = load("res://scenes/resources/mushroom.tscn")
	herb_scene = load("res://scenes/resources/herb.tscn")

	if not tree_scene:
		push_warning("[ChunkManager] Failed to load tree scene")


func get_terrain_material() -> StandardMaterial3D:
	return terrain_material


func get_height_at(x: float, z: float) -> float:
	# Snap to cell center FIRST for consistent height across each cell
	# This ensures objects spawn at the same height as the terrain mesh
	var snapped_x: float = (floor(x / cell_size) + 0.5) * cell_size
	var snapped_z: float = (floor(z / cell_size) + 0.5) * cell_size

	# Use snapped coordinates for all distance calculations
	var flatten_radius: float = 6.0
	var flatten_falloff: float = 8.0

	# Flatten area around spawn point (campsite)
	var distance_from_center: float = Vector2(snapped_x, snapped_z).length()

	if distance_from_center < flatten_radius:
		return 0.0

	# Pond depression - create a deep area for swimming
	# Terrain floor is below water surface so player can sink
	var distance_from_pond: float = Vector2(snapped_x - pond_center.x, snapped_z - pond_center.y).length()
	if distance_from_pond < pond_radius:
		var pond_factor: float = distance_from_pond / pond_radius
		var pond_floor_y: float = -2.5  # Deep enough for swimming
		# Pond floor is deep, edges ramp up to normal terrain
		if pond_factor < 0.7:
			return pond_floor_y  # Flat pond floor (deep)
		else:
			# Gradual slope from pond floor to terrain edge
			var edge_factor: float = (pond_factor - 0.7) / 0.3
			return pond_floor_y + (height_step - pond_floor_y) * edge_factor

	# Base terrain height from noise (sampled at cell center)
	var raw_height: float = noise.get_noise_2d(snapped_x, snapped_z)
	var height: float = (raw_height + 1.0) * 0.5 * height_scale

	# Quantize to blocky steps
	height = floor(height / height_step) * height_step
	height = max(height_step, height)

	# Gradual transition from campsite (uses snapped distance)
	if distance_from_center < flatten_radius + flatten_falloff:
		var t: float = (distance_from_center - flatten_radius) / flatten_falloff
		t = clamp(t, 0.0, 1.0)
		t = floor(t * 4.0) / 4.0
		height *= t

	return height


func _world_to_chunk(world_pos: Vector3) -> Vector2i:
	var chunk_world_size: float = chunk_size_cells * cell_size
	var chunk_x: int = int(floor(world_pos.x / chunk_world_size))
	var chunk_z: int = int(floor(world_pos.z / chunk_world_size))
	return Vector2i(chunk_x, chunk_z)


func _update_chunks_around_player() -> void:
	var player_chunk: Vector2i = _world_to_chunk(player.global_position)
	_load_chunks_around(player_chunk)


func _load_chunks_around(center_chunk: Vector2i) -> void:
	# Determine which chunks should be loaded
	var should_be_loaded: Dictionary = {}

	for dx in range(-render_distance, render_distance + 1):
		for dz in range(-render_distance, render_distance + 1):
			var chunk_coord: Vector2i = Vector2i(center_chunk.x + dx, center_chunk.y + dz)
			should_be_loaded[chunk_coord] = true

	# Queue chunks to unload (loaded but shouldn't be)
	for chunk_coord in loaded_chunks.keys():
		if not should_be_loaded.has(chunk_coord):
			if not chunks_to_unload.has(chunk_coord):
				chunks_to_unload.append(chunk_coord)

	# Queue chunks to load (should be loaded but aren't)
	for chunk_coord in should_be_loaded.keys():
		if not loaded_chunks.has(chunk_coord) and not chunks_to_load.has(chunk_coord):
			chunks_to_load.append(chunk_coord)

	# Sort chunks to load by distance from player (closest first)
	chunks_to_load.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var dist_a: float = Vector2(a - center_chunk).length()
		var dist_b: float = Vector2(b - center_chunk).length()
		return dist_a < dist_b
	)


func _process_chunk_queues() -> void:
	# Unload chunks first (frees memory)
	var unloaded: int = 0
	while not chunks_to_unload.is_empty() and unloaded < chunks_per_frame:
		var chunk_coord: Vector2i = chunks_to_unload.pop_front()
		_unload_chunk(chunk_coord)
		unloaded += 1

	# Then load new chunks
	var loaded: int = 0
	while not chunks_to_load.is_empty() and loaded < chunks_per_frame:
		var chunk_coord: Vector2i = chunks_to_load.pop_front()
		_load_chunk(chunk_coord)
		loaded += 1


func _load_chunk(chunk_coord: Vector2i) -> void:
	if loaded_chunks.has(chunk_coord):
		return

	var chunk: TerrainChunk = TerrainChunk.new()
	chunk.setup(chunk_coord, self)
	chunk.name = "Chunk_%d_%d" % [chunk_coord.x, chunk_coord.y]
	add_child(chunk)
	chunk.generate()

	loaded_chunks[chunk_coord] = chunk

	# Spawn fishing spot if this chunk contains the pond and we haven't spawned it yet
	if not fishing_spot_spawned:
		var chunk_world_size: float = chunk_size_cells * cell_size
		var chunk_min_x: float = chunk_coord.x * chunk_world_size
		var chunk_max_x: float = chunk_min_x + chunk_world_size
		var chunk_min_z: float = chunk_coord.y * chunk_world_size
		var chunk_max_z: float = chunk_min_z + chunk_world_size

		if pond_center.x >= chunk_min_x and pond_center.x < chunk_max_x and \
		   pond_center.y >= chunk_min_z and pond_center.y < chunk_max_z:
			_spawn_fishing_spot()


func _unload_chunk(chunk_coord: Vector2i) -> void:
	if not loaded_chunks.has(chunk_coord):
		return

	var chunk: TerrainChunk = loaded_chunks[chunk_coord]
	chunk.unload()
	loaded_chunks.erase(chunk_coord)


func _spawn_fishing_spot() -> void:
	if not fishing_spot_scene or fishing_spot_spawned:
		return

	var fishing_spot: Node3D = fishing_spot_scene.instantiate()
	fishing_spot.name = "Pond"

	# Position water to fill the terrain depression
	# Terrain pond floor is at Y=0, water surface should be slightly above
	var pond_y: float = 0.0
	fishing_spot.position = Vector3(pond_center.x, pond_y, pond_center.y)

	if "pond_width" in fishing_spot:
		# Water should fill the terrain depression edge-to-edge
		# Terrain reaches water level at about 93% of pond_radius
		var water_diameter: float = pond_radius * 2.0 * 0.95
		fishing_spot.pond_width = water_diameter
		fishing_spot.pond_depth = water_diameter
		fishing_spot.fish_count = 5

	add_child(fishing_spot)
	fishing_spot_spawned = true
	print("[ChunkManager] Spawned fishing pond at (%.1f, %.1f)" % [pond_center.x, pond_center.y])


# Debug info
func get_loaded_chunk_count() -> int:
	return loaded_chunks.size()


func get_pending_load_count() -> int:
	return chunks_to_load.size()


func get_pending_unload_count() -> int:
	return chunks_to_unload.size()
