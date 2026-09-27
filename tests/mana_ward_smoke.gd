extends SceneTree
const Sim=preload("res://scripts/expedition_simulation.gd")
const Store=preload("res://scripts/save_store.gd")
var checks:=0
var failures:=0

func _initialize() -> void:
	call_deferred("run_checks")

func check(value: bool,description: String) -> void:
	checks+=1
	if value: print("PASS: ",description)
	else:
		failures+=1
		push_error("FAIL: "+description)

func model(selected: String="Arcanist",fraction: float=0.35) -> RefCounted:
	var stats: Dictionary={"max_hp":1000,"max_mana":100,"attack":200,"ability_damage":600,"mana_cost":20,"armor":0,"crit":5.0,"class_mitigation":0,"attributes":{"Spirit":16},"mana_guard":fraction}
	var simulation:=Sim.new()
	simulation.setup(selected,stats,4,"Ward Test Boss",1991)
	return simulation

func run_checks() -> void:
	var simulation:=model()
	var enemy: Dictionary=simulation.waves[0][0]
	simulation._hurt_hero(enemy,100.0)
	check(simulation.hero_hp==935 and simulation.hero_mana==30,"35 damage absorbed at a cost of 70 Mana")
	check(simulation.events[0].type=="ward" and simulation.events[0].absorbed==35 and simulation.events[1].damage==65,"visual events report absorbed and actual health damage separately")
	simulation.events.clear()
	simulation._hurt_hero(enemy,100.0)
	check(simulation.hero_hp==840 and simulation.hero_mana==20,"partial ward uses only Mana above one ability cast")
	simulation.events.clear()
	simulation._hurt_hero(enemy,100.0)
	check(simulation.hero_hp==740 and simulation.hero_mana==20 and simulation.events.size()==1,"reserve prevents absorption without preventing incoming damage")
	simulation.hero_mana=21
	simulation._hurt_hero(enemy,10.0)
	check(simulation.hero_mana==21 and simulation.hero_hp==730,"odd Mana cannot buy fractional absorption or cross the reserve")
	simulation.hero_mana=0
	simulation._hurt_hero(enemy,20.0)
	check(simulation.hero_mana==0 and simulation.hero_hp==710,"empty Mana never becomes negative")
	simulation=model()
	simulation.stats.armor=180
	simulation._hurt_hero(enemy,200.0)
	check(simulation.hero_hp==935 and simulation.hero_mana==30,"ward applies after armor mitigation")
	simulation=model()
	simulation._hurt_hero(enemy,1.0)
	check(simulation.hero_hp==999 and simulation.hero_mana==100,"minimum hit does not create free absorption")
	for selected in ["Vowkeeper","Ranger"]:
		simulation=model(selected)
		simulation._hurt_hero(enemy,100.0)
		check(simulation.hero_hp==900 and simulation.hero_mana==100,selected+": ward is exclusive to Arcanist")
	var legacy:=model()
	legacy.stats.erase("mana_guard")
	var restored:=Sim.new()
	check(restored.restore(legacy.snapshot()) and not restored.stats.has("mana_guard"),"old expedition checkpoint retains its original rules")
	legacy.simulate_to_end()
	restored.simulate_to_end()
	check(restored.snapshot()==legacy.snapshot(),"old checkpoint produces exactly the same outcome after update")
	simulation=model()
	simulation.advance(9.37)
	var original: Dictionary=simulation.snapshot()
	restored=Sim.new()
	check(restored.restore_encoded(simulation.encode_snapshot()) and restored.snapshot()==original,"ward combat checkpoint restores bit-exactly")
	simulation.simulate_to_end()
	restored.simulate_to_end()
	check(restored.snapshot()==simulation.snapshot(),"ward checkpoint preserves final outcome and RNG")
	for invalid in [-0.1,0.51,INF,NAN,"ward"]:
		var bad: Dictionary=original.duplicate(true)
		bad.fields.stats.mana_guard=invalid
		check(not Sim.new().restore(bad),"invalid ward stat rejected: "+str(invalid))
	var game: Node=load("res://Main.tscn").instantiate()
	game.save_store=Store.new("user://ward-"+str(Time.get_ticks_usec()))
	game.clock_source=func(): return 1790516000.0
	root.add_child(game)
	game.character_class="Arcanist"
	check(game._combat_stats().mana_guard==0.35,"new Arcanist expeditions receive the ward stat")
	var normal_stats: Dictionary=game._combat_stats()
	game.allocated_attributes.Spirit=10
	check(game._combat_stats().max_mana-normal_stats.max_mana==90,"Spirit adds a usable defensive Mana pool")
	game.allocated_attributes.Spirit=0
	var live: RefCounted=game._new_expedition(8,77)
	var skipped: RefCounted=game._new_expedition(8,77)
	var ward_events:=0
	while not live.finished:
		for event in live.advance(1.0/60.0):
			if event.type=="ward": ward_events+=1
	skipped.simulate_to_end()
	check(live.won==skipped.won and live.hero_hp==skipped.hero_hp and live.hero_mana==skipped.hero_mana and live.rng.state==skipped.rng.state,"live and skipped ward combat remain identical")
	check(ward_events>0 and live.casts>0,"automatic combat uses both ward and Nova")
	game._start_run(1)
	check(game.combat_hud.has("ward") and game.run_arena.world.ward_shell!=null,"Arcanist world and HUD expose ward feedback")
	game.run_arena.world._show_event({"type":"ward","absorbed":7,"mana_spent":14,"source":0})
	check(game.run_arena.world.ward_shell.visible,"absorbing damage displays the shield shell")
	game.run_arena.world._process(0.4)
	check(not game.run_arena.world.ward_shell.visible,"shield feedback expires without changing the simulation rules")
	game._toggle_run_pause()
	var saved: Dictionary=game.expedition.snapshot()
	game._save_progress()
	game._load_progress()
	check(game.expedition.snapshot()==saved and not game.run_active,"game save preserves a paused ward-enabled expedition")
	game.free()
	await process_frame
	print("MANA WARD SMOKE: ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
