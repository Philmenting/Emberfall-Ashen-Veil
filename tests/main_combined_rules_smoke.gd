extends SceneTree
## New-run, reward, durable-save and background integration through the actual game.
const Bot=preload("res://tests/balance_survey_bot.gd")
const Sim=preload("res://scripts/expedition_simulation.gd")
const Contract=preload("res://scripts/expedition_contract.gd")
const Store=preload("res://scripts/save_store.gd")
const Loot=preload("res://scripts/class_loot.gd")
const Relics=preload("res://scripts/class_relics.gd")
var checks:=0
var failures:=0
var now:=1790512000
var folder:="user://main-combined-"+str(Time.get_ticks_usec())

func _initialize() -> void: call_deferred("run_checks")

func check(value: bool, description: String) -> void:
	checks+=1
	if value: print("PASS: ",description)
	else:
		failures+=1
		push_error("FAIL: "+description)

func game_for(selected: String="Vowkeeper", suffix: String="") -> Node:
	var game:=Bot.new()
	game.character_class=selected
	game.world_seed=1979
	game.clock_source=func(): return float(now)
	game.save_store=Store.new(folder+"/"+(suffix if not suffix.is_empty() else str(Time.get_ticks_usec())))
	for slot in game.GEAR_SLOTS: game.equipment[slot]=game._normalize_item(game.equipment[slot],slot)
	return game

func relic_item(selected: String) -> Dictionary:
	var rng:=RandomNumberGenerator.new()
	rng.seed=43
	return Relics.attune(Loot.roll(selected,true,1,rng,"Amulet","RARE"),selected)

func reward_ledger(game: Node) -> Array:
	return [game.inventory,game.pending_idle_ash,game.pending_idle_xp,game.pending_idle_runs,game.pending_idle_fails,game.pending_idle_gear,game.pending_idle_salvaged,game.expedition_serial,game.floor_number,game.first_relic_claimed,game.guardian_trophies,game.pending_class_relic]

func frozen_checkpoint(game: Node) -> String:
	return game.expedition.encode_snapshot()

func check_new_runs() -> void:
	for selected in ["Vowkeeper","Arcanist","Ranger"]:
		var game:=game_for(selected)
		var campaign: RefCounted=game._new_expedition(1,1)
		var old_oath: RefCounted=game._new_expedition(1,1,Contract.oath("cinder"))
		var new_oath: RefCounted=game._new_expedition(1,1,Contract.combine(["unmended","cinder"]))
		check(campaign.uses_phased_bosses() and campaign.waves[5][0].boss_phase==0 and not campaign.stats.has("oath_rules"),selected+": campaign opts into phased guardians only")
		check(old_oath.uses_phased_bosses() and not old_oath.stats.has("oath_rules") and not old_oath.OathRules.enabled(old_oath.stats),selected+": legacy oath construction retains its original combat rules")
		check(new_oath.stats.oath_rules==1 and new_oath.OathRules.enabled(new_oath.stats) and new_oath.contract()==Contract.combine(["unmended","cinder"]),selected+": combined rules freeze into the actual new expedition")
		var before_serial: int=game.expedition_serial
		for invalid in [Contract.combine(["unmended","cinder","hollow"]),{"version":2,"mode":"oath","oaths":["cinder","cinder"]},{"version":2,"mode":"oath","oaths":["cinder","hollow","unmended"]}]:
			# The invalid builder returns no contract; the UI prevents starting an empty
			# oath selection. Forged nonempty dictionaries must be rejected by main.
			if invalid.is_empty(): continue
			game._start_run(1,invalid)
		check(game.expedition_serial==before_serial and game.expedition==null and game.page=="camp",selected+": forged combined contracts cannot start or consume a serial")
		var wins:=0
		var both_phases:=0
		var fast_first_contact:=true
		var clear_times: Array=[]
		for serial in range(1,25):
			var first: RefCounted=game._new_expedition(1,serial)
			var phases: Array=[]
			var first_hit:=-1.0
			var first_signature:=-1.0
			while not first.finished:
				for event in first.advance(0.1):
					if event.type=="boss_phase": phases.append(event.phase)
					if event.type=="hit" and first_hit<0.0: first_hit=first.elapsed
					if event.type=="hero_attack" and event.get("skill",false) and not event.has("ability_id") and first_signature<0.0: first_signature=first.elapsed
			if first.won: wins+=1; clear_times.append(first.elapsed)
			if phases==[1,2]: both_phases+=1
			fast_first_contact=fast_first_contact and first_hit>=0.0 and first_hit<5.0 and first_signature>=0.0 and first_signature<5.0
		check(wins==24,selected+": ordinary starting gear clears all 24 personal-sequence first floors")
		check(both_phases==24,selected+": every normal first-floor guardian reaches both real health transitions")
		check(fast_first_contact,selected+": first contact and signature remain within five seconds across 24 seeds")
		print("NEW_FIRST_FLOOR ",JSON.stringify({"class":selected,"seeds":24,"wins":wins,"both_phases":both_phases,"clear_seconds":clear_times}))
		game.free()

func check_combined_rewards() -> void:
	for selected in ["Vowkeeper","Arcanist","Ranger"]:
		for keys in [["unmended","cinder"],["unmended","hollow"],["cinder","hollow"]]:
			var plain:=game_for(selected)
			var combined:=game_for(selected)
			plain.first_relic_claimed=true
			combined.first_relic_claimed=true
			var rules:=Contract.combine(keys)
			plain._grant_expedition_rewards(true,2,false,23,selected)
			combined._grant_expedition_rewards(true,2,false,23,selected,rules)
			check(combined.run_reward.gold==int(plain.run_reward.gold*Contract.reward_multiplier(rules)) and combined.run_reward.xp==int(plain.run_reward.xp*Contract.reward_multiplier(rules)),selected+" "+str(keys)+": exact additive victory currencies")
			check(combined.inventory.size()==plain.inventory.size()+Contract.bonus_drop_count(rules),selected+" "+str(keys)+": extra drop awarded once")
			if "cinder" in keys:
				check(combined.inventory[0].slot=="Amulet" and combined.inventory[0].quality in ["EPIC","LEGENDARY"] and combined.inventory[0].relic==Relics.CLASS_KEYS[selected],selected+" "+str(keys)+": guaranteed class effect is an actual Epic-or-better Amulet")
			var failed:=game_for(selected)
			failed._grant_expedition_rewards(false,1,false,23,selected,rules)
			check(failed.run_reward.gold==55 and failed.run_reward.xp==100 and failed.inventory.is_empty() and not failed.first_relic_claimed and failed.guardian_trophies.is_empty(),selected+" "+str(keys)+": defeat grants no oath loot, bonus or first-clear entitlement")
			for game in [plain,combined,failed]: game.free()
	var trial:=game_for()
	trial.floor_number=2
	trial._grant_expedition_rewards(true,1,false,23,"Vowkeeper",Contract.trial(1))
	var before: Array=[trial.inventory.duplicate(true),trial.player_gold,trial.player_xp,trial.trial_cleared]
	trial._grant_expedition_rewards(true,1,false,23,"Vowkeeper",Contract.trial(1))
	check(before==[trial.inventory,trial.player_gold,trial.player_xp,trial.trial_cleared],"combined support preserves once-only separate trial rewards")
	var hunt:=game_for("Arcanist")
	hunt.floor_number=2
	hunt._grant_expedition_rewards(true,1,false,23,"Arcanist",Contract.hunt("Boots"))
	check(hunt.inventory.all(func(item): return item.slot=="Boots") and hunt.floor_number==2 and not hunt.first_relic_claimed,"combined support preserves targeted Hunts without campaign or first-gift progression")
	trial.free(); hunt.free()

func check_checkpoint_integration() -> void:
	for selected in ["Vowkeeper","Arcanist","Ranger"]:
		var game:=game_for(selected,"paused-"+selected)
		game.floor_number=11
		game.first_relic_claimed=true
		game.allocated_attributes.Vitality=240
		game.allocated_attributes[game.CLASS_DATA[selected].primary]=50
		game.equipment.Amulet=relic_item(selected)
		game.equipment.Amulet.locked=true
		game._start_run(11,Contract.combine(["unmended","cinder"]))
		while not game.expedition.finished and game.expedition.waves[5][0].boss_phase<1: game.expedition.advance(0.1)
		var reached: bool=not game.expedition.finished and game.expedition.waves[5][0].boss_phase==1
		if reached: game.expedition.advance(0.1)
		check(reached and not game.expedition.waves[5][0].warning.is_empty(),selected+": controlled prepared build reaches a real phase-one committed warning")
		game.run_active=false
		game._sync_model_state()
		var encoded:=frozen_checkpoint(game)
		check(game.save_store.save_game(game._build_save_payload())==OK,selected+": paused combined phase checkpoint persists through SaveStore")
		var cold:=game_for(selected,"paused-"+selected)
		cold._load_progress()
		check(cold.page=="run" and not cold.run_active and cold.expedition!=null and frozen_checkpoint(cold)==encoded and cold.equipment.Amulet.locked,selected+": cold restart keeps frozen phase, contract, paused state and protected relic")
		game.expedition.simulate_to_end()
		if cold.expedition!=null: cold.expedition.simulate_to_end()
		game.expedition.accumulator=0.0
		if cold.expedition!=null: cold.expedition.accumulator=0.0
		check(cold.expedition!=null and game.expedition.encode_snapshot()==cold.expedition.encode_snapshot(),selected+": loaded combined phase finishes with identical combat and RNG")
		game.free(); cold.free()
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/oaths_legacy_020.json"))
	var legacy:=game_for("Vowkeeper","legacy")
	legacy.page="run"
	legacy.run_active=false
	legacy.expedition=Sim.new()
	legacy.expedition.restore_encoded(fixture.checkpoints[0].snapshot)
	legacy.run_floor=legacy.expedition.floor_id
	check(legacy.save_store.save_game(legacy._build_save_payload())==OK,"original v1 oath checkpoint saves through the new main profile schema")
	var loaded:=game_for("Vowkeeper","legacy")
	loaded._load_progress()
	check(loaded.expedition!=null and frozen_checkpoint(loaded)==fixture.checkpoints[0].snapshot and not loaded.expedition.stats.has("boss_phases") and not loaded.expedition.stats.has("oath_rules"),"cold loading an old run never enables the current new-run flags")
	legacy.free(); loaded.free()

func check_background_and_skip() -> void:
	for selected in ["Vowkeeper","Arcanist","Ranger"]:
		var rules:=Contract.combine(["unmended","cinder"])
		var watched:=game_for(selected)
		var skipped:=game_for(selected)
		for game in [watched,skipped]:
			game.floor_number=2
			game.first_relic_claimed=true
			game.equipment.Amulet=relic_item(selected)
			game._start_run(1,rules)
		while not watched.expedition.finished: watched.expedition.advance(0.137)
		watched._grant_expedition_rewards(watched.expedition.won,1,false,watched.expedition.run_seed,selected,rules)
		skipped._skip_run()
		watched.expedition.accumulator=0.0; skipped.expedition.accumulator=0.0
		check(watched.expedition.encode_snapshot()==skipped.expedition.encode_snapshot() and watched.inventory==skipped.inventory and watched.player_gold==skipped.player_gold and watched.player_xp==skipped.player_xp and watched.first_relic_claimed==skipped.first_relic_claimed,selected+": watched and main Skip preserve identical combined outcome, loot and currencies")
		watched.free(); skipped.free()
		var background:=game_for(selected)
		var manual:=game_for(selected)
		for game in [background,manual]:
			game.floor_number=2
			game.first_relic_claimed=true
			game.equipment.Amulet=relic_item(selected)
			game._start_run(1,rules)
			game.farm_enabled=true
			game.auto_repeat=false
			game.last_saved_at=now-1200
		background._accrue_offline_time()
		manual.expedition.advance(1200.0)
		var remaining: int=maxi(0,floori(manual.expedition.accumulator+0.00001))
		manual._grant_expedition_rewards(manual.expedition.won,1,true,manual.expedition.run_seed,selected,rules)
		manual.expedition=null
		manual.page="camp"
		manual.run_active=false
		manual._simulate_offline_time(remaining)
		check(reward_ledger(background)==reward_ledger(manual) and background.idle_progress_seconds==manual.idle_progress_seconds and background.page=="camp",selected+": background active combined run and subsequent farming match explicit frozen simulation and rewards")
		var earned: Array=reward_ledger(background).duplicate(true)
		background._accrue_offline_time()
		check(earned==reward_ledger(background),selected+": repeated background reconciliation cannot duplicate the combined reward")
		background.free(); manual.free()

func check_protected_first_gift() -> void:
	var game:=game_for("Arcanist","protected")
	var protected: Dictionary=game.equipment.Weapon.duplicate(true)
	protected.locked=true
	for i in range(game.MAX_BAG_SIZE): game.inventory.append(protected.duplicate(true))
	var bag: Array=game.inventory.duplicate(true)
	var rules:=Contract.combine(["unmended","cinder"])
	game._grant_expedition_rewards(true,1,false,1979,"Arcanist",rules)
	check(game.first_relic_claimed and game.inventory==bag and not game.pending_class_relic.is_empty() and game.pending_class_relic.relic=="echo_lightning" and game.pending_class_relic.quality in ["EPIC","LEGENDARY"],"combined first victory preserves every protected item and reserves its Epic class gift")
	var reserved: Dictionary=game.pending_class_relic.duplicate(true)
	check(game.save_store.save_game(game._build_save_payload())==OK,"protected-bag class entitlement persists")
	var loaded:=game_for("Arcanist","protected")
	loaded._load_progress()
	check(loaded.first_relic_claimed and loaded.inventory==bag and loaded.pending_class_relic==reserved,"cold restart retains protected bag and exactly one reserved class gift")
	game._grant_expedition_rewards(true,1,false,1980,"Arcanist",rules)
	check(game.pending_class_relic==reserved and game.inventory==bag,"repeated combined victory cannot replace the once-only reserved gift or sell protected gear")
	game.inventory.remove_at(0)
	game._claim_reserved_relic()
	var claimed_count: int=game.inventory.size()
	game._claim_reserved_relic()
	check(game.pending_class_relic.is_empty() and game.inventory.size()==claimed_count and game.inventory[-1].relic=="echo_lightning","reserved combined gift can be claimed once after making room")
	game.free(); loaded.free()

func manual_repeats(game: Node, frozen_stats: Dictionary, target_floor: int, seconds: int) -> void:
	var remaining:=seconds
	while remaining>=30:
		var seed_value: int=game._run_seed_for_serial(game.expedition_serial)
		var sim:=Sim.new()
		sim.setup(game.character_class,frozen_stats,target_floor,String(game._region_data(target_floor).boss),seed_value)
		sim.simulate_to_end()
		var duration:=maxi(30,ceili(sim.elapsed))
		if duration>remaining: break
		remaining-=duration
		game.expedition_serial+=1
		game._grant_expedition_rewards(sim.won,target_floor,true,seed_value,sim.class_key,sim.contract())
	game.idle_progress_seconds=remaining

func finish_cooperative(game: Node) -> void:
	while game.offline_job!=null: game._process(0.1)

func check_frozen_repeat() -> void:
	for selected in ["Vowkeeper","Arcanist","Ranger"]:
		var class_index: int=["Vowkeeper","Arcanist","Ranger"].find(selected)
		var rules:=Contract.combine([["unmended","cinder"],["unmended","hollow"],["cinder","hollow"]][class_index])
		var background:=game_for(selected,"repeat-"+selected)
		var manual:=game_for(selected)
		for game in [background,manual]:
			game.floor_number=3
			game.farm_floor=2
			game.farm_mode="hunt"
			game.hunt_slot="Boots"
			game.first_relic_claimed=true
			game.allocated_attributes.Vitality=40
			game.allocated_attributes[game.CLASS_DATA[selected].primary]=20
			game.equipment.Amulet=relic_item(selected)
			game._start_run(1,rules)
			game.auto_repeat=true
			game.farm_enabled=true
			game.last_saved_at=now-1800
		var frozen_stats: Dictionary=manual.expedition.stats.duplicate(true)
		frozen_stats.erase("relic_charge")
		# A checkpoint's combat authority cannot be silently replaced by the
		# current profile's later build, even when replaying an AFK batch.
		for game in [background,manual]: game.allocated_attributes[game.CLASS_DATA[selected].primary]+=99
		background._accrue_offline_time(true)
		check(background.offline_job!=null and background._valid_offline_repeat(background.offline_repeat_rules,selected),selected+": active successful combined repeat creates a validated frozen cooperative context")
		var context: Dictionary=background._offline_farm_context()
		check(context.floor==1 and context.contract==rules and context.stats==frozen_stats and not context.stats.has("relic_charge") and background.farm_floor==2 and background.farm_mode=="hunt" and background.hunt_slot=="Boots",selected+": oath repeat preserves the original frozen build and independent selected Hunt")
		check(background.save_store.save_game(background._build_save_payload())==OK,selected+": pending oath repeat batch and its template persist atomically")
		var cold:=game_for(selected,"repeat-"+selected)
		cold._load_progress()
		check(cold.pending_afk_seconds==background.pending_afk_seconds and cold.offline_repeat_rules==background.offline_repeat_rules and cold._offline_farm_context().stats==frozen_stats,selected+": a cold pending-batch restart keeps its exact frozen contract and stats")
		cold._accrue_offline_time(true)
		manual.expedition.advance(1800.0)
		check(manual.expedition.won,selected+": controlled combined repeat build wins its initial real expedition")
		var remaining: int=maxi(0,floori(manual.expedition.accumulator+0.00001))
		manual._grant_expedition_rewards(manual.expedition.won,1,true,manual.expedition.run_seed,selected,rules)
		manual.expedition=null
		manual.page="camp"
		manual.run_active=false
		manual_repeats(manual,frozen_stats,1,remaining)
		finish_cooperative(background)
		finish_cooperative(cold)
		check(reward_ledger(background)==reward_ledger(manual) and background.idle_progress_seconds==manual.idle_progress_seconds,selected+": cooperative combined repeat currencies, loot, seeds and time match individual frozen runs")
		check(reward_ledger(cold)==reward_ledger(manual) and cold.idle_progress_seconds==manual.idle_progress_seconds,selected+": cold-resumed cooperative repeat cannot duplicate or omit a reward")
		check(background.offline_repeat_rules==cold.offline_repeat_rules and not background.offline_repeat_rules.is_empty(),selected+": chosen combined repeat remains authoritative after its first AFK batch")
		now+=600
		background._accrue_offline_time()
		cold._accrue_offline_time()
		manual_repeats(manual,frozen_stats,1,600+manual.idle_progress_seconds)
		check(reward_ledger(background)==reward_ledger(manual) and reward_ledger(cold)==reward_ledger(manual),selected+": a second absence repeats the same two oaths and frozen build")
		var earned: Array=reward_ledger(background).duplicate(true)
		background._accrue_offline_time()
		check(earned==reward_ledger(background),selected+": repeat reconciliation at the same timestamp remains once-only")
		var initial_template: Dictionary=background.offline_repeat_rules.duplicate(true)
		var fresh:=Sim.new()
		fresh.restore_encoded(initial_template.template)
		for corruption in ["hero_hp","rng_state","elapsed","class","version","charge"]:
			var invalid: Dictionary=initial_template.duplicate(true)
			var state: Dictionary=fresh.snapshot()
			match corruption:
				"hero_hp": state.fields.hero_hp-=1
				"rng_state": state.rng_state+=1
				"elapsed": state.fields.elapsed=0.1
				"class": state.fields.class_key="Ranger" if selected!="Ranger" else "Arcanist"
				"version": invalid.version=1.0
				"charge": state.fields.stats.relic_charge=0.0
			if corruption!="version": invalid.template=Marshalls.raw_to_base64(var_to_bytes(state))
			check(not background._valid_offline_repeat(invalid,selected),selected+": forged frozen repeat template rejected: "+corruption)
			var payload: ConfigFile=background._build_save_payload()
			payload.set_value("idle","offline_repeat_rules",invalid)
			check(not background._valid_backup_payload(payload),selected+": a backup cannot install the forged repeat template: "+corruption)
		if not cold.inventory.is_empty(): cold._equip_item(cold.inventory[0])
		check(cold.offline_repeat_rules.is_empty() and cold._offline_farm_context().contract==Contract.hunt("Boots") and cold._offline_farm_context().floor==2,selected+": manual gear preparation ends the frozen oath repeat and restores the selected Hunt")
		background.free(); manual.free(); cold.free()

func check_hollow_hud_costs() -> void:
	var game:=game_for("Arcanist")
	game._start_run(1,Contract.combine(["hollow"]))
	for key in ["state","life","encounter","boss","enemy","skill","guard","ward"]:
		var label:=Label.new()
		game.add_child(label)
		game.combat_hud[key]=label
	for key in ["auto","repeat"]:
		var button:=Button.new()
		game.add_child(button)
		game.combat_hud[key]=button
	for key in ["hp","mana","progress","enemy_hp"]:
		var bar:=ProgressBar.new()
		game.add_child(bar)
		game.combat_hud[key]=bar
	game.combat_hud.techniques={}
	for key in game.expedition.stats.skill_loadout:
		var label:=Label.new()
		game.add_child(label)
		game.combat_hud.techniques[key]=label
	game.expedition.hero_mana=int(game.Skills.DEFINITIONS.frost_ward.cost)+1
	game._sync_model_state()
	game._sync_combat_hud()
	check(game.expedition.hero_mana<game.expedition.technique_cost("frost_ward") and game.combat_hud.techniques.frost_ward.text.contains("LOW MANA"),"Hollow technique HUD uses increased actual Mana cost at the readiness boundary")
	check(game.combat_hud.skill.text.contains(str(game.expedition.signature_cost())+" Mana"),"Hollow signature HUD displays the authoritative cast cost")
	game.expedition.hero_mana=game.expedition.signature_cost()+7
	game._sync_model_state()
	game._sync_combat_hud()
	check(game.combat_hud.ward.text.ends_with(" 7 MANA AVAILABLE"),"Hollow Mana Ward HUD reserves the actual signature cost")
	game.free()

func run_checks() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	check_new_runs()
	check_combined_rewards()
	check_checkpoint_integration()
	check_background_and_skip()
	check_protected_first_gift()
	check_frozen_repeat()
	check_hollow_hud_costs()
	if checks<156:
		failures+=1
		push_error("Incomplete main integration coverage: expected at least 156 checks, ran "+str(checks))
	print("MAIN COMBINED RULES SMOKE: ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
