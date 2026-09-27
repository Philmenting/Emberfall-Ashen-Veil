extends Node3D
## A continuous, deterministic dungeon. Combat requests only occur in weapon range.
signal combat_requested
signal state_changed(description: String)
const Actor = preload("res://scripts/dungeon_actor.gd")
const CHECKPOINTS := [Vector3(0,0,-4),Vector3(3,0,-15),Vector3(0,0,-27),Vector3(-3,0,-39),Vector3(2,0,-50),Vector3(0,0,-63)]
const CHAMBERS := ["THE BROKEN GATE", "WARDEN'S GALLERY", "THE ASH BRIDGE", "CHAPEL OF VOWS", "RELIQUARY", "THE INNER SANCTUM"]
var character_class := "Vowkeeper"
var region_index := 0
var active := true
var hero: Node3D
var camera: Camera3D
var enemies: Array[Node3D] = []
var torches: Array[OmniLight3D] = []
var effects: Array[Dictionary] = []
var index := 0
var elapsed := 0.0
var phase := "travel"
var phase_time := 0.0
var attack_clock := 0.0
var impact_pending := false
var health_ratio := 1.0
var camera_target := Vector3.ZERO
var materials: Dictionary = {}
var floor_materials: Array[ShaderMaterial] = []
var rng := RandomNumberGenerator.new()
var next_index := 0
var last_description := ""
var enemy_bar: MeshInstance3D

func _ready() -> void:
	rng.seed = 7291 + region_index
	_build_materials()
	_build_environment()
	_build_dungeon()
	_batch_static_geometry()
	hero = Actor.new()
	hero.kind = character_class
	hero.position = Vector3(0,0,5)
	add_child(hero)
	for i in range(CHECKPOINTS.size()):
		var enemy := Actor.new()
		enemy.hostile = true
		enemy.boss = i == CHECKPOINTS.size()-1
		enemy.kind = "Warden"
		enemy.position = CHECKPOINTS[i]
		enemy.rotation.y = PI
		add_child(enemy)
		enemies.append(enemy)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 44.0
	camera.near = 0.2
	camera.far = 100.0
	add_child(camera)
	camera.current = true
	camera_target = hero.position + Vector3(0,0,-1.8)
	_position_camera()
	var lantern := OmniLight3D.new()
	lantern.light_color = Color("afcfeb")
	lantern.light_energy = 0.65
	lantern.omni_range = 6.0
	lantern.position = Vector3(0,2.8,0)
	hero.add_child(lantern)
	enemy_bar = _box(Vector3.ZERO,Vector3(1.1,0.045,0.075),materials.blood)

func _build_materials() -> void:
	materials.stone = _material(Color("444950"))
	materials.edge = _material(Color("656a71"))
	materials.dark = _material(Color("252933"))
	materials.metal = _material(Color("65533a"),0.7)
	materials.blood = _material(Color("ae493c"),0.0,true)
	materials.fire = _material(Color("f37825"),0.0,true)
	materials.soul = _material(Color("6bc4cc"),0.0,true)
	materials.cloth = _material(Color("392c35"))
	materials.bone = _material(Color("a29b86"))
	for i in range(5):
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://assets/shaders/aged_stone.gdshader")
		mat.set_shader_parameter("stone_tint", Color("636970").darkened(float(i)*0.055))
		floor_materials.append(mat)
	materials.stone = floor_materials[2]
	var edge_mat := ShaderMaterial.new()
	edge_mat.shader = preload("res://assets/shaders/aged_stone.gdshader")
	edge_mat.set_shader_parameter("stone_tint", Color("727777"))
	materials.edge = edge_mat

func _material(color: Color, metallic: float = 0.0, glow: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.88 if metallic == 0.0 else 0.46
	mat.metallic = metallic
	if glow:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.8
	return mat

func _build_environment() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("070c12")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("8c9eb8")
	env.ambient_light_energy = 0.28
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("111b25")
	env.fog_density = 0.020
	environment.environment = env
	add_child(environment)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-52,-32,0)
	moon.light_color = Color("a8c9ee")
	moon.light_energy = 0.7
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 45.0
	add_child(moon)

func _build_dungeon() -> void:
	# Stone tiles are grouped per chamber/material so the long map stays inexpensive.
	for room in range(7):
		var batches: Array = [[],[],[],[],[]]
		for z in range(9):
			var world_z := 9.0-float(room*9+z)*1.25
			var bridge := world_z < -21.0 and world_z > -32.0
			for x in range(-6,7):
				if bridge and abs(x)>2: continue
				var pos := Vector3(float(x)*1.15 + (0.13 if z%2==0 else -0.13),-0.19,world_z)
				var dimensions := Vector3(rng.randf_range(1.08,1.12),0.35,rng.randf_range(1.17,1.22))
				pos.y += rng.randf_range(-0.012,0.012)
				batches[rng.randi_range(0,4)].append(Transform3D(Basis.IDENTITY.scaled(dimensions),pos))
		for m in range(5):
			_batch_boxes(batches[m],floor_materials[m])
		var z_center := 4.0-float(room)*11.2
		var bridge_room := room == 3
		if not bridge_room:
			for side in [-1.0,1.0]:
				# Foreground parapets are deliberately low to keep the hero visible.
				var height := 2.4 if side < 0.0 else 0.65
				_box(Vector3(side*7.3,height/2-0.15,z_center),Vector3(0.8,height,10.9),materials.stone)
				_box(Vector3(side*7.3,height-0.1,z_center),Vector3(1.0,0.18,10.9),materials.edge)
				for dz in [-4.5,4.5]:
					_pillar(Vector3(side*6.5,0,z_center+dz),side<0)
				_torch(Vector3(side*5.8,1.35,z_center))
				# Buttress ribs and staggered masonry articulate the outer wall.
				for row in range(3 if side<0 else 1):
					for brick in range(8):
						_box(Vector3(side*6.86,0.18+row*0.62,z_center-4.7+brick*1.3+(0.3 if row%2 else 0.0)),Vector3(0.13,0.57,1.24),floor_materials[(brick+row)%5])
				if room % 2 == 0:
					_sarcophagus(Vector3(side*5.3,0,z_center+2.5))
			_arch(Vector3(-6.45,0,z_center),PI/2)
			_banner(Vector3(-6.3,3.8,z_center-2.5))
			for j in range(35):
				var rubble := _box(Vector3((-1.0 if j%2==0 else 1.0)*rng.randf_range(4.4,6.5),0.08,z_center+rng.randf_range(-4.7,4.7)),Vector3(rng.randf_range(0.1,0.42),0.18,rng.randf_range(0.1,0.35)),materials.stone)
				rubble.rotation = Vector3(rng.randf()*0.4,rng.randf()*TAU,rng.randf()*0.3)
			for j in range(8):
				var stain := _ring(Vector3(rng.randf_range(-5.5,5.5),0.015,z_center+rng.randf_range(-4,4)),rng.randf_range(0.15,0.6),materials.dark)
				stain.scale = Vector3(1.4,0.1,0.4)
			for j in range(14):
				var crack := _box(Vector3(rng.randf_range(-5.0,5.0),0.017,z_center+rng.randf_range(-4.0,4.0)),Vector3(0.014,0.01,rng.randf_range(0.3,0.9)),materials.dark)
				crack.rotation.y = rng.randf()*TAU
	# Narrow causeway with balustrades, broken supports and a blue abyss below it.
	for z in range(10):
		for side in [-1.0,1.0]:
			_box(Vector3(side*3.0,0.4,-21.0-z*1.2),Vector3(0.20,0.9,0.24),materials.edge)
	for side in [-1.0,1.0]:
		_box(Vector3(side*3.0,0.87,-26.3),Vector3(0.35,0.15,11.7),materials.stone)
		_pillar(Vector3(side*3.1,0,-20.5),false)
		_pillar(Vector3(side*3.1,0,-32.2),false)
		_torch(Vector3(side*3.1,1.55,-20.5))
		_torch(Vector3(side*3.1,1.55,-32.2))
	# Entrance gate and boss sanctuary.
	_arch(Vector3(0,0,8.0),0)
	for side in [-1.0,1.0]:
		_pillar(Vector3(side*4.2,0,-66.0),true)
		_box(Vector3(side*3.8,1.6,-67),Vector3(0.9,3.2,0.9),materials.dark)
		_torch(Vector3(side*3.8,2.5,-66.8))
	_box(Vector3(0,0.12,-63),Vector3(7.0,0.2,6.0),materials.dark)
	_ring(Vector3(0,0.235,-63),2.7,materials.metal)
	_ring(Vector3(0,0.24,-63),2.4,materials.blood)
	_box(Vector3(0,0.5,-67),Vector3(3.0,1.0,1.0),materials.stone)
	# Faded carpet sections and scattered bones, clear of the walking centerline.
	for z in [1.0,-11.0,-38.0,-49.0]:
		_box(Vector3(0,0.012,z),Vector3(2.5,0.018,4.5),materials.cloth)
		for side in [-1.0,1.0]:
			_box(Vector3(side*1.15,0.026,z),Vector3(0.045,0.01,4.5),materials.metal)
		for j in range(4):
			var bone := _box(Vector3(4.0+j*0.17,0.10,z+j*0.25),Vector3(0.38,0.07,0.08),materials.bone)
			bone.rotation.y = j*0.7

func _pillar(pos: Vector3, tall: bool) -> void:
	_box(pos+Vector3(0,0.16,0),Vector3(1.15,0.32,1.15),materials.dark)
	_box(pos+Vector3(0,0.39,0),Vector3(0.90,0.16,0.90),materials.edge)
	var height := 4.0 if tall else 1.3
	_box(pos+Vector3(0,height/2+0.45,0),Vector3(0.63,height,0.63),materials.stone)
	for side in [-1.0,1.0]:
		_box(pos+Vector3(side*0.29,height/2+0.45,-0.34),Vector3(0.12,height,0.15),materials.edge)
	_box(pos+Vector3(0,height+0.46,0),Vector3(0.9,0.22,0.9),materials.edge)
	if tall:
		_box(pos+Vector3(0,height+0.68,0),Vector3(0.72,0.24,0.72),materials.dark)

func _arch(pos: Vector3, angle: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = angle
	add_child(root)
	for side in [-1.0,1.0]:
		var foot := _box(Vector3(side*2.0,1.8,0),Vector3(0.38,3.6,0.42),materials.edge,root)
		foot.name = "ArchPillar"
		for i in range(6):
			var t := float(i)/6.0
			var block := _box(Vector3(side*(2.0-t*1.85),3.6+sin(t*PI/2)*1.9,0),Vector3(0.5,0.43,0.48),materials.stone,root)
			block.rotation.z = -side*(0.4+t*0.8)
	_box(Vector3(0,5.5,0),Vector3(0.42,0.6,0.65),materials.metal,root)

func _sarcophagus(pos: Vector3) -> void:
	_box(pos+Vector3(0,0.35,0),Vector3(0.95,0.7,2.3),materials.dark)
	_box(pos+Vector3(0,0.78,0),Vector3(1.1,0.22,2.5),materials.stone)
	_box(pos+Vector3(0,0.92,0),Vector3(0.14,0.045,1.4),materials.metal)
	_box(pos+Vector3(0,0.93,-0.4),Vector3(0.6,0.045,0.14),materials.metal)

func _banner(pos: Vector3) -> void:
	# Torn cloth with a raised original oath sigil.
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = PI/2
	add_child(root)
	_box(Vector3(0,0.10,0),Vector3(1.4,0.08,0.08),materials.metal,root)
	for i in range(9):
		var length := 2.3 - (0.20 if i%3==0 else 0.0)
		_box(Vector3((i-4)*0.13,-length/2,sin(i*0.9)*0.035),Vector3(0.135,length,0.025),materials.cloth,root)
	_box(Vector3(0,-0.9,0.065),Vector3(0.055,0.9,0.035),materials.metal,root)
	for side in [-1.0,1.0]:
		var sigil := _box(Vector3(side*0.19,-0.7,0.065),Vector3(0.045,0.5,0.035),materials.metal,root)
		sigil.rotation.z = side*0.7

func _torch(pos: Vector3) -> void:
	_box(pos+Vector3(0,-0.55,0),Vector3(0.16,1.1,0.16),materials.metal)
	_box(pos,Vector3(0.48,0.12,0.48),materials.dark)
	var flame := SphereMesh.new()
	flame.radius = 0.14
	flame.height = 0.50
	var fire := MeshInstance3D.new()
	fire.mesh = flame
	fire.material_override = materials.fire
	fire.position = pos+Vector3(0,0.22,0)
	add_child(fire)
	var light := OmniLight3D.new()
	light.position = pos+Vector3(0,0.55,0)
	light.light_color = Color("ffab60")
	light.light_energy = 2.2
	light.omni_range = 5.5
	add_child(light)
	torches.append(light)

func _batch_static_geometry() -> void:
	# Batch static boxes by material AND room, preserving frustum/light culling.
	# Dynamic actors/effects are created afterwards and remain articulated.
	var groups: Dictionary = {}
	for node in find_children("*","MeshInstance3D",true,false):
		var mesh_node: MeshInstance3D = node
		if not mesh_node.mesh is BoxMesh: continue
		var mat: Material = mesh_node.material_override
		var room := floori(mesh_node.global_position.z/11.0)
		var key := str(mat.get_instance_id())+":"+str(room)
		if not groups.has(key): groups[key] = {"material":mat,"transforms":[]}
		var transform: Transform3D = mesh_node.global_transform
		transform.basis = transform.basis.scaled_local(mesh_node.mesh.size)
		groups[key].transforms.append(transform)
		mesh_node.get_parent().remove_child(mesh_node)
		mesh_node.queue_free()
	for group in groups.values():
		_batch_boxes(group.transforms,group.material)

func _batch_boxes(transforms: Array, mat: Material) -> void:
	if transforms.is_empty(): return
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	mesh.material = mat
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for i in range(transforms.size()): multi.set_instance_transform(i,transforms[i])
	var node := MultiMeshInstance3D.new()
	node.multimesh = multi
	add_child(node)

func _box(pos: Vector3,dimensions: Vector3,mat: Material,parent: Node3D = null) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	instance.material_override = mat
	instance.position = pos
	if parent == null: add_child(instance)
	else: parent.add_child(instance)
	return instance

func _ring(pos: Vector3,radius: float,mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius-0.028
	mesh.outer_radius = radius+0.028
	mesh.rings = 40
	mesh.ring_segments = 6
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	add_child(node)
	return node

func _process(delta: float) -> void:
	if not active: return
	elapsed += delta
	phase_time += delta
	_update_effects(delta)
	for i in range(torches.size()):
		torches[i].light_energy = 2.1+sin(elapsed*8.0+i*2.1)*0.15
	var enemy: Node3D = enemies[index]
	if phase == "travel":
		var distance := 1.55 if character_class == "Vowkeeper" else 3.8
		var destination: Vector3 = CHECKPOINTS[index] + Vector3(0,0,distance)
		var direction: Vector3 = destination-hero.position
		if direction.length()>0.08:
			hero.position = hero.position.move_toward(destination,delta*2.55)
			hero.rotation.y = lerp_angle(hero.rotation.y,atan2(-direction.x,-direction.z),minf(delta*9.0,1.0))
			hero.animate(delta,true)
			_set_description("AUTO • MOVING TO " + CHAMBERS[index])
		else:
			phase = "combat"
			attack_clock = 0.0
			phase_time = 0.0
	elif phase == "combat":
		hero.animate(delta,false)
		var direction: Vector3 = enemy.position-hero.position
		hero.rotation.y = lerp_angle(hero.rotation.y,atan2(-direction.x,-direction.z),minf(delta*10.0,1.0))
		attack_clock -= delta
		if attack_clock <= 0.0:
			hero.strike()
			attack_clock = 2.05
			impact_pending = true
			phase_time = 0.0
		if impact_pending and phase_time >= 0.36:
			impact_pending = false
			combat_requested.emit()
		_set_description("AUTO • " + ("BOSS FIGHT" if index==5 else "IN COMBAT"))
	elif phase == "loot":
		hero.animate(delta,false)
		if phase_time > 0.9:
			index = next_index
			phase = "travel"
			health_ratio = 1.0
			phase_time = 0.0
			_set_description("AUTO • CONTINUING THE DESCENT")
	elif phase == "complete":
		hero.animate(delta,false)
	for opponent in enemies:
		opponent.animate(delta,false)
	if enemy.death_time < 0:
		var facing: Vector3 = hero.position-enemy.position
		enemy.rotation.y = lerp_angle(enemy.rotation.y,atan2(-facing.x,-facing.z),minf(delta*4.0,1.0))
	enemy_bar.visible = phase == "combat"
	enemy_bar.position = enemy.position+Vector3(0,3.8 if index==5 else 2.65,0)
	enemy_bar.scale.x = maxf(0.01,health_ratio)
	camera_target = camera_target.lerp(hero.position+Vector3(0,0,-1.8),1.0-exp(-delta*4.0))
	_position_camera()

func _position_camera() -> void:
	camera.position = camera_target+Vector3(9.0,12.8,12.0)
	camera.look_at(camera_target+Vector3(0,0.4,0))

func _set_description(value: String) -> void:
	if value != last_description:
		last_description = value
		state_changed.emit(value)

func resolve_hit(damage: int, ratio: float, defeated: bool, next_stage: int, ability: bool) -> void:
	health_ratio = ratio
	var target: Node3D = enemies[index]
	var color := Color("f3cc86")
	if character_class == "Arcanist": color = Color("a797ff")
	if character_class == "Ranger": color = Color("91e9bd")
	var effect_mat := _material(color,0.0,true)
	var ring := _ring(target.position+Vector3(0,0.15,0),0.8,effect_mat)
	effects.append({"node":ring,"age":0.0,"life":0.5,"kind":"ring"})
	for i in range(9):
		var spark := _box(target.position+Vector3(0,1.0,0),Vector3.ONE*0.055,effect_mat)
		effects.append({"node":spark,"age":0.0,"life":0.45,"kind":"spark","velocity":Vector3(rng.randf_range(-2,2),rng.randf_range(1,4),rng.randf_range(-2,2))})
	var number := Label3D.new()
	number.text = str(damage)
	number.font_size = 64 if ability else 48
	number.pixel_size = 0.008
	number.modulate = color
	number.outline_size = 10
	number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	number.no_depth_test = true
	number.position = target.position+Vector3(0,2.7 if index<5 else 4.0,0)
	add_child(number)
	effects.append({"node":number,"age":0.0,"life":0.9,"kind":"number"})
	if character_class != "Vowkeeper":
		var start := hero.position+Vector3(0,1.3,0)
		var end := target.position+Vector3(0,1.1,0)
		var bolt := _box((start+end)*0.5,Vector3(0.055,0.055,start.distance_to(end)),effect_mat)
		bolt.look_at(end)
		effects.append({"node":bolt,"age":0.0,"life":0.18,"kind":"bolt"})
	if defeated:
		target.die()
		next_index = mini(next_stage,5)
		phase = "complete" if next_stage>=6 else "loot"
		phase_time = 0.0
		var loot := _box(target.position+Vector3(0,0.35,0),Vector3(0.13,0.65,0.13),materials.soul)
		effects.append({"node":loot,"age":0.0,"life":1.1,"kind":"loot"})
	else:
		target.strike()

func _update_effects(delta: float) -> void:
	for i in range(effects.size()-1,-1,-1):
		var effect: Dictionary = effects[i]
		effect.age += delta
		var node: Node3D = effect.node
		if effect.kind == "ring": node.scale = Vector3.ONE*(1.0+effect.age*3.0)
		elif effect.kind == "spark":
			node.position += Vector3(effect.velocity)*delta
			effect.velocity.y -= delta*8.0
		elif effect.kind == "number": node.position.y += delta*0.9
		elif effect.kind == "loot":
			node.position = node.position.lerp(hero.position+Vector3(0,0.8,0),delta*4.0)
		if effect.age >= effect.life:
			node.queue_free()
			effects.remove_at(i)
