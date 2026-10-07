extends SceneTree
## GPU volumes, physical support, bow release and event-driven contact.
const SourceSkin=preload("res://tests/source_avatar_skin.gd")
const Actor=preload("res://scripts/dungeon_actor.gd")
const Sim=preload("res://scripts/expedition_simulation.gd")
const World=preload("res://scripts/dungeon_world.gd")
const Bot=preload("res://tests/balance_survey_bot.gd")
const SOURCE_SURFACE_COUNTS={"Arcanist":8,"Vowkeeper":10,"Ranger":12,"raider":8}
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
		for slot in range(4): point+=(transforms[arrays[Mesh.ARRAY_BONES][i*4+slot]]*arrays[Mesh.ARRAY_VERTEX][i])*arrays[Mesh.ARRAY_WEIGHTS][i*4+slot]
		minimum=minf(minimum,point.y*actor.body.scale.y)
	return minimum
func run_checks() -> void:
	for key in Actor.HEROES+Actor.HOSTILES+["guardian_0","guardian_1","guardian_2","guardian_3"]:
		var actor:=make_actor(key)
		if actor.source_avatar:
			check_source_avatar(actor)
			actor.free()
			continue
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
	# New attacks contain an actual step. Verify its physical contract at the
	# normal game clock: one continuously loaded sole, a lifted free boot, a
	# landed stance before release, and no translation of the world actor.
	for class_key in Actor.HEROES:
		for style in ["basic","signature"]:
			var fighter:=make_actor(class_key)
			if fighter.source_avatar:
				check_source_cast(fighter,style)
				fighter.free()
				continue
			var arrays: Array=fighter.model.mesh.surface_get_arrays(0)
			var support_bone: int=14 if class_key=="Vowkeeper" else 17
			var step_bone: int=17 if support_bone==14 else 14
			var support_points:=foot_vertices(arrays,support_bone)
			var step_points:=foot_vertices(arrays,step_bone)
			var anchor: Vector3=fighter.motion_rig.skeleton.get_bone_global_pose(support_bone).origin
			var world_start: Transform3D=fighter.transform
			var locked:=true; var clear:=true; var raised:=false; var landed:=false
			var surface_clear:=true; var did_release:=false
			fighter.strike(style,.30,true)
			var launch:=.30 if class_key=="Vowkeeper" else .215
			for frame in range(1,40):
				var elapsed:=float(frame)/60.0
				fighter.sync_attack(maxf(0.0,.30-elapsed)); fighter.animate(1.0/60.0,false)
				if elapsed>=launch and not did_release:
					did_release=true
					fighter.release_attack()
					landed=absf(sole(fighter,step_points,step_bone))<.025
				var point: Vector3=fighter.motion_rig.skeleton.get_bone_global_pose(support_bone).origin
				locked=locked and anchor.distance_to(point)<.012 and fighter.transform==world_start
				clear=clear and absf(sole(fighter,support_points,support_bone))<.025 and sole(fighter,step_points,step_bone)>-.012
				raised=raised or sole(fighter,step_points,step_bone)>.065
				# Skin the actual blended 60-Hz return as well as direct poses;
				# the first 50 ms contained a blade-floor dip between key poses.
				surface_clear=surface_clear and posed_floor(fighter,arrays)>-.01
			check(locked and clear and raised and landed,class_key+" "+style+": normal-speed step clears and lands while its support sole and actor stay fixed")
			var action: String="basic" if style=="basic" else "skill"
			for phase in ["windup","recover"]:
				for progress in [.25,.45,.80,1.0]:
					fighter.motion_rig.pose(phase+"_"+action,progress*(.34 if phase=="recover" else 1.0))
					surface_clear=surface_clear and posed_floor(fighter,arrays)>-.01
			check(surface_clear,class_key+" "+style+": every skinned attack vertex clears the floor through the real 60-Hz windup and return")
			fighter.free()
	var caster:=make_actor("Arcanist")
	caster.strike("basic",.30,true); caster.sync_attack(.085); caster.animate(.215,false)
	var casting_hand: Vector3=caster.motion_rig.palm_position(0)
	var casting_chest: Vector3=caster.motion_rig.motion_node.transform*caster.motion_rig.skeleton.get_bone_global_pose(caster.motion_rig.skeleton.find_bone("spine_03")).origin
	var casting_shoulder: Vector3=caster.motion_rig.motion_node.transform*caster.motion_rig.skeleton.get_bone_global_pose(caster.motion_rig.skeleton.find_bone("upperarm_l")).origin
	# The authored clip reaches straight forward from the left shoulder;
	# its hand must stay on the left side of the torso, without crossing it.
	var own_side:=casting_hand.x<casting_chest.x-.02 if caster.source_avatar else casting_hand.x<casting_shoulder.x-.02
	check(casting_hand.z<casting_chest.z-.35 and own_side,"the casting palm reaches the real forward target plane and stays on its anatomical side")
	caster.free()
	var ranger:=make_actor("Ranger")
	check_native_bow_release(ranger)
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
			var origin_before:Vector3=shooter.projectile_origin()
			var hand_before:Vector3=shooter.body.to_global(shooter.motion_rig.weapon_grip_position()) if shooter.source_avatar else shooter.body.to_global(shooter.motion_rig.skeleton.get_bone_global_pose(11).origin)
			var held:bool=shooter.release_time<0.0
			shooter.release_attack()
			var hand_after:Vector3=shooter.body.to_global(shooter.motion_rig.weapon_grip_position()) if shooter.source_avatar else shooter.body.to_global(shooter.motion_rig.skeleton.get_bone_global_pose(11).origin)
			check(held and tip_before.distance_to(shooter.weapon_world_position())<.025 and hand_before.distance_to(hand_after)<.025,class_key+" "+style+": the actual 85 ms early release has a prepared weapon and continuous grip")
			var launch_point:Vector3=shooter.projectile_origin()
			var emitter:Vector3=shooter.body.to_global(shooter.motion_rig.palm_position(0)) if class_key=="Arcanist" else shooter.weapon_world_position()
			check(origin_before.distance_to(launch_point)<.025 and launch_point.distance_to(emitter)<.001,class_key+" "+style+": the actual casting palm or bow emitter remains continuous at release")
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
	var launched:=0; var palm_launch:=true
	for frame in range(360):
		world._process(1.0/60.0)
		for effect: Dictionary in world.effects:
			if effect.kind=="projectile" and float(effect.age)==0.0:
				launched+=1
				var palm:Vector3=world.hero.body.to_global(world.hero.motion_rig.palm_position(0))
				palm_launch=palm_launch and Vector3(effect.origin).distance_to(palm)<.025 and Vector3(effect.origin).distance_to(world.hero.weapon_world_position())>.25 and world.hero.release_time==0.0
		for event: Dictionary in reference.advance(1.0/60.0):
			if event.type=="hit": hits+=1; synchronized=synchronized and world.hero.release_time>=0.0 and world.hero.pose_frame==4
		same=same and sim.encode_snapshot()==reference.encode_snapshot()
	check(same,"native 3D animation never changes combat timing, damage, loot or simulation RNG")
	check(hits>=2 and synchronized,"visible 3D contact is synchronized to actual damage events")
	check(launched>0 and palm_launch,"actual Arcanist projectiles leave the leading palm on the release frame, clear of the staff tip")
	world.free(); bot.free()
	print("CHARACTER THREE D SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

# The authored native65 ABI is audited by bone names and rendered surfaces.
# Legacy29 actors retain all original tests above. Source casting is a planted
# artist clip; it has no invented procedural attack step to assert.
func check_source_avatar(actor: Node3D) -> void:
	var rig=actor.motion_rig
	var class_key=actor.appearance_key
	var complete_surfaces=rig.surfaces.size()==int(SOURCE_SURFACE_COUNTS.get(class_key,-1))
	for surface in complete_source_surfaces(rig):
		complete_surfaces=complete_surfaces and surface.is_visible_in_tree() and surface.mesh!=null and surface.skin!=null and surface.get_node_or_null(surface.skeleton)==rig.skeleton
	check(rig.skeleton.get_bone_count()==65 and complete_surfaces,class_key+": full native skeleton and complete visible authored surfaces")
	var valid=true
	for surface in complete_source_surfaces(rig):
		for slot in surface.mesh.get_surface_count():
			var a=surface.mesh.surface_get_arrays(slot)
			for index in a[Mesh.ARRAY_VERTEX].size():
				var sum=0.0
				for influence in 4:sum+=a[Mesh.ARRAY_WEIGHTS][index*4+influence]
				valid=valid and absf(sum-1.0)<.0001 and a[Mesh.ARRAY_VERTEX][index].is_finite() and a[Mesh.ARRAY_NORMAL][index].is_finite()
	var triangle_budget:=20000 if class_key=="raider" else 40000
	check(valid and rig.rendered_triangles<=triangle_budget,class_key+": normalized actual body/accessory skin weights, finite geometry and full render budget")
	actor.strike("basic",.30,true);actor.sync_attack(.02);actor.animate(.10,false)
	var before=rig.capture_pose();actor.animate(0,false)
	check(rig.capture_pose()==before and actor.release_time<0.0,class_key+": zero-time update preserves pose and simulation contact")
	actor.animate(1.0,false)
	check(actor.release_time<0.0,class_key+": renderer cannot invent held damage")
	check(actor.release_attack() and not actor.release_attack(),class_key+": actual source contact releases exactly once")
	actor.animate(.5,false);actor.reduced_motion=true;actor.animate(.5,false)
	var quiet=rig.capture_pose();var clock=actor.clock;actor.animate(.3,false)
	check(rig.capture_pose()==quiet and actor.clock==clock,class_key+": Reduced Motion freezes decorative source idle")
	actor.reduced_motion=false;actor.die()
	var floor_clear=true;var final_floor=INF
	for time in [.22,.45,.68,.90]:
		rig.pose("death",time);rig.apply_actor_postprocess(actor,"death",time,0.0,true)
		final_floor=complete_source_bounds(rig).position.y*actor.body.scale.y
		floor_clear=floor_clear and final_floor>-.035
	check(floor_clear and final_floor<.065,class_key+": all actually skinned falling surfaces clear the floor and the corpse rests on it")
func check_source_cast(fighter: Node3D,style: String) -> void:
	var origin=fighter.transform;var clear=true;var released=false
	fighter.strike(style,.30,true)
	for frame in range(1,40):
		var elapsed=float(frame)/60.0
		fighter.sync_attack(maxf(0.0,.30-elapsed));fighter.animate(1.0/60.0,false)
		if elapsed>=.215 and not released:released=fighter.release_attack()
		clear=clear and SourceSkin.actual_bounds(fighter.motion_rig,source_accessories(fighter.motion_rig)).position.y>-.01 and fighter.transform==origin
	check(clear and released,fighter.appearance_key+" "+style+": actual 60-Hz source cast and recovery stay grounded without moving the world actor")

func complete_source_surfaces(rig: RefCounted) -> Array:
	var result: Array=rig.surfaces.duplicate()
	result.append_array(source_accessories(rig))
	return result

func source_accessories(rig: RefCounted) -> Array:
	return rig.style.accessories if rig.style!=null else []

func complete_source_bounds(rig: RefCounted) -> AABB:
	var result:=SourceSkin.actual_bounds(rig,source_accessories(rig))
	if rig.key=="raider":
		for point in rig.weapon_points:
			result=result.expand(rig.motion_node.transform*(rig.weapon.transform*point))
	return result

func indexed_axis_endpoints(mesh: Mesh,axis: int) -> PackedVector3Array:
	# Recover the real mesh's endpoint-ring centres from indexed vertices;
	# no legacy bone index, guessed cylinder height or arrow nock coordinate.
	var points:=PackedVector3Array()
	var unique_positions: Dictionary={}
	var slots:=1 if mesh is PrimitiveMesh else mesh.get_surface_count()
	for slot in slots:
		var arrays: Array=mesh.get_mesh_arrays() if mesh is PrimitiveMesh else mesh.surface_get_arrays(slot)
		var used: Dictionary={}
		for index in arrays[Mesh.ARRAY_INDEX]: used[index]=true
		for index in used:
			var point: Vector3=arrays[Mesh.ARRAY_VERTEX][index]
			# UV/normal seams duplicate the same endpoint-ring position. Count
			# each actual geometric point once so a seam cannot bias its centre.
			var key:=Vector3i(roundi(point.x*10000000),roundi(point.y*10000000),roundi(point.z*10000000))
			if not unique_positions.has(key): points.append(point);unique_positions[key]=true
	if points.is_empty(): return PackedVector3Array()
	var low:=INF;var high:=-INF
	for point in points: low=minf(low,point[axis]);high=maxf(high,point[axis])
	var low_sum:=Vector3.ZERO;var high_sum:=Vector3.ZERO
	var low_count:=0;var high_count:=0
	for point in points:
		if absf(point[axis]-low)<.000001: low_sum+=point;low_count+=1
		if absf(point[axis]-high)<.000001: high_sum+=point;high_count+=1
	return PackedVector3Array([low_sum/float(low_count),high_sum/float(high_count)])

func actual_string_geometry(rig: RefCounted) -> Dictionary:
	var joins: Array[Vector3]=[];var ends: Array[Vector3]=[]
	var valid: bool=rig.bow_strings.size()==2
	for string: MeshInstance3D in rig.bow_strings:
		valid=valid and string.is_visible_in_tree() and string.mesh is CylinderMesh
		var endpoints:=indexed_axis_endpoints(string.mesh,1)
		if endpoints.size()!=2: return {"valid":false,"joins":joins,"ends":ends}
		joins.append(rig.weapon.transform*(string.transform*endpoints[0]))
		ends.append(rig.weapon.transform*(string.transform*endpoints[1]))
		valid=valid and joins.back().distance_to(ends.back())>.10
	return {"valid":valid,"joins":joins,"ends":ends}

func check_native_bow_release(ranger: Node3D) -> void:
	var rig=ranger.motion_rig;var skeleton: Skeleton3D=rig.skeleton
	var left_hand:=skeleton.find_bone("hand_l");var right_hand:=skeleton.find_bone("hand_r")
	ranger.strike("basic",.6,true);ranger.sync_attack(.10);ranger.animate(.15,false)
	var drawn:=actual_string_geometry(rig)
	var physical_strings: bool=drawn.valid and drawn.joins.size()==2 and drawn.ends.size()==2
	check(physical_strings,"Ranger draws two visible indexed volumetric string meshes")
	if not physical_strings: return
	var nock: Vector3=drawn.joins[0]
	var straight: Vector3=Geometry3D.get_closest_point_to_segment(nock,drawn.ends[0],drawn.ends[1])
	check(nock.distance_to(straight)>.16 and nock.distance_to(drawn.joins[1])<.0001,"Ranger physically draws both real string segments more than16cm from their original endpoint chord")
	var hook: Vector3=skeleton.get_bone_global_pose(right_hand)*rig.class_pose_state.hook_local
	var pad:=Vector3.ZERO
	for influence in rig.bow_hook_probe.bones.size():
		pad+=(skeleton.get_bone_global_pose(rig.bow_hook_probe.bones[influence])*rig.bow_hook_probe.binds[influence]*rig.bow_hook_probe.point)*rig.bow_hook_probe.weights[influence]
	var shaft:=rig.bow_arrow.find_child("Arrow__leather",false,false) as MeshInstance3D
	check(shaft!=null and shaft.mesh!=null,"Ranger keeps the actual original indexed arrow shaft prop")
	if shaft==null or shaft.mesh==null: return
	var shaft_endpoints:=indexed_axis_endpoints(shaft.mesh,2)
	var shaft_begin: Vector3=rig.weapon.transform*(rig.bow_arrow.transform*(shaft.transform*shaft_endpoints[0]))
	var shaft_end: Vector3=rig.weapon.transform*(rig.bow_arrow.transform*(shaft.transform*shaft_endpoints[1]))
	var shaft_contact:=Geometry3D.get_closest_point_to_segment(nock,shaft_begin,shaft_end)
	check(left_hand>=0 and right_hand>=0 and rig.bow_arrow.visible and nock.distance_to(hook)<.0001 and absf(nock.distance_to(pad)-.0028)<.0001 and nock.distance_to(shaft_contact)<.0001,"named native draw hand and actual weighted finger pad meet the real indexed arrow shaft and string nock")
	var release_hand: Vector3=skeleton.get_bone_global_pose(right_hand).origin
	var bow_grip: Vector3=skeleton.get_bone_global_pose(left_hand)*rig.bow_grip_center
	var released: bool=ranger.release_attack()
	var contact:=actual_string_geometry(rig)
	check(released and ranger.release_time==0.0 and not rig.bow_arrow.visible and contact.joins[0].distance_to(nock)<.0001 and contact.joins[1].distance_to(nock)<.0001,"real release immediately hides the held arrow while both physical string segments remain continuous before recoil")
	ranger.animate(.085,false)
	var recovered:=actual_string_geometry(rig)
	var recovered_nock: Vector3=recovered.joins[0]
	var returned_line: Vector3=Geometry3D.get_closest_point_to_segment(recovered_nock,recovered.ends[0],recovered.ends[1])
	var native_outward: Vector3=skeleton.get_bone_global_rest(right_hand).origin-skeleton.get_bone_global_rest(skeleton.find_bone("spine_03")).origin
	native_outward.y=0.0;native_outward=native_outward.normalized()
	var hand_displacement: Vector3=skeleton.get_bone_global_pose(right_hand).origin-release_hand
	var grip_after: Vector3=skeleton.get_bone_global_pose(left_hand)*rig.bow_grip_center
	check(recovered.valid and recovered_nock.distance_to(recovered.joins[1])<.0001 and recovered_nock.distance_to(returned_line)<.0001 and not rig.bow_arrow.visible and bow_grip.distance_to(grip_after)<.008 and hand_displacement.dot(native_outward)>.08,"real string returns to its endpoint line while the named bow hand holds aim and native draw hand follows through outward; side="+str(hand_displacement.dot(native_outward)))
