extends "res://tests/raider_native_smoke.gd"
## Reuse the strict actual indexed male-hand audit for every real role prop.
## Contact3mm / penetration1mm / three opposed fingers remain unchanged.
const NativeHostile=preload("res://scripts/native_hostile_rig.gd")
const HostileSkin=preload("res://tests/source_avatar_skin.gd")
var shaft_grid: Dictionary={}
const CONTACT_CELL:=.012
var closest_breastplate_clearance:=INF

func weighted_surface_points(rig: RefCounted,surface: MeshInstance3D,frame: Transform3D) -> Dictionary:
	var arrays=surface.mesh.surface_get_arrays(0)
	var transforms: Array[Transform3D]=[]
	for bind in surface.skin.get_bind_count():
		var name=surface.skin.get_bind_name(bind)
		var bone=rig.skeleton.find_bone(name) if name!=&"" else surface.skin.get_bind_bone(bind)
		assert(bone>=0)
		transforms.append(frame*rig.skeleton.get_bone_global_pose(bone)*surface.skin.get_bind_pose(bind))
	var result=PackedVector3Array();result.resize(arrays[Mesh.ARRAY_VERTEX].size())
	var referenced: Dictionary={}
	for index in arrays[Mesh.ARRAY_INDEX]:referenced[index]=true
	for index in referenced:
		var point=Vector3.ZERO
		for influence in 4:
			var weight=arrays[Mesh.ARRAY_WEIGHTS][index*4+influence]
			if weight>0:point+=(transforms[arrays[Mesh.ARRAY_BONES][index*4+influence]]*arrays[Mesh.ARRAY_VERTEX][index])*weight
		result[index]=point
	return {"source":arrays[Mesh.ARRAY_VERTEX],"points":result,"indices":arrays[Mesh.ARRAY_INDEX],"referenced":referenced}

func audit_breastplate_clearance(actor: Node3D,label: String) -> void:
	var rig=actor.motion_rig;var plate: MeshInstance3D
	for surface: MeshInstance3D in rig.surfaces:
		if String(surface.name).ends_with("FittedBreastplate"):plate=surface;break
	if plate==null:return
	# Compare actual weighted garment and plate triangles in the moving
	# chest's original coordinate frame. Original front cloth and separate
	# raised belt/lacing are included; guessed socket/AABB gaps cannot pass.
	var chest=rig.skeleton.find_bone("spine_02")
	var frame=rig.skeleton.get_bone_global_rest(chest)*rig.skeleton.get_bone_global_pose(chest).affine_inverse()
	var shell=weighted_surface_points(rig,plate,frame);var measured=0;var minimum=INF
	for surface: MeshInstance3D in rig.surfaces:
		if String(surface.name) not in ["Male_Ranger_Body","Male_Ranger_Body_Belt_1"]:continue
		var garment=weighted_surface_points(rig,surface,frame)
		for vertex in garment.referenced:
			var source: Vector3=garment.source[vertex]
			if source.z<.035 or absf(source.x)>.085 or source.y<1.17 or source.y>1.40:continue
			var point: Vector3=garment.points[vertex]
			for offset in range(0,shell.indices.size(),3):
				var a: Vector3=shell.points[shell.indices[offset]];var b: Vector3=shell.points[shell.indices[offset+1]];var c: Vector3=shell.points[shell.indices[offset+2]]
				var aa=Vector2(a.x,a.y);var bb=Vector2(b.x,b.y);var cc=Vector2(c.x,c.y);var pp=Vector2(point.x,point.y)
				var denominator=(bb-aa).cross(cc-aa)
				if absf(denominator)<1e-10:continue
				var second=(pp-aa).cross(cc-aa)/denominator;var third=(bb-aa).cross(pp-aa)/denominator
				var first=1.0-second-third
				if minf(first,minf(second,third))<-.00001:continue
				minimum=minf(minimum,a.z*first+b.z*second+c.z*third-point.z);measured+=1;break
	closest_breastplate_clearance=minf(closest_breastplate_clearance,minimum)
	check(measured>=20 and minimum>=.003,label+": actual weighted breastplate clears original tunic and raised belt by3mm; min="+str(minimum)+" vertices="+str(measured))

func actual_shaft_triangles(rig: RefCounted,hand_inverse: Transform3D,origin: Vector3,axis: Vector3) -> Array:
	var triangles: Array=[]
	shaft_grid.clear()
	for part: MeshInstance3D in rig.weapon.get_children():
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
	for index in triangles.size():
		var bounds: AABB=triangles[index].bounds
		var low=Vector3i(floori(bounds.position.x/CONTACT_CELL),floori(bounds.position.y/CONTACT_CELL),floori(bounds.position.z/CONTACT_CELL))
		var high=Vector3i(floori(bounds.end.x/CONTACT_CELL),floori(bounds.end.y/CONTACT_CELL),floori(bounds.end.z/CONTACT_CELL))
		for x in range(low.x,high.x+1):
			for y in range(low.y,high.y+1):
				for z in range(low.z,high.z+1):
					var cell=Vector3i(x,y,z)
					if not shaft_grid.has(cell):shaft_grid[cell]=[]
					shaft_grid[cell].append(index)
	return triangles

func actual_contact_patch(skin: Array[Vector3],shaft: Array) -> Dictionary:
	# Exact triangle-to-triangle contacts are unchanged. Spatial bins only
	# discard prop faces outside the actual skin triangle's3mm AABB; dense
	# inherited staff ornaments must not make the strict contact audit quadratic.
	var best={"distance":INF,"point":Vector3.ZERO}
	for corner in range(1,skin.size()-1):
		var triangle=[skin[0],skin[corner],skin[corner+1]]
		var bounds=AABB(triangle[0],Vector3.ZERO).expand(triangle[1]).expand(triangle[2]).grow(CONTACT_GAP)
		var low=Vector3i(floori(bounds.position.x/CONTACT_CELL),floori(bounds.position.y/CONTACT_CELL),floori(bounds.position.z/CONTACT_CELL))
		var high=Vector3i(floori(bounds.end.x/CONTACT_CELL),floori(bounds.end.y/CONTACT_CELL),floori(bounds.end.z/CONTACT_CELL))
		var candidates: Dictionary={}
		for x in range(low.x,high.x+1):
			for y in range(low.y,high.y+1):
				for z in range(low.z,high.z+1):
					for index in shaft_grid.get(Vector3i(x,y,z),[]):candidates[index]=true
		for index in candidates:
			var prop=shaft[index]
			if not bounds.intersects(prop.bounds):continue
			var candidate=triangle_contact_patch(triangle,prop.points)
			if candidate.distance<best.distance:best=candidate
	return best

func native_actor(role: String) -> Node3D:
	var actor=Actor.new();actor.hostile=true;actor.boss=role.begins_with("guardian_")
	actor.kind="boss" if actor.boss else role
	if actor.boss:actor.region_index=int(role.right(1))
	root.add_child(actor)
	check(actor.source_avatar and actor.motion_rig is NativeHostile,"Production role uses complete native65 rig: "+role)
	check(actor.motion_rig.skeleton.get_bone_count()==65,"Original65 bone hierarchy and native bind ABI: "+role)
	cache_actual_arm(actor.motion_rig)
	return actor

func pose_distance(before: Dictionary,after: Dictionary) -> float:
	var error=0.0
	for bone in before.rotations.size():
		error=maxf(error,before.positions[bone].distance_to(after.positions[bone]))
		var q: Quaternion=before.rotations[bone].inverse()*after.rotations[bone]
		error=maxf(error,2.0*atan2(Vector3(q.x,q.y,q.z).length(),absf(q.w)))
	return error

func audit_material_phases(actor: Node3D) -> void:
	var rig=actor.motion_rig;var original: Array=[]
	var peer=Actor.new();peer.hostile=true;peer.boss=actor.boss;peer.kind=actor.kind;peer.region_index=actor.region_index;root.add_child(peer)
	var peer_materials: Array=[]
	for surface: MeshInstance3D in peer.motion_rig.surfaces+peer.motion_rig.weapon.get_children():
		for slot in surface.mesh.get_surface_count():
			var material=surface.get_active_material(slot) as StandardMaterial3D
			peer_materials.append([material,material.albedo_color,material.roughness,material.emission_energy_multiplier])
	for surface: MeshInstance3D in rig.surfaces+rig.weapon.get_children():
		for slot in surface.mesh.get_surface_count():
			var material=surface.get_active_material(slot) as StandardMaterial3D
			check(material!=null and material.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED,"Visible native role material remains opaque: "+actor.appearance_key)
			original.append([material,material.albedo_color,material.roughness,material.emission_energy_multiplier])
	actor.set_boss_phase(2)
	var changed=false
	for item in original:changed=changed or not item[0].albedo_color.is_equal_approx(item[1])
	check(changed==actor.boss,"Only actual guardian surfaces change through real bossphase hook: "+actor.appearance_key)
	actor.set_boss_phase(0);rig.set_visual_readability(0.0,0.0)
	for item in original:
		var expected: Color=item[1]*.40;expected.a=item[1].a
		check(item[0].albedo_color.is_equal_approx(expected) and item[0].roughness==item[2],"Defeated role restores actual PBR pigment/alpha before demotion: "+actor.appearance_key)
	rig.set_visual_readability(1.0,0.0)
	for item in original:check(item[0].albedo_color.is_equal_approx(item[1]),"Phase0/live role restores original material without accumulated tint: "+actor.appearance_key)
	for item in peer_materials:
		check(item[0].albedo_color.is_equal_approx(item[1]) and item[0].roughness==item[2] and item[0].emission_energy_multiplier==item[3],"Real phase/readability updates leave same-role peer materials unchanged: "+actor.appearance_key)
		for active in original:check(item[0]!=active[0],"Same-role peers own distinct mutable material instances: "+actor.appearance_key)
	peer.free()

func run() -> void:
	var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/hostiles057/manifest.json"))
	check(manifest.native_bones==65 and manifest.original_rest_identical_to_raider056,"Offline native male clothing inventory binds to exact original rest")
	check(FileAccess.get_sha256("res://assets/models/hostiles057/male-clothing-native65.glb")==manifest.outfit.sha256,"Shared packed original clothing SHA matches builder inventory")
	var verified_cuff=false
	for part in manifest.cloth_parts:
		if part.name=="Male_Ranger_Arms":
			verified_cuff=part.has("wrist_glove_clip") and part.wrist_glove_clip.discarded_overlapping_glove_triangles>0 and part.wrist_glove_clip.original_body_hands_and_binds_unchanged
	check(verified_cuff,"Generated sleeve cuffs remove overlapping Ranger gloves while retaining independently verified original hands")
	var measured: Dictionary={}
	for role in NativeHostile.PROPS:
		var actor=native_actor(role);var rig=actor.motion_rig;var fixed_actor=actor.transform
		for action in ["Walk_Loop","Sword_Idle","Sword_Regular_A","Sword_Regular_B","Sword_Regular_C","Hit_Chest","Death01","Spell_Simple_Idle_Loop","Spell_Simple_Shoot","Spell_Simple_Enter"]:
			check(rig.player.has_animation(action),"Original native role clip is present and bound: "+role+" "+action)
		check(FileAccess.get_sha256("res://assets/models/hostiles057/"+role+"-fitted.glb")==manifest.weapons[role].sha256,"Actual fitted project role prop SHA matches provenance: "+role)
		var triangles=0;var labels: Array=[];var identities: Array=[]
		for surface: MeshInstance3D in rig.surfaces+rig.weapon.get_children():
			labels.append(String(surface.name));identities.append([surface,surface.mesh,surface.skin])
			for slot in surface.mesh.get_surface_count():triangles+=surface.mesh.surface_get_arrays(slot)[Mesh.ARRAY_INDEX].size()/3
		check(triangles==rig.rendered_triangles and triangles<=rig.triangle_budget(),"All visible native role parts match actual declared triangle budget: "+role+" "+str(triangles))
		check("Male_Peasant_Body" not in labels and "Male_Peasant_Legs" not in labels and "Male_Ranger_Body" in labels,"Original Ranger tunic replaces obsolete Peasant tunic, avoiding doubled cloth: "+role)
		for required in ["Raider_Authored_Head","Eyes","Eyebrows","Hair_Beard","Male_Peasant_Arms","Male_Peasant_Feet","Male_Ranger_Arms","Male_Ranger_Legs"]:
			check(required in labels,"Visible complete male anatomy/clothing includes "+required+": "+role)
		if role=="bulwark":check("Hostile057_StrappedForearmShield" in labels,"Bulwark shield attaches to actual forearm instead of an unclosed hand")
		audit_material_phases(actor)
		for phase in [["idle",.20],["walk",.25],["windup_skill",.25],["windup_skill",.75],["windup_skill",1.0],["recover_skill",.10]]:
			rig.pose(phase[0],phase[1]);rig.apply_actor_postprocess(actor,phase[0],phase[1],0.0,true)
			audit_pose(actor,role+" actual "+phase[0]+" "+str(phase[1]))
			audit_breastplate_clearance(actor,role+" actual "+phase[0]+" "+str(phase[1]))
			var before=rig._capture_source_pose()
			rig.pose(phase[0],phase[1]);rig.apply_actor_postprocess(actor,phase[0],phase[1],0.0,true)
			check(pose_distance(before,rig._capture_source_pose())<.0001,"Held native role sample does not accumulate transforms: "+role)
			var unit_scale=true;var exact_chain=true
			for bone in skeleton_count(rig):
				unit_scale=unit_scale and rig.skeleton.get_bone_pose_scale(bone).distance_to(Vector3.ONE)<.0001
				var name=String(rig.skeleton.get_bone_name(bone))
				if name not in ["root","pelvis"]:exact_chain=exact_chain and rig.skeleton.get_bone_pose_position(bone).distance_to(rig.skeleton.get_bone_rest(bone).origin)<.0002
			check(unit_scale and exact_chain,"Native role attack retains original anatomy translations and unit scale: "+role)
			rig.refresh_bounds();check(HostileSkin.actual_bounds(rig).position.y>=-.015,"Actual weighted native clothing/armor clears floor during role actions: "+role)
		for action in ["basic","skill","heavy"]:
			rig.pose("windup_"+action,1.0);var before=rig._capture_source_pose();var tip=rig.weapon_tip()
			rig.pose("recover_"+action,0.0)
			check(pose_distance(before,rig._capture_source_pose())<.0001 and tip.distance_to(rig.weapon_tip())<.0001,"All65 bones and actual role weapon join windup/recovery at authoritative release: "+role+" "+action)
		check(actor.transform==fixed_actor,"Native actions leave authoritative role position/rotation unchanged: "+role)
		actor.cancel_attack();actor.anticipation=0.0;actor.animate(.4,false)
		var before_hit=rig._capture_source_pose();actor.react(1.0,1.2);actor.animate(.04,false)
		check(pose_distance(before_hit,rig._capture_source_pose())>.005 and actor.transform==fixed_actor,"Actual damage applies native Hit_Chest without relocating role: "+role)
		audit_pose(actor,role+" actual hit overlay")
		audit_breastplate_clearance(actor,role+" actual hit overlay")
		actor.impact_time=-1.0
		for time in [0.0,.25,.50,.75,.90]:
			rig.pose("death",time);rig.apply_actor_postprocess(actor,"death",time,0.0,true)
			var minimum=HostileSkin.actual_bounds(rig).position.y
			check(minimum>=-.012,"Actual weighted original anatomy/clothing/armor stays above death floor: "+role+" "+str(time)+" min="+str(minimum))
			if time==.90:check(minimum<.035,"Final native death anatomy rests on real floor: "+role+" min="+str(minimum))
			audit_breastplate_clearance(actor,role+" actual death "+str(time))
			var prop_min=INF
			for point in rig.weapon_points:prop_min=minf(prop_min,(rig.motion_node.transform*(rig.weapon.transform*point)).y)
			check(prop_min>=.0029,"Actual settled rigid role prop clears floor: "+role+" "+str(time))
		for original in identities:check(original[0].mesh==original[1] and original[0].skin==original[2],"Native role rendering retains immutable shared mesh/skin: "+role)
		measured[role]={"triangles":triangles,"visible_skin_surfaces":rig.surfaces.size(),"armor_surfaces":rig.role_style.accessories.size(),"weapon_surfaces":rig.weapon.get_child_count()}
		actor.free()
	print("NATIVE_HOSTILE_METRICS ",JSON.stringify(measured))
	print("NATIVE_HOSTILE_CONTACT poses=",poses," max_finger_gap_m=",widest_finger_gap," max_penetration_m=",worst_penetration," max_actual_thumb_gap_m=",actual_thumb_gap)
	print("NATIVE_HOSTILE_BREASTPLATE min_actual_weighted_tunic_and_belt_clearance_m=",closest_breastplate_clearance)
	print("NATIVE HOSTILE SMOKE: ",checks," checks, ",failures.size()," failures")
	for failure in failures:print("FAIL ",failure)
	quit(0 if failures.is_empty() else 1)

func skeleton_count(rig: RefCounted) -> int:return rig.skeleton.get_bone_count()
