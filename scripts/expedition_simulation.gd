extends RefCounted
## Single deterministic authority for watched, skipped and offline expeditions.
## All combat and movement use fixed 100 ms steps; rendering never rolls damage.
const Contract = preload("res://scripts/expedition_contract.gd")
const Skills = preload("res://scripts/class_skills.gd")
const Layout = preload("res://scripts/dungeon_layout.gd")
const ThemeData = preload("res://scripts/dungeon_theme.gd")
const BossPatterns = preload("res://scripts/boss_patterns.gd")
const STEP := 0.1
const WALK_SPEED := 2.55
const MAX_DURATION := 240.0
const LEGACY_MAX_DURATION := 180.0
const COMBAT_VARIANTS := Layout.VARIANT_COUNT
const CHECKPOINTS := [Vector2(0,-4),Vector2(3,-15),Vector2(0,-27),Vector2(-3,-39),Vector2(2,-50),Vector2(0,-63)]
const PACKS := [
	["raider","raider","raider"],
	["raider","hexer","raider"],
	["bulwark","hexer","raider"],
	["elite","raider","raider"],
	["hexer","bulwark","hexer"],
	["boss","raider","hexer"]
]
const ROLE_NAMES := {"raider":"Hollow Stalker","bulwark":"Ashbound Shieldbearer","hexer":"Grave Hexer","elite":"Cinder Captain","boss":"The Bell Warden"}
const ABILITIES := {"Vowkeeper":"Ember Oath","Arcanist":"Veil Nova","Ranger":"Cinder Volley"}
var class_key := "Vowkeeper"
var stats: Dictionary = {}
var floor_id := 1
var run_seed := 1
var legacy_layout := false
var rng := RandomNumberGenerator.new()
var waves: Array = []
var stage := 0
var phase := "travel"
var phase_clock := 0.0
var elapsed := 0.0
var accumulator := 0.0
var hero_pos := Vector2(0,5)
var hero_hp := 100
var hero_mana := 100
var target_id := -1
var action := "Moving"
var attack_cd := 0.0
var skill_cd := 0.0
var dodge_cd := 0.0
var guard_time := 0.0
var pending_attack: Dictionary = {}
var dodge_goal := Vector2.ZERO
var dodging := false
var finished := false
var won := false
var events: Array = []
var kills := 0
var dodges := 0
var casts := 0
var journey: Dictionary = {}
var rotation: Dictionary = {}

func setup(selected_class: String, combat_stats: Dictionary, target_floor: int, boss_name: String, seed_value: int) -> void:
	class_key = selected_class
	stats = combat_stats.duplicate(true)
	floor_id = maxi(1,target_floor)
	run_seed = seed_value
	legacy_layout = false
	rng.seed = Layout.procedural_seed(run_seed,floor_id) if uses_procedural_generation() else Layout.variant_seed(run_seed,floor_id)
	hero_hp = int(stats.max_hp)
	hero_mana = int(stats.max_mana)
	if uses_rotation():
		rotation={"cooldowns":{},"uses":{}}
		for key in stats.skill_loadout:
			rotation.cooldowns[key]=0.0
			rotation.uses[key]=0
	var scaling := 1.0+float(floor_id-1)*0.13+pow(maxf(floor_id-8,0.0),1.35)*0.035
	if uses_journey():
		journey={"travel_index":0,"channel":0.0,"well_used":false,"seal_broken":false,"chest_open":false}
	var variant_key := layout_seed()
	var region_id := Layout.region(floor_id)
	var packs: Array = Layout.packs(region_id,variant_key) if uses_journey() else PACKS
	var offsets := [Vector2(-1.2,0.3),Vector2(0,-1.1),Vector2(1.2,0.4),Vector2(-2.4,-1.5),Vector2(2.4,-1.4)]
	for room in range(packs.size()):
		var pack: Array = []
		var spawn_points: Array=Layout.spawn_points(region_id,room,packs[room].size(),variant_key) if uses_journey() else []
		for slot in range(packs[room].size()):
			var role: String = packs[room][slot]
			var hp := int(float({"raider":300,"bulwark":520,"hexer":260,"elite":850,"boss":2400}[role])*scaling)
			if uses_journey() and role not in ["boss","elite"]: hp=int(hp*0.72)
			hp=int(hp*Contract.health_scale(contract()))
			var point: Vector2 = Vector2(spawn_points[slot]) if uses_journey() else checkpoint(room)+offsets[slot]
			if role == "boss": point = checkpoint(room)
			if role == "hexer": point.y -= 1.0
			var enemy: Dictionary={"id":room*10+slot,"role":role,"name":boss_name if role=="boss" else ThemeData.enemy_name((floor_id-1)/10,role),"hp":hp,"max_hp":hp,"pos":point,"spawn":point,"cooldown":0.7+slot*0.35,"special_cd":2.5,"slow":0.0,"warning":{},"damage":(10.0+floor_id*2.2)*(1.6 if role in ["elite","boss"] else 1.0)}
			if uses_procedural_generation():
				enemy["cooldown"]+=rng.randf_range(0.0,0.35)
				if role=="raider":
					enemy["flank_phase"]=rng.randf_range(0.0,TAU)
					enemy["flank_direction"]=-1.0 if rng.randf()<0.5 else 1.0
					enemy["flank_radius"]=rng.randf_range(0.35,0.85)
				elif role=="hexer":
					enemy["preferred_range"]=rng.randf_range(4.2,5.8)
					enemy["warning_radius"]=rng.randf_range(0.95,1.4)
					enemy["warning_duration"]=rng.randf_range(0.85,1.2)
				elif role=="elite":
					enemy["special_cd"]=rng.randf_range(2.4,4.0)
			pack.append(enemy)
			pack.back().damage*=Contract.damage_scale(contract())
			if role=="boss" and int(stats.get("boss_patterns",0))==1: pack.back()["awakened"]=false
			if role=="boss" and uses_procedural_generation(): pack.back()["last_pattern_variant"]=-1
		waves.append(pack)
	if uses_procedural_generation() and int(stats.get("dungeon_generation",1))>=4:
		_prepare_reinforcements()
	if uses_tactical_movement():
		journey["combat_movement"]={"target":-1,"wait":rng.randf_range(0.8,1.6),"remaining":0.0,"goal":hero_pos}

func _prepare_reinforcements() -> void:
	# Two members of the ordinary packs arrive late as seed-bound ambushes.
	# They remain part of the original 26-enemy budget, so rewards and AFK
	# accounting do not change when their arrival timing changes.
	var selected_rooms: Array[int]=[]
	while selected_rooms.size()<2:
		var room:=rng.randi_range(0,4)
		if not selected_rooms.has(room): selected_rooms.append(room)
	for ambush_index in range(selected_rooms.size()):
		var room: int=selected_rooms[ambush_index]
		var candidates: Array[int]=[]
		for slot in range(waves[room].size()):
			var enemy: Dictionary=waves[room][slot]
			if enemy.role in ["raider","hexer"]: candidates.append(slot)
		if candidates.is_empty(): continue
		var chosen_slot: int=candidates[rng.randi_range(0,candidates.size()-1)]
		var chosen: Dictionary=waves[room][chosen_slot]
		chosen["spawned"]=false
		chosen["spawn_delay"]=rng.randf_range(3.8,7.2)+float(ambush_index)*0.6
		var entry_point:=_ambush_entry_point(room,int(chosen.id))
		chosen["pos"]=entry_point
		chosen["spawn"]=entry_point

func _ambush_entry_point(room: int, excluded_id: int) -> Vector2:
	# Late arrivals enter from a seed-selected edge of the chamber rather than
	# materializing in their original formation. Keep each point inside the
	# walkable room and clear of the enemies already fighting there.
	var origin:=checkpoint(room)
	for attempt in range(16):
		var angle:=rng.randf_range(-PI,PI)
		var candidate:=origin+Vector2(cos(angle)*rng.randf_range(4.35,5.0),sin(angle)*rng.randf_range(3.55,4.15))
		candidate=Layout.combat_point(Layout.region(floor_id),room,candidate,layout_seed())
		var spaced:=true
		for enemy in waves[room]:
			if int(enemy.id)==excluded_id or enemy.hp<=0 or not enemy.get("spawned",true): continue
			if candidate.distance_to(Vector2(enemy.pos))<1.8:
				spaced=false
				break
		if spaced: return candidate
	return origin+Vector2(4.7,0.0)

func advance(delta: float) -> Array:
	events = []
	if finished: return events
	accumulator += maxf(0.0,delta)
	while accumulator+0.00001 >= STEP and not finished:
		accumulator -= STEP
		_step()
	return events.duplicate(true)

func simulate_to_end() -> void:
	# Same fixed steps as the live scene, no estimated success chance.
	while not finished:
		advance(1.0)

func living() -> Array:
	var result: Array = []
	if stage >= waves.size(): return result
	for enemy in waves[stage]:
		if enemy.hp>0 and enemy.get("spawned",true): result.append(enemy)
	return result

func enemy_by_id(id_value: int) -> Dictionary:
	if id_value<0: return {}
	var wave_index := id_value/10
	var slot := id_value%10
	if wave_index<0 or wave_index>=waves.size() or slot>=waves[wave_index].size(): return {}
	return waves[wave_index][slot]

func _step() -> void:
	elapsed += STEP
	phase_clock += STEP
	attack_cd = maxf(0.0,attack_cd-STEP)
	skill_cd = maxf(0.0,skill_cd-STEP)
	dodge_cd = maxf(0.0,dodge_cd-STEP)
	guard_time = maxf(0.0,guard_time-STEP)
	if uses_rotation():
		for key in rotation.cooldowns: rotation.cooldowns[key]=maxf(0.0,rotation.cooldowns[key]-STEP)
	if elapsed >= duration_limit():
		_finish(false)
		return
	if uses_journey() and phase in ["travel","interact"]:
		_tick_journey()
		return
	if phase == "travel":
		var approach := 2.1 if class_key=="Vowkeeper" else 4.4
		var goal: Vector2 = checkpoint(stage)+Vector2(0,approach)
		hero_pos = hero_pos.move_toward(goal,WALK_SPEED*STEP)
		action = "Moving to encounter %d" % (stage+1)
		if hero_pos.distance_to(goal)<0.03:
			phase = "combat"
			phase_clock = 0.0
			events.append({"type":"engage","stage":stage})
		return
	if phase == "loot":
		action = "Collecting • continuing the descent"
		if phase_clock>=0.9:
			stage += 1
			if uses_journey(): journey.travel_index=0
			if stage >= waves.size():
				_finish(true)
			else:
				phase = "travel"
				phase_clock = 0.0
		return
	if phase != "combat": return
	_tick_reinforcements()
	var targets := living()
	if targets.is_empty():
		if _has_pending_reinforcements(stage):
			action = "Listening for movement in the dark"
			return
		phase = "interact" if uses_journey() else "loot"
		phase_clock = 0.0
		if uses_journey(): journey.channel=0.0
		pending_attack.clear()
		dodging = false
		return
	for enemy in targets:
		enemy.slow = maxf(0.0,enemy.slow-STEP)
		_tick_enemy(enemy)
		for other in targets:
			if enemy.id==other.id: continue
			var separation: Vector2 = Vector2(enemy.pos)-Vector2(other.pos)
			if separation.length()>0.01 and separation.length()<0.75:
				enemy.pos = _clamp_walkable(Vector2(enemy.pos)+separation.normalized()*0.08)
		if hero_hp<=0:
			_finish(false)
			return
	_auto_hero()

func _has_pending_reinforcements(room: int) -> bool:
	if room<0 or room>=waves.size(): return false
	for enemy in waves[room]:
		if enemy.hp>0 and not enemy.get("spawned",true): return true
	return false

func _tick_reinforcements() -> void:
	if stage<0 or stage>=waves.size(): return
	for enemy in waves[stage]:
		if enemy.hp<=0 or enemy.get("spawned",true): continue
		# If the first wave is already gone, release the remaining ambush
		# immediately instead of making a strong build wait for a timer.
		enemy.spawn_delay=0.0 if living().is_empty() else maxf(0.0,float(enemy.spawn_delay)-STEP)
		if enemy.spawn_delay<=0.0:
			enemy.spawned=true
			enemy.pos=enemy.spawn
			events.append({"type":"reinforcement_spawn","source":enemy.id,"position":enemy.pos,"name":enemy.name})

func _choose_target() -> Dictionary:
	var best: Dictionary = {}
	var best_score := -INF
	var candidates: Array[Dictionary]=[]
	for enemy in living():
		var distance: float = hero_pos.distance_to(enemy.pos)
		var score := -distance*10.0
		if class_key=="Ranger":
			score += 90.0 if enemy.role=="hexer" else 0.0
			score += (1.0-float(enemy.hp)/float(enemy.max_hp))*30.0
		elif class_key=="Arcanist":
			for neighbor in living():
				if Vector2(enemy.pos).distance_to(neighbor.pos)<=3.1: score += 18.0
		elif enemy.role in ["bulwark","elite","boss"]:
			score += 8.0
		candidates.append({"enemy":enemy,"score":score})
		if score>best_score:
			best = enemy
			best_score = score
	if not uses_varied_targeting() or candidates.size()<2:
		return best
	# Only vary among similarly valuable enemies, and hold the current target
	# throughout its attack cooldown. The seeded choice is replayable in AFK/skip.
	var close_targets: Array[Dictionary]=[]
	for candidate in candidates:
		if best_score-float(candidate.score)<=10.0:
			close_targets.append(candidate.enemy)
	if close_targets.size()<2:
		return best
	var current:=enemy_by_id(target_id)
	if not current.is_empty() and current.hp>0 and current.get("spawned",true):
		var reach:=1.75 if class_key=="Vowkeeper" else 5.2
		if attack_cd>0.0 or hero_pos.distance_to(current.pos)>reach:
			return current
	return close_targets[rng.randi_range(0,close_targets.size()-1)]

func _tick_combat_movement(target: Dictionary, can_start: bool) -> bool:
	if not uses_tactical_movement() or journey.is_empty(): return false
	var movement: Dictionary=journey.get("combat_movement",{})
	if movement.is_empty(): return false
	if int(movement.get("target",-1))!=int(target.id):
		movement["target"]=int(target.id)
		movement["remaining"]=0.0
		movement["goal"]=hero_pos
		movement["wait"]=rng.randf_range(0.8,1.6)
	if float(movement.remaining)>0.0:
		# Reposition during an attack cooldown, but never let it consume a ready
		# attack. Keep the unfinished step for the next cooldown window.
		if not can_start:
			journey["combat_movement"]=movement
			return false
		var goal: Vector2=movement.goal
		var step_distance:=WALK_SPEED*1.2*STEP
		var next_position:=hero_pos.move_toward(goal,step_distance)
		var target_distance:=next_position.distance_to(target.pos)
		var leaves_combat_space:=not _combat_position_walkable(next_position)
		var leaves_class_range:=class_key=="Vowkeeper" and (target_distance<0.85 or target_distance>1.65)
		if leaves_combat_space or leaves_class_range or _combat_position_threatened(next_position) or _combat_position_threatened(hero_pos.lerp(next_position,0.5)):
			movement["remaining"]=0.0
			movement["wait"]=rng.randf_range(0.6,1.2)
			journey["combat_movement"]=movement
			return false
		hero_pos=goal if hero_pos.distance_to(goal)<=step_distance else next_position
		movement["remaining"]=maxf(0.0,float(movement.remaining)-STEP)
		if hero_pos.distance_to(goal)<0.08:
			movement["remaining"]=0.0
			movement["wait"]=rng.randf_range(0.8,1.7)
		journey["combat_movement"]=movement
		action="Circling " + String(target.name) if class_key=="Vowkeeper" else "Shifting firing position"
		return true
	if not can_start:
		journey["combat_movement"]=movement
		return false
	movement["wait"]=maxf(0.0,float(movement.wait)-STEP)
	if float(movement.wait)>0.0:
		journey["combat_movement"]=movement
		return false
	if _combat_position_threatened(hero_pos):
		movement["wait"]=rng.randf_range(0.45,0.9)
		journey["combat_movement"]=movement
		return false
	var target_position: Vector2=target.pos
	var relative:=hero_pos-target_position
	var current_angle:=atan2(relative.y,relative.x) if relative.length()>0.01 else rng.randf_range(-PI,PI)
	for attempt in range(10):
		var side:=1.0 if rng.randf()<0.5 else -1.0
		var angle:=current_angle+side*rng.randf_range(0.32,1.05)
		var radius:=rng.randf_range(1.0,1.5) if class_key=="Vowkeeper" else rng.randf_range(3.25,4.75)
		var candidate:=_clamp_walkable(target_position+Vector2.from_angle(angle)*radius)
		var distance_to_target:=candidate.distance_to(target_position)
		if hero_pos.distance_to(candidate)<0.35: continue
		if class_key=="Vowkeeper" and (distance_to_target<0.9 or distance_to_target>1.6): continue
		if class_key!="Vowkeeper" and (distance_to_target<2.8 or distance_to_target>5.05): continue
		var step_goal:=hero_pos.move_toward(candidate,minf(hero_pos.distance_to(candidate),rng.randf_range(0.65,1.15)))
		var goal_distance:=step_goal.distance_to(target_position)
		if class_key=="Vowkeeper" and (goal_distance<0.85 or goal_distance>1.65): continue
		if _combat_position_threatened(step_goal) or _combat_position_threatened(hero_pos.lerp(step_goal,0.5)): continue
		var crowded:=false
		for enemy in living():
			if enemy.id!=target.id and Vector2(enemy.pos).distance_to(step_goal)<0.62:
				crowded=true
				break
		if crowded: continue
		movement["goal"]=step_goal
		movement["remaining"]=hero_pos.distance_to(step_goal)/(WALK_SPEED*1.2)
		movement["wait"]=0.0
		journey["combat_movement"]=movement
		return _tick_combat_movement(target,true)
	movement["wait"]=rng.randf_range(0.6,1.1)
	journey["combat_movement"]=movement
	return false

func _combat_position_threatened(point: Vector2) -> bool:
	for enemy in living():
		if not enemy.warning.is_empty() and BossPatterns.threatens(enemy.warning,point,0.2): return true
	return false

func _combat_position_walkable(point: Vector2) -> bool:
	if not uses_journey(): return true
	return Layout.contains(Layout.region(floor_id),point,layout_seed(),movement_seed(),uses_wandering_routes(),uses_scouting_routes(),uses_expanded_scouting_routes())

func _auto_hero() -> void:
	# React to committed ground attacks, not to future random results.
	if dodge_cd<=0.0 and not dodging:
		for enemy in living():
			if enemy.warning.is_empty(): continue
			var warning: Dictionary = enemy.warning
			if warning.has("zones"):
				if warning.left>0.95 or not BossPatterns.threatens(warning,hero_pos,0.2): continue
				dodge_goal=_safe_boss_escape()
				if dodge_goal==hero_pos: continue
			else:
				if warning.left>0.75 or hero_pos.distance_to(warning.center)>warning.radius+0.2: continue
				var away: Vector2 = (hero_pos-Vector2(warning.center)).normalized()
				if away.length()<0.1: away = Vector2(1,0)
				dodge_goal = _clamp_walkable(Vector2(warning.center)+away*(warning.radius+0.7))
				if dodge_goal.distance_to(warning.center)<warning.radius+0.1:
					dodge_goal = _clamp_walkable(Vector2(warning.center)+Vector2(0,warning.radius+0.8))
			dodging = true
			dodges += 1
			dodge_cd = 3.5 if class_key=="Ranger" else 6.0
			pending_attack.clear()
			events.append({"type":"evade","position":hero_pos,"goal":dodge_goal})
			break
	if dodging:
		hero_pos = hero_pos.move_toward(dodge_goal,6.8*STEP)
		action = "Evading a ground attack"
		if hero_pos.distance_to(dodge_goal)<0.1: dodging = false
		return
	if not pending_attack.is_empty():
		pending_attack.left -= STEP
		if pending_attack.left<=0.0:
			_resolve_hero_attack()
		return
	var target := _choose_target()
	if target.is_empty(): return
	target_id = target.id
	var distance := hero_pos.distance_to(target.pos)
	var reach := 1.75 if class_key=="Vowkeeper" else 5.2
	if class_key=="Ranger" and distance<1.5 and dodge_cd<=0:
		var away: Vector2 = (hero_pos-Vector2(target.pos)).normalized()
		dodge_goal = _clamp_walkable(hero_pos+away*2.4)
		dodging = true
		dodge_cd = 3.5
		events.append({"type":"backstep","position":hero_pos,"goal":dodge_goal})
		return
	if distance>reach:
		var next_position:=_clamp_walkable(hero_pos.move_toward(target.pos,WALK_SPEED*STEP))
		for enemy in living():
			if enemy.warning.has("zones") and not BossPatterns.threatens(enemy.warning,hero_pos,0.2) and BossPatterns.threatens(enemy.warning,next_position,0.2):
				action="Holding safe ground"
				return
		hero_pos = next_position
		action = "Closing on " + String(target.name)
		return
	if attack_cd>0:
		if class_key=="Arcanist" and int(stats.get("arcane_tactics",0))==1 and _arcane_reposition():
			action="Creating spell distance"
			return
	if _tick_combat_movement(target,attack_cd>0.0): return
	if attack_cd>0:
		action = "Holding the front line" if class_key=="Vowkeeper" else "Keeping firing distance"
		return
	if uses_rotation() and _try_technique(target,true): return
	var use_skill := skill_cd<=0 and hero_mana>=int(stats.mana_cost)
	var nearby := 0
	for enemy in living():
		if Vector2(enemy.pos).distance_to(hero_pos if class_key=="Vowkeeper" else target.pos)<=3.2: nearby += 1
	if class_key=="Vowkeeper": use_skill = use_skill and (nearby>=2 or hero_hp<int(stats.max_hp)*0.75 or target.role in ["boss","elite"])
	elif class_key=="Arcanist": use_skill = use_skill and (nearby>=2 or target.role in ["boss","elite"])
	elif class_key=="Ranger": use_skill = use_skill and (target.role in ["hexer","elite","boss"] or living().size()>=2)
	if not use_skill and uses_rotation() and _try_technique(target,false): return
	var name_value: String = ABILITIES[class_key] if use_skill else {"Vowkeeper":"Oathblade","Arcanist":"Arcane Bolt","Ranger":"Piercing Shot"}[class_key]
	pending_attack = {"target":target.id,"skill":use_skill,"left":0.3,"name":name_value}
	attack_cd = 1.05 if class_key=="Ranger" else 1.3
	if use_skill:
		hero_mana -= int(stats.mana_cost)
		skill_cd = {"Vowkeeper":5.5,"Arcanist":6.0,"Ranger":4.5}[class_key]
		casts += 1
		action = "Casting " + name_value
	else:
		action = name_value
	events.append({"type":"hero_attack","target":target.id,"skill":use_skill,"name":name_value})

func _arcane_reposition() -> bool:
	# Walk between committed casts. Never cancel an attack, teleport or gain
	# invulnerability; the normal dodge cooldown still governs ground attacks.
	var nearest:=INF
	for enemy in living():
		if enemy.role!="hexer": nearest=minf(nearest,hero_pos.distance_to(enemy.pos))
	if nearest>=2.8: return false
	var best:=hero_pos
	var best_distance:=nearest+0.02
	for direction in range(16):
		var point:=_clamp_walkable(hero_pos+Vector2.from_angle(TAU*direction/16.0)*WALK_SPEED*STEP)
		if point.distance_to(checkpoint(stage))>6.5: continue
		var safe:=true
		var separation:=INF
		for enemy in living():
			if not enemy.warning.is_empty() and BossPatterns.threatens(enemy.warning,point,0.2):
				safe=false
				break
			if enemy.role!="hexer": separation=minf(separation,point.distance_to(enemy.pos))
		if safe and separation>best_distance:
			best=point
			best_distance=separation
	if best==hero_pos: return false
	hero_pos=best
	return true

func _resolve_hero_attack() -> void:
	var attack := pending_attack.duplicate()
	pending_attack.clear()
	if attack.has("ability_id"):
		_resolve_technique(attack)
		return
	var target := enemy_by_id(attack.target)
	if target.is_empty() or target.hp<=0: return
	var selected: Array = [target]
	if attack.skill:
		selected.clear()
		for enemy in living():
			var origin: Vector2 = hero_pos if class_key=="Vowkeeper" else target.pos
			var radius := 2.9 if class_key=="Vowkeeper" else 4.5 if class_key=="Arcanist" and int(stats.get("arcane_tactics",0))==1 else 3.2
			if class_key=="Ranger":
				origin = hero_pos
				radius = 6.0
			if Vector2(enemy.pos).distance_to(origin)<=radius: selected.append(enemy)
		if not selected.has(target): selected.append(target)
		if class_key=="Vowkeeper":
			guard_time = maxf(guard_time,2.8) if uses_rotation() else 2.8
			var healed := mini(int(stats.max_hp)-hero_hp,int(float(stats.max_hp)*0.08))
			hero_hp += healed
			events.append({"type":"guard","heal":healed})
		elif class_key=="Arcanist":
			hero_mana = mini(int(stats.max_mana),hero_mana+int(stats.mana_cost)/4)
			events.append({"type":"nova","position":target.pos,"radius":4.5 if int(stats.get("arcane_tactics",0))==1 else 3.2})
	for enemy in selected:
		var amount := float(stats.ability_damage if attack.skill else stats.attack)
		if attack.skill: amount *= 0.82 if class_key=="Ranger" else 0.90
		var crit := rng.randf()*100.0 < float(stats.crit)+(12.0 if class_key=="Ranger" and attack.skill else 0.0)
		if crit: amount *= 2.15 if class_key=="Ranger" else 1.7
		if enemy.role in ["bulwark","elite"] and class_key!="Arcanist": amount *= 0.72
		var damage := mini(enemy.hp,maxi(1,int(amount)))
		enemy.hp -= damage
		if attack.skill and class_key=="Arcanist": enemy.slow = 2.4
		if attack.skill and enemy.role=="hexer":
			enemy.warning = {}
			enemy.cooldown = 1.5
			events.append({"type":"interrupt","target":enemy.id})
		events.append({"type":"hit","target":enemy.id,"damage":damage,"critical":crit,"skill":attack.skill,"name":attack.name,"dead":enemy.hp<=0})
		if enemy.hp<=0:
			kills += 1
			enemy.warning = {}
	hero_mana = mini(int(stats.max_mana),hero_mana+maxi(1,int(stats.attributes.Spirit)/4))

func _safe_boss_escape() -> Vector2:
	var best:=hero_pos
	var best_distance:=INF
	for radius in [0.8,1.4,2.1,3.0,4.0,5.0,6.0]:
		for direction in range(16):
			var point:=_clamp_walkable(hero_pos+Vector2.from_angle(TAU*direction/16.0)*float(radius))
			var distance:=hero_pos.distance_to(point)
			if distance>=best_distance: continue
			var safe:=true
			for enemy in living():
				if not enemy.warning.is_empty() and BossPatterns.threatens(enemy.warning,point,0.35):
					safe=false
					break
			if safe:
				best=point
				best_distance=distance
	return best

func _tick_enemy(enemy: Dictionary) -> void:
	if enemy.has("awakened") and not enemy.awakened and enemy.hp<=enemy.max_hp*0.5:
		enemy.awakened=true
		events.append({"type":"boss_phase","source":enemy.id,"name":enemy.name})
	if not enemy.warning.is_empty():
		enemy.warning.left -= STEP
		if enemy.warning.left<=0:
			var warning: Dictionary = enemy.warning
			if BossPatterns.threatens(warning,hero_pos):
				_hurt_hero(enemy,float(enemy.damage)*float(warning.get("multiplier",2.7 if enemy.role=="boss" else 1.5)))
			else:
				events.append({"type":"miss","source":enemy.id})
			var impact: Dictionary={"type":"impact","source":enemy.id,"position":warning.center,"radius":warning.radius}
			if warning.has("zones"): impact["zones"]=warning.zones.duplicate(true)
			events.append(impact)
			enemy.warning = {}
			enemy.cooldown = 1.5
		return
	enemy.cooldown -= STEP
	enemy.special_cd -= STEP
	var distance := Vector2(enemy.pos).distance_to(hero_pos)
	if enemy.role=="boss" and enemy.special_cd<=0:
		if int(stats.get("boss_patterns",0))==1:
			var pattern_variant:=0
			if uses_procedural_generation():
				var previous_variant:=int(enemy.get("last_pattern_variant",-1))
				pattern_variant=1-previous_variant if previous_variant in [0,1] else rng.randi_range(0,1)
				enemy["last_pattern_variant"]=pattern_variant
			enemy.warning=BossPatterns.create((floor_id-1)/10,enemy.pos,hero_pos,enemy.get("awakened",false),pattern_variant)
			var event: Dictionary=enemy.warning.duplicate(true)
			event.merge({"type":"warning","source":enemy.id,"position":enemy.warning.center,"duration":enemy.warning.total})
			events.append(event)
			enemy.special_cd=5.0 if enemy.get("awakened",false) else 6.8
		else:
			_warn(enemy,2.6,1.4)
			enemy.special_cd = 6.5
		return
	if enemy.role=="hexer":
		if uses_procedural_generation():
			var preferred_range:=float(enemy.preferred_range)
			if distance>preferred_range+0.55:
				enemy.pos=_clamp_walkable(Vector2(enemy.pos).move_toward(hero_pos,STEP*1.15))
			elif distance<preferred_range-0.65:
				var retreat: Vector2=(Vector2(enemy.pos)-hero_pos).normalized()
				if retreat.length()<0.1: retreat=Vector2(1,0)
				var retreat_point:=_clamp_walkable(Vector2(enemy.pos)+retreat*STEP*1.05)
				if retreat_point.distance_to(enemy.pos)>0.01: enemy.pos=retreat_point
				elif enemy.cooldown<=0:
					_warn(enemy,float(enemy.warning_radius),float(enemy.warning_duration))
					enemy.warning["multiplier"]=1.0
			elif enemy.cooldown<=0:
				_warn(enemy,float(enemy.warning_radius),float(enemy.warning_duration))
				enemy.warning["multiplier"]=1.0
		else:
			if distance>5.8: enemy.pos = Vector2(enemy.pos).move_toward(hero_pos,STEP*1.15)
			elif enemy.cooldown<=0: _warn(enemy,1.15,1.0)
		return
	if enemy.role=="elite" and uses_procedural_generation() and enemy.special_cd<=0.0 and distance<=6.2:
		_warn(enemy,1.65,0.95)
		enemy.warning["multiplier"]=1.6
		enemy.special_cd=rng.randf_range(4.8,6.4)
		return
	if distance>1.5:
		var speed := 1.05 if enemy.role in ["bulwark","boss"] else 1.65
		var goal := hero_pos
		if enemy.role=="raider" and uses_procedural_generation():
			var orbit_angle:=float(enemy.flank_phase)+elapsed*float(enemy.flank_direction)*0.72
			goal=hero_pos+Vector2.from_angle(orbit_angle)*float(enemy.flank_radius)
		enemy.pos = _clamp_walkable(Vector2(enemy.pos).move_toward(goal,STEP*speed*(0.45 if enemy.slow>0 else 1.0)))
	elif enemy.cooldown<=0:
		_hurt_hero(enemy,enemy.damage)
		enemy.cooldown = 2.5 if enemy.role=="bulwark" else 1.8

func _warn(enemy: Dictionary, radius: float, seconds: float) -> void:
	enemy.warning = {"center":hero_pos,"radius":radius,"left":seconds,"total":seconds}
	events.append({"type":"warning","source":enemy.id,"position":hero_pos,"radius":radius,"duration":seconds})

func _hurt_hero(enemy: Dictionary, raw: float) -> void:
	var mitigation := float(stats.armor)/(float(stats.armor)+180.0)
	var damage := maxi(1,int(raw*(1.0-mitigation)*(0.55 if guard_time>0 else 1.0))-int(stats.class_mitigation))
	# The optional stat keeps pre-0.8 expedition checkpoints on their old rules.
	# Reserve one ability cast; Spirit now fuels both spellcasting and defense.
	var ward_fraction := float(stats.get("mana_guard",0.0)) if class_key=="Arcanist" else 0.0
	if ward_fraction>0.0:
		var reserve := int(stats.mana_cost)
		var absorbed := mini(floori(damage*ward_fraction),maxi(0,hero_mana-reserve)/2)
		if absorbed>0:
			hero_mana -= absorbed*2
			damage -= absorbed
			events.append({"type":"ward","source":enemy.id,"absorbed":absorbed,"mana_spent":absorbed*2})
	hero_hp = maxi(0,hero_hp-damage)
	events.append({"type":"hero_hit","source":enemy.id,"damage":damage})

func uses_journey() -> bool:
	return int(stats.get("dungeon_journey",0))==1

func uses_tactical_movement() -> bool:
	return uses_journey() and int(stats.get("dungeon_generation",1))>=5

func uses_varied_targeting() -> bool:
	return uses_journey() and int(stats.get("auto_target_variance",0))==1

func uses_procedural_generation() -> bool:
	return int(stats.get("dungeon_generation",1))>=2

func movement_seed() -> int:
	# Current runs share the same 256 route/combat patterns so AFK result caching is exact.
	# Checkpoints without a route version keep their original full-seed route on resume.
	if int(stats.get("route_pattern_version",0)) in [1,2,3,4]:
		return posmod(run_seed,COMBAT_VARIANTS)+1
	return run_seed if int(stats.get("dungeon_generation",1))>=3 else 0

func uses_wandering_routes() -> bool:
	return int(stats.get("route_pattern_version",0))==2

func uses_scouting_routes() -> bool:
	return int(stats.get("route_pattern_version",0))>=3

func uses_expanded_scouting_routes() -> bool:
	return int(stats.get("route_pattern_version",0))>=4

func movement_approach() -> float:
	return 2.1 if class_key=="Vowkeeper" else 4.4

func checkpoint(room: int) -> Vector2:
	return Layout.center(Layout.region(floor_id),room,layout_seed()) if uses_journey() else CHECKPOINTS[room]

func layout_seed() -> int:
	if legacy_layout or not uses_journey(): return 0
	return Layout.procedural_seed(run_seed,floor_id) if uses_procedural_generation() else Layout.variant_seed(run_seed,floor_id)

func _tick_journey() -> void:
	var region_id := Layout.region(floor_id)
	if phase=="travel":
		var points := Layout.travel_points(region_id,stage,movement_approach(),layout_seed(),movement_seed(),uses_wandering_routes(),uses_scouting_routes(),uses_expanded_scouting_routes())
		var leg: int=journey.travel_index
		var goal: Vector2=points[leg]
		hero_pos=hero_pos.move_toward(goal,WALK_SPEED*STEP)
		action="Following the passage to "+Layout.room_name(region_id,stage)
		if hero_pos.distance_to(goal)<0.03:
			journey.travel_index+=1
			if journey.travel_index>=points.size():
				phase="combat"
				phase_clock=0.0
				events.append({"type":"engage","stage":stage})
		return
	if stage in [1,3,5]:
		var destination := Layout.interact_point(region_id,stage,layout_seed())+Vector2(0,1.25)
		if hero_pos.distance_to(destination)>0.05:
			hero_pos=hero_pos.move_toward(destination,WALK_SPEED*STEP)
			action="Approaching the "+({1:"healing well",3:"sanctum seal",5:"guardian's reliquary"}[stage])
			return
		action=Layout.interact_name(stage)
		journey.channel+=STEP
		if journey.channel<1.2: return
		if stage==1 and not journey.well_used:
			journey.well_used=true
			var restored := mini(int(stats.max_hp)-hero_hp,maxi(1,int(stats.max_hp*0.18)))
			hero_hp+=restored
			events.append({"type":"well","position":hero_pos,"restored":restored})
		elif stage==3: journey.seal_broken=true
		elif stage==5: journey.chest_open=true
		events.append({"type":"objective","stage":stage,"position":hero_pos})
	phase="loot"
	phase_clock=0.0

func _clamp_walkable(point: Vector2) -> Vector2:
	if uses_journey(): return Layout.combat_point(Layout.region(floor_id),stage,point,layout_seed())
	var half_width := 2.2 if point.y<-20.0 and point.y>-33.0 else 5.8
	return Vector2(clampf(point.x,-half_width,half_width),clampf(point.y,-67.0,8.0))

func _finish(success: bool) -> void:
	finished = true
	won = success
	phase = "finished"
	pending_attack.clear()
	events.append({"type":"finished","won":won})

const SNAPSHOT_VERSION := 1
const SNAPSHOT_FIELDS := ["class_key","stats","floor_id","run_seed","waves","stage","phase","phase_clock","elapsed","accumulator","hero_pos","hero_hp","hero_mana","target_id","action","attack_cd","skill_cd","dodge_cd","guard_time","pending_attack","dodge_goal","dodging","finished","won","kills","dodges","casts"]

func snapshot() -> Dictionary:
	var state := {"version":SNAPSHOT_VERSION,"rng_state":rng.state,"fields":{}}
	for field in SNAPSHOT_FIELDS:
		var value = get(field)
		state.fields[field] = value.duplicate(true) if value is Dictionary or value is Array else value
	if uses_journey(): state["journey"]=journey.duplicate(true)
	if uses_rotation(): state["rotation"]=rotation.duplicate(true)
	return state

func encode_snapshot() -> String:
	# Binary Variant encoding preserves the exact floating point and RNG state.
	return Marshalls.raw_to_base64(var_to_bytes(snapshot()))

func restore_encoded(encoded: String) -> bool:
	if encoded.length()>512000: return false
	var decoded = bytes_to_var(Marshalls.base64_to_raw(encoded))
	return restore(decoded) if decoded is Dictionary else false

func restore(state: Dictionary) -> bool:
	if state.get("version",0)!=SNAPSHOT_VERSION or not state.get("rng_state") is int: return false
	var data = state.get("fields")
	if not data is Dictionary: return false
	for field in SNAPSHOT_FIELDS:
		if not data.has(field) or typeof(data[field])!=typeof(get(field)): return false
		if data[field] is float and not is_finite(data[field]): return false
	if not ABILITIES.has(data.class_key) or data.floor_id<1 or data.floor_id>100000: return false
	if data.stage<0 or data.stage>6 or data.elapsed<0 or data.elapsed>MAX_DURATION+STEP*2: return false
	if not data.phase in ["travel","combat","interact","loot","finished"]: return false
	if data.stats.has("dungeon_journey") and (not data.stats.dungeon_journey is int or not data.stats.dungeon_journey in [0,1]): return false
	if data.stats.has("expedition_contract") and not Contract.valid(data.stats.expedition_contract,data.floor_id): return false
	if data.stats.has("expedition_contract") and Contract.mode(data.stats.expedition_contract)=="trial" and data.elapsed>Contract.TRIAL_LIMIT+STEP*2: return false
	var new_journey: bool = data.stats.get("dungeon_journey",0)==1
	if data.elapsed>(MAX_DURATION if new_journey else LEGACY_MAX_DURATION)+STEP*2: return false
	if data.phase=="interact" and not new_journey: return false
	if new_journey:
		var saved_journey=state.get("journey")
		if not saved_journey is Dictionary: return false
		var route_version:=int(data.stats.get("route_pattern_version",0))
		var travel_index_limit:=1 if data.stage==0 else 9 if route_version>=3 else 6 if route_version==2 else 4
		if route_version>=3:
			var route_layout_seed:=Layout.procedural_seed(data.run_seed,data.floor_id) if int(data.stats.get("dungeon_generation",1))>=2 else Layout.variant_seed(data.run_seed,data.floor_id)
			var route_movement_seed:=posmod(data.run_seed,COMBAT_VARIANTS)+1
			var route_approach:=2.1 if data.class_key=="Vowkeeper" else 4.4
			travel_index_limit=Layout.travel_points(Layout.region(data.floor_id),data.stage,route_approach,route_layout_seed,route_movement_seed,false,true,route_version>=4).size()
		if not saved_journey.get("travel_index") is int or saved_journey.travel_index<0 or saved_journey.travel_index>travel_index_limit: return false
		if data.phase=="travel" and saved_journey.travel_index>=travel_index_limit: return false
		if not saved_journey.get("channel") is float or not is_finite(saved_journey.channel) or saved_journey.channel<0.0 or saved_journey.channel>1.31: return false
		for flag in ["well_used","seal_broken","chest_open"]:
			if not saved_journey.get(flag) is bool: return false
		if int(data.stats.get("dungeon_generation",1))>=5:
			var movement: Variant=saved_journey.get("combat_movement")
			if not movement is Dictionary: return false
			if not movement.get("target") is int or movement.target< -1 or movement.target>=60: return false
			if not _valid_number(movement.get("wait")) or movement.wait<0.0 or movement.wait>2.0: return false
			if not _valid_number(movement.get("remaining")) or movement.remaining<0.0 or movement.remaining>0.6: return false
			if not _valid_point(movement.get("goal")): return false
		if data.stage>=4 and not saved_journey.seal_broken: return false
		if data.won and not saved_journey.chest_open: return false
	if data.finished!=(data.phase=="finished") or (data.stage==6 and not data.finished): return false
	if data.won and (not data.finished or data.stage!=6): return false
	if data.accumulator < -0.0001 or (not data.finished and data.accumulator>STEP+0.0001): return false
	if not _valid_point(data.hero_pos) or not _valid_point(data.dodge_goal): return false
	for stat in ["max_hp","max_mana","attack","ability_damage","mana_cost","crit","armor","class_mitigation"]:
		if not _valid_number(data.stats.get(stat)): return false
	if data.stats.max_hp<1 or data.stats.max_mana<0 or data.stats.mana_cost<0: return false
	if data.stats.has("mana_guard"):
		if not _valid_number(data.stats.mana_guard) or data.stats.mana_guard<0.0 or data.stats.mana_guard>0.5: return false
	if data.stats.has("boss_patterns") and (not data.stats.boss_patterns is int or not data.stats.boss_patterns in [0,1]): return false
	if data.stats.has("arcane_tactics") and (not data.stats.arcane_tactics is int or not data.stats.arcane_tactics in [0,1]): return false
	if data.stats.has("dungeon_generation") and (not data.stats.dungeon_generation is int or not data.stats.dungeon_generation in [1,2,3,4,5,6]): return false
	if data.stats.has("route_pattern_version") and (not data.stats.route_pattern_version is int or data.stats.route_pattern_version not in [1,2,3,4]): return false
	if data.stats.has("auto_target_variance") and (not data.stats.auto_target_variance is int or data.stats.auto_target_variance not in [0,1]): return false
	if not data.stats.get("attributes") is Dictionary or not _valid_number(data.stats.attributes.get("Spirit")): return false
	if data.hero_hp<0 or data.hero_hp>data.stats.max_hp or data.hero_mana<0 or data.hero_mana>data.stats.max_mana: return false
	var saved_legacy_layout := _snapshot_uses_legacy_layout(data) if new_journey else true
	var expected_packs: Array=PACKS
	if new_journey:
		var expected_seed := Layout.variant_seed(data.run_seed,data.floor_id)
		if int(data.stats.get("dungeon_generation",1))>=2: expected_seed=Layout.procedural_seed(data.run_seed,data.floor_id)
		expected_packs=Layout.PACKS if saved_legacy_layout else Layout.packs(Layout.region(data.floor_id),expected_seed)
		if int(data.stats.get("dungeon_generation",1))>=5:
			var saved_movement: Dictionary=state.journey.combat_movement
			if saved_movement.target>=0 and not _valid_enemy_id(saved_movement.target,expected_packs): return false
	var has_rotation: bool=data.stats.get("skill_rotation",0) is int and data.stats.get("skill_rotation",0)==1
	if data.stats.has("skill_rotation") and (not data.stats.skill_rotation is int or not data.stats.skill_rotation in [0,1]): return false
	if has_rotation:
		if not Skills.valid(data.class_key,data.stats.get("skill_loadout")): return false
		var saved_rotation=state.get("rotation")
		if not saved_rotation is Dictionary or not saved_rotation.get("cooldowns") is Dictionary or not saved_rotation.get("uses") is Dictionary: return false
		if saved_rotation.cooldowns.size()!=2 or saved_rotation.uses.size()!=2: return false
		for key in data.stats.skill_loadout:
			var cd=saved_rotation.cooldowns.get(key)
			var used=saved_rotation.uses.get(key)
			if not cd is float or not is_finite(cd) or cd<0.0 or cd>Skills.DEFINITIONS[key].cooldown: return false
			if not used is int or used<0 or used>1000: return false
	if data.waves.size()!=6: return false
	var reinforcement_count:=0
	var reinforcement_rooms: Dictionary={}
	for wave_index in range(6):
		if not data.waves[wave_index] is Array or data.waves[wave_index].size()!=expected_packs[wave_index].size(): return false
		for slot in range(data.waves[wave_index].size()):
			var enemy = data.waves[wave_index][slot]
			if not enemy is Dictionary: return false
			if enemy.get("id")!=wave_index*10+slot or enemy.get("role")!=expected_packs[wave_index][slot]: return false
			if not enemy.get("name") is String or not _valid_point(enemy.get("pos")) or not _valid_point(enemy.get("spawn")): return false
			for stat in ["hp","max_hp","cooldown","special_cd","slow","damage"]:
				if not _valid_number(enemy.get(stat)): return false
			if enemy.max_hp<1 or enemy.hp<0 or enemy.hp>enemy.max_hp: return false
			if enemy.has("awakened") and (enemy.role!="boss" or not enemy.awakened is bool): return false
			if enemy.has("last_pattern_variant") and (not enemy.last_pattern_variant is int or enemy.last_pattern_variant not in [-1,0,1]): return false
			for ai_field in ["flank_phase","flank_direction","flank_radius","preferred_range","warning_radius","warning_duration"]:
				if enemy.has(ai_field) and not _valid_number(enemy[ai_field]): return false
			if enemy.has("flank_direction") and absf(enemy.flank_direction)!=1.0: return false
			if enemy.has("flank_radius") and (enemy.flank_radius<0.2 or enemy.flank_radius>1.2): return false
			if enemy.has("preferred_range") and (enemy.preferred_range<3.0 or enemy.preferred_range>7.0): return false
			if enemy.has("warning_radius") and (enemy.warning_radius<0.7 or enemy.warning_radius>1.8): return false
			if enemy.has("warning_duration") and (enemy.warning_duration<0.6 or enemy.warning_duration>1.5): return false
			if int(data.stats.get("dungeon_generation",1))>=4 and (enemy.has("spawned") or enemy.has("spawn_delay")):
				if not enemy.has("spawned") or not enemy.has("spawn_delay"): return false
				if not enemy.spawned is bool or not _valid_number(enemy.spawn_delay) or enemy.role not in ["raider","hexer"]: return false
				if enemy.spawn_delay<0.0 or enemy.spawn_delay>7.8: return false
				if enemy.spawned and enemy.spawn_delay>0.0001: return false
				if not enemy.spawned and enemy.spawn_delay<=0.0: return false
				reinforcement_count+=1
				reinforcement_rooms[wave_index]=int(reinforcement_rooms.get(wave_index,0))+1
			if int(data.stats.get("dungeon_generation",1))>=2:
				if enemy.role=="raider" and not (enemy.has("flank_phase") and enemy.has("flank_direction") and enemy.has("flank_radius")): return false
				if enemy.role=="hexer" and not (enemy.has("preferred_range") and enemy.has("warning_radius") and enemy.has("warning_duration")): return false
			var warning = enemy.get("warning")
			if not warning is Dictionary: return false
			if not warning.is_empty():
				if not _valid_point(warning.get("center")): return false
				for stat in ["left","total","radius"]:
					if not _valid_number(warning.get(stat)) or warning[stat]<0: return false
				if warning.has("multiplier") and (not _valid_number(warning.multiplier) or warning.multiplier<0.5 or warning.multiplier>3.0): return false
				if warning.has("zones") and (enemy.role!="boss" or not BossPatterns.valid(warning)): return false
	if int(data.stats.get("dungeon_generation",1))>=4:
		if reinforcement_count!=2: return false
		for room_count in reinforcement_rooms.values():
			if room_count!=1: return false
	if data.target_id!=-1 and not _valid_enemy_id(data.target_id,expected_packs): return false
	if not data.pending_attack.is_empty():
		var attack: Dictionary = data.pending_attack
		if not _valid_enemy_id(attack.get("target"),expected_packs) or not attack.get("skill") is bool or not attack.get("name") is String or not _valid_number(attack.get("left")): return false
	if not data.pending_attack.is_empty() and data.pending_attack.has("ability_id"):
		var attack: Dictionary=data.pending_attack
		if not has_rotation or not attack.ability_id is String or not attack.ability_id in data.stats.skill_loadout: return false
		if not attack.skill or attack.name!=Skills.DEFINITIONS[attack.ability_id].name: return false
		if not _valid_point(attack.get("center")) or attack.left<0.0 or attack.left>Skills.DEFINITIONS[attack.ability_id].cast: return false
	for field in SNAPSHOT_FIELDS:
		var value = data[field]
		set(field,value.duplicate(true) if value is Dictionary or value is Array else value)
	legacy_layout=saved_legacy_layout
	journey=state.journey.duplicate(true) if new_journey else {}
	rotation=state.rotation.duplicate(true) if has_rotation else {}
	rng.state = state.rng_state
	events = []
	return true

func _valid_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func _valid_point(value: Variant) -> bool:
	return value is Vector2 and is_finite(value.x) and is_finite(value.y) and absf(value.x)<=20.0 and value.y>=-80.0 and value.y<=20.0

func _valid_enemy_id(value: Variant, packs: Array=PACKS) -> bool:
	return value is int and value>=0 and value/10<6 and value%10<packs[value/10].size()

func _snapshot_uses_legacy_layout(data: Dictionary) -> bool:
	if int(data.stats.get("dungeon_generation",1))>=2: return false
	var saved_waves=data.get("waves")
	if not saved_waves is Array or saved_waves.size()!=6: return false
	var region_id:=Layout.region(int(data.floor_id))
	var offsets := [Vector2(-1.2,0.3),Vector2(0,-1.1),Vector2(1.2,0.4),Vector2(-2.4,-1.5),Vector2(2.4,-1.4)]
	for room in range(6):
		if not saved_waves[room] is Array or saved_waves[room].size()!=Layout.PACKS[room].size(): return false
		for slot in range(saved_waves[room].size()):
			var enemy=saved_waves[room][slot]
			if not enemy is Dictionary or enemy.get("role")!=Layout.PACKS[room][slot]: return false
			var spawn=enemy.get("spawn")
			if not spawn is Vector2: return false
			var expected: Vector2=Layout.center(region_id,room)+offsets[slot]
			if enemy.role=="boss": expected=Layout.center(region_id,room)
			if enemy.role=="hexer": expected.y-=1.0
			if Vector2(spawn).distance_to(expected)>0.001: return false
	return true

func uses_rotation() -> bool:
	return int(stats.get("skill_rotation",0))==1

func _try_technique(target: Dictionary, protection: bool) -> bool:
	var candidates: Array[String]=[]
	for key in stats.skill_loadout:
		var definition: Dictionary=Skills.DEFINITIONS[key]
		if (definition.kind=="guard")!=protection or rotation.cooldowns[key]>0.0 or hero_mana<int(definition.cost): continue
		if protection:
			if guard_time>0.5: continue
			var threatened:=hero_hp<float(stats.max_hp)*0.7
			for enemy in living():
				if not enemy.warning.is_empty() and BossPatterns.threatens(enemy.warning,hero_pos,0.2): threatened=true
			if not threatened: continue
		else:
			var special: bool=target.role in ["elite","boss"]
			if definition.kind=="single":
				if key=="marked": special=special or target.role in ["hexer","bulwark"]
				if not special and target.hp>float(target.max_hp)*0.4: continue
			else:
				var nearby:=0
				var origin: Vector2=hero_pos if key=="sunder" else target.pos
				for enemy in living():
					if Vector2(enemy.pos).distance_to(origin)<=float(definition.radius): nearby+=1
				if nearby<2 and not special: continue
		candidates.append(key)
	if candidates.is_empty(): return false
	# Keep protection decisive, but let equally valid offensive techniques vary
	# from encounter to encounter. The expedition seed makes this replayable.
	var key: String=candidates[0] if protection or candidates.size()==1 else candidates[rng.randi_range(0,candidates.size()-1)]
	var definition: Dictionary=Skills.DEFINITIONS[key]
	pending_attack={"target":target.id,"skill":true,"left":float(definition.cast),"name":definition.name,"ability_id":key,"center":hero_pos if key=="sunder" else Vector2(target.pos)}
	hero_mana-=int(definition.cost)
	rotation.cooldowns[key]=float(definition.cooldown)
	rotation.uses[key]+=1
	casts+=1
	attack_cd=maxf(1.05 if class_key=="Ranger" else 1.3,float(definition.cast)+0.15)
	action="Casting "+String(definition.name)
	events.append({"type":"technique_cast","ability_id":key,"position":pending_attack.center,"duration":definition.cast,"radius":definition.radius})
	events.append({"type":"hero_attack","target":target.id,"skill":true,"name":definition.name,"ability_id":key})
	return true

func _resolve_technique(attack: Dictionary) -> void:
	var key: String=attack.ability_id
	var definition: Dictionary=Skills.DEFINITIONS[key]
	var target := enemy_by_id(attack.target)
	var origin: Vector2=attack.center
	var selected: Array=[]
	if definition.kind=="guard":
		guard_time=maxf(guard_time,float(definition.guard))
		origin=hero_pos
		if key=="frost_ward":
			for enemy in living():
				if hero_pos.distance_to(enemy.pos)<=3.0: enemy.slow=maxf(enemy.slow,4.0)
		if key=="smoke":
			var away := (hero_pos-Vector2(target.get("pos",hero_pos+Vector2(0,-1)))).normalized()
			var goal := _clamp_walkable(hero_pos+away*2.4)
			var safe:=goal.distance_to(hero_pos)>0.3
			for enemy in living():
				if not enemy.warning.is_empty() and BossPatterns.threatens(enemy.warning,goal,0.2): safe=false
			if safe:
				dodge_goal=goal
				dodging=true
	elif definition.kind=="area":
		if key=="sunder": origin=hero_pos
		for enemy in living():
			if Vector2(enemy.pos).distance_to(origin)<=float(definition.radius): selected.append(enemy)
	elif not target.is_empty() and target.hp>0:
		selected.append(target)
		origin=target.pos
		if definition.kind=="chain":
			var from: Vector2=target.pos
			for jump in range(2):
				var next: Dictionary={}
				var nearest: float=definition.radius+0.00001
				for enemy in living():
					if selected.has(enemy): continue
					var distance:=from.distance_to(enemy.pos)
					if distance<nearest: nearest=distance; next=enemy
				if next.is_empty(): break
				selected.append(next)
				from=next.pos
	var points: Array=[hero_pos]
	for enemy in selected:
		points.append(Vector2(enemy.pos))
		var amount := float(Skills.damage(key,stats))
		var critical:=rng.randf()*100.0<float(stats.crit)
		if critical: amount*=2.15 if class_key=="Ranger" else 1.7
		if key!="marked" and enemy.role in ["bulwark","elite"] and class_key!="Arcanist": amount*=0.72
		var damage:=mini(enemy.hp,maxi(1,int(amount)))
		enemy.hp-=damage
		if key=="rain": enemy.slow=maxf(enemy.slow,1.7)
		events.append({"type":"hit","target":enemy.id,"damage":damage,"critical":critical,"skill":true,"name":definition.name,"dead":enemy.hp<=0})
		if enemy.hp<=0:
			kills+=1
			enemy.warning={}
	# Same on-hit Spirit recovery as a normal attack, once per technique.
	if not selected.is_empty(): hero_mana=mini(int(stats.max_mana),hero_mana+maxi(1,int(stats.attributes.Spirit)/4))
	events.append({"type":"technique","ability_id":key,"position":origin,"radius":definition.radius,"points":points})

func contract() -> Dictionary:
	return stats.get("expedition_contract",{})

func duration_limit() -> float:
	if Contract.mode(contract())=="trial": return Contract.TRIAL_LIMIT
	return MAX_DURATION if uses_journey() else LEGACY_MAX_DURATION
