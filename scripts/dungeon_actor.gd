extends Node3D
## Original articulated models. Geometry and animation are authored in Godot.
const ThemeData = preload("res://scripts/dungeon_theme.gd")
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
	materials.skin = _mat(Color("c1aa95") if not hostile else Color(theme.skin), 0.0)
	materials.glow = _mat(Color("81d9e6") if not hostile else Color(theme.glow), 0.0, true)
	body = Node3D.new()
	add_child(body)
	# Torso: tapered cuirass, inset breastplate, belt and overlapping tassets.
	_cylinder(body, Vector3(0,1.2,0), 0.28,0.36,0.58, materials.metal, 8)
	_box(body, Vector3(0,1.36,-0.23), Vector3(0.46,0.32,0.10), materials.edge)
	_box(body, Vector3(0,1.36,-0.292), Vector3(0.09,0.22,0.025), materials.trim)
	_cylinder(body, Vector3(0,0.94,0),0.29,0.3,0.12,materials.leather,10)
	_box(body,Vector3(0,0.96,-0.29),Vector3(0.15,0.12,0.07),materials.trim)
	for side in [-1.0,1.0]:
		var skirt := _box(body,Vector3(side*0.22,0.81,-0.02),Vector3(0.27,0.31,0.37),materials.metal)
		skirt.rotation.z = side * 0.15
		_box(body,Vector3(side*0.23,0.78,-0.22),Vector3(0.2,0.025,0.02),materials.trim)
	_sphere(body,Vector3(0,1.76,0),Vector3(0.225,0.26,0.21),materials.skin)
	_sphere(body,Vector3(0,1.84,0.015),Vector3(0.25,0.24,0.23),materials.metal)
	_box(body,Vector3(0,1.76,-0.21),Vector3(0.37,0.075,0.04),materials.leather)
	for side in [-1.0,1.0]:
		_box(body,Vector3(side*0.095,1.78,-0.235),Vector3(0.095,0.028,0.018),materials.glow)
		_box(body,Vector3(side*0.185,1.67,-0.15),Vector3(0.08,0.22,0.12),materials.edge)
	if not hostile:
		_box(body,Vector3(0,2.035,0.05),Vector3(0.06,0.20,0.34),materials.trim)
	else:
		for side in [-1.0,1.0]:
			var horn := _cylinder(body,Vector3(side*0.24,2.05,0),0.08,0.0,0.45,materials.trim,6)
			horn.rotation.z = -side * 0.6
	left_arm = _arm(-1.0)
	right_arm = _arm(1.0)
	left_leg = _leg(-1.0)
	right_leg = _leg(1.0)
	left_knee = left_leg.get_child(1)
	right_knee = right_leg.get_child(1)
	cape = Node3D.new()
	cape.position = Vector3(0,1.5,0.21)
	body.add_child(cape)
	for i in range(5):
		var strip := _box(cape,Vector3((i-2)*0.12,-0.48,0.16),Vector3(0.125,0.94+0.05*sin(i),0.045),materials.cloth)
		strip.rotation.x = -0.2
	weapon = Node3D.new()
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
	else:
		_box(weapon,Vector3(0,-0.09,0),Vector3(0.09,0.3,0.09),materials.leather)
		_box(weapon,Vector3(0,0.10,0),Vector3(0.40,0.085,0.10),materials.trim)
		var blade := _box(weapon,Vector3(0,0.70,0),Vector3(0.12,1.1,0.055),materials.edge)
		blade.rotation.z = 0.015
		_box(weapon,Vector3(0,0.67,-0.035),Vector3(0.027,0.85,0.012),materials.glow)
		_cylinder(weapon,Vector3(0,1.31,0),0.085,0,0.18,materials.edge,4)
		if not hostile or kind in ["bulwark","elite","boss"]:
			var shield := _sphere(left_arm,Vector3(-0.05,-0.37,-0.12),Vector3(0.29,0.39,0.10),materials.metal)
			_box(shield,Vector3(0,0,-1.0),Vector3(0.16,1.5,0.10),materials.trim)
	if boss:
		scale = Vector3.ONE * 1.65
		_build_boss_regalia()
	elif kind=="hexer":
		scale = Vector3(0.82,1.10,0.82)
		_cylinder(body,Vector3(0,0.57,0),0.40,0.25,0.85,materials.cloth,10)
	elif kind=="bulwark" or kind=="elite": scale = Vector3(1.22,1.15,1.22)
	elif hostile: scale = Vector3(0.87,0.96,0.87)
	_merge_rigid_parts(self)

func _mat(color: Color, metal: float, glow: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metal
	mat.roughness = 0.4 if metal > 0.0 else 0.9
	if glow:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 2.0
	return mat

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
	pivot.position = Vector3(side*0.38,1.48,0)
	body.add_child(pivot)
	_sphere(pivot,Vector3(side*0.03,0,0),Vector3(0.23,0.17,0.23),materials.edge)
	_sphere(pivot,Vector3(side*0.03,0.025,0),Vector3(0.2,0.16,0.2),materials.metal)
	_cylinder(pivot,Vector3(0,-0.21,0),0.085,0.10,0.32,materials.leather)
	_cylinder(pivot,Vector3(0,-0.44,-0.02),0.11,0.13,0.23,materials.metal)
	_sphere(pivot,Vector3(0,-0.59,-0.02),Vector3.ONE*0.10,materials.leather)
	return pivot

func _leg(side: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(side*0.18,0.89,0)
	body.add_child(pivot)
	_cylinder(pivot,Vector3(0,-0.20,0),0.11,0.14,0.40,materials.leather)
	var knee := Node3D.new()
	knee.position.y = -0.39
	pivot.add_child(knee)
	_sphere(knee,Vector3(0,0,-0.055),Vector3(0.13,0.12,0.13),materials.edge)
	_cylinder(knee,Vector3(0,-0.20,0),0.10,0.13,0.34,materials.metal)
	_box(knee,Vector3(0,-0.40,-0.07),Vector3(0.23,0.15,0.39),materials.leather)
	_box(knee,Vector3(0,-0.365,-0.18),Vector3(0.24,0.095,0.20),materials.edge)
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
	for group in groups.values():
		var surface:=SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for entry in group.entries:
			surface.append_from(entry.mesh,0,entry.transform)
		var combined:=MeshInstance3D.new()
		combined.mesh=surface.commit()
		combined.material_override=group.material
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
