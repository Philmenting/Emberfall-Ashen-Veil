extends "res://scripts/main.gd"
## Separate Android package; observes real touch and Android Back events only.
var capture: AudioEffectCapture
var report_clock:=0.0
var observed_state: Dictionary={}
var paused_snapshot: Dictionary={}
var paused_clock:=0.0
var observed_peak:=0.0

func _ready() -> void:
	super._ready()
	capture=AudioEffectCapture.new()
	AudioServer.add_bus_effect(0,capture)
	print("ANDROID_OPTIONS_READY driver=",AudioServer.get_driver_name())

func _process(delta: float) -> void:
	var next: Dictionary={"page":page,"active":run_active,"menu":has_node("Options"),"settings":preferences.duplicate()}
	if next!=observed_state:
		observed_state=next
		print("ANDROID_OPTIONS_STATE ",JSON.stringify(next))
	if page=="run" and not run_active:
		if paused_snapshot.is_empty(): paused_snapshot=expedition.snapshot()
		paused_clock+=delta
		if paused_clock>2.0:
			print("ANDROID_OPTIONS_PAUSE_", "PASS" if paused_snapshot==expedition.snapshot() else "FAIL")
			paused_clock=-1000.0
	else:
		paused_snapshot={}
		paused_clock=0.0
	if capture==null: return
	var samples:=capture.get_buffer(capture.get_frames_available())
	for frame in samples: observed_peak=maxf(observed_peak,maxf(absf(frame.x),absf(frame.y)))
	report_clock+=delta
	if report_clock>=5.0:
		print("ANDROID_OPTIONS_AUDIO peak=",observed_peak," master=",preferences.master," music=",preferences.music," effects=",preferences.effects)
		report_clock=0.0
		observed_peak=0.0

func _handle_back() -> void:
	print("ANDROID_OPTIONS_BACK frame=",Engine.get_process_frames()," menu_before=",has_node("Options"))
	super._handle_back()
