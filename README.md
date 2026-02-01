# Into the Wild

A solo camping adventure game built in Godot 4.5. Survive in the wilderness by gathering resources, crafting tools, building shelter, and managing your hunger and health through dynamic weather conditions.

**Visual Style:** Blocky, retro aesthetic reminiscent of early 3D games like Minecraft.

## Features

### Infinite Procedural World
- **Chunk-based terrain** - Endless exploration with procedurally generated landscapes
- **Biome variety** - Mixed forests with oak, big oak, and birch trees
- **Natural features** - Ponds for swimming and fishing, grass, flowers
- **Blocky terrain** - Cell-based terrain with vertical cliffs and height variation

### Survival Systems
- **Health & Hunger** - Manage your vital stats to stay alive
- **Weather System** - Dynamic weather including rain, storms, fog, heat waves, and cold snaps
- **Day/Night Cycle** - 20-minute real-time days with dynamic sky, stars, and moon
- **Swimming** - Explore underwater with breath mechanics

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
- **K** - Quick save
- **L** - Quick load

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

- Godot 4.5+
- macOS, Windows, or Linux

## Running the Game

1. Clone this repository
2. Open the project in Godot 4.5
3. Run the main scene (`scenes/main.tscn`)

## Development

See `DEV_LOG.md` for development history and `into-the-wild-game-spec.md` for the full game specification.

## License

This project is for personal/educational use.
