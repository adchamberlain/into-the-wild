# Into the Wild - Development Log

## Session 1 - Phase 1: Walking Around (2026-01-19)

**Core Systems**: Player controller (WASD, mouse look, jump, sprint), procedural terrain with FastNoiseLite, day/night cycle (20 min = 1 game day), dynamic sky/lighting, basic HUD with time display.

**Files**: `player_controller.gd`, `terrain_generator.gd`, `time_manager.gd`, `environment_manager.gd`, `hud.gd`

---

## Session 2 - Phases 2-4: Gathering, Survival, Crafting (2026-01-19)

**Resource System**: Harvestable nodes (branches, rocks, berries), interaction raycast, tool requirements, multi-chop trees.

**Inventory & Stats**: Dictionary-based storage, health/hunger with signals, hunger depletion (disabled for testing).

**Crafting**: 5 recipes (stone axe, torch, campfire kit, rope, berry pouch), crafting UI with C key.

**Equipment**: Slots 1-4, torch light, axe tool usage, placeable items.

**Files**: `resource_node.gd`, `inventory.gd`, `player_stats.gd`, `crafting_system.gd`, `crafting_ui.gd`, `equipment.gd`

---

## Session 3 - Terrain Collision (2026-01-24)

Fixed terrain and object collision. Markers converted to StaticBody3D, terrain uses HeightMapShape3D, player spawns at y=5.

---

## Session 4 - Phase 5: Campsite Building (2026-01-24)

**Structures**: Fire pit (warmth, light), shelter (weather protection, rest), storage container (20 slots).

**Placement System**: Grid snapping, collision validation, green/red preview.

**Campsite Manager**: Tracks structures, level progression (1-3).

**Files**: `structure_base.gd`, `structure_fire_pit.gd`, `structure_shelter.gd`, `structure_storage.gd`, `placement_system.gd`, `campsite_manager.gd`

---

## Session 5 - Phase 6: Weather & Survival (2026-01-24)

**Weather System**: 6 types (Clear, Rain, Storm, Fog, Heat Wave, Cold Snap), damage effects, visual overlays.

**Config Menu** (Tab key): Toggles for hunger/health/weather damage, day length slider.

**Equipment Menu** (I key): Shows all slots with counts.

**Files**: `weather_manager.gd`, `config_menu.gd`, `equipment_menu.gd`

---

## Session 6 - Save/Load & Resources (2026-01-25)

**Save System**: JSON to `user://saves/save.json` - player state, inventory, time, weather, structures.

**Resource Manager**: Respawning after 6 game hours, trees use secondary drops (wood + branches).

**Shelter Rest**: E to rest, sleeping at night skips to dawn with full heal.

**Storage UI**: Two-panel transfer interface.

**Fire Pit Menu**: Warm up, cook food, add fuel (1 wood = 1 day burn time).

**Files**: `save_load.gd`, `resource_manager.gd`, `storage_ui.gd`, `fire_menu.gd`

---

## Session 7 - High Priority Features (2026-01-25)

**Tool Durability**: Axe 150, fishing rod 50. Durability bar in HUD.

**Fishing**: Multi-step mechanic (cast, wait, catch), 3 fishing spots.

**New Resources**: Mushrooms (10), herbs (8) - food and crafting.

**Crafting Bench**: Placeable workbench, opens crafting UI.

**New Recipes**: Fishing rod, healing salve (+30 health), crafting bench kit.

---

## Session 8 - Visual Polish (2026-01-31)

**Weather Particles**: Rain (600), storm (1200), snow (400), dust/fog (150). GPU-accelerated.

**Night Sky**: 800 stars, moon with arc path, weather affects visibility.

**Fishing Visuals**: Organic ponds, swimming fish, first-person rod model, catch animation.

**Blocky Aesthetic**: All meshes converted to BoxMesh for Minecraft style.

**Background Music**: 12 ambient tracks with shuffle, crossfade, config controls.

**Files**: `weather_particles.gd`, `music_manager.gd`, `ATTRIBUTIONS.md`

---

## Session 9 - Terrain & Tools (2026-01-31)

**Blocky Terrain**: Cell-based (3x3), height quantization (0.5 steps), vertical cliffs.

**Procedural Forest**: Noise-based density, ~80-120 trees, random rotation/scale.

**First-Person Axe**: Visible model, swing animation with wind-up/chop.

---

## Session 10 - Forest Biome (2026-01-31)

**Tree Types**: Small oak (60%), big oak (30%), birch (10%) with layered canopies.

**Terrain Colors**: Grass tops (green), dirt sides (brown), grass sod edges.

**Ground Decorations**: 250 grass tufts, 70 flowers (red/yellow).

**Natural Pond**: Single 10x8 pond with terrain depression.

**Files**: `big_tree_resource.tscn`, `birch_tree_resource.tscn`

---

## Session 11 - Infinite World (2026-01-31)

**Chunk System**: 16x16 cells per chunk, render distance 3, progressive loading.

**TerrainChunk**: Self-contained mesh, collision, trees, decorations.

**ChunkManager**: Load/unload around player, shared materials and noise.

**Files**: `terrain_chunk.gd`, `chunk_manager.gd`

---

## Sessions 12-19 - Bug Fixes & Polish (2026-01-31)

- **Coordinates Display**: HUD shows X/Y/Z, configurable toggle.
- **Tree Spawn Fix**: Snapped noise sampling for consistent heights.
- **Berry Bush**: Green bush with 7 red berries, berries disappear on harvest.
- **Resource Height Fix**: Auto-adjust Y to sit on terrain surface.
- **Tree Floating Fix**: Disabled terrain adjustment for chunk-spawned trees.
- **Random Resources**: Branches, rocks, berries spawn procedurally in chunks.
- **Terrain Colors**: Vibrant grass green, dark soil brown.

**Files**: `berry_bush.gd`, `berry_bush.tscn`, `branch.tscn`, `rock.tscn`

---

## Session 20 - Swimming (2026-01-31)

**Swimming Mechanics**: Sink slowly, space to rise, jump out at edges.

**Underwater Effect**: Blue tint overlay.

**Water Rendering**: Flat plane surface, Area3D detection.

**Pond Depression**: Floor at y=-2.5, 8 unit radius bowl.

---

## Session 21 - Tiered Crafting (2026-01-31)

**Basic (Hand)**: Stone axe, torch, campfire kit, rope, crafting bench kit.

**Advanced (Bench)**: Shelter kit, storage box, fishing rod, healing salve, berry pouch.

UI shows "(Requires Bench)" when not at bench.

---

## Sessions 22-23 - Collision & World Floor (2026-01-31)

**Box Collision**: Each terrain cell has BoxShape3D, must jump to climb blocks.

**World Floor**: Impenetrable plane at y=-100 prevents fall-through.

**Jump Height**: 5.5 velocity (~1.5 blocks max).

---

## Session 24 - HUD Readability (2026-01-31)

**Monospace Font**: SF Mono with fallbacks.

**Semi-Transparent Panels**: Dark backgrounds (75-80% opacity) behind all text.

**Standardized Sizes**: Time 36px, labels 24px, coordinates 20px.

**Files**: `hud_font.tres`

---

## Session 25 - Campsite Progression (2026-02-01)

**Level Requirements**:
- Level 1: Survival Camp (starting)
- Level 2: Fire pit + Shelter + Crafting bench + Drying rack + Fishing rod
- Level 3: Canvas tent + Storage + Herb garden + 6 structures + 3 days at Level 2

**New Structures**:
- Drying Rack: Food preservation
- Herb Garden: Passive herb production
- Canvas Tent: Better weather protection
- Log Cabin: Walkable interior with bed (full restore) and kitchen (5 advanced recipes)

**Celebration UI**: Animated panel on level-up with unlocks list.

**Files**: `structure_drying_rack.gd`, `structure_garden.gd`, `structure_canvas_tent.gd`, `structure_cabin.gd`, `cabin_bed.gd`, `cabin_kitchen.gd`

---

## Session 26 - Pause Menu & Polish (2026-01-31)

**Pause Menu**: Escape key toggles, freezes game tree, Resume/Quit buttons. Uses SF Mono font and consistent styling with HUD (gold title, dark panel).

**Stone Axe Fix**: Redesigned geometry and animation:
- Idle: Vertical with 18° clockwise tilt for natural right-handed grip
- Head extends toward target (-Z) so blade hits first when swinging
- Swing animation: wind up tilts head back, swing brings head forward into target

**UI Guidelines**: Added font and styling guidelines to CLAUDE.md.

**Files**: `pause_menu.tscn`, `equipment.gd`, `CLAUDE.md`

---

## Session 27 - Performance & UI Polish (2026-01-31)

**Performance Optimization**:
- VSync + 60 FPS cap in project settings
- HUD throttling: 10 updates/sec instead of every frame
- Raycast throttling: 10 checks/sec for interaction detection
- Disabled SSIL and glow (major GPU drains)
- Reduced star count: 800 → 200
- Reduced render distance: 3 → 2 chunks (49 → 25 chunks)
- Cached camera reference to avoid per-frame lookups
- Throttled weather fire checks, respawn checks, placement validation

**Axe Visibility Fix**: Moved axe further from camera (Z: -0.5 → -0.7) to prevent near-plane clipping. Added tween tracking to prevent animation conflicts.

**UI Improvements**:
- Interaction prompt: Added semi-transparent background panel
- Font consistency: Applied SF Mono (hud_font.tres) to all UI elements
  - storage_ui.tscn: Added font to 6 labels
  - Dynamic labels in storage_ui.gd, equipment_menu.gd, crafting_ui.gd

**Crafting Fix**: Advanced recipes now only appear when at crafting bench. Pressing C away from bench shows only basic recipes (Stone Axe, Torch, Campfire Kit, Rope, Crafting Bench Kit). Must interact with crafting bench to see/craft advanced items.

**Files**: `project.godot`, `hud.gd`, `hud.tscn`, `player_controller.gd`, `environment_manager.gd`, `chunk_manager.gd`, `weather_manager.gd`, `resource_manager.gd`, `placement_system.gd`, `campsite_manager.gd`, `equipment.gd`, `storage_ui.tscn`, `storage_ui.gd`, `equipment_menu.gd`, `crafting_ui.gd`

---

## Session 28 - UI Bug Fixes (2026-01-31)

**Fishing Prompt Fix**: "Cast Line" prompt only shows when fishing rod is equipped. Previously showed with any tool (e.g., axe) near water.

**Interaction Text Fix**: Removed duplicate `[E]` prefix from fishing spot - HUD already adds it. Fixed "[E] [E] Cast Line" display bug.

**Empty Prompt Handling**: HUD now hides interaction prompt when text is empty (e.g., near water without fishing rod).

**Notification Styling**: Updated notification panel to match project UI standards:
- Background: `Color(0.1, 0.1, 0.12, 0.8)`
- Corner radius: 10px
- Content margins: 16-20px

**Files**: `fishing_spot.gd`, `hud.gd`, `hud.tscn`

---

## Session 29 - DualSense Controller Support (2026-02-01)

**Full PlayStation DualSense controller support** enabling gamepad play alongside existing keyboard/mouse controls.

**Input Mappings** (project.godot):
- Left Stick: Movement (WASD equivalent)
- Right Stick: Camera look (mouse look equivalent)
- Cross (×): Jump, swim up, UI accept
- Circle (○): Unequip, UI cancel/back
- Square (□): Interact
- Triangle (△): Eat food/use healing items
- R2 Trigger: Use equipped item (place, fish, chop)
- L3 (Left Stick Click): Sprint
- L1/R1: Cycle through equipment slots
- Options: Pause menu
- Touchpad: Open crafting menu
- Create: Open inventory/equipment menu
- D-pad + Left Stick: UI navigation

**New Input Actions**: `look_up`, `look_down`, `look_left`, `look_right`, `eat`, `use_equipped`, `unequip`, `open_crafting`, `open_inventory`, `pause`, `next_slot`, `prev_slot`, `ui_up`, `ui_down`, `ui_left`, `ui_right`, `ui_accept`

**InputManager Singleton** (`scripts/systems/input_manager.gd`):
- AutoLoad singleton for global access
- Tracks current input device (keyboard/mouse vs controller)
- Emits `input_device_changed` signal when switching devices
- Provides button prompt text based on device (e.g., "E" vs "□")
- PlayStation button symbol support (×, ○, □, △, R2, L1, etc.)

**Player Controller Updates**:
- Right stick camera control with configurable sensitivity
- Analog movement using action strengths (supports partial stick input)
- Unified `_get_movement_input()` function for both input methods
- Action-based input for jump, sprint, interact, eat, use equipped

**Equipment System Updates**:
- L1/R1 cycling through available equipment slots
- Smart cycling: Only cycles through items player actually has
- Maintains current slot position for intuitive cycling

**UI Updates**:
- Dynamic button prompts that change based on input device
- HUD interaction prompts show controller symbols when using gamepad
- Equipment display shows controller hints (R2 place, ○ unequip)
- Celebration prompts update ("Press any button" vs "Press any key")
- Menus close with Circle button (ui_cancel)
- Pause menu works with Options button

**Files Modified**:
- `project.godot` - Input mappings and AutoLoad registration
- `scripts/systems/input_manager.gd` - NEW: Input device tracking singleton
- `scripts/player/player_controller.gd` - Controller movement and camera
- `scripts/player/equipment.gd` - L1/R1 slot cycling
- `scripts/ui/hud.gd` - Dynamic button prompts
- `scripts/ui/pause_menu.gd` - Controller pause toggle
- `scripts/ui/crafting_ui.gd` - Controller menu toggle
- `scripts/ui/equipment_menu.gd` - Controller menu toggle

---

## Session 30 - Credits & README Update (2026-02-01)

**README Overhaul**: Comprehensive update reflecting all implemented features:
- Infinite procedural world with chunk system
- Full campsite progression (Levels 1-3) with 8 structures
- DualSense controller support with PlayStation button prompts
- Tiered crafting (basic vs advanced recipes)
- Swimming, weather particles, ambient music
- Added Credits section with author info

**In-Game Credits Screen**: Added to pause menu:
- Credits button between Resume and Quit
- Dedicated credits panel showing:
  - Game title
  - Author: Andrew Chamberlain, Ph.D.
  - Website: andrewchamberlain.com
  - Music credits (Valdis Story)
- Back button and ESC support to return to pause menu

**Files Modified**: `README.md`, `scenes/ui/pause_menu.tscn`, `scripts/ui/pause_menu.gd`

---

## Session 31 - Multiple Save Slots (2026-02-01)

**Save Slot System**: Upgraded from single save file to 3 save slots with selection UI.

**Save/Load Changes** (`scripts/core/save_load.gd`):
- Added `NUM_SLOTS: int = 3` constant
- New methods: `save_game_slot(slot)`, `load_game_slot(slot)`, `has_save_slot(slot)`, `delete_save_slot(slot)`
- Added `get_slot_info(slot)` returns metadata: empty status, campsite level, formatted timestamp
- Added `get_all_slots_info()` for UI population
- Updated signals to include slot number: `game_saved(filepath, slot)`, `game_loaded(filepath, slot)`
- Legacy `save_game()`/`load_game()` wrappers use slot 1 for backward compatibility
- Slot files: `save_slot_1.json`, `save_slot_2.json`, `save_slot_3.json`

**Config Menu Updates** (`scripts/ui/config_menu.gd`):
- Programmatically created slot selection panel matching existing UI style
- Save/Load buttons now show slot selection instead of immediate action
- Slot buttons display: "Slot 1: Empty" or "Slot 1: Level 2 Camp - Feb 1, 12:30 PM"
- Empty slots disabled for load (greyed out)
- Cancel button returns to main config menu
- ESC key also closes slot panel
- Status messages show slot number: "Saved to Slot 2!", "Loaded Slot 3!"

**UI Flow**:
- Press K or click Save → Slot selection panel appears
- Select any slot → Game saves, notification shows slot number
- Press L or click Load → Slot selection (empty slots disabled)
- Select occupied slot → Game loads, notification shows slot number

**Campsite Level Bug Fix**: Fixed campsite level not updating after loading:
- Bug: `has_crafted_fishing_rod` was not saved/loaded, so Level 2 requirements failed after load
- Now saves: `has_crafted_fishing_rod`, `days_at_level_2`, `level_2_start_day`
- Added `_verify_crafting_flags_from_inventory()` for backward compatibility with old saves
- After loading, checks player inventory for Fishing Rod/Stone Axe and sets flags accordingly
- Calls `_check_level_progression()` after load to verify/update campsite level

**Controller Placement Fix**: Fixed structure placement not working with controller:
- `placement_system.gd` only handled keyboard input (KEY_R) for confirming placement
- Added action-based input handling for `use_equipped` (R2) to confirm placement
- Added `unequip` (Circle) to cancel placement

**Controller Unequip Fix**: Fixed Circle button not unequipping items:
- `pause_menu.gd` was intercepting `ui_cancel` (Circle) even when not paused
- This consumed the input before Equipment could handle the `unequip` action
- Fixed by only responding to `ui_cancel` when pause menu is already open

**D-Pad Menu Navigation**: Added D-pad support for crafting and equipment menus:
- Crafting menu: D-pad up/down to navigate recipes, Cross (X) to craft
- Equipment menu: D-pad up/down to navigate items, Cross (X) to equip
- Visual highlight shows currently focused item
- First item focused when menu opens

**Files Modified**: `scripts/core/save_load.gd`, `scripts/ui/config_menu.gd`, `scripts/ui/hud.gd`, `scripts/campsite/placement_system.gd`, `scripts/ui/pause_menu.gd`, `scripts/ui/crafting_ui.gd`, `scripts/ui/equipment_menu.gd`

---

## Session 32 - Environment Improvements (2026-02-01)

**Multiple Water Pools**: World now generates multiple ponds spread across the landscape:
- 5 ponds total (configurable via `pond_count`)
- First pond always near campsite at (15, 12) for reliable fishing access
- Additional ponds placed randomly with 60-unit minimum spacing
- Ponds must be at least 25 units from campsite
- Each pond gets terrain depression and fishing spot when chunk loads
- Deterministic placement (same seed = same pond locations)

**Rocks Near Water**: Rocks now spawn primarily near pond shorelines:
- High density within 15 units of pond edges (8x base density at water's edge)
- Density tapers off with distance from water
- Very rare rocks elsewhere (10% of base density)
- Creates natural shoreline rock formations around all water features

**Code Refactoring**:
- `pond_center` single variable replaced with `pond_locations: Array[Vector2]`
- New helper functions: `get_distance_to_nearest_pond()`, `is_near_any_pond()`
- Tree, resource, and decoration spawning updated to check all ponds
- Fishing spots spawned dynamically as chunks containing ponds load

**Files Modified**: `scripts/world/chunk_manager.gd`, `scripts/world/terrain_chunk.gd`

---

## Session 33 - Terrain Variety (2026-02-01)

**Region System**: World now has 4 distinct terrain types with unique characteristics:

**Region Types** (determined by low-frequency noise at 0.008):
- **MEADOW** (noise < -0.3): Gentle rolling terrain, lighter vibrant green grass
- **FOREST** (noise -0.3 to 0.2): Dense trees, default dark green (previous terrain)
- **HILLS** (noise 0.2 to 0.5): Dramatic elevation changes with detail noise
- **ROCKY** (noise > 0.5): Jagged blocky cliffs, grey stone surface

**Height Generation by Region**:
| Region | Height Scale | Height Step | Character |
|--------|-------------|-------------|-----------|
| MEADOW | 2.0 | 0.5 | Gentle rolling terrain |
| FOREST | 5.0 | 1.0 | Current default |
| HILLS | 12.0 | 1.5 | Dramatic elevation (up to ~15 units) |
| ROCKY | 8.0 | 2.0 | Jagged, blocky cliffs |

Hills also get additional detail noise (+3 units variation) for more interesting terrain.

**Surface Colors by Region**:
| Region | Grass Color | Dirt Color |
|--------|------------|------------|
| MEADOW | Lighter green (0.35, 0.58, 0.20) | Light brown (0.45, 0.30, 0.18) |
| FOREST | Dark green (0.28, 0.52, 0.15) | Brown (0.40, 0.26, 0.14) |
| HILLS | Medium green (0.32, 0.48, 0.18) | Medium brown (0.42, 0.28, 0.16) |
| ROCKY | Grey stone (0.45, 0.42, 0.38) | Dark grey (0.35, 0.33, 0.30) |

**Vegetation Spawning by Region**:
| Region | Trees | Rocks | Berries/Herbs |
|--------|-------|-------|---------------|
| MEADOW | 10% | 30% | 200% |
| FOREST | 150% | 100% | 100% |
| HILLS | 60% | 150% | 80% |
| ROCKY | 20% | 500% | 20% |

Rocky regions provide foundation for future cave system.

**New Noise Generators**:
- `region_noise`: Frequency 0.008 for ~125 unit regions
- `detail_noise`: Frequency 0.04 for hills terrain variation

**New ChunkManager API**:
- `get_region_at(x, z)` → RegionType
- `get_region_colors(region)` → Dictionary with grass/dirt colors
- `get_vegetation_multiplier(region, type)` → float multiplier

**Files Modified**: `scripts/world/chunk_manager.gd`, `scripts/world/terrain_chunk.gd`

---

## Session 34 - Enhanced Water Features (2026-02-01)

**Complete water system overhaul** with varied ponds, lakes, rivers, and ambient sound infrastructure.

### Water Body System Redesign

**New Data Structures** (`chunk_manager.gd`):
- `WaterBodyType` enum: POND, LAKE, RIVER
- `water_bodies: Array[Dictionary]` replaces simple `pond_locations` array
- Each water body stores: type, center, radius, depth
- `rivers: Array[Dictionary]` stores river paths with fishing pools

### Region-Specific Ponds

| Region | Radius Range | Depth |
|--------|-------------|-------|
| MEADOW | 10-14 | 2.5 |
| FOREST | 6-10 | 2.5 |
| HILLS | 5-8 | 3.0 |
| ROCKY | 4-6 | 3.5 |

### Lake Generation (NEW)

- 2-3 large lakes per world (20-30 unit radius)
- MEADOW regions only (flat terrain)
- 80+ unit spacing between lakes
- 40+ unit spacing from ponds
- Must be 50+ units from spawn
- 8 fish per lake (vs 5 for ponds)

### River Generation (NEW)

- 2-3 rivers per world
- Source points in HILLS/ROCKY regions (high terrain)
- Path follows terrain gradient downhill toward MEADOW
- Natural curved paths with perpendicular offsets
- Base width: 5 units, fishing pool width: 8 units
- Depth: 2.0 units with sloped cross-section profile
- Fishing pools placed every 40 units along river

**River Path Algorithm**:
1. Find source in high terrain region
2. Sample heights in multiple directions
3. Follow lowest path with random curve offsets
4. Stop when reaching MEADOW or 120+ units length
5. Smooth path for natural appearance

### Terrain Carving Updates

- `get_height_at()` now handles variable radii for ponds/lakes
- River cross-section: flat floor (40% width), sloped edges (40-100% width)
- All water bodies carve terrain appropriately

### Unified Water Detection

- New `is_in_water(x, z, buffer)` function checks all water types
- `is_near_any_pond()` now wraps `is_in_water()` for backward compatibility
- `get_nearest_water_body()` returns detailed water body info
- Trees, resources, decorations use unified water check

### River Rendering

- Inline river segment creation (no external scene required)
- PlaneMesh water surface per segment
- Area3D for swimming detection with enter/exit signals
- Segments spawned as chunks load
- Fishing pools at river widening points

### Ambient Sound System (NEW)

**AmbientSoundManager** singleton (`scripts/core/ambient_sound_manager.gd`):
- Up to 6 AudioStreamPlayer3D emitters for water sounds
- Spatial audio with natural falloff (8 unit full volume, 40 unit max distance)
- Emitters positioned at nearby water bodies and river waypoints
- Update throttling (0.5 second intervals)
- Graceful handling when audio file not present

**Audio Bus Layout** (`resources/default_bus_layout.tres`):
- Master (default)
- Music (for background tracks)
- Ambient (for environmental sounds, -8dB default)
- SFX (for gameplay sounds)

**Audio Files**:
- `assets/audio/ambient/pond_ambient.mp3` - Calm water sound for ponds and lakes
- `assets/audio/ambient/river_ambient.mp3` - Flowing stream sound for rivers
- Source: Pixabay (royalty-free, no attribution required)

### New Files

| File | Purpose |
|------|---------|
| `scripts/core/ambient_sound_manager.gd` | Spatial ambient audio singleton |
| `resources/default_bus_layout.tres` | Audio bus configuration |

### Improved Hills & Rocky Terrain

**HILLS Region**:
- Height scale increased from 12 to 22 for much taller hills
- Step size changed to 1.0 (always jumpable)
- New `hill_noise` creates dramatic large-scale peaks with variation
- New `path_noise` carves winding valleys through hills for climbing routes
- Power curve applied to hill shapes for more dramatic peaks
- Detail noise increased to 4 units for surface variation

**ROCKY Region**:
- Height scale increased from 8 to 12
- Step size changed from 2.0 to 1.0 (now jumpable)
- Uses same path_noise to create some climbing routes
- Jagged detail with higher frequency noise

**Climbable Paths**: Path noise creates natural valleys that wind through terrain, ensuring every hill has at least one route with 1-step increments that can be jumped.

### Files Modified

| File | Changes |
|------|---------|
| `scripts/world/chunk_manager.gd` | Water body system, rivers, terrain carving, `is_in_water()`, improved hills/rocky terrain |
| `project.godot` | AmbientSoundManager autoload, audio bus reference |
| `ATTRIBUTIONS.md` | Water sound asset info |

---

## Session 35 - Rope Ladder (2026-02-01)

**New Craftable Structure**: Rope Ladder for climbing steep cliffs.

### Recipe
- **Inputs**: 2 rope + 4 branches
- **Output**: rope_ladder_kit
- **Requires**: Crafting bench

### Placement
- Place against any vertical surface
- 8 unit tall ladder with visual rungs
- Grid-snapped like other structures

### Climbing Mechanics
- Walk into ladder to grab it
- W/Forward: Climb up
- S/Backward: Climb down
- Space/Jump: Also climbs up
- At top: Player pushed forward onto ledge
- At bottom: Normal movement resumes

### Visual Design
- Two tan rope lines running vertically
- Wood rungs every 0.5 units
- Top anchor knot/hook visual
- Matches blocky aesthetic

### Files Created
- `scripts/campsite/structure_rope_ladder.gd` - Ladder structure with climbing logic

### Files Modified
- `scripts/crafting/crafting_system.gd` - Added rope_ladder_kit recipe
- `scripts/campsite/structure_data.gd` - Added rope_ladder structure definition
- `scripts/campsite/placement_system.gd` - Added _create_rope_ladder() function

---

## Session 35b - Spawn Area Always Forest (2026-02-01)

**Forest Spawn Zone**: The area within 60 units of spawn (0,0) is now always FOREST region, regardless of noise values. This ensures a consistent starting experience with:
- Moderate tree density
- Standard terrain height variation
- The guaranteed campsite pond at (15, 12)

**Files Modified**: `scripts/world/chunk_manager.gd` - Added spawn distance check in `get_region_at()`

---

## Session 36 - Structure Spacing & Move Functionality (2026-02-01)

**Structure Spacing Validation**: Prevents placing structures too close to each other.
- Added `footprint_radius` to each structure type in StructureData
- 1 meter minimum edge-to-edge spacing enforced
- Preview turns red when placement would overlap
- Edge-to-edge calculation: center distance - both radii >= min_spacing

**Footprint Radii** (based on collision sizes):
| Structure | Footprint Radius |
|-----------|------------------|
| fire_pit | 0.85 |
| basic_shelter | 1.4 |
| storage_container | 0.6 |
| crafting_bench | 0.7 |
| drying_rack | 0.8 |
| herb_garden | 1.25 |
| canvas_tent | 2.0 |
| cabin | 4.0 |
| rope_ladder | 0.5 |

**Move Structure Feature**: Relocate placed structures without rebuilding.
- Look at structure and press M (keyboard) or D-pad Up (controller)
- Original structure becomes semi-transparent (50% alpha)
- Green/red preview shows new location validity
- R/R2 to confirm, Q/Circle to cancel
- Structure stays at original position if cancelled
- Move respects spacing validation (excludes self from check)

**New Input Action**: `move_structure`
- Keyboard: M key
- Controller: D-pad Up (button_index 11)

**HUD Update**: Interaction prompt now shows move hint when looking at structures:
- Example: `[E] Use Fire  [M] Move`
- Keyboard/controller prompts update dynamically

**New Signals** (`PlacementSystem`):
- `structure_move_started(structure: Node3D)`
- `structure_move_confirmed(structure: Node3D, old_pos: Vector3, new_pos: Vector3)`
- `structure_move_cancelled(structure: Node3D)`

**Bug Fix**: Structures placed underground on elevated terrain
- Previous code hardcoded `target_pos.y = 0` regardless of terrain height
- Added `_get_ground_height()` function that raycasts from y=50 down to find actual terrain surface
- Structures now correctly sit on terrain at any elevation

### Files Modified
| File | Changes |
|------|---------|
| `scripts/campsite/structure_data.gd` | Added footprint_radius to all structures |
| `scripts/campsite/placement_system.gd` | Spacing validation, move mode, ground height raycast |
| `scripts/campsite/campsite_manager.gd` | Added get_placed_structures() method |
| `scripts/player/player_controller.gd` | Move input handling, _try_move_structure() |
| `scripts/ui/hud.gd` | Move hint in interaction prompt |
| `scripts/systems/input_manager.gd` | move_structure button prompts |
| `project.godot` | move_structure input action |

---

## Session 37 - Bug Fixes & Save/Load Improvements (2026-02-01)

### UI Null Viewport Fix

Fixed "Cannot call method 'set_input_as_handled' on a null value" error that occurred during scene transitions.

**Root Cause**: `get_viewport()` returns null when a node is not in the scene tree, which can happen during scene reload (e.g., when loading a save with different world seed).

**Fix Applied to All UI Files**:
- Added `is_inside_tree()` check at start of `_input()` functions
- Added `_handle_input()` helper function that safely checks viewport before calling `set_input_as_handled()`

**Files Modified**: `config_menu.gd`, `pause_menu.gd`, `fire_menu.gd`, `storage_ui.gd`, `equipment_menu.gd`, `crafting_ui.gd`

### Save/Load System Improvements

**Problem**: Loading a saved game from a fresh start (different world seed) showed only blue sky with nothing visible.

**Improvements Made** (`scripts/core/save_load.gd`):
1. Added `process_mode = PROCESS_MODE_ALWAYS` to ensure SaveLoad works even if game is paused
2. Added warnings when critical node references (player, chunk_manager) are not found
3. Improved `_check_pending_load()`:
   - Waits 3 frames instead of 1 for terrain to fully initialize
   - Re-acquires node references after waiting (in case they weren't available initially)
   - Better error logging with reference status
4. Added `get_tree().paused = false` after loading to ensure game is unpaused
5. Added detailed logging throughout `_apply_save_data()` to help diagnose issues

### Fire Menu Jump Fix

**Problem**: Pressing X button to select a menu option also made the player jump.

**Root Cause**: When X is pressed:
1. Menu handles `ui_accept` and calls the action (e.g., Warm Up)
2. Action function calls `close_menu()` which sets `is_open = false`
3. Same frame, player controller's `_physics_process` checks `_is_ui_blocking_input()`
4. Menu appears closed, so jump is allowed

**Fix** (`scripts/ui/fire_menu.gd`):
1. Consume both `ui_accept` and `jump` actions in `_input()` when menu is open
2. Defer `is_open = false` to end of frame via `call_deferred("_set_closed")`
3. This ensures `_is_ui_blocking_input()` returns true for entire frame when menu closes

### Files Modified

| File | Changes |
|------|---------|
| `scripts/core/save_load.gd` | process_mode, better logging, error handling, unpause after load |
| `scripts/ui/config_menu.gd` | Null viewport safety |
| `scripts/ui/pause_menu.gd` | Null viewport safety |
| `scripts/ui/fire_menu.gd` | Null viewport safety, jump fix with deferred close |
| `scripts/ui/storage_ui.gd` | Null viewport safety |
| `scripts/ui/equipment_menu.gd` | Null viewport safety |
| `scripts/ui/crafting_ui.gd` | Null viewport safety |

### Trees Don't Spawn on Structures

**Problem**: If a player cut down a tree and placed a structure (like a shelter) at that location, the tree could respawn inside the structure.

**Fix Applied**:
1. **Resource respawning** (`resource_manager.gd`):
   - Added `campsite_manager_path` reference
   - Added `_is_structure_blocking_respawn()` function
   - Before respawning a tree, checks if any structure is within range
   - If blocked, keeps tree in depleted list to check again later

2. **Chunk tree spawning** (`chunk_manager.gd`, `terrain_chunk.gd`):
   - Added `is_position_blocked_by_structure()` helper function
   - When chunks load and spawn trees, checks each position against structures
   - Uses structure footprint radius + tree radius for overlap detection

**Files Modified**:
| File | Changes |
|------|---------|
| `scripts/resources/resource_manager.gd` | Structure blocking check for respawns |
| `scripts/world/chunk_manager.gd` | `is_position_blocked_by_structure()` helper |
| `scripts/world/terrain_chunk.gd` | Check structures before spawning trees |
| `scenes/main.tscn` | Added campsite_manager_path to ResourceManager |

### Cabin Placement Distance Fix

**Problem**: Could not place the log cabin because validation always failed - player was always "too close" even at maximum placement distance.

**Root Cause**:
- Cabin footprint radius is 4.0m
- Validation required player to be at least 3.5m from structure center (footprint - 0.5)
- But `placement_distance` was only 3.0m, so cabin was always placed too close

**Fix** (`placement_system.gd`):
- `_update_preview_position()`: Calculate `effective_distance` based on footprint
  - For structures with footprint > 2.0m, use `max(placement_distance, footprint + 1.5)`
  - Cabin now placed at 5.5m instead of 3.0m
- `_validate_placement()`: Increase `max_distance` for large structures
  - For structures with footprint > 2.0m, allow `footprint + 3.0m` max distance
  - Cabin can now be placed up to 7.0m away

---

## Session 38 - Sound Effects System (2026-02-02)

**SFXManager Singleton**: New pooled audio player system for gameplay sound effects.

### Architecture

**Pool System** (`scripts/core/sfx_manager.gd`):
- 8 AudioStreamPlayer instances routed to "SFX" bus
- Round-robin allocation for overlapping sounds
- Preloads all sounds at startup for instant playback

**Cooldown System**:
| Sound Type | Cooldown |
|------------|----------|
| footstep | 0.3s |
| chop | 0.15s |
| swing | 0.2s |
| pickup | 0.1s |
| berry_pluck | 0.15s |
| tree_fall | 0.5s |
| cast | 0.3s |
| fish_caught | 0.5s |
| tool_break | 0.5s |
| place_confirm | 0.2s |
| place_cancel | 0.2s |

**Anti-Repetition**: Footsteps track last-played variant per surface to avoid repeating same sound.

### Public API

```gdscript
SFXManager.play_footstep(surface: String)  # "grass", "stone", "water"
SFXManager.play_sfx(sound_name: String)    # "chop", "swing", "pickup", etc.
SFXManager.set_volume(volume: float)       # 0.0 to 1.0
```

### Sound Categories

**Footsteps** (4 variants each):
- `grass_1..4.mp3` - Default walking sound
- `stone_1..4.mp3` - Rocky/hills terrain
- `water_1..4.mp3` - Swimming/wading

**Tools**:
- `axe_swing.mp3` - Swing animation
- `wood_chop.mp3` - Hit on tree
- `tool_break.mp3` - Durability depleted

**Gathering**:
- `item_pickup.mp3` - Generic pickup
- `berry_pluck.mp3` - Berries and herbs
- `tree_fall.mp3` - Tree chopped down

**Fishing**:
- `cast.mp3` - Line cast
- `fish_caught.mp3` - Successful catch

**Placement**:
- `confirm.mp3` - Structure placed
- `cancel.mp3` - Placement cancelled

### Integration Points

**Player Movement** (`player_controller.gd`):
- Footsteps every 0.4s while moving on floor
- Surface detection: Rocky/Hills → stone, Water → water, else → grass
- Works in both normal movement and swimming

**Equipment** (`equipment.gd`):
- Swing sound on every axe swing
- Chop sound on successful tree hit
- Tool break sound when durability depleted
- Cast sound when fishing line thrown
- Fish caught sound on successful catch

**Resource Nodes** (`resource_node.gd`):
- Berry pluck for berries/herbs
- Generic pickup for other resources
- Tree fall when multi-chop tree harvested

**Placement System** (`placement_system.gd`):
- Confirm sound on structure placement
- Cancel sound when placement cancelled
- Same sounds for move confirm/cancel

### Sound File Structure

```
assets/audio/sfx/
├── footsteps/
│   ├── grass_1..4.mp3
│   ├── stone_1..4.mp3
│   └── water_1..4.mp3
├── tools/
│   ├── axe_swing.mp3
│   ├── wood_chop.mp3
│   └── tool_break.mp3
├── gather/
│   ├── item_pickup.mp3
│   ├── berry_pluck.mp3
│   └── tree_fall.mp3
├── fishing/
│   ├── cast.mp3
│   └── fish_caught.mp3
├── placement/
│   ├── confirm.mp3
│   └── cancel.mp3
└── ui/
    ├── menu_open.mp3
    ├── menu_close.mp3
    ├── select.mp3
    └── cancel.mp3
```

**Audio files sourced from OpenGameArt.org** (CC0/CC-BY licensed) - see ATTRIBUTIONS.md for credits.

### Bug Fixes During Testing

1. **Dictionary iteration type error**: Removed explicit `: String` type annotations when iterating over dictionary keys (returns Variant in Godot 4.x)

2. **Region type mismatch**: `get_region_at()` returns `RegionType` enum (int), not String - fixed comparison logic

3. **Water sounds on adjacent blocks**: Added Y-position check (`global_position.y < water_surface_y`) to only play water footsteps when actually submerged

4. **Slow movement near water**: Swimming movement was triggered by `is_in_water` flag alone - now requires both `is_in_water` AND being below water surface

### Files Created
- `scripts/core/sfx_manager.gd` - SFXManager singleton

### Files Modified
| File | Changes |
|------|---------|
| `project.godot` | Added SFXManager autoload |
| `scripts/player/player_controller.gd` | Footstep timer and surface detection |
| `scripts/player/equipment.gd` | Tool swing/chop/break and fishing sounds |
| `scripts/resources/resource_node.gd` | Gather and tree fall sounds |
| `scripts/campsite/placement_system.gd` | Placement confirm/cancel sounds |

---

## Session 39 - Visual Polish (2026-02-02)

**Three visual improvements** for a more Minecraft-like aesthetic: distance fog, vertex ambient occlusion, and pixelated textures.

### Distance Fog

**Persistent atmospheric fog** that's always on (not just during weather):
- Base fog density: 0.008 (subtle distance fade)
- Fog color lerps with time of day to match sky horizon:
  - Dawn: Warm orange-pink `(0.95, 0.75, 0.6)`
  - Day: Light blue `(0.65, 0.75, 0.9)`
  - Dusk: Orange `(0.9, 0.6, 0.5)`
  - Night: Dark blue `(0.1, 0.1, 0.2)`
- Weather fog ADDS to base density instead of replacing it
- Creates atmospheric depth and helps hide chunk loading at distance

### Vertex Ambient Occlusion

**Per-vertex AO** darkens corners where terrain blocks meet:

**Top Face AO**:
- Each of 4 corner vertices samples 3 adjacent cell heights
- If neighbor is higher, that corner is darker (12% per occluding neighbor)
- Creates natural shadowing at block edges
- Clamped to 55-100% brightness

**Side Face AO**:
- Top vertices: Check for overhang from terrain behind
- Bottom vertices: Naturally darker (10% base) + additional from surrounding heights
- AO interpolated along face for smooth gradient
- Bottom of cliffs appears recessed/shadowed

### Pixelated Textures

**16x16 procedural textures** generated at runtime:

**Texture Atlas** (32x32, 4 textures in 2x2 grid):
| Position | Texture | Description |
|----------|---------|-------------|
| Top-left | grass_top | Green with pixel variation |
| Top-right | grass_side | 4px grass strip over dirt |
| Bottom-left | dirt | Brown with dark spots |
| Bottom-right | stone | Grey with crack patterns |

**UV Mapping**:
- Top faces: Full grass_top (or stone for ROCKY regions)
- Side faces: grass_side for tall faces, dirt for pure dirt sections
- UV coordinates per-vertex with atlas lookups

**Material Setup**:
- `TEXTURE_FILTER_NEAREST` for crisp pixels (no interpolation)
- Texture modulates with vertex color (preserves region tinting + AO)
- Combined effect: texture detail × region color × AO darkening

### Files Created

| File | Purpose |
|------|---------|
| `scripts/world/terrain_textures.gd` | TerrainTextures class - generates 16x16 textures programmatically |

### Files Modified

| File | Changes |
|------|---------|
| `scripts/world/environment_manager.gd` | Persistent distance fog, time-based fog color, weather fog adds to base |
| `scripts/world/terrain_chunk.gd` | Vertex AO calculation for top and side faces, UV coordinates |
| `scripts/world/chunk_manager.gd` | Textured material with atlas and nearest-neighbor filtering |

---

## Session 40 - Distance Fog Fix (2026-02-02)

**Fixed fog being too dense when player is far from spawn.**

### Problem

The previous exponential fog system calculated fog based on absolute world-space distance from the camera. This caused terrain far from the origin to appear heavily fogged even in clear weather, because the exponential falloff accumulated over large distances.

### Solution

Switched from `FOG_MODE_EXPONENTIAL` to `FOG_MODE_DEPTH` which uses camera-relative depth values:
- `fog_depth_begin`: 60 units (fog starts)
- `fog_depth_end`: 300 units (full fog)
- `fog_depth_curve`: 1.0 (linear falloff)

This ensures fog is consistent regardless of where the player is in the world - it always fades terrain between 60-300 units from the camera.

### Weather Integration

Weather now affects visibility by modifying `fog_depth_end`:
| Weather | Visibility Distance |
|---------|---------------------|
| Clear | 300 units |
| Heat Wave | 250 units |
| Cold Snap | 220 units |
| Rain | 200 units |
| Storm | 120 units |
| Fog | 80 units |

Weather fog density values were also reduced since they now add extra haze on top of depth fog.

### Files Modified
- `scripts/world/environment_manager.gd` - Switched to depth fog, added weather visibility distances

### Drying Rack Interaction Text Fix

**Problem**: When adding food to the drying rack, the percentage progress wasn't shown until the player looked away and back.

**Cause**: `_update_interaction_target()` only emits `interaction_target_changed` when the target changes. After interaction, the target is still the same drying rack, so the HUD wasn't updated even though `get_interaction_text()` returned new text.

**Fix**: In `_try_interact()`, re-emit `interaction_target_changed` after calling `interact()` to refresh the HUD with any updated text.

**Files Modified**: `scripts/player/player_controller.gd`

### Cabin Structure Fix

**Problem**: The log cabin had visible gaps at the top where you could see through to the sky. The peaked roof left triangular openings at the front and back (gable areas).

**Fix**: Added three new elements to the cabin structure:
1. **Ceiling** - Flat wooden ceiling at wall height to close off the interior
2. **Front gable wall** - Fills the triangular gap under the roof at the front
3. **Back gable wall** - Fills the triangular gap under the roof at the back

Also adjusted roof angle from 25° to 30° for better coverage and tweaked positioning.

**Files Modified**: `scripts/campsite/placement_system.gd`, `scripts/core/save_load.gd`

### Kitchen Recipe Message Fix

**Problem**: When cooking at the cabin kitchen, the "missing ingredients" message was confusing. It would say "Need 1 dried fish" when the player already had 1 dried fish - but the recipe actually required 2.

**Cause**: The message showed how many *more* items were needed (the difference), but phrased it as the total needed, causing confusion.

**Fix**: Changed the message format to show both the required amount and current inventory:
- Before: "Need 1 dried fish for Preserved Meal"
- After: "Need 2 dried fish (have 1) for Preserved Meal"

Also replaced underscores with spaces in item names for better readability (e.g., "dried fish" instead of "dried_fish").

**Files Modified**: `scripts/campsite/cabin_kitchen.gd`

### Dynamic Interaction Text Refresh

**Problem**: The drying rack percentage only updated when the player looked away and back, or interacted with it. The text was static even though the drying progress was advancing.

**Fix**: Added a periodic refresh timer (1 second interval) that automatically updates the interaction text for the current target. This makes dynamic text like the drying rack's "Drying Fish (45%)" update in real-time while the player looks at it.

**Files Modified**: `scripts/player/player_controller.gd`

### A-Frame Cabin Redesign

**Problem**: The original cabin had walls poking out at odd angles with rectangular gable boxes that didn't fit the angled roof properly.

**Solution**: Complete redesign as an Austrian-style A-frame cabin:
- **Steep roof panels** extend from short knee walls (0.8m) up to a high peak (5.5m)
- **Stepped triangular walls** at front and back use stacked boxes that get narrower toward the peak (blocky Minecraft aesthetic)
- **Doorway** cut into the front triangular wall
- **No separate ceiling** - the angled roof IS the ceiling/walls on the sides
- **Dimensions**: 6x6 base, 5.5m peak height

The A-frame design is cleaner and more distinctive, matching the traditional alpine cabin style.

**Bug Fixes**:
1. **Roof corners sticking out** - Fixed roof panel positioning so they start from the knee wall base and extend cleanly to the peak without overlapping corners
2. **Can't enter cabin** - Split front wall collision into three parts (left of door, right of door, above door) leaving a gap for the doorway

### Resources Don't Spawn Inside Structures

**Problem**: Mushrooms, herbs, and other small resources could spawn inside structure footprints.

**Fix**:
1. Added `is_position_blocked_by_structure()` check to the resource spawning loop in terrain_chunk.gd for initial chunk spawning
2. Extended `remove_trees_overlapping_structures()` in chunk_manager.gd to also remove resources (mushrooms, herbs, berries, etc.) that overlap with structures when loading a saved game

Note: Resource respawning already had this check in resource_manager.gd.

### A-Frame Roof Peak Fix

**Problem**: Roof panel corners were still sticking out at the peak where the two angled panels meet.

**Fix**:
1. Shortened roof panels by calculating the corner extension distance and subtracting it from the panel length
2. Added a ridge cap (horizontal box at the peak) to cover the gap and create a clean ridge line
3. Formula: `corner_extension = roof_thickness / (2 * sin(roof_angle))`

**Files Modified**: `scripts/campsite/placement_system.gd`, `scripts/core/save_load.gd`, `scripts/world/terrain_chunk.gd`, `scripts/world/chunk_manager.gd`

---

## Session 41 - Tool Tiers, Traps & Stations (2026-02-02)

**Three major feature sets** expanding content depth: tool tiers, animal trapping, and level 3 crafting stations.

### Tool Tier System

**Tool Effectiveness Multiplier** - Different axes now have varying chopping power:

| Tool | Durability | Effectiveness | Chops per Tree |
|------|------------|---------------|----------------|
| Primitive Axe | 30 | 0.5 | 4 |
| Stone Axe | 150 | 1.0 | 2 |
| Metal Axe | 300 | 2.0 | 1 |

**Implementation**:
- Added `effectiveness` field to `EQUIPPABLE_ITEMS` in equipment.gd
- New `get_tool_effectiveness()` helper function
- ResourceNode now uses `chop_progress_float` for fractional progress
- Each axe type has distinct visual model (primitive has vine binding, metal has shiny blade)

**Recipes**:
- Primitive Axe: 1 river_rock + 1 branch (no bench required)
- Metal Axe: 2 metal_ingot + 2 branch (requires bench, camp level 3)

### Ore Resource & Smithing

**Iron Ore Deposits**:
- New `OreNode` class extending ResourceNode
- Spawns in ROCKY (4.5% chance) and HILLS (1.5% chance) regions
- Requires axe, 3 chops to harvest
- Yields: 2 iron_ore + 1 river_rock

**Smithing Station** (Level 3 structure):
- Smelts iron_ore → metal_ingot
- Requires 2 wood as fuel per smelt
- Processing time: 120 seconds (2 game hours)
- Visual: Stone forge with coal pit, bellows, and anvil

**Recipe**: 15 river_rock + 8 wood + 2 rope (requires bench, camp level 3)

### Snare Trap & Animal Resources

**Snare Trap** (Level 2 structure):
- Requires bait (berry, mushroom, or herb)
- Checks for catch every game hour when baited
- 15% catch chance per check

**Catch Table**:
| Animal | Chance | Loot |
|--------|--------|------|
| Rabbit | 70% | 2 raw_meat + 1 hide |
| Bird | 30% | 1 raw_meat + 2 feathers |

**New Resources**: raw_meat, hide, feathers

**Recipe**: 2 rope + 4 branches (requires bench, camp level 2)

### Smoker Structure

**Smoker** (Level 3 structure):
- Converts raw_meat → smoked_meat
- Also works with fish → smoked_fish
- Requires 1 wood as fuel
- Processing time: 180 seconds (3 game hours)
- Visual: Wooden frame with smoking racks over stone fire pit

**Recipe**: 10 wood + 6 river_rock + 2 rope (requires bench, camp level 3)

### Weather Vane

**Weather Vane** (Level 3 structure):
- Shows current weather on interact
- Displays forecast for next weather period
- Arrow wobbles with animated wind effect
- Cardinal direction markers (N/S/E/W)

**Weather Manager Updates**:
- Added `next_weather` tracking
- New `_generate_forecast()` function
- `get_current_weather_name()` and `get_next_weather()` API
- 85% forecast accuracy (slight chance of being wrong)

**Recipe**: 6 branches + 1 metal_ingot (requires bench, camp level 3)

### New Files Created

| File | Purpose |
|------|---------|
| `scripts/resources/ore_node.gd` | Ore deposit resource node |
| `scenes/resources/ore_node.tscn` | Ore visual with rust-colored veins |
| `scripts/campsite/structure_smithing_station.gd` | Ore smelting logic |
| `scripts/campsite/structure_snare_trap.gd` | Animal trapping logic |
| `scripts/campsite/structure_smoker.gd` | Meat smoking logic |
| `scripts/campsite/structure_weather_vane.gd` | Weather display logic |

### Files Modified

| File | Changes |
|------|---------|
| `scripts/player/equipment.gd` | Added primitive_axe, metal_axe, effectiveness, new kit items |
| `scripts/resources/resource_node.gd` | Fractional chop progress with tool effectiveness |
| `scripts/crafting/crafting_system.gd` | 6 new recipes |
| `scripts/campsite/structure_data.gd` | 4 new structures + placeables |
| `scripts/campsite/placement_system.gd` | Visual creation for new structures |
| `scripts/world/terrain_chunk.gd` | Ore spawning in ROCKY/HILLS |
| `scripts/world/chunk_manager.gd` | Load ore_scene |
| `scripts/world/weather_manager.gd` | Forecast system |

---

## Session 42 - Ambient Animals (2026-02-02)

**Ambient wildlife system** that provides atmospheric life to the wilderness. Rabbits and birds spawn in chunks and flee when the player approaches.

### Architecture

**Base Class** (`scripts/creatures/ambient_animal_base.gd`):
- State machine: IDLE → MOVING → FLEEING
- Throttled player proximity checks (4x/second for performance)
- Configurable flee and awareness distances
- Terrain height sampling via ChunkManager
- `despawn()` method for chunk cleanup

### Rabbit Behavior

**AmbientRabbit** (`scripts/creatures/ambient_rabbit.gd`):
- Hopping movement with parabolic arc animation
- 3 hops per movement cycle, 8 rapid hops when fleeing
- Flee distance: 8 units
- Brown-grey blocky mesh (body, head, ears, tail)
- Squash/stretch animation during hops

| State | Behavior |
|-------|----------|
| IDLE | Stand still 2-8 seconds |
| MOVING | 3 hops in random direction |
| FLEEING | 8 rapid hops away from player |

### Bird Behavior

**AmbientBird** (`scripts/creatures/ambient_bird.gd`):
- Hybrid perched/flying behavior
- Wing flapping animation during flight
- Chirps while perched (5-15 second intervals)
- Flee distance: 12 units
- Grey-blue blocky mesh (body, head, wings, tail, beak)

| State | Behavior |
|-------|----------|
| PERCHED | Sit on ground or elevated, chirp periodically |
| FLYING | Fly 3-8s toward random target |
| LANDING | Descend to ground or tree height |
| FLEEING | Take off vertically, fly away fast |

### Spawn Rates by Region

| Region | Rabbits | Birds |
|--------|---------|-------|
| MEADOW | 1-2 | 1-2 |
| FOREST | 1-3 | 1-2 |
| HILLS | 0-1 | 1-3 |
| ROCKY | 0 | 0-2 |

Maximum 4 animals per chunk for performance.

### Performance Optimizations

1. **Node3D only** - No CharacterBody3D or physics
2. **Throttled checks** - Player distance checked 4x/second, not every frame
3. **Simple meshes** - BoxMesh for all parts (matches game aesthetic)
4. **Chunk lifecycle** - Created/destroyed with chunks, no global tracking
5. **Deterministic seeding** - Consistent animal positions per chunk

### Sound Effects

Added to SFXManager with cooldowns:
- `rabbit_hop` (0.2s cooldown)
- `bird_chirp` (0.5s cooldown)
- `bird_flap` (0.3s cooldown)

**Note**: Sound files needed in `assets/audio/sfx/animals/`:
- `rabbit_hop.mp3` - Soft thump
- `bird_chirp.mp3` - Single chirp
- `bird_flap.mp3` - Wing sound

### Files Created

| File | Purpose |
|------|---------|
| `scripts/creatures/ambient_animal_base.gd` | Base class with state machine |
| `scripts/creatures/ambient_rabbit.gd` | Hopping rabbit behavior |
| `scripts/creatures/ambient_bird.gd` | Flying/perching bird behavior |

### Files Modified

| File | Changes |
|------|---------|
| `scripts/world/terrain_chunk.gd` | Animal spawning, `spawned_animals` array, cleanup in `unload()` |
| `scripts/core/sfx_manager.gd` | Animal sound paths and cooldowns |

---

## Session 43 - Resource Economy Balancing (2026-02-03)

**Game balancing adjustments** to create satisfying progression that's challenging but not frustrating. Focus on a camping adventure experience rather than hardcore survival.

### Hunger System Rebalancing

**File**: `scripts/player/player_stats.gd`

| Parameter | Before | After | Impact |
|-----------|--------|-------|--------|
| hunger_depletion_rate | 0.1/sec | 0.05/sec | 2x longer between meals (~33 min vs ~16 min) |

- At rest: ~33 minutes from full to empty (was ~16 min)
- Sprinting (2x multiplier): ~16 minutes (was ~8 min)
- Reduces constant eating pressure, allows more exploration time

### Tree Respawn Time

**File**: `scripts/resources/resource_manager.gd`

| Parameter | Before | After | Impact |
|-----------|--------|-------|--------|
| tree_respawn_time_hours | 168 (7 days) | 48 (2 days) | Trees respawn much faster |

- Players who chop trees on day 1 get them back by day 3
- Prevents permanent deforestation of play area
- Still meaningful enough to plan resource gathering

### Primitive Axe Durability

**File**: `scripts/player/equipment.gd`

| Tool | Before | After | Trees Before Breaking |
|------|--------|-------|----------------------|
| primitive_axe | 30 | 50 | ~12 trees (was ~7) |

- More forgiving early game experience
- Still creates urgency to upgrade to stone axe
- 67% more uses per primitive axe

### Resource Spawn Density

**File**: `scripts/world/chunk_manager.gd`

| Resource | Before | After | Change |
|----------|--------|-------|--------|
| berry_density | 0.02 | 0.03 | 50% more berries |
| herb_density | 0.02 | 0.025 | 25% more herbs |

- Berries more abundant for food chain reliability
- More herbs for healing salve crafting

### Expanded Food Values

**File**: `scripts/player/player_controller.gd`

Added missing preserved and cooked food values:

| Category | Food Item | Hunger Restored |
|----------|-----------|-----------------|
| **Raw** | berry | 15 |
| | mushroom | 10 |
| | herb | 5 |
| | fish | 25 |
| | raw_meat (NEW) | 20 |
| **Processed** | berry_pouch | 40 |
| **Cooked** | cooked_berries | 25 |
| | cooked_mushroom | 20 |
| | cooked_fish | 40 |
| | cooked_meat (NEW) | 35 |
| **Preserved** | dried_fish (NEW) | 30 |
| | dried_berries (NEW) | 20 |
| | dried_mushroom (NEW) | 15 |
| **Smoked** | smoked_meat (NEW) | 45 |
| | smoked_fish (NEW) | 50 |

### Progression Impact

**Early Game (Level 1, Day 1-2)**:
- 33 min between full meals = less pressure
- Primitive axe lasts ~12 trees = enough to establish camp
- Berries more abundant for reliable food

**Mid Game (Level 2, Day 3-7)**:
- Stone axe trivializes wood gathering
- Drying rack creates food stockpile
- Fishing + preservation = food abundance

**Late Game (Level 3, Day 8+)**:
- Metal axe makes gathering relaxing
- Kitchen provides best food efficiency
- Smoker creates premium preserved food
- Focus shifts to building and exploration

### Torch Light Fix

**Problem**: Equipped torch light wasn't visible because energy was too low (2.0) compared to ambient lighting (~1.0).

**Fix**: Increased torch light_energy from 2.0 to 8.0 and light_range from 10.0 to 15.0.

### Placeable Torches

**New Feature**: Torches can now be placed on the ground as a light source and reclaimed later.

**Placement**:
- Equip torch and press R/R2 to place
- Torch stands upright in the ground
- Provides same light as held torch (energy 8.0, range 15.0)
- Subtle flicker animation for atmosphere

**Reclaim**:
- Look at placed torch and press E/Square to pick up
- Returns torch to inventory
- Can also use M/D-pad Up to move it like other structures

**Visual Design**:
- Wooden stick handle
- Cloth wrap near top
- Blocky flame with emissive material
- Inner bright flame core

### Files Created

| File | Purpose |
|------|---------|
| `scripts/campsite/structure_placed_torch.gd` | Placed torch behavior with reclaim |

### Files Modified

| File | Changes |
|------|---------|
| `scripts/player/player_stats.gd` | Reduced hunger_depletion_rate from 0.1 to 0.05 |
| `scripts/resources/resource_manager.gd` | Reduced tree_respawn_time_hours from 168 to 48 |
| `scripts/player/equipment.gd` | Increased primitive_axe durability; torch light energy 2→8, range 10→15, added placeable |
| `scripts/world/chunk_manager.gd` | Increased berry_density to 0.03, herb_density to 0.025 |
| `scripts/player/player_controller.gd` | Added raw_meat, cooked_meat, dried foods, and smoked foods |
| `scripts/campsite/structure_data.gd` | Added placed_torch structure, torch to PLACEABLE_ITEMS |
| `scripts/campsite/placement_system.gd` | Added _create_placed_torch() visual builder |

---

## Session 44 - Terrain Performance Optimization (2026-02-04)

**Performance optimizations** to fix stuttering during terrain chunk loading, especially noticeable on MacBook Pro.

### Root Causes Identified

1. **Expensive `get_height_at()` calls** - Terrain noise sampling called multiple times per frame per animal
2. **Uncached `SFXManager` lookups** - Scene tree traversal (`get_node_or_null("/root/SFXManager")`) on every hop/chirp
3. **`look_at()` every frame** - Matrix calculations for 14+ animals every single frame
4. **No distance-based culling** - Animals far from player still fully processed
5. **30% spawn rate** - With 25 chunks loaded, ~7-8 chunks had animals (~14-16 animals)

### Optimizations Applied

**Base Class Improvements** (`ambient_animal_base.gd`):
- Cached `sfx_manager` reference in `_ready()` instead of per-call lookup
- Added distance-based culling: animals beyond 50 units skip processing entirely
- Throttled `look_at()` calls to every 0.1 seconds instead of every frame
- New constants: `PROCESSING_DISTANCE`, `ROTATION_UPDATE_INTERVAL`
- New state: `is_too_far` flag checked during proximity updates

**Bird Optimizations** (`ambient_bird.gd`):
- Uses cached `sfx_manager` from base class
- Flying `look_at()` now throttled via base class timer
- Entire bird state machine skipped when `is_too_far`

**Rabbit Optimizations** (`ambient_rabbit.gd`):
- Uses cached `sfx_manager` from base class
- Reduced terrain height sampling from 2-3 calls per hop to 1 call
- When hitting water, uses current Y instead of resampling terrain
- `look_at()` now throttled
- Hop processing skipped when `is_too_far`

**Spawn Rate Reduction** (`terrain_chunk.gd`):
- Animal spawn rate reduced from 30% to 15% of chunks
- With 25 chunks, now ~3-4 chunks have animals (~6-8 animals total)
- Halves the number of active animals while keeping atmosphere

### Performance Impact

| Metric | Before | After |
|--------|--------|-------|
| Animals active | 14-16 | 6-8 |
| `get_height_at()` calls/sec | ~30-40 | ~8-12 |
| `look_at()` calls/frame | 14-16 | 0-2 (throttled) |
| SFX lookups/sec | ~10-20 | 0 (cached) |
| Far animals processed | 100% | 0% (culled at 50 units) |

### Files Modified

| File | Changes |
|------|---------|
| `scripts/creatures/ambient_animal_base.gd` | Cached sfx_manager, distance culling, throttled look_at |
| `scripts/creatures/ambient_bird.gd` | Uses cached sfx_manager, distance culling |
| `scripts/creatures/ambient_rabbit.gd` | Uses cached sfx_manager, reduced terrain sampling, distance culling |
| `scripts/world/terrain_chunk.gd` | Reduced spawn rate from 30% to 15% |

---

## Session 45 - Trap UX Improvements (2026-02-04)

**Enhanced snare trap user experience** with visual state changes, HUD notifications, and catch alerts.

### Visual State Changes

Traps now visually reflect their current state, making it easy to check traps at a glance:

**Empty State (default)**:
- Snare loop open and flat on ground
- Trigger stick upright
- No bait or animal visible

**Baited State**:
- Visible bait mesh based on bait type:
  - Berry: Red sphere on trigger plate
  - Mushroom: Brown cap with light stem
  - Herb: Green rectangular bundle
- Trigger stick still upright, snare loop open

**Caught State**:
- Trigger stick fallen/horizontal (trap sprung)
- Snare loop contracted/raised (tightened)
- Caught animal visible:
  - **Rabbit**: Brown body with head, ears, and tail
  - **Bird**: Grey-blue body with folded wings + scattered feathers

### HUD Notifications

Replaced console-only messages with proper in-game notifications:

| Action | Notification | Color |
|--------|--------------|-------|
| Bait trap | "Trap baited with Berry" | Green |
| Check baited trap | "Trap is baited with berry. Waiting..." | Yellow |
| No bait available | "Need bait: berry, mushroom, or herb" | Orange |
| Trap catches animal | "A trap caught a Rabbit!" | Bright green |
| Collect catch | "Collected Rabbit: +2 Raw Meat, +1 Hide" | Green |

Collection shows combined loot in a single notification to avoid overlapping messages.

### Catch Alert System

When a trap catches something, players are now notified even when elsewhere:

1. **Audio cue**: "trap_snap" sound effect plays (added to SFXManager)
2. **HUD notification**: "A trap caught a Rabbit!" appears with bright green color

This ensures players know to check their traps without constantly walking back.

### Save/Load Support

Trap state now persists correctly across save/load:
- Saves: `is_baited`, `bait_type`, `has_catch`, `catch_type`, `catch_loot`, `check_timer`
- Visuals restored via `call_deferred("_update_visuals")` after loading

### New Visual Elements in Placement System

Added to `_create_snare_trap()`:
- `SnareLoopOpen` / `SnareLoopClosed` meshes
- `TriggerUpright` / `TriggerFallen` meshes
- `BaitBerry`, `BaitMushroom`, `BaitHerb` meshes
- `CaughtRabbit` node (body, head, ears)
- `CaughtBird` node (body, wings, scattered feathers)

### Files Modified

| File | Changes |
|------|---------|
| `scripts/campsite/structure_snare_trap.gd` | Complete rewrite with visual state management, HUD notifications, catch alerts, save/load |
| `scripts/campsite/placement_system.gd` | Added visual state meshes to `_create_snare_trap()` |
| `scripts/core/sfx_manager.gd` | Added "trap_snap" sound path and cooldown |

### Files Created

| File | Purpose |
|------|---------|
| `assets/audio/sfx/traps/` | Directory for trap sound effects |

**Note**: `trap_snap.mp3` audio file needs to be added for the sound effect to play.

---

## Session 14: Environmental Puzzles & Caves

### Overview

Implemented a major exploration progression system with two components:
1. **Environmental Obstacles** - Thorny bushes that gate areas in HILLS/ROCKY regions
2. **Cave System** - Explorable underground areas with unique resources and darkness mechanics

### New Files Created

| File | Purpose |
|------|---------|
| `scripts/world/obstacle_thorns.gd` | Thorny bush obstacle that blocks paths, requires machete to clear (3 chops) |
| `scripts/world/cave_entrance.gd` | Cave entrance point in ROCKY regions, requires light source to enter |
| `scripts/core/cave_transition.gd` | Autoload singleton managing cave scene transitions, stores return position |
| `scripts/caves/cave_interior_manager.gd` | Cave interior mechanics: darkness overlay, light detection, damage system |
| `scripts/resources/crystal_node.gd` | Glowing cave crystal, hand-gatherable, provides ambient light |
| `scripts/resources/rare_ore_node.gd` | Valuable ore deposit with golden emissive veins, yields rare_ore + crystal |
| `scenes/caves/cave_interior_small.tscn` | Small cave scene with terrain, resources, exit area, darkness overlay |

### Files Modified

| File | Changes |
|------|---------|
| `scripts/player/equipment.gd` | Added machete (slot 20) and lantern (slot 21) tools with visuals and swing animations |
| `scripts/crafting/crafting_system.gd` | Added machete recipe (2 metal_ingot + 1 branch, Level 2) and lantern recipe (2 metal_ingot + 1 crystal, Level 3) |
| `scripts/world/chunk_manager.gd` | Added obstacles/cave_entrances arrays, spawning logic in HILLS/ROCKY regions, visual spawning when chunks load |
| `scripts/core/save_load.gd` | Added obstacle cleared states, cave resource states, current_cave_id persistence |
| `project.godot` | Registered CaveTransition autoload |

### Feature Details

#### Thorny Bushes (Obstacles)
- Spawn in HILLS and ROCKY regions (5 per world)
- Minimum 40 units from spawn, 30 units apart
- Require machete to clear (3 effective chops)
- Visual: Dense green/brown tangled brambles using BoxMeshes
- State persisted in save files

#### Machete Tool
- Craftable at Level 2 workbench: 2 metal_ingot + 1 branch
- Durability: 200 uses
- Uses axe swing animation pattern
- Works on both resource nodes and obstacles

#### Cave Entrances
- Spawn in ROCKY regions only (4 per world)
- Minimum 80 units from spawn, 60 units apart
- Require torch or lantern equipped to enter
- Visual: Rocky arch with dark opening
- Connects to cave interior via CaveTransition autoload

#### Cave Interior System
- Separate scene architecture (teleport in/out)
- Darkness overlay (95% opacity when no light)
- Light source detection every 0.5 seconds
- Damage system: After 60s in darkness, 2 HP every 10 seconds
- Exit area triggers return to overworld at saved position

#### Cave Resources
- **Crystals**: Hand-gatherable, emit blue-purple glow (OmniLight3D), resource_type="crystal"
- **Rare Ore**: Requires pickaxe (5 chops), golden emissive veins, yields rare_ore + crystal secondary

#### Lantern Tool
- Craftable at Level 3 workbench: 2 metal_ingot + 1 crystal
- 2x brighter than torch (energy 16.0 vs 8.0)
- 2x longer range (30.0 vs 15.0)
- Placeable like torch

### Progression Flow

| Camp Level | New Access |
|------------|------------|
| Level 1 | Basic exploration, blocked by thorns |
| Level 2 | Smithing → metal_ingot → machete (clear thorns) |
| Level 3 | Cave crystals → lantern (extended cave exploration) |

### Technical Notes

- CaveTransition autoload manages scene changes with fade effects
- Placeholder behavior when cave scene files don't exist
- Equipment._use_tool() extended to detect "obstacle" group in addition to "resource_node"
- Cave scenes use WorldEnvironment with dark ambient lighting
- Obstacle/cave states stored in save data under `obstacles` and `cave_resources` keys

---

## Session 46 - Performance Fixes & Loading Screen (2026-02-04)

### Performance Optimizations

**Shader Compilation Stuttering**: Fixed severe stuttering/freezing caused by creating new materials per obstacle/cave instance.

**Obstacle Thorns** (`scripts/world/obstacle_thorns.gd`):
- Reduced from 20 meshes to 6 larger clusters
- Implemented static shared materials (`_get_base_material()`, `_get_thorn_material()`, `_get_spike_material()`)
- Materials created once and reused across all thorn instances

**Cave Entrances** (`scripts/world/cave_entrance.gd`):
- Fixed see-through doorway issue - now includes mountain rock mass behind entrance
- Reduced from 12+ meshes to 5 larger meshes
- Implemented static shared materials (`_get_rock_material()`, `_get_dark_material()`)
- Added proper collision for mountain structure

**Spawn Distance Adjustments** (`scripts/world/chunk_manager.gd`):
- Increased `obstacle_spawn_min_distance` from 40 to 100 units
- Increased `cave_spawn_min_distance` from 80 to 110 units
- Pushes heavy objects outside initial chunk load radius (~96 units)
- Reduces startup jitter from material creation

### Loading Screen

**New Visual Loading Screen** (`scripts/ui/loading_screen.gd`):
- Displays while world initializes to hide remaining startup jitter
- Shows cycling camping-related artwork using ColorRect primitives:
  - Campfire with logs and layered flames
  - Axe with handle and metal head
  - Fishing rod with line and caught fish
  - Tent with ground, walls, and opening
  - Tree with trunk and layered foliage
- Artwork cycles every 1.5 seconds with fade transitions
- Monitors `chunk_manager.get_pending_load_count()` for load completion
- Minimum 2.5 second display time for smooth experience
- Fades out gracefully when ready

**Integration**:
- Added LoadingScreen node to `scenes/main.tscn`
- Renders on CanvasLayer 100 (above all other UI)
- Uses project's SF Mono font for consistent styling

### Files Created

| File | Purpose |
|------|---------|
| `scripts/ui/loading_screen.gd` | Visual loading screen with camping artwork |

### Files Modified

| File | Changes |
|------|---------|
| `scripts/world/obstacle_thorns.gd` | Static shared materials, reduced mesh count |
| `scripts/world/cave_entrance.gd` | Mountain structure, static shared materials, reduced mesh count |
| `scripts/world/chunk_manager.gd` | Increased spawn distances for obstacles and caves |
| `scenes/main.tscn` | Added LoadingScreen node |

---

## Session 47 - Chunk Loading Performance & Loading Screen Polish (2026-02-03)

### Critical Performance Fix: Chunk Boundary Stuttering

Fixed severe jitter/freezing that occurred every time the player crossed chunk boundaries while moving.

**Root Causes Identified and Fixed:**

1. **Redundant Noise Sampling** - Each 16x16 chunk was calling `get_height_at()` 4,000+ times for mesh generation, AO calculations, and collision.

2. **256 Collision Shapes Per Chunk** - Creating 256 individual `BoxShape3D` nodes per chunk caused major frame spikes.

3. **Synchronous Heavy Operations** - All spawning happened in a single frame when chunks loaded.

**Solutions Implemented:**

| Optimization | Before | After | Improvement |
|--------------|--------|-------|-------------|
| Height sampling | ~4,350 calls/chunk | ~324 calls/chunk | 13x reduction |
| Collision shapes | 256 BoxShape3D/chunk | 1 HeightMapShape3D/chunk | 256x reduction |
| Spawning | All in one frame | Deferred across frames | Eliminates spikes |

### Technical Details

**Height Caching** (`scripts/world/terrain_chunk.gd`):
- Pre-compute all heights into 18x18 array (16 cells + 1 border on each side)
- Cache populated once during mesh generation
- Reused for AO calculations, side faces, and collision generation
- Cleared after collision to free memory

**HeightMapShape3D Collision**:
- Single `HeightMapShape3D` per chunk instead of 256 `BoxShape3D`
- Built from same height cache used for mesh
- Properly scaled and positioned at chunk center
- Works correctly with `CharacterBody3D.move_and_slide()`

**Deferred Spawning**:
- Trees, resources, decorations, and animals spawn on subsequent frames via `call_deferred()`
- Extra frame delays using `await get_tree().process_frame` to spread load further

### Loading Screen Improvements

**Visual Polish**:
- Fixed viewport coverage (added root_control container for proper anchoring)
- Enlarged camping artwork
- Increased subtitle font size (20→42px)
- Increased progress label font size (18→36px)
- Moved title section lower for professional video game appearance

**Player Controls**:
- Disabled all input while loading screen active
- Added `_is_loading_screen_active()` check in player controller
- Prevents movement/interaction during world initialization

### Bug Fix: Ambient Animals

Fixed "Cannot call method 'look_at' on a null value" error after loading screen.
- Cause: `mesh_container` created after `await` in `_ready()`, but `_process()` could run during the await
- Fix: Create `mesh_container` before any `await` calls in `AmbientAnimalBase._ready()`

### Files Modified

| File | Changes |
|------|---------|
| `scripts/world/terrain_chunk.gd` | Height caching, HeightMapShape3D collision, deferred spawning |
| `scripts/world/chunk_manager.gd` | Reduced obstacle/cave counts for initial testing |
| `scripts/ui/loading_screen.gd` | Visual improvements, proper viewport coverage |
| `scripts/player/player_controller.gd` | Disable controls during loading screen |
| `scripts/creatures/ambient_animal_base.gd` | Fix mesh_container null error |

### Performance Results

- **Before**: Game froze for 100-200ms every ~9 steps while sprinting (chunk boundary crossing)
- **After**: Smooth gameplay with no perceptible stuttering when crossing chunk boundaries

---

## Session 48 - Mountain Biome & Ponderosa Pines (2026-02-04)

### New MOUNTAIN Biome

Added a fifth region type for dramatic alpine peaks far from spawn, creating exploration goals and elevation-based progression.

**Region Characteristics:**
| Property | Value |
|----------|-------|
| Noise threshold | > 0.6 AND > 100 units from spawn |
| Height scale | 50.0 (tallest terrain) |
| Height step | 1.5 (dramatic blocky cliffs) |
| Grass color | Alpine grey-green (0.38, 0.45, 0.35) |
| Dirt color | Mountain grey (0.42, 0.40, 0.38) |

**Vegetation Multipliers:**
| Resource | Multiplier |
|----------|------------|
| Trees | 0.8x (mostly ponderosa below treeline) |
| Rocks | 3.0x |
| Berries | 0.3x |
| Herbs | 0.5x |
| Osha Root | 2.0x (alpine specialty) |

**Terrain Generation:**
- Uses `hill_noise` at 0.8x frequency for large-scale mountain shapes
- Power curve (1.8) for dramatic peaks
- Medium-scale ridges add 8 units variation
- Detail noise adds 5 units of surface variation
- Climbing paths carved via `path_noise` (threshold 0.25)
- Minimum height 15 units

### Ponderosa Pine Trees

New tree type that grows at elevation and dominates the MOUNTAIN biome, creating realistic alpine forests.

**Visual Design** (`scenes/resources/ponderosa_pine_resource.tscn`):
- Tall straight trunk (7 units vs 5 for big oak)
- Orange-brown bark color (distinctive ponderosa look)
- Conical canopy with 5 stacked needle layers tapering to peak
- Total height: ~12 units when fully grown

**Resource Yield:**
- 5 wood, 3 branches
- 4 chops required with axe

**Spawning Rules:**
| Region | Elevation | Ponderosa Chance |
|--------|-----------|------------------|
| MOUNTAIN | < 45 units (below treeline) | 85% |
| MOUNTAIN | ≥ 45 units (above treeline) | No trees |
| Any | > 25 units | 50% (outside groves) |
| Any | > 15 units in pine grove | 70% |

**Pine Grove Clustering:**
- New `pine_grove_noise` (frequency 0.05) creates natural grove patterns
- Groves form at noise values > 0.2
- Creates realistic stands of ponderosa on hillsides

### Alpine Lakes

High-elevation lakes in MOUNTAIN regions.

**Generation Parameters:**
| Parameter | Value |
|-----------|-------|
| Count | 2 per world |
| Radius range | 12-18 units |
| Depth | 4.0 units |
| Min distance from spawn | 100 units |
| Min spacing between alpine lakes | 60 units |

**Features:**
- Marked with `is_alpine: true` flag
- Fishing available (same as regular lakes)
- Carved into mountain terrain

### Osha Root - Alpine Medicinal Plant

New resource exclusive to high-altitude areas, providing both healing and hunger restoration.

**Visual Design** (`scenes/resources/osha_root.tscn`):
- Crossed leaves (celery-like appearance)
- Visible brown root at base
- Small plant profile

**Resource Properties:**
- `resource_type: "osha_root"`
- Hand-gatherable (no tool required)
- Interaction text: "Dig"

**Spawning Rules:**
| Region | Elevation | Spawn Chance |
|--------|-----------|--------------|
| MOUNTAIN | 20-45 units | 4% (base × 2.0 mult) |
| HILLS | > 25 units | 1% (base × 0.5 mult) |
| ROCKY | > 25 units | 0.6% (base × 0.3 mult) |

**Consumption Effects:**
- Hunger restored: 20
- Health restored: 25
- Both effects apply when consumed (checks health first)

### Files Created

| File | Purpose |
|------|---------|
| `scenes/resources/ponderosa_pine_resource.tscn` | Ponderosa pine tree with conical canopy |
| `scenes/resources/osha_root.tscn` | Alpine medicinal plant |

### Files Modified

| File | Changes |
|------|---------|
| `scripts/world/chunk_manager.gd` | Added MOUNTAIN to RegionType, region parameters, alpine lake generation, pine_grove_noise, ponderosa/osha scene loading, MOUNTAIN terrain height calculation |
| `scripts/world/terrain_chunk.gd` | Ponderosa spawning with elevation/grove logic, osha root spawning, treeline mechanic, MOUNTAIN animal spawning |
| `scripts/player/player_controller.gd` | Added osha_root to FOOD_VALUES (20) and HEALING_ITEMS (25), updated footstep surface detection for MOUNTAIN |

### Gameplay Impact

**Early Exploration:**
- Mountains visible in distance, creating exploration goals
- Ponderosa pines mark transition to higher elevations

**Mid-Game:**
- Access to mountain regions for osha root (powerful healing+food)
- Alpine lakes for alternative fishing spots

**Late-Game:**
- Full mountain exploration with climbing paths
- Osha root farming for expedition supplies

---

## Session 17 - River End Bug Fix & Chunk Boundary Collision Fix (2026-02-04)

### Problem 1: River Endpoints

At river endpoints, two issues were observed:
1. Water didn't visually extend to the terrain edge
2. Player fell through "solid-looking" blocks at river ends

**Root Cause:** Mismatch between water mesh taper and terrain carving. Water mesh tapers to 10% width at ends, but terrain carving used full width, creating invisible "holes".

**Fix:** Modified `_get_river_info_at()` to include taper calculation matching the water mesh.

### Problem 2: Falling Through Terrain at Chunk Boundaries

Player fell through terrain at chunk edges (specifically at position ~94.7, -158.6).

**Root Cause:** Cache indexing bug in collision heightmap generation at chunk edges:
- Height cache was built for cell centers: `chunk_world_x + (cx-1)*3 + 1.5`
- Collision vertices at edges (x=16) sample: `chunk_world_x + 16*3 = chunk_world_x + 48`
- Cache index 16 holds height for position 46.5, not 48.0
- These snap to **different cells**, causing height mismatches at chunk boundaries
- Where chunks meet, collision surfaces had different heights, creating gaps players could fall through

**Fix:** Changed condition for cache usage from `x < _height_cache_size - 1` to `x < chunk_size_cells`. Edge vertices (x=16 or z=16) now always use `get_height_at()` directly for correct chunk boundary alignment.

### Files Modified

| File | Changes |
|------|---------|
| `scripts/world/chunk_manager.gd` | Updated `_get_river_info_at()` with taper calculation, added `_point_to_segment_distance_with_t()` helper function |
| `scripts/world/terrain_chunk.gd` | Fixed collision heightmap edge vertex heights - edge vertices now use direct `get_height_at()` instead of cache |

### Technical Details

**River taper fix:**
- `path_position` calculated from segment index + parametric t value
- Taper applied when `path_position < 8` (start) or `path_position > path_length - 8` (end)
- Taper formula: `min_width_factor + (1 - min_width_factor) * t²` where t is distance from end

**Chunk boundary fix:**
- Interior vertices (x < 16 AND z < 16): Use cache with offset `[z+1][x+1]`
- Edge vertices (x >= 16 OR z >= 16): Use `get_height_at(world_x, world_z)` directly
- This ensures adjacent chunks have matching collision heights at boundaries

### Problem 3: Cave Entrance Visual Mismatch

Large gray untextured rectangular block visible in MOUNTAIN regions looked disconnected from terrain.

**Root Cause:** Cave entrance used a uniform flat `StandardMaterial3D` with color `Color(0.4, 0.38, 0.35)` that didn't match the terrain's varied vertex-colored appearance.

**Fix:** Updated `cave_entrance.gd`:
- Changed base rock color to match ROCKY terrain: `Color(0.45, 0.42, 0.38)`
- Added `_create_tinted_rock_material()` function that creates color variations
- Each mesh piece (main mass, peak, front pieces) now gets a slightly different tint
- Tints are deterministic based on `cave_id` for consistency

### Files Modified (Session 17 continued)

| File | Changes |
|------|---------|
| `scripts/world/chunk_manager.gd` | River taper fix |
| `scripts/world/terrain_chunk.gd` | Chunk boundary collision fix |
| `scripts/world/cave_entrance.gd` | Updated rock colors to match terrain, added per-piece color variation |

---

## Session 49 - Grappling Hook Tool (2026-02-04)

**New craftable tool** for ascending steep cliff faces in MOUNTAIN and ROCKY regions. Complements rope ladders by providing active traversal rather than placed infrastructure.

### Core Mechanic

1. Equip grappling hook
2. Aim at cliff face - crosshair shows target validity (green/red/white)
3. Fire with R2/right-click
4. Player is pulled up via tween-based ascent
5. Land on top of cliff with slight forward momentum

### Crafting Recipe

| Ingredient | Quantity |
|------------|----------|
| Rope | 3 |
| Metal Ingot | 2 |
| Branch | 1 |

- Requires crafting bench
- Camp Level 2

### Technical Implementation

**Target Detection:**
- Raycast from camera to find cliff faces (vertical surfaces)
- Validates: height difference (2-15 units), horizontal range (8 units), line of sight
- Checks for valid landing zone (flat top, not water)
- Returns anchor point and calculated landing position

**Ascent Mechanics:**
- Tween-based movement (not physics) for reliability
- Smooth ease-out curve
- Player state set to `is_grappling` to disable normal movement
- Rope visual updates each frame during ascent
- Durability consumed on successful grapple (100 uses)

**Visual Feedback:**
- Color-coded targeting reticle in HUD:
  - Green: Valid target
  - Red: Invalid target (shows reason)
  - White: No target
  - Blue: Currently grappling
- Rope mesh stretches from player to anchor during ascent
- Hook visual appears at anchor point
- First-person grappling hook model when equipped

**Range Limits:**
| Dimension | Limit |
|-----------|-------|
| Vertical | 15 units |
| Horizontal | 8 units |
| Total distance | 17 units |

### Files Created

| File | Purpose |
|------|---------|
| `scripts/player/grappling_hook.gd` | Core grappling logic, target detection, ascent tween, visuals |
| `docs/GRAPPLING_HOOK_DESIGN.md` | Full design document |

### Files Modified

| File | Changes |
|------|---------|
| `scripts/player/equipment.gd` | Added grappling_hook to EQUIPPABLE_ITEMS, TOOL_MAX_DURABILITY, model creation, _use_grappling_hook() |
| `scripts/crafting/crafting_system.gd` | Added grappling_hook recipe |
| `scripts/player/player_controller.gd` | Added is_grappling state, set_grappling() function, movement override |
| `scripts/core/sfx_manager.gd` | Added grapple_fire, grapple_attach, grapple_land sound paths and cooldowns |
| `scripts/ui/hud.gd` | Added grapple targeting reticle with color-coded feedback |

### Sound Effects Needed

| Sound | Path | Description |
|-------|------|-------------|
| grapple_fire | `assets/audio/sfx/tools/grapple_fire.mp3` | Whoosh + rope sound |
| grapple_attach | `assets/audio/sfx/tools/grapple_attach.mp3` | Metal impact on stone |
| grapple_land | `assets/audio/sfx/tools/grapple_land.mp3` | Soft landing thud |

---

## Session 50 - Bug Fixes & Terrain Stability (2026-02-04)

### Bug Fixes

**Grappling Hook:**
- Fixed undefined variable bug in `get_grapple_target()` - `top_world_x`/`top_world_z` changed to `best_x`/`best_z`
- Fixed duplicate variable declaration for `anchor`

**Structure Save/Load:**
- Added `get_save_data()` and `load_save_data()` methods to `StructureBase` class
- Fixes parse error in `structure_snare_trap.gd` that was calling non-existent super methods

**Interaction System:**
- Moved interaction raycast checks before the resting/climbing/grappling early return in `_physics_process`
- Fixes bug where player couldn't pick up objects after using grappling hook

### Fall-Through Protection

Added robust terrain fall-through detection and recovery:
- Tracks last safe position when player is on floor
- Detects when player falls 3+ units below expected terrain height
- Automatically teleports player back to last safe position
- Fallback to terrain height if no safe position recorded

### Camera Improvements

- Increased camera near clip from 0.05 to 0.15 to reduce terrain clipping on steep slopes

### Mountain Terrain Stability

Reduced mountain terrain extremeness to fix geometry glitches:
- Height scale: 50 → 30
- Ridge contribution: 8 → 4
- Detail contribution: 5 → 2
- Step size: 1.5 → 1.0
- Minimum height: 15 → 10

### Files Modified

| File | Changes |
|------|---------|
| `scripts/player/grappling_hook.gd` | Fixed undefined variables in target detection |
| `scripts/campsite/structure_base.gd` | Added save/load methods |
| `scripts/player/player_controller.gd` | Added fall-through protection, fixed interaction check order |
| `scripts/world/chunk_manager.gd` | Reduced mountain terrain extremeness |
| `scenes/player/player.tscn` | Increased camera near clip |

### Known Issues (To Fix Later)

1. Camera still clips through terrain on very steep slopes (may need camera collision system)
2. Mountain terrain geometry still has some visual glitches at extreme heights
3. HeightMapShape3D creates invisible collision slopes near cliffs (fundamental Godot limitation)
4. Grappling hook landing position can be imprecise

### Debug Code to Remove

- `_debug_give_grappling_hook()` in `player_controller.gd` - auto-gives grappling hook for testing

---

## Session 51 - Mountain Terrain Fix (2026-02-05)

### Problem

Mountain terrain was unplayable due to:
- Extreme heights (36+ units vs HILLS 26 units)
- Weak path carving (40% vs HILLS 60%)
- HeightMapShape3D creates invisible collision slopes on blocky terrain
- Adjacent cells could have 10+ unit height differences causing single-cell cliffs

### Solution: Two-Pronged Fix

**1. Terrain Parameter Tuning:**

Adjusted mountain generation parameters for more reasonable terrain:

| Parameter | Before | After |
|-----------|--------|-------|
| Height scale | 30.0 | 24.0 |
| Ridge addition | 4.0 | 2.0 |
| Detail addition | 2.0 | 1.0 |
| Path carving | 0.4 | 0.55 |
| Minimum height | 10.0 | 4.0 |

Result: Max peaks ~27 units (still dramatic), clearer climbing paths.

**2. Height Difference Limiter:**

Added `_limit_height_difference()` function that caps height differences between adjacent cells at 8 units max. This prevents single-cell cliffs that cause collision issues while preserving dramatic multi-cell cliffs.

**3. Trimesh Collision for Mountains:**

For chunks containing MOUNTAIN terrain, now uses `ConcavePolygonShape3D` (trimesh) instead of `HeightMapShape3D`. This makes collision match the visual mesh exactly - no more invisible slopes causing players to slide off cliffs they should be able to stand on.

Other biomes continue to use `HeightMapShape3D` for better performance.

### Files Modified

| File | Changes |
|------|---------|
| `scripts/world/chunk_manager.gd` | Tuned 5 mountain parameters, added `_limit_height_difference()` and `_get_raw_mountain_height()` functions |
| `scripts/world/terrain_chunk.gd` | Added conditional trimesh collision for mountains via `_generate_trimesh_collision()` and `_generate_heightmap_collision()` |

### Verification Checklist

1. **Height test**: Walk to mountains, peaks should reach ~25-27 units max
2. **Path test**: Climbing paths should be clearly navigable without jumping constantly
3. **Cliff test**: No single-cell drops greater than 8 units
4. **Collision test**: Walk along cliff edges - no falling through or sliding off
5. **Visual test**: Mountains still look distinct and dramatic vs HILLS

---

## Session 52 - Performance Fix: Batched Spawning (2026-02-05)

### Problem

Game was stuttering every few seconds while walking around. The stuttering coincided with chunk loading, where all trees, resources, decorations, and animals for a chunk were being instantiated in a single frame.

### Solution: Batched Spawning System

Converted all chunk spawning from synchronous to async coroutines that yield periodically to spread work across multiple frames.

**Key Changes:**

1. **Batched Tree Spawning**: Trees now spawn in batches of 6, yielding between batches
2. **Batched Resource Spawning**: Resources spawn in batches of 10, yielding between batches
3. **Batched Decoration Spawning**: Decorations spawn in batches of 15, yielding between batches
4. **Sequential Chaining**: Spawners chain sequentially (trees → resources → decorations → animals)

**Additional Optimizations:**

| Setting | Before | After | Impact |
|---------|--------|-------|--------|
| Tree grid size | 2.5 | 3.5 | 47% fewer grid checks |
| Tree density | 0.25 | 0.30 | Compensates for larger grid |
| Resource grid size | 4.0 | 5.0 | 36% fewer grid checks |
| Target grass per chunk | 60 | 40 | 33% fewer decorations |
| Target flowers per chunk | 20 | 12 | 40% fewer decorations |

### How Batching Works

Instead of:
```
spawn_all_trees()  # 30+ instantiations in one frame -> stutter
```

Now:
```
spawn 6 trees -> yield -> spawn 6 trees -> yield -> ...
```

This spreads the CPU cost across multiple frames, eliminating visible stuttering.

### Files Modified

| File | Changes |
|------|---------|
| `scripts/world/terrain_chunk.gd` | Added batching constants, converted spawning to async coroutines with yields |
| `scripts/world/chunk_manager.gd` | Increased tree_grid_size (3.5) and tree_density (0.30) |

---

## Session 53 - Terrain Collision Fix: Height Sampling Alignment (2026-02-05)

### Problem

Players were falling through terrain, especially near water edges and terrain transitions. The root cause was a **sampling position mismatch** between the visual mesh and collision.

### Root Cause Analysis

The visual mesh samples heights at **cell centers**:
```gdscript
// Visual mesh - samples at cell centers
var world_x: float = chunk_world_x + (cx * cell_size) + cell_size / 2.0
```

But the heightmap collision was sampling at **grid vertices**:
```gdscript
// Collision (OLD BUG) - samples at grid vertices
var world_x: float = chunk_world_x + x * cell_size  // Missing center offset!
```

This meant collision heights were sampled 1 unit away from where the visual mesh sampled. At terrain transitions (water edges, cliffs), this caused the collision surface to be at a completely different height than the visible terrain.

### The Fix

Aligned heightmap collision sampling with visual mesh:

```gdscript
// Collision (FIXED) - samples at cell centers like visual mesh
var world_x: float = chunk_world_x + x * cell_size + cell_size / 2.0
var world_z: float = chunk_world_z + z * cell_size + cell_size / 2.0
```

Also adjusted heightmap position offset to match the new sampling:
```gdscript
collision_shape.position = Vector3(
    chunk_world_x + chunk_world_size / 2.0 + cell_size / 2.0,  // +0.5 cell offset
    0.0,
    chunk_world_z + chunk_world_size / 2.0 + cell_size / 2.0
)
```

### What Didn't Work

1. **Trimesh collision for all terrain** - Too expensive, caused severe stuttering
2. **Stuck detection system** - Band-aid that fired constantly, didn't fix root cause
3. **Heightmap scale adjustment** - Created worse mismatch issues

### Performance: Async Terrain Mesh Generation

Also added async terrain mesh generation to fix stuttering when chunks load:

**Before:** Terrain mesh (576 cells with triangles) generated in one frame → stutter

**After:** Mesh generation spread across 4 frames (6 rows per frame):
```gdscript
const MESH_ROWS_PER_BATCH: int = 6

func _generate_terrain_mesh_batched() -> void:
    for cz in range(chunk_size_cells):
        # ... generate row ...
        rows_this_batch += 1
        if rows_this_batch >= MESH_ROWS_PER_BATCH:
            rows_this_batch = 0
            await get_tree().process_frame
```

**New chunk generation pipeline:**
1. `_build_height_cache()` - sync (fast, needed for collision)
2. `_generate_collision_from_mesh()` - sync (player needs to walk immediately)
3. `_generate_terrain_mesh_batched()` - async (4 frames)
4. Tree/resource/decoration spawning - async (already batched)

### Additional Fix: MAX Height Sampling

HeightMapShape3D interpolates between samples, creating smooth slopes where our visual mesh has flat steps. At height transitions (cliffs, river edges), the interpolated collision can be BELOW the visual terrain, causing fall-through.

**Fix**: For each heightmap vertex, sample the MAX height of all 4 surrounding cell centers:
```gdscript
for offset in [(-0.5,-0.5), (0.5,-0.5), (-0.5,0.5), (0.5,0.5)]:
    var sample_h: float = get_height_at(world_x + offset.x * cell_size, ...)
    if sample_h > height:
        height = sample_h
```

This ensures collision is always AT or ABOVE the visual terrain.

### Emergency Recovery Loop Detection

Added detection for when fall-through recovery gets stuck in a loop (keeps recovering to same bad position). After 3 recoveries in 2 seconds, player is teleported to spawn (0, 5, 0) as emergency escape.

### Files Modified

| File | Changes |
|------|---------|
| `scripts/world/terrain_chunk.gd` | Fixed collision with MAX height sampling, async mesh generation |
| `scripts/player/player_controller.gd` | Added recovery loop detection with emergency spawn teleport |

---

## Session 54 - Minecraft-Style BoxShape3D Collision System (2026-02-05)

### Problem: HeightMapShape3D Fall-Through

Despite multiple fixes to HeightMapShape3D collision (MAX height sampling, aligned coordinates), players could still fall through terrain at height transitions. The fundamental issue: HeightMapShape3D **interpolates** between sample points, creating smooth collision surfaces that don't match our blocky visual terrain.

At cliffs and height transitions:
- Visual terrain: flat top at height 10, vertical cliff, flat top at height 5
- HeightMapShape3D: smooth slope from 10 to 5, can dip BELOW visual surface

### Solution: Per-Cell BoxShape3D (Minecraft-Style)

Replaced HeightMapShape3D with individual BoxShape3D for each terrain cell:

```gdscript
func _generate_box_collision() -> void:
    for cz in range(chunk_size_cells):
        for cx in range(chunk_size_cells):
            var height: float = _height_cache[cz + 1][cx + 1]
            if height < 0:  # Skip water
                continue

            var box: BoxShape3D = BoxShape3D.new()
            box.size = Vector3(cell_size, max(height, 0.5), cell_size)

            var collision_shape: CollisionShape3D = CollisionShape3D.new()
            collision_shape.shape = box
            collision_shape.position = Vector3(world_x, box_height / 2.0, world_z)
            terrain_collision.add_child(collision_shape)
```

**Why this works:**
- Each cell gets a box extending from y=0 to cell height
- Collision perfectly matches visual: flat top at exact cell height
- No interpolation = no invisible slopes = no fall-through
- Vertical cliff faces handled naturally (boxes don't overlap)

### Performance: Async Batching

256 boxes per chunk (16x16 cells) is more shapes than HeightMapShape3D, but:
- BoxShape3D is trivial (just an AABB)
- Godot's Jolt physics handles thousands of AABB efficiently
- Async batching spreads creation across frames:

```gdscript
const BOXES_PER_BATCH: int = 32  # Cheap AABB creation

# Yield every 32 boxes to prevent frame stutter
if boxes_this_batch >= BOXES_PER_BATCH:
    boxes_this_batch = 0
    await get_tree().process_frame
```

At 60fps: 32 boxes/frame = 8 frames = ~130ms to complete chunk collision.
Player walks from chunk edge inward, so collision is ready before they reach interior.

### Simplified Fall Recovery

With collision now matching visual terrain, the complex fall-through detection (comparing player Y to expected terrain height) is no longer needed. Simplified to emergency-only recovery:

```gdscript
func _update_fall_protection(delta: float) -> void:
    # Track safe position when on floor
    if is_on_floor() and not is_grappling:
        last_safe_position = global_position

    # Emergency recovery only for extreme cases (shouldn't trigger)
    if global_position.y < -50:
        _recover_from_fall()
```

### Code Removed

Deleted these functions (obsolete with BoxShape3D):
- `_generate_heightmap_collision()` - replaced by `_generate_box_collision()`
- `_generate_trimesh_collision()` - alternative approach, never used
- `_add_collision_side_face()` - helper for trimesh, no longer needed
- `_generate_collision()` - wrapper function, simplified away

Removed from player_controller.gd:
- Terrain height comparison logic (fall-through detection)
- Recovery loop counter system (3-recovery limit)

### Files Modified

| File | Changes |
|------|---------|
| `scripts/world/terrain_chunk.gd` | Replaced HeightMapShape3D with BoxShape3D per cell, async batching |
| `scripts/player/player_controller.gd` | Simplified fall recovery to emergency-only |

---

## Session - Fix Performance Stuttering: Batched Collision + Debug Logging (2026-02-05)

### Problem
Every few seconds, the game stuttered. Root cause: `_generate_box_collision()` in `terrain_chunk.gd` ran **synchronously**, creating 256 `CollisionShape3D` + `BoxShape3D` objects with 256 `add_child()` calls in a single frame. This happened every time the player crossed a chunk boundary.

### Changes

**Batched Collision Generation** (`terrain_chunk.gd`):
- Added `COLLISION_ROWS_PER_BATCH: int = 4` constant - yields every 4 rows (64 shapes/frame, completes in 4 frames)
- Added `_generate_box_collision_batched()` async function with safety checks for early chunk unload
- Modified `generate()` to accept `sync_collision: bool` parameter
- Modified `_generate_collision_from_mesh()` to call sync or batched version
- Player's current chunk always gets sync collision (no fall-through risk)
- Distant chunks (distance 1-2) batch collision across ~4 frames

**Performance Debug Logging** (`chunk_manager.gd`):
- Added `@export var debug_performance: bool = true` flag
- `_load_chunk()`: prints chunk coord, elapsed ms, and whether sync collision was used
- `_process_chunk_queues()`: prints queue sizes when processing
- `_process()`: warns when chunk manager work exceeds 8ms frame budget

**Debug Timing** (`terrain_chunk.gd`):
- `generate()`: times `_build_height_cache()` and collision generation separately
- `debug_performance` flag passed from chunk_manager to each terrain_chunk

**Distance-Based Sync** (`chunk_manager.gd`):
- `_load_chunk()` calculates whether chunk is the player's current chunk
- Passes `sync_collision = (chunk_coord == player_chunk)` to `chunk.generate()`
- No-player fallback sets `last_player_chunk` for consistent behavior

### Files Modified

| File | Changes |
|------|---------|
| `scripts/world/terrain_chunk.gd` | Batched collision, debug timing, `COLLISION_ROWS_PER_BATCH` constant, `debug_performance` var |
| `scripts/world/chunk_manager.gd` | Performance logging, `debug_performance` export, pass sync_collision flag to chunks |

---

## Session - Fix Performance Stuttering Phase 2: Batch Height Cache + Limit Concurrency (2026-02-05)

### Problem
Phase 1 (collision batching) eliminated collision spikes, but chunks still caused **30-55ms frame spikes**. Debug logging revealed two remaining bottlenecks:
- `_build_height_cache()`: **17-30ms** synchronous (324 `get_height_at()` calls with water body loops, river checks, multi-noise sampling)
- First mesh batch: **~24ms** because `MESH_ROWS_PER_BATCH=6` was too large
- Coroutine accumulation: multiple chunks' async batches overlapping in the same frame

### Changes

**Batched Height Cache** (`terrain_chunk.gd`):
- Added `HEIGHTCACHE_ROWS_PER_BATCH: int = 4` constant
- Added `_build_height_cache_batched()` - yields every 4 rows (72 `get_height_at()` calls per batch, ~3.8ms each)
- Sync version kept for player's chunk (needs immediate collision)

**Reduced Mesh Batch Size** (`terrain_chunk.gd`):
- Changed `MESH_ROWS_PER_BATCH` from 6 to **2** (~8ms per batch instead of ~24ms)
- Added `is_inside_tree()` safety check after mesh batch yields

**Concurrency Limiting** (`chunk_manager.gd` + `terrain_chunk.gd`):
- Added `MAX_CONCURRENT_HEAVY_GENERATIONS: int = 2` and `_active_heavy_generations` counter to chunk_manager
- Added `heavy_generation_slot_available` signal for slot release notification
- Chunks wait for a slot before starting heavy async work (height cache + mesh)
- Slots released before lighter spawning work (trees, resources, decorations)

**Restructured `generate()`** (`terrain_chunk.gd`):
- Player chunk: sync height cache + sync collision + fire-and-forget async mesh/spawning (unchanged behavior)
- Distant chunks: `_generate_async_full()` manages full pipeline with slot acquisition/release
- `is_generated` set early to prevent re-entry
- `is_inside_tree()` checks after every yield for safe cleanup

**Unload Safety** (`terrain_chunk.gd`):
- `unload()` calls `_release_generation_slot()` to prevent deadlock on mid-generation unload

### Files Modified

| File | Changes |
|------|---------|
| `scripts/world/terrain_chunk.gd` | Batched height cache, reduced mesh batch size, `_generate_async_full()`, slot management, unload cleanup |
| `scripts/world/chunk_manager.gd` | Concurrency tracking vars/signal (`MAX_CONCURRENT_HEAVY_GENERATIONS`, `_active_heavy_generations`, `heavy_generation_slot_available`) |

---

## Session 18 - Fix Grappling Hook Detection (2026-02-05)

Fixed two critical bugs that prevented the grappling hook crosshair from ever turning green on cliff faces.

### Bug 1: Cell Boundary Snapping
When the physics ray hits the side of a tall collision box (cliff face), the hit position lands right at the cell boundary (e.g., x=2.999). `get_height_at()` uses `floor(x / cell_size)` which snaps this to the **short cell in front** of the cliff instead of the tall cliff cell, returning the wrong (low) height. Fix: nudge the hit position 0.15 units into the collider before the height lookup, and if that still misses, scan forward along the horizontal look direction (up to 5 cells) to find nearby cliffs.

### Bug 2: LOS Check Blocked by Cliff's Own Collision
The line-of-sight ray from player chest to cliff top anchor always passes through the cliff's own collision geometry. The old tolerance (`anchor_dist - 2.0`) was far too small — the LOS ray hits the cliff face many units before reaching the anchor, always returning "Obstructed". Fix: check if the LOS hit is near the anchor horizontally (within 1.5 cell widths); if so, it's the cliff face itself, not an intervening obstruction.

### Additional Improvement
Changed cliff-top search to use horizontal-only forward direction (`Vector2(ray_dir.x, ray_dir.z).normalized()`) instead of the full 3D ray direction. This prevents steep upward look angles from undershooting the horizontal scan distance.

### Files Modified

| File | Changes |
|------|---------|
| `scripts/player/grappling_hook.gd` | Fixed cell boundary snapping with 0.15-unit nudge, added horizontal forward scan for cliff detection, fixed LOS check to allow cliff face hits near anchor |

---

## Session 19 - Fix Grappling Hook Terrain Clipping (2026-02-05)

Fixed a bug where using the grappling hook would pull the player through terrain geometry, trapping them underground.

### Root Cause
`_interpolate_grapple()` used a straight-line lerp from the player's start position to the cliff-top target. Since `is_grappling` disables physics processing (velocity zeroed, early return in `_physics_process`), the player's position was set directly without collision detection — so the straight-line path went right through terrain.

### Fix: Arc Path + Terrain Safety Checks
1. **Parabolic arc path**: The grapple trajectory now arcs upward, peaking 3 units above the highest point (start or target). This carries the player up and over terrain instead of through it.
2. **Terrain height clamping during interpolation**: At every interpolation step, the player's Y is clamped to at least 0.5 units above the terrain surface at their current X,Z position.
3. **Landing position terrain verification**: On grapple completion, the final landing Y is verified against actual terrain height to prevent placement underground.

### Files Modified

| File | Changes |
|------|---------|
| `scripts/player/grappling_hook.gd` | Replaced straight-line lerp with parabolic arc in `_interpolate_grapple()`, added terrain height safety checks during interpolation and on landing |

---

## Session 20 - Complete Visual Art Overhaul (2026-02-05)

Rebuilt all 3D object artwork across the entire game to match the rich, layered art style of the loading screen. The loading screen uses multi-component ColorRect layering with color gradations, texture details, highlights/shadows, and small accent elements. Applied this same philosophy to all 3D objects using layered BoxMeshes with varied materials.

### Design Philosophy
- **Multiple color shades** per object (base + dark + light + highlight) instead of single flat colors
- **Layered meshes** building up complex forms from simple primitives
- **Texture simulation** via overlapping darker/lighter strips (bark, grain, stone cracks)
- **Detail elements** that add richness (sparks, tools, lashing, flowers, eyes, berries)
- **Environmental context** (lily pads on ponds, moss on caves, mulch in gardens)

### Objects Rebuilt

**Campsite Structures** (save_load.gd):
- **Fire Pit**: 8 individual colored stones in ring, crossed logs with bark texture, layered fire (embers → deep orange → yellow → white tip), hot core, rising sparks, ground glow
- **Basic Shelter**: Canvas with seam lines and shadow underside, bark-textured poles with lashing at joints, front support sticks, leaf bed with scattered patches
- **Storage Container**: Plank grain lines, metal corner bands and reinforcements, handle with brackets, front latch, lid highlight
- **Crafting Bench**: Wood grain lines, edge banding, cross-braces, hammer and knife on surface, wear marks
- **Drying Rack**: Bark-detailed posts with forked tops, lashing at joints, hanging meat strips and herb bundles, cord details
- **Herb Garden**: Plank borders with corner posts, furrow rows in soil, 8 varied herb types with leaf clusters, flowers on select plants, mulch chips
- **Canvas Tent**: Two-tone panels (shadow/light sides), seam lines, front flaps showing dark interior, bark-detailed ridge pole, guy ropes, tent stakes, ground cloth
- **Cabin Bed**: Headboard with vertical slats and cap, footboard, side rails, sheet layer, blanket with fold and wrinkle lines, pillow with indent
- **Cabin Kitchen**: Cabinet door lines with handles, stone block lines, hearth with layered fire, cooking pot with handle, wall shelf with brackets, jars/bowls, knife

**Creatures**:
- **Bird**: Warm breast patch, lighter belly, darker crown, white eye rings with black pupils, two-tone beak (upper/lower mandible), wing tips and wing bars, tail tip, feet with toes
- **Rabbit**: Darker spine ridge, lighter belly, puffy cheeks, pink nose, eyes with pupils, whiskers, pink inner ears, front/hind paws, fluffy tail with transparency overlay, haunches

**Resource Nodes**:
- **Crystal Node**: Rock base cluster, tall central spire with bright tip, internal refraction streaks, 4 varied secondary crystals (different materials), 5 scattered ground shards
- **Rare Ore**: Multi-rock composite shape (3 overlapping rocks + base), crack fissures, 6 gold veins (varied brightness), gold nugget spots on surface
- **Fishing Spot**: Deeper water center, 8 varied shore rocks with highlights, lily pads with flower, cattail reeds at edges, richer water material
- **Fish**: Olive-green back, pale belly, silvery side stripe, head with eyes, dorsal fin, forked tail, pectoral fins, body spots/markings

**Equipment**:
- **Grappling Hook**: Detailed hub with top cap, rope attachment ring, rope end, prong shafts with hook tips and barbs, multi-material metalwork (dark/light/highlight)

**World Objects**:
- **Cave Entrance**: Rock ledge overhang, scattered boulders, stalactites, moss patches, deeper darkness interior
- **Thorns**: Leaf clusters, protruding thorn spikes, dark berries, tangled vine/branch details

### Files Modified

| File | Changes |
|------|---------|
| `scripts/core/save_load.gd` | Rebuilt all 10 structure creation functions with detailed multi-mesh artwork |
| `scripts/creatures/ambient_bird.gd` | Rebuilt `_build_mesh()` with 20+ component detailed bird |
| `scripts/creatures/ambient_rabbit.gd` | Rebuilt `_build_mesh()` with 25+ component detailed rabbit |
| `scripts/resources/crystal_node.gd` | Rebuilt `_setup_crystal_visual()` with rock base, multi-shard crystals |
| `scripts/resources/rare_ore_node.gd` | Rebuilt `_setup_ore_visual()` with composite rock, cracks, gold nuggets |
| `scripts/resources/fishing_spot.gd` | Rebuilt `_create_pond_mesh()` with shore rocks, lily pads, reeds; rebuilt `_create_fish_mesh()` with detailed anatomy |
| `scripts/player/grappling_hook.gd` | Rebuilt hook visual with hub, cap, ring, detailed prongs with barbs |
| `scripts/world/cave_entrance.gd` | Added ledge, boulders, stalactites, moss, deeper darkness |
| `scripts/world/obstacle_thorns.gd` | Added leaf clusters, thorn spikes, berries, tangled vines |

---

## Session 27 - Sync Placement System Art with Save/Load Art (2026-02-05)

### Summary
Fixed all campsite structures using outdated simple art when placed during gameplay. The detailed artwork that was added to `save_load.gd` (Session 26) was only used when loading saved games. The `placement_system.gd` still had the original basic single-box versions for all structures. Synced all 9 structure creation functions so placed structures match the detailed art.

### Structures Updated in `placement_system.gd`
- **Fire Pit**: Redesigned to elegant simplicity - 6 stones in neat ring (2 alternating shades), 2 crossed logs, 3-layer fire (base/mid/tip). Replaced overbuilt version that had 8 stones, highlights, bark stripes, log ends, charred center, 9 fire layers, sparks, ground glow (~35 meshes → ~11)
- **Basic Shelter**: Was canvas + poles only. Now has canvas shadow underside, seam lines, bark strips, lashing, leaf bed
- **Storage Container**: Was plain box + lid. Now has plank grain lines, metal corner bands, handle with brackets, latch
- **Crafting Bench**: Was tabletop + 4 legs. Now has wood grain, edge banding, cross-braces, hammer + knife on surface, wear marks
- **Drying Rack**: Was posts + uniform strips. Now has bark detail, forked tops, lashing, varied meat strips and herb bundles
- **Herb Garden**: Was border + uniform green blocks. Now has plank detail, corner posts, furrows, 8 varied herb types, leaf clusters, flowers, mulch
- **Canvas Tent**: Was panels + back wall + ridge. Now has light/shadow panel variation, seam lines, front flaps, dark interior, bark detail, guy ropes, stakes, ground cloth
- **Cabin Bed**: Was frame + blanket + pillow. Now has headboard with slats, footboard, side rails, sheet layer, blanket fold + wrinkles, pillow indent
- **Cabin Kitchen**: Was counter + stone + fire box. Now has cabinet door lines + handles, stone block lines, hearth, layered fire, cooking pot, shelf with items, knife

### Bug Fix: Structures Floating Above Ground

**Root cause**: Terrain collision boxes had a minimum height of 0.5 units, enforced via `max(height, 0.5)`. But the box was positioned from y=0 upward, putting the collision TOP at 0.5 even when the visual terrain was at y=0.0 (campsite area). The placement system raycast hit this collision surface, placing structures 0.5 units above the visible ground.

**Fix**: Changed collision box positioning so the TOP always aligns with the visual terrain height. The minimum thickness is maintained by extending the box downward underground instead of upward above the surface. Applied to both `_generate_box_collision()` (sync) and `_generate_box_collision_batched()` (async) in terrain_chunk.gd.

### Bug Fix: Save/Load Using Old Art from Stale Scene Files

**Root cause**: `_recreate_structure()` in `save_load.gd` loads from `.tscn` scene files FIRST via `ResourceLoader.exists(scene_path)`, only falling back to programmatic creation if the scene doesn't exist. Four stale `.tscn` files contained the old simple art and were overriding the detailed programmatic code:
- `scenes/campsite/structures/fire_pit.tscn`
- `scenes/campsite/structures/basic_shelter.tscn`
- `scenes/campsite/structures/crafting_bench.tscn`
- `scenes/campsite/structures/storage_container.tscn`

**Fix**: Deleted all 4 stale `.tscn` files and cleared their scene paths in `structure_data.gd`. Now all structures use the detailed programmatic `_create_structure_programmatically()` path.

### Bug Fix: Residual Structure Floating

Even after the collision box fix, structures still appeared to float slightly above the ground due to the collision surface and visual terrain surface meeting at exactly the same Y level, creating a visible seam. Added a -0.04 unit Y offset when placing structures so they sink slightly into the ground, eliminating the visual gap.

### Files Modified

| File | Changes |
|------|---------|
| `scripts/campsite/placement_system.gd` | Replaced 9 `_create_*` functions with detailed art; redesigned fire pit to elegant simplicity; added -0.04 ground sink offset |
| `scripts/core/save_load.gd` | Redesigned fire pit to match placement_system (elegant 6-stone + 3-flame version) |
| `scripts/world/terrain_chunk.gd` | Fixed collision box Y positioning so top matches visual terrain height |
| `scripts/campsite/structure_data.gd` | Cleared scene paths for fire_pit, basic_shelter, storage_container, crafting_bench |
| `scenes/campsite/structures/*.tscn` | Deleted 4 stale scene files (fire_pit, basic_shelter, crafting_bench, storage_container) |

---

## Session 55 - Cave Crash Fix & Water Collision Fix (2026-02-06)

### Cave Entry Crash Fix

**Bug**: Entering a cave crashed with "Cannot call method 'get_first_node_in_group' on a null value."

**Root Cause**: `change_scene_to_packed()` destroyed the entire main scene including the player node. The cave scene had a `PlayerSpawn` marker but no code to instantiate a player. `CaveInteriorManager` tried to find the player via `get_first_node_in_group("player")` and got null, then crashed calling methods on it.

**Fix**: Reparent the player node across scene transitions instead of letting it be destroyed:
- Before entering cave: remove player from main scene, store reference on the CaveTransition autoload
- After cave scene loads: add preserved player at `PlayerSpawn` position
- Before exiting cave: remove player from cave scene, store reference
- After main scene loads: replace the fresh player from `main.tscn` with the preserved one

This preserves all player state (inventory, stats, equipment) across both transitions without needing serialization.

### Water Collision Fix

**Bug**: Player walked on top of water instead of sinking in and swimming.

**Root Cause**: Water cells (negative terrain height) created a solid collision box filling the entire water volume from pond floor to y=0. For a pond with depth -2.5, the box extended from y=-2.5 to y=0, creating an invisible platform at the water surface. The player stood on this collision and never dropped below `water_surface_y` (0.15), so the swimming condition `global_position.y < water_surface_y` was never true.

**Fix**: Changed water cell collision from a solid volume-filling box to a thin 0.5-unit slab at the pond floor only. For depth -2.5, the slab sits at y=-2.5 to y=-2.0. Now the player falls through the water surface, the Area3D triggers `is_in_water`, and swimming activates properly. Applied to both sync and batched collision generation.

### Files Modified

| File | Changes |
|------|---------|
| `scripts/core/cave_transition.gd` | Player reparenting across scene transitions (stored_player var, updated _load_cave_scene, _return_to_overworld, _restore_player_position) |
| `scripts/world/terrain_chunk.gd` | Water cell collision: thin floor slab instead of solid volume (both _generate_box_collision and _generate_box_collision_batched) |

---

### Rope Ladder Placement Fix

**Bug**: Rope ladders couldn't be placed near 2-block high obstacles. The preview would turn red (invalid) or the ladder height would be miscalculated.

**Root Causes** (three interrelated problems):

1. **Preview landed on top of cliff**: The grid-snapped preview position used `_get_ground_height()` which could return the cliff top, not the base. Cliff detection then ran from on top of the cliff where there's no cliff face ahead → validation failed.

2. **Single-height cliff detection**: `_has_cliff_face()` cast one ray at y+1.0, which could miss short (2-block) cliffs depending on exact positioning.

3. **Gaps in height sampling**: `_calculate_cliff_height()` sampled at irregular intervals `[1, 2, 3, 4, 5, 6, 8, 10, 12, 15]` with gaps that could miscalculate short cliffs. The horizontal ray reach of 2.0 units was also too short.

**Fixes**:
1. **Preview base snapping**: For rope ladders, compare the preview ground height with the player's ground height. If the preview is >0.5 units higher (on top of the cliff), snap the preview down to the player's ground level.
2. **Multi-height cliff detection**: `_has_cliff_face()` now checks at three heights (0.3, 0.8, 1.5) to catch both short and tall cliffs.
3. **Consistent height sampling**: `_calculate_cliff_height()` now uses uniform 1.0-unit steps from 1 to 15, and extended horizontal ray reach from 2.0 to 3.0 units.
4. **Multi-height cliff snapping**: `_snap_to_cliff_face()` now tries three heights (0.5, 1.0, 1.5) to find the cliff face.

### Files Modified

| File | Changes |
|------|---------|
| `scripts/campsite/placement_system.gd` | Rope ladder preview base-snapping, multi-height cliff detection, consistent height sampling, multi-height cliff snapping |

---

### Cave System Polish (3 fixes)

**Bug 1: Interaction from side walls** - Player could trigger "Enter Cave" from anywhere they could raycast to the rock mass collision, even the side walls.

**Fix**: Added `_is_near_cave_mouth()` check in `cave_entrance.gd`. Uses `to_local()` to convert the player position to the entrance's local space and checks they're in front of the dark opening (within 4 units horizontal, between z=0 and z=8). Both `interact()` and `get_interaction_text()` now return empty/false when the player isn't near the mouth.

**Bug 2: No HUD in cave scene** - The cave interior had no HUD, so the player couldn't see inventory, equipment, stats, or interaction prompts.

**Fix**: The HUD is now reparented alongside the player during cave transitions. On cave entry, both Player and HUD are removed from the main scene before `change_scene_to_packed()`, then added to the cave scene. On cave exit, both are removed from cave and restored to the main scene, replacing the fresh instances from `main.tscn`. The HUD's existing signal connections to the player's child nodes (Inventory, Equipment, PlayerStats) remain valid since both nodes are preserved.

**Bug 3: Exiting cave reset all game state** - Loading a fresh `main.tscn` on exit reset campsite level, structures, time, weather, etc.

**Fix**: Three-part solution:
1. **Auto-save on entry**: Before entering cave, `save_game()` is called to capture all world state
2. **Pending load on exit**: `GameState.set_pending_load_slot(1)` triggers SaveLoad's `_check_pending_load()` in the fresh main scene, which restores campsite level, structures, time, weather, etc.
3. **Skip player data**: `GameState.skip_player_data_on_load` flag tells SaveLoad to skip player data restoration so the preserved player keeps any items gained in the cave

**Also fixed**: `_load_cave_scene()` null crash - added second `await process_frame` before accessing `tree.current_scene` (Godot's `change_scene_to_packed()` is deferred).

### Files Modified

| File | Changes |
|------|---------|
| `scripts/core/cave_transition.gd` | HUD reparenting, cave autosave before entry, pending autosave load on exit, null safety |
| `scripts/world/cave_entrance.gd` | `_is_near_cave_mouth()` proximity check for interaction |
| `scripts/core/game_state.gd` | Added `skip_player_data_on_load` and `pending_cave_autosave` flags |
| `scripts/core/save_load.gd` | `save_cave_autosave()` / `load_cave_autosave()` using temp file, skip player data flag in `_apply_save_data()` |

---

## Session 22 - Cave Entrance Redesign (2026-02-06)

### Overview
Complete redesign of cave entrances to be low-profile hillside mounds instead of giant rectangular blocks. Added terrain flattening around caves so players can walk to the entrance on foot without a rope ladder. Fixed collision to prevent falling through the top and walking through walls, while leaving an open gap for the entrance mouth.

### Terrain Flattening (`chunk_manager.gd`)
- Added cave position terrain flattening in `get_height_at()`, similar to existing spawn flattening
- **Inner radius (8 units)**: Flat platform at height 2.0 around each cave center
- **Outer falloff (8-12 units)**: Smooth ramp from platform height to natural terrain height
- Creates a walkable approach from any direction, even on steep ROCKY/HILLS terrain

### Cave Spawn Rules (`chunk_manager.gd`)
- Caves now spawn in both ROCKY and HILLS regions (was ROCKY-only) - terrain flattening makes both walkable
- Reduced `cave_spawn_min_distance` from 110 to 85 units so caves are reachable sooner

### New Cave Visual (`cave_entrance.gd`)
- **Low-profile mound**: Main body is 12x6x10 (was 14x12x12), total height ~8 units (was ~16)
- **Shoulder pieces**: Two boxes flanking the entrance, angled outward for natural rock look
- **Cap/peak**: Small angled box on top instead of a towering peak
- **Dark opening**: 4x4 at ground level (y=2.0), easily visible and walkable into
- Kept decorative boulders, stalactites, moss patches (rescaled to fit lower profile)
- Updated all shared static meshes to new sizes

### Collision with Entrance Gap
Replaced 2 solid boxes (which blocked the entrance and let player walk on top) with 4 pieces:
- **Back mass**: Behind the entrance opening
- **Left/Right walls**: Flanking the 4-unit entrance gap
- **Top cap**: Above the entrance opening
- 4-unit-wide x 4-unit-tall gap at center front allows walking in

### Tighter Interaction Zone
- Horizontal distance reduced from 4.0 to 2.5 units
- Z range tightened from (0, 8) to (0.5, 4.0)
- Added vertical check: `y < 4.0` prevents triggering from on top of cave

### Files Modified

| File | Changes |
|------|---------|
| `scripts/world/chunk_manager.gd` | Cave terrain flattening in `get_height_at()`, HILLS region allowed in `_generate_cave_entrances()`, reduced `cave_spawn_min_distance` to 85 |
| `scripts/world/cave_entrance.gd` | Complete visual redesign as low-profile mound, collision with entrance gap, tighter `_is_near_cave_mouth()` |

---

## Session 23 - Cave Interior Bug Fixes (2026-02-06)

### Overview
Fixed four bugs with cave interiors: entrance interaction triggering from wrong positions, placed torches not emitting light, HUD/menus invisible in darkness, and pause menu not working.

### Bug 1: Cave entrance interaction while facing a wall
**Problem**: "Enter Cave" prompt appeared when near the entrance but facing a wall, not the opening.
**Fix**: Added facing direction check to `_is_near_cave_mouth()`. Now uses dot product between player's forward vector and direction to entrance center. Requires `dot > 0.3` (~73 degrees of facing), so the player must be roughly looking toward the entrance.

### Bug 2: Placed torch doesn't emit light in cave
**Problem**: Placing a torch unequips it. CaveInteriorManager only checked equipped items for light, so it applied the 95% opacity darkness overlay, hiding the 3D torch light.
**Fix**: Added `_has_placed_light_nearby()` to CaveInteriorManager that scans scene children for StaticBody3D nodes with a "TorchLight" OmniLight3D child. If any placed torch exists, the cave is considered lit.

### Bug 3: HUD/menus invisible in cave darkness
**Problem**: DarknessOverlay CanvasLayer at layer 50 covered the HUD (default layer 1). Unequipping a torch made everything black including inventory, equipment, and crafting menus.
**Fix**: Set HUD CanvasLayer to layer 60 (above darkness overlay). PauseMenu was already at layer 100.

### Bug 4: Cannot pause inside cave
**Problem**: PauseMenu is part of main.tscn and gets destroyed during cave scene transition. ESC key did nothing in caves.
**Fix**: Preserve PauseMenu across cave transitions alongside Player and HUD. Added `stored_pause_menu` to CaveTransition autoload, with store/restore logic in both `_load_cave_scene()` and `_return_to_overworld()`.

### Bug 5: Placed torches lost on save/load
**Problem**: `_create_structure_programmatically()` in save_load.gd had no case for "placed_torch", so placed torches weren't recreated when loading a save.
**Fix**: Added `_create_placed_torch()` function to save_load.gd matching the placement_system version (handle, wrap, flame, inner flame, OmniLight3D with flicker).

### Files Modified

| File | Changes |
|------|---------|
| `scripts/world/cave_entrance.gd` | Facing direction check in `_is_near_cave_mouth()` |
| `scripts/caves/cave_interior_manager.gd` | `_has_placed_light_nearby()` for placed torch detection |
| `scenes/ui/hud.tscn` | CanvasLayer layer set to 60 |
| `scripts/core/cave_transition.gd` | PauseMenu store/restore across transitions |
| `scripts/core/save_load.gd` | `_create_placed_torch()` for save/load persistence |

---

## Session 24 - Cave Entrance Visual Redesign v2 (2026-02-06)

### Problem
Cave entrance was a massive grey rectangular structure (12x6x10 mound body + 4x4.5x6 shoulders + 7x3x6 cap) that just looked like a giant grey wall. The dark opening was hidden behind all this geometry. Camera could clip through the rock when approaching.

### Fix
Completely replaced the massive mound design with a minimal rock archway:
- **Dark opening is the dominant visual**: 3.5x3.5 dark rectangle is the first thing you see
- **Rock arch frame**: Two thin pillars (1.5x3.5x1.5) and a lintel (5.5x1.5x1.8) framing the opening
- **Small overhang**: 4.0x0.6x1.2 ledge jutting forward above the opening
- **Thin back wall**: 5.0x4.5x0.5 behind the opening for depth illusion
- **Total footprint**: ~5.5 wide, ~5 tall, ~2.5 deep (was ~12x8x10)
- Collision matches just the arch frame pieces, no massive invisible boxes

### Files Modified

| File | Changes |
|------|---------|
| `scripts/world/cave_entrance.gd` | Complete rewrite - minimal rock arch instead of massive mound structure |

---

## Session - Torch Instant Placement Refactor

### Features Implemented

**Instant torch placement** - Torches now place instantly with one button press instead of entering a preview placement mode:

1. **`place_torch_instant()` in PlacementSystem** - New function that calculates position 3m in front of player, snaps to grid, gets ground height, creates and places torch in one step. No preview, no confirmation needed.

2. **Interact button (E/L2) places torches** - When pressing interact with no target and a torch equipped, the torch is instantly placed on the ground ahead of the player.

3. **Use equipped (R/R2) also places torches** - The `_place_item()` function in Equipment now short-circuits to instant placement for torches, keeping R/R2 as a working alternative.

4. **Updated HUD hints** - Equipped torch display now shows `[E place, Q unequip]` (keyboard) or `[L2 place, ○ unequip]` (controller) instead of the old R/R2 hint.

5. **Removed Move option for torches** - Placed torches no longer show `[M] Move` in the interaction prompt. They only show `[E] Pick Up Torch`.

6. **Blocked move action for torches** - Pressing M while looking at a placed torch does nothing (defensive guard in `_try_move_structure()`).

### Files Modified

| File | Changes |
|------|---------|
| `scripts/campsite/placement_system.gd` | Added `place_torch_instant()` function for one-step torch placement |
| `scripts/player/player_controller.gd` | `_try_interact()` places torch when no target; `_try_move_structure()` blocks torch moves |
| `scripts/player/equipment.gd` | `_place_item()` routes torch to instant placement instead of preview mode |
| `scripts/ui/hud.gd` | Torch shows interact key hint; placed torches excluded from Move prompt |

---

## Session - Compass & Lodestone Navigation System (2026-02-06)

### Overview
Added a compass + lodestone navigation system. Rare ore (mined in caves) can now be crafted into a compass and lodestone beacon. When both are active, a directional HUD indicator shows an arrow pointing toward the lodestone with distance, helping players navigate back to their beacon.

### Features Implemented

1. **Compass & Lodestone crafting recipe** - Requires 2x rare_ore, 1x metal_ingot, 1x crystal at a crafting bench (camp level 3). Produces both a `compass` (passive inventory item) and a `lodestone` (placeable item).

2. **Lodestone structure** - A dark magnetic rock with golden emissive veins and a subtle warm glow light. Can be placed instantly (same pattern as torches) and picked up by interacting with it (E key).

3. **Compass HUD indicator** - Small panel on the left side below the stats panel showing directional arrow and distance to lodestone (e.g., `Lodestone  ↗  42m`). Uses 8 unicode arrows for cardinal/ordinal directions. Only visible when compass is in inventory AND lodestone is placed. Direction is calculated on the XZ plane using camera forward vector.

4. **Lodestone instant placement** - Equip lodestone and press R to place 3m in front of player (grid-snapped, terrain-height-adjusted). Same one-press pattern as torch placement.

5. **Lodestone pick-up** - Interact with placed lodestone to reclaim it. Excluded from structure move system (pick-up only, like torches).

### Files Modified

| File | Changes |
|------|---------|
| `scripts/crafting/crafting_system.gd` | Added compass recipe; craft() gives bonus lodestone on compass craft |
| `scripts/campsite/structure_data.gd` | Added lodestone to STRUCTURES dict and PLACEABLE_ITEMS array |
| `scripts/player/equipment.gd` | Added lodestone to EQUIPPABLE_ITEMS (slot 23); instant placement in _place_item() |
| `scripts/core/save_load.gd` | Added lodestone case to _create_structure_programmatically(); added _create_lodestone() mesh function |
| `scripts/campsite/placement_system.gd` | Added place_lodestone_instant() and _create_lodestone() mesh function |
| `scripts/ui/hud.gd` | Added compass panel creation, direction calculation, and throttled compass update; excluded lodestone from Move prompt |

### Files Created

| File | Description |
|------|-------------|
| `scripts/campsite/structure_lodestone.gd` | StructureLodestone class extending StructureBase - pick-up interaction, campsite unregister |

---

## Session 36 - Config Menu Cleanup & Torch Placement Fix (2026-02-06)

### Overview
Fixed several config menu UI issues (controller navigation, font consistency, duplicate buttons, hint text) and fixed torch/lodestone placement clipping under terrain at step boundaries.

### Features Implemented

1. **Config menu: removed duplicate Save/Load buttons** - Save and Load were already accessible from the main pause menu; removed the buttons, status label, and related signal handlers from the config menu to reduce clutter.

2. **Config menu: UI Scale now controller-navigable** - The UI Scale slider was not selectable with D-pad because `_build_focusable_controls()` ran before the slider was created. Fixed by rebuilding the focusable controls list after UI Scale creation.

3. **Config menu: UI Scale font size matched** - Changed UI Scale label from 24px to 32px and value label from 24px to 28px, matching all other config menu items.

4. **Config menu: combined close hint** - Updated hint label from keyboard-only "Press TAB to close" to show both input methods: "Press TAB or B to close" (keyboard mode) / "↑↓ Navigate ←→ Adjust A Select B/TAB Close" (controller mode). Increased hint font size from 26px to 32px.

5. **Torch/lodestone placement: snap to terrain cell centers** - Changed grid snap from 1.0m (arbitrary) to 3.0m terrain cell centers using `(floor(x / cell_size) + 0.5) * cell_size`. This ensures objects always land on the center top of a terrain block, not on edges or between blocks.

6. **Torch/lodestone placement: authoritative height lookup** - Replaced physics raycast (`_get_ground_height`) with `ChunkManager.get_height_at()` for Y positioning. The raycast could return incorrect heights at terrain step boundaries where collision box edges meet, causing objects to clip under terrain. The ChunkManager function returns the exact mathematical block height.

### Files Modified

| File | Changes |
|------|---------|
| `scenes/ui/config_menu.tscn` | Removed SaveLoadContainer, SaveButton, LoadButton, SaveStatusLabel, HSeparator5; increased HintLabel font_size to 32 |
| `scripts/ui/config_menu.gd` | Removed save/load button refs and signal handlers; fixed UI Scale font sizes; changed insertion point to before hint separator; added `_build_focusable_controls()` call after UI Scale creation; updated hint text for both input devices |
| `scripts/campsite/placement_system.gd` | Added `chunk_manager` reference (found via Main node); torch and lodestone snap to terrain cell centers; use `chunk_manager.get_height_at()` for authoritative block height |

---

## Session 37 - Music Toggle, Torch Elevation, Pit Prevention & Sleep Fix (2026-02-06)

### Overview
Fixed music toggle race condition, restricted torch placement to same elevation, prevented inescapable terrain pits, added cave-aware torch placement, and fixed canvas tent / cabin bed not advancing days.

### Features Implemented

1. **Music toggle fix** - Toggling music off then on failed because the 1-second fade-out tween's `stop()` callback fired after re-enabling. Fixed by tracking the fade tween and killing it on re-enable before starting fresh playback.

2. **Torch placement: same-elevation restriction** - Torches now only place on terrain at the same elevation as the player (±1.5 block height tolerance). Prevents torches from landing on mountain peaks or in valleys when the forward projection crosses an elevation change.

3. **Torch placement: cave-aware logic** - In caves, `ChunkManager` is freed (overworld unloaded). Fixed by using `is_instance_valid(chunk_manager)` instead of truthiness check. Cave placement uses 1.0m grid snap, raycasts from player height + 2 (below ceiling, above floor), and skips the same-elevation check (cave floors are flat).

4. **Terrain pit prevention** - Rocky/hilly terrain could generate isolated low cells creating inescapable pits. Added universal pit prevention at the end of `get_height_at()`: no cell may be more than 1 block below ALL its cardinal neighbors. Uses recursive neighbor check with a `_in_pit_check` guard flag to prevent infinite recursion.

5. **Canvas tent & cabin bed day advancement fix** - Both `structure_canvas_tent.gd` and `cabin_bed.gd` overrode `_skip_to_dawn()` but forgot to increment `time_manager.current_day` and emit `day_changed`. This caused "Day 3/3" at camp level 2 to never advance, blocking level 3 progression. Fixed both to match the parent shelter's behavior.

### Files Modified

| File | Changes |
|------|---------|
| `scripts/core/music_manager.gd` | Added `fade_tween` tracking; kill pending fade on re-enable in `set_music_enabled()` |
| `scripts/campsite/placement_system.gd` | Added overworld/cave branching with `is_instance_valid()`; same-elevation check (1.5 threshold) in overworld; cave-specific raycast from player height |
| `scripts/world/chunk_manager.gd` | Added universal pit prevention in `get_height_at()` with `_in_pit_check` recursion guard |
| `scripts/campsite/structure_canvas_tent.gd` | Added `current_day += 1` and `day_changed.emit()` to `_skip_to_dawn()` |
| `scripts/campsite/cabin_bed.gd` | Added `current_day += 1` and `day_changed.emit()` to `_skip_to_dawn()` |
| `scripts/core/save_load.gd` | Added `day` to time data save/load; emit `day_changed` on load |

---

## Session 24 - Cave Crash Fix & Cave Resource Respawn Cooldown (2026-02-06)

### Cave Crash Fix

**Problem**: Game occasionally crashed when the player entered a cave due to timing race conditions during scene transitions.

**Root Cause**: `CaveInteriorManager._ready()` used `await get_tree().process_frame` which created a race condition with `CaveTransition` adding the player to the cave scene. The order of coroutine resumption was non-deterministic, causing null reference errors. Additionally, double-clicking the cave entrance could trigger two transitions simultaneously.

**Fixes**:
- Replaced `await` calls in `CaveInteriorManager._ready()` and `_setup_references()` with `call_deferred()` for deterministic initialization
- Added `_setup_complete` flag to prevent `_process()` from running before setup finishes
- Added `_transitioning` guard in `CaveTransition` to prevent double entry/exit
- Fixed error path in `_load_cave_scene()` that destructively freed the player/HUD on failure - now attempts to return to overworld instead
- Fixed `_show_notification()` HUD lookup to use `get_tree().current_scene` instead of hardcoded paths

### Cave Resource Respawn Cooldown

**Problem**: Cave resources (crystals, iron ore, rare ore) respawned every time the player entered/exited the cave, allowing infinite accumulation. Resources were never registered with `ResourceManager` since it only discovers overworld resources.

**Fix**: Added persistent cave resource depletion tracking to `CaveTransition` (autoload singleton that survives scene transitions):
- `cave_resource_state` dictionary tracks depleted resources per cave ID with timestamps
- On cave entry, `CaveInteriorManager._setup_cave_resources()` checks tracked state and marks resources as depleted if their 6-hour respawn timer hasn't elapsed
- On resource depletion, `_on_cave_resource_depleted()` records the event to CaveTransition
- Game time is snapshotted in `CaveTransition.entry_game_*` before the overworld scene is destroyed (since TimeManager lives in the overworld)
- State is included in save/load via `CaveTransition.get_save_data()`/`load_save_data()`

### Files Modified

| File | Changes |
|------|---------|
| `scripts/caves/cave_interior_manager.gd` | Removed awaits, added `_setup_complete` flag, added `_setup_cave_resources()` and `_on_cave_resource_depleted()`, fixed HUD lookup |
| `scripts/core/cave_transition.gd` | Added `_transitioning` guard, time snapshot on entry, `cave_resource_state` tracking with `track_cave_resource_depleted()` and `get_depleted_cave_resources()`, included in save/load |

---

## Session 133 - Regression Test Suite & Fall Recovery Fix (2026-02-07)

### Fall Recovery Fix
Fixed edge case in `_recover_from_fall()` where `Vector3.ZERO` was used as a sentinel for "no safe position recorded". Since the campsite is at world origin (0,0,0), players at the campsite would fail the check. Added `_has_safe_position: bool` flag to track whether a safe position has been recorded.

### Regression Test Suite
Created comprehensive automated test suite (493 tests across 7 test files) that runs headless:
```
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --script tests/run_all_tests.gd
```

**Test Coverage:**
- **Inventory** (23 tests): add/remove/has_item/clear, edge cases (zero/negative), copy safety
- **Crafting** (177 tests): recipe field validation, material checks, bench/camp-level requirements, input consumption, output production, compass+lodestone special case, all recipes discoverable
- **TerrainCollision** (52 tests): box geometry for normal/water/zero-height terrain, minimum box height, cell coverage gaps, chunk boundary contiguity, pit prevention logic, height cache border
- **StructureData** (143 tests): footprint validation, item-to-structure roundtrip, spacing rules, structure count (15), cabin largest/torch smallest, camp level requirements
- **CaveTransition** (21 tests): resource respawn timing (6-hour threshold, cross-day, exact boundary), duplicate tracking, save data roundtrip, double entry guard, scene path existence, exit position offset
- **SaveLoad** (44 tests): inventory/position/structure JSON roundtrip, field presence, version, time field ranges, float precision
- **UIConstants** (33 tests): font size tier ranges, panel background color, text colors (gold/green/red/grey), font resource existence, tier non-overlap

### Files Created/Modified

| File | Changes |
|------|---------|
| `tests/test_base.gd` | New - lightweight test framework with assert helpers |
| `tests/run_all_tests.gd` | New - SceneTree-based test runner |
| `tests/test_inventory.gd` | New - 13 test functions |
| `tests/test_crafting.gd` | New - 13 test functions |
| `tests/test_terrain_collision.gd` | New - 12 test functions |
| `tests/test_structure_data.gd` | New - 12 test functions |
| `tests/test_cave_transition.gd` | New - 10 test functions |
| `tests/test_save_load.gd` | New - 10 test functions |
| `tests/test_ui_constants.gd` | New - 12 test functions |
| `scripts/player/player_controller.gd` | Fixed Vector3.ZERO sentinel in fall recovery |
| `CLAUDE.md` | Added Regression Tests section under Workflow |

---

## Session - Convert Caves to Inline Terrain Features (2026-02-07)

**Major architectural change**: Replaced scene-based cave system with Minecraft-style inline caves built directly in the overworld. No more scene transitions, autosaves, or interaction prompts.

### What Changed

**Cave Structure** (`scripts/world/cave_entrance.gd`):
- Complete rewrite from entrance-only visual to full walkable tunnel (6-wide x 5-tall x 18-deep)
- Tunnel has segmented walls, ceiling, floor, back wall, stalactites, wall outcrops, floor rubble, stalagmites
- Area3D detects player entry/exit and notifies CaveTransition
- Spawns 2 CrystalNodes + 1 RareOreNode inside cave
- Applies saved depleted resource state on ready
- Removed `interact()`, `get_interaction_text()`, interactable group - player walks in freely
- Kept `cave_entrance` group for terrain flattening
- Uses shared static materials for tunnel walls/ceiling/floor

**Cave Transition** (`scripts/core/cave_transition.gd`):
- Stripped from 514 lines to ~200 lines - now a pure state manager
- Removed all scene transition code: `enter_cave()`, `exit_cave()`, `_load_cave_scene()`, `_return_to_overworld()`, `_restore_player_position()`, `_show_placeholder_cave()`, `_fade_back()`
- Removed stored player/HUD/PauseMenu preservation, return position tracking, overworld seed storage
- Added `player_entered_cave()` / `player_exited_cave()` for Area3D callbacks
- Added inline darkness system (from cave_interior_manager): light checking every 0.5s, 95% darkness overlay, damage after 60s in darkness (2 HP / 10s)
- Changed resource respawn from 6 hours to 72 hours (3 game days)
- Simplified save data to just `cave_resource_state`

**Terrain Flattening** (`scripts/world/chunk_manager.gd`):
- Increased `cave_flat_inner` from 8.0 to 16.0 (covers full cave depth)
- Increased `cave_flat_outer` from 12.0 to 22.0 (gradual ramp around cave)

**Save/Load Cleanup** (`scripts/core/save_load.gd`):
- Removed `CAVE_AUTOSAVE_FILE` constant
- Removed `save_cave_autosave()`, `has_cave_autosave()`, `load_cave_autosave()` functions
- Removed cave autosave pending check in `_check_pending_load()`
- Removed `skip_player_data_on_load` check in `_apply_save_data()`

**Game State Cleanup** (`scripts/core/game_state.gd`):
- Removed `skip_player_data_on_load` and `pending_cave_autosave` variables

**Deleted Files**:
- `scripts/caves/cave_interior_manager.gd` (423 lines)
- `scenes/caves/cave_interior_small.tscn`

**Tests** (`tests/test_cave_transition.gd`):
- Updated respawn threshold from 6h to 72h
- Added `test_resource_respawn_72h_boundary` (71h59m vs 72h01m)
- Removed `test_cave_scene_paths_exist`, `test_exit_position_offset`, `test_double_entry_guard` (no longer relevant)
- Updated `test_save_data_roundtrip` for simplified save format

**Validation** (`validation/check_scene.gd`):
- New headless validation script checks script loading, deleted file absence, and CaveTransition API correctness

### Test Results
- All 488 regression tests pass (was 493 - removed 5 scene-transition-specific tests, added 3 new inline-cave tests)

| File | Changes |
|------|---------|
| `scripts/world/cave_entrance.gd` | Major rewrite - full walkable tunnel with resources |
| `scripts/core/cave_transition.gd` | Major simplification - state manager with darkness |
| `scripts/world/chunk_manager.gd` | Terrain flattening radius 8→16 / 12→22 |
| `scripts/core/save_load.gd` | Removed cave autosave system |
| `scripts/core/game_state.gd` | Removed cave pending vars |
| `tests/test_cave_transition.gd` | Updated for 72h respawn, removed scene tests |
| `validation/check_scene.gd` | New - headless cave system validation |
| `scripts/caves/cave_interior_manager.gd` | Deleted |
| `scenes/caves/cave_interior_small.tscn` | Deleted |

---

## Session - Bug Fix Batch (2026-02-07)

**Six gameplay bug fixes** reported by players during play-testing.

### Thorn Bush Obstacle Rework

**Problem**: Thorn bushes were `StaticBody3D` walls that players could clip through, and the hard-wall mechanic didn't make gameplay sense for thorns.

**Fix**: Converted thorns from a blocking wall to a damage + slow zone:
- Disabled `StaticBody3D` collision (layer/mask set to 0)
- Added `Area3D` detection zone for player entry/exit
- Players inside thorns take **1 HP damage every 0.5 seconds** (2 HP/s effective)
- Movement slowed to **40% speed** while inside thorns
- Added `set_thorn_slow()` method to player controller
- Machete clearing mechanic unchanged (3 chops to clear)
- Slow effect removed immediately when cleared or when player exits

**Files Modified**: `scripts/world/obstacle_thorns.gd`, `scripts/player/player_controller.gd`

### Iron Ore Harvest Sound

**Problem**: Harvesting iron ore played the `tree_fall` sound effect, which makes no sense for mining ore.

**Cause**: `_complete_harvest()` in `resource_node.gd` played `tree_fall` for any resource with `chops_required > 1`. Iron ore has `chops_required = 5`.

**Fix**: Changed the condition to check resource type instead of chop count:
- `resource_type == "wood"` or `secondary_resource_type == "branch"` → play `tree_fall`
- Everything else → play `pickup`

**Files Modified**: `scripts/resources/resource_node.gd`

### Footstep Sounds Against Walls

**Problem**: Footstep sounds played when the player walked into a wall and couldn't actually move.

**Cause**: Footsteps triggered based on **input direction** (`direction.length() > 0`) before `move_and_slide()`, not actual movement. When blocked by a wall, velocity is zeroed by collision resolution but footsteps had already been triggered.

**Fix**: Moved footstep logic to **after** `move_and_slide()` in `_physics_process()`:
- Checks actual horizontal velocity (`Vector2(velocity.x, velocity.z).length() > 0.5`)
- Covers both walking and swimming in one location
- Removed old input-based footstep calls from `_process_normal_movement()` and `_process_swimming()`

**Files Modified**: `scripts/player/player_controller.gd`

### Floating Structures on Load

**Problem**: Structures placed far from spawn could float above the ground after saving and loading.

**Cause**: Structures were loaded with their saved Y position directly, while terrain height at distant locations can vary slightly between sessions. The player's Y was already recalculated from terrain on load, but structures were not.

**Fix**: Added terrain height recalculation in `_recreate_structure()`:
```gdscript
if chunk_manager and chunk_manager.has_method("get_height_at"):
    var terrain_y: float = chunk_manager.get_height_at(pos.x, pos.z)
    pos.y = terrain_y
```

**Files Modified**: `scripts/core/save_load.gd`

### Structure Rotation Not Persisted

**Problem**: Shelters, tents, and cabins would face random directions after saving and loading instead of keeping their door oriented toward the player.

**Cause**: Structure rotation was never saved. Only `type` and `position` were stored. On load, structures were recreated with default rotation (0,0,0), so doors faced world +Z regardless of original placement orientation.

**Fix**:
- **Save**: Added `"rotation_y": structure.rotation.y` to structure save data
- **Load**: Restore `structure.rotation.y` from saved data
- Old saves without `rotation_y` gracefully default to 0

**Files Modified**: `scripts/core/save_load.gd`

### Torch/Lodestone Placement Offset

**Problem**: Torches and lodestones placed one block ahead of where the camera crosshair was pointing.

**Cause**: Placement used the camera's forward direction **flattened to horizontal** and projected 3m from the **player's feet**, ignoring camera pitch entirely. Combined with 3m cell grid snapping, the placement consistently overshot.

**Fix**: Added `_get_crosshair_terrain_hit()` — a physics raycast from the camera along its actual look direction (including pitch). Torch/lodestone now places where the crosshair hits terrain. Falls back to the old forward projection if the crosshair doesn't hit terrain within range (e.g., looking at the sky).

**Files Modified**: `scripts/campsite/placement_system.gd`

### Files Modified

| File | Changes |
|------|---------|
| `scripts/world/obstacle_thorns.gd` | Converted from blocking wall to Area3D damage+slow zone |
| `scripts/resources/resource_node.gd` | Fixed harvest sound: tree_fall only for trees, pickup for ore |
| `scripts/player/player_controller.gd` | Post-collision footsteps, thorn slow support |
| `scripts/core/save_load.gd` | Recalculate structure Y on load, save/restore rotation_y |
| `scripts/campsite/placement_system.gd` | Crosshair raycast for torch/lodestone placement |

### Test Results
- All 488 regression tests pass

---

## Session 29 - Cave Entrance Fixes (2026-02-07)

### Bug 1: Cave Entrance Invisible / Properties Not Set

**Symptom**: Player traveled to logged cave entrance location but found nothing visible.

**Cause**: `_spawn_cave_entrance()` in `chunk_manager.gd` used `if "cave_id" in entrance:` to conditionally set properties after `set_script()`. The GDScript `in` operator on Objects after `set_script()` is fragile and may fail to detect `@export` properties, leaving `cave_id` at default 0 and `cave_type` at "small". While the geometry should still render with default values, the pattern is incorrect and was replaced with direct assignment. Also changed `global_position` to `position` (local) since the parent Terrain node is at origin.

**Fix**: Direct property assignment without `in` checks. Added diagnostic print in `_setup_visuals()` to log cave_id, type, and position when visuals are built.

### Bug 2: Inescapable Hole Near Cave Entrances

**Symptom**: Player fell into a pit near cave entrance at (-140.5, 3.0, 125.5) and could not escape. Distance from cave center was ~15.7 units, right at the cave platform edge.

**Cause**: The terrain ramp from cave platform (y=2.0) to natural ROCKY/HILLS terrain (y=10-20+) transitioned over only 6 units (`cave_flat_outer=22` minus `cave_flat_inner=16`). With cell_size=3.0, this created 2-cell transitions with 5-10 unit height jumps — unclimbable walls surrounding the cave platform like a bowl.

**Fix**: Three changes to `get_height_at()`:
1. **Widened ramp**: `cave_flat_outer` increased from 22 to 46 (30-unit transition zone, ~10 cells)
2. **Smoothstep curve**: `t = t * t * (3.0 - 2.0 * t)` for gentle start near cave platform
3. **Slope cap**: `cave_max_slope = 0.67` limits height increase to 2.0 per cell, guaranteeing climbability regardless of surrounding terrain height

Also increased `cave_min_spacing` from 60 to 100 to prevent ramp overlap between adjacent caves.

### Files Modified

| File | Changes |
|------|---------|
| `scripts/world/chunk_manager.gd` | Direct property assignment in `_spawn_cave_entrance()`, wider/smoother cave terrain ramp with slope cap, increased cave spacing |
| `scripts/world/cave_entrance.gd` | Diagnostic print in `_setup_visuals()`, shared material optimization (palette/moss from previous session) |

### Test Results
- All 488 regression tests pass

---

### Cave Interior Cleanup (continued)

**Symptom**: Inside the cave, terrain blocks were visible through the floor, a tree was growing through the ceiling, and the interior looked chaotic.

**Cause**: The terrain mesh/collision generation and tree/resource spawning systems had no awareness of cave tunnel volumes. They generated terrain blocks, trees, and resources at every grid cell, including those inside the cave tunnel (local x=[-3,+3], z=[0,-18]).

**Fix**: Added two exclusion functions to `chunk_manager.gd`:
- `is_inside_cave_tunnel(x, z)` — rectangular check for the tunnel volume (with 1-unit margin)
- `is_near_cave_entrance(x, z)` — wider check covering tunnel + entrance rocks + boulders

Applied exclusions in `terrain_chunk.gd`:
1. **Terrain mesh generation**: Skip cells inside cave tunnel in `_generate_terrain_mesh_batched()`
2. **Terrain collision (sync)**: Skip cells in `_generate_box_collision()`
3. **Terrain collision (batched)**: Skip cells in `_generate_box_collision_batched()`
4. **Tree spawning**: Skip positions near cave entrance in `_spawn_chunk_trees()`
5. **Resource spawning**: Skip positions near cave entrance in `_spawn_chunk_resources()`

### Files Modified (cumulative)

| File | Changes |
|------|---------|
| `scripts/world/chunk_manager.gd` | Property assignment fix, terrain ramp, cave spacing, `is_inside_cave_tunnel()`, `is_near_cave_entrance()` |
| `scripts/world/cave_entrance.gd` | Diagnostic print, shared material optimization |
| `scripts/world/terrain_chunk.gd` | Cave tunnel exclusion in mesh generation, both collision generators, tree spawning, and resource spawning |

### Test Results
- All 488 regression tests pass

---

### Performance: Pit Prevention Optimization

**Symptom**: Stuttering during gameplay, especially when crossing chunk boundaries.

**Root cause**: The `get_height_at()` pit prevention used 4 recursive calls per cell, each doing the full terrain computation (10 water body iterations, river checks, noise sampling, cave ramp). For the player's sync height cache (324 cells), this meant 324 * 4 = 1,296 redundant `get_height_at()` calls, each as expensive as the primary call. Total: ~1,620 full height computations per chunk load.

**Fix**: Moved pit prevention from recursive calls inside `get_height_at()` to a post-processing pass on the height cache:
1. Set `_in_pit_check = true` during height cache build → skips pit prevention in all calls
2. After build completes, run `_apply_pit_prevention()` on the cached heights
3. Post-processing uses cached neighbor values (4 array lookups per cell vs 4 full function calls)

**Impact**: ~80% reduction in height cache computation. The 1,296 recursive calls (each doing water/river/noise/cave loops) are replaced by 256 simple array comparisons. The sync height cache for the player's chunk drops from ~17-30ms to ~4-8ms.

**Behavior**: Identical to the previous implementation - pit prevention still checks that no cell is more than 1 block below ALL cardinal neighbors, using the same raw (pre-pit-prevention) neighbor heights.

### Files Modified (cumulative)

| File | Changes |
|------|---------|
| `scripts/world/terrain_chunk.gd` | Pit prevention as post-processing on height cache, cave tunnel exclusion |

### Test Results
- All 488 regression tests pass

---

## Session 30 - Fix Concurrency Bug in Pit Prevention (2026-02-07)

### Problem
After the pit prevention optimization (Session 29), the game was "shaky and weird" with stuttering from the very first frame. The gameplay was described as "absolutely terrible."

### Root Cause: Shared Mutable State Across Frame Yields
The pit prevention optimization used a shared boolean flag `chunk_manager._in_pit_check` that was set to `true` during height cache builds and cleared after. For the **sync** build (player's chunk, no yields), this worked fine. But for the **batched** build (distant chunks), the flag stayed `true` across `await get_tree().process_frame` yields.

When the player's chunk sync build completed and cleared the flag to `false` mid-batch, the remaining rows of the batched build suddenly had pit prevention **re-enabled** inside `get_height_at()`. This caused:
1. **4x recursive overhead** on those rows (exactly what the optimization was supposed to eliminate)
2. **Double pit prevention** - once inline in `get_height_at()`, then again in `_apply_pit_prevention()` post-processing
3. **Inconsistent terrain heights** - some rows got pit prevention, others didn't, within the same chunk

### Fix
Replaced the shared mutable flag with an explicit `skip_pit_check: bool = false` parameter on `get_height_at()`. Height cache builds pass `true` to skip inline pit prevention (applied as post-processing instead). The shared `_in_pit_check` flag now only serves as a recursion guard within single-frame `get_height_at()` calls - never held across yields.

### Architectural Lesson
**Never hold shared mutable state across `await` yields in GDScript coroutines.** Even though GDScript is single-threaded, cooperative multitasking via `await` means other coroutines run between yields. Shared flags that span yields create the exact same class of bugs as thread-safety issues in multi-threaded code. Prefer function parameters over shared flags when possible.

### Files Modified

| File | Changes |
|------|---------|
| `scripts/world/chunk_manager.gd` | Added `skip_pit_check` parameter to `get_height_at()` |
| `scripts/world/terrain_chunk.gd` | Removed shared flag manipulation from height cache builds, use parameter instead |

### Test Results
- All 488 regression tests pass

---

## Session 31 - Fix Mesh Generation Bottleneck: Cached Side Face AO (2026-02-07)

### Problem
Despite the concurrency bug fix (Session 30), the game still had extreme stuttering at 14-21 FPS for the first 10-15 seconds after loading. Added performance profiling instrumentation to diagnose the root cause.

### Root Cause: Uncached Side Face AO Lookups
Profiling revealed mesh batch times of 29-76ms (target: ~8ms) and ~800-1000 `get_height_at()` calls per frame during chunk generation.

The culprit was `_add_side_faces_cached()` calling `_calculate_side_ao_top()` (1 uncached `get_height_at()` call) and `_calculate_side_ao_bottom()` (3 uncached `get_height_at()` calls) for every side face during mesh generation. Each of those calls triggered 4 recursive pit-prevention lookups, resulting in **20 full height computations per side face**. These neighbor heights were already available in the height cache but weren't being used.

### Fix
- Modified `_add_side_faces_cached()` to pre-fetch cardinal neighbor heights from the height cache and compute AO inline
- Created `_add_side_quad_ao()` that takes pre-computed ao_top and ao_bottom parameters
- Created `_calc_side_ao_bottom_cached()` helper that uses cached heights
- Removed dead code: `_add_top_face`, `_add_side_faces`, `_calculate_vertex_ao`, `_calculate_side_ao_top`, `_calculate_side_ao_bottom` (-223 lines, +50 lines net)
- Removed all `[PERF]` profiling instrumentation after confirming the fix (84 lines removed across 3 files)
- Removed diagnostic print from `cave_entrance.gd`

### Files Modified

| File | Changes |
|------|---------|
| `scripts/world/terrain_chunk.gd` | Cache-based AO computation, new `_add_side_quad_ao()` and `_calc_side_ao_bottom_cached()`, removed dead code and profiling |
| `scripts/world/chunk_manager.gd` | Removed profiling variables, frame timing, call counters, chunk load timing |
| `scripts/world/cave_entrance.gd` | Removed diagnostic print |

### Test Results
- All 488 regression tests pass

---

## Session 32 - Fix Cave Entrance Fall-Through (2026-02-07)

### Problem
Player fell through the terrain when approaching a cave entrance, ending up at Y=-12.6 with no way to recover.

### Root Cause: Collision Gap Between Terrain Skip Zone and Cave Floor
When caves were converted to inline terrain features, `is_inside_cave_tunnel()` removes terrain collision boxes in a rectangular zone (X:[-4,+4], Z:[-19,+1] relative to cave center). The cave's own floor collision was supposed to replace this, but it only covered (X:[-3,+3], Z:[-18,0]) — leaving three gaps:

1. **Front entrance (Z=0 to +1)**: 1-unit gap right where the player walks in
2. **Both sides (X=±3 to ±4)**: 1-unit gaps on each side
3. **Back (Z=-19 to -18)**: 1-unit gap (covered by back wall)

Additionally, the fall recovery threshold was set at Y=-50, so a player at Y=-12.6 wouldn't trigger the emergency respawn.

### Fix
- Expanded cave floor collision from `Vector3(6.0, 0.5, 18.0)` to `Vector3(9.0, 0.5, 21.0)`, fully covering the terrain skip zone with 0.5-unit margin on each side
- Lowered fall recovery threshold from Y=-50 to Y=-15 as a safety net for any future fall-through edge cases

### Files Modified

| File | Changes |
|------|---------|
| `scripts/world/cave_entrance.gd` | Expanded floor collision to cover full terrain skip zone |
| `scripts/player/player_controller.gd` | Lowered `fall_warning_y` from -50 to -15 |

### Test Results
- All 488 regression tests pass

---

## Session - Cave Entrance Redesign: Natural Sinkhole (2026-02-07)

### Overview
Completely redesigned cave entrances from above-ground bunker/building structures to natural sinkholes — holes in the ground that the player descends into via stone steps.

### What Changed

**Old design**: Dark opening at y=1.6 framed by large rock masses reaching y=4.8 above ground. Looked like a building sitting on the terrain.

**New design**: Rocky crater rim at ground level (y=0) with a 5-step stairway descending to y=-2.5, leading into an underground tunnel with floor at y=-3.0 and ceiling at y=0.

### Architecture (side view)
```
Terrain surface (y=0)
═══╗ rim rocks ╔═══════════════════════════
   ║           ║  ceiling (ground above)
   ╠─step 1    ╠═══════════════════════════
   ╠──step 2   ║
   ╠───step 3  ║    UNDERGROUND TUNNEL
   ╠────step 4 ║    (floor at y=-3.0)
   ╠─────step 5║    crystals, ore, details
   ╚═══════════╩═══════════════════════════
   z=+3        z=-6                    z=-24
```

### Key Design Decisions
- **5 solid steps**: Each step is a filled box from its tread down to the tunnel floor (y=-3.0), preventing any gaps
- **3.0 unit headroom**: Tunnel ceiling at y=0, floor at y=-3.0 (player capsule ~2 units)
- **Crater rim**: 8 low rim boulders + 5 scattered surface boulders, no above-ground walls
- **Earth walls**: Inner crater sides descend from y=0 to y=-3.0
- **Cave Area3D**: Starts at z=-3 (only triggers when player is actually underground)
- **Surface replacement panels**: Collision panels at y=0 fill the terrain skip zone around the opening
- **Floor slab**: 11×30 unit collision floor covers entire terrain skip zone with margin

### Files Modified

| File | Changes |
|------|---------|
| `scripts/world/cave_entrance.gd` | Complete rewrite: `_build_entrance_rocks()` → `_build_crater_rim()`, new `_build_stairway()`, shifted `_build_tunnel()` underground, shifted `_build_interior_details()`, repositioned `_build_cave_area()`, rewritten `_build_collision()`, adjusted `_spawn_resources()` positions. Added `_earth_mat` and `_step_mat` shared static materials. |
| `scripts/world/chunk_manager.gd` | `is_inside_cave_tunnel()`: expanded z range from `[-19,+1]` to `[-25,+4]`. `is_near_cave_entrance()`: expanded z range from `[-20,+7]` to `[-26,+7]`. |

### Test Results
- All 488 regression tests pass

---

## Session 40 - Cave Overhaul: Deeper Cave, Movement Fix, Z-Fighting Fix (2026-02-08)

### Summary
Comprehensive cave entrance overhaul fixing four major issues:
1. **Movement bug fixed**: Removed rectangular flat zone check from `get_height_at()` that created hard height edges causing players to get stuck on block boundaries in flat terrain
2. **Z-fighting eliminated**: Lowered ALL cave geometry tops to y<=-0.3 (local) so nothing overlaps with terrain at y=0.0
3. **Terrain gap minimized**: Shrunk skip zone from X:[-4,+4] Z:[-6,+4] to X:[-3,+3] Z:[-5,+4] — smaller hole in terrain means less visible gap
4. **Cave made much deeper**: Steps now descend 1.0 per step (was 0.5), tunnel floor at y=-5.5 (was -3.0), giving ~5 units of headroom
5. **Removed above-ground decorations**: No more rim boulders, scattered rocks, or moss patches that caused z-fighting with terrain

### Key Design Changes
- **5 deep steps**: Each step drops 1.0 unit, from y=-1.0 to y=-5.0 (tunnel floor at y=-5.5)
- **~5 unit headroom**: Tunnel ceiling at y=-0.8, floor at y=-5.5
- **No surface decorations**: Terrain generates naturally over the cave, Minecraft-style
- **Tighter walls**: X=±2.8 (was ±3.5), matching tighter skip zone
- **Movement fix**: Circular flat zone (16-unit radius) + ramp zone (16-46 units) handles all terrain transitions smoothly without hard edges

### Files Modified

| File | Changes |
|------|---------|
| `scripts/world/chunk_manager.gd` | Removed rectangular flat zone check from `get_height_at()` (fixes movement bug). Shrunk `is_inside_cave_tunnel()` skip zone to X:[-3,+3] Z:[-5,+4]. |
| `scripts/world/cave_entrance.gd` | Deepened cave: steps 1.0/step to y=-5.0, floor y=-5.5. Lowered all wall/ceiling tops below y=-0.3. Removed rim boulders, scattered rocks, moss. Tightened walls to X=±2.8. Updated collision, interior details, resources for new depth. |

### Test Results
- All 488 regression tests pass

---

## Session 41 - Remove Rope Ladder Item (2026-02-09)

### Summary
Removed the rope ladder item entirely from the game. The grappling hook already covers vertical traversal needs, making the rope ladder redundant. The rope ladder had several implementation gaps (no-op `_rebuild_ladder_visuals()`, missing `set_climbing()` player method, non-existent .tscn scene file) and fragile cliff-face placement detection that didn't work reliably. Removing it simplifies the codebase significantly.

### Changes
- Removed `rope_ladder` structure definition from structure data and placeable items list
- Removed `rope_ladder_kit` crafting recipe (was 2 rope + 4 branches)
- Removed `rope_ladder_kit` from equipment system (slot 13)
- Moved grappling hook from slot 14/`]` key to slot 13/`[` key to fill the gap
- Removed rope ladder entry from equipment menu UI
- Removed all rope ladder special-case logic from placement system: cliff-base snapping, cliff-face validation, cliff height calculation, cliff face snapping
- Removed three cliff helper functions only used by rope ladder: `_has_cliff_face()`, `_snap_to_cliff_face()`, `_calculate_cliff_height()`
- Removed `_create_rope_ladder()` procedural generation function (~75 lines)
- Deleted `scripts/campsite/structure_rope_ladder.gd` (climbing script)

### Files Modified

| File | Changes |
|------|---------|
| `scripts/campsite/structure_data.gd` | Removed `rope_ladder` from STRUCTURES dict and `rope_ladder_kit` from PLACEABLE_ITEMS |
| `scripts/crafting/crafting_system.gd` | Removed `rope_ladder_kit` recipe |
| `scripts/player/equipment.gd` | Removed `rope_ladder_kit` equippable entry; moved grappling_hook to slot 13; removed `]` key binding |
| `scripts/ui/equipment_menu.gd` | Removed rope ladder slot; reassigned `[` key to grappling hook |
| `scripts/campsite/placement_system.gd` | Removed `calculated_ladder_height` var, rope ladder preview snapping, cliff validation, cliff snap/height calc on confirm, `_create_rope_ladder()`, `_has_cliff_face()`, `_snap_to_cliff_face()`, `_calculate_cliff_height()` |
| `scripts/campsite/structure_rope_ladder.gd` | **Deleted** |

---

## Session 42 - Config Menu Fix, Remove Thorns, Cave Gap Fix (2026-02-08)

### Config Menu: PlayStation Button Labels
Fixed the config menu navigation hint at the bottom of the screen. It displayed Xbox labels ("A Select  B/TAB Close") instead of PlayStation symbols. Now uses `InputManager.get_prompt()` to dynamically show correct symbols for the connected controller (e.g., "✕ Select  ○ Close"). Also removed stale "B" from the keyboard-mode hint.

| File | Changes |
|------|---------|
| `scripts/ui/config_menu.gd` | Use `InputManager.get_prompt("ui_accept")`/`get_prompt("ui_cancel")` for controller hints |

### Remove Thorn Bush Obstacles
Removed the thorn bush obstacle system entirely. Thorns looked bad visually and the Area3D damage/slow mechanic didn't work reliably. The machete tool remains as a standalone weapon.

**Removed:**
- `scripts/world/obstacle_thorns.gd` (411 lines) — full ObstacleThorns implementation
- Obstacle generation, spawning, tracking, and save/load in chunk_manager.gd
- Thorn slow effect (`thorn_slow_active`, `set_thorn_slow()`) from player_controller.gd
- Obstacle save/load blocks from save_load.gd
- Thorn references from game spec and README

| File | Changes |
|------|---------|
| `scripts/world/obstacle_thorns.gd` | **Deleted** |
| `scripts/world/chunk_manager.gd` | Removed obstacle vars, `_generate_obstacles()`, `_spawn_obstacles_in_chunk()`, `_spawn_obstacle()`, `get_spawned_obstacles()`, `get_obstacles_save_data()`, `load_obstacles_save_data()`, script loading |
| `scripts/player/player_controller.gd` | Removed `thorn_slow_active`, `thorn_slow_multiplier`, slow effect application, `set_thorn_slow()` |
| `scripts/core/save_load.gd` | Removed obstacle save/load blocks |
| `into-the-wild-game-spec.md` | Removed thorn obstacle example |
| `README.md` | Updated machete description |
| `tests/test_structure_data.gd` | Fixed pre-existing structure count (15 → 14) |

### Cave Entrance Terrain Gap and Fall Recovery

**Bug 1: Terrain gap to the left of cave entrances**

**Symptom**: Player fell through a gap in the landscape next to cave entrances at approximately (39, -3.5, -123).

**Cause**: The cave's collision walls (0.8 units wide at X:±2.8) didn't extend far enough to guarantee overlap with terrain cells. The terrain skip zone is X:[-3,+3] but cells (cell_size=3.0) aren't aligned to the cave center. Depending on grid alignment, up to 1.5 units of gap could exist between the nearest terrain collision block edge and the cave wall — enough for the player to fall through.

**Fix**: Widened cave collision walls to guarantee overlap regardless of grid alignment:
- Side walls: 0.8 → 2.8 wide (center shifted outward to ±3.8), extending to X:±5.2
- Front wall: 6.4 → 10.4 wide, extended forward from 0.8 to 2.2 deep
- All collision tops raised from y=-0.3 to y=+0.2 (local) to overlap vertically with terrain blocks

**Bug 2: Fall recovery lands underground**

**Symptom**: Recovery teleported player to Y:-2.999, still below terrain. Log: `[Player] Recovered to last safe position: (39.40995, -2.999058, -127.4506)`

**Cause**: Safe position tracker stored position when `is_on_floor()` was true, which included standing on cave geometry below the terrain surface. Recovery put the player back at that underground position.

**Fix**: Recovery now uses `chunk_manager.get_height_at()` to find the actual terrain surface height at the recovery XZ position, and teleports to `terrain_height + 1.0`. Falls back to last safe position or spawn if chunk_manager is unavailable.

| File | Changes |
|------|---------|
| `scripts/world/cave_entrance.gd` | Widened side walls (2.8), front wall (10.4×2.2), raised collision tops |
| `scripts/player/player_controller.gd` | `_recover_from_fall()` uses `get_height_at()` for terrain-aware recovery, added `_find_chunk_manager()` helper |

### Test Results
- All 473 regression tests pass (count reduced from 488 due to thorn removal and structure count fix)

---

## Session 43 - Birch Bark Map Feature (2026-02-08)

### Birch Bark Harvesting
The machete lost its only purpose when thorn bushes were removed. This gives it a new role: harvesting birch bark from birch trees. Equip the machete and use it on a birch tree (white bark) to harvest `birch_bark`. Each tree has a 3-day regrowth cooldown tracked per-tree position, with save/load persistence.

### Bark Map Crafting
New crafting recipe: `birch_bark x3 + berry x2` = Birch Bark Map. Requires crafting bench and camp level 2.

### Map Overlay
Equip the bark_map and press R to open a fullscreen wilderness map showing:
- Terrain regions colored by type (meadow, forest, hills, rocky, mountain)
- Water bodies as blue circles, rivers as blue lines
- Cave entrances as dark squares
- Campsite at origin as gold circle
- Player position as white circle
- North indicator and color legend

Press R again to close. Movement is blocked while map is open.

### Equipment Menu
Bark map added to equipment menu as slot `]` (slot 24).

| File | Type | Changes |
|------|------|---------|
| `scripts/player/equipment.gd` | Modified | Bark harvest tracker, birch tree detection in `_use_tool()`, `_harvest_birch_bark()`, `bark_map` equippable item, `_use_map()` toggle, `_close_map_if_open()`, save/load helpers, `]` key binding |
| `scripts/crafting/crafting_system.gd` | Modified | Added `bark_map` recipe |
| `scripts/ui/bark_map_ui.gd` | **New** | CanvasLayer map overlay with terrain sampling and custom `_draw()` rendering |
| `scripts/player/player_controller.gd` | Modified | Added `map_ui` group check to `_is_ui_blocking_input()` |
| `scripts/core/save_load.gd` | Modified | Save/load bark harvest tracker data |
| `scripts/ui/hud.gd` | Modified | Added bark_map equipped hint `[R open map, Q unequip]` |
| `scripts/ui/equipment_menu.gd` | Modified | Added bark_map to equipment slot list |

### Test Results
- All 479 regression tests pass

---

## Session 44 - Auto Step-Up for Terrain Traversal (2026-02-08)

### Problem
Forest terrain quantizes heights to 1.0-unit steps, causing adjacent blocks to differ by exactly 1 unit. These look flat visually but the player gets stuck on every edge and has to jump constantly to traverse "flat" terrain.

### Solution
Added Minecraft-style auto step-up to the player controller. When the player walks into a terrain step while on the ground, the system:
1. Detects forward movement would collide
2. Tests incrementally higher positions (0.1 unit increments, up to 1.1 units)
3. Finds the minimum elevation where forward movement is unblocked
4. Teleports the player up; `move_and_slide()` floor snapping handles landing

Safety checks prevent step-up when: no obstacle ahead, ceiling above, still blocked at elevated height (wall not step), or not on floor (airborne/swimming).

| File | Type | Changes |
|------|------|---------|
| `scripts/player/player_controller.gd` | Modified | Added `STEP_HEIGHT`, `STEP_TEST_INCREMENT` constants, `_try_step_up()` method, step-up call before `move_and_slide()` |

### Test Results
- All 479 regression tests pass

---

## Session 45 - Fix Cave Terrain Gaps (2026-02-08)

### Problem
Players fall through terrain near cave entrances — both inside and outside. Previous fixes (widening cave walls in Session 38) addressed symptoms, not the root cause. Visual gaps also visible: terrain removal zone larger than cave geometry, and a gap between stair side walls and tunnel walls.

### Root Cause
`is_inside_cave_tunnel()` checks **cell centers** against a rectangular skip zone `X:[-3,+3], Z:[-5,+4]`. With `cell_size=3.0`, a cell whose center lands on the boundary gets fully removed — but its half extends **outside** the boundary. This expands the effective terrain removal zone by up to 1.5 units on each side. The cave's visual and collision geometry only covered the intended zone, leaving both visual holes and fall-through gaps at the expanded edges.

### Solution (Two Iterations)

**First attempt** — collision-only band-aids: added surface-level collision cap slabs and extended side wall collision Z-size. This prevented fall-through but didn't fix the visual gaps (terrain still removed too far, earth wall meshes still had gaps).

**Root cause fix** — three changes:

1. **`is_inside_cave_tunnel()` now checks cell edges, not centers** — Shrinks check boundaries by `cell_size / 2.0` (1.5 units) so a cell is only skipped if its **entire footprint** falls within the intended zone. Effective center check becomes `X:[-1.5, +1.5], Z:[-3.5, +2.5]`, guaranteeing removal never exceeds `X:[-3,+3], Z:[-5,+4]`.

2. **Extended stair side earth wall visual meshes** — Z-size from 7.5 to 9.5 (center shifted from -0.75 to -1.75), now covering Z:[-6.5, +3.0]. Closes the visible gap between stair walls (were ending at Z:-4.5) and tunnel walls (starting at Z:-6.0).

3. **Removed surface collision caps** — No longer needed since terrain removal matches cave geometry. Side wall collision stays extended (Z-size 11.0) as a safety margin.

| File | Type | Changes |
|------|------|---------|
| `scripts/world/chunk_manager.gd` | Modified | `is_inside_cave_tunnel()` shrinks boundaries by `cell_size / 2.0` to check cell edges |
| `scripts/world/cave_entrance.gd` | Modified | Extended stair side earth wall Z-size 7.5→9.5, extended side wall collision Z-size 9→11, removed surface cap collisions |

### Test Results
- All 479 regression tests pass

### Lesson Learned
When terrain generation removes cells based on point-in-zone checks, always account for cell extent (half cell_size) to avoid removing cells that only partially overlap the zone. Fix the generation logic rather than patching gaps with extra geometry.

---

## Session 46 - Snap Cave Dimensions to Cell Grid (2026-02-08)

### Overview
Complete redesign of cave geometry to snap all X/Z boundaries to multiples of `cell_size` (3.0). Previously, cave geometry used fractional dimensions (4.6-wide stairs, walls at X:±2.8, 1.5-deep steps) which never aligned with the 3.0-unit terrain grid, causing unpredictable terrain removal and recurring gap bugs. This session eliminates the root cause by making cave and terrain grids identical.

### Key Changes
- **Skip zone**: Now `X:[-3,+3], Z:[-6,+6]` (2×4 cells = 6 wide × 12 deep). With cave center snapped to grid, exactly 8 cells are always removed deterministically.
- **Stairway**: 4 steps (was 5), each 3.0 deep in Z with 1.5 drop per step. Width 6.0. All Z boundaries on grid multiples. Tunnel floor at Y=-6.0 (was -5.5).
- **Crater walls**: Inner faces at X:±3.0 and Z:+6.0 (on grid), 1.5 thick extending outward. Front wall 9.0 wide to cover corners.
- **Tunnel**: Walls inner faces at X:±3.0 (on grid), 6 segments of 3.0 depth each. Floor at Y=-6.0, ceiling at Y=-0.75. Back wall at Z=-24.0.
- **Cave center snapping**: `_generate_cave_entrances()` now rounds candidate positions to nearest `cell_size` multiple before storing.
- **Grid alignment rule**: Added to CLAUDE.md — all terrain-interacting geometry must snap X/Z to cell_size multiples.

### Design Principles
1. Cave center snapped to cell edges (multiples of 3.0 in world coords)
2. All X/Z outer boundaries at multiples of 3.0 from cave center
3. Y-axis uses gameplay-appropriate values (doesn't interact with terrain grid)
4. Interior details (stalactites, rubble) unchanged — purely decorative, no grid interaction

### Files Modified
| File | Status | Changes |
|------|--------|---------|
| `scripts/world/cave_entrance.gd` | Modified | Complete rewrite of all geometry functions with grid-snapped dimensions |
| `scripts/world/chunk_manager.gd` | Modified | Snap cave center to cell grid, update skip zone to X:[-3,+3] Z:[-6,+6], update near-cave zone to X:[-6,+6] Z:[-27,+9] |
| `CLAUDE.md` | Modified | Added Grid Alignment Rule section |

### Test Results
- All regression tests pass

---

## Session 47 - Cave Visual Fixes and Decoration Exclusion (2026-02-08)

### Stairway Seam Fix
Fixed z-fighting seam visible on cave staircase steps. The 4 steps had Z-depth of exactly 3.0, creating perfectly coplanar faces at their Z boundaries (Z=3.0, Z=0.0, Z=-3.0). Extended each step's Z depth from 3.0 to 3.1 (both visual meshes and collision shapes) so adjacent steps overlap by 0.05 units on each side, eliminating the z-fighting.

### Decoration Cave Exclusion
Flowers and grass tufts were spawning in mid-air over cave openings because `_spawn_chunk_decorations()` didn't check for cave zones. Trees and resources already excluded cave areas via `is_near_cave_entrance()`, but decorations were missing this check. Added the same `is_near_cave_entrance()` exclusion to both grass tuft and flower spawning loops.

### README Update
Updated README.md with recent feature additions:
- Birch Bark Map feature and crafting recipe (Session 43)
- Birch bark harvesting with machete
- Auto step-up terrain traversal (Session 44)
- Grappling hook slot number fix (22 → 13, from Session 41)

| File | Type | Changes |
|------|------|---------|
| `scripts/world/cave_entrance.gd` | Modified | Stair step Z depth 3.0 → 3.1 (visual + collision) to fix z-fighting seams |
| `scripts/world/terrain_chunk.gd` | Modified | Added `is_near_cave_entrance()` check to grass tuft and flower spawning |
| `README.md` | Modified | Added bark map, birch harvesting, auto step-up, fixed grappling hook slot |

### Test Results
- All 479 regression tests pass

---

## Session 48 - Cave Z-Fighting Fix and Camp Level Progression Bug (2026-02-09)

### Cave Entrance Overhang Z-Fighting Fix
Fixed z-fighting on the exterior surface of caves at the far end where dark and green terrain were flashing. The tunnel entrance overhang mesh at the skip zone boundary had its top face at exactly local Y=0.0, which equals terrain_height in world space — coplanar with the terrain top faces. Since the overhang is 9.0 units wide but the skip zone is only 6.0 wide, terrain cells generated outside the skip zone had top faces at the exact same Y as the overhang, causing z-fighting. Lowered the overhang center from Y=-0.5 to Y=-0.75, placing its top face 0.25 units below terrain surface.

### Camp Level 2→3 Day Counter Off-By-One Fix
Fixed camp level progression being stuck at level 2 despite days passing. The HUD displayed `days_at_level_2 + 1` as "Day X/3" (so "Day 3/3" appeared when `days_at_level_2 = 2`), but the requirement checked `days_at_level_2 >= 3`. This meant the player had to wait one extra day beyond the "Day 3/3" display before the requirement was satisfied. Since the HUD was capped at "Day 3/3" via `min()`, that extra day was invisible — it looked permanently stuck. Changed the threshold from `>= 3` to `>= 2` so the level-up triggers when the HUD shows "Day 3/3".

| File | Type | Changes |
|------|------|---------|
| `scripts/world/cave_entrance.gd` | Modified | Lowered tunnel entrance overhang Y from -0.5 to -0.75 to fix z-fighting with terrain |
| `scripts/campsite/campsite_manager.gd` | Modified | Changed day requirement from `>= 3` to `>= 2` to align with HUD display |

### Test Results
- All 479 regression tests pass

---

## Session 49 - Grappling Hook Sounds & Animal Spawn Rates (2026-02-11)

### Grappling Hook Sound Effects
Added three procedurally-generated audio files for the grappling hook. The SFXManager entries and gameplay code already existed from Session 49 (grapple_fire, grapple_attach, grapple_land) but the audio files were missing, causing silent playback. Generated sounds using Python/numpy synthesis:
- **grapple_fire.mp3** - Rising-pitch whoosh with metallic zing (plays on launch)
- **grapple_attach.mp3** - Sharp metallic clank with rock scrape (plays 150ms after fire)
- **grapple_land.mp3** - Low thud with dirt crunch (plays on cliff landing)

### Ambient Animal Spawn Rate Increase
Animals were extremely rare due to cascading spawn filters. Increased visibility ~4-5x:
- Chunk spawn gate: 15% → 40% of chunks can have animals
- Per-chunk cap: 2 → 4 animals maximum
- Meadow: 0-1 rabbit/bird → 1-2 each (guaranteed at least 1)
- Forest: 0-1 rabbit/bird → 1-2 rabbits, 0-2 birds
- Hills: birds only → 0-1 rabbit, 1-2 birds
- Mountain: 0-1 bird → 1-2 birds
- Rocky: unchanged (0-1 bird)

| File | Type | Changes |
|------|------|---------|
| `assets/audio/sfx/tools/grapple_fire.mp3` | New | Hook launch sound |
| `assets/audio/sfx/tools/grapple_attach.mp3` | New | Hook attach impact sound |
| `assets/audio/sfx/tools/grapple_land.mp3` | New | Landing thud sound |
| `scripts/world/terrain_chunk.gd` | Modified | Increased animal spawn rates and per-biome counts |

### Test Results
- All 479 regression tests pass

---

## Session 50 - Bug Fix Marathon: 20 Gameplay Bugs (2026-02-14)

Fixed all 20 bugs reported from gameplay testing session. Changes span combat, UI, structures, crafting, weather, environment, and creatures.

### Bug Fixes

**1. Rare ore "Need Pickaxe" text** - Changed to "Need Axe" to match `required_tool = "axe"` (`rare_ore_node.gd`)

**2. Bunnies jumping at terrain block corners** - Added `_get_smoothed_terrain_height()` to `ambient_animal_base.gd` that samples 5 points (center + 4 offsets) and returns max height, preventing clipping at cell edges

**3. Torch pickup HUD persistence** - Added `is_instance_valid` check after `interact()` in `player_controller.gd` to clear stale targets when objects are freed

**4. Cave "need a light" notification** - Removed notification messages from `cave_transition.gd`, darkness damage still works silently

**5. Structure placement inside caves** - Added `cave_entrance` group skip in `placement_system.gd` validation so cave colliders don't block placement

**6. Cave 3D stones replaced with wall designs** - Replaced all 3D stalactites/rubble/outcrops in `cave_entrance.gd` with flat 0.02-thick panels (mineral streaks, crack patterns, moss patches)

**7. Campfire light coloring** - Adjusted fire light to warmer color `(1.0, 0.7, 0.35)`, energy `2.2`, range `10.0`, attenuation `1.5` in both `save_load.gd` and `structure_fire_pit.gd`

**8. Night too dark** - Increased night ambient `(0.25, 0.25, 0.4)`, sun intensity `0.25`, moon light `0.35`, sky/fog colors in `environment_manager.gd`

**9. Day counter HUD after sleeping** - Changed HUD `day_changed` handler to use `call_deferred("_update_campsite_level_display")` to ensure campsite_manager processes first

**10. Sun billboard** - Added `billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED` to sun material, removed manual `look_at` in `environment_manager.gd`

**11. Floating herbs/stones in rocky areas** - Increased terrain sample offsets from 0.5 to 1.5 (half cell_size) in `terrain_chunk.gd`

**12. Cabin bed exit position** - Changed exit offset from `Vector3(-1.0, 0, 0)` to `Vector3(0, 0, 1.0)` (toward cabin interior) in `cabin_bed.gd`

**13. Cabin "Press L2" does nothing** - Changed `get_interaction_text()` to return empty string since player walks through door and interior objects handle interactions

**14. Campfire visual stays on when fuel runs out** - Grouped 3 flame layers into container Node3D named "FireMesh" in `save_load.gd`, changed `fire_mesh` type to `Node3D` in `structure_fire_pit.gd`

**15. Hide has no crafting use** - Added 3 new recipes: Waterskin (2 hide + 1 rope, hunger 35), Hide Bedroll (3 hide + 2 branch, heals 40), Leather Strips (1 hide = 2 strips)

**16. Lake fish restocking** - Connected fishing spots to `day_changed` signal for automatic daily respawn when depleted

**17. Weather station forecast** - Added `get_forecast(days)` method to `weather_manager.gd` for multi-day predictions. Weather vane now shows HUD notification with current weather + 5-day forecast

**18. Birch bark map** - Doubled map size from 700px to 1400px. Replaced player white circle with X marker (drawn as two crossed lines with dark outline)

**19. Lantern place/pickup** - Full lantern placement system: `structure_placed_lantern.gd` (pickup on interact), `_create_placed_lantern()` mesh (glass housing, metal frame, crystal core, corner posts), `place_lantern_instant()` in placement_system, save/load support, HUD pickup-only mode

**20. Snare trap catch rate** - Halved from 15% to 7.5% per check (`CATCH_CHANCE = 0.075`)

| File | Type | Changes |
|------|------|---------|
| `scripts/resources/rare_ore_node.gd` | Modified | "Need Axe" text |
| `scripts/creatures/ambient_animal_base.gd` | Modified | Smoothed terrain height sampling |
| `scripts/creatures/ambient_rabbit.gd` | Modified | Use smoothed height in hops |
| `scripts/player/player_controller.gd` | Modified | Post-interact validity check, hide_bedroll/waterskin items, lantern pickup-only |
| `scripts/core/cave_transition.gd` | Modified | Removed HUD notifications |
| `scripts/campsite/placement_system.gd` | Modified | Cave group skip, lantern instant placement, lantern mesh creation |
| `scripts/world/cave_entrance.gd` | Modified | Flat wall decorations instead of 3D rocks |
| `scripts/core/save_load.gd` | Modified | Fire mesh container, fire light tuning, lantern creation |
| `scripts/campsite/structure_fire_pit.gd` | Modified | Light values, fire_mesh type Node3D |
| `scripts/world/environment_manager.gd` | Modified | Night brightness, sun billboard |
| `scripts/ui/hud.gd` | Modified | Deferred day counter update, lantern pickup-only |
| `scripts/world/terrain_chunk.gd` | Modified | Resource spawn sample offsets |
| `scripts/campsite/cabin_bed.gd` | Modified | Exit position toward cabin interior |
| `scripts/campsite/structure_cabin.gd` | Modified | Empty interaction text |
| `scripts/crafting/crafting_system.gd` | Modified | 3 new hide recipes |
| `scripts/resources/fishing_spot.gd` | Modified | Daily respawn via day_changed |
| `scripts/world/weather_manager.gd` | Modified | Multi-day forecast method |
| `scripts/campsite/structure_weather_vane.gd` | Modified | HUD forecast display |
| `scripts/ui/bark_map_ui.gd` | Modified | 2x larger map, X player marker |
| `scripts/player/equipment.gd` | Modified | Lantern instant placement |
| `scripts/campsite/structure_data.gd` | Modified | placed_lantern structure + lantern placeable |
| `scripts/campsite/structure_snare_trap.gd` | Modified | Halved catch chance |
| `scripts/campsite/structure_placed_lantern.gd` | New | Placed lantern with pickup support |
| `tests/test_structure_data.gd` | Modified | Updated structure count to 15 |

### Test Results
- All 506 regression tests pass

---

## Session 51 - Bug Fix Session: 6 Gameplay Issues (2026-02-15)

### Bug Fixes

1. **Floating resources fixed** - Sticks, rocks, mushrooms were floating above terrain because `_spawn_resource()` sampled 5 terrain points and used the maximum height, causing resources near terrain steps to float at the neighboring cell's higher elevation. Root cause fix: use only the height at the resource's actual position instead of multi-point sampling.

2. **Weather vane forecast now deterministic** - `get_forecast()` was using `randf()` which gave different results each call. Fixed by using a seeded `RandomNumberGenerator` based on the current game day, so checking the weather vane multiple times on the same day always shows the same forecast.

3. **Weather vane display changed to vertical table** - Was joining forecast lines with " | " making a horizontal bar. Changed to "\n" join so each day appears on its own row. Also made notification duration scale with line count (3s base + 1s per extra line).

4. **Fire extinguish visual fix** - When fire burned out, top flame components could persist. Fixed `_set_fire_state()` to re-acquire node references if lost (handles save/load edge case) and explicitly set visibility on each child MeshInstance3D of the fire container.

5. **Birch bark map enlarged 50% + improved player marker** - Map size increased from 1400 to 2100 pixels. Player marker now has a filled circle background, thicker outline, and ring for visibility. When player is off the map edge, the X marker clamps to the map boundary and turns red. Legend updated with on-map/off-map indicators.

6. **Hide crafting recipes replaced with tool upgrades** - Removed waterskin, hide bedroll, and leather strips (impractical items). Added:
   - **Leather Axe Wrap** (2 hide + 1 rope): Doubles axe durability. Equip and use to apply to best axe in inventory.
   - **Leather Hook Wrap** (3 hide + 1 rope): Triples grappling hook durability. Equip and use to apply.
   - Upgrades persist through save/load and scale current durability proportionally.

7. **Controller O/X button swap** - Jump moved from ✕ to ○, unequip moved from ○ to ✕. Also swapped ui_accept and ui_cancel controller bindings. Updated both project.godot input map and InputManager display prompts.

### New Files
- `tests/test_weather_forecast.gd` - 32 tests covering forecast determinism, recipe changes, and controller mapping

### Modified Files
- `scripts/world/terrain_chunk.gd` - Simplified `_spawn_resource()` to use direct height
- `scripts/world/weather_manager.gd` - Deterministic seeded RNG in `get_forecast()`
- `scripts/campsite/structure_weather_vane.gd` - Vertical forecast layout
- `scripts/campsite/structure_fire_pit.gd` - Robust fire state toggling
- `scripts/ui/hud.gd` - Notification duration scales with line count
- `scripts/ui/bark_map_ui.gd` - 50% larger map, improved marker, edge clamping
- `scripts/crafting/crafting_system.gd` - Replaced hide recipes with leather wraps
- `scripts/player/equipment.gd` - Added leather wrap items, upgrade system, save/load
- `scripts/systems/input_manager.gd` - Swapped ○/✕ controller prompts
- `project.godot` - Swapped ○/✕ input bindings
- `tests/run_all_tests.gd` - Added weather forecast test suite

### Test Results
- All 532 regression tests pass (500 existing + 32 new)

---

## Session 52 - Bug Fix Session: 8 Gameplay Issues (2026-02-17)

### Bug Fixes

**1. Axe sound on collectibles** - When chopping single-hit collectibles (branches, stones), the wood chop impact sound no longer plays. Only the swing sound plays for pickup items; the chop sound is reserved for multi-hit resources like trees and ore.

**2. Cave torches appearing on surface after reload** - Torches and lanterns placed inside caves were teleported to the surface on reload because `_recreate_structure()` unconditionally overwrote Y position with terrain height. Fixed by adding `is_cave` flag to structure save data and skipping Y recalculation for cave structures.

**3. Missing structures after save/reload** - Smithing station, weather vane, snare trap, and smoker all failed to load because `_create_structure_programmatically()` in save_load.gd was missing match cases for these 4 structure types. Added all 4 creation functions with complete visual meshes matching the placement system versions.

**4. Cabin bed exit position** - Changed wake-up exit offset from `Vector3(0, 0, 1.0)` (forward) to `Vector3(1.0, 0, 0)` (right side of bed), rotated by bed orientation.

**5. Leather wrap visual indicators** - When leather axe wrap or leather hook wrap upgrades are applied, the equipped tool now shows visible leather wrapping: brown leather strips around the handle and a leather guard/pad near the tool head. Visuals check for durability upgrade metadata when creating the model.

**6. Fall damage system** - Player now takes damage from falls. Tracks Y position when fall begins, calculates damage on landing. Threshold: 4 units (no damage below), 8 HP per unit beyond threshold, capped at 80 HP max. Shows red HUD notification on impact.

**7. Death/respawn system** - When HP reaches zero, player auto-respawns at their latest shelter (cabin > tent > basic shelter) with 50% health/hunger, all inventory and structures intact. Game auto-saves after respawn. Shows notification explaining what happened. Respawn point updates when structures are loaded.

**8. Bunny terrain collision** - Rabbits no longer clip through terrain or trees when fleeing. Added steep terrain detection (>1 unit height difference triggers direction change), physics raycast obstacle checking before each hop, and perpendicular direction fallback when blocked. Also added terrain steepness check to base animal class `_move_animal()`.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/player/equipment.gd` | Modified | Collectible swing sound, leather wrap visuals for axe/hook |
| `scripts/core/save_load.gd` | Modified | 4 new structure creators, cave flag in save data, skip Y recalc for caves |
| `scripts/campsite/cabin_bed.gd` | Modified | Exit to right side of bed |
| `scripts/player/player_controller.gd` | Modified | Fall damage system, death/respawn system |
| `scripts/creatures/ambient_rabbit.gd` | Modified | Terrain steepness check, physics raycast obstacle avoidance |
| `scripts/creatures/ambient_animal_base.gd` | Modified | Steep terrain avoidance in base movement |

### Test Results
- All 532 regression tests pass

---

## Session 53 - Bug Fix Session: 3 Gameplay Issues (2026-02-17)

### Bug Fixes

**1. Canvas tent missing collision** - Player could walk through the canvas tent in all directions. The tent collision box in `save_load.gd` was only 0.1 units tall (a floor slab at ground level), while `placement_system.gd` had the correct 1.8-unit tall collision. Fixed by updating `save_load.gd` to match: `Vector3(3.0, 1.8, 2.5)` at `y=0.9`.

**2. Cave torches relocated to surface after save/reload** - The `is_cave` flag was set using a single global check (`not in_overworld`) that only checked if `chunk_manager` exists. Since the player is in the overworld when saving, every structure got `is_cave: false`. Fixed by comparing each structure's Y position to terrain height at that X/Z — if more than 1 unit below terrain, it's flagged as a cave structure and its Y is preserved on reload.

**3. Persistent "Pick Up Torch" HUD prompt after pickup** - After picking up a torch, the interaction prompt stayed on screen. `destroy()` calls `queue_free()` which doesn't free the node until end of frame, so `is_instance_valid()` still returned true. Fixed by adding `is_queued_for_deletion()` checks in both `_try_interact()` and `_update_interaction_target()`. Applies to all pickup-on-interact items (torch, lantern, lodestone).

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/core/save_load.gd` | Modified | Tent collision box height 0.1→1.8; per-structure cave detection via terrain Y comparison |
| `scripts/player/player_controller.gd` | Modified | Added `is_queued_for_deletion()` checks for interaction target cleanup |

### Test Results
- All 532 regression tests pass

---

## Session 54 - Testing Rule Added to CLAUDE.md (2026-02-17)

### Changes

Added a **Testing Rule** section to `CLAUDE.md` requiring regression tests for all bug fixes and new logic. This ensures every bug fix includes a test that reproduces the issue, and new data-transforming or decision-making logic gets unit test coverage.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `CLAUDE.md` | Modified | Added "Testing Rule" section with guidelines for writing tests (extend `TestBase`, register in `run_all_tests.gd`) |

---

## Session 55 - Code Audit Bug Fixes (2026-02-17)

### Bug Fixes

**1. Campsite progression flags lost on save/load** - `save_load.gd` checked inventory for `"Fishing Rod"` and `"Stone Axe"` (display names), but the inventory stores items by crafting key (`"fishing_rod"`, `"stone_axe"`). The lookup always failed, so `has_crafted_fishing_rod` and `has_crafted_tool` were never restored from inventory after loading — silently breaking campsite level progression.

**2. Garden cooldown display off by 1 minute at boundaries** - `int(tend_cooldown / 60) + 1` showed "2 minutes" when exactly 60 seconds remained. Changed to `ceili(tend_cooldown / 60.0)` for correct ceiling rounding. Affected both the interaction notification and the interaction prompt text.

**3. Fishing pond color changes after respawn** - Original pond water color was `Color(0.15, 0.42, 0.55, 0.72)` but `respawn()` restored it to `Color(0.15, 0.35, 0.45, 0.75)` — noticeably darker and greener. Fixed to use the exact original color.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/core/save_load.gd` | Modified | Fixed inventory key lookups: `"Fishing Rod"` → `"fishing_rod"`, `"Stone Axe"` → `"stone_axe"` |
| `scripts/campsite/structure_garden.gd` | Modified | Fixed cooldown display: `int(x/60)+1` → `ceili(x/60.0)` in 2 places |
| `scripts/resources/fishing_spot.gd` | Modified | Fixed respawn water color to match original `Color(0.15, 0.42, 0.55, 0.72)` |
| `tests/test_bug_regressions.gd` | New | Regression tests for all 3 bugs (12 assertions) |
| `tests/run_all_tests.gd` | Modified | Registered new test file |

### Test Results
- All 544 regression tests pass (12 new)

---

## Session 56 - Code Audit Bug Fixes Round 2 (2026-02-17)

### Bug Fixes

**1. Storage UI signal leak** - `storage_ui.gd` connected `player_inventory.inventory_changed` on open but only disconnected the storage inventory signal on close. After repeated open/close cycles, stale signal connections accumulated, causing `_refresh_lists()` to fire multiple times per inventory change.

**2. Placement system crash on freed structure** - `placement_system.gd` used `not moving_structure` in `_confirm_move()` and `cancel_move()` which doesn't detect freed nodes in Godot. If a structure was destroyed while in move mode, accessing its properties would crash. Changed to `is_instance_valid(moving_structure)`.

**3. HUD notification timer overlap** - `hud.gd` created a new `SceneTreeTimer` for each `show_notification()` call without cancelling the previous one. If notification B fired 2s after notification A, A's 3s timer would hide B after only 1 second. Fixed by tracking the timer and disconnecting the old one before creating a new one.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/ui/storage_ui.gd` | Modified | Added player_inventory signal disconnect in `close_storage()` |
| `scripts/campsite/placement_system.gd` | Modified | `_confirm_move()` and `cancel_move()` use `is_instance_valid()` |
| `scripts/ui/hud.gd` | Modified | Track `_notification_timer`, cancel old timer on new notification |
| `tests/test_bug_regressions.gd` | Modified | Added 3 regression tests (7 new assertions, 19 total) |

### Test Results
- All 551 regression tests pass (7 new)

---

## Session 57 - Code Audit Bug Fixes Round 3 (2026-02-17)

### Bug Fixes

**1. Fire pit state never saved** - `save_load.gd` used `has_method("is_lit")` to detect fire pits, but `is_lit` is a property (`var`), not a method. `has_method()` always returned false, so fire pit lit state was silently dropped from save data. Also added `fuel_remaining` to save/restore, which was never persisted.

**2. Weather forecast lost on load** - `_collect_weather_data()` saved `current_weather` and `duration_remaining` but not `next_weather`. After loading a save, the forecast always reset to CLEAR regardless of what weather was actually predicted. Added `next_weather` to save/restore.

**3. Death doesn't reset movement state** - `_on_player_died()` didn't clear `is_resting`, `is_climbing`, or `is_grappling`. If the player died while resting (e.g., starvation), they'd respawn stuck in resting state and unable to move. Also resets `fall_start_y` to respawn position.

**4. Emergency fall recovery causes false fall damage** - `_recover_from_fall()` teleported the player to safety but didn't reset `fall_start_y` or `is_falling`. The stale height from before the fall caused immediate max fall damage on the next landing after recovery.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/core/save_load.gd` | Modified | Fire pit: `has_method("is_lit")` → `"is_lit" in structure`; added fuel_remaining save/restore; added next_weather to weather save/restore |
| `scripts/player/player_controller.gd` | Modified | Death handler resets is_resting/is_climbing/is_grappling/fall_start_y; fall recovery resets is_falling/fall_start_y |
| `tests/test_bug_regressions.gd` | Modified | Added 4 regression tests (11 new assertions, 30 total) |

### Test Results
- All 562 regression tests pass (11 new)

---

## Session 58 - Code Audit Bug Fixes Round 4 (2026-02-17)

### Bug Fixes

**1. Storage box inventory lost on save/load** - `save_load.gd` had zero code to save or restore storage box contents. Items stored in the storage container were permanently lost on every save/load cycle. Added `storage_items` field to structure save data during collection, and restoring items via `storage_inventory.add_item()` during structure recreation.

**2. Resource harvest timer callback on freed player** - `resource_node.gd` fires `_complete_harvest(player)` after a 0.2s timer delay, but never checked if the player node was still valid. If the player died or the scene transitioned during that window, accessing the freed player reference would crash. Added `is_instance_valid(player)` guard.

**3. Fishing catch callback on freed player** - `fishing_spot.gd` used `if current_player:` in `_attempt_catch()` which doesn't detect freed nodes. Changed to `is_instance_valid(current_player)` to prevent crashes if the player is freed during the fishing wait period.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/core/save_load.gd` | Modified | Save/restore storage inventory contents via `storage_items` in struct_data |
| `scripts/resources/resource_node.gd` | Modified | Added `is_instance_valid(player)` check in `_complete_harvest()` |
| `scripts/resources/fishing_spot.gd` | Modified | Changed `if current_player:` to `is_instance_valid(current_player)` in catch callback |
| `tests/test_bug_regressions.gd` | Modified | Added 3 regression tests (10 new assertions, 40 total) |

### Test Results
- All 572 regression tests pass (10 new)

---

## Session 59 - Code Audit Bug Fixes Round 5 (2026-02-17)

### Bug Fixes

**1. Snare trap state lost on save/load** - `structure_snare_trap.gd` had `get_save_data()` and `load_save_data()` methods to persist bait/catch state, but `save_load.gd` never called them. Snare trap bait type, catch status, and caught animal were all lost on every save/load. Added generic `get_save_data()` / `load_save_data()` calls in the structure collection and recreation pipeline, benefiting any future structures that implement these methods.

**2. Fire menu cooking doesn't verify item removal** - `fire_menu.gd` `_on_cook_pressed()` called `player_inventory.remove_item()` but ignored the return value. If removal failed (e.g., race condition or empty inventory), the player would get free hunger restoration without spending the ingredient. Now captures and checks the return value, aborting if removal fails.

**3. Pause menu unpauses before load attempt** - `pause_menu.gd` `_on_slot_button_pressed()` called `resume_game()` before `load_game_slot()`. If the load failed, the game was already unpaused with no menu visible. Reordered to call `resume_game()` after `load_game_slot()` so the game stays paused if load fails.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/core/save_load.gd` | Modified | Call `get_save_data()` / `load_save_data()` for structures that support them |
| `scripts/ui/fire_menu.gd` | Modified | Check `remove_item()` return value in `_on_cook_pressed()` |
| `scripts/ui/pause_menu.gd` | Modified | Reorder `resume_game()` after `load_game_slot()` in load handler |
| `tests/test_bug_regressions.gd` | Modified | Added 3 regression tests (14 new assertions, 54 total) |

### Test Results
- All 586 regression tests pass (14 new)

---

## Session 60 - Code Audit Bug Fixes Round 6 (2026-02-17)

### Bug Fixes

**1. Storms never extinguish fires** - `weather_manager.gd` used `has_method("is_lit")` to check if a fire pit has fire state, but `is_lit` is a property (var), not a method. `has_method()` always returned false, so the `continue` always fired and storms could never extinguish fires. Same bug pattern as the save_load fire state fix from Round 3. Changed to `"is_lit" in fire`.

**2. Stale interaction target crashes** - `player_controller.gd` used `if current_interaction_target:` (lines 240, 481) to check the target before accessing it. This doesn't detect freed nodes — if a resource was gathered (calls `queue_free()`), accessing methods on the stale reference crashes. Changed both locations to `is_instance_valid(current_interaction_target)`.

**3. Drying rack remove_item unchecked** - `structure_drying_rack.gd` `_start_drying()` called `remove_item()` but ignored the return value. If removal failed, drying would start without consuming the food item. Now checks return value and aborts if removal fails.

**4. Smoker remove_item unchecked** - `structure_smoker.gd` `_start_smoking()` called `remove_item()` twice (meat + wood) without checking either return value. Now checks both: if fuel removal fails after meat was taken, the meat is refunded.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/world/weather_manager.gd` | Modified | Changed `has_method("is_lit")` to `"is_lit" in fire` in storm effect |
| `scripts/player/player_controller.gd` | Modified | Changed interaction target checks to `is_instance_valid()` |
| `scripts/campsite/structure_drying_rack.gd` | Modified | Check `remove_item()` return value in `_start_drying()` |
| `scripts/campsite/structure_smoker.gd` | Modified | Check both `remove_item()` return values, refund meat if fuel removal fails |
| `tests/test_bug_regressions.gd` | Modified | Added 4 regression tests (9 new assertions, 63 total) |

### Test Results
- All 595 regression tests pass (9 new)

---

## Session 61 - Code Audit Bug Fixes Round 7 (2026-02-17)

### Bug Fixes

**1. Crafting partial ingredient loss** - `crafting_system.gd` `craft()` removed ingredients in a loop without checking `remove_item()` return values. If any removal failed mid-loop, previously consumed ingredients were lost but the craft output was still given. Added tracking of consumed items with refund on failure.

**2. Cabin kitchen ingredient duplication** - `cabin_kitchen.gd` `interact()` consumed ingredients without verifying removal success. Same fix pattern: track consumed items and refund if any removal fails.

**3. Resource respawn timing breaks on save/load** - `resource_manager.gd` `get_depleted_data()` saved `depleted_hour` and `depleted_minute` but not `days_elapsed`. On load, the days counter reset to 0, meaning resources that should have respawned already would need to wait the full respawn time again. Added `days_elapsed` to both save and restore.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/crafting/crafting_system.gd` | Modified | Check each `remove_item()` return, refund consumed items on failure |
| `scripts/campsite/cabin_kitchen.gd` | Modified | Check each `remove_item()` return, refund consumed items on failure |
| `scripts/resources/resource_manager.gd` | Modified | Save and restore `days_elapsed` in depleted resource data |
| `tests/test_bug_regressions.gd` | Modified | Added 3 regression tests (7 new assertions, 70 total) |

### Test Results
- All 602 regression tests pass (7 new)

---

## Session 62 - Code Audit Bug Fixes Round 8 (2026-02-17)

### Bug Fixes

**1. Grapple tween callback crashes on dead player** - `grappling_hook.gd` `_on_grapple_complete()` directly accessed `player.global_position` without checking `is_instance_valid(player)`. If the player died during the grapple tween, the callback crashed on the freed reference. Added validity guard that cleans up visuals and exits early.

**2. Death during grapple orphans rope/hook visuals** - `player_controller.gd` `_on_player_died()` set `is_grappling = false` but never called `cancel_grapple()` on the GrapplingHook child node. Rope and hook meshes remained in the scene as orphaned nodes. Now calls `cancel_grapple()` to properly clean up.

**3. Fire pit negative fuel causes negative light energy** - `structure_fire_pit.gd` checked for extinguish (`fuel <= 0`) AFTER the dimming calculation. When `fuel_burn_rate * delta` overshot past zero in a single frame, `dim_factor` went negative, causing negative `light_energy` for one frame. Reordered to check extinguish first, then dim only in the `elif` branch.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/player/grappling_hook.gd` | Modified | Added `is_instance_valid(player)` guard in `_on_grapple_complete()` |
| `scripts/player/player_controller.gd` | Modified | Death handler calls `cancel_grapple()` on GrapplingHook child |
| `scripts/campsite/structure_fire_pit.gd` | Modified | Reordered extinguish check before dimming, fixed misplaced print |
| `tests/test_bug_regressions.gd` | Modified | Added 3 regression tests (6 new assertions, 76 total) |

### Test Results
- All 608 regression tests pass (6 new)

---

## Session 63 - Code Audit Bug Fixes Round 9 (2026-02-17)

### Bug Fixes

**1. Equipment durability goes negative before break check** - `equipment.gd` `use_durability()` subtracted the damage amount without clamping, allowing negative durability values. The `durability_changed` signal emitted these negative values to the HUD before the `<= 0` break check caught them. Fixed by clamping with `max(durability - amount, 0)`. Also added return value check on `remove_item()` in `_break_tool()`.

**2. Equipment upgrade consumes nothing on removal failure** - `equipment.gd` `_use_upgrade()` applied the full durability upgrade (modified `tool_durability`, stored upgrade metadata) then called `remove_item()` without checking its return. If removal failed, the player got a free upgrade. Now checks return value and reverts all upgrade changes on failure.

**3. Placement system places structures without consuming items** - `placement_system.gd` had 4 locations (`place_torch_instant`, `place_lodestone_instant`, `place_lantern_instant`, `_confirm_placement`) that added structures to the scene tree and activated them before calling `remove_item()` without checking the return. If item removal failed, the player got a free structure. Now checks return value and calls `queue_free()` on the placed structure if consumption fails.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/player/equipment.gd` | Modified | Clamp durability to 0, check `remove_item()` in `_break_tool()` and `_use_upgrade()` with revert on failure |
| `scripts/campsite/placement_system.gd` | Modified | Check `remove_item()` return in 4 placement functions, clean up structures on failure |
| `tests/test_bug_regressions.gd` | Modified | Added 3 regression tests (13 new assertions, 89 total) |

### Test Results
- All 621 regression tests pass (13 new)

---

## Session 64 - Code Audit Bug Fixes Round 10 (2026-02-17)

### Bug Fixes

**1. Smithing station ore loss on fuel removal failure** - `structure_smithing_station.gd` `_start_smelting()` called `remove_item()` twice (ore then fuel) without checking returns. If fuel removal failed, the ore was already consumed but smelting never started - player lost ore for nothing. Added return checks with ore refund if fuel removal fails.

**2. Storm fire effects crash on freed fire nodes** - `weather_manager.gd` `_update_storm_fire_effects()` iterated `fire_pits` without `is_instance_valid()` checks. If a fire pit was destroyed during a storm, accessing `is_lit` on the freed node would crash. Also, `fire_storm_timers` dictionary accumulated freed node keys as a memory leak. Added validity check in loop and cleanup pass for freed dictionary keys.

**3. Campsite structure iteration crashes on freed nodes** - `campsite_manager.gd` `get_structures_of_type()` iterated `placed_structures` without `is_instance_valid()` checks. This core function feeds `get_fire_pits()`, `get_shelters()`, and other callers. If a structure was `queue_free()`d but not yet removed from the array, calling `has_method()` on the freed node would crash. Added validity guard.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/campsite/structure_smithing_station.gd` | Modified | Check `remove_item()` returns for ore and fuel, refund ore if fuel fails |
| `scripts/world/weather_manager.gd` | Modified | Add `is_instance_valid(fire)` in storm loop, clean up freed timer keys |
| `scripts/campsite/campsite_manager.gd` | Modified | Add `is_instance_valid(structure)` in `get_structures_of_type()` |
| `tests/test_bug_regressions.gd` | Modified | Added 3 regression tests (6 new assertions, 95 total) |

### Test Results
- All 627 regression tests pass (6 new)

---

## Session 65 - Code Audit Bug Fixes Round 11 (2026-02-17)

### Bug Fixes

**1. Weather fire effectiveness crashes on freed nodes** - `weather_manager.gd` `_update_fire_effectiveness()` iterated `fire_pits` without `is_instance_valid()` checks. We fixed the storm fire loop in Round 10 but missed this second fire iteration function. If a fire pit was destroyed while weather was active, calling `has_method()` on the freed node would crash. Added validity guard.

**2. Music manager infinite recursion on missing tracks** - `music_manager.gd` `_play_next_track()` recursively called itself when a track failed to load. If all 12 tracks were missing (e.g., asset directory not found), this caused infinite recursion and stack overflow crash. Changed to use `call_deferred()` with a bounds check that stops after cycling through all tracks once.

**3. Fire menu division by zero on fuel display** - `fire_menu.gd` calculated `fuel_remaining / max_fuel` without checking if `max_fuel > 0`. If `max_fuel` was 0 (corrupted save data, config error), this would crash with division by zero. Added `max_fuel > 0` guard.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/world/weather_manager.gd` | Modified | Add `is_instance_valid(fire)` in `_update_fire_effectiveness()` |
| `scripts/core/music_manager.gd` | Modified | Replace direct recursion with `call_deferred()` + bounds check |
| `scripts/ui/fire_menu.gd` | Modified | Add `max_fuel > 0` guard before division |
| `tests/test_bug_regressions.gd` | Modified | Added 3 regression tests (5 new assertions, 100 total) |

### Test Results
- All 632 regression tests pass (5 new)

---

## Session 66 - Code Audit Bug Fixes Round 12 (2026-02-17)

### Bug Fixes

**1. Sleep callbacks crash on freed player** - `structure_shelter.gd`, `structure_canvas_tent.gd`, and `cabin_bed.gd` all have `_skip_to_dawn()` / `_do_full_restore()` / `_wake_up()` functions called as async callbacks from `fade_to_black_and_back()`. These fire 2-3 seconds later, but never checked `is_instance_valid(player)`. If the player died during the fade (e.g., starvation), accessing `player.has_node()` on the freed reference would crash. Added validity guards to all 5 affected functions across 3 files.

**2. Garden state lost on save/load** - `structure_garden.gd` had no `get_save_data()` or `load_save_data()` methods. All garden state (`production_timer`, `stored_herbs`, `can_tend`, `tend_cooldown`) was lost on every save/load cycle. Players lost accumulated herbs and cooldowns reset, allowing immediate re-tending. Added both methods with proper serialization.

**3. Shelter resting_player uses truthiness instead of validity** - `structure_shelter.gd` `_on_period_changed()` checked `if is_player_resting and resting_player:` but a freed node passes truthiness in GDScript. Changed to `is_instance_valid(resting_player)` to properly detect freed player during period change signals.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/campsite/structure_shelter.gd` | Modified | `is_instance_valid(player)` in `_skip_to_dawn()`, `is_instance_valid(resting_player)` in `_on_period_changed()` |
| `scripts/campsite/structure_canvas_tent.gd` | Modified | `is_instance_valid(player)` in `_skip_to_dawn()` |
| `scripts/campsite/cabin_bed.gd` | Modified | `is_instance_valid(player)` in `_do_full_restore()` and `_wake_up()` |
| `scripts/campsite/structure_garden.gd` | Modified | Added `get_save_data()` and `load_save_data()` for all state variables |
| `tests/test_bug_regressions.gd` | Modified | Added 3 regression tests (11 new assertions, 111 total) |

### Test Results
- All 643 regression tests pass (11 new)

---

## Session 67 - Code Audit Bug Fixes Round 13 (2026-02-17)

### Bug Fixes

**1. Creature freed-player crashes in base class, bird, and rabbit** - `ambient_animal_base.gd`, `ambient_bird.gd`, and `ambient_rabbit.gd` all used `if player and` or `if player:` to check the cached player reference, but freed nodes pass truthiness in GDScript. If the player died while creatures were active (fleeing, chirping, hopping), accessing methods on the freed reference would crash. Changed 6 locations across 3 files to use `is_instance_valid(player)`.

**2. Cave darkness overlay tween accumulation** - `cave_transition.gd` `_update_darkness_overlay()` created a new tween every call without killing the previous one. Rapid light source toggling (equipping/unequipping torch) accumulated orphan tweens fighting over the overlay alpha, causing visual glitches. Added a `darkness_tween` member variable and `kill()` call before creating each new tween.

**3. Save/load position dictionary unsafe access** - `save_load.gd` accessed campsite position with `pos["x"]` and `pos["z"]` which crashes if the key is missing (corrupted save data). Changed to `pos.get("x", 0.0)` and `pos.get("z", 0.0)` for safe fallback.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/creatures/ambient_animal_base.gd` | Modified | `is_instance_valid(player)` in `_process()` proximity check |
| `scripts/creatures/ambient_bird.gd` | Modified | `is_instance_valid(player)` in `_chirp()`, `_on_enter_fleeing()`, `_process_fleeing()` |
| `scripts/creatures/ambient_rabbit.gd` | Modified | `is_instance_valid(player)` in hop sound and `_process_fleeing()` |
| `scripts/core/cave_transition.gd` | Modified | Track darkness tween, kill before creating new |
| `scripts/core/save_load.gd` | Modified | Safe `.get()` access for position dictionary |
| `tests/test_bug_regressions.gd` | Modified | Added 3 regression tests (9 new assertions, 120 total) |

### Test Results
- All 652 regression tests pass (9 new)

---

## Session 68 - Code Audit Bug Fixes Round 14 (2026-02-17)

### Bug Fixes

**1. Resting structure freed node crash** - `player_controller.gd` checked `resting_in_structure` with truthiness (`if resting_in_structure:`) instead of `is_instance_valid()`. If the structure was destroyed while the player was resting (e.g., storm damage), calling `interact()` on the freed node would crash. Changed to `is_instance_valid(resting_in_structure)`.

**2. Drying rack state lost on save/load** - `structure_drying_rack.gd` had no `get_save_data()` or `load_save_data()` methods. All drying state (`is_drying`, `current_food`, `drying_progress`) was lost on save/load. Partially-dried food vanished and consumed resources were lost. Added both methods with proper serialization.

**3. Smoker and smithing station state lost on save/load** - `structure_smoker.gd` and `structure_smithing_station.gd` both lacked save/load methods. In-progress smoking/smelting was lost on save/load - consumed resources (meat/ore/wood) vanished with no output. Added `get_save_data()`/`load_save_data()` to both structures.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/player/player_controller.gd` | Modified | `is_instance_valid(resting_in_structure)` instead of truthiness |
| `scripts/campsite/structure_drying_rack.gd` | Modified | Added `get_save_data()` and `load_save_data()` for drying state |
| `scripts/campsite/structure_smoker.gd` | Modified | Added `get_save_data()` and `load_save_data()` for smoking state |
| `scripts/campsite/structure_smithing_station.gd` | Modified | Added `get_save_data()` and `load_save_data()` for smelting state |
| `tests/test_bug_regressions.gd` | Modified | Added 3 regression tests (15 new assertions, 135 total) |

### Test Results
- All 667 regression tests pass (15 new)

---

## Session 69 - Code Audit Bug Fixes Round 15 (2026-02-17)

### Bug Fixes

**1. Climbing structure not reset on death** - `player_controller.gd` death/respawn handler reset `is_climbing = false` and `resting_in_structure = null` but never set `climbing_structure = null`. This left a dangling reference to the ladder. If the structure was later freed, future climbing interactions could crash on the stale reference.

**2. Fishing fail_catch freed player crash** - `fishing_spot.gd` `_fail_catch()` checked `current_player` with truthiness (`if current_player:`) instead of `is_instance_valid()`. If the player died during the catch window, calling `_get_player_equipment()` on the freed reference would crash. Changed to `is_instance_valid(current_player)`.

**3. Crafting recipes status crashes on stale recipe IDs** - `crafting_system.gd` `get_all_recipes_status()` accessed `recipes[recipe_id]` with bracket notation without checking if the recipe existed. If `discovered_recipes` contained a stale ID not in the recipes dictionary (e.g., recipe removed during game updates), this would crash with KeyError. Added `recipes.has(recipe_id)` guard with continue.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/player/player_controller.gd` | Modified | Add `climbing_structure = null` in death/respawn handler |
| `scripts/resources/fishing_spot.gd` | Modified | `is_instance_valid(current_player)` in `_fail_catch()` |
| `scripts/crafting/crafting_system.gd` | Modified | Guard `recipes.has(recipe_id)` in `get_all_recipes_status()` |
| `tests/test_bug_regressions.gd` | Modified | Added 3 regression tests (5 new assertions, 140 total) |

### Test Results
- All 672 regression tests pass (5 new)

---

## Session 70 - Code Audit Bug Fixes Round 16 (2026-02-17)

### Bug Fixes

**1. Grapple interpolation crashes on freed player** - `grappling_hook.gd` `_interpolate_grapple()` checked player with truthiness (`not player`) instead of `is_instance_valid()`. This tween method runs every frame during grapple ascent. If the player died mid-grapple, the tween would continue and crash when setting `global_position` on the freed node. The completion callback `_on_grapple_complete()` already used `is_instance_valid()` but the per-frame interpolation did not.

**2. Cave resource depleted signal crashes on freed node** - `cave_entrance.gd` `_on_resource_depleted()` accessed `res_node.name` without validating the node was still valid. If a cave resource node was freed between signal connection and emission (e.g., chunk unloading), this would crash. Added `is_instance_valid(res_node)` guard.

**3. Fire menu crashes on destroyed fire pit** - `fire_menu.gd` checked `current_fire` with truthiness instead of `is_instance_valid()` before accessing fuel properties. If the fire pit was destroyed while the menu was open (e.g., storm damage), accessing `fuel_remaining`/`max_fuel` on the freed node would crash.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/player/grappling_hook.gd` | Modified | `is_instance_valid(player)` in `_interpolate_grapple()` |
| `scripts/world/cave_entrance.gd` | Modified | `is_instance_valid(res_node)` in `_on_resource_depleted()` |
| `scripts/ui/fire_menu.gd` | Modified | `is_instance_valid(current_fire)` in fuel display |
| `tests/test_bug_regressions.gd` | Modified | Added 3 regression tests (3 new assertions, 143 total) |

### Test Results
- All 675 regression tests pass (3 new)

---

## Session 71 - Code Audit Bug Fixes Round 17 (2026-02-17)

### Bug Fixes

**1. Fishing visual callbacks crash on freed nodes** - `equipment.gd` `_hide_fishing_visuals()` and `hide_fishing_line()` checked `caught_fish_model` and `line_pivot` with truthiness instead of `is_instance_valid()`. These are called as tween callbacks or from `fishing_spot._fail_catch()`. If the nodes were freed via `_remove_fishing_rod()` (unequip during animation, death), accessing `.visible` on the freed reference would crash.

**2. Snare trap bait not checking remove_item** - `structure_snare_trap.gd` `_set_bait()` called `remove_item()` without checking the return value. If removal failed (race condition between has_item check and remove), the trap became baited without consuming the bait item, duplicating resources.

**3. Fire menu fuel not checking remove_item** - `fire_menu.gd` `_on_add_fuel_pressed()` called `remove_item("wood", 1)` without checking the return value. If removal failed, `add_fuel()` was called anyway, giving free fire fuel without consuming wood.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/player/equipment.gd` | Modified | `is_instance_valid()` in `_hide_fishing_visuals()` and `hide_fishing_line()` |
| `scripts/campsite/structure_snare_trap.gd` | Modified | Check `remove_item()` return in `_set_bait()` |
| `scripts/ui/fire_menu.gd` | Modified | Check `remove_item()` return in `_on_add_fuel_pressed()` |
| `tests/test_bug_regressions.gd` | Modified | Added 3 regression tests (7 new assertions, 150 total) |

### Test Results
- All 682 regression tests pass (7 new)

---

## Session 72 - Code Audit Bug Fixes Round 18 (2026-02-17)

### Bug Fixes

**1. Fire pit warmth division by zero** - `structure_fire_pit.gd` `get_warmth_at()` divided `distance / warmth_radius` without checking if `warmth_radius` was 0. During storms, `set_effectiveness(0.0)` sets `warmth_radius = base_warmth_radius * 0.0 = 0.0`. If a player stood at the exact fire position, `0.0 / 0.0` produced NaN, corrupting warmth calculations. Added `warmth_radius <= 0.0` guard.

**2. Storm fire effects crash on freed player** - `weather_manager.gd` `_update_storm_fire_effects()` checked `player` with truthiness (`if player else`) instead of `is_instance_valid()`. This function runs independently during storms without the player guard in `_apply_weather_effects()`. If the player was freed, accessing `global_position` on the freed node would crash.

**3. Fire menu action handlers crash on freed fire pit** - `fire_menu.gd` action handlers (`_on_warm_up_pressed`, `_on_cook_pressed`, `_on_add_fuel_pressed`) all checked `current_fire` with truthiness instead of `is_instance_valid()`. We fixed the fuel display in Round 16 but missed 3 remaining handlers. If the fire pit was destroyed while the menu was open, calling methods on the freed node would crash.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/campsite/structure_fire_pit.gd` | Modified | Add `warmth_radius <= 0.0` guard in `get_warmth_at()` |
| `scripts/world/weather_manager.gd` | Modified | `is_instance_valid(player)` in `_update_storm_fire_effects()` |
| `scripts/ui/fire_menu.gd` | Modified | `is_instance_valid(current_fire)` in 3 action handlers |
| `tests/test_bug_regressions.gd` | Modified | Added 3 regression tests (5 new assertions, 155 total) |

### Test Results
- All 687 regression tests pass (5 new)

---

## Session 73 - Code Audit Bug Fixes Round 19 (2026-02-17)

### Bug Fixes

**1. Move structure crash on freed interaction target** - `player_controller.gd` `_try_move_structure()` checked `current_interaction_target` with truthiness instead of `is_instance_valid()`. If the target node was freed (e.g., structure destroyed by another system) between raycast detection and the move attempt, truthiness would pass but `is_in_group("structure")` would crash on the freed node.

**2. Weather vane crash on freed arrow pivot** - `structure_weather_vane.gd` `_process()` checked `arrow_pivot` with truthiness instead of `is_instance_valid()`. If the child node was freed during scene transitions or tree restructuring, truthiness would pass but accessing `.rotation.y` on the freed node would crash. This runs every frame, making it a high-frequency crash risk.

**3. Grapple rope normalize-before-check logic bug** - `grappling_hook.gd` `_update_rope_visual()` called `(to - from).normalized()` then checked `direction.length() > 0.001`. Since `normalized()` always returns length 0 (for zero vectors) or ~1.0, the guard was ineffective — any non-zero distance passed the check. When `from` and `to` were very close but not identical, `look_at()` was called with near-overlapping positions, causing visual glitches. Fixed by checking the actual distance (`length`) before normalizing.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/player/player_controller.gd` | Modified | `is_instance_valid(current_interaction_target)` in `_try_move_structure()` |
| `scripts/campsite/structure_weather_vane.gd` | Modified | `is_instance_valid(arrow_pivot)` in `_process()` |
| `scripts/player/grappling_hook.gd` | Modified | Check `length > 0.001` before normalizing in `_update_rope_visual()` |
| `tests/test_bug_regressions.gd` | Modified | Added 3 regression tests (4 new assertions, 159 total) |

### Test Results
- All 691 regression tests pass (4 new)

---

## Session 74 - Code Audit Bug Fixes Round 20 (2026-02-17)

### Bug Fixes

**1. HUD interaction target crash on freed node** - `hud.gd` `_on_interaction_target_changed()` checked `target` with truthiness instead of `is_instance_valid()`. This is a signal handler — the target node could be freed between signal emission and handler execution. Truthiness passes for freed nodes, so `is_in_group("structure")` would crash when trying to add the move hint to the interaction prompt.

**2. Storage UI item duplication on failed transfer** - `storage_ui.gd` `_on_transfer_pressed()` and `_on_transfer_all_pressed()` called `remove_item()` without checking the return value. If removal failed (item consumed by another system between check and removal), the item was still added to the destination, duplicating items. Fixed all 4 transfer paths to check the `remove_item()` return before calling `add_item()`.

**3. Storm fire tending check uses freed player truthiness** - `weather_manager.gd` `_update_storm_fire_effects()` line 161 checked `player` with truthiness in the `is_tending` calculation. Line 149 already correctly used `is_instance_valid(player)` for computing `player_pos`, but this leftover truthiness check could incorrectly mark fires near the world origin as "tended" when the player was freed.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/ui/hud.gd` | Modified | `is_instance_valid(target)` in `_on_interaction_target_changed()` |
| `scripts/ui/storage_ui.gd` | Modified | Check `remove_item()` return in all 4 transfer paths |
| `scripts/world/weather_manager.gd` | Modified | `is_instance_valid(player)` in storm tending check |
| `tests/test_bug_regressions.gd` | Modified | Added 3 regression tests (4 new assertions, 163 total) |

### Test Results
- All 695 regression tests pass (4 new)

---

## Next Session

## Session 75 - Code Audit Bug Fixes Round 21 (2026-02-17)

### Bug Fixes

**1. Shelter sleep crash on freed time_manager** - `structure_shelter.gd` `_skip_to_dawn()` accessed `time_manager` properties (current_day, current_hour, etc.) without `is_instance_valid()` check. This function is called as a tween callback after a 1-second fade delay. If the scene transitions during the fade, `time_manager` could be freed, and all property accesses would crash.

**2. Cabin bed sleep crash on freed time_manager** - `cabin_bed.gd` `_skip_to_dawn()` had the same issue — accessed `time_manager` properties without validity check in a deferred tween callback. Same 1-second window where scene transitions could free the time_manager.

**3. Player stats division by zero in percent getters** - `player_stats.gd` `get_health_percent()` and `get_hunger_percent()` divided by `max_health` and `max_hunger` without zero guards. If save data is corrupted or values reset to 0, division by zero produces NaN that propagates through HUD progress bars and warmth calculations. Added `<= 0.0` guard returning 0.0.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/campsite/structure_shelter.gd` | Modified | Add `is_instance_valid(time_manager)` guard in `_skip_to_dawn()` |
| `scripts/campsite/cabin_bed.gd` | Modified | Add `is_instance_valid(time_manager)` guard in `_skip_to_dawn()` |
| `scripts/player/player_stats.gd` | Modified | Add zero guards in `get_health_percent()` and `get_hunger_percent()` |
| `tests/test_bug_regressions.gd` | Modified | Added 3 regression tests (4 new assertions, 167 total) |

### Test Results
- All 699 regression tests pass (4 new)

---

## Session 76 - Code Audit Bug Fixes Round 22 (2026-02-17)

### Bug Fixes

**1. Drying rack crash on freed player_inventory** - `structure_drying_rack.gd` `_complete_drying()` checked `player_inventory` with truthiness (`if player_inventory:`) instead of `is_instance_valid()`. The `player_inventory` reference is stored during `interact()` but `_complete_drying()` fires from `_process()` after 60 seconds of drying time. If the player dies or the scene transitions during drying, the stale reference passes truthiness but calling `.add_item()` on the freed node crashes.

**2. Smoker crash on freed player_inventory** - `structure_smoker.gd` `_complete_smoking()` had the same stale `player_inventory` truthiness issue. Smoking takes 180 seconds, giving a 3-minute window where the player could die or leave, leaving a dangling reference that crashes on `.add_item()`.

**3. Smithing station crash on freed player_inventory** - `structure_smithing_station.gd` `_complete_smelting()` had the same pattern. Smelting takes 120 seconds. All three structures now use `is_instance_valid(player_inventory)` in their completion callbacks.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/campsite/structure_drying_rack.gd` | Modified | `is_instance_valid(player_inventory)` in `_complete_drying()` |
| `scripts/campsite/structure_smoker.gd` | Modified | `is_instance_valid(player_inventory)` in `_complete_smoking()` |
| `scripts/campsite/structure_smithing_station.gd` | Modified | `is_instance_valid(player_inventory)` in `_complete_smelting()` |
| `tests/test_bug_regressions.gd` | Modified | Added 3 regression tests (3 new assertions, 170 total) |

### Test Results
- All 702 regression tests pass (3 new)

---

## Session 77 - Code Audit Bug Fixes Round 23 (2026-02-17)

### Bug Fixes

**1. Fire pit light crash on freed node in _process()** - `structure_fire_pit.gd` `_process()` checked `fire_light` with truthiness (`and fire_light:`) in the dimming code. If the FireLight child node was freed externally, the freed reference passes truthiness and accessing `.light_energy` crashes. Changed to `is_instance_valid(fire_light)`.

**2. Fire pit flare crash on freed light node** - `structure_fire_pit.gd` `flare()` checked `fire_light` with truthiness (`if not fire_light`) instead of `is_instance_valid()`. A freed node passes truthiness so the guard wouldn't trigger, and the subsequent `.light_energy` access and tween would crash. Changed to `is_instance_valid(fire_light)`.

**3. Fire pit unchecked wood removal on lighting** - `structure_fire_pit.gd` `interact()` called `inventory.remove_item("wood", 1)` without checking the return value. If removal failed, the code still set `fuel_remaining = max_fuel` and lit the fire, giving the player free fuel without consuming wood. Now checks return value and aborts on failure.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/campsite/structure_fire_pit.gd` | Modified | `is_instance_valid(fire_light)` in `_process()` and `flare()`, check `remove_item` return in `interact()` |
| `tests/test_bug_regressions.gd` | Modified | Added 3 regression tests (4 new assertions, 174 total) |

### Test Results
- All 706 regression tests pass (4 new)

---

## Session 78 - Code Audit Bug Fixes Round 24 (2026-02-17)

### Bug Fixes

**1. Canvas tent sleep crash on freed time_manager** - `structure_canvas_tent.gd` `_skip_to_dawn()` overrides the parent shelter method but forgot the `is_instance_valid(time_manager)` guard. We fixed this in `structure_shelter.gd` and `cabin_bed.gd` in Round 21 but missed the canvas tent override. The callback fires after a 1-second fade delay via tween, during which a scene transition could free the time_manager.

**2. Free healing/food via unchecked remove_item in _try_eat** - `player_controller.gd` `_try_eat()` called `remove_item()` for both healing items (line 613) and food (line 629) without checking the return value. If removal failed, `stats.heal()` or `stats.eat()` still executed, giving the player free healing/hunger without consuming items.

**3. Free campfire via unchecked remove_item** - `equipment.gd` `_legacy_place_campfire()` placed the campfire in the scene (`add_child`) BEFORE calling `remove_item("campfire_kit", 1)` and didn't check the return value. If removal failed, the player got a free campfire without consuming the kit. Now checks return and cleans up the campfire on failure.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/campsite/structure_canvas_tent.gd` | Modified | Add `is_instance_valid(time_manager)` guard in `_skip_to_dawn()` |
| `scripts/player/player_controller.gd` | Modified | Check `remove_item` return in `_try_eat()` for both healing and food |
| `scripts/player/equipment.gd` | Modified | Check `remove_item` return in `_legacy_place_campfire()`, cleanup on failure |
| `tests/test_bug_regressions.gd` | Modified | Added 3 regression tests (4 new assertions, 178 total) |

### Test Results
- All 710 regression tests pass (4 new)

---

## Session 79 - Code Audit Bug Fixes Round 25 (2026-02-18)

### Overview
Comprehensive bug hunt Round 1: Launched 5 parallel agents to search for Vector3 truthiness, null/freed node access, dictionary access, signal/connection, and logic/game mechanic bugs. Found and fixed 10 bugs across the codebase.

### Bug Fixes

**1. Zero-vector normalization NaN crashes (6 sites)** - `grappling_hook.gd`, `placement_system.gd` (x4), `hud.gd`, `ambient_animal_base.gd`, `ambient_bird.gd`, `ambient_rabbit.gd` all called `.normalized()` on vectors that could be zero-length, producing NaN values that propagated through physics. Added `length_squared() > 0.001` guards with sensible fallbacks.

**2. Freed node access crashes (4 sites)** - `weather_manager.gd` (x3) and `chunk_manager.gd` used bare truthiness checks (`if not player`) instead of `is_instance_valid()`, which fails to detect freed nodes. Changed to proper validity checks.

**3. Bark map rivers invisible** - `bark_map_ui.gd` used wrong dictionary keys `river.get("start")`/`river.get("end")` but rivers use a `"path"` array of points. Fixed to iterate `river.get("path", [])` segments.

**4. Rest state soft-lock** - `player_controller.gd` set `is_resting = true` when entering a shelter but never cleared it if the shelter was freed (demolished/scene transition). Added `is_instance_valid(resting_in_structure)` check that clears `is_resting` when structure is gone.

**5. Grappling hook scene transition crash** - `grappling_hook.gd` called `get_tree().current_scene.add_child()` without null-checking `current_scene`, which is null during scene transitions.

**6. Osha root only healed, didn't restore hunger** - `player_controller.gd` consumed osha_root as a healing item but didn't check if it was also in FOOD_VALUES to restore hunger simultaneously.

**7. Resource node timer on freed node** - `resource_node.gd` harvest timer callback didn't verify self was still valid before executing.

**8. Signal connection guards (3 sites)** - `structure_shelter.gd`, `campsite_manager.gd`, `weather_manager.gd` connected signals without checking `is_connected()` first, risking duplicate connections.

**9. Float equality in config_menu** - `config_menu.gd` compared float with `!= 1.0` for pluralization, which can fail due to floating-point imprecision. Changed to `is_equal_approx()`.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/player/grappling_hook.gd` | Modified | Zero-vector guard on dismount, null-check `current_scene` before `add_child()` |
| `scripts/campsite/placement_system.gd` | Modified | Zero-vector guards at 4 normalization sites |
| `scripts/ui/hud.gd` | Modified | Compass NaN early return on zero-length forward vector |
| `scripts/creatures/ambient_animal_base.gd` | Modified | Flee direction NaN guard |
| `scripts/creatures/ambient_bird.gd` | Modified | Flight direction NaN guard |
| `scripts/creatures/ambient_rabbit.gd` | Modified | Hop direction NaN guard |
| `scripts/world/weather_manager.gd` | Modified | `is_instance_valid()` for player/stats, `is_connected()` guard |
| `scripts/world/chunk_manager.gd` | Modified | `is_instance_valid(player)` in `_process` |
| `scripts/ui/bark_map_ui.gd` | Modified | River drawing uses `"path"` key segments |
| `scripts/player/player_controller.gd` | Modified | Rest state soft-lock fix, osha_root dual-use |
| `scripts/resources/resource_node.gd` | Modified | Self-validity check in harvest timer |
| `scripts/campsite/structure_shelter.gd` | Modified | Signal connection guard |
| `scripts/campsite/campsite_manager.gd` | Modified | Signal connection guard |
| `scripts/ui/config_menu.gd` | Modified | `is_equal_approx()` for float comparison |
| `tests/test_bug_regressions.gd` | Modified | Added 10 regression tests (24 new assertions) |

### Test Results
- All 734 regression tests pass (24 new)

---

## Session 80 - Code Audit Bug Fixes Round 26 (2026-02-18)

### Overview
Comprehensive bug hunt Round 2: Launched 5 more parallel agents focusing on save/load data integrity, UI/HUD display, race conditions, dead code/logic errors, and gameplay/balance bugs. Found and fixed 19 bugs ranging from critical save/load issues to medium gameplay polish.

### Bug Fixes

**Critical:**

**1. Cave darkness damage never applies** - `cave_transition.gd` called `player.take_damage()` directly, but damage is handled by the `PlayerStats` child node. The player node has no `take_damage` method, so darkness damage was silently ignored. Now gets `PlayerStats` via `get_node_or_null("PlayerStats")`.

**2. Save/load campsite race condition** - `save_load.gd` called `_apply_campsite_data()` (which builds structures with awaits for frame batching) and `_apply_save_data()` without `await`, causing subsequent code to execute before structures were built. Added `await` to both calls, and propagated `await` to `load_game()` and deferred loader.

**3. Config settings not saved/restored** - Game settings (hunger, weather damage, day length, etc.) were lost on reload. Added `get_config()`/`apply_config()` to `config_menu.gd` and integrated with save/load system. Fixed wrong variable names in `apply_config` (`health_drain_toggle` → `health_toggle`, `coordinates_toggle` → `show_coordinates_toggle`).

**4. Processing structures lose output after reload** - `structure_drying_rack.gd`, `structure_smoker.gd`, `structure_smithing_station.gd` cached `player_inventory` at build time. After save/reload, the cached reference was stale (freed), so completed items vanished. Now looks up player via `get_first_node_in_group("player")` at completion time.

**5. Cave state not persisted** - `cave_transition.gd` didn't save `is_in_cave`, `current_cave_id`, or `is_dark`. Loading while in a cave would lose all cave state. Added these fields to `get_save_data()`/`load_save_data()`.

**High:**

**6. use_equipped fires during placement** - `player_controller.gd` processed `use_equipped` even when placement system was active (placing/moving structures), consuming items unintentionally. Now checks `is_placing`/`is_moving` and skips.

**7. K/L keys active when config menu closed** - `config_menu.gd` K/L key handlers toggled settings even when the menu was closed, interfering with gameplay. Added `is_visible` check.

**8. Unlimited fire healing** - Fire warmup had no cooldown, allowing players to spam warmth repeatedly. Added 30-second cooldown timer.

**9. Fire cooking doesn't produce items** - Cooking at fire directly restored hunger instead of producing cooked items in inventory, bypassing the food system. Changed to `player_inventory.add_item(output_item, 1)`.

**10. Cooking at extinguished fire** - No check for `fire.is_lit` before allowing cook/warm actions. Added `is_lit` check to both `_on_cook_pressed()` and `_on_warm_up_pressed()`.

**11. Celebration input not consumed** - HUD celebration dialog didn't call `set_input_as_handled()`, allowing key presses to leak through to gameplay.

**Medium:**

**12. No raw_meat cooking recipe** - `fire_menu.gd` had no recipe for `raw_meat`, making hunted meat uncookable. Added `"raw_meat": {"output": "cooked_meat", "hunger": 35}`.

**13. dried_herb unconsumable** - `dried_herb` had no entry in `FOOD_VALUES`, making it a dead-end crafting product. Added `"dried_herb": 8.0`.

**14. Fishing always respawns on day change** - `fishing_spot.gd` `_on_day_changed` always respawned fish regardless of depletion time. Now checks hours elapsed vs `respawn_time_hours`.

**15. Weather _rolled_today not saved** - `save_load.gd` didn't save/restore `_rolled_today` or `weather_enabled`, causing weather to re-roll on load. Added both to `_collect_weather_data()` and `_apply_weather_data()`.

**16. Equipment menu cursor visibility** - `equipment_menu.gd` didn't show/hide mouse cursor when opening/closing. Added `MOUSE_MODE_VISIBLE`/`MOUSE_MODE_CAPTURED` toggling.

**17. HUD weather display stale after load** - `hud.gd` didn't refresh weather display after game load. Added `_on_weather_changed` call in `_on_game_loaded`.

**18. Return-by-reference bugs (3 sites)** - `crafting_system.gd` `get_discovered_recipes()` and `get_recipe()`, `campsite_manager.gd` `get_placed_structures()` all returned internal data by reference, allowing callers to mutate internal state. Now return `.duplicate()`.

**19. cave_resource_state returned by reference** - `cave_transition.gd` `get_save_data()` returned `cave_resource_state` by reference. Now uses `.duplicate(true)` for deep copy.

### Modified Files
| File | Type | Changes |
|------|------|---------|
| `scripts/core/cave_transition.gd` | Modified | Darkness damage uses PlayerStats, save/load state, deep duplicate |
| `scripts/core/save_load.gd` | Modified | await campsite/save data, config save/load, weather rolled_today, await propagation |
| `scripts/ui/config_menu.gd` | Modified | `apply_config()` method, K/L visibility check, fixed variable names |
| `scripts/campsite/structure_drying_rack.gd` | Modified | Fresh player inventory lookup on completion |
| `scripts/campsite/structure_smoker.gd` | Modified | Fresh player inventory lookup on completion |
| `scripts/campsite/structure_smithing_station.gd` | Modified | Fresh player inventory lookup on completion |
| `scripts/player/player_controller.gd` | Modified | Skip use_equipped during placement, dried_herb in FOOD_VALUES |
| `scripts/ui/fire_menu.gd` | Modified | raw_meat recipe, warmup cooldown, is_lit checks, inventory-based cooking |
| `scripts/ui/hud.gd` | Modified | Celebration input consumed, weather refresh after load |
| `scripts/ui/equipment_menu.gd` | Modified | Mouse cursor visibility on toggle |
| `scripts/resources/fishing_spot.gd` | Modified | Hour-based respawn check |
| `scripts/crafting/crafting_system.gd` | Modified | `.duplicate()` in getters |
| `scripts/campsite/campsite_manager.gd` | Modified | `.duplicate()` in get_placed_structures |
| `tests/test_bug_regressions.gd` | Modified | Added 19 regression tests (57 new assertions) |

### Test Results
- All 791 regression tests pass (57 new)

---

## Session 81 — Round 3 Bug Fixes (17 Bugs)

### Overview
Third round of systematic bug hunting using 5 parallel specialized agents: resource/economy exploits, state machine bugs, math/physics errors, input handling issues, and memory/lifecycle problems. Found and fixed 17 bugs across 10 source files. Added 17 regression tests (51 assertions).

### Bugs Fixed

#### Critical
1. **Fishing spot permanent depletion** — Respawn calculation used wrong day reference (`current_day` instead of `depleted_day`), causing fish to never respawn after depletion across day boundaries. Added `depleted_day` tracking variable.

#### High Priority
2. **Death doesn't reset water state** — Player remained in swimming state after dying in water. Added `is_in_water = false`, `_water_area_count = 0`, `_hide_underwater_effect()` to death handler.
3. **Cave transition type mismatch** — `current_cave_id` default was `""` (string) but code expects `int`. Changed to `-1`.
4. **Equipment _input no UI guards** — Equipment hotkeys worked while crafting/storage menus were open. Added `_is_ui_blocking_input()` check.
5. **Player actions not blocked by UI** — Interact, eat, equip/unequip actions fired through open menus. Added UI blocking check to `_input()`.
6. **Movement not blocked by UI** — WASD movement and sprint worked while menus were open. Added UI blocking to `_process_normal_movement` and `_process_swimming`.
7. **Placement null inventory** — `_confirm_placement` silently skipped item consumption when inventory was null, giving free structures. Changed to early abort with `queue_free()`.

#### Medium Priority
8. **Equipped items transferable to storage** — Could transfer equipped items creating phantom equipped state. Added `_unequip_if_equipped()` before player→storage transfers.
9. **Death doesn't close menus** — UI menus stayed open after death with stale data. Added `_close_all_menus()` to death handler.
10. **Window refocus** — Alt-tab didn't restore mouse capture. Added `NOTIFICATION_WM_WINDOW_FOCUS_IN` handler.
11. **Camera lerp clamp** — Lerp alpha could exceed 1.0 at low FPS. Added `minf()` clamp.
12. **Grapple cancel input** — Cancel grapple didn't consume input, allowing fallthrough to other handlers.
13. **Placement input consumed** — Placement confirm/cancel didn't consume input events.
14. **Fire pit flare tween** — Multiple flare tweens could stack. Added tween tracking and kill-before-create.
15. **Controller look blocked** — Right-stick camera look worked through open menus. Added UI blocking gate.
16. **Water ref-counting** — Overlapping water areas caused stuck swimming state. Added `_water_area_count` ref counter.
17. **Menu overlap** — Equipment and crafting menus could open simultaneously. Added `_is_other_menu_open()` checks.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/resources/fishing_spot.gd` | Modified | `depleted_day` tracking for correct respawn calculation |
| `scripts/player/player_controller.gd` | Modified | Death resets (water, menus), UI input blocking (actions, movement, sprint, controller look), window refocus, camera lerp clamp, water ref-counting, `_close_all_menus()` |
| `scripts/player/equipment.gd` | Modified | `_is_ui_blocking_input()` guard in `_input()` |
| `scripts/player/grappling_hook.gd` | Modified | Input consumed after grapple cancel |
| `scripts/core/cave_transition.gd` | Modified | `current_cave_id` default changed from `""` to `-1` |
| `scripts/campsite/placement_system.gd` | Modified | Null inventory early abort, input consumption on confirm/cancel |
| `scripts/campsite/structure_fire_pit.gd` | Modified | Flare tween tracking and lifecycle management |
| `scripts/ui/crafting_ui.gd` | Modified | Menu overlap prevention with `_is_other_menu_open()` |
| `scripts/ui/equipment_menu.gd` | Modified | Menu overlap prevention with `_is_other_menu_open()` |
| `scripts/ui/storage_ui.gd` | Modified | `_unequip_if_equipped()` before player→storage transfers |
| `tests/test_bug_regressions.gd` | Modified | Added 17 regression tests (51 new assertions) |

### Test Results
- All 834 regression tests pass (51 new)

---

## Session 83 — Round 5 Bug Fixes (6 Bugs)

### Overview
Fifth round of bug hunting with 6 parallel agents covering: interaction systems, weather/time, campsite structure lifecycle, crafting/inventory, terrain/world gen, and player stats/survival. Found and fixed 6 bugs across 11 source files. Added 9 regression tests (22 assertions).

### Bugs Fixed

#### High Priority
1. **Death signal fires multiple times** — `player_stats.gd` `_update_health()` and `take_damage()` both emitted `player_died` every frame health was <=0 with no guard. Caused multiple death sequences, double XP loss, UI flickering. Added `is_dead` flag that gates all damage processing and signal emission. Reset on respawn in `player_controller.gd`.
2. **Save/load doesn't emit time_changed** — `save_load.gd` `_apply_time_data()` set `current_hour`/`current_minute`/`current_day` on TimeManager but never emitted `time_changed` or `day_changed` signals. HUD time display showed stale time until next in-game minute tick.
3. **Double structure unregistration** — `structure_placed_torch.gd`, `structure_placed_lantern.gd`, `structure_lodestone.gd` all called `_unregister_from_campsite()` manually before `destroy()`. But `destroy()` emits `structure_destroyed` signal which the campsite manager already listens to for unregistration — causing double-unregister and potential errors.
4. **Structures can be placed in water** — `placement_system.gd` `_validate_placement()` checked terrain height and slope but never checked if the position was submerged. Players could place campfire, shelter, etc. in ponds/rivers. Added `is_in_water()` check.

#### Medium Priority
5. **Direct hunger assignment bypasses signals** — `structure_shelter.gd`, `structure_canvas_tent.gd`, `cabin_bed.gd`, `cabin_kitchen.gd` all set `stats.hunger` directly instead of calling `stats.eat()`. This skipped the `hunger_changed` signal, so HUD hunger bar didn't update after sleeping or cooking until next `_process` tick.
6. **Cabin bed direct hunger in both rest paths** — Both `_do_rest()` (daytime) and `_do_full_restore()` (nighttime) used direct assignment. Fixed both to use `stats.eat()`.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/player/player_stats.gd` | Modified | Added `is_dead` guard flag, gates `_update_health`, `take_damage`, signal emission |
| `scripts/player/player_controller.gd` | Modified | Reset `stats.is_dead = false` on respawn |
| `scripts/core/save_load.gd` | Modified | Emit `time_changed` and `day_changed` in `_apply_time_data` |
| `scripts/campsite/structure_placed_torch.gd` | Modified | Removed manual `_unregister_from_campsite()` before `destroy()` |
| `scripts/campsite/structure_placed_lantern.gd` | Modified | Same fix as torch |
| `scripts/campsite/structure_lodestone.gd` | Modified | Same fix as torch |
| `scripts/campsite/placement_system.gd` | Modified | Added `is_in_water()` check in `_validate_placement` |
| `scripts/campsite/structure_shelter.gd` | Modified | `stats.eat(30.0)` instead of direct hunger assignment |
| `scripts/campsite/structure_canvas_tent.gd` | Modified | `stats.eat(SLEEP_HUNGER_RESTORE)` instead of direct assignment |
| `scripts/campsite/cabin_bed.gd` | Modified | `stats.eat()` in both `_do_rest` and `_do_full_restore` |
| `scripts/campsite/cabin_kitchen.gd` | Modified | `player_stats.eat(hunger_restore)` instead of direct assignment |
| `tests/test_bug_regressions.gd` | Modified | Added 9 regression tests (22 new assertions) |

### Test Results
- All 881 regression tests pass (22 new)

---

## Session 82 — Round 4 Bug Fixes (9 Bugs)

### Overview
Fourth round of bug hunting with 6 parallel agents covering: array/index bounds, string/type conversion, timer/tween lifecycle, signal disconnect/cleanup, save/load data integrity, and edge case/boundary conditions. Found and fixed 9 bugs across 6 source files. Added 10 regression tests (25 assertions).

### Bugs Fixed

#### Critical
1. **Player Y position ignored on load when in cave** — `_apply_player_data` always recalculated Y from terrain height, ignoring saved Y. Players who saved while in a cave would be teleported to the terrain surface on load. Now uses saved Y when `is_in_cave` is true.

#### High Priority
2. **Equipment axe_swing_tween created on player** — Tween was `player.create_tween()` but animated `stone_axe_model`/`machete_model` (Equipment children). If Equipment freed, tween ran on invalid nodes. Changed to `create_tween()` (self).
3. **Loading screen orphaned coroutine** — `_finish_loading()` used `await` without checking `is_instance_valid(self)` after timer, causing `create_tween()` on freed node if scene transitioned during delay.

#### Medium Priority
4. **HUD notification timer disconnect without is_connected** — `disconnect()` called without verifying signal was still connected, erroring if timer already fired.
5. **HUD celebration_tween kill without is_valid()** — Inconsistent with fire_pit and other tween patterns. Added `is_valid()` check before `kill()`.
6. **Config menu music settings not saved/restored** — `music_enabled` and `music_volume` missing from `get_config()`/`apply_config()`. Music preferences lost on save/load.
7. **Cave transition light_check_timer not reset on load** — After loading while in a cave, darkness check was delayed up to `DARKNESS_CHECK_INTERVAL` seconds.
8. **Health/hunger not clamped on load** — Corrupted save data could set negative or above-max values. Added `clampf()` to valid ranges.
9. **Structure position defaults use int 0** — Vector3 construction used int defaults instead of float 0.0.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/core/save_load.gd` | Modified | Cave-aware player Y positioning, health/hunger clamping, float defaults |
| `scripts/player/equipment.gd` | Modified | `axe_swing_tween = create_tween()` instead of `player.create_tween()` |
| `scripts/ui/loading_screen.gd` | Modified | `is_instance_valid(self)` check after await |
| `scripts/ui/hud.gd` | Modified | Notification `is_connected` guard, celebration tween `is_valid()` check |
| `scripts/ui/config_menu.gd` | Modified | `music_enabled`/`music_volume` in get_config/apply_config/_apply_config |
| `scripts/core/cave_transition.gd` | Modified | `light_check_timer = 0.0` in load_save_data |
| `tests/test_bug_regressions.gd` | Modified | Added 10 regression tests (25 new assertions) |

### Test Results
- All 859 regression tests pass (25 new)

---

## Session 84 — Round 6 Bug Fixes (11 Bugs)

### Overview
Sixth round of bug hunting with 6 parallel code review agents covering player scripts, campsite scripts, core/save/crafting, UI, world/terrain, and creatures/resources. Found and fixed 11 bugs across 10 source files. Added 13 regression tests (26 assertions).

### Bugs Fixed

#### Critical
1. **Resource respawn timer double-counts days** — `resource_manager.gd` added 1440 minutes when `elapsed < 0` AND added `days_elapsed * 1440`, double-counting day boundaries. Resources respawned ~3x faster than intended after multi-day depletion. Removed the `if elapsed < 0` correction since `days_elapsed` already handles midnight crossings.
2. **global_position set before node in scene tree** — `save_load.gd` `_recreate_structure` set `structure.global_position` before `add_child`, which requires scene tree. Changed to `structure.position`.
3. **Structure registered without being in tree** — Same function registered structure with campsite_manager even when container was null. Moved registration inside container check, added early return with queue_free.
4. **Underwater overlay CanvasLayer leak** — `player_controller.gd` checked `has_node("UnderwaterOverlay")` but the CanvasLayer child is named `"UnderwaterCanvas"`. Check always failed, creating a new CanvasLayer+ColorRect every water entry.

#### High Priority
5. **False fall damage after grapple** — `is_falling` not reset when `set_grappling(false)`, so pre-grapple `fall_start_y` caused incorrect fall damage on landing.
6. **Grapple attach sound fires after cancel** — Timer created for attach sound (0.15s) played even after `cancel_grapple`. Now stores timer reference and disconnects on cancel.
7. **Bird NaN flight target** — `_on_enter_fleeing` called `.normalized()` on zero-length Vector2 when bird is at same position as player. Added `length_squared` guard with random fallback direction.
8. **Freed emitter crash in ambient sound** — `_sync_emitters` called `.stop()` on popped emitter without validity check. Added `is_instance_valid` guard.

#### Medium Priority
9. **Berry bush chop_progress_float not reset** — `berry_bush.respawn()` overrides without calling `super()` and forgot to reset `chop_progress_float`, making bush easier to harvest after respawn.
10. **Fire pit flare/dim light energy fight** — `_process` dim logic and `flare()` tween both wrote `fire_light.light_energy` every frame, interrupting flare visual. Dim logic now skips when flare tween is active.
11. **Freed nodes accumulate in cached arrays** — `save_load.gd` cleared `placed_structures` and `structure_counts` on load but not `_cached_fire_pits`/`_cached_shelters`. Also added `is_instance_valid(self)` guard in shelter/bed `_skip_to_dawn` callbacks.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/resources/resource_manager.gd` | Modified | Removed double day-count in elapsed time calculation |
| `scripts/core/save_load.gd` | Modified | `position` instead of `global_position`, guarded registration, re-validate container after await, clear cached arrays |
| `scripts/player/player_controller.gd` | Modified | Fixed underwater overlay name check, reset `is_falling` on grapple end |
| `scripts/player/grappling_hook.gd` | Modified | Track and cancel attach sound timer |
| `scripts/creatures/ambient_bird.gd` | Modified | Zero-vector guard on flee direction |
| `scripts/core/ambient_sound_manager.gd` | Modified | `is_instance_valid` on popped emitter |
| `scripts/resources/berry_bush.gd` | Modified | Reset `chop_progress_float` in respawn |
| `scripts/campsite/structure_fire_pit.gd` | Modified | Skip dim when flare tween active |
| `scripts/campsite/structure_shelter.gd` | Modified | `is_instance_valid(self)` in `_skip_to_dawn` |
| `scripts/campsite/cabin_bed.gd` | Modified | `is_instance_valid(self)` in `_skip_to_dawn` |
| `tests/test_bug_regressions.gd` | Modified | Added 13 regression tests (26 new assertions) |

### Test Results
- All 911 regression tests pass (30 new)

---

## Session 85 — Round 7 Bug Fixes (8 Bugs)

### Overview
Seventh round of bug fixes targeting world/terrain and UI systems. Found by parallel code review agents from the Round 6 scan. Fixed 8 bugs across 5 source files. Added 8 regression tests (18 assertions).

### Bugs Fixed

#### Critical
1. **environment_manager `get_node()` crash** — Used `get_node()` without null check for `time_manager_path` and `sun_light_path`. Crashes with fatal error if exported NodePath is misconfigured. Changed to `get_node_or_null()` with guards.
2. **Cave flat-zone `break` skips remaining caves** — `chunk_manager.gd` `get_height_at()` used `break` in the cave flat-zone loop when a point was in one cave's falloff zone. This prevented checking remaining caves for flat-zone membership, causing wrong terrain height between adjacent caves. Changed to `continue`.
3. **HUD `get_node()` crash** — Same pattern as environment_manager: `get_node()` for `time_manager` and `player` without null check. Changed to `get_node_or_null()` with guards.

#### High Priority
4. **River miter check after `normalized()`** — `_spawn_entire_river` checked `miter.length() < 0.1` after `.normalized()`, which always returns 1.0. Near-180-degree river bends produced wildly stretched vertices. Now checks unnormalized sum length before normalizing.
5. **Crafting `_restore_focus` steals gameplay input** — `_do_restore_focus()` ran after 2-frame await even if menu was closed, calling `grab_focus()` and stealing input from gameplay. Added `is_open` and `is_instance_valid` guards.
6. **Storage UI freed node access** — `open_storage()` accessed `storage.storage_inventory` without `is_instance_valid` guard. Could crash if storage node freed between signal dispatch and handler.

#### Medium Priority
7. **River material shader recompile** — Each river created a new `StandardMaterial3D`, causing shader recompile stutter (2 rivers = 2 compilations). Added shared material via `_get_river_water_material()` getter.
8. **`_height_limit_cache` unbounded growth** — Dictionary in `_limit_height_difference` grew indefinitely during mountain exploration with no cleanup. Added `HEIGHT_CACHE_MAX_SIZE = 2048` cap with clear-on-overflow.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/world/environment_manager.gd` | Modified | `get_node_or_null()` with guards for time_manager and sun_light |
| `scripts/world/chunk_manager.gd` | Modified | Cave `continue`, height cache cap, shared river material, miter pre-normalize check |
| `scripts/ui/hud.gd` | Modified | `get_node_or_null()` with guards for time_manager and player |
| `scripts/ui/crafting_ui.gd` | Modified | `is_open` and `is_instance_valid` guards in `_do_restore_focus` |
| `scripts/ui/storage_ui.gd` | Modified | `is_instance_valid` guard on storage inventory access |
| `tests/test_bug_regressions.gd` | Modified | Added 8 regression tests (18 new assertions) |

### Test Results
- All 932 regression tests pass (21 new)

---

## Session 86 — Round 8 Bug Fixes (8 Bugs)

### Overview
Eighth round of bug fixes targeting cross-system interactions: death/respawn cleanup, save/load data integrity, chunk management, and terrain height. Found by 5 parallel agents investigating death/respawn, save/load, placement/structures, fishing/weather/fire, and terrain/chunk/cave interactions. Fixed 8 bugs across 6 source files. Added 8 regression tests.

### Bugs Fixed

#### Critical
1. **Cave save/load order** — `_apply_player_data()` read `cave_transition.is_in_cave` BEFORE cave state was loaded, so it was always `false`. Player saved inside a cave would have Y position overwritten by terrain height on load, falling through the cave floor. Moved cave state loading before player data.
2. **Weather effects not restored on load** — `_apply_weather_data()` directly assigned `current_weather` without calling `_set_weather()`, skipping hunger_multiplier, fire effectiveness, and weather_changed signal. Loading a save during rain/storm/heat_wave would not restore gameplay effects or weather particles. Added explicit side-effect replay.

#### High Priority
3. **Shelter `is_player_resting` not reset on death** — When player died while resting in a shelter, the shelter's `is_player_resting` stayed `true`. Later `_on_period_changed` would fire `_trigger_sleep_sequence`, causing a phantom time skip to dawn. Added structure state cleanup in `_on_player_died()`.
4. **CabinBed `is_player_sleeping` not reset on death** — Same issue: `is_player_sleeping` persisted after death. Added cleanup in same block.
5. **PlacementSystem preview not cancelled on death** — Dying while in placement mode left `is_placing = true` and the ghost preview mesh in the scene. Added `cancel_placement()` call in death handler.
6. **FishingSpot state persists after death** — `is_fishing`/`waiting_for_catch`/`current_player` not reset when player died mid-fishing. Timers would fire on an invalid player reference. Added `is_instance_valid(current_player)` check in `_process()`.

#### Medium Priority
7. **Stale chunk queue entries cause terrain holes** — `_load_chunks_around()` didn't filter stale entries from load/unload queues when player oscillated at chunk boundaries. A chunk queued for unload would be removed even though the player moved back and it was needed again, causing brief terrain holes. Added queue filtering.
8. **Height cache key collision at negative coords** — Cache key used `int(x / cell_size)` which truncates toward zero, while terrain snapping uses `floor()`. At negative coordinates, `int(-0.5)=0` but `floor(-0.5)=-1`, causing different terrain cells to share cache keys and produce wrong heights. Changed to `int(floor())`.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/core/save_load.gd` | Modified | Moved cave state loading before player data; added weather side-effect replay |
| `scripts/player/player_controller.gd` | Modified | Death handler: reset shelter/bed state, cancel placement |
| `scripts/resources/fishing_spot.gd` | Modified | `is_instance_valid(current_player)` guard in `_process` |
| `scripts/world/chunk_manager.gd` | Modified | Queue stale entry filtering; `floor()` in height cache key |
| `tests/test_bug_regressions.gd` | Modified | Added 8 regression tests; widened 2 existing search windows |

### Test Results
- All 955 regression tests pass (23 new)

---

## Session 84 - Round 9: Bug Fixes (2026-02-18)

### Summary
Found and fixed 18 bugs across equipment, campsite structures, cave resources, terrain, UI menus, and player stats. Skipped 2 architectural/performance issues (chunk boundary seams, batched collision timing). Total test count: **1000 tests passing**.

### Bugs Fixed

#### Equipment System (6 bugs)
1. **`use_durability()` used raw max instead of upgraded max** — Signal emitted `TOOL_MAX_DURABILITY[item]` instead of `get_equipped_max_durability()`, giving wrong percentage when leather wrap upgrade was applied. Fixed.
2. **Axe swing tween kept running after tool broke** — `_remove_stone_axe()` and `_remove_machete()` didn't kill `axe_swing_tween` before freeing the model node, causing errors on freed node. Added tween kill.
3. **Fishing cast/catch tweens were local vars** — Old tweens couldn't be killed when starting new ones, causing overlapping animations. Added `fishing_cast_tween` and `fish_caught_tween` member vars with kill-on-replace logic.
4. **`_harvest_birch_bark` signal after durability** — `use_durability(1)` was called before `item_used.emit()`, but durability can clear `equipped_item` to `""`, so signal carried wrong item. Swapped order.
5. **Equipment menu missing 11 items** — `EQUIPMENT_SLOTS` only had 14 of 25 equippable items, making metal_axe, machete, lantern, smoker_kit, etc. unequippable for controller users. Added all missing items.
6. **Equipment menu display for items without keyboard shortcut** — Added graceful handling for empty key labels (indented display instead of `[]`).

#### Campsite Structures (3 bugs)
7. **Processing structures silently lost products** — Drying rack, smoker, and smithing station discarded finished products when player inventory was unreachable. Added `pending_output` field that stores the product for later pickup on next interaction, persisted in save data.
8. **Shelter double sleep sequence** — `_on_period_changed` could fire `_trigger_sleep_sequence` while already sleeping (during fade), causing double time skip and double heal. Added `_is_sleeping` guard flag.
9. **Canvas tent `_skip_to_dawn` could access freed self** — Fade callback executed after tent was freed during cave transition. Added `is_instance_valid(self)` check.

#### Cave System (2 bugs)
10. **Cave resource collision stays active after depleted load** — Crystal and rare ore nodes create collision shapes in deferred setup, but `_set_depleted_state(true)` ran before shapes existed, leaving invisible walls. Added post-creation `is_depleted` check to disable collision.
11. **Darkness notification threshold unreachable** — Threshold used `* 0.5` (65s) but first damage was at ~70s, so notification was never shown. Changed to `* 1.5` (75s).

#### Terrain (2 bugs)
12. **Trees placed underwater** — Terrain chunk tree placement didn't check for negative Y heights, placing trees in water bodies. Added `tree_y < 0` guard.
13. **`_get_raw_mountain_height` missing carved neighbor check** — Applied path carving unconditionally, while `get_height_at` required `_has_carved_neighbor`. Height limiter got wrong neighbor data, causing terrain artifacts. Added matching check.

#### UI/Menu (3 bugs)
14. **Config menu Tab during pause got stuck** — Tab key could open config menu during game pause without setting `opened_from_pause_menu`, causing menu to get stuck on close. Added visibility/pause guard.
15. **Pause menu load didn't await async function** — `load_game_slot()` is async but wasn't awaited, causing race condition. Added await with failure handling.
16. **Config menu load didn't await async function** — Same issue as pause menu. Added await with failure handling.

#### Player Stats (1 bug)
17. **`heal()` and `eat()` on dead player** — Shelter sleep sequence could call heal/eat after player death, restoring health/hunger and corrupting dead state. Added `is_dead` guard to both functions.

#### Test (1 fix)
18. **Cave test used wrong respawn constant** — Test used `RESPAWN_HOURS = 72.0` but production uses `CAVE_RESOURCE_RESPAWN_HOURS = 168.0`. Updated to 168h with corrected test values.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/player/equipment.gd` | Modified | Durability signal, tween lifecycle, birch bark signal order, fishing tweens |
| `scripts/player/player_stats.gd` | Modified | `is_dead` guards in `heal()` and `eat()` |
| `scripts/ui/equipment_menu.gd` | Modified | Added 11 missing items, empty key label handling |
| `scripts/ui/config_menu.gd` | Modified | Tab key guard, await load_game_slot |
| `scripts/ui/pause_menu.gd` | Modified | Await load_game_slot with failure handling |
| `scripts/campsite/structure_drying_rack.gd` | Modified | `pending_output` field for product storage |
| `scripts/campsite/structure_smoker.gd` | Modified | `pending_output` field for product storage |
| `scripts/campsite/structure_smithing_station.gd` | Modified | `pending_output` field for product storage |
| `scripts/campsite/structure_shelter.gd` | Modified | `_is_sleeping` double sleep guard |
| `scripts/campsite/structure_canvas_tent.gd` | Modified | `is_instance_valid(self)` in `_skip_to_dawn` |
| `scripts/resources/crystal_node.gd` | Modified | Disable collision when loaded as depleted |
| `scripts/resources/rare_ore_node.gd` | Modified | Disable collision when loaded as depleted |
| `scripts/core/cave_transition.gd` | Modified | Darkness notification threshold fix |
| `scripts/world/terrain_chunk.gd` | Modified | Tree underwater guard |
| `scripts/world/chunk_manager.gd` | Modified | `_has_carved_neighbor` in `_get_raw_mountain_height` |
| `tests/test_cave_transition.gd` | Modified | Updated to 168h respawn constant |
| `tests/test_bug_regressions.gd` | Modified | Added 18 regression tests |

### Test Results
- All 1000 regression tests pass (45 new)

---

## Session 84 - Startup Crash Fix (2026-02-19)

### Overview
Fixed a startup crash caused by node initialization order and a non-fatal scene tree error.

### Bug Fixes (2 fixes)

#### Crash (1 fix)
1. **Startup crash: null `active_player` in MusicManager** — `ConfigMenu._ready()` called `MusicManager.set_music_enabled()` before `MusicManager._ready()` had created the audio players, causing a null reference crash on `active_player.stop()`. Added null guard to `set_music_enabled()` to safely no-op when called before initialization; the `music_enabled` flag is still stored so `_ready()` picks it up.

#### Non-fatal Error (1 fix)
2. **Ambient sound emitter `global_position` before `add_child()`** — `ambient_sound_manager.gd` set `emitter.global_position` before calling `add_child(emitter)`, causing a "not is_inside_tree()" error since `global_position` requires the node to be in the scene tree. Swapped the order so `add_child()` happens first.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/core/music_manager.gd` | Modified | Null guard for `active_player` in `set_music_enabled()` |
| `scripts/core/ambient_sound_manager.gd` | Modified | `add_child()` before `global_position` assignment |
| `tests/test_bug_regressions.gd` | Modified | Added 2 regression tests |

### Test Results
- All 1004 regression tests pass (2 new)

---

## Session 85 - Bug Fixes & Bark Strip Visual (2026-02-19)

### Overview
Fixed 3 crashes (save load, weather type mismatch, scene teardown), fixed creatures moving backwards, and added a visual stripped-bark band on birch trees after bark harvesting.

### Bug Fixes (4 fixes)

#### Crashes (2 fixes)
1. **Load crash: scene teardown null tree** — When loading a saved game with a different world seed, `load_game_slot()` triggers `reload_current_scene()` but the awaiting `pause_menu` still calls `resume_game()`, crashing on `get_tree().paused = false`. Added `is_inside_tree()` guard.

2. **Load crash: Weather enum passed as String** — `hud.gd._on_game_loaded()` called `_on_weather_changed(weather_manager.current_weather)` but `current_weather` is a Weather enum (int), not a String. Changed to `get_weather_name()`.

#### Visual (2 fixes)
3. **Creatures moving backwards** — All creature meshes (rabbit, bird) have faces at +Z, but Godot's `look_at()` orients -Z toward the target by default. Added `use_model_front=true` parameter to all three `look_at()` calls (base class, rabbit, bird).

4. **Birch bark strip visual** — See New Features below.

### New Features (1 feature)

#### Bark Strip Visual
When the machete strips bark from a birch tree, a brown BoxMesh band appears at eye level on the trunk, simulating exposed wood. The band:
- Uses shared static material for performance
- Persists across chunk unloading/reloading via `bark_harvest_tracker`
- Disappears after the 3-day regrowth cooldown expires

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/ui/pause_menu.gd` | Modified | `is_inside_tree()` guard in `resume_game()` |
| `scripts/ui/hud.gd` | Modified | Use `get_weather_name()` instead of raw enum |
| `scripts/creatures/ambient_animal_base.gd` | Modified | `use_model_front=true` in `look_at()` |
| `scripts/creatures/ambient_rabbit.gd` | Modified | `use_model_front=true` in `look_at()` |
| `scripts/creatures/ambient_bird.gd` | Modified | `use_model_front=true` in `look_at()` |
| `scripts/player/equipment.gd` | Modified | Bark strip visual helpers, harvest integration |
| `scripts/world/terrain_chunk.gd` | Modified | Apply bark strips on birch tree spawn |
| `tests/test_bug_regressions.gd` | Modified | Added 7 regression tests |

### Test Results
- All 1023 regression tests pass (17 new)

---

## Session 19 - Bug Fixing Batch (Feb 21, 2026)

### Summary
Fixed 9 gameplay bugs and added a placement cooldown, covering floating trees, torch behavior, HUD prompts, map rendering, and berry bush physics.

### Changes

**1. Fix floating trees in rocky region**
- Trees and resources were calling `get_height_at()` directly, bypassing the post-processed height cache (which includes pit prevention and flat smoothing)
- Added `_get_cached_height_at()` helper to `terrain_chunk.gd` that reads from the height cache, ensuring trees sit at the same height as the terrain mesh

**2. Torch auto-equip on pickup and after placement**
- After placing a torch, if the player has more torches in inventory, the next one auto-equips
- Picking up a placed torch also auto-equips it
- Works in both the primary and fallback placement paths

**3. Fix torch/lantern light not illuminating ground**
- Root cause: terrain material uses `CULL_DISABLED`, causing self-shadowing in the OmniLight3D shadow pass
- Added `shadow_bias = 1.0` and `shadow_normal_bias = 2.0` to all torch and lantern light creation (equipped, placed, and save/loaded)

**4. Fix lodestone HUD prompt persisting after pickup**
- After pickup, `_update_interaction_target()` could re-acquire the queued-for-deletion node in the same frame via raycast
- Added `is_queued_for_deletion()` filter to raycast results and emit `interaction_cleared` in the stale reference check

**5. Clear plants/grass under cabin footprint on placement**
- Added `clear_decorations_in_radius()` to `chunk_manager.gd` that removes grass tufts and flowers within a structure's footprint
- Called from `placement_system.gd` after any structure placement

**6. Persist berry bush collision after harvest**
- Removed the code that disabled `CollisionShape3D` children in `_on_berry_gather_complete()` — bush now keeps its physical collision even when depleted

**7-9. Birchbark map overhaul**
- Rewrote `bark_map_ui.gd` from fullscreen overlay to compact HUD panel on the right side
- Water bodies rendered as blocky grid cells (sampled per-cell) instead of smooth circles
- Added structure icons (cabin, canvas tent, basic shelter) and cave entrance markers
- Map is 700px with semi-transparent terrain colors (0.55 alpha) so game world shows through
- Uses `clip_contents = true` to prevent drawing outside map bounds

**10. Placement cooldown (0.5s)**
- Added cooldown timer to `_place_item()` in `equipment.gd` to prevent rapid-fire torch/lantern/lodestone placement from controller trigger

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `CLAUDE.md` | Modified | Suspended testing rules |
| `scripts/world/terrain_chunk.gd` | Modified | Added `_get_cached_height_at()`, use for tree/resource spawning |
| `scripts/player/equipment.gd` | Modified | Torch auto-equip, shadow bias on torch light, placement cooldown |
| `scripts/campsite/structure_placed_torch.gd` | Modified | Auto-equip torch on pickup |
| `scripts/player/player_controller.gd` | Modified | Lodestone HUD fix, torch auto-equip fallback path |
| `scripts/campsite/placement_system.gd` | Modified | Shadow bias on placed torch/lantern, decoration clearing |
| `scripts/core/save_load.gd` | Modified | Shadow bias on loaded torch/lantern lights |
| `scripts/resources/berry_bush.gd` | Modified | Keep collision after berry harvest |
| `scripts/ui/bark_map_ui.gd` | Modified | Complete rewrite: HUD panel, blocky water, structures, transparency |
| `scripts/world/chunk_manager.gd` | Modified | Added `clear_decorations_in_radius()` |

---

## Session 28 - Death Fade-to-Black & Silent Auto-Save (2026-02-22)

**Death screen fade**: Player death now triggers a cinematic fade-to-black sequence instead of instant teleport. Screen fades to black over 1s, holds black for 1s while the player is teleported to the respawn point, then fades back in over 1s. Uses the existing `HUD.fade_to_black_and_back()` system.

**Silent death auto-save**: The auto-save to slot 5 on death no longer shows "Saved to Slot 5!" notification. Added `silent` parameter to `save_game_slot()` that skips the `game_saved` signal emission, preventing the HUD notification.

**Implementation**: Split `_on_player_died()` into two phases — phase 1 resets stats/states and triggers the fade, phase 2 (`_respawn_after_fade()`) runs as a callback while the screen is black to teleport and notify.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/player/player_controller.gd` | Modified | Split death into fade phases, silent auto-save call |
| `scripts/core/save_load.gd` | Modified | Added `silent` param to `save_game_slot()` |

---

## Session 29 - Smoker & Drying Rack Require Pickup (2026-02-22)

**Require player pickup**: Smoker and drying rack no longer auto-add finished products to the player's inventory. Output is always stored in `pending_output`, requiring the player to return and interact with the structure to collect it. A gold HUD notification ("Smoker finished! Collect your food." / "Drying rack finished! Collect your food.") alerts the player when processing completes.

**What changed**: Removed the auto-add-to-inventory path from `_complete_smoking()` and `_complete_drying()`. The existing `pending_output` + collect-on-interact mechanism (previously only a fallback) is now the primary path. No changes needed to `interact()`, `get_interaction_text()`, save/load, or food visuals — those already handled `pending_output` correctly.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/campsite/structure_smoker.gd` | Modified | `_complete_smoking()` always stores in `pending_output`, adds HUD notification |
| `scripts/campsite/structure_drying_rack.gd` | Modified | `_complete_drying()` always stores in `pending_output`, adds HUD notification |

---

## Session 30 - Save Slot Confirmation & Bubble Improvements (2026-02-22)

**Save slot overwrite confirmation**: Saving to an occupied slot now shows "Overwrite Slot X?" with Yes/No confirmation instead of silently overwriting. Saving to empty slots still works immediately. Default focus on "No" for safety.

**Save slot delete**: Each occupied slot now shows a "Del" button. Pressing it shows "Delete Slot X save?" with Yes/No confirmation. Deleting refreshes the slot list. Delete buttons are hidden for empty slots.

**Confirmation dialog**: New reusable confirmation panel built programmatically (same dark styling as slot panel). Full D-pad/controller navigation support. ui_cancel dismisses back to slot list. Both overwrite and delete share the same panel.

**Bubble HUD doubled size**: Underwater breath bubbles increased from 20px to 40px font size for better visibility.

**Bubble pop sound**: Each time a bubble is lost underwater, a procedural "pop" sound plays. Generated using the same AudioStreamWAV pattern as the fall_hurt sound — high-frequency ping (~800Hz) with rapid decay and noise burst.

**Bubble blink warning**: When the player is down to 2 or fewer bubbles, remaining bubbles blink on/off (0.35s toggle, staying blue) to warn of imminent drowning. Blinking stops when player surfaces or has more than 2 bubbles.

**Smithing station visual feedback**: Smelter now shows clear visual changes during use. Idle: dim fire and light. Smelting: fire flares up (3x emission, pulsing light), ore piece appears on forge and gradually glows orange-hot as progress increases. Complete: ore becomes silver ingot with emission glow, gold HUD notification "Smelting complete! Collect your ingot." Also switched to pickup-required pattern matching smoker/drying rack.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/ui/pause_menu.gd` | Modified | Added confirmation dialog panel, delete buttons per slot, overwrite guard, confirm navigation |
| `scripts/ui/hud.gd` | Modified | Doubled bubble size (20→40px), added blink state/timer, blink warning at ≤2 bubbles |
| `scripts/player/player_controller.gd` | Modified | Play bubble_pop SFX when losing a bubble |
| `scripts/core/sfx_manager.gd` | Modified | Added procedural bubble_pop sound generator, cooldown entry |
| `scripts/campsite/structure_smithing_station.gd` | Modified | Added fire intensity changes, ore/ingot visuals, smelting progress glow, HUD notification, pickup-required pattern |

---

## Session 31 - Fix Osha Root Spawning (2026-02-22)

**Osha root never spawning**: Osha root was configured with elevation thresholds far above actual terrain heights, making it effectively impossible to find. The non-MOUNTAIN check required `res_y > 25.0`, but HILLS terrain tops out at ~10 and ROCKY at ~14. The MOUNTAIN check (`res_y > 20.0`) was barely reachable since mountains peak around 24. Lowered thresholds to match real terrain: MOUNTAIN >8, ROCKY >6, HILLS >5. Also made each region an explicit check instead of a catch-all `elif`.

**Osha root usage**: It's a dual-purpose consumable — restores 20 hunger (like raw meat) and heals 25 health (nearly as good as healing salve at 30). It's the only item that's both food and medicine.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/world/terrain_chunk.gd` | Modified | Lowered osha elevation thresholds to match actual terrain heights per region |

---

## Session 32 - Bow & Arrow System (2026-02-22)

**Bow & arrow weapon system**: Added a complete bow and arrow hunting system. Feathers (from snare traps) now have a crafting purpose — arrow bundles.

**Crafting recipes**:
- Bow: 2 rope + 3 branch (bench, camp level 2)
- Arrow Bundle: 2 feathers + 4 branch → 20 arrows (bench, camp level 2)

**Bow mechanics**: Equip bow, hold right-click to draw (0.5s charge), release to fire. Draw progress affects arrow speed (60%-100%). Minimum 30% draw required to fire. Bow has 80 durability (1 per shot). Each shot consumes 1 arrow from inventory.

**Arrow projectile**: Physics-based RigidBody3D arrows with gravity arc. Arrows orient along their velocity during flight. Miss a target? Arrow sticks in terrain briefly then despawns. Max flight time 4 seconds.

**Animal hunting**: Ambient birds and rabbits are now huntable. Each animal has a StaticBody3D hitbox on collision layer 2 for arrow detection. On hit: death animation (tip over), loot drops to inventory, despawn after 1 second. Birds drop 1 raw meat + 2 feathers. Rabbits drop 1 raw meat + 1 hide.

**Bow visual**: Procedural BoxMesh bow model attached to camera when equipped — two curved limbs, grip, and animated string that pulls back during draw.

**Sound effects**: Three procedural AudioStreamWAV sounds — bow draw (woody creak), bow fire (string twang), arrow hit (impact thud).

**HUD**: Shows arrow count when bow is equipped. Updates live when arrows are consumed. Bow and arrows categorized under Tools in inventory display.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/crafting/crafting_system.gd` | Modified | Added bow and arrow_bundle recipes |
| `scripts/player/equipment.gd` | Modified | Added bow equipment slot (slot 27), durability (80), model create/remove |
| `scripts/player/arrow_projectile.gd` | Created | RigidBody3D arrow with physics, hit detection, procedural mesh |
| `scripts/player/bow_system.gd` | Created | Draw/fire mechanics, arrow spawning, bow model builder |
| `scripts/creatures/ambient_animal_base.gd` | Modified | Added take_hit(), loot drops, hitbox StaticBody3D, ambient_animal group |
| `scripts/creatures/ambient_bird.gd` | Modified | Added loot table (1 meat, 2 feathers) |
| `scripts/creatures/ambient_rabbit.gd` | Modified | Added loot table (1 meat, 1 hide) |
| `scripts/player/player_controller.gd` | Modified | Added BowSystem child, use_equipped guard, TEMP test spawn |
| `scripts/ui/hud.gd` | Modified | Arrow count display, bow/arrows in TOOL_ITEMS, BowSystem signal |
| `scripts/core/sfx_manager.gd` | Modified | Added 3 procedural bow/arrow sounds |

### Known Issues
- TEMP: New games spawn with bow + 20 arrows for testing (remove before release)

---

## Session 33 - Bow Visual Polish & Bird Hunting Balance (2026-02-22)

**Bow visual improvements** (2 iterations based on play-testing screenshots):
- Iteration 1: Replaced flat rectangle bow with multi-segment curved limbs (4 segments per side with progressive taper and tilt), added tip nocks, grip wrap accents, thinner string, pushed model further from camera
- Iteration 2: Flipped bow orientation so limbs curve toward player (+Z) like a real recurve bow. Replaced single sliding straight-line string with two-segment V-string (upper + lower halves from nock tips to center pull point) that creates a realistic V-shape when drawn

**Bird hunting balance**: Birds were nearly impossible to hunt — they had a 12-unit flee distance, only 30% chance to land on the ground, and short idle times. Retuned for huntability:
- Ground perch chance increased from 30% to 55% (birds forage on ground more)
- Ground idle duration extended to 6-15 seconds (was 2-8s), giving time to aim
- Flee distance reduced from 12 to 9 units (bow range is ~40, so plenty of room)
- Elevated perch heights lowered (1.5-4m vs 2-5m)

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/player/bow_system.gd` | Modified | Flipped limb orientation (+Z curve), V-string with upper/lower segments, `_update_string()` and `_position_string_segment()` methods |
| `scripts/creatures/ambient_bird.gd` | Modified | Flee distance 12→9, ground perch 30%→55%, ground idle 6-15s, lower perch heights |

---

## Session 34 - Bow Polish & Arrow Fix (2026-02-22)

**Bow model gap fix**: Closed visible see-through gaps between the grip and limb segments. Limb segments now start at Y=0.02 (overlapping the grip edge at Y=0.03) instead of Y=0.04. Nock positions adjusted to match new limb length.

**Arrow vertical orientation fix**: Arrows shot straight up appeared to fly sideways, and arrows shot straight down were invisible. Root cause: `look_at()` was skipped entirely when velocity was near-vertical (dot product > 0.99 with UP). Fix: switch to `Vector3.FORWARD` as the up reference vector when velocity is within ~25 degrees of vertical, so the arrow always orients along its flight path.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/player/bow_system.gd` | Modified | Limb start Y 0.04→0.02, nock Y 0.245→0.225 |
| `scripts/player/arrow_projectile.gd` | Modified | Use FORWARD as up vector for near-vertical flight |

---

## Session 35 - Map Toggle Fix & Equipment Key Bindings (2026-02-22)

**Map R2 toggle fix**: Birch bark map flickered rapidly when toggling with R2 controller trigger. Root cause was twofold: (1) BarkMapUI's `_input` handler caught the same event that opened the map, immediately closing it, and (2) analog trigger jitter generated multiple events per press causing rapid open/close cycles. After several iterations, solved by moving close detection entirely to `_process` using `Input.is_action_just_pressed()` (Godot's built-in one-frame-per-press debouncing) with a release gate — the map waits for R2 to be fully released before accepting a close press. Equipment side also blocks `_use_map` until R2 is released after each call to prevent reopening.

**Equipment key binding fixes**: Bow and birch bark map were missing from the equipment menu and keyboard shortcuts. Added bow (`\` key, slot 27) to equipment menu. Fixed `]` and other special keys not working on Mac by checking both `physical_keycode` and `keycode` as fallback for all equipment key bindings.

**TEMP test items**: Added birch bark map to test spawn inventory alongside bow and arrows.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/ui/bark_map_ui.gd` | Modified | Replaced `_input` close handler with `_process`-based `is_action_just_pressed` + release gate |
| `scripts/player/equipment.gd` | Modified | Added `_map_open_blocked` release tracking, dual keycode/physical_keycode checks, `\` key for bow |
| `scripts/ui/equipment_menu.gd` | Modified | Added bow entry with `\` key binding |
| `scripts/player/player_controller.gd` | Modified | Added bark_map to TEMP test spawn |

---

## Session 36 - Pinnable Map Overlay (2026-02-23)

**Pinnable map**: Map overlay now stays pinned on the HUD when switching equipment. Previously, switching from map to bow/axe/etc. would auto-close the map overlay. Now: equip map → R2 opens overlay → switch to any tool → overlay stays visible → switch back to map → R2 closes overlay. Three changes: (1) Removed self-close input handling from `bark_map_ui.gd` — MapUI no longer watches for R2 presses, (2) Removed `_close_map_if_open()` call from `equipment.gd:unequip()` so map persists across equipment switches, (3) Made `_use_map()` toggle — if map overlay already exists, close it instead of ignoring.

**Map jitter fix**: Increased `REGATHER_DISTANCE` from 40 to 120 units (3x). The expensive terrain re-sampling was causing frame jitter when running with the map open. The player marker still updates every frame, but the full terrain/water/cave data re-sample now triggers far less often.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/ui/bark_map_ui.gd` | Modified | Removed `_action_released` var and self-close logic from `_process()`; increased `REGATHER_DISTANCE` from 40 to 120 |
| `scripts/player/equipment.gd` | Modified | Removed `_close_map_if_open()` from `unequip()`, made `_use_map()` toggle overlay on/off |

---

## Session 37 - Sky Improvements: Blocky Clouds & Horizon Haze (2026-02-23)

**Blocky voxel clouds**: Added a full cloud system with 30 pre-allocated BoxMesh cloud clusters that drift across the sky. Each cluster is 4-8 overlapping boxes creating puffy rectangular shapes, matching the game's blocky art style. Clouds use a single shared static material for performance.

**Weather integration**: Cloud count, color, opacity, and wind speed change per weather type with smooth 3-second tween transitions:
- Clear: 8 scattered white clouds
- Rain: 18 gray clouds, denser coverage
- Storm: 28 dark clouds, fast movement
- Fog: 5 pale thin clouds
- Heat Wave: 0 clouds (realistic clear sky)
- Cold Snap: 10 ice-tinted clouds

**Time-of-day tinting**: Clouds pick up warm orange-pink tint at dawn/dusk, dim to blue at night (0.3 alpha so stars show through), and appear white during daytime.

**Horizon haze**: Added atmospheric haze band near the horizon using a large inverted cylinder mesh with a gradient shader (quadratic falloff). Color shifts with time of day (warm at dawn/dusk, blue during day, dark at night) and responds to weather (fog intensifies haze, storms darken it).

**Time-scaled cloud speed**: Cloud drift speed scales proportionally with game day length — at 2-minute days, clouds move 10x faster than at the default 20-minute days.

**Day length slider fix**: Config menu slider now increments in whole minutes instead of fractional values.

**Floating grass fix**: Decorative grass and flowers were using raw noise height (`chunk_manager.get_height_at()`) instead of the post-processed height cache (`_get_cached_height_at()`). Rocky terrain applies pit prevention and flat smoothing that lower isolated peaks, but decorations were placed at the un-smoothed height, causing them to float above terrain.

**Moon phase fix**: Moon phases now use alpha transparency instead of a dark shadow overlay. Previously, a dark box was overlaid on the moon to simulate phases, making the new moon appear as a visible black square. Now: full moon = fully visible (alpha 1.0), quarter = partially transparent (0.65), crescent = mostly transparent (0.35), new moon = completely invisible (0.0). Moonlight intensity also scales with phase.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/world/cloud_manager.gd` | Created | 30-cloud pool, BoxMesh clusters, weather/time integration, wind drift with wrapping, time-scaled speed |
| `scripts/world/environment_manager.gd` | Modified | Added horizon haze, moon phase transparency (replacing shadow overlay), haze time-of-day/weather integration |
| `scripts/world/terrain_chunk.gd` | Modified | Fixed grass/flower placement to use `_get_cached_height_at()` instead of raw noise height |
| `scenes/main.tscn` | Modified | Added CloudManager node as child of EnvironmentManager |
| `scenes/ui/config_menu.tscn` | Modified | Day length slider step set to 1.0 (whole minutes) |
| `docs/plans/2026-02-23-sky-clouds-haze-design.md` | Created | Design document for sky improvements |
| `docs/plans/2026-02-23-sky-clouds-haze.md` | Created | Implementation plan |

---

## Session 38 - Environment Polish: Tree Sway & Terrain Scatter (2026-02-23)

**Tree sway animation**: Added a single-manager system (`TreeSway`) that handles wind sway for all trees. Instead of per-tree `_process`, one manager updates 50 trees per frame in a round-robin batch. Foliage nodes translate laterally using sine waves, with higher foliage swaying more (height factor). Distance culling at 80 units. Periodic cleanup of freed tree references every 5 seconds.

**Terrain scatter decorations**: Added three types of purely decorative (no collision) scatter objects to terrain chunks:

- **Boulders**: 2-4 wide, flat overlapping slabs in earthy gray/brown tones. Spawn in all regions with density multipliers (3x rocky, 4x mountain, 2x hills). Visually distinct from small cubic collectible rocks.
- **Bushes**: Organic multi-box clusters with dark/light green core, 3-5 leaf clusters at varied angles, and lighter green top tuft. Forest regions only.
- **Logs/Stumps**: 50/50 chance of fallen log (3-5 unit tapered trunk) or tree stump (solid bark body with inset light wood top face showing ring pattern, grass tufts at base). Forest regions only, sparse.

All scatter objects use shared static materials for performance, respect exclusion zones (ponds, caves, campsite), use `_get_cached_height_at()` for correct placement, and batch-yield during spawning to prevent frame stuttering.

**Slope check**: Added `_is_steep_slope()` helper that samples 4 neighboring terrain heights and rejects decoration placement if any height differs by more than 0.5 units. Prevents boulders and stumps from clipping into terrain step edges.

**Renamed "River Rock" to "Rock"**: Updated display name in `resources.json` and fixed `resource_node.gd` interaction prompt to show "Pick up Rock" instead of "Pick up River Rock".

**Removed legacy markers**: Removed the three placeholder brown box markers (Rock1/Rock2/Rock3) from `main.tscn` that were leftover from early development.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/world/tree_sway.gd` | Created | Single-manager tree sway system with batched updates, distance culling, cleanup |
| `scripts/world/terrain_chunk.gd` | Modified | Added scatter rock/bush/log/stump spawning and mesh builders, shared static materials, slope check, registered trees with TreeSway |
| `scripts/world/chunk_manager.gd` | Modified | Added `tree_sway` reference for terrain chunks to register trees |
| `scripts/resources/resource_node.gd` | Modified | Fixed interaction text to show "Rock" instead of "River Rock" |
| `data/resources.json` | Modified | Changed river_rock display name from "River Rock" to "Rock" |
| `scenes/main.tscn` | Modified | Added TreeSway node, removed legacy Markers/Rock1-3 nodes |

---

## Session 39 - Wilderness Sign, HUD Polish & Bug Fixes (2026-02-23)

**Wilderness information kiosk**: Added a covered kiosk-style sign near the player spawn that displays Carlston Wilderness regulations when the player reads it. The sign is a world fixture (not moveable, not saved) that spawns fresh each session.

**3D sign structure**: Two dark-brown posts with cross beam, angled V-roof with ridge cap, olive/tan information board at eye height, darker header strip, dark frame edges, and angled support braces. All built from BoxMesh primitives with shared static materials. Scaled to 70% of original size via `SIGN_SCALE` constant with a scaled `MeshRoot` container.

**Readable overlay**: Pressing interact opens a full-screen overlay (CanvasLayer 100) styled as a national-park-style information board with forest-green outer panel, tan/cream inner panel, and dark-brown text. Displays "CARLSTON WILDERNESS" title, welcome message, geometric pine tree logo emblem, six regulation bullet points (hunting, swimming, pits, resource collection, severe weather, care), and a dynamic close hint. Overlay freezes the player via `set_resting()` and hides the HUD via `set_overlay_mode()`.

**Viewport-relative text scaling**: All overlay fonts, margins, spacing, and the tree logo scale proportionally to the viewport height relative to a 1080px reference. Labels are registered in a `_scaled_labels` array and rescaled on `_notification(NOTIFICATION_RESIZED)`. Ensures the sign looks good on any screen size.

**Tree logo emblem**: Added a geometric pine tree drawn via `_draw()` polygons on a Control node, using an inline GDScript attached at runtime. The logo sits between the subtitle and regulations header.

**Flat terrain placement**: Sign placement uses `_find_flat_spot_for_sign()` which searches a grid of candidate positions 4-8 units from spawn, samples 5 footprint points per candidate, and picks the position with the least height variance. Sign rotates to face spawn.

**Dynamic close hint**: Close prompt uses `InputManager.get_prompt("interact")` to show the correct button for keyboard vs controller input, instead of hardcoded "[E]".

**HUD overlay mode**: Added `set_overlay_mode(enabled)` to `hud.gd` that hides all HUD panels when an overlay is active. Guarded all three paths that show the interaction prompt panel (`_on_interaction_target_changed`, placement prompt, resting prompt) with `_overlay_active` check to prevent duplicate close prompts.

**HUD label changes**: Renamed health bar label from "HP" to "Health" and hunger bar from "FD" to "Hunger". Added border outlines to both progress bars (2px border with muted color matching each bar) for better visibility as meters deplete. Widened StatsPanel to accommodate longer labels.

**Leather axe wrap fix**: When leather wrap upgrade is applied, axe durability now restores to 100% (the new max) instead of keeping the current worn-down value.

**Shelter exit fix**: Flipped shelter exit position from closed side (+Z) to open side (-Z) so player exits through the shelter opening. Player now faces outward from the shelter.

**Tree sway parse error fix**: Removed stray `1` character in `tree_sway.gd` line 87 that caused "Could not parse global class TreeSway" on launch.

**Animal loot timing fix**: Fixed loot drop timing in `ambient_animal_base.gd` so items spawn after the death animation completes (via tween callback) instead of before.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/world/wilderness_sign.gd` | Created | Full wilderness sign: StructureBase subclass, shared static materials, 3D kiosk mesh at 70% scale, readable overlay with regulations, tree logo, viewport-relative font scaling, flat terrain placement, dynamic close hint, interaction toggle, player freeze/HUD hide |
| `scripts/ui/hud.gd` | Modified | Added `_overlay_active` flag and `set_overlay_mode()` method, guarded all three interaction prompt show paths with overlay check, added `add_to_group("hud")` |
| `scenes/ui/hud.tscn` | Modified | Renamed HP→Health, FD→Hunger, added 2px border outlines to health/hunger progress bars, widened StatsPanel to 520px |
| `scripts/world/chunk_manager.gd` | Modified | Added wilderness sign script loading and spawning with `_find_flat_spot_for_sign()` flat terrain search |
| `scripts/player/equipment.gd` | Modified | Leather axe wrap now restores durability to 100% (new max) |
| `scripts/campsite/structure_shelter.gd` | Modified | Flipped exit offset to -Z (open side), player faces outward |
| `scripts/world/tree_sway.gd` | Fixed | Removed stray character causing parse error |
| `scripts/creatures/ambient_animal_base.gd` | Modified | Loot drops after death animation via tween callback |
| `docs/plans/2026-02-23-wilderness-sign-design.md` | Created | Design document for wilderness sign |
| `docs/plans/2026-02-23-wilderness-sign.md` | Created | Implementation plan |

---

## Session 40 - Desert Biome: World Generation & Content (2026-02-23)

Built the complete desert biome ring (150-250 units from spawn) with terrain generation, flora, fauna, oases with underwater gem mining, and diamond arrow mechanics. Desert uses sandy tan terrain with dune-shaped height variation, 20-unit transition zones blending into adjacent biomes.

### Desert Terrain (Tasks 1, 7, 14)

- Added `DESERT = 5` to RegionType enum with sandy brown color palette and dune height params
- Distance-based biome detection in `get_region_at()`: 170-230 = DESERT, 150-170/230-250 = transition blend
- Desert vegetation spawning: cacti (80% prickly, 20% fruit), palm trees, excludes non-desert trees
- Desert creature spawning: lizards (1-3 per chunk), tortoises (0-1), no rabbits/birds
- Oasis terrain depression: pools sit 4 units below surrounding desert floor
- Transition zone color blending between desert and adjacent biomes

### Flora (Tasks 2, 3)

- **Palm Tree** (`palm_tree.gd`): Procedural Node3D with 4-segment tapered trunk, trunk ring bands, 6 drooping fronds (alternating light/dark green), 2-3 coconuts near crown. All shared static materials.
- **Cactus** (`cactus.gd`): StaticBody3D with two variants. Main column with vertical ridges, 0-2 branching arms, 8 white spines. Prickly variant: Area3D contact damage (8 HP, 1.5s cooldown). Fruit variant: harvestable red fruit on top, interactable/resource_node groups.

### Fauna (Task 4)

- **Ambient Lizard** (`ambient_lizard.gd`): Fast-darting green/brown lizard, non-huntable, small BoxMesh body with legs and tail
- **Ambient Tortoise** (`ambient_tortoise.gd`): Slow olive-green tortoise with domed shell, non-huntable

### Desert Oases (Task 6)

- **Desert Oasis** (`desert_oasis.gd`): 3 oases placed in desert ring (2 diamond, 1 opal). Each has swimmable pool (Area3D water detection), 4-6 palm trees, and underwater gem deposits on pool floor.
- Oasis placement: evenly spaced around desert ring with min 60-unit separation. Desert river routes to opal oasis.
- Water visual: semi-transparent blue disc at surface + darker deep water layer beneath

### Underwater Gem Mining (Task 5)

- **Gem Node** (`gem_node.gd`): Extends ResourceNode, diamond or opal variants. Crystal cluster of 4 angled columns with emission glow, bright tips, glow halo disc, and OmniLight3D. Requires axe, 4 hits to mine. Shared static materials per variant.

### Diamond Arrow Projectile (Task 8)

- **Diamond Arrow** (`diamond_arrow_projectile.gd`): RigidBody3D arrow that persists after impact. Blue-tinted diamond arrowhead with emission glow. Becomes pickable after hitting terrain or animals (adds to "interactable"/"resource_node" groups with enlarged pickup collision). Player recovers arrows via interaction.

### Bow & Equipment Integration (Task 9)

- Bow system prefers diamond arrows over regular arrows when firing
- Enchanted bow: 1.67x draw speed, 1.5x arrow velocity
- Equipment registry: diamond_axe (3.0 effectiveness, 900 durability), enchanted_bow (200 durability)

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/world/chunk_manager.gd` | Modified | DESERT RegionType, region params, oasis generation, desert river, terrain depression |
| `scripts/world/palm_tree.gd` | Created | Procedural palm tree with shared materials |
| `scripts/world/cactus.gd` | Created | Prickly/fruit cactus variants with contact damage |
| `scripts/creatures/ambient_lizard.gd` | Created | Fast-darting desert lizard |
| `scripts/creatures/ambient_tortoise.gd` | Created | Slow desert tortoise |
| `scripts/world/desert_oasis.gd` | Created | Oasis with pool, palms, gem deposits |
| `scripts/resources/gem_node.gd` | Created | Underwater diamond/opal gem resource |
| `scripts/player/diamond_arrow_projectile.gd` | Created | Recoverable diamond arrow |
| `scripts/player/bow_system.gd` | Modified | Diamond arrow preference, enchanted bow bonuses |
| `scripts/player/equipment.gd` | Modified | Diamond axe and enchanted bow stats |
| `scripts/world/terrain_chunk.gd` | Modified | Desert vegetation/creature spawning, transition blending |
| `docs/plans/2026-02-23-desert-biome-design.md` | Created | Desert biome design document |
| `docs/plans/2026-02-23-desert-biome.md` | Created | 16-task implementation plan |

---

## Session 41 - Desert Biome: Items & Crafting Recipes (2026-02-23)

Added desert biome reward-loop items and endgame crafting recipes. Players can now find diamonds and opals in the desert, harvest cactus fruit for food, and craft powerful diamond/enchanted equipment at camp level 3.

### New Inventory Items

- **cactus_fruit**: Desert food item restoring 15 hunger (same as berry). Added to `FOOD_VALUES` in player_controller and `FOOD_ITEMS` in HUD. Cactus already drops this item via `cactus.gd` interaction.
- **diamond**: Crafting material already dropped by `gem_node.gd` diamond variant. No new registration needed (falls into Resources category in HUD).
- **opal**: Crafting material already dropped by `gem_node.gd` opal variant. No new registration needed.
- **diamond_arrows**: Ammo item already handled by `bow_system.gd` (prefers diamond arrows, spawns `DiamondArrowProjectile`). Added to `TOOL_ITEMS` in HUD for categorization.

### New Crafting Recipes (all require bench + camp level 3)

- **Diamond Axe**: 2 diamond + 1 metal_ingot + 1 rope -> diamond_axe (3x effectiveness, 900 durability)
- **Diamond Arrows**: 1 diamond + 5 branch + 2 feathers -> 10 diamond_arrows (recoverable after firing)
- **Enchanted Bow**: 2 opal + 1 bow + 1 rope -> enchanted_bow (50% faster arrows, 200 durability)

### HUD Updates

- Added `diamond_axe`, `enchanted_bow`, `diamond_arrows` to TOOL_ITEMS category array
- Added `cactus_fruit` to FOOD_ITEMS category array
- Equipped display now shows arrow count for enchanted_bow (same as regular bow)
- Arrow count in equipped display now sums regular arrows + diamond arrows

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/crafting/crafting_system.gd` | Modified | Added 3 recipes: diamond_axe, diamond_arrow_bundle, enchanted_bow |
| `scripts/player/player_controller.gd` | Modified | Added cactus_fruit to FOOD_VALUES (15.0 hunger) |
| `scripts/ui/hud.gd` | Modified | Added new items to TOOL_ITEMS/FOOD_ITEMS arrays, enchanted_bow equipped display, combined arrow count |

---

## Session 42 - Desert Survival: Hunger Drain, Sandstorms & Heat HUD (2026-02-23)

Implemented the desert survival challenge system: faster hunger drain in desert regions, periodic sandstorm events with particle effects and speed reduction, and HUD indicators for heat and sandstorm visibility.

### Desert Hunger Drain (Task 11)

- Added `desert_hunger_multiplier` to `PlayerStats` (1.5x when in desert, 1.0x otherwise)
- Multiplier applied alongside existing weather hunger multiplier in `_update_hunger()`
- Player controller checks desert status every 2 seconds via `_check_desert_status()`
- Uses `ChunkManager.get_region_at()` to determine if player is in DESERT region

### Sandstorm System (Task 12)

- Created `Sandstorm` (Node3D) class at `scripts/world/sandstorm.gd`
- Periodic storms: 3-5 minute random delay between storms, 30-45 second duration
- 800 GPUParticles3D sand particles with turbulence, horizontal wind direction
- Sandy brown particle color (0.82, 0.72, 0.55) with alpha transparency
- 30% movement speed reduction during active storms (`SPEED_MULTIPLIER = 0.7`)
- Signals: `sandstorm_started` / `sandstorm_ended` for HUD integration
- Automatically ends storm when player leaves desert

### Heat HUD Indicator & Sandstorm Overlay (Task 13)

- Heat indicator panel: "HEAT 1.5x" in warning red, positioned right of StatsPanel
- Styled with standard HUD font (28px), dark semi-transparent background
- Sandstorm overlay: full-screen ColorRect with sandy brown tint (alpha 0.3)
- Smooth 2-second fade in/out transitions via Tween
- Both elements hidden during overlay mode (map, menus)
- Notification "A sandstorm is approaching!" shown when storm starts

### Integration Flow

Player enters desert -> `_check_desert_status()` detects DESERT region -> sets hunger multiplier to 1.5x, shows heat HUD indicator, enables sandstorm timer -> after random delay, sandstorm starts -> particles emit, speed reduced 30%, sandy overlay fades in, notification shown -> storm ends after 30-45s -> overlay fades out, speed restored -> cycle repeats while in desert

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/world/sandstorm.gd` | Created | Sandstorm system with particles, timing, speed reduction |
| `scripts/player/player_stats.gd` | Modified | Added desert_hunger_multiplier, applied in _update_hunger() |
| `scripts/player/player_controller.gd` | Modified | Desert check timer, sandstorm creation, speed reduction, HUD notifications |
| `scripts/ui/hud.gd` | Modified | Heat indicator panel, sandstorm overlay with fade transitions |

---

## Session 43 - Desert Biome: Code Review Fixes (2026-02-23)

Fixed critical and important issues identified during code review of the desert biome implementation.

### Critical Fixes

- **GemNode missing super._ready()**: `gem_node.gd` wasn't calling `super._ready()`, so `node_name`, `original_scale`, and group membership from ResourceNode base were never initialized. Fixed by setting resource properties before calling `super._ready()`.
- **Cactus DamageArea collision layers**: Default collision_layer=1/mask=1 caused false positives from terrain. Set `collision_layer=0, collision_mask=4` (player layer only).
- **Oasis WaterArea collision layers**: Same issue as cactus. Set `collision_layer=0, collision_mask=4`.

### Important Fixes

- **Palm tree per-instance materials**: Ring bands and coconuts created new `StandardMaterial3D` per tree instance. Added `shared_ring_material` and `shared_coconut_material` static vars, initialized in `_ensure_shared_materials()`, used in `build()`.
- **DiamondArrowProjectile unsafe access**: `get_interaction_text()` returned text even when not pickable. `interact()` used `"inventory" in player_node` which doesn't work for @onready vars in GDScript 4.x. Fixed with `is_pickable` guard and `get_node_or_null("Inventory")` pattern.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/world/palm_tree.gd` | Fixed | Shared static materials for ring/coconut |
| `scripts/world/cactus.gd` | Fixed | DamageArea collision_layer=0, collision_mask=4 |
| `scripts/world/desert_oasis.gd` | Fixed | WaterArea collision_layer=0, collision_mask=4 |
| `scripts/resources/gem_node.gd` | Fixed | Call super._ready() with proper property ordering |
| `scripts/player/diamond_arrow_projectile.gd` | Fixed | is_pickable guard, safe inventory access |

---

## Session 44 - Desert Biome: Play-Test Bug Fixes & Polish (2026-02-23)

Play-tested the desert biome and fixed 11 issues covering collision detection, visual rendering, balance, and art quality.

### Collision & Interaction Fixes

- **Cactus damage not working**: DamageArea `collision_mask` was 4 (layer 3) but player is on layer 1. Changed to `collision_mask=1`. Same fix for oasis WaterArea swimming detection.
- **Oasis water flashing/Z-fighting**: Oasis registered as POND in `water_bodies` caused a FishingSpot (with its own water mesh) to spawn on top of the oasis water surface. Pre-marked oasis water body indices as spawned to prevent duplicate fishing spots.
- **River/oasis water overlap**: River water quads rendered on top of oasis water surface. Added oasis proximity check to skip river quads within oasis bounds.

### Visual & Rendering Fixes

- **Gems visible through terrain**: Gem halo had `no_depth_test=true`, rendering through everything. Removed it and reduced OmniLight range/energy.
- **Gems disappearing under water**: Gem crystal materials used `TRANSPARENCY_ALPHA`, causing rendering order issues with the transparent water surface. Made crystals opaque (emission still gives crystalline look).
- **Oasis water gaps at edges**: Water surface (radius*2) didn't cover the full terrain depression (radius+3 ramp zone). Expanded water surface to `(radius+3.5)*2`.
- **Oasis deep water Z-fighting**: Deep water layer was only 0.02 below surface. Moved to 0.15 below.
- **Palm fronds disconnected**: Fronds were positioned at their center offset from crown. Rewrote to use pivot Node3Ds at crown so fronds rotate from attachment point.
- **Palm tree ring bands overhanging**: Rings were fixed at 0.38 width but trunk tapers from 0.35 to 0.20. Rings now match trunk width at their height position.
- **Cactus rough appearance**: Ridges protruded beyond body surface. Made ridges flush, reduced spine size and protrusion.

### Balance & UX

- **HUD overlap**: Heat indicator overlapped with air bubble display. Moved heat panel below StatsPanel.
- **Desert ring too uniform**: Perfect cylinder shape. Added multi-frequency sine noise to boundaries (±19 unit variation) for organic thicker/thinner sections.
- **Too many cacti**: Halved spawn density (0.7 → 0.35 multiplier).
- **Too much cactus fruit**: Reduced fruit variant from 20% to 10%.
- **Cactus no sound on damage**: Added `fall_hurt` SFX to cactus contact damage.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/world/cactus.gd` | Fixed | collision_mask=1, flush ridges, smaller spines, hurt SFX |
| `scripts/world/desert_oasis.gd` | Fixed | collision_mask=1, expanded water surface, deep water Y offset |
| `scripts/world/chunk_manager.gd` | Fixed | Organic desert boundaries, skip river quads in oasis, prevent oasis fishing spots |
| `scripts/world/terrain_chunk.gd` | Fixed | Dynamic desert transition bounds, halved cactus density, 10% fruit |
| `scripts/world/palm_tree.gd` | Fixed | Pivot-based fronds, tapered ring bands |
| `scripts/resources/gem_node.gd` | Fixed | Removed no_depth_test, opaque crystals, reduced light |
| `scripts/ui/hud.gd` | Fixed | Heat panel below StatsPanel |

---

## Session 45 - Collision & Physics Bug Fixes (2026-02-23)

Fixed cabin sensor flickering, added collision to palm trees and scattered decorations, and fixed desert creature movement through terrain.

### Bug Fixes

- **Cabin enter/exit flickering**: Protection Area3D was sized to full cabin dimensions, so the player's collision body clipped through the boundary while walking along the outside walls. Shrunk the detection area inward by `wall_thick + 0.3` (0.55 units) on each side so only players actually inside trigger it. Fixed in both `save_load.gd` and `placement_system.gd`.
- **Palm trees had no collision**: PalmTree extended Node3D with no physics body. Changed to extend StaticBody3D and added a CollisionShape3D (0.5 x tree_height x 0.5 box) centered on the trunk's sway midpoint. Not cuttable with axe (no group membership).
- **Desert creatures walking through blocks**: Lizards and tortoises used base class `_move_animal()` which only checked terrain height and cave pits but did no physics raycast. Added a raycast obstacle check (collision_mask=1) to `_move_animal()` in `AmbientAnimalBase`, matching the approach used by rabbits in `_start_single_hop()`. Animals now reverse direction when hitting terrain blocks, trees, or structures.
- **Tortoise too fast**: Halved movement speed from 1.0/2.0 to 0.5/1.0 (move/flee).
- **Scattered decorations had no collision**: Rocks, bushes, stumps, and fallen logs were purely visual MeshInstance3D nodes. Added StaticBody3D + CollisionShape3D to all four types in `terrain_chunk.gd`, sized to match their visual bounds.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/core/save_load.gd` | Fixed | Cabin protection area shrunk inward |
| `scripts/campsite/placement_system.gd` | Fixed | Cabin protection area shrunk inward |
| `scripts/world/palm_tree.gd` | Fixed | Extends StaticBody3D, trunk collision box |
| `scripts/creatures/ambient_animal_base.gd` | Fixed | Physics raycast in `_move_animal()` |
| `scripts/creatures/ambient_tortoise.gd` | Fixed | Halved move/flee speed |
| `scripts/world/terrain_chunk.gd` | Fixed | Collision on scattered rocks, bushes, stumps, fallen logs |

---

## Session 46 - Desert Sand Visuals & Health Regen Fix (2026-02-23)

Overhauled desert terrain to look like realistic, uniform sand instead of a patchy checkerboard. Fixed health regeneration not triggering when hunger bar was full.

### Desert Sand Overhaul

The desert terrain had three problems making it look like a patchwork quilt rather than sand:

1. **Noisy grass texture applied to sand**: The 16x16 grass_top texture has ±0.08 pixel variation and 10% dark spots — great for grass, terrible for sand. Added dedicated `sand_top` and `sand_side` textures to the atlas with only ±0.02 noise for a smooth, uniform appearance.

2. **Too much per-cell color variation**: Each terrain cell got a random ±0.08 color offset, creating visible contrast between adjacent cells. Reduced to ±0.02 for desert regions.

3. **Ambient occlusion too harsh on flat sand**: AO darkened cell corners by up to 36% when neighbors had different heights, making the grid pattern visible. Softened AO by 75% for desert cells (lerp toward 1.0).

Also adjusted desert base colors to warmer yellow-brown: grass `(0.84, 0.75, 0.45)`, dirt `(0.72, 0.60, 0.35)`.

### Health Regen Bug Fix

Health was not regenerating when hunger was full due to a frame-order race condition. `_update_hunger()` runs before `_update_health()` in `_process()`, so even at full hunger, the drain tick reduces it below `max_hunger` before the regen check. Changed threshold from `hunger >= max_hunger` to `hunger >= max_hunger * 0.98`. Especially noticeable in the desert where the 1.5x hunger multiplier drains faster.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/world/terrain_textures.gd` | Modified | Expanded atlas from 32x32 to 48x32, added sand_top/sand_side textures and UV functions |
| `scripts/world/terrain_chunk.gd` | Modified | Desert cells use sand textures, reduced color variation and AO for desert |
| `scripts/world/chunk_manager.gd` | Modified | Warmer desert base colors |
| `scripts/player/player_stats.gd` | Fixed | Health regen threshold 98% instead of exactly full |

---

## Session 47 - Equipment Artwork Pass (2026-02-24)

Added distinct held visuals for all equippable items that were previously invisible when equipped.

### Diamond Axe Artwork

Created `_add_diamond_axe_head()` in `equipment.gd` — an 8-component design substantially different from other axes:
- **Silver pommel** cap at handle bottom, **silver mount** with blue-tinted accent ring connecting handle to head
- **Diamond head body**: deep blue `(0.35, 0.55, 0.9)` with subtle emission glow (1.2x)
- **Left/right facet panels**: angled ±8 degrees to simulate cut diamond faces
- **Inner core highlight**: bright cyan-white with 2.0x emission for sparkle effect
- **Crystalline blade edge**: blue-white with 2.5x emission — brightest component
- Dark refined hardwood handle (longer than other axes)
- Fixed transparency bug: removed alpha transparency, kept emission-only glow

### Enchanted Bow Artwork

Modified `build_bow_model()` in `bow_system.gd` to accept `bow_type` parameter. When `"enchanted_bow"`:
- **Dark purple-wood limbs** `(0.35, 0.22, 0.45)` with metallic sheen
- **Opal inlay strips** on limb segments 1 and 3 — purple `(0.6, 0.45, 0.85)` with 1.8x emission
- **Glowing opal gem** inset on grip — bright purple `(0.7, 0.5, 0.95)` with 2.5x emission
- **Purple accent grip wraps** with subtle emission
- **Opal-tinted nock tips** with 1.5x emission glow
- **Purple-tinged bowstring** with faint 0.6x emission

### Placeable Kit Held Models

Added a generic kit bundle system for all 12 placeable items that previously showed nothing when equipped:
- **Bundle shape**: burlap-wrapped parcel (3 BoxMesh components: base, horizontal accent band, vertical cross-strap)
- **Color-coded accent straps** per item type:
  - Campfire: orange-red | Shelter: tan | Storage: warm brown | Bench: dark wood
  - Drying Rack: light wood | Garden: green | Tent: canvas off-white | Cabin: dark timber
  - Snare Trap: rope tan | Smithing Station: steel grey | Smoker: smoky brown
- **Lodestone**: unique model — dark iron-grey stone with two crossing magnetic-blue glowing veins (emission 1.2-1.5x)

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/player/equipment.gd` | Modified | Diamond axe head, kit bundle system (12 placeables + lodestone), diamond axe transparency fix, bow type passthrough |
| `scripts/player/bow_system.gd` | Modified | Enchanted bow visuals with opal materials, accepts bow_type parameter |

---

## Session 48 - Bug Fix Pass: 11 Play Session Bugs (2026-02-28)

Fixed 11 bugs reported from play-testing session. Includes a new crouch mechanic with Minecraft-style edge prevention.

### Bug Fixes

1. **Heat panel popup on sign close** — `set_overlay_mode(false)` was unconditionally showing the heat panel. Now only hides it on overlay enter; visibility is driven by actual desert heat state.

2. **"HP" and "FD" in notifications** — Changed all notification text from "HP" to "health" and "FD" to "hunger" across player_controller.gd and cactus.gd for clarity.

3. **Tortoise too fast** — Reduced move_speed 0.5→0.25, flee_speed 1.0→0.5 (50% reduction).

4. **Lizard too fast** — Reduced move_speed 5.0→3.75, flee_speed 9.0→6.75 (75% of original).

5. **Torch casting shadows above** — Disabled shadow_enabled on hand-held torch light. Placed torches keep shadows.

6. **Torch not lighting ground** — Lowered light position from Y=1.2 to Y=0.8 (hand height), added omni_attenuation=0.6 for reduced falloff.

7. **Fall damage "-0 HP"** — Added guard to skip damage notification and sound effect when calculated damage < 1.0.

8. **Controller remap + crouch mechanic**:
   - Unequip moved from ✕ (button 0) to □ (button 2)
   - Crafting key changed from C to X
   - New crouch action: C key / ✕ button (toggle)
   - Crouch lowers camera to Y=0.8, halves collision height to 0.9, speed limited to 2.5
   - Minecraft-style edge prevention: raycasts ahead while crouched to prevent walking off ledges
   - Ceiling check prevents standing up under low ceilings
   - Jump uncrouches first (blocked if ceiling above)

9. **"Cooked Cooked Berries"** — Removed redundant "Cooked" prefix from fire_menu notification since output_name already includes it.

10. **Canvas tent exit position** — Changed exit Z offset from -2.5 to +2.5 so player exits at the door side (positive Z).

11. **Diamond axe z-fighting** — Shrunk core highlight mesh (0.03→0.02 X, 0.08→0.06 Y, 0.10→0.08 Z), nudged Y from 0.27 to 0.28, added render_priority=1 on material.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/ui/hud.gd` | Modified | Heat panel no longer force-shown on overlay exit |
| `scripts/player/player_controller.gd` | Modified | HP→health, FD→hunger notifications, fall damage guard, crouch mechanic with edge prevention |
| `scripts/world/cactus.gd` | Modified | HP→health in damage notification |
| `scripts/creatures/ambient_tortoise.gd` | Modified | Halved move/flee speeds |
| `scripts/creatures/ambient_lizard.gd` | Modified | Reduced move/flee speeds to 75% |
| `scripts/player/equipment.gd` | Modified | Torch shadow off + lower position, diamond axe core z-fighting fix |
| `scripts/ui/fire_menu.gd` | Modified | Removed duplicate "Cooked" prefix |
| `scripts/campsite/structure_shelter.gd` | Modified | Tent exit Z offset flipped to door side |
| `scripts/systems/input_manager.gd` | Modified | Updated prompts: crafting C→X, unequip ✕→□, added crouch |
| `project.godot` | Modified | Remapped unequip/crafting buttons, added crouch input action |

---

## Session 48b - Arrow Type Switching for Bow (2026-02-28)

Added the ability for the player to cycle between regular and diamond arrows when a bow is equipped.

### Features

- **Arrow type toggle**: Press T (keyboard) or D-pad Down (controller) to cycle between regular and diamond arrows while bow is equipped
- **Preferred arrow tracking**: BowSystem tracks `preferred_arrow` state ("arrows" or "diamond_arrows")
- **Smart fallback**: If preferred type runs out mid-combat, automatically falls back to the other type
- **HUD display updated**: Now shows count and type of selected arrows (e.g., "5 diamond arrows" or "10 regular arrows") instead of combined total
- **Switch hint in HUD**: Equipment display shows the cycle key: "[R-click aim, T switch, Q unequip]"
- **Notifications**: Shows "Switched to Diamond arrows" / "Switched to Regular arrows" on toggle, or "No diamond arrows!" if type unavailable

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/player/bow_system.gd` | Modified | Added preferred_arrow state, cycle_ammo input, arrow_type_changed signal, fallback fire logic |
| `scripts/ui/hud.gd` | Modified | Bow display shows arrow type/count from BowSystem, connects arrow_type_changed signal |
| `scripts/systems/input_manager.gd` | Modified | Added cycle_ammo prompts (T / D-Dn) |
| `project.godot` | Modified | Added cycle_ammo input action (T key + D-pad Down) |

---

## Session 48c - Rope Model + Return to Camp Fix (2026-02-28)

### Rope Equipment Artwork
Added held visual for rope — the one equippable item that was missing hand artwork. The model is a coiled bundle of hemp rope with:
- Main coil body (tan, 0.1 × 0.12 × 0.08)
- Dark inner hole giving depth to the coil
- Horizontal wrap band holding coil together
- Trailing rope tail hanging down with frayed end

### Return to Camp Fix
Changed "Return to Camp" in pause menu to teleport the player to their shelter respawn point (cabin > canvas tent > basic shelter) instead of always going to the world origin. Falls back to origin if no shelter has been built.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/player/equipment.gd` | Modified | Added rope_model variable, ROPE_REST constants, _create_rope_model(), _remove_rope_model(), equip/unequip dispatch |
| `scripts/ui/pause_menu.gd` | Modified | Return to Camp uses player.respawn_position when shelter exists |

---

## Session 48d - Rope Model v2, Enchanted Bow Hit Radius (2026-02-28)

### Rope Model Redo
Replaced the blocky rectangular rope model with a proper round coil — 12 small cube segments arranged in a torus ring, 3 loops stacked vertically, with alternating tan/dark materials for a woven rope texture. Trailing end hangs down from one side.

### Enchanted Bow — Larger Hit Radius
Arrows fired from the enchanted bow now have a significantly larger hit detection area (1.2×1.2×1.0 vs regular 0.15×0.15×0.6), making it much easier to hit animals. The `enchanted` flag is set on both ArrowProjectile and DiamondArrowProjectile before they enter the scene tree, so the enlarged hitbox is active from spawn. This gives the enchanted bow a meaningful gameplay advantage beyond just faster draw/arrow speed.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/player/equipment.gd` | Modified | Rope model redone as torus coil with ring of box segments |
| `scripts/player/bow_system.gd` | Modified | Sets `enchanted = true` on arrows when fired from enchanted bow |
| `scripts/player/arrow_projectile.gd` | Modified | Added `enchanted` var, 8x larger hit area when set |
| `scripts/player/diamond_arrow_projectile.gd` | Modified | Added `enchanted` var, 8x larger hit area when set |

---

## Session 48e - Desert Sinkhole Easter Egg + Split Branches Recipe (2026-02-28)

### Split Branches Recipe
Added "Split Branches" crafting recipe: 1 wood → 4 branches. Hand-craftable, no bench or camp level required. Addresses resource imbalance where players accumulate hundreds of wood but run low on branches.

### Desert Sinkhole Easter Egg — Full Implementation

Added a hidden sinkhole in the desert biome containing an ancient explorer's journal — the ultimate item in the game. Reaching it requires a deep underwater dive aided by a coca leaf plant. The journal grants permanent stat boosts, reveals map markers, and unlocks a hang glider recipe for powered flight.

#### Sinkhole Generation
- 30-unit deep water-filled sinkhole at 180° in the desert ring (~200 units from spawn)
- 5-unit radius with 3-unit gradual slope at rim
- Registered as water body for terrain carving in `get_height_at()`
- Vegetation suppressed within 12-unit buffer zone
- Faint blue-green glow from OmniLight3D at the bottom
- Swimming Area3D for water detection

#### Coca Leaf Plant
- New resource node scene: bushy plant with 4 broad leaves in bright/dark green
- Spawns 7 units east of sinkhole — the only green vegetation nearby
- When eaten: doubles underwater breath duration (4s → 8s per bubble) for 5 minutes
- Makes the 30-unit dive possible (normal air = 20s, with buff = 40s, dive takes ~20.5s)
- Respawns after 72 hours game time via existing resource depletion system

#### Explorer's Journal Pickup
- Glowing book on a stone pedestal at the sinkhole bottom
- Procedural visuals: 4-layer stone pedestal + emissive amber book + warm OmniLight3D
- Shared static materials pattern for performance
- Goes into inventory as `explorers_journal`, never respawns once collected

#### Journal Reading UI
- Full-screen CanvasLayer at layer 80 with dark semi-transparent background
- 3-4 paragraphs of weathered explorer lore mentioning oases, caves, and the glider design
- Closes on ESC/Circle, can be re-read anytime from inventory

#### Three Rewards on First Read
1. **Stat Boost**: +25 max health (100→125), -20% hunger depletion (0.05→0.04/sec)
2. **Hang Glider Recipe**: Unlocked in crafting system (`requires_journal: true` gate)
3. **Map Markers**: Compass HUD cycles through oases, caves, and sinkhole positions every 3 seconds

#### Hang Glider Equipment
- Equippable tool (slot 30, tool_type "glider")
- Infinite durability (not in TOOL_MAX_DURABILITY)
- First-person model: triangular fabric wing frame with grip bar, struts, and canvas panels
- Recipe: 4 rope + 6 branch + 2 hide (bench, camp level 3, journal required)

#### Hang Glider Flight Mechanics
- **Deploy**: Press R/R2 while airborne with glider equipped
- **Pitch control**: Camera look up = climb (1 u/s), look down = dive (2 u/s), level = gentle descent
- **Horizontal speed**: 8 u/s (faster than sprinting at 6 u/s)
- **Max height**: 25 units above terrain (above trees, below mountain peaks)
- **Steering**: WASD / left stick for direction
- **Retract**: Jump, crouch, land on ground, or enter water
- HUD "GLIDING" indicator while in flight
- State safety: crouch disabled while gliding, gliding reset on death

#### Save/Load Integration
- Player data: `has_read_journal`, `map_markers_unlocked`, `coca_leaf_timer`, `max_health_bonus`, `hunger_depletion_rate`
- World data: `sinkhole_book_collected` gates journal respawn
- Stat bonuses restored before health clamping for correct max health on load
- Coca leaf breath buff restored if timer > 0
- All new fields use `.get()` with defaults for backward compatibility

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/crafting/crafting_system.gd` | Modified | Added split branches recipe, hang glider recipe with `requires_journal` gate, `_check_journal_read()` helper |
| `scripts/world/chunk_manager.gd` | Modified | Sinkhole generation, terrain carving, contents spawning, book collection gate, `sinkhole_book_collected` var |
| `scripts/world/terrain_chunk.gd` | Modified | Vegetation suppression near sinkhole |
| `scenes/resources/coca_leaf.tscn` | Created | Coca leaf resource node scene |
| `scripts/world/explorers_journal_pickup.gd` | Created | Journal pickup with pedestal and emissive book visuals |
| `scripts/ui/journal_ui.gd` | Created | Full-screen journal reading UI |
| `scripts/player/player_controller.gd` | Modified | Coca leaf buff, journal reading, gliding state, `_process_gliding()`, rewards |
| `scripts/player/player_stats.gd` | Modified | `max_health_bonus`, `get_max_health()` |
| `scripts/player/equipment.gd` | Modified | Hang glider in EQUIPPABLE_ITEMS, first-person model |
| `scripts/ui/hud.gd` | Modified | POI cycling on compass, GLIDING indicator |
| `scripts/systems/input_manager.gd` | Modified | Glider equipment prompts |
| `scripts/core/save_load.gd` | Modified | Save/load all new journal, sinkhole, and stat fields |
| `docs/plans/2026-02-28-desert-sinkhole-easter-egg-design.md` | Created | Full design document |
| `docs/plans/2026-02-28-desert-sinkhole-easter-egg.md` | Created | 8-task implementation plan |

---

## Session – 2026-02-28 (Explorer's Journal Equippable)

### What Was Built
Made the Explorer's Journal a proper equippable tool instead of an eat-intercepted item:

1. **Equippable item**: Added `explorers_journal` to EQUIPPABLE_ITEMS (slot 31, tool_type "journal")
2. **Held book model**: Dark reddish-brown leather cover, cream page block, darker spine strip, leather strap with brass clasp — attached to camera like other held tools
3. **R2 use action**: Press R2 to open journal UI (with toggle guard like map), delegates to existing `_open_journal()` for rewards/signals
4. **Book-style UI**: Replaced plain panel with two-page open book spread — leather cover frame, dark spine divider, parchment pages with dark brown ink text, viewport-relative font scaling
5. **Removed eat fallback**: Journal no longer intercepts the eat action in `_try_eat()`

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/player/equipment.gd` | Modified | Added explorers_journal to EQUIPPABLE_ITEMS, held book model, journal use dispatch with toggle guard |
| `scripts/ui/journal_ui.gd` | Modified | Restyled as two-page book: leather cover, spine, parchment pages, dark ink text, viewport-relative scaling |
| `scripts/player/player_controller.gd` | Modified | Removed eat-based journal fallback from `_try_eat()` |

---

## Session – 2026-02-28 (Glider Rework & Bug Fixes)

### What Was Built
Reworked hang glider flight mechanics and fixed several bugs:

1. **Boost mechanic**: Replaced awkward "look up to climb" with a boost button (Space/Circle). Each press gives a 2-second burst of upward lift at 5 m/s. No cooldown — player can repeatedly boost to gain significant altitude
2. **Slow descent**: Glider now descends at a constant 1.0 m/s instead of variable pitch-based descent
3. **Camera roll fix**: Forced player body and camera roll to zero every frame during gliding, both before and after `move_and_slide()`. Replaced camera-basis direction math with clean yaw-based trig to prevent roll contamination
4. **Redesigned glider model**: Proper delta-wing shape with A-frame control bar, keel spine, V-shaped leading edges, triangular fabric wing panels, support cables, and trailing edge
5. **Equipment lock while gliding**: Blocked all equipment switching (number keys, L1/R1 cycling, unequip) during flight
6. **Heat/compass overlap fix**: Moved heat panel below compass panel so they don't overlap when both visible
7. **HUD updates**: Gliding indicator shows "BOOSTING" (gold) when ascending and "GLIDING" (green) otherwise. Equipment hint shows boost and retract keys
8. **Journal UI fix**: Changed controller close hint from "Circle to close" to "X to close"
9. **Max height raised**: Glide ceiling increased from 25 to 50 units above terrain

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/player/player_controller.gd` | Modified | Boost mechanic, camera roll fix, yaw-based movement, _stop_gliding() helper, temp spawn items |
| `scripts/player/equipment.gd` | Modified | Block equipment switching while gliding, redesigned glider model |
| `scripts/ui/hud.gd` | Modified | Boost/gliding indicator, heat panel repositioned, updated equipment hints |
| `scripts/ui/journal_ui.gd` | Modified | Fixed controller close hint text |

---

## Session – 2026-03-01 (Inventory Stack Limits)

### What Was Built
Added per-item stack limits to the player inventory, creating a resource management mechanic and fixing HUD overflow when carrying many items. Storage boxes remain unlimited.

1. **Core inventory limits**: Added `STACK_LIMITS` dictionary with per-item limits (50 for bulk, 20 for food/materials, 10 for cooked food/rare items, 5 for tools/kits, 3 for wraps, 1 for journal/lodestone). `enforce_limits` flag controls whether limits are active (true for player, false for storage). Added `get_stack_limit()`, `can_add_item()`, `get_remaining_capacity()` helpers and `item_add_refused` signal
2. **Player controller integration**: Enables limits on player inventory, shows HUD notification "Can't carry more [Item] (X/X). Store items first." when refused
3. **Save/load safety**: Temporarily disables limits during inventory restore to protect existing saves with items above new limits
4. **HUD display**: Shows "Name: 5/20" format with color coding — red at limit, yellow at 80%+
5. **Crafting system**: `can_craft()` now checks output capacity. Crafting UI shows red "Inventory full (X/X)" when player has ingredients but output is at limit
6. **Fire menu & cabin kitchen**: Check output capacity before cooking, refuse with notification if full
7. **Storage UI**: Storage→player transfers check capacity. "Transfer All" clamps to remaining capacity. Player item list shows limits (e.g. "Wood x5/50")
8. **Resource gathering**: All resource nodes (trees, rocks, berries, crystals, cactus) check capacity before depleting. Trees reset chop progress if player can't carry wood
9. **Structure pickups**: Torch, lantern, and lodestone check capacity before destroying the placed structure
10. **Processing structures**: Smoker, drying rack, smithing station check capacity when collecting output. Garden does partial harvest (takes what fits, leaves the rest)
11. **Birch bark & arrow recovery**: Machete bark harvest and diamond arrow pickup check capacity, leave resource/arrow in world if full

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/player/inventory.gd` | Modified | STACK_LIMITS dict, enforce_limits flag, item_add_refused signal, get_stack_limit(), can_add_item(), get_remaining_capacity(), modified add_item() |
| `scripts/player/player_controller.gd` | Modified | Enable enforce_limits, connect item_add_refused for HUD notification |
| `scripts/core/save_load.gd` | Modified | Temporarily disable limits during inventory restore |
| `scripts/ui/hud.gd` | Modified | Show "Name: X/Y" format, color coding for near/at limit |
| `scripts/crafting/crafting_system.gd` | Modified | Check output capacity in can_craft() |
| `scripts/ui/crafting_ui.gd` | Modified | Show "Inventory full" label when output at limit |
| `scripts/ui/fire_menu.gd` | Modified | Check output capacity before cooking |
| `scripts/campsite/cabin_kitchen.gd` | Modified | Check output capacity before cooking |
| `scripts/ui/storage_ui.gd` | Modified | Capacity checks on storage→player transfers, show limits in player list |
| `scripts/resources/resource_node.gd` | Modified | Pre-check capacity in interact() and _complete_harvest() |
| `scripts/resources/crystal_node.gd` | Modified | Pre-check capacity in interact() |
| `scripts/world/cactus.gd` | Modified | Pre-check capacity before harvesting fruit |
| `scripts/world/explorers_journal_pickup.gd` | Modified | Pre-check capacity before collecting journal |
| `scripts/campsite/structure_placed_torch.gd` | Modified | Pre-check capacity before pickup/destroy |
| `scripts/campsite/structure_placed_lantern.gd` | Modified | Pre-check capacity before pickup/destroy |
| `scripts/campsite/structure_lodestone.gd` | Modified | Pre-check capacity before pickup/destroy |
| `scripts/campsite/structure_smoker.gd` | Modified | Check capacity when collecting pending output |
| `scripts/campsite/structure_drying_rack.gd` | Modified | Check capacity when collecting pending output |
| `scripts/campsite/structure_smithing_station.gd` | Modified | Check capacity when collecting pending output |
| `scripts/campsite/structure_garden.gd` | Modified | Partial harvest — take what fits, leave rest |
| `scripts/player/equipment.gd` | Modified | Check capacity before birch bark harvest |
| `scripts/player/diamond_arrow_projectile.gd` | Modified | Check capacity before arrow recovery |

---

## Session 49 - Inventory HUD Refinements (2026-03-01)

Iterative HUD improvements for the inventory panel after stack limits were added.

### Changes
1. **Two-column layout**: Replaced ScrollContainer with HBoxContainer-based two columns when items exceed 14, with category continuation headers when splitting mid-category
2. **Toggle visibility**: V key (keyboard) and D-pad Left (controller) toggle inventory panel on/off
3. **Font size tuning**: Items 36px, category headers 29px, title 40px — balanced between readable and compact
4. **Removed eat hint**: Removed the "[F] Eat" label from the bottom of the inventory panel
5. **Controller hints**: Updated hint bar to show "D←-Inventory" for controller users

### Files Changed

| File | Changes |
|------|---------|
| `scripts/ui/hud.gd` | Two-column layout, V/D-pad toggle, font sizes, removed eat hint, controller hint update |
| `scenes/ui/hud.tscn` | Updated InventoryPanel structure (VBoxContainer > HBoxContainer columns), font sizes |

---

## Session 50 - Per-Frame Performance Fix (2026-03-01)

### Problem
Stuttering and stickiness near spawn when walking and panning the camera, persisting even after world generation completed.

### Root Cause
`add_theme_color_override()` was being called **every frame** in two HUD `_process()` code paths, even when the color hadn't changed. This is an expensive Godot operation that triggers internal theme invalidation/recalculation each call.

1. **Grapple reticle** (`_update_grapple_reticle()`): Called every frame from `_process()`, unconditionally setting crosshair color via `add_theme_color_override()` — even when the grappling hook wasn't equipped and the color was already default.
2. **Gliding indicator**: Updated label text and color every frame while gliding, even when the boost state hadn't changed.

Additionally, `print()` debug statements in `inventory.add_item()` and the HUD signal handler were generating console I/O on every item pickup.

### Fix
- **Cached last color/state**: Added `_last_crosshair_color` and `_last_glide_boosting` vars. Theme overrides now only fire when the value actually changes.
- **Removed debug prints**: Cleaned out `print()` calls from inventory and HUD signal handlers.

### Lesson
**Never call `add_theme_color_override()` unconditionally in `_process()`**. Always cache the last value and guard with a comparison. This applies to all `add_theme_*_override()` methods.

### Files Changed

| File | Changes |
|------|---------|
| `scripts/ui/hud.gd` | Cache crosshair color and glide state, only call theme override on change; removed debug print |
| `scripts/player/inventory.gd` | Removed debug print statements from add_item() and clear() |

---

## Session 51 - Dev Mode Toggle in Settings Menu (2026-03-01)

Added a runtime-togglable "Dev Mode (all items)" setting to the config menu, replacing the hardcoded `DEV_GIVE_ALL_ITEMS` constant that required code edits and restarts.

### Changes
1. **Runtime toggle**: New CheckButton in config menu between "Start with Bow & Map" and the tree respawn slider
2. **Inventory snapshot/restore**: Toggling ON snapshots current inventory then populates all items; toggling OFF restores the exact pre-dev-mode inventory state
3. **Save/load persistence**: Dev mode setting saved in config data, persists across game saves
4. **Default off**: Game now starts without dev items by default — no more editing code to disable

### Implementation
- `player_controller.gd`: `const DEV_GIVE_ALL_ITEMS` replaced with `var dev_mode: bool = false` and `_pre_dev_inventory` snapshot dictionary. `_dev_populate_inventory()` snapshots before filling; `_dev_clear_inventory()` restores from snapshot.
- `config_menu.gd`: `dev_mode_enabled` state var, toggle UI ref, signal handler that calls populate/clear on player, included in `get_config()`/`apply_config()` for save/load.
- `config_menu.tscn`: `DevModeToggle` CheckButton node added to VBoxContainer.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/player/player_controller.gd` | Modified | `var dev_mode`, `_pre_dev_inventory` snapshot, `_dev_clear_inventory()` restore method |
| `scripts/ui/config_menu.gd` | Modified | `dev_mode_enabled` state, toggle wiring, save/load, controller nav support |
| `scenes/ui/config_menu.tscn` | Modified | Added DevModeToggle CheckButton node |

---

## Session - Sinkhole Pocket Desert Relocation (2026-03-01)

Relocated the sinkhole easter egg from the main desert ring (200 units at 180 degrees) to a hidden pocket desert biome 350 units due west of spawn. The pocket desert is a small, roughly circular desert area (~50-unit radius with organic noise boundaries) that sits outside the main desert ring, making the sinkhole much harder for players to stumble upon.

### Features
- **Pocket desert biome**: New isolated desert area centered at (-350, 0) with organic noise-based boundaries (reuses `_desert_boundary_offset()` for natural wobble). Returns `RegionType.DESERT` so cacti, palms, sand colors, and desert terrain all apply automatically.
- **Gradual color blending**: 15-unit transition zone where terrain colors smoothly interpolate between surrounding biome and desert sand. Applied to both top-face and side-face rendering paths.
- **Rock spire landmark**: Tall 4-piece BoxMesh sandstone formation at the eastern edge of the pocket desert (~(-305, 0)). Visible from ~80-100 units as a subtle hint to explorers heading west.
- **Vegetation suppression**: Extended `is_near_sinkhole()` to also clear vegetation around the rock spire (6-unit radius).
- **Sinkhole unchanged**: Same 45-unit deep pit, water, glow, coca leaf plant, Explorer's Journal, and all rewards. Only the position changed.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/world/chunk_manager.gd` | Modified | Pocket desert vars, moved sinkhole to pocket center, `get_region_at()` pocket check, `get_pocket_desert_blend()` helper, `_spawn_rock_spire()`, pre-computed `rock_spire_position`, extended vegetation suppression |
| `scripts/world/terrain_chunk.gd` | Modified | Pocket desert color blending in both top-face and side-face render paths, `is_desert` flag updates |
| `docs/plans/2026-03-01-sinkhole-pocket-desert-design.md` | New | Design document |
| `docs/plans/2026-03-01-sinkhole-pocket-desert.md` | New | Implementation plan |

---

## Session - Torch/Lantern Terrain Lighting Fix (2026-03-01)

Fixed a long-standing bug where torches and lanterns illuminated objects (trees, rocks, signs) but NOT the terrain ground surface.

### Root Cause

All terrain SurfaceTool triangles (top faces and side faces) had **clockwise winding order**, making them back-facing. With `CULL_DISABLED`, Godot renders both sides but negates normals for back-facing fragments (`NORMAL = -NORMAL`). This turned `Vector3.UP` into `Vector3.DOWN` for top faces, causing `dot(normal, light_direction) < 0` = zero light contribution from point lights above.

### Fix

Swapped all triangle winding from CW to CCW (counter-clockwise = front-facing):
- **Top faces**: `(v0,v2,v1)/(v0,v3,v2)` → `(v0,v1,v2)/(v0,v2,v3)`
- **Side faces**: Same swap pattern applied to grass strip, dirt section, and short-side triangles

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/world/terrain_chunk.gd` | Modified | Fixed winding order in `_add_top_face_cached()` and `_add_side_quad_ao()` |

---

## Session - Explorer's Journal Content Expansion (2026-03-01)

Expanded the Explorer's Journal from a single two-page spread into an 11-spread multi-page book with page-turning navigation. The journal now tells the full story of E.W. Carlston's exploration of the Carlston Wilderness through dated diary entries, followed by a complete crafting recipe reference.

### Features
- **Multi-page navigation**: D-pad left/right (controller) or arrow keys (keyboard) to turn pages. Page indicator shows "Page N of 11" with contextual Prev/Next labels.
- **6 adventure diary entries** (Spreads 1-6): Chronological story from Day 1 (arrival in the forest) through Day 47 (the sinkhole farewell). Covers forest, crafting basics, caves and ores, the desert and oases, mountain peaks, the hang glider, and the final discovery.
- **5 recipe reference pages** (Spreads 7-11): All 34 crafting recipes organized by tier — Hand Crafting, Getting Established (Bench Lvl 1), Expanding Your Range (Bench Lvl 2), Advanced Crafting (Bench Lvl 3), and Rare & Extraordinary. Each recipe shows exact ingredients with flavor text.
- **Quality fixes**: Memory leak prevention (UI nodes freed on close), synchronous child cleanup (no flicker on page turn), preloaded font, cached page data, null guards.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/ui/journal_ui.gd` | Modified | Complete rewrite: page data array, `_populate_page()` method, page-turning input, 11 spreads of content, memory management |
| `docs/plans/2026-03-01-explorer-journal-content-design.md` | New | Design document |
| `docs/plans/2026-03-01-explorer-journal-content.md` | New | Implementation plan |

---

## Session - Food Selection Menu (2026-03-02)

Replaced the auto-eat system (F/Triangle consumed highest-value food automatically) with a food selection menu that shows all consumable items, their quantities, and what they restore (hunger, health, or both). Player now chooses what to eat.

### Features
- **Food selection UI**: Centered panel with "C O N S U M E" title, hunger/health stats (color-coded green/yellow/red), scrollable item list, and button prompts
- **Item details**: Each row shows item name, quantity (x3), and restore values (+40 hunger, +20 HP). Coca leaf shows special "+5, 5min breath" text. Dual items (hearty stew) show both hunger and HP
- **Full input support**: F/Triangle toggles menu, Arrow/D-pad navigates, Enter/Circle consumes, Esc/Cross closes. Dynamic button prompts update for controller vs keyboard
- **Smart behavior**: Auto-closes when last item consumed, shows "No food or healing items!" when empty, blocks player movement/jump while open, integrates with close-all-menus on death
- **Lazy creation**: Menu CanvasLayer created on first use (journal_ui pattern), no scene file needed

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/ui/food_menu.gd` | New | Full food selection menu — CanvasLayer with programmatic UI, item list, navigation, consume logic |
| `scripts/player/player_controller.gd` | Modified | Added `_food_menu` var, `_toggle_food_menu()`, `consume_item()`, added food_menu to `_is_ui_blocking_input()` and `_close_all_menus()` |

---

## Session - Carved Tree Landmark (2026-03-02)

Added the Carved Tree trail landmark for the trail-home endgame feature. An interactable tree with carved initials ("M.W.C.") and an arrow pointing east, with a readable overlay displaying a clue about following the ridge to a stone cairn.

### Features
- **Procedural 3D visuals**: Dark brown trunk (BoxMesh 0.8x3.0x0.8), lighter carved face inset on front, arrow carving made of thin dark strips, multi-block green canopy on top
- **Shared static materials**: 5 materials (trunk, carved face, arrow, canopy, canopy dark) using `static var` / `_ensure_shared_materials()` pattern to avoid per-instance shader compilation
- **Readable overlay**: CanvasLayer (layer 100) with centered panel, gold title "The Carved Tree" (48px), white body text (32px) with M.W. Carlston's trail marker clue, grey close hint (28px)
- **Full interaction pattern**: `add_to_group("interactable")`, `interact()` toggles overlay, `get_interaction_text()` returns context-aware text, freezes player via `set_resting(true)`, hides HUD via `set_overlay_mode(true)`
- **Controller support**: Checks `/root/InputManager` for correct button prompt, `ui_cancel` to close
- **OmniLight3D**: Faint warm glow (energy 0.5, range 4) to help player spot the landmark
- **State tracking**: `has_been_read` flag set on first interaction for future save/load integration

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/world/trail_carved_tree.gd` | New | Carved tree landmark — extends StaticBody3D, shared materials, BoxMesh visuals, overlay UI, interaction system |

---

## Session - Trailhead Signpost Landmark (2026-03-02)

Added the Trailhead Signpost, the FINAL landmark in the trail-home endgame. A weathered wooden signpost with two directional arms that shows a confirmation overlay when interacted. The player can choose to leave the wilderness, triggering a cinematic fade-to-black transition to the house scene.

### Features
- **Procedural 3D visuals**: Weathered vertical post (BoxMesh 0.15x2.5x0.15), two directional sign arms at slight downward angles, decorative dark text strips on each arm, packed earth base, warm OmniLight3D glow
- **Shared static materials**: 4 materials (post, arm, text strip, base) using `static var` / `_ensure_shared_materials()` pattern
- **Two-state overlay with selection**: CanvasLayer (layer 100) shows signpost directions ("Carlston Wilderness" and "Longridge Road, Oakland, California — 225 miles"), body text, and two selectable choices ("Yes, head home" / "Not yet") with up/down navigation and gold/grey highlight
- **Full interaction pattern**: `add_to_group("interactable")`, `interact()` toggles overlay, `get_interaction_text()` returns context-aware text, freezes player via `set_resting(true)`, hides HUD via `set_overlay_mode(true)`
- **Leave wilderness transition**: On "Yes" confirmation — emits `leave_wilderness_confirmed` signal, snapshots player inventory to GameState, fades music (2s), fades screen to black (3s), shows "225 miles later..." text (holds 3s), then changes scene to `res://scenes/house/house.tscn`
- **Controller support**: Checks `/root/InputManager` for correct button prompt, `ui_up`/`ui_down` to navigate, `ui_accept` to confirm, `ui_cancel` to close

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/world/trail_signpost.gd` | New | Trailhead signpost landmark — extends StaticBody3D, shared materials, BoxMesh visuals, two-choice overlay UI, leave-wilderness transition sequence |

---

## Session - Wilderness Inventory Viewer (2026-03-02)

Added a read-only Journey Inventory UI for the house scene. When the player interacts with the storage box in the Oakland Hills house, this overlay displays all items they had when completing the wilderness journey.

### Features
- **CanvasLayer overlay** (layer 100): Full-screen dark background with centered PanelContainer, following the wilderness sign overlay pattern
- **Lazy UI creation**: Builds UI programmatically on `open()`, destroys all children on `close()` for clean lifecycle
- **Sorted item list**: Reads `journey_inventory` from GameState autoload, sorts items alphabetically by display name, renders in a ScrollContainer with alternating row backgrounds
- **Item display**: Each row shows display name (32px white) and count (32px green "x{N}"), item keys converted via `.capitalize().replace("_", " ")` matching existing codebase pattern
- **Empty state handling**: Graceful grey centered message if inventory is empty
- **Player freeze/unfreeze**: Uses `set_resting(true/false)` pattern for player immobilization
- **Controller support**: Close hint uses InputManager.get_prompt("ui_cancel") for dynamic button text
- **Input handling**: Closes on `ui_cancel` action press

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/house/journey_inventory_ui.gd` | New | Read-only CanvasLayer overlay for viewing wilderness journey inventory from house storage box |

---

## Session - Oakland Hills House Scene (2026-03-02)

Created the Oakland Hills house — a complete separate Godot scene the player arrives at after completing the wilderness journey. The house is built entirely programmatically using BoxMesh primitives in the same art style as the rest of the game. Colonial style interior with dark hardwood floors, white walls, crown molding, and six-pane windows.

### Features
- **House layout**: 12x10 unit interior with 3 rooms — living room (6x5), kitchen (6x5), dining room (6x10), connected by doorways with proper wall collision
- **Colonial interior style**: Dark hardwood floors, classic white walls, off-white ceiling, crown molding along all ceiling-wall junctions, six-pane colonial windows with outdoor vista backdrops (sky, green hills, distant houses)
- **Living room**: Couch (upholstered blue-grey with arms/back), coffee table on 4 legs, bookshelf with 4 shelves of colored book spines (8 colors with height variation), muted red-brown rug, wilderness storage box with lid and handle
- **Kitchen**: Counter with white cabinet faces and handles, stove with 4 burners, kettle with handle and spout on stove, fridge with handle
- **Dining room**: Table with 4 legs, 4 chairs (seat + back + 4 legs each), sandwich on plate (with lettuce detail), chandelier with cross arms and 4 emissive light holders
- **Two cat portraits**: All-black cat with yellow eyes (body, head, ears, tail) and tuxedo cat with white chest/chin overlay, mounted on west wall in dark wood frames with cream backgrounds
- **Front door**: Solid dark wood with handle on south wall
- **5 interactable objects**: Kettle ("Warm. Familiar."), sandwich ("A good sandwich."), bookshelves ("Your old field guides. You smile."), storage box (placeholder for journey inventory viewer), front door (placeholder for NG+ selection)
- **Interaction system**: Dynamic GDScript factory creates interactable scripts at runtime, each with `interact()` and `get_interaction_text()` methods, added to "interactable" group via `_ready()`
- **Text overlay system**: Reusable centered PanelContainer on CanvasLayer (layer 100) that shows text for 2 seconds or until key press, freezes player via `set_resting()`
- **Lighting**: 5 warm OmniLight3D (no DirectionalLight), WorldEnvironment with warm ambient light, dark solid background, no fog
- **Simplified player controller**: WASD walk only (no sprint/jump), mouse/controller look, interaction raycast (same E-key pattern), bottom-center prompt panel, `set_resting()` compatibility, no HUD/health/hunger
- **Fade-in**: CanvasLayer (layer 200) with black ColorRect that tweens alpha 1->0 over 2 seconds on load
- **30 shared static materials**: All materials use `static var` pattern for zero per-instance allocation
- **Minimal .tscn file**: Just root Node3D with house_scene.gd script, everything built in `_ready()`

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/house/house_scene.gd` | New | Main house controller — builds all geometry, materials, lighting, environment, interactables, and fade-in in `_ready()` |
| `scripts/house/house_player.gd` | New | Simplified first-person player controller for indoor movement — walk only, mouse/controller look, interaction raycast, prompt UI |
| `scenes/house/house.tscn` | New | Minimal scene file — Node3D root with house_scene.gd script |

---

## Session - Endgame Homecoming: Integration Fixes (2026-03-02)

Fixed two critical integration issues from the endgame implementation: the storage box and front door in the house scene were showing placeholder text overlays instead of opening their actual UIs.

### Fixes
- **Storage box**: Now instantiates and opens `journey_inventory_ui.gd` via new `open_journey_inventory(player)` method on house_scene.gd
- **Front door**: Now instantiates and opens `new_game_plus_ui.gd` via new `open_new_game_plus(player)` method on house_scene.gd
- **NG+ subtitle**: Clarified to "Choose 5 items to bring with you (1 of each)" so players understand they get quantity 1

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/house/house_scene.gd` | Modified | Added `open_journey_inventory()`, `open_new_game_plus()` methods; updated interactable factory to call them for storage_box and front_door |
| `scripts/house/new_game_plus_ui.gd` | Modified | Updated subtitle text to clarify quantity |

---

---

## Session 36: House Interior Redesign

### What Was Built

Comprehensive interior redesign of the Oakland Hills colonial house to create a more authentic, lived-in feel with varied room character.

#### Living Room — Fireplace & Reoriented Layout
- **Brick fireplace** against west wall (south of window at Z=2.5), with firebox, hearth, mantel shelf, candlesticks, framed photo, and chimney breast to ceiling
- **Couch** reoriented to face west toward fireplace (runs along Z axis at X=3.5)
- **Coffee table** between couch and fireplace at X=2.0
- **Armchair** repositioned to north side at (2.0, 3.8), facing south toward seating area
- **End table with lamp** next to couch arm at (4.2, 2.5)
- **Rug** repositioned under seating group
- **Storage box** moved to southwest corner near kitchen divider

#### Kitchen-to-Dining Room Doorway
- Center divider wall (X=6) split into 3 sections with 1.5m doorway at Z=7.5
- Allows passage between kitchen and dining room

#### Kitchen Improvements
- Kitchen stools upgraded to **proper chairs with backs**
- **Window herb planter** on west wall kitchen window sill (terracotta box with green leaf clusters)

#### Dining Room Additions
- **Sideboard/buffet** against east wall between windows, with 4 cabinet doors, handles, candlestick holders, and serving tray
- **Deep navy area rug** under dining table
- **Potted plant** in southeast corner (terracotta pot, soil, 4 green leaf boxes at varying heights)

#### Bedroom Additions
- **Reading chair** near west wall at Z=11.0 with small side table
- **Wardrobe/armoire** against south bedroom wall with double doors, handles, and crown piece
- **Console table** in transition zone near east wall with decorative vase
- **Framed photo** on west wall in hallway transition area

#### Lighting Overhaul
- Living room: dimmer warm light + fireplace glow (orange, near floor) + end table lamp glow
- Kitchen: slightly cooler/brighter task lighting
- Dining room: chandelier with shadow casting + fill light
- Bedroom: warmer/dimmer cozy tones + nightstand lamp glow
- Added `_add_light_with_shadow()` helper function

#### Window Backdrops
- Direction-based sky and hill colors: south (bay view, bluer), north (overcast, deep green), west (warm sunset), east (crisp morning)
- Local materials created per window instead of shared static materials

#### Tree Painting Nameplates
- Small brass nameplate on dark wood backing below each tree painting
- Matches wall orientation (east/west vs north/south)

#### New Materials
- `_mat_brick`: warm red-brown (Color(0.55, 0.28, 0.18))
- `_mat_fireplace_interior`: dark charcoal (Color(0.12, 0.1, 0.1))

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/house/house_scene.gd` | Modified | Rewrote living room furniture (fireplace, couch reorientation), split center divider wall with doorway, added dining room sideboard/rug/plant, kitchen chair backs and herb planter, bedroom reading chair/wardrobe/console table, overhauled lighting, direction-based window colors, tree painting nameplates, new brick materials |

---

## Session 37: Bedroom/Kitchen Fixes, Pause Menu, Footsteps, Trail Progression Gating

### What Was Built

Fixed several house interior issues, added missing house scene features, and implemented trail progression gating for the endgame.

#### Bedroom Layout Fixes
- **Room depth increased** from 5.0 to 7.0 (`BEDROOM_DEPTH = 7.0`, Z=10-17)
- **Bed orientation fixed** — headboard now at +Z (toward north wall), footboard at -Z
- **Bed repositioned** to Z=16.0 (closer to north wall for proper bedroom feel)
- **Windows spread** to Z=12.5 and Z=15.5 (were at Z=11.5 and Z=13.5)
- **Paintings repositioned** into clear wall gaps: West at Z=11.0,14.0; East at Z=11.0,16.5; North at X=3.0
- **Nightstand** moved near headboard, drawer face flipped to face into room
- **Dresser** moved to Z=14.0 (between new window positions)
- **Rug** moved to bed_z - 1.5 (in front of footboard)
- **Bedroom lights** spread for larger room (Z=12.5 and Z=15.5)

#### Kitchen Sink Fix
- **Faucet flipped** to +Z (toward wall, was facing into room)
- **Basin deepened** (Y=0.84) with taller basin walls
- **L-return counter removed** — was blocking bedroom doorway

#### House Pause Menu (New)
- New file `scripts/house/house_pause_menu.gd`
- Resume and Quit to Desktop buttons
- Controller D-pad navigation with ui_accept to activate
- PROCESS_MODE_ALWAYS so it works while tree is paused
- SFXManager sounds on open/close/navigate

#### House Footsteps
- Added footstep sounds to `house_player.gd`
- FOOTSTEP_INTERVAL = 0.45, uses `SFXManager.play_footstep("stone")` for hardwood floors

#### Trail Progression Gating
- **Carved tree** (first marker): No prerequisite, sets `trail_carved_tree_found = true`
- **Stone cairn** (second marker): Requires carved tree found. Sets `trail_stone_cairn_found = true`
- **Signpost** (final marker): Requires stone cairn found. Sets `trail_signpost_found = true`
- Each marker has `_can_interact()` check — returns empty prompt text and blocks interaction if prerequisite not met
- `trail_testing_mode = true` in GameState bypasses all checks for development
- Trail state saved/loaded through save system (`data["trail"]` dictionary)
- `reset_journey()` resets all trail flags

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/house/house_scene.gd` | Modified | Bedroom depth 5→7, bed orientation fix, window/painting/furniture repositioning, sink faucet flip, L-return counter removed, fruit bowl moved to main counter |
| `scripts/house/house_player.gd` | Modified | Added footstep sounds (FOOTSTEP_INTERVAL, SFXManager.play_footstep) |
| `scripts/house/house_pause_menu.gd` | New | Simplified pause menu with Resume/Quit, controller support |
| `scripts/core/game_state.gd` | Modified | Added trail_carved_tree_found, trail_stone_cairn_found, trail_signpost_found, trail_testing_mode; updated reset_journey() |
| `scripts/world/trail_carved_tree.gd` | Modified | Sets trail_carved_tree_found in _show_overlay() |
| `scripts/world/trail_stone_cairn.gd` | Modified | Added _can_interact() prerequisite check (requires carved tree), sets trail_stone_cairn_found |
| `scripts/world/trail_signpost.gd` | Modified | Added _can_interact() prerequisite check (requires stone cairn), sets trail_signpost_found |
| `scripts/core/save_load.gd` | Modified | Trail state saved in _collect_save_data(), restored in _apply_save_data() |
| `scenes/main.tscn` | Modified | Player spawn at (345, 25, -345) for testing near signpost |

---

## Session 38: House Playtest Bug Fixes

### What Was Built

Extensive playtest-driven bug fixing across the house interior, addressing furniture placement, visual issues, and a critical NG+ transition bug.

#### NG+ Black Screen Fix
- **Root cause**: Fade overlay (`CanvasLayer`, layer 200) was added to `get_tree().root` and persisted across the scene change, covering everything with an opaque black rect permanently
- **Fix**: `fade_canvas.queue_free()` called in the tween callback before `change_scene_to_file()`
- File: `scripts/house/new_game_plus_ui.gd`

#### Living Room Fixes
- **End table**: Moved from (4.2, 2.5) behind the couch back to (3.5, 2.8) beside the north arm
- **Fireplace photo removed**: Framed photo was placed on the chimney breast brick wall — looked wrong, removed
- **Cat portraits relocated**: Were at Z=0.8 and Z=1.4 on west wall, hidden behind the fireplace/chimney (Z≈0.3-1.6). Moved to Z=3.5 and Z=4.2 (between window and kitchen divider)

#### Kitchen Fixes
- **Sink rebuilt with depth**: Basin bottom lowered from Y=0.84 to Y=0.68, dark `mat_basin_interior` for visible depth, walls 0.22 tall (was 0.10), proper rim at counter level
- **Kitchen chairs rotated 90°**: Backs were on -Z side (perpendicular to table). Fixed to face outward along X axis using `sign(sx) * 0.175` offset
- **Upper cabinet above stove removed**: Replaced with proper standalone range hood + chimney vent to ceiling. Stoves don't have cabinets above them.

#### Dining Room Fixes
- **Chairs rotated 180°**: All 4 chairs had backs facing toward the table instead of away. Swapped rotations: south-side chairs now `PI`, north-side now `0.0`
- **Terrain maps visible**: Grid cells were at same Z-depth as paper background (hidden inside). Offset cells 0.01 toward room interior so biome colors are visible

#### Bedroom Fixes
- **Reading chair spacing**: Moved from Z=11.0 to Z=12.0 — was only 0.15m from wardrobe at Z=10.25
- **Tree paintings squared**: Frame was 0.65×0.55 (rectangular). Changed to 0.55×0.55 (square) on all walls
- **Storage box relocated**: Moved from (0.5, 4.5) near kitchen divider (blocking doorway, unreachable) to bedroom east wall at (5.5, 12.0)

#### Hardwood Floor Planks
- New `_build_hardwood_planks()` function overlays alternating-color plank strips on the base floor
- 5 wood tone variations (Color range 0.24-0.36 red, 0.13-0.23 green, 0.06-0.12 blue)
- 0.4m wide planks with 0.02m gaps between them for visible plank lines
- Seeded RNG (seed=7531) for consistent appearance
- Covers both main house (30 planks) and bedroom (15 planks)

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/house/house_scene.gd` | Modified | End table moved, fireplace photo removed, cat portraits relocated, sink rebuilt with depth, kitchen chairs rotated, upper stove cabinet → range hood, dining chairs flipped, terrain map cells offset, reading chair moved, tree paintings squared, storage box relocated, hardwood floor planks added |
| `scripts/house/new_game_plus_ui.gd` | Modified | Free fade_canvas before scene change to prevent permanent black overlay |

---

## Session 39: House Interior Polish & Trailhead Sign (2026-03-03)

### What Was Built

Major visual polish pass across the house interior and the trailhead endgame sign, driven by playtest feedback.

#### Trailhead Sign (Endgame)
- **Font sizes dramatically increased** for climactic impact: title 56→120px, directions 36→64px, body 40→64px, choices 40→64px, hint 28→48px
- **Panel shrunk** from 80%→70% width, 90%→84% height so text fills the space better
- **VBox spacing** increased from 16→24 for breathing room

#### Living Room Furniture
- **Couch upgraded to Restoration Hardware leather**: warm tan/camel leather material (0.82, 0.72, 0.58), darker accent leather for cushion piping, 3-section tufted seat and back cushions, rolled arm details, dark walnut wooden legs
- **Couch moved against east wall**: X=3.5→5.4 (back against divider wall), coffee table shifted to X=3.8, rug centered at X=4.2
- **Armchair repositioned**: Moved from north side (X=2.0, Z=3.8) to south of fireplace (X=1.8, Z=0.5), rotated to face east toward couch

#### Kitchen Upgrades
- **Fridge: modern stainless steel French-door**: white→stainless steel material (metallic=0.7), French-door style with center seam, vertical handles, freezer drawer, ice/water dispenser, top chrome trim. Rotated 90° to sit flat against west wall with doors facing into kitchen. Moved south to clear window. Added collision body.
- **Wine fridge added** in NE corner: under-counter style (0.55×0.9×0.55), dark body with tinted glass door, chrome frame, 3 wire rack shelves with wine bottles, blue LED accent light inside

#### Fireplace Fix
- **Chimney breast shortened**: brick extended to Y=3.0 (ceiling), clipping through crown molding. Reduced to stop at Y=2.85 (below molding). Width narrowed from 1.3→1.1 to match back wall

#### Chandelier Shadows Fix
- **Disabled shadow** on dining room chandelier OmniLight. A real 4-bulb chandelier wouldn't cast sharp X-shaped arm shadows — the multiple light sources wash each other out

#### Terrain Map Paintings Redesigned
- **Complete rewrite** of `_build_terrain_map`: replaced random grid with coherent geographic features
- Winding sinusoidal river, elliptical lake with lighter shoreline, mountain cluster with grey peaks
- Forest zones with distance-based density, diagonal trail, orange campsite marker
- Finer grid (0.04 vs 0.08 cell size) for more detail

#### Console Table Moved
- Relocated from transition zone (Z=10.5, blocking hallway) to bedroom east wall (Z=12.5)

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/world/trail_signpost.gd` | Modified | All font sizes increased for dramatic endgame feel, panel anchors tightened, vbox spacing increased |
| `scripts/house/house_scene.gd` | Modified | Leather couch, couch/chair/table repositioned, stainless steel French-door fridge with collision, wine fridge, chimney breast fix, chandelier shadow fix, terrain maps rewritten, console table moved |

---

## Session 40: House Interior Batch Updates (2026-03-03)

### What Was Built

Large batch of house interior improvements driven by playtesting feedback. Many changes across furniture positioning, collision, UI, and player controller.

#### Kitchen Rework
- **Counter/stove shifted right** toward bedroom door: counter_x 1.75→2.45, stove_x 3.3→4.0. Closes the gap between stove and bedroom door area
- **Wine fridge relocated** from center divider wall to north wall, left of counter. Rotated 90° so glass door faces -Z into kitchen. Added collision body
- **Sink shifted right** with counter: sink_x 2.0→2.7, cutting board 2.6→3.3, fruit bowl 1.0→1.7
- **Upper cabinets shifted right**: 0.9→1.6, range hood 3.3→4.0 (above stove)
- **Counter/sink collision added**: Single StaticBody3D covering full counter run
- **Stove collision added**: Separate StaticBody3D for stove
- **Explorer's Journal on kitchen table**: Interactable book that opens the full journal UI, always available

#### Living Room Furniture
- **Cat portraits moved** from west wall to center divider wall (X=6) behind couch, facing -X into living room
- **Interactable name plaques** added: Tuxedo cat = "Melvin" (left), Black cat = "Webster" (right), with brass nameplates
- **Coffee table collision** added
- **Armchair collision** added
- **Kitchen table + chairs collision** added

#### Crown Molding & Baseboards
- **Baseboards split around all doorways**: Kitchen/LR doorway (X=2-4 at Z=5), center divider doorway (Z=6.75-8.25), bedroom doorway (X=4.5-5.5 at Z=10). Players no longer step over baseboards
- **Doorway casing** already had sides + top only (verified correct)

#### Wall Paintings
- **Large east wall map moved to north wall**: Two maps now centered on dining room north wall at X=8.0 and X=10.0

#### House Player Controller
- **Crosshair** added: Centered "+" label on screen (white, semi-transparent)
- **Crouch system**: Toggle on "crouch" action, reduces speed to 2.5, lowers collision box (0.9 height), camera lerps to Y=0.8, ceiling clearance check before standing
- **Jump system**: JUMP_VELOCITY=5.5, auto-stand from crouch before jumping, gravity already handled

#### House Pause Menu
- **Save Game button** added between Resume and Quit to Desktop
- Saves to slot 1 with player_location="house" marker
- Shows green "Game Saved!" confirmation for 2 seconds
- **Load system updated**: Detects house saves and transitions directly to house scene

#### NG+ UI (from previous session, committed together)
- **Redesigned to compact centered grid**: Multi-column layout, items no longer stretch full width
- **Confirmation dialog**: "Are you sure?" modal before departing to wilderness
- **Front door reopen fix**: Checks .is_open and cleans up stale instances

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/house/house_scene.gd` | Modified | Kitchen shifted right, wine fridge relocated, collision on counter/stove/table/chairs/armchair, cat portraits moved with plaques, baseboard splits, map painting moved, journal on kitchen table |
| `scripts/house/house_player.gd` | Modified | Crosshair, crouch system, jump system |
| `scripts/house/house_pause_menu.gd` | Modified | Save Game button, confirmation label, save to slot 1 |
| `scripts/house/new_game_plus_ui.gd` | Modified | Compact grid layout, confirmation dialog, front door reopen fix |
| `scripts/core/save_load.gd` | Modified | House save detection in load_game_slot(), house save display in get_slot_info() |
| `scripts/ui/pause_menu.gd` | Modified | Display "House" for house saves in slot panel |

---

## Session 41: House Playtesting Fixes (2026-03-03)

### What Was Built

Large batch of playtesting-driven fixes for the house interior.

#### Living Room
- **Couch repositioned** to X=5.45, Z=2.5 (back against divider wall, centered)
- **Armchair repositioned** to X=1.8, Z=2.5, rotated to face couch (+X direction)
- **Coffee table centered** at X=3.7, Z=2.5 between couch and chair
- **Side tables and end tables** repositioned around furniture
- **Rug fixed**: Size 3.0x3.0 at (3.5, 0.01, 2.5) — no longer extends into kitchen

#### Bedroom
- **Ponderosa painting replaced** with pixelated sunset over the ocean painting
- **Sunset painting** has full art: sky gradient, sun with emission glow, clouds, ocean, sun reflection
- **Palm painting moved** from east wall Z=16.5 to Z=11.0
- **All tree picture frames enlarged** from 0.55x0.55 to 0.7x0.7
- **Mirror above dresser removed**, replaced with sunset painting above dresser on east wall
- **Z-fighting fix**: Art offset increased to 0.03, thinned to 0.012

#### Kitchen/Dining
- **Bookshelf text** changed: removed "You smile." from interaction
- **Kettle text** changed to "Pine needle tea with osha root honey -- perfect."
- **Dining room maps** made same size (both 1.2x0.9)
- **Dining room journal removed** from dinner table (kept on kitchen table only)

#### UI & Controls
- **Jumping disabled** in house (removed jump handler)
- **NG+ controller fix**: Added ui_up/ui_down navigation to confirmation dialog
- **Save slot selection** added: Pause menu now shows slot picker when saving

#### Bug Fixes
- **Winnie portrait** accidentally replaced — restored correctly above bed
- **Variable ordering bug** fixed for sunset painting placement

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/house/house_scene.gd` | Modified | Living room layout, paintings, sunset art, kettle text, journal removed, maps resized |
| `scripts/house/house_player.gd` | Modified | Jump handling removed |
| `scripts/house/house_pause_menu.gd` | Rewritten | Save slot picker with 3 slots, slot info display |
| `scripts/house/new_game_plus_ui.gd` | Modified | Controller navigation for confirmation dialog |

---

## Session 42: Bug Fixes, Cabinet Molding, Dining Sandwich (2026-03-03)

### What Was Built

Bug fixes, UI polish, and new house details.

#### Bug Fixes
- **House save load crash fixed**: `game_loaded` signal was emitted after `change_scene_to_file()`, causing HUD's `show_notification` to call `get_tree().create_timer()` on a freed node. Removed the signal emit for house transitions. Added null guards in HUD and pause menu timer.
- **Blue flash on house load fixed**: Set `RenderingServer.set_default_clear_color(Color.BLACK)` at start of house `_ready()` to prevent default blue sky showing for one frame.
- **Save slots increased** from 3 to 5 (matching wilderness game)

#### Kitchen
- **Lower cabinet doors**: Changed from 3 to 4 doors, each with crown molding trim
- **Upper cabinet doors**: Added handles and crown molding trim around both door panels
- **Shelf with flower vase** added above kitchen sink: small shelf with metal L-brackets, cream ceramic vase, 4 colored flowers (pink, yellow, white, mauve)

#### Dining Room
- **Pastrami sandwich** added at south-left place setting with lettuce and pastrami layers
- **Water glass** added next to sandwich (transparent glass with water inside)
- **Interaction**: "Pastrami on rye -- my favorite." (3s display)

#### Bedroom
- **Palm painting removed** from east wall near armoire (user reported as blank frame)

#### UI
- **Pause menu hint** made dynamic: shows "[ESC to resume]" on keyboard, "[✕ to resume]" on controller. Updates in real-time via InputManager signal.
- **Inventory spacing fixed** (both journey inventory and NG+ UI): Changed from full-width expand to 5-space text padding between item names and quantities

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/house/house_scene.gd` | Modified | Cabinet molding, sink shelf with flowers, dining sandwich + water, blue flash fix, palm painting removed |
| `scripts/house/house_pause_menu.gd` | Modified | 5 save slots, dynamic hint text, timer null guard |
| `scripts/house/journey_inventory_ui.gd` | Modified | Item spacing fixed (5-space padding) |
| `scripts/house/new_game_plus_ui.gd` | Modified | Item spacing fixed (5-space padding) |
| `scripts/core/save_load.gd` | Modified | Removed game_loaded emit for house scene transitions |
| `scripts/ui/hud.gd` | Modified | Null guard in show_notification |

---

## Session 43 — House Polish & Save/Load Crash Fix

**Date**: 2026-03-03

### Summary

Fixed cabinet doors not appearing in the kitchen, added pickup SFX to sandwich interactions, and resolved a crash when loading a house save from the wilderness pause menu.

### Changes

#### Kitchen Cabinet Doors Fix
- **Root cause**: Cabinet door geometry was positioned on the wrong side (wall-facing instead of kitchen-facing) AND offsets pushed doors into the cabinet body instead of protruding outward
- Fixed `face_z` from `counter_z + 0.30` to `counter_z - 0.30` (lower) and `counter_z + 0.175` to `counter_z - 0.175` (upper) — puts doors on the south/kitchen-facing side
- Flipped door panel, molding trim, and handle Z offsets from `+` to `-` so geometry protrudes into the kitchen rather than disappearing into the cabinet body
- All 6 lower doors and 2 upper doors now visible with colonial raised-panel molding and handles

#### Sandwich Pickup Sound
- Added `SFXManager.play_sfx("pickup")` to both "sandwich" and "dining_sandwich" interactions in the interactable script factory, matching the tea kettle pattern

#### Save/Load Crash Fix
- **Bug**: Loading a house save slot from the wilderness pause menu crashed with "Cannot call method 'get_first_node_in_group' on a null value"
- **Root cause**: During scene teardown (`change_scene_to_file`), trail landmark nodes' `_exit_tree()` called `_hide_overlay()` which used `get_tree()` — but `get_tree()` returns null for nodes being freed during scene change
- **Fix 1**: Added `if not is_inside_tree(): return` guard in `_hide_overlay()` for all 4 trail scripts (trail_carved_tree, wilderness_sign, trail_stone_cairn, trail_signpost)
- **Fix 2**: Added `if not is_inside_tree(): return` after `await` in pause_menu's load handler — prevents calling `resume_game()` on a freed PauseMenu after scene change
- **Fix 3**: Added `is_inside_tree()` guards to house_scene's `show_text_overlay()` and `_hide_text_overlay()`
- **Fix 4**: Changed `not chunk_manager` to `not is_instance_valid(chunk_manager)` in AmbientSoundManager — catches stale freed reference after scene change

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/house/house_scene.gd` | Modified | Cabinet door Z-positioning fix (lower + upper), sandwich pickup SFX, text overlay guards |
| `scripts/ui/pause_menu.gd` | Modified | Guard after await in load handler for scene change safety |
| `scripts/world/trail_carved_tree.gd` | Modified | `is_inside_tree()` guard in `_hide_overlay()` |
| `scripts/world/wilderness_sign.gd` | Modified | `is_inside_tree()` guard in `_hide_overlay()` |
| `scripts/world/trail_stone_cairn.gd` | Modified | `is_inside_tree()` guard in `_hide_overlay()` |
| `scripts/world/trail_signpost.gd` | Modified | `is_inside_tree()` guard in `_hide_overlay()` |
| `scripts/core/ambient_sound_manager.gd` | Modified | `is_instance_valid()` check for stale chunk_manager |

---

## Session 44 — Compass Widget, Trail Clue Overhaul, Stone Cairn & Cat Portraits

**Date**: 2026-03-03

### Summary

Added an always-visible graphical compass widget to the HUD. Overhauled all trail landmark clues to include cardinal directions, distances in meters, and target coordinates computed dynamically from seed-based positions. Made the stone cairn dramatically larger as a proper landmark. Fixed cat portraits that were hidden inside a wall.

### Changes

#### Compass Widget (`scripts/ui/compass_widget.gd`)
- New self-contained `Control` using `_draw()` for custom rendering (same pattern as `bark_map_ui.gd`)
- 45px radius circle with dark semi-transparent background disc
- Outer ring with 8 tick marks (4 cardinal longer, 4 intercardinal shorter), all rotating with player yaw
- N/E/S/W labels at rotated positions — N highlighted in gold, others white
- Center dot and fixed gold chevron at 12 o'clock (direction indicator, does NOT rotate)
- Updates via `queue_redraw()` every frame for smooth rotation
- Fixed E/W swap bug (base angles were backwards)

#### HUD Integration (`scripts/ui/hud.gd`)
- Added `compass_widget` variable and `_create_compass_widget()` function
- Anchored to top-center (0.5, 0.0) at y=15, between StatsPanel and TimePanel
- Hides during overlays via `set_overlay_mode()`

#### Trail Clue Overhaul
- **Carved tree**: Clue now dynamically computes cardinal direction, distance in meters, and Z-line to the stone cairn. E.g. "Go east about 280 units. Stay on the Z: -280 line."
- **Stone cairn**: Clue shows direction, distance, and target X/Z coordinates to the signpost. E.g. "Go southeast about 100 units to X: 350, Z: -350."
- Both landmarks use a `_cardinal_direction()` helper that computes the actual 8-way direction from seed-based positions
- Body text is now set dynamically in `_show_overlay()` instead of hardcoded in `_build_overlay()`

#### Carved Tree Arrow Direction
- Tree node now rotates at spawn time (`chunk_manager.gd`) so the carved arrow physically points toward the stone cairn's actual position
- Uses `atan2(-dz, dx)` to compute the correct Y rotation from tree to cairn

#### Stone Cairn Scale-Up
- Total height increased from ~1.1 to ~4.2 units (~3.5x scale)
- Added 7th capstone layer on top
- Added ring of 8 scattered rubble stones around base for wider footprint
- Glow light energy tripled (0.4 → 1.2) and range tripled (3.5 → 10.0)

#### Cat Portraits Fix (`scripts/house/house_scene.gd`)
- **Bug**: Portraits were at X=5.97, inside the center divider wall (wall face at X=5.925)
- **Fix**: Moved to X=5.91 so frames sit flush against the wall surface
- Centered both paintings symmetrically over the couch at Z=2.0 (Melvin) and Z=3.0 (Webster)

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/ui/compass_widget.gd` | New | Graphical rotating compass widget, E/W fix |
| `scripts/ui/hud.gd` | Modified | Compass widget variable, creation function, overlay integration |
| `scripts/world/trail_carved_tree.gd` | Modified | Dynamic clue text with direction/distance/Z-line, `_cardinal_direction()` helper |
| `scripts/world/trail_stone_cairn.gd` | Modified | 3.5x larger cairn, dynamic clue with direction/distance/target coords, `_cardinal_direction()` helper |
| `scripts/world/chunk_manager.gd` | Modified | Rotate carved tree at spawn to point arrow toward cairn |
| `scripts/house/house_scene.gd` | Modified | Cat portrait X position fix, centered over couch |

---

## Session 45 — UI Fixes, Drying Rack, Food Consumption Guards, Shelter Exit

**Date**: 2026-03-04

### Summary

Fixed multiple UI and gameplay bugs: food menu positioning and sizing, save slot delete button on controller, drying rack not clearing food visuals on collection, food consumption when hunger is full, and shelter rest exit placement.

### Changes

#### Food Menu Centering Fix (`scripts/ui/food_menu.gd`)
- **Bug**: Food menu appeared at the top-left of the screen instead of centered
- **Root cause**: `anchors_preset = PRESET_CENTER` doesn't work when the panel is a direct child of a CanvasLayer (no parent Control providing a reference rect)
- **Fix**: Wrapped the main panel in a full-screen `CenterContainer` with `PRESET_FULL_RECT` anchors

#### Food Menu Sizing (`scripts/ui/food_menu.gd`)
- **Bug**: Menu was too narrow (cutting off text) and too short (only showing 3-4 items)
- **Fix**: Increased panel width from 500px to 700px, increased row height to 56px, menu now shows up to 8 rows before scrolling

#### Save Slot Delete Button on Controller (`scripts/ui/pause_menu.gd`)
- **Bug**: Navigating to the "Del" button with a controller and pressing accept would load the save slot instead of deleting it
- **Root cause**: `_activate_focused_slot_button()` always used the tracked `focused_slot_index` into `slot_buttons`, ignoring Godot's native focus which had moved to the delete button via D-pad right
- **Fix**: `_activate_focused_slot_button()` now checks `gui_get_focus_owner()` first — if a delete button has native focus, it activates that instead

#### Drying Rack Visual Cleanup (`scripts/core/save_load.gd`)
- **Bug**: Food visuals remained on the drying rack after collecting dried food
- **Root cause**: `save_load.gd`'s `_create_drying_rack()` added permanent decorative food meshes (meat strips, herb bundles) that weren't tracked by `StructureDryingRack.food_meshes`, so `_update_food_visuals()` never hid them
- **Fix**: Removed the static decorative food from the save/load rack builder — the script's `_create_food_visuals()` handles dynamic food display based on drying state

#### Food Consumption Guard (`scripts/player/player_controller.gd`)
- **Bug**: Player could consume food when hunger was already full, wasting items and showing "+0 hunger"
- **Fix**: Added guards in `consume_item()` that block consumption and show "Already full!" when:
  - Food-only items: blocked when hunger is within 0.5 of max
  - Healing-only items: blocked when health is within 0.5 of max
  - Dual food+healing items: blocked only when both stats are maxed
  - Coca leaf: exempt (primary benefit is breath buff, not hunger)
- Uses 0.5 tolerance to handle float precision (hunger 99.7 displays as 100/100)

#### Shelter Rest Exit Position (`scripts/campsite/structure_shelter.gd`)
- **Bug**: After resting, player was placed at the back of the shelter (closed end near the tarp)
- **Fix**: Flipped exit offset from `+Z` to `-Z` and rotated player facing by 180° so they exit at the open front end

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/ui/food_menu.gd` | Modified | CenterContainer wrapping, width 500→700, row height 56px, scroll sizing |
| `scripts/ui/pause_menu.gd` | Modified | Delete button focus check in `_activate_focused_slot_button()` |
| `scripts/core/save_load.gd` | Modified | Removed static decorative food from drying rack builder |
| `scripts/player/player_controller.gd` | Modified | Hunger/health full guards in `consume_item()` |
| `scripts/campsite/structure_shelter.gd` | Modified | Flipped exit offset and facing for shelter rest |

---

---

## Session 46 — Compass Coordinates, Direction Fixes, Home Scene Improvements

**Date**: 2026-03-04

### Summary

Major coordinate system overhaul replacing X/Y/Z with compass directions (E/W, N/S, Elevation). Fixed numerous direction bugs, shelter exit positions, smithing station ingot loss, and added home scene improvements including bed rest experience and journal/inventory fixes.

### Changes

#### Coordinate System Overhaul
- **HUD**: Changed from "X: 5.2 Y: 3.1 Z: 12.0" to "5.2 E  12.0 N  Elev: 3.1"
- **Trail clues**: Stone cairn and carved tree now show compass directions instead of X/Z
- **Convention**: -Z = north, +X = east, Y = elevation (Godot standard)

#### N/S Direction Fixes
- **HUD**: Walking north showed "S" — fixed conditional in `hud.gd`
- **Cardinal direction in clues**: `_cardinal_direction()` names array started with "south" at angle 0, but angle 0 = -Z = north — fixed in both trail scripts
- **Carved tree arrow**: Arrow pointed west but clue said east — mirrored X positions and swapped arrowhead angles

#### Shelter Exit Architecture (`structure_shelter.gd`, `structure_canvas_tent.gd`)
- Added virtual methods `_get_exit_offset()` and `_get_exit_facing_offset()` to base class
- Canvas tent exits at +Z (door side), basic shelter exits at -Z (open front)

#### Smithing Station Ingot Loss (`structure_smithing_station.gd`)
- **Bug**: Smelting multiple ore only produced 1 ingot (no count tracking)
- **Fix**: Added `pending_output_count`, auto-smelt chaining, batch collection, save/load persistence

#### Fish & Visual Fixes
- Fish swimming sideways: added `-PI/2` rotation offset (mesh faces +X)
- Z-fighting on fish spots: increased spot Z-size 0.062 → 0.07
- Compass rose: scaled 1.5x with transparency
- Stone cairn: cell-centered with `+ cell_size/2.0`, boosted glow
- Torch kit box: added "torch" to equipment kit model exclusion
- Cactus fruit: reduced spawn rate 10% → 4%

#### Map Persistence Through Death (`player_controller.gd`)
- Removed map_ui from `_close_all_menus()` so map stays visible

#### Journal Re-open Fix (`house_scene.gd`)
- **Bug**: L2 stopped working after closing journal once (node not freed)
- **Fix**: Connected `journal_closed` signal to `queue_free()` and clear reference

#### Wilderness Inventory Scroll (`journey_inventory_ui.gd`)
- **Bug**: Item list cut off, no controller scroll
- **Fix**: Removed expand flag from spacer, added D-pad/stick scrolling in `_process()`

#### Bed Rest Experience (`house_scene.gd`)
- Player positioned at pillow end, camera tilted 80° up toward ceiling
- Dim overlay (alpha 0.4) with centered "You rest peacefully..." text
- Toggle: "Rest in Bed" / "Get Out of Bed" with same controller command

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/ui/hud.gd` | Modified | Compass coordinate display, N/S fix |
| `scenes/ui/hud.tscn` | Modified | Default coordinate label text |
| `scripts/world/trail_stone_cairn.gd` | Modified | Compass coords, cardinal direction fix, glow |
| `scripts/world/trail_carved_tree.gd` | Modified | Compass coords, cardinal direction fix, arrow mirror |
| `scripts/world/chunk_manager.gd` | Modified | Stone cairn cell centering |
| `scripts/world/terrain_chunk.gd` | Modified | Cactus fruit rarity 10%→4% |
| `scripts/campsite/structure_shelter.gd` | Modified | Virtual exit methods |
| `scripts/campsite/structure_canvas_tent.gd` | Modified | Override exit to +Z door side |
| `scripts/campsite/structure_smithing_station.gd` | Modified | Ingot count tracking, auto-smelt |
| `scripts/resources/fishing_spot.gd` | Modified | Fish rotation fix, z-fighting fix |
| `scripts/player/player_controller.gd` | Modified | Map persistence through death |
| `scripts/player/equipment.gd` | Modified | Torch kit box exclusion |
| `scripts/ui/compass_widget.gd` | Modified | 1.5x scale, transparency |
| `scripts/house/house_scene.gd` | Modified | Journal fix, bed rest system |
| `scripts/house/journey_inventory_ui.gd` | Modified | Scroll fix, controller support |

---

---

## Session 47 — Home Scene Polish: Placards, Fireplace, NG+ Fixes, Bed Rest

**Date**: 2026-03-04

### Summary

Major home scene improvements: added name placards and interactions to all wall art (maps and paintings), interactive fireplace with fire toggle and crackling sound, fixed bed rest exit, fixed journey inventory persistence across save/load, fixed New Game+ item selection (D-pad nav, confirmation dialog, no default starter gear).

### Changes

#### Map Placards and Interactions (`house_scene.gd`)
- All 4 dining room terrain maps now have brass nameplates and interactable text overlays
- Map names: "Hidden Lake", "Deep Canyon", "Ice Cold River", "My Favorite Fishing Spot"
- Maps converted from plain Node3D to StaticBody3D with collision and interactable scripts

#### Tree Painting Placards (`house_scene.gd`)
- Oak and cactus bedroom paintings now interactable: "Coastal live oak and desert cactus"
- `_build_tree_picture()` updated to accept optional `object_type` and `frame_size` params
- Collision shapes scale with frame size

#### Ponderosa Pine Painting (`house_scene.gd`)
- Large 1.2x1.2 framed ponderosa pine on east face of center divider wall (dining room)
- Interactable with "Ponderosa pine" text overlay and brass nameplate

#### Interactive Fireplace (`house_scene.gd`)
- Player can light or extinguish the fire via interaction
- When lit: 3-layer procedural flame meshes (base orange, mid bright, tip yellow) with emission
- Warm OmniLight3D (energy 1.8, range 6.0) replaces ambient glow when fire is active
- Looping procedural crackling sound: 25 discrete pop/snap events with exponential decay, low-pass filtered
- Interaction text toggles: "Light Fireplace" / "Put Out Fire"

#### Bed Rest Exit Fix (`house_scene.gd`)
- **Bug**: Player was stuck in bed with no way to exit
- **Fix**: Added `_input` handler for ui_cancel/interact to call `_get_out_of_bed()`
- Added hint text on dim overlay showing button prompt (e.g., "[B] Get out of bed")
- Fixed duplicate `_input` function parser error by merging into existing handler
- Added 0.5s cooldown to prevent interact button from immediately bouncing player out

#### Journey Inventory Save/Load Fix (`house_pause_menu.gd`, `save_load.gd`)
- **Bug**: Saving in house and reloading lost all wilderness inventory
- **Root cause**: `_collect_house_save_data()` never serialized `journey_inventory`
- **Fix**: Save now includes `journey_inventory`, load restores it

#### New Game+ Item Selection Fixes (`new_game_plus_ui.gd`, `player_controller.gd`)
- Added D-pad left/right navigation between columns in item grid
- Fixed confirmation dialog button highlighting (replaced `find_child` with direct refs, added `>` cursor)
- Explorer's Journal excluded from selectable items
- **Bug**: Default bow/arrows/map still given in NG+
- **Root cause**: `consume_new_game_plus_items()` cleared `is_new_game_plus` before the check
- **Fix**: Capture NG+ flag before consuming items

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/house/house_scene.gd` | Modified | Map/painting placards, fireplace fire+sound, bed rest fixes |
| `scripts/house/new_game_plus_ui.gd` | Modified | D-pad left/right nav, confirmation highlighting, journal exclusion |
| `scripts/house/house_pause_menu.gd` | Modified | Save journey_inventory in house saves |
| `scripts/core/save_load.gd` | Modified | Restore journey_inventory on house load |
| `scripts/player/player_controller.gd` | Modified | Skip default items in NG+, fix flag timing |

---

---

## Session 48 — Repo Cleanup & v1.0 GitHub Release (2026-03-08)

### Summary

Cleaned up git staging area (many files had been accidentally staged via `git add .`), fixed .gitignore, and published the first GitHub Release with the macOS distributable.

### Changes

#### Git & .gitignore Cleanup
- Restored `/dist/` to .gitignore (had been removed, exposing the 192 MB zip to git)
- Added `.claude/` to .gitignore to keep Claude Code config out of the repo
- Unstaged `dist/IntoTheWild.zip` (build artifact, should never be in git)
- Deleted accidental screenshot files from `scripts/player/`

#### GitHub Release v1.0
- Created git tag `v1.0` on current main
- Published GitHub Release with `dist/IntoTheWild.zip` (192 MB) as downloadable asset
- Release URL: https://github.com/adchamberlain/into-the-wild/releases/tag/v1.0

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `.gitignore` | Modified | Restored `/dist/`, added `.claude/` |
| `scripts/player/Screenshot*.png` | Deleted | Removed accidental screenshot + import file |

---

## Session 49 — HUD Fix, Release Pipeline, Play Guide & Issue Templates (2026-03-08)

### Summary
Fixed misleading HUD save/load hints, established a fully automated release pipeline (Godot CLI export → Apple notarization → GitHub release upload), wrote a comprehensive play guide, and set up GitHub Issues for bug tracking.

### Changes

#### HUD Fix
- Fixed misleading keyboard hints: HUD showed `K-Save L-Load` but those keys only work inside the Tab config menu
- Updated hint to `Tab-Menu` to accurately reflect the workflow

#### Automated Release Pipeline
- Verified Godot CLI exports work from the command line (no GUI needed) for both macOS and Windows
- Exported macOS build (`dist/IntoTheWild.app`) with code signing
- Exported Windows build (`dist/IntoTheWild.exe` + `dist/IntoTheWild.pck`)
- Ran Apple notarization via `scripts/notarize.py` — accepted and stapled
- Created zips and uploaded both platforms to GitHub Release v1.0
- Full pipeline documented in memory for future sessions

#### Play Guide
- Created `dist/PLAY_GUIDE.md` — comprehensive game guide covering controls, survival, crafting recipes, camp progression, biomes, hunting, fishing, weather, tools, NG+, and tips
- Recommends PlayStation DualSense controller, notes keyboard/mouse also fully supported
- Uploaded to GitHub Release v1.0 as downloadable asset

#### GitHub Issues Setup
- Created `.github/ISSUE_TEMPLATE/bug_report.yml` — structured form with platform, input method, description, reproduction steps, frequency
- Created `.github/ISSUE_TEMPLATE/feature_request.yml` — simple suggestion form
- Added bug report link to top of README.md

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/ui/hud.gd` | Modified | Changed keyboard hint to `Tab-Menu` |
| `.github/ISSUE_TEMPLATE/bug_report.yml` | Created | Structured bug report template |
| `.github/ISSUE_TEMPLATE/feature_request.yml` | Created | Feature request template |
| `.github/ISSUE_TEMPLATE/config.yml` | Created | Allow blank issues |
| `README.md` | Modified | Added bug report link at top |
| `dist/PLAY_GUIDE.md` | Created | Comprehensive play guide (not in git, uploaded to release) |

---

## Session 50 — Promotional Website for intothewild.dev (2026-03-08)

### Summary
Built a promotional website for the game at intothewild.dev. Static HTML/CSS site with dark forest theme, screenshot showcase, feature grid, download links, and responsive layout. Registered domain on Cloudflare, ready for drag-and-drop deployment.

### Changes

#### Website (website/)
- Created `index.html`, `style.css`, `script.js` — same architecture as storyanalytics.ai
- Dark forest color palette: deep green/black background (`#0a0f0d`), green accent (`#6BCB77`), amber CTA buttons (`#e8a940`)
- Sections: Nav → Hero ("Survive. Build. Explore.") → Download (macOS + Windows) → 3 value prop cards → 4 screenshot showcase blocks → 9-card feature grid → 4-image gallery → CTA → Footer
- Download links point to GitHub Release v1.0 assets
- Footer links to GitHub, Play Guide, and bug reporting

#### Screenshots
- Took 10 in-game screenshots, selected 8 best for the site
- Programmatically cropped all screenshots from ultrawide (2560x1080) to game viewport only (1520x1022), removing IDE sidebar and Finder
- Placed across hero, 4 showcase blocks, and 4-image gallery grid
- Skipped bunnies.png and tortoise.png (too small/dark for web)

#### Domain & Hosting
- Registered intothewild.dev on Cloudflare
- Website files are gitignored (`/website/` in .gitignore) — not in the public repo
- Deploy via Cloudflare Pages drag-and-drop of the `website/` folder

#### README Update
- Added website link (intothewild.dev) to top of README alongside bug report link

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `website/index.html` | Created | Full landing page (gitignored) |
| `website/style.css` | Created | Dark forest theme (gitignored) |
| `website/script.js` | Created | Smooth scroll (gitignored) |
| `website/images/*.png` | Created | 8 cropped game screenshots (gitignored) |
| `.gitignore` | Modified | Added `/website/` |
| `README.md` | Modified | Added website link |

---

## Session 51 — Fix blank map HUD in house scene (2026-03-09)

### Summary
Fixed a bug where the map HUD persisted as a blank panel in the house scene after completing the game. The MapUI CanvasLayer is added to `get_tree().root` (not the scene tree), so it survived `change_scene_to_file()` calls. Added cleanup in `house_scene._ready()` to free any lingering map_ui nodes.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/house/house_scene.gd` | Modified | Added `_cleanup_wilderness_hud()` to remove lingering MapUI on house scene load |

---

## Session 52 — Fix UI hint bugs and inventory overlap (issue #12) (2026-03-09)

### Summary
Fixed 4 UI bugs reported by a player on Windows (GitHub issue #12): wrong key hints in the food menu, HUD, and crafting UI, plus inventory panel overlapping the equipped panel on smaller screens.

### Changes
1. **Food menu close hint**: Changed from `[Esc] Close` to `[F] Close` — ESC opens the pause menu, F actually toggles the food menu. This also resolves the "can't consume food" report, which was caused by hint confusion preventing users from discovering Enter to consume.
2. **HUD control hints**: Changed keyboard hints from `"C-Craft"` to `"X-Craft C-Crouch"` — C is crouch, X is craft. Added crouch hint for keyboard only (not controller).
3. **Crafting UI close hint**: Changed from `"Press C to close"` to `"Press X to close"`.
4. **Inventory panel width cap**: Clamped inventory panel's `offset_right` to `viewport_width - 480` so it can't overlap the EquippedPanel on narrow screens.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/ui/food_menu.gd` | Modified | Close prompt uses `"eat"` action (F) instead of `"ui_cancel"` (ESC) |
| `scripts/ui/hud.gd` | Modified | Keyboard hints: X-Craft C-Crouch; inventory width capped to prevent overlap |
| `scenes/ui/hud.tscn` | Modified | Default hint text updated to match runtime hints |
| `scripts/ui/crafting_ui.gd` | Modified | Close hint says X instead of C; fixed stale comment |

---

## Session 53 — Procedural Water Generation, Desert Expansion & Biome Scaling (2026-03-09)

### Summary
Major world generation overhaul: moved the desert boundary from 150 to 300 units, doubled biome sizes, fixed diamond arrow recovery bug, and implemented infinite procedural water generation so ponds, lakes, and rivers spawn at any distance as the player explores.

### Changes

1. **Diamond arrow fix**: Arrows were lost on animal hit because the projectile wasn't frozen at the impact point before becoming pickable. Added `freeze = true` and `linear_velocity = Vector3.ZERO` before `_become_pickable()`. Also added "Arrow inventory full!" HUD notification.

2. **Default brightness**: Changed from 170% to 110% in config_menu.gd.

3. **Desert boundary expansion**: Moved desert ring from 150-230 to 300-360 units from origin. Moved pocket desert from (-350, 0) to (-600, 0). Updated oasis distance to 330 units. Pushed trail landmarks outward (carved tree ~430, cairn ~410, signpost ~480). Updated journal clue text.

4. **Doubled biome size**: Changed region noise frequency from 0.008 to 0.004 so biomes cover more area and feel more expansive.

5. **Procedural water generation**: Grid-based deterministic system that spawns water features as chunks load:
   - **Water cells** (80x80 grid): Each cell hashes coordinates + world seed to decide pond/lake placement. Biome-specific probabilities (40% pond in meadow, 35% in forest, etc.). Lakes only in meadow/mountain.
   - **River cells** (200x200 grid): 25% chance per cell in hills/rocky biomes. Generates short rivers (12 segments max) with smoothing and fishing pools.
   - **Spatial hash**: O(1) water body lookups in `get_height_at()` replacing O(n) linear scan over all water bodies.
   - **Inner zone protection**: Pre-marks cells within startup generation bounds to prevent duplicates.
   - **Chunk integration**: Water cells evaluated synchronously in `_load_chunk()` before `chunk.generate()` so terrain depressions are carved correctly.

6. **Testing re-enabled**: Removed SUSPENDED status from CLAUDE.md testing rules.

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/player/diamond_arrow_projectile.gd` | Modified | Freeze arrow on animal hit, HUD notification on full inventory |
| `scripts/ui/config_menu.gd` | Modified | Default brightness 1.7 → 1.1 |
| `scripts/world/chunk_manager.gd` | Modified | Desert ring 300-360, pocket desert (-600,0), biome freq 0.004, procedural water grid + spatial hash + river cells |
| `scripts/ui/journal_ui.gd` | Modified | Updated trail clue distances |
| `CLAUDE.md` | Modified | Re-enabled testing rules |
| `docs/superpowers/specs/2026-03-09-procedural-water-generation-design.md` | Created | Design spec for procedural water |
| `docs/superpowers/plans/2026-03-09-procedural-water-generation.md` | Created | Implementation plan |

---

## Session 54 — Tutorial Hint System (2026-03-10)

### Summary
Added a minimal, ambient tutorial hint system inspired by Breath of the Wild. 18 contextual one-time hints teach new players as they play — hints fire once at the right moment, then never again. Includes a "SURVIVAL TIP" gold-bordered HUD panel, per-save-slot persistence, queue system with 4-second spacing, loading guard to prevent false triggers during save restoration, and a "Show Hints" config toggle.

### Changes

1. **HintManager autoload** (`scripts/ui/hint_manager.gd`): New autoload owning all hint definitions (18 hints), seen-state tracking, FIFO queue with 4s spacing, loading guard, and config integration. Game systems call `HintManager.try_show("hint_id")` at trigger points.

2. **HUD hint display** (`scripts/ui/hud.gd`): New `show_hint()` method with programmatically-built gold-bordered "SURVIVAL TIP" panel using RichTextLabel for BBCode highlighting. Fade in/out animations, 8s+ display duration.

3. **Save/load integration** (`scripts/core/save_load.gd`): `seen_hints` array persisted per save slot. Loading guard prevents hints from firing during inventory/crafting restoration.

4. **Config toggle** (`scripts/ui/config_menu.gd`): "Show Hints" CheckButton, on by default. When off, hints are suppressed but not marked as seen — turning hints back on mid-game still shows relevant hints.

5. **Early game triggers**: First resource gathered, first craft, hunger below 40%, fire pit/shelter/cabin placement, first fish caught.

6. **Mid/late game triggers**: First non-clear weather, camp level 2 hint and level-up, bow/machete/hang glider acquisition, rare resource collection, desert entry, water entry, fall damage, deep well/sinkhole discovery.

### Hint Catalog (18 hints)
| ID | Trigger |
|---|---|
| `first_gather` | First resource gathered |
| `first_craft` | First recipe crafted |
| `hunger_low` | Hunger below 40% |
| `first_fire_pit` | Fire pit placed |
| `first_shelter` | Shelter placed |
| `first_weather` | First non-clear weather |
| `first_fish` | First fish caught |
| `camp_level_2_hint` | 2+ structures at camp level 1 |
| `camp_level_2_up` | Camp reaches level 2 |
| `first_bow` | Bow added to inventory |
| `swim_warning` | Player enters water |
| `fall_warning` | First fall damage |
| `desert_entry` | Player enters desert |
| `first_rare_resource` | First rare resource collected |
| `first_machete` | Machete added to inventory |
| `first_hang_glider` | Hang glider added to inventory |
| `first_cabin` | Cabin placed |
| `deep_well_discovery` | Player enters sinkhole water |

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/ui/hint_manager.gd` | Created | HintManager autoload with 18 hints, queue, loading guard |
| `scripts/ui/hud.gd` | Modified | Added show_hint(), _hide_hint(), _create_hint_panel() |
| `scripts/core/save_load.gd` | Modified | Save/load seen_hints, loading guard |
| `scripts/ui/config_menu.gd` | Modified | Show Hints toggle, get/apply config |
| `scripts/resources/resource_node.gd` | Modified | first_gather trigger |
| `scripts/crafting/crafting_system.gd` | Modified | first_craft trigger |
| `scripts/player/player_stats.gd` | Modified | hunger_low trigger |
| `scripts/campsite/placement_system.gd` | Modified | fire_pit, shelter, cabin triggers |
| `scripts/resources/fishing_spot.gd` | Modified | first_fish trigger |
| `scripts/world/weather_manager.gd` | Modified | first_weather trigger |
| `scripts/campsite/campsite_manager.gd` | Modified | camp_level_2_hint, camp_level_2_up triggers |
| `scripts/player/inventory.gd` | Modified | bow, machete, hang_glider, rare resource triggers |
| `scripts/player/player_controller.gd` | Modified | desert_entry, swim_warning, fall_warning triggers |
| `scripts/world/chunk_manager.gd` | Modified | deep_well_discovery trigger |
| `project.godot` | Modified | HintManager autoload registration |
| `tests/test_hint_manager.gd` | Created | 10 tests, 17 assertions |
| `tests/run_all_tests.gd` | Modified | Registered test_hint_manager.gd |

---

## Session 54 - Tutorial Hints Polish, Home Scene Music, Canvas Tent Fixes (2026-03-10)

**Tutorial Hint System Polish** (from play-testing):
- Repositioned hint panel down (offset_top 120→220) to avoid compass collision
- Increased font sizes (header 32→44px, body 28→40px, min width 500→600) for readability
- Added light transparency to hint panel background (opacity 0.70)
- Added `{action}` placeholder system for controller-aware prompts — `_resolve_prompts()` replaces placeholders with InputManager.get_prompt() at display time (supports keyboard and DualSense)
- Fixed critical bug: seen_hints not restoring from saves — was reading from top-level `data` instead of `data["player"]` dict
- Reduced torch brightness by 20% (8.0→6.4) for held and placed torches
- Fixed 3 Godot warnings in house_scene.gd (shadowed variables)

**Home Scene Music**:
- Added 6 deep house/chill tracks from Pixabay to `assets/music/mp3/tracks/home-scene/`
- House scene stops wilderness MusicManager and plays its own playlist
- "The Mountain" plays first, remaining tracks shuffle randomly, permanent loop
- Volume at -10 dB matching wilderness ambient level

**Canvas Tent Visual Fixes**:
- Fixed guy rope rotation — ropes were pointing upward instead of downward to ground stakes (swapped rotation.z signs)
- Fixed A-frame panel corners protruding above ridge — repositioned panels so top edges align exactly at ridge line (0, 1.8), excess extends below ground and is hidden

| File | Status | Changes |
|------|--------|---------|
| `scripts/house/house_scene.gd` | Modified | Home scene music player, track shuffling, MusicManager disable |
| `scripts/campsite/placement_system.gd` | Modified | Canvas tent panel repositioning, guy rope rotation fix |
| `scripts/core/save_load.gd` | Modified | Canvas tent panel repositioning, guy rope rotation fix |
| `assets/music/mp3/tracks/home-scene/` | Created | 6 deep house/chill MP3 tracks |

---

## Session - iPad Port Implementation (2026-03-10)

**iPad Support**: Added complete iPad touch controls and mobile HUD system, targeting App Store distribution as a free app. Single codebase with platform detection (`OS.get_name() == "iOS"`).

**Day Counter (All Platforms)**: Added persistent "Day X" counter to the HUD time panel in gold text, using existing `time_manager.current_day`.

**Touch Controls** (`scripts/ui/touch_controls.gd`): Virtual joystick (bottom-left), swipe-to-look (right side), action buttons (JUMP/SPRINT/ACT), context buttons (USE/EAT/CROUCH), menu icons. All 56px, highly transparent, safe-area aware.

**Mobile HUD**: Explicit font tiers (Title 38px, Primary 28px, Secondary 22px, Hint 20px), inventory hidden, ◀ ▶ cycle arrows, safe area insets on all panels.

**Menu Adaptation**: All 8 menus get close ✕ button, 44x44 min touch targets, D-pad disabled on iOS.

**iOS Export**: Bundle ID `com.andrewchamberlain.IntoTheWild`, iPad-only landscape, iOS 14+, App Store metadata, privacy manifest.

---

## Session - iPad Testing & Refinement (2026-03-10)

Successfully exported, deployed, and tested the iPad build on real hardware. Multiple rounds of iteration to fix touch interactions, UI layout, and performance.

### iOS Export Pipeline
Established a repeatable CLI-based export pipeline (no Xcode GUI needed):
1. `Godot --headless --export-debug "iOS"` → generates Xcode project + archives + IPA
2. `xcrun devicectl device install app --device <DEVICE_ID>` → installs directly to iPad
3. iPad device ID: `5AADF247-1A77-512B-819E-25C8C4D15BCB`
4. Added `build/.gdignore` to prevent Godot from scanning export output

### Menu Button Fix (Critical Bug)
**Root cause**: Close buttons ("✕") were added as children of `PanelContainer` in `_apply_mobile_menu_style()`. Godot's `PanelContainer` resizes ALL children to fill its content area, making each close button an invisible full-panel overlay that intercepted every tap and called close/resume — so tapping any menu item would just close the menu.

**Fix**: Moved close buttons from `panel.add_child()` to `add_child()` (CanvasLayer level) with proper viewport-relative anchor positioning. Close buttons now start hidden and sync visibility with their respective menu open/close states.

**Affected files**: `pause_menu.gd`, `equipment_menu.gd`, `crafting_ui.gd`

### Removed Unnecessary iOS Touch Workarounds
Removed `_try_ios_button_press()` manual hit-testing and `_ios_touch_frame` debounce code from all three menu scripts. With the close button fix, Godot's built-in `emulate_mouse_from_touch` handles button clicks naturally — no custom touch handling needed.

### Menu CanvasLayer Ordering
Raised all menu CanvasLayers above the HUD (layer 60) and TouchControls (layer 61) so GUI input reaches menus first:
- `equipment_menu.tscn`: layer 5 → 102
- `crafting_ui.tscn`: layer 2 → 102
- `config_menu.tscn`: layer 10 → 102
- `fire_menu.tscn`: layer 10 → 102
- `storage_ui.tscn`: layer 10 → 102
- `pause_menu.tscn`: already at layer 100

### HUD Mouse Filter Fix
Added `_set_mouse_filter_ignore(self)` on iOS in `hud.gd` `_ready()` — recursively sets `MOUSE_FILTER_IGNORE` on all HUD Controls so they don't intercept GUI input destined for menu panels on lower CanvasLayers.

### Input.set_mouse_mode() iOS Guards
Wrapped all `Input.set_mouse_mode()` calls in `OS.get_name() != "iOS"` guards across 7 menu scripts. On iOS, `set_mouse_mode()` is a no-op but could interfere with touch-to-mouse emulation. Affected: `pause_menu.gd`, `equipment_menu.gd`, `crafting_ui.gd`, `config_menu.gd`, `food_menu.gd`, `fire_menu.gd`, `storage_ui.gd`.

### Compass Widget Restored on Mobile
Re-enabled the graphical rotating compass on the mobile HUD, repositioned below the stats panel (top-left, at y=95 below HP/FD bars). Previously hidden on mobile. Removed the guard in `set_overlay_mode` that was hiding compass on mobile.

### USE Button Repositioned
Moved the USE touch button from overlapping the Equipped panel (top-right) to below the ◀ ▶ slot arrows. New position: right-aligned under equipped panel at y=185, preventing overlap with longer item names.

### Left-Side HUD Stacking (Safe Area)
Fixed all left-side HUD indicator panels to use safe area offsets on mobile, preventing overlap with the compass widget. Elements now stack correctly:
- Stats panel (HP/FD): y=12 to 90
- Compass widget: y=95 to 185
- Compass panel (lodestone/POI text): y=190 to 240
- Heat indicator: y=245 to 290
- Coca leaf buff: stacks dynamically below lowest visible indicator

### Touch Controls Performance Fix
Optimized `touch_controls.gd` `_process()` to only iterate buttons when `menu_open` state changes (cached `_last_menu_open_state`), instead of every frame. Reduces per-frame work when menus are open/closed.

| File | Status | Changes |
|------|--------|---------|
| `scripts/ui/pause_menu.gd` | Modified | Close button as CanvasLayer child, removed iOS touch workarounds, debug prints, mouse_mode guards, visibility sync |
| `scripts/ui/equipment_menu.gd` | Modified | Close button as CanvasLayer child, removed iOS touch workarounds, mouse_mode guards, visibility sync |
| `scripts/ui/crafting_ui.gd` | Modified | Close button as CanvasLayer child, removed iOS touch workarounds, mouse_mode guards, visibility sync |
| `scripts/ui/hud.gd` | Modified | Compass widget on mobile, mouse_filter ignore, left-side safe area stacking, USE button note |
| `scripts/ui/touch_controls.gd` | Modified | USE button repositioned, _process optimization |
| `scripts/ui/config_menu.gd` | Modified | mouse_mode iOS guards |
| `scripts/ui/food_menu.gd` | Modified | mouse_mode iOS guards |
| `scripts/ui/fire_menu.gd` | Modified | mouse_mode iOS guards |
| `scripts/ui/storage_ui.gd` | Modified | mouse_mode iOS guards |
| `scenes/ui/equipment_menu.tscn` | Modified | CanvasLayer 5 → 102 |
| `scenes/ui/crafting_ui.tscn` | Modified | CanvasLayer 2 → 102 |
| `scenes/ui/config_menu.tscn` | Modified | CanvasLayer 10 → 102 |
| `scenes/ui/fire_menu.tscn` | Modified | CanvasLayer 10 → 102 |
| `scenes/ui/storage_ui.tscn` | Modified | CanvasLayer 10 → 102 |

---

## Session - iPad Polish & Menu Fixes (2026-03-10, continued)

### Close Button Fix for All Menus

Fixed the PanelContainer close button overlay bug across ALL remaining menus. The close button was being added as a child of PanelContainer, which stretched it to fill the entire panel and intercepted all taps. Moved close buttons to CanvasLayer children with deferred dynamic positioning using `panel.get_global_rect()`.

Fixed menus: `config_menu.gd`, `storage_ui.gd`, `food_menu.gd`, `fire_menu.gd`, `journal_ui.gd`. Previously fixed: `pause_menu.gd`, `equipment_menu.gd`, `crafting_ui.gd`.

### Quit Button Hidden on iOS

`get_tree().quit()` doesn't work on iOS (Apple forbids programmatic app termination). Hidden the Quit Game button entirely on iOS in the pause menu.

### Bow USE Button Hold-to-Draw

The mobile USE button was dispatching both press and release of `use_equipped` in the same frame via the `pressed` signal, so the bow started drawing but immediately cancelled. Changed to `button_down`/`button_up` signals for proper hold-to-draw-and-release-to-fire.

### Equipment Cycling with "None" Option

Added slot 0 ("none") to the equipment cycling array so players can unequip items by cycling through with ◀ ▶ arrows. USE button stays visible but grays out when nothing is equipped.

### Taller Touch Buttons

Doubled the height of ◀, USE, and ▶ buttons (44px → 88px) and increased font size. BAG, EAT, CRAFT, MENU buttons also made 88px tall with dark gray borders for consistent design across all top-row buttons.

### EAT Button

Added EAT button to mobile HUD near the FD (food) bar. Uses the same `_create_menu_button` as BAG/CRAFT/MENU for consistent design (84x88 dark rectangle with gray border, orange text). Fires the "eat" action to open the food/consume menu.

Fixed food menu open/close race condition — `player_controller` now calls `set_input_as_handled()` after opening the food menu to prevent `food_menu._input` from seeing the same press event and immediately closing it.

### Food Menu Touch Support

Made food item rows tappable on iOS by connecting `gui_input` on each row panel. Updated hint text from "[?] Consume" to "Tap item to eat" on mobile.

### Notification Panel Positioning

Pushed the notification panel well below the time panel on mobile (offset_top = 200+st). Required clearing `anchors_preset` and fully re-specifying anchors/offsets to ensure they stick.

### Map HUD Adjustments

Increased MAP_TOP from 200 to 250 on mobile to accommodate taller touch buttons.

### Button Color Scheme

- USE button: green text with dark green background (primary action)
- EAT button: orange text (matches FD/hunger theme)
- BAG, CRAFT, MENU: gray, all consistent design

| File | Status | Changes |
|------|--------|---------|
| `scripts/ui/config_menu.gd` | Modified | Close button moved to CanvasLayer child, deferred positioning, visibility sync |
| `scripts/ui/storage_ui.gd` | Modified | Close button moved to CanvasLayer child, deferred positioning, visibility sync |
| `scripts/ui/food_menu.gd` | Modified | Close button fix, tappable item rows on iOS, "Tap item to eat" hint |
| `scripts/ui/fire_menu.gd` | Modified | Close button moved to CanvasLayer child, deferred positioning, visibility sync |
| `scripts/ui/journal_ui.gd` | Modified | Close button moved to CanvasLayer child, deferred positioning, freed on close |
| `scripts/ui/pause_menu.gd` | Modified | Quit button hidden on iOS |
| `scripts/ui/hud.gd` | Modified | EAT button, taller ◀/USE/▶, green USE style, notification repositioning |
| `scripts/ui/touch_controls.gd` | Modified | Removed old EAT circle button, added EAT to menu strip, taller menu buttons with borders |
| `scripts/ui/equipment_menu.gd` | Modified | Close button refinements |
| `scripts/ui/bark_map_ui.gd` | Modified | MAP_TOP 200→250 on mobile |
| `scripts/player/equipment.gd` | Modified | "None" option in slot cycling, USE grays out when unequipped |
| `scripts/player/player_controller.gd` | Modified | set_input_as_handled after opening food menu |

---

## Session 38 - iOS Polish: Placement, Inventory, Save Load Fixes (2026-03-10)

Continued iPad play-testing and fixed several critical iOS issues discovered during gameplay.

### Crafting Menu Scroll Position Preserved

When crafting an item, the recipe list used to jump back to the top (all children were cleared and recreated). Now saves and restores `scroll_container.scroll_vertical` when `preserve_focus=true`, so players can craft multiple items without losing their scroll position. Also set `mouse_filter = MOUSE_FILTER_PASS` on recipe buttons and panels so touch drag gestures pass through to the ScrollContainer for smoother scrolling. Increased `scroll_deadzone` from 30 to 40.

### Placement Mode Touch Buttons

Placing structures (campfire kit, shelter, etc.) was impossible on iOS — the USE button grayed out when entering placement mode (item gets unequipped), and the cancel prompt referenced the Q key which doesn't exist on touch. Fixed by transforming the ◀/USE/▶ button strip during placement:
- ◀ becomes **X** (cancel) — fires `unequip` action to cancel placement
- USE becomes **PLACE** (or **MOVE** during structure move) — stays enabled to confirm
- ▶ is hidden during placement
- Buttons restore to normal when placement ends

### Structure MOVE Button

Added a contextual golden MOVE button that appears below the equipment arrows when near a moveable structure (shelter, fire pit, etc.). Fires the `move_structure` action. Hidden when player walks away.

### Touch-Friendly Placement Prompts

On iOS, placement prompts now show "Walk to position, tap PLACE to set down" instead of "[R] Place [Q] Cancel" which referenced non-existent keyboard keys.

### Resource Inventory in BAG Menu

The BAG (equipment) menu on iOS now shows a full inventory with three sections:
- **Equipment** — tap to equip (same as before)
- **Resources** — wood, branches, rocks, ore, etc. with counts
- **Food** — berries, fish, cooked items, etc. with counts

Title changed from "Equipment" to "Inventory". Resource/food sections update in real-time when inventory changes.

### Save Load Touch Controls Fix

Loading a saved game broke all touch controls (no joystick, no buttons, no camera panning). Root cause: `static var menu_open` on TouchControls persisted across scene reloads — saving from the pause menu left it `true`, hiding everything permanently. Fixed by resetting `menu_open = false` in `_ready()`.

Also fixed player controller lookup — replaced single-frame `await` with a retry loop (up to 60 frames) so touch look works even if the player node loads late after a save.

### EAT Button Visibility on Save Load

EAT button didn't appear after loading a save because `eat_button` member variable was never assigned (local `_eat_btn` was used instead). Fixed assignment and added initial visibility check in `_find_player_deferred` based on current food inventory.

### EAT Button Position

Moved EAT button rightward (300→380 + safe margin) to avoid overlapping with underwater air bubble display.

### Notification Panel Position

Pushed notification panel further down (offset_top 200→320 + safe top) to fully clear the time panel and menu buttons on iOS.

### Crafting Menu Event Consumption

Added `_handle_input()` (set_input_as_handled) after toggling the crafting menu to prevent the action event from being processed by multiple handlers, which could cause an immediate open-then-close.

| File | Status | Changes |
|------|--------|---------|
| `scripts/ui/crafting_ui.gd` | Modified | Scroll position preserved on craft, MOUSE_FILTER_PASS for touch scroll, event consumption fix |
| `scripts/ui/equipment_menu.gd` | Modified | Resource/food inventory sections on iOS, title → "Inventory" |
| `scripts/ui/hud.gd` | Modified | Placement touch buttons (PLACE/X/MOVE), notification position fix, structure MOVE button |
| `scripts/ui/touch_controls.gd` | Modified | menu_open reset, player lookup retry, EAT button assignment + position, initial visibility |
| `scripts/ui/food_menu.gd` | Modified | scroll_deadzone for iOS |
| `scripts/ui/storage_ui.gd` | Modified | scroll_deadzone for iOS |

---

## Session 39 - App Store Submission & iOS Bug Fixes (2026-03-11)

Prepared the game for Apple App Store submission, fixed multiple iOS bugs discovered during iPad play-testing, and submitted v1.0.0 for review.

### App Store Preparation

- Generated all 15 iOS icon sizes from `icon.svg` using `rsvg-convert`, stored in `resources/ios-icons/`
- Wired icons into `export_presets.cfg` (icon_1024x1024, app_store_1024x1024, ipad_167x167, etc.)
- Updated bundle ID from `com.andrewchamberlain.IntoTheWildGame` to `com.andrewchamberlain.into-the-wild`
- Set version to `1.0.0` in export presets
- Expanded `APP_STORE_METADATA_IOS.md` with full feature list, promotional text, privacy policy URL, and support URL
- Created `build/ExportOptions.plist` for App Store Connect upload
- Resized iPad screenshots (2388x1668) to App Store dimensions (2732x2048) with black bar padding
- Generated iPhone 6.5" screenshots (2778x1284) for App Store requirement
- Verified release readiness: `trail_testing_mode = false`, player spawn at `(0, 25, 0)`

### iOS Bug Fixes

**Jump button stuck after release**: `TouchScreenButton.action` doesn't reliably fire action release on iOS. Replaced native action handling with explicit `pressed`/`released` signal handlers using `Input.parse_input_event()` for all touch buttons (JUMP, SPRINT, ACT, and menu buttons). Same pattern already used by the USE button in hud.gd.

**Wrong signal names crashed all buttons**: `TouchScreenButton` extends `Node2D`, not `BaseButton` — uses `pressed`/`released` signals, not `button_down`/`button_up`. The wrong signal names caused runtime errors preventing all touch buttons and menus from rendering.

**PLACE button grayed out during structure placement**: When entering placement mode, the item gets unequipped, triggering the equipment update callback to disable the USE/PLACE button. Added `in_placement_touch_mode` flag so the callback skips disabling the button while placement is active.

**Hang glider missing from equipment menu**: Added `hang_glider` to `EQUIPMENT_SLOTS` array in `equipment_menu.gd`.

**Hang glider hint incorrect**: Changed tip from "use sprint for speed boost" to "tap jump repeatedly for a boost".

### Performance Optimizations

**UI blocking check** (`_is_ui_blocking_input`): Replaced 6x `get_nodes_in_group()` calls per physics frame with a single `TouchControls.menu_open` static flag check. All menus already maintain this flag.

**Grappling hook target detection**: Throttled from every frame to 10x/sec (`GRAPPLE_CHECK_INTERVAL = 0.1`). Saves 3 raycasts + terrain lookups ~50 times/sec.

**Ambient animal movement**: Reduced terrain height samples from 5 to 1 per movement frame (single `get_height_at` instead of `_get_smoothed_terrain_height`). Throttled obstacle raycasts to every 5th movement frame.

### Inventory Sorting

Equipment list now sorts alphabetically on mobile (no keyboard hotkeys to preserve order for). Resources and food sections already sorted alphabetically.

| File | Status | Changes |
|------|--------|---------|
| `export_presets.cfg` | Modified | iOS icons, bundle ID, version 1.0.0 |
| `APP_STORE_METADATA_IOS.md` | Modified | Full rewrite with features, URLs |
| `resources/ios-icons/*.png` | Created | 15 icon sizes from SVG |
| `scripts/ui/touch_controls.gd` | Modified | Explicit pressed/released signals, removed btn.action |
| `scripts/ui/hud.gd` | Modified | in_placement_touch_mode flag for PLACE button |
| `scripts/ui/equipment_menu.gd` | Modified | Alphabetical sort on mobile, hang glider slot |
| `scripts/ui/hint_manager.gd` | Modified | Hang glider hint text fix |
| `scripts/player/player_controller.gd` | Modified | TouchControls.menu_open instead of group queries |
| `scripts/player/grappling_hook.gd` | Modified | Throttled target detection |
| `scripts/creatures/ambient_animal_base.gd` | Modified | Reduced height samples, throttled raycasts |

---

## Session 40 - iOS Controller Bug Fixes (2026-03-11)

Fixed multiple bugs discovered during iPad play-testing with a Sony PlayStation (DualSense) controller.

### Controller Hints Overlapping Time Display

Controller hint labels ("Share-Equip", "Pad-Craft", etc.) were children of the EquippedPanel at the top-right, causing them to overflow leftward over the time/day display. Created a new `ControllerHintsPanel` anchored to bottom-center of the screen for controller hints on mobile. Touch mode still hides hints entirely (touch buttons replace them).

### Crafting Menu Inaccessible on iOS Controller

The `open_crafting` action was mapped only to `JOY_BUTTON_TOUCHPAD` (button_index 20), which Apple's GCController framework doesn't expose for DualSense controllers on iOS. Added R3 (right stick click, button_index 8) as an additional mapping. Updated controller prompts from "Pad" to "R3".

### Touch Controls Don't Return After Controller Disconnect

The `InputManager` only detected device changes via input events, so powering off a controller left the system stuck in controller mode with invisible touch controls. Added `Input.joy_connection_changed` signal handler to auto-switch back to touch mode on iOS when a controller disconnects.

### Equipped Panel Overlapping Slot Arrows

The equipped panel had a fixed 80px height, causing overlap with the ◀ USE ▶ buttons when content had multiple lines (e.g., bow with arrow count + durability bar). Made the panel auto-size to content, and the slot arrows now dynamically reposition below the panel after each update.

### Compact Equipped Text on Mobile Controller

With controller connected, the equipped label showed verbose hints like "Equipped: Bow (10 regular arrows) [R-click aim, D-Dn switch, □ unequip]" which covered the time display. On mobile with controller, now shows only the item name and essential info (e.g., arrow count). Action hints are in the bottom controller hints panel.

### Circle Button Triggering Bow Shot

After shooting with R2, pressing Circle (jump) would also fire the bow. Root cause: the HUD's USE button (`Button` node) could receive Godot's controller focus, and Circle (mapped to `ui_accept`) would activate it. Set `focus_mode = FOCUS_NONE` on all HUD buttons (◀, USE, ▶, MOVE).

### Stale Xcode Project Cleanup

Removed old `Into_the_Wild.xcodeproj` (generated from project name "Into the Wild") that kept reappearing alongside the current `IntoTheWild.xcodeproj`. Enabled `delete_old_export_files_unconditionally` in iOS export preset.

| File | Status | Changes |
|------|--------|---------|
| `scripts/ui/hud.gd` | Modified | Bottom controller hints panel, auto-sizing equipped panel, compact text on mobile controller, focus_mode=FOCUS_NONE on all HUD buttons |
| `scripts/systems/input_manager.gd` | Modified | R3 prompt for crafting, joy_connection_changed handler for controller disconnect |
| `project.godot` | Modified | Added R3 (button_index 8) to open_crafting action |
| `export_presets.cfg` | Modified | delete_old_export_files_unconditionally=true |

---

## Next Session

### Planned Tasks
1. Check Apple App Store review status — address any rejection feedback
2. Submit update with controller bug fixes once v1.0.0 is approved
3. Continue iPad play-testing with controller — verify all menus navigate correctly
4. Deploy website to Cloudflare Pages at intothewild.dev
5. Continue play-testing end-of-game trail sequence with new clues and compass
6. Review and fix any bugs filed via GitHub Issues

### Known Issues
- Tortoise materials are per-instance (minor, could be shared static)
- Rock spire uses per-instance materials (minor, only one ever spawns)
- Interactable script factory uses string formatting — fragile if labels contain special characters (current labels are all safe)
- WeatherForecast test expects unequip maps to ✕ but prompt is □ (pre-existing test mismatch)

### Reference
See `into-the-wild-game-spec.md` for full game specification.
