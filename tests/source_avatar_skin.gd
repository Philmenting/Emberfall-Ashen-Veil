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
	for surface in additional_surfaces:
		if not surfaces.has(surface):surfaces.append(surface)
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

static func actual_figure_bounds(rig: RefCounted,additional_surfaces: Array=[]) -> AABB:
	# Rigid held objects use their actual node transform and indexed vertices,
	# including a second-hand shield/censer. A role-specific guessed socket or
	# a single legacy weapon_points array cannot cover those independent props.
	var result:=actual_bounds(rig,additional_surfaces)
	var local_from_world: Transform3D=rig.motion_node.global_transform.affine_inverse()
	for part: MeshInstance3D in rig.motion_node.find_children("*","MeshInstance3D",true,false):
		if not part.is_visible_in_tree() or part.skin!=null or part.mesh==null: continue
		var transform: Transform3D=rig.motion_node.transform*local_from_world*part.global_transform
		var slots: int=1 if part.mesh is PrimitiveMesh else part.mesh.get_surface_count()
		for slot in slots:
			var arrays: Array=part.mesh.get_mesh_arrays() if part.mesh is PrimitiveMesh else part.mesh.surface_get_arrays(slot)
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			var used: Dictionary={}
			if indices.is_empty():
				for index in vertices.size(): used[index]=true
			else:
				for index in indices: used[index]=true
			for index in used:
				var point:=transform*vertices[index]
				assert(point.is_finite(),"Actual rigid prop vertex must stay finite")
				result=result.expand(point)
	return result
