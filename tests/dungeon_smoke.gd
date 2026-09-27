extends SceneTree
## Isolated data required; tests exercise both live view and headless combat.
var failures := 0
var checks := 0
var game: Node
func _initialize() -> void:
	call_deferred("run_checks")
func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)
	else: print("PASS: " + description)
func create_game(class_value: String) -> void:
	game = load("res://Main.tscn").instantiate()
	root.add_child(game)
	game.farm_enabled = false
	game.character_class = class_value
	game.floor_number = 1
	game.farm_floor = 1
	game.inventory.clear()
	game.expedition_serial = 1
	game._start_run()
func outcome(sim: RefCounted) -> Array:
	return [sim.won,sim.elapsed,sim.hero_hp,sim.hero_mana,sim.kills,sim.dodges,sim.casts,sim.hero_pos]
func run_checks() -> void:
	for class_value in ["Vowkeeper","Arcanist","Ranger"]:
		create_game(class_value)
		var arena: Node = game.run_arena
		var world: Node = arena.world
		var origin: Vector3 = world.hero.position
		var skipped: RefCounted = game._new_expedition(1,1)
		skipped.simulate_to_end()
		var stepped: RefCounted = game._new_expedition(1,1)
		while not stepped.finished: stepped.advance(0.017)
		check(outcome(skipped)==outcome(stepped),class_value+": frame rate and skipping produce identical combat")
		check(skipped.kills==18 and skipped.won,class_value+": defeats six varied packs and boss")
		var threatened: RefCounted=game._new_expedition(1,1)
		threatened.phase="combat"
		threatened._warn(threatened.waves[0][0],1.15,0.5)
		threatened._auto_hero()
		check(skipped.casts>0 and threatened.dodging and threatened.dodges==1,class_value+": uses abilities and reacts when actually threatened")
		await create_timer(1.0).timeout
		check(world.hero.position.distance_to(origin)>1.0,class_value+": walks through dungeon")
		check(game.expedition.kills==0 and game.enemy_health==game.enemy_max_health,class_value+": no attacks before entering combat")
		game._toggle_run_pause()
		var stopped: Vector3 = world.hero.position
		var stopped_time: float = game.expedition.elapsed
		await create_timer(0.4).timeout
		check(world.hero.position==stopped and game.expedition.elapsed==stopped_time,class_value+": pause freezes simulation and world")
		game._toggle_run_pause()
		await create_timer(110.0).timeout
		check(game.page=="loot" and game.run_succeeded and game.run_boss_defeated,class_value+": live run reaches victory and loot")
		check(outcome(game.expedition)==outcome(skipped),class_value+": live and skipped result exactly match")
		check(game.floor_number==2 and game.run_loot.size()>0,class_value+": unlock and gear awarded once")
		game.queue_free()
		await process_frame
	create_game("Ranger")
	var ranger: RefCounted = game._new_expedition(1,9)
	ranger.stage=1
	ranger.hero_pos=Vector2(3,-13)
	check(ranger._choose_target().role=="hexer","Ranger prioritizes the enemy caster")
	game.character_class="Arcanist"
	var arcanist: RefCounted = game._new_expedition(1,9)
	var multiple_hits := false
	while not arcanist.finished and arcanist.stage<1:
		var hits := 0
		for event in arcanist.advance(0.1):
			if event.type=="hit" and event.skill: hits += 1
		if hits>1: multiple_hits=true
	check(multiple_hits,"Arcanist Nova damages multiple members of a pack")
	game.character_class="Vowkeeper"
	var vow: RefCounted = game._new_expedition(1,9)
	var enemy: Dictionary = vow.waves[0][0]
	var hp: int = vow.hero_hp
	vow._hurt_hero(enemy,50.0)
	var unguarded: int = hp-vow.hero_hp
	vow.hero_hp=hp
	vow.guard_time=2.0
	vow._hurt_hero(enemy,50.0)
	check(hp-vow.hero_hp<unguarded,"Vowkeeper Guard reduces actual incoming damage")
	var impossible: RefCounted = game._new_expedition(100,9)
	impossible.simulate_to_end()
	check(not impossible.won,"insufficient gear cannot randomly clear an impossible floor")
	# Same cached AFK pattern, distinct loot seeds.
	var cached_pattern: RefCounted = game._new_expedition(1,73)
	var first_pattern: RefCounted = game._new_expedition(1,9)
	cached_pattern.simulate_to_end()
	first_pattern.simulate_to_end()
	check(outcome(cached_pattern)==outcome(first_pattern),"offline pattern cache is equivalent to a full simulation")
	check(cached_pattern.run_seed!=first_pattern.run_seed,"repeated combat patterns retain independent loot seeds")
	var without_mana: RefCounted = game._new_expedition(1,3)
	without_mana.stats.mana_cost=10000
	without_mana.simulate_to_end()
	check(without_mana.casts==0,"abilities cannot be cast without sufficient mana")
	var ordinary: RefCounted = game._new_expedition(10,3)
	ordinary.simulate_to_end()
	game.equipment.Weapon.power += 500
	var upgraded: RefCounted = game._new_expedition(10,3)
	upgraded.simulate_to_end()
	check(upgraded.won and upgraded.elapsed<ordinary.elapsed and upgraded.hero_hp>ordinary.hero_hp,"stronger weapon clears faster with more remaining health")
	game.equipment.Weapon.power -= 500
	game.queue_free()
	await process_frame
	create_game("Vowkeeper")
	game._toggle_run_pause()
	game._skip_run()
	check(game.page=="loot" and game.run_succeeded,"skip also works while paused")
	var gold_after: int = game.player_gold
	game._complete_run()
	check(game.player_gold==gold_after,"completed run cannot award rewards twice")
	game.queue_free()
	await process_frame
	create_game("Vowkeeper")
	game.auto_repeat=true
	game.expedition.simulate_to_end()
	game._on_combat_advanced([])
	var old_model: RefCounted = game.expedition
	await create_timer(1.4).timeout
	check(game.page=="run" and game.expedition!=old_model and game.run_floor==1,"auto repeat starts the same farm floor after collecting loot")
	game.expedition.hero_hp=1
	game.expedition.hero_mana=0
	game.expedition.stats.attack=1
	game.expedition.stats.ability_damage=1
	game.expedition.simulate_to_end()
	game._on_combat_advanced([])
	check(not game.auto_repeat and not game.run_succeeded,"auto repeat stops on defeat")
	await create_timer(1.4).timeout
	game.queue_free()
	await process_frame
	create_game("Vowkeeper")
	game.farm_enabled=true
	game.idle_progress_seconds=0
	game.pending_idle_runs=0
	game.pending_idle_fails=0
	var same_arena: Node = game.run_arena
	game.backgrounded_at=int(Time.get_unix_time_from_system())-5
	game.last_saved_at=game.backgrounded_at
	game._resume_from_background()
	check(game.page=="run" and game.run_arena==same_arena,"short interruption preserves the live world")
	check(game.expedition.elapsed>=4.999 and game.idle_progress_seconds==0,"short background time advances the same expedition exactly once")
	var pending: RefCounted = load("res://scripts/expedition_simulation.gd").new()
	check(pending.restore(game.expedition.snapshot()),"current expedition checkpoint can be restored")
	pending.advance(150.0)
	var available: int = floori(pending.accumulator+0.00001)+game.idle_progress_seconds
	var serial: int = game.expedition_serial
	var expected_runs := 1
	while available>=30:
		var expected: RefCounted = game._new_expedition(1,serial)
		expected.simulate_to_end()
		var duration := maxi(30,ceili(expected.elapsed))
		if duration>available: break
		available-=duration
		expected_runs+=1
		serial+=1
	game.backgrounded_at=int(Time.get_unix_time_from_system())-150
	game.last_saved_at=game.backgrounded_at
	game._resume_from_background()
	check(game.page=="camp" and not game.run_active,"completed offline expeditions return to the report")
	check(game.pending_idle_runs+game.pending_idle_fails==expected_runs,"AFK counts use actual simulated durations")
	check(game.idle_progress_seconds==available,"AFK leaves the exact unused time remainder")
	check(game.floor_number==2 and game.farm_floor==1,"AFK repeats the selected floor without runaway progression")
	game._resume_from_background()
	check(game.pending_idle_runs+game.pending_idle_fails==expected_runs,"duplicate resume cannot duplicate AFK rewards")
	game._set_farm_floor(100)
	check(game.farm_floor<=maxi(1,game.floor_number-1),"farm selector cannot access uncleared higher floors")
	var benchmark := Time.get_ticks_msec()
	game._simulate_offline_time(24*60*60)
	print("24H AFK benchmark ms=",Time.get_ticks_msec()-benchmark)
	check(game.inventory.size()<=game.MAX_BAG_SIZE and game.pending_idle_salvaged>0,"long AFK sessions respect bag limit and sell overflow")
	game._save_progress()
	var saved_serial: int = game.expedition_serial
	var saved_gold: int = game.pending_idle_ash
	game._load_progress()
	check(game.expedition_serial==saved_serial and game.pending_idle_ash==saved_gold,"farm cursor and pending rewards survive save/load")
	game.queue_free()
	await process_frame
	print("DUNGEON SMOKE: ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
