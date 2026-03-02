# Explorer's Journal Content Expansion — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Expand the Explorer's Journal from a single two-page spread into an 11-spread multi-page book with page-turning navigation, adventure diary entries, and a complete crafting recipe reference.

**Architecture:** Single-file rewrite of `scripts/ui/journal_ui.gd`. Replace the hardcoded `JOURNAL_TEXT` with a structured page data array. Add page navigation state (`_current_page`), input handling for d-pad/arrow keys, and a `_rebuild_pages()` method that tears down and rebuilds page content when turning pages. The book chrome (background, shadow, leather cover, spine) is built once; only the page content is rebuilt on turn.

**Tech Stack:** GDScript (Godot 4.5), programmatic UI via CanvasLayer

**Design doc:** `docs/plans/2026-03-01-explorer-journal-content-design.md`

**Note:** Testing is SUSPENDED per CLAUDE.md. No test steps included.

---

### Task 1: Define page data structure and navigation state

**Files:**
- Modify: `scripts/ui/journal_ui.gd:1-31` (top of file — constants and state vars)

Replace `JOURNAL_TEXT` with a structured page data array and add navigation state.

**Step 1: Replace constants and add state variables**

Remove the `JOURNAL_TEXT` constant (lines 13-30). Add these new members after the existing `_is_open` var:

```gdscript
var _current_page: int = 0
var _total_pages: int = 0

# Page content containers (rebuilt on page turn)
var _left_vbox: VBoxContainer
var _right_vbox: VBoxContainer
var _nav_label: Label
```

**Step 2: Add the page data method**

Add a new method `_get_pages()` that returns an Array of Dictionaries. Each dictionary represents one spread with keys:
- `left_title`: String (optional, shown as header on left page — e.g. "Day 1" or "Hand Crafting")
- `left_text`: String (left page body text)
- `right_text`: String (right page body text)
- `is_title_page`: bool (true only for spread 1, triggers special title layout)
- `is_recipe_page`: bool (true for spreads 7-11, triggers recipe formatting with bullet-style lines)

The method should return all 11 spreads. Write the full content for **spread 1 only** in this task (title page + Day 1). Use placeholder text `"[CONTENT TODO]"` for spreads 2-11 — they'll be filled in Task 4.

**Spread 1 content:**

Left page (title page):
```
is_title_page = true
left_title = "Explorer's Journal"
left_text = "A Record of the Carlston Wilderness\n\n~ ~ ~\n\nProperty of E.W. Carlston"
```

Right page (Day 1):
```
right_text = "Day 1\n\nI arrived at the edge of the Carlston Wilderness this morning with little more than my boots and a good feeling. The forest here is beautiful — birch and pine standing so close together they form a kind of cathedral. Found a clear pond not far from where I set up camp. Fish rising at dusk. If I can rig a fishing rod, dinner is sorted.\n\nRabbits everywhere. Birds calling from every direction. The air smells like pine needles after rain. I've decided to map this whole place, every last corner of it. Something tells me it's worth the effort."
```

**Step 3: Initialize page count in `open_journal()`**

In `open_journal()`, after setting `_is_open = true`, add:
```gdscript
_current_page = 0
_total_pages = _get_pages().size()
```

**Step 4: Commit**

```bash
git add scripts/ui/journal_ui.gd
git commit -m "Add journal page data structure and navigation state"
```

---

### Task 2: Refactor _build_ui into chrome + page content

**Files:**
- Modify: `scripts/ui/journal_ui.gd:48-236` (the `_build_ui` method)

Split `_build_ui()` into two concerns:
1. `_build_ui()` — builds the permanent book chrome (background, shadow, leather cover, spine, empty page containers) and calls `_populate_page()`
2. `_populate_page()` — fills the left and right page VBoxContainers with content from `_get_pages()[_current_page]`

**Step 1: Refactor _build_ui()**

Keep all the chrome-building code (lines 48-191 — background, shadow, leather cover panel, HBox, left page PanelContainer, spine, right page PanelContainer). But instead of adding content labels directly:

- Store `left_vbox` in `_left_vbox` (the instance variable)
- Store `right_vbox` in `_right_vbox`
- After `add_child(panel)`, call `_populate_page()`

Remove all the label-creation code from `_build_ui()` (title, rule, flourish, day label, left body, right body, hint label — lines 137-233). That logic moves to `_populate_page()`.

**Step 2: Write _populate_page()**

New method that:
1. Clears all children from `_left_vbox` and `_right_vbox`
2. Gets `var page: Dictionary = _get_pages()[_current_page]`
3. Loads font and computes scale factor (same as `_build_ui`)
4. Sets ink color: `Color(0.18, 0.12, 0.06)`

**Left page logic:**
- If `page.is_title_page`:
  - Add title label: `page.left_title`, centered, 40px, darker ink color `Color(0.30, 0.18, 0.06)`
  - Add horizontal rule (ColorRect, 2px height, `Color(0.45, 0.32, 0.15, 0.6)`)
  - Add body label: `page.left_text`, centered, 24px, `Color(0.45, 0.32, 0.15, 0.7)`, expand fill
- Else if `page.is_recipe_page`:
  - Add header label: `page.left_title`, centered, 32px, `Color(0.30, 0.18, 0.06)`
  - Add horizontal rule
  - Add body label: `page.left_text`, autowrap, 20px (slightly smaller for recipe density), ink color, expand fill
- Else (diary page):
  - Add header label: `page.left_title` (e.g. "Day 5"), centered, 32px, ink color
  - Add horizontal rule
  - Add body label: `page.left_text`, autowrap, 22px, ink color, expand fill

**Right page logic:**
- Add body label: `page.right_text`, autowrap, same font size as left page (20px for recipe, 22px for diary), ink color, expand fill
- Add navigation bar at bottom (see below)

**Navigation bar (bottom of right page):**
- Create an HBoxContainer
- Left side: if `_current_page > 0`, add label `"< Prev"` in hint color `Color(0.45, 0.32, 0.15, 0.5)`, 18px
- Center: add label `"Page N of M"` (using `_current_page + 1` and `_total_pages`), centered, hint color, 18px — store in `_nav_label`
- Right side: if `_current_page < _total_pages - 1`, add label `"Next >"` in hint color, 18px
- Below the HBox: add close/nav hint label. Check InputManager for controller:
  - Controller: `"D-Pad: turn pages  |  X: close"`
  - Keyboard: `"Arrows: turn pages  |  ESC / B: close"`

**Step 3: Commit**

```bash
git add scripts/ui/journal_ui.gd
git commit -m "Refactor journal UI into chrome + paginated content"
```

---

### Task 3: Add page-turning input handling

**Files:**
- Modify: `scripts/ui/journal_ui.gd` — the `_input()` method (lines 239-259)

**Step 1: Add page turn handling to _input()**

In `_input()`, before the close-check logic, add page turn detection:

```gdscript
# Page turning — d-pad left/right or arrow keys
if event.is_action_pressed("ui_left"):
    if _current_page > 0:
        _current_page -= 1
        _populate_page()
    var vp: Viewport = get_viewport()
    if vp:
        vp.set_input_as_handled()
    return

if event.is_action_pressed("ui_right"):
    if _current_page < _total_pages - 1:
        _current_page += 1
        _populate_page()
    var vp: Viewport = get_viewport()
    if vp:
        vp.set_input_as_handled()
    return
```

This goes before the close-button checks so page turns are handled first. `ui_left` and `ui_right` map to d-pad left/right on controller and arrow keys on keyboard by default in Godot.

**Step 2: Commit**

```bash
git add scripts/ui/journal_ui.gd
git commit -m "Add page-turning input for d-pad and arrow keys"
```

---

### Task 4: Write all journal content (spreads 2-11)

**Files:**
- Modify: `scripts/ui/journal_ui.gd` — the `_get_pages()` method

Replace all `"[CONTENT TODO]"` placeholders with the final content from the design doc. This is the largest task but is purely data entry — no logic changes.

**Step 1: Write diary spreads 2-6**

Fill in the content for these spreads using the approved text from the design doc (`docs/plans/2026-03-01-explorer-journal-content-design.md`):

- **Spread 2** — Day 5: The Forest & First Crafting (`is_title_page = false, is_recipe_page = false`)
- **Spread 3** — Day 12: The Rocky Highlands & Caves
- **Spread 4** — Day 20: The Desert Ring & Oases
- **Spread 5** — Day 31: Mountain Peaks & The Glider
- **Spread 6** — Day 47: The Sinkhole & Final Words

**Step 2: Write recipe spreads 7-11**

Fill in the content for these spreads (`is_recipe_page = true`):

- **Spread 7** — "Hand Crafting" — left_title: `"Field Notes: Hand Crafting"`, recipes listed with bullet format:
  ```
  Primitive Axe — 1 river rock, 1 branch
  Stone Axe — 2 river rocks, 1 branch
  Torch — 2 branches
  Plant Rope — 3 branches
  ```
  Right page continues:
  ```
  Split Branches — 1 wood log (yields 4)
  Campfire Kit — 4 branches, 3 river rocks
  Crafting Bench Kit — 6 wood, 4 branches
  ```
  Plus flavor text about the crafting bench.

- **Spread 8** — "Getting Established" (Bench, Camp Level 1)
- **Spread 9** — "Expanding Your Range" (Bench, Camp Level 2)
- **Spread 10** — "Advanced Crafting" (Bench, Camp Level 3, first half)
- **Spread 11** — "Rare & Extraordinary" (Bench, Camp Level 3, second half + hang glider + end flourish)

Use the exact recipe ingredients from `scripts/crafting/crafting_system.gd` to ensure accuracy. Cross-reference every recipe name and ingredient count.

**Step 3: Commit**

```bash
git add scripts/ui/journal_ui.gd
git commit -m "Add all journal diary entries and crafting recipe content"
```

---

### Task 5: Manual playtesting and polish

**Files:**
- Modify: `scripts/ui/journal_ui.gd` (if adjustments needed)

**Step 1: Verify in-game**

Launch the game and open the journal. Check:
- [ ] Title page displays correctly with centered title and subtitle
- [ ] All 11 spreads are navigable with d-pad left/right and arrow keys
- [ ] Page indicator shows correct "Page N of 11"
- [ ] Navigation hints show correct controller/keyboard text
- [ ] Text fits within page bounds on all spreads (no overflow or clipping)
- [ ] Recipe pages are readable with ingredient lists
- [ ] Close button still works (ESC, B, X on controller)
- [ ] Game pauses while journal is open and resumes on close
- [ ] First-read rewards still trigger correctly
- [ ] Journal can be re-opened from equipment after first read

**Step 2: Adjust font sizes if needed**

If any spread's text overflows the page, reduce font size for that page type:
- Diary pages: try 20px instead of 22px
- Recipe pages: try 18px instead of 20px
- Or trim text slightly to fit

**Step 3: Final commit**

```bash
git add scripts/ui/journal_ui.gd
git commit -m "Polish journal layout and text fitting"
```

---

### Task 6: Update DEV_LOG.md

**Files:**
- Modify: `DEV_LOG.md`

**Step 1: Add session entry**

Add a new session entry documenting:
- Expanded Explorer's Journal from 1 spread to 11 spreads
- Added page-turning navigation (d-pad/arrow keys)
- 6 adventure diary entries telling E.W. Carlston's story in the Carlston Wilderness
- 5 recipe reference pages covering all 34 crafting recipes
- Page indicator and navigation hints (controller + keyboard)
- List modified files: `scripts/ui/journal_ui.gd`

**Step 2: Commit**

```bash
git add DEV_LOG.md
git commit -m "Update DEV_LOG with journal content expansion session"
```
