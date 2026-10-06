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
func actual_boot_floors(rig: RefCounted) -> Vector2:
	var low:=Vector2(INF,INF)
	# These probes are indexed native boot vertices with all original skin
	# influences; no legacy ankle socket or contact-plane proxy participates.
	for probe in rig.floor_probes:
		var point:=Vector3.ZERO
		for i in probe.bones.size():
			point+=(rig.skeleton.get_bone_global_pose(probe.bones[i])*probe.binds[i]*probe.point)*probe.weights[i]
		point=rig.motion_node.transform*point
		low[probe.side]=minf(low[probe.side],point.y)
	return low

func check_native_sword_boot_support(hero: Node3D) -> void:
	var rig: RefCounted=hero.motion_rig
	var feet: Array[int]=[rig.skeleton.find_bone("foot_l"),rig.skeleton.find_bone("foot_r")]
	check(hero.source_avatar and rig.skeleton.get_bone_count()==65 and feet[0]>=0 and feet[1]>=0,"sword support uses both named native65 boots")
	var reference:=Actor.new();root.add_child(reference)
	var source: RefCounted=reference.motion_rig
	var release: float=source.player.get_animation("Sword_Regular_A").length*.62
	var original_motion:=true
	var clearance:=true
	var starts:=Vector2.ZERO
	var peak:=Vector2.ZERO
	var path: Array[Vector3]=[]
	for sample in range(31):
		var phase:=float(sample)/30.0
		hero.sync_attack(hero.attack_duration*(1.0-phase));hero.animate(0.0,false)
		# Read the unmodified artist sample independently of the production
		# actor's clip selector, blending, floor offset and weapon posing.
		source._sample("Sword_Regular_A",release*phase)
		for side in 2:
			original_motion=original_motion and rig.skeleton.get_bone_global_pose(feet[side]).is_equal_approx(source.skeleton.get_bone_global_pose(source.skeleton.find_bone("foot_l" if side==0 else "foot_r")))
		var floor:=actual_boot_floors(rig)
		if sample==0:starts=floor
		peak=Vector2(maxf(peak.x,floor.x),maxf(peak.y,floor.y))
		clearance=clearance and floor.is_finite() and minf(floor.x,floor.y)>=.0029
		path.append(rig._point("foot_l"));path.append(rig._point("foot_r"))
	check(original_motion,"both actual native feet follow the original artist Sword A transforms throughout preparation")
	# Sword A contains a two-boot hop, not the former synthetic one-boot
	# lunge. Preserve its real weight movement and measure its visible soles.
	check(peak.x>starts.x+.10 and peak.y>starts.y+.10 and path[0].distance_to(path[-2])>.25 and path[1].distance_to(path[-1])>.20,"the original sword hop lifts both actually weighted boots and carries both native feet through the cut")
	var contact: Array[Transform3D]=[]
	for foot in feet:contact.append(rig.skeleton.get_bone_global_pose(foot))
	hero.release_attack()
	var continuous:=true
	for side in 2:continuous=continuous and contact[side].is_equal_approx(rig.skeleton.get_bone_global_pose(feet[side]))
	check(continuous,"simulation release preserves both exact native boot transforms into sword recovery")
	for sample in range(30):
		hero.animate(.34/30.0,false)
		var floor:=actual_boot_floors(rig)
		clearance=clearance and floor.is_finite() and minf(floor.x,floor.y)>=.0029
	var landed:=actual_boot_floors(rig)
	check(clearance,"all actual weighted sword soles clear the floor throughout the complete hop and recovery")
	check(minf(landed.x,landed.y)<=.0031 and landed.x<.02 and landed.y<.02 and peak.x-landed.x>.10 and peak.y-landed.y>.10,"the complete native sword recovery lands a real support sole at 3 mm and returns both boots to their grounded guard")
	print("NATIVE SWORD SUPPORT: start=",starts," peak=",peak," landed=",landed," foot_l travel=",path[0].distance_to(path[-2])," foot_r travel=",path[1].distance_to(path[-1]))
	reference.free()

func run_checks() -> void:
	var hero:=Actor.new(); root.add_child(hero); hero.animate(.15,false)
	var before_yaw: float=hero.rotation.y
	hero.face_toward(Vector3(1,0,0)); hero.animate(1.0/60.0,false)
	check(absf(angle_difference(before_yaw,hero.rotation.y))<.30 and hero.scale.x>0,"direction changes turn a real volume continuously without a mirrored silhouette")
	hero.strike("basic",.5,true); hero.sync_attack(.22); hero.animate(.10,false)
	var cast_yaw: float=hero.desired_yaw
	hero.face_toward(Vector3(-1,0,0))
	check(hero.desired_yaw==cast_yaw,"an in-flight cast holds its target orientation")
	check_native_sword_boot_support(hero)
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
		var has_settled:=false;var clear_after_collapse:=true
		for actor in world.actor_by_id.values():
			if not actor.boss and actor.death_time>2.2:
				has_settled=true;clear_after_collapse=clear_after_collapse and not actor.visible
		check(has_settled and clear_after_collapse,class_key+": completed collapses leave the active weapon and feet readable without changing rewards")
		var before: String=sim.encode_snapshot(); world._update_combat_readability(.2)
		check(sim.encode_snapshot()==before and world.hero.silhouette_focus>.5,class_key+": heroine emphasis is visual only")
		world.hero.die(); world.hero.animate(1.5,false); world._update_combat_readability(.2)
		check(world.hero.silhouette_focus==0 and world.hero.emphasis<.7 and not world.hero_marker.visible,class_key+": the defeated heroine retains corpse treatment")
		world.free()
	bot.free()
	print("ANIMATION CRAFT SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
