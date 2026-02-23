# Carlston Wilderness Sign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a National Forest Service-style information kiosk near spawn that players interact with to read wilderness regulations (game instructions in disguise).

**Architecture:** A single self-contained `wilderness_sign.gd` script extending `StructureBase` that builds its own 3D mesh and manages its own full-screen overlay UI. The HUD gets two small helper methods to hide/show panels. The sign is spawned by `chunk_manager.gd` when the spawn chunk loads.

**Tech Stack:** GDScript, Godot 4.5, BoxMesh procedural geometry, CanvasLayer overlay

---

### Task 1: Create wilderness_sign.gd — 3D mesh construction

**Files:**
- Create: `scripts/world/wilderness_sign.gd`

**Step 1: Create the script with mesh building**

Create `scripts/world/wilderness_sign.gd`:

```gdscript
extends StructureBase
class_name WildernessSign
## National Forest Service-style information kiosk near spawn.

# Shared materials (static to avoid per-instance allocation)
static var _post_mat: StandardMaterial3D
static var _roof_mat: StandardMaterial3D
static var _board_mat: StandardMaterial3D
static var _header_mat: StandardMaterial3D

var overlay_visible: bool = false
var player_ref: Node = null

# Overlay UI nodes
var overlay_layer: CanvasLayer
var overlay_bg: ColorRect
var overlay_panel: PanelContainer

const HUD_FONT: Font = preload("res://resources/hud_font.tres")


func _ready() -> void:
	structure_type = "wilderness_sign"
	structure_name = "Wilderness Sign"
	interaction_text = "Read Sign"
	super._ready()
	_init_materials()
	_build_mesh()
	_build_overlay()


static func _init_materials() -> void:
	if _post_mat:
		return
	# Dark brown wood posts
	_post_mat = StandardMaterial3D.new()
	_post_mat.albedo_color = Color(0.35, 0.22, 0.12)
	_post_mat.roughness = 0.9

	# Dark green/brown roof
	_roof_mat = StandardMaterial3D.new()
	_roof_mat.albedo_color = Color(0.18, 0.25, 0.15)
	_roof_mat.roughness = 0.85

	# Olive/tan board face
	_board_mat = StandardMaterial3D.new()
	_board_mat.albedo_color = Color(0.55, 0.50, 0.35)
	_board_mat.roughness = 0.8

	# Darker header strip
	_header_mat = StandardMaterial3D.new()
	_header_mat.albedo_color = Color(0.30, 0.28, 0.20)
	_header_mat.roughness = 0.85


func _build_mesh() -> void:
	var mesh_root: Node3D = Node3D.new()
	mesh_root.name = "MeshRoot"
	add_child(mesh_root)

	# Left post
	_add_box(mesh_root, Vector3(-1.3, 1.75, 0), Vector3(0.2, 3.5, 0.2), _post_mat)
	# Right post
	_add_box(mesh_root, Vector3(1.3, 1.75, 0), Vector3(0.2, 3.5, 0.2), _post_mat)

	# Cross beam at top connecting posts
	_add_box(mesh_root, Vector3(0, 3.3, 0), Vector3(2.8, 0.15, 0.22), _post_mat)

	# Angled roof — two slabs forming a shallow V
	var roof_left: MeshInstance3D = _add_box(mesh_root, Vector3(-0.7, 3.65, 0), Vector3(1.6, 0.08, 0.9), _roof_mat)
	roof_left.rotation_degrees.z = 8.0
	var roof_right: MeshInstance3D = _add_box(mesh_root, Vector3(0.7, 3.65, 0), Vector3(1.6, 0.08, 0.9), _roof_mat)
	roof_right.rotation_degrees.z = -8.0

	# Roof ridge cap
	_add_box(mesh_root, Vector3(0, 3.72, 0), Vector3(0.3, 0.06, 0.95), _roof_mat)

	# Main information board
	_add_box(mesh_root, Vector3(0, 2.0, 0.08), Vector3(2.4, 1.5, 0.08), _board_mat)

	# Header strip "INFORMATION"
	_add_box(mesh_root, Vector3(0, 2.85, 0.13), Vector3(2.4, 0.2, 0.04), _header_mat)

	# Board frame edges (thin dark strips)
	_add_box(mesh_root, Vector3(0, 2.76, 0.13), Vector3(2.44, 0.04, 0.04), _post_mat)  # top
	_add_box(mesh_root, Vector3(0, 1.26, 0.13), Vector3(2.44, 0.04, 0.04), _post_mat)  # bottom
	_add_box(mesh_root, Vector3(-1.2, 2.0, 0.13), Vector3(0.04, 1.5, 0.04), _post_mat)  # left
	_add_box(mesh_root, Vector3(1.2, 2.0, 0.13), Vector3(0.04, 1.5, 0.04), _post_mat)  # right

	# Small support braces (angled struts from posts to board)
	var brace_left: MeshInstance3D = _add_box(mesh_root, Vector3(-1.1, 1.0, 0.0), Vector3(0.1, 0.6, 0.12), _post_mat)
	brace_left.rotation_degrees.z = 25.0
	var brace_right: MeshInstance3D = _add_box(mesh_root, Vector3(1.1, 1.0, 0.0), Vector3(0.1, 0.6, 0.12), _post_mat)
	brace_right.rotation_degrees.z = -25.0

	# Collision shape for interaction raycast
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(2.8, 3.5, 0.5)
	collision.shape = shape
	collision.position = Vector3(0, 1.75, 0)
	add_child(collision)


func _add_box(parent: Node3D, pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	box.material = mat
	mi.mesh = box
	mi.position = pos
	parent.add_child(mi)
	return mi
```

**Step 2: Verify no syntax errors**

Open the project in Godot or review the script manually. Ensure all types are annotated per Godot 4.5 requirements.

---

### Task 2: Add overlay UI to wilderness_sign.gd

**Files:**
- Modify: `scripts/world/wilderness_sign.gd` (append overlay methods)

**Step 1: Add the overlay build and show/hide methods**

Append to `wilderness_sign.gd`:

```gdscript
func _build_overlay() -> void:
	# CanvasLayer ensures overlay renders on top of everything
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 100
	overlay_layer.visible = false
	add_child(overlay_layer)

	# Semi-transparent background
	overlay_bg = ColorRect.new()
	overlay_bg.color = Color(0.02, 0.04, 0.02, 0.85)
	overlay_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_layer.add_child(overlay_bg)

	# Outer panel — forest-green border
	var outer_style: StyleBoxFlat = StyleBoxFlat.new()
	outer_style.bg_color = Color(0.15, 0.22, 0.12, 1.0)
	outer_style.corner_radius_top_left = 12
	outer_style.corner_radius_top_right = 12
	outer_style.corner_radius_bottom_left = 12
	outer_style.corner_radius_bottom_right = 12
	outer_style.content_margin_left = 16.0
	outer_style.content_margin_right = 16.0
	outer_style.content_margin_top = 16.0
	outer_style.content_margin_bottom = 16.0

	overlay_panel = PanelContainer.new()
	overlay_panel.add_theme_stylebox_override("panel", outer_style)
	overlay_panel.set_anchors_preset(Control.PRESET_CENTER)
	overlay_panel.anchor_left = 0.1
	overlay_panel.anchor_right = 0.9
	overlay_panel.anchor_top = 0.05
	overlay_panel.anchor_bottom = 0.95
	overlay_layer.add_child(overlay_panel)

	# Inner panel — tan/cream background
	var inner_style: StyleBoxFlat = StyleBoxFlat.new()
	inner_style.bg_color = Color(0.72, 0.68, 0.55, 1.0)
	inner_style.corner_radius_top_left = 8
	inner_style.corner_radius_top_right = 8
	inner_style.corner_radius_bottom_left = 8
	inner_style.corner_radius_bottom_right = 8
	inner_style.content_margin_left = 40.0
	inner_style.content_margin_right = 40.0
	inner_style.content_margin_top = 30.0
	inner_style.content_margin_bottom = 30.0

	var inner_panel: PanelContainer = PanelContainer.new()
	inner_panel.add_theme_stylebox_override("panel", inner_style)
	overlay_panel.add_child(inner_panel)

	# Content VBox
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	inner_panel.add_child(vbox)

	# Title
	var title: Label = Label.new()
	title.text = "CARLSTON WILDERNESS"
	title.add_theme_font_override("font", HUD_FONT)
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(0.30, 0.18, 0.05, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Separator
	var sep: HSeparator = HSeparator.new()
	sep.add_theme_constant_override("separation", 8)
	vbox.add_child(sep)

	# Subtitle
	var subtitle: Label = Label.new()
	subtitle.text = "Welcome to Carlston Wilderness"
	subtitle.add_theme_font_override("font", HUD_FONT)
	subtitle.add_theme_font_size_override("font_size", 36)
	subtitle.add_theme_color_override("font_color", Color(0.25, 0.20, 0.10, 1.0))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	# Spacer
	var spacer1: Control = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer1)

	# Section header
	var section_header: Label = Label.new()
	section_header.text = "REGULATIONS & INFORMATION"
	section_header.add_theme_font_override("font", HUD_FONT)
	section_header.add_theme_font_size_override("font_size", 32)
	section_header.add_theme_color_override("font_color", Color(0.30, 0.18, 0.05, 1.0))
	section_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(section_header)

	# Spacer
	var spacer2: Control = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer2)

	# Regulation items
	var regulations: Array[String] = [
		"Hunting of birds and rabbits is permitted within\nwilderness boundaries.",
		"Swimming areas are unmarked. Exercise caution\nnear water — currents can be dangerous.",
		"Deep pits and sinkholes are present in this area.\nWatch your step.",
		"Collection of wood, stone, and natural resources\nis permitted.",
		"Take care of the wilderness.",
	]

	for reg_text in regulations:
		var reg: Label = Label.new()
		reg.text = "•  " + reg_text
		reg.add_theme_font_override("font", HUD_FONT)
		reg.add_theme_font_size_override("font_size", 28)
		reg.add_theme_color_override("font_color", Color(0.15, 0.12, 0.05, 1.0))
		reg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(reg)

	# Bottom spacer
	var spacer3: Control = Control.new()
	spacer3.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer3)

	# Close hint
	var close_hint: Label = Label.new()
	close_hint.text = "[E] Close"
	close_hint.add_theme_font_override("font", HUD_FONT)
	close_hint.add_theme_font_size_override("font_size", 28)
	close_hint.add_theme_color_override("font_color", Color(0.35, 0.30, 0.18, 0.8))
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(close_hint)


func interact(player: Node) -> bool:
	if not is_active:
		return false

	if overlay_visible:
		_hide_overlay()
	else:
		player_ref = player
		_show_overlay()
	return true


func _input(event: InputEvent) -> void:
	if not overlay_visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_hide_overlay()
		get_viewport().set_input_as_handled()


func _show_overlay() -> void:
	overlay_visible = true
	overlay_layer.visible = true

	# Freeze player movement
	if player_ref and player_ref.has_method("set_resting"):
		player_ref.set_resting(true, self)

	# Hide HUD
	var hud: Node = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("set_overlay_mode"):
		hud.set_overlay_mode(true)


func _hide_overlay() -> void:
	overlay_visible = false
	overlay_layer.visible = false

	# Unfreeze player
	if player_ref and player_ref.has_method("set_resting"):
		player_ref.set_resting(false)

	# Show HUD
	var hud: Node = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("set_overlay_mode"):
		hud.set_overlay_mode(false)

	player_ref = null
```

---

### Task 3: Add HUD overlay mode

**Files:**
- Modify: `scripts/ui/hud.gd`

**Step 1: Add the HUD to the "hud" group and add set_overlay_mode()**

In `hud.gd`, in the `_ready()` function, add:
```gdscript
add_to_group("hud")
```

Then add this new method at the end of the file:

```gdscript
func set_overlay_mode(enabled: bool) -> void:
	## Hide or show all HUD panels for full-screen overlay display.
	var panels: Array[Control] = [
		get_node_or_null("TimePanel"),
		get_node_or_null("StatsPanel"),
		get_node_or_null("EquippedPanel"),
		inventory_panel,
		interaction_prompt_panel,
		notification_panel,
	]
	# Also hide compass if it exists
	var compass: Control = get_node_or_null("CompassPanel")
	if compass:
		panels.append(compass)

	for panel in panels:
		if panel:
			panel.visible = not enabled
```

**Step 2: Find `_ready()` in hud.gd and add the group registration**

Search for `func _ready()` in hud.gd and add `add_to_group("hud")` as the first line inside it.

---

### Task 4: Spawn the sign from chunk_manager.gd

**Files:**
- Modify: `scripts/world/chunk_manager.gd`

**Step 1: Add sign script reference and spawn flag**

Near the other script/scene vars (around line 173), add:
```gdscript
var wilderness_sign_script: GDScript
var wilderness_sign_spawned: bool = false
```

**Step 2: Load the script in `_load_scenes()`**

In `_load_scenes()` (line 997), after the cave_entrance_script load (line 1014), add:
```gdscript
wilderness_sign_script = load("res://scripts/world/wilderness_sign.gd")
```

**Step 3: Spawn the sign when the spawn chunk loads**

In the chunk loading flow, after `_spawn_cave_entrances_in_chunk` is called (line 1477), add a call to spawn the sign:
```gdscript
_spawn_wilderness_sign(chunk_min_x, chunk_max_x, chunk_min_z, chunk_max_z)
```

Then add the spawn method:
```gdscript
func _spawn_wilderness_sign(min_x: float, max_x: float, min_z: float, max_z: float) -> void:
	if wilderness_sign_spawned or not wilderness_sign_script:
		return

	# Sign position: (6, terrain_y, -4) — near spawn, facing toward player
	var sign_x: float = 6.0
	var sign_z: float = -4.0

	# Only spawn when the chunk containing the sign position loads
	if sign_x < min_x or sign_x >= max_x or sign_z < min_z or sign_z >= max_z:
		return

	var sign_node: StaticBody3D = StaticBody3D.new()
	sign_node.set_script(wilderness_sign_script)
	sign_node.name = "WildernessSign"

	var terrain_y: float = get_height_at(sign_x, sign_z)
	sign_node.position = Vector3(sign_x, terrain_y, sign_z)

	# Face toward spawn (0,0) — rotate to face roughly toward player
	sign_node.rotation.y = atan2(-sign_x, -sign_z)

	add_child(sign_node)
	wilderness_sign_spawned = true
```

**Step 4: Commit**

```bash
git add scripts/world/wilderness_sign.gd scripts/ui/hud.gd scripts/world/chunk_manager.gd
git commit -m "Add Carlston Wilderness information sign near spawn"
```

---

### Task 5: Update DEV_LOG.md

**Files:**
- Modify: `DEV_LOG.md`

**Step 1: Add session entry**

Add a new session entry documenting the wilderness sign feature: 3D kiosk mesh, interaction overlay, HUD integration, and spawn placement.
