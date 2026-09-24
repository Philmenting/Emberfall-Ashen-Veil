extends Control

const CRYPT_BACKGROUND: Texture2D = preload("res://assets/hollow_spire_corridor.webp")
const NYRA_SPRITE: Texture2D = preload("res://assets/nyra_runner.webp")
const CINDER_KNIGHT_SPRITE: Texture2D = preload("res://assets/cinder_knight.webp")

var character_class := "Vowkeeper"
var enemy_name := "Hollow Stalker"
var encounter := 1
var region_index := 0
var elapsed := 0.0
var animation_enabled := true

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	if not animation_enabled:
		return
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 2.0 or h <= 2.0:
		return

	_draw_crypt_background(w, h)
	var glow_color: Color = [Color("ef8249"), Color("55b6b8"), Color("9b79cf"), Color("ef713a")][clampi(region_index, 0, 3)]
	var is_boss := ["The Bell Warden", "The Silt Abbot", "The Mourning Queen", "The Cinder Sovereign"].has(enemy_name)
	var encounter_pulse := 0.5 + 0.5 * sin(elapsed * 2.4)

	# A low fog band and ember motes keep the hallway alive while Nyra advances.
	draw_rect(Rect2(0.0, h * 0.72, w, h * 0.28), Color(0.025, 0.032, 0.045, 0.26))
	for i in range(14):
		var ember_x := fposmod(float(i * 167 + encounter * 41) + elapsed * (8.0 + float(i % 4) * 2.2), w)
		var ember_y := h * (0.18 + fposmod(float(i * 61), 57.0) / 100.0)
		var ember_alpha := 0.24 + 0.30 * (0.5 + 0.5 * sin(elapsed * (2.1 + float(i % 3)) + float(i)))
		draw_circle(Vector2(ember_x, ember_y), 1.0 + float(i % 3) * 0.45, Color(1.0, 0.47, 0.22, ember_alpha))

	# The hollow knight waits deeper in the nave; the boss grows larger with distance and threat.
	var enemy_idle := sin(elapsed * 1.7 + 0.6) * h * 0.006
	var enemy_feet := Vector2(w * 0.785, h * 0.825 + enemy_idle)
	var enemy_scale := 1.18 if is_boss else 0.94
	var enemy_height := h * (0.51 if is_boss else 0.45) * enemy_scale
	var enemy_width := enemy_height * float(CINDER_KNIGHT_SPRITE.get_size().x) / float(CINDER_KNIGHT_SPRITE.get_size().y)
	var enemy_rect := Rect2(Vector2(enemy_feet.x - enemy_width * 0.5, enemy_feet.y - enemy_height), Vector2(enemy_width, enemy_height))
	_draw_ground_shadow(Vector2(enemy_feet.x, enemy_feet.y - h * 0.008), enemy_width * 0.36, h * 0.025, 0.48)
	draw_circle(Vector2(enemy_feet.x, enemy_feet.y - enemy_height * 0.58), enemy_height * (0.24 if is_boss else 0.17), Color(glow_color.r, glow_color.g * 0.36, glow_color.b * 0.20, 0.09 + encounter_pulse * 0.04))
	var enemy_tint := Color(1.0, 0.97, 0.93, 1.0)
	if region_index == 1:
		enemy_tint = Color(0.82, 0.96, 1.0, 1.0)
	elif region_index == 2:
		enemy_tint = Color(0.92, 0.87, 1.0, 1.0)
	elif region_index == 3:
		enemy_tint = Color(1.0, 0.88, 0.78, 1.0)
	draw_texture_rect(CINDER_KNIGHT_SPRITE, enemy_rect, false, enemy_tint)

	# Nyra runs from the near end of the causeway toward each enemy, then lunges to strike.
	var run_cycle := fposmod(elapsed + 0.7, 9.0)
	var approach := clampf(run_cycle / 5.2, 0.0, 1.0)
	var eased_approach := approach * approach * (3.0 - 2.0 * approach)
	var strike := 0.0
	if run_cycle > 5.2:
		strike = maxf(0.0, sin((run_cycle - 5.2) * TAU / 1.05))
	var travel_lunge := strike * w * 0.018
	var hero_x := lerpf(w * 0.18, w * 0.565, eased_approach) + travel_lunge
	var hero_bob := sin(elapsed * 12.0) * h * 0.009 if run_cycle < 5.2 else sin(elapsed * 3.2) * h * 0.004
	var hero_feet := Vector2(hero_x, h * lerpf(0.91, 0.825, eased_approach) + hero_bob)
	var hero_height := h * 0.45 * lerpf(1.02, 0.80, eased_approach)
	var hero_width := hero_height * float(NYRA_SPRITE.get_size().x) / float(NYRA_SPRITE.get_size().y)
	var hero_rect := Rect2(Vector2(hero_feet.x - hero_width * 0.5, hero_feet.y - hero_height), Vector2(hero_width, hero_height))
	_draw_ground_shadow(Vector2(hero_feet.x, hero_feet.y - h * 0.008), hero_width * 0.35, h * 0.024, 0.52)
	if run_cycle < 5.2:
		_draw_run_dust(hero_feet, hero_width, h)
	var hero_tint := Color(1.0, 0.985, 0.96, 1.0)
	if character_class == "Arcanist":
		hero_tint = Color(0.96, 0.90, 1.0, 1.0)
	elif character_class == "Ranger":
		hero_tint = Color(0.91, 1.0, 0.91, 1.0)
	draw_texture_rect(NYRA_SPRITE, hero_rect, false, hero_tint)
	if strike > 0.28:
		_draw_sword_arc(hero_feet, hero_width, hero_height, enemy_feet, strike, glow_color)

func _draw_crypt_background(w: float, h: float) -> void:
	var texture_size := CRYPT_BACKGROUND.get_size()
	var image_aspect := float(texture_size.x) / float(texture_size.y)
	var viewport_aspect := w / h
	var source_position := Vector2.ZERO
	var source_size := Vector2(float(texture_size.x), float(texture_size.y))
	if image_aspect > viewport_aspect:
		source_size.x = float(texture_size.y) * viewport_aspect
		source_position.x = (float(texture_size.x) - source_size.x) * 0.5
	else:
		source_size.y = float(texture_size.x) / viewport_aspect
		var camera_shift := 0.50 + 0.30 * sin(elapsed * 0.075)
		source_position.y = maxf(0.0, float(texture_size.y) - source_size.y) * camera_shift
	draw_texture_rect_region(CRYPT_BACKGROUND, Rect2(Vector2.ZERO, Vector2(w, h)), Rect2(source_position, source_size), Color(0.84, 0.87, 0.91, 1.0))
	var region_tint: Color = [Color(0.18, 0.045, 0.025, 0.08), Color(0.015, 0.12, 0.15, 0.10), Color(0.12, 0.04, 0.18, 0.10), Color(0.20, 0.055, 0.01, 0.11)][clampi(region_index, 0, 3)]
	draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)), region_tint)

func _draw_ground_shadow(center: Vector2, radius_x: float, radius_y: float, alpha: float) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var angle := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	draw_colored_polygon(points, Color(0.008, 0.010, 0.015, alpha))

func _draw_run_dust(feet: Vector2, sprite_width: float, h: float) -> void:
	for i in range(7):
		var phase := fposmod(elapsed * 0.54 + float(i) * 0.16, 1.0)
		var dust_position := Vector2(feet.x - sprite_width * 0.24 - phase * sprite_width * 0.20, feet.y - phase * h * 0.055)
		var dust_alpha := (1.0 - phase) * 0.30
		draw_circle(dust_position, 1.5 + phase * 3.2, Color(0.72, 0.64, 0.55, dust_alpha))

func _draw_sword_arc(feet: Vector2, sprite_width: float, sprite_height: float, enemy_feet: Vector2, strength: float, glow: Color) -> void:
	var slash_center := Vector2(feet.x + sprite_width * 0.18, feet.y - sprite_height * 0.59)
	var slash_radius := sprite_width * 0.21
	draw_arc(slash_center, slash_radius, -0.98, 0.82, 20, Color(glow.r, glow.g * 0.52, glow.b * 0.24, 0.25 * strength), 9.0, true)
	draw_arc(slash_center, slash_radius, -0.98, 0.82, 20, Color(1.0, 0.80, 0.53, 0.98 * strength), 2.4, true)
	var impact := Vector2(feet.x + sprite_width * 0.42, feet.y - sprite_height * 0.56)
	if enemy_feet.x < feet.x + sprite_width * 0.62:
		impact.x = enemy_feet.x - sprite_width * 0.12
	draw_circle(impact, 2.5 + strength * 3.0, Color(1.0, 0.68, 0.36, 0.92 * strength))
