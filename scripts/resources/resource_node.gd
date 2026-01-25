extends StaticBody3D
class_name ResourceNode
## A harvestable resource node in the world (branches, rocks, berries, etc.)

signal gathered(resource_type: String, amount: int)
signal depleted()

# Resource properties
@export var resource_type: String = "branch"
@export var resource_amount: int = 1
@export var interaction_text: String = "Gather"

# Secondary resource drop (e.g., trees also drop branches)
@export var secondary_resource_type: String = ""
@export var secondary_resource_amount: int = 0

# Tool requirement (empty string = no tool needed)
@export var required_tool: String = ""
@export var chops_required: int = 1  # How many chops/hits to harvest (for trees)

# Visual feedback
@export var gather_scale_punch: float = 0.8
@export var gather_animation_duration: float = 0.2

# State
var is_depleted: bool = false
var is_animating: bool = false
var original_scale: Vector3
var chop_progress: int = 0  # Current chops received

# Respawn tracking
var depleted_time: float = 0.0  # When the resource was depleted (game time)
var node_name: String = ""  # Original node name for save/load identification


func _ready() -> void:
	# Store original scale for animation
	original_scale = scale
	# Store node name for identification
	node_name = name
	# Add to interactable group so raycast can find us
	add_to_group("interactable")
	add_to_group("resource_node")


## Called when player interacts with this node. Returns true if gathering succeeded.
func interact(player: Node) -> bool:
	if is_depleted or is_animating:
		return false

	# Check tool requirement
	if required_tool != "":
		var equipment: Equipment = _get_player_equipment(player)
		if not equipment or not equipment.has_tool_equipped(required_tool):
			print("[Resource] Requires %s tool to harvest" % required_tool)
			return false

	# For multi-chop resources, this is handled by receive_chop instead
	if chops_required > 1:
		print("[Resource] Use R to chop this resource")
		return false

	# Play gather animation
	_play_gather_animation()

	# Emit signal for any listeners
	gathered.emit(resource_type, resource_amount)

	# Add to player inventory if they have one
	var inventory: Inventory = _get_player_inventory(player)
	if inventory:
		inventory.add_item(resource_type, resource_amount)

	# Mark as depleted and hide
	is_depleted = true
	depleted.emit()

	return true


## Called when player chops this resource with a tool. Returns true if chop was valid.
func receive_chop(player: Node) -> bool:
	if is_depleted or is_animating:
		return false

	# Check tool requirement
	if required_tool != "":
		var equipment: Equipment = _get_player_equipment(player)
		if not equipment or not equipment.has_tool_equipped(required_tool):
			return false

	chop_progress += 1
	print("[Resource] Chop %d/%d" % [chop_progress, chops_required])

	# Play chop feedback animation (shake)
	_play_chop_animation()

	# Check if fully harvested
	if chop_progress >= chops_required:
		# Delay the gather to let chop animation play
		get_tree().create_timer(0.2).timeout.connect(_complete_harvest.bind(player))

	return true


func _complete_harvest(player: Node) -> void:
	# Play gather animation
	_play_gather_animation()

	# Emit signal for any listeners
	gathered.emit(resource_type, resource_amount)

	# Add to player inventory if they have one
	var inventory: Inventory = _get_player_inventory(player)
	if inventory:
		inventory.add_item(resource_type, resource_amount)
		# Also add secondary resource if defined
		if secondary_resource_type != "" and secondary_resource_amount > 0:
			inventory.add_item(secondary_resource_type, secondary_resource_amount)

	# Mark as depleted and hide
	is_depleted = true
	depleted.emit()


## Get the text to show in interaction prompt.
func get_interaction_text() -> String:
	var text: String = "%s %s" % [interaction_text, resource_type.capitalize()]
	if required_tool != "" and chops_required > 1:
		text = "[R] Chop %s (%d/%d)" % [resource_type.capitalize(), chop_progress, chops_required]
	elif required_tool != "":
		text += " (needs %s)" % required_tool.capitalize()
	return text


func _get_player_inventory(player: Node) -> Inventory:
	# Try to find Inventory node as child of player
	if player.has_node("Inventory"):
		return player.get_node("Inventory") as Inventory
	# Try to find it as a property
	if player.has_method("get_inventory"):
		return player.get_inventory()
	return null


func _get_player_equipment(player: Node) -> Equipment:
	if player.has_node("Equipment"):
		return player.get_node("Equipment") as Equipment
	if player.has_method("get_equipment"):
		return player.get_equipment()
	return null


func _play_chop_animation() -> void:
	# Quick shake animation to show the chop hit
	is_animating = true
	var tween: Tween = create_tween()

	# Shake left-right quickly
	var shake_amount: float = 0.1
	tween.tween_property(self, "position:x", position.x + shake_amount, 0.05)
	tween.tween_property(self, "position:x", position.x - shake_amount, 0.05)
	tween.tween_property(self, "position:x", position.x + shake_amount * 0.5, 0.05)
	tween.tween_property(self, "position:x", position.x, 0.05)

	tween.tween_callback(func(): is_animating = false)


func _play_gather_animation() -> void:
	is_animating = true

	# Create a simple scale punch animation using a tween
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	# Scale down quickly
	tween.tween_property(self, "scale", original_scale * gather_scale_punch, gather_animation_duration * 0.3)
	# Then fade out and scale to zero
	tween.tween_property(self, "scale", Vector3.ZERO, gather_animation_duration * 0.7)

	# When animation completes, remove the node entirely
	tween.tween_callback(_on_gather_animation_complete)


func _on_gather_animation_complete() -> void:
	is_animating = false
	# Hide the node instead of destroying it (for respawning)
	_set_depleted_state(true)


## Set the depleted visual state (hidden and non-interactive).
func _set_depleted_state(depleted: bool) -> void:
	is_depleted = depleted
	visible = not depleted

	# Disable/enable collision
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = depleted

	if depleted:
		# Remove from interactable group while depleted
		remove_from_group("interactable")
	else:
		# Re-add to interactable group when respawned
		add_to_group("interactable")


## Respawn this resource node (restore to harvestable state).
func respawn() -> void:
	# Reset state
	chop_progress = 0
	scale = original_scale

	# Restore visibility and collision
	_set_depleted_state(false)

	print("[Resource] %s respawned" % node_name)
