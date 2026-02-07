extends Node
## Global game state that persists across scene reloads.
## Used to pass data (like world seed) when reloading the main scene.

# World seed to use when the main scene loads (0 = generate new)
var pending_world_seed: int = 0
var has_pending_seed: bool = false

# Save slot to load after scene reload (0 = none)
var pending_load_slot: int = 0

# When true, pending load skips player data restoration (cave exit preserves
# the player's current inventory/stats so they keep cave-gained items)
var skip_player_data_on_load: bool = false

# When true, load the cave autosave (separate temp file, not a user slot)
var pending_cave_autosave: bool = false

# UI scale factor (persisted to user://display_config.cfg)
var ui_scale: float = 1.0


func _ready() -> void:
	_load_display_config()
	call_deferred("_apply_ui_scale")


## Auto-detect a reasonable UI scale based on screen DPI.
## High-DPI (Retina) screens return 1.0; lower-DPI monitors scale down.
func _auto_detect_ui_scale() -> float:
	var screen_idx: int = get_window().current_screen if get_window() else DisplayServer.get_primary_screen()
	var dpi: int = DisplayServer.screen_get_dpi(screen_idx)
	if dpi <= 0:
		return 1.0
	# Retina ~220 DPI → 1.0, standard 1080p 24" ~92 DPI → 0.75, 1440p 27" ~109 DPI → 0.9
	var scale: float = clampf(float(dpi) / 120.0, 0.7, 1.0)
	return snappedf(scale, 0.05)


## Set the UI scale and persist it.
func set_ui_scale(scale: float) -> void:
	ui_scale = clampf(scale, 0.5, 1.5)
	_apply_ui_scale()
	_save_display_config()


## Apply UI scale to the root window's content scale factor.
func _apply_ui_scale() -> void:
	if get_tree() and get_tree().root:
		get_tree().root.content_scale_factor = ui_scale
		print("[GameState] UI scale applied: %.2f" % ui_scale)


## Load display preferences from config file.
func _load_display_config() -> void:
	var config := ConfigFile.new()
	if config.load("user://display_config.cfg") == OK:
		ui_scale = config.get_value("display", "ui_scale", _auto_detect_ui_scale())
	else:
		ui_scale = _auto_detect_ui_scale()
	print("[GameState] UI scale loaded: %.2f (auto-detect would be %.2f)" % [ui_scale, _auto_detect_ui_scale()])


## Save display preferences to config file.
func _save_display_config() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "ui_scale", ui_scale)
	config.save("user://display_config.cfg")


## Set a world seed to be used when the main scene next loads.
func set_pending_world_seed(seed_value: int) -> void:
	pending_world_seed = seed_value
	has_pending_seed = true
	print("[GameState] Pending world seed set: %d" % seed_value)


## Get and clear the pending world seed (returns 0 if none pending).
func consume_pending_world_seed() -> int:
	if has_pending_seed:
		var seed_val: int = pending_world_seed
		pending_world_seed = 0
		has_pending_seed = false
		print("[GameState] Pending world seed consumed: %d" % seed_val)
		return seed_val
	return 0


## Set a save slot to be loaded after scene reload.
func set_pending_load_slot(slot: int) -> void:
	pending_load_slot = slot
	print("[GameState] Pending load slot set: %d" % slot)


## Get and clear the pending load slot (returns 0 if none pending).
func consume_pending_load_slot() -> int:
	var slot: int = pending_load_slot
	pending_load_slot = 0
	return slot
