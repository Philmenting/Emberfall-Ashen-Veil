extends "res://scripts/main.gd"
## Native review fixtures, with ordinary equipped stats; never a player's real save.
var capture_dir:="/tmp/emberfall-gear-goals-preview"
func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): capture_dir=argument.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(capture_dir)
	save_store=SaveStore.new("user://gear-preview-"+str(Time.get_ticks_usec()))
	clock_source=func(): return 2000000000
	super._ready()
	set_process(false); farm_enabled=false; offline_job=null; pending_afk_seconds=0
	_finish_welcome(false)
	character_class="Arcanist"; world_seed=1979; floor_number=12
	_capture_cases.call_deferred()

func _capture_cases() -> void:
	for resolution in [Vector2i(854,480),Vector2i(1200,535),Vector2i(1040,1080)]:
		get_window().size=resolution
		preferences.large_text=resolution.x==854
		for slot in GEAR_SLOTS: equipment[slot].erase("region")
		equipment.Helmet.region=0; equipment.Chest.region=0
		var duplicate: Dictionary=equipment.Weapon.duplicate(true)
		duplicate.slot="Weapon"; duplicate.status=""; duplicate.affinity=character_class
		var rng:=RandomNumberGenerator.new(); rng.seed=42
		var held:=_generate_item(true,11,rng,character_class,"Boots")
		inventory=[duplicate,held]
		gear_tab="sets"; _navigate("gear")
		await _capture("set-goals-%dx%d" % [resolution.x,resolution.y])
		gear_tab="bag"; _show_all_gear(); _review_cleanup()
		await _capture("duplicate-sales-%dx%d" % [resolution.x,resolution.y])
	print("GEAR_GOALS_CAPTURE_PASS 6 native review frames")
	get_tree().quit()

func _capture(key: String) -> void:
	for frame in range(6): await get_tree().process_frame
	var scroll:=find_child("PageScroll",true,false) as ScrollContainer
	if scroll==null or scroll.get_child(0).size.x>scroll.size.x+1:
		push_error("Review content overflows horizontally: "+key)
		get_tree().quit(1)
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(capture_dir+"/"+key+".png")
	print("GEAR_GOALS_CAPTURE ",key," actual_size=",get_viewport_rect().size)
