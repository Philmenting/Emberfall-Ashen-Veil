extends RefCounted
## Original art direction shared by the world and its inhabitants.
const THEMES := [
	{"id":"spire", "stone":"747a80", "edge":"9d9990", "dark":"20272d", "metal":"82715a", "cloth":"40262b", "fire":"ec843b", "light":"eaa36c", "moon":"cad4de", "ambient":"9aaeba", "fog":"15212a", "background":"080f15", "roughness":0.86, "density":0.006, "enemy":"943b30", "skin":"7e8075", "glow":"ee853e"},
	{"id":"archive", "stone":"697f78", "edge":"8e9d92", "dark":"192c2d", "metal":"708276", "cloth":"243d3c", "fire":"6bbfad", "light":"83c8b7", "moon":"abc8c4", "ambient":"72988f", "fog":"122728", "background":"071316", "roughness":0.61, "density":0.007, "enemy":"459a94", "skin":"80afa6", "glow":"75cdb9"},
	{"id":"ossuary", "stone":"807d7e", "edge":"b5ae9e", "dark":"27242b", "metal":"9b917c", "cloth":"452d3c", "fire":"a99ab9", "light":"c1afcb", "moon":"c8c3d5", "ambient":"958e9d", "fog":"202029", "background":"101017", "roughness":0.84, "density":0.007, "enemy":"976caf", "skin":"c3bca5", "glow":"bb9fc3"},
	{"id":"citadel", "stone":"666464", "edge":"968576", "dark":"272324", "metal":"88705a", "cloth":"472820", "fire":"e47732", "light":"e89553", "moon":"cdbdae", "ambient":"988f8b", "fog":"251b18", "background":"110d0c", "roughness":0.89, "density":0.008, "enemy":"ce652c", "skin":"827065", "glow":"e89e58"}
]
# Lighting distinguishes each region's masonry from the neutral-lit figures.
# These tune the existing room lights, never add region-specific render passes.
const LIGHTING := [
	{"key":"d4dce5", "key_energy":0.94, "rim":"9dc8df", "actor":"eee5d9", "actor_energy":0.80, "fill":"cddce5", "ambient_energy":0.17},
	{"key":"b2cec7", "key_energy":0.90, "rim":"a7d4dd", "actor":"eee5d8", "actor_energy":0.84, "fill":"d9dce4", "ambient_energy":0.17},
	{"key":"ccc6d6", "key_energy":0.92, "rim":"bcc8e5", "actor":"efe5d7", "actor_energy":0.82, "fill":"d3dbe7", "ambient_energy":0.17},
	{"key":"d7c4b1", "key_energy":0.88, "rim":"9ebfd6", "actor":"e0e7ec", "actor_energy":0.84, "fill":"cbdce7", "ambient_energy":0.16}
]
const ENEMY_NAMES := [
	{"raider":"Hollow Stalker","bulwark":"Ashbound Shieldbearer","hexer":"Grave Hexer","elite":"Cinder Captain"},
	{"raider":"Drowned Acolyte","bulwark":"Silt Sentinel","hexer":"Tide Scribe","elite":"Archive Keeper"},
	{"raider":"Bone Pilgrim","bulwark":"Ossuary Guardian","hexer":"Glass Seer","elite":"Mourning Herald"},
	{"raider":"Ember Thrall","bulwark":"Furnace Guard","hexer":"Cinder Invoker","elite":"Crown Executioner"}
]
static func definition(index: int) -> Dictionary:
	var region:=clampi(index,0,THEMES.size()-1)
	var theme: Dictionary=THEMES[region].duplicate(true)
	theme.lighting=LIGHTING[region].duplicate(true)
	return theme
static func enemy_name(index: int, role: String) -> String:
	return ENEMY_NAMES[clampi(index,0,ENEMY_NAMES.size()-1)].get(role,"Guardian")
