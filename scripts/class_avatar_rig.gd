extends "res://scripts/source_avatar_rig.gd"
## Ranger and Vowkeeper keep the manufacturer's identical original native65
## rest and complete clothed anatomy. No legacy29 mesh/bone mapping is used.
const OUTFIT=preload("res://assets/models/classes055/ranger-native65.glb")
const ClassStyle=preload("res://scripts/class_avatar_style.gd")
const ClassPose=preload("res://scripts/class_avatar_pose.gd")
const SWORD=preload("res://assets/models/vowkeeper.glb")
const BOW=preload("res://assets/models/ranger.glb")
var class_weapon_scale:=.55
var class_grip:=Vector3(0,-.045,0)
var bow_strings: Array[MeshInstance3D]=[]
var bow_arrow: Node3D
var class_pose_state: Dictionary={}
var last_clip:="idle"
var last_clip_time:=0.0
var sword_idle_pose: Dictionary={}
var class_death_floor:=-1.0
var weighted_probes: Array=[]
static var weighted_probe_cache: Dictionary={}
var bow_grip_pose: Dictionary={}
var bow_hook_pose: Dictionary={}
var bow_grip_center:=Vector3.ZERO
var bow_grasp_frame:=Basis.IDENTITY
var bow_hook_local:=Vector3(0,.064,.006)
var bow_hook_probe: Dictionary={}
var bow_rest_height:=.045

static func has_appearance(appearance: String) -> bool:return appearance in ["Vowkeeper","Ranger"]

func build(parent: Node3D,appearance: String) -> void:
	key=appearance
	motion_node=OUTFIT.instantiate() as Node3D;motion_node.name="AuthoredClassAvatar"
	parent.add_child(motion_node)
	skeleton=motion_node.find_children("*","Skeleton3D",true,false)[0]
	player=motion_node.find_children("*","AnimationPlayer",true,false)[0]
	player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	assert(skeleton.get_bone_count()==65)
	var library=player.get_animation_library("").duplicate() as AnimationLibrary
	player.remove_animation_library("");player.add_animation_library("",library)
	var accepted=AVATAR.instantiate() as Node3D
	var accepted_skeleton=accepted.find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
	var accepted_player=accepted.find_children("*","AnimationPlayer",true,false)[0] as AnimationPlayer
	for action in accepted_player.get_animation_list():
		if action=="RESET" or library.has_animation(action):continue
		library.add_animation(action,accepted_player.get_animation(action))
	for action in ["Idle_Loop","Walk_Loop","Spell_Simple_Idle_Loop"]:
		if not player.has_animation(action) and player.has_animation(action.trim_suffix("_Loop")):
			library.add_animation(action,player.get_animation(action.trim_suffix("_Loop")))
	for i in skeleton.get_bone_count():
		assert(skeleton.get_bone_name(i)==accepted_skeleton.get_bone_name(i))
		assert(skeleton.get_bone_global_rest(i).is_equal_approx(accepted_skeleton.get_bone_global_rest(i)))
		rest.append(skeleton.get_bone_global_rest(i));bone_bounds.append(AABB());populated.append(false)
	for source: MeshInstance3D in accepted.find_children("*","MeshInstance3D",true,false):
		var label=String(source.name)
		if label not in ["Eyebrows","Eyes","Nyra_Authored_Head","Nyra_Hair_Buns"]:continue
		if key=="Ranger" and label.contains("Hair"):continue
		var part=MeshInstance3D.new();part.name=source.name;part.mesh=source.mesh;part.skin=source.skin
		part.transform=source.transform
		motion_node.add_child(part);part.skeleton=part.get_path_to(skeleton)
	accepted.free()
	for child: MeshInstance3D in motion_node.find_children("*","MeshInstance3D",true,false):
		if key=="Vowkeeper" and String(child.name).contains("Head_Hood"):
			child.free();continue
		child.layers=2;child.ignore_occlusion_culling=true;child.extra_cull_margin=3.0
		surfaces.append(child)
		for slot in child.mesh.get_surface_count():
			var material=child.get_active_material(slot)
			if material!=null:child.set_surface_override_material(slot,material.duplicate())
			_index_surface(child,slot)
			_append_weighted_probes(child,slot)
	mesh=surfaces[0].mesh;skin=surfaces[0].skin
	style=ClassStyle.new();style.apply(self)
	var rendered_surfaces: Array[MeshInstance3D]=[]
	var hidden_triangles=0
	for surface in surfaces:
		if surface.visible:rendered_surfaces.append(surface)
		else:
			for slot in surface.mesh.get_surface_count():hidden_triangles+=surface.mesh.surface_get_arrays(slot)[Mesh.ARRAY_INDEX].size()/3
	surfaces=rendered_surfaces
	if weighted_probe_cache.has(key):weighted_probes=weighted_probe_cache[key]
	else:weighted_probe_cache[key]=weighted_probes
	rendered_triangles=triangles-hidden_triangles+style.triangle_count
	source_rest_pose=_capture_source_pose()
	# Native sword fingers define the unused hand and the bow's thumb/index
	# draw hook; the physical weapon hand gets the verified fitted aperture.
	_sample("Sword_Idle",0.0);sword_idle_pose=_capture_source_pose()
	var profile=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/nyra052/staff-grip053.json"))
	var center=profile.hand_local_origin;grip_center=Vector3(center[0],center[1],center[2])
	var axis=profile.hand_local_axis;grip_axis=Vector3(axis[0],axis[1],axis[2]).normalized()
	for name in profile.bone_local_quaternions_xyzw:
		var index=skeleton.find_bone(name);var q=profile.bone_local_quaternions_xyzw[name]
		grip_pose[index]=Quaternion(q[0],q[1],q[2],q[3]).normalized()
	grasp_frame=_frame(grip_axis,Vector3.RIGHT)
	if key=="Ranger":ClassPose.prepare_bow_grip(self)
	_build_weapon()
	motion_node.rotation.y=PI
	pose("idle",0.0)
	if key=="Ranger":ClassPose.prepare_arrow_rest(self);pose("idle",0.0)
	refresh_bounds()
	source_height=1.85;build_ok=true

func _append_weighted_probes(surface: MeshInstance3D,slot: int) -> void:
	if weighted_probe_cache.has(key):return
	var arrays=surface.mesh.surface_get_arrays(slot);var used={}
	for index in arrays[Mesh.ARRAY_INDEX]:used[index]=true
	for index in used:
		var probe={"point":arrays[Mesh.ARRAY_VERTEX][index],"bones":[],"weights":[],"binds":[]}
		for influence in 4:
			var weight=float(arrays[Mesh.ARRAY_WEIGHTS][index*4+influence])
			if weight<=0.0:continue
			var bind=int(arrays[Mesh.ARRAY_BONES][index*4+influence]);var name=surface.skin.get_bind_name(bind)
			var bone=skeleton.find_bone(name) if name!=&"" else surface.skin.get_bind_bone(bind)
			probe.bones.append(bone);probe.weights.append(weight);probe.binds.append(surface.skin.get_bind_pose(bind))
		weighted_probes.append(probe)

func _build_weapon() -> void:
	weapon=Node3D.new();weapon.name="HeldSword" if key=="Vowkeeper" else "HeldBow"
	motion_node.add_child(weapon)
	var source=(SWORD if key=="Vowkeeper" else BOW).instantiate()
	if key=="Ranger":
		class_weapon_scale=.75;class_grip=Vector3.ZERO
		bow_arrow=Node3D.new();bow_arrow.name="NockedArrow";weapon.add_child(bow_arrow)
	for child: MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
		var label=String(child.name)
		if not label.begins_with("Weapon__") and not (key=="Ranger" and label.begins_with("Arrow__")):continue
		var part=MeshInstance3D.new();part.name=child.name;part.mesh=child.mesh
		if key=="Ranger" and label=="Weapon__leather":
			# The source bow's thick central handle is fitted to the measured
			# native finger aperture. The authored limbs/ornaments stay intact.
			var fitted=ArrayMesh.new()
			for slot in child.mesh.get_surface_count():
				var arrays=child.mesh.surface_get_arrays(slot).duplicate()
				var points: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX].duplicate()
				for index in points.size():
					var amount=1.0-smoothstep(.10,.17,absf(points[index].y))
					if points[index].z<.10:
						var radial=Vector2(points[index].x,points[index].z)
						var fitted_radius=.0175/class_weapon_scale
						if radial.length()>fitted_radius:
							var scale=lerpf(1.0,fitted_radius/radial.length(),amount)
							points[index].x*=scale;points[index].z*=scale
				arrays[Mesh.ARRAY_VERTEX]=points
				fitted.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
				fitted.surface_set_material(slot,child.mesh.surface_get_material(slot))
			part.mesh=fitted
		part.layers=2;part.extra_cull_margin=3.0
		(bow_arrow if label.begins_with("Arrow__") else weapon).add_child(part)
		for slot in part.mesh.get_surface_count():
			var arrays=part.mesh.surface_get_arrays(slot);rendered_triangles+=arrays[Mesh.ARRAY_INDEX].size()/3
			for point in arrays[Mesh.ARRAY_VERTEX]:weapon_points.append(point)
			var material=part.mesh.surface_get_material(slot)
			if material!=null:part.set_surface_override_material(slot,material.duplicate())
	source.free()
	if key=="Ranger":
		for index in 2:
			var string=MeshInstance3D.new();string.name="BowStringUpper" if index==0 else "BowStringLower"
			var cylinder=CylinderMesh.new();cylinder.top_radius=.0028;cylinder.bottom_radius=.0028;cylinder.height=1.0;cylinder.radial_segments=6;cylinder.rings=0
			string.mesh=cylinder;string.layers=2
			rendered_triangles+=24
			var material=StandardMaterial3D.new();material.albedo_color=Color(.65,.60,.46);material.roughness=.88
			string.material_override=material;weapon.add_child(string);bow_strings.append(string)
	weapon_basis=grasp_frame*Basis(Vector3.UP,PI*.5)

func pose(clip: String,time: float) -> void:
	last_clip=clip;last_clip_time=time
	if key=="Vowkeeper":_sword_pose(clip,time)
	else:
		if clip=="death":
			_sample("Death01",clampf(time/.90,0,1)*player.get_animation("Death01").length)
			class_pose_state={"draw":0.0,"aim":0.0,"nocked":false}
		elif clip=="walk":_sample("Walk_Loop",fposmod(time,1.0)*player.get_animation("Walk_Loop").length)
		elif clip.begins_with("windup") or clip.begins_with("recover"):
			# Bow time is draw/recovery phase, not an idle clock. Keep the
			# native support pose identical at windup(1) and recovery(0),
			# where the production contact event intentionally skips blending.
			_sample("Idle_Loop",0.0)
		else:_sample("Idle_Loop",fposmod(time,player.get_animation("Idle_Loop").length))
		ClassPose.apply_bow(self,clip,time)
	_apply_weapon_fingers();_update_weapon()

func _sword_pose(clip: String,time: float) -> void:
	if clip=="death":_sample("Death01",clampf(time/.90,0,1)*player.get_animation("Death01").length);return
	if clip=="walk":_sample("Walk_Loop",fposmod(time,1.0)*player.get_animation("Walk_Loop").length);return
	if clip.begins_with("windup") or clip.begins_with("recover"):
		var action=clip.get_slice("_",1)
		var source="Sword_Regular_A" if action=="basic" else ("Sword_Regular_B" if action=="skill" else "Sword_Regular_C")
		var length=player.get_animation(source).length
		var release=length*(.62 if action=="basic" else (.56 if action=="skill" else .67))
		var recovering=clip.begins_with("recover")
		var phase=clampf(time/RECOVERY if recovering else time,0,1)
		_sample(source,lerpf(release,length,phase) if recovering else release*phase)
		if recovering:
			var settle=smoothstep(.45,1.0,phase)
			for i in skeleton.get_bone_count():
				skeleton.set_bone_pose_rotation(i,skeleton.get_bone_pose_rotation(i).slerp(sword_idle_pose.rotations[i],settle))
				skeleton.set_bone_pose_position(i,skeleton.get_bone_pose_position(i).lerp(sword_idle_pose.positions[i],settle))
			skeleton.force_update_all_bone_transforms()
	else:_sample("Sword_Idle",fposmod(time,player.get_animation("Sword_Idle").length))

func _apply_weapon_fingers() -> void:
	if key=="Vowkeeper":
		for bone in grip_pose:skeleton.set_bone_pose_rotation(bone,grip_pose[bone])
	else:
		ClassPose.fit_bow_fingers(self)
	skeleton.force_update_all_bone_transforms()

func _update_weapon() -> void:
	if weapon==null:return
	if key=="Ranger":
		ClassPose.update_bow(self)
		return
	var hand=skeleton.get_bone_global_pose(skeleton.find_bone("hand_r"))
	var basis=hand.basis*weapon_basis*class_weapon_scale
	weapon.transform=Transform3D(basis,hand*grip_center-basis*class_grip)

func weapon_grip_position() -> Vector3:return motion_node.transform*(weapon.transform*class_grip)
func weapon_tip() -> Vector3:
	if key=="Ranger":return motion_node.transform*(weapon.transform*(bow_arrow.transform*Vector3(0,0,-.63)))
	return motion_node.transform*(weapon.transform*Vector3(0,1.39,0))

func apply_actor_postprocess(actor: Variant,clip: String,time: float,_delta: float,_contact: bool) -> void:
	motion_node.position.y=.009
	var low=INF
	var probes=weighted_probes if clip=="death" else floor_probes
	var poses: Array[Transform3D]=[]
	for i in skeleton.get_bone_count():poses.append(skeleton.get_bone_global_pose(i))
	for probe in probes:
		var point=Vector3.ZERO
		for i in probe.bones.size():point+=(poses[probe.bones[i]]*probe.binds[i]*probe.point)*probe.weights[i]
		low=minf(low,(motion_node.basis*point).y)
	if is_finite(low):motion_node.position.y=maxf(.009,.003-low)
	if clip=="walk" and actor.moving:_plant_feet(actor)
	else:
		actor.plant_active[0]=false;actor.plant_active[1]=false
	var phase=clampf(actor.impact_time/actor.recoil_duration,0,1)
	actor.hit_strength=(smoothstep(0,.16,phase)*(1.0-smoothstep(.16,1.0,phase)))*actor.recoil_intensity if actor.impact_time>=0.0 and actor.death_time<0.0 else 0.0
	if clip!="death" and actor.hit_strength>0.0 and not actor.reduced_motion:
		var influence=.22 if actor.attack_time>=0.0 and actor.release_time<0.0 else (.45 if actor.attack_time>=0.0 else 1.0)
		Combat.apply_recoil(self,actor,influence)
	_apply_weapon_fingers()
	if key=="Ranger" and clip!="death":ClassPose.apply_bow(self,clip,time,true)
	_update_weapon()
	if clip=="death":
		var drop=smoothstep(.12,.75,time)
		weapon.basis=weapon.basis.orthonormalized().slerp(Basis(Vector3.RIGHT,PI*.5),drop)*class_weapon_scale
		weapon.position=weapon.position.lerp(Vector3(-.35,.035-motion_node.position.y,-.15),drop)
		var minimum=INF
		for point in weapon_points:minimum=minf(minimum,(motion_node.transform*(weapon.transform*point)).y)
		if minimum<.003:weapon.position.y+=.003-minimum
	actor.motion_offset=motion_node.position
	refresh_bounds()

func refresh_bounds() -> void:
	var first=true
	for bone in skeleton.get_bone_count():
		if not populated[bone]:continue
		var box=motion_node.transform*(skeleton.get_bone_global_pose(bone)*bone_bounds[bone])
		bounds=box if first else bounds.merge(box);first=false
	if weapon!=null:
		for part in weapon.find_children("*","MeshInstance3D",true,false):
			var local=part.transform
			if part.get_parent()==bow_arrow:local=bow_arrow.transform*local
			bounds=bounds.merge(motion_node.transform*(weapon.transform*(local*part.mesh.get_aabb())))
