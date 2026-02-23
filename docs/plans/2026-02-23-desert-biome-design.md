# Desert Biome Design

## Overview

A ring-shaped desert biome surrounds the existing world at 150-250 units from spawn. It features sandy dune terrain, cactuses, palm trees, palm oases with underwater rare gems, desert-specific creatures, and survival hazards. Beyond the desert, normal forest/rocky terrain resumes.

## Architecture: Approach A — Extend RegionType Enum

Add `DESERT = 5` to the existing `RegionType` enum in `chunk_manager.gd`. The `get_region_at()` function already uses distance from spawn as a factor. A distance check determines when to return DESERT. All existing per-region infrastructure (colors, height params, vegetation multipliers, animal spawn tables) gets a new DESERT entry.

## Terrain & Biome Integration

### Distance-based region selection

```
distance from (0,0):
  0-60      -> FOREST (existing)
  60-150    -> noise-based (existing: MEADOW/FOREST/HILLS/ROCKY/MOUNTAIN)
  150-170   -> transition blend (lerp desert colors/heights with inner region)
  170-230   -> DESERT
  230-250   -> transition blend (lerp desert with outer region)
  250+      -> noise-based (existing regions resume)
```

### Desert terrain parameters

- Ground colors: Sandy tan base `Color(0.82, 0.72, 0.55)` with gold/brown variation
- Height: Gentle rolling dunes, `height_scale: 4.0`, low frequency noise for broad dune shapes
- One river can spawn in desert, routed toward the opal oasis
- Vegetation multiplier: `{ tree: 0.0, rock: 0.3, berry: 0.0, herb: 0.0, osha: 0.0, cactus: 1.0, palm: 0.3 }`

### Transition zones

The 20-unit bands on each edge interpolate ground color, height scale, and vegetation density between the adjacent region and desert. Trees gradually thin to zero; grass color shifts to tan. Cactuses and palms fade in.

## Desert Vegetation

### Cactuses (new vegetation type)

- 80% are **prickly cactuses**: Deal 5-10 HP contact damage via Area3D collision when player touches them. Brief "Ouch!" notification. 1-2 second damage cooldown.
- 20% are **fruit-bearing cactuses**: Harvestable cactus fruit (red fruit, food item). Interaction prompt "Pick cactus fruit [E]".
- Visual: Tall green column with arm branches, built from BoxMesh primitives.

### Palm trees (new tree type)

- Replace forest trees in desert biome.
- Tan/brown trunk, green frond clusters at top (BoxMesh layered style).
- Clustered near oases (4-6 per oasis), sparse elsewhere.

## Palm Oases

### Placement

3 oases distributed around the desert ring (~120 degrees apart). Each is a circular pool ~12 units diameter, ~4 units deep (deeper than regular ponds at 2.5). Surrounded by a cluster of 4-6 palm trees.

### Gem types

- 2 oases contain **diamond nodes** (2-3 nodes each, ~5-6 diamonds total)
- 1 oasis contains **opal nodes** (3 nodes, ~3 opals total) — the desert river leads to this one

### Underwater gem nodes

- Sit on the pool floor, visually glowing/sparkling to be visible from the surface.
- Mined like ore using the axe — requires multiple hits while managing breath (4-second bubble drain).
- Player must dive, hit a few times, surface for air, dive again.

### Oasis river

A single desert river spawns, flowing from the desert ring edge toward the opal oasis. Uses existing river system but with sandy banks. Helps the player discover the opal oasis.

### Visual

Oasis water is slightly bluer/more vivid than regular pond water. Palm trees have tan trunks with green frond clusters at the top.

## Desert Creatures

### Lizards (new, extends AmbientAnimalBase)

- Small, low to ground, fast movement speed.
- Sandy brown/green coloring, built from flat BoxMesh primitives (body, 4 legs, tail).
- Behavior: Primarily IDLE (sunbathing), quick darting MOVING bursts, fast FLEEING.
- Spawn: 1-3 per desert chunk (65% of chunks).
- Non-huntable: Arrows pass through or bounce off harmlessly.

### Tortoises (new, extends AmbientAnimalBase)

- Larger than lizards, dome-shaped shell from layered BoxMeshes (brown/green shell, tan body, stubby legs, small head).
- Behavior: Very slow movement, short flee distance, mostly IDLE.
- Spawn: 0-1 per desert chunk, less common than lizards.
- Non-huntable.

### Spawn table

```
DESERT: 1-3 lizards, 0-1 tortoises, 0 rabbits, 0 birds
```

## Desert Hazards

### Faster hunger drain

- When player is in DESERT region, hunger drains at 1.5x normal rate.
- Checked via `get_region_at(player.x, player.z)` in the hunger tick.
- HUD shows a subtle heat indicator so the player understands why hunger is dropping faster.
- Eating cactus fruit restores hunger, giving harvestable cactuses a survival purpose.

### Periodic sandstorms

- Trigger every 3-5 minutes while player is in desert, lasting 30-45 seconds.
- Reuses existing `weather_particles.gd` GPUParticles3D system with sand-colored particles (tan/brown) blowing horizontally.
- Effects during sandstorm:
  - Reduced visibility (fog-like sandy overlay)
  - Player movement speed reduced ~30%
  - Sand particle effects around the player
- Sandstorms only active when player is in desert range — entering forest immediately clears the effect.
- Audio: Wind sound effect during sandstorm.

### Cactus damage

- 80% of cactuses deal 5-10 HP contact damage on touch via Area3D.
- Brief "Ouch!" HUD notification.
- 1-2 second cooldown to prevent rapid repeated damage.

## Crafting Rewards

### New items

- `diamond` — rare gem, mined from oasis floor
- `opal` — rare gem, mined from opal oasis floor
- `cactus_fruit` — food item, harvested from fruit-bearing cactuses

### Diamond Axe

- Recipe: 2 diamonds + 1 metal ore + 1 rope
- Effectiveness: 3.0 (vs Metal Axe at 2.0)
- Durability: 3x Metal Axe
- Visual: Lighter blue-tinted axe head with sparkle
- Requires crafting bench

### Diamond Arrows

- Recipe: 1 diamond + 5 sticks + 2 feathers (yields 10 arrows)
- Key difference: **they don't disappear**
- When a diamond arrow hits terrain, it sticks and becomes a pickup item (Area3D with interaction prompt "Pick up diamond arrow [E]")
- When it hits an animal, it deals damage, drops to the ground at the animal's position, becomes pickable
- Tracked as `diamond_arrows` in inventory, separate from regular `arrows`
- Bow system checks for diamond arrows first, then regular arrows
- Visual: Blue-tinted arrowhead, slight glow/shimmer
- If the player can't reach where they land, they are lost
- Requires crafting bench

### Enchanted Bow

- Recipe: 2 opals + 1 bow + 1 rope
- Faster draw speed (0.6x draw time)
- Longer range (1.5x arrow speed)
- Visual: Bow with green/purple iridescent tint on the limbs
- Requires crafting bench

## Files

### New files (~8)

- `scripts/world/desert_oasis.gd` — Oasis pool generation, palm tree clusters, underwater gem nodes
- `scripts/world/cactus.gd` — Cactus vegetation with damage/fruit variants
- `scripts/world/palm_tree.gd` — Palm tree mesh generation
- `scripts/world/sandstorm.gd` — Sandstorm particle effect, visibility reduction, speed debuff
- `scripts/creatures/ambient_lizard.gd` — Lizard mesh + behavior (extends AmbientAnimalBase)
- `scripts/creatures/ambient_tortoise.gd` — Tortoise mesh + behavior (extends AmbientAnimalBase)
- `scripts/player/diamond_arrow_projectile.gd` — Extends/modifies ArrowProjectile, persists as pickup
- `scripts/resources/gem_node.gd` — Underwater mineable gem (diamond/opal variants)

### Modified files (~7)

- `scripts/world/chunk_manager.gd` — Add DESERT to RegionType, desert params, oasis placement, desert river, distance-based region selection
- `scripts/world/terrain_chunk.gd` — Desert vegetation spawning (cactus/palm), desert creature spawn table, transition blending
- `scripts/player/bow_system.gd` — Diamond arrow priority, spawn diamond projectile variant
- `scripts/player/equipment.gd` — Diamond axe + enchanted bow definitions
- `scripts/crafting/crafting_system.gd` — New recipes (diamond axe, diamond arrows, enchanted bow)
- `scripts/player/player_controller.gd` — Desert hunger drain multiplier, cactus damage handling
- `scripts/ui/hud.gd` — Desert heat indicator, sandstorm overlay
