# Into the Wild

A solo camping adventure game built in Godot 4.5. Survive in the wilderness by gathering resources, crafting tools, building shelter, and managing your hunger and health through dynamic weather conditions.

## Features

### Survival Systems
- **Health & Hunger** - Manage your vital stats to stay alive
- **Weather System** - Dynamic weather including rain, storms, fog, heat waves, and cold snaps
- **Day/Night Cycle** - 20-minute real-time days with 6 time periods

### Gathering & Crafting
- **Resource Gathering** - Collect branches, rocks, berries, mushrooms, herbs, and wood
- **Tree Chopping** - Use the stone axe to chop trees for wood
- **Fishing** - Catch fish at fishing spots with a fishing rod
- **Crafting System** - Craft tools, structures, and consumables

### Building
- **Fire Pit** - Provides warmth, light, and cooking
- **Shelter** - Protection from storms, rest to restore health
- **Storage Box** - Store extra items
- **Crafting Bench** - Dedicated crafting station

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

### Movement
- **WASD** - Move
- **Mouse** - Look around
- **Space** - Jump
- **Shift** - Sprint
- **Escape** - Release/capture mouse

### Interaction
- **E** - Interact with objects
- **F** - Eat food / Use healing items
- **R** - Use equipped tool / Place structure
- **Q** - Unequip current item
- **1-8** - Equip item in slot

### Menus
- **C** - Crafting menu
- **I** - Equipment menu
- **Tab** - Config menu
- **K** - Quick save
- **L** - Quick load

## Crafting Recipes

| Recipe | Ingredients | Output |
|--------|-------------|--------|
| Stone Axe | 2 River Rock + 1 Branch | Tool for chopping |
| Torch | 2 Branch | Light source |
| Rope | 3 Branch | Crafting material |
| Campfire Kit | 4 Branch + 3 River Rock | Placeable fire pit |
| Shelter Kit | 6 Branch + 2 Rope | Placeable shelter |
| Storage Box | 4 Wood + 1 Rope | Placeable storage |
| Fishing Rod | 3 Branch + 1 Rope | Fishing tool |
| Crafting Bench Kit | 6 Wood + 4 Branch | Placeable workbench |
| Healing Salve | 3 Herb | Instant +30 health |
| Berry Pouch | 5 Berry | Concentrated food |

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

## Requirements

- Godot 4.5+

## Running the Game

1. Clone this repository
2. Open the project in Godot 4.5
3. Run the main scene (`scenes/main.tscn`)

## Development

See `DEV_LOG.md` for development history and `into-the-wild-game-spec.md` for the full game specification.

## License

This project is for personal/educational use.
