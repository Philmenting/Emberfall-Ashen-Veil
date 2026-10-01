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
		print("ANDROID_ART_REGION_PASS ",region," ",REGIONS[region].boss," ",capture.get_width(),"x",capture.get_height())
	print("ANDROID_ART_PASS all four regions rendered with authored models and material maps")
