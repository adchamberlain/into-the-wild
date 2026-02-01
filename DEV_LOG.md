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

## Next Session

### Planned Tasks
1. Sound effects (footsteps, interactions, ambient)
2. Game balancing and polish
3. Pixelated textures (optional)
4. Save/load for new progression flags
5. Optional: DualSense haptics and adaptive triggers

### Reference
See `into-the-wild-game-spec.md` for full game specification.
