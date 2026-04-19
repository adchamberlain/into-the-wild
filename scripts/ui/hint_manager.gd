extends Node
## Manages contextual gameplay hints shown to the player once each.

const HINTS: Dictionary = {
	"first_gather": {
		"message": "You gathered your first resource! Look for [color=#ffda4d]sticks[/color] and [color=#ffda4d]stones[/color] nearby — you'll need them to craft tools."
	},
	"first_craft": {
		"message": "Nice work! Open the [color=#ffda4d]Crafting Menu ({open_crafting})[/color] anytime to see what else you can build."
	},
	"hunger_low": {
		"message": "Your hunger is getting low. [color=#ffda4d]Fish[/color] at a pond, gather [color=#ffda4d]berries[/color], or [color=#ffda4d]cook meat[/color] at a fire pit. Press [color=#ffda4d]{eat}[/color] to eat food."
	},
	"first_fire_pit": {
		"message": "Your fire pit is ready! You can [color=#ffda4d]cook food[/color] here. Next up: build a [color=#ffda4d]Shelter[/color] to protect yourself from storms."
	},
	"first_shelter": {
		"message": "Shelter built! You'll take less damage during storms now. Keep building — more structures help [color=#ffda4d]level up your camp[/color]."
	},
	"first_weather": {
		"message": "Weather is changing! [color=#ffda4d]Storms[/color] deal damage when exposed, [color=#ffda4d]cold snaps[/color] drain hunger faster, and [color=#ffda4d]heat waves[/color] are brutal. Seek shelter!"
	},
	"first_fish": {
		"message": "Fresh catch! Fish can be [color=#ffda4d]eaten raw[/color] in a pinch, but [color=#ffda4d]cooking[/color] at a fire pit gives much more nutrition."
	},
	"camp_level_2_hint": {
		"message": "Your camp is growing! Build a [color=#ffda4d]Fire Pit[/color], [color=#ffda4d]Shelter[/color], [color=#ffda4d]Crafting Bench[/color], [color=#ffda4d]Drying Rack[/color], and craft a [color=#ffda4d]Fishing Rod[/color] to reach Camp Level 2."
	},
	"camp_level_2_up": {
		"message": "Camp Level 2 unlocked! You can now build a [color=#ffda4d]Canvas Tent[/color] and [color=#ffda4d]Herb Garden[/color]. Keep going for Level 3!"
	},
	"first_bow": {
		"message": "You have a bow! [color=#ffda4d]Equip it[/color] and use it to hunt [color=#ffda4d]rabbits[/color] and [color=#ffda4d]birds[/color] for meat. Aim carefully — arrows are precious."
	},
	"swim_warning": {
		"message": "You can swim, but watch your [color=#ffda4d]air bubbles[/color] underwater! Surface before they run out or you'll take damage."
	},
	"fall_warning": {
		"message": "Ouch! Long falls deal damage. Watch your step near cliffs and ledges."
	},
	"desert_entry": {
		"message": "The desert is scorching! [color=#ffda4d]Heat[/color] drains your hunger faster out here. Watch out for [color=#ffda4d]cactuses[/color] — they hurt on contact."
	},
	"first_rare_resource": {
		"message": "Rare find! These materials unlock [color=#ffda4d]advanced recipes[/color] at the Crafting Bench — powerful tools and equipment."
	},
	"first_machete": {
		"message": "Machete ready! Use it to [color=#ffda4d]cut through thick vegetation[/color] and access areas you couldn't reach before."
	},
	"first_hang_glider": {
		"message": "Hang glider equipped! [color=#ffda4d]Jump ({jump}) from high ground[/color] and hold to glide. Tap [color=#ffda4d]jump ({jump})[/color] repeatedly mid-air for a boost."
	},
	"first_cabin": {
		"message": "Your cabin is complete! Sleep in the [color=#ffda4d]bed[/color] to skip to morning, and use the [color=#ffda4d]kitchen[/color] for advanced recipes."
	},
	"deep_well_discovery": {
		"message": "There's something at the bottom of this well... but it's far too deep to swim. Maybe there's [color=#ffda4d]another way down[/color]."
	},
	"camp_level_crafting": {
		"message": "Some recipes require a higher [color=#ffda4d]Camp Level[/color]. Build more structures at your campsite to level up and unlock advanced crafting!"
	},
	"first_compass": {
		"message": "You crafted the [color=#ffda4d]Compass & Lodestone[/color]! Place the lodestone anywhere to mark a location — the compass needle in your HUD always points back to it. Lifesaver for finding your way home."
	},
}

const RARE_RESOURCES: Array[String] = ["diamond", "opal", "crystal", "rare_ore", "iron_ore"]

const ITEM_HINTS: Dictionary = {
	"bow": "first_bow",
	"enchanted_bow": "first_bow",
	"machete": "first_machete",
	"hang_glider": "first_hang_glider",
	"compass": "first_compass",
}

const QUEUE_SPACING: float = 4.0

var _seen_hints: Array[String] = []
var _queue: Array[String] = []
var _hints_enabled: bool = true
var _is_loading: bool = false
var _processing_queue: bool = false


func try_show(hint_id: String) -> void:
	if _is_loading:
		return
	if not _hints_enabled:
		return
	if not HINTS.has(hint_id):
		return
	if _seen_hints.has(hint_id):
		return

	_seen_hints.append(hint_id)
	_queue.append(hint_id)

	if not _processing_queue:
		_process_queue()


func _process_queue() -> void:
	if not is_inside_tree():
		return
	_processing_queue = true
	while _queue.size() > 0:
		var hint_id: String = _queue.pop_front()
		if HINTS.has(hint_id):
			var hint_data: Dictionary = HINTS[hint_id]
			_display_hint(hint_data["message"])
		if _queue.size() > 0:
			await get_tree().create_timer(QUEUE_SPACING).timeout
	_processing_queue = false


func _display_hint(message: String) -> void:
	if not is_inside_tree():
		return
	var resolved: String = _resolve_prompts(message)
	var hud_nodes: Array[Node] = get_tree().get_nodes_in_group("hud")
	if hud_nodes.size() > 0:
		var hud: Node = hud_nodes[0]
		if hud.has_method("show_hint"):
			hud.show_hint(resolved)


## Replace {action_name} placeholders with current input prompts.
func _resolve_prompts(message: String) -> String:
	var input_mgr: Node = get_node_or_null("/root/InputManager")
	if not input_mgr or not input_mgr.has_method("get_prompt"):
		# Fallback: strip placeholders to just show the action name
		return message
	var result: String = message
	# Find all {action} placeholders and replace with current prompt
	var start: int = result.find("{")
	while start != -1:
		var end: int = result.find("}", start)
		if end == -1:
			break
		var action: String = result.substr(start + 1, end - start - 1)
		var prompt: String = input_mgr.get_prompt(action)
		result = result.substr(0, start) + prompt + result.substr(end + 1)
		start = result.find("{", start + prompt.length())
	return result


func has_seen(hint_id: String) -> bool:
	return _seen_hints.has(hint_id)


func get_seen_hints() -> Array[String]:
	return _seen_hints.duplicate()


func set_seen_hints(hints: Array) -> void:
	_seen_hints.clear()
	for hint: Variant in hints:
		if hint is String:
			_seen_hints.append(hint as String)


func clear_seen_hints() -> void:
	_seen_hints.clear()


func set_loading(loading: bool) -> void:
	_is_loading = loading


func set_hints_enabled(enabled: bool) -> void:
	_hints_enabled = enabled
