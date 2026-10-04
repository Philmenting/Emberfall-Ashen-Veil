extends RefCounted
## Connected original 0.48 regional architecture, with explicit passage clearance.
const Layout=preload("res://scripts/dungeon_layout.gd")
const RoomGround=preload("res://scripts/room_ground.gd")
const Authored=preload("res://scripts/authored_architecture.gd")
const MODEL_ROOT="res://assets/models/environment/"
const REGIONS=["spire","archive","ossuary","citadel"]
const MODELS={
	"spire_bay":preload("res://assets/models/environment/spire_bay.glb"),
	"spire_bay_broken":preload("res://assets/models/environment/spire_bay_broken.glb"),
	"spire_solid":preload("res://assets/models/environment/spire_solid.glb"),
	"spire_return":preload("res://assets/models/environment/spire_return.glb"),
	"archive_bay":preload("res://assets/models/environment/archive_bay.glb"),
	"archive_bay_broken":preload("res://assets/models/environment/archive_bay_broken.glb"),
	"archive_solid":preload("res://assets/models/environment/archive_solid.glb"),
	"archive_return":preload("res://assets/models/environment/archive_return.glb"),
	"ossuary_bay":preload("res://assets/models/environment/ossuary_bay.glb"),
	"ossuary_bay_broken":preload("res://assets/models/environment/ossuary_bay_broken.glb"),
	"ossuary_solid":preload("res://assets/models/environment/ossuary_solid.glb"),
	"ossuary_return":preload("res://assets/models/environment/ossuary_return.glb"),
	"citadel_bay":preload("res://assets/models/environment/citadel_bay.glb"),
	"citadel_bay_broken":preload("res://assets/models/environment/citadel_bay_broken.glb"),
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
		if not String(entry.kind).begins_with("bay"): continue
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
	_build_ground_joins(w,centers)

static func _plan(region: int,centers: Array,clearance: Array) -> Array:
	var result: Array=[]
	for room in range(centers.size()):
		var c: Vector3=centers[room]
		# Thin rear and left enclosures, with a genuine gap at every route crossing.
		# Each bay carries its own supported rear gallery; no crown spans a path.
		_fill_run(result,region,room,c+Vector3(0,0,-6.35),0.0,-13.10,13.10,"bay",clearance)
		_fill_run(result,region,room,c+Vector3(-6.95,0,0),PI*.5,-6.30,5.20,"bay",clearance)
		# The camera-near side is a low, damaged enclosure, never a tall end block.
		_fill_run(result,region,room,c+Vector3(6.95,0,1.40),-PI*.5,-4.35,4.35,"return",clearance)
	return result

static func _entry_transform(entry: Dictionary) -> Transform3D:
	return Transform3D(Basis(Vector3.UP,float(entry.angle)).scaled_local(Vector3(float(entry.width)/4.20,1.0,1.0)),entry.at)

static func _fill_run(output: Array,region: int,room: int,origin: Vector3,angle: float,minimum: float,maximum: float,kind: String,clearance: Array) -> void:
	# Split the placement band before instantiation. This adapts to every real
	# seed and turn; it does not add a collider and try to repair the route later.
	var intervals: Array[Vector2]=[Vector2(minimum,maximum)]
	var depth: float=([3.65,4.75,4.15,4.70][region] if kind!="return" else 1.0)
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
		var count: int=maxi(1,ceili(length/4.65))
		var width: float=length/float(count)
		for index_value in range(count):
			var middle: float=interval.x+(float(index_value)+.5)*width
			var chosen: String=kind if width>=3.30 or kind=="return" else "solid"
			if chosen=="bay" and (index_value+room)%2==1: chosen="bay_broken"
			var entry: Dictionary={"region":region,"room":room,"kind":chosen,"at":origin+basis*Vector3(middle,0,0),"angle":angle,"width":width+.035}
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
		"masonry": return _masonry(w,false)
		"dressed_stone": return _masonry(w,true)
		"paving": return w.court_material
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

static func _masonry(w,dressed: bool=false) -> ShaderMaterial:
	var cache: Dictionary=_world_materials(w)
	var key: String="dressed_stone" if dressed else "masonry"
	if cache.has(key): return cache[key]
	var material:=ShaderMaterial.new()
	material.shader=preload("res://assets/shaders/masonry_surface.gdshader")
	material.set_shader_parameter("masonry_color",preload("res://assets/materials/stone/Rock030_1K-JPG_Color.jpg") if dressed else preload("res://assets/materials/masonry/Bricks096_1K-PNG_Color.png"))
	material.set_shader_parameter("masonry_normal",preload("res://assets/materials/stone/Rock030_1K-JPG_NormalGL.jpg") if dressed else preload("res://assets/materials/masonry/Bricks096_1K-PNG_NormalGL.png"))
	material.set_shader_parameter("masonry_roughness",preload("res://assets/materials/stone/Rock030_1K-JPG_Roughness.jpg") if dressed else preload("res://assets/materials/masonry/Bricks096_1K-PNG_Roughness.png"))
	material.set_shader_parameter("meters_per_repeat",Vector2(1.4,1.4) if dressed else Vector2(2.8,1.4))
	material.set_shader_parameter("pigment_saturation",.35)
	material.set_shader_parameter("dampness",.32)
	material.set_shader_parameter("roughness_bias",.08)
	material.set_shader_parameter("relief",.38 if dressed else .80)
	material.set_shader_parameter("stone_tint",Color(["dddcd7","d1ddd4","e2dbd0","d4c7b9"][w.region_index]))
	cache[key]=material
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
		if part.channel=="paving": piece.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		w.add_child(piece)
	if String(entry.kind).begins_with("bay"):
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

static func _build_ground_joins(w,centers: Array) -> void:
	# Only the real Court union's exposed edges receive low native continuations.
	# Channel edges belong to their authored banks and must stay open.
	var court: MeshInstance3D=w.get_node_or_null("ContinuousStoneCourt")
	if court==null or not court.has_meta("ground_rectangles"): return
	var rectangles: Array[Rect2]=[]
	rectangles.assign(court.get_meta("ground_rectangles"))
	var holes: Array=court.get_meta("channel_holes",[])
	var groups: Dictionary={}
	for edge: PackedVector2Array in RoomGround.boundary_edges(rectangles):
		var a: Vector2=edge[0]; var b: Vector2=edge[1]
		var along: Vector2=(b-a).normalized()
		var outward:=Vector2(along.y,-along.x)
		var count: int=maxi(1,ceili(a.distance_to(b)/1.4))
		for index_value in range(count):
			var p: Vector2=a.lerp(b,float(index_value)/count)
			var q: Vector2=a.lerp(b,float(index_value+1)/count)
			var middle: Vector2=(p+q)*.5
			var channel:=false
			for hole: Rect2 in holes:
				if hole.grow(.8).has_point(middle+outward*.35): channel=true; break
			if channel: continue
			var room:=0; var nearest:=INF
			for candidate in range(centers.size()):
				var center: Vector3=centers[candidate]
				var distance: float=middle.distance_squared_to(Vector2(center.x,center.z))
				if distance<nearest: nearest=distance; room=candidate
			var width_p: float=.91+.24*sin(p.x*2.7+p.y*1.83)
			var width_q: float=.91+.24*sin(q.x*2.7+q.y*1.83)
			var outer_p: Vector2=p+outward*width_p
			var outer_q: Vector2=q+outward*width_q
			# At re-entrant corners stop a skirt that would enter another court.
			var overlap:=false
			for rectangle: Rect2 in rectangles:
				if rectangle.has_point((outer_p+outer_q)*.5): overlap=true; break
			if overlap: continue
			if not groups.has(room):
				var top:=SurfaceTool.new(); top.begin(Mesh.PRIMITIVE_TRIANGLES)
				var side:=SurfaceTool.new(); side.begin(Mesh.PRIMITIVE_TRIANGLES)
				groups[room]={"paving":top,"masonry":side}
			var inner_a:=Vector3(p.x,-.030,p.y)
			var inner_b:=Vector3(q.x,-.030,q.y)
			var outer_a:=Vector3(outer_p.x,-.09-.025*sin(p.x+p.y),outer_p.y)
			var outer_b:=Vector3(outer_q.x,-.09-.025*sin(q.x+q.y),outer_q.y)
			_emit_join_quad(groups[room].paving,[inner_a,inner_b,outer_b,outer_a],Vector3.UP)
			var foot_a:=outer_a+Vector3(outward.x*.23,-1.25,outward.y*.23)
			var foot_b:=outer_b+Vector3(outward.x*.23,-1.25,outward.y*.23)
			_emit_join_quad(groups[room].masonry,[outer_a,outer_b,foot_b,foot_a],Vector3(outward.x,0,outward.y))
	for room in groups:
		for family: String in groups[room]:
			var surface: SurfaceTool=groups[room][family]
			surface.generate_tangents()
			var mesh: ArrayMesh=surface.commit()
			if mesh.get_surface_count()==0: continue
			var node:=MeshInstance3D.new()
			node.name="CourtJoin_%d_%s"%[room,family]
			node.mesh=mesh
			node.material_override=w.court_material if family=="paving" else _masonry(w)
			node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			node.set_meta("decoration_chamber",room)
			node.set_meta("regional_module","ground_join")
			w.add_child(node)

static func _emit_join_quad(surface: SurfaceTool,points: Array,normal: Vector3) -> void:
	var tangent: Vector3=Vector3.RIGHT if absf(normal.y)>.5 else Vector3.UP.cross(normal).normalized()
	var bitangent: Vector3=normal.cross(tangent).normalized()
	var winding: Array=[0,1,2,0,2,3]
	if (points[1]-points[0]).cross(points[2]-points[0]).dot(normal)>0.0: winding=[0,2,1,0,3,2]
	for index_value: int in winding:
		var point: Vector3=points[index_value]
		surface.set_normal(normal)
		surface.set_uv(Vector2(point.dot(tangent),point.dot(bitangent)))
		surface.add_vertex(point)

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
