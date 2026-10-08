extends SceneTree
const Actor=preload("res://scripts/dungeon_actor.gd")
var checks:=0
var failures:=0
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures+=1;push_error(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	for key in Actor.HEROES+Actor.HOSTILES+["guardian_0","guardian_1","guardian_2","guardian_3"]:
		var actor=make_actor(key);check_source_walk(actor);actor.free()
	print("WALK CONTACT DIAGNOSTIC: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
func make_actor(key: String) -> Node3D:
	var actor:=Actor.new(); actor.boss=key.begins_with("guardian_")
	actor.hostile=actor.boss or key not in Actor.HEROES; actor.kind="boss" if actor.boss else key
	if actor.boss: actor.region_index=int(key.right(1))
	root.add_child(actor); actor.animate(.15,false)
	return actor
func native_boot_probes(rig: RefCounted) -> Array:
	var result: Array=[]
	for surface: MeshInstance3D in rig.surfaces:
		if not String(surface.name).contains("Feet"): continue
		for slot in surface.mesh.get_surface_count():
			var arrays: Array=surface.mesh.surface_get_arrays(slot)
			var used: Dictionary={}
			for index in arrays[Mesh.ARRAY_INDEX]:used[index]=true
			for index in used:
				var vertex: Vector3=arrays[Mesh.ARRAY_VERTEX][index]
				if vertex.y>=.055:continue
				var influences: Array=[];var sides:=Vector2.ZERO
				for influence in 4:
					var weight: float=arrays[Mesh.ARRAY_WEIGHTS][index*4+influence]
					if weight<=0:continue
					var bind: int=arrays[Mesh.ARRAY_BONES][index*4+influence]
					var name: String=String(surface.skin.get_bind_name(bind))
					var bone: int=rig.skeleton.find_bone(name) if not name.is_empty() else surface.skin.get_bind_bone(bind)
					assert(bone>=0,"A real native boot influence must resolve")
					var bone_name:=String(rig.skeleton.get_bone_name(bone))
					if bone_name.ends_with("_l"):sides.x+=weight
					elif bone_name.ends_with("_r"):sides.y+=weight
					influences.append([bone,surface.skin.get_bind_pose(bind)*vertex,weight])
				assert(maxf(sides.x,sides.y)>.5,"Native sole side is determined by its real anatomical influences")
				result.append({"side":0 if sides.x>sides.y else 1,"influences":influences})
	return result

func native_boot_minima(actor: Node3D,probes: Array) -> Vector2:
	var rig: RefCounted=actor.motion_rig
	var poses: Array[Transform3D]=[]
	for bone in rig.skeleton.get_bone_count():poses.append(rig.skeleton.get_bone_global_pose(bone))
	var result:=Vector2(INF,INF)
	for probe in probes:
		var point:=Vector3.ZERO
		for influence in probe.influences:point+=(poses[influence[0]]*influence[1])*influence[2]
		var world: Vector3=actor.body.to_global(rig.motion_node.transform*point)
		result[probe.side]=minf(result[probe.side],world.y)
	return result

func check_source_walk(actor: Node3D) -> void:
	var rig: RefCounted=actor.motion_rig
	var key: String=actor.appearance_key
	var probes:=native_boot_probes(rig)
	check(probes.size()>100,key+": walking oracle reconstructs actual indexed boot soles through all four original mixed native skin influences")
	var grounded:=true;var raised:=false;var locked:=true;var finite:=true
	var previous: Array[Vector3]=[Vector3.ZERO,Vector3.ZERO];var old_active: Array[bool]=[false,false]
	var stable_samples:=0;var max_drift:=0.0;var minimum:=INF;var maximum_lift:=0.0
	var loaded_minimum:=INF;var free_minimum:=INF;var loaded_maximum:=-INF
	var worst_loaded: Dictionary={}
	for frame in 120:
		var displacement:=Vector3(0,0,-2.0/60.0)
		actor.position+=displacement;actor.follow_travel(displacement);actor.animate(1.0/60.0,true,2.0)
		var minima:=native_boot_minima(actor,probes)
		var side:=0 if actor.plant_active[0] else 1
		var ankle: Vector3=actor.body.to_global(rig.motion_node.transform*rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone("foot_l" if side==0 else "foot_r")).origin)
		if frame>12:
			if minima[side]<loaded_minimum:
				var named_poses: Dictionary={}
				for name in ["pelvis","thigh_l","calf_l","foot_l","ball_l","thigh_r","calf_r","foot_r","ball_r"]:
					var bone: int=rig.skeleton.find_bone(name)
					if bone<0:continue
					var pose: Transform3D=rig.skeleton.get_bone_global_pose(bone)
					named_poses[name]={"origin":[pose.origin.x,pose.origin.y,pose.origin.z],"basis_x":[pose.basis.x.x,pose.basis.x.y,pose.basis.x.z],"basis_y":[pose.basis.y.x,pose.basis.y.y,pose.basis.y.z],"basis_z":[pose.basis.z.x,pose.basis.z.y,pose.basis.z.z]}
				worst_loaded={"frame":frame,"plant_active":actor.plant_active.duplicate(),"loaded_side":side,"gait_phase":actor.gait_phase,"min_loaded_world_y":minima[side],"min_free_world_y":minima[1-side],"motion_y":rig.motion_node.position.y,"source_named_poses":named_poses}
			minimum=minf(minimum,minf(minima.x,minima.y));maximum_lift=maxf(maximum_lift,minima[1-side])
			loaded_minimum=minf(loaded_minimum,minima[side]);free_minimum=minf(free_minimum,minima[1-side]);loaded_maximum=maxf(loaded_maximum,minima[side])
			grounded=grounded and absf(minima[side])<.04 and minima[1-side]>-.035
			raised=raised or minima[1-side]>.07
			locked=locked and actor.plant_active[side] and not actor.plant_active[1-side] and ankle.distance_to(actor.plant_points[side])<.008
			if actor.plant_active[side] and old_active[side]:
				var drift:=ankle.distance_to(previous[side]);max_drift=maxf(max_drift,drift)
				locked=locked and drift<.008;stable_samples+=1
		finite=finite and minima.is_finite() and ankle.is_finite() and actor.pose_bounds().position.is_finite()
		previous[side]=ankle;old_active=actor.plant_active.duplicate()
	check(grounded and raised and finite,key+": native walking keeps the actually weighted loaded sole on the floor while the other original boot visibly clears it")
	check(locked and stable_samples>30,key+": real native stance ankle stays planted in world space during authoritative actor travel")
	print("NATIVE_WALK_METRIC ",key," boot_probes=",probes.size()," stable_samples=",stable_samples," max_world_stance_drift=",max_drift," min_world_boot_y=",minimum," min_world_loaded_y=",loaded_minimum," max_world_loaded_y=",loaded_maximum," min_world_free_y=",free_minimum," max_world_free_lift=",maximum_lift)
	print("NATIVE_WALK_WORST ",key," ",JSON.stringify(worst_loaded))

