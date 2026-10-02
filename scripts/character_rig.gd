extends RefCounted
## One GPU-skinned surface per figure. Logical joints retain combat presentation API.

static func create(actor: Node3D,joints: Dictionary) -> Skeleton3D:
	var skeleton:=Skeleton3D.new()
	skeleton.name="CharacterSkeleton"
	actor.add_child(skeleton)
	for part in joints: skeleton.add_bone(part)
	for part in joints:
		var index:=skeleton.find_bone(part)
		var joint: Node3D=joints[part]
		if joint.get_parent()!=actor:
			skeleton.set_bone_parent(index,skeleton.find_bone(String(joint.get_parent().name)))
		skeleton.set_bone_rest(index,joint.transform)
		skeleton.set_bone_pose_position(index,joint.position)
	return skeleton

static func bake(authored: Node3D,skeleton: Skeleton3D,joints: Dictionary) -> ArrayMesh:
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for source in authored.find_children("*","MeshInstance3D",true,false):
		var part:=String(source.name).get_slice("__",0)
		assert(joints.has(part),"Unknown authored character part: "+part)
		var bone:=skeleton.find_bone(part)
		var rest:=skeleton.get_bone_global_rest(bone)
		var transform: Transform3D=rest*source.transform
		var normal_basis:=transform.basis.inverse().transposed()
		for slot in range(source.mesh.get_surface_count()):
			var material: StandardMaterial3D=source.mesh.surface_get_material(slot)
			var category:=_category(material.resource_name.get_slice(".",0))
			var arrays: Array=source.mesh.surface_get_arrays(slot)
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
			var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			for i in range(indices.size() if not indices.is_empty() else vertices.size()):
				var index: int=indices[i] if not indices.is_empty() else i
				var local: Vector3=source.transform*vertices[index]
				var secondary:=bone
				var weight:=0.0
				if part in ["ArmL","ArmR"]:
					secondary=skeleton.find_bone("ForearmL" if part=="ArmL" else "ForearmR")
					weight=1.0 if local.z < -0.22 else 1.0-smoothstep(-0.40,-0.18,local.y)
				elif part=="Body":
					secondary=skeleton.find_bone("Head")
					weight=smoothstep(1.60,1.69,local.y)
				elif part=="Cape":
					secondary=skeleton.find_bone("CapeTip")
					weight=1.0-smoothstep(-0.85,-0.30,local.y)
				surface.set_bones(PackedInt32Array([bone,secondary,0,0]))
				surface.set_weights(PackedFloat32Array([1.0-weight,weight,0,0]))
				surface.set_color(material.albedo_color)
				surface.set_uv(Vector2(category,0))
				surface.set_uv2(Vector2(material.metallic,1.0 if material.emission_enabled else 0.0))
				surface.set_normal((normal_basis*normals[index]).normalized())
				surface.add_vertex(transform*vertices[index])
	surface.index()
	return surface.commit()

static func _category(material: String) -> float:
	if material in ["wine","violet","sage","linen","ash"]: return 1.0
	if material=="leather": return 2.0
	if material=="skin": return 3.0
	if material=="bone": return 4.0
	return 0.0
