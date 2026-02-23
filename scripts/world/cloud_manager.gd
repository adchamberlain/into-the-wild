extends Node3D
class_name CloudManager
## Manages blocky voxel-style clouds that respond to weather and time of day.

# Cloud pool settings
const CLOUD_POOL_SIZE: int = 30
const CLOUD_ALTITUDE: float = 100.0
const CLOUD_FIELD_RADIUS: float = 250.0
const CLOUD_WRAP_MARGIN: float = 50.0

# Shared material for ALL cloud boxes (static for performance)
static var cloud_material: StandardMaterial3D = null

# Cloud container follows player XZ
var cloud_container: Node3D = null

# Pool of cloud cluster Node3Ds
var cloud_pool: Array[Node3D] = []

# Wind
var wind_speed: float = 2.5
var wind_direction: Vector2 = Vector2(1.0, 0.0)  # Normalized XZ direction
var target_wind_speed: float = 2.5

# Weather state
var active_cloud_count: int = 8
var target_cloud_count: int = 8
var cloud_base_color: Color = Color(0.95, 0.95, 0.97, 0.7)
var target_cloud_color: Color = Color(0.95, 0.95, 0.97, 0.7)

# Time-of-day tint (applied on top of weather color)
var time_tint: Color = Color(1.0, 1.0, 1.0, 1.0)
var time_alpha_multiplier: float = 1.0

# Cached camera reference (same pattern as environment_manager.gd)
var cached_camera: Camera3D = null

# Node references
var weather_manager: Node = null
var time_manager: Node = null

# Transition tween
var weather_tween: Tween = null


func _ready() -> void:
	_init_shared_material()
	_create_cloud_container()
	_create_cloud_pool()

	# Connect to WeatherManager
	weather_manager = get_node_or_null("../../WeatherManager")
	if weather_manager and weather_manager.has_signal("weather_changed"):
		weather_manager.weather_changed.connect(_on_weather_changed)

	# Connect to TimeManager
	time_manager = get_node_or_null("../../TimeManager")
	if time_manager and time_manager.has_signal("time_changed"):
		time_manager.time_changed.connect(_on_time_changed)

	# Apply initial state
	_apply_cloud_visibility()
	_update_time_tint()
	print("[CloudManager] Initialized with %d cloud clusters" % CLOUD_POOL_SIZE)


func _init_shared_material() -> void:
	if cloud_material != null:
		return
	cloud_material = StandardMaterial3D.new()
	cloud_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cloud_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cloud_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	cloud_material.albedo_color = cloud_base_color


func _create_cloud_container() -> void:
	cloud_container = Node3D.new()
	cloud_container.name = "CloudContainer"
	add_child(cloud_container)


func _create_cloud_pool() -> void:
	for i: int in range(CLOUD_POOL_SIZE):
		var cluster: Node3D = _build_cloud_cluster()
		cluster.name = "Cloud_%d" % i
		cloud_container.add_child(cluster)
		cloud_pool.append(cluster)

		# Scatter randomly across the field
		var angle: float = randf() * TAU
		var dist: float = randf() * CLOUD_FIELD_RADIUS
		cluster.position = Vector3(
			cos(angle) * dist,
			randf_range(-5.0, 5.0),  # Slight vertical variation
			sin(angle) * dist
		)


func _build_cloud_cluster() -> Node3D:
	var cluster: Node3D = Node3D.new()

	# Determine box count: 4-8 total (1 base + 3-7 additional)
	var additional_count: int = randi_range(3, 7)

	# Base box: ~12x2x8 with slight randomization
	var base_mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var base_box: BoxMesh = BoxMesh.new()
	base_box.size = Vector3(
		randf_range(10.0, 14.0),
		randf_range(1.5, 2.5),
		randf_range(6.0, 10.0)
	)
	base_box.material = cloud_material
	base_mesh_instance.mesh = base_box
	base_mesh_instance.name = "Base"
	cluster.add_child(base_mesh_instance)

	# Additional boxes offset on top/sides
	for j: int in range(additional_count):
		var extra: MeshInstance3D = MeshInstance3D.new()
		var extra_box: BoxMesh = BoxMesh.new()
		extra_box.size = Vector3(
			randf_range(4.0, 8.0),
			randf_range(1.5, 2.5),
			randf_range(4.0, 6.0)
		)
		extra_box.material = cloud_material
		extra.mesh = extra_box
		extra.name = "Part_%d" % j

		# Offset: mostly on top with some lateral spread
		extra.position = Vector3(
			randf_range(-5.0, 5.0),
			randf_range(0.0, 2.0),
			randf_range(-3.0, 3.0)
		)
		cluster.add_child(extra)

	return cluster


func _process(delta: float) -> void:
	# Follow camera XZ position
	if not is_instance_valid(cached_camera):
		cached_camera = get_viewport().get_camera_3d()

	if cached_camera:
		var cam_pos: Vector3 = cached_camera.global_position
		cloud_container.global_position = Vector3(
			cam_pos.x,
			cam_pos.y + CLOUD_ALTITUDE,
			cam_pos.z
		)

	# Drift clouds
	_drift_clouds(delta)


func _drift_clouds(delta: float) -> void:
	var drift: Vector3 = Vector3(
		wind_direction.x * wind_speed * delta,
		0.0,
		wind_direction.y * wind_speed * delta
	)

	var wrap_radius: float = CLOUD_FIELD_RADIUS + CLOUD_WRAP_MARGIN

	for i: int in range(cloud_pool.size()):
		var cluster: Node3D = cloud_pool[i]
		if not cluster.visible:
			continue

		cluster.position += drift

		# Wrap to opposite side if beyond field
		var xz_dist: float = Vector2(cluster.position.x, cluster.position.z).length()
		if xz_dist > wrap_radius:
			# Place on opposite side with some randomness
			var opposite_dir: Vector2 = -Vector2(cluster.position.x, cluster.position.z).normalized()
			var new_dist: float = CLOUD_FIELD_RADIUS * randf_range(0.7, 1.0)
			cluster.position.x = opposite_dir.x * new_dist
			cluster.position.z = opposite_dir.y * new_dist
			cluster.position.y = randf_range(-5.0, 5.0)


func _on_weather_changed(weather_type: String) -> void:
	# Determine target cloud settings based on weather
	match weather_type:
		"Clear":
			target_cloud_count = 8
			target_cloud_color = Color(0.95, 0.95, 0.97, 0.7)
			target_wind_speed = randf_range(2.0, 3.0)
		"Rain":
			target_cloud_count = 18
			target_cloud_color = Color(0.6, 0.6, 0.65, 0.85)
			target_wind_speed = randf_range(3.0, 4.0)
		"Storm":
			target_cloud_count = 28
			target_cloud_color = Color(0.35, 0.35, 0.4, 0.95)
			target_wind_speed = randf_range(5.0, 7.0)
		"Fog":
			target_cloud_count = 5
			target_cloud_color = Color(0.8, 0.8, 0.82, 0.4)
			target_wind_speed = randf_range(1.0, 2.0)
		"Heat Wave":
			target_cloud_count = 0
			target_cloud_color = Color(0.95, 0.95, 0.97, 0.0)
			target_wind_speed = 1.0
		"Cold Snap":
			target_cloud_count = 10
			target_cloud_color = Color(0.85, 0.88, 0.95, 0.6)
			target_wind_speed = randf_range(2.0, 3.0)
		_:
			target_cloud_count = 8
			target_cloud_color = Color(0.95, 0.95, 0.97, 0.7)
			target_wind_speed = 2.5

	# Randomize wind direction on each weather change
	var angle: float = randf() * TAU
	wind_direction = Vector2(cos(angle), sin(angle))

	# Tween transition over 3 seconds
	_transition_weather()


func _transition_weather() -> void:
	# Kill any existing weather tween
	if weather_tween and weather_tween.is_valid():
		weather_tween.kill()

	weather_tween = create_tween()
	weather_tween.set_parallel(true)

	# Tween cloud color and alpha
	var start_color: Color = cloud_base_color
	weather_tween.tween_method(
		_tween_cloud_color,
		start_color,
		target_cloud_color,
		3.0
	)

	# Tween wind speed
	weather_tween.tween_property(self, "wind_speed", target_wind_speed, 3.0)

	# Update active cloud count immediately (visibility toggled)
	# We tween the count separately for a gradual reveal/hide
	var start_count: int = active_cloud_count
	weather_tween.tween_method(
		_tween_cloud_count,
		start_count,
		target_cloud_count,
		3.0
	)


func _tween_cloud_color(color: Color) -> void:
	cloud_base_color = color
	_update_material_color()


func _tween_cloud_count(count: float) -> void:
	active_cloud_count = int(count)
	_apply_cloud_visibility()


func _update_material_color() -> void:
	if cloud_material == null:
		return

	# Apply time-of-day tint on top of weather color
	var final_color: Color = Color(
		cloud_base_color.r * time_tint.r,
		cloud_base_color.g * time_tint.g,
		cloud_base_color.b * time_tint.b,
		cloud_base_color.a * time_alpha_multiplier
	)
	cloud_material.albedo_color = final_color


func _apply_cloud_visibility() -> void:
	for i: int in range(cloud_pool.size()):
		cloud_pool[i].visible = i < active_cloud_count


func _on_time_changed(hour: int, minute: int) -> void:
	_update_time_tint()


func _update_time_tint() -> void:
	if not time_manager:
		return

	var progress: float = time_manager.get_day_progress()

	# Determine time-of-day tint based on day progress
	# Dawn: 0.21-0.29 (5AM-7AM) - warm orange-pink
	# Day: 0.29-0.75 (7AM-6PM) - white (no tint)
	# Dusk: 0.75-0.875 (6PM-9PM) - warm orange-red
	# Night: 0.875-1.0, 0.0-0.21 (9PM-5AM) - blue, reduced alpha

	if progress >= 0.21 and progress < 0.25:
		# Transitioning into dawn
		var t: float = (progress - 0.21) / 0.04
		time_tint = Color(1.0, 1.0, 1.0).lerp(Color(1.1, 0.85, 0.75), t)
		time_alpha_multiplier = lerpf(0.3, 0.8, t)
	elif progress >= 0.25 and progress < 0.29:
		# Dawn proper - warm orange-pink
		var t: float = (progress - 0.25) / 0.04
		time_tint = Color(1.1, 0.85, 0.75).lerp(Color(1.0, 1.0, 1.0), t)
		time_alpha_multiplier = lerpf(0.8, 1.0, t)
	elif progress >= 0.29 and progress < 0.75:
		# Daytime - white (no tint)
		time_tint = Color(1.0, 1.0, 1.0)
		time_alpha_multiplier = 1.0
	elif progress >= 0.75 and progress < 0.83:
		# Transitioning into dusk - warm orange-red
		var t: float = (progress - 0.75) / 0.08
		time_tint = Color(1.0, 1.0, 1.0).lerp(Color(1.1, 0.7, 0.55), t)
		time_alpha_multiplier = 1.0
	elif progress >= 0.83 and progress < 0.875:
		# Dusk to night transition
		var t: float = (progress - 0.83) / 0.045
		time_tint = Color(1.1, 0.7, 0.55).lerp(Color(0.6, 0.65, 0.9), t)
		time_alpha_multiplier = lerpf(1.0, 0.3, t)
	else:
		# Night - blue tint, reduced alpha so stars show through
		time_tint = Color(0.6, 0.65, 0.9)
		time_alpha_multiplier = 0.3

	_update_material_color()
