extends SceneTree
## Live class, six equipped quality accents, shared meshes and lit portraits.
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
	check(hero.model.mesh.get_surface_count()==1 and hero.motion_rig.triangles<=40000,"complete lit volume stays in one surface below 40k triangles")
	check(hero.motion_rig.skeleton.get_bone_count()==29 and hero.model.skin!=null and hero.motion_rig.player.has_animation("walk"),"visible 3D volume binds to a native skeleton and animation player")
	var uniforms: Dictionary={"Weapon":"weapon","Helmet":"helm","Chest":"chest","Gloves":"gloves","Boots":"boots","Amulet":"accent"}
	for slot in uniforms:
		check(hero.equipment_grades[slot]==2 and float(hero.surface_material.get_shader_parameter(uniforms[slot]+"_rank"))==2.0,slot+": actual rarity reaches its independent surface accent")
	var peer:=Actor.new(); peer.kind="Arcanist"; root.add_child(peer)
	check(peer.model.mesh==hero.model.mesh and peer.model.skin==hero.model.skin and peer.surface_material!=hero.surface_material,"peers share immutable geometry and skin; equipped materials remain independent")
	var original: Mesh=hero.model.mesh
	gear.Weapon.quality="LEGENDARY"
	check(hero.equipment_grades.Weapon==2,"caller mutation cannot silently alter equipped appearance")
	hero.configure_equipment(gear,"Arcanist")
	check(hero.equipment_grades.Weapon==4 and peer.equipment_grades.Weapon==0 and hero.model.mesh==original,"a weapon quality update keeps the real class mesh and does not recolor peers")
	hero.configure_equipment(gear,"Ranger")
	check(hero.appearance_key=="Ranger" and hero.model.mesh!=original and hero.motion_rig.skeleton.get_bone_parent(20)==7,"Ranger uses its actual bow model held in the left hand")
	for class_key in Actor.HEROES:
		hero.configure_equipment(gear,class_key)
		check(hero.appearance_key==class_key and hero.equipment_grades.Weapon==4,class_key+": changing class retains actual equipped grades")
		var portrait:=HeroArt.new(); portrait.configure(class_key,gear); portrait.size=Vector2(140,140); root.add_child(portrait)
		portrait.set_presentation(true,true)
		check(portrait.actor.appearance_key==class_key and portrait.actor.model.mesh==hero.model.mesh and portrait.actor.equipment_grades.Weapon==4,class_key+": portrait and battle render the same equipped spatial heroine")
		check(portrait.viewport.render_target_update_mode==SubViewport.UPDATE_ONCE and portrait.camera.position.z<0,class_key+": Battery portrait keeps the real face view without continuous rendering")
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
