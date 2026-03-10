extends Node3D
class_name ChunkManager
## Manages dynamic loading/unloading of terrain chunks around the player.

# Region types for terrain variety
enum RegionType { MEADOW, FOREST, HILLS, ROCKY, MOUNTAIN, DESERT }

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
@export var tree_density: float = 0.30  # Increased to compensate for larger grid
@export var tree_min_distance: float = 14.0
@export var tree_grid_size: float = 3.5  # Increased from 2.5 - fewer checks, better performance

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

# Cave entrance settings
# Each: {center: Vector2, cave_id: int, cave_type: String}
var cave_entrances: Array[Dictionary] = []
var cave_count: int = 2  # Target number of cave entrances (reduced for performance)
var cave_min_spacing: float = 100.0  # Min distance between caves (must exceed 2x ramp radius)
var cave_spawn_min_distance: float = 85.0  # Min distance from spawn

# Desert oasis settings
var desert_oases: Array[Dictionary] = []  # {center: Vector2, gem_type: String, gem_count: int, radius: float, depth: float}
var desert_inner_radius: float = 300.0
var desert_outer_radius: float = 360.0
var spawned_oasis_indices: Array[int] = []  # Track which oases have been spawned

# Desert sinkhole (hidden easter egg in pocket desert west of spawn)
var desert_sinkhole: Dictionary = {}
var sinkhole_spawned: bool = false
var sinkhole_book_collected: bool = false
var sinkhole_book_script: GDScript = null  # Loaded later when script exists

# Pocket desert biome (hidden area containing sinkhole, west of spawn)
var pocket_desert_center: Vector2 = Vector2(-600.0, 0.0)
var pocket_desert_radius: float = 50.0
var pocket_desert_blend: float = 15.0  # Transition zone width
var rock_spire_spawned: bool = false
var rock_spire_position: Vector2 = Vector2.ZERO  # Computed in _ready

# Trail home landmarks
var carved_tree_script: GDScript
var stone_cairn_script: GDScript
var trail_signpost_script: GDScript

var carved_tree_spawned: bool = false
var stone_cairn_spawned: bool = false
var trail_signpost_spawned: bool = false

# Pre-computed positions (set in _ready)
var carved_tree_position: Vector2 = Vector2.ZERO
var stone_cairn_position: Vector2 = Vector2.ZERO
var trail_signpost_position: Vector2 = Vector2.ZERO

# Region-specific pond sizes {radius_min, radius_max, depth}
var region_pond_params: Dictionary = {
	RegionType.MEADOW: {"radius_min": 10.0, "radius_max": 14.0, "depth": 2.5},
	RegionType.FOREST: {"radius_min": 6.0, "radius_max": 10.0, "depth": 2.5},
	RegionType.HILLS: {"radius_min": 5.0, "radius_max": 8.0, "depth": 3.0},
	RegionType.ROCKY: {"radius_min": 4.0, "radius_max": 6.0, "depth": 3.5},
	RegionType.MOUNTAIN: {"radius_min": 8.0, "radius_max": 12.0, "depth": 4.0}
}

# Alpine lake settings (high elevation lakes in MOUNTAIN region)
var alpine_lake_count: int = 2  # Target number of alpine lakes
var alpine_lake_min_radius: float = 12.0
var alpine_lake_max_radius: float = 18.0
var alpine_lake_depth: float = 4.0
var alpine_lake_min_elevation: float = 30.0  # Minimum terrain height for alpine lakes
var alpine_lake_min_spacing: float = 60.0  # Min distance between alpine lakes

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
	},
	RegionType.MOUNTAIN: {
		"grass": Color(0.38, 0.45, 0.35),  # Alpine grey-green
		"dirt": Color(0.42, 0.40, 0.38)     # Mountain grey
	},
	RegionType.DESERT: {
		"grass": Color(0.84, 0.75, 0.45),  # Warm yellow-brown sand
		"dirt": Color(0.72, 0.60, 0.35)     # Deeper brown sand
	},
}

# Region-specific height parameters
var region_height_params: Dictionary = {
	RegionType.MEADOW: {"scale": 2.0, "step": 0.5},   # Gentle rolling terrain
	RegionType.FOREST: {"scale": 5.0, "step": 1.0},   # Current default
	RegionType.HILLS: {"scale": 22.0, "step": 1.0},   # Dramatic hills with jumpable steps
	RegionType.ROCKY: {"scale": 12.0, "step": 1.0},   # Jagged cliffs with jumpable steps
	RegionType.MOUNTAIN: {"scale": 24.0, "step": 1.0}, # Tall peaks with stable geometry
	RegionType.DESERT: {"scale": 4.0, "step": 0.5},  # Gentle rolling dunes
}

# Region-specific vegetation multipliers
var region_vegetation: Dictionary = {
	RegionType.MEADOW: {"tree": 0.1, "rock": 0.3, "berry": 2.0, "herb": 2.0, "osha": 0.0},
	RegionType.FOREST: {"tree": 1.5, "rock": 1.0, "berry": 1.0, "herb": 1.0, "osha": 0.0},
	RegionType.HILLS: {"tree": 0.6, "rock": 1.5, "berry": 0.8, "herb": 0.8, "osha": 0.5},
	RegionType.ROCKY: {"tree": 0.2, "rock": 5.0, "berry": 0.2, "herb": 0.2, "osha": 0.3},
	RegionType.MOUNTAIN: {"tree": 0.8, "rock": 3.0, "berry": 0.3, "herb": 0.5, "osha": 2.0},
	RegionType.DESERT: {"tree": 0.0, "rock": 0.3, "berry": 0.0, "herb": 0.0, "osha": 0.0, "cactus": 1.0, "palm": 0.3},
}

# Noise generators
var noise: FastNoiseLite
var forest_noise: FastNoiseLite
var region_noise: FastNoiseLite  # Low-frequency noise for region determination
var detail_noise: FastNoiseLite  # Higher-frequency detail for hills
var hill_noise: FastNoiseLite    # Large-scale hill shapes
var path_noise: FastNoiseLite    # Creates valleys/paths through hills for climbing
var pine_grove_noise: FastNoiseLite  # Clustering for ponderosa pine groves
var noise_seed: int = 0
var noise_seed_set: bool = false  # True if seed was set externally (e.g., from save file)

# Tree scenes
var tree_scene: PackedScene
var big_tree_scene: PackedScene
var birch_tree_scene: PackedScene
var ponderosa_pine_scene: PackedScene

# Resource scenes
var branch_scene: PackedScene
var rock_scene: PackedScene
var berry_bush_scene: PackedScene
var mushroom_scene: PackedScene
var herb_scene: PackedScene
var ore_scene: PackedScene
var osha_root_scene: PackedScene
var coca_leaf_scene: PackedScene

# Resource spawning settings
@export var branch_density: float = 0.08  # Branches per grid cell chance
@export var rock_density: float = 0.03
@export var berry_density: float = 0.03
@export var mushroom_density: float = 0.025
@export var herb_density: float = 0.025

# Fishing spots (one per pond/lake)
var fishing_spot_scene: PackedScene
var spawned_pond_indices: Array[int] = []  # Track which water bodies have fishing spots

# River segments tracking
var river_segment_scene: PackedScene
var spawned_river_indices: Array[int] = []  # Track which rivers have been fully spawned
var spawned_river_fishing_pools: Array[Vector2] = []  # Track spawned river fishing pools

# Cave entrance tracking
var cave_entrance_script: GDScript
var spawned_cave_indices: Array[int] = []  # Track which cave entrances have been spawned

# Wilderness sign
var wilderness_sign_script: GDScript
var wilderness_sign_spawned: bool = false

# Resource manager reference (for registering chunk-spawned trees)
var resource_manager: ResourceManager

# Tree sway manager reference
var tree_sway: TreeSway

# Shared material for all chunks
var terrain_material: StandardMaterial3D

# Chunk tracking
signal heavy_generation_slot_available

var loaded_chunks: Dictionary = {}  # Vector2i -> TerrainChunk

# Concurrency limiting - prevents coroutine accumulation across chunks
const MAX_CONCURRENT_HEAVY_GENERATIONS: int = 2
var _active_heavy_generations: int = 0
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
	_generate_cave_entrances()
	_generate_desert_oases()
	_generate_desert_sinkhole()
	_setup_material()
	_setup_world_floor()
	_load_scenes()

	# Find resource manager (ResourceManager is a sibling of World, which is our parent)
	var main_node: Node = get_parent().get_parent()  # World -> Main
	if main_node:
		resource_manager = main_node.get_node_or_null("ResourceManager") as ResourceManager
		tree_sway = main_node.get_node_or_null("TreeSway") as TreeSway

	# Find player node
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_parent().get_node_or_null("Player")

	if player:
		# Debug: teleport player to a trail landmark for testing
		var game_state: Node = get_node_or_null("/root/GameState")
		if game_state and game_state.get("debug_spawn_at_landmark") != null:
			var landmark: String = game_state.debug_spawn_at_landmark
			var target_pos: Vector2 = Vector2.ZERO
			if landmark == "carved_tree" and carved_tree_position != Vector2.ZERO:
				target_pos = carved_tree_position
			elif landmark == "stone_cairn" and stone_cairn_position != Vector2.ZERO:
				target_pos = stone_cairn_position
			elif landmark == "signpost" and trail_signpost_position != Vector2.ZERO:
				target_pos = trail_signpost_position
			if target_pos != Vector2.ZERO:
				player.global_position = Vector3(target_pos.x, 25.0, target_pos.y)
				print("[ChunkManager] Debug: spawned player at '%s' (%.0f, %.0f)" % [landmark, target_pos.x, target_pos.y])
		# Initial chunk loading around player
		_update_chunks_around_player()
	else:
		push_warning("[ChunkManager] No player found, loading chunks around origin")
		last_player_chunk = Vector2i(0, 0)
		_load_chunks_around(Vector2i(0, 0))


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
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

	# Region noise - very low frequency for large distinct regions (~250 units across)
	region_noise = FastNoiseLite.new()
	region_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	region_noise.seed = noise_seed + 1500
	region_noise.frequency = 0.004
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

	# Pine grove noise - creates clustering for ponderosa pine stands
	pine_grove_noise = FastNoiseLite.new()
	pine_grove_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	pine_grove_noise.seed = noise_seed + 5500
	pine_grove_noise.frequency = 0.05  # Medium frequency for grove-sized clusters
	pine_grove_noise.fractal_octaves = 2


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
	_generate_alpine_lakes()
	_generate_rivers()

	# Update legacy pond_locations for backward compatibility
	_update_legacy_pond_locations()

	print("[ChunkManager] Water features generated: %d ponds, %d lakes (incl. alpine), %d rivers" % [
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


func _generate_alpine_lakes() -> void:
	## Generate high-elevation lakes in MOUNTAIN regions
	var alpine_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	alpine_rng.seed = noise_seed + 1888

	var world_extent: float = 180.0  # Larger extent for mountain regions
	var attempts: int = 0
	var max_attempts: int = alpine_lake_count * 150
	var alpine_lakes_generated: int = 0

	while alpine_lakes_generated < alpine_lake_count and attempts < max_attempts:
		attempts += 1

		# Generate random position (far from spawn where mountains are)
		var candidate: Vector2 = Vector2(
			alpine_rng.randf_range(-world_extent, world_extent),
			alpine_rng.randf_range(-world_extent, world_extent)
		)

		# Alpine lakes must be far from spawn
		if candidate.length() < 100.0:
			continue

		# Must be in MOUNTAIN region
		var region: RegionType = get_region_at(candidate.x, candidate.y)
		if region != RegionType.MOUNTAIN:
			continue

		# Check distance from existing water bodies
		var too_close: bool = false
		for body in water_bodies:
			var required_spacing: float = alpine_lake_min_spacing if body["type"] == WaterBodyType.LAKE else 40.0
			if candidate.distance_to(body["center"]) < required_spacing + body["radius"]:
				too_close = true
				break

		if too_close:
			continue

		var alpine_radius: float = alpine_rng.randf_range(alpine_lake_min_radius, alpine_lake_max_radius)

		water_bodies.append({
			"type": WaterBodyType.LAKE,
			"center": candidate,
			"radius": alpine_radius,
			"depth": alpine_lake_depth,
			"is_alpine": true  # Mark as alpine lake
		})

		alpine_lakes_generated += 1
		print("[ChunkManager] Generated alpine lake at (%.1f, %.1f) radius=%.1f" % [
			candidate.x, candidate.y, alpine_radius
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

		# Smooth the path to eliminate sharp corners
		river_path = _smooth_river_path(river_path)

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
	var max_segments: int = 20
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

		# Don't get too close to cave entrances
		var near_cave: bool = false
		for cave in cave_entrances:
			if next_pos.distance_to(cave["center"]) < 20.0:
				near_cave = true
				break
		if near_cave:
			continue

		path.append(next_pos)
		direction = (next_pos - current).normalized()
		current = next_pos

		# Stop if we've reached MEADOW
		var region: RegionType = get_region_at(current.x, current.y)
		if region == RegionType.MEADOW and path.size() >= 8:
			break

	return path


func _smooth_river_path(path: Array[Vector2]) -> Array[Vector2]:
	## Smooth a river path using Catmull-Rom spline interpolation
	## This creates gentle curves instead of sharp corners
	if path.size() < 3:
		return path

	var smoothed: Array[Vector2] = []
	var subdivisions: int = 8  # More subdivisions for smoother curves

	for i in range(path.size() - 1):
		# Get 4 control points for Catmull-Rom (p0, p1, p2, p3)
		var p0: Vector2 = path[max(0, i - 1)]
		var p1: Vector2 = path[i]
		var p2: Vector2 = path[min(path.size() - 1, i + 1)]
		var p3: Vector2 = path[min(path.size() - 1, i + 2)]

		# Add the start point
		smoothed.append(p1)

		# Add interpolated points
		for j in range(1, subdivisions):
			var t: float = float(j) / float(subdivisions)
			var point: Vector2 = _catmull_rom(p0, p1, p2, p3, t)
			smoothed.append(point)

	# Add the final point
	smoothed.append(path[path.size() - 1])

	return smoothed


func _catmull_rom(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	## Catmull-Rom spline interpolation between p1 and p2
	var t2: float = t * t
	var t3: float = t2 * t

	var x: float = 0.5 * (
		(2.0 * p1.x) +
		(-p0.x + p2.x) * t +
		(2.0 * p0.x - 5.0 * p1.x + 4.0 * p2.x - p3.x) * t2 +
		(-p0.x + 3.0 * p1.x - 3.0 * p2.x + p3.x) * t3
	)

	var y: float = 0.5 * (
		(2.0 * p1.y) +
		(-p0.y + p2.y) * t +
		(2.0 * p0.y - 5.0 * p1.y + 4.0 * p2.y - p3.y) * t2 +
		(-p0.y + 3.0 * p1.y - 3.0 * p2.y + p3.y) * t3
	)

	return Vector2(x, y)


func _place_fishing_pools(river_path: Array[Vector2]) -> Array[Vector2]:
	## Place one fishing pool near the middle of the river
	var pools: Array[Vector2] = []
	if river_path.size() < 2:
		return pools

	var mid_index: int = river_path.size() / 2
	pools.append(river_path[mid_index])
	return pools


func _generate_cave_entrances() -> void:
	## Generate cave entrances in ROCKY regions
	cave_entrances.clear()

	var cave_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	cave_rng.seed = noise_seed + 2222

	var world_extent: float = 140.0
	var attempts: int = 0
	var max_attempts: int = cave_count * 150
	var caves_generated: int = 0

	# Cave types with distribution
	var cave_types: Array[String] = ["small", "small", "medium", "medium"]

	while caves_generated < cave_count and attempts < max_attempts:
		attempts += 1

		# Generate random position
		var candidate: Vector2 = Vector2(
			cave_rng.randf_range(-world_extent, world_extent),
			cave_rng.randf_range(-world_extent, world_extent)
		)

		# Must be very far from spawn
		if candidate.length() < cave_spawn_min_distance:
			continue

		# Caves in ROCKY or HILLS regions (terrain flattening makes them walkable)
		var region: RegionType = get_region_at(candidate.x, candidate.y)
		if region != RegionType.ROCKY and region != RegionType.HILLS:
			continue

		# Check distance from existing caves
		var too_close: bool = false
		for existing in cave_entrances:
			if candidate.distance_to(existing["center"]) < cave_min_spacing:
				too_close = true
				break

		if too_close:
			continue

		# Check distance from water bodies
		for body in water_bodies:
			if candidate.distance_to(body["center"]) < body["radius"] + 20.0:
				too_close = true
				break

		if too_close:
			continue

		# Check distance from rivers
		for river in rivers:
			var river_path: Array = river["path"]
			for seg_i in range(1, river_path.size()):
				if _point_to_segment_distance(candidate, river_path[seg_i - 1], river_path[seg_i]) < 20.0:
					too_close = true
					break
			if too_close:
				break

		if too_close:
			continue

		var cave_type: String = cave_types[caves_generated % cave_types.size()]

		# Snap cave center to nearest cell_size grid so all cave geometry
		# aligns with terrain cell boundaries, eliminating terrain gaps.
		var snapped_x: float = roundf(candidate.x / cell_size) * cell_size
		var snapped_z: float = roundf(candidate.y / cell_size) * cell_size
		var snapped_center := Vector2(snapped_x, snapped_z)

		cave_entrances.append({
			"center": snapped_center,
			"cave_id": caves_generated,
			"cave_type": cave_type
		})

		caves_generated += 1
		print("[ChunkManager] Generated %s cave #%d at (%.0f, %.0f)" % [
			cave_type, caves_generated, candidate.x, candidate.y
		])


func _generate_desert_oases() -> void:
	## Place 3 oases ~120 degrees apart in the desert ring (~200 units from spawn)
	desert_oases.clear()

	var oasis_distance: float = 330.0  # Distance from spawn (centered in desert ring)
	var oasis_configs: Array[Dictionary] = [
		{"angle_deg": 0.0, "gem_type": "diamond", "gem_count": 3},
		{"angle_deg": 120.0, "gem_type": "diamond", "gem_count": 2},
		{"angle_deg": 240.0, "gem_type": "opal", "gem_count": 3},
	]

	for config: Dictionary in oasis_configs:
		var angle_rad: float = deg_to_rad(config["angle_deg"])
		var raw_x: float = cos(angle_rad) * oasis_distance
		var raw_z: float = sin(angle_rad) * oasis_distance

		# Snap to cell_size grid (multiples of 3.0)
		var snapped_x: float = roundf(raw_x / cell_size) * cell_size
		var snapped_z: float = roundf(raw_z / cell_size) * cell_size

		var oasis_data: Dictionary = {
			"center": Vector2(snapped_x, snapped_z),
			"gem_type": config["gem_type"],
			"gem_count": config["gem_count"],
			"radius": 6.0,
			"depth": 4.0
		}
		desert_oases.append(oasis_data)

		# Also add oasis as a water body so terrain gets depressed
		# Mark index as spawned so no fishing spot is created on top of the oasis
		var oasis_wb_idx: int = water_bodies.size()
		water_bodies.append({
			"type": WaterBodyType.POND,
			"center": Vector2(snapped_x, snapped_z),
			"radius": 6.0,
			"depth": 4.0
		})
		spawned_pond_indices.append(oasis_wb_idx)

		print("[ChunkManager] Generated desert oasis #%d (%s) at (%.0f, %.0f)" % [
			desert_oases.size(), config["gem_type"], snapped_x, snapped_z
		])

	# Generate desert river leading to the opal oasis (index 2)
	_generate_desert_river()

	# Update legacy pond_locations
	_update_legacy_pond_locations()

	print("[ChunkManager] Desert oases generated: %d oases" % desert_oases.size())


func _generate_desert_river() -> void:
	## Generate a river segment in the desert ring that leads to the opal oasis (index 2)
	if desert_oases.size() < 3:
		return

	var opal_center: Vector2 = desert_oases[2]["center"]

	# River starts ~60 units away from the opal oasis in the desert ring
	# Direction: from further out in the desert ring toward the oasis
	var to_spawn: Vector2 = -opal_center.normalized()  # Direction toward spawn
	var river_start_offset: Vector2 = to_spawn.rotated(deg_to_rad(45.0)) * 60.0
	var river_start: Vector2 = opal_center + river_start_offset

	# Snap start to grid
	river_start.x = roundf(river_start.x / cell_size) * cell_size
	river_start.y = roundf(river_start.y / cell_size) * cell_size

	# Build a simple path from start to oasis center with some curves
	var river_path: Array[Vector2] = []
	var segments: int = 8
	for i: int in range(segments + 1):
		var t: float = float(i) / float(segments)
		var pos: Vector2 = river_start.lerp(opal_center, t)
		# Add perpendicular offset for natural curves (sinusoidal)
		var perp: Vector2 = (opal_center - river_start).normalized().rotated(PI / 2.0)
		var curve_amount: float = sin(t * PI * 2.0) * 8.0
		pos += perp * curve_amount
		river_path.append(pos)

	# Smooth the path
	river_path = _smooth_river_path(river_path)

	# Place fishing pool near the middle
	var fishing_pools: Array[Vector2] = _place_fishing_pools(river_path)

	rivers.append({
		"path": river_path,
		"width": river_base_width,
		"fishing_pools": fishing_pools
	})

	print("[ChunkManager] Generated desert river toward opal oasis: start (%.0f, %.0f) -> end (%.0f, %.0f), %d segments" % [
		river_start.x, river_start.y, opal_center.x, opal_center.y, river_path.size()
	])


func is_near_oasis(world_x: float, world_z: float, buffer: float = 2.0) -> bool:
	## Check if a world position is near any desert oasis (for tree/resource exclusion)
	for oasis: Dictionary in desert_oases:
		var center: Vector2 = oasis["center"]
		var radius: float = oasis["radius"]
		var dist: float = Vector2(world_x - center.x, world_z - center.y).length()
		if dist < radius + buffer:
			return true
	return false


func _generate_desert_sinkhole() -> void:
	## Place the hidden sinkhole at the center of the pocket desert
	var raw_x: float = pocket_desert_center.x
	var raw_z: float = pocket_desert_center.y

	# Snap to cell_size grid (multiples of 3.0)
	var snapped_x: float = roundf(raw_x / cell_size) * cell_size
	var snapped_z: float = roundf(raw_z / cell_size) * cell_size

	desert_sinkhole = {
		"center": Vector2(snapped_x, snapped_z),
		"radius": 5.0,
		"depth": 45.0
	}

	# Register as a water body (type POND) for terrain carving
	var sink_wb_idx: int = water_bodies.size()
	water_bodies.append({
		"type": WaterBodyType.POND,
		"center": Vector2(snapped_x, snapped_z),
		"radius": 5.0,
		"depth": 45.0
	})
	# Prevent fishing spots from spawning on the sinkhole
	spawned_pond_indices.append(sink_wb_idx)

	# Update legacy pond_locations
	_update_legacy_pond_locations()

	# Pre-compute rock spire position (used by multiple systems)
	rock_spire_position = Vector2(
		roundf((pocket_desert_center.x + pocket_desert_radius - 5.0) / cell_size) * cell_size,
		roundf(pocket_desert_center.y / cell_size) * cell_size
	)

	print("[ChunkManager] Generated desert sinkhole at (%.0f, %.0f) in pocket desert" % [snapped_x, snapped_z])

	# Trail home landmark positions (far-out, with slight seed-based variation)
	var trail_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	trail_rng.seed = noise_seed + 7777

	carved_tree_position = Vector2(
		roundf((trail_rng.randf_range(-20, 20)) / cell_size) * cell_size,
		roundf((-430.0 + trail_rng.randf_range(-15, 15)) / cell_size) * cell_size
	)
	stone_cairn_position = Vector2(
		roundf((410.0 + trail_rng.randf_range(-20, 20)) / cell_size) * cell_size + cell_size / 2.0,
		roundf((-410.0 + trail_rng.randf_range(-15, 15)) / cell_size) * cell_size + cell_size / 2.0
	)
	trail_signpost_position = Vector2(
		roundf((480.0 + trail_rng.randf_range(-15, 15)) / cell_size) * cell_size,
		roundf((-480.0 + trail_rng.randf_range(-15, 15)) / cell_size) * cell_size
	)

	print("[ChunkManager] Trail landmarks: tree=(%.0f,%.0f) cairn=(%.0f,%.0f) signpost=(%.0f,%.0f)" % [
		carved_tree_position.x, carved_tree_position.y,
		stone_cairn_position.x, stone_cairn_position.y,
		trail_signpost_position.x, trail_signpost_position.y
	])


func is_near_sinkhole(world_x: float, world_z: float, buffer: float = 12.0) -> bool:
	## Check if a world position is near the desert sinkhole or rock spire (for vegetation suppression)
	if desert_sinkhole.size() == 0:
		return false
	var dist: float = Vector2(world_x - desert_sinkhole["center"].x, world_z - desert_sinkhole["center"].y).length()
	if dist < desert_sinkhole["radius"] + buffer:
		return true
	# Also suppress vegetation near rock spire
	var spire_dist: float = Vector2(world_x - rock_spire_position.x, world_z - rock_spire_position.y).length()
	return spire_dist < 6.0


func is_near_trail_landmark(world_x: float, world_z: float) -> bool:
	## Returns true if position is within clearing radius of any trail landmark.
	var clear_radius: float = 6.0
	if carved_tree_position != Vector2.ZERO:
		var dist: float = Vector2(world_x - carved_tree_position.x, world_z - carved_tree_position.y).length()
		if dist < clear_radius:
			return true
	if stone_cairn_position != Vector2.ZERO:
		var dist: float = Vector2(world_x - stone_cairn_position.x, world_z - stone_cairn_position.y).length()
		if dist < clear_radius:
			return true
	if trail_signpost_position != Vector2.ZERO:
		var dist: float = Vector2(world_x - trail_signpost_position.x, world_z - trail_signpost_position.y).length()
		if dist < clear_radius:
			return true
	return false


func _spawn_sinkhole_contents() -> void:
	## Spawn the glow light and water area at the bottom of the sinkhole
	if sinkhole_spawned or desert_sinkhole.size() == 0:
		return

	var center: Vector2 = desert_sinkhole["center"]
	var sinkhole_radius: float = desert_sinkhole["radius"]
	var depth: float = desert_sinkhole["depth"]

	# Bottom glow light (hint to the player)
	var glow: OmniLight3D = OmniLight3D.new()
	glow.name = "SinkholeGlow"
	glow.light_color = Color(0.3, 0.7, 0.6)
	glow.light_energy = 1.5
	glow.omni_range = 8.0
	glow.shadow_enabled = false
	glow.position = Vector3(center.x, -depth + 2.0, center.y)
	add_child(glow)

	# Water surface visual at ground level (y=0)
	var water_mesh: MeshInstance3D = MeshInstance3D.new()
	water_mesh.name = "SinkholeWaterSurface"
	var box_mesh: BoxMesh = BoxMesh.new()
	# Cover the sinkhole opening plus the 3-unit ramp zone
	box_mesh.size = Vector3((sinkhole_radius + 3.5) * 2.0, 0.15, (sinkhole_radius + 3.5) * 2.0)
	water_mesh.mesh = box_mesh

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.1, 0.35, 0.5, 0.7)
	mat.roughness = 0.05
	mat.metallic = 0.1
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	water_mesh.material_override = mat
	water_mesh.position = Vector3(center.x, 0.0, center.y)
	add_child(water_mesh)

	# Deeper water center (darker patch)
	var deep_mesh: MeshInstance3D = MeshInstance3D.new()
	deep_mesh.name = "SinkholeDeepWater"
	var deep_box: BoxMesh = BoxMesh.new()
	deep_box.size = Vector3(sinkhole_radius * 2.0, 0.12, sinkhole_radius * 2.0)
	deep_mesh.mesh = deep_box

	var deep_mat: StandardMaterial3D = StandardMaterial3D.new()
	deep_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	deep_mat.albedo_color = Color(0.05, 0.2, 0.35, 0.5)
	deep_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	deep_mesh.material_override = deep_mat
	deep_mesh.position = Vector3(center.x, -0.15, center.y)
	add_child(deep_mesh)

	# Water Area3D for swimming detection - matches oasis pattern
	var water_area: Area3D = Area3D.new()
	water_area.name = "SinkholeWaterArea"
	water_area.collision_layer = 0
	water_area.collision_mask = 1  # Player is on layer 1

	var area_shape: CollisionShape3D = CollisionShape3D.new()
	var area_box: BoxShape3D = BoxShape3D.new()
	# Match the water volume - extends from surface down to sinkhole floor
	area_box.size = Vector3((sinkhole_radius + 3.5) * 2.0 + 1.0, depth + 1.0, (sinkhole_radius + 3.5) * 2.0 + 1.0)
	area_shape.shape = area_box
	# Position: surface at y=0, extends down to sinkhole floor
	area_shape.position = Vector3(center.x, -depth / 2.0, center.y)
	water_area.add_child(area_shape)

	# Connect signals for swimming detection
	water_area.body_entered.connect(_on_sinkhole_water_entered)
	water_area.body_exited.connect(_on_sinkhole_water_exited)

	add_child(water_area)

	# Coca leaf plant near sinkhole rim
	if coca_leaf_scene:
		var leaf_offset: Vector2 = Vector2(10.0, 0.0)  # East of sinkhole (beyond 8-unit carving zone)
		var leaf_x: float = center.x + leaf_offset.x
		var leaf_z: float = center.y + leaf_offset.y
		# Snap to cell grid
		leaf_x = roundf(leaf_x / cell_size) * cell_size + cell_size / 2.0
		leaf_z = roundf(leaf_z / cell_size) * cell_size + cell_size / 2.0
		var leaf_y: float = get_height_at(leaf_x, leaf_z)
		var coca_node: Node3D = coca_leaf_scene.instantiate()
		coca_node.name = "SinkholeCocaLeaf"
		coca_node.position = Vector3(leaf_x, leaf_y, leaf_z)
		add_child(coca_node)

	# Spawn the Explorer's Journal on pedestal at sinkhole bottom (only if not already collected)
	if sinkhole_book_script and not sinkhole_book_collected:
		var book_node: StaticBody3D = StaticBody3D.new()
		book_node.set_script(sinkhole_book_script)
		book_node.name = "ExplorersJournal"
		book_node.position = Vector3(center.x, -depth + 0.5, center.y)
		add_child(book_node)

	sinkhole_spawned = true
	print("[ChunkManager] Spawned sinkhole contents at (%.0f, %.0f)" % [center.x, center.y])


func _spawn_rock_spire() -> void:
	## Spawn a tall rock spire at the eastern edge of the pocket desert as a landmark
	if rock_spire_spawned:
		return

	# Use pre-computed position at eastern edge of pocket desert
	var spire_x: float = rock_spire_position.x
	var spire_z: float = rock_spire_position.y
	var spire_y: float = get_height_at(spire_x, spire_z)

	var spire_root: Node3D = Node3D.new()
	spire_root.name = "RockSpire"
	spire_root.position = Vector3(spire_x, spire_y, spire_z)

	# Base block - wide and heavy
	var base: MeshInstance3D = MeshInstance3D.new()
	var base_mesh: BoxMesh = BoxMesh.new()
	base_mesh.size = Vector3(3.0, 3.0, 3.0)
	base.mesh = base_mesh
	var base_mat: StandardMaterial3D = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.55, 0.45, 0.32)  # Warm sandstone
	base_mat.roughness = 0.9
	base.material_override = base_mat
	base.position = Vector3(0.0, 1.5, 0.0)
	spire_root.add_child(base)

	# Middle section - narrower, slightly offset
	var mid: MeshInstance3D = MeshInstance3D.new()
	var mid_mesh: BoxMesh = BoxMesh.new()
	mid_mesh.size = Vector3(2.2, 3.5, 2.2)
	mid.mesh = mid_mesh
	var mid_mat: StandardMaterial3D = StandardMaterial3D.new()
	mid_mat.albedo_color = Color(0.50, 0.40, 0.28)  # Slightly darker
	mid_mat.roughness = 0.9
	mid.material_override = mid_mat
	mid.position = Vector3(0.3, 4.75, -0.2)
	spire_root.add_child(mid)

	# Upper section - narrower still
	var upper: MeshInstance3D = MeshInstance3D.new()
	var upper_mesh: BoxMesh = BoxMesh.new()
	upper_mesh.size = Vector3(1.5, 2.5, 1.5)
	upper.mesh = upper_mesh
	var upper_mat: StandardMaterial3D = StandardMaterial3D.new()
	upper_mat.albedo_color = Color(0.60, 0.48, 0.33)  # Lighter weathered top
	upper_mat.roughness = 0.85
	upper.material_override = upper_mat
	upper.position = Vector3(-0.2, 7.75, 0.15)
	spire_root.add_child(upper)

	# Cap - small angled top piece
	var cap: MeshInstance3D = MeshInstance3D.new()
	var cap_mesh: BoxMesh = BoxMesh.new()
	cap_mesh.size = Vector3(1.0, 1.2, 1.0)
	cap.mesh = cap_mesh
	var cap_mat: StandardMaterial3D = StandardMaterial3D.new()
	cap_mat.albedo_color = Color(0.65, 0.52, 0.36)  # Lightest - sun-bleached
	cap_mat.roughness = 0.8
	cap.material_override = cap_mat
	cap.position = Vector3(0.1, 9.6, -0.1)
	cap.rotation_degrees = Vector3(5.0, 15.0, -8.0)  # Slight tilt for character
	spire_root.add_child(cap)

	add_child(spire_root)
	rock_spire_spawned = true
	print("[ChunkManager] Spawned rock spire landmark at (%.0f, %.0f)" % [spire_x, spire_z])


func _on_sinkhole_water_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		# Set water surface Y to the sinkhole's terrain-level surface
		if "water_surface_y" in body and desert_sinkhole.size() > 0:
			var sink_center: Vector2 = desert_sinkhole["center"]
			body.water_surface_y = get_height_at(sink_center.x + desert_sinkhole["radius"] + 4.0, sink_center.y)
		if body.has_method("set_in_water"):
			body.set_in_water(true)
		print("[ChunkManager] Player entered sinkhole water")


func _on_sinkhole_water_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		# Reset water surface Y to default pond level
		if "water_surface_y" in body:
			body.water_surface_y = 0.15
		if body.has_method("set_in_water"):
			body.set_in_water(false)
		print("[ChunkManager] Player exited sinkhole water")


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


## Pit prevention: guard flag to prevent recursion when checking neighbor heights
var _in_pit_check: bool = false

## Cached neighbor heights for height limiting (bounded to prevent unbounded growth)
var _height_limit_cache: Dictionary = {}
const HEIGHT_CACHE_MAX_SIZE: int = 2048


func _limit_height_difference(x: float, z: float, height: float, max_diff: float) -> float:
	## Limit height difference between this cell and its neighbors to max_diff units.
	## This prevents single-cell cliffs that cause collision issues.
	## Returns the adjusted height.

	# Create cache key for this position
	var cache_key: String = "%d_%d" % [int(floor(x / cell_size)), int(floor(z / cell_size))]

	# If we've already calculated this position, return cached result
	if _height_limit_cache.has(cache_key):
		return _height_limit_cache[cache_key]

	# Get raw heights of cardinal neighbors (without limiting, to avoid recursion)
	var neighbor_offsets: Array[Vector2] = [
		Vector2(cell_size, 0),   # East
		Vector2(-cell_size, 0),  # West
		Vector2(0, cell_size),   # South
		Vector2(0, -cell_size)   # North
	]

	var min_neighbor_height: float = INF
	for offset in neighbor_offsets:
		var nx: float = x + offset.x
		var nz: float = z + offset.y
		var neighbor_height: float = _get_raw_mountain_height(nx, nz)
		if neighbor_height < min_neighbor_height:
			min_neighbor_height = neighbor_height

	# If lowest neighbor is more than max_diff below us, limit our height
	if min_neighbor_height != INF and height - min_neighbor_height > max_diff:
		height = min_neighbor_height + max_diff

	# Cache the result (clear if too large to prevent unbounded memory growth)
	if _height_limit_cache.size() >= HEIGHT_CACHE_MAX_SIZE:
		_height_limit_cache.clear()
	_height_limit_cache[cache_key] = height
	return height


func _get_raw_mountain_height(x: float, z: float) -> float:
	## Get the raw mountain height without height limiting (to avoid recursion).
	## This is a simplified version of the MOUNTAIN case in get_height_at.
	var snapped_x: float = (floor(x / cell_size) + 0.5) * cell_size
	var snapped_z: float = (floor(z / cell_size) + 0.5) * cell_size

	var region: RegionType = get_region_at(snapped_x, snapped_z)
	if region != RegionType.MOUNTAIN:
		# For non-mountain regions, use a high value so it doesn't constrain mountains
		return INF

	var params: Dictionary = region_height_params[region]
	var region_height_scale: float = params["scale"]

	# Large-scale mountain shapes
	var mountain_shape: float = hill_noise.get_noise_2d(snapped_x * 0.6, snapped_z * 0.6)
	mountain_shape = (mountain_shape + 1.0) * 0.5
	mountain_shape = pow(mountain_shape, 1.5)
	var height: float = mountain_shape * region_height_scale

	# Add ridges and detail
	var ridge: float = hill_noise.get_noise_2d(snapped_x * 1.0, snapped_z * 1.0)
	ridge = (ridge + 1.0) * 0.5
	height += ridge * 2.0

	var detail: float = detail_noise.get_noise_2d(snapped_x * 1.5, snapped_z * 1.5)
	height += detail * 1.0

	# Apply path carving (only if neighbor also carved, matching get_height_at logic)
	var path_value: float = path_noise.get_noise_2d(snapped_x, snapped_z)
	var mountain_path_threshold: float = 0.25
	if path_value > mountain_path_threshold:
		var has_carved_neighbor: bool = _has_carved_neighbor(snapped_x, snapped_z, mountain_path_threshold)
		if has_carved_neighbor:
			var path_strength: float = (path_value - mountain_path_threshold) / (1.0 - mountain_path_threshold)
			var path_reduction: float = path_strength * height * 0.55
			height -= path_reduction

	# Minimum height
	height = max(4.0, height)

	return height


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
	terrain_material.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
	terrain_material.roughness = 1.0
	terrain_material.metallic = 0.0
	terrain_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	terrain_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

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
	ponderosa_pine_scene = load("res://scenes/resources/ponderosa_pine_resource.tscn")
	fishing_spot_scene = load("res://scenes/resources/fishing_spot.tscn")

	# Load resource scenes
	branch_scene = load("res://scenes/resources/branch.tscn")
	rock_scene = load("res://scenes/resources/rock.tscn")
	berry_bush_scene = load("res://scenes/resources/berry_bush.tscn")
	mushroom_scene = load("res://scenes/resources/mushroom.tscn")
	herb_scene = load("res://scenes/resources/herb.tscn")
	ore_scene = load("res://scenes/resources/ore_node.tscn")
	osha_root_scene = load("res://scenes/resources/osha_root.tscn")
	coca_leaf_scene = load("res://scenes/resources/coca_leaf.tscn")

	# Load cave entrance script
	cave_entrance_script = load("res://scripts/world/cave_entrance.gd")

	# Load wilderness sign script
	wilderness_sign_script = load("res://scripts/world/wilderness_sign.gd")

	# Load explorer's journal pickup script (sinkhole easter egg)
	sinkhole_book_script = load("res://scripts/world/explorers_journal_pickup.gd")

	# Load trail home landmark scripts
	carved_tree_script = load("res://scripts/world/trail_carved_tree.gd")
	stone_cairn_script = load("res://scripts/world/trail_stone_cairn.gd")
	trail_signpost_script = load("res://scripts/world/trail_signpost.gd")

	if not tree_scene:
		push_warning("[ChunkManager] Failed to load tree scene")
	if not ponderosa_pine_scene:
		push_warning("[ChunkManager] Failed to load ponderosa pine scene")
	if not osha_root_scene:
		push_warning("[ChunkManager] Failed to load osha root scene")


func get_terrain_material() -> StandardMaterial3D:
	return terrain_material


func get_region_at(x: float, z: float) -> RegionType:
	## Determines the region type at a given world position using low-frequency noise
	## Always FOREST near spawn point for consistent starting experience
	var spawn_distance: float = Vector2(x, z).length()
	if spawn_distance < 60.0:
		return RegionType.FOREST

	# Pocket desert biome (hidden area west of spawn containing sinkhole)
	var pocket_dist: float = Vector2(x - pocket_desert_center.x, z - pocket_desert_center.y).length()
	var pocket_angle: float = atan2(z - pocket_desert_center.y, x - pocket_desert_center.x)
	var pocket_boundary: float = pocket_desert_radius + _desert_boundary_offset(pocket_angle)
	if pocket_dist <= pocket_boundary:
		return RegionType.DESERT

	# Desert ring with organic noise-based boundaries
	var desert_angle: float = atan2(z, x)
	var inner_offset: float = _desert_boundary_offset(desert_angle)
	var outer_offset: float = _desert_boundary_offset(desert_angle + 1.0)
	var desert_inner: float = 300.0 + inner_offset
	var desert_outer: float = 360.0 + outer_offset
	if spawn_distance >= desert_inner and spawn_distance <= desert_outer:
		return RegionType.DESERT

	var value: float = region_noise.get_noise_2d(x, z)

	# MOUNTAIN regions appear at extreme high noise values AND far from spawn
	# This creates distant mountain peaks that players can explore
	if value > 0.6 and spawn_distance > 100.0:
		return RegionType.MOUNTAIN

	if value < -0.3:
		return RegionType.MEADOW
	elif value < 0.2:
		return RegionType.FOREST
	elif value < 0.5:
		return RegionType.HILLS
	else:
		return RegionType.ROCKY


## Returns a noise-based offset for the desert ring boundary at a given angle.
## Uses multiple sine frequencies for organic variation (max ~±19 units).
func _desert_boundary_offset(angle: float) -> float:
	return sin(angle * 3.0) * 10.0 + sin(angle * 7.0 + 1.5) * 6.0 + sin(angle * 13.0 + 3.0) * 3.0


## Returns the desert inner and outer radii at a given world position.
## Used by terrain_chunk.gd for transition blending.
func get_desert_boundaries(x: float, z: float) -> Vector2:
	var angle: float = atan2(z, x)
	var inner: float = 300.0 + _desert_boundary_offset(angle)
	var outer: float = 360.0 + _desert_boundary_offset(angle + 1.0)
	return Vector2(inner, outer)


## Returns a blend factor (0.0 to 1.0) for the pocket desert transition zone.
## 0.0 = fully outside (no desert blend), 1.0 = fully inside pocket desert.
## Used by terrain_chunk.gd for smooth color transitions.
func get_pocket_desert_blend(x: float, z: float) -> float:
	var pocket_dist: float = Vector2(x - pocket_desert_center.x, z - pocket_desert_center.y).length()
	var pocket_angle: float = atan2(z - pocket_desert_center.y, x - pocket_desert_center.x)
	var pocket_boundary: float = pocket_desert_radius + _desert_boundary_offset(pocket_angle)
	if pocket_dist <= pocket_boundary:
		return 1.0  # Fully inside pocket desert
	elif pocket_dist <= pocket_boundary + pocket_desert_blend:
		return 1.0 - (pocket_dist - pocket_boundary) / pocket_desert_blend
	return 0.0  # Outside blend zone


func get_region_colors(region: RegionType) -> Dictionary:
	## Returns grass and dirt colors for the specified region
	return region_colors[region]


func get_vegetation_multiplier(region: RegionType, resource_type: String) -> float:
	## Returns the vegetation spawn multiplier for a resource type in a region
	return region_vegetation[region].get(resource_type, 1.0)


func get_height_at(x: float, z: float, skip_pit_check: bool = false) -> float:
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

	# Flatten terrain around cave entrances for walkable approach (covers full cave depth)
	var cave_flat_inner: float = 16.0  # Flat platform radius
	var cave_flat_outer: float = 46.0  # Ramp falloff radius (wide enough for gradual climb)
	var cave_platform_height: float = 2.0  # Low walkable platform height
	var cave_max_slope: float = 0.67  # Max height per world unit (2.0 per cell) - ensures climbability

	for cave in cave_entrances:
		var cave_center: Vector2 = cave["center"]
		var dist_to_cave: float = Vector2(snapped_x - cave_center.x, snapped_z - cave_center.y).length()
		if dist_to_cave < cave_flat_inner:
			return cave_platform_height
		elif dist_to_cave < cave_flat_outer:
			continue  # In falloff zone for this cave - still check other caves for flat zone

	# Oasis pool depressions - flat floor with gradual ramp beyond edge
	for oasis: Dictionary in desert_oases:
		var oasis_dist: float = Vector2(snapped_x - oasis["center"].x, snapped_z - oasis["center"].y).length()
		if oasis_dist < oasis["radius"]:
			# Pool floor - completely flat across the entire pool
			return -oasis["depth"]
		elif oasis_dist < oasis["radius"] + 3.0:
			# Ramp from pool edge to terrain
			var blend_factor: float = (oasis_dist - oasis["radius"]) / 3.0
			return lerpf(-oasis["depth"], height_step, blend_factor)

	# Sinkhole depression - deep pit with climbable rim
	# Zones: pit floor (0-5) -> ramp to surface (5-8) -> flat rim at y=0 (8-12) -> handled later as ramp to terrain
	if desert_sinkhole.size() > 0:
		var sink_center: Vector2 = Vector2(desert_sinkhole["center"].x, desert_sinkhole["center"].y)
		var sink_dist: float = Vector2(snapped_x - sink_center.x, snapped_z - sink_center.y).length()
		var sink_radius: float = desert_sinkhole["radius"]
		var sink_rim_end: float = sink_radius + 7.0  # Flat rim extends 4 units beyond ramp
		if sink_dist < sink_radius:
			return -desert_sinkhole["depth"]
		elif sink_dist < sink_radius + 3.0:
			# Ramp from pit floor to water surface (y=0)
			var blend_factor: float = (sink_dist - sink_radius) / 3.0
			return lerpf(-desert_sinkhole["depth"], 0.0, blend_factor)
		elif sink_dist < sink_rim_end:
			# Flat rim at water level - player can stand here after exiting water
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

	# Special terrain generation for MOUNTAIN - tall peaks with stable geometry
	elif region == RegionType.MOUNTAIN:
		# Large-scale mountain shapes using hill noise
		var mountain_shape: float = hill_noise.get_noise_2d(snapped_x * 0.6, snapped_z * 0.6)
		# Transform to 0-1 range, then apply power curve for peaks
		mountain_shape = (mountain_shape + 1.0) * 0.5
		mountain_shape = pow(mountain_shape, 1.5)
		height = mountain_shape * region_height_scale

		# Add medium-scale ridges (reduced for stability)
		var ridge: float = hill_noise.get_noise_2d(snapped_x * 1.0, snapped_z * 1.0)
		ridge = (ridge + 1.0) * 0.5
		height += ridge * 2.0

		# Add detail variation for rocky surface (reduced)
		var detail: float = detail_noise.get_noise_2d(snapped_x * 1.5, snapped_z * 1.5)
		height += detail * 1.0

		# Carve climbing paths through mountains
		var path_value: float = path_noise.get_noise_2d(snapped_x, snapped_z)
		var mountain_path_threshold: float = 0.25

		if path_value > mountain_path_threshold:
			var has_carved_neighbor: bool = _has_carved_neighbor(snapped_x, snapped_z, mountain_path_threshold)
			if has_carved_neighbor:
				var path_strength: float = (path_value - mountain_path_threshold) / (1.0 - mountain_path_threshold)
				var path_reduction: float = path_strength * height * 0.55
				height -= path_reduction

		# Ensure mountains have minimum height
		height = max(4.0, height)

		# Limit height differences between adjacent cells to prevent single-cell cliffs
		# Max 8 units difference keeps terrain climbable while preserving dramatic multi-cell cliffs
		height = _limit_height_difference(snapped_x, snapped_z, height, 8.0)

	# Quantize to blocky steps (using region-specific step size)
	height = floor(height / region_height_step) * region_height_step
	height = max(region_height_step, height)

	# Gradual transition from campsite (uses snapped distance)
	if distance_from_center < flatten_radius + flatten_falloff:
		var t: float = (distance_from_center - flatten_radius) / flatten_falloff
		t = clamp(t, 0.0, 1.0)
		t = floor(t * 4.0) / 4.0
		height *= t

	# Gradual ramp from cave platform to natural terrain
	for cave in cave_entrances:
		var cave_center: Vector2 = cave["center"]
		var dist_to_cave: float = Vector2(snapped_x - cave_center.x, snapped_z - cave_center.y).length()
		if dist_to_cave >= cave_flat_inner and dist_to_cave < cave_flat_outer:
			var t: float = (dist_to_cave - cave_flat_inner) / (cave_flat_outer - cave_flat_inner)
			t = clamp(t, 0.0, 1.0)
			# Smooth-step curve: gentle start near cave (climbable), steeper toward natural terrain
			t = t * t * (3.0 - 2.0 * t)
			var ramp_height: float = cave_platform_height + (height - cave_platform_height) * t
			# Cap gradient to prevent unclimbable cliffs around cave platform
			var max_height_at_dist: float = cave_platform_height + (dist_to_cave - cave_flat_inner) * cave_max_slope
			height = min(ramp_height, max_height_at_dist)

	# Gradual ramp from sinkhole rim (y=0) to natural terrain
	if desert_sinkhole.size() > 0:
		var sink_center: Vector2 = Vector2(desert_sinkhole["center"].x, desert_sinkhole["center"].y)
		var sink_dist2: float = Vector2(snapped_x - sink_center.x, snapped_z - sink_center.y).length()
		var sink_radius2: float = desert_sinkhole["radius"]
		var sink_rim_end2: float = sink_radius2 + 7.0
		var sink_ramp_outer: float = sink_rim_end2 + 12.0  # 12-unit ramp zone beyond rim
		if sink_dist2 >= sink_rim_end2 and sink_dist2 < sink_ramp_outer:
			var t: float = (sink_dist2 - sink_rim_end2) / (sink_ramp_outer - sink_rim_end2)
			t = clamp(t, 0.0, 1.0)
			t = t * t * (3.0 - 2.0 * t)  # Smooth-step for gradual start
			var ramp_height: float = lerpf(0.0, height, t)
			# Cap slope to 0.5 per unit (1.5 per cell) - gentler than cave slopes
			var max_height_at_dist: float = (sink_dist2 - sink_rim_end2) * 0.5
			height = min(ramp_height, max_height_at_dist)

	# Pit prevention: ensure no cell is more than 1 block below ALL cardinal neighbors.
	# This prevents inescapable holes. skip_pit_check is used by height cache builds
	# (which do pit prevention as post-processing instead). _in_pit_check is a
	# recursion guard so neighbor lookups skip this step (one level deep only).
	if not skip_pit_check and not _in_pit_check:
		_in_pit_check = true
		var min_neighbor: float = INF
		var pit_offsets: Array[Vector2] = [
			Vector2(cell_size, 0), Vector2(-cell_size, 0),
			Vector2(0, cell_size), Vector2(0, -cell_size)
		]
		for offset in pit_offsets:
			var nh: float = get_height_at(snapped_x + offset.x, snapped_z + offset.y)
			if nh < min_neighbor:
				min_neighbor = nh
		_in_pit_check = false
		if min_neighbor != INF and min_neighbor - height > 1.0:
			height = min_neighbor - 1.0

	return height


func _get_river_info_at(x: float, z: float, river: Dictionary) -> Dictionary:
	## Get information about whether a point is in a river and how far from center
	## Now includes taper at river ends to match visual water mesh
	var pos: Vector2 = Vector2(x, z)
	var path: Array = river["path"]
	var base_width: float = river["width"]
	var fishing_pools: Array = river["fishing_pools"]

	var min_dist: float = INF
	var effective_width: float = base_width
	var closest_segment: int = -1
	var closest_t: float = 0.0  # Parametric position along closest segment

	# Check distance to each segment and track which is closest
	for i in range(path.size() - 1):
		var a: Vector2 = path[i]
		var b: Vector2 = path[i + 1]
		var dist_info: Dictionary = _point_to_segment_distance_with_t(pos, a, b)
		var dist: float = dist_info["distance"]

		if dist < min_dist:
			min_dist = dist
			closest_segment = i
			closest_t = dist_info["t"]

	# Safety check - if no segments found, return not in river
	if closest_segment < 0:
		return {"in_river": false, "distance": INF, "width": base_width}

	# Calculate effective path position (0 to path.size()-1 as float)
	var path_position: float = float(closest_segment) + closest_t
	var path_length: float = float(path.size() - 1)

	# Taper settings - must match water mesh rendering
	var taper_points: int = 8  # Number of waypoints to taper over
	var min_width_factor: float = 0.1  # Minimum width as fraction of full width

	# Calculate taper factor based on position along river
	var taper: float = 1.0
	if path_position < taper_points:
		# Taper at start - use smooth easing (quadratic ease-in)
		var t: float = path_position / float(taper_points)
		taper = min_width_factor + (1.0 - min_width_factor) * (t * t)
	elif path_position > path_length - taper_points:
		# Taper at end - use smooth easing
		var dist_from_end: float = path_length - path_position
		var t: float = dist_from_end / float(taper_points)
		taper = min_width_factor + (1.0 - min_width_factor) * (t * t)

	# Apply taper to width
	effective_width = base_width * taper

	# Check if near a fishing pool (wider section) - only if not heavily tapered
	if taper > 0.5:
		for pool_pos in fishing_pools:
			if pos.distance_to(pool_pos) < river_fishing_pool_spacing * 0.5:
				effective_width = max(effective_width, river_fishing_pool_width * taper)
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


func _point_to_segment_distance_with_t(p: Vector2, a: Vector2, b: Vector2) -> Dictionary:
	## Calculate distance and parametric position (t) from point p to line segment ab
	var ab: Vector2 = b - a
	var ap: Vector2 = p - a

	var ab_len_sq: float = ab.length_squared()
	if ab_len_sq == 0:
		return {"distance": ap.length(), "t": 0.0}

	# Project p onto the line, clamped to segment
	var t: float = clamp(ap.dot(ab) / ab_len_sq, 0.0, 1.0)
	var closest: Vector2 = a + ab * t

	return {"distance": p.distance_to(closest), "t": t}


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

	# Filter stale entries: remove from unload queue if now needed again,
	# and remove from load queue if no longer needed (prevents terrain holes
	# when player oscillates at chunk boundaries)
	chunks_to_unload = chunks_to_unload.filter(func(c: Vector2i) -> bool: return not should_be_loaded.has(c))
	chunks_to_load = chunks_to_load.filter(func(c: Vector2i) -> bool: return should_be_loaded.has(c))

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

	# Determine if player is standing on this chunk (needs sync collision)
	var player_chunk: Vector2i = last_player_chunk
	var is_player_chunk: bool = (chunk_coord == player_chunk)

	var chunk: TerrainChunk = TerrainChunk.new()
	chunk.setup(chunk_coord, self)
	chunk.name = "Chunk_%d_%d" % [chunk_coord.x, chunk_coord.y]
	add_child(chunk)
	chunk.generate(is_player_chunk)

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

	# Spawn cave entrances in this chunk
	_spawn_cave_entrances_in_chunk(chunk_min_x, chunk_max_x, chunk_min_z, chunk_max_z)

	# Spawn desert oases in this chunk
	_spawn_oases_in_chunk(chunk_min_x, chunk_max_x, chunk_min_z, chunk_max_z)

	# Spawn sinkhole contents when its chunk loads
	if not sinkhole_spawned and desert_sinkhole.size() > 0:
		var sink_center: Vector2 = desert_sinkhole["center"]
		if sink_center.x >= chunk_min_x and sink_center.x < chunk_max_x and \
		   sink_center.y >= chunk_min_z and sink_center.y < chunk_max_z:
			_spawn_sinkhole_contents()

	# Spawn rock spire landmark when its chunk loads
	if not rock_spire_spawned:
		if rock_spire_position.x >= chunk_min_x and rock_spire_position.x < chunk_max_x and \
		   rock_spire_position.y >= chunk_min_z and rock_spire_position.y < chunk_max_z:
			_spawn_rock_spire()

	# Spawn wilderness sign near spawn
	_spawn_wilderness_sign(chunk_min_x, chunk_max_x, chunk_min_z, chunk_max_z)

	# Spawn trail home landmarks
	if not carved_tree_spawned:
		if carved_tree_position.x >= chunk_min_x and carved_tree_position.x < chunk_max_x and \
		   carved_tree_position.y >= chunk_min_z and carved_tree_position.y < chunk_max_z:
			_spawn_trail_carved_tree()

	if not stone_cairn_spawned:
		if stone_cairn_position.x >= chunk_min_x and stone_cairn_position.x < chunk_max_x and \
		   stone_cairn_position.y >= chunk_min_z and stone_cairn_position.y < chunk_max_z:
			_spawn_trail_stone_cairn()

	if not trail_signpost_spawned:
		if trail_signpost_position.x >= chunk_min_x and trail_signpost_position.x < chunk_max_x and \
		   trail_signpost_position.y >= chunk_min_z and trail_signpost_position.y < chunk_max_z:
			_spawn_trail_signpost()


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


func is_inside_cave_tunnel(world_x: float, world_z: float) -> bool:
	## Check if a world position falls inside the cave skip zone (crater/stairway).
	## Skip zone: X:[-3,+3], Z:[-6,+6] (2x4 cells = 6 wide x 12 deep).
	## The tunnel area (Z < -6) is NOT skipped — terrain generates on top.
	##
	## Cave center is snapped to cell_size grid, so skip zone boundaries align
	## exactly with cell edges. We shrink the check by half_cell since this
	## receives cell CENTER coordinates — a cell is only skipped if its entire
	## footprint falls within the zone.
	var half_cell: float = cell_size / 2.0
	for cave in cave_entrances:
		var cave_center: Vector2 = cave["center"]
		var local_x: float = world_x - cave_center.x
		var local_z: float = world_z - cave_center.y
		if (local_x >= -3.0 + half_cell and local_x <= 3.0 - half_cell
				and local_z >= -6.0 + half_cell and local_z <= 6.0 - half_cell):
			return true
	return false


func is_near_cave_entrance(world_x: float, world_z: float) -> bool:
	## Check if a world position is near any cave entrance (wider area for tree/resource exclusion).
	## 1-cell buffer around cave: X:[-6,+6], Z:[-27,+9].
	for cave in cave_entrances:
		var cave_center: Vector2 = cave["center"]
		var local_x: float = world_x - cave_center.x
		var local_z: float = world_z - cave_center.y
		if local_x >= -6.0 and local_x <= 6.0 and local_z >= -27.0 and local_z <= 9.0:
			return true
	return false


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


## Shared river water material (avoids shader recompile per river)
var _river_water_material: StandardMaterial3D = null

func _get_river_water_material() -> StandardMaterial3D:
	if not _river_water_material:
		_river_water_material = StandardMaterial3D.new()
		_river_water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_river_water_material.vertex_color_use_as_albedo = true
		_river_water_material.roughness = 0.1
		_river_water_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _river_water_material


func _spawn_entire_river(river_idx: int, river: Dictionary) -> void:
	## Spawn an entire river as one continuous mesh
	var path: Array = river["path"]
	var width: float = river["width"]

	if path.size() < 2:
		return

	var river_root: Node3D = Node3D.new()
	river_root.name = "River_%d" % river_idx

	# Create grid-snapped water mesh (cell-aligned quads matching terrain depression)
	var water_mesh: MeshInstance3D = MeshInstance3D.new()
	water_mesh.name = "WaterMesh"

	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var water_y: float = 0.05
	var water_color: Color = Color(0.2, 0.45, 0.6, 0.7)
	var normal: Vector3 = Vector3.UP

	# Compute bounding box of river path with padding for max possible width
	var pad: float = max(width, river_fishing_pool_width) / 2.0 + cell_size
	var bb_min_x: float = INF
	var bb_max_x: float = -INF
	var bb_min_z: float = INF
	var bb_max_z: float = -INF
	for point in path:
		bb_min_x = min(bb_min_x, point.x - pad)
		bb_max_x = max(bb_max_x, point.x + pad)
		bb_min_z = min(bb_min_z, point.y - pad)
		bb_max_z = max(bb_max_z, point.y + pad)

	# Snap bounding box to cell grid
	var start_cx: int = int(floor(bb_min_x / cell_size))
	var end_cx: int = int(floor(bb_max_x / cell_size)) + 1
	var start_cz: int = int(floor(bb_min_z / cell_size))
	var end_cz: int = int(floor(bb_max_z / cell_size)) + 1

	# Generate grid-aligned water quads for each cell inside the river
	var quad_count: int = 0
	var half_cell: float = cell_size / 2.0
	for cx in range(start_cx, end_cx):
		for cz in range(start_cz, end_cz):
			# Snap to cell center (same formula as get_height_at)
			var snapped_x: float = (float(cx) + 0.5) * cell_size
			var snapped_z: float = (float(cz) + 0.5) * cell_size

			# Skip river quads inside oasis areas to prevent Z-fighting
			if is_near_oasis(snapped_x, snapped_z, 4.0):
				continue

			var river_info: Dictionary = _get_river_info_at(snapped_x, snapped_z, river)
			if river_info["in_river"]:
				var v0: Vector3 = Vector3(snapped_x - half_cell, water_y, snapped_z - half_cell)
				var v1: Vector3 = Vector3(snapped_x + half_cell, water_y, snapped_z - half_cell)
				var v2: Vector3 = Vector3(snapped_x + half_cell, water_y, snapped_z + half_cell)
				var v3: Vector3 = Vector3(snapped_x - half_cell, water_y, snapped_z + half_cell)

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

				quad_count += 1

	if quad_count == 0:
		river_root.queue_free()
		return

	water_mesh.mesh = st.commit()

	# Semi-transparent water material (shared across all rivers to avoid shader recompiles)
	water_mesh.material_override = _get_river_water_material()

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
	print("[ChunkManager] Spawned river %d mesh with %d grid quads" % [river_idx, quad_count])


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


func _spawn_cave_entrances_in_chunk(min_x: float, max_x: float, min_z: float, max_z: float) -> void:
	## Spawn cave entrances in this chunk
	if not cave_entrance_script:
		return

	for cave_idx in range(cave_entrances.size()):
		if cave_idx in spawned_cave_indices:
			continue

		var cave_center: Vector2 = cave_entrances[cave_idx]["center"]
		if cave_center.x >= min_x and cave_center.x < max_x and \
		   cave_center.y >= min_z and cave_center.y < max_z:
			_spawn_cave_entrance(cave_idx)


func _spawn_cave_entrance(cave_idx: int) -> void:
	## Spawn a single cave entrance at the specified index
	if cave_idx in spawned_cave_indices or cave_idx >= cave_entrances.size():
		return

	var cave_data: Dictionary = cave_entrances[cave_idx]
	var cave_center: Vector2 = cave_data["center"]
	var cave_type: String = cave_data["cave_type"]

	# Create cave entrance node
	var entrance: StaticBody3D = StaticBody3D.new()
	entrance.set_script(cave_entrance_script)
	entrance.name = "Cave_%d_%s" % [cave_idx, cave_type]

	# Set cave properties directly (do NOT use "in" check - it can fail after set_script)
	entrance.cave_id = cave_idx
	entrance.cave_type = cave_type

	# Position on terrain - use position (local) since parent (Terrain) is at origin
	var terrain_height: float = get_height_at(cave_center.x, cave_center.y)
	entrance.position = Vector3(cave_center.x, terrain_height, cave_center.y)

	add_child(entrance)
	spawned_cave_indices.append(cave_idx)

	print("[ChunkManager] Spawned %s cave entrance #%d at (%.0f, %.0f)" % [
		cave_type, cave_idx, cave_center.x, cave_center.y
	])


func _spawn_oases_in_chunk(min_x: float, max_x: float, min_z: float, max_z: float) -> void:
	## Spawn desert oases when their center falls within this chunk
	for oasis_idx: int in range(desert_oases.size()):
		if oasis_idx in spawned_oasis_indices:
			continue

		var oasis_center: Vector2 = desert_oases[oasis_idx]["center"]
		if oasis_center.x >= min_x and oasis_center.x < max_x and \
		   oasis_center.y >= min_z and oasis_center.y < max_z:
			_spawn_oasis(oasis_idx)


func _spawn_oasis(oasis_idx: int) -> void:
	## Spawn a single desert oasis at the specified index
	if oasis_idx in spawned_oasis_indices or oasis_idx >= desert_oases.size():
		return

	var oasis_data: Dictionary = desert_oases[oasis_idx]
	var oasis_center: Vector2 = oasis_data["center"]

	var oasis: DesertOasis = DesertOasis.new()
	oasis.name = "DesertOasis_%d" % oasis_idx
	oasis.oasis_radius = oasis_data["radius"]
	oasis.oasis_depth = oasis_data["depth"]
	oasis.gem_type = oasis_data["gem_type"]
	oasis.gem_count = oasis_data["gem_count"]

	# Position at terrain height (should be depressed by water body system)
	var terrain_y: float = 0.0  # Water surface at y=0 for oasis
	oasis.position = Vector3(oasis_center.x, terrain_y, oasis_center.y)

	# Build with deterministic RNG based on oasis index
	var oasis_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	oasis_rng.seed = noise_seed + 5000 + oasis_idx * 100

	add_child(oasis)
	oasis.build(oasis_rng)
	spawned_oasis_indices.append(oasis_idx)

	print("[ChunkManager] Spawned desert oasis #%d (%s) at (%.0f, %.0f)" % [
		oasis_idx, oasis_data["gem_type"], oasis_center.x, oasis_center.y
	])


func _spawn_wilderness_sign(min_x: float, max_x: float, min_z: float, max_z: float) -> void:
	if wilderness_sign_spawned or not wilderness_sign_script:
		return
	# Find the flattest spot near spawn for the sign
	var best_pos: Vector2 = _find_flat_spot_for_sign()
	if best_pos.x < min_x or best_pos.x >= max_x or best_pos.y < min_z or best_pos.y >= max_z:
		return
	var sign_node: StaticBody3D = StaticBody3D.new()
	sign_node.set_script(wilderness_sign_script)
	sign_node.name = "WildernessSign"
	var terrain_y: float = get_height_at(best_pos.x, best_pos.y)
	sign_node.position = Vector3(best_pos.x, terrain_y, best_pos.y)
	# Face toward spawn (0,0)
	sign_node.rotation.y = atan2(-best_pos.x, -best_pos.y)
	add_child(sign_node)
	wilderness_sign_spawned = true


func _find_flat_spot_for_sign() -> Vector2:
	## Search candidate positions near spawn and pick the one with least height variation.
	## Candidates are on a grid from 4-8 units out, avoiding the immediate spawn area.
	var best_candidate: Vector2 = Vector2(6.0, -4.0)
	var best_variance: float = 999.0
	# Footprint sample offsets (sign is ~2 units wide after 0.7 scale)
	var footprint: Array[Vector2] = [
		Vector2(0, 0), Vector2(-1.0, 0), Vector2(1.0, 0),
		Vector2(0, 0.5), Vector2(0, -0.5),
	]
	# Search grid: ring around spawn at 5-8 unit distance, stepping by cell_size (3.0)
	for cx: float in range(-8, 9, 3):
		for cz: float in range(-8, 9, 3):
			var dist: float = Vector2(cx, cz).length()
			if dist < 4.0 or dist > 9.0:
				continue
			# Sample heights across the sign footprint at this candidate
			var h_min: float = 999.0
			var h_max: float = -999.0
			for fp: Vector2 in footprint:
				var h: float = get_height_at(cx + fp.x, cz + fp.y)
				h_min = min(h_min, h)
				h_max = max(h_max, h)
			var variance: float = h_max - h_min
			if variance < best_variance:
				best_variance = variance
				best_candidate = Vector2(cx, cz)
	return best_candidate


func _spawn_trail_carved_tree() -> void:
	if carved_tree_spawned or not carved_tree_script:
		return
	var node: StaticBody3D = StaticBody3D.new()
	node.set_script(carved_tree_script)
	node.name = "TrailCarvedTree"
	var terrain_y: float = get_height_at(carved_tree_position.x, carved_tree_position.y)
	node.position = Vector3(carved_tree_position.x, terrain_y, carved_tree_position.y)
	# Rotate so the arrow (local +X) points toward the stone cairn
	var dx: float = stone_cairn_position.x - carved_tree_position.x
	var dz: float = stone_cairn_position.y - carved_tree_position.y
	node.rotation.y = atan2(-dz, dx)
	add_child(node)
	carved_tree_spawned = true
	print("[ChunkManager] Spawned trail carved tree at (%.0f, %.0f)" % [carved_tree_position.x, carved_tree_position.y])


func _spawn_trail_stone_cairn() -> void:
	if stone_cairn_spawned or not stone_cairn_script:
		return
	var node: StaticBody3D = StaticBody3D.new()
	node.set_script(stone_cairn_script)
	node.name = "TrailStoneCairn"
	var terrain_y: float = get_height_at(stone_cairn_position.x, stone_cairn_position.y)
	node.position = Vector3(stone_cairn_position.x, terrain_y, stone_cairn_position.y)
	add_child(node)
	stone_cairn_spawned = true
	print("[ChunkManager] Spawned trail stone cairn at (%.0f, %.0f)" % [stone_cairn_position.x, stone_cairn_position.y])


func _spawn_trail_signpost() -> void:
	if trail_signpost_spawned or not trail_signpost_script:
		return
	var node: StaticBody3D = StaticBody3D.new()
	node.set_script(trail_signpost_script)
	node.name = "TrailSignpost"
	var terrain_y: float = get_height_at(trail_signpost_position.x, trail_signpost_position.y)
	node.position = Vector3(trail_signpost_position.x, terrain_y, trail_signpost_position.y)
	# Face back toward spawn (so the player sees the sign facing them)
	node.rotation.y = atan2(-trail_signpost_position.x, -trail_signpost_position.y)
	add_child(node)
	trail_signpost_spawned = true
	print("[ChunkManager] Spawned trail signpost at (%.0f, %.0f)" % [trail_signpost_position.x, trail_signpost_position.y])


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


func clear_decorations_in_radius(center_x: float, center_z: float, radius: float) -> void:
	## Remove decorative grass and flowers within a radius (used when placing structures).
	var center_2d: Vector2 = Vector2(center_x, center_z)
	for chunk_coord: Vector2i in loaded_chunks.keys():
		var chunk: TerrainChunk = loaded_chunks[chunk_coord]
		if not is_instance_valid(chunk) or not chunk.decorations_container:
			continue
		# Quick AABB check: skip chunks too far away
		var chunk_center_x: float = (chunk_coord.x + 0.5) * chunk_size_cells * cell_size
		var chunk_center_z: float = (chunk_coord.y + 0.5) * chunk_size_cells * cell_size
		if Vector2(chunk_center_x, chunk_center_z).distance_to(center_2d) > radius + chunk_size_cells * cell_size:
			continue
		var to_remove: Array[Node] = []
		for child: Node in chunk.decorations_container.get_children():
			var child_pos: Vector3 = child.global_position
			var dist: float = Vector2(child_pos.x, child_pos.z).distance_to(center_2d)
			if dist < radius:
				to_remove.append(child)
		for node: Node in to_remove:
			node.queue_free()
