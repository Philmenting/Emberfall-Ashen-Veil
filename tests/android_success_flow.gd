extends "res://scripts/main.gd"
## Real UI actions with ordinary starting gear in the isolated offline QA package.
const MARKER := "user://success-qa.cfg"
func _ready() -> void:
	super._ready()
	farm_enabled=false
	var marker:=ConfigFile.new()
	if marker.load(MARKER)==OK:
		if page=="run" and not run_active and expedition.contract()==Contract.combine(["cinder","hollow"]) and expedition.stats.get("class_relic")=="echo_lightning" and expedition.encode_snapshot().sha256_text()==marker.get_value("qa","snapshot_hash") and inventory.size()==marker.get_value("qa","bag_count") and equipment.Amulet.get("locked",false):
			print("ANDROID_SUCCESS_PASS restart preserves combined oaths, protected relic, checkpoint and rewards")
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
	var before_reading:=expedition.encode_snapshot()
	find_child("CombatSkill_chain",true,false).pressed.emit()
	await _capture("skill-reading")
	if run_active or not combat_details_open or expedition.encode_snapshot()!=before_reading:
		push_error("ANDROID_SUCCESS_FAIL reading did not freeze combat"); return
	if not _build_save_payload().get_value("run","active",false):
		push_error("ANDROID_SUCCESS_FAIL reading lost resume intent"); return
	last_back_frame=-1; _handle_back()
	if combat_details_open or not run_active:
		push_error("ANDROID_SUCCESS_FAIL Back did not resume after reading"); return
	run_arena.animation_enabled=false
	print("ANDROID_READABILITY_PASS real skill inspection pauses and Back resumes")
	_skip_run()
	if not run_succeeded or find_child("EquipClassRelic",true,false)==null: push_error("ANDROID_SUCCESS_FAIL first reward missing"); return
	await _capture("first-relic")
	find_child("ProtectItem",true,false).pressed.emit()
	find_child("EquipClassRelic",true,false).pressed.emit()
	if _combat_stats().get("class_relic")!="echo_lightning": push_error("ANDROID_SUCCESS_FAIL relic not equipped"); return
	gear_tab="bag"; _navigate("gear")
	find_child("BagViewFilter",true,false).item_selected.emit(3)
	if not _filtered_inventory().is_empty() or not equipment.Amulet.get("locked",false): push_error("ANDROID_SUCCESS_FAIL protection or filter mismatch"); return
	await _capture("filtered-bag")
	gear_tab="equipment"; _build_ui()
	var scroll:=find_child("PageScroll",true,false) as ScrollContainer
	await get_tree().process_frame
	scroll.scroll_vertical=100000
	await _capture("protected-gear")
	_return_to_camp()
	find_child("CampTable",true,false).pressed.emit()
	await _capture("oaths")
	find_child("Oathcinder",true,false).pressed.emit()
	find_child("Oathhollow",true,false).pressed.emit()
	find_child("StartOathExpedition",true,false).pressed.emit()
	_toggle_run_pause()
	if expedition.contract()!=Contract.combine(["cinder","hollow"]): push_error("ANDROID_SUCCESS_FAIL oath rule missing"); return
	await _capture("oath-run")
	var marker:=ConfigFile.new()
	marker.set_value("qa","snapshot_hash",expedition.encode_snapshot().sha256_text())
	marker.set_value("qa","bag_count",inventory.size())
	if marker.save(MARKER)!=OK: push_error("ANDROID_SUCCESS_FAIL marker save failed"); return
	print("ANDROID_SUCCESS_PASS first descent, class relic and combined oath UI")
	if "--quit-after-success" in OS.get_cmdline_user_args(): get_tree().quit()
func _capture(key: String) -> void:
	for frame in range(3): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://success-"+key+".png")
