extends StructureBase
class_name WildernessSign
## Carlston Wilderness information kiosk sign near the player spawn.
## Displays a readable overlay with wilderness regulations when interacted with.

const HUD_FONT: Font = preload("res://resources/hud_font.tres")

# Shared materials (one instance for all signs)
static var _mat_post: StandardMaterial3D
static var _mat_roof: StandardMaterial3D
static var _mat_board: StandardMaterial3D
static var _mat_header: StandardMaterial3D
static var _mat_frame: StandardMaterial3D
static var _materials_initialized: bool = false

# Overlay UI
var overlay_layer: CanvasLayer
var is_overlay_visible: bool = false
var close_hint_label: Label

# Labels and containers for dynamic scaling
var _scaled_labels: Array[Dictionary] = []  # [{label, base_size}]
var _inner_style: StyleBoxFlat
var _content_vbox: VBoxContainer
var _tree_logo: Control
const REFERENCE_HEIGHT: float = 1080.0  # Design reference resolution


func _ready() -> void:
	structure_type = "wilderness_sign"
	structure_name = "Wilderness Sign"
	interaction_text = "Read Sign"
	super._ready()
	# Remove from "structure" group so it can't be moved/picked up
	remove_from_group("structure")
	_init_materials()
	_build_mesh()
	_build_overlay()


static func _init_materials() -> void:
	if _materials_initialized:
		return
	_materials_initialized = true

	# Dark brown wood posts
	_mat_post = StandardMaterial3D.new()
	_mat_post.albedo_color = Color(0.30, 0.18, 0.08)
	_mat_post.roughness = 0.9

	# Dark green roof panels
	_mat_roof = StandardMaterial3D.new()
	_mat_roof.albedo_color = Color(0.15, 0.25, 0.10)
	_mat_roof.roughness = 0.85

	# Olive/tan information board
	_mat_board = StandardMaterial3D.new()
	_mat_board.albedo_color = Color(0.65, 0.58, 0.40)
	_mat_board.roughness = 0.8

	# Darker header strip
	_mat_header = StandardMaterial3D.new()
	_mat_header.albedo_color = Color(0.35, 0.22, 0.10)
	_mat_header.roughness = 0.85

	# Dark frame edges
	_mat_frame = StandardMaterial3D.new()
	_mat_frame.albedo_color = Color(0.22, 0.14, 0.06)
	_mat_frame.roughness = 0.9


func _build_mesh() -> void:
	# Scale the entire sign to 70% of original size
	const SIGN_SCALE: float = 0.7

	# Mesh container (scaled down, collision stays separate)
	var mesh_root: Node3D = Node3D.new()
	mesh_root.name = "MeshRoot"
	mesh_root.scale = Vector3(SIGN_SCALE, SIGN_SCALE, SIGN_SCALE)
	add_child(mesh_root)

	# --- Left post ---
	var left_post: MeshInstance3D = MeshInstance3D.new()
	var left_post_mesh: BoxMesh = BoxMesh.new()
	left_post_mesh.size = Vector3(0.2, 3.5, 0.2)
	left_post.mesh = left_post_mesh
	left_post.material_override = _mat_post
	left_post.position = Vector3(-1.3, 1.75, 0.0)
	mesh_root.add_child(left_post)

	# --- Right post ---
	var right_post: MeshInstance3D = MeshInstance3D.new()
	var right_post_mesh: BoxMesh = BoxMesh.new()
	right_post_mesh.size = Vector3(0.2, 3.5, 0.2)
	right_post.mesh = right_post_mesh
	right_post.material_override = _mat_post
	right_post.position = Vector3(1.3, 1.75, 0.0)
	mesh_root.add_child(right_post)

	# --- Cross beam at top ---
	var cross_beam: MeshInstance3D = MeshInstance3D.new()
	var cross_beam_mesh: BoxMesh = BoxMesh.new()
	cross_beam_mesh.size = Vector3(2.8, 0.15, 0.2)
	cross_beam.mesh = cross_beam_mesh
	cross_beam.material_override = _mat_post
	cross_beam.position = Vector3(0.0, 3.45, 0.0)
	mesh_root.add_child(cross_beam)

	# --- Angled roof - left slab ---
	var roof_left: MeshInstance3D = MeshInstance3D.new()
	var roof_left_mesh: BoxMesh = BoxMesh.new()
	roof_left_mesh.size = Vector3(1.6, 0.08, 0.7)
	roof_left.mesh = roof_left_mesh
	roof_left.material_override = _mat_roof
	roof_left.position = Vector3(-0.65, 3.65, 0.0)
	roof_left.rotation_degrees.z = 8.0
	mesh_root.add_child(roof_left)

	# --- Angled roof - right slab ---
	var roof_right: MeshInstance3D = MeshInstance3D.new()
	var roof_right_mesh: BoxMesh = BoxMesh.new()
	roof_right_mesh.size = Vector3(1.6, 0.08, 0.7)
	roof_right.mesh = roof_right_mesh
	roof_right.material_override = _mat_roof
	roof_right.position = Vector3(0.65, 3.65, 0.0)
	roof_right.rotation_degrees.z = -8.0
	mesh_root.add_child(roof_right)

	# --- Ridge cap ---
	var ridge: MeshInstance3D = MeshInstance3D.new()
	var ridge_mesh: BoxMesh = BoxMesh.new()
	ridge_mesh.size = Vector3(0.3, 0.1, 0.75)
	ridge.mesh = ridge_mesh
	ridge.material_override = _mat_post
	ridge.position = Vector3(0.0, 3.75, 0.0)
	mesh_root.add_child(ridge)

	# --- Main information board ---
	var board: MeshInstance3D = MeshInstance3D.new()
	var board_mesh: BoxMesh = BoxMesh.new()
	board_mesh.size = Vector3(2.4, 1.5, 0.06)
	board.mesh = board_mesh
	board.material_override = _mat_board
	board.position = Vector3(0.0, 2.25, 0.05)
	mesh_root.add_child(board)

	# --- Header strip ---
	var header: MeshInstance3D = MeshInstance3D.new()
	var header_mesh: BoxMesh = BoxMesh.new()
	header_mesh.size = Vector3(2.3, 0.25, 0.02)
	header.mesh = header_mesh
	header.material_override = _mat_header
	header.position = Vector3(0.0, 2.85, 0.09)
	mesh_root.add_child(header)

	# --- Frame edges (thin dark strips) ---
	# Top edge
	var frame_top: MeshInstance3D = MeshInstance3D.new()
	var frame_top_mesh: BoxMesh = BoxMesh.new()
	frame_top_mesh.size = Vector3(2.44, 0.06, 0.02)
	frame_top.mesh = frame_top_mesh
	frame_top.material_override = _mat_frame
	frame_top.position = Vector3(0.0, 3.02, 0.09)
	mesh_root.add_child(frame_top)

	# Bottom edge
	var frame_bottom: MeshInstance3D = MeshInstance3D.new()
	var frame_bottom_mesh: BoxMesh = BoxMesh.new()
	frame_bottom_mesh.size = Vector3(2.44, 0.06, 0.02)
	frame_bottom.mesh = frame_bottom_mesh
	frame_bottom.material_override = _mat_frame
	frame_bottom.position = Vector3(0.0, 1.48, 0.09)
	mesh_root.add_child(frame_bottom)

	# Left edge
	var frame_left: MeshInstance3D = MeshInstance3D.new()
	var frame_left_mesh: BoxMesh = BoxMesh.new()
	frame_left_mesh.size = Vector3(0.06, 1.54, 0.02)
	frame_left.mesh = frame_left_mesh
	frame_left.material_override = _mat_frame
	frame_left.position = Vector3(-1.22, 2.25, 0.09)
	mesh_root.add_child(frame_left)

	# Right edge
	var frame_right: MeshInstance3D = MeshInstance3D.new()
	var frame_right_mesh: BoxMesh = BoxMesh.new()
	frame_right_mesh.size = Vector3(0.06, 1.54, 0.02)
	frame_right.mesh = frame_right_mesh
	frame_right.material_override = _mat_frame
	frame_right.position = Vector3(1.22, 2.25, 0.09)
	mesh_root.add_child(frame_right)

	# --- Support braces (angled from posts to board) ---
	var brace_left: MeshInstance3D = MeshInstance3D.new()
	var brace_left_mesh: BoxMesh = BoxMesh.new()
	brace_left_mesh.size = Vector3(0.12, 0.7, 0.12)
	brace_left.mesh = brace_left_mesh
	brace_left.material_override = _mat_post
	brace_left.position = Vector3(-1.15, 1.2, 0.0)
	brace_left.rotation_degrees.z = 25.0
	mesh_root.add_child(brace_left)

	var brace_right: MeshInstance3D = MeshInstance3D.new()
	var brace_right_mesh: BoxMesh = BoxMesh.new()
	brace_right_mesh.size = Vector3(0.12, 0.7, 0.12)
	brace_right.mesh = brace_right_mesh
	brace_right.material_override = _mat_post
	brace_right.position = Vector3(1.15, 1.2, 0.0)
	brace_right.rotation_degrees.z = -25.0
	mesh_root.add_child(brace_right)

	# --- Collision shape (scaled separately — Godot warns about scaled collision parents) ---
	var col_shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(2.8 * SIGN_SCALE, 3.5 * SIGN_SCALE, 0.5 * SIGN_SCALE)
	col_shape.shape = box
	col_shape.position = Vector3(0.0, 1.75 * SIGN_SCALE, 0.0)
	add_child(col_shape)


func _build_overlay() -> void:
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 100
	overlay_layer.visible = false
	add_child(overlay_layer)

	# Semi-transparent dark green background
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.05, 0.10, 0.04, 0.65)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_layer.add_child(bg)

	# Outer panel - forest green
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

	# Inner panel - tan/cream
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

	# Content VBox
	_content_vbox = VBoxContainer.new()
	_content_vbox.add_theme_constant_override("separation", 16)
	inner_panel.add_child(_content_vbox)
	var vbox: VBoxContainer = _content_vbox

	# Title
	var title: Label = _make_label(vbox, "CARLSTON WILDERNESS", 56,
		Color(0.30, 0.18, 0.05), HORIZONTAL_ALIGNMENT_CENTER)

	# Separator
	var sep: HSeparator = HSeparator.new()
	var sep_style: StyleBoxFlat = StyleBoxFlat.new()
	sep_style.bg_color = Color(0.30, 0.18, 0.05, 0.5)
	sep_style.content_margin_top = 2.0
	sep_style.content_margin_bottom = 2.0
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	# Tree logo emblem (centered between title and subtitle)
	var logo_container: CenterContainer = CenterContainer.new()
	_tree_logo = Control.new()
	_tree_logo.custom_minimum_size = Vector2(80, 90)
	_tree_logo.set_script(_create_tree_logo_script())
	logo_container.add_child(_tree_logo)
	vbox.add_child(logo_container)

	# Subtitle
	_make_label(vbox, "Welcome to Carlston Wilderness", 36,
		Color(0.30, 0.18, 0.05), HORIZONTAL_ALIGNMENT_CENTER)

	# Spacer between subtitle and section header
	var mid_spacer: Control = Control.new()
	mid_spacer.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(mid_spacer)

	# Section header
	_make_label(vbox, "REGULATIONS & INFORMATION", 32,
		Color(0.30, 0.18, 0.05), HORIZONTAL_ALIGNMENT_CENTER)

	# Bullet points
	var bullets: Array[String] = [
		"Hunting of birds and rabbits is permitted within wilderness boundaries.",
		"Swimming areas are unmarked. Exercise caution near water \u2014 currents can be dangerous.",
		"Deep pits and sinkholes are present in this area. Watch your step.",
		"Collection of wood, stone, and natural resources is permitted.",
		"Severe weather may occur without warning. Seek cover immediately during storms.",
		"Take care of the wilderness.",
	]

	for bullet_text: String in bullets:
		var bullet: Label = _make_label(vbox, "\u2022  " + bullet_text, 28,
			Color(0.30, 0.18, 0.05))
		bullet.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Expanding spacer
	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Close hint (text updated dynamically in _show_overlay)
	close_hint_label = _make_label(vbox, "", 28,
		Color(0.45, 0.40, 0.30), HORIZONTAL_ALIGNMENT_CENTER)


func _create_tree_logo_script() -> GDScript:
	## Returns an inline GDScript for the tree logo Control that draws via _draw().
	var src: String = """extends Control

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	var cx: float = w / 2.0

	# Dark background square
	draw_rect(Rect2(0, 0, w, h), Color(0.12, 0.18, 0.10))

	# Tree crown - dark green triangle (outline/shadow)
	var outer: PackedVector2Array = PackedVector2Array([
		Vector2(cx, h * 0.08),
		Vector2(cx + w * 0.42, h * 0.72),
		Vector2(cx - w * 0.42, h * 0.72),
	])
	draw_colored_polygon(outer, Color(0.15, 0.28, 0.12))

	# Tree crown - lighter green triangle (inner)
	var inner: PackedVector2Array = PackedVector2Array([
		Vector2(cx, h * 0.15),
		Vector2(cx + w * 0.32, h * 0.68),
		Vector2(cx - w * 0.32, h * 0.68),
	])
	draw_colored_polygon(inner, Color(0.22, 0.42, 0.18))

	# Trunk - small brown rectangle
	var trunk_w: float = w * 0.10
	var trunk_h: float = h * 0.15
	draw_rect(Rect2(cx - trunk_w / 2.0, h * 0.70, trunk_w, trunk_h), Color(0.35, 0.22, 0.12))
"""
	var script: GDScript = GDScript.new()
	script.source_code = src
	script.reload()
	return script


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
	# Scale panel margins and vbox spacing
	if _inner_style:
		_inner_style.content_margin_left = 40.0 * sf
		_inner_style.content_margin_right = 40.0 * sf
		_inner_style.content_margin_top = 30.0 * sf
		_inner_style.content_margin_bottom = 30.0 * sf
	if _content_vbox:
		_content_vbox.add_theme_constant_override("separation", int(16 * sf))
	if _tree_logo:
		_tree_logo.custom_minimum_size = Vector2(80 * sf, 90 * sf)
		_tree_logo.queue_redraw()


func interact(player_node: Node) -> bool:
	if is_overlay_visible:
		_hide_overlay()
	else:
		_show_overlay(player_node)
	return true


func get_interaction_text() -> String:
	if is_overlay_visible:
		return "Close Sign"
	return "Read Sign"


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
	overlay_layer.visible = true

	# Scale fonts to current viewport size
	_scale_fonts()

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
