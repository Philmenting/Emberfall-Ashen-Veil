extends RefCounted
## Original GLTF models authored with tools/art/build_characters.py.
## Explicit dependencies ensure all eleven appearances are present in Android exports.
const MODELS = {
	"Vowkeeper":preload("res://assets/models/vowkeeper.glb"),
	"Arcanist":preload("res://assets/models/arcanist.glb"),
	"Ranger":preload("res://assets/models/ranger.glb"),
	"raider":preload("res://assets/models/raider.glb"),
	"hexer":preload("res://assets/models/hexer.glb"),
	"bulwark":preload("res://assets/models/bulwark.glb"),
	"elite":preload("res://assets/models/elite.glb"),
	"guardian_0":preload("res://assets/models/guardian_0.glb"),
	"guardian_1":preload("res://assets/models/guardian_1.glb"),
	"guardian_2":preload("res://assets/models/guardian_2.glb"),
	"guardian_3":preload("res://assets/models/guardian_3.glb"),
}

static func appearance(kind: String, boss: bool, region: int) -> PackedScene:
	return MODELS["guardian_%d" % clampi(region,0,3)] if boss else MODELS.get(kind,MODELS.raider)
