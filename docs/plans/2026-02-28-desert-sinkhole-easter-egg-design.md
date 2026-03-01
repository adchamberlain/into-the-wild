# Desert Sinkhole Easter Egg — Design Document

## Overview

A hidden sinkhole in the desert biome contains an ancient explorer's journal — the ultimate item in the game. Reaching it requires a deep underwater dive made possible by a nearby coca leaf plant. The journal grants permanent stat boosts, reveals map markers for all points of interest, and unlocks the hang glider recipe — a flight tool that transforms late-game exploration.

## The Sinkhole

**Location**: Fixed position in the desert ring at angle 180° (~200 units from spawn), equidistant from the three oases. No palms, no gems, no visual hints from a distance.

**Terrain**:
- 5-unit radius circular depression
- 30 units deep, water-filled from surface to bottom
- 3-unit gradual slope at the rim for natural appearance
- Water surface at ground level relative to desert terrain

**Visual hints**:
- Faint blue-green OmniLight3D glow at the bottom
- Book on a stone pedestal with warm amber emissive glow
- No surrounding vegetation — just sand and the hole

**Generation**: Registered as a water body in chunk_manager, terrain carved like oasis pools but deeper. Single fixed spawn location, deterministic.

## The Coca Leaf Plant

**Location**: 5-8 units from the sinkhole rim. The only green vegetation near the sinkhole.

**Visual**: Bushy plant ~0.5 units tall, broad oval leaves in 2-3 shades of green. Stands out against sand.

**Interaction**: Hand-gatherable. Interaction text: "Pick Coca Leaf". Yields 1 `coca_leaf` item.

**Consumption** (eat action):
- Notification: "Your breathing slows... lungs feel stronger" (green text)
- `BREATH_BUBBLE_INTERVAL` doubles from 4.0s to 8.0s for 5 minutes (300 seconds)
- After 5 minutes: notification "The coca leaf effect fades" (yellow text), interval returns to 4.0s
- Hunger restored: 5 (minor)

**Respawn**: 72 hours game time. Tracked in save data. Only one plant exists.

**Dive math**:
- Without coca leaf: 5 bubbles × 4s = 20s available. 30-unit round trip needs ~20.5s. Impossible (no margin, drowns).
- With coca leaf: 5 bubbles × 8s = 40s available. 30-unit round trip needs ~20.5s. Comfortable margin.

## The Explorer's Journal

**Pickup**: Interact (E/Square) with the book underwater. Goes into inventory as `explorers_journal`.

**Reading**: Use from inventory/equipment. Full-screen UI panel (pause menu style) displays journal pages. Book stays in inventory permanently as a keepsake — not consumed.

**Journal text**: 3-4 short paragraphs from a previous explorer. Weathered, pragmatic tone. Mentions the oases, caves, and mountains. Ends with: *"If you've found this, you've earned what I've left behind. The wilderness gives its secrets to those willing to go deep."*

**Re-reading**: Can read anytime from inventory. Rewards only trigger on first read.

## Rewards (First Read)

### Reward 1: Permanent Stat Boost
- Notification: "Ancient survival wisdom flows through you..."
- Max health: +25 (100 → 125)
- Hunger depletion rate: -20% (0.05 → 0.04/sec)
- Both permanent, saved to player data

### Reward 2: Hang Glider Recipe Unlock
- Notification: "You've learned to craft a Hang Glider"
- Recipe: 4 rope + 6 branch + 2 hide (requires bench, camp level 3)
- Infinite durability — the only unbreakable equipment in the game

### Reward 3: Map Markers
- Notification: "The journal reveals hidden locations..."
- Compass HUD panel gains permanent entries:
  - All 3 oases (labeled by gem type)
  - All cave entrances
  - The sinkhole itself
- Entries cycle in the compass display when player has compass equipped

## Hang Glider

### Crafting
- Recipe: 4 rope + 6 branch + 2 hide
- Requires crafting bench, camp level 3
- Recipe only available after reading the explorer's journal

### Equipment
- Equips to a tool slot
- Infinite durability (never breaks)
- First-person model: triangular fabric wing frame with grip bar

### Flight Mechanics
- **Deploy**: Jump, then press R/R2 (use_equipped) while airborne
- **Pitch**: Camera look up/down (right stick or mouse) controls climb/dive
- **Steer**: WASD / left stick for horizontal direction
- **Retract**: Jump or crouch to fold glider and drop

### Flight Parameters
- Climb rate: ~1 u/s (pitching up)
- Descent rate: ~2 u/s (pitching down or neutral)
- Level flight: sustainable by holding slight upward pitch
- Horizontal speed: ~8 u/s (faster than sprinting at ~6 u/s)
- Max height: 25 units above terrain (above trees, below mountain peaks)
- Landing: touch ground to auto-retract

### Controls
| Action | Keyboard | Controller |
|--------|----------|------------|
| Deploy | R (use) | R2 |
| Pitch up | Mouse up | Right stick up |
| Pitch down | Mouse down | Right stick down |
| Steer | WASD | Left stick |
| Retract | Space or C | Cross (×) or crouch |

No new input mappings required — reuses existing camera and movement inputs.

## Save/Load Considerations

**New persistent data**:
- `has_read_journal: bool` — whether rewards have been granted (prevents double-granting)
- `journal_stat_boost_applied: bool` — health/hunger bonuses active
- `max_health_bonus: int` — saved as part of player stats
- `hunger_rate_multiplier: float` — saved as part of player stats
- `map_markers_unlocked: bool` — compass shows POI entries
- `coca_leaf_depleted_time: float` — respawn tracking (like cave resources)
- `sinkhole_book_collected: bool` — whether the book has been picked up
- `coca_leaf_effect_remaining: float` — buff timer (if active when saving)

## Discovery Flow

1. Player explores desert, stumbles upon a dark hole in the sand (no other landmarks nearby)
2. Notices faint glow from the depths — curiosity piqued
3. Dives in, sees the book glowing far below
4. Runs out of air, surfaces gasping (or drowns and respawns)
5. Notices the coca leaf plant near the rim — the only green thing around
6. Picks it, eats it, gets the breathing buff notification
7. Dives again with doubled air time, reaches the book
8. Surfaces triumphant, reads the journal
9. Receives all three rewards in sequence
10. Crafts the hang glider and soars above the world they've spent hours exploring on foot
