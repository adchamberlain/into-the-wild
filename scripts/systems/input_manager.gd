extends Node
## Singleton that tracks input device (keyboard/mouse vs controller) and provides button prompt helpers.
## Registered as AutoLoad "InputManager" in Project Settings.

signal input_device_changed(is_controller: bool)

# Current input device state
var using_controller: bool = false

# Button prompt mappings for keyboard
const KEYBOARD_PROMPTS: Dictionary = {
	"interact": "E",
	"jump": "Space",
	"sprint": "Shift",
	"eat": "F",
	"use_equipped": "R",
	"unequip": "Q",
	"open_crafting": "C",
	"open_inventory": "I",
	"pause": "Esc",
	"ui_accept": "Enter",
	"ui_cancel": "Esc",
}

# Button prompt mappings for PlayStation controller (DualSense)
# Using recognizable labels: Share (left button), Pad (touchpad), Menu (right button)
const CONTROLLER_PROMPTS: Dictionary = {
	"interact": "□",
	"jump": "✕",
	"sprint": "L3",
	"eat": "△",
	"use_equipped": "R2",
	"unequip": "○",
	"open_crafting": "Pad",
	"open_inventory": "Share",
	"pause": "Menu",
	"next_slot": "R1",
	"prev_slot": "L1",
	"ui_accept": "✕",
	"ui_cancel": "○",
}


func _ready() -> void:
	# Process input to detect device changes
	set_process_input(true)


func _input(event: InputEvent) -> void:
	var was_using_controller: bool = using_controller

	# Detect controller input
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		# Only switch to controller if there's actual input (not just noise)
		if event is InputEventJoypadMotion:
			var motion_event: InputEventJoypadMotion = event as InputEventJoypadMotion
			if abs(motion_event.axis_value) > 0.2:
				using_controller = true
		else:
			using_controller = true

	# Detect keyboard/mouse input
	elif event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		using_controller = false

	# Emit signal if device changed
	if was_using_controller != using_controller:
		input_device_changed.emit(using_controller)


## Get the button prompt text for an action based on current input device.
func get_prompt(action: String) -> String:
	if using_controller:
		return CONTROLLER_PROMPTS.get(action, "?")
	else:
		return KEYBOARD_PROMPTS.get(action, "?")


## Get formatted prompt string like "[E] Interact" or "[□] Interact".
func get_formatted_prompt(action: String, label: String) -> String:
	return "[%s] %s" % [get_prompt(action), label]


## Check if currently using controller.
func is_using_controller() -> bool:
	return using_controller


## Get all connected joypads.
func get_connected_joypads() -> Array[int]:
	return Input.get_connected_joypads()


## Check if any joypad is connected.
func has_joypad_connected() -> bool:
	return Input.get_connected_joypads().size() > 0
