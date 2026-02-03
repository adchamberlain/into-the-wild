extends Node
## SFXManager: Pooled audio player singleton for sound effects.
## Uses a pool of AudioStreamPlayers routed to the SFX bus with cooldown system.

# Audio player pool
const POOL_SIZE: int = 8
var audio_pool: Array[AudioStreamPlayer] = []
var pool_index: int = 0

# Volume control (0.0 to 1.0)
var sfx_volume: float = 1.0

# Cooldown timers to prevent rapid-fire spam
var cooldowns: Dictionary = {}
const DEFAULT_COOLDOWNS: Dictionary = {
	"footstep": 0.3,
	"chop": 0.15,
	"swing": 0.2,
	"pickup": 0.1,
	"berry_pluck": 0.15,
	"tree_fall": 0.5,
	"cast": 0.3,
	"fish_caught": 0.5,
	"tool_break": 0.5,
	"place_confirm": 0.2,
	"place_cancel": 0.2,
	"menu_open": 0.1,
	"menu_close": 0.1,
	"select": 0.05,
	"cancel": 0.1,
	# Animal sounds - very long cooldowns since many animals exist in world
	"rabbit_hop": 3.0,  # Only hear a hop every 3 seconds max
	"bird_chirp": 8.0,  # Rare chirps
	"bird_flap": 5.0,   # Rare flap sounds
}

# Anti-repetition tracking for footsteps
var last_footstep_index: Dictionary = {
	"grass": -1,
	"stone": -1,
	"water": -1,
}

# Sound file paths
const SFX_PATHS: Dictionary = {
	# Tool sounds
	"swing": "res://assets/audio/sfx/tools/axe_swing.mp3",
	"chop": "res://assets/audio/sfx/tools/wood_chop.mp3",
	"tool_break": "res://assets/audio/sfx/tools/tool_break.mp3",

	# Gather sounds
	"pickup": "res://assets/audio/sfx/gather/item_pickup.mp3",
	"berry_pluck": "res://assets/audio/sfx/gather/berry_pluck.mp3",
	"tree_fall": "res://assets/audio/sfx/gather/tree_fall.mp3",

	# Fishing sounds
	"cast": "res://assets/audio/sfx/fishing/cast.mp3",
	"reel": "res://assets/audio/sfx/fishing/reel.mp3",
	"fish_caught": "res://assets/audio/sfx/fishing/fish_caught.mp3",

	# UI sounds
	"menu_open": "res://assets/audio/sfx/ui/menu_open.mp3",
	"menu_close": "res://assets/audio/sfx/ui/menu_close.mp3",
	"select": "res://assets/audio/sfx/ui/select.mp3",
	"cancel": "res://assets/audio/sfx/ui/cancel.mp3",

	# Placement sounds
	"place_confirm": "res://assets/audio/sfx/placement/confirm.mp3",
	"place_cancel": "res://assets/audio/sfx/placement/cancel.mp3",

	# Animal sounds
	"rabbit_hop": "res://assets/audio/sfx/animals/rabbit_hop.mp3",
	"bird_chirp": "res://assets/audio/sfx/animals/bird_chirp.mp3",
	"bird_flap": "res://assets/audio/sfx/animals/bird_flap.mp3",
}

# Footstep paths (multiple variants per surface)
const FOOTSTEP_PATHS: Dictionary = {
	"grass": [
		"res://assets/audio/sfx/footsteps/grass_1.mp3",
		"res://assets/audio/sfx/footsteps/grass_2.mp3",
		"res://assets/audio/sfx/footsteps/grass_3.mp3",
		"res://assets/audio/sfx/footsteps/grass_4.mp3",
	],
	"stone": [
		"res://assets/audio/sfx/footsteps/stone_1.mp3",
		"res://assets/audio/sfx/footsteps/stone_2.mp3",
		"res://assets/audio/sfx/footsteps/stone_3.mp3",
		"res://assets/audio/sfx/footsteps/stone_4.mp3",
	],
	"water": [
		"res://assets/audio/sfx/footsteps/water_1.mp3",
		"res://assets/audio/sfx/footsteps/water_2.mp3",
		"res://assets/audio/sfx/footsteps/water_3.mp3",
		"res://assets/audio/sfx/footsteps/water_4.mp3",
	],
}

# Preloaded audio streams for fast access
var loaded_sfx: Dictionary = {}
var loaded_footsteps: Dictionary = {}


func _ready() -> void:
	# Create audio player pool
	for i: int in range(POOL_SIZE):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		audio_pool.append(player)

	# Preload all sound effects
	_preload_sounds()

	print("[SFXManager] Initialized with %d audio players" % POOL_SIZE)


func _process(delta: float) -> void:
	# Update cooldown timers
	var keys_to_remove: Array = []
	for sound_name in cooldowns.keys():
		cooldowns[sound_name] -= delta
		if cooldowns[sound_name] <= 0:
			keys_to_remove.append(sound_name)

	for key in keys_to_remove:
		cooldowns.erase(key)


## Preload all sound files for instant playback.
func _preload_sounds() -> void:
	# Preload standard SFX
	for sound_name in SFX_PATHS.keys():
		var path: String = SFX_PATHS[sound_name]
		if ResourceLoader.exists(path):
			loaded_sfx[sound_name] = load(path)

	# Preload footsteps
	for surface in FOOTSTEP_PATHS.keys():
		loaded_footsteps[surface] = []
		for path in FOOTSTEP_PATHS[surface]:
			if ResourceLoader.exists(path):
				loaded_footsteps[surface].append(load(path))


## Get the next available audio player from the pool.
func _get_next_player() -> AudioStreamPlayer:
	var player: AudioStreamPlayer = audio_pool[pool_index]
	pool_index = (pool_index + 1) % POOL_SIZE
	return player


## Check if a sound is on cooldown.
func _is_on_cooldown(sound_name: String) -> bool:
	return cooldowns.has(sound_name) and cooldowns[sound_name] > 0


## Set cooldown for a sound.
func _set_cooldown(sound_name: String) -> void:
	var cooldown_time: float = DEFAULT_COOLDOWNS.get(sound_name, 0.1)
	cooldowns[sound_name] = cooldown_time


## Play a footstep sound for the given surface type.
## surface: "grass", "stone", or "water"
func play_footstep(surface: String) -> void:
	if _is_on_cooldown("footstep"):
		return

	# Default to grass if unknown surface
	if not loaded_footsteps.has(surface):
		surface = "grass"

	var variants: Array = loaded_footsteps.get(surface, [])
	if variants.is_empty():
		return

	# Pick random variant, avoiding last played
	var last_index: int = last_footstep_index.get(surface, -1)
	var new_index: int = randi() % variants.size()

	# Anti-repetition: reroll if we got the same sound
	if new_index == last_index and variants.size() > 1:
		new_index = (new_index + 1) % variants.size()

	last_footstep_index[surface] = new_index

	var stream: AudioStream = variants[new_index]
	if stream:
		var player: AudioStreamPlayer = _get_next_player()
		player.stream = stream
		player.volume_db = linear_to_db(sfx_volume * 0.7)  # Footsteps slightly quieter
		player.play()
		_set_cooldown("footstep")


## Play a sound effect by name.
## sound_name: Key from SFX_PATHS (e.g., "chop", "swing", "pickup")
func play_sfx(sound_name: String) -> void:
	if _is_on_cooldown(sound_name):
		return

	var stream: AudioStream = loaded_sfx.get(sound_name)
	if not stream:
		# Sound not loaded, skip silently
		return

	var player: AudioStreamPlayer = _get_next_player()
	player.stream = stream
	player.volume_db = linear_to_db(sfx_volume)
	player.play()
	_set_cooldown(sound_name)


## Set the SFX volume (0.0 to 1.0).
func set_volume(volume: float) -> void:
	sfx_volume = clampf(volume, 0.0, 1.0)


## Get the current SFX volume.
func get_volume() -> float:
	return sfx_volume
