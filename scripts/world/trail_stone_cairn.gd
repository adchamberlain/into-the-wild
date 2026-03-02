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
	# ===== STACKED STONES =====
	# Each stone is slightly smaller and offset with slight rotation for a natural look.
	# Y positions stack upward from ground level.

	var y_cursor: float = 0.0

	# Stone 1 (base): largest
	var stone1: MeshInstance3D = MeshInstance3D.new()
	var mesh1: BoxMesh = BoxMesh.new()
	mesh1.size = Vector3(0.6, 0.25, 0.6)
	stone1.mesh = mesh1
	stone1.material_override = _stone_mat_1
	stone1.position = Vector3(0.0, y_cursor + 0.125, 0.0)
	stone1.rotation_degrees = Vector3(0.0, 8.0, 2.0)
	add_child(stone1)
	y_cursor += 0.25

	# Stone 2
	var stone2: MeshInstance3D = MeshInstance3D.new()
	var mesh2: BoxMesh = BoxMesh.new()
	mesh2.size = Vector3(0.5, 0.22, 0.5)
	stone2.mesh = mesh2
	stone2.material_override = _stone_mat_2
	stone2.position = Vector3(0.02, y_cursor + 0.11, -0.01)
	stone2.rotation_degrees = Vector3(-3.0, -12.0, 1.5)
	add_child(stone2)
	y_cursor += 0.22

	# Stone 3
	var stone3: MeshInstance3D = MeshInstance3D.new()
	var mesh3: BoxMesh = BoxMesh.new()
	mesh3.size = Vector3(0.4, 0.20, 0.45)
	stone3.mesh = mesh3
	stone3.material_override = _stone_mat_3
	stone3.position = Vector3(-0.03, y_cursor + 0.10, 0.02)
	stone3.rotation_degrees = Vector3(2.0, 15.0, -3.0)
	add_child(stone3)
	y_cursor += 0.20

	# Stone 4
	var stone4: MeshInstance3D = MeshInstance3D.new()
	var mesh4: BoxMesh = BoxMesh.new()
	mesh4.size = Vector3(0.35, 0.18, 0.35)
	stone4.mesh = mesh4
	stone4.material_override = _stone_mat_4
	stone4.position = Vector3(0.01, y_cursor + 0.09, -0.02)
	stone4.rotation_degrees = Vector3(-1.5, -7.0, 5.0)
	add_child(stone4)
	y_cursor += 0.18

	# Stone 5
	var stone5: MeshInstance3D = MeshInstance3D.new()
	var mesh5: BoxMesh = BoxMesh.new()
	mesh5.size = Vector3(0.25, 0.15, 0.25)
	stone5.mesh = mesh5
	stone5.material_override = _stone_mat_5
	stone5.position = Vector3(-0.02, y_cursor + 0.075, 0.01)
	stone5.rotation_degrees = Vector3(3.0, 10.0, -2.0)
	add_child(stone5)
	y_cursor += 0.15

	# Stone 6 (top): smallest
	var stone6: MeshInstance3D = MeshInstance3D.new()
	var mesh6: BoxMesh = BoxMesh.new()
	mesh6.size = Vector3(0.15, 0.12, 0.15)
	stone6.mesh = mesh6
	stone6.material_override = _stone_mat_6
	stone6.position = Vector3(0.01, y_cursor + 0.06, -0.01)
	stone6.rotation_degrees = Vector3(-2.0, 14.0, 4.0)
	add_child(stone6)
	y_cursor += 0.12

	# ===== LIGHT =====
	# Faint warm glow to help player spot the cairn
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "CairnGlow"
	light.light_color = Color(0.95, 0.85, 0.6)
	light.light_energy = 0.4
	light.omni_range = 3.5
	light.shadow_enabled = false
	light.position = Vector3(0.0, y_cursor * 0.5, 0.0)
	add_child(light)

	# ===== COLLISION =====
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(0.7, y_cursor + 0.1, 0.7)
	collision.shape = shape
	collision.position = Vector3(0.0, (y_cursor + 0.1) * 0.5, 0.0)
	add_child(collision)


func _build_overlay() -> void:
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 100
	overlay_layer.visible = false
	add_child(overlay_layer)

	# Semi-transparent dark background
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_layer.add_child(bg)

	# Centered panel
	var panel: PanelContainer = PanelContainer.new()
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.12, 0.8)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.content_margin_left = 20.0
	panel_style.content_margin_right = 20.0
	panel_style.content_margin_top = 20.0
	panel_style.content_margin_bottom = 20.0
	panel.add_theme_stylebox_override("panel", panel_style)
	# Center the panel on screen
	panel.anchor_left = 0.2
	panel.anchor_right = 0.8
	panel.anchor_top = 0.15
	panel.anchor_bottom = 0.85
	panel.offset_left = 0.0
	panel.offset_right = 0.0
	panel.offset_top = 0.0
	panel.offset_bottom = 0.0
	overlay_layer.add_child(panel)

	# Content VBox
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	# Title
	var title: Label = Label.new()
	title.text = "The Stone Cairn"
	title.add_theme_font_override("font", HUD_FONT)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Separator
	var sep: HSeparator = HSeparator.new()
	var sep_style: StyleBoxFlat = StyleBoxFlat.new()
	sep_style.bg_color = Color(0.9, 0.9, 0.9, 0.3)
	sep_style.content_margin_top = 2.0
	sep_style.content_margin_bottom = 2.0
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	# Spacer
	var spacer_top: Control = Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer_top)

	# Body text
	var body: Label = Label.new()
	body.text = "A carefully balanced stack of stones, placed here with intention. Each rock chosen and fitted by someone who understood the wilderness.\n\nScratched into the base rock:\n\n'The trail drops into the valley beyond the mountains. Look for the old signpost.'\n\n— M.W.C."
	body.add_theme_font_override("font", HUD_FONT)
	body.add_theme_font_size_override("font_size", 32)
	body.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(body)

	# Expanding spacer to push hint to bottom
	var spacer_bottom: Control = Control.new()
	spacer_bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer_bottom)

	# Close hint (text updated dynamically in _show_overlay)
	close_hint_label = Label.new()
	close_hint_label.text = "[E] Close"
	close_hint_label.add_theme_font_override("font", HUD_FONT)
	close_hint_label.add_theme_font_size_override("font_size", 28)
	close_hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	close_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(close_hint_label)


## Get the text to show in interaction prompt.
func get_interaction_text() -> String:
	if is_overlay_visible:
		return "Close"
	return "Read Cairn"


## Called when player interacts with this node.
func interact(player: Node) -> void:
	if is_overlay_visible:
		_hide_overlay()
	else:
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
