extends Node
class_name MusicManager
## Manages ambient background music during gameplay.
## Plays tracks randomly with crossfade transitions.
##
## Music Attribution:
## Minecraft-style Music Pack by Valdis Story (Reddit: u/ThatOneRandomDev)
## Source: https://www.reddit.com/r/godot/comments/1gllruv/its_free_for_a_day_minecraft_style_music_pack/
## License: Free to use (open source)

signal track_changed(track_name: String)

# Music settings
@export var music_enabled: bool = true
@export var music_volume_db: float = -10.0  # Default volume (quieter for ambient)
@export var crossfade_duration: float = 3.0  # Seconds to crossfade between tracks
@export var pause_between_tracks: float = 5.0  # Seconds of silence between tracks

# Track paths (MP3 format)
const MUSIC_PATH: String = "res://assets/music/mp3/tracks/"
const TRACK_LIST: Array[String] = [
	"Cuddle Clouds.mp3",
	"Drifting Memories.mp3",
	"Evening Harmony.mp3",
	"Floating Dream.mp3",
	"Forgotten Biomes.mp3",
	"Gentle Breeze.mp3",
	"Golden Gleam.mp3",
	"Polar Lights.mp3",
	"Strange Worlds.mp3",
	"Sunlight Through Leaves.mp3",
	"Wanderer's Tale.mp3",
	"Whispering Woods.mp3"
]

# Audio players for crossfading
var player_a: AudioStreamPlayer
var player_b: AudioStreamPlayer
var active_player: AudioStreamPlayer
var inactive_player: AudioStreamPlayer

# State
var current_track_index: int = -1
var track_order: Array[int] = []
var is_crossfading: bool = false
var pause_timer: float = 0.0
var waiting_for_next: bool = false


func _ready() -> void:
	# Create two audio players for crossfading
	player_a = AudioStreamPlayer.new()
	player_a.name = "MusicPlayerA"
	player_a.bus = "Music"  # Will use Master if Music bus doesn't exist
	player_a.volume_db = music_volume_db
	player_a.finished.connect(_on_track_finished.bind(player_a))
	add_child(player_a)

	player_b = AudioStreamPlayer.new()
	player_b.name = "MusicPlayerB"
	player_b.bus = "Music"
	player_b.volume_db = -80.0  # Start silent
	player_b.finished.connect(_on_track_finished.bind(player_b))
	add_child(player_b)

	active_player = player_a
	inactive_player = player_b

	# Shuffle track order
	_shuffle_tracks()

	# Start playing
	if music_enabled:
		_play_next_track()

	print("[MusicManager] Initialized with %d tracks" % TRACK_LIST.size())


func _process(delta: float) -> void:
	# Handle pause between tracks
	if waiting_for_next:
		pause_timer -= delta
		if pause_timer <= 0:
			waiting_for_next = false
			_play_next_track()


func _shuffle_tracks() -> void:
	# Create shuffled order of track indices
	track_order.clear()
	for i in range(TRACK_LIST.size()):
		track_order.append(i)

	# Fisher-Yates shuffle
	for i in range(track_order.size() - 1, 0, -1):
		var j: int = randi() % (i + 1)
		var temp: int = track_order[i]
		track_order[i] = track_order[j]
		track_order[j] = temp


func _play_next_track() -> void:
	if not music_enabled:
		return

	# Move to next track in shuffled order
	current_track_index += 1
	if current_track_index >= track_order.size():
		# Reshuffle and start over
		_shuffle_tracks()
		current_track_index = 0

	var track_index: int = track_order[current_track_index]
	var track_name: String = TRACK_LIST[track_index]
	var track_path: String = MUSIC_PATH + track_name

	# Load and play the track
	var stream: AudioStream = load(track_path)
	if stream:
		if active_player.playing:
			# Crossfade to new track
			_crossfade_to(stream)
		else:
			# Just play directly
			active_player.stream = stream
			active_player.volume_db = music_volume_db
			active_player.play()

		var display_name: String = track_name.get_basename()
		track_changed.emit(display_name)
		print("[MusicManager] Now playing: %s" % display_name)
	else:
		print("[MusicManager] Failed to load track: %s" % track_path)
		# Try next track
		_play_next_track()


func _crossfade_to(new_stream: AudioStream) -> void:
	if is_crossfading:
		return

	is_crossfading = true

	# Setup inactive player with new track
	inactive_player.stream = new_stream
	inactive_player.volume_db = -80.0
	inactive_player.play()

	# Crossfade
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(active_player, "volume_db", -80.0, crossfade_duration)
	tween.tween_property(inactive_player, "volume_db", music_volume_db, crossfade_duration)

	tween.set_parallel(false)
	tween.tween_callback(_on_crossfade_complete)


func _on_crossfade_complete() -> void:
	is_crossfading = false

	# Stop the old player
	active_player.stop()

	# Swap players
	var temp: AudioStreamPlayer = active_player
	active_player = inactive_player
	inactive_player = temp


func _on_track_finished(player: AudioStreamPlayer) -> void:
	if player != active_player:
		return

	if not music_enabled:
		return

	# Wait a bit before playing next track (like Minecraft)
	waiting_for_next = true
	pause_timer = pause_between_tracks
	print("[MusicManager] Track finished, waiting %.1f seconds..." % pause_between_tracks)


## Enable or disable music.
func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	if enabled:
		if not active_player.playing:
			_play_next_track()
	else:
		# Fade out current music
		var tween: Tween = create_tween()
		tween.tween_property(active_player, "volume_db", -80.0, 1.0)
		tween.tween_callback(active_player.stop)
		waiting_for_next = false


## Set music volume (0.0 to 1.0).
func set_volume(volume: float) -> void:
	# Convert 0-1 to decibels (-80 to 0, with offset for ambient level)
	if volume <= 0:
		music_volume_db = -80.0
	else:
		music_volume_db = linear_to_db(volume) - 5.0  # -5 offset for ambient level

	if active_player and active_player.playing and not is_crossfading:
		active_player.volume_db = music_volume_db


## Get current track name.
func get_current_track() -> String:
	if current_track_index < 0 or current_track_index >= track_order.size():
		return ""
	var track_index: int = track_order[current_track_index]
	return TRACK_LIST[track_index].get_basename()


## Skip to next track.
func skip_track() -> void:
	waiting_for_next = false
	_play_next_track()
