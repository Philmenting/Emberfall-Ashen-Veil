extends RefCounted
## Elliptical ring profiles: height, half-width, half-depth, forward offset.
## Original continuous surfaces replace stacks of disconnected primitives.
static var profile_cache: Dictionary={}

static func profile(rings: Array, sides: int=16) -> ArrayMesh:
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
				surface.add_vertex(Vector3(sin(angle)*ring.y,ring.x,cos(angle)*ring.z+ring.w))
	for cap in [0,rings.size()-1]:
		var ring: Vector4=rings[cap]
		for side in range(sides):
			var order: Array=[side,side+1] if cap==0 else [side+1,side]
			for index in [-1,order[0],order[1]]:
				var angle:=TAU*float(index)/sides
				surface.set_uv(Vector2(0.5,0.5) if index==-1 else Vector2(sin(angle),cos(angle))*0.5+Vector2.ONE*0.5)
				surface.add_vertex(Vector3(0,ring.x,ring.w) if index==-1 else Vector3(sin(angle)*ring.y,ring.x,cos(angle)*ring.z+ring.w))
	surface.generate_normals()
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
