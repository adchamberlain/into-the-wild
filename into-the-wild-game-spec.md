# Into the Wild — Complete Game Specification

## Overview

**Into the Wild** is a solo camping adventure game where you explore the wilderness, gather resources, solve environmental challenges, and build up your campsite from a bare patch of ground into a thriving wilderness basecamp.

**Visual Style:** Blocky and retro, reminiscent of early 3D games like Minecraft.

**Target Platform:** macOS (with potential for Windows/Linux export later)

**Distribution:** Personal use and sharing with friends

---

## Core Gameplay

### The Gather → Build → Unlock Loop

Players spend their time exploring the wilderness around their campsite, collecting resources, and bringing them back to craft improvements. As the campsite levels up, new tools become available that let you access previously unreachable resources and areas, which feeds back into further upgrades.

### Resource Types

| Category | Examples | Used For |
|----------|----------|----------|
| **Wood** | Branches, logs, hardwood, birch bark | Shelters, fire, tools, furniture |
| **Stone** | River rocks, flint, slate, ore | Fire rings, tools, construction |
| **Plant** | Berries, herbs, mushrooms, pine resin, wild vegetables | Food, medicine, crafting |
| **Water** | Stream water, spring water, rainwater | Drinking, cooking, cleaning |
| **Animal** | Fish, feathers, pelts (from traps) | Food, clothing, gear |
| **Salvage** | Rope, old canvas, rusted metal, glass | Repairs, advanced crafting |

Resources have quality tiers (common → uncommon → rare) that affect what you can craft.

---

## Survival Meters

### Health

- Depletes from environmental hazards: falling from heights, exposure to extreme weather (storms without shelter, cold snaps without fire), and wildlife encounters
- Regenerates slowly when hunger bar is full
- If it hits zero, player passes out and wakes up back at camp having lost some carried resources

### Hunger

- Depletes steadily over time, slightly faster when doing physical activities (chopping, building)
- Eating food refills it
- When hunger drops to zero, health starts draining (can't die directly from hunger, but becomes vulnerable)

### Food Progression

| Food Type | Hunger Restored |
|-----------|-----------------|
| Raw berries/plants | Low |
| Raw fish/meat | Medium |
| Dried/preserved food | Medium |
| Cooked meals | High |

No sickness mechanics, no risk from eating raw food—it just restores less hunger.

### How Survival Ties Into Gameplay

- Better shelter protects health during storms
- Fire and cooking stations let you get more value from food
- Food preservation means you can explore longer without rushing back
- Reaching Level 3 with full cooking recipes makes survival easier, rewarding progression

---

## Campsite Progression

### Level 1 — Bare Bones
*Starting point. Survival basics only.*

- Ground tarp or improvised shelter
- Simple fire pit (requires constant tending)
- Stick fishing
- Foraged food only (no cooking)
- One small storage container
- Basic hand tools (rock hammer, sharpened stick)

**To unlock Level 2:** Build a proper shelter, establish a reliable fire source, and craft your first real tool.

### Level 2 — Functional Camp
*You've got the basics down. Time to get comfortable.*

- Canvas tent or lean-to with rain protection
- Stone fire ring with cooking grate
- Crafting bench for tools and gear
- Fishing rod, snare traps
- Food drying rack and storage
- Herb garden plot
- Workbench for repairs
- Expanded inventory/storage

**To unlock Level 3:** Craft advanced tools, establish food sustainability (garden + preserved food stores), and complete a major construction project.

### Level 3 — Wilderness Basecamp
*A true home in the wild.*

- Log cabin or large permanent shelter
- Full cooking station with recipes
- Advanced crafting stations (smithing, tanning, carpentry)
- Multiple garden plots
- Smoker for long-term food preservation
- Weather vane and basic forecasting
- Observation deck or lookout point
- Trophy/collection display for rare finds
- Map table showing full exploration progress

---

## Exploration & The World

### Map Structure

The world is divided into zones radiating out from your campsite:

1. **Immediate Surroundings** — Safe, basic resources, always accessible
2. **Near Wilderness** — Moderate challenge, better resources, requires basic tools
3. **Deep Wilderness** — Difficult terrain, rare resources, requires advanced gear
4. **Hidden Areas** — Caves, mountain peaks, secret groves. Require solving environmental puzzles to access.

### Environmental Puzzles

Natural obstacles requiring creative problem-solving:

- A river too wide to cross → build a raft or find materials for a rope bridge
- A cliff face with rare minerals → craft climbing gear
- A flooded cave → wait for dry weather or build a drainage channel
- Dense thorns blocking a path → craft a machete or find another route
- A bear's territory → craft noise makers to scare it off, or find bait to lure it elsewhere

---

## Day/Night & Weather Systems

### Time of Day

Each game day cycles through morning, afternoon, evening, and night. Different times affect:

- **Resource availability** — Some fish bite at dawn, some mushrooms only appear at night
- **Visibility** — Night exploration requires torches or lanterns
- **Wildlife behavior** — Different animals active at different times

### Weather

Weather changes dynamically and affects gameplay:

| Weather | Effects |
|---------|---------|
| **Clear** | Normal gameplay, good visibility |
| **Rain** | Fire harder to maintain, fishing improved, some paths become muddy/impassable |
| **Storm** | Must seek shelter or take health damage, risk of damage to campsite if not secured |
| **Fog** | Reduced visibility, easier to get lost, some rare resources appear |
| **Heat wave** | Hunger depletes faster |
| **Cold snap** | Must stay near fire or take health damage, water sources may freeze (ice fishing unlocked) |

Players can eventually build a weather vane to get short-term forecasts and plan accordingly.

---

## Crafting System

### Discovery-Based

- Players discover recipes through experimentation rather than having a full recipe book
- Combining resources at a crafting station shows possible outcomes based on what you're holding
- Once discovered, recipes are saved to a journal for reference

### Tool Progression

Tools wear out with use and need repair or replacement. Better materials = more durable tools.

**Example progression for axes:**
- Sharpened stone (breaks quickly, slow)
- Stone axe with wood handle (moderate durability)
- Metal axe head with hardwood handle (durable, fast)

---

## Win Condition / Endgame

No traditional "ending." The goal is to reach Level 3 campsite and fully explore the map. Completionists can aim to:

- Discover all crafting recipes
- Find all hidden areas
- Collect rare variants of every resource
- Build every possible campsite upgrade

A simple achievement/milestone system tracks progress and gives players goals.

---

## What's NOT in the MVP

Explicitly out of scope for version 1:

- NPCs or other characters
- Multiplayer
- Combat system
- Story or narrative quests
- Character customization beyond basic gear

---

# Technical Architecture

## Recommended Stack

**Engine:** Godot 4.3 (latest stable)

**Language:** GDScript (Python-like syntax, built into Godot)

**Why Godot:**
- GDScript is syntactically very similar to Python (indentation-based, dynamic typing)
- Professional-grade engine that scales to commercial releases
- Handles 3D blocky/voxel aesthetics well
- Free, open source, no licensing fees or royalties
- Runs great on macOS, easy to export Mac builds
- Lightweight and solo-dev friendly

## Project Structure

```
into-the-wild/
├── project.godot              # Project configuration
├── assets/
│   ├── models/                # 3D models (.glb or .obj)
│   ├── textures/              # Blocky pixel textures
│   ├── audio/                 # Sound effects, ambient loops
│   └── ui/                    # UI sprites and fonts
├── scenes/
│   ├── main.tscn              # Main game scene
│   ├── player/
│   │   └── player.tscn        # Player character + camera
│   ├── world/
│   │   ├── world.tscn         # World container
│   │   ├── zones/             # Different exploration zones
│   │   └── terrain/           # Terrain chunks
│   ├── campsite/
│   │   ├── campsite.tscn      # Base campsite scene
│   │   └── structures/        # Buildable structures
│   ├── resources/
│   │   └── resource_node.tscn # Harvestable resource template
│   └── ui/
│       ├── hud.tscn           # Health, hunger bars
│       ├── inventory.tscn     # Inventory screen
│       └── crafting.tscn      # Crafting interface
├── scripts/
│   ├── player/
│   │   ├── player_controller.gd
│   │   ├── player_stats.gd    # Health, hunger logic
│   │   └── inventory.gd
│   ├── world/
│   │   ├── time_manager.gd    # Day/night cycle
│   │   ├── weather_manager.gd
│   │   └── zone_manager.gd
│   ├── campsite/
│   │   ├── campsite_manager.gd
│   │   ├── structure.gd       # Base class for buildings
│   │   └── campsite_level.gd  # Progression logic
│   ├── resources/
│   │   ├── resource_node.gd
│   │   └── resource_types.gd
│   ├── crafting/
│   │   ├── crafting_system.gd
│   │   └── recipe_database.gd
│   └── core/
│       ├── game_manager.gd    # Global game state
│       └── save_load.gd       # Save/load functionality
└── data/
    ├── resources.json         # Resource definitions
    ├── recipes.json           # Crafting recipes
    └── structures.json        # Building definitions
```

## Core Systems

### 1. Player System
- First-person camera (recommended for immersion)
- Movement, jumping, basic interaction (press E to gather, open containers, etc.)
- Inventory management
- Stats tracking (health, hunger)

### 2. World System
- Terrain divided into chunks for performance
- Zone system tracking player location
- Resource nodes that spawn, get harvested, and respawn over time
- Environmental hazards tied to zones

### 3. Time & Weather
- Global clock that ticks forward (configurable speed)
- Weather state machine (clear → cloudy → rain → storm, etc.)
- Events that fire on time/weather changes (notify other systems)

### 4. Campsite System
- Grid-based placement system for structures
- Structure states (under construction → built → damaged → repaired)
- Level tracking and upgrade requirements
- Interaction points (fire pit for cooking, crafting bench for crafting, etc.)

### 5. Crafting System
- Recipe database loaded from JSON
- Discovery tracking (what has the player found?)
- Input validation (do you have the materials?)
- Output generation (create the item, deduct materials)

### 6. Persistence
- Save game state to JSON file
- Load on startup
- Auto-save periodically

---

## MVP Build Order

### Phase 1 — Walking Around
- Basic terrain (flat ground with some hills)
- Player movement and camera
- Day/night cycle with lighting changes

### Phase 2 — Gathering
- Resource nodes in the world
- Player can interact to gather
- Basic inventory (just a list for now)

### Phase 3 — Survival Meters
- Health and hunger bars on screen
- Hunger depletes over time
- Health drains when hunger is zero
- Eating food restores hunger

### Phase 4 — Crafting
- Crafting interface
- A handful of starter recipes
- Discovery system

### Phase 5 — Campsite Building
- Placement system for structures
- First few buildable items (fire pit, basic shelter, storage)
- Campsite level 1 → 2 progression

### Phase 6 — Weather & Environment
- Weather system
- Weather effects on gameplay (health damage in storms, etc.)
- Shelter protects from weather

### Phase 7 — Polish & Expand
- More resources, recipes, structures
- Level 3 campsite content
- Save/load system
- Sound and visual polish

---

## Getting Started

1. Download Godot 4.3 from godotengine.org (standard version, not .NET)
2. Work through the "Your first 3D game" tutorial in official docs
3. Start Phase 1 with simple terrain and player controller

---

## Developer Background

- Strong Python experience
- Some JavaScript experience
- First game development project
- Goal: Build solid foundation that can scale into full game
