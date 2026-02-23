# Sky Improvements: Blocky Clouds & Horizon Haze

**Date**: 2026-02-23
**Status**: Approved

## Overview

Add blocky voxel-style clouds and a horizon haze band to make the sky more realistic and immersive. Clouds integrate fully with the weather system. Heat wave remains cloudless (realistic). All other weather types show appropriate cloud coverage.

## Cloud System

### Architecture

New file: `scripts/world/cloud_manager.gd`, child of `EnvironmentManager`.

**Cloud clusters**: Node3D groups of 4-8 overlapping BoxMesh instances creating puffy rectangular shapes.
- Base box: ~12x2x8 units
- 3-7 additional boxes offset on top/sides, sizes 4x1.5x4 to 8x2.5x6
- All boxes share a static StandardMaterial3D (unshaded, transparency enabled)

**Cloud pool**: Pre-create ~30 clusters at `_ready()`. Enable/disable based on weather.

**Altitude**: 100 units above player Y.

**Movement**: Drift at 2-7 u/s in a consistent wind direction (randomized per weather change). Wrap when exiting ~250 unit radius from player.

**Player-relative**: Container follows player XZ.

### Weather Integration

| Weather   | Active Clouds | Color                        | Alpha | Speed   |
|-----------|--------------|------------------------------|-------|---------|
| Clear     | 6-10         | White (0.95, 0.95, 0.97)    | 0.7   | 2-3 u/s |
| Rain      | 15-20        | Gray (0.6, 0.6, 0.65)       | 0.85  | 3-4 u/s |
| Storm     | 25-30        | Dark gray (0.35, 0.35, 0.4) | 0.95  | 5-7 u/s |
| Fog       | 4-6          | Pale (0.8, 0.8, 0.82)       | 0.4   | 1-2 u/s |
| Heat Wave | 0            | --                           | --    | --      |
| Cold Snap | 8-12         | Ice (0.85, 0.88, 0.95)      | 0.6   | 2-3 u/s |

**Transitions**: Tween alpha and enable/disable clusters over 3 seconds.

**Time-of-day tinting**: Clouds pick up ambient sky color — warmer at dawn/dusk, blue at night, reduced alpha at night for star visibility.

## Horizon Haze

Lives in `environment_manager.gd` alongside existing sky code.

**Mesh**: Inverted CylinderMesh, radius ~400 units, height ~60 units, bottom at horizon.

**Material**: ShaderMaterial with vertical gradient (solid at bottom, transparent at top).

**Time-of-day colors**:
- Dawn: (1.0, 0.6, 0.4), alpha 0.3
- Day: (0.7, 0.8, 0.95), alpha 0.15
- Dusk: (0.95, 0.45, 0.3), alpha 0.35
- Night: (0.1, 0.1, 0.25), alpha 0.1

**Weather**: Fog increases alpha to 0.5, storm darkens, heat wave adds warm tint.

**Follows player**: Tracks XZ position like clouds.

## Performance

- Shared static materials for all cloud boxes (no per-instance allocation)
- Pool of pre-created clusters avoids runtime Node creation
- Horizon haze is a single mesh + single shader
- Total additional draw calls: ~30 cloud clusters + 1 haze cylinder
