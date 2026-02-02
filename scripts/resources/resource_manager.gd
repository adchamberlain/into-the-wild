extends Node
class_name ResourceManager
## Manages resource nodes in the world, including respawning depleted resources.

signal resource_respawned(resource_node: ResourceNode)

# Respawn settings (in game hours)
@export var respawn_time_hours: float = 6.0  # Game hours until respawn for regular resources
@export var tree_respawn_time_hours: float = 168.0  # Game hours until tree respawn (7 days default)
@export var respawn_enabled: bool = true

# Node references
@export var time_manager_path: NodePath
@export var resources_container_path: NodePath
@export var campsite_manager_path: NodePath

var time_manager: Node
var resources_container: Node3D
var campsite_manager: Node

# Tracking
var depleted_resources: Array[Dictionary] = []  # {node, depleted_at_hour, depleted_at_minute, days_elapsed}
var all_resources: Array[ResourceNode] = []
var last_hour: int = -1  # Track for day rollover

# Performance: throttle respawn checks
const RESPAWN_CHECK_INTERVAL: float = 5.0  # Only check every 5 seconds
var respawn_check_timer: float = 0.0


func _ready() -> void:
	# Get references
	if time_manager_path:
		time_manager = get_node_or_null(time_manager_path)

	if resources_container_path:
		resources_container = get_node_or_null(resources_container_path)

	if campsite_manager_path:
		campsite_manager = get_node_or_null(campsite_manager_path)

	# Find and register all resource nodes
	call_deferred("_discover_resources")


func _process(delta: float) -> void:
	if not time_manager:
		return

	# Track day rollover for multi-day respawns
	var current_hour: int = time_manager.current_hour
	if last_hour >= 0 and current_hour == 0 and last_hour == 23:
		_on_day_changed()
	last_hour = current_hour

	if not respawn_enabled or depleted_resources.is_empty():
		return

	# Throttle respawn checks - no need to check every frame
	respawn_check_timer += delta
	if respawn_check_timer >= RESPAWN_CHECK_INTERVAL:
		respawn_check_timer = 0.0
		_check_respawns()


## Called when a new day starts (hour rolls over from 23 to 0).
func _on_day_changed() -> void:
	# Increment days_elapsed for all depleted resources
	for info: Dictionary in depleted_resources:
		info["days_elapsed"] = info.get("days_elapsed", 0) + 1


## Discover all resource nodes in the resources container.
func _discover_resources() -> void:
	if not resources_container:
		# Try to find Resources node in parent
		resources_container = get_parent().get_node_or_null("Resources")

	if not resources_container:
		push_warning("[ResourceManager] No resources container found")
		return

	# Find all resource nodes
	for child in resources_container.get_children():
		if child is ResourceNode:
			_register_resource(child)

	print("[ResourceManager] Discovered %d resource nodes" % all_resources.size())


## Register a resource node for tracking.
func _register_resource(resource: ResourceNode) -> void:
	if resource in all_resources:
		return

	all_resources.append(resource)

	# Connect to depleted signal
	if not resource.depleted.is_connected(_on_resource_depleted):
		resource.depleted.connect(_on_resource_depleted.bind(resource))


## Called when a resource is depleted.
func _on_resource_depleted(resource: ResourceNode) -> void:
	if not time_manager:
		return

	# Record when this resource was depleted
	var depleted_info: Dictionary = {
		"node": resource,
		"depleted_hour": time_manager.current_hour,
		"depleted_minute": time_manager.current_minute,
		"days_elapsed": 0
	}
	depleted_resources.append(depleted_info)

	var type_label: String = "tree" if resource.resource_type == "wood" else resource.resource_type
	print("[ResourceManager] %s (%s) depleted at %d:%02d" % [resource.node_name, type_label, time_manager.current_hour, time_manager.current_minute])


## Check if any depleted resources should respawn.
func _check_respawns() -> void:
	if not time_manager:
		return

	var current_time_minutes: float = time_manager.current_hour * 60.0 + time_manager.current_minute

	var to_respawn: Array[Dictionary] = []

	for info: Dictionary in depleted_resources:
		var depleted_time_minutes: float = info["depleted_hour"] * 60.0 + info["depleted_minute"]

		# Determine respawn time based on resource type
		var resource: ResourceNode = info["node"]
		var respawn_minutes: float = respawn_time_hours * 60.0
		if is_instance_valid(resource) and resource.resource_type == "wood":
			respawn_minutes = tree_respawn_time_hours * 60.0

		# Handle day wrap-around (track elapsed days)
		var elapsed: float = current_time_minutes - depleted_time_minutes
		var days_elapsed: int = info.get("days_elapsed", 0)
		if elapsed < 0:
			elapsed += 24.0 * 60.0  # Add a full day

		# Add accumulated days
		elapsed += days_elapsed * 24.0 * 60.0

		if elapsed >= respawn_minutes:
			to_respawn.append(info)

	# Respawn resources (but not if a structure is in the way)
	for info: Dictionary in to_respawn:
		var resource: ResourceNode = info["node"]
		if is_instance_valid(resource):
			# Check if there's a structure blocking respawn
			if _is_structure_blocking_respawn(resource.global_position):
				# Don't respawn yet - structure is in the way
				# Keep in depleted list to check again later
				continue

			resource.respawn()
			resource_respawned.emit(resource)

		depleted_resources.erase(info)


## Check if a structure is blocking respawn at the given position.
## Trees shouldn't respawn if a structure has been placed where they were.
func _is_structure_blocking_respawn(position: Vector3) -> bool:
	if not campsite_manager:
		# Try to find campsite manager if not set
		campsite_manager = get_node_or_null("/root/Main/CampsiteManager")
		if not campsite_manager:
			return false

	if not campsite_manager.has_method("get_placed_structures"):
		return false

	var structures: Array = campsite_manager.get_placed_structures()
	var resource_pos_2d: Vector2 = Vector2(position.x, position.z)

	# Buffer distance - trees are about 1-2 units radius, structures have footprints
	const TREE_RADIUS: float = 1.5

	for structure: Node in structures:
		if not is_instance_valid(structure):
			continue

		var struct_pos: Vector3 = structure.global_position
		var struct_pos_2d: Vector2 = Vector2(struct_pos.x, struct_pos.z)

		# Get structure's footprint radius
		var footprint: float = 1.0
		if "structure_type" in structure:
			footprint = StructureData.get_footprint_radius(structure.structure_type)

		# Check if tree would overlap with structure (edge to edge)
		var distance: float = resource_pos_2d.distance_to(struct_pos_2d)
		var min_distance: float = footprint + TREE_RADIUS

		if distance < min_distance:
			return true

	return false


## Get all resource nodes (for save/load).
func get_all_resources() -> Array[ResourceNode]:
	return all_resources


## Get depleted resource data for saving.
func get_depleted_data() -> Array[Dictionary]:
	var data: Array[Dictionary] = []
	for info: Dictionary in depleted_resources:
		var resource: ResourceNode = info["node"]
		if is_instance_valid(resource):
			data.append({
				"node_name": resource.node_name,
				"depleted_hour": info["depleted_hour"],
				"depleted_minute": info["depleted_minute"]
			})
	return data


## Restore depleted state from save data.
func load_depleted_data(data: Array) -> void:
	for saved_info: Dictionary in data:
		var node_name: String = saved_info.get("node_name", "")
		var resource: ResourceNode = _find_resource_by_name(node_name)
		if resource:
			# Mark as depleted
			resource._set_depleted_state(true)
			# Add to tracking
			depleted_resources.append({
				"node": resource,
				"depleted_hour": saved_info.get("depleted_hour", 0),
				"depleted_minute": saved_info.get("depleted_minute", 0)
			})


## Find a resource node by its original name.
func _find_resource_by_name(node_name: String) -> ResourceNode:
	for resource: ResourceNode in all_resources:
		if resource.node_name == node_name:
			return resource
	return null


## Force respawn all depleted resources (for testing).
func respawn_all() -> void:
	for info: Dictionary in depleted_resources:
		var resource: ResourceNode = info["node"]
		if is_instance_valid(resource):
			resource.respawn()
			resource_respawned.emit(resource)

	depleted_resources.clear()
	print("[ResourceManager] All resources respawned")
