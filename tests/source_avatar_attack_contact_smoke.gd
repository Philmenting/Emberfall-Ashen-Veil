extends "res://tests/source_avatar_grip_smoke.gd"
## Reuse the actual indexed arm/shaft contact audit at the new strongest
## full-body loading and catch poses, which the locomotion audit omits.
const Combat = preload("res://scripts/source_avatar_combat.gd")

func run() -> void:
	var actor = make_actor()
	audit_actual_handle_mesh(actor.motion_rig)
	for action in ["basic", "skill", "heavy"]:
		for phase in [.28, .33, .57, .82, 1.0]:
			var clip: String = "windup_" + action
			actor.motion_rig.pose(clip, phase)
			actor.motion_rig.apply_actor_postprocess(actor, clip, phase, 0.0, true)
			audit_pose(actor, action + ": full-body load " + str(phase))
		for phase in [.0, .14, .18, .40, .65, 1.0]:
			var clip: String = "recover_" + action
			var time: float = phase * Combat.RECOVERY
			actor.motion_rig.pose(clip, time)
			actor.motion_rig.apply_actor_postprocess(actor, clip, time, 0.0, true)
			audit_pose(actor, action + ": full-body catch/recovery " + str(phase))
	actor.free()
	for style in ["basic", "signature", "starfall"]:
		actor = make_actor()
		var duration := .80 if style == "starfall" else .42
		actor.strike(style, duration, true)
		actor.sync_attack(duration * .67)
		actor.animate(0.0, false)
		audit_pose(actor, style + ": actual simulation-held body load")
		actor.sync_attack(0.0)
		actor.animate(0.0, false)
		check(actor.release_time < 0.0, style + ": contact posing retains simulation authority")
		check(actor.release_attack(), style + ": actual simulation confirmation starts full-body recovery")
		actor.animate(Combat.RECOVERY * .16, false)
		audit_pose(actor, style + ": actual full-body release catch")
		actor.free()
	check(poses == 39, "Exactly 39 peak load, catch, recovery and simulation poses exercise physical staff contact")
	print("SOURCE AVATAR ATTACK CONTACT SMOKE: ", checks, " checks, ", poses, " actual poses, ", failures.size(), " failures")
	print("Maximum actual arm/shaft penetration: ", worst_penetration, " m; maximum finger gap: ", widest_finger_gap, " m")
	quit(0 if failures.is_empty() else 1)
