extends RefCounted
## One equipped amulet effect; frozen into a new expedition's stats.
const DEFINITIONS := {
	"stored_ember":{"class":"Vowkeeper","name":"Bellwarden's Memory","short":"Guard stores damage for your next Ember Oath.","rule":"While Guard is active, store prevented damage (up to 60% of signature damage). Your next Ember Oath releases it into its primary target."},
	"echo_lightning":{"class":"Arcanist","name":"Veilglass Conductor","short":"Veil Nova chains to two enemies beyond its blast.","rule":"Veil Nova chains to up to two enemies outside its blast. Each jump reaches 4 metres and deals 45% of signature damage."},
	"returning_thorn":{"class":"Ranger","name":"Crowflight Loop","short":"Cinder Volley returns for a second hit on its target.","rule":"Cinder Volley returns to its primary target for a second strike dealing 35% of signature damage."}
}
const CLASS_KEYS := {"Vowkeeper":"stored_ember","Arcanist":"echo_lightning","Ranger":"returning_thorn"}

static func effect(item: Dictionary, selected_class: String) -> String:
	var key: Variant=item.get("relic","")
	if key is String and DEFINITIONS.has(key) and item.get("slot")=="Amulet" and DEFINITIONS[key].class==selected_class: return key
	return ""

static func attune(item: Dictionary, selected_class: String) -> Dictionary:
	var result:=item.duplicate(true)
	if not CLASS_KEYS.has(selected_class) or result.get("slot")!="Amulet": return result
	var key: String=CLASS_KEYS[selected_class]
	result.relic=key
	result.name=DEFINITIONS[key].name
	return result

static func describe(item: Dictionary) -> String:
	var key: Variant=item.get("relic","")
	if not key is String or not DEFINITIONS.has(key): return ""
	return String(DEFINITIONS[key].class)+" • "+String(DEFINITIONS[key].rule)
