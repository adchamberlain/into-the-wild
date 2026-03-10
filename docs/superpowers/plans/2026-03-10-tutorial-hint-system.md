# Tutorial Hint System Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a minimal, ambient tutorial hint system that teaches new players through one-time contextual messages.

**Architecture:** New `HintManager` autoload owns all hint definitions, seen-state tracking, and queue logic. Game systems call `HintManager.try_show("hint_id")` at trigger points. HUD gets a new `show_hint()` method with gold-bordered "SURVIVAL TIP" presentation. Seen hints persist per save slot.

**Tech Stack:** Godot 4.5, GDScript

**Spec:** `docs/superpowers/specs/2026-03-10-tutorial-hint-system-design.md`

---

## Chunk 1: Core HintManager + Tests

### Task 1: Create test file for HintManager

**Files:**
- Create: `tests/test_hint_manager.gd`

- [ ] **Step 1: Write the test file with core tests**

```gdscript
extends "res://tests/test_base.gd"
## Tests for HintManager - hint display logic, seen tracking, queue, config, loading guard.

func run_tests() -> Dictionary:
	set_test_name("HintManager")

	test_try_show_marks_seen()
	test_hint_not_shown_twice()
	test_loading_guard_suppresses()
	test_loading_guard_does_not_mark_seen()
	test_config_disabled_suppresses()
	test_config_disabled_does_not_mark_seen()
	test_get_set_seen_hints()
	test_clear_seen_hints()
	test_unknown_hint_ignored()
	test_queue_ordering()

	return get_results()


func test_try_show_marks_seen() -> void:
	var hm: HintManager = HintManager.new()
	hm._is_loading = false
	hm._hints_enabled = true
	hm.try_show("first_gather")
	assert_true(hm.has_seen("first_gather"), "hint marked as seen after try_show")
	hm.free()


func test_hint_not_shown_twice() -> void:
	var hm: HintManager = HintManager.new()
	hm._is_loading = false
	hm._hints_enabled = true
	hm.try_show("first_gather")
	var queue_size_after_first: int = hm._queue.size()
	hm.try_show("first_gather")
	var queue_size_after_second: int = hm._queue.size()
	# Second call should not add to queue (already seen)
	assert_equal(queue_size_after_second, queue_size_after_first, "duplicate hint not queued")
	hm.free()


func test_loading_guard_suppresses() -> void:
	var hm: HintManager = HintManager.new()
	hm._is_loading = true
	hm._hints_enabled = true
	hm.try_show("first_gather")
	assert_equal(hm._queue.size(), 0, "hint not queued during loading")
	hm.free()


func test_loading_guard_does_not_mark_seen() -> void:
	var hm: HintManager = HintManager.new()
	hm._is_loading = true
	hm._hints_enabled = true
	hm.try_show("first_gather")
	assert_false(hm.has_seen("first_gather"), "hint not marked seen during loading")
	hm.free()


func test_config_disabled_suppresses() -> void:
	var hm: HintManager = HintManager.new()
	hm._is_loading = false
	hm._hints_enabled = false
	hm.try_show("first_gather")
	assert_equal(hm._queue.size(), 0, "hint not queued when disabled")
	hm.free()


func test_config_disabled_does_not_mark_seen() -> void:
	var hm: HintManager = HintManager.new()
	hm._is_loading = false
	hm._hints_enabled = false
	hm.try_show("first_gather")
	assert_false(hm.has_seen("first_gather"), "hint not marked seen when disabled")
	hm.free()


func test_get_set_seen_hints() -> void:
	var hm: HintManager = HintManager.new()
	hm.set_seen_hints(["first_gather", "first_craft"])
	assert_true(hm.has_seen("first_gather"), "restored hint is seen")
	assert_true(hm.has_seen("first_craft"), "restored hint is seen")
	assert_false(hm.has_seen("first_weather"), "non-restored hint is not seen")
	var saved: Array[String] = hm.get_seen_hints()
	assert_equal(saved.size(), 2, "get_seen_hints returns correct count")
	hm.free()


func test_clear_seen_hints() -> void:
	var hm: HintManager = HintManager.new()
	hm._is_loading = false
	hm._hints_enabled = true
	hm.try_show("first_gather")
	hm.clear_seen_hints()
	assert_false(hm.has_seen("first_gather"), "seen hints cleared")
	hm.free()


func test_unknown_hint_ignored() -> void:
	var hm: HintManager = HintManager.new()
	hm._is_loading = false
	hm._hints_enabled = true
	hm.try_show("nonexistent_hint_id")
	assert_equal(hm._queue.size(), 0, "unknown hint not queued")
	hm.free()


func test_queue_ordering() -> void:
	var hm: HintManager = HintManager.new()
	hm._is_loading = false
	hm._hints_enabled = true
	hm.try_show("first_gather")
	hm.try_show("first_craft")
	assert_equal(hm._queue.size(), 2, "both hints queued")
	assert_equal(hm._queue[0], "first_gather", "first hint queued first")
	assert_equal(hm._queue[1], "first_craft", "second hint queued second")
	hm.free()
```

- [ ] **Step 2: Register test in run_all_tests.gd**

In `tests/run_all_tests.gd`, add to the `test_files` array (around line 26):

```gdscript
"res://tests/test_hint_manager.gd",
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --script tests/run_all_tests.gd`
Expected: FAIL — `HintManager` class does not exist yet.

---

### Task 2: Create HintManager autoload

**Files:**
- Create: `scripts/ui/hint_manager.gd`
- Modify: `project.godot:23-29` (autoload section)

- [ ] **Step 1: Create hint_manager.gd**

```gdscript
extends Node
class_name HintManager
## Manages tutorial hints — one-time contextual tips shown to new players.
## Registered as autoload. Game systems call try_show("hint_id") at trigger points.

## Hint definitions: id -> { message, color }
## Messages use BBCode [color=gold]...[/color] for key term highlighting.
const HINTS: Dictionary = {
	"first_gather": {
		"message": "You gathered your first resource! Look for [color=#ffda4d]sticks[/color] and [color=#ffda4d]stones[/color] nearby — you'll need them to craft tools.",
	},
	"first_craft": {
		"message": "Nice work! Open the [color=#ffda4d]Crafting Menu (C)[/color] anytime to see what else you can build.",
	},
	"hunger_low": {
		"message": "Your hunger is getting low. [color=#ffda4d]Fish[/color] at a pond, gather [color=#ffda4d]berries[/color], or [color=#ffda4d]cook meat[/color] at a fire pit to eat.",
	},
	"first_fire_pit": {
		"message": "Your fire pit is ready! You can [color=#ffda4d]cook food[/color] here. Next up: build a [color=#ffda4d]Shelter[/color] to protect yourself from storms.",
	},
	"first_shelter": {
		"message": "Shelter built! You'll take less damage during storms now. Keep building — more structures help [color=#ffda4d]level up your camp[/color].",
	},
	"first_weather": {
		"message": "Weather is changing! [color=#ffda4d]Storms[/color] deal damage when exposed, [color=#ffda4d]cold snaps[/color] drain hunger faster, and [color=#ffda4d]heat waves[/color] are brutal. Seek shelter!",
	},
	"first_fish": {
		"message": "Fresh catch! Fish can be [color=#ffda4d]eaten raw[/color] in a pinch, but [color=#ffda4d]cooking[/color] at a fire pit gives much more nutrition.",
	},
	"camp_level_2_hint": {
		"message": "Your camp is growing! Build a [color=#ffda4d]Fire Pit[/color], [color=#ffda4d]Shelter[/color], [color=#ffda4d]Crafting Bench[/color], [color=#ffda4d]Drying Rack[/color], and craft a [color=#ffda4d]Fishing Rod[/color] to reach Camp Level 2.",
	},
	"camp_level_2_up": {
		"message": "Camp Level 2 unlocked! You can now build a [color=#ffda4d]Canvas Tent[/color] and [color=#ffda4d]Herb Garden[/color]. Keep going for Level 3!",
	},
	"first_bow": {
		"message": "You have a bow! [color=#ffda4d]Equip it[/color] and use it to hunt [color=#ffda4d]rabbits[/color] and [color=#ffda4d]birds[/color] for meat. Aim carefully — arrows are precious.",
	},
	"swim_warning": {
		"message": "You can swim, but watch your [color=#ffda4d]air bubbles[/color] underwater! Surface before they run out or you'll take damage.",
	},
	"fall_warning": {
		"message": "Ouch! Long falls deal damage. Watch your step near cliffs and ledges.",
	},
	"desert_entry": {
		"message": "The desert is scorching! [color=#ffda4d]Heat[/color] drains your hunger faster out here. Watch out for [color=#ffda4d]cactuses[/color] — they hurt on contact.",
	},
	"first_rare_resource": {
		"message": "Rare find! These materials unlock [color=#ffda4d]advanced recipes[/color] at the Crafting Bench — powerful tools and equipment.",
	},
	"first_machete": {
		"message": "Machete ready! Use it to [color=#ffda4d]cut through thick vegetation[/color] and access areas you couldn't reach before.",
	},
	"first_hang_glider": {
		"message": "Hang glider equipped! [color=#ffda4d]Jump from high ground[/color] and hold jump to glide. Use [color=#ffda4d]sprint[/color] mid-air for a speed boost.",
	},
	"first_cabin": {
		"message": "Your cabin is complete! Sleep in the [color=#ffda4d]bed[/color] to skip to morning, and use the [color=#ffda4d]kitchen[/color] for advanced recipes.",
	},
	"deep_well_discovery": {
		"message": "There's something at the bottom of this well... but it's far too deep to swim. Maybe there's [color=#ffda4d]another way down[/color].",
	},
}

## Rare resource types that trigger the "first_rare_resource" hint.
const RARE_RESOURCES: Array[String] = ["diamond", "opal", "crystal", "rare_ore", "iron_ore"]

## Items that trigger equipment-specific hints on inventory add.
const ITEM_HINTS: Dictionary = {
	"bow": "first_bow",
	"enchanted_bow": "first_bow",
	"machete": "first_machete",
	"hang_glider": "first_hang_glider",
}

## Time between queued hints in seconds.
const QUEUE_SPACING: float = 4.0

## Seen hints for the current save slot.
var _seen_hints: Array[String] = []

## Pending hint queue (FIFO).
var _queue: Array[String] = []

## Whether hints are enabled in config.
var _hints_enabled: bool = true

## Loading guard — true during save data restoration.
var _is_loading: bool = false

## Whether the queue processor is currently active.
var _processing_queue: bool = false


func try_show(hint_id: String) -> void:
	if _is_loading:
		return
	if not _hints_enabled:
		return
	if not HINTS.has(hint_id):
		return
	if hint_id in _seen_hints:
		return

	_seen_hints.append(hint_id)
	_queue.append(hint_id)

	if not _processing_queue:
		_process_queue()


func _process_queue() -> void:
	_processing_queue = true
	while _queue.size() > 0:
		var hint_id: String = _queue.pop_front()
		var hint_data: Dictionary = HINTS[hint_id]
		_display_hint(hint_data["message"])
		if _queue.size() > 0:
			await get_tree().create_timer(QUEUE_SPACING).timeout
	_processing_queue = false


func _display_hint(message: String) -> void:
	var hud: Node = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_hint"):
		hud.show_hint(message)


func has_seen(hint_id: String) -> bool:
	return hint_id in _seen_hints


func get_seen_hints() -> Array[String]:
	return _seen_hints.duplicate()


func set_seen_hints(hints: Array) -> void:
	_seen_hints.clear()
	for h: String in hints:
		_seen_hints.append(h)


func clear_seen_hints() -> void:
	_seen_hints.clear()


func set_loading(loading: bool) -> void:
	_is_loading = loading


func set_hints_enabled(enabled: bool) -> void:
	_hints_enabled = enabled
```

- [ ] **Step 2: Register autoload in project.godot**

In `project.godot`, add to the `[autoload]` section (after the CaveTransition line):

```
HintManager="*res://scripts/ui/hint_manager.gd"
```

- [ ] **Step 3: Run tests to verify they pass**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --script tests/run_all_tests.gd`
Expected: All HintManager tests PASS. All existing tests still PASS.

- [ ] **Step 4: Commit**

```bash
git add scripts/ui/hint_manager.gd project.godot tests/test_hint_manager.gd tests/run_all_tests.gd
git commit -m "Add HintManager autoload with hint definitions, queue logic, and tests"
```

---

## Chunk 2: HUD Hint Display

### Task 3: Add show_hint() method to HUD

**Files:**
- Modify: `scripts/ui/hud.gd:58-60` (add hint panel variables)
- Modify: `scripts/ui/hud.gd:267-269` (hide hint panel on init)
- Modify: `scripts/ui/hud.gd:842-844` (add show_hint/hide_hint after notification methods)

- [ ] **Step 1: Add hint panel member variables**

After the notification variables (line 60 in `scripts/ui/hud.gd`), add:

```gdscript
# Tutorial hint panel (built programmatically)
var hint_panel: PanelContainer = null
var hint_label: RichTextLabel = null
var _hint_timer: SceneTreeTimer = null
```

- [ ] **Step 2: Create hint panel in _ready()**

Add a new method `_create_hint_panel()` and call it from `_ready()`. Insert the call near line 269 (after hiding notification panel). The method builds the hint panel programmatically:

```gdscript
func _create_hint_panel() -> void:
	var font: Font = load("res://resources/hud_font.tres")

	hint_panel = PanelContainer.new()
	hint_panel.name = "HintPanel"

	# Gold-bordered dark panel
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12, 0.85)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(1, 0.85, 0.3, 0.3)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	hint_panel.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	hint_panel.add_child(vbox)

	# Header label
	var header: Label = Label.new()
	header.text = "SURVIVAL TIP"
	header.add_theme_font_override("font", font)
	header.add_theme_font_size_override("font_size", 32)
	header.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)

	# Body label (RichTextLabel for BBCode color tags)
	hint_label = RichTextLabel.new()
	hint_label.bbcode_enabled = true
	hint_label.fit_content = true
	hint_label.scroll_active = false
	hint_label.add_theme_font_override("normal_font", font)
	hint_label.add_theme_font_size_override("normal_font_size", 28)
	hint_label.add_theme_color_override("default_color", Color(0.9, 0.9, 0.9, 1))
	hint_label.custom_minimum_size.x = 500
	vbox.add_child(hint_label)

	# Position: center-top, below the notification panel
	hint_panel.anchors_preset = Control.PRESET_CENTER_TOP
	hint_panel.anchor_top = 0.0
	hint_panel.anchor_bottom = 0.0
	hint_panel.anchor_left = 0.5
	hint_panel.anchor_right = 0.5
	hint_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hint_panel.offset_top = 120  # Below notification panel area
	hint_panel.visible = false
	hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(hint_panel)
```

- [ ] **Step 3: Add show_hint() and _hide_hint() methods**

Insert after `_hide_notification()` (after line 844 in `scripts/ui/hud.gd`):

```gdscript
## Show a tutorial hint with gold "SURVIVAL TIP" header. Uses BBCode for highlighting.
func show_hint(message: String) -> void:
	if not is_inside_tree():
		return
	if hint_panel and hint_label:
		hint_label.text = message
		hint_panel.visible = true
		hint_panel.modulate.a = 0.0
		# Fade in
		var tween: Tween = create_tween()
		tween.tween_property(hint_panel, "modulate:a", 1.0, 0.3)
		# Cancel previous hint timer
		if _hint_timer and _hint_timer.time_left > 0 and _hint_timer.timeout.is_connected(_hide_hint):
			_hint_timer.timeout.disconnect(_hide_hint)
		# Duration: 8s base + 1s per line
		var line_count: int = message.count("\n") + 1
		var duration: float = 8.0 + max(0, line_count - 1) * 1.0
		_hint_timer = get_tree().create_timer(duration)
		_hint_timer.timeout.connect(_hide_hint)


func _hide_hint() -> void:
	if hint_panel:
		var tween: Tween = create_tween()
		tween.tween_property(hint_panel, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func() -> void: hint_panel.visible = false)
```

- [ ] **Step 4: Call _create_hint_panel() from _ready()**

In `_ready()`, after the line that hides the notification panel (around line 269), add:

```gdscript
	# Create tutorial hint panel
	_create_hint_panel()
```

- [ ] **Step 5: Run tests to verify nothing is broken**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --script tests/run_all_tests.gd`
Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add scripts/ui/hud.gd
git commit -m "Add show_hint() method to HUD with gold SURVIVAL TIP panel"
```

---

## Chunk 3: Save/Load + Config Integration

### Task 4: Add seen_hints to save/load system

**Files:**
- Modify: `scripts/core/save_load.gd:433-476` (_collect_player_data)
- Modify: `scripts/core/save_load.gd:564-639` (_apply_save_data)

- [ ] **Step 1: Save seen_hints in _collect_player_data()**

In `scripts/core/save_load.gd`, in `_collect_player_data()`, after the journal/sinkhole state block (after line 474), add:

```gdscript
	# Tutorial hints seen state
	var hint_manager: Node = get_node_or_null("/root/HintManager")
	if hint_manager and hint_manager.has_method("get_seen_hints"):
		data["seen_hints"] = hint_manager.get_seen_hints()
```

- [ ] **Step 2: Set loading guard and restore seen_hints in _apply_save_data()**

In `scripts/core/save_load.gd`, in `_apply_save_data()`:

First, at the very start of the function (after line 565 `print("[SaveLoad] Applying save data...")`), add the loading guard:

```gdscript
	# Set loading guard on HintManager to suppress hints during restoration
	var hint_manager: Node = get_node_or_null("/root/HintManager")
	if hint_manager and hint_manager.has_method("set_loading"):
		hint_manager.set_loading(true)
```

Then, after the player data restoration (after line 615 `_apply_player_data(data["player"])`), restore seen hints and clear the loading guard:

```gdscript
	# Restore tutorial hint state
	if hint_manager and hint_manager.has_method("set_seen_hints"):
		hint_manager.set_seen_hints(data.get("seen_hints", []))
	# Clear loading guard after all data is restored
	if hint_manager and hint_manager.has_method("set_loading"):
		hint_manager.set_loading(false)
```

Note: The loading guard clear should go near the end of `_apply_save_data()`, after the config restoration (after line 632). Move it there to ensure all inventory restoration completes first.

- [ ] **Step 3: Clear seen_hints on new game**

Search for the new game initialization flow. When a new game starts (no save loaded), HintManager starts with empty `_seen_hints` by default since it's an autoload that resets. If there's an explicit `new_game()` or scene reload, ensure `HintManager.clear_seen_hints()` is called. This may already be handled by the autoload reloading, but add an explicit clear in `_apply_save_data` when `seen_hints` key is missing (the `.get("seen_hints", [])` default handles this).

- [ ] **Step 4: Run tests**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --script tests/run_all_tests.gd`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/core/save_load.gd
git commit -m "Add seen_hints save/load with loading guard to prevent false triggers"
```

---

### Task 5: Add "Show Hints" toggle to config menu

**Files:**
- Modify: `scripts/ui/config_menu.gd:25-37` (add property)
- Modify: `scripts/ui/config_menu.gd:727-742` (get_config)
- Modify: `scripts/ui/config_menu.gd:746-795` (apply_config)

- [ ] **Step 1: Add hints_enabled property**

In `scripts/ui/config_menu.gd`, after `var screen_brightness: float = 1.1` (line 37), add:

```gdscript
var hints_enabled: bool = true
```

Also add a UI reference variable near the other toggle variables (in the `# UI References` section):

```gdscript
var hints_toggle: CheckButton = null
```

- [ ] **Step 2: Add to get_config()**

In `get_config()` (line 727-742), add to the returned dictionary:

```gdscript
		"hints_enabled": hints_enabled,
```

- [ ] **Step 3: Add to apply_config()**

In `apply_config()` (line 746-795), add restoration logic:

```gdscript
	hints_enabled = data.get("hints_enabled", true)
```

And add UI toggle update:

```gdscript
	if hints_toggle:
		hints_toggle.button_pressed = hints_enabled
```

Also propagate to HintManager:

```gdscript
	var hint_manager: Node = get_node_or_null("/root/HintManager")
	if hint_manager and hint_manager.has_method("set_hints_enabled"):
		hint_manager.set_hints_enabled(hints_enabled)
```

- [ ] **Step 4: Create the toggle UI element**

Add a method `_create_hints_toggle()` following the pattern of `_create_brightness_control()` (lines 269-326). Create a `CheckButton` labeled "Show Hints" and insert it in the VBoxContainer before the hint separator. Connect its `toggled` signal to update `hints_enabled` and propagate to HintManager.

```gdscript
func _create_hints_toggle() -> void:
	var vbox: VBoxContainer = panel.get_node("VBoxContainer")
	var font: Font = load("res://resources/hud_font.tres")

	var sep := HSeparator.new()
	sep.name = "HintsSeparator"

	var container := HBoxContainer.new()
	container.name = "HintsContainer"
	container.add_theme_constant_override("separation", 10)

	var name_label := Label.new()
	name_label.text = "Show Hints"
	name_label.add_theme_font_override("font", font)
	name_label.add_theme_font_size_override("font_size", 32)
	name_label.custom_minimum_size.x = 200
	container.add_child(name_label)

	hints_toggle = CheckButton.new()
	hints_toggle.button_pressed = hints_enabled
	container.add_child(hints_toggle)

	# Insert before the hint separator (at bottom of config options)
	var hint_sep: Node = vbox.get_node_or_null("HSeparator4")
	var insert_idx: int
	if hint_sep:
		insert_idx = hint_sep.get_index()
	else:
		insert_idx = vbox.get_child_count()
	vbox.add_child(sep)
	vbox.move_child(sep, insert_idx)
	vbox.add_child(container)
	vbox.move_child(container, insert_idx + 1)

	hints_toggle.toggled.connect(_on_hints_toggled)
	_build_focusable_controls()


func _on_hints_toggled(pressed: bool) -> void:
	hints_enabled = pressed
	var hint_manager: Node = get_node_or_null("/root/HintManager")
	if hint_manager and hint_manager.has_method("set_hints_enabled"):
		hint_manager.set_hints_enabled(pressed)
```

Call `_create_hints_toggle()` from `_ready()` where other programmatic controls are created.

- [ ] **Step 5: Run tests**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --script tests/run_all_tests.gd`
Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add scripts/ui/config_menu.gd
git commit -m "Add 'Show Hints' toggle to config menu, on by default"
```

---

## Chunk 4: Trigger Hookups (Early Game)

### Task 6: Add early game hint triggers

**Files:**
- Modify: `scripts/resources/resource_node.gd` (~line 148, after `gathered.emit()`)
- Modify: `scripts/crafting/crafting_system.gd` (~line 442, after `recipe_crafted.emit()`)
- Modify: `scripts/player/player_stats.gd` (~line 84, after `hunger_changed.emit()`)
- Modify: `scripts/campsite/placement_system.gd` (in `_confirm_placement()`)
- Modify: `scripts/resources/fishing_spot.gd` (after `fish_caught.emit()`)

- [ ] **Step 1: Add first_gather trigger in resource_node.gd**

In `scripts/resources/resource_node.gd`, after the `gathered.emit(resource_type, resource_amount)` line (~line 148), add:

```gdscript
		HintManager.try_show("first_gather")
```

- [ ] **Step 2: Add first_craft trigger in crafting_system.gd**

In `scripts/crafting/crafting_system.gd`, after `recipe_crafted.emit()` (~line 442), add:

```gdscript
	HintManager.try_show("first_craft")
```

- [ ] **Step 3: Add hunger_low trigger in player_stats.gd**

In `scripts/player/player_stats.gd`, in `_update_hunger()`, after `hunger_changed.emit(hunger, max_hunger)` (line 84), add:

```gdscript
		# Tutorial hint when hunger drops below 40%
		if hunger < max_hunger * 0.4:
			HintManager.try_show("hunger_low")
```

- [ ] **Step 4: Add structure placement triggers in placement_system.gd**

In `scripts/campsite/placement_system.gd`, in `_confirm_placement()`, after the structure is placed and registered, add:

```gdscript
	# Tutorial hints for specific structures
	if current_structure_type == "fire_pit":
		HintManager.try_show("first_fire_pit")
	elif current_structure_type == "shelter":
		HintManager.try_show("first_shelter")
	elif current_structure_type == "cabin":
		HintManager.try_show("first_cabin")
```

- [ ] **Step 5: Add first_fish trigger in fishing_spot.gd**

In `scripts/resources/fishing_spot.gd`, after `fish_caught.emit()` (~line 596), add:

```gdscript
		HintManager.try_show("first_fish")
```

- [ ] **Step 6: Run tests**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --script tests/run_all_tests.gd`
Expected: All tests PASS.

- [ ] **Step 7: Commit**

```bash
git add scripts/resources/resource_node.gd scripts/crafting/crafting_system.gd scripts/player/player_stats.gd scripts/campsite/placement_system.gd scripts/resources/fishing_spot.gd
git commit -m "Add early game hint triggers: gather, craft, hunger, structures, fishing"
```

---

## Chunk 5: Trigger Hookups (Mid + Late Game)

### Task 7: Add mid and late game hint triggers

**Files:**
- Modify: `scripts/world/weather_manager.gd` (in `_set_weather()` or weather_changed emission)
- Modify: `scripts/campsite/campsite_manager.gd` (structure count + level change)
- Modify: `scripts/player/inventory.gd` (in `add_item()` for equipment hints)
- Modify: `scripts/player/player_controller.gd` (desert, water, fall triggers)
- Modify: `scripts/world/chunk_manager.gd` (~line 1516, sinkhole water entry)

- [ ] **Step 1: Add weather trigger in weather_manager.gd**

In `scripts/world/weather_manager.gd`, where `weather_changed.emit()` is called in `_set_weather()`, add:

```gdscript
	if current_weather != Weather.CLEAR:
		HintManager.try_show("first_weather")
```

- [ ] **Step 2: Add camp level triggers in campsite_manager.gd**

In `scripts/campsite/campsite_manager.gd`:

After `structure_added.emit()` in `register_structure()` (~line 157), add:

```gdscript
	# Hint about camp level requirements after placing 2+ structures
	if placed_structures.size() >= 2 and campsite_level == 1:
		HintManager.try_show("camp_level_2_hint")
```

In `_check_level_progression()`, after `campsite_level_changed.emit(campsite_level)` (~line 254), add:

```gdscript
		if campsite_level == 2:
			HintManager.try_show("camp_level_2_up")
```

- [ ] **Step 3: Add equipment item triggers in inventory.gd**

In `scripts/player/inventory.gd`, in `add_item()`, after `item_added.emit()` (~line 111), add:

```gdscript
	# Tutorial hints for specific equipment items
	if resource_type in HintManager.ITEM_HINTS:
		HintManager.try_show(HintManager.ITEM_HINTS[resource_type])
	if resource_type in HintManager.RARE_RESOURCES:
		HintManager.try_show("first_rare_resource")
```

- [ ] **Step 4: Add desert entry trigger in player_controller.gd**

In `scripts/player/player_controller.gd`, in `_check_desert_status()` (~line 1499), after `_is_in_desert` is set, add:

```gdscript
	if _is_in_desert:
		HintManager.try_show("desert_entry")
```

- [ ] **Step 5: Add water entry trigger in player_controller.gd**

In `scripts/player/player_controller.gd`, in `set_in_water()` (~line 906), when entering water, add:

```gdscript
		HintManager.try_show("swim_warning")
```

Add this inside the condition where `is_in_water` becomes true.

- [ ] **Step 6: Add fall damage trigger in player_controller.gd**

In `scripts/player/player_controller.gd`, in `_apply_fall_damage()` (~line 1231), after `stats.take_damage(damage)`, add:

```gdscript
		HintManager.try_show("fall_warning")
```

- [ ] **Step 7: Add deep well discovery trigger in chunk_manager.gd**

In `scripts/world/chunk_manager.gd`, in `_on_sinkhole_water_entered()` (~line 1516), after the player enters sinkhole water, add:

```gdscript
		HintManager.try_show("deep_well_discovery")
```

- [ ] **Step 8: Run tests**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --script tests/run_all_tests.gd`
Expected: All tests PASS.

- [ ] **Step 9: Commit**

```bash
git add scripts/world/weather_manager.gd scripts/campsite/campsite_manager.gd scripts/player/inventory.gd scripts/player/player_controller.gd scripts/world/chunk_manager.gd
git commit -m "Add mid/late game hint triggers: weather, camp levels, equipment, desert, water, falls, sinkhole"
```

---

## Chunk 6: Final Integration + DEV_LOG

### Task 8: Update DEV_LOG and final verification

**Files:**
- Modify: `DEV_LOG.md`

- [ ] **Step 1: Run full test suite**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --script tests/run_all_tests.gd`
Expected: ALL tests pass including new HintManager tests and all existing tests.

- [ ] **Step 2: Update DEV_LOG.md**

Add a new session entry documenting:
- Tutorial hint system implemented
- 18 contextual hints covering early through late game
- HintManager autoload with queue, loading guard, config toggle
- Per-save-slot persistence
- List all new/modified files

- [ ] **Step 3: Final commit and push**

```bash
git add DEV_LOG.md
git commit -m "Update DEV_LOG for tutorial hint system implementation"
git push origin main
```
