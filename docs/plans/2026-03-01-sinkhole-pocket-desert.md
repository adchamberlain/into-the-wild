# Sinkhole Pocket Desert Relocation - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Move the sinkhole easter egg from the main desert ring to a hidden pocket desert biome 350 units due west, with organic noise boundaries, gradual color blending, and a rock spire landmark.

**Architecture:** Add a pocket desert definition (center + radius + noise boundary) to `chunk_manager.gd`. Insert a distance check in `get_region_at()` before the desert ring check. Add a blend helper function in `chunk_manager.gd` and call it from `terrain_chunk.gd`'s two color-blending locations. Spawn a rock spire when the pocket's chunk loads. Move sinkhole generation to the pocket center.

**Tech Stack:** GDScript (Godot 4.5), procedural BoxMesh geometry

**Testing:** SUSPENDED per CLAUDE.md — no new tests.

---

### Task 1: Add pocket desert data and move sinkhole position

**Files:**
- Modify: `scripts/world/chunk_manager.gd:68-72` (sinkhole vars section)
- Modify: `scripts/world/chunk_manager.gd:952-983` (`_generate_desert_sinkhole()`)

**Step 1: Add pocket desert variables**

After line 72 (`var sinkhole_book_script`), add:

```gdscript
# Pocket desert biome (hidden area containing sinkhole, west of spawn)
var pocket_desert_center: Vector2 = Vector2(-350.0, 0.0)
var pocket_desert_radius: float = 50.0
var pocket_desert_blend: float = 15.0  # Transition zone width
var rock_spire_spawned: bool = false
```

**Step 2: Update `_generate_desert_sinkhole()` to use pocket center**

Replace the entire `_generate_desert_sinkhole()` function (lines 952-983) with:

```gdscript
func _generate_desert_sinkhole() -> void:
	## Place the hidden sinkhole at the center of the pocket desert
	var raw_x: float = pocket_desert_center.x
	var raw_z: float = pocket_desert_center.y

	# Snap to cell_size grid (multiples of 3.0)
	var snapped_x: float = roundf(raw_x / cell_size) * cell_size
	var snapped_z: float = roundf(raw_z / cell_size) * cell_size

	desert_sinkhole = {
		"center": Vector2(snapped_x, snapped_z),
		"radius": 5.0,
		"depth": 45.0
	}

	# Register as a water body (type POND) for terrain carving
	var sink_wb_idx: int = water_bodies.size()
	water_bodies.append({
		"type": WaterBodyType.POND,
		"center": Vector2(snapped_x, snapped_z),
		"radius": 5.0,
		"depth": 45.0
	})
	# Prevent fishing spots from spawning on the sinkhole
	spawned_pond_indices.append(sink_wb_idx)

	# Update legacy pond_locations
	_update_legacy_pond_locations()

	print("[ChunkManager] Generated desert sinkhole at (%.0f, %.0f) in pocket desert" % [snapped_x, snapped_z])
```

**Step 3: Commit**

```bash
git add scripts/world/chunk_manager.gd
git commit -m "Move sinkhole position to pocket desert center (-350, 0)"
```

---

### Task 2: Add pocket desert biome check to `get_region_at()`

**Files:**
- Modify: `scripts/world/chunk_manager.gd:1332-1362` (`get_region_at()`)

**Step 1: Add pocket desert check after spawn-forest, before desert ring**

Insert after line 1337 (`return RegionType.FOREST`) and before line 1339 (desert ring comment):

```gdscript
	# Pocket desert biome (hidden area west of spawn containing sinkhole)
	var pocket_dist: float = Vector2(x - pocket_desert_center.x, z - pocket_desert_center.y).length()
	var pocket_angle: float = atan2(z - pocket_desert_center.y, x - pocket_desert_center.x)
	var pocket_boundary: float = pocket_desert_radius + _desert_boundary_offset(pocket_angle)
	if pocket_dist <= pocket_boundary:
		return RegionType.DESERT
```

This reuses the existing `_desert_boundary_offset()` function which gives ±~19 units of organic wobble, making the pocket boundary range from ~31 to ~69 units.

**Step 2: Commit**

```bash
git add scripts/world/chunk_manager.gd
git commit -m "Add pocket desert biome detection in get_region_at()"
```

---

### Task 3: Add pocket desert blend helper

**Files:**
- Modify: `scripts/world/chunk_manager.gd:1373-1377` (after `get_desert_boundaries()`)

**Step 1: Add blend factor helper**

After the `get_desert_boundaries()` function (line 1377), add:

```gdscript

## Returns a blend factor (0.0 to 1.0) for the pocket desert transition zone.
## 0.0 = fully outside (no desert blend), 1.0 = fully inside pocket desert.
## Used by terrain_chunk.gd for smooth color transitions.
func get_pocket_desert_blend(x: float, z: float) -> float:
	var pocket_dist: float = Vector2(x - pocket_desert_center.x, z - pocket_desert_center.y).length()
	var pocket_angle: float = atan2(z - pocket_desert_center.y, x - pocket_desert_center.x)
	var pocket_boundary: float = pocket_desert_radius + _desert_boundary_offset(pocket_angle)
	if pocket_dist <= pocket_boundary:
		return 1.0  # Fully inside pocket desert
	elif pocket_dist <= pocket_boundary + pocket_desert_blend:
		return 1.0 - (pocket_dist - pocket_boundary) / pocket_desert_blend
	return 0.0  # Outside blend zone
```

**Step 2: Commit**

```bash
git add scripts/world/chunk_manager.gd
git commit -m "Add pocket desert blend factor helper for terrain transitions"
```

---

### Task 4: Add pocket desert color blending to terrain_chunk.gd

**Files:**
- Modify: `scripts/world/terrain_chunk.gd:472-486` (top face desert blending)
- Modify: `scripts/world/terrain_chunk.gd:659-675` (side face desert blending)

There are two nearly identical desert-transition blocks in terrain_chunk.gd. Both need a pocket desert blend check added.

**Step 1: Update top face blending (after line 486)**

After the existing desert ring transition block (line 486, closing of the `elif` for outer transition), add:

```gdscript
	# Pocket desert transition zone blending
	var pocket_blend: float = chunk_manager.get_pocket_desert_blend(center_x, center_z)
	if pocket_blend > 0.0 and region != ChunkManager.RegionType.DESERT:
		var desert_colors: Dictionary = chunk_manager.region_colors[ChunkManager.RegionType.DESERT]
		grass_color = grass_color.lerp(desert_colors["grass"], pocket_blend)
```

**Step 2: Update the `is_desert` check on line 492**

Change line 492 from:
```gdscript
	var is_desert: bool = region == ChunkManager.RegionType.DESERT or (spawn_dist >= d_inner and spawn_dist <= d_outer)
```
To:
```gdscript
	var is_desert: bool = region == ChunkManager.RegionType.DESERT or (spawn_dist >= d_inner and spawn_dist <= d_outer) or pocket_blend > 0.5
```

**Step 3: Update side face blending (after line 675)**

After the existing desert ring transition block (line 675), add:

```gdscript
	# Pocket desert transition zone blending
	var pocket_blend: float = chunk_manager.get_pocket_desert_blend(center_x, center_z)
	if pocket_blend > 0.0 and region != ChunkManager.RegionType.DESERT:
		var desert_colors: Dictionary = chunk_manager.region_colors[ChunkManager.RegionType.DESERT]
		grass_color = grass_color.lerp(desert_colors["grass"], pocket_blend)
		dirt_color = dirt_color.lerp(desert_colors["dirt"], pocket_blend)
```

**Step 4: Update the `is_desert` check on line 681**

Change line 681 from:
```gdscript
	var is_desert: bool = region == ChunkManager.RegionType.DESERT or (spawn_dist >= d_inner and spawn_dist <= d_outer)
```
To:
```gdscript
	var is_desert: bool = region == ChunkManager.RegionType.DESERT or (spawn_dist >= d_inner and spawn_dist <= d_outer) or pocket_blend > 0.5
```

**Step 5: Commit**

```bash
git add scripts/world/terrain_chunk.gd
git commit -m "Add pocket desert color blending to terrain chunk rendering"
```

---

### Task 5: Add rock spire landmark at pocket desert edge

**Files:**
- Modify: `scripts/world/chunk_manager.gd` (add `_spawn_rock_spire()` function and call it from `_process_chunk_queues()`)

**Step 1: Add rock spire spawn function**

Add after `_spawn_sinkhole_contents()` (after line 1091):

```gdscript

func _spawn_rock_spire() -> void:
	## Spawn a tall rock spire at the eastern edge of the pocket desert as a landmark
	if rock_spire_spawned:
		return

	# Place at eastern edge of pocket desert (facing main play area)
	var spire_x: float = pocket_desert_center.x + pocket_desert_radius - 5.0
	var spire_z: float = pocket_desert_center.y
	# Snap to grid
	spire_x = roundf(spire_x / cell_size) * cell_size
	spire_z = roundf(spire_z / cell_size) * cell_size
	var spire_y: float = get_height_at(spire_x, spire_z)

	var spire_root: Node3D = Node3D.new()
	spire_root.name = "RockSpire"
	spire_root.position = Vector3(spire_x, spire_y, spire_z)

	# Base block - wide and heavy
	var base: MeshInstance3D = MeshInstance3D.new()
	var base_mesh: BoxMesh = BoxMesh.new()
	base_mesh.size = Vector3(3.0, 3.0, 3.0)
	base.mesh = base_mesh
	var base_mat: StandardMaterial3D = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.55, 0.45, 0.32)  # Warm sandstone
	base_mat.roughness = 0.9
	base.material_override = base_mat
	base.position = Vector3(0.0, 1.5, 0.0)
	spire_root.add_child(base)

	# Middle section - narrower, slightly offset
	var mid: MeshInstance3D = MeshInstance3D.new()
	var mid_mesh: BoxMesh = BoxMesh.new()
	mid_mesh.size = Vector3(2.2, 3.5, 2.2)
	mid.mesh = mid_mesh
	var mid_mat: StandardMaterial3D = StandardMaterial3D.new()
	mid_mat.albedo_color = Color(0.50, 0.40, 0.28)  # Slightly darker
	mid_mat.roughness = 0.9
	mid.material_override = mid_mat
	mid.position = Vector3(0.3, 4.75, -0.2)
	spire_root.add_child(mid)

	# Upper section - narrower still
	var upper: MeshInstance3D = MeshInstance3D.new()
	var upper_mesh: BoxMesh = BoxMesh.new()
	upper_mesh.size = Vector3(1.5, 2.5, 1.5)
	upper.mesh = upper_mesh
	var upper_mat: StandardMaterial3D = StandardMaterial3D.new()
	upper_mat.albedo_color = Color(0.60, 0.48, 0.33)  # Lighter weathered top
	upper_mat.roughness = 0.85
	upper.material_override = upper_mat
	upper.position = Vector3(-0.2, 7.75, 0.15)
	spire_root.add_child(upper)

	# Cap - small angled top piece
	var cap: MeshInstance3D = MeshInstance3D.new()
	var cap_mesh: BoxMesh = BoxMesh.new()
	cap_mesh.size = Vector3(1.0, 1.2, 1.0)
	cap.mesh = cap_mesh
	var cap_mat: StandardMaterial3D = StandardMaterial3D.new()
	cap_mat.albedo_color = Color(0.65, 0.52, 0.36)  # Lightest - sun-bleached
	cap_mat.roughness = 0.8
	cap.material_override = cap_mat
	cap.position = Vector3(0.1, 9.6, -0.1)
	cap.rotation_degrees = Vector3(5.0, 15.0, -8.0)  # Slight tilt for character
	spire_root.add_child(cap)

	add_child(spire_root)
	rock_spire_spawned = true
	print("[ChunkManager] Spawned rock spire landmark at (%.0f, %.0f)" % [spire_x, spire_z])
```

**Step 2: Call rock spire spawn from `_process_chunk_queues()`**

In `_process_chunk_queues()`, after the sinkhole spawn block (line 1835), add:

```gdscript
	# Spawn rock spire landmark when its chunk loads
	if not rock_spire_spawned:
		var spire_x: float = roundf((pocket_desert_center.x + pocket_desert_radius - 5.0) / cell_size) * cell_size
		var spire_z: float = roundf(pocket_desert_center.y / cell_size) * cell_size
		if spire_x >= chunk_min_x and spire_x < chunk_max_x and \
		   spire_z >= chunk_min_z and spire_z < chunk_max_z:
			_spawn_rock_spire()
```

**Step 3: Commit**

```bash
git add scripts/world/chunk_manager.gd
git commit -m "Add rock spire landmark at eastern edge of pocket desert"
```

---

### Task 6: Update vegetation suppression for pocket desert area

**Files:**
- Modify: `scripts/world/chunk_manager.gd:986-991` (`is_near_sinkhole()`)

The existing `is_near_sinkhole()` function already works based on sinkhole position (which now moves to the pocket). No changes needed for vegetation suppression around the sinkhole itself.

However, verify that the vegetation suppression also accounts for the rock spire so trees/bushes don't clip through it.

**Step 1: Add rock spire proximity check to `is_near_sinkhole()`**

Rename and expand to cover the rock spire:

```gdscript
func is_near_sinkhole(world_x: float, world_z: float, buffer: float = 12.0) -> bool:
	## Check if a world position is near the desert sinkhole or rock spire (for vegetation suppression)
	if desert_sinkhole.size() == 0:
		return false
	var dist: float = Vector2(world_x - desert_sinkhole["center"].x, world_z - desert_sinkhole["center"].y).length()
	if dist < desert_sinkhole["radius"] + buffer:
		return true
	# Also suppress vegetation near rock spire
	var spire_x: float = roundf((pocket_desert_center.x + pocket_desert_radius - 5.0) / cell_size) * cell_size
	var spire_z: float = roundf(pocket_desert_center.y / cell_size) * cell_size
	var spire_dist: float = Vector2(world_x - spire_x, world_z - spire_z).length()
	return spire_dist < 6.0
```

**Step 2: Commit**

```bash
git add scripts/world/chunk_manager.gd
git commit -m "Extend vegetation suppression to cover rock spire area"
```

---

### Task 7: Add save/load for rock_spire_spawned state

**Files:**
- Modify: `scripts/core/save_load.gd` (save and load `rock_spire_spawned`)

**Step 1: Check current save/load for sinkhole state**

The `rock_spire_spawned` flag is runtime-only (recomputed when chunks load), similar to `sinkhole_spawned`. It does NOT need to be saved — it's set to true when the chunk containing the spire loads, same pattern as `sinkhole_spawned`.

**No save/load changes needed.** Both `sinkhole_spawned` and `rock_spire_spawned` are chunk-load triggers, not persistent state.

**Step 1: Verify — no action needed, move on.**

---

### Task 8: Test in-game and commit final

**Step 1: Launch the game**

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . 2>&1 | head -50
```

**Step 2: Verify these behaviors:**

1. Walk west (~350 units) — terrain should gradually transition to desert sand
2. The pocket desert should be roughly circular (~100 units across) with organic edges
3. Rock spire should be visible as a tall sandstone formation at the eastern edge
4. Cacti and palms spawn in the pocket desert, no regular trees
5. Sinkhole is at the center of the pocket with water, glow, and journal
6. The old desert ring at 170-230 units no longer has a sinkhole
7. Coca leaf plant is near the sinkhole

**Step 3: Final commit and push**

```bash
git push origin main
```

---

### Task 9: Update DEV_LOG.md

**Files:**
- Modify: `DEV_LOG.md`

**Step 1: Add session entry documenting the sinkhole relocation**

Add a new session entry describing:
- Moved sinkhole from main desert ring to hidden pocket desert at (-350, 0)
- New pocket desert biome with organic noise boundaries (~50-unit radius)
- Gradual 15-unit color blend transition to surrounding biomes
- Rock spire landmark at eastern edge as subtle hint
- All sinkhole mechanics unchanged (coca leaf, journal, rewards)
- List all modified files
