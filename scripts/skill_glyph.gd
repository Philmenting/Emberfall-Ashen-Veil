extends Control
const Skills=preload("res://scripts/class_skills.gd")
var ability_id := "bastion"

func _ready() -> void:
	custom_minimum_size=Vector2(36,36)
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var data: Dictionary=Skills.DEFINITIONS[ability_id]
	var color := Color(data.color)
	draw_circle(Vector2(18,18),16,Color("101820"))
	draw_arc(Vector2(18,18),16,0,TAU,32,color.darkened(0.35),1.2,true)
	if data.kind=="guard":
		var shield:=PackedVector2Array([Vector2(18,7),Vector2(28,11),Vector2(26,22),Vector2(18,29),Vector2(10,22),Vector2(8,11),Vector2(18,7)])
		draw_polyline(shield,color,2,true)
		draw_line(Vector2(18,12),Vector2(18,23),color,2,true)
	elif ability_id=="chain":
		draw_polyline(PackedVector2Array([Vector2(24,7),Vector2(12,19),Vector2(23,17),Vector2(12,29)]),color,3,true)
	elif ability_id in ["rain","marked"]:
		for i in range(3 if ability_id=="rain" else 1):
			var x:=12.0+i*6 if ability_id=="rain" else 18.0
			draw_line(Vector2(x,8),Vector2(x,27),color,2,true)
			draw_polyline(PackedVector2Array([Vector2(x-3,22),Vector2(x,27),Vector2(x+3,22)]),color,2,true)
	elif ability_id=="starfall":
		var star:=PackedVector2Array()
		for i in range(11):
			var angle:=TAU*i/10.0-PI/2
			star.append(Vector2(18,18)+Vector2.from_angle(angle)*(11 if i%2==0 else 4))
		draw_polyline(star,color,2,true)
	else:
		draw_line(Vector2(10,27),Vector2(26,9),color,3,true)
		draw_line(Vector2(10,19),Vector2(18,26),color,2,true)
		if ability_id=="sunder": draw_arc(Vector2(18,18),11,-1.3,1.3,16,color,2,true)
