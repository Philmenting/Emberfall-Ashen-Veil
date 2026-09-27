extends SceneTree
const Skills=preload("res://scripts/class_skills.gd")
const Sim=preload("res://scripts/expedition_simulation.gd")
const Bot=preload("res://tests/balance_survey_bot.gd")
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
func model(selected: String, key: String) -> RefCounted:
	var stats: Dictionary={"max_hp":10000,"max_mana":1000,"attack":100,"ability_damage":500,"mana_cost":25,"crit":0.0,"armor":0,"class_mitigation":0,"attributes":{"Spirit":20},"skill_rotation":1,"skill_loadout":Skills.normalize(selected,[key])}
	var sim:=Sim.new()
	sim.setup(selected,stats,1,"Guardian",1979)
	sim.phase="combat"
	sim.hero_pos=Vector2(0,-4)
	sim.skill_cd=9.0
	for enemy in sim.waves[0]:
		enemy.hp=2000
		enemy.max_hp=2000
	return sim
func outcome(sim: RefCounted) -> Array:
	return [sim.won,sim.elapsed,sim.hero_hp,sim.hero_mana,sim.kills,sim.hero_pos,sim.rng.state,sim.rotation,sim.journey]
func run_checks() -> void:
	for selected in Skills.CLASSES:
		check(Skills.valid(selected,Skills.defaults(selected)),selected+": two distinct class techniques by default")
		check(Skills.normalize(selected,["unknown",Skills.choices(selected)[0],Skills.choices(selected)[0],17]).size()==2,selected+": malformed/duplicate choices normalize")
		for key in Skills.choices(selected):
			var definition: Dictionary=Skills.DEFINITIONS[key]
			var sim:=model(selected,key)
			var target: Dictionary=sim.waves[0][0]
			if definition.kind=="guard": sim.hero_hp=5000
			if key=="judgment": target.hp=700
			if key=="marked": target.role="hexer"
			var hp: int=target.hp
			var mana: int=sim.hero_mana
			check(sim._try_technique(target,definition.kind=="guard"),key+": suitable situation starts a cast")
			check(sim.hero_mana==mana-int(definition.cost) and sim.rotation.cooldowns[key]==definition.cooldown and sim.rotation.uses[key]==1,key+": actual Mana and cooldown charged once")
			if key!="marked":
				var restored:=Sim.new()
				check(restored.restore_encoded(sim.encode_snapshot()) and restored.snapshot()==sim.snapshot(),key+": in-flight cast checkpoint is exact")
				var original:=Sim.new()
				original.restore_encoded(sim.encode_snapshot())
				original.simulate_to_end()
				restored.simulate_to_end()
				check(original.snapshot()==restored.snapshot(),key+": cast continuation preserves final RNG and combat")
			sim._resolve_hero_attack()
			if definition.kind=="guard":
				check(sim.guard_time==definition.guard,key+": protection duration is applied")
				var before: int=sim.hero_hp
				sim._hurt_hero(target,100.0)
				check(before-sim.hero_hp==55,key+": Guard reduces real incoming damage by 45 percent")
			else: check(target.hp<hp,key+": impact deals real damage")
			if key=="chain": check(sim.waves[0][1].hp<2000 and sim.waves[0][2].hp<2000,"lightning jumps to three nearby targets")
			if key=="rain": check(target.slow==1.7,"Thornfall slows targets")
			if key=="frost_ward": check(target.slow==4.0,"Frost Mantle slows nearby melee enemies")
			if key=="smoke": check(sim.dodging and sim.hero_pos.distance_to(sim.dodge_goal)>0.3,"Cinder Veil schedules an actual retreat")
			check(not sim._try_technique(target,definition.kind=="guard") or sim.pending_attack.get("ability_id")!=key,key+": cooling technique cannot repeat")
			var empty:=model(selected,key)
			empty.hero_mana=0
			empty.hero_hp=5000
			check(not empty._try_technique(empty.waves[0][0],definition.kind=="guard"),key+": insufficient Mana prevents casting")
	# Ground bursts aim at cast-time positions, so enemies can leave them.
	for key in ["starfall","rain"]:
		var sim:=model("Arcanist" if key=="starfall" else "Ranger",key)
		sim._try_technique(sim.waves[0][0],false)
		for enemy in sim.waves[0]: enemy.pos=Vector2(15,-15)
		sim._resolve_hero_attack()
		check(sim.waves[0][0].hp==2000 and sim.hero_mana<1000,key+": moving out of marked ground avoids impact without refunding Mana")
	var guard:=model("Vowkeeper","bastion")
	check(not guard._try_technique(guard.waves[0][0],true),"protection is held while healthy and safe")
	guard._warn(guard.waves[0][0],2.0,1.0)
	check(guard._try_technique(guard.waves[0][0],true),"ground danger can trigger protection before losing Life")
	guard=model("Vowkeeper","bastion")
	guard.hero_hp=5000
	guard.guard_time=2.0
	check(not guard._try_technique(guard.waves[0][0],true),"existing Guard is not overwritten with a redundant protection cast")
	var signature:=model("Vowkeeper","sunder")
	signature.skill_cd=0.0
	signature._auto_hero()
	check(signature.pending_attack.skill and not signature.pending_attack.has("ability_id"),"signature precedes equipped offensive techniques")
	var canceled:=model("Arcanist","starfall")
	canceled._try_technique(canceled.waves[0][0],false)
	canceled._warn(canceled.waves[0][0],1.5,0.6)
	canceled._auto_hero()
	check(canceled.pending_attack.is_empty() and canceled.dodging and canceled.rotation.cooldowns.starfall>0.0,"automatic evasion cancels the cast without refunding cooldown")
	var sample:=model("Arcanist","chain")
	for flag in [-1,2,1.0,"on"]:
		var bad: Dictionary=sample.snapshot()
		bad.fields.stats.skill_rotation=flag
		check(not Sim.new().restore(bad),"invalid rotation flag rejected: "+str(flag))
	for loadout in [["chain","chain"],["chain","marked"],["chain"],"chain"]:
		var bad: Dictionary=sample.snapshot()
		bad.fields.stats.skill_loadout=loadout
		check(not Sim.new().restore(bad),"invalid checkpoint loadout rejected: "+str(loadout))
	for value in [-1.0,INF,"ready",99.0]:
		var bad: Dictionary=sample.snapshot()
		bad.rotation.cooldowns.chain=value
		check(not Sim.new().restore(bad),"invalid technique cooldown rejected: "+str(value))
	var bad: Dictionary=sample.snapshot()
	bad.erase("rotation")
	check(not Sim.new().restore(bad),"new combat cannot restore without technique state")
	bad=sample.snapshot()
	bad.fields.pending_attack={"target":0,"skill":true,"left":0.2,"name":"Fake","ability_id":"marked","center":Vector2.ZERO}
	check(not Sim.new().restore(bad),"foreign pending technique rejected")
	for selected in Skills.CLASSES:
		var game:=Bot.new()
		game.character_class=selected
		var matching:=true
		var viable:=true
		var used:=false
		for variant in range(64):
			var live: RefCounted=game._new_expedition(1,variant)
			var skip: RefCounted=game._new_expedition(1,variant)
			while not live.finished: live.advance(0.031)
			skip.simulate_to_end()
			if outcome(live)!=outcome(skip): matching=false
			if not live.won: viable=false
			for count in live.rotation.uses.values(): if count>0: used=true
		check(matching,selected+": 64 live/skip outcomes agree including rotation state")
		check(viable and used,selected+": starter builds clear all variants and actually use techniques")
		# Every selectable pair is exercised in all four regions with durable test gear.
		for excluded in Skills.choices(selected):
			var pair: Array=Skills.choices(selected)
			pair.erase(excluded)
			game.skill_loadouts[selected]=pair
			var region_match:=true
			for region_id in range(4):
				var sim: RefCounted=game._new_expedition(region_id*10+1,17)
				sim.stats.max_hp=100000
				sim.hero_hp=100000
				var clone:=Sim.new()
				if not clone.restore_encoded(sim.encode_snapshot()): region_match=false; continue
				sim.simulate_to_end()
				while not clone.finished: clone.advance(0.043)
				if outcome(sim)!=outcome(clone): region_match=false
			check(region_match,selected+": pair "+str(pair)+" matches in every region")
		game.free()
	var legacy: Array=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/rotation_legacy_011.json"))
	for row in legacy:
		var sim:=Sim.new()
		var ok:=sim.restore_encoded(row.snapshot)
		if ok: sim.simulate_to_end()
		check(ok and sim.encode_snapshot().sha256_text()==row.final_hash,"0.11 expedition preserved exactly: %s/%d" % [row.class,int(row.floor)])
	var path: String="user://rotation-"+str(Time.get_ticks_usec())
	var game: Node=load("res://Main.tscn").instantiate()
	game.save_store=Store.new(path)
	game.clock_source=func(): return 1790512000.0
	root.add_child(game)
	game.farm_enabled=false
	game.onboarding_complete=true
	game.gear_tab="skills"
	game._navigate("gear")
	check(game.find_child("TechniqueCard_bastion",true,false)!=null and game.find_child("EquipTechnique_judgment_1",true,false)!=null,"skills editor renders class choices and real equip actions")
	var card: Control=game.find_child("TechniqueCard_bastion",true,false)
	var equip_button: Control=game.find_child("EquipTechnique_judgment_1",true,false)
	check(card.mouse_filter==Control.MOUSE_FILTER_PASS and equip_button.mouse_filter==Control.MOUSE_FILTER_PASS,"cards and equip buttons pass drag events to the page scroller")
	game._equip_technique("judgment",1)
	check(game.skill_loadouts.Vowkeeper==["bastion","judgment"],"equipping replaces the chosen technique slot")
	game._equip_technique("judgment",0)
	check(game.skill_loadouts.Vowkeeper==["judgment","bastion"],"equipping an already slotted technique swaps priorities")
	game._select_class("Ranger")
	game._equip_technique("marked",1)
	game._select_class("Vowkeeper")
	check(game.skill_loadouts.Vowkeeper==["judgment","bastion"] and game.skill_loadouts.Ranger==["smoke","marked"],"each class retains its own loadout")
	game._start_run(1)
	game.run_arena.animation_enabled=false
	var fixed: Dictionary=game.expedition.snapshot()
	game._equip_technique("sunder",0)
	check(game.expedition.snapshot()==fixed and game.skill_loadouts.Vowkeeper==["judgment","bastion"],"loadouts cannot change during a running expedition")
	check(game.combat_hud.techniques.size()==2,"combat HUD shows both equipped technique cooldowns")
	game._toggle_run_pause()
	game._save_progress()
	game.free()
	await process_frame
	game=load("res://Main.tscn").instantiate()
	game.save_store=Store.new(path)
	game.clock_source=func(): return 1790512000.0
	root.add_child(game)
	check(game.skill_loadouts.Vowkeeper==["judgment","bastion"] and game.skill_loadouts.Ranger==["smoke","marked"],"class loadouts survive a cold start")
	check(game.page=="run" and not game.run_active and game.expedition.snapshot()==fixed,"paused rotation checkpoint resumes exactly after cold start")
	var world: Node=game.run_arena.world
	var before: Dictionary=game.expedition.snapshot()
	world._show_event({"type":"technique","ability_id":"chain","position":Vector2.ZERO,"radius":4.0,"points":[Vector2.ZERO,Vector2(1,-1),Vector2(2,-2)]})
	world._show_event({"type":"technique","ability_id":"starfall","position":Vector2.ZERO,"radius":3.5,"points":[]})
	check(world.effects.size()>0 and game.expedition.snapshot()==before,"technique effects render without altering simulation")
	world._update_effects(5.0)
	check(world.effects.is_empty(),"technique effects release their temporary nodes")
	game.free()
	print("SKILL ROTATION SMOKE: ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
