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

### Code Style

- Godot 4.5 requires explicit type annotations (no Variant inference)
- Use `physical_keycode` for key detection (Mac compatibility)
- Prefer signals for decoupled communication between systems
- Add nodes to groups for raycast detection (`interactable`, `resource_node`)

### Current Phase

See the bottom of `DEV_LOG.md` for the current development phase and planned tasks.
