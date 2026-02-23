extends Node3D
class_name Sandstorm
## Periodic sandstorm effect that occurs when the player is in the desert.
## Emits sand particles, reduces movement speed, and notifies the HUD.

signal sandstorm_started()
signal sandstorm_ended()

var is_active: bool = false
var is_in_desert: bool = false
var storm_timer: float = 0.0
var storm_duration: float = 0.0
var next_storm_delay: float = 0.0
var particles: GPUParticles3D

const MIN_DELAY: float = 180.0  # 3 minutes between storms
const MAX_DELAY: float = 300.0  # 5 minutes between storms
const MIN_DURATION: float = 30.0
const MAX_DURATION: float = 45.0
const SPEED_MULTIPLIER: float = 0.7  # 30% speed reduction during storm


func _ready() -> void:
	_setup_particles()
	_randomize_next_storm()


func _process(delta: float) -> void:
	if not is_in_desert:
		if is_active:
			end_storm()
		return

	if is_active:
		storm_timer += delta
		if storm_timer >= storm_duration:
			end_storm()
	else:
		next_storm_delay -= delta
		if next_storm_delay <= 0:
			start_storm()


func set_in_desert(in_desert: bool) -> void:
	is_in_desert = in_desert
	if not in_desert and is_active:
		end_storm()


func start_storm() -> void:
	is_active = true
	storm_timer = 0.0
	storm_duration = randf_range(MIN_DURATION, MAX_DURATION)
	if particles:
		particles.emitting = true
	sandstorm_started.emit()
	print("[Sandstorm] Storm started (duration: %.0fs)" % storm_duration)


func end_storm() -> void:
	is_active = false
	if particles:
		particles.emitting = false
	_randomize_next_storm()
	sandstorm_ended.emit()
	print("[Sandstorm] Storm ended")


func _randomize_next_storm() -> void:
	next_storm_delay = randf_range(MIN_DELAY, MAX_DELAY)


func _setup_particles() -> void:
	particles = GPUParticles3D.new()
	particles.amount = 800
	particles.lifetime = 2.0
	particles.visibility_aabb = AABB(Vector3(-20, -5, -20), Vector3(40, 15, 40))

	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(15.0, 3.0, 15.0)
	mat.direction = Vector3(1.0, -0.1, 0.3)
	mat.spread = 15.0
	mat.initial_velocity_min = 8.0
	mat.initial_velocity_max = 14.0
	mat.gravity = Vector3(2.0, -0.5, 0.5)
	mat.turbulence_enabled = true
	mat.turbulence_noise_strength = 3.0

	particles.process_material = mat

	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(0.08, 0.04, 0.08)
	var mesh_mat: StandardMaterial3D = StandardMaterial3D.new()
	mesh_mat.albedo_color = Color(0.82, 0.72, 0.55, 0.6)
	mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = mesh_mat
	particles.draw_pass_1 = mesh

	particles.emitting = false
	add_child(particles)
