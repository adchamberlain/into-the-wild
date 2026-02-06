# Grappling Hook Design Document

## Overview

A craftable climbing tool that allows players to ascend steep cliff faces in MOUNTAIN and ROCKY regions. Unlike rope ladders (placed infrastructure), the grappling hook is an **active traversal tool** - equip it, aim at a cliff, and pull yourself up.

**Design Goal:** Reward exploration of the new MOUNTAIN biome by gating the highest peaks behind a mid-to-late game tool that feels satisfying to use.

---

## Gameplay Design

### Core Mechanic

1. **Equip** the grappling hook (equipment slot, like axe or torch)
2. **Aim** at a climbable cliff face within range
3. **Fire** (R2/right-click) to launch the hook
4. **Ascend** automatically as the rope pulls you up
5. **Dismount** at the top, pushed forward onto the ledge

### When It Works

The grappling hook activates when aiming at:
- A **vertical cliff face** (side of terrain block)
- With a **flat top surface** above it (valid landing zone)
- Within **maximum range** (15 units vertical, 8 units horizontal)
- **Line-of-sight** clear between player and anchor point

### When It Doesn't Work

- Aiming at horizontal surfaces (ground, ceilings)
- Target too far away
- No valid landing zone at top (e.g., cliff continues higher)
- Obstructed path (terrain blocks between player and target)
- Underwater

### Visual Feedback

**Before Firing:**
- Crosshair changes color when aiming at valid target:
  - **Green**: Valid grapple point
  - **Red**: Invalid (too far, no landing, obstructed)
  - **White**: No target (aiming at sky/ground)

**During Ascent:**
- Visible rope stretches from player to anchor point
- Hook visible at anchor
- Player model pulled upward (no walking animation)
- Camera follows smoothly

**On Arrival:**
- Small dust particles at landing
- Hook retracts/disappears
- Player momentum carries forward slightly

---

## Technical Design

### Target Detection System

```
DETECTION ALGORITHM:

1. Cast ray from camera forward (max 20 units)
2. If hit terrain side face:
   a. Get cell coordinates of hit block
   b. Sample height of cell directly above hit point
   c. If top cell is flat (valid landing):
      - Calculate anchor point (top surface center)
      - Verify line-of-sight to anchor
      - Return anchor position
   d. Else: No valid target
3. If hit anything else: No valid target
```

**Key Functions Needed:**
- `_get_grapple_target() -> Dictionary` - Returns `{valid: bool, anchor: Vector3, landing: Vector3}` or `{valid: false}`
- `_is_valid_landing_zone(cell_x, cell_z) -> bool` - Checks if cell is flat enough to stand on
- `_check_line_of_sight(from: Vector3, to: Vector3) -> bool` - Raycast for obstructions

### Anchor Point Calculation

Given a cliff face hit at world position `(hx, hy, hz)`:

```gdscript
# Get the cell above the hit point
var cell_x = floor(hx / cell_size)
var cell_z = floor(hz / cell_size)
var top_height = chunk_manager.get_height_at(cell_x * cell_size, cell_z * cell_size)

# Anchor point is center of top surface
var anchor = Vector3(
    cell_x * cell_size + cell_size / 2,
    top_height,
    cell_z * cell_size + cell_size / 2
)

# Landing position is slightly forward from anchor
var landing = anchor + (player_position - anchor).normalized() * 1.5
landing.y = top_height
```

### Ascent Movement

**Option A: Tween-Based (Recommended)**
- Simple, predictable, no physics edge cases
- Tween player position from current to anchor over `ascent_time`
- Disable gravity and normal movement during ascent
- Use `Tween.TRANS_QUAD` + `EASE_OUT` for satisfying feel

```gdscript
var tween = create_tween()
tween.tween_property(self, "global_position", anchor_point, ascent_time)
tween.tween_callback(_on_grapple_complete)
```

**Option B: Physics Pull**
- More dynamic but harder to tune
- Apply constant force toward anchor
- Risk of oscillation, collision issues

**Recommendation:** Start with tween-based. It matches the game's blocky aesthetic and avoids physics complexity.

### Ascent Speed

| Distance | Time | Feel |
|----------|------|------|
| 5 units | 0.6s | Quick hop |
| 10 units | 1.0s | Satisfying climb |
| 15 units | 1.3s | Dramatic ascent |

Formula: `ascent_time = 0.4 + (distance * 0.06)`

### Collision During Ascent

Two approaches:

**Simple (Recommended):** Disable collision during ascent. The line-of-sight check ensures the path is clear before firing.

**Complex:** Keep collision enabled, abort grapple if player hits something. More realistic but adds edge cases.

### Rope Visual

Use `ImmediateMesh` or `MeshInstance3D` with a thin cylinder:

```gdscript
func _update_rope_visual(from: Vector3, to: Vector3):
    var length = from.distance_to(to)
    var midpoint = (from + to) / 2

    rope_mesh.mesh.height = length
    rope_mesh.global_position = midpoint
    rope_mesh.look_at(to, Vector3.UP)
    rope_mesh.rotate_object_local(Vector3.RIGHT, PI/2)
```

**Rope Properties:**
- Radius: 0.03 units (thin rope)
- Color: Tan/brown (`Color(0.6, 0.5, 0.3)`)
- Material: Unshaded for consistent look

### Hook Visual

Simple blocky hook at anchor point:
- Metal grey color
- 3-4 BoxMesh pieces forming hook shape
- Appears when grapple fires, disappears on retract

---

## Integration with Existing Systems

### Equipment System (`equipment.gd`)

Add to `EQUIPPABLE_ITEMS`:

```gdscript
"grappling_hook": {
    "name": "Grappling Hook",
    "slot": 22,  # Next available slot
    "is_tool": true,
    "tool_type": "grappling_hook",
    "durability": 100,
    "max_durability": 100,
    "effectiveness": 1.0,
    "is_light_source": false,
    "is_placeable": false
}
```

### Player Controller (`player_controller.gd`)

New state and functions:

```gdscript
# State
var is_grappling: bool = false
var grapple_target: Vector3
var grapple_tween: Tween

# Input handling in _physics_process or _input
func _handle_grapple_input():
    if not is_grappling and Input.is_action_just_pressed("use_equipped"):
        var equipped = equipment.get_current_item()
        if equipped and equipped.tool_type == "grappling_hook":
            _try_grapple()

func _try_grapple():
    var target = _get_grapple_target()
    if target.valid:
        _start_grapple(target.anchor, target.landing)

func _start_grapple(anchor: Vector3, landing: Vector3):
    is_grappling = true
    # Disable normal movement
    # Create rope visual
    # Start tween
    # Play sound

func _on_grapple_complete():
    is_grappling = false
    global_position = landing_position
    # Small forward velocity
    # Retract rope visual
    # Play landing sound
```

### Crafting System (`crafting_system.gd`)

New recipe:

```gdscript
{
    "id": "grappling_hook",
    "name": "Grappling Hook",
    "ingredients": {
        "rope": 3,
        "metal_ingot": 2,
        "branch": 1
    },
    "result": "grappling_hook",
    "result_count": 1,
    "requires_bench": true,
    "camp_level_required": 2
}
```

### Chunk Manager (`chunk_manager.gd`)

May need a helper function:

```gdscript
func get_cell_at_world_pos(world_x: float, world_z: float) -> Dictionary:
    var cell_x = floor(world_x / cell_size)
    var cell_z = floor(world_z / cell_size)
    var height = get_height_at(world_x, world_z)
    return {
        "cell_x": cell_x,
        "cell_z": cell_z,
        "height": height,
        "world_center": Vector3(
            cell_x * cell_size + cell_size / 2,
            height,
            cell_z * cell_size + cell_size / 2
        )
    }
```

---

## Crafting & Progression

### Recipe

| Ingredient | Quantity | Source |
|------------|----------|--------|
| Rope | 3 | Crafted from plant fiber |
| Metal Ingot | 2 | Smelted from iron ore |
| Branch | 1 | Trees, ground |

**Requirements:**
- Crafting bench
- Camp Level 2

### Progression Context

| Camp Level | Vertical Traversal Options |
|------------|---------------------------|
| Level 1 | Jump (~1.5 blocks max) |
| Level 2 | Rope ladder (placed), **Grappling hook (active)** |
| Level 3 | Lantern for cave exploration |

The grappling hook becomes available at the same tier as rope ladders but serves a different purpose:
- **Rope Ladder**: Permanent installation for frequently-used routes
- **Grappling Hook**: Exploration tool for first-time ascents, temporary access

### Durability

- **Max Durability**: 100
- **Per Use**: 1 durability
- **Effective Uses**: 100 grapples before breaking

This is generous - climbing is already gated by crafting requirements, no need to make it frustrating.

---

## Sound Design

| Event | Sound | Notes |
|-------|-------|-------|
| Fire hook | `grapple_fire.mp3` | Whoosh + metal clink |
| Hook attach | `grapple_attach.mp3` | Metal impact on stone |
| Ascending | `grapple_ascend.mp3` | Rope tension/creaking (looped) |
| Land | `grapple_land.mp3` | Soft thud + dust |
| Invalid target | `grapple_fail.mp3` | Dull thunk (hook bounces off) |

**File locations:** `assets/audio/sfx/tools/`

---

## UI/UX

### HUD Integration

When grappling hook equipped, show targeting reticle:
- Small crosshair in center of screen
- Color indicates target validity (green/red/white)
- Optional: Show distance to target

### Interaction Prompt

When aiming at valid target:
```
[R2] Grapple
```

When aiming at invalid target:
```
(Too far) or (No landing) or (Obstructed)
```

### Controller Support

| Action | Keyboard | Controller |
|--------|----------|------------|
| Fire grapple | Right-click | R2 |
| Cancel (mid-air) | Escape | Circle |

**Cancel behavior:** If player presses cancel during ascent, abort and fall. Useful if they realize they're going somewhere wrong.

---

## Edge Cases & Constraints

### Handled Edge Cases

1. **Grappling while swimming**: Disabled - must be on land
2. **Grappling into water**: Check landing zone isn't water
3. **Target moves** (impossible with static terrain): N/A
4. **Durability depletes mid-grapple**: Complete current grapple, break after landing
5. **Save/load during grapple**: Abort grapple, place player at starting position

### Range Limits

| Dimension | Limit | Reasoning |
|-----------|-------|-----------|
| Vertical | 15 units | ~10 terrain blocks, covers most mountain cliffs |
| Horizontal | 8 units | Prevents "spider-man" swinging across gaps |
| Total distance | 17 units | Pythagorean limit |

### What You Can't Grapple

- Trees (not terrain)
- Structures (player-built)
- Cave entrances (use door interaction)
- Other players (N/A, single-player)
- Animals (not solid)

---

## Implementation Plan

### Phase 1: Core Mechanic (MVP)
1. Add equipment entry for grappling hook
2. Add crafting recipe
3. Implement target detection (raycast + validation)
4. Implement tween-based ascent
5. Basic rope visual (cylinder mesh)
6. Landing and dismount

### Phase 2: Polish
1. Targeting reticle with color feedback
2. Hook visual at anchor point
3. Sound effects
4. Particle effects (dust on land)
5. Camera smoothing during ascent

### Phase 3: Edge Cases
1. Cancel mid-ascent
2. Water detection
3. Durability integration
4. Save/load handling

---

## Testing Checklist

### Functional Tests
- [ ] Can craft grappling hook at level 2 bench
- [ ] Grapple fires only when aiming at valid cliff
- [ ] Player ascends smoothly to anchor point
- [ ] Player lands on flat surface at top
- [ ] Rope visual appears and disappears correctly
- [ ] Durability decreases per use
- [ ] Tool breaks at 0 durability

### Edge Case Tests
- [ ] Cannot grapple while swimming
- [ ] Cannot grapple to water landing zones
- [ ] Cannot grapple through terrain (LOS check)
- [ ] Cannot grapple beyond max range
- [ ] Cancel mid-ascent works
- [ ] Save/load during grapple handles gracefully

### Performance Tests
- [ ] No frame drops during target detection
- [ ] Rope mesh doesn't cause GC spikes
- [ ] Multiple rapid grapples don't leak resources

### Region Tests
- [ ] Works in MOUNTAIN biome (primary use case)
- [ ] Works in ROCKY biome
- [ ] Works in HILLS biome
- [ ] Works on forest terrain (smaller cliffs)

---

## Future Enhancements (Out of Scope)

These ideas are interesting but not part of the initial implementation:

1. **Swing mechanic**: Grapple to overhang and swing across gaps
2. **Pull objects**: Grapple branches/resources to pull them to you
3. **Upgraded hook**: Longer range, faster ascent, multiple charges
4. **Grapple points**: Special anchor points in specific locations (caves, etc.)
5. **Multiplayer**: Pull other players (if multiplayer added)

---

## Files to Create

| File | Purpose |
|------|---------|
| `scripts/player/grappling_hook.gd` | Core grappling logic, target detection, ascent |
| `scripts/ui/grapple_reticle.gd` | Targeting crosshair UI |

## Files to Modify

| File | Changes |
|------|---------|
| `scripts/player/equipment.gd` | Add grappling_hook to EQUIPPABLE_ITEMS |
| `scripts/player/player_controller.gd` | Integrate grappling state and input |
| `scripts/crafting/crafting_system.gd` | Add grappling_hook recipe |
| `scripts/core/sfx_manager.gd` | Add grapple sound paths |
| `scripts/ui/hud.gd` | Add grapple reticle rendering |

---

## Summary

The grappling hook is a **mid-game exploration tool** that rewards players who've progressed through the smithing chain. It complements rope ladders by providing **spontaneous vertical traversal** rather than placed infrastructure.

**Key design principles:**
1. **Tween-based movement** for reliability and feel
2. **Strict target validation** to prevent exploits
3. **Clear visual feedback** so players understand what's grappleable
4. **Generous durability** since crafting is already the gate

The implementation leverages existing systems (equipment, crafting, terrain height queries) and adds minimal new complexity.
