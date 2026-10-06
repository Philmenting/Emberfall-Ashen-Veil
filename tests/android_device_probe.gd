extends "res://scripts/main.gd"
## QA-only wall-clock workload. The adb observer must establish physical hardware.
## Every run uses ordinary floor-1 equipment, the production simulation and renderer.
const CONFIG_PATH:="user://device-probe-config.json"
const STATUS_PATH:="user://device-probe-status.json"
const REPORT_PATH:="user://device-performance.json"
var probe_case_seconds:=200.0
var probe_warmup_seconds:=3.0
var probe_cases:Array=[]
var probe_case:Dictionary={}
var probe_initial_equipment:Dictionary={}
var probe_initial_attributes:Dictionary={}
var probe_source:Dictionary={}
var probe_started_usec:=0
var probe_failed:=false
var probe_probe_only:=false

func _ready() -> void:
	save_store=SaveStore.new("user://device-probe-"+str(Time.get_ticks_usec()))
	super._ready()
	set_process(false)
	farm_enabled=false; offline_job=null; pending_afk_seconds=0; auto_repeat=false
	world_seed=1979; onboarding_complete=true
	probe_initial_equipment=equipment.duplicate(true)
	probe_initial_attributes=allocated_attributes.duplicate(true)
	var welcome:=get_node_or_null("Welcome")
	if welcome!=null: remove_child(welcome); welcome.queue_free()
	_probe.call_deferred()

func _probe() -> void:
	if FileAccess.file_exists(CONFIG_PATH):
		var config:Variant=JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
		if not config is Dictionary:
			_fail_probe("invalid probe configuration"); return
		probe_case_seconds=clampf(float(config.get("case_seconds",200.0)),4.0,600.0)
		probe_warmup_seconds=clampf(float(config.get("warmup_seconds",3.0)),1.0,10.0)
		probe_source=config.get("provenance",{}).duplicate(true)
		probe_probe_only=bool(config.get("short_fixture_smoke",false))
	probe_started_usec=Time.get_ticks_usec()
	_write_status("ready")
	print("ANDROID_DEVICE_PROBE_READY cases=6 case_seconds=",probe_case_seconds)
	for battery in [false,true]:
		preferences.battery=battery
		preferences.reduced_motion=false
		_apply_preferences()
		for selected in ["Vowkeeper","Arcanist","Ranger"]:
			var measurement:Dictionary=await _measure_case(selected,battery)
			if probe_failed: return
			probe_cases.append(measurement)
			print("ANDROID_DEVICE_CASE_MEASURED ",JSON.stringify(measurement))
	var valid:=probe_cases.size()==6
	for row in probe_cases:
		valid=valid and int(row.frames)>=30 and float(row.simulation_seconds)>0.0 and int(row.hero_attacks)>0
	if not valid:
		_fail_probe("a case lacked advancing ordinary combat"); return
	var report:Dictionary={"schema":2,"status":"measured","physical_hardware_verified_by_fixture":false,
		"workload":"six real-time repeated floor-1 expeditions; ordinary starting equipment, no stat buffs or travel skips",
		"device":OS.get_model_name(),"platform":OS.get_name(),"renderer":RenderingServer.get_current_rendering_method(),
		"engine":Engine.get_version_info().string,"case_seconds":probe_case_seconds,"warmup_seconds":probe_warmup_seconds,
		"short_fixture_smoke":probe_probe_only,"elapsed_seconds":float(Time.get_ticks_usec()-probe_started_usec)/1000000.0,
		"logical_resolution":{"width":get_viewport_rect().size.x,"height":get_viewport_rect().size.y},
		"provenance":probe_source,"measurements":probe_cases,
		"scope":"Post-draw wall-clock intervals, Godot process/physics CPU and 3D viewport render timings. GPU timings are null if the renderer returns no positive timestamps; this is not GPU utilisation or touch latency. App and renderer timing instrumentation adds overhead.",
		"touch_acceptance":"pending; requires observed touch, Android Back, insets and lifecycle on the physical device"}
	if not _write_json(REPORT_PATH,report):
		_fail_probe("performance report write failed"); return
	run_active=false
	if is_instance_valid(run_arena): run_arena.animation_enabled=false
	_write_status("measured")
	print("ANDROID_DEVICE_PROBE_MEASURED cases=6 ordinary_combat=true")
	if "--quit-after-probe" in OS.get_cmdline_user_args(): get_tree().quit()

func _start_probe_run() -> void:
	# Repeat from the same starting build: earned XP/rewards never improve the probe.
	equipment=probe_initial_equipment.duplicate(true)
	allocated_attributes=probe_initial_attributes.duplicate(true)
	player_level=1; attribute_points=0
	_start_run(1)
	if is_instance_valid(run_arena):
		RenderingServer.viewport_set_measure_render_time(run_arena.render_viewport.get_viewport_rid(),true)
	probe_case.runs_started=int(probe_case.get("runs_started",0))+1
	probe_case.last_sim_elapsed=0.0

func _measure_case(selected:String,battery:bool) -> Dictionary:
	character_class=selected
	probe_case={"class":selected,"quality":"battery" if battery else "balanced","target_fps":30 if battery else 60,
		"runs_started":0,"runs_completed":0,"guardian_attacks":0,"hero_attacks":0,"hits":0,"simulation_seconds":0.0,
		"render_configurations":{}}
	_start_probe_run()
	var started:=Time.get_ticks_usec()
	var previous:=started
	var warmup_until:=started+int(probe_warmup_seconds*1000000.0)
	var next_status:=started
	var frame_ms:Array[float]=[]
	var route_frame_ms:Array[float]=[]
	var guardian_frame_ms:Array[float]=[]
	var process_ms:Array[float]=[]
	var physics_ms:Array[float]=[]
	var render_cpu_ms:Array[float]=[]
	var render_gpu_ms:Array[float]=[]
	var draws:Array[float]=[]
	var static_bytes:Array[float]=[]
	while float(Time.get_ticks_usec()-started)/1000000.0<probe_case_seconds:
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var now:=Time.get_ticks_usec()
		if expedition.finished:
			probe_case.runs_completed+=1
			_start_probe_run()
			warmup_until=now+int(probe_warmup_seconds*1000000.0)
		elif now>=warmup_until and is_instance_valid(run_arena) and run_active:
			frame_ms.append(float(now-previous)/1000.0)
			if expedition.stage==5 and expedition.phase=="combat": guardian_frame_ms.append(float(now-previous)/1000.0)
			else: route_frame_ms.append(float(now-previous)/1000.0)
			process_ms.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000.0)
			physics_ms.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0)
			var rid:RID=run_arena.render_viewport.get_viewport_rid()
			render_cpu_ms.append(RenderingServer.viewport_get_measured_render_time_cpu(rid))
			render_gpu_ms.append(RenderingServer.viewport_get_measured_render_time_gpu(rid))
			draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
			static_bytes.append(Performance.get_monitor(Performance.MEMORY_STATIC))
			probe_case.render_width=run_arena.render_viewport.size.x
			probe_case.render_height=run_arena.render_viewport.size.y
			var actual_quality:="battery" if battery else "balanced-adaptive" if run_arena.budget.reduced else "balanced"
			var render_key:="%dx%d / %s" % [probe_case.render_width,probe_case.render_height,actual_quality]
			if not probe_case.render_configurations.has(render_key):
				probe_case.render_configurations[render_key]={"quality":actual_quality,"width":probe_case.render_width,"height":probe_case.render_height,"frames":0}
			probe_case.render_configurations[render_key].frames+=1
		if now>=next_status:
			_write_status("measuring")
			next_status=now+5000000
		previous=now
		if frame_ms.size()>=36000:
			_fail_probe("measured frame limit exceeded"); return {}
	probe_case.frames=frame_ms.size()
	probe_case.case_wall_seconds=float(Time.get_ticks_usec()-started)/1000000.0
	probe_case.frame_intervals=_distribution(frame_ms)
	probe_case.ordinary_route_frame_intervals=_distribution(route_frame_ms)
	probe_case.guardian_frame_intervals=_distribution(guardian_frame_ms)
	probe_case.frame_intervals["frames_over_target_plus_5_percent"]=0
	probe_case.frame_intervals["frames_over_50_ms"]=0
	for interval in frame_ms:
		if interval>1000.0/float(probe_case.target_fps)*1.05:
			probe_case.frame_intervals.frames_over_target_plus_5_percent+=1
		if interval>50.0: probe_case.frame_intervals.frames_over_50_ms+=1
	probe_case.process_cpu_ms=_distribution(process_ms)
	probe_case.physics_cpu_ms=_distribution(physics_ms)
	probe_case.viewport_render_cpu_ms=_distribution(render_cpu_ms)
	probe_case.viewport_render_gpu_ms=_distribution(render_gpu_ms) if _has_positive(render_gpu_ms) else null
	probe_case.gpu_timing_status="measured" if probe_case.viewport_render_gpu_ms!=null else "unavailable_for_renderer"
	probe_case.draw_calls=_distribution(draws)
	probe_case.godot_static_memory_bytes=_distribution(static_bytes)
	return probe_case.duplicate(true)

func _on_combat_advanced(updates:Array) -> void:
	# Keep the real live renderer, event hooks and HUD; restarting adds no rewards.
	_sync_model_state(); _sync_combat_hud()
	if is_instance_valid(audio): audio.combat_events(updates,character_class)
	for event in updates:
		if event.type=="hero_attack": probe_case.hero_attacks=int(probe_case.get("hero_attacks",0))+1
		if event.type=="impact" and int(event.get("source",-1))==50:
			probe_case.guardian_attacks=int(probe_case.get("guardian_attacks",0))+1
		if event.type=="hit": probe_case.hits=int(probe_case.get("hits",0))+1
	probe_case.simulation_seconds=float(probe_case.get("simulation_seconds",0.0))+maxf(0.0,expedition.elapsed-float(probe_case.get("last_sim_elapsed",0.0)))
	probe_case.last_sim_elapsed=expedition.elapsed

func _distribution(values:Array[float]) -> Dictionary:
	if values.is_empty(): return {"samples":0}
	var sorted:=values.duplicate()
	sorted.sort()
	var total:=0.0
	for value in sorted:
		total+=value
	return {"samples":sorted.size(),"mean":total/float(sorted.size()),"median":sorted[floori(float(sorted.size()-1)*.5)],
		"p95":sorted[mini(sorted.size()-1,ceili(float(sorted.size())*.95)-1)],"p99":sorted[mini(sorted.size()-1,ceili(float(sorted.size())*.99)-1)],
		"max":sorted.back()}

func _has_positive(values:Array[float]) -> bool:
	for value in values:
		if value>0.0: return true
	return false

func _write_json(path:String,value:Dictionary) -> bool:
	var output:=FileAccess.open(path,FileAccess.WRITE)
	if output==null: return false
	output.store_string(JSON.stringify(value,"\t")); output.close()
	return true

func _write_status(status:String) -> void:
	_write_json(STATUS_PATH,{"schema":1,"status":status,"completed_cases":probe_cases.size(),"case":probe_case,
		"elapsed_seconds":float(Time.get_ticks_usec()-probe_started_usec)/1000000.0,"case_seconds":probe_case_seconds})

func _fail_probe(reason:String) -> void:
	probe_failed=true
	_write_json(STATUS_PATH,{"schema":1,"status":"failed","failure":reason,"completed_cases":probe_cases.size()})
	print("ANDROID_DEVICE_PROBE_FAIL ",reason)
	if "--quit-after-probe" in OS.get_cmdline_user_args(): get_tree().quit(1)
