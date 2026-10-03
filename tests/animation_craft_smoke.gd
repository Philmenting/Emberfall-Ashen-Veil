extends SceneTree
## Physical presentation contracts: support, whole-body force, directional
## reactions, interruption and exact simulation parity across all classes.
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
func make_actor(key: String) -> Node3D:
	var actor:=Actor.new(); actor.boss=key.begins_with("guardian_")
	actor.hostile=actor.boss or key not in Actor.HEROES
	actor.kind="boss" if actor.boss else key
	if actor.boss: actor.region_index=int(key.right(1))
	root.add_child(actor)
	return actor
func run_checks() -> void:
	for key in ["Vowkeeper","Arcanist","Ranger","raider","bulwark","hexer","elite","guardian_0","guardian_1","guardian_2","guardian_3"]:
		var actor:=make_actor(key)
		actor.strike("basic",.4,true); actor.sync_attack(.12); actor.animate(.016,false)
		var loaded_hip: Vector3=actor.motion_rig.skeleton.get_bone_global_pose(0).origin
		var loaded_chest: Basis=actor.motion_rig.skeleton.get_bone_global_pose(1).basis
		var loaded: PackedFloat32Array=actor.joint_angles.duplicate()
		check(absf(actor.chest_yaw)>.05 and absf(actor.joint_angles[0])>.015,key+": windup loads pelvis and turns the chest")
		actor.release_attack()
		check(loaded_chest!=actor.motion_rig.skeleton.get_bone_global_pose(1).basis and loaded_hip.distance_to(actor.motion_rig.skeleton.get_bone_global_pose(0).origin)>.025,key+": contact transfers real torso/hip weight")
		check(absf(loaded[10]-actor.joint_angles[10])+absf(loaded[13]-actor.joint_angles[13])>.025,key+": legs respond to the loaded body and contact")
		var finite:=true; var grounded:=true; var continuity:=true
		var last: Vector3=actor.motion_rig.skeleton.get_bone_global_pose(0).origin
		for frame in range(40):
			actor.animate(1.0/120.0,false,0)
			var hip: Vector3=actor.motion_rig.skeleton.get_bone_global_pose(0).origin
			continuity=continuity and hip.distance_to(last)<actor.figure_height*.035
			last=hip
			finite=finite and actor.pose_bounds().position.is_finite() and actor.pose_bounds().size.is_finite()
			for foot in [12,15]: grounded=grounded and absf(actor.motion_rig.skeleton.get_bone_global_pose(foot).origin.y-actor.motion_rig.rest[foot].y)<.045
		check(finite and continuity,key+": follow-through settles without a root-position pop")
		check(grounded,key+": support ankles stay at the physical floor during contact and recovery")
		actor.animate(.6,false); actor.reduced_motion=true; actor.animate(.4,false)
		var quiet: PackedFloat32Array=actor.joint_angles.duplicate(); var quiet_yaw: float=actor.chest_yaw
		actor.animate(.3,false)
		check(actor.joint_angles==quiet and actor.chest_yaw==quiet_yaw,key+": Reduced Motion leaves idle completely stationary")
		actor.reduced_motion=false
		actor.react(-1,.5); actor.animate(.05,false)
		var weak: float=absf(actor.motion_offset.x)
		actor.impact_time=-1; actor.react(1,1.4); actor.animate(.05,false)
		check(actor.motion_offset.x>0 and absf(actor.motion_offset.x)>weak,key+": stronger directional damage has a stronger recoil")
		actor.die()
		var above_floor:=true; var staged:=false
		for frame in range(32):
			actor.animate(1.0/60.0,false)
			above_floor=above_floor and absf(actor.motion_rig.contact_floor()-.015)<.003
			if frame==8: staged=absf(actor.joint_angles[1])>.10 and absf(actor.joint_angles[10])>.05
		check(staged and above_floor,key+": knees and torso collapse in stages without sinking through the floor")
		actor.animate(.2,false)
		check(actor.pose_frame==5 and actor.silhouette_focus==0 and actor.emphasis<1.0,key+": settled corpses recede from live combat")
		actor.free()
	var walker:=make_actor("Vowkeeper"); walker.gait_blend=1.0
	for frame in range(24): walker.animate(1.0/60.0,true,3)
	var support:=12 if fposmod(walker.gait_phase,TAU)<PI else 15
	var planted: Vector3=walker.motion_rig.skeleton.get_bone_global_pose(support).origin
	var locked:=true
	for frame in range(8):
		walker.animate(1.0/60.0,false,0)
		locked=locked and walker.motion_rig.skeleton.get_bone_global_pose(support).origin.distance_to(planted)<.006
	check(locked,"stopping plants one foot while the swing foot returns to guard")
	walker.free()
	var fast:=make_actor("Vowkeeper")
	fast.strike("basic",.12,true); fast.sync_attack(.01); fast.animate(.01,false); fast.release_attack()
	fast.animate(.06,false)
	var old_root: Vector3=fast.motion_offset
	fast.strike("sunder",.10,true); fast.sync_attack(.09); fast.animate(.008,false)
	check(fast.external_release and fast.release_time<0.0 and fast.motion_offset.distance_to(old_root)<.02,"a fast real cast blends out of recovery and retains its own countdown")
	check(fast.release_attack() and fast.transition_time<0.0 and fast.joint_angles[0]>.10,"the following real impact reaches its contact pose immediately during the recovery blend")
	fast.free()
	var bot:=Bot.new()
	for class_key in Actor.HEROES:
		bot.character_class=class_key
		var sim:=Sim.new(); var reference:=Sim.new()
		sim.setup(class_key,bot._combat_stats(),1,"Guardian",1979)
		reference.setup(class_key,bot._combat_stats(),1,"Guardian",1979)
		var world:=World.new(); world.simulation=sim; world.character_class=class_key; world.active=false
		root.add_child(world); world.set_process(false); world.active=true
		var same:=true
		for frame in range(420):
			world._process(1.0/60.0); reference.advance(1.0/60.0)
			same=same and sim.encode_snapshot()==reference.encode_snapshot()
		check(same,class_key+": rendered attacks/reactions/readability never change simulation or RNG")
		var before: String=sim.encode_snapshot()
		world._update_combat_readability(.2)
		check(sim.encode_snapshot()==before and world.hero.silhouette_focus>.5,class_key+": focus is visual only and the heroine stays emphasized")
		world.hero.die(); world.hero.animate(1.5,false)
		world._update_combat_readability(.2)
		check(world.hero.silhouette_focus==0.0 and world.hero.emphasis<.7 and not world.hero_marker.visible,class_key+": combat focus does not restore the defeated heroine's live emphasis")
		world.free()
	bot.free()
	print("ANIMATION CRAFT SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
