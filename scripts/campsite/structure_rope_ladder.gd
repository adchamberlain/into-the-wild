extends StructureBase
class_name StructureRopeLadder
## A climbable rope ladder for scaling steep cliffs.

# Ladder settings
@export var ladder_height: float = 8.0  # How tall the ladder is
@export var climb_speed: float = 4.0  # How fast player climbs
@export var rung_spacing: float = 0.5  # Visual spacing between rungs

# State
var player_on_ladder: Node = null
var climb_area: Area3D


func _ready() -> void:
	super._ready()
	structure_type = "rope_ladder"
	structure_name = "Rope Ladder"
	interaction_text = "Climb"

	# Find or create the climb detection area
	climb_area = get_node_or_null("ClimbArea")
	if climb_area:
		climb_area.body_entered.connect(_on_climb_area_body_entered)
		climb_area.body_exited.connect(_on_climb_area_body_exited)


func _physics_process(delta: float) -> void:
	if not player_on_ladder:
		return

	# Handle climbing input
	_process_climbing(delta)


func _process_climbing(delta: float) -> void:
	if not is_instance_valid(player_on_ladder):
		player_on_ladder = null
		return

	var player: CharacterBody3D = player_on_ladder as CharacterBody3D
	if not player:
		return

	# Get vertical input (forward/backward or jump for up, crouch-like for down)
	var climb_input: float = 0.0

	# Use move_forward/backward for up/down on ladder
	climb_input += Input.get_action_strength("move_forward")  # W or stick up = climb up
	climb_input -= Input.get_action_strength("move_backward")  # S or stick down = climb down

	# Jump also makes you climb up
	if Input.is_action_pressed("jump"):
		climb_input = 1.0

	if abs(climb_input) > 0.1:
		# Player is actively climbing
		var climb_velocity: float = climb_input * climb_speed

		# Calculate new position
		var new_y: float = player.global_position.y + climb_velocity * delta

		# Clamp to ladder bounds
		var ladder_bottom: float = global_position.y
		var ladder_top: float = global_position.y + ladder_height

		# Allow dismounting at top by going slightly above
		if new_y >= ladder_top:
			# Player reached top - push them forward off the ladder
			_dismount_at_top(player)
			return

		# Allow dismounting at bottom
		if new_y <= ladder_bottom:
			new_y = ladder_bottom
			# Let normal physics take over
			player_on_ladder = null
			return

		# Apply climbing position (override normal physics)
		player.velocity = Vector3.ZERO
		player.global_position.y = new_y

		# Keep player aligned with ladder
		var ladder_pos: Vector3 = global_position
		var forward: Vector3 = -global_transform.basis.z
		player.global_position.x = ladder_pos.x + forward.x * 0.3
		player.global_position.z = ladder_pos.z + forward.z * 0.3
	else:
		# Player stationary on ladder - prevent falling
		player.velocity = Vector3.ZERO


func _dismount_at_top(player: CharacterBody3D) -> void:
	# Push player forward and up slightly when reaching top
	var forward: Vector3 = -global_transform.basis.z.normalized()
	player.global_position = global_position + Vector3(0, ladder_height + 0.5, 0) + forward * 1.0
	player.velocity = forward * 2.0  # Small push forward
	player_on_ladder = null


func _on_climb_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		# Player can now grab the ladder
		player_on_ladder = body
		print("[RopeLadder] Player grabbed ladder")


func _on_climb_area_body_exited(body: Node3D) -> void:
	if body == player_on_ladder:
		player_on_ladder = null
		print("[RopeLadder] Player released ladder")


## Override interact to grab the ladder
func interact(player: Node) -> bool:
	if not super.interact(player):
		return false

	# Start climbing
	player_on_ladder = player
	print("[RopeLadder] Player started climbing")
	return true


## Get the height of this ladder
func get_ladder_height() -> float:
	return ladder_height


## Set the ladder height (called when placing to match cliff height)
func set_ladder_height(height: float) -> void:
	ladder_height = height
	# Rebuild visuals if needed
	_rebuild_ladder_visuals()


func _rebuild_ladder_visuals() -> void:
	# This would rebuild the ladder mesh to match the new height
	# For programmatic ladders, this is handled during creation
	pass
