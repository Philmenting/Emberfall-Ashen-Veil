extends SceneTree
## Live class/data, actual shared source surfaces, legacy accents and lit portraits.
const Actor=preload("res://scripts/dungeon_actor.gd")
const HeroArt=preload("res://scripts/hero_art.gd")
var checks:=0
var failures:=0
func _initialize() -> void: run_checks.call_deferred()
func check(value: bool,label: String) -> void:
	checks+=1
	if not value: failures+=1; push_error("FAIL: "+label)
func run_checks() -> void:
	var gear: Dictionary={}
	for slot in ["Weapon","Helmet","Chest","Gloves","Boots","Amulet"]: gear[slot]={"quality":"RARE","tier":3,"temper":4}
	var hero:=Actor.new(); hero.configure_equipment(gear,"Arcanist"); root.add_child(hero)
	check(hero.kind=="Arcanist" and hero.equipment_grades.Helmet==2,"pending class and actual Helmet data bind when entering the tree")
	check(source_surfaces_rendered(hero) and source_surface_count(hero)==8 and hero.motion_rig.triangles<=40000,"eight actual authored surfaces retain the lit volume below 40k triangles")
	check(hero.motion_rig.skeleton.get_bone_count()==65 and source_surfaces_rendered(hero) and hero.motion_rig.player.has_animation("Walk_Loop") and hero.motion_rig.player.has_animation("Death01"),"visible authored surfaces bind to the original native65 skeleton and source animation player")
	var uniforms: Dictionary={"Weapon":"weapon","Helmet":"helm","Chest":"chest","Gloves":"gloves","Boots":"boots","Amulet":"accent"}
	for slot in uniforms:
		check(hero.equipment_grades[slot]==2 and hero.equipped_items[slot].quality=="RARE",slot+": actual rarity binds to the native avatar equipment data and material finish")
	var peer:=Actor.new(); peer.kind="Arcanist"; root.add_child(peer)
	check(source_peers_match(hero,peer,true),"source peers share all eight immutable meshes and native skins with independent actual PBR overrides")
	var material: StandardMaterial3D=hero.motion_rig.surfaces[0].get_active_material(0)
	var peer_material: StandardMaterial3D=peer.motion_rig.surfaces[0].get_active_material(0)
	var original_color:=material.albedo_color
	var peer_color:=peer_material.albedo_color
	material.albedo_color=Color(0.2,0.3,0.4,1.0)
	check(peer_material.albedo_color==peer_color and material!=peer_material,"mutating an actual visible PBR override leaves the peer material unchanged")
	material.albedo_color=original_color
	var original: Mesh=hero.motion_rig.surfaces[0].mesh
	var original_source: Array=[]
	for surface in hero.motion_rig.surfaces: original_source.append([surface.mesh,surface.skin])
	gear.Weapon.quality="LEGENDARY"
	check(hero.equipment_grades.Weapon==2,"caller mutation cannot silently alter equipped appearance")
	hero.configure_equipment(gear,"Arcanist")
	check(hero.equipment_grades.Weapon==4 and peer.equipment_grades.Weapon==0 and source_geometry_unchanged(hero,original_source) and source_peers_match(hero,peer,true),"a source weapon grade update preserves actual authored geometry and independent peer PBR materials")
	hero.configure_equipment(gear,"Ranger")
	var ranger_rig=hero.motion_rig
	var left_hand=ranger_rig.skeleton.find_bone("hand_l")
	var palm=ranger_rig.motion_node.transform*(ranger_rig.skeleton.get_bone_global_pose(left_hand)*ranger_rig.bow_grip_center)
	check(hero.appearance_key=="Ranger" and hero.model.mesh!=original and left_hand>=0 and ranger_rig.weapon_grip_position().distance_to(palm)<.001,"Ranger binds its real bow handle to the authored left palm")
	for class_key in Actor.HEROES:
		hero.configure_equipment(gear,class_key)
		check(hero.appearance_key==class_key and hero.equipment_grades.Weapon==4,class_key+": changing class retains actual equipped grades")
		if not hero.source_avatar:
			for slot in uniforms:
				var rank:=4 if slot=="Weapon" else 2
				check(hero.model.visible and hero.model.material_override==hero.surface_material and hero.equipment_grades[slot]==rank and float(hero.surface_material.get_shader_parameter(uniforms[slot]+"_rank"))==float(rank),class_key+" "+slot+": actual rarity reaches its independent visible surface accent")
		var portrait:=HeroArt.new(); portrait.configure(class_key,gear); portrait.size=Vector2(140,140); root.add_child(portrait)
		portrait.set_presentation(true,true)
		if hero.source_avatar:
			check(portrait.actor.appearance_key==class_key and source_peers_match(hero,portrait.actor,true) and portrait.actor.equipment_grades.Weapon==4,class_key+": portrait and battle render the same complete source meshes and native skins with bound gear data")
		else:
			check(portrait.actor.appearance_key==class_key and portrait.actor.model.mesh==hero.model.mesh and portrait.actor.equipment_grades.Weapon==4,class_key+": portrait and battle render the same equipped spatial heroine")
		check(portrait.viewport.render_target_update_mode==SubViewport.UPDATE_ONCE and portrait.camera.position.z<0,class_key+": Battery portrait keeps the real face view without continuous rendering")
		portrait.set_presentation(false,false)
		portrait.viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
		portrait._process(1.0/120.0)
		check(portrait.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED,class_key+": unchanged portrait reuses its rendered texture")
		portrait._process(1.0/24.0)
		check(portrait.viewport.render_target_update_mode==SubViewport.UPDATE_ONCE,class_key+": a new idle pose requests exactly one portrait redraw")
		portrait.hide();portrait.viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
		portrait._process(1.0)
		check(portrait.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED,class_key+": hidden portrait does not submit animation work")
		portrait.free()
	for kind in Actor.HOSTILES:
		var enemy:=Actor.new(); enemy.kind=kind; enemy.hostile=true; root.add_child(enemy)
		check(enemy.appearance_key==kind and enemy.model.skin!=null,kind+": live hostile uses its own volumetric model")
		enemy.free()
	var first:=Actor.new(); first.boss=true; root.add_child(first)
	var second:=Actor.new(); second.boss=true; root.add_child(second)
	first.set_boss_phase(2)
	check(first.boss_phase==2 and float(first.surface_material.get_shader_parameter("boss_phase"))==2 and second.boss_phase==0,"phase illumination stays independent per guardian")
	check(first.figure_height==4.6 and first.model.mesh==second.model.mesh,"monumental guardians share authored geometry at their real body scale")
	first.free(); second.free(); hero.free(); peer.free()
	print("CHARACTER EQUIPMENT SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func source_surfaces_rendered(actor: Node3D) -> bool:
	if not actor.source_avatar or actor.model.visible or actor.motion_rig.surfaces.is_empty(): return false
	for surface in actor.motion_rig.surfaces:
		if not surface.is_visible_in_tree() or surface.mesh==null or surface.skin==null or surface.get_node_or_null(surface.skeleton)!=actor.motion_rig.skeleton: return false
	return true

func source_surface_count(actor: Node3D) -> int:
	var count:=0
	for surface in actor.motion_rig.surfaces: count+=surface.mesh.get_surface_count()
	return count

func source_geometry_unchanged(actor: Node3D,original: Array) -> bool:
	if not source_surfaces_rendered(actor) or original.size()!=actor.motion_rig.surfaces.size(): return false
	for index in original.size():
		var surface: MeshInstance3D=actor.motion_rig.surfaces[index]
		if surface.mesh!=original[index][0] or surface.skin!=original[index][1]: return false
	return true

func source_peers_match(first: Node3D,second: Node3D,independent_materials: bool) -> bool:
	if not source_surfaces_rendered(first) or not source_surfaces_rendered(second): return false
	for index in first.motion_rig.surfaces.size():
		var a: MeshInstance3D=first.motion_rig.surfaces[index]
		var b: MeshInstance3D=second.motion_rig.surfaces[index]
		if a.name!=b.name or a.mesh!=b.mesh or a.skin!=b.skin: return false
		for slot in a.mesh.get_surface_count():
			var material=a.get_active_material(slot)
			var peer_material=b.get_active_material(slot)
			if not material is StandardMaterial3D or not peer_material is StandardMaterial3D: return false
			if independent_materials and (a.get_surface_override_material(slot)==null or b.get_surface_override_material(slot)==null or material==peer_material): return false
			if material.albedo_texture!=peer_material.albedo_texture or material.normal_texture!=peer_material.normal_texture or material.roughness_texture!=peer_material.roughness_texture: return false
	return true
