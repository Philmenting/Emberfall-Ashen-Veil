extends SceneTree
const Forecast = preload("res://scripts/farm_forecast.gd")
const Simulation = preload("res://scripts/expedition_simulation.gd")
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
func run_checks() -> void:
	var game: Node=load("res://Main.tscn").instantiate()
	root.add_child(game)
	game.farm_enabled=false
	for selected in ["Vowkeeper","Arcanist","Ranger"]:
		game.character_class=selected
		var original: Dictionary=game.equipment.duplicate(true)
		var candidate: Dictionary=game.equipment.Weapon.duplicate(true)
		candidate.power+=21
		candidate.stats[game.CLASS_DATA[selected].primary]=int(candidate.stats.get(game.CLASS_DATA[selected].primary,0))+5
		var before: Dictionary=game._combat_stats()
		var raw_armor:=0
		for item in game.equipment.values(): raw_armor+=int(item.get("armor",0))
		var durability_scale:=1.2 if selected=="Vowkeeper" else 1.0
		check(before.max_hp==int(float(100+int(before.attributes.Vitality)*14)*durability_scale) and before.armor==int(float(raw_armor)*durability_scale),selected+": class Life and Armor profile matches its design")
		var changes: Dictionary=game._compare_item(candidate)
		check(game.equipment==original,selected+": comparing gear never mutates equipment")
		var old: Dictionary=game.equipment.Weapon
		game.equipment.Weapon=candidate
		var after: Dictionary=game._combat_stats()
		var matches:=true
		for key in changes: matches=matches and is_equal_approx(float(changes[key]),float(after[key]-before[key]))
		check(matches,selected+": displayed deltas equal actual equip results")
		check(changes.attack==46 and changes.ability_damage>0,selected+": weapon and primary attribute affect damage")
		game.equipment.Weapon=old
		var model: RefCounted=game._new_expedition(1,1)
		var snapshot: Dictionary=model.snapshot()
		var serial: int=game.expedition_serial
		var report:=Forecast.new()
		report.setup(selected,game._combat_stats(),1,"Guardian")
		check(report.summary().is_empty(),selected+": incomplete assessment cannot present a clear rate")
		report.step(3)
		check(report.processed==3 and not report.complete(),selected+": assessment can yield after a bounded batch")
		while not report.complete(): report.step(2)
		var expected_wins:=0
		var expected_seconds:=0
		for i in range(Simulation.COMBAT_VARIANTS):
			var sim: RefCounted=game._new_expedition(1,i+1)
			sim.simulate_to_end()
			if sim.won: expected_wins+=1
			expected_seconds+=maxi(30,ceili(sim.elapsed))
		var result: Dictionary=report.summary()
		check(result.wins==expected_wins and is_equal_approx(result.seconds,float(expected_seconds)/Simulation.COMBAT_VARIANTS),selected+": forecast matches every actual combat pattern")
		check(result.rate==1.0 and result.clears_per_hour>0,selected+": initial floor is reliable")
		check(game.expedition_serial==serial and model.snapshot()==snapshot,selected+": forecast does not consume runs or alter a live fight")
		var complete: Dictionary=report.summary()
		report.step(10)
		check(report.summary()==complete,selected+": completed forecast is idempotent")
	game.character_class="Vowkeeper"
	var rank_item: Dictionary=game.equipment.Weapon.duplicate(true)
	rank_item.stats.Strength+=20
	check(game._compare_item(rank_item).mana_cost>0,"ability rank increase also reports additional mana cost")
	var stats: Dictionary=game._combat_stats()
	var hard:=Forecast.new()
	hard.setup(game.character_class,stats,100,"Guardian")
	while not hard.complete(): hard.step(4)
	check(hard.summary().rate==0.0,"impossible floor has no estimated victories")
	check(hard.summary().combat_shortest<hard.summary().shortest,"actual fight length is separate from the minimum AFK cycle")
	var unused_rating: Dictionary=game.equipment.Chest.duplicate(true)
	unused_rating.power+=100
	check(game._compare_item(unused_rating).attack==0,"non-weapon item rating is not shown as additional attack")
	var vitality: Dictionary=game.equipment.Chest.duplicate(true)
	vitality.stats.Vitality+=4
	vitality.armor+=10
	var changes: Dictionary=game._compare_item(vitality)
	var before_vitality: Dictionary=game._combat_stats()
	var proposed_loadout: Dictionary=game.equipment.duplicate()
	proposed_loadout.Chest=vitality
	var after_vitality: Dictionary=game._combat_stats(proposed_loadout)
	check(changes.max_hp==after_vitality.max_hp-before_vitality.max_hp and changes.armor==after_vitality.armor-before_vitality.armor,"armor and Vitality comparison shows actual survivability bonuses")
	game.allocated_attributes.Dexterity=1000
	check(game._combat_stats().crit==100.0,"displayed critical chance respects the actual 100 percent maximum")
	game.allocated_attributes.Dexterity=0
	game.page="camp"
	game._build_ui()
	var old_revision: int=game.ui_revision
	game._navigate("gear")
	await process_frame
	check(game.ui_revision>old_revision and game.page=="gear","navigating cancels assessments tied to old UI")
	game._navigate("camp")
	var deadline := Time.get_ticks_msec()+20000
	while game.forecast_cache.is_empty() and Time.get_ticks_msec()<deadline: await process_frame
	check(not game.forecast_cache.is_empty(),"cooperative assessment completes and caches results in the camp")
	game.free()
	await process_frame
	print("GEAR / FORECAST SMOKE: ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
