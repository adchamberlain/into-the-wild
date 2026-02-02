extends Node
## Global game state that persists across scene reloads.
## Used to pass data (like world seed) when reloading the main scene.

# World seed to use when the main scene loads (0 = generate new)
var pending_world_seed: int = 0
var has_pending_seed: bool = false

# Save slot to load after scene reload (0 = none)
var pending_load_slot: int = 0


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
