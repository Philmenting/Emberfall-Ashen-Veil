extends SceneTree
const Sim=preload("res://scripts/expedition_simulation.gd")
const Store=preload("res://scripts/save_store.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run_checks")
func check(value: bool, description: String) -> void:
	checks+=1
	if value: print("PASS: ",description)
	else:
		failures+=1
		push_error("FAIL: "+description)

func model(selected: String="Arcanist", enabled: bool=true, floor_value: int=1) -> RefCounted:
	var stats: Dictionary={"max_hp":10000,"max_mana":1000,"attack":300,"ability_damage":800,"mana_cost":25,"crit":0.0,"armor":0,"class_mitigation":0,"attributes":{"Spirit":20},"boss_patterns":1}
	if enabled: stats.arcane_tactics=1
	var sim:=Sim.new()
	sim.setup(selected,stats,floor_value,"Tactics Boss",1979)
	return sim

func close_case(selected: String="Arcanist", enabled: bool=true) -> RefCounted:
	var sim:=model(selected,enabled)
	sim.phase="combat"
	sim.hero_pos=Vector2(0,-2.6)
	sim.attack_cd=1.0
	sim.dodge_cd=4.0
	return sim

func run_checks() -> void:
	var sim:=close_case()
	var start: Vector2=sim.hero_pos
	var mana: int=sim.hero_mana
	sim._auto_hero()
	check(sim.hero_pos!=start and sim.hero_pos.distance_to(start)<=sim.WALK_SPEED*sim.STEP+0.0001,"Arcanist moves between attacks at walking speed")
	check(sim.action=="Creating spell distance" and sim.hero_mana==mana and sim.dodge_cd==4.0,"spacing is visible in the action and grants no Mana or dodge reset")
	sim=close_case()
	start=sim.hero_pos
	sim.pending_attack={"target":0,"skill":true,"left":0.3,"name":"Veil Nova"}
	sim._auto_hero()
	check(sim.hero_pos==start and is_equal_approx(sim.pending_attack.left,0.2),"committed casting remains stationary and completes normally")
	sim=close_case()
	start=sim.hero_pos
	sim._warn(sim.waves[0][0],5.0,2.0)
	sim._auto_hero()
	check(sim.hero_pos==start,"spacing does not enter an announced ground hazard")
	for selected in ["Vowkeeper","Ranger"]:
		sim=close_case(selected)
		start=sim.hero_pos
		sim._auto_hero()
		check(sim.hero_pos==start,selected+": Arcanist spacing is not applied")
	sim=close_case("Arcanist",false)
	start=sim.hero_pos
	sim._auto_hero()
	check(sim.hero_pos==start,"old expeditions retain stationary spell recovery")
	sim=close_case()
	sim.stage=2
	sim.hero_pos=Vector2(2.15,-26.0)
	for i in range(25): sim._arcane_reposition()
	check(absf(sim.hero_pos.x)<=2.2001 and sim.hero_pos.distance_to(sim.CHECKPOINTS[2])<=6.5001,"repositioning remains inside the narrow bridge and encounter area")
	for enabled in [false,true]:
		sim=model("Arcanist",enabled)
		sim.phase="combat"
		for i in range(3):
			sim.waves[0][i].pos=Vector2([0.0,4.2,5.0][i],-4)
			sim.waves[0][i].hp=1000
			sim.waves[0][i].max_hp=1000
		sim.pending_attack={"target":0,"skill":true,"left":0.0,"name":"Veil Nova"}
		sim._resolve_hero_attack()
		check(sim.waves[0][0].hp<1000 and (sim.waves[0][1].hp<1000)==enabled and sim.waves[0][2].hp==1000,"Nova uses "+("4.5" if enabled else "legacy 3.2")+" radius without hitting beyond it")
		var pulse: Dictionary={}
		for event in sim.events:
			if event.type=="nova": pulse=event
		check(pulse.get("radius",0.0)==(4.5 if enabled else 3.2) and pulse.position==Vector2(0,-4),"Nova presentation receives the actual impact center and radius")
	sim=close_case()
	sim._auto_hero()
	var restored:=Sim.new()
	check(restored.restore_encoded(sim.encode_snapshot()) and restored.snapshot()==sim.snapshot(),"checkpoint after repositioning restores exactly")
	sim.simulate_to_end()
	restored.simulate_to_end()
	check(sim.snapshot()==restored.snapshot(),"resumed tactics preserve final combat and RNG")
	for invalid in [-1,2,1.0,"enabled"]:
		var bad: Dictionary=sim.snapshot()
		bad.fields.stats.arcane_tactics=invalid
		check(not Sim.new().restore(bad),"invalid tactics flag rejected: "+str(invalid))
	for region in range(4):
		var matching:=true
		for variant in range(64):
			var live:=model("Arcanist",true,region*10+1)
			# Re-seed before any combat; setup generated no random rolls.
			live.rng.seed=posmod(1979+variant*104729,64)+live.floor_id*4099
			var skipped:=Sim.new()
			skipped.restore(live.snapshot())
			while not live.finished: live.advance(0.071)
			skipped.simulate_to_end()
			if [live.won,live.hero_hp,live.hero_mana,live.hero_pos,live.elapsed,live.rng.state]!=[skipped.won,skipped.hero_hp,skipped.hero_mana,skipped.hero_pos,skipped.elapsed,skipped.rng.state]: matching=false
		check(matching,"region %d: all 64 Arcanist tactics outcomes match live/skip" % region)
	var golden: Array=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/arcane_legacy_09.json"))
	for row in golden:
		var old:=model("Arcanist",false,int(row.floor))
		old.simulate_to_end()
		check(old.encode_snapshot().sha256_text()==row.sha256,"exact 0.9 Arcanist reference on floor "+str(row.floor))
	var game: Node=load("res://Main.tscn").instantiate()
	game.save_store=Store.new("user://arcane-tactics-"+str(Time.get_ticks_usec()))
	root.add_child(game)
	game.character_class="Arcanist"
	check(game._combat_stats().arcane_tactics==1,"new Arcanist expeditions enable the tactics rules")
	game._start_run(1)
	game._toggle_run_pause()
	var world: Node=game.run_arena.world
	world._show_event({"type":"nova","position":Vector2(0,-4),"radius":4.5})
	var effect: Dictionary=world.effects.back()
	check(effect.kind=="nova" and is_equal_approx(effect.node.mesh.outer_radius,4.528),"world displays a Nova pulse with the simulated radius")
	world._update_effects(0.5)
	check(world.effects.is_empty(),"Nova effect expires and releases its scene node")
	game.free()
	await process_frame
	print("ARCANE TACTICS SMOKE: ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
