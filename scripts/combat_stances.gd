extends RefCounted
## Preparation choices shared by live combat, forecasts, Skip and AFK.
const ORDER := ["balanced", "assault", "bastion"]
const DEFINITIONS := {
	"balanced": {"name":"Balanced", "outgoing":1.0, "incoming":1.0, "color":"d2ad70", "description":"Standard damage and defense. A reliable starting point for every class."},
	"assault": {"name":"Assault", "outgoing":1.18, "incoming":1.22, "color":"efa184", "description":"Deal 18% more damage, take 22% more damage. Clear safe floors faster; test your forecast before pushing."},
	"bastion": {"name":"Bastion", "outgoing":0.88, "incoming":0.80, "color":"9dcabc", "description":"Take 20% less damage, deal 12% less damage. Survive harder encounters at the cost of clear speed."}
}

static func valid(value: Variant) -> bool:
	return value is String and value in ORDER

static func normalize(value: Variant) -> String:
	return value if valid(value) else "balanced"

static func normalize_book(value: Variant) -> Dictionary:
	var book: Dictionary = {}
	for class_key in ["Vowkeeper", "Arcanist", "Ranger"]:
		book[class_key] = normalize(value.get(class_key)) if value is Dictionary else "balanced"
	return book

static func definition(stats: Dictionary) -> Dictionary:
	return DEFINITIONS[normalize(stats.get("combat_stance"))]
