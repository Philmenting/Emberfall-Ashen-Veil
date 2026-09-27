extends RefCounted
## Deterministic, class-attuned drops. Affinity is guidance, never an equip lock.
const SLOTS := ["Weapon","Helmet","Chest","Gloves","Boots","Amulet"]
const ATTRIBUTES := ["Strength","Dexterity","Intellect","Vitality","Spirit"]
const PRIMARY := {"Vowkeeper":"Strength","Arcanist":"Intellect","Ranger":"Dexterity"}
const NAMES := {
	"Vowkeeper": {
		"Weapon":["Oathsplitter Blade","Bellwarden's Edge","Vigilant Greatsword","Ashwake Sword"],
		"Helmet":["Oathguard Helm","Bellwarden Visor"],
		"Chest":["Ashbound Plate","Vigilant Cuirass"],
		"Gloves":["Oathguard Gauntlets","Emberforged Grips"],
		"Boots":["Bellwarden Greaves","Vigilant Sabatons"],
		"Amulet":["Oathkeeper Seal","Heart of the Vigil"]
	},
	"Arcanist": {
		"Weapon":["Veilbranch Staff","Starless Wand","Siltcall Staff","Cinderweave Rod"],
		"Helmet":["Veilweaver Hood","Silt Scribe's Circlet"],
		"Chest":["Starless Vestments","Veilweaver Robe"],
		"Gloves":["Runebound Wraps","Scribe's Grasp"],
		"Boots":["Veilwalker Treads","Starless Slippers"],
		"Amulet":["Veilglass Focus","Scribe's Reliquary"]
	},
	"Ranger": {
		"Weapon":["Crowflight Bow","Cinderstring Bow","Hollowthorn Longbow","Ashwind Recurve"],
		"Helmet":["Crowflight Hood","Ashwind Cowl"],
		"Chest":["Tracker's Leathers","Crowflight Vest"],
		"Gloves":["Cinderstring Grips","Tracker's Gloves"],
		"Boots":["Ashwind Boots","Silent Tracker Treads"],
		"Amulet":["Crow's Eye Pendant","Ashwind Compass"]
	}
}

static func roll(selected_class: String, boss_bonus: bool, requested_tier: int, rng: RandomNumberGenerator) -> Dictionary:
	var affinity: String=selected_class if PRIMARY.has(selected_class) else "Vowkeeper"
	var slot: String=SLOTS[rng.randi()%SLOTS.size()]
	var quality_roll:=rng.randf()
	var quality:="COMMON"
	if quality_roll>0.992: quality="LEGENDARY"
	elif quality_roll>0.955: quality="EPIC"
	elif quality_roll>0.82: quality="RARE"
	elif quality_roll>0.53: quality="UNCOMMON"
	if boss_bonus and quality in ["COMMON","UNCOMMON"]: quality="RARE"
	var bonus: int={"COMMON":0,"UNCOMMON":5,"RARE":12,"EPIC":22,"LEGENDARY":36}[quality]
	var tier:=clampi(requested_tier,1,10)
	var power:=tier*18+rng.randi_range(7,17)+bonus
	var armor:=int(power*(0.82 if slot in ["Helmet","Chest","Gloves","Boots"] else 0.0))
	var affixes: int={"COMMON":1,"UNCOMMON":1,"RARE":2,"EPIC":3,"LEGENDARY":4}[quality]
	var stats: Dictionary={}
	var candidates:=ATTRIBUTES.duplicate()
	var primary: String=PRIMARY[affinity]
	candidates.erase(primary)
	# Every drop contributes to the chosen class; other affixes preserve tradeoffs.
	stats[primary]=rng.randi_range(1,3+tier+int(bonus/10))
	for i in range(affixes-1):
		var attribute: String=candidates.pop_at(rng.randi()%candidates.size())
		stats[attribute]=rng.randi_range(1,3+tier+int(bonus/10))
	if quality in ["EPIC","LEGENDARY"]: stats.Crit=rng.randi_range(1,3+tier)
	var sell:=28+tier*12+bonus*4+rng.randi_range(0,16)
	var names: Array=NAMES[affinity][slot]
	return {"name":names[rng.randi()%names.size()],"slot":slot,"power":power,"quality":quality,"tier":tier,"armor":armor,"stats":stats,"sell":sell,"temper":0,"status":"","affinity":affinity}
