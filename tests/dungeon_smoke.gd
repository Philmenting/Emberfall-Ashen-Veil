extends SceneTree
## Run in an isolated user-data directory: see README. Never touches a real save.
var failures := 0
var game: Node
func _initialize() -> void:
	call_deferred("run_checks")
func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + description)
	else:
		print("PASS: " + description)
func create_game(class_name_value: String) -> void:
	game = load("res://Main.tscn").instantiate()
	root.add_child(game)
	game.farm_enabled = false
	game.character_class = class_name_value
	game.floor_number = 1
	game._start_run()
func run_checks() -> void:
	for class_name_value in ["Vowkeeper","Arcanist","Ranger"]:
		create_game(class_name_value)
		var arena: Node = game.run_arena
		var world: Node = arena.world
		var origin: Vector3 = world.hero.position
		await create_timer(1.0).timeout
		check(world.hero.position.distance_to(origin)>1.0,class_name_value+": walks in world space")
		check(game.enemy_health==game.enemy_max_health,class_name_value+": no damage outside attack range")
		game._toggle_run_pause()
		var stopped: Vector3 = world.hero.position
		var time_before: float = world.elapsed
		await create_timer(0.5).timeout
		check(world.hero.position==stopped and world.elapsed==time_before,class_name_value+": pause freezes movement and animation")
		game._toggle_run_pause()
		await create_timer(90.0).timeout
		check(game.page=="loot",class_name_value+": automatic traversal reaches results")
		check(game.run_succeeded and game.run_boss_defeated,class_name_value+": all six encounters including boss resolved")
		check(game.run_stage==6 and game.floor_number==2,class_name_value+": floor reward applied once")
		check(game.run_loot.size()>0,class_name_value+": real gear reward exists")
		game.queue_free()
		await process_frame
	create_game("Vowkeeper")
	var initial_gold: int = game.player_gold
	game._toggle_run_pause()
	game._skip_run()
	check(game.page=="loot" and game.run_succeeded,"skip from paused traversal completes the same combat model")
	check(game.player_gold==initial_gold+190,"skip grants completion reward exactly once")
	game.queue_free()
	await process_frame
	create_game("Vowkeeper")
	game.run_health=1
	game.run_mana=0
	game.floor_number=100
	game._prepare_enemy()
	game._skip_run()
	check(game.page=="loot" and not game.run_succeeded,"fatal encounter produces retreat results")
	game.queue_free()
	await process_frame
	create_game("Vowkeeper")
	game.farm_enabled = true
	game.idle_progress_seconds = 0
	var same_arena: Node = game.run_arena
	game.backgrounded_at = int(Time.get_unix_time_from_system())-5
	game.last_saved_at = game.backgrounded_at
	game._resume_from_background()
	check(game.page=="run" and game.run_arena==same_arena,"short background interruption preserves the live world")
	check(game.idle_progress_seconds>=5,"short background time is carried into AFK accounting")
	game.backgrounded_at = int(Time.get_unix_time_from_system())-150
	game.last_saved_at = game.backgrounded_at
	var reports_before: int = game.pending_idle_runs+game.pending_idle_fails
	game._resume_from_background()
	check(game.page=="camp" and not game.run_active,"long background interruption returns to AFK report")
	var reports_after: int = game.pending_idle_runs+game.pending_idle_fails
	check(reports_after==reports_before+2,"background time produces exactly two complete AFK runs")
	game._resume_from_background()
	check(game.pending_idle_runs+game.pending_idle_fails==reports_after,"duplicate resume notification cannot duplicate rewards")
	game.queue_free()
	await process_frame
	print("DUNGEON SMOKE: ",failures," failures")
	quit(0 if failures==0 else 1)
