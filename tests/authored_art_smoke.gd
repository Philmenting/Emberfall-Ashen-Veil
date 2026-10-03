extends SceneTree
## Live 3D source geometry, skinning and render budget.
const Models=preload("res://scripts/authored_characters.gd")
const Architecture=preload("res://scripts/authored_architecture.gd")
const Actor=preload("res://scripts/dungeon_actor.gd")
const Sim=preload("res://scripts/expedition_simulation.gd")
const Layout=preload("res://scripts/dungeon_layout.gd")
const Bot=preload("res://tests/balance_survey_bot.gd")
# Inspect actual exported/placed geometry before MultiMesh batching. The headless
# dummy renderer does not retain usable MultiMesh instance-transform readback.
class SceneryAudit extends "res://scripts/dungeon_world.gd":
	var retained_dressing_bounds: Array[AABB]=[]
	func _build_region_landmarks() -> void:
		var previous:=find_children("*","MeshInstance3D",true,false)
		super._build_region_landmarks()
		_record_added(previous)
	func _build_ruin_depth() -> void:
		var previous:=find_children("*","MeshInstance3D",true,false)
		super._build_ruin_depth()
		_record_added(previous)
	func _record_added(previous: Array) -> void:
		for part in find_children("*","MeshInstance3D",true,false):
			if previous.has(part): continue
			var local_bounds: AABB=AABB(-part.mesh.size*.5,part.mesh.size) if part.mesh is BoxMesh else part.mesh.get_aabb()
			var bounds: AABB=part.global_transform*local_bounds
			if bounds.end.y>.5 and bounds.position.y<2.8: retained_dressing_bounds.append(bounds)
var checks:=0
var failures:=0

func _initialize() -> void: call_deferred("run_checks")
func check(value: bool, description: String) -> void:
	checks+=1
	if value: print("PASS: ",description)
	else: failures+=1; push_error("FAIL: "+description)

func run_checks() -> void:
	var allowed: Array=["Body","ArmL","ArmR","LegL","LegR","KneeL","KneeR","Cape","Weapon","HairL","HairR","BowString","Arrow"]
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
		if name in ["vault","library","altar","throne"]:
			check(prop.find_children("*","MeshInstance3D",true,false).size()<=12,name+": repeated landmark stays joined within twelve material meshes")
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
		check(shared and first_parts.size()==2 and first.model.skin==second.model.skin,"guardian %d: cached runtime uses one shared volumetric surface plus contact shadow" % region)
		first.strike("telegraph"); first.animate(0.2,false); first.react(); first.animate(0.06,false)
		first.die(); first.animate(1.0,false)
		check(first.body.position.is_finite() and first.pose_frame==5 and first.appearance_key=="guardian_%d" % region,"guardian %d: actual 3D attack, impact and defeat states remain finite" % region)
		first.free(); second.free()
	var game:=Bot.new()
	for region in range(4):
		for seed_value in [1979,1042,7351]:
			var sim:=Sim.new()
			sim.setup("Arcanist",game._combat_stats(),region*10+1,"Guardian",seed_value)
			var world:=SceneryAudit.new()
			world.simulation=sim; world.region_index=region; world.character_class="Arcanist"; world.active=false
			root.add_child(world)
			var floors:=Layout.floor_rects(region,sim.layout_seed(),sim.movement_seed(),sim.uses_wandering_routes(),sim.uses_scouting_routes(),sim.uses_expanded_scouting_routes())
			var intersections:=0
			for bounds in world.retained_dressing_bounds:
				var footprint:=Rect2(Vector2(bounds.position.x,bounds.position.z),Vector2(bounds.size.x,bounds.size.z))
				for floor_rect in floors:
					if floor_rect.grow(.199).intersects(footprint):
						intersections+=1; break
			check(world.retained_dressing_bounds.size()>20,"region %d seed %d: route audit includes real standing-height dressing" % [region,seed_value])
			check(intersections==0,"region %d seed %d: added walls and complete props leave authoritative passages clear (%d intersections)" % [region,seed_value,intersections])
			var batch_count:=world.find_children("*","MultiMeshInstance3D",true,false).size()
			check(batch_count<450,"region %d seed %d: repeated static geometry stays below 450 batches (%d)" % [region,seed_value,batch_count])
			world.free()
	game.free()
	print("AUTHORED ART SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
