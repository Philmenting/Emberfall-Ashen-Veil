extends "res://tests/source_avatar_grip_smoke.gd"
## Actual weighted anatomy/handle contact/string placement over the live class
## windup, release, recovery, zero-delta hold and death floor.
var grip_side:="r"
var source_radii: Dictionary={}
var maximum_class_gap:=0.0
var maximum_class_penetration:=0.0
var class_metrics: Dictionary={}
var production_release_metrics: Dictionary={}

func actual_arrow_tip(rig: RefCounted) -> Dictionary:
	# The arrow is a rigid original prop, not skinned anatomy. Use actual
	# indexed tip geometry and its node world transform, even while hidden.
	var tip: Dictionary={}
	var minimum_z=INF
	for part: MeshInstance3D in rig.bow_arrow.get_children():
		for slot in part.mesh.get_surface_count():
			var arrays=part.mesh.surface_get_arrays(slot)
			for index in arrays[Mesh.ARRAY_INDEX]:
				var point: Vector3=arrays[Mesh.ARRAY_VERTEX][index]
				var local=part.transform*point
				if local.z<minimum_z:
					minimum_z=local.z
					tip={"part":part,"point":point,"index":index}
	return tip

func audit_production_bow_release(style: String) -> void:
	var actor=Actor.new();actor.kind="Ranger"
	actor.position=Vector3(2.7,.13,-1.4);actor.rotation.y=.63
	root.add_child(actor)
	var rig=actor.motion_rig;var skeleton: Skeleton3D=rig.skeleton
	actor.strike(style,.40,true)
	# Match DungeonWorld's existing projectile launch boundary, rather than
	# calling the pose helper directly or advancing a second release tick.
	actor.sync_attack(actor.PROJECTILE_RELEASE_LEAD)
	actor.animate(0.0,false)
	check(actor.last_clip=="windup_"+("basic" if style=="basic" else "skill") and rig.last_clip_time==1.0 and rig.bow_arrow.visible,style+": real production actor reaches full nocked draw at projectile launch boundary")
	var before=rig._capture_source_pose()
	var indexed_tip=actual_arrow_tip(rig)
	check(not indexed_tip.is_empty(),style+": physical arrow tip comes from an actually indexed prop vertex")
	if indexed_tip.is_empty():actor.free();return
	var before_tip: Vector3=indexed_tip.part.to_global(indexed_tip.point)
	var released=actor.release_attack()
	check(released and actor.release_time==0.0 and not rig.bow_arrow.visible and actor.last_clip.begins_with("recover_"),style+": production release immediately hides the arrow before projectile_origin is read")
	var after=rig._capture_source_pose()
	var maximum_position=0.0;var maximum_rotation=0.0;var maximum_scale=0.0
	for bone in skeleton.get_bone_count():
		maximum_position=maxf(maximum_position,before.positions[bone].distance_to(after.positions[bone]))
		var rotation_delta: Quaternion=before.rotations[bone].inverse()*after.rotations[bone]
		# atan2 retains precision near zero; acos(dot) can report a spurious
		# milliradian jump from the original float32 quaternion rounding.
		var angle=2.0*atan2(Vector3(rotation_delta.x,rotation_delta.y,rotation_delta.z).length(),absf(rotation_delta.w))
		maximum_rotation=maxf(maximum_rotation,angle)
		maximum_scale=maxf(maximum_scale,before.scales[bone].distance_to(after.scales[bone]))
	check(maximum_position<.000001 and maximum_rotation<.0001 and maximum_scale<.000001,style+": all65 native bones remain continuous through real contact; position="+str(maximum_position)+" rotation="+str(maximum_rotation)+" scale="+str(maximum_scale))
	var hidden_tip: Vector3=indexed_tip.part.to_global(indexed_tip.point)
	var socket_error=hidden_tip.distance_to(actor.body.to_global(rig.weapon_tip()))
	var origin_error=hidden_tip.distance_to(actor.projectile_origin())
	var contact_jump=hidden_tip.distance_to(before_tip)
	check(socket_error<.0001,style+": actual indexed hidden arrow tip matches weapon_tip immediately after production release; error="+str(socket_error))
	check(origin_error<.0001,style+": actual indexed hidden arrow tip matches projectile_origin immediately after production release; error="+str(origin_error))
	check(contact_jump<.0001,style+": actual physical arrow tip remains continuous at release; jump="+str(contact_jump))
	production_release_metrics[style]={"native_bones":skeleton.get_bone_count(),"maximum_bone_position_jump_m":maximum_position,"maximum_bone_rotation_jump_rad":maximum_rotation,"maximum_bone_scale_jump":maximum_scale,"hidden_arrow_tip_socket_error_m":socket_error,"hidden_arrow_tip_projectile_origin_error_m":origin_error,"actual_arrow_tip_contact_jump_m":contact_jump}
	actor.free()

func digit_for(name: String) -> int:
	if name=="hand_"+grip_side:return 0
	if not name.ends_with("_"+grip_side):return -1
	return DIGITS.find(name.split("_")[0])

func actual_radius(rig: RefCounted) -> float:
	var origin=rig.weapon.transform*rig.class_grip
	var axis=(rig.weapon.basis*Vector3.UP).normalized()
	var radius=0.0
	var evaluated=0
	for part in rig.weapon.get_children():
		if not part is MeshInstance3D or not String(part.name).begins_with("Weapon__"):continue
		for slot in part.mesh.get_surface_count():
			var arrays=part.mesh.surface_get_arrays(slot);var vertices=arrays[Mesh.ARRAY_VERTEX];var indices=arrays[Mesh.ARRAY_INDEX]
			for offset in range(0,indices.size(),3):
				var polygon: Array[Vector3]=[]
				for corner in 3:polygon.append(rig.weapon.transform*(part.transform*vertices[indices[offset+corner]]))
				polygon=clip_axial_polygon(polygon,origin,axis,.035,true)
				polygon=clip_axial_polygon(polygon,origin,axis,-.035,false)
				for point in polygon:
					var delta=point-origin;radius=maxf(radius,(delta-axis*delta.dot(axis)).length());evaluated+=1
	check(evaluated>10 and radius>.012 and radius<.020,"Actual "+rig.key+" handle radius is physically fitted to native fingers: "+str(radius))
	return radius

func audit_class_grip(actor: Node3D,label: String) -> void:
	var rig=actor.motion_rig;var skeleton: Skeleton3D=rig.skeleton
	var hand=skeleton.get_bone_global_pose(skeleton.find_bone("hand_"+grip_side));var inverse=hand.affine_inverse()
	var origin=inverse*(rig.weapon.transform*rig.class_grip)
	var axis=(inverse.basis*(rig.weapon.basis*Vector3.UP)).normalized()
	var horizontal=axis.cross(Vector3.RIGHT).normalized();var vertical=axis.cross(horizontal).normalized()
	var minima: Array[float]=[INF,INF,INF,INF,INF,INF]
	var directions: Array[Vector3]=[Vector3.ZERO,Vector3.ZERO,Vector3.ZERO,Vector3.ZERO,Vector3.ZERO,Vector3.ZERO]
	var minimum=INF;var triangles_used=0
	for record in arm_surfaces:
		var vertices=PackedVector3Array();vertices.resize(record.probes.size())
		for index in record.used:
			var point=Vector3.ZERO
			for influence in record.probes[index]:point+=(skeleton.get_bone_global_pose(influence[0])*influence[1])*influence[2]
			vertices[index]=inverse*point
		var indices: PackedInt32Array=record.indices
		for offset in range(0,indices.size(),3):
			var polygon: Array[Vector3]=[]
			for corner in 3:polygon.append(vertices[indices[offset+corner]]-origin)
			polygon=clip_axial_polygon(polygon,Vector3.ZERO,axis,.045,true)
			polygon=clip_axial_polygon(polygon,Vector3.ZERO,axis,-.045,false)
			if polygon.size()<3:continue
			triangles_used+=1
			var closest=Vector2(INF,INF)
			for corner in range(1,polygon.size()-1):
				var a=polygon[0];var b=polygon[corner];var c=polygon[corner+1]
				var candidate=closest_projected_triangle(Vector2(a.dot(horizontal),a.dot(vertical)),Vector2(b.dot(horizontal),b.dot(vertical)),Vector2(c.dot(horizontal),c.dot(vertical)))
				if candidate.length_squared()<closest.length_squared():closest=candidate
			var distance=closest.length()
			if distance<minimum:
				minimum=distance
			var digit=record.triangle_digits[offset/3]
			if digit>=0 and distance<minima[digit]:
				minima[digit]=distance;directions[digit]=(horizontal*closest.x+vertical*closest.y).normalized()
	var radius=float(source_radii[rig.key]);var penetration=maxf(0.0,radius-minimum)
	maximum_class_penetration=maxf(maximum_class_penetration,penetration)
	check(triangles_used>100 and is_finite(minimum),label+": contact includes actually indexed weighted arm triangles")
	check(penetration<=.0015,label+": actual hand/handle penetration below1.5mm; "+str(penetration))
	check(minima[1]<=radius+.003,label+": actual thumb contacts actual handle within3mm; gap="+str(minima[1]-radius))
	var contacts=0;var opposed=0
	for digit in range(2,6):
		var gap=maxf(0.0,minima[digit]-radius);maximum_class_gap=maxf(maximum_class_gap,gap)
		if gap<=.003:
			contacts+=1
			if directions[1].dot(directions[digit])<-.4:opposed+=1
	check(contacts>=3 and opposed>=2,label+": at least3 real fingers wrap and oppose the thumb")
	if rig.key=="Ranger" and rig.bow_arrow.visible:
		var nock=rig.weapon.transform*(rig.bow_arrow.position+Vector3(0,0,.34))
		var hook=skeleton.get_bone_global_pose(skeleton.find_bone("hand_r"))*rig.class_pose_state.hook_local
		check(nock.distance_to(hook)<.0001,label+": actual rendered arrow/string follows right draw-hand hook below0.1mm")
		var pad=Vector3.ZERO
		for index in rig.bow_hook_probe.bones.size():pad+=(skeleton.get_bone_global_pose(rig.bow_hook_probe.bones[index])*rig.bow_hook_probe.binds[index]*rig.bow_hook_probe.point)*rig.bow_hook_probe.weights[index]
		check(absf(nock.distance_to(pad)-.0028)<.0001,label+": actual string radius touches a real indexed native finger pad below0.1mm")
		for string in rig.bow_strings:
			var point=rig.weapon.transform*(string.transform*Vector3(0,-.5,0))
			check(point.distance_to(hook)<.0001,label+": real string cylinder meets actual draw hand")
		var indexed_tip=actual_arrow_tip(rig)
		var physical_tip: Vector3=indexed_tip.part.to_global(indexed_tip.point)
		check(actor.body.to_global(rig.weapon_tip()).distance_to(physical_tip)<.0001,label+": actual projectile socket matches indexed rendered arrow tip during draw")
	poses+=1

func weighted_bounds(rig: RefCounted) -> AABB:
	var result=AABB();var first=true;var transforms: Array[Transform3D]=[]
	for bone in rig.skeleton.get_bone_count():transforms.append(rig.skeleton.get_bone_global_pose(bone))
	for record in rig.weighted_probes:
		var point=Vector3.ZERO
		for influence in record.bones.size():point+=(transforms[record.bones[influence]]*record.binds[influence]*record.point)*record.weights[influence]
		point=rig.motion_node.transform*point
		result=AABB(point,Vector3.ZERO) if first else result.expand(point);first=false
	return result

func actual_rendered_triangles(rig: RefCounted) -> int:
	var count=0
	for part in rig.motion_node.find_children("*","MeshInstance3D",true,false):
		if not part.is_visible_in_tree():continue
		if part.mesh is ArrayMesh:
			for slot in part.mesh.get_surface_count():count+=part.mesh.surface_get_arrays(slot)[Mesh.ARRAY_INDEX].size()/3
		elif part.mesh is PrimitiveMesh:count+=part.mesh.get_mesh_arrays()[Mesh.ARRAY_INDEX].size()/3
	return count

func run() -> void:
	for class_key in ["Vowkeeper","Ranger"]:
		var actor=Actor.new();actor.kind=class_key;root.add_child(actor)
		var rig=actor.motion_rig
		check(actor.source_avatar and rig.skeleton.get_bone_count()==65,class_key+": ordinary production actor retains complete original native65 anatomy")
		check(rig.motion_node.find_children("*","Skeleton3D",true,false).size()==1,class_key+": head/outfit/armor bind to one running source skeleton")
		check(rig.player.has_animation("Walk_Loop") and rig.player.has_animation("Death01"),class_key+": source artist walking and death remain real native animations")
		if class_key=="Vowkeeper":
			var plate=rig.motion_node.find_child("Vowkeeper055_Breastplate",true,false) as MeshInstance3D
			check(rig.style.accessories.size()==3 and plate!=null,"Vowkeeper: continuous breastplate and two real outer armor mesh groups are actually present")
			if plate!=null:
				var data=plate.mesh.surface_get_arrays(0);var clockwise=true
				for offset in range(0,data[Mesh.ARRAY_INDEX].size(),3):
					var a=data[Mesh.ARRAY_INDEX][offset];var b=data[Mesh.ARRAY_INDEX][offset+1];var c=data[Mesh.ARRAY_INDEX][offset+2]
					var normal=(data[Mesh.ARRAY_VERTEX][b]-data[Mesh.ARRAY_VERTEX][a]).cross(data[Mesh.ARRAY_VERTEX][c]-data[Mesh.ARRAY_VERTEX][a])
					clockwise=clockwise and normal.dot(data[Mesh.ARRAY_NORMAL][a])<0.0
				check(clockwise,"Actual breastplate uses renderer clockwise front faces with true outward normals")
		check(rig.player.has_animation("Sword_Regular_A") and rig.player.has_animation("Sword_Regular_B") and rig.player.has_animation("Sword_Regular_C"),class_key+": genuine rest-relative source sword animations imported")
		var actual=actual_rendered_triangles(rig)
		class_metrics[class_key]={"native_bones":65,"source_triangles":rig.triangles,"maximum_rendered_triangles":rig.rendered_triangles,"actually_visible_guard_triangles":actual,"actual_source_surfaces":rig.surfaces.size(),"armor_surfaces":rig.style.accessories.size()}
		check(actual<=40000 and rig.rendered_triangles<=40000,class_key+": full actually visible outfit/head/armor/weapon stays within40k; actual="+str(actual)+" recorded="+str(rig.rendered_triangles))
		check(actor.portrait_anchor().y>1.6 and actor.portrait_anchor().y<2.2,class_key+": actual production head remains readable at original adult height; y="+str(actor.portrait_anchor().y))
		grip_side="l" if class_key=="Ranger" else "r"
		cache_actual_arm(rig)
		var arm_index=0
		for surface in rig.surfaces:
			if not String(surface.name).contains("Arms"):continue
			for slot in surface.mesh.get_surface_count():arm_surfaces[arm_index].name=String(surface.name);arm_index+=1
		source_radii[class_key]=actual_radius(rig)
		class_metrics[class_key].measured_handle_maximum_radius_m=source_radii[class_key]
		if class_key=="Ranger":class_metrics[class_key].actual_arrow_rest_height_m=rig.bow_rest_height
		var release_hands=[]
		for action in ["basic","skill","heavy"]:
			for phase in [0.0,.25,.50,.75,1.0]:
				rig.pose("windup_"+action,phase);rig.apply_actor_postprocess(actor,"windup_"+action,phase,0.0,true)
				audit_class_grip(actor,class_key+" windup_"+action+" "+str(phase))
				audit_anatomy(rig,class_key+" "+action)
				release_hands.append(rig.weapon_tip())
			for phase in [0.0,.14,.34]:
				rig.pose("recover_"+action,phase);rig.apply_actor_postprocess(actor,"recover_"+action,phase,0.0,true)
				audit_class_grip(actor,class_key+" recover_"+action+" "+str(phase))
				audit_anatomy(rig,class_key+" "+action+" recovery")
			# Exact repeated source phase includes cached pose, restored digits,
			# bow solves and actual actor postprocessing, without accumulating.
			rig.pose("windup_"+action,.67);rig.apply_actor_postprocess(actor,"windup_"+action,.67,0.0,true)
			var frozen=rig._capture_source_pose();var weapon_frozen=rig.weapon.transform
			for repeat in 8:
				rig.pose("windup_"+action,.67);rig.apply_actor_postprocess(actor,"windup_"+action,.67,0.0,true)
			check(rig._capture_source_pose()==frozen and rig.weapon.transform==weapon_frozen,class_key+" "+action+": repeated held phase is exactly stable on all65nativebones and actual prop")
		if class_key=="Vowkeeper":
			for technique in ["sunder","judgment"]:
				actor.attack_time=-1.0;actor.release_time=-1.0
				actor.strike(technique,.50,true)
				actor.animate(0.0,false)
				check(actor.last_clip=="windup_heavy" and rig.last_sample=="Sword_Regular_C",technique+": real production actor uses genuine heavy sword phrase")
			actor.attack_time=-1.0;actor.release_time=-1.0
		for phase in [0.0,.18,.36,.54,.72,.90]:
			rig.pose("death",phase);rig.apply_actor_postprocess(actor,"death",phase,0.0,true)
			var box=weighted_bounds(rig)
			check(box.position.y>=-.001 and box.size.y<2.5,class_key+": actual weighted complete body and armor clear the floor through death; min="+str(box.position.y))
			check(rig.bounds.grow(.0002).encloses(box),class_key+": actual weighted death geometry remains inside native actor bounds")
		actor.attack_time=-1.0;actor.release_time=-1.0
		actor.clock=.40;actor.last_clip="idle";actor.blend_age=1.0;actor.blend_pose.clear()
		actor.animate(0.0,false)
		var location=actor.transform
		var pelvis=rig.skeleton.find_bone("pelvis")
		var pelvis_pose=rig.skeleton.get_bone_pose(pelvis)
		var chest=rig.skeleton.find_bone("spine_03")
		var clean_chest=rig.skeleton.get_bone_global_pose(chest).basis
		actor.react(1.0,1.0);actor.impact_time=actor.recoil_duration*.16
		actor.animate(0.0,false)
		check(not rig.skeleton.get_bone_global_pose(chest).basis.is_equal_approx(clean_chest),class_key+": actual hurt event articulates native shoulder compression")
		check(actor.transform==location and rig.skeleton.get_bone_pose(pelvis)==pelvis_pose,class_key+": actual recoil leaves actor position and pelvis stable")
		audit_class_grip(actor,class_key+" real hurt")
		var hurt=rig._capture_source_pose()
		for repeat in 8:actor.animate(0.0,false)
		check(rig._capture_source_pose()==hurt,class_key+": held actual recoil never accumulates")
		actor.impact_time=-1.0;actor.animate(0.0,false)
		actor.free()
	for style in ["basic","signature"]:audit_production_bow_release(style)
	print("CLASS ACTUAL GRIP: max gap=",maximum_class_gap," max penetration=",maximum_class_penetration,"; poses=",poses)
	print("CLASS NATIVE INVENTORY: ",JSON.stringify(class_metrics))
	print("CLASS PRODUCTION RELEASE: ",JSON.stringify(production_release_metrics))
	print("CLASS AVATAR QUALITY SMOKE: %d checks, %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func audit_anatomy(rig: RefCounted,label: String) -> void:
	var valid=true
	for bone in rig.skeleton.get_bone_count():
		var name=String(rig.skeleton.get_bone_name(bone))
		var pose=rig.skeleton.get_bone_pose(bone)
		valid=valid and pose.origin.is_finite() and pose.basis.is_finite() and pose.basis.get_scale().distance_to(Vector3.ONE)<.0001
		if name not in ["root","pelvis"]:valid=valid and pose.origin.distance_to(rig.skeleton.get_bone_rest(bone).origin)<.0001
	check(valid,label+": every true native limb length/scale remains original and finite")
