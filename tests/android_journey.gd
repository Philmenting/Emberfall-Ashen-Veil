extends "res://scripts/main.gd"
## Actual starter expedition; no modified health, gear, damage or combat speed.
var captured: Dictionary={}
var completed:=false
func _ready() -> void:
	save_store=SaveStore.new("user://journey-"+str(Time.get_ticks_usec()))
	super._ready()
	farm_enabled=false
	auto_repeat=false
	character_class="Arcanist"
	floor_number=1
	expedition_serial=1
	_start_run(1)
	print("ANDROID_JOURNEY_START ",JSON.stringify(expedition.stats))
func _on_combat_advanced(updates: Array) -> void:
	super._on_combat_advanced(updates)
	if expedition.finished and not completed:
		completed=true
		print("ANDROID_JOURNEY_END ",JSON.stringify({"won":expedition.won,"elapsed":expedition.elapsed,"hp":expedition.hero_hp,"kills":expedition.kills,"journey":expedition.journey,"loot":run_loot}))
		_capture_rewards()
		return
	if expedition.stage==0 and expedition.phase=="combat": _once("pack")
	if expedition.stage==1 and expedition.phase=="travel" and expedition.journey.travel_index==2: _once("turn")
	if expedition.stage==1 and expedition.phase=="interact" and expedition.journey.channel>0.4: _once("well")
	if expedition.stage==3 and expedition.phase=="interact" and expedition.journey.channel>0.4: _once("seal")
	if expedition.stage==5 and expedition.phase=="combat": _once("boss")
	if expedition.journey.chest_open and not expedition.finished: _once("chest")
func _once(moment: String) -> void:
	if captured.has(moment): return
	captured[moment]=true
	_capture(moment)
func _capture_rewards() -> void:
	await get_tree().create_timer(1.6).timeout
	await _capture("loot")
	print("ANDROID_JOURNEY_DONE")
func _capture(moment: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://journey-"+moment+".png")
	print("ANDROID_JOURNEY_CAPTURE ",moment," ",expedition.hero_pos)
