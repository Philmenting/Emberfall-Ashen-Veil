extends "res://scripts/main.gd"
## QA views: starting combat stats; later-floor defeat is a deliberately staged progression case.
var output_dir:="/tmp/emberfall-recovery"
func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): output_dir=argument.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(output_dir)
	save_store=SaveStore.new("user://recovery-preview-"+str(Time.get_ticks_usec()))
	super._ready()
	set_process(false); farm_enabled=false; world_seed=1979; onboarding_complete=true
	_capture_cases.call_deferred()
func _capture_cases() -> void:
	var starter:=equipment.duplicate(true)
	for resolution in [Vector2i(1200,535),Vector2i(1040,1080),Vector2i(854,480)]:
		get_window().size=resolution
		await get_tree().process_frame
		for large in [false,true]:
			preferences.large_text=large
			var suffix:="-%dx%d%s" % [resolution.x,resolution.y,"-large" if large else ""]
			equipment=starter.duplicate(true); inventory.clear(); floor_number=40; character_class="Arcanist"; attribute_points=2; player_gold=600; player_level=1; allocated_attributes={"Strength":0,"Dexterity":0,"Intellect":0,"Vitality":0,"Spirit":0}
			pending_class_relic={}; first_relic_claimed=true
			_start_run(40); _skip_run()
			if run_succeeded: push_error("Expected staged late-floor defeat"); get_tree().quit(1); return
			await _capture("defeat"+suffix)
			var rng:=RandomNumberGenerator.new(); rng.seed=55
			for slot in GEAR_SLOTS:
				var item:=ClassLoot.roll("Arcanist",true,1,rng,slot,"RARE")
				item.region=0; item.locked=true; inventory.append(item)
			page="gear"; gear_tab="bag"; bag_slot="Weapon"; bag_view="protected"; _build_ui()
			await _capture("protected-bag"+suffix)
			gear_tab="equipment"; equipment.Amulet.locked=true; _build_ui()
			var scroll:=find_child("PageScroll",true,false) as ScrollContainer
			await get_tree().process_frame
			scroll.scroll_vertical=100000
			await _capture("equipment"+suffix)
			gear_tab="bag"; bag_slot="All"; bag_view="class"; character_class="Ranger"; _build_ui()
			await _capture("empty-filter"+suffix)
			while inventory.size()<MAX_BAG_SIZE:
				var held: Dictionary=inventory[0].duplicate(true); held.name="Stored relic %d" % inventory.size(); inventory.append(held)
			first_relic_claimed=false; _grant_expedition_rewards(true,1,false,23,"Ranger")
			bag_slot="All"; bag_view="protected"; _build_ui()
			await _capture("held-reward"+suffix)
	get_tree().quit()
func _capture(key: String) -> void:
	for frame in range(3): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output_dir+"/"+key+".png")
	print("RECOVERY_CAPTURE ",key)
