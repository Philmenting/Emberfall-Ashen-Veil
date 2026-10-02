extends "res://scripts/main.gd"
## Real UI actions with ordinary starting gear in the isolated offline QA package.
const MARKER := "user://success-qa.cfg"
func _ready() -> void:
	super._ready()
	farm_enabled=false
	var marker:=ConfigFile.new()
	if marker.load(MARKER)==OK:
		if page=="run" and not run_active and expedition.contract()==Contract.oath("cinder") and expedition.stats.get("class_relic")=="echo_lightning" and expedition.encode_snapshot().sha256_text()==marker.get_value("qa","snapshot_hash") and inventory.size()==marker.get_value("qa","bag_count"):
			print("ANDROID_SUCCESS_PASS restart preserves oath, relic, checkpoint and rewards")
		else: push_error("ANDROID_SUCCESS_FAIL checkpoint changed on restart")
		if "--quit-after-success" in OS.get_cmdline_user_args(): get_tree().quit()
		return
	_run_flow.call_deferred()
func _run_flow() -> void:
	var choose:=find_child("ChooseArcanist",true,false)
	if choose==null: push_error("ANDROID_SUCCESS_FAIL missing first-run choice"); return
	choose.pressed.emit()
	await _capture("welcome")
	find_child("BeginExpedition",true,false).pressed.emit()
	run_arena.animation_enabled=false
	var updates: Array=expedition.advance(1.0)
	_on_combat_advanced(updates)
	if expedition.casts<1: push_error("ANDROID_SUCCESS_FAIL signature did not fire early"); return
	await _capture("first-fight")
	_skip_run()
	if not run_succeeded or find_child("EquipClassRelic",true,false)==null: push_error("ANDROID_SUCCESS_FAIL first reward missing"); return
	await _capture("first-relic")
	find_child("EquipClassRelic",true,false).pressed.emit()
	if _combat_stats().get("class_relic")!="echo_lightning": push_error("ANDROID_SUCCESS_FAIL relic not equipped"); return
	_return_to_camp()
	await _capture("oaths")
	find_child("Oathcinder",true,false).pressed.emit()
	_toggle_run_pause()
	if expedition.contract()!=Contract.oath("cinder"): push_error("ANDROID_SUCCESS_FAIL oath rule missing"); return
	await _capture("oath-run")
	var marker:=ConfigFile.new()
	marker.set_value("qa","snapshot_hash",expedition.encode_snapshot().sha256_text())
	marker.set_value("qa","bag_count",inventory.size())
	if marker.save(MARKER)!=OK: push_error("ANDROID_SUCCESS_FAIL marker save failed"); return
	print("ANDROID_SUCCESS_PASS first descent, class relic and oath UI")
	if "--quit-after-success" in OS.get_cmdline_user_args(): get_tree().quit()
func _capture(key: String) -> void:
	for frame in range(3): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://success-"+key+".png")
