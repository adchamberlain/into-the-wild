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

## Session 7 - High Priority Features (2026-01-25)

### What Was Built

**Four Core Gameplay Features**

#### New Files Created

```
scripts/resources/fishing_spot.gd       # Fishing location with cast/catch mechanics
scenes/resources/fishing_spot.tscn      # Visual water area with collision
scenes/resources/mushroom.tscn          # Mushroom resource (uses resource_node.gd)
scenes/resources/herb.tscn              # Herb resource (uses resource_node.gd)
scripts/campsite/structure_crafting_bench.gd  # Crafting bench structure
scenes/campsite/structures/crafting_bench.tscn  # Wooden workbench
```

#### Files Modified

```
scripts/player/equipment.gd             # Added durability system, fishing rod (slot 7), crafting bench kit (slot 8)
scripts/player/player_controller.gd     # Added herb, fish to FOOD_VALUES, healing_salve as healing item
scripts/crafting/crafting_system.gd     # Added fishing_rod, healing_salve, crafting_bench_kit recipes
scripts/campsite/structure_data.gd      # Added crafting_bench structure definition
scripts/campsite/placement_system.gd    # Added crafting_bench programmatic fallback
scripts/ui/hud.gd                       # Added durability bar, tool broken notification
scenes/ui/hud.tscn                      # Added DurabilityBar ProgressBar node
scripts/ui/equipment_menu.gd            # Added slots 7-8 for new items
scripts/core/save_load.gd               # Added tool_durability save/load, crafting_bench recreation
scenes/main.tscn                        # Added 10 mushrooms, 8 herbs, 3 fishing spots
```

#### Features Implemented

1. **Tool Durability System** (`equipment.gd`)
   - Tools now have durability that decreases with use
   - Stone Axe: 150 max durability, -1 per chop
   - Fishing Rod: 50 max durability, -1 per catch
   - Durability bar shows under equipped item display
   - Tool breaks when durability reaches 0 (removed from inventory)
   - Signals: `durability_changed`, `tool_broken`
   - Durability saved/loaded with game state

2. **Fishing System** (`fishing_spot.gd` + `fishing_spot.tscn`)
   - 3 fishing spots placed in world (edges of map)
   - Requires fishing rod equipped (slot 7)
   - Multi-step mechanic:
     1. Look at fishing spot, press R to cast
     2. Wait 3-8 seconds (random)
     3. "Fish on the line!" notification appears
     4. Press R within 2 seconds to catch
     5. Fish added to inventory, durability used
   - Fishing spots deplete after catch, respawn later
   - Visual feedback with water color changes

3. **New World Resources** (mushrooms + herbs)
   - 10 mushrooms scattered in wooded areas (brown cap, white stem)
   - 8 herbs near campsite center (green leafy plants)
   - Both use existing resource_node.gd system
   - Respawn after 6 game hours
   - Food values: mushroom (+10 hunger), herb (+5 hunger)

4. **Crafting Bench Structure** (`structure_crafting_bench.gd`)
   - Placeable wooden workbench
   - Opens crafting UI when interacted with (E key)
   - Recipe: 6 wood + 4 branch → crafting_bench_kit
   - Equip with key 8, place with R

5. **New Recipes**
   - **Fishing Rod**: 3 branch + 1 rope (tool for catching fish)
   - **Healing Salve**: 3 herb → instant heal item (+30 health)
   - **Crafting Bench Kit**: 6 wood + 4 branch (placeable workbench)

6. **Healing Items**
   - Healing salve provides instant +30 health when used (F key)
   - Prioritizes healing items when health is low

#### Equipment Slots (Updated)

| Slot | Item | Notes |
|------|------|-------|
| 1 | Torch | Light source |
| 2 | Stone Axe | Chop trees (150 durability) |
| 3 | Campfire Kit | Placeable fire pit |
| 4 | Rope | Crafting material |
| 5 | Shelter Kit | Placeable lean-to |
| 6 | Storage Box | Placeable storage |
| 7 | Fishing Rod | Catch fish (50 durability) |
| 8 | Crafting Bench Kit | Placeable workbench |

#### Resource Summary

| Resource | Location | Amount | Respawn |
|----------|----------|--------|---------|
| Mushroom | Wooded areas | 10 nodes | 6 hours |
| Herb | Near campsite | 8 nodes | 6 hours |
| Fish | Fishing spots | 3 spots | 6 hours |

#### Gameplay Flow

**Fishing:**
1. Craft fishing rod (3 branch + 1 rope)
2. Equip with key 7
3. Find fishing spot (blue circular water areas)
4. Look at spot, press R to cast
5. Wait for "Fish on the line!" notification
6. Quickly press R to catch
7. Cook fish at campfire for +40 hunger

**Healing:**
1. Gather 3 herbs near campsite
2. Craft healing salve (C menu)
3. Press F when health is low to use salve (+30 health)

---

## Session 8 - Weather Particle Effects (2026-01-31)

### What Was Built

**Weather Particle Effects System** - Visual particles for rain, storm, snow, and dust/fog

#### New Files Created

```
scripts/world/weather_particles.gd    # Controller for weather particles
scenes/effects/weather_particles.tscn # Scene wrapper (programmatic setup)
```

#### Files Modified

```
scenes/player/player.tscn    # Added WeatherParticles as child of Camera3D
scenes/main.tscn             # Added weather_manager_path to WeatherParticles
DEV_LOG.md                   # This documentation
```

#### Features Implemented

1. **Weather Particles Controller** (`scripts/world/weather_particles.gd`)
   - Connects to `weather_changed` signal from WeatherManager
   - Creates and configures GPUParticles3D nodes programmatically
   - Smooth tween transitions (2 seconds) between weather states
   - Camera-relative positioning (attached to Camera3D)

2. **Rain Particles**
   - 600 particles falling at 15-20 m/s
   - Elongated quad mesh (0.05 x 0.3 units)
   - Semi-transparent blue-white color
   - 1.5 second lifetime
   - Emission box: 15x0.5x15 units above camera

3. **Storm Particles**
   - 1200 particles (2x rain density)
   - Faster velocity: 20-30 m/s
   - Wind offset in direction vector (angled fall)
   - Darker blue-grey color
   - 1.2 second lifetime

4. **Snow Particles** (Cold Snap)
   - 400 particles with slow fall (2-4 m/s)
   - Turbulence enabled for drifting effect
   - Square white snowflakes (0.15 x 0.15 units)
   - 4 second lifetime for long drifts

5. **Dust/Haze Particles** (Fog/Heat Wave)
   - 150 large particles (1x1 units)
   - Very slow drift (0.5-1.5 m/s)
   - Low opacity (0.1-0.15 alpha)
   - Grey for Fog, yellow-tinted for Heat Wave
   - 6 second lifetime

#### Weather-to-Particle Mapping

| Weather | Particles | Description |
|---------|-----------|-------------|
| Clear | None | All particles fade out |
| Rain | RainParticles | 600 falling droplets |
| Storm | StormParticles | 1200 heavy rain with wind |
| Fog | DustParticles | Grey floating particles |
| Heat Wave | DustParticles | Yellow-tinted dust |
| Cold Snap | SnowParticles | Drifting snowflakes |

#### Technical Details

- Uses GPUParticles3D for performance (GPU-accelerated)
- All particle systems created programmatically in `_ready()`
- Particles attached to Camera3D for camera-relative effect
- Smooth 2-second tween transitions using `amount_ratio`
- ParticleProcessMaterial used for physics configuration
- Billboard mode for particles to always face camera

#### Testing

Use WeatherManager debug method to force weather changes:
```gdscript
weather_manager.set_weather_debug("rain")   # Test rain particles
weather_manager.set_weather_debug("storm")  # Test storm particles
weather_manager.set_weather_debug("cold")   # Test snow particles
weather_manager.set_weather_debug("fog")    # Test dust/fog particles
weather_manager.set_weather_debug("heat")   # Test heat wave dust
weather_manager.set_weather_debug("clear")  # Fade out all particles
```

---

## Session 8b - Night Sky (Stars and Moon) (2026-01-31)

### What Was Built

**Night Sky System** - Stars and moon visible during nighttime hours

#### Files Modified

```
scripts/world/environment_manager.gd   # Added stars and moon systems
DEV_LOG.md                             # This documentation
```

#### Features Implemented

1. **Star Field** (GPUParticles3D)
   - 800 star particles in a large sphere (300 unit radius)
   - Stars appear at dusk (~6 PM) and fade at dawn (~7 AM)
   - Billboard quads always face camera
   - Varying sizes (0.5x to 1.5x scale)
   - Unshaded white material for bright appearance
   - Follows camera position for infinite sky illusion

2. **Moon**
   - Sphere mesh (3 unit radius by default)
   - Pale yellow-white color with emission glow
   - Moves across night sky:
     - Rises in east at dusk
     - Overhead at midnight
     - Sets in west at dawn
   - Fades in/out with stars

3. **Moon Light**
   - Subtle directional light from moon direction
   - Blue-tinted light color (0.7, 0.75, 0.9)
   - Low intensity (0.15 max) for ambient night illumination
   - Only active during night hours

4. **Weather Integration**
   - Stars and moon visibility reduced by weather:
     - Storm: 0% visibility (completely obscured)
     - Rain: 30% visibility
     - Fog: 20% visibility
     - Cold Snap: 90% visibility (clear cold nights)
     - Clear: 100% visibility

#### Configuration Options

New export variables in EnvironmentManager:
- `star_count: int = 800` - Number of star particles
- `moon_size: float = 3.0` - Moon sphere radius
- `moon_distance: float = 200.0` - Distance from camera to moon

#### Time-based Behavior

| Time | Stars | Moon |
|------|-------|------|
| 6 AM - 7 AM | Fading out | Fading/setting |
| 7 AM - 6 PM | Hidden | Hidden |
| 6 PM - 8 PM | Fading in | Rising |
| 8 PM - 6 AM | Full brightness | Visible, moving |

#### Technical Details

- Stars use `one_shot = true` with long lifetime for static positions
- Night sky container follows camera position (not rotation)
- Moon position calculated using trigonometry for arc path
- All materials use `SHADING_MODE_UNSHADED` for consistent brightness
- Stars use `no_depth_test = true` to render behind all objects

---

## Session 8c - Fishing Visual Improvements (2026-01-31)

### What Was Built

**Enhanced Fishing Experience** - Organic ponds, visible swimming fish, fishing rod model

#### Files Modified

```
scripts/resources/fishing_spot.gd    # Complete rewrite with organic ponds and fish
scenes/resources/fishing_spot.tscn   # Simplified (mesh now created programmatically)
scripts/player/equipment.gd          # Added fishing rod model and animations
DEV_LOG.md                           # This documentation
```

#### Features Implemented

1. **Organic Pond Shape**
   - Replaced cylindrical pond with irregular organic polygon
   - 12-point perturbed ellipse for natural shoreline
   - Muddy brown shore ring around water edge
   - Decorative rocks placed around pond edge
   - Pond sits flat with the landscape (minimal height)

2. **Swimming Fish**
   - 3 visible fish per pond by default
   - Fish swim around randomly within pond bounds
   - Subtle bobbing animation for realism
   - Fish head towards movement direction
   - When bite occurs, one fish swims toward the line
   - Fish hidden when pond is depleted, shown on respawn

3. **First-Person Fishing Rod**
   - Visible rod model when fishing rod equipped (slot 7)
   - Brown wooden handle with lighter wood rod
   - Positioned in lower-right of view
   - Casting animation when line is cast
   - Fishing line appears during fishing

4. **Caught Fish Animation**
   - Fish model appears at end of line when caught
   - Animated reeling in with spinning fish
   - Rod lifts up during catch
   - Visual feedback for successful catch

#### Pond Configuration

New export variables in FishingSpot:
- `fish_count: int = 3` - Number of visible fish
- `pond_width: float = 4.0` - Pond size X
- `pond_depth: float = 3.0` - Pond size Z
- `pond_height: float = 0.15` - Water surface height

#### Fish Behavior

- Fish swim at 0.3 units/second
- Random target positions within pond bounds
- Pick new target when within 0.2 units of current target
- Subtle vertical bobbing (±0.005 units)
- Face direction of movement

---

## Session 8d - Blocky Minecraft-Style Aesthetic (2026-01-31)

### What Was Built

**Complete Visual Overhaul** - Converted all rounded meshes to blocky box-based meshes for a Minecraft-like aesthetic

#### Files Modified

**Scene Files:**
```
scenes/resources/tree_resource.tscn    # Trunk: CylinderMesh → BoxMesh, Foliage: SphereMesh → BoxMesh
scenes/resources/mushroom.tscn         # Cap & stem: CylinderMesh → BoxMesh
scenes/resources/herb.tscn             # Leaves & stem: CylinderMesh → BoxMesh
scenes/player/player.tscn              # Player body: CapsuleMesh → BoxMesh
scenes/campsite/structures/fire_pit.tscn    # Rocks & fire: CylinderMesh → BoxMesh
scenes/campsite/structures/basic_shelter.tscn # Poles: CylinderMesh → BoxMesh
scenes/main.tscn                       # Rocks & berries: SphereMesh → BoxMesh
```

**Script Files:**
```
scripts/resources/fishing_spot.gd      # Shore rocks & fish: SphereMesh/PrismMesh → BoxMesh
scripts/player/equipment.gd            # Fishing rod, caught fish, legacy campfire → BoxMesh
scripts/world/environment_manager.gd   # Moon: SphereMesh → BoxMesh
scripts/campsite/placement_system.gd   # Programmatic fire pit & shelter → BoxMesh
```

#### Mesh Conversions

| Object | Before | After |
|--------|--------|-------|
| Tree trunk | CylinderMesh | BoxMesh (0.7 x 3.0 x 0.7) |
| Tree foliage | SphereMesh | BoxMesh (2.5 x 2.0 x 2.5) |
| Mushroom cap | CylinderMesh | BoxMesh (0.35 x 0.1 x 0.35) |
| Mushroom stem | CylinderMesh | BoxMesh (0.1 x 0.15 x 0.1) |
| Herb leaves | CylinderMesh | BoxMesh (0.25 x 0.15 x 0.25) |
| Herb stem | CylinderMesh | BoxMesh (0.06 x 0.1 x 0.06) |
| Player body | CapsuleMesh | BoxMesh (0.6 x 1.8 x 0.6) |
| Fire pit rocks | CylinderMesh | BoxMesh (1.2 x 0.3 x 1.2) |
| Fire flames | CylinderMesh (cone) | BoxMesh (0.5 x 0.7 x 0.5) |
| Shelter poles | CylinderMesh | BoxMesh (0.1 x 1.6 x 0.1) |
| Rocks (resource) | SphereMesh | BoxMesh (0.4 x 0.35 x 0.4) |
| Berries | SphereMesh | BoxMesh (0.25 x 0.3 x 0.25) |
| Shore rocks | SphereMesh | BoxMesh (variable size) |
| Swimming fish | SphereMesh body + PrismMesh tail | BoxMesh body + BoxMesh tail |
| Caught fish | SphereMesh + PrismMesh | BoxMesh + BoxMesh |
| Fishing rod | CylinderMesh (4 parts) | BoxMesh (4 parts) |
| Fishing line | CylinderMesh | BoxMesh (thin) |
| Moon | SphereMesh | BoxMesh (flat square) |

#### Visual Style Notes

- All objects now use BoxMesh with simple dimensions
- Colors remain the same (solid, no textures)
- Gives a cohesive Minecraft/voxel-like appearance
- Flat shading inherent to box geometry provides hard edges

---

## Session 8e - Background Music (2026-01-31)

### What Was Built

**Ambient Background Music System** - Minecraft-style music plays during gameplay

#### New Files Created

```
scripts/core/music_manager.gd    # Music playback with shuffle and crossfade
ATTRIBUTIONS.md                  # Third-party asset credits
```

#### Files Modified

```
scenes/main.tscn                 # Added MusicManager node
scenes/ui/config_menu.tscn       # Added music toggle and volume controls
scripts/ui/config_menu.gd        # Added music settings handlers
DEV_LOG.md                       # This documentation
```

#### Features Implemented

1. **Music Manager** (`scripts/core/music_manager.gd`)
   - Loads 12 ambient music tracks from assets/music/mp3/tracks/
   - Shuffled playback order (no repeats until all played)
   - Crossfade transitions (3 seconds) between tracks
   - Pause between tracks (5 seconds) like Minecraft
   - Volume control via config menu
   - Enable/disable toggle

2. **Config Menu Controls**
   - Music toggle (on/off)
   - Volume slider (0-100%)
   - Settings applied immediately

3. **Attribution**
   - Created ATTRIBUTIONS.md with music credits
   - Source: Minecraft-style Music Pack by Valdis Story
   - Reddit: https://www.reddit.com/r/godot/comments/1gllruv/

#### Music Tracks (12 total)

- Cuddle Clouds
- Drifting Memories
- Evening Harmony
- Floating Dream
- Forgotten Biomes
- Gentle Breeze
- Golden Gleam
- Polar Lights
- Strange Worlds
- Sunlight Through Leaves
- Wanderer's Tale
- Whispering Woods

#### Technical Details

- Uses two AudioStreamPlayer nodes for crossfading
- Default volume: -10 dB (quieter for ambient background)
- MP3 format used (smaller file size than WAV)
- Fisher-Yates shuffle for random track order

---

## Session 9 - Terrain, Forest, and Tool Visuals (2026-01-31)

### What Was Built

**Blocky Terrain, Procedural Forest, and First-Person Tool Models**

#### Files Modified

```
scripts/world/terrain_generator.gd      # Blocky Minecraft-style terrain with forest spawning
scripts/world/environment_manager.gd    # Improved lighting for better contrast
scripts/player/equipment.gd             # Stone axe model, fishing line fix
scripts/resources/fishing_spot.gd       # Improved fishing flow with auto-uncast
scenes/resources/tree_resource.tscn     # Brightened tree colors
```

#### Features Implemented

1. **Blocky Minecraft-Style Terrain** (`terrain_generator.gd`)
   - Replaced smooth terrain with stepped blocky terrain
   - Cell-based generation (3x3 unit cells)
   - Height quantization (0.5 unit steps) creates distinct terraces
   - Flat shading with explicit normals for hard edges
   - Vertical cliff faces where height differences occur
   - Flat campsite area preserved in center

2. **Procedural Forest Generation** (`terrain_generator.gd`)
   - Noise-based density creates natural clustering
   - Thick patches where noise is high, sparse/clearings where low
   - ~80-120 trees spawned around campsite
   - Trees placed at correct terrain height
   - Random rotation and scale (0.7x to 1.3x) for variety
   - Minimum distance from campsite (14 units)
   - Trees added to Resources container for ResourceManager tracking

3. **First-Person Stone Axe Model** (`equipment.gd`)
   - Visible blocky axe when stone_axe equipped (slot 2)
   - Wooden handle, stone head, blade edge, rope binding
   - Positioned in lower-right view
   - Swing animation with wind-up and chop motion:
     - Wind up: raises back and right
     - Chop: swings down and forward with blade leading
   - Blade correctly oriented to hit target

4. **Fishing Line Fix** (`equipment.gd`)
   - Line now properly hangs from rod tip down into water
   - Uses pivot node at rod tip with global rotation override
   - Line follows rod tip position but always points straight down

5. **Improved Fishing Flow** (`fishing_spot.gd`)
   - Updated interaction text: "[E] Cast Line" → "Waiting for bite..." → "[E] Reel In!"
   - Notification now includes instruction: "Fish on the line! Press E!"
   - Line automatically uncasts when fish gets away
   - Added `hide_fishing_line()` method for clean retraction

6. **Lighting and Contrast Improvements** (`environment_manager.gd`, `terrain_generator.gd`, `tree_resource.tscn`)
   - Increased ambient light energy (0.8 → 1.0)
   - Increased SSIL indirect lighting (0.5 → 0.7)
   - Disabled SSAO for softer shadows
   - Brightened tree trunk color (0.4, 0.25, 0.15) → (0.55, 0.4, 0.3)
   - Brightened tree foliage (0.2, 0.5, 0.2) → (0.25, 0.55, 0.25)
   - Brightened terrain color (0.35, 0.55, 0.25) → (0.45, 0.62, 0.35)

#### Terrain Configuration

| Setting | Value | Description |
|---------|-------|-------------|
| cell_size | 3.0 | Size of each terrain block |
| height_scale | 6.0 | Maximum terrain height |
| height_step | 0.5 | Height quantization step |
| noise_scale | 0.02 | Terrain noise frequency |

#### Forest Configuration

| Setting | Value | Description |
|---------|-------|-------------|
| tree_density | 0.15 | Base spawn probability |
| tree_min_distance | 14.0 | Min distance from center |
| tree_max_distance | 48.0 | Max distance from center |
| tree_grid_size | 3.0 | Placement grid cell size |

#### Controls (Updated)
- **2** - Equip stone axe (now visible in hand)
- **E/R** - Swing axe to chop (animated chop motion)

---

## Session 10 - Minecraft Forest Biome Visual Overhaul (2026-01-31)

### What Was Built

**Complete Forest Biome Aesthetic Update** - Minecraft-style terrain, varied tree types, and ground decorations

#### New Files Created

```
scenes/resources/big_tree_resource.tscn     # Large oak tree (2x trunk, larger canopy)
scenes/resources/birch_tree_resource.tscn   # Birch tree (white trunk, lighter leaves)
```

#### Files Modified

```
scripts/world/terrain_generator.gd      # Vertex colors, tree type system, ground decorations
scenes/resources/tree_resource.tscn     # Updated to small oak style with layered canopy
```

#### Features Implemented

1. **Terrain Dual-Color System** (`terrain_generator.gd`)
   - Top faces now use bright grass green `Color(0.48, 0.75, 0.35)`
   - Side/cliff faces use brown dirt `Color(0.55, 0.35, 0.2)`
   - Implemented via vertex colors with `vertex_color_use_as_albedo`
   - Creates classic Minecraft grass-block look

2. **Small Oak Tree** (`tree_resource.tscn`)
   - Layered canopy for rounded sphere shape:
     - Main layer: 3.5 x 2.0 x 3.5
     - Middle layer: 2.8 x 1.5 x 2.8
     - Top layer: 1.8 x 1.2 x 1.8
     - Bottom layer: 2.5 x 1.0 x 2.5
     - Cross layer: 4.0 x 1.5 x 2.5
   - Taller trunk (4.0 units)
   - Dark oak bark color: `Color(0.45, 0.3, 0.15)`
   - Bright leaf color: `Color(0.2, 0.6, 0.2)`
   - Drops 3 wood + 3 branches

3. **Big Oak Tree** (`big_tree_resource.tscn`)
   - 2x2 trunk (1.5 x 5.0 x 1.5)
   - Larger layered canopy (5.5 main, up to 3.0 top)
   - Drops 5 wood + 5 branches
   - Requires 5 chops to harvest

4. **Birch Tree** (`birch_tree_resource.tscn`)
   - White trunk color: `Color(0.9, 0.85, 0.8)`
   - Lighter green leaves: `Color(0.35, 0.7, 0.3)`
   - Narrower trunk (0.55 x 5.0 x 0.55)
   - Drops 3 birch_wood + 2 branches
   - Medium-sized layered canopy

5. **Mixed Tree Type Spawning** (`terrain_generator.gd`)
   - 60% small oak trees
   - 30% big oak trees
   - 10% birch trees
   - Different scale variations per type:
     - Small oak: 0.7x to 1.2x (most variety)
     - Big oak: 0.9x to 1.1x (less variation)
     - Birch: 0.8x to 1.1x (uniform)

6. **Increased Forest Density**
   - Tree density increased from 0.15 to 0.25
   - Grid size reduced from 3.0 to 2.5 (tighter packing)
   - Max distance increased from 48 to 60 (larger forest)
   - Creates denser Minecraft-style forest

7. **Ground Decorations** (`terrain_generator.gd`)
   - **Tall Grass**: 250 grass tufts scattered on terrain
     - Crossed quad design (X-shape)
     - 0.25-0.4 unit height
     - Slightly darker green than terrain
   - **Red Flowers**: 35 poppies/tulips
     - Blocky stem + head design
     - Bright red `Color(0.85, 0.15, 0.15)`
   - **Yellow Flowers**: 35 dandelions
     - Same design, yellow `Color(0.95, 0.85, 0.15)`
   - Noise-based clustering for natural distribution
   - Avoids campsite center (8 unit minimum distance)

#### Tree Type Comparison

| Type | Trunk Size | Canopy Size | Wood Drop | Chops | Color |
|------|------------|-------------|-----------|-------|-------|
| Small Oak | 0.7 x 4.0 x 0.7 | 3.5 main | 3 wood | 3 | Dark brown + green |
| Big Oak | 1.5 x 5.0 x 1.5 | 5.5 main | 5 wood | 5 | Dark brown + green |
| Birch | 0.55 x 5.0 x 0.55 | 3.0 main | 3 birch_wood | 3 | White + light green |

#### Color Palette Update

| Element | Old Color | New Color |
|---------|-----------|-----------|
| Grass (top) | (0.45, 0.62, 0.35) | (0.48, 0.75, 0.35) |
| Dirt (sides) | N/A | (0.55, 0.35, 0.2) |
| Oak trunk | (0.55, 0.4, 0.3) | (0.45, 0.3, 0.15) |
| Oak leaves | (0.25, 0.55, 0.25) | (0.2, 0.6, 0.2) |
| Birch trunk | N/A | (0.9, 0.85, 0.8) |
| Birch leaves | N/A | (0.35, 0.7, 0.3) |

#### Technical Details

- Ground decorations use SurfaceTool for procedural mesh generation
- Grass tufts are crossed quads (no collision, visual only)
- Flowers use BoxMesh for blocky Minecraft look
- All decorations inherit terrain height
- Tree type logging shows spawn counts for debugging

---

## Session 10b - Terrain Polish & Natural Pond (2026-01-31)

### What Was Built

**Minecraft-accurate terrain colors, grass sod edges, and natural pond integration**

#### Files Modified

```
scripts/world/terrain_generator.gd    # Grass sod edges, color refinement, pond depression
scenes/main.tscn                      # Removed hardcoded fishing spots
```

#### Features Implemented

1. **Grass "Sod" Edges on Cliff Faces**
   - Side faces now show green grass strip at top (0.25 units thick)
   - Brown dirt below the grass strip
   - Creates authentic Minecraft grass block appearance
   - Short step-downs show all grass (no dirt visible)

2. **Minecraft-Accurate Colors**
   - Grass: `Color(0.30, 0.50, 0.22)` - true forest green
   - Dirt: `Color(0.52, 0.36, 0.22)` - rich brown
   - Added per-cell color variation for texture-like appearance
   - Removed washed-out pale colors

3. **Natural Pond with Terrain Depression**
   - Single large pond (10x8 units) instead of 3 small ones
   - Bowl-shaped terrain depression at pond location
   - Pond position: (15, 12) - just outside campsite
   - Depression radius: 8 units, depth: 1.5 units
   - Flat bottom with sloping edges like natural water collection
   - 5 fish in larger pond

4. **Spawn Exclusion Zones**
   - Trees avoid pond area with 2-unit margin
   - Ground decorations (grass, flowers) avoid pond area
   - Prevents objects spawning in/over water

5. **Terrain Configuration Updates**
   - Height step increased to 1.0 for more visible terraces
   - Campsite flatten radius reduced to 6.0 for more terrain variety
   - Smaller flat area shows terrain earlier around spawn

#### Color Comparison

| Element | Before | After |
|---------|--------|-------|
| Grass top | Pale mint green | Forest green (0.30, 0.50, 0.22) |
| Dirt sides | Light tan/beige | Rich brown (0.52, 0.36, 0.22) |
| Side edges | All dirt | Green sod strip + dirt below |

#### Technical Details

- Side quads split into two parts when taller than grass_thickness
- Per-cell color variation uses sin() for pseudo-random consistency
- Pond spawned by terrain generator (not hardcoded in scene)
- Terrain height returns negative values in pond depression

---

## Session 11 - Dynamic Chunk-Based Terrain System (2026-01-31)

### What Was Built

**Infinite World Generation** - Minecraft-style dynamic chunk loading/unloading as player explores

#### New Files Created

```
scripts/world/terrain_chunk.gd     # Individual chunk: terrain mesh, collision, trees, decorations
scripts/world/chunk_manager.gd     # Manages chunk loading/unloading around player
```

#### Files Modified

```
scenes/world/world.tscn            # Switched from terrain_generator.gd to chunk_manager.gd
```

#### Features Implemented

1. **TerrainChunk Class** (`scripts/world/terrain_chunk.gd`)
   - Self-contained chunk that generates:
     - Blocky terrain mesh with grass tops and dirt sides
     - Grass "sod" edges on cliff faces
     - HeightMapShape3D collision
     - Trees (small oak 60%, big oak 30%, birch 10%)
     - Ground decorations (grass tufts, red/yellow flowers)
   - Deterministic generation using chunk coordinates as seed
   - Consistent results regardless of load order
   - Clean `unload()` method for memory management

2. **ChunkManager Class** (`scripts/world/chunk_manager.gd`)
   - Tracks player position and determines which chunks to load
   - Configurable render distance (default: 3 chunks in each direction)
   - Chunk queue system for progressive loading:
     - Unloads distant chunks first (frees memory)
     - Loads nearest chunks first (player-centric)
     - Rate-limited to prevent frame drops (1 chunk/frame default)
   - Maintains shared resources:
     - Single terrain material for all chunks
     - Noise generators (terrain + forest density)
     - Tree scene references
   - Spawns fishing pond when its chunk loads

3. **Seamless Chunk Borders**
   - Side faces use `get_height_at()` which works for any world coordinate
   - Neighbor heights queried across chunk boundaries
   - No visible seams between chunks
   - Consistent height generation via shared noise

4. **Per-Chunk Resource Generation**
   - Trees use deterministic RNG seeded by chunk coordinates
   - Same chunk always generates same trees
   - Forest density noise creates natural clustering
   - Decorations distributed proportionally to chunk area
   - Respects exclusion zones (campsite, pond)

5. **World Scene Update** (`scenes/world/world.tscn`)
   - Replaced `terrain_generator.gd` with `chunk_manager.gd`
   - Configurable exports for chunk size, render distance, terrain parameters

#### Chunk System Architecture

```
ChunkManager (Node3D)
├── Manages loaded_chunks: Dictionary[Vector2i, TerrainChunk]
├── Monitors player position in _process()
├── Queues chunks_to_load and chunks_to_unload
└── Spawns fishing spot when pond chunk loads

TerrainChunk (Node3D)
├── terrain_mesh (MeshInstance3D) - Blocky terrain
├── terrain_collision (StaticBody3D) - HeightMapShape3D
├── trees_container (Node3D) - Procedural trees
└── decorations_container (Node3D) - Grass, flowers
```

#### Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| chunk_size_cells | 16 | Cells per chunk side (16x16 = 256 cells) |
| render_distance | 3 | Chunks loaded in each direction |
| chunks_per_frame | 1 | Rate limiting for smooth loading |
| cell_size | 3.0 | World units per cell |

#### Chunk Size Calculation

- Chunk world size: `chunk_size_cells × cell_size = 16 × 3 = 48 units`
- With render_distance 3: loads 7×7 = 49 chunks (336×336 units visible)
- Total initial terrain: ~112,896 square units

#### Memory Management

- Chunks beyond render_distance are unloaded
- Each chunk cleans up:
  - Terrain mesh and material
  - Collision shape
  - All spawned trees
  - All decorations
- Dictionary tracking prevents double-loading

#### Preserved Features

- Flat campsite area at origin (6 unit radius)
- Natural pond with depression at (15, 12)
- Original terrain colors (Minecraft forest green/dirt brown)
- Tree type distribution and clustering
- Ground decoration noise-based placement

---

## Session 12 - Coordinates Display (2026-01-31)

### What Was Built

**Player Coordinates HUD Display** - Shows player position on screen with configurable toggle

#### Files Modified

```
scenes/ui/hud.tscn              # Added CoordinatesLabel node
scripts/ui/hud.gd               # Added coordinates display logic and show_coordinates property
scenes/ui/config_menu.tscn      # Added ShowCoordinatesToggle checkbox
scripts/ui/config_menu.gd       # Added show_coordinates config option and HUD reference
scenes/main.tscn                # Added hud_path to ConfigMenu
```

#### Features Implemented

1. **Coordinates Display** (`hud.gd` + `hud.tscn`)
   - Shows player X, Y, Z position in top-left area (below stats)
   - Format: "X: 0.0  Y: 0.0  Z: 0.0" with one decimal place
   - Semi-transparent grey text with shadow for readability
   - Updates every frame in `_process()`
   - Respects `show_coordinates` property for visibility

2. **Config Menu Toggle** (`config_menu.gd` + `config_menu.tscn`)
   - New toggle: "Show Coordinates" in config menu (Tab)
   - Default: On (enabled by default for debugging)
   - Applies setting to HUD via `hud_path` reference
   - Saved in config dictionary for potential future persistence

#### Config Menu Options (Updated)

| Setting | Description | Default |
|---------|-------------|---------|
| Show Coordinates | Display player X/Y/Z position on HUD | On |
| ... (other existing options) | | |

#### Technical Details

- Coordinates update in `_process()` for real-time tracking
- HUD referenced by ConfigMenu via `@export var hud_path: NodePath`
- Visibility controlled by `show_coordinates: bool` property on HUD
- Position displayed with one decimal precision (%.1f format)

---

## Session 13 - Tree Spawn Position Fix (2026-01-31)

### What Was Built

**Bug Fix: Trees spawning inside terrain blocks** - Fixed height calculation to match terrain mesh

#### Files Modified

```
scripts/world/terrain_generator.gd    # Fixed _get_blocky_height() noise sampling
scripts/world/chunk_manager.gd        # Fixed get_height_at() noise sampling
```

#### Issue Description

Trees (and other objects) were sometimes spawning partially buried inside terrain blocks. The trunk would appear to be stuck in the ground rather than sitting on top of it.

#### Root Cause

The terrain mesh is built by sampling height at the **center** of each cell:
```gdscript
var center_x: float = world_x + cell_size / 2.0
var center_z: float = world_z + cell_size / 2.0
var height: float = _get_blocky_height(center_x, center_z)
```

But when spawning trees, `_get_blocky_height(tree_x, tree_z)` sampled at the **exact tree position**. Since the noise values vary slightly within a cell and get `floor()`'d to quantized heights, two points in the same cell could produce different heights:

- Terrain at cell center (10.5, 6.0) → noise 0.34 → floor(2.01) = **2.0**
- Tree at (10.2, 5.7) → noise 0.32 → floor(1.92) = **1.0**

This caused trees to spawn at Y=1.0 while the terrain surface was at Y=2.0, burying the tree trunk.

#### Fix Applied

Modified both `_get_blocky_height()` (terrain_generator.gd) and `get_height_at()` (chunk_manager.gd) to snap coordinates to cell centers before sampling noise:

```gdscript
# Snap to cell center for consistent height across each cell
# This ensures objects spawn at the same height as the terrain mesh
var snapped_x: float = (floor(x / cell_size) + 0.5) * cell_size
var snapped_z: float = (floor(z / cell_size) + 0.5) * cell_size

# Base terrain height from noise (sampled at cell center)
var raw_height: float = noise.get_noise_2d(snapped_x, snapped_z)
```

This ensures that any position within a cell returns the same height as the terrain mesh at that cell, so objects always sit properly on the terrain surface.

#### Technical Details

- The snap formula `(floor(x / cell_size) + 0.5) * cell_size` works for both positive and negative coordinates
- Distance-based checks (campsite, pond) still use exact coordinates for accurate boundary detection
- Only the noise sampling is snapped, preserving special area behavior

---

## Session 14 - Berry Bush Visual Improvement (2026-01-31)

### What Was Built

**Berry Bush Visual Overhaul** - Berries now appear as green bushes with red berry dots

#### New Files Created

```
scripts/resources/berry_bush.gd      # Specialized berry behavior (berries disappear, bush stays)
scenes/resources/berry_bush.tscn     # Green bush with 7 red berry spheres
```

#### Files Modified

```
scenes/main.tscn                     # Berry nodes now use berry_bush.tscn scene
```

#### Features Implemented

1. **Berry Bush Scene** (`scenes/resources/berry_bush.tscn`)
   - Green spherical bush mesh (squashed sphere shape)
   - 7 small red berry spheres scattered on the bush surface
   - Berries positioned at varied angles for natural look
   - Collision shape for interaction

2. **Berry Bush Script** (`scripts/resources/berry_bush.gd`)
   - Extends ResourceNode with custom harvest behavior
   - When harvested:
     - Berries shrink and fade (animation)
     - Bush mesh remains visible
     - Resource becomes non-interactable
   - Respawn restores berries visibility

3. **Visual Design**
   - Bush: Dark green (0.2, 0.45, 0.15) with spherical shape
   - Berries: Bright red (0.8, 0.15, 0.15) small spheres
   - Berry size: 0.04 radius for small dot appearance
   - 7 berries distributed across bush surface

#### Berry Bush Behavior

| State | Bush | Berries | Interaction |
|-------|------|---------|-------------|
| Unharvested | Visible | Visible (7 red dots) | "Pick Berry" prompt |
| Harvesting | Visible | Shrinking animation | N/A |
| Depleted | Visible (green bush) | Hidden | No interaction |
| Respawned | Visible | Visible again | "Pick Berry" prompt |

#### Technical Details

- Berry bush uses SphereShape3D for collision (matches organic shape)
- Berries contained in "Berries" Node3D for group animation
- Tween animation shrinks berries to zero scale
- Collision disabled when depleted (removed from interactable group)
- `respawn()` override restores berries visibility and scale

---

## Session 15 - Resource Terrain Height Fix (2026-01-31)

### What Was Built

**Bug Fix: Resources spawning inside terrain** - Resources now auto-adjust Y position to sit on terrain surface

#### Files Modified

```
scripts/resources/resource_node.gd    # Added terrain height adjustment in _ready()
```

#### Issue Description

Resources like rocks and branches were sometimes spawning partially buried inside terrain blocks. The resources had hardcoded Y positions that didn't account for the dynamic chunk-based terrain.

#### Fix Applied

Added automatic terrain height adjustment to ResourceNode:

1. **New Export Variables**
   - `adjust_to_terrain: bool = true` - Enable/disable auto-positioning
   - `height_offset: float = 0.1` - Manual height offset (half object height)

2. **Auto-Detection System**
   - On `_ready()`, waits one frame for ChunkManager to initialize
   - Queries `ChunkManager.get_height_at()` for terrain height at resource's X,Z position
   - Auto-detects mesh height from MeshInstance3D child node
   - Falls back to resource_type-based defaults if no mesh found

3. **Height Offset Calculation**
   - Automatically reads mesh AABB to get actual height
   - Positions object center at `terrain_height + (mesh_height / 2)`
   - Ensures object's base sits exactly on terrain surface

#### Resource Height Offsets

| Resource | Mesh Height | Auto Offset |
|----------|-------------|-------------|
| Branch | 0.2 | 0.1 |
| Rock | 0.35 | 0.175 |
| Berry Bush | ~0.5 | ~0.25 |

#### Technical Details

- Uses recursive search to find ChunkManager in scene tree
- Works with both static scene resources and dynamically spawned ones
- Trees already spawned by chunk system have correct positioning
- `adjust_to_terrain` can be disabled for resources with manual positioning

---

## Session 16 - Tree Floating Fix (2026-01-31)

### What Was Built

**Bug Fix: Trees floating above terrain** - Fixed height calculation to use consistent snapped coordinates

#### Files Modified

```
scripts/world/chunk_manager.gd    # Fixed get_height_at() to snap coordinates first
```

#### Issue Description

Trees were sometimes floating above terrain blocks instead of being flush with the surface. This was visible throughout the forest where tree trunks hovered above the terrain.

#### Root Cause

In `get_height_at()`, coordinates were snapped to cell centers for noise sampling, but the campsite transition zone distance was calculated using the EXACT position. This meant:

- Terrain mesh at cell center (4.5, 7.5): distance 8.75, transition t=0.25
- Tree at (3.1, 6.1) snaps to same cell (4.5, 7.5) for noise, but: distance 6.84, transition t=0.0

The different `t` values caused different height multipliers for objects in the same terrain cell.

#### Fix Applied

Moved coordinate snapping to the BEGINNING of `get_height_at()`, so all calculations (distance from campsite, distance from pond, noise lookup, transition multiplier) use the same snapped cell-center coordinates:

```gdscript
func get_height_at(x: float, z: float) -> float:
    # Snap to cell center FIRST for consistent height across each cell
    var snapped_x: float = (floor(x / cell_size) + 0.5) * cell_size
    var snapped_z: float = (floor(z / cell_size) + 0.5) * cell_size

    # Use snapped coordinates for ALL distance calculations
    var distance_from_center: float = Vector2(snapped_x, snapped_z).length()
    # ... rest uses snapped_x, snapped_z throughout
```

Now any position within a cell returns exactly the same height as the terrain mesh.

---

## Session 17 - Terrain Color Improvements (2026-01-31)

### What Was Built

**Terrain Color Update** - More natural grass green and darker dirt brown

#### Files Modified

```
scripts/world/chunk_manager.gd    # Updated base grass and dirt colors
scripts/world/terrain_chunk.gd    # Updated color variation clamp ranges
```

#### Color Changes

| Element | Old Color | New Color | Description |
|---------|-----------|-----------|-------------|
| Grass | (0.30, 0.50, 0.22) | (0.28, 0.52, 0.15) | Vibrant lawn green |
| Dirt | (0.52, 0.36, 0.22) | (0.40, 0.26, 0.14) | Rich dark soil brown |

#### Clamp Range Updates

Top face grass:
- R: 0.20-0.38 (was 0.15-0.45)
- G: 0.45-0.62 (was 0.35-0.60)
- B: 0.08-0.22 (was 0.12-0.35)

Side face dirt:
- R: 0.32-0.50 (was 0.35-0.65)
- G: 0.18-0.32 (was 0.22-0.48)
- B: 0.06-0.18 (was 0.12-0.32)

#### Color Distinction from Resources

Terrain colors are distinct from:
- Herb leaves: (0.3, 0.6, 0.25) - brighter, more saturated green
- Berry bush: (0.2, 0.45, 0.15) - darker forest green

---

## Session 18 - Tree Floating Fix Part 2 (2026-01-31)

### What Was Built

**Bug Fix: Trees still floating** - Disabled terrain adjustment for trees that are already positioned by chunk system

#### Files Modified

```
scenes/resources/tree_resource.tscn      # Added adjust_to_terrain = false
scenes/resources/big_tree_resource.tscn  # Added adjust_to_terrain = false
scenes/resources/birch_tree_resource.tscn # Added adjust_to_terrain = false
```

#### Issue Description

Trees were still floating above terrain despite the earlier fix to `get_height_at()`.

#### Root Cause

When I added terrain adjustment to `resource_node.gd`, it affected ALL resources including trees. Trees are:
1. First positioned correctly by the chunk spawner using `get_height_at()`
2. Then repositioned AGAIN by `ResourceNode._ready()` terrain adjustment

This double-positioning caused trees to end up at incorrect heights.

#### Fix Applied

Set `adjust_to_terrain = false` in all three tree scene files. Trees spawned by the chunk system are already positioned at the correct terrain height and don't need additional adjustment.

Resources that DO need terrain adjustment (branches, rocks, berries in main.tscn with hardcoded positions) still have the default `adjust_to_terrain = true`.

---

## Session 19 - Random Resource Spawning (2026-01-31)

### What Was Built

**Procedural Resource Distribution** - Resources now spawn randomly throughout the terrain instead of only in the campsite area

#### New Files Created

```
scenes/resources/branch.tscn    # Branch resource scene (uses resource_node.gd)
scenes/resources/rock.tscn      # Rock resource scene (uses resource_node.gd)
```

#### Files Modified

```
scripts/world/chunk_manager.gd  # Added resource scene loading and density settings
scripts/world/terrain_chunk.gd  # Added _spawn_chunk_resources() with noise-based distribution
scenes/main.tscn                # Removed all hardcoded resources (Resources node now empty)
scenes/resources/berry_bush.tscn # Set adjust_to_terrain = false
scenes/resources/herb.tscn      # Set adjust_to_terrain = false
```

#### Features Implemented

1. **Resource Scene Files**
   - `branch.tscn`: Branch resource with BoxMesh (0.6 x 0.2 x 0.2), brown color
   - `rock.tscn`: Rock resource with BoxMesh (0.4 x 0.35 x 0.4), grey color
   - Both use existing `resource_node.gd` script
   - `adjust_to_terrain = false` (chunk system handles positioning)

2. **Chunk Manager Resource Loading** (`chunk_manager.gd`)
   - Loads 5 resource scenes: branch, rock, berry_bush, mushroom, herb
   - Configurable density settings:
     - `branch_density: float = 0.08`
     - `rock_density: float = 0.03`
     - `berry_density: float = 0.02`
     - `mushroom_density: float = 0.025`
     - `herb_density: float = 0.02`

3. **Per-Chunk Resource Spawning** (`terrain_chunk.gd`)
   - Resources spawned in `_spawn_chunk_resources()` during chunk generation
   - Noise-based clustering for natural distribution:
     - **Branches**: More common near trees (forest noise > 0.3)
     - **Rocks**: More common away from campsite (distance > 15)
     - **Berry Bushes**: More common in clearings (forest noise < -0.2)
     - **Mushrooms**: More common in forests (forest noise > 0.2)
     - **Herbs**: Scattered everywhere (no bias)
   - Grid-based spawning with density checks per cell
   - Random rotation for variety
   - Deterministic RNG seeded by chunk coordinates

4. **Removed Hardcoded Resources**
   - Deleted 30 branches from main.tscn
   - Deleted 5 rocks from main.tscn
   - Deleted 3 berry bushes from main.tscn
   - Deleted 10 mushrooms from main.tscn
   - Deleted 8 herbs from main.tscn
   - Resources node now empty (populated dynamically)

#### Resource Spawning Logic

```gdscript
func _spawn_chunk_resources() -> void:
    # Use chunk-seeded RNG for deterministic spawning
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = hash(Vector2(chunk_coord.x * 1000, chunk_coord.y))

    # Grid-based spawning
    for cell_x in range(chunk_manager.chunk_size_cells):
        for cell_z in range(chunk_manager.chunk_size_cells):
            var world_x: float = chunk_world_origin.x + cell_x * cell_size + cell_size / 2.0
            var world_z: float = chunk_world_origin.y + cell_z * cell_size + cell_size / 2.0

            # Check density and environmental factors per resource type
            # Spawn with noise-based clustering
```

#### Resource Distribution Summary

| Resource | Base Density | Preferred Location |
|----------|--------------|-------------------|
| Branch | 8% | Near trees (forested areas) |
| Rock | 3% | Away from campsite |
| Berry Bush | 2% | Clearings (low forest noise) |
| Mushroom | 2.5% | Forested areas |
| Herb | 2% | Everywhere (no bias) |

#### Technical Details

- Resources spawned per chunk, cleaned up when chunk unloads
- `spawned_resources: Array[Node3D]` tracks chunk resources for cleanup
- Resources container created per chunk: `chunk/Resources`
- Positions at terrain height using `chunk_manager.get_height_at()`
- Avoids campsite center (distance < 8 units)
- Avoids pond area (distance from pond center < pond radius + 2)

---

## Session 20 - Swimming Mechanics & Water System (2026-01-31)

### What Was Built

**Swimming System** - Player can swim in the pond with proper water physics and visuals

#### Files Modified

```
scripts/player/player_controller.gd    # Swimming mechanics, underwater effect
scripts/resources/fishing_spot.gd      # Water plane rendering, Area3D detection
scripts/world/chunk_manager.gd         # Terrain pond depression, water sizing
scripts/world/terrain_chunk.gd         # Resource spawning with pond avoidance
scripts/ui/crafting_ui.gd              # Fixed crafting bench interaction
scenes/player/player.tscn              # Updated collision layer/mask
```

#### Features Implemented

1. **Swimming Mechanics** (`player_controller.gd`)
   - Player sinks slowly in water (`swim_sink_speed = 3.0`)
   - Pressing spacebar makes player rise (`swim_rise_speed = 2.5`)
   - Slower horizontal movement while swimming (`swim_move_speed = 2.5`)
   - Jump out of water when at surface AND touching terrain edge
   - Water surface cap prevents swimming into air (except when jumping out)

2. **Underwater Visual Effect** (`player_controller.gd`)
   - Blue tint overlay when player enters water
   - CanvasLayer with ColorRect at layer 10 (above most UI)
   - Color: semi-transparent blue `(0.1, 0.3, 0.5, 0.4)`
   - Automatically shows/hides based on `is_in_water` state

3. **Water Rendering** (`fishing_spot.gd`)
   - Changed from 3D box mesh to flat plane surface
   - Eliminates visible walls clipping through terrain at edges
   - Semi-transparent blue material with both sides rendered
   - Water plane sized to fill terrain depression edge-to-edge

4. **Terrain Pond Depression** (`chunk_manager.gd`)
   - Pond floor at Y=-2.5 (deep enough for swimming)
   - Circular depression with radius 8 units
   - Gradual slope from floor to terrain edge (factor 0.7 to 1.0)
   - Water fills the depression like a natural bowl

5. **Water Detection** (`fishing_spot.gd`)
   - Area3D covers full water volume (3.0 units deep)
   - Detects player entering/exiting water via body_entered/body_exited signals
   - Calls `player.set_in_water(true/false)` to toggle swimming mode

6. **Resource Pond Avoidance** (`terrain_chunk.gd`)
   - Resources check distance from pond AFTER jitter is applied
   - Prevents branches, rocks, mushrooms from spawning in water
   - Buffer zone of 2 units around pond edge

7. **Crafting Bench Fix** (`crafting_ui.gd`)
   - Added `toggle_crafting_menu()` public method
   - Added CraftingUI to "crafting_ui" group for bench to find it
   - Crafting bench E key interaction now works properly

8. **Fishing Interaction Fix** (`fishing_spot.gd`)
   - Collision shape covers entire water surface
   - Player can fish from any edge of the pond
   - Interaction raycast detects water from all angles

#### Swimming Controls

| Action | Key | Effect |
|--------|-----|--------|
| Sink | Automatic | Player slowly sinks in water |
| Swim Up | Space (hold) | Rise toward surface |
| Jump Out | Space (at edge) | Jump onto terrain |
| Move | WASD | Slower movement in water |

#### Swimming Configuration

| Setting | Value | Description |
|---------|-------|-------------|
| swim_sink_speed | 3.0 | How fast player sinks |
| swim_rise_speed | 2.5 | How fast player rises with space |
| swim_move_speed | 2.5 | Horizontal movement speed |
| water_surface_y | 0.15 | Y position of water surface |
| pond_floor_y | -2.5 | Y position of pond bottom |

#### Technical Details

- Swimming detected via Area3D overlap, not collision
- Player collision layer 1, mask 1 (doesn't collide with water layer 2)
- Interaction raycast mask 3 (detects both layer 1 and 2)
- Terrain provides floor collision at pond bottom
- Jump-out requires `is_on_wall()` to prevent mid-pond jumping

---

## Next Session: Phase 8 - Polish & Content (Continued)

### Completed Features
- ✅ Tool durability system with HUD display
- ✅ Fishing system with multi-step mechanic
- ✅ Mushrooms and herbs as new resources
- ✅ Crafting bench placeable structure
- ✅ Healing salve instant heal item
- ✅ New recipes (fishing rod, healing salve, crafting bench)
- ✅ Weather particle effects (rain, storm, snow, dust)
- ✅ Night sky with stars and moon
- ✅ Improved fishing ponds with organic shape
- ✅ Visible swimming fish in ponds
- ✅ First-person fishing rod model
- ✅ Caught fish animation
- ✅ Blocky Minecraft-style aesthetic (all meshes)
- ✅ Background music system with 12 tracks

### Planned Tasks
1. Sound effects (footsteps, interactions, ambient)
2. Additional structures (cooking grate, water collector)
3. Level 3 campsite content
4. Game balancing and polish
5. Pixelated textures (optional enhancement)

### Reference
See `into-the-wild-game-spec.md` for full game specification.
