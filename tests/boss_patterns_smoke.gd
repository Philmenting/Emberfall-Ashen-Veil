extends SceneTree
const Sim=preload("res://scripts/expedition_simulation.gd")
const Patterns=preload("res://scripts/boss_patterns.gd")
const Store=preload("res://scripts/save_store.gd")
var checks:=0
var failures:=0

func _initialize() -> void:
	call_deferred("run_checks")

func check(value: bool, description: String) -> void:
	checks+=1
	if value: print("PASS: ",description)
	else:
		failures+=1
		push_error("FAIL: "+description)

func model(region: int, selected: String="Vowkeeper", variant: int=0) -> RefCounted:
	var stats: Dictionary={"max_hp":10000,"max_mana":1000,"attack":300,"ability_damage":800,"mana_cost":25,"crit":5.0,"armor":0,"class_mitigation":0,"attributes":{"Spirit":20},"boss_patterns":1}
	var sim:=Sim.new()
	sim.setup(selected,stats,region*10+1,"Pattern Boss",1979+variant*104729)
	return sim

func boss_case(region: int, awakened: bool=false) -> RefCounted:
	var sim:=model(region)
	sim.stage=5
	sim.phase="combat"
	sim.hero_pos=Vector2(0,-60)
	sim.waves[5][1].hp=0
	sim.waves[5][2].hp=0
	var boss: Dictionary=sim.waves[5][0]
	boss.awakened=awakened
	boss.warning=Patterns.create(region,boss.pos,sim.hero_pos,awakened)
	boss.cooldown=999.0
	boss.special_cd=999.0
	return sim

func run_checks() -> void:
	var ring: Dictionary=Patterns.create(0,Vector2.ZERO,Vector2(0,3),false).zones[0]
	check(not Patterns.contains(ring,Vector2.ZERO) and Patterns.contains(ring,Vector2(0,3)) and not Patterns.contains(ring,Vector2(0,5)),"bell ring has a safe center and exterior")
	var beam: Dictionary=Patterns.create(1,Vector2.ZERO,Vector2(3,3),false).zones[0]
	check(Patterns.contains(beam,Vector2(5,5)) and not Patterns.contains(beam,Vector2(5,2)),"tidal lane uses its committed direction")
	var grave: Dictionary=Patterns.create(2,Vector2.ZERO,Vector2(0,3),false)
	check(grave.zones.size()==3 and Patterns.threatens(grave,Vector2(2.3,3)) and not Patterns.threatens(grave,Vector2(0,5)),"grave bloom has three distinct blast circles")
	var cross: Dictionary=Patterns.create(3,Vector2.ZERO,Vector2(0,3),false)
	check(Patterns.threatens(cross,Vector2(4,3)) and Patterns.threatens(cross,Vector2(0,7)) and not Patterns.threatens(cross,Vector2(2,5)),"furnace cross leaves safe diagonal sectors")
	for region in range(4):
		var sim:=boss_case(region)
		var boss: Dictionary=sim.waves[5][0]
		var warning: Dictionary=boss.warning.duplicate(true)
		check(Patterns.valid(warning),"region %d: generated warning validates" % region)
		var safe: Vector2=sim._safe_boss_escape()
		check(not Patterns.threatens(warning,safe,0.3) and safe.x>=-5.8 and safe.x<=5.8 and safe.y>=-67,"region %d: escape stays inside walkable bounds" % region)
		boss.warning.left=0.8
		sim._auto_hero()
		check(sim.dodging and sim.dodges==1,"region %d: hero reacts automatically" % region)
		while not boss.warning.is_empty(): sim.advance(0.1)
		check(sim.hero_hp==10000 and not Patterns.threatens(warning,sim.hero_pos),"region %d: automatic escape avoids actual damage" % region)
		# A committed attack hits once, even at an intersection of multiple zones.
		sim=boss_case(region,true)
		boss=sim.waves[5][0]
		boss.damage=100.0
		boss.warning.left=0.0
		var expected:=int(100.0*boss.warning.multiplier)
		sim._tick_enemy(boss)
		check(sim.hero_hp==10000-expected,"region %d: standing in danger takes one resolved hit" % region)
		var phase_sim:=boss_case(region)
		var phase_boss: Dictionary=phase_sim.waves[5][0]
		phase_boss.warning={}
		phase_boss.hp=int(phase_boss.max_hp*0.5)
		phase_boss.special_cd=0.0
		phase_sim._tick_enemy(phase_boss)
		check(phase_boss.awakened and phase_boss.warning.awakened and phase_boss.warning.total<warning.total,"region %d: half-health phase strengthens future attacks" % region)
		var phase_events:=0
		for event in phase_sim.events:
			if event.type=="boss_phase": phase_events+=1
		phase_sim.events.clear()
		phase_sim._tick_enemy(phase_boss)
		check(phase_events==1 and phase_sim.events.is_empty(),"region %d: awakening announces exactly once" % region)
		var saved: Dictionary=phase_sim.snapshot()
		var resumed:=Sim.new()
		check(resumed.restore_encoded(phase_sim.encode_snapshot()) and resumed.snapshot()==saved,"region %d: mid-cast checkpoint is exact" % region)
		phase_sim.simulate_to_end()
		resumed.simulate_to_end()
		check(resumed.snapshot()==phase_sim.snapshot(),"region %d: resumed boss phase finishes identically" % region)
		var bad: Dictionary=saved.duplicate(true)
		bad.fields.waves[5][0].warning.zones[0].radius=-1.0
		check(not Sim.new().restore(bad),"region %d: invalid telegraph rejected" % region)
		# Whole expeditions at different frame sizes must agree with skip.
		for selected in ["Vowkeeper","Arcanist","Ranger"]:
			var matching:=true
			for variant in range(64):
				var live:=model(region,selected,variant)
				var skip:=model(region,selected,variant)
				while not live.finished: live.advance(0.137)
				skip.simulate_to_end()
				if [live.won,live.hero_hp,live.hero_mana,live.rng.state,live.dodges,live.kills,live.elapsed,live.hero_pos]!=[skip.won,skip.hero_hp,skip.hero_mana,skip.rng.state,skip.dodges,skip.kills,skip.elapsed,skip.hero_pos]: matching=false
			check(matching,"region %d %s: all 64 live/skip outcomes agree" % [region,selected])
		# Build the actual world from a saved, active telegraph.
		var game: Node=load("res://Main.tscn").instantiate()
		game.save_store=Store.new("user://boss-"+str(region)+"-"+str(Time.get_ticks_usec()))
		root.add_child(game)
		game.floor_number=region*10+1
		game._start_run()
		game.run_active=false
		game.expedition=boss_case(region)
		game._sync_model_state()
		game._build_ui()
		var world: Node=game.run_arena.world
		check(world.warnings.has(50) and world.warnings[50].get_child_count()==2,"region %d: restored shape has fill and outline" % region)
		check(game.combat_hud.boss.visible and game.combat_hud.boss.text.contains(Patterns.NAMES[region].to_upper()),"region %d: HUD names the current boss attack" % region)
		var before: Dictionary=game.expedition.snapshot()
		world._process(0.4)
		check(game.expedition.snapshot()==before,"region %d: paused boss and warning remain frozen" % region)
		game.free()
		await process_frame
	# Legacy checkpoints retain pre-0.9 rules, including an already cast circle.
	var legacy:=model(0)
	legacy.stats.erase("boss_patterns")
	legacy.waves[5][0].erase("awakened")
	legacy.stage=5
	legacy.phase="combat"
	legacy.hero_pos=Vector2(0,-60)
	legacy._warn(legacy.waves[5][0],2.6,1.4)
	var restored:=Sim.new()
	check(restored.restore(legacy.snapshot()) and not restored.stats.has("boss_patterns"),"pre-0.9 checkpoint does not enable new patterns")
	legacy.simulate_to_end()
	restored.simulate_to_end()
	check(restored.snapshot()==legacy.snapshot(),"legacy circular boss continues exactly")
	var golden: Array=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/boss_legacy_08.json"))
	for row in golden:
		var old:=model(int(row.region),row["class"])
		old.stats.erase("boss_patterns")
		old.waves[5][0].erase("awakened")
		old.stage=5
		old.phase="combat"
		old.hero_pos=Vector2(0,-60)
		old._warn(old.waves[5][0],2.6,1.4)
		old.simulate_to_end()
		check(old.encode_snapshot().sha256_text()==row.sha256,"exact 0.8 reference: region %d %s" % [row.region,row["class"]])
	for malformed in [{"shape":"circle","radius":NAN,"center":Vector2.ZERO},{"shape":"beam","radius":1.0,"length":4.0,"direction":Vector2(2,0),"center":Vector2.ZERO},{"shape":"annulus","radius":2.0,"inner":3.0,"center":Vector2.ZERO}]:
		var invalid:=Patterns.create(0,Vector2.ZERO,Vector2.ZERO,false)
		invalid.zones=[malformed]
		check(not Patterns.valid(invalid),"malformed geometry rejected: "+str(malformed.shape))
	print("BOSS PATTERNS SMOKE: ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
