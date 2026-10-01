extends SceneTree

const Sim = preload("res://scripts/expedition_simulation.gd")
const Layout = preload("res://scripts/dungeon_layout.gd")
const Bot = preload("res://tests/balance_survey_bot.gd")

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(value: bool, description: String) -> void:
	checks += 1
	if value:
		print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)

func prepare_maneuver(sim: RefCounted) -> Dictionary:
	sim.stage = 0
	sim.phase = "combat"
	var center: Vector2 = Layout.center(Layout.region(sim.floor_id),0,sim.layout_seed())
	sim.hero_pos = center + Vector2(-1.2 if sim.class_key == "Vowkeeper" else -4.0,0)
	var target: Dictionary = sim.waves[0][0]
	for enemy in sim.waves[0]:
		enemy.hp = 0
		enemy.warning = {}
		enemy.pos = center + Vector2(4.5,3.5)
	target.hp = target.max_hp
	target.pos = center
	sim.target_id = target.id
	sim.attack_cd = 1.3
	sim.journey["combat_movement"] = {"target":target.id,"wait":0.0,"remaining":0.0,"goal":sim.hero_pos}
	return target

func run_checks() -> void:
	var bot: Node = Bot.new()
	var varied_directions := {"Vowkeeper":{},"Arcanist":{},"Ranger":{}}
	var walkable := true
	var class_ranges := true
	var deterministic := true
	var movement_restores := true
	for selected in ["Vowkeeper","Arcanist","Ranger"]:
		bot.character_class = selected
		var stats: Dictionary = bot._combat_stats()
		for serial in range(24):
			var seed_value := 1979 + serial * 104729
			var sim := Sim.new()
			sim.setup(selected,stats,1,"Movement guardian",seed_value)
			var target := prepare_maneuver(sim)
			var origin: Vector2 = sim.hero_pos
			var moved: bool = sim._tick_combat_movement(target,true)
			if not moved:
				class_ranges = false
				continue
			var movement_state: Dictionary = sim.journey.combat_movement.duplicate(true)
			var movement_rng: int = sim.rng.state
			var direction: Vector2 = (sim.hero_pos-origin).normalized().snapped(Vector2(0.1,0.1))
			varied_directions[selected][str(direction)] = true
			var resumed := Sim.new()
			if not resumed.restore_encoded(sim.encode_snapshot()):
				movement_restores = false
			else:
				for step in range(8):
					if float(sim.journey.combat_movement.remaining) > 0.0:
						sim._tick_combat_movement(sim.enemy_by_id(target.id),true)
					if float(resumed.journey.combat_movement.remaining) > 0.0:
						resumed._tick_combat_movement(resumed.enemy_by_id(target.id),true)
				if sim.snapshot() != resumed.snapshot():
					movement_restores = false
			var replay := Sim.new()
			replay.setup(selected,stats,1,"Movement guardian",seed_value)
			var replay_target := prepare_maneuver(replay)
			var replay_moved: bool = replay._tick_combat_movement(replay_target,true)
			if replay_moved != moved or replay.hero_pos != origin.move_toward(sim.journey.combat_movement.goal,2.55*1.2*Sim.STEP) or replay.journey.combat_movement != movement_state or replay.rng.state != movement_rng:
				deterministic = false
			var steps := 0
			while float(sim.journey.combat_movement.remaining) > 0.0 and steps < 64:
				sim._tick_combat_movement(sim.enemy_by_id(target.id),true)
				var point: Vector2 = sim.hero_pos
				var radius: float = point.distance_to(target.pos)
				if not Layout.contains(Layout.region(sim.floor_id),point,sim.layout_seed(),sim.movement_seed(),sim.uses_wandering_routes(),sim.uses_scouting_routes()):
					walkable = false
				if selected == "Vowkeeper" and (radius < 0.85 or radius > 1.65):
					class_ranges = false
				if selected != "Vowkeeper" and (radius < 2.8 or radius > 5.05):
					class_ranges = false
				steps += 1
			if float(sim.journey.combat_movement.remaining) > 0.0:
				walkable = false
			sim = null
			resumed = null
			replay = null
	check(varied_directions.Vowkeeper.size() >= 12,"Vowkeeper takes seed-varied steps while staying in melee range")
	check(varied_directions.Arcanist.size() >= 12,"Arcanist shifts firing positions across run seeds")
	check(varied_directions.Ranger.size() >= 12,"Ranger shifts firing positions across run seeds")
	check(walkable,"every step in the reposition path stays inside the chamber")
	check(class_ranges,"repositioning preserves melee and ranged attack distances")
	check(deterministic,"the same class and run seed reproduce the same step and RNG state")
	check(movement_restores,"saved movement resumes with the same destination and combat state")
	var attacks_fire := true
	for selected in ["Vowkeeper","Arcanist","Ranger"]:
		bot.character_class = selected
		var sim := Sim.new()
		sim.setup(selected,bot._combat_stats(),1,"Movement guardian",1979)
		prepare_maneuver(sim)
		sim.hero_mana = 0
		sim.attack_cd = 0.0
		sim.journey.combat_movement.remaining = 0.4
		sim.journey.combat_movement.goal = sim.hero_pos + Vector2(0.3,0)
		var before: Vector2 = sim.hero_pos
		sim._auto_hero()
		if sim.pending_attack.is_empty() or sim.hero_pos != before or not is_equal_approx(float(sim.journey.combat_movement.remaining),0.4):
			attacks_fire = false
	check(attacks_fire,"a ready basic attack fires without waiting for a pending reposition")
	bot.free()
	print("COMBAT MOVEMENT SMOKE: ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
