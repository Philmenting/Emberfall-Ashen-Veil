extends SceneTree
const Sculpt=preload("res://scripts/sculpted_mesh.gd")
const Actor=preload("res://scripts/dungeon_actor.gd")
const World=preload("res://scripts/dungeon_world.gd")
const Sim=preload("res://scripts/expedition_simulation.gd")
const Bot=preload("res://tests/balance_survey_bot.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run_checks")
func check(ok: bool, label: String) -> void:
	checks+=1
	if ok: print("PASS: ",label)
	else: failures+=1; push_error("FAIL: "+label)
func attack_pose(kind: String, style: String) -> Vector3:
	var actor:=Actor.new()
	actor.kind=kind
	root.add_child(actor)
	actor.strike(style)
	actor.animate(0.08,false)
	# Source65 uses its original PBR materials; the legacy shader's action
	# uniform is not part of that renderer. Gameplay/VFX emphasis still applies.
	var shader_emphasis=0.0 if actor.source_avatar else float(actor.surface_material.get_shader_parameter("action_intensity"))
	var result:=Vector3(float(actor.pose_frame),actor.action_intensity,shader_emphasis)
	actor.free()
	return result
func run_checks() -> void:
	var profile:=Sculpt.profile([Vector4(0,1,1,0),Vector4(1,1,1,0)])
	var arrays:=profile.surface_get_arrays(0)
	var outward:=true
	for i in range(arrays[Mesh.ARRAY_VERTEX].size()):
		var point: Vector3=arrays[Mesh.ARRAY_VERTEX][i]
		var normal: Vector3=arrays[Mesh.ARRAY_NORMAL][i]
		if Vector2(point.x,point.z).length()>0.5: outward=outward and Vector2(point.x,point.z).dot(Vector2(normal.x,normal.z))>0.0
	check(outward,"shared architectural profile surfaces face outward")
	var floor_mesh:=Sculpt.paver()
	var floor_arrays:=floor_mesh.surface_get_arrays(0)
	var up:=true
	for i in range(floor_arrays[Mesh.ARRAY_VERTEX].size()):
		if floor_arrays[Mesh.ARRAY_VERTEX][i].y>0.49: up=up and floor_arrays[Mesh.ARRAY_NORMAL][i].y>0.0
	check(up,"beveled paver top surfaces face upward")
	for kind in ["Vowkeeper","Arcanist","Ranger","raider","bulwark","hexer","elite","boss"]:
		var actor:=Actor.new()
		actor.kind=kind; actor.hostile=kind not in ["Vowkeeper","Arcanist","Ranger"]; actor.boss=kind=="boss"
		root.add_child(actor)
		check(actor.find_child("ContactShadow",true,false)!=null and actor.model.skin!=null,kind+": 3D actor retains contact shadow and native GPU skinning")
		var finite:=true
		for node in actor.find_children("*","MeshInstance3D",true,false):
			for surface in range(node.mesh.get_surface_count()):
				for vertex in node.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]: finite=finite and vertex.is_finite()
		actor.strike()
		for i in range(20): actor.animate(0.016,true)
		actor.die(); actor.animate(0.2,false)
		check(finite and actor.body.position.is_finite(),kind+": spatial geometry, animation clips and movement stay finite")
		actor.queue_free()
	for row in [["Vowkeeper","sunder"],["Arcanist","starfall"],["Ranger","rain"]]:
		var basic_pose:=attack_pose(row[0],"basic")
		var technique_pose:=attack_pose(row[0],row[1])
		check(basic_pose.distance_to(technique_pose)>0.15,row[0]+": actual signature style supplies stronger action emphasis")
	var first:=Actor.new()
	first.kind="Arcanist"
	root.add_child(first)
	var size_before:=Actor.appearance_cache.size()
	var second:=Actor.new()
	second.kind="Arcanist"
	root.add_child(second)
	check(Actor.appearance_cache.size()==size_before,"repeated characters share the authored 3D geometry")
	first.queue_free(); second.queue_free()
	var runner:=Actor.new()
	runner.kind="Ranger"
	root.add_child(runner)
	var initial_phase: float=runner.gait_phase
	runner.animate(0.2,true,3.4)
	check(runner.gait_phase>initial_phase,"running cadence advances with actual travel speed")
	var first_stride:=runner.pose_frame
	runner.animate(0.23,true,3.4)
	check(first_stride in [1,2] and runner.pose_frame in [1,2] and runner.pose_frame!=first_stride,"continuous locomotion alternates grounded left/right support")
	runner.strike()
	runner.animate(0.30,false)
	check(runner.pose_frame==4,"attack motion reaches its contact state at the configured release")
	runner.react()
	runner.animate(0.06,false)
	check(runner.impact_time>=0.0 and runner.hit_strength>0.1,"enemy reacts to an actual hit with a short surface flash and lean")
	runner.strike(); runner.strike()
	check(runner.attack_queued,"rapid attacks queue without restarting the current swing")
	runner.animate(0.65,false)
	check(runner.attack_time==0.0 and not runner.attack_queued,"queued swing begins after recovery")
	runner.die(); runner.animate(1.0,false)
	check(runner.pose_frame==5 and runner.death_time>0.0,"death animation displays the continuous skinned corpse")
	runner.queue_free()
	var game:=Bot.new()
	game.character_class="Arcanist"
	for region in range(4):
		var sim:=Sim.new()
		sim.setup("Arcanist",game._combat_stats(),1+region*10,"Guardian",1979)
		var before:=sim.encode_snapshot()
		var world:=World.new()
		world.simulation=sim; world.region_index=region; world.character_class="Arcanist"; world.active=false
		root.add_child(world)
		await process_frame
		check(sim.encode_snapshot()==before,"region %d: visual setup does not alter combat or RNG" % region)
		check(world.find_child("LowCryptMist",true,false)!=null and world.find_child("DungeonDust",true,false)!=null,"region %d: mist and dust are present" % region)
		check((world.find_child("FloodedArchive",true,false)!=null)==(region==1) and (world.find_child("LavaBasin",true,false)!=null)==(region==3),"region %d: animated regional surfaces retained" % region)
		var carved_floor_count:=0
		var continuous_floor_count:=0
		var carved_floor_unshadowed:=true
		for batch in world.find_children("*","MultiMeshInstance3D",true,false):
			if batch.material_override==world.materials.intarsia:
				carved_floor_count+=batch.multimesh.instance_count
				carved_floor_unshadowed=carved_floor_unshadowed and batch.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if batch.material_override==world.court_material:
				continuous_floor_count+=batch.multimesh.instance_count
				carved_floor_unshadowed=carved_floor_unshadowed and batch.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Module thresholds and perimeter paving now share the court material.
		# Their instance count is not the number of continuous floor surfaces.
		check(carved_floor_count==1 and continuous_floor_count>=1 and carved_floor_unshadowed,"region %d: court and regional paving remain unshadowed with one guardian inlay" % region)
		world.reduced_motion=true
		world.set_shadows(false)
		var battery_hidden:=not world.sun.shadow_enabled
		for beam in world.sanctuary_beams: battery_hidden=battery_hidden and not beam.visible
		for light in world.sanctuary_lights: battery_hidden=battery_hidden and not light.visible
		var ruin_materials:Dictionary=world.get_meta("ruin_material_cache",{})
		for family in ["masonry","dressed_stone"]:
			battery_hidden=battery_hidden and ruin_materials.has(family) and is_zero_approx(ruin_materials[family].get_shader_parameter("relief"))
		check(battery_hidden and sim.encode_snapshot()==before,"region %d: Battery removes decorative lighting without changing combat" % region)
		world.set_shadows(true)
		var quality_restored:=world.sun.shadow_enabled
		for beam in world.sanctuary_beams: quality_restored=quality_restored and beam.visible
		for light in world.sanctuary_lights: quality_restored=quality_restored and light.visible
		for family in ["masonry","dressed_stone"]:
			quality_restored=quality_restored and float(ruin_materials[family].get_shader_parameter("relief"))>0.0
		check(quality_restored and is_zero_approx(world.sanctuary_beam_material.get_shader_parameter("motion")),"region %d: quality returns while reduced motion freezes beam drift" % region)
		world.reduced_motion=false
		world.set_shadows(true)
		var pattern: Dictionary=world.BossPatterns.create(region,sim.checkpoint(0),sim.hero_pos,false)
		var warning_visual: Node3D=world._pattern_visual(pattern.zones,Color("f05f40"),0.32,true)
		var bounds: AABB=warning_visual.get_child(0).mesh.get_aabb()
		world._update_warning(warning_visual,pattern)
		var early: float=warning_visual.get_child(0).material_override.get_shader_parameter("progress")
		pattern.left=pattern.total*0.25
		world._update_warning(warning_visual,pattern)
		check(is_equal_approx(early,0.0) and is_equal_approx(warning_visual.get_child(0).material_override.get_shader_parameter("progress"),0.75),"region %d: hazard shading reflects actual countdown" % region)
		check(warning_visual.scale==Vector3.ONE and warning_visual.get_child(0).mesh.get_aabb()==bounds,"region %d: countdown preserves the full collision footprint" % region)
		warning_visual.queue_free()
		world._launch_projectile(int(sim.waves[0][0].id),Color.WHITE)
		var palm:Vector3=world.hero.body.to_global(world.hero.motion_rig.palm_position(0))
		check(Vector3(world.effects.back().origin).distance_to(palm)<.0001,"region %d: spell release originates at the animated casting palm" % region)
		world._update_effects(0.04)
		check(world.effects.back().node.position.distance_to(Vector3(world.effects.back().origin))>0.1,"region %d: ranged projectile travels toward its target" % region)
		world._impact_sparks(Vector3.ZERO,Color.WHITE)
		world._slash_arc(Vector3.ZERO,Color.WHITE)
		world._update_effects(1.0)
		await process_frame
		check(world.effects.is_empty() and sim.encode_snapshot()==before,"region %d: combat VFX clean up without affecting simulation" % region)
		world.queue_free()
		await process_frame
	game.free()
	print("VISUALS SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
