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
	weapon = _joint(right_arm,"Weapon",Vector3(0,-0.54,0))
	var joints := {"Body":body,"ArmL":left_arm,"ArmR":right_arm,"LegL":left_leg,
		"LegR":right_leg,"KneeL":left_knee,"KneeR":right_knee,"Cape":cape,"Weapon":weapon}
	var appearance_key:=str([kind,boss,region_index])
	if appearance_cache.has(appearance_key):
		for part in appearance_cache[appearance_key]:
			_mesh(joints[part],Vector3.ZERO,appearance_cache[appearance_key][part],shared_surface)
	else:
		_build_authored(joints)
		_merge_rigid_parts(self)
		var parts: Dictionary={}
		for part in joints:
			for child in joints[part].get_children():
				if child is MeshInstance3D: parts[part]=child.mesh
		appearance_cache[appearance_key]=parts
	if boss: scale=Vector3.ONE*1.65
	elif kind=="hexer": scale=Vector3(0.82,1.10,0.82)
	elif kind in ["bulwark","elite"]: scale=Vector3(1.22,1.15,1.22)
	elif hostile: scale=Vector3(0.87,0.96,0.87)
	if hostile and kind=="raider": body_hunch=0.18
	_contact_shadow()

func _build_authored(joints: Dictionary) -> void:
	var authored: Node3D = preload("res://scripts/authored_characters.gd").appearance(kind,boss,region_index).instantiate()
	for source in authored.find_children("*","MeshInstance3D",true,false):
		var part: String = String(source.name).get_slice("__",0)
		assert(joints.has(part),"Unknown authored character pivot: "+part)
		# Blender exports one mesh per material and animated part. Transfer its
		# evaluated local geometry; animation retains the same joints and timing.
		for surface in range(source.mesh.get_surface_count()):
			var imported: StandardMaterial3D = source.mesh.surface_get_material(surface)
			var color: Color = imported.albedo_color
			var mat := _mat(color,imported.metallic,imported.emission_enabled)
			mat.resource_name=imported.resource_name
			var mesh := ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,source.mesh.surface_get_arrays(surface))
			var piece := _mesh(joints[part],Vector3.ZERO,mesh,mat)
			piece.transform=source.transform
	authored.free()
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
		return
	var speed:=maxf(horizontal_speed,2.5) if horizontal_speed>=0.0 else 3.2
	var gait:=1.0 if walking else 0.0
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
	if attack_time >= 0.0:
		attack_time += delta
		var phase := clampf(attack_time/0.62,0.0,1.0)
		var anticipation:=1.0-smoothstep(0.0,0.27,phase)
		var follow_through:=smoothstep(0.25,0.48,phase)*(1.0-smoothstep(0.69,1.0,phase))
		var recovery:=smoothstep(0.67,1.0,phase)
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

func _telegraph_pose(anticipation: float) -> void:
	if attack_style!="telegraph": return
	left_arm.rotation.x += -0.86*anticipation
	right_arm.rotation.x += -0.98*anticipation
	left_arm.rotation.z += -0.18*anticipation
	right_arm.rotation.z += 0.18*anticipation
	body.rotation.x += 0.12*anticipation

func _merge_rigid_parts(pivot: Node3D) -> void:
	# Keep animated joints, merge only static meshes attached to each joint.
	# The authored silhouette and materials stay intact with fewer draw calls.
	var groups: Dictionary = {}
	var meshes: Array[MeshInstance3D] = []
	_collect_rigid_meshes(pivot,pivot,groups,meshes)
	if not groups.is_empty():
		var key:=str([kind,hostile,boss,region_index,get_path_to(pivot),"authored-materials-v1"])
		if not merged_cache.has(key):
			var surface:=SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			for group in groups.values():
				var tint: Color=group.material.get_meta("art_tint",Color.WHITE)
				var packed_material:=Vector2(group.material.get_meta("art_metal",0.0),group.material.get_meta("art_glow",0.0))
				for entry in group.entries:
					var arrays: Array=entry.mesh.surface_get_arrays(0)
					var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
					var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
					var uv: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV]!=null else PackedVector2Array()
					var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
					var normal_basis: Basis=entry.transform.basis.inverse().transposed()
					for i in range(indices.size() if not indices.is_empty() else vertices.size()):
						var index: int=indices[i] if not indices.is_empty() else i
						surface.set_color(tint)
						surface.set_uv2(packed_material)
						surface.set_uv(uv[index] if index<uv.size() else Vector2.ZERO)
						surface.set_normal((normal_basis*normals[index]).normalized())
						surface.add_vertex(entry.transform*vertices[index])
			surface.index()
			merged_cache[key]=surface.commit()
		if shared_surface==null:
			shared_surface=ShaderMaterial.new()
			shared_surface.shader=preload("res://assets/shaders/forged_surface.gdshader")
			shared_surface.set_shader_parameter("vertex_materials",true)
			shared_surface.set_shader_parameter("aged_metal",preload("res://assets/materials/metal/Metal063_1K-JPG_Color.jpg"))
			shared_surface.set_shader_parameter("metal_roughness",preload("res://assets/materials/metal/Metal063_1K-JPG_Roughness.jpg"))
		var combined:=MeshInstance3D.new()
		combined.mesh=merged_cache[key]
		combined.material_override=shared_surface
		pivot.add_child(combined)
	# Remove deepest children first so nested shield details are merged once.
	meshes.reverse()
	for mesh in meshes:
		mesh.get_parent().remove_child(mesh)
		mesh.queue_free()

func _collect_rigid_meshes(pivot: Node3D,parent: Node3D,groups: Dictionary,meshes: Array[MeshInstance3D]) -> void:
	for child in parent.get_children():
		if child is MeshInstance3D:
			var mat: Material=child.material_override
			var key:=mat.get_instance_id()
			if not groups.has(key): groups[key]={"material":mat,"entries":[]}
			var local_transform:=Transform3D.IDENTITY
			var cursor: Node3D=child
			while cursor!=pivot:
				local_transform=cursor.transform*local_transform
				cursor=cursor.get_parent()
			groups[key].entries.append({"mesh":child.mesh,"transform":local_transform})
			meshes.append(child)
			_collect_rigid_meshes(pivot,child,groups,meshes)
		elif child is Node3D:
			_merge_rigid_parts(child)
