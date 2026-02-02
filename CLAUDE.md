# Claude Code Notes

## Project Overview

**Into the Wild** is a solo camping adventure game built in Godot 4.5 with GDScript. See `into-the-wild-game-spec.md` for the full game specification.

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

### Current Phase

See the bottom of `DEV_LOG.md` for the current development phase and planned tasks.
