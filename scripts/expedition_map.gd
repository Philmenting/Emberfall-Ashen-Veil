extends Control
const Layout = preload("res://scripts/dungeon_layout.gd")
var simulation: RefCounted

func _ready() -> void:
	custom_minimum_size=Vector2(190,84)
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	queue_redraw()

func project(point: Vector2) -> Vector2:
	# The descending journey reads left to right; world north is map right.
	return Vector2(9+(8-point.y)/84.0*(size.x-18),size.y*0.5+point.x*2.0)

func _draw() -> void:
	if simulation==null or not simulation.uses_journey(): return
	var region_id := Layout.region(simulation.floor_id)
	for room in range(6):
		var visited: bool=room<=simulation.stage
		var color := Color("b29a70") if visited else Color("46505b")
		if room>0:
			var path := PackedVector2Array()
			for point in Layout.travel_points(region_id,room,0): path.append(project(point))
			draw_polyline(path,color,2.0,true)
		var location := project(Layout.center(region_id,room))
		draw_rect(Rect2(location-Vector2(8,10),Vector2(16,20)),Color("111b25"))
		draw_rect(Rect2(location-Vector2(8,10),Vector2(16,20)),color,false,1.0)
		if room in [1,3,5]:
			var done: bool=simulation.journey[{1:"well_used",3:"seal_broken",5:"chest_open"}[room]]
			draw_circle(location,2.5,Color("82c8bd") if done else Color("d7b87c"))
	draw_circle(project(simulation.hero_pos),4.0,Color("f8f2d9"))
	draw_circle(project(simulation.hero_pos),6.0,Color("b29a70"),false,1.0,true)
