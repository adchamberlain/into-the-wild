# Into the Wild

> **Website:** [intothewild.dev](https://intothewild.dev/) | **Found a bug or have feedback?** [Report it here](https://github.com/adchamberlain/into-the-wild/issues/new/choose)

A solo camping adventure game built in Godot 4.5. Explore an infinite procedural wilderness, gather resources, craft tools, build your campsite, and uncover hidden secrets deep in the desert.

**Visual Style:** Blocky, retro aesthetic reminiscent of early 3D games like Minecraft. All visuals are procedurally generated using layered BoxMesh primitives — no imported 3D models.

## Features

### Infinite Procedural World
- **Chunk-based terrain** - Endless exploration with procedurally generated landscapes
- **Five distinct biomes** - Forest (dense trees, player spawn), Meadow (gentle rolling hills), Hills (dramatic terrain with climbing paths), Rocky (jagged cliffs with caves), Mountain (alpine peaks with ponderosa pines)
- **Desert biome** - Organic-shaped desert region with cacti, palm trees, sandstorms, and 1.5x hunger drain
- **Desert oases** - 3 palm oases with swimmable pools containing underwater diamond and opal gem deposits
- **Desert sinkhole** - A hidden deep pit containing a submerged Explorer's Journal that unlocks late-game content
- **Natural water features** - Ponds, lakes, alpine lakes, rivers, and desert oases for swimming and fishing
- **Cave system** - Underground caves in rocky regions with crystal nodes, rare ore, stalactites, and darkness mechanics (torch required)
- **Ambient wildlife** - Rabbits and birds (huntable with bow or snare traps), desert lizards and tortoises
- **Auto step-up** - Minecraft-style automatic climbing over 1-block terrain steps
- **Loading screen** - Cycling camping artwork while the world generates

### Survival Systems
- **Health & Hunger** - Manage vital stats; hunger depletion accelerates when sprinting
- **Fall Damage** - Falls beyond 4 units deal escalating damage (8 HP per unit, max 80 HP)
- **Death & Respawn** - Respawn at your latest shelter with 50% health/hunger, inventory intact
- **Weather System** - Dynamic weather including rain, storms, fog, heat waves, cold snaps, and desert sandstorms with GPU-accelerated particle effects
- **Day/Night Cycle** - Configurable day length with dynamic sky, stars, and moon
- **Swimming & Diving** - Explore underwater with breath mechanics and air bubble display
- **Cave Darkness** - Caves are pitch dark; staying too long without a torch deals damage
- **Cactus Hazards** - Prickly cacti deal contact damage; fruit-bearing cacti can be harvested
- **Save System** - 3 save slots with camp level and timestamp display

### Exploration & Discovery
- **Bow & Arrow** - Craft bows and arrows to hunt wildlife; physics-based arrow projectiles with gravity arc
- **Enchanted Bow** - Upgraded bow crafted with opals, with larger hit radius and visual opal inlay
- **Diamond Arrows** - Premium ammunition crafted from diamonds
- **Grappling Hook** - Fire at cliff faces to ascend vertical terrain with parabolic arc traversal
- **Hang Glider** - Soar above the wilderness after unlocking via the Explorer's Journal
- **Compass & Lodestone** - Craft from rare ore; place the lodestone anywhere and the HUD compass points back to it with distance
- **Birch Bark Map** - Fullscreen wilderness map showing terrain regions, water bodies, caves, campsite, and player position
- **Explorer's Journal** - A hidden ancient book in the desert sinkhole that grants stat boosts, reveals hidden locations on the compass, and unlocks the hang glider recipe
- **Coca Leaf** - Rare consumable found near the sinkhole that doubles breath capacity for 5 minutes, with HUD countdown timer
- **Tool Upgrades** - Craft leather wraps from hide to multiply axe, grappling hook, and bow durability (with visible wrap on the tool model)

### Gathering & Crafting
- **Resource Gathering** - Collect branches, rocks, berries, mushrooms, herbs, wood, cactus fruit, and osha root
- **Tree Chopping** - Use axes to chop trees with first-person swing animation; tool tier affects chop speed
- **Birch Bark Harvesting** - Use the machete on birch trees to harvest bark (3-day regrowth cooldown)
- **Fishing** - Multi-step fishing mechanic at pond, lake, and river fishing spots
- **Gem Mining** - Dive underwater in desert oases to mine diamond and opal deposits
- **Cave Mining** - Harvest crystal nodes and rare ore from underground caves
- **Ore Smelting** - Smelt iron ore into metal ingots at the smithing station
- **Tiered Crafting** - Basic recipes by hand, advanced recipes at crafting bench, gourmet meals at the cabin kitchen

### Campsite Progression

Build up your camp through three levels:

| Level | Name | Requirements |
|-------|------|--------------|
| 1 | Survival Camp | Starting level |
| 2 | Functional Camp | Fire pit + Shelter + Crafting bench + Drying rack + Fishing rod |
| 3 | Wilderness Basecamp | 6 structures + 3 days at Level 2 + Explorer's Journal |

### Structures

| Structure | Description |
|-----------|-------------|
| Fire Pit | Warmth, light, cooking raw food. Add wood for fuel. |
| Shelter | Weather protection, rest to restore health and sleep to dawn |
| Storage Box | 20-slot container for extra items |
| Crafting Bench | Access advanced crafting recipes |
| Drying Rack | Dry fish, berries, mushrooms, and herbs for preservation |
| Herb Garden | Passive herb production with 8 herb varieties |
| Canvas Tent | Better weather protection with larger radius |
| Snare Trap | Bait with food to catch rabbits (70%) and birds (30%) |
| Smithing Station | Smelt iron ore into metal ingots |
| Smoker | Smoke meat and fish for premium food preservation |
| Weather Vane | Shows current weather and forecast |
| Log Cabin | Walkable interior with bed (full restore) and kitchen (5 gourmet recipes) |
| Placed Torch | Instant light source, placeable and retrievable |
| Lodestone | Navigation beacon — compass points back to it from anywhere |

### Tools & Equipment

| Item | Description |
|------|-------------|
| Primitive Axe | Basic tree chopping (50 durability) |
| Stone Axe | Standard tree chopping (150 durability) |
| Metal Axe | Fast tree chopping (300 durability) |
| Diamond Axe | Instant tree chopping (infinite durability) |
| Machete | Harvest birch bark (200 durability) |
| Fishing Rod | Catch fish at fishing spots (50 durability) |
| Grappling Hook | Ascend cliff faces (100 durability) |
| Bow | Hunt wildlife with arrows (200 durability, hold right-click to draw) |
| Enchanted Bow | Upgraded bow with opal inlay and larger hit radius (200 durability) |
| Torch | Portable light source (required for caves) |
| Lantern | Bright light source, 2x torch range |
| Compass | Shows direction and distance to lodestone on HUD |
| Lodestone | Placeable navigation beacon |
| Birch Bark Map | Fullscreen wilderness map |
| Hang Glider | Soar through the air (unlocked via Explorer's Journal) |

## Controls

### Keyboard & Mouse

#### Movement
- **WASD** - Move
- **Mouse** - Look around
- **Space** - Jump / Swim up
- **Shift** - Sprint
- **C** - Crouch (prevents falling off edges)

#### Interaction
- **E** - Interact with objects
- **F** - Eat food / Use healing items
- **R** - Use equipped tool / Place structure
- **Right-click (hold)** - Draw bow (when equipped), release to fire
- **Q** - Unequip current item
- **M** - Move placed structure
- **1-9, 0, -, =, [, ], \\** - Quick equip items

#### Menus
- **X** - Crafting menu
- **I** - Equipment menu
- **V** - Toggle inventory panel (HUD overlay)
- **Tab** - Config menu (save/load via K/L within this menu)
- **Escape** - Pause menu

### PlayStation DualSense Controller

Full controller support with PlayStation button prompts.

#### Movement
- **Left Stick** - Move
- **Right Stick** - Look around
- **Cross** - Jump / Swim up
- **L3 (Left Stick Click)** - Sprint

#### Interaction
- **Square** - Interact with objects
- **Triangle** - Eat food / Use healing items
- **R2** - Use equipped tool / Place structure
- **Circle** - Unequip current item
- **L1/R1** - Cycle through equipment slots
- **D-Pad Up** - Move placed structure

#### Menus
- **Touchpad** - Crafting menu
- **Create** - Equipment menu
- **D-Pad Left** - Toggle inventory panel
- **Options** - Pause menu

## Crafting Recipes

### Basic Recipes (Hand Crafting)

| Recipe | Ingredients |
|--------|-------------|
| Primitive Axe | 1 River Rock + 1 Branch |
| Stone Axe | 2 River Rock + 1 Branch |
| Torch | 2 Branch |
| Rope | 3 Branch |
| Split Branches | 1 Wood (yields 4 Branch) |
| Campfire Kit | 4 Branch + 3 River Rock |
| Crafting Bench Kit | 6 Wood + 4 Branch |

### Workbench Recipes

| Recipe | Ingredients | Camp Level |
|--------|-------------|------------|
| Shelter Kit | 6 Branch + 2 Rope | 1 |
| Storage Box | 4 Wood + 1 Rope | 1 |
| Fishing Rod | 3 Branch + 1 Rope | 1 |
| Healing Salve | 3 Herb | 1 |
| Berry Pouch | 5 Berry | 1 |
| Drying Rack Kit | 6 Branch + 2 Rope | 1 |
| Garden Plot Kit | 4 Wood + 2 Herb | 2 |
| Canvas Tent Kit | 8 Branch + 4 Rope + 4 Wood | 2 |
| Snare Trap Kit | 2 Rope + 4 Branch | 2 |
| Machete | 2 Metal Ingot + 1 Branch | 2 |
| Grappling Hook | 3 Rope + 2 Metal Ingot + 1 Branch | 2 |
| Bow | 2 Rope + 3 Branch | 2 |
| Arrow Bundle (x20) | 2 Feathers + 4 Branch | 2 |
| Leather Axe Wrap | 2 Hide + 1 Rope | 2 |
| Leather Hook Wrap | 3 Hide + 1 Rope | 2 |
| Leather Bow Wrap | 2 Hide + 1 Rope | 2 |
| Map | 3 Birch Bark + 2 Berry | 2 |
| Smithing Station Kit | 15 River Rock + 8 Wood + 2 Rope | 3 |
| Smoker Kit | 10 Wood + 6 River Rock + 2 Rope | 3 |
| Weather Vane Kit | 6 Branch + 1 Metal Ingot | 3 |
| Metal Axe | 2 Metal Ingot + 2 Branch | 3 |
| Diamond Axe | 2 Diamond + 1 Metal Ingot + 1 Rope | 3 |
| Cabin Kit | 30 Wood + 20 Branch + 10 River Rock + 6 Rope | 3 |
| Lantern | 2 Metal Ingot + 1 Crystal | 3 |
| Compass & Lodestone | 2 Rare Ore + 1 Metal Ingot + 1 Crystal | 3 |
| Enchanted Bow | 2 Opal + 1 Bow + 1 Rope | 3 |
| Diamond Arrows (x10) | 1 Diamond + 5 Branch + 2 Feathers | 3 |
| Hang Glider | 4 Rope + 6 Branch + 2 Hide | 3 (requires Journal) |

## Food & Cooking

### Raw Food

| Food | Hunger | Notes |
|------|--------|-------|
| Berry | +15 | Foraged from bushes |
| Cactus Fruit | +15 | Harvested from fruit cacti |
| Mushroom | +10 | Foraged |
| Herb | +5 | Foraged or grown in garden |
| Fish | +25 | Caught with fishing rod |
| Raw Meat | +20 | From snare traps or hunting |
| Osha Root | +20, +25 HP | Alpine medicinal plant |
| Coca Leaf | +5 | Doubles breath time for 5 minutes |
| Berry Pouch | +40 | Crafted from 5 berries |
| Healing Salve | +30 HP | Crafted from 3 herbs |

### Fire Pit Cooking

| Raw | Cooked | Hunger |
|-----|--------|--------|
| Berry | Cooked Berries | +25 |
| Mushroom | Cooked Mushroom | +20 |
| Fish | Cooked Fish | +40 |
| Raw Meat | Cooked Meat | +35 |

### Drying Rack

| Raw | Dried | Hunger |
|-----|-------|--------|
| Fish | Dried Fish | +30 |
| Berry | Dried Berries | +20 |
| Mushroom | Dried Mushroom | +15 |
| Herb | Dried Herb | +8 |

### Smoker

| Raw | Smoked | Hunger |
|-----|--------|--------|
| Raw Meat | Smoked Meat | +45 |
| Fish | Smoked Fish | +50 |

### Kitchen (Log Cabin)

| Meal | Ingredients | Hunger | Health |
|------|-------------|--------|--------|
| Hearty Stew | 2 Fish + 1 Herb + 1 Mushroom | +100 | +20 |
| Preserved Meal | 2 Dried Fish + 1 Dried Berries | +80 | — |
| Mushroom Soup | 2 Mushroom + 1 Herb | +50 | +10 |
| Cooked Fish | 1 Fish | +40 | — |
| Herb Tea | 2 Herb | +10 | +30 |

## Weather Effects

| Weather | Effect | Protection |
|---------|--------|------------|
| Storm | 2 HP/sec damage | Shelter |
| Cold Snap | 1.5 HP/sec damage | Fire warmth |
| Heat Wave | 2x hunger depletion | Eat more |
| Rain | Reduces fire effectiveness | None needed |
| Fog | Reduced visibility | None needed |
| Sandstorm | Reduced visibility + 1 HP/sec | Shelter |

## Audio

- 12 ambient music tracks with shuffle playback and crossfade transitions
- "Sunlight Through Leaves" always plays first on game start
- Configurable music volume and toggle in settings
- Sound effects for tools, gathering, crafting, weather, wildlife, and UI navigation
- Procedural sound effect for coca leaf consumption

## Settings

Accessible via the config menu (Tab key or through Pause menu):

| Setting | Description |
|---------|-------------|
| Day Length | Adjust game day speed (configurable range) |
| Tree Respawn Time | How long before chopped trees regrow |
| Hunger Damage | Toggle hunger depletion |
| Health Damage | Toggle health drain when starving |
| Weather Damage | Toggle weather damage effects |
| HUD Coordinates | Show/hide position coordinates |
| Music | Toggle background music with fade |
| Music Volume | Adjust music volume |
| SFX Volume | Adjust sound effects volume |
| Brightness | Screen brightness (50%-200%) |

## Requirements

- **Godot 4.5+** (free and open source game engine)
- **Operating System:** Windows 10/11, macOS 10.15+, or Linux
- **Graphics:** OpenGL 3.3 / Vulkan compatible GPU
- **Controller (optional):** PlayStation DualSense/DualShock or Xbox controller

## Installation

### Step 1: Install Godot Engine

#### Windows
1. Go to [godotengine.org/download](https://godotengine.org/download/windows/)
2. Download **Godot 4.5** (Standard version)
3. Extract the ZIP file to a folder (e.g., `C:\Godot`)
4. Run `Godot_v4.5-stable_win64.exe` (no installation required)

#### macOS
1. Go to [godotengine.org/download](https://godotengine.org/download/macos/)
2. Download **Godot 4.5** (Standard version)
3. Open the DMG and drag Godot to your Applications folder
4. First launch: Right-click → Open (to bypass Gatekeeper)

#### Linux
1. Go to [godotengine.org/download](https://godotengine.org/download/linux/)
2. Download **Godot 4.5** (Standard version)
3. Extract and run the executable, or install via your package manager

### Step 2: Download the Game

#### Option A: Clone with Git
```bash
git clone https://github.com/adchamberlain/into-the-wild.git
```

#### Option B: Download ZIP
1. Click the green **Code** button on GitHub
2. Select **Download ZIP**
3. Extract to a folder of your choice

### Step 3: Run the Game

1. Open Godot Engine
2. Click **Import** and navigate to the game folder
3. Select the `project.godot` file and click **Open**
4. Once the project loads, press **F5** or click the **Play** button in the top-right

## Controller Setup

### PlayStation Controller (DualSense / DualShock 4)
- **Windows:** Connect via USB or Bluetooth (native support in Windows 10/11)
- **macOS:** Connect via USB or Bluetooth (System Preferences → Bluetooth)
- **Linux:** Connect via USB or Bluetooth (most distros support it natively)

### Xbox Controller
- **Windows:** Connect via USB, Bluetooth, or Xbox Wireless Adapter
- **macOS:** Connect via USB or Bluetooth
- **Linux:** Connect via USB (xpad driver) or Bluetooth

The game auto-detects your input device and switches button prompts accordingly.

## Troubleshooting

### Game won't start
- Ensure you have Godot 4.5 or newer (not 3.x)
- Try running with `--verbose` flag for error messages

### Controller not detected
- Reconnect the controller
- On macOS, ensure Bluetooth permissions are granted
- Try a wired USB connection

### Poor performance
- Close other applications
- In Godot: Project → Project Settings → Rendering → Adjust quality settings

## Development

See `DEV_LOG.md` for development history and `into-the-wild-game-spec.md` for the full game specification.

## Credits

**Created by:** Andrew Chamberlain, Ph.D. & Lucas Ventura-Chamberlain
**Website:** [andrewchamberlain.com](https://andrewchamberlain.com)

### Music

Minecraft-style Music Pack by Valdis Story (u/ThatOneRandomDev)
- License: Free to use (open source)
- See `ATTRIBUTIONS.md` for full track listing

## License

This project is for personal/educational use.
