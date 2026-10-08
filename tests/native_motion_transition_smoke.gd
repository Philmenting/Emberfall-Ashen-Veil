extends "res://tests/source_avatar_evade_smoke.gd"
## Actual production actors exercise walk/cast/contact/recovery, early and
## late interrupted casts, moving evade support and a fresh damage response.
## Grip checks reconstruct the rendered weighted finger triangles.
var transition_records: Dictionary = {}
var transitions_sampled := 0

func pose_points(actor: Node3D) -> Dictionary:
	var result := {}
	for name in ["pelvis", "spine_03", "Head", "hand_l", "hand_r", "foot_l", "foot_r"]:
		result[name] = world_bone(actor, name).origin
	result.weapon = actor.weapon_world_position()
	return result

func actual_contact(actor: Node3D, label: String) -> void:
	check(complete_native_lengths(actor.motion_rig), label + ": every native rest, scale and anatomical segment stays original")
	check(weighted_sole_minimum(actor.motion_rig) >= .0029, label + ": actually weighted boot geometry remains above the floor")
	if actor.kind == "Arcanist": audit_pose(actor, label)
	else: audit_class_grip(actor, label)
	transitions_sampled += 1

func held_actual_frame(actor: Node3D, label: String) -> void:
	var frozen: Dictionary = actor.motion_rig._capture_source_pose()
	var prop: Transform3D = actor.motion_rig.weapon.transform
	var clock_before: float = actor.clock
	var attack_before: float = actor.attack_time
	var impact_before: float = actor.impact_time
	for repeat in 4: actor._apply_motion(0.0)
	check(actor.motion_rig._capture_source_pose() == frozen and actor.motion_rig.weapon.transform == prop, label + ": held real transition/recoil is bit-identical and never compounds")
	check(actor.clock == clock_before and actor.attack_time == attack_before and actor.impact_time == impact_before, label + ": visual zero-delta updates advance no clocks")

func audit_native_sequence(class_key: String) -> void:
	var actor = Actor.new()
	actor.kind = class_key
	root.add_child(actor)
	var rig = actor.motion_rig
	grip_side = "l" if class_key == "Ranger" else "r"
	arm_surfaces.clear()
	cache_actual_arm(rig)
	if class_key != "Arcanist": source_radii[class_key] = actual_radius(rig)
	for frame in 20:
		var travel := Vector3(0.0, 0.0, -.0533333)
		actor.position += travel
		actor.follow_travel(travel)
		actor.animate(1.0 / 60.0, true, 3.2)
	actual_contact(actor, class_key + " actual moving walk")
	actor.strike("signature", .36, true)
	var maximum_chest_step := .0
	var maximum_weapon_step := .0
	var maximum_entry_weapon_step := .0
	var previous := pose_points(actor)
	for frame in 16:
		actor.sync_attack(.36 - float(frame) / 60.0)
		actor.animate(1.0 / 60.0, false)
		var current := pose_points(actor)
		maximum_chest_step = maxf(maximum_chest_step, previous.spine_03.distance_to(current.spine_03))
		maximum_weapon_step = maxf(maximum_weapon_step, previous.weapon.distance_to(current.weapon))
		if frame <= 8: maximum_entry_weapon_step = maxf(maximum_entry_weapon_step, previous.weapon.distance_to(current.weapon))
		previous = current
		if frame in [0, 2, 5, 10, 15]: actual_contact(actor, class_key + " live walk-to-signature frame " + str(frame))
	check(maximum_chest_step < .12, class_key + ": ordinary 60Hz walk/cast chest movement has no >12cm frame replacement; actual=" + str(maximum_chest_step))
	# The source sword deliberately accelerates through the later strike.
	# Its full swing speed is recorded separately; this bound targets the
	# guard/clip handover rather than rejecting a legitimate fast blade arc.
	check(maximum_entry_weapon_step < .30, class_key + ": ordinary 60Hz weapon tip follows the real arm through the first9entryframes; actual=" + str(maximum_entry_weapon_step))
	actor.sync_attack(Actor.PROJECTILE_RELEASE_LEAD if class_key != "Vowkeeper" else 0.0)
	actor.animate(0.0, false)
	var draw_hook_head_height := .0
	if class_key == "Ranger":
		var actual_hook: Vector3 = rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone("hand_r")) * rig.class_pose_state.hook_local
		var actual_head: Vector3 = rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone("Head")).origin
		draw_hook_head_height = absf(actual_hook.y-actual_head.y)
		check(draw_hook_head_height < .18,class_key+": actually rendered draw hook reaches natural shoulder/head height; head vertical distance="+str(draw_hook_head_height))
	var launch: Dictionary = rig._capture_source_pose()
	var launch_tip: Vector3 = actor.weapon_world_position()
	check(actor.release_time < 0.0 and actor.external_release and actor.attack_duration == .36, class_key + ": polished motion leaves original committed duration and external release authority intact")
	check(actor.release_attack(), class_key + ": genuine contact is still accepted immediately")
	var exact_contact := true
	var maximum_component_jump := .0
	for bone in 65:
		var first: Quaternion = launch.rotations[bone]
		var second: Quaternion = rig.skeleton.get_bone_pose_rotation(bone)
		var component := maxf(maxf(absf(first.x-second.x),absf(first.y-second.y)),maxf(absf(first.z-second.z),absf(first.w-second.w)))
		maximum_component_jump = maxf(maximum_component_jump,component)
		exact_contact = exact_contact and launch.positions[bone].distance_to(rig.skeleton.get_bone_pose_position(bone)) < .000001 and component < .00001
	check(exact_contact and actor.weapon_world_position().distance_to(launch_tip) < .0001, class_key + ": all65bones and the physical weapon meet exactly across authoritative release")
	actual_contact(actor, class_key + " actual contact boundary")
	for frame in 24: actor.animate(1.0 / 60.0, false)
	check(actor.attack_time < 0.0 and actor.release_time < 0.0, class_key + ": original recovery completes without a stored attack")
	actual_contact(actor, class_key + " ordinary recovery-to-guard")
	var cancel_records: Array[Dictionary] = []
	for cancel_phase in [.32, .67, .93]:
		actor.strike("signature", .36, true)
		var visual_duration: float = .36 - Actor.PROJECTILE_RELEASE_LEAD if class_key != "Vowkeeper" else .36
		actor.sync_attack(.36 - visual_duration * float(cancel_phase))
		actor.animate(.08, false)
		var departure := pose_points(actor)
		var position_before: Transform3D = actor.transform
		var direction := Vector3(-1.0, 0, 0) if cancel_phase < .5 else (Vector3(0, 0, 1.0) if cancel_phase < .8 else Vector3(.707107, 0, .707107))
		var goal: Vector3 = actor.global_position + direction * .90
		actor.begin_evade(actor.global_position, goal)
		actor.animate(0.0, false)
		var entered := pose_points(actor)
		var chest_jump: float = departure.spine_03.distance_to(entered.spine_03)
		var weapon_jump: float = departure.weapon.distance_to(entered.weapon)
		var ankle_jump: float = maxf(departure.foot_l.distance_to(entered.foot_l),departure.foot_r.distance_to(entered.foot_r))
		check(actor.last_clip == "evade" and actor.attack_time < 0.0 and actor.release_time < 0.0 and not actor.external_release and not actor.attack_queued, class_key + ": actual cancel at phase " + str(cancel_phase) + " yields evade without confirming damage")
		check(actor.transform == position_before, class_key + ": switching pose alone never translates or rotates the actual actor")
		check(chest_jump < .035 and weapon_jump < .060, class_key + ": interrupted native chest/weapon enter escape continuously; chest=" + str(chest_jump) + " weapon=" + str(weapon_jump))
		check(ankle_jump < .0001,class_key + ": the actual cancellation event keeps both originally planted world ankles below0.1mm; actual="+str(ankle_jump))
		held_actual_frame(actor, class_key + " real cancelled entry " + str(cancel_phase))
		var largest_escape_step := .0
		previous = entered
		for frame in range(1, 13):
			actor.global_position = actor.evade_state.origin.lerp(goal, float(frame) / 12.0)
			actor.animate(1.0 / 60.0, false)
			var current := pose_points(actor)
			largest_escape_step = maxf(largest_escape_step, previous.weapon.distance_to(current.weapon))
			previous = current
			if frame in [1, 3, 6, 12]: actual_contact(actor, class_key + " cancel=" + str(cancel_phase) + " true escape frame=" + str(frame))
		check(largest_escape_step < .30, class_key + ": interrupted moving escape has no >30cm weapon-tip frame jump; actual=" + str(largest_escape_step))
		actor.sync_evade(false)
		actor.react(1.0, .65)
		actor.animate(.035, false)
		held_actual_frame(actor, class_key + " actual escape landing with fresh impact")
		actual_contact(actor, class_key + " true landing impact")
		actor.strike("basic", .32, true)
		actor.animate(0.0, false)
		check(actor.last_clip == "windup_basic" and actor.evade_time < 0.0 and actor.attack_duration == .32 and actor.external_release, class_key + ": the next committed cast immediately owns state and keeps its original32centisecond duration")
		for frame in 4: actor.animate(1.0 / 60.0, false)
		actual_contact(actor, class_key + " true evade-to-next-cast")
		actor.cancel_attack()
		actor.animate(.50, false)
		cancel_records.append({"normalized_cancel_phase": cancel_phase, "chest_entry_jump_m": chest_jump, "weapon_entry_jump_m": weapon_jump, "maximum_cancel_ankle_world_jump_m":ankle_jump, "maximum_escape_weapon_frame_step_m": largest_escape_step})
	transition_records[class_key] = {"ordinary_walk_cast_maximum_chest_step_m": maximum_chest_step, "ordinary_walk_cast_first9frames_maximum_weapon_step_m":maximum_entry_weapon_step, "ordinary_walk_cast_entire_sampled_phrase_maximum_weapon_step_m": maximum_weapon_step, "actual_release_native65_continuous": exact_contact, "actual_release_maximum_quaternion_component_jump":maximum_component_jump, "ranger_full_draw_hook_to_native_head_height_m":draw_hook_head_height, "cancel_cases": cancel_records}
	actor.free()

func run() -> void:
	for class_key in ["Arcanist", "Ranger", "Vowkeeper"]: audit_native_sequence(class_key)
	print("NATIVE MOTION TRANSITION METRICS ", JSON.stringify(transition_records))
	print("NATIVE MOTION TRANSITION SMOKE: %d checks, %d failures" % [checks, failures.size()])
	arm_surfaces.clear()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)
