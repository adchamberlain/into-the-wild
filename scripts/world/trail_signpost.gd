extends StaticBody3D
## Trailhead Signpost — the FINAL landmark in the trail-home endgame.
## A weathered wooden signpost with two directional arms. When interacted,
## shows an overlay with a confirmation prompt to leave the wilderness.
## Choosing "Yes" triggers a fade-out transition to the house scene.

signal leave_wilderness_confirmed

const HUD_FONT: Font = preload("res://resources/hud_font.tres")

# State
var has_been_read: bool = false

# Shared static materials (avoid per-instance shader compilation)
static var _post_mat: StandardMaterial3D = null
static var _arm_mat: StandardMaterial3D = null
static var _text_strip_mat: StandardMaterial3D = null
static var _base_mat: StandardMaterial3D = null
static var _materials_initialized: bool = false

# Overlay UI
var overlay_layer: CanvasLayer
var is_overlay_visible: bool = false
var _player_ref: Node = null

# Selection state (0 = "Yes, head home", 1 = "Not yet")
var _selected_index: int = 0
var _yes_label: Label
var _no_label: Label
var _hint_label: Label

# Colors for selection highlighting (park-sign style)
const COLOR_SELECTED: Color = Color(0.15, 0.10, 0.02)  # Dark brown, bold
const COLOR_UNSELECTED: Color = Color(0.50, 0.45, 0.35)  # Faded brown


func _ready() -> void:
	add_to_group("interactable")
	_ensure_shared_materials()
	call_deferred("_build_visuals")
	call_deferred("_build_overlay")


static func _ensure_shared_materials() -> void:
	if _materials_initialized:
		return
	_materials_initialized = true

	# Vertical post: weathered grey-brown
	_post_mat = StandardMaterial3D.new()
	_post_mat.albedo_color = Color(0.40, 0.35, 0.25)
	_post_mat.roughness = 0.9

	# Sign arms: lighter wood
	_arm_mat = StandardMaterial3D.new()
	_arm_mat.albedo_color = Color(0.55, 0.48, 0.35)
	_arm_mat.roughness = 0.85

	# Text strips: dark marks on the arms
	_text_strip_mat = StandardMaterial3D.new()
	_text_strip_mat.albedo_color = Color(0.22, 0.18, 0.12)
	_text_strip_mat.roughness = 0.9

	# Base: packed earth
	_base_mat = StandardMaterial3D.new()
	_base_mat.albedo_color = Color(0.45, 0.38, 0.28)
	_base_mat.roughness = 0.95


func _build_visuals() -> void:
	# ===== VERTICAL POST =====
	var post: MeshInstance3D = MeshInstance3D.new()
	var post_mesh: BoxMesh = BoxMesh.new()
	post_mesh.size = Vector3(0.15, 2.5, 0.15)
	post.mesh = post_mesh
	post.material_override = _post_mat
	post.position = Vector3(0, 1.25, 0)
	add_child(post)

	# ===== SIGN ARM 1 (backward / wilderness) =====
	# Points in the -Z direction, slight downward tilt
	var arm1: MeshInstance3D = MeshInstance3D.new()
	var arm1_mesh: BoxMesh = BoxMesh.new()
	arm1_mesh.size = Vector3(1.2, 0.3, 0.05)
	arm1.mesh = arm1_mesh
	arm1.material_override = _arm_mat
	arm1.position = Vector3(-0.52, 2.2, 0)
	arm1.rotation_degrees = Vector3(0, 0, -5)
	add_child(arm1)

	# Text strips on arm 1 (decorative dark lines suggesting text)
	var strip1a: MeshInstance3D = MeshInstance3D.new()
	var strip1a_mesh: BoxMesh = BoxMesh.new()
	strip1a_mesh.size = Vector3(0.6, 0.03, 0.01)
	strip1a.mesh = strip1a_mesh
	strip1a.material_override = _text_strip_mat
	strip1a.position = Vector3(-0.52, 2.24, 0.03)
	strip1a.rotation_degrees = Vector3(0, 0, -5)
	add_child(strip1a)

	var strip1b: MeshInstance3D = MeshInstance3D.new()
	var strip1b_mesh: BoxMesh = BoxMesh.new()
	strip1b_mesh.size = Vector3(0.45, 0.03, 0.01)
	strip1b.mesh = strip1b_mesh
	strip1b.material_override = _text_strip_mat
	strip1b.position = Vector3(-0.55, 2.16, 0.03)
	strip1b.rotation_degrees = Vector3(0, 0, -5)
	add_child(strip1b)

	# ===== SIGN ARM 2 (forward / Oakland) =====
	# Points in the +X direction, slight downward tilt
	var arm2: MeshInstance3D = MeshInstance3D.new()
	var arm2_mesh: BoxMesh = BoxMesh.new()
	arm2_mesh.size = Vector3(1.4, 0.3, 0.05)
	arm2.mesh = arm2_mesh
	arm2.material_override = _arm_mat
	arm2.position = Vector3(0.62, 1.95, 0)
	arm2.rotation_degrees = Vector3(0, 0, -5)
	add_child(arm2)

	# Text strips on arm 2 (decorative dark lines suggesting text)
	var strip2a: MeshInstance3D = MeshInstance3D.new()
	var strip2a_mesh: BoxMesh = BoxMesh.new()
	strip2a_mesh.size = Vector3(0.7, 0.03, 0.01)
	strip2a.mesh = strip2a_mesh
	strip2a.material_override = _text_strip_mat
	strip2a.position = Vector3(0.62, 1.99, 0.03)
	strip2a.rotation_degrees = Vector3(0, 0, -5)
	add_child(strip2a)

	var strip2b: MeshInstance3D = MeshInstance3D.new()
	var strip2b_mesh: BoxMesh = BoxMesh.new()
	strip2b_mesh.size = Vector3(0.5, 0.03, 0.01)
	strip2b.mesh = strip2b_mesh
	strip2b.material_override = _text_strip_mat
	strip2b.position = Vector3(0.65, 1.91, 0.03)
	strip2b.rotation_degrees = Vector3(0, 0, -5)
	add_child(strip2b)

	# ===== BASE =====
	var base: MeshInstance3D = MeshInstance3D.new()
	var base_mesh: BoxMesh = BoxMesh.new()
	base_mesh.size = Vector3(0.4, 0.05, 0.4)
	base.mesh = base_mesh
	base.material_override = _base_mat
	base.position = Vector3(0, 0.025, 0)
	add_child(base)

	# ===== LIGHT =====
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "SignpostGlow"
	light.light_color = Color(0.9, 0.8, 0.5)
	light.light_energy = 0.5
	light.omni_range = 4.0
	light.shadow_enabled = false
	light.position = Vector3(0, 2.3, 0.3)
	add_child(light)

	# ===== COLLISION =====
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(0.4, 2.5, 0.4)
	collision.shape = shape
	collision.position = Vector3(0, 1.25, 0)
	add_child(collision)


func _build_overlay() -> void:
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 100
	overlay_layer.visible = false
	add_child(overlay_layer)

	# Semi-transparent dark green background (matching wilderness sign)
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.05, 0.10, 0.04, 0.65)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_layer.add_child(bg)

	# Outer panel - forest green (matching wilderness sign)
	var outer_panel: PanelContainer = PanelContainer.new()
	var outer_style: StyleBoxFlat = StyleBoxFlat.new()
	outer_style.bg_color = Color(0.15, 0.22, 0.12)
	outer_style.corner_radius_top_left = 12
	outer_style.corner_radius_top_right = 12
	outer_style.corner_radius_bottom_left = 12
	outer_style.corner_radius_bottom_right = 12
	outer_style.content_margin_left = 40.0
	outer_style.content_margin_right = 40.0
	outer_style.content_margin_top = 30.0
	outer_style.content_margin_bottom = 30.0
	outer_panel.add_theme_stylebox_override("panel", outer_style)
	outer_panel.anchor_left = 0.1
	outer_panel.anchor_right = 0.9
	outer_panel.anchor_top = 0.05
	outer_panel.anchor_bottom = 0.95
	outer_panel.offset_left = 0.0
	outer_panel.offset_right = 0.0
	outer_panel.offset_top = 0.0
	outer_panel.offset_bottom = 0.0
	overlay_layer.add_child(outer_panel)

	# Inner panel - tan/cream (matching wilderness sign)
	var inner_panel: PanelContainer = PanelContainer.new()
	var inner_style: StyleBoxFlat = StyleBoxFlat.new()
	inner_style.bg_color = Color(0.72, 0.68, 0.55)
	inner_style.corner_radius_top_left = 8
	inner_style.corner_radius_top_right = 8
	inner_style.corner_radius_bottom_left = 8
	inner_style.corner_radius_bottom_right = 8
	inner_style.content_margin_left = 40.0
	inner_style.content_margin_right = 40.0
	inner_style.content_margin_top = 30.0
	inner_style.content_margin_bottom = 30.0
	inner_panel.add_theme_stylebox_override("panel", inner_style)
	outer_panel.add_child(inner_panel)

	# Dark brown text color (matching wilderness sign)
	var text_color: Color = Color(0.30, 0.18, 0.05)
	var hint_color: Color = Color(0.45, 0.40, 0.30)

	# Content VBox
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	inner_panel.add_child(vbox)

	# Title: "TRAILHEAD"
	var title: Label = Label.new()
	title.text = "TRAILHEAD"
	title.add_theme_font_override("font", HUD_FONT)
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", text_color)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Separator
	var sep1: HSeparator = HSeparator.new()
	var sep_style: StyleBoxFlat = StyleBoxFlat.new()
	sep_style.bg_color = Color(0.30, 0.18, 0.05, 0.5)
	sep_style.content_margin_top = 2.0
	sep_style.content_margin_bottom = 2.0
	sep1.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep1)

	# Spacer
	var spacer_top: Control = Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer_top)

	# Direction line 1: wilderness (backward)
	var dir1: Label = Label.new()
	dir1.text = "\u2190  Carlston Wilderness"
	dir1.add_theme_font_override("font", HUD_FONT)
	dir1.add_theme_font_size_override("font_size", 36)
	dir1.add_theme_color_override("font_color", text_color)
	dir1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(dir1)

	# Direction line 2: Oakland (forward)
	var dir2: Label = Label.new()
	dir2.text = "Longridge Road, Oakland, California \u2014 225 miles  \u2192"
	dir2.add_theme_font_override("font", HUD_FONT)
	dir2.add_theme_font_size_override("font_size", 36)
	dir2.add_theme_color_override("font_color", text_color)
	dir2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dir2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(dir2)

	# Spacer
	var spacer_dirs: Control = Control.new()
	spacer_dirs.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer_dirs)

	# Separator
	var sep2: HSeparator = HSeparator.new()
	var sep_style2: StyleBoxFlat = StyleBoxFlat.new()
	sep_style2.bg_color = Color(0.30, 0.18, 0.05, 0.5)
	sep_style2.content_margin_top = 2.0
	sep_style2.content_margin_bottom = 2.0
	sep2.add_theme_stylebox_override("separator", sep_style2)
	vbox.add_child(sep2)

	# Expanding spacer above body text to center it vertically
	var spacer_top: Control = Control.new()
	spacer_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer_top)

	# Body text — centered, larger
	var body: Label = Label.new()
	body.text = "The wood is weathered but the letters are still clear. Someone carved this sign a long time ago. This is the way home."
	body.add_theme_font_override("font", HUD_FONT)
	body.add_theme_font_size_override("font_size", 40)
	body.add_theme_color_override("font_color", text_color)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(body)

	# Expanding spacer below body text
	var spacer_mid: Control = Control.new()
	spacer_mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer_mid)

	# Choice: "Yes, head home"
	_yes_label = Label.new()
	_yes_label.text = "\u25b6  Yes, head home"
	_yes_label.add_theme_font_override("font", HUD_FONT)
	_yes_label.add_theme_font_size_override("font_size", 40)
	_yes_label.add_theme_color_override("font_color", COLOR_SELECTED)
	_yes_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_yes_label)

	# Choice: "Not yet"
	_no_label = Label.new()
	_no_label.text = "   Not yet"
	_no_label.add_theme_font_override("font", HUD_FONT)
	_no_label.add_theme_font_size_override("font_size", 40)
	_no_label.add_theme_color_override("font_color", COLOR_UNSELECTED)
	_no_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_no_label)

	# Spacer before hint
	var spacer_bottom: Control = Control.new()
	spacer_bottom.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer_bottom)

	# Navigation hint (updated dynamically for controller/keyboard)
	_hint_label = Label.new()
	_hint_label.add_theme_font_override("font", HUD_FONT)
	_hint_label.add_theme_font_size_override("font_size", 28)
	_hint_label.add_theme_color_override("font_color", hint_color)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_hint_label)
	_update_hint_text()


func _update_selection_visuals() -> void:
	if _yes_label:
		_yes_label.text = ("\u25b6  Yes, head home" if _selected_index == 0
			else "   Yes, head home")
		_yes_label.add_theme_color_override("font_color",
			COLOR_SELECTED if _selected_index == 0 else COLOR_UNSELECTED)
	if _no_label:
		_no_label.text = ("\u25b6  Not yet" if _selected_index == 1
			else "   Not yet")
		_no_label.add_theme_color_override("font_color",
			COLOR_SELECTED if _selected_index == 1 else COLOR_UNSELECTED)


func _update_hint_text() -> void:
	if not _hint_label:
		return
	var input_mgr: Node = get_node_or_null("/root/InputManager")
	var using_controller: bool = false
	if input_mgr and "using_controller" in input_mgr:
		using_controller = input_mgr.using_controller
	if using_controller:
		_hint_label.text = "[D-Pad] Select  [\u25cb] Confirm"
	else:
		_hint_label.text = "[\u2191/\u2193] Select  [Enter] Confirm"


## Get the text to show in interaction prompt.
func get_interaction_text() -> String:
	if is_overlay_visible:
		return "Close"
	return "Read Signpost"


## Called when player interacts with this node.
func interact(player: Node) -> void:
	if is_overlay_visible:
		_hide_overlay()
	else:
		_show_overlay(player)


func _exit_tree() -> void:
	if is_overlay_visible:
		_hide_overlay()


func _input(event: InputEvent) -> void:
	if not is_overlay_visible:
		return

	# Refresh hint if input device changed (keyboard vs controller)
	_update_hint_text()

	# Navigate selection: up/down
	if event.is_action_pressed("ui_up"):
		_selected_index = 0
		_update_selection_visuals()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_down"):
		_selected_index = 1
		_update_selection_visuals()
		get_viewport().set_input_as_handled()
		return

	# Confirm selection
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _selected_index == 0:
			_confirm_leave()
		else:
			_hide_overlay()
		return

	# Cancel (same as "Not yet")
	if event.is_action_pressed("ui_cancel"):
		_hide_overlay()
		get_viewport().set_input_as_handled()
		return


func _show_overlay(player_node: Node) -> void:
	if is_overlay_visible:
		return
	is_overlay_visible = true
	has_been_read = true
	_player_ref = player_node
	_selected_index = 0
	_update_selection_visuals()
	overlay_layer.visible = true

	# Freeze player movement
	if player_node and player_node.has_method("set_resting"):
		player_node.set_resting(true, self)

	# Hide HUD
	var hud_nodes: Array[Node] = get_tree().get_nodes_in_group("hud")
	for hud: Node in hud_nodes:
		if hud.has_method("set_overlay_mode"):
			hud.set_overlay_mode(true)


func _hide_overlay() -> void:
	if not is_overlay_visible:
		return
	is_overlay_visible = false
	overlay_layer.visible = false

	# Unfreeze player
	var player_node: Node = get_tree().get_first_node_in_group("player")
	if player_node and player_node.has_method("set_resting"):
		player_node.set_resting(false)

	# Show HUD
	var hud_nodes: Array[Node] = get_tree().get_nodes_in_group("hud")
	for hud: Node in hud_nodes:
		if hud.has_method("set_overlay_mode"):
			hud.set_overlay_mode(false)

	_player_ref = null


func _confirm_leave() -> void:
	# Emit signal for any other systems listening
	leave_wilderness_confirmed.emit()

	# Hide the overlay UI but keep player frozen and HUD hidden
	is_overlay_visible = false
	overlay_layer.visible = false

	# Snapshot player inventory to GameState
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("save_journey_inventory"):
		var inventory: Node = null
		if _player_ref:
			inventory = _player_ref.get_node_or_null("Inventory")
		if inventory and inventory.has_method("get_all_items"):
			game_state.save_journey_inventory(inventory.get_all_items())
		if "pending_house_transition" in game_state:
			game_state.pending_house_transition = true
		if "journey_completed" in game_state:
			game_state.journey_completed = true

	# Start the transition sequence
	_begin_transition()


func _begin_transition() -> void:
	# Fade-to-black overlay on a high canvas layer
	var fade_layer: CanvasLayer = CanvasLayer.new()
	fade_layer.layer = 200
	add_child(fade_layer)

	var fade_rect: ColorRect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(fade_rect)

	# "225 miles later..." text (hidden initially)
	var miles_label: Label = Label.new()
	miles_label.text = "225 miles later..."
	miles_label.add_theme_font_override("font", HUD_FONT)
	miles_label.add_theme_font_size_override("font_size", 48)
	miles_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0))
	miles_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	miles_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	miles_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(miles_label)

	# Fade out music (2s)
	var music: Node = get_node_or_null("/root/Main/MusicManager")
	if music and music.has_method("fade_out"):
		music.fade_out(2.0)

	# Transition tween sequence
	var tween: Tween = create_tween()

	# Step 1: Fade screen to black (3s, starting at the same time as music fade)
	tween.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 3.0)

	# Step 2: Brief pause, then show "225 miles later..." text (fade in over 1s)
	tween.tween_interval(0.5)
	tween.tween_property(miles_label, "theme_override_colors/font_color",
		Color(0.9, 0.9, 0.9, 1), 1.0)

	# Step 3: Hold the text for 3 seconds
	tween.tween_interval(3.0)

	# Step 4: Fade out text
	tween.tween_property(miles_label, "theme_override_colors/font_color",
		Color(0.9, 0.9, 0.9, 0), 1.0)

	# Step 5: Brief pause then change scene
	tween.tween_interval(0.5)
	tween.tween_callback(_change_to_house_scene)


func _change_to_house_scene() -> void:
	get_tree().change_scene_to_file("res://scenes/house/house.tscn")
