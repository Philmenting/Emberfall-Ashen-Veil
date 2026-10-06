extends RefCounted
## Three cast phrases on the original native65 rig. The source clips supply
## the stance, fingers and breathing; these paths articulate the actual left
## arm and torso without translating a limb joint or changing a skin bind.
const RECOVERY := .34
const SOURCE_LOAD := {"basic": .44, "skill": .62, "heavy": .73}
const SOURCE_FOLLOW := {"basic": .42, "skill": .48, "heavy": .56}
const PHRASES := {
	"basic": {
		# A small gathered palm, a direct jab, and a short elastic catch.
		"windup": [
			[0.0, Vector3(.24, -.30, .06), Vector3.ZERO, Vector3.ZERO, Vector3.ZERO],
			[.33, Vector3(.23, .02, .23), Vector3(0, .025, 0), Vector3(-.025, -.065, .015), Vector3(-.18, 0, -.08)],
			[.66, Vector3(.20, .08, .31), Vector3(0, .015, 0), Vector3(-.010, -.030, .005), Vector3(-.10, 0, -.04)],
			[1.0, Vector3(.12, .13, .46), Vector3(0, -.025, 0), Vector3(.035, .065, -.010), Vector3.ZERO],
		],
		"recover": [
			[0.0, Vector3(.12, .13, .46), Vector3(0, -.025, 0), Vector3(.035, .065, -.010), Vector3.ZERO],
			[.14, Vector3(.10, .135, .485), Vector3(0, -.020, 0), Vector3(.045, .050, -.015), Vector3(.06, 0, 0)],
			[.45, Vector3(.24, .03, .29), Vector3(0, .010, 0), Vector3(-.015, -.020, .010), Vector3(-.12, 0, -.05)],
			[1.0, Vector3(.24, -.30, .06), Vector3.ZERO, Vector3.ZERO, Vector3.ZERO],
		],
	},
	"skill": {
		# Gather above the left shoulder, open the chest, sweep down and out.
		"windup": [
			[0.0, Vector3(.24, -.30, .06), Vector3.ZERO, Vector3.ZERO, Vector3.ZERO],
			[.34, Vector3(.28, .36, .15), Vector3(0, .050, -.025), Vector3(-.045, -.105, -.045), Vector3(-.26, -.08, -.17)],
			[.57, Vector3(.32, .41, .25), Vector3(0, .025, -.020), Vector3(-.035, -.045, -.060), Vector3(-.23, -.05, -.13)],
			[.82, Vector3(.25, .30, .36), Vector3(0, -.025, .005), Vector3(.015, .045, -.020), Vector3(-.12, -.025, -.04)],
			[1.0, Vector3(.12, .24, .44), Vector3(0, -.045, .015), Vector3(.045, .100, .015), Vector3(-.08, 0, 0)],
		],
		"recover": [
			[0.0, Vector3(.12, .24, .44), Vector3(0, -.045, .015), Vector3(.045, .100, .015), Vector3(-.08, 0, 0)],
			[.16, Vector3(.08, .21, .477), Vector3(0, -.035, .015), Vector3(.065, .080, .020), Vector3(.04, 0, .04)],
			[.49, Vector3(.29, .14, .29), Vector3(0, .015, -.010), Vector3(-.015, -.035, -.020), Vector3(-.18, -.04, -.10)],
			[1.0, Vector3(.24, -.30, .06), Vector3.ZERO, Vector3.ZERO, Vector3.ZERO],
		],
	},
	"heavy": {
		# A low chamber and held load, followed by a deliberate forward thrust.
		"windup": [
			[0.0, Vector3(.24, -.30, .06), Vector3.ZERO, Vector3.ZERO, Vector3.ZERO],
			[.32, Vector3(.38, -.20, .06), Vector3(-.035, .065, -.020), Vector3(-.065, -.145, -.035), Vector3(-.24, -.05, -.18)],
			[.70, Vector3(.40, -.12, .15), Vector3(-.030, .055, -.015), Vector3(-.050, -.105, -.025), Vector3(-.20, -.04, -.15)],
			[1.0, Vector3(.10, .10, .47), Vector3(.030, -.055, .015), Vector3(.095, .145, .025), Vector3(.04, 0, .02)],
		],
		"recover": [
			[0.0, Vector3(.10, .10, .47), Vector3(.030, -.055, .015), Vector3(.095, .145, .025), Vector3(.04, 0, .02)],
			[.18, Vector3(.075, .115, .485), Vector3(.035, -.045, .015), Vector3(.115, .120, .035), Vector3(.08, 0, .04)],
			[.50, Vector3(.30, -.04, .29), Vector3(-.010, .020, -.010), Vector3(-.025, -.040, -.015), Vector3(-.18, 0, -.09)],
			[1.0, Vector3(.24, -.30, .06), Vector3.ZERO, Vector3.ZERO, Vector3.ZERO],
		],
	},
}

static func source_sample(clip: String, time: float) -> Dictionary:
	var recovering := clip.begins_with("recover_")
	var action := clip.get_slice("_", 1)
	if not PHRASES.has(action):
		action = "basic"
	var phase := clampf(time / RECOVERY if recovering else time, 0.0, 1.0)
	if recovering:
		var split: float = SOURCE_FOLLOW[action]
		if phase < split:
			return {"action": "Spell_Simple_Shoot", "time": .24 + phase / split * .26}
		return {"action": "Spell_Simple_Exit", "time": (phase - split) / (1.0 - split) * .4333333}
	var split: float = SOURCE_LOAD[action]
	if phase < split:
		return {"action": "Spell_Simple_Enter", "time": phase / split * .5333333}
	return {"action": "Spell_Simple_Shoot", "time": (phase - split) / (1.0 - split) * .24}

static func apply_recoil(rig: RefCounted, actor: Variant, influence: float) -> void:
	var phase := clampf(actor.impact_time / actor.recoil_duration, 0.0, 1.0)
	# The native shoulders absorb an actual impact, then return through one
	# small rebound. This is an upper-body response only: no boot, pelvis,
	# actor translation or camera transform participates in the reaction.
	var compression := smoothstep(0.0, .16, phase) * (1.0 - smoothstep(.16, .67, phase))
	var rebound := -.18 * sin(PI * smoothstep(.57, 1.0, phase))
	var amount: float = (compression + rebound) * actor.recoil_intensity * influence
	var direction: float = actor.recoil_direction
	_rotate(rig, "spine_01", Vector3(.035, .015 * direction, .025 * direction) * amount)
	_rotate(rig, "spine_03", Vector3(.075, .030 * direction, .055 * direction) * amount)
	# The gaze checks later than the chest and recovers with less rebound.
	var head_compression := smoothstep(.025, .18, phase) * (1.0 - smoothstep(.18, .70, phase))
	var head_amount: float = (head_compression + rebound * .55) * actor.recoil_intensity * influence
	_rotate(rig, "Head", Vector3(-.035, -.010 * direction, -.030 * direction) * head_amount)

static func apply(rig: RefCounted, clip: String, time: float) -> void:
	if not clip.begins_with("windup_") and not clip.begins_with("recover_"):
		return
	var action := clip.get_slice("_", 1)
	if not PHRASES.has(action):
		action = "basic"
	var recovering := clip.begins_with("recover_")
	var phase := clampf(time / RECOVERY if recovering else time, 0.0, 1.0)
	var keys: Array = PHRASES[action]["recover" if recovering else "windup"]
	# Hip loading leads the chest; the free palm completes the gesture.
	# The lead vanishes exactly at entry/release/settle, so all source bones
	# still meet the same release pose and a cancellation has no stored pose.
	var state := _state(keys, phase, recovering)
	var entry := .22 if action == "heavy" else .14
	var influence := 1.0 - smoothstep(.60, 1.0, phase) if recovering else smoothstep(0.0, entry, phase)
	if influence <= 0.0:
		return
	var skeleton: Skeleton3D = rig.skeleton
	# Keep the actual source sole positions and orientations while the pelvis
	# turns under the chest. Solving with the original rest lengths preserves
	# the pose's planted boots instead of producing a sliding or stretched leg.
	var soles: Array[Transform3D] = []
	var poles: Array[Vector3] = []
	for suffix in ["l", "r"]:
		soles.append(skeleton.get_bone_global_pose(skeleton.find_bone("foot_" + suffix)))
		poles.append(skeleton.get_bone_global_pose(skeleton.find_bone("calf_" + suffix)).origin - skeleton.get_bone_global_pose(skeleton.find_bone("thigh_" + suffix)).origin)
	_rotate(rig, "pelvis", state[1] * influence)
	_rotate(rig, "spine_01", state[2] * influence * .45)
	_rotate(rig, "spine_03", state[2] * influence * .55)
	# Counter the chest turn so the gaze remains directed toward the cast.
	_rotate(rig, "Head", Vector3(-state[2].x * .35, -state[2].y * .55, -state[2].z * .25) * influence)
	rig.hold_cast_soles(soles, poles)
	var hand := skeleton.find_bone("hand_l")
	var current := skeleton.get_bone_global_pose(hand)
	var chest: Vector3 = skeleton.get_bone_global_pose(skeleton.find_bone("spine_03")).origin
	var target := current.origin.lerp(chest + state[0], influence)
	var wrist := Basis.from_euler(state[3] * influence) * current.basis
	rig.solve_cast_arm(target, wrist)

static func _state(keys: Array, phase: float, recovering: bool = false) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for field in range(1, 5):
		var lead := .055 if field == 2 else (.025 if field == 3 else 0.0)
		var timed := clampf(phase + lead * sin(PI * phase), 0.0, 1.0)
		result.append(_path(keys, field, timed, recovering))
	return result

static func _path(keys: Array, field: int, phase: float, recovering: bool) -> Vector3:
	var index := 0
	while index < keys.size() - 2 and phase > float(keys[index + 1][0]):
		index += 1
	var first: Array = keys[index]
	var second: Array = keys[index + 1]
	var width := float(second[0]) - float(first[0])
	var amount := clampf((phase - float(first[0])) / width, 0.0, 1.0)
	var squared := amount * amount
	var cubed := squared * amount
	var start: Vector3 = first[field]
	var finish: Vector3 = second[field]
	var start_velocity := _tangent(keys, field, index, recovering) * width
	var finish_velocity := _tangent(keys, field, index + 1, recovering) * width
	return start * (2.0 * cubed - 3.0 * squared + 1.0) + start_velocity * (cubed - 2.0 * squared + amount) + finish * (-2.0 * cubed + 3.0 * squared) + finish_velocity * (cubed - squared)

static func _tangent(keys: Array, field: int, index: int, recovering: bool) -> Vector3:
	# Shape-preserving Hermite tangents continue through passing keys. A real
	# change of direction stops only that component, rather than freezing the
	# entire hand/chest at each key as independent smoothsteps used to do.
	if index == 0:
		if not recovering:
			return Vector3.ZERO
		return (keys[1][field] - keys[0][field]) / float(keys[1][0] - keys[0][0]) * .65
	if index == keys.size() - 1:
		if recovering:
			return Vector3.ZERO
		return (keys[index][field] - keys[index - 1][field]) / float(keys[index][0] - keys[index - 1][0]) * .20
	var before_width := float(keys[index][0]) - float(keys[index - 1][0])
	var after_width := float(keys[index + 1][0]) - float(keys[index][0])
	var before: Vector3 = (keys[index][field] - keys[index - 1][field]) / before_width
	var after: Vector3 = (keys[index + 1][field] - keys[index][field]) / after_width
	var result := Vector3.ZERO
	var first_weight := 2.0 * after_width + before_width
	var second_weight := after_width + 2.0 * before_width
	for axis in 3:
		if before[axis] * after[axis] > 0.0:
			result[axis] = (first_weight + second_weight) / (first_weight / before[axis] + second_weight / after[axis])
	return result

static func _rotate(rig: RefCounted, name: String, angles: Vector3) -> void:
	var bone: int = rig.skeleton.find_bone(name)
	var current: Transform3D = rig.skeleton.get_bone_global_pose(bone)
	rig._global_rotation(bone, Basis.from_euler(angles) * current.basis)
