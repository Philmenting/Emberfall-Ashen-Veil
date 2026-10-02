extends SceneTree
## Inspection of actual character meshes, separate from store gameplay screenshots.
const Actor=preload("res://scripts/dungeon_actor.gd")
var output_dir:="/tmp/emberfall-model-art"

func _initialize() -> void: call_deferred("capture_models")

func capture_models() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): output_dir=argument.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size=Vector2i(1200,840)
	root.content_scale_size=Vector2i(1200,840)
	var stage:=Node3D.new(); root.add_child(stage)
	var background:=WorldEnvironment.new()
	var environment:=Environment.new()
	environment.background_mode=Environment.BG_COLOR
	environment.background_color=Color("151b23")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color("aab6cb")
	environment.ambient_light_energy=0.35
	environment.sky=preload("res://scripts/dungeon_lighting.gd").reflection_sky()
	environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	background.environment=environment; stage.add_child(background)
	var key:=DirectionalLight3D.new(); key.rotation_degrees=Vector3(-40,145,0)
	key.light_color=Color("ffe4bb"); key.light_energy=1.1; stage.add_child(key)
	var rim:=DirectionalLight3D.new(); rim.rotation_degrees=Vector3(-27,-36,0)
	rim.light_color=Color("a9b7c4"); rim.light_energy=0.5; stage.add_child(rim)
	var camera:=Camera3D.new(); stage.add_child(camera); camera.current=true
	var caption:=Label.new(); caption.position=Vector2(32,757); caption.add_theme_font_size_override("font_size",21)
	root.add_child(caption)
	for appearance in ["Vowkeeper","Arcanist","Ranger","raider","hexer","bulwark","elite","guardian_0","guardian_1","guardian_2","guardian_3"]:
		var actor:=Actor.new()
		actor.kind=appearance if not appearance.begins_with("guardian") else "boss"
		actor.boss=appearance.begins_with("guardian"); actor.hostile=actor.boss or appearance not in ["Vowkeeper","Arcanist","Ranger"]
		if actor.boss: actor.region_index=int(appearance.right(1))
		stage.add_child(actor)
		actor.animate(0.1,false)
		var target:=Vector3(0,actor.visual_height()*0.49,0)
		camera.position=target+Vector3(3.4,1.0,-5.0)*(2.2 if actor.boss else 1.0)
		camera.fov=34; camera.look_at(target)
		caption.text="EMBERFALL · "+appearance.replace("_"," ").to_upper()+"\n3D MODEL INSPECTION · IN-GAME ASSET"
		for frame in range(5): await process_frame
		await RenderingServer.frame_post_draw
		var capture:=root.get_texture().get_image(); capture.convert(Image.FORMAT_RGB8)
		capture.save_png(output_dir+"/"+appearance+".png")
		actor.free()
	quit()
