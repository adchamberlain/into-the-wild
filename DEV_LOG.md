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

## Next Session

### Planned Tasks
1. Add camera collision to prevent clipping into terrain
2. Add grappling hook sound effect audio files
3. Disable `debug_performance` logging once stuttering is confirmed fixed

### Reference
See `into-the-wild-game-spec.md` for full game specification.
