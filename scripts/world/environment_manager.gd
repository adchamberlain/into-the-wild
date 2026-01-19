extends WorldEnvironment
## Manages sky, lighting, and ambient environment based on time of day.

@export var time_manager_path: NodePath

# Sun/Moon light reference
@export var sun_light_path: NodePath

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


func _ready() -> void:
	if time_manager_path:
		time_manager = get_node(time_manager_path)
		time_manager.time_changed.connect(_on_time_changed)

	if sun_light_path:
		sun_light = get_node(sun_light_path)

	_setup_environment()


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
	environment.ambient_light_energy = 0.5
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_white = 6.0
	environment.ssao_enabled = true
	environment.ssil_enabled = true
	environment.glow_enabled = true
	environment.glow_intensity = 0.3


func _on_time_changed(hour: int, minute: int) -> void:
	_update_environment()


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
