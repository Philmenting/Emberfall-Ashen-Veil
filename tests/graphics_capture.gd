extends SceneTree
## Real rendered scenes, isolated from player saves and online progression.
const World=preload("res://scripts/dungeon_world.gd")
const Sim=preload("res://scripts/expedition_simulation.gd")
const Bot=preload("res://tests/balance_survey_bot.gd")
var capture_dir:=OS.get_environment("EMBERFALL_CAPTURE_DIR")

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	if capture_dir.is_empty():
		push_error("EMBERFALL_CAPTURE_DIR is required")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(capture_dir)
	root.size=Vector2i(1280,720)
	root.msaa_3d=Viewport.MSAA_2X if OS.get_environment("EMBERFALL_CAPTURE_BASELINE")=="1" else Viewport.MSAA_4X
	var game:=Bot.new()
	for region in range(4):
		for scene_kind in ["Vowkeeper","Arcanist","Ranger","Boss"]:
			var kind: String="Vowkeeper" if scene_kind=="Boss" else scene_kind
			game.character_class=kind
			var sim:=Sim.new()
			sim.setup(kind,game._combat_stats(),1+region*10,"Guardian",1979)
			if scene_kind=="Boss":
				# A stationary display fixture, never a progression or balance claim.
				sim.stage=5
				sim.phase="combat"
				sim.hero_pos=sim.checkpoint(5)+Vector2(0,2.8)
				sim.target_id=50
			else:
				sim.advance(3.5)
			var before:=sim.encode_snapshot()
			var world:=World.new()
			world.simulation=sim
			world.region_index=region
			world.character_class=kind
			world.active=false
			root.add_child(world)
			world.hero.rotation.y=0.4
			for actor in world.enemies:
				var facing: Vector3=world.hero.position-actor.position
				actor.rotation.y=atan2(-facing.x,-facing.z)
			for frame in range(12):
				await process_frame
				world.hero.animate(1.0/60.0,false)
			world.hero.strike()
			world.hero.animate(0.20,false)
			await RenderingServer.frame_post_draw
			var label: String=["spire","archive","ossuary","citadel"][region]+"-"+scene_kind.to_lower()
			var image:=root.get_texture().get_image()
			if image.save_png(capture_dir.path_join(label+".png"))!=OK:
				push_error("Could not save "+label)
				quit(1)
				return
			print("CAPTURE ",label," draws=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
			if sim.encode_snapshot()!=before:
				push_error("Visual capture altered simulation")
				quit(1)
				return
			if region==0 and scene_kind!="Boss":
				world.camera.position=world.hero.position+Vector3(1.3,1.95,-3.1)
				world.camera.look_at(world.hero.position+Vector3(0,1.23,0))
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(capture_dir.path_join("portrait-"+kind.to_lower()+".png"))
			world.free()
			await process_frame
	game.free()
	quit()

