# Into the Wild - Development Log

## Session 1 - Phase 1 Complete (2026-01-19)

### What Was Built

**Phase 1: Walking Around** - Complete

#### Project Structure
```
into-the-wild/
├── project.godot              # Godot 4.5 project config
├── icon.svg                   # Simple tree icon
├── assets/                    # Empty folders for models, textures, audio, ui
├── scenes/
│   ├── main.tscn              # Main game scene (entry point)
│   ├── player/player.tscn     # First-person player with camera
│   ├── world/world.tscn       # World container with terrain
│   └── ui/hud.tscn            # Time display HUD
├── scripts/
│   ├── player/player_controller.gd   # Movement, mouse look, jump, sprint
│   ├── world/terrain_generator.gd    # Procedural terrain with hills
│   ├── world/time_manager.gd         # Day/night cycle (20 min game days)
│   ├── world/environment_manager.gd  # Dynamic sky/lighting
│   ├── core/game_manager.gd          # Global game state (placeholder)
│   └── ui/hud.gd                     # Time display
└── data/                      # Empty, ready for JSON configs
```

#### Features Implemented

1. **Player Controller** (`scripts/player/player_controller.gd`)
   - First-person camera at eye height (1.6m)
   - WASD movement using physical key detection (Mac compatible)
   - Mouse look with pitch clamping (-89 to +89 degrees)
   - Jumping (Space) and sprinting (Shift)
   - Mouse capture/release with Escape key
   - Walk speed: 5 units/sec, Sprint speed: 8 units/sec

2. **Terrain** (`scripts/world/terrain_generator.gd`)
   - 100x100 unit procedural terrain using FastNoiseLite
   - Hills generated with simplex noise
   - Flattened area at center (15 unit radius) for campsite
   - Visual only - collision disabled (uses simple floor instead)

3. **Simple Floor** (in `main.tscn`)
   - 200x200 unit flat collision surface
   - Green grass color
   - Placeholder rocks and trees for visual reference

4. **Day/Night Cycle** (`scripts/world/time_manager.gd`)
   - 20 real minutes = 1 game day
   - 6 time periods: Dawn, Morning, Afternoon, Evening, Dusk, Night
   - Signals emitted on time/period changes

5. **Dynamic Environment** (`scripts/world/environment_manager.gd`)
   - Procedural sky that changes color with time
   - Sun position follows time of day
   - Ambient lighting adjusts automatically

6. **HUD** (`scripts/ui/hud.gd`)
   - Time display in top-right corner
   - Shows current time (12-hour format) and period name

#### Controls
- **WASD** - Move (forward/back/strafe)
- **Mouse** - Look around
- **Space** - Jump
- **Shift** - Sprint (hold while moving)
- **Escape** - Release/capture mouse cursor

#### Known Issues / Notes
- Terrain collision disabled due to overlap with floor causing player to get stuck
- Will need proper terrain collision when we remove the simple floor
- Godot 4.5 requires explicit type annotations (no Variant inference)

---

## Next Session: Phase 2 - Gathering

### Planned Tasks
1. Resource data structure - Define resource types in `resources.json`
2. Resource node scene - Harvestable objects (branches, stones, berries)
3. Interaction system - Raycast-based "press E to interact"
4. Basic inventory - Array-based with add/remove/stack
5. Inventory UI - Simple list display
6. Resource spawning - Place nodes in world

### Reference
See `into-the-wild-game-spec.md` for full game specification.
