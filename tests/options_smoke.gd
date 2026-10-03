extends SceneTree
const Preferences=preload("res://scripts/game_preferences.gd")
const Audio=preload("res://scripts/audio_director.gd")
const Store=preload("res://scripts/save_store.gd")
var checks:=0
var failures:=0
var path: String="user://options-"+str(Time.get_ticks_usec())

func _initialize() -> void:
	call_deferred("run_checks")

func check(value: bool,description: String) -> void:
	checks+=1
	if value: print("PASS: ",description)
	else:
		failures+=1
		push_error("FAIL: "+description)

func new_game() -> Node:
	var game: Node=load("res://Main.tscn").instantiate()
	game.save_store=Store.new(path)
	game.clock_source=func(): return 1790512000.0
	root.add_child(game)
	return game

func run_checks() -> void:
	check(Preferences.normalize(null)==Preferences.DEFAULTS,"missing preferences retain safe defaults")
	var normalized:=Preferences.normalize({"master":INF,"music":-9.0,"effects":99,"battery":"yes","numbers":false,"large_text":"yes","reduced_motion":"yes"})
	check(normalized.master==0.8 and normalized.music==0.0 and normalized.effects==1.0 and not normalized.battery and not normalized.numbers and not normalized.large_text and not normalized.reduced_motion,"invalid settings are bounded and type checked")
	for key in ["camp","dungeon","ui","swing","bolt","impact","arcane_contact","arrow_contact","hurt","oath","nova","volley","warning","step","ward","lightning","starfall","victory","defeat"]:
		var stream:=Audio.stream_for(key)
		var peak:=0
		var energy:=0.0
		var data:=stream.data
		for i in range(0,data.size(),2):
			var sample:=data.decode_s16(i)
			peak=maxi(peak,absi(sample))
			energy+=float(sample)*sample
		check(peak>100 and peak<=16384 and energy>0.0 and data.decode_s16(0)==0 and absi(data.decode_s16(data.size()-2))<50,key+": audible PCM with bounded peaks and quiet edges")
		check(Audio.stream_for(key)==stream,key+": synthesis is cached")
		if key in ["camp","dungeon"]:
			check(stream.loop_end==data.size()/2 and stream.loop_mode==AudioStreamWAV.LOOP_FORWARD,key+": loop boundaries use sample frames")
	var game:=new_game()
	game._finish_welcome(false)
	game.get_window().go_back_requested.emit()
	check(game.page=="camp","Back from armory returns to camp")
	game.get_window().go_back_requested.emit()
	check(game.page=="camp" and not game.has_node("Options"),"duplicate Back delivery within a frame is handled once")
	await process_frame
	await process_frame
	game.get_window().go_back_requested.emit()
	await process_frame
	await process_frame
	check(game.has_node("Options"),"Back at camp opens options instead of quitting")
	var menu: Control=game.get_node("Options")
	for name_value in ["CloseSettings","SaveAndExit","MasterVolume","MusicVolume","EffectsVolume","LargeText","ReducedMotion"]:
		var control: Control=menu.find_child(name_value,true,false)
		check(control!=null and game.get_global_rect().encloses(control.get_global_rect()),name_value+" fits within landscape viewport")
	var backup_tab: Button=menu.find_child("SaveBackupTab",true,false)
	backup_tab.pressed.emit()
	await process_frame
	var export_field: TextEdit=menu.find_child("BackupExportCode",true,false)
	var import_field: TextEdit=menu.find_child("BackupRestoreCode",true,false)
	var restore_button: Button=menu.find_child("RestoreBackup",true,false)
	var undo_button: Button=menu.find_child("UndoBackupRestore",true,false)
	check(export_field!=null and export_field.text.begins_with("EMBERFALL-SAVE-1|") and not export_field.editable,"options exports a copyable save backup code")
	check(import_field!=null and restore_button!=null and not restore_button.disabled and undo_button!=null and undo_button.disabled,"camp exposes import and a disabled undo until a restore exists")
	var gold_before_invalid_restore: int=game.player_gold
	import_field.text="invalid backup"
	restore_button.pressed.emit()
	var backup_status: Label=menu.find_child("BackupStatus",true,false)
	check(game.player_gold==gold_before_invalid_restore and backup_status.text.contains("invalid"),"invalid backup entered through the UI leaves progress unchanged")
	var settings_tab: Button=menu.find_child("SettingsTab",true,false)
	settings_tab.pressed.emit()
	await process_frame
	var font_probe: Label=game._label("Readable text",12,game.PALE)
	game.add_child(font_probe)
	var standard_font_size:=font_probe.get_theme_font_size("font_size")
	game._change_preference("large_text",true)
	check(font_probe.get_theme_font_size("font_size")>standard_font_size,"large-text option updates labels already on screen")
	check(game.preferences.large_text,"large-text preference is enabled")
	game._change_preference("master",0.0)
	check(game.audio.music.volume_db<=-79.0 and game.audio.voices[0].volume_db<=-79.0,"master mute affects both music and effects")
	var voice_count: int=game.audio.cursor
	game.audio.cue("nova")
	check(game.audio.cursor==voice_count,"muted effects never allocate a voice")
	game._change_preference("master",0.75)
	game._change_preference("music",0.0)
	game._change_preference("effects",0.5)
	check(game.audio.music.volume_db<=-79.0 and game.audio.voices[0].volume_db>-79.0,"music and effects volumes are independent")
	game._change_preference("battery",true)
	game._change_preference("numbers",false)
	game._change_preference("reduced_motion",true)
	check(Engine.max_fps==30,"battery mode caps presentation at 30 FPS")
	game._close_settings()
	game._start_run(1)
	game.run_arena.animation_enabled=false
	game.expedition.advance(5.25)
	var checkpoint: Dictionary=game.expedition.snapshot()
	var serial: int=game.expedition_serial
	var gold: int=game.player_gold
	check(game.run_arena.render_container.stretch_shrink==2 and game.run_arena.render_viewport.msaa_3d==Viewport.MSAA_DISABLED and not game.run_arena.world.sun.shadow_enabled,"battery mode reduces rendering resolution, MSAA and shadows")
	check(not game.run_arena.world.damage_numbers,"damage number preference reaches the 3D world")
	check(game.run_arena.world.reduced_motion,"reduced-motion preference reaches the 3D world")
	game.run_arena.world._kick_camera(0.08)
	check(game.run_arena.world.camera_shake_time==0.0,"reduced motion suppresses nonessential impact shake")
	game._show_settings()
	check(not game.run_active and game.menu_resume_run and game.has_node("Options"),"opening options pauses an active run")
	for i in range(120): game.run_arena.world._process(1.0/60)
	check(game.expedition.snapshot()==checkpoint,"options menu leaves exact combat state unchanged")
	game._change_preference("battery",false)
	game._change_preference("numbers",true)
	game._change_preference("reduced_motion",false)
	check(Engine.max_fps==60 and game.run_arena.render_container.stretch_shrink==1 and game.run_arena.world.sun.shadow_enabled,"balanced mode restores rendering immediately")
	game.run_arena.world._kick_camera(0.08)
	check(game.run_arena.world.camera_shake_time==0.0,"balanced mode keeps the combat camera steady on impact")
	check(game.expedition.snapshot()==checkpoint and game.expedition_serial==serial and game.player_gold==gold,"graphics changes cannot affect simulation, runs or rewards")
	game.get_window().go_back_requested.emit()
	check(game.run_active and not game.has_node("Options"),"Back closes menu and resumes previously active run")
	game._toggle_run_pause()
	game._show_settings()
	game._close_settings()
	check(not game.run_active,"closing options preserves a manually paused run")
	game.audio.set_suspended(true)
	voice_count=game.audio.cursor
	game.audio.cue("oath")
	check(game.audio.suspended and (not game.audio.music.playing or game.audio.music.stream_paused) and game.audio.cursor==voice_count,"background suspension stops playback and rejects new cues")
	game.audio.set_suspended(false)
	check(not game.audio.suspended and game.audio.preferences.music==0.0 and (not game.audio.music.playing or game.audio.music.stream_paused),"foreground preserves muted music without replaying effects")
	game._change_preference("music",0.5)
	check(not game.audio.music.stream_paused,"unmuting music resumes its playback")
	game._change_preference("music",0.0)
	game._change_preference("reduced_motion",true)
	game._save_progress()
	game.free()
	await process_frame
	game=new_game()
	check(game.preferences.master==0.75 and game.preferences.music==0.0 and game.preferences.effects==0.5 and not game.preferences.battery and game.preferences.numbers and game.preferences.large_text and game.preferences.reduced_motion,"audio, graphics, readability and motion preferences survive a cold start")
	check(game.page=="run" and not game.run_active and game.expedition.snapshot()==checkpoint,"paused expedition survives options and cold start")
	game.free()
	await process_frame
	Audio.bank.clear()
	print("OPTIONS SMOKE: ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
