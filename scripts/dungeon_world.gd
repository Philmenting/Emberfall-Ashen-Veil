extends Node3D
## A continuous, deterministic dungeon. Combat requests only occur in weapon range.
signal simulation_advanced(events: Array)
var simulation: RefCounted
var actor_by_id: Dictionary = {}
var bars: Dictionary = {}
var warnings: Dictionary = {}
var last_stage := -1
var target_ring: MeshInstance3D
signal state_changed(description: String)
const Skills = preload("res://scripts/class_skills.gd")
const Layout = preload("res://scripts/dungeon_layout.gd")
const Actor = preload("res://scripts/dungeon_actor.gd")
const ThemeData = preload("res://scripts/dungeon_theme.gd")
const BossPatterns = preload("res://scripts/boss_patterns.gd")
const LOOT_COLORS := {"COMMON":"c7c3bc","UNCOMMON":"83cf8b","RARE":"76bfe8","EPIC":"bb91ee","LEGENDARY":"ffd277"}
var theme: Dictionary = {}
var character_class := "Vowkeeper"
var region_index := 0
var active := true
var damage_numbers := true
var reduced_motion := false
var sun: DirectionalLight3D
var ward_shell: MeshInstance3D
var ward_flash := 0.0
var guard_visual: Node3D
var hero: Node3D
var camera: Camera3D
var enemies: Array[Node3D] = []
var torches: Array[OmniLight3D] = []
var effects: Array[Dictionary] = []
var index := 0
var elapsed := 0.0
var phase := "travel"
var phase_time := 0.0
var camera_target := Vector3.ZERO
var camera_zoom := 1.0
var camera_shake_time := 0.0
var camera_shake_strength := 0.0
var materials: Dictionary = {}
var floor_materials: Array[ShaderMaterial] = []
var rng := RandomNumberGenerator.new()
var last_description := ""
var journey_props: Dictionary = {}
var recovered_drops: Array[Dictionary] = []
var sanctum_gate: Node3D

func _ready() -> void:
	region_index = clampi(region_index,0,3)
	theme = ThemeData.definition(region_index)
	rng.seed = 7291 + region_index
	_build_materials()
	_build_environment()
	_build_dungeon()
	_build_regional_details()
	_build_dressed_rooms()
	_batch_static_geometry()
	if simulation.uses_journey(): _build_journey_props()
	if simulation.Contract.mode(simulation.contract())=="trial": _build_trial_gate()
	hero = Actor.new()
	hero.kind = character_class
	hero.position = _point(simulation.hero_pos)
	add_child(hero)
	if character_class=="Arcanist":
		ward_shell = MeshInstance3D.new()
		var shell_mesh := SphereMesh.new()
		shell_mesh.radius=0.88
		shell_mesh.height=2.3
		shell_mesh.radial_segments=16
		shell_mesh.rings=8
		ward_shell.mesh=shell_mesh
		var shell_material := _material(Color(0.50,0.40,0.95,0.22),0.0,true)
		shell_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		shell_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		ward_shell.material_override=shell_material
		ward_shell.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ward_shell.position=Vector3(0,1.15,0)
		ward_shell.visible=false
		hero.add_child(ward_shell)
	guard_visual=Node3D.new()
	guard_visual.name="GuardVisual"
	hero.add_child(guard_visual)
	var guard_color := Color("edc98b") if character_class=="Vowkeeper" else Color("89dbe9") if character_class=="Arcanist" else Color("97bdb5")
	var guard_material := _material(Color(guard_color,0.32),0.0,true)
	guard_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	for segment in range(6):
		var angle := TAU*segment/6.0
		var plate := _box(Vector3(sin(angle)*0.8,0.9,cos(angle)*0.8),Vector3(0.48,0.9,0.04),guard_material,guard_visual)
		plate.rotation.y=angle
		plate.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	guard_visual.visible=simulation.guard_time>0.0
	_ensure_wave(mini(simulation.stage,5))
	_ensure_wave(mini(simulation.stage,5)+1)
	target_ring = _ring(Vector3.ZERO,0.65,materials.metal)
	target_ring.visible = false
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 40.0
	camera.near = 0.2
	camera.far = 100.0
	add_child(camera)
	camera.current = true
	camera_target = hero.position + Vector3(0,0,-1.8)
	_position_camera()
	var lantern := OmniLight3D.new()
	lantern.light_color = Color("cad8e5")
	lantern.light_energy = 1.15
	lantern.omni_range = 6.0
	lantern.position = Vector3(0,2.8,0)
	hero.add_child(lantern)

func _build_materials() -> void:
	materials.stone = _material(Color(theme.stone))
	materials.edge = _material(Color(theme.edge))
	materials.dark = _material(Color(theme.dark))
	materials.metal = _material(Color(theme.metal),0.7)
	materials.blood = _material(Color("ae493c"),0.0,true)
	materials.fire = _material(Color(theme.fire),0.0,true)
	materials.soul = _material(Color("6bc4cc"),0.0,true)
	materials.cloth = _material(Color(theme.cloth))
	materials.bone = _material(Color("a29b86"))
	for i in range(5):
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://assets/shaders/aged_stone.gdshader")
		mat.set_shader_parameter("stone_tint", Color(theme.stone).darkened(float(i)*0.055))
		mat.set_shader_parameter("roughness",theme.roughness)
		floor_materials.append(mat)
	materials.stone = floor_materials[2]
	var edge_mat := ShaderMaterial.new()
	edge_mat.shader = preload("res://assets/shaders/aged_stone.gdshader")
	edge_mat.set_shader_parameter("stone_tint", Color(theme.edge))
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
	env.background_color = Color(theme.background)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(theme.ambient)
	env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(theme.fog)
	env.fog_density = theme.density
	environment.environment = env
	add_child(environment)
	var moon := DirectionalLight3D.new()
	sun = moon
	moon.rotation_degrees = Vector3(-52,-32,0)
	moon.light_color = Color(theme.moon)
	moon.light_energy = 0.95
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 32.0
	add_child(moon)
	var rim:=DirectionalLight3D.new()
	rim.rotation_degrees=Vector3(-24,145,0)
	rim.light_color=Color("c4a278")
	rim.light_energy=0.38
	add_child(rim)

func _build_dungeon() -> void:
	if simulation.uses_journey():
		_build_journey_floor()
		return
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
				if region_index==2: height = 0.45
				_box(Vector3(side*7.3,height/2-0.15,z_center),Vector3(0.8,height,10.9),materials.stone)
				_box(Vector3(side*7.3,height-0.1,z_center),Vector3(1.0,0.18,10.9),materials.edge)
				for dz in [-4.5,4.5]:
					if region_index!=2: _pillar(Vector3(side*6.5,0,z_center+dz),side<0)
				_torch(Vector3(side*5.8,1.35,z_center))
				# Buttress ribs and staggered masonry articulate the outer wall.
				for row in range((3 if side<0 else 1) if region_index!=2 else 0):
					for brick in range(8):
						_box(Vector3(side*6.86,0.18+row*0.62,z_center-4.7+brick*1.3+(0.3 if row%2 else 0.0)),Vector3(0.13,0.57,1.24),floor_materials[(brick+row)%5])
				if room % 2 == 0 and region_index==0:
					_sarcophagus(Vector3(side*5.3,0,z_center+2.5))
			if region_index in [0,1]: _arch(Vector3(-6.45,0,z_center),PI/2)
			if region_index in [0,3]: _banner(Vector3(-6.3,3.8,z_center-2.5))
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
	_box(Vector3(0,0.005,-63),Vector3(7.0,0.02,6.0),materials.dark)
	_ring(Vector3(0,0.035,-63),2.7,materials.metal)
	# Decorative inlays must not look like an active red danger telegraph.
	_ring(Vector3(0,0.040,-63),2.4,materials.dark)
	_box(Vector3(0,0.5,-67),Vector3(3.0,1.0,1.0),materials.stone)
	# Faded carpet sections and scattered bones, clear of the walking centerline.
	for z in [1.0,-11.0,-38.0,-49.0]:
		if region_index in [0,3]: _box(Vector3(0,0.012,z),Vector3(2.5,0.018,4.5),materials.cloth)
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
	var flame := QuadMesh.new()
	flame.size=Vector2(0.7,1.1)
	var fire := MeshInstance3D.new()
	fire.mesh=flame
	var fire_mat:=ShaderMaterial.new()
	fire_mat.shader=preload("res://assets/shaders/ember_flame.gdshader")
	fire_mat.set_shader_parameter("flame_color",Color(theme.fire))
	fire.material_override=fire_mat
	fire.position=pos+Vector3(0,0.35,0)
	fire.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(fire)
	var light := OmniLight3D.new()
	light.position = pos+Vector3(0,0.55,0)
	light.light_color = Color(theme.light)
	light.light_energy = 3.4
	light.omni_range = 7.0
	add_child(light)
	torches.append(light)

func _batch_static_geometry() -> void:
	# All repeated static primitives share draw calls per material and chamber.
	# Animated liquid surfaces, actors and combat effects remain separate.
	var groups: Dictionary = {}
	for node in find_children("*","MeshInstance3D",true,false):
		var mesh_node: MeshInstance3D = node
		var source: Mesh = mesh_node.mesh
		if mesh_node.name in ["FloodedArchive","LavaBasin","LowCryptMist"]: continue
		var signature := ""
		var transform: Transform3D = mesh_node.global_transform
		if source is BoxMesh:
			signature = "box"
			transform.basis = transform.basis.scaled_local(source.size)
		elif source is CylinderMesh:
			signature = "cylinder:"+str([source.bottom_radius,source.top_radius,source.height,source.radial_segments])
		elif source is TorusMesh:
			signature = "torus:"+str([source.inner_radius,source.outer_radius,source.rings,source.ring_segments])
		elif source is PlaneMesh:
			signature="plane:"+str(source.size)
		elif source is SphereMesh:
			signature = "sphere:"+str([source.radius,source.height,source.radial_segments,source.rings])
		else: continue
		var mat: Material = mesh_node.material_override
		var room := floori(mesh_node.global_position.z/11.0)
		var key := str(mat.get_instance_id())+":"+str(room)+":"+signature
		if not groups.has(key):
			var mesh: Mesh = BoxMesh.new() if source is BoxMesh else source
			if mesh is BoxMesh: mesh.size = Vector3.ONE
			groups[key] = {"material":mat,"transforms":[],"mesh":mesh}
		groups[key].transforms.append(transform)
		mesh_node.get_parent().remove_child(mesh_node)
		mesh_node.queue_free()
	for group in groups.values():
		_batch_mesh(group.transforms,group.material,group.mesh)

func _batch_boxes(transforms: Array, mat: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	_batch_mesh(transforms,mat,mesh)

func _batch_mesh(transforms: Array,mat: Material,mesh: Mesh,casts_shadow: bool=true) -> void:
	if transforms.is_empty(): return
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for i in range(transforms.size()): multi.set_instance_transform(i,transforms[i])
	var node := MultiMeshInstance3D.new()
	node.multimesh = multi
	if mesh is PlaneMesh or not casts_shadow: node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.material_override = mat
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

func _ring(pos: Vector3,radius: float,mat: Material,parent: Node3D = null) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius-0.028
	mesh.outer_radius = radius+0.028
	mesh.rings = 40
	mesh.ring_segments = 6
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	if parent==null: add_child(node)
	else: parent.add_child(node)
	return node

func _ensure_wave(wave_index: int) -> void:
	if wave_index<0 or wave_index>=simulation.waves.size(): return
	for enemy in simulation.waves[wave_index]:
		if actor_by_id.has(enemy.id): continue
		var actor := Actor.new()
		actor.hostile = true
		actor.boss = enemy.role=="boss"
		actor.kind = enemy.role
		actor.region_index = region_index
		actor.position = _point(enemy.pos)
		actor.rotation.y = PI
		actor.visible = enemy.get("spawned",true)
		add_child(actor)
		actor_by_id[enemy.id] = actor
		enemies.append(actor)
		bars[enemy.id] = _box(actor.position+Vector3(0,2.5,0),Vector3(0.9,0.045,0.075),materials.blood)
		bars[enemy.id].visible = enemy.hp>0 and enemy.get("spawned",true) and wave_index==simulation.stage
		bars[enemy.id].position.y = 3.8 if enemy.role=="boss" else 2.5
		bars[enemy.id].scale.x = maxf(0.01,float(enemy.hp)/float(enemy.max_hp))
		if enemy.hp<=0:
			actor.die()
			actor.animate(0.8,false)
		if not enemy.warning.is_empty():
			_show_event(_warning_event(enemy))

func _warning_event(enemy: Dictionary) -> Dictionary:
	var event: Dictionary=enemy.warning.duplicate(true)
	event.merge({"type":"warning","source":enemy.id,"position":enemy.warning.center,"duration":enemy.warning.left})
	return event

func _point(point: Vector2) -> Vector3:
	return Vector3(point.x,0,point.y)

func _process(delta: float) -> void:
	if not active or simulation==null: return
	elapsed += delta
	guard_visual.visible=simulation.guard_time>0.0
	guard_visual.rotation.y=elapsed*0.4
	ward_flash=maxf(0.0,ward_flash-delta)
	if is_instance_valid(ward_shell):
		ward_shell.visible=ward_flash>0.0
		ward_shell.scale=Vector3.ONE*(1.0+(0.35-ward_flash)*0.12)
	_update_effects(delta)
	camera_shake_time=maxf(0.0,camera_shake_time-delta)
	if camera_shake_time<=0.0: camera_shake_strength=0.0
	var previous: Vector3 = hero.position
	var updates: Array = simulation.advance(delta)
	index = mini(simulation.stage,5)
	phase = simulation.phase
	if index!=last_stage:
		_ensure_wave(index)
		_ensure_wave(index+1)
		last_stage = index
		for id_value in actor_by_id.keys():
			if int(id_value)/10<index-1:
				enemies.erase(actor_by_id[id_value])
				actor_by_id[id_value].queue_free()
				bars[id_value].queue_free()
				actor_by_id.erase(id_value)
				bars.erase(id_value)
	hero.position = hero.position.lerp(_point(simulation.hero_pos),minf(1.0,delta*18.0))
	var direction := hero.position-previous
	var walking := direction.length()>0.002
	if not walking:
		var target: Dictionary = simulation.enemy_by_id(simulation.target_id)
		if not target.is_empty(): direction = _point(target.pos)-hero.position
	if direction.length()>0.01:
		hero.rotation.y = lerp_angle(hero.rotation.y,atan2(-direction.x,-direction.z),minf(delta*12.0,1.0))
	hero.animate(delta,walking,direction.length()/maxf(delta,0.0001))
	for id_value in actor_by_id:
		var enemy: Dictionary = simulation.enemy_by_id(id_value)
		var actor: Node3D = actor_by_id[id_value]
		var old_position: Vector3 = actor.position
		actor.position = actor.position.lerp(_point(enemy.pos),minf(1.0,delta*15.0))
		if enemy.hp>0:
			var facing: Vector3 = hero.position-actor.position
			actor.rotation.y = lerp_angle(actor.rotation.y,atan2(-facing.x,-facing.z),minf(delta*7.0,1.0))
		if enemy.hp<=0 and actor.death_time<0: actor.die()
		var actor_displacement:=actor.position.distance_to(old_position)
		actor.animate(delta,actor_displacement>0.002,actor_displacement/maxf(delta,0.0001))
		if not enemy.warning.is_empty() and not warnings.has(id_value):
			_show_event(_warning_event(enemy))
		var bar: MeshInstance3D = bars[id_value]
		bar.visible = enemy.hp>0 and enemy.get("spawned",true) and int(id_value)/10==index
		bar.position = actor.position+Vector3(0,3.8 if enemy.role=="boss" else 2.5,0)
		bar.scale.x = maxf(0.01,float(enemy.hp)/float(enemy.max_hp))
	for event in updates: _show_event(event)
	if simulation.uses_journey(): _sync_journey_props(delta)
	for id_value in warnings.keys():
		var enemy: Dictionary = simulation.enemy_by_id(id_value)
		if enemy.warning.is_empty() or simulation.finished:
			warnings[id_value].queue_free()
			warnings.erase(id_value)
		else:
			# Boss telegraphs keep the exact collision footprint throughout the cast.
			warnings[id_value].scale = Vector3.ONE if enemy.warning.has("zones") else Vector3.ONE*(0.92+sin(elapsed*14.0)*0.04)
	target_ring.visible = phase=="combat" and actor_by_id.has(simulation.target_id)
	if target_ring.visible: target_ring.position = actor_by_id[simulation.target_id].position+Vector3(0,0.07,0)
	for i in range(torches.size()): torches[i].light_energy = 3.1+sin(elapsed*8.0+i*2.1)*0.22
	var camera_anchor:=hero.position+Vector3(0,0,-1.8)
	if direction.length()>0.01:
		camera_anchor+=direction.normalized()*0.48
	var target_enemy: Dictionary=simulation.enemy_by_id(simulation.target_id)
	if not target_enemy.is_empty():
		var focus_point:=_point(target_enemy.pos)+Vector3(0,0,-1.05)
		var focus_weight:=0.30 if target_enemy.get("role","")=="boss" else 0.12
		camera_anchor=camera_anchor.lerp(focus_point,focus_weight)
	var boss_focus:=_boss_is_active()
	var zoom_target:=0.94 if boss_focus and not reduced_motion else 1.0
	camera_zoom=lerpf(camera_zoom,zoom_target,1.0-exp(-delta*1.35))
	camera_target = camera_target.lerp(camera_anchor,1.0-exp(-delta*4.0))
	_position_camera()
	_set_description("AUTO • " + String(simulation.action).to_upper())
	simulation_advanced.emit(updates)

func _position_camera() -> void:
	var shake:=Vector3.ZERO
	if not reduced_motion and camera_shake_time>0.0:
		var envelope:=clampf(camera_shake_time/0.18,0.0,1.0)
		var phase:=elapsed*73.0
		shake=Vector3(sin(phase),cos(phase*1.17+0.6),sin(phase*0.83+1.7))*camera_shake_strength*envelope
	camera.position = camera_target+Vector3(8.5,11.8,11.2)*camera_zoom+shake
	camera.look_at(camera_target+Vector3(0,0.4,0))

func _boss_is_active() -> bool:
	if simulation==null or simulation.waves.is_empty(): return false
	var wave_index:=clampi(simulation.stage,0,simulation.waves.size()-1)
	for enemy in simulation.waves[wave_index]:
		if enemy.get("role","")=="boss" and int(enemy.get("hp",0))>0 and enemy.get("spawned",true): return true
	return false

func _kick_camera(intensity: float) -> void:
	if reduced_motion: return
	camera_shake_strength=maxf(camera_shake_strength,clampf(intensity,0.0,0.085))
	camera_shake_time=maxf(camera_shake_time,0.18)

func _set_description(value: String) -> void:
	if value != last_description:
		last_description = value
		state_changed.emit(value)

func _show_event(event: Dictionary) -> void:
	var color := {"Vowkeeper":Color("f3cc86"),"Arcanist":Color("ac88ff"),"Ranger":Color("84e3b4")}[character_class] as Color
	match String(event.type):
		"technique_cast":
			var definition: Dictionary=Skills.DEFINITIONS[event.ability_id]
			if event.ability_id in ["starfall","rain"]:
				var marker := _ring(_point(event.position)+Vector3(0,0.07,0),float(event.radius),_material(Color(definition.color),0.0,true))
				effects.append({"node":marker,"age":0.0,"life":float(event.duration)+0.1,"kind":"cast_mark","ability_id":event.ability_id})
		"technique":
			_show_technique(event)
		"well":
			_float_text(hero.position+Vector3(0,2.6,0),"LIFE +"+str(event.restored),Color("91d1ae"))
		"objective":
			var message: String={1:"WELL RESTORED",3:"SANCTUM UNSEALED",5:"RELIQUARY CLAIMED"}.get(int(event.stage),"COMPLETE")
			_float_text(hero.position+Vector3(0,3.0,0),message,Color("efcf93"))
		"reinforcement_spawn":
			var source_id:=int(event.source)
			if actor_by_id.has(source_id): actor_by_id[source_id].visible=true
			var arrival_position:=_point(event.position)
			var arrival:=_ring(arrival_position+Vector3(0,0.08,0),0.88,materials.fire)
			arrival.scale=Vector3.ONE*0.18
			arrival.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			effects.append({"node":arrival,"age":0.0,"life":0.48,"kind":"nova"})
			_float_text(arrival_position+Vector3(0,2.55,0),"AMBUSH",Color("f29b68"))
		"hero_attack":
			var style:=String(event.get("ability_id",""))
			if style.is_empty(): style="signature" if event.get("skill",false) else "basic"
			hero.strike(style)
		"hit":
			if not actor_by_id.has(event.target): return
			var actor: Node3D = actor_by_id[event.target]
			actor.react()
			_float_text(actor.position+Vector3(0,2.5,0),str(event.damage)+("!" if event.critical else ""),color)
			var mat := _material(color,0.0,true)
			var ring := _ring(actor.position+Vector3(0,0.08,0),0.6,mat)
			effects.append({"node":ring,"age":0.0,"life":0.4,"kind":"ring"})
			if character_class!="Vowkeeper":
				var start := hero.position+Vector3(0,1.3,0)
				var end := actor.position+Vector3(0,1.1,0)
				var bolt := _box((start+end)*0.5,Vector3(0.06,0.06,start.distance_to(end)),mat)
				bolt.look_at(end)
				effects.append({"node":bolt,"age":0.0,"life":0.18,"kind":"bolt"})
			_impact_sparks(actor.position+Vector3(0,1.0,0),color)
			if character_class=="Vowkeeper": _slash_arc(hero.position,color)
			if event.dead:
				actor.die()
				var loot := _box(actor.position+Vector3(0,0.5,0),Vector3(0.12,0.5,0.12),materials.soul)
				effects.append({"node":loot,"age":0.0,"life":0.9,"kind":"loot"})
		"hero_hit":
			hero.react()
			var heavy_hit:=false
			if actor_by_id.has(event.source):
				var attacker: Node3D=actor_by_id[event.source]
				var enemy_kind:=String(attacker.get("kind"))
				var heavy: bool=enemy_kind in ["bulwark","elite","boss"]
				heavy_hit=heavy
				attacker.strike("heavy" if heavy else "enemy")
			_kick_camera(0.070 if heavy_hit else 0.034)
			_float_text(hero.position+Vector3(0,2.3,0),"−"+str(event.damage),Color("f89583"))
		"ward":
			if ward_flash<=0.0:
				_float_text(hero.position+Vector3(0,2.85,0),"WARD "+str(event.absorbed),Color("b6a4f0"))
			ward_flash=0.35
			if is_instance_valid(ward_shell): ward_shell.visible=true
		"nova":
			var wave:=_ring(_point(event.position)+Vector3(0,0.12,0),float(event.radius),_material(Color("b89aef"),0.0,true))
			wave.scale=Vector3.ONE*0.15
			wave.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			effects.append({"node":wave,"age":0.0,"life":0.45,"kind":"nova"})
		"warning":
			if warnings.has(event.source): warnings[event.source].queue_free()
			if event.has("zones"):
				warnings[event.source]=_pattern_visual(event.zones,Color("f05f40"),0.32)
				if actor_by_id.has(event.source): actor_by_id[event.source].strike("telegraph")
				return
			var zone := Node3D.new()
			zone.position = _point(event.position)+Vector3(0,0.06,0)
			add_child(zone)
			var disc := MeshInstance3D.new()
			var mesh := CylinderMesh.new()
			mesh.top_radius = event.radius
			mesh.bottom_radius = event.radius
			mesh.height = 0.025
			mesh.radial_segments = 40
			disc.mesh = mesh
			var mat := _material(Color(0.9,0.12,0.045,0.30))
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			disc.material_override = mat
			disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			zone.add_child(disc)
			var outline := _ring(Vector3.ZERO,event.radius,materials.blood)
			remove_child(outline)
			zone.add_child(outline)
			warnings[event.source] = zone
			if actor_by_id.has(event.source): actor_by_id[event.source].strike("telegraph")
		"impact":
			_kick_camera(0.055)
			if event.has("zones"):
				var burst:=_pattern_visual(event.zones,Color(theme.fire),0.55)
				effects.append({"node":burst,"age":0.0,"life":0.45,"kind":"pattern"})
				return
			var ring := _ring(_point(event.position)+Vector3(0,0.12,0),event.radius,materials.fire)
			effects.append({"node":ring,"age":0.0,"life":0.35,"kind":"ring"})
		"boss_phase":
			_kick_camera(0.060)
			if actor_by_id.has(event.source): _float_text(actor_by_id[event.source].position+Vector3(0,4.3,0),"AWAKENED",Color("ffd89b"))
		"interrupt":
			if actor_by_id.has(event.target): _float_text(actor_by_id[event.target].position+Vector3(0,2.8,0),"INTERRUPTED",Color("b4a2e4"))
		"guard":
			_float_text(hero.position+Vector3(0,2.6,0),"GUARD +"+str(event.heal),Color("91d1ae"))
		"evade", "backstep":
			_float_text(hero.position+Vector3(0,2.3,0),"EVADE",Color("adcbe0"))
		"finished":
			if not event.won: hero.die()

func _pattern_visual(zones: Array, tint: Color, alpha: float) -> Node3D:
	var node:=Node3D.new()
	node.name="BossTelegraph"
	add_child(node)
	for border in [false,true]:
		var vertices:=PackedVector3Array()
		for zone in zones:
			if not border:
				for point in BossPatterns.triangles(zone): vertices.append(_point(point)+Vector3(0,0.085,0))
			else:
				for outline in BossPatterns.outlines(zone):
					for i in range(outline.size()):
						var a: Vector2=outline[i]
						var b: Vector2=outline[(i+1)%outline.size()]
						var direction: Vector2=(b-a).normalized()
						var width:=Vector2(-direction.y,direction.x)*0.035
						for point in [a-width,b-width,a+width,b-width,b+width,a+width]: vertices.append(_point(point)+Vector3(0,0.10,0))
		var arrays:=[]
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX]=vertices
		var mesh:=ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var visual:=MeshInstance3D.new()
		visual.mesh=mesh
		var color:=tint.lightened(0.3) if border else tint
		color.a=0.95 if border else alpha
		var material:=_material(color,0.0,true)
		material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode=BaseMaterial3D.CULL_DISABLED
		visual.material_override=material
		visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.add_child(visual)
	return node

func _float_text(pos: Vector3, value: String, color: Color) -> void:
	if not damage_numbers: return
	var label := Label3D.new()
	label.text = value
	label.font_size = 38 if value.length()>5 else 52
	label.pixel_size = 0.007
	label.modulate = color
	label.outline_size = 8
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = pos
	add_child(label)
	effects.append({"node":label,"age":0.0,"life":0.85,"kind":"number"})

func _update_effects(delta: float) -> void:
	for i in range(effects.size()-1,-1,-1):
		var effect: Dictionary = effects[i]
		effect.age += delta
		var node: Node3D = effect.node
		if effect.kind=="cast_mark" and simulation.pending_attack.get("ability_id","")!=effect.ability_id: effect.age=effect.life
		if effect.kind=="fall": node.position+=Vector3(0,-10.0*delta,0)
		if effect.kind == "ring": node.scale = Vector3.ONE*(1.0+effect.age*3.0)
		elif effect.kind == "nova": node.scale=Vector3.ONE*lerpf(0.15,1.0,minf(1.0,effect.age/effect.life))
		elif effect.kind == "spark":
			node.position += Vector3(effect.velocity)*delta
			effect.velocity.y -= delta*8.0
		elif effect.kind == "number": node.position.y += delta*0.9
		elif effect.kind == "loot":
			node.position = node.position.lerp(hero.position+Vector3(0,0.8,0),delta*4.0)
		elif effect.kind == "recovered_gear":
			node.position.y=float(effect.base_y)+sin(elapsed*3.2+float(effect.phase))*0.11
			node.rotation.y+=delta*0.9
		if effect.age >= effect.life:
			node.queue_free()
			effects.remove_at(i)

func _build_regional_details() -> void:
	materials.wood = _material(Color("302b28"))
	materials.pages = _material(Color("adac85"))
	materials.moss = _material(Color("315746"))
	materials.crystal = _material(Color("655184"),0.55)
	materials.iron = _material(Color("262329"),0.7)
	if simulation.uses_journey():
		_build_journey_details()
		return
	match region_index:
		0:
			# An enormous broken bell marks the original tower's final chamber.
			_cylinder(Vector3(0,3.5,-67.4),1.05,0.58,1.5,materials.metal,16)
			_ring(Vector3(0,2.78,-67.4),1.02,materials.metal)
			_box(Vector3(0,2.5,-67.4),Vector3(0.15,0.70,0.15),materials.dark)
			_box(Vector3(0,4.6,-67.4),Vector3(0.12,0.8,0.12),materials.metal)
		1:
			_liquid(Vector3(0,-0.36,-28),Vector2(44,104),false)
			for chamber in range(7):
				var z:=3.0-chamber*11.2
				if chamber==3: continue
				for side in [-1.0,1.0]:
					_bookshelf(Vector3(side*6.1,0,z),side)
					_box(Vector3(side*5.8,0.025,z+3.0),Vector3(1.7,0.025,1.2),materials.moss)
					for reed in range(5):
						var stem:=_box(Vector3(side*(5.8+reed*0.11),0.35,z+3.0+reed*0.09),Vector3(0.025,0.65+reed*0.06,0.025),materials.moss)
						stem.rotation.z=side*0.16
				for side in [-1.0,1.0]:
					var broken:=_box(Vector3(side*4.9,0.13,z-3.0),Vector3(0.5,0.24,0.65),materials.wood)
					broken.rotation.y=side*0.7
					_box(broken.position+Vector3(0,0.13,0),Vector3(0.4,0.03,0.55),materials.pages)
			for side in [-1.0,1.0]:
				_bookshelf(Vector3(side*5.3,0,-64),side)
		2:
			for chamber in range(7):
				var z:=4.0-chamber*11.2
				if chamber==3: continue
				for side in [-1.0,1.0]:
					_rib_arch(Vector3(side*6.3,0,z),side)
					for i in range(4):
						var pos:=Vector3(side*(5.4+i*0.4),0,z+2.4+i*0.6)
						var shard:=_cylinder(pos+Vector3(0,0.6+i*0.19,0),0.28+i*0.09,0.015,1.2+i*0.38,materials.crystal,5)
						shard.rotation.z=side*(0.12+i*0.07)
						shard.rotation.y=i*1.7
					for bone in range(7):
						var fragment:=_box(Vector3(side*(4.9+float(bone%3)*0.45),0.1,z-3.1+bone*0.3),Vector3(0.6,0.14,0.12),materials.bone)
						fragment.rotation.y=float(bone)*0.9
			# An open blackglass basin replaces the tower's empty void.
			_box(Vector3(0,-3.8,-28),Vector3(60,0.5,115),materials.dark)
			for side in [-1.0,1.0]:
				for i in range(10):
					_cylinder(Vector3(side*(9.2+float(i%3)),0.2,-3.0-i*7),0.75,0.02,4.2,materials.crystal,5)
		3:
			_liquid(Vector3(0,-0.55,-28),Vector2(44,104),true)
			for chamber in range(7):
				var z:=4.0-chamber*11.2
				if chamber==3: continue
				for side in [-1.0,1.0]:
					_furnace(Vector3(side*6.1,0,z),side)
					for i in range(5):
						_box(Vector3(side*5.8,0.04,z+3.2+i*0.22),Vector3(1.8,0.08,0.08),materials.iron)
					for link in range(6):
						var chain:=_ring(Vector3(side*5.6,3.0-link*0.34,z-3.9),0.19,materials.metal)
						chain.rotation.x=PI/2
						chain.rotation.y=float(link%2)*PI/2
			# Crown-shaped gate silhouettes the final arena.
			for i in range(7):
				var height:=3.2+float(3-abs(i-3))*0.45
				_cylinder(Vector3((i-3)*0.72,height/2,-67.3),0.26,0.0,height,materials.metal,5)

func _cylinder(pos: Vector3,bottom: float,top: float,height: float,mat: Material,sides: int = 8) -> MeshInstance3D:
	var node:=MeshInstance3D.new()
	var mesh:=CylinderMesh.new()
	mesh.bottom_radius=bottom
	mesh.top_radius=top
	mesh.height=height
	mesh.radial_segments=sides
	node.mesh=mesh
	node.material_override=mat
	node.position=pos
	add_child(node)
	return node

func _liquid(pos: Vector3,dimensions: Vector2,lava: bool) -> void:
	var mat:=ShaderMaterial.new()
	mat.shader=preload("res://assets/shaders/dungeon_water.gdshader")
	mat.set_shader_parameter("water_color",Color("491b0b") if lava else Color("123d42"))
	mat.set_shader_parameter("crest_color",Color("f57d29") if lava else Color("459082"))
	mat.set_shader_parameter("lava",1.0 if lava else 0.0)
	var mesh:=PlaneMesh.new()
	mesh.size=dimensions
	var surface:=MeshInstance3D.new()
	surface.name="LavaBasin" if lava else "FloodedArchive"
	surface.mesh=mesh
	surface.material_override=mat
	surface.position=pos
	add_child(surface)

func _bookshelf(pos: Vector3,side: float) -> void:
	_box(pos+Vector3(side*0.34,1.35,0),Vector3(0.14,2.7,3.4),materials.wood)
	for end in [-1.0,1.0]:
		_box(pos+Vector3(0,1.35,end*1.7),Vector3(0.8,2.7,0.13),materials.metal)
	for shelf in range(4):
		_box(pos+Vector3(0,0.18+shelf*0.75,0),Vector3(0.8,0.12,3.4),materials.wood)
		if shelf==3: continue
		for book in range(11):
			var height:=0.34+float((book+shelf)%3)*0.085
			var volume:=_box(pos+Vector3(-side*0.14,0.28+shelf*0.75+height/2,-1.40+book*0.28),Vector3(0.46,height,0.20),materials.pages if book%4==0 else materials.cloth)
			volume.rotation.x=0.10 if book%5==0 else 0.0

func _rib_arch(pos: Vector3,side: float) -> void:
	_box(pos+Vector3(0,0.20,0),Vector3(1.25,0.4,1.7),materials.dark)
	for i in range(6):
		var t:=float(i)/5.0
		var rib:=_box(pos+Vector3(-side*pow(t,1.5)*1.7,0.6+t*3.7,0),Vector3(0.42-t*0.24,0.92,0.38-t*0.20),materials.bone)
		rib.rotation.z=side*t*0.72
		var second:=_box(pos+Vector3(-side*pow(t,1.5)*1.5,0.6+t*3.3,0.8),Vector3(0.34-t*0.18,0.82,0.30-t*0.14),materials.bone)
		second.rotation.z=side*t*0.72

func _furnace(pos: Vector3,side: float) -> void:
	_box(pos+Vector3(0,0.95,0),Vector3(1.6,1.9,2.5),materials.dark)
	_box(pos+Vector3(-side*0.82,0.85,0),Vector3(0.04,0.95,1.65),materials.fire)
	for bar in range(6):
		_box(pos+Vector3(-side*0.87,0.85,-0.77+bar*0.31),Vector3(0.08,1.14,0.075),materials.iron)
	_box(pos+Vector3(0,2.0,0),Vector3(1.85,0.23,2.7),materials.metal)
	_box(pos+Vector3(side*0.23,2.80,0),Vector3(0.68,1.45,0.86),materials.iron)
	_box(pos+Vector3(side*0.23,3.59,0),Vector3(0.95,0.20,1.1),materials.metal)

func set_shadows(enabled: bool) -> void:
	if is_instance_valid(sun): sun.shadow_enabled=enabled

func _build_journey_floor() -> void:
	var cells: Dictionary={}
	var rectangles := Layout.floor_rects(region_index,simulation.layout_seed(),simulation.movement_seed(),simulation.uses_wandering_routes(),simulation.uses_scouting_routes(),simulation.uses_expanded_scouting_routes())
	var tile_size := 1.0
	for x in range(-16,17):
		for z in range(-76,10):
			var point := Vector2(x,z)*tile_size
			for rect in rectangles:
				if rect.grow(0.5).has_point(point):
					cells[Vector2i(x,z)]=true
					break
	var batches: Array=[[],[],[],[],[]]
	var covered: Dictionary={}
	for cell: Vector2i in cells:
		var position3 := Vector3(cell.x,-0.2,cell.y)
		var dimensions := Vector3(0.97,0.36,0.97)
		if not covered.has(cell):
			if cells.has(cell+Vector2i.RIGHT) and posmod(cell.x+cell.y,3)!=0:
				dimensions.x=1.97
				position3.x+=0.5
				covered[cell+Vector2i.RIGHT]=true
			position3.y+=float(posmod(cell.x*17+cell.y*29,7)-3)*0.003
			batches[posmod(cell.x*17+cell.y*13,5)].append(Transform3D(Basis.IDENTITY.scaled(dimensions),position3))
		for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			if cells.has(cell+direction): continue
			# Only silhouettes at floor boundaries; passages remain open.
			var rear: bool=direction.x<0 or direction.y<0
			var height := 1.65 if rear and region_index!=2 else 0.42
			var edge := Vector3(cell.x+direction.x*0.49,height*0.5,cell.y+direction.y*0.49)
			var shape := Vector3(0.16,height,1.0) if direction.x!=0 else Vector3(1.0,height,0.16)
			_box(edge,shape,materials.stone)
			_box(edge+Vector3(0,height*0.5,0),Vector3(shape.x+0.08,0.1,shape.z+0.08),materials.edge)
	var paver:=preload("res://scripts/sculpted_mesh.gd").paver()
	for m in range(5): _batch_mesh(batches[m],floor_materials[m],paver,false)
	for room in range(6):
		var origin := _point(Layout.center(region_index,room,simulation.layout_seed()))
		for side in [-1.0,1.0]:
			for end in [-1.0,1.0]:
				_pillar(origin+Vector3(side*5.5,0,end*4.3),side<0)
			_torch(origin+Vector3(side*4.9,1.5,0))
		for i in range(12):
			var rubble := _box(origin+Vector3((-1.0 if i%2==0 else 1.0)*rng.randf_range(4.8,5.3),0.07,rng.randf_range(-3.8,3.8)),Vector3(0.2,0.14,0.3),materials.stone)
			rubble.rotation.y=rng.randf()*TAU
		if room in [0,3] and region_index in [0,3]:
			_box(origin+Vector3(0,0.012,0),Vector3(2.8,0.015,5.2),materials.cloth)
		if room>0:
			var previous := Layout.center(region_index,room-1,simulation.layout_seed())
			var current := Layout.center(region_index,room,simulation.layout_seed())
			var middle := (previous.y+current.y)*0.5
			# Entry markers frame both ends of a bent connecting gallery.
			for point in [Vector2(previous.x,middle),Vector2(current.x,middle)]:
				for side in [-1.0,1.0]:
					_box(_point(point)+Vector3(0,0.4,side*2.0),Vector3(0.3,0.8,0.3),materials.metal)
	_arch(Vector3(0,0,7.8),0)
	var boss_center := _point(Layout.center(region_index,5,simulation.layout_seed()))
	_ring(boss_center+Vector3(0,0.04,0),3.4,materials.metal)
	_ring(boss_center+Vector3(0,0.045,0),3.1,materials.dark)

func _build_journey_details() -> void:
	if region_index==1: _liquid(Vector3(0,-0.5,-32),Vector2(48,105),false)
	if region_index==3: _liquid(Vector3(0,-0.5,-32),Vector2(48,105),true)
	if region_index==2: _box(Vector3(0,-4,-32),Vector3(55,0.5,110),materials.dark)
	for room in range(6):
		var origin := _point(Layout.center(region_index,room,simulation.layout_seed()))
		for side in [-1.0,1.0]:
			match region_index:
				0:
					_sarcophagus(origin+Vector3(side*4.9,0,2.5))
					if side<0: _banner(origin+Vector3(-5.4,3.4,0))
				1:
					_bookshelf(origin+Vector3(side*5.0,0,1),side)
					_box(origin+Vector3(side*4.7,0.025,3.3),Vector3(1.6,0.025,1.2),materials.moss)
				2:
					_rib_arch(origin+Vector3(side*5.4,0,1.2),side)
					for i in range(3):
						var shard := _cylinder(origin+Vector3(side*(4.9+i*0.25),0.7+i*0.2,3),0.25,0.015,1.4+i*0.4,materials.crystal,5)
						shard.rotation.z=side*0.25
				3:
					_furnace(origin+Vector3(side*5.1,0,1.5),side)
	var boss_center := _point(Layout.center(region_index,5,simulation.layout_seed()))
	if region_index==0:
		_cylinder(boss_center+Vector3(0,3.5,-4.3),1.05,0.58,1.5,materials.metal,16)
		_ring(boss_center+Vector3(0,2.78,-4.3),1.02,materials.metal)
	elif region_index==3:
		for i in range(7):
			var height: float = 3.0+(3-absi(i-3))*0.4
			_cylinder(boss_center+Vector3((i-3)*0.7,height*0.5,-4.4),0.26,0.0,height,materials.metal,5)

func _build_journey_props() -> void:
	for room in [1,3,5]:
		var prop := Node3D.new()
		prop.name="HealingWell" if room==1 else ("SanctumSeal" if room==3 else "GuardianReliquary")
		prop.position=_point(Layout.interact_point(region_index,room,simulation.layout_seed()))
		add_child(prop)
		journey_props[room]=prop
		_box(Vector3(0,-0.03,0),Vector3(1.5,0.15,1.5),materials.dark,prop)
		if room==1:
			for side in [-1.0,1.0]:
				_box(Vector3(side*0.6,0.3,0),Vector3(0.18,0.6,1.4),materials.edge,prop)
				_box(Vector3(0,0.3,side*0.6),Vector3(1.4,0.6,0.18),materials.edge,prop)
			_box(Vector3(0,0.28,0),Vector3(1.0,0.06,1.0),materials.soul,prop)
		elif room==3:
			_box(Vector3(0,0.55,0),Vector3(0.8,1.1,0.8),materials.stone,prop)
			var seal := _box(Vector3(0,1.4,0),Vector3(0.5,0.5,0.5),materials.soul,prop)
			seal.name="SealGem"
			seal.rotation=Vector3(0.5,0.6,0.5)
		else:
			_box(Vector3(0,0.35,0),Vector3(1.3,0.7,0.85),materials.dark,prop)
			for x in [-0.48,0.48]: _box(Vector3(x,0.4,0),Vector3(0.1,0.78,0.9),materials.metal,prop)
			var lid := _box(Vector3(0,0.77,0),Vector3(1.35,0.16,0.9),materials.metal,prop)
			lid.name="ChestLid"
			var beam := _box(Vector3(0,1.8,0),Vector3(0.09,2.5,0.09),materials.soul,prop)
			beam.name="LootBeam"
			beam.visible=false
	sanctum_gate=Node3D.new()
	sanctum_gate.name="SanctumGate"
	sanctum_gate.position=_point(Layout.center(region_index,5,simulation.layout_seed()))+Vector3(0,0,5.8)
	add_child(sanctum_gate)
	for i in range(9): _box(Vector3((i-4)*0.48,1.1,0),Vector3(0.1,2.2,0.1),materials.metal,sanctum_gate)
	_box(Vector3(0,2.1,0),Vector3(4.3,0.16,0.16),materials.metal,sanctum_gate)
	_sync_journey_props(100.0)

func _sync_journey_props(delta: float) -> void:
	if journey_props.is_empty(): return
	var gem: Node3D=journey_props[3].get_node("SealGem")
	gem.visible=not simulation.journey.seal_broken
	var gate_height := -2.8 if simulation.journey.seal_broken else 0.0
	sanctum_gate.position.y=move_toward(sanctum_gate.position.y,gate_height,delta*2.6)
	var lid: Node3D=journey_props[5].get_node("ChestLid")
	lid.rotation.x=lerpf(lid.rotation.x,-1.1 if simulation.journey.chest_open else 0.0,minf(1.0,delta*5.0))
	journey_props[5].get_node("LootBeam").visible=simulation.journey.chest_open

func show_recovered_gear(items: Array) -> void:
	if not simulation.uses_journey() or not journey_props.has(5) or items.is_empty(): return
	recovered_drops.clear()
	var count:=mini(items.size(),2)
	var chest: Node3D=journey_props[5]
	for index_value in range(count):
		var item=items[index_value]
		if not item is Dictionary: continue
		var slot:=String(item.get("slot","Weapon"))
		var quality:=String(item.get("quality","RARE")).to_upper()
		var tint:=Color(LOOT_COLORS.get(quality,"76bfe8"))
		var relic:=Node3D.new()
		relic.name="RecoveredRelic"
		var phase_offset:=float(index_value)*PI
		var base_y:=1.55
		relic.position=chest.position+Vector3((float(index_value)-float(count-1)*0.5)*1.45,base_y,0.0)
		add_child(relic)
		_ring(Vector3(0,0.05,0),0.48,_material(tint,0.0,true),relic)
		_gear_drop_shape(slot,tint,relic)
		var title:=Label3D.new()
		title.name="RelicLabel"
		title.text=String(item.get("name","Recovered Relic"))+"\n"+quality+"  •  "+slot.to_upper()
		title.font_size=28
		title.pixel_size=0.006
		title.modulate=tint.lightened(0.14)
		title.outline_size=5
		title.outline_modulate=Color("171419")
		title.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		title.no_depth_test=true
		title.position=Vector3(0,1.85,0)
		relic.add_child(title)
		var saved_item: Dictionary=item.duplicate(true)
		recovered_drops.append({"node":relic,"item":saved_item,"label":title})
		effects.append({"node":relic,"age":0.0,"life":2.4,"kind":"recovered_gear","base_y":base_y,"phase":phase_offset})

func _gear_drop_shape(slot: String,tint: Color,parent: Node3D) -> void:
	var metal:=_material(tint,0.72,true)
	var dark:=_material(tint.darkened(0.50),0.52)
	match slot:
		"Weapon":
			var blade:=_box(Vector3(0,0.62,0),Vector3(0.14,0.96,0.09),metal,parent)
			blade.rotation.z=-0.12
			_box(Vector3(0,0.05,0),Vector3(0.52,0.10,0.14),dark,parent)
			_box(Vector3(0,-0.16,0),Vector3(0.11,0.34,0.11),_material(Color("403027"),0.35),parent)
		"Helmet":
			_drop_sphere(Vector3(0,0.54,0),0.34,metal,parent)
			_box(Vector3(0,0.32,-0.27),Vector3(0.46,0.11,0.12),dark,parent)
			_box(Vector3(0,0.85,0),Vector3(0.10,0.42,0.12),metal,parent)
		"Chest":
			_box(Vector3(0,0.54,0),Vector3(0.68,0.70,0.32),metal,parent)
			_box(Vector3(-0.42,0.77,0),Vector3(0.28,0.29,0.36),dark,parent)
			_box(Vector3(0.42,0.77,0),Vector3(0.28,0.29,0.36),dark,parent)
		"Gloves":
			for side in [-1.0,1.0]:
				_box(Vector3(side*0.25,0.48,0),Vector3(0.25,0.39,0.26),metal,parent)
				_box(Vector3(side*0.25,0.22,0),Vector3(0.31,0.11,0.30),dark,parent)
		"Boots":
			for side in [-1.0,1.0]:
				_box(Vector3(side*0.20,0.40,0),Vector3(0.23,0.54,0.27),metal,parent)
				_box(Vector3(side*0.20,0.12,-0.08),Vector3(0.29,0.12,0.41),dark,parent)
		"Amulet":
			_ring(Vector3(0,0.57,0),0.28,metal,parent)
			_drop_sphere(Vector3(0,0.56,0),0.16,metal,parent)
		_:
			_drop_sphere(Vector3.ZERO,0.34,metal,parent)

func _drop_sphere(position_value: Vector3,radius: float,material: Material,parent: Node3D) -> MeshInstance3D:
	var node:=MeshInstance3D.new()
	var mesh:=SphereMesh.new()
	mesh.radius=radius
	mesh.height=radius*2.0
	mesh.radial_segments=16
	mesh.rings=8
	node.mesh=mesh
	node.material_override=material
	node.position=position_value
	parent.add_child(node)
	return node

func _show_technique(event: Dictionary) -> void:
	var key: String=event.ability_id
	var definition: Dictionary=Skills.DEFINITIONS[key]
	var tint := Color(definition.color)
	var material := _material(tint,0.0,true)
	_float_text(hero.position+Vector3(0,3.2,0),String(definition.short),tint)
	if definition.kind=="guard":
		var pulse := _ring(hero.position+Vector3(0,0.1,0),0.9,material)
		effects.append({"node":pulse,"age":0.0,"life":0.5,"kind":"ring"})
	elif key=="chain" or definition.kind=="single":
		for i in range(event.points.size()-1):
			var start := _point(event.points[i])+Vector3(0,1.4,0)
			var finish := _point(event.points[i+1])+Vector3(0,1.2,0)
			var previous := start
			for part in range(1,7):
				var point := start.lerp(finish,part/6.0)
				if key=="chain" and part<6: point+=Vector3(0.12 if part%2==0 else -0.12,0.14 if part%2==0 else -0.14,0)
				if previous.distance_to(point)>0.001:
					var bolt := _box((previous+point)*0.5,Vector3(0.08,0.08,previous.distance_to(point)),material)
					bolt.look_at(point)
					effects.append({"node":bolt,"age":0.0,"life":0.32,"kind":"bolt"})
				previous=point
	else:
		var origin := _point(event.position)
		var pulse := _ring(origin+Vector3(0,0.12,0),float(event.radius),material)
		pulse.scale=Vector3.ONE*0.15
		effects.append({"node":pulse,"age":0.0,"life":0.45,"kind":"nova"})
		for i in range(10 if key=="rain" else 6):
			var angle := TAU*i/(10.0 if key=="rain" else 6.0)
			var radius := float(event.radius)*0.7
			var position3 := origin+Vector3(sin(angle)*radius,3.0,cos(angle)*radius)
			var streak := _box(position3,Vector3(0.04,0.9,0.04) if key=="rain" else Vector3(0.12,1.2,0.12),material)
			effects.append({"node":streak,"age":0.0,"life":0.3,"kind":"fall"})

func _build_trial_gate() -> void:
	var glow:=_material(Color("9365c4"),0.0,true)
	var center:=Vector3(0,1.65,5.5)
	for radius in [1.4,1.65]:
		var ring:=_ring(center,radius,glow)
		ring.name="AshTrialGate"
		ring.rotation_degrees.x=90
		ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in range(8):
		var angle:=TAU*i/8.0
		var rune:=_box(center+Vector3(sin(angle)*1.55,cos(angle)*1.55,0),Vector3(0.14,0.25,0.12),glow)
		rune.rotation.z=-angle

func _build_dressed_rooms() -> void:
	# Secondary architecture below and behind the playable floor gives the ruins mass.
	var grime:=ShaderMaterial.new()
	grime.shader=preload("res://assets/shaders/ground_grime.gdshader")
	grime.set_shader_parameter("tint",Color(0.075,0.055,0.042,0.68))
	var blood:=ShaderMaterial.new()
	blood.shader=preload("res://assets/shaders/ground_grime.gdshader")
	blood.set_shader_parameter("tint",Color(0.13,0.032,0.024,0.46))
	for room in range(6):
		var origin:=_point(Layout.center(region_index,room,simulation.layout_seed())) if simulation.uses_journey() else Vector3(0,0,4-room*11.2)
		_box(origin+Vector3(0,-1.1,0),Vector3(12.1,1.7,9.4),materials.dark)
		for side in [-1.0,1.0]:
			for step in range(3):
				_box(origin+Vector3(side*(5.7-step*0.28),-1.6-step*0.7,0),Vector3(0.85,0.75,9.5),materials.stone)
			for z in [-3.5,0.0,3.5]:
				# Molded bases and inset ribbed niches break the flat boundary wall.
				_box(origin+Vector3(side*5.5,0.35,z),Vector3(0.9,0.7,1.1),materials.dark)
				if side<0 and region_index!=2:
					_pillar(origin+Vector3(-6.1,0,z),true)
					_box(origin+Vector3(-6.55,1.8,z),Vector3(0.25,3.6,2.9),materials.dark)
					for bar in range(4):
						_box(origin+Vector3(-6.37,1.7,z-0.75+bar*0.5),Vector3(0.07,2.4,0.07),materials.metal)
		if region_index in [0,1]:
			_arch(origin+Vector3(-6.6,-0.15,0),PI/2)
			for far in [-1.0,1.0]:
				_pillar(origin+Vector3(-9.3,-3.1,far*3.6),true)
		for i in range(9):
			var patch:=MeshInstance3D.new()
			var plane:=PlaneMesh.new()
			plane.size=Vector2(2.0+rng.randf()*2.0,1.2+rng.randf()*2.0)
			patch.mesh=plane
			patch.material_override=blood if i%4==0 and region_index!=1 else grime
			patch.position=origin+Vector3(rng.randf_range(-4.5,4.5),0.025+i*0.0004,rng.randf_range(-3.7,3.7))
			patch.rotation.y=rng.randf()*TAU
			patch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(patch)
		for i in range(18):
			var side: float=-1.0 if i%2==0 else 1.0
			var rock:=_cylinder(origin+Vector3(side*rng.randf_range(4.2,5.4),0.08,rng.randf_range(-4,4)),rng.randf_range(0.12,0.28),0.05,rng.randf_range(0.13,0.38),materials.stone,5)
			rock.rotation=Vector3(rng.randf()*0.6,rng.randf()*TAU,rng.randf()*0.4)
	var mist:=MeshInstance3D.new()
	mist.name="LowCryptMist"
	var veil:=PlaneMesh.new()
	veil.size=Vector2(52,110)
	mist.mesh=veil
	var fog_material:=ShaderMaterial.new()
	fog_material.shader=preload("res://assets/shaders/crypt_mist.gdshader")
	fog_material.set_shader_parameter("mist_color",Color(Color(theme.fog).lightened(0.18),0.42))
	mist.material_override=fog_material
	mist.position=Vector3(0,-0.7,-32)
	mist.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mist)
	if region_index==0:
		_box(Vector3(0,-4.6,-32),Vector3(54,0.3,110),materials.dark)
		for side in [-1.0,1.0]:
			for i in range(16):
				var rock:=_cylinder(Vector3(side*(8.5+float(i%3)), -2.6,-3-i*4.4),2.0,0.6,4.5,materials.dark,5)
				rock.rotation.z=side*0.25
	# Floating motes remain decorative and never consume simulation randomness.
	var dust:=CPUParticles3D.new()
	dust.name="DungeonDust"
	dust.amount=90
	dust.lifetime=9.0
	dust.preprocess=9.0
	dust.emission_shape=CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents=Vector3(16,2.2,43)
	dust.position=Vector3(0,1.8,-32)
	dust.direction=Vector3(0.3,1.0,0)
	dust.initial_velocity_min=0.08
	dust.initial_velocity_max=0.22
	dust.gravity=Vector3.ZERO
	dust.scale_amount_min=0.012
	dust.scale_amount_max=0.035
	var mote:=SphereMesh.new()
	mote.radial_segments=4
	mote.rings=2
	dust.mesh=mote
	dust.material_override=_material(Color("b49a73"),0,true)
	add_child(dust)

func _impact_sparks(origin: Vector3,color: Color) -> void:
	for i in range(5):
		var spark:=_box(origin,Vector3(0.025,0.07,0.025),_material(color,0,true))
		spark.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		effects.append({"node":spark,"age":0.0,"life":0.22+rng.randf()*0.15,"kind":"spark","velocity":Vector3(rng.randf_range(-2.5,2.5),rng.randf_range(0.6,2.2),rng.randf_range(-2.5,2.5))})

func _slash_arc(origin: Vector3,color: Color) -> void:
	var mesh:=SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(12):
		var a:=hero.rotation.y-1.2+i*0.2
		var b:=a+0.2
		for point in [Vector2(a,1.1),Vector2(b,1.1),Vector2(a,1.9),Vector2(b,1.1),Vector2(b,1.9),Vector2(a,1.9)]:
			mesh.add_vertex(Vector3(-sin(point.x)*point.y,0.9+sin(point.x)*0.25,-cos(point.x)*point.y))
	mesh.generate_normals()
	var arc:=MeshInstance3D.new()
	arc.mesh=mesh.commit()
	var mat:=_material(Color(color,0.45),0,true)
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	arc.material_override=mat
	arc.position=origin
	arc.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(arc)
	effects.append({"node":arc,"age":0.0,"life":0.16,"kind":"slash"})
