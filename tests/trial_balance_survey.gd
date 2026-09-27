extends SceneTree
const Sim=preload("res://scripts/expedition_simulation.gd")
const Contract=preload("res://scripts/expedition_contract.gd")
func _initialize() -> void:
 var rows=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/trial_balance_013.json"))
 for row in rows:
  for tier in [10,20,30]:
   var wins:=0; var timeouts:=0; var duration:=0.0
   var values: Dictionary=row.stats.duplicate(true)
   values.expedition_contract=Contract.trial(tier)
   for serial in range(1,65):
    var sim:=Sim.new()
    sim.setup(row.class,values,Contract.trial_floor(tier),"Guardian",1979+serial*104729)
    sim.simulate_to_end()
    if sim.won: wins+=1
    elif sim.hero_hp>0: timeouts+=1
    duration+=sim.elapsed
   print("TRIAL_FRONTIER ",JSON.stringify({"class":row.class,"earned_after_runs":480,"trial":tier,"wins":wins,"timeouts":timeouts,"mean_seconds":duration/64.0}))
 quit()
