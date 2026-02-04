extends Node
## Frame time profiler that logs performance spikes and chunk loading events.
## Helps diagnose stuttering issues by recording when frame times exceed thresholds.

# Configuration
const SPIKE_THRESHOLD_MS: float = 33.0  # Log frames longer than 33ms (< 30 FPS)
const SEVERE_SPIKE_MS: float = 100.0     # Severe spike threshold
const LOG_TO_FILE: bool = true
const LOG_FILE_PATH: String = "user://frame_profiler.log"
const MAX_LOG_ENTRIES: int = 1000        # Keep last N entries in memory

# Tracking
var frame_count: int = 0
var spike_count: int = 0
var severe_spike_count: int = 0
var total_spike_time_ms: float = 0.0
var session_start_time: int = 0

# Recent spikes for analysis
var recent_spikes: Array[Dictionary] = []

# Player position tracking (to correlate with chunk boundaries)
var player: Node3D = null
var last_player_pos: Vector3 = Vector3.ZERO
var last_chunk_coord: Vector2i = Vector2i(-9999, -9999)

# Chunk manager reference
var chunk_manager: Node = null

# File handle
var log_file: FileAccess = null


func _ready() -> void:
	session_start_time = Time.get_ticks_msec()

	if LOG_TO_FILE:
		log_file = FileAccess.open(LOG_FILE_PATH, FileAccess.WRITE)
		if log_file:
			log_file.store_line("=== Frame Profiler Session Started ===")
			log_file.store_line("Time: %s" % Time.get_datetime_string_from_system())
			log_file.store_line("Spike threshold: %.1f ms" % SPIKE_THRESHOLD_MS)
			log_file.store_line("")
			log_file.flush()

	# Find player and chunk manager after scene loads
	call_deferred("_find_references")

	print("[FrameProfiler] Started - logging spikes > %.0fms to %s" % [SPIKE_THRESHOLD_MS, LOG_FILE_PATH])


func _find_references() -> void:
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	chunk_manager = get_tree().get_first_node_in_group("chunk_manager")

	if player:
		last_player_pos = player.global_position
	if chunk_manager and "cell_size" in chunk_manager:
		last_chunk_coord = _world_to_chunk(last_player_pos)


func _process(delta: float) -> void:
	frame_count += 1
	var frame_time_ms: float = delta * 1000.0

	# Check for spike
	if frame_time_ms > SPIKE_THRESHOLD_MS:
		_log_spike(frame_time_ms, delta)


func _log_spike(frame_time_ms: float, delta: float) -> void:
	spike_count += 1
	total_spike_time_ms += frame_time_ms

	var is_severe: bool = frame_time_ms >= SEVERE_SPIKE_MS
	if is_severe:
		severe_spike_count += 1

	# Gather context
	var context: Dictionary = _gather_context()

	# Create spike entry
	var spike_entry: Dictionary = {
		"frame": frame_count,
		"time_ms": frame_time_ms,
		"severe": is_severe,
		"timestamp": Time.get_ticks_msec() - session_start_time,
		"context": context
	}

	# Store in memory
	recent_spikes.append(spike_entry)
	if recent_spikes.size() > MAX_LOG_ENTRIES:
		recent_spikes.pop_front()

	# Format log message
	var severity: String = "SEVERE" if is_severe else "SPIKE"
	var msg: String = "[%s] Frame %d: %.1fms" % [severity, frame_count, frame_time_ms]

	if context.has("player_pos"):
		msg += " | Pos: (%.0f, %.0f)" % [context.player_pos.x, context.player_pos.z]

	if context.has("chunk_changed") and context.chunk_changed:
		msg += " | CHUNK BOUNDARY: %s -> %s" % [str(context.prev_chunk), str(context.curr_chunk)]

	if context.has("chunks_loading") and context.chunks_loading > 0:
		msg += " | Loading: %d chunks" % context.chunks_loading

	if context.has("chunks_unloading") and context.chunks_unloading > 0:
		msg += " | Unloading: %d chunks" % context.chunks_unloading

	# Print to console
	if is_severe:
		push_warning(msg)
	else:
		print(msg)

	# Write to file
	if log_file:
		log_file.store_line(msg)
		log_file.flush()


func _gather_context() -> Dictionary:
	var context: Dictionary = {}

	# Player position
	if player and is_instance_valid(player):
		context.player_pos = player.global_position
		context.player_velocity = player.velocity if "velocity" in player else Vector3.ZERO

		# Check for chunk boundary crossing
		if chunk_manager and "cell_size" in chunk_manager:
			var curr_chunk: Vector2i = _world_to_chunk(player.global_position)
			if curr_chunk != last_chunk_coord:
				context.chunk_changed = true
				context.prev_chunk = last_chunk_coord
				context.curr_chunk = curr_chunk
				last_chunk_coord = curr_chunk
			else:
				context.chunk_changed = false

		last_player_pos = player.global_position

	# Chunk manager state
	if chunk_manager:
		if chunk_manager.has_method("get_pending_load_count"):
			context.chunks_loading = chunk_manager.get_pending_load_count()
		if chunk_manager.has_method("get_pending_unload_count"):
			context.chunks_unloading = chunk_manager.get_pending_unload_count()
		if chunk_manager.has_method("get_loaded_chunk_count"):
			context.chunks_loaded = chunk_manager.get_loaded_chunk_count()

	return context


func _world_to_chunk(world_pos: Vector3) -> Vector2i:
	if not chunk_manager:
		return Vector2i(0, 0)
	var chunk_world_size: float = chunk_manager.chunk_size_cells * chunk_manager.cell_size
	var chunk_x: int = int(floor(world_pos.x / chunk_world_size))
	var chunk_z: int = int(floor(world_pos.z / chunk_world_size))
	return Vector2i(chunk_x, chunk_z)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		_write_summary()
		if log_file:
			log_file.close()


func _write_summary() -> void:
	var summary: String = "\n=== Session Summary ===\n"
	summary += "Total frames: %d\n" % frame_count
	summary += "Total spikes: %d (%.1f%%)\n" % [spike_count, 100.0 * spike_count / max(1, frame_count)]
	summary += "Severe spikes: %d\n" % severe_spike_count
	summary += "Total spike time: %.0fms\n" % total_spike_time_ms

	if spike_count > 0:
		summary += "Average spike: %.1fms\n" % (total_spike_time_ms / spike_count)

	# Analyze chunk boundary correlation
	var chunk_boundary_spikes: int = 0
	for spike in recent_spikes:
		if spike.context.get("chunk_changed", false):
			chunk_boundary_spikes += 1

	if recent_spikes.size() > 0:
		summary += "\nChunk boundary spikes: %d / %d (%.0f%%)\n" % [
			chunk_boundary_spikes,
			recent_spikes.size(),
			100.0 * chunk_boundary_spikes / recent_spikes.size()
		]

	summary += "========================\n"

	print(summary)
	if log_file:
		log_file.store_line(summary)
		log_file.flush()


## Get recent spikes for external analysis
func get_recent_spikes() -> Array[Dictionary]:
	return recent_spikes


## Get summary statistics
func get_stats() -> Dictionary:
	return {
		"frame_count": frame_count,
		"spike_count": spike_count,
		"severe_spike_count": severe_spike_count,
		"total_spike_time_ms": total_spike_time_ms,
		"spike_percentage": 100.0 * spike_count / max(1, frame_count)
	}


## Clear collected data (useful for testing specific scenarios)
func reset_stats() -> void:
	frame_count = 0
	spike_count = 0
	severe_spike_count = 0
	total_spike_time_ms = 0.0
	recent_spikes.clear()
	session_start_time = Time.get_ticks_msec()
	print("[FrameProfiler] Stats reset")
