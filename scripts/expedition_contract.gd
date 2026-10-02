extends RefCounted
## Frozen expedition rules carried by the simulation checkpoint.
const SLOTS := ["Weapon","Helmet","Chest","Gloves","Boots","Amulet"]
const TRIAL_LIMIT := 150.0
const MAX_TRIAL := 30
const OATH_ORDER := ["unmended","cinder","hollow"]
const LEGACY_OATHS := ["unmended","cinder"]
const OATHS := {
	"unmended":{"name":"Oath of the Unmended","rule":"No healing from Ember Oath or the well. Victory grants 30% more Gold and XP, plus one extra Rare-or-better drop.","short":"No healing • +30% Gold / XP • +1 relic","risk":"Healing is disabled.","benefit":"Deal 15% more damage while Guard is active; Bellwarden's Memory charges 25% faster.","reward":"Victory: +30% Gold and XP, and one extra Rare-or-better drop."},
	"cinder":{"name":"Oath of Cinders","rule":"Enemies deal 25% more damage. Victory guarantees one Epic-or-better Amulet carrying your class effect.","short":"Enemies +25% damage • Epic class Amulet","risk":"Enemies deal 25% more damage.","benefit":"Damaging skills deal 15% more damage; class relic effects deal 25% more damage.","reward":"Victory: a guaranteed Epic-or-better class Amulet."},
	"hollow":{"name":"Oath of the Hollow","rule":"All skills cost 35% more Mana, but their cooldowns are 20% shorter. Victory grants 20% more Gold and XP.","short":"Skills +35% Mana / −20% cooldown • +20% Gold / XP","risk":"All skills cost 35% more Mana.","benefit":"Signature and technique cooldowns are 20% shorter.","reward":"Victory: +20% Gold and XP."}
}

static func oath(key: String) -> Dictionary:
	# Existing callers and recorded checkpoints retain the original two rules.
	if key in LEGACY_OATHS: return {"version":1,"mode":"oath","oath":key}
	return combine([key]) if key=="hollow" else {}

static func combine(keys: Array) -> Dictionary:
	# Reject an invalid selection instead of silently dropping a risk or reward.
	if keys.is_empty() or keys.size()>2: return {}
	var ordered: Array=[]
	for key in keys:
		if not key is String or not key in OATH_ORDER or keys.count(key)!=1: return {}
	for key in OATH_ORDER:
		if key in keys: ordered.append(key)
	return {"version":2,"mode":"oath","oaths":ordered}

static func oath_keys(value: Dictionary) -> Array:
	if mode(value)!="oath": return []
	if value.get("version")==1 and value.get("oath") in LEGACY_OATHS: return [value.oath]
	if value.get("version")==2 and value.get("oaths") is Array: return value.oaths.duplicate()
	return []

static func has_oath(value: Dictionary, key: String) -> bool:
	return key in oath_keys(value)

static func no_healing(value: Dictionary) -> bool:
	return has_oath(value,"unmended")


static func hunt(slot: String) -> Dictionary:
	return {"version":1,"mode":"hunt","slot":slot if slot in SLOTS else "Weapon"}

static func trial(tier: int) -> Dictionary:
	return {"version":1,"mode":"trial","tier":clampi(tier,1,MAX_TRIAL)}

static func trial_floor(tier: int) -> int:
	return 1+(clampi(tier,1,MAX_TRIAL)-1)*2

static func valid(value: Variant, target_floor: int) -> bool:
	if not value is Dictionary or not value.get("version") is int: return false
	if value.version==2:
		return value.size()==3 and value.get("mode")=="oath" and value.get("oaths") is Array and not combine(value.oaths).is_empty() and combine(value.oaths)==value
	if value.version!=1: return false
	if value.get("mode")=="oath": return value.size()==3 and value.get("oath") is String and value.oath in LEGACY_OATHS
	if value.get("mode")=="hunt": return value.size()==3 and value.get("slot") is String and value.slot in SLOTS
	if value.get("mode")=="trial": return value.size()==3 and value.get("tier") is int and value.tier>=1 and value.tier<=MAX_TRIAL and target_floor==trial_floor(value.tier)
	return false

static func mode(value: Dictionary) -> String:
	return String(value.get("mode","campaign"))

static func title(value: Dictionary) -> String:
	if mode(value)=="oath":
		var keys:=oath_keys(value)
		if keys.size()==1 and OATHS.has(keys[0]): return String(OATHS[keys[0]].name).to_upper()
		var names: Array[String]=[]
		for key in keys:
			if OATHS.has(key): names.append(String(OATHS[key].name).trim_prefix("Oath of the ").trim_prefix("Oath of "))
		return "OATHS • "+" + ".join(names).to_upper()
	if mode(value)=="hunt": return "HUNT • "+String(value.slot).to_upper()
	if mode(value)=="trial": return "ASH TRIAL %02d" % int(value.tier)
	return "CAMPAIGN"

static func health_scale(value: Dictionary) -> float:
	return 1.25 if mode(value)=="trial" else 1.15 if mode(value)=="hunt" else 1.0

static func damage_scale(value: Dictionary) -> float:
	if has_oath(value,"cinder"): return 1.25
	return 1.15 if mode(value)=="trial" else 1.08 if mode(value)=="hunt" else 1.0

static func gold_xp_bonus(value: Dictionary) -> float:
	return (0.3 if has_oath(value,"unmended") else 0.0)+(0.2 if has_oath(value,"hollow") else 0.0)

static func reward_multiplier(value: Dictionary) -> float:
	return 1.0+gold_xp_bonus(value)

static func bonus_drop_count(value: Dictionary) -> int:
	return 1 if has_oath(value,"unmended") else 0

static func guarantees_class_relic(value: Dictionary) -> bool:
	return has_oath(value,"cinder")

static func describe(value: Dictionary) -> String:
	var lines: Array[String]=[]
	for key in oath_keys(value):
		if not OATHS.has(key): continue
		var definition: Dictionary=OATHS[key]
		lines.append(String(definition.rule) if value.get("version")==1 else String(definition.risk)+" "+String(definition.benefit)+" "+String(definition.reward))
	if oath_keys(value).size()==2:
		lines.append("Both risks apply. Currency bonuses add together; each drop reward is awarded once.")
	return "\n".join(lines)

static func synergy_description(value: Dictionary, selected_class: String, stats: Dictionary={}) -> String:
	if value.get("version")!=2: return ""
	var lines: Array[String]=[]
	if has_oath(value,"unmended"):
		lines.append({"Vowkeeper":"Ember Oath and Oath Bastion grant Guard; Bellwarden's Memory stores the extra prevented damage faster.","Arcanist":"Frost Mantle enables the Guard damage bonus while Mana absorbs part of incoming damage.","Ranger":"Cinder Veil enables the Guard damage bonus during its retreat."}.get(selected_class,"Protection techniques enable the Guard damage bonus."))
		if stats.get("regional_set",-1)==0: lines.append("Ashen Vigil extends signature Guard, keeping the damage bonus active longer.")
	if has_oath(value,"cinder"):
		lines.append({"Vowkeeper":"Ember Oath, Sundering Arc and Ashen Judgment gain skill damage. Bellwarden's Memory releases 25% more stored damage.","Arcanist":"Veil Nova, Lightning and Starfall gain skill damage. Veilglass Conductor's extra chain hits gain 25% damage.","Ranger":"Cinder Volley, Thornfall and Marked Shot gain skill damage. Crowflight Loop's return hit gains 25% damage."}.get(selected_class,"Damaging skills and class relic effects gain damage."))
		if stats.get("regional_set",-1)==2: lines.append("Mourning Thread grants another 4 critical percentage points to your signature.")
	if has_oath(value,"hollow"):
		lines.append("Both equipped techniques and your signature recover sooner; Spirit and a larger Mana pool sustain the higher cost.")
		if stats.get("regional_set",-1)==1: lines.append("Drowned Script also discounts your technique costs by 20% under Hollow.")
		if stats.get("regional_set",-1)==3: lines.append("Cinder Crown also shortens your technique cooldowns by 15% under Hollow.")
	return "\n".join(lines)
