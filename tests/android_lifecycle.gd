extends "res://scripts/main.gd"
## Dedicated package fixture: launch, background/kill, relaunch, kill, relaunch.
## Uses the real game save/resume path; never ship as the application's main scene.
var lifecycle_stage := 0
const MARKER := "user://lifecycle-test.cfg"

func _ready() -> void:
	var marker := ConfigFile.new()
	marker.load(MARKER)
	lifecycle_stage = int(marker.get_value("test","stage",0))
	var previous: ConfigFile = save_store.load_save()
	var expected: RefCounted
	if lifecycle_stage==1 and previous!=null:
		expected=Expedition.new()
		if not expected.restore_encoded(previous.get_value("run","snapshot","")):
			print("ANDROID_LIFECYCLE_FAIL invalid checkpoint")
			expected=null
		else:
			var away:=clampi(int(Time.get_unix_time_from_system())-int(previous.get_value("idle","saved_at",0)),0,MAX_OFFLINE_SECONDS)
			expected.advance(float(away))
	super._ready()
	if lifecycle_stage==0:
		farm_enabled=true
		_start_run(1)
		get_tree().create_timer(12.0).timeout.connect(_checkpoint)
	elif lifecycle_stage==1:
		if expected!=null and expedition!=null and expedition.snapshot()==expected.snapshot():
			print("ANDROID_LIFECYCLE_PASS cold restart matches saved combat plus elapsed background time; elapsed=",expedition.elapsed)
		else: print("ANDROID_LIFECYCLE_FAIL restart differs")
		_capture("restored")
		get_tree().create_timer(3.0).timeout.connect(_settle)
	else:
		farm_enabled=false
		if player_gold==int(marker.get_value("test","gold",-1)) and pending_idle_runs==0 and page=="camp":
			print("ANDROID_LIFECYCLE_PASS settled run is not rewarded twice")
		else: print("ANDROID_LIFECYCLE_FAIL repeated settlement")
		_capture("settled")

func _checkpoint() -> void:
	_save_progress()
	var marker:=ConfigFile.new()
	marker.set_value("test","stage",1)
	marker.save(MARKER)
	_capture("checkpoint")
	print("ANDROID_LIFECYCLE_READY elapsed=",expedition.elapsed," hp=",expedition.hero_hp," stage=",expedition.stage)

func _settle() -> void:
	_skip_run()
	farm_enabled=false
	_save_progress()
	var marker:=ConfigFile.new()
	marker.set_value("test","stage",2)
	marker.set_value("test","gold",player_gold)
	marker.save(MARKER)
	_capture("loot")
	print("ANDROID_LIFECYCLE_SETTLED gold=",player_gold)

func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://lifecycle-"+label+".png")
