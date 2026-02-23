# Bow & Arrow System Design

## Crafting Recipes

- **Bow**: 2 rope + 3 branch (bench, camp level 2)
- **Arrow Bundle**: 2 feathers + 4 branch → 20 arrows (bench, camp level 2)

## Equipment

- Bow uses a new equipment slot. Shows a BoxMesh bow model when equipped.
- Arrows tracked as inventory count. Each shot consumes 1 arrow.
- Bow has durability (like axes). Breaks after enough uses, must craft another.

## Shooting Mechanic

- Hold right-click to draw (0.5s charge). Release to fire.
- Arrow spawns as RigidBody3D with initial velocity in camera forward direction.
- Gravity creates a natural arc over distance.
- ~40-50 unit max range before despawn.
- Missed arrows stick into terrain briefly then despawn (no recovery).

## Animal Hunting

- Add `take_hit(damage: float)` to AmbientAnimalBase. On hit: brief death animation (fall over), drop loot, despawn after 1 second.
- **Bird**: drops 1 raw_meat + 1-2 feathers
- **Rabbit**: drops 1 raw_meat + 1 hide
- Arrow collision via Area3D checking "ambient_animal" group.

## Future Defense Support

- Arrow collision also checks "hostile" group. No hostiles exist yet but the system will support them.
- `take_hit()` accepts damage amount, defaults to one-shotting ambient animals.

## Visuals (Procedural BoxMesh)

- **Bow**: Curved strip (thin tall box segments) with string line
- **Arrow in flight**: Thin shaft + triangular head + feather tail fins
- **Draw animation**: Tween pulling string backward

## Sound

- Procedural SFX: bow draw (low creak), release (twang), arrow hit (thud)

## Key Files Affected

- `scripts/crafting/crafting_system.gd` - New recipes
- `scripts/player/equipment.gd` - Bow equipment slot, ammo tracking
- `scripts/player/player_controller.gd` - Draw/fire input handling, bow HUD
- `scripts/creatures/ambient_animal_base.gd` - take_hit(), loot drops
- `scripts/creatures/ambient_bird.gd` - Bird-specific loot
- `scripts/creatures/ambient_rabbit.gd` - Rabbit-specific loot
- New: `scripts/player/bow_system.gd` - Bow mechanics, arrow spawning, projectile physics
- New: `scripts/player/arrow_projectile.gd` - Arrow RigidBody3D with collision detection
- `scripts/core/sfx_manager.gd` - Bow/arrow sound effects
- `scripts/ui/hud.gd` - Arrow count display when bow equipped
