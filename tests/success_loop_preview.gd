extends "res://scripts/main.gd"
## Actual UI and unmodified starting stats. Frozen captures are presentation evidence.
var output_dir:="/tmp/emberfall-success"
func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): output_dir=argument.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(output_dir)
	save_store=SaveStore.new("user://success-preview-"+str(Time.get_ticks_usec()))
	super._ready()
	set_process(false); farm_enabled=false; world_seed=1979
	_capture_cases.call_deferred()
func _capture_cases() -> void:
	var starter:=equipment.duplicate(true)
	for resolution in [Vector2i(1200,535),Vector2i(1040,1080),Vector2i(854,480)]:
		get_window().size=resolution
		await get_tree().process_frame
		player_level=1; player_xp=0; player_gold=600; allocated_attributes={"Strength":0,"Dexterity":0,"Intellect":0,"Vitality":0,"Spirit":0}; attribute_points=2
		equipment=starter.duplicate(true); inventory.clear(); first_relic_claimed=false; guardian_trophies=[]; floor_number=1; expedition_serial=1
		character_class="Arcanist"; page="camp"; preferences.large_text=false
		_build_ui(); _show_welcome()
		await _capture("welcome-%dx%d" % [resolution.x,resolution.y])
		preferences.large_text=true; _build_ui(); _show_welcome()
		await _capture("welcome-large-%dx%d" % [resolution.x,resolution.y])
		preferences.large_text=false; _finish_welcome(true)
		run_active=false; run_arena.animation_enabled=false
		expedition.advance(0.4); _sync_model_state(); _sync_combat_hud()
		await _capture("first-fight-%dx%d" % [resolution.x,resolution.y])
		_skip_run()
		await _capture("first-relic-%dx%d" % [resolution.x,resolution.y])
		find_child("EquipClassRelic",true,false).pressed.emit()
		_return_to_camp()
		var scroll:=find_child("PageScroll",true,false) as ScrollContainer
		await get_tree().process_frame
		scroll.ensure_control_visible(find_child("Oathcinder",true,false))
		await _capture("oaths-%dx%d" % [resolution.x,resolution.y])
		_start_run(floor_number,Contract.oath("cinder")); run_active=false; run_arena.animation_enabled=false; _sync_combat_hud()
		await _capture("oath-run-%dx%d" % [resolution.x,resolution.y])
	get_tree().quit()
func _capture(key: String) -> void:
	for frame in range(3): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output_dir+"/"+key+".png")
	print("SUCCESS_CAPTURE ",key)
