extends Node3D
class_name WeatherParticles
## Controls weather particle effects based on WeatherManager state.
## Attaches to Camera3D for camera-relative particles.

@export var weather_manager_path: NodePath

var weather_manager: WeatherManager

# Particle systems
var rain_particles: GPUParticles3D
var storm_particles: GPUParticles3D
var snow_particles: GPUParticles3D
var dust_particles: GPUParticles3D

# Transition state
var active_particles: GPUParticles3D = null
var transition_tween: Tween = null
const TRANSITION_DURATION: float = 2.0


func _ready() -> void:
	# Get weather manager reference
	if weather_manager_path:
		weather_manager = get_node_or_null(weather_manager_path)
		if weather_manager:
			weather_manager.weather_changed.connect(_on_weather_changed)
			print("[WeatherParticles] Connected to WeatherManager")

	# Setup particle systems
	_setup_rain_particles()
	_setup_storm_particles()
	_setup_snow_particles()
	_setup_dust_particles()

	# Start with all disabled
	_disable_all_particles()


func _setup_rain_particles() -> void:
	rain_particles = GPUParticles3D.new()
	rain_particles.name = "RainParticles"
	rain_particles.amount = 600
	rain_particles.lifetime = 1.5
	rain_particles.explosiveness = 0.0
	rain_particles.randomness = 0.2
	rain_particles.visibility_aabb = AABB(Vector3(-20, -20, -20), Vector3(40, 40, 40))
	rain_particles.emitting = false

	# Create process material
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(15.0, 0.5, 15.0)
	material.direction = Vector3(0, -1, 0)
	material.spread = 5.0
	material.initial_velocity_min = 15.0
	material.initial_velocity_max = 20.0
	material.gravity = Vector3(0, -5, 0)
	rain_particles.process_material = material

	# Create mesh (elongated quad for rain drops)
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.05, 0.3)
	rain_particles.draw_pass_1 = mesh

	# Rain material (semi-transparent blue-white)
	var mesh_material := StandardMaterial3D.new()
	mesh_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_material.albedo_color = Color(0.8, 0.85, 1.0, 0.6)
	mesh_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mesh.material = mesh_material

	# Position above camera
	rain_particles.position = Vector3(0, 10, 0)

	add_child(rain_particles)


func _setup_storm_particles() -> void:
	storm_particles = GPUParticles3D.new()
	storm_particles.name = "StormParticles"
	storm_particles.amount = 1200
	storm_particles.lifetime = 1.2
	storm_particles.explosiveness = 0.0
	storm_particles.randomness = 0.3
	storm_particles.visibility_aabb = AABB(Vector3(-25, -25, -25), Vector3(50, 50, 50))
	storm_particles.emitting = false

	# Create process material
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(18.0, 0.5, 18.0)
	material.direction = Vector3(0.3, -1, 0.2)  # Wind offset
	material.spread = 10.0
	material.initial_velocity_min = 20.0
	material.initial_velocity_max = 30.0
	material.gravity = Vector3(2, -8, 1)  # Wind effect
	storm_particles.process_material = material

	# Create mesh
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.06, 0.35)
	storm_particles.draw_pass_1 = mesh

	# Storm rain material (darker, more opaque)
	var mesh_material := StandardMaterial3D.new()
	mesh_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_material.albedo_color = Color(0.6, 0.65, 0.8, 0.7)
	mesh_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mesh.material = mesh_material

	# Position above camera
	storm_particles.position = Vector3(0, 12, 0)

	add_child(storm_particles)


func _setup_snow_particles() -> void:
	snow_particles = GPUParticles3D.new()
	snow_particles.name = "SnowParticles"
	snow_particles.amount = 400
	snow_particles.lifetime = 4.0
	snow_particles.explosiveness = 0.0
	snow_particles.randomness = 0.5
	snow_particles.visibility_aabb = AABB(Vector3(-25, -25, -25), Vector3(50, 50, 50))
	snow_particles.emitting = false

	# Create process material
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(15.0, 0.5, 15.0)
	material.direction = Vector3(0, -1, 0)
	material.spread = 30.0
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 4.0
	material.gravity = Vector3(0, -0.5, 0)
	# Turbulence for drifting effect
	material.turbulence_enabled = true
	material.turbulence_noise_strength = 2.0
	material.turbulence_noise_speed = Vector3(0.5, 0.2, 0.5)
	material.turbulence_noise_scale = 3.0
	snow_particles.process_material = material

	# Create mesh (square snowflakes)
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.15, 0.15)
	snow_particles.draw_pass_1 = mesh

	# Snow material (white, soft)
	var mesh_material := StandardMaterial3D.new()
	mesh_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_material.albedo_color = Color(1.0, 1.0, 1.0, 0.85)
	mesh_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mesh.material = mesh_material

	# Position above camera
	snow_particles.position = Vector3(0, 12, 0)

	add_child(snow_particles)


func _setup_dust_particles() -> void:
	dust_particles = GPUParticles3D.new()
	dust_particles.name = "DustParticles"
	dust_particles.amount = 150
	dust_particles.lifetime = 6.0
	dust_particles.explosiveness = 0.0
	dust_particles.randomness = 0.8
	dust_particles.visibility_aabb = AABB(Vector3(-30, -15, -30), Vector3(60, 30, 60))
	dust_particles.emitting = false

	# Create process material
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(20.0, 8.0, 20.0)
	material.direction = Vector3(1, 0, 0.5)
	material.spread = 180.0
	material.initial_velocity_min = 0.5
	material.initial_velocity_max = 1.5
	material.gravity = Vector3(0, 0, 0)
	# Gentle turbulence
	material.turbulence_enabled = true
	material.turbulence_noise_strength = 1.0
	material.turbulence_noise_speed = Vector3(0.2, 0.1, 0.2)
	material.turbulence_noise_scale = 5.0
	dust_particles.process_material = material

	# Create mesh (large soft particles)
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.0, 1.0)
	dust_particles.draw_pass_1 = mesh

	# Dust material (grey, very low opacity) - default for fog
	var mesh_material := StandardMaterial3D.new()
	mesh_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_material.albedo_color = Color(0.7, 0.7, 0.7, 0.15)
	mesh_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mesh.material = mesh_material

	# Position around camera
	dust_particles.position = Vector3(0, 0, 0)

	add_child(dust_particles)


func _disable_all_particles() -> void:
	rain_particles.emitting = false
	rain_particles.amount_ratio = 0.0
	storm_particles.emitting = false
	storm_particles.amount_ratio = 0.0
	snow_particles.emitting = false
	snow_particles.amount_ratio = 0.0
	dust_particles.emitting = false
	dust_particles.amount_ratio = 0.0


func _on_weather_changed(weather_type: String) -> void:
	print("[WeatherParticles] Weather changed to: %s" % weather_type)

	# Cancel any existing transition
	if transition_tween and transition_tween.is_valid():
		transition_tween.kill()

	# Determine which particles to use
	var new_particles: GPUParticles3D = null

	match weather_type:
		"Clear":
			new_particles = null
		"Rain":
			new_particles = rain_particles
		"Storm":
			new_particles = storm_particles
		"Cold Snap":
			new_particles = snow_particles
		"Fog":
			_set_dust_color(Color(0.7, 0.7, 0.7, 0.15))  # Grey for fog
			new_particles = dust_particles
		"Heat Wave":
			_set_dust_color(Color(0.9, 0.8, 0.5, 0.12))  # Yellow-tinted for heat
			new_particles = dust_particles

	# Transition particles
	_transition_to_particles(new_particles)


func _set_dust_color(color: Color) -> void:
	var mesh: QuadMesh = dust_particles.draw_pass_1 as QuadMesh
	if mesh and mesh.material:
		var mat: StandardMaterial3D = mesh.material as StandardMaterial3D
		if mat:
			mat.albedo_color = color


func _transition_to_particles(new_particles: GPUParticles3D) -> void:
	transition_tween = create_tween()
	transition_tween.set_parallel(true)

	# Fade out all current particles
	if rain_particles.emitting:
		transition_tween.tween_property(rain_particles, "amount_ratio", 0.0, TRANSITION_DURATION)
	if storm_particles.emitting:
		transition_tween.tween_property(storm_particles, "amount_ratio", 0.0, TRANSITION_DURATION)
	if snow_particles.emitting:
		transition_tween.tween_property(snow_particles, "amount_ratio", 0.0, TRANSITION_DURATION)
	if dust_particles.emitting:
		transition_tween.tween_property(dust_particles, "amount_ratio", 0.0, TRANSITION_DURATION)

	# Fade in new particles
	if new_particles:
		new_particles.emitting = true
		new_particles.amount_ratio = 0.0
		transition_tween.tween_property(new_particles, "amount_ratio", 1.0, TRANSITION_DURATION)

	# After transition, disable particles that are faded out
	transition_tween.set_parallel(false)
	transition_tween.tween_callback(_cleanup_inactive_particles.bind(new_particles))

	active_particles = new_particles


func _cleanup_inactive_particles(keep_active: GPUParticles3D) -> void:
	if rain_particles != keep_active:
		rain_particles.emitting = false
	if storm_particles != keep_active:
		storm_particles.emitting = false
	if snow_particles != keep_active:
		snow_particles.emitting = false
	if dust_particles != keep_active:
		dust_particles.emitting = false
