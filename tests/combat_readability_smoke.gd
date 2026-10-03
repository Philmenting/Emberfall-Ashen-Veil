extends SceneTree
## Live inspection must never spend time, Mana, random draws or checkpoint state.
const Store=preload("res://scripts/save_store.gd")
const Readout=preload("res://scripts/combat_readout.gd")
const HealthBar=preload("res://scripts/combat_health_bar.gd")
var checks:=0
var failures:=0

func _initialize() -> void: run_checks.call_deferred()
func check(value: bool, description: String) -> void:
	checks+=1
	if value: print("PASS: ",description)
	else: failures+=1; push_error("FAIL: "+description)
func settle() -> void:
	for frame in range(5): await process_frame

func run_checks() -> void:
	var game:Node=load("res://Main.tscn").instantiate()
	game.save_store=Store.new("user://combat-readability-"+str(Time.get_ticks_usec()))
	game.clock_source=func(): return 2000000000.0
	root.add_child(game)
	game._finish_welcome(false)
	game.farm_enabled=false; game.world_seed=1979
	for class_key in ["Vowkeeper","Arcanist","Ranger"]:
		game.character_class=class_key
		var observed:RefCounted=game._new_expedition(1,1)
		var baseline:RefCounted=game._new_expedition(1,1)
		var cast_seen:=false; var cooldown_seen:=false; var reads_pure:=true
		while not observed.finished:
			observed.advance(0.1)
			var before:String=observed.encode_snapshot()
			for entry in Readout.skills(observed):
				cast_seen=cast_seen or entry.state=="casting"
				cooldown_seen=cooldown_seen or entry.state=="cooldown"
			Readout.route(observed); Readout.protection(observed)
			reads_pure=reads_pure and before==observed.encode_snapshot()
		baseline.simulate_to_end()
		# Skip supplies whole seconds; its unused final fraction is not game time.
		var watched_state:Dictionary=observed.snapshot()
		var skipped_state:Dictionary=baseline.snapshot()
		watched_state.fields.erase("accumulator"); skipped_state.fields.erase("accumulator")
		check(reads_pure and watched_state==skipped_state,class_key+": repeated HUD reads preserve watched/skip outcome, elapsed time and RNG")
		check(cast_seen and cooldown_seen,class_key+": actual casts and cooldowns are visible")
		var model:RefCounted=game._new_expedition(1,1)
		model.hero_mana=0
		var mana_correct:=true
		for entry in Readout.skills(model): mana_correct=mana_correct and entry.state=="mana"
		check(mana_correct,class_key+": no READY indication when Mana is insufficient")
		model.pending_attack={"skill":true,"left":0.2}
		check(Readout.skills(model)[0].state=="casting",class_key+": committed signature stays CASTING after its Mana was spent")
		model.stats.erase("skill_rotation")
		check(Readout.skills(model).size()==1,class_key+": old checkpoint shows only its actual signature")
	game.character_class="Arcanist"
	game._start_run(1)
	game.run_arena.animation_enabled=false
	await settle()
	var snapshot:Dictionary=game.expedition.snapshot()
	var world_id:int=game.run_arena.world.get_instance_id()
	game.find_child("CombatSkill_chain",true,false).pressed.emit()
	await settle()
	check(game.combat_details_open and not game.run_active and not game.run_arena.animation_enabled,"skill tap pauses combat before opening its explanation")
	check(game.expedition.snapshot()==snapshot and game.run_arena.world.get_instance_id()==world_id,"reading leaves the checkpoint, enemies and camera scene intact")
	check("Lightning".to_upper() in game.combat_hud.inspected_title.text and "three enemies" in game.combat_hud.inspected_rule.text,"selected equipped skill exposes its real trigger and effect")
	check(game._build_save_payload().get_value("run","active",false),"save during reading preserves the previously active run intent")
	game._inspect_combat_skill("frost_ward")
	check(not game.run_active and game.details_resume_run,"switching inspected skills never overwrites resume intent")
	game._show_settings()
	game._close_settings()
	check(game.combat_details_open and not game.run_active,"nested options returns to the paused reading view")
	game._build_ui()
	await settle()
	check(game.combat_hud.details_sheet.visible and not game.run_active and game.details_resume_run,"layout rebuild preserves the open reading view and resume intent")
	game.last_back_frame=-1; game._handle_back()
	check(not game.combat_details_open and game.run_active and game.run_arena.animation_enabled,"Back restores an active run exactly once")
	game._toggle_run_pause()
	game._toggle_combat_details()
	check(not game._build_save_payload().get_value("run","active",true),"manually paused run stays paused in saved checkpoint while reading")
	game._toggle_combat_details()
	check(not game.run_active,"closing Details never starts a manually paused run")
	game._toggle_combat_details()
	game.find_child("AutoControl",true,false).pressed.emit()
	check(game.run_active and not game.combat_details_open,"Resume explicitly closes the reading view and continues combat")
	game._toggle_run_pause()
	game.expedition.hero_mana=game.expedition.signature_cost()
	check("WARD RESERVE" in Readout.protection(game.expedition),"Mana Ward clearly shows when its reserved Mana cannot absorb damage")
	game.expedition.guard_time=2.4
	check("GUARD 2.4s" in Readout.protection(game.expedition),"protection display uses actual remaining Guard duration")
	var reinforcement:Dictionary=game.expedition.waves[0].back()
	reinforcement["spawned"]=false
	check(Readout.route(game.expedition).objective.begins_with(str(game.expedition.waves[0].size())),"room progress includes living reinforcements that have not arrived")
	for resolution in [Vector2i(2424,1080),Vector2i(1040,1080),Vector2i(854,480)]:
		root.size=resolution
		await settle()
		for large in [false,true]:
			game.preferences.large_text=large
			game._build_ui()
			await settle()
			var fits:=true
			var rectangles:Array[Rect2]=[]
			for entry in game.combat_hud.skill_tiles.values():
				var button:Button=entry.button
				fits=fits and game.get_global_rect().encloses(button.get_global_rect()) and button.size.y>=48
				for other in rectangles: fits=fits and not other.grow(3).intersects(button.get_global_rect())
				rectangles.append(button.get_global_rect())
				for label in button.find_children("*","Label",true,false):
					fits=fits and button.get_global_rect().encloses(label.get_global_rect()) and label.get_minimum_size().x<=label.size.x+1.0
			check(fits,"%dx%d %s: skill labels and touch targets fit without overlapping" % [resolution.x,resolution.y,"large" if large else "normal"])
			var world:Node3D=game.run_arena.world
			var edge:float=(game.combat_hud.readouts.global_position.y-game.global_position.y)/game.size.y
			check(world.hud_bottom_ratio<edge,"%dx%d: camera reserves the actual readout height (%.3f < %.3f)" % [resolution.x,resolution.y,world.hud_bottom_ratio,edge])
			game._toggle_combat_details()
			await settle()
			check(game.combat_hud.details_sheet.get_global_rect().end.y<=game.combat_hud.readouts.global_position.y-7,"%dx%d: reading sheet leaves skill and resume controls exposed" % [resolution.x,resolution.y])
			game._toggle_combat_details()
	# Restart from an authentic run after the synthetic Mana/reinforcement probes.
	game._start_run(1)
	game._inspect_combat_skill("chain")
	var persisted_snapshot:String=game.expedition.encode_snapshot()
	var resumed:Node=load("res://Main.tscn").instantiate()
	resumed.save_store=game.save_store
	resumed.clock_source=game.clock_source
	root.add_child(resumed)
	check(resumed.page=="run" and resumed.run_active and resumed.expedition.encode_snapshot()==persisted_snapshot,"cold restart during a temporary reading pause restores the same active checkpoint")
	resumed.free()
	game._toggle_combat_details()
	game._toggle_run_pause()
	game._inspect_combat_skill("chain")
	var paused:Node=load("res://Main.tscn").instantiate()
	paused.save_store=game.save_store
	paused.clock_source=game.clock_source
	root.add_child(paused)
	check(paused.page=="run" and not paused.run_active and paused.expedition.encode_snapshot()==persisted_snapshot,"cold restart preserves a manual pause even when Details was open")
	paused.free()
	# A temporary reading overlay must not make warm AFK differ from cold AFK.
	for was_active in [true,false]:
		game._start_run(1)
		if not was_active: game._toggle_run_pause()
		game.farm_enabled=true
		game.clock_source=func(): return 2000000000.0
		game._inspect_combat_skill("chain")
		var initial_elapsed:float=game.expedition.elapsed
		var cold:Node=load("res://Main.tscn").instantiate()
		cold.save_store=Store.new("user://reading-away-"+str(Time.get_ticks_usec()))
		cold.save_store.save_game(game._build_save_payload())
		cold.clock_source=func(): return 2000000012.0
		root.add_child(cold)
		game.clock_source=cold.clock_source
		game._accrue_offline_time(false)
		check(game.expedition.encode_snapshot()==cold.expedition.encode_snapshot(),"%s before reading: warm and cold AFK resume preserve the same full checkpoint" % ("active" if was_active else "paused"))
		check(game.expedition.elapsed>initial_elapsed if was_active else game.expedition.elapsed==initial_elapsed,"%s before reading: AFK follows the underlying play intent" % ("active" if was_active else "paused"))
		cold.free()
		game._toggle_combat_details()
		game.clock_source=func(): return 2000000000.0
		game.last_saved_at=2000000000
	var bar:=HealthBar.new()
	bar.max_value=100; bar.value=100
	root.add_child(bar)
	bar.value=65
	check(bar.value==65 and bar.trail_value==100,"Life falls immediately while the loss remains briefly visible")
	bar._process(0.30)
	check(bar.trail_value>65 and bar.trail_value<100,"damage trace settles progressively instead of flashing the screen")
	bar.value=90
	check(bar.trail_value==90,"healing clears the old damage trace immediately")
	bar.value=40; bar.set_presentation(true,false)
	check(bar.trail_value==40 and not bar.is_processing(),"Reduced Motion makes health changes immediate without a moving trace")
	bar.free(); game.free()
	await process_frame
	print("COMBAT READABILITY SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
