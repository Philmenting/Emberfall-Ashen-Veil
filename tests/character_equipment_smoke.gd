extends SceneTree
## Actual painted-pose, equipment accent and portrait contract; no obsolete rig.
const Actor=preload("res://scripts/dungeon_actor.gd")
const HeroArt=preload("res://scripts/hero_art.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run_checks")
func check(value: bool,message: String) -> void:
	checks+=1
	if value: print("PASS: ",message)
	else: failures+=1; push_error("FAIL: "+message)

func run_checks() -> void:
	var gear: Dictionary={}
	for slot in ["Weapon","Helmet","Chest","Gloves","Boots","Amulet"]: gear[slot]={"quality":"RARE","tier":3,"temper":4,"name":"Actual equipped "+slot}
	var hero:=Actor.new(); hero.configure_equipment(gear,"Arcanist"); root.add_child(hero)
	check(hero.kind=="Arcanist" and hero.equipment_grades.Helmet==2,"pending real class and Helmet data configure when actor enters tree")
	check(hero.atlas_path.ends_with("arcanist.png") and hero.atlas_grid==Vector2(3,2),"Arcanist renders its real six-pose class atlas")
	check(hero.painted_model.mesh.get_surface_count()==1 and hero.painted_model.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()<=2500,"live figure uses one bounded source-alpha polygon surface")
	check(hero.find_children("*","Skeleton3D",true,false).is_empty() and hero.find_children("*","MeshInstance3D",true,false).size()==2,"runtime contains the visible painting and contact shadow without a hidden obsolete model")
	check(hero.equipment_grades.size()==6 and Actor.EQUIPMENT_REGIONS.size()==6,"all six equipped qualities have defined physical accent regions")
	var slots: Dictionary={"Weapon":"weapon","Helmet":"helm","Chest":"chest","Gloves":"gloves","Boots":"boots","Amulet":"accent"}
	var six_bound:=true
	for slot in slots: six_bound=six_bound and float(hero.surface_material.get_shader_parameter(slots[slot]+"_rank"))==2.0
	check(six_bound,"six independent shader accent grades match actual equipped qualities")
	var peer:=Actor.new(); peer.kind="Arcanist"; root.add_child(peer)
	check(peer.atlas_texture==hero.atlas_texture and peer.painted_model.mesh==hero.painted_model.mesh and peer.surface_material!=hero.surface_material,"figures share actual image/pose meshes and isolate equipment materials")
	var before:=hero.atlas_texture
	gear.Weapon.quality="LEGENDARY"
	check(hero.equipment_grades.Weapon==2,"caller mutations cannot silently recolor equipped artwork")
	hero.configure_equipment(gear,"Arcanist")
	check(hero.equipment_grades.Weapon==4 and peer.equipment_grades.Weapon==0 and hero.atlas_texture==before,"weapon rarity updates its physical accent without inventing an item mesh or recoloring peers")
	hero.configure_equipment(gear,"Ranger")
	check(hero.kind=="Ranger" and hero.atlas_texture!=before and hero.atlas_path.ends_with("ranger.png"),"class selection changes to the actual bow-carrying Nyra artwork")
	hero.reduced_motion=true
	var initial_clock:=hero.clock
	hero.animate(0.2,true,3.2)
	check(hero.clock==initial_clock and hero.pose_frame in [1,2],"Reduced Motion freezes decorative clock while actual walking poses remain clear")
	hero.set_telegraph(1.5); hero.animate(0.9,false)
	check(hero.pose_frame==3,"warning longer than a swing holds the authored windup")
	hero.strike("heavy")
	check(hero.pose_frame==4 and is_zero_approx(hero.telegraph_left),"heavy impact immediately selects the real strike pose")
	hero.die(); hero.animate(0.2,false)
	check(hero.pose_frame==5,"defeat renders the authored fallen figure")
	for enemy_kind in Actor.HOSTILE_BLOCKS:
		var enemy:=Actor.new(); enemy.kind=enemy_kind; enemy.hostile=true; root.add_child(enemy)
		check(enemy.atlas_path.ends_with("hostiles.png") and enemy.atlas_grid==Vector2(6,4) and enemy.atlas_origin==Actor.HOSTILE_BLOCKS[enemy_kind],enemy_kind+": correct six-pose block is bound in shared hostile atlas")
		enemy.free()
	var boss:=Actor.new(); boss.boss=true; boss.hostile=true; boss.kind="boss"; root.add_child(boss)
	var other_boss:=Actor.new(); other_boss.boss=true; other_boss.hostile=true; other_boss.kind="boss"; root.add_child(other_boss)
	boss.set_boss_phase(2)
	check(boss.boss_phase==2 and float(boss.surface_material.get_shader_parameter("boss_phase"))==2.0 and other_boss.boss_phase==0,"actual phase emphasis stays independent per guardian")
	check(is_equal_approx(boss.figure_height,4.6) and is_equal_approx(boss.pose_bounds().position.y,0.0),"monumental guardian uses a 4.6-unit idle body scale and actual authored ground anchor")
	for actor in [peer,boss]:
		actor._set_pose(0)
		var idle_scale: float=actor.pixels_per_world_unit
		var idle_height: float=actor.visual_height()
		var mapped:=true
		var finite:=true
		for pose in range(6):
			actor._set_pose(pose)
			mapped=mapped and is_equal_approx(actor.pixels_per_world_unit,idle_scale) and is_equal_approx(actor.pose_bounds().position.y,0.0)
			var arrays: Array=actor.painted_model.mesh.surface_get_arrays(0)
			for vertex in arrays[Mesh.ARRAY_VERTEX]: finite=finite and vertex.is_finite()
			for uv in arrays[Mesh.ARRAY_TEX_UV]: finite=finite and uv.is_finite() and uv.x>=0.0 and uv.y>=0.0 and uv.x<=1.0 and uv.y<=1.0
		check(mapped and finite,actor.kind+": all authored poses preserve one body pixel scale, actual feet and finite source UVs")
		check(actor.visual_height()<idle_height*(.90 if actor.boss else .55),actor.kind+": the actual defeated pose stays low instead of being stretched to idle height")
		actor._set_pose(0)
	var portrait:=HeroArt.new(); portrait.size=Vector2(128,128); portrait.configure("Arcanist",gear); root.add_child(portrait)
	check(portrait.actor.kind=="Arcanist" and portrait.actor.atlas_texture==Actor.ATLAS_TEXTURES.Arcanist and portrait.actor.equipment_grades.Weapon==4,"portrait crops the actual idle class figure with the same real equipped accents")
	portrait.set_presentation(true,true)
	check(not portrait.is_processing() and portrait.viewport.render_target_update_mode==SubViewport.UPDATE_ONCE,"portrait respects Reduced Motion and Battery budgets")
	portrait.configure("Vowkeeper",gear)
	check(portrait.actor.kind=="Vowkeeper" and portrait.actor.atlas_texture==Actor.ATLAS_TEXTURES.Vowkeeper,"portrait class change selects actual sword/shield artwork")
	portrait.free(); hero.free(); peer.free(); boss.free(); other_boss.free()
	print("CHARACTER EQUIPMENT SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
