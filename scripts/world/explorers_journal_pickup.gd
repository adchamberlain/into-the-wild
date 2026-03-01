extends StaticBody3D
## Explorer's Journal pickup - a glowing ancient book on a stone pedestal
## found at the bottom of the desert sinkhole. One-time collectible that
## grants lore and unlocks the hang glider recipe.

# State
var is_collected: bool = false

# Shared static materials (avoid per-instance shader compilation)
static var _pedestal_base_mat: StandardMaterial3D = null
static var _pedestal_cap_mat: StandardMaterial3D = null
static var _pedestal_dark_mat: StandardMaterial3D = null
static var _book_mat: StandardMaterial3D = null
static var _book_page_mat: StandardMaterial3D = null
static var _book_spine_mat: StandardMaterial3D = null
static var _materials_initialized: bool = false


func _ready() -> void:
	add_to_group("interactable")
	_ensure_shared_materials()
	call_deferred("_build_visuals")


static func _ensure_shared_materials() -> void:
	if _materials_initialized:
		return
	_materials_initialized = true

	# Pedestal base: grey-brown stone
	_pedestal_base_mat = StandardMaterial3D.new()
	_pedestal_base_mat.albedo_color = Color(0.5, 0.48, 0.45)
	_pedestal_base_mat.roughness = 0.9

	# Pedestal cap: lighter stone top
	_pedestal_cap_mat = StandardMaterial3D.new()
	_pedestal_cap_mat.albedo_color = Color(0.58, 0.55, 0.52)
	_pedestal_cap_mat.roughness = 0.85

	# Pedestal dark band: darker accent ring
	_pedestal_dark_mat = StandardMaterial3D.new()
	_pedestal_dark_mat.albedo_color = Color(0.38, 0.36, 0.33)
	_pedestal_dark_mat.roughness = 0.95

	# Book cover: leather brown with emissive amber glow
	_book_mat = StandardMaterial3D.new()
	_book_mat.albedo_color = Color(0.45, 0.3, 0.15)
	_book_mat.emission_enabled = true
	_book_mat.emission = Color(0.8, 0.6, 0.2)
	_book_mat.emission_energy_multiplier = 1.5
	_book_mat.roughness = 0.7

	# Book page edges: cream/off-white
	_book_page_mat = StandardMaterial3D.new()
	_book_page_mat.albedo_color = Color(0.85, 0.82, 0.72)
	_book_page_mat.emission_enabled = true
	_book_page_mat.emission = Color(0.6, 0.5, 0.25)
	_book_page_mat.emission_energy_multiplier = 0.5
	_book_page_mat.roughness = 0.8

	# Book spine: darker leather
	_book_spine_mat = StandardMaterial3D.new()
	_book_spine_mat.albedo_color = Color(0.35, 0.22, 0.1)
	_book_spine_mat.emission_enabled = true
	_book_spine_mat.emission = Color(0.6, 0.4, 0.15)
	_book_spine_mat.emission_energy_multiplier = 1.0
	_book_spine_mat.roughness = 0.75


func _build_visuals() -> void:
	# ===== STONE PEDESTAL =====
	# Dark base slab
	var base_slab: MeshInstance3D = MeshInstance3D.new()
	var base_mesh: BoxMesh = BoxMesh.new()
	base_mesh.size = Vector3(0.7, 0.08, 0.7)
	base_slab.mesh = base_mesh
	base_slab.material_override = _pedestal_dark_mat
	base_slab.position = Vector3(0, 0.04, 0)
	add_child(base_slab)

	# Main pedestal body
	var pedestal_body: MeshInstance3D = MeshInstance3D.new()
	var body_mesh: BoxMesh = BoxMesh.new()
	body_mesh.size = Vector3(0.6, 0.28, 0.6)
	pedestal_body.mesh = body_mesh
	pedestal_body.material_override = _pedestal_base_mat
	pedestal_body.position = Vector3(0, 0.22, 0)
	add_child(pedestal_body)

	# Dark accent band in middle of pedestal
	var accent_band: MeshInstance3D = MeshInstance3D.new()
	var band_mesh: BoxMesh = BoxMesh.new()
	band_mesh.size = Vector3(0.62, 0.04, 0.62)
	accent_band.mesh = band_mesh
	accent_band.material_override = _pedestal_dark_mat
	accent_band.position = Vector3(0, 0.20, 0)
	add_child(accent_band)

	# Lighter cap on top of pedestal
	var cap: MeshInstance3D = MeshInstance3D.new()
	var cap_mesh: BoxMesh = BoxMesh.new()
	cap_mesh.size = Vector3(0.65, 0.06, 0.65)
	cap.mesh = cap_mesh
	cap.material_override = _pedestal_cap_mat
	cap.position = Vector3(0, 0.39, 0)
	add_child(cap)

	# ===== BOOK ON PEDESTAL =====
	# Main book body (leather cover)
	var book: MeshInstance3D = MeshInstance3D.new()
	var book_mesh: BoxMesh = BoxMesh.new()
	book_mesh.size = Vector3(0.3, 0.06, 0.4)
	book.mesh = book_mesh
	book.material_override = _book_mat
	book.position = Vector3(0, 0.45, 0)
	book.rotation_degrees = Vector3(0, 12, 0)  # Slightly angled for visual interest
	add_child(book)

	# Page edges (thin lighter strip visible on the right side)
	var pages: MeshInstance3D = MeshInstance3D.new()
	var page_mesh: BoxMesh = BoxMesh.new()
	page_mesh.size = Vector3(0.28, 0.04, 0.38)
	pages.mesh = page_mesh
	pages.material_override = _book_page_mat
	pages.position = Vector3(0, 0.45, 0)
	pages.rotation_degrees = Vector3(0, 12, 0)
	add_child(pages)

	# Spine detail (darker strip along one edge)
	var spine: MeshInstance3D = MeshInstance3D.new()
	var spine_mesh: BoxMesh = BoxMesh.new()
	spine_mesh.size = Vector3(0.03, 0.065, 0.4)
	spine.mesh = spine_mesh
	spine.material_override = _book_spine_mat
	# Position the spine on the left edge of the book, accounting for rotation
	spine.position = Vector3(-0.14, 0.45, 0)
	spine.rotation_degrees = Vector3(0, 12, 0)
	add_child(spine)

	# ===== LIGHT =====
	# Warm amber omni light on the book
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "BookGlow"
	light.light_color = Color(0.9, 0.7, 0.3)
	light.light_energy = 0.8
	light.omni_range = 3.0
	light.shadow_enabled = false
	light.position = Vector3(0, 0.55, 0)
	add_child(light)

	# ===== COLLISION =====
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(0.7, 0.5, 0.7)
	collision.shape = shape
	collision.position = Vector3(0, 0.25, 0)
	add_child(collision)


## Get the text to show in interaction prompt.
func get_interaction_text() -> String:
	if is_collected:
		return ""
	return "Take Explorer's Journal"


## Called when player interacts with this node.
func interact(player: Node) -> void:
	if is_collected:
		return
	is_collected = true

	# Add to player inventory
	var inventory: Inventory = _get_player_inventory(player)
	if inventory:
		inventory.add_item("explorers_journal", 1)

	# Play pickup sound
	SFXManager.play_sfx("pickup")

	# Show gold notification
	_show_notification("Found the Explorer's Journal!", Color(1.0, 0.85, 0.3))

	print("[ExplorersJournal] Player picked up the Explorer's Journal")

	# Animate and remove
	_play_pickup_animation()


func _get_player_inventory(player: Node) -> Inventory:
	if player.has_node("Inventory"):
		return player.get_node("Inventory") as Inventory
	if player.has_method("get_inventory"):
		return player.get_inventory()
	return null


func _show_notification(message: String, color: Color) -> void:
	var hud: Node = _find_hud()
	if hud and hud.has_method("show_notification"):
		hud.show_notification(message, color)


func _find_hud() -> Node:
	var root: Node = get_tree().root
	if root.has_node("Main/HUD"):
		return root.get_node("Main/HUD")
	return null


func _play_pickup_animation() -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)

	# Float upward and shrink
	tween.tween_property(self, "position:y", position.y + 1.0, 0.4)
	tween.parallel().tween_property(self, "scale", Vector3.ZERO, 0.4)

	# Remove after animation
	tween.tween_callback(queue_free)
