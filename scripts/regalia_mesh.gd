extends RefCounted
## Original curved plate, cloth and weapon geometry, shared by articulated joints.
static var cache: Dictionary={}

static func panel(rings: Array, arc: float=1.25, segments: int=24) -> ArrayMesh:
	# Partial elliptical shell. The front is open only at its shaped outline.
	var key:=str([rings,arc,segments])
	if cache.has(key): return cache[key]
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(rings.size()-1):
		for column in range(segments):
			for corner in [[row,column],[row+1,column+1],[row,column+1],[row,column],[row+1,column],[row+1,column+1]]:
				var ring: Vector4=rings[corner[0]]
				var u:=float(corner[1])/segments
				var angle: float=PI+(u-0.5)*arc*2.0
				var before: Vector4=rings[maxi(0,corner[0]-1)]
				var after: Vector4=rings[mini(rings.size()-1,corner[0]+1)]
				var tangent:=Vector3(cos(angle)*ring.y,0,-sin(angle)*ring.z)
				var along:=Vector3(sin(angle)*(after.y-before.y),after.x-before.x,cos(angle)*(after.z-before.z)+after.w-before.w)
				surface.set_uv(Vector2(u,float(corner[0])/(rings.size()-1)))
				surface.set_normal(tangent.cross(along).normalized())
				surface.add_vertex(Vector3(sin(angle)*ring.y,ring.x,cos(angle)*ring.z+ring.w))
	surface.index()
	surface.generate_tangents()
	var mesh:=surface.commit()
	cache[key]=mesh
	return mesh

static func tube(points: Array, radius: float, sides: int=10) -> ArrayMesh:
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(points.size()-1):
		for side in range(sides):
			for corner in [[row,side],[row+1,side+1],[row,side+1],[row,side],[row+1,side],[row+1,side+1]]:
				var index: int=corner[0]
				var direction: Vector3=(points[mini(index+1,points.size()-1)]-points[maxi(0,index-1)]).normalized()
				var first:=direction.cross(Vector3.FORWARD).normalized()
				if first.length_squared()<0.1: first=direction.cross(Vector3.UP).normalized()
				var second:=direction.cross(first).normalized()
				var angle:=TAU*float(corner[1])/sides
				var normal:=first*cos(angle)+second*sin(angle)
				surface.set_normal(normal)
				surface.set_uv(Vector2(float(corner[1])/sides,float(index)/(points.size()-1)))
				surface.add_vertex(points[index]+normal*radius)
	surface.index()
	surface.generate_tangents()
	return surface.commit()

static func hood() -> ArrayMesh:
	# Back and sides wrap around a face opening, not a closed cone over the head.
	var rings: Array=[Vector4(1.65,0.13,0.12,0.02),Vector4(1.76,0.17,0.17,0.015),Vector4(1.94,0.16,0.17,0),Vector4(2.07,0.065,0.075,0.01)]
	var mesh:=panel(rings,2.02,32)
	# Rotate the open shell to the rear, leaving facial anatomy visible.
	return mesh

static func blade() -> ArrayMesh:
	# Cross section has sharpened edges and a raised central ridge.
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows: Array=[Vector3(0.13,0.095,0.025),Vector3(0.28,0.105,0.022),Vector3(1.10,0.060,0.018),Vector3(1.34,0.001,0.001)]
	for row in range(rows.size()-1):
		for side in range(4):
			for corner in [[row,side],[row+1,side],[row+1,side+1],[row,side],[row+1,side+1],[row,side+1]]:
				var ring: Vector3=rows[corner[0]]
				var angle:=TAU*float(corner[1])/4
				surface.set_uv(Vector2(float(corner[1])/4,float(corner[0])/3))
				surface.add_vertex(Vector3(sin(angle)*ring.y,ring.x,cos(angle)*ring.z))
	surface.generate_normals()
	surface.generate_tangents()
	return surface.commit()
