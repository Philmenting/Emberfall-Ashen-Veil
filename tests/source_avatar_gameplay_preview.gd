extends "res://tests/attack_gameplay_preview.gd"
var frame_records: Array=[]
func _record() -> void:
	get_window().size=Vector2i(1200,536)
	await get_tree().process_frame
	character_class="Arcanist";floor_number=1;_start_run();_manual()
	await _settle_renderer()
	assert(run_arena.world.hero.source_avatar)
	for frame in 120:await _source_frame()
	var before=expedition.elapsed
	while not expedition.finished:
		if expedition.stage==5 and not expedition.enemy_by_id(50).warning.is_empty():break
		expedition.advance(.1)
	assert(not expedition.finished)
	var after=expedition.elapsed
	_sync_model_state();_build_ui();_manual();await _settle_renderer()
	for frame in 120:await _source_frame()
	var f=FileAccess.open(capture_dir+"/manifest.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"frames":frame_records,"count":frame_index,"simulation_step":1.0/30.0,"cut_elapsed_before":before,"cut_elapsed_after":after,"source_model_sha256":FileAccess.get_sha256("res://assets/models/nyra052/arcanist.glb"),"staff_sha256":FileAccess.get_sha256("res://assets/models/nyra052/staff-grip053.glb"),"grip_profile_sha256":FileAccess.get_sha256("res://assets/models/nyra052/staff-grip053.json"),"scope":"ordinary Main Arcanist; first fight and same expedition first guardian; existing game camera/HUD/VFX; source65 rig"},"\t"))
	print("SOURCE65 GAMEPLAY: ",frame_index," actual chronological frames, ordinary gear and camera")
	get_tree().quit(0)
func _source_frame() -> void:
	await _frame()
	var hero=run_arena.world.hero
	var camera=run_arena.world.camera
	frame_records.append({"frame":frame_index-1,"elapsed":expedition.elapsed,"clip":hero.last_clip,"attack_time":hero.attack_time,"release_time":hero.release_time,"camera_origin":[camera.position.x,camera.position.y,camera.position.z],"camera_basis":[camera.basis.x.x,camera.basis.x.y,camera.basis.x.z,camera.basis.y.x,camera.basis.y.y,camera.basis.y.z,camera.basis.z.x,camera.basis.z.y,camera.basis.z.z],"actor_position":[hero.position.x,hero.position.y,hero.position.z]})
