extends "res://scripts/main.gd"
## Real Android UI, AFK recovery and restart journal. A dedicated offline QA package only.
const MARKER := "user://beta-qa.cfg"
var expected_gold := 0
var expected_runs := 0
var expected_serial := 0
var checked := false

func _ready() -> void:
	var marker := ConfigFile.new()
	if marker.load(MARKER)==OK and marker.get_value("qa","finished",false):
		checked=true
		super._ready()
		if pending_idle_runs==int(marker.get_value("qa","runs")) and expedition_serial==int(marker.get_value("qa","serial")):
			print("ANDROID_BETA_PASS restart does not repeat settled AFK rewards")
		else: print("ANDROID_BETA_FAIL duplicate settlement on restart")
		return
	onboarding_complete=true
	character_class="Arcanist"
	world_seed=1979
	floor_number=2
	farm_enabled=true
	var bot = preload("res://tests/balance_survey_bot.gd").new()
	bot.character_class=character_class; bot.world_seed=world_seed; bot.floor_number=floor_number
	bot._simulate_offline_time(3600)
	expected_gold=bot.pending_idle_ash; expected_runs=bot.pending_idle_runs; expected_serial=bot.expedition_serial
	bot.free()
	var now := int(Time.get_unix_time_from_system())
	clock_source=func(): return now
	last_saved_at=now
	var payload := _build_save_payload()
	payload.set_value("idle","saved_at",now-3600)
	save_store.save_game(payload)
	super._ready()
	print("ANDROID_BETA_READY cooperative=",offline_job!=null," version=",preload("res://scripts/release_info.gd").VERSION)

func _process(delta: float) -> void:
	super._process(delta)
	if checked or offline_job!=null: return
	checked=true
	if pending_idle_ash==expected_gold and pending_idle_runs==expected_runs and expedition_serial==expected_serial:
		print("ANDROID_BETA_PASS exact AFK ledger, runs=",pending_idle_runs," serial=",expedition_serial)
	else: print("ANDROID_BETA_FAIL AFK ledger mismatch")
	var marker := ConfigFile.new()
	marker.set_value("qa","finished",true)
	marker.set_value("qa","runs",pending_idle_runs)
	marker.set_value("qa","serial",expedition_serial)
	marker.save(MARKER)
	farm_enabled=false
	_save_progress()
	_capture.call_deferred()

func _capture() -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://beta-qa-camp.png")
