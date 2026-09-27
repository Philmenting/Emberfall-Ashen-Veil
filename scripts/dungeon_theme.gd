extends RefCounted
## Original art direction shared by the world and its inhabitants.
const THEMES := [
	{"id":"spire", "stone":"636970", "edge":"727777", "dark":"252933", "metal":"65533a", "cloth":"392c35", "fire":"f37825", "light":"ffab60", "moon":"a8c9ee", "ambient":"8c9eb8", "fog":"111b25", "background":"070c12", "roughness":0.84, "density":0.020, "enemy":"943b30", "skin":"7e8075", "glow":"ff7433"},
	{"id":"archive", "stone":"4e7470", "edge":"78928a", "dark":"1d383b", "metal":"6d866d", "cloth":"31565a", "fire":"54dcd5", "light":"72ead9", "moon":"82bfc9", "ambient":"79a6a0", "fog":"153839", "background":"071a21", "roughness":0.42, "density":0.024, "enemy":"459a94", "skin":"80afa6", "glow":"71ffdb"},
	{"id":"ossuary", "stone":"555162", "edge":"89848c", "dark":"252333", "metal":"a39476", "cloth":"4b284e", "fire":"b396f0", "light":"c0a4f2", "moon":"bdb1de", "ambient":"9f94ac", "fog":"292337", "background":"161222", "roughness":0.68, "density":0.018, "enemy":"976caf", "skin":"c3bca5", "glow":"da96ff"},
	{"id":"citadel", "stone":"61514c", "edge":"847164", "dark":"302725", "metal":"ac7339", "cloth":"612b24", "fire":"ff6a21", "light":"ff994d", "moon":"e8aa76", "ambient":"b8937b", "fog":"382018", "background":"180c0a", "roughness":0.76, "density":0.021, "enemy":"ce652c", "skin":"827065", "glow":"ffc249"}
]
const ENEMY_NAMES := [
	{"raider":"Hollow Stalker","bulwark":"Ashbound Shieldbearer","hexer":"Grave Hexer","elite":"Cinder Captain"},
	{"raider":"Drowned Acolyte","bulwark":"Silt Sentinel","hexer":"Tide Scribe","elite":"Archive Keeper"},
	{"raider":"Bone Pilgrim","bulwark":"Ossuary Guardian","hexer":"Glass Seer","elite":"Mourning Herald"},
	{"raider":"Ember Thrall","bulwark":"Furnace Guard","hexer":"Cinder Invoker","elite":"Crown Executioner"}
]
static func definition(index: int) -> Dictionary:
	return THEMES[clampi(index,0,THEMES.size()-1)].duplicate(true)
static func enemy_name(index: int, role: String) -> String:
	return ENEMY_NAMES[clampi(index,0,ENEMY_NAMES.size()-1)].get(role,"Guardian")
