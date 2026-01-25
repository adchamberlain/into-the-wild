extends StaticBody3D
class_name FishingSpot
## A fishing spot where players can catch fish with a fishing rod.

signal fish_caught(fish_type: String, amount: int)
signal spot_depleted()
signal spot_respawned()

# Fishing properties
@export var fish_type: String = "fish"
@export var respawn_time_hours: float = 6.0

# Fishing timing
@export var min_wait_time: float = 3.0  # Minimum seconds to wait for bite
@export var max_wait_time: float = 8.0  # Maximum seconds to wait for bite
@export var catch_window: float = 2.0   # Seconds to press R after bite

# State
var is_depleted: bool = false
var is_fishing: bool = false
var waiting_for_catch: bool = false
var current_player: Node = null
var catch_timer: float = 0.0
var catch_window_timer: float = 0.0

# Respawn tracking
var depleted_hour: int = 0
var depleted_minute: int = 0


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("fishing_spot")


func _process(delta: float) -> void:
	if not is_fishing:
		return

	if waiting_for_catch:
		# Count down catch window
		catch_window_timer -= delta
		if catch_window_timer <= 0:
			# Missed the catch
			_fail_catch()
	else:
		# Count down to fish bite
		catch_timer -= delta
		if catch_timer <= 0:
			# Fish is biting!
			_fish_bite()


func interact(player: Node) -> bool:
	if is_depleted:
		return false

	# Check if player has fishing rod equipped
	var equipment: Node = _get_player_equipment(player)
	if not equipment or not equipment.has_tool_equipped("fishing"):
		print("[FishingSpot] Need a fishing rod equipped!")
		return false

	if not is_fishing:
		# Start fishing
		_start_fishing(player)
		return true
	elif waiting_for_catch:
		# Try to catch the fish
		_attempt_catch()
		return true

	return false


func get_interaction_text() -> String:
	if is_depleted:
		return "Depleted"
	if waiting_for_catch:
		return "[R] Catch!"
	if is_fishing:
		return "Fishing..."
	return "[R] Cast Line"


func _start_fishing(player: Node) -> void:
	is_fishing = true
	waiting_for_catch = false
	current_player = player
	catch_timer = randf_range(min_wait_time, max_wait_time)
	print("[FishingSpot] Line cast... waiting for a bite")


func _fish_bite() -> void:
	waiting_for_catch = true
	catch_window_timer = catch_window
	print("[FishingSpot] A fish is biting! Press R quickly!")
	_show_notification("Fish on the line!", Color(0.4, 0.8, 1.0))


func _attempt_catch() -> void:
	if not waiting_for_catch:
		return

	# Success! Caught a fish
	is_fishing = false
	waiting_for_catch = false

	# Add fish to player inventory
	if current_player:
		var inventory: Node = _get_player_inventory(current_player)
		if inventory:
			inventory.add_item(fish_type, 1)
			print("[FishingSpot] Caught a %s!" % fish_type)
			_show_notification("Caught a fish!", Color(0.4, 1.0, 0.4))

		# Use durability on the fishing rod
		var equipment: Node = _get_player_equipment(current_player)
		if equipment and equipment.has_method("use_durability"):
			equipment.use_durability(1)

	# Deplete the spot
	_deplete()
	fish_caught.emit(fish_type, 1)


func _fail_catch() -> void:
	is_fishing = false
	waiting_for_catch = false
	print("[FishingSpot] The fish got away...")
	_show_notification("The fish got away!", Color(1.0, 0.6, 0.4))


func _deplete() -> void:
	is_depleted = true
	spot_depleted.emit()

	# Track depletion time
	var time_manager: Node = _find_time_manager()
	if time_manager:
		depleted_hour = time_manager.current_hour
		depleted_minute = time_manager.current_minute

	# Visual feedback - darken the water
	var mesh: MeshInstance3D = get_node_or_null("WaterMesh")
	if mesh and mesh.material_override:
		var mat: StandardMaterial3D = mesh.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(0.2, 0.3, 0.35, 0.7)

	print("[FishingSpot] Fishing spot depleted, will respawn later")


func respawn() -> void:
	is_depleted = false
	is_fishing = false
	waiting_for_catch = false
	current_player = null

	# Restore water color
	var mesh: MeshInstance3D = get_node_or_null("WaterMesh")
	if mesh and mesh.material_override:
		var mat: StandardMaterial3D = mesh.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(0.2, 0.4, 0.5, 0.7)

	spot_respawned.emit()
	print("[FishingSpot] Fishing spot respawned")


func _get_player_inventory(player: Node) -> Node:
	if player.has_method("get_inventory"):
		return player.get_inventory()
	if player.has_node("Inventory"):
		return player.get_node("Inventory")
	return null


func _get_player_equipment(player: Node) -> Node:
	if player.has_method("get_equipment"):
		return player.get_equipment()
	if player.has_node("Equipment"):
		return player.get_node("Equipment")
	return null


func _find_time_manager() -> Node:
	var root: Node = get_tree().root
	if root.has_node("Main/TimeManager"):
		return root.get_node("Main/TimeManager")
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
