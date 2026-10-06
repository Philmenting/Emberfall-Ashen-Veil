extends Node3D
## A continuous, deterministic dungeon. Combat requests only occur in weapon range.
signal simulation_advanced(events: Array)
var simulation: RefCounted
var actor_by_id: Dictionary = {}
var bars: Dictionary = {}
var warnings: Dictionary = {}
var last_stage := -1
var target_ring: MeshInstance3D
var hero_marker: MeshInstance3D
signal state_changed(description: String)
const Skills = preload("res://scripts/class_skills.gd")
const Layout = preload("res://scripts/dungeon_layout.gd")
const Actor = preload("res://scripts/dungeon_actor.gd")
const Ruins = preload("res://scripts/ruin_architecture.gd")
const ThemeData = preload("res://scripts/dungeon_theme.gd")
const REGION_BACKDROPS = [preload("res://assets/world/ashen-realms/spire.png"),preload("res://assets/world/ashen-realms/archive.png"),preload("res://assets/world/ashen-realms/ossuary.png"),preload("res://assets/world/ashen-realms/citadel.png")]
const BossPatterns = preload("res://scripts/boss_patterns.gd")
const CAMERA_BOOM := Vector3(8.0,9.3,13.5)
const LOOT_COLORS := {"COMMON":"c7c3bc","UNCOMMON":"83cf8b","RARE":"76bfe8","EPIC":"bb91ee","LEGENDARY":"ffd277"}
var theme: Dictionary = {}
var character_class := "Vowkeeper"
var region_index := 0
var active := true
var damage_numbers := true
var reduced_motion := false
var hud_bottom_ratio := 0.84
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
var camera_zoom := 0.94
var camera_shake_time := 0.0
var camera_shake_strength := 0.0
var materials: Dictionary = {}
var floor_materials: Array[ShaderMaterial] = []
var rng := RandomNumberGenerator.new()
var last_description := ""
var journey_props: Dictionary = {}
var recovered_drops: Array[Dictionary] = []
var sanctum_gate: Node3D
var sanctuary_beams: Array[MeshInstance3D] = []
var sanctuary_lights: Array[SpotLight3D] = []
var sanctuary_glass: ShaderMaterial
var sanctuary_beam_material: ShaderMaterial
var sanctuary_gold: StandardMaterial3D
var region_matte: MeshInstance3D
var court_material: ShaderMaterial
var hero_equipment: Dictionary={}
var dressing_room: int=-1
var dressing_clearance: Array[Rect2]=[]
var occluder_batches: Array[Dictionary]=[]
var framing_scale := 1.0
var projectile_emitted := false
var shot_stage := -1
var shot_aspect := -1.0
var shot_scale := 1.0
var shot_points: Array[Vector3] = []
var shot_travel := false
var shot_pan := Vector3.ZERO
var framing_pan := Vector3.ZERO
var shot_bottom := -1.0

func character_cache_keys() -> Array[String]:
	var keys: Array[String]=[character_class]
	keys.append_array(Actor.HOSTILES)
	keys.append("guardian_%d" % clampi(region_index,0,3))
	return keys

func _ready() -> void:
	region_index = clampi(region_index,0,3)
	# This retains a warm roster; it does not instantiate absent appearances.
	# Any other still-live world/portrait is protected by Rig's weak live pins.
	Actor.retain_character_cache(character_cache_keys())
	theme = ThemeData.definition(region_index)
	rng.seed = 7291 + region_index
	_build_materials()
	_build_environment()
	_prepare_dressing_clearance()
	_build_court_ground()
	_build_dungeon()
	_build_regional_details()
	_build_dressed_rooms()
	_build_sanctuary_details()
	# Regional landmarks are integrated in the connected room kit.
	_build_ruin_depth()
	_batch_static_geometry()
	if simulation.uses_journey(): _build_journey_props()
	if simulation.Contract.mode(simulation.contract())=="trial": _build_trial_gate()
	hero = Actor.new()
	hero.kind = character_class
	hero.position = _point(simulation.hero_pos)
	add_child(hero)
	if hero.has_method("configure_equipment"): hero.configure_equipment(hero_equipment,character_class)
	if not simulation.pending_attack.is_empty():
		var pending_style:=String(simulation.pending_attack.get("ability_id","signature" if simulation.pending_attack.get("skill",false) else "basic"))
		var duration: float=Skills.DEFINITIONS.get(pending_style,{}).get("cast",0.3)
		hero.strike(pending_style,duration,true)
		hero.sync_attack(float(simulation.pending_attack.left))
		hero.animate(0,false,0)
	if character_class=="Arcanist":
		ward_shell = MeshInstance3D.new()
		var shell_mesh := SphereMesh.new()
		shell_mesh.radius=0.88
		shell_mesh.height=2.3
		shell_mesh.radial_segments=16
		shell_mesh.rings=8
		ward_shell.mesh=shell_mesh
		var shell_material := ShaderMaterial.new()
		shell_material.shader=preload("res://assets/shaders/ward_surface.gdshader")
		ward_shell.material_override=shell_material
		ward_shell.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ward_shell.position=Vector3(0,1.15,0)
		ward_shell.visible=false
		hero.add_child(ward_shell)
	guard_visual=Node3D.new()
	guard_visual.name="GuardVisual"
	hero.add_child(guard_visual)
	var guard_color := Color("edc98b") if character_class=="Vowkeeper" else Color("89dbe9") if character_class=="Arcanist" else Color("97bdb5")
	var guard_material := ShaderMaterial.new()
	guard_material.shader=preload("res://assets/shaders/ward_surface.gdshader")
	guard_material.set_shader_parameter("ward_color",guard_color)
	for segment in range(6):
		var surface:=SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for step in range(8):
			for point: Vector2 in [Vector2(step,0),Vector2(step+1,0),Vector2(step+1,1),Vector2(step,0),Vector2(step+1,1),Vector2(step,1)]:
				var angle: float=TAU*float(segment)/6.0+(point.x/8.0-0.5)*0.80
				var radius: float=0.86 if point.y==0 else 0.73
				surface.add_vertex(Vector3(sin(angle)*radius,0.28+point.y*1.25,cos(angle)*radius))
		var plate:=MeshInstance3D.new(); surface.generate_normals(); plate.mesh=surface.commit()
		plate.material_override=guard_material; guard_visual.add_child(plate)
		plate.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	guard_visual.visible=simulation.guard_time>0.0
	_ensure_wave(mini(simulation.stage,5))
	target_ring = _ring(Vector3.ZERO,0.65,_material(Color("9c8763")))
	target_ring.visible = false
	hero_marker=_ring(hero.position+Vector3(0,.075,0),.47,_material(Color("6f9892")))
	hero_marker.name="HeroFootprint"
	hero_marker.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 38.0
	camera.near = 0.2
	camera.far = 125.0
	add_child(camera)
	camera.current = true
	camera_target = _camera_anchor()
	camera_zoom = 0.86 if _boss_is_active() else 0.94
	_build_region_matte()
	_position_camera()
	var lantern := OmniLight3D.new()
	lantern.light_color = Color("cad8e5")
	lantern.light_energy = 1.18
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
	var cloth:=ShaderMaterial.new()
	cloth.shader=preload("res://assets/shaders/crafted_surface.gdshader")
	cloth.set_shader_parameter("surfaces",preload("res://assets/materials/field-surfaces/material-atlas.png"))
	cloth.set_shader_parameter("cell",Vector2(0,1))
	cloth.set_shader_parameter("tint",Color(theme.cloth))
	cloth.set_shader_parameter("roughness",.96)
	cloth.set_shader_parameter("scale",1.35)
	materials.cloth=cloth
	materials.bone = _material(Color("a29b86"))
	for i in range(5):
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://assets/shaders/weathered_stone.gdshader")
		mat.set_shader_parameter("stone_tint", Color(theme.stone).darkened(float(i)*0.055))
		mat.set_shader_parameter("roughness",theme.roughness)
		mat.set_shader_parameter("weathering",0.24 if region_index==1 else 0.08)
		mat.set_shader_parameter("mineral_tint",Color(["384746","294d40","52435f","503a2c"][region_index]))
		_set_stone_textures(mat)
		floor_materials.append(mat)
	materials.stone = floor_materials[2]
	var edge_mat := ShaderMaterial.new()
	edge_mat.shader = preload("res://assets/shaders/weathered_stone.gdshader")
	edge_mat.set_shader_parameter("stone_tint", Color(theme.edge))
	_set_stone_textures(edge_mat)
	materials.edge = edge_mat
	materials.intarsia=floor_materials[4].duplicate()
	materials.intarsia.set_shader_parameter("stone_tint",Color(theme.stone).darkened(0.34))

func _set_stone_textures(mat: ShaderMaterial) -> void:
	mat.set_shader_parameter("stone_color",preload("res://assets/materials/stone/Rock030_1K-JPG_Color.jpg"))
	mat.set_shader_parameter("stone_normal",preload("res://assets/materials/stone/Rock030_1K-JPG_NormalGL.jpg"))
	mat.set_shader_parameter("stone_roughness",preload("res://assets/materials/stone/Rock030_1K-JPG_Roughness.jpg"))

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
	env.ambient_light_energy = 0.18
	env.sky=preload("res://scripts/dungeon_lighting.gd").reflection_sky()
	env.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(theme.fog)
	env.fog_density = theme.density
	environment.environment = env
	add_child(environment)
	var moon := DirectionalLight3D.new()
	sun = moon
	moon.rotation_degrees = Vector3(-52,-36,0)
	moon.light_color = Color(theme.moon)
	moon.light_energy = 1.06
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 32.0
	# One focused room shadow map avoids four repeated scene passes.
	moon.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	add_child(moon)
	var rim:=DirectionalLight3D.new()
	rim.rotation_degrees=Vector3(-24,145,0)
	rim.light_color=Color("82bed4")
	rim.light_energy=0.25
	add_child(rim)
	var actor_key:=DirectionalLight3D.new()
	actor_key.name="CharacterKeyLight"
	actor_key.rotation_degrees=Vector3(-34,32,0)
	actor_key.light_color=Color("e0e7e9")
	actor_key.light_energy=.62
	actor_key.light_cull_mask=2
	add_child(actor_key)

func _build_court_ground() -> void:
	court_material=ShaderMaterial.new()
	court_material.shader=preload("res://assets/shaders/ruin_floor.gdshader")
	court_material.set_shader_parameter("flagstones",preload("res://assets/materials/ruin-floor/ruin-floor-albedo.png"))
	court_material.set_shader_parameter("mineral",preload("res://assets/materials/stone/Rock030_1K-JPG_Color.jpg"))
	court_material.set_shader_parameter("micro_normal",preload("res://assets/materials/stone/Rock030_1K-JPG_NormalGL.jpg"))
	court_material.set_shader_parameter("floor_tint",Color(["929b9e","84998d","b0aaa0","91867c"][region_index]))
	court_material.set_shader_parameter("dampness",0.72 if region_index==1 else 0.10)
	court_material.set_shader_parameter("ash",0.82 if region_index==3 else 0.08)
	var centers:=PackedVector2Array()
	for room in range(6): centers.append(Layout.center(region_index,room,simulation.layout_seed()) if simulation.uses_journey() else Vector2(0,4-room*11.2))
	court_material.set_shader_parameter("room_centers",centers)
	var room_positions:Array=[]
	for center in centers: room_positions.append(_point(center))
	var holes:Array=Ruins.ground_holes(region_index,room_positions,dressing_clearance)
	var floor_rectangles:Array[Rect2]=[]
	for passage in dressing_clearance: floor_rectangles.append(passage.grow(.72))
	# Regional bays bring their own structural floors; this mesh joins the
	# authoritative room and corridor surfaces without an artificial horizon.
	var ground=preload("res://scripts/room_ground.gd")
	var pieces:Array[Rect2]=ground.cover(floor_rectangles,holes)
	var mesh:=ground.surface(pieces,-.019)
	var foundation:=MeshInstance3D.new()
	foundation.name="CourtFoundation"
	foundation.mesh=ground.foundation(pieces,-.02,.86)
	foundation.material_override=materials.stone
	add_child(foundation)
	var court:=MeshInstance3D.new(); court.name="ContinuousStoneCourt"
	court.mesh=mesh; court.material_override=court_material
	court.set_meta("channel_holes",holes)
	court.set_meta("ground_rectangles",pieces)
	court.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(court)

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
				var height := 1.4 if side < 0.0 else 0.40
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
	_authored_prop("pillar" if tall else "broken_pillar",pos)

func _arch(pos: Vector3, angle: float) -> void:
	_authored_prop("arch",pos,angle)

func _sarcophagus(pos: Vector3) -> void:
	_authored_prop("tomb",pos)

func _authored_prop(kind: String, pos: Vector3, angle: float=0.0, parent: Node3D=null) -> Node3D:
	var prop: Node3D = preload("res://scripts/authored_architecture.gd").MODELS[kind].instantiate()
	prop.position=pos
	prop.rotation.y=angle
	if parent==null: add_child(prop)
	else: parent.add_child(prop)
	for piece in prop.find_children("*","MeshInstance3D",true,false):
		var original: StandardMaterial3D=piece.mesh.surface_get_material(0)
		match original.resource_name.get_slice(".",0):
			"stone": piece.material_override=materials.stone
			"edge": piece.material_override=materials.edge
			"recess": piece.material_override=materials.intarsia if kind=="intarsia" else materials.dark
			"bone": piece.material_override=materials.bone
			"glass": piece.material_override=sanctuary_glass
			"glass_gold": piece.material_override=sanctuary_gold
			"bronze":
				piece.material_override=materials.metal if kind=="intarsia" else preload("res://scripts/authored_architecture.gd").crafted(original)
			_: piece.material_override=preload("res://scripts/authored_architecture.gd").crafted(original)
	if kind not in ["intarsia","brazier","well","tomb"]:
		var chamber:=dressing_room if dressing_room>=0 else _nearest_chamber(pos)
		for part in prop.find_children("*","MeshInstance3D",true,false): part.set_meta("decoration_chamber",chamber)
	return prop

func _banner(pos: Vector3) -> Node3D:
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
	return root

func _torch(pos: Vector3) -> void:
	_authored_prop("brazier",pos)
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
	light.light_energy = 2.2
	light.omni_range = 7.0
	add_child(light)
	torches.append(light)

func _batch_static_geometry() -> void:
	# All repeated static primitives share draw calls per material and chamber.
	# Animated liquid surfaces, actors and combat effects remain separate.
	var groups: Dictionary = {}
	for node in find_children("*","MeshInstance3D",true,false):
		var mesh_node: MeshInstance3D = node
		var dynamic_prop:=false
		for prop in journey_props.values():
			if prop.is_ancestor_of(mesh_node): dynamic_prop=true; break
		if dynamic_prop: continue
		var source: Mesh = mesh_node.mesh
		# Godot renames duplicate sibling names. Keep dynamic planes by identity,
		# otherwise later room beams are batched, freed and lose quality control.
		if sanctuary_beams.has(mesh_node): continue
		if mesh_node.get_meta("regional_liquid",false):
			# Water and embers keep their animated material, but share the same
			# room visibility as the containing architectural bay.
			var liquid_chamber:=int(mesh_node.get_meta("decoration_chamber",-1))
			if liquid_chamber>=0: occluder_batches.append({"node":mesh_node,"chamber":liquid_chamber})
			continue
		if mesh_node.name in ["FloodedArchive","LavaBasin","LowCryptMist","SanctuaryBeam"]: continue
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
		elif source is ArrayMesh:
			signature="authored:"+str(source.get_instance_id())
		else: continue
		var mat: Material = mesh_node.material_override
		var room := floori(mesh_node.global_position.z/11.0)
		var casts_shadow: bool=mesh_node.cast_shadow!=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var chamber:=int(mesh_node.get_meta("decoration_chamber",-1))
		var key := str(mat.get_instance_id())+":"+str(room)+":"+signature+":"+str(casts_shadow)+":"+str(chamber)
		if not groups.has(key):
			var mesh: Mesh = BoxMesh.new() if source is BoxMesh else source
			if mesh is BoxMesh: mesh.size = Vector3.ONE
			groups[key] = {"material":mat,"transforms":[],"mesh":mesh,"casts_shadow":casts_shadow,"chamber":chamber}
		groups[key].transforms.append(transform)
		mesh_node.get_parent().remove_child(mesh_node)
		mesh_node.queue_free()
	for group in groups.values():
		var batch:=_batch_mesh(group.transforms,group.material,group.mesh,group.casts_shadow)
		if group.chamber>=0: occluder_batches.append({"node":batch,"chamber":group.chamber})
	_update_occluder_visibility()

func _batch_boxes(transforms: Array, mat: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	_batch_mesh(transforms,mat,mesh)

func _batch_mesh(transforms: Array,mat: Material,mesh: Mesh,casts_shadow: bool=true) -> MultiMeshInstance3D:
	if transforms.is_empty(): return null
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
	return node

func _box(pos: Vector3,dimensions: Vector3,mat: Material,parent: Node3D = null) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	instance.material_override = mat
	instance.position = pos
	if dressing_room>=0: instance.set_meta("decoration_chamber",dressing_room)
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
		actor.death_lean = [-1.0,0.0,1.0][posmod(int(enemy.id)+region_index,3)]
		actor.visible = enemy.get("spawned",true)
		add_child(actor)
		if actor.boss and actor.has_method("set_boss_phase"): actor.set_boss_phase(int(enemy.get("boss_phase",0)))
		actor_by_id[enemy.id] = actor
		enemies.append(actor)
		bars[enemy.id] = _box(actor.position+Vector3(0,2.5,0),Vector3(0.9,0.045,0.075),materials.blood)
		bars[enemy.id].visible = not actor.boss and enemy.hp>0 and enemy.get("spawned",true) and wave_index==simulation.stage
		bars[enemy.id].position.y = 3.8 if enemy.role=="boss" else 2.5
		bars[enemy.id].scale.x = maxf(0.01,float(enemy.hp)/float(enemy.max_hp))
		if enemy.hp<=0:
			actor.die()
			actor.animate(0.8,false)
		if not enemy.warning.is_empty():
			actor.set_telegraph(float(enemy.warning.get("left",0.0)),float(enemy.warning.get("total",0.0)))
			actor.animate(0,false,0)
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
	# A combat shot never breathes with a swing, hit, target change or warning.
	# Reserve the room/action envelope once; hold it until the next chamber.
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
		last_stage = index
		_update_occluder_visibility()
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
	var hero_speed:=direction.length()/maxf(delta,0.0001)
	if simulation.phase!="travel":
		var target: Dictionary = simulation.enemy_by_id(simulation.target_id)
		if not target.is_empty(): direction = _point(target.pos)-hero.position
	hero.reduced_motion=reduced_motion
	hero.face_toward(direction,camera.position)
	var actor_speeds: Dictionary={}
	for id_value in actor_by_id:
		var enemy: Dictionary = simulation.enemy_by_id(id_value)
		var actor: Node3D = actor_by_id[id_value]
		var old_position: Vector3 = actor.position
		actor.position = actor.position.lerp(_point(enemy.pos),minf(1.0,delta*15.0))
		if enemy.hp>0:
			var facing: Vector3 = hero.position-actor.position
			actor.face_toward(facing,camera.position)
		var actor_displacement:=actor.position.distance_to(old_position)
		actor.follow_travel(actor.position-old_position,camera.position)
		actor_speeds[id_value]=actor_displacement/maxf(delta,0.0001)
		actor.reduced_motion=reduced_motion
		actor.set_telegraph(maxf(0.0,float(enemy.warning.get("left",0.0))-simulation.accumulator),float(enemy.warning.get("total",0.0)))
		actor.anticipation=clampf(1.0-float(enemy.cooldown)/.24,0.0,1.0) if actor.position.distance_to(hero.position)<1.8 and enemy.hp>0 else 0.0
		if not enemy.warning.is_empty() and not warnings.has(id_value):
			_show_event(_warning_event(enemy))
		var bar: MeshInstance3D = bars[id_value]
		bar.visible = not actor.boss and enemy.hp>0 and enemy.get("spawned",true) and int(id_value)/10==index
		bar.position = actor.position+Vector3(0,3.8 if enemy.role=="boss" else 2.5,0)
		bar.scale.x = maxf(0.01,float(enemy.hp)/float(enemy.max_hp))
	for event in updates: _show_event(event)
	if not simulation.pending_attack.is_empty(): hero.sync_attack(maxf(0.0,float(simulation.pending_attack.left)-simulation.accumulator))
	elif hero.external_release and hero.release_time<0.0: hero.cancel_attack()
	hero.follow_travel(hero.position-previous,camera.position)
	hero.animate(delta,walking,hero_speed)
	if not simulation.pending_attack.is_empty() and not projectile_emitted and character_class!="Vowkeeper":
		var pending: Dictionary=simulation.pending_attack
		var remaining:=maxf(0.0,float(pending.left)-simulation.accumulator)
		if not pending.has("ability_id") and remaining<=Actor.PROJECTILE_RELEASE_LEAD and actor_by_id.has(pending.target):
			var color: Color=Color("79dbdc") if character_class=="Arcanist" else Color("84e3b4")
			# The weapon/string releases with the visible flight; impact follows
			# on the unchanged simulation damage frame a few milliseconds later.
			hero.release_attack()
			_launch_projectile(int(pending.target),color,maxf(0.016,remaining))
			projectile_emitted=true
	for id_value in actor_by_id:
		var actor: Node3D=actor_by_id[id_value]
		if simulation.enemy_by_id(id_value).hp<=0: actor.die()
		var speed: float=actor_speeds[id_value]
		actor.animate(delta,speed>.12,speed)
		# Let the actual collapse read, then clear defeated scenery from the
		# active fighters. The enemy dictionary, drops and rewards are untouched.
		if actor.death_time>.70 and not actor.boss:
			actor.set_defeated_readability(lerpf(.72,.12,smoothstep(.70,1.10,actor.death_time)))
			actor.visible=actor.death_time<1.12
	if simulation.uses_journey(): _sync_journey_props(delta)
	for id_value in warnings.keys():
		var enemy: Dictionary = simulation.enemy_by_id(id_value)
		if enemy.warning.is_empty() or simulation.finished:
			warnings[id_value].queue_free()
			warnings.erase(id_value)
		else:
			_update_warning(warnings[id_value],enemy.warning)
	target_ring.visible = phase=="combat" and actor_by_id.has(simulation.target_id)
	if target_ring.visible: target_ring.position = actor_by_id[simulation.target_id].position+Vector3(0,0.07,0)
	_update_combat_readability(delta)
	for i in range(torches.size()): torches[i].light_energy = 2.1+sin(elapsed*4.0+i*2.1)*0.10
	var camera_anchor:=_camera_anchor()
	var zoom_target:=0.86 if simulation.stage==5 else 0.94
	camera_zoom=lerpf(camera_zoom,zoom_target,1.0-exp(-delta*2.0))
	if absf(camera_zoom-zoom_target)<.0001: camera_zoom=zoom_target
	camera_target = camera_target.lerp(camera_anchor,1.0-exp(-delta*4.0))
	if camera_target.distance_to(camera_anchor)<.001: camera_target=camera_anchor
	_position_camera(delta)
	_set_description("AUTO • " + String(simulation.action).to_upper())
	simulation_advanced.emit(updates)

func _update_combat_readability(delta: float) -> void:
	hero_marker.visible=phase=="combat" and hero.death_time<0.0
	hero_marker.position=hero.position+Vector3(0,.075,0)
	if hero.death_time<0.0: hero.set_readability(1.0,.62)
	var hero_screen:=camera.unproject_position(hero.position+Vector3.UP*hero.figure_height*.55)
	var viewport_width:=maxf(1.0,get_viewport().get_visible_rect().size.x)
	for id_value in actor_by_id:
		var actor: Node3D=actor_by_id[id_value]
		if actor.death_time>=0.0 or not actor.visible: continue
		var enemy: Dictionary=simulation.enemy_by_id(id_value)
		var important: bool=id_value==simulation.target_id or not enemy.warning.is_empty() or actor.boss
		var actor_screen:=camera.unproject_position(actor.position+Vector3.UP*actor.figure_height*.55)
		var crowded:=actor_screen.distance_to(hero_screen)/viewport_width<.095
		# Never move a figure away from its real collision/warning floor.
		# Only nearby background combatants recede; warnings remain prominent.
		var goal:=.62 if crowded and not important else 1.0
		var focus:=.44 if id_value==simulation.target_id else 0.0
		actor.set_readability(lerpf(actor.emphasis,goal,1.0-exp(-delta*9.0)),focus)

func _position_camera(delta: float=0.0) -> void:
	var viewport_size: Vector2=get_viewport().get_visible_rect().size
	var aspect: float=viewport_size.x/maxf(viewport_size.y,1.0)
	var traveling: bool=simulation.phase=="travel"
	var changed:bool=shot_stage!=simulation.stage or absf(shot_aspect-aspect)>.01 or shot_travel!=traveling or absf(shot_bottom-hud_bottom_ratio)>.003
	if changed:
		shot_stage=simulation.stage; shot_aspect=aspect
		shot_travel=traveling; shot_bottom=hud_bottom_ratio
		shot_scale=.60; shot_pan=Vector3.ZERO
		shot_points=_travel_shot_points() if traveling else _room_shot_points()
	# Compose the immutable room envelope once into the usable HUD rectangle.
	# Pan and distance are solved together; empty foreground no longer forces
	# an unnecessarily distant shot merely because its old aim was below ground.
	var anchor:=_camera_anchor()
	var aim_height:=1.35 if simulation.stage==5 else 1.05
	var top:=.245 if aspect>1.3 else .15
	var bottom:=hud_bottom_ratio-.008
	var points: Array[Vector3]=shot_points.duplicate()
	if traveling:
		for i in points.size(): points[i]+=anchor
	else: _append_warning_bounds(points)
	if changed:
		var lower:=.35; var upper:=4.0
		var best_pan:=Vector3.ZERO
		for search in range(12):
			var candidate:float=(lower+upper)*.5
			var pan:=Vector3.ZERO
			var offset:=CAMERA_BOOM*camera_zoom*candidate
			var safe:=true
			for center_pass in range(12):
				camera.position=anchor+pan+offset
				camera.look_at(anchor+pan+Vector3.UP*aim_height)
				var low:=Vector2(INF,INF); var high:=Vector2(-INF,-INF)
				var near_depth:=INF;var far_depth:=0.0
				for point in points:
					var depth:float=-camera.to_local(point).z
					if depth<=.25: safe=false;break
					near_depth=minf(near_depth,depth);far_depth=maxf(far_depth,depth)
					var screen:=camera.unproject_position(point)/viewport_size
					low=low.min(screen); high=high.max(screen)
				if not safe:break
				var center:=(low+high)*.5
				var span:float=(near_depth+far_depth)*tan(deg_to_rad(camera.fov)*.5)
				var correction:=camera.basis.x*(center.x-.5)*span*aspect+camera.basis.y*((top+bottom)*.5-center.y)*span
				pan+=correction*.62
			camera.position=anchor+pan+offset
			camera.look_at(anchor+pan+Vector3.UP*aim_height)
			for point in points:
				var screen:=camera.unproject_position(point)/viewport_size
				safe=safe and screen.x>=.074 and screen.x<=.926 and screen.y>=top+.006 and screen.y<=bottom-.006
			if safe: upper=candidate;best_pan=pan
			else: lower=candidate
		shot_scale=upper;shot_pan=best_pan
	else:
		# An unexpected real warning can only pull the settled shot back; the
		# stored pan cannot oscillate with attacks or changing targets.
		for pass_index in range(5):
			camera.position=anchor+shot_pan+CAMERA_BOOM*camera_zoom*shot_scale
			camera.look_at(anchor+shot_pan+Vector3.UP*aim_height)
			var factor:=1.0
			for point in points:
				var screen:=camera.unproject_position(point)/viewport_size
				factor=maxf(factor,absf(screen.x-.5)/.43)
				var middle:=(top+bottom)*.5
				factor=maxf(factor,absf(screen.y-middle)/maxf(.1,(bottom-top)*.5))
			if factor<=1.002:break
			shot_scale*=minf(factor*1.008,1.35)
	framing_scale=shot_scale if delta<=0.0 else move_toward(framing_scale,shot_scale,delta*1.5)
	framing_pan=shot_pan if delta<=0.0 else framing_pan.lerp(shot_pan,1.0-exp(-delta*5.0))
	if framing_pan.distance_to(shot_pan)<.001: framing_pan=shot_pan
	camera.position=camera_target+framing_pan+CAMERA_BOOM*camera_zoom*framing_scale
	camera.look_at(camera_target+framing_pan+Vector3.UP*aim_height)
	_update_region_matte()

func _room_shot_points() -> Array[Vector3]:
	var points: Array[Vector3]=[]
	var center:=_point(simulation.checkpoint(clampi(simulation.stage,0,5)))
	for x in [-4.0,4.0]:
		for z in [-3.5,3.5]: points.append(center+Vector3(x,0,z))
	for enemy in simulation.waves[clampi(simulation.stage,0,simulation.waves.size()-1)]:
		var foot:=_point(enemy.spawn)
		var h:=4.6 if enemy.role=="boss" else 2.15
		var reach:=h*(.52 if enemy.role=="boss" else .34)
		for x in [-reach,reach]:
			for z in [-reach,reach]:
				for y in [0.0,h*(1.20 if enemy.role=="boss" else 1.06)]: points.append(foot+Vector3(x,y,z))
	for x in [-1.3,1.3]:
		for z in [-1.3,1.3]:
			for y in [0.0,3.45]: points.append(hero.position+Vector3(x,y,z))
	if simulation.stage==5:
		var boss: Dictionary=simulation.enemy_by_id(50)
		if not boss.is_empty():
			for phase_index in range(3):
				for variant in range(2):
					var warning:=BossPatterns.create_phased(region_index,boss.pos,simulation.hero_pos,phase_index,variant)
					for zone in warning.zones:
						for outline in BossPatterns.outlines(zone):
							for point in outline: points.append(_point(point))
	return points

func _travel_shot_points() -> Array[Vector3]:
	var points: Array[Vector3]=[]
	for x in [-4.8,4.8]:
		for z in [-4.0,4.0]: points.append(Vector3(x,0,z))
	for x in [-1.8,1.8]:
		for z in [-.5,2.2]:
			for y in [0.0,3.45]: points.append(Vector3(x,y,z))
	return points

func _append_warning_bounds(points: Array[Vector3]) -> void:
	for wave in simulation.waves:
		for enemy in wave:
			if enemy.hp<=0 or not enemy.get("spawned",true) or enemy.warning.is_empty(): continue
			for zone in enemy.warning.get("zones",[]):
				for outline in BossPatterns.outlines(zone):
					for point in outline: points.append(_point(point))

func _framing_points() -> Array[Vector3]:
	var points: Array[Vector3]=[hero.position,hero.position+Vector3(0,2.25,0)]
	_append_actor_bounds(points,hero)
	var target: Dictionary=simulation.enemy_by_id(simulation.target_id)
	if not target.is_empty():
		var foot:=_point(target.pos)
		points.append(foot)
		var target_height:=4.65 if target.get("role","")=="boss" else 2.3
		var target_actor: Node3D=actor_by_id.get(int(target.id))
		if target_actor!=null:
			target_height=maxf(target_height,target_actor.visual_height())
			_append_actor_bounds(points,target_actor)
		points.append(foot+Vector3(0,target_height,0))
	for wave in simulation.waves:
		for enemy in wave:
			if enemy.hp<=0 or not enemy.get("spawned",true) or enemy.warning.is_empty(): continue
			for zone in enemy.warning.get("zones",[]):
				for outline in BossPatterns.outlines(zone):
					for point in outline: points.append(_point(point))
	return points

func _append_actor_bounds(points: Array[Vector3],actor: Node3D) -> void:
	var bounds: AABB=actor.pose_bounds()
	for x in [bounds.position.x,bounds.end.x]:
		for y in [bounds.position.y,bounds.end.y]:
			for z in [bounds.position.z,bounds.end.z]: points.append(actor.to_global(Vector3(x,y,z)))

func _boss_is_active() -> bool:
	if simulation==null or simulation.waves.is_empty(): return false
	var wave_index:=clampi(simulation.stage,0,simulation.waves.size()-1)
	for enemy in simulation.waves[wave_index]:
		if enemy.get("role","")=="boss" and int(enemy.get("hp",0))>0 and enemy.get("spawned",true): return true
	return false

func _kick_camera(_intensity: float) -> void:
	# Hits belong to the affected body and contact effect, not the whole world.
	camera_shake_strength=0.0; camera_shake_time=0.0

func _set_description(value: String) -> void:
	if value != last_description:
		last_description = value
		state_changed.emit(value)

func _show_event(event: Dictionary) -> void:
	var color := {"Vowkeeper":Color("f3cc86"),"Arcanist":Color("79dbdc"),"Ranger":Color("84e3b4")}[character_class] as Color
	match String(event.type):
		"technique_cast":
			var definition: Dictionary=Skills.DEFINITIONS[event.ability_id]
			if event.ability_id in ["starfall","rain"]:
				var marker := _ring(_point(event.position)+Vector3(0,0.07,0),float(event.radius),_material(Color(definition.color),0.0,true))
				effects.append({"node":marker,"age":0.0,"life":float(event.duration)+0.1,"kind":"cast_mark","ability_id":event.ability_id})
		"technique":
			hero.release_attack()
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
			if actor_by_id.has(event.target): hero.face_toward(actor_by_id[event.target].position-hero.position,camera.position,true)
			var style:=String(event.get("ability_id",""))
			if style.is_empty(): style="signature" if event.get("skill",false) else "basic"
			var duration: float=Skills.DEFINITIONS.get(style,{}).get("cast",0.3)
			hero.strike(style,duration,true)
			projectile_emitted=false
		"hit":
			hero.release_attack()
			if not actor_by_id.has(event.target): return
			var actor: Node3D = actor_by_id[event.target]
			actor.react_from(hero.position,camera.position,1.25 if event.critical else .80)
			var impact_color: Color = Color("ffe1a2") if event.critical else color
			_float_text(actor.position+Vector3(0,2.5,0),str(event.damage)+("!" if event.critical else ""),impact_color)
			if event.critical: _kick_camera(0.025)
			# Actual damage is communicated at the body contact. Repeated ground
			# rings looked like targets and obscured Nyra's support feet in crowds.
			_impact_sparks(actor.position+Vector3(0,1.25,0),impact_color)
			if character_class=="Vowkeeper": _slash_arc(hero.position,color)
			if event.dead:
				actor.die()
				_contact_dust(actor.position)
				var loot := _magic_volume(actor.position+Vector3(0,0.5,0),Vector3(0.14,0.23,0.14),_magic_material(Color("6bc4cc"),0.82))
				effects.append({"node":loot,"age":0.0,"life":0.9,"kind":"loot"})
		"hero_hit":
			var heavy_hit:=false
			if actor_by_id.has(event.source):
				var attacker: Node3D=actor_by_id[event.source]
				var enemy_kind:=String(attacker.get("kind"))
				var heavy: bool=enemy_kind in ["bulwark","elite","boss"]
				heavy_hit=heavy
				hero.react_from(attacker.position,camera.position,1.15 if heavy else .65)
				attacker.strike("heavy")
			else: hero.react(0,.8)
			_kick_camera(0.070 if heavy_hit else 0.034)
			_float_text(hero.position+Vector3(0,2.3,0),"−"+str(event.damage),Color("f89583"))
		"ward":
			if ward_flash<=0.0:
				_float_text(hero.position+Vector3(0,2.85,0),"WARD "+str(event.absorbed),Color("a3ecea"))
			ward_flash=0.35
			if is_instance_valid(ward_shell): ward_shell.visible=true
		"nova":
			var wave:=_ring(_point(event.position)+Vector3(0,0.12,0),float(event.radius),_material(Color("8fe6e3"),0.0,true))
			wave.scale=Vector3.ONE*0.15
			wave.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			effects.append({"node":wave,"age":0.0,"life":0.45,"kind":"nova"})
		"warning":
			if warnings.has(event.source): warnings[event.source].queue_free()
			var zones: Array = event.get("zones",[{"shape":"circle","center":event.position,"radius":event.get("radius",1.0)}])
			var zone := _pattern_visual(zones,Color("ff6a2e"),0.32,true)
			var timer := Label3D.new()
			timer.name = "ImpactCountdown"
			timer.font_size = 36
			timer.pixel_size = 0.006
			timer.outline_size = 8
			timer.modulate = Color("ffe1b0")
			timer.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			timer.no_depth_test = true
			timer.position = _point(event.position)+Vector3(0,0.6,0)
			zone.add_child(timer)
			warnings[event.source] = zone
			var source: Dictionary = simulation.enemy_by_id(int(event.source))
			if not source.is_empty() and not source.warning.is_empty(): _update_warning(zone,source.warning)
			if actor_by_id.has(event.source): actor_by_id[event.source].set_telegraph(float(event.get("duration",1.3)),float(source.warning.get("total",event.get("duration",1.3))))
		"impact":
			if actor_by_id.has(event.get("source",-1)): actor_by_id[event.source].strike("heavy")
			_kick_camera(0.055)
			if event.has("zones"):
				var burst:=_pattern_visual(event.zones,Color(theme.fire),0.55)
				effects.append({"node":burst,"age":0.0,"life":0.45,"kind":"pattern"})
				return
			var ring := _ring(_point(event.position)+Vector3(0,0.12,0),event.radius,materials.fire)
			effects.append({"node":ring,"age":0.0,"life":0.35,"kind":"ring"})
		"boss_phase":
			_kick_camera(0.060)
			if actor_by_id.has(event.source):
				var guardian: Node3D=actor_by_id[event.source]
				if guardian.has_method("set_boss_phase"): guardian.set_boss_phase(int(event.get("phase",1)))
				var label_height: float=guardian.visual_height() if guardian.has_method("visual_height") else 4.3
				_float_text(guardian.position+Vector3(0,label_height+0.15,0),String(event.get("phase_name","AWAKENED")).to_upper(),Color("ffd89b"))
				_impact_sparks(guardian.position+Vector3(0,label_height*0.8,0),Color(theme.fire))
		"interrupt":
			if actor_by_id.has(event.target): _float_text(actor_by_id[event.target].position+Vector3(0,2.8,0),"INTERRUPTED",Color("b4a2e4"))
		"guard":
			_float_text(hero.position+Vector3(0,2.6,0),"GUARD +"+str(event.heal),Color("91d1ae"))
		"evade", "backstep":
			hero.retreat()
			for effect in effects:
				if effect.kind=="projectile": effect.age=effect.life
			_float_text(hero.position+Vector3(0,2.3,0),"EVADE",Color("adcbe0"))
		"finished":
			if not event.won: hero.die()

func _pattern_visual(zones: Array, tint: Color, alpha: float, timed: bool=false) -> Node3D:
	var node:=Node3D.new()
	node.name="BossTelegraph"
	add_child(node)
	for layer in range(3 if timed else 2):
		var border:=layer>0
		var ink_ground:=timed and layer==1
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
						var width:=Vector2(-direction.y,direction.x)*(0.10 if ink_ground else 0.043)
						for point in [a-width,b-width,a+width,b-width,b+width,a+width]: vertices.append(_point(point)+Vector3(0,0.103 if ink_ground else 0.11,0))
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
		if timed:
			var telegraph := ShaderMaterial.new()
			telegraph.shader = preload("res://assets/shaders/combat_telegraph.gdshader")
			telegraph.set_shader_parameter("danger_color",tint)
			telegraph.set_shader_parameter("border",border)
			telegraph.set_shader_parameter("ink_ground",ink_ground)
			visual.material_override=telegraph
		else:
			visual.material_override=material
		visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.add_child(visual)
	return node

func _float_text(pos: Vector3, value: String, color: Color) -> void:
	if not damage_numbers: return
	var label := Label3D.new()
	label.text = value
	label.font_size = 34 if value.length()>5 else (44 if value.ends_with("!") else 38)
	label.pixel_size = 0.0065
	label.modulate = color
	label.outline_size = 8
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = pos
	add_child(label)
	effects.append({"node":label,"age":0.0,"life":0.70,"kind":"number"})

func _update_effects(delta: float) -> void:
	for i in range(effects.size()-1,-1,-1):
		var effect: Dictionary = effects[i]
		effect.age += delta
		var node: Node3D = effect.node
		if effect.kind=="cast_mark" and simulation.pending_attack.get("ability_id","")!=effect.ability_id: effect.age=effect.life
		if effect.kind=="projectile":
			var destination: Vector3 = effect.destination
			if actor_by_id.has(effect.target): destination=actor_by_id[effect.target].position+Vector3(0,1.15,0)
			var progress := clampf(float(effect.age)/float(effect.life),0.0,1.0)
			node.position = Vector3(effect.origin).lerp(destination,progress)
			if character_class=="Arcanist": node.position.y+=sin(progress*PI)*0.35
			if node.position.distance_to(destination)>0.01: node.look_at(destination)
			for part in node.get_children():
				if part is MeshInstance3D and part.material_override is ShaderMaterial:
					part.material_override.set_shader_parameter("fade",1.0-smoothstep(.82,1.0,progress))
		if effect.kind=="fall": node.position+=Vector3(0,-10.0*delta,0)
		if effect.kind == "ring": node.scale = Vector3.ONE*(1.0+effect.age*3.0)
		elif effect.kind == "nova": node.scale=Vector3.ONE*lerpf(0.15,1.0,minf(1.0,effect.age/effect.life))
		elif effect.kind == "spark":
			node.position += Vector3(effect.velocity)*delta
			effect.velocity.y -= delta*8.0
			node.material_override.set_shader_parameter("fade",1.0-smoothstep(.10,1.0,clampf(effect.age/effect.life,0.0,1.0)))
		elif effect.kind == "contact_dust":
			var progress: float=clampf(effect.age/effect.life,0.0,1.0)
			node.scale=Vector3.ONE*lerpf(.34,1.0,progress)
			node.material_override.set_shader_parameter("deposit_color",Color(.36,.32,.27,(1.0-progress)*.34))
		elif effect.kind == "contact_light":
			node.light_energy=(1.0-clampf(effect.age/effect.life,0.0,1.0))*.65
		elif effect.kind == "slash":
			node.material_override.albedo_color.a=(1.0-clampf(effect.age/effect.life,0.0,1.0))*.32
		elif effect.kind == "number":
			node.position.y += delta*.65
			node.modulate.a=1.0-smoothstep(.38,.70,float(effect.age))
		elif effect.kind == "loot":
			node.position = node.position.lerp(hero.position+Vector3(0,0.8,0),delta*4.0)
			node.material_override.set_shader_parameter("fade",1.0-smoothstep(.55,1.0,clampf(effect.age/effect.life,0.0,1.0)))
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
			_authored_prop("bell",Vector3(0,2.78,-67.4))
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
	mat.set_shader_parameter("motion",0.0 if reduced_motion else 1.0)
	var mesh:=PlaneMesh.new()
	mesh.size=dimensions
	var surface:=MeshInstance3D.new()
	surface.name="LavaBasin" if lava else "FloodedArchive"
	surface.set_meta("regional_liquid",true)
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
	var rib:=_authored_prop("bone_arch",pos)
	rib.scale.x=-side

func _furnace(pos: Vector3,side: float) -> void:
	_authored_prop("furnace",pos,side*PI/2)

func set_shadows(enabled: bool) -> void:
	if is_instance_valid(sun): sun.shadow_enabled=enabled
	if court_material!=null: court_material.set_shader_parameter("relief",.18 if enabled else 0.0)
	for mat in floor_materials: mat.set_shader_parameter("relief",0.32 if enabled else 0.0)
	materials.edge.set_shader_parameter("relief",0.32 if enabled else 0.0)
	materials.intarsia.set_shader_parameter("relief",0.32 if enabled else 0.0)
	var ruin_materials: Dictionary=get_meta("ruin_material_cache",{})
	if ruin_materials.has("masonry"): ruin_materials.masonry.set_shader_parameter("relief",.80 if enabled else 0.0)
	if ruin_materials.has("dressed_stone"): ruin_materials.dressed_stone.set_shader_parameter("relief",.38 if enabled else 0.0)
	for beam in sanctuary_beams: beam.visible=enabled
	for light in sanctuary_lights: light.visible=enabled
	if sanctuary_beam_material!=null:
		sanctuary_beam_material.set_shader_parameter("motion",0.0 if reduced_motion else 1.0)
	for node in find_children("*","MeshInstance3D",true,false):
		if node.get_meta("regional_liquid",false): node.material_override.set_shader_parameter("motion",0.0 if reduced_motion else 1.0)

func _build_journey_floor() -> void:
	# The authored floor is continuous and flush. Architecture, not a regular
	# tray of enlarged tiles, describes the room around the true combat route.
	for room in range(6):
		var origin:=_point(Layout.center(region_index,room,simulation.layout_seed()))
		for side in [-1.0,1.0]:
			_torch(origin+Vector3(side*5.7,0.0,-1.6 if side<0.0 else 2.6))

func _build_journey_details() -> void:
	# The connected regional bay modules supply the structural props. The old
	# standalone moss boxes, bone cones and miniature furnaces were provisional.
	pass

func _build_journey_props() -> void:
	for room in [1,3,5]:
		var prop: Node3D=Ruins.create_reliquary(self) if room==5 else Node3D.new()
		prop.name="HealingWell" if room==1 else ("SanctumSeal" if room==3 else "GuardianReliquary")
		prop.position=_point(Layout.interact_point(region_index,room,simulation.layout_seed()))
		add_child(prop)
		journey_props[room]=prop
		if room!=5: _box(Vector3(0,-0.03,0),Vector3(1.5,0.15,1.5),materials.dark,prop)
		if room==1:
			_authored_prop("well",Vector3.ZERO,0.0,prop)
		elif room==3:
			_box(Vector3(0,0.55,0),Vector3(0.8,1.1,0.8),materials.stone,prop)
			var seal := _box(Vector3(0,1.4,0),Vector3(0.5,0.5,0.5),materials.soul,prop)
			seal.name="SealGem"
			seal.rotation=Vector3(0.5,0.6,0.5)
		else:
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
	var mist:=MeshInstance3D.new()
	mist.name="LowCryptMist"
	var veil:=PlaneMesh.new()
	veil.size=Vector2(36,96)
	mist.mesh=veil
	var fog_material:=ShaderMaterial.new()
	fog_material.shader=preload("res://assets/shaders/crypt_mist.gdshader")
	fog_material.set_shader_parameter("mist_color",Color(Color(theme.fog).lightened(0.18),0.17))
	mist.material_override=fog_material
	mist.position=Vector3(0,-0.7,-32)
	mist.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mist)
	# The distant painterly ruins remain visible around the walkable galleries;
	# exposed flat underworld boxes would sever floor from that atmosphere.
	# Floating motes remain decorative and never consume simulation randomness.
	var dust:=CPUParticles3D.new()
	dust.name="DungeonDust"
	dust.amount=40
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

func _build_sanctuary_details() -> void:
	# Original shared GLTF carvings, outside the combat/simulation layer.
	sanctuary_glass=ShaderMaterial.new()
	sanctuary_glass.shader=preload("res://assets/shaders/sanctuary_glass.gdshader")
	var window_color:=Color(["edc89a","67cdb5","b8a0d9","eaa16a"][region_index])
	sanctuary_glass.set_shader_parameter("glass_tint",window_color)
	sanctuary_gold=_material(Color("7f7056"),0.65,false)
	sanctuary_beam_material=ShaderMaterial.new()
	sanctuary_beam_material.shader=preload("res://assets/shaders/sanctuary_beam.gdshader")
	sanctuary_beam_material.set_shader_parameter("beam_tint",Color(window_color,0.035))
	for room in range(6):
		var origin:=_point(Layout.center(region_index,room,simulation.layout_seed())) if simulation.uses_journey() else Vector3(0,0,4-room*11.2)
		if room==5:
			var medallion:=_authored_prop("intarsia",origin+Vector3(0,0.010,0))
			medallion.name="SanctuaryIntarsia"
			medallion.scale=Vector3(.76,.24,.76)
			for part in medallion.find_children("*","MeshInstance3D",true,false):
				part.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Leaded windows are authored in the region paintings. Their live light
		# remains on the stones without a second slab hiding the painted figures.
		var beam:=MeshInstance3D.new()
		beam.name="SanctuaryBeam%d" % room
		var quad:=QuadMesh.new()
		quad.size=Vector2(2.0,7.2)
		beam.mesh=quad
		beam.material_override=sanctuary_beam_material
		beam.position=origin+Vector3(-3.3,2.1,0)
		beam.rotation=Vector3(0,0,0.92)
		beam.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(beam)
		sanctuary_beams.append(beam)
		var light:=SpotLight3D.new()
		light.name="WindowLight"
		light.light_color=window_color
		light.light_energy=1.05
		light.spot_range=10.0
		light.spot_angle=34.0
		light.spot_attenuation=1.4
		light.shadow_enabled=false
		add_child(light)
		light.position=origin+Vector3(-5.9,3.6,0)
		light.look_at(origin+Vector3(0,0,-0.8))
		sanctuary_lights.append(light)

func _impact_sparks(origin: Vector3,color: Color) -> void:
	if not reduced_motion and is_instance_valid(sun) and sun.shadow_enabled:
		var flash:=OmniLight3D.new()
		flash.position=origin; flash.light_color=color; flash.light_energy=.65; flash.omni_range=2.3
		add_child(flash)
		effects.append({"node":flash,"age":0.0,"life":.10,"kind":"contact_light"})
	for i in range(5):
		var spark:=_magic_volume(origin,Vector3(0.035,0.035,0.095),_magic_material(color,0.86))
		effects.append({"node":spark,"age":0.0,"life":0.22+rng.randf()*0.15,"kind":"spark","velocity":Vector3(rng.randf_range(-2.5,2.5),rng.randf_range(0.6,2.2),rng.randf_range(-2.5,2.5))})
		# Orient the fragment from the already-drawn velocity; never consume
		# extra randomness for decoration or alter the five-spark draw order.
		spark.look_at(origin+Vector3(effects.back().velocity))

func _magic_material(color: Color,opacity: float) -> ShaderMaterial:
	var material:=ShaderMaterial.new()
	material.shader=preload("res://assets/shaders/magic_volume.gdshader")
	material.set_shader_parameter("magic_color",color)
	material.set_shader_parameter("opacity",opacity)
	return material

func _magic_volume(position_value: Vector3,dimensions: Vector3,material: Material,parent: Node3D=null) -> MeshInstance3D:
	var volume:=MeshInstance3D.new()
	var mesh:=SphereMesh.new()
	mesh.radius=0.5
	mesh.height=1.0
	mesh.radial_segments=10
	mesh.rings=5
	volume.mesh=mesh
	volume.scale=dimensions
	volume.position=position_value
	volume.material_override=material
	volume.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if parent==null: add_child(volume)
	else: parent.add_child(volume)
	return volume

func _contact_dust(foot: Vector3) -> void:
	if reduced_motion or not is_instance_valid(sun) or not sun.shadow_enabled: return
	var dust:=MeshInstance3D.new(); var plane:=PlaneMesh.new(); plane.size=Vector2(1.5,1.3)
	dust.mesh=plane; dust.position=foot+Vector3(0,.025,0)
	var mat:=ShaderMaterial.new(); mat.shader=preload("res://assets/shaders/ruin_deposit.gdshader")
	mat.set_shader_parameter("mineral",preload("res://assets/materials/stone/Rock030_1K-JPG_Color.jpg"))
	mat.set_shader_parameter("deposit_color",Color(.36,.32,.27,.34))
	dust.material_override=mat; dust.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(dust)
	effects.append({"node":dust,"age":0.0,"life":.42,"kind":"contact_dust"})

func _slash_arc(_origin: Vector3,color: Color) -> void:
	# The ribbon follows the spatial blade in its actual sweep plane.
	var grip: Vector3=hero.weapon_grip_position()
	var blade: Vector3=hero.weapon_world_position(camera.position)-grip
	var normal: Vector3=hero.global_basis.x.normalized()
	var mesh:=SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(12):
		var a: float=-.55+float(i)*.55/12.0
		var b: float=a+.55/12.0
		for point in [Vector2(a,.84),Vector2(b,.84),Vector2(a,1.0),Vector2(b,.84),Vector2(b,1.0),Vector2(a,1.0)]:
			mesh.add_vertex(Basis(normal,point.x)*blade*point.y)
	mesh.generate_normals()
	var arc:=MeshInstance3D.new()
	arc.mesh=mesh.commit()
	var mat:=_material(Color(color,0.30),0,true)
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	arc.material_override=mat
	arc.position=grip
	arc.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(arc)
	effects.append({"node":arc,"age":0.0,"life":0.12,"kind":"slash"})

func _update_warning(node: Node3D, warning: Dictionary) -> void:
	# Temporal feedback never shrinks or moves the actual hazard footprint.
	var progress := clampf(1.0-float(warning.left)/maxf(0.001,float(warning.total)),0.0,1.0)
	for child in node.get_children():
		if child is MeshInstance3D and child.material_override is ShaderMaterial:
			child.material_override.set_shader_parameter("progress",progress)
	var timer := node.get_node_or_null("ImpactCountdown") as Label3D
	if timer!=null: timer.text="%.1fs" % maxf(0.0,float(warning.left))

func _launch_projectile(target: int, color: Color,flight_seconds: float=Actor.PROJECTILE_RELEASE_LEAD) -> void:
	var origin: Vector3=hero.projectile_origin()
	var destination: Vector3 = actor_by_id[target].position+Vector3(0,1.15,0)
	var projectile := Node3D.new()
	projectile.name = "SpellBolt" if character_class=="Arcanist" else "CinderArrow"
	projectile.position = origin
	add_child(projectile)
	var material := _magic_material(color,0.88)
	# Local -Z is the actual direction of flight. Rounded, tapered volumes
	# carry the class hue without the old lit/emissive rectangular bars.
	_magic_volume(Vector3(0,0,-0.17),Vector3(0.10,0.10,0.27),material,projectile)
	_magic_volume(Vector3(0,0,0.18),Vector3(0.045,0.045,0.46),_magic_material(color,0.48),projectile)
	if character_class=="Arcanist":
		_magic_volume(Vector3(0,0,-0.19),Vector3(0.17,0.17,0.22),_magic_material(color,0.46),projectile)
	if origin.distance_to(destination)>0.01: projectile.look_at(destination)
	effects.append({"node":projectile,"age":0.0,"life":flight_seconds,"kind":"projectile","origin":origin,"destination":destination,"target":target})

func _build_region_landmarks() -> void:
	# The guardian belongs to a region-specific sanctuary with physical depth.
	for room in [3,5]:
		dressing_room=room
		var center:=_point(Layout.center(region_index,room,simulation.layout_seed())) if simulation.uses_journey() else Vector3(0,0,4-room*11.2)
		var landmark:=_authored_prop(["vault","library","altar","throne"][region_index],center+Vector3(-1.0,0,-7.4),PI)
		landmark.scale=Vector3.ONE*0.90
		landmark.name="RegionalLandmark%d" % room
		_keep_clear_dressing(landmark)
	dressing_room=-1

func _prepare_dressing_clearance() -> void:
	if simulation.uses_journey():
		dressing_clearance=Layout.floor_rects(region_index,simulation.layout_seed(),simulation.movement_seed(),simulation.uses_wandering_routes(),simulation.uses_scouting_routes(),simulation.uses_expanded_scouting_routes())
	else:
		dressing_clearance=[Rect2(-5.8,-58,11.6,68)]

func _dressing_footprint_clear(position: Vector3, size: Vector3) -> bool:
	var footprint:=Rect2(Vector2(position.x-size.x*.5,position.z-size.z*.5),Vector2(size.x,size.z))
	for floor_rect in dressing_clearance:
		if floor_rect.grow(.20).intersects(footprint): return false
	return true

func _keep_clear_dressing(prop: Node3D) -> void:
	# Keep complete props, never sliced pillars or shelves. Check the actual
	# exported bounds after rotation/scale, before joining the static batches.
	for part in prop.find_children("*","MeshInstance3D",true,false):
		var local_bounds: AABB=AABB(-part.mesh.size*.5,part.mesh.size) if part.mesh is BoxMesh else part.mesh.get_aabb()
		var bounds: AABB=part.global_transform*local_bounds
		if bounds.end.y<=.5 or bounds.position.y>=2.8: continue
		if not _dressing_footprint_clear(bounds.get_center(),bounds.size):
			prop.get_parent().remove_child(prop)
			prop.queue_free()
			return

func _build_ruin_depth() -> void:
	preload("res://scripts/ruin_architecture.gd").build(self)

func _build_region_matte() -> void:
	region_matte=MeshInstance3D.new()
	region_matte.name="RegionalMattePainting"
	var plane:=QuadMesh.new()
	plane.size=Vector2(1,1)
	region_matte.mesh=plane
	var paint:=ShaderMaterial.new()
	paint.shader=preload("res://assets/shaders/region_matte.gdshader")
	paint.set_shader_parameter("painting",REGION_BACKDROPS[region_index])
	# This distant unlit plate needs the same atmospheric extinction as the
	# live region. Camp uses the shared shader's unchanged zero-haze default.
	paint.set_shader_parameter("haze_color",Color(theme.fog))
	paint.set_shader_parameter("haze_strength",1.0-exp(-float(theme.density)*75.0))
	paint.set_shader_parameter("distance_contrast",0.72)
	region_matte.material_override=paint
	region_matte.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	region_matte.extra_cull_margin=100.0
	add_child(region_matte)

func _update_region_matte() -> void:
	if not is_instance_valid(region_matte): return
	# A camera-facing distant plate fills only the horizon behind the live world.
	# Its lower edge lies below the foreground floor, preserving genuine movement.
	var distance: float=75.0
	var viewport_size: Vector2=get_viewport().get_visible_rect().size
	var aspect: float=viewport_size.x/maxf(viewport_size.y,1.0)
	var full_height: float=2.0*distance*tan(deg_to_rad(camera.fov)*0.5)
	var height: float=full_height*1.02
	var width: float=maxf(height*2.244,full_height*aspect*1.02)
	region_matte.transform=Transform3D(camera.basis.scaled_local(Vector3(width,height,1)),camera.position-camera.basis.z*distance)

func _nearest_chamber(pos: Vector3) -> int:
	var best:=0
	var closest:=INF
	for chamber in range(6):
		var center:=_point(Layout.center(region_index,chamber,simulation.layout_seed())) if simulation.uses_journey() else Vector3(0,0,4-chamber*11.2)
		var distance: float=absf(center.z-pos.z)
		if distance<closest: closest=distance; best=chamber
	return best

func _update_occluder_visibility() -> void:
	# Tall dressing in the chamber behind the camera must never obscure a fight.
	# Walking floor and real collision boundaries are unaffected by this culling.
	var chamber:=clampi(simulation.stage,0,5)
	for entry in occluder_batches:
		var ahead:int=int(entry.chamber)-chamber
		entry.node.visible=ahead in [0,1] or (simulation.phase=="travel" and ahead==-1)

func _camera_anchor() -> Vector3:
	if simulation.phase!="travel":
		return _point(simulation.checkpoint(clampi(simulation.stage,0,5)))+Vector3(0,0,1.35)
	var anchor: Vector3=hero.position+Vector3(0,0,-1.3)
	return anchor
