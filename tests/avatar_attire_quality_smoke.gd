extends SceneTree
## Verify actual dynamic native-skinned attire buffers, fixed attachments,
## original skin/bind hierarchy, grounding, bounds and bounded upload work.
const Actor=preload("res://scripts/dungeon_actor.gd")
const NativeMeshLods=preload("res://scripts/native_mesh_lods.gd")
var checks:=0
var failures:=0
var sampled_poses:=0
var gpu_readback:=false
var gpu_poses:=0

func _initialize() -> void:run.call_deferred()
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures+=1;push_error(label)

func make_actor(key: String) -> Node3D:
	var actor=Actor.new();actor.kind=key;root.add_child(actor);actor.set_process(false)
	return actor

func bone_snapshot(rig: Variant) -> Array:
	var result=[]
	for bone in rig.skeleton.get_bone_count():result.append([rig.skeleton.get_bone_rest(bone),rig.skeleton.get_bone_pose(bone)])
	return result

func finishes_separate(rig: Variant) -> bool:
	var cloth=false;var leather=false;var metal=false
	for part: MeshInstance3D in rig.motion_node.find_children("*","MeshInstance3D",true,false):
		if not part.visible:continue
		for slot in part.mesh.get_surface_count():
			var material=part.get_active_material(slot) as StandardMaterial3D
			if material==null:continue
			var name=String(part.name)
			if name.contains("Split_Tail") or name=="Female_Ranger_Body":cloth=cloth or (material.metallic==0.0 and material.roughness>=.85 and material.metallic_specular<=.25)
			if name.contains("Leather_Facing") or name.contains("Body_Belt"):leather=leather or (material.metallic==0.0 and material.roughness>=.60 and material.roughness<=.72 and material.metallic_specular>=.30)
			if name.contains("Shoulder_Bronze") or name.contains("Worn_Steel") or name.begins_with("Vowkeeper055_"):metal=metal or (material.metallic>=.65 and material.roughness<.55)
	return cloth and leather and (metal or rig.key=="Ranger")

func bindings_follow(motion: Variant) -> bool:
	for binding in motion.records:
		if not String(binding.part.name).contains("Tail_Binding"):continue
		var side="Left" if String(binding.part.name).contains("Left") else "Right"
		var tail: Dictionary={}
		for record in motion.records:
			if String(record.part.name).contains(side+"_Split_Tail"):tail=record;break
		if tail.is_empty():return false
		for index in binding.rest.size():
			var nearest=-1;var distance=INF
			for candidate in tail.rest.size():
				var next=binding.rest[index].distance_squared_to(tail.rest[candidate])
				if next<distance:distance=next;nearest=candidate
			if nearest<0 or sqrt(distance)>.007:return false
			var edge_offset=binding.points[index]-binding.rest[index]
			var cloth_offset=tail.points[nearest]-tail.rest[nearest]
			if edge_offset.distance_to(cloth_offset)>.0005:return false
	return true

func audit_buffers(actor: Variant,label: String) -> void:
	var rig=actor.motion_rig;var motion=rig.style.attire_motion
	# Diagnostic synchronization is deliberate here and never runs in play.
	if gpu_readback:RenderingServer.force_sync()
	var actual_first=true;var actual=AABB()
	var largest=0.0;var exact_points=true;var fixed=true;var bounded=true;var finite=true
	var native_skin=true
	var transforms=[]
	for bone in rig.skeleton.get_bone_count():transforms.append(rig.skeleton.get_bone_global_pose(bone))
	for record in motion.records:
		var arrays=record.part.mesh.surface_get_arrays(record.slot)
		var points: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX] if gpu_readback else record.points
		var rs_bytes=PackedByteArray()
		if gpu_readback:rs_bytes=RenderingServer.mesh_get_surface(record.part.mesh.get_rid(),record.slot).vertex_data
		# Dummy storage intentionally ignores vertex-update calls in Godot.
		# Native GL validates real uploaded bytes; CI's headless bounds use the
		# explicit CPU upload oracle and make no GPU geometry claim.
		check(points.size()==record.points.size(),label+": actual uploaded vertex count")
		for index in points.size():
			if gpu_readback:
				exact_points=exact_points and points[index].distance_to(record.points[index])<.000001
				var server_point=Vector3(rs_bytes.decode_float(index*12),rs_bytes.decode_float(index*12+4),rs_bytes.decode_float(index*12+8))
				exact_points=exact_points and server_point.distance_to(record.points[index])<.000001
			var offset=points[index].distance_to(record.rest[index]);largest=maxf(largest,offset)
			finite=finite and points[index].is_finite()
			bounded=bounded and offset<=record.limit+.000001
			if record.mask[index]<=.00001:fixed=fixed and offset<.000001
		for probe in record.probes:
			var point=Vector3.ZERO;var total=0.0
			for influence in probe.bones.size():
				point+=(transforms[probe.bones[influence]]*probe.binds[influence]*points[probe.index])*probe.weights[influence]
				total+=probe.weights[influence]
			native_skin=native_skin and absf(total-1.0)<.000063
			point=rig.motion_node.transform*point
			actual=AABB(point,Vector3.ZERO) if actual_first else actual.expand(point);actual_first=false
	if gpu_readback:
		check(exact_points,label+": renderer reads the exact dynamically uploaded positions")
		gpu_poses+=1
	check(fixed,label+": scalp/waist/front hood attachments remain fixed")
	check(finite and bounded and native_skin,label+": all actual points stay finite, bounded and retain normalized native skin")
	check(actual.position.y>=-.001,label+": actual deformed cloth/hair stays above the floor")
	check(rig.bounds.grow(.0002).encloses(actual),label+": current actor envelope includes actually skinned deformed geometry")
	check(actual.is_equal_approx(motion.actual_bounds()),label+": independent native-skin calculation agrees with exact upload oracle")
	print("ATTIRE BUFFER ",actor.kind," ",label,": max offset=",largest," m; actual min_y=",actual.position.y)
	sampled_poses+=1

func run() -> void:
	gpu_readback=DisplayServer.get_name()!="headless" and not RenderingServer.get_video_adapter_name().is_empty()
	for arg in OS.get_cmdline_user_args():
		if arg=="--require-gpu" and not gpu_readback:
			push_error("Attire native readback requires a real GL/Vulkan renderer, not Dummy headless storage")
			print("AVATAR ATTIRE QUALITY SMOKE: 1 checks, 1 failures");quit(1);return
	print("ATTIRE VERIFICATION SCOPE: ","native renderer byte readback" if gpu_readback else "headless CPU upload/bounds oracle; Dummy vertex updates are no-op")
	for key in Actor.HEROES:
		var actor=make_actor(key);var peer=make_actor(key)
		var rig=actor.motion_rig;var motion=rig.style.attire_motion;var peer_motion=peer.motion_rig.style.attire_motion
		check(actor.source_avatar and rig.skeleton.get_bone_count()==65,key+": production actor uses one unchanged native65 skeleton")
		check(motion.records.size()==(5 if key=="Arcanist" else 2),key+": secondary detail uses only the expected existing meshes")
		check(finishes_separate(rig),key+": rendered cloth, leather and existing metal have distinct plausible PBR responses")
		check(motion.moved_vertex_count>50 and motion.moved_vertex_count<6500,key+": only bounded loose cloth/hair vertices are candidates")
		var frame_bytes=0;var private=true;var peer_unchanged=true;var lods_preserved=true
		var peer_buffers=[]
		for record in peer_motion.records:peer_buffers.append(record.part.mesh.surface_get_arrays(record.slot)[Mesh.ARRAY_VERTEX])
		for index in motion.records.size():
			var record=motion.records[index];frame_bytes+=record.rest.size()*12
			private=private and record.part.mesh!=peer_motion.records[index].part.mesh and record.part.skin==peer_motion.records[index].part.skin
			var actual_lods=NativeMeshLods.lods_for(record.part.mesh,record.slot)
			lods_preserved=lods_preserved and actual_lods.size()==record.lods.size()
			for distance in record.lods:lods_preserved=lods_preserved and actual_lods.has(distance) and actual_lods[distance]==record.lods[distance]
		check(private,key+": mutable derived buffers are actor-owned while native Skin is shared")
		check(lods_preserved,key+": actual renderer-derived meshes preserve every imported LOD distance and index")
		check(frame_bytes<=90000,key+": one dirty pose uploads at most 90 kB without adding meshes, surfaces or draw passes")
		var bones=bone_snapshot(rig);var weapon=rig.weapon.transform
		rig.style.update_motion("windup_heavy",.8,false)
		check(bindings_follow(motion),key+": coat bindings remain attached to corresponding cloth within 0.5 mm during flare")
		check(bones==bone_snapshot(rig) and weapon==rig.weapon.transform,key+": cloth/hair motion changes neither native bones nor held weapon transform")
		var before=motion.upload_calls;var before_bytes=motion.uploaded_bytes
		rig.style.update_motion("windup_heavy",.8)
		check(motion.upload_calls==before and motion.uploaded_bytes==before_bytes,key+": unchanged pose performs zero redundant uploads")
		for index in peer_motion.records.size():peer_unchanged=peer_unchanged and peer_buffers[index]==peer_motion.records[index].part.mesh.surface_get_arrays(peer_motion.records[index].slot)[Mesh.ARRAY_VERTEX]
		check(peer_unchanged,key+": changing one actor cannot deform its peer")
		for sample in [["idle",.4],["walk",.125],["walk",.375],["windup_basic",.70],["windup_skill",1.0],["windup_heavy",.8],["recover_heavy",.10],["recover_heavy",.34],["evade",.5],["death",.36],["death",.90]]:
			rig.pose(sample[0],sample[1]);rig.apply_actor_postprocess(actor,sample[0],sample[1],0.0,true)
			audit_buffers(actor,key+"/"+sample[0]+"/"+str(sample[1]))
		actor.reduced_motion=true
		rig.pose("walk",.375);rig.apply_actor_postprocess(actor,"walk",.375,0.0,true)
		check(motion.max_displacement==0.0,key+": reduced motion restores all detail vertices exactly")
		before=motion.upload_calls
		for time in [.1,.2,.4,.6]:
			rig.pose("walk",time);rig.apply_actor_postprocess(actor,"walk",time,0.0,true)
		check(motion.upload_calls==before,key+": reduced motion does not upload new buffers while source animation continues")
		actor.reduced_motion=false;rig.pose("death",.90);rig.apply_actor_postprocess(actor,"death",.90,0.0,true)
		before=motion.upload_calls
		rig.pose("death",.90);rig.apply_actor_postprocess(actor,"death",.90,0.0,true)
		check(motion.max_displacement==0.0 and motion.upload_calls==before,key+": held death keeps exact rest geometry without repeated work")
		print("ATTIRE BUDGET ",key,": records=",motion.records.size(),"; movable vertices=",motion.moved_vertex_count,"; dirty vertex upload bytes=",frame_bytes)
		actor.free();peer.free()
	print("AVATAR ATTIRE QUALITY POSES: ",sampled_poses)
	print("AVATAR ATTIRE GPU READBACK POSES: ",gpu_poses)
	print("AVATAR ATTIRE QUALITY SMOKE: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
