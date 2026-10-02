extends SceneTree
## Native motion inspection of actual runtime actors, not advertised gameplay.
const Actor=preload("res://scripts/dungeon_actor.gd")
var output_dir:="/tmp/emberfall-motion"
var quick:=false
var frame_index:=0
func _initialize() -> void: call_deferred("capture_motion")
func capture_motion() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): output_dir=argument.trim_prefix("--capture-dir=")
		if argument=="--quick": quick=true
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size=Vector2i(1280,720); root.content_scale_size=Vector2i(1280,720)
	var stage:=Node3D.new(); root.add_child(stage)
	var background:=WorldEnvironment.new(); var environment:=Environment.new()
	environment.background_mode=Environment.BG_COLOR; environment.background_color=Color("151b23")
	background.environment=environment; stage.add_child(background)
	var camera:=Camera3D.new(); camera.position=Vector3(0,2.5,11)
	stage.add_child(camera); camera.current=true; camera.fov=32; camera.look_at(Vector3(0,1.25,0))
	var caption:=Label.new(); caption.position=Vector2(32,26); caption.add_theme_font_size_override("font_size",23); root.add_child(caption)
	var actors: Array=[]
	for group in range(3):
		for old in actors: old.free()
		actors.clear()
		var keys: Array=["Vowkeeper","Arcanist","Ranger"] if group==0 else ["raider","bulwark","hexer","elite"] if group==1 else ["guardian_0","guardian_1","guardian_2","guardian_3"]
		keys=keys.filter(func(key: String) -> bool: return ResourceLoader.exists("res://assets/characters/motion/"+key.to_lower()+".png"))
		for n in range(keys.size()):
			var actor:=Actor.new(); actor.boss=group==2; actor.hostile=group!=0
			actor.kind="boss" if actor.boss else keys[n]; actor.region_index=n if actor.boss else 0
			actor.position.x=(float(n)-float(keys.size()-1)*.5)*(2.8 if group==0 else 2.6)
			if actor.boss: actor.scale=Vector3.ONE*.48
			stage.add_child(actor); actors.append(actor)
			print("MOTION_MESH ",keys[n]," ",actor.painted_model.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()," vertices / ",actor.motion_rig.skeleton.get_bone_count()," bones")
		for f in range(240):
			caption.text=("NYRA · SWORD / STAFF / BOW" if group==0 else "HOSTILES · RAIDER / BULWARK / HEXER / ELITE" if group==1 else "GUARDIANS · BELL / SILT / MOURNING / CINDER")+"\n"+("CONTINUOUS STEP" if f<60 else ("WINDUP → CONTACT → RECOVERY" if f<150 else ("HIT / RETREAT" if f<195 else "COLLAPSE")))
			for actor in actors:
				if f in [60,100,140]: actor.strike("heavy" if actor.boss and f==140 else "basic",.65)
				if f==160: actor.react()
				if f==175: actor.retreat()
				if f==195: actor.die()
				actor.animate(1.0/30.0,f<60,2.0)
			if not quick or f in [0,15,30,45,70,79,84,90,109,124,164,180,200,205,211,225]:
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(output_dir+"/"+("inspect-%d-%03d.png" % [group,f] if quick else "frame-%04d.png" % frame_index))
				frame_index+=1
	print("PAINTED_MOTION_CAPTURE_PASS ",frame_index," real renderer frames")
	quit()
