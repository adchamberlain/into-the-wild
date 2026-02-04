extends StructureBase
class_name StructureSnareTrap
## Snare trap for catching small game (rabbits, birds).

signal animal_caught(animal_type: String, loot: Dictionary)

# Bait items that can be used
const VALID_BAIT: Array[String] = ["berry", "mushroom", "herb"]

# Catch chances and loot tables
const CATCH_CHANCE: float = 0.15  # 15% chance per check
const CHECK_INTERVAL: float = 60.0  # Check every game hour (60 seconds at default speed)

# Catch table: type -> {weight, loot: {item: amount}}
const CATCH_TABLE: Dictionary = {
	"rabbit": {
		"weight": 70,  # 70% of catches
		"loot": {
			"raw_meat": 2,
			"hide": 1
		}
	},
	"bird": {
		"weight": 30,  # 30% of catches
		"loot": {
			"raw_meat": 1,
			"feathers": 2
		}
	}
}

# State
var is_baited: bool = false
var bait_type: String = ""
var has_catch: bool = false
var catch_type: String = ""
var catch_loot: Dictionary = {}
var check_timer: float = 0.0
var player_inventory: Node = null

# Visual node references
var snare_loop_open: Node3D = null
var snare_loop_closed: Node3D = null
var trigger_upright: Node3D = null
var trigger_fallen: Node3D = null
var bait_berry: Node3D = null
var bait_mushroom: Node3D = null
var bait_herb: Node3D = null
var caught_rabbit: Node3D = null
var caught_bird: Node3D = null


func _ready() -> void:
	super._ready()
	structure_type = "snare_trap"
	structure_name = "Snare Trap"
	interaction_text = "Bait Trap"

	# Get visual node references (deferred to ensure children exist)
	call_deferred("_setup_visual_references")


func _setup_visual_references() -> void:
	snare_loop_open = get_node_or_null("SnareLoopOpen")
	snare_loop_closed = get_node_or_null("SnareLoopClosed")
	trigger_upright = get_node_or_null("TriggerUpright")
	trigger_fallen = get_node_or_null("TriggerFallen")
	bait_berry = get_node_or_null("BaitBerry")
	bait_mushroom = get_node_or_null("BaitMushroom")
	bait_herb = get_node_or_null("BaitHerb")
	caught_rabbit = get_node_or_null("CaughtRabbit")
	caught_bird = get_node_or_null("CaughtBird")

	# Ensure initial visual state is correct
	_update_visuals()


func _process(delta: float) -> void:
	# Only check for catches when baited and no catch yet
	if is_baited and not has_catch:
		check_timer += delta
		if check_timer >= CHECK_INTERVAL:
			check_timer = 0.0
			_check_for_catch()


func interact(player: Node) -> bool:
	if not is_active:
		return false

	player_inventory = null
	if player.has_method("get_inventory"):
		player_inventory = player.get_inventory()

	# If there's a catch, collect it
	if has_catch:
		_collect_catch()
		return true

	# If baited, just show status
	if is_baited:
		_show_notification("Trap is baited with %s. Waiting..." % bait_type, Color(0.8, 0.8, 0.6))
		return true

	# Try to bait the trap
	if player_inventory:
		for bait: String in VALID_BAIT:
			if player_inventory.has_item(bait):
				_set_bait(bait)
				return true
		_show_notification("Need bait: berry, mushroom, or herb", Color(1.0, 0.6, 0.4))
	return true


func _set_bait(bait: String) -> void:
	if not player_inventory or not player_inventory.has_item(bait):
		return

	player_inventory.remove_item(bait, 1)
	bait_type = bait
	is_baited = true
	check_timer = 0.0
	interaction_text = "Check Trap"

	# Update visuals and show notification
	_update_visuals()
	var bait_display: String = bait.capitalize()
	_show_notification("Trap baited with %s" % bait_display, Color(0.6, 0.9, 0.6))
	print("[SnareTrap] Trap baited with %s" % bait)


func _check_for_catch() -> void:
	if not is_baited or has_catch:
		return

	var roll: float = randf()
	if roll < CATCH_CHANCE:
		# Success! Determine what we caught
		_make_catch()


func _make_catch() -> void:
	# Roll for catch type based on weights
	var total_weight: int = 0
	for animal: String in CATCH_TABLE:
		total_weight += CATCH_TABLE[animal]["weight"]

	var roll: int = randi() % total_weight
	var cumulative: int = 0

	for animal: String in CATCH_TABLE:
		cumulative += CATCH_TABLE[animal]["weight"]
		if roll < cumulative:
			catch_type = animal
			catch_loot = CATCH_TABLE[animal]["loot"].duplicate()
			break

	has_catch = true
	is_baited = false  # Bait consumed
	bait_type = ""
	interaction_text = "Collect Catch"

	# Update visuals
	_update_visuals()

	# Play trap snap sound effect
	if Engine.has_singleton("SFXManager"):
		var sfx: Node = Engine.get_singleton("SFXManager")
		if sfx.has_method("play_sfx"):
			sfx.play_sfx("trap_snap")
	else:
		# Fallback: try to find SFXManager as autoload
		var sfx: Node = get_node_or_null("/root/SFXManager")
		if sfx and sfx.has_method("play_sfx"):
			sfx.play_sfx("trap_snap")

	# Show catch notification to player
	var catch_display: String = catch_type.capitalize()
	_show_notification("A trap caught a %s!" % catch_display, Color(0.4, 1.0, 0.4))

	print("[SnareTrap] Caught a %s!" % catch_type)


func _collect_catch() -> void:
	if not has_catch:
		return

	# Build combined loot message
	var loot_parts: Array[String] = []

	# Add loot to player inventory
	if player_inventory:
		for item: String in catch_loot:
			var amount: int = catch_loot[item]
			player_inventory.add_item(item, amount)
			var item_display: String = item.capitalize().replace("_", " ")
			loot_parts.append("+%d %s" % [amount, item_display])
			print("[SnareTrap] +%d %s" % [amount, item])

	# Show combined notification
	var catch_display: String = catch_type.capitalize()
	var loot_msg: String = ", ".join(loot_parts)
	_show_notification("Collected %s: %s" % [catch_display, loot_msg], Color(0.6, 1.0, 0.6))

	animal_caught.emit(catch_type, catch_loot)

	# Reset state
	has_catch = false
	catch_type = ""
	catch_loot = {}
	interaction_text = "Bait Trap"

	# Update visuals
	_update_visuals()

	print("[SnareTrap] Trap reset. Add bait to catch more.")


func _update_visuals() -> void:
	# Update snare loop visibility
	if snare_loop_open:
		snare_loop_open.visible = not has_catch
	if snare_loop_closed:
		snare_loop_closed.visible = has_catch

	# Update trigger stick
	if trigger_upright:
		trigger_upright.visible = not has_catch
	if trigger_fallen:
		trigger_fallen.visible = has_catch

	# Update bait visuals
	if bait_berry:
		bait_berry.visible = is_baited and bait_type == "berry"
	if bait_mushroom:
		bait_mushroom.visible = is_baited and bait_type == "mushroom"
	if bait_herb:
		bait_herb.visible = is_baited and bait_type == "herb"

	# Update caught animal visuals
	if caught_rabbit:
		caught_rabbit.visible = has_catch and catch_type == "rabbit"
	if caught_bird:
		caught_bird.visible = has_catch and catch_type == "bird"


func get_interaction_text() -> String:
	if has_catch:
		return "Collect %s" % catch_type.capitalize()
	elif is_baited:
		return "Check Trap (%s)" % bait_type.capitalize()
	return "Bait Trap"


func _show_notification(message: String, color: Color) -> void:
	var hud: Node = _find_hud()
	if hud and hud.has_method("show_notification"):
		hud.show_notification(message, color)


func _find_hud() -> Node:
	var root: Node = get_tree().root
	if root.has_node("Main/HUD"):
		return root.get_node("Main/HUD")
	return null


# Save/load support for trap state
func get_save_data() -> Dictionary:
	var data: Dictionary = super.get_save_data()
	data["is_baited"] = is_baited
	data["bait_type"] = bait_type
	data["has_catch"] = has_catch
	data["catch_type"] = catch_type
	data["catch_loot"] = catch_loot
	data["check_timer"] = check_timer
	return data


func load_save_data(data: Dictionary) -> void:
	super.load_save_data(data)
	is_baited = data.get("is_baited", false)
	bait_type = data.get("bait_type", "")
	has_catch = data.get("has_catch", false)
	catch_type = data.get("catch_type", "")
	catch_loot = data.get("catch_loot", {})
	check_timer = data.get("check_timer", 0.0)

	# Update visuals after loading
	call_deferred("_update_visuals")

	# Update interaction text
	if has_catch:
		interaction_text = "Collect Catch"
	elif is_baited:
		interaction_text = "Check Trap"
	else:
		interaction_text = "Bait Trap"
