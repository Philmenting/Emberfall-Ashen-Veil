extends "res://scripts/main.gd"
## Dedicated preview-package entry point, never the normal game's main scene.
var preview_clock := 0.0
var captured_steps: Dictionary = {}
func _ready() -> void:
	super._ready()
	farm_enabled = false
	floor_number = 1
	character_class = "Vowkeeper"
	_start_run()
func _process(delta: float) -> void:
	preview_clock += delta
	for moment in [2,12,25,40,58,75]:
		if preview_clock >= moment and not captured_steps.has(moment):
			captured_steps[moment] = true
			_capture(moment)
func _capture(moment: int) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://android-3d-%02d.png" % moment)
	print("ANDROID_3D_CAPTURE time=",moment," page=",page," stage=",run_stage," fps=",Engine.get_frames_per_second())

func _on_combat_advanced(updates: Array) -> void:
	for event in updates:
		if event.type=="warning" and expedition.enemy_by_id(event.source).role=="boss" and not captured_steps.has(90):
			captured_steps[90]=true
			_capture(90)
	super._on_combat_advanced(updates)
