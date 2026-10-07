extends "res://tests/source_avatar_grip_smoke.gd"
## Test real indexed weighted male hands and original head/garment surfaces,
## production release continuity, real authored Hit_Chest overlay and death floor.
const RaiderRig=preload("res://scripts/raider_avatar_rig.gd")
var actual_thumb_gap:=0.0

func actual_shaft_triangles(rig: RefCounted,hand_inverse: Transform3D,origin: Vector3,axis: Vector3) -> Array:
	var triangles: Array=[]
	for part: MeshInstance3D in rig.weapon.get_children():
		if not String(part.name).contains("Wood"):continue
		for slot in part.mesh.get_surface_count():
			var arrays=part.mesh.surface_get_arrays(slot)
			for offset in range(0,arrays[Mesh.ARRAY_INDEX].size(),3):
				var polygon: Array[Vector3]=[]
				for corner in 3:polygon.append(hand_inverse*(rig.weapon.transform*(part.transform*arrays[Mesh.ARRAY_VERTEX][arrays[Mesh.ARRAY_INDEX][offset+corner]]))-origin)
				polygon=clip_axial_polygon(polygon,Vector3.ZERO,axis,AXIAL_BAND,true)
				polygon=clip_axial_polygon(polygon,Vector3.ZERO,axis,-AXIAL_BAND,false)
				for corner in range(1,polygon.size()-1):
					var a=polygon[0];var b=polygon[corner];var c=polygon[corner+1]
					if (b-a).cross(c-a).length_squared()<1e-16:continue
					triangles.append({"points":[a,b,c],"bounds":AABB(a,Vector3.ZERO).expand(b).expand(c)})
	return triangles

func closest_on_triangle(point: Vector3,a: Vector3,b: Vector3,c: Vector3) -> Vector3:
	var ab=b-a;var ac=c-a;var ap=point-a
	if ab.cross(ac).length_squared()<1e-16:
		var best=a;var distance=INF
		for edge in [[a,b],[b,c],[c,a]]:
			var candidate=Geometry3D.get_closest_point_to_segment(point,edge[0],edge[1])
			if point.distance_squared_to(candidate)<distance:best=candidate;distance=point.distance_squared_to(candidate)
		return best
	var d1=ab.dot(ap);var d2=ac.dot(ap)
	if d1<=0 and d2<=0:return a
	var bp=point-b;var d3=ab.dot(bp);var d4=ac.dot(bp)
	if d3>=0 and d4<=d3:return b
	var vc=d1*d4-d3*d2
	if vc<=0 and d1>=0 and d3<=0:return a+ab*(d1/(d1-d3))
	var cp=point-c;var d5=ab.dot(cp);var d6=ac.dot(cp)
	if d6>=0 and d5<=d6:return c
	var vb=d5*d2-d1*d6
	if vb<=0 and d2>=0 and d6<=0:return a+ac*(d2/(d2-d6))
	var va=d3*d6-d5*d4
	if va<=0 and d4-d3>=0 and d5-d6>=0:return b+(c-b)*((d4-d3)/((d4-d3)+(d5-d6)))
	var inverse=1.0/(va+vb+vc)
	return a+ab*(vb*inverse)+ac*(vc*inverse)

func triangle_contact_patch(skin: Array,wood: Array) -> Dictionary:
	var best_distance:=INF;var best_skin:=Vector3.ZERO
	for point: Vector3 in skin:
		var nearest=closest_on_triangle(point,wood[0],wood[1],wood[2]);var distance=point.distance_to(nearest)
		if distance<best_distance:best_distance=distance;best_skin=point
	for point: Vector3 in wood:
		var nearest=closest_on_triangle(point,skin[0],skin[1],skin[2]);var distance=point.distance_to(nearest)
		if distance<best_distance:best_distance=distance;best_skin=nearest
	for a in 3:
		var intersection=Geometry3D.segment_intersects_triangle(skin[a],skin[(a+1)%3],wood[0],wood[1],wood[2])
		if intersection!=null:return {"distance":0.0,"point":intersection}
		intersection=Geometry3D.segment_intersects_triangle(wood[a],wood[(a+1)%3],skin[0],skin[1],skin[2])
		if intersection!=null:return {"distance":0.0,"point":intersection}
		for b in 3:
			var nearest=Geometry3D.get_closest_points_between_segments(skin[a],skin[(a+1)%3],wood[b],wood[(b+1)%3]);var distance=nearest[0].distance_to(nearest[1])
			if distance<best_distance:best_distance=distance;best_skin=nearest[0]
	return {"distance":best_distance,"point":best_skin}

func actual_contact_patch(skin: Array[Vector3],shaft: Array) -> Dictionary:
	var best={"distance":INF,"point":Vector3.ZERO}
	for corner in range(1,skin.size()-1):
		var triangle=[skin[0],skin[corner],skin[corner+1]]
		var bounds=AABB(triangle[0],Vector3.ZERO).expand(triangle[1]).expand(triangle[2]).grow(CONTACT_GAP)
		for wood in shaft:
			if not bounds.intersects(wood.bounds):continue
			var candidate=triangle_contact_patch(triangle,wood.points)
			if candidate.distance<best.distance:best=candidate
	return best

func audit_pose(actor: Node3D, label: String) -> void:
	poses += 1
	var rig = actor.motion_rig
	var skeleton: Skeleton3D = rig.skeleton
	var hand = skeleton.get_bone_global_pose(skeleton.find_bone("hand_r"))
	var hand_inverse = hand.affine_inverse()
	var origin: Vector3 = hand_inverse * (rig.weapon.transform * RaiderRig.AXE_GRIP)
	var axis: Vector3 = (hand_inverse.basis * (rig.weapon.basis * Vector3.UP)).normalized()
	var world_axis: Vector3 = (actor.body.global_basis * rig.motion_node.basis * rig.weapon.basis * Vector3.UP).normalized()
	check(world_axis.is_finite() and absf(world_axis.length()-1.0)<.001, label + ": actual axe axis follows native swinging wrist")
	# A socket/contact minimum alone can pass with an open distal finger.
	# Every actual native distal joint and fingertip must wrap the shaft too.
	for digit in ["index","middle","ring","pinky"]:
		for suffix in ["_03_r","_04_leaf_r"]:
			var point: Vector3=hand_inverse*rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone(digit+suffix)).origin-origin
			var axial=point.dot(axis);var radial=(point-axis*axial).length()
			check(radial<=.035 and absf(axial)<=.070,label+": native distal "+digit+suffix+" actually wraps handle; radial="+str(radial))
	var horizontal = axis.cross(Vector3.RIGHT).normalized()
	var vertical = axis.cross(horizontal).normalized()
	var shaft=actual_shaft_triangles(rig,hand_inverse,origin,axis)
	check(shaft.size()>16,label+": contact uses actual indexed wooden triangles in the complete ±55mm hand band")
	var actual_gaps: Array[float] = [INF, INF, INF, INF, INF, INF]
	var actual_directions: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
	var minima: Array[float] = [INF, INF, INF, INF, INF, INF]
	var directions: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
	var contact_directions: Array = [[], [], [], [], [], []]
	var all_arm_minimum = INF
	var considered_triangles = 0
	for record in arm_surfaces:
		var vertices = PackedVector3Array()
		vertices.resize(record.probes.size())
		for index in record.used:
			var point = Vector3.ZERO
			for influence in record.probes[index]:
				point += (skeleton.get_bone_global_pose(influence[0]) * influence[1]) * influence[2]
			assert(point.is_finite(), "Actually weighted grip geometry remains finite")
			vertices[index] = hand_inverse * point
		var indices: PackedInt32Array = record.indices
		for offset in range(0, indices.size(), 3):
			var a = vertices[indices[offset]] - origin
			var b = vertices[indices[offset + 1]] - origin
			var c = vertices[indices[offset + 2]] - origin
			var axial_a = a.dot(axis)
			var axial_b = b.dot(axis)
			var axial_c = c.dot(axis)
			if minf(axial_a, minf(axial_b, axial_c)) > AXIAL_BAND or maxf(axial_a, maxf(axial_b, axial_c)) < -AXIAL_BAND:
				continue
			var polygon: Array[Vector3] = [a, b, c]
			polygon = clip_axial_polygon(polygon, Vector3.ZERO, axis, AXIAL_BAND, true)
			polygon = clip_axial_polygon(polygon, Vector3.ZERO, axis, -AXIAL_BAND, false)
			if polygon.size() < 3:
				continue
			considered_triangles += 1
			var closest = Vector2(INF, INF)
			for corner in range(1, polygon.size() - 1):
				var first = polygon[0]
				var second = polygon[corner]
				var third = polygon[corner + 1]
				var candidate = closest_projected_triangle(Vector2(first.dot(horizontal), first.dot(vertical)), Vector2(second.dot(horizontal), second.dot(vertical)), Vector2(third.dot(horizontal), third.dot(vertical)))
				if candidate.length_squared() < closest.length_squared():
					closest = candidate
			var distance = closest.length()
			# Every arm triangle contributes to clearance, including mixed-bind
			# triangles that cannot be assigned to one dominant digit.
			all_arm_minimum = minf(all_arm_minimum, distance)
			var digit: int = record.triangle_digits[offset / 3]
			if digit>=0 and distance<=RaiderRig.AXE_RADIUS+CONTACT_GAP:
				var actual=actual_contact_patch(polygon,shaft)
				var actual_direction=(actual.point-axis*actual.point.dot(axis)).normalized()
				if actual.distance<actual_gaps[digit]:
					actual_gaps[digit]=actual.distance;actual_directions[digit]=actual_direction
				if actual.distance<=CONTACT_GAP:contact_directions[digit].append(actual_direction)
			if digit >= 0 and distance < minima[digit]:
				minima[digit] = distance
				directions[digit] = (horizontal * closest.x + vertical * closest.y).normalized()
	var penetration = maxf(0.0, RaiderRig.AXE_RADIUS - all_arm_minimum)
	worst_penetration = maxf(worst_penetration, penetration)
	check(considered_triangles > 100 and is_finite(all_arm_minimum), label + ": clearance uses actual indexed arm triangles")
	check(penetration <= MAX_PENETRATION, label + ": whole arm avoids shaft penetration beyond 1 mm; measured " + str(penetration))
	actual_thumb_gap=maxf(actual_thumb_gap,actual_gaps[1])
	check(is_finite(actual_gaps[1]) and actual_gaps[1]<=CONTACT_GAP,label+": actual thumb skin touches real shaft facets within 3 mm; gap "+str(actual_gaps[1]))
	var finger_contacts = 0
	var opposed_contacts = 0
	for digit in range(2,6):
		var gap=actual_gaps[digit]
		widest_finger_gap=maxf(widest_finger_gap,gap)
		if is_finite(gap) and gap<=CONTACT_GAP:finger_contacts+=1
	# One real touching thumb patch must oppose three distinct real touching
	# fingers. Search all actual patches, rather than selecting one minimum.
	for thumb_direction: Vector3 in contact_directions[1]:
		var witness_contacts=0
		for digit in range(2,6):
			for contact_direction: Vector3 in contact_directions[digit]:
				if thumb_direction.dot(contact_direction)<-.5:
					witness_contacts+=1
					break
		opposed_contacts=maxi(opposed_contacts,witness_contacts)
	check(finger_contacts >= 3, label + ": at least three actual fingers contact the handle within 3 mm")
	check(opposed_contacts >= 3, label + ": thumb opposes at least three finger contacts around the shaft")
	check(is_finite(minima[0]) and minima[0] >= RaiderRig.AXE_RADIUS - MAX_PENETRATION and minima[0] <= RaiderRig.AXE_RADIUS + .014, label + ": palm stays clear and within 14 mm of the supported shaft")


func make_raider() -> Node3D:
	var actor=Actor.new();actor.kind="raider";actor.hostile=true
	root.add_child(actor)
	check(actor.source_avatar and actor.motion_rig is RaiderRig,"Production ordinary Raider uses authored native65 rig")
	check(actor.motion_rig.skeleton.get_bone_count()==65,"Original65 bone hierarchy survives import")
	cache_actual_arm(actor.motion_rig)
	return actor

func audit_axe_mesh(rig: RefCounted) -> void:
	var origin: Vector3=rig.weapon.transform*RaiderRig.AXE_GRIP
	var axis: Vector3=(rig.weapon.basis*Vector3.UP).normalized()
	var low=INF;var high=0.0;var count=0
	for part: MeshInstance3D in rig.weapon.get_children():
		for slot in part.mesh.get_surface_count():
			var arrays=part.mesh.surface_get_arrays(slot)
			for offset in range(0,arrays[Mesh.ARRAY_INDEX].size(),3):
				var polygon: Array[Vector3]=[]
				for corner in 3:polygon.append(rig.weapon.transform*(part.transform*arrays[Mesh.ARRAY_VERTEX][arrays[Mesh.ARRAY_INDEX][offset+corner]]))
				polygon=clip_axial_polygon(polygon,origin,axis,AXIAL_BAND,true)
				polygon=clip_axial_polygon(polygon,origin,axis,-AXIAL_BAND,false)
				for point in polygon:
					var delta=point-origin;var radius=(delta-axis*delta.dot(axis)).length()
					low=minf(low,radius);high=maxf(high,radius);count+=1
	check(count>=24 and low>=.0155 and high<=.0185,"Rendered indexed original faceted axe grip fits actual18mm circumradius male finger aperture; radii "+str(low)+" / "+str(high))
	check(is_equal_approx(rig.weapon.basis.get_scale().y,RaiderRig.AXE_SCALE),"Axe retains intended authored longitudinal scale")
	var actual_count=0
	for surface: MeshInstance3D in rig.surfaces+rig.weapon.get_children():
		for slot in surface.mesh.get_surface_count():actual_count+=surface.mesh.surface_get_arrays(slot)[Mesh.ARRAY_INDEX].size()/3
	check(actual_count==rig.rendered_triangles and actual_count<=20000,"All visible original surfaces including axe measured honestly below20k; "+str(actual_count))
	check(rig.source_height>1.7 and rig.source_height<2.2,"Actual original body height excludes the extended axe")

func audit_axe_readability(rig: RefCounted) -> void:
	var originals: Array=[]
	for part: MeshInstance3D in rig.weapon.get_children():
		for slot in part.mesh.get_surface_count():
			var material=part.get_active_material(slot) as StandardMaterial3D
			originals.append({"material":material,"albedo":material.albedo_color,"roughness":material.roughness})
	rig.set_visual_readability(0.0,0.0)
	for original in originals:
		var material: StandardMaterial3D=original.material
		var expected: Color=original.albedo*.4;expected.a=original.albedo.a
		check(material.albedo_color.is_equal_approx(expected) and material.roughness==original.roughness,"Defeated readability lowers actual original axe PBR surface while preserving alpha/roughness")
	rig.set_visual_readability(1.0,0.0)
	for original in originals:check(original.material.albedo_color.is_equal_approx(original.albedo),"Living readability restores original axe material without compounded tint")

func run() -> void:
	var actor=make_raider();var rig=actor.motion_rig
	var labels=[]
	for surface in rig.surfaces:
		labels.append(String(surface.name))
		check(surface.skin!=null and surface.layers==2,"Original part keeps native skin and actor light layer: "+String(surface.name))
		for slot in surface.mesh.get_surface_count():
			var material=surface.get_active_material(slot) as StandardMaterial3D
			check(material!=null and material.albedo_texture!=null and material.normal_texture!=null,"Original indexed surface retains artist color/normal maps: "+String(surface.name))
	for name in ["Raider_Authored_Head","Eyes","Eyebrows","Hair_Beard","Male_Peasant_Body","Male_Peasant_Arms","Male_Peasant_Feet","Male_Peasant_Legs"]:
		check(name in labels,"Complete original anatomy/clothing includes "+name)
	for name in ["Sword_Regular_A","Sword_Idle","Hit_Chest","Death01","Walk_Loop"]:check(rig.player.has_animation(name),"Original authored phrase imported: "+name)
	audit_axe_mesh(rig)
	audit_axe_readability(rig)
	for phase in [["idle",0.0],["idle",.5],["walk",.0],["walk",.25],["walk",.50],["walk",.75],["windup_jab",.0],["windup_jab",.25],["windup_jab",.65],["windup_jab",1.0],["recover_jab",.0],["recover_jab",.08],["recover_jab",.17],["recover_jab",.30]]:
		rig.pose(phase[0],phase[1]);rig.apply_actor_postprocess(actor,phase[0],phase[1],0.0,true)
		audit_pose(actor,"Native "+phase[0]+" "+str(phase[1]))
		var original=rig.capture_pose();rig.pose(phase[0],phase[1]);rig.apply_actor_postprocess(actor,phase[0],phase[1],0.0,true)
		var repeated=rig.capture_pose();var drift=0.0
		for bone in original.size():drift=maxf(drift,original[bone].origin.distance_to(repeated[bone].origin))
		check(drift<.000001,"Repeated zero-delta native pose never compounds anatomical translation")
	rig.pose("windup_jab",1.0);var before=rig._capture_source_pose();var tip=actor.weapon_world_position()
	rig.pose("recover_jab",0.0);var after=rig._capture_source_pose();var rotation=0.0;var position=0.0
	for bone in 65:
		position=maxf(position,before.positions[bone].distance_to(after.positions[bone]));var q: Quaternion=before.rotations[bone].inverse()*after.rotations[bone];rotation=maxf(rotation,2.0*atan2(Vector3(q.x,q.y,q.z).length(),absf(q.w)))
	check(position<.000001 and rotation<.0001,"All native bones remain continuous at real windup/recovery boundary")
	check(tip.distance_to(actor.weapon_world_position())<.0001,"Actual indexed axe tip remains continuous at release")
	actor.strike("basic",.28,true);actor.sync_attack(0.0);actor.animate(0.0,false)
	var release_before=actor.weapon_world_position();check(actor.release_attack(),"Production Raider releases from actual simulation trigger")
	check(release_before.distance_to(actor.weapon_world_position())<.0001,"Production release preserves actual indexed axe contact point")
	actor.cancel_attack();actor.attack_time=-1.0;actor.release_time=-1.0;actor.animate(.4,false)
	var actor_position=actor.position;var chest=rig.skeleton.get_bone_pose_rotation(rig.skeleton.find_bone("spine_03"));actor.react(1.0,1.2);actor.animate(.04,false)
	var hit_chest=rig.skeleton.get_bone_pose_rotation(rig.skeleton.find_bone("spine_03"));check(chest.angle_to(hit_chest)>.005,"Actual damage visibly applies authored Hit_Chest chest reaction")
	check(actor.position==actor_position,"Native hit reaction leaves authoritative actor position untouched")
	audit_pose(actor,"Production authored Hit_Chest overlay")
	actor.die();actor.animate(.90,false)
	var minimum=INF
	for surface in rig.surfaces:
		for slot in surface.mesh.get_surface_count():
			var arrays=surface.mesh.surface_get_arrays(slot);var used={}
			for index in arrays[Mesh.ARRAY_INDEX]:used[index]=true
			for index in used:
				var point=Vector3.ZERO
				for influence in 4:
					var weight=float(arrays[Mesh.ARRAY_WEIGHTS][index*4+influence]);if weight<=0.0:continue
					var bind=arrays[Mesh.ARRAY_BONES][index*4+influence];var name=surface.skin.get_bind_name(bind);var bone=rig.skeleton.find_bone(name) if name!=&"" else surface.skin.get_bind_bone(bind)
					point+=(rig.skeleton.get_bone_global_pose(bone)*surface.skin.get_bind_pose(bind)*arrays[Mesh.ARRAY_VERTEX][index])*weight
				minimum=minf(minimum,(rig.motion_node.transform*point).y)
	check(minimum>=-.001 and minimum<.035,"Actual indexed weighted original death anatomy rests on real floor; minimum "+str(minimum))
	var axe_minimum=INF
	for point in rig.weapon_points:axe_minimum=minf(axe_minimum,(rig.motion_node.transform*(rig.weapon.transform*point)).y)
	check(axe_minimum>=.0029,"Settled rigid axe indexed surface stays above floor")
	actor.free()
	for iteration in 3:
		actor=make_raider();actor.free()
	print("RAIDER_NATIVE_SMOKE checks=",checks," failures=",failures.size()," poses=",poses," max_finger_gap_m=",widest_finger_gap," max_penetration_m=",worst_penetration," max_actual_thumb_gap_m=",actual_thumb_gap)
	print("RAIDER NATIVE SMOKE: ",checks," checks, ",failures.size()," failures")
	for failure in failures:print("FAIL ",failure)
	quit(0 if failures.is_empty() else 1)
