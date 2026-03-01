# Desert Sinkhole Easter Egg — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a hidden sinkhole in the desert biome containing an ancient explorer's journal. A nearby coca leaf plant enables the deep dive. The journal grants permanent stat boosts, map markers, and unlocks a hang glider recipe for powered flight.

**Architecture:** The sinkhole is generated alongside desert oases in `chunk_manager.gd` as a water body with 30-unit depth. The coca leaf is a new resource node scene. The journal is a new interactable pickup that triggers rewards via player_controller. The hang glider is a new equipment item with a dedicated flight state in the player controller.

**Tech Stack:** GDScript, Godot 4.5, BoxMesh procedural art, existing resource_node/equipment/crafting patterns.

---

### Task 1: Generate the Sinkhole in chunk_manager.gd

**Files:**
- Modify: `scripts/world/chunk_manager.gd`

**Step 1: Add sinkhole data variable**

Near line 30 (after `desert_oases` array), add:

```gdscript
var desert_sinkhole: Dictionary = {}  # {center: Vector2, radius: float, depth: float}
var sinkhole_spawned: bool = false
```

**Step 2: Add `_generate_desert_sinkhole()` function**

After `_generate_desert_oases()` (~line 884), add a new function that places the sinkhole at 180° in the desert ring (opposite oasis #1 at 0°), ~200 units from spawn. Register it as a water body for terrain carving.

```gdscript
func _generate_desert_sinkhole() -> void:
	var angle_rad: float = deg_to_rad(180.0)
	var distance: float = 200.0
	var raw_x: float = cos(angle_rad) * distance
	var raw_z: float = sin(angle_rad) * distance
	var snapped_x: float = roundf(raw_x / cell_size) * cell_size
	var snapped_z: float = roundf(raw_z / cell_size) * cell_size

	desert_sinkhole = {
		"center": Vector2(snapped_x, snapped_z),
		"radius": 5.0,
		"depth": 30.0
	}

	# Register as water body for terrain carving
	var wb_idx: int = water_bodies.size()
	water_bodies.append({
		"type": WaterBodyType.POND,
		"center": Vector2(snapped_x, snapped_z),
		"radius": 5.0,
		"depth": 30.0
	})
	spawned_pond_indices.append(wb_idx)

	print("[ChunkManager] Generated desert sinkhole at (%.0f, %.0f)" % [snapped_x, snapped_z])
```

**Step 3: Call from `_ready()`**

In `_ready()`, after the `_generate_desert_oases()` call (~line 223), add:

```gdscript
_generate_desert_sinkhole()
```

**Step 4: Add sinkhole terrain carving in `get_height_at()`**

In `get_height_at()`, near the desert oasis terrain carving section (~line 1248), add a check for the sinkhole. Use a 3-unit ramp at the rim just like oases:

```gdscript
# Check sinkhole
if desert_sinkhole.size() > 0:
	var sink_dist: float = Vector2(snapped_x - desert_sinkhole["center"].x, snapped_z - desert_sinkhole["center"].y).length()
	if sink_dist < desert_sinkhole["radius"]:
		return -desert_sinkhole["depth"]
	elif sink_dist < desert_sinkhole["radius"] + 3.0:
		var blend_factor: float = (sink_dist - desert_sinkhole["radius"]) / 3.0
		return lerpf(-desert_sinkhole["depth"], height_step, blend_factor)
```

**Step 5: Add `_spawn_sinkhole_contents()` function**

Similar to `_spawn_oasis()`, add a function that spawns the book pedestal, glow light, and coca leaf plant when the sinkhole's chunk loads. Called from `_process_chunk_queues()` or similar chunk-spawn logic where oases are spawned.

```gdscript
func _spawn_sinkhole_contents() -> void:
	if sinkhole_spawned or desert_sinkhole.size() == 0:
		return

	var center: Vector2 = desert_sinkhole["center"]
	var depth: float = desert_sinkhole["depth"]

	# Spawn the book node at the bottom of the sinkhole
	var book_node: StaticBody3D = StaticBody3D.new()
	book_node.set_script(sinkhole_book_script)
	book_node.name = "ExplorersJournal"
	book_node.position = Vector3(center.x, -depth + 0.5, center.y)
	add_child(book_node)

	# Spawn the coca leaf plant ~7 units from the rim
	var leaf_offset: Vector2 = Vector2(7.0, 0.0)  # East of sinkhole
	var leaf_x: float = center.x + leaf_offset.x
	var leaf_z: float = center.y + leaf_offset.y
	var leaf_y: float = get_height_at(leaf_x, leaf_z)
	var coca_node: StaticBody3D = load("res://scenes/resources/coca_leaf.tscn").instantiate()
	coca_node.position = Vector3(leaf_x, leaf_y, leaf_z)
	add_child(coca_node)

	# Bottom glow light (hint to the player)
	var glow: OmniLight3D = OmniLight3D.new()
	glow.name = "SinkholeGlow"
	glow.light_color = Color(0.3, 0.7, 0.6)  # Blue-green
	glow.light_energy = 1.5
	glow.omni_range = 8.0
	glow.shadow_enabled = false
	glow.position = Vector3(center.x, -depth + 2.0, center.y)
	add_child(glow)

	sinkhole_spawned = true
	print("[ChunkManager] Spawned sinkhole contents at (%.0f, %.0f)" % [center.x, center.y])
```

**Step 6: Trigger sinkhole spawn from chunk loading**

In the chunk loading section where oases are spawned (search for `_spawn_oasis`), add a call to check if the sinkhole should spawn based on chunk proximity:

```gdscript
# After oasis spawn checks, add:
if not sinkhole_spawned and desert_sinkhole.size() > 0:
	var sink_center: Vector2 = desert_sinkhole["center"]
	if sink_center.x >= min_x and sink_center.x < max_x and sink_center.y >= min_z and sink_center.y < max_z:
		_spawn_sinkhole_contents()
```

**Step 7: Add `sinkhole_book_script` preload**

Near the top of chunk_manager.gd where other scripts are loaded, add:

```gdscript
var sinkhole_book_script: GDScript = load("res://scripts/world/explorers_journal_pickup.gd")
```

**Step 8: Suppress vegetation near sinkhole**

In the vegetation/tree/resource spawning sections of `terrain_chunk.gd`, add a check to prevent cacti and palms from spawning within 12 units of the sinkhole center (similar to the oasis exclusion zone). Use a new `chunk_manager.is_near_sinkhole(x, z)` helper.

**Step 9: Commit**

```
git add scripts/world/chunk_manager.gd scripts/world/terrain_chunk.gd
git commit -m "Generate desert sinkhole: 30-unit deep water pit at 180° in desert ring"
```

---

### Task 2: Create the Coca Leaf Resource Node

**Files:**
- Create: `scenes/resources/coca_leaf.tscn`
- Modify: `scripts/player/player_controller.gd`
- Modify: `scripts/core/save_load.gd`

**Step 1: Create `coca_leaf.tscn`**

Model after `scenes/resources/osha_root.tscn`. A bushy green plant with broad oval leaves in 2-3 shades of green, ~0.5 units tall. Uses `resource_node.gd` script with:

```
resource_type = "coca_leaf"
resource_amount = 1
interaction_text = "Pick Coca Leaf"
adjust_to_terrain = false
```

Visual meshes: 3-4 broad leaf clusters (BoxMesh, wider and flatter than osha), stems, in bright green `Color(0.3, 0.6, 0.2)` and darker green `Color(0.2, 0.45, 0.15)`. Larger overall than osha_root to stand out against sand.

**Step 2: Add coca leaf to FOOD_VALUES in player_controller.gd**

In the `FOOD_VALUES` dictionary (~line 114), add:

```gdscript
"coca_leaf": 5.0,
```

**Step 3: Add coca leaf breath buff in `_try_eat()`**

Find the `_try_eat()` function. After consuming the coca leaf (hunger restored), apply the breath buff:

```gdscript
if item_type == "coca_leaf":
	coca_leaf_timer = 300.0  # 5 minutes
	_base_breath_interval = BREATH_BUBBLE_INTERVAL
	BREATH_BUBBLE_INTERVAL = _base_breath_interval * 2.0  # 4s -> 8s
	get_tree().call_group("hud", "show_notification", "Your breathing slows... lungs feel stronger", Color(0.6, 1, 0.6, 1))
```

**Step 4: Add coca leaf state variables**

Near the breath variables (~line 107), add:

```gdscript
var coca_leaf_timer: float = 0.0
var _base_breath_interval: float = 4.0
```

Note: `BREATH_BUBBLE_INTERVAL` at line 110 must change from `const` to `var` to allow runtime modification.

**Step 5: Add coca leaf timer tick in `_physics_process()`**

After `_update_breath(delta)` (~line 381), add:

```gdscript
if coca_leaf_timer > 0.0:
	coca_leaf_timer -= delta
	if coca_leaf_timer <= 0.0:
		coca_leaf_timer = 0.0
		BREATH_BUBBLE_INTERVAL = _base_breath_interval
		get_tree().call_group("hud", "show_notification", "The coca leaf effect fades", Color(1, 0.85, 0.3, 1))
```

**Step 6: Save/load coca leaf timer**

In `save_load.gd`, add `coca_leaf_timer` to player data save/load so the buff persists across saves.

**Step 7: Add coca leaf depletion tracking to save data**

The sinkhole's coca leaf needs respawn tracking (72h game time). Add to sinkhole save data:

```gdscript
"coca_leaf_depleted_time": -1.0  # Game hours when depleted, -1 = available
```

**Step 8: Commit**

```
git add scenes/resources/coca_leaf.tscn scripts/player/player_controller.gd scripts/core/save_load.gd
git commit -m "Add coca leaf plant: doubles underwater breath duration for 5 minutes"
```

---

### Task 3: Create the Explorer's Journal Pickup

**Files:**
- Create: `scripts/world/explorers_journal_pickup.gd`

**Step 1: Create the pickup script**

A `StaticBody3D` script with:
- Procedural BoxMesh visuals: leather-brown book on a stone pedestal, warm amber emissive glow
- Collision shape for interaction raycast
- Added to `interactable` group
- `interact()` method: adds `explorers_journal` to player inventory, removes self from scene
- `get_interaction_text()` returns "Take Explorer's Journal"

```gdscript
extends StaticBody3D

var is_collected: bool = false

func _ready() -> void:
	add_to_group("interactable")
	_build_visual()

func _build_visual() -> void:
	# Stone pedestal
	var pedestal: MeshInstance3D = MeshInstance3D.new()
	var ped_mesh: BoxMesh = BoxMesh.new()
	ped_mesh.size = Vector3(0.6, 0.4, 0.6)
	pedestal.mesh = ped_mesh
	var ped_mat: StandardMaterial3D = StandardMaterial3D.new()
	ped_mat.albedo_color = Color(0.5, 0.48, 0.45)
	pedestal.material_override = ped_mat
	pedestal.position = Vector3(0, 0.2, 0)
	add_child(pedestal)

	# Book on pedestal
	var book: MeshInstance3D = MeshInstance3D.new()
	var book_mesh: BoxMesh = BoxMesh.new()
	book_mesh.size = Vector3(0.3, 0.06, 0.4)
	book.mesh = book_mesh
	var book_mat: StandardMaterial3D = StandardMaterial3D.new()
	book_mat.albedo_color = Color(0.45, 0.3, 0.15)
	book_mat.emission_enabled = true
	book_mat.emission = Color(0.8, 0.6, 0.2)
	book_mat.emission_energy_multiplier = 1.5
	book.material_override = book_mat
	book.position = Vector3(0, 0.43, 0)
	add_child(book)

	# Collision
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(0.6, 0.6, 0.6)
	collision.shape = shape
	collision.position = Vector3(0, 0.3, 0)
	add_child(collision)

func get_interaction_text() -> String:
	if is_collected:
		return ""
	return "Take Explorer's Journal"

func interact(player: Node) -> void:
	if is_collected:
		return
	is_collected = true
	var inventory: Node = player.get_node_or_null("Inventory")
	if inventory:
		inventory.add_item("explorers_journal", 1)
	get_tree().call_group("hud", "show_notification", "Found the Explorer's Journal!", Color(1, 0.85, 0.3, 1))
	queue_free()
```

**Step 2: Track collection in save data**

Add `sinkhole_book_collected: bool` to save data so the book doesn't respawn after being collected.

**Step 3: Commit**

```
git add scripts/world/explorers_journal_pickup.gd
git commit -m "Add Explorer's Journal pickup: glowing book on pedestal at sinkhole bottom"
```

---

### Task 4: Journal Reading UI and Rewards

**Files:**
- Create: `scripts/ui/journal_ui.gd`
- Modify: `scripts/player/player_controller.gd`
- Modify: `scripts/player/player_stats.gd`
- Modify: `scripts/core/save_load.gd`

**Step 1: Create journal UI**

Full-screen panel (CanvasLayer 80, above HUD at 60, below pause at 100). Uses project font/styling conventions from CLAUDE.md:
- Dark semi-transparent background `Color(0.1, 0.1, 0.12, 0.85)`
- Gold title "Explorer's Journal" at 56px
- Journal text in white at 32px, 3-4 paragraphs
- "Close" hint at bottom at 28px
- ESC/Circle to close

Journal text content (pragmatic, weathered explorer tone):

```
"Day 47. I've mapped every oasis in this forsaken desert ring — three
in all, each hiding gemstones beneath the water. Diamonds in two of
them, opals in the third. The opal pool has a river that flows to it
from the east.

The caves in the rocky highlands hold crystals and rare ore. I've
marked four entrances. Bring light — the darkness in those tunnels
will kill you faster than any beast.

I spent weeks perfecting a design for a glider — fabric stretched
across a frame of branches and rope. From the mountain peaks, you can
see the whole world. The plans are sketched on the last page.

If you've found this, you've earned what I've left behind. The
wilderness gives its secrets to those willing to go deep."
```

**Step 2: Trigger journal reading from player_controller.gd**

When the player uses `explorers_journal` (eat/use action), instead of eating it:
- Open the journal UI
- On first read, trigger all 3 rewards after closing the UI
- Set `has_read_journal = true` in player data
- The item stays in inventory (not consumed)

**Step 3: Implement Reward 1 — Stat boost**

In `player_stats.gd`, add:
```gdscript
var max_health_bonus: int = 0
```

Modify `max_health` to be `100 + max_health_bonus`. When journal is first read, set `max_health_bonus = 25` and heal to new max.

In `player_controller.gd`, reduce `hunger_depletion_rate` from 0.05 to 0.04 permanently. Save this value.

Notification: "Ancient survival wisdom flows through you..." (green)

**Step 4: Implement Reward 2 — Hang glider recipe unlock**

In `crafting_system.gd`, add the hang_glider recipe with a new field `"requires_journal": true`. The recipe is hidden from the crafting UI until `has_read_journal` is true.

Recipe:
```gdscript
"hang_glider": {
	"name": "Hang Glider",
	"inputs": {"rope": 4, "branch": 6, "hide": 2},
	"output_type": "hang_glider",
	"output_amount": 1,
	"description": "A fabric wing for soaring above the wilderness.",
	"requires_bench": true,
	"min_camp_level": 3,
	"requires_journal": true
}
```

Notification: "You've learned to craft a Hang Glider" (green)

**Step 5: Implement Reward 3 — Map markers**

Add a `map_markers_unlocked: bool` flag to player save data. When true, the compass HUD panel (in `hud.gd`) cycles through additional entries:
- All 3 oasis positions (from `chunk_manager.desert_oases`) with gem type labels
- All cave entrance positions (from `chunk_manager.cave_entrances`)
- The sinkhole position

The compass update function (~line 1084 in hud.gd) already shows direction/distance to lodestone. Extend it to cycle through POIs every 3 seconds when `map_markers_unlocked` is true.

Notification: "The journal reveals hidden locations..." (green)

**Step 6: Save/load all new persistent data**

In `save_load.gd`, add to player data:
- `has_read_journal: bool`
- `max_health_bonus: int`
- `hunger_depletion_rate: float`
- `map_markers_unlocked: bool`
- `sinkhole_book_collected: bool`

**Step 7: Commit**

```
git add scripts/ui/journal_ui.gd scripts/player/player_controller.gd scripts/player/player_stats.gd scripts/crafting/crafting_system.gd scripts/ui/hud.gd scripts/core/save_load.gd
git commit -m "Add journal reading UI with 3 rewards: stat boost, hang glider recipe, map markers"
```

---

### Task 5: Hang Glider Equipment and Crafting

**Files:**
- Modify: `scripts/player/equipment.gd`
- Modify: `scripts/crafting/crafting_system.gd`
- Modify: `scripts/campsite/structure_data.gd` (only if needed for placement)

**Step 1: Add hang glider to EQUIPPABLE_ITEMS**

In `equipment.gd` (~line 12), add to the EQUIPPABLE_ITEMS dictionary:

```gdscript
"hang_glider": {
	"slot": 25,
	"name": "Hang Glider",
	"tool_type": "glider",
	"has_light": false,
	"effectiveness": 1.0,
	"placeable": false,
	"upgrade_target": ""
}
```

**Step 2: Hang glider has no durability (infinite)**

Do NOT add it to `TOOL_MAX_DURABILITY`. In `init_tool_durability()`, skip items not in the dictionary (they get infinite use).

**Step 3: Create first-person held model**

Add `_create_hang_glider_model()` to equipment.gd. Triangular fabric wing frame with grip bar:
- Central grip bar: horizontal dark-wood cylinder (BoxMesh, 0.04 x 0.04 x 0.5)
- Two wing struts from grip bar angling outward/forward (branch-colored)
- Cross-strut connecting wing tips
- Fabric panels (flat BoxMesh, canvas-tan with slight transparency) stretched between struts
- Held position: above and in front of camera, angled slightly

**Step 4: Add crafting recipe (conditionally visible)**

Already covered in Task 4 Step 4 — the recipe exists with `requires_journal: true`. In `crafting_system.gd`, modify `get_all_recipes_status()` to filter out recipes with `requires_journal: true` unless the player has read the journal.

**Step 5: Commit**

```
git add scripts/player/equipment.gd scripts/crafting/crafting_system.gd
git commit -m "Add hang glider equipment: infinite durability, first-person model, conditional recipe"
```

---

### Task 6: Hang Glider Flight Mechanics

**Files:**
- Modify: `scripts/player/player_controller.gd`
- Modify: `scripts/ui/hud.gd`
- Modify: `scripts/systems/input_manager.gd`

**Step 1: Add gliding state variables**

Near the swimming/grappling state vars in player_controller.gd, add:

```gdscript
var is_gliding: bool = false
var glide_speed: float = 8.0
var glide_climb_rate: float = 1.0
var glide_descent_rate: float = 2.0
var glide_max_height_above_terrain: float = 25.0
```

**Step 2: Add deploy/retract logic**

In the input handling section (where `use_equipped` is processed), add:
- If hang_glider is equipped AND player is airborne (not on floor) AND presses use_equipped → set `is_gliding = true`
- If gliding AND presses jump or crouch → set `is_gliding = false`, resume normal physics

**Step 3: Add `_process_gliding()` function**

New function called from `_physics_process()` when `is_gliding`:

```gdscript
func _process_gliding(delta: float) -> void:
	# Get camera pitch for climb/dive control
	var pitch: float = camera.rotation.x  # Negative = looking up, positive = looking down

	# Vertical movement based on camera pitch
	# Looking up (pitch < 0): climb at up to glide_climb_rate
	# Looking down (pitch > 0): descend at up to glide_descent_rate
	# Level (pitch ~0): gentle descent
	var vertical_speed: float = 0.0
	if pitch < -0.1:  # Looking up
		var climb_factor: float = clampf(-pitch / 0.8, 0.0, 1.0)
		vertical_speed = glide_climb_rate * climb_factor
	else:
		var dive_factor: float = clampf(pitch / 0.8, 0.0, 1.0)
		vertical_speed = -glide_descent_rate * (0.3 + 0.7 * dive_factor)

	# Enforce max height above terrain
	var terrain_height: float = 0.0
	var chunk_mgr: Node = get_tree().get_first_node_in_group("chunk_manager")
	if chunk_mgr and chunk_mgr.has_method("get_height_at"):
		terrain_height = chunk_mgr.get_height_at(global_position.x, global_position.z)
	var height_above_terrain: float = global_position.y - terrain_height
	if height_above_terrain >= glide_max_height_above_terrain and vertical_speed > 0:
		vertical_speed = 0.0

	velocity.y = vertical_speed

	# Horizontal movement: forward in camera direction at glide_speed
	var cam_basis: Basis = camera.global_transform.basis
	var forward: Vector3 = -cam_basis.z
	forward.y = 0
	forward = forward.normalized()

	# Allow steering with left stick / WASD
	var input_dir: Vector2 = _get_movement_input()
	var move_dir: Vector3 = forward
	if input_dir.length() > 0.1:
		var right: Vector3 = cam_basis.x
		right.y = 0
		right = right.normalized()
		move_dir = (forward * input_dir.y + right * input_dir.x).normalized()
		if move_dir.length() < 0.1:
			move_dir = forward

	velocity.x = move_dir.x * glide_speed
	velocity.z = move_dir.z * glide_speed

	move_and_slide()

	# Auto-land if touching ground
	if is_on_floor():
		is_gliding = false
```

**Step 4: Integrate into `_physics_process()`**

Add early return for gliding state, similar to swimming/grappling:

```gdscript
if is_gliding:
	_process_gliding(delta)
	return
```

**Step 5: Disable gliding when entering water**

In the water detection section, if `is_gliding` and entering water, retract glider.

**Step 6: Add HUD indicator**

When gliding, show a small "GLIDING" label or change the crosshair color to indicate flight state. Optional: show altitude above terrain.

**Step 7: Update input_manager.gd prompts**

Add glider prompts for the equipment display: `[R2 deploy, × retract]` (controller) / `[R deploy, Space retract]` (keyboard).

**Step 8: Commit**

```
git add scripts/player/player_controller.gd scripts/ui/hud.gd scripts/systems/input_manager.gd
git commit -m "Add hang glider flight: pitch-based climb/dive, 8 u/s speed, 25-unit max height"
```

---

### Task 7: Save/Load Integration

**Files:**
- Modify: `scripts/core/save_load.gd`
- Modify: `scripts/world/chunk_manager.gd`

**Step 1: Save sinkhole state**

Add to the world/structure save data:
- `sinkhole_book_collected`: whether the book has been taken
- `coca_leaf_depleted_time`: game time when coca leaf was picked (-1 if available)

**Step 2: Save journal reward state**

Add to player save data:
- `has_read_journal`
- `max_health_bonus`
- `hunger_depletion_rate`
- `map_markers_unlocked`
- `coca_leaf_timer` (remaining buff time)

**Step 3: Load and restore state**

On load:
- If `sinkhole_book_collected`, don't spawn the book in `_spawn_sinkhole_contents()`
- If coca leaf depleted and 72h haven't elapsed, don't spawn coca leaf
- Restore stat bonuses, recipe visibility, compass markers
- Restore coca leaf breath buff timer if active

**Step 4: Backward compatibility**

All new fields default gracefully: `has_read_journal = false`, `max_health_bonus = 0`, `map_markers_unlocked = false`, etc. Old saves without these fields work without changes.

**Step 5: Commit**

```
git add scripts/core/save_load.gd scripts/world/chunk_manager.gd
git commit -m "Save/load sinkhole state, journal rewards, coca leaf respawn tracking"
```

---

### Task 8: Update DEV_LOG.md

**Files:**
- Modify: `DEV_LOG.md`

**Step 1: Add session entry**

Document all features implemented: sinkhole generation, coca leaf plant, explorer's journal pickup, journal reading UI, 3 rewards (stat boost, hang glider, map markers), hang glider flight mechanics, save/load integration.

List all new and modified files.

**Step 2: Update Next Session section**

Remove completed tasks, add any follow-up items discovered during implementation.

**Step 3: Commit**

```
git add DEV_LOG.md
git commit -m "Update dev log with desert sinkhole Easter egg session"
```

---

## Implementation Order

Tasks 1-3 form the core sinkhole/pickup/coca leaf (can be tested by walking to the sinkhole, eating coca leaf, diving). Task 4 adds the journal reading and rewards. Task 5-6 add the hang glider. Task 7 ensures persistence. Task 8 is documentation.

Each task builds on the previous one and can be verified independently before moving to the next.
