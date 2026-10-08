extends SceneTree
const Stances = preload("res://scripts/combat_stances.gd")
const Sim = preload("res://scripts/expedition_simulation.gd")
const Bot = preload("res://tests/balance_survey_bot.gd")
var checks := 0
var failures := 0

func _initialize() -> void: call_deferred("run_checks")

func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error("FAIL: "+label)

func outcome(sim: RefCounted) -> Dictionary:
	var state: Dictionary = sim.snapshot()
	state.fields.erase("accumulator") # Skip can have unused time after the final step.
	return state

func run_checks() -> void:
	check(Stances.normalize(null)=="balanced" and Stances.normalize(12)=="balanced" and Stances.normalize("unknown")=="balanced","invalid choices fall back to balanced")
	var game := Bot.new()
	for selected_class in ["Vowkeeper","Arcanist","Ranger"]:
		game.character_class=selected_class
		for stance in Stances.ORDER:
			game.combat_stances[selected_class]=stance
			var stats: Dictionary=game._combat_stats()
			check(stats.combat_stance==stance,"new runs use the selected class stance")
			for seed_value in [1979,104729,500003]:
				var live := Sim.new()
				live.setup(selected_class,stats,1,"Guardian",seed_value)
				for i in range(123): live.advance(0.1)
				var saved := live.encode_snapshot()
				var resumed := Sim.new()
				check(resumed.restore_encoded(saved),"stance checkpoint restores")
				while not live.finished: live.advance(0.1)
				resumed.simulate_to_end()
				check(outcome(live)==outcome(resumed),"resumed and watched combat remain identical")
				var skipped := Sim.new()
				skipped.setup(selected_class,stats,1,"Guardian",seed_value)
				skipped.simulate_to_end()
				check(outcome(live)==outcome(skipped),"watched and Skip/AFK combat remain identical")
				check(live.won,"each class and stance clears the opening floor")
			var stats_without: Dictionary=stats.duplicate(true)
			stats_without.erase("combat_stance")
			if stance=="balanced":
				var legacy := Sim.new()
				legacy.setup(selected_class,stats_without,1,"Guardian",1979)
				var balanced := Sim.new()
				balanced.setup(selected_class,stats,1,"Guardian",1979)
				legacy.simulate_to_end(); balanced.simulate_to_end()
				var balanced_result := outcome(balanced)
				balanced_result.fields.stats.erase("combat_stance")
				check(outcome(legacy)==balanced_result,"old runs preserve original damage and RNG")
		# Deterministic damage probes isolate stance values from routing/crit/armor.
		var incoming: Array[int]=[]
		var outgoing: Array[int]=[]
		var technique_damage: Array[int]=[]
		for stance in Stances.ORDER:
			game.combat_stances[selected_class]=stance
			var stats: Dictionary=game._combat_stats()
			stats.armor=0; stats.class_mitigation=0; stats.mana_guard=0.0; stats.crit=0.0
			var sim := Sim.new()
			sim.setup(selected_class,stats,1,"Guardian",1979)
			var target: Dictionary=sim.waves[0][0]
			sim._hurt_hero(target,100.0)
			incoming.append(int(stats.max_hp)-sim.hero_hp)
			target.role="raider"; target.hp=100000
			sim.pending_attack={"target":target.id,"skill":false,"name":"Probe"}
			sim._resolve_hero_attack()
			outgoing.append(100000-int(target.hp))
			var key: String={"Vowkeeper":"sunder","Arcanist":"chain","Ranger":"marked"}[selected_class]
			target.pos=sim.hero_pos; target.hp=100000
			sim._resolve_technique({"ability_id":key,"target":target.id,"center":sim.hero_pos})
			technique_damage.append(100000-int(target.hp))
		check(incoming==[100,122,80],"incoming damage follows all three stances")
		check(outgoing[1]>outgoing[0] and outgoing[2]<outgoing[0],"normal attacks follow stance tradeoffs")
		check(technique_damage[1]>technique_damage[0] and technique_damage[2]<technique_damage[0],"equipped techniques follow stance tradeoffs")
	game.combat_stances=Stances.normalize_book({"Vowkeeper":"assault","Arcanist":"bastion"})
	var payload: ConfigFile=game._build_save_payload()
	check(payload.get_value("hero","combat_stances")==game.combat_stances,"save and backup payloads include per-class choices")
	check(game._valid_backup_payload(payload),"valid stance backup passes validation")
	payload.set_value("hero","combat_stances",{"Vowkeeper":"unknown"})
	check(not game._valid_backup_payload(payload),"malformed backup stance is rejected")
	var sim := game._new_expedition(1,1)
	var invalid: Dictionary=sim.snapshot()
	invalid.fields.stats.combat_stance="unknown"
	check(not Sim.new().restore(invalid),"invalid checkpoint stance is rejected")
	# Exercise the actual controls and profile loader, rather than only the model.
	game.page="gear"
	var parent := VBoxContainer.new()
	root.add_child(parent)
	game._build_stance_editor(parent)
	var button := parent.find_child("CombatStance_assault",true,false) as Button
	check(button!=null and button.focus_mode==Control.FOCUS_ALL,"stance controls are reachable by keyboard")
	button.pressed.emit()
	check(game.combat_stances[game.character_class]=="assault","stance control updates the selected class")
	check(sim.stats.combat_stance=="balanced","changing preparation does not alter an existing expedition")
	game.page="run"
	game._select_combat_stance("bastion")
	check(game.combat_stances[game.character_class]=="assault","stance cannot be changed mid-expedition")
	game.page="gear"
	game.save_store=game.SaveStore.new("user://stance-profile")
	check(game.save_store.save_game(game._build_save_payload())==OK,"stance profile saves to disk")
	game.combat_stances=Stances.normalize_book({})
	game._load_progress()
	check(game.combat_stances.Ranger=="assault" and game.combat_stances.Arcanist=="bastion" and game.combat_stances.Vowkeeper=="assault","profile reload preserves independent class choices")
	parent.queue_free()
	game.free()
	await process_frame
	print("COMBAT STANCES SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
