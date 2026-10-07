extends SceneTree
## Inspect actual bound hero surfaces, skeletons and props across the three
## classes. Separate native captures verify the depth shader's visible result.
const Actor=preload("res://scripts/dungeon_actor.gd")
const Readability=preload("res://scripts/combat_readability.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run_checks.call_deferred()
func check(value: bool,label: String) -> void:
	checks+=1
	if value:print("PASS: ",label)
	else:failures+=1;push_error("FAIL: "+label)

func run_checks() -> void:
	var camera:=Camera3D.new();root.add_child(camera)
	camera.position=Vector3(8,9.3,13.5);camera.look_at(Vector3(0,1.05,0))
	for class_key in ["Arcanist","Vowkeeper","Ranger"]:
		var hero:=Actor.new();hero.kind=class_key;root.add_child(hero)
		var observer:=Readability.new()
		var original_materials: Dictionary={}
		for part: MeshInstance3D in hero.body.find_children("*","MeshInstance3D",true,false):
			if not part.is_visible_in_tree():continue
			var values: Array=[]
			for slot in part.mesh.get_surface_count():values.append(part.get_active_material(slot))
			original_materials[part.get_instance_id()]=values
		observer.update(hero,camera,true)
		check(observer.surfaces.size()==original_materials.size(),class_key+": visibility binds every real visible skin, garment and held prop, excluding the hidden compatibility proxy")
		var exact_meshes:=true;var exact_bones:=true;var original_pbr:=true;var no_shadow:=true;var held_prop:=false
		for entry in observer.surfaces:
			var source:=entry.source.get_ref() as MeshInstance3D
			var copy:=entry.copy.get_ref() as MeshInstance3D
			exact_meshes=exact_meshes and copy.mesh==source.mesh and copy.skin==source.skin and copy.get_parent()==source.get_parent() and copy.transform==source.transform
			if source.skin!=null:exact_bones=exact_bones and copy.get_node(copy.skeleton)==source.get_node(source.skeleton)
			for slot in source.mesh.get_surface_count():original_pbr=original_pbr and source.get_active_material(slot)==original_materials[source.get_instance_id()][slot]
			no_shadow=no_shadow and copy.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			held_prop=held_prop or hero.motion_rig.weapon.is_ancestor_of(source)
		check(exact_meshes and exact_bones,class_key+": every reveal surface shares its original mesh, skin, native skeleton, parent and transform")
		check(original_pbr and no_shadow and held_prop,class_key+": original PBR and shadows remain untouched; the actual held weapon participates")
		var original_position:=hero.position
		var original_camera:=camera.transform
		for style in ["basic","signature"]:
			hero.attack_time=-1;hero.release_time=-1;hero.strike(style,.30,true);hero.sync_attack(.06);hero.animate(0,false)
			observer.update(hero,camera,true)
			var synchronous:=true
			for entry in observer.surfaces:
				var source:=entry.source.get_ref() as MeshInstance3D
				var copy:=entry.copy.get_ref() as MeshInstance3D
				synchronous=synchronous and copy.transform==source.transform and copy.is_visible_in_tree()==source.is_visible_in_tree()
			check(synchronous and hero.position==original_position and camera.transform==original_camera,class_key+" "+style+": skin and prop follow the real cast without moving the actor or camera")
		observer.update(hero,camera,false)
		var disabled:=true
		for entry in observer.surfaces:disabled=disabled and not entry.copy.get_ref().visible
		check(disabled and not observer.enabled,class_key+": an unobstructed/travel frame disables every additional hero draw")
		hero.die();observer.update(hero,camera,true)
		check(not observer.enabled,class_key+": defeated heroes receive no occlusion emphasis")
		observer.dispose()
		check(hero.body.find_children("OccludedHero_*","MeshInstance3D",true,false).is_empty(),class_key+": disposing visibility leaves no extra geometry or retained skeleton")
		hero.free()
	# Rebind against an actual in-place class/equipment change rather than a
	# synthetic object ID; no previous skin or prop may survive that transition.
	var changed:=Actor.new();changed.kind="Arcanist";root.add_child(changed)
	var observer:=Readability.new();observer.update(changed,camera,true)
	changed.configure_equipment({},"Ranger");observer.update(changed,camera,true)
	var current_only:=true
	for entry in observer.surfaces:
		var source:=entry.source.get_ref() as MeshInstance3D
		current_only=current_only and source!=null and changed.body.is_ancestor_of(source)
	check(current_only and observer.rig_reference.get_ref()==changed.motion_rig,"class switch: the pass rebinds exclusively to the current native skin, clothing and bow")
	observer.dispose();changed.free();camera.free()
	await process_frame
	print("COMBAT OCCLUSION SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
