extends ResourceNode
class_name BerryBush
## A berry bush resource that shows berries on a green bush.
## When harvested, only the berries disappear - the bush remains visible.

@onready var berries_container: Node3D = $Berries


func _ready() -> void:
	super._ready()
	# Ensure berries are visible at start
	if berries_container:
		berries_container.visible = true


## Override the gather animation to only hide the berries, not the whole bush.
func _play_gather_animation() -> void:
	is_animating = true

	if not berries_container:
		# Fallback to default behavior if no berries container
		super._play_gather_animation()
		return

	# Animate the berries shrinking and fading
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)

	# Scale berries down to nothing
	tween.tween_property(berries_container, "scale", Vector3.ZERO, gather_animation_duration)

	# When animation completes, mark as depleted but stay visible
	tween.tween_callback(_on_berry_gather_complete)


func _on_berry_gather_complete() -> void:
	is_animating = false
	berries_container.visible = false

	# Mark as depleted but don't hide the bush
	is_depleted = true

	# Disable collision so player can't interact again
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = true

	# Remove from interactable group while depleted
	remove_from_group("interactable")


## Override respawn to restore berries visibility.
func respawn() -> void:
	# Reset state
	chop_progress = 0
	scale = original_scale
	is_depleted = false

	# Restore berries
	if berries_container:
		berries_container.visible = true
		berries_container.scale = Vector3.ONE

	# Re-enable collision
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = false

	# Re-add to interactable group
	add_to_group("interactable")

	print("[Resource] %s respawned" % node_name)
