extends SceneTree
## Combat evidence for the optional rules, including immutable pre-change outcomes.
const Sim=preload("res://scripts/expedition_simulation.gd")
const Contract=preload("res://scripts/expedition_contract.gd")
const Patterns=preload("res://scripts/boss_patterns.gd")
const Skills=preload("res://scripts/class_skills.gd")
const Relics=preload("res://scripts/class_relics.gd")
const Offline=preload("res://scripts/offline_farm.gd")
var checks:=0
var failures:=0

func _initialize() -> void: call_deferred("run_checks")

func check(value: bool, description: String) -> void:
	checks+=1
	if value: print("PASS: ",description)
	else:
		failures+=1
		push_error("FAIL: "+description)

func values(selected: String, rules: Dictionary={}, journey: bool=false) -> Dictionary:
	var result: Dictionary={"max_hp":9000,"max_mana":600,"attack":200,"ability_damage":1000,"mana_cost":25,"crit":0.0,"armor":0,"class_mitigation":0,"attributes":{"Spirit":20},"boss_patterns":1,"boss_phases":1,"oath_rules":1}
	if not rules.is_empty(): result.expedition_contract=rules
	if journey:
		result.attack=1200
		result.ability_damage=2500
		result.armor=110
		result.class_mitigation=5
		result.arcane_tactics=1 if selected=="Arcanist" else 0
		result.class_relic=Relics.CLASS_KEYS[selected]
		result.dungeon_journey=1
		result.dungeon_generation=6
		result.route_pattern_version=4
		result.auto_target_variance=1
		result.skill_rotation=1
		result.skill_loadout=Skills.defaults(selected)
	return result

func model(selected: String="Vowkeeper", region: int=0, rules: Dictionary={}, seed_value: int=1979, journey: bool=false) -> RefCounted:
	var sim:=Sim.new()
	sim.setup(selected,values(selected,rules,journey),region*10+1,"Three-phase guardian",seed_value)
	return sim

func encounter(selected: String="Vowkeeper", rules: Dictionary={}) -> RefCounted:
	var sim:=model(selected,0,rules)
	sim.phase="combat"
	sim.hero_pos=Vector2.ZERO
	for enemy in sim.waves[0]: enemy.hp=0
	var target: Dictionary=sim.waves[0][0]
	target.hp=100000
	target.max_hp=100000
	target.pos=Vector2.ZERO
	return sim

func boss_case(region: int, phase_value: int, variant: int) -> RefCounted:
	var sim:=model()
	sim.floor_id=region*10+1
	sim.stage=5
	sim.phase="combat"
	sim.hero_pos=Vector2(0,-60)
	for enemy in sim.waves[5]: enemy.hp=0
	var boss: Dictionary=sim.waves[5][0]
	boss.hp=int(boss.max_hp*[1.0,0.55,0.25][phase_value])
	sim._update_boss_phase(boss)
	boss.warning=Patterns.create_phased(region,boss.pos,sim.hero_pos,phase_value,variant)
	boss.cooldown=999.0
	boss.special_cd=999.0
	sim.attack_cd=999.0
	sim.events.clear()
	return sim

func danger_point(warning: Dictionary) -> Vector2:
	var zone: Dictionary=warning.zones[0]
	return Vector2(zone.center)+Vector2.RIGHT*(float(zone.radius)+float(zone.inner))*0.5 if zone.shape=="annulus" else Vector2(zone.center)

func threat_map(warning: Dictionary) -> String:
	var map_text:=""
	for y in range(-67,-55):
		for x in range(-11,12): map_text+="1" if Patterns.threatens(warning,Vector2(x*0.5,y)) else "0"
	return map_text

func normalize_finished(sim: RefCounted) -> Dictionary:
	sim.accumulator=0.0
	return sim.snapshot()

func check_contracts() -> void:
	check(Contract.oath("unmended")=={"version":1,"mode":"oath","oath":"unmended"} and Contract.oath("cinder")=={"version":1,"mode":"oath","oath":"cinder"},"original oath constructors retain exact version-one shape")
	var pair:=Contract.combine(["cinder","unmended"])
	check(pair=={"version":2,"mode":"oath","oaths":["unmended","cinder"]} and Contract.valid(pair,1),"combined oaths have one canonical order")
	check(Contract.oath_keys(pair)==["unmended","cinder"] and Contract.has_oath(pair,"unmended") and Contract.has_oath(pair,"cinder") and Contract.no_healing(pair),"combined rules expose both risks to gameplay")
	check(Contract.title(pair).contains("UNMENDED + CINDERS") and Contract.describe(pair).contains("Both risks apply"),"combined title and descriptions explain both oaths")
	for keys in [[],["fake"],["unmended","unmended"],["unmended","cinder","hollow"],[1],["unmended",null]]:
		check(Contract.combine(keys).is_empty(),"invalid selection rejected without silently dropping keys: "+str(keys))
	for bad in [
		{"version":2,"mode":"oath","oaths":[]},
		{"version":2,"mode":"oath","oaths":["unmended","unmended"]},
		{"version":2,"mode":"oath","oaths":["unmended","cinder","hollow"]},
		{"version":2,"mode":"oath","oaths":["cinder","unmended"]},
		{"version":2,"mode":"oath","oaths":["unknown"]},
		{"version":2,"mode":"oath","oaths":[1]},
		{"version":2,"mode":"oath","oaths":["cinder"],"bonus":999},
		{"version":1,"mode":"oath","oath":"hollow"},
		{"version":2,"mode":"hunt","oaths":["cinder"]},
		{"version":2,"mode":"trial","oaths":["cinder"]},
		{"version":2.0,"mode":"oath","oaths":["cinder"]}
	]: check(not Contract.valid(bad,1),"forged or mixed contract rejected: "+str(bad))
	check(is_equal_approx(Contract.reward_multiplier(Contract.combine(["unmended","hollow"])),1.5) and Contract.bonus_drop_count(pair)==1 and Contract.guarantees_class_relic(pair),"combined currency bonuses add and each loot benefit occurs once")
	check(Contract.valid(Contract.trial(3),5) and not Contract.valid(Contract.trial(3),1) and Contract.valid(Contract.hunt("Boots"),11),"separate trial floor and hunt slot rules retain their validation")

func check_oath_mechanics() -> void:
	var plain:=encounter()
	var unmended:=encounter("Vowkeeper",Contract.combine(["unmended"]))
	for sim in [plain,unmended]:
		sim.guard_time=1.0
		sim.pending_attack={"target":0,"skill":false,"left":0.0,"name":"Oathblade"}
		sim._resolve_hero_attack()
	check(plain.waves[0][0].hp-unmended.waves[0][0].hp==int(200*1.15)-200,"Unmended Guard increases actual basic attack damage")
	var no_guard:=encounter("Vowkeeper",Contract.combine(["unmended"]))
	no_guard.pending_attack={"target":0,"skill":false,"left":0.0,"name":"Oathblade"}
	no_guard._resolve_hero_attack()
	check(no_guard.waves[0][0].hp==100000-200,"Unmended damage bonus requires active Guard")
	for sim in [plain,unmended]:
		sim.stats.class_relic="stored_ember"
		sim._hurt_hero(sim.waves[0][0],100.0)
	check(is_equal_approx(unmended.stats.relic_charge,plain.stats.relic_charge*1.25),"Unmended charges Bellwarden's Memory faster with the original cap")
	var previous_hp: int=unmended.hero_hp
	unmended.pending_attack={"target":0,"skill":true,"left":0.0,"name":"Ember Oath"}
	unmended._resolve_hero_attack()
	check(unmended.hero_hp==previous_hp and unmended.stats.relic_charge==0.0,"Unmended blocks signature healing and discharges its real relic once")
	var well:=model("Vowkeeper",0,Contract.combine(["unmended","hollow"]),1979,true)
	well.stage=1; well.phase="interact"; well.journey.channel=1.2
	well.hero_hp-=100
	well.hero_pos=well.Layout.interact_point(0,1,well.layout_seed())+Vector2(0,1.25)
	previous_hp=well.hero_hp
	well._tick_journey()
	check(well.hero_hp==previous_hp and well.journey.well_used,"combined Unmended consumes the well without healing")
	var cinder:=encounter("Vowkeeper",Contract.combine(["cinder"]))
	check(is_equal_approx(cinder.waves[0][0].damage,plain.waves[0][0].damage*1.25),"Cinder's enemy damage risk remains an actual raw-damage rule")
	cinder.stats.class_relic="stored_ember"
	cinder.stats.relic_charge=80.0
	cinder.pending_attack={"target":0,"skill":true,"left":0.0,"name":"Ember Oath"}
	cinder._resolve_hero_attack()
	check(100000-cinder.waves[0][0].hp==int((1000*1.15+80*1.25)*0.9),"Cinder buffs signature damage and Vowkeeper stored release separately")
	var mage:=encounter("Arcanist",Contract.combine(["cinder"]))
	mage.stats.class_relic="echo_lightning"
	for slot in [1,2]:
		mage.waves[0][slot].hp=100000
		mage.waves[0][slot].max_hp=100000
		mage.waves[0][slot].pos=Vector2(4.0 if slot==1 else 7.0,0)
	mage.pending_attack={"target":0,"skill":true,"left":0.0,"name":"Veil Nova"}
	mage._resolve_hero_attack()
	check(mage.waves[0][1].hp==100000-int(1000*0.45*1.25) and mage.waves[0][2].hp==mage.waves[0][1].hp,"Cinder buffs both real Arcanist relic jumps beyond Nova")
	var ranger:=encounter("Ranger",Contract.combine(["cinder"]))
	ranger.stats.class_relic="returning_thorn"
	ranger.pending_attack={"target":0,"skill":true,"left":0.0,"name":"Cinder Volley"}
	ranger._resolve_hero_attack()
	var return_hits: Array=[]
	for event in ranger.events:
		if event.type=="hit" and event.name==Relics.DEFINITIONS.returning_thorn.name: return_hits.append(event)
	check(return_hits.size()==1 and return_hits[0].damage==int(1000*0.35*1.25),"Cinder buffs Ranger's single real return strike")
	var technique:=encounter("Vowkeeper",Contract.combine(["cinder"]))
	technique._resolve_technique({"target":0,"ability_id":"judgment","center":Vector2.ZERO})
	check(technique.waves[0][0].hp==100000-int(float(Skills.damage("judgment",technique.stats))*1.15),"Cinder increases equipped technique damage")
	cinder.stats.regional_set=2
	check(cinder.OathRules.signature_crit(cinder.stats)==4.0 and Contract.synergy_description(cinder.contract(),"Vowkeeper",cinder.stats).contains("another 4"),"Cinder's Mourning Thread synergy applies the disclosed extra critical chance")
	var hollow:=encounter("Vowkeeper",Contract.combine(["hollow"]))
	hollow.hero_hp=int(hollow.stats.max_hp*0.6)
	var initial_mana: int=hollow.hero_mana
	hollow._auto_hero()
	check(hollow.signature_cost()==34 and hollow.hero_mana==initial_mana-34 and is_equal_approx(hollow.skill_cd,5.5*0.8),"Hollow spends increased signature Mana and starts a genuinely shorter cooldown")
	var guarded:=encounter("Vowkeeper",Contract.combine(["hollow"]))
	guarded.stats.skill_rotation=1
	guarded.stats.skill_loadout=["bastion","judgment"]
	guarded.rotation={"cooldowns":{"bastion":0.0,"judgment":0.0},"uses":{"bastion":0,"judgment":0}}
	guarded.hero_hp=int(guarded.stats.max_hp*0.6)
	initial_mana=guarded.hero_mana
	check(guarded._try_technique(guarded.waves[0][0],true) and guarded.hero_mana==initial_mana-22 and is_equal_approx(guarded.rotation.cooldowns.bastion,14.0*0.8),"Hollow modifies actual equipped technique cost and cooldown")
	guarded.stats.regional_set=1
	guarded.rotation.cooldowns.bastion=0.0
	guarded.pending_attack.clear()
	initial_mana=guarded.hero_mana
	guarded._try_technique(guarded.waves[0][0],true)
	check(guarded.hero_mana==initial_mana-18,"Drowned Script mitigates Hollow technique Mana costs")
	guarded.stats.regional_set=3
	guarded.rotation.cooldowns.bastion=0.0
	guarded.pending_attack.clear()
	guarded._try_technique(guarded.waves[0][0],true)
	check(is_equal_approx(guarded.rotation.cooldowns.bastion,14.0*0.8*0.85),"Cinder Crown shortens Hollow technique cooldowns further")
	var v1:=encounter("Vowkeeper",Contract.oath("cinder"))
	v1.pending_attack={"target":0,"skill":true,"left":0.0,"name":"Ember Oath"}
	v1._resolve_hero_attack()
	check(v1.waves[0][0].hp==100000-900 and not v1.OathRules.enabled(v1.stats),"a new profile's optional flag cannot alter a version-one oath")

func check_phase_geometry() -> void:
	for region in range(4):
		var phase_maps: Array=[]
		for phase_value in range(3):
			var variant_maps: Array=[]
			for variant in range(2):
				var sim:=boss_case(region,phase_value,variant)
				var boss: Dictionary=sim.waves[5][0]
				var warning: Dictionary=boss.warning.duplicate(true)
				var label:="region %d phase %d variant %d" % [region,phase_value,variant]
				check(Patterns.valid(warning) and warning.phase==phase_value and warning.zones.size()<=3,label+": real geometry validates and fits mobile zone budget")
				variant_maps.append(threat_map(warning))
				sim.hero_pos=danger_point(warning)
				check(Patterns.threatens(warning,sim.hero_pos),label+": a zone contains its real damage probe")
				var safe: Vector2=sim._safe_boss_escape()
				check(safe!=sim.hero_pos and not Patterns.threatens(warning,safe,0.35) and safe==sim._clamp_walkable(safe),label+": auto avoidance finds reachable walkable safe ground")
				boss.warning.left=0.8
				sim._auto_hero()
				while not boss.warning.is_empty(): sim.advance(0.1)
				var missed:=false
				for event in sim.events:
					if event.type=="miss": missed=true
				check(sim.hero_hp==sim.stats.max_hp and missed,label+": automatic escape prevents actual damage at impact")
				var struck:=boss_case(region,phase_value,variant)
				var struck_boss: Dictionary=struck.waves[5][0]
				struck.hero_pos=danger_point(struck_boss.warning)
				struck_boss.damage=100.0
				struck_boss.warning.left=0.0
				var expected:=int(100.0*struck_boss.warning.multiplier)
				struck._tick_enemy(struck_boss)
				var hit_count:=0
				for event in struck.events:
					if event.type=="hero_hit": hit_count+=1
				check(struck.hero_hp==struck.stats.max_hp-expected and hit_count==1,label+": committed geometry resolves one real hit")
			check(variant_maps[0]!=variant_maps[1],"region %d phase %d: variants change threatened arena cells" % [region,phase_value])
			phase_maps.append(variant_maps[0])
		check(phase_maps[0]!=phase_maps[1] and phase_maps[1]!=phase_maps[2] and phase_maps[0]!=phase_maps[2],"region %d: all three health phases change actual threatened ground" % region)
		var transition:=boss_case(region,0,0)
		var transitioning_boss: Dictionary=transition.waves[5][0]
		transitioning_boss.hp=int(transitioning_boss.max_hp*0.6)
		transition._update_boss_phase(transitioning_boss)
		check(transitioning_boss.boss_phase==1 and transitioning_boss.warning.is_empty() and transition.events.size()==1 and transition.events[0].phase==1,"region %d: first threshold emits one structural transition and ends old cast" % region)
		transitioning_boss.special_cd=0.0
		transition._tick_enemy(transitioning_boss)
		check(transitioning_boss.warning.phase==1,"region %d: next real attack uses phase-one geometry" % region)
		transition.events.clear()
		transitioning_boss.hp=int(transitioning_boss.max_hp*0.3)
		transition._update_boss_phase(transitioning_boss)
		transition._tick_enemy(transitioning_boss)
		check(transitioning_boss.boss_phase==2 and transitioning_boss.warning.phase==2 and transition.events[0].phase==2,"region %d: final threshold emits a distinct transition and altered attack" % region)
		transition.events.clear()
		transition._tick_enemy(transitioning_boss)
		check(transition.events.is_empty(),"region %d: a reached phase never announces twice" % region)
		var resumed:=Sim.new()
		check(resumed.restore_encoded(transition.encode_snapshot()) and resumed.snapshot()==transition.snapshot(),"region %d: phase-two committed warning restores exactly" % region)
		var crossed:=boss_case(region,0,0)
		crossed.waves[5][0].hp=int(crossed.waves[5][0].max_hp*0.3)
		crossed._update_boss_phase(crossed.waves[5][0])
		check(crossed.events.size()==2 and crossed.events[0].phase==1 and crossed.events[1].phase==2,"region %d: one large surviving hit records both crossed thresholds once" % region)
	var basic:=boss_case(0,0,0)
	basic.waves[5][0].hp=1800
	basic.pending_attack={"target":50,"skill":false,"left":0.0,"name":"Oathblade"}
	basic._resolve_hero_attack()
	check(basic.waves[5][0].hp==1600 and basic.waves[5][0].boss_phase==1 and Sim.new().restore(basic.snapshot()),"an actual basic hit commits its crossed phase before a checkpoint can be written")
	var technique:=boss_case(0,0,0)
	technique.hero_pos=technique.waves[5][0].pos
	technique._resolve_technique({"target":50,"ability_id":"judgment","center":technique.hero_pos})
	check(technique.waves[5][0].boss_phase==1 and technique.waves[5][0].warning.is_empty() and Sim.new().restore(technique.snapshot()),"an actual equipped-technique hit commits its structural transition immediately")
	var relic:=boss_case(0,1,0)
	relic.class_key="Ranger"
	relic.stats.class_relic="returning_thorn"
	relic.stats.ability_damage=200
	relic.waves[5][0].hp=830
	relic._release_relic(relic.waves[5][0],[relic.waves[5][0]],0.0)
	check(relic.waves[5][0].hp==760 and relic.waves[5][0].boss_phase==2 and Sim.new().restore(relic.snapshot()),"an actual class-relic return hit commits the final phase immediately")

func check_snapshot_rejection() -> void:
	var sim:=boss_case(0,1,0)
	var good: Dictionary=sim.snapshot()
	var destination:=model()
	var before: Dictionary=destination.snapshot()
	for kind in ["missing_flag","flag_zero","flag_bool","missing_pattern_flag","missing_phase","phase_float","phase_range","health_mismatch","awakened_mismatch","wrong_role","warning_phase","warning_region","warning_geometry","warning_origin","warning_bonus"]:
		var bad: Dictionary=good.duplicate(true)
		var boss: Dictionary=bad.fields.waves[5][0]
		match kind:
			"missing_flag": bad.fields.stats.erase("boss_phases")
			"flag_zero": bad.fields.stats.boss_phases=0
			"flag_bool": bad.fields.stats.boss_phases=true
			"missing_pattern_flag": bad.fields.stats.erase("boss_patterns")
			"missing_phase": boss.erase("boss_phase")
			"phase_float": boss.boss_phase=1.0
			"phase_range": boss.boss_phase=3
			"health_mismatch": boss.hp=boss.max_hp
			"awakened_mismatch": boss.awakened=false
			"wrong_role": bad.fields.waves[0][0].boss_phase=0
			"warning_phase": boss.warning.phase=2
			"warning_region": boss.warning=Patterns.create_phased(1,boss.warning.origin,boss.warning.aim_target,1,0)
			"warning_geometry": boss.warning.zones[0].radius+=0.1
			"warning_origin": boss.warning.origin+=Vector2(0.1,0)
			"warning_bonus": boss.warning["bonus"]=99
		check(not destination.restore(bad) and destination.snapshot()==before,"malformed phase checkpoint rejected atomically: "+kind)
	var procedural:=model("Vowkeeper",0,{},1979,true)
	procedural.stage=5
	procedural.phase="combat"
	procedural.journey.seal_broken=true
	procedural.hero_pos=procedural.checkpoint(5)+Vector2(0,3)
	procedural.waves[5][0].special_cd=0.0
	procedural._tick_enemy(procedural.waves[5][0])
	var desynchronized: Dictionary=procedural.snapshot()
	desynchronized.fields.waves[5][0].last_pattern_variant=1-int(desynchronized.fields.waves[5][0].warning.variant)
	check(not Sim.new().restore(desynchronized),"phased warning cannot disagree with its frozen alternate-pattern history")
	var combined:=model("Vowkeeper",0,Contract.combine(["unmended","cinder"]))
	for flag in [null,0,true,2]:
		var bad: Dictionary=combined.snapshot()
		if flag==null: bad.fields.stats.erase("oath_rules")
		else: bad.fields.stats.oath_rules=flag
		check(not Sim.new().restore(bad),"combined contract requires exact frozen integer opt-in: "+str(flag))
	var forged: Dictionary=combined.snapshot()
	for bad_rules in [{"version":2,"mode":"oath","oaths":["cinder","cinder"]},{"version":2,"mode":"oath","oaths":["cinder","hollow","unmended"]}]:
		forged.fields.stats.expedition_contract=bad_rules
		check(not Sim.new().restore(forged),"forged combined contract cannot restore")
	var legacy: Dictionary=boss_case(0,0,0).snapshot()
	legacy.fields.stats.erase("boss_phases")
	legacy.fields.waves[5][0].erase("boss_phase")
	legacy.fields.waves[5][0].warning={"center":legacy.fields.hero_pos,"radius":2.6,"left":1.4,"total":1.4}
	check(Sim.new().restore(legacy),"an original circular warning still restores with no phase opt-in")
	for key in ["phase","phase_name","origin","aim_target"]:
		var orphaned: Dictionary=legacy.duplicate(true)
		orphaned.fields.waves[5][0].warning[key]=1
		check(not Sim.new().restore(orphaned),"orphaned phase metadata cannot enable new rules in a legacy warning: "+key)

func check_parity() -> void:
	var selections: Array=[["unmended"],["cinder"],["hollow"],["unmended","cinder"],["unmended","hollow"],["cinder","hollow"]]
	for selected in ["Vowkeeper","Arcanist","Ranger"]:
		for region in range(4):
			for keys in selections:
				var matching:=true
				for seed_value in [1979,4191,8317]:
					var rules:=Contract.combine(keys)
					var watched:=model(selected,region,rules,seed_value,true)
					watched.stats.regional_set=region
					var skipped:=Sim.new()
					matching=matching and skipped.restore_encoded(watched.encode_snapshot())
					watched.advance(17.3)
					var restarted:=Sim.new()
					matching=matching and restarted.restore_encoded(watched.encode_snapshot())
					while not watched.finished: watched.advance(0.137)
					skipped.simulate_to_end()
					restarted.simulate_to_end()
					matching=matching and normalize_finished(watched)==normalize_finished(skipped) and watched.snapshot()==normalize_finished(restarted)
				check(matching,"region %d %s %s: three seeds match for watched, Skip and binary restart" % [region,selected,str(keys)])
		for region in range(4):
			var rules:=Contract.combine(selections[3+["Vowkeeper","Arcanist","Ranger"].find(selected)])
			var frozen:=values(selected,rules,true)
			frozen.regional_set=region
			var job:=Offline.new()
			job.setup(selected,frozen,region*10+1,"Offline guardian",600,1,97)
			var ledger: Array=[]
			while not job.done: ledger.append_array(job.step(2000))
			var expected: Array=[]
			var remaining:=600
			var serial:=1
			while remaining>=30:
				var seed_value:=Offline.seed_for_serial(97,serial)
				var manual:=Sim.new()
				manual.setup(selected,frozen,region*10+1,"Offline guardian",seed_value)
				manual.simulate_to_end()
				var duration:=maxi(30,ceili(manual.elapsed))
				if duration>remaining: break
				remaining-=duration
				serial+=1
				expected.append({"won":manual.won,"seed":seed_value})
			check(ledger==expected and job.serial==serial and job.remaining==remaining and job.stats==frozen,"region %d %s: AFK ledger exactly matches explicit phased combined-oath simulations" % [region,selected])
	var trial:=model("Vowkeeper",0,Contract.trial(1))
	var hunt:=model("Vowkeeper",0,Contract.hunt("Boots"))
	var campaign:=model()
	check(trial.duration_limit()==150.0 and trial.waves[5][0].max_hp==int(campaign.waves[5][0].max_hp*1.25) and hunt.waves[5][0].max_hp==int(campaign.waves[5][0].max_hp*1.15),"new boss flag retains trial deadline and hunt difficulty rules")

func check_legacy() -> void:
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/oaths_legacy_020.json"))
	for row in fixture.checkpoints:
		var legacy:=Sim.new()
		var restored:=legacy.restore_encoded(row.snapshot)
		var flags_unchanged: bool=restored and not legacy.stats.has("boss_phases") and not legacy.stats.has("oath_rules") and not legacy.waves[5][0].has("boss_phase")
		if restored: legacy.simulate_to_end()
		check(flags_unchanged and legacy.encode_snapshot().sha256_text()==row.final_hash,"immutable version-one checkpoint and outcome: %s region %d %s" % [row["class"],int(row.region),row.oath])

func run_checks() -> void:
	check_contracts()
	check_oath_mechanics()
	check_phase_geometry()
	check_snapshot_rejection()
	check_parity()
	check_legacy()
	# Godot may return from one function after a runtime error and continue the
	# caller. Never report a passing suite when a whole group did not execute.
	if checks<338:
		failures+=1
		push_error("Incomplete combat coverage: expected at least 338 checks, ran "+str(checks))
	print("COMBINED OATHS / PHASES SMOKE: ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
