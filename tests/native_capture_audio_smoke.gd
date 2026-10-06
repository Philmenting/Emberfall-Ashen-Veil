extends SceneTree
## Exercise native offline audio against real AudioDirector acceptance and state.
const Audio = preload("res://scripts/audio_director.gd")
const Capture = preload("res://tests/native_capture_audio.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run_checks.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	if value: print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func nonzero(data: PackedByteArray) -> bool:
	for offset in range(0, data.size(), 4):
		if absf(data.decode_float(offset)) > .00001: return true
	return false

func all_zero(data: PackedByteArray) -> bool:
	for offset in range(0, data.size(), 4):
		if data.decode_float(offset) != 0.0: return false
	return true

func isolated_gain_block(master: float) -> PackedByteArray:
	var audio := Audio.new()
	root.add_child(audio)
	audio.apply_preferences({"master": master, "music": 0.0, "effects": 1.0})
	var capture := Capture.new()
	capture.attach(audio)
	audio.cue("impact")
	var block := capture.mix(1470)
	capture.detach()
	audio.free()
	return block

func check_native_effect_eof() -> void:
	var audio := Audio.new()
	root.add_child(audio)
	audio.apply_preferences({"master": 1.0, "music": 0.0, "effects": 1.0})
	var capture := Capture.new()
	capture.attach(audio)
	audio.cue("ui") # The real 70 ms WAV ends inside a normal 30 Hz output block.
	var reference := Audio.stream_for("ui").instantiate_playback()
	reference.start()
	var gain := db_to_linear(audio.voices[0].volume_db)
	var partial_seen := false
	var exact_native_samples := true
	var exact_zero_tail := true
	var eof_events := 0
	for frame in 8:
		var request := floori(float(frame + 1) * capture.sample_rate / 30.0) - capture.sample_frames
		var decoded := reference.mix_audio(1.0, request)
		if not decoded.is_empty() and decoded.size() < request: partial_seen = true
		var pcm := capture.mix(request)
		check(pcm.size() == request * 8 and capture.sample_frames == floori(float(frame + 1) * capture.sample_rate / 30.0),
			"short native effect EOF preserves every sample in chronological frame %d" % frame)
		for index in request:
			var sample := Vector2(pcm.decode_float(index * 8), pcm.decode_float(index * 8 + 4))
			if index < decoded.size():
				exact_native_samples = exact_native_samples and sample.distance_to(decoded[index] * gain) < .0000001
			else:
				exact_zero_tail = exact_zero_tail and sample == Vector2.ZERO
		for event in capture.take_frame_events():
			if event.type == "effect_eof":
				eof_events += 1
				check(event.valid_frames == decoded.size() and event.zero_tail_frames == request - decoded.size()
					and event.silence_from_sample_frame == frame * capture.sample_rate / 30 + decoded.size(),
					"real SFX EOF evidence records the exact valid tail and zero-padding boundary")
	check(partial_seen, "the real short WAV decoder returns a partial block at actual EOF")
	check(exact_native_samples and exact_zero_tail,
		"every valid EOF-tail sample matches the independent native decoder and every remaining sample is exact zero")
	check(eof_events == 1 and capture.completed_effects == 1 and capture.voice_ended[0],
		"an ended one-shot is recorded exactly once and remains ended")
	check(capture.eof_silence_frames > 0 and capture.accepted_cues == 1 and all_zero(capture.mix(1470)),
		"completed effects leave the future recording timeline silent without restarting or inventing cues")
	capture.detach()
	audio.free()

func check_native_buffered_tail() -> void:
	var audio := Audio.new()
	root.add_child(audio)
	audio.apply_preferences({"master": 1.0, "music": 0.0, "effects": 1.0})
	var capture := Capture.new()
	capture.attach(audio)
	audio.cue("ui")
	var source := Audio.stream_for("ui")
	var reference := source.instantiate_playback()
	reference.start()
	# Approach EOF, then use individual output samples so the native resampler's
	# prefetch crossing cannot be hidden inside a large final request.
	var prefix := floori(float(source.data.size() / 2 - 256) * capture.sample_rate / Audio.RATE)
	reference.mix_audio(1.0, prefix)
	capture.mix(prefix)
	var buffered_tail_seen := false
	var exact_native_tail := true
	var drained := false
	var ticks := 0
	var gain := db_to_linear(audio.voices[0].volume_db)
	for index in ceili(float(512) * capture.sample_rate / Audio.RATE):
		var was_playing := reference.is_playing()
		var decoded := reference.mix_audio(1.0, 1)
		if not was_playing and not decoded.is_empty(): buffered_tail_seen = true
		var pcm := capture.mix(1)
		var sample := Vector2(pcm.decode_float(0), pcm.decode_float(4))
		var expected := decoded[0] * gain if not decoded.is_empty() else Vector2.ZERO
		exact_native_tail = exact_native_tail and sample.distance_to(expected) < .0000001
		ticks += 1
		if decoded.is_empty():
			drained = true
			break
	check(buffered_tail_seen, "the native resampler's final valid samples are drained after is_playing becomes false")
	check(drained and capture.voice_ended[0] and capture.completed_effects == 1,
		"native buffered one-shot data is exhausted exactly once at the decoder's actual EOF")
	check(exact_native_tail and capture.sample_frames == prefix + ticks,
		"single-sample EOF draining matches native output without shortening or extending the sample clock")
	check(all_zero(capture.mix(1470)), "drained native resampler history cannot resurrect an ended cue")
	capture.detach()
	audio.free()

func run_checks() -> void:
	var audio := Audio.new()
	root.add_child(audio)
	audio.apply_preferences({"master": 1.0, "music": 1.0, "effects": 1.0})
	audio.set_context(false)
	var capture := Capture.new()
	capture.attach(audio)
	check(capture.sample_rate == int(AudioServer.get_mix_rate()) and capture.voices.size() == Audio.VOICES,
		"native capture uses the actual AudioServer output rate and the live six-voice capacity")
	var music_frames := capture.sample_rate * 12 + 37
	var loop_pcm := capture.mix(music_frames)
	check(loop_pcm.size() == music_frames * 8 and capture.sample_frames == music_frames,
		"crossing a real music loop returns precisely the requested stereo float samples")
	check(capture.music.is_playing() and capture.music.get_playback_position() < .02,
		"the actual native music decoder wraps and continues playing")
	check(capture.completed_effects == 0 and capture.eof_silence_frames == 0 and not capture.music_ended,
		"a looping score fills the whole requested span and never receives one-shot EOF padding")
	check(capture.finite and capture.peak > .01 and capture.peak < 1.0 and nonzero(loop_pcm),
		"the native music bed remains finite, nonzero and below full scale")
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(audio.music.stream.data)
	check(capture.stream_fingerprints.camp == hash.finish().hex_encode(),
		"music evidence fingerprints the exact original PCM bytes")
	capture.take_frame_events()
	audio.set_context(true)
	var events := capture.take_frame_events()
	check(events.size() == 1 and events[0].context == "dungeon" and capture.music.get_playback_position() < .02,
		"a real dungeon context change replaces and restarts the native score")
	audio.set_context(true)
	check(capture.take_frame_events().is_empty(), "an unchanged music context does not restart or invent a transition")
	# Cancellation observes the existing accepted path. It never synthesizes a
	# release/contact merely because a committed cast appeared in a frame log.
	audio.combat_events([{"type": "hero_attack", "skill": false}], "Arcanist")
	audio.combat_events([{"type": "evade"}], "Arcanist")
	events = capture.take_frame_events()
	check(events.size() == 2 and events[0].key == "arcane_gather" and events[1].key == "step",
		"an interrupted cast records actual gather/evade without an invented discharge or hit")
	check(events[0].sample_frame == music_frames and events[1].sample_frame == music_frames,
		"coincident accepted cues begin at the same explicit fixed-step sample boundary")
	var accepted := capture.accepted_cues
	var cursor := audio.cursor
	audio.cue("arcane_gather")
	check(capture.accepted_cues == accepted and audio.cursor == cursor and capture.take_frame_events().is_empty(),
		"the real wall-clock duplicate rejection allocates neither a capture cue nor a live voice")
	# Clear that short-lived example through the production suspend path, then
	# allocate seven different keys. Ring slot six must replace only slot zero.
	audio.set_suspended(true)
	check(capture.voices.all(func(value): return value == null),
		"production suspension stops every captured effects playback")
	var paused_position := capture.music.get_playback_position()
	check(all_zero(capture.mix(1470)) and capture.music.get_playback_position() == paused_position,
		"suspension emits exact silence while preserving the paused score position")
	accepted = capture.accepted_cues
	audio.cue("warning")
	check(capture.accepted_cues == accepted, "suspended cues remain rejected by the ordinary director")
	audio.set_suspended(false)
	var keys: Array[String] = ["nova", "starfall", "warning", "hurt", "lightning", "ward", "victory"]
	var first_slot := audio.cursor
	for key in keys: audio.cue(key)
	check(capture.stolen_voices == 1 and capture.voice_keys[first_slot] == "victory",
		"the seventh accepted cue steals the actual first ring slot, rather than adding a seventh voice")
	check(capture.voices.all(func(value): return value != null) and audio.cursor == (first_slot + 7) % Audio.VOICES,
		"coincident accepted sounds keep exactly the live six slots and cursor order")
	for offset in 6:
		var slot := (first_slot + offset) % Audio.VOICES
		var expected := "victory" if offset == 0 else keys[offset]
		check(capture.voice_keys[slot] == expected and audio.voices[slot].stream == Audio.stream_for(expected),
			"captured slot %d retains the exact stream allocated by AudioDirector" % slot)
	var live_pcm := capture.mix(1470)
	check(nonzero(live_pcm) and capture.finite and capture.peak < 1.0,
		"six accepted effects and the original music bed mix audibly with retained headroom")
	audio.apply_preferences({"master": 0.0, "music": 1.0, "effects": 1.0})
	check(all_zero(capture.mix(1470)) and capture.voices.all(func(value): return value == null),
		"actual master mute produces silence and clears existing effects")
	accepted = capture.accepted_cues
	audio.cue("arcane_release")
	check(capture.accepted_cues == accepted, "master mute cannot create a native capture discharge")
	audio.apply_preferences({"master": .5, "music": 0.0, "effects": .4})
	check(is_equal_approx(db_to_linear(audio.voices[0].volume_db), .5 * .4 * .24) and capture.music_is_paused(),
		"capture reads the real normalized gain and independent music mute")
	audio.cue("arcane_release")
	check(nonzero(capture.mix(1470)), "muting the music keeps an accepted effects cue audible")
	audio.apply_preferences({"master": 1.0, "music": 1.0, "effects": 0.0})
	check(capture.voices.all(func(value): return value == null) and nonzero(capture.mix(1470)),
		"effects mute clears voices while the score resumes from its preserved position")
	capture.take_frame_events()
	var previous := capture.sample_frames
	for frame in 30:
		var expected_end := previous + floori(float(frame + 1) * capture.sample_rate / 30.0)
		var block := capture.mix(expected_end - capture.sample_frames)
		check(block.size() % 8 == 0 and capture.sample_frames == expected_end,
			"chronological frame %d has no missing or overlapping native PCM samples" % frame)
	check(capture.sample_frames - previous == capture.sample_rate,
		"thirty recorded frames produce exactly one second of native audio")
	var summary := capture.summary()
	check(summary.finite and summary.channels == 2 and summary.sample_format == "f32le" and summary.rms > 0.0,
		"the durable audio summary describes the real finite stereo PCM and audible energy")
	capture.detach()
	check(not audio.cue_accepted.has_connections() and not audio.music_context_changed.has_connections()
		and not audio.mix_state_changed.has_connections(), "detaching removes all observational connections")
	audio.free()
	var full_gain := isolated_gain_block(1.0)
	var half_gain := isolated_gain_block(.5)
	var gain_matches := full_gain.size() == half_gain.size() and nonzero(full_gain)
	for offset in range(0, full_gain.size(), 4):
		gain_matches = gain_matches and absf(half_gain.decode_float(offset) - full_gain.decode_float(offset) * .5) < .0000001
	check(gain_matches, "halving the actual master preference halves every captured native effects sample in both channels")
	check_native_effect_eof()
	check_native_buffered_tail()
	print("NATIVE CAPTURE AUDIO SMOKE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
