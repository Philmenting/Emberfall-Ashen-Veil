extends SceneTree
const Actor=preload("res://scripts/dungeon_actor.gd")
const Budget=preload("res://scripts/render_budget.gd")
const Main=preload("res://scripts/main.gd")
var checks:=0
var failures:=0
func _initialize() -> void: run_checks.call_deferred()
func check(value: bool,message: String) -> void:
	checks+=1
	if value: print("PASS: ",message)
	else: failures+=1; push_error(message)

func run_checks() -> void:
	for kind in ["Vowkeeper","Arcanist","Ranger","boss"]:
		var actor:=Actor.new(); actor.kind=kind; actor.boss=kind=="boss"; root.add_child(actor)
		var mesh: MeshInstance3D=actor.painted_model
		check(actor.find_children("*","MeshInstance3D",true,false).size()==2,kind+": one authored cutout and one contact shadow")
		check(mesh.mesh.get_surface_count()==1 and mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()<=6000,kind+": painted body parts stay in one bounded skinned surface")
		check(actor.atlas_texture!=null and actor.atlas_grid==Vector2(3,2),kind+": six authored poses are loaded from the real class/guardian sheet")
		check(mesh.material_override.get_shader_parameter("atlas_texture")==actor.motion_rig.texture and mesh.skin==actor.motion_rig.skin and actor.motion_rig.skeleton.get_bone_count()==23,kind+": visible painted layers use the native skeleton and skin")
		actor.animate(0.20,true,3.0)
		var walking_blend: float=actor.gait_blend
		actor.animate(1.0/60.0,false,0.0)
		check(actor.gait_blend>0.0 and actor.gait_blend<walking_blend,kind+": stopping retains a fading stride")
		actor.animate(1.0,false)
		check(actor.pose_frame==0,kind+": travel recovery returns to authored idle pose")
		actor.strike(); actor.animate(0.001,false)
		check(actor.pose_frame==3,kind+": actual attack starts in authored windup pose")
		actor.animate(0.30,false)
		check(actor.pose_frame==4 and actor.release_time>=0.0 and mesh.mesh==actor.motion_rig.mesh,kind+": committed action reaches contact while retaining the animated mesh")
		actor.set_telegraph(1.4); actor.animate(0.85,false)
		check(actor.pose_frame==3,kind+": real warning countdown holds the windup longer than a basic swing")
		actor.strike("heavy")
		check(actor.pose_frame==4 and is_zero_approx(actor.telegraph_left),kind+": actual heavy impact clears warning and displays strike immediately")
		actor.die(); actor.animate(0.1,false)
		check(mesh.skin!=null and actor.motion_rig.skeleton.get_bone_pose_rotation(0)!=Quaternion.IDENTITY,kind+": defeat first buckles the visible articulated figure")
		actor.animate(0.6,false)
		check(actor.pose_frame==5 and mesh.skin==null and actor.body.position.is_finite(),kind+": completed collapse settles into the painted fallen figure")
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
