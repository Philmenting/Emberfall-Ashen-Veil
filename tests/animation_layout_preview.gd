extends "res://scripts/main.gd"
## Native moving layout inspection. Late-region Life is a QA fixture only.
var capture_dir:="/tmp/emberfall-animation-layout"
func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): capture_dir=argument.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(capture_dir)
	save_store=SaveStore.new("user://animation-layout-"+str(Time.get_ticks_usec()))
	super._ready()
	set_process(false); farm_enabled=false; pending_afk_seconds=0; offline_job=null
	_finish_welcome(false); world_seed=1979
	_capture_cases.call_deferred()
func _capture_cases() -> void:
	for resolution in [Vector2i(2424,1080),Vector2i(1040,1080),Vector2i(854,480)]:
		get_window().size=resolution
		await get_tree().process_frame
		preferences.large_text=resolution.x==854
		for class_key in ["Vowkeeper","Arcanist","Ranger"]:
			character_class=class_key; floor_number=1; _start_run()
			_prepare_manual()
			for frame in range(150):
				run_arena.world._process(1.0/30.0)
				if not expedition.pending_attack.is_empty() and float(expedition.pending_attack.left)<.09: break
			await _capture("hero-%s-%dx%d" % [class_key,resolution.x,resolution.y])
		for region in range(4):
			character_class=["Vowkeeper","Ranger","Arcanist","Arcanist"][region]
			floor_number=region*10+1; _start_run()
			run_active=false; run_arena.animation_enabled=false
			expedition.stats.max_hp=100000; expedition.hero_hp=100000
			while not expedition.finished:
				expedition.advance(.1)
				if expedition.stage==5 and not expedition.enemy_by_id(50).warning.is_empty(): break
			if expedition.finished: push_error("Animation layout fixture did not reach guardian"); get_tree().quit(1); return
			_sync_model_state(); _build_ui(); _prepare_manual()
			for frame in range(90):
				var warning: Dictionary=expedition.enemy_by_id(50).warning
				if warning.is_empty() or float(warning.left)<.16: break
				run_arena.world._process(1.0/30.0)
			await _capture("boss-%d-windup-%dx%d" % [region,resolution.x,resolution.y])
			for frame in range(12):
				run_arena.world._process(1.0/30.0)
				if run_arena.world.actor_by_id[50].release_time>=0: break
			await _capture("boss-%d-contact-%dx%d" % [region,resolution.x,resolution.y])
	print("ANIMATION_LAYOUT_CAPTURE_PASS 33 native moving scene frames / three layouts")
	get_tree().quit()
func _prepare_manual() -> void:
	run_active=false; run_arena.animation_enabled=false
	run_arena.set_process(false); run_arena.world.set_process(false)
	run_arena.world.active=true
func _capture(key: String) -> void:
	for frame in range(3): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(capture_dir+"/"+key+".png")
	print("ANIMATION_LAYOUT_CAPTURE ",key," actual_size=",get_viewport_rect().size)
