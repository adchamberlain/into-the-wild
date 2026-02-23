extends StaticBody3D
class_name LootDrop
## A small pickup node that sits on the ground after an animal is killed.
## Player walks up and interacts (E / L2) to collect the loot.
## Drops to terrain height on spawn so mid-air kills land on the ground.

var loot: Dictionary = {}  # { "raw_meat": 1, "feathers": 2 }
var despawn_timer: float = 120.0  # Despawn after 2 minutes if not collected


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 1
	collision_mask = 0
	_build_visual()
	_drop_to_terrain()


func _process(delta: float) -> void:
	despawn_timer -= delta
	if despawn_timer <= 0:
		queue_free()


func _drop_to_terrain() -> void:
	var chunk_manager: Node = get_tree().get_first_node_in_group("chunk_manager")
	if chunk_manager and chunk_manager.has_method("get_height_at"):
		var terrain_y: float = chunk_manager.get_height_at(global_position.x, global_position.z)
		if terrain_y > -100.0:  # Valid height
			global_position.y = terrain_y


func _build_visual() -> void:
	# Tied cloth bundle with loot items peeking out
	var container: Node3D = Node3D.new()
	container.name = "LootVisual"
	add_child(container)

	# Base cloth wrap (slightly flattened, wider than tall)
	var cloth: MeshInstance3D = MeshInstance3D.new()
	var cloth_mesh: BoxMesh = BoxMesh.new()
	cloth_mesh.size = Vector3(0.4, 0.25, 0.35)
	cloth.mesh = cloth_mesh
	cloth.position = Vector3(0, 0.13, 0)
	var cloth_mat: StandardMaterial3D = StandardMaterial3D.new()
	cloth_mat.albedo_color = Color(0.55, 0.42, 0.28)
	cloth.material_override = cloth_mat
	container.add_child(cloth)

	# Cloth knot/tie on top
	var knot: MeshInstance3D = MeshInstance3D.new()
	var knot_mesh: BoxMesh = BoxMesh.new()
	knot_mesh.size = Vector3(0.2, 0.12, 0.15)
	knot.mesh = knot_mesh
	knot.position = Vector3(0, 0.28, 0)
	var knot_mat: StandardMaterial3D = StandardMaterial3D.new()
	knot_mat.albedo_color = Color(0.48, 0.36, 0.22)
	knot.material_override = knot_mat
	container.add_child(knot)

	# Ear/poking corner (cloth bunching up on one side)
	var ear: MeshInstance3D = MeshInstance3D.new()
	var ear_mesh: BoxMesh = BoxMesh.new()
	ear_mesh.size = Vector3(0.1, 0.1, 0.1)
	ear.mesh = ear_mesh
	ear.position = Vector3(0.15, 0.26, 0.05)
	ear.rotation_degrees = Vector3(0, 0, 20)
	var ear_mat: StandardMaterial3D = StandardMaterial3D.new()
	ear_mat.albedo_color = Color(0.5, 0.38, 0.24)
	ear.material_override = ear_mat
	container.add_child(ear)

	# Item peeking out (a small colored piece suggesting contents)
	var peek: MeshInstance3D = MeshInstance3D.new()
	var peek_mesh: BoxMesh = BoxMesh.new()
	peek_mesh.size = Vector3(0.08, 0.06, 0.12)
	peek.mesh = peek_mesh
	peek.position = Vector3(-0.1, 0.27, -0.08)
	var peek_mat: StandardMaterial3D = StandardMaterial3D.new()
	# Color hint based on loot contents
	if loot.has("feathers"):
		peek_mat.albedo_color = Color(0.85, 0.85, 0.8)  # White feather
	elif loot.has("hide"):
		peek_mat.albedo_color = Color(0.6, 0.45, 0.3)  # Tan hide
	else:
		peek_mat.albedo_color = Color(0.7, 0.25, 0.2)  # Reddish meat
	peek.material_override = peek_mat
	container.add_child(peek)

	# Rope tie around the middle
	var rope: MeshInstance3D = MeshInstance3D.new()
	var rope_mesh: BoxMesh = BoxMesh.new()
	rope_mesh.size = Vector3(0.44, 0.04, 0.39)
	rope.mesh = rope_mesh
	rope.position = Vector3(0, 0.2, 0)
	var rope_mat: StandardMaterial3D = StandardMaterial3D.new()
	rope_mat.albedo_color = Color(0.65, 0.55, 0.35)
	rope.material_override = rope_mat
	container.add_child(rope)

	# Collision shape for raycast detection
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(0.6, 0.5, 0.6)
	col.shape = shape
	col.position = Vector3(0, 0.25, 0)
	add_child(col)


func get_interaction_text() -> String:
	var parts: Array[String] = []
	for item_type: String in loot:
		var amount: int = loot[item_type]
		parts.append("%dx %s" % [amount, item_type.replace("_", " ")])
	return "Collect " + ", ".join(parts)


func interact(player: Node) -> bool:
	var inv: Inventory = player.inventory if "inventory" in player else null
	if not inv:
		return false

	var hud: Node = get_tree().get_first_node_in_group("hud")
	var loot_msg: String = ""

	for item_type: String in loot:
		var amount: int = loot[item_type]
		inv.add_item(item_type, amount)
		if loot_msg != "":
			loot_msg += ", "
		loot_msg += "%dx %s" % [amount, item_type.replace("_", " ")]

	if hud and hud.has_method("show_notification") and loot_msg != "":
		hud.show_notification("Collected: " + loot_msg, Color(0.6, 1.0, 0.6))

	SFXManager.play_sfx("pickup")
	queue_free()
	return true
