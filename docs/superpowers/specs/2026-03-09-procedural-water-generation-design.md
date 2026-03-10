# Procedural Water Generation Design

## Problem

All water features (ponds, lakes, alpine lakes, rivers) are pre-generated at startup within fixed bounding boxes (max ~255 units from origin). With the desert ring now at 300-360 units, there is a dead zone from ~255 units outward where no water ever appears. Beyond the desert ring, the world is completely dry.

## Goals

- Water features spawn procedurally at any distance as the player explores
- Consistent density matching the inner zone (~1 pond per ~7,500 sq units)
- No water features inside the desert ring (oases are hand-placed)
- Rivers in hills/rocky biomes flowing downhill
- Fully deterministic from world seed (no save/load changes needed)
- No performance impact on chunk loading

## Approach: Grid-Based Region Cells

### Water Cell Grid (Ponds & Lakes)

The world is divided into **80x80 unit water cells**. Each cell is identified by integer coordinates `(cell_x, cell_z)` computed as `floor(world_pos / 80)`.

Each cell deterministically decides whether it contains a water feature using a hash of `(cell_x, cell_z, noise_seed)`. Probability and type depend on biome sampled at the cell center:

| Biome | Pond chance | Lake chance |
|---|---|---|
| Meadow | 40% | 15% |
| Forest | 35% | 0% |
| Hills/Rocky | 25% | 0% |
| Mountain | 20% | 10% (alpine, if elevation sufficient) |
| Desert | 0% | 0% |

If a feature is placed, its exact position is jittered within the cell (+/-30 units from center) to avoid grid-aligned placement. Radius and depth use existing `region_pond_params` tables. The biome is re-confirmed at the jittered position.

### River Grid

Rivers use a separate **200x200 unit grid**. Each river cell deterministically decides whether it contains a river source:

1. Hash `(river_cell_x, river_cell_z, noise_seed + 7000)` to get a candidate position
2. Sample biome at candidate - must be HILLS or ROCKY
3. If valid (~25% probability), generate a short river path (8-12 segments, 18 units each) flowing downhill
4. River paths capped to ~200 units from source, keeping them regional
5. Reuses existing `_generate_river_path` logic with reduced `max_segments` (12)
6. Path gets existing smoothing and fishing pool placement

### Chunk Loading Integration

Water cell evaluation happens **synchronously in `_load_chunk()` in `chunk_manager.gd`**, before `chunk.generate()` is called. This is critical — the water body must be in the `water_bodies` array before `_build_height_cache` runs so terrain correctly carves depressions.

For each chunk load, determine which water cells (80x80) overlap with the chunk (48x48 units = 16 cells * 3.0 cell_size). A chunk can overlap at most **4 water cells** (2x2 when straddling cell boundaries in both axes). For each overlapping cell not yet evaluated:

1. Hash cell coordinates to decide if/what water feature spawns
2. Sample biome at jittered position to confirm validity
3. If valid, add to existing `water_bodies` array
4. Mark cell as evaluated in a `Dictionary` keyed by `Vector2i(cell_x, cell_z)`

### Inner Zone Preservation

Existing startup-generated water features (camp pond, 6 ponds, 2 lakes, 2 alpine lakes, 2 rivers) remain unchanged. Water cells are pre-marked as evaluated based on the actual generation extents:

- **Pond/lake cells**: All cells whose center falls within 150 units of origin (matching `world_extent = 150.0` for pond/lake generation)
- **Alpine lake cells**: All cells whose center falls within 180 units of origin (matching `world_extent = 180.0`)
- **River cells** (200-unit grid): All cells whose center falls within 120 units of origin (matching `world_extent = 120.0` for river source generation)

### Desert Exclusion

Both the **desert ring** (300-360 units) and the **pocket desert** at (-600, 0) with radius 50 + 15 unit blend zone are naturally excluded because `get_region_at()` returns `DESERT` for those positions, and the biome table assigns 0% probability to desert. The biome check at the jittered position ensures edge cases in the blend zone are handled correctly.

### Performance

- **Water cell evaluation**: ~0.1ms per cell (hash + biome check). A chunk overlaps at most 4 water cells (2x2 at boundaries).
- **No per-frame work**: Evaluation happens once during chunk population, never re-evaluated.
- **River generation**: ~1-2ms for path generation, deferred via `await get_tree().process_frame` to avoid blocking chunk loading.
- **`water_bodies` array growth**: The `get_height_at()` function iterates all entries in `water_bodies` on every height query (324 calls per height cache build). With extended exploration, this array grows unboundedly. To mitigate: add a spatial hash bucket lookup so `get_height_at()` only checks water bodies within the relevant chunk's neighborhood (~2 chunk radii). Bucket size of 80 units (matching water cell grid) keeps lookup to O(1) average per query instead of O(n) over all water bodies.

### Save/Load

No changes needed. The system is fully deterministic from `(grid_coordinates, noise_seed)`. On load, the evaluated-cells dictionary starts empty and cells are re-evaluated as chunks load around the player's saved position, producing identical results.

Fishing spots at procedural ponds/lakes use the same `spawned_pond_indices` pattern as existing ones - spawned when the chunk loads, removed when it unloads.

### Unloading

When chunks unload, water cell entries stay in the evaluated dictionary and water body data persists in `water_bodies`. This ensures consistency if the player returns.

## Files to Modify

- `scripts/world/chunk_manager.gd` - Water cell grid logic, integration with `_load_chunk()`, inner zone marking, river grid, spatial hash for `water_bodies` lookups in `get_height_at()`
- No changes to `scripts/world/terrain_chunk.gd` (already consumes `water_bodies` dynamically)
- No changes to `scripts/core/save_load.gd`

## Key Constraints

- Spawn-safe forest zone (60 units) - no water features
- Desert ring (300-360 units) - no water features, only hand-placed oases
- Pocket desert at (-600, 0) radius 50+15 blend - no water features (biome check excludes)
- Camp pond at (15, 12) - always present, never overwritten
- River spawn exclusion within 40 units of origin
