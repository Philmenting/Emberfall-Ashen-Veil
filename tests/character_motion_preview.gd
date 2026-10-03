extends SceneTree
## Real runtime model/clip inspection at 30 FPS. This is labeled QA footage;
## ordinary geared combat has a separate capture through the live game scene.
const Actor=preload("res://scripts/dungeon_actor.gd")
var output_dir:="/tmp/emberfall-3d-motion"
var frame_index:=0
func _initialize() -> void: capture_motion.call_deferred()
func capture_motion() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): output_dir=argument.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size=Vector2i(1280,720); root.content_scale_size=Vector2i(1280,720)
	var stage:=Node3D.new(); root.add_child(stage)
	var environment:=Environment.new(); environment.background_mode=Environment.BG_COLOR; environment.background_color=Color("151b23")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; environment.ambient_light_color=Color("aab6cb"); environment.ambient_light_energy=.35
	environment.sky=preload("res://scripts/dungeon_lighting.gd").reflection_sky(); environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	var background:=WorldEnvironment.new(); background.environment=environment; stage.add_child(background)
	var key:=DirectionalLight3D.new(); key.rotation_degrees=Vector3(-35,145,0); key.light_color=Color("ffe4bb"); key.light_energy=1.10; key.shadow_enabled=true; key.directional_shadow_max_distance=18.0; stage.add_child(key)
	var rim:=DirectionalLight3D.new(); rim.rotation_degrees=Vector3(-24,-36,0); rim.light_color=Color("9aabb9"); rim.light_energy=.48; stage.add_child(rim)
	var floor_mesh:=PlaneMesh.new(); floor_mesh.size=Vector2(24,24)
	var floor_mat:=StandardMaterial3D.new(); floor_mat.albedo_color=Color("222a32"); floor_mat.roughness=.95
	var floor_node:=MeshInstance3D.new(); floor_node.mesh=floor_mesh; floor_node.material_override=floor_mat; stage.add_child(floor_node)
	var camera:=Camera3D.new(); camera.position=Vector3(3,3,-14); stage.add_child(camera); camera.current=true; camera.fov=32; camera.look_at(Vector3(0,1.25,0))
	var caption:=Label.new(); caption.position=Vector2(32,26); caption.add_theme_font_size_override("font_size",22); root.add_child(caption)
	var actors: Array[Node3D]=[]
	for group in range(3):
		for old in actors: old.free()
		actors.clear()
		var keys: Array=Actor.HEROES if group==0 else Actor.HOSTILES if group==1 else ["guardian_0","guardian_1","guardian_2","guardian_3"]
		for n in keys.size():
			var actor:=Actor.new(); actor.boss=group==2; actor.hostile=group!=0; actor.kind="boss" if actor.boss else keys[n]
			actor.region_index=n if actor.boss else 0
			actor.position=Vector3((float(n)-float(keys.size()-1)*.5)*2.65,0,1.9)
			if actor.boss: actor.scale=Vector3.ONE*.48
			stage.add_child(actor); actors.append(actor)
			print("NATIVE_3D_MESH ",keys[n]," triangles=",actor.motion_rig.triangles," bones=",actor.motion_rig.skeleton.get_bone_count())
		for f in range(240):
			caption.text=("NYRA · SWORD / STAFF / BOW" if group==0 else "HOSTILES · RAIDER / BULWARK / HEXER / ELITE" if group==1 else "GUARDIANS · BELL / SILT / MOURNING / CINDER")+"\n"+("3D MOTION INSPECTION · STEP / TURN" if f<60 else "3D MOTION INSPECTION · WINDUP / CONTACT / RECOVERY" if f<150 else "3D MOTION INSPECTION · HIT / RETREAT" if f<195 else "3D MOTION INSPECTION · COLLAPSE")
			for actor in actors:
				if f<60:
					var displacement:=Vector3(0,0,-2.0/30.0); actor.position+=displacement; actor.follow_travel(displacement)
					actor.face_toward(Vector3(.8,0,-.4) if f in range(30,47) else Vector3.FORWARD)
				if f in [60,100,140]: actor.strike("signature" if f==140 else "basic",.65)
				if f==160: actor.react(-1,1.1)
				if f==175: actor.retreat()
				if f in range(175,190):
					var displacement:=Vector3(0,0,2.0/30.0); actor.position+=displacement; actor.follow_travel(displacement)
				if f==195: actor.die()
				actor.animate(1.0/30.0,f<60 or f in range(175,190),2.0)
			await process_frame; await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output_dir+"/frame-%04d.png" % frame_index); frame_index+=1
	print("CHARACTER_3D_MOTION_PASS ",frame_index," frames / actual runtime models / 30 FPS")
	quit()
