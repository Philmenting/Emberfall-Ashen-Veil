extends Node3D
## Weighted anatomical meshes with original articulated armor and weapons.
const ThemeData = preload("res://scripts/dungeon_theme.gd")
static var merged_cache: Dictionary={}
static var shared_surface: ShaderMaterial
var anatomy: Skeleton3D
var anatomy_bones: Dictionary={}
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
	death_lean=-1.0 if (kind.hash()+region_index)%2==0 else 1.0
	var theme:=ThemeData.definition(region_index)
	var accent:=Color("b18b57")
	if kind=="Arcanist": accent=Color("9170bd")
	if kind=="Ranger": accent=Color("579b7f")
	if hostile: accent=Color(theme.enemy)
	if kind=="bulwark": accent=Color("8d7954")
	if kind=="elite": accent=Color("d15b2e")
	materials.metal=_mat(Color("424c57") if not hostile else Color("403438"),0.78)
	materials.edge=_mat(Color("aeb8bc") if not hostile else Color("978775"),0.82)
	materials.cloth=_mat(accent.darkened(0.42),0.0)
	materials.trim=_mat(accent,0.7)
	materials.leather=_mat(Color("423132"),0.0,false,1.0)
	materials.bone=_mat(Color("b7ad91"),0.0,false,3.0)
	materials.skin=_mat(Color("c1aa95") if not hostile else Color(theme.skin),0.0,false,2.0)
	materials.glow=_mat(Color("81d9e6") if not hostile else Color(theme.glow),0.0,true)
	materials.hair=_mat(Color("332a27"),0.0,false,1.0)
	for key in materials: materials[key].resource_name=key
	body=Node3D.new()
	body.name="Body"
	add_child(body)
	var caster: bool=kind in ["Arcanist","hexer"]
	var ranger: bool=kind=="Ranger"
	var ghoul: bool=hostile and kind=="raider"
	left_arm=_arm(-1.0)
	right_arm=_arm(1.0)
	left_leg=_leg(-1.0)
	right_leg=_leg(1.0)
	left_knee=left_leg.get_node("Knee")
	right_knee=right_leg.get_node("Knee")
	_load_anatomy(theme,accent)
	if ghoul:
		body_hunch=0.18
		_profile(body,[Vector4(0.59,0.25,0.15,0),Vector4(0.90,0.23,0.16,0)],materials.leather)
		for side in [-1.0,1.0]:
			for rib in range(5):
				_curve(body,[Vector3(side*0.055,1.16+rib*0.065,-0.18),Vector3(side*0.20,1.18+rib*0.065,-0.15),Vector3(side*0.26,1.16+rib*0.065,-0.02)],0.009,materials.bone)
	else:
		_build_cuirass(caster,ranger)
		if caster: _build_robe()
		else:
			for side in [-1.0,1.0]:
				for tier in range(3):
					var tasset:=_panel(body,[Vector4(0.59-tier*0.045,0.125,0.042,0),Vector4(0.73-tier*0.045,0.14,0.055,0),Vector4(0.88-tier*0.045,0.12,0.050,0)],materials.leather if ranger else materials.metal,1.24)
					tasset.position=Vector3(side*0.18,0,-0.15)
					tasset.rotation.z=side*0.14
		_build_headwear(caster,ranger)
	cape=Node3D.new()
	cape.name="Cape"
	cape.position=Vector3(0,1.49,0.20)
	body.add_child(cape)
	if not ghoul:
		var fabric:=_mesh(cape,Vector3.ZERO,preload("res://scripts/sculpted_mesh.gd").mantle(),materials.cloth)
		fabric.scale=Vector3(1.15,0.84 if ranger else 1.0,1.0)
		for side in [-1.0,1.0]:
			_curve(cape,[Vector3(side*0.17,0,0),Vector3(side*0.24,-0.40,0.05),Vector3(side*0.29,-0.85,0.17),Vector3(side*0.30,-1.08,0.22)],0.009,materials.trim)
	weapon=Node3D.new()
	weapon.name="Weapon"
	weapon.position=Vector3(0,-0.61,-0.035)
	right_arm.add_child(weapon)
	_build_weapon(caster,ranger,ghoul)
	if boss:
		scale=Vector3.ONE*1.65
		_build_boss_regalia()
	elif kind=="hexer": scale=Vector3(0.86,1.10,0.86)
	elif kind in ["bulwark","elite"]: scale=Vector3(1.22,1.15,1.22)
	elif hostile: scale=Vector3(0.87,0.96,0.87)
	_merge_rigid_parts(self)
	_sync_anatomy()
	_contact_shadow()

func _load_anatomy(theme: Dictionary, accent: Color) -> void:
	var model: Node3D=(preload("res://assets/models/ashen-anatomy.glb") if hostile else preload("res://assets/models/nyra-anatomy.glb")).instantiate()
	model.name="SkinnedAnatomy"
	model.set_meta("keep_unmerged",true)
	body.add_child(model)
	anatomy=model.find_children("*","Skeleton3D",true,false)[0]
	for name_value in ["ArmL","ArmR","LegL","LegR","KneeL","KneeR"]:
		anatomy_bones[name_value]=anatomy.find_bone(name_value)
	var material:=ShaderMaterial.new()
	material.shader=preload("res://assets/shaders/anatomy_surface.gdshader")
	material.set_shader_parameter("skin_tint",Color("c6ae9c") if not hostile else Color(theme.skin))
	material.set_shader_parameter("cloth_tint",accent.darkened(0.62))
	material.set_shader_parameter("all_skin",hostile and kind=="raider")
	material.set_shader_parameter("skin_texture",preload("res://assets/textures/skin-albedo.webp"))
	material.set_shader_parameter("skin_normal",preload("res://assets/textures/skin-normal.png"))
	material.set_shader_parameter("linen_texture",preload("res://assets/textures/linen-albedo.webp"))
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		mesh.material_override=material
	# Eyeballs sit inside the sculpted eyelids, at the imported anatomical landmarks.
	var eye_y:=1.88279 if hostile else 1.87190
	var eye_z:=-0.13972 if hostile else -0.11698
	var sclera:=_mat(Color("aeaaa0"),0.0,false,3.0)
	var iris:=_mat(Color(theme.glow) if hostile else Color("477c83"),0.15,hostile)
	for side in [-1.0,1.0]:
		_sphere(body,Vector3(side*0.035,eye_y,eye_z),Vector3(0.024,0.021,0.022),sclera)
		_sphere(body,Vector3(side*0.035,eye_y,eye_z-0.020),Vector3(0.011,0.011,0.004),iris)
		if not hostile:
			_sphere(body,Vector3(side*0.035,eye_y,eye_z-0.024),Vector3(0.0045,0.0055,0.002),materials.leather)

func _sync_anatomy() -> void:
	if anatomy==null: return
	for entry in [["ArmL",left_arm],["ArmR",right_arm],["LegL",left_leg],["LegR",right_leg],["KneeL",left_knee],["KneeR",right_knee]]:
		var bone: int=anatomy_bones[entry[0]]
		if bone>=0: anatomy.set_bone_pose_rotation(bone,entry[1].quaternion)

func _textures(material: ShaderMaterial) -> void:
	material.set_shader_parameter("steel_texture",preload("res://assets/textures/steel-albedo.webp"))
	material.set_shader_parameter("linen_texture",preload("res://assets/textures/linen-albedo.webp"))
	material.set_shader_parameter("leather_texture",preload("res://assets/textures/leather-albedo.webp"))
	material.set_shader_parameter("bone_texture",preload("res://assets/textures/bone-albedo.webp"))
	material.set_shader_parameter("skin_texture",preload("res://assets/textures/skin-albedo.webp"))

func _panel(parent: Node3D,rings: Array,mat: Material,arc: float=1.25) -> MeshInstance3D:
	return _mesh(parent,Vector3.ZERO,preload("res://scripts/regalia_mesh.gd").panel(rings,arc),mat)

func _curve(parent: Node3D,points: Array,radius: float,mat: Material) -> MeshInstance3D:
	return _mesh(parent,Vector3.ZERO,preload("res://scripts/regalia_mesh.gd").tube(points,radius),mat)

func _build_cuirass(caster: bool,ranger: bool) -> void:
	var plate_material: Material=materials.cloth if caster else materials.leather if ranger else materials.metal
	var rings: Array=[Vector4(0.92,0.225,0.165,0),Vector4(1.04,0.235,0.185,0),Vector4(1.18,0.27,0.215,0),Vector4(1.34,0.295,0.23,0),Vector4(1.46,0.265,0.19,0),Vector4(1.56,0.19,0.135,0)]
	_panel(body,rings,plate_material,1.35)
	var back:=_panel(body,rings,materials.cloth if caster else plate_material,1.35)
	back.rotation.y=PI
	for side in [-1.0,1.0]:
		_curve(body,[Vector3(side*0.12,1.58,-0.12),Vector3(side*0.23,1.48,-0.17),Vector3(side*0.265,1.34,-0.20),Vector3(side*0.22,1.08,-0.18),Vector3(side*0.19,0.92,-0.14)],0.010,materials.trim)
		for tier in range(3):
			var plate:=_panel(body,[Vector4(0.94+tier*0.085,0.215+tier*0.015,0.175+tier*0.016,0),Vector4(1.015+tier*0.085,0.23+tier*0.015,0.19+tier*0.016,0)],plate_material,1.26)
			plate.position.z=-0.017
		# Three scrolls per side are raised metal inlays, following the chest curvature.
		for tier in range(3):
			var points: Array=[]
			for step in range(16):
				var t:=float(step)/15.0
				points.append(Vector3(side*(0.045+t*0.17),1.24+tier*0.085+sin(t*PI)*0.035,-0.236+pow(t,2.0)*0.034))
			_curve(body,points,0.004,materials.trim)
	_profile(body,[Vector4(0.88,0.242,0.179,0),Vector4(0.93,0.245,0.184,0)],materials.leather)
	_box(body,Vector3(0,0.912,-0.195),Vector3(0.10,0.065,0.023),materials.trim)
	for side in [-1.0,1.0]:
		var pouch:=_profile(body,[Vector4(0.68,0.055,0.050,0),Vector4(0.86,0.075,0.057,0)],materials.leather)
		pouch.position=Vector3(side*0.235,0,0.06)
		_sphere(body,Vector3(side*0.235,0.83,-0.001),Vector3.ONE*0.010,materials.trim)
	if ranger:
		_curve(body,[Vector3(-0.23,1.54,-0.12),Vector3(-0.10,1.34,-0.242),Vector3(0.10,1.12,-0.205),Vector3(0.23,0.94,-0.13)],0.023,materials.leather)
		var quiver:=_profile(body,[Vector4(0.82,0.09,0.10,0),Vector4(1.50,0.115,0.11,0)],materials.leather)
		quiver.position=Vector3(-0.23,0,0.27)
		for i in range(6):
			var x: float=-0.29+i*0.025
			_curve(body,[Vector3(x,1.35,0.27),Vector3(x-0.02,1.78,0.27)],0.004,materials.bone)
			var feather:=_panel(body,[Vector4(1.68,0.024,0.006,0),Vector4(1.78,0.010,0.005,0)],materials.cloth,1.5)
			feather.position=Vector3(x-0.02,0,0.27)
	elif caster:
		_sphere(body,Vector3(0,1.45,-0.202),Vector3(0.035,0.047,0.02),materials.trim)
		_sphere(body,Vector3(0,1.45,-0.225),Vector3(0.020,0.031,0.015),materials.glow)

func _build_robe() -> void:
	_profile(body,[Vector4(0.10,0.36,0.25,0.03),Vector4(0.25,0.34,0.24,0.02),Vector4(0.62,0.27,0.20,0),Vector4(0.88,0.22,0.16,0)],materials.cloth,48)
	for pleat in range(14):
		var angle:=float(pleat)*TAU/14.0
		var fold:=_panel(body,[Vector4(0.11,0.030,0.017,0),Vector4(0.30,0.050,0.025,0),Vector4(0.68,0.035,0.015,0),Vector4(0.86,0.016,0.005,0)],materials.cloth,1.4)
		fold.position=Vector3(sin(angle)*0.25,0,cos(angle)*0.18)
		fold.rotation.y=angle
	for side in [-1.0,1.0]:
		_curve(body,[Vector3(side*0.07,0.15,-0.246),Vector3(side*0.09,0.44,-0.226),Vector3(side*0.11,0.74,-0.20),Vector3(side*0.12,1.17,-0.229)],0.010,materials.trim)
		for i in range(5):
			var jewel:=_box(body,Vector3(side*0.09,0.24+i*0.085,-0.25+i*0.009),Vector3(0.024,0.024,0.008),materials.trim)
			jewel.rotation.z=PI/4

func _build_headwear(caster: bool,ranger: bool) -> void:
	var hood:=_mesh(body,Vector3.ZERO,preload("res://scripts/regalia_mesh.gd").hood(),materials.cloth if caster or ranger else materials.metal)
	hood.rotation.y=PI
	for side in [-1.0,1.0]:
		_curve(body,[Vector3(side*0.13,1.70,-0.080),Vector3(side*0.153,1.82,-0.096),Vector3(side*0.11,1.98,-0.14),Vector3(side*0.025,2.05,-0.061)],0.010,materials.trim)
		if ranger:
			for strand in range(3):
				_curve(body,[Vector3(side*(0.12+strand*0.005),1.85,0.04),Vector3(side*0.16,1.69,0.09+strand*0.008),Vector3(side*0.15,1.55,0.15)],0.012,materials.hair)
	if not caster and not ranger:
		_curve(body,[Vector3(-0.13,1.92,-0.113),Vector3(-0.055,1.96,-0.149),Vector3(0,1.97,-0.16),Vector3(0.055,1.96,-0.149),Vector3(0.13,1.92,-0.113)],0.012,materials.edge)
		_curve(body,[Vector3(0,1.96,-0.162),Vector3(0,1.86,-0.173),Vector3(0,1.80,-0.185)],0.010,materials.edge)
	if hostile:
		for side in [-1.0,1.0]:
			var horn:=_profile(body,[Vector4(0,0.065,0.06,0),Vector4(0.14,0.054,0.04,0.02),Vector4(0.30,0.028,0.025,0.09),Vector4(0.44,0.002,0.003,0.16)],materials.bone,16)
			horn.position=Vector3(side*0.15,1.94,0.045)
			horn.rotation.z=-side*0.50

func _build_weapon(caster: bool,ranger: bool,ghoul: bool) -> void:
	if caster:
		_curve(weapon,[Vector3(0,-0.50,0),Vector3(0,0.30,0),Vector3(0.025,1.08,0)],0.024,materials.leather)
		for y in [-0.43,-0.12,0.26,0.72,1.02]:
			_cylinder(weapon,Vector3(0,y,0),0.039,0.039,0.035,materials.trim,20)
		var gem:=_profile(weapon,[Vector4(1.12,0.025,0.025,0),Vector4(1.27,0.10,0.10,0),Vector4(1.42,0.012,0.012,0)],materials.glow,6)
		gem.rotation.y=PI/6
		for side in [-1.0,1.0]:
			_curve(weapon,[Vector3(0,0.93,0),Vector3(side*0.13,1.13,0),Vector3(side*0.15,1.30,0),Vector3(side*0.06,1.45,0)],0.015,materials.edge)
	elif ranger:
		var path: Array=[]
		for i in range(33):
			var t: float=-1.0+float(i)/16.0
			path.append(Vector3(0,t*0.69,-0.15-(1.0-t*t)*0.27))
		_curve(weapon,path,0.024,materials.leather)
		for side in [-1.0,1.0]:
			_curve(weapon,[Vector3(0,side*0.69,-0.15),Vector3(0,side*0.60,-0.20),Vector3(0,side*0.52,-0.27)],0.033,materials.trim)
		_curve(weapon,[Vector3(0,-0.69,-0.15),Vector3(0,0,-0.10),Vector3(0,0.69,-0.15)],0.0025,materials.bone)
		_curve(weapon,[Vector3(0,0,-0.10),Vector3(0,0,-0.96)],0.004,materials.bone)
		var tip:=_profile(weapon,[Vector4(0,0.025,0.025,0),Vector4(0.10,0.001,0.001,0)],materials.edge,4)
		tip.rotation.x=-PI/2
		tip.position.z=-0.96
	elif ghoul:
		for finger in range(3):
			_curve(weapon,[Vector3((finger-1)*0.038,-0.07,-0.035),Vector3((finger-1)*0.04,-0.15,-0.055),Vector3((finger-1)*0.045,-0.21,-0.13)],0.009,materials.bone)
	else:
		_cylinder(weapon,Vector3(0,-0.045,0),0.034,0.034,0.29,materials.leather,20)
		_sphere(weapon,Vector3(0,-0.21,0),Vector3.ONE*0.045,materials.trim)
		_curve(weapon,[Vector3(-0.22,0.085,0.015),Vector3(-0.10,0.135,0),Vector3(0,0.12,0),Vector3(0.10,0.135,0),Vector3(0.22,0.085,0.015)],0.025,materials.trim)
		_mesh(weapon,Vector3.ZERO,preload("res://scripts/regalia_mesh.gd").blade(),materials.edge)
		for row in range(4):
			var rune:=_box(weapon,Vector3(0,0.38+row*0.11,-0.026),Vector3(0.018,0.042,0.003),materials.trim)
			rune.rotation.z=0.35
		if not hostile or kind in ["bulwark","elite","boss"]:
			var shield:=_panel(left_arm,[Vector4(-0.91,0.025,0.045,0),Vector4(-0.74,0.19,0.09,0),Vector4(-0.31,0.265,0.14,0),Vector4(-0.08,0.22,0.11,0)],materials.metal,1.3)
			shield.position=Vector3(-0.075,0,-0.16)
			for side in [-1.0,1.0]:
				_curve(left_arm,[Vector3(-0.075,-0.90,-0.205),Vector3(-0.075+side*0.19,-0.73,-0.24),Vector3(-0.075+side*0.23,-0.32,-0.23),Vector3(-0.075+side*0.19,-0.11,-0.23)],0.012,materials.trim)
			_curve(left_arm,[Vector3(-0.075,-0.80,-0.27),Vector3(-0.075,-0.45,-0.306),Vector3(-0.075,-0.19,-0.28)],0.014,materials.trim)
			_sphere(left_arm,Vector3(-0.075,-0.36,-0.302),Vector3(0.032,0.040,0.014),materials.trim)

func _mat(color: Color, metal: float, glow: bool = false, surface_type: float = 0.0) -> Material:
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
	_textures(mat)
	mat.set_shader_parameter("tint",color)
	mat.set_shader_parameter("metal",metal)
	mat.set_shader_parameter("cloth",1.0 if metal==0.0 else 0.0)
	mat.set_shader_parameter("surface_type",surface_type)
	mat.set_meta("art_surface",surface_type)
	mat.set_meta("art_tint",color)
	mat.set_meta("art_metal",metal)
	mat.set_meta("art_glow",0.0)
	return mat

func _profile(parent: Node3D,rings: Array,mat: Material,sides: int=24) -> MeshInstance3D:
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
	var mesh:=preload("res://scripts/sculpted_mesh.gd").bevelled_box()
	var instance:=_mesh(parent,pos,mesh,mat)
	instance.scale=dimensions
	return instance

func _cylinder(parent: Node3D,pos: Vector3,bottom: float,top: float,height: float,mat: Material,sides: int = 12) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	mesh.radial_segments = sides
	return _mesh(parent,pos,mesh,mat)

func _sphere(parent: Node3D,pos: Vector3,dimensions: Vector3,mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 20
	mesh.rings = 10
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
	var pivot:=Node3D.new()
	pivot.name="ArmL" if side<0 else "ArmR"
	pivot.position=Vector3(side*0.33,1.47,0)
	body.add_child(pivot)
	if kind=="raider" and hostile: return pivot
	var light_armor: bool=kind in ["Ranger","Arcanist","hexer"]
	for tier in range(3):
		var plate:=_panel(pivot,[Vector4(-0.10,0.135,0.14,0),Vector4(0.015,0.175,0.19,0),Vector4(0.09,0.12,0.15,0)],materials.leather if light_armor else materials.metal,1.58)
		plate.position=Vector3(side*(0.025+tier*0.015),-tier*0.074,0)
		plate.rotation.z=side*(0.2+tier*0.06)
		var rear:=_panel(pivot,[Vector4(-0.10,0.135,0.14,0),Vector4(0.015,0.175,0.19,0),Vector4(0.09,0.12,0.15,0)],materials.leather if light_armor else materials.metal,1.58)
		rear.transform=plate.transform
		rear.rotate_y(PI)
		_curve(pivot,[Vector3(-0.11,-0.09-tier*0.074,-0.11),Vector3(0,-0.11-tier*0.074,-0.145),Vector3(0.11,-0.09-tier*0.074,-0.11)],0.008,materials.trim)
	_profile(pivot,[Vector4(-0.51,0.074,0.08,-0.025),Vector4(-0.46,0.085,0.090,-0.02),Vector4(-0.35,0.102,0.10,-0.01),Vector4(-0.29,0.094,0.095,0)],materials.leather if light_armor else materials.metal)
	for y in [-0.48,-0.34]:
		_cylinder(pivot,Vector3(0,y,-0.017),0.096,0.096,0.024,materials.trim,24)
	for i in range(4):
		_sphere(pivot,Vector3(side*0.065,-0.32-i*0.05,-0.090),Vector3.ONE*0.008,materials.trim)
	return pivot

func _leg(side: float) -> Node3D:
	var pivot:=Node3D.new()
	pivot.name="LegL" if side<0 else "LegR"
	pivot.position=Vector3(side*0.18,0.89,0)
	body.add_child(pivot)
	var knee:=Node3D.new()
	knee.name="Knee"
	knee.position.y=-0.39
	pivot.add_child(knee)
	if kind=="raider" and hostile: return pivot
	_panel(pivot,[Vector4(-0.30,0.10,0.105,0),Vector4(-0.13,0.13,0.14,0),Vector4(-0.015,0.13,0.12,0)],materials.leather,1.32)
	var light_armor: bool=kind in ["Ranger","Arcanist","hexer"]
	_panel(knee,[Vector4(-0.10,0.055,0.085,-0.015),Vector4(0,0.10,0.12,-0.03),Vector4(0.085,0.070,0.095,-0.01)],materials.edge,1.33)
	_profile(knee,[Vector4(-0.35,0.060,0.075,0),Vector4(-0.25,0.073,0.085,0),Vector4(-0.08,0.105,0.11,0)],materials.leather if light_armor else materials.metal)
	for i in range(3):
		var shoe:=_panel(knee,[Vector4(-0.45+i*0.034,0.080,0.10,0),Vector4(-0.38+i*0.034,0.084,0.10,0)],materials.leather if light_armor else materials.metal,1.5)
		shoe.position.z=-0.045-i*0.023
	_box(knee,Vector3(0,-0.451,-0.047),Vector3(0.165,0.06,0.27),materials.leather)
	return pivot

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
		_sync_anatomy()
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

	_sync_anatomy()

func _telegraph_pose(anticipation: float) -> void:
	if attack_style!="telegraph": return
	left_arm.rotation.x += -0.86*anticipation
	right_arm.rotation.x += -0.98*anticipation
	left_arm.rotation.z += -0.18*anticipation
	right_arm.rotation.z += 0.18*anticipation
	body.rotation.x += 0.12*anticipation

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
				var packed_material:=Vector2(group.material.get_meta("art_metal",0.0),group.material.get_meta("art_glow",0.0)+group.material.get_meta("art_surface",0.0)*4.0)
				for entry in group.entries:
					var arrays: Array=entry.mesh.surface_get_arrays(0)
					var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
					var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
					var uv: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
					var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
					var normal_basis: Basis=entry.transform.basis.inverse().transposed()
					for i in range(indices.size() if not indices.is_empty() else vertices.size()):
						var index: int=indices[i] if not indices.is_empty() else i
						surface.set_color(tint.srgb_to_linear())
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
			_textures(shared_surface)
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
		if child.has_meta("keep_unmerged"): continue
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

