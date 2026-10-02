extends RefCounted
## Original art direction shared by the world and its inhabitants.
const THEMES := [
	{"id":"spire", "stone":"989387", "edge":"b5a99a", "dark":"28333d", "metal":"a78956", "cloth":"392c35", "fire":"f37825", "light":"ffab60", "moon":"f5d3a0", "ambient":"8baaba", "fog":"111b25", "background":"070c12", "roughness":0.84, "density":0.009, "enemy":"943b30", "skin":"7e8075", "glow":"ff7433"},
	{"id":"archive", "stone":"74968c", "edge":"a5b2a1", "dark":"1d383b", "metal":"6d866d", "cloth":"31565a", "fire":"54dcd5", "light":"72ead9", "moon":"82bfc9", "ambient":"79a6a0", "fog":"153839", "background":"071a21", "roughness":0.42, "density":0.012, "enemy":"459a94", "skin":"80afa6", "glow":"71ffdb"},
	{"id":"ossuary", "stone":"a19aae", "edge":"c6bfbc", "dark":"252333", "metal":"a39476", "cloth":"4b284e", "fire":"b396f0", "light":"c0a4f2", "moon":"bdb1de", "ambient":"9f94ac", "fog":"292337", "background":"161222", "roughness":0.68, "density":0.010, "enemy":"976caf", "skin":"c3bca5", "glow":"da96ff"},
	{"id":"citadel", "stone":"817468", "edge":"a9967a", "dark":"302725", "metal":"ac7339", "cloth":"612b24", "fire":"ff6a21", "light":"ff994d", "moon":"e8aa76", "ambient":"b8937b", "fog":"382018", "background":"180c0a", "roughness":0.76, "density":0.013, "enemy":"ce652c", "skin":"827065", "glow":"ffc249"}
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
