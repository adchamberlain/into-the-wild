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

### Files Changed

| File | Status | Changes |
|------|--------|---------|
| `scripts/world/cloud_manager.gd` | Created | 30-cloud pool, BoxMesh clusters, weather/time integration, wind drift with wrapping, time-scaled speed |
| `scripts/world/environment_manager.gd` | Modified | Added horizon haze (CylinderMesh + gradient shader), haze time-of-day colors, weather modifiers, camera tracking |
| `scenes/main.tscn` | Modified | Added CloudManager node as child of EnvironmentManager |
| `scenes/ui/config_menu.tscn` | Modified | Day length slider step set to 1.0 (whole minutes) |
| `docs/plans/2026-02-23-sky-clouds-haze-design.md` | Created | Design document for sky improvements |
| `docs/plans/2026-02-23-sky-clouds-haze.md` | Created | Implementation plan |

---

## Next Session

### Planned Tasks
1. Add desert biome far from spawn site
2. Remove TEMP test spawn items (bow + 20 arrows + bark_map) once satisfied
3. Continue play-testing and bug fixing

### Reference
See `into-the-wild-game-spec.md` for full game specification.
