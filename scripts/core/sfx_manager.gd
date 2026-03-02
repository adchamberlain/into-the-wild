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
	"fall_hurt": 0.5,
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
	"select": 0.0,  # No cooldown — deliberate user navigation
	"cancel": 0.1,
	# Trap sounds
	"trap_snap": 0.5,  # Trap catching prey
	# Animal sounds - very long cooldowns since many animals exist in world
	"rabbit_hop": 3.0,  # Only hear a hop every 3 seconds max
	"bird_chirp": 8.0,  # Rare chirps
	"bird_flap": 5.0,   # Rare flap sounds
	# Grappling hook sounds
	"grapple_fire": 0.3,
	"grapple_attach": 0.3,
	"grapple_land": 0.3,
	"bubble_pop": 0.3,
	# Bow sounds
	"bow_draw": 0.3,
	"bow_fire": 0.2,
	"arrow_hit": 0.15,
	"coca_leaf": 0.5,
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

	# Trap sounds
	"trap_snap": "res://assets/audio/sfx/traps/trap_snap.mp3",

	# Animal sounds
	"rabbit_hop": "res://assets/audio/sfx/animals/rabbit_hop.mp3",
	"bird_chirp": "res://assets/audio/sfx/animals/bird_chirp.mp3",
	"bird_flap": "res://assets/audio/sfx/animals/bird_flap.mp3",

	# Grappling hook sounds
	"grapple_fire": "res://assets/audio/sfx/tools/grapple_fire.mp3",
	"grapple_attach": "res://assets/audio/sfx/tools/grapple_attach.mp3",
	"grapple_land": "res://assets/audio/sfx/tools/grapple_land.mp3",
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

	# Generate procedural sounds
	loaded_sfx["fall_hurt"] = _generate_fall_hurt_sound()
	loaded_sfx["bubble_pop"] = _generate_bubble_pop_sound()
	loaded_sfx["bow_draw"] = _generate_bow_draw_sound()
	loaded_sfx["bow_fire"] = _generate_bow_fire_sound()
	loaded_sfx["arrow_hit"] = _generate_arrow_hit_sound()
	loaded_sfx["coca_leaf"] = _generate_coca_leaf_sound()

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


## Generate a procedural "ouch" grunt sound for fall damage.
## Short low-frequency burst with quick decay to simulate a pain grunt.
func _generate_fall_hurt_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.25
	var num_samples: int = int(sample_rate * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(num_samples * 2)  # 16-bit samples = 2 bytes each

	for i: int in range(num_samples):
		var t: float = float(i) / sample_rate
		# Quick exponential decay envelope
		var envelope: float = exp(-t * 16.0)
		# Low grunt tone (~120 Hz) with harmonics for roughness
		var wave: float = sin(t * 120.0 * TAU) * 0.5
		wave += sin(t * 180.0 * TAU) * 0.25
		wave += sin(t * 85.0 * TAU) * 0.2
		# Add a bit of noise for breathiness
		wave += (randf() * 2.0 - 1.0) * 0.15
		# Downward pitch bend (grunt falling off)
		var bend: float = 1.0 - t * 2.0
		wave = sin(t * 120.0 * bend * TAU) * 0.4 + wave * 0.6

		var sample: float = wave * envelope * 0.7
		var sample_int: int = clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


## Generate a procedural bubble pop sound.
## Short high-frequency ping with rapid decay to simulate an underwater bubble popping.
func _generate_bubble_pop_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.15
	var num_samples: int = int(sample_rate * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(num_samples * 2)

	for i: int in range(num_samples):
		var t: float = float(i) / sample_rate
		# Very fast decay for a short pop
		var envelope: float = exp(-t * 40.0)
		# High-pitched pop tone (~800 Hz) with a harmonic
		var wave: float = sin(t * 800.0 * TAU) * 0.6
		wave += sin(t * 1200.0 * TAU) * 0.25
		# Slight upward pitch bend (bubble release)
		var bend: float = 1.0 + t * 3.0
		wave = sin(t * 800.0 * bend * TAU) * 0.5 + wave * 0.5
		# Tiny noise burst at the start for the "pop" attack
		var noise_env: float = exp(-t * 80.0)
		wave += (randf() * 2.0 - 1.0) * 0.3 * noise_env

		var sample: float = wave * envelope * 0.5
		var sample_int: int = clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


## Generate a procedural bow draw (creak) sound.
func _generate_bow_draw_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.35
	var num_samples: int = int(sample_rate * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(num_samples * 2)

	for i: int in range(num_samples):
		var t: float = float(i) / sample_rate
		var envelope: float = minf(t * 6.0, 1.0) * exp(-t * 2.0)
		var wobble: float = sin(t * 8.0 * TAU) * 0.15
		var wave: float = sin(t * (150.0 + wobble * 30.0) * TAU) * 0.4
		wave += sin(t * 220.0 * TAU) * 0.2
		wave += (randf() * 2.0 - 1.0) * 0.1

		var sample: float = wave * envelope * 0.4
		var sample_int: int = clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


## Generate a procedural bow fire (twang) sound.
func _generate_bow_fire_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.3
	var num_samples: int = int(sample_rate * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(num_samples * 2)

	for i: int in range(num_samples):
		var t: float = float(i) / sample_rate
		var envelope: float = exp(-t * 12.0)
		var wave: float = sin(t * 400.0 * TAU) * 0.5
		wave += sin(t * 800.0 * TAU) * 0.25
		wave += sin(t * 600.0 * TAU) * 0.15
		var bend: float = 1.0 - t * 1.5
		wave = sin(t * 400.0 * bend * TAU) * 0.4 + wave * 0.6
		var attack: float = exp(-t * 60.0)
		wave += (randf() * 2.0 - 1.0) * 0.2 * attack

		var sample: float = wave * envelope * 0.5
		var sample_int: int = clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


## Generate a procedural arrow hit (thud) sound.
func _generate_arrow_hit_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.2
	var num_samples: int = int(sample_rate * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(num_samples * 2)

	for i: int in range(num_samples):
		var t: float = float(i) / sample_rate
		var envelope: float = exp(-t * 25.0)
		var wave: float = sin(t * 100.0 * TAU) * 0.5
		wave += sin(t * 60.0 * TAU) * 0.3
		var impact: float = exp(-t * 50.0)
		wave += (randf() * 2.0 - 1.0) * 0.4 * impact

		var sample: float = wave * envelope * 0.6
		var sample_int: int = clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


## Generate a procedural magical ascending sound for coca leaf consumption.
## Shimmering rising tones with harmonics to evoke an ethereal breath-enhancing effect.
func _generate_coca_leaf_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 1.2
	var num_samples: int = int(sample_rate * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(num_samples * 2)

	for i: int in range(num_samples):
		var t: float = float(i) / sample_rate
		# Fade in then out envelope (gentle swell)
		var fade_in: float = minf(t * 4.0, 1.0)
		var fade_out: float = exp(-(t - 0.3) * 2.5) if t > 0.3 else 1.0
		var envelope: float = fade_in * fade_out

		# Ascending base tone: sweeps from ~400 Hz to ~900 Hz
		var freq_base: float = 400.0 + t * 420.0
		var wave: float = sin(t * freq_base * TAU) * 0.3

		# Shimmering harmonic: octave above, also ascending
		var freq_high: float = freq_base * 2.0
		wave += sin(t * freq_high * TAU) * 0.2

		# Sparkle overtone: fifth above, with tremolo
		var freq_fifth: float = freq_base * 1.5
		var tremolo: float = 0.5 + 0.5 * sin(t * 12.0 * TAU)
		wave += sin(t * freq_fifth * TAU) * 0.15 * tremolo

		# Gentle chime pings at intervals for magical sparkle
		for ping_t: float in [0.0, 0.15, 0.35, 0.6]:
			var dt: float = t - ping_t
			if dt >= 0.0 and dt < 0.3:
				var ping_env: float = exp(-dt * 15.0)
				var ping_freq: float = 1200.0 + ping_t * 800.0
				wave += sin(dt * ping_freq * TAU) * 0.12 * ping_env

		var sample: float = wave * envelope * 0.6
		var sample_int: int = clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


## Get the current SFX volume.
func get_volume() -> float:
	return sfx_volume
