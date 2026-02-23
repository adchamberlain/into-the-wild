extends Node
class_name TreeSway
## Applies subtle wind sway to all tree foliage nodes.
## Single manager handles all trees for performance (instead of per-tree _process).

# Sway parameters
const SWAY_AMPLITUDE_DEG: float = 2.0  # Max rotation in degrees
const SWAY_FREQUENCY: float = 1.0  # Base oscillation speed (Hz)
const SWAY_DISTANCE_CULL: float = 80.0  # Skip trees beyond this distance from camera

# Registered trees: [tree_node, foliage_nodes_array, phase_offset, base_positions]
var _trees: Array[Dictionary] = []

# Cached camera
var _cached_camera: Camera3D = null

# Performance: only update a batch of trees per frame
const TREES_PER_FRAME: int = 50
var _current_index: int = 0

# Periodic cleanup of freed trees
var _cleanup_timer: float = 0.0
const CLEANUP_INTERVAL: float = 5.0


func register_tree(tree: Node3D, phase_offset: float) -> void:
	## Register a tree for sway animation. Call after adding tree to scene.
	var foliage_data: Array[Dictionary] = []

	for child: Node in tree.get_children():
		if child is MeshInstance3D and child.name.begins_with("Foliage"):
			var base_pos: Vector3 = child.position
			# Higher foliage sways more (normalized by tree height)
			var height_factor: float = clampf((base_pos.y - 3.0) / 5.0, 0.0, 1.0)
			foliage_data.append({
				"node": child,
				"base_x": base_pos.x,
				"base_z": base_pos.z,
				"height_factor": height_factor,
			})

	if foliage_data.is_empty():
		return

	_trees.append({
		"tree": tree,
		"foliage": foliage_data,
		"phase": phase_offset,
	})


func unregister_tree(tree: Node3D) -> void:
	## Remove a tree from sway tracking.
	for i: int in range(_trees.size() - 1, -1, -1):
		if _trees[i]["tree"] == tree:
			_trees.remove_at(i)
			break


func _process(delta: float) -> void:
	if _trees.is_empty():
		return

	# Periodic cleanup of freed trees
	_cleanup_timer += delta
	if _cleanup_timer >= CLEANUP_INTERVAL:
		_cleanup_timer = 0.0
		cleanup_freed_trees()

	# Cache camera
	if not is_instance_valid(_cached_camera):
		_cached_camera = get_viewport().get_camera_3d()

	var cam_pos: Vector3 = Vector3.ZERO
	if _cached_camera:
		cam_pos = _cached_camera.global_position

	var time_sec: float = Time.get_ticks_msec() / 1000.0
	var amplitude: float = deg_to_rad(SWAY_AMPLITUDE_DEG)
	var cull_dist_sq: float = SWAY_DISTANCE_CULL * SWAY_DISTANCE_CULL

	# Process a batch of trees this frame
	var count: int = mini(_trees.size(), TREES_PER_FRAME)
	for i: int in range(count):
		var idx: int = (_current_index + i) % _trees.size()
		var entry: Dictionary = _trees[idx]

		# Skip freed trees (check before casting to avoid "freed object" error)
		if not is_instance_valid(entry["tree"]):
			continue
		var tree: Node3D = entry["tree"] as Node3D

		# Skip if not visible or too far
		if not tree.visible:
			continue
		var dist_sq: float = cam_pos.distance_squared_to(tree.global_position)
		if dist_sq > cull_dist_sq:
			continue

		var phase: float = entry["phase"] as float
		var sway_x: float = sin(time_sec * SWAY_FREQUENCY * TAU + phase) * amplitude
		var sway_z: float = sin(time_sec * SWAY_FREQUENCY * TAU * 0.7 + phase + 1.3) * amplitude

		var foliage_array: Array = entry["foliage"] as Array
		for f_data: Variant in foliage_array:
			var fd: Dictionary = f_data as Dictionary
			if not is_instance_valid(fd["node"]):
				continue
			var node: MeshInstance3D = fd["node"] as MeshInstance3D
			var hf: float = fd["height_factor"] as float
			# Translate foliage laterally based on height factor
			node.position.x = (fd["base_x"] as float) + sway_x * hf * 0.5
			node.position.z = (fd["base_z"] as float) + sway_z * hf * 0.5

	_current_index = (_current_index + count) % maxi(_trees.size(), 1)


func cleanup_freed_trees() -> void:
	## Remove entries for trees that have been freed. Call periodically.
	for i: int in range(_trees.size() - 1, -1, -1):
		if not is_instance_valid(_trees[i]["tree"]):
			_trees.remove_at(i)
