extends Node
## Chiptune music player — synthesizes audio from song data!
##
## HOW IT WORKS:
## We pre-render the ENTIRE song into an audio buffer when load_song() is called.
## This means all the expensive math happens once (during loading), and then
## Godot's built-in C++ audio engine handles smooth playback for free.
##
## Think of it like drawing a picture:
## - Old approach: redrawing the picture 44,100 times per second (way too slow!)
## - New approach: draw it once, then just display the finished picture
##
## WAVEFORM SHAPES (what makes each instrument sound different):
## - Square:   jumps between high and low (classic NES beep)
## - Triangle: ramps up then down smoothly (NES bass, like Mario underground)
## - Sawtooth: ramps up then drops (buzzy, aggressive)
## - Sine:     smooth wave (pure tone, like a flute)
## - Noise:    random values (drums, percussion, wind effects)

## Using 22050 instead of 44100 to reduce audio data size by half.
## For chiptune music (square waves, triangle waves), there's no audible
## difference — those waveforms don't have frequencies above 11025 Hz anyway.
## The smaller data means Godot's audio server has less work to do.
const SAMPLE_RATE: int = 22050

## ADSR envelope — fast settings for crisp chiptune notes
const ATTACK_TIME: float = 0.005
const DECAY_TIME: float = 0.02
const SUSTAIN_LEVEL: float = 0.9
const RELEASE_TIME: float = 0.02

var song_data: Dictionary = {}
var is_playing: bool = false

## Just ONE AudioStreamPlayer — the pre-rendered audio plays through this.
## No more juggling 4 separate generators!
var player: AudioStreamPlayer

## Looping and volume
var loop: bool = true
var master_volume: float = 0.4


func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.bus = "Master"
	add_child(player)
	# When the song finishes (only fires if not looping)
	player.finished.connect(_on_finished)


func _on_finished() -> void:
	is_playing = false


## Load song data and pre-render the entire song into an audio buffer.
## This does ALL the heavy math once so playback is effortless.
func load_song(data: Dictionary) -> void:
	song_data = data
	_pre_render()


func play_song() -> void:
	if player.stream == null:
		push_warning("MusicPlayer: No song loaded!")
		return
	is_playing = true
	player.play()


func stop_song() -> void:
	is_playing = false
	player.stop()


## Pre-render the entire song into a PCM audio buffer.
## This is where ALL the sound generation happens — once, upfront.
func _pre_render() -> void:
	# === Step 1: Calculate tick timing ===
	# Convert musical time (bars, beats, ticks) into seconds
	var bpm: float = song_data.get("bpm", 120)
	var subdivisions: int = song_data.get("subdivisions", 4)
	var total_bars: int = song_data.get("total_bars", 4)
	var beats_per_bar: int = song_data.get("beats_per_bar", 4)
	var total_ticks: int = total_bars * beats_per_bar * subdivisions
	var tempo_changes: Array = song_data.get("tempo_changes", [[0, bpm]])

	# Build lookup: tick number → time in seconds
	var tick_to_time: PackedFloat64Array = PackedFloat64Array()
	tick_to_time.resize(total_ticks + 1)
	var time: float = 0.0
	for tick in range(total_ticks):
		tick_to_time[tick] = time
		var bar: int = tick / (beats_per_bar * subdivisions)
		var current_bpm: float = bpm
		for tc in tempo_changes:
			if tc[0] <= bar:
				current_bpm = tc[1]
		time += 60.0 / current_bpm / subdivisions
	tick_to_time[total_ticks] = time

	var total_duration: float = time

	# === Step 2: Create the mix buffer ===
	# Extra samples at the end for the release tail of the last notes
	var release_samples: int = int(RELEASE_TIME * SAMPLE_RATE) + 1
	var total_samples: int = int(total_duration * SAMPLE_RATE) + release_samples
	var mix: PackedFloat32Array = PackedFloat32Array()
	mix.resize(total_samples)
	mix.fill(0.0)

	# === Step 3: Render each track's notes into the mix buffer ===
	var tracks: Array = song_data.get("tracks", [])

	for track in tracks:
		var volume: float = track.get("volume", 0.8)
		var waveform_str: String = track.get("waveform", "square")
		var notes: Array = track.get("notes", [])

		# Convert waveform string to int for faster comparison in the inner loop
		# (comparing ints is much faster than comparing strings)
		var wtype: int = 0  # 0=square, 1=triangle, 2=sawtooth, 3=sine, 4=noise
		match waveform_str:
			"triangle": wtype = 1
			"sawtooth": wtype = 2
			"sine": wtype = 3
			"noise": wtype = 4

		# Pre-calculate envelope sample counts
		var att_samples: int = int(ATTACK_TIME * SAMPLE_RATE)
		var dec_samples: int = int(DECAY_TIME * SAMPLE_RATE)
		var rel_samples: int = int(RELEASE_TIME * SAMPLE_RATE)

		# Render each note
		for note in notes:
			var pitch: int = note[0]
			var start_tick: int = note[1]
			var dur_ticks: int = note[2]
			var end_tick: int = mini(start_tick + dur_ticks, total_ticks)

			var freq: float = 440.0 * pow(2.0, (pitch - 69) / 12.0)
			var phase_inc: float = freq / SAMPLE_RATE

			# Convert note timing to sample positions
			var s_start: int = int(tick_to_time[start_tick] * SAMPLE_RATE)
			var s_end: int = int(tick_to_time[end_tick] * SAMPLE_RATE)
			var s_release_end: int = mini(s_end + rel_samples, total_samples)
			var note_samples: int = s_end - s_start  # How many samples the note is "on"

			var phase: float = 0.0

			# Generate samples for this note's entire lifetime (on + release)
			for s in range(s_start, s_release_end):
				# Calculate envelope value based on position within the note
				var env: float
				var pos: int = s - s_start  # Position within the note

				if s < s_end:
					# Note is ON — go through attack → decay → sustain
					if pos < att_samples:
						# Attack: ramp from 0 to 1
						env = float(pos) / float(att_samples)
					elif pos < att_samples + dec_samples:
						# Decay: ramp from 1 down to sustain level
						var dp: int = pos - att_samples
						env = 1.0 - (1.0 - SUSTAIN_LEVEL) * float(dp) / float(dec_samples)
					else:
						# Sustain: hold steady
						env = SUSTAIN_LEVEL
				else:
					# Note is OFF — release: ramp from sustain down to 0
					var rp: int = s - s_end
					if rel_samples > 0:
						env = SUSTAIN_LEVEL * (1.0 - float(rp) / float(rel_samples))
					else:
						env = 0.0

				# Advance waveform phase
				phase += phase_inc
				if phase >= 1.0:
					phase -= 1.0

				# Generate waveform sample based on type
				var wave: float
				if wtype == 0:  # square
					wave = 1.0 if phase < 0.5 else -1.0
				elif wtype == 1:  # triangle
					wave = phase * 4.0 - 1.0 if phase < 0.5 else 3.0 - phase * 4.0
				elif wtype == 2:  # sawtooth
					wave = 2.0 * phase - 1.0
				elif wtype == 3:  # sine
					wave = sin(phase * TAU)
				else:  # noise
					wave = randf_range(-1.0, 1.0)

				# Add this note's contribution to the mix
				mix[s] += wave * env * volume

	# === Step 4: Crossfade at loop point ===
	# When a song loops, the last sample jumps to the first sample.
	# If those values are different, you hear a "click" or "pop".
	# A crossfade smoothly blends the end into the beginning, eliminating the click.
	# Think of it like a DJ mixing two records together instead of just cutting.
	var loop_end_sample: int = int(total_duration * SAMPLE_RATE)
	var crossfade_samples: int = mini(int(0.03 * SAMPLE_RATE), loop_end_sample / 2)  # 30ms crossfade

	if loop and crossfade_samples > 0:
		for i in range(crossfade_samples):
			# 'fade' goes from 1.0 to 0.0 over the crossfade region
			var fade: float = 1.0 - float(i) / float(crossfade_samples)
			# Blend: end of song fades out while beginning fades in
			var end_idx: int = loop_end_sample - crossfade_samples + i
			if end_idx >= 0 and end_idx < total_samples:
				mix[end_idx] = mix[end_idx] * fade + mix[i] * (1.0 - fade)

	# === Step 5: Normalize to prevent clipping ===
	# Find the loudest sample in the mix
	var peak: float = 0.0
	for i in range(total_samples):
		var abs_val: float = absf(mix[i])
		if abs_val > peak:
			peak = abs_val

	# Scale everything so the loudest point = master_volume
	var scale: float = master_volume
	if peak > 0.0:
		scale = master_volume / peak

	# === Step 6: Convert to 16-bit PCM audio data ===
	# PCM = "Pulse Code Modulation" — the standard way to store digital audio.
	# We convert our -1.0 to 1.0 float values into integers from -32768 to 32767.
	# Each sample takes 2 bytes (16 bits), stored in little-endian order.
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_samples * 2)

	for i in range(total_samples):
		var val: int = clampi(int(mix[i] * scale * 32767.0), -32768, 32767)
		# Little-endian: low byte first, then high byte
		data[i * 2] = val & 0xFF
		data[i * 2 + 1] = (val >> 8) & 0xFF

	# === Step 7: Create the audio stream ===
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = loop_end_sample

	player.stream = stream
