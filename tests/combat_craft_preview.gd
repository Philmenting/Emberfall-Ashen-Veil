extends "res://scripts/main.gd"
## Isolated, frozen visual fixtures. Use -- --capture-dir=/absolute/path.
## High health in boss fixtures isolates presentation; this is not a balance test.
var capture_dir := "/tmp/emberfall-craft"

func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): capture_dir=argument.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(capture_dir)
	save_store=SaveStore.new("user://craft-preview-"+str(Time.get_ticks_usec()))
	super._ready()
	var welcome:=get_node_or_null("Welcome")
	if welcome!=null: remove_child(welcome); welcome.queue_free()
	farm_enabled=false
	world_seed=1979
	onboarding_complete=true
	_capture_cases.call_deferred()

func _capture_cases() -> void:
	for resolution in [Vector2i(1280,720),Vector2i(854,480),Vector2i(1200,535),Vector2i(1040,1080)]:
		get_window().size=resolution
		await get_tree().process_frame
		character_class="Arcanist"
		page="gear"; gear_tab="skills"
		_build_ui()
		await _capture("stances-%dx%d" % [resolution.x,resolution.y])
		for region in range(4):
			character_class=["Vowkeeper","Arcanist","Ranger","Arcanist"][region]
			floor_number=region*10+1
			_start_run()
			run_arena.animation_enabled=false
			expedition.stats.max_hp=100000
			expedition.hero_hp=100000
			# Advance the actual simulation until an actual boss warning is active.
			while not expedition.finished:
				expedition.advance(0.1)
				var boss: Dictionary=expedition.enemy_by_id(50)
				if expedition.stage==5 and not boss.warning.is_empty(): break
			if expedition.finished: push_error("Preview failed to reach a boss telegraph"); get_tree().quit(1); return
			_sync_model_state()
			_build_ui()
			run_arena.animation_enabled=false
			await _capture("boss-%d-%dx%d" % [region,resolution.x,resolution.y])
			if region==1:
				_toggle_combat_details()
				await _capture("details-%dx%d" % [resolution.x,resolution.y])
	get_tree().quit()

func _capture(filename: String) -> void:
	for frame in range(3): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(capture_dir+"/"+filename+".png")
	print("CRAFT_CAPTURE ",filename)
