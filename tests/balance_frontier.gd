extends SceneTree
const Sim=preload("res://scripts/expedition_simulation.gd")
func _initialize() -> void:
	var rows: Array=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/balance_frontier_07.json"))
	for fixture in rows:
		for enabled in [false,true]:
			var row: Dictionary=fixture.duplicate(true)
			row.stats.mana_guard=0.35 if enabled and row["class"]=="Arcanist" else 0.0
			var wins:=0
			var dead:=0
			var timed_out:=0
			var mana:=0.0
			var health:=0.0
			var elapsed:=0.0
			var stages:=0.0
			for i in range(64):
				var sim:=Sim.new()
				sim.setup(row["class"],row.stats,row.floor,"Frontier Boss",1979+i*104729)
				sim.simulate_to_end()
				if sim.won: wins+=1
				elif sim.hero_hp<=0: dead+=1
				else: timed_out+=1
				mana+=sim.hero_mana
				health+=sim.hero_hp
				elapsed+=sim.elapsed
				stages+=sim.stage
			print("FRONTIER ward=",enabled," ",row["class"]," floor=",row.floor," wins=",wins," deaths=",dead," timeouts=",timed_out," mean_mana=",mana/64," mean_hp=",health/64," mean_seconds=",elapsed/64," mean_stages=",stages/64)
	quit()
