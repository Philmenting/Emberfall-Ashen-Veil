extends Control

var character_class := "Vowkeeper"
var enemy_name := "Hollow Stalker"
var encounter := 1
var region_index := 0
var elapsed := 0.0

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 2.0 or h <= 2.0:
		return
	var floor_y := h * 0.84
	var sky_top: Color = [Color("312a2c"), Color("1e3039"), Color("2b2637"), Color("3b2725")][clampi(region_index, 0, 3)]
	var sky_bottom: Color = [Color("151a20"), Color("111d24"), Color("171620"), Color("211514")][clampi(region_index, 0, 3)]
	var region_glow: Color = [Color("ad5340"), Color("3f9b9f"), Color("8c66ae"), Color("e07a39")][clampi(region_index, 0, 3)]
	for i in range(16):
		var y0 := h * float(i) / 16.0
		var y1 := h * float(i + 1) / 16.0 + 1.0
		draw_rect(Rect2(0, y0, w, y1 - y0), sky_top.lerp(sky_bottom, float(i) / 16.0))
	# Moonlight, distant ridges, and the broken bell tower.
	draw_circle(Vector2(w * 0.77, h * 0.28), h * 0.17, Color(region_glow.r, region_glow.g, region_glow.b, 0.25))
	draw_circle(Vector2(w * 0.77, h * 0.28), h * 0.115, Color(region_glow.r, region_glow.g, region_glow.b, 0.42))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, floor_y), Vector2(w * 0.10, h * 0.46), Vector2(w * 0.22, h * 0.62),
		Vector2(w * 0.34, h * 0.40), Vector2(w * 0.48, h * 0.62), Vector2(w * 0.65, h * 0.43),
		Vector2(w * 0.80, h * 0.64), Vector2(w * 0.93, h * 0.45), Vector2(w, h * 0.57),
		Vector2(w, h), Vector2(0, h)
	]), Color("20242a"))
	for tower_x in [w * 0.12, w * 0.88]:
		draw_rect(Rect2(tower_x, h * 0.24, w * 0.035, h * 0.48), Color("171a1f"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(tower_x - w * 0.022, h * 0.27), Vector2(tower_x + w * 0.017, h * 0.10), Vector2(tower_x + w * 0.055, h * 0.27)
		]), Color("171a1f"))
		draw_rect(Rect2(tower_x + w * 0.010, h * 0.42, w * 0.009, h * 0.045), Color(0.89, 0.47, 0.27, 0.55))
	draw_rect(Rect2(0, floor_y, w, h - floor_y), Color("11161b"))
	draw_line(Vector2(0, floor_y), Vector2(w, floor_y), Color("79614c"), 1.0, true)
	for i in range(10):
		var x := fmod(float(i * 71 + 22), w)
		draw_line(Vector2(x, floor_y + 3.0), Vector2(x - w * 0.03, h), Color(0.53, 0.40, 0.31, 0.13), 1.0, true)

	var hx := w * 0.32
	var bob := sin(elapsed * 2.2) * h * 0.012
	var head_y := h * 0.36 + bob
	# Nyra's ash mantle and plated torso.
	draw_colored_polygon(PackedVector2Array([
		Vector2(hx - w * 0.075, h * 0.49 + bob), Vector2(hx + w * 0.07, h * 0.48 + bob),
		Vector2(hx + w * 0.12, floor_y), Vector2(hx + w * 0.035, h * 0.78),
		Vector2(hx - w * 0.045, floor_y), Vector2(hx - w * 0.15, h * 0.91)
	]), Color("20262e"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(hx - w * 0.060, h * 0.46 + bob), Vector2(hx + w * 0.055, h * 0.46 + bob),
		Vector2(hx + w * 0.085, h * 0.68), Vector2(hx, h * 0.76), Vector2(hx - w * 0.095, h * 0.65)
	]), Color("58616a"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(hx - w * 0.11, h * 0.48 + bob), Vector2(hx - w * 0.045, h * 0.45 + bob),
		Vector2(hx - w * 0.025, h * 0.63), Vector2(hx - w * 0.095, h * 0.67), Vector2(hx - w * 0.15, h * 0.58)
	]), Color("777d82"))
	draw_circle(Vector2(hx, head_y), h * 0.105, Color("262b32"))
	draw_circle(Vector2(hx, head_y + h * 0.018), h * 0.062, Color("b58c72"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(hx - w * 0.075, head_y + h * 0.02), Vector2(hx - w * 0.055, head_y - h * 0.085),
		Vector2(hx + w * 0.005, head_y - h * 0.105), Vector2(hx + w * 0.055, head_y - h * 0.050),
		Vector2(hx + w * 0.04, head_y - h * 0.005), Vector2(hx - w * 0.015, head_y - h * 0.038)
	]), Color("d5d0c5"))
	draw_circle(Vector2(hx + w * 0.027, head_y + h * 0.01), h * 0.009, Color("e6b96e"))
	draw_circle(Vector2(hx - w * 0.035, h * 0.59), h * 0.018, Color("bd7c52"))

	# Class weapons are readable silhouettes: sword, staff, or bow.
	match character_class:
		"Arcanist":
			draw_line(Vector2(hx + w * 0.11, h * 0.72), Vector2(hx + w * 0.18, h * 0.18), Color("8e6844"), 3.0, true)
			draw_circle(Vector2(hx + w * 0.18, h * 0.18), h * 0.05, Color(0.62, 0.42, 0.88, 0.82 + sin(elapsed * 4.0) * 0.12))
			draw_circle(Vector2(hx + w * 0.18, h * 0.18), h * 0.022, Color("e5d7f5"))
			_draw_attack(hx + w * 0.21, h * 0.43, w * 0.31)
		"Ranger":
			draw_arc(Vector2(hx + w * 0.17, h * 0.49), h * 0.19, -1.28, 1.28, 20, Color("b88a58"), 2.4, true)
			draw_line(Vector2(hx + w * 0.17, h * 0.30), Vector2(hx + w * 0.17, h * 0.68), Color("e0d4bc"), 1.0, true)
			_draw_attack(hx + w * 0.22, h * 0.48, w * 0.31)
		_:
			draw_line(Vector2(hx + w * 0.16, h * 0.78), Vector2(hx + w * 0.22, h * 0.17), Color("1a1e23"), 5.0, true)
			draw_line(Vector2(hx + w * 0.16, h * 0.78), Vector2(hx + w * 0.22, h * 0.17), Color("c9c9c3"), 1.8, true)
			draw_line(Vector2(hx + w * 0.13, h * 0.62), Vector2(hx + w * 0.24, h * 0.64), Color("d2ad70"), 2.4, true)
			_draw_attack(hx + w * 0.24, h * 0.48, w * 0.29)

	# Enemy silhouettes change for the final Bell Warden encounter.
	var ex := w * 0.72
	var pulse := 0.70 + (sin(elapsed * 3.1) + 1.0) * 0.10
	var is_boss := ["The Bell Warden", "The Silt Abbot", "The Mourning Queen", "The Cinder Sovereign"].has(enemy_name)
	var boss_metal := Color("a4774c")
	var boss_eye := Color(1.0, 0.40, 0.17, pulse)
	match enemy_name:
		"The Silt Abbot":
			boss_metal = Color("4c969a")
			boss_eye = Color(0.34, 0.92, 0.88, pulse)
		"The Mourning Queen":
			boss_metal = Color("8870a6")
			boss_eye = Color(0.82, 0.49, 1.0, pulse)
		"The Cinder Sovereign":
			boss_metal = Color("ba5737")
			boss_eye = Color(1.0, 0.72, 0.25, pulse)
	var shadow_points := PackedVector2Array()
	var shadow_width := w * (0.145 if is_boss else 0.095)
	for i in range(20):
		var angle := TAU * float(i) / 20.0
		shadow_points.append(Vector2(ex + cos(angle) * shadow_width, floor_y + h * 0.008 + sin(angle) * h * (0.032 if is_boss else 0.025)))
	draw_colored_polygon(shadow_points, Color(0.78, 0.28, 0.20, 0.28 if is_boss else 0.22))
	if is_boss:
		# Towering armor, a cracked bronze bell, and a horned crown make the boss legible at mobile scale.
		draw_colored_polygon(PackedVector2Array([
			Vector2(ex - w * 0.15, floor_y), Vector2(ex - w * 0.14, h * 0.52), Vector2(ex - w * 0.19, h * 0.37),
			Vector2(ex - w * 0.13, h * 0.28), Vector2(ex - w * 0.09, h * 0.20), Vector2(ex + w * 0.10, h * 0.20),
			Vector2(ex + w * 0.16, h * 0.34), Vector2(ex + w * 0.20, h * 0.50), Vector2(ex + w * 0.13, floor_y)
		]), Color("272b31"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(ex - w * 0.14, h * 0.42), Vector2(ex - w * 0.075, h * 0.36), Vector2(ex + w * 0.08, h * 0.36),
			Vector2(ex + w * 0.15, h * 0.44), Vector2(ex + w * 0.10, h * 0.57), Vector2(ex - w * 0.10, h * 0.57)
		]), Color("61534a"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(ex - w * 0.095, h * 0.39), Vector2(ex - w * 0.07, h * 0.51), Vector2(ex - w * 0.035, h * 0.57),
			Vector2(ex + w * 0.035, h * 0.57), Vector2(ex + w * 0.075, h * 0.51), Vector2(ex + w * 0.09, h * 0.39),
			Vector2(ex + w * 0.035, h * 0.35), Vector2(ex - w * 0.045, h * 0.35)
		]), boss_metal)
		draw_arc(Vector2(ex, h * 0.30), h * 0.14, PI * 1.08, PI * 1.92, 28, boss_metal.lightened(0.35), 2.0, true)
		draw_circle(Vector2(ex, h * 0.26), h * 0.072, Color("17191e"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(ex - w * 0.082, h * 0.25), Vector2(ex - w * 0.12, h * 0.085), Vector2(ex - w * 0.025, h * 0.20),
			Vector2(ex + w * 0.025, h * 0.20), Vector2(ex + w * 0.12, h * 0.085), Vector2(ex + w * 0.082, h * 0.25)
		]), Color("877461"))
		draw_circle(Vector2(ex - w * 0.038, h * 0.275), h * 0.012, boss_eye)
		draw_circle(Vector2(ex + w * 0.038, h * 0.275), h * 0.012, boss_eye)
		draw_line(Vector2(ex, h * 0.44), Vector2(ex + w * 0.015, h * 0.54), Color("32261f"), 2.4, true)
	else:
		draw_colored_polygon(PackedVector2Array([
			Vector2(ex - w * 0.095, floor_y), Vector2(ex - w * 0.06, h * 0.53), Vector2(ex - w * 0.11, h * 0.43),
			Vector2(ex - w * 0.07, h * 0.31), Vector2(ex, h * 0.25), Vector2(ex + w * 0.075, h * 0.32),
			Vector2(ex + w * 0.12, h * 0.47), Vector2(ex + w * 0.05, h * 0.60), Vector2(ex + w * 0.10, floor_y)
		]), Color("333139"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(ex - w * 0.06, h * 0.35), Vector2(ex, h * 0.29), Vector2(ex + w * 0.06, h * 0.36),
			Vector2(ex + w * 0.045, h * 0.48), Vector2(ex, h * 0.53), Vector2(ex - w * 0.05, h * 0.47)
		]), Color("908579"))
		draw_line(Vector2(ex - w * 0.04, h * 0.39), Vector2(ex - w * 0.01, h * 0.41), Color(1.0, 0.43, 0.22, pulse), 2.2, true)
		draw_line(Vector2(ex + w * 0.01, h * 0.41), Vector2(ex + w * 0.04, h * 0.39), Color(1.0, 0.43, 0.22, pulse), 2.2, true)
		draw_line(Vector2(ex - w * 0.065, h * 0.36), Vector2(ex - w * 0.10, h * 0.24), Color("8b7770"), 2.2, true)
		draw_line(Vector2(ex + w * 0.065, h * 0.36), Vector2(ex + w * 0.10, h * 0.24), Color("8b7770"), 2.2, true)
	for i in range(9):
		var ember_x := fmod(float(i * 47 + encounter * 19), w)
		var ember_y := h * (0.23 + fmod(float(i * 23 + encounter * 7), 52.0) / 100.0)
		draw_circle(Vector2(ember_x, ember_y), 1.3, Color(1.0, 0.48, 0.25, 0.6))

func _draw_attack(start_x: float, y: float, distance: float) -> void:
	var flicker := 0.72 + (sin(elapsed * 5.0) + 1.0) * 0.10
	var attack_color := Color("e5ad70") if character_class == "Ranger" else Color("f09255")
	if character_class == "Arcanist":
		attack_color = Color("be8ee9")
	var end := Vector2(start_x + distance, y + sin(elapsed * 3.0) * size.y * 0.025)
	draw_line(Vector2(start_x, y), end, Color(attack_color.r, attack_color.g, attack_color.b, 0.18), 12.0, true)
	draw_line(Vector2(start_x, y), end, Color(attack_color.r, attack_color.g, attack_color.b, flicker), 3.0, true)
	draw_circle(end, 4.0 + sin(elapsed * 5.0) * 1.0, attack_color.lightened(0.5))
