extends SceneTree
const Sim=preload("res://scripts/expedition_simulation.gd")
const Layout=preload("res://scripts/dungeon_layout.gd")
const Bot=preload("res://tests/balance_survey_bot.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run_checks")
func check(value: bool, description: String) -> void:
	checks+=1
	if value: print("PASS: ",description)
	else:
		failures+=1
		push_error("FAIL: "+description)
func outcome(sim: RefCounted) -> Array:
	return [sim.won,sim.elapsed,sim.hero_hp,sim.hero_mana,sim.kills,sim.hero_pos,sim.rng.state,sim.journey]
func run_checks() -> void:
	var seen: Array=[]
	for region_id in range(4):
		check(not seen.has(Layout.ROUTES[region_id]),"region %d has a distinct floor plan" % region_id)
		seen.append(Layout.ROUTES[region_id])
		var connected:=true
		for room in range(1,6):
			var points:=Layout.travel_points(region_id,room,4.4)
			for i in range(points.size()-1):
				for step in range(101):
					if not Layout.contains(region_id,Vector2(points[i]).lerp(points[i+1],step/100.0)): connected=false
		check(connected,"region %d: every travel segment is on the floor" % region_id)
		for selected in ["Vowkeeper","Arcanist","Ranger"]:
			var game:=Bot.new()
			game.character_class=selected
			var stats: Dictionary=game._combat_stats()
			# Geometry/continuation fixture; starter balance is checked separately below.
			stats.max_hp=100000
			stats.attack*=6
			stats.ability_damage*=6
			var floor_value:=region_id*10+1
			var live:=Sim.new()
			live.setup(selected,stats,floor_value,"Journey guardian",1979)
			var skipped:=Sim.new()
			check(skipped.restore_encoded(live.encode_snapshot()),"%s/%d initial journey restores" % [selected,region_id])
			var valid_positions:=true
			var objective_counts: Dictionary={1:0,3:0,5:0}
			var snapshots: Array=[]
			var captured: Dictionary={}
			while not live.finished:
				var events:=live.advance(0.071)
				if not Layout.contains(region_id,live.hero_pos): valid_positions=false
				for enemy in live.living():
					if not Layout.contains(region_id,enemy.pos): valid_positions=false
				for event in events:
					if event.type=="objective": objective_counts[event.stage]+=1
				var key:=str(live.stage)+live.phase
				if live.phase in ["travel","interact"] and not captured.has(key):
					captured[key]=true
					snapshots.append(live.encode_snapshot())
			check(valid_positions,"%s/%d hero and enemies stay on walkable floor" % [selected,region_id])
			check(live.won and live.kills==26 and objective_counts=={1:1,3:1,5:1},"%s/%d completes 26 enemies and each objective once" % [selected,region_id])
			skipped.simulate_to_end()
			check(outcome(live)==outcome(skipped),"%s/%d watched and skipped outcomes match" % [selected,region_id])
			var exact:=true
			for encoded in snapshots:
				var resumed:=Sim.new()
				if not resumed.restore_encoded(encoded): exact=false; continue
				resumed.simulate_to_end()
				# accumulator differs with the caller's frame size, gameplay state does not.
				if outcome(resumed)!=outcome(live): exact=false
			check(exact,"%s/%d travel and interaction checkpoints preserve final result" % [selected,region_id])
			game.free()
	for selected in ["Vowkeeper","Arcanist","Ranger"]:
		var game:=Bot.new()
		game.character_class=selected
		var wins:=0
		var matching:=true
		for serial in range(64):
			var sim: RefCounted=game._new_expedition(1,serial)
			var duplicate: RefCounted=game._new_expedition(1,serial)
			sim.simulate_to_end()
			while not duplicate.finished: duplicate.advance(0.031)
			if sim.won: wins+=1
			if outcome(sim)!=outcome(duplicate): matching=false
		check(wins==64,selected+": all 64 starting-floor variants are winnable with starter gear")
		check(matching,selected+": all 64 variants agree live/skip")
		game.free()
	var legacy: Array=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/journey_legacy_010.json"))
	for row in legacy:
		var sim:=Sim.new()
		var restored:=sim.restore_encoded(row.snapshot)
		if restored: sim.simulate_to_end()
		check(restored and sim.encode_snapshot().sha256_text()==row.final_hash,"0.10 checkpoint keeps exact old outcome: %s/%d" % [row.class,int(row.floor)])
	var bot:=Bot.new()
	var model: RefCounted=bot._new_expedition(1,1)
	for invalid in [-1,2,1.0,"yes"]:
		var bad: Dictionary=model.snapshot()
		bad.fields.stats.dungeon_journey=invalid
		check(not Sim.new().restore(bad),"invalid journey flag rejected: "+str(invalid))
	for missing in ["travel_index","channel","well_used","seal_broken","chest_open"]:
		var bad: Dictionary=model.snapshot()
		bad.journey.erase(missing)
		check(not Sim.new().restore(bad),"missing journey field rejected: "+missing)
	var deadline:=Sim.new()
	deadline.restore_encoded(model.encode_snapshot())
	deadline.elapsed=239.95
	deadline.advance(0.1)
	check(deadline.finished and not deadline.won,"new journey stops at its four-minute safety limit")
	deadline=Sim.new()
	deadline.restore_encoded(legacy[0].snapshot)
	deadline.elapsed=179.95
	deadline.advance(0.1)
	check(deadline.finished and not deadline.won,"old checkpoint keeps its three-minute limit")
	var bad: Dictionary=model.snapshot()
	bad.journey.travel_index=4
	check(not Sim.new().restore(bad),"invalid current travel leg rejected")
	bad=model.snapshot()
	bad.fields.stage=4
	check(not Sim.new().restore(bad),"closed sanctum cannot resume beyond its seal")
	# Healing cannot be awarded twice after a checkpoint during the channel.
	model.stage=1
	model.phase="interact"
	model.hero_pos=Layout.interact_point(0,1)+Vector2(0,1.25)
	model.hero_hp-=100
	model.journey.channel=0.8
	var restored:=Sim.new()
	check(restored.restore_encoded(model.encode_snapshot()),"mid-well channel restores")
	var before: int=restored.hero_hp
	restored.advance(0.5)
	var healed: int=restored.hero_hp
	check(healed>before and restored.journey.well_used,"well restores actual Life once")
	restored._tick_journey()
	check(restored.hero_hp==healed,"well cannot grant duplicate healing")
	bot.free()
	# Visible map and props also reconstruct correctly from a saved objective state.
	var game: Node=load("res://Main.tscn").instantiate()
	root.add_child(game)
	game.farm_enabled=false
	game.floor_number=1
	game._start_run(1)
	game.run_arena.animation_enabled=false
	var world: Node=game.run_arena.world
	check(game.find_child("ExpeditionMap",true,false)!=null,"in-run route map is present")
	check(world.journey_props.size()==3 and world.sanctum_gate.position.y==0.0,"well, seal, chest and closed gate are rendered")
	game.expedition.journey.seal_broken=true
	game.expedition.journey.chest_open=true
	world._sync_journey_props(10.0)
	check(world.sanctum_gate.position.y< -2.0 and not world.journey_props[3].get_node("SealGem").visible,"breaking the seal opens the visible gate")
	check(world.journey_props[5].get_node("LootBeam").visible,"opened chest displays its loot beam")
	game.free()
	print("JOURNEY SMOKE: ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
