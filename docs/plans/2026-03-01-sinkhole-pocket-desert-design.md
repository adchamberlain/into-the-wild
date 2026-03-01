# Sinkhole Pocket Desert Relocation - Design

## Goal

Move the sinkhole easter egg from the main desert ring (200 units, 180°) to a hidden pocket desert biome 350 units due west of spawn. This makes the sinkhole harder to find by placing it in an isolated, small desert area outside the main ring.

## Pocket Desert Biome

- **Center**: (-350, 0) — due west, 350 units from spawn
- **Base radius**: ~50 units with organic noise boundary using `_desert_boundary_offset()` (same sine-wave function the desert ring uses), giving ±~19 units of wobble
- **Effective radius**: 31-69 units depending on angle
- **Biome behavior**: Returns `RegionType.DESERT` — desert height params (scale 4.0, step 0.5), sand colors, cacti/palms, no trees/berries
- **Blend zone**: 15-unit transition band outside the pocket boundary where terrain colors interpolate between desert and surrounding biome
- **Implementation**: New check in `get_region_at()` after spawn-forest check, before desert ring check

## Sinkhole Relocation

- **New position**: Pocket center (-350, 0), snapped to cell_size grid → (-351, 0)
- **Same properties**: 5-unit radius, 45-unit depth, 3-unit rim ramp, water body registration, 12-unit vegetation suppression buffer
- **Coca leaf plant**: 10 units east of sinkhole (~(-341, 0))
- **Book pedestal**: Same procedural visuals, same interaction, same rewards

## Distant Landmark (Rock Spire)

- **Purpose**: Subtle visual hint to draw curious explorers westward
- **Location**: Eastern edge of pocket desert (~(-300, 0)), facing the main play area
- **Construction**: 3-4 stacked BoxMeshes with slight offsets and rotation, ~8-10 units tall
- **Colors**: Desert rock tones (tan/brown/rust), slightly darker than surrounding terrain
- **Visibility**: ~80-100 units

## Save/Load & Backward Compatibility

- No save format changes needed — sinkhole state fields unchanged
- Sinkhole position is generated deterministically, not saved
- Old saves with `sinkhole_book_collected = true` still work — book won't respawn
- Pocket desert appears retroactively in old saves (biome is position-based)
- Update "Ancient Sinkhole" compass POI to new position

## Files to Modify

- `scripts/world/chunk_manager.gd` — `get_region_at()`, `_generate_desert_sinkhole()`, sinkhole spawning, map marker position
- `scripts/world/terrain_chunk.gd` — blend zone color interpolation for pocket desert proximity
- `scripts/ui/hud.gd` — update sinkhole POI coordinates (if hardcoded)
