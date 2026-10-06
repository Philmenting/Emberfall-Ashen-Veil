extends RefCounted
## Fixture-only mix of the actual accepted AudioDirector streams and slots.
## Native WAV decoding/resampling runs at AudioServer's rate. This is fixed-step
## PCM evidence, not a recording of a physical speaker or real-time AudioServer.
var director: Node
var music: AudioStreamPlayback
var voices: Array[AudioStreamPlayback] = []
var voice_keys: Array[String] = []
var voice_ended: Array[bool] = []
var voice_looping: Array[bool] = []
var music_looping := false
var music_ended := false
var sample_rate := 0
var sample_frames := 0
var accepted_cues := 0
var stolen_voices := 0
var completed_effects := 0
var eof_silence_frames := 0
var peak := 0.0
var energy := 0.0
var finite := true
var frame_events: Array[Dictionary] = []
var stream_fingerprints: Dictionary = {}

func attach(value: Node) -> void:
	assert(director == null, "A native capture mixer can attach only once.")
	director = value
	sample_rate = AudioServer.get_mix_rate()
	voices.resize(director.VOICES)
	voice_keys.resize(director.VOICES)
	voice_ended.resize(director.VOICES)
	voice_looping.resize(director.VOICES)
	for slot in voices.size(): voice_ended[slot] = true
	director.cue_accepted.connect(_on_cue)
	director.music_context_changed.connect(_on_context)
	director.mix_state_changed.connect(_on_state)
	if director.music.stream != null: _on_context(director.music.stream)
	_on_state()

func detach() -> void:
	if is_instance_valid(director):
		director.cue_accepted.disconnect(_on_cue)
		director.music_context_changed.disconnect(_on_context)
		director.mix_state_changed.disconnect(_on_state)
	if music != null: music.stop()
	_clear_voices()
	director = null

func _fingerprint(source: AudioStreamWAV) -> String:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(source.data)
	return hash.finish().hex_encode()

func _on_context(source: AudioStreamWAV) -> void:
	if music != null: music.stop()
	music = source.instantiate_playback()
	music.start()
	music_looping = source.loop_mode != AudioStreamWAV.LOOP_DISABLED
	music_ended = false
	stream_fingerprints[director.context] = _fingerprint(source)
	frame_events.append({"type": "context", "context": director.context, "sample_frame": sample_frames})

func _on_state() -> void:
	if director.suspended or director.preferences.master * director.preferences.effects <= 0.0:
		_clear_voices()
	frame_events.append({"type": "state", "sample_frame": sample_frames,
		"suspended": director.suspended, "preferences": director.preferences.duplicate(true),
		"music_paused": music_is_paused(),
		"music_gain": db_to_linear(director.music.volume_db),
		"effects_gain": db_to_linear(director.voices[0].volume_db)})

func music_is_paused() -> bool:
	# Dummy never starts AudioStreamPlayer, so its stream_paused getter does not
	# retain the pause request. Use the director's exact public intent guards.
	return director.suspended or director.preferences.master * director.preferences.music <= 0.0

func _clear_voices() -> void:
	for slot in voices.size():
		if voices[slot] != null: voices[slot].stop()
		voices[slot] = null
		voice_keys[slot] = ""
		voice_ended[slot] = true
		voice_looping[slot] = false

func _on_cue(key: String, slot: int, source: AudioStreamWAV) -> void:
	var replaced := ""
	if voices[slot] != null and not voice_ended[slot]:
		replaced = voice_keys[slot]
		stolen_voices += 1
		voices[slot].stop()
	voices[slot] = source.instantiate_playback()
	voices[slot].start()
	voice_keys[slot] = key
	voice_ended[slot] = false
	voice_looping[slot] = source.loop_mode != AudioStreamWAV.LOOP_DISABLED
	accepted_cues += 1
	if not stream_fingerprints.has(key): stream_fingerprints[key] = _fingerprint(source)
	frame_events.append({"type": "cue", "key": key, "slot": slot,
		"sample_frame": sample_frames, "replaced_key": replaced,
		"acceptance_wall_msec": Time.get_ticks_msec()})

func mix(sample_count: int) -> PackedByteArray:
	assert(is_instance_valid(director) and sample_count > 0)
	var mixed := PackedVector2Array()
	mixed.resize(sample_count)
	if music != null and not music_ended and not music_is_paused():
		var music_frames := _add_playback(mixed, music, db_to_linear(director.music.volume_db), music_looping)
		music_ended = music_frames < sample_count
	if not director.suspended:
		for slot in voices.size():
			if voices[slot] != null and not voice_ended[slot]:
				var voice_frames := _add_playback(mixed, voices[slot], db_to_linear(director.voices[slot].volume_db), voice_looping[slot])
				if voice_frames < sample_count:
					voice_ended[slot] = true
					completed_effects += 1
					eof_silence_frames += sample_count - voice_frames
					frame_events.append({"type": "effect_eof", "key": voice_keys[slot], "slot": slot,
						"sample_frame": sample_frames, "valid_frames": voice_frames,
						"silence_from_sample_frame": sample_frames + voice_frames,
						"zero_tail_frames": sample_count - voice_frames})
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 8)
	for index in sample_count:
		var sample := mixed[index]
		finite = finite and sample.is_finite()
		peak = maxf(peak, maxf(absf(sample.x), absf(sample.y)))
		energy += sample.length_squared()
		bytes.encode_float(index * 8, sample.x)
		bytes.encode_float(index * 8 + 4, sample.y)
	sample_frames += sample_count
	return bytes

func _add_playback(output: PackedVector2Array, playback: AudioStreamPlayback, gain: float, looping: bool) -> int:
	# is_playing() can become false while the native resampler still contains
	# a final valid tail. Drain until mix_audio itself reports the exact EOF.
	# That API trims its returned array to valid frames; the untouched part of
	# our already zero-initialized output retains the full recording timeline.
	var decoded := playback.mix_audio(1.0, output.size())
	assert(decoded.size() <= output.size(), "Native decoder returned more frames than requested.")
	if looping:
		assert(decoded.size() == output.size() and playback.is_playing(), "Looping native audio must fill its requested block without EOF.")
	elif decoded.size() < output.size():
		assert(not playback.is_playing(), "A short native WAV block must represent actual EOF.")
	for index in decoded.size(): output[index] += decoded[index] * gain
	return decoded.size()

func take_frame_events() -> Array[Dictionary]:
	var result := frame_events
	frame_events = []
	return result

func summary() -> Dictionary:
	return {"scope": "Native AudioStreamPlayback fixed-step stereo float PCM from actual accepted AudioDirector slots, streams and gain/suspend state; no physical audio loopback.",
		"sample_rate": sample_rate, "channels": 2, "sample_format": "f32le", "sample_frames": sample_frames,
		"seconds": float(sample_frames) / sample_rate, "accepted_cues": accepted_cues,
		"stolen_voices": stolen_voices, "finite": finite, "peak": peak,
		"completed_effects": completed_effects, "eof_silence_frames": eof_silence_frames,
		"eof_padding_scope": "Zero-filled suffix frames in each ended one-shot's first EOF block; concurrent score/other voices retain their real samples.",
		"rms": sqrt(energy / maxi(1, sample_frames * 2)), "stream_pcm_sha256": stream_fingerprints,
		"cue_clock_scope": "Observe the ordinary director's accepted cues; its existing 80 ms duplicate check uses wall time. Each accepted cue begins at its recorded fixed-step sample boundary."}
