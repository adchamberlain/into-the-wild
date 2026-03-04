extends StaticBody3D
## Carved Tree landmark — a distinctive tree with carved initials ("M.W.C.")
## and an arrow pointing east. Part of the trail-home endgame feature.
## Displays a readable overlay with a clue when interacted with.

const HUD_FONT: Font = preload("res://resources/hud_font.tres")

# State
var has_been_read: bool = false

# Shared static materials (avoid per-instance shader compilation)
static var _trunk_mat: StandardMaterial3D = null
static var _carved_face_mat: StandardMaterial3D = null
static var _arrow_mat: StandardMaterial3D = null
static var _canopy_mat: StandardMaterial3D = null
static var _canopy_dark_mat: StandardMaterial3D = null
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


func _ready() -> void:
	add_to_group("interactable")
	_ensure_shared_materials()
	call_deferred("_build_visuals")
	call_deferred("_build_overlay")


static func _ensure_shared_materials() -> void:
	if _materials_initialized:
		return
	_materials_initialized = true

	# Trunk: dark brown bark
	_trunk_mat = StandardMaterial3D.new()
	_trunk_mat.albedo_color = Color(0.30, 0.18, 0.08)
	_trunk_mat.roughness = 0.9

	# Carved face: lighter exposed wood
	_carved_face_mat = StandardMaterial3D.new()
	_carved_face_mat.albedo_color = Color(0.6, 0.5, 0.3)
	_carved_face_mat.roughness = 0.75

	# Arrow carving: dark lines cut into the wood
	_arrow_mat = StandardMaterial3D.new()
	_arrow_mat.albedo_color = Color(0.25, 0.15, 0.06)
	_arrow_mat.roughness = 0.85

	# Canopy: forest green foliage
	_canopy_mat = StandardMaterial3D.new()
	_canopy_mat.albedo_color = Color(0.2, 0.45, 0.15)
	_canopy_mat.roughness = 0.8

	# Canopy dark: variation for depth
	_canopy_dark_mat = StandardMaterial3D.new()
	_canopy_dark_mat.albedo_color = Color(0.15, 0.35, 0.10)
	_canopy_dark_mat.roughness = 0.85


func _build_visuals() -> void:
	# ===== TRUNK =====
	var trunk: MeshInstance3D = MeshInstance3D.new()
	var trunk_mesh: BoxMesh = BoxMesh.new()
	trunk_mesh.size = Vector3(0.8, 3.0, 0.8)
	trunk.mesh = trunk_mesh
	trunk.material_override = _trunk_mat
	trunk.position = Vector3(0, 1.5, 0)
	add_child(trunk)

	# ===== CARVED FACE =====
	# Flat lighter patch inset on the front side of the trunk
	var carved_face: MeshInstance3D = MeshInstance3D.new()
	var face_mesh: BoxMesh = BoxMesh.new()
	face_mesh.size = Vector3(0.6, 0.8, 0.02)
	carved_face.mesh = face_mesh
	carved_face.material_override = _carved_face_mat
	carved_face.position = Vector3(0, 1.6, 0.41)
	add_child(carved_face)

	# ===== ARROW CARVING =====
	# Arrow made of thin dark strips on the carved face, pointing right (east)
	# Horizontal shaft
	var arrow_shaft: MeshInstance3D = MeshInstance3D.new()
	var shaft_mesh: BoxMesh = BoxMesh.new()
	shaft_mesh.size = Vector3(0.35, 0.03, 0.01)
	arrow_shaft.mesh = shaft_mesh
	arrow_shaft.material_override = _arrow_mat
	arrow_shaft.position = Vector3(-0.02, 1.45, 0.425)
	add_child(arrow_shaft)

	# Upper arrowhead line (angled strip)
	var arrow_upper: MeshInstance3D = MeshInstance3D.new()
	var upper_mesh: BoxMesh = BoxMesh.new()
	upper_mesh.size = Vector3(0.15, 0.03, 0.01)
	arrow_upper.mesh = upper_mesh
	arrow_upper.material_override = _arrow_mat
	arrow_upper.position = Vector3(0.13, 1.49, 0.425)
	arrow_upper.rotation_degrees = Vector3(0, 0, 40)
	add_child(arrow_upper)

	# Lower arrowhead line (angled strip)
	var arrow_lower: MeshInstance3D = MeshInstance3D.new()
	var lower_mesh: BoxMesh = BoxMesh.new()
	lower_mesh.size = Vector3(0.15, 0.03, 0.01)
	arrow_lower.mesh = lower_mesh
	arrow_lower.material_override = _arrow_mat
	arrow_lower.position = Vector3(0.13, 1.41, 0.425)
	arrow_lower.rotation_degrees = Vector3(0, 0, -40)
	add_child(arrow_lower)

	# ===== CANOPY =====
	# A few green blocks on top suggesting foliage
	var canopy_main: MeshInstance3D = MeshInstance3D.new()
	var canopy_main_mesh: BoxMesh = BoxMesh.new()
	canopy_main_mesh.size = Vector3(1.6, 1.0, 1.6)
	canopy_main.mesh = canopy_main_mesh
	canopy_main.material_override = _canopy_mat
	canopy_main.position = Vector3(0, 3.5, 0)
	add_child(canopy_main)

	var canopy_top: MeshInstance3D = MeshInstance3D.new()
	var canopy_top_mesh: BoxMesh = BoxMesh.new()
	canopy_top_mesh.size = Vector3(1.1, 0.7, 1.1)
	canopy_top.mesh = canopy_top_mesh
	canopy_top.material_override = _canopy_dark_mat
	canopy_top.position = Vector3(0.1, 4.2, 0.1)
	add_child(canopy_top)

	var canopy_side: MeshInstance3D = MeshInstance3D.new()
	var canopy_side_mesh: BoxMesh = BoxMesh.new()
	canopy_side_mesh.size = Vector3(0.8, 0.6, 1.0)
	canopy_side.mesh = canopy_side_mesh
	canopy_side.material_override = _canopy_mat
	canopy_side.position = Vector3(-0.6, 3.3, 0.2)
	add_child(canopy_side)

	# ===== LIGHT =====
	# Faint warm glow to help player spot the carved tree
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "CarvedTreeGlow"
	light.light_color = Color(0.9, 0.8, 0.5)
	light.light_energy = 0.5
	light.omni_range = 4.0
	light.shadow_enabled = false
	light.position = Vector3(0, 1.8, 0.5)
	add_child(light)

	# ===== COLLISION =====
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(0.8, 3.0, 0.8)
	collision.shape = shape
	collision.position = Vector3(0, 1.5, 0)
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
	_make_label(vbox, "THE CARVED TREE", 56, text_color, HORIZONTAL_ALIGNMENT_CENTER)

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


## Convert a direction vector between two XZ points into a cardinal direction name.
static func _cardinal_direction(from: Vector2, to: Vector2) -> String:
	var dx: float = to.x - from.x   # +X = east
	var dz: float = to.y - from.y   # -Z = south in Godot
	var angle: float = atan2(dx, -dz)  # 0 = south, PI/2 = east
	# Normalize to 0..TAU
	if angle < 0:
		angle += TAU
	# 8 sectors of 45 degrees each, starting from south
	var sector: int = int((angle + PI / 8.0) / (PI / 4.0)) % 8
	var names: Array[String] = ["south", "southeast", "east", "northeast", "north", "northwest", "west", "southwest"]
	return names[sector]


## Get the text to show in interaction prompt.
func get_interaction_text() -> String:
	if is_overlay_visible:
		return "Close"
	return "Read Carved Tree"


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
	if event.is_action_pressed("ui_cancel"):
		_hide_overlay()
		get_viewport().set_input_as_handled()


func _show_overlay(player_node: Node) -> void:
	if is_overlay_visible:
		return
	is_overlay_visible = true
	has_been_read = true
	overlay_layer.visible = true

	# Compute direction, distance, and Z-line to the stone cairn for the clue text
	if _body_label:
		var dir_name: String = "east"
		var nav_text: String = "a long walk east"
		var cm: Node = get_tree().get_first_node_in_group("chunk_manager")
		if cm and "stone_cairn_position" in cm:
			var cairn_pos: Vector2 = cm.stone_cairn_position
			var my_pos: Vector2 = Vector2(global_position.x, global_position.z)
			var dist: int = int(my_pos.distance_to(cairn_pos))
			dir_name = _cardinal_direction(my_pos, cairn_pos)
			nav_text = "Follow the ridge %s to the stone cairn about %d paces. Stay on the Z = %d line" % [dir_name, dist, int(cairn_pos.y)]
		_body_label.text = "Carved deep into the bark, the letters M.W.C. are still sharp after all these years. Below the initials, an arrow points %s.\n\nScratched in smaller letters beneath:\n\n'%s.'\n\n\u2014 M.W. Carlston's trail marker" % [dir_name, nav_text]

	# Scale fonts to current viewport size
	_scale_fonts()

	# Play magical discovery sound
	var sfx: Node = get_node_or_null("/root/SFXManager")
	if sfx and sfx.has_method("play_sfx"):
		sfx.play_sfx("coca_leaf")

	# Mark as found in global state for trail progression
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state:
		game_state.trail_carved_tree_found = true

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
	var player_node: Node = get_tree().get_first_node_in_group("player")
	if player_node and player_node.has_method("set_resting"):
		player_node.set_resting(false)

	# Show HUD
	var hud_nodes: Array[Node] = get_tree().get_nodes_in_group("hud")
	for hud: Node in hud_nodes:
		if hud.has_method("set_overlay_mode"):
			hud.set_overlay_mode(false)
