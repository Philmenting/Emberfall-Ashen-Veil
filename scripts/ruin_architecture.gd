extends RefCounted
## Original live masonry: four construction systems, shared clearance and UV-lit stone.
const Layout=preload("res://scripts/dungeon_layout.gd")
const Authored=preload("res://scripts/authored_architecture.gd")
static var masonry_cache: Dictionary={}

# Public court contract. Rect2.x/y are WORLD X/Z; callers cut these exact holes
# from the court at y=-.019. The channel surfaces below use this same function.
# There are no holes in either the room or its actual generated walking route.
static func ground_holes(region: int, centers: Array, walking_rects: Array) -> Array[Rect2]:
	var holes: Array[Rect2]=[]
	if region not in [1,3]: return holes
	for center_value in centers:
		var c: Vector3=center_value
		holes.append_array(_channel_holes(c,walking_rects))
	return holes

static func _channel_holes(c: Vector3, walking_rects: Array) -> Array[Rect2]:
	var pieces: Array[Rect2]=[Rect2(Vector2(c.x-7.85,c.z-4.8),Vector2(1.75,9.6))]
	for walking in walking_rects:
		var next: Array[Rect2]=[]
		for piece in pieces: next.append_array(_subtract_rect(piece,walking.grow(.22)))
		pieces=next
	var result: Array[Rect2]=[]
	for piece in pieces:
		if piece.size.x>=.55 and piece.size.y>=1.2: result.append(piece)
	return result

static func _subtract_rect(source: Rect2, cut: Rect2) -> Array[Rect2]:
	if not source.intersects(cut): return [source]
	var overlap: Rect2=source.intersection(cut)
	var result: Array[Rect2]=[]
	if overlap.position.y>source.position.y:
		result.append(Rect2(source.position,Vector2(source.size.x,overlap.position.y-source.position.y)))
	if overlap.end.y<source.end.y:
		result.append(Rect2(Vector2(source.position.x,overlap.end.y),Vector2(source.size.x,source.end.y-overlap.end.y)))
	if overlap.position.x>source.position.x:
		result.append(Rect2(Vector2(source.position.x,overlap.position.y),Vector2(overlap.position.x-source.position.x,overlap.size.y)))
	if overlap.end.x<source.end.x:
		result.append(Rect2(Vector2(overlap.end.x,overlap.position.y),Vector2(source.end.x-overlap.end.x,overlap.size.y)))
	return result

static func build(w) -> void:
	for room in range(6):
		w.dressing_room=room
		var c: Vector3=w._point(Layout.center(w.region_index,room,w.simulation.layout_seed())) if w.simulation.uses_journey() else Vector3(0,0,4-room*11.2)
		match w.region_index:
			0: _bell_nave(w,c,room)
			1: _retaining_archive(w,c,room)
			2: _carved_ossuary(w,c,room)
			3: _furnace_works(w,c,room)
		if w.region_index in [1,3]:
			for hole in _channel_holes(c,w.dressing_clearance): _channel(w,hole,w.region_index==3)
		# Fallen facings stay against the wall; none floats in the combat aisle.
		for i in range(9):
			var along: float=-5.25+float(i)*1.27
			var at: Vector3=c+Vector3(-8.15-float(i%3)*.31,.13,along)
			_stone(w,at,Vector3(.42+float(i%3)*.17,.27,.49+float(i%2)*.26),4,i,Basis.from_euler(Vector3(.08,float(i)*1.29,.11)))
		_deposit(w,c+Vector3(-6.0,.012,0),Vector2(2.7,11.6),.54)
		_deposit(w,c+Vector3(-3.6,.013,-6.15),Vector2(7.2,2.6),.44)
	w.dressing_room=-1

# Eight clipped corners, several uneven face rings and a fractured top preserve
# real chipped silhouettes under live light. Three variants share cached meshes.
# Exposed for the camp to use the same worn construction without a new raster.
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

static func _instance(w, mesh: Mesh, at: Vector3, size: Vector3, material: Material, orientation: Basis=Basis.IDENTITY) -> MeshInstance3D:
	var transform:=Transform3D(orientation.scaled_local(size),at)
	var bounds: AABB=transform*mesh.get_aabb()
	if bounds.end.y>.5 and bounds.position.y<2.8 and not w._dressing_footprint_clear(bounds.get_center(),bounds.size): return null
	var part:=MeshInstance3D.new()
	part.mesh=mesh; part.transform=transform; part.material_override=material
	part.set_meta("decoration_chamber",w.dressing_room)
	w.add_child(part)
	return part

static func _stone(w, at: Vector3, size: Vector3, tone: int=2, variant: int=0, orientation: Basis=Basis.IDENTITY) -> MeshInstance3D:
	return _instance(w,masonry_mesh(variant),at,size,w.floor_materials[posmod(tone,5)],orientation)

static func _iron(w) -> Material:
	var original:=StandardMaterial3D.new()
	original.resource_name="iron"; original.albedo_color=Color(w.theme.metal).darkened(.24)
	original.metallic=.68; original.roughness=.78
	return Authored.crafted(original)

static func _metal(w, at: Vector3, size: Vector3, orientation: Basis=Basis.IDENTITY) -> MeshInstance3D:
	return _instance(w,masonry_mesh(0),at,size,_iron(w),orientation)

static func _prop(w, key: String, at: Vector3, scale: Vector3, angle: float=0.0) -> Node3D:
	var prop: Node3D=w._authored_prop(key,at,angle)
	prop.scale=scale
	for part in prop.find_children("*","MeshInstance3D",true,false): part.set_meta("decoration_chamber",w.dressing_room)
	w._keep_clear_dressing(prop)
	return prop

# A rubble-filled wall has unequal courses, staggered large facings and a ragged
# broken crest. Opening intervals omit full facing stones, exposing real depth.
static func _wall(w, origin: Vector3, length: float, height: float, depth: float, side_face: bool, seed_value: int, openings: Array=[]) -> void:
	var y: float=0.0
	var row: int=0
	while y<height-.18:
		var course: float=[.72,.53,.86,.62,.67][posmod(row+seed_value,5)]
		var u: float=-length*.5
		var column: int=0
		while u<length*.5-.1:
			var width: float=minf([1.53,1.06,1.92,1.31,2.07][posmod(column+row*2+seed_value,5)],length*.5-u)
			var middle: float=u+width*.5
			var crest: float=height-.42*maxf(0.0,sin(middle*1.33+float(seed_value)))-.34*maxf(0.0,cos(middle*.68))
			var keep: bool=y+course*.5<crest
			for opening in openings:
				var gap: Vector3=opening # local center, half-width, opening height
				if absf(middle-gap.x)<gap.y+width*.48 and y<gap.z: keep=false
			if keep and width>.16:
				var local:=Vector3(middle,y+course*.5-.03,.025*sin(float(column*3+row)))
				var dimensions:=Vector3(width+.035,course+.04,depth*(1.0+.075*sin(float(row*5+column))))
				if side_face: local=Vector3(local.z,local.y,local.x); dimensions=Vector3(dimensions.z,dimensions.y,dimensions.x)
				_stone(w,origin+local,dimensions,[1,2,4][posmod(column+row+seed_value,3)],column+row)
			u+=width
			column+=1
		y+=course*.93
		row+=1

static func _pier(w, at: Vector3, height: float, width: float, depth: float, seed_value: int) -> void:
	var y: float=0.0
	var row: int=0
	while y<height-.12:
		var h: float=minf([.54,.81,.72,.96][posmod(row+seed_value,4)],height-y)
		var taper: float=lerpf(1.0,.70,minf(1.0,y/(height*.70)))
		if y>height-.8: taper=.91
		_stone(w,at+Vector3(.035*sin(float(row*4+seed_value)),y+h*.5,0),Vector3(width*taper,h+.04,depth*(.86+taper*.14)),[1,2,4][posmod(row+seed_value,3)],row+seed_value)
		y+=h*.95
		row+=1

static func _arch(w, origin: Vector3, half_width: float, spring: float, rise: float, thickness: float, depth: float, side_face: bool=false, tone: int=2) -> void:
	var segments: int=12
	var facing:=Basis(Vector3.UP,PI*.5 if side_face else 0.0)
	for segment in range(segments):
		var angle: float=PI*(float(segment)+.5)/float(segments)
		var position:=Vector3(cos(angle)*half_width,spring+sin(angle)*rise,0)
		var tangent_angle: float=atan2(-cos(angle)*rise,sin(angle)*half_width)
		var span: float=Vector2(sin(angle)*half_width,cos(angle)*rise).length()*PI/float(segments)*1.035
		var orientation: Basis=facing*Basis(Vector3.BACK,tangent_angle)
		_instance(w,masonry_mesh(0,true),origin+facing*position,Vector3(span,thickness,depth),w.floor_materials[tone],orientation)

static func _bell_nave(w,c: Vector3,room: int) -> void:
	# Massive clustered belfry supports: the nave is held by piers, not shelves.
	_wall(w,c+Vector3(-9.05,0,.2),13.8,5.4,1.45,true,room,[Vector3(-1.7,1.45,3.3)])
	for entry in [[-5.2,6.9],[1.9,7.8],[5.7,4.6]]:
		var z: float=entry[0]
		_pier(w,c+Vector3(-7.98,0,z),entry[1],2.05,2.25,room+int(z))
		_stone(w,c+Vector3(-7.66,.22,z),Vector3(2.65,.54,2.8),4,room)
	_arch(w,c+Vector3(-8.0,0,-1.6),2.6,3.0,2.75,.73,1.65,true,1)
	_prop(w,"bell",c+Vector3(-8.1,3.25,-1.6),Vector3.ONE*(1.7 if room==5 else 1.42))
	_metal(w,c+Vector3(-8.1,6.0,-1.6),Vector3(.32,.30,4.25))
	_prop(w,"tomb",c+Vector3(-6.97,0,3.3),Vector3(.90,.91,.94),.12)
	# The rear load-bearing arch leaves the entire authoritative route open.
	_wall(w,c+Vector3(-7.85,0,-8.25),5.0,5.9,1.85,false,room+2)
	_wall(w,c+Vector3(8.2,0,-8.15),4.2,2.8,1.75,false,room+4)
	_pier(w,c+Vector3(-6.75,0,-7.9),6.4,1.85,2.1,room)
	_pier(w,c+Vector3(6.9,0,-8.0),3.5,1.82,1.85,room+1)
	_arch(w,c+Vector3(0,0,-8.35),6.95,3.50,3.0,.74,1.8,false,2)
	# A fallen fractured return, angled off the room, resolves the broken end.
	_stone(w,c+Vector3(7.9,.33,-5.9),Vector3(2.5,.62,2.9),4,room,Basis(Vector3.UP,-.32))
	if room in [1,5]: _prop(w,"bell",c+Vector3(-6.85,.24,-4.15),Vector3.ONE*.60,.45)

static func _retaining_archive(w,c: Vector3,room: int) -> void:
	# Water bears against a broad battered stack-house wall. Book storage is
	# raised behind its footings; the open foreground channel stays in sight.
	_wall(w,c+Vector3(-9.45,0,.0),13.1,4.65,2.3,true,room+3,[Vector3(.4,1.65,3.35)])
	for z in [-5.35,3.65]:
		_pier(w,c+Vector3(-8.7,-.32,z),5.35 if z<0 else 3.9,2.35,1.9,room+3)
		_stone(w,c+Vector3(-8.28,.21,z),Vector3(1.9,.64,2.65),4,room)
	# Deep masonry niche with a supported shelf unit; no freestanding grid wall.
	_stone(w,c+Vector3(-9.25,.27,.40),Vector3(2.65,.62,4.10),4,room)
	_prop(w,"library",c+Vector3(-8.82,.57,.45),Vector3(.61,.85,.64),PI*.5)
	_arch(w,c+Vector3(-8.55,0,.45),2.0,2.45,1.15,.74,1.7,true,4)
	# Ruined watergate shoulders and a skewed low vault replace the nave arch.
	_wall(w,c+Vector3(-7.35,0,-7.65),6.0,4.2,2.1,false,room+1)
	_wall(w,c+Vector3(7.6,0,-7.85),3.65,2.9,2.0,false,room+2)
	_pier(w,c+Vector3(-4.90,0,-8.65),5.7,2.35,2.1,room+4)
	_arch(w,c+Vector3(-2.1,0,-8.65),3.4,3.25,1.45,.90,2.2,false,4)
	# Water-control tie irons are mounted to the retaining wall.
	for z in [-4.5,2.9]:
		_metal(w,c+Vector3(-8.18,1.12,z),Vector3(.13,.21,1.2))
		_metal(w,c+Vector3(-8.16,1.45,z),Vector3(.13,.91,.15))
	if room in [2,5]:
		_prop(w,"library",c+Vector3(6.95,.25,-7.25),Vector3(.70,.68,.7),PI)
		_stone(w,c+Vector3(6.95,.09,-7.3),Vector3(3.8,.29,1.9),4,room)

static func _carved_ossuary(w,c: Vector3,room: int) -> void:
	# A continuous thick burial wall is cut into deep arched loculi. Tombs sit
	# inside their stone reveals rather than lining up as loose floor ornaments.
	_wall(w,c+Vector3(-9.1,0,0),13.0,5.85,1.6,true,room+6,[Vector3(-3.25,1.10,2.8),Vector3(2.45,1.10,3.15)])
	for slot in range(2):
		var z: float=-3.25+float(slot)*5.7
		_stone(w,c+Vector3(-9.77,1.55,z),Vector3(.48,3.1,3.1),4,slot)
		for side in [-1.0,1.0]: _pier(w,c+Vector3(-8.10,0,z+side*1.58),3.75,1.75,.94,room+slot)
		_arch(w,c+Vector3(-8.11,0,z),1.65,2.0,1.76,.72,1.74,true,1)
		_stone(w,c+Vector3(-8.6,.15,z),Vector3(2.55,.38,3.0),4,room)
		_prop(w,"tomb",c+Vector3(-8.15,.32,z),Vector3(.88,.95,.78),PI*.5)
	# Carved transverse ribs spring from broad shoulders behind the combat plane.
	_wall(w,c+Vector3(-7.75,0,-8.2),5.15,5.6,1.8,false,room+2)
	_wall(w,c+Vector3(7.2,0,-8.4),3.3,3.5,1.55,false,room+4)
	_pier(w,c+Vector3(-6.7,0,-8.0),5.15,2.0,1.9,room)
	_pier(w,c+Vector3(6.9,0,-8.15),3.75,1.9,1.9,room+3)
	_arch(w,c+Vector3(0,0,-8.15),6.9,3.6,3.6,.47,1.15,false,1)
	_arch(w,c+Vector3(0,0,-9.2),6.9,3.6,3.6,.34,.68,false,4)
	if room in [3,5]: _prop(w,"altar",c+Vector3(-6.8,0,-6.9),Vector3(.75,.85,.75),PI*.88)
	for i in range(4):
		_instance(w,masonry_mesh(i),c+Vector3(-6.5-float(i%2)*.4,.055,-3.0+float(i)*1.8),Vector3(.45,.09,.10),w.materials.bone,Basis(Vector3.UP,float(i)*.79))

static func _furnace_works(w,c: Vector3,room: int) -> void:
	# Furnace shell and flue are architecture: thick shoulders surround a dark
	# firebox, then narrow into a battered chimney. No classical column kit.
	_wall(w,c+Vector3(-9.55,0,0),13.2,3.35,2.05,true,room+4,[Vector3(-1.2,1.65,2.65)])
	for z in [-3.25,.85]:
		_pier(w,c+Vector3(-8.55,0,z),4.1,2.15,1.55,room+int(z))
	_arch(w,c+Vector3(-8.4,0,-1.2),2.08,1.35,1.68,.92,2.15,true,4)
	# The dark firebox lies behind the grate; the channel starts in front of it.
	_stone(w,c+Vector3(-10.1,1.15,-1.2),Vector3(.45,2.8,3.1),4,room)
	_prop(w,"furnace",c+Vector3(-8.92,.05,-1.2),Vector3(.88,1.18,.90),PI*.5)
	_chimney(w,c+Vector3(-9.05,3.35,-1.2),4.15 if room%2==0 else 5.1,3.20,3.1,room)
	for z in [-2.65,.23]:
		_metal(w,c+Vector3(-7.56,1.30,z),Vector3(.19,2.65,.19))
		_metal(w,c+Vector3(-7.53,2.23,z),Vector3(.19,.22,.66))
	# Massive black-iron transverse bracing hangs above the open passage.
	_wall(w,c+Vector3(-7.45,0,-8.45),5.55,4.65,2.05,false,room+5)
	_wall(w,c+Vector3(7.7,0,-8.7),3.8,2.6,2.15,false,room+1)
	_chimney(w,c+Vector3(-6.7,0,-8.7),7.1,2.5,2.65,room+1)
	_chimney(w,c+Vector3(7.3,0,-8.65),4.7,2.65,2.50,room+2)
	for y in [3.65,4.65]: _metal(w,c+Vector3(.3,y,-8.68),Vector3(13.5,.28,.47))
	for x in [-4.9,-1.45,2.1,5.35]:
		_metal(w,c+Vector3(x,4.14,-8.70),Vector3(.15,1.15,.20),Basis(Vector3.BACK,.5))
	# A low broken casting bed grounds the service area beside the furnace.
	_stone(w,c+Vector3(-8.05,.15,4.6),Vector3(2.5,.40,2.5),4,room)
	for z in [3.75,4.4,5.1]: _metal(w,c+Vector3(-7.65,.42,z),Vector3(1.50,.17,.32))
	if room==5: _prop(w,"throne",c+Vector3(-6.8,0,-6.8),Vector3(.82,.98,.85),PI*.83)

static func _chimney(w,at: Vector3,height: float,width: float,depth: float,seed_value: int) -> void:
	# Raking, connected flue walls with an open crown; each course has chipped
	# edges and different bedding. A dark inset lies below the actual opening.
	var y: float=0.0
	var row: int=0
	while y<height-.15:
		var h: float=minf(.78+float(posmod(row+seed_value,3))*.17,height-y)
		var taper: float=lerpf(1.0,.60,y/height)
		var w0: float=width*taper
		var d0: float=depth*taper
		for side in [-1.0,1.0]:
			_stone(w,at+Vector3(side*(w0*.5-.20),y+h*.5,0),Vector3(.55,h+.045,d0),4,row+seed_value)
			_stone(w,at+Vector3(0,y+h*.5,side*(d0*.5-.20)),Vector3(maxf(.6,w0-.65),h+.045,.55),[2,4][row%2],row)
		if row in [1,4]:
			for side in [-1.0,1.0]: _metal(w,at+Vector3(side*(w0*.5+.015),y+.16,0),Vector3(.10,.18,d0+.11))
		y+=h*.95
		row+=1
	_stone(w,at+Vector3(0,height-.68,0),Vector3(width*.49,.16,depth*.49),4,seed_value)

static func _channel(w,hole: Rect2,lava: bool) -> void:
	var middle: Vector2=hole.get_center()
	w._liquid(Vector3(middle.x,-.30,middle.y),hole.size,lava)
	var liquid: Node=w.get_child(w.get_child_count()-1)
	liquid.set_meta("decoration_chamber",w.dressing_room)
	liquid.set_meta("court_hole",hole)
	# Banks expose their vertical cross-section below the actual walking plane.
	for side in [-1.0,1.0]:
		var x: float=middle.x+side*(hole.size.x*.5+.11)
		var segment_count: int=maxi(1,ceili(hole.size.y/1.35))
		var segment: float=hole.size.y/float(segment_count)
		for j in range(segment_count):
			var z: float=hole.position.y+(float(j)+.5)*segment
			_stone(w,Vector3(x,-.28,z),Vector3(.45,.94,segment+.08),4,j)
			_stone(w,Vector3(x,.145,z),Vector3(.57,.24,segment+.09),2,j+1)
	for side in [-1.0,1.0]:
		_stone(w,Vector3(middle.x,-.29,middle.y+side*(hole.size.y*.5+.13)),Vector3(hole.size.x+.68,.89,.40),4,1)
	if lava:
		# Short maintenance grates, with most of the molten channel left visible.
		var z: float=hole.position.y+.72
		while z<hole.end.y-.5:
			for bar in range(4):
				_metal(w,Vector3(middle.x,.055,z+float(bar)*.22),Vector3(hole.size.x+.32,.14,.095))
			for side in [-1.0,1.0]: _metal(w,Vector3(middle.x+side*(hole.size.x*.5-.1),.075,z+.33),Vector3(.11,.16,.86))
			z+=3.15
	else:
		# Retaining pins belong to the bank, with no objects floating on the water.
		for j in range(2):
			_metal(w,Vector3(hole.position.x-.14,.18,hole.position.y+.7+float(j)*(hole.size.y-1.4)),Vector3(.14,.48,.14))

static func _deposit(w,at: Vector3,size: Vector2,opacity: float) -> void:
	var patch:=MeshInstance3D.new(); var plane:=PlaneMesh.new(); plane.size=size
	patch.name="WallFootingDeposit"; patch.mesh=plane; patch.position=at
	var mat:=ShaderMaterial.new(); mat.shader=preload("res://assets/shaders/ruin_deposit.gdshader")
	mat.set_shader_parameter("mineral",preload("res://assets/materials/stone/Rock030_1K-JPG_Color.jpg"))
	mat.set_shader_parameter("deposit_color",Color(.075,.085,.075,opacity) if w.region_index==1 else Color(.12,.10,.08,opacity))
	patch.material_override=mat; patch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	patch.set_meta("decoration_chamber",w.dressing_room)
	w.add_child(patch)
