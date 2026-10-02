extends RefCounted
## Three worn pieces from one region activate one set. The largest set wins ties by region order.
const DEFINITIONS := [
	{"name":"Ashen Vigil","rule":"Your signature grants one extra second of Guard."},
	{"name":"Drowned Script","rule":"Your signature costs 20% less Mana."},
	{"name":"Mourning Thread","rule":"Your signature has 8 extra percentage points of critical chance."},
	{"name":"Cinder Crown","rule":"Your signature cooldown is 15% shorter."}
]
static func active(equipment: Dictionary) -> int:
	var counts: Array=[0,0,0,0]
	for item in equipment.values():
		var region: Variant=item.get("region") if item is Dictionary else null
		if region is int and region>=0 and region<4: counts[region]+=1
	var best:=-1
	for region in range(4):
		if counts[region]>=3 and (best<0 or counts[region]>counts[best]): best=region
	return best
