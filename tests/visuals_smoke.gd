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
func run_checks() -> void:
	var profile:=Sculpt.profile([Vector4(0,1,1,0),Vector4(1,1,1,0)])
	var arrays:=profile.surface_get_arrays(0)
	var outward:=true
	for i in range(arrays[Mesh.ARRAY_VERTEX].size()):
		var point: Vector3=arrays[Mesh.ARRAY_VERTEX][i]
		var normal: Vector3=arrays[Mesh.ARRAY_NORMAL][i]
		if Vector2(point.x,point.z).length()>0.5: outward=outward and Vector2(point.x,point.z).dot(Vector2(normal.x,normal.z))>0.0
	check(outward,"sculpted character surfaces face outward")
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
	var first:=Actor.new()
	first.kind="Arcanist"
	root.add_child(first)
	var size_before:=Actor.merged_cache.size()
	var second:=Actor.new()
	second.kind="Arcanist"
	root.add_child(second)
	check(Actor.merged_cache.size()==size_before,"repeated character appearances reuse merged geometry")
	first.queue_free(); second.queue_free()
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
