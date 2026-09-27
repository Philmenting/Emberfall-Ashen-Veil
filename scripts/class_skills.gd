extends RefCounted
## Original selectable techniques. Signature skills remain class-specific.
const CLASSES := {
	"Vowkeeper":["bastion","sunder","judgment"],
	"Arcanist":["frost_ward","chain","starfall"],
	"Ranger":["smoke","rain","marked"]
}
const DEFINITIONS := {
	"bastion":{"name":"Oath Bastion","short":"BASTION","role":"Protection","cost":16,"cooldown":14.0,"cast":0.25,"kind":"guard","guard":5.0,"factor":0.0,"radius":0.0,"color":"efc989","rule":"Below 70% Life or when a ground attack threatens you. Grants 5 seconds of Guard (45% less incoming damage)."},
	"sunder":{"name":"Sundering Arc","short":"SUNDER","role":"Melee area","cost":22,"cooldown":8.0,"cast":0.4,"kind":"area","factor":0.78,"radius":3.6,"color":"f5b661","rule":"Against nearby groups or an elite/guardian. Sweeps a broad area around you."},
	"judgment":{"name":"Ashen Judgment","short":"JUDGMENT","role":"Single target","cost":26,"cooldown":10.0,"cast":0.55,"kind":"single","factor":1.5,"radius":0.0,"color":"ffe3a2","rule":"Against elites, guardians or an enemy below 40% Life. A focused heavy strike."},
	"frost_ward":{"name":"Frost Mantle","short":"FROST","role":"Protection / slow","cost":22,"cooldown":14.0,"cast":0.25,"kind":"guard","guard":3.5,"factor":0.0,"radius":3.0,"color":"89dbe9","rule":"Below 70% Life or when a ground attack threatens you. Grants 3.5 seconds of Guard and slows nearby enemies for 4 seconds."},
	"chain":{"name":"Veil Lightning","short":"LIGHTNING","role":"Chained targets","cost":28,"cooldown":8.0,"cast":0.35,"kind":"chain","factor":0.72,"radius":4.0,"color":"a3b8ff","rule":"Against groups or an elite/guardian. Jumps to up to three enemies; each jump reaches 4 metres."},
	"starfall":{"name":"Ashen Starfall","short":"STARFALL","role":"Ground burst","cost":38,"cooldown":12.0,"cast":0.8,"kind":"area","factor":1.2,"radius":3.5,"color":"d6a2ff","rule":"Against clustered enemies or an elite/guardian. Marks the target's current position; enemies can leave before impact."},
	"smoke":{"name":"Cinder Veil","short":"VEIL","role":"Protection / retreat","cost":16,"cooldown":14.0,"cast":0.25,"kind":"guard","guard":2.8,"factor":0.0,"radius":0.0,"color":"97bdb5","rule":"Below 70% Life or when a ground attack threatens you. Grants 2.8 seconds of Guard and retreats if a safe destination exists."},
	"rain":{"name":"Thornfall","short":"THORNFALL","role":"Ground area / slow","cost":28,"cooldown":9.0,"cast":0.55,"kind":"area","factor":0.9,"radius":3.8,"color":"8cdeb1","rule":"Against clustered enemies or an elite/guardian. Arrows strike the marked ground and slow enemies for 1.7 seconds."},
	"marked":{"name":"Marked Shot","short":"MARKED","role":"Armor piercing","cost":24,"cooldown":8.0,"cast":0.4,"kind":"single","factor":1.2,"radius":0.0,"color":"e0efab","rule":"Prioritizes your selected target: a caster, shieldbearer, elite or guardian. Ignores shieldbearer/elite damage reduction."}
}

static func choices(selected_class: String) -> Array:
	return CLASSES.get(selected_class,CLASSES.Vowkeeper).duplicate()

static func defaults(selected_class: String) -> Array:
	return choices(selected_class).slice(0,2)

static func normalize(selected_class: String, value: Variant) -> Array:
	var allowed := choices(selected_class)
	var result: Array=[]
	if value is Array:
		for key in value:
			if key is String and key in allowed and not key in result and result.size()<2: result.append(key)
	for key in allowed:
		if result.size()<2 and not key in result: result.append(key)
	return result

static func valid(selected_class: String, value: Variant) -> bool:
	return value is Array and value.size()==2 and normalize(selected_class,value)==value

static func normalize_book(value: Variant) -> Dictionary:
	var result: Dictionary={}
	for selected_class in CLASSES:
		result[selected_class]=normalize(selected_class,value.get(selected_class) if value is Dictionary else null)
	return result

static func damage(key: String, stats: Dictionary) -> int:
	return maxi(0,int(float(stats.ability_damage)*float(DEFINITIONS[key].factor)))
