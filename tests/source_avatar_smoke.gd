extends SceneTree
const Actor=preload("res://scripts/dungeon_actor.gd")
var checks:=0
var failures: Array[String]=[]
func check(value: bool,message: String) -> void:
	checks+=1
	if not value:failures.append(message);push_error(message)
func _initialize() -> void:call_deferred("run")
func actual_bounds(rig: RefCounted) -> AABB:
	return preload("res://tests/source_avatar_skin.gd").actual_bounds(rig)
func run() -> void:
	var actor=Actor.new();actor.kind="Arcanist";root.add_child(actor)
	check(actor.source_avatar,"Ordinary Arcanist uses authored avatar")
	check(actor.motion_rig.build_ok,"Avatar build succeeds")
	check(actor.motion_rig.skeleton.get_bone_count()==65,"All source65 bones remain")
	check(not actor.model.visible,"Legacy proxy is hidden")
	check(actor.motion_rig.triangles==22108,"Complete authored avatar triangle inventory")
	var phases=[["idle",.0],["walk",.25],["walk",.75],["windup_basic",.25],["windup_basic",.65],["windup_basic",1.0],["recover_basic",.10],["recover_basic",.34],["death",.90]]
	var records=[]
	for phase in phases:
		actor.motion_rig.pose(phase[0],phase[1]);actor.motion_rig.apply_actor_postprocess(actor,phase[0],phase[1],0.0,true)
		var box=actual_bounds(actor.motion_rig)
		check(box.position.y>-.025,"Whole body above floor: "+phase[0]+" "+str(box.position.y))
		check(box.size.y<2.8 and box.size.x<3.0,"No disproportionate whole-body deformation")
		check(actor.projectile_origin().is_finite() and actor.weapon_world_position().is_finite(),"Source sockets are finite")
		records.append({"clip":phase[0],"time":phase[1],"min_y":box.position.y,"size":[box.size.x,box.size.y,box.size.z]})
	actor.motion_rig.pose("idle",0.0)
	var locked=true
	var maximum_drift=0.0
	var support_frames=0
	var floor_clear=true
	for frame in 120:
		var move=Vector3(0,0,-2.0/60.0)
		actor.position+=move;actor.follow_travel(move);actor.animate(1.0/60.0,true,2.0)
		for side in 2:
			if not actor.plant_active[side]:continue
			support_frames+=1
			var foot=actor.motion_rig.skeleton.find_bone("foot_l" if side==0 else "foot_r")
			var actual=actor.body.to_global(actor.motion_rig.motion_node.transform*actor.motion_rig.skeleton.get_bone_global_pose(foot).origin)
			var drift=actual.distance_to(actor.plant_points[side])
			maximum_drift=maxf(maximum_drift,drift)
			if drift>.008:print("FOOT_DRIFT ",frame," ",side," ",drift," actual ",actual," target ",actor.plant_points[side])
			locked=locked and drift<.008
		if frame%15==0:floor_clear=floor_clear and actual_bounds(actor.motion_rig).position.y>-.012
	print("MAXIMUM FOOT DRIFT: ",maximum_drift)
	check(support_frames>=100,"Foot lock is actually exercised through world travel")
	check(locked,"Source stance foot remains locked during actual world travel")
	check(floor_clear,"Source animated walking skin stays above floor")
	actor.animate(.3,false)
	actor.strike("basic",.30,true)
	for i in 10:actor.animate(.03,false)
	check(actor.release_time<0.0,"Visual animation cannot release externally timed damage")
	actor.release_attack()
	check(actor.release_time>=0.0,"Simulation confirmation starts recovery")
	actor.configure_equipment({},"Vowkeeper")
	check(not actor.source_avatar and actor.model.visible,"Switching to legacy class restores its renderer")
	actor.configure_equipment({},"Arcanist")
	check(actor.source_avatar and not actor.model.visible,"Switching back rebuilds authored rig")
	print("SOURCE AVATAR: ",checks," checks, ",failures.size()," failures")
	print(JSON.stringify(records))
	actor.free();quit(0 if failures.is_empty() else 1)
