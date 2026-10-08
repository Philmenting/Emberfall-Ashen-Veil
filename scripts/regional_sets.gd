extends RefCounted
## Three worn pieces from one region activate one set. The largest set wins ties by region order.
const DEFINITIONS := [
	{"name":"Ashen Vigil","rule":"Your signature grants one extra second of Guard."},
	{"name":"Drowned Script","rule":"Your signature costs 20% less Mana."},
	{"name":"Mourning Thread","rule":"Your signature has 8 extra percentage points of critical chance."},
	{"name":"Cinder Crown","rule":"Your signature cooldown is 15% shorter."}
]
static func counts(equipment: Dictionary) -> Array[int]:
	var result: Array[int]=[0,0,0,0]
	for item in equipment.values():
		var region: Variant=item.get("region") if item is Dictionary else null
		if region is int and region>=0 and region<DEFINITIONS.size(): result[region]+=1
	return result

static func missing_slots(equipment: Dictionary, region: int) -> Array[String]:
	var result: Array[String]=[]
	if region<0 or region>=DEFINITIONS.size(): return result
	for slot in ["Weapon","Helmet","Chest","Gloves","Boots","Amulet"]:
		if equipment.get(slot,{}).get("region",-1)!=region: result.append(slot)
	return result

static func active(equipment: Dictionary) -> int:
	var worn:=counts(equipment)
	var best:=-1
	for region in range(4):
		if worn[region]>=3 and (best<0 or worn[region]>worn[best]): best=region
	return best
