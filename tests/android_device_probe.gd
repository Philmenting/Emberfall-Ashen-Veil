extends "res://scripts/main.gd"
## ARM64 device-only benchmark fixture. Ordinary starting gear; live combat, no shipping save.
func _ready() -> void:
	save_store=SaveStore.new("user://device-probe-"+str(Time.get_ticks_usec()))
	super._ready(); set_process(false)
	farm_enabled=false; world_seed=1979; onboarding_complete=true
	var welcome:=get_node_or_null("Welcome")
	if welcome!=null: remove_child(welcome); welcome.queue_free()
	_probe.call_deferred()
func _probe() -> void:
	var measurements: Array=[]
	for battery in [false,true]:
		preferences.battery=battery
		_apply_preferences()
		for selected in ["Vowkeeper","Arcanist","Ranger"]:
			character_class=selected
			_start_run(1)
			for frame in range(60): await get_tree().process_frame
			var intervals: Array[float]=[]
			var draws: Array[float]=[]
			var previous:=Time.get_ticks_usec()
			for frame in range(90):
				await get_tree().process_frame
				await RenderingServer.frame_post_draw
				var now:=Time.get_ticks_usec()
				intervals.append((now-previous)/1000.0); previous=now
				draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
			intervals.sort(); draws.sort()
			measurements.append({"class":selected,"quality":"battery" if battery else "balanced","frames":90,"median_frame_ms":intervals[45],"p95_frame_ms":intervals[85],"median_draw_calls":draws[45],"render_width":run_arena.render_viewport.size.x if is_instance_valid(run_arena) else 0,"render_height":run_arena.render_viewport.size.y if is_instance_valid(run_arena) else 0,"live_combat":page=="run" and not expedition.finished})
			run_active=false
			if is_instance_valid(run_arena): run_arena.animation_enabled=false
	var report: Dictionary={"schema":1,"workload":"live floor-1 combat; ordinary gear; 60 warmup and 90 measured frames per case","device":OS.get_model_name(),"platform":OS.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"logical_resolution":{"width":get_viewport_rect().size.x,"height":get_viewport_rect().size.y},"measurements":measurements}
	var output:=FileAccess.open("user://device-performance.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"\t")); output.close()
	var valid_live_window:=true
	for row in measurements: valid_live_window=valid_live_window and row.live_combat
	print("ANDROID_DEVICE_PROBE_PASS " if valid_live_window else "ANDROID_DEVICE_PROBE_FAIL incomplete live combat window ",JSON.stringify(report))
	if "--quit-after-probe" in OS.get_cmdline_user_args(): get_tree().quit(0 if valid_live_window else 1)

func _on_combat_advanced(updates: Array) -> void:
	_sync_model_state(); _sync_combat_hud()
	if is_instance_valid(audio): audio.combat_events(updates,character_class)
