extends RefCounted
## Cooperative fixed-step AFK ledger. No threads, scene nodes or approximate combat.
const Simulation = preload("res://scripts/expedition_simulation.gd")
const MAX_SECONDS := 86400
var remaining := 0
var total_seconds := 0
var serial := 1
var profile_seed := 1
var floor_id := 1
var class_key := "Vowkeeper"
var boss_name := "Guardian"
var stats: Dictionary = {}
var outcomes: Dictionary = {}
var current: RefCounted
var done := false

static func seed_for_serial(world_seed: int, run_serial: int) -> int:
	return maxi(1,posmod(world_seed*48271+maxi(1,run_serial)*104729+1979,2147483647))

func setup(selected: String, values: Dictionary, target_floor: int, boss: String, seconds: int, next_serial: int, seed: int) -> void:
	class_key=selected; stats=values.duplicate(true); floor_id=target_floor
	boss_name=boss; remaining=clampi(seconds,0,MAX_SECONDS); total_seconds=remaining
	serial=next_serial; profile_seed=seed

func step(budget_usec: int=6000) -> Array:
	var completed: Array=[]
	var deadline := Time.get_ticks_usec()+maxi(1,budget_usec)
	while not done and completed.size()<12 and Time.get_ticks_usec()<deadline:
		if remaining<30:
			done=true
			break
		var seed_value := seed_for_serial(profile_seed,serial)
		var pattern := posmod(seed_value,Simulation.COMBAT_VARIANTS)
		if not outcomes.has(pattern):
			if current==null:
				current=Simulation.new()
				current.setup(class_key,stats,floor_id,boss_name,seed_value)
			current.advance(0.5)
			if not current.finished: continue
			outcomes[pattern]={"duration":maxi(30,ceili(current.elapsed)),"won":current.won}
			current=null
		var outcome: Dictionary=outcomes[pattern]
		if int(outcome.duration)>remaining:
			done=true
			break
		remaining-=int(outcome.duration)
		serial+=1
		completed.append({"won":outcome.won,"seed":seed_value})
	return completed
