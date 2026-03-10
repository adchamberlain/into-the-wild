# iPad Port Design Spec

## Overview

Add iPad support to Into the Wild as a separate build target from the same codebase. The game runs in landscape-only mode with touch controls, a scaled-down HUD, and distribution through the Apple App Store as a free app.

## Approach

**Platform Abstraction Layer** — single codebase with `OS.get_name() == "iOS"` checks that swap in touch controls and mobile HUD adjustments. All changes are additive; desktop/Windows builds are unaffected.

## Touch Controls

### Layout (Landscape)

**Left side:**
- Virtual joystick (bottom-left, ~130px diameter) — forward/back/strafe, no turning
- Semi-transparent: background 6% alpha, border 15% alpha, text 35% alpha

**Right side:**
- Swipe-to-look zone covers the entire right half of the screen
- Swiping left/right turns the player, swiping up/down looks up/down

**Always-visible action buttons (bottom-right, vertical stack):**
- JUMP — white tint
- SPRINT — blue tint
- ACT (interact) — gold tint
- All 56px diameter, uniform 12px gaps, highly transparent (6% bg, 15% border, 40% text)

**Context-sensitive buttons:**
- USE — appears directly below the equipped item panel (top-right) when an item is equipped. Dashed border.
- EAT — appears directly beside the health/hunger bars (top-left) when player has food. Dashed border.
- CROUCH — appears near cliff edges only. Dashed border, positioned near the core action buttons.
- All context buttons are same 56px size and transparency as core buttons.

**Menu access (top row, right of center):**
- Inventory (🎒), Crafting (⚒️), Pause (⏸️) as 36px icon buttons with dark semi-transparent backgrounds

### Architecture

**New files:**
- `scenes/ui/touch_controls.tscn` — CanvasLayer (layer 61, above HUD)
- `scripts/ui/touch_controls.gd` — all touch input logic

**Components within touch_controls.gd:**
1. **VirtualJoystick** — handles `InputEventScreenTouch` / `InputEventScreenDrag` in left zone. Outputs Vector2 direction mapped to `move_forward`, `move_back`, `move_left`, `move_right` actions via `Input.action_press()` / `Input.action_release()`.
2. **SwipeLookZone** — any touch/drag outside joystick and button areas. Calls `apply_touch_look(delta_x, delta_y)` on player_controller.
3. **ActionButtons** — each fires `Input.action_press()` / `Input.action_release()` so existing game code works unchanged.
4. **ContextManager** — listens for signals (player has food, player near cliff, player has equipped item) to show/hide conditional buttons.

**Changes to existing files:**
- `scripts/systems/input_manager.gd` — add `TOUCH` device type and `var using_touch: bool`. Add `InputEventScreenTouch` / `InputEventScreenDrag` detection to `_input()` to set `using_touch = true` (and `using_controller = false`). Add `TOUCH_PROMPTS` dictionary with mappings like `"interact": "Tap ACT"`, `"jump": "Tap JUMP"`, etc. Update `get_prompt()` to check `using_touch` before returning prompts. On iOS, initialize `using_touch = true` at startup since touch is always the primary input.
- `scripts/player/player_controller.gd` — add `apply_touch_look(delta_x: float, delta_y: float)` method for touch camera rotation. Add sensitivity setting for touch.
- `scenes/main.tscn` or autoload — instantiate `touch_controls.tscn` only when `OS.get_name() == "iOS"`

**No other scripts need changes** — they all use `Input.is_action_pressed()` which works regardless of input source.

## HUD Adaptations

### Mobile flag

Add `var is_mobile: bool` in `hud.gd`, set from `OS.get_name() == "iOS"`.

### Scaling

Define explicit mobile font size tiers (not a blanket multiplier, to avoid conflicting with the UIConstants regression test which validates desktop tiers):

- **Titles/Headlines:** 36-42px (desktop: 56-64px)
- **Primary labels:** 26-32px (desktop: 40-48px)
- **Secondary info:** 20-26px (desktop: 32-40px)
- **Hints/Small text:** 18-22px (desktop: 28-32px)

The UIConstants test should only validate desktop font tiers. Mobile tiers are a separate spec and should get their own test.

Panel padding/margins scale proportionally (~65% of desktop values).

### Layout changes on iPad

- **Inventory panel hidden** — accessed only via 🎒 menu button (full-screen overlay)
- **Equipped item panel** — top-right, shows item name + ◀ ▶ cycle arrows (replaces L1/R1)
- **Menu icon buttons** — 🎒 ⚒️ ⏸️ row, top, right of center
- **Safe area insets** — query `DisplayServer.get_display_safe_area()` (returns `Rect2i` in screen pixels) at startup and on orientation change. Apply as margins to the root HUD MarginContainer: `margin_left = safe.position.x`, `margin_top = safe.position.y`, `margin_right = screen_width - (safe.position.x + safe.size.x)`, `margin_bottom = screen_height - (safe.position.y + safe.size.y)`. The touch_controls CanvasLayer applies the same insets to its button positioning. On non-iOS platforms, safe area is the full screen (zero insets).
- Stats panel, time panel, interaction prompt, notifications, celebrations — same structure, just scaled

### Unchanged on iPad

- Compass widget
- Heat indicator
- Coca leaf buff timer
- Air bubbles (drowning)
- POI cycling
- Sandstorm overlay

## Menu Touch Adaptation

All existing menus (crafting, inventory, equipment, food, storage, fire, pause, config) stay as full-screen overlays.

**Changes:**
- Enforce 44x44pt minimum tap targets (Apple HIG)
- Apply `is_mobile` font scaling
- Add explicit close/X button to each menu (replaces Esc/touchpad key)
- Disable D-pad focus navigation on iPad (tap directly selects)
- Hide system cursor on iOS
- Verify crafting recipe list uses ScrollContainer for swipe-to-scroll

**No structural changes** — same scenes, same scripts, sizing adjustments and close buttons gated behind `is_mobile`.

## Day Counter (All Platforms)

New HUD feature added to all platforms during this work:

- Use existing `time_manager.current_day` (already tracked, already saved as `"day"` in save data) — no new state variable needed
- Display in the time panel below time and period: "Day X" in gold/yellow color
- Separate from camp level day counter ("Day 1 of 3") which tracks progress toward next camp level
- Simply a HUD addition reading an existing value

## Build & Distribution

### Export

- Use existing iOS export preset (preset.3) in `export_presets.cfg`
- Fill in Team ID: `KAL9468P2B` (same as Sky Checker)
- Download Godot 4.5 iOS export templates
- Set `export_path` in preset.3 to `build/ios/IntoTheWild` before exporting (currently blank)
- Export command: `Godot --headless --export-release "iOS" build/ios/IntoTheWild`
- Note: Godot iOS export produces an Xcode project directory structure, not a single file

### Xcode Configuration

- Orientation: landscape-only
- Device family: iPad only (family 2)
- Deployment target: iOS 14.0
- Bundle ID: `com.andrewchamberlain.IntoTheWildGame`
- Automatic signing (same as Sky Checker)
- App icon: 1024x1024 universal
- Launch storyboard for iPad

### App Store

- Create new App ID in App Store Connect
- Free app, no IAP
- Category: Games > Adventure or Simulation
- Privacy policy (no data collection)
- iPad screenshots: 2048x2732 (12.9" Pro), 2048x1536 (standard)
- Create APP_STORE_METADATA.md following Sky Checker's pattern
- TestFlight first for hands-on testing

### Privacy

- `PrivacyInfo.xcprivacy` with no data collection, no tracking
- Simpler than Sky Checker (no location permission needed)

## Testing

New test files to create and register in `tests/run_all_tests.gd`:

- **`tests/test_touch_controls.gd`** — joystick direction mapping (Vector2 output for cardinal/diagonal inputs), touch zone boundary classification (given a screen position, correctly identifies joystick zone vs. swipe zone vs. button zone), dead zone behavior (small inputs below threshold produce zero movement)
- **`tests/test_mobile_hud.gd`** — `is_mobile` flag correctly gates inventory panel visibility, mobile font size tiers are within specified ranges, safe area margin calculation produces correct values for sample `Rect2i` inputs, day counter label shows correct value from `time_manager.current_day`
- **`tests/test_input_manager_touch.gd`** — `using_touch` flag activates correctly, `get_prompt()` returns touch prompts when `using_touch` is true, device type transitions (touch → controller → touch) work correctly

## Out of Scope

- iPhone support (iPad only for v1)
- Hotbar / quick-slot system (keep single equipped item with cycle)
- Customizable button positions (v1 uses fixed layout)
- CI/CD automation for iOS builds (manual Xcode submission)
- Game Center integration
- iCloud save sync
