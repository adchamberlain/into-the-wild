extends CanvasLayer
## Simple config menu for toggling game features during development/testing.

signal config_changed()

# Node references
@export var time_manager_path: NodePath
@export var weather_manager_path: NodePath
@export var player_path: NodePath
@export var save_load_path: NodePath
@export var resource_manager_path: NodePath
@export var music_manager_path: NodePath
@export var hud_path: NodePath

var time_manager: Node
var weather_manager: Node
var player: Node
var player_stats: Node
var save_load: Node
var resource_manager: Node
var music_manager: Node
var hud: Node

# Config state (defaults)
var hunger_enabled: bool = false
var health_drain_enabled: bool = false
var weather_damage_enabled: bool = false
var weather_enabled: bool = true
var unlimited_fire_enabled: bool = false
var show_coordinates_enabled: bool = true
var tree_respawn_days: float = 7.0
var day_length_minutes: float = 20.0
var music_enabled: bool = true
var music_volume: float = 50.0  # 0-100

# UI References
@onready var panel: PanelContainer = $Panel
@onready var hunger_toggle: CheckButton = $Panel/VBoxContainer/HungerToggle
@onready var health_toggle: CheckButton = $Panel/VBoxContainer/HealthToggle
@onready var weather_damage_toggle: CheckButton = $Panel/VBoxContainer/WeatherDamageToggle
@onready var weather_toggle: CheckButton = $Panel/VBoxContainer/WeatherToggle
@onready var unlimited_fire_toggle: CheckButton = $Panel/VBoxContainer/UnlimitedFireToggle
@onready var show_coordinates_toggle: CheckButton = $Panel/VBoxContainer/ShowCoordinatesToggle
@onready var day_length_slider: HSlider = $Panel/VBoxContainer/DayLengthContainer/DayLengthSlider
@onready var day_length_label: Label = $Panel/VBoxContainer/DayLengthContainer/DayLengthValue
@onready var tree_respawn_slider: HSlider = $Panel/VBoxContainer/TreeRespawnContainer/TreeRespawnSlider
@onready var tree_respawn_label: Label = $Panel/VBoxContainer/TreeRespawnContainer/TreeRespawnValue
@onready var hint_label: Label = $Panel/VBoxContainer/HintLabel
@onready var music_toggle: CheckButton = $Panel/VBoxContainer/MusicToggle
@onready var music_volume_slider: HSlider = $Panel/VBoxContainer/MusicVolumeContainer/MusicVolumeSlider
@onready var music_volume_label: Label = $Panel/VBoxContainer/MusicVolumeContainer/MusicVolumeValue

var is_visible: bool = false
var opened_from_pause_menu: bool = false

# Slot selection state
var selecting_slot_for_save: bool = false
var selecting_slot_for_load: bool = false

# Slot panel references (set in _ready)
var slot_panel: PanelContainer
var slot_buttons: Array[Button] = []

# UI Scale
var ui_scale_slider: HSlider
var ui_scale_label: Label

# Controller navigation
var focused_control_index: int = 0
var focusable_controls: Array[Control] = []  # All navigable controls in order
var focused_slot_index: int = 0  # For slot panel navigation


func _ready() -> void:
	# This node must process even when the tree is paused (opened from pause menu)
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Add to group for UI state detection
	add_to_group("config_menu")

	# Connect to InputManager for device change updates
	var input_mgr: Node = get_node_or_null("/root/InputManager")
	if input_mgr and input_mgr.has_signal("input_device_changed"):
		input_mgr.input_device_changed.connect(_on_input_device_changed)

	# Get node references
	if time_manager_path:
		time_manager = get_node_or_null(time_manager_path)
	if weather_manager_path:
		weather_manager = get_node_or_null(weather_manager_path)
	if player_path:
		player = get_node_or_null(player_path)
		if player:
			player_stats = player.get_node_or_null("PlayerStats")
	if save_load_path:
		save_load = get_node_or_null(save_load_path)
	if resource_manager_path:
		resource_manager = get_node_or_null(resource_manager_path)
	if music_manager_path:
		music_manager = get_node_or_null(music_manager_path)
	if hud_path:
		hud = get_node_or_null(hud_path)

	# Initialize UI state
	_init_ui()

	# Create UI scale control
	_create_ui_scale_control()

	# Create slot selection panel
	_create_slot_panel()

	# Start hidden
	panel.visible = false
	is_visible = false


func _init_ui() -> void:
	# Set initial toggle states
	hunger_toggle.button_pressed = hunger_enabled
	health_toggle.button_pressed = health_drain_enabled
	weather_damage_toggle.button_pressed = weather_damage_enabled
	weather_toggle.button_pressed = weather_enabled
	unlimited_fire_toggle.button_pressed = unlimited_fire_enabled
	if show_coordinates_toggle:
		show_coordinates_toggle.button_pressed = show_coordinates_enabled

	# Set day length slider
	if time_manager and "day_length_minutes" in time_manager:
		day_length_minutes = time_manager.day_length_minutes
	day_length_slider.value = day_length_minutes
	day_length_label.text = "%.0f min" % day_length_minutes

	# Set tree respawn slider
	if resource_manager and "tree_respawn_time_hours" in resource_manager:
		tree_respawn_days = resource_manager.tree_respawn_time_hours / 24.0
	tree_respawn_slider.value = tree_respawn_days
	tree_respawn_label.text = "%.0f day%s" % [tree_respawn_days, "s" if tree_respawn_days != 1.0 else ""]

	# Set music controls
	if music_toggle:
		music_toggle.button_pressed = music_enabled
	if music_volume_slider:
		music_volume_slider.value = music_volume
	if music_volume_label:
		music_volume_label.text = "%.0f%%" % music_volume

	# Connect signals
	hunger_toggle.toggled.connect(_on_hunger_toggled)
	health_toggle.toggled.connect(_on_health_toggled)
	weather_damage_toggle.toggled.connect(_on_weather_damage_toggled)
	weather_toggle.toggled.connect(_on_weather_toggled)
	unlimited_fire_toggle.toggled.connect(_on_unlimited_fire_toggled)
	if show_coordinates_toggle:
		show_coordinates_toggle.toggled.connect(_on_show_coordinates_toggled)
	day_length_slider.value_changed.connect(_on_day_length_changed)
	tree_respawn_slider.value_changed.connect(_on_tree_respawn_changed)

	# Connect music signals
	if music_toggle:
		music_toggle.toggled.connect(_on_music_toggled)
	if music_volume_slider:
		music_volume_slider.value_changed.connect(_on_music_volume_changed)

	# Build focusable controls list for controller navigation
	_build_focusable_controls()

	# Apply initial config
	_apply_config()


## Create the UI Scale slider programmatically and insert it before the hint label.
func _create_ui_scale_control() -> void:
	var game_state: Node = get_node_or_null("/root/GameState")
	if not game_state or not "ui_scale" in game_state:
		return

	var vbox: VBoxContainer = panel.get_node("VBoxContainer")
	var font: Font = load("res://resources/hud_font.tres")

	# Separator before UI Scale
	var sep := HSeparator.new()
	sep.name = "UIScaleSeparator"

	# Container
	var container := HBoxContainer.new()
	container.name = "UIScaleContainer"
	container.add_theme_constant_override("separation", 10)

	# Name label
	var name_label := Label.new()
	name_label.text = "UI Scale"
	name_label.add_theme_font_override("font", font)
	name_label.add_theme_font_size_override("font_size", 32)
	name_label.custom_minimum_size.x = 200
	container.add_child(name_label)

	# Slider
	ui_scale_slider = HSlider.new()
	ui_scale_slider.min_value = 0.5
	ui_scale_slider.max_value = 1.5
	ui_scale_slider.step = 0.05
	ui_scale_slider.value = game_state.ui_scale
	ui_scale_slider.custom_minimum_size.x = 200
	ui_scale_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(ui_scale_slider)

	# Value label
	ui_scale_label = Label.new()
	ui_scale_label.text = "%.0f%%" % (game_state.ui_scale * 100)
	ui_scale_label.add_theme_font_override("font", font)
	ui_scale_label.add_theme_font_size_override("font_size", 28)
	ui_scale_label.custom_minimum_size.x = 80
	container.add_child(ui_scale_label)

	# Insert before the hint separator
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

	# Connect
	ui_scale_slider.value_changed.connect(_on_ui_scale_changed)

	# Rebuild focusable controls now that ui_scale_slider exists
	_build_focusable_controls()


func _on_ui_scale_changed(value: float) -> void:
	if ui_scale_label:
		ui_scale_label.text = "%.0f%%" % (value * 100)
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("set_ui_scale"):
		game_state.set_ui_scale(value)


## Create the slot selection panel programmatically.
func _create_slot_panel() -> void:
	slot_panel = PanelContainer.new()
	slot_panel.name = "SlotPanel"

	# Match main panel styling
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12, 0.95)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	slot_panel.add_theme_stylebox_override("panel", style)

	# Center the panel
	slot_panel.anchors_preset = Control.PRESET_CENTER
	slot_panel.anchor_left = 0.5
	slot_panel.anchor_top = 0.5
	slot_panel.anchor_right = 0.5
	slot_panel.anchor_bottom = 0.5
	slot_panel.offset_left = -180
	slot_panel.offset_top = -150
	slot_panel.offset_right = 180
	slot_panel.offset_bottom = 150
	slot_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	slot_panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	slot_panel.add_child(vbox)

	# Title label
	var title_label: Label = Label.new()
	title_label.name = "SlotTitle"
	title_label.text = "Select Slot"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var font: Font = load("res://resources/hud_font.tres")
	title_label.add_theme_font_override("font", font)
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))
	vbox.add_child(title_label)

	# Separator
	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)

	# Slot buttons
	slot_buttons.clear()
	for i: int in range(1, 4):
		var btn: Button = Button.new()
		btn.name = "SlotButton%d" % i
		btn.text = "Slot %d: Empty" % i
		btn.add_theme_font_override("font", font)
		btn.add_theme_font_size_override("font_size", 24)
		btn.custom_minimum_size = Vector2(300, 50)
		btn.pressed.connect(_on_slot_button_pressed.bind(i))
		vbox.add_child(btn)
		slot_buttons.append(btn)

	# Another separator
	var sep2: HSeparator = HSeparator.new()
	vbox.add_child(sep2)

	# Cancel button
	var cancel_btn: Button = Button.new()
	cancel_btn.name = "CancelButton"
	cancel_btn.text = "Cancel"
	cancel_btn.add_theme_font_override("font", font)
	cancel_btn.add_theme_font_size_override("font_size", 24)
	cancel_btn.pressed.connect(_on_slot_cancel_pressed)
	vbox.add_child(cancel_btn)

	add_child(slot_panel)
	slot_panel.visible = false


func _input(event: InputEvent) -> void:
	# Don't process input if not in tree (prevents null viewport errors during scene transitions)
	if not is_inside_tree():
		return

	# Keyboard shortcuts
	if event is InputEventKey and event.pressed:
		# Toggle menu with Tab key
		if event.physical_keycode == KEY_TAB:
			toggle_menu()
			_handle_input()
			return
		# Escape to close slot panel or menu
		elif event.physical_keycode == KEY_ESCAPE:
			if slot_panel and slot_panel.visible:
				_hide_slot_panel()
				_handle_input()
			elif is_visible:
				toggle_menu()
				_handle_input()
			return
		# Quick save with K (Keep)
		elif event.physical_keycode == KEY_K:
			_on_save_pressed()
			_handle_input()
			return
		# Quick load with L (Load)
		elif event.physical_keycode == KEY_L:
			_on_load_pressed()
			_handle_input()
			return

	# Controller: Open config menu with L3+R3 (both stick buttons)
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_LEFT_STICK:
			if Input.is_joy_button_pressed(event.device, JOY_BUTTON_RIGHT_STICK):
				toggle_menu()
				_handle_input()
				return
		elif event.button_index == JOY_BUTTON_RIGHT_STICK:
			if Input.is_joy_button_pressed(event.device, JOY_BUTTON_LEFT_STICK):
				toggle_menu()
				_handle_input()
				return

	# Only handle navigation when menu is open
	if not is_visible:
		return

	# Handle slot panel navigation separately
	if slot_panel and slot_panel.visible:
		if event.is_action_pressed("ui_cancel"):
			_hide_slot_panel()
			_handle_input()
			return
		if event.is_action_pressed("ui_down"):
			_navigate_slot_buttons(1)
			_handle_input()
			return
		if event.is_action_pressed("ui_up"):
			_navigate_slot_buttons(-1)
			_handle_input()
			return
		if event.is_action_pressed("ui_accept"):
			_activate_focused_slot_button()
			_handle_input()
			return
		return

	# Controller cancel to close menu
	if event.is_action_pressed("ui_cancel"):
		toggle_menu()
		_handle_input()
		return

	# D-pad navigation
	if event.is_action_pressed("ui_down"):
		_navigate_controls(1)
		_handle_input()
		return
	if event.is_action_pressed("ui_up"):
		_navigate_controls(-1)
		_handle_input()
		return

	# Left/right to adjust sliders or toggle checkboxes
	if event.is_action_pressed("ui_left"):
		_adjust_focused_control(-1)
		_handle_input()
		return
	if event.is_action_pressed("ui_right"):
		_adjust_focused_control(1)
		_handle_input()
		return

	# Accept to toggle checkbox or press button
	if event.is_action_pressed("ui_accept"):
		_activate_focused_control()
		_handle_input()
		return


func _handle_input() -> void:
	var vp: Viewport = get_viewport()
	if vp:
		vp.set_input_as_handled()


func toggle_menu() -> void:
	is_visible = not is_visible

	# If closing menu, hide both panels
	if not is_visible:
		panel.visible = false
		if slot_panel:
			slot_panel.visible = false
		selecting_slot_for_save = false
		selecting_slot_for_load = false

		# If opened from pause menu, return to it
		if opened_from_pause_menu:
			opened_from_pause_menu = false
			var pause_menu: Node = _find_pause_menu()
			if pause_menu and "panel" in pause_menu:
				pause_menu.panel.visible = true
			return  # Don't change mouse mode, pause menu handles it
	else:
		# If opening and slot panel was visible, hide it and show main
		if slot_panel and slot_panel.visible:
			slot_panel.visible = false
		panel.visible = true
		# Update hint label based on input device
		_update_hint_label()
		# Focus first control for controller navigation
		focused_control_index = 0
		_update_control_focus()

	# Handle mouse capture
	if is_visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


## Show the config menu (called from pause menu).
func show_menu(from_pause_menu: bool = false) -> void:
	opened_from_pause_menu = from_pause_menu
	is_visible = true
	panel.visible = true
	if slot_panel:
		slot_panel.visible = false
	selecting_slot_for_save = false
	selecting_slot_for_load = false
	_update_hint_label()
	focused_control_index = 0
	_update_control_focus()


func _find_pause_menu() -> Node:
	var root: Node = get_tree().root
	if root.has_node("Main/PauseMenu"):
		return root.get_node("Main/PauseMenu")
	return null


func _on_hunger_toggled(pressed: bool) -> void:
	hunger_enabled = pressed
	_apply_config()
	print("[ConfigMenu] Hunger depletion: %s" % ("ON" if pressed else "OFF"))


func _on_health_toggled(pressed: bool) -> void:
	health_drain_enabled = pressed
	_apply_config()
	print("[ConfigMenu] Health drain (starvation): %s" % ("ON" if pressed else "OFF"))


func _on_weather_damage_toggled(pressed: bool) -> void:
	weather_damage_enabled = pressed
	_apply_config()
	print("[ConfigMenu] Weather damage (storms/cold): %s" % ("ON" if pressed else "OFF"))


func _on_weather_toggled(pressed: bool) -> void:
	weather_enabled = pressed
	_apply_config()
	print("[ConfigMenu] Weather system: %s" % ("ON" if pressed else "OFF"))


func _on_unlimited_fire_toggled(pressed: bool) -> void:
	unlimited_fire_enabled = pressed
	_apply_config()
	print("[ConfigMenu] Unlimited fire burn time: %s" % ("ON" if pressed else "OFF"))


func _on_show_coordinates_toggled(pressed: bool) -> void:
	show_coordinates_enabled = pressed
	_apply_config()
	print("[ConfigMenu] Show coordinates: %s" % ("ON" if pressed else "OFF"))


func _on_day_length_changed(value: float) -> void:
	day_length_minutes = value
	day_length_label.text = "%.0f min" % value
	_apply_config()
	print("[ConfigMenu] Day length: %.0f minutes" % value)


func _on_tree_respawn_changed(value: float) -> void:
	tree_respawn_days = value
	tree_respawn_label.text = "%.0f day%s" % [value, "s" if value != 1.0 else ""]
	_apply_config()
	print("[ConfigMenu] Tree respawn time: %.0f days" % value)


func _on_music_toggled(pressed: bool) -> void:
	music_enabled = pressed
	if music_manager:
		music_manager.set_music_enabled(pressed)
	print("[ConfigMenu] Music: %s" % ("ON" if pressed else "OFF"))


func _on_music_volume_changed(value: float) -> void:
	music_volume = value
	if music_volume_label:
		music_volume_label.text = "%.0f%%" % value
	if music_manager:
		music_manager.set_volume(value / 100.0)
	print("[ConfigMenu] Music volume: %.0f%%" % value)


func _apply_config() -> void:
	# Apply hunger setting
	if player_stats:
		player_stats.hunger_depletion_enabled = hunger_enabled
		player_stats.health_drain_enabled = health_drain_enabled
		player_stats.weather_damage_enabled = weather_damage_enabled

	# Apply weather setting
	if weather_manager:
		weather_manager.weather_enabled = weather_enabled
		if not weather_enabled:
			# Force clear weather when disabled
			weather_manager.set_weather_debug("clear")

	# Apply day length
	if time_manager and "day_length_minutes" in time_manager:
		time_manager.day_length_minutes = day_length_minutes
		# Recalculate seconds per minute
		if time_manager.has_method("_recalculate_time_scale"):
			time_manager._recalculate_time_scale()
		elif "_seconds_per_game_minute" in time_manager:
			time_manager._seconds_per_game_minute = (day_length_minutes * 60.0) / (24.0 * 60.0)

	# Apply unlimited fire setting to all fire pits
	var fire_pits: Array = get_tree().get_nodes_in_group("campsite_structures")
	for structure: Node in fire_pits:
		if structure is StructureFirePit:
			structure.unlimited_fuel = unlimited_fire_enabled

	# Apply tree respawn time
	if resource_manager and "tree_respawn_time_hours" in resource_manager:
		resource_manager.tree_respawn_time_hours = tree_respawn_days * 24.0

	# Apply show coordinates setting
	if hud and "show_coordinates" in hud:
		hud.show_coordinates = show_coordinates_enabled

	config_changed.emit()


## Get current config as dictionary.
func get_config() -> Dictionary:
	return {
		"hunger_enabled": hunger_enabled,
		"health_drain_enabled": health_drain_enabled,
		"weather_damage_enabled": weather_damage_enabled,
		"weather_enabled": weather_enabled,
		"unlimited_fire_enabled": unlimited_fire_enabled,
		"show_coordinates_enabled": show_coordinates_enabled,
		"tree_respawn_days": tree_respawn_days,
		"day_length_minutes": day_length_minutes
	}


## Save/Load functions
func _on_save_pressed() -> void:
	if not save_load:
		_show_save_status("Error: Save system not found", Color.RED)
		return

	# Show slot selection for save
	selecting_slot_for_save = true
	selecting_slot_for_load = false
	_update_slot_panel_for_save()
	_show_slot_panel()


func _on_load_pressed() -> void:
	if not save_load:
		_show_save_status("Error: Save system not found", Color.RED)
		return

	# Show slot selection for load
	selecting_slot_for_save = false
	selecting_slot_for_load = true
	_update_slot_panel_for_load()
	_show_slot_panel()


## Update slot panel buttons for save operation.
func _update_slot_panel_for_save() -> void:
	if not slot_panel:
		return

	var title: Label = slot_panel.get_node_or_null("VBoxContainer/SlotTitle")
	if title:
		title.text = "Save to Slot"

	var slots_info: Array[Dictionary] = save_load.get_all_slots_info()
	for i: int in range(slot_buttons.size()):
		var btn: Button = slot_buttons[i]
		var info: Dictionary = slots_info[i]
		btn.disabled = false  # Can always save to any slot
		if info["empty"]:
			btn.text = "Slot %d: Empty" % (i + 1)
		else:
			btn.text = "Slot %d: Level %d Camp - %s" % [i + 1, info["campsite_level"], info["formatted_time"]]


## Update slot panel buttons for load operation.
func _update_slot_panel_for_load() -> void:
	if not slot_panel:
		return

	var title: Label = slot_panel.get_node_or_null("VBoxContainer/SlotTitle")
	if title:
		title.text = "Load from Slot"

	var slots_info: Array[Dictionary] = save_load.get_all_slots_info()
	for i: int in range(slot_buttons.size()):
		var btn: Button = slot_buttons[i]
		var info: Dictionary = slots_info[i]
		if info["empty"]:
			btn.text = "Slot %d: Empty" % (i + 1)
			btn.disabled = true  # Can't load empty slots
		else:
			btn.text = "Slot %d: Level %d Camp - %s" % [i + 1, info["campsite_level"], info["formatted_time"]]
			btn.disabled = false


## Show the slot selection panel.
func _show_slot_panel() -> void:
	if slot_panel:
		panel.visible = false
		slot_panel.visible = true
		# Always show mouse cursor when slot panel is visible
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		# Focus first slot button for controller navigation
		focused_slot_index = 0
		if not slot_buttons.is_empty():
			slot_buttons[0].grab_focus()


## Hide the slot selection panel.
func _hide_slot_panel() -> void:
	if slot_panel:
		slot_panel.visible = false
		selecting_slot_for_save = false
		selecting_slot_for_load = false
		# Return to main config panel if menu is still open
		if is_visible:
			panel.visible = true
		else:
			# If config menu wasn't open, restore mouse capture
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


## Handle slot button press.
func _on_slot_button_pressed(slot: int) -> void:
	if selecting_slot_for_save:
		save_load.save_game_slot(slot)
	elif selecting_slot_for_load:
		save_load.load_game_slot(slot)

	_hide_slot_panel()


## Handle cancel button press.
func _on_slot_cancel_pressed() -> void:
	_hide_slot_panel()



# ============================================================================
# Controller Navigation
# ============================================================================

## Build the list of focusable controls for controller navigation.
func _build_focusable_controls() -> void:
	focusable_controls.clear()

	# Add controls in visual order (top to bottom as they appear in the menu)
	if hunger_toggle:
		focusable_controls.append(hunger_toggle)
	if health_toggle:
		focusable_controls.append(health_toggle)
	if weather_damage_toggle:
		focusable_controls.append(weather_damage_toggle)
	if weather_toggle:
		focusable_controls.append(weather_toggle)
	if unlimited_fire_toggle:
		focusable_controls.append(unlimited_fire_toggle)
	if show_coordinates_toggle:
		focusable_controls.append(show_coordinates_toggle)
	if tree_respawn_slider:
		focusable_controls.append(tree_respawn_slider)
	if day_length_slider:
		focusable_controls.append(day_length_slider)
	if music_toggle:
		focusable_controls.append(music_toggle)
	if music_volume_slider:
		focusable_controls.append(music_volume_slider)
	if ui_scale_slider:
		focusable_controls.append(ui_scale_slider)


## Navigate through controls with D-pad.
func _navigate_controls(direction: int) -> void:
	if focusable_controls.is_empty():
		return

	focused_control_index = (focused_control_index + direction) % focusable_controls.size()
	if focused_control_index < 0:
		focused_control_index = focusable_controls.size() - 1

	_update_control_focus()


## Update focus on the current control.
func _update_control_focus() -> void:
	if focusable_controls.is_empty():
		return

	if focused_control_index >= 0 and focused_control_index < focusable_controls.size():
		focusable_controls[focused_control_index].grab_focus()


## Adjust the focused control (for sliders, use left/right to change value).
func _adjust_focused_control(direction: int) -> void:
	if focusable_controls.is_empty():
		return

	if focused_control_index < 0 or focused_control_index >= focusable_controls.size():
		return

	var control: Control = focusable_controls[focused_control_index]

	if control is HSlider:
		var slider: HSlider = control as HSlider
		var step: float = (slider.max_value - slider.min_value) / 10.0  # 10 steps
		slider.value += direction * step
	elif control is CheckButton:
		# Toggle checkbox with left/right too
		var check: CheckButton = control as CheckButton
		check.button_pressed = not check.button_pressed


## Activate the focused control (toggle checkbox or press button).
func _activate_focused_control() -> void:
	if focusable_controls.is_empty():
		return

	if focused_control_index < 0 or focused_control_index >= focusable_controls.size():
		return

	var control: Control = focusable_controls[focused_control_index]

	if control is CheckButton:
		var check: CheckButton = control as CheckButton
		check.button_pressed = not check.button_pressed
	elif control is Button:
		var button: Button = control as Button
		if not button.disabled:
			button.pressed.emit()


# Slot panel navigation

## Navigate slot buttons with D-pad.
func _navigate_slot_buttons(direction: int) -> void:
	if slot_buttons.is_empty():
		return

	focused_slot_index = (focused_slot_index + direction) % slot_buttons.size()
	if focused_slot_index < 0:
		focused_slot_index = slot_buttons.size() - 1

	slot_buttons[focused_slot_index].grab_focus()


## Activate the focused slot button.
func _activate_focused_slot_button() -> void:
	if slot_buttons.is_empty():
		return

	if focused_slot_index >= 0 and focused_slot_index < slot_buttons.size():
		var button: Button = slot_buttons[focused_slot_index]
		if not button.disabled:
			button.pressed.emit()


## Called when input device changes (controller <-> keyboard).
func _on_input_device_changed(_is_controller: bool) -> void:
	if is_visible:
		_update_hint_label()


## Update hint label based on input device.
func _update_hint_label() -> void:
	var input_mgr: Node = get_node_or_null("/root/InputManager")
	var using_controller: bool = input_mgr and input_mgr.is_using_controller()

	# Update hint label - always show both keyboard and controller close methods
	if hint_label:
		if using_controller:
			hint_label.text = "↑↓ Navigate  ←→ Adjust  A Select  B/TAB Close"
		else:
			hint_label.text = "Press TAB or B to close"
