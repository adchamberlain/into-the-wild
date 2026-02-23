# Desert Biome Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a ring-shaped desert biome at 150-250 units from spawn with palm oases containing underwater diamonds/opals, desert vegetation (cactus/palm), ambient creatures (lizard/tortoise), and survival hazards (hunger drain, sandstorms).

**Architecture:** Extend the existing `RegionType` enum with `DESERT = 5`. Distance-based selection in `get_region_at()` overrides noise when 150-250 units from origin. All per-region infrastructure (colors, heights, vegetation, animals) gets a DESERT entry. Oases are placed like water bodies. New vegetation/creature scripts follow existing patterns.

**Tech Stack:** Godot 4.5, GDScript, procedural BoxMesh primitives, GPUParticles3D for sandstorms.

**Design doc:** `docs/plans/2026-02-23-desert-biome-design.md`

---

## Task 1: Add DESERT RegionType and terrain parameters

**Files:**
- Modify: `scripts/world/chunk_manager.gd`

**Step 1: Add DESERT to RegionType enum**

At line 5, change:
```gdscript
enum RegionType { MEADOW, FOREST, HILLS, ROCKY, MOUNTAIN }
```
to:
```gdscript
enum RegionType { MEADOW, FOREST, HILLS, ROCKY, MOUNTAIN, DESERT }
```

**Step 2: Add DESERT entry to region_colors dictionary**

After the MOUNTAIN entry (around line 108), add:
```gdscript
RegionType.DESERT: {
    "grass": Color(0.82, 0.72, 0.55),  # Sandy tan
    "dirt": Color(0.70, 0.58, 0.40)     # Darker sand
},
```

**Step 3: Add DESERT entry to region_height_params dictionary**

After the MOUNTAIN entry (around line 119), add:
```gdscript
RegionType.DESERT: {"scale": 4.0, "step": 0.5},  # Gentle rolling dunes
```

**Step 4: Add DESERT entry to region_vegetation dictionary**

After the MOUNTAIN entry (around line 128), add:
```gdscript
RegionType.DESERT: {"tree": 0.0, "rock": 0.3, "berry": 0.0, "herb": 0.0, "osha": 0.0, "cactus": 1.0, "palm": 0.3},
```

**Step 5: Update get_region_at() with desert distance check**

In `get_region_at()` (line 1035), add desert ring logic after the spawn forest check and before noise-based selection. The full function should become:

```gdscript
func get_region_at(x: float, z: float) -> RegionType:
    var spawn_distance: float = Vector2(x, z).length()
    if spawn_distance < 60.0:
        return RegionType.FOREST

    # Desert ring: 150-250 units from spawn
    # Transition zones: 150-170 (blend in), 230-250 (blend out)
    if spawn_distance >= 170.0 and spawn_distance <= 230.0:
        return RegionType.DESERT

    var value: float = region_noise.get_noise_2d(x, z)

    if value > 0.6 and spawn_distance > 100.0:
        return RegionType.MOUNTAIN
    if value < -0.3:
        return RegionType.MEADOW
    elif value < 0.2:
        return RegionType.FOREST
    elif value < 0.5:
        return RegionType.HILLS
    else:
        return RegionType.ROCKY
```

Note: The 150-170 and 230-250 transition zones will be handled by color/height interpolation in terrain_chunk.gd (Task 7), not by returning a different RegionType. Chunks in those bands will get DESERT or the noise-based region, but their visual parameters will be blended.

**Step 6: Commit**

```bash
git add scripts/world/chunk_manager.gd
git commit -m "feat: add DESERT RegionType with terrain parameters"
```

---

## Task 2: Create palm tree mesh

**Files:**
- Create: `scripts/world/palm_tree.gd`

**Step 1: Create palm_tree.gd**

Follow the pattern of tree creation in `terrain_chunk.gd` `_spawn_chunk_trees()` (lines 966-1025). Palm trees are a Node3D with BoxMesh primitives: tan trunk (tall, thin column with slight taper), green frond clusters at top.

```gdscript
extends Node3D
class_name PalmTree
## A procedural palm tree built from BoxMesh primitives.

static var shared_trunk_material: StandardMaterial3D
static var shared_frond_material: StandardMaterial3D
static var shared_frond_dark_material: StandardMaterial3D

var tree_height: float = 6.0


func _init() -> void:
    _ensure_shared_materials()


static func _ensure_shared_materials() -> void:
    if shared_trunk_material != null:
        return
    shared_trunk_material = StandardMaterial3D.new()
    shared_trunk_material.albedo_color = Color(0.55, 0.40, 0.25)
    shared_frond_material = StandardMaterial3D.new()
    shared_frond_material.albedo_color = Color(0.25, 0.55, 0.20)
    shared_frond_dark_material = StandardMaterial3D.new()
    shared_frond_dark_material.albedo_color = Color(0.18, 0.42, 0.15)


func build(rng: RandomNumberGenerator) -> void:
    tree_height = rng.randf_range(5.0, 8.0)

    # Trunk - slightly curved using 3-4 stacked segments
    var segments: int = 4
    var segment_height: float = tree_height / segments
    var sway_x: float = rng.randf_range(-0.3, 0.3)
    var sway_z: float = rng.randf_range(-0.3, 0.3)

    for i: int in range(segments):
        var trunk_seg: MeshInstance3D = MeshInstance3D.new()
        var seg_box: BoxMesh = BoxMesh.new()
        var width: float = lerpf(0.35, 0.20, float(i) / segments)
        seg_box.size = Vector3(width, segment_height, width)
        seg_box.material = shared_trunk_material
        trunk_seg.mesh = seg_box
        trunk_seg.position = Vector3(
            sway_x * float(i) / segments,
            segment_height * 0.5 + segment_height * i,
            sway_z * float(i) / segments
        )
        add_child(trunk_seg)

    # Trunk ring details (darker bands)
    var ring_mat: StandardMaterial3D = StandardMaterial3D.new()
    ring_mat.albedo_color = Color(0.42, 0.30, 0.18)
    for i: int in range(3):
        var ring: MeshInstance3D = MeshInstance3D.new()
        var ring_box: BoxMesh = BoxMesh.new()
        ring_box.size = Vector3(0.38, 0.06, 0.38)
        ring_box.material = ring_mat
        ring.mesh = ring_box
        ring.position.y = tree_height * 0.3 + i * tree_height * 0.25
        add_child(ring)

    # Crown position (top of trunk with sway offset)
    var crown_pos: Vector3 = Vector3(sway_x, tree_height, sway_z)

    # Fronds - 6 drooping leaf clusters radiating outward
    var frond_count: int = 6
    for i: int in range(frond_count):
        var angle: float = TAU * i / frond_count + rng.randf_range(-0.2, 0.2)
        var frond_len: float = rng.randf_range(2.0, 3.0)

        # Main frond leaf
        var frond: MeshInstance3D = MeshInstance3D.new()
        var frond_box: BoxMesh = BoxMesh.new()
        frond_box.size = Vector3(0.5, 0.05, frond_len)
        frond_box.material = shared_frond_material if i % 2 == 0 else shared_frond_dark_material
        frond.mesh = frond_box
        frond.position = crown_pos + Vector3(cos(angle) * frond_len * 0.4, -0.3, sin(angle) * frond_len * 0.4)
        frond.rotation.y = angle
        frond.rotation.x = deg_to_rad(25.0)  # Droop down
        add_child(frond)

    # Coconut cluster (2-3 small brown spheres near crown)
    var coconut_mat: StandardMaterial3D = StandardMaterial3D.new()
    coconut_mat.albedo_color = Color(0.45, 0.30, 0.15)
    var coconut_count: int = rng.randi_range(2, 3)
    for i: int in range(coconut_count):
        var coconut: MeshInstance3D = MeshInstance3D.new()
        var coconut_box: BoxMesh = BoxMesh.new()
        coconut_box.size = Vector3(0.18, 0.18, 0.18)
        coconut_box.material = coconut_mat
        coconut.mesh = coconut_box
        var c_angle: float = TAU * i / coconut_count
        coconut.position = crown_pos + Vector3(cos(c_angle) * 0.2, -0.4, sin(c_angle) * 0.2)
        add_child(coconut)
```

**Step 2: Commit**

```bash
git add scripts/world/palm_tree.gd
git commit -m "feat: add procedural palm tree mesh"
```

---

## Task 3: Create cactus with damage/fruit variants

**Files:**
- Create: `scripts/world/cactus.gd`

**Step 1: Create cactus.gd**

Cactus is an interactable Node3D. 80% are prickly (damage on touch via Area3D), 20% are fruit-bearing (harvestable via interaction). Follow the pattern of resource nodes for interaction.

```gdscript
extends Node3D
class_name Cactus
## A procedural cactus. 80% deal contact damage, 20% have harvestable fruit.

static var shared_body_material: StandardMaterial3D
static var shared_dark_material: StandardMaterial3D
static var shared_spine_material: StandardMaterial3D
static var shared_fruit_material: StandardMaterial3D

var is_fruit_bearing: bool = false
var is_harvested: bool = false
var damage_cooldown: float = 0.0
const DAMAGE_COOLDOWN_TIME: float = 1.5
const CONTACT_DAMAGE: float = 8.0


func _init() -> void:
    _ensure_shared_materials()


static func _ensure_shared_materials() -> void:
    if shared_body_material != null:
        return
    shared_body_material = StandardMaterial3D.new()
    shared_body_material.albedo_color = Color(0.30, 0.55, 0.25)
    shared_dark_material = StandardMaterial3D.new()
    shared_dark_material.albedo_color = Color(0.22, 0.42, 0.18)
    shared_spine_material = StandardMaterial3D.new()
    shared_spine_material.albedo_color = Color(0.85, 0.82, 0.70)
    shared_fruit_material = StandardMaterial3D.new()
    shared_fruit_material.albedo_color = Color(0.85, 0.20, 0.25)


func build(rng: RandomNumberGenerator, fruit: bool) -> void:
    is_fruit_bearing = fruit

    # Main column
    var height: float = rng.randf_range(1.5, 3.0)
    var width: float = rng.randf_range(0.35, 0.50)

    var body: MeshInstance3D = MeshInstance3D.new()
    var body_box: BoxMesh = BoxMesh.new()
    body_box.size = Vector3(width, height, width)
    body_box.material = shared_body_material
    body.mesh = body_box
    body.position.y = height * 0.5
    add_child(body)

    # Vertical ridges (darker stripes)
    for i: int in range(4):
        var ridge: MeshInstance3D = MeshInstance3D.new()
        var ridge_box: BoxMesh = BoxMesh.new()
        ridge_box.size = Vector3(0.03, height * 0.9, width + 0.02)
        ridge_box.material = shared_dark_material
        ridge.mesh = ridge_box
        ridge.position.y = height * 0.5
        ridge.rotation.y = TAU * i / 4
        add_child(ridge)

    # Arms (0-2 branches)
    var arm_count: int = rng.randi_range(0, 2)
    for i: int in range(arm_count):
        var arm_y: float = height * rng.randf_range(0.4, 0.7)
        var arm_dir: float = 1.0 if i == 0 else -1.0
        var arm_length: float = rng.randf_range(0.6, 1.2)

        # Horizontal segment
        var h_arm: MeshInstance3D = MeshInstance3D.new()
        var h_box: BoxMesh = BoxMesh.new()
        h_box.size = Vector3(arm_length, width * 0.7, width * 0.7)
        h_box.material = shared_body_material
        h_arm.mesh = h_box
        h_arm.position = Vector3(arm_dir * arm_length * 0.5 + arm_dir * width * 0.4, arm_y, 0)
        add_child(h_arm)

        # Vertical tip
        var v_arm: MeshInstance3D = MeshInstance3D.new()
        var v_box: BoxMesh = BoxMesh.new()
        var tip_h: float = rng.randf_range(0.5, 1.0)
        v_box.size = Vector3(width * 0.65, tip_h, width * 0.65)
        v_box.material = shared_body_material
        v_arm.mesh = v_box
        v_arm.position = Vector3(arm_dir * (arm_length + width * 0.3), arm_y + tip_h * 0.5, 0)
        add_child(v_arm)

    # Spines (small white protrusions)
    for i: int in range(8):
        var spine: MeshInstance3D = MeshInstance3D.new()
        var spine_box: BoxMesh = BoxMesh.new()
        spine_box.size = Vector3(0.02, 0.12, 0.02)
        spine_box.material = shared_spine_material
        spine.mesh = spine_box
        var s_angle: float = TAU * i / 8
        spine.position = Vector3(
            cos(s_angle) * width * 0.5,
            rng.randf_range(height * 0.2, height * 0.8),
            sin(s_angle) * width * 0.5
        )
        spine.rotation.z = cos(s_angle) * deg_to_rad(30.0)
        spine.rotation.x = sin(s_angle) * deg_to_rad(30.0)
        add_child(spine)

    # Fruit (only on fruit-bearing cactuses)
    if is_fruit_bearing:
        var fruit_mesh: MeshInstance3D = MeshInstance3D.new()
        fruit_mesh.name = "FruitMesh"
        var fruit_box: BoxMesh = BoxMesh.new()
        fruit_box.size = Vector3(0.18, 0.22, 0.18)
        fruit_box.material = shared_fruit_material
        fruit_mesh.mesh = fruit_box
        fruit_mesh.position = Vector3(0, height + 0.12, 0)
        add_child(fruit_mesh)

        # Add to interactable group for raycasts
        add_to_group("interactable")
        add_to_group("resource_node")

    # Damage area (for prickly cactuses)
    if not is_fruit_bearing:
        var damage_area: Area3D = Area3D.new()
        damage_area.name = "DamageArea"
        damage_area.collision_layer = 0
        damage_area.collision_mask = 4  # Player layer
        var damage_shape: CollisionShape3D = CollisionShape3D.new()
        var damage_box: BoxShape3D = BoxShape3D.new()
        damage_box.size = Vector3(width + 0.3, height, width + 0.3)
        damage_shape.shape = damage_box
        damage_shape.position.y = height * 0.5
        damage_area.add_child(damage_shape)
        damage_area.body_entered.connect(_on_player_contact)
        add_child(damage_area)


func _process(delta: float) -> void:
    if damage_cooldown > 0:
        damage_cooldown -= delta


func _on_player_contact(body: Node) -> void:
    if damage_cooldown > 0:
        return
    if not body.has_method("take_damage"):
        # Try parent (PlayerController is the CharacterBody3D)
        if body.get_parent() and body.get_parent().has_method("take_damage"):
            body = body.get_parent()
        else:
            return
    damage_cooldown = DAMAGE_COOLDOWN_TIME
    body.take_damage(CONTACT_DAMAGE)
    # Show notification via HUD
    var hud_nodes: Array[Node] = body.get_tree().get_nodes_in_group("hud")
    if hud_nodes.size() > 0 and hud_nodes[0].has_method("show_notification"):
        hud_nodes[0].show_notification("Ouch! Cactus spines!", Color(1.0, 0.5, 0.5, 1))


## Called by interaction system when player presses E on fruit cactus
func get_interaction_text() -> String:
    if is_fruit_bearing and not is_harvested:
        return "Pick cactus fruit"
    return ""


func interact(player_node: Node) -> void:
    if not is_fruit_bearing or is_harvested:
        return
    is_harvested = true

    # Add fruit to player inventory
    var inventory: Node = player_node.get_node_or_null("Inventory")
    if inventory and inventory.has_method("add_item"):
        inventory.add_item("cactus_fruit", 1)

    # Hide fruit mesh
    var fruit_node: Node = get_node_or_null("FruitMesh")
    if fruit_node:
        fruit_node.visible = false

    # Show notification
    var hud_nodes: Array[Node] = get_tree().get_nodes_in_group("hud")
    if hud_nodes.size() > 0 and hud_nodes[0].has_method("show_notification"):
        hud_nodes[0].show_notification("+1 Cactus Fruit", Color(0.6, 1.0, 0.6, 1))
```

**Step 2: Verify cactus damage interaction works with existing player**

Check `player_controller.gd` for a `take_damage` method. If it uses `player_stats.take_damage()` or similar, adjust the call. The existing health system is in `player_stats.gd` — look for a method to deal damage and use that.

**Step 3: Commit**

```bash
git add scripts/world/cactus.gd
git commit -m "feat: add cactus with damage and fruit variants"
```

---

## Task 4: Create desert ambient creatures (lizard and tortoise)

**Files:**
- Create: `scripts/creatures/ambient_lizard.gd`
- Create: `scripts/creatures/ambient_tortoise.gd`

**Step 1: Create ambient_lizard.gd**

Extend `AmbientAnimalBase`. Fast, darting movement. Non-huntable (empty loot table, override `take_hit` to do nothing). Follow the pattern of `ambient_rabbit.gd` for structure.

```gdscript
extends AmbientAnimalBase
class_name AmbientLizard
## A small desert lizard. Fast, darting movement. Non-huntable ambient creature.


func _ready() -> void:
    super._ready()
    flee_distance = 6.0
    awareness_distance = 10.0
    move_speed = 5.0
    flee_speed = 9.0
    loot_table = {}  # Non-huntable
    _build_mesh()


func take_hit(_damage: float) -> void:
    # Non-huntable — ignore all damage
    return


func _build_mesh() -> void:
    if not mesh_container:
        return

    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = hash(global_position)

    # Color variation: sandy brown to olive green
    var base_hue: float = rng.randf_range(0.08, 0.18)
    var body_color: Color = Color.from_hsv(base_hue, 0.45, 0.50)
    var belly_color: Color = Color.from_hsv(base_hue, 0.25, 0.65)
    var dark_color: Color = Color.from_hsv(base_hue, 0.50, 0.35)

    var body_mat: StandardMaterial3D = StandardMaterial3D.new()
    body_mat.albedo_color = body_color
    var belly_mat: StandardMaterial3D = StandardMaterial3D.new()
    belly_mat.albedo_color = belly_color
    var dark_mat: StandardMaterial3D = StandardMaterial3D.new()
    dark_mat.albedo_color = dark_color
    var eye_mat: StandardMaterial3D = StandardMaterial3D.new()
    eye_mat.albedo_color = Color(0.1, 0.1, 0.1)

    # Body (flat, elongated)
    var body: MeshInstance3D = MeshInstance3D.new()
    var body_box: BoxMesh = BoxMesh.new()
    body_box.size = Vector3(0.12, 0.06, 0.30)
    body_box.material = body_mat
    body.mesh = body_box
    body.position = Vector3(0, 0.05, 0)
    mesh_container.add_child(body)

    # Belly
    var belly: MeshInstance3D = MeshInstance3D.new()
    var belly_box: BoxMesh = BoxMesh.new()
    belly_box.size = Vector3(0.10, 0.02, 0.25)
    belly_box.material = belly_mat
    belly.mesh = belly_box
    belly.position = Vector3(0, 0.02, 0)
    mesh_container.add_child(belly)

    # Head
    var head: MeshInstance3D = MeshInstance3D.new()
    var head_box: BoxMesh = BoxMesh.new()
    head_box.size = Vector3(0.10, 0.06, 0.10)
    head_box.material = body_mat
    head.mesh = head_box
    head.position = Vector3(0, 0.05, -0.18)
    mesh_container.add_child(head)

    # Eyes
    for side: float in [-1.0, 1.0]:
        var eye: MeshInstance3D = MeshInstance3D.new()
        var eye_box: BoxMesh = BoxMesh.new()
        eye_box.size = Vector3(0.025, 0.025, 0.025)
        eye_box.material = eye_mat
        eye.mesh = eye_box
        eye.position = Vector3(side * 0.04, 0.07, -0.21)
        mesh_container.add_child(eye)

    # Legs (4 splayed out)
    for i: int in range(4):
        var leg: MeshInstance3D = MeshInstance3D.new()
        var leg_box: BoxMesh = BoxMesh.new()
        leg_box.size = Vector3(0.12, 0.03, 0.03)
        leg_box.material = dark_mat
        leg.mesh = leg_box
        var side: float = -1.0 if i % 2 == 0 else 1.0
        var z_pos: float = -0.08 if i < 2 else 0.08
        leg.position = Vector3(side * 0.10, 0.02, z_pos)
        leg.rotation.z = side * deg_to_rad(20.0)
        mesh_container.add_child(leg)

    # Tail (long, thin, tapering)
    var tail: MeshInstance3D = MeshInstance3D.new()
    var tail_box: BoxMesh = BoxMesh.new()
    tail_box.size = Vector3(0.05, 0.04, 0.25)
    tail_box.material = dark_mat
    tail.mesh = tail_box
    tail.position = Vector3(0, 0.04, 0.22)
    mesh_container.add_child(tail)

    var tail_tip: MeshInstance3D = MeshInstance3D.new()
    var tip_box: BoxMesh = BoxMesh.new()
    tip_box.size = Vector3(0.03, 0.025, 0.15)
    tip_box.material = dark_mat
    tail_tip.mesh = tip_box
    tail_tip.position = Vector3(0, 0.03, 0.40)
    mesh_container.add_child(tail_tip)
```

**Step 2: Create ambient_tortoise.gd**

Slow, mostly idle. Dome shell from layered boxes. Non-huntable.

```gdscript
extends AmbientAnimalBase
class_name AmbientTortoise
## A slow desert tortoise. Mostly idle, short flee distance. Non-huntable.


func _ready() -> void:
    super._ready()
    flee_distance = 4.0
    awareness_distance = 8.0
    move_speed = 1.0
    flee_speed = 2.0
    loot_table = {}  # Non-huntable
    _build_mesh()


func take_hit(_damage: float) -> void:
    # Non-huntable — ignore all damage
    return


func _build_mesh() -> void:
    if not mesh_container:
        return

    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = hash(global_position)

    var shell_color: Color = Color(0.40, 0.35, 0.22)
    var shell_dark: Color = Color(0.30, 0.25, 0.15)
    var skin_color: Color = Color(0.50, 0.42, 0.30)
    var eye_color: Color = Color(0.1, 0.1, 0.1)

    var shell_mat: StandardMaterial3D = StandardMaterial3D.new()
    shell_mat.albedo_color = shell_color
    var shell_dark_mat: StandardMaterial3D = StandardMaterial3D.new()
    shell_dark_mat.albedo_color = shell_dark
    var skin_mat: StandardMaterial3D = StandardMaterial3D.new()
    skin_mat.albedo_color = skin_color
    var eye_mat: StandardMaterial3D = StandardMaterial3D.new()
    eye_mat.albedo_color = eye_color

    # Shell dome (layered boxes to create dome shape)
    var shell_layers: Array[Dictionary] = [
        {"size": Vector3(0.40, 0.08, 0.45), "y": 0.12},
        {"size": Vector3(0.36, 0.08, 0.40), "y": 0.20},
        {"size": Vector3(0.28, 0.06, 0.32), "y": 0.26},
        {"size": Vector3(0.18, 0.04, 0.22), "y": 0.30},
    ]
    for layer: Dictionary in shell_layers:
        var shell: MeshInstance3D = MeshInstance3D.new()
        var shell_box: BoxMesh = BoxMesh.new()
        shell_box.size = layer["size"]
        shell_box.material = shell_mat
        shell.mesh = shell_box
        shell.position.y = layer["y"]
        mesh_container.add_child(shell)

    # Shell pattern (darker segments on top)
    for i: int in range(3):
        var seg: MeshInstance3D = MeshInstance3D.new()
        var seg_box: BoxMesh = BoxMesh.new()
        seg_box.size = Vector3(0.32, 0.01, 0.10)
        seg_box.material = shell_dark_mat
        seg.mesh = seg_box
        seg.position = Vector3(0, 0.21, -0.12 + i * 0.12)
        mesh_container.add_child(seg)

    # Underbelly (flat)
    var belly: MeshInstance3D = MeshInstance3D.new()
    var belly_box: BoxMesh = BoxMesh.new()
    belly_box.size = Vector3(0.35, 0.04, 0.40)
    belly_box.material = skin_mat
    belly.mesh = belly_box
    belly.position.y = 0.06
    mesh_container.add_child(belly)

    # Head (protruding from front of shell)
    var head: MeshInstance3D = MeshInstance3D.new()
    var head_box: BoxMesh = BoxMesh.new()
    head_box.size = Vector3(0.12, 0.10, 0.12)
    head_box.material = skin_mat
    head.mesh = head_box
    head.position = Vector3(0, 0.12, -0.28)
    mesh_container.add_child(head)

    # Eyes
    for side: float in [-1.0, 1.0]:
        var eye: MeshInstance3D = MeshInstance3D.new()
        var eye_box: BoxMesh = BoxMesh.new()
        eye_box.size = Vector3(0.03, 0.03, 0.03)
        eye_box.material = eye_mat
        eye.mesh = eye_box
        eye.position = Vector3(side * 0.05, 0.15, -0.32)
        mesh_container.add_child(eye)

    # Legs (4 stubby)
    for i: int in range(4):
        var leg: MeshInstance3D = MeshInstance3D.new()
        var leg_box: BoxMesh = BoxMesh.new()
        leg_box.size = Vector3(0.08, 0.08, 0.10)
        leg_box.material = skin_mat
        leg.mesh = leg_box
        var side: float = -1.0 if i % 2 == 0 else 1.0
        var z_pos: float = -0.14 if i < 2 else 0.14
        leg.position = Vector3(side * 0.18, 0.04, z_pos)
        mesh_container.add_child(leg)

    # Tail (short stubby)
    var tail: MeshInstance3D = MeshInstance3D.new()
    var tail_box: BoxMesh = BoxMesh.new()
    tail_box.size = Vector3(0.05, 0.04, 0.10)
    tail_box.material = skin_mat
    tail.mesh = tail_box
    tail.position = Vector3(0, 0.06, 0.25)
    mesh_container.add_child(tail)
```

**Step 3: Commit**

```bash
git add scripts/creatures/ambient_lizard.gd scripts/creatures/ambient_tortoise.gd
git commit -m "feat: add desert lizard and tortoise ambient creatures"
```

---

## Task 5: Create underwater gem node

**Files:**
- Create: `scripts/resources/gem_node.gd`

**Step 1: Create gem_node.gd**

Follow the pattern of `ore_node.gd` which extends `ResourceNode`. Gem node sits on pool floor, glows, requires axe to mine (multiple hits while underwater). Two variants: diamond and opal.

```gdscript
extends ResourceNode
class_name GemNode
## An underwater gem deposit found in desert oases.
## Requires axe to mine. Glows to be visible from the surface.

var gem_type: String = "diamond"  # "diamond" or "opal"

static var shared_diamond_material: StandardMaterial3D
static var shared_opal_material: StandardMaterial3D
static var shared_glow_material: StandardMaterial3D


func _ready() -> void:
    super._ready()
    required_tool = "axe"
    chops_required = 4
    adjust_to_terrain = false

    if gem_type == "diamond":
        resource_type = "diamond"
        resource_amount = 1
        interaction_text = "Mine Diamond"
    else:
        resource_type = "opal"
        resource_amount = 1
        interaction_text = "Mine Opal"

    _ensure_shared_materials()
    _build_gem_mesh()


static func _ensure_shared_materials() -> void:
    if shared_diamond_material != null:
        return
    shared_diamond_material = StandardMaterial3D.new()
    shared_diamond_material.albedo_color = Color(0.7, 0.85, 1.0)
    shared_diamond_material.emission_enabled = true
    shared_diamond_material.emission = Color(0.4, 0.6, 1.0)
    shared_diamond_material.emission_energy_multiplier = 0.8

    shared_opal_material = StandardMaterial3D.new()
    shared_opal_material.albedo_color = Color(0.85, 0.75, 1.0)
    shared_opal_material.emission_enabled = true
    shared_opal_material.emission = Color(0.6, 0.4, 0.9)
    shared_opal_material.emission_energy_multiplier = 0.8

    shared_glow_material = StandardMaterial3D.new()
    shared_glow_material.albedo_color = Color(1, 1, 1, 0.3)
    shared_glow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    shared_glow_material.emission_enabled = true
    shared_glow_material.emission = Color(0.8, 0.9, 1.0)
    shared_glow_material.emission_energy_multiplier = 1.5


func _build_gem_mesh() -> void:
    var mat: StandardMaterial3D = shared_diamond_material if gem_type == "diamond" else shared_opal_material

    # Main crystal cluster (3-4 angled boxes)
    for i: int in range(4):
        var crystal: MeshInstance3D = MeshInstance3D.new()
        var crystal_box: BoxMesh = BoxMesh.new()
        var h: float = randf_range(0.3, 0.6)
        crystal_box.size = Vector3(0.12, h, 0.12)
        crystal_box.material = mat
        crystal.mesh = crystal_box
        crystal.position = Vector3(
            randf_range(-0.15, 0.15),
            h * 0.5,
            randf_range(-0.15, 0.15)
        )
        crystal.rotation.x = deg_to_rad(randf_range(-15, 15))
        crystal.rotation.z = deg_to_rad(randf_range(-15, 15))
        add_child(crystal)

    # Glow sphere (semi-transparent light halo)
    var glow: MeshInstance3D = MeshInstance3D.new()
    var glow_box: BoxMesh = BoxMesh.new()
    glow_box.size = Vector3(0.8, 0.8, 0.8)
    glow_box.material = shared_glow_material
    glow.mesh = glow_box
    glow.position.y = 0.3
    add_child(glow)
```

**Step 2: Commit**

```bash
git add scripts/resources/gem_node.gd
git commit -m "feat: add underwater gem node for diamond and opal"
```

---

## Task 6: Create desert oasis generation

**Files:**
- Create: `scripts/world/desert_oasis.gd`
- Modify: `scripts/world/chunk_manager.gd` — add oasis placement logic

**Step 1: Create desert_oasis.gd**

Generates the oasis pool (deeper water body), surrounding palm trees, and underwater gem nodes. Similar to how fishing_spot.gd creates water areas.

```gdscript
extends Node3D
class_name DesertOasis
## A palm oasis in the desert with a deep pool containing rare gems.

var oasis_radius: float = 6.0
var oasis_depth: float = 4.0
var gem_type: String = "diamond"  # "diamond" or "opal"
var gem_count: int = 3


func build(rng: RandomNumberGenerator) -> void:
    # Create water visual (blue-tinted disc)
    var water_mesh: MeshInstance3D = MeshInstance3D.new()
    var water_box: BoxMesh = BoxMesh.new()
    water_box.size = Vector3(oasis_radius * 2, 0.15, oasis_radius * 2)
    var water_mat: StandardMaterial3D = StandardMaterial3D.new()
    water_mat.albedo_color = Color(0.15, 0.45, 0.65, 0.7)
    water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    water_box.material = water_mat
    water_mesh.mesh = water_box
    water_mesh.position.y = 0.1
    add_child(water_mesh)

    # Water area for swimming detection
    var water_area: Area3D = Area3D.new()
    water_area.name = "WaterArea"
    water_area.collision_layer = 0
    water_area.collision_mask = 4  # Player detection
    var water_shape: CollisionShape3D = CollisionShape3D.new()
    var water_volume: BoxShape3D = BoxShape3D.new()
    water_volume.size = Vector3(oasis_radius * 2, oasis_depth, oasis_radius * 2)
    water_shape.shape = water_volume
    water_shape.position.y = -oasis_depth * 0.5
    water_area.add_child(water_shape)
    water_area.body_entered.connect(_on_body_entered_water)
    water_area.body_exited.connect(_on_body_exited_water)
    add_child(water_area)

    # Spawn palm trees around the pool
    var palm_count: int = rng.randi_range(4, 6)
    for i: int in range(palm_count):
        var angle: float = TAU * i / palm_count + rng.randf_range(-0.3, 0.3)
        var dist: float = oasis_radius + rng.randf_range(1.0, 3.0)
        var palm: PalmTree = PalmTree.new()
        palm.build(rng)
        palm.position = Vector3(cos(angle) * dist, 0, sin(angle) * dist)
        add_child(palm)

    # Spawn gem nodes on pool floor
    for i: int in range(gem_count):
        var gem: GemNode = GemNode.new()
        gem.gem_type = gem_type
        var gem_angle: float = TAU * i / gem_count + rng.randf_range(-0.3, 0.3)
        var gem_dist: float = rng.randf_range(1.0, oasis_radius - 1.0)
        gem.position = Vector3(
            cos(gem_angle) * gem_dist,
            -oasis_depth + 0.2,  # Sitting on pool floor
            sin(gem_angle) * gem_dist
        )
        add_child(gem)


func _on_body_entered_water(body: Node) -> void:
    if body.has_method("set_in_water"):
        body.set_in_water(true, 0.1)  # Water surface at y=0.1


func _on_body_exited_water(body: Node) -> void:
    if body.has_method("set_in_water"):
        body.set_in_water(false, 0.1)
```

**Step 2: Add oasis placement to chunk_manager.gd**

Add oasis configuration variables near the existing water body / cave variables (around lines 34-62):

```gdscript
# Desert oasis settings
var desert_oases: Array[Dictionary] = []  # {center: Vector2, gem_type: String, gem_count: int}
var desert_inner_radius: float = 170.0
var desert_outer_radius: float = 230.0
```

Add an `_generate_desert_oases()` function that places 3 oases ~120 degrees apart in the desert ring. Call it from `_ready()` after water body generation. 2 diamond oases (2-3 gems each), 1 opal oasis (3 gems). The opal oasis should be the target of the desert river.

**Step 3: Add desert river routing**

In the river generation code (lines 530-596), add logic for one river in the desert ring. It should start from the desert ring edge and flow toward the opal oasis center. Use the same river infrastructure but constrain it to the desert distance range.

**Step 4: Instantiate oases in terrain_chunk.gd**

When a chunk is in the desert range and overlaps an oasis center, instantiate a `DesertOasis` at the oasis position. Check `desert_oases` array from chunk_manager.

**Step 5: Commit**

```bash
git add scripts/world/desert_oasis.gd scripts/world/chunk_manager.gd scripts/world/terrain_chunk.gd
git commit -m "feat: add desert oasis generation with underwater gems"
```

---

## Task 7: Add desert vegetation and creature spawning to terrain_chunk.gd

**Files:**
- Modify: `scripts/world/terrain_chunk.gd`

**Step 1: Add cactus/palm spawning in `_spawn_chunk_trees()`**

In `_spawn_chunk_trees()` (line 880), add DESERT case to the tree type selection (around line 966). When region is DESERT:
- Skip all normal tree types (oak, birch, pine)
- Instead spawn cactuses and palm trees based on vegetation multipliers
- Use `cactus` multiplier from `region_vegetation` for cactus density
- Use `palm` multiplier for isolated palm trees (separate from oasis palms)
- 80% of cactuses are prickly, 20% are fruit-bearing (use `rng.randf() < 0.2`)

```gdscript
# Inside tree type selection, before existing tree logic:
if region == ChunkManager.RegionType.DESERT:
    var cactus_mult: float = vegetation.get("cactus", 0.0)
    var palm_mult: float = vegetation.get("palm", 0.0)
    if rng.randf() < 0.7 * cactus_mult:
        # Spawn cactus
        var cactus: Cactus = Cactus.new()
        cactus.build(rng, rng.randf() < 0.2)  # 20% fruit bearing
        cactus.position = Vector3(world_x, height, world_z)
        add_child(cactus)
    elif rng.randf() < 0.3 * palm_mult:
        # Spawn isolated palm tree
        var palm: PalmTree = PalmTree.new()
        palm.build(rng)
        palm.position = Vector3(world_x, height, world_z)
        add_child(palm)
    continue  # Skip normal tree logic
```

**Step 2: Add desert creature spawning in `_spawn_chunk_animals()`**

In `_spawn_chunk_animals()` (line 1807), add DESERT case to the region match block:

```gdscript
ChunkManager.RegionType.DESERT:
    rabbit_count = 0
    bird_count = 0
    # Desert-specific creatures handled below
```

After the existing animal spawning loop, add desert creature spawning:

```gdscript
if region == ChunkManager.RegionType.DESERT:
    var lizard_count: int = rng.randi_range(1, 3)
    var tortoise_count: int = rng.randi_range(0, 1)
    # Spawn lizards and tortoises at valid positions (same validation as rabbits)
```

**Step 3: Add transition zone color blending**

In the mesh generation code where region colors are applied, check if the cell position is in a transition zone (150-170 or 230-250 units from spawn). If so, lerp between the desert colors and the noise-based region colors using the position within the transition band.

```gdscript
# In mesh color application:
var spawn_dist: float = Vector2(world_x, world_z).length()
var blend: float = 1.0  # Full region color by default

if spawn_dist >= 150.0 and spawn_dist < 170.0:
    # Inner transition: blend from normal to desert
    blend = (spawn_dist - 150.0) / 20.0
    # Lerp colors between noise-region and DESERT
elif spawn_dist > 230.0 and spawn_dist <= 250.0:
    # Outer transition: blend from desert to normal
    blend = 1.0 - (spawn_dist - 230.0) / 20.0
```

**Step 4: Commit**

```bash
git add scripts/world/terrain_chunk.gd
git commit -m "feat: add desert vegetation/creature spawning and transition blending"
```

---

## Task 8: Create diamond arrow projectile

**Files:**
- Create: `scripts/player/diamond_arrow_projectile.gd`

**Step 1: Create diamond_arrow_projectile.gd**

Extends or closely follows `ArrowProjectile` pattern. Key difference: when it sticks or hits terrain, instead of `queue_free()` after 1.5s, it becomes a persistent pickup item.

```gdscript
extends RigidBody3D
class_name DiamondArrowProjectile
## A diamond-tipped arrow that persists after landing and can be picked up.

const MAX_FLIGHT_TIME: float = 5.0  # Slightly longer range
const ARROW_DAMAGE: float = 100.0

var flight_timer: float = 0.0
var is_stuck: bool = false
var has_hit: bool = false
var is_pickable: bool = false


func _ready() -> void:
    _build_mesh()
    collision_layer = 0
    collision_mask = 1

    contact_monitor = true
    max_contacts_reported = 1
    body_entered.connect(_on_body_entered)

    var physics_shape: CollisionShape3D = CollisionShape3D.new()
    var physics_box: BoxShape3D = BoxShape3D.new()
    physics_box.size = Vector3(0.05, 0.05, 0.5)
    physics_shape.shape = physics_box
    add_child(physics_shape)

    # Area3D for animal detection
    var hit_area: Area3D = Area3D.new()
    hit_area.name = "HitArea"
    hit_area.collision_layer = 0
    hit_area.collision_mask = 2
    var area_shape: CollisionShape3D = CollisionShape3D.new()
    var area_box: BoxShape3D = BoxShape3D.new()
    area_box.size = Vector3(0.15, 0.15, 0.6)
    area_shape.shape = area_box
    hit_area.add_child(area_shape)
    hit_area.body_entered.connect(_on_area_body_entered)
    add_child(hit_area)


func _physics_process(delta: float) -> void:
    if is_stuck:
        return  # Stay in place, don't despawn

    flight_timer += delta
    if flight_timer >= MAX_FLIGHT_TIME:
        _become_pickable()
        return

    var vel: Vector3 = linear_velocity
    if vel.length_squared() > 0.01:
        var vel_norm: Vector3 = vel.normalized()
        var up: Vector3 = Vector3.FORWARD if absf(vel_norm.dot(Vector3.UP)) > 0.9 else Vector3.UP
        look_at(global_position + vel, up)


func _on_body_entered(_body: Node) -> void:
    if has_hit:
        return
    _stick_and_become_pickable()


func _on_area_body_entered(body: Node) -> void:
    if has_hit:
        return
    var target: Node = null
    if body.has_method("take_hit"):
        target = body
    elif body.get_parent() and body.get_parent().has_method("take_hit"):
        target = body.get_parent()

    if target:
        has_hit = true
        target.take_hit(ARROW_DAMAGE)
        SFXManager.play_sfx("arrow_hit")
        # Drop at animal position and become pickable
        _become_pickable()


func _stick_and_become_pickable() -> void:
    is_stuck = true
    has_hit = true
    freeze = true
    SFXManager.play_sfx("arrow_hit")
    _become_pickable()


func _become_pickable() -> void:
    is_stuck = true
    has_hit = true
    freeze = true
    is_pickable = true

    # Add to interactable group for player raycast pickup
    add_to_group("interactable")
    add_to_group("resource_node")

    # Add pickup area
    var pickup_area: Area3D = Area3D.new()
    pickup_area.name = "PickupArea"
    pickup_area.collision_layer = 0
    pickup_area.collision_mask = 4  # Player layer
    var pickup_shape: CollisionShape3D = CollisionShape3D.new()
    var pickup_box: BoxShape3D = BoxShape3D.new()
    pickup_box.size = Vector3(0.8, 0.8, 0.8)
    pickup_shape.shape = pickup_box
    pickup_area.add_child(pickup_shape)
    add_child(pickup_area)


func get_interaction_text() -> String:
    if is_pickable:
        return "Pick up diamond arrow"
    return ""


func interact(player_node: Node) -> void:
    if not is_pickable:
        return
    var inventory: Node = player_node.get_node_or_null("Inventory")
    if inventory and inventory.has_method("add_item"):
        inventory.add_item("diamond_arrows", 1)
    queue_free()


func _build_mesh() -> void:
    # Shaft - slightly lighter wood
    var shaft_mesh: MeshInstance3D = MeshInstance3D.new()
    var shaft_box: BoxMesh = BoxMesh.new()
    shaft_box.size = Vector3(0.03, 0.03, 0.5)
    var shaft_mat: StandardMaterial3D = StandardMaterial3D.new()
    shaft_mat.albedo_color = Color(0.50, 0.35, 0.18)
    shaft_box.material = shaft_mat
    shaft_mesh.mesh = shaft_box
    add_child(shaft_mesh)

    # Diamond arrowhead - blue tinted with emission
    var head_mesh: MeshInstance3D = MeshInstance3D.new()
    var head_box: BoxMesh = BoxMesh.new()
    head_box.size = Vector3(0.07, 0.07, 0.10)
    var head_mat: StandardMaterial3D = StandardMaterial3D.new()
    head_mat.albedo_color = Color(0.6, 0.8, 1.0)
    head_mat.emission_enabled = true
    head_mat.emission = Color(0.3, 0.5, 0.8)
    head_mat.emission_energy_multiplier = 0.4
    head_box.material = head_mat
    head_mesh.mesh = head_box
    head_mesh.position.z = -0.27
    head_mesh.rotation.z = deg_to_rad(45.0)
    add_child(head_mesh)

    # Tail fins (same as regular arrow)
    var fin_mat: StandardMaterial3D = StandardMaterial3D.new()
    fin_mat.albedo_color = Color(0.6, 0.55, 0.45)
    for i: int in range(2):
        var fin: MeshInstance3D = MeshInstance3D.new()
        var fin_box: BoxMesh = BoxMesh.new()
        fin_box.size = Vector3(0.06, 0.005, 0.08)
        fin_box.material = fin_mat
        fin.mesh = fin_box
        fin.position.z = 0.22
        if i == 1:
            fin.rotation.z = deg_to_rad(90.0)
        add_child(fin)
```

**Step 2: Commit**

```bash
git add scripts/player/diamond_arrow_projectile.gd
git commit -m "feat: add diamond arrow projectile with pickup mechanic"
```

---

## Task 9: Integrate diamond arrows and enchanted bow into bow_system and equipment

**Files:**
- Modify: `scripts/player/bow_system.gd`
- Modify: `scripts/player/equipment.gd`

**Step 1: Add diamond_axe, enchanted_bow to EQUIPPABLE_ITEMS in equipment.gd**

After the `bow` entry (around line 180), add:

```gdscript
"diamond_axe": {
    "name": "Diamond Axe",
    "slot": 28,
    "has_light": false,
    "tool_type": "axe",
    "effectiveness": 3.0
},
"enchanted_bow": {
    "name": "Enchanted Bow",
    "slot": 29,
    "has_light": false,
    "tool_type": "bow"
},
```

**Step 2: Add durability entries to TOOL_MAX_DURABILITY**

In the durability dictionary (line 185), add:

```gdscript
"diamond_axe": 900,
"enchanted_bow": 200,
```

**Step 3: Update bow_system.gd to support diamond arrows**

In `_has_arrows()` (line 181), check for diamond arrows too:

```gdscript
func _has_arrows() -> bool:
    if not inventory:
        return false
    return inventory.has_item("diamond_arrows", 1) or inventory.has_item("arrows", 1)
```

In `_fire()` (line 126), consume the correct arrow type:

```gdscript
# Consume 1 arrow (prefer diamond arrows)
var using_diamond: bool = false
if inventory:
    if inventory.has_item("diamond_arrows", 1):
        inventory.remove_item("diamond_arrows", 1)
        using_diamond = true
    else:
        inventory.remove_item("arrows", 1)
arrow_count_changed.emit(get_arrow_count())
```

In `_spawn_arrow()` (line 154), spawn the correct projectile type:

```gdscript
func _spawn_arrow() -> void:
    if not camera:
        return
    var forward: Vector3 = -camera.global_basis.z
    var spawn_pos: Vector3 = camera.global_position + forward * 1.5
    var up_angle_rad: float = deg_to_rad(ARROW_LAUNCH_ANGLE)
    var launch_dir: Vector3 = (forward + camera.global_basis.y * tan(up_angle_rad)).normalized()
    var speed: float = lerpf(0.6, 1.0, draw_progress) * ARROW_SPEED

    # Check if enchanted bow for speed bonus
    if equipment and equipment.get_equipped() == "enchanted_bow":
        speed *= 1.5

    var arrow: RigidBody3D
    if _using_diamond_arrow:
        arrow = DiamondArrowProjectile.new()
    else:
        arrow = ArrowProjectile.new()

    var scene_root: Node = get_tree().current_scene
    if scene_root:
        scene_root.add_child(arrow)
        arrow.global_position = spawn_pos
        arrow.linear_velocity = launch_dir * speed
```

Add a class variable to track diamond arrow usage and enchanted bow draw speed:

```gdscript
var _using_diamond_arrow: bool = false
```

In `_fire()`, set `_using_diamond_arrow` before calling `_spawn_arrow()`.

For enchanted bow draw speed, in the draw progress update (where `draw_progress` increases), multiply draw rate by `1.0 / 0.6` when enchanted bow is equipped.

**Step 4: Update `get_arrow_count()` to include diamond arrows**

```gdscript
func get_arrow_count() -> int:
    if not inventory:
        return 0
    return inventory.get_item_count("arrows") + inventory.get_item_count("diamond_arrows")
```

**Step 5: Commit**

```bash
git add scripts/player/bow_system.gd scripts/player/equipment.gd
git commit -m "feat: integrate diamond arrows and enchanted bow into equipment and bow system"
```

---

## Task 10: Add crafting recipes for diamond axe, diamond arrows, enchanted bow, and cactus fruit

**Files:**
- Modify: `scripts/crafting/crafting_system.gd`

**Step 1: Add new recipes to the recipes dictionary**

After the existing `arrow_bundle` recipe (around line 274), add:

```gdscript
"diamond_axe": {
    "name": "Diamond Axe",
    "inputs": {"diamond": 2, "metal_ingot": 1, "rope": 1},
    "output_type": "diamond_axe",
    "output_amount": 1,
    "description": "A powerful axe with a diamond edge. Chops and mines much faster.",
    "requires_bench": true,
    "min_camp_level": 3
},
"diamond_arrow_bundle": {
    "name": "Diamond Arrows",
    "inputs": {"diamond": 1, "branch": 5, "feathers": 2},
    "output_type": "diamond_arrows",
    "output_amount": 10,
    "description": "10 diamond-tipped arrows. Recoverable after firing.",
    "requires_bench": true,
    "min_camp_level": 3
},
"enchanted_bow": {
    "name": "Enchanted Bow",
    "inputs": {"opal": 2, "bow": 1, "rope": 1},
    "output_type": "enchanted_bow",
    "output_amount": 1,
    "description": "An opal-infused bow. Faster draw and longer range.",
    "requires_bench": true,
    "min_camp_level": 3
},
```

**Step 2: Add cactus_fruit as a food item**

Check how existing food items (berry, raw_meat, etc.) work in the inventory/consumption system. Add `cactus_fruit` to the food items list wherever food types are defined. It should restore hunger similar to a berry.

**Step 3: Commit**

```bash
git add scripts/crafting/crafting_system.gd
git commit -m "feat: add desert crafting recipes for diamond axe, diamond arrows, enchanted bow"
```

---

## Task 11: Add desert hunger drain

**Files:**
- Modify: `scripts/player/player_stats.gd`
- Modify: `scripts/player/player_controller.gd`

**Step 1: Add desert hunger multiplier to player_stats.gd**

The existing `hunger_multiplier` (line 32) is already used by weather_manager for heat waves. The desert hunger drain should stack with or replace the weather multiplier. Add a separate desert multiplier:

```gdscript
var desert_hunger_multiplier: float = 1.0  # 1.5x when in desert
```

In `_update_hunger()` (line 57), apply it:

```gdscript
var depletion: float = hunger_depletion_rate
depletion *= hunger_multiplier
depletion *= desert_hunger_multiplier
```

**Step 2: Update player_controller.gd to set desert multiplier**

Add a periodic check (every 2-3 seconds to avoid per-frame overhead) that calls `chunk_manager.get_region_at()` with player position. If DESERT, set `desert_hunger_multiplier = 1.5`, else `1.0`.

```gdscript
var _desert_check_timer: float = 0.0
const DESERT_CHECK_INTERVAL: float = 2.0

# In _process():
_desert_check_timer += delta
if _desert_check_timer >= DESERT_CHECK_INTERVAL:
    _desert_check_timer = 0.0
    _check_desert_status()

func _check_desert_status() -> void:
    var chunk_mgr: Node = get_node_or_null("/root/Main/ChunkManager")  # Adjust path
    if not chunk_mgr or not chunk_mgr.has_method("get_region_at"):
        return
    var region: int = chunk_mgr.get_region_at(global_position.x, global_position.z)
    var stats: PlayerStats = get_node_or_null("PlayerStats")
    if stats:
        if region == ChunkManager.RegionType.DESERT:
            stats.desert_hunger_multiplier = 1.5
        else:
            stats.desert_hunger_multiplier = 1.0
```

**Step 3: Commit**

```bash
git add scripts/player/player_stats.gd scripts/player/player_controller.gd
git commit -m "feat: add 1.5x hunger drain in desert biome"
```

---

## Task 12: Create sandstorm system

**Files:**
- Create: `scripts/world/sandstorm.gd`
- Modify: `scripts/ui/hud.gd` — sandstorm overlay
- Modify: `scripts/player/player_controller.gd` — speed reduction

**Step 1: Create sandstorm.gd**

Manages sandstorm lifecycle: triggers every 3-5 minutes in desert, lasts 30-45 seconds. Uses GPUParticles3D following the pattern in `weather_particles.gd`. Attaches to player when in desert.

```gdscript
extends Node3D
class_name Sandstorm
## Periodic sandstorm effect in the desert biome.
## Reduces visibility and player movement speed.

signal sandstorm_started()
signal sandstorm_ended()

var is_active: bool = false
var is_in_desert: bool = false
var storm_timer: float = 0.0
var storm_duration: float = 0.0
var next_storm_delay: float = 0.0
var particles: GPUParticles3D

const MIN_DELAY: float = 180.0  # 3 minutes
const MAX_DELAY: float = 300.0  # 5 minutes
const MIN_DURATION: float = 30.0
const MAX_DURATION: float = 45.0
const SPEED_MULTIPLIER: float = 0.7  # 30% speed reduction


func _ready() -> void:
    _setup_particles()
    _randomize_next_storm()


func _process(delta: float) -> void:
    if not is_in_desert:
        if is_active:
            end_storm()
        return

    if is_active:
        storm_timer += delta
        if storm_timer >= storm_duration:
            end_storm()
    else:
        next_storm_delay -= delta
        if next_storm_delay <= 0:
            start_storm()


func set_in_desert(in_desert: bool) -> void:
    is_in_desert = in_desert
    if not in_desert and is_active:
        end_storm()


func start_storm() -> void:
    is_active = true
    storm_timer = 0.0
    storm_duration = randf_range(MIN_DURATION, MAX_DURATION)
    if particles:
        particles.emitting = true
    sandstorm_started.emit()


func end_storm() -> void:
    is_active = false
    if particles:
        particles.emitting = false
    _randomize_next_storm()
    sandstorm_ended.emit()


func _randomize_next_storm() -> void:
    next_storm_delay = randf_range(MIN_DELAY, MAX_DELAY)


func _setup_particles() -> void:
    particles = GPUParticles3D.new()
    particles.amount = 800
    particles.lifetime = 2.0
    particles.visibility_aabb = AABB(Vector3(-20, -5, -20), Vector3(40, 15, 40))

    var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
    mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    mat.emission_box_extents = Vector3(15.0, 3.0, 15.0)
    mat.direction = Vector3(1.0, -0.1, 0.3)  # Mostly horizontal wind
    mat.spread = 15.0
    mat.initial_velocity_min = 8.0
    mat.initial_velocity_max = 14.0
    mat.gravity = Vector3(2.0, -0.5, 0.5)
    mat.turbulence_enabled = true
    mat.turbulence_noise_strength = 3.0

    particles.process_material = mat

    # Sand grain mesh
    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = Vector3(0.08, 0.04, 0.08)
    var mesh_mat: StandardMaterial3D = StandardMaterial3D.new()
    mesh_mat.albedo_color = Color(0.82, 0.72, 0.55, 0.6)
    mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mesh.material = mesh_mat
    particles.draw_pass_1 = mesh

    particles.emitting = false
    add_child(particles)
```

**Step 2: Add sandstorm overlay to hud.gd**

Add a full-screen ColorRect overlay that fades in/out during sandstorms. Sandy brown color with reduced opacity for visibility reduction.

Connect to sandstorm signals. When active, show overlay with `Color(0.82, 0.72, 0.55, 0.3)`.

**Step 3: Add speed reduction to player_controller.gd**

In the `_check_desert_status()` function from Task 11, also check sandstorm state. When sandstorm is active, multiply movement speed by `SPEED_MULTIPLIER` (0.7).

**Step 4: Wire sandstorm into the scene**

Add sandstorm as a child of the player (so particles follow them). The desert check from Task 11 also calls `sandstorm.set_in_desert()`.

**Step 5: Commit**

```bash
git add scripts/world/sandstorm.gd scripts/ui/hud.gd scripts/player/player_controller.gd
git commit -m "feat: add periodic sandstorm with visibility and speed reduction"
```

---

## Task 13: Add desert heat indicator to HUD

**Files:**
- Modify: `scripts/ui/hud.gd`

**Step 1: Add heat indicator**

When player is in desert, show a small indicator near the hunger bar (e.g., "HEAT 1.5x" in the warning red color or a sun icon). Use the same check as the desert hunger multiplier — listen for a signal or poll.

Follow the pattern of existing HUD elements: PanelContainer with Label, semi-transparent background, positioned near the hunger bar.

**Step 2: Commit**

```bash
git add scripts/ui/hud.gd
git commit -m "feat: add desert heat indicator to HUD"
```

---

## Task 14: Add terrain depression for oasis pools

**Files:**
- Modify: `scripts/world/chunk_manager.gd`

**Step 1: Add oasis terrain flattening to get_height_at()**

Follow the pattern of pond/cave terrain flattening already in `get_height_at()` (campsite flattening at 6-unit radius, cave flattening at 16-unit radius). Add oasis pool depression: within oasis_radius, lower terrain to -oasis_depth. Ramp up terrain at the pool edge (2-3 unit transition).

In `get_height_at()`, after existing water body checks, add:

```gdscript
# Oasis pool depressions
for oasis: Dictionary in desert_oases:
    var oasis_dist: float = Vector2(x - oasis.center.x, z - oasis.center.y).length()
    if oasis_dist < oasis.radius:
        # Pool floor
        final_height = -oasis.depth
    elif oasis_dist < oasis.radius + 3.0:
        # Ramp from pool edge to terrain
        var blend_factor: float = (oasis_dist - oasis.radius) / 3.0
        final_height = lerpf(-oasis.depth, final_height, blend_factor)
```

**Step 2: Commit**

```bash
git add scripts/world/chunk_manager.gd
git commit -m "feat: add terrain depression for desert oasis pools"
```

---

## Task 15: Add cactus_fruit and gem items to inventory system

**Files:**
- Modify: Inventory item definitions (find where items like `berry`, `raw_meat` are defined)
- Modify: Food consumption system (where food items restore hunger)

**Step 1: Find item/food definitions**

Search for where `berry` is defined as a food item and where eating food restores hunger. Add `cactus_fruit` to the same lists. Also add `diamond` and `opal` as inventory items (non-food, crafting materials).

**Step 2: Add cactus_fruit as food**

Cactus fruit should restore ~15 hunger (similar to berry). Add it alongside berry in the food item list.

**Step 3: Add diamond and opal as crafting materials**

Add to the item registry alongside other materials like `crystal`, `metal_ingot`, etc.

**Step 4: Add diamond_arrows as inventory item**

Add `diamond_arrows` alongside `arrows` in the inventory system. They should stack and be tracked separately from regular arrows.

**Step 5: Commit**

```bash
git commit -m "feat: add cactus fruit, diamond, opal, and diamond arrows to inventory"
```

---

## Task 16: Integration testing and polish

**Step 1: Test desert region selection**

Verify `get_region_at()` returns DESERT for positions at 200 units from spawn, and normal regions at 100 and 300 units.

**Step 2: Test oasis placement**

Verify 3 oases are placed in the desert ring, spaced ~120 degrees apart.

**Step 3: Test diamond arrow lifecycle**

Fire a diamond arrow, verify it sticks in terrain, walk up to it, verify interaction prompt appears, pick it up, verify inventory count increases.

**Step 4: Test crafting recipes**

Verify diamond axe, diamond arrows, and enchanted bow can be crafted with correct ingredients at crafting bench.

**Step 5: Test sandstorm**

Stand in desert for 3-5 minutes, verify sandstorm triggers, particles appear, speed reduces, overlay shows, and it ends after 30-45 seconds.

**Step 6: Test hunger drain**

Verify hunger drains 1.5x faster in desert vs forest.

**Step 7: Test cactus interactions**

Touch a prickly cactus, verify damage + notification. Interact with fruit cactus, verify fruit added to inventory.

**Step 8: Final commit**

```bash
git add -A
git commit -m "feat: desert biome integration testing and polish"
```

---

## Summary

| Task | Description | New Files | Modified Files |
|------|-------------|-----------|----------------|
| 1 | DESERT RegionType + params | — | chunk_manager.gd |
| 2 | Palm tree mesh | palm_tree.gd | — |
| 3 | Cactus with damage/fruit | cactus.gd | — |
| 4 | Lizard + tortoise creatures | ambient_lizard.gd, ambient_tortoise.gd | — |
| 5 | Underwater gem node | gem_node.gd | — |
| 6 | Oasis generation | desert_oasis.gd | chunk_manager.gd, terrain_chunk.gd |
| 7 | Desert vegetation/creature spawning | — | terrain_chunk.gd |
| 8 | Diamond arrow projectile | diamond_arrow_projectile.gd | — |
| 9 | Bow/equipment integration | — | bow_system.gd, equipment.gd |
| 10 | Crafting recipes | — | crafting_system.gd |
| 11 | Desert hunger drain | — | player_stats.gd, player_controller.gd |
| 12 | Sandstorm system | sandstorm.gd | hud.gd, player_controller.gd |
| 13 | Desert heat HUD indicator | — | hud.gd |
| 14 | Oasis terrain depression | — | chunk_manager.gd |
| 15 | Inventory items (fruit, gems, arrows) | — | inventory system files |
| 16 | Integration testing | — | various |
