extends RefCounted
## Artist-authored modular avatar. Original native65 rest, skin, UVs and PBR
## remain on the imported scene; source clips are retargeted offline relative to rest.
const AVATAR=preload("res://assets/models/nyra052/arcanist.glb")
const WEAPON=preload("res://assets/models/nyra052/staff-grip053.glb")
const RECOVERY:=.34
const STAFF_SCALE:=.75
const STAFF_GRIP:=Vector3(0,-.147,0)
const GRIP_RADIUS:=.018
var build_ok:=false
var key:="Arcanist"
var motion_node: Node3D
var skeleton: Skeleton3D
var player: AnimationPlayer
var mesh: ArrayMesh
var skin: Skin
var body_material: StandardMaterial3D
var animation_profile: Dictionary={}
var rest: Array[Transform3D]=[]
var bounds:=AABB()
var source_height:=1.85
var triangles:=0
var weapon: Node3D
var surfaces: Array[MeshInstance3D]=[]
var bone_bounds: Array[AABB]=[]
var populated: Array[bool]=[]
var floor_probes: Array=[]
var grip_pose: Dictionary={}
var death_grip_pose: Dictionary={}
var grip_center:=Vector3.ZERO
var grip_axis:=Vector3.UP
var grasp_frame:=Basis.IDENTITY
var weapon_basis:=Basis.IDENTITY
var last_sample:=""
var last_time:=-1.0
var death_grounding: Array=[]
var weapon_points: PackedVector3Array=PackedVector3Array()
var planted_basis: Array[Basis]=[Basis.IDENTITY,Basis.IDENTITY]

static func has_appearance(appearance: String) -> bool:
	return appearance=="Arcanist"
static func retain_cache(appearances: Array[String]) -> Array[String]:
	return appearances

func build(parent: Node3D,appearance: String) -> void:
	key=appearance
	if FileAccess.file_exists("res://assets/models/nyra052/death-grounding.json"):
		var grounding=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/nyra052/death-grounding.json"))
		death_grounding=grounding.samples
	motion_node=AVATAR.instantiate() as Node3D;motion_node.name="AuthoredAvatar"
	parent.add_child(motion_node)
	skeleton=motion_node.find_children("*","Skeleton3D",true,false)[0]
	player=motion_node.find_children("*","AnimationPlayer",true,false)[0]
	player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var library=player.get_animation_library("").duplicate() as AnimationLibrary
	player.remove_animation_library("");player.add_animation_library("",library)
	for action in ["Idle_Loop","Walk_Loop","Spell_Simple_Idle_Loop"]:
		if not player.has_animation(action) and player.has_animation(action.trim_suffix("_Loop")):
			library.add_animation(action,player.get_animation(action.trim_suffix("_Loop")))
	assert(skeleton.get_bone_count()==65)
	for i in skeleton.get_bone_count():
		rest.append(skeleton.get_bone_global_rest(i));bone_bounds.append(AABB());populated.append(false)
	for child in motion_node.find_children("*","MeshInstance3D",true,false):
		var surface: MeshInstance3D=child
		surface.layers=2;surface.ignore_occlusion_culling=true;surface.extra_cull_margin=3.0
		surfaces.append(surface)
		for slot in surface.mesh.get_surface_count():
			var material=surface.get_active_material(slot)
			if material!=null:surface.set_surface_override_material(slot,material.duplicate())
			_index_surface(surface,slot)
	if not surfaces.is_empty():mesh=surfaces[0].mesh;skin=surfaces[0].skin
	_sample("Sword_Idle",0.0)
	for i in skeleton.get_bone_count():
		var name=String(skeleton.get_bone_name(i))
		if name.ends_with("_r") and name.split("_")[0] in ["thumb","index","middle","ring","pinky"]:
			death_grip_pose[i]=skeleton.get_bone_pose_rotation(i)
	var profile=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/nyra052/staff-grip053.json"))
	var center=profile.hand_local_origin;grip_center=Vector3(center[0],center[1],center[2])
	var axis=profile.hand_local_axis;grip_axis=Vector3(axis[0],axis[1],axis[2]).normalized()
	for bone_name in profile.bone_local_quaternions_xyzw:
		var bone=skeleton.find_bone(bone_name);var q=profile.bone_local_quaternions_xyzw[bone_name]
		assert(bone>=0)
		grip_pose[bone]=Quaternion(q[0],q[1],q[2],q[3]).normalized()
	grasp_frame=_frame(grip_axis,Vector3.RIGHT)
	# Finger aperture follows local +Y of the prop; roll its ornament toward
	# the character's front without changing the grasp axis.
	weapon_basis=grasp_frame*Basis(Vector3.UP,PI*.5)
	weapon=Node3D.new();weapon.name="HeldStaff";motion_node.add_child(weapon)
	var source=WEAPON.instantiate()
	for child in source.find_children("*","MeshInstance3D",true,false):
		if not String(child.name).begins_with("Weapon__"):continue
		var part=MeshInstance3D.new();part.name=child.name;part.mesh=child.mesh
		part.layers=2;part.extra_cull_margin=3.0;weapon.add_child(part)
		for slot in part.mesh.get_surface_count():
			var arrays=part.mesh.surface_get_arrays(slot)
			var used={}
			for index in arrays[Mesh.ARRAY_INDEX]:used[index]=true
			for index in used:weapon_points.append(arrays[Mesh.ARRAY_VERTEX][index])
	source.free()
	motion_node.rotation.y=PI
	pose("idle",0.0);refresh_bounds()
	source_height=bounds.size.y
	assert(source_height>1.5 and source_height<3.5)
	# Height is the authored figure; the extended staff must not shrink its body.
	source_height=1.85
	build_ok=true

func _index_surface(surface: MeshInstance3D,slot: int) -> void:
	var arrays=surface.mesh.surface_get_arrays(slot)
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	var bones: PackedInt32Array=arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
	assert(weights.size()==vertices.size()*4)
	triangles+=indices.size()/3
	var used: Dictionary={}
	for index in indices:used[index]=true
	for index in used:
		var probe={"point":vertices[index],"bones":[],"weights":[],"binds":[],"side":0 if vertices[index].x>0.0 else 1}
		for influence in 4:
			var weight=weights[index*4+influence]
			if weight<=0.0:continue
			var bind=bones[index*4+influence];var name=surface.skin.get_bind_name(bind)
			var bone=skeleton.find_bone(name) if name!=&"" else surface.skin.get_bind_bone(bind)
			assert(bone>=0)
			var local=surface.skin.get_bind_pose(bind)*vertices[index]
			if populated[bone]:bone_bounds[bone]=bone_bounds[bone].expand(local)
			else:bone_bounds[bone]=AABB(local,Vector3.ZERO);populated[bone]=true
			probe.bones.append(bone);probe.weights.append(weight);probe.binds.append(surface.skin.get_bind_pose(bind))
		# Only physical boot vertices close to the source floor. Staff is excluded.
		if String(surface.name).contains("Feet") and vertices[index].y<.055:floor_probes.append(probe)

func _sample(action: String,time: float) -> void:
	if action==last_sample and is_equal_approx(time,last_time):return
	assert(player.has_animation(action),action)
	player.play(action);player.advance(0.0);player.seek(time,true);player.advance(0.0)
	skeleton.force_update_all_bone_transforms();last_sample=action;last_time=time

func pose(clip: String,time: float) -> void:
	if clip=="idle":_sample("Idle_Loop",fposmod(time,player.get_animation("Idle_Loop").length))
	elif clip=="walk":_sample("Walk_Loop",fposmod(time,1.0)*player.get_animation("Walk_Loop").length)
	elif clip.begins_with("windup"):
		var phase=clampf(time,0,1)
		if phase<.55:_sample("Spell_Simple_Enter",phase/.55*.5333333)
		else:_sample("Spell_Simple_Shoot",(phase-.55)/.45*.24)
	elif clip.begins_with("recover"):
		var phase=clampf(time/RECOVERY,0,1)
		if phase<.55:_sample("Spell_Simple_Shoot",.24+phase/.55*.26)
		else:_sample("Spell_Simple_Exit",(phase-.55)/.45*.4333333)
	elif clip=="death":_sample("Death01",clampf(time/.90,0,1)*player.get_animation("Death01").length)
	else:_sample("Spell_Simple_Idle_Loop",0.0)
	var fingers=death_grip_pose if clip=="death" else grip_pose
	for bone in fingers:skeleton.set_bone_pose_rotation(bone,fingers[bone])
	skeleton.force_update_all_bone_transforms()
	_update_weapon()

func capture_pose() -> Array[Transform3D]:
	var result: Array[Transform3D]=[]
	for i in skeleton.get_bone_count():result.append(skeleton.get_bone_pose(i))
	return result
func blend_from(previous: Array[Transform3D],amount: float) -> void:
	for i in skeleton.get_bone_count():
		var current=skeleton.get_bone_pose(i)
		skeleton.set_bone_pose_position(i,previous[i].origin.lerp(current.origin,amount))
		skeleton.set_bone_pose_rotation(i,previous[i].basis.get_rotation_quaternion().slerp(current.basis.get_rotation_quaternion(),amount))
	skeleton.force_update_all_bone_transforms();_update_weapon()
func _update_weapon() -> void:
	if weapon==null:return
	var hand=skeleton.get_bone_global_pose(skeleton.find_bone("hand_r"))
	var basis=hand.basis*weapon_basis*STAFF_SCALE
	weapon.transform=Transform3D(basis,hand*grip_center-basis*STAFF_GRIP)
func _point(bone: String,local: Vector3=Vector3.ZERO) -> Vector3:
	return motion_node.transform*(skeleton.get_bone_global_pose(skeleton.find_bone(bone))*local)
func head_anchor() -> Vector3:return _point("Head",Vector3(0,.065,0))
func palm_position(side: int) -> Vector3:return _point("hand_l" if side==0 else "hand_r",Vector3(0,.06,0))
func weapon_grip_position() -> Vector3:return motion_node.transform*(weapon.transform*STAFF_GRIP)
func weapon_tip() -> Vector3:return motion_node.transform*(weapon.transform*Vector3(0,1.40,0))
func walk_stride() -> float:return 1.46
func configure_rendering(model: MeshInstance3D) -> void:
	# Render original imported surfaces with their native skin and real PBR maps.
	# The actor's legacy combined mesh is only an API placeholder.
	model.visible=false
func dispose() -> void:
	if is_instance_valid(motion_node):motion_node.free()
func set_visual_readability(_value: float,_focus: float) -> void:pass
func apply_actor_postprocess(actor: Variant,clip: String,time: float,_delta: float,_contact: bool) -> void:
	motion_node.position.y=.009
	if clip!="death":
		var low=INF
		for probe in floor_probes:
			var point=Vector3.ZERO
			for i in probe.bones.size():point+=(skeleton.get_bone_global_pose(probe.bones[i])*probe.binds[i]*probe.point)*probe.weights[i]
			low=minf(low,point.y)
		if is_finite(low):motion_node.position.y=maxf(.009,.003-low)
	if clip=="death" and not death_grounding.is_empty():
		var sample=clampf(time/.90,0,1)*float(death_grounding.size()-1)
		var index=int(floor(sample))
		motion_node.position.y=lerpf(float(death_grounding[index]),float(death_grounding[mini(index+1,death_grounding.size()-1)]),sample-index)
		var drop=smoothstep(.12,.75,time)
		weapon.basis=weapon.basis.orthonormalized().slerp(Basis(Vector3.RIGHT,PI*.5),drop)*STAFF_SCALE
		weapon.position=weapon.position.lerp(Vector3(-.35,.035-motion_node.position.y,-.15),drop)
		var lowest=INF
		for point in weapon_points:lowest=minf(lowest,(motion_node.transform*(weapon.transform*point)).y)
		if lowest<.003:weapon.position.y+=.003-lowest
	if clip=="walk" and actor.moving:_plant_feet(actor)
	else:
		actor.plant_active[0]=false
		actor.plant_active[1]=false
	if clip!="death":
		_support_staff_arm()
		_update_weapon()
	actor.motion_offset=motion_node.position
	var phase=clampf(actor.impact_time/actor.recoil_duration,0,1)
	actor.hit_strength=(smoothstep(0,.16,phase)*(1.0-smoothstep(.16,1.0,phase)))*actor.recoil_intensity if actor.impact_time>=0.0 and actor.death_time<0.0 else 0.0
	refresh_bounds()
func refresh_bounds() -> void:
	var first=true
	for bone in skeleton.get_bone_count():
		if not populated[bone]:continue
		var box=motion_node.transform*(skeleton.get_bone_global_pose(bone)*bone_bounds[bone])
		bounds=box if first else bounds.merge(box);first=false
	if weapon!=null:
		for part in weapon.get_children():
			bounds=bounds.merge(motion_node.transform*(weapon.transform*(part.transform*part.mesh.get_aabb())))

func _frame(direction: Vector3,normal: Vector3) -> Basis:
	var y=direction.normalized()
	var z=(normal-y*normal.dot(y)).normalized()
	return Basis(y.cross(z).normalized(),y,z)
func _global_rotation(bone: int,basis: Basis) -> void:
	var parent=skeleton.get_bone_parent(bone)
	var local=basis if parent<0 else skeleton.get_bone_global_pose(parent).basis.inverse()*basis
	skeleton.set_bone_pose_rotation(bone,local.orthonormalized().get_rotation_quaternion())
	skeleton.force_update_all_bone_transforms()

func _support_staff_arm() -> void:
	# A bent support forearm presents the finger opening to an upright staff.
	# Solve against the native rest lengths; never stretch the hand or arm.
	var upper=skeleton.find_bone("upperarm_r")
	var lower=skeleton.find_bone("lowerarm_r")
	var hand=skeleton.find_bone("hand_r")
	var chest=skeleton.get_bone_global_pose(skeleton.find_bone("spine_03")).origin
	var target=chest+Vector3(-.30,-.10,.14)
	var start=skeleton.get_bone_global_pose(upper).origin
	var first=rest[lower].origin-rest[upper].origin
	var second=rest[hand].origin-rest[lower].origin
	var a=first.length();var b=second.length()
	var direction=(target-start).normalized()
	var distance=clampf(start.distance_to(target),absf(a-b)+.001,a+b-.0002)
	var pole=Vector3(-.35,-.8,-.4)
	var bend=(pole-direction*pole.dot(direction)).normalized()
	var along=(a*a-b*b+distance*distance)/(2.0*distance)
	var elbow=start+direction*along+bend*sqrt(maxf(0.0,a*a-along*along))
	var finish=start+direction*distance
	var normal=(elbow-start).cross(finish-elbow)
	var rest_normal=first.cross(second)
	if rest_normal.length_squared()<.000001:
		rest_normal=rest[upper].basis.z-first.normalized()*rest[upper].basis.z.dot(first.normalized())
	_global_rotation(upper,_frame(elbow-start,normal)*_frame(first,rest_normal).inverse()*rest[upper].basis)
	_global_rotation(lower,_frame(finish-elbow,normal)*_frame(second,rest_normal).inverse()*rest[lower].basis)
	_global_rotation(hand,_frame(Vector3.UP,Vector3.LEFT)*grasp_frame.inverse())
func _plant_feet(actor: Variant) -> void:
	var minima=[INF,INF]
	for probe in floor_probes:
		var point=Vector3.ZERO
		for i in probe.bones.size():point+=(skeleton.get_bone_global_pose(probe.bones[i])*probe.binds[i]*probe.point)*probe.weights[i]
		minima[probe.side]=minf(minima[probe.side],point.y)
	var support=0 if minima[0]<minima[1] else 1
	for side in 2:
		if side!=support:actor.plant_active[side]=false;continue
		var suffix="l" if side==0 else "r"
		var thigh=skeleton.find_bone("thigh_"+suffix)
		var calf=skeleton.find_bone("calf_"+suffix)
		var foot=skeleton.find_bone("foot_"+suffix)
		var current=skeleton.get_bone_global_pose(foot)
		if not actor.plant_active[side]:
			actor.plant_points[side]=actor.body.to_global(motion_node.transform*current.origin);actor.plant_active[side]=true
			planted_basis[side]=current.basis
		var target=motion_node.transform.affine_inverse()*actor.body.to_local(actor.plant_points[side])
		var start=skeleton.get_bone_global_pose(thigh).origin
		var first=rest[calf].origin-rest[thigh].origin
		var second=rest[foot].origin-rest[calf].origin
		var a=first.length();var b=second.length()
		# Keep native leg lengths. Adapt pelvis height when a planted ankle
		# would otherwise lie beyond the retargeted leg's reach.
		var reach=a+b-.0002
		if start.distance_to(target)>reach:
			var horizontal=Vector2(start.x-target.x,start.z-target.z).length_squared()
			if horizontal<reach*reach:
				var shift=target.y+sqrt(reach*reach-horizontal)-start.y
				var pelvis=skeleton.find_bone("pelvis")
				var parent=skeleton.get_bone_parent(pelvis)
				var global=skeleton.get_bone_global_pose(pelvis)
				global.origin.y+=minf(0.0,shift)
				skeleton.set_bone_pose_position(pelvis,skeleton.get_bone_global_pose(parent).affine_inverse()*global.origin)
				skeleton.force_update_all_bone_transforms()
				start=skeleton.get_bone_global_pose(thigh).origin
		var direction=(target-start).normalized();var distance=clampf(start.distance_to(target),absf(a-b)+.001,a+b-.0002)
		var knee=skeleton.get_bone_global_pose(calf).origin
		var bend=knee-start-direction*(knee-start).dot(direction)
		if bend.length_squared()<.000001:bend=Vector3.BACK-direction*direction.z
		bend=bend.normalized()
		var along=(a*a-b*b+distance*distance)/(2.0*distance)
		var elbow=start+direction*along+bend*sqrt(maxf(0.0,a*a-along*along))
		var finish=start+direction*distance
		var normal=(elbow-start).cross(finish-elbow)
		var rest_normal=first.cross(second)
		if rest_normal.length_squared()<.000001:rest_normal=rest[thigh].basis.z-first.normalized()*rest[thigh].basis.z.dot(first.normalized())
		_global_rotation(thigh,_frame(elbow-start,normal)*_frame(first,rest_normal).inverse()*rest[thigh].basis)
		_global_rotation(calf,_frame(finish-elbow,normal)*_frame(second,rest_normal).inverse()*rest[calf].basis)
		_global_rotation(foot,planted_basis[side])
