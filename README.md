# Into the Wild

A solo camping adventure game built in Godot 4.5. Survive in the wilderness by gathering resources, crafting tools, building shelter, and managing your hunger and health through dynamic weather conditions.

**Visual Style:** Blocky, retro aesthetic reminiscent of early 3D games like Minecraft.

## Features

### Infinite Procedural World
- **Chunk-based terrain** - Endless exploration with procedurally generated landscapes
- **Biome variety** - Mixed forests with oak, big oak, and birch trees
- **Natural features** - Ponds for swimming and fishing, grass, flowers
- **Blocky terrain** - Cell-based terrain with vertical cliffs and height variation
- **Ambient wildlife** - Rabbits and birds that flee when approached

### Survival Systems
- **Health & Hunger** - Manage your vital stats to stay alive
- **Weather System** - Dynamic weather including rain, storms, fog, heat waves, and cold snaps
- **Day/Night Cycle** - 20-minute real-time days with dynamic sky, stars, and moon
- **Swimming** - Explore underwater with breath mechanics
- **Save System** - 3 save slots with camp level and timestamp display

### Gathering & Crafting
- **Resource Gathering** - Collect branches, rocks, berries, mushrooms, herbs, and wood
- **Tree Chopping** - Use the stone axe to chop trees (with first-person swing animation)
- **Fishing** - Multi-step fishing mechanic at pond fishing spots
- **Tiered Crafting** - Basic recipes by hand, advanced recipes at crafting bench

### Campsite Progression

Build up your camp through three levels:

| Level | Name | Requirements |
|-------|------|--------------|
| 1 | Survival Camp | Starting level |
| 2 | Functional Camp | Fire pit + Shelter + Crafting bench + Drying rack + Fishing rod |
| 3 | Wilderness Basecamp | Canvas tent + Storage + Herb garden + 6 structures + 3 days at Level 2 |

### Structures

| Structure | Description |
|-----------|-------------|
| Fire Pit | Warmth, light, cooking. Add wood for fuel. |
| Shelter | Weather protection, rest to restore health |
| Storage Box | 20-slot container for extra items |
| Crafting Bench | Access advanced crafting recipes |
| Drying Rack | Food preservation |
| Herb Garden | Passive herb production |
| Canvas Tent | Better weather protection |
| Log Cabin | Walkable interior with bed (full restore) and kitchen (5 advanced recipes) |

### Tools & Equipment

| Slot | Item | Description |
|------|------|-------------|
| 1 | Torch | Portable light source |
| 2 | Stone Axe | Chop trees (150 durability) |
| 3 | Campfire Kit | Place a fire pit |
| 4 | Rope | Crafting material |
| 5 | Shelter Kit | Place a lean-to shelter |
| 6 | Storage Box | Place storage container |
| 7 | Fishing Rod | Catch fish (50 durability) |
| 8 | Crafting Bench Kit | Place a workbench |

## Controls

### Keyboard & Mouse

#### Movement
- **WASD** - Move
- **Mouse** - Look around
- **Space** - Jump / Swim up
- **Shift** - Sprint
- **Escape** - Pause menu

#### Interaction
- **E** - Interact with objects
- **F** - Eat food / Use healing items
- **R** - Use equipped tool / Place structure
- **Q** - Unequip current item
- **1-8** - Equip item in slot

#### Menus
- **C** - Crafting menu
- **I** - Equipment menu
- **Tab** - Config menu
- **K** - Save game (3 slots)
- **L** - Load game (3 slots)

### PlayStation DualSense Controller

Full controller support with PlayStation button prompts.

#### Movement
- **Left Stick** - Move
- **Right Stick** - Look around
- **Cross (×)** - Jump / Swim up
- **L3 (Left Stick Click)** - Sprint

#### Interaction
- **Square (□)** - Interact with objects
- **Triangle (△)** - Eat food / Use healing items
- **R2** - Use equipped tool / Place structure
- **Circle (○)** - Unequip current item
- **L1/R1** - Cycle through equipment slots

#### Menus
- **Touchpad** - Crafting menu
- **Create** - Equipment menu
- **Options** - Pause menu

## Crafting Recipes

### Basic Recipes (Hand Crafting)

| Recipe | Ingredients |
|--------|-------------|
| Stone Axe | 2 River Rock + 1 Branch |
| Torch | 2 Branch |
| Rope | 3 Branch |
| Campfire Kit | 4 Branch + 3 River Rock |
| Crafting Bench Kit | 6 Wood + 4 Branch |

### Advanced Recipes (Requires Crafting Bench)

| Recipe | Ingredients |
|--------|-------------|
| Shelter Kit | 6 Branch + 2 Rope |
| Storage Box | 4 Wood + 1 Rope |
| Fishing Rod | 3 Branch + 1 Rope |
| Healing Salve | 3 Herb |
| Berry Pouch | 5 Berry |

## Cooking

Cook raw food at a fire pit for better hunger restoration:

| Raw Food | Cooked | Hunger Restored |
|----------|--------|-----------------|
| Berry | Cooked Berries | +25 (vs +15 raw) |
| Mushroom | Cooked Mushroom | +20 (vs +10 raw) |
| Fish | Cooked Fish | +40 (vs +25 raw) |

## Weather Effects

| Weather | Effect | Protection |
|---------|--------|------------|
| Storm | 2 HP/sec damage | Shelter |
| Cold Snap | 1.5 HP/sec damage | Fire warmth |
| Heat Wave | 2x hunger depletion | Eat more |
| Rain | Reduces fire effectiveness | None needed |
| Fog | Reduced visibility | None needed |

Weather features GPU-accelerated particle effects for rain, snow, and dust.

## Audio

- 12 ambient music tracks with shuffle and crossfade
- Configurable music volume in settings

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
4. Once the project loads, press **F5** or click the **Play** button (▶) in the top-right

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
