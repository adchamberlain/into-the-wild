extends Node3D
## Generates a blocky Minecraft-style terrain with stepped hills and forest.

@export var terrain_size: int = 100
@export var cell_size: float = 3.0  # Larger cells for gentler terrain
@export var height_scale: float = 6.0  # Lower hills
@export var height_step: float = 1.0  # Larger steps for visible Minecraft-style terraces
@export var noise_scale: float = 0.02  # Broader noise for rolling hills

# Tree spawning settings
@export var tree_density: float = 0.25  # Base probability of tree per cell (increased for denser forest)
@export var tree_min_distance: float = 14.0  # Minimum distance from campsite center
@export var tree_max_distance: float = 60.0  # Maximum distance for tree spawning
@export var tree_grid_size: float = 2.5  # Grid cell size for placement

# Pond settings - natural depression in terrain with fishing spot
var pond_center: Vector2 = Vector2(15.0, 12.0)  # Just outside campsite
var pond_radius: float = 8.0  # Size of the pond depression
var pond_depth: float = 1.5  # How deep the depression is
var fishing_spot_scene: PackedScene

# Minecraft-style colors (matched to actual Minecraft forest biome)
var grass_color: Color = Color(0.30, 0.50, 0.22)  # Forest green like Minecraft (not mint!)
var dirt_color: Color = Color(0.52, 0.36, 0.22)   # Rich brown dirt like Minecraft

var noise: FastNoiseLite
var terrain_mesh: MeshInstance3D
var terrain_collision: StaticBody3D

# Cache heights for collision
var height_cache: Dictionary = {}

# Tree scenes (multiple types)
var tree_scene: PackedScene  # Small oak
var big_tree_scene: PackedScene  # Big oak
var birch_tree_scene: PackedScene  # Birch
var spawned_trees: Array[Node3D] = []
var forest_noise: FastNoiseLite  # Separate noise for forest density


func _ready() -> void:
	_setup_noise()
	_generate_blocky_terrain()
	_load_tree_scene()
	_load_fishing_spot_scene()
	# Defer spawning to ensure Resources node exists
	call_deferred("_spawn_forest")
	call_deferred("_spawn_ground_decorations")
	call_deferred("_spawn_pond")


func _setup_noise() -> void:
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = randi()
	noise.fractal_octaves = 2  # Fewer octaves for broader, more plateau-like hills
	noise.frequency = noise_scale


func _generate_blocky_terrain() -> void:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_size: float = terrain_size / 2.0
	var cells_per_side: int = int(terrain_size / cell_size)

	# Generate each cell as a flat quad at its quantized height
	for cz in range(cells_per_side):
		for cx in range(cells_per_side):
			var world_x: float = (cx * cell_size) - half_size
			var world_z: float = (cz * cell_size) - half_size

			# Get quantized height for this cell's center
			var center_x: float = world_x + cell_size / 2.0
			var center_z: float = world_z + cell_size / 2.0
			var height: float = _get_blocky_height(center_x, center_z)

			# Cache for collision
			height_cache[Vector2i(cx, cz)] = height

			# Create top face of this cell (flat quad) with color variation
			_add_top_face(surface_tool, world_x, world_z, cell_size, height, cx, cz)

			# Create side faces where there's a height difference with neighbors
			_add_side_faces(surface_tool, cx, cz, world_x, world_z, cell_size, height, cells_per_side)

	# Commit mesh (no generate_normals - we set them manually for flat shading)
	var mesh: ArrayMesh = surface_tool.commit()

	terrain_mesh = MeshInstance3D.new()
	terrain_mesh.mesh = mesh
	terrain_mesh.material_override = _create_terrain_material()
	add_child(terrain_mesh)

	# Create collision
	_create_collision(mesh)


func _add_top_face(st: SurfaceTool, x: float, z: float, size: float, height: float, cx: int, cz: int) -> void:
	# Four corners of the top face
	var v0 := Vector3(x, height, z)
	var v1 := Vector3(x + size, height, z)
	var v2 := Vector3(x + size, height, z + size)
	var v3 := Vector3(x, height, z + size)

	var normal := Vector3.UP

	# Add subtle color variation per cell (like Minecraft's pixel texture)
	# Use cell coordinates to create consistent pseudo-random variation
	var variation: float = sin(cx * 12.9898 + cz * 78.233) * 0.08  # -0.08 to +0.08
	var cell_grass: Color = Color(
		clamp(grass_color.r + variation, 0.15, 0.45),
		clamp(grass_color.g + variation * 0.5, 0.35, 0.6),
		clamp(grass_color.b + variation * 0.3, 0.12, 0.35)
	)

	# Triangle 1 - grass color for top faces
	st.set_color(cell_grass)
	st.set_normal(normal)
	st.add_vertex(v0)
	st.set_color(cell_grass)
	st.set_normal(normal)
	st.add_vertex(v2)
	st.set_color(cell_grass)
	st.set_normal(normal)
	st.add_vertex(v1)

	# Triangle 2
	st.set_color(cell_grass)
	st.set_normal(normal)
	st.add_vertex(v0)
	st.set_color(cell_grass)
	st.set_normal(normal)
	st.add_vertex(v3)
	st.set_color(cell_grass)
	st.set_normal(normal)
	st.add_vertex(v2)


func _add_side_faces(st: SurfaceTool, cx: int, cz: int, x: float, z: float, size: float, height: float, cells_per_side: int) -> void:
	# Check each neighbor and add side face if there's a drop
	var half_size: float = terrain_size / 2.0

	# North side (z-)
	if cz > 0:
		var neighbor_height: float = height_cache.get(Vector2i(cx, cz - 1), 0.0)
		if height > neighbor_height:
			_add_side_quad(st, Vector3(x, height, z), Vector3(x + size, height, z),
						   Vector3(x + size, neighbor_height, z), Vector3(x, neighbor_height, z),
						   Vector3(0, 0, -1))

	# South side (z+)
	if cz < cells_per_side - 1:
		var nz: float = ((cz + 1) * size) - half_size + size / 2.0
		var nx: float = x + size / 2.0
		var neighbor_height: float = _get_blocky_height(nx, nz)
		if height > neighbor_height:
			_add_side_quad(st, Vector3(x + size, height, z + size), Vector3(x, height, z + size),
						   Vector3(x, neighbor_height, z + size), Vector3(x + size, neighbor_height, z + size),
						   Vector3(0, 0, 1))

	# West side (x-)
	if cx > 0:
		var neighbor_height: float = height_cache.get(Vector2i(cx - 1, cz), 0.0)
		if height > neighbor_height:
			_add_side_quad(st, Vector3(x, height, z + size), Vector3(x, height, z),
						   Vector3(x, neighbor_height, z), Vector3(x, neighbor_height, z + size),
						   Vector3(-1, 0, 0))

	# East side (x+)
	if cx < cells_per_side - 1:
		var nx: float = ((cx + 1) * size) - half_size + size / 2.0
		var nz: float = z + size / 2.0
		var neighbor_height: float = _get_blocky_height(nx, nz)
		if height > neighbor_height:
			_add_side_quad(st, Vector3(x + size, height, z), Vector3(x + size, height, z + size),
						   Vector3(x + size, neighbor_height, z + size), Vector3(x + size, neighbor_height, z),
						   Vector3(1, 0, 0))


func _add_side_quad(st: SurfaceTool, v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3, normal: Vector3) -> void:
	# v0 and v1 are at top (height), v2 and v3 are at bottom (neighbor_height)
	# Add a grass "sod" strip at the top, then dirt below - like Minecraft
	var grass_thickness: float = 0.25  # Thickness of grass layer on side
	var total_height: float = v0.y - v2.y

	# Add subtle color variation based on position
	var variation: float = sin(v0.x * 12.9898 + v0.z * 78.233 + v0.y * 37.719) * 0.06
	var cell_grass: Color = Color(
		clamp(grass_color.r + variation, 0.2, 0.4),
		clamp(grass_color.g + variation * 0.5, 0.4, 0.6),
		clamp(grass_color.b + variation * 0.3, 0.15, 0.3)
	)
	var cell_dirt: Color = Color(
		clamp(dirt_color.r + variation, 0.35, 0.65),
		clamp(dirt_color.g + variation * 0.8, 0.22, 0.48),
		clamp(dirt_color.b + variation * 0.5, 0.12, 0.32)
	)

	# If the side is tall enough, split into grass strip + dirt
	if total_height > grass_thickness:
		# Calculate grass strip bottom vertices
		var grass_bottom_y: float = v0.y - grass_thickness
		var g2 := Vector3(v1.x, grass_bottom_y, v1.z)  # Bottom-right of grass strip
		var g3 := Vector3(v0.x, grass_bottom_y, v0.z)  # Bottom-left of grass strip

		# Draw grass strip at top (green sod layer)
		st.set_color(cell_grass)
		st.set_normal(normal)
		st.add_vertex(v0)
		st.set_color(cell_grass)
		st.set_normal(normal)
		st.add_vertex(v1)
		st.set_color(cell_grass)
		st.set_normal(normal)
		st.add_vertex(g2)

		st.set_color(cell_grass)
		st.set_normal(normal)
		st.add_vertex(v0)
		st.set_color(cell_grass)
		st.set_normal(normal)
		st.add_vertex(g2)
		st.set_color(cell_grass)
		st.set_normal(normal)
		st.add_vertex(g3)

		# Draw dirt section below the grass strip
		st.set_color(cell_dirt)
		st.set_normal(normal)
		st.add_vertex(g3)
		st.set_color(cell_dirt)
		st.set_normal(normal)
		st.add_vertex(g2)
		st.set_color(cell_dirt)
		st.set_normal(normal)
		st.add_vertex(v2)

		st.set_color(cell_dirt)
		st.set_normal(normal)
		st.add_vertex(g3)
		st.set_color(cell_dirt)
		st.set_normal(normal)
		st.add_vertex(v2)
		st.set_color(cell_dirt)
		st.set_normal(normal)
		st.add_vertex(v3)
	else:
		# Side is shorter than grass thickness - just draw all grass
		st.set_color(cell_grass)
		st.set_normal(normal)
		st.add_vertex(v0)
		st.set_color(cell_grass)
		st.set_normal(normal)
		st.add_vertex(v1)
		st.set_color(cell_grass)
		st.set_normal(normal)
		st.add_vertex(v2)

		st.set_color(cell_grass)
		st.set_normal(normal)
		st.add_vertex(v0)
		st.set_color(cell_grass)
		st.set_normal(normal)
		st.add_vertex(v2)
		st.set_color(cell_grass)
		st.set_normal(normal)
		st.add_vertex(v3)


func _get_blocky_height(x: float, z: float) -> float:
	# Flatten area around spawn point (campsite) - smaller for more terrain variety
	var distance_from_center: float = Vector2(x, z).length()
	var flatten_radius: float = 6.0  # Reduced from 12 for more terrain near camp
	var flatten_falloff: float = 8.0

	if distance_from_center < flatten_radius:
		# Completely flat at y=0 in the campsite area
		return 0.0

	# Check if in pond area - create a natural depression
	var distance_from_pond: float = Vector2(x - pond_center.x, z - pond_center.y).length()
	if distance_from_pond < pond_radius:
		# Create bowl-shaped depression for the pond
		var pond_factor: float = distance_from_pond / pond_radius
		# Inner area is flat at the bottom, edges slope up
		if pond_factor < 0.6:
			return -pond_depth  # Flat bottom of pond
		else:
			# Smooth transition from pond bottom to surrounding terrain
			var edge_factor: float = (pond_factor - 0.6) / 0.4
			return -pond_depth + (pond_depth * edge_factor)

	# Base terrain height from noise
	var raw_height: float = noise.get_noise_2d(x, z)

	# Convert noise (-1 to 1) to positive height
	var height: float = (raw_height + 1.0) * 0.5 * height_scale

	# Quantize to blocky steps - this creates the Minecraft-style terraces
	height = floor(height / height_step) * height_step

	# Ensure minimum ground level
	height = max(height_step, height)

	# Gradual transition from campsite - use stepped transition
	if distance_from_center < flatten_radius + flatten_falloff:
		var t: float = (distance_from_center - flatten_radius) / flatten_falloff
		t = clamp(t, 0.0, 1.0)
		# Quantize the transition factor too for blocky edges
		t = floor(t * 4.0) / 4.0
		height *= t

	return height


func _create_terrain_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true  # Use vertex colors for grass/dirt
	material.albedo_color = Color.WHITE  # Neutral base color
	# Use per-vertex shading for flat blocky look (not per-pixel)
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT
	material.roughness = 1.0  # Fully rough for flat matte look
	material.metallic = 0.0
	# Disable backface culling
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _create_collision(_mesh: Mesh) -> void:
	terrain_collision = StaticBody3D.new()

	# Use HeightMapShape3D for terrain collision
	var collision_shape: CollisionShape3D = CollisionShape3D.new()
	var heightmap: HeightMapShape3D = HeightMapShape3D.new()

	# Create height data array - sample at 1 unit intervals for accurate collision
	var map_width: int = terrain_size + 1
	var map_depth: int = terrain_size + 1
	var height_data: PackedFloat32Array = PackedFloat32Array()
	height_data.resize(map_width * map_depth)

	var half_size: float = terrain_size / 2.0

	for z in range(map_depth):
		for x in range(map_width):
			var world_x: float = x - half_size
			var world_z: float = z - half_size
			var height: float = _get_blocky_height(world_x, world_z)
			height_data[z * map_width + x] = height

	heightmap.map_width = map_width
	heightmap.map_depth = map_depth
	heightmap.map_data = height_data

	collision_shape.shape = heightmap
	collision_shape.position = Vector3(0, 0, 0)
	terrain_collision.add_child(collision_shape)

	add_child(terrain_collision)


func get_height_at(x: float, z: float) -> float:
	return _get_blocky_height(x, z)


func _load_tree_scene() -> void:
	# Load all tree type scenes
	tree_scene = load("res://scenes/resources/tree_resource.tscn")
	if not tree_scene:
		push_warning("[TerrainGenerator] Failed to load small oak tree scene")

	big_tree_scene = load("res://scenes/resources/big_tree_resource.tscn")
	if not big_tree_scene:
		push_warning("[TerrainGenerator] Failed to load big oak tree scene")

	birch_tree_scene = load("res://scenes/resources/birch_tree_resource.tscn")
	if not birch_tree_scene:
		push_warning("[TerrainGenerator] Failed to load birch tree scene")

	# Setup forest density noise (different from terrain noise)
	forest_noise = FastNoiseLite.new()
	forest_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	forest_noise.seed = randi()  # Different seed for variety
	forest_noise.frequency = 0.08  # Creates medium-sized patches
	forest_noise.fractal_octaves = 2


func _spawn_forest() -> void:
	if not tree_scene or not forest_noise:
		return

	# Find or create Resources container
	var resources_container: Node3D = get_parent().get_node_or_null("Resources")
	if not resources_container:
		resources_container = Node3D.new()
		resources_container.name = "Resources"
		get_parent().add_child(resources_container)

	var tree_index: int = 0
	var tree_counts: Dictionary = {"small_oak": 0, "big_oak": 0, "birch": 0}

	# Iterate over a grid covering the forest area
	var grid_start: float = -tree_max_distance
	var grid_end: float = tree_max_distance

	var x: float = grid_start
	while x < grid_end:
		var z: float = grid_start
		while z < grid_end:
			# Check distance from campsite center
			var distance: float = Vector2(x, z).length()

			if distance >= tree_min_distance and distance <= tree_max_distance:
				# Get forest density at this location (0 to 1)
				var density_value: float = (forest_noise.get_noise_2d(x, z) + 1.0) * 0.5

				# Apply density curve - creates more contrast between thick and thin areas
				# Values below 0.3 = sparse, above 0.6 = dense
				var spawn_chance: float = 0.0
				if density_value > 0.35:
					# Scale density to spawn probability
					spawn_chance = tree_density * (density_value - 0.35) / 0.65 * 2.5

				# Reduce density at edges for natural fade
				var edge_factor: float = 1.0 - (distance - tree_min_distance) / (tree_max_distance - tree_min_distance)
				edge_factor = clamp(edge_factor * 1.5, 0.3, 1.0)
				spawn_chance *= edge_factor

				# Random check for this cell
				if randf() < spawn_chance:
					# Add jitter within the cell for natural placement
					var jitter_x: float = randf_range(-tree_grid_size * 0.4, tree_grid_size * 0.4)
					var jitter_z: float = randf_range(-tree_grid_size * 0.4, tree_grid_size * 0.4)
					var tree_x: float = x + jitter_x
					var tree_z: float = z + jitter_z

					# Skip if in pond area
					var dist_to_pond: float = Vector2(tree_x - pond_center.x, tree_z - pond_center.y).length()
					if dist_to_pond < pond_radius + 2.0:  # Add margin around pond
						z += tree_grid_size
						continue

					# Get terrain height
					var tree_y: float = _get_blocky_height(tree_x, tree_z)

					# Choose tree type: 60% small oak, 30% big oak, 10% birch
					var tree: Node3D
					var tree_type_roll: float = randf()
					var tree_type: String

					if tree_type_roll < 0.60:
						tree = tree_scene.instantiate()
						tree_type = "small_oak"
					elif tree_type_roll < 0.90 and big_tree_scene:
						tree = big_tree_scene.instantiate()
						tree_type = "big_oak"
					elif birch_tree_scene:
						tree = birch_tree_scene.instantiate()
						tree_type = "birch"
					else:
						tree = tree_scene.instantiate()
						tree_type = "small_oak"

					tree.name = "Tree_Gen_%d" % tree_index
					tree.position = Vector3(tree_x, tree_y, tree_z)

					# Random Y rotation
					tree.rotation.y = randf() * TAU

					# Scale variation based on tree type
					var scale_factor: float
					if tree_type == "big_oak":
						scale_factor = randf_range(0.9, 1.1)  # Big oaks have less variation
					elif tree_type == "birch":
						scale_factor = randf_range(0.8, 1.1)  # Birches are more uniform
					else:
						scale_factor = randf_range(0.7, 1.2)  # Small oaks have more variety
					tree.scale = Vector3(scale_factor, scale_factor, scale_factor)

					resources_container.add_child(tree)
					spawned_trees.append(tree)
					tree_counts[tree_type] += 1
					tree_index += 1

			z += tree_grid_size
		x += tree_grid_size

	print("[TerrainGenerator] Spawned %d trees (small oak: %d, big oak: %d, birch: %d)" % [
		spawned_trees.size(),
		tree_counts["small_oak"],
		tree_counts["big_oak"],
		tree_counts["birch"]
	])


func _spawn_ground_decorations() -> void:
	# Spawn grass tufts and flowers on the terrain surface
	var decorations_container: Node3D = Node3D.new()
	decorations_container.name = "GroundDecorations"
	add_child(decorations_container)

	var grass_count: int = 0
	var red_flower_count: int = 0
	var yellow_flower_count: int = 0

	# Target counts
	var target_grass: int = 250
	var target_red_flowers: int = 35
	var target_yellow_flowers: int = 35

	# Spawn decorations in a radius around the campsite
	var decoration_radius: float = 55.0
	var min_distance: float = 8.0  # Avoid campsite center

	# Use noise for natural clustering
	var decoration_noise: FastNoiseLite = FastNoiseLite.new()
	decoration_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	decoration_noise.seed = randi()
	decoration_noise.frequency = 0.15

	# Spawn grass tufts
	while grass_count < target_grass:
		var x: float = randf_range(-decoration_radius, decoration_radius)
		var z: float = randf_range(-decoration_radius, decoration_radius)
		var distance: float = Vector2(x, z).length()

		# Skip if in pond area
		var dist_to_pond: float = Vector2(x - pond_center.x, z - pond_center.y).length()
		if dist_to_pond < pond_radius + 1.0:
			continue

		if distance >= min_distance and distance <= decoration_radius:
			# Use noise to create natural clustering
			var noise_value: float = (decoration_noise.get_noise_2d(x, z) + 1.0) * 0.5
			if noise_value > 0.3:  # Only spawn in certain noise regions
				var y: float = _get_blocky_height(x, z)
				_create_grass_tuft(decorations_container, Vector3(x, y + 0.01, z))
				grass_count += 1

	# Spawn red flowers (poppies/tulips)
	while red_flower_count < target_red_flowers:
		var x: float = randf_range(-decoration_radius, decoration_radius)
		var z: float = randf_range(-decoration_radius, decoration_radius)
		var distance: float = Vector2(x, z).length()

		# Skip if in pond area
		var dist_to_pond: float = Vector2(x - pond_center.x, z - pond_center.y).length()
		if dist_to_pond < pond_radius + 1.0:
			continue

		if distance >= min_distance and distance <= decoration_radius:
			var noise_value: float = (decoration_noise.get_noise_2d(x * 1.5, z * 1.5) + 1.0) * 0.5
			if noise_value > 0.5:  # Flowers are more sparse
				var y: float = _get_blocky_height(x, z)
				_create_flower(decorations_container, Vector3(x, y + 0.01, z), Color(0.85, 0.15, 0.15))  # Red
				red_flower_count += 1

	# Spawn yellow flowers (dandelions)
	while yellow_flower_count < target_yellow_flowers:
		var x: float = randf_range(-decoration_radius, decoration_radius)
		var z: float = randf_range(-decoration_radius, decoration_radius)
		var distance: float = Vector2(x, z).length()

		# Skip if in pond area
		var dist_to_pond: float = Vector2(x - pond_center.x, z - pond_center.y).length()
		if dist_to_pond < pond_radius + 1.0:
			continue

		if distance >= min_distance and distance <= decoration_radius:
			var noise_value: float = (decoration_noise.get_noise_2d(x * 1.3 + 100.0, z * 1.3 + 100.0) + 1.0) * 0.5
			if noise_value > 0.5:
				var y: float = _get_blocky_height(x, z)
				_create_flower(decorations_container, Vector3(x, y + 0.01, z), Color(0.95, 0.85, 0.15))  # Yellow
				yellow_flower_count += 1

	print("[TerrainGenerator] Spawned ground decorations: %d grass, %d red flowers, %d yellow flowers" % [
		grass_count, red_flower_count, yellow_flower_count
	])


func _create_grass_tuft(parent: Node3D, pos: Vector3) -> void:
	# Create a simple grass tuft using crossed quads (X-shape)
	var grass: MeshInstance3D = MeshInstance3D.new()

	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Grass properties
	var height: float = randf_range(0.25, 0.4)
	var width: float = 0.15
	var grass_green: Color = Color(0.3, 0.65, 0.25)  # Slightly darker than terrain grass

	# Create two crossed quads for the grass tuft
	# First quad (along X axis)
	_add_grass_quad(st, Vector3(-width, 0, 0), Vector3(width, 0, 0),
					Vector3(width, height, 0), Vector3(-width, height, 0), grass_green)

	# Second quad (along Z axis)
	_add_grass_quad(st, Vector3(0, 0, -width), Vector3(0, 0, width),
					Vector3(0, height, width), Vector3(0, height, -width), grass_green)

	var mesh: ArrayMesh = st.commit()
	grass.mesh = mesh

	# Create material
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # Simple flat look
	grass.material_override = mat

	grass.position = pos
	grass.rotation.y = randf() * TAU  # Random rotation
	parent.add_child(grass)


func _add_grass_quad(st: SurfaceTool, v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3, color: Color) -> void:
	# Add a quad with vertex colors
	st.set_color(color)
	st.set_normal(Vector3.UP)

	# Triangle 1
	st.add_vertex(v0)
	st.add_vertex(v1)
	st.add_vertex(v2)

	# Triangle 2
	st.add_vertex(v0)
	st.add_vertex(v2)
	st.add_vertex(v3)


func _create_flower(parent: Node3D, pos: Vector3, petal_color: Color) -> void:
	# Create a simple blocky flower
	var flower: Node3D = Node3D.new()

	# Stem (thin green box)
	var stem: MeshInstance3D = MeshInstance3D.new()
	var stem_mesh: BoxMesh = BoxMesh.new()
	stem_mesh.size = Vector3(0.05, 0.3, 0.05)
	stem.mesh = stem_mesh

	var stem_mat: StandardMaterial3D = StandardMaterial3D.new()
	stem_mat.albedo_color = Color(0.2, 0.5, 0.15)  # Dark green stem
	stem.material_override = stem_mat
	stem.position.y = 0.15
	flower.add_child(stem)

	# Flower head (small colored box)
	var head: MeshInstance3D = MeshInstance3D.new()
	var head_mesh: BoxMesh = BoxMesh.new()
	head_mesh.size = Vector3(0.15, 0.12, 0.15)
	head.mesh = head_mesh

	var head_mat: StandardMaterial3D = StandardMaterial3D.new()
	head_mat.albedo_color = petal_color
	head.material_override = head_mat
	head.position.y = 0.35
	flower.add_child(head)

	flower.position = pos
	flower.rotation.y = randf() * TAU
	parent.add_child(flower)


func _load_fishing_spot_scene() -> void:
	fishing_spot_scene = load("res://scenes/resources/fishing_spot.tscn")
	if not fishing_spot_scene:
		push_warning("[TerrainGenerator] Failed to load fishing spot scene")


func _spawn_pond() -> void:
	if not fishing_spot_scene:
		return

	# Find or create Resources container
	var resources_container: Node3D = get_parent().get_node_or_null("Resources")
	if not resources_container:
		resources_container = Node3D.new()
		resources_container.name = "Resources"
		get_parent().add_child(resources_container)

	# Create fishing spot at pond center
	var fishing_spot: Node3D = fishing_spot_scene.instantiate()
	fishing_spot.name = "Pond"

	# Position at pond center, at the bottom of the depression
	var pond_y: float = -pond_depth + 0.1  # Slightly above the bottom
	fishing_spot.position = Vector3(pond_center.x, pond_y, pond_center.y)

	# Configure larger pond size
	if fishing_spot.has_method("set") or "pond_width" in fishing_spot:
		fishing_spot.pond_width = 10.0  # Larger pond
		fishing_spot.pond_depth = 8.0   # Depth dimension (z)
		fishing_spot.fish_count = 5     # More fish in bigger pond

	resources_container.add_child(fishing_spot)
	print("[TerrainGenerator] Spawned fishing pond at (%.1f, %.1f)" % [pond_center.x, pond_center.y])
