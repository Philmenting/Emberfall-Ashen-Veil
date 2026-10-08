extends SceneTree
const Bot=preload("res://tests/balance_survey_bot.gd")
const Loot=preload("res://scripts/class_loot.gd")
const Relics=preload("res://scripts/class_relics.gd")
const Contract=preload("res://scripts/expedition_contract.gd")
func _initialize() -> void: call_deferred("survey")
func survey() -> void:
	var rows: Array=[]
	var first_rows: Array=[]
	var failures:=0
	for selected in Relics.CLASS_KEYS:
		var game:=Bot.new(); game.character_class=selected; game.world_seed=1979
		var clears:=0; var slowest:=0.0; var contact_max:=0.0; var signature_max:=0.0
		for serial in range(1,25):
			var sim: RefCounted=game._new_expedition(1,serial)
			var contact:=-1.0; var signature:=-1.0
			while not sim.finished:
				for event in sim.advance(0.1):
					if event.type=="hit" and contact<0: contact=sim.elapsed
					if event.type=="hero_attack" and event.get("skill",false) and not event.has("ability_id") and signature<0: signature=sim.elapsed
			if sim.won: clears+=1
			if contact<0 or signature<0: failures+=1
			slowest=maxf(slowest,sim.elapsed); contact_max=maxf(contact_max,contact); signature_max=maxf(signature_max,signature)
		first_rows.append({"class":selected,"runs":24,"wins":clears,"slowest_clear_seconds":slowest,"latest_first_contact_seconds":contact_max,"latest_first_signature_seconds":signature_max})
		if clears!=24 or slowest>=180 or contact_max>=5 or signature_max>=5: failures+=1
		var rng:=RandomNumberGenerator.new(); rng.seed=11
		game.equipment.Amulet=Relics.attune(Loot.roll(selected,true,1,rng,"Amulet","RARE"),selected)
		for floor_id in [2,6]:
			for keys in [[], ["unmended"], ["cinder"], ["hollow"], ["unmended","cinder"], ["unmended","hollow"], ["cinder","hollow"]]:
				var wins:=0; var total_seconds:=0.0
				for serial in range(1,17):
					var sim: RefCounted=game._new_expedition(floor_id,serial,Contract.combine(keys))
					sim.simulate_to_end()
					if sim.won: wins+=1
					total_seconds+=sim.elapsed
				rows.append({"class":selected,"floor":floor_id,"oaths":keys,"runs":16,"wins":wins,"mean_seconds":total_seconds/16})
		game.free()
	var report: Dictionary={"schema":2,"time_basis":"simulation_seconds","scenario":"ordinary level-1 starting gear; oath comparisons add one seeded class amulet, without level gains or upgraded equipment","first_descent":first_rows,"oaths":rows,"new_boss_phases":true,"human_test_results":false,"failures":failures}
	var path:="user://success-balance.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="): path=arg.trim_prefix("--report=")
	var output:=FileAccess.open(path,FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"\t")); output.close()
	print("SUCCESS BALANCE SURVEY: 744 expeditions, ",failures," first-session failures, report=",path)
	quit(1 if failures else 0)
