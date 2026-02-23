# Sky Improvements: Blocky Clouds & Horizon Haze - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add blocky voxel-style clouds and horizon haze to make the sky more realistic and weather-responsive.

**Architecture:** New `cloud_manager.gd` manages a pool of 30 BoxMesh cloud clusters that drift across the sky, with weather controlling count/color/speed. Horizon haze is a cylinder mesh with gradient shader added to `environment_manager.gd`. Both follow the player's XZ position.

**Tech Stack:** GDScript, Godot 4.5 (BoxMesh, StandardMaterial3D, ShaderMaterial, CylinderMesh)

---

### Task 1: Create Cloud Manager with Static Cloud Pool

**Files:**
- Create: `scripts/world/cloud_manager.gd`

**Step 1: Create the cloud manager script**

```gdscript
extends Node3D
class_name CloudManager
## Manages blocky voxel-style clouds that drift across the sky.
## Clouds respond to weather changes and time-of-day lighting.

# Cloud container that follows the player
var cloud_container: Node3D

# Pool of cloud cluster Node3Ds
var cloud_pool: Array[Node3D] = []
const MAX_CLOUDS: int = 30

# Shared static material for all cloud boxes (performance)
static var cloud_material: StandardMaterial3D

# Cloud field settings
const CLOUD_ALTITUDE: float = 100.0  # Height above player
const CLOUD_FIELD_RADIUS: float = 250.0  # How far clouds spread from center
const WRAP_MARGIN: float = 20.0  # Extra distance before wrapping

# Wind / drift
var wind_direction: Vector3 = Vector3(1.0, 0.0, 0.3).normalized()
var wind_speed: float = 2.5  # Units per second

# Weather state
var target_cloud_count: int = 8
var target_cloud_color: Color = Color(0.95, 0.95, 0.97)
var target_cloud_alpha: float = 0.7
var target_wind_speed: float = 2.5

# Current interpolated state
var current_cloud_alpha: float = 0.7
var current_cloud_color: Color = Color(0.95, 0.95, 0.97)

# Time-of-day tint
var time_tint: Color = Color(1.0, 1.0, 1.0)
var night_alpha_multiplier: float = 1.0

# Cached camera reference
var cached_camera: Camera3D = null

# Weather config: [active_count, color, alpha, min_speed, max_speed]
var weather_cloud_config: Dictionary = {
	"Clear": [8, Color(0.95, 0.95, 0.97), 0.7, 2.0, 3.0],
	"Rain": [18, Color(0.6, 0.6, 0.65), 0.85, 3.0, 4.0],
	"Storm": [28, Color(0.35, 0.35, 0.4), 0.95, 5.0, 7.0],
	"Fog": [5, Color(0.8, 0.8, 0.82), 0.4, 1.0, 2.0],
	"Heat Wave": [0, Color(1.0, 1.0, 1.0), 0.0, 0.0, 0.0],
	"Cold Snap": [10, Color(0.85, 0.88, 0.95), 0.6, 2.0, 3.0],
}


func _ready() -> void:
	cloud_container = Node3D.new()
	cloud_container.name = "CloudContainer"
	add_child(cloud_container)

	_init_shared_material()
	_create_cloud_pool()
	_apply_weather("Clear")

	# Connect to weather manager signal
	var weather_manager: Node = _find_weather_manager()
	if weather_manager:
		weather_manager.weather_changed.connect(_on_weather_changed)
		print("[CloudManager] Connected to WeatherManager")

	# Connect to time manager for time-of-day tinting
	var time_manager: Node = _find_time_manager()
	if time_manager and time_manager.has_signal("time_changed"):
		time_manager.time_changed.connect(_on_time_changed)

	print("[CloudManager] Initialized with %d cloud clusters" % MAX_CLOUDS)


func _find_weather_manager() -> Node:
	# Walk up to find WeatherManager sibling
	var parent: Node = get_parent()
	if parent:
		parent = parent.get_parent()  # CloudManager is child of EnvironmentManager
	if parent:
		return parent.get_node_or_null("WeatherManager")
	return null


func _find_time_manager() -> Node:
	var parent: Node = get_parent()
	if parent:
		parent = parent.get_parent()
	if parent:
		return parent.get_node_or_null("TimeManager")
	return null


func _init_shared_material() -> void:
	if cloud_material:
		return
	cloud_material = StandardMaterial3D.new()
	cloud_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cloud_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cloud_material.albedo_color = Color(0.95, 0.95, 0.97, 0.7)
	cloud_material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Visible from below too


func _create_cloud_pool() -> void:
	for i: int in range(MAX_CLOUDS):
		var cluster: Node3D = _build_cloud_cluster()
		cluster.visible = false
		cloud_container.add_child(cluster)
		cloud_pool.append(cluster)

		# Scatter initial positions randomly across the field
		var angle: float = randf() * TAU
		var dist: float = randf() * CLOUD_FIELD_RADIUS
		cluster.position = Vector3(
			cos(angle) * dist,
			0.0,
			sin(angle) * dist
		)


func _build_cloud_cluster() -> Node3D:
	var cluster: Node3D = Node3D.new()
	cluster.name = "Cloud"

	# Base box - the main body of the cloud
	var base: MeshInstance3D = _create_cloud_box(
		Vector3(randf_range(10.0, 14.0), randf_range(1.5, 2.5), randf_range(6.0, 10.0)),
		Vector3.ZERO
	)
	cluster.add_child(base)

	# Add 3-7 additional boxes for puffy shape
	var extra_count: int = randi_range(3, 7)
	for j: int in range(extra_count):
		var size: Vector3 = Vector3(
			randf_range(4.0, 8.0),
			randf_range(1.0, 2.5),
			randf_range(4.0, 6.0)
		)
		var offset: Vector3 = Vector3(
			randf_range(-5.0, 5.0),
			randf_range(-0.5, 1.5),
			randf_range(-3.0, 3.0)
		)
		var box: MeshInstance3D = _create_cloud_box(size, offset)
		cluster.add_child(box)

	return cluster


func _create_cloud_box(size: Vector3, offset: Vector3) -> MeshInstance3D:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.material_override = cloud_material
	mesh_instance.position = offset
	return mesh_instance


func _process(delta: float) -> void:
	# Follow player XZ, fixed altitude above
	if not is_instance_valid(cached_camera):
		cached_camera = get_viewport().get_camera_3d()

	if cached_camera:
		var cam_pos: Vector3 = cached_camera.global_position
		cloud_container.global_position = Vector3(cam_pos.x, cam_pos.y + CLOUD_ALTITUDE, cam_pos.z)

	# Drift all visible clouds
	for cloud: Node3D in cloud_pool:
		if not cloud.visible:
			continue
		cloud.position += wind_direction * wind_speed * delta

		# Wrap clouds that drift too far from center
		var dist_from_center: float = Vector2(cloud.position.x, cloud.position.z).length()
		if dist_from_center > CLOUD_FIELD_RADIUS + WRAP_MARGIN:
			# Wrap to opposite side
			var wrap_dir: Vector2 = -Vector2(cloud.position.x, cloud.position.z).normalized()
			var wrap_dist: float = CLOUD_FIELD_RADIUS * randf_range(0.7, 1.0)
			cloud.position.x = wrap_dir.x * wrap_dist
			cloud.position.z = wrap_dir.y * wrap_dist
			# Randomize Y slightly on wrap
			cloud.position.y = randf_range(-3.0, 3.0)


func _on_weather_changed(weather_type: String) -> void:
	_apply_weather(weather_type)


func _apply_weather(weather_type: String) -> void:
	var config: Array = weather_cloud_config.get(weather_type, weather_cloud_config["Clear"])

	target_cloud_count = config[0]
	target_cloud_color = config[1]
	target_cloud_alpha = config[2]
	var speed_min: float = config[3]
	var speed_max: float = config[4]
	target_wind_speed = randf_range(speed_min, speed_max)

	# Randomize wind direction on weather change
	var angle: float = randf() * TAU
	wind_direction = Vector3(cos(angle), 0.0, sin(angle))

	# Tween transition
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "wind_speed", target_wind_speed, 3.0)
	tween.tween_property(self, "current_cloud_alpha", target_cloud_alpha, 3.0)
	tween.tween_property(self, "current_cloud_color", target_cloud_color, 3.0)
	tween.set_parallel(false)
	tween.tween_callback(_update_cloud_visibility)

	# Update material color immediately starts transitioning
	_start_material_transition()

	print("[CloudManager] Weather: %s -> %d clouds, speed %.1f" % [weather_type, target_cloud_count, target_wind_speed])


func _start_material_transition() -> void:
	# Use a separate tween to update the material each frame during transition
	var mat_tween: Tween = create_tween()
	mat_tween.tween_method(_update_material_color, 0.0, 1.0, 3.0)


func _update_material_color(progress: float) -> void:
	if cloud_material:
		var tinted_color: Color = current_cloud_color * time_tint
		cloud_material.albedo_color = Color(
			tinted_color.r, tinted_color.g, tinted_color.b,
			current_cloud_alpha * night_alpha_multiplier
		)


func _update_cloud_visibility() -> void:
	# Show/hide clouds based on target count
	for i: int in range(MAX_CLOUDS):
		cloud_pool[i].visible = i < target_cloud_count


func _on_time_changed(hour: int, minute: int) -> void:
	# Update time-of-day tinting
	var time_manager: Node = _find_time_manager()
	if not time_manager:
		return

	var progress: float = time_manager.get_day_progress()

	# Calculate time tint and night multiplier
	if progress < 0.25:  # Night to dawn
		var blend: float = progress / 0.25
		time_tint = Color(0.4, 0.4, 0.6).lerp(Color(1.0, 0.8, 0.7), blend)
		night_alpha_multiplier = lerpf(0.3, 0.8, blend)
	elif progress < 0.3:  # Dawn to day
		var blend: float = (progress - 0.25) / 0.05
		time_tint = Color(1.0, 0.8, 0.7).lerp(Color(1.0, 1.0, 1.0), blend)
		night_alpha_multiplier = lerpf(0.8, 1.0, blend)
	elif progress < 0.7:  # Day
		time_tint = Color(1.0, 1.0, 1.0)
		night_alpha_multiplier = 1.0
	elif progress < 0.8:  # Day to dusk
		var blend: float = (progress - 0.7) / 0.1
		time_tint = Color(1.0, 1.0, 1.0).lerp(Color(1.0, 0.7, 0.5), blend)
		night_alpha_multiplier = lerpf(1.0, 0.8, blend)
	elif progress < 0.85:  # Dusk to night
		var blend: float = (progress - 0.8) / 0.05
		time_tint = Color(1.0, 0.7, 0.5).lerp(Color(0.4, 0.4, 0.6), blend)
		night_alpha_multiplier = lerpf(0.8, 0.3, blend)
	else:  # Night
		time_tint = Color(0.4, 0.4, 0.6)
		night_alpha_multiplier = 0.3

	# Apply tint to material
	_update_material_color(1.0)
```

**Step 2: Verify the script has no syntax errors**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit 2>&1 | head -20`
Expected: No GDScript errors related to cloud_manager.gd

**Step 3: Commit**

```bash
git add scripts/world/cloud_manager.gd
git commit -m "Add cloud manager with blocky voxel cloud pool"
```

---

### Task 2: Wire Cloud Manager into Scene Tree

**Files:**
- Modify: `scenes/main.tscn`

**Step 1: Add CloudManager as child of EnvironmentManager in main.tscn**

The cloud manager needs to be added as a child node of EnvironmentManager. Since .tscn files are complex, use Godot's scene format to add a new node entry.

Add after the EnvironmentManager node definition in `scenes/main.tscn`:

```
[node name="CloudManager" type="Node3D" parent="EnvironmentManager"]
script = ExtResource("<cloud_manager_id>")
```

This requires:
1. Adding an `ext_resource` entry for `scripts/world/cloud_manager.gd`
2. Adding the node entry as a child of EnvironmentManager

**Step 2: Test in-game**

Run the game, verify:
- Clouds appear in the sky as white blocky shapes
- They drift slowly
- They wrap around when far from the player

**Step 3: Commit**

```bash
git add scenes/main.tscn
git commit -m "Wire cloud manager into scene tree"
```

---

### Task 3: Add Horizon Haze to Environment Manager

**Files:**
- Modify: `scripts/world/environment_manager.gd`

**Step 1: Add horizon haze mesh and shader to environment_manager.gd**

Add these variables near the top (after the existing vars):

```gdscript
# Horizon haze
var haze_mesh: MeshInstance3D
var haze_material: ShaderMaterial

# Haze colors for different times of day
var haze_colors: Dictionary = {
	"dawn": Color(1.0, 0.6, 0.4),
	"day": Color(0.7, 0.8, 0.95),
	"dusk": Color(0.95, 0.45, 0.3),
	"night": Color(0.1, 0.1, 0.25)
}
var haze_alphas: Dictionary = {
	"dawn": 0.3,
	"day": 0.15,
	"dusk": 0.35,
	"night": 0.1
}
# Weather modifiers for haze
var weather_haze_alpha_multiplier: Dictionary = {
	"Clear": 1.0,
	"Rain": 1.3,
	"Storm": 1.5,
	"Fog": 2.5,
	"Heat Wave": 1.2,
	"Cold Snap": 1.1
}
var weather_haze_color_tint: Dictionary = {
	"Clear": Color(1.0, 1.0, 1.0),
	"Rain": Color(0.7, 0.75, 0.85),
	"Storm": Color(0.5, 0.5, 0.55),
	"Fog": Color(0.85, 0.85, 0.88),
	"Heat Wave": Color(1.1, 0.95, 0.8),
	"Cold Snap": Color(0.85, 0.9, 1.0)
}
```

Add a `_setup_horizon_haze()` method:

```gdscript
func _setup_horizon_haze() -> void:
	haze_mesh = MeshInstance3D.new()
	haze_mesh.name = "HorizonHaze"

	# Large inverted cylinder around the player
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = 400.0
	cylinder.bottom_radius = 400.0
	cylinder.height = 60.0
	cylinder.radial_segments = 32
	cylinder.rings = 1
	haze_mesh.mesh = cylinder

	# Create shader for vertical gradient
	var shader: Shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never;

uniform vec4 haze_color : source_color = vec4(0.7, 0.8, 0.95, 0.15);
uniform float haze_intensity : hint_range(0.0, 1.0) = 0.15;

void fragment() {
	// UV.y goes 0 (bottom) to 1 (top) on cylinder
	// Fade from solid at bottom to transparent at top
	float gradient = 1.0 - UV.y;
	gradient = gradient * gradient;  // Quadratic falloff for softer transition

	ALBEDO = haze_color.rgb;
	ALPHA = gradient * haze_intensity;
}
"""

	haze_material = ShaderMaterial.new()
	haze_material.shader = shader
	haze_material.set_shader_parameter("haze_color", Color(0.7, 0.8, 0.95, 0.15))
	haze_material.set_shader_parameter("haze_intensity", 0.15)

	haze_mesh.material_override = haze_material

	# Position: bottom of cylinder at roughly horizon level
	haze_mesh.position = Vector3(0, -10, 0)

	add_child(haze_mesh)
```

Call `_setup_horizon_haze()` at the end of `_setup_night_sky()`.

Add haze update to `_update_environment()` method — add a call to `_update_haze()` at the end:

```gdscript
func _update_haze() -> void:
	if not haze_material or not time_manager:
		return

	var progress: float = time_manager.get_day_progress()

	# Calculate haze color and alpha based on time of day (same blending logic as sky)
	var from_key: String
	var to_key: String
	var blend: float

	if progress < 0.25:
		from_key = "night"
		to_key = "dawn"
		blend = progress / 0.25
	elif progress < 0.3:
		from_key = "dawn"
		to_key = "day"
		blend = (progress - 0.25) / 0.05
	elif progress < 0.7:
		from_key = "day"
		to_key = "day"
		blend = 0.0
	elif progress < 0.8:
		from_key = "day"
		to_key = "dusk"
		blend = (progress - 0.7) / 0.1
	elif progress < 0.85:
		from_key = "dusk"
		to_key = "night"
		blend = (progress - 0.8) / 0.05
	else:
		from_key = "night"
		to_key = "night"
		blend = 0.0

	var haze_color: Color = haze_colors[from_key].lerp(haze_colors[to_key], blend)
	var haze_alpha: float = lerpf(haze_alphas[from_key], haze_alphas[to_key], blend)

	# Apply weather modifiers
	var weather_alpha_mult: float = weather_haze_alpha_multiplier.get(current_weather, 1.0)
	var weather_tint: Color = weather_haze_color_tint.get(current_weather, Color(1.0, 1.0, 1.0))

	haze_color = haze_color * weather_tint
	haze_alpha = clampf(haze_alpha * weather_alpha_mult, 0.0, 0.6)

	haze_material.set_shader_parameter("haze_color", haze_color)
	haze_material.set_shader_parameter("haze_intensity", haze_alpha)
```

Also add haze following to the `_process()` method — the haze mesh should track the player like the sky elements:

Add inside `_process()` after the sun_container position update:
```gdscript
		if haze_mesh:
			haze_mesh.global_position = Vector3(cam_pos.x, cam_pos.y - 10.0, cam_pos.z)
```

**Step 2: Verify no syntax errors**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit 2>&1 | head -20`
Expected: No errors

**Step 3: Test in-game**

Run the game, verify:
- Subtle color band visible near the horizon
- Color shifts with time of day (warm at dawn/dusk, blue during day)

**Step 4: Commit**

```bash
git add scripts/world/environment_manager.gd
git commit -m "Add horizon haze with time-of-day and weather integration"
```

---

### Task 4: Visual Tuning and Polish

**Files:**
- Modify: `scripts/world/cloud_manager.gd` (if needed)
- Modify: `scripts/world/environment_manager.gd` (if needed)

**Step 1: Test all weather types**

In-game, use the debug weather command or modify weather_manager to cycle through each weather type. Verify:
- Clear: 6-10 scattered white clouds
- Rain: 15-20 gray clouds, denser coverage
- Storm: 25-30 dark clouds, fast movement, near-total coverage
- Fog: 4-6 pale, thin clouds
- Heat Wave: 0 clouds (clear sky)
- Cold Snap: 8-12 ice-tinted clouds

**Step 2: Test time-of-day transitions**

Speed up time or wait through a full day cycle. Verify:
- Dawn: Clouds tinted warm orange-pink, haze warm
- Day: White clouds, subtle blue haze
- Dusk: Clouds tinted orange-red, haze warm
- Night: Clouds dim and semi-transparent, dark haze

**Step 3: Adjust values as needed**

Tune cloud sizes, alpha values, wind speeds, haze intensity based on visual testing. This is an iterative step.

**Step 4: Commit**

```bash
git add scripts/world/cloud_manager.gd scripts/world/environment_manager.gd
git commit -m "Polish cloud and haze visuals after playtesting"
```

---

### Task 5: Update DEV_LOG.md

**Files:**
- Modify: `DEV_LOG.md`

**Step 1: Add session entry documenting the sky improvements**

Add a new session entry describing:
- Cloud system: 30-cloud pool, BoxMesh clusters, weather integration
- Horizon haze: cylinder with gradient shader, time-of-day colors
- Weather integration table
- Performance notes (shared materials, pre-allocated pool)

**Step 2: Update "Next Session" section**

Remove clouds/sky from planned tasks, add any follow-up polish items discovered during testing.

**Step 3: Commit and push**

```bash
git add DEV_LOG.md
git commit -m "Update dev log with sky improvements session"
git push
```
