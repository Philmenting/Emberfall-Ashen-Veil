extends RefCounted
## Modular original cathedral meshes, shared by every chamber.
const MODELS = {
	"field_table":preload("res://assets/models/expedition_table.glb"),
	"field_forge":preload("res://assets/models/field_forge.glb"),
	"seal_shrine":preload("res://assets/models/seal_shrine.glb"),
	"vault":preload("res://assets/models/ruined_vault.glb"),
	"library":preload("res://assets/models/drowned_library.glb"),
	"altar":preload("res://assets/models/reliquary_altar.glb"),
	"throne":preload("res://assets/models/furnace_throne.glb"),
	"brazier":preload("res://assets/models/ceremonial_brazier.glb"),
	"lancet":preload("res://assets/models/leaded_lancet.glb"),
	"intarsia":preload("res://assets/models/sanctuary_intarsia.glb"),
	"pillar":preload("res://assets/models/pillar.glb"),
	"broken_pillar":preload("res://assets/models/broken_pillar.glb"),
	"arch":preload("res://assets/models/gothic_arch.glb"),
	"tomb":preload("res://assets/models/carved_tomb.glb"),
	"bell":preload("res://assets/models/hanging_bell.glb"),
	"bone_arch":preload("res://assets/models/bone_arch.glb"),
	"furnace":preload("res://assets/models/furnace.glb"),
	"well":preload("res://assets/models/pilgrim_well.glb"),
}

static var crafted_materials: Dictionary={}

static func crafted(original: StandardMaterial3D) -> Material:
	var key:=String(original.resource_name).get_slice(".",0)
	if key not in ["oak","leather","wine","sage","violet","linen","ash","iron","silver","bronze","gold","patina"]: return original
	var cache_key:=key+original.albedo_color.to_html()+str(original.metallic)+str(original.roughness)
	if crafted_materials.has(cache_key): return crafted_materials[cache_key]
	var material:=ShaderMaterial.new()
	material.shader=preload("res://assets/shaders/crafted_surface.gdshader")
	material.set_shader_parameter("surfaces",preload("res://assets/materials/field-surfaces/material-atlas.png"))
	material.set_shader_parameter("cell",Vector2.ZERO if key=="oak" else (Vector2(1,0) if key=="leather" else (Vector2(1,1) if original.metallic>0.3 else Vector2(0,1))))
	material.set_shader_parameter("tint",original.albedo_color)
	material.set_shader_parameter("metal",original.metallic)
	material.set_shader_parameter("roughness",maxf(0.5,original.roughness))
	material.set_shader_parameter("scale",1.4 if key=="oak" else 2.1)
	crafted_materials[cache_key]=material
	return material
