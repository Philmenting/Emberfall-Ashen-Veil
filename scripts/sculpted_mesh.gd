extends RefCounted
## Elliptical ring profiles: height, half-width, half-depth, forward offset.
## Original continuous surfaces replace stacks of disconnected primitives.
static var profile_cache: Dictionary={}

static func profile(rings: Array, sides: int=24) -> ArrayMesh:
	var cache_key:=str(rings)+":"+str(sides)
	if profile_cache.has(cache_key): return profile_cache[cache_key]
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(rings.size()-1):
		for side in range(sides):
			for corner in [[row,side],[row+1,side+1],[row,side+1],[row,side],[row+1,side],[row+1,side+1]]:
				var ring: Vector4=rings[corner[0]]
				var angle:=TAU*float(corner[1])/sides
				surface.set_uv(Vector2(float(corner[1])/sides,float(corner[0])/(rings.size()-1)))
				var before: Vector4=rings[maxi(0,int(corner[0])-1)]
				var after: Vector4=rings[mini(rings.size()-1,int(corner[0])+1)]
				var around:=Vector3(cos(angle)*ring.y,0,-sin(angle)*ring.z)
				var along:=Vector3(sin(angle)*(after.y-before.y),after.x-before.x,cos(angle)*(after.z-before.z)+after.w-before.w)
				surface.set_normal(around.cross(along).normalized())
				surface.add_vertex(Vector3(sin(angle)*ring.y,ring.x,cos(angle)*ring.z+ring.w))
	for cap in [0,rings.size()-1]:
		var ring: Vector4=rings[cap]
		for side in range(sides):
			var order: Array=[side,side+1] if cap==0 else [side+1,side]
			for index in [-1,order[0],order[1]]:
				var angle:=TAU*float(index)/sides
				surface.set_uv(Vector2(0.5,0.5) if index==-1 else Vector2(sin(angle),cos(angle))*0.5+Vector2.ONE*0.5)
				surface.set_normal(Vector3.DOWN if cap==0 else Vector3.UP)
				surface.add_vertex(Vector3(0,ring.x,ring.w) if index==-1 else Vector3(sin(angle)*ring.y,ring.x,cos(angle)*ring.z+ring.w))
	surface.index()
	var result:=surface.commit()
	profile_cache[cache_key]=result
	return result

static func paver() -> ArrayMesh:
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	var outline: Array=[Vector2(-0.46,-0.5),Vector2(0.46,-0.5),Vector2(0.5,-0.46),Vector2(0.5,0.46),Vector2(0.46,0.5),Vector2(-0.46,0.5),Vector2(-0.5,0.46),Vector2(-0.5,-0.46)]
	for row in range(2):
		for side in range(8):
			for corner in [[row,side],[row+1,(side+1)%8],[row+1,side],[row,side],[row,(side+1)%8],[row+1,(side+1)%8]]:
				var point: Vector2=outline[corner[1]]*(0.96 if corner[0]==2 else 1.0)
				surface.set_uv(point+Vector2.ONE*0.5)
				surface.add_vertex(Vector3(point.x,[-0.5,0.32,0.5][corner[0]],point.y))
	for side in range(8):
		for index in [-1,side,(side+1)%8]:
			var point: Vector2=Vector2.ZERO if index<0 else outline[index]*0.96
			surface.set_uv(point+Vector2.ONE*0.5)
			surface.add_vertex(Vector3(point.x,0.5,point.y))
	surface.generate_normals()
	return surface.commit()

static var bevel_cache: Dictionary={}

static func bevelled_box(bevel: float=0.06) -> ArrayMesh:
	var key:=clampf(bevel,0.005,0.2)
	if bevel_cache.has(key): return bevel_cache[key]
	var inner:=0.5-key
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for axis in range(3):
		for sign_value in [-1.0,1.0]:
			var normal:=Vector3.ZERO
			normal[axis]=sign_value
			var points: Array[Vector3]=[]
			for corner in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
				var point:=normal*0.5
				point[(axis+1)%3]=corner.x*inner
				point[(axis+2)%3]=corner.y*inner
				points.append(point)
			_polygon(surface,points,normal)
	for axis in range(3):
		var a: int=(axis+1)%3
		var b: int=(axis+2)%3
		for first in [-1.0,1.0]:
			for second in [-1.0,1.0]:
				var normal:=Vector3.ZERO
				normal[a]=first
				normal[b]=second
				var points: Array[Vector3]=[]
				for corner in [Vector2(-inner,0),Vector2(inner,0),Vector2(inner,1),Vector2(-inner,1)]:
					var point:=Vector3.ZERO
					point[axis]=corner.x
					point[a]=first*(0.5 if corner.y==0 else inner)
					point[b]=second*(inner if corner.y==0 else 0.5)
					points.append(point)
				_polygon(surface,points,normal.normalized())
	for x in [-1.0,1.0]:
		for y in [-1.0,1.0]:
			for z in [-1.0,1.0]:
				_polygon(surface,[Vector3(x*0.5,y*inner,z*inner),Vector3(x*inner,y*0.5,z*inner),Vector3(x*inner,y*inner,z*0.5)],Vector3(x,y,z).normalized())
	surface.index()
	var result:=surface.commit()
	result.set_meta("batch_shape","bevel:"+str(key))
	bevel_cache[key]=result
	return result

static func _polygon(surface: SurfaceTool, points: Array, normal: Vector3) -> void:
	if (points[1]-points[0]).cross(points[2]-points[0]).dot(normal)>0:
		points.reverse()
	for index in range(1,points.size()-1):
		for point: Vector3 in [points[0],points[index],points[index+1]]:
			surface.set_normal(normal)
			surface.set_uv(Vector2(point.x,point.z)+Vector2.ONE*0.5)
			surface.add_vertex(point)

static func mantle() -> ArrayMesh:
	if profile_cache.has("mantle"): return profile_cache["mantle"]
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in [-1.0,1.0]:
		for row in range(8):
			for column in range(16):
				var points: Array=[Vector2(column,row),Vector2(column+1,row+1),Vector2(column+1,row),Vector2(column,row),Vector2(column,row+1),Vector2(column+1,row+1)]
				if face>0: points.reverse()
				for point: Vector2 in points:
					var u: float=point.x/16.0
					var v: float=point.y/8.0
					var width:=lerpf(0.22,0.39,v)
					var fold:=sin(u*PI*8.0)*0.025*v
					var hem:=sin(u*PI*5.0)*0.035*v*v
					surface.set_uv(Vector2(u,v))
					surface.add_vertex(Vector3((u*2.0-1.0)*width,-v*1.16+hem,v*v*0.23+fold+face*0.004))
	surface.generate_normals()
	surface.index()
	var result:=surface.commit()
	profile_cache["mantle"]=result
	return result
