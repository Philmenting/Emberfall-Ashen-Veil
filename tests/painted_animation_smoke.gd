extends SceneTree
## Continuous native animation invariants, actual event timing and GPU budgets.
const Actor=preload("res://scripts/dungeon_actor.gd")
const Sim=preload("res://scripts/expedition_simulation.gd")
const World=preload("res://scripts/dungeon_world.gd")
const Bot=preload("res://tests/balance_survey_bot.gd")
var checks:=0
var failures:=0
var sole_cache: Dictionary={}
func _initialize() -> void: call_deferred("run_checks")
func check(value: bool,message: String) -> void:
	checks+=1
	if value: print("PASS: ",message)
	else: failures+=1; push_error("FAIL: "+message)
func make_actor(key: String) -> Node3D:
	var actor:=Actor.new()
	actor.boss=key.begins_with("guardian_"); actor.hostile=actor.boss or key not in Actor.HEROES
	actor.kind="boss" if actor.boss else key
	if actor.boss: actor.region_index=int(key.right(1))
	root.add_child(actor)
	return actor
func skin_point(actor: Node3D,point: Vector3,bone: int) -> Vector3:
	return actor.motion_rig.bone_point(bone,point)
func sole(actor: Node3D,arrays: Array,foot: int) -> float:
	var key:=str(actor.get_instance_id())+":"+str(foot)
	if not sole_cache.has(key):
		var points:=PackedVector3Array()
		for i in range(arrays[Mesh.ARRAY_VERTEX].size()):
			if int(arrays[Mesh.ARRAY_BONES][i*4+1])==foot and float(arrays[Mesh.ARRAY_WEIGHTS][i*4+1])>.98: points.append(arrays[Mesh.ARRAY_VERTEX][i])
		sole_cache[key]=points
	var lowest:=INF
	var transform: Transform3D=actor.motion_rig.skeleton.get_bone_global_pose(foot)*Transform3D(Basis.IDENTITY,-actor.motion_rig.rest[foot])
	for point: Vector3 in sole_cache[key]: lowest=minf(lowest,(transform*point).y)
	return lowest
func run_checks() -> void:
	for key in ["Vowkeeper","Arcanist","Ranger","raider","bulwark","hexer","elite","guardian_0","guardian_1","guardian_2","guardian_3"]:
		var actor:=make_actor(key)
		var mesh: ArrayMesh=actor.painted_model.mesh
		var arrays: Array=mesh.surface_get_arrays(0)
		var count: int=arrays[Mesh.ARRAY_VERTEX].size()
		check(mesh.get_surface_count()==1 and count<=6000 and actor.motion_rig.skeleton.get_bone_count()==23,key+": complete painted anatomy, one surface, <=6000 vertices and 23 native bones")
		var data: Dictionary=actor.motion_rig.layer_data
		check(data.parts.size()==12 and data.packing=="separate_painted_anatomical_parts" and actor.painted_model.skin.get_bind_count()==23,key+": complete source parts bind to the visible native skin")
		var weights_valid: bool=arrays[Mesh.ARRAY_WEIGHTS].size()==count*4 and arrays[Mesh.ARRAY_BONES].size()==count*4
		var weapon_vertices: Array=[]
		for i in range(count):
			var sum_weights:=0.0
			for j in range(4):
				var weight: float=arrays[Mesh.ARRAY_WEIGHTS][i*4+j]
				var bone: int=arrays[Mesh.ARRAY_BONES][i*4+j]
				weights_valid=weights_valid and is_finite(weight) and weight>=0.0 and bone>=0 and bone<23
				sum_weights+=weight
			weights_valid=weights_valid and absf(sum_weights-1.0)<.0001 and arrays[Mesh.ARRAY_VERTEX][i].is_finite() and arrays[Mesh.ARRAY_TEX_UV][i].is_finite()
			if int(arrays[Mesh.ARRAY_BONES][i*4])==6 and is_equal_approx(float(arrays[Mesh.ARRAY_WEIGHTS][i*4]),1.0): weapon_vertices.append(arrays[Mesh.ARRAY_VERTEX][i])
		check(weights_valid and weapon_vertices.size()>8,key+": finite normalized GPU weights and a rigid weapon panel")
		var source_a: Vector3=weapon_vertices[0]; var source_b: Vector3=weapon_vertices[weapon_vertices.size()/2]
		var weapon_length:=source_a.distance_to(source_b)
		var rigid:=true; var finite:=true; var changing:=0; var grounded:=true; var lifted:=false
		var previous: Transform3D=actor.motion_rig.skeleton.get_bone_global_pose(11)
		var previous_support:=-1; var planted_x:=0.0; var locked:=true
		actor.gait_blend=1.0
		for sample in range(120):
			actor.animate(1.0/60.0,true,3.0)
			var now: Transform3D=actor.motion_rig.skeleton.get_bone_global_pose(11)
			if not now.is_equal_approx(previous): changing+=1
			previous=now
			var phase:=fposmod(actor.gait_phase,TAU)/TAU
			var foot:=12 if phase<.5 else 15
			var world_foot_x: float=float(sample)/60.0*3.0*actor.gait_axis+actor.motion_rig.skeleton.get_bone_global_pose(foot).origin.x
			if foot==previous_support: locked=locked and absf(world_foot_x-planted_x)<.006
			previous_support=foot; planted_x=world_foot_x
			var floor_y:=sole(actor,arrays,foot)
			grounded=grounded and absf(floor_y)<.035
			lifted=lifted or sole(actor,arrays,15 if foot==12 else 12)>.05
			finite=finite and actor.pose_bounds().position.is_finite() and actor.pose_bounds().size.is_finite()
		if not (changing>110 and grounded and lifted): print("GAIT_DIAGNOSTIC ",key," changed=",changing," grounded=",grounded," lifted=",lifted," soles=",sole(actor,arrays,12),"/",sole(actor,arrays,15))
		check(changing>110 and grounded and lifted,key+": continuously changing gait, a grounded support sole and a lifted swing foot")
		check(locked,key+": stance foot compensates actual travel without sliding")
		actor.strike("basic",.5)
		for sample in range(60):
			actor.animate(1.0/60.0,false)
			rigid=rigid and absf(skin_point(actor,source_a,6).distance_to(skin_point(actor,source_b,6))-weapon_length)<.0001
			finite=finite and actor.pose_bounds().size.is_finite()
		check(rigid and finite and actor.painted_model.mesh==mesh and mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==arrays[Mesh.ARRAY_VERTEX],key+": swings preserve blade length and cached source geometry without CPU rewrites")
		actor.die(); actor.animate(.18,false)
		check(actor.death_time>0.0 and actor.painted_model.mesh==mesh and absf(actor.joint_angles[0])>.05,key+": defeat first buckles and falls rather than instantly swapping a still")
		actor.animate(.5,false)
		check(actor.pose_frame==5 and actor.painted_model.mesh!=mesh and actor.painted_model.skin==null,key+": collapse ends in the original calibrated fallen painting")
		actor.free()
	var hero:=make_actor("Vowkeeper")
	hero.strike("basic",.6,true)
	hero.sync_attack(.4); hero.animate(.03,false)
	var before: PackedFloat32Array=hero.joint_angles.duplicate()
	hero.animate(0,false)
	check(hero.joint_angles==before and hero.release_time<0,"zero-time/pause keeps windup stationary and cannot create a hit")
	hero.animate(1,false)
	check(hero.release_time<0,"simulation-driven casts cannot release just because renderer time elapsed")
	hero.sync_attack(.02); hero.animate(.016,false)
	check(hero.release_attack() and not hero.release_attack() and hero.pose_frame==4,"actual hit releases once, including multi-target attacks")
	hero.animate(.4,false)
	hero.strike("basic",.6,true); hero.retreat(); hero.animate(.06,true,3)
	check(hero.attack_time<0 and hero.release_time<0 and hero.retreat_time>=0,"a real dodge cancels the pending cast and enters a retreat stance")
	hero.reduced_motion=true; hero.retreat_time=-1; hero.gait_blend=0; hero.impact_time=-1
	var reduced_clock: float=hero.clock
	hero.animate(.2,false)
	var reduced_pose: PackedFloat32Array=hero.joint_angles.duplicate()
	hero.animate(.2,false)
	check(hero.clock==reduced_clock and hero.joint_angles==reduced_pose,"Reduced Motion holds a still idle without decorative motion")
	hero.strike("basic",.3); hero.animate(.3,false)
	check(hero.pose_frame==4 and absf(hero.joint_angles[3])>.3,"Reduced Motion retains essential readable weapon contact")
	hero.free()
	var ranger:=make_actor("Ranger")
	ranger.strike("basic",.6,true); ranger.sync_attack(.2); ranger.animate(.016,false)
	var draw: Vector3=ranger.motion_rig.skeleton.get_bone_global_pose(21).origin
	var straight: Vector3=(ranger.motion_rig.skeleton.get_bone_global_pose(20).origin+ranger.motion_rig.skeleton.get_bone_global_pose(22).origin)*.5
	check(draw.distance_to(straight)>.12,"Ranger actually pulls the GPU-skinned bowstring while drawing")
	ranger.release_attack()
	draw=ranger.motion_rig.skeleton.get_bone_global_pose(21).origin
	straight=(ranger.motion_rig.skeleton.get_bone_global_pose(20).origin+ranger.motion_rig.skeleton.get_bone_global_pose(22).origin)*.5
	check(draw.distance_to(straight)<.001,"bowstring springs straight at the actual release")
	ranger.free()
	var game:=Bot.new(); game.character_class="Arcanist"
	var stats: Dictionary=game._combat_stats()
	var sim:=Sim.new(); var reference:=Sim.new()
	sim.setup("Arcanist",stats,1,"Guardian",1979); reference.setup("Arcanist",stats,1,"Guardian",1979)
	var world:=World.new(); world.simulation=sim; world.character_class="Arcanist"; world.active=false; root.add_child(world); world.set_process(false); world.active=true
	var same:=true; var hit_count:=0; var synchronized:=true; var projectile_seen:=false
	for frame in range(360):
		world._process(1.0/60.0)
		var events: Array=reference.advance(1.0/60.0)
		same=same and sim.encode_snapshot()==reference.encode_snapshot()
		for event: Dictionary in events:
			if event.type=="hit":
				hit_count+=1; synchronized=synchronized and world.hero.release_time>=0.0 and world.hero.pose_frame==4
		for effect: Dictionary in world.effects:
			if effect.kind=="projectile": projectile_seen=true; synchronized=synchronized and effect.life<=.085
	check(same,"running the new animation never changes damage, combat timing, loot or simulation RNG")
	check(hit_count>=2 and synchronized and projectile_seen,"real hits reach contact; short projectiles arrive during the actual damage frame")
	world.free(); game.free()
	print("PAINTED ANIMATION SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
