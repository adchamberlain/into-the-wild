extends StaticBody3D
class_name LootDrop
## A small pickup node that sits on the ground after an animal is killed.
## Player walks up and interacts (E / L2) to collect the loot.

var loot: Dictionary = {}  # { "raw_meat": 1, "feathers": 2 }
var despawn_timer: float = 120.0  # Despawn after 2 minutes if not collected


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 1
	collision_mask = 0
	_build_visual()


func _process(delta: float) -> void:
	despawn_timer -= delta
	if despawn_timer <= 0:
		queue_free()


func _build_visual() -> void:
	# Small burlap-sack-style loot bag on the ground
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(0.4, 0.3, 0.4)
	mesh_instance.mesh = box
	mesh_instance.position = Vector3(0, 0.15, 0)

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.4, 0.25)  # Brown sack color
	mesh_instance.material_override = mat
	add_child(mesh_instance)

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
