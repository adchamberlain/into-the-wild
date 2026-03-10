# Tutorial Hint System Design

## Overview

A minimal, ambient hint system that teaches new players the game through contextual one-time messages. Inspired by Breath of the Wild — hints appear once at the right moment, then never again. The game teaches you as you play, not before.

## Design Decisions

- **Style:** Minimal & ambient — hints fire once per trigger, per save slot
- **Presentation:** Enhanced center-screen notification with gold "SURVIVAL TIP" header, distinct from system notifications
- **Toggle:** Config menu "Show Hints" option, on by default
- **Persistence:** Per-save-slot via `seen_hints` array in player save data
- **Queueing:** Sequential with ~4 second spacing, no dropping
- **Loading guard:** `_is_loading` flag suppresses hints during save restoration
- **Scope:** 18 hints covering early through late game

## Architecture

### New File: `scripts/ui/hint_manager.gd` (Autoload)

Registered as `HintManager` in `project.godot`. Core responsibilities:

- **Hint registry:** Dictionary of hint ID → `{ message, color }` for all 18 hints
- **Seen tracking:** `seen_hints: Array[String]` — persisted per save slot
- **Queue management:** FIFO queue, processes one hint at a time with 4-second spacing
- **Display:** Calls `hud.show_hint()` (new method, separate from `show_notification()`)
- **Config check:** Reads `hints_enabled` from config; when off, hints are suppressed but NOT marked as seen
- **Loading guard:** `_is_loading` flag prevents hints during save data restoration

**Public API:**
```gdscript
HintManager.try_show(hint_id: String) -> void  # Called by game systems
HintManager.set_seen_hints(hints: Array) -> void  # Called by save_load on restore
HintManager.get_seen_hints() -> Array[String]  # Called by save_load on save
HintManager.set_loading(loading: bool) -> void  # Called by save_load
HintManager.set_hints_enabled(enabled: bool) -> void  # Called by config
```

### Trigger Pattern

Existing scripts add one line at trigger points:
```gdscript
HintManager.try_show("storm_warning")
```

HintManager handles all "should I show this?" logic internally.

### Equipment Hints via item_added

Hints for bow, machete, hang glider, and rare resources trigger on `Inventory.item_added` (not `recipe_crafted`) to handle:
- `start_with_bow_map` config giving items at spawn
- New Game Plus carrying items over

The loading guard prevents these from firing during save restoration.

## HUD Presentation

New `show_hint()` method in `hud.gd`, separate from `show_notification()`:

- **Header:** "SURVIVAL TIP" in gold `Color(1, 0.85, 0.3, 1)`, 32px
- **Border:** StyleBoxFlat with border color `Color(1, 0.85, 0.3, 0.3)`
- **Background:** `Color(0.1, 0.1, 0.12, 0.85)`
- **Body:** RichTextLabel with BBCode for gold highlights, 28px
- **Font:** `hud_font.tres` (SF Mono)
- **Duration:** 8 seconds base + 1 second per additional line
- **Animation:** Fade in 0.3s, fade out 0.5s
- **Position:** Center-screen, same area as notifications (separate node so they don't conflict)

## Hint Catalog (18 hints)

### Early Game

| ID | Trigger | Message |
|---|---|---|
| `first_gather` | First item added to inventory | "You gathered your first resource! Look for [color=gold]sticks[/color] and [color=gold]stones[/color] nearby — you'll need them to craft tools." |
| `first_craft` | First `recipe_crafted` signal | "Nice work! Open the [color=gold]Crafting Menu (C)[/color] anytime to see what else you can build." |
| `hunger_low` | Hunger drops below 40% | "Your hunger is getting low. [color=gold]Fish[/color] at a pond, gather [color=gold]berries[/color], or [color=gold]cook meat[/color] at a fire pit to eat." |
| `first_fire_pit` | Fire pit placed | "Your fire pit is ready! You can [color=gold]cook food[/color] here. Next up: build a [color=gold]Shelter[/color] to protect yourself from storms." |
| `first_shelter` | Shelter placed | "Shelter built! You'll take less damage during storms now. Keep building — more structures help [color=gold]level up your camp[/color]." |

### Mid Game

| ID | Trigger | Message |
|---|---|---|
| `first_weather` | First non-clear weather | "Weather is changing! [color=gold]Storms[/color] deal damage when exposed, [color=gold]cold snaps[/color] drain hunger faster, and [color=gold]heat waves[/color] are brutal. Seek shelter!" |
| `first_fish` | First fish caught | "Fresh catch! Fish can be [color=gold]eaten raw[/color] in a pinch, but [color=gold]cooking[/color] at a fire pit gives much more nutrition." |
| `camp_level_2_hint` | 2 structures placed, camp still level 1 | "Your camp is growing! Build a [color=gold]Fire Pit[/color], [color=gold]Shelter[/color], [color=gold]Crafting Bench[/color], [color=gold]Drying Rack[/color], and craft a [color=gold]Fishing Rod[/color] to reach Camp Level 2." |
| `camp_level_2_up` | Camp reaches level 2 | "Camp Level 2 unlocked! You can now build a [color=gold]Canvas Tent[/color] and [color=gold]Herb Garden[/color]. Keep going for Level 3!" |
| `first_bow` | Bow added to inventory | "You crafted a bow! [color=gold]Equip it[/color] and use it to hunt [color=gold]rabbits[/color] and [color=gold]birds[/color] for meat. Aim carefully — arrows are precious." |
| `swim_warning` | Player enters water | "You can swim, but watch your [color=gold]air bubbles[/color] underwater! Surface before they run out or you'll take damage." |
| `fall_warning` | First fall damage taken | "Ouch! Long falls deal damage. Watch your step near cliffs and ledges." |

### Late Game / Exploration

| ID | Trigger | Message |
|---|---|---|
| `desert_entry` | Player enters desert biome | "The desert is scorching! [color=gold]Heat[/color] drains your hunger faster out here. Watch out for [color=gold]cactuses[/color] — they hurt on contact." |
| `first_rare_resource` | First diamond/opal/crystal/rare_ore/iron added | "Rare find! These materials unlock [color=gold]advanced recipes[/color] at the Crafting Bench — powerful tools and equipment." |
| `first_machete` | Machete added to inventory | "Machete ready! Use it to [color=gold]cut through thick vegetation[/color] and access areas you couldn't reach before." |
| `first_hang_glider` | Hang glider added to inventory | "Hang glider equipped! [color=gold]Jump from high ground[/color] and hold jump to glide. Use [color=gold]sprint[/color] mid-air for a speed boost." |
| `first_cabin` | Cabin placed | "Your cabin is complete! Sleep in the [color=gold]bed[/color] to skip to morning, and use the [color=gold]kitchen[/color] for advanced recipes." |
| `deep_well_discovery` | Player finds the deep well | "There's something at the bottom of this well... but it's far too deep to swim. Maybe there's [color=gold]another way down[/color]." |

## File Changes

### New (1)
- `scripts/ui/hint_manager.gd` — autoload (~150-200 lines)

### Modified (~11)

| File | Change | Size |
|---|---|---|
| `project.godot` | Register HintManager autoload | 1 line |
| `scripts/ui/hud.gd` | Add `show_hint()` + hint panel nodes | ~40 lines |
| `scripts/core/save_load.gd` | Save/load `seen_hints` + loading guard | ~10 lines |
| `scripts/ui/config_menu.gd` | "Show Hints" toggle | ~15 lines |
| `scripts/resources/resource_node.gd` | `try_show("first_gather")` | 1 line |
| `scripts/crafting/crafting_system.gd` | `try_show("first_craft")` | 1-2 lines |
| `scripts/player/inventory.gd` | `try_show()` for bow/machete/glider/rare | 3-4 lines |
| `scripts/world/weather_manager.gd` | `try_show("first_weather")` | 1 line |
| `scripts/player/player_controller.gd` | Desert, water, fall hints | 3-4 lines |
| `scripts/campsite/campsite_manager.gd` | Camp level hints | 2-3 lines |
| `scripts/campsite/placement_system.gd` | Structure-specific hints | 2-3 lines |
| `scripts/resources/fishing_spot.gd` | `try_show("first_fish")` | 1 line |

### Tests
- `tests/test_hint_manager.gd` — hint shown once, queue spacing, loading guard, config toggle, seen persistence
