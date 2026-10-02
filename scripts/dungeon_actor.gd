extends Node3D
## Painterly six-pose cutouts driven by the live 3D simulation. No hidden GLB rig.
static var appearance_cache: Dictionary = {}
static var pose_mesh_cache: Dictionary = {}
static var metadata_cache: Dictionary = {}
var region_index := 0
var kind := "Vowkeeper"
var hostile := false
var boss := false
var reduced_motion := false
var body: Node3D
var painted_model: MeshInstance3D
var surface_material: ShaderMaterial
var atlas_texture: Texture2D
var atlas_path := ""
var atlas_grid := Vector2(3, 2)
var atlas_origin := Vector2.ZERO
var figure_height := 2.15
var pixels_per_world_unit := 1.0
var atlas_data: Dictionary = {}
var frame_data: Dictionary = {}
var source_region := Rect2()
var pose_frame := 0
var clock := 0.0
var gait_phase := 0.0
var gait_blend := 0.0
var moving := false
var attack_time := -1.0
var attack_queued := false
var attack_style := "basic"
var queued_attack_style := "basic"
var action_intensity := 1.0
var impact_time := -1.0
var hit_strength := 0.0
var death_time := -1.0
var death_lean := 1.0
var boss_phase := 0
var telegraph_left := 0.0
var equipped_items: Dictionary = {}
var equipment_grades: Dictionary = {}
var health_bar: MeshInstance3D
var materials: Dictionary = {}

const HEROES: Array[String] = ["Vowkeeper", "Arcanist", "Ranger"]
const ATLAS_TEXTURES = {
	"Vowkeeper":preload("res://assets/characters/vowkeeper.png"),
	"Arcanist":preload("res://assets/characters/arcanist.png"),
	"Ranger":preload("res://assets/characters/ranger.png"),
	"hostiles":preload("res://assets/characters/hostiles.png"),
	"guardian_0":preload("res://assets/characters/guardian_0.png"),
	"guardian_1":preload("res://assets/characters/guardian_1.png"),
	"guardian_2":preload("res://assets/characters/guardian_2.png"),
	"guardian_3":preload("res://assets/characters/guardian_3.png"),
}
const HOSTILE_BLOCKS := {"raider":Vector2(0,0),"bulwark":Vector2(3,0),"hexer":Vector2(0,2),"elite":Vector2(3,2)}
const GEAR_RANKS := {"COMMON":0,"UNCOMMON":1,"RARE":2,"EPIC":3,"LEGENDARY":4}
const GEAR_TINTS: Array[Color] = [Color("98794c"),Color("a5b393"),Color("93c4c6"),Color("b79ec6"),Color("e7bf79")]
const EQUIPMENT_REGIONS := {"Weapon":Rect2(0.70,0.12,0.26,0.59),"Helmet":Rect2(0.31,0.04,0.37,0.20),"Chest":Rect2(0.31,0.24,0.39,0.52),"Gloves":Rect2(0.12,0.40,0.78,0.28),"Boots":Rect2(0.12,0.76,0.78,0.20),"Amulet":Rect2(0.453,0.343,0.114,0.114)}

func _ready() -> void:
	body=Node3D.new()
	body.name="PaintedBody"
	add_child(body)
	death_lean=-1.0 if (kind.hash()+region_index)%2==0 else 1.0
	_load_appearance()
	_contact_shadow()
	if not hostile and not boss: configure_equipment(equipped_items,kind)
	set_boss_phase(boss_phase)
	_set_pose(0)

func _load_appearance() -> void:
	if boss:
		atlas_texture=ATLAS_TEXTURES["guardian_%d" % clampi(region_index,0,3)]
		atlas_path="res://assets/characters/guardian_%d.png" % clampi(region_index,0,3)
		atlas_grid=Vector2(3,2); atlas_origin=Vector2.ZERO; figure_height=4.6
	elif kind in HEROES:
		atlas_texture=ATLAS_TEXTURES[kind]
		atlas_path="res://assets/characters/"+kind.to_lower()+".png"
		atlas_grid=Vector2(3,2); atlas_origin=Vector2.ZERO; figure_height=2.15
	else:
		atlas_texture=ATLAS_TEXTURES.hostiles
		atlas_path="res://assets/characters/hostiles.png"
		atlas_grid=Vector2(6,4); atlas_origin=HOSTILE_BLOCKS.get(kind,Vector2.ZERO)
		figure_height=2.30 if kind in ["bulwark","elite"] else 2.15
	appearance_cache[atlas_path]=atlas_texture
	assert(atlas_texture!=null,"Missing authored pose atlas: "+atlas_path)
	var metadata_path:=atlas_path.trim_suffix(".png")+".atlas.json"
	if not metadata_cache.has(metadata_path):
		metadata_cache[metadata_path]=JSON.parse_string(FileAccess.get_file_as_string(metadata_path))
	atlas_data=metadata_cache[metadata_path]
	assert(atlas_data.get("packing","")=="calibrated_source_uv_polygons","Missing calibrated pose geometry: "+metadata_path)
	if painted_model==null:
		painted_model=MeshInstance3D.new()
		painted_model.name="PaintedCharacter"
		painted_model.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		body.add_child(painted_model)
		painted_model.extra_cull_margin=figure_height
		painted_model.ignore_occlusion_culling=true
		painted_model.transparency=0.0
		surface_material=ShaderMaterial.new()
		surface_material.shader=preload("res://assets/shaders/painted_actor.gdshader")
		painted_model.material_override=surface_material
	painted_model.position=Vector3.ZERO
	surface_material.set_shader_parameter("atlas_texture",atlas_texture)
	surface_material.set_shader_parameter("atlas_grid",atlas_grid)
	surface_material.set_shader_parameter("atlas_origin",atlas_origin)
	_set_pose(pose_frame)

func configure_equipment(equipment: Dictionary,class_key: String="") -> void:
	equipped_items=equipment.duplicate(true)
	if body==null:
		if class_key in HEROES: kind=class_key
		return
	if boss or hostile: return
	if class_key in HEROES and class_key!=kind:
		kind=class_key
		_load_appearance()
	surface_material.set_shader_parameter("equipment_enabled",true)
	equipment_grades.clear()
	var uniforms := {"Weapon":"weapon","Helmet":"helm","Chest":"chest","Amulet":"accent","Gloves":"gloves","Boots":"boots"}
	for slot in uniforms:
		var item: Dictionary=equipment.get(slot,equipment.get("Helm",{}) if slot=="Helmet" else {})
		var quality:=String(item.get("quality",item.get("rarity","COMMON"))).to_upper()
		var rank: int=GEAR_RANKS.get(quality,0)
		equipment_grades[slot]=rank
		surface_material.set_shader_parameter(uniforms[slot]+"_rank",float(rank))
		surface_material.set_shader_parameter(uniforms[slot]+"_tint",GEAR_TINTS[rank])

func set_boss_phase(phase: int) -> void:
	boss_phase=clampi(phase,0,2)
	if surface_material!=null:
		surface_material.set_shader_parameter("boss_surface",boss)
		surface_material.set_shader_parameter("boss_phase",float(boss_phase))

func visual_height() -> float:
	return maxf(0.0,pose_bounds().end.y+body.position.y)*scale.y if painted_model!=null else figure_height*scale.y

func pose_bounds() -> AABB:
	return painted_model.mesh.get_aabb() if painted_model!=null else AABB()

func portrait_anchor() -> Vector3:
	if atlas_data.is_empty(): return Vector3(0,figure_height*.87,0)
	var idle_index:=int(atlas_origin.y)*int(atlas_grid.x)+int(atlas_origin.x)
	var idle: Dictionary=atlas_data.frames[idle_index]
	var point: Array=idle.get("portrait_anchor",idle.foot_anchor)
	var foot: Array=idle.foot_anchor
	return Vector3((float(point[0])-float(foot[0]))/pixels_per_world_unit,(float(foot[1])-float(point[1]))/pixels_per_world_unit,0)

func _contact_shadow() -> void:
	var mat:=ShaderMaterial.new()
	mat.shader=preload("res://assets/shaders/ground_grime.gdshader")
	mat.set_shader_parameter("tint",Color(0.01,0.009,0.013,0.53))
	var mesh:=PlaneMesh.new()
	mesh.size=Vector2(2.2,1.2) if boss else Vector2(1.10,0.66)
	var shadow:=MeshInstance3D.new()
	shadow.mesh=mesh; shadow.material_override=mat
	shadow.name="ContactShadow"; shadow.position.y=0.028
	shadow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)

func strike(style: String="basic") -> void:
	if death_time>=0.0: return
	var requested_style:=style if not style.is_empty() else "basic"
	if requested_style=="heavy":
		telegraph_left=0.0
		attack_queued=false
		attack_time=0.23; attack_style=requested_style
		_set_pose(4)
		return
	if attack_time>=0.0:
		attack_queued=true; queued_attack_style=requested_style
	else:
		attack_time=0.0; attack_style=requested_style
		_set_pose(3)

func react() -> void:
	if death_time<0.0 and impact_time<0.0: impact_time=0.0

func set_telegraph(remaining_seconds: float) -> void:
	telegraph_left=maxf(remaining_seconds,0.0)
	if telegraph_left>0.0 and death_time<0.0: _set_pose(3)

func die() -> void:
	death_time=0.0
	attack_queued=false; attack_time=-1.0
	_set_pose(5)

func _set_pose(frame: int) -> void:
	pose_frame=clampi(frame,0,5)
	if surface_material==null or atlas_data.is_empty(): return
	var index: int=(int(atlas_origin.y)+pose_frame/3)*int(atlas_grid.x)+int(atlas_origin.x)+pose_frame%3
	frame_data=atlas_data.frames[index]
	pixels_per_world_unit=float(frame_data.body_height)/figure_height
	var rect: Array=frame_data.region
	source_region=Rect2(float(rect[0]),float(rect[1]),float(rect[2]),float(rect[3]))
	var cache_key:=atlas_path+":"+str(index)+":"+str(figure_height)
	if not pose_mesh_cache.has(cache_key):
		pose_mesh_cache[cache_key]=_build_pose_mesh(frame_data)
	painted_model.mesh=pose_mesh_cache[cache_key]
	var texture_size:=Vector2(float(atlas_texture.get_width()),float(atlas_texture.get_height()))
	surface_material.set_shader_parameter("frame_region",Vector4(source_region.position.x/texture_size.x,source_region.position.y/texture_size.y,source_region.size.x/texture_size.x,source_region.size.y/texture_size.y))
	surface_material.set_shader_parameter("pose_frame",float(pose_frame))

func _build_pose_mesh(data: Dictionary) -> ArrayMesh:
	var vertices:=PackedVector3Array()
	var uvs:=PackedVector2Array()
	var indices:=PackedInt32Array()
	var foot: Array=data.foot_anchor
	for polygon: Array in data.polygons:
		var source_points:=PackedVector2Array()
		for point: Array in polygon: source_points.append(Vector2(float(point[0]),float(point[1])))
		var triangles:=Geometry2D.triangulate_polygon(source_points)
		assert(not triangles.is_empty(),"Authored alpha contour failed triangulation: "+atlas_path)
		var first:=vertices.size()
		for point in source_points:
			vertices.append(Vector3((point.x-float(foot[0]))/pixels_per_world_unit,(float(foot[1])-point.y)/pixels_per_world_unit,0))
			uvs.append((point-source_region.position)/source_region.size)
		for triangle in triangles: indices.append(first+triangle)
	var arrays:=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_TEX_UV]=uvs
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

func animate(delta: float,walking: bool,horizontal_speed: float=-1.0) -> void:
	if body==null: return
	moving=walking
	if not reduced_motion: clock+=delta
	if death_time>=0.0:
		death_time+=delta
		body.position=Vector3.ZERO
		surface_material.set_shader_parameter("lean",0.0)
		_set_pose(5)
		return
	var speed:=clampf(horizontal_speed,0.0,6.0) if horizontal_speed>=0.0 else 3.2
	gait_blend=lerpf(gait_blend,1.0 if walking else 0.0,1.0-exp(-delta*12.0))
	if walking: gait_phase+=delta*speed*3.25
	var frame:=1+int(floor(gait_phase/PI))%2 if gait_blend>0.22 else 0
	body.position=Vector3.ZERO
	action_intensity=1.0
	if telegraph_left>0.0:
		frame=3
	elif attack_time>=0.0:
		attack_time+=delta
		var empowered:=attack_style in ["signature","sunder","judgment","chain","starfall","rain","marked"]
		action_intensity=1.2 if empowered else 1.0
		if attack_style=="telegraph":
			frame=3
		elif attack_time<0.23: frame=3
		elif attack_time<0.47: frame=4
		else: frame=0
		if attack_time>=0.62:
			if attack_queued:
				attack_time=0.0; attack_queued=false; attack_style=queued_attack_style; frame=3
			else: attack_time=-1.0
	hit_strength=0.0
	if impact_time>=0.0:
		impact_time+=delta
		hit_strength=sin(clampf(impact_time/0.24,0.0,1.0)*PI)*exp(-impact_time*2.6)
		if impact_time>=0.24: impact_time=-1.0; hit_strength=0.0
		if not reduced_motion: body.position.x=death_lean*0.045*hit_strength
	surface_material.set_shader_parameter("hit_flash",hit_strength)
	surface_material.set_shader_parameter("lean",death_lean*0.025*hit_strength if not reduced_motion else 0.0)
	surface_material.set_shader_parameter("action_intensity",action_intensity)
	_set_pose(frame)
