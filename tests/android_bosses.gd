extends "res://scripts/main.gd"
## Separate visual fixture: jumps to each boss; high HP isolates rendering.
## Combat progression is tested separately in boss_patterns_smoke.gd.
var case_index:=-1
var case_clock:=0.0
var captured:=false
var evade_captured:=false
var changing:=false

func _ready() -> void:
	super._ready()
	farm_enabled=false
	auto_repeat=false
	_next_case.call_deferred()

func _next_case() -> void:
	case_index+=1
	if case_index>=8:
		_toggle_run_pause()
		set_process(false)
		print("ANDROID_BOSSES_DONE")
		return
	floor_number=(case_index%4)*10+1
	character_class="Arcanist"
	_start_run()
	expedition.stats.max_hp=10000
	expedition.hero_hp=10000
	expedition.stage=5
	expedition.phase="combat"
	expedition.hero_pos=Vector2(0,-60)
	expedition.waves[5][1].hp=0
	expedition.waves[5][2].hp=0
	var boss: Dictionary=expedition.waves[5][0]
	boss.special_cd=0.5
	if case_index>=4: boss.hp=int(boss.max_hp*0.49)
	_sync_model_state()
	_build_ui()
	case_clock=0.0
	captured=false
	evade_captured=false
	changing=false

func _process(delta: float) -> void:
	if case_index<0 or changing: return
	case_clock+=delta
	if case_clock>5.0:
		changing=true
		_next_case.call_deferred()

func _on_combat_advanced(updates: Array) -> void:
	super._on_combat_advanced(updates)
	for event in updates:
		if event.type=="warning" and event.has("zones") and not captured:
			captured=true
			_capture_case(case_index,"warning")
		if event.type=="evade" and not evade_captured:
			evade_captured=true
			_capture_case(case_index,"evade")

func _capture_case(index: int, moment: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://boss-%d-%s.png" % [index,moment])
	print("ANDROID_BOSS_CAPTURE case=",index," moment=",moment," pattern=",expedition.waves[5][0].warning.get("name","resolved")," awakened=",expedition.waves[5][0].awakened," hp=",expedition.hero_hp," position=",expedition.hero_pos)
