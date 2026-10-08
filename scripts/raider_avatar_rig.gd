extends "res://scripts/source_avatar_rig.gd"
## Original clothed native65 anatomy replaces the old modular monster body.
## The male head/eyes/brows/beard keep original geometry and inverse binds;
## the combat actor still owns attack, contact, movement and death clocks.
const RAIDER=preload("res://assets/models/raider056/raider-native65.glb")
const AXE=preload("res://assets/models/raider056/axe-fitted.glb")
const AXE_SCALE:=.55
const AXE_GRIP:=Vector3(0,.035,0)
const AXE_RADIUS:=.018
const ATTACK_RECOVERY:=.30
var weapon_tip_point:=Vector3.ZERO
var sword_idle_pose: Dictionary={}
var hit_samples: Array[Dictionary]=[]
var material_origins: Dictionary={}
var last_clip:="idle"
var last_clip_time:=0.0
var raider_death_grounding: Array=[]

static func has_appearance(appearance: String) -> bool:return appearance=="raider"

func build(parent: Node3D,appearance: String) -> void:
	key=appearance
	motion_node=RAIDER.instantiate() as Node3D;motion_node.name="AuthoredRaiderAvatar"
	parent.add_child(motion_node)
	skeleton=motion_node.find_children("*","Skeleton3D",true,false)[0]
	player=motion_node.find_children("*","AnimationPlayer",true,false)[0]
	player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	assert(skeleton.get_bone_count()==65)
	var library=player.get_animation_library("").duplicate() as AnimationLibrary
	player.remove_animation_library("");player.add_animation_library("",library)
	for action in ["Idle_Loop","Walk_Loop"]:
		if not player.has_animation(action) and player.has_animation(action.trim_suffix("_Loop")):
			library.add_animation(action,player.get_animation(action.trim_suffix("_Loop")))
	for i in skeleton.get_bone_count():
		rest.append(skeleton.get_bone_global_rest(i));bone_bounds.append(AABB());populated.append(false)
	for surface: MeshInstance3D in motion_node.find_children("*","MeshInstance3D",true,false):
		surface.layers=2;surface.ignore_occlusion_culling=true;surface.extra_cull_margin=3.0
		surfaces.append(surface)
		for slot in surface.mesh.get_surface_count():
			var original=surface.get_active_material(slot)
			if original!=null:
				var material=original.duplicate() as StandardMaterial3D
				surface.set_surface_override_material(slot,material)
				material_origins[material]={"albedo":material.albedo_color,"roughness":material.roughness}
			_index_surface(surface,slot)
	mesh=surfaces[0].mesh;skin=surfaces[0].skin
	rendered_triangles=triangles
	source_rest_pose=_capture_source_pose()
	_sample("Sword_Idle",0.0);sword_idle_pose=_capture_source_pose()
	var profile=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/raider056/axe-grip.json"))
	var center=profile.hand_local_origin;grip_center=Vector3(center[0],center[1],center[2])
	var axis=profile.hand_local_axis;grip_axis=Vector3(axis[0],axis[1],axis[2]).normalized()
	for name in profile.bone_local_quaternions_xyzw:
		var bone=skeleton.find_bone(name);var q=profile.bone_local_quaternions_xyzw[name]
		assert(bone>=0);grip_pose[bone]=Quaternion(q[0],q[1],q[2],q[3]).normalized()
	grasp_frame=_frame(grip_axis,Vector3.RIGHT)
	weapon_basis=grasp_frame*Basis(Vector3.UP,PI*.5)
	_build_axe()
	var grounding=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/raider056/death-grounding.json"))
	raider_death_grounding=grounding.samples
	# Cache real authored Hit_Chest offsets once. Runtime recoil is a bounded
	# rest-relative overlay on chest/neck/head/clavicles, never a second clock.
	for phase in 17:
		_sample("Hit_Chest",player.get_animation("Hit_Chest").length*float(phase)/16.0)
		hit_samples.append(_capture_source_pose())
	motion_node.rotation.y=PI
	pose("idle",0.0);refresh_bounds()
	# Original actual anatomy height excludes the held extended weapon.
	source_height=float(JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/raider056/raider-native65.json")).source_height_m)
	assert(source_height>1.7 and source_height<2.2)
	assert(rendered_triangles<=triangle_budget())
	build_ok=true

func triangle_budget() -> int:return 20000

func _build_axe() -> void:
	weapon=Node3D.new();weapon.name="HeldRaiderAxe";motion_node.add_child(weapon)
	var source=AXE.instantiate();var tip_height=-INF
	for original: MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
		if not String(original.name).begins_with("Weapon__"):continue
		var part=MeshInstance3D.new();part.name=original.name;part.mesh=original.mesh
		part.transform=original.transform;part.layers=2;part.extra_cull_margin=3.0;weapon.add_child(part)
		for slot in part.mesh.get_surface_count():
			var material=original.get_active_material(slot)
			if material!=null:
				var copy=material.duplicate() as StandardMaterial3D
				part.set_surface_override_material(slot,copy)
				material_origins[copy]={"albedo":copy.albedo_color,"roughness":copy.roughness}
			var arrays=part.mesh.surface_get_arrays(slot);rendered_triangles+=arrays[Mesh.ARRAY_INDEX].size()/3
			for index in arrays[Mesh.ARRAY_INDEX]:
				var point: Vector3=part.transform*arrays[Mesh.ARRAY_VERTEX][index];weapon_points.append(point)
				if point.y>tip_height:tip_height=point.y;weapon_tip_point=point
	source.free()
	assert(weapon.get_child_count()==4 and weapon_points.size()>0)

func pose(clip: String,time: float) -> void:
	last_clip=clip;last_clip_time=time
	if clip=="death":_sample("Death01",clampf(time/.90,0,1)*player.get_animation("Death01").length)
	elif clip=="walk":_sample("Walk_Loop",fposmod(time,1.0)*player.get_animation("Walk_Loop").length)
	elif clip.begins_with("windup") or clip.begins_with("recover"):
		var length=player.get_animation("Sword_Regular_A").length
		var release=length*.56
		var recovering=clip.begins_with("recover")
		var phase=clampf(time/ATTACK_RECOVERY if recovering else time,0,1)
		var sample_time=lerpf(release,length,phase) if recovering else release*phase
		_sample("Sword_Regular_A",sample_time)
		if recovering:
			var settle=smoothstep(.62,1.0,phase)
			for i in skeleton.get_bone_count():
				skeleton.set_bone_pose_rotation(i,skeleton.get_bone_pose_rotation(i).slerp(sword_idle_pose.rotations[i],settle))
				skeleton.set_bone_pose_position(i,skeleton.get_bone_pose_position(i).lerp(sword_idle_pose.positions[i],settle))
	else:_sample("Sword_Idle",fposmod(time,player.get_animation("Sword_Idle").length))
	_fit_fingers();_update_weapon()

func _fit_fingers() -> void:
	for bone in grip_pose:skeleton.set_bone_pose_rotation(bone,grip_pose[bone])
	skeleton.force_update_all_bone_transforms()

func _update_weapon() -> void:
	if weapon==null:return
	var hand=skeleton.get_bone_global_pose(skeleton.find_bone("hand_r"))
	var basis=hand.basis*weapon_basis*AXE_SCALE
	weapon.transform=Transform3D(basis,hand*grip_center-basis*AXE_GRIP)

func weapon_grip_position() -> Vector3:return motion_node.transform*(weapon.transform*AXE_GRIP)
func weapon_tip() -> Vector3:return motion_node.transform*(weapon.transform*weapon_tip_point)
func walk_stride() -> float:return 1.46

func apply_actor_postprocess(actor: Variant,clip: String,time: float,_delta: float,_contact: bool) -> void:
	motion_node.position.y=.009
	if clip=="death":
		var sample=clampf(time/.90,0,1)*float(raider_death_grounding.size()-1)
		var i=int(floor(sample));motion_node.position.y=lerpf(float(raider_death_grounding[i]),float(raider_death_grounding[mini(i+1,raider_death_grounding.size()-1)]),sample-i)
	else:
		var low=INF
		for probe in floor_probes:
			var point=Vector3.ZERO
			for i in probe.bones.size():point+=(skeleton.get_bone_global_pose(probe.bones[i])*probe.binds[i]*probe.point)*probe.weights[i]
			low=minf(low,point.y)
		if is_finite(low):motion_node.position.y=maxf(.009,.003-low)
	if clip=="walk" and actor.moving:_plant_feet(actor)
	else:
		actor.plant_active[0]=false;actor.plant_active[1]=false
	var phase=clampf(actor.impact_time/actor.recoil_duration,0,1)
	actor.hit_strength=(smoothstep(0,.16,phase)*(1.0-smoothstep(.16,1.0,phase)))*actor.recoil_intensity if actor.impact_time>=0.0 and actor.death_time<0.0 else 0.0
	if clip!="death" and actor.hit_strength>0.0 and not actor.reduced_motion:
		var influence=.22 if actor.attack_time>=0.0 and actor.release_time<0.0 else (.45 if actor.attack_time>=0.0 else 1.0)
		_apply_native_hit(phase,actor.hit_strength*influence)
	_fit_fingers();_update_weapon()
	if clip=="death":
		# The collapsing body retains its weapon during the first contact;
		# the rigid axe then settles on the real floor, independent of bones.
		var drop=smoothstep(.20,.82,time)
		weapon.basis=weapon.basis.orthonormalized().slerp(Basis(Vector3.RIGHT,PI*.5),drop)*AXE_SCALE
		weapon.position=weapon.position.lerp(Vector3(-.28,.045-motion_node.position.y,-.10),drop)
		var low=INF
		for point in weapon_points:low=minf(low,(motion_node.transform*(weapon.transform*point)).y)
		if low<.003:weapon.position.y+=.003-low
	actor.motion_offset=motion_node.position;refresh_bounds()

func _apply_native_hit(phase: float,amount: float) -> void:
	var sample=clampf(phase,0,1)*16.0;var index=int(floor(sample));var next=mini(index+1,16);var alpha=sample-index
	for name in ["spine_01","spine_02","spine_03","neck_01","Head","clavicle_l","clavicle_r"]:
		var bone=skeleton.find_bone(name)
		var sampled: Quaternion=hit_samples[index].rotations[bone].slerp(hit_samples[next].rotations[bone],alpha)
		var native: Quaternion=source_rest_pose.rotations[bone]
		var offset=native.inverse()*sampled
		var posed=skeleton.get_bone_pose_rotation(bone)
		skeleton.set_bone_pose_rotation(bone,posed*Quaternion.IDENTITY.slerp(offset,clampf(amount,0,1)))
	skeleton.force_update_all_bone_transforms()

func set_visual_readability(value: float,focus: float) -> void:
	# Original PBR maps and opaque alpha remain intact; materials are owned by
	# this rig, so defeated emphasis never mutates another living Raider.
	for material: StandardMaterial3D in material_origins:
		var original: Color=material_origins[material].albedo
		var gain=lerpf(.40,1.0,clampf(value,0,1))
		var tint=original*gain
		tint.a=original.a
		material.albedo_color=tint.lerp(Color(tint.r*1.06,tint.g*1.035,tint.b,tint.a),clampf(focus,0,1)*.20)
