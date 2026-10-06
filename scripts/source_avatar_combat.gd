extends RefCounted
## Three cast phrases on the original native65 rig. The source clips supply
## the stance, fingers and breathing; these paths articulate the actual left
## arm and torso without translating a limb joint or changing a skin bind.
const RECOVERY := .34
const PHRASES := {
	"basic": {
		# A small gathered palm, a direct jab, and a short elastic catch.
		"windup": [
			[0.0, Vector3(.24, -.30, .06), Vector3.ZERO, Vector3.ZERO, Vector3.ZERO],
			[.40, Vector3(.23, .02, .23), Vector3(0, .025, 0), Vector3(-.025, -.065, .015), Vector3(-.18, 0, -.08)],
			[.72, Vector3(.20, .08, .31), Vector3(0, .015, 0), Vector3(-.010, -.030, .005), Vector3(-.10, 0, -.04)],
			[1.0, Vector3(.12, .13, .46), Vector3(0, -.025, 0), Vector3(.035, .065, -.010), Vector3.ZERO],
		],
		"recover": [
			[0.0, Vector3(.12, .13, .46), Vector3(0, -.025, 0), Vector3(.035, .065, -.010), Vector3.ZERO],
			[.16, Vector3(.11, .10, .475), Vector3(0, -.020, 0), Vector3(.045, .050, -.015), Vector3(.06, 0, 0)],
			[.45, Vector3(.24, .03, .29), Vector3(0, .010, 0), Vector3(-.015, -.020, .010), Vector3(-.12, 0, -.05)],
			[1.0, Vector3(.24, -.30, .06), Vector3.ZERO, Vector3.ZERO, Vector3.ZERO],
		],
	},
	"skill": {
		# Gather above the left shoulder, open the chest, sweep down and out.
		"windup": [
			[0.0, Vector3(.24, -.30, .06), Vector3.ZERO, Vector3.ZERO, Vector3.ZERO],
			[.36, Vector3(.28, .36, .15), Vector3(0, .050, -.025), Vector3(-.045, -.105, -.045), Vector3(-.26, -.08, -.17)],
			[.65, Vector3(.32, .41, .25), Vector3(0, .025, -.020), Vector3(-.035, -.045, -.060), Vector3(-.23, -.05, -.13)],
			[.84, Vector3(.25, .30, .36), Vector3(0, -.025, .005), Vector3(.015, .045, -.020), Vector3(-.12, -.025, -.04)],
			[1.0, Vector3(.12, .24, .44), Vector3(0, -.045, .015), Vector3(.045, .100, .015), Vector3(-.08, 0, 0)],
		],
		"recover": [
			[0.0, Vector3(.12, .24, .44), Vector3(0, -.045, .015), Vector3(.045, .100, .015), Vector3(-.08, 0, 0)],
			[.18, Vector3(.08, .19, .47), Vector3(0, -.035, .015), Vector3(.065, .080, .020), Vector3(.04, 0, .04)],
			[.49, Vector3(.29, .14, .29), Vector3(0, .015, -.010), Vector3(-.015, -.035, -.020), Vector3(-.18, -.04, -.10)],
			[1.0, Vector3(.24, -.30, .06), Vector3.ZERO, Vector3.ZERO, Vector3.ZERO],
		],
	},
	"heavy": {
		# A low chamber and held load, followed by a deliberate forward thrust.
		"windup": [
			[0.0, Vector3(.24, -.30, .06), Vector3.ZERO, Vector3.ZERO, Vector3.ZERO],
			[.40, Vector3(.38, -.20, .06), Vector3(-.035, .065, -.020), Vector3(-.065, -.145, -.035), Vector3(-.24, -.05, -.18)],
			[.76, Vector3(.40, -.12, .15), Vector3(-.030, .055, -.015), Vector3(-.050, -.105, -.025), Vector3(-.20, -.04, -.15)],
			[1.0, Vector3(.10, .10, .47), Vector3(.030, -.055, .015), Vector3(.095, .145, .025), Vector3(.04, 0, .02)],
		],
		"recover": [
			[0.0, Vector3(.10, .10, .47), Vector3(.030, -.055, .015), Vector3(.095, .145, .025), Vector3(.04, 0, .02)],
			[.18, Vector3(.08, .07, .48), Vector3(.035, -.045, .015), Vector3(.115, .120, .035), Vector3(.08, 0, .04)],
			[.50, Vector3(.30, -.04, .29), Vector3(-.010, .020, -.010), Vector3(-.025, -.040, -.015), Vector3(-.18, 0, -.09)],
			[1.0, Vector3(.24, -.30, .06), Vector3.ZERO, Vector3.ZERO, Vector3.ZERO],
		],
	},
}

static func apply(rig: RefCounted, clip: String, time: float) -> void:
	if not clip.begins_with("windup_") and not clip.begins_with("recover_"):
		return
	var action := clip.get_slice("_", 1)
	if not PHRASES.has(action):
		action = "basic"
	var recovering := clip.begins_with("recover_")
	var phase := clampf(time / RECOVERY if recovering else time, 0.0, 1.0)
	var keys: Array = PHRASES[action]["recover" if recovering else "windup"]
	var state := _state(keys, phase)
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

static func _state(keys: Array, phase: float) -> Array[Vector3]:
	var index := 0
	while index < keys.size() - 2 and phase > float(keys[index + 1][0]):
		index += 1
	var first: Array = keys[index]
	var second: Array = keys[index + 1]
	var amount := smoothstep(float(first[0]), float(second[0]), phase)
	var result: Array[Vector3] = []
	for field in range(1, 5):
		result.append((first[field] as Vector3).lerp(second[field], amount))
	return result

static func _rotate(rig: RefCounted, name: String, angles: Vector3) -> void:
	var bone: int = rig.skeleton.find_bone(name)
	var current: Transform3D = rig.skeleton.get_bone_global_pose(bone)
	rig._global_rotation(bone, Basis.from_euler(angles) * current.basis)
