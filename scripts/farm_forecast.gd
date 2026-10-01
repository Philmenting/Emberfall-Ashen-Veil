extends RefCounted
## Read-only assessment of every combat and layout pattern; never creates loot or advances a save.
const Simulation = preload("res://scripts/expedition_simulation.gd")
var selected_class := "Vowkeeper"
var stats: Dictionary = {}
var floor_id := 1
var boss_name := "Guardian"
var processed := 0
var wins := 0
var total_seconds := 0
var shortest := 1000000
var longest := 0
var combat_shortest := 1000000
var combat_longest := 0

func setup(class_value: String,values: Dictionary,target_floor: int,boss: String) -> void:
	selected_class=class_value
	stats=values.duplicate(true)
	floor_id=target_floor
	boss_name=boss
	processed=0
	wins=0
	total_seconds=0
	shortest=1000000
	longest=0
	combat_shortest=1000000
	combat_longest=0

func step(count: int=2) -> void:
	for i in range(count):
		if processed>=Simulation.COMBAT_VARIANTS: return
		var sim:=Simulation.new()
		sim.setup(selected_class,stats,floor_id,boss_name,1979+(processed+1)*104729)
		sim.simulate_to_end()
		var combat_seconds:=ceili(sim.elapsed)
		combat_shortest=mini(combat_shortest,combat_seconds)
		combat_longest=maxi(combat_longest,combat_seconds)
		var duration:=maxi(30,combat_seconds)
		total_seconds+=duration
		shortest=mini(shortest,duration)
		longest=maxi(longest,duration)
		if sim.won: wins+=1
		processed+=1

func complete() -> bool:
	return processed==Simulation.COMBAT_VARIANTS

func summary() -> Dictionary:
	if not complete(): return {}
	var average:=float(total_seconds)/processed
	var rate:=float(wins)/processed
	return {"rate":rate,"seconds":average,"shortest":shortest,"longest":longest,"clears_per_hour":3600.0/average*rate,"gold_per_hour":3600.0/average*(rate*(186+floor_id*4)+(1.0-rate)*55),"wins":wins,"patterns":processed,"combat_shortest":combat_shortest,"combat_longest":combat_longest}
