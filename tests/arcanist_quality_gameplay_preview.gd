extends "res://tests/attack_gameplay_preview.gd"
## Continuous ordinary Arcanist expedition, including travel and the first guardian.
## A localhost receiver encodes every original viewport PNG without accumulating files.
## Fixed simulation steps establish playback speed; capture wall time is not game FPS.
const CAPTURE_STEP := 1.0 / 30.0
const SETTLE_FRAMES := 90
const STREAM_TIMEOUT_USEC := 120000000
const NativeAudio = preload("res://tests/native_capture_audio.gd")
var stream := StreamPeerTCP.new()
var stream_port := 0
var max_simulation_seconds := 240.0
var records: FileAccess
var pending_frame_events: Array = []
var guardian_seen := false
var guardian_warning_seen := false
var capture_failed := false
var previous_frame_usec := 0
var holding_result_ui := false
var result_frames := 0
var manual_rendering := false
var previous_render_loop_enabled := true
var capture_portraits: Array = []
var native_audio: RefCounted
var audio_file: FileAccess

func _exit_tree() -> void:
	_restore_render_loop()
	if audio_file != null: audio_file.close()
	if native_audio != null: native_audio.detach()

func _build_ui() -> void:
	# Main's 2.2-second result timer advances during slow PNG transport. Hold
	# its original UI builder for the equivalent 66 recorded simulation frames.
	if holding_result_ui and result_frames < 66: return
	super._build_ui()
	_capture_portrait_nodes()

func _capture_portrait_nodes() -> void:
	capture_portraits.clear()
	for node in find_children("*","Control",true,false):
		if node.get_script()==HeroArt:
			node.set_process(false)
			capture_portraits.append(node)

func _step_portraits() -> void:
	# Software rendering can take seconds per output frame. The portrait's
	# original 24 Hz update rule must follow playback time, like the world,
	# instead of turning its ordinary breathing into an accelerated flicker.
	for portrait in capture_portraits:
		if is_instance_valid(portrait):portrait._process(CAPTURE_STEP)

func _finish_run_presentation() -> void:
	holding_result_ui = true
	super._finish_run_presentation()

func _on_combat_advanced(updates: Array) -> void:
	pending_frame_events.append_array(updates.duplicate(true))
	super._on_combat_advanced(updates)

func _record() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--stream-port="):
			stream_port = int(argument.trim_prefix("--stream-port="))
		if argument.begins_with("--max-simulation-seconds="):
			max_simulation_seconds = float(argument.trim_prefix("--max-simulation-seconds="))
	if stream_port < 1 or stream_port > 65535 or max_simulation_seconds <= 0.0 or max_simulation_seconds > 240.0:
		_capture_error("Provide a localhost stream port and a simulation limit in (0, 240].")
		return
	if stream.connect_to_host("127.0.0.1", stream_port) != OK:
		_capture_error("Could not connect to the localhost capture receiver.")
		return
	var deadline := Time.get_ticks_usec() + STREAM_TIMEOUT_USEC
	while stream.get_status() == StreamPeerTCP.STATUS_CONNECTING:
		stream.poll()
		if Time.get_ticks_usec() > deadline:
			_capture_error("Capture receiver connection timed out.")
			return
		await get_tree().process_frame
	if stream.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		_capture_error("Capture receiver rejected the connection.")
		return
	stream.set_no_delay(true)
	get_window().size = Vector2i(1200, 536)
	await get_tree().process_frame
	character_class = "Arcanist"
	floor_number = 1
	auto_repeat = false
	# Use the same available technique equip action as the player's Armory.
	# Chain, Starfall and the always-equipped signature exercise all cast phrases.
	_equip_technique("chain", 0)
	_equip_technique("starfall", 1)
	_start_run(1)
	_manual()
	await _settle_renderer()
	_capture_portrait_nodes()
	if not run_arena.world.hero.source_avatar:
		_capture_error("The ordinary Arcanist did not load the native source avatar.")
		return
	native_audio = NativeAudio.new()
	native_audio.attach(audio)
	audio_file = FileAccess.open(capture_dir + "/native-game-audio.f32le", FileAccess.WRITE)
	if audio_file == null:
		_capture_error("Could not create the native accepted-cue PCM stream.")
		return
	previous_render_loop_enabled = RenderingServer.is_render_loop_enabled()
	RenderingServer.set_render_loop_enabled(false)
	manual_rendering = true
	records = FileAccess.open(capture_dir + "/frames.jsonl", FileAccess.WRITE)
	if records == null:
		_capture_error("Could not create the chronological frame log.")
		return
	var metadata: Dictionary = {
		"schema": 1,
		"scope": "Continuous ordinary floor-1 Arcanist expedition; original Main HUD, camera, effects, gear and damage; no travel cuts or stat overrides.",
		"simulation_step_seconds": CAPTURE_STEP,
		"playback_fps": 30,
		"maximum_simulation_seconds": max_simulation_seconds,
		"settle_frames": SETTLE_FRAMES,
		"world_seed": world_seed,
		"run_seed": expedition.run_seed,
		"initial_stats": _json_value(expedition.stats),
		"selected_skill_loadout": _json_value(Skills.normalize(character_class, skill_loadouts.get(character_class))),
		"loadout_scope": "Player-selectable Chain and Starfall equipped through the ordinary Armory action; unchanged starting gear and combat formulas.",
		"platform": OS.get_name(),
		"engine_version": Engine.get_version_info(),
		"device": OS.get_model_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"video_adapter": RenderingServer.get_video_adapter_name(),
		"video_adapter_vendor": RenderingServer.get_video_adapter_vendor(),
		"viewport": [get_window().size.x, get_window().size.y],
		"source_model_sha256": FileAccess.get_sha256("res://assets/models/nyra052/arcanist.glb"),
		"staff_sha256": FileAccess.get_sha256("res://assets/models/nyra052/staff-grip053.glb"),
		"grip_profile_sha256": FileAccess.get_sha256("res://assets/models/nyra052/staff-grip053.json"),
		"death_grounding_sha256": FileAccess.get_sha256("res://assets/models/nyra052/death-grounding.json"),
		"cast_director_sha256": FileAccess.get_sha256("res://scripts/source_avatar_combat.gd"),
		"projection_scope": "Camera subviewport coordinates; current conservative actor pose bounds, including source joint influence envelopes and actual staff geometry. Rectangle overlap is a visibility proxy, not a rendered-pixel occlusion measurement.",
		"wall_time_scope": "Capture intervals include viewport readback, PNG encoding and encoder acknowledgements. They are not normal gameplay frame-rate measurements.",
		"render_driver_scope": "Capture fixture disables automatic rendering after normal scene warmup. Two SceneTree ticks flush deferred scene changes; force_sync and force_draw render exactly one original viewport per recorded simulation step. TCP polling can yield without redundant GPU draws. Production quality, camera and runtime assets are unchanged.",
		"audio_scope": native_audio.summary().scope,
		"audio_sample_rate": native_audio.sample_rate,
		"audio_channels": 2,
		"audio_clock_scope": native_audio.summary().cue_clock_scope,
		"result_ui_timer_scope": "The original Main result UI builder is held until 66 recorded ending frames, preserving its normal 2.2-second delay in fixed-step playback despite slow capture transport.",
		"portrait_clock_scope": "Original HeroArt animation advances on fixed 30 Hz playback, retaining its original 1/24-second update threshold (updates every two recorded frames). Slow software viewport export does not advance portrait motion between recorded frames.",
		"physical_device_performance": false
	}
	if not _write_json("capture-metadata.json", metadata): return
	previous_frame_usec = Time.get_ticks_usec()
	var settle := 0
	var frame_limit := ceili(max_simulation_seconds / CAPTURE_STEP)
	while frame_index < frame_limit + SETTLE_FRAMES:
		pending_frame_events.clear()
		var advanced := false
		if not expedition.finished and frame_index < frame_limit:
			if page != "run" or not is_instance_valid(run_arena):
				_capture_error("The ordinary expedition left the run scene before finishing.")
				return
			run_arena.world._process(CAPTURE_STEP)
			advanced = true
		elif expedition.finished:
			settle += 1
			result_frames = settle
			if is_instance_valid(run_arena) and is_instance_valid(run_arena.world):
				# advance() returns no events after finishing, while the original
				# world still advances its collapse and effect presentation.
				run_arena.world._process(CAPTURE_STEP)
			if holding_result_ui and settle == 66:
				holding_result_ui = false
				_build_ui()
		else:
			break
		_step_portraits()
		# Flush deferred scene/transform updates without rendering a second
		# costly software frame while the TCP receiver acknowledges the PNG.
		await get_tree().process_frame
		await get_tree().process_frame
		RenderingServer.force_sync()
		RenderingServer.force_draw(false, CAPTURE_STEP)
		var now := Time.get_ticks_usec()
		var record := _frame_record(now, advanced)
		var first_sample: int = native_audio.sample_frames
		var expected_end := floori(float(frame_index + 1) * native_audio.sample_rate / 30.0)
		var pcm: PackedByteArray = native_audio.mix(expected_end - first_sample)
		audio_file.store_buffer(pcm)
		if not native_audio.finite or native_audio.peak > 1.0:
			_capture_error("Native game PCM is nonfinite or exceeds full-scale mix headroom.")
			return
		record["audio"] = {"first_sample_frame": first_sample, "end_sample_frame": native_audio.sample_frames,
			"sample_rate": native_audio.sample_rate, "channels": 2,
			"accepted_state_events": native_audio.take_frame_events()}
		records.store_line(JSON.stringify(record))
		records.flush()
		previous_frame_usec = now
		var pixels := get_viewport().get_texture().get_image().save_png_to_buffer()
		if pixels.is_empty() or not await _send_png(pixels):
			if not capture_failed:
				_capture_error("Viewport capture or streaming failed.")
			return
		frame_index += 1
		if expedition.finished and settle >= SETTLE_FRAMES:
			break
	records.close()
	audio_file.close()
	var summary: Dictionary = {
		"schema": 1,
		"frames": frame_index,
		"playback_seconds": frame_index * CAPTURE_STEP,
		"simulation_elapsed": expedition.elapsed,
		"simulation_finished": expedition.finished,
		"won": expedition.won,
		"guardian_seen": guardian_seen,
		"guardian_warning_seen": guardian_warning_seen,
		"settle_frames_recorded": settle,
		"complete": expedition.finished and settle >= SETTLE_FRAMES,
		"audio": native_audio.summary(),
		"native_pcm_sha256": FileAccess.get_sha256(capture_dir + "/native-game-audio.f32le"),
		"scope": "Recording completeness and actual combat outcome; no visual or release approval."
	}
	if not _write_json("capture-summary.json", summary): return
	stream.disconnect_from_host()
	_restore_render_loop()
	print("ARCANIST_QUALITY_CAPTURE_COMPLETE " if summary.complete else "ARCANIST_QUALITY_CAPTURE_INCOMPLETE ", JSON.stringify(summary))
	get_tree().quit(0)

func _frame_record(now: int, advanced: bool) -> Dictionary:
	var record: Dictionary = {
		"frame": frame_index,
		"playback_seconds": frame_index * CAPTURE_STEP,
		"simulation_advanced": advanced,
		"simulation_elapsed": expedition.elapsed,
		"simulation_accumulator": expedition.accumulator,
		"stage": expedition.stage,
		"phase": expedition.phase,
		"page": page,
		"finished": expedition.finished,
		"won": expedition.won,
		"hero_hp": expedition.hero_hp,
		"pending_attack": _json_value(expedition.pending_attack),
		"events": _json_value(pending_frame_events),
		"capture_wall_usec": now,
		"capture_frame_interval_ms": float(now - previous_frame_usec) / 1000.0
	}
	var guardian: Dictionary = expedition.enemy_by_id(50)
	if not guardian.is_empty():
		record["guardian"] = {"hp": guardian.hp, "maximum_hp": guardian.max_hp, "warning": _json_value(guardian.warning), "boss_phase": guardian.get("boss_phase", 0)}
		if expedition.stage == 5 and expedition.phase == "combat":
			guardian_seen = true
			if not guardian.warning.is_empty(): guardian_warning_seen = true
	if is_instance_valid(run_arena) and is_instance_valid(run_arena.world):
		var world: Node3D = run_arena.world
		var hero: Node3D = world.hero
		var camera: Camera3D = world.camera
		record["camera"] = _transform_record(camera.global_transform)
		record["render_viewport"] = [camera.get_viewport().get_visible_rect().size.x, camera.get_viewport().get_visible_rect().size.y]
		record["hero"] = {
			"position": _vector_record(hero.global_position),
			"clip": hero.last_clip,
			"attack_style": hero.attack_style,
			"attack_time": hero.attack_time,
			"attack_duration": hero.attack_duration,
			"release_time": hero.release_time,
			"source_avatar": hero.source_avatar,
			"skeleton_bones": hero.motion_rig.skeleton.get_bone_count(),
			"native_sample": hero.motion_rig.last_sample,
			"native_sample_time": hero.motion_rig.last_time,
			"grip_world": _vector_record(hero.weapon_grip_position()),
			"casting_palm_world": _vector_record(hero.projectile_origin()),
			"projection": _actor_projection(hero, camera)
		}
		if world.actor_by_id.has(50):
			record["guardian_projection"] = _actor_projection(world.actor_by_id[50], camera)
	return record

func _actor_projection(actor: Node3D, camera: Camera3D) -> Dictionary:
	var bounds: AABB = actor.pose_bounds()
	var minimum := Vector2(INF, INF)
	var maximum := Vector2(-INF, -INF)
	var behind := 0
	for corner in 8:
		var point: Vector3 = actor.global_transform * bounds.get_endpoint(corner)
		if camera.is_position_behind(point): behind += 1
		var projected := camera.unproject_position(point)
		minimum = minimum.min(projected)
		maximum = maximum.max(projected)
	var viewport := camera.get_viewport().get_visible_rect()
	var rectangle := Rect2(minimum, maximum - minimum)
	return {
		"rectangle": [rectangle.position.x, rectangle.position.y, rectangle.size.x, rectangle.size.y],
		"viewport_intersection": rectangle.intersects(viewport),
		"fully_inside_viewport": viewport.encloses(rectangle),
		"corners_behind_camera": behind,
		"actor_visible": actor.is_visible_in_tree(),
		"bounds_source": "actor.pose_bounds(): conservative current source skin and staff bounds"
	}

func _send_png(pixels: PackedByteArray) -> bool:
	var length := pixels.size()
	var packet := PackedByteArray([(length >> 24) & 255, (length >> 16) & 255, (length >> 8) & 255, length & 255])
	packet.append_array(pixels)
	var cursor := 0
	var deadline := Time.get_ticks_usec() + STREAM_TIMEOUT_USEC
	while cursor < packet.size():
		stream.poll()
		if stream.get_status() != StreamPeerTCP.STATUS_CONNECTED or Time.get_ticks_usec() > deadline:
			_capture_error("PNG stream disconnected or stalled.")
			return false
		var result := stream.put_partial_data(packet.slice(cursor, mini(cursor + 65536, packet.size())))
		if result[0] != OK:
			_capture_error("Could not send PNG bytes to the receiver.")
			return false
		cursor += int(result[1])
		if result[1] == 0: await get_tree().process_frame
	while stream.get_available_bytes() < 1:
		stream.poll()
		if stream.get_status() != StreamPeerTCP.STATUS_CONNECTED or Time.get_ticks_usec() > deadline:
			_capture_error("Encoder acknowledgement timed out.")
			return false
		await get_tree().process_frame
	var acknowledgement := stream.get_data(1)
	if acknowledgement[0] != OK or acknowledgement[1][0] != 6:
		_capture_error("Encoder rejected the frame.")
		return false
	return true

func _capture_error(message: String) -> void:
	capture_failed = true
	if records != null: records.close()
	stream.disconnect_from_host()
	_restore_render_loop()
	push_error("ARCANIST_QUALITY_CAPTURE_FAIL " + message)
	get_tree().quit(1)

func _restore_render_loop() -> void:
	if manual_rendering:
		RenderingServer.set_render_loop_enabled(previous_render_loop_enabled)
		manual_rendering = false

func _write_json(filename: String, value: Dictionary) -> bool:
	var output := FileAccess.open(capture_dir + "/" + filename, FileAccess.WRITE)
	if output == null:
		_capture_error("Could not write " + filename)
		return false
	output.store_string(JSON.stringify(value, "\t"))
	output.close()
	return true

func _vector_record(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

func _transform_record(value: Transform3D) -> Dictionary:
	return {"origin": _vector_record(value.origin), "basis": [_vector_record(value.basis.x), _vector_record(value.basis.y), _vector_record(value.basis.z)]}

func _json_value(value: Variant) -> Variant:
	if value is Vector2: return [value.x, value.y]
	if value is Vector3: return _vector_record(value)
	if value is Color: return [value.r, value.g, value.b, value.a]
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value: result[String(key)] = _json_value(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item in value: result.append(_json_value(item))
		return result
	return value
