extends Node3D
## Fully volumetric, opaque 3D characters. Native skeletons play authored clips;
## simulation events decide contact, warnings and death, never renderer clocks.
const Rig=preload("res://scripts/character_rig.gd")
const HEROES: Array[String]=["Vowkeeper","Arcanist","Ranger"]
const HOSTILES: Array[String]=["raider","bulwark","hexer","elite"]
const GEAR_RANKS: Dictionary={"COMMON":0,"UNCOMMON":1,"RARE":2,"EPIC":3,"LEGENDARY":4}
const GEAR_TINTS: Array[Color]=[Color("98794c"),Color("a5b393"),Color("93c4c6"),Color("b79ec6"),Color("e7bf79")]
const COLLAPSE_DURATION:=.90
static var appearance_cache: Dictionary={}
var region_index:=0
var kind:="Vowkeeper"
var hostile:=false
var boss:=false
var reduced_motion:=false
var figure_height:=2.15
var body: Node3D
var model: MeshInstance3D
var surface_material: ShaderMaterial
var motion_rig: RefCounted
var equipped_items: Dictionary={}
var equipment_grades: Dictionary={}
var materials: Dictionary={}
var appearance_key:=""
var clock:=0.0
var gait_phase:=0.0
var gait_blend:=0.0
var moving:=false
var attack_time:=-1.0
var attack_duration:=.30
var attack_queued:=false
var attack_style:="basic"
var queued_attack_style:="basic"
var external_release:=false
var release_time:=-1.0
var action_intensity:=1.0
var impact_time:=-1.0
var hit_strength:=0.0
var recoil_direction:=1.0
var recoil_intensity:=1.0
var recoil_duration:=.24
var death_time:=-1.0
var death_lean:=1.0
var pose_frame:=0
var boss_phase:=0
var telegraph_left:=0.0
var telegraph_duration:=0.0
var retreat_time:=-1.0
var anticipation:=0.0
var emphasis:=1.0
var silhouette_focus:=0.0
var motion_offset:=Vector3.ZERO
var desired_yaw:=0.0
var travel_direction:=Vector3.FORWARD
var last_clip:=""
var blend_age:=1.0
var blend_pose: Array[Transform3D]=[]
var plant_points: Array[Vector3]=[Vector3.ZERO,Vector3.ZERO]
var plant_active: Array[bool]=[false,false]
var stop_time:=-1.0
var stop_support:=-1

func _ready() -> void:
	desired_yaw=rotation.y
	body=Node3D.new(); body.name="CharacterBody"; add_child(body)
	_load_appearance()
	_contact_shadow()
	if not hostile and not boss: configure_equipment(equipped_items,kind)
	set_boss_phase(boss_phase)
	set_readability(1.0,.55 if not hostile and not boss else 0.0)
	_apply_motion(0.0)

func _load_appearance() -> void:
	appearance_key="guardian_%d" % clampi(region_index,0,3) if boss else kind
	if not appearance_key in HEROES+HOSTILES and not boss: appearance_key="raider"
	figure_height=4.6 if boss else (2.30 if kind in ["bulwark","elite"] else 2.15)
	if motion_rig!=null:
		motion_rig.player.free(); motion_rig.skeleton.free()
	motion_rig=Rig.new(); motion_rig.build(body,appearance_key)
	appearance_cache[appearance_key]=motion_rig.mesh
	body.scale=Vector3.ONE*figure_height/motion_rig.source_height
	if model==null:
		model=MeshInstance3D.new(); model.name="SkinnedCharacter"; body.add_child(model)
		model.extra_cull_margin=figure_height
		model.ignore_occlusion_culling=true
		surface_material=ShaderMaterial.new()
		surface_material.shader=preload("res://assets/shaders/character_surface.gdshader")
		surface_material.set_shader_parameter("face_albedo",preload("res://assets/materials/nyra-face/nyra-face-albedo.png"))
		surface_material.set_shader_parameter("field_surfaces",preload("res://assets/materials/field-surfaces/material-atlas.png"))
		surface_material.set_shader_parameter("metal_grain",preload("res://assets/materials/metal/Metal063_1K-JPG_Color.jpg"))
		surface_material.set_shader_parameter("metal_roughness",preload("res://assets/materials/metal/Metal063_1K-JPG_Roughness.jpg"))
		model.material_override=surface_material
	model.mesh=motion_rig.mesh; model.skin=motion_rig.skin
	model.skeleton=model.get_path_to(motion_rig.skeleton)
	last_clip=""; blend_pose.clear(); blend_age=1.0
	plant_active=[false,false]

func configure_equipment(equipment: Dictionary,class_key: String="") -> void:
	equipped_items=equipment.duplicate(true)
	if body==null:
		if class_key in HEROES: kind=class_key
		return
	if boss or hostile: return
	if class_key in HEROES and class_key!=kind:
		kind=class_key; _load_appearance(); _apply_motion(0.0)
	surface_material.set_shader_parameter("equipment_enabled",true)
	equipment_grades.clear()
	var uniforms: Dictionary={"Weapon":"weapon","Helmet":"helm","Chest":"chest","Gloves":"gloves","Boots":"boots","Amulet":"accent"}
	for slot in uniforms:
		var item: Dictionary=equipment.get(slot,equipment.get("Helm",{}) if slot=="Helmet" else {})
		var quality:=String(item.get("quality",item.get("rarity","COMMON"))).to_upper()
		var rank: int=GEAR_RANKS.get(quality,0)
		equipment_grades[slot]=rank
		surface_material.set_shader_parameter(uniforms[slot]+"_rank",float(rank))
		surface_material.set_shader_parameter(uniforms[slot]+"_tint",GEAR_TINTS[rank])

func set_boss_phase(value: int) -> void:
	boss_phase=clampi(value,0,2)
	if surface_material!=null:
		surface_material.set_shader_parameter("boss_surface",boss)
		surface_material.set_shader_parameter("boss_phase",float(boss_phase))

func visual_height() -> float:
	return figure_height*scale.y if death_time<0.0 else maxf(0.0,pose_bounds().end.y)*scale.y

func pose_bounds() -> AABB:
	return body.transform*motion_rig.bounds if motion_rig!=null else AABB()

func portrait_anchor() -> Vector3:
	return body.transform*(motion_rig.skeleton.get_bone_global_pose(3)*Vector3(0,.10,-.035)) if motion_rig!=null else Vector3(0,1.85,0)

func weapon_world_position(_camera_position: Vector3=Vector3.ZERO) -> Vector3:
	return body.to_global(motion_rig.weapon_tip())

func weapon_grip_position() -> Vector3:
	return body.to_global(motion_rig.skeleton.get_bone_global_pose(20).origin)

func face_toward(direction: Vector3,_camera_position: Vector3=Vector3.ZERO,force: bool=false) -> void:
	if death_time>=0.0 or direction.length_squared()<.0025: return
	if not force and (attack_time>=0.0 or telegraph_left>0.0): return
	desired_yaw=atan2(-direction.x,-direction.z)

func follow_travel(displacement: Vector3,_camera_position: Vector3=Vector3.ZERO) -> void:
	if displacement.length_squared()<.000001: return
	travel_direction=(global_basis.inverse()*displacement.normalized()).normalized()
	travel_direction.y=0.0

func strike(style: String="basic",windup_seconds: float=.30,wait_for_hit: bool=false) -> void:
	if death_time>=0.0: return
	if style=="heavy":
		telegraph_left=0.0; attack_queued=false; attack_time=0.0
		attack_style=style; release_time=0.0; external_release=false; pose_frame=4
		_apply_motion(0.0,true); return
	if wait_for_hit and release_time>=0.0:
		attack_time=-1.0; attack_queued=false
	if attack_time>=0.0:
		attack_queued=true; queued_attack_style=style
	else:
		attack_time=0.0; attack_style=style; release_time=-1.0
		attack_duration=maxf(.06,windup_seconds); external_release=wait_for_hit
		pose_frame=3

func sync_attack(remaining: float) -> void:
	if external_release and attack_time>=0.0 and release_time<0.0:
		attack_time=maxf(0.0,attack_duration-remaining)

func release_attack() -> bool:
	if death_time>=0.0 or attack_time<0.0 or release_time>=0.0: return false
	release_time=0.0; pose_frame=4
	_apply_motion(0.0,true)
	return true

func cancel_attack() -> void:
	if release_time<0.0:
		attack_time=-1.0; attack_queued=false; external_release=false

func retreat() -> void:
	cancel_attack(); retreat_time=0.0

func react(direction: float=0.0,intensity: float=1.0) -> void:
	if death_time>=0.0: return
	if impact_time<0.0 or intensity>recoil_intensity+.15:
		impact_time=0.0; recoil_direction=signf(direction) if absf(direction)>.05 else 1.0
		recoil_intensity=clampf(intensity,.35,1.5); recoil_duration=lerpf(.18,.30,clampf((intensity-.35)/1.15,0,1))

func react_from(source: Vector3,_camera_position: Vector3=Vector3.ZERO,intensity: float=1.0) -> void:
	var local: Vector3=global_basis.inverse()*(global_position-source)
	react(local.x if absf(local.x)>.10 else local.z,intensity)

func set_readability(value: float,focus: float=0.0) -> void:
	emphasis=clampf(value,.55,1.0); silhouette_focus=clampf(focus,0.0,1.0)
	if surface_material!=null:
		surface_material.set_shader_parameter("readability",emphasis)
		surface_material.set_shader_parameter("silhouette_focus",silhouette_focus)
		surface_material.set_shader_parameter("focus_tint",Color("f1dbac") if not hostile else Color("dcba80"))

func set_telegraph(remaining_seconds: float,total_seconds: float=-1.0) -> void:
	if total_seconds>0.0: telegraph_duration=total_seconds
	elif remaining_seconds>telegraph_left+.05: telegraph_duration=remaining_seconds
	telegraph_left=maxf(remaining_seconds,0.0)
	if telegraph_left>0.0 and death_time<0.0: pose_frame=3

func die() -> void:
	if death_time>=0.0: return
	death_time=0.0; attack_time=-1.0; release_time=-1.0
	attack_queued=false; telegraph_left=0.0; plant_active=[false,false]

func animate(delta: float,walking: bool,horizontal_speed: float=-1.0) -> void:
	if body==null: return
	delta=maxf(0.0,delta)
	if not reduced_motion: clock+=delta
	if death_time>=0.0:
		death_time+=delta; pose_frame=5 if death_time>=COLLAPSE_DURATION else 0
		_apply_motion(delta)
		if death_time>=COLLAPSE_DURATION: set_readability(lerpf(1.0,.60,smoothstep(.90,1.60,death_time)),0.0)
		return
	rotation.y=lerp_angle(rotation.y,desired_yaw,1.0-exp(-delta*10.0))
	if walking and not moving and gait_blend<.10:
		gait_phase=PI*.5
		plant_active=[false,false]
	if moving and not walking:
		stop_time=0.0; stop_support=0 if fposmod(gait_phase,TAU)<PI else 1
	moving=walking
	if walking: stop_time=-1.0
	elif stop_time>=0.0: stop_time+=delta
	gait_blend=lerpf(gait_blend,1.0 if walking else 0.0,1.0-exp(-delta*12.0))
	if walking:
		var speed:=clampf(horizontal_speed,0.0,6.0) if horizontal_speed>=0.0 else 3.2
		gait_phase+=delta*speed/body.scale.x*TAU/1.60
	pose_frame=1+int(floor(gait_phase/PI))%2 if gait_blend>.22 else 0
	action_intensity=1.20 if attack_style in ["signature","sunder","judgment","chain","starfall","rain","marked"] else 1.0
	if telegraph_left>0.0: pose_frame=3
	elif attack_time>=0.0:
		if release_time>=0.0: release_time+=delta
		elif not external_release:
			attack_time+=delta
			if attack_time>=attack_duration: release_time=maxf(0.0,attack_time-attack_duration)
		pose_frame=3 if release_time<0.0 else (4 if release_time<.14 else 0)
		if release_time>=Rig.Clips.RECOVERY:
			attack_time=-1.0; release_time=-1.0; external_release=false
			if attack_queued:
				attack_queued=false; strike(queued_attack_style)
	if retreat_time>=0.0:
		retreat_time+=delta
		if retreat_time>.32: retreat_time=-1.0
	if impact_time>=0.0:
		impact_time+=delta
		if impact_time>=recoil_duration: impact_time=-1.0
	_apply_motion(delta)

func _apply_motion(delta: float=0.0,contact: bool=false) -> void:
	var clip:="idle"; var time:=fposmod(clock,4.2) if not reduced_motion else 0.0
	var action:="skill" if action_intensity>1.05 else "basic"
	if death_time>=0.0: clip="death"; time=minf(death_time,COLLAPSE_DURATION)
	elif telegraph_left>0.0:
		clip="windup_heavy"; time=clampf(1.0-telegraph_left/maxf(telegraph_duration,.001),0,1)
	elif attack_time>=0.0:
		if attack_style=="heavy": action="heavy"
		if release_time<0.0: clip="windup_"+action; time=clampf(attack_time/attack_duration,0,1)
		else: clip="recover_"+action; time=minf(release_time,Rig.Clips.RECOVERY)
	elif gait_blend>.04:
		clip="walk"; time=fposmod(gait_phase,TAU)/TAU
	if clip!=last_clip:
		blend_pose=motion_rig.capture_pose(); blend_age=0.0
		last_clip=clip
	motion_rig.pose(clip,time)
	if contact: blend_age=1.0
	else: blend_age+=delta
	if blend_age<.10 and not blend_pose.is_empty(): motion_rig.blend_from(blend_pose,smoothstep(0,.10,blend_age))
	if clip=="walk": _plant_feet()
	elif stop_time<0.0 or stop_time>.24: plant_active=[false,false]
	hit_strength=sin(clampf(impact_time/recoil_duration,0,1)*PI)*recoil_intensity if impact_time>=0.0 and death_time<0.0 else 0.0
	if hit_strength>0.0 and not reduced_motion:
		var influence:=.25 if attack_time>=0.0 or telegraph_left>0.0 else 1.0
		var skeleton: Skeleton3D=motion_rig.skeleton
		var chest:=skeleton.get_bone_pose_rotation(2)
		skeleton.set_bone_pose_rotation(2,chest*Quaternion.from_euler(Vector3(.04,0,.045*recoil_direction)*hit_strength*influence))
		skeleton.set_bone_pose_position(0,skeleton.get_bone_pose_position(0)+Vector3(.035*recoil_direction,0,.018)*hit_strength*influence)
		skeleton.force_update_all_bone_transforms()
	motion_offset=motion_rig.skeleton.get_bone_pose_position(0)
	surface_material.set_shader_parameter("hit_flash",hit_strength*.32)
	surface_material.set_shader_parameter("action_intensity",action_intensity)
	motion_rig.refresh_bounds()

func _plant_feet() -> void:
	var skeleton: Skeleton3D=motion_rig.skeleton
	var phase:=fposmod(gait_phase,TAU)/TAU
	var yaw:=atan2(-travel_direction.x,-travel_direction.z)
	var direction_basis:=Basis(Vector3.UP,yaw)
	for side in range(2):
		var foot_index:=14 if side==0 else 17
		var offset: Vector3=motion_rig.rest[foot_index].origin
		var target: Vector3=skeleton.get_bone_global_pose(foot_index).origin
		target=offset+direction_basis*(target-offset)
		var supporting:=fposmod(phase+side*.5,1.0)<.5
		if not moving: supporting=side==stop_support and stop_time<.20
		if supporting:
			if not plant_active[side]: plant_points[side]=body.to_global(target); plant_active[side]=true
			target=body.to_local(plant_points[side])
		else:
			plant_active[side]=false
			if not moving:
				target=target.lerp(offset,smoothstep(0,.20,stop_time))
				target.y=maxf(target.y,offset.y+sin(clampf(stop_time/.20,0,1)*PI)*.035)
		motion_rig.solve_leg(side,target,direction_basis*Vector3.FORWARD)

func _contact_shadow() -> void:
	var material:=ShaderMaterial.new(); material.shader=preload("res://assets/shaders/ground_grime.gdshader")
	material.set_shader_parameter("tint",Color(.01,.009,.013,.48))
	var mesh:=PlaneMesh.new(); mesh.size=Vector2(2.2,1.2) if boss else Vector2(1.10,.66)
	var shadow:=MeshInstance3D.new(); shadow.name="ContactShadow"
	shadow.mesh=mesh; shadow.material_override=material; shadow.position.y=.028
	shadow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)
