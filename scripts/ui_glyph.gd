extends Control
## Small, authored line glyphs; the same stroke language in camp and combat.
var key := "portal"
var ink := Color("d9b578")
var stroke := 1.7

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(24, 24)

func _draw() -> void:
	var scale_factor := minf(size.x, size.y) / 24.0
	var origin := (size - Vector2.ONE * 24.0 * scale_factor) * 0.5
	draw_set_transform(origin, 0.0, Vector2.ONE * scale_factor)
	match key:
		"pause":
			draw_rect(Rect2(7, 5, 3, 14), ink)
			draw_rect(Rect2(14, 5, 3, 14), ink)
		"play":
			draw_colored_polygon(PackedVector2Array([Vector2(8, 5), Vector2(19, 12), Vector2(8, 19)]), ink)
		"repeat", "auto":
			draw_arc(Vector2(12, 12), 7.5, 0.2, 2.8, 20, ink, stroke, true)
			draw_arc(Vector2(12, 12), 7.5, 3.4, 6.0, 20, ink, stroke, true)
			_line([Vector2(18, 3), Vector2(20, 7), Vector2(15, 7)])
			_line([Vector2(6, 21), Vector2(4, 17), Vector2(9, 17)])
		"loot", "bag":
			_line([Vector2(4, 10), Vector2(20, 10), Vector2(20, 20), Vector2(4, 20), Vector2(4, 10), Vector2(7, 5), Vector2(17, 5), Vector2(20, 10)])
			draw_rect(Rect2(10, 9, 4, 5), ink, false, stroke)
		"forge":
			_line([Vector2(4, 7), Vector2(20, 7), Vector2(17, 11), Vector2(8, 11), Vector2(7, 15), Vector2(17, 15)])
			_line([Vector2(11, 15), Vector2(11, 19), Vector2(7, 21), Vector2(19, 21)])
		"hero":
			draw_arc(Vector2(12, 7), 3.0, 0, TAU, 18, ink, stroke, true)
			_line([Vector2(5, 21), Vector2(6, 16), Vector2(9, 13), Vector2(15, 13), Vector2(18, 16), Vector2(19, 21)])
		"seals":
			_line([Vector2(12, 2), Vector2(20, 6), Vector2(19, 16), Vector2(12, 22), Vector2(5, 16), Vector2(4, 6), Vector2(12, 2)])
			_line([Vector2(8, 12), Vector2(11, 15), Vector2(17, 9)])
		"map", "table":
			_line([Vector2(3, 5), Vector2(9, 3), Vector2(15, 5), Vector2(21, 3), Vector2(21, 19), Vector2(15, 21), Vector2(9, 19), Vector2(3, 21), Vector2(3, 5)])
			draw_line(Vector2(9, 3), Vector2(9, 19), ink, stroke, true)
			draw_line(Vector2(15, 5), Vector2(15, 21), ink, stroke, true)
		"back":
			_line([Vector2(14, 5), Vector2(7, 12), Vector2(14, 19)])
			draw_line(Vector2(7, 12), Vector2(21, 12), ink, stroke, true)
		"settings":
			for y in [6, 12, 18]: draw_line(Vector2(3, y), Vector2(21, y), ink, stroke, true)
			for point in [Vector2(8, 6), Vector2(16, 12), Vector2(10, 18)]: draw_circle(point, 2.5, ink)
		"camp":
			_line([Vector2(2, 19), Vector2(12, 4), Vector2(22, 19), Vector2(2, 19)])
			_line([Vector2(8, 19), Vector2(12, 12), Vector2(16, 19)])
		"weapon":
			_line([Vector2(6, 19), Vector2(18, 7), Vector2(20, 3), Vector2(16, 5), Vector2(4, 17)])
			draw_line(Vector2(5, 12),Vector2(12,19),ink,stroke,true)
			draw_line(Vector2(3,21),Vector2(7,17),ink,stroke+0.7,true)
		"helmet":
			_line([Vector2(5, 18),Vector2(5, 8),Vector2(8, 3),Vector2(16, 3),Vector2(19, 8),Vector2(19, 18),Vector2(14, 21),Vector2(10, 21),Vector2(5, 18)])
			draw_line(Vector2(7,11),Vector2(10,11),ink,stroke,true)
			draw_line(Vector2(14,11),Vector2(17,11),ink,stroke,true)
		"chest":
			_line([Vector2(3, 4),Vector2(8, 3),Vector2(10, 6),Vector2(14, 6),Vector2(16, 3),Vector2(21, 4),Vector2(18, 10),Vector2(18, 20),Vector2(6, 20),Vector2(6, 10),Vector2(3, 4)])
			draw_line(Vector2(12,7),Vector2(12,18),ink,stroke,true)
		"gloves":
			_line([Vector2(5, 20),Vector2(4, 13),Vector2(7, 5),Vector2(9, 5),Vector2(9, 12),Vector2(11, 3),Vector2(13, 3),Vector2(14, 12),Vector2(16, 8),Vector2(19, 10),Vector2(18, 16),Vector2(14, 21),Vector2(5, 20)])
		"boots":
			_line([Vector2(7, 3),Vector2(16, 3),Vector2(15, 14),Vector2(21, 17),Vector2(21, 21),Vector2(5, 21),Vector2(5, 15),Vector2(7, 3)])
			draw_line(Vector2(7,8),Vector2(15,8),ink,stroke,true)
		"amulet":
			draw_arc(Vector2(12,9),7.0,PI,TAU,24,ink,stroke,true)
			_line([Vector2(5,9),Vector2(9,14),Vector2(15,14),Vector2(19,9)])
			_line([Vector2(12,12),Vector2(17,17),Vector2(12,22),Vector2(7,17),Vector2(12,12)])
		_:
			_line([Vector2(5, 21), Vector2(5, 10), Vector2(8, 4), Vector2(16, 4), Vector2(19, 10), Vector2(19, 21)])
			draw_arc(Vector2(12, 12), 4, 0, TAU, 20, ink, stroke, true)
	draw_set_transform(Vector2.ZERO)

func _line(points: Array) -> void:
	draw_polyline(PackedVector2Array(points), ink, stroke, true)
