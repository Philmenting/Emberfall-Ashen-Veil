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

static func boundary_edges(rectangles:Array[Rect2])->Array[PackedVector2Array]:
	# cover() produces disjoint rectangles. Remove the shared portions of their
	# edges, including T-junctions, so construction follows the actual perimeter.
	# Basin edges remain present: their stone walls must end at the open water.
	var result:Array[PackedVector2Array]=[]
	for piece in rectangles:
		for side in range(4):
			var horizontal:=side%2==0
			var line:float=[piece.position.y,piece.end.x,piece.end.y,piece.position.x][side]
			var spans:Array[Vector2]=[Vector2(piece.position.x,piece.end.x) if horizontal else Vector2(piece.position.y,piece.end.y)]
			for other in rectangles:
				var neighbor:float=[other.end.y,other.position.x,other.position.y,other.end.x][side]
				if absf(neighbor-line)>.00001: continue
				var cut:=Vector2(other.position.x,other.end.x) if horizontal else Vector2(other.position.y,other.end.y)
				var remaining:Array[Vector2]=[]
				for span in spans:
					var low:=maxf(span.x,cut.x);var high:=minf(span.y,cut.y)
					if high-low<=.00001:
						remaining.append(span)
						continue
					if low-span.x>.00001: remaining.append(Vector2(span.x,low))
					if span.y-high>.00001: remaining.append(Vector2(high,span.y))
				spans=remaining
				if spans.is_empty(): break
			for span in spans:
				var a:=Vector2(span.x,line) if horizontal else Vector2(line,span.x)
				var b:=Vector2(span.y,line) if horizontal else Vector2(line,span.y)
				result.append(PackedVector2Array([a,b] if side<2 else [b,a]))
	return result

static func foundation(rectangles:Array[Rect2],height:float,depth:float)->ArrayMesh:
	var mesh:=SurfaceTool.new();mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for edge in boundary_edges(rectangles):
		var a:=Vector3(edge[0].x,height,edge[0].y)
		var b:=Vector3(edge[1].x,height,edge[1].y)
		var c:=b-Vector3.UP*depth;var d:=a-Vector3.UP*depth
		var normal:Vector3=(b-a).cross(c-a).normalized()
		for point in [a,c,b,a,d,c]:
			mesh.set_normal(normal);mesh.add_vertex(point)
	return mesh.commit()
