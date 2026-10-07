extends "res://scripts/main.gd"
## Native 1200x536 UI evidence. The guardian inspection has boosted Life and
## two deliberately overlapping fixture positions; it is not a gameplay run.
var capture_dir:="/tmp/emberfall-combat-occlusion-056"
func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):capture_dir=argument.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(capture_dir)
	save_store=SaveStore.new("user://combat-occlusion-056-"+str(Time.get_ticks_usec()))
	super._ready();set_process(false);farm_enabled=false;pending_afk_seconds=0;offline_job=null
	_finish_welcome(false);world_seed=1979
	_capture_cases.call_deferred()
func _capture_cases() -> void:
	get_window().size=Vector2i(1200,536)
	await get_tree().process_frame
	character_class="Arcanist";floor_number=1;_start_run()
	run_arena.animation_enabled=false;run_arena.world.set_process(false)
	expedition.stats.max_hp=100000;expedition.hero_hp=100000
	while not expedition.finished:
		expedition.advance(.1)
		if expedition.stage==5 and not expedition.enemy_by_id(50).warning.is_empty():break
	if expedition.finished:
		push_error("OCCLUSION_CAPTURE_FAIL guardian not reached");get_tree().quit(1);return
	_sync_model_state();_build_ui()
	run_arena.animation_enabled=false;run_arena.world.set_process(false);run_arena.world.active=false
	for frame in range(6):await get_tree().process_frame
	var world: Node3D=run_arena.world
	var guardian: Node3D=world.actor_by_id[50]
	var natural: Vector3=world.hero.position
	var original_camera: Transform3D=world.camera.transform
	var original_snapshot: String=expedition.encode_snapshot()
	for fixture in ["natural","overlap"]:
		var away: Vector3=guardian.position-world.camera.position;away.y=0
		world.hero.position=natural if fixture=="natural" else guardian.position+away.normalized()*1.3
		world.hero.strike("basic",.3,true);world.hero.sync_attack(.06);world.hero.animate(0,false)
		world._update_combat_readability(0)
		print("OCCLUSION_FIXTURE ",fixture," enabled=",world.combat_readability.enabled," nearest_depth=",world.combat_readability.nearest_depth)
		world.combat_readability.update(world.hero,world.camera,false)
		await _capture("boss-"+fixture+"-opaque")
		world._update_combat_readability(0)
		await _capture("boss-"+fixture+"-reveal")
	if expedition.encode_snapshot()!=original_snapshot or world.camera.transform!=original_camera:
		push_error("OCCLUSION_CAPTURE_FAIL changed simulation="+str(expedition.encode_snapshot()!=original_snapshot)+" camera="+str(world.camera.transform!=original_camera));get_tree().quit(1);return
	print("OCCLUSION_CAPTURE_PASS four original PNG frames; original camera and simulation preserved")
	get_tree().quit()
func _capture(key: String) -> void:
	for frame in range(3):await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var error:=get_viewport().get_texture().get_image().save_png(capture_dir+"/"+key+".png")
	if error!=OK:push_error("OCCLUSION_CAPTURE_FAIL save "+key);get_tree().quit(1);return
	print("OCCLUSION_CAPTURE ",key)
