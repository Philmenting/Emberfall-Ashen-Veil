extends "res://scripts/main.gd"
## Isolated captures of real UI and simulated expedition outcomes; never a shipping scene.
var capture_dir := "/tmp/emberfall-beta-preview"
var notch := false

func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): capture_dir=argument.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(capture_dir)
	save_store=SaveStore.new("user://beta-preview-"+str(Time.get_ticks_usec()))
	super._ready()
	world_seed=1979
	set_process(false)
	_capture_cases.call_deferred()

func _mobile_insets() -> Dictionary:
	return {"left":36,"right":36,"top":0,"bottom":20} if notch else {"left":0,"right":0,"top":0,"bottom":0}

func _capture_cases() -> void:
	for resolution in [Vector2i(1280,720),Vector2i(854,480)]:
		get_window().size=resolution
		await get_tree().process_frame
		character_class="Arcanist"
		page="camp"; floor_number=1; farm_enabled=true
		_build_ui(); _show_welcome()
		await _capture("welcome-%dx%d" % [resolution.x,resolution.y])
		_build_ui()
		await _capture("camp-%dx%d" % [resolution.x,resolution.y])
		_start_run(1)
		run_active=false; run_arena.animation_enabled=false
		expedition.advance(15.0); _sync_model_state(); _build_ui()
		await _capture("expedition-%dx%d" % [resolution.x,resolution.y])
		while not expedition.finished:
			expedition.advance(0.1)
			if expedition.stage==5 and not expedition.enemy_by_id(50).warning.is_empty(): break
		if not expedition.finished:
			_sync_model_state(); _build_ui()
			await _capture("guardian-%dx%d" % [resolution.x,resolution.y])
		_skip_run()
		await _capture("loot-%dx%d" % [resolution.x,resolution.y])
		_return_to_camp()
		_show_settings()
		get_node("Options")._select_tab("beta")
		await _capture("feedback-%dx%d" % [resolution.x,resolution.y])
		_close_settings()
		notch=true; _build_ui()
		await _capture("camp-simulated-cutout-%dx%d" % [resolution.x,resolution.y])
		notch=false
		_reconcile_farm_time(86400,true); _build_ui()
		await _capture("afk-recovery-%dx%d" % [resolution.x,resolution.y])
		offline_job=null; pending_afk_seconds=0
	get_tree().quit()

func _capture(filename: String) -> void:
	for frame in range(3): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var capture := get_viewport().get_texture().get_image()
	capture.convert(Image.FORMAT_RGB8)
	capture.save_png(capture_dir+"/"+filename+".png")
	print("BETA_CAPTURE ",filename)
