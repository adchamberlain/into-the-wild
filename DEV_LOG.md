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

## Next Session

### Planned Tasks
1. Source ~23 sound files from Pixabay to populate sfx directories
2. Add UI sounds to menus (optional)
3. Game balancing and polish
4. Optional: DualSense haptics and adaptive triggers
5. Cave entrances in rocky regions (deferred)

### Reference
See `into-the-wild-game-spec.md` for full game specification.
