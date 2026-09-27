extends RefCounted
## Single deterministic authority for watched, skipped and offline expeditions.
## All combat and movement use fixed 100 ms steps; rendering never rolls damage.
const STEP := 0.1
const WALK_SPEED := 2.55
const MAX_DURATION := 180.0
const COMBAT_VARIANTS := 64
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

func setup(selected_class: String, combat_stats: Dictionary, target_floor: int, boss_name: String, seed_value: int) -> void:
	class_key = selected_class
	stats = combat_stats.duplicate(true)
	floor_id = maxi(1,target_floor)
	run_seed = seed_value
	rng.seed = posmod(run_seed,COMBAT_VARIANTS)+floor_id*4099
	hero_hp = int(stats.max_hp)
	hero_mana = int(stats.max_mana)
	var scaling := 1.0+float(floor_id-1)*0.13+pow(maxf(floor_id-8,0.0),1.35)*0.035
	var offsets := [Vector2(-1.2,0.3),Vector2(0,-1.1),Vector2(1.2,0.4)]
	for room in range(PACKS.size()):
		var pack: Array = []
		for slot in range(PACKS[room].size()):
			var role: String = PACKS[room][slot]
			var hp := int(float({"raider":300,"bulwark":520,"hexer":260,"elite":850,"boss":2400}[role])*scaling)
			var point: Vector2 = CHECKPOINTS[room]+offsets[slot]
			if role == "boss": point = CHECKPOINTS[room]
			if role == "hexer": point.y -= 1.0
			pack.append({"id":room*10+slot,"role":role,"name":boss_name if role=="boss" else ROLE_NAMES[role],"hp":hp,"max_hp":hp,"pos":point,"spawn":point,"cooldown":0.7+slot*0.35,"special_cd":2.5,"slow":0.0,"warning":{},"damage":(10.0+floor_id*2.2)*(1.6 if role in ["elite","boss"] else 1.0)})
		waves.append(pack)

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
		if enemy.hp>0: result.append(enemy)
	return result

func enemy_by_id(id_value: int) -> Dictionary:
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
	if elapsed >= MAX_DURATION:
		_finish(false)
		return
	if phase == "travel":
		var approach := 2.1 if class_key=="Vowkeeper" else 4.4
		var goal: Vector2 = CHECKPOINTS[stage]+Vector2(0,approach)
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
			if stage >= waves.size():
				_finish(true)
			else:
				phase = "travel"
				phase_clock = 0.0
		return
	if phase != "combat": return
	var targets := living()
	if targets.is_empty():
		phase = "loot"
		phase_clock = 0.0
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

func _choose_target() -> Dictionary:
	var best: Dictionary = {}
	var best_score := -INF
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
		if score>best_score:
			best = enemy
			best_score = score
	return best

func _auto_hero() -> void:
	# React to committed ground attacks, not to future random results.
	if dodge_cd<=0.0 and not dodging:
		for enemy in living():
			if enemy.warning.is_empty(): continue
			var warning: Dictionary = enemy.warning
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
		hero_pos = _clamp_walkable(hero_pos.move_toward(target.pos,WALK_SPEED*STEP))
		action = "Closing on " + String(target.name)
		return
	if attack_cd>0:
		action = "Holding the front line" if class_key=="Vowkeeper" else "Keeping firing distance"
		return
	var use_skill := skill_cd<=0 and hero_mana>=int(stats.mana_cost)
	var nearby := 0
	for enemy in living():
		if Vector2(enemy.pos).distance_to(hero_pos if class_key=="Vowkeeper" else target.pos)<=3.2: nearby += 1
	if class_key=="Vowkeeper": use_skill = use_skill and (nearby>=2 or hero_hp<int(stats.max_hp)*0.75 or target.role in ["boss","elite"])
	elif class_key=="Arcanist": use_skill = use_skill and (nearby>=2 or target.role in ["boss","elite"])
	elif class_key=="Ranger": use_skill = use_skill and (target.role in ["hexer","elite","boss"] or living().size()>=2)
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

func _resolve_hero_attack() -> void:
	var attack := pending_attack.duplicate()
	pending_attack.clear()
	var target := enemy_by_id(attack.target)
	if target.is_empty() or target.hp<=0: return
	var selected: Array = [target]
	if attack.skill:
		selected.clear()
		for enemy in living():
			var origin: Vector2 = hero_pos if class_key=="Vowkeeper" else target.pos
			var radius := 2.9 if class_key=="Vowkeeper" else 3.2
			if class_key=="Ranger":
				origin = hero_pos
				radius = 6.0
			if Vector2(enemy.pos).distance_to(origin)<=radius: selected.append(enemy)
		if not selected.has(target): selected.append(target)
		if class_key=="Vowkeeper":
			guard_time = 2.8
			var healed := mini(int(stats.max_hp)-hero_hp,int(float(stats.max_hp)*0.08))
			hero_hp += healed
			events.append({"type":"guard","heal":healed})
		elif class_key=="Arcanist":
			hero_mana = mini(int(stats.max_mana),hero_mana+int(stats.mana_cost)/4)
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

func _tick_enemy(enemy: Dictionary) -> void:
	if not enemy.warning.is_empty():
		enemy.warning.left -= STEP
		if enemy.warning.left<=0:
			var warning: Dictionary = enemy.warning
			if hero_pos.distance_to(warning.center)<=warning.radius:
				_hurt_hero(enemy,float(enemy.damage)*(2.7 if enemy.role=="boss" else 1.5))
			else:
				events.append({"type":"miss","source":enemy.id})
			events.append({"type":"impact","source":enemy.id,"position":warning.center,"radius":warning.radius})
			enemy.warning = {}
			enemy.cooldown = 1.5
		return
	enemy.cooldown -= STEP
	enemy.special_cd -= STEP
	var distance := Vector2(enemy.pos).distance_to(hero_pos)
	if enemy.role=="boss" and enemy.special_cd<=0:
		_warn(enemy,2.6,1.4)
		enemy.special_cd = 6.5
		return
	if enemy.role=="hexer":
		if distance>5.8: enemy.pos = Vector2(enemy.pos).move_toward(hero_pos,STEP*1.15)
		elif enemy.cooldown<=0:
			_warn(enemy,1.15,1.0)
		return
	if distance>1.5:
		var speed := 1.05 if enemy.role in ["bulwark","boss"] else 1.65
		enemy.pos = _clamp_walkable(Vector2(enemy.pos).move_toward(hero_pos,STEP*speed*(0.45 if enemy.slow>0 else 1.0)))
	elif enemy.cooldown<=0:
		_hurt_hero(enemy,enemy.damage)
		enemy.cooldown = 2.5 if enemy.role=="bulwark" else 1.8

func _warn(enemy: Dictionary, radius: float, seconds: float) -> void:
	enemy.warning = {"center":hero_pos,"radius":radius,"left":seconds,"total":seconds}
	events.append({"type":"warning","source":enemy.id,"position":hero_pos,"radius":radius,"duration":seconds})

func _hurt_hero(enemy: Dictionary, raw: float) -> void:
	var mitigation := float(stats.armor)/(float(stats.armor)+180.0)
	var damage := maxi(1,int(raw*(1.0-mitigation)*(0.55 if guard_time>0 else 1.0))-int(stats.class_mitigation))
	hero_hp = maxi(0,hero_hp-damage)
	events.append({"type":"hero_hit","source":enemy.id,"damage":damage})

func _clamp_walkable(point: Vector2) -> Vector2:
	var half_width := 2.2 if point.y<-20.0 and point.y>-33.0 else 5.8
	return Vector2(clampf(point.x,-half_width,half_width),clampf(point.y,-67.0,8.0))

func _finish(success: bool) -> void:
	finished = true
	won = success
	phase = "finished"
	pending_attack.clear()
	events.append({"type":"finished","won":won})
