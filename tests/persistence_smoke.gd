extends SceneTree
## Run with isolated XDG_DATA_HOME. Never opens the player's normal save.
const Expedition = preload("res://scripts/expedition_simulation.gd")
const Store = preload("res://scripts/save_store.gd")
var test_now := 1790511800
var checks := 0
var failures := 0
var folder := "user://persistence-"+str(Time.get_ticks_usec())

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition: print("PASS: ",description)
	else:
		failures += 1
		push_error("FAIL: "+description)

func payload(gold: int) -> ConfigFile:
	var save := ConfigFile.new()
	save.set_value("hero","gold",gold)
	save.set_value("idle","saved_at",test_now)
	return save

func write(path: String, body: String) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(body)
	file.close()

func result(sim: RefCounted) -> Array:
	return [sim.won,sim.elapsed,sim.hero_hp,sim.hero_mana,sim.kills,sim.dodges,sim.casts,sim.hero_pos,sim.rng.state]

func new_game(path: String) -> Node:
	var game: Node = load("res://Main.tscn").instantiate()
	game.save_store = Store.new(path)
	game.clock_source = func(): return float(test_now)
	root.add_child(game)
	if is_instance_valid(game.run_arena): game.run_arena.animation_enabled=false
	return game

func run_checks() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var world_one:=new_game(folder+"/world-one")
	var first_world_seed: int=world_one.world_seed
	var first_run_seed: int=world_one._run_seed_for_serial(25)
	check(first_world_seed>0 and first_world_seed<=world_one.MAX_PROFILE_SEED,"new profiles receive an in-range personal dungeon seed")
	check(first_run_seed==world_one._run_seed_for_serial(25) and first_run_seed!=world_one._run_seed_for_serial(26),"personal dungeon seed produces a stable sequence of distinct runs")
	world_one._save_progress()
	world_one.free()
	world_one=new_game(folder+"/world-one")
	check(world_one.world_seed==first_world_seed and world_one._run_seed_for_serial(25)==first_run_seed,"profile seed and run sequence survive a cold launch")
	world_one.free()
	var world_two:=new_game(folder+"/world-two")
	check(world_two.world_seed!=first_world_seed and world_two._run_seed_for_serial(25)!=first_run_seed,"separate new profiles start on independent dungeon sequences")
	world_two.free()
	var old_profile_store:=Store.new(folder+"/old-profile")
	var old_profile:=ConfigFile.new()
	old_profile.set_value("hero","expedition_serial",40)
	old_profile.set_value("idle","saved_at",test_now)
	check(old_profile_store.save_game(old_profile)==OK,"pre-seed profile fixture is stored")
	var migrated_profile:=new_game(folder+"/old-profile")
	check(migrated_profile.world_seed>0 and migrated_profile._build_save_payload().has_section_key("hero","world_seed"),"older saves get one persisted dungeon seed when loaded")
	migrated_profile.free()
	await process_frame
	var sample := new_game(folder+"/sample")
	var current_route: RefCounted=sample._new_expedition(1,25)
	check(current_route.movement_seed()==posmod(current_route.run_seed,Expedition.COMBAT_VARIANTS)+1,"new expeditions share their route with the 256-pattern AFK cache")
	check(current_route.uses_scouting_routes(),"new expeditions use seed-bound exploration routes with optional side passages")
	var version_two_route_stats: Dictionary=sample._combat_stats()
	version_two_route_stats.route_pattern_version=2
	var version_two_route:=Expedition.new()
	version_two_route.setup("Vowkeeper",version_two_route_stats,1,"Guardian",123456)
	check(version_two_route.uses_wandering_routes() and not version_two_route.uses_scouting_routes(),"active version-2 checkpoints keep their original S-bend route")
	var version_one_route_stats: Dictionary=sample._combat_stats()
	version_one_route_stats.route_pattern_version=1
	var version_one_route:=Expedition.new()
	version_one_route.setup("Vowkeeper",version_one_route_stats,1,"Guardian",123456)
	check(not version_one_route.uses_wandering_routes(),"active version-1 checkpoints keep their original passage shape")
	var legacy_route_stats: Dictionary=sample._combat_stats()
	legacy_route_stats.erase("route_pattern_version")
	var legacy_route:=Expedition.new()
	legacy_route.setup("Vowkeeper",legacy_route_stats,1,"Guardian",123456)
	var resumed_legacy_route:=Expedition.new()
	check(resumed_legacy_route.restore_encoded(legacy_route.encode_snapshot()) and resumed_legacy_route.movement_seed()==legacy_route.run_seed,"older active checkpoints retain their full-seed passage route")
	for class_value in ["Vowkeeper","Arcanist","Ranger"]:
		sample.character_class=class_value
		var times := [1.37,3.1,12.25,29.05,48.15,60.03]
		for seconds in times:
			var sim: RefCounted=sample._new_expedition(1,19)
			sim.advance(seconds)
			var cfg:=payload(1)
			cfg.set_value("run","snapshot",sim.encode_snapshot())
			var parsed:=ConfigFile.new()
			parsed.parse(cfg.encode_to_text())
			var restored:=Expedition.new()
			var loaded:=restored.restore_encoded(parsed.get_value("run","snapshot"))
			check(loaded and restored.snapshot()==sim.snapshot(),"%s %.2fs: serialized checkpoint is bit-exact" % [class_value,seconds])
			if loaded:
				sim.simulate_to_end()
				restored.simulate_to_end()
				check(result(sim)==result(restored),"%s %.2fs: restart preserves outcome and RNG" % [class_value,seconds])
	var original: RefCounted=sample._new_expedition(1,12)
	original.advance(10.0)
	var state: Dictionary=original.snapshot()
	state.fields.stats.attack=0
	check(original.stats.attack>0,"snapshot owns a deep copy")
	var destination:=Expedition.new()
	check(destination.restore(original.snapshot()),"valid state restores")
	state=original.snapshot()
	var before: Dictionary=destination.snapshot()
	state.fields.waves[0][0].erase("hp")
	check(not destination.restore(state) and destination.snapshot()==before,"missing enemy health rejected without changing live state")
	state=original.snapshot()
	state.fields.stage=8
	check(not destination.restore(state),"invalid room rejected")
	state=original.snapshot()
	state.fields.hero_pos=Vector2(NAN,0)
	check(not destination.restore(state),"non-finite position rejected")
	state=original.snapshot()
	state.version=99
	check(not destination.restore(state),"future checkpoint version rejected")
	check(destination.enemy_by_id(-1).is_empty(),"unset target cannot select an enemy through a negative index")
	sample.free()

	var source_game:=new_game(folder+"/backup-source")
	source_game.player_gold=12345
	source_game._start_run(1)
	source_game.expedition.advance(3.27)
	source_game.run_active=false
	source_game._save_progress()
	var backup_code: String=source_game._create_backup_code()
	var imported_payload: ConfigFile=source_game.save_store.parse_backup_code(backup_code)
	check(not backup_code.is_empty() and imported_payload!=null and imported_payload.get_value("hero","gold")==12345 and imported_payload.get_value("hero","world_seed")==source_game.world_seed,"backup code exports the personal dungeon sequence with the hero and resumable expedition")
	var older_backup:=ConfigFile.new()
	older_backup.parse(imported_payload.encode_to_text())
	older_backup.erase_section_key("hero","world_seed")
	check(source_game._valid_backup_payload(older_backup),"older backup codes remain valid without the personal dungeon seed")
	var corrupt_code:=backup_code
	corrupt_code=corrupt_code.substr(0,corrupt_code.length()-1)+("0" if corrupt_code.right(1)!="0" else "1")
	check(source_game.save_store.parse_backup_code(corrupt_code)==null,"backup checksum rejects an altered code")
	var restore_game:=new_game(folder+"/backup-target")
	restore_game.player_gold=77
	restore_game._save_progress()
	check(restore_game._restore_backup_code(backup_code),"valid backup restores into the local store")
	check(FileAccess.file_exists(restore_game.save_store.base_path+".0.pre_restore"),"restoring preserves the previous local save as a recovery copy")
	restore_game._load_progress()
	check(restore_game.player_gold==12345 and restore_game.page=="run" and not restore_game.run_active and restore_game.expedition.snapshot()==source_game.expedition.snapshot(),"imported backup restores hero data and the exact paused expedition")
	var unchanged_gold: int=restore_game.player_gold
	check(not restore_game._restore_backup_code("not a backup code") and restore_game.player_gold==unchanged_gold,"invalid backup leaves current progress unchanged")
	check(restore_game._restore_local_recovery_copy(),"undo restores the previous on-device save")
	restore_game._load_progress()
	check(restore_game.player_gold==77 and restore_game.page=="camp","undo recovers the previous hero state")
	source_game.free()
	restore_game.free()

	var path:=folder+"/slots"
	var store:=Store.new(path)
	check(store.load_save()==null and not store.write_blocked,"new player has no recovery error")
	check(store.save_game(payload(100))==OK,"first generation saves")
	check(store.save_game(payload(200))==OK,"second generation saves")
	check(store.save_game(payload(300))==OK,"third generation replaces only the older slot")
	check(Store.new(path).load_save().get_value("hero","gold")==300,"newest valid generation loads")
	write(path+".0.tmp","interrupted write")
	check(Store.new(path).load_save().get_value("hero","gold")==300,"interrupted temporary write is ignored")
	var damaged:=ConfigFile.new()
	damaged.load(path+".0")
	damaged.set_value("storage","payload","tampered")
	damaged.save(path+".0")
	var recovered:=Store.new(path)
	check(recovered.load_save().get_value("hero","gold")==200 and not recovered.notice.is_empty(),"checksum failure recovers previous generation with visible notice")
	check(recovered.save_game(payload(250))==OK and Store.new(path).load_save().get_value("hero","gold")==250,"recovery repairs damaged slot while retaining backup")
	write(path+".0","[broken")
	write(path+".1","[broken")
	var corrupt:=Store.new(path)
	check(corrupt.load_save()==null and corrupt.write_blocked and corrupt.save_game(payload(1))==ERR_UNAVAILABLE,"two corrupt generations are preserved, never overwritten")
	var future_path:=folder+"/future"
	var future_store:=Store.new(future_path)
	future_store.save_game(payload(123))
	var future:=ConfigFile.new()
	future.set_value("storage","version",99)
	future.save(future_path+".1")
	check(future_store.load_save().get_value("hero","gold")==123 and future_store.write_blocked,"future-format save prevents accidental downgrade writes")
	check(future_store.save_game(payload(321))==ERR_UNAVAILABLE,"downgrade cannot overwrite future save")
	var legacy_path:=folder+"/legacy"
	payload(456).save(legacy_path)
	var legacy_bytes:=FileAccess.get_file_as_bytes(legacy_path)
	var migrated:=Store.new(legacy_path)
	var legacy:=migrated.load_save()
	check(legacy.get_value("hero","gold")==456 and migrated.save_game(legacy)==OK,"legacy player migrates into validated slots")
	check(FileAccess.get_file_as_bytes(legacy_path)==legacy_bytes,"migration preserves original legacy file")
	var missing:=Store.new(folder+"/missing/parent/save")
	check(missing.save_game(payload(1))!=OK,"unwritable destination reports failure")

	var game_path:=folder+"/lifecycle"
	var game:=new_game(game_path)
	game.farm_enabled=true
	game._start_run(1)
	game.run_arena.animation_enabled=false
	game.expedition.advance(12.37)
	game.run_active=false
	game.auto_repeat=true
	game._save_progress()
	var checkpoint: Dictionary=game.expedition.snapshot()
	var gold: int=game.player_gold
	game.free()
	game=new_game(game_path)
	check(game.page=="run" and not game.run_active and game.auto_repeat,"cold launch restores paused and repeat controls")
	check(game.expedition.snapshot()==checkpoint,"cold launch restores exact fight state")
	check(game.run_arena.world.hero.position==Vector3(game.expedition.hero_pos.x,0,game.expedition.hero_pos.y),"restored camera world starts at the hero's saved position")
	game.last_saved_at=test_now-120
	game._accrue_offline_time()
	check(game.expedition.snapshot()==checkpoint and game.pending_idle_runs==0,"paused hero earns no parallel offline expeditions")
	game.run_active=true
	var reference:=Expedition.new()
	reference.restore(checkpoint)
	reference.advance(5.0)
	game.backgrounded_at=test_now-5
	game.last_saved_at=game.backgrounded_at
	game._resume_from_background()
	check(game.expedition.snapshot()==reference.snapshot() and game.pending_idle_runs==0,"background catch-up advances the current run without duplicate farming")
	game.run_arena.animation_enabled=false
	game._save_progress()
	game.free()
	game=new_game(game_path)
	check(game.run_active and game.auto_repeat and game.expedition.snapshot()==reference.snapshot(),"active run survives process death with repeat state")
	game._save_progress()
	game.free()
	test_now+=1
	reference.advance(1.0)
	game=new_game(game_path)
	check(game.expedition.snapshot()==reference.snapshot(),"one real second between save and launch is accounted exactly")
	game.last_saved_at=test_now-150
	game._accrue_offline_time()
	check(game.page=="camp" and game.expedition==null and game.pending_idle_runs>0,"long absence settles current run and remaining AFK time")
	var reports: int=game.pending_idle_runs
	var ash: int=game.pending_idle_ash
	game._save_progress()
	game.free()
	game=new_game(game_path)
	check(game.pending_idle_runs==reports and game.pending_idle_ash==ash and game.player_gold==gold,"restart cannot settle the completed run twice")
	game._claim_idle_cache()
	var claimed_gold: int=game.player_gold
	check(claimed_gold==gold+ash and game.pending_idle_ash==0,"claim transfers pending gold once")
	game.free()
	game=new_game(game_path)
	game._claim_idle_cache()
	check(game.player_gold==claimed_gold,"claimed offline rewards cannot be claimed again after restart")
	var watermark:=test_now+1000
	game.last_saved_at=watermark
	game._accrue_offline_time()
	game._save_progress()
	check(game.last_saved_at==watermark and game.pending_idle_runs==0,"clock rollback does not move the accounting watermark backwards")
	game.free()
	await process_frame
	print("PERSISTENCE SMOKE: ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
