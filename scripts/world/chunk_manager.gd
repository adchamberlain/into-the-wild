extends Node3D
class_name ChunkManager
## Manages dynamic loading/unloading of terrain chunks around the player.

# Region types for terrain variety
enum RegionType { MEADOW, FOREST, HILLS, ROCKY }

# Water body types
enum WaterBodyType { POND, LAKE, RIVER }

# Chunk configuration
@export var chunk_size_cells: int = 16  # Cells per chunk side (16x16 = 256 cells per chunk)
@export var render_distance: int = 2  # Chunks to load in each direction (reduced from 3 for performance)
@export var cell_size: float = 3.0  # Size of each terrain cell

# Terrain generation settings (shared with chunks)
@export var height_scale: float = 5.0  # Height variation for hills (default, per-region override)
@export var height_step: float = 1.0   # 1 block = 1 unit (default, per-region override)
@export var noise_scale: float = 0.018  # Moderate frequency for varied terrain

# Tree spawning settings
@export var tree_density: float = 0.25
@export var tree_min_distance: float = 14.0
@export var tree_grid_size: float = 2.5

# Water body settings - structured storage replacing simple pond_locations
# Each water body: {type: WaterBodyType, center: Vector2, radius: float, depth: float}
var water_bodies: Array[Dictionary] = []

# Rivers stored separately (polyline paths)
# Each: {path: Array[Vector2], width: float, fishing_pools: Array[Vector2]}
var rivers: Array[Dictionary] = []

# Pond settings (region-specific sizes)
var pond_radius: float = 8.0  # Default radius for backward compatibility
var pond_depth: float = 2.5  # Default depth for swimming
var pond_min_spacing: float = 50.0  # Minimum distance between ponds
var pond_count: int = 6  # Target number of ponds to generate

# Lake settings
var lake_count: int = 2  # Target number of lakes (MEADOW only)
var lake_min_radius: float = 20.0
var lake_max_radius: float = 30.0
var lake_depth: float = 3.0
var lake_min_spacing: float = 80.0  # Min distance between lakes
var lake_pond_spacing: float = 40.0  # Min distance from ponds

# River settings
var river_count: int = 2  # Target number of rivers
var river_base_width: float = 5.0
var river_fishing_pool_width: float = 8.0
var river_depth: float = 2.0
var river_fishing_pool_spacing: float = 40.0  # Distance between fishing pools

# Region-specific pond sizes {radius_min, radius_max, depth}
var region_pond_params: Dictionary = {
	RegionType.MEADOW: {"radius_min": 10.0, "radius_max": 14.0, "depth": 2.5},
	RegionType.FOREST: {"radius_min": 6.0, "radius_max": 10.0, "depth": 2.5},
	RegionType.HILLS: {"radius_min": 5.0, "radius_max": 8.0, "depth": 3.0},
	RegionType.ROCKY: {"radius_min": 4.0, "radius_max": 6.0, "depth": 3.5}
}

# Legacy support - computed from water_bodies for existing code
var pond_locations: Array[Vector2] = []

# Colors (default forest colors, overridden per region)
# Vibrant lawn green - distinct from herb (0.3, 0.6, 0.25) and berry bush (0.2, 0.45, 0.15)
var grass_color: Color = Color(0.28, 0.52, 0.15)
# Rich dark soil brown
var dirt_color: Color = Color(0.40, 0.26, 0.14)

# Region-specific color palettes
var region_colors: Dictionary = {
	RegionType.MEADOW: {
		"grass": Color(0.35, 0.58, 0.20),  # Lighter, vibrant green
		"dirt": Color(0.45, 0.30, 0.18)     # Light brown
	},
	RegionType.FOREST: {
		"grass": Color(0.28, 0.52, 0.15),  # Current dark green
		"dirt": Color(0.40, 0.26, 0.14)     # Current brown
	},
	RegionType.HILLS: {
		"grass": Color(0.32, 0.48, 0.18),  # Medium green
		"dirt": Color(0.42, 0.28, 0.16)     # Medium brown
	},
	RegionType.ROCKY: {
		"grass": Color(0.45, 0.42, 0.38),  # Grey stone
		"dirt": Color(0.35, 0.33, 0.30)     # Dark grey
	}
}

# Region-specific height parameters
var region_height_params: Dictionary = {
	RegionType.MEADOW: {"scale": 2.0, "step": 0.5},   # Gentle rolling terrain
	RegionType.FOREST: {"scale": 5.0, "step": 1.0},   # Current default
	RegionType.HILLS: {"scale": 22.0, "step": 1.0},   # Dramatic hills with jumpable steps
	RegionType.ROCKY: {"scale": 12.0, "step": 1.0}    # Jagged cliffs with jumpable steps
}

# Region-specific vegetation multipliers
var region_vegetation: Dictionary = {
	RegionType.MEADOW: {"tree": 0.1, "rock": 0.3, "berry": 2.0, "herb": 2.0},
	RegionType.FOREST: {"tree": 1.5, "rock": 1.0, "berry": 1.0, "herb": 1.0},
	RegionType.HILLS: {"tree": 0.6, "rock": 1.5, "berry": 0.8, "herb": 0.8},
	RegionType.ROCKY: {"tree": 0.2, "rock": 5.0, "berry": 0.2, "herb": 0.2}
}

# Noise generators
var noise: FastNoiseLite
var forest_noise: FastNoiseLite
var region_noise: FastNoiseLite  # Low-frequency noise for region determination
var detail_noise: FastNoiseLite  # Higher-frequency detail for hills
var hill_noise: FastNoiseLite    # Large-scale hill shapes
var path_noise: FastNoiseLite    # Creates valleys/paths through hills for climbing
var noise_seed: int = 0
var noise_seed_set: bool = false  # True if seed was set externally (e.g., from save file)

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
var ore_scene: PackedScene

# Resource spawning settings
@export var branch_density: float = 0.08  # Branches per grid cell chance
@export var rock_density: float = 0.03
@export var berry_density: float = 0.02
@export var mushroom_density: float = 0.025
@export var herb_density: float = 0.02

# Fishing spots (one per pond/lake)
var fishing_spot_scene: PackedScene
var spawned_pond_indices: Array[int] = []  # Track which water bodies have fishing spots

# River segments tracking
var river_segment_scene: PackedScene
var spawned_river_indices: Array[int] = []  # Track which rivers have been fully spawned
var spawned_river_fishing_pools: Array[Vector2] = []  # Track spawned river fishing pools

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
	add_to_group("chunk_manager")
	_setup_noise()
	_generate_water_bodies()
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

	# Process chunk loading/unloading queue (skip if nothing to do)
	if not chunks_to_load.is_empty() or not chunks_to_unload.is_empty():
		_process_chunk_queues()


func _setup_noise() -> void:
	# Check for pending world seed from GameState autoload (set during save load)
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state and game_state.has_pending_seed:
		noise_seed = game_state.consume_pending_world_seed()
		noise_seed_set = true

	# Only generate a new seed if one wasn't set externally (e.g., from save file)
	if not noise_seed_set:
		noise_seed = randi()
		print("[ChunkManager] Generated new world seed: %d" % noise_seed)
	else:
		print("[ChunkManager] Using existing world seed: %d" % noise_seed)

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

	# Region noise - very low frequency for large distinct regions (~125 units across)
	region_noise = FastNoiseLite.new()
	region_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	region_noise.seed = noise_seed + 1500
	region_noise.frequency = 0.008
	region_noise.fractal_octaves = 1

	# Detail noise for hills - adds variety to dramatic terrain
	detail_noise = FastNoiseLite.new()
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	detail_noise.seed = noise_seed + 2500
	detail_noise.frequency = 0.04
	detail_noise.fractal_octaves = 2

	# Hill noise - creates large-scale hill shapes with more variation
	hill_noise = FastNoiseLite.new()
	hill_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	hill_noise.seed = noise_seed + 3500
	hill_noise.frequency = 0.012  # Large hills
	hill_noise.fractal_octaves = 3
	hill_noise.fractal_lacunarity = 2.0
	hill_noise.fractal_gain = 0.5

	# Path noise - creates winding valleys/ridges for climbing paths
	path_noise = FastNoiseLite.new()
	path_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	path_noise.seed = noise_seed + 4500
	path_noise.frequency = 0.025  # Medium frequency for winding paths
	path_noise.fractal_octaves = 2


## Get the current world seed for saving.
func get_world_seed() -> int:
	return noise_seed


## Set the world seed before terrain generation (call before _ready runs, or use set_world_seed_and_regenerate).
func set_world_seed(seed_value: int) -> void:
	noise_seed = seed_value
	noise_seed_set = true
	print("[ChunkManager] World seed set to: %d" % seed_value)


func _generate_water_bodies() -> void:
	## Master function that generates all water features in sequence
	water_bodies.clear()
	rivers.clear()
	pond_locations.clear()

	_generate_pond_locations()
	_generate_lakes()
	_generate_rivers()

	# Update legacy pond_locations for backward compatibility
	_update_legacy_pond_locations()

	print("[ChunkManager] Water features generated: %d ponds, %d lakes, %d rivers" % [
		_count_water_bodies(WaterBodyType.POND),
		_count_water_bodies(WaterBodyType.LAKE),
		rivers.size()
	])

	# Print all water locations for debugging
	print_water_locations()


func _generate_pond_locations() -> void:
	# Generate multiple ponds spread across the landscape with region-specific sizes
	# First pond is always near the campsite (the main fishing pond)
	var camp_pond_center: Vector2 = Vector2(15.0, 12.0)
	var camp_region: RegionType = get_region_at(camp_pond_center.x, camp_pond_center.y)
	var camp_params: Dictionary = region_pond_params.get(camp_region, region_pond_params[RegionType.FOREST])

	water_bodies.append({
		"type": WaterBodyType.POND,
		"center": camp_pond_center,
		"radius": 8.0,  # Fixed size for camp pond
		"depth": camp_params["depth"]
	})

	# Use deterministic random for consistent world generation
	var pond_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	pond_rng.seed = noise_seed + 777

	# World extent - ponds can spawn within loaded chunk range
	var world_extent: float = 150.0  # Reasonable exploration distance

	var attempts: int = 0
	var max_attempts: int = pond_count * 50
	var ponds_generated: int = 1  # Already have camp pond

	while ponds_generated < pond_count and attempts < max_attempts:
		attempts += 1

		# Generate random position
		var candidate: Vector2 = Vector2(
			pond_rng.randf_range(-world_extent, world_extent),
			pond_rng.randf_range(-world_extent, world_extent)
		)

		# Check distance from campsite (not too close)
		if candidate.length() < 25.0:
			continue

		# Check distance from all existing water bodies
		var too_close: bool = false
		for body in water_bodies:
			var spacing: float = pond_min_spacing
			if body["type"] == WaterBodyType.LAKE:
				spacing = lake_pond_spacing
			if candidate.distance_to(body["center"]) < spacing + body["radius"]:
				too_close = true
				break

		if too_close:
			continue

		# Get region-specific pond parameters
		var region: RegionType = get_region_at(candidate.x, candidate.y)
		var params: Dictionary = region_pond_params.get(region, region_pond_params[RegionType.FOREST])

		var pond_size: float = pond_rng.randf_range(params["radius_min"], params["radius_max"])

		water_bodies.append({
			"type": WaterBodyType.POND,
			"center": candidate,
			"radius": pond_size,
			"depth": params["depth"]
		})

		ponds_generated += 1
		print("[ChunkManager] Generated %s pond at (%.1f, %.1f) radius=%.1f" % [
			RegionType.keys()[region], candidate.x, candidate.y, pond_size
		])


func _generate_lakes() -> void:
	## Generate 2-3 large lakes in MEADOW regions only
	var lake_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	lake_rng.seed = noise_seed + 888

	var world_extent: float = 150.0
	var attempts: int = 0
	var max_attempts: int = lake_count * 100
	var lakes_generated: int = 0

	while lakes_generated < lake_count and attempts < max_attempts:
		attempts += 1

		# Generate random position
		var candidate: Vector2 = Vector2(
			lake_rng.randf_range(-world_extent, world_extent),
			lake_rng.randf_range(-world_extent, world_extent)
		)

		# Lakes must be far from spawn
		if candidate.length() < 50.0:
			continue

		# Lakes only in MEADOW regions
		var region: RegionType = get_region_at(candidate.x, candidate.y)
		if region != RegionType.MEADOW:
			continue

		# Check distance from existing water bodies
		var too_close: bool = false
		for body in water_bodies:
			var required_spacing: float = lake_min_spacing if body["type"] == WaterBodyType.LAKE else lake_pond_spacing
			if candidate.distance_to(body["center"]) < required_spacing + body["radius"]:
				too_close = true
				break

		if too_close:
			continue

		var lake_radius: float = lake_rng.randf_range(lake_min_radius, lake_max_radius)

		water_bodies.append({
			"type": WaterBodyType.LAKE,
			"center": candidate,
			"radius": lake_radius,
			"depth": lake_depth
		})

		lakes_generated += 1
		print("[ChunkManager] Generated lake at (%.1f, %.1f) radius=%.1f" % [
			candidate.x, candidate.y, lake_radius
		])


func _generate_rivers() -> void:
	## Generate 2-3 rivers flowing from HILLS/ROCKY regions down to MEADOW
	var river_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	river_rng.seed = noise_seed + 999

	var world_extent: float = 120.0
	var attempts: int = 0
	var max_attempts: int = river_count * 200  # More attempts to find valid spots
	var rivers_generated: int = 0

	while rivers_generated < river_count and attempts < max_attempts:
		attempts += 1

		# Find a source point in HILLS or ROCKY region
		var source: Vector2 = Vector2(
			river_rng.randf_range(-world_extent, world_extent),
			river_rng.randf_range(-world_extent, world_extent)
		)

		# Must start well away from camp/spawn area
		if source.length() < 50.0:
			continue

		var source_region: RegionType = get_region_at(source.x, source.y)
		# Also allow FOREST as a fallback if no HILLS/ROCKY found after many attempts
		var valid_region: bool = source_region == RegionType.HILLS or source_region == RegionType.ROCKY
		if not valid_region and attempts > max_attempts / 2:
			valid_region = source_region == RegionType.FOREST  # Fallback to forest
		if not valid_region:
			continue

		# Check distance from existing rivers
		var too_close_to_river: bool = false
		for existing_river in rivers:
			if existing_river["path"].size() > 0:
				if source.distance_to(existing_river["path"][0]) < 60.0:
					too_close_to_river = true
					break
		if too_close_to_river:
			continue

		# Generate river path following terrain gradient
		var river_path: Array[Vector2] = _generate_river_path(source, river_rng)

		if river_path.size() < 4:
			continue  # Too short, try again

		# Place fishing pools along the river
		var fishing_pools: Array[Vector2] = _place_fishing_pools(river_path)

		rivers.append({
			"path": river_path,
			"width": river_base_width,
			"fishing_pools": fishing_pools
		})

		rivers_generated += 1
		var start_pos: Vector2 = river_path[0]
		var end_pos: Vector2 = river_path[river_path.size() - 1]
		print("[ChunkManager] Generated river #%d: start (%.0f, %.0f) -> end (%.0f, %.0f), %d segments, %d pools" % [
			rivers_generated, start_pos.x, start_pos.y, end_pos.x, end_pos.y,
			river_path.size(), fishing_pools.size()
		])


func _generate_river_path(source: Vector2, rng: RandomNumberGenerator) -> Array[Vector2]:
	## Generate a river path following terrain gradient toward lower regions
	var path: Array[Vector2] = [source]
	var current: Vector2 = source
	var segment_length: float = 18.0
	var max_segments: int = 10
	var direction: Vector2 = Vector2.ZERO
	var spawn_exclusion_radius: float = 40.0  # Keep rivers away from spawn area

	for _i in range(max_segments):
		# Sample heights in multiple directions to find downhill
		var best_dir: Vector2 = Vector2.ZERO
		var lowest_height: float = INF

		for angle_offset in [-PI/3, -PI/6, 0, PI/6, PI/3]:
			var test_angle: float = direction.angle() + angle_offset if direction != Vector2.ZERO else rng.randf() * TAU
			var test_dir: Vector2 = Vector2.from_angle(test_angle)
			var test_pos: Vector2 = current + test_dir * segment_length
			var test_height: float = _get_base_terrain_height(test_pos.x, test_pos.y)

			# Prefer lower terrain with slight randomness
			test_height += rng.randf_range(-1.0, 1.0)

			# Strongly penalize directions toward spawn
			if test_pos.length() < spawn_exclusion_radius:
				test_height += 100.0  # Make this direction very unattractive

			if test_height < lowest_height:
				lowest_height = test_height
				best_dir = test_dir

		if best_dir == Vector2.ZERO:
			best_dir = Vector2.from_angle(rng.randf() * TAU)

		# Add perpendicular offset for natural curves
		var perp: Vector2 = Vector2(-best_dir.y, best_dir.x)
		var curve_offset: float = rng.randf_range(-5.0, 5.0)

		var next_pos: Vector2 = current + best_dir * segment_length + perp * curve_offset

		# Don't enter spawn exclusion zone
		if next_pos.length() < spawn_exclusion_radius:
			continue

		# Don't get too close to water bodies (ponds/lakes)
		var near_water: bool = false
		for body in water_bodies:
			if next_pos.distance_to(body["center"]) < body["radius"] + 15.0:
				near_water = true
				break
		if near_water:
			continue

		path.append(next_pos)
		direction = (next_pos - current).normalized()
		current = next_pos

		# Stop if we've reached MEADOW
		var region: RegionType = get_region_at(current.x, current.y)
		if region == RegionType.MEADOW and path.size() >= 4:
			break

	return path


func _place_fishing_pools(river_path: Array[Vector2]) -> Array[Vector2]:
	## Place fishing pools along the river path at regular intervals
	var pools: Array[Vector2] = []
	var accumulated_distance: float = 0.0

	for i in range(1, river_path.size()):
		var segment_length: float = river_path[i].distance_to(river_path[i - 1])
		accumulated_distance += segment_length

		if accumulated_distance >= river_fishing_pool_spacing:
			pools.append(river_path[i])
			accumulated_distance = 0.0

	return pools


func _has_carved_neighbor(x: float, z: float, threshold: float) -> bool:
	## Check if at least one cardinal neighbor would also be carved (path_noise > threshold)
	## This prevents isolated pits that players could get stuck in
	var offsets: Array[Vector2] = [
		Vector2(cell_size, 0),   # East
		Vector2(-cell_size, 0),  # West
		Vector2(0, cell_size),   # South
		Vector2(0, -cell_size)   # North
	]

	for offset in offsets:
		var neighbor_path: float = path_noise.get_noise_2d(x + offset.x, z + offset.y)
		if neighbor_path > threshold:
			return true

	return false


func _get_base_terrain_height(x: float, z: float) -> float:
	## Get terrain height without water body modifications (for river path finding)
	var region: RegionType = get_region_at(x, z)
	var params: Dictionary = region_height_params[region]
	var region_height_scale: float = params["scale"]

	var raw_height: float = noise.get_noise_2d(x, z)
	var height: float = (raw_height + 1.0) * 0.5 * region_height_scale

	if region == RegionType.HILLS:
		var detail: float = detail_noise.get_noise_2d(x, z)
		height += detail * 3.0

	return height


func _update_legacy_pond_locations() -> void:
	## Update pond_locations array for backward compatibility with existing code
	pond_locations.clear()
	for body in water_bodies:
		if body["type"] == WaterBodyType.POND or body["type"] == WaterBodyType.LAKE:
			pond_locations.append(body["center"])


func _count_water_bodies(body_type: WaterBodyType) -> int:
	var count: int = 0
	for body in water_bodies:
		if body["type"] == body_type:
			count += 1
	return count


func _setup_material() -> void:
	terrain_material = StandardMaterial3D.new()
	terrain_material.vertex_color_use_as_albedo = true
	terrain_material.albedo_color = Color.WHITE
	terrain_material.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT
	terrain_material.roughness = 1.0
	terrain_material.metallic = 0.0
	terrain_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	# Add pixelated texture atlas
	var texture_atlas: ImageTexture = TerrainTextures.get_texture_atlas()
	if texture_atlas:
		terrain_material.albedo_texture = texture_atlas
		# CRITICAL: Use nearest-neighbor filtering for crisp pixelated look
		terrain_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		# Texture modulates with vertex color (preserves region tinting + AO)
		terrain_material.albedo_color = Color.WHITE


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
	ore_scene = load("res://scenes/resources/ore_node.tscn")

	if not tree_scene:
		push_warning("[ChunkManager] Failed to load tree scene")


func get_terrain_material() -> StandardMaterial3D:
	return terrain_material


func get_region_at(x: float, z: float) -> RegionType:
	## Determines the region type at a given world position using low-frequency noise
	## Always FOREST near spawn point for consistent starting experience
	var spawn_distance: float = Vector2(x, z).length()
	if spawn_distance < 60.0:
		return RegionType.FOREST

	var value: float = region_noise.get_noise_2d(x, z)
	if value < -0.3:
		return RegionType.MEADOW
	elif value < 0.2:
		return RegionType.FOREST
	elif value < 0.5:
		return RegionType.HILLS
	else:
		return RegionType.ROCKY


func get_region_colors(region: RegionType) -> Dictionary:
	## Returns grass and dirt colors for the specified region
	return region_colors[region]


func get_vegetation_multiplier(region: RegionType, resource_type: String) -> float:
	## Returns the vegetation spawn multiplier for a resource type in a region
	return region_vegetation[region].get(resource_type, 1.0)


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

	# Check all water bodies (ponds and lakes) for terrain depression
	for body in water_bodies:
		var body_center: Vector2 = body["center"]
		var body_radius: float = body["radius"]
		var body_depth: float = body["depth"]

		var distance_from_body: float = Vector2(snapped_x - body_center.x, snapped_z - body_center.y).length()
		if distance_from_body < body_radius:
			var pond_factor: float = distance_from_body / body_radius
			var pond_floor_y: float = -body_depth  # Deep enough for swimming
			# Pond floor is deep, edges ramp up to normal terrain
			if pond_factor < 0.7:
				return pond_floor_y  # Flat pond floor (deep)
			else:
				# Gradual slope from pond floor to terrain edge
				var edge_factor: float = (pond_factor - 0.7) / 0.3
				return pond_floor_y + (height_step - pond_floor_y) * edge_factor

	# Check rivers for terrain depression
	for river in rivers:
		var river_info: Dictionary = _get_river_info_at(snapped_x, snapped_z, river)
		if river_info["in_river"]:
			var dist_from_center: float = river_info["distance"]
			var width: float = river_info["width"]
			var half_width: float = width / 2.0

			# River cross-section profile
			# 0-40% width: flat floor at depth
			# 40-100% width: linear slope to terrain edge
			var floor_y: float = -river_depth

			if dist_from_center < half_width * 0.4:
				return floor_y  # Flat river floor
			else:
				# Gradual slope from river floor to edge
				var slope_start: float = half_width * 0.4
				var slope_factor: float = (dist_from_center - slope_start) / (half_width - slope_start)
				slope_factor = clamp(slope_factor, 0.0, 1.0)
				return floor_y + (height_step - floor_y) * slope_factor

	# Get region type for this position to determine height parameters
	var region: RegionType = get_region_at(snapped_x, snapped_z)
	var params: Dictionary = region_height_params[region]
	var region_height_scale: float = params["scale"]
	var region_height_step: float = params["step"]

	# Base terrain height from noise (sampled at cell center)
	var raw_height: float = noise.get_noise_2d(snapped_x, snapped_z)
	var height: float = (raw_height + 1.0) * 0.5 * region_height_scale

	# Special terrain generation for HILLS - dramatic with climbable paths
	if region == RegionType.HILLS:
		# Large-scale hill shapes - creates peaks and valleys with high variation
		var hill_shape: float = hill_noise.get_noise_2d(snapped_x, snapped_z)
		# Transform to 0-1 range, then apply power curve for more dramatic peaks
		hill_shape = (hill_shape + 1.0) * 0.5
		hill_shape = pow(hill_shape, 1.5)  # Emphasize peaks
		height = hill_shape * region_height_scale

		# Add detail variation for interesting surface
		var detail: float = detail_noise.get_noise_2d(snapped_x, snapped_z)
		height += detail * 4.0  # Up to 4 units of detail variation

		# Carve climbing paths using path noise
		# Path noise creates winding valleys that cut through steep terrain
		var path_value: float = path_noise.get_noise_2d(snapped_x, snapped_z)
		var path_threshold: float = 0.2

		# Only carve if at least one neighbor would also be carved (prevents isolated pits)
		if path_value > path_threshold:
			var has_carved_neighbor: bool = _has_carved_neighbor(snapped_x, snapped_z, path_threshold)
			if has_carved_neighbor:
				var path_strength: float = (path_value - path_threshold) / (1.0 - path_threshold)
				# Reduce height in path areas - creates climbing routes
				var path_reduction: float = path_strength * height * 0.6
				height -= path_reduction

		# Ensure minimum height in hills
		height = max(2.0, height)

	# Special terrain generation for ROCKY - jagged cliffs with some paths
	elif region == RegionType.ROCKY:
		# Base rocky terrain
		var rocky_base: float = hill_noise.get_noise_2d(snapped_x * 1.5, snapped_z * 1.5)
		rocky_base = (rocky_base + 1.0) * 0.5
		height = rocky_base * region_height_scale

		# Add jagged detail
		var detail: float = detail_noise.get_noise_2d(snapped_x * 2.0, snapped_z * 2.0)
		height += detail * 3.0

		# Carve some paths through rocky terrain (less frequent than hills)
		var path_value: float = path_noise.get_noise_2d(snapped_x, snapped_z)
		var rocky_path_threshold: float = 0.4

		# Only carve if at least one neighbor would also be carved (prevents isolated pits)
		if path_value > rocky_path_threshold:
			var has_carved_neighbor: bool = _has_carved_neighbor(snapped_x, snapped_z, rocky_path_threshold)
			if has_carved_neighbor:
				var path_strength: float = (path_value - rocky_path_threshold) / (1.0 - rocky_path_threshold)
				height -= path_strength * height * 0.4

		height = max(1.0, height)

	# Quantize to blocky steps (using region-specific step size)
	height = floor(height / region_height_step) * region_height_step
	height = max(region_height_step, height)

	# Gradual transition from campsite (uses snapped distance)
	if distance_from_center < flatten_radius + flatten_falloff:
		var t: float = (distance_from_center - flatten_radius) / flatten_falloff
		t = clamp(t, 0.0, 1.0)
		t = floor(t * 4.0) / 4.0
		height *= t

	return height


func _get_river_info_at(x: float, z: float, river: Dictionary) -> Dictionary:
	## Get information about whether a point is in a river and how far from center
	var pos: Vector2 = Vector2(x, z)
	var path: Array = river["path"]
	var base_width: float = river["width"]
	var fishing_pools: Array = river["fishing_pools"]

	var min_dist: float = INF
	var effective_width: float = base_width

	# Check distance to each segment
	for i in range(path.size() - 1):
		var a: Vector2 = path[i]
		var b: Vector2 = path[i + 1]
		var dist: float = _point_to_segment_distance(pos, a, b)

		if dist < min_dist:
			min_dist = dist

			# Check if near a fishing pool (wider section)
			for pool_pos in fishing_pools:
				if pos.distance_to(pool_pos) < river_fishing_pool_spacing * 0.5:
					effective_width = river_fishing_pool_width
					break

	var in_river: bool = min_dist < effective_width / 2.0

	return {
		"in_river": in_river,
		"distance": min_dist,
		"width": effective_width
	}


func _point_to_segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	## Calculate the minimum distance from point p to line segment ab
	var ab: Vector2 = b - a
	var ap: Vector2 = p - a

	var ab_len_sq: float = ab.length_squared()
	if ab_len_sq == 0:
		return ap.length()

	# Project p onto the line, clamped to segment
	var t: float = clamp(ap.dot(ab) / ab_len_sq, 0.0, 1.0)
	var closest: Vector2 = a + ab * t

	return p.distance_to(closest)


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

	# Spawn fishing spots for any water bodies in this chunk
	var chunk_world_size: float = chunk_size_cells * cell_size
	var chunk_min_x: float = chunk_coord.x * chunk_world_size
	var chunk_max_x: float = chunk_min_x + chunk_world_size
	var chunk_min_z: float = chunk_coord.y * chunk_world_size
	var chunk_max_z: float = chunk_min_z + chunk_world_size

	# Spawn ponds and lakes
	for body_idx in range(water_bodies.size()):
		if body_idx in spawned_pond_indices:
			continue
		var body_center: Vector2 = water_bodies[body_idx]["center"]
		if body_center.x >= chunk_min_x and body_center.x < chunk_max_x and \
		   body_center.y >= chunk_min_z and body_center.y < chunk_max_z:
			_spawn_fishing_spot(body_idx)

	# Spawn river segments and fishing pools in this chunk
	_spawn_river_features_in_chunk(chunk_coord, chunk_min_x, chunk_max_x, chunk_min_z, chunk_max_z)


func _unload_chunk(chunk_coord: Vector2i) -> void:
	if not loaded_chunks.has(chunk_coord):
		return

	var chunk: TerrainChunk = loaded_chunks[chunk_coord]
	chunk.unload()
	loaded_chunks.erase(chunk_coord)


func _spawn_fishing_spot(body_idx: int) -> void:
	if not fishing_spot_scene or body_idx in spawned_pond_indices:
		return

	if body_idx >= water_bodies.size():
		return

	var body: Dictionary = water_bodies[body_idx]
	var body_center: Vector2 = body["center"]
	var body_radius: float = body["radius"]
	var body_type: WaterBodyType = body["type"]

	var fishing_spot: Node3D = fishing_spot_scene.instantiate()
	var type_name: String = "Pond" if body_type == WaterBodyType.POND else "Lake"
	fishing_spot.name = "%s_%d" % [type_name, body_idx]

	# Position water to fill the terrain depression
	var pond_y: float = 0.0
	fishing_spot.position = Vector3(body_center.x, pond_y, body_center.y)

	if "pond_width" in fishing_spot:
		# Water should fill the terrain depression edge-to-edge
		# Terrain reaches water level at about 93% of radius
		var water_diameter: float = body_radius * 2.0 * 0.95
		fishing_spot.pond_width = water_diameter
		fishing_spot.pond_depth = water_diameter

		# Lakes have more fish
		if body_type == WaterBodyType.LAKE:
			fishing_spot.fish_count = 8
		else:
			fishing_spot.fish_count = 5

	add_child(fishing_spot)
	spawned_pond_indices.append(body_idx)
	print("[ChunkManager] Spawned %s %d at (%.1f, %.1f) radius=%.1f" % [
		type_name.to_lower(), body_idx, body_center.x, body_center.y, body_radius
	])


func get_distance_to_nearest_pond(world_x: float, world_z: float) -> float:
	## Returns the distance from a world position to the nearest pond/lake edge
	var min_distance: float = INF
	for body in water_bodies:
		var center: Vector2 = body["center"]
		var radius: float = body["radius"]
		var dist_to_center: float = Vector2(world_x - center.x, world_z - center.y).length()
		var dist_to_edge: float = dist_to_center - radius
		if dist_to_edge < min_distance:
			min_distance = dist_to_edge
	return min_distance


func get_nearest_water_body(world_x: float, world_z: float) -> Dictionary:
	## Returns the nearest water body (pond/lake) with distance info
	var nearest: Dictionary = {}
	var min_distance: float = INF

	for body in water_bodies:
		var center: Vector2 = body["center"]
		var radius: float = body["radius"]
		var dist_to_center: float = Vector2(world_x - center.x, world_z - center.y).length()
		var dist_to_edge: float = dist_to_center - radius

		if dist_to_edge < min_distance:
			min_distance = dist_to_edge
			nearest = body.duplicate()
			nearest["distance_to_edge"] = dist_to_edge
			nearest["distance_to_center"] = dist_to_center

	return nearest


func is_in_water(world_x: float, world_z: float, buffer: float = 2.0) -> bool:
	## Returns true if the position is within any water body (including buffer)
	## Checks ponds, lakes, and rivers

	# Check ponds and lakes
	for body in water_bodies:
		var center: Vector2 = body["center"]
		var radius: float = body["radius"]
		var dist: float = Vector2(world_x - center.x, world_z - center.y).length()
		if dist < radius + buffer:
			return true

	# Check rivers
	for river in rivers:
		var river_info: Dictionary = _get_river_info_at(world_x, world_z, river)
		if river_info["distance"] < river_info["width"] / 2.0 + buffer:
			return true

	return false


func is_near_any_pond(world_x: float, world_z: float, buffer: float = 2.0) -> bool:
	## Legacy function - now calls is_in_water for backward compatibility
	return is_in_water(world_x, world_z, buffer)


func _spawn_river_features_in_chunk(chunk_coord: Vector2i, min_x: float, max_x: float, min_z: float, max_z: float) -> void:
	## Spawn entire rivers when any part enters a loaded chunk
	for river_idx in range(rivers.size()):
		if river_idx in spawned_river_indices:
			continue

		var river: Dictionary = rivers[river_idx]
		var path: Array = river["path"]
		var fishing_pools: Array = river["fishing_pools"]

		# Check if any part of river is in this chunk
		var river_in_chunk: bool = false
		for i in range(path.size() - 1):
			var start: Vector2 = path[i]
			var end: Vector2 = path[i + 1]
			if _segment_intersects_rect(start, end, min_x, max_x, min_z, max_z):
				river_in_chunk = true
				break

		# Also check if any waypoint is in chunk
		if not river_in_chunk:
			for waypoint in path:
				if waypoint.x >= min_x and waypoint.x < max_x and \
				   waypoint.y >= min_z and waypoint.y < max_z:
					river_in_chunk = true
					break

		if river_in_chunk:
			# Spawn the entire river as one continuous mesh
			_spawn_entire_river(river_idx, river)
			spawned_river_indices.append(river_idx)

			# Spawn all fishing pools for this river
			for pool_pos in fishing_pools:
				if not pool_pos in spawned_river_fishing_pools:
					_spawn_river_fishing_pool(pool_pos)
					spawned_river_fishing_pools.append(pool_pos)


func _segment_intersects_rect(start: Vector2, end: Vector2, min_x: float, max_x: float, min_z: float, max_z: float) -> bool:
	## Check if a line segment intersects or is contained within a rectangle
	# If either endpoint is in the rect, it intersects
	if start.x >= min_x and start.x <= max_x and start.y >= min_z and start.y <= max_z:
		return true
	if end.x >= min_x and end.x <= max_x and end.y >= min_z and end.y <= max_z:
		return true

	# Check if segment crosses any edge of the rectangle
	var corners: Array[Vector2] = [
		Vector2(min_x, min_z), Vector2(max_x, min_z),
		Vector2(max_x, max_z), Vector2(min_x, max_z)
	]

	for i in range(4):
		var c1: Vector2 = corners[i]
		var c2: Vector2 = corners[(i + 1) % 4]
		if _segments_intersect(start, end, c1, c2):
			return true

	return false


func _segments_intersect(p1: Vector2, p2: Vector2, p3: Vector2, p4: Vector2) -> bool:
	## Check if two line segments intersect
	var d1: float = _cross_product_2d(p4 - p3, p1 - p3)
	var d2: float = _cross_product_2d(p4 - p3, p2 - p3)
	var d3: float = _cross_product_2d(p2 - p1, p3 - p1)
	var d4: float = _cross_product_2d(p2 - p1, p4 - p1)

	if ((d1 > 0 and d2 < 0) or (d1 < 0 and d2 > 0)) and \
	   ((d3 > 0 and d4 < 0) or (d3 < 0 and d4 > 0)):
		return true
	return false


func _cross_product_2d(a: Vector2, b: Vector2) -> float:
	return a.x * b.y - a.y * b.x


func _spawn_entire_river(river_idx: int, river: Dictionary) -> void:
	## Spawn an entire river as one continuous mesh
	var path: Array = river["path"]
	var width: float = river["width"]

	if path.size() < 2:
		return

	var river_root: Node3D = Node3D.new()
	river_root.name = "River_%d" % river_idx

	# Create the water mesh using SurfaceTool
	var water_mesh: MeshInstance3D = MeshInstance3D.new()
	water_mesh.name = "WaterMesh"

	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var water_y: float = 0.05
	var half_width: float = width / 2.0
	var water_color: Color = Color(0.2, 0.45, 0.6, 0.7)
	var normal: Vector3 = Vector3.UP

	# Calculate edge vertices for each waypoint
	var left_edges: Array[Vector3] = []
	var right_edges: Array[Vector3] = []

	for i in range(path.size()):
		var current: Vector2 = path[i]
		var direction: Vector2

		if i == 0:
			# First point - use direction to next point
			direction = (path[1] - path[0]).normalized()
		elif i == path.size() - 1:
			# Last point - use direction from previous point
			direction = (path[i] - path[i - 1]).normalized()
		else:
			# Middle points - average direction from prev and to next
			var dir_in: Vector2 = (path[i] - path[i - 1]).normalized()
			var dir_out: Vector2 = (path[i + 1] - path[i]).normalized()
			direction = ((dir_in + dir_out) / 2.0).normalized()

		var perpendicular: Vector2 = Vector2(-direction.y, direction.x)
		var left: Vector2 = current + perpendicular * half_width
		var right: Vector2 = current - perpendicular * half_width

		left_edges.append(Vector3(left.x, water_y, left.y))
		right_edges.append(Vector3(right.x, water_y, right.y))

	# Create quads between consecutive edge pairs
	for i in range(path.size() - 1):
		var v0: Vector3 = left_edges[i]      # Start left
		var v1: Vector3 = right_edges[i]     # Start right
		var v2: Vector3 = right_edges[i + 1] # End right
		var v3: Vector3 = left_edges[i + 1]  # End left

		# Triangle 1: v0, v1, v2
		st.set_color(water_color)
		st.set_normal(normal)
		st.add_vertex(v0)
		st.set_color(water_color)
		st.set_normal(normal)
		st.add_vertex(v1)
		st.set_color(water_color)
		st.set_normal(normal)
		st.add_vertex(v2)

		# Triangle 2: v0, v2, v3
		st.set_color(water_color)
		st.set_normal(normal)
		st.add_vertex(v0)
		st.set_color(water_color)
		st.set_normal(normal)
		st.add_vertex(v2)
		st.set_color(water_color)
		st.set_normal(normal)
		st.add_vertex(v3)

	water_mesh.mesh = st.commit()

	# Semi-transparent water material
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.1
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	water_mesh.material_override = mat

	river_root.add_child(water_mesh)

	# Create water areas for swimming detection along the river
	for i in range(path.size() - 1):
		var start: Vector2 = path[i]
		var end: Vector2 = path[i + 1]
		var center: Vector2 = (start + end) / 2.0
		var length: float = start.distance_to(end)
		var direction: Vector2 = (end - start).normalized()
		var angle: float = atan2(direction.x, direction.y)

		var water_area: Area3D = Area3D.new()
		water_area.name = "WaterArea_%d" % i

		var area_shape: CollisionShape3D = CollisionShape3D.new()
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(width + 1.0, river_depth + 1.0, length + 2.0)
		area_shape.shape = box
		area_shape.position = Vector3(center.x, -river_depth / 2.0, center.y)
		area_shape.rotation.y = angle
		water_area.add_child(area_shape)

		water_area.body_entered.connect(_on_river_body_entered)
		water_area.body_exited.connect(_on_river_body_exited)

		river_root.add_child(water_area)

	add_child(river_root)
	print("[ChunkManager] Spawned river %d mesh with %d segments" % [river_idx, path.size() - 1])


func _spawn_river_fishing_pool(pool_pos: Vector2) -> void:
	## Spawn a fishing spot at a river fishing pool
	if not fishing_spot_scene:
		return

	var fishing_spot: Node3D = fishing_spot_scene.instantiate()
	fishing_spot.name = "RiverPool_%.0f_%.0f" % [pool_pos.x, pool_pos.y]

	fishing_spot.position = Vector3(pool_pos.x, 0.0, pool_pos.y)

	if "pond_width" in fishing_spot:
		fishing_spot.pond_width = river_fishing_pool_width
		fishing_spot.pond_depth = river_fishing_pool_width
		fishing_spot.fish_count = 3

	add_child(fishing_spot)
	print("[ChunkManager] Spawned river fishing pool at (%.1f, %.1f)" % [pool_pos.x, pool_pos.y])


func _on_river_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if body.has_method("set_in_water"):
			body.set_in_water(true)


func _on_river_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		if body.has_method("set_in_water"):
			body.set_in_water(false)


# Debug info
func print_water_locations() -> void:
	## Debug function to print all water feature locations
	print("\n=== WATER FEATURES ===")
	print("Ponds and Lakes:")
	for i in range(water_bodies.size()):
		var body: Dictionary = water_bodies[i]
		var type_name: String = "POND" if body["type"] == WaterBodyType.POND else "LAKE"
		print("  %d. %s at (%.0f, %.0f) radius=%.0f" % [
			i, type_name, body["center"].x, body["center"].y, body["radius"]
		])

	print("\nRivers:")
	for i in range(rivers.size()):
		var river: Dictionary = rivers[i]
		var path: Array = river["path"]
		if path.size() >= 2:
			var start: Vector2 = path[0]
			var end: Vector2 = path[path.size() - 1]
			print("  %d. Start (%.0f, %.0f) -> End (%.0f, %.0f), %d waypoints" % [
				i, start.x, start.y, end.x, end.y, path.size()
			])
			print("     Waypoints: ", path)
	print("======================\n")


func get_loaded_chunk_count() -> int:
	return loaded_chunks.size()


func get_pending_load_count() -> int:
	return chunks_to_load.size()


func get_pending_unload_count() -> int:
	return chunks_to_unload.size()


## Remove trees and resources that overlap with player structures.
## Called after loading a saved game to clean up items that spawned before structures were loaded.
func remove_trees_overlapping_structures() -> void:
	var campsite_mgr: Node = get_node_or_null("/root/Main/CampsiteManager")
	if not campsite_mgr or not campsite_mgr.has_method("get_placed_structures"):
		return

	var structures: Array = campsite_mgr.get_placed_structures()
	if structures.is_empty():
		return

	var trees_removed: int = 0
	var resources_removed: int = 0

	# Iterate through all loaded chunks
	for chunk_coord: Vector2i in loaded_chunks.keys():
		var chunk: TerrainChunk = loaded_chunks[chunk_coord]
		if not chunk:
			continue

		# Check each tree in this chunk
		var trees_to_remove: Array[Node3D] = []
		for tree: Node3D in chunk.spawned_trees:
			if not is_instance_valid(tree):
				continue

			var tree_pos: Vector3 = tree.global_position
			var tree_pos_2d: Vector2 = Vector2(tree_pos.x, tree_pos.z)

			# Check against all structures
			for structure: Node in structures:
				if not is_instance_valid(structure):
					continue

				var struct_pos: Vector3 = structure.global_position
				var struct_pos_2d: Vector2 = Vector2(struct_pos.x, struct_pos.z)

				# Get structure's footprint radius
				var footprint: float = 1.0
				if "structure_type" in structure:
					footprint = StructureData.get_footprint_radius(structure.structure_type)

				# Tree radius for overlap check
				var tree_radius: float = 1.5
				var min_distance: float = footprint + tree_radius

				if tree_pos_2d.distance_to(struct_pos_2d) < min_distance:
					trees_to_remove.append(tree)
					break  # No need to check other structures

		# Remove overlapping trees
		for tree: Node3D in trees_to_remove:
			chunk.spawned_trees.erase(tree)
			tree.queue_free()
			trees_removed += 1

		# Check each resource (mushrooms, herbs, berries, etc.) in this chunk
		var resources_to_remove: Array[Node3D] = []
		for resource: Node3D in chunk.spawned_resources:
			if not is_instance_valid(resource):
				continue

			var res_pos: Vector3 = resource.global_position
			var res_pos_2d: Vector2 = Vector2(res_pos.x, res_pos.z)

			# Check against all structures
			for structure: Node in structures:
				if not is_instance_valid(structure):
					continue

				var struct_pos: Vector3 = structure.global_position
				var struct_pos_2d: Vector2 = Vector2(struct_pos.x, struct_pos.z)

				# Get structure's footprint radius
				var footprint: float = 1.0
				if "structure_type" in structure:
					footprint = StructureData.get_footprint_radius(structure.structure_type)

				# Small resource radius for overlap check
				var resource_radius: float = 0.5
				var min_distance: float = footprint + resource_radius

				if res_pos_2d.distance_to(struct_pos_2d) < min_distance:
					resources_to_remove.append(resource)
					break  # No need to check other structures

		# Remove overlapping resources
		for resource: Node3D in resources_to_remove:
			chunk.spawned_resources.erase(resource)
			resource.queue_free()
			resources_removed += 1

	if trees_removed > 0 or resources_removed > 0:
		print("[ChunkManager] Removed %d trees and %d resources overlapping with structures" % [trees_removed, resources_removed])


## Check if a position overlaps with any player structure.
## Used to prevent trees from spawning on top of structures.
func is_position_blocked_by_structure(x: float, z: float, radius: float = 1.5) -> bool:
	var campsite_mgr: Node = get_node_or_null("/root/Main/CampsiteManager")
	if not campsite_mgr or not campsite_mgr.has_method("get_placed_structures"):
		return false

	var structures: Array = campsite_mgr.get_placed_structures()
	var pos_2d: Vector2 = Vector2(x, z)

	for structure: Node in structures:
		if not is_instance_valid(structure):
			continue

		var struct_pos: Vector3 = structure.global_position
		var struct_pos_2d: Vector2 = Vector2(struct_pos.x, struct_pos.z)

		# Get structure's footprint radius
		var footprint: float = 1.0
		if "structure_type" in structure:
			footprint = StructureData.get_footprint_radius(structure.structure_type)

		# Check if tree would overlap with structure
		var distance: float = pos_2d.distance_to(struct_pos_2d)
		var min_distance: float = footprint + radius

		if distance < min_distance:
			return true

	return false
