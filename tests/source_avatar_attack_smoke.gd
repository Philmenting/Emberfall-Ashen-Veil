extends SceneTree
## Validate the production native65 casts, including actually weighted hand
## geometry and whole body surfaces. A socket-only displacement cannot pass.
const Actor = preload("res://scripts/dungeon_actor.gd")
const SkinAudit = preload("res://tests/source_avatar_skin.gd")
const SourceRig = preload("res://scripts/source_avatar_rig.gd")
const Combat = preload("res://scripts/source_avatar_combat.gd")
var checks := 0
var failures: Array[String] = []
var hand_probes: Array = []
var body_probes: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func cache_rendered_hand(rig: RefCounted) -> void:
	for surface in rig.surfaces:
		if not String(surface.name).contains("Arms"):
			continue
		for slot in surface.mesh.get_surface_count():
			var arrays = surface.mesh.surface_get_arrays(slot)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var binds: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var used := {}
			for index in arrays[Mesh.ARRAY_INDEX]:
				used[index] = true
			for index in used:
				var influences: Array = []
				var hand_weight := 0.0
				for influence in 4:
					var weight := weights[index * 4 + influence]
					if weight <= 0.0:
						continue
					var bind := binds[index * 4 + influence]
					var name: StringName = surface.skin.get_bind_name(bind)
					var bone: int = rig.skeleton.find_bone(name) if name != &"" else surface.skin.get_bind_bone(bind)
					influences.append([bone, surface.skin.get_bind_pose(bind) * vertices[index], weight])
					if String(rig.skeleton.get_bone_name(bone)) == "hand_l":
						hand_weight += weight
				if hand_weight > .75:
					hand_probes.append(influences)
	check(hand_probes.size() > 20, "Motion uses indexed, actually rendered left-hand vertices")

func rendered_hand(rig: RefCounted) -> Vector3:
	var center := Vector3.ZERO
	for influences in hand_probes:
		var point := Vector3.ZERO
		for influence in influences:
			point += (rig.skeleton.get_bone_global_pose(influence[0]) * influence[1]) * influence[2]
		center += rig.motion_node.transform * point
	return center / float(hand_probes.size())

func cache_rendered_body(rig: RefCounted) -> void:
	for surface in rig.surfaces:
		if not String(surface.name).ends_with("_Body"):
			continue
		for slot in surface.mesh.get_surface_count():
			var arrays = surface.mesh.surface_get_arrays(slot)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var binds: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var used := {}
			for index in arrays[Mesh.ARRAY_INDEX]:
				used[index] = true
			for index in used:
				var influences: Array = []
				for influence in 4:
					var weight := weights[index * 4 + influence]
					if weight <= 0.0:
						continue
					var bind := binds[index * 4 + influence]
					var name: StringName = surface.skin.get_bind_name(bind)
					var bone: int = rig.skeleton.find_bone(name) if name != &"" else surface.skin.get_bind_bone(bind)
					influences.append([bone, surface.skin.get_bind_pose(bind) * vertices[index], weight])
				body_probes.append(influences)
	check(body_probes.size() > 100, "Body motion uses indexed, actually rendered outfit vertices")

func rendered_body(rig: RefCounted) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for influences in body_probes:
		var point := Vector3.ZERO
		for influence in influences:
			point += (rig.skeleton.get_bone_global_pose(influence[0]) * influence[1]) * influence[2]
		points.append(rig.motion_node.transform * point)
	return points

func rendered_soles(rig: RefCounted) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for probe in rig.floor_probes:
		var point := Vector3.ZERO
		for influence in probe.bones.size():
			point += (rig.skeleton.get_bone_global_pose(probe.bones[influence]) * probe.binds[influence] * probe.point) * probe.weights[influence]
		points.append(rig.motion_node.transform * point)
	return points

func knee_flexion(rig: RefCounted) -> float:
	var total := 0.0
	for suffix in ["l", "r"]:
		var hip: Vector3 = rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone("thigh_" + suffix)).origin
		var knee: Vector3 = rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone("calf_" + suffix)).origin
		var ankle: Vector3 = rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone("foot_" + suffix)).origin
		total += (knee - hip).angle_to(ankle - knee)
	return total * .5

func pose_source_control(actor: Node3D, clip: String, time: float) -> void:
	# Independent control: the identical immutable artist clip, without the
	# combat overlay. Normal floor grounding and staff support still run.
	var sample := Combat.source_sample(clip, time)
	actor.motion_rig._sample(sample.action, sample.time)
	actor.motion_rig.apply_actor_postprocess(actor, clip, time, 0.0, true)

func whole_body_metrics(actor: Node3D, control: Node3D, clip: String, time: float) -> Dictionary:
	pose_actor(actor, clip, time)
	pose_source_control(control, clip, time)
	var rig = actor.motion_rig
	var reference = control.motion_rig
	var pelvis: int = rig.skeleton.find_bone("pelvis")
	var chest: int = rig.skeleton.find_bone("spine_03")
	var body := rendered_body(rig)
	var original := rendered_body(reference)
	var squared_motion := 0.0
	for index in body.size():
		squared_motion += body[index].distance_squared_to(original[index])
	return {
		"pelvis": rig.motion_node.transform * rig.skeleton.get_bone_global_pose(pelvis).origin - reference.motion_node.transform * reference.skeleton.get_bone_global_pose(pelvis).origin,
		"chest": (rig.skeleton.get_bone_global_pose(chest).basis * reference.skeleton.get_bone_global_pose(chest).basis.inverse()).get_rotation_quaternion(),
		"knee": knee_flexion(rig) - knee_flexion(reference),
		"body_rms": sqrt(squared_motion / float(body.size())),
	}

func contact_metrics(rig: RefCounted, reference: RefCounted) -> Dictionary:
	var result := {"floor": true, "ankles": true, "vertex": 0.0, "center": 0.0}
	var soles := rendered_soles(rig)
	var originals := rendered_soles(reference)
	var contact_delta := [Vector2.ZERO, Vector2.ZERO]
	var contact_count := [0, 0]
	for index in soles.size():
		var drift := Vector2(soles[index].x - originals[index].x, soles[index].z - originals[index].z)
		result.vertex = maxf(result.vertex, drift.length())
		result.floor = result.floor and soles[index].y >= .0029
		var side: int = rig.floor_probes[index].side
		contact_delta[side] += drift
		contact_count[side] += 1
	for side in 2:
		result.center = maxf(result.center, contact_delta[side].length() / float(contact_count[side]))
	for suffix in ["l", "r"]:
		var foot: int = rig.skeleton.find_bone("foot_" + suffix)
		var actual: Transform3D = rig.skeleton.get_bone_global_pose(foot)
		var original: Transform3D = reference.skeleton.get_bone_global_pose(foot)
		result.ankles = result.ankles and actual.origin.distance_to(original.origin) < .0001 and actual.basis.is_equal_approx(original.basis)
	var head: int = rig.skeleton.find_bone("Head")
	result.gaze = rig.skeleton.get_bone_global_pose(head).basis.get_rotation_quaternion().angle_to(reference.skeleton.get_bone_global_pose(head).basis.get_rotation_quaternion())
	return result

func pose_actor(actor: Node3D, clip: String, time: float) -> void:
	actor.motion_rig.pose(clip, time)
	actor.motion_rig.apply_actor_postprocess(actor, clip, time, 0.0, true)

func run() -> void:
	var actor = Actor.new()
	actor.kind = "Arcanist"
	root.add_child(actor)
	var rig = actor.motion_rig
	check(actor.source_avatar and rig.skeleton.get_bone_count() == 65, "Attack fixture uses the production native65 avatar")
	check(not actor.model.visible and rig.surfaces.size() == 8, "Eight authored surfaces, rather than a legacy proxy, render the attack")
	for clip in ["Spell_Simple_Enter", "Spell_Simple_Shoot", "Spell_Simple_Exit", "Idle_Loop", "Walk_Loop", "Death01"]:
		check(rig.player.has_animation(clip), "Source animation remains available: " + clip)
	cache_rendered_hand(rig)
	cache_rendered_body(rig)
	var source_control = Actor.new()
	source_control.kind = "Arcanist"
	root.add_child(source_control)
	var records := {}
	for action in ["basic", "skill", "heavy"]:
		var windup: String = "windup_" + String(action)
		var recovery: String = "recover_" + String(action)
		var path: Array[Vector3] = []
		var upper: int = rig.skeleton.find_bone("upperarm_l")
		var lower: int = rig.skeleton.find_bone("lowerarm_l")
		var hand: int = rig.skeleton.find_bone("hand_l")
		var upper_length: float = rig.rest[upper].origin.distance_to(rig.rest[lower].origin)
		var lower_length: float = rig.rest[lower].origin.distance_to(rig.rest[hand].origin)
		var lengths_exact := true
		var fingers_exact := true
		var scales_exact := true
		var source_rest_exact := true
		var native_lengths_exact := true
		var staff_upright := true
		var maximum_step := 0.0
		var maximum_step_frame := 0
		var previous_body: Array[Vector3] = []
		var largest_body_step := 0.0
		var largest_sole_drift := 0.0
		var largest_contact_drift := 0.0
		var sole_transforms_fixed := true
		var physical_floor_clear := true
		var largest_gaze_turn := 0.0
		for frame in 61:
			pose_actor(actor, windup, frame / 60.0)
			pose_source_control(source_control, windup, frame / 60.0)
			path.append(rendered_hand(rig))
			var body := rendered_body(rig)
			if not previous_body.is_empty():
				var body_step := 0.0
				for index in body.size():
					body_step += body[index].distance_squared_to(previous_body[index])
				largest_body_step = maxf(largest_body_step, sqrt(body_step / float(body.size())))
			previous_body = body
			var contacts := contact_metrics(rig, source_control.motion_rig)
			largest_sole_drift = maxf(largest_sole_drift, contacts.vertex)
			largest_contact_drift = maxf(largest_contact_drift, contacts.center)
			physical_floor_clear = physical_floor_clear and contacts.floor
			sole_transforms_fixed = sole_transforms_fixed and contacts.ankles
			largest_gaze_turn = maxf(largest_gaze_turn, contacts.gaze)
			if frame > 0:
				var step: float = path[-1].distance_to(path[-2])
				if step > maximum_step:
					maximum_step = step
					maximum_step_frame = frame
			var shoulder: Vector3 = rig.skeleton.get_bone_global_pose(upper).origin
			var elbow: Vector3 = rig.skeleton.get_bone_global_pose(lower).origin
			var palm: Vector3 = rig.skeleton.get_bone_global_pose(hand).origin
			lengths_exact = lengths_exact and absf(shoulder.distance_to(elbow) - upper_length) < .00001 and absf(elbow.distance_to(palm) - lower_length) < .00001
			for bone in rig.grip_pose:
				fingers_exact = fingers_exact and rig.skeleton.get_bone_pose_rotation(bone).is_equal_approx(rig.grip_pose[bone])
			for bone in 65:
				scales_exact = scales_exact and rig.skeleton.get_bone_pose_scale(bone).distance_to(Vector3.ONE) < .00001
				source_rest_exact = source_rest_exact and rig.skeleton.get_bone_global_rest(bone).is_equal_approx(rig.rest[bone])
				var parent: int = rig.skeleton.get_bone_parent(bone)
				if parent >= 0 and String(rig.skeleton.get_bone_name(bone)) not in ["root", "pelvis"]:
					var length: float = rig.skeleton.get_bone_global_pose(bone).origin.distance_to(rig.skeleton.get_bone_global_pose(parent).origin)
					var original: float = rig.rest[bone].origin.distance_to(rig.rest[parent].origin)
					native_lengths_exact = native_lengths_exact and absf(length - original) < .00001
			var shaft: Vector3 = (rig.motion_node.basis * rig.weapon.basis * Vector3.UP).normalized()
			staff_upright = staff_upright and shaft.dot(Vector3.UP) > .98
			if frame in [0, 24, 39, 60]:
				var bounds: AABB = SkinAudit.actual_bounds(rig)
				check(bounds.position.y > -.025 and bounds.size.y < 2.8 and bounds.size.x < 3.0, action + ": complete weighted body keeps floor clearance and proportions at " + str(frame))
		check(lengths_exact, action + ": actual native arm lengths remain exact throughout the cast")
		check(native_lengths_exact, action + ": both native legs, arms and every finger retain their original parent-child lengths")
		check(scales_exact and source_rest_exact, action + ": all 65 original rests and unit pose scales remain unchanged")
		check(fingers_exact and staff_upright, action + ": fitted right fingers and upright staff remain supported")
		check(sole_transforms_fixed, action + ": both original native ankle transforms remain planted throughout the load transfer")
		check(physical_floor_clear, action + ": all actually weighted physical bootfloor vertices remain above the floor")
		check(largest_contact_drift < .008 and largest_sole_drift < .020, action + ": weighted boot contacts remain planted while their original calf-weighted leather flexes; center " + str(largest_contact_drift) + ", vertex " + str(largest_sole_drift))
		check(largest_body_step < .035, action + ": the actually weighted outfit has a continuous whole-body windup; RMS step " + str(largest_body_step))
		check(largest_gaze_turn < .35, action + ": stronger hips and shoulders leave the original target-facing gaze within 20 degrees")
		check(maximum_step < .065, action + ": visible casting hand follows a continuous windup; largest normalized-frame step " + str(maximum_step))
		print("ATTACK PATH ", action, ": largest step frame ", maximum_step_frame, " from ", path[maxi(0, maximum_step_frame - 1)], " to ", path[maximum_step_frame], "; load ", path[24], "; release ", path[60])
		check(path[0].distance_to(path[-1]) > .35, action + ": actual rendered left hand performs a substantial cast")
		# Load and follow-through must move the physical figure, not merely an
		# empty hand socket. Compare weighted outfit, native pelvis and geometric
		# knee flexion against the same original source samples on a second actor.
		var load_phase: float = {"basic": .33, "skill": .34, "heavy": .32}[action]
		var follow_phase: float = {"basic": .14, "skill": .16, "heavy": .18}[action]
		var load := whole_body_metrics(actor, source_control, windup, load_phase)
		var caught := whole_body_metrics(actor, source_control, recovery, follow_phase * Combat.RECOVERY)
		var minimum_load: float = {"basic": .030, "skill": .045, "heavy": .065}[action]
		var minimum_knee: float = {"basic": .20, "skill": .24, "heavy": .30}[action]
		var minimum_body: float = {"basic": .025, "skill": .040, "heavy": .055}[action]
		var minimum_transfer: float = {"basic": .040, "skill": .055, "heavy": .060}[action]
		var minimum_turn: float = {"basic": .40, "skill": .65, "heavy": .80}[action]
		check(load.pelvis.y < -minimum_load and load.knee > minimum_knee, action + ": the real pelvis lowers into visibly flexed native knees, rather than lowering the whole model")
		check(load.body_rms > minimum_body, action + ": the actually rendered outfit visibly participates in the load")
		check(absf(caught.pelvis.x - load.pelvis.x) > minimum_transfer, action + ": physical pelvis transfers weight sideways through the release")
		check(load.chest.angle_to(caught.chest) > minimum_turn, action + ": native chest and shoulders turn through a substantial full-body follow-through")
		print("ATTACK BODY ", action, ": load ", load, "; catch ", caught, "; boot center ", largest_contact_drift, "; boot vertex ", largest_sole_drift, "; body RMS step ", largest_body_step)
		# A passing hand/chest key must not behave as a tiny stop. Measure
		# the actual weighted glove, including its imported source torso, on
		# both sides of the late passing key rather than checking curve code.
		var passing: float = {"basic": .66, "skill": .82, "heavy": .70}[action]
		var passing_hand: Array[Vector3] = []
		for offset in [-.012, -.004, .004, .012]:
			pose_actor(actor, windup, passing + float(offset))
			passing_hand.append(rendered_hand(rig))
		var near_speed: float = passing_hand[1].distance_to(passing_hand[2]) / .008
		var approach_speed: float = passing_hand[0].distance_to(passing_hand[1]) / .008
		var depart_speed: float = passing_hand[2].distance_to(passing_hand[3]) / .008
		print("ATTACK PASSING ", action, ": approach ", approach_speed, ", key ", near_speed, ", depart ", depart_speed)
		check(near_speed > .12 and near_speed > minf(approach_speed, depart_speed) * .65, action + ": the actual glove carries velocity through the late passing key")
		pose_actor(actor, windup, 1.0)
		var release_hand: Vector3 = rendered_hand(rig)
		var release_pose: Array[Transform3D] = rig.capture_pose()
		pose_actor(actor, recovery, 0.0)
		check(rendered_hand(rig).distance_to(release_hand) < .0001, action + ": windup and recovery meet at the same actually skinned release hand")
		var release_continuous := true
		for bone in 65:
			release_continuous = release_continuous and release_pose[bone].is_equal_approx(rig.skeleton.get_bone_pose(bone))
		check(release_continuous, action + ": release is continuous across all native bones")
		var near_release: Vector3 = release_hand
		pose_actor(actor, windup, .97)
		var approach: Vector3 = release_hand - rendered_hand(rig)
		pose_actor(actor, recovery, .045)
		var follow: Vector3 = rendered_hand(rig) - near_release
		check(follow.length() > .006 and follow.dot(approach) > 0.0, action + ": the actual glove continues through discharge before folding back")
		pose_actor(actor, recovery, 0.0)
		var previous: Vector3 = rendered_hand(rig)
		var recovery_step := 0.0
		previous_body = rendered_body(rig)
		var body_recovery_step := 0.0
		var recovery_floor_clear := true
		var recovery_ankles_fixed := true
		var recovery_contact_drift := 0.0
		var recovery_sole_drift := 0.0
		var recovery_gaze_turn := 0.0
		var recovery_support_exact := true
		var recovery_lengths_exact := true
		for frame in range(1, 61):
			pose_actor(actor, recovery, frame / 60.0 * SourceRig.RECOVERY)
			pose_source_control(source_control, recovery, frame / 60.0 * SourceRig.RECOVERY)
			var contacts := contact_metrics(rig, source_control.motion_rig)
			recovery_floor_clear = recovery_floor_clear and contacts.floor
			recovery_ankles_fixed = recovery_ankles_fixed and contacts.ankles
			recovery_contact_drift = maxf(recovery_contact_drift, contacts.center)
			recovery_sole_drift = maxf(recovery_sole_drift, contacts.vertex)
			recovery_gaze_turn = maxf(recovery_gaze_turn, contacts.gaze)
			for bone in rig.grip_pose:
				recovery_support_exact = recovery_support_exact and rig.skeleton.get_bone_pose_rotation(bone).is_equal_approx(rig.grip_pose[bone])
			var shaft: Vector3 = (rig.motion_node.basis * rig.weapon.basis * Vector3.UP).normalized()
			recovery_support_exact = recovery_support_exact and shaft.dot(Vector3.UP) > .98
			for bone in 65:
				var parent: int = rig.skeleton.get_bone_parent(bone)
				if parent >= 0 and String(rig.skeleton.get_bone_name(bone)) not in ["root", "pelvis"]:
					var length: float = rig.skeleton.get_bone_global_pose(bone).origin.distance_to(rig.skeleton.get_bone_global_pose(parent).origin)
					var original: float = rig.rest[bone].origin.distance_to(rig.rest[parent].origin)
					recovery_lengths_exact = recovery_lengths_exact and absf(length - original) < .00001
			var point := rendered_hand(rig)
			recovery_step = maxf(recovery_step, point.distance_to(previous))
			previous = point
			var body := rendered_body(rig)
			var body_step := 0.0
			for index in body.size():
				body_step += body[index].distance_squared_to(previous_body[index])
			body_recovery_step = maxf(body_recovery_step, sqrt(body_step / float(body.size())))
			previous_body = body
		check(recovery_step < .065, action + ": visible recovery is continuous; largest normalized-frame step " + str(recovery_step))
		check(body_recovery_step < .035, action + ": the weighted full body settles continuously after discharge; RMS step " + str(body_recovery_step))
		check(recovery_floor_clear and recovery_ankles_fixed, action + ": the physical bootfloor and original ankle contacts also stay planted through the stronger catch and recovery")
		check(recovery_contact_drift < .008 and recovery_sole_drift < .020, action + ": recovery preserves weighted boot contacts; center " + str(recovery_contact_drift) + ", vertex " + str(recovery_sole_drift))
		check(recovery_gaze_turn < .35, action + ": the head keeps sight of the original target through the strongest shoulder catch")
		check(recovery_support_exact and recovery_lengths_exact, action + ": stronger follow-through keeps the fitted supporting fingers, upright staff and all original native segment lengths")
		pose_source_control(source_control, recovery, Combat.RECOVERY)
		var settled := true
		for bone in 65:
			settled = settled and rig.skeleton.get_bone_pose(bone).is_equal_approx(source_control.motion_rig.skeleton.get_bone_pose(bone))
		check(settled, action + ": all original bones return to the clean artist clip after full-body recovery")
		pose_actor(actor, windup, .65)
		var stable_pose: Array[Transform3D] = rig.capture_pose()
		for repeat in 12:
			pose_actor(actor, windup, .65)
		var stable := true
		for bone in 65:
			stable = stable and stable_pose[bone].is_equal_approx(rig.skeleton.get_bone_pose(bone))
		check(stable, action + ": a held simulation phase never accumulates additive deformation")
		for other in [["windup_skill", .30], ["recover_heavy", .10], ["walk", .31], ["idle", .70]]:
			pose_actor(actor, String(other[0]), float(other[1]))
		pose_actor(actor, windup, .65)
		var order_independent := true
		for bone in 65:
			order_independent = order_independent and stable_pose[bone].is_equal_approx(rig.skeleton.get_bone_pose(bone))
		check(order_independent, action + ": immutable imported tracks reset before every source sample; phase pose is independent of prior actions")
		records[action] = path
	# Distinct silhouettes come from rendered skin at load and contact, not a
	# different action label, timing-only remap or multiplied source amplitude.
	check(records.skill[24].y - records.basic[24].y > .25, "Signature gathers the actual glove above the compact basic cast")
	check(records.basic[24].y - records.heavy[24].y > .12, "Heavy chambers the actual glove lower than the basic cast")
	check(records.skill[60].y - records.basic[60].y > .075, "Signature releases from its own higher actual palm trajectory")
	check(records.skill[39].distance_to(records.heavy[39]) > .45, "Signature sweep and heavy load have visibly different weighted hand paths")
	source_control.free()
	actor.free()
	# Exercise simulation-controlled launch timing through the normal actor,
	# including the actual left hand from which DungeonWorld spawns a spell.
	for style in ["basic", "signature"]:
		actor = Actor.new()
		actor.kind = "Arcanist"
		root.add_child(actor)
		actor.strike(style, .36, true)
		actor.sync_attack(Actor.PROJECTILE_RELEASE_LEAD)
		actor.animate(0.0, false)
		var left: Vector3 = actor.body.to_global(actor.motion_rig.palm_position(0))
		check(actor.last_clip == ("windup_skill" if style == "signature" else "windup_basic"), style + ": normal production actor chooses its distinct source phrase")
		check(actor.projectile_origin().distance_to(left) < .000001, style + ": projectile starts at the posed real leading palm")
		for frame in 12:
			actor.animate(1.0 / 60.0, false)
		check(actor.release_time < 0.0, style + ": held visual motion cannot release simulation damage")
		check(actor.release_attack() and actor.release_time == 0.0, style + ": simulation confirmation alone starts recovery")
		actor.free()
	# The third phrase belongs to Nyra's existing Starfall ground burst in
	# ordinary combat. This uses its real .8 s windup and external confirmation
	# rather than a diagnostic-only heavy strike or a new player ability.
	actor = Actor.new()
	actor.kind = "Arcanist"
	root.add_child(actor)
	actor.strike("starfall", .80, true)
	for phase in [0.0, .4, .76, 1.0]:
		actor.sync_attack(.80 * (1.0 - float(phase)))
		actor.animate(0.0, false)
		check(actor.last_clip == "windup_heavy", "Existing Starfall chooses the native heavy phrase at phase " + str(phase))
		check(actor.release_time < 0.0 and is_equal_approx(actor.attack_duration, .80), "Starfall keeps its real .8 s simulation windup and held damage")
		if is_equal_approx(float(phase), .4):
			check(rendered_hand(actor.motion_rig).y < records.basic[24].y - .12, "Normal Starfall actor actually renders the low heavy chamber")
	check(actor.release_attack() and actor.last_clip == "recover_heavy", "Starfall simulation confirmation starts its own heavy follow-through")
	check(is_equal_approx(actor.action_intensity, 1.20), "Starfall retains its existing signature-skill effect intensity")
	actor.free()
	for class_key in ["Vowkeeper", "Ranger"]:
		actor = Actor.new()
		actor.kind = class_key
		root.add_child(actor)
		actor.strike("starfall", .80, true)
		actor.sync_attack(.40)
		actor.animate(0.0, false)
		check(actor.last_clip == "windup_skill", class_key + ": the Arcanist phrase mapping leaves other class animation choices intact")
		actor.free()
	# Real impact events articulate visible native skin while preserving the
	# boots and accepted support hand. Compare the same simulation frame to a
	# second ordinary actor so breathing cannot masquerade as a hurt response.
	actor = Actor.new()
	actor.kind = "Arcanist"
	root.add_child(actor)
	var control = Actor.new()
	control.kind = "Arcanist"
	root.add_child(control)
	actor.react(1.0, 1.0)
	actor.animate(.04, false)
	control.animate(.04, false)
	var chest: int = actor.motion_rig.skeleton.find_bone("spine_03")
	var head: int = actor.motion_rig.skeleton.find_bone("Head")
	var chest_delta: float = actor.motion_rig.skeleton.get_bone_global_pose(chest).basis.get_rotation_quaternion().angle_to(control.motion_rig.skeleton.get_bone_global_pose(chest).basis.get_rotation_quaternion())
	check(actor.hit_strength > .80 and chest_delta > .035, "A real damage event at .04 s articulates the native chest")
	check(actor.motion_rig.skeleton.get_bone_global_pose(head).origin.distance_to(control.motion_rig.skeleton.get_bone_global_pose(head).origin) > .008, "The native head reacts to the actual upper-body impact")
	check(rendered_hand(actor.motion_rig).distance_to(rendered_hand(control.motion_rig)) > .008, "Actually weighted visible source skin participates in the hurt pose")
	var feet_fixed := true
	for bone_name in ["pelvis", "foot_l", "foot_r"]:
		var bone: int = actor.motion_rig.skeleton.find_bone(bone_name)
		feet_fixed = feet_fixed and actor.motion_rig.skeleton.get_bone_global_pose(bone).is_equal_approx(control.motion_rig.skeleton.get_bone_global_pose(bone))
	check(feet_fixed and actor.global_transform.is_equal_approx(control.global_transform), "Hurt reaction leaves the native pelvis, boots and world position unchanged")
	var supported := true
	for bone in actor.motion_rig.grip_pose:
		supported = supported and actor.motion_rig.skeleton.get_bone_pose_rotation(bone).is_equal_approx(actor.motion_rig.grip_pose[bone])
	var shaft: Vector3 = (actor.motion_rig.motion_node.basis * actor.motion_rig.weapon.basis * Vector3.UP).normalized()
	check(supported and shaft.dot(Vector3.UP) > .98, "Hurt pose preserves the fitted right fingers and upright staff")
	var lengths_fixed := true
	for bone in 65:
		var parent: int = actor.motion_rig.skeleton.get_bone_parent(bone)
		if parent >= 0 and String(actor.motion_rig.skeleton.get_bone_name(bone)) not in ["root", "pelvis"]:
			var length: float = actor.motion_rig.skeleton.get_bone_global_pose(bone).origin.distance_to(actor.motion_rig.skeleton.get_bone_global_pose(parent).origin)
			var original: float = actor.motion_rig.rest[bone].origin.distance_to(actor.motion_rig.rest[parent].origin)
			lengths_fixed = lengths_fixed and absf(length - original) < .00001
	check(lengths_fixed, "All native parent-child lengths remain original throughout the real hurt pose")
	var hurt_pose: Array[Transform3D] = actor.motion_rig.capture_pose()
	for repeat in 12:
		# Keep the ordinary entry blend unchanged. A forced contact flag would
		# deliberately end that blend and compare different visual states.
		actor._apply_motion(0.0)
	var hurt_stable := true
	for bone in 65:
		hurt_stable = hurt_stable and hurt_pose[bone].is_equal_approx(actor.motion_rig.skeleton.get_bone_pose(bone))
	check(hurt_stable, "A held actual impact frame never accumulates native recoil")
	var impact_turn: Quaternion = (actor.motion_rig.skeleton.get_bone_global_pose(chest).basis * control.motion_rig.skeleton.get_bone_global_pose(chest).basis.inverse()).get_rotation_quaternion()
	var initial_turn: Vector3 = impact_turn.get_axis() * impact_turn.get_angle()
	var rebound_step: float = actor.recoil_duration * .72 - actor.impact_time
	actor.animate(rebound_step, false)
	control.animate(rebound_step, false)
	var return_turn: Quaternion = (actor.motion_rig.skeleton.get_bone_global_pose(chest).basis * control.motion_rig.skeleton.get_bone_global_pose(chest).basis.inverse()).get_rotation_quaternion()
	var rebound_turn: Vector3 = return_turn.get_axis() * return_turn.get_angle()
	check(rebound_turn.length() > .005 and rebound_turn.length() < initial_turn.length() * .25 and rebound_turn.dot(initial_turn) < 0.0, "A real hurt response returns through a small opposing native chest rebound")
	var settle: float = actor.recoil_duration
	actor.animate(settle, false)
	control.animate(settle, false)
	var returned := true
	for bone in 65:
		returned = returned and actor.motion_rig.skeleton.get_bone_pose(bone).is_equal_approx(control.motion_rig.skeleton.get_bone_pose(bone))
	check(actor.impact_time < 0.0 and actor.hit_strength == 0.0 and returned, "Native hurt pose returns to the same clean source pose after the real recoil duration")
	actor.reduced_motion = true
	control.reduced_motion = true
	actor.react(-1.0, 1.0)
	actor.animate(.04, false)
	control.animate(.04, false)
	var reduced_equal := true
	for bone in 65:
		reduced_equal = reduced_equal and actor.motion_rig.skeleton.get_bone_pose(bone).is_equal_approx(control.motion_rig.skeleton.get_bone_pose(bone))
	check(actor.hit_strength > .80 and reduced_equal, "Reduced motion retains the actual damage event and suppresses native recoil movement")
	actor.reduced_motion = false
	control.reduced_motion = false
	actor.impact_time = -1.0
	for target in [actor, control]:
		target.strike("signature", .42, true)
		target.sync_attack(.20)
		target.animate(0.0, false)
	actor.react(1.0, 1.0)
	actor.animate(.04, false)
	control.animate(.04, false)
	var cast_delta: float = actor.motion_rig.skeleton.get_bone_global_pose(chest).basis.get_rotation_quaternion().angle_to(control.motion_rig.skeleton.get_bone_global_pose(chest).basis.get_rotation_quaternion())
	check(cast_delta > .005 and cast_delta < chest_delta * .45 and actor.release_time < 0.0, "A committed source cast attenuates real hurt recoil without releasing simulation damage")
	actor.free()
	control.free()
	# Cancel the actual ordinary actor while loading and while almost ready.
	# The first retreat frame preserves the visible glove; once its regular
	# transition ends, no cancelled attack survives into locomotion or repeat.
	for style in ["basic", "signature", "starfall"]:
		for remaining in [.38, .08]:
			actor = Actor.new()
			actor.kind = "Arcanist"
			root.add_child(actor)
			control = Actor.new()
			control.kind = "Arcanist"
			root.add_child(control)
			actor.strike(style, .42, true)
			actor.sync_attack(float(remaining))
			actor.animate(0.0, false)
			var before_cancel: Vector3 = rendered_hand(actor.motion_rig)
			var before_cancel_body := rendered_body(actor.motion_rig)
			actor.retreat()
			actor.animate(0.0, true, 2.0)
			control.animate(0.0, true, 2.0)
			check(actor.attack_time < 0.0 and actor.release_time < 0.0 and not actor.attack_queued and not actor.external_release, style + ": real retreat cancels the unreleased cast without a damage confirmation")
			check(rendered_hand(actor.motion_rig).distance_to(before_cancel) < .002, style + ": cancellation enters locomotion from the current visible glove without a pose snap")
			var cancelled_body := rendered_body(actor.motion_rig)
			var cancel_body_step := 0.0
			for index in cancelled_body.size():
				cancel_body_step += cancelled_body[index].distance_squared_to(before_cancel_body[index])
			check(sqrt(cancel_body_step / float(cancelled_body.size())) < .002, style + ": cancellation preserves the currently weighted full-body pose on its entry frame")
			for frame in 20:
				actor.animate(1.0 / 60.0, true, 2.0)
				control.animate(1.0 / 60.0, true, 2.0)
			var clean_walk := true
			for bone in 65:
				clean_walk = clean_walk and actor.motion_rig.skeleton.get_bone_pose(bone).is_equal_approx(control.motion_rig.skeleton.get_bone_pose(bone))
			check(clean_walk, style + ": the cancelled phrase leaves no native-bone residue after the ordinary walking transition")
			for target in [actor, control]:
				target.strike("signature", .42, true)
				target.sync_attack(.14)
				target.animate(0.0, false)
			var clean_repeat := true
			for bone in 65:
				clean_repeat = clean_repeat and actor.motion_rig.skeleton.get_bone_pose(bone).is_equal_approx(control.motion_rig.skeleton.get_bone_pose(bone))
			check(clean_repeat, style + ": an immediate subsequent committed signature starts from the same clean source pose")
			actor.free()
			control.free()
	print("SOURCE AVATAR ATTACK: ", checks, " checks, ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
