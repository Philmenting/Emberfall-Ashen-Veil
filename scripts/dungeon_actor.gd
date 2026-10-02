extends Node3D
## Original Blender-authored models with articulated, simulation-driven animation.
static var merged_cache: Dictionary={}
static var appearance_cache: Dictionary={}
static var shared_surface: ShaderMaterial
var region_index := 0
var kind := "Vowkeeper"
var hostile := false
var boss := false
var body: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_knee: Node3D
var right_knee: Node3D
var cape: Node3D
var weapon: Node3D
var clock := 0.0
var gait_phase := 0.0
var gait_blend := 0.0
var rig: Skeleton3D
var rig_joints: Array[Node3D] = []
var left_forearm: Node3D
var right_forearm: Node3D
var head: Node3D
var cape_tip: Node3D
var attack_time := -1.0
var attack_queued := false
var attack_style := "basic"
var queued_attack_style := "basic"
var impact_time := -1.0
var death_time := -1.0
var death_lean := 1.0
var body_hunch := 0.0
var moving := false
var health_bar: MeshInstance3D
var materials: Dictionary = {}

func _ready() -> void:
	death_lean = -1.0 if (kind.hash()+region_index)%2==0 else 1.0
	body = _joint(self,"Body",Vector3.ZERO)
	var shoulders:=0.29 if kind in ["Arcanist","Ranger","hexer"] or (boss and region_index in [1,2]) else 0.33
	left_arm = _joint(body,"ArmL",Vector3(-shoulders,1.47,0))
	right_arm = _joint(body,"ArmR",Vector3(shoulders,1.47,0))
	left_leg = _joint(body,"LegL",Vector3(-0.18,0.89,0))
	right_leg = _joint(body,"LegR",Vector3(0.18,0.89,0))
	left_knee = _joint(left_leg,"KneeL",Vector3(0,-0.39,0))
	right_knee = _joint(right_leg,"KneeR",Vector3(0,-0.39,0))
	cape = _joint(body,"Cape",Vector3(0,1.5,0.21))
	left_forearm = _joint(left_arm,"ForearmL",Vector3(0,-0.28,0))
	right_forearm = _joint(right_arm,"ForearmR",Vector3(0,-0.28,0))
	weapon = _joint(right_forearm,"Weapon",Vector3(0,-0.26,0))
	head = _joint(body,"Head",Vector3(0,1.63,0))
	cape_tip = _joint(cape,"CapeTip",Vector3(0,-0.65,0.12))
	var joints := {"Body":body,"ArmL":left_arm,"ArmR":right_arm,"LegL":left_leg,
		"LegR":right_leg,"KneeL":left_knee,"KneeR":right_knee,"Cape":cape,"Weapon":weapon}
	joints.merge({"ForearmL":left_forearm,"ForearmR":right_forearm,"Head":head,"CapeTip":cape_tip})
	if shared_surface==null:
		shared_surface=ShaderMaterial.new()
		shared_surface.shader=preload("res://assets/shaders/forged_surface.gdshader")
		shared_surface.set_shader_parameter("vertex_materials",true)
		shared_surface.set_shader_parameter("aged_metal",preload("res://assets/materials/metal/Metal063_1K-JPG_Color.jpg"))
		shared_surface.set_shader_parameter("metal_roughness",preload("res://assets/materials/metal/Metal063_1K-JPG_Roughness.jpg"))
	var appearance_key:=str([kind,boss,region_index,"skinned-v2"])
	var builder := preload("res://scripts/character_rig.gd")
	rig=builder.create(self,joints)
	for part in joints: rig_joints.append(joints[part])
	if not merged_cache.has(appearance_key):
		var authored: Node3D=preload("res://scripts/authored_characters.gd").appearance(kind,boss,region_index).instantiate()
		merged_cache[appearance_key]=builder.bake(authored,rig,joints)
		authored.free()
	appearance_cache[appearance_key]=merged_cache[appearance_key]
	var model := _mesh(self,Vector3.ZERO,merged_cache[appearance_key],shared_surface)
	model.name="SkinnedCharacter"
	model.custom_aabb=model.mesh.get_aabb().grow(0.8)
	model.skeleton=model.get_path_to(rig)
	model.skin=rig.create_skin_from_rest_transforms()
	if boss: scale=Vector3.ONE*1.65
	elif kind=="hexer": scale=Vector3(0.82,1.10,0.82)
	elif kind in ["bulwark","elite"]: scale=Vector3(1.22,1.15,1.22)
	elif hostile: scale=Vector3(0.87,0.96,0.87)
	if hostile and kind=="raider": body_hunch=0.18
	_contact_shadow()

func _joint(parent: Node3D, label: String, at: Vector3) -> Node3D:
	var pivot:=Node3D.new()
	pivot.name=label
	pivot.position=at
	parent.add_child(pivot)
	return pivot

func _mat(color: Color, metal: float, glow: bool = false) -> Material:
	if glow:
		var emissive:=StandardMaterial3D.new()
		emissive.albedo_color=color
		emissive.emission_enabled=true
		emissive.emission=color
		emissive.emission_energy_multiplier=1.3
		emissive.set_meta("art_tint",color)
		emissive.set_meta("art_metal",metal)
		emissive.set_meta("art_glow",1.0)
		return emissive
	var mat:=ShaderMaterial.new()
	mat.shader=preload("res://assets/shaders/forged_surface.gdshader")
	mat.set_shader_parameter("tint",color)
	mat.set_shader_parameter("metal",metal)
	mat.set_shader_parameter("cloth",1.0 if metal==0.0 else 0.0)
	mat.set_meta("art_tint",color)
	mat.set_meta("art_metal",metal)
	mat.set_meta("art_glow",0.0)
	return mat

func _contact_shadow() -> void:
	var mat:=ShaderMaterial.new()
	mat.shader=preload("res://assets/shaders/ground_grime.gdshader")
	mat.set_shader_parameter("tint",Color(0.01,0.009,0.013,0.60))
	var mesh:=PlaneMesh.new()
	mesh.size=Vector2(1.3,1.0)
	var shadow:=_mesh(self,Vector3(0,0.028,0),mesh,mat)
	shadow.name="ContactShadow"
	shadow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _mesh(parent: Node3D,pos: Vector3,mesh: Mesh,mat: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = mat
	instance.position = pos
	parent.add_child(instance)
	return instance

func strike(style: String = "basic") -> void:
	if death_time>=0.0: return
	var requested_style := style if not style.is_empty() else "basic"
	if attack_time>=0.0:
		attack_queued=true
		queued_attack_style=requested_style
	else:
		attack_time=0.0
		attack_style=requested_style

func react() -> void:
	if death_time>=0.0 or impact_time>=0.0: return
	impact_time=0.0

func die() -> void:
	death_time = 0.0

func animate(delta: float, walking: bool, horizontal_speed: float = -1.0) -> void:
	clock += delta
	moving = walking
	if death_time >= 0.0:
		death_time += delta
		var fall:=1.0-exp(-death_time*4.2)
		body.rotation.z = death_lean*minf(death_time*2.8, PI*0.49)
		body.rotation.x = sin(death_time*8.0)*0.12*exp(-death_time*2.8)
		body.position.y = -minf(death_time*0.68,0.48)
		left_arm.rotation.x = -0.8*fall+sin(death_time*6.0)*0.22*exp(-death_time*3.0)
		right_arm.rotation.x = 0.45*fall-sin(death_time*6.0+0.8)*0.18*exp(-death_time*3.0)
		left_leg.rotation.x = death_lean*0.42*fall
		right_leg.rotation.x = -death_lean*0.32*fall
		cape.rotation.x = -0.15+0.38*fall
		left_forearm.rotation.x=-0.34*fall
		right_forearm.rotation.x=-0.58*fall
		head.rotation.z=death_lean*0.16*fall
		cape_tip.rotation.x=0.22*fall
		_sync_rig()
		return
	var speed:=clampf(horizontal_speed,0.0,6.0) if horizontal_speed>=0.0 else 3.2
	gait_blend=lerpf(gait_blend,1.0 if walking else 0.0,1.0-exp(-delta*12.0))
	var gait:=gait_blend
	if walking: gait_phase+=delta*speed*3.25
	var stride := sin(gait_phase)*0.49*gait
	var breath:=sin(clock*1.65)
	var bob:=(0.032+0.038*(0.5+0.5*cos(gait_phase*2.0)))*gait
	body.position = Vector3(sin(clock*0.83)*0.012, bob+breath*0.014*(1.0-gait), 0.0)
	left_leg.rotation.x = stride
	right_leg.rotation.x = -stride
	left_knee.rotation.x = maxf(0.0,-stride)*0.92
	right_knee.rotation.x = maxf(0.0,stride)*0.92
	left_arm.rotation.x = -0.18-stride*0.48
	right_arm.rotation.x = -0.25+stride*0.48
	left_arm.rotation.z = -0.035+sin(gait_phase)*0.035*gait
	right_arm.rotation.z = 0.035-sin(gait_phase)*0.035*gait
	body.rotation.x = body_hunch+sin(gait_phase)*0.035*gait+breath*0.008
	body.rotation.y = sin(gait_phase)*0.045*gait+sin(clock*0.72)*0.018*(1.0-gait)
	body.rotation.z = -sin(gait_phase)*0.035*gait
	cape.rotation.x = -0.15-absf(stride)*0.22
	cape.rotation.y = -sin(gait_phase)*0.035*gait
	cape.rotation.z = sin(gait_phase-0.8)*0.09*gait+sin(clock*2.1)*0.035
	left_forearm.rotation.x=-0.11-absf(stride)*0.16
	right_forearm.rotation.x=-0.16-absf(stride)*0.16
	head.rotation=Vector3(breath*0.015,-body.rotation.y*0.45,0)
	cape_tip.rotation.x=lerpf(cape_tip.rotation.x,-gait*0.20+sin(clock*2.1-0.8)*0.04,1.0-exp(-delta*7.0))
	if attack_time >= 0.0:
		attack_time += delta
		var phase := clampf(attack_time/0.62,0.0,1.0)
		var anticipation:=smoothstep(0.0,0.11,phase)*(1.0-smoothstep(0.18,0.38,phase))
		var follow_through:=smoothstep(0.25,0.48,phase)*(1.0-smoothstep(0.69,1.0,phase))
		var recovery:=smoothstep(0.67,0.80,phase)*(1.0-smoothstep(0.80,1.0,phase))
		right_forearm.rotation.x-=0.52*anticipation+0.18*follow_through
		left_forearm.rotation.x-=0.34*anticipation
		head.rotation.x-=0.06*anticipation
		cape_tip.rotation.x+=0.17*follow_through
		var guarding := attack_style in ["bastion","frost_ward","smoke"]
		var empowered := attack_style in ["signature","sunder","judgment","chain","starfall","rain","marked"]
		var power := 1.2 if empowered else 1.0
		if attack_style=="telegraph": power=1.12
		match kind:
			"Vowkeeper":
				if attack_style=="telegraph":
					_telegraph_pose(anticipation)
				elif guarding:
					# Bring the shield across the chest; the weapon stays ready behind it.
					left_arm.rotation.x += -0.88*anticipation-0.20*follow_through+0.15*recovery
					left_arm.rotation.z += -0.16*anticipation+0.28*follow_through
					right_arm.rotation.x += -0.18*anticipation-0.46*follow_through+0.10*recovery
					body.rotation.x += 0.10*anticipation-0.12*follow_through
					body.position.z += 0.06*anticipation
				else:
					right_arm.rotation.x += -0.50*anticipation-1.18*power*follow_through+0.26*recovery
					right_arm.rotation.z += 0.20*anticipation-0.48*power*follow_through
					left_arm.rotation.x += -0.18*anticipation-0.28*follow_through
					left_arm.rotation.z += -0.08*anticipation-0.24*follow_through
					body.rotation.x += 0.16*anticipation-0.31*power*follow_through+0.09*recovery
					body.rotation.y += -0.26*anticipation+0.66*power*follow_through-0.20*recovery
					body.position.z += -0.22*power*follow_through+0.08*recovery
			"Arcanist","hexer":
				if attack_style=="telegraph":
					_telegraph_pose(anticipation)
				elif guarding:
					left_arm.rotation.x += -0.82*anticipation-0.18*follow_through+0.14*recovery
					right_arm.rotation.x += -0.70*anticipation-0.22*follow_through+0.12*recovery
					body.rotation.x += 0.10*anticipation-0.08*follow_through
					body.rotation.y += -0.14*anticipation
				else:
					var overhead := 0.42 if attack_style=="starfall" else 0.0
					right_arm.rotation.x += (-0.68-overhead)*anticipation-0.45*power*follow_through+0.18*recovery
					left_arm.rotation.x += (-0.48-overhead*0.65)*anticipation-0.52*power*follow_through+0.12*recovery
					right_arm.rotation.z += 0.10*anticipation-0.18*follow_through
					left_arm.rotation.z += -0.12*anticipation+0.16*follow_through
					body.rotation.x += 0.06*anticipation-0.12*follow_through
					body.rotation.y += -0.12*anticipation+0.28*follow_through-0.12*recovery
					body.position.z += 0.04*anticipation+0.05*follow_through
			"Ranger":
				if attack_style=="telegraph":
					_telegraph_pose(anticipation)
				elif guarding:
					right_arm.rotation.x += -0.72*anticipation-0.16*follow_through+0.12*recovery
					left_arm.rotation.x += -0.34*anticipation-0.12*follow_through
					body.rotation.y += 0.24*anticipation-0.18*follow_through
					body.position.z += 0.14*anticipation
				else:
					var overhead := 0.36 if attack_style=="rain" else 0.0
					right_arm.rotation.x += (-0.46-overhead)*anticipation-0.68*power*follow_through+0.18*recovery
					left_arm.rotation.x += -0.30*anticipation-0.62*power*follow_through+0.10*recovery
					right_arm.rotation.z += 0.34*anticipation-0.26*follow_through
					left_arm.rotation.z += -0.18*anticipation+0.12*follow_through
					body.rotation.x += -0.06*anticipation+0.16*follow_through
					body.rotation.y += 0.16*anticipation-0.34*follow_through+0.10*recovery
					body.position.z += -0.19*power*follow_through+0.10*recovery
			_:
				if attack_style=="telegraph":
					_telegraph_pose(anticipation)
				else:
					var heavy := attack_style=="heavy"
					var force := 1.0 if heavy else 0.74
					right_arm.rotation.x += -0.48*anticipation-0.92*force*follow_through+0.24*recovery
					right_arm.rotation.z += 0.14*anticipation-0.34*force*follow_through
					left_arm.rotation.x += -0.18*anticipation-0.20*follow_through
					body.rotation.x += 0.12*anticipation-0.25*force*follow_through+0.08*recovery
					body.rotation.y += -0.16*anticipation+0.36*force*follow_through-0.13*recovery
					body.position.z += -0.16*force*follow_through+0.06*recovery
		if phase>=1.0:
			if attack_queued:
				attack_time=0.0
				attack_queued=false
				attack_style=queued_attack_style
			else:
				attack_time=-1.0
	if impact_time>=0.0:
		impact_time+=delta
		var flinch:=sin(clampf(impact_time/0.24,0.0,1.0)*PI)*exp(-impact_time*2.6)
		body.position.x+=death_lean*0.075*flinch
		body.rotation.z+=death_lean*0.14*flinch
		left_arm.rotation.x-=0.24*flinch
		right_arm.rotation.x+=0.18*flinch
		if impact_time>=0.24: impact_time=-1.0

	_sync_rig()

func _telegraph_pose(anticipation: float) -> void:
	if attack_style!="telegraph": return
	left_arm.rotation.x += -0.86*anticipation
	right_arm.rotation.x += -0.98*anticipation
	left_arm.rotation.z += -0.18*anticipation
	right_arm.rotation.z += 0.18*anticipation
	body.rotation.x += 0.12*anticipation

func _sync_rig() -> void:
	for bone in range(rig_joints.size()):
		var joint := rig_joints[bone]
		rig.set_bone_pose_position(bone,joint.position)
		rig.set_bone_pose_rotation(bone,joint.quaternion)
