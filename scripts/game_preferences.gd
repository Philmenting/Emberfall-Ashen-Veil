extends RefCounted
## Stored inside the same validated save generations as the hero.
const DEFAULTS := {"master":0.8,"music":0.35,"effects":0.7,"battery":false,"numbers":true}

static func normalize(raw: Variant) -> Dictionary:
	var result := DEFAULTS.duplicate()
	if not raw is Dictionary: return result
	for key in ["master","music","effects"]:
		var value: Variant = raw.get(key,result[key])
		if (value is int or value is float) and is_finite(float(value)):
			result[key] = clampf(float(value),0.0,1.0)
	for key in ["battery","numbers"]:
		if raw.get(key) is bool: result[key] = raw[key]
	return result
