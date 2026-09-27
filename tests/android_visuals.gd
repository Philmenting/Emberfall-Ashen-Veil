extends "res://scripts/main.gd"
var visual_clock:=0.0
var shots: Dictionary={}
func _ready() -> void:
	save_store=SaveStore.new("user://visuals-"+str(Time.get_ticks_usec()))
	super._ready()
	farm_enabled=false
	onboarding_complete=true
	var welcome:=get_node_or_null("Welcome")
	if welcome!=null: remove_child(welcome); welcome.queue_free()
	character_class="Arcanist"
	_start_run(1)
func _process(delta: float) -> void:
	visual_clock+=delta
	for moment in [2,12,35,60,85]:
		if visual_clock>=moment and not shots.has(moment):
			shots[moment]=true
			_capture(moment)
func _capture(moment: int) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://visuals-%02d.png" % moment)
	print("ANDROID_VISUAL ",moment," fps=",Engine.get_frames_per_second()," draws=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," page=",page," stage=",run_stage)
func _on_combat_advanced(updates: Array) -> void:
	super._on_combat_advanced(updates)
	if expedition.finished and not shots.has(100):
		shots[100]=true
		print("ANDROID_VISUAL_END ",JSON.stringify({"won":expedition.won,"elapsed":expedition.elapsed,"hp":expedition.hero_hp,"mana":expedition.hero_mana,"loot":run_loot}))
