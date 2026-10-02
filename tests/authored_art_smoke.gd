extends SceneTree
## Source archive geometry plus the actual painted runtime asset/render budget.
const Models=preload("res://scripts/authored_characters.gd")
const Architecture=preload("res://scripts/authored_architecture.gd")
const Actor=preload("res://scripts/dungeon_actor.gd")
var checks:=0
var failures:=0

func _initialize() -> void: call_deferred("run_checks")
func check(value: bool, description: String) -> void:
	checks+=1
	if value: print("PASS: ",description)
	else: failures+=1; push_error("FAIL: "+description)

func run_checks() -> void:
	var allowed: Array=["Body","ArmL","ArmR","LegL","LegR","KneeL","KneeR","Cape","Weapon"]
	var appearances: Array=[]
	for name in Models.MODELS:
		var scene: PackedScene=Models.MODELS[name]
		check(not appearances.has(scene),name+": own exported character appearance")
		appearances.append(scene)
		var model:=scene.instantiate()
		var triangles:=0
		var valid:=true
		for source in model.find_children("*","MeshInstance3D",true,false):
			valid=valid and allowed.has(String(source.name).get_slice("__",0))
			for surface in range(source.mesh.get_surface_count()):
				var arrays: Array=source.mesh.surface_get_arrays(surface)
				var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
				var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
				var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
				triangles+=indices.size()/3
				for normal in normals: valid=valid and normal.is_finite() and normal.length()>0.9
				for vertex in vertices: valid=valid and vertex.is_finite()
		check(valid,name+": finite geometry and normals fit the animated joint contract")
		check(triangles>4000 and triangles<=40000,name+": character geometry remains within the 40k triangle ceiling (%d)" % triangles)
		model.free()
	for name in Architecture.MODELS:
		var prop: Node3D=Architecture.MODELS[name].instantiate()
		check(not prop.find_children("*","MeshInstance3D",true,false).is_empty(),name+": architectural GLTF is available for export")
		prop.free()
	for region in range(4):
		var first:=Actor.new(); first.kind="boss"; first.hostile=true; first.boss=true; first.region_index=region
		root.add_child(first)
		var second:=Actor.new(); second.kind="boss"; second.hostile=true; second.boss=true; second.region_index=region
		root.add_child(second)
		var first_parts:=first.find_children("*","MeshInstance3D",true,false)
		var second_parts:=second.find_children("*","MeshInstance3D",true,false)
		var shared:=first_parts.size()==second_parts.size()
		for index in range(first_parts.size()-1): shared=shared and first_parts[index].mesh==second_parts[index].mesh
		check(shared and first_parts.size()==2 and first.atlas_texture==second.atlas_texture,"guardian %d: cached runtime uses one painted pose surface plus contact shadow" % region)
		first.strike("telegraph"); first.animate(0.2,false); first.react(); first.animate(0.06,false)
		first.die(); first.animate(0.2,false)
		check(first.body.position.is_finite() and first.pose_frame==5 and first.atlas_path.ends_with("guardian_%d.png" % region),"guardian %d: actual painted attack, impact and defeat states remain finite" % region)
		first.free(); second.free()
	print("AUTHORED ART SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
