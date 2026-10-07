extends SceneTree
const Actor=preload("res://scripts/dungeon_actor.gd")
const Budget=preload("res://scripts/render_budget.gd")
const Main=preload("res://scripts/main.gd")
const SourceSkin=preload("res://tests/source_avatar_skin.gd")
const SOURCE_SURFACE_COUNTS={"Arcanist":8,"Vowkeeper":10,"Ranger":12,"raider":8}
const ACCESSORY_COUNTS={"Arcanist":11,"Vowkeeper":3,"Ranger":0,"raider":0}
var checks:=0
var failures:=0
func _initialize() -> void: run_checks.call_deferred()
func check(value: bool,message: String) -> void:
	checks+=1
	if value: print("PASS: ",message)
	else: failures+=1; push_error(message)

func run_checks() -> void:
	for kind in ["Vowkeeper","Arcanist","Ranger","raider","boss"]:
		var actor:=Actor.new(); actor.kind=kind; actor.boss=kind=="boss"; actor.hostile=kind in ["raider","boss"]; root.add_child(actor)
		var mesh: MeshInstance3D=actor.model
		var source_geometry: Array=[]
		if actor.source_avatar:
			for surface in complete_source_surfaces(actor): source_geometry.append([surface,surface.mesh,surface.skin])
			check(source_surfaces_rendered(actor) and actor.get_node_or_null("ContactShadow") is MeshInstance3D,kind+": complete class-specific rendered source surfaces and accessories plus contact shadow; compatibility proxy stays hidden")
			var material_slots_present:=true
			for surface in complete_source_surfaces(actor):
				material_slots_present=material_slots_present and surface.mesh.get_surface_count()>0
				for slot in surface.mesh.get_surface_count():
					material_slots_present=material_slots_present and surface.get_active_material(slot)!=null
			var visible_triangles:=actual_visible_triangles(actor.motion_rig)
			var triangle_budget:=20000 if kind=="raider" else 40000
			check(actor.motion_rig.surfaces.size()==SOURCE_SURFACE_COUNTS[kind] and material_slots_present and visible_triangles<=triangle_budget and actor.motion_rig.rendered_triangles<=triangle_budget,kind+": exact class source mesh inventory, bound material slots and full actual outfit/accessory/weapon triangle budget; visible="+str(visible_triangles))
			check(complete_source_bounds(actor).size.z>.30,kind+": all four skin influences give the complete rendered figure and accessories real depth")
			check(source_surfaces_rendered(actor) and actor.motion_rig.skeleton.get_bone_count()==65 and actor.motion_rig.player.has_animation("Walk_Loop") and actor.motion_rig.player.has_animation("Death01"),kind+": original native65 skin and authored walking/death clips drive the visible surfaces")
		else:
			check(actor.find_children("*","MeshInstance3D",true,false).size()==2,kind+": one volumetric surface and one contact shadow")
			check(mesh.mesh.get_surface_count()==1 and actor.motion_rig.triangles<=40000,kind+": lit 3D geometry fits one bounded skinned surface")
			check(mesh.mesh.get_aabb().size.z>.30,kind+": figure has real depth, not a camera-facing card")
			check(mesh.skin==actor.motion_rig.skin and actor.motion_rig.skeleton.get_bone_count()==29 and actor.motion_rig.player.has_animation("death"),kind+": native skeleton and AnimationPlayer drive the visible volume")
		actor.animate(0.20,true,3.0)
		if actor.source_avatar:
			check(actor.motion_rig.player.current_animation=="Walk_Loop" and complete_source_bounds(actor).size.z>.30,kind+": actual walking samples the authored clip on the complete visible weighted surfaces")
		var walking_blend: float=actor.gait_blend
		actor.animate(1.0/60.0,false,0.0)
		check(actor.gait_blend>0.0 and actor.gait_blend<walking_blend,kind+": stopping retains a fading stride")
		actor.animate(1.0,false)
		check(actor.pose_frame==0,kind+": travel recovery returns to 3D guard pose")
		actor.strike(); actor.animate(0.001,false)
		check(actor.pose_frame==3,kind+": actual attack starts in authored spatial windup")
		actor.animate(0.30,false)
		if actor.source_avatar:
			check(actor.pose_frame==4 and actor.release_time>=0.0 and source_geometry_unchanged(actor,source_geometry),kind+": committed action reaches contact while retaining all actual authored meshes and skins")
		else:
			check(actor.pose_frame==4 and actor.release_time>=0.0 and mesh.mesh==actor.motion_rig.mesh,kind+": committed action reaches contact while retaining the animated mesh")
		actor.set_telegraph(1.4); actor.animate(0.85,false)
		check(actor.pose_frame==3,kind+": real warning countdown holds the windup longer than a basic swing")
		actor.strike("heavy")
		check(actor.pose_frame==4 and is_zero_approx(actor.telegraph_left),kind+": actual heavy impact clears warning and displays strike immediately")
		actor.die(); actor.animate(0.1,false)
		if actor.source_avatar:
			var pelvis: int=actor.motion_rig.skeleton.find_bone("pelvis")
			check(source_surfaces_rendered(actor) and actor.motion_rig.player.current_animation=="Death01" and actor.motion_rig.skeleton.get_bone_global_pose(pelvis).origin.y<actor.motion_rig.rest[pelvis].origin.y-.10,kind+": authored defeat lowers the actual native pelvis and articulated surfaces")
		else:
			check(mesh.skin!=null and actor.motion_rig.skeleton.get_bone_pose_position(1).y<actor.motion_rig.rest[1].origin.y-.10,kind+": defeat first buckles the visible articulated figure")
		actor.animate(1.0,false)
		if actor.source_avatar:
			check(actor.pose_frame==5 and source_geometry_unchanged(actor,source_geometry) and actor.body.position.is_finite(),kind+": completed collapse retains every original actual body/accessory mesh and skin")
			var floor:=complete_source_bounds(actor).position.y
			check(floor>-.025 and floor<.065,kind+": independently measured complete indexed weighted body and accessories settle above the floor; minimum="+str(floor))
		else:
			check(actor.pose_frame==5 and mesh.skin!=null and actor.body.position.is_finite(),kind+": completed collapse settles into the same skinned 3D figure on the floor")
		actor.free()
	var budget:=Budget.new()
	for frame in range(60*20): budget.sample(1.0/60.0,true)
	check(not budget.reduced,"steady 60 FPS keeps full resolution")
	for frame in range(30*7): budget.sample(1.0/30.0,true)
	check(budget.reduced,"sustained 30 FPS lowers render resolution")
	for frame in range(60*12): budget.sample(1.0/60.0,true)
	check(budget.reduced,"short recovery does not oscillate quality")
	for frame in range(60*12): budget.sample(1.0/60.0,true)
	check(not budget.reduced,"sustained recovery restores full resolution")
	budget.reset()
	for frame in range(30*30): budget.sample(1.0/30.0,false)
	check(not budget.reduced and budget.age==0.0,"paused play does not drive adaptive quality")
	for frame in range(20): budget.sample(1.0,true)
	check(not budget.reduced,"isolated long stalls do not drive adaptive quality")
	for frame in range(80): budget.sample(0.5,true)
	check(budget.reduced,"persistent very slow rendering also lowers quality")
	var game: Node=load("res://Main.tscn").instantiate()
	game.save_store=preload("res://scripts/save_store.gd").new("user://presentation-smoke-"+str(Time.get_ticks_usec()))
	root.add_child(game); game.farm_enabled=false; game.pending_afk_seconds=0; game.offline_job=null
	game._finish_welcome(false); game._start_run(1); game.run_active=false; game.run_arena.animation_enabled=false
	await process_frame
	var before: Dictionary=game.expedition.snapshot()
	var arena_id: int=game.run_arena.get_instance_id()
	check(not game.combat_hud.hero_details.visible and not game.combat_hud.route_details.visible,"combat HUD starts with compact panels")
	game._toggle_combat_details()
	await process_frame
	check(game.combat_hud.hero_details.visible and game.combat_hud.route_details.visible,"details expose skills, resources, objective and map")
	game._toggle_combat_details()
	check(game.expedition.snapshot()==before and game.run_arena.get_instance_id()==arena_id,"opening and closing details preserves combat and the existing camera")
	game.run_arena.budget.age=10.0
	for frame in range(30*7): game.run_arena.budget.sample(1.0/30.0,true)
	game.run_arena._process(1.0/30.0)
	check(game.run_arena.render_container.stretch_shrink==2 and game.expedition.snapshot()==before,"adaptive resolution changes rendering without advancing combat")
	game.run_arena.apply_quality(false,true,false)
	for resolution in [Vector2i(854,480),Vector2i(1200,535),Vector2i(1040,1080)]:
		root.size=resolution
		await process_frame
		await process_frame
		for large_text in [false,true]:
			game._change_preference("large_text",large_text,false)
			for expanded in [false,true]:
				if game.combat_hud.hero_details.visible!=expanded: game._toggle_combat_details()
				await process_frame
				var viewport_rect: Rect2=game.get_global_rect()
				var inside:=true
				for name in ["CombatDetailsToggle","OpenSettings"]:
					var button: Button=game.find_child(name,true,false)
					inside=inside and viewport_rect.encloses(button.get_global_rect()) and button.size.y>=48
				for control in [game.combat_hud.pause,game.combat_hud.repeat]:
					inside=inside and viewport_rect.encloses(control.get_global_rect())
				check(inside,"%dx%d: %s HUD actions fit with %s text and 48-unit targets" % [resolution.x,resolution.y,"expanded" if expanded else "compact","large" if large_text else "standard"])
	game.free()
	print("PRESENTATION SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func source_surfaces_rendered(actor: Node3D) -> bool:
	if not actor.source_avatar or actor.model.visible: return false
	if actor.motion_rig.surfaces.size()!=int(SOURCE_SURFACE_COUNTS.get(actor.appearance_key,-1)): return false
	if source_accessories(actor).size()!=int(ACCESSORY_COUNTS.get(actor.appearance_key,-1)): return false
	for surface in complete_source_surfaces(actor):
		if not surface.is_visible_in_tree() or surface.mesh==null or surface.skin==null or surface.get_node_or_null(surface.skeleton)!=actor.motion_rig.skeleton: return false
	return true

func source_geometry_unchanged(actor: Node3D,original: Array) -> bool:
	var complete:=complete_source_surfaces(actor)
	if not source_surfaces_rendered(actor) or original.size()!=complete.size(): return false
	for index in original.size():
		var surface: MeshInstance3D=complete[index]
		if surface!=original[index][0] or surface.mesh!=original[index][1] or surface.skin!=original[index][2]: return false
	return true

func complete_source_surfaces(actor: Node3D) -> Array:
	var result: Array=actor.motion_rig.surfaces.duplicate()
	result.append_array(source_accessories(actor))
	return result

func source_accessories(actor: Node3D) -> Array:
	return actor.motion_rig.style.accessories if actor.motion_rig.style!=null else []

func complete_source_bounds(actor: Node3D) -> AABB:
	var rig: RefCounted=actor.motion_rig
	var result:=SourceSkin.actual_bounds(rig,source_accessories(actor))
	if actor.appearance_key=="raider":
		for point in rig.weapon_points:
			result=result.expand(rig.motion_node.transform*(rig.weapon.transform*point))
	return result

func actual_visible_triangles(rig: RefCounted) -> int:
	var count:=0
	for part: MeshInstance3D in rig.motion_node.find_children("*","MeshInstance3D",true,false):
		if not part.is_visible_in_tree(): continue
		if part.mesh is ArrayMesh:
			for slot in part.mesh.get_surface_count(): count+=part.mesh.surface_get_arrays(slot)[Mesh.ARRAY_INDEX].size()/3
		elif part.mesh is PrimitiveMesh: count+=part.mesh.get_mesh_arrays()[Mesh.ARRAY_INDEX].size()/3
	return count
