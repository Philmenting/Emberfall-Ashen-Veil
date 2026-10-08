extends "res://tests/class_avatar_quality_smoke.gd"
## Audit the real native bones, weighted boots and indexed hand geometry of
## the directional procedural evade, rather than checking a label or socket.
const Evade = preload("res://scripts/source_avatar_evade.gd")
const ClassRig = preload("res://scripts/class_avatar_rig.gd")
const Simulation = preload("res://scripts/expedition_simulation.gd")
const World = preload("res://scripts/dungeon_world.gd")
const Bot = preload("res://tests/balance_survey_bot.gd")
const RealSkinAudit = preload("res://tests/source_avatar_skin.gd")
var evade_metrics: Dictionary = {}
var production_metrics: Dictionary = {}

func pose_evade(actor: Node3D, state: Dictionary, phase: float, distance_progress: float) -> void:
	actor.global_position = state.origin + state.direction_world * state.distance_world * distance_progress
	var before := actor.transform
	actor.motion_rig.pose("evade", 0.0)
	Evade.apply(actor.motion_rig, actor, phase, state)
	actor.motion_rig.apply_actor_postprocess(actor, "evade", phase, 0.0, true)
	check(actor.transform == before, "Evade posing preserves the actual actor transform")

func world_bone(actor: Node3D, name: String) -> Transform3D:
	var rig = actor.motion_rig
	return rig.motion_node.global_transform * rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone(name))

func weighted_sole_minimum(rig: RefCounted) -> float:
	var minimum := INF
	for probe in rig.floor_probes:
		var point := Vector3.ZERO
		for index in probe.bones.size():
			point += (rig.skeleton.get_bone_global_pose(probe.bones[index]) * probe.binds[index] * probe.point) * probe.weights[index]
		minimum = minf(minimum, (rig.motion_node.transform * point).y)
	return minimum

func indexed_weapon_minimum(actor: Node3D) -> float:
	var minimum := INF
	var points := 0
	for part: MeshInstance3D in actor.motion_rig.weapon.find_children("*", "MeshInstance3D", true, false):
		if not part.is_visible_in_tree() or part.mesh == null:
			continue
		var surfaces: Array = []
		if part.mesh is ArrayMesh:
			for slot in part.mesh.get_surface_count():
				surfaces.append(part.mesh.surface_get_arrays(slot))
		elif part.mesh is PrimitiveMesh:
			surfaces.append(part.mesh.get_mesh_arrays())
		for arrays in surfaces:
			for index in arrays[Mesh.ARRAY_INDEX]:
				var point: Vector3 = actor.body.to_local(part.to_global(arrays[Mesh.ARRAY_VERTEX][index]))
				assert(point.is_finite(), "Actually indexed held prop geometry must remain finite")
				minimum = minf(minimum, point.y)
				points += 1
	check(points > 100 and is_finite(minimum), actor.kind + ": weapon floor includes actual indexed shaft/bow/sword/string meshes and node transforms")
	return minimum

func complete_native_lengths(rig: RefCounted) -> bool:
	var skeleton: Skeleton3D = rig.skeleton
	for bone in skeleton.get_bone_count():
		if not skeleton.get_bone_global_pose(bone).is_finite():
			return false
		if skeleton.get_bone_pose_scale(bone).distance_to(Vector3.ONE) > .00001:
			return false
		if not skeleton.get_bone_global_rest(bone).is_equal_approx(rig.rest[bone]):
			return false
		var parent := skeleton.get_bone_parent(bone)
		if parent < 0 or String(skeleton.get_bone_name(bone)) in ["root", "pelvis"]:
			continue
		var actual: float = skeleton.get_bone_global_pose(bone).origin.distance_to(skeleton.get_bone_global_pose(parent).origin)
		var original: float = rig.rest[bone].origin.distance_to(rig.rest[parent].origin)
		if absf(actual - original) > .00002:
			return false
	return true

func audit_class(class_key: String) -> void:
	var actor = Actor.new()
	actor.kind = class_key
	actor.position = Vector3(2.7, .13, -1.4)
	actor.rotation.y = .63
	root.add_child(actor)
	var rig = actor.motion_rig
	check(actor.source_avatar and rig.skeleton.get_bone_count() == 65, class_key + ": real production native65 anatomy supports evade")
	grip_side = "l" if class_key == "Ranger" else "r"
	cache_actual_arm(rig)
	if class_key != "Arcanist":
		source_radii[class_key] = actual_radius(rig)
	var minimum_drop := INF
	var maximum_drop := 0.0
	var minimum_lean := INF
	var maximum_support_drift := 0.0
	var minimum_floor := INF
	var minimum_whole_outfit := INF
	var minimum_weapon := INF
	for direction_index in 8:
		actor.position = Vector3(2.7, .13, -1.4)
		actor.rotation.y = .63
		var world_direction := Vector3(cos(direction_index * TAU / 8.0), 0.0, sin(direction_index * TAU / 8.0))
		rig.pose("evade", 0.0)
		rig.apply_actor_postprocess(actor, "evade", 0.0, 0.0, true)
		var base_pose: Dictionary = rig._capture_source_pose()
		var base_pelvis := world_bone(actor, "pelvis").origin
		var base_chest := world_bone(actor, "spine_03").origin - base_pelvis
		var state := Evade.begin(actor, actor.global_position, actor.global_position + world_direction * 2.4)
		check(state.direction_world.dot(world_direction) > .9999 and is_equal_approx(state.distance_world, 2.4), class_key + ": evade uses the actual world path in direction " + str(direction_index))
		var state_before := state.duplicate(true)
		for phase in [0.0, .12, .30, .50, .72, .86, 1.0]:
			pose_evade(actor, state, phase, phase)
			check(complete_native_lengths(rig), class_key + ": all65 bones retain original rests, scales and limb lengths at phase " + str(phase))
			minimum_floor = minf(minimum_floor, weighted_sole_minimum(rig))
			check(weighted_sole_minimum(rig) >= .0025, class_key + ": actually weighted boot geometry clears the original ground at phase " + str(phase))
			var whole_outfit: AABB = RealSkinAudit.actual_bounds(rig, rig.style.accessories)
			minimum_whole_outfit = minf(minimum_whole_outfit, whole_outfit.position.y)
			check(whole_outfit.position.y >= .0015, class_key + ": every actually indexed weighted source garment, robe tail and accessory clears the original ground at phase " + str(phase) + "; minimum=" + str(whole_outfit.position.y))
			var weapon_floor := indexed_weapon_minimum(actor)
			minimum_weapon = minf(minimum_weapon, weapon_floor)
			check(weapon_floor >= .002, class_key + ": actual indexed held weapon clears the original ground throughout evade; minimum=" + str(weapon_floor))
			if phase == .50:
				var expected_pelvis: Vector3 = base_pelvis + world_direction * 2.4 * phase
				var pelvis := world_bone(actor, "pelvis").origin
				var drop: float = expected_pelvis.y - pelvis.y
				var lean := ((world_bone(actor, "spine_03").origin - pelvis) - base_chest).dot(world_direction)
				minimum_drop = minf(minimum_drop, drop)
				maximum_drop = maxf(maximum_drop, drop)
				minimum_lean = minf(minimum_lean, lean)
				check(drop > .10 and drop < .36, class_key + ": centre of gravity visibly lowers within adult anatomy; drop=" + str(drop))
				check(lean > .015, class_key + ": articulated chest leans into the actual escape direction; lean=" + str(lean))
				for side in ["l", "r"]:
					var thigh: Vector3 = rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone("thigh_" + side)).origin
					var knee: Vector3 = rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone("calf_" + side)).origin
					var ankle: Vector3 = rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone("foot_" + side)).origin
					var leg_axis := (ankle - thigh).normalized()
					var bend := knee - thigh - leg_axis * (knee - thigh).dot(leg_axis)
					check(bend.z > .015, class_key + ": actual anatomical knee bends toward the source forward plane during every escape direction; side=" + side + " forward=" + str(bend.z))
				if class_key == "Arcanist":
					audit_pose(actor, class_key + " evade direction " + str(direction_index))
				else:
					audit_class_grip(actor, class_key + " evade direction " + str(direction_index))
			if phase in [0.0, 1.0]:
				check(rig._capture_source_pose() == base_pose, class_key + ": every native bone returns exactly to the same source combat guard at evade boundary")
		check(state == state_before, class_key + ": posing never mutates captured path/contact state")
		pose_evade(actor, state, .40, .05)
		var held_pose: Dictionary = rig._capture_source_pose()
		var held_weapon: Transform3D = rig.weapon.transform
		var support := "foot_l" if state.lead_side == 0 else "foot_r"
		var support_world := world_bone(actor, support).origin
		for held in 4:
			pose_evade(actor, state, .40, .05)
		check(rig._capture_source_pose() == held_pose and rig.weapon.transform == held_weapon, class_key + ": repeated frozen evade phase has zero accumulating pose or grip drift")
		pose_evade(actor, state, .40, .10)
		var drift := world_bone(actor, support).origin.distance_to(support_world)
		maximum_support_drift = maxf(maximum_support_drift, drift)
		check(drift < .001, class_key + ": actual support ankle holds its world anchor during the real low-step stance; drift=" + str(drift))
		pose_evade(actor, state, .55, .50)
		var midpoint: Dictionary = rig._capture_source_pose()
		pose_evade(actor, state, .22, .10)
		pose_evade(actor, state, .55, .50)
		check(rig._capture_source_pose() == midpoint, class_key + ": evade pose is independent of previous samples")
		check(is_equal_approx(Evade.path_progress(actor, state), .50), class_key + ": progress is derived from actual visual actor displacement")
		rig.pose("walk", .31)
		rig.apply_actor_postprocess(actor, "walk", .31, 0.0, true)
		var walked: Dictionary = rig._capture_source_pose()
		pose_evade(actor, state, .55, .50)
		rig.pose("walk", .31)
		rig.apply_actor_postprocess(actor, "walk", .31, 0.0, true)
		check(rig._capture_source_pose() == walked, class_key + ": ordinary source walking retains no cancelled evade pose")
	evade_metrics[class_key] = {"directions": 8, "native_bones": 65, "minimum_crouch_world_m": minimum_drop, "maximum_crouch_world_m": maximum_drop, "minimum_directional_chest_lean_world_m": minimum_lean, "maximum_world_support_drift_m": maximum_support_drift, "minimum_weighted_boot_source_y_m": minimum_floor, "minimum_all_weighted_source_and_accessory_y_m": minimum_whole_outfit, "minimum_actual_indexed_weapon_source_y_m": minimum_weapon}
	actor.free()

func audit_actor_lifecycle(class_key: String) -> void:
	var actor = Actor.new()
	actor.kind = class_key
	actor.position = Vector3(2.7, .13, -1.4)
	actor.rotation.y = .63
	root.add_child(actor)
	actor.strike("signature", .40, true)
	actor.sync_attack(.28)
	actor.animate(.06, false)
	var origin: Vector3 = actor.global_position
	var goal := origin + Vector3(-1.7, 0, 1.7)
	actor.begin_evade(origin, goal)
	check(actor.evade_time == 0.0 and actor.attack_time < 0.0 and actor.release_time < 0.0 and not actor.external_release, class_key + ": real evade event cancels the existing visible cast without releasing it")
	actor.global_position = origin.lerp(goal, .45)
	actor.sync_evade(true)
	actor.animate(.06, true, 6.8)
	check(actor.last_clip == "evade" and is_equal_approx(actor.evade_phase, .45 * .78), class_key + ": production actor owns a directional evade clip driven by actual path displacement")
	check(complete_native_lengths(actor.motion_rig), class_key + ": production blend and evade retain every native limb length")
	var held: Dictionary = actor.motion_rig._capture_source_pose()
	var time_before: float = actor.evade_time
	var phase_before: float = actor.evade_phase
	for sample in 4:
		actor._apply_motion(0.0, true)
	check(actor.motion_rig._capture_source_pose() == held and actor.evade_time == time_before and actor.evade_phase == phase_before, class_key + ": repeated actual actor posing changes neither pose nor evade clock")
	actor.global_position = goal
	actor.sync_evade(false)
	actor.animate(.07, false)
	check(actor.last_clip == "evade" and actor.evade_phase > .78 and actor.evade_phase < 1.0, class_key + ": actual path completion settles back into the source combat guard")
	actor.strike("basic", .32, true)
	actor.animate(0.0, false)
	check(actor.evade_time < 0.0 and actor.evade_state.is_empty() and actor.last_clip == "windup_basic" and actor.attack_duration == .32 and actor.external_release, class_key + ": a genuinely committed next cast immediately takes the pose with its original timing")
	actor.begin_evade(goal, goal + Vector3(.60, 0.0, .60))
	actor.global_position = goal + Vector3(.60, 0.0, .60)
	actor.sync_evade(false)
	actor.animate(.15, false)
	check(actor.evade_time < 0.0 and actor.evade_state.is_empty() and actor.last_clip != "evade", class_key + ": completed visual recovery leaves no persistent dodge state")
	actor.begin_evade(actor.global_position, actor.global_position + Vector3(1.0, 0, 0))
	actor.die()
	actor.animate(.06, false)
	check(actor.evade_time < 0.0 and actor.evade_state.is_empty() and actor.last_clip == "death", class_key + ": death immediately ends evade and owns the original source death clip")
	production_metrics[class_key] = {"real_actor_begin_sync_settle": true, "new_cast_keeps_original_timing": true, "death_priority": true}
	actor.free()

func audit_world_event_and_restore() -> void:
	var game := Bot.new()
	game.character_class = "Arcanist"
	var simulation := Simulation.new()
	simulation.setup("Arcanist", game._combat_stats(), 1, "Guardian", 1979)
	# A bounded warning fixture exercises the real simulation's ordinary
	# warning -> cancellation -> 6.8 m/s escape. Health, damage, movement
	# speed, i-frames, equipment and rewards are the normal production values.
	var source_room := -1
	var hexer: Dictionary = {}
	for room in simulation.waves.size():
		for enemy: Dictionary in simulation.waves[room]:
			if enemy.role == "hexer" and enemy.get("spawned", true):
				source_room = room
				hexer = enemy
				break
		if not hexer.is_empty():
			break
	check(not hexer.is_empty(), "Real-world evade fixture uses its original native Hexer warning source")
	if hexer.is_empty():
		game.free()
		return
	simulation.stage = source_room
	simulation.phase = "combat"
	simulation.hero_pos = simulation._clamp_walkable(simulation.checkpoint(source_room) + Vector2(0, 1.0))
	simulation.attack_cd = 1.0
	simulation.skill_cd = 1.0
	var warning_radius := float(hexer.get("warning_radius", 1.15))
	var warning_duration := float(hexer.get("warning_duration", 1.0))
	simulation._warn(hexer, warning_radius, warning_duration)
	var reference := Simulation.new()
	check(reference.restore_encoded(simulation.encode_snapshot()), "Reference restores the exact warning/RNG/hero authority snapshot")
	var world = World.new()
	world.simulation = simulation
	world.character_class = "Arcanist"
	world.position = Vector3(4.0, 0.0, -6.0)
	world.rotation.y = .47
	world.active = false
	root.add_child(world)
	world.set_process(false)
	world.active = true
	var camera_before: Transform3D = world.camera.transform
	var same_authority := true
	var camera_stable := true
	var event_seen := false
	var actual_evade_seen := false
	var world_goal_correct := false
	var support_samples := 0
	var previous_support := Vector3.ZERO
	var maximum_support_drift := 0.0
	var saved_inflight := ""
	for frame in 72:
		world._process(1.0 / 60.0)
		var events: Array = reference.advance(1.0 / 60.0)
		same_authority = same_authority and simulation.encode_snapshot() == reference.encode_snapshot()
		camera_stable = camera_stable and world.camera.transform.is_equal_approx(camera_before)
		for event in events:
			if event.type in ["evade", "backstep"]:
				event_seen = true
				saved_inflight = simulation.encode_snapshot()
				actual_evade_seen = world.hero.last_clip == "evade" and world.hero.evade_time >= 0.0
				var expected_goal: Vector3 = world.to_global(world._point(event.goal))
				world_goal_correct = world.hero.evade_state.goal.distance_to(expected_goal) < .00001
		if world.hero.evade_time >= 0.0 and world.hero.evade_phase >= .15 and world.hero.evade_phase <= .73:
			var state: Dictionary = world.hero.evade_state
			var travelled: float = (world.hero.global_position - state.origin).dot(state.direction_world)
			if travelled < .23 * 1.50 * float(state.scale_world):
				var side := "foot_l" if state.lead_side == 0 else "foot_r"
				var current_support := world_bone(world.hero, side).origin
				if support_samples > 0:
					maximum_support_drift = maxf(maximum_support_drift, current_support.distance_to(previous_support))
				previous_support = current_support
				support_samples += 1
	check(event_seen and actual_evade_seen, "A real simulation warning/evade event reaches the production world and native evade pose")
	check(world_goal_correct, "An actually translated and rotated world converts the original local simulation goal to the correct real global evade path")
	check(support_samples >= 2 and maximum_support_drift < .001, "The actual transformed world preserves its real support ankle during the low step; samples=" + str(support_samples) + " drift=" + str(maximum_support_drift))
	check(same_authority, "Real world evade/animation leaves original movement, HP, pending attacks, RNG, i-frames and rewards byte-identical to a presentation-free simulation")
	check(camera_stable, "The actual room camera stays fixed through warning, low-step evade, landing and next cast")
	world.free()
	if not saved_inflight.is_empty():
		var restored := Simulation.new()
		var restored_reference := Simulation.new()
		check(restored.restore_encoded(saved_inflight) and restored_reference.restore_encoded(saved_inflight), "An actual in-flight escape is accepted by the original save-state decoder")
		var resumed = World.new()
		resumed.simulation = restored
		resumed.character_class = "Arcanist"
		resumed.position = Vector3(4.0, 0.0, -6.0)
		resumed.rotation.y = .47
		resumed.active = false
		root.add_child(resumed)
		resumed.set_process(false)
		resumed.active = true
		resumed._process(0.0)
		check(resumed.hero.last_clip == "evade" and resumed.hero.evade_time >= 0.0 and resumed.hero.evade_state.goal.distance_to(resumed.to_global(resumed._point(restored.dodge_goal))) < .00001, "Restoring mid-escape in a transformed world builds the pose from the actual remaining global path without replaying an event")
		check(restored.encode_snapshot() == saved_inflight, "Lazy restored evade setup writes no simulation state")
		var resume_same := true
		for frame in 8:
			resumed._process(.10)
			restored_reference.advance(.10)
			resume_same = resume_same and restored.encode_snapshot() == restored_reference.encode_snapshot()
		check(resume_same, "A restored escape keeps the same normal combat outcome and RNG during recovery")
		resumed.free()
	production_metrics["world"] = {"warning_fixture": "original generated Hexer warning; normal production HP/damage/gear", "warning_radius_m": warning_radius, "warning_duration_s": warning_duration, "actual_simulation_event": event_seen, "actor_evade_from_event": actual_evade_seen, "authoritative_snapshot_identical": same_authority, "settled_camera_unchanged": camera_stable, "actual_inflight_restore": not saved_inflight.is_empty(), "translated_rotated_world_goal_correct": world_goal_correct, "real_world_support_samples": support_samples, "maximum_real_world_support_drift_m": maximum_support_drift}
	game.free()

func run() -> void:
	for class_key in ["Arcanist", "Ranger", "Vowkeeper"]:
		audit_class(class_key)
		audit_actor_lifecycle(class_key)
	audit_world_event_and_restore()
	print(JSON.stringify({"suite": "source_avatar_evade_smoke", "checks": checks, "failures": failures.size(), "poses": poses, "source": "procedural native65 low step on actual simulation displacement; no authored dodge clip", "metrics": evade_metrics, "production_metrics": production_metrics, "maximum_class_grip_gap_m": maximum_class_gap, "maximum_class_grip_penetration_m": maximum_class_penetration, "maximum_staff_grip_gap_m": widest_finger_gap, "maximum_staff_grip_penetration_m": worst_penetration}))
	print("SOURCE AVATAR EVADE SMOKE: %d checks, %d failures" % [checks, failures.size()])
	arm_surfaces.clear()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)
