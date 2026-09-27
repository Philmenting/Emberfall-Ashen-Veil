extends Node3D
## Original articulated models. Geometry and animation are authored in Godot.
const ThemeData = preload("res://scripts/dungeon_theme.gd")
static var merged_cache: Dictionary={}
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
var attack_time := -1.0
var death_time := -1.0
var moving := false
var health_bar: MeshInstance3D
var materials: Dictionary = {}

func _ready() -> void:
	var theme := ThemeData.definition(region_index)
	var accent := Color("b18b57")
	if kind == "Arcanist": accent = Color("9170bd")
	if kind == "Ranger": accent = Color("579b7f")
	if hostile: accent = Color(theme.enemy)
	if kind=="hexer": accent = Color(theme.enemy).lightened(0.15)
	if kind=="bulwark": accent = Color("8d7954")
	if kind=="elite": accent = Color("d15b2e")
	materials.metal = _mat(Color("303c49") if not hostile else Color("30282b"), 0.72)
	materials.edge = _mat(Color("adb7b7") if not hostile else Color("79685b"), 0.8)
	materials.cloth = _mat(accent.darkened(0.55), 0.0)
	materials.trim = _mat(accent, 0.65)
	materials.leather = _mat(Color("211e22"), 0.0)
	materials.bone = _mat(Color("a19b84"),0.0)
	materials.skin = _mat(Color("c1aa95") if not hostile else Color(theme.skin), 0.0)
	materials.glow = _mat(Color("81d9e6") if not hostile else Color(theme.glow), 0.0, true)
	for key in materials: materials[key].resource_name=key
	body = Node3D.new()
	body.name="Body"
	add_child(body)
	# Human proportions, fitted cuirasses and layered cloth, authored as ring meshes.
	var caster: bool=kind in ["Arcanist","hexer"]
	var ranger: bool=kind=="Ranger"
	var ghoul: bool=hostile and kind=="raider"
	_profile(body,[Vector4(0.9,0.20,0.15,0),Vector4(1.04,0.21,0.16,0),Vector4(1.32,0.31,0.20,0),Vector4(1.51,0.28,0.16,0),Vector4(1.6,0.16,0.12,0)],materials.skin if ghoul else materials.cloth if caster or ranger else materials.metal)
	if not ghoul:
		_profile(body,[Vector4(0.88,0.22,0.17,0),Vector4(0.97,0.23,0.18,0)],materials.leather)
		_sphere(body,Vector3(0,0.93,-0.18),Vector3(0.065,0.065,0.025),materials.trim)
		if caster:
			_profile(body,[Vector4(0.13,0.38,0.25,0.04),Vector4(0.40,0.32,0.23,0),Vector4(0.85,0.21,0.16,0)],materials.cloth)
			for side in [-1.0,1.0]:
				var stole:=_profile(body,[Vector4(0.30,0.055,0.015,0),Vector4(1.35,0.06,0.02,0)],materials.trim)
				stole.position=Vector3(side*0.13,0,-0.21)
		else:
			for side in [-1.0,1.0]:
				var tasset:=_profile(body,[Vector4(0.62,0.13,0.055,0),Vector4(0.87,0.15,0.065,0)],materials.leather if ranger else materials.metal)
				tasset.position=Vector3(side*0.18,0,-0.14)
				tasset.rotation.z=side*0.12
	# Sculpted neck, narrow jaw and brow; less oversized helmet/head mass.
	_cylinder(body,Vector3(0,1.65,0),0.075,0.09,0.20,materials.skin,12)
	_profile(body,[Vector4(1.65,0.075,0.08,-0.05),Vector4(1.72,0.125,0.13,-0.025),Vector4(1.87,0.145,0.14,0),Vector4(1.98,0.08,0.09,0.015)],materials.skin)
	if caster or ranger:
		_profile(body,[Vector4(1.67,0.17,0.16,0.065),Vector4(1.89,0.19,0.16,0.06),Vector4(2.05,0.07,0.07,0.08)],materials.cloth)
		_sphere(body,Vector3(0,1.80,-0.115),Vector3(0.105,0.135,0.04),materials.skin if not hostile else materials.leather)
	elif not ghoul:
		_profile(body,[Vector4(1.68,0.16,0.15,0.015),Vector4(1.9,0.17,0.16,0),Vector4(2.03,0.065,0.075,0)],materials.metal)
		_box(body,Vector3(0,1.79,-0.158),Vector3(0.26,0.025,0.018),materials.leather)
		_box(body,Vector3(0,1.72,-0.16),Vector3(0.025,0.16,0.025),materials.edge)
	for side in [-1.0,1.0]:
		_sphere(body,Vector3(side*0.059,1.81,-0.156),Vector3(0.027,0.013,0.01),materials.glow if hostile else materials.leather)
	if hostile and not ghoul and not caster:
		for side in [-1.0,1.0]:
			var horn:=_profile(body,[Vector4(0,0.065,0.06,0),Vector4(0.22,0.035,0.04,0.03),Vector4(0.40,0.003,0.005,0.11)],materials.bone)
			horn.position=Vector3(side*0.17,1.9,0.02)
			horn.rotation.z=-side*0.6
	left_arm = _arm(-1.0)
	right_arm = _arm(1.0)
	left_leg = _leg(-1.0)
	right_leg = _leg(1.0)
	left_knee = left_leg.get_child(1)
	right_knee = right_leg.get_child(1)
	cape = Node3D.new()
	cape.name="Cape"
	cape.position = Vector3(0,1.5,0.21)
	body.add_child(cape)
	if not ghoul:
		_profile(cape,[Vector4(-1.13,0.34,0.035,0.22),Vector4(-0.65,0.30,0.03,0.10),Vector4(0,0.22,0.03,0)],materials.cloth)
		for side in [-1.0,1.0]:
			var hem:=_profile(cape,[Vector4(-1.12,0.018,0.02,0.22),Vector4(-0.65,0.018,0.02,0.10),Vector4(0,0.016,0.02,0)],materials.trim)
			hem.position.x=side*0.26
	weapon = Node3D.new()
	weapon.name="Weapon"
	weapon.position = Vector3(0,-0.54,0)
	right_arm.add_child(weapon)
	if (kind == "Arcanist" and not hostile) or kind=="hexer":
		_cylinder(weapon,Vector3(0,0.37,0),0.036,0.025,1.8,materials.trim,8)
		_sphere(weapon,Vector3(0,1.34,0),Vector3.ONE*0.13,materials.glow)
		for side in [-1.0,1.0]:
			var claw := _box(weapon,Vector3(side*0.14,1.26,0),Vector3(0.04,0.36,0.06),materials.edge)
			claw.rotation.z = -side*0.4
	elif kind == "Ranger" and not hostile:
		for i in range(8):
			var angle := -1.2+float(i)*2.4/7.0
			var bow := _box(weapon,Vector3(0, sin(angle)*0.65, -cos(angle)*0.32),Vector3(0.065,0.23,0.07),materials.trim)
			bow.rotation.x = -angle*0.4
		_box(weapon,Vector3(0,0,-0.11),Vector3(0.014,1.23,0.014),materials.edge)
	elif ghoul:
		for finger in range(3):
			var claw:=_profile(weapon,[Vector4(-0.30,0.002,0.003,-0.05),Vector4(0,0.025,0.025,0)],materials.bone)
			claw.position.x=(finger-1)*0.06
	else:
		_box(weapon,Vector3(0,-0.09,0),Vector3(0.09,0.3,0.09),materials.leather)
		_box(weapon,Vector3(0,0.10,0),Vector3(0.40,0.085,0.10),materials.trim)
		var blade := _profile(weapon,[Vector4(0.16,0.095,0.025,0),Vector4(0.96,0.065,0.017,0),Vector4(1.27,0.002,0.002,0)],materials.edge,4)
		blade.rotation.z = 0.015
		_box(weapon,Vector3(0,0.67,-0.035),Vector3(0.027,0.85,0.012),materials.glow)
		_cylinder(weapon,Vector3(0,1.31,0),0.085,0,0.18,materials.edge,4)
		if not hostile or kind in ["bulwark","elite","boss"]:
			var shield := _profile(left_arm,[Vector4(-0.86,0.035,0.025,0),Vector4(-0.63,0.25,0.065,0),Vector4(-0.20,0.30,0.075,0),Vector4(-0.07,0.19,0.06,0)],materials.metal,8)
			shield.position=Vector3(-0.08,0,-0.18)
			_box(left_arm,Vector3(-0.08,-0.43,-0.26),Vector3(0.025,0.61,0.025),materials.trim)
	if boss:
		scale = Vector3.ONE * 1.65
		_build_boss_regalia()
	elif kind=="hexer":
		scale = Vector3(0.82,1.10,0.82)
		_cylinder(body,Vector3(0,0.57,0),0.40,0.25,0.85,materials.cloth,10)
	elif kind=="bulwark" or kind=="elite": scale = Vector3(1.22,1.15,1.22)
	elif hostile: scale = Vector3(0.87,0.96,0.87)
	if ghoul:
		body.rotation.x=0.18
		for side in [-1.0,1.0]:
			for rib in range(4):
				var bone:=_box(body,Vector3(side*0.15,1.19+rib*0.075,-0.17),Vector3(0.23,0.025,0.025),materials.bone)
				bone.rotation.z=-side*0.25
	_merge_rigid_parts(self)
	_contact_shadow()

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

func _profile(parent: Node3D,rings: Array,mat: Material,sides: int=16) -> MeshInstance3D:
	return _mesh(parent,Vector3.ZERO,preload("res://scripts/sculpted_mesh.gd").profile(rings,sides),mat)

func _contact_shadow() -> void:
	var mat:=ShaderMaterial.new()
	mat.shader=preload("res://assets/shaders/ground_grime.gdshader")
	mat.set_shader_parameter("tint",Color(0.01,0.009,0.013,0.60))
	var mesh:=PlaneMesh.new()
	mesh.size=Vector2(1.3,1.0)
	var shadow:=_mesh(self,Vector3(0,0.028,0),mesh,mat)
	shadow.name="ContactShadow"
	shadow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _box(parent: Node3D, pos: Vector3, dimensions: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	return _mesh(parent,pos,mesh,mat)

func _cylinder(parent: Node3D,pos: Vector3,bottom: float,top: float,height: float,mat: Material,sides: int = 12) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	mesh.radial_segments = sides
	return _mesh(parent,pos,mesh,mat)

func _sphere(parent: Node3D,pos: Vector3,dimensions: Vector3,mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 12
	mesh.rings = 6
	var instance := _mesh(parent,pos,mesh,mat)
	instance.scale = dimensions * 2.0
	return instance

func _mesh(parent: Node3D,pos: Vector3,mesh: Mesh,mat: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = mat
	instance.position = pos
	parent.add_child(instance)
	return instance

func _arm(side: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.name="ArmL" if side<0 else "ArmR"
	pivot.position = Vector3(side*0.33,1.47,0)
	body.add_child(pivot)
	_sphere(pivot,Vector3(side*0.03,0,0),Vector3(0.18,0.13,0.19),materials.edge)
	_sphere(pivot,Vector3(side*0.03,0.025,0),Vector3(0.16,0.12,0.17),materials.metal)
	_cylinder(pivot,Vector3(0,-0.21,0),0.085,0.10,0.32,materials.leather)
	var bracer:=_profile(pivot,[Vector4(-0.56,0.08,0.075,-0.02),Vector4(-0.29,0.115,0.105,-0.02)],materials.metal)
	for i in range(2):
		_cylinder(pivot,Vector3(0,-0.35-i*0.15,-0.02),0.116-i*0.012,0.116-i*0.012,0.035,materials.trim,12)
	_sphere(pivot,Vector3(0,-0.59,-0.02),Vector3.ONE*0.10,materials.leather)
	return pivot

func _leg(side: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.name="LegL" if side<0 else "LegR"
	pivot.position = Vector3(side*0.18,0.89,0)
	body.add_child(pivot)
	_cylinder(pivot,Vector3(0,-0.20,0),0.11,0.14,0.40,materials.leather)
	var knee := Node3D.new()
	knee.name="Knee"
	knee.position.y = -0.39
	pivot.add_child(knee)
	_sphere(knee,Vector3(0,0,-0.055),Vector3(0.13,0.12,0.13),materials.edge)
	_cylinder(knee,Vector3(0,-0.20,0),0.10,0.13,0.34,materials.metal)
	_box(knee,Vector3(0,-0.40,-0.07),Vector3(0.19,0.13,0.32),materials.leather)
	_box(knee,Vector3(0,-0.365,-0.18),Vector3(0.195,0.07,0.17),materials.edge)
	return pivot

func strike() -> void:
	attack_time = 0.0

func die() -> void:
	death_time = 0.0

func animate(delta: float, walking: bool) -> void:
	clock += delta
	moving = walking
	if death_time >= 0.0:
		death_time += delta
		body.rotation.z = minf(death_time * 2.6, PI*0.48)
		body.position.y = -minf(death_time*0.5,0.32)
		return
	var stride := sin(clock*10.0) * (0.65 if walking else 0.025)
	body.position.y = absf(sin(clock*10.0))*0.055 if walking else sin(clock*2.0)*0.012
	left_leg.rotation.x = stride
	right_leg.rotation.x = -stride
	left_knee.rotation.x = maxf(0.0,-stride)*1.1
	right_knee.rotation.x = maxf(0.0,stride)*1.1
	left_arm.rotation.x = -stride*0.65
	right_arm.rotation.x = stride*0.65 - 0.25
	body.rotation.y = sin(clock*10.0)*0.07 if walking else 0.0
	cape.rotation.x = -0.15-absf(stride)*0.3
	cape.rotation.z = sin(clock*5.0)*0.045
	if attack_time >= 0.0:
		attack_time += delta
		var phase := clampf(attack_time/0.75,0.0,1.0)
		right_arm.rotation.x = -sin(phase*PI)*2.4
		right_arm.rotation.z = sin(phase*TAU)*0.65
		body.rotation.y = sin(phase*TAU)*0.4
		if kind in ["Arcanist","hexer"]:
			right_arm.rotation.x=-0.3-sin(phase*PI)*0.9
			left_arm.rotation.x=-0.8-sin(phase*PI)*0.5
			body.rotation.y=sin(phase*TAU)*0.15
		elif kind=="Ranger":
			right_arm.rotation.x=-1.1
			left_arm.rotation.x=-1.25
			right_arm.rotation.z=0.35+sin(phase*PI)*0.25
		if attack_time > 0.75:
			attack_time = -1.0
	else:
		right_arm.rotation.z = 0.0

func _build_boss_regalia() -> void:
	# Each region's boss has a silhouette readable from the following camera.
	match region_index:
		0:
			for side in [-1.0,1.0]:
				_cylinder(body,Vector3(side*0.57,1.85,0),0.18,0.10,0.35,materials.trim,8)
		1:
			_cylinder(body,Vector3(0,0.69,0),0.53,0.27,1.15,materials.cloth,12)
			_cylinder(body,Vector3(0,2.06,0),0.29,0.09,0.68,materials.cloth,6)
			for side in [-1.0,1.0]:
				_box(body,Vector3(side*0.26,1.15,-0.30),Vector3(0.11,0.9,0.04),materials.trim)
		2:
			for i in range(7):
				var angle:=float(i)*TAU/7.0
				_cylinder(body,Vector3(sin(angle)*0.25,2.19,cos(angle)*0.25),0.065,0.0,0.50,materials.edge,5)
			for side in [-1.0,1.0]:
				var rib:=_box(body,Vector3(side*0.66,1.75,0.12),Vector3(0.65,0.10,0.16),materials.skin)
				rib.rotation.z=side*0.6
		3:
			for side in [-1.0,1.0]:
				var vent:=_box(body,Vector3(side*0.38,1.78,0.18),Vector3(0.20,0.68,0.24),materials.metal)
				vent.rotation.z=-side*0.22
				_sphere(body,Vector3(side*0.43,2.16,0.18),Vector3(0.11,0.17,0.11),materials.glow)
			_box(body,Vector3(0,1.36,-0.31),Vector3(0.20,0.28,0.03),materials.glow)

func _merge_rigid_parts(pivot: Node3D) -> void:
	# Keep animated joints, merge only static meshes attached to each joint.
	# The authored silhouette and materials stay intact with fewer draw calls.
	var groups: Dictionary = {}
	var meshes: Array[MeshInstance3D] = []
	_collect_rigid_meshes(pivot,pivot,groups,meshes)
	if not groups.is_empty():
		var key:=str([kind,hostile,boss,region_index,get_path_to(pivot),"vertex-materials"])
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
					var uv: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
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
