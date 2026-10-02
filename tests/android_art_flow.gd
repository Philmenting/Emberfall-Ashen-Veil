extends "res://scripts/main.gd"
## Android graphics inspection fixture: actual assets, all classes and four guardians.
## Extra Life only keeps the presentation fixture alive; this is not a balance test.
func _ready() -> void:
	save_store=SaveStore.new("user://android-art-inspection")
	super._ready()
	set_process(false)
	farm_enabled=false; offline_job=null; pending_afk_seconds=0
	onboarding_complete=true; world_seed=1979
	var welcome:=get_node_or_null("Welcome")
	if welcome!=null: remove_child(welcome); welcome.queue_free()
	_inspect_regions.call_deferred()

func _inspect_regions() -> void:
	var measurements: Array=[]
	print("ANDROID_ART_READY actual GLTF assets, renderer=",RenderingServer.get_current_rendering_method())
	for region in range(4):
		character_class=["Vowkeeper","Arcanist","Ranger","Arcanist"][region]
		floor_number=region*10+1
		_start_run()
		run_active=false; run_arena.animation_enabled=false
		expedition.stats.max_hp=100000; expedition.hero_hp=100000
		while not expedition.finished and expedition.elapsed<600.0:
			expedition.advance(0.1)
			if expedition.stage==5 and not expedition.enemy_by_id(50).warning.is_empty(): break
		if expedition.finished or expedition.stage!=5:
			print("ANDROID_ART_FAIL region ",region," could not reach the guardian")
			return
		_sync_model_state(); _build_ui(); run_arena.animation_enabled=false
		for frame in range(12): await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var capture:=get_viewport().get_texture().get_image()
		capture.convert(Image.FORMAT_RGB8)
		if capture.save_png("user://art-region-%d.png" % region)!=OK:
			print("ANDROID_ART_FAIL screenshot write failed")
			return
		for battery in [false,true]:
			run_arena.apply_quality(battery,true,false)
			Engine.max_fps=30 if battery else 60
			for frame in range(5): await get_tree().process_frame
			measurements.append(await _measure_render(region,battery))
		Engine.max_fps=60
		print("ANDROID_ART_REGION_PASS ",region," ",REGIONS[region].boss," ",capture.get_width(),"x",capture.get_height())
	var report: Dictionary={"schema":1,"scenario":"frozen guardian render workload","platform":OS.get_name(),"device":OS.get_model_name(),"renderer":RenderingServer.get_current_rendering_method(),"resolution":{"width":get_viewport().get_visible_rect().size.x,"height":get_viewport().get_visible_rect().size.y},"measurements":measurements}
	var output:=FileAccess.open("user://art-performance.json",FileAccess.WRITE)
	if output==null:
		print("ANDROID_ART_FAIL performance report write failed"); return
	output.store_string(JSON.stringify(report,"\t")); output.close()
	print("ANDROID_ART_PASS all four regions rendered with authored models and material maps")
	if "--quit-after-art" in OS.get_cmdline_user_args(): get_tree().quit()

func _measure_render(region: int,battery: bool) -> Dictionary:
	var frame_ms: Array[float]=[]
	var draw_calls: Array[float]=[]
	var previous:=Time.get_ticks_usec()
	for frame in range(30):
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var now:=Time.get_ticks_usec()
		frame_ms.append((now-previous)/1000.0)
		previous=now
		draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	frame_ms.sort(); draw_calls.sort()
	var measurement: Dictionary={"region":region,"quality":"battery" if battery else "balanced","frames":frame_ms.size(),"median_frame_ms":frame_ms[15],"p95_frame_ms":frame_ms[28],"median_draw_calls":draw_calls[15],"render_width":run_arena.render_viewport.size.x,"render_height":run_arena.render_viewport.size.y,"target_fps":30 if battery else 60}
	print("ART_RENDER_METRIC ",JSON.stringify(measurement))
	return measurement
