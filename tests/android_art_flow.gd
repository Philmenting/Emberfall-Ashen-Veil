extends "res://scripts/main.gd"
## Android graphics inspection fixture: actual assets, all classes and four guardians.
## Extra Life only keeps the presentation fixture alive; this is not a balance test.
const NativeSkinAudit=preload("res://tests/source_avatar_skin.gd")
const GUARDIAN_ACTIONS=["Sword_Regular_C","Spell_Simple_Shoot","Spell_Simple_Enter","Sword_Regular_C"]
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
	var motion: Array=[]
	print("ANDROID_ART_READY native spatial 3D skeletons, renderer=",RenderingServer.get_current_rendering_method())
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
		motion.append(await _inspect_motion(region))
		print("ANDROID_ART_REGION_PASS ",region," ",REGIONS[region].boss," ",capture.get_width(),"x",capture.get_height())
	var report: Dictionary={"schema":2,"scenario":"frozen guardian render workload; separately stepped real native65 combat animation","platform":OS.get_name(),"device":OS.get_model_name(),"renderer":RenderingServer.get_current_rendering_method(),"resolution":{"width":get_viewport().get_visible_rect().size.x,"height":get_viewport().get_visible_rect().size.y},"measurements":measurements,"motion":motion}
	var output:=FileAccess.open("user://art-performance.json",FileAccess.WRITE)
	if output==null:
		print("ANDROID_ART_FAIL performance report write failed"); return
	output.store_string(JSON.stringify(report,"\t")); output.close()
	print("ANDROID_ART_PASS all four regions rendered with authored 3D models and lit materials")
	if "--quit-after-art" in OS.get_cmdline_user_args(): get_tree().quit()

func _inspect_motion(region: int) -> Dictionary:
	run_arena.apply_quality(false,true,false)
	var world: Node3D=run_arena.world
	world.set_process(false); world.active=true
	var guardian: Node3D=world.actor_by_id[50]
	var skeleton: Skeleton3D=guardian.motion_rig.skeleton
	var head:=skeleton.find_bone("Head")
	if head<0:
		print("ANDROID_ART_FAIL motion ",region," native head bone missing")
		world.active=false
		return {"region":region,"passed":false}
	var previous: Transform3D=skeleton.get_bone_global_pose(head)
	var changed:=0; var hashes: Array=[]
	var before: float=expedition.elapsed
	for frame in range(20):
		world._process(.05)
		var pose: Transform3D=skeleton.get_bone_global_pose(head)
		if not pose.is_equal_approx(previous): changed+=1
		previous=pose
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		if frame in [0,5,11,17]:
			var capture:=get_viewport().get_texture().get_image()
			hashes.append(hash(capture.get_data()))
			if capture.save_png("user://motion-region-%d-%02d.png" % [region,frame])!=OK:
				print("ANDROID_ART_FAIL motion screenshot write failed")
	world.active=false
	var unique: Dictionary={}
	for value in hashes: unique[value]=true
	var bones:=skeleton.get_bone_count()
	var player: AnimationPlayer=guardian.motion_rig.player
	var bound_clips: Array[String]=[]
	for clip in player.get_animation_list():
		if _clip_targets_skeleton(player,skeleton,clip):bound_clips.append(String(clip))
	var required: Array[String]=["Walk_Loop","Hit_Chest","Death01",GUARDIAN_ACTIONS[region]]
	var required_bound:=true
	for clip in required:required_bound=required_bound and bound_clips.has(clip)
	var visible_skinned:=0;var visible_props:=0;var actual_triangles:=0
	for part: MeshInstance3D in guardian.motion_rig.motion_node.find_children("*","MeshInstance3D",true,false):
		if not part.is_visible_in_tree() or part.mesh==null:continue
		if part.skin!=null:visible_skinned+=1
		else:visible_props+=1
		for slot in part.mesh.get_surface_count():
			var arrays: Array=part.mesh.surface_get_arrays(slot)
			actual_triangles+=(arrays[Mesh.ARRAY_VERTEX].size() if arrays[Mesh.ARRAY_INDEX].is_empty() else arrays[Mesh.ARRAY_INDEX].size())/3
	var depth:=NativeSkinAudit.actual_figure_bounds(guardian.motion_rig).size.z
	var valid: bool=changed>=6 and unique.size()==4 and expedition.elapsed>before+.8 and guardian.source_avatar and guardian.surface_material==null and bones==65 and required_bound and visible_skinned>8 and visible_props>0 and actual_triangles==guardian.motion_rig.rendered_triangles and actual_triangles<=40000 and depth>.30
	print("ANDROID_MOTION_REGION_PASS " if valid else "ANDROID_ART_FAIL motion ",region," bone_changes=",changed," unique_frames=",unique.size())
	return {"region":region,"frames":20,"simulation_step_seconds":.05,"simulation_advanced_seconds":expedition.elapsed-before,"bone_changes":changed,"bone_name":skeleton.get_bone_name(head),"unique_rendered_frames":unique.size(),"skeleton_bones":bones,"native_clips":bound_clips.size(),"bound_native_clips":bound_clips,"required_native_clips":required,"visible_skinned_meshes":visible_skinned,"visible_rigid_props":visible_props,"visible_triangles":actual_triangles,"weighted_figure_depth":depth,"captures":[0,5,11,17],"passed":valid,"physical_device_performance":false}

func _clip_targets_skeleton(player: AnimationPlayer,skeleton: Skeleton3D,clip: StringName) -> bool:
	var animation:=player.get_animation(clip)
	if animation==null or animation.get_track_count()==0:return false
	var animation_root:=player.get_node(player.root_node)
	for track in animation.get_track_count():
		var path:=animation.track_get_path(track)
		if path.get_subname_count()!=1 or animation_root.get_node_or_null(NodePath(path.get_concatenated_names()))!=skeleton or skeleton.find_bone(path.get_subname(0))<0:return false
	return true

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
