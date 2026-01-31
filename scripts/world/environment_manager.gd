extends WorldEnvironment
## Manages sky, lighting, and ambient environment based on time of day.

@export var time_manager_path: NodePath

# Sun/Moon light reference
@export var sun_light_path: NodePath

# Night sky elements
var stars_particles: GPUParticles3D
var moon_mesh: MeshInstance3D
var moon_light: DirectionalLight3D
var stars_container: Node3D

# Night sky settings
@export var star_count: int = 800
@export var moon_size: float = 3.0
@export var moon_distance: float = 200.0

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
	"dawn": 0.5,
	"day": 1.0,
	"dusk": 0.4,
	"night": 0.1
}

var time_manager: Node
var sun_light: DirectionalLight3D
var sky_material: ProceduralSkyMaterial

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
	"Rain": 0.01,
	"Storm": 0.02,
	"Fog": 0.08,
	"Heat Wave": 0.005,
	"Cold Snap": 0.01
}


func _ready() -> void:
	if time_manager_path:
		time_manager = get_node(time_manager_path)
		time_manager.time_changed.connect(_on_time_changed)

	if sun_light_path:
		sun_light = get_node(sun_light_path)

	_setup_environment()
	_setup_night_sky()


func _setup_environment() -> void:
	# Create procedural sky
	sky_material = ProceduralSkyMaterial.new()
	var day_color: Color = sky_colors["day"]
	sky_material.sky_top_color = day_color
	sky_material.sky_horizon_color = day_color.lightened(0.2)
	sky_material.ground_bottom_color = Color(0.2, 0.2, 0.2)
	sky_material.ground_horizon_color = day_color.lightened(0.3)
	sky_material.sun_angle_max = 30.0
	sky_material.sun_curve = 0.15

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
	environment.ssao_enabled = false  # Disable SSAO for softer look
	environment.ssil_enabled = true
	environment.ssil_intensity = 0.7  # More indirect lighting
	environment.glow_enabled = true
	environment.glow_intensity = 0.25


func _setup_night_sky() -> void:
	# Create container for night sky elements (will follow camera)
	stars_container = Node3D.new()
	stars_container.name = "NightSky"
	add_child(stars_container)

	_setup_stars()
	_setup_moon()
	print("[EnvironmentManager] Night sky initialized")


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

	# Create blocky box mesh for moon
	var box := BoxMesh.new()
	box.size = Vector3(moon_size * 2, moon_size * 2, moon_size * 0.5)  # Flat square
	moon_mesh.mesh = box

	# Moon material (pale yellow-white, slightly emissive)
	var moon_material := StandardMaterial3D.new()
	moon_material.albedo_color = Color(0.95, 0.93, 0.85)
	moon_material.emission_enabled = true
	moon_material.emission = Color(0.9, 0.88, 0.8)
	moon_material.emission_energy_multiplier = 0.5
	moon_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	moon_mesh.material_override = moon_material

	# Position moon at distance
	moon_mesh.position = Vector3(0, moon_distance * 0.7, -moon_distance * 0.7)

	stars_container.add_child(moon_mesh)

	# Add subtle moon light
	moon_light = DirectionalLight3D.new()
	moon_light.name = "MoonLight"
	moon_light.light_color = Color(0.7, 0.75, 0.9)
	moon_light.light_energy = 0.0  # Start off, enabled at night
	moon_light.shadow_enabled = false
	add_child(moon_light)


func _on_time_changed(hour: int, minute: int) -> void:
	_update_environment()
	_update_night_sky()


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

	# Update sun
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


## Set weather overlay effects.
func set_weather_overlay(weather: String) -> void:
	current_weather = weather
	_apply_weather_effects()
	_update_night_sky()  # Weather affects star visibility


func _apply_weather_effects() -> void:
	var color_mod: Color = weather_color_modifiers.get(current_weather, Color(1.0, 1.0, 1.0))
	var intensity_mod: float = weather_intensity_modifiers.get(current_weather, 1.0)
	var fog_density: float = weather_fog_density.get(current_weather, 0.0)

	# Apply fog effect
	if fog_density > 0:
		environment.fog_enabled = true
		environment.fog_density = fog_density
		environment.fog_light_color = color_mod.lightened(0.3)
		environment.fog_light_energy = 0.5
	else:
		environment.fog_enabled = false

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
	# Make night sky follow camera position (but not rotation)
	if stars_container:
		var camera: Camera3D = get_viewport().get_camera_3d()
		if camera:
			stars_container.global_position = camera.global_position
