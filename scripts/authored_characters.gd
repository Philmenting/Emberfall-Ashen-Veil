extends RefCounted
## Original volumetric Blender models used by the live 3D character runtime.
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

## Source-skinned assets retain their proportional anatomy, UVs and sockets.
## Complete assets include the head, hair and equipment in the same rest space.
## Accepted production entries are res:// String paths, loaded only on demand.
## Native review fixtures may still inject PackedScene resources directly.
static var BODY_MODELS: Dictionary = {}
static var BODY_COMPLETE: Dictionary = {}
## Generate accepted profiles as GDScript data literals; no runtime JSON file.
## Keep this dictionary mutable for isolated native review fixtures.
static var BODY_PROFILES: Dictionary = {}

static func body_scene(key: String) -> PackedScene:
	var source: Variant=BODY_MODELS.get(key)
	if source==null: return null
	if source is PackedScene: return source
	assert(source is String and String(source).begins_with("res://"),"Complete source entries use product paths or injected PackedScenes")
	var scene:=ResourceLoader.load(String(source),"PackedScene",ResourceLoader.CACHE_MODE_REUSE) as PackedScene
	assert(scene!=null,"Cannot load complete source character: "+key)
	# Do not replace the path with scene: the temporary source is released after
	# baking; the Rig cache and live actors own only the required baked resources.
	return scene
## Authored jewelry follows the Amulet channel independently of its chest bone.
const BODY_MATERIAL_SLOTS={"EF49_worn_silver":5.0}

static func appearance(kind: String, boss: bool, region: int) -> PackedScene:
	return MODELS["guardian_%d" % clampi(region,0,3)] if boss else MODELS.get(kind,MODELS.raider)
