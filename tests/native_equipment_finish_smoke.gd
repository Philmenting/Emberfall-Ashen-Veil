extends SceneTree
## Observe real rendered native PBR surfaces and independent live portraits.
## No legacy-proxy shader value can satisfy these equipment checks.
const Actor=preload("res://scripts/dungeon_actor.gd")
const HeroArt=preload("res://scripts/hero_art.gd")
var checks:=0
var failures:=0
const SLOTS: Array[String]=["Weapon","Helmet","Chest","Gloves","Boots","Amulet"]

func _initialize() -> void: run_checks.call_deferred()
func check(value: bool,label: String) -> void:
	checks+=1
	if value: print("PASS: ",label)
	else: failures+=1; push_error("FAIL: "+label)

func make_actor(key: String) -> Node3D:
	var actor:=Actor.new(); actor.kind=key; root.add_child(actor)
	actor.set_process(false); actor.configure_equipment({},key)
	return actor

func materials(actor: Node3D) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for part: MeshInstance3D in actor.motion_rig.motion_node.find_children("*","MeshInstance3D",true,false):
		if not part.visible or part.mesh==null: continue
		for surface in part.mesh.get_surface_count():
			var material:=part.get_active_material(surface) as StandardMaterial3D
			if material==null: continue
			var arrays:=part.mesh.surface_get_arrays(surface)
			result.append({"part":part,"surface":surface,"name":String(part.name),"material":material,"mesh":part.mesh,"skin":part.skin,"vertices":hash(arrays[Mesh.ARRAY_VERTEX]),"indices":hash(arrays[Mesh.ARRAY_INDEX]),"weights":hash(arrays[Mesh.ARRAY_WEIGHTS]),"bones":hash(arrays[Mesh.ARRAY_BONES]),"color":material.albedo_color,"roughness":material.roughness,"metallic":material.metallic,"specular":material.metallic_specular,"normal_scale":material.normal_scale,"albedo_texture":material.albedo_texture,"normal_texture":material.normal_texture,"roughness_texture":material.roughness_texture,"metallic_texture":material.metallic_texture,"ao_texture":material.ao_texture,"emission_texture":material.emission_texture,"emission":material.emission,"emission_enabled":material.emission_enabled,"emission_energy":material.emission_energy_multiplier,"next_pass":material.next_pass})
	return result

func state_unchanged(before: Dictionary,after: Dictionary,include_finish: bool=true,require_mesh_identity: bool=true) -> bool:
	for property in ["mesh","skin","vertices","indices","weights","bones","metallic","specular","normal_scale","albedo_texture","normal_texture","roughness_texture","metallic_texture","ao_texture","emission_texture","emission","emission_enabled","emission_energy","next_pass"]:
		if property=="mesh" and not require_mesh_identity: continue
		if before[property]!=after[property]: return false
	return not include_finish or (before.color==after.color and before.roughness==after.roughness)

func snapshots_equal(before: Array[Dictionary],after: Array[Dictionary],include_finish: bool=true,require_mesh_identity: bool=true) -> bool:
	if before.size()!=after.size(): return false
	for index in before.size():
		if before[index].name!=after[index].name or not state_unchanged(before[index],after[index],include_finish,require_mesh_identity): return false
	return true

func facial(before: Array[Dictionary],after: Array[Dictionary]) -> bool:
	var found:=false
	for index in before.size():
		var name:=String(before[index].name).to_lower()
		var material:=String(before[index].material.resource_name)
		var protected:=name.contains("hair") or name.contains("eyebrow") or name.contains("eyes") or (name.contains("head") and not name.contains("hood") and not name.contains("circlet")) or material.contains("Regular_Female")
		if protected:
			found=true
			if not state_unchanged(before[index],after[index]): return false
	return found

func all_gear(quality: String) -> Dictionary:
	var result: Dictionary={}
	for slot in SLOTS: result[slot]={"quality":quality,"tier":3,"temper":4,"attack":113,"armor":27}
	return result

func run_checks() -> void:
	for key in Actor.HEROES:
		var actor:=make_actor(key); var peer:=make_actor(key)
		var baseline:=materials(actor); var peer_before:=materials(peer)
		check(actor.source_avatar and not actor.model.visible and baseline.size()>8,key+": tests inspect the visible native figure and held weapon, beyond the hidden proxy")
		var geometry_matches:=baseline.size()==peer_before.size(); var shared_meshes:=0; var overrides_independent:=geometry_matches
		for index in baseline.size():
			geometry_matches=geometry_matches and baseline[index].vertices==peer_before[index].vertices and baseline[index].indices==peer_before[index].indices and baseline[index].skin==peer_before[index].skin
			if baseline[index].mesh==peer_before[index].mesh: shared_meshes+=1
			overrides_independent=overrides_independent and baseline[index].material!=peer_before[index].material
		check(geometry_matches and shared_meshes>=actor.motion_rig.surfaces.size() and overrides_independent,key+": native body sources share meshes/skins, fitted weapon geometry matches, and all materials are independent")
		var observed_slot_groups: Dictionary={}
		for slot in SLOTS:
			var equipment: Dictionary={slot:{"quality":"LEGENDARY","tier":3,"temper":4,"attack":113,"armor":27}}
			var authority:=JSON.stringify(equipment)
			actor.configure_equipment(equipment,key)
			var equipped:=materials(actor)
			var changed:=0; var held_weapon_changed:=false; var local:=true
			var changed_surfaces: Dictionary={}
			for index in baseline.size():
				if baseline[index].color!=equipped[index].color or baseline[index].roughness!=equipped[index].roughness:
					changed+=1
					changed_surfaces[index]=true
					held_weapon_changed=held_weapon_changed or String(equipped[index].name).begins_with("Weapon__")
					local=local and equipped[index].roughness<=baseline[index].roughness and baseline[index].roughness-equipped[index].roughness<=.032001 and equipped[index].color.a==baseline[index].color.a
			check(changed>0 and (slot!="Weapon" or held_weapon_changed) and local,key+" "+slot+": real visible equipment changes with restrained pigment/finish, including the held weapon")
			check(snapshots_equal(baseline,equipped,false) and facial(baseline,equipped),key+" "+slot+": textures, skin, vertices, facial features, exposed hands and emission remain unchanged")
			check(snapshots_equal(peer_before,materials(peer)) and JSON.stringify(equipment)==authority and actor.equipped_items==equipment,key+" "+slot+": peer appearance and authoritative equipment data remain isolated")
			actor.configure_equipment(equipment,key)
			check(snapshots_equal(equipped,materials(actor)),key+" "+slot+": repeated equip cannot accumulate tint or finish drift")
			actor.configure_equipment(all_gear("COMMON"),key)
			check(snapshots_equal(baseline,materials(actor)),key+" "+slot+": Common restores every original styled PBR value exactly")
			actor.configure_equipment({},key)
			check(snapshots_equal(baseline,materials(actor)),key+" "+slot+": unequip also restores the original visible finish exactly")
			observed_slot_groups[slot]=changed_surfaces
		var independent_slots:=true
		for index in SLOTS.size()-1:
			for other in range(index+1,SLOTS.size()):
				for surface in observed_slot_groups[SLOTS[index]]:
					independent_slots=independent_slots and not observed_slot_groups[SLOTS[other]].has(surface)
		check(independent_slots,key+": six observed equipment channels change separate real surfaces without overriding or compounding each other")
		actor.configure_equipment(all_gear("RARE"),key)
		var rare:=materials(actor)
		var legendary:=all_gear("LEGENDARY")
		actor.configure_equipment(legendary,key)
		var battle:=materials(actor)
		var ranks_differ:=false; var polish_progresses:=true
		for index in rare.size():
			ranks_differ=ranks_differ or rare[index].color!=battle[index].color or rare[index].roughness!=battle[index].roughness
			polish_progresses=polish_progresses and rare[index].roughness>=battle[index].roughness
		check(ranks_differ and polish_progresses,key+": Rare and Legendary have distinct native pigments and a bounded progressing finish")
		var portrait:=HeroArt.new(); portrait.configure(key,legendary); portrait.size=Vector2(140,140); root.add_child(portrait)
		portrait.set_presentation(true,true)
		var portrait_before:=materials(portrait.actor)
		var same_finish:=battle.size()==portrait_before.size(); var independent:=same_finish
		for index in mini(battle.size(),portrait_before.size()):
			same_finish=same_finish and state_unchanged(battle[index],portrait_before[index],true,false)
			independent=independent and battle[index].material!=portrait_before[index].material
		check(same_finish and independent,key+": live portrait and battle show the same equipped native finish with independent overrides")
		portrait.configure(key,{})
		check(snapshots_equal(battle,materials(actor)) and snapshots_equal(baseline,materials(portrait.actor),true,false) and facial(baseline,battle),key+": portrait unequip cannot reset battle gear or recolor either face")
		portrait.free(); actor.free(); peer.free()
	# Reusing an actor across classes must bind a new baseline, not carry the
	# previous class's tinted resources into the next source skin.
	var reused:=make_actor("Arcanist")
	for key in ["Vowkeeper","Ranger","Arcanist"]:
		reused.configure_equipment(all_gear("LEGENDARY"),key)
		reused.configure_equipment({},key)
		var fresh:=make_actor(key)
		check(snapshots_equal(materials(reused),materials(fresh),true,false),key+": class switch resets to that class's own exact source finish")
		fresh.free()
	reused.free()
	print("NATIVE EQUIPMENT FINISH SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
