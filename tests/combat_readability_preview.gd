extends "res://scripts/main.gd"
## Native UI evidence. Guardian fixtures have extra Life; the clip uses normal gear.
var capture_dir:="/tmp/emberfall-readability"
var capture_video:=false
func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): capture_dir=argument.trim_prefix("--capture-dir=")
		if argument=="--video": capture_video=true
	DirAccess.make_dir_recursive_absolute(capture_dir)
	save_store=SaveStore.new("user://readability-preview-"+str(Time.get_ticks_usec()))
	super._ready()
	set_process(false); farm_enabled=false; pending_afk_seconds=0; offline_job=null
	_finish_welcome(false); world_seed=1979
	_capture_cases.call_deferred()
func _capture_cases() -> void:
	if capture_video:
		await _video()
		get_tree().quit(); return
	for resolution in [Vector2i(2424,1080),Vector2i(1040,1080),Vector2i(854,480)]:
		get_window().size=resolution
		await get_tree().process_frame
		preferences.large_text=resolution.x==854
		for class_key in ["Vowkeeper","Arcanist","Ranger"]:
			character_class=class_key; floor_number=1; _start_run()
			_manual()
			for frame in range(55): run_arena.world._process(1.0/30.0)
			await _capture("skills-%s-%dx%d" % [class_key,resolution.x,resolution.y])
			if class_key=="Arcanist":
				_inspect_combat_skill("chain")
				await _capture("reading-%dx%d" % [resolution.x,resolution.y])
				_toggle_combat_details()
				expedition.hero_mana=expedition.signature_cost()
				expedition.guard_time=2.4
				expedition.skill_cd=0; expedition.pending_attack.clear()
				for key in expedition.rotation.cooldowns: expedition.rotation.cooldowns[key]=0.0
				_sync_model_state(); _sync_combat_hud()
				await _capture("ward-reserve-%dx%d" % [resolution.x,resolution.y])
		for region in range(4):
			character_class=["Vowkeeper","Arcanist","Ranger","Arcanist"][region]
			floor_number=region*10+1; _start_run()
			run_arena.animation_enabled=false
			expedition.stats.max_hp=100000; expedition.hero_hp=100000
			while not expedition.finished:
				expedition.advance(.1)
				if expedition.stage==5 and not expedition.enemy_by_id(50).warning.is_empty(): break
			if expedition.finished: push_error("READABILITY_CAPTURE_FAIL guardian not reached"); get_tree().quit(1); return
			_sync_model_state(); _build_ui(); _manual()
			await _capture("guardian-%d-%dx%d" % [region,resolution.x,resolution.y])
	print("READABILITY_CAPTURE_PASS 27 native frames / three layouts")
	get_tree().quit()
func _manual() -> void:
	run_arena.set_process(false); run_arena.world.set_process(false)
	run_arena.world.active=true
func _capture(key: String) -> void:
	for frame in range(4): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(capture_dir+"/"+key+".png")
	print("READABILITY_CAPTURE ",key)
func _video() -> void:
	get_window().size=Vector2i(1200,536)
	await get_tree().process_frame
	character_class="Arcanist"; floor_number=1; _start_run(); _manual()
	for frame in range(360):
		if frame==150: _inspect_combat_skill("chain")
		if frame==240: _toggle_combat_details()
		run_arena.world._process(1.0/30.0)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(capture_dir+"/frame-%04d.png" % frame)
	print("READABILITY_CLIP_PASS 360 native frames / 30 FPS / normal gear / real reading pause")
