extends RefCounted
## Local, bounded wall-clock measurements. No file, network or simulation writes.
const CAPACITY:=1800
const MAX_CASES:=8
const WARMUP_SECONDS:=2.0
var cases: Dictionary={}
var previous_usec:=0
var previous_key:=""
var was_active:=false
var warmup:=WARMUP_SECONDS
var case_context:Dictionary={}
var last_recorded_key:=""

func sample(now_usec: int,active: bool,key: String,context: Dictionary={}) -> void:
	if not active:
		was_active=false; previous_usec=now_usec
		return
	if not was_active or key!=previous_key or now_usec<=previous_usec:
		previous_usec=now_usec; previous_key=key; was_active=true
		case_context=context.duplicate(true)
		warmup=WARMUP_SECONDS
		return
	var seconds:=float(now_usec-previous_usec)/1000000.0
	previous_usec=now_usec
	if warmup>0.0:
		warmup=maxf(0.0,warmup-seconds)
		return
	if not cases.has(key):
		if cases.size()>=MAX_CASES: cases.erase(cases.keys()[0])
		var values:=PackedFloat64Array(); values.resize(CAPACITY)
		cases[key]={"times":values,"cursor":0,"count":0,"context":case_context.duplicate(true)}
	elif key!=last_recorded_key:
		# A revisited graphics mode is recent too, even if its case was created
		# earlier. Keep the summary and bounded eviction order truthful.
		var revisited:Dictionary=cases[key]
		cases.erase(key); cases[key]=revisited
	last_recorded_key=key
	var entry: Dictionary=cases[key]
	entry.times[entry.cursor]=seconds*1000.0
	entry.cursor=(int(entry.cursor)+1)%CAPACITY
	entry.count=mini(int(entry.count)+1,CAPACITY)

func rows() -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for key in cases:
		var entry: Dictionary=cases[key]
		var count:int=entry.count
		if count==0: continue
		var times:PackedFloat64Array=entry.times.slice(0,count)
		times.sort()
		var total:=0.0; var above_33:=0; var above_50:=0
		for value in times:
			total+=value
			if value>33.334: above_33+=1
			if value>50.0: above_50+=1
		var row: Dictionary=entry.context.duplicate(true)
		row.merge({"case":key,"frames":count,"sample_seconds":total/1000.0,
			"mean_fps":float(count)*1000.0/total,"median_frame_ms":(times[floori((count-1)*.5)]+times[floori(count*.5)])*.5,
			"p95_frame_ms":times[mini(count-1,ceili(count*.95)-1)],"worst_frame_ms":times[count-1],
			"frames_over_33_ms":above_33,"frames_over_50_ms":above_50})
		result.append(row)
	return result

func report() -> Dictionary:
	return {"schema":1,"device":OS.get_model_name(),"platform":OS.get_name(),
		"renderer":RenderingServer.get_current_rendering_method(),"measurements":rows(),
		"scope":"Local active-combat wall-clock frame intervals. Two seconds warmup after resume or case change; latest 1800 frames per case, at most eight cases. No thermal or touch measurement. Device identity is not proof of physical hardware.",
		"storage":"Memory only; shared only by an explicit copy action."}

func summary() -> String:
	var measured:=rows()
	if measured.is_empty(): return "Play an expedition for a few seconds to measure frame pacing on this device. Paused time is excluded."
	var latest:Dictionary=measured.back()
	return "Last measured: %.1f FPS average · %.1f ms p95 · %d frames.\n%s · %dx%d rendered" % [latest.mean_fps,latest.p95_frame_ms,latest.frames,latest.get("quality",""),latest.get("render_width",0),latest.get("render_height",0)]
