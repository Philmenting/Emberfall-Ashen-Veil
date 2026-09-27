extends "res://scripts/main.gd"
## Starts in the real skill editor. An actual Starfall slot-I tap starts the run.
var capture_keys: Dictionary={}
var started:=false
var completed:=false
func _ready() -> void:
	save_store=SaveStore.new("user://skills-"+str(Time.get_ticks_usec()))
	super._ready()
	farm_enabled=false
	onboarding_complete=true
	var welcome:=get_node_or_null("Welcome")
	if welcome!=null: remove_child(welcome); welcome.queue_free()
	character_class="Arcanist"
	floor_number=1
	expedition_serial=1
	gear_tab="skills"
	_navigate("gear")
	print("ANDROID_SKILLS_READY ",save_store.base_path)
	for child in find_children("*","ScrollContainer",true,false):
		var scrolling: ScrollContainer=child
		scrolling.scroll_started.connect(func(): print("ANDROID_SKILLS_SCROLL_START"))
		scrolling.scroll_ended.connect(func(): print("ANDROID_SKILLS_SCROLL_END"))
func _equip_technique(key: String, slot: int) -> void:
	super._equip_technique(key,slot)
	print("ANDROID_SKILLS_EQUIP ",key," slot=",slot," loadout=",skill_loadouts.Arcanist)
	if key=="starfall" and slot==0 and not started:
		started=true
		_start_after_selection()
func _start_after_selection() -> void:
	await _capture("selection")
	await get_tree().create_timer(1.2).timeout
	_start_run(1)
	print("ANDROID_SKILLS_START ",JSON.stringify(expedition.stats))
func _on_combat_advanced(updates: Array) -> void:
	super._on_combat_advanced(updates)
	for event in updates:
		if event.type=="technique_cast": _once("cast-"+String(event.ability_id))
		if event.type=="technique":
			_once("impact-"+String(event.ability_id))
			print("ANDROID_SKILLS_IMPACT ",event.ability_id," ",expedition.hero_mana," Mana")
	if expedition.finished and not completed:
		completed=true
		print("ANDROID_SKILLS_END ",JSON.stringify({"won":expedition.won,"elapsed":expedition.elapsed,"hp":expedition.hero_hp,"mana":expedition.hero_mana,"rotation":expedition.rotation,"loot":run_loot}))
		_finish_capture()
func _once(moment: String) -> void:
	if capture_keys.has(moment): return
	capture_keys[moment]=true
	_capture(moment)
func _finish_capture() -> void:
	await get_tree().create_timer(1.6).timeout
	await _capture("loot")
	print("ANDROID_SKILLS_DONE")
func _capture(moment: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://skills-"+moment+".png")
	print("ANDROID_SKILLS_CAPTURE ",moment)
