extends Node3D
## Continuously skinned approved paintings, driven by live simulation events.
const MotionRig=preload("res://scripts/painted_motion_rig.gd")
static var appearance_cache: Dictionary = {}
static var pose_mesh_cache: Dictionary = {}
static var metadata_cache: Dictionary = {}
var region_index := 0
var kind := "Vowkeeper"
var hostile := false
var boss := false
var reduced_motion := false
var body: Node3D
var painted_model: MeshInstance3D
var surface_material: ShaderMaterial
var atlas_texture: Texture2D
var atlas_path := ""
var atlas_grid := Vector2(3, 2)
var atlas_origin := Vector2.ZERO
var figure_height := 2.15
var pixels_per_world_unit := 1.0
var atlas_data: Dictionary = {}
var frame_data: Dictionary = {}
var source_region := Rect2()
var pose_frame := 0
var clock := 0.0
var gait_phase := 0.0
var gait_blend := 0.0
var moving := false
var attack_time := -1.0
var attack_queued := false
var attack_style := "basic"
var queued_attack_style := "basic"
var action_intensity := 1.0
var impact_time := -1.0
var hit_strength := 0.0
var death_time := -1.0
var death_lean := 1.0
var boss_phase := 0
var telegraph_left := 0.0
var equipped_items: Dictionary = {}
var equipment_grades: Dictionary = {}
var health_bar: MeshInstance3D
var materials: Dictionary = {}
var motion_rig: RefCounted
var joint_angles:=PackedFloat32Array()
var facing_sign:=1.0
var attack_duration:=0.3
var release_time:=-1.0
var external_release:=false
var telegraph_duration:=0.0
var retreat_time:=-1.0
var anticipation:=0.0
var motion_offset:=Vector3.ZERO
var cloth_follow:=0.0
var corpse_shift:=0.0
var gait_axis:=1.0
var anticipated_blend:=0.0
const COLLAPSE_DURATION:=0.58

const HEROES: Array[String] = ["Vowkeeper", "Arcanist", "Ranger"]
const ATLAS_TEXTURES = {
	"Vowkeeper":preload("res://assets/characters/vowkeeper.png"),
	"Arcanist":preload("res://assets/characters/arcanist.png"),
	"Ranger":preload("res://assets/characters/ranger.png"),
	"hostiles":preload("res://assets/characters/hostiles.png"),
	"guardian_0":preload("res://assets/characters/guardian_0.png"),
	"guardian_1":preload("res://assets/characters/guardian_1.png"),
	"guardian_2":preload("res://assets/characters/guardian_2.png"),
	"guardian_3":preload("res://assets/characters/guardian_3.png"),
}
const HOSTILE_BLOCKS := {"raider":Vector2(0,0),"bulwark":Vector2(3,0),"hexer":Vector2(0,2),"elite":Vector2(3,2)}
const GEAR_RANKS := {"COMMON":0,"UNCOMMON":1,"RARE":2,"EPIC":3,"LEGENDARY":4}
const GEAR_TINTS: Array[Color] = [Color("98794c"),Color("a5b393"),Color("93c4c6"),Color("b79ec6"),Color("e7bf79")]
const EQUIPMENT_REGIONS := {"Weapon":Rect2(0.70,0.12,0.26,0.59),"Helmet":Rect2(0.31,0.04,0.37,0.20),"Chest":Rect2(0.31,0.24,0.39,0.52),"Gloves":Rect2(0.12,0.40,0.78,0.28),"Boots":Rect2(0.12,0.76,0.78,0.20),"Amulet":Rect2(0.453,0.343,0.114,0.114)}

func _ready() -> void:
	body=Node3D.new()
	body.name="PaintedBody"
	add_child(body)
	death_lean=-1.0 if (kind.hash()+region_index)%2==0 else 1.0
	gait_axis=-1.0 if hostile or boss else 1.0
	_load_appearance()
	_contact_shadow()
	if not hostile and not boss: configure_equipment(equipped_items,kind)
	set_boss_phase(boss_phase)
	_set_pose(0)

func _load_appearance() -> void:
	if boss:
		atlas_texture=ATLAS_TEXTURES["guardian_%d" % clampi(region_index,0,3)]
		atlas_path="res://assets/characters/guardian_%d.png" % clampi(region_index,0,3)
		atlas_grid=Vector2(3,2); atlas_origin=Vector2.ZERO; figure_height=4.6
	elif kind in HEROES:
		atlas_texture=ATLAS_TEXTURES[kind]
		atlas_path="res://assets/characters/"+kind.to_lower()+".png"
		atlas_grid=Vector2(3,2); atlas_origin=Vector2.ZERO; figure_height=2.15
	else:
		atlas_texture=ATLAS_TEXTURES.hostiles
		atlas_path="res://assets/characters/hostiles.png"
		atlas_grid=Vector2(6,4); atlas_origin=HOSTILE_BLOCKS.get(kind,Vector2.ZERO)
		figure_height=2.30 if kind in ["bulwark","elite"] else 2.15
	appearance_cache[atlas_path]=atlas_texture
	assert(atlas_texture!=null,"Missing authored pose atlas: "+atlas_path)
	var metadata_path:=atlas_path.trim_suffix(".png")+".atlas.json"
	if not metadata_cache.has(metadata_path):
		metadata_cache[metadata_path]=JSON.parse_string(FileAccess.get_file_as_string(metadata_path))
	atlas_data=metadata_cache[metadata_path]
	assert(atlas_data.get("packing","")=="calibrated_source_uv_polygons","Missing calibrated pose geometry: "+metadata_path)
	if painted_model==null:
		painted_model=MeshInstance3D.new()
		painted_model.name="PaintedCharacter"
		painted_model.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		body.add_child(painted_model)
		painted_model.extra_cull_margin=figure_height
		painted_model.ignore_occlusion_culling=true
		painted_model.transparency=0.0
		surface_material=ShaderMaterial.new()
		surface_material.shader=preload("res://assets/shaders/painted_actor.gdshader")
		painted_model.material_override=surface_material
	painted_model.position=Vector3.ZERO
	surface_material.set_shader_parameter("atlas_texture",atlas_texture)
	surface_material.set_shader_parameter("atlas_grid",atlas_grid)
	surface_material.set_shader_parameter("atlas_origin",atlas_origin)
	_load_motion_rig()
	_set_pose(pose_frame)

func _load_motion_rig() -> void:
	if motion_rig!=null and is_instance_valid(motion_rig.skeleton): motion_rig.skeleton.free()
	var idle_index:=int(atlas_origin.y)*int(atlas_grid.x)+int(atlas_origin.x)
	var idle: Dictionary=atlas_data.frames[idle_index]
	var key: String="guardian_%d" % region_index if boss else kind
	motion_rig=MotionRig.new()
	motion_rig.build(key,idle,float(idle.body_height)/figure_height)
	body.add_child(motion_rig.skeleton)
	painted_model.skeleton=painted_model.get_path_to(motion_rig.skeleton)
	joint_angles.resize(MotionRig.NAMES.size()); joint_angles.fill(0.0)
	motion_rig.pose(joint_angles)
	surface_material.set_shader_parameter("animated_bow",kind=="Ranger" and not boss and not hostile)

func configure_equipment(equipment: Dictionary,class_key: String="") -> void:
	equipped_items=equipment.duplicate(true)
	if body==null:
		if class_key in HEROES: kind=class_key
		return
	if boss or hostile: return
	if class_key in HEROES and class_key!=kind:
		kind=class_key
		_load_appearance()
	surface_material.set_shader_parameter("equipment_enabled",true)
	equipment_grades.clear()
	var uniforms := {"Weapon":"weapon","Helmet":"helm","Chest":"chest","Amulet":"accent","Gloves":"gloves","Boots":"boots"}
	for slot in uniforms:
		var item: Dictionary=equipment.get(slot,equipment.get("Helm",{}) if slot=="Helmet" else {})
		var quality:=String(item.get("quality",item.get("rarity","COMMON"))).to_upper()
		var rank: int=GEAR_RANKS.get(quality,0)
		equipment_grades[slot]=rank
		surface_material.set_shader_parameter(uniforms[slot]+"_rank",float(rank))
		surface_material.set_shader_parameter(uniforms[slot]+"_tint",GEAR_TINTS[rank])

func set_boss_phase(phase: int) -> void:
	boss_phase=clampi(phase,0,2)
	if surface_material!=null:
		surface_material.set_shader_parameter("boss_surface",boss)
		surface_material.set_shader_parameter("boss_phase",float(boss_phase))

func visual_height() -> float:
	return maxf(0.0,pose_bounds().end.y+body.position.y)*scale.y if painted_model!=null else figure_height*scale.y

func pose_bounds() -> AABB:
	if painted_model==null: return AABB()
	var bounds: AABB=motion_rig.bounds if motion_rig!=null and painted_model.mesh==motion_rig.mesh else painted_model.mesh.get_aabb()
	if painted_model.mesh!=motion_rig.mesh: bounds.position.x+=corpse_shift
	if facing_sign<0.0: bounds.position.x=-bounds.end.x
	return bounds

func face_toward(direction: Vector3,camera_position: Vector3) -> void:
	if death_time>=0.0: return
	var right:=Vector3.UP.cross(((camera_position-position)*Vector3(1,0,1)).normalized())
	var projected:=direction.dot(right)
	# A dead zone prevents shoulder-to-shoulder opponents flickering left/right.
	if absf(projected)<0.22: return
	var authored_direction: float=-1.0 if hostile or boss else 1.0
	facing_sign=signf(projected)*authored_direction
	surface_material.set_shader_parameter("facing_sign",facing_sign)

func weapon_world_position(camera_position: Vector3) -> Vector3:
	var right:=Vector3.UP.cross(((camera_position-position)*Vector3(1,0,1)).normalized())
	var tip: Vector3=motion_rig.weapon_tip()
	return position+right*tip.x*facing_sign*scale.x+Vector3.UP*tip.y*scale.y

func follow_travel(displacement: Vector3,camera_position: Vector3) -> void:
	if displacement.length()<.001: return
	var right:=Vector3.UP.cross(((camera_position-position)*Vector3(1,0,1)).normalized())
	gait_axis=displacement.normalized().dot(right)/facing_sign

func portrait_anchor() -> Vector3:
	if motion_rig!=null and painted_model.mesh==motion_rig.mesh: return motion_rig.skeleton.get_bone_global_pose(2).origin
	if atlas_data.is_empty(): return Vector3(0,figure_height*.87,0)
	var idle_index:=int(atlas_origin.y)*int(atlas_grid.x)+int(atlas_origin.x)
	var idle: Dictionary=atlas_data.frames[idle_index]
	var point: Array=idle.get("portrait_anchor",idle.foot_anchor)
	var foot: Array=idle.foot_anchor
	return Vector3((float(point[0])-float(foot[0]))/pixels_per_world_unit,(float(foot[1])-float(point[1]))/pixels_per_world_unit,0)

func _contact_shadow() -> void:
	var mat:=ShaderMaterial.new()
	mat.shader=preload("res://assets/shaders/ground_grime.gdshader")
	mat.set_shader_parameter("tint",Color(0.01,0.009,0.013,0.53))
	var mesh:=PlaneMesh.new()
	mesh.size=Vector2(2.2,1.2) if boss else Vector2(1.10,0.66)
	var shadow:=MeshInstance3D.new()
	shadow.mesh=mesh; shadow.material_override=mat
	shadow.name="ContactShadow"; shadow.position.y=0.028
	shadow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)

func strike(style: String="basic",windup_seconds: float=0.3,wait_for_hit: bool=false) -> void:
	if death_time>=0.0: return
	var requested_style:=style if not style.is_empty() else "basic"
	if requested_style=="heavy":
		telegraph_left=0.0
		attack_queued=false
		attack_time=0.23; attack_style=requested_style; release_time=0.0
		external_release=false; pose_frame=4
		_apply_motion()
		return
	if attack_time>=0.0:
		attack_queued=true; queued_attack_style=requested_style
	else:
		attack_time=0.0; attack_style=requested_style; release_time=-1.0
		attack_duration=maxf(0.06,windup_seconds); external_release=wait_for_hit
		pose_frame=3

func sync_attack(remaining: float) -> void:
	if external_release and attack_time>=0.0 and release_time<0.0:
		attack_time=maxf(0.0,attack_duration-remaining)

func release_attack() -> bool:
	if death_time>=0.0 or attack_time<0.0 or release_time>=0.0: return false
	release_time=0.0; pose_frame=4
	_apply_motion()
	return true

func cancel_attack() -> void:
	if release_time<0.0:
		attack_time=-1.0; attack_queued=false; external_release=false

func retreat() -> void:
	cancel_attack(); retreat_time=0.0

func react() -> void:
	if death_time<0.0 and impact_time<0.0: impact_time=0.0

func set_telegraph(remaining_seconds: float,total_seconds: float=-1.0) -> void:
	if total_seconds>0.0: telegraph_duration=total_seconds
	elif remaining_seconds>telegraph_left+0.05: telegraph_duration=remaining_seconds
	telegraph_left=maxf(remaining_seconds,0.0)
	if telegraph_left>0.0 and death_time<0.0: pose_frame=3

func die() -> void:
	if death_time>=0.0: return
	death_time=0.0
	attack_queued=false; attack_time=-1.0; release_time=-1.0; telegraph_left=0.0

func _set_pose(frame: int) -> void:
	pose_frame=clampi(frame,0,5)
	if surface_material==null or atlas_data.is_empty(): return
	var index: int=(int(atlas_origin.y)+pose_frame/3)*int(atlas_grid.x)+int(atlas_origin.x)+pose_frame%3
	frame_data=atlas_data.frames[index]
	pixels_per_world_unit=float(frame_data.body_height)/figure_height
	var rect: Array=frame_data.region
	source_region=Rect2(float(rect[0]),float(rect[1]),float(rect[2]),float(rect[3]))
	var cache_key:=atlas_path+":"+str(index)+":"+str(figure_height)
	if pose_frame==0 and motion_rig!=null:
		painted_model.mesh=motion_rig.mesh
		painted_model.skin=motion_rig.skin
	else:
		painted_model.skin=null
	if pose_frame!=0 and not pose_mesh_cache.has(cache_key):
		pose_mesh_cache[cache_key]=_build_pose_mesh(frame_data)
	if pose_frame!=0: painted_model.mesh=pose_mesh_cache[cache_key]
	corpse_shift=0.0
	if pose_frame==5:
		var bounds: AABB=painted_model.mesh.get_aabb()
		corpse_shift=-bounds.get_center().x+death_lean*figure_height*.18
	surface_material.set_shader_parameter("sprite_offset",Vector2(corpse_shift,0))
	var texture_size:=Vector2(float(atlas_texture.get_width()),float(atlas_texture.get_height()))
	if pose_frame==0 and motion_rig!=null:
		surface_material.set_shader_parameter("atlas_texture",motion_rig.texture)
		surface_material.set_shader_parameter("frame_region",Vector4(0,0,1,1))
		surface_material.set_shader_parameter("layered_parts",true)
	else:
		surface_material.set_shader_parameter("atlas_texture",atlas_texture)
		surface_material.set_shader_parameter("frame_region",Vector4(source_region.position.x/texture_size.x,source_region.position.y/texture_size.y,source_region.size.x/texture_size.x,source_region.size.y/texture_size.y))
		surface_material.set_shader_parameter("layered_parts",false)
	surface_material.set_shader_parameter("pose_frame",float(pose_frame))

func _build_pose_mesh(data: Dictionary) -> ArrayMesh:
	var vertices:=PackedVector3Array()
	var uvs:=PackedVector2Array()
	var indices:=PackedInt32Array()
	var foot: Array=data.foot_anchor
	for polygon: Array in data.polygons:
		var source_points:=PackedVector2Array()
		for point: Array in polygon: source_points.append(Vector2(float(point[0]),float(point[1])))
		var triangles:=Geometry2D.triangulate_polygon(source_points)
		assert(not triangles.is_empty(),"Authored alpha contour failed triangulation: "+atlas_path)
		var first:=vertices.size()
		for point in source_points:
			vertices.append(Vector3((point.x-float(foot[0]))/pixels_per_world_unit,(float(foot[1])-point.y)/pixels_per_world_unit,0))
			uvs.append((point-source_region.position)/source_region.size)
		for triangle in triangles: indices.append(first+triangle)
	var arrays:=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_TEX_UV]=uvs
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

func animate(delta: float,walking: bool,horizontal_speed: float=-1.0) -> void:
	if body==null: return
	delta=maxf(0.0,delta)
	moving=walking
	if not reduced_motion: clock+=delta
	if death_time>=0.0:
		death_time+=delta
		if death_time>=COLLAPSE_DURATION:
			if painted_model.mesh==motion_rig.mesh: _set_pose(5)
			surface_material.set_shader_parameter("hit_flash",0.0)
		else: _apply_motion(delta)
		return
	var speed:=clampf(horizontal_speed,0.0,6.0) if horizontal_speed>=0.0 else 3.2
	gait_blend=lerpf(gait_blend,1.0 if walking else 0.0,1.0-exp(-delta*12.0))
	anticipated_blend=lerpf(anticipated_blend,anticipation,1.0-exp(-delta*12.0))
	if walking: gait_phase+=delta*speed*(2.6 if boss else 3.5)
	pose_frame=1+int(floor(gait_phase/PI))%2 if gait_blend>0.22 else 0
	action_intensity=1.0
	if telegraph_left>0.0:
		pose_frame=3
	elif attack_time>=0.0:
		if release_time>=0.0: release_time+=delta
		elif not external_release:
			attack_time+=delta
			if attack_time>=attack_duration: release_time=maxf(0.0,attack_time-attack_duration)
		var empowered:=attack_style in ["signature","sunder","judgment","chain","starfall","rain","marked"]
		action_intensity=1.2 if empowered else 1.0
		pose_frame=3 if release_time<0.0 else (4 if release_time<0.16 else 0)
		var recovery:=0.46 if boss or attack_style=="heavy" else 0.32
		if release_time>=recovery:
			if attack_queued:
				attack_time=0.0; release_time=-1.0; attack_queued=false; attack_style=queued_attack_style; pose_frame=3
			else: attack_time=-1.0; release_time=-1.0; external_release=false
	hit_strength=0.0
	if impact_time>=0.0:
		impact_time+=delta
		hit_strength=sin(clampf(impact_time/0.24,0.0,1.0)*PI)*exp(-impact_time*2.6)
		if impact_time>=0.24: impact_time=-1.0; hit_strength=0.0
	if retreat_time>=0.0:
		retreat_time+=delta
		if retreat_time>=0.38: retreat_time=-1.0
	surface_material.set_shader_parameter("hit_flash",hit_strength)
	surface_material.set_shader_parameter("action_intensity",action_intensity)
	_apply_motion(delta)

func _apply_motion(delta: float=0.0) -> void:
	if motion_rig==null: return
	if painted_model.mesh!=motion_rig.mesh and death_time<COLLAPSE_DURATION:
		var semantic:=pose_frame; _set_pose(0); pose_frame=semantic
	joint_angles.fill(0.0)
	motion_offset=Vector3.ZERO
	var breath:=sin(clock*1.8+float(kind.hash()%13)) if not reduced_motion else 0.0
	joint_angles[1]=breath*0.012; joint_angles[2]=-breath*0.010
	var stride:=sin(gait_phase)*gait_blend
	joint_angles[3]=stride*0.12; joint_angles[7]=-stride*0.16
	joint_angles[1]+=-stride*0.025; joint_angles[2]+=stride*0.022
	var windup:=0.0
	var release:=0.0
	var recovery:=1.0
	if telegraph_left>0.0:
		var progress:=clampf(1.0-telegraph_left/maxf(telegraph_duration,.001),0,1)
		windup=_ease(minf(progress/.78,1.0))
		release=_ease(clampf((progress-.90)/.10,0,1))
	elif attack_time>=0.0:
		if release_time<0.0:
			var progress:=clampf(attack_time/maxf(attack_duration,.001),0,1)
			windup=_ease(minf(progress/.72,1.0))
			release=_ease(clampf((progress-.72)/.28,0,1))
		else:
			# Contact is immediate on the real hit. Follow-through adds weight;
			# a slow cubic recovery returns to stance without a pose pop.
			windup=1.0; release=1.0
			var duration:=0.46 if boss or attack_style=="heavy" else 0.32
			recovery=1.0-_ease(clampf((release_time-.055)/(duration-.055),0,1))
	elif anticipated_blend>0.0: windup=anticipated_blend*.65
	if windup>0.0:
		var poses:=_action_poses()
		var prepared: Array=poses[0]; var contact: Array=poses[1]
		var influence:=windup*recovery
		joint_angles[3]=lerpf(float(prepared[0]),float(contact[0]),release)*influence
		joint_angles[4]=lerpf(float(prepared[1]),float(contact[1]),release)*influence
		joint_angles[7]=lerpf(float(prepared[3]),float(contact[3]),release)*influence
		joint_angles[8]=lerpf(float(prepared[4]),float(contact[4]),release)*influence
		joint_angles[1]=lerpf(float(prepared[5]),float(contact[5]),release)*influence
		joint_angles[2]=-joint_angles[1]*.55
		var weapon_angle:=lerpf(float(prepared[2]),float(contact[2]),release)*influence
		joint_angles[6]=weapon_angle-joint_angles[1]-joint_angles[3]-joint_angles[4]
		motion_offset.x=(.018 if hostile else -.018)*figure_height*windup*recovery*(1.0-release*2.4)
		motion_offset.y=-figure_height*.012*influence
	if not reduced_motion:
		joint_angles[1]+=death_lean*hit_strength*.09
		joint_angles[2]-=death_lean*hit_strength*.07
		motion_offset.x+=death_lean*hit_strength*figure_height*.022
		cloth_follow=lerpf(cloth_follow,-joint_angles[1]*.32+stride*.025,1.0-exp(-delta*7.0))
		var cloth_strength:=0.007+gait_blend*.01
		joint_angles[16]=cloth_follow+sin(clock*2.1)*cloth_strength
		joint_angles[17]=cloth_follow*1.3+sin(clock*2.1-.55)*cloth_strength*1.4
		joint_angles[18]=cloth_follow*1.6+sin(clock*2.1-1.1)*cloth_strength*1.6
		joint_angles[19]=sin(clock*2.1-.4)*.012
	if retreat_time>=0.0:
		var lean:=sin(clampf(retreat_time/.38,0,1)*PI)
		joint_angles[1]+=(.12 if hostile else -.12)*lean
		joint_angles[3]-=lean*.14; joint_angles[7]+=lean*.2
		motion_offset.y-=figure_height*.028*lean
	if death_time>=0.0:
		var collapse:=_ease(clampf(death_time/COLLAPSE_DURATION,0,1))
		joint_angles[0]=death_lean*collapse*.80
		joint_angles[1]=-death_lean*collapse*.18
		joint_angles[2]=death_lean*collapse*.2
		joint_angles[3]=collapse*.45; joint_angles[7]=-collapse*.35
		motion_offset.y=-figure_height*.28*collapse
		motion_offset.x=death_lean*figure_height*.20*collapse
	# Two-joint leg IK keeps stance soles on the floor while the pelvis breathes,
	# winds up or recoils. Swing feet lift; foot orientation stays level.
	var leg_targets: Array[Vector3]=[]
	for pair in range(2):
		var phase_value:=gait_phase+float(pair)*PI
		var contact_phase:=fposmod(phase_value,TAU)/TAU
		var swing:=contact_phase>=.5
		var amplitude:=PI/(2.0*(2.6 if boss else 3.5))
		var u: float=(contact_phase-.5)*2.0
		# Stance moves backwards at exactly projected travel speed. Hermite
		# swing shares its endpoint velocities and lifts without a foot snap.
		var step_x: float=amplitude*(1.0-4.0*contact_phase) if not swing else amplitude*(-1.0-2.0*u+12.0*u*u-8.0*u*u*u)
		var lift: float=pow(sin(u*PI),2)*.065*figure_height if swing else 0.0
		var limb:=10 if pair==0 else 13
		var target: Vector3=motion_rig.rest[limb+2]
		target.x=lerpf(target.x,motion_rig.rest[limb].x,gait_blend)
		target+=Vector3(step_x*gait_axis*gait_blend/maxf(scale.x,.01),lift*gait_blend,0)
		leg_targets.append(target)
	if death_time<0.0:
		var lower_pelvis:=0.0
		for pair in range(2):
			var limb:=10 if pair==0 else 13
			var hip: Vector3=motion_rig.rest[limb]+motion_offset
			var reach: float=motion_rig.local_rest[limb+1].length()+motion_rig.local_rest[limb+2].length()-.004
			var horizontal: float=absf(leg_targets[pair].x-hip.x)
			var vertical:=sqrt(maxf(0,reach*reach-horizontal*horizontal))
			lower_pelvis=maxf(lower_pelvis,hip.y-leg_targets[pair].y-vertical)
		motion_offset.y-=maxf(0,lower_pelvis)
	for pair in range(2): _leg_ik(10 if pair==0 else 13,leg_targets[pair])
	motion_rig.pose(joint_angles,motion_offset)
	if kind=="Ranger" and not hostile and death_time<0.0:
		var pull:=figure_height*.12*windup*recovery*(1.0-release)
		var string_point: Vector3=motion_rig.set_bow_draw(pull)
		if windup*recovery>.02:
			var initial_hand: Vector3=motion_rig.skeleton.get_bone_global_pose(9).origin
			var approach:=_ease(clampf(windup*recovery/.55,0,1))
			_reach_arm(7,initial_hand.lerp(string_point+Vector3(-.015,0,0),approach))
			motion_rig.pose(joint_angles,motion_offset)
			motion_rig.set_bow_draw(pull)
	surface_material.set_shader_parameter("pose_frame",float(pose_frame))

func _reach_arm(first: int,target: Vector3) -> void:
	var parent: Transform3D=motion_rig.skeleton.get_bone_global_pose(1)
	var goal: Vector3=parent.affine_inverse()*target-motion_rig.local_rest[first]
	var upper: Vector3=motion_rig.local_rest[first+1]
	var lower: Vector3=motion_rig.local_rest[first+2]
	var distance:=clampf(goal.length(),absf(upper.length()-lower.length())+.001,upper.length()+lower.length()-.001)
	var shoulder:=atan2(goal.y,goal.x)-acos(clampf((upper.length_squared()+distance*distance-lower.length_squared())/(2.0*upper.length()*distance),-1,1))
	var elbow:=Vector3(cos(shoulder),sin(shoulder),0)*upper.length()
	var forearm:=atan2(goal.y-elbow.y,goal.x-elbow.x)
	joint_angles[first]=wrapf(shoulder-atan2(upper.y,upper.x),-PI,PI)
	joint_angles[first+1]=wrapf(forearm-atan2(lower.y,lower.x)-joint_angles[first],-PI,PI)

func _leg_ik(first: int,target: Vector3) -> void:
	var root_anchor: Vector3=motion_rig.rest[0]
	var relative: Vector3=Basis(Vector3.BACK,-joint_angles[0])*(target-root_anchor-motion_offset)+root_anchor
	var hip: Vector3=motion_rig.rest[first]
	var upper: Vector3=motion_rig.rest[first+1]-hip
	var lower: Vector3=motion_rig.rest[first+2]-motion_rig.rest[first+1]
	var goal:=relative-hip
	var distance:=clampf(goal.length(),absf(upper.length()-lower.length())+.001,upper.length()+lower.length()-.001)
	var rest_cross:=upper.x*lower.y-upper.y*lower.x
	var bend:=1.0 if rest_cross<0.0 else -1.0
	var hip_angle:=atan2(goal.y,goal.x)+bend*acos(clampf((upper.length_squared()+distance*distance-lower.length_squared())/(2.0*upper.length()*distance),-1,1))
	var knee: Vector3=hip+Vector3(cos(hip_angle),sin(hip_angle),0)*upper.length()
	var shin_angle:=atan2(relative.y-knee.y,relative.x-knee.x)
	joint_angles[first]=hip_angle-atan2(upper.y,upper.x)
	joint_angles[first+1]=shin_angle-atan2(lower.y,lower.x)-joint_angles[first]
	joint_angles[first+2]=-joint_angles[0]-joint_angles[first]-joint_angles[first+1]

func _action_poses() -> Array:
	# upper arm, elbow, absolute blade/staff angle, off arm/elbow, chest.
	if boss:
		var weapon_windup: float=[-.85,-.25,-1.65,-1.60][region_index]
		var weapon_contact: float=[.35,.75,-.3,-.45][region_index]
		return [[-.62,-1.05,weapon_windup,.24,-.22,-.09],[-.18,-.42,weapon_contact,-.18,.1,.14]]
	if kind=="Vowkeeper" and attack_style in ["guard","aegis"]:
		return [[-.15,-.4,.9,-.4,-.55,.04],[.15,-.3,.6,-.6,-.45,-.06]]
	if kind=="Arcanist" and attack_style in ["starfall","signature"]:
		return [[.1,-.5,.4,-.5,-.55,.08],[.9,.5,.5,.7,-.3,-.10]]
	if kind=="Ranger" and attack_style=="rain":
		return [[.9,.5,1.4,-.48,-1.15,-.08],[.94,.5,1.42,-.05,-.7,-.06]]
	match kind:
		"Vowkeeper": return [[-.40,-1.20,2.60,-.12,-.20,.10],[1.10,.65,.70,.12,-.25,-.16]]
		"Arcanist": return [[.18,-.65,.24,-.32,-.50,.07],[.75,.42,-.58,.38,-.35,-.12]]
		"Ranger": return [[.70,.42,.85,-.48,-1.15,-.08],[.74,.46,.91,-.05,-.70,-.06]]
		"hexer": return [[-.35,-.45,-.32,.15,-.50,-.06],[-.15,-.55,.66,-.30,-.20,.10]]
		_: return [[-.48,-.65,-1.30,.25,-.2,-.10],[-.15,-.38,-.32,-.25,-.3,.14]]

static func _ease(t: float) -> float:
	return t*t*(3.0-2.0*t)
