extends "res://scripts/main.gd"
## Real renderer inspection; elevated Life for late-region art only, never advertising.
var capture_dir:="/tmp/emberfall-redesign"
func _ready() -> void:
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--capture-dir="): capture_dir=argument.trim_prefix("--capture-dir=")
    DirAccess.make_dir_recursive_absolute(capture_dir)
    save_store=SaveStore.new("user://redesign-review-"+str(Time.get_ticks_usec()))
    super._ready()
    set_process(false); farm_enabled=false; pending_afk_seconds=0; offline_job=null
    var welcome:=get_node_or_null("Welcome")
    if welcome!=null: remove_child(welcome); welcome.queue_free()
    onboarding_complete=true; world_seed=1979; character_class="Arcanist"
    _capture_cases.call_deferred()
func _capture_cases() -> void:
    for resolution in [Vector2i(1200,535),Vector2i(1040,1080),Vector2i(854,480)]:
        get_window().size=resolution
        await get_tree().process_frame
        preferences.large_text=resolution.x==854
        floor_number=2; page="camp"; guardian_trophies=[0]
        _build_ui()
        await _capture("camp-%dx%d" % [resolution.x,resolution.y])
        if has_method("_open_camp_station"):
            _open_camp_station("table")
            await _capture("oaths-%dx%d" % [resolution.x,resolution.y])
        for region in range(4):
            character_class=["Arcanist","Ranger","Vowkeeper","Arcanist"][region]
            floor_number=region*10+1
            _start_run()
            run_active=false; run_arena.animation_enabled=false
            expedition.stats.max_hp=100000; expedition.hero_hp=100000
            while not expedition.finished:
                expedition.advance(0.1)
                if expedition.stage==5 and not expedition.enemy_by_id(50).warning.is_empty(): break
            if expedition.finished: push_error("Redesign fixture failed to reach guardian"); get_tree().quit(1); return
            _sync_model_state(); _build_ui(); run_arena.animation_enabled=false
            await _capture("boss-%d-%dx%d" % [region,resolution.x,resolution.y])
        page="gear"; gear_tab="equipment"; _build_ui()
        await _capture("gear-%dx%d" % [resolution.x,resolution.y])
    print("REDESIGN_CAPTURE_PASS actual scenes; late guardian fixtures use extra Life")
    get_tree().quit()
func _capture(key: String) -> void:
    for frame in range(5): await get_tree().process_frame
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(capture_dir+"/"+key+".png")
    print("REDESIGN_CAPTURE ",key)
