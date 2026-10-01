extends SceneTree
const Sim=preload("res://scripts/expedition_simulation.gd")
const Layout=preload("res://scripts/dungeon_layout.gd")
const Bot=preload("res://tests/balance_survey_bot.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run_checks")
func check(value: bool, description: String) -> void:
	checks+=1
	if value: print("PASS: ",description)
	else:
		failures+=1
		push_error("FAIL: "+description)
func outcome(sim: RefCounted) -> Array:
	return [sim.won,sim.elapsed,sim.hero_hp,sim.hero_mana,sim.kills,sim.hero_pos,sim.rng.state,sim.journey]
func prepare_maneuver(sim: RefCounted) -> Dictionary:
	sim.stage=0
	sim.phase="combat"
	var center: Vector2=Layout.center(Layout.region(sim.floor_id),0,sim.layout_seed())
	sim.hero_pos=center+Vector2(-1.2 if sim.class_key=="Vowkeeper" else -4.0,0)
	var target: Dictionary=sim.waves[0][0]
	for enemy in sim.waves[0]:
		enemy.hp=0
		enemy.warning={}
		enemy.pos=center+Vector2(4.5,3.5)
	target.hp=target.max_hp
	target.pos=center
	sim.target_id=target.id
	sim.attack_cd=1.3
	sim.journey["combat_movement"]={"target":target.id,"wait":0.0,"remaining":0.0,"goal":sim.hero_pos}
	return target
func run_checks() -> void:
	var route_signatures: Dictionary={}
	var movement_path_signatures: Dictionary={}
	var wandering_path_signatures: Dictionary={}
	var exploration_path_signatures: Dictionary={}
	var packs_signatures: Dictionary={}
	var expected_path_length: float=-1.0
	var path_lengths_match:=true
	var movement_paths_stay_walkable:=true
	var longest_wander_path:=0.0
	var shortest_wander_path:=INF
	var wander_paths_stay_walkable:=true
	var exploration_paths_stay_walkable:=true
	var path_layout_seed:=Layout.procedural_seed(1979,1)
	for serial in range(64):
		var run_seed:=1979+serial*104729
		var seed_value:=Layout.procedural_seed(run_seed,1)
		var route:=Layout.route(0,seed_value)
		var packs:=Layout.packs(0,seed_value)
		var spawns:=Layout.spawn_points(0,2,packs[2].size(),seed_value)
		var path:=Layout.travel_points(0,1,4.4,path_layout_seed,run_seed)
		var wandering_path:=Layout.travel_points(0,1,4.4,path_layout_seed,run_seed,true)
		var exploration_path:=Layout.travel_points(0,1,4.4,path_layout_seed,run_seed,false,true)
		route_signatures[str(route)]=true
		movement_path_signatures[str(path)]=true
		wandering_path_signatures[str(wandering_path)]=true
		exploration_path_signatures[str(exploration_path)]=true
		packs_signatures[str(packs)]=true
		check(route==Layout.route(0,seed_value) and packs==Layout.packs(0,seed_value) and spawns==Layout.spawn_points(0,2,packs[2].size(),seed_value),"seed %d reproduces its route, enemy lineups and spawns" % serial)
		check(path==Layout.travel_points(0,1,4.4,path_layout_seed,run_seed),"run seed %d reproduces its passage bends" % serial)
		check(wandering_path==Layout.travel_points(0,1,4.4,path_layout_seed,run_seed,true),"run seed %d reproduces its wandering corridor" % serial)
		check(exploration_path==Layout.travel_points(0,1,4.4,path_layout_seed,run_seed,false,true),"run seed %d reproduces its exploratory corridor" % serial)
		var path_length:=0.0
		for i in range(path.size()-1):
			path_length+=Vector2(path[i]).distance_to(path[i+1])
			for step in range(101):
				if not Layout.contains(0,Vector2(path[i]).lerp(path[i+1],step/100.0),path_layout_seed,run_seed): movement_paths_stay_walkable=false
		if expected_path_length<0.0: expected_path_length=path_length
		elif not is_equal_approx(path_length,expected_path_length): path_lengths_match=false
		var wander_length:=0.0
		for i in range(wandering_path.size()-1):
			wander_length+=Vector2(wandering_path[i]).distance_to(wandering_path[i+1])
			for step in range(101):
				if not Layout.contains(0,Vector2(wandering_path[i]).lerp(wandering_path[i+1],step/100.0),path_layout_seed,run_seed,true): wander_paths_stay_walkable=false
		longest_wander_path=maxf(longest_wander_path,wander_length)
		shortest_wander_path=minf(shortest_wander_path,wander_length)
		for i in range(exploration_path.size()-1):
			for step in range(101):
				if not Layout.contains(0,Vector2(exploration_path[i]).lerp(exploration_path[i+1],step/100.0),path_layout_seed,run_seed,false,true): exploration_paths_stay_walkable=false
	check(route_signatures.size()>=60,"64 seeds create varied but repeatable route shapes")
	check(movement_path_signatures.size()>=60,"every run seed varies where the hero turns through a passage")
	check(wandering_path_signatures.size()>=60,"new runs take varied S-bends instead of the same straight corridor")
	check(exploration_path_signatures.size()>=60,"new runs vary their exploratory route and choose different side passages")
	check(path_lengths_match,"per-run passage variation preserves travel distance and AFK timing")
	check(movement_paths_stay_walkable,"per-run passage bends stay inside generated corridors")
	check(longest_wander_path-shortest_wander_path<=1.51,"new route variation adds at most 1.5 metres of travel per passage")
	check(wander_paths_stay_walkable,"new S-bend routes stay on the generated floor")
	check(exploration_paths_stay_walkable,"scouting routes and their side passages stay on the generated floor")
	check(packs_signatures.size()>=40,"64 seeds create varied enemy compositions")
	var procedural_routes: Dictionary={}
	var procedural_packs: Dictionary={}
	var procedural_spawns: Dictionary={}
	var groups_keep_fixed_size:=true
	var formations_stay_in_room:=true
	var formations_are_spaced:=true
	for pattern in range(Layout.VARIANT_COUNT):
		var seed_value:=Layout.procedural_seed(1979+pattern*104729,1)
		var route:=Layout.route(0,seed_value)
		var packs:=Layout.packs(0,seed_value)
		var spawns:=Layout.spawn_points(0,2,packs[2].size(),seed_value)
		procedural_routes[str(route)]=true
		procedural_packs[str(packs)]=true
		procedural_spawns[str(spawns)]=true
		var room_center:=Layout.center(0,2,seed_value)
		var room_rect:=Rect2(room_center-Layout.ROOM_HALF,Layout.ROOM_HALF*2.0)
		for i in range(spawns.size()):
			if not room_rect.has_point(spawns[i]): formations_stay_in_room=false
			for j in range(i):
				if Vector2(spawns[i]).distance_to(spawns[j])<0.9: formations_are_spaced=false
		var enemies_in_run:=0
		for pack in packs: enemies_in_run+=pack.size()
		if enemies_in_run!=26: groups_keep_fixed_size=false
	check(procedural_routes.size()>=250,"the newer seed bank creates at least 250 distinct route patterns")
	check(procedural_packs.size()>=230,"the newer seed bank creates at least 230 distinct pack lineups")
	check(procedural_spawns.size()>=250,"the newer seed bank creates at least 250 independently varied spawn formations")
	check(formations_stay_in_room,"all randomized spawns stay within their room")
	check(formations_are_spaced,"randomized enemy spawns do not overlap")
	check(groups_keep_fixed_size,"random pack roles keep the six-room enemy count at 26")
	var seen: Array=[]
	for region_id in range(4):
		check(not seen.has(Layout.ROUTES[region_id]),"region %d has a distinct floor plan" % region_id)
		seen.append(Layout.ROUTES[region_id])
		var connected:=true
		for room in range(1,6):
			var points:=Layout.travel_points(region_id,room,4.4)
			for i in range(points.size()-1):
				for step in range(101):
					if not Layout.contains(region_id,Vector2(points[i]).lerp(points[i+1],step/100.0)): connected=false
		check(connected,"region %d: every travel segment is on the floor" % region_id)
		for selected in ["Vowkeeper","Arcanist","Ranger"]:
			var game:=Bot.new()
			game.character_class=selected
			var stats: Dictionary=game._combat_stats()
			# Geometry/continuation fixture; starter balance is checked separately below.
			stats.max_hp=100000
			stats.attack*=6
			stats.ability_damage*=6
			var floor_value:=region_id*10+1
			var live:=Sim.new()
			live.setup(selected,stats,floor_value,"Journey guardian",1979)
			var skipped:=Sim.new()
			check(skipped.restore_encoded(live.encode_snapshot()),"%s/%d initial journey restores" % [selected,region_id])
			var valid_positions:=true
			var objective_counts: Dictionary={1:0,3:0,5:0}
			var reinforcement_events:=0
			var snapshots: Array=[]
			var captured: Dictionary={}
			while not live.finished:
				var events:=live.advance(0.071)
				if not Layout.contains(region_id,live.hero_pos,live.layout_seed(),live.movement_seed(),live.uses_wandering_routes(),live.uses_scouting_routes()): valid_positions=false
				for enemy in live.living():
					if not Layout.contains(region_id,enemy.pos,live.layout_seed(),live.movement_seed(),live.uses_wandering_routes(),live.uses_scouting_routes()): valid_positions=false
				for event in events:
					if event.type=="objective": objective_counts[event.stage]+=1
					if event.type=="reinforcement_spawn": reinforcement_events+=1
				var key:=str(live.stage)+live.phase
				if live.phase in ["travel","interact"] and not captured.has(key):
					captured[key]=true
					snapshots.append(live.encode_snapshot())
			check(valid_positions,"%s/%d hero and enemies stay on walkable floor" % [selected,region_id])
			check(live.won and live.kills==26 and objective_counts=={1:1,3:1,5:1},"%s/%d completes 26 enemies and each objective once" % [selected,region_id])
			check(reinforcement_events==2,"%s/%d produces two timed, seed-bound ambush arrivals" % [selected,region_id])
			skipped.simulate_to_end()
			check(outcome(live)==outcome(skipped),"%s/%d watched and skipped outcomes match" % [selected,region_id])
			var exact:=true
			for encoded in snapshots:
				var resumed:=Sim.new()
				if not resumed.restore_encoded(encoded): exact=false; continue
				resumed.simulate_to_end()
				# accumulator differs with the caller's frame size, gameplay state does not.
				if outcome(resumed)!=outcome(live): exact=false
			check(exact,"%s/%d travel and interaction checkpoints preserve final result" % [selected,region_id])
			game.free()
	for selected in ["Vowkeeper","Arcanist","Ranger"]:
		var game:=Bot.new()
		game.character_class=selected
		var wins:=0
		var matching:=true
		for serial in range(Layout.VARIANT_COUNT):
			var sim: RefCounted=game._new_expedition(1,serial)
			var duplicate: RefCounted=game._new_expedition(1,serial)
			sim.simulate_to_end()
			while not duplicate.finished: duplicate.advance(0.031)
			if sim.won: wins+=1
			if outcome(sim)!=outcome(duplicate): matching=false
		check(wins==Layout.VARIANT_COUNT,selected+": all 256 starting-floor patterns are winnable with starter gear")
		check(matching,selected+": all 256 patterns agree live/skip")
		game.free()
	var legacy: Array=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/journey_legacy_010.json"))
	for row in legacy:
		var sim:=Sim.new()
		var restored:=sim.restore_encoded(row.snapshot)
		if restored: sim.simulate_to_end()
		check(restored and sim.encode_snapshot().sha256_text()==row.final_hash,"0.10 checkpoint keeps exact old outcome: %s/%d" % [row.class,int(row.floor)])
	var bot:=Bot.new()
	var reinforcement_patterns: Dictionary={}
	var reinforcement_entry_signatures: Dictionary={}
	var reinforcement_entries_walkable:=true
	var reinforcement_entries_at_edge:=true
	var reinforcement_entries_spaced:=true
	var no_gap: RefCounted=bot._new_expedition(1,17)
	var ambush_room: int=-1
	for room in range(5):
		for enemy in no_gap.waves[room]:
			if enemy.has("spawned") and not enemy.spawned: ambush_room=room
	if ambush_room>=0:
		no_gap.stage=ambush_room
		no_gap.phase="combat"
		no_gap.hero_pos=no_gap.checkpoint(ambush_room)
		for enemy in no_gap.waves[ambush_room]:
			if enemy.get("spawned",true): enemy.hp=0
	var no_gap_spawned:=false
	for event in no_gap.advance(0.1):
		if event.type=="reinforcement_spawn": no_gap_spawned=true
	check(ambush_room>=0 and no_gap_spawned,"ambush arrives immediately when its room is already clear")
	for serial in range(Layout.VARIANT_COUNT):
		var sample: RefCounted=bot._new_expedition(1,serial)
		var scheduled: Array[String]=[]
		for room in range(5):
			for enemy in sample.waves[room]:
				if not enemy.has("spawned"): continue
				scheduled.append("%d:%d" % [room,enemy.id%10])
				var entry: Vector2=enemy.spawn
				var center: Vector2=sample.checkpoint(room)
				reinforcement_entry_signatures["%d:%s" % [room,str(entry.snapped(Vector2(0.01,0.01)))]]=true
				if not Layout.contains(Layout.region(sample.floor_id),entry,sample.layout_seed(),sample.movement_seed(),sample.uses_wandering_routes(),sample.uses_scouting_routes()): reinforcement_entries_walkable=false
				var offset:=entry-center
				if maxf(absf(offset.x)/Layout.ROOM_HALF.x,absf(offset.y)/Layout.ROOM_HALF.y)<0.5: reinforcement_entries_at_edge=false
				for other in sample.waves[room]:
					if int(other.id)==int(enemy.id) or not other.get("spawned",true) or other.hp<=0: continue
					if entry.distance_to(Vector2(other.pos))<1.799: reinforcement_entries_spaced=false
		reinforcement_patterns[str(scheduled)]=true
	check(reinforcement_patterns.size()>=60,"the pattern bank varies which rooms and enemies create ambushes")
	check(reinforcement_entry_signatures.size()>=250,"seed-bound ambushes use many distinct room-edge entry points")
	check(reinforcement_entries_walkable,"every ambush entry point is on walkable room floor")
	check(reinforcement_entries_at_edge,"ambushes enter from the outer half of their chamber")
	check(reinforcement_entries_spaced,"ambushes enter at least 1.8 metres from the active group")
	var ambush_live: RefCounted=bot._new_expedition(1,17)
	var ambush_resume:=Sim.new()
	var saw_ambush:=false
	while not ambush_live.finished and not saw_ambush:
		for event in ambush_live.advance(0.1):
			if event.type=="reinforcement_spawn":
				saw_ambush=true
				check(ambush_resume.restore_encoded(ambush_live.encode_snapshot()),"checkpoint during a dungeon ambush restores")
				break
	ambush_live.simulate_to_end()
	ambush_resume.simulate_to_end()
	check(saw_ambush and outcome(ambush_live)==outcome(ambush_resume),"live and restored ambush runs finish identically")
	var model: RefCounted=bot._new_expedition(1,1)
	check(model.uses_tactical_movement() and model.uses_scouting_routes() and model.journey.has("combat_movement"),"new campaign expeditions carry generation-6 exploration routes and tactical movement state")
	var movement_patterns: Dictionary={}
	var movement_is_walkable:=true
	var movement_keeps_class_range:=true
	var ready_attacks_are_not_delayed:=true
	var movement_restores:=false
	var deterministic_movement:=true
	for selected in ["Vowkeeper","Arcanist","Ranger"]:
		bot.character_class=selected
		var class_patterns: Dictionary={}
		for serial in range(24):
			var run_seed:=1979+serial*104729
			var stats: Dictionary=bot._combat_stats()
			var sim:=Sim.new()
			sim.setup(selected,stats,1,"Movement guardian",run_seed)
			var target:=prepare_maneuver(sim)
			var origin: Vector2=sim.hero_pos
			var moved: bool=sim._tick_combat_movement(target,true)
			var first_move_position: Vector2=sim.hero_pos
			var first_move_state: Dictionary=sim.journey.combat_movement.duplicate(true)
			var first_move_rng: int=sim.rng.state
			if moved:
				class_patterns[str((sim.hero_pos-origin).normalized().snapped(Vector2(0.1,0.1)))]=true
				if not Layout.contains(Layout.region(sim.floor_id),sim.hero_pos,sim.layout_seed(),sim.movement_seed(),sim.uses_wandering_routes(),sim.uses_scouting_routes()): movement_is_walkable=false
				if not Layout.contains(Layout.region(sim.floor_id),sim.journey.combat_movement.goal,sim.layout_seed(),sim.movement_seed(),sim.uses_wandering_routes(),sim.uses_scouting_routes()): movement_is_walkable=false
				var radius: float=sim.hero_pos.distance_to(target.pos)
				if selected=="Vowkeeper" and (radius<0.85 or radius>1.65): movement_keeps_class_range=false
				if selected!="Vowkeeper" and (radius<2.8 or radius>5.05): movement_keeps_class_range=false
				if not movement_restores and float(sim.journey.combat_movement.remaining)>0.0:
					var resumed:=Sim.new()
					var loaded: bool=resumed.restore_encoded(sim.encode_snapshot())
					if loaded:
						for step in range(8):
							if float(sim.journey.combat_movement.remaining)>0.0: sim._tick_combat_movement(sim.enemy_by_id(target.id),true)
							if float(resumed.journey.combat_movement.remaining)>0.0: resumed._tick_combat_movement(resumed.enemy_by_id(target.id),true)
						movement_restores=sim.snapshot()==resumed.snapshot()
					else:
						movement_restores=false
				var replay:=Sim.new()
				replay.setup(selected,stats,1,"Movement guardian",run_seed)
				var replay_target:=prepare_maneuver(replay)
				var replay_moved: bool=replay._tick_combat_movement(replay_target,true)
				if replay_moved!=moved or replay.hero_pos!=first_move_position or replay.journey.combat_movement!=first_move_state or replay.rng.state!=first_move_rng: deterministic_movement=false
				var movement_steps:=0
				while float(sim.journey.combat_movement.remaining)>0.0 and movement_steps<64:
					sim._tick_combat_movement(sim.enemy_by_id(target.id),true)
					var step_radius: float=sim.hero_pos.distance_to(target.pos)
					if not Layout.contains(Layout.region(sim.floor_id),sim.hero_pos,sim.layout_seed(),sim.movement_seed(),sim.uses_wandering_routes(),sim.uses_scouting_routes()): movement_is_walkable=false
					if selected=="Vowkeeper" and (step_radius<0.85 or step_radius>1.65): movement_keeps_class_range=false
					if selected!="Vowkeeper" and (step_radius<2.8 or step_radius>5.05): movement_keeps_class_range=false
					movement_steps+=1
				if float(sim.journey.combat_movement.remaining)>0.0: movement_is_walkable=false
		movement_patterns[selected]=class_patterns.size()
		var ready_sim:=Sim.new()
		ready_sim.setup(selected,bot._combat_stats(),1,"Movement guardian",1979)
		prepare_maneuver(ready_sim)
		ready_sim.hero_mana=0
		ready_sim.attack_cd=0.0
		ready_sim.journey.combat_movement.remaining=0.4
		ready_sim.journey.combat_movement.goal=ready_sim.hero_pos+Vector2(0.3,0)
		var ready_position: Vector2=ready_sim.hero_pos
		ready_sim._auto_hero()
		if ready_sim.pending_attack.is_empty() or ready_sim.hero_pos!=ready_position or not is_equal_approx(float(ready_sim.journey.combat_movement.remaining),0.4): ready_attacks_are_not_delayed=false
	check(movement_patterns.get("Vowkeeper",0)>=12,"Vowkeeper combat steps vary by seed while staying in melee reach")
	check(movement_patterns.get("Arcanist",0)>=12,"Arcanist combat steps vary by seed while holding spell distance")
	check(movement_patterns.get("Ranger",0)>=12,"Ranger combat steps vary by seed while holding firing distance")
	check(movement_is_walkable,"random combat steps and their destinations stay inside the active chamber")
	check(movement_keeps_class_range,"class combat steps preserve melee and ranged attack distances")
	check(movement_restores,"a saved movement step resumes with exactly the same state and RNG")
	check(deterministic_movement,"the same class and run seed reproduce the same combat step")
	check(ready_attacks_are_not_delayed,"a ready attack fires immediately while a reposition step is pending")
	var legacy_stats: Dictionary=model.stats.duplicate(true)
	legacy_stats.dungeon_generation=4
	var legacy_generation:=Sim.new()
	legacy_generation.setup("Vowkeeper",legacy_stats,1,"Movement guardian",model.run_seed)
	var legacy_generation_resume:=Sim.new()
	check(not legacy_generation.uses_tactical_movement() and not legacy_generation.journey.has("combat_movement") and legacy_generation_resume.restore_encoded(legacy_generation.encode_snapshot()),"generation-4 expeditions restore without the new movement state")
	var missing_movement: Dictionary=model.snapshot()
	missing_movement.journey.erase("combat_movement")
	check(not Sim.new().restore(missing_movement),"generation-5 checkpoints cannot resume without their movement state")
	for invalid in [-1,2,1.0,"yes"]:
		var bad: Dictionary=model.snapshot()
		bad.fields.stats.dungeon_journey=invalid
		check(not Sim.new().restore(bad),"invalid journey flag rejected: "+str(invalid))
	for missing in ["travel_index","channel","well_used","seal_broken","chest_open"]:
		var bad: Dictionary=model.snapshot()
		bad.journey.erase(missing)
		check(not Sim.new().restore(bad),"missing journey field rejected: "+missing)
	var deadline:=Sim.new()
	deadline.restore_encoded(model.encode_snapshot())
	deadline.elapsed=239.95
	deadline.advance(0.1)
	check(deadline.finished and not deadline.won,"new journey stops at its four-minute safety limit")
	deadline=Sim.new()
	deadline.restore_encoded(legacy[0].snapshot)
	deadline.elapsed=179.95
	deadline.advance(0.1)
	check(deadline.finished and not deadline.won,"old checkpoint keeps its three-minute limit")
	var bad: Dictionary=model.snapshot()
	bad.journey.travel_index=4
	check(not Sim.new().restore(bad),"invalid current travel leg rejected")
	bad=model.snapshot()
	bad.fields.stage=4
	check(not Sim.new().restore(bad),"closed sanctum cannot resume beyond its seal")
	# Healing cannot be awarded twice after a checkpoint during the channel.
	model.stage=1
	model.phase="interact"
	model.hero_pos=Layout.interact_point(0,1,model.layout_seed())+Vector2(0,1.25)
	model.hero_hp-=100
	model.journey.channel=0.8
	var restored:=Sim.new()
	check(restored.restore_encoded(model.encode_snapshot()),"mid-well channel restores")
	var before: int=restored.hero_hp
	restored.advance(0.5)
	var healed: int=restored.hero_hp
	check(healed>before and restored.journey.well_used,"well restores actual Life once")
	restored._tick_journey()
	check(restored.hero_hp==healed,"well cannot grant duplicate healing")
	bot.free()
	# Visible map and props also reconstruct correctly from a saved objective state.
	var game: Node=load("res://Main.tscn").instantiate()
	root.add_child(game)
	game.farm_enabled=false
	game.floor_number=1
	game._start_run(1)
	game.run_arena.animation_enabled=false
	var world: Node=game.run_arena.world
	check(game.find_child("ExpeditionMap",true,false)!=null,"in-run route map is present")
	var route_map: Control=game.find_child("ExpeditionMap",true,false)
	check(route_map.custom_minimum_size==Vector2(200,96),"in-run route map uses the enlarged landscape footprint")
	check(game.combat_hud.room.get_theme_font_size("font_size")>=11 and game.combat_hud.objective.get_theme_font_size("font_size")>=10 and game.combat_hud.encounter.get_theme_font_size("font_size")>=11,"combat objective and pack labels use readable base sizes")
	check(world.journey_props.size()==3 and world.sanctum_gate.position.y==0.0,"well, seal, chest and closed gate are rendered")
	game.expedition.journey.seal_broken=true
	game.expedition.journey.chest_open=true
	world._sync_journey_props(10.0)
	check(world.sanctum_gate.position.y< -2.0 and not world.journey_props[3].get_node("SealGem").visible,"breaking the seal opens the visible gate")
	check(world.journey_props[5].get_node("LootBeam").visible,"opened chest displays its loot beam")
	game.run_succeeded=true
	game.run_loot=[{"name":"Ashen Vowblade","quality":"LEGENDARY","slot":"Weapon"}]
	game._present_recovered_gear()
	check(world.recovered_drops.size()==1 and world.recovered_drops[0].item.name==game.run_loot[0].name and world.recovered_drops[0].item.quality==game.run_loot[0].quality,"the reliquary displays the same named, quality-rated item awarded to the player")
	check(is_instance_valid(world.recovered_drops[0].label) and world.recovered_drops[0].label.text.contains("Ashen Vowblade") and world.recovered_drops[0].node.get_node_or_null("RelicLabel")!=null,"the recovered 3D relic shows its item name in the dungeon")
	game.free()
	print("JOURNEY SMOKE: ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
