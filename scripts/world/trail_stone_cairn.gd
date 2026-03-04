extends StaticBody3D
## Trail Stone Cairn - a stack of carefully balanced stones marking a trail.
## Displays a readable overlay with a clue when interacted with.

const HUD_FONT: Font = preload("res://resources/hud_font.tres")

# Shared static materials (avoid per-instance shader compilation)
static var _stone_mat_1: StandardMaterial3D = null
static var _stone_mat_2: StandardMaterial3D = null
static var _stone_mat_3: StandardMaterial3D = null
static var _stone_mat_4: StandardMaterial3D = null
static var _stone_mat_5: StandardMaterial3D = null
static var _stone_mat_6: StandardMaterial3D = null
static var _materials_initialized: bool = false

# Overlay UI
var overlay_layer: CanvasLayer
var is_overlay_visible: bool = false
var close_hint_label: Label
var _body_label: Label

# Labels and containers for dynamic scaling
var _scaled_labels: Array[Dictionary] = []  # [{label, base_size}]
var _inner_style: StyleBoxFlat
var _content_vbox: VBoxContainer
const REFERENCE_HEIGHT: float = 1080.0

# State
var has_been_read: bool = false

# Player reference for unfreezing
var _player_ref: Node = null


func _ready() -> void:
	add_to_group("interactable")
	_ensure_shared_materials()
	call_deferred("_build_visuals")
	call_deferred("_build_overlay")


static func _ensure_shared_materials() -> void:
	if _materials_initialized:
		return
	_materials_initialized = true

	# Base stone: large grey
	_stone_mat_1 = StandardMaterial3D.new()
	_stone_mat_1.albedo_color = Color(0.5, 0.48, 0.45)
	_stone_mat_1.roughness = 0.9

	# Stone 2: slightly lighter grey
	_stone_mat_2 = StandardMaterial3D.new()
	_stone_mat_2.albedo_color = Color(0.55, 0.52, 0.48)
	_stone_mat_2.roughness = 0.9

	# Stone 3: medium grey
	_stone_mat_3 = StandardMaterial3D.new()
	_stone_mat_3.albedo_color = Color(0.48, 0.45, 0.42)
	_stone_mat_3.roughness = 0.9

	# Stone 4: brown-grey
	_stone_mat_4 = StandardMaterial3D.new()
	_stone_mat_4.albedo_color = Color(0.45, 0.42, 0.38)
	_stone_mat_4.roughness = 0.9

	# Stone 5: lighter grey
	_stone_mat_5 = StandardMaterial3D.new()
	_stone_mat_5.albedo_color = Color(0.52, 0.50, 0.47)
	_stone_mat_5.roughness = 0.9

	# Top stone: lightest
	_stone_mat_6 = StandardMaterial3D.new()
	_stone_mat_6.albedo_color = Color(0.58, 0.55, 0.52)
	_stone_mat_6.roughness = 0.9


func _build_visuals() -> void:
	# ===== SCATTERED BASE RUBBLE =====
	# Ring of loose stones around the base for a wider footprint and natural look.
	var rubble_data: Array = [
		{"pos": Vector3(1.6, 0.15, 0.8), "size": Vector3(0.7, 0.3, 0.55), "rot": Vector3(5, 20, 8), "mat": _stone_mat_3},
		{"pos": Vector3(-1.4, 0.12, 1.0), "size": Vector3(0.6, 0.25, 0.5), "rot": Vector3(-3, -35, 6), "mat": _stone_mat_4},
		{"pos": Vector3(0.9, 0.10, -1.5), "size": Vector3(0.5, 0.2, 0.6), "rot": Vector3(4, 50, -5), "mat": _stone_mat_2},
		{"pos": Vector3(-1.0, 0.13, -1.2), "size": Vector3(0.55, 0.26, 0.45), "rot": Vector3(-6, 15, 10), "mat": _stone_mat_5},
		{"pos": Vector3(1.8, 0.08, -0.5), "size": Vector3(0.4, 0.16, 0.5), "rot": Vector3(8, -25, -4), "mat": _stone_mat_1},
		{"pos": Vector3(-1.7, 0.10, -0.2), "size": Vector3(0.5, 0.2, 0.4), "rot": Vector3(-4, 40, 7), "mat": _stone_mat_3},
		{"pos": Vector3(0.3, 0.09, 1.8), "size": Vector3(0.45, 0.18, 0.55), "rot": Vector3(3, -60, 5), "mat": _stone_mat_6},
		{"pos": Vector3(-0.5, 0.11, 1.5), "size": Vector3(0.6, 0.22, 0.4), "rot": Vector3(-5, 70, -3), "mat": _stone_mat_2},
	]
	for rd: Dictionary in rubble_data:
		var rubble: MeshInstance3D = MeshInstance3D.new()
		var rmesh: BoxMesh = BoxMesh.new()
		rmesh.size = rd["size"] as Vector3
		rubble.mesh = rmesh
		rubble.material_override = rd["mat"] as StandardMaterial3D
		rubble.position = rd["pos"] as Vector3
		rubble.rotation_degrees = rd["rot"] as Vector3
		add_child(rubble)

	# ===== MAIN STACKED STONES =====
	# Tall pyramid of stones — each layer smaller and slightly offset/rotated.
	# Total height ~4.2 units (visible from far away).

	var y_cursor: float = 0.0

	# Stone 1 (base): massive foundation slab
	var stone1: MeshInstance3D = MeshInstance3D.new()
	var mesh1: BoxMesh = BoxMesh.new()
	mesh1.size = Vector3(2.2, 0.7, 2.2)
	stone1.mesh = mesh1
	stone1.material_override = _stone_mat_1
	stone1.position = Vector3(0.0, y_cursor + 0.35, 0.0)
	stone1.rotation_degrees = Vector3(0.0, 8.0, 1.5)
	add_child(stone1)
	y_cursor += 0.7

	# Stone 2: wide base layer
	var stone2: MeshInstance3D = MeshInstance3D.new()
	var mesh2: BoxMesh = BoxMesh.new()
	mesh2.size = Vector3(1.8, 0.65, 1.7)
	stone2.mesh = mesh2
	stone2.material_override = _stone_mat_2
	stone2.position = Vector3(0.06, y_cursor + 0.325, -0.04)
	stone2.rotation_degrees = Vector3(-2.0, -12.0, 1.0)
	add_child(stone2)
	y_cursor += 0.65

	# Stone 3
	var stone3: MeshInstance3D = MeshInstance3D.new()
	var mesh3: BoxMesh = BoxMesh.new()
	mesh3.size = Vector3(1.5, 0.6, 1.5)
	stone3.mesh = mesh3
	stone3.material_override = _stone_mat_3
	stone3.position = Vector3(-0.08, y_cursor + 0.3, 0.06)
	stone3.rotation_degrees = Vector3(1.5, 15.0, -2.0)
	add_child(stone3)
	y_cursor += 0.6

	# Stone 4
	var stone4: MeshInstance3D = MeshInstance3D.new()
	var mesh4: BoxMesh = BoxMesh.new()
	mesh4.size = Vector3(1.2, 0.55, 1.3)
	stone4.mesh = mesh4
	stone4.material_override = _stone_mat_4
	stone4.position = Vector3(0.05, y_cursor + 0.275, -0.05)
	stone4.rotation_degrees = Vector3(-1.0, -7.0, 3.0)
	add_child(stone4)
	y_cursor += 0.55

	# Stone 5
	var stone5: MeshInstance3D = MeshInstance3D.new()
	var mesh5: BoxMesh = BoxMesh.new()
	mesh5.size = Vector3(0.9, 0.5, 1.0)
	stone5.mesh = mesh5
	stone5.material_override = _stone_mat_5
	stone5.position = Vector3(-0.04, y_cursor + 0.25, 0.03)
	stone5.rotation_degrees = Vector3(2.0, 10.0, -1.5)
	add_child(stone5)
	y_cursor += 0.5

	# Stone 6 (cap): smaller but still substantial
	var stone6: MeshInstance3D = MeshInstance3D.new()
	var mesh6: BoxMesh = BoxMesh.new()
	mesh6.size = Vector3(0.65, 0.4, 0.7)
	stone6.mesh = mesh6
	stone6.material_override = _stone_mat_6
	stone6.position = Vector3(0.03, y_cursor + 0.2, -0.02)
	stone6.rotation_degrees = Vector3(-1.5, 14.0, 2.5)
	add_child(stone6)
	y_cursor += 0.4

	# Stone 7 (top): pointed capstone
	var stone7: MeshInstance3D = MeshInstance3D.new()
	var mesh7: BoxMesh = BoxMesh.new()
	mesh7.size = Vector3(0.35, 0.45, 0.35)
	stone7.mesh = mesh7
	stone7.material_override = _stone_mat_2
	stone7.position = Vector3(0.0, y_cursor + 0.225, 0.0)
	stone7.rotation_degrees = Vector3(-2.0, 22.0, 4.0)
	add_child(stone7)
	y_cursor += 0.45

	# ===== LIGHT =====
	# Strong warm glow visible from a distance
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "CairnGlow"
	light.light_color = Color(0.95, 0.85, 0.6)
	light.light_energy = 1.2
	light.omni_range = 10.0
	light.shadow_enabled = false
	light.position = Vector3(0.0, y_cursor * 0.6, 0.0)
	add_child(light)

	# ===== COLLISION =====
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(2.5, y_cursor + 0.2, 2.5)
	collision.shape = shape
	collision.position = Vector3(0.0, (y_cursor + 0.2) * 0.5, 0.0)
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
	_inner_style = StyleBoxFlat.new()
	_inner_style.bg_color = Color(0.72, 0.68, 0.55)
	_inner_style.corner_radius_top_left = 8
	_inner_style.corner_radius_top_right = 8
	_inner_style.corner_radius_bottom_left = 8
	_inner_style.corner_radius_bottom_right = 8
	_inner_style.content_margin_left = 40.0
	_inner_style.content_margin_right = 40.0
	_inner_style.content_margin_top = 30.0
	_inner_style.content_margin_bottom = 30.0
	inner_panel.add_theme_stylebox_override("panel", _inner_style)
	outer_panel.add_child(inner_panel)

	# Dark brown text color (matching wilderness sign)
	var text_color: Color = Color(0.30, 0.18, 0.05)
	var hint_color: Color = Color(0.45, 0.40, 0.30)

	# Content VBox
	_content_vbox = VBoxContainer.new()
	_content_vbox.add_theme_constant_override("separation", 16)
	inner_panel.add_child(_content_vbox)
	var vbox: VBoxContainer = _content_vbox

	# Title
	_make_label(vbox, "THE STONE CAIRN", 56, text_color, HORIZONTAL_ALIGNMENT_CENTER)

	# Separator
	var sep: HSeparator = HSeparator.new()
	var sep_style: StyleBoxFlat = StyleBoxFlat.new()
	sep_style.bg_color = Color(0.30, 0.18, 0.05, 0.5)
	sep_style.content_margin_top = 2.0
	sep_style.content_margin_bottom = 2.0
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	# Spacer
	var spacer_top: Control = Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer_top)

	# Body text (distance filled in dynamically in _show_overlay)
	_body_label = _make_label(vbox, "", 36, text_color)
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Expanding spacer to push hint to bottom
	var spacer_bottom: Control = Control.new()
	spacer_bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer_bottom)

	# Close hint (text updated dynamically in _show_overlay)
	close_hint_label = _make_label(vbox, "", 28, hint_color, HORIZONTAL_ALIGNMENT_CENTER)


func _make_label(parent: Node, text: String, base_size: int, color: Color,
		alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_override("font", HUD_FONT)
	label.add_theme_font_size_override("font_size", base_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	parent.add_child(label)
	_scaled_labels.append({"label": label, "base_size": base_size})
	return label


func _scale_fonts() -> void:
	var viewport_height: float = get_viewport().get_visible_rect().size.y
	var sf: float = viewport_height / REFERENCE_HEIGHT
	for entry: Dictionary in _scaled_labels:
		var label: Label = entry["label"] as Label
		var base_size: int = entry["base_size"] as int
		if is_instance_valid(label):
			label.add_theme_font_size_override("font_size", int(base_size * sf))
	if _inner_style:
		_inner_style.content_margin_left = 40.0 * sf
		_inner_style.content_margin_right = 40.0 * sf
		_inner_style.content_margin_top = 30.0 * sf
		_inner_style.content_margin_bottom = 30.0 * sf
	if _content_vbox:
		_content_vbox.add_theme_constant_override("separation", int(16 * sf))


## Check if trail prerequisite is met (carved tree must be found first).
func _can_interact() -> bool:
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state and game_state.trail_testing_mode:
		return true
	if game_state and game_state.trail_carved_tree_found:
		return true
	return false


## Get the text to show in interaction prompt.
func get_interaction_text() -> String:
	if is_overlay_visible:
		return "Close"
	if not _can_interact():
		return ""
	return "Read Cairn"


## Called when player interacts with this node.
func interact(player: Node) -> void:
	if is_overlay_visible:
		_hide_overlay()
	elif _can_interact():
		_show_overlay(player)


func _input(event: InputEvent) -> void:
	if not is_overlay_visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_hide_overlay()
		get_viewport().set_input_as_handled()


func _show_overlay(player_node: Node) -> void:
	if is_overlay_visible:
		return
	is_overlay_visible = true
	has_been_read = true
	overlay_layer.visible = true
	_player_ref = player_node

	# Compute distance and Z-line to the signpost for the clue text
	if _body_label:
		var nav_text: String = "not far southeast"
		var cm: Node = get_tree().get_first_node_in_group("chunk_manager")
		if cm and "trail_signpost_position" in cm:
			var sign_pos: Vector2 = cm.trail_signpost_position
			var my_pos: Vector2 = Vector2(global_position.x, global_position.z)
			var dist: int = int(my_pos.distance_to(sign_pos))
			nav_text = "Go southeast about %d units. Stay on the Z: %d line" % [dist, int(sign_pos.y)]
		_body_label.text = "A carefully balanced stack of stones, placed here with intention. Each rock chosen and fitted by someone who understood the wilderness.\n\nScratched into the base rock:\n\n'The old signpost lies southeast. %s.'\n\n\u2014 M.W.C." % nav_text

	# Scale fonts to current viewport size
	_scale_fonts()

	# Play magical discovery sound
	var sfx: Node = get_node_or_null("/root/SFXManager")
	if sfx and sfx.has_method("play_sfx"):
		sfx.play_sfx("coca_leaf")

	# Mark as found in global state for trail progression
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state:
		game_state.trail_stone_cairn_found = true

	# Update close hint with current input device
	var input_mgr: Node = get_node_or_null("/root/InputManager")
	var interact_key: String = "E"
	if input_mgr and input_mgr.has_method("get_prompt"):
		interact_key = input_mgr.get_prompt("interact")
	if close_hint_label:
		close_hint_label.text = "[%s] Close" % interact_key

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
	# During scene teardown get_tree() may be null — just clear flag and bail
	if not is_inside_tree():
		return
	overlay_layer.visible = false

	# Unfreeze player
	var player_node: Node = _player_ref
	if player_node == null:
		player_node = get_tree().get_first_node_in_group("player")
	if player_node and player_node.has_method("set_resting"):
		player_node.set_resting(false)
	_player_ref = null

	# Show HUD
	var hud_nodes: Array[Node] = get_tree().get_nodes_in_group("hud")
	for hud: Node in hud_nodes:
		if hud.has_method("set_overlay_mode"):
			hud.set_overlay_mode(false)


func _exit_tree() -> void:
	if is_overlay_visible:
		_hide_overlay()
