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
	var result:=Vector3(actor.right_arm.rotation.x,actor.left_arm.rotation.x,actor.body.rotation.y)
	actor.free()
	return result
func run_checks() -> void:
	var profile:=Sculpt.profile([Vector4(0,1,1,0),Vector4(1,1,1,0)])
	var arrays:=profile.surface_get_arrays(0)
	var outward:=true
	for i in range(arrays[Mesh.ARRAY_VERTEX].size()):
		var point: Vector3=arrays[Mesh.ARRAY_VERTEX][i]
		var normal: Vector3=arrays[Mesh.ARRAY_NORMAL][i]
		if Vector2(point.x,point.z).length()>0.5 and absf(normal.y)<0.99: outward=outward and Vector2(point.x,point.z).dot(Vector2(normal.x,normal.z))>0.0
	check(outward,"sculpted character surfaces face outward")
	var bevel:=Sculpt.bevelled_box()
	var bevel_arrays:=bevel.surface_get_arrays(0)
	var bevel_outward:=true
	for i in range(bevel_arrays[Mesh.ARRAY_VERTEX].size()):
		var point: Vector3=bevel_arrays[Mesh.ARRAY_VERTEX][i]
		var normal: Vector3=bevel_arrays[Mesh.ARRAY_NORMAL][i]
		bevel_outward=bevel_outward and point.dot(normal)>0.3 and normal.is_normalized()
	check(bevel_outward,"beveled armor and architecture have finite outward normals")
	check(Sculpt.bevelled_box()==bevel,"beveled geometry is shared across static batches")
	var mantle_arrays:=Sculpt.mantle().surface_get_arrays(0)
	var front:=false
	var back:=false
	for normal: Vector3 in mantle_arrays[Mesh.ARRAY_NORMAL]:
		front=front or normal.z< -0.5
		back=back or normal.z>0.5
	check(front and back,"folded mantle is visible from both sides")
	var smooth:=true
	for normal: Vector3 in arrays[Mesh.ARRAY_NORMAL]:
		smooth=smooth and normal.is_normalized()
	check(smooth,"profile normals remain normalized at seams and end caps")
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
		check(actor.find_child("ContactShadow",true,false)!=null and actor.left_knee!=null and actor.right_knee!=null,kind+": model retains shadow and articulated joints")
		var finite:=true
		for node in actor.find_children("*","MeshInstance3D",true,false):
			for surface in range(node.mesh.get_surface_count()):
				for vertex in node.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]: finite=finite and vertex.is_finite()
		actor.strike()
		for i in range(20): actor.animate(0.016,true)
		actor.die(); actor.animate(0.2,false)
		check(finite and actor.body.position.is_finite(),kind+": geometry and movement stay finite")
		actor.queue_free()
	for row in [["Vowkeeper","bastion"],["Arcanist","starfall"],["Ranger","rain"]]:
		var basic_pose:=attack_pose(row[0],"basic")
		var technique_pose:=attack_pose(row[0],row[1])
		check(basic_pose.distance_to(technique_pose)>0.15,row[0]+": equipped technique uses its own anticipation pose")
	var first:=Actor.new()
	first.kind="Arcanist"
	root.add_child(first)
	var size_before:=Actor.merged_cache.size()
	var second:=Actor.new()
	second.kind="Arcanist"
	root.add_child(second)
	check(Actor.merged_cache.size()==size_before,"repeated character appearances reuse merged geometry")
	first.queue_free(); second.queue_free()
	var runner:=Actor.new()
	runner.kind="Ranger"
	root.add_child(runner)
	var initial_phase: float=runner.gait_phase
	runner.animate(0.2,true,3.4)
	check(runner.gait_phase>initial_phase,"running cadence advances with actual travel speed")
	check(is_equal_approx(runner.left_leg.rotation.x,-runner.right_leg.rotation.x),"locomotion keeps left and right steps in opposition")
	runner.strike()
	runner.animate(0.30,false)
	check(runner.body.position.z< -0.05,"attack animation has a visible forward follow-through")
	runner.react()
	runner.animate(0.06,false)
	check(runner.impact_time>=0.0 and absf(runner.body.rotation.z)>0.01,"enemy reacts to a hit with a short flinch")
	runner.strike(); runner.strike()
	check(runner.attack_queued,"rapid attacks queue without restarting the current swing")
	runner.animate(0.65,false)
	check(runner.attack_time==0.0 and not runner.attack_queued,"queued swing begins after recovery")
	runner.die(); runner.animate(0.16,false)
	check(runner.body.position.y<0.0 and absf(runner.body.rotation.z)>0.01,"death animation falls with a varied lean")
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
		check(world.scene_environment.glow_enabled and world.scene_environment.sky!=null,"region %d: reflective lighting and glow are configured" % region)
		world.set_shadows(false)
		var battery_rays_hidden:=true
		for ray in world.decorative_rays: battery_rays_hidden=battery_rays_hidden and not ray.visible
		check(not world.scene_environment.glow_enabled and battery_rays_hidden and not world.sun.shadow_enabled,"region %d: battery mode disables the added lighting cost" % region)
		world.set_shadows(true)
		check(world.scene_environment.glow_enabled and world.decorative_rays[0].visible,"region %d: normal quality restores decorative lighting" % region)
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
