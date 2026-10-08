extends RefCounted
## Optional version-two mechanics. Original contracts never enter this module's rules.
const Contract=preload("res://scripts/expedition_contract.gd")

static func enabled(stats: Dictionary) -> bool:
	var rules: Dictionary=stats.get("expedition_contract",{})
	return stats.get("oath_rules",0)==1 and rules.get("version")==2 and Contract.valid(rules,1)

static func active(stats: Dictionary, key: String) -> bool:
	return enabled(stats) and Contract.has_oath(stats.expedition_contract,key)

static func cast_cost(stats: Dictionary, base: int, technique: bool=false) -> int:
	if not active(stats,"hollow"): return base
	var scale:=1.35
	if technique and stats.get("regional_set",-1)==1: scale*=0.8
	return maxi(1,ceili(float(base)*scale)) if base>0 else 0

static func cooldown_scale(stats: Dictionary, technique: bool=false) -> float:
	if not active(stats,"hollow"): return 1.0
	return 0.8*(0.85 if technique and stats.get("regional_set",-1)==3 else 1.0)

static func outgoing_scale(stats: Dictionary, guard: float, skill: bool) -> float:
	var scale:=1.15 if active(stats,"unmended") and guard>0.0 else 1.0
	if skill and active(stats,"cinder"): scale*=1.15
	return scale

static func relic_scale(stats: Dictionary) -> float:
	return 1.25 if active(stats,"cinder") else 1.0

static func charge_scale(stats: Dictionary) -> float:
	return 1.25 if active(stats,"unmended") else 1.0

static func signature_crit(stats: Dictionary) -> float:
	return 4.0 if active(stats,"cinder") and stats.get("regional_set",-1)==2 else 0.0
