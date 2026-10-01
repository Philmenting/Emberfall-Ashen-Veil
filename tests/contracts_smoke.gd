extends SceneTree
const Contract=preload("res://scripts/expedition_contract.gd")
const Sim=preload("res://scripts/expedition_simulation.gd")
const Loot=preload("res://scripts/class_loot.gd")
const Store=preload("res://scripts/save_store.gd")
var checks:=0
var failures:=0
var games: Array=[]
func _initialize() -> void: call_deferred("run_checks")
func check(value: bool, description: String) -> void:
	checks+=1
	if value: print("PASS: ",description)
	else:
		failures+=1
		push_error("FAIL: "+description)
func game_instance(path: String="") -> Node:
	var game=load("res://Main.tscn").instantiate()
	game.save_store=Store.new(path if not path.is_empty() else "user://contracts-"+str(Time.get_ticks_usec()))
	game.clock_source=func(): return 1790512000.0
	root.add_child(game)
	game.farm_enabled=false
	game.onboarding_complete=true
	var welcome=game.get_node_or_null("Welcome")
	if welcome!=null: game.remove_child(welcome); welcome.queue_free()
	games.append(game)
	return game
func run_checks() -> void:
	check(Contract.valid(Contract.hunt("Boots"),11),"hunt contract accepts a real slot")
	check(Contract.valid(Contract.trial(4),7),"trial tier fixes its enemy floor")
	for bad in [{},{"version":1,"mode":"unknown"},{"version":1,"mode":"hunt","slot":"Gold"},{"version":1,"mode":"trial","tier":0},{"version":1.0,"mode":"hunt","slot":"Boots"},{"version":1,"mode":"trial","tier":1,"bonus":900}]:
		check(not Contract.valid(bad,1),"malformed contract rejected: "+str(bad))
	check(not Contract.valid(Contract.trial(4),1),"trial cannot claim another tier's floor")
	var game:=game_instance()
	var golden=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/contracts_legacy_012.json"))
	for row in golden.checkpoints:
		var legacy:=Sim.new()
		var ok:=legacy.restore_encoded(row.snapshot)
		if ok: legacy.simulate_to_end()
		check(ok and legacy.encode_snapshot().sha256_text()==row.final_hash,"0.12 checkpoint preserved: %s/%d" % [row.class,int(row.floor)])
	var old_gear: Array=[]
	for selected in ["Vowkeeper","Arcanist","Ranger"]:
		for seed_value in range(64):
			var rng:=RandomNumberGenerator.new(); rng.seed=seed_value
			old_gear.append(Loot.roll(selected,true,1+seed_value%10,rng))
	check(var_to_str(old_gear).sha256_text()==golden.loot_hash,"192 ordinary campaign drops remain exactly unchanged")
	for slot in Contract.SLOTS:
		var matches:=true
		for selected in ["Vowkeeper","Arcanist","Ranger"]:
			for seed_value in range(64):
				var rng:=RandomNumberGenerator.new(); rng.seed=seed_value
				var item:=Loot.roll(selected,true,1+seed_value%10,rng,slot)
				matches=matches and item.slot==slot and item.stats.has(Loot.PRIMARY[selected]) and item.quality in ["RARE","EPIC","LEGENDARY"]
		check(matches,"focused "+slot+" drops preserve class attributes, tier and boss quality")
	var campaign=game._new_expedition(1,1)
	var hunt=game._new_expedition(1,1,Contract.hunt("Boots"))
	var trial=game._new_expedition(1,1,Contract.trial(1))
	check(hunt.waves[5][0].max_hp==int(campaign.waves[5][0].max_hp*1.15) and is_equal_approx(hunt.waves[5][0].damage,campaign.waves[5][0].damage*1.08),"hunts have actual increased health and incoming damage")
	check(trial.waves[5][0].max_hp==int(campaign.waves[5][0].max_hp*1.25) and is_equal_approx(trial.waves[5][0].damage,campaign.waves[5][0].damage*1.15) and trial.duration_limit()==150.0,"trial difficulty and timer are actual simulation rules")
	for selected in ["Vowkeeper","Arcanist","Ranger"]:
		game.character_class=selected
		for rules in [Contract.hunt("Weapon"),Contract.trial(1)]:
			var equal:=true
			var wins:=0
			for serial in range(1,65):
				var live=game._new_expedition(1,serial,rules)
				var skipped=game._new_expedition(1,serial,rules)
				while not live.finished: live.advance(0.1)
				skipped.simulate_to_end()
				# Skip has leftover wall time; all actual state fields otherwise match.
				live.accumulator=0.0; skipped.accumulator=0.0
				equal=equal and live.snapshot()==skipped.snapshot()
				if live.won: wins+=1
			check(equal,selected+" "+rules.mode+": all 64 live/skip outcomes match")
			print("CONTRACT_BALANCE ",selected," ",rules.mode," ",wins,"/64 starting-gear wins")
		for rules in [Contract.hunt("Amulet"),Contract.trial(4)]:
			var target:=7 if rules.mode=="trial" else 11
			var sim=game._new_expedition(target,19,rules)
			sim.advance(17.3)
			var restored:=Sim.new()
			var ok:=restored.restore_encoded(sim.encode_snapshot())
			sim.simulate_to_end(); restored.simulate_to_end()
			check(ok and sim.snapshot()==restored.snapshot(),selected+" "+rules.mode+": checkpoint continuation exact")
	var timeout=game._new_expedition(1,1,Contract.trial(1))
	timeout.stats.attack=1; timeout.stats.ability_damage=1
	for wave in timeout.waves:
		for enemy in wave: enemy.damage=0.0
	timeout.simulate_to_end()
	check(not timeout.won and abs(timeout.elapsed-150.0)<0.11,"trial fails at deadline even while hero survives")
	for value in [{"version":1,"mode":"hunt","slot":"Broken"},Contract.trial(2),{"version":1,"mode":"trial","tier":"1"}]:
		var state=trial.snapshot(); state.fields.stats.expedition_contract=value
		check(not Sim.new().restore(state),"corrupt contract checkpoint rejected")
	game.character_class="Arcanist"
	game.floor_number=2
	game._navigate("map")
	game._select_world_tab("hunts")
	check(game.find_child("HuntSlot_Boots",true,false)!=null and game.find_child("StartHunt",true,false)!=null,"world hunt choices and start button exist")
	game._choose_farm_goal("Boots")
	check(game.farm_mode=="hunt" and game.hunt_slot=="Boots","slot selection changes the real AFK farm goal")
	game._start_farming()
	game.run_arena.animation_enabled=false
	check(game.expedition.contract()==Contract.hunt("Boots") and game.auto_repeat,"visible farming carries the selected hunt contract")
	game._choose_farm_goal("Weapon")
	check(game.hunt_slot=="Boots","running hunt selection is locked")
	game._skip_run()
	check(game.run_succeeded and not game.run_loot.is_empty() and game.run_loot.all(func(item): return item.slot=="Boots") and game.floor_number==2,"skip awards targeted loot without campaign progression")
	game._return_to_camp()
	game._select_world_tab("trials")
	game._navigate("map")
	check(game.find_child("StartTrial",true,false)!=null,"trial entry exists after campaign unlock")
	game._start_trial()
	game.run_arena.animation_enabled=false
	check(game.combat_hud.has("trial_clock") and game.combat_hud.repeat.disabled and game.run_arena.world.find_child("AshTrialGate",true,false)!=null,"trial has countdown, locked repeat and visible original portal")
	game._toggle_repeat()
	check(not game.auto_repeat,"trials cannot enable automatic repeat")
	game._skip_run()
	check(game.run_succeeded and game.trial_cleared==1 and game.floor_number==2 and game.run_loot.size()==1 and game.run_loot[0].quality in ["EPIC","LEGENDARY"],"trial first clear grants Epic loot and separate progression")
	var count: int=game.inventory.size()
	var gold: int=game.player_gold
	game._grant_expedition_rewards(true,1,false,1979,"Arcanist",Contract.trial(1))
	check(game.inventory.size()==count and game.player_gold==gold and game.trial_cleared==1,"duplicate first-clear reward cannot be granted twice")
	game._grant_expedition_rewards(false,4,false,1979,"Arcanist",Contract.trial(2))
	check(game.inventory.size()==count and game.player_gold==gold and game.trial_cleared==1,"trial defeat grants no rewards or progression")
	game._return_to_camp()
	game._start_trial()
	game.run_arena.animation_enabled=false
	check(game.run_floor==3 and game.floor_number==2,"next trial uses its own level beyond campaign floor")
	game.run_active=false
	game._save_progress()
	var resumed:=game_instance(game.save_store.base_path)
	check(resumed.trial_cleared==1 and resumed.farm_mode=="hunt" and resumed.hunt_slot=="Boots" and resumed.page=="run" and not resumed.run_active and resumed.expedition.contract()==Contract.trial(2),"cold load retains hunt choice, trial progress and paused trial")
	resumed.run_arena.animation_enabled=false
	var offline:=game_instance()
	offline.character_class="Arcanist"; offline.floor_number=2; offline.farm_mode="hunt"; offline.hunt_slot="Amulet"
	var manual:=game_instance()
	manual.character_class="Arcanist"; manual.floor_number=2; manual.farm_mode="hunt"; manual.hunt_slot="Amulet"
	manual.world_seed=offline.world_seed
	offline._simulate_offline_time(1200)
	var remaining:=1200
	while remaining>=30:
		var run=manual._new_expedition(1,manual.expedition_serial,manual._farm_contract())
		run.simulate_to_end()
		var cost:=maxi(30,ceili(run.elapsed))
		if cost>remaining: break
		remaining-=cost; manual.expedition_serial+=1
		manual._grant_expedition_rewards(run.won,1,true,run.run_seed,"",run.contract())
	check(offline.inventory==manual.inventory and offline.pending_idle_ash==manual.pending_idle_ash and offline.pending_idle_xp==manual.pending_idle_xp and offline.expedition_serial==manual.expedition_serial and offline.idle_progress_seconds==remaining,"cached AFK hunts equal individually simulated runs and rewards")
	check(offline.inventory.all(func(item): return item.slot=="Amulet") and offline.floor_number==2,"AFK target applies to every relic without campaign advancement")
	var background:=game_instance()
	background.character_class="Arcanist"; background.floor_number=2
	background.farm_mode="hunt"; background.hunt_slot="Helmet"
	background._start_trial(); background.run_arena.animation_enabled=false
	background.farm_enabled=true
	background.clock_source=func(): return 1790512600.0
	background._accrue_offline_time()
	check(background.page=="camp" and background.trial_cleared==1 and background.farm_mode=="hunt" and background.hunt_slot=="Helmet" and background.pending_idle_runs>1,"background trial finishes once then selected hunt resumes")
	var rewards: int=background.pending_idle_ash
	background._accrue_offline_time()
	check(background.pending_idle_ash==rewards and background.trial_cleared==1,"duplicate resume adds no trial reward")
	var locked:=game_instance()
	locked._start_trial(); locked._choose_farm_goal("Weapon")
	check(locked.page=="camp" and locked.farm_mode=="campaign","first campaign clear is required for hunts and trials")
	var full:=game_instance()
	full.floor_number=2
	for i in range(full.MAX_BAG_SIZE): full.inventory.append(full.equipment.Weapon.duplicate(true))
	var before_gold: int=full.player_gold
	full._grant_expedition_rewards(true,1,false,1979,"Arcanist",Contract.trial(1))
	check(full.inventory.size()==full.MAX_BAG_SIZE and full.trial_cleared==1 and full.player_gold-before_gold>730 and full.run_reward.gold==full.player_gold-before_gold,"full bag sells trial relic once and displays actual total Gold")
	var failed:=game_instance()
	failed._grant_expedition_rewards(false,1,true,1979,"Arcanist",Contract.trial(1))
	failed._build_ui()
	var report_visible:=false
	for label in failed.find_children("*","Label",true,false):
		if "1 setbacks" in label.text: report_visible=true
	check(failed.pending_idle_fails==1 and failed.pending_idle_ash==0 and report_visible,"offline trial defeat is visible even without monetary rewards")
	failed._claim_idle_cache()
	check(failed.pending_idle_fails==0,"zero-reward defeat report can be acknowledged")
	var finished:=game_instance()
	finished.floor_number=2; finished.trial_cleared=Contract.MAX_TRIAL
	finished.world_tab="trials"; finished._navigate("map")
	finished._start_trial()
	check(finished.page=="map" and finished.find_child("StartTrial",true,false)==null,"all 30 trials have a terminal completion state")
	for g in games: g.queue_free()
	await process_frame
	print("CONTRACTS SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
