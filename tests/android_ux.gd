extends "res://scripts/main.gd"
## Separate touch-test package. Screenshots and state logs only; real UI handles input.
var ux_clock:=0.0
var ux_seen: Dictionary={}
var pause_state: Dictionary={}
var pause_clock:=0.0
var pause_verified:=false
func _ready() -> void:
	super._ready()
	print("ANDROID_UX_READY welcome=",has_node("Welcome"))
func _process(delta: float) -> void:
	ux_clock+=delta
	var state_key:=page+"-"+character_class+("-active" if run_active else "-idle")
	if ux_clock>1.0 and not ux_seen.has(state_key):
		ux_seen[state_key]=true
		_capture(state_key)
	if page=="run" and expedition!=null:
		if expedition.elapsed>=6.0 and not ux_seen.has("combat"):
			ux_seen.combat=true
			_capture("combat")
		if not run_active:
			if pause_state.is_empty(): pause_state=expedition.snapshot()
			pause_clock+=delta
			if pause_clock>2.0 and not pause_verified:
				pause_verified=true
				print("ANDROID_UX_PAUSE_", "PASS" if expedition.snapshot()==pause_state else "FAIL")
		else:
			pause_state={}
			pause_clock=0.0
func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://ux-"+label+".png")
	print("ANDROID_UX_CAPTURE page=",page," class=",character_class," active=",run_active," onboarding=",onboarding_complete," label=",label)
