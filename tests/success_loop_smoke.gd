extends SceneTree
const Bot=preload("res://tests/balance_survey_bot.gd")
const Sim=preload("res://scripts/expedition_simulation.gd")
const Contract=preload("res://scripts/expedition_contract.gd")
const Relics=preload("res://scripts/class_relics.gd")
const Loot=preload("res://scripts/class_loot.gd")
const Notes=preload("res://scripts/playtest_notes.gd")
const Audio=preload("res://scripts/audio_director.gd")
const Store=preload("res://scripts/save_store.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run_checks")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("FAIL: "+label)
func game_for(selected: String) -> Node:
	var game:=Bot.new()
	game.character_class=selected
	game.world_seed=1979
	for slot in game.GEAR_SLOTS: game.equipment[slot]=game._normalize_item(game.equipment[slot],slot)
	return game
func relic_item(selected: String, seed_value: int=11) -> Dictionary:
	var rng:=RandomNumberGenerator.new(); rng.seed=seed_value
	return Relics.attune(Loot.roll(selected,true,1,rng,"Amulet","RARE"),selected)
func run_checks() -> void:
	for key in Contract.OATHS:
		check(Contract.valid(Contract.oath(key),2),"valid oath: "+key)
	for bad in [{"version":1,"mode":"oath","oath":"fake"},{"version":1,"mode":"oath","oath":"cinder","gold":999}, {"version":1,"mode":"oath","oath":1}]: check(not Contract.valid(bad,2),"reject forged oath")
	for selected in Relics.CLASS_KEYS:
		var game:=game_for(selected)
		var first: RefCounted=game._new_expedition(1,1)
		var contact:=-1.0; var signature:=-1.0
		while not first.finished:
			for event in first.advance(0.1):
				if event.type=="hit" and contact<0: contact=first.elapsed
				if event.type=="hero_attack" and event.get("skill",false) and not event.has("ability_id") and signature<0: signature=first.elapsed
		check(contact>=0 and contact<5.0 and signature>=0 and signature<5.0,"first contact and signature within 5 seconds: "+selected)
		check(first.won and first.elapsed<180.0,"normal starting gear clears first floor within three minutes: "+selected)
		print("FIRST_SESSION ",selected," contact=",contact," signature=",signature," clear=",first.elapsed)
		game._grant_expedition_rewards(true,1,false,first.run_seed,selected)
		check(game.first_relic_claimed and game.inventory[0].slot=="Amulet" and game.inventory[0].relic==Relics.CLASS_KEYS[selected],"first victory earns actual class effect: "+selected)
		check(game.guardian_trophies==[0] and game.floor_number==2,"campaign advances and grants seal")
		var earned: Dictionary=game.inventory[0]
		game.equipment.Amulet=earned
		check(game._combat_stats().class_relic==Relics.CLASS_KEYS[selected],"equipped effect freezes into combat stats")
		var other:="Ranger" if selected!="Ranger" else "Vowkeeper"
		check(Relics.effect(earned,other).is_empty(),"other class can equip but effect is inactive")
		check(not game._is_safe_upgrade(relic_item(other)),"automatic upgrades preserve class effect")
		for key in ["", "unmended", "cinder"]:
			var rules: Dictionary=Contract.oath(key)
			var watched: RefCounted=game._new_expedition(2,5,rules)
			var skipped: RefCounted=game._new_expedition(2,5,rules)
			watched.advance(5.0)
			var resumed:=Sim.new()
			check(resumed.restore_encoded(watched.encode_snapshot()),"relic/oath checkpoint restores: "+selected+"/"+key)
			while not watched.finished: watched.advance(0.1)
			skipped.simulate_to_end(); resumed.simulate_to_end()
			# Unconsumed caller delta after the final step differs; combat does not.
			for completed in [watched,skipped,resumed]: completed.accumulator=0.0
			check(watched.encode_snapshot()==skipped.encode_snapshot() and watched.encode_snapshot()==resumed.encode_snapshot(),"watch, skip and resume are identical: "+selected+"/"+key)
		var corrupted: Dictionary=game._new_expedition(2,5).snapshot()
		corrupted.fields.stats.class_relic="fake"
		check(not Sim.new().restore(corrupted),"unknown relic rejected in checkpoint")
		game.save_store=Store.new("user://success-"+selected+str(Time.get_ticks_usec()))
		check(game.save_store.save_game(game._build_save_payload())==OK,"relic progress saves")
		var restored:=game_for(selected); restored.save_store=game.save_store; restored._load_progress()
		check(restored.first_relic_claimed and restored.guardian_trophies==[0] and restored.equipment.Amulet==earned,"one-time reward, seals and item survive reload")
		restored.free(); game.free()
	# Exact risk/reward trade-offs, no reward inflation on defeat.
	var normal:=game_for("Arcanist"); normal.first_relic_claimed=true
	normal._grant_expedition_rewards(true,2,false,23,"Arcanist")
	var oath:=game_for("Arcanist"); oath.first_relic_claimed=true
	oath._grant_expedition_rewards(true,2,false,23,"Arcanist",Contract.oath("unmended"))
	check(oath.run_reward.gold==int(normal.run_reward.gold*1.3) and oath.run_reward.xp==int(normal.run_reward.xp*1.3) and oath.inventory.size()==normal.inventory.size()+1,"unmended victory earns exact bonus and extra drop")
	var cinder:=game_for("Arcanist"); cinder.first_relic_claimed=true
	cinder._grant_expedition_rewards(true,2,false,23,"Arcanist",Contract.oath("cinder"))
	check(cinder.inventory[0].quality in ["EPIC","LEGENDARY"] and cinder.inventory[0].relic=="echo_lightning","cinder victory guarantees Epic class amulet")
	var defeat:=game_for("Arcanist")
	defeat._grant_expedition_rewards(false,2,false,23,"Arcanist",Contract.oath("unmended"))
	check(defeat.run_reward.gold==55 and defeat.run_reward.xp==100 and defeat.inventory.is_empty() and not defeat.first_relic_claimed,"defeat never earns oath bonus or one-time reward")
	var basic: RefCounted=normal._new_expedition(2,1)
	var harder: RefCounted=normal._new_expedition(2,1,Contract.oath("cinder"))
	check(is_equal_approx(harder.waves[0][0].damage,basic.waves[0][0].damage*1.25),"cinder enemies deal 25% extra raw damage")
	for game in [normal,oath,cinder,defeat]: game.free()
	# Real mechanics in a controlled encounter, with ordinary stats.
	var tank:=game_for("Vowkeeper"); tank.equipment.Amulet=relic_item("Vowkeeper")
	var model: RefCounted=tank._new_expedition(1,1,Contract.oath("unmended"))
	model.hero_hp-=100; model.guard_time=1.0
	model._hurt_hero(model.waves[0][0],100.0)
	check(model.stats.relic_charge>0 and model.stats.relic_charge<=model.stats.ability_damage*0.6,"Guard stores bounded prevented damage")
	var hp_before: int=model.hero_hp
	model.pending_attack={"target":model.waves[0][0].id,"skill":true,"left":0.0,"name":"Ember Oath"}
	model._resolve_hero_attack()
	check(model.hero_hp==hp_before and model.stats.relic_charge==0.0,"unmended blocks signature healing, charged oath discharges once")
	model.stage=1; model.phase="interact"; model.journey.channel=1.2
	model.hero_pos=model.Layout.interact_point(0,1,model.layout_seed())+Vector2(0,1.25)
	model._tick_journey()
	check(model.hero_hp==hp_before and model.journey.well_used,"unmended consumes well without healing")
	var invalid: Dictionary=model.snapshot(); invalid.fields.stats.relic_charge=INF
	check(not Sim.new().restore(invalid),"non-finite stored damage rejected")
	tank.free()
	var mage:=game_for("Arcanist"); mage.equipment.Amulet=relic_item("Arcanist")
	model=mage._new_expedition(1,1)
	model.waves[0]=[
		{"id":0,"hp":10000,"role":"raider","pos":Vector2(0,0),"warning":{}},
		{"id":1,"hp":10000,"role":"raider","pos":Vector2(4,0),"warning":{}},
		{"id":2,"hp":10000,"role":"raider","pos":Vector2(7,0),"warning":{}},
		{"id":3,"hp":10000,"role":"raider","pos":Vector2(10,0),"warning":{}},
		{"id":4,"hp":10000,"role":"raider","pos":Vector2(15,0),"warning":{}}
	]
	model.pending_attack={"target":0,"skill":true,"left":0.0,"name":"Veil Nova"}
	model._resolve_hero_attack()
	# The first chain point starts at the edge of the blast (4.5m), not its centre.
	check(model.waves[0][2].hp<10000 and model.waves[0][3].hp<10000 and model.waves[0][4].hp==10000,"Nova chains outside blast to two nearby targets, never across unlimited distance")
	mage.free()
	var ranger:=game_for("Ranger"); ranger.equipment.Amulet=relic_item("Ranger")
	model=ranger._new_expedition(1,1)
	model.waves[0][0].hp=100000
	model.pending_attack={"target":0,"skill":true,"left":0.0,"name":"Cinder Volley"}
	model._resolve_hero_attack()
	var hits:=0
	for event in model.events:
		if event.type=="hit" and event.target==0: hits+=1
	check(hits==2,"returning volley hits primary target a second time")
	ranger.free()
	check(Audio.haptic_duration([{"type":"warning"},{"type":"hero_hit"}])==32 and Audio.haptic_duration([{"type":"hit","critical":false}])==0,"haptics combine significant events and ignore ordinary hits")
	check(Notes.normalize({"first_hit":INF,"first_clear":-1,"unknown":99}).is_empty(),"local notes reject invalid observations")
	var note_game:=game_for("Arcanist")
	note_game._note_playtest("first_hit",1.0)
	check(note_game.playtest_notes.is_empty(),"playtest notes are off by default")
	note_game.preferences.playtest=true
	note_game._note_playtest("first_hit",1.0); note_game._note_playtest("first_hit",10.0)
	check(note_game.playtest_notes.first_hit==1.0,"opt-in records first observation exactly once")
	note_game.free()
	var sets:=game_for("Arcanist")
	var original_cost: int=sets._combat_stats().mana_cost
	for region in range(4):
		for slot in ["Helmet","Chest","Gloves"]: sets.equipment[slot].region=region
		check(sets.RegionalSets.active(sets.equipment)==region,"three worn pieces activate regional set")
		var values: Dictionary=sets._combat_stats()
		check(values.regional_set==region and values.mana_cost==(maxi(1,int(original_cost*0.8)) if region==1 else original_cost),"set effect freezes into new combat stats")
		var set_model: RefCounted=sets._new_expedition(1,1)
		set_model.advance(0.4)
		if region==0: check(set_model.guard_time>0.0,"Ashen Vigil grants Guard to Arcanist signature")
		if region==3: check(set_model.skill_cd<5.0,"Cinder Crown reduces signature cooldown")
		var set_resumed:=Sim.new()
		check(set_resumed.restore_encoded(set_model.encode_snapshot()),"regional set checkpoint restores")
		var saved: Dictionary=set_model.snapshot(); saved.fields.stats.regional_set=4
		check(not Sim.new().restore(saved),"unknown regional set rejected")
	sets.equipment.Gloves.erase("region")
	check(sets.RegionalSets.active(sets.equipment)==-1,"two worn pieces do not activate a set")
	sets.free()
	print("SUCCESS LOOP SMOKE: ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
