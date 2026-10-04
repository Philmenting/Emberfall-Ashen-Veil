extends RefCounted
## Disjoint rectangles cover real rooms and corridors, with genuine open cuts.
static func subtract(source:Rect2,hole:Rect2)->Array[Rect2]:
	var cut:=source.intersection(hole)
	if cut.size.x<=.0001 or cut.size.y<=.0001: return [source]
	var result:Array[Rect2]=[]
	for piece in [Rect2(source.position,Vector2(source.size.x,cut.position.y-source.position.y)),Rect2(Vector2(source.position.x,cut.end.y),Vector2(source.size.x,source.end.y-cut.end.y)),Rect2(Vector2(source.position.x,cut.position.y),Vector2(cut.position.x-source.position.x,cut.size.y)),Rect2(Vector2(cut.end.x,cut.position.y),Vector2(source.end.x-cut.end.x,cut.size.y))]:
		if piece.size.x>.0001 and piece.size.y>.0001: result.append(piece)
	return result

static func cover(rectangles:Array[Rect2],holes:Array=[])->Array[Rect2]:
	var result:Array[Rect2]=[]
	for rectangle in rectangles:
		var fragments:Array[Rect2]=[rectangle]
		for existing in result:
			var next:Array[Rect2]=[]
			for fragment in fragments: next.append_array(subtract(fragment,existing))
			fragments=next
			if fragments.is_empty(): break
		result.append_array(fragments)
	for hole:Rect2 in holes:
		var next:Array[Rect2]=[]
		for rectangle in result: next.append_array(subtract(rectangle,hole))
		result=next
	return result

static func surface(rectangles:Array[Rect2],height:float)->ArrayMesh:
	var mesh:=SurfaceTool.new(); mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for piece in rectangles:
		var a:=Vector3(piece.position.x,height,piece.position.y)
		var b:=Vector3(piece.end.x,height,piece.position.y)
		var c:=Vector3(piece.end.x,height,piece.end.y)
		var d:=Vector3(piece.position.x,height,piece.end.y)
		for point in [a,b,c,a,c,d]:
			mesh.set_normal(Vector3.UP); mesh.add_vertex(point)
	return mesh.commit()

static func foundation(rectangles:Array[Rect2],height:float,depth:float)->ArrayMesh:
	var mesh:=SurfaceTool.new();mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for piece in rectangles:
		var corners:Array[Vector3]=[Vector3(piece.position.x,height,piece.position.y),Vector3(piece.end.x,height,piece.position.y),Vector3(piece.end.x,height,piece.end.y),Vector3(piece.position.x,height,piece.end.y)]
		for side in range(4):
			var a:=corners[side];var b:=corners[(side+1)%4]
			var c:=b-Vector3.UP*depth;var d:=a-Vector3.UP*depth
			var normal:Vector3=(b-a).cross(c-a).normalized()
			for point in [a,c,b,a,d,c]:
				mesh.set_normal(normal);mesh.add_vertex(point)
	return mesh.commit()
