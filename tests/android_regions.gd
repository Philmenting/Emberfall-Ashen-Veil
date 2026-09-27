extends "res://scripts/main.gd"
## Separate Android visual/performance fixture. Never exported by the game presets.
var region_case := -1
var case_clock := 0.0
var case_captured := false
var transitioning := false
var fps_samples: Array[float] = []
func _ready() -> void:
	save_store=SaveStore.new("user://regional-art-"+str(Time.get_ticks_usec()))
	super._ready()
	var welcome:=get_node_or_null("Welcome")
	if welcome!=null: remove_child(welcome); welcome.queue_free()
	farm_enabled=false
	_next_case.call_deferred()
func _next_case() -> void:
	region_case+=1
	if region_case>=12:
		set_process(false)
		print("ANDROID_REGIONS_DONE")
		return
	floor_number=(region_case%4)*10+1
	character_class=["Vowkeeper","Arcanist","Ranger"][region_case/4]
	_start_run()
	# High health isolates rendering from progression balance during the showcase.
	expedition.stats.max_hp=100000
	expedition.hero_hp=100000
	expedition.stats.armor=10000
	expedition.stage=1 if region_case<8 else 5
	expedition.phase="combat"
	expedition.hero_pos=expedition.checkpoint(expedition.stage)+Vector2(0,3.0)
	_sync_model_state()
	_build_ui()
	case_clock=0.0
	case_captured=false
	transitioning=false
	fps_samples.clear()
func _process(delta: float) -> void:
	if region_case<0 or transitioning: return
	case_clock+=delta
	if case_clock>2.0: fps_samples.append(1.0/maxf(delta,0.001))
	if case_clock>=6.0 and not case_captured:
		case_captured=true
		_capture_case(region_case)
	if case_clock>=9.0:
		transitioning=true
		_next_case.call_deferred()
func _capture_case(index: int) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://region-%d.png" % index)
	var total:=0.0
	for sample in fps_samples: total+=sample
	print("ANDROID_REGION_CAPTURE case=",index," theme=",run_arena.world.theme.id," fps_mean=",snappedf(total/maxi(1,fps_samples.size()),0.1)," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
