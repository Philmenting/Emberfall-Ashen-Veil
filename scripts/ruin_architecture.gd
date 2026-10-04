extends RefCounted
## Connected original 0.47 regional architecture, with explicit passage clearance.
const Layout=preload("res://scripts/dungeon_layout.gd")
const Authored=preload("res://scripts/authored_architecture.gd")
const MODEL_ROOT="res://assets/models/environment/"
const REGIONS=["spire","archive","ossuary","citadel"]
const MODELS={
	"spire_bay":preload("res://assets/models/environment/spire_bay.glb"),
	"spire_crown":preload("res://assets/models/environment/spire_crown.glb"),
	"spire_solid":preload("res://assets/models/environment/spire_solid.glb"),
	"spire_return":preload("res://assets/models/environment/spire_return.glb"),
	"archive_bay":preload("res://assets/models/environment/archive_bay.glb"),
	"archive_crown":preload("res://assets/models/environment/archive_crown.glb"),
	"archive_solid":preload("res://assets/models/environment/archive_solid.glb"),
	"archive_return":preload("res://assets/models/environment/archive_return.glb"),
	"ossuary_bay":preload("res://assets/models/environment/ossuary_bay.glb"),
	"ossuary_crown":preload("res://assets/models/environment/ossuary_crown.glb"),
	"ossuary_solid":preload("res://assets/models/environment/ossuary_solid.glb"),
	"ossuary_return":preload("res://assets/models/environment/ossuary_return.glb"),
	"citadel_bay":preload("res://assets/models/environment/citadel_bay.glb"),
	"citadel_crown":preload("res://assets/models/environment/citadel_crown.glb"),
	"citadel_solid":preload("res://assets/models/environment/citadel_solid.glb"),
	"citadel_return":preload("res://assets/models/environment/citadel_return.glb"),
}
static var masonry_cache: Dictionary={}
static var template_cache: Dictionary={}

# Every bay/return brings its own paved foundation and court-overlapping lip.
# The court only needs its normal room/corridor margin; no remote plane is needed.
static func ground_footprints(_region: int,_centers: Array,_clearance: Array) -> Array[Rect2]:
	return []

# Exact openings in the *built* Archive basin, not a generic liquid strip. The
# bridge/deck/retaining walls are meshes in the same placed architectural bay.
static func ground_holes(region: int,centers: Array,clearance: Array) -> Array[Rect2]:
	var result: Array[Rect2]=[]
	if region!=1: return result
	for entry in _plan(region,centers,clearance):
		if entry.kind!="bay": continue
		var transform: Transform3D=_entry_transform(entry)
		var bounds: AABB=transform*AABB(Vector3(-1.66,-.9,-4.28),Vector3(3.32,.6,4.40))
		result.append(Rect2(Vector2(bounds.position.x,bounds.position.z),Vector2(bounds.size.x,bounds.size.z)))
	return result

static func build(w) -> void:
	var centers: Array=[]
	for room in range(6):
		centers.append(w._point(Layout.center(w.region_index,room,w.simulation.layout_seed())) if w.simulation.uses_journey() else Vector3(0,0,4-room*11.2))
	for entry in _plan(w.region_index,centers,w.dressing_clearance):
		w.dressing_room=entry.room
		_place(w,entry)
	w.dressing_room=-1

static func _plan(region: int,centers: Array,clearance: Array) -> Array:
	var result: Array=[]
	for room in range(centers.size()):
		var c: Vector3=centers[room]
		# A 34m rear elevation occupies the whole useful far field. All ground
		# bays stop at the actual protected route, while the high gallery links
		# their shoulders across those passages and continues into native depth.
		_fill_run(result,region,room,c+Vector3(0,0,-6.45),0.0,-17.0,17.0,"bay",clearance)
		_fill_crown(result,region,room,c+Vector3(0,0,-6.45),0.0,-17.0,17.0,clearance)
		# Deep left aisle and its connected vault return form an inhabited edge.
		_fill_run(result,region,room,c+Vector3(-6.85,0,0),PI*.5,-6.85,6.85,"bay",clearance)
		_fill_crown(result,region,room,c+Vector3(-6.85,0,0),PI*.5,-6.85,6.85,clearance)
		# Tall mass turns the rear corner; the camera-near right side stays open.
		_fill_run(result,region,room,c+Vector3(6.85,0,-4.30),-PI*.5,-2.40,2.40,"bay",clearance)
		_fill_run(result,region,room,c+Vector3(6.85,0,3.20),-PI*.5,-4.45,4.45,"return",clearance)
	return result

static func _entry_transform(entry: Dictionary) -> Transform3D:
	return Transform3D(Basis(Vector3.UP,float(entry.angle)).scaled_local(Vector3(float(entry.width)/4.90,1.0,1.0)),entry.at)

static func _fill_run(output: Array,region: int,room: int,origin: Vector3,angle: float,minimum: float,maximum: float,kind: String,clearance: Array) -> void:
	# Split the placement band before instantiation. This adapts to every real
	# seed and turn; it does not add a collider and try to repair the route later.
	var intervals: Array[Vector2]=[Vector2(minimum,maximum)]
	var depth: float=6.25 if kind!="return" else 2.70
	var basis:=Basis(Vector3.UP,angle)
	var inverse:=Transform3D(basis,origin).affine_inverse()
	for walking: Rect2 in clearance:
		var protected: Rect2=walking.grow(.27)
		var box: AABB=inverse*AABB(Vector3(protected.position.x,-1,protected.position.y),Vector3(protected.size.x,10,protected.size.y))
		if box.end.z< -depth or box.position.z>.63: continue
		var next: Array[Vector2]=[]
		for interval in intervals:
			if box.end.x<=interval.x or box.position.x>=interval.y: next.append(interval); continue
			if box.position.x>interval.x: next.append(Vector2(interval.x,minf(interval.y,box.position.x)))
			if box.end.x<interval.y: next.append(Vector2(maxf(interval.x,box.end.x),interval.y))
		intervals=next
	for interval in intervals:
		var length: float=interval.y-interval.x
		if length<.72: continue
		var count: int=maxi(1,ceili(length/4.8))
		var width: float=length/float(count)
		for index_value in range(count):
			var middle: float=interval.x+(float(index_value)+.5)*width
			var chosen: String=kind if width>=2.8 or kind=="return" else "solid"
			var entry: Dictionary={"region":region,"room":room,"kind":chosen,"at":origin+basis*Vector3(middle,0,0),"angle":angle,"width":width+.035}
			if _entry_clear(entry,clearance): output.append(entry)

static func _fill_crown(output: Array,region: int,room: int,origin: Vector3,angle: float,minimum: float,maximum: float,clearance: Array) -> void:
	var count: int=maxi(1,ceili((maximum-minimum)/4.8))
	var width: float=(maximum-minimum)/float(count)
	var basis:=Basis(Vector3.UP,angle)
	for index_value in range(count):
		var at: Vector3=origin+basis*Vector3(minimum+(float(index_value)+.5)*width,0,0)
		var entry: Dictionary={"region":region,"room":room,"kind":"crown","at":at,"angle":angle,"width":width+.05}
		if _entry_clear(entry,clearance): output.append(entry)

static func _entry_clear(entry: Dictionary,clearance: Array) -> bool:
	var placement: Transform3D=_entry_transform(entry)
	for part in _template(REGIONS[entry.region]+"_"+entry.kind):
		var bounds: AABB=(placement*part.transform)*part.mesh.get_aabb()
		if bounds.end.y<=.5 or bounds.position.y>=2.8: continue
		var footprint:=Rect2(Vector2(bounds.position.x,bounds.position.z),Vector2(bounds.size.x,bounds.size.z))
		for walking: Rect2 in clearance:
			if walking.grow(.205).intersects(footprint): return false
	return true

static func _template(key: String) -> Array:
	if template_cache.has(key): return template_cache[key]
	var source: Node3D=MODELS[key].instantiate()
	var parts: Array=[]
	for piece: MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
		var local: Transform3D=piece.transform
		var parent: Node=piece.get_parent()
		while parent!=source and parent is Node3D:
			local=parent.transform*local; parent=parent.get_parent()
		local=source.transform*local
		var original: Material=piece.mesh.surface_get_material(0)
		var channel: String=String(original.resource_name).get_slice(".",0).trim_prefix("environment_")
		parts.append({"mesh":piece.mesh,"transform":local,"channel":channel,"original":original})
	source.free()
	template_cache[key]=parts
	return parts

static func _world_materials(w) -> Dictionary:
	# Materials die with their owning expedition. Only immutable mesh templates
	# live in the static cache, so repeated descents do not retain per-world state.
	if not w.has_meta("ruin_material_cache"): w.set_meta("ruin_material_cache",{})
	return w.get_meta("ruin_material_cache")

static func _material(w,part: Dictionary) -> Material:
	var channel: String=part.channel
	var material_cache: Dictionary=_world_materials(w)
	match channel:
		"stone": return _masonry(w)
		"edge": return w.materials.edge
		"dark": return w.floor_materials[4]
		"floor": return w.floor_materials[1]
	var key: String=channel
	if material_cache.has(key): return material_cache[key]
	var original: StandardMaterial3D=part.original.duplicate()
	original.resource_name=channel
	if channel=="ember":
		original.emission_energy_multiplier=.55; original.roughness=.9
		material_cache[key]=original
	else: material_cache[key]=Authored.crafted(original)
	return material_cache[key]

static func _masonry(w) -> ShaderMaterial:
	var cache: Dictionary=_world_materials(w)
	if cache.has("masonry"): return cache.masonry
	var material:=ShaderMaterial.new()
	material.shader=preload("res://assets/shaders/masonry_surface.gdshader")
	material.set_shader_parameter("masonry_color",preload("res://assets/materials/masonry/Bricks096_1K-PNG_Color.png"))
	material.set_shader_parameter("masonry_normal",preload("res://assets/materials/masonry/Bricks096_1K-PNG_NormalGL.png"))
	material.set_shader_parameter("masonry_roughness",preload("res://assets/materials/masonry/Bricks096_1K-PNG_Roughness.png"))
	material.set_shader_parameter("cap_color",preload("res://assets/materials/stone/Rock030_1K-JPG_Color.jpg"))
	material.set_shader_parameter("cap_normal",preload("res://assets/materials/stone/Rock030_1K-JPG_NormalGL.jpg"))
	material.set_shader_parameter("cap_roughness",preload("res://assets/materials/stone/Rock030_1K-JPG_Roughness.jpg"))
	material.set_shader_parameter("stone_tint",Color(["dddcd7","d1ddd4","e2dbd0","d4c7b9"][w.region_index]))
	cache.masonry=material
	return material

static func _place(w,entry: Dictionary) -> void:
	var placement: Transform3D=_entry_transform(entry)
	var key: String=REGIONS[entry.region]+"_"+entry.kind
	for part in _template(key):
		var transform: Transform3D=placement*part.transform
		var bounds: AABB=transform*part.mesh.get_aabb()
		# Keep the existing World contract authoritative, even after template edits.
		if bounds.end.y>.5 and bounds.position.y<2.8 and not w._dressing_footprint_clear(bounds.get_center(),bounds.size): return
	for part in _template(key):
		var piece:=MeshInstance3D.new()
		piece.name=key+"_"+String(part.channel)
		piece.mesh=part.mesh; piece.transform=placement*part.transform
		piece.material_override=_material(w,part)
		piece.set_meta("decoration_chamber",entry.room)
		piece.set_meta("regional_module",key)
		if part.channel=="floor": piece.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		w.add_child(piece)
	if entry.kind=="bay":
		if entry.region==1: _basin(w,placement,false)
		if entry.region==3: _basin(w,placement,true)

static func _basin(w,placement: Transform3D,lava: bool) -> void:
	var material_cache: Dictionary=_world_materials(w)
	var key: String="hearth" if lava else "basin"
	var material: ShaderMaterial
	if material_cache.has(key): material=material_cache[key]
	else:
		material=ShaderMaterial.new()
		if lava:
			material.shader=preload("res://assets/shaders/dungeon_water.gdshader")
			material.set_shader_parameter("water_color",Color("341708"))
			material.set_shader_parameter("crest_color",Color("bc4b18"))
			material.set_shader_parameter("lava",1.0)
		else:
			material.shader=preload("res://assets/shaders/environment_basin.gdshader")
			material.set_shader_parameter("mineral",preload("res://assets/materials/stone/Rock030_1K-JPG_Color.jpg"))
		material.set_shader_parameter("motion",0.0 if w.reduced_motion else 1.0)
		material_cache[key]=material
	var surface:=MeshInstance3D.new()
	var plane:=PlaneMesh.new(); plane.size=Vector2(2.45,1.34) if lava else Vector2(3.32,4.40)
	surface.name="LavaBasin" if lava else "FloodedArchive"
	surface.mesh=plane; surface.material_override=material
	surface.transform=placement*Transform3D(Basis.IDENTITY,Vector3(0,.13,-3.25) if lava else Vector3(0,-.39,-2.08))
	surface.set_meta("regional_liquid",true); surface.set_meta("decoration_chamber",w.dressing_room)
	surface.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	w.add_child(surface)

# Camp compatibility: cached small dressed stones, never used as room-wall nodes.
static func masonry_piece(index: int=0) -> ArrayMesh:
	return masonry_mesh(index)

static func masonry_mesh(variant: int=0, wedge: bool=false) -> ArrayMesh:
	var key: int=posmod(variant,3)+(10 if wedge else 0)
	if masonry_cache.has(key): return masonry_cache[key]
	var outline: Array[Vector2]=[Vector2(-.39,-.5),Vector2(.42,-.5),Vector2(.5,-.36),Vector2(.5,.41),Vector2(.36,.5),Vector2(-.43,.5),Vector2(-.5,.35),Vector2(-.5,-.39)]
	var rings: Array=[]
	for row in range(4):
		var points: Array[Vector3]=[]
		for corner in range(8):
			var p: Vector2=outline[corner]
			var noise: float=sin(float(corner*13+key*7+row*5)*1.73)
			var bevel: float=[.88,1.0,.99,.86][row]
			var y: float=[-.5,-.37,.33,.5][row]
			if row==3: y-=.035+.105*maxf(0.0,sin(float(corner*7+key*11)*1.24))
			if row==2: y+=noise*.055
			p*=bevel
			p.x+=noise*.018; p.y+=cos(float(corner*9+key*5+row)*1.61)*.015
			if wedge: p.x*=lerpf(.71,1.0,(y+.5))
			points.append(Vector3(p.x,y,p.y))
		rings.append(points)
	var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(3):
		for corner in range(8):
			var following: int=(corner+1)%8
			var outward: Vector3=Vector3(outline[corner].x,0,outline[corner].y).normalized()
			_triangle(st,rings[row][corner],rings[row+1][corner],rings[row+1][following],outward)
			_triangle(st,rings[row][corner],rings[row+1][following],rings[row][following],outward)
	for row in [0,3]:
		var middle: Vector3=Vector3.ZERO
		for point in rings[row]: middle+=point
		middle/=8.0
		for corner in range(8): _triangle(st,middle,rings[row][corner],rings[row][(corner+1)%8],Vector3.DOWN if row==0 else Vector3.UP)
	st.index()
	var mesh: ArrayMesh=st.commit()
	masonry_cache[key]=mesh
	return mesh

static func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, outward: Vector3) -> void:
	var normal: Vector3=(b-a).cross(c-a).normalized()
	if normal.dot(outward)<0.0: normal=-normal
	# Godot's front faces are clockwise; the supplied normal faces out.
	var points: Array=[a,c,b] if (b-a).cross(c-a).dot(normal)>0.0 else [a,b,c]
	for point in points:
		st.set_normal(normal)
		var n: Vector3=normal.abs()
		st.set_uv(Vector2(point.z,point.y) if n.x>n.y and n.x>n.z else (Vector2(point.x,point.z) if n.y>n.z else Vector2(point.x,point.y)))
		st.add_vertex(point)
