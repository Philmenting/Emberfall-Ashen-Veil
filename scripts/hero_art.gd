extends Control

const INK := Color("11151b")
const DEEP := Color("1b2028")
const STEEL := Color("52606a")
const PALE := Color("d6d1c7")
const GOLD := Color("c59b5a")
const EMBER := Color("b64b3f")
var character_class := "Vowkeeper"

func _draw() -> void:
	var w := size.x
	var h := size.y
	var cx := w * 0.52
	# A bruised-red moon and a broken skyline establish an original dark-fantasy world.
	draw_circle(Vector2(cx, h * 0.29), min(w, h) * 0.25, Color(0.34, 0.15, 0.14, 0.34))
	draw_circle(Vector2(cx, h * 0.29), min(w, h) * 0.195, Color(0.70, 0.37, 0.25, 0.23))
	draw_circle(Vector2(cx, h * 0.29), min(w, h) * 0.15, Color(0.88, 0.62, 0.43, 0.24))

	var distant := PackedVector2Array([
		Vector2(0, h * 0.73), Vector2(w * 0.08, h * 0.58), Vector2(w * 0.19, h * 0.66),
		Vector2(w * 0.31, h * 0.52), Vector2(w * 0.43, h * 0.68), Vector2(w * 0.58, h * 0.55),
		Vector2(w * 0.72, h * 0.67), Vector2(w * 0.87, h * 0.54), Vector2(w, h * 0.65),
		Vector2(w, h), Vector2(0, h)
	])
	draw_colored_polygon(distant, Color("22252b"))
	# Spires of the Hollow keep the horizon readable behind the character.
	for spire in [Vector2(w * 0.14, h * 0.43), Vector2(w * 0.84, h * 0.39), Vector2(w * 0.74, h * 0.50)]:
		var base: float = float(spire.y) + h * 0.30
		draw_rect(Rect2(spire.x - w * 0.022, spire.y, w * 0.044, base - spire.y), Color("171b21"))
		draw_colored_polygon(PackedVector2Array([spire + Vector2(-w * 0.045, h * 0.055), spire + Vector2(0, -h * 0.045), spire + Vector2(w * 0.045, h * 0.055)]), Color("171b21"))
		draw_rect(Rect2(spire.x - w * 0.008, spire.y + h * 0.10, w * 0.016, h * 0.018), Color(0.78, 0.38, 0.22, 0.75))

	# Nyra's mantle.
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - w * 0.11, h * 0.48), Vector2(cx + w * 0.13, h * 0.47),
		Vector2(cx + w * 0.25, h * 0.94), Vector2(cx + w * 0.06, h * 0.85),
		Vector2(cx - w * 0.02, h * 0.95), Vector2(cx - w * 0.20, h * 0.88),
		Vector2(cx - w * 0.27, h * 0.97)
	]), Color("171c23"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - w * 0.11, h * 0.49), Vector2(cx + w * 0.06, h * 0.51),
		Vector2(cx - w * 0.01, h * 0.87), Vector2(cx - w * 0.19, h * 0.91)
	]), Color("29313a"))
	# Armor plates and a small ember sigil.
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - w * 0.105, h * 0.48), Vector2(cx + w * 0.10, h * 0.47),
		Vector2(cx + w * 0.17, h * 0.72), Vector2(cx + w * 0.015, h * 0.81),
		Vector2(cx - w * 0.13, h * 0.68)
	]), Color("41474d"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - w * 0.14, h * 0.49), Vector2(cx + w * 0.005, h * 0.47),
		Vector2(cx - w * 0.01, h * 0.65), Vector2(cx - w * 0.10, h * 0.69),
		Vector2(cx - w * 0.19, h * 0.59)
	]), Color("697079"))
	draw_line(Vector2(cx - w * 0.13, h * 0.52), Vector2(cx + w * 0.09, h * 0.72), Color("aa8351"), maxf(1.0, w * 0.009), true)
	draw_circle(Vector2(cx - w * 0.035, h * 0.62), w * 0.023, EMBER)
	draw_circle(Vector2(cx - w * 0.035, h * 0.62), w * 0.011, Color("eeb36e"))

	# Hood, face, and a crown of pale ash-colored hair.
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - w * 0.14, h * 0.30), Vector2(cx - w * 0.11, h * 0.18),
		Vector2(cx - w * 0.035, h * 0.12), Vector2(cx + w * 0.08, h * 0.16),
		Vector2(cx + w * 0.15, h * 0.29), Vector2(cx + w * 0.10, h * 0.47),
		Vector2(cx - w * 0.11, h * 0.47)
	]), Color("252b32"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - w * 0.075, h * 0.24), Vector2(cx + w * 0.07, h * 0.22),
		Vector2(cx + w * 0.09, h * 0.37), Vector2(cx + w * 0.025, h * 0.43),
		Vector2(cx - w * 0.06, h * 0.39)
	]), Color("b68c71"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - w * 0.16, h * 0.27), Vector2(cx - w * 0.13, h * 0.15),
		Vector2(cx - w * 0.045, h * 0.12), Vector2(cx - w * 0.005, h * 0.20),
		Vector2(cx - w * 0.08, h * 0.25), Vector2(cx - w * 0.10, h * 0.42)
	]), PALE)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx + w * 0.10, h * 0.20), Vector2(cx + w * 0.15, h * 0.17),
		Vector2(cx + w * 0.14, h * 0.33), Vector2(cx + w * 0.105, h * 0.42),
		Vector2(cx + w * 0.065, h * 0.37)
	]), Color("a8a9a6"))
	draw_line(Vector2(cx - w * 0.025, h * 0.31), Vector2(cx + w * 0.055, h * 0.31), Color("382d2a"), maxf(1.5, w * 0.009), true)
	draw_circle(Vector2(cx + w * 0.055, h * 0.315), w * 0.009, Color("e3aa61"))

	match character_class:
		"Arcanist":
			draw_line(Vector2(cx + w * 0.18, h * 0.81), Vector2(cx + w * 0.28, h * 0.15), Color("8e6844"), w * 0.018, true)
			draw_circle(Vector2(cx + w * 0.28, h * 0.15), w * 0.045, Color("9b77c7"))
			draw_circle(Vector2(cx + w * 0.28, h * 0.15), w * 0.021, Color("e4d8f3"))
		"Ranger":
			draw_arc(Vector2(cx + w * 0.22, h * 0.52), h * 0.18, -1.26, 1.26, 20, Color("bd915d"), w * 0.012, true)
			draw_line(Vector2(cx + w * 0.22, h * 0.34), Vector2(cx + w * 0.22, h * 0.70), PALE, w * 0.005, true)
		_:
			draw_line(Vector2(cx + w * 0.20, h * 0.79), Vector2(cx + w * 0.31, h * 0.22), Color("15191e"), w * 0.04, true)
			draw_line(Vector2(cx + w * 0.20, h * 0.79), Vector2(cx + w * 0.31, h * 0.22), Color("bac0bf"), w * 0.012, true)
			draw_line(Vector2(cx + w * 0.14, h * 0.64), Vector2(cx + w * 0.26, h * 0.66), GOLD, w * 0.018, true)
			draw_line(Vector2(cx + w * 0.20, h * 0.78), Vector2(cx + w * 0.18, h * 0.89), Color("8e653c"), w * 0.025, true)

	# Floating cinders.
	for point in [Vector2(w * 0.18, h * 0.31), Vector2(w * 0.76, h * 0.27), Vector2(w * 0.27, h * 0.73), Vector2(w * 0.83, h * 0.74)]:
		draw_circle(point, maxf(1.2, w * 0.006), Color(0.96, 0.53, 0.27, 0.72))
