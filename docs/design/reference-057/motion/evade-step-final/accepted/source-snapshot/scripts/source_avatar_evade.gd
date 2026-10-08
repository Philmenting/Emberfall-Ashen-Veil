extends RefCounted
## Directional low steps on the unmodified native65 anatomy. This is an
## explicit procedural pose, not an artist-authored dodge clip. The actual
## simulation supplies the path; this helper never moves an actor or changes
## invulnerability, attacks, damage, cooldowns or simulation clocks.
# A half-cycle lateral step must leave room for the native knee to bend.
# This visual stride changes no simulation distance or escape duration.
const STRIDE_SOURCE := 1.00
const STANCE_END := .50
const FOOT_CLEARANCE_SOURCE := .065
const CROUCH_SOURCE := .19

static func begin(actor: Variant, simulation_origin: Vector3, goal: Vector3) -> Dictionary:
	var rig: RefCounted = actor.motion_rig
	var origin: Vector3 = actor.global_position
	var displacement := goal - origin
	displacement.y = 0.0
	var distance := displacement.length()
	if distance < .001:
		return {}
	var direction := displacement / distance
	var local_direction: Vector3 = rig.motion_node.global_basis.inverse() * direction
	local_direction.y = 0.0
	local_direction = local_direction.normalized()
	var feet: Array[Transform3D] = []
	for side in ["l", "r"]:
		feet.append(rig.motion_node.global_transform * rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone("foot_" + side)))
	return {
		"origin": origin,
		"simulation_origin": simulation_origin,
		"goal": goal,
		"direction_world": direction,
		"distance_world": distance,
		"scale_world": rig.motion_node.global_basis.x.length(),
		"initial_feet_world": feet,
		"lead_side": 0 if local_direction.x >= 0.0 else 1,
	}

static func path_progress(actor: Variant, state: Dictionary) -> float:
	if state.is_empty():
		return 1.0
	var travelled: float = (actor.global_position - state.origin).dot(state.direction_world)
	return clampf(travelled / maxf(float(state.distance_world), .001), 0.0, 1.0)

static func apply(rig: RefCounted, actor: Variant, phase: float, state: Dictionary) -> void:
	if state.is_empty() or phase <= 0.0 or phase >= 1.0:
		return
	var amount := smoothstep(0.0, .15, phase) * (1.0 - smoothstep(.73, 1.0, phase))
	if amount <= 0.0:
		return
	var skeleton: Skeleton3D = rig.skeleton
	var carrying_shoulder: Basis = skeleton.get_bone_global_pose(skeleton.find_bone("spine_03")).basis
	# Both rigs use this same floor baseline before their weighted boot scan.
	# Reset it before world-to-native target conversion so a held pose cannot
	# accumulate the previous frame's grounding correction.
	rig.motion_node.position.y = .009
	var direction: Vector3 = rig.motion_node.global_basis.inverse() * state.direction_world
	direction.y = 0.0
	direction = direction.normalized()
	var soles: Array[Transform3D] = []
	var poles: Array[Vector3] = []
	var travelled: float = clampf((actor.global_position - state.origin).dot(state.direction_world), 0.0, float(state.distance_world))
	var scale_world := maxf(float(state.scale_world), .001)
	var stride_world := STRIDE_SOURCE * scale_world
	var inverse: Transform3D = rig.motion_node.global_transform.affine_inverse()
	for side in 2:
		var suffix := "l" if side == 0 else "r"
		var thigh: int = skeleton.find_bone("thigh_" + suffix)
		var calf: int = skeleton.find_bone("calf_" + suffix)
		var foot: int = skeleton.find_bone("foot_" + suffix)
		var current := skeleton.get_bone_global_pose(foot)
		# Open with the outside foot while the inside foot holds the ground.
		# Each support lasts half a cycle: the outside foot lands before the
		# trailing foot catches up. A shorter stance lets both feet swing at
		# once and can carry the trailing foot across the outside ankle.
		var offset := .5 if side == int(state.lead_side) else 0.0
		var cycle := travelled / stride_world + offset
		var gait_phase := fposmod(cycle, 1.0)
		var swing := clampf((gait_phase - STANCE_END) / (1.0 - STANCE_END), 0.0, 1.0)
		# During stance the world anchor is exactly constant. During swing the
		# ankle advances through a continuous trajectory and clears the floor.
		# A phase offset alternates the native feet without a walk animation.
		var advance := (_advance(cycle) - _advance(offset)) * stride_world
		var lift := pow(sin(PI * swing), 1.35) * FOOT_CLEARANCE_SOURCE * scale_world
		var world: Transform3D = state.initial_feet_world[side]
		world.origin += state.direction_world * advance + Vector3.UP * lift
		var target := inverse * world
		var toe_axis := Vector3.UP.cross(direction).normalized()
		var toe := -.12 * sin(TAU * swing) * amount
		target.basis = Basis(toe_axis, toe) * target.basis.orthonormalized()
		soles.append(Transform3D(current.basis.slerp(target.basis, amount), current.origin.lerp(target.origin, amount)))
		# Anatomical knees keep the source forward bend even when escaping
		# backwards. Direction only opens the leg slightly sideways; adding a
		# backwards travel vector to a nearly straight native calf would turn
		# its bend plane through the back of the leg.
		var source_pole := skeleton.get_bone_global_pose(calf).origin - skeleton.get_bone_global_pose(thigh).origin
		source_pole.z = maxf(source_pole.z, .24)
		poles.append(source_pole + Vector3(direction.x * .035 * amount, 0.0, 0.0))
	_rotate(rig, "pelvis", Vector3(direction.z * .10, direction.x * .085, -direction.x * .09) * amount)
	var pelvis: int = skeleton.find_bone("pelvis")
	var parent: int = skeleton.get_bone_parent(pelvis)
	var pelvis_global := skeleton.get_bone_global_pose(pelvis)
	pelvis_global.origin += (direction * .035 - Vector3.UP * CROUCH_SOURCE) * amount
	skeleton.set_bone_pose_position(pelvis, skeleton.get_bone_global_pose(parent).affine_inverse() * pelvis_global.origin)
	skeleton.force_update_all_bone_transforms()
	_rotate(rig, "spine_01", Vector3(direction.z * .11, -direction.x * .045, -direction.x * .055) * amount)
	# The archer stabilizes the bow-carrying shoulder against the low hip
	# step. Preserve its actual source global frame while its origin follows
	# the articulated lower trunk. Both arm chains then keep the accepted
	# weighted forearm/hand fit around the narrow physical bow handle.
	if String(rig.key) == "Ranger":
		rig._global_rotation(skeleton.find_bone("spine_03"), carrying_shoulder)
		_rotate(rig, "Head", Vector3(-direction.z * .03, direction.x * .025, direction.x * .02) * amount)
	else:
		_rotate(rig, "spine_03", Vector3(direction.z * .14, -direction.x * .05, -direction.x * .065) * amount)
		_rotate(rig, "Head", Vector3(-direction.z * .13, direction.x * .025, direction.x * .06) * amount)
	# Reuse the real rest-length two-bone solver. It can lower the pelvis by
	# the minimum extra amount needed for a long step; it never stretches a
	# thigh, calf or ankle, changes a skin bind, or scales a native joint.
	rig.hold_cast_soles(soles, poles)

static func _advance(cycle: float) -> float:
	var phase := fposmod(cycle, 1.0)
	return floorf(cycle) + smoothstep(STANCE_END, 1.0, phase)

static func _rotate(rig: RefCounted, name: String, angles: Vector3) -> void:
	var bone: int = rig.skeleton.find_bone(name)
	var current: Transform3D = rig.skeleton.get_bone_global_pose(bone)
	rig._global_rotation(bone, Basis.from_euler(angles) * current.basis)
