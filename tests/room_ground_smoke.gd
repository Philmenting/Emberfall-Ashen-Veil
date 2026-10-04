extends SceneTree
## Real walkable rooms remain supported, while basins and the outside stay open.
const Ground=preload("res://scripts/room_ground.gd")
const Layout=preload("res://scripts/dungeon_layout.gd")
var checks:=0
var failures:=0
func check(value:bool,description:String)->void:
	checks+=1
	if not value: failures+=1; push_error("FAIL: "+description)
func _contains(rectangles:Array[Rect2],point:Vector2)->bool:
	for rectangle in rectangles:
		if rectangle.has_point(point): return true
	return false
func _initialize()->void:
	var joined:Array[Rect2]=[Rect2(0,0,8,6),Rect2(4,2,8,6)]
	var cuts:Array=[Rect2(5,3,2,2)]
	var pieces:=Ground.cover(joined,cuts)
	var area:=0.0;var overlaps:=0;var holes:=0
	for index in pieces.size():
		area+=pieces[index].get_area()
		for other in range(index+1,pieces.size()):
			if pieces[index].intersects(pieces[other]): overlaps+=1
		if pieces[index].intersects(cuts[0]): holes+=1
	check(is_equal_approx(area,76.0) and overlaps==0,"overlapping rooms have exactly one supported surface without z-fighting")
	check(holes==0 and not _contains(pieces,Vector2(6,4)),"basin removes the full stone surface above its opening")
	check(not _contains(pieces,Vector2(2,7)) and not _contains(pieces,Vector2(10,1)),"outside corners remain open rather than filling a rectangular landscape")
	var perimeter:=0.0;var hole_perimeter:=0.0;var exposed:=true
	for edge in Ground.boundary_edges(pieces):
		var direction:Vector2=(edge[1]-edge[0]).normalized()
		var outward:=Vector2(direction.y,-direction.x)
		var midpoint:Vector2=(edge[0]+edge[1])*.5
		var length:float=edge[0].distance_to(edge[1])
		perimeter+=length
		exposed=exposed and _contains(pieces,midpoint-outward*.001) and not _contains(pieces,midpoint+outward*.001)
		if cuts[0].has_point(midpoint+outward*.001): hole_perimeter+=length
	check(exposed and is_equal_approx(perimeter,48.0),"partial shared edges and T-junctions have no internal foundation faces")
	check(is_equal_approx(hole_perimeter,8.0),"the basin retains its complete inward-facing stone boundary")
	for region in range(4):
		for seed_value in [1979,1042,7351]:
			var walkable:Array=Layout.floor_rects(region,seed_value,seed_value+17,true,true,true)
			var support:Array[Rect2]=[]
			for rectangle:Rect2 in walkable: support.append(rectangle.grow(.72))
			var result:=Ground.cover(support)
			var supported:=true;var unique:=true
			for rectangle:Rect2 in walkable:
				for x in [rectangle.position.x,rectangle.get_center().x,rectangle.end.x]:
					for y in [rectangle.position.y,rectangle.get_center().y,rectangle.end.y]:
						supported=supported and _contains(result,Vector2(x,y))
			for index in result.size():
				for other in range(index+1,result.size()):
					if result[index].intersects(result[other]):
						var overlap:=result[index].intersection(result[other])
						# Rect2 subtraction can leave shared-edge roundoff below 1e-5 m.
						if minf(overlap.size.x,overlap.size.y)>.00001: unique=false
			check(supported and unique,"region %d seed %d: rooms and every route junction remain supported without coplanar overlap" % [region,seed_value])
	for mesh in [Ground.surface(pieces,-.02),Ground.foundation(pieces,-.02,.86)]:
		var arrays:Array=mesh.surface_get_arrays(0)
		var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		var valid:=true
		for index in range(0,vertices.size(),3):
			var front:=-(vertices[index+1]-vertices[index]).cross(vertices[index+2]-vertices[index]).normalized()
			valid=valid and front.is_finite() and front.dot(normals[index])>.99
		check(valid,"court and cut-edge foundation use outward normals with Godot front-face winding")
	print("ROOM GROUND SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
