extends RefCounted
## Reconstruct the actually rendered weighted source surfaces, not the API proxy.
static func actual_bounds(rig: RefCounted) -> AABB:
	var result=AABB();var first=true
	for surface in rig.surfaces:
		for slot in surface.mesh.get_surface_count():
			var a=surface.mesh.surface_get_arrays(slot)
			var v: PackedVector3Array=a[Mesh.ARRAY_VERTEX];var j: PackedInt32Array=a[Mesh.ARRAY_BONES];var w: PackedFloat32Array=a[Mesh.ARRAY_WEIGHTS]
			var used={}
			for index in a[Mesh.ARRAY_INDEX]:used[index]=true
			for index in used:
				var point=Vector3.ZERO
				for influence in 4:
					var bind=j[index*4+influence];var name=surface.skin.get_bind_name(bind)
					var bone=rig.skeleton.find_bone(name) if name!=&"" else surface.skin.get_bind_bone(bind)
					point+=(rig.skeleton.get_bone_global_pose(bone)*surface.skin.get_bind_pose(bind)*v[index])*w[index*4+influence]
				point=rig.motion_node.transform*point
				assert(point.is_finite(),"Actual skinned vertex must stay finite")
				result=AABB(point,Vector3.ZERO) if first else result.expand(point);first=false
	return result
