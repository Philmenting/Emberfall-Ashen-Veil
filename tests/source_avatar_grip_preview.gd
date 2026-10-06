extends SceneTree
## Actual production hand/shaft contact, viewed from three sides.
var actor: Node3D
var camera: Camera3D
var capture_dir="/tmp/emberfall-source-studio"
func _initialize() -> void:call_deferred("run")
func capture(label: String,clip: String,time: float,position: Vector3,target: Vector3,size: float) -> void:
	actor.motion_rig.pose(clip,time)
	actor.motion_rig.apply_actor_postprocess(actor,clip,time,0.0,true)
	camera.position=position;camera.size=size;camera.look_at(target)
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(capture_dir+"/"+label+".png")==OK)
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):capture_dir=arg.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(capture_dir);root.size=Vector2i(1200,1200)
	var stage=Node3D.new();root.add_child(stage)
	var environment=WorldEnvironment.new();environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("242932")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("a8b0bc");environment.environment.ambient_light_energy=.35;stage.add_child(environment)
	var floor=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(20,20);floor.mesh=plane
	var material=StandardMaterial3D.new();material.albedo_color=Color("343d47");material.roughness=.95;floor.material_override=material;stage.add_child(floor)
	for params in [[Vector3(-3,4,-4),1.15,Color("ffe9d2")],[Vector3(3,2,-2),.5,Color("b4d0ed")],[Vector3(1,3,3),.8,Color("f4d6a5")]]:
		var light=OmniLight3D.new();light.position=params[0];light.light_energy=params[1];light.light_color=params[2];light.omni_range=12;light.shadow_enabled=true;stage.add_child(light)
	actor=preload("res://scripts/dungeon_actor.gd").new();actor.kind="Arcanist";stage.add_child(actor)
	assert(actor.source_avatar)
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;stage.add_child(camera);camera.current=true
	var rig=actor.motion_rig
	for phase in [["idle",.4],["walk",.25],["windup_basic",1.0],["recover_basic",.14]]:
		rig.pose(phase[0],phase[1]);rig.apply_actor_postprocess(actor,phase[0],phase[1],0.0,true)
		var hand=actor.body.to_global(rig.motion_node.transform*rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone("hand_r")).origin)
		var label=String(phase[0])+"-"+str(phase[1])
		await capture(label+"-front",phase[0],phase[1],hand+Vector3(0,.055,-1.5),hand+Vector3(0,.025,0),.27)
		var outside=(actor.body.global_basis*rig.motion_node.basis*Vector3.LEFT).normalized()
		await capture(label+"-outer",phase[0],phase[1],hand+outside*1.5+Vector3(0,.055,0),hand+Vector3(0,.025,0),.27)
		await capture(label+"-back",phase[0],phase[1],hand+Vector3(0,.055,1.5),hand+Vector3(0,.025,0),.27)
	print("GRIP PREVIEW: 12 actual hand closeups; idle/walk/cast/recovery, three sides")
	quit(0)
