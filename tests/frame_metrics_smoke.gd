extends SceneTree
const Metrics=preload("res://scripts/frame_metrics.gd")
var checks:=0
var failures:=0
func check(value:bool,description:String)->void:
	checks+=1
	if value: print("PASS: ",description)
	else: failures+=1; push_error("FAIL: "+description)
func _initialize()->void:
	var metrics:=Metrics.new()
	check(metrics.rows().is_empty(),"no result is fabricated before active play")
	var t:=1000000
	metrics.sample(t,true,"balanced",{"quality":"balanced","render_width":1200,"render_height":540})
	for i in range(101):
		t+=20000; metrics.sample(t,true,"balanced")
	var before:int=metrics.rows()[0].frames
	for i in range(99):
		t+=20000; metrics.sample(t,true,"balanced")
	var row:Dictionary=metrics.rows()[0]
	check(row.frames==before+99 and is_equal_approx(row.mean_fps,50.0) and is_equal_approx(row.p95_frame_ms,20.0),"known wall intervals yield correct mean and percentile")
	# The metadata belongs to the case's measured context, not a last-frame guess.
	check(row.get("quality","")=="balanced","case retains its rendering context")
	var count:int=row.frames
	t+=100000000; metrics.sample(t,false,"balanced")
	t+=50000000; metrics.sample(t,true,"balanced")
	check(metrics.rows()[0].frames==count,"pause and resume gap cannot pollute frame pacing")
	for i in range(110):
		t+=20000; metrics.sample(t,true,"balanced")
	t+=100000; metrics.sample(t,true,"balanced")
	check(metrics.rows()[0].worst_frame_ms==100.0 and metrics.rows()[0].frames_over_50_ms==1,"real gameplay stall remains in measurements")
	for i in range(2100):
		t+=20000; metrics.sample(t,true,"balanced")
	row=metrics.rows()[0]
	check(row.frames==Metrics.CAPACITY and row.worst_frame_ms==20.0,"bounded rolling window discards old samples without distorting new ones")
	for c in range(10):
		var key:="case-"+str(c)
		for i in range(110):
			t+=20000; metrics.sample(t,true,key,{"quality":key})
	check(metrics.rows().size()==Metrics.MAX_CASES and metrics.rows().back().quality=="case-9","bounded cases retain recent quality and display combinations")
	for i in range(110):
		t+=20000; metrics.sample(t,true,"case-2",{"quality":"case-2"})
	check(metrics.rows().back().quality=="case-2","returning to an existing mode updates the last-measured summary")
	for i in range(110):
		t+=20000; metrics.sample(t,true,"case-10",{"quality":"case-10"})
	var kept:Array=[]
	for measured in metrics.rows(): kept.append(measured.quality)
	check(kept.has("case-2") and not kept.has("case-3") and kept.back()=="case-10","bounded history evicts the least recently measured case")
	check(metrics.report().storage.contains("Memory only") and not metrics.report().has("save"),"copyable report contains measurements and no save or account data")
	print("FRAME METRICS SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
