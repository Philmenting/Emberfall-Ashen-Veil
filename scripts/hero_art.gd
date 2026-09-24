extends Control

const NYRA_PORTRAIT: Texture2D = preload("res://assets/nyra_portrait.webp")

var character_class := "Vowkeeper"

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 2.0 or h <= 2.0:
		return
	var texture_size := NYRA_PORTRAIT.get_size()
	var source_position := Vector2.ZERO
	var source_size := Vector2(float(texture_size.x), float(texture_size.y))
	var image_aspect := float(texture_size.x) / float(texture_size.y)
	var viewport_aspect := w / h
	if image_aspect > viewport_aspect:
		source_size.x = float(texture_size.y) * viewport_aspect
		source_position.x = (float(texture_size.x) - source_size.x) * 0.5
	else:
		source_size.y = float(texture_size.x) / viewport_aspect
		source_position.y = (float(texture_size.y) - source_size.y) * 0.32
	var tint := Color.WHITE
	if character_class == "Arcanist":
		tint = Color(0.94, 0.91, 1.0, 1.0)
	elif character_class == "Ranger":
		tint = Color(0.92, 1.0, 0.92, 1.0)
	draw_texture_rect_region(NYRA_PORTRAIT, Rect2(Vector2.ZERO, Vector2(w, h)), Rect2(source_position, source_size), tint)
	for i in range(5):
		var ember_x := fposmod(float(i * 71 + 29), w)
		var ember_y := fposmod(float(i * 97 + 41), h)
		draw_circle(Vector2(ember_x, ember_y), 1.1, Color(1.0, 0.48, 0.23, 0.36))
