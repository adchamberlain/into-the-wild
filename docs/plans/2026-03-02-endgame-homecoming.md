# Endgame Homecoming Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add the game's ending — a 4-landmark trail leading home to a cozy Oakland Hills house, with a New Game+ loop.

**Architecture:** Three new world landmark scripts (carved tree, stone cairn, trailhead signpost) spawned by chunk_manager at fixed far-out positions. A transition manager handles the cinematic walk-out and scene change. The Oakland Hills house is a separate scene (`scenes/house/house.tscn`) with its own player controller, interactable objects, and a read-only inventory viewer. GameState autoload carries journey data between scenes.

**Tech Stack:** Godot 4.5, GDScript, BoxMesh procedural art, existing interaction/overlay patterns

---

### Task 1: Add Trail Clue to Explorer's Journal

**Files:**
- Modify: `scripts/ui/journal_ui.gd` (the Day 47 entry, ~line 75-81)

**Step 1: Update the journal's final diary entry**

In `_get_pages()`, modify the Day 47 spread (Spread 6). Change the `right_text` to include a trail hint at the end. The current text ends with Carlston's farewell. Add a postscript that hints at the carved tree on the north ridge.

Change the `right_text` of the Day 47 spread from:

```gdscript
"right_text": "I'm leaving this journal on a pedestal at the bottom, for whoever comes next. Everything I've learned is in these pages — every place worth visiting, every recipe for every tool and structure that made this wilderness feel like home.\n\nThe Carlston Wilderness is a generous place if you're willing to explore it. Every oasis, every cave, every mountain peak has something wonderful waiting. Take your time. Build well. Climb high.\n\nHappy trails.\n\n— M.W. Carlston",
```

To:

```gdscript
"right_text": "I'm leaving this journal on a pedestal at the bottom, for whoever comes next. Everything I've learned is in these pages — every place worth visiting, every recipe for every tool and structure that made this wilderness feel like home.\n\nThe Carlston Wilderness is a generous place if you're willing to explore it. Every oasis, every cave, every mountain peak has something wonderful waiting. Take your time. Build well. Climb high.\n\nHappy trails.\n\n— M.W. Carlston\n\nP.S. — If you ever want to find your way home, I marked the old ranger trail years ago. Start at the carved tree on the north ridge, about 300 paces from camp. You'll know it when you see my initials.",
```

**Step 2: Commit**

```bash
git add scripts/ui/journal_ui.gd
git commit -m "Add trail home clue to Explorer's Journal Day 47 entry"
```

---

### Task 2: Create the Carved Tree Landmark

**Files:**
- Create: `scripts/world/trail_carved_tree.gd`

**Step 1: Write the carved tree script**

Follows the `explorers_journal_pickup.gd` pattern: extends `StaticBody3D`, adds to `"interactable"` group, builds BoxMesh visuals, implements `interact()` and `get_interaction_text()`.

The carved tree is a distinctive, larger-than-normal tree trunk with a flat carved face showing "M.W.C." initials and an arrow. When interacted, shows an overlay (WildernessSign pattern) with the clue text: *"Carved into the bark: M.W.C. An arrow points east. Below it, scratched in smaller letters: 'Follow the ridge east to the stone cairn.'"*

Key implementation details:
- `extends StaticBody3D` (like explorers_journal_pickup.gd)
- `add_to_group("interactable")` in `_ready()`
- Shared static materials for trunk (dark brown), carved face (lighter exposed wood), carved text (dark grooves)
- Trunk: tall BoxMesh (~0.8 x 3.0 x 0.8), darker brown
- Carved face: flat lighter BoxMesh inset on one side (~0.6 x 0.8 x 0.02)
- Arrow carving: thin dark BoxMesh strips forming a simple arrow shape on the face
- `OmniLight3D` with faint warm glow (subtle, to help player spot it)
- `CollisionShape3D` for the trunk
- Overlay UI: `CanvasLayer` with `layer=100`, `PanelContainer` with `StyleBoxFlat` (dark semi-transparent), centered text with `HUD_FONT`
- `interact()` toggles overlay, calls `player.set_resting(true/false)` and HUD `set_overlay_mode()`
- `_input()` watches for `ui_cancel` to close overlay
- Track `var has_been_read: bool = false` for save/load state (but don't gate progression on it)

**Step 2: Commit**

```bash
git add scripts/world/trail_carved_tree.gd
git commit -m "Add carved tree landmark for trail home"
```

---

### Task 3: Create the Stone Cairn Landmark

**Files:**
- Create: `scripts/world/trail_stone_cairn.gd`

**Step 1: Write the stone cairn script**

Same pattern as the carved tree. A stacked-rock cairn (5-6 BoxMesh stones of decreasing size, stacked, slightly offset for natural look). Interacting shows an overlay with: *"A carefully balanced stack of stones. Scratched into the base rock: 'The trail drops into the valley beyond the mountains. Look for the old signpost.' — M.W.C."*

Key implementation details:
- Same `StaticBody3D` + `"interactable"` group pattern
- Shared static materials: base stone (grey), accent stones (lighter grey, brown-grey variety)
- 5-6 stacked BoxMesh stones, each slightly smaller and offset: base (~0.6 x 0.3 x 0.6), then (~0.5 x 0.25 x 0.5), up to a small top stone (~0.2 x 0.15 x 0.2)
- Slight rotation on each stone for natural stacking look
- `OmniLight3D` faint warm glow
- Same overlay/interaction pattern as carved tree

**Step 2: Commit**

```bash
git add scripts/world/trail_stone_cairn.gd
git commit -m "Add stone cairn landmark for trail home"
```

---

### Task 4: Create the Trailhead Signpost Landmark

**Files:**
- Create: `scripts/world/trail_signpost.gd`

**Step 1: Write the trailhead signpost script**

A weathered wooden signpost with two directional arms pointing in opposite directions. One arm reads (in the overlay): *"← Carlston Wilderness"*. The other reads: *"Longridge Road, Oakland, California — 225 miles →"*.

When interacted, shows an overlay with a confirmation prompt: **"Leave the wilderness?"** with two options: **[Yes, head home]** and **[Not yet]**. Choosing "Yes" emits a signal that the transition manager picks up.

Key implementation details:
- Same `StaticBody3D` + `"interactable"` group pattern
- Shared static materials: post (weathered grey-brown), sign arms (lighter wood), text (dark)
- Vertical post: BoxMesh (~0.15 x 2.5 x 0.15)
- Two angled sign arms at top: BoxMesh (~1.2 x 0.3 x 0.05), one pointing back, one pointing forward
- Overlay: `CanvasLayer` with centered panel showing the two sign directions as text, plus a confirmation choice
- Two focusable buttons/labels: `[Yes, head home]` and `[Not yet]`
- Controller support: D-pad up/down to select, A/Enter to confirm
- `signal leave_wilderness_confirmed` — emitted when player confirms "Yes"
- `get_interaction_text()` returns `"Read Signpost"`
- `interact()` freezes player, shows overlay with choice

**Step 2: Commit**

```bash
git add scripts/world/trail_signpost.gd
git commit -m "Add trailhead signpost landmark with leave-wilderness choice"
```

---

### Task 5: Spawn Trail Landmarks in Chunk Manager

**Files:**
- Modify: `scripts/world/chunk_manager.gd`

**Step 1: Add landmark variables and script loading**

Near the existing `wilderness_sign_spawned` / `rock_spire_spawned` vars (~line 78-79, 204), add:

```gdscript
# Trail home landmarks
var carved_tree_script: GDScript
var stone_cairn_script: GDScript
var trail_signpost_script: GDScript

var carved_tree_spawned: bool = false
var stone_cairn_spawned: bool = false
var trail_signpost_spawned: bool = false

# Pre-computed positions (set in _ready)
var carved_tree_position: Vector2 = Vector2.ZERO
var stone_cairn_position: Vector2 = Vector2.ZERO
var trail_signpost_position: Vector2 = Vector2.ZERO
```

**Step 2: Load scripts in `_load_scenes()`**

After the existing `sinkhole_book_script` load (~line 1402), add:

```gdscript
carved_tree_script = load("res://scripts/world/trail_carved_tree.gd")
stone_cairn_script = load("res://scripts/world/trail_stone_cairn.gd")
trail_signpost_script = load("res://scripts/world/trail_signpost.gd")
```

**Step 3: Compute landmark positions in `_ready()`**

After the existing `rock_spire_position` computation (~line 989), add position computation. Positions should be:
- Carved tree: ~300 units north (0, -300) with slight randomized offset from world seed
- Stone cairn: ~400 units NE (280, -280) with slight offset
- Trail signpost: ~500 units NE (350, -350) with slight offset

Snap all positions to `cell_size` grid (like sinkhole center does):

```gdscript
# Trail home landmark positions
var trail_rng: RandomNumberGenerator = RandomNumberGenerator.new()
trail_rng.seed = noise_seed + 7777

carved_tree_position = Vector2(
    roundf((trail_rng.randf_range(-20, 20)) / cell_size) * cell_size,
    roundf((-300.0 + trail_rng.randf_range(-15, 15)) / cell_size) * cell_size
)
stone_cairn_position = Vector2(
    roundf((280.0 + trail_rng.randf_range(-20, 20)) / cell_size) * cell_size,
    roundf((-280.0 + trail_rng.randf_range(-15, 15)) / cell_size) * cell_size
)
trail_signpost_position = Vector2(
    roundf((350.0 + trail_rng.randf_range(-15, 15)) / cell_size) * cell_size,
    roundf((-350.0 + trail_rng.randf_range(-15, 15)) / cell_size) * cell_size
)
```

**Step 4: Add spawn calls in `_load_chunk()`**

After the existing `_spawn_wilderness_sign(...)` call (~line 1973), add:

```gdscript
# Spawn trail home landmarks
if not carved_tree_spawned:
    if carved_tree_position.x >= chunk_min_x and carved_tree_position.x < chunk_max_x and \
       carved_tree_position.y >= chunk_min_z and carved_tree_position.y < chunk_max_z:
        _spawn_trail_carved_tree()

if not stone_cairn_spawned:
    if stone_cairn_position.x >= chunk_min_x and stone_cairn_position.x < chunk_max_x and \
       stone_cairn_position.y >= chunk_min_z and stone_cairn_position.y < chunk_max_z:
        _spawn_trail_stone_cairn()

if not trail_signpost_spawned:
    if trail_signpost_position.x >= chunk_min_x and trail_signpost_position.x < chunk_max_x and \
       trail_signpost_position.y >= chunk_min_z and trail_signpost_position.y < chunk_max_z:
        _spawn_trail_signpost()
```

**Step 5: Write spawn functions**

Follow the `_spawn_wilderness_sign()` pattern. Add these after the existing spawn functions:

```gdscript
func _spawn_trail_carved_tree() -> void:
    if carved_tree_spawned or not carved_tree_script:
        return
    var node: StaticBody3D = StaticBody3D.new()
    node.set_script(carved_tree_script)
    node.name = "TrailCarvedTree"
    var terrain_y: float = get_height_at(carved_tree_position.x, carved_tree_position.y)
    node.position = Vector3(carved_tree_position.x, terrain_y, carved_tree_position.y)
    add_child(node)
    carved_tree_spawned = true
    print("[ChunkManager] Spawned trail carved tree at (%.0f, %.0f)" % [carved_tree_position.x, carved_tree_position.y])


func _spawn_trail_stone_cairn() -> void:
    if stone_cairn_spawned or not stone_cairn_script:
        return
    var node: StaticBody3D = StaticBody3D.new()
    node.set_script(stone_cairn_script)
    node.name = "TrailStoneCairn"
    var terrain_y: float = get_height_at(stone_cairn_position.x, stone_cairn_position.y)
    node.position = Vector3(stone_cairn_position.x, terrain_y, stone_cairn_position.y)
    add_child(node)
    stone_cairn_spawned = true
    print("[ChunkManager] Spawned trail stone cairn at (%.0f, %.0f)" % [stone_cairn_position.x, stone_cairn_position.y])


func _spawn_trail_signpost() -> void:
    if trail_signpost_spawned or not trail_signpost_script:
        return
    var node: StaticBody3D = StaticBody3D.new()
    node.set_script(trail_signpost_script)
    node.name = "TrailSignpost"
    var terrain_y: float = get_height_at(trail_signpost_position.x, trail_signpost_position.y)
    node.position = Vector3(trail_signpost_position.x, terrain_y, trail_signpost_position.y)
    # Face back toward spawn
    node.rotation.y = atan2(-trail_signpost_position.x, -trail_signpost_position.y)
    add_child(node)
    trail_signpost_spawned = true
    print("[ChunkManager] Spawned trail signpost at (%.0f, %.0f)" % [trail_signpost_position.x, trail_signpost_position.y])
```

**Step 6: Suppress vegetation around landmarks**

Extend the existing `is_near_sinkhole()` function (or create a new `is_near_trail_landmark()`) to clear trees/rocks in a ~6 unit radius around each landmark so they're visible and accessible.

**Step 7: Commit**

```bash
git add scripts/world/chunk_manager.gd
git commit -m "Spawn trail home landmarks in chunk manager at far positions"
```

---

### Task 6: Add Journey State to GameState Autoload

**Files:**
- Modify: `scripts/core/game_state.gd`

**Step 1: Add journey data fields to GameState**

These persist across scene transitions (wilderness → house → new wilderness):

```gdscript
# Journey completion data (persists across scene changes)
var journey_completed: bool = false
var journey_inventory: Dictionary = {}  # item_type -> count snapshot
var new_game_plus_items: Array[String] = []  # 5 chosen items for NG+
var is_new_game_plus: bool = false
var pending_house_transition: bool = false
```

Add helper methods:

```gdscript
func save_journey_inventory(inventory_data: Dictionary) -> void:
    journey_inventory = inventory_data.duplicate()
    journey_completed = true


func set_new_game_plus_items(items: Array[String]) -> void:
    new_game_plus_items = items.duplicate()
    is_new_game_plus = true


func consume_new_game_plus_items() -> Array[String]:
    if is_new_game_plus:
        var items: Array[String] = new_game_plus_items.duplicate()
        new_game_plus_items.clear()
        is_new_game_plus = false
        return items
    return []
```

**Step 2: Commit**

```bash
git add scripts/core/game_state.gd
git commit -m "Add journey completion state to GameState autoload"
```

---

### Task 7: Create the Wilderness Transition Manager

**Files:**
- Create: `scripts/core/wilderness_transition.gd`

**Step 1: Write the transition manager**

This script handles the cinematic walk-out sequence when the player confirms leaving at the signpost. It:

1. Listens for the signpost's `leave_wilderness_confirmed` signal
2. Snapshots the player's inventory into GameState
3. Plays the auto-walk + fade-to-black sequence
4. Loads the house scene

```gdscript
extends Node
## Manages the cinematic transition from wilderness to Oakland Hills house.

var _player: Node = null
var _fade_rect: ColorRect = null
var _text_label: Label = null

const HUD_FONT: Font = preload("res://resources/hud_font.tres")


func trigger_transition(player: Node) -> void:
    _player = player

    # Snapshot inventory to GameState
    var game_state: Node = get_node_or_null("/root/GameState")
    if game_state:
        var inventory: Node = player.get_node_or_null("Inventory")
        if inventory and inventory.has_method("get_all_items"):
            game_state.save_journey_inventory(inventory.get_all_items())
        game_state.pending_house_transition = true

    # Disable player input
    if player.has_method("set_resting"):
        player.set_resting(true, self)

    # Hide HUD
    for hud: Node in get_tree().get_nodes_in_group("hud"):
        if hud.has_method("set_overlay_mode"):
            hud.set_overlay_mode(true)

    # Create fade overlay
    _create_fade_overlay()

    # Start the sequence
    _play_transition_sequence()


func _create_fade_overlay() -> void:
    var canvas: CanvasLayer = CanvasLayer.new()
    canvas.layer = 200  # Above everything
    add_child(canvas)

    _fade_rect = ColorRect.new()
    _fade_rect.color = Color(0, 0, 0, 0)  # Start transparent
    _fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
    canvas.add_child(_fade_rect)

    _text_label = Label.new()
    _text_label.text = ""
    _text_label.add_theme_font_override("font", HUD_FONT)
    _text_label.add_theme_font_size_override("font_size", 36)
    _text_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0))
    _text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _text_label.set_anchors_preset(Control.PRESET_FULL_RECT)
    canvas.add_child(_text_label)


func _play_transition_sequence() -> void:
    var tween: Tween = create_tween()

    # Phase 1: Fade wilderness sounds (2s)
    # (MusicManager and AmbientSoundManager fade handled here)
    var music: Node = get_node_or_null("/root/Main/MusicManager")
    if music and music.has_method("fade_out"):
        music.fade_out(2.0)
    var ambient: Node = get_node_or_null("/root/AmbientSoundManager")
    if ambient and ambient.has_method("fade_out"):
        ambient.fade_out(2.0)

    # Phase 2: Fade to black (3s, starting at 1s)
    tween.tween_interval(1.0)
    tween.tween_property(_fade_rect, "color:a", 1.0, 3.0)

    # Phase 3: Show "225 miles later..." text (hold 3s)
    tween.tween_interval(1.0)
    tween.tween_callback(_show_transition_text)
    tween.tween_interval(3.0)

    # Phase 4: Fade text and load house scene
    tween.tween_callback(_load_house_scene)


func _show_transition_text() -> void:
    _text_label.text = "225 miles later..."
    _text_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))


func _load_house_scene() -> void:
    get_tree().change_scene_to_file("res://scenes/house/house.tscn")
```

The transition manager is added as a child of Main (or instantiated by the signpost when needed). The signpost calls `transition_manager.trigger_transition(player)` when the player confirms.

**Alternative approach:** Instead of a separate manager node, the signpost script itself can contain the transition logic inline. This avoids needing to wire up a separate node. The signpost creates the fade overlay, snapshots inventory, and calls `get_tree().change_scene_to_file()`. Choose whichever is cleaner during implementation — if the signpost handles it all, no separate file is needed.

**Step 2: Commit**

```bash
git add scripts/core/wilderness_transition.gd
git commit -m "Add wilderness-to-house transition manager with cinematic fadeout"
```

---

### Task 8: Create the Oakland Hills House Scene

This is the largest task. The house is a separate scene with its own scripts.

**Files:**
- Create: `scripts/house/house_scene.gd` (main house controller)
- Create: `scripts/house/house_player.gd` (simplified player controller for indoor movement)
- Create: `scripts/house/house_interactable.gd` (base for interactable house objects)

**Step 1: Write the house scene controller**

`house_scene.gd` is the root script for the house scene. It:
- Builds the entire house geometry programmatically (BoxMesh, same art style)
- Creates the player spawn point
- Sets up warm indoor lighting
- Creates interactable objects (kettle, sandwich, bookshelves, storage box, front door)
- Fades in from black on load
- Plays no survival mechanics (no hunger, no weather, no HUD)

House layout (all measurements in Godot units, 1 unit ≈ 1 meter):

```
Room dimensions (approximate):
- Total house footprint: ~12 x 10 units
- Living room: 6 x 5 (front left)
- Kitchen: 6 x 5 (back left)
- Dining room: 6 x 10 (right side)
- Ceiling height: 3.0 units
- Wall thickness: 0.15 units
```

Materials (all shared static vars):
- Floor: dark hardwood brown `Color(0.25, 0.15, 0.08)`, roughness 0.7
- Walls: classic white `Color(0.92, 0.90, 0.88)`, roughness 0.9
- Crown molding: slightly off-white `Color(0.88, 0.86, 0.84)`, roughness 0.85
- Window frame: white `Color(0.9, 0.88, 0.86)`, roughness 0.8
- Window glass: light blue tint `Color(0.7, 0.8, 0.9, 0.3)`, transparency enabled
- Furniture wood: medium brown `Color(0.4, 0.25, 0.12)`, roughness 0.75
- Upholstery: muted blue-grey `Color(0.35, 0.4, 0.5)`, roughness 0.9

The house builds all geometry in `_ready()` via helper functions like `_build_floor()`, `_build_walls()`, `_build_living_room()`, `_build_kitchen()`, `_build_dining_room()`, `_build_windows()`, `_build_crown_molding()`.

Each room's contents are built with BoxMesh primitives:
- Couch: several boxes forming seat, back, arms
- Coffee table: flat box on 4 small leg boxes
- Bookshelves: frame box with colored book spine boxes
- Kitchen counter: long box with cabinet doors (colored strips)
- Dining table: flat box on legs, chairs around it
- Chandelier: small boxes hanging from ceiling with OmniLight

**Cat portraits:** Two framed pictures on the living room wall. Each is a thin BoxMesh frame with a colored background, and the cat rendered as simple BoxMesh pixel art:
- Black cat: all-black body boxes, two small yellow eye boxes
- Tuxedo cat: black body with white chest/belly box, two small yellow eye boxes

**Step 2: Write the house player controller**

`house_player.gd` is a stripped-down version of the wilderness player controller. It supports:
- WASD movement (walking speed only, no sprinting)
- Mouse look
- Interaction raycast (same E-key pattern)
- NO jumping, NO sprinting, NO equipment, NO inventory management
- NO HUD (no health/hunger bars)
- Mouse starts visible on scene load for menu feel, captured on first click

**Step 3: Write interactable objects**

`house_interactable.gd` is a simple base for house objects:

```gdscript
extends StaticBody3D

var interaction_text: String = "Interact"
var _overlay_visible: bool = false

func _ready() -> void:
    add_to_group("interactable")

func get_interaction_text() -> String:
    return interaction_text

func interact(player: Node) -> void:
    pass  # Override in subclasses or instances
```

Specific interactables are either subclasses or configured instances:
- **Kettle**: `interaction_text = "Make tea"`, `interact()` plays SFX, shows brief text overlay *"Warm. Familiar."*
- **Sandwich**: `interaction_text = "Eat sandwich"`, same gentle text overlay
- **Bookshelves**: `interaction_text = "Browse books"`, text overlay *"Your old field guides. You smile."*
- **Front door**: `interaction_text = "Open door"`, triggers the New Game+ selection UI (Task 10)
- **Storage box**: `interaction_text = "View wilderness inventory"`, opens read-only inventory viewer (Task 9)

These can all be instances of `house_interactable.gd` with different configurations rather than separate scripts, to keep it simple. The house_scene.gd script sets up each one.

**Step 4: Set up lighting**

- No DirectionalLight3D (no sunlight indoors)
- 4-6 OmniLight3D placed around the house for warm lamp glow:
  - Living room: 2 lights (warm yellow, `Color(1.0, 0.9, 0.7)`, energy 0.8, range 6)
  - Kitchen: 1 light (slightly brighter, energy 1.0)
  - Dining room: 1 light from chandelier position (warm, energy 0.9)
- Window backdrops: simple colored boxes behind the window glass suggesting outdoor light
  - Hills green: `Color(0.3, 0.5, 0.25)`
  - Sky blue: `Color(0.5, 0.65, 0.8)`
  - Distant houses: small tan/brown boxes

**Step 5: Add fade-in on scene load**

In `_ready()`, create a `ColorRect` overlay starting at full black, then tween alpha to 0 over 2 seconds. Play a gentle ambient sound (clock ticking, quiet neighborhood).

**Step 6: Commit**

```bash
git add scripts/house/house_scene.gd scripts/house/house_player.gd scripts/house/house_interactable.gd
git commit -m "Add Oakland Hills house scene with colonial interior and interactables"
```

---

### Task 9: Wilderness Inventory Viewer (Read-Only Storage Box)

**Files:**
- Create: `scripts/house/journey_inventory_ui.gd`

**Step 1: Write the read-only inventory viewer**

A `CanvasLayer` overlay (following WildernessSign pattern) that displays the player's wilderness inventory as a scrollable list. Items shown with name and count, but no transfer/equip buttons.

```gdscript
extends CanvasLayer
## Read-only viewer for the wilderness inventory stored in the house.

const HUD_FONT: Font = preload("res://resources/hud_font.tres")

var is_open: bool = false
var _inventory_data: Dictionary = {}  # item_type -> count


func open(inventory: Dictionary) -> void:
    _inventory_data = inventory
    _build_ui()
    visible = true
    is_open = true


func close() -> void:
    visible = false
    is_open = false
    # Free UI children for clean rebuild
    for child in get_children():
        child.queue_free()
```

The UI layout:
- Dark semi-transparent panel (`Color(0.1, 0.1, 0.12, 0.85)`)
- Title: "W I L D E R N E S S  I N V E N T O R Y" in gold
- Subtitle: "From your journey in the Carlston Wilderness"
- `ScrollContainer` with `VBoxContainer` of item rows
- Each row: `Label` with item display name and "x{count}" in white
- Close hint at bottom: "[Esc] Close"
- Input: `ui_cancel` to close

Pull inventory data from `GameState.journey_inventory`.

**Step 2: Commit**

```bash
git add scripts/house/journey_inventory_ui.gd
git commit -m "Add read-only wilderness inventory viewer for house storage box"
```

---

### Task 10: New Game+ Item Selection UI

**Files:**
- Create: `scripts/house/new_game_plus_ui.gd`

**Step 1: Write the item selection UI**

A `CanvasLayer` overlay that lets the player pick exactly 5 items from their wilderness inventory to carry into a new run.

Layout:
- Dark panel, title: "R E T U R N  T O  T H E  W I L D E R N E S S"
- Subtitle: "Choose 5 items to bring with you"
- Left column: available items (scrollable list from journey_inventory)
- Right column: selected items (up to 5 slots)
- Counter: "3 / 5 selected"
- Item rows are selectable — pressing Enter/A toggles selection
- When 5 are selected, a "Confirm" button appears
- Cancel returns to the house

On confirm:
1. Store the 5 chosen item types in `GameState.new_game_plus_items`
2. Generate a new random world seed
3. Set `GameState.pending_world_seed` and `GameState.is_new_game_plus = true`
4. Fade to black
5. Call `get_tree().change_scene_to_file("res://scenes/main.tscn")`

**Step 2: Commit**

```bash
git add scripts/house/new_game_plus_ui.gd
git commit -m "Add New Game+ item selection UI for returning to wilderness"
```

---

### Task 11: Wire Up New Game+ in Wilderness Startup

**Files:**
- Modify: `scripts/player/player_controller.gd`

**Step 1: Check for New Game+ items on wilderness load**

In the player controller's `_ready()` (or wherever initial inventory is set up), check GameState for NG+ items:

```gdscript
# Check for New Game+ starting items
var game_state: Node = get_node_or_null("/root/GameState")
if game_state and game_state.is_new_game_plus:
    var ng_plus_items: Array[String] = game_state.consume_new_game_plus_items()
    for item_type: String in ng_plus_items:
        inventory.add_item(item_type, 1)
    print("[Player] New Game+ started with %d items" % ng_plus_items.size())
```

This goes after the existing inventory setup but before dev mode checks. The new wilderness is a fresh world (new seed, no save loaded), so inventory starts empty except for these 5 items.

**Step 2: Commit**

```bash
git add scripts/player/player_controller.gd
git commit -m "Add New Game+ starting items from GameState on wilderness load"
```

---

### Task 12: Register House Scene in Project

**Files:**
- Create: `scenes/house/house.tscn` (minimal scene file, or generate programmatically)
- Modify: `project.godot` (only if needed for scene registration — likely not needed since we use `change_scene_to_file`)

**Step 1: Create the house scene file**

The house scene needs a minimal `.tscn` that the house_scene.gd script attaches to. It can be as simple as a `Node3D` root with the script attached, plus a `Camera3D` and basic `WorldEnvironment`:

```
[gd_scene format=3]

[node name="House" type="Node3D"]
script = ExtResource("res://scripts/house/house_scene.gd")
```

Or build the scene fully in code from `house_scene.gd`'s `_ready()` — the root node is a `Node3D` with the script, and everything else (camera, lights, geometry, player) is added as children programmatically.

**Step 2: Verify scene transition works**

Test: from the signpost in wilderness, confirm "leave", watch the fade, verify house scene loads with fade-in, walk around, interact with objects.

**Step 3: Commit**

```bash
git add scenes/house/house.tscn
git commit -m "Add house scene file for Oakland Hills interior"
```

---

### Task 13: Integration Testing and Polish

**Step 1: Test the full loop**

1. Start a new game, progress to the sinkhole, read the journal (verify trail clue text)
2. Navigate to carved tree (~300 north), interact, read clue
3. Navigate to stone cairn (~400 NE), interact, read clue
4. Navigate to trail signpost (~500 NE), interact, confirm leave
5. Watch transition sequence (fade, text, house load)
6. Explore house — interact with kettle, sandwich, bookshelves, cat portraits
7. Open wilderness storage box — verify full inventory is there, read-only
8. Interact with front door — select 5 items, confirm
9. Verify new wilderness loads with those 5 items in inventory
10. Verify trail landmarks exist in new world (new positions)

**Step 2: Polish and fix issues**

- Adjust landmark visibility (glow intensity, vegetation clearing radius)
- Tune transition timing (fade duration, text hold time)
- Ensure house lighting feels warm and cozy
- Verify controller support throughout
- Check that quitting from house pause menu works cleanly

**Step 3: Final commit**

```bash
git add -A
git commit -m "Polish endgame homecoming: testing fixes and visual tuning"
```

---

## Task Dependency Summary

```
Task 1 (journal clue) ──────────────────────────────┐
Task 2 (carved tree) ───────┐                        │
Task 3 (stone cairn) ───────┤                        │
Task 4 (signpost) ──────────┤── Task 5 (chunk mgr) ──┤
Task 6 (GameState) ─────────┤                        ├── Task 13 (integration)
Task 7 (transition mgr) ────┤                        │
Task 8 (house scene) ───────┤── Task 12 (scene file)─┤
Task 9 (inventory viewer) ──┤                        │
Task 10 (NG+ UI) ───────────┤── Task 11 (NG+ wire) ──┘
```

Tasks 1-4 and 6 can be built in parallel. Task 5 depends on 2-4. Tasks 8-10 can be built in parallel. Task 11 depends on 6 and 10. Task 12 depends on 8. Task 13 depends on everything.
