extends SceneTree
## Native production stills: unedited cloth, hair and material finish.
var actor: Node3D
var camera: Camera3D
var capture_dir="/tmp/emberfall-attire057"
var records: Array=[]
func _initialize() -> void:run.call_deferred()
func capture(key: String,label: String,clip: String,time: float,back: bool=false) -> void:
	actor.motion_rig.pose(clip,time);actor.motion_rig.apply_actor_postprocess(actor,clip,time,0.0,true)
	camera.position=Vector3(2.8,1.8,4 if back else -4);camera.size=3.7;camera.look_at(Vector3(0,1.5,0))
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var filename=key.to_lower()+"-"+label+".png"
	assert(root.get_texture().get_image().save_png(capture_dir+"/"+filename)==OK)
	var motion=actor.motion_rig.style.attire_motion
	records.append({"file":filename,"class":key,"clip":clip,"time":time,"max_displacement_metres":motion.max_displacement,"moving_vertices":motion.moved_vertex_count,"dynamic_surfaces":motion.records.size(),"upload_calls":motion.upload_calls,"uploaded_bytes":motion.uploaded_bytes,"native_bones":actor.motion_rig.skeleton.get_bone_count()})
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):capture_dir=arg.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(capture_dir);root.size=Vector2i(1200,1200)
	var stage=Node3D.new();root.add_child(stage)
	var env=WorldEnvironment.new();env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("202731")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("abb4c2");env.environment.ambient_light_energy=.40;stage.add_child(env)
	var floor=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(12,12);floor.mesh=plane
	var material=StandardMaterial3D.new();material.albedo_color=Color("323a44");material.roughness=.95;floor.material_override=material;stage.add_child(floor)
	for params in [[Vector3(-3,4,-4),1.1,Color("ffe3c6")],[Vector3(3,3,-2),.5,Color("b0d2ef")],[Vector3(1,3,3),.85,Color("ead8bf")]]:
		var light=OmniLight3D.new();light.position=params[0];light.light_energy=params[1];light.light_color=params[2];light.omni_range=12;light.shadow_enabled=true;light.light_cull_mask=3;stage.add_child(light)
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.current=true;stage.add_child(camera)
	for key in ["Arcanist","Ranger","Vowkeeper"]:
		actor=preload("res://scripts/dungeon_actor.gd").new();actor.kind=key;stage.add_child(actor);actor.set_process(false)
		await capture(key,"idle-front","idle",.4)
		await capture(key,"walk-rear","walk",.125,true)
		await capture(key,"cast-front","windup_heavy",.8)
		await capture(key,"cast-rear","windup_heavy",.8,true)
		actor.free()
	var output=FileAccess.open(capture_dir+"/native-receipt.json",FileAccess.WRITE);output.store_string(JSON.stringify({"scope":"Twelve unedited actual production-actor diagnostic stills. Native skinned vertices and real PBR materials. No overlays or standalone proxy body. Not ordinary combat, full-playback acceptance, or physical-phone performance.","frames":records},"\t")+"\n");output.close()
	print("AVATAR ATTIRE QUALITY PREVIEW: 12 native diagnostic stills, 0 overlays")
	quit(0)
