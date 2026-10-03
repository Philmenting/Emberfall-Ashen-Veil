extends RefCounted
## Shared volumetric geometry, 29 native skinning bones and authored 3D clips.
## Source models are bound once per appearance; animation never rewrites vertices.
const Models=preload("res://scripts/authored_characters.gd")
const Clips=preload("res://scripts/character_animation.gd")
const NAMES: Array[String]=["Root","Pelvis","Chest","Head","ClavicleL","UpperArmL","ForearmL","HandL","ClavicleR","UpperArmR","ForearmR","HandR","ThighL","ShinL","FootL","ThighR","ShinR","FootR","Cape","CapeTip","Weapon","BowUpper","BowString","BowLower","Arrow","CoatL","CoatR","HairL","HairR"]
const PARENTS: Array[int]=[-1,0,1,2,2,4,5,6,2,8,9,10,1,12,13,1,15,16,2,18,11,20,20,20,22,1,1,3,3]
const REST: Array[Vector3]=[Vector3.ZERO,Vector3(0,.90,0),Vector3(0,.39,0),Vector3(0,.42,0),Vector3(-.17,.19,0),Vector3(-.15,0,0),Vector3(0,-.31,0),Vector3(0,-.28,-.01),Vector3(.17,.19,0),Vector3(.15,0,0),Vector3(0,-.31,0),Vector3(0,-.28,-.01),Vector3(-.13,0,0),Vector3(0,-.42,0),Vector3(0,-.38,-.04),Vector3(.13,0,0),Vector3(0,-.42,0),Vector3(0,-.38,-.04),Vector3(0,.25,.14),Vector3(0,-.66,.10),Vector3.ZERO,Vector3(0,.60,.34),Vector3(0,0,.34),Vector3(0,-.60,.34),Vector3.ZERO,Vector3(-.12,-.03,0),Vector3(.12,-.03,0),Vector3(-.116,.12,.033),Vector3(.116,.12,.033)]
static var cache: Dictionary={}
var skeleton: Skeleton3D
var player: AnimationPlayer
var mesh: ArrayMesh
var skin: Skin
var library: AnimationLibrary
var rest: Array[Transform3D]=[]
var bone_bounds: Array[AABB]=[]
var bounds:=AABB()
var source_height:=2.0
var key:=""
var triangles:=0

func build(parent: Node3D,appearance: String) -> void:
	key=appearance
	skeleton=Skeleton3D.new(); skeleton.name="CharacterSkeleton"
	parent.add_child(skeleton)
	for name in NAMES: skeleton.add_bone(name)
	for i in NAMES.size():
		var bone_parent: int=7 if key=="Ranger" and i==20 else PARENTS[i]
		var offset:=REST[i]
		if key in ["Vowkeeper","Arcanist","Ranger"]:
			if i in [1,13,14,16,17]: offset.y*=1.17
			elif i in [6,7,10,11]: offset.y*=1.14
			elif i==3: offset.y-=.0154
			elif i in [27,28]: offset.y*=.86; offset.x*=.95
		skeleton.set_bone_parent(i,bone_parent)
		skeleton.set_bone_rest(i,Transform3D(Basis.IDENTITY,offset))
		skeleton.set_bone_pose_position(i,offset)
		rest.append(skeleton.get_bone_global_rest(i))
	if not cache.has(key):
		var authored: Node3D=Models.MODELS[key].instantiate()
		var baked:=_bake(authored)
		authored.free()
		baked.skin=skeleton.create_skin_from_rest_transforms()
		baked.library=Clips.create(key,rest)
		cache[key]=baked
	var data: Dictionary=cache[key]
	mesh=data.mesh; skin=data.skin; source_height=data.height; triangles=data.triangles
	bone_bounds.assign(data.bone_bounds); library=data.library
	player=AnimationPlayer.new(); player.name="CharacterAnimationPlayer"
	player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	parent.add_child(player); player.root_node=NodePath("..")
	player.add_animation_library("",library)
	pose("idle",0.0)

func _bake(authored: Node3D) -> Dictionary:
	var surface:=SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_custom_format(0,SurfaceTool.CUSTOM_RGB_FLOAT)
	var limits: Array[AABB]=[]; var populated: Array[bool]=[]
	for i in NAMES.size(): limits.append(AABB()); populated.append(false)
	var height:=0.0; var count:=0
	for source: MeshInstance3D in authored.find_children("*","MeshInstance3D",true,false):
		var part:=String(source.name).get_slice("__",0)
		var origin:=_part_origin(part)
		for slot in source.mesh.get_surface_count():
			var material: StandardMaterial3D=source.mesh.surface_get_material(slot)
			var material_name:=String(material.resource_name).get_slice(".",0)
			var category:=_category(material_name)
			var arrays: Array=source.mesh.surface_get_arrays(slot)
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
			var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			var size: int=vertices.size() if indices.is_empty() else indices.size()
			count+=size/3
			for cursor in size:
				var i: int=cursor if indices.is_empty() else indices[cursor]
				var local: Vector3=source.transform*vertices[i]
				var vertex:=local+origin
				var weights:=_weights(part,local)
				var equipment_slot:=_equipment_slot(part,local,material_name)
				var color:=material.albedo_color.srgb_to_linear()
				color.a=category/8.0
				surface.set_color(color)
				surface.set_custom(0,Color(vertex.x,vertex.y,vertex.z,1.0))
				surface.set_uv(Vector2(equipment_slot,material.roughness))
				surface.set_uv2(Vector2(material.metallic,1.0 if material.emission_enabled else 0.0))
				surface.set_bones(PackedInt32Array([int(weights.x),int(weights.y),0,0]))
				surface.set_weights(PackedFloat32Array([1.0-weights.z,weights.z,0,0]))
				surface.set_normal((source.transform.basis.inverse().transposed()*normals[i]).normalized())
				surface.add_vertex(vertex)
				var supported: Array[int]=[]
				if weights.z<.999: supported.append(int(weights.x))
				if weights.z>.001: supported.append(int(weights.y))
				for bone in supported:
					if populated[bone]: limits[bone]=limits[bone].expand(vertex)
					else: limits[bone]=AABB(vertex,Vector3.ZERO); populated[bone]=true
				if part in ["Body","HairL","HairR"]: height=maxf(height,vertex.y)
	surface.index()
	return {"mesh":surface.commit(),"height":height,"triangles":count,"bone_bounds":limits}

func _part_origin(part: String) -> Vector3:
	match part:
		"Body","HairL","HairR": return Vector3.ZERO
		"ArmL": return rest[5].origin
		"ArmR": return rest[9].origin
		"LegL": return rest[12].origin
		"LegR": return rest[15].origin
		"KneeL": return rest[13].origin
		"KneeR": return rest[16].origin
		"Cape": return rest[18].origin
		"Weapon","BowString","Arrow": return rest[20].origin
	assert(false,"Unbound 3D source part: "+part)
	return Vector3.ZERO

func _weights(part: String,p: Vector3) -> Vector3:
	if key in ["Vowkeeper","Arcanist","Ranger"]:
		if part in ["Body","HairL","HairR"]:
			if p.y<=1.053: p.y/=1.17
			elif p.y<1.753: p.y-=.153
			else: p.y=1.60+(p.y-1.753)/.86
		elif part.begins_with("Arm"): p.y/=1.14
		elif part.begins_with("Leg") or part.begins_with("Knee"): p.y/=1.17
	match part:
		"Body":
			if p.y>1.60: return Vector3(2,3,smoothstep(1.60,1.69,p.y))
			if p.y<.84:
				return Vector3(1,25 if p.x<0.0 else 26,1.0-smoothstep(.64,.90,p.y))
			return Vector3(1,2,smoothstep(.99,1.20,p.y))
		"HairL": return Vector3(3,27,1.0-smoothstep(1.72,1.83,p.y))
		"HairR": return Vector3(3,28,1.0-smoothstep(1.72,1.83,p.y))
		"ArmL","ArmR":
			var upper:=5 if part=="ArmL" else 9
			if p.z<-.22: return Vector3(upper+1,upper+1,0)
			if p.y<-.54: return Vector3(upper+1,upper+2,1.0-smoothstep(-.59,-.55,p.y))
			return Vector3(upper,upper+1,1.0-smoothstep(-.35,-.26,p.y))
		"LegL": return Vector3(12,13,1.0-smoothstep(-.40,-.34,p.y))
		"LegR": return Vector3(15,16,1.0-smoothstep(-.40,-.34,p.y))
		"KneeL": return Vector3(13,14,1.0-smoothstep(-.29,-.24,p.y))
		"KneeR": return Vector3(16,17,1.0-smoothstep(-.29,-.24,p.y))
		"Cape": return Vector3(18,19,1.0-smoothstep(-.84,-.28,p.y))
		"BowString":
			return Vector3(22,21 if p.y>=0.0 else 23,clampf(absf(p.y)/.60,0,1))
		"Arrow": return Vector3(24,24,0)
		"Weapon":
			if key=="Ranger": return Vector3(20,21 if p.y>=0.0 else 23,smoothstep(.30,.59,absf(p.y)))
			return Vector3(20,20,0)
	return Vector3(1,1,0)

func _equipment_slot(part: String,p: Vector3,mat: String) -> float:
	if part in ["Weapon","BowString","Arrow"]: return 0.0
	if mat in ["soul","ember"] and part=="Body": return 5.0
	if part=="Body": return 1.0 if p.y>(1.7874 if key in ["Vowkeeper","Arcanist","Ranger"] else 1.64) else 2.0
	if part.begins_with("Arm"): return 3.0
	if part.begins_with("Knee") or part.begins_with("Leg"): return 4.0
	return -1.0

func _category(mat: String) -> float:
	if key in ["Vowkeeper","Arcanist","Ranger"]:
		if mat=="skin": return 6.0
		if mat in ["lip","lip_shadow"]: return 7.0
	if mat in ["wine","violet","sage","linen","ash"]: return 1.0
	if mat=="leather": return 2.0
	if mat in ["skin","lip","lip_shadow","eye","iris"]: return 3.0
	if mat in ["hair","hair_shadow"]: return 4.0
	if mat=="bone": return 5.0
	return 0.0

func pose(clip: String,time: float) -> void:
	if player.current_animation!=clip: player.play(clip)
	player.seek(time,true)
	skeleton.force_update_all_bone_transforms()

func capture_pose() -> Array[Transform3D]:
	var result: Array[Transform3D]=[]
	for i in NAMES.size(): result.append(skeleton.get_bone_pose(i))
	return result

func blend_from(previous: Array[Transform3D],amount: float) -> void:
	for i in NAMES.size():
		var current:=skeleton.get_bone_pose(i)
		skeleton.set_bone_pose_position(i,previous[i].origin.lerp(current.origin,amount))
		var old_rotation:=previous[i].basis.get_rotation_quaternion() if previous[i].basis.get_scale().length_squared()>.001 else Quaternion.IDENTITY
		var new_rotation:=current.basis.get_rotation_quaternion() if current.basis.get_scale().length_squared()>.001 else Quaternion.IDENTITY
		skeleton.set_bone_pose_rotation(i,old_rotation.slerp(new_rotation,amount))
		skeleton.set_bone_pose_scale(i,previous[i].basis.get_scale().lerp(current.basis.get_scale(),amount))
	skeleton.force_update_all_bone_transforms()

func solve_leg(side: int,target: Vector3,pole: Vector3=Vector3.FORWARD) -> void:
	var poses:=capture_pose()
	Clips.solve_two(poses,12 if side==0 else 15,13 if side==0 else 16,14 if side==0 else 17,target,pole,key)
	Clips.global_rotation(poses,14 if side==0 else 17,Basis.IDENTITY,key)
	for i in [12,13,14] if side==0 else [15,16,17]:
		skeleton.set_bone_pose_rotation(i,poses[i].basis.get_rotation_quaternion())
	skeleton.force_update_all_bone_transforms()

func refresh_bounds() -> void:
	var first:=true
	for i in NAMES.size():
		if bone_bounds[i].size==Vector3.ZERO: continue
		var skin_transform:=skeleton.get_bone_global_pose(i)*rest[i].affine_inverse()
		var posed:=skin_transform*bone_bounds[i]
		bounds=posed if first else bounds.merge(posed); first=false

func weapon_tip() -> Vector3:
	var point:=Vector3(0,1.39,0)
	if key in ["Arcanist","hexer","guardian_1","guardian_2"]: point=Vector3(0,1.40,-.025)
	elif key=="Ranger": point=Vector3(0,0,-.62)
	elif key=="raider": point=Vector3(0,-.30,-.12)
	elif key=="guardian_0": point=Vector3(0,.90,0)
	elif key=="guardian_3": point=Vector3(.36,1.04,0)
	return skeleton.get_bone_global_pose(20)*point
