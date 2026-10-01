extends "res://scripts/main.gd"
## Render a new store composition from the game's own 3D scene, not painted gameplay.
func _ready() -> void:
	get_window().size=Vector2i(1024,500)
	get_window().content_scale_size=Vector2i(1024,500)
	save_store=SaveStore.new("user://store-art-"+str(Time.get_ticks_usec()))
	super._ready()
	character_class="Arcanist"; world_seed=1979
	_start_run(1)
	run_active=false
	while not expedition.finished:
		expedition.advance(0.1)
		if expedition.stage==5 and not expedition.enemy_by_id(50).warning.is_empty(): break
	_sync_model_state(); _build_ui()
	for child in get_children():
		if child!=run_arena and child is CanvasItem: child.hide()
	run_arena.animation_enabled=false
	run_arena.world.camera.h_offset=-7.0
	var brand := PanelContainer.new()
	brand.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	brand.anchor_right=0.49
	var style := StyleBoxFlat.new()
	style.bg_color=Color("11161b")
	style.content_margin_left=34; style.content_margin_right=24
	style.border_width_right=2; style.border_color=GOLD
	brand.add_theme_stylebox_override("panel",style)
	add_child(brand)
	var center := VBoxContainer.new()
	center.alignment=BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation",18)
	brand.add_child(center)
	center.add_child(_label("✦",48,GOLD))
	center.add_child(_label("EMBERFALL",47,PALE,true))
	center.add_child(_label("A S H E N   V E I L",23,GOLD,true))
	center.add_child(_paragraph_label("Prepare your build.\nLet Nyra brave the Veil.",22,PALE))
	center.add_child(_label("DARK FANTASY  •  AFK RPG",13,MUTED,true))
	for frame in range(5): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://docs/play/assets")
	var capture := get_viewport().get_texture().get_image()
	capture.convert(Image.FORMAT_RGB8)
	capture.save_png("res://docs/play/assets/feature-graphic.png")
	get_tree().quit()
