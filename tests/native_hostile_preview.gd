extends SceneTree
## Original native runtime studio comparison, never an ordinary combat claim.
const Actor=preload("res://scripts/dungeon_actor.gd")
var output_dir:="/tmp/emberfall-hostiles057"
var stage: Node3D
var camera: Camera3D

func _initialize() -> void:run.call_deferred()
func capture(actor: Node3D,role: String,label: String,clip: String,time: float) -> void:
	actor.motion_rig.pose(clip,time);actor.motion_rig.apply_actor_postprocess(actor,clip,time,0.0,true)
	for frame in 3:await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output_dir+"/"+role+"-"+label+".png")==OK)

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):output_dir=argument.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(output_dir);root.size=Vector2i(1000,1000)
	stage=Node3D.new();root.add_child(stage)
	var environment=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("1c242b")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color("a8b4c0");environment.ambient_light_energy=.34
	environment.sky=preload("res://scripts/dungeon_lighting.gd").reflection_sky();environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	var world=WorldEnvironment.new();world.environment=environment;stage.add_child(world)
	for p in [[Vector3(-3,6,-4),1.2,Color("ffe9d2")],[Vector3(3,4,-2),.5,Color("b4d0ed")],[Vector3(1,5,3),.8,Color("f4d6a5")]]:
		var light=OmniLight3D.new();light.position=p[0];light.light_energy=p[1];light.light_color=p[2];light.omni_range=16;light.shadow_enabled=true;light.light_cull_mask=3;stage.add_child(light)
	var floor=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(20,20);floor.mesh=plane
	var material=StandardMaterial3D.new();material.albedo_color=Color("343d47");material.roughness=.95;floor.material_override=material;stage.add_child(floor)
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;stage.add_child(camera);camera.current=true
	var count=0
	for role in ["hexer","bulwark","elite","guardian_0","guardian_1","guardian_2","guardian_3"]:
		var actor=Actor.new();actor.hostile=true;actor.boss=role.begins_with("guardian_");actor.kind="boss" if actor.boss else role
		if actor.boss:actor.region_index=int(role.right(1))
		stage.add_child(actor);assert(actor.source_avatar)
		var scale=actor.figure_height/2.15;camera.position=Vector3(2.3,2.0,-4)*scale;camera.size=4.8*scale;camera.look_at(Vector3(0,1.55,0)*scale)
		await capture(actor,role,"guard","idle",.2);count+=1
		await capture(actor,role,"load","windup_heavy",.65);count+=1
		await capture(actor,role,"release","windup_heavy",1.0);count+=1
		await capture(actor,role,"death","death",.90);count+=1
		actor.free()
	stage.free();print("NATIVE_HOSTILE_PREVIEW_PASS ",count," original runtime images; studio inspection only");quit(0)
