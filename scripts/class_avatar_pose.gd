extends RefCounted
## Bow draw/release is fitted in the original native65 space. Two complete
## arm chains retain authored lengths, and the real string meets the actual
## index/middle draw hook. Simulation alone decides when an arrow is released.

static func apply_bow(rig: RefCounted,clip: String,time: float,after_blend: bool=false) -> void:
	if clip=="death":return
	var recovering=clip.begins_with("recover")
	var casting=clip.begins_with("windup") or recovering
	var action=clip.get_slice("_",1) if casting else "basic"
	var phase=clampf(time/rig.RECOVERY if recovering else time,0,1)
	var draw=0.0
	var aim=0.0
	var peak=.36 if action=="basic" else (.42 if action=="skill" else .45)
	if casting:
		if recovering:
			draw=(1.0-smoothstep(0,.13,phase))*peak
			aim=1.0-smoothstep(.42,1.0,phase)
		else:
			draw=smoothstep(.08,.78 if action=="basic" else .90,phase)*peak
			aim=smoothstep(0,.36,phase)
	var skeleton: Skeleton3D=rig.skeleton
	if not after_blend:
		var turn=-.22-.30*aim
		for names in [["pelvis",.22],["spine_01",.28],["spine_03",.50]]:
			var bone=skeleton.find_bone(names[0])
			rig._global_rotation(bone,Basis(Vector3.UP,turn*float(names[1]))*skeleton.get_bone_global_pose(bone).basis)
		var head=skeleton.find_bone("Head")
		rig._global_rotation(head,Basis(Vector3.UP,-turn*.48)*skeleton.get_bone_global_pose(head).basis)
	var chest=skeleton.get_bone_global_pose(skeleton.find_bone("spine_03")).origin
	var grip=chest+Vector3(.20,-.20,.16).lerp(Vector3(.17,-.055,.49),aim)
	# Arrow rides above the actual gripping fingers, instead of travelling
	# through the middle of the fist inherited from the legacy prop origin.
	var nock=grip+Vector3(0,rig.bow_rest_height,-(.34+draw)*rig.class_weapon_scale)
	var release=Vector3.ZERO
	if recovering:release=Vector3(-.14,.035,-.045)*sin(smoothstep(0,.44,phase)*PI)
	var hand_basis=rig._frame(Vector3.UP,Vector3.LEFT)*rig.grasp_frame.inverse()
	# The left grip is mirrored from the already measured right aperture.
	# Present the palm toward flight: the shaft sits in front of the wrist,
	# so its lower half clears the actual weighted forearm at a low guard.
	var left_basis=rig._frame(Vector3.UP,Vector3.LEFT)*rig.bow_grasp_frame.inverse()
	var left_hand=grip-left_basis*rig.bow_grip_center
	rig._solve_cast_chain(skeleton.find_bone("upperarm_l"),skeleton.find_bone("lowerarm_l"),skeleton.find_bone("hand_l"),left_hand,Vector3(.65,-.40,-.25))
	rig._global_rotation(skeleton.find_bone("hand_l"),left_basis)
	var hook_local: Vector3=rig.bow_hook_local
	var right_hand=nock+release-hand_basis*hook_local
	rig._solve_cast_chain(skeleton.find_bone("upperarm_r"),skeleton.find_bone("lowerarm_r"),skeleton.find_bone("hand_r"),right_hand,Vector3(-.65,.22,-.48))
	rig._global_rotation(skeleton.find_bone("hand_r"),hand_basis)
	rig.class_pose_state={"draw":draw,"aim":aim,"nocked":casting and not recovering,"hook_local":hook_local}

static func fit_bow_fingers(rig: RefCounted) -> void:
	for bone in rig.bow_grip_pose:rig.skeleton.set_bone_pose_rotation(bone,rig.bow_grip_pose[bone])
	for bone in rig.bow_hook_pose:rig.skeleton.set_bone_pose_rotation(bone,rig.bow_hook_pose[bone])

static func prepare_bow_grip(rig: RefCounted) -> void:
	var skeleton: Skeleton3D=rig.skeleton
	var original=rig._capture_source_pose()
	rig._restore_source_pose(rig.source_rest_pose)
	for bone in rig.grip_pose:skeleton.set_bone_pose_rotation(bone,rig.grip_pose[bone])
	skeleton.force_update_all_bone_transforms()
	var world_mirror=Basis(Vector3(-1,0,0),Vector3.UP,Vector3.BACK)
	var right_hand=skeleton.find_bone("hand_r");var left_hand=skeleton.find_bone("hand_l")
	var right_rest=rig.rest[right_hand].affine_inverse();var left_rest=rig.rest[left_hand].affine_inverse()
	# Native left/right hand rest frames have different axis conventions.
	# Reflect through those real frames, not a guessed hand-local X axis.
	var mirror=rig.rest[left_hand].basis.inverse()*world_mirror*rig.rest[right_hand].basis
	var targets={}
	for right in rig.grip_pose:
		var name=String(skeleton.get_bone_name(right));var left=skeleton.find_bone(name.trim_suffix("_r")+"_l")
		var relative=skeleton.get_bone_global_pose(right_hand).basis.inverse()*skeleton.get_bone_global_pose(right).basis
		var native_right=(right_rest*rig.rest[right]).basis
		var native_left=(left_rest*rig.rest[left]).basis
		var delta=relative*native_right.inverse()
		targets[left]=skeleton.get_bone_global_pose(left_hand).basis*(mirror*delta*mirror.inverse())*native_left
		# Native source right fingers supply the relaxed three-finger hook.
		rig.bow_hook_pose[right]=rig.sword_idle_pose.rotations[right]
	# Source profile keys are stored leaf-to-root; apply global targets in
	# native parent-first order so a later knuckle does not rotate an already
	# fitted fingertip a second time.
	var ordered=targets.keys();ordered.sort()
	for left in ordered:
		rig._global_rotation(left,targets[left])
		rig.bow_grip_pose[left]=skeleton.get_bone_pose_rotation(left)
	# The verified opening is mirrored in hand-local coordinates. The handle
	# diameter is narrowed to exactly the accepted physical staff diameter.
	rig.bow_grip_center=mirror*rig.grip_center
	rig.bow_grasp_frame=rig._frame((mirror*rig.grip_axis).normalized(),Vector3.RIGHT)
	rig._restore_source_pose(original)
	prepare_actual_draw_hook(rig)

static func prepare_actual_draw_hook(rig: RefCounted) -> void:
	var skeleton: Skeleton3D=rig.skeleton
	for bone in rig.bow_hook_pose:skeleton.set_bone_pose_rotation(bone,rig.bow_hook_pose[bone])
	skeleton.force_update_all_bone_transforms()
	var hand=skeleton.get_bone_global_pose(skeleton.find_bone("hand_r")).affine_inverse()
	var closest=INF
	var seed=Vector3(0,.064,.006)
	for part: MeshInstance3D in rig.surfaces:
		if String(part.name)!="Female_Ranger_Arms":continue
		for slot in part.mesh.get_surface_count():
			var arrays=part.mesh.surface_get_arrays(slot);var used={}
			for index in arrays[Mesh.ARRAY_INDEX]:used[index]=true
			for index in used:
				var pure=true;var point=Vector3.ZERO;var normal=Vector3.ZERO
				var probe={"point":arrays[Mesh.ARRAY_VERTEX][index],"bones":[],"weights":[],"binds":[]}
				for influence in 4:
					var weight=float(arrays[Mesh.ARRAY_WEIGHTS][index*4+influence])
					if weight<=0.0:continue
					var bind=int(arrays[Mesh.ARRAY_BONES][index*4+influence]);var name=part.skin.get_bind_name(bind)
					var bone=skeleton.find_bone(name) if name!=&"" else part.skin.get_bind_bone(bind)
					var label=String(skeleton.get_bone_name(bone))
					pure=pure and label.ends_with("_r") and (label.begins_with("index_") or label.begins_with("middle_"))
					var transform=skeleton.get_bone_global_pose(bone)*part.skin.get_bind_pose(bind)
					point+=(transform*probe.point)*weight
					normal+=(transform.basis*arrays[Mesh.ARRAY_NORMAL][index])*weight
					probe.bones.append(bone);probe.weights.append(weight);probe.binds.append(part.skin.get_bind_pose(bind))
				if not pure:continue
				point=hand*point;normal=(hand.basis*normal).normalized()
				var distance=point.distance_squared_to(seed)
				if distance<closest:
					closest=distance
					rig.bow_hook_local=point+normal*.0028
					rig.bow_hook_probe=probe
	assert(not rig.bow_hook_probe.is_empty(),"Bow draw must contact an actually indexed native finger pad")

static func update_bow(rig: RefCounted) -> void:
	var skeleton: Skeleton3D=rig.skeleton
	var hand=skeleton.get_bone_global_pose(skeleton.find_bone("hand_l"))
	var grip=hand*rig.bow_grip_center
	# Original bow local -Z is arrow flight; original +Z is the drawn string.
	var frame=Basis(Vector3.LEFT,Vector3.UP,Vector3.FORWARD)
	rig.weapon.transform=Transform3D(frame*rig.class_weapon_scale,grip)
	var draw=float(rig.class_pose_state.get("draw",0.0))
	var nock=Vector3(0,rig.bow_rest_height/rig.class_weapon_scale,.34+draw)
	if rig.class_pose_state.get("nocked",false):
		var hook=rig.class_pose_state.get("hook_local",Vector3(0,.064,.006))
		var contact=skeleton.get_bone_global_pose(skeleton.find_bone("hand_r"))*hook
		nock=rig.weapon.transform.affine_inverse()*contact
	for index in 2:
		var end=Vector3(0,.60 if index==0 else -.60,.34)
		var direction=end-nock;var y=direction.normalized()
		var x=y.cross(Vector3.RIGHT).normalized();var z=x.cross(y).normalized()
		rig.bow_strings[index].transform=Transform3D(Basis(x,y*direction.length(),z),(end+nock)*.5)
	rig.bow_arrow.position=nock-Vector3(0,0,.34)
	rig.bow_arrow.visible=rig.class_pose_state.get("nocked",false)

static func prepare_arrow_rest(rig: RefCounted) -> void:
	# Measure the full visible native gripping digits, not a guessed hand
	# centre. The original arrow radius is3.75mm at actual runtime scale.
	var skeleton: Skeleton3D=rig.skeleton
	var origin=rig.weapon.transform*rig.class_grip
	var highest=-INF
	for probe in rig.weighted_probes:
		var finger_weight=0.0;var point=Vector3.ZERO
		for index in probe.bones.size():
			var name=String(skeleton.get_bone_name(probe.bones[index]))
			if name.ends_with("_l") and name.get_slice("_",0) in ["index","middle","ring","pinky","thumb"]:finger_weight+=probe.weights[index]
			point+=(skeleton.get_bone_global_pose(probe.bones[index])*probe.binds[index]*probe.point)*probe.weights[index]
		if finger_weight<.60:continue
		var displacement=point-origin
		if Vector2(displacement.x,displacement.z).length()>.05:continue
		highest=maxf(highest,displacement.y)
	assert(is_finite(highest),"Bow arrow rest requires actual indexed native grip fingers")
	rig.bow_rest_height=highest+.006
