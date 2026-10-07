extends "res://tests/arcanist_quality_gameplay_preview.gd"
## Observe the exact ordinary expedition prefix without changing its clocks,
## input, camera, actors, damage, gear, effects or audio. The receiver enforces
## 20–30 seconds and records that the actual expedition remains unfinished.
var first_hit_frame := -1
var first_evade_frame := -1
var first_cast_frames: Dictionary = {}
var selected_pose_markers: Dictionary = {}
var observed_cast_frame := -1
var observed_cast_style := ""
const CaptureActor = preload("res://scripts/dungeon_actor.gd")
const CaptureClips = preload("res://scripts/character_animation.gd")

func _write_json(filename: String, value: Dictionary) -> bool:
	if filename in ["capture-metadata.json", "capture-summary.json"]:
		value["recording_kind"] = "ordinary_expedition_prefix"
		value["prefix_playback_seconds"] = max_simulation_seconds
	if filename == "capture-metadata.json":
		value["scope"] = "Exact chronological start of the ordinary floor-1 Arcanist expedition; original HUD, camera, gear, damage, seed and loadout. This 20–30 second prefix is not a completed dungeon or a victory."
		value["pose_observation_scope"] = "Read-only actual root/body and selected native bone world transforms; all original simulation, camera, visual and audio processing remains inherited unchanged."
		value["native_raider_model_sha256"] = FileAccess.get_sha256("res://assets/models/raider056/raider-native65.glb")
	return super._write_json(filename, value)

func _frame_record(now: int, advanced: bool) -> Dictionary:
	var record: Dictionary = super._frame_record(now, advanced)
	for event in pending_frame_events:
		if event.type == "hit" and first_hit_frame < 0: first_hit_frame = frame_index
		if event.type in ["evade", "backstep"] and first_evade_frame < 0: first_evade_frame = frame_index
		if event.type == "hero_attack":
			observed_cast_style = str(event.get("ability_id", "signature" if event.get("skill", false) else "basic"))
			observed_cast_frame = frame_index
			if not first_cast_frames.has(observed_cast_style): first_cast_frames[observed_cast_style] = frame_index
	record["prefix_first_hit_age"] = frame_index - first_hit_frame if first_hit_frame >= 0 else -1
	record["prefix_first_evade_age"] = frame_index - first_evade_frame if first_evade_frame >= 0 else -1
	if is_instance_valid(run_arena) and is_instance_valid(run_arena.world):
		var world: Node3D = run_arena.world
		record["hero_pose"] = _observed_pose(world.hero)
		record["prefix_pose_markers"] = _first_cast_pose_markers(world.hero)
		var raiders: Array = []
		for actor_id in world.actor_by_id:
			var actor: Node3D = world.actor_by_id[actor_id]
			if actor.kind != "raider": continue
			var observation := _observed_pose(actor)
			observation["id"] = actor_id
			raiders.append(observation)
		record["raider_poses"] = raiders
	return record

func _first_cast_pose_markers(hero: Node3D) -> Array:
	var markers: Array = []
	if hero.attack_time < 0.0 or first_cast_frames.get(observed_cast_style, -2) != observed_cast_frame: return markers
	var phase: float
	var thresholds: Dictionary
	var phrase: String
	var phase_step: float
	if hero.release_time < 0.0:
		var visual_duration: float = hero.attack_duration
		if hero.external_release and hero.attack_style in ["basic", "signature"]:
			visual_duration = maxf(.06, visual_duration - CaptureActor.PROJECTILE_RELEASE_LEAD)
		phase = hero.attack_time / visual_duration
		phase_step = CAPTURE_STEP / visual_duration
		thresholds = {"load": .32, "drive": .65, "pre-contact": .95}
		phrase = "windup"
	else:
		var duration: float = CaptureClips.recovery_duration(hero.appearance_key, hero.attack_style)
		phase = hero.release_time / duration
		phase_step = CAPTURE_STEP / duration
		thresholds = {"follow-through": .16, "catch": .5}
		phrase = "recovery"
	for label in thresholds:
		var marker := "first-" + observed_cast_style + "-" + phrase + "-" + str(label)
		# Choose the nearest original30Hzframe instead of capturing a frame
		# late when a short load/drive phase lies between playback samples.
		if phase >= float(thresholds[label]) - phase_step * .5 and not selected_pose_markers.has(marker):
			markers.append(marker)
			selected_pose_markers[marker] = true
	return markers

func _observed_pose(actor: Node3D) -> Dictionary:
	var observation: Dictionary = {
		"root": _transform_record(actor.global_transform),
		"body": _transform_record(actor.body.global_transform),
		"source_avatar": actor.source_avatar,
		"attack_time": actor.attack_time,
		"release_time": actor.release_time,
		"impact_time": actor.impact_time,
		"death_time": actor.death_time,
		"clip": actor.last_clip,
		"evade_time": actor.evade_time,
		"evade_duration": actor.evade_duration,
		"evade_phase": actor.evade_phase,
		"evade_path_active": actor.evade_path_active,
	}
	if not actor.source_avatar: return observation
	var rig: RefCounted = actor.motion_rig
	var bones: Dictionary = {}
	for name in ["pelvis", "spine_01", "spine_03", "Head", "upperarm_l", "upperarm_r", "hand_l", "hand_r", "thigh_l", "thigh_r", "foot_l", "foot_r"]:
		var bone: int = rig.skeleton.find_bone(name)
		if bone >= 0:
			bones[name] = _transform_record(rig.skeleton.global_transform * rig.skeleton.get_bone_global_pose(bone))
	observation["bones_world"] = bones
	observation["native_model"] = _transform_record(rig.motion_node.global_transform)
	return observation
