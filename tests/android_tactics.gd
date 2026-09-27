extends "res://scripts/main.gd"
## Fresh isolated save, normal starting gear, actual floor-one rewards.
var captured_nova:=false
var captured_spacing:=false
var completed:=false
var spacing_steps:=0

func _ready() -> void:
	save_store=SaveStore.new("user://tactics-"+str(Time.get_ticks_usec()))
	super._ready()
	farm_enabled=false
	auto_repeat=false
	character_class="Arcanist"
	floor_number=1
	expedition_serial=1
	_start_run(1)
	print("ANDROID_TACTICS_START ",JSON.stringify(expedition.stats))

func _on_combat_advanced(updates: Array) -> void:
	super._on_combat_advanced(updates)
	for event in updates:
		if event.type=="nova" and not captured_nova:
			captured_nova=true
			_capture_nova()
	if expedition.action=="Creating spell distance":
		spacing_steps+=1
		if not captured_spacing:
			captured_spacing=true
			_capture("spacing")
	if expedition.finished and not completed:
		completed=true
		print("ANDROID_TACTICS_END ",JSON.stringify({"won":expedition.won,"elapsed":expedition.elapsed,"hp":expedition.hero_hp,"mana":expedition.hero_mana,"spacing_frames":spacing_steps,"loot":run_loot}))
		_capture_rewards()

func _capture_nova() -> void:
	await get_tree().create_timer(0.3).timeout
	_capture("nova")

func _capture_rewards() -> void:
	await get_tree().create_timer(1.6).timeout
	await _capture("loot")
	gear_tab="bag"
	_navigate("gear")
	await get_tree().create_timer(0.5).timeout
	await _capture("bag")
	print("ANDROID_TACTICS_DONE")

func _capture(moment: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://tactics-"+moment+".png")
	print("ANDROID_TACTICS_CAPTURE ",moment," page=",page," position=",expedition.hero_pos)
