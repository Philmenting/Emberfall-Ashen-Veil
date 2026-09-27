extends "res://scripts/main.gd"
## Isolated Android touch fixture; campaign unlock is earned by a normal skip.
var capture_keys: Dictionary={}
var hunt_finished:=false
var trial_finished:=false
func _ready() -> void:
	save_store=SaveStore.new("user://contracts-"+str(Time.get_ticks_usec()))
	super._ready()
	farm_enabled=false
	onboarding_complete=true
	var welcome:=get_node_or_null("Welcome")
	if welcome!=null: remove_child(welcome); welcome.queue_free()
	character_class="Arcanist"
	_start_run(1)
	_skip_run()
	print("ANDROID_CONTRACT_UNLOCK ",JSON.stringify({"floor":floor_number,"won":run_succeeded,"hp":expedition.hero_hp,"gear":equipment}))
	world_tab="hunts"
	_navigate("map")
	_capture("hunt-menu")
func _choose_farm_goal(slot: String) -> void:
	super._choose_farm_goal(slot)
	print("ANDROID_CONTRACT_SELECT ",JSON.stringify(_farm_contract()))
func _start_farming() -> void:
	super._start_farming()
	print("ANDROID_CONTRACT_HUNT_START ",JSON.stringify(expedition.stats))
func _start_trial() -> void:
	super._start_trial()
	print("ANDROID_CONTRACT_TRIAL_START ",JSON.stringify(expedition.stats))
	_capture("trial-gate")
func _on_combat_advanced(updates: Array) -> void:
	super._on_combat_advanced(updates)
	var mode:=Contract.mode(expedition.contract())
	if mode=="hunt" and expedition.stage>=2: _once("hunt-combat")
	if mode=="trial" and expedition.stage==5 and not expedition.finished: _once("trial-boss")
	if not expedition.finished: return
	if mode=="hunt" and not hunt_finished:
		print("ANDROID_CONTRACT_HUNT_END ",JSON.stringify({"won":expedition.won,"elapsed":expedition.elapsed,"loot":run_loot,"floor":floor_number,"rules":expedition.contract()}))
		if not auto_repeat:
			hunt_finished=true
			_hunt_done()
	if mode=="trial" and not trial_finished:
		trial_finished=true
		print("ANDROID_CONTRACT_TRIAL_END ",JSON.stringify({"won":expedition.won,"elapsed":expedition.elapsed,"loot":run_loot,"floor":floor_number,"trial_cleared":trial_cleared,"reward":run_reward}))
		_trial_done()
func _hunt_done() -> void:
	await get_tree().create_timer(1.6).timeout
	await _capture("hunt-loot")
	await get_tree().create_timer(1.0).timeout
	world_tab="trials"
	_navigate("map")
	await _capture("trial-menu")
func _trial_done() -> void:
	await get_tree().create_timer(1.6).timeout
	await _capture("trial-loot")
	print("ANDROID_CONTRACT_DONE")
func _once(moment: String) -> void:
	if capture_keys.has(moment): return
	capture_keys[moment]=true
	_capture(moment)
func _capture(moment: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://contracts-"+moment+".png")
	print("ANDROID_CONTRACT_CAPTURE ",moment)
