extends SceneTree
## Five bounded native-runtime images for material/pose inspection. This is a
## studio fixture; ordinary combat is recorded separately through the game.
const Actor=preload("res://scripts/dungeon_actor.gd")
var output_dir:="/tmp/emberfall-hostile-quality"
var actors: Array[Node3D]=[]
var camera: Camera3D
var caption: Label

func _initialize() -> void: capture_cases.call_deferred()

func make_actor(key: String,position: Vector3) -> Node3D:
	var actor:=Actor.new(); actor.hostile=true; actor.boss=key.begins_with("guardian_")
	actor.kind="boss" if actor.boss else key
	if actor.boss: actor.region_index=int(key.right(1))
	actor.position=position
	root.get_node("HostileStudio").add_child(actor)
	actor.animate(.15,false); actors.append(actor)
	return actor

func capture(name: String) -> void:
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw
	var result:=root.get_texture().get_image().save_png(output_dir+"/"+name+".png")
	assert(result==OK,"Native hostile image could not be written")
	print("HOSTILE_NATIVE_CAPTURE ",name)

func capture_cases() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): output_dir=argument.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size=Vector2i(1200,675); root.content_scale_size=Vector2i(1200,675)
	var stage:=Node3D.new(); stage.name="HostileStudio"; root.add_child(stage)
	var environment:=Environment.new(); environment.background_mode=Environment.BG_COLOR; environment.background_color=Color("151c22")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; environment.ambient_light_color=Color("abb8c5"); environment.ambient_light_energy=.32
	environment.sky=preload("res://scripts/dungeon_lighting.gd").reflection_sky(); environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	var background:=WorldEnvironment.new(); background.environment=environment; stage.add_child(background)
	var key:=DirectionalLight3D.new(); key.rotation_degrees=Vector3(-35,145,0); key.light_color=Color("ffe4bb"); key.light_energy=1.10; key.shadow_enabled=true; key.directional_shadow_max_distance=22.0; stage.add_child(key)
	var rim:=DirectionalLight3D.new(); rim.rotation_degrees=Vector3(-24,-36,0); rim.light_color=Color("9aabb9"); rim.light_energy=.48; stage.add_child(rim)
	var floor_mesh:=PlaneMesh.new(); floor_mesh.size=Vector2(24,24)
	var floor_mat:=StandardMaterial3D.new(); floor_mat.albedo_color=Color("252d33"); floor_mat.roughness=.95
	var floor_node:=MeshInstance3D.new(); floor_node.mesh=floor_mesh; floor_node.material_override=floor_mat; stage.add_child(floor_node)
	camera=Camera3D.new(); camera.position=Vector3(2.8,3.6,-13.5); camera.fov=35; stage.add_child(camera); camera.current=true; camera.look_at(Vector3(0,1.12,1.5))
	caption=Label.new(); caption.position=Vector2(32,24); caption.add_theme_font_size_override("font_size",21); root.add_child(caption)
	var keys: Array[String]=["raider","hexer","bulwark","elite"]
	for index in keys.size(): make_actor(keys[index],Vector3((1.5-index)*2.35,0,1.5))
	caption.text="NATIVE HOSTILE INSPECTION · SCAVENGER / HEXER / SHIELD BEARER / ELITE\nREST SPACE PRESERVED · AGED METAL / CLOTH / RESTRAINED INLAYS"
	await capture("hostile-role-guards")
	for actor in actors:
		actor.anticipation=.86; actor.animate(0.0,false)
	caption.text="NATIVE HOSTILE INSPECTION · ORDINARY PREPARATION\nDISTINCT CLAW / PALM / SHIELD-LED CUT / DIAGONAL CUT"
	await capture("hostile-role-preparations")
	for actor in actors: actor.free()
	actors.clear()
	var bell:=make_actor("guardian_0",Vector3.ZERO)
	camera.position=Vector3(5.2,5.0,-13.0); camera.look_at(Vector3(0,2.1,0))
	bell.set_telegraph(.32,1.4); bell.animate(0.0,false)
	caption.text="NATIVE BELL WARDEN INSPECTION · COMMITTED WARNING\nONE LOADED BELL MACE / ASYMMETRIC CENSER COUNTERWEIGHT"
	await capture("bell-warning-chamber")
	bell.strike("heavy"); bell.animate(0.0,false)
	caption.text="NATIVE BELL WARDEN INSPECTION · AUTHORITATIVE RELEASE\nSAME REST LENGTHS / SOLES / SOURCE WEAPON"
	await capture("bell-heavy-contact")
	bell.animate(.16,false)
	caption.text="NATIVE BELL WARDEN INSPECTION · KNEE CATCH / WEIGHTED RETURN\nNATIVE 0.56 SECOND RECOVERY · WORLD ANCHOR UNCHANGED"
	await capture("bell-heavy-catch")
	print("HOSTILE_QUALITY_NATIVE_PASS 5 original runtime PNGs / studio fixture")
	quit(0)
