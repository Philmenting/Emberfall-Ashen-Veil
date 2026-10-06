extends SceneTree
## Inspect the actual native skin during hostile preparation, contact and
## weighted recovery. No source mesh, camera or simulation state is rewritten.
const Actor=preload("res://scripts/dungeon_actor.gd")
const Rig=preload("res://scripts/character_rig.gd")
const Style=preload("res://scripts/hostile_style.gd")
var checks:=0
var failures:=0

func _initialize() -> void: run_checks.call_deferred()
func check(value: bool,label: String) -> void:
	checks+=1
	if not value: failures+=1; push_error("FAIL: "+label)

func make_actor(key: String) -> Node3D:
	var actor:=Actor.new(); actor.hostile=true; actor.boss=key.begins_with("guardian_")
	actor.kind="boss" if actor.boss else key
	if actor.boss: actor.region_index=int(key.right(1))
	root.add_child(actor); actor.animate(.15,false)
	return actor

func pose_error(a: Array[Transform3D],b: Array[Transform3D]) -> float:
	var error:=0.0
	for index in a.size():
		error=maxf(error,a[index].origin.distance_to(b[index].origin))
		for axis in 3: error=maxf(error,a[index].basis[axis].distance_to(b[index].basis[axis]))
	return error

func posed_minimum(rig: RefCounted,arrays: Array) -> float:
	var transforms: Array[Transform3D]=[]
	for bone in rig.NAMES.size(): transforms.append(rig.skeleton.get_bone_global_pose(bone)*rig.rest[bone].affine_inverse())
	var minimum:=INF
	for index in arrays[Mesh.ARRAY_VERTEX].size():
		var point:=Vector3.ZERO
		for influence in 4:
			var weight: float=arrays[Mesh.ARRAY_WEIGHTS][index*4+influence]
			if weight>0.0: point+=(transforms[arrays[Mesh.ARRAY_BONES][index*4+influence]]*arrays[Mesh.ARRAY_VERTEX][index])*weight
		minimum=minf(minimum,point.y)
	return minimum

func run_checks() -> void:
	var contacts: Dictionary={}
	for key in Style.KEYS:
		var actor:=make_actor(key)
		var rig: RefCounted=actor.motion_rig
		var mesh: ArrayMesh=rig.mesh; var skin: Skin=rig.skin
		var arrays: Array=mesh.surface_get_arrays(0)
		var world_before: Transform3D=actor.transform
		var mesh_identity:=true; var lengths:=true; var scales:=true; var finite:=true
		var grounded:=true; var continuity:=true
		var max_length_error:=0.0; var length_bone:=""; var max_continuity:=0.0; var max_emission:=0.0
		for action in ["basic","skill","heavy"]:
			var duration: float=Rig.Clips.recovery_duration(key,action)
			rig.pose("windup_"+action,1.0)
			var contact: Array[Transform3D]=rig.capture_pose()
			if action==Rig.Clips.hostile_action(key): contacts[key]=contact
			rig.pose("recover_"+action,0.0)
			var join_error:=pose_error(contact,rig.capture_pose())
			max_continuity=maxf(max_continuity,join_error)
			continuity=continuity and join_error<.0003
			for clip in ["windup_"+action,"recover_"+action]:
				for frame in range(31):
					rig.pose(clip,float(frame)/30.0*(duration if clip.begins_with("recover") else 1.0))
					for bone in rig.NAMES.size():
						var pose: Transform3D=rig.skeleton.get_bone_pose(bone)
						finite=finite and pose.origin.is_finite() and pose.basis.x.is_finite() and pose.basis.y.is_finite() and pose.basis.z.is_finite()
						if bone in range(2,18):
							var length_error:=absf(pose.origin.length()-rig.skeleton.get_bone_rest(bone).origin.length())
							if length_error>max_length_error: max_length_error=length_error; length_bone=String(rig.NAMES[bone])
							lengths=lengths and length_error<.0002
						if bone not in [24,25,26]: scales=scales and pose.basis.get_scale().distance_to(Vector3.ONE)<.0002
						elif bone in [25,26]: scales=scales and pose.basis.get_scale().y>=.70 and pose.basis.get_scale().y<=1.0002
					if frame in [0,15,30]: grounded=grounded and posed_minimum(rig,arrays)>-.015
					mesh_identity=mesh_identity and rig.mesh==mesh and rig.skin==skin
		check(lengths and scales and finite,key+": all native actions keep finite unit-scale joints and authored anatomical chain lengths")
		check(mesh_identity and actor.transform==world_before,key+": preparation and recovery share the immutable source skin and fixed world actor")
		check(continuity,key+": every windup enters its contact recovery without a pose discontinuity")
		check(grounded,key+": actual weighted body, weapon, censer, shield and cloth clear the floor across action phases")
		actor.last_clip=""; actor.anticipation=.72; actor.animate(.10,false)
		var prepared: Array[Transform3D]=rig.capture_pose()
		actor.react_from(actor.position+Vector3(1,0,0),Vector3.ZERO,.8); actor.animate(.04,false)
		var impacted: Array[Transform3D]=rig.capture_pose()
		check(pose_error(prepared,impacted)>.0001 and actor.transform==world_before,key+": an actual hit visibly compresses the native upper body without moving its world anchor")
		actor.animate(0.0,false)
		check(pose_error(impacted,rig.capture_pose())<.00002,key+": repeated zero-time impact frames cannot accumulate bone deformation")
		actor.impact_time=-1.0; actor.anticipation=0.0; actor.set_telegraph(.8,1.4); actor.animate(.01,false)
		check(actor.last_clip=="windup_heavy" and actor.release_time<0.0,key+": an authoritative warning retains the heavy preparation and cannot invent release")
		actor.strike("heavy"); actor.animate(.12,false)
		check(actor.last_clip=="recover_heavy" and actor.release_time>=0.0,key+": the real warning release reaches the heavy recovery once")
		var duration: float=Rig.Clips.recovery_duration(key,"heavy")
		actor.animate(duration+.10,false)
		check(actor.attack_time<0.0 and actor.release_time<0.0,key+": weighted recovery completes using the native clip's duration")
		var material_valid:=true; var restrained_glow:=false
		for index in arrays[Mesh.ARRAY_VERTEX].size():
			var color: Color=arrays[Mesh.ARRAY_COLOR][index]
			var finish: Vector2=arrays[Mesh.ARRAY_TEX_UV2][index]
			max_emission=maxf(max_emission,finish.y)
			# Mesh channels are float32; the exact authored .60 reads back as
			# .6000000238. This bound allows one small representation error.
			material_valid=material_valid and color.r>=0.0 and color.g>=0.0 and color.b>=0.0 and maxf(color.r,maxf(color.g,color.b))<1.0 and finish.x>=0.0 and finish.x<=1.0 and finish.y<=.600001
			restrained_glow=restrained_glow or finish.y>.0
		check(material_valid and (restrained_glow or key=="raider"),key+": baked pigments stay physically bounded and luminous inlays retain restrained emission")
		print("HOSTILE_METRIC ",key," length=",max_length_error," bone=",length_bone," join=",max_continuity," max_emission=",max_emission)
		actor.free()
	var distinct:=true
	var roles: Array[String]=["raider","hexer","bulwark","elite","guardian_0"]
	for index in roles.size()-1:
		for other in range(index+1,roles.size()): distinct=distinct and pose_error(contacts[roles[index]],contacts[roles[other]])>.08
	check(distinct,"ordinary scavenger, caster, shield bearer, elite and Bell Warden contacts carry distinct native action silhouettes")
	print("HOSTILE QUALITY SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
