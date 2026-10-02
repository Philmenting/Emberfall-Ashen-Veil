extends RefCounted
## Optional local notes. No identifiers, exact visit dates or network transport.
const MILESTONES := ["first_hit","first_signature","first_clear","first_relic_equipped"]
static func normalize(value: Variant) -> Dictionary:
	var result: Dictionary={}
	if value is Dictionary:
		for key in MILESTONES:
			var seconds: Variant=value.get(key)
			if (seconds is int or seconds is float) and is_finite(float(seconds)) and seconds>=0.0 and seconds<=86400.0: result[key]=float(seconds)
		if value.get("returned_next_day") is bool: result.returned_next_day=value.returned_next_day
	return result

static func report(value: Dictionary) -> String:
	var lines: PackedStringArray=["Optional local playtest notes (simulation seconds, not loading time):"]
	for key in MILESTONES:
		lines.append(key+": "+("%.1f s" % float(value[key]) if value.has(key) else "not observed"))
	lines.append("Returned after at least a day: "+str(value.get("returned_next_day",false)))
	return "\n".join(lines)
