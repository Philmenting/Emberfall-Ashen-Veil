extends "res://scripts/main.gd"
## Native attack evidence: real starts and first guardian, ordinary gear.
## Editorial cuts skip travel only. Every recorded step is 1/30 simulation second.
var capture_dir:="/tmp/emberfall-attacks"
var frame_index:=0
var bare_inspection:=false

func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): capture_dir=argument.trim_prefix("--capture-dir=")
		if argument=="--bare": bare_inspection=true
	DirAccess.make_dir_recursive_absolute(capture_dir)
	save_store=SaveStore.new("user://attack-capture-"+str(Time.get_ticks_usec()))
	super._ready()
	set_process(false); farm_enabled=false; pending_afk_seconds=0; offline_job=null
	_finish_welcome(false); world_seed=1979
	_record.call_deferred()

func _record() -> void:
	get_window().size=Vector2i(1200,536)
	await get_tree().process_frame
	for class_key in ["Vowkeeper","Arcanist","Ranger"]:
		character_class=class_key; floor_number=1; _start_run(); _manual()
		print("ATTACK_CAPTURE ",class_key," ordinary start / frame ",frame_index)
		for frame in range(120): await _frame()
		if bare_inspection: continue
		# Advance the very same normal-geared expedition to its first warning.
		while not expedition.finished:
			if expedition.stage==5 and not expedition.enemy_by_id(50).warning.is_empty(): break
			expedition.advance(.1)
		if expedition.finished:
			push_error("ATTACK_CAPTURE_FAIL normal gear did not reach guardian: "+class_key)
			get_tree().quit(1); return
		_sync_model_state(); _build_ui(); _manual()
		print("ATTACK_CAPTURE ",class_key," ordinary guardian / frame ",frame_index)
		for frame in range(120): await _frame()
	print("ATTACK_CAPTURE_PASS ",frame_index," native frames / 30 FPS / three classes / ordinary gear / real damage and release / bare=",bare_inspection)
	get_tree().quit()

func _manual() -> void:
	run_arena.set_process(false); run_arena.world.set_process(false)
	run_arena.world.active=true
	if bare_inspection:
		run_arena.world.damage_numbers=false
		if not has_node("InspectionLabel"):
			var label:=Label.new(); label.name="InspectionLabel"
			label.text="QA · ACTUAL ATTACK SPEED · EFFECTS HIDDEN"
			label.position=Vector2(310,24); label.add_theme_font_size_override("font_size",15)
			add_child(label)

func _frame() -> void:
	if page=="run": run_arena.world._process(1.0/30.0)
	if bare_inspection:
		var world:Node3D=run_arena.world
		for effect in world.effects: effect.node.visible=false
		world.target_ring.visible=false; world.hero_marker.visible=false
		world.guard_visual.visible=false
		if is_instance_valid(world.ward_shell): world.ward_shell.visible=false
		for bar in world.bars.values(): bar.visible=false
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(capture_dir+"/frame-%04d.png" % frame_index)
	frame_index+=1
