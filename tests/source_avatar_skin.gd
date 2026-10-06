extends RefCounted
## Reconstruct the actually rendered weighted source surfaces, not the API proxy.
static func actual_bounds(rig: RefCounted,additional_surfaces: Array=[]) -> AABB:
	var result=AABB();var first=true
	# One pose snapshot per audit. Resolve native binds once, then reconstruct
	# every actual vertex with the same four weighted bone * inverse-bind
	# transforms. Per-vertex name lookup is unnecessary and made full-scene
	# projection audits take minutes without adding coverage.
	var poses: Array[Transform3D]=[]
	for bone in rig.skeleton.get_bone_count():poses.append(rig.skeleton.get_bone_global_pose(bone))
	var surfaces: Array=rig.surfaces.duplicate()
	surfaces.append_array(additional_surfaces)
	for surface in surfaces:
		var transforms: Array[Transform3D]=[]
		for bind in surface.skin.get_bind_count():
			var name=surface.skin.get_bind_name(bind)
			var bone=rig.skeleton.find_bone(name) if name!=&"" else surface.skin.get_bind_bone(bind)
			assert(bone>=0 and bone<poses.size(),"Actual skin bind must resolve to the native skeleton")
			transforms.append(poses[bone]*surface.skin.get_bind_pose(bind))
		for slot in surface.mesh.get_surface_count():
			var a=surface.mesh.surface_get_arrays(slot)
			var v: PackedVector3Array=a[Mesh.ARRAY_VERTEX];var j: PackedInt32Array=a[Mesh.ARRAY_BONES];var w: PackedFloat32Array=a[Mesh.ARRAY_WEIGHTS]
			var used={}
			for index in a[Mesh.ARRAY_INDEX]:used[index]=true
			for index in used:
				var point=Vector3.ZERO
				for influence in 4:
					var weight=w[index*4+influence]
					if weight<=0.0:continue
					point+=(transforms[j[index*4+influence]]*v[index])*weight
				point=rig.motion_node.transform*point
				assert(point.is_finite(),"Actual skinned vertex must stay finite")
				result=AABB(point,Vector3.ZERO) if first else result.expand(point);first=false
	return result
