extends Control
## Painted stations occupy real camp anchors; equipment and seals come from the save.
const Actor = preload("res://scripts/dungeon_actor.gd")
const STATION_ATLAS = preload("res://assets/world/camp-stations.png")
const STATION_CELLS := 3
var character_class := "Vowkeeper"
var equipment: Dictionary = {}
var earned_seals: Array = []
var reduced_motion := false
var battery_mode := false
var render_container: SubViewportContainer
var render_viewport: SubViewport
var world: Node3D
var hero: Node3D
var camera: Camera3D
var station_art: Dictionary = {}
var station_anchors: Dictionary = {}
var fire_lights: Array[OmniLight3D] = []
var motes: Array[MeshInstance3D] = []
var materials: Dictionary = {}
var clock := 0.0

func configure(class_key: String, items: Dictionary, seals: Array) -> void:
	character_class = class_key
	equipment = items.duplicate(true)
	earned_seals = seals.duplicate()
	if is_instance_valid(hero): hero.configure_equipment(equipment, character_class)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	render_container = SubViewportContainer.new()
	render_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	render_container.stretch = true
	render_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(render_container)
	render_viewport = SubViewport.new()
	render_viewport.size = Vector2i(960, 540)
	render_viewport.own_world_3d = true
	render_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	render_container.add_child(render_viewport)
	world = Node3D.new()
	world.name = "AshenHaven"
	render_viewport.add_child(world)
	_build_materials()
	_build_environment()
	_build_haven()
	hero = Actor.new()
	hero.name = "CampHeroModel"
	hero.kind = character_class
	hero.position = Vector3(0.0, 0.13, 0.45)
	hero.rotation.y = PI - 0.23
	world.add_child(hero)
	hero.configure_equipment(equipment, character_class)
	camera = Camera3D.new()
	camera.name = "CampCamera"
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 52.0
	camera.position = Vector3(0.4, 4.6, 11.6)
	camera.near = 0.2
	camera.far = 65.0
	world.add_child(camera)
	camera.look_at(Vector3(0.0, 1.2, -0.5))
	camera.current = true
	_build_distant_painting()
	_build_stations()
	resized.connect(_update_composition)
	_update_composition()
	apply_quality(battery_mode, reduced_motion)

func _build_materials() -> void:
	var stone := ShaderMaterial.new()
	stone.shader = preload("res://assets/shaders/painted_stone.gdshader")
	stone.set_shader_parameter("stone_color", preload("res://assets/world/painted-stone.png"))
	stone.set_shader_parameter("stone_tint", Color("6d6860"))
	stone.set_shader_parameter("weathering", 0.55)
	materials.stone = stone
	materials.paving = ShaderMaterial.new()
	materials.paving.shader = preload("res://assets/shaders/camp_paving.gdshader")
	materials.paving.set_shader_parameter("stone_color", preload("res://assets/world/painted-stone.png"))
	materials.metal = _material(Color("8e7047"), 0.58)
	materials.rune = _material(Color("c2a071"), 0.35)
	materials.fire = _material(Color("dc9760"), 0.0, true)

func _build_environment() -> void:
	var environment := WorldEnvironment.new()
	var values := Environment.new()
	values.background_mode = Environment.BG_COLOR
	values.background_color = Color("29333e")
	values.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	values.ambient_light_color = Color("b7c4c9")
	values.ambient_light_energy = 0.38
	values.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	values.fog_enabled = true
	values.fog_light_color = Color("344047")
	values.fog_density = 0.008
	environment.environment = values
	world.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.name = "EveningSun"
	sun.light_color = Color("ffd7aa")
	sun.light_energy = 0.9
	sun.rotation_degrees = Vector3(-38, -48, 0)
	sun.shadow_enabled = not battery_mode
	world.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.light_color = Color("87a2c2")
	fill.light_energy = 0.35
	fill.rotation_degrees = Vector3(-28, 135, 0)
	world.add_child(fill)

func _build_haven() -> void:
	# A painted stone floor recedes into the courtyard painting without a raised edge.
	var floor := PlaneMesh.new()
	floor.size = Vector2(22.0, 18.0)
	_mesh(Vector3(0, 0.015, 1.0), floor, materials.paving).name = "CampStoneCourt"
	var platform := _cylinder(Vector3(0, 0.055, 0.45), 1.25, 0.08, materials.stone)
	platform.name = "CampStonePlatform"

func _build_stations() -> void:
	_painted_station("forge", "PaintedForge", 0, Vector3(-5.2, 0.08, -1.2), 3.45)
	_painted_station("table", "ExpeditionTable", 1, Vector3(-2.7, 0.08, 2.15), 2.75)
	_painted_station("portal", "VeilGate", 2, Vector3(3.7, 0.08, -3.0), 4.55)
	fire_lights.append(_light(world, Vector3(-4.8, 1.1, -0.8), Color("d9a374"), 0.7, 3.6))
	# The low stone shelf stays empty until the corresponding guardian is defeated.
	var altar := Node3D.new()
	altar.name = "GuardianSealAltar"
	altar.position = Vector3(3.25, 0.0, 2.15)
	world.add_child(altar)
	_box(Vector3(0, 0.22, 0), Vector3(2.18, 0.42, 0.66), materials.stone, altar)
	for region in range(4):
		var at := Vector3(-0.81 + region * 0.54, 0.465, 0.02)
		_cylinder(at, 0.18, 0.045, materials.stone, altar).name = "SealStand%d" % region
		if region not in earned_seals: continue
		var seal := Node3D.new()
		seal.name = "EarnedGuardianSeal%d" % region
		seal.position = at + Vector3(0, 0.2, 0)
		altar.add_child(seal)
		var coin := _cylinder(Vector3.ZERO, 0.2, 0.055, materials.metal, seal)
		coin.rotation.x = PI / 2.0
		var rune := _box(Vector3(0, 0, 0.034), Vector3(0.025, 0.24, 0.017), materials.rune, seal)
		rune.rotation.z = region * PI / 4.0
		_box(Vector3(0, 0, 0.035), Vector3(0.16, 0.025, 0.018), materials.rune, seal)
	station_anchors.seals = altar.position + Vector3(0, 0.45, 0.0)
	for i in range(6):
		var orb := SphereMesh.new()
		orb.radius = 0.008
		orb.height = 0.016
		orb.radial_segments = 6
		orb.rings = 3
		var mote := _mesh(Vector3(-4.9 + (i % 3) * 0.17, 0.9 + i * 0.21, -0.9), orb, materials.fire)
		mote.name = "ForgeEmber%d" % i
		motes.append(mote)

func _painted_station(key: String, node_name: String, cell: int, at: Vector3, height: float) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = STATION_ATLAS
	var edge := float(STATION_ATLAS.get_width()) / STATION_CELLS
	atlas.region = Rect2(float(cell) * edge, 0, edge, STATION_ATLAS.get_height())
	var art := Sprite3D.new()
	art.name = node_name
	art.texture = atlas
	art.pixel_size = height / STATION_ATLAS.get_height()
	art.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	art.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	art.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.shaded = false
	art.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	art.position = at + camera.basis.y * height * 0.5
	art.set_meta("station_height", height)
	art.set_meta("station_base", at)
	world.add_child(art)
	station_art[key] = art
	station_anchors[key] = at

func _update_composition() -> void:
	if not is_instance_valid(camera): return
	var aspect := size.x / maxf(size.y, 1.0)
	var spread := clampf(aspect / 1.65, 0.72, 1.2)
	for key in station_art:
		var art: Sprite3D = station_art[key]
		var at: Vector3 = art.get_meta("station_base")
		at.x *= spread
		art.position = at + camera.basis.y * float(art.get_meta("station_height")) * 0.5
		station_anchors[key] = at
	world.get_node("GuardianSealAltar").position.x = 3.25 * spread
	station_anchors.seals = world.get_node("GuardianSealAltar").position + Vector3(0, 0.45, 0)

func _material(color: Color, metallic: float = 0.0, luminous: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = 0.87
	if luminous:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.7
	return material

func _box(at: Vector3, dimensions: Vector3, material: Material, parent: Node3D = null) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = dimensions
	return _mesh(at, shape, material, parent)

func _cylinder(at: Vector3, radius: float, height: float, material: Material, parent: Node3D = null) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 20
	return _mesh(at, shape, material, parent)

func _mesh(at: Vector3, shape: Mesh, material: Material, parent: Node3D = null) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.mesh = shape
	mesh.material_override = material
	mesh.position = at
	(world if parent == null else parent).add_child(mesh)
	return mesh

func _build_distant_painting() -> void:
	var distance := 45.0
	var height := 2.0 * distance * tan(deg_to_rad(camera.fov) * 0.5)
	var matte := MeshInstance3D.new()
	matte.name = "PaintedCampHorizon"
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	matte.mesh = quad
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/camp_matte.gdshader")
	material.set_shader_parameter("painting", preload("res://assets/world/camp-matte.png"))
	matte.material_override = material
	matte.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	matte.extra_cull_margin = 80.0
	world.add_child(matte)
	matte.transform = Transform3D(camera.basis.scaled_local(Vector3(height * 2.4, height * 1.2, 1.0)), camera.position - camera.basis.z * distance)

func _light(parent: Node3D, at: Vector3, color: Color, energy: float, radius: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = color
	light.light_energy = energy
	light.omni_range = radius
	parent.add_child(light)
	return light

func apply_quality(battery: bool, motion_reduced: bool) -> void:
	battery_mode = battery
	reduced_motion = motion_reduced
	if not is_instance_valid(render_viewport): return
	render_container.stretch_shrink = 2 if battery else 1
	render_viewport.msaa_3d = Viewport.MSAA_DISABLED if battery else Viewport.MSAA_2X
	world.get_node("EveningSun").shadow_enabled = not battery
	set_process(not reduced_motion)

func station_position(key: String) -> Vector2:
	if not is_instance_valid(camera): return size * 0.5
	var at: Vector3 = hero.position if key == "hero" else station_anchors.get(key, Vector3.ZERO)
	return camera.unproject_position(at) * size / Vector2(render_viewport.size)

func _process(delta: float) -> void:
	clock += delta
	if is_instance_valid(hero): hero.animate(delta, false)
	for light in fire_lights:
		light.light_energy = 0.7 + sin(clock * 2.4) * 0.04
	for mote in motes:
		mote.position.y += delta * 0.075
		if mote.position.y > 2.5: mote.position.y = 0.8
