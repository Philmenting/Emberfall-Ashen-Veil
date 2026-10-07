extends SceneTree
const Actor=preload("res://scripts/dungeon_actor.gd")
var checks:=0
var failures:=0
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures+=1;push_error(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var ranger=Actor.new();ranger.kind="Ranger";root.add_child(ranger);ranger.animate(.15,false)
	check_native_bow_release(ranger)
	ranger.free()
	print("BOW CONTACT DIAGNOSTIC: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
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
	ranger.strike("basic",.6,true);ranger.sync_attack(ranger.PROJECTILE_RELEASE_LEAD);ranger.animate(.15,false)
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
	print("NATIVE_BOW_RELEASE_METRIC line_distance=",recovered_nock.distance_to(returned_line),"; nock_join=",recovered_nock.distance_to(recovered.joins[1]),"; bow_grip_distance=",bow_grip.distance_to(grip_after),"; draw_hand_outward=",hand_displacement.dot(native_outward),"; arrow_visible=",rig.bow_arrow.visible)
	check(recovered.valid and recovered_nock.distance_to(recovered.joins[1])<.0001 and recovered_nock.distance_to(returned_line)<.0001 and not rig.bow_arrow.visible and bow_grip.distance_to(grip_after)<.008 and hand_displacement.dot(native_outward)>.08,"real string returns to its endpoint line while the named bow hand holds aim and native draw hand follows through outward; side="+str(hand_displacement.dot(native_outward)))
