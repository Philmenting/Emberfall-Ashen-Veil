extends SceneTree
## Bounded original runtime images of live native class body/armor/weapon
## contact. Ordinary encounter playback is captured by the gameplay recorder.
const Actor=preload("res://scripts/dungeon_actor.gd")
var output_dir:="/tmp/emberfall-class-quality"
var camera: Camera3D
var actor: Node3D

func _initialize() -> void:run.call_deferred()

func capture(label: String,clip: String,time: float) -> void:
	actor.motion_rig.pose(clip,time)
	actor.motion_rig.apply_actor_postprocess(actor,clip,time,0.0,true)
	for index in 3:await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output_dir+"/"+actor.kind.to_lower()+"-"+label+".png")==OK)
	print("CLASS_NATIVE_CAPTURE ",actor.kind," ",label)

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):output_dir=argument.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size=Vector2i(1000,1000)
	var stage=Node3D.new();root.add_child(stage)
	var environment=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("1c242b")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color("a8b4c0");environment.ambient_light_energy=.34
	environment.sky=preload("res://scripts/dungeon_lighting.gd").reflection_sky();environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	var world=WorldEnvironment.new();world.environment=environment;stage.add_child(world)
	for params in [[Vector3(-3,4,-4),1.2,Color("ffe9d2")],[Vector3(3,2,-2),.5,Color("b4d0ed")],[Vector3(1,3,3),.8,Color("f4d6a5")]]:
		var light=OmniLight3D.new();light.position=params[0];light.light_energy=params[1];light.light_color=params[2];light.omni_range=12;light.shadow_enabled=true;stage.add_child(light)
	var floor=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(20,20);floor.mesh=plane
	var material=StandardMaterial3D.new();material.albedo_color=Color("343d47");material.roughness=.95;floor.material_override=material;stage.add_child(floor)
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.position=Vector3(2.3,1.7,-4)
	camera.size=3.1;stage.add_child(camera);camera.current=true;camera.look_at(Vector3(0,1.2,0))
	for class_key in ["Vowkeeper","Ranger"]:
		actor=Actor.new();actor.kind=class_key;stage.add_child(actor)
		assert(actor.source_avatar)
		await capture("guard","idle",.4)
		await capture("basic-load","windup_basic",.65)
		await capture("basic-release","windup_basic",1.0)
		await capture("signature-load","windup_skill",.65)
		await capture("heavy-release","windup_heavy",1.0)
		await capture("recovery","recover_basic",.14)
		actor.motion_rig.pose("windup_basic",1.0)
		actor.motion_rig.apply_actor_postprocess(actor,"windup_basic",1.0,0.0,true)
		var grip=actor.body.to_global(actor.motion_rig.weapon_grip_position())
		camera.position=grip+Vector3(.55,.18,-.65);camera.size=.40;camera.look_at(grip)
		await capture("grip-closeup","windup_basic",1.0)
		camera.position=Vector3(2.3,1.7,-4);camera.size=3.1;camera.look_at(Vector3(0,1.2,0))
		actor.free()
	print("CLASS_QUALITY_NATIVE_PASS 14 original runtime images; studio inspection only")
	quit(0)
