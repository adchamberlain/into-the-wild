extends Node
## Singleton that tracks input device (keyboard/mouse vs controller) and provides button prompt helpers.
## Registered as AutoLoad "InputManager" in Project Settings.

signal input_device_changed(is_controller: bool)

# Current input device state
var using_controller: bool = false
var using_touch: bool = false

# Button prompt mappings for keyboard
const KEYBOARD_PROMPTS: Dictionary = {
	"interact": "E",
	"jump": "Space",
	"sprint": "Shift",
	"eat": "F",
	"use_equipped": "R",
	"unequip": "Q",
	"open_crafting": "X",
	"open_inventory": "I",
	"pause": "Esc",
	"ui_accept": "Enter",
	"ui_cancel": "Esc",
	"move_structure": "M",
	"crouch": "C",
	"cycle_ammo": "T",
}

# Button prompt mappings for touch devices (iOS/Android)
const TOUCH_PROMPTS: Dictionary = {
	"interact": "Tap ACT",
	"jump": "Tap JUMP",
	"sprint": "Tap SPRINT",
	"eat": "Tap EAT",
	"use_equipped": "Tap USE",
	"open_crafting": "Tap ⚒️",
	"open_inventory": "Tap 🎒",
	"pause": "Tap ⏸️",
	"crouch": "Tap CROUCH",
	"move_structure": "Tap MOVE",
	"cycle_ammo": "Tap AMMO",
	"next_slot": "Tap ▶",
	"prev_slot": "Tap ◀",
	"unequip": "Tap UNEQUIP",
}

# Button prompt mappings for PlayStation controller (DualSense)
# Share (left button), Pad (touchpad click), Menu (right button)
const CONTROLLER_PROMPTS: Dictionary = {
	"interact": "L2",
	"jump": "○",
	"sprint": "L3",
	"eat": "△",
	"use_equipped": "R2",
	"unequip": "✕",
	"open_crafting": "Pad",
	"open_inventory": "Share",
	"pause": "Menu",
	"next_slot": "R1",
	"prev_slot": "L1",
	"ui_accept": "○",
	"ui_cancel": "✕",
	"move_structure": "D-Up",
	"crouch": "✕",
	"cycle_ammo": "D-Dn",
}


func _ready() -> void:
	# This node must process even when the tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Process input to detect device changes
	set_process_input(true)
	# Auto-detect iOS and default to touch mode
	if OS.get_name() == "iOS":
		using_touch = true
		using_controller = false
	# Listen for controller connect/disconnect events
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _input(event: InputEvent) -> void:
	# Detect touch input first (highest priority)
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		if not using_touch:
			using_touch = true
			using_controller = false
			input_device_changed.emit(false)
		return

	var was_using_controller: bool = using_controller
	var was_using_touch: bool = using_touch

	# Detect controller input
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		# Only switch to controller if there's actual input (not just noise)
		if event is InputEventJoypadMotion:
			var motion_event: InputEventJoypadMotion = event as InputEventJoypadMotion
			if abs(motion_event.axis_value) > 0.2:
				using_controller = true
				using_touch = false
		else:
			using_controller = true
			using_touch = false

	# Detect keyboard/mouse input
	elif event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		# On iOS, mouse events are emulated from touch — don't let them override touch mode
		if OS.get_name() == "iOS" and (event is InputEventMouseButton or event is InputEventMouseMotion):
			return
		using_controller = false
		using_touch = false

	# Emit signal if device changed
	if was_using_controller != using_controller or was_using_touch != using_touch:
		input_device_changed.emit(using_controller)


## Get the button prompt text for an action based on current input device.
func get_prompt(action: String) -> String:
	if using_touch:
		return TOUCH_PROMPTS.get(action, "?")
	elif using_controller:
		return CONTROLLER_PROMPTS.get(action, "?")
	else:
		return KEYBOARD_PROMPTS.get(action, "?")


## Get formatted prompt string like "[E] Interact" or "[□] Interact".
func get_formatted_prompt(action: String, label: String) -> String:
	return "[%s] %s" % [get_prompt(action), label]


## Check if currently using controller.
func is_using_controller() -> bool:
	return using_controller


## Check if currently using touch input.
func is_using_touch() -> bool:
	return using_touch


## Get all connected joypads.
func get_connected_joypads() -> Array[int]:
	return Input.get_connected_joypads()


## Check if any joypad is connected.
func has_joypad_connected() -> bool:
	return Input.get_connected_joypads().size() > 0


## Handle controller connect/disconnect events.
func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if not connected and using_controller:
		# Controller disconnected — switch back to touch on iOS, keyboard elsewhere
		if OS.get_name() == "iOS":
			using_touch = true
		using_controller = false
		input_device_changed.emit(false)
