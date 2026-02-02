extends Node
## Manages spatial ambient sounds for water features and other environmental audio.
## Uses AudioStreamPlayer3D nodes positioned at water edges for immersive audio.
## Supports separate sounds for ponds/lakes and rivers.
## Sounds play when player is adjacent to (within ~6 units of) water edges.

# Configuration
@export var adjacent_range: float = 12.0  # Play sound when within this distance of water edge
@export var max_pond_emitters: int = 4  # Maximum active pond/lake emitters
@export var max_river_emitters: int = 3  # Maximum active river emitters
@export var update_interval: float = 0.25  # How often to update emitter positions (seconds)

# Audio streams - separate sounds for different water types
var pond_sound: AudioStream  # For ponds and lakes
var river_sound: AudioStream  # For rivers/streams
var sounds_loaded: bool = false

# Active emitters - tracked separately by type
var pond_emitters: Array[AudioStreamPlayer3D] = []
var river_emitters: Array[AudioStreamPlayer3D] = []

# Reference to chunk manager
var chunk_manager: Node

# Update throttling
var update_timer: float = 0.0
var player: Node3D


func _ready() -> void:
	_load_water_sounds()

	# Find chunk manager after scene is ready
	await get_tree().process_frame
	chunk_manager = get_tree().get_first_node_in_group("chunk_manager")
	if not chunk_manager:
		var main: Node = get_tree().root.get_node_or_null("Main")
		if main:
			chunk_manager = main.get_node_or_null("ChunkManager")

	player = get_tree().get_first_node_in_group("player")

	if not chunk_manager:
		push_warning("[AmbientSoundManager] ChunkManager not found")
	else:
		print("[AmbientSoundManager] Initialized with ChunkManager")


func _process(delta: float) -> void:
	if not sounds_loaded or not chunk_manager:
		return

	# Throttle updates
	update_timer += delta
	if update_timer < update_interval:
		return
	update_timer = 0.0

	# Update player reference if needed
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if not player:
			return

	_update_water_emitters()


func _load_water_sounds() -> void:
	## Load water ambient sounds from assets
	var pond_loaded: bool = false
	var river_loaded: bool = false

	# Load pond/lake sound
	var pond_path: String = "res://assets/audio/ambient/pond_ambient.mp3"
	if ResourceLoader.exists(pond_path):
		pond_sound = load(pond_path)
		if pond_sound is AudioStreamMP3:
			pond_sound.loop = true
		pond_loaded = true
		print("[AmbientSoundManager] Pond ambient sound loaded")
	else:
		# Try ogg fallback
		pond_path = "res://assets/audio/ambient/pond_ambient.ogg"
		if ResourceLoader.exists(pond_path):
			pond_sound = load(pond_path)
			if pond_sound is AudioStreamOggVorbis:
				pond_sound.loop = true
			pond_loaded = true
			print("[AmbientSoundManager] Pond ambient sound loaded (ogg)")

	# Load river/stream sound
	var river_path: String = "res://assets/audio/ambient/river_ambient.mp3"
	if ResourceLoader.exists(river_path):
		river_sound = load(river_path)
		if river_sound is AudioStreamMP3:
			river_sound.loop = true
		river_loaded = true
		print("[AmbientSoundManager] River ambient sound loaded")
	else:
		# Try ogg fallback
		river_path = "res://assets/audio/ambient/river_ambient.ogg"
		if ResourceLoader.exists(river_path):
			river_sound = load(river_path)
			if river_sound is AudioStreamOggVorbis:
				river_sound.loop = true
			river_loaded = true
			print("[AmbientSoundManager] River ambient sound loaded (ogg)")

	sounds_loaded = pond_loaded or river_loaded

	if not pond_loaded:
		push_warning("[AmbientSoundManager] Pond ambient sound not found")
	if not river_loaded:
		push_warning("[AmbientSoundManager] River ambient sound not found")


func _update_water_emitters() -> void:
	## Update emitter positions based on player proximity to water EDGES
	if not player:
		return

	var player_pos: Vector3 = player.global_position
	var player_pos_2d: Vector2 = Vector2(player_pos.x, player_pos.z)

	# Collect nearby pond/lake edge positions
	var nearby_pond_positions: Array[Vector3] = []

	# Collect nearby river positions
	var nearby_river_positions: Array[Vector3] = []

	# Check water bodies (ponds and lakes) - use distance to EDGE, not center
	if "water_bodies" in chunk_manager:
		var water_bodies: Array = chunk_manager.water_bodies
		for body in water_bodies:
			var center: Vector2 = body["center"]
			var radius: float = body["radius"]

			var dist_to_center: float = player_pos_2d.distance_to(center)
			var dist_to_edge: float = dist_to_center - radius

			# Player is inside the water (negative distance to edge)
			if dist_to_edge < 0:
				# Place emitter at player position so they always hear it
				nearby_pond_positions.append(Vector3(player_pos.x, 0.0, player_pos.z))
			# Player is adjacent to water edge (outside but nearby)
			elif dist_to_edge < adjacent_range:
				# Calculate nearest point on water edge
				var dir_to_player: Vector2 = (player_pos_2d - center)
				if dir_to_player.length() > 0.01:
					dir_to_player = dir_to_player.normalized()
				else:
					dir_to_player = Vector2(1, 0)

				var edge_point: Vector2 = center + dir_to_player * radius
				nearby_pond_positions.append(Vector3(edge_point.x, 0.0, edge_point.y))

	# Check rivers - find nearest point on river path
	if "rivers" in chunk_manager:
		var rivers_data: Array = chunk_manager.rivers
		for river in rivers_data:
			var path: Array = river["path"]
			var river_width: float = river.get("width", 5.0)
			var half_width: float = river_width / 2.0

			# Find nearest point on river to player
			var nearest_point: Vector2 = Vector2.ZERO
			var min_dist: float = INF

			for i in range(path.size() - 1):
				var a: Vector2 = path[i]
				var b: Vector2 = path[i + 1]
				var closest: Vector2 = _get_closest_point_on_segment(player_pos_2d, a, b)
				var dist: float = player_pos_2d.distance_to(closest)

				if dist < min_dist:
					min_dist = dist
					nearest_point = closest

			# Distance to river edge (accounting for river width)
			var dist_to_river_edge: float = min_dist - half_width

			# Player is inside the river (negative distance to edge)
			if dist_to_river_edge < 0:
				# Place emitter at player position so they always hear it
				nearby_river_positions.append(Vector3(player_pos.x, 0.0, player_pos.z))
			# Player is adjacent to river edge (outside but nearby)
			elif dist_to_river_edge < adjacent_range:
				# Place emitter at nearest point on river
				nearby_river_positions.append(Vector3(nearest_point.x, 0.0, nearest_point.y))

	# Sort by distance to player
	nearby_pond_positions.sort_custom(func(a: Vector3, b: Vector3) -> bool:
		return a.distance_to(player_pos) < b.distance_to(player_pos)
	)
	nearby_river_positions.sort_custom(func(a: Vector3, b: Vector3) -> bool:
		return a.distance_to(player_pos) < b.distance_to(player_pos)
	)

	# Limit to max emitters
	if nearby_pond_positions.size() > max_pond_emitters:
		nearby_pond_positions.resize(max_pond_emitters)
	if nearby_river_positions.size() > max_river_emitters:
		nearby_river_positions.resize(max_river_emitters)

	# Update or create emitters for each type
	if pond_sound:
		_sync_emitters(pond_emitters, nearby_pond_positions, pond_sound)
	if river_sound:
		_sync_emitters(river_emitters, nearby_river_positions, river_sound)


func _get_closest_point_on_segment(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	## Find the closest point on line segment ab to point p
	var ab: Vector2 = b - a
	var ap: Vector2 = p - a

	var ab_len_sq: float = ab.length_squared()
	if ab_len_sq < 0.0001:
		return a

	var t: float = clamp(ap.dot(ab) / ab_len_sq, 0.0, 1.0)
	return a + ab * t


func _sync_emitters(emitters: Array[AudioStreamPlayer3D], target_positions: Array[Vector3], sound: AudioStream) -> void:
	## Synchronize active emitters with target positions

	# Remove excess emitters
	while emitters.size() > target_positions.size():
		var emitter: AudioStreamPlayer3D = emitters.pop_back()
		emitter.stop()
		emitter.queue_free()

	# Update existing emitters or create new ones
	for i in range(target_positions.size()):
		var target_pos: Vector3 = target_positions[i]

		if i < emitters.size():
			# Update existing emitter position
			emitters[i].global_position = target_pos
		else:
			# Create new emitter
			var emitter: AudioStreamPlayer3D = _create_water_emitter(sound)
			emitter.global_position = target_pos
			add_child(emitter)
			emitters.append(emitter)
			emitter.play()


func _create_water_emitter(sound: AudioStream) -> AudioStreamPlayer3D:
	## Create a new water sound emitter with proper 3D settings
	var emitter: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	emitter.stream = sound
	emitter.autoplay = false

	# 3D audio settings - emitter is at water edge, close to player
	emitter.unit_size = 3.0  # Full volume within 3 units
	emitter.max_distance = adjacent_range + 5.0  # Fade out just beyond adjacent range
	emitter.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE

	# Volume adjustment
	emitter.volume_db = -6.0

	# Use Ambient bus if available, otherwise Master
	if AudioServer.get_bus_index("Ambient") >= 0:
		emitter.bus = "Ambient"

	return emitter


func get_active_emitter_count() -> int:
	return pond_emitters.size() + river_emitters.size()


func get_pond_emitter_count() -> int:
	return pond_emitters.size()


func get_river_emitter_count() -> int:
	return river_emitters.size()


func set_water_volume(volume_db: float) -> void:
	## Set volume for all water emitters
	for emitter in pond_emitters:
		emitter.volume_db = volume_db
	for emitter in river_emitters:
		emitter.volume_db = volume_db
