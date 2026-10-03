extends SceneTree
## Regression contracts for steady room shots, continuous orientation, physical
## action support and identical simulation across all three live 3D classes.
const Actor=preload("res://scripts/dungeon_actor.gd")
const Sim=preload("res://scripts/expedition_simulation.gd")
const World=preload("res://scripts/dungeon_world.gd")
const Bot=preload("res://tests/balance_survey_bot.gd")
var checks:=0
var failures:=0
func _initialize() -> void: run_checks.call_deferred()
func check(value: bool,label: String) -> void:
	checks+=1
	if not value: failures+=1; push_error("FAIL: "+label)
func run_checks() -> void:
	var hero:=Actor.new(); root.add_child(hero); hero.animate(.15,false)
	var before_yaw: float=hero.rotation.y
	hero.face_toward(Vector3(1,0,0)); hero.animate(1.0/60.0,false)
	check(absf(angle_difference(before_yaw,hero.rotation.y))<.30 and hero.scale.x>0,"direction changes turn a real volume continuously without a mirrored silhouette")
	hero.strike("basic",.5,true); hero.sync_attack(.22); hero.animate(.10,false)
	var cast_yaw: float=hero.desired_yaw
	hero.face_toward(Vector3(-1,0,0))
	check(hero.desired_yaw==cast_yaw,"an in-flight cast holds its target orientation")
	var feet: Array[Vector3]=[]
	for bone in [14,17]: feet.append(hero.motion_rig.skeleton.get_bone_global_pose(bone).origin)
	hero.sync_attack(.015); hero.animate(.15,false); hero.release_attack()
	var supported:=true
	for i in range(2): supported=supported and feet[i].distance_to(hero.motion_rig.skeleton.get_bone_global_pose(14 if i==0 else 17).origin)<.012
	check(supported,"loaded body and weapon transfer weight while support ankles stay planted")
	hero.animate(.07,false); hero.strike("sunder",.10,true); hero.sync_attack(.085); hero.animate(.008,false)
	check(hero.external_release and hero.release_time<0.0 and hero.release_attack(),"a following real cast owns its countdown even during recovery")
	hero.animate(.5,false); hero.strike("basic",.4,true); hero.retreat(); hero.animate(.15,true,2.0)
	check(hero.attack_time<0.0 and hero.retreat_time>=0.0,"a real retreat cancels an unreleased cast")
	hero.free()
	var bot:=Bot.new()
	for resolution in [Vector2i(2424,1080),Vector2i(1040,1080),Vector2i(854,480)]:
		root.size=resolution
		for region in range(4):
			var sim:=Sim.new(); bot.character_class="Vowkeeper"
			sim.setup("Vowkeeper",bot._combat_stats(),1+region*10,"Guardian",1979)
			sim.phase="combat"
			var world:=World.new(); world.simulation=sim; world.region_index=region; world.active=false
			root.add_child(world); world.set_process(false)
			world.camera_target=world._camera_anchor(); world.camera_zoom=.94; world._position_camera()
			var transform: Transform3D=world.camera.transform; var zoom: float=world.framing_scale
			var state: String=sim.encode_snapshot(); var old_target: int=sim.target_id; var stable:=true
			for sample in range(24):
				world.hero.strike("heavy"); world.hero.animate(float(sample)/60.0,false)
				world.hero.position.x=sin(sample)*.45
				sim.target_id=int(sim.waves[0][sample%sim.waves[0].size()].id)
				world._kick_camera(3.0); world._position_camera()
				stable=stable and world.camera.transform.is_equal_approx(transform) and world.framing_scale==zoom and world.camera_shake_strength==0.0
			check(stable,"%dx%d region %d: hits, weapon poses, hero shifts and target switches never move or breathe the room camera" % [resolution.x,resolution.y,region])
			sim.target_id=old_target
			check(sim.encode_snapshot()==state,"camera and native animation do not modify simulation state")
			world.free()
		for class_key in Actor.HEROES:
			var sim:=Sim.new(); bot.character_class=class_key
			sim.setup(class_key,bot._combat_stats(),1,"Guardian",1979)
			sim.phase="travel"
			var world:=World.new(); world.simulation=sim; world.character_class=class_key; world.active=false
			root.add_child(world); world.set_process(false)
			var visible:=true; var scale:=0.0
			for sample in range(24):
				world.hero.position=Vector3(.4*sin(sample*.2),0,-sample*1.5)
				world.camera_target=world._camera_anchor(); world._position_camera()
				if sample==0: scale=world.framing_scale
				visible=visible and absf(world.framing_scale-scale)<.0001
				var points: Array[Vector3]=[]; world._append_actor_bounds(points,world.hero)
				for point in points:
					var screen: Vector2=world.camera.unproject_position(point)/Vector2(resolution)
					visible=visible and screen.x>.07 and screen.x<.93 and screen.y>.13 and screen.y<.86
			check(visible,"%dx%d %s: every travel anchor retains the complete spatial figure without accumulating camera retreat" % [resolution.x,resolution.y,class_key])
			world.free()
	for class_key in Actor.HEROES:
		bot.character_class=class_key
		var sim:=Sim.new(); var reference:=Sim.new()
		sim.setup(class_key,bot._combat_stats(),1,"Guardian",1979); reference.setup(class_key,bot._combat_stats(),1,"Guardian",1979)
		var world:=World.new(); world.simulation=sim; world.character_class=class_key; world.active=false
		root.add_child(world); world.set_process(false); world.active=true
		var same:=true
		for frame in range(420):
			world._process(1.0/60.0); reference.advance(1.0/60.0)
			same=same and sim.encode_snapshot()==reference.encode_snapshot()
		check(same,class_key+": rendered 3D actions never change simulation or RNG")
		var before: String=sim.encode_snapshot(); world._update_combat_readability(.2)
		check(sim.encode_snapshot()==before and world.hero.silhouette_focus>.5,class_key+": heroine emphasis is visual only")
		world.hero.die(); world.hero.animate(1.5,false); world._update_combat_readability(.2)
		check(world.hero.silhouette_focus==0 and world.hero.emphasis<.7 and not world.hero_marker.visible,class_key+": the defeated heroine retains corpse treatment")
		world.free()
	bot.free()
	print("ANIMATION CRAFT SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
