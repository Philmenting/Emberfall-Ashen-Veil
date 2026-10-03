extends "res://scripts/main.gd"
## Deterministic frame capture of real fights with ordinary starting gear.
## Cuts omit intervening travel; playback retains actual combat speed (30 FPS).
var output_dir:="/tmp/emberfall-gameplay"
var frame_index:=0
var capture_class:="Arcanist"
func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): output_dir=argument.trim_prefix("--capture-dir=")
		if argument.begins_with("--class=") and argument.trim_prefix("--class=") in ["Vowkeeper","Arcanist","Ranger"]: capture_class=argument.trim_prefix("--class=")
	DirAccess.make_dir_recursive_absolute(output_dir)
	save_store=SaveStore.new("user://gameplay-clip-"+str(Time.get_ticks_usec()))
	super._ready()
	set_process(false); farm_enabled=false; world_seed=1979; character_class=capture_class
	_record.call_deferred()
func _record() -> void:
	get_window().size=Vector2i(1200,536)
	await get_tree().process_frame
	_finish_welcome(false)
	print("GAMEPLAY_CLIP actual camp")
	for frame in range(60): await _frame()
	_start_run(1)
	_prepare_manual_world()
	print("GAMEPLAY_CLIP first encounter")
	for frame in range(90):
		run_arena.world._process(1.0/30.0)
		await _frame()
	# Editorial cuts advance this same normal-geared expedition, never its stats.
	while not expedition.finished and (expedition.stage<5 or expedition.phase!="combat"): expedition.advance(0.1)
	if expedition.finished: push_error("Gameplay clip did not reach guardian"); get_tree().quit(1); return
	_sync_model_state(); _build_ui(); _prepare_manual_world()
	for frame in range(15): run_arena.world._process(1.0/30.0)
	print("GAMEPLAY_CLIP guardian encounter")
	for frame in range(150):
		run_arena.world._process(1.0/30.0)
		await _frame()
	# Continue to the last real phase before the second cut; no forced health.
	while not expedition.finished and int(expedition.enemy_by_id(50).get("boss_phase",0))<2: expedition.advance(0.1)
	_sync_model_state(); _build_ui(); _prepare_manual_world()
	print("GAMEPLAY_CLIP fractured guardian")
	for frame in range(60):
		if page=="run": run_arena.world._process(1.0/30.0)
		await _frame()
	if page=="run": _skip_run()
	if not run_succeeded: push_error("Gameplay clip failed to clear with starting gear"); get_tree().quit(1); return
	print("GAMEPLAY_CLIP earned relic")
	for frame in range(120): await _frame()
	var soundtrack:=AudioDirector.stream_for("dungeon")
	soundtrack.save_to_wav(output_dir+"/score.wav")
	print("GAMEPLAY_CLIP_PASS 480 frames / 30 FPS / ordinary gear")
	get_tree().quit()
func _prepare_manual_world() -> void:
	run_arena.set_process(false)
	run_arena.world.set_process(false)
	run_arena.world.active=true
func _frame() -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output_dir+"/frame-%04d.png" % frame_index)
	frame_index+=1
