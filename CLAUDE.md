# Claude Code Notes

## Project Overview

**Into the Wild** is a solo camping adventure game built in Godot 4.5 with GDScript. See `into-the-wild-game-spec.md` for the full game specification.

This project primarily uses Python and TypeScript for tooling/experiments, and GDScript for the Godot survival game. When working on the game, all scripts are GDScript (.gd files). When working on data/ML experiments, use Python.

## Important Guidelines

### Development Log

**Always keep `DEV_LOG.md` fully updated.** After each development session:

1. Document what was built with a new session entry
2. List all new/modified files
3. Describe features implemented with enough detail to understand the changes
4. Note any known issues or technical debt
5. Update the "Next Session" section with planned tasks

This log serves as our historical record of development progress.

### Spawn/Campsite Location

The player spawn and campsite area must always have these characteristics:

- **Forest region**: 60-unit radius around spawn (0,0) is always FOREST, never plains/meadow/rocky
- **Nearby fishing pond**: Guaranteed pond at approximately (15, 12) - close but not at spawn
- **Trees and cover**: Forest density provides plenty of trees for resources and atmosphere
- **Near terrain variation**: Hills/rocky regions should be accessible but not at the immediate spawn

Rivers and other water features must stay 40+ units away from spawn to keep the campsite area clean.

### Code Style

- Godot 4.5 requires explicit type annotations (no Variant inference)
- Use `physical_keycode` for key detection (Mac compatibility)
- Prefer signals for decoupled communication between systems
- Add nodes to groups for raycast detection (`interactable`, `resource_node`)

### UI Font & Styling

**Font**: Use `resources/hud_font.tres` (SF Mono with fallbacks: Menlo, Monaco, JetBrains Mono, Consolas, Courier New). This gives a terminal/Homebrew aesthetic.

**Font Sizes** (standardized across all UI):
- Titles/Headlines: 56-64px (e.g., "PAUSED", "CAMP LEVEL UP!")
- Primary labels: 40-48px (time, stats, menu items)
- Secondary info: 32-40px (coordinates, descriptions)
- Hints/Small text: 28-32px (keyboard hints, prompts)

**Panel Backgrounds**: Use StyleBoxFlat with:
- Color: `Color(0.1, 0.1, 0.12, 0.8)` (dark semi-transparent)
- Corner radius: 10px
- Content margins: 16-20px

**Important**: Always wrap HUD text in PanelContainers with semi-transparent backgrounds for readability. Never use standalone Labels in the HUD - they become unreadable against bright backgrounds. Use StyleBoxFlat with `Color(0.05, 0.05, 0.08, 0.75)` for overlays like notifications and prompts.

**Text Colors**:
- White/Light: `Color(0.9, 0.9, 0.9, 1)` for primary text
- Gold/Yellow: `Color(1, 0.85, 0.3, 1)` for titles/highlights
- Green: `Color(0.6, 1, 0.6, 1)` for success/positive
- Red: `Color(1, 0.5, 0.5, 1)` for warnings/negative
- Grey: `Color(0.6-0.7, 0.6-0.7, 0.6-0.7, 1)` for hints/secondary

### Chunk Generation Performance

Chunk generation has three expensive operations that **must be batched** across frames for distant chunks to avoid stuttering:

1. **Height cache** (`_build_height_cache`): 324 `get_height_at()` calls, each doing water body loops, river checks, and multi-noise sampling. Costs 17-30ms synchronous. Batched version yields every 4 rows (~3.8ms/batch).
2. **Mesh generation** (`_generate_terrain_mesh_batched`): Must use small batch sizes (`MESH_ROWS_PER_BATCH = 2`, ~8ms/batch). Larger values (e.g., 6) cause 24ms+ spikes.
3. **Collision generation** (`_generate_box_collision_batched`): 256 BoxShape3D nodes. Batched at 4 rows/frame.

**Concurrency limiting** is critical: `MAX_CONCURRENT_HEAVY_GENERATIONS = 2` in `chunk_manager.gd` prevents multiple chunks' coroutines from overlapping in the same frame. Without this, 7 new chunks at a boundary crossing compound to 30-55ms/frame. The player's chunk always runs synchronously (height cache + collision) to prevent fall-through.

### Current Phase

See the bottom of `DEV_LOG.md` for the current development phase and planned tasks.

## Godot Development

For complex bugs involving interconnected systems (terrain, collision, caves, save/load), use a task agent to explore all files that interact with the affected system and map out their dependencies, then come back with a plan before making any changes. Don't jump straight to code.

When fixing bugs in Godot/GDScript, always verify that fixes don't introduce regressions in related systems. After each fix, check: 1) No dangling function references 2) No null value errors 3) Related gameplay mechanics still work. Run a mental 'blast radius' check before committing.

For iterative visual/geometry work (cave designs, structure art, UI layouts, loading screens), propose the approach and get user confirmation BEFORE implementing. When user reports visual issues, ask for specifics rather than guessing fixes. Expect 2-3 rounds of iteration minimum.

For performance optimization in Godot, always profile and identify ALL bottlenecks before fixing any single one. Don't declare victory after fixing one bottleneck - check for remaining issues (height cache, mesh batching, collision sync, async readiness). Prefer comprehensive fixes over incremental band-aids.

### Common GDScript Pitfalls

When editing GDScript files, be careful with: 1) Vector3 truthiness (use `vector != Vector3.ZERO` not `if vector`) 2) Dictionary `.has()` vs property access 3) Slot/index number mismatches between input handlers and inventory systems. Double-check these patterns.

## Workflow

After completing all changes for a task, always commit and push to main unless told otherwise. Use descriptive commit messages summarizing what was changed and why.

### Regression Tests

Before committing changes, run the regression test suite:
```
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --script tests/run_all_tests.gd
```
All tests must pass. If a test fails, fix the issue before committing. The suite covers:
- **Inventory** - add/remove/has/clear/edge cases
- **Crafting** - recipes, bench/level requirements, input consumption, output production
- **TerrainCollision** - box geometry, water slabs, pit prevention, chunk boundaries
- **StructureData** - footprints, item mappings, spacing rules, camp levels
- **CaveTransition** - respawn timing, save roundtrip, entry guards, scene paths
- **SaveLoad** - serialization roundtrips, field presence, JSON precision
- **UIConstants** - font size tiers, panel colors, text colors, font resource
