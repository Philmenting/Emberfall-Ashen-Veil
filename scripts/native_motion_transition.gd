extends RefCounted
## Clip changes follow the last displayed base pose, including interrupted
## casts. This layer runs after the directional evade pose and before the
## fresh damage response and rigid weapon fit. It never changes an actor,
## simulation clock, native rest, joint scale or skin bind.
var clip := ""
var age := 1.0
var duration := .0
var previous: Dictionary = {}
var departure: Dictionary = {}
var previous_soles: Array[Transform3D] = []
var departure_soles: Array[Transform3D] = []
var previous_poles: Array[Vector3] = []
var departure_poles: Array[Vector3] = []
var previous_bow: Dictionary = {}
var departure_bow: Dictionary = {}
var amount := 1.0
var previous_sword_hand := Transform3D.IDENTITY
var departure_sword_hand := Transform3D.IDENTITY
var departure_motion_transform := Transform3D.IDENTITY

func apply(rig: RefCounted, actor: Variant, next_clip: String, time: float, delta: float, contact: bool, requested_duration: float) -> void:
	var changing := clip != next_clip
	if changing:
		departure = previous
		departure_soles = previous_soles.duplicate()
		departure_poles = previous_poles.duplicate()
		departure_bow = previous_bow.duplicate()
		departure_sword_hand = previous_sword_hand
		departure_motion_transform = rig.motion_node.transform
		var leaving_evade := clip == "evade"
		clip = next_clip
		age = 0.0
		duration = minf(requested_duration, .085)
		# A cancelled cast must visibly fold into the escape rather than
		# replacing the already drawn shoulder with a frozen idle shoulder.
		if next_clip == "evade": duration = .16 if String(rig.key) == "Vowkeeper" else .075
		elif leaving_evade and next_clip.begins_with("windup"): duration = minf(duration, .045)
		# An in-flight save enters its real current phase immediately. The
		# actual launch/contact also always owns the exact authored endpoint.
		if departure.is_empty() or next_clip == "death" or (next_clip.begins_with("windup") and time > .24): age = duration
	if (contact and (next_clip.begins_with("windup") or next_clip.begins_with("recover"))) or actor.reduced_motion:
		age = duration
	else:
		age += maxf(delta, 0.0)
	amount = smoothstep(0.0, maxf(duration, .00001), age)
	if amount < 1.0 and not departure.is_empty():
		var skeleton: Skeleton3D = rig.skeleton
		var sword_hand := skeleton.get_bone_global_pose(skeleton.find_bone("hand_r"))
		var targets: Array[Transform3D] = []
		var poles: Array[Vector3] = []
		for side in 2:
			var suffix := "l" if side == 0 else "r"
			var current := skeleton.get_bone_global_pose(skeleton.find_bone("foot_" + suffix))
			if next_clip == "evade" and time < .15 and not actor.evade_state.is_empty():
				# The instant cancellation frame has not travelled yet. Its
				# source idle must not replace the genuinely planted cast sole.
				# Preserve the actual event's world anchor, then hand over to
				# the existing directional foot trajectory by its .15 load phase.
				# Use the event's fixed rig baseline under the current actor.
				# Feeding yesterday's floor correction back into this inverse
				# changes a held knee by float32 rounding on every redraw.
				var reference: Transform3D = rig.motion_node.get_parent().global_transform * departure_motion_transform
				var anchored: Transform3D = reference.affine_inverse() * actor.evade_state.initial_feet_world[side]
				var foot_entry := smoothstep(0.0,.15,time)
				current = Transform3D(anchored.basis.slerp(current.basis,foot_entry),anchored.origin.lerp(current.origin,foot_entry))
			# The evade owns real world stance anchors. Blending those anchors
			# would introduce foot sliding on the authoritative escape path.
			if next_clip != "evade" and departure_soles.size() == 2:
				current = Transform3D(departure_soles[side].basis.slerp(current.basis, amount), departure_soles[side].origin.lerp(current.origin, amount))
			targets.append(current)
			var thigh := skeleton.get_bone_global_pose(skeleton.find_bone("thigh_" + suffix)).origin
			var knee := skeleton.get_bone_global_pose(skeleton.find_bone("calf_" + suffix)).origin
			var pole := knee - thigh
			pole.z = maxf(pole.z, .16)
			if departure_poles.size() == 2: pole = departure_poles[side].lerp(pole,amount)
			poles.append(pole)
		for bone in skeleton.get_bone_count():
			var name := String(skeleton.get_bone_name(bone))
			# Only the native hip/root can translate. Interpolating child
			# offsets would alter the original anatomical segment lengths.
			if name in ["pelvis", "root"]:
				skeleton.set_bone_pose_position(bone, departure.positions[bone].lerp(skeleton.get_bone_pose_position(bone), amount))
			skeleton.set_bone_pose_rotation(bone, departure.rotations[bone].slerp(skeleton.get_bone_pose_rotation(bone), amount))
		skeleton.force_update_all_bone_transforms()
		rig.hold_cast_soles(targets, poles)
		if String(rig.key) == "Vowkeeper":
			# Local slerps across shoulder/elbow/wrist can wind a rigid blade
			# around the character even though every joint takes its own short
			# path. Interpolate the actual global hand, then solve the native
			# rest-length arm, so a cancelled swing retracts on one clear arc.
			var target := departure_sword_hand.origin.lerp(sword_hand.origin, amount)
			rig._solve_cast_chain(skeleton.find_bone("upperarm_r"),skeleton.find_bone("lowerarm_r"),skeleton.find_bone("hand_r"),target,Vector3(-.50,-.30,-.30))
			rig._global_rotation(skeleton.find_bone("hand_r"),departure_sword_hand.basis.slerp(sword_hand.basis,amount))
		if String(rig.key) == "Ranger" and not departure_bow.is_empty():
			for field in ["draw", "aim"]:
				rig.class_pose_state[field] = lerpf(float(departure_bow.get(field, 0.0)), float(rig.class_pose_state.get(field, 0.0)), amount)
			rig.class_pose_state.release = departure_bow.get("release", Vector3.ZERO).lerp(rig.class_pose_state.get("release", Vector3.ZERO), amount)
	# Save the clean base before recoil is freshly applied. Saving recoil
	# here would compound damage every time a zero-delta frame is held.
	previous = _snapshot(rig)
	previous_soles.clear()
	previous_poles.clear()
	for suffix in ["l", "r"]:
		previous_soles.append(rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone("foot_" + suffix)))
		previous_poles.append(rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone("calf_"+suffix)).origin-rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone("thigh_"+suffix)).origin)
	if String(rig.key) == "Ranger": previous_bow = rig.class_pose_state.duplicate()
	if String(rig.key) == "Vowkeeper": previous_sword_hand = rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone("hand_r"))

func _snapshot(rig: RefCounted) -> Dictionary:
	# Rotation-only history plus the two legitimate translation joints.
	# There is no reason to allocate/read65unused native scales each frame.
	var rotations: Array[Quaternion] = []
	for bone in rig.skeleton.get_bone_count(): rotations.append(rig.skeleton.get_bone_pose_rotation(bone))
	var positions := {}
	for name in ["pelvis", "root"]:
		var bone: int = rig.skeleton.find_bone(name)
		if bone >= 0: positions[bone] = rig.skeleton.get_bone_pose_position(bone)
	return {"positions": positions, "rotations": rotations}

func reset() -> void:
	clip = ""
	age = 1.0
	previous.clear()
	departure.clear()
	previous_soles.clear()
	departure_soles.clear()
	previous_poles.clear()
	departure_poles.clear()
	previous_bow.clear()
	departure_bow.clear()
	amount = 1.0
