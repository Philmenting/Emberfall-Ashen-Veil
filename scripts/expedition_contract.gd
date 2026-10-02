extends RefCounted
## Frozen expedition rules carried by the simulation checkpoint.
const SLOTS := ["Weapon","Helmet","Chest","Gloves","Boots","Amulet"]
const TRIAL_LIMIT := 150.0
const MAX_TRIAL := 30
const OATHS := {
	"unmended":{"name":"Oath of the Unmended","rule":"No healing from Ember Oath or the well. Victory grants 30% more Gold and XP, plus one extra Rare-or-better drop.","short":"No healing • +30% Gold / XP • +1 relic"},
	"cinder":{"name":"Oath of Cinders","rule":"Enemies deal 25% more damage. Victory guarantees one Epic-or-better Amulet carrying your class effect.","short":"Enemies +25% damage • Epic class Amulet"}
}

static func oath(key: String) -> Dictionary:
	return {"version":1,"mode":"oath","oath":key} if OATHS.has(key) else {}

static func no_healing(value: Dictionary) -> bool:
	return mode(value)=="oath" and value.get("oath")=="unmended"


static func hunt(slot: String) -> Dictionary:
	return {"version":1,"mode":"hunt","slot":slot if slot in SLOTS else "Weapon"}

static func trial(tier: int) -> Dictionary:
	return {"version":1,"mode":"trial","tier":clampi(tier,1,MAX_TRIAL)}

static func trial_floor(tier: int) -> int:
	return 1+(clampi(tier,1,MAX_TRIAL)-1)*2

static func valid(value: Variant, target_floor: int) -> bool:
	if not value is Dictionary or not value.get("version") is int or value.version!=1: return false
	if value.get("mode")=="oath": return value.size()==3 and value.get("oath") is String and OATHS.has(value.oath)
	if value.get("mode")=="hunt": return value.size()==3 and value.get("slot") is String and value.slot in SLOTS
	if value.get("mode")=="trial": return value.size()==3 and value.get("tier") is int and value.tier>=1 and value.tier<=MAX_TRIAL and target_floor==trial_floor(value.tier)
	return false

static func mode(value: Dictionary) -> String:
	return String(value.get("mode","campaign"))

static func title(value: Dictionary) -> String:
	if mode(value)=="oath": return String(OATHS[value.oath].name).to_upper()
	if mode(value)=="hunt": return "HUNT • "+String(value.slot).to_upper()
	if mode(value)=="trial": return "ASH TRIAL %02d" % int(value.tier)
	return "CAMPAIGN"

static func health_scale(value: Dictionary) -> float:
	return 1.25 if mode(value)=="trial" else 1.15 if mode(value)=="hunt" else 1.0

static func damage_scale(value: Dictionary) -> float:
	if mode(value)=="oath" and value.get("oath")=="cinder": return 1.25
	return 1.15 if mode(value)=="trial" else 1.08 if mode(value)=="hunt" else 1.0
