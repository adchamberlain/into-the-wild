# Bow & Arrow Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a bow and arrow weapon system that lets players craft a bow, craft arrows from feathers, and hunt ambient animals with physics-based arrow projectiles.

**Architecture:** The bow is an equippable tool managed by `equipment.gd`. A new `bow_system.gd` child node on the player handles draw/fire input, spawns arrow projectiles, and builds the bow visual model. Arrows are standalone `arrow_projectile.gd` nodes (RigidBody3D) that detect hits via body_entered signals. Animals gain a `take_hit()` method in `AmbientAnimalBase` for loot drops and death.

**Tech Stack:** Godot 4.5, GDScript, RigidBody3D for arrow physics, procedural BoxMesh visuals, procedural AudioStreamWAV sounds.

**Testing:** SUSPENDED per CLAUDE.md — no new tests. Verify manually in-game.

---

### Task 1: Add Crafting Recipes

**Files:**
- Modify: `scripts/crafting/crafting_system.gd:28-260` (recipes dictionary)

**Step 1: Add bow and arrow recipes to the recipes dictionary**

Add these two entries inside the `recipes = {` dictionary, after the existing `leather_hook_wrap` entry (line ~259):

```gdscript
"bow": {
    "name": "Bow",
    "inputs": {"rope": 2, "branch": 3},
    "output_type": "bow",
    "output_amount": 1,
    "description": "A hunting bow for shooting arrows.",
    "requires_bench": true,
    "min_camp_level": 2
},
"arrow_bundle": {
    "name": "Arrow Bundle",
    "inputs": {"feathers": 2, "branch": 4},
    "output_type": "arrows",
    "output_amount": 20,
    "description": "A bundle of 20 arrows for the bow.",
    "requires_bench": true,
    "min_camp_level": 2
},
```

**Step 2: Commit**

```bash
git add scripts/crafting/crafting_system.gd
git commit -m "feat: add bow and arrow bundle crafting recipes"
```

---

### Task 2: Add Bow Equipment Slot and Durability

**Files:**
- Modify: `scripts/player/equipment.gd:12-176` (EQUIPPABLE_ITEMS, TOOL_MAX_DURABILITY)

**Step 1: Add bow to EQUIPPABLE_ITEMS dictionary**

Add after the `leather_hook_wrap` entry (around line 175):

```gdscript
"bow": {
    "name": "Bow",
    "slot": 27,
    "has_light": false,
    "tool_type": "bow"
},
```

**Step 2: Add bow to TOOL_MAX_DURABILITY dictionary**

Add inside `TOOL_MAX_DURABILITY` (around line 179):

```gdscript
"bow": 80,
```

**Step 3: Commit**

```bash
git add scripts/player/equipment.gd
git commit -m "feat: add bow equipment slot and durability"
```

---

### Task 3: Add Arrow Projectile Script

**Files:**
- Create: `scripts/player/arrow_projectile.gd`

**Step 1: Create the arrow projectile**

The arrow is a RigidBody3D that:
- Has an Area3D child for hit detection (collision with animals/hostiles)
- Builds its own procedural BoxMesh visual (shaft + head + tail fins)
- On `body_entered`: calls `take_hit()` on animals, plays hit sound, despawns
- On terrain hit (or timeout): freezes in place briefly, then despawns
- Despawns after 4 seconds max flight time

```gdscript
extends RigidBody3D
class_name ArrowProjectile
## A physics-based arrow projectile that detects hits on animals and terrain.

const MAX_FLIGHT_TIME: float = 4.0
const STUCK_DURATION: float = 1.5
const ARROW_DAMAGE: float = 100.0  # One-shots ambient animals

var flight_timer: float = 0.0
var is_stuck: bool = false
var stuck_timer: float = 0.0
var has_hit: bool = false


func _ready() -> void:
    # Build arrow mesh
    _build_mesh()

    # Set up collision - layer 0 (terrain), detect layer 4 (animals)
    collision_layer = 0  # Arrow doesn't block anything
    collision_mask = 1   # Collide with terrain (layer 1)

    # Connect body contact for terrain hits
    contact_monitor = true
    max_contacts_reported = 1
    body_entered.connect(_on_body_entered)

    # Create Area3D for animal detection (wider than physics body)
    var area: Area3D = Area3D.new()
    area.name = "HitArea"
    var area_shape: CollisionShape3D = CollisionShape3D.new()
    var box: BoxShape3D = BoxShape3D.new()
    box.size = Vector3(0.15, 0.15, 0.6)
    area_shape.shape = box
    area.add_child(area_shape)
    area.collision_layer = 0
    area.collision_mask = 2  # Layer 2 for animals
    area.body_entered.connect(_on_area_body_entered)
    add_child(area)

    # Physics collision shape (thin stick)
    var col: CollisionShape3D = CollisionShape3D.new()
    var col_box: BoxShape3D = BoxShape3D.new()
    col_box.size = Vector3(0.05, 0.05, 0.5)
    col.shape = col_box
    add_child(col)


func _physics_process(delta: float) -> void:
    if is_stuck:
        stuck_timer += delta
        if stuck_timer >= STUCK_DURATION:
            queue_free()
        return

    flight_timer += delta
    if flight_timer >= MAX_FLIGHT_TIME:
        queue_free()
        return

    # Orient arrow along velocity
    if linear_velocity.length() > 1.0:
        look_at(global_position + linear_velocity.normalized(), Vector3.UP)


func _on_body_entered(body: Node) -> void:
    # Terrain or structure hit
    if has_hit:
        return
    has_hit = true
    _stick_in_place()


func _on_area_body_entered(body: Node) -> void:
    if has_hit:
        return
    # Check for huntable animals
    if body.has_method("take_hit"):
        has_hit = true
        body.take_hit(ARROW_DAMAGE)
        var sfx: Node = get_node_or_null("/root/SFXManager")
        if sfx and sfx.has_method("play_sfx"):
            sfx.play_sfx("arrow_hit")
        queue_free()


func _stick_in_place() -> void:
    is_stuck = true
    freeze = true
    var sfx: Node = get_node_or_null("/root/SFXManager")
    if sfx and sfx.has_method("play_sfx"):
        sfx.play_sfx("arrow_hit")


func _build_mesh() -> void:
    # Arrow shaft - thin brown stick
    var shaft_mat: StandardMaterial3D = StandardMaterial3D.new()
    shaft_mat.albedo_color = Color(0.45, 0.3, 0.15)
    var shaft_mesh: BoxMesh = BoxMesh.new()
    shaft_mesh.size = Vector3(0.03, 0.03, 0.5)
    var shaft: MeshInstance3D = MeshInstance3D.new()
    shaft.mesh = shaft_mesh
    shaft.material_override = shaft_mat
    add_child(shaft)

    # Arrow head - dark metal triangle (small box, rotated)
    var head_mat: StandardMaterial3D = StandardMaterial3D.new()
    head_mat.albedo_color = Color(0.3, 0.3, 0.35)
    var head_mesh: BoxMesh = BoxMesh.new()
    head_mesh.size = Vector3(0.06, 0.06, 0.08)
    var head: MeshInstance3D = MeshInstance3D.new()
    head.mesh = head_mesh
    head.material_override = head_mat
    head.position = Vector3(0, 0, -0.27)
    head.rotation_degrees.z = 45
    add_child(head)

    # Tail fins - two small feather-colored flaps
    var fin_mat: StandardMaterial3D = StandardMaterial3D.new()
    fin_mat.albedo_color = Color(0.6, 0.55, 0.45)
    var fin_mesh: BoxMesh = BoxMesh.new()
    fin_mesh.size = Vector3(0.06, 0.005, 0.08)

    var fin1: MeshInstance3D = MeshInstance3D.new()
    fin1.mesh = fin_mesh
    fin1.material_override = fin_mat
    fin1.position = Vector3(0, 0, 0.22)
    add_child(fin1)

    var fin2: MeshInstance3D = MeshInstance3D.new()
    fin2.mesh = fin_mesh
    fin2.material_override = fin_mat
    fin2.position = Vector3(0, 0, 0.22)
    fin2.rotation_degrees.z = 90
    add_child(fin2)
```

**Step 2: Commit**

```bash
git add scripts/player/arrow_projectile.gd
git commit -m "feat: add arrow projectile with physics and hit detection"
```

---

### Task 4: Add Bow System Script

**Files:**
- Create: `scripts/player/bow_system.gd`

**Step 1: Create the bow system**

This node is added as a child of the player. It handles:
- Draw/fire input (right-click hold to draw, release to fire)
- Spawning arrow projectiles with initial velocity
- Building the bow visual model when equipped
- Consuming arrows from inventory and durability from equipment

```gdscript
extends Node
class_name BowSystem
## Handles bow draw/fire mechanics, arrow spawning, and bow visuals.

signal arrow_count_changed(count: int)
signal bow_drawn()
signal bow_fired()

const DRAW_TIME: float = 0.5  # Seconds to fully draw
const ARROW_SPEED: float = 40.0  # Initial arrow velocity
const ARROW_LAUNCH_ANGLE: float = 2.0  # Slight upward angle in degrees

var player: CharacterBody3D
var camera: Camera3D
var equipment: Equipment
var inventory: Inventory

# State
var is_drawing: bool = false
var draw_progress: float = 0.0
var bow_model: Node3D

# Visuals
var string_mesh: MeshInstance3D
var string_rest_z: float = 0.0
var string_drawn_z: float = 0.08


func _ready() -> void:
    call_deferred("_setup_references")


func _setup_references() -> void:
    player = get_parent() as CharacterBody3D
    if player:
        camera = player.get_node_or_null("Camera3D")
        equipment = player.get_node_or_null("Equipment")
        inventory = player.get_node_or_null("Inventory")


func _input(event: InputEvent) -> void:
    if not _is_bow_equipped():
        return

    # Block if UI is open
    if player and player.has_method("_is_ui_blocking_input") and player._is_ui_blocking_input():
        return

    # Block while resting
    if player and "is_resting" in player and player.is_resting:
        return

    # Right mouse button to draw/fire
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_RIGHT:
            if event.pressed:
                _start_draw()
            else:
                if is_drawing:
                    _fire()

    # Controller: use_equipped action for draw/fire
    if event.is_action_pressed("use_equipped") and not is_drawing:
        _start_draw()
    elif event.is_action_released("use_equipped") and is_drawing:
        _fire()


func _process(delta: float) -> void:
    if is_drawing:
        draw_progress = minf(draw_progress + delta / DRAW_TIME, 1.0)
        # Animate string pullback
        if string_mesh:
            string_mesh.position.z = lerpf(string_rest_z, string_drawn_z, draw_progress)

    # Cancel draw if bow unequipped mid-draw
    if is_drawing and not _is_bow_equipped():
        _cancel_draw()


func _start_draw() -> void:
    if not _has_arrows():
        var hud: Node = get_tree().get_first_node_in_group("hud")
        if hud and hud.has_method("show_notification"):
            hud.show_notification("No arrows!", Color(1.0, 0.5, 0.5))
        return

    is_drawing = true
    draw_progress = 0.0
    bow_drawn.emit()

    var sfx: Node = get_node_or_null("/root/SFXManager")
    if sfx and sfx.has_method("play_sfx"):
        sfx.play_sfx("bow_draw")


func _fire() -> void:
    if draw_progress < 0.3:
        # Too short a draw, cancel
        _cancel_draw()
        return

    if not _has_arrows():
        _cancel_draw()
        return

    # Consume one arrow
    if inventory:
        inventory.remove_item("arrows", 1)
        arrow_count_changed.emit(inventory.get_item_count("arrows"))

    # Use bow durability
    if equipment:
        equipment.use_durability(1)

    # Spawn arrow
    _spawn_arrow()

    # Play fire sound
    var sfx: Node = get_node_or_null("/root/SFXManager")
    if sfx and sfx.has_method("play_sfx"):
        sfx.play_sfx("bow_fire")

    bow_fired.emit()

    # Reset draw state
    is_drawing = false
    draw_progress = 0.0
    if string_mesh:
        string_mesh.position.z = string_rest_z


func _cancel_draw() -> void:
    is_drawing = false
    draw_progress = 0.0
    if string_mesh:
        string_mesh.position.z = string_rest_z


func _spawn_arrow() -> void:
    if not camera:
        return

    var arrow: ArrowProjectile = ArrowProjectile.new()

    # Spawn slightly in front of camera
    var spawn_pos: Vector3 = camera.global_position + (-camera.global_basis.z) * 1.5
    arrow.global_position = spawn_pos

    # Direction: camera forward with slight upward angle for arc feel
    var forward: Vector3 = -camera.global_basis.z
    var up_adjustment: Vector3 = camera.global_basis.y * tan(deg_to_rad(ARROW_LAUNCH_ANGLE))
    var direction: Vector3 = (forward + up_adjustment).normalized()

    # Scale speed by draw progress (minimum 60% at partial draw)
    var speed_mult: float = lerpf(0.6, 1.0, draw_progress)
    arrow.linear_velocity = direction * ARROW_SPEED * speed_mult

    # Add arrow to scene tree (not as child of player, so it persists independently)
    get_tree().current_scene.add_child(arrow)


func _is_bow_equipped() -> bool:
    return equipment != null and equipment.get_equipped() == "bow"


func _has_arrows() -> bool:
    return inventory != null and inventory.has_item("arrows", 1)


func get_arrow_count() -> int:
    if inventory:
        return inventory.get_item_count("arrows")
    return 0


## Build the procedural bow model. Called by equipment when bow is equipped.
func build_bow_model() -> Node3D:
    if bow_model and is_instance_valid(bow_model):
        bow_model.queue_free()

    bow_model = Node3D.new()
    bow_model.name = "BowModel"

    var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
    wood_mat.albedo_color = Color(0.5, 0.35, 0.18)

    var dark_wood_mat: StandardMaterial3D = StandardMaterial3D.new()
    dark_wood_mat.albedo_color = Color(0.35, 0.22, 0.1)

    # Bow limbs - three segments to approximate a curve
    # Lower limb
    var lower: MeshInstance3D = MeshInstance3D.new()
    var lower_mesh: BoxMesh = BoxMesh.new()
    lower_mesh.size = Vector3(0.04, 0.3, 0.04)
    lower.mesh = lower_mesh
    lower.material_override = wood_mat
    lower.position = Vector3(0, -0.2, 0)
    lower.rotation_degrees.z = -8
    bow_model.add_child(lower)

    # Upper limb
    var upper: MeshInstance3D = MeshInstance3D.new()
    var upper_mesh: BoxMesh = BoxMesh.new()
    upper_mesh.size = Vector3(0.04, 0.3, 0.04)
    upper.mesh = upper_mesh
    upper.material_override = wood_mat
    upper.position = Vector3(0, 0.2, 0)
    upper.rotation_degrees.z = 8
    bow_model.add_child(upper)

    # Grip (center, darker)
    var grip: MeshInstance3D = MeshInstance3D.new()
    var grip_mesh: BoxMesh = BoxMesh.new()
    grip_mesh.size = Vector3(0.05, 0.1, 0.05)
    grip.mesh = grip_mesh
    grip.material_override = dark_wood_mat
    grip.position = Vector3(0, 0, 0)
    bow_model.add_child(grip)

    # String - thin white line
    var string_mat: StandardMaterial3D = StandardMaterial3D.new()
    string_mat.albedo_color = Color(0.85, 0.82, 0.75)
    var s_mesh: BoxMesh = BoxMesh.new()
    s_mesh.size = Vector3(0.008, 0.65, 0.008)
    string_mesh = MeshInstance3D.new()
    string_mesh.mesh = s_mesh
    string_mesh.material_override = string_mat
    string_mesh.position = Vector3(0, 0, string_rest_z)
    bow_model.add_child(string_mesh)

    return bow_model


## Remove bow model when unequipped.
func clear_bow_model() -> void:
    if bow_model and is_instance_valid(bow_model):
        bow_model.queue_free()
        bow_model = null
    string_mesh = null
    _cancel_draw()
```

**Step 2: Commit**

```bash
git add scripts/player/bow_system.gd
git commit -m "feat: add bow system with draw/fire mechanics and bow model"
```

---

### Task 5: Add Animal Hit/Death and Loot Drops

**Files:**
- Modify: `scripts/creatures/ambient_animal_base.gd` (add `take_hit()`, loot drop, death)
- Modify: `scripts/creatures/ambient_bird.gd` (add to group, define loot)
- Modify: `scripts/creatures/ambient_rabbit.gd` (add to group, define loot)

**Step 1: Add `take_hit()` and loot methods to AmbientAnimalBase**

Add at the bottom of `ambient_animal_base.gd` (before the closing of the class, after `_get_random_nearby_position`):

```gdscript
# Loot table (override in subclasses)
var loot_table: Dictionary = {}
var is_dead: bool = false


## Called when hit by an arrow or other weapon.
func take_hit(damage: float) -> void:
    if is_dead:
        return
    is_dead = true

    # Drop loot items on the ground
    _drop_loot()

    # Play death visual - tip over
    if mesh_container:
        var tween: Tween = create_tween()
        tween.tween_property(mesh_container, "rotation_degrees:x", 90.0, 0.3)

    # Play hit sound
    if sfx_manager and sfx_manager.has_method("play_sfx"):
        sfx_manager.play_sfx("arrow_hit")

    # Despawn after brief delay
    var timer: SceneTreeTimer = get_tree().create_timer(1.0)
    timer.timeout.connect(queue_free)


## Drop loot items near the animal's position.
func _drop_loot() -> void:
    # Add items directly to player inventory (simpler than physical drops)
    var player_node: Node = get_tree().get_first_node_in_group("player")
    if not player_node:
        return
    var inv: Node = player_node.get_node_or_null("Inventory")
    if not inv or not inv.has_method("add_item"):
        return

    var hud: Node = get_tree().get_first_node_in_group("hud")
    var loot_msg: String = ""

    for item_type: String in loot_table:
        var amount: int = loot_table[item_type]
        inv.add_item(item_type, amount)
        if loot_msg != "":
            loot_msg += ", "
        loot_msg += "%dx %s" % [amount, item_type.replace("_", " ")]

    if hud and hud.has_method("show_notification") and loot_msg != "":
        hud.show_notification("Hunted: " + loot_msg, Color(0.6, 1.0, 0.6))
```

**Step 2: Add birds and rabbits to "ambient_animal" group and define loot**

In `ambient_bird.gd`, in the `_ready()` or at the top of `_build_mesh()` (which is called from base `_ready`), add group membership. Since `_ready` is in the base class, override or add to the bird's initialization. The simplest approach: add `add_to_group("ambient_animal")` in each subclass's `_build_mesh()` at the top, and set `loot_table`.

In `ambient_bird.gd`, add at the top of `_build_mesh()`:

```gdscript
func _build_mesh() -> void:
    add_to_group("ambient_animal")
    loot_table = {"raw_meat": 1, "feathers": 2}
    # ... existing mesh code ...
```

In `ambient_rabbit.gd`, add at the top of `_build_mesh()`:

```gdscript
func _build_mesh() -> void:
    add_to_group("ambient_animal")
    loot_table = {"raw_meat": 1, "hide": 1}
    # ... existing mesh code ...
```

**Step 3: Commit**

```bash
git add scripts/creatures/ambient_animal_base.gd scripts/creatures/ambient_bird.gd scripts/creatures/ambient_rabbit.gd
git commit -m "feat: add animal hunting - take_hit(), loot drops, death animation"
```

---

### Task 6: Wire Bow System into Player Controller

**Files:**
- Modify: `scripts/player/player_controller.gd` (add BowSystem child node, wire up)

**Step 1: Add BowSystem as child node**

In `player_controller.gd`, in the `_ready()` function (around line 170), add after the existing child node setup:

```gdscript
# Create bow system
var bow_system: BowSystem = BowSystem.new()
bow_system.name = "BowSystem"
add_child(bow_system)
```

**Step 2: Update `_input` to let BowSystem handle right-click when bow equipped**

The BowSystem's `_input` method will handle right-click naturally since it's a child node and Godot propagates input. No changes needed to `_input` in player_controller — the BowSystem checks `_is_bow_equipped()` internally and ignores input when bow isn't equipped.

**Step 3: Commit**

```bash
git add scripts/player/player_controller.gd
git commit -m "feat: wire bow system into player controller"
```

---

### Task 7: Wire Bow Visuals into Equipment

**Files:**
- Modify: `scripts/player/equipment.gd` (build/clear bow model on equip/unequip)

**Step 1: Add bow model management**

In the `_equip_visual()` or equivalent method that creates tool models when equipped, add bow model handling. Find where axe/grappling hook models are created and add parallel logic for the bow.

Look for the method that creates the visual (likely `_create_tool_model` or similar in the equip flow). Add:

```gdscript
# In the equip flow, after existing tool model creation:
if item_type == "bow":
    var bow_system: Node = get_parent().get_node_or_null("BowSystem")
    if bow_system and bow_system.has_method("build_bow_model"):
        var model: Node3D = bow_system.build_bow_model()
        if model:
            # Position at player's side/hand (similar to axe positioning)
            model.position = Vector3(0.3, -0.1, -0.3)
            model.rotation_degrees = Vector3(0, 0, -15)
            _tool_model_parent.add_child(model)
```

And in the unequip flow:

```gdscript
if old_item == "bow":
    var bow_system: Node = get_parent().get_node_or_null("BowSystem")
    if bow_system and bow_system.has_method("clear_bow_model"):
        bow_system.clear_bow_model()
```

NOTE: The exact integration points depend on how `equipment.gd` creates tool models. The implementer must read the equip/unequip methods (around lines 400-600) and find where `_create_stone_axe_model()`, etc. are called to add the bow model in the same pattern.

**Step 2: Commit**

```bash
git add scripts/player/equipment.gd
git commit -m "feat: add bow visual model on equip/unequip"
```

---

### Task 8: Add HUD Arrow Count Display

**Files:**
- Modify: `scripts/ui/hud.gd` (show arrow count when bow equipped, update equipped label hints)

**Step 1: Add arrow count to equipped display**

In `_update_equipped_display()` (around line 339), add a case for the bow:

```gdscript
elif equipped_type == "bow":
    var arrow_count: int = 0
    var player_node: Node = get_tree().get_first_node_in_group("player")
    if player_node:
        var inv: Node = player_node.get_node_or_null("Inventory")
        if inv and inv.has_method("get_item_count"):
            arrow_count = inv.get_item_count("arrows")
    equipped_label.text += " (%d arrows) [R-click aim, %s unequip]" % [arrow_count, unequip_key]
```

Add this after the `fishing_rod` case (line 359) and before the `bark_map` case.

**Step 2: Connect BowSystem's arrow_count_changed signal to refresh the display**

In the HUD's `_ready()` or connection setup, after the equipment signals are connected, also listen for arrow count changes to refresh the display. The simplest approach: in `_update_equipped_display()`, the arrow count is read live each time it's called. The BowSystem emits `arrow_count_changed` which can trigger `_update_equipped_display()`. Wire this in the HUD's `_ready` after finding the player:

```gdscript
var bow: Node = player.get_node_or_null("BowSystem")
if bow and bow.has_signal("arrow_count_changed"):
    bow.arrow_count_changed.connect(func(_count: int) -> void: _update_equipped_display())
```

**Step 3: Commit**

```bash
git add scripts/ui/hud.gd
git commit -m "feat: show arrow count in HUD when bow equipped"
```

---

### Task 9: Add Procedural Bow/Arrow Sound Effects

**Files:**
- Modify: `scripts/core/sfx_manager.gd` (add bow_draw, bow_fire, arrow_hit sounds and cooldowns)

**Step 1: Add cooldown entries**

In `DEFAULT_COOLDOWNS` (around line 15), add:

```gdscript
"bow_draw": 0.3,
"bow_fire": 0.2,
"arrow_hit": 0.15,
```

**Step 2: Add procedural sound generators**

Add three new generator functions after `_generate_bubble_pop_sound()` (line 309):

```gdscript
## Generate a procedural bow draw (creak) sound.
func _generate_bow_draw_sound() -> AudioStreamWAV:
    var sample_rate: int = 22050
    var duration: float = 0.35
    var num_samples: int = int(sample_rate * duration)
    var data: PackedByteArray = PackedByteArray()
    data.resize(num_samples * 2)

    for i: int in range(num_samples):
        var t: float = float(i) / sample_rate
        # Slow rising envelope (creaking tension)
        var envelope: float = minf(t * 6.0, 1.0) * exp(-t * 2.0)
        # Low woody creak (~150Hz with wobble)
        var wobble: float = sin(t * 8.0 * TAU) * 0.15
        var wave: float = sin(t * (150.0 + wobble * 30.0) * TAU) * 0.4
        wave += sin(t * 220.0 * TAU) * 0.2
        # Friction noise
        wave += (randf() * 2.0 - 1.0) * 0.1

        var sample: float = wave * envelope * 0.4
        var sample_int: int = clampi(int(sample * 32767.0), -32768, 32767)
        data[i * 2] = sample_int & 0xFF
        data[i * 2 + 1] = (sample_int >> 8) & 0xFF

    var stream: AudioStreamWAV = AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = sample_rate
    stream.stereo = false
    stream.data = data
    return stream


## Generate a procedural bow fire (twang) sound.
func _generate_bow_fire_sound() -> AudioStreamWAV:
    var sample_rate: int = 22050
    var duration: float = 0.3
    var num_samples: int = int(sample_rate * duration)
    var data: PackedByteArray = PackedByteArray()
    data.resize(num_samples * 2)

    for i: int in range(num_samples):
        var t: float = float(i) / sample_rate
        # Sharp attack, medium decay (string release)
        var envelope: float = exp(-t * 12.0)
        # High twang tone (~400Hz) with harmonics
        var wave: float = sin(t * 400.0 * TAU) * 0.5
        wave += sin(t * 800.0 * TAU) * 0.25
        wave += sin(t * 600.0 * TAU) * 0.15
        # Slight downward pitch bend (string settling)
        var bend: float = 1.0 - t * 1.5
        wave = sin(t * 400.0 * bend * TAU) * 0.4 + wave * 0.6
        # Tiny noise burst at attack
        var attack: float = exp(-t * 60.0)
        wave += (randf() * 2.0 - 1.0) * 0.2 * attack

        var sample: float = wave * envelope * 0.5
        var sample_int: int = clampi(int(sample * 32767.0), -32768, 32767)
        data[i * 2] = sample_int & 0xFF
        data[i * 2 + 1] = (sample_int >> 8) & 0xFF

    var stream: AudioStreamWAV = AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = sample_rate
    stream.stereo = false
    stream.data = data
    return stream


## Generate a procedural arrow hit (thud) sound.
func _generate_arrow_hit_sound() -> AudioStreamWAV:
    var sample_rate: int = 22050
    var duration: float = 0.2
    var num_samples: int = int(sample_rate * duration)
    var data: PackedByteArray = PackedByteArray()
    data.resize(num_samples * 2)

    for i: int in range(num_samples):
        var t: float = float(i) / sample_rate
        # Sharp attack, fast decay (impact)
        var envelope: float = exp(-t * 25.0)
        # Low thud (~100Hz) with a bit of higher impact
        var wave: float = sin(t * 100.0 * TAU) * 0.5
        wave += sin(t * 60.0 * TAU) * 0.3
        # Noise burst for impact texture
        var impact: float = exp(-t * 50.0)
        wave += (randf() * 2.0 - 1.0) * 0.4 * impact

        var sample: float = wave * envelope * 0.6
        var sample_int: int = clampi(int(sample * 32767.0), -32768, 32767)
        data[i * 2] = sample_int & 0xFF
        data[i * 2 + 1] = (sample_int >> 8) & 0xFF

    var stream: AudioStreamWAV = AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = sample_rate
    stream.stereo = false
    stream.data = data
    return stream
```

**Step 3: Register the procedural sounds in `_preload_sounds()`**

After the existing `loaded_sfx["bubble_pop"]` line (line 156), add:

```gdscript
loaded_sfx["bow_draw"] = _generate_bow_draw_sound()
loaded_sfx["bow_fire"] = _generate_bow_fire_sound()
loaded_sfx["arrow_hit"] = _generate_arrow_hit_sound()
```

**Step 4: Commit**

```bash
git add scripts/core/sfx_manager.gd
git commit -m "feat: add procedural bow draw, fire, and arrow hit sounds"
```

---

### Task 10: Add Arrows to Consumable/Inventory Display

**Files:**
- Modify: `scripts/ui/hud.gd` (add "arrows" to recognized items list)
- Modify: `scripts/player/player_controller.gd` (add "arrows" to the consumable items list at line 124)

**Step 1: Add "arrows" to the edible items list**

In `player_controller.gd` around line 124, the list of items in inventory display includes `"osha_root"`. Add `"arrows"` to this array so arrows show in the equipment menu:

```gdscript
"berry", "mushroom", "herb", "fish", "raw_meat", "osha_root", "arrows",
```

**Step 2: Commit**

```bash
git add scripts/player/player_controller.gd scripts/ui/hud.gd
git commit -m "feat: add arrows to inventory display"
```

---

### Task 11: Update DEV_LOG.md

**Files:**
- Modify: `DEV_LOG.md`

**Step 1: Add session entry documenting the bow & arrow system**

Add a new session entry after the latest session, documenting:
- Bow crafting recipe (2 rope + 3 branch, bench, camp level 2)
- Arrow bundle crafting (2 feathers + 4 branch → 20 arrows)
- Physics-based arrow projectile with gravity arc
- Animal hunting (birds drop meat+feathers, rabbits drop meat+hide)
- Procedural bow/arrow sound effects
- HUD arrow count display
- All files created and modified

Update the Next Session section to remove the feathers task and add play-testing the bow.

**Step 2: Commit**

```bash
git add DEV_LOG.md
git commit -m "docs: update DEV_LOG with bow and arrow system"
```

---

## Task Dependency Order

Tasks 1-2 are independent (crafting + equipment config).
Task 3 is independent (arrow projectile).
Task 4 depends on Task 3 (bow system uses ArrowProjectile).
Task 5 is independent (animal hunting).
Task 6 depends on Tasks 4 (wiring bow system into player).
Task 7 depends on Tasks 2, 4 (equipment needs bow slot + bow system).
Task 8 depends on Task 4 (HUD needs BowSystem signal).
Task 9 is independent (sound effects).
Task 10 is independent (inventory display).
Task 11 is last (documentation).

**Parallelizable groups:**
- Group A (independent): Tasks 1, 2, 3, 5, 9, 10
- Group B (after Group A): Tasks 4, 7
- Group C (after Group B): Tasks 6, 8
- Group D (last): Task 11
