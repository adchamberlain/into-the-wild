extends WorldEnvironment
## Manages sky, lighting, and ambient environment based on time of day.

@export var time_manager_path: NodePath

# Sun/Moon light reference
@export var sun_light_path: NodePath

# Night sky elements
var stars_particles: GPUParticles3D
var moon_mesh: MeshInstance3D
var moon_shadow: MeshInstance3D  # Shadow overlay for moon phases
var moon_light: DirectionalLight3D
var stars_container: Node3D

# Sun mesh
var sun_mesh: MeshInstance3D
var sun_container: Node3D

# Moon phase tracking
var current_moon_phase: int = 0  # 0-7, 0 = Full Moon
const LUNAR_CYCLE_DAYS: int = 8  # 8 phases, 1 day each
const MOON_PHASES: Array[String] = [
	"Full Moon",
	"Waning Gibbous",
	"Last Quarter",
	"Waning Crescent",
	"New Moon",
	"Waxing Crescent",
	"First Quarter",
	"Waxing Gibbous"
]

# Sky settings
@export var star_count: int = 200  # Reduced from 800 for performance
@export var moon_size: float = 8.0
@export var moon_distance: float = 300.0
@export var sun_size: float = 12.0
@export var sun_distance: float = 350.0

# Color settings for different times
var sky_colors: Dictionary = {
	"dawn": Color(0.95, 0.7, 0.5),
	"day": Color(0.4, 0.6, 0.9),
	"dusk": Color(0.9, 0.5, 0.4),
	"night": Color(0.05, 0.05, 0.15)
}

var ambient_colors: Dictionary = {
	"dawn": Color(0.8, 0.6, 0.5),
	"day": Color(1.0, 1.0, 1.0),
	"dusk": Color(0.8, 0.5, 0.4),
	"night": Color(0.1, 0.1, 0.2)
}

var sun_colors: Dictionary = {
	"dawn": Color(1.0, 0.7, 0.4),
	"day": Color(1.0, 0.98, 0.95),
	"dusk": Color(1.0, 0.6, 0.3),
	"night": Color(0.3, 0.3, 0.5)
}

var sun_intensities: Dictionary = {
	"dawn": 0.55,
	"day": 1.1,
	"dusk": 0.45,
	"night": 0.12
}

var time_manager: Node
var sun_light: DirectionalLight3D
var sky_material: ProceduralSkyMaterial

# Cached camera reference for performance
var cached_camera: Camera3D = null

# Base distance fog settings (always on for atmosphere)
# Using depth fog mode for consistent fog regardless of player position
var base_fog_depth_begin: float = 60.0    # Fog starts at 60 units from camera
var base_fog_depth_end: float = 300.0     # Full fog at 300 units (far terrain)
var base_fog_depth_curve: float = 1.0     # Linear falloff (1.0 = linear)

# Fog colors for different times (matched to sky horizon)
var fog_colors: Dictionary = {
	"dawn": Color(0.95, 0.75, 0.6),
	"day": Color(0.65, 0.75, 0.9),
	"dusk": Color(0.9, 0.6, 0.5),
	"night": Color(0.1, 0.1, 0.2)
}

# Weather overlay
var current_weather: String = "Clear"
var weather_color_modifiers: Dictionary = {
	"Clear": Color(1.0, 1.0, 1.0),
	"Rain": Color(0.7, 0.75, 0.85),
	"Storm": Color(0.4, 0.42, 0.5),
	"Fog": Color(0.85, 0.85, 0.88),
	"Heat Wave": Color(1.1, 1.0, 0.9),
	"Cold Snap": Color(0.8, 0.85, 1.0)
}
var weather_intensity_modifiers: Dictionary = {
	"Clear": 1.0,
	"Rain": 0.6,
	"Storm": 0.3,
	"Fog": 0.7,
	"Heat Wave": 1.1,
	"Cold Snap": 0.8
}
var weather_fog_density: Dictionary = {
	"Clear": 0.0,
	"Rain": 0.005,
	"Storm": 0.01,
	"Fog": 0.02,
	"Heat Wave": 0.002,
	"Cold Snap": 0.005
}

# Weather affects fog depth end (visibility distance)
var weather_fog_depth_end: Dictionary = {
	"Clear": 300.0,     # Full visibility
	"Rain": 200.0,      # Slightly reduced
	"Storm": 120.0,     # Heavily reduced
	"Fog": 80.0,        # Very low visibility
	"Heat Wave": 250.0, # Heat haze slightly reduces
	"Cold Snap": 220.0  # Cold air slightly reduces
}


func _ready() -> void:
	if time_manager_path:
		time_manager = get_node(time_manager_path)
		time_manager.time_changed.connect(_on_time_changed)
		if time_manager.has_signal("day_changed"):
			time_manager.day_changed.connect(_on_day_changed)

	if sun_light_path:
		sun_light = get_node(sun_light_path)

	_setup_environment()
	_setup_night_sky()
	_update_moon_phase()  # Set initial moon phase


func _setup_environment() -> void:
	# Create procedural sky
	sky_material = ProceduralSkyMaterial.new()
	var day_color: Color = sky_colors["day"]
	sky_material.sky_top_color = day_color
	sky_material.sky_horizon_color = day_color.lightened(0.2)
	sky_material.ground_bottom_color = Color(0.2, 0.2, 0.2)
	sky_material.ground_horizon_color = day_color.lightened(0.3)
	# Disable procedural sun disc (DirectionalLight3D provides actual sun lighting)
	sky_material.sun_angle_max = 0.0
	sky_material.sun_curve = 0.0

	var sky: Sky = Sky.new()
	sky.sky_material = sky_material

	environment.sky = sky
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 1.0  # Higher for balanced lighting
	environment.ambient_light_sky_contribution = 0.5
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_white = 6.0
	# Disable expensive post-processing effects for better performance
	environment.ssao_enabled = false
	environment.ssil_enabled = false  # SSIL is very GPU-intensive
	environment.glow_enabled = false  # Glow adds GPU overhead

	# Enable base distance fog for atmosphere (always on)
	# Using depth mode for consistent fog regardless of player world position
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_depth_begin = base_fog_depth_begin
	environment.fog_depth_end = base_fog_depth_end
	environment.fog_depth_curve = base_fog_depth_curve
	environment.fog_light_color = fog_colors["day"]
	environment.fog_light_energy = 0.5  # Subtle fog, not overpowering
	environment.fog_sun_scatter = 0.0   # Disabled - causes bright reflections


func _setup_night_sky() -> void:
	# Create container for night sky elements (will follow camera)
	stars_container = Node3D.new()
	stars_container.name = "NightSky"
	add_child(stars_container)

	_setup_stars()
	_setup_moon()
	_setup_sun()
	print("[EnvironmentManager] Sky elements initialized")


func _setup_stars() -> void:
	stars_particles = GPUParticles3D.new()
	stars_particles.name = "Stars"
	stars_particles.amount = star_count
	stars_particles.lifetime = 1000.0  # Very long lifetime - stars don't move
	stars_particles.explosiveness = 1.0  # All spawn at once
	stars_particles.randomness = 0.0
	stars_particles.one_shot = true  # Emit once and stay
	stars_particles.visibility_aabb = AABB(Vector3(-500, 0, -500), Vector3(1000, 500, 1000))
	stars_particles.emitting = true

	# Process material for star positions - emit from a flat disc high above
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	# Wide flat box high in the sky - stars spread across sky dome
	material.emission_box_extents = Vector3(400.0, 50.0, 400.0)
	material.direction = Vector3(0, 0, 0)
	material.spread = 0.0
	material.initial_velocity_min = 0.0
	material.initial_velocity_max = 0.0
	material.gravity = Vector3(0, 0, 0)
	# Small consistent scale for tiny star dots
	material.scale_min = 0.3
	material.scale_max = 0.8
	stars_particles.process_material = material

	# Star mesh (tiny square dot)
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.4, 0.4)
	stars_particles.draw_pass_1 = mesh

	# Star material (bright white, unshaded, billboard)
	var mesh_material := StandardMaterial3D.new()
	mesh_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_material.albedo_color = Color(1.0, 1.0, 0.95, 0.9)
	mesh_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	# Depth test enabled so terrain occludes stars properly
	mesh.material = mesh_material

	# Position stars high above camera (only in upper sky)
	stars_particles.position = Vector3(0, 150, 0)

	stars_container.add_child(stars_particles)


func _setup_moon() -> void:
	moon_mesh = MeshInstance3D.new()
	moon_mesh.name = "Moon"

	# Create blocky box mesh for moon (flat square, Minecraft-style)
	var box := BoxMesh.new()
	box.size = Vector3(moon_size, moon_size, moon_size * 0.15)  # Flat square
	moon_mesh.mesh = box

	# Moon material (pale yellow-white, unshaded for consistent look)
	var moon_material := StandardMaterial3D.new()
	moon_material.albedo_color = Color(0.95, 0.95, 0.88)
	moon_material.emission_enabled = true
	moon_material.emission = Color(0.85, 0.85, 0.75)
	moon_material.emission_energy_multiplier = 1.0
	moon_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	moon_mesh.material_override = moon_material

	# Position moon at distance
	moon_mesh.position = Vector3(0, moon_distance * 0.7, -moon_distance * 0.7)
	moon_mesh.visible = false  # Start hidden, shown at night

	stars_container.add_child(moon_mesh)

	# Create shadow overlay for moon phases
	moon_shadow = MeshInstance3D.new()
	moon_shadow.name = "MoonShadow"

	var shadow_box := BoxMesh.new()
	shadow_box.size = Vector3(moon_size * 0.55, moon_size * 1.05, moon_size * 0.2)
	moon_shadow.mesh = shadow_box

	# Dark material for shadow (matches night sky)
	var shadow_material := StandardMaterial3D.new()
	shadow_material.albedo_color = Color(0.05, 0.05, 0.12, 1.0)
	shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	moon_shadow.material_override = shadow_material
	moon_shadow.visible = false

	# Shadow is child of moon so it moves with it
	moon_mesh.add_child(moon_shadow)

	# Add subtle moon light
	moon_light = DirectionalLight3D.new()
	moon_light.name = "MoonLight"
	moon_light.light_color = Color(0.7, 0.75, 0.9)
	moon_light.light_energy = 0.0  # Start off, enabled at night
	moon_light.shadow_enabled = false
	add_child(moon_light)


func _setup_sun() -> void:
	# Create container for sun (follows camera like stars)
	sun_container = Node3D.new()
	sun_container.name = "SunContainer"
	add_child(sun_container)

	sun_mesh = MeshInstance3D.new()
	sun_mesh.name = "Sun"

	# Create blocky box mesh for sun (flat square, Minecraft-style)
	var box := BoxMesh.new()
	box.size = Vector3(sun_size, sun_size, sun_size * 0.2)  # Flat square
	sun_mesh.mesh = box

	# Sun material (bright yellow-white, unshaded and emissive)
	var sun_material := StandardMaterial3D.new()
	sun_material.albedo_color = Color(1.0, 0.95, 0.7)
	sun_material.emission_enabled = true
	sun_material.emission = Color(1.0, 0.9, 0.6)
	sun_material.emission_energy_multiplier = 2.0
	sun_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sun_mesh.material_override = sun_material

	# Initial position (will be updated based on time)
	sun_mesh.position = Vector3(0, sun_distance, 0)

	sun_container.add_child(sun_mesh)


func _on_time_changed(hour: int, minute: int) -> void:
	_update_environment()
	_update_night_sky()


func _on_day_changed(day: int) -> void:
	_update_moon_phase()


func _update_environment() -> void:
	if not time_manager:
		return

	var progress: float = time_manager.get_day_progress()

	# Determine which colors to blend between
	var from_key: String
	var to_key: String
	var blend: float

	if progress < 0.25:  # Midnight to 6 AM
		from_key = "night"
		to_key = "dawn"
		blend = progress / 0.25
	elif progress < 0.3:  # 6 AM to ~7 AM (dawn)
		from_key = "dawn"
		to_key = "day"
		blend = (progress - 0.25) / 0.05
	elif progress < 0.7:  # 7 AM to ~5 PM (day)
		from_key = "day"
		to_key = "day"
		blend = 0.0
	elif progress < 0.8:  # 5 PM to ~7 PM (dusk)
		from_key = "day"
		to_key = "dusk"
		blend = (progress - 0.7) / 0.1
	elif progress < 0.85:  # 7 PM to ~8 PM
		from_key = "dusk"
		to_key = "night"
		blend = (progress - 0.8) / 0.05
	else:  # 8 PM to midnight
		from_key = "night"
		to_key = "night"
		blend = 0.0

	# Update sky colors
	var from_sky: Color = sky_colors[from_key]
	var to_sky: Color = sky_colors[to_key]
	var sky_color: Color = from_sky.lerp(to_sky, blend)
	sky_material.sky_top_color = sky_color
	sky_material.sky_horizon_color = sky_color.lightened(0.2)
	sky_material.ground_horizon_color = sky_color.lightened(0.1)

	# Update ambient light
	var from_ambient: Color = ambient_colors[from_key]
	var to_ambient: Color = ambient_colors[to_key]
	var ambient_color: Color = from_ambient.lerp(to_ambient, blend)
	environment.ambient_light_color = ambient_color

	# Update sun light
	if sun_light:
		var from_sun: Color = sun_colors[from_key]
		var to_sun: Color = sun_colors[to_key]
		var sun_color: Color = from_sun.lerp(to_sun, blend)
		var from_intensity: float = sun_intensities[from_key]
		var to_intensity: float = sun_intensities[to_key]
		var sun_intensity: float = lerpf(from_intensity, to_intensity, blend)

		sun_light.light_color = sun_color
		sun_light.light_energy = sun_intensity

		# Rotate sun based on time
		var sun_angle: float = time_manager.get_sun_angle()
		sun_light.rotation.x = -sun_angle + PI / 2  # Overhead at noon

	# Update fog color to match sky horizon (time of day)
	var from_fog: Color = fog_colors[from_key]
	var to_fog: Color = fog_colors[to_key]
	var fog_color: Color = from_fog.lerp(to_fog, blend)
	environment.fog_light_color = fog_color

	# Update blocky sun mesh position
	_update_sun_position(progress)


func _update_sun_position(progress: float) -> void:
	if not sun_mesh:
		return

	# Sun is visible during day (roughly 6 AM to 8 PM)
	# progress: 0.25 = 6 AM, 0.5 = noon, 0.83 = 8 PM
	var is_daytime: bool = progress >= 0.25 and progress < 0.83

	if is_daytime:
		sun_mesh.visible = true

		# Calculate sun arc across sky
		# Map 0.25-0.83 to 0-PI (sunrise to sunset)
		var day_progress: float = (progress - 0.25) / 0.58  # 0 at sunrise, 1 at sunset
		var sun_arc_angle: float = day_progress * PI  # 0 to PI

		# Sun rises in east (+X), peaks overhead, sets in west (-X)
		var sun_x: float = cos(sun_arc_angle) * sun_distance
		var sun_y: float = sin(sun_arc_angle) * sun_distance * 0.8 + 50.0  # Arc height
		var sun_z: float = -sun_distance * 0.3  # Slightly in front

		sun_mesh.position = Vector3(sun_x, sun_y, sun_z)
	else:
		sun_mesh.visible = false


func _update_celestial_facing() -> void:
	# Make sun and moon face camera position (at origin of their containers)
	# This creates a billboard effect while keeping the blocky aesthetic
	if sun_mesh and sun_mesh.visible:
		# Look at the container origin (where camera is)
		var dir_to_camera: Vector3 = -sun_mesh.position.normalized()
		if dir_to_camera.length() > 0.1:
			sun_mesh.look_at(sun_mesh.position + dir_to_camera * 10.0, Vector3.UP)

	if moon_mesh and moon_mesh.visible:
		var dir_to_camera: Vector3 = -moon_mesh.position.normalized()
		if dir_to_camera.length() > 0.1:
			moon_mesh.look_at(moon_mesh.position + dir_to_camera * 10.0, Vector3.UP)


func _update_moon_phase() -> void:
	if not time_manager or not moon_shadow:
		return

	# Calculate moon phase from day (0-7, starts at full moon on day 1)
	var day: int = time_manager.get_current_day()
	current_moon_phase = (day - 1) % LUNAR_CYCLE_DAYS

	# Update shadow position and size based on phase
	# Shadow covers different portions of the moon for each phase
	var shadow_visible: bool = true
	var shadow_x: float = 0.0  # Local X offset
	var shadow_scale_x: float = 0.55  # Width of shadow

	match current_moon_phase:
		0:  # Full Moon - no shadow
			shadow_visible = false
		1:  # Waning Gibbous - small shadow on right
			shadow_x = moon_size * 0.35
			shadow_scale_x = 0.35
		2:  # Last Quarter - half shadow on right
			shadow_x = moon_size * 0.27
			shadow_scale_x = 0.55
		3:  # Waning Crescent - large shadow on right
			shadow_x = moon_size * 0.1
			shadow_scale_x = 0.85
		4:  # New Moon - full shadow
			shadow_x = 0.0
			shadow_scale_x = 1.1
		5:  # Waxing Crescent - large shadow on left
			shadow_x = -moon_size * 0.1
			shadow_scale_x = 0.85
		6:  # First Quarter - half shadow on left
			shadow_x = -moon_size * 0.27
			shadow_scale_x = 0.55
		7:  # Waxing Gibbous - small shadow on left
			shadow_x = -moon_size * 0.35
			shadow_scale_x = 0.35

	moon_shadow.visible = shadow_visible
	if shadow_visible:
		moon_shadow.position = Vector3(shadow_x, 0, -moon_size * 0.05)  # Slightly in front
		var shadow_mesh: BoxMesh = moon_shadow.mesh as BoxMesh
		if shadow_mesh:
			shadow_mesh.size = Vector3(moon_size * shadow_scale_x, moon_size * 1.05, moon_size * 0.2)

	print("[EnvironmentManager] Moon phase: %s (day %d)" % [MOON_PHASES[current_moon_phase], day])


func get_moon_phase_name() -> String:
	return MOON_PHASES[current_moon_phase]


func get_moon_phase() -> int:
	return current_moon_phase


## Set weather overlay effects.
func set_weather_overlay(weather: String) -> void:
	current_weather = weather
	_apply_weather_effects()
	_update_night_sky()  # Weather affects star visibility


func _apply_weather_effects() -> void:
	var color_mod: Color = weather_color_modifiers.get(current_weather, Color(1.0, 1.0, 1.0))
	var intensity_mod: float = weather_intensity_modifiers.get(current_weather, 1.0)
	var weather_fog: float = weather_fog_density.get(current_weather, 0.0)
	var weather_depth_end: float = weather_fog_depth_end.get(current_weather, base_fog_depth_end)

	# Weather reduces visibility by adjusting fog depth end
	environment.fog_depth_end = weather_depth_end

	# Weather fog adds extra haze density on top of depth fog
	environment.fog_density = weather_fog

	# Weather modifies fog color slightly
	if weather_fog > 0.005:
		# Heavy weather tints the fog
		var current_fog: Color = environment.fog_light_color
		environment.fog_light_color = current_fog.lerp(color_mod.lightened(0.2), 0.4)

	# Adjust ambient light based on weather
	var base_ambient: Color = environment.ambient_light_color
	environment.ambient_light_energy = 1.0 * intensity_mod

	# Adjust sun intensity for weather
	if sun_light:
		var base_intensity: float = sun_light.light_energy
		# Store base intensity from time-of-day and apply weather modifier
		# We'll modulate the light color slightly
		sun_light.light_color = sun_light.light_color.lerp(color_mod, 0.3)

	# Adjust sky colors for weather
	if sky_material:
		var base_sky: Color = sky_material.sky_top_color
		sky_material.sky_top_color = base_sky.lerp(color_mod, 0.2)

	print("[EnvironmentManager] Applied weather overlay: %s" % current_weather)


func _update_night_sky() -> void:
	if not time_manager or not stars_container:
		return

	var progress: float = time_manager.get_day_progress()

	# Calculate night visibility (0 = day, 1 = full night)
	# Night is roughly 8PM (0.83) to 6AM (0.25)
	var night_alpha: float = 0.0

	if progress < 0.25:  # Midnight to 6 AM - full night
		night_alpha = 1.0
	elif progress < 0.30:  # 6 AM to ~7 AM - fade out at dawn
		night_alpha = 1.0 - ((progress - 0.25) / 0.05)
	elif progress < 0.75:  # Day - no stars
		night_alpha = 0.0
	elif progress < 0.83:  # ~6 PM to 8 PM - fade in at dusk
		night_alpha = (progress - 0.75) / 0.08
	else:  # 8 PM to midnight - full night
		night_alpha = 1.0

	# Apply weather reduction (clouds obscure stars)
	var weather_visibility: float = 1.0
	match current_weather:
		"Storm":
			weather_visibility = 0.0
		"Rain":
			weather_visibility = 0.3
		"Fog":
			weather_visibility = 0.2
		"Cold Snap":
			weather_visibility = 0.9  # Clear cold nights show stars well

	night_alpha *= weather_visibility

	# Update star visibility
	if stars_particles:
		var star_mesh: QuadMesh = stars_particles.draw_pass_1 as QuadMesh
		if star_mesh and star_mesh.material:
			var mat: StandardMaterial3D = star_mesh.material as StandardMaterial3D
			if mat:
				mat.albedo_color.a = night_alpha * 0.9

	# Update moon visibility and position
	if moon_mesh:
		var moon_mat: StandardMaterial3D = moon_mesh.material_override as StandardMaterial3D
		if moon_mat:
			moon_mat.albedo_color.a = night_alpha
			moon_mat.emission_energy_multiplier = night_alpha * 0.5

		# Move moon across night sky
		# Moon rises in east (positive X), sets in west (negative X)
		var moon_angle: float = 0.0
		if progress < 0.25:  # Midnight to 6 AM
			# Moon going from overhead to setting
			moon_angle = PI * (0.5 + progress / 0.25 * 0.5)  # PI/2 to PI
		elif progress >= 0.75:  # 6 PM to midnight
			# Moon rising to overhead
			moon_angle = PI * ((progress - 0.75) / 0.25 * 0.5)  # 0 to PI/2

		var moon_x: float = cos(moon_angle) * moon_distance
		var moon_y: float = sin(moon_angle) * moon_distance * 0.6 + 50.0  # Keep above horizon
		var moon_z: float = -moon_distance * 0.5
		moon_mesh.position = Vector3(moon_x, moon_y, moon_z)
		moon_mesh.visible = night_alpha > 0.05

	# Update moon light
	if moon_light:
		moon_light.light_energy = night_alpha * 0.15
		# Point moon light downward from moon direction
		if moon_mesh:
			moon_light.look_at_from_position(moon_mesh.position, Vector3.ZERO)


func _process(_delta: float) -> void:
	# Make sky elements follow camera position (but not rotation)
	# Use cached camera reference for performance (avoid get_viewport().get_camera_3d() every frame)
	if not is_instance_valid(cached_camera):
		cached_camera = get_viewport().get_camera_3d()

	if cached_camera:
		var cam_pos: Vector3 = cached_camera.global_position
		if stars_container:
			stars_container.global_position = cam_pos
		if sun_container:
			sun_container.global_position = cam_pos

	# Make sun and moon face camera (billboard-style, but blocky)
	_update_celestial_facing()
