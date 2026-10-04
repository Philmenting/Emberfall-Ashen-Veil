extends SceneTree
## GPU volumes, physical support, bow release and event-driven contact.
const Actor=preload("res://scripts/dungeon_actor.gd")
const Sim=preload("res://scripts/expedition_simulation.gd")
const World=preload("res://scripts/dungeon_world.gd")
const Bot=preload("res://tests/balance_survey_bot.gd")
var checks:=0
var failures:=0
func _initialize() -> void: run_checks.call_deferred()
func check(value: bool,label: String) -> void:
	checks+=1
	if not value: failures+=1; push_error("FAIL: "+label)
func make_actor(key: String) -> Node3D:
	var actor:=Actor.new(); actor.boss=key.begins_with("guardian_")
	actor.hostile=actor.boss or key not in Actor.HEROES; actor.kind="boss" if actor.boss else key
	if actor.boss: actor.region_index=int(key.right(1))
	root.add_child(actor); actor.animate(.15,false)
	return actor
func skin_point(actor: Node3D,point: Vector3,bone: int) -> Vector3:
	return actor.motion_rig.skeleton.get_bone_global_pose(bone)*actor.motion_rig.rest[bone].affine_inverse()*point
func foot_vertices(arrays: Array,bone: int) -> PackedVector3Array:
	var points:=PackedVector3Array()
	for i in arrays[Mesh.ARRAY_VERTEX].size():
		for slot in range(4):
			if int(arrays[Mesh.ARRAY_BONES][i*4+slot])==bone and float(arrays[Mesh.ARRAY_WEIGHTS][i*4+slot])>.999:
				points.append(arrays[Mesh.ARRAY_VERTEX][i]); break
	return points
func sole(actor: Node3D,points: PackedVector3Array,bone: int) -> float:
	var minimum:=INF
	var transform: Transform3D=actor.motion_rig.skeleton.get_bone_global_pose(bone)*actor.motion_rig.rest[bone].affine_inverse()
	for point in points: minimum=minf(minimum,(transform*point).y)
	return minimum
func posed_floor(actor: Node3D,arrays: Array) -> float:
	var transforms: Array[Transform3D]=[]
	for bone in range(29): transforms.append(actor.motion_rig.skeleton.get_bone_global_pose(bone)*actor.motion_rig.rest[bone].affine_inverse())
	var minimum:=INF
	for i in arrays[Mesh.ARRAY_VERTEX].size():
		var point:=Vector3.ZERO
		for slot in range(2): point+=(transforms[arrays[Mesh.ARRAY_BONES][i*4+slot]]*arrays[Mesh.ARRAY_VERTEX][i])*arrays[Mesh.ARRAY_WEIGHTS][i*4+slot]
		minimum=minf(minimum,point.y*actor.body.scale.y)
	return minimum
func run_checks() -> void:
	for key in Actor.HEROES+Actor.HOSTILES+["guardian_0","guardian_1","guardian_2","guardian_3"]:
		var actor:=make_actor(key)
		var mesh: Mesh=actor.model.mesh; var arrays: Array=mesh.surface_get_arrays(0)
		var valid:=true; var weapon: Array[Vector3]=[]; var normals_3d:=false
		for i in arrays[Mesh.ARRAY_VERTEX].size():
			var sum:=0.0
			for slot in range(4): sum+=arrays[Mesh.ARRAY_WEIGHTS][i*4+slot]
			valid=valid and absf(sum-1.0)<.0001 and arrays[Mesh.ARRAY_VERTEX][i].is_finite() and arrays[Mesh.ARRAY_NORMAL][i].is_finite()
			normals_3d=normals_3d or absf(arrays[Mesh.ARRAY_NORMAL][i].x)>.6
			if int(arrays[Mesh.ARRAY_BONES][i*4])==20 and float(arrays[Mesh.ARRAY_WEIGHTS][i*4])>.999: weapon.append(arrays[Mesh.ARRAY_VERTEX][i])
		check(valid and normals_3d and mesh.get_aabb().size.z>.30,key+": normalized GPU weights, spatial normals and real model depth")
		check(actor.motion_rig.skeleton.get_bone_count()==29 and actor.motion_rig.library.get_animation_list().size()==9,key+": complete walk, guard, basic, skill, heavy and death animation library")
		var soles: Dictionary={14:foot_vertices(arrays,14),17:foot_vertices(arrays,17)}
		var finite:=true; var grounded:=true; var lifted:=false; var locked:=true
		var previous:=Vector3.ZERO; var old_support:=-1
		for frame in range(120):
			var displacement:=Vector3(0,0,-2.0/60.0)
			actor.position+=displacement; actor.follow_travel(displacement); actor.animate(1.0/60.0,true,2.0)
			var support:=0 if fposmod(actor.gait_phase,TAU)<PI else 1
			var foot:=14 if support==0 else 17
			var planted: Vector3=actor.body.to_global(actor.motion_rig.skeleton.get_bone_global_pose(foot).origin)
			if frame>12 and support==old_support: locked=locked and planted.distance_to(previous)<.008
			previous=planted; old_support=support
			if frame>12:
				grounded=grounded and absf(sole(actor,soles[foot],foot))<.04
				lifted=lifted or sole(actor,soles[17 if foot==14 else 14],17 if foot==14 else 14)>.07
			finite=finite and actor.pose_bounds().position.is_finite() and actor.pose_bounds().size.is_finite()
		check(finite and grounded and lifted,key+": stance sole stays on the floor while the other boot clears it")
		check(locked,key+": stance foot stays planted in world space during actual travel")
		actor.animate(.4,false); actor.strike("basic",.5,true); actor.sync_attack(.02); actor.animate(.10,false)
		var before: Array[Transform3D]=actor.motion_rig.capture_pose()
		actor.animate(0,false)
		check(actor.motion_rig.capture_pose()==before and actor.release_time<0.0,key+": zero-time frame cannot move a pose or invent contact")
		actor.animate(1.0,false)
		check(actor.release_time<0.0,key+": renderer time cannot release a simulation-held cast")
		check(actor.release_attack() and not actor.release_attack() and actor.pose_frame==4,key+": actual hit reaches contact once")
		var rigid:=true
		if weapon.size()>3:
			var length:=weapon[0].distance_to(weapon[weapon.size()/2])
			for frame in range(22):
				actor.animate(1.0/60.0,false)
				rigid=rigid and absf(skin_point(actor,weapon[0],20).distance_to(skin_point(actor,weapon[weapon.size()/2],20))-length)<.0002
		check(rigid and actor.model.mesh==mesh,key+": recovering preserves weapon length and immutable cached vertices")
		actor.reduced_motion=true; actor.animate(.5,false)
		var quiet: Array[Transform3D]=actor.motion_rig.capture_pose(); var quiet_clock: float=actor.clock
		actor.animate(.3,false)
		check(actor.clock==quiet_clock and actor.motion_rig.capture_pose()==quiet,key+": Reduced Motion freezes the decorative idle")
		actor.reduced_motion=false; actor.die(); actor.animate(.22,false)
		var crouch: float=actor.motion_rig.skeleton.get_bone_pose_position(1).y
		actor.animate(1.1,false)
		check(crouch<actor.motion_rig.rest[1].origin.y-.10 and actor.pose_frame==5 and actor.model.mesh==mesh and actor.model.skin!=null,key+": knees buckle and the same skinned 3D body settles without a pose-sheet swap")
		var floor_clear:=true; var final_floor:=INF
		for time in [.22,.45,.68,.90]:
			actor.motion_rig.pose("death",time)
			final_floor=posed_floor(actor,arrays)
			floor_clear=floor_clear and final_floor>-.035
		check(floor_clear and final_floor<.065,key+": the complete falling surface clears the floor and its final corpse rests on it")
		var left_fold: float=actor.motion_rig.skeleton.get_bone_pose_rotation(13).get_angle()
		var right_fold: float=actor.motion_rig.skeleton.get_bone_pose_rotation(16).get_angle()
		check(absf(left_fold-right_fold)>.25 and actor.motion_rig.skeleton.get_bone_pose_rotation(3).get_angle()>.30,key+": the settled body has articulated unequal legs and a turned head")
		var variants_grounded:=true
		for lean in [-1.0,0.0,1.0]:
			actor.death_lean=lean; actor.animate(0.0,false)
			var actual_floor:float=posed_floor(actor,arrays)
			variants_grounded=variants_grounded and actual_floor>-.035 and actual_floor<.065
		check(variants_grounded,key+": all actual runtime corpse variants rest on the same floor")
		actor.free()
	var ranger:=make_actor("Ranger")
	ranger.strike("basic",.6,true); ranger.sync_attack(.10); ranger.animate(.15,false)
	var draw: Vector3=ranger.motion_rig.skeleton.get_bone_global_pose(22).origin
	var straight: Vector3=(ranger.motion_rig.skeleton.get_bone_global_pose(21).origin+ranger.motion_rig.skeleton.get_bone_global_pose(23).origin)*.5
	check(draw.distance_to(straight)>.16,"Ranger draws the actual volumetric bowstring")
	check(ranger.motion_rig.skeleton.get_bone_global_pose(11).origin.distance_to(draw)<.06,"draw hand reaches the real nock rather than empty space")
	ranger.release_attack()
	draw=ranger.motion_rig.skeleton.get_bone_global_pose(22).origin
	straight=(ranger.motion_rig.skeleton.get_bone_global_pose(21).origin+ranger.motion_rig.skeleton.get_bone_global_pose(23).origin)*.5
	check(draw.distance_to(straight)<.001 and ranger.motion_rig.skeleton.get_bone_pose_scale(24).length()<.001,"real release straightens the string and releases the held arrow")
	ranger.free()
	# The renderer launches ranged basic/signature projectiles before damage.
	# A full draw/cast must already be ready at that real frame, or the weapon
	# snaps between its unfinished preparation and the contact pose.
	for class_key in ["Arcanist","Ranger"]:
		for style in ["basic","signature"]:
			var shooter:=make_actor(class_key)
			shooter.strike(style,.30,true)
			for frame in range(1,14):
				shooter.sync_attack(.30-float(frame)/60.0)
				shooter.animate(1.0/60.0,false)
			var tip_before:Vector3=shooter.weapon_world_position()
			var hand_before:Vector3=shooter.body.to_global(shooter.motion_rig.skeleton.get_bone_global_pose(11).origin)
			var held:bool=shooter.release_time<0.0
			shooter.release_attack()
			var hand_after:Vector3=shooter.body.to_global(shooter.motion_rig.skeleton.get_bone_global_pose(11).origin)
			check(held and tip_before.distance_to(shooter.weapon_world_position())<.025 and hand_before.distance_to(hand_after)<.025,class_key+" "+style+": the actual 85 ms early release has a prepared weapon and continuous grip")
			shooter.free()
	var raider:=make_actor("raider")
	var resting_tip:Vector3=raider.weapon_world_position()
	raider.anticipation=.70; raider.animate(.15,false)
	check(raider.attack_time<0.0 and raider.release_time<0.0 and resting_tip.distance_to(raider.weapon_world_position())>.12,"ordinary hostile visibly prepares during its real cooldown without inventing a hit")
	raider.free()
	var bot:=Bot.new(); bot.character_class="Arcanist"
	var sim:=Sim.new(); var reference:=Sim.new()
	sim.setup("Arcanist",bot._combat_stats(),1,"Guardian",1979); reference.setup("Arcanist",bot._combat_stats(),1,"Guardian",1979)
	var world:=World.new(); world.simulation=sim; world.character_class="Arcanist"; world.active=false; root.add_child(world); world.set_process(false); world.active=true
	var same:=true; var hits:=0; var synchronized:=true
	for frame in range(360):
		world._process(1.0/60.0)
		for event: Dictionary in reference.advance(1.0/60.0):
			if event.type=="hit": hits+=1; synchronized=synchronized and world.hero.release_time>=0.0 and world.hero.pose_frame==4
		same=same and sim.encode_snapshot()==reference.encode_snapshot()
	check(same,"native 3D animation never changes combat timing, damage, loot or simulation RNG")
	check(hits>=2 and synchronized,"visible 3D contact is synchronized to actual damage events")
	world.free(); bot.free()
	print("CHARACTER THREE D SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
