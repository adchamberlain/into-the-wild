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

## Session 2 - Phases 2-4 Complete (2026-01-19)

### What Was Built

**Phase 2: Gathering** - Complete
**Phase 3: Survival Meters** - Complete
**Phase 4: Crafting** - Complete
**Bonus: Equipment System** - Complete

#### Updated Project Structure
```
into-the-wild/
├── scripts/
│   ├── player/
│   │   ├── player_controller.gd   # Added interaction raycast, E to interact, R to use tool
│   │   ├── player_stats.gd        # NEW: Health and hunger management
│   │   ├── inventory.gd           # NEW: Item storage with signals
│   │   └── equipment.gd           # NEW: Equippable items and effects
│   ├── resources/
│   │   └── resource_node.gd       # NEW: Harvestable resource nodes
│   ├── crafting/
│   │   └── crafting_system.gd     # NEW: Recipe management and crafting
│   └── ui/
│       ├── hud.gd                 # Updated: Stats bars, inventory display, equipment
│       └── crafting_ui.gd         # NEW: Crafting interface
```

#### Features Implemented

1. **Resource Nodes** (`scripts/resources/resource_node.gd`)
   - Harvestable objects: branches, river rocks, berries
   - Interaction via raycast (E key)
   - Tool requirements (some resources need axe)
   - Multi-chop resources (trees require multiple hits)
   - Gather/chop animations with visual feedback
   - Depleted state hides node and disables collision

2. **Inventory System** (`scripts/player/inventory.gd`)
   - Dictionary-based storage (resource_type → quantity)
   - Add/remove/check items with signals
   - Live UI updates via `inventory_changed` signal

3. **Player Stats** (`scripts/player/player_stats.gd`)
   - Health: 100 max, drains when starving, regenerates when full
   - Hunger: 100 max, depletes over time (faster when sprinting)
   - `eat()`, `take_damage()`, `heal()` methods
   - Signals for UI updates and player death
   - Note: Hunger depletion currently disabled for testing (line 46)

4. **Crafting System** (`scripts/crafting/crafting_system.gd`)
   - 5 starter recipes:
     - Stone Axe (2 river rock + 1 branch)
     - Torch (2 branches)
     - Campfire Kit (4 branches + 3 river rocks)
     - Rope (3 branches)
     - Berry Pouch (5 berries)
   - `can_craft()` checks materials, `craft()` consumes and produces
   - Discovery system foundation (all recipes unlocked for now)

5. **Crafting UI** (`scripts/ui/crafting_ui.gd`)
   - Toggle with C key
   - Shows all recipes with ingredients and descriptions
   - Buttons disabled when materials insufficient
   - Auto-refreshes when inventory changes

6. **Equipment System** (`scripts/player/equipment.gd`)
   - Number keys 1-4 to equip items, Q to unequip
   - Equippable items:
     - Torch (slot 1): Creates OmniLight3D for illumination
     - Stone Axe (slot 2): Tool for chopping resources
     - Campfire Kit (slot 3): Placeable item
     - Rope (slot 4): Utility item
   - Tool usage with R key (swing animation, chop resources)
   - Placeable items create world objects (campfire with light)

7. **HUD Updates** (`scripts/ui/hud.gd`)
   - Health and hunger progress bars
   - Live inventory display panel
   - Currently equipped item display
   - Interaction prompts ("[E] Gather Branch")

#### Controls (Updated)
- **WASD** - Move
- **Mouse** - Look around
- **Space** - Jump
- **Shift** - Sprint
- **Escape** - Release/capture mouse
- **E** - Interact (gather resources)
- **R** - Use equipped tool (chop) or place item
- **C** - Toggle crafting menu
- **1-4** - Equip item in slot
- **Q** - Unequip current item

#### Known Issues / Notes
- Hunger depletion disabled for testing (`player_stats.gd` line 46)
- All recipes auto-discovered (discovery-based learning not yet active)
- Campfire is purely visual (no cooking functionality yet)
- Resource nodes don't respawn

---

## Session 3 - Terrain & Collision Improvements (2026-01-24)

### What Was Built

**Terrain collision and object collision overhaul**

#### Changes Made

1. **Object Collision** (`scenes/main.tscn`)
   - Marker rocks converted from `MeshInstance3D` to `StaticBody3D` with `BoxShape3D` collision
   - Removed redundant visual-only marker trees (duplicates of resource trees)
   - All objects in the world now have proper collision - player cannot walk through them

2. **Terrain System Rewrite** (`scripts/world/terrain_generator.gd`)
   - Terrain material now has `cull_mode = CULL_DISABLED` to prevent see-through from any angle
   - Reduced terrain resolution for more blocky, Minecraft-like appearance
   - Flat campsite area (12 unit radius) at y=0 with smooth transition to hills
   - All terrain heights are positive (no negative valleys) for walkability
   - **HeightMapShape3D** collision - proper terrain collision that works with CharacterBody3D
   - Player can walk/jump on hills where slope is gentle enough

3. **Player Spawn** (`scenes/main.tscn`)
   - Player now spawns at y=5 and falls onto terrain
   - Ensures player doesn't spawn inside collision geometry

#### Technical Notes
- `HeightMapShape3D` is the correct collision type for terrain in Godot 4
- Trimesh collision causes movement issues with CharacterBody3D
- Backface culling must be disabled on terrain material to prevent see-through

---

## Session 4 - Phase 5 Complete (2026-01-24)

### What Was Built

**Phase 5: Campsite Building System** - Complete

#### New Files Created

```
scripts/campsite/
├── structure_base.gd        # Base class for all structures (extends StaticBody3D)
├── structure_data.gd        # Static data: structure types, costs, scenes
├── structure_fire_pit.gd    # Fire pit with warmth, light, interaction
├── structure_shelter.gd     # Shelter with weather protection area
├── structure_storage.gd     # Storage container with own inventory
├── placement_system.gd      # Grid-based preview, validation, placement
└── campsite_manager.gd      # Tracks structures, campsite level progression

scenes/campsite/structures/
├── fire_pit.tscn            # Fire pit scene (rocks, fire mesh, light, warmth area)
├── basic_shelter.tscn       # Lean-to shelter (frame, canvas, protection area)
└── storage_container.tscn   # Wooden storage box
```

#### Features Implemented

1. **Structure Base System** (`structure_base.gd`)
   - Base class extending StaticBody3D (same pattern as ResourceNode)
   - Added to "interactable" and "structure" groups for raycast detection
   - `interact()`, `get_interaction_text()` interface
   - `on_placed()` callback and destruction signals

2. **Structure Data** (`structure_data.gd`)
   - Static definitions for all structure types
   - Maps items to structures (campfire_kit → fire_pit, etc.)
   - `is_placeable_item()` utility for equipment system

3. **Fire Pit** (`structure_fire_pit.gd` + `fire_pit.tscn`)
   - Rock ring mesh, fire cone mesh, OmniLight3D
   - Warmth area (5m radius) with Area3D
   - `is_in_warmth_range()`, `get_warmth_at()` for survival integration
   - Fire state management (lit/extinguished)

4. **Basic Shelter** (`structure_shelter.gd` + `basic_shelter.tscn`)
   - Lean-to design: frame beam, angled canvas cover, support poles
   - Protection Area3D (3m radius) for weather protection
   - Player enter/exit detection via Area3D signals
   - `is_in_protection_range()` for survival integration

5. **Storage Container** (`structure_storage.gd` + `storage_container.tscn`)
   - Wooden box mesh with lid detail
   - Has its own Inventory instance (20 slots)
   - `open_storage()`, `close_storage()` interaction
   - Item add/remove/check methods for transfer

6. **Placement System** (`placement_system.gd`)
   - Attached to Player as child node
   - Preview mode with transparent ghost mesh
   - Grid snapping (1 meter grid)
   - Real-time collision validation via PhysicsShapeQueryParameters3D
   - Green (valid) / Red (invalid) visual feedback
   - R to confirm (if valid), Q to cancel
   - On confirm: instantiates structure, consumes item, registers with manager
   - Fallback: creates structures programmatically if scene doesn't exist

7. **Campsite Manager** (`campsite_manager.gd`)
   - Tracks all placed structures with counts by type
   - Campsite level progression:
     - Level 1: Survival Camp (starting level)
     - Level 2: Established Camp (fire_pit + shelter + crafted tool)
     - Level 3: Homestead (storage + 3+ structures)
   - Signals: `structure_added`, `structure_removed`, `campsite_level_changed`
   - Listens to crafting system for tool crafting flag
   - Helper methods: `is_near_fire()`, `is_in_shelter()` for survival

8. **New Recipes** (`crafting_system.gd`)
   - Shelter Kit: 6 branches + 2 rope
   - Storage Box: 4 wood + 1 rope

9. **Equipment Updates** (`equipment.gd`)
   - Added slots 5 (Shelter Kit) and 6 (Storage Box)
   - Keys 5 and 6 now equip new items
   - `_place_item()` delegates to PlacementSystem
   - Legacy fallback for campfire if PlacementSystem missing

10. **HUD Updates** (`hud.gd` + `hud.tscn`)
    - Campsite level display: "Camp Lvl 1: Survival Camp"
    - Updates when `campsite_level_changed` signal fires
    - Updated controls list to show slots 1-6

11. **Scene Updates**
    - `player.tscn`: Added PlacementSystem node
    - `main.tscn`: Added CampsiteManager node, Structures container

#### Placement Flow
1. Player crafts campfire_kit/shelter_kit/storage_box
2. Equip with 3/5/6 key
3. Press R to enter placement mode
4. Ghost preview follows player aim, snapped to 1m grid
5. Real-time validation (distance, collisions)
6. Green = valid, Red = invalid
7. R confirms (if valid), Q cancels
8. On confirm: item consumed, structure placed, registered with manager

#### Level 2 Requirements (from spec)
- Build proper shelter (basic_shelter) ✓
- Establish reliable fire source (fire_pit) ✓
- Craft first real tool (stone_axe) ✓

#### Controls (Updated)
- **1-6** - Equip item in slot
- **R** - Use/Chop/Place (enters placement mode for placeable items)
- **Q** - Unequip current item / Cancel placement

#### Bug Fixes During Testing
- Fixed trees not disappearing when chopped (now uses `queue_free()`)
- Added crosshair to HUD for easier resource targeting
- Fixed placement validation detecting ground as obstacle
- Fixed shelter geometry (front frame now at ground level, proper lean-to shape)
- Added rest functionality to shelter (+10 health)
- Added warm up functionality to fire pit (+15 health)
- Added more resources to world (20 branches, 5 rocks) for full crafting

#### Known Issues / Notes
- Storage UI is console-based only (no graphical transfer interface yet)
- Structures don't have durability/damage yet
- Weather system not implemented (shelter protection is ready for it)
- Fire doesn't require fuel (always lit when placed)

---

## Session 5 - Phase 6 Complete (2026-01-24)

### What Was Built

**Phase 6: Weather & Enhanced Survival** - Complete

#### New Files Created

```
scripts/world/
└── weather_manager.gd    # Weather state machine, damage application, protection checks
```

#### Files Modified

```
scripts/world/environment_manager.gd   # Weather color overlays, fog effects
scripts/player/player_stats.gd         # Re-enabled hunger, added weather hunger multiplier
scripts/campsite/structure_fire_pit.gd # Added effectiveness, extinguish methods
scripts/ui/hud.gd                      # Weather display, protection status
scenes/ui/hud.tscn                     # Weather and protection labels
scenes/main.tscn                       # Added WeatherManager node
```

#### Features Implemented

1. **Weather Manager** (`scripts/world/weather_manager.gd`)
   - 6 weather types: Clear, Rain, Storm, Fog, Heat Wave, Cold Snap
   - Weather transitions at time period changes (dawn, morning, etc.)
   - Weather state machine:
     - Clear → Can transition to any weather
     - Rain → Can escalate to Storm (30% chance)
     - Storm → Returns to Clear after duration
     - Cold Snap only at Night/Dawn
     - Heat Wave only during Morning/Afternoon
   - Configurable transition probabilities
   - Weather duration: 1-3 game hours

2. **Weather Effects**
   - **Storm**: 2 HP/sec damage when outside shelter
   - **Cold Snap**: 1.5 HP/sec damage when not near fire
   - **Heat Wave**: Hunger depletes 2x faster
   - **Rain**: Fire effectiveness reduced to 50%
   - **Storm + Fire**: Fire extinguishes after 30 seconds unless player is nearby to tend it

3. **Visual Weather Effects** (`environment_manager.gd`)
   - Weather color overlays modifying sky/ambient colors
   - Rain: Darker, bluer tint
   - Storm: Very dark grey
   - Fog: White/grey with fog density effect
   - Heat Wave: Yellow/orange tint
   - Cold Snap: Blue tint
   - Dynamic fog density per weather type

4. **Hunger System Re-enabled** (`player_stats.gd`)
   - Removed testing early return
   - Added `hunger_multiplier` property (default 1.0)
   - Weather Manager sets multiplier to 2.0 during heat waves
   - Normal depletion rate: ~16 minutes to empty when idle

5. **Fire Weather Interactions** (`structure_fire_pit.gd`)
   - `set_effectiveness(value)` - Reduces warmth radius and light intensity
   - `extinguish()` - Puts out fire (can be relit by interaction)
   - `tend_fire()` - Keeps fire alive during storms
   - During rain: warmth radius reduced to 50%
   - During storm: fire extinguishes after 30 seconds if player isn't nearby

6. **HUD Weather Display** (`hud.gd` + `hud.tscn`)
   - Weather label shows current weather type
   - Color-coded: dangerous weather in orange/red
   - Protection status: "Sheltered", "Near Fire", "Sheltered + Fire", "Exposed"
   - Green = protected, Red = exposed in dangerous weather
   - Damage flash effect when taking weather damage

#### Weather State Machine

```
        ┌──────────────────────────────────────┐
        │                                      │
        ▼                                      │
     CLEAR ──────► RAIN ──────► STORM ─────────┘
        │           │
        │           └──────────────────────────┐
        │                                      │
        ├──────► FOG ──────────────────────────┤
        │                                      │
        ├──────► HEAT_WAVE (day only) ─────────┤
        │                                      │
        └──────► COLD_SNAP (night/dawn only) ──┘
```

#### Protection Logic

| Weather    | Damage Rate | Protection Required     |
|------------|-------------|-------------------------|
| Storm      | 2 HP/sec    | Shelter                 |
| Cold Snap  | 1.5 HP/sec  | Fire warmth             |
| Heat Wave  | 2x hunger   | None (must eat more)    |
| Rain       | None        | Reduces fire effectiveness |
| Fog        | None        | Reduces visibility      |
| Clear      | None        | -                       |

#### Testing/Debug

WeatherManager has a `set_weather_debug(weather_name)` method for testing:
- Call from console or script to force specific weather
- Valid names: "clear", "rain", "storm", "fog", "heat", "cold"

#### Known Issues / Notes

- Weather is purely procedural (no save/load yet)
- Fog visual effect is subtle - may want to adjust density
- Fire must be manually relit after storm extinguishes it
- No visual rain/snow particles yet (just color overlay and fog)

---

## Session 5b - Config Menu (2026-01-24)

### What Was Built

**Developer/Player Config Menu** - Toggle game features for testing

#### New Files Created

```
scripts/ui/config_menu.gd    # Config menu logic and state
scenes/ui/config_menu.tscn   # Config menu UI
```

#### Files Modified

```
scripts/player/player_stats.gd    # Added hunger_depletion_enabled, health_drain_enabled flags
scripts/world/weather_manager.gd  # Added weather_enabled flag
scenes/main.tscn                  # Added ConfigMenu node
scenes/ui/hud.tscn                # Updated controls list
```

#### Features Implemented

1. **Config Menu** (`config_menu.gd` + `config_menu.tscn`)
   - Toggle with **Tab** key
   - Shows/hides mouse cursor when opened/closed
   - Settings persist during game session

2. **Toggleable Options**
   - **Hunger Depletion**: On/Off (default: Off)
   - **Health Drain (Starvation)**: On/Off (default: Off)
   - **Weather System**: On/Off (default: On)
   - **Day Length**: Slider 1-60 minutes (default: 20)

3. **Integration**
   - PlayerStats checks `hunger_depletion_enabled` before depleting hunger
   - PlayerStats checks `health_drain_enabled` before draining health from starvation
   - WeatherManager checks `weather_enabled` before changing weather or applying effects
   - Disabling weather forces clear weather immediately
   - Day length changes apply immediately to TimeManager

#### Controls (Updated)
- **Tab** - Toggle config menu

---

## Session 5c - Equipment Menu & Improvements (2026-01-24)

### What Was Built

**Equipment Menu & Config Improvements**

#### New Files Created

```
scripts/ui/equipment_menu.gd    # Equipment menu logic
scenes/ui/equipment_menu.tscn   # Equipment menu UI
```

#### Files Modified

```
scripts/player/player_stats.gd    # Added weather_damage_enabled flag
scripts/world/weather_manager.gd  # Check weather_damage_enabled before applying damage
scripts/ui/config_menu.gd         # Added weather damage toggle
scenes/ui/config_menu.tscn        # Added weather damage toggle UI
scenes/main.tscn                  # Added EquipmentMenu, 10 more branches
scenes/ui/hud.tscn                # Cleaned up controls list
```

#### Features Implemented

1. **Equipment Menu** (`equipment_menu.gd` + `equipment_menu.tscn`)
   - Toggle with **I** key
   - Shows all 6 equipment slots with their hotkeys
   - Displays item count from inventory
   - Shows which item is currently equipped (green, "[EQUIPPED]")
   - Grayed out items you don't have
   - Updates live when inventory/equipment changes

2. **Weather Damage Toggle** (Config Menu)
   - New toggle: "Weather Damage (Storms/Cold)"
   - Default: Off
   - Separate from weather system toggle (weather can change but not damage you)
   - Affects storm damage and cold snap damage only

3. **More Resources**
   - Added 10 more branches (Branch21-30) spread around the map
   - Total branches now: 30 (was 20)

4. **HUD Cleanup**
   - Removed overlapping Controls list entirely
   - Simplified equipment hint to "I-Equip  C-Craft  Tab-Config"
   - Clean layout: stats top-left, time/weather top-right, inventory bottom-left, equipped bottom-right

#### Config Menu Options (Updated)

| Setting | Description | Default |
|---------|-------------|---------|
| Hunger Depletion | Hunger bar drains over time | Off |
| Health Drain (Starvation) | Health drains when hunger is zero | Off |
| Weather Damage (Storms/Cold) | Take damage from storms and cold snaps | Off |
| Weather System | Weather changes dynamically | On |
| Unlimited Fire Burn Time | Fire never runs out of fuel | Off |
| Tree Respawn Time | Days until chopped trees respawn (1-7) | 1 day |
| Day Length | Minutes per game day (1-60) | 20 |

#### Tree Respawning
- Trees respawn after a configurable number of game days (default: 1 day)
- Regular resources (branches, rocks, berries) respawn after 6 game hours
- ResourceManager tracks day rollover for multi-day respawn timers
- Tree respawn time can be adjusted from 1-7 days in the config menu

#### Controls (Updated)
- **I** - Equipment menu (shows slots and hotkeys)
- **Tab** - Config menu
- **1-6** - Equip items (shown in equipment menu)

---

## Session 6 - Save/Load & Resource Respawning (2026-01-25)

### What Was Built

**Phase 7 (Partial): Save/Load System & Resource Improvements**

#### New Files Created

```
scripts/core/save_load.gd           # Save/load game state to JSON
scripts/resources/resource_manager.gd   # Tracks resources and handles respawning
```

#### Files Modified

```
scripts/resources/resource_node.gd     # Support for secondary drops, respawning instead of queue_free
scenes/resources/tree_resource.tscn    # Trees now drop 3 branches + 3 wood
scripts/ui/config_menu.gd              # Added save/load buttons and F5/F9 shortcuts
scenes/ui/config_menu.tscn             # Added save/load UI elements
scripts/ui/hud.gd                      # Added notification system for save/load feedback
scenes/ui/hud.tscn                     # Added notification label, updated control hints
scenes/main.tscn                       # Added SaveLoad and ResourceManager nodes
```

#### Features Implemented

1. **Save/Load System** (`scripts/core/save_load.gd`)
   - Saves game state to `user://saves/save.json`
   - Serializes:
     - Player position, health, hunger
     - Inventory contents
     - Time of day (hour, minute)
     - Weather type and duration
     - Campsite level, placed structures, crafted tool flag
     - Depleted resources for respawn tracking
     - Discovered recipes
   - Structures are recreated from saved data with full state restoration
   - Fire pits retain lit/extinguished state

2. **Resource Respawning** (`scripts/resources/resource_manager.gd`)
   - Depleted resources no longer use `queue_free()` - they hide and disable instead
   - ResourceManager tracks all resource nodes and their depleted time
   - Resources respawn after 6 game hours (configurable)
   - Handles day wrap-around for respawn timing
   - `respawn_all()` method available for testing

3. **Tree Drop Update** (`resource_node.gd`)
   - Added `secondary_resource_type` and `secondary_resource_amount` exports
   - Trees now give **3 wood + 3 branches** when chopped down
   - Supports any resource having a secondary drop

4. **Save/Load Controls**
   - **K** - Quick save (works anywhere) - "Keep"
   - **L** - Quick load (works anywhere) - "Load"
   - Save/Load buttons in Config Menu (Tab)
   - Visual feedback: "Game Saved!" / "Game Loaded!" notifications

5. **HUD Updates**
   - Notification label for save/load feedback (top center, auto-hides)
   - Updated control hints: "F5-Save  F9-Load"

#### Save File Format

```json
{
  "version": 1,
  "timestamp": "2026-01-25T...",
  "player": {
    "position": {"x": 0, "y": 5, "z": 0},
    "health": 100,
    "hunger": 100,
    "inventory": {"branch": 5, "wood": 3, ...},
    "equipped_item": "stone_axe"
  },
  "time": {"hour": 8, "minute": 30},
  "weather": {"weather_type": 0, "duration_remaining": 50.0},
  "campsite": {
    "level": 2,
    "has_crafted_tool": true,
    "structures": [...]
  },
  "resources": {
    "depleted": [{"node_name": "Branch1", "depleted_hour": 8, "depleted_minute": 0}]
  },
  "crafting": {"discovered_recipes": ["stone_axe", "torch", ...]}
}
```

#### Controls (Updated)
- **K** - Quick save
- **L** - Quick load
- **Tab** - Config menu (also has Save/Load buttons)

#### Shelter Resting System
- Press **E** on shelter to lay down and rest (camera looks up at canvas, +10 health)
- Press **E** again to get up and exit the shelter
- Movement and mouse look disabled while resting
- HUD shows "[E] Get Up" prompt while resting
- **Sleep feature**: If resting at night (after 7 PM), screen fades to black and time skips to dawn (6 AM)
  - Full health restore when sleeping through night
  - +30 hunger restore
  - Fade-to-black visual effect

#### Storage UI
- Press **E** on storage box to open storage transfer UI
- Two-panel layout: Your Inventory (left) and Storage Box (right)
- Click **>>** to move one item to storage, **<<** to take one item
- Click **All** to transfer entire stack
- Press **E** or **Escape** to close

#### Fire Pit Interaction Menu
- Press **E** on fire to open interaction menu with three options:
  - **Warm Up** (+15 Health) - Visual flare effect, HUD notification
  - **Cook Food** - Cook berries/mushrooms/fish for more hunger restoration
  - **Add Fuel** - Add 1 wood to extend fire burn time by 1 day
- **Fuel System**: Fire burns fuel over time (1 game day default)
  - 1 game day = 1200 seconds at default 20-minute day length
  - Fire dims when fuel runs low (<30%)
  - Fire extinguishes when fuel depleted
  - Need 1 wood to relight or extend burn time
  - Adding 1 wood adds 1 day of burn time (can stockpile up to 2 days)
  - **Config Option**: "Unlimited Fire Burn Time" toggle in config menu (Tab)
- **Cooking Recipes**:
  - Berry → Cooked Berries (+25 hunger vs +15 raw)
  - Mushroom → Cooked Mushroom (+20 hunger vs +10 raw)
  - Fish → Cooked Fish (+40 hunger)
- Visual flare effect on all interactions
- HUD notifications for feedback

#### Known Issues / Notes
- Save file located at `user://saves/save.json` (Godot user data folder)
- Only one save slot currently (could expand to multiple slots later)
- Resources respawn at their original positions even after loading
- Structures container must exist for structure recreation

---

## Session 6b - Fire Fuel System & Tree Respawning (2026-01-25)

### What Was Built

**Fire Fuel System Improvements & Tree Respawning**

#### Files Modified

```
scripts/campsite/structure_fire_pit.gd    # Fuel system: 1 day burn time, wood as fuel
scripts/ui/fire_menu.gd                   # Uses wood instead of branches for fuel
scripts/ui/config_menu.gd                 # Added unlimited fire toggle, tree respawn slider
scenes/ui/config_menu.tscn                # Added toggle and slider UI elements
scripts/resources/resource_manager.gd     # Separate tree respawn time, day tracking
scenes/main.tscn                          # Connected ResourceManager to ConfigMenu
DEV_LOG.md                                # Updated documentation
```

#### Features Implemented

1. **Fire Fuel System**
   - Fire burns for 1 game day by default (1200 seconds at 20-minute day length)
   - Adding 1 wood extends burn time by 1 day
   - Can stockpile up to 2 days of fuel
   - Fire dims below 30% fuel, extinguishes at 0%
   - **Config Toggle**: "Unlimited Fire Burn Time" disables fuel consumption

2. **Tree Respawning**
   - Trees respawn after configurable number of game days (default: 1 day)
   - Separate respawn timer for trees vs regular resources
   - ResourceManager tracks day rollover for multi-day timers
   - **Config Slider**: "Tree Respawn Time" adjustable from 1-7 days
   - Regular resources (branches, rocks, berries) still respawn after 6 game hours

3. **Config Menu Updates**
   - New toggle: "Unlimited Fire Burn Time"
   - New slider: "Tree Respawn Time (days)"
   - Panel expanded to accommodate new options

---

## Next Session: Phase 7 - Content & Polish (Continued)

### Completed Features
- ✅ Save/Load system
- ✅ Resource respawning (6 hours for regular, 1-7 days for trees)
- ✅ Storage UI for item transfer
- ✅ Shelter resting with sleep/time skip
- ✅ Fire pit interaction menu with cooking
- ✅ Fire fuel system (1 day burn time, wood as fuel)
- ✅ Config toggles for survival mechanics

### Planned Tasks
1. Additional recipes and structures (cooking grate, crafting bench)
2. Weather particle effects (rain, snow)
3. Sound effects and ambient audio
4. Discovery-based crafting system
5. Level 2/3 campsite content
6. Fishing system (to use the "fish" cooking recipe)
7. Game polish and balancing

### Reference
See `into-the-wild-game-spec.md` for full game specification.
