# Explorer's Journal Content Expansion — Design

## Overview

Expand the Explorer's Journal from a single two-page spread into an 11-spread multi-page book with page-turning navigation. The journal tells the chronological story of E.W. Carlston's time in the Carlston Wilderness, followed by a complete crafting recipe reference organized by tier.

## Design Decisions

- **Tone**: Adventurous storyteller — wonder-filled and practical, not dark or grim
- **Structure**: Approach A — story entries first (spreads 1-6), recipe reference at back (spreads 7-11)
- **Chronology**: Dated diary entries (Day 1, 5, 12, 20, 31, 47) building a narrative arc
- **Navigation**: D-pad left/right on controller, arrow keys on keyboard. Page indicator at bottom.
- **Total spreads**: 11 (each spread = left page + right page)
- **All game functionality preserved**: rewards, first-read flag, save/load, equipment — unchanged

## Spread Layout

### Adventure Diary (Spreads 1-6)

**Spread 1 — Title Page + Day 1: Arrival**
- Left: Title "Explorer's Journal", subtitle "A Record of the Carlston Wilderness", "Property of E.W. Carlston"
- Right: Day 1 — arriving at the forest, finding the pond, rabbits and birds, deciding to map the wilderness

**Spread 2 — Day 5: The Forest & First Crafting**
- Left: Day 5 — learning basic crafting, river rocks + branches for tools, rope from plant fibers, building a workbench
- Right: Day 5 continued — fishing at the pond, drying rack, berry gathering, herbs for healing salve, building a shelter

**Spread 3 — Day 12: The Rocky Highlands & Caves**
- Left: Day 12 — pushing north into highlands, discovering first cave entrance, crystals and ore inside
- Right: Day 12 continued — four cave entrances found, practical torch advice, lantern recommendation

**Spread 4 — Day 20: The Desert Ring & Oases**
- Left: Day 20 — desert to the south, three oases discovered, diamonds in the first two pools
- Right: Day 20 continued — opals in the third oasis, river from the east, lizards, tortoise, cactus

**Spread 5 — Day 31: Mountain Peaks & The Glider**
- Left: Day 31 — climbing western mountains with grappling hook, panoramic views from the peak
- Right: Day 31 continued — the hang glider idea, design process, first flight, plans in the back pages

**Spread 6 — Day 47: The Sinkhole & Final Words**
- Left: Day 47 — final discovery, the sinkhole in the desert, diving to the bottom
- Right: Day 47 continued — leaving the journal behind, farewell message, signed "E.W. Carlston"

### Recipe Reference (Spreads 7-11)

**Spread 7 — Hand Crafting (No Tools Required)**
- Primitive Axe, Stone Axe, Torch, Plant Rope, Split Branches, Campfire Kit, Crafting Bench Kit
- Flavor note about the crafting bench being the most important early build

**Spread 8 — Workbench: Getting Established**
- Shelter Kit, Storage Box, Drying Rack Kit, Fishing Rod, Berry Pouch, Healing Salve, Map
- Flavor note about birch bark and berry ink for the map

**Spread 9 — Workbench: Expanding Your Range**
- Garden Plot Kit, Canvas Tent Kit, Snare Trap Kit, Machete, Grappling Hook, Leather Axe Wrap, Leather Hook Wrap, Bow, Arrow Bundle
- Flavor note about the grappling hook opening up highlands and mountains

**Spread 10 — Workbench: Advanced Crafting**
- Cabin Kit, Smithing Station Kit, Smoker Kit, Weather Vane Kit, Metal Axe, Lantern, Compass & Lodestone
- Flavor note about the compass and lodestone beacon

**Spread 11 — Workbench: Rare & Extraordinary**
- Diamond Axe, Diamond Arrows, Enchanted Bow, Hang Glider
- Flavor note about the hang glider as the explorer's greatest creation
- "End of Journal" flourish

## Navigation UI

- Page indicator at bottom center: "Page 3 of 11" style
- Controller hint: "D-Pad to turn pages" / Keyboard: "Arrow Keys to turn pages"
- Close hint: "X to close" (controller) / "ESC or B to close" (keyboard)
- D-pad left / left arrow = previous page, D-pad right / right arrow = next page
- First page: no left navigation. Last page: no right navigation.

## Implementation Scope

### What Changes
- `scripts/ui/journal_ui.gd` — major rewrite: page data array, page-turning input, dynamic page building

### What Does NOT Change
- `scripts/world/explorers_journal_pickup.gd` — pickup mechanics unchanged
- `scripts/player/player_controller.gd` — journal open/close/rewards unchanged
- `scripts/player/equipment.gd` — held journal model unchanged
- `scripts/core/save_load.gd` — save/load unchanged
- `scripts/crafting/crafting_system.gd` — recipe unlocking unchanged
