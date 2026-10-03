extends RefCounted
## Conservative bag cleanup: preserve build options, then compare raw item properties.
const ATTRIBUTES := ["Strength","Dexterity","Intellect","Vitality","Spirit","Crit"]
const QUALITIES := ["COMMON","UNCOMMON","RARE","EPIC","LEGENDARY"]

static func is_obsolete(item: Dictionary, equipped: Dictionary, selected_class: String) -> bool:
	if item.get("locked",false) or not item.get("slot") in equipped: return false
	# Relics, high rarities, alternate-class gear and invested items require individual review.
	if not String(item.get("relic","")).is_empty(): return false
	if item.get("quality","") in ["EPIC","LEGENDARY"] or int(item.get("temper",0))>0: return false
	if item.get("affinity",selected_class)!=selected_class: return false
	var worn: Dictionary=equipped[item.slot]
	# Different regions are useful for assembling a future set, even with lower stats.
	if item.get("region",-1)!=worn.get("region",-1): return false
	if int(item.get("tier",1))>int(worn.get("tier",1)): return false
	var item_quality:=QUALITIES.find(String(item.get("quality","COMMON")))
	var worn_quality:=QUALITIES.find(String(worn.get("quality","COMMON")))
	if item_quality<0 or worn_quality<item_quality: return false
	for key in ["power","armor"]:
		if int(item.get(key,0))>int(worn.get(key,0)): return false
	var stats: Dictionary=item.get("stats",{})
	var worn_stats: Dictionary=worn.get("stats",{})
	# Unknown affixes may acquire mechanics later; do not assume they are worthless.
	for key in stats:
		if key not in ATTRIBUTES: return false
	for key in ATTRIBUTES:
		if float(stats.get(key,0))>float(worn_stats.get(key,0)): return false
	return true
