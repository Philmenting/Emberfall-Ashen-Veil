extends SceneTree
## Regression contracts for steady room shots, continuous orientation, physical
## action support and identical simulation across all three live 3D classes.
const Actor=preload("res://scripts/dungeon_actor.gd")
const Sim=preload("res://scripts/expedition_simulation.gd")
const World=preload("res://scripts/dungeon_world.gd")
const Bot=preload("res://tests/balance_survey_bot.gd")
var checks:=0
var failures:=0
func _initialize() -> void: run_checks.call_deferred()
func check(value: bool,label: String) -> void:
	checks+=1
	if not value: failures+=1; push_error("FAIL: "+label)
func actual_boot_floors(rig: RefCounted) -> Vector2:
	var low:=Vector2(INF,INF)
	# These probes are indexed native boot vertices with all original skin
	# influences; no legacy ankle socket or contact-plane proxy participates.
	for probe in rig.floor_probes:
		var point:=Vector3.ZERO
		for i in probe.bones.size():
			point+=(rig.skeleton.get_bone_global_pose(probe.bones[i])*probe.binds[i]*probe.point)*probe.weights[i]
		point=rig.motion_node.transform*point
		low[probe.side]=minf(low[probe.side],point.y)
	return low

func check_native_sword_boot_support(hero: Node3D,action: String="basic") -> void:
	var rig: RefCounted=hero.motion_rig
	var feet: Array[int]=[rig.skeleton.find_bone("foot_l"),rig.skeleton.find_bone("foot_r")]
	check(hero.source_avatar and rig.skeleton.get_bone_count()==65 and feet[0]>=0 and feet[1]>=0,"sword support uses both named native65 boots")
	var reference:=Actor.new();root.add_child(reference)
	var source: RefCounted=reference.motion_rig
	var source_clip: String="Sword_Regular_A" if action=="basic" else ("Sword_Regular_B" if action=="skill" else "Sword_Regular_C")
	var release: float=source.player.get_animation(source_clip).length*(.62 if action=="basic" else (.56 if action=="skill" else .67))
	source._sample("Sword_Idle",0.0)
	var guard: Array[Transform3D]=[]
	for side in 2:guard.append(source.skeleton.get_bone_global_pose(source.skeleton.find_bone("foot_l" if side==0 else "foot_r")))
	# Earlier direction assertions deliberately leave a turn in progress.
	# Begin this independent stance fixture already facing its held target.
	hero.rotation.y=hero.desired_yaw
	var anchor: Vector3=hero.global_position
	var planted: Array[Vector3]=[]
	var guard_support:=true
	var clearance:=true
	var starts:=Vector2.ZERO
	var peak:=Vector2.ZERO
	var original_starts:=Vector2.ZERO
	var original_peak:=Vector2.ZERO
	var original_path: Array[Vector3]=[]
	var max_world_drift:=0.0
	var hip_start:=0.0
	var hip_low:=INF
	var hip_high:=-INF
	var hip_curve: Array[float]=[]
	var pelvis: int=rig.skeleton.find_bone("pelvis")
	for sample in range(31):
		var phase:=float(sample)/30.0
		# A fresh committed cast needs real elapsed blend time; zero-delta
		# redraws would hold its initial native transition at amount=0.
		hero.sync_attack(hero.attack_duration*(1.0-phase))
		hero.animate(0.0 if sample==0 else hero.attack_duration/30.0,false)
		# Preserve the original two-boot hop as an independent source oracle.
		# Direct native sampling bypasses production selection, blending and IK.
		source._sample(source_clip,release*phase)
		var original_floor:=actual_boot_floors(source)
		if sample==0:original_starts=original_floor
		original_peak=Vector2(maxf(original_peak.x,original_floor.x),maxf(original_peak.y,original_floor.y))
		original_path.append(source._point("foot_l"));original_path.append(source._point("foot_r"))
		for side in 2:
			var foot: Transform3D=rig.skeleton.get_bone_global_pose(feet[side])
			guard_support=guard_support and foot.is_equal_approx(guard[side])
			var actual_world: Vector3=rig.skeleton.to_global(foot.origin)
			if sample==0:planted.append(actual_world)
			max_world_drift=maxf(max_world_drift,actual_world.distance_to(planted[side]))
		var floor:=actual_boot_floors(rig)
		if sample==0:starts=floor;hip_start=rig.skeleton.to_global(rig.skeleton.get_bone_global_pose(pelvis).origin).y
		peak=Vector2(maxf(peak.x,floor.x),maxf(peak.y,floor.y))
		var actual_hip: float=rig.skeleton.to_global(rig.skeleton.get_bone_global_pose(pelvis).origin).y
		hip_low=minf(hip_low,actual_hip);hip_high=maxf(hip_high,actual_hip);hip_curve.append(actual_hip)
		clearance=clearance and floor.is_finite() and minf(floor.x,floor.y)>=.0029
	if action=="basic":check(original_peak.x>original_starts.x+.10 and original_peak.y>original_starts.y+.10 and original_path[0].distance_to(original_path[-2])>.25 and original_path[1].distance_to(original_path[-1])>.20,"the independently sampled original Sword A still lifts both weighted boots over 10 cm and preserves its complete native travelling foot paths")
	check(guard_support,"the production sword preparation holds both actual native SwordIdle Foot transforms while the original source supplies the upper-body cut")
	check(hip_start-hip_low>.005,"the production sword preparation loads the actual pelvis by over 5 mm above its planted support instead of remaining rigid")
	var recovery_guard:=true
	var contact: Array[Transform3D]=[]
	for foot in feet:contact.append(rig.skeleton.get_bone_global_pose(foot))
	hero.release_attack()
	var continuous:=true
	for side in 2:continuous=continuous and contact[side].is_equal_approx(rig.skeleton.get_bone_global_pose(feet[side]))
	check(continuous,"simulation release preserves both exact native boot transforms into sword recovery")
	for sample in range(30):
		hero.animate(.34/30.0,false)
		var floor:=actual_boot_floors(rig)
		clearance=clearance and floor.is_finite() and minf(floor.x,floor.y)>=.0029
		for side in 2:
			var foot: Transform3D=rig.skeleton.get_bone_global_pose(feet[side])
			recovery_guard=recovery_guard and foot.is_equal_approx(guard[side])
			max_world_drift=maxf(max_world_drift,rig.skeleton.to_global(foot.origin).distance_to(planted[side]))
	var landed:=actual_boot_floors(rig)
	var returned:=true
	for side in 2:returned=returned and rig.skeleton.get_bone_global_pose(feet[side]).is_equal_approx(guard[side])
	check(recovery_guard,"each actual intermediate "+action+" recovery retains both original native SwordIdle Foot transforms")
	check(max_world_drift<.008 and hero.global_position.is_equal_approx(anchor),"both actual sword feet remain within 8 mm of their world stance throughout preparation and recovery without moving the simulation actor")
	check(clearance,"all actual weighted production sword soles clear 2.9 mm throughout the complete planted preparation and recovery")
	check(minf(landed.x,landed.y)<=.0031 and landed.x<.02 and landed.y<.02 and returned,"the complete native sword recovery returns both actual Foot transforms to guard with a real support sole at 3 mm and both boots below 20 mm")
	print("NATIVE SWORD SUPPORT ",action,": start=",starts," peak=",peak," landed=",landed," max_world_stance_drift=",max_world_drift," actual_world_hip_load=",hip_start-hip_low," actual_hip_range=",hip_high-hip_low," actual_hip_curve=",hip_curve)
	print("ORIGINAL NATIVE SWORD SOURCE ",action,": start=",original_starts," peak=",original_peak," foot_l travel=",original_path[0].distance_to(original_path[-2])," foot_r travel=",original_path[1].distance_to(original_path[-1]))
	reference.free()

func run_checks() -> void:
	for action in ["basic","skill","heavy"]:
		var hero:=Actor.new();root.add_child(hero)
		hero.strike("basic" if action=="basic" else ("signature" if action=="skill" else "sunder"),.5,true)
		check_native_sword_boot_support(hero,action)
		hero.free()
	print("SWORD HIP DIAGNOSTIC: ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
