extends RefCounted
## Read-only presentation of the frozen expedition, including older checkpoints.
const Skills = preload("res://scripts/class_skills.gd")
const Oaths = preload("res://scripts/oath_combat_rules.gd")
const SIGNATURES := {
	"Vowkeeper": {"short":"EMBER OATH", "color":"d2ad70", "cooldown":5.5},
	"Arcanist": {"short":"VEIL NOVA", "color":"a58ed4", "cooldown":6.0},
	"Ranger": {"short":"CINDER VOLLEY", "color":"83b596", "cooldown":4.5}
}

static func skills(simulation: RefCounted) -> Array[Dictionary]:
	var signature: Dictionary = SIGNATURES[simulation.class_key]
	var duration: float = signature.cooldown * Oaths.cooldown_scale(simulation.stats)
	if simulation.stats.get("regional_set", -1) == 3: duration *= 0.85
	var pending: Dictionary = simulation.pending_attack
	var signature_cast: bool = pending.get("skill", false) and not pending.has("ability_id")
	var result: Array[Dictionary] = [_skill("signature", signature.short, Color(signature.color), simulation.skill_cd, duration, simulation.signature_cost(), simulation.hero_mana, signature_cast)]
	if simulation.uses_rotation():
		for key in simulation.stats.skill_loadout:
			var definition: Dictionary = Skills.DEFINITIONS[key]
			var cooldown: float = simulation.rotation.cooldowns.get(key, 0.0)
			result.append(_skill(key, definition.short, Color(definition.color), cooldown, float(definition.cooldown) * Oaths.cooldown_scale(simulation.stats, true), simulation.technique_cost(key), simulation.hero_mana, pending.get("ability_id", "") == key))
	return result

static func _skill(key: String, title: String, color: Color, remaining: float, duration: float, cost: int, mana: int, casting: bool) -> Dictionary:
	var state := "casting" if casting else "cooldown" if remaining > 0.0 else "mana" if mana < cost else "ready"
	var status := "CASTING" if casting else "%.1fs" % maxf(0.1, remaining) if remaining > 0.0 else "LOW MANA" if mana < cost else "READY"
	return {"key":key, "title":title, "color":color, "state":state, "status":status, "cost":cost, "remaining":remaining, "progress":clampf(1.0 - remaining / maxf(0.1, duration), 0.0, 1.0)}

static func route(simulation: RefCounted) -> Dictionary:
	var total: int = simulation.waves.size()
	var completed: int = clampi(simulation.stage, 0, total)
	var label := "CHAMBER %d / %d" % [mini(completed + 1, total), total]
	var objective := "Follow the passage"
	if simulation.phase == "combat":
		var remaining := 0
		for enemy in simulation.waves[mini(completed, total - 1)]:
			if enemy.hp > 0: remaining += 1
		objective = "1 foe remains" if remaining == 1 else "%d foes remain" % remaining
	elif simulation.uses_journey():
		objective = simulation.Layout.objective(mini(completed, total - 1))
		if simulation.journey.get("chest_open", false):
			objective = "Reliquary recovered"
			completed = total
		elif simulation.stage == total - 1 and simulation.living().is_empty(): objective = "Recover the reliquary"
		elif simulation.phase == "travel": objective = "Follow the passage"
	if simulation.finished and simulation.won: completed = total
	return {"label":label, "objective":objective, "completed":completed, "total":total}

static func protection(simulation: RefCounted) -> String:
	var parts: PackedStringArray = []
	if simulation.guard_time > 0.0: parts.append("GUARD %.1fs" % maxf(0.1, simulation.guard_time))
	if simulation.class_key == "Arcanist" and float(simulation.stats.get("mana_guard", 0.0)) > 0.0:
		parts.append("WARD" if simulation.hero_mana - simulation.signature_cost() >= 2 else "WARD RESERVE")
	return " · ".join(parts)
