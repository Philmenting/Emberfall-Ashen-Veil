extends RefCounted
## Separate native65 attire and source material finish. The original avatar's
## eight surfaces, UVs, bones, skin weights and accepted staff remain untouched.
const ATTIRE=preload("res://assets/models/nyra054/nyra-attire054.glb")
var accessories: Array[MeshInstance3D]=[]
var skeleton: Skeleton3D
var motion_node: Node3D
var bone_bounds: Array[AABB]=[]
var populated: Array[bool]=[]
var floor_probes: Array=[]
var triangle_count:=0

func apply(rig: Variant) -> void:
	skeleton=rig.skeleton
	motion_node=rig.motion_node
	for surface: MeshInstance3D in rig.surfaces:
		for slot in surface.mesh.get_surface_count():
			var material=surface.get_active_material(slot) as StandardMaterial3D
			if material==null:continue
			# Each rendered source owns this material already. Original PBR image
			# references, authored UV detail and native topology are retained.
			var name=String(surface.name)
			if name.contains("Peasant_Arms"):
				material.albedo_color=Color(.22,.31,.43)
				material.roughness=.88
			elif name.contains("Peasant_Body"):
				material.albedo_color=Color(.40,.42,.44)
				material.roughness=.85
			elif name.contains("Peasant_Legs"):
				material.albedo_color=Color(.33,.36,.40)
				material.roughness=.90
			elif name.contains("Peasant_Feet"):
				material.albedo_color=Color(.43,.40,.36)
				material.roughness=.76
			elif name.contains("Hair_Buns"):
				material.albedo_color=Color(.60,.64,.69)
				material.roughness=.66
				material.normal_scale=1.08
				material.metallic_specular=.38
			elif name.contains("Eyebrows"):
				material.albedo_color=Color(.36,.33,.30)
				material.roughness=.82
			elif name.contains("Eyes"):
				material.roughness=.22
				material.metallic_specular=.46
			elif name.contains("Head"):
				material.albedo_color=Color(.97,.95,.93)
				material.roughness=.79
				material.normal_scale=.42
				material.metallic_specular=.34
	for i in skeleton.get_bone_count():
		bone_bounds.append(AABB())
		populated.append(false)
	var source_coat_detail: StandardMaterial3D
	for surface: MeshInstance3D in rig.surfaces:
		if String(surface.name).contains("Peasant_Body"):
			source_coat_detail=surface.get_active_material(0) as StandardMaterial3D
	var source=ATTIRE.instantiate()
	for child in source.find_children("*","MeshInstance3D",true,false):
		var part=MeshInstance3D.new()
		part.name=child.name
		part.mesh=child.mesh
		part.skin=child.skin
		part.layers=2
		part.ignore_occlusion_culling=true
		part.extra_cull_margin=3.0
		motion_node.add_child(part)
		part.skeleton=part.get_path_to(skeleton)
		accessories.append(part)
		for slot in part.mesh.get_surface_count():
			var material=child.get_active_material(slot)
			if material!=null:
				var own=material.duplicate() as StandardMaterial3D
				# The fitted bodice keeps original garment UVs, so the author's
				# physical fine normal/ORM detail remains aligned after cutting.
				# Newly modeled tails have their own UVs and retain their actual
				# folded mesh shading instead of sampling an unrelated atlas.
				if String(part.name).contains("Open_Coat_Bodice") and source_coat_detail!=null:
					own.normal_enabled=source_coat_detail.normal_enabled
					own.normal_texture=source_coat_detail.normal_texture
					own.normal_scale=.38
					own.roughness_texture=source_coat_detail.roughness_texture
					own.roughness_texture_channel=source_coat_detail.roughness_texture_channel
					own.roughness=.88
					own.ao_enabled=source_coat_detail.ao_enabled
					own.ao_texture=source_coat_detail.ao_texture
					own.ao_texture_channel=source_coat_detail.ao_texture_channel
				part.set_surface_override_material(slot,own)
			_index_surface(part,slot)
	source.free()

func _index_surface(surface: MeshInstance3D,slot: int) -> void:
	var arrays=surface.mesh.surface_get_arrays(slot)
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	var bones: PackedInt32Array=arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
	assert(weights.size()==vertices.size()*4)
	triangle_count+=indices.size()/3
	var used: Dictionary={}
	for index in indices:used[index]=true
	for index in used:
		var probe={"point":vertices[index],"bones":[],"weights":[],"binds":[]}
		for influence in 4:
			var weight=weights[index*4+influence]
			if weight<=0.0:continue
			var bind=bones[index*4+influence]
			var name=surface.skin.get_bind_name(bind)
			var bone=skeleton.find_bone(name) if name!=&"" else surface.skin.get_bind_bone(bind)
			assert(bone>=0)
			var local=surface.skin.get_bind_pose(bind)*vertices[index]
			if populated[bone]:bone_bounds[bone]=bone_bounds[bone].expand(local)
			else:bone_bounds[bone]=AABB(local,Vector3.ZERO);populated[bone]=true
			probe.bones.append(bone)
			probe.weights.append(weight)
			probe.binds.append(surface.skin.get_bind_pose(bind))
		# Death can put the shoulder/back shell on the floor as well as the
		# hems. Keep all actually indexed accessory vertices for that audit.
		floor_probes.append(probe)

func current_bounds() -> AABB:
	var bounds:=AABB()
	var first=true
	for bone in skeleton.get_bone_count():
		if not populated[bone]:continue
		var box=motion_node.transform*(skeleton.get_bone_global_pose(bone)*bone_bounds[bone])
		bounds=box if first else bounds.merge(box)
		first=false
	return bounds

func hem_floor_offset() -> float:
	# Death can land on any part of the garment. Despite the historical
	# method name, this measures all indexed accessory vertices, not a
	# bounding box or just the knees. Walking continues to use its boots.
	var low=INF
	var poses: Array[Transform3D]=[]
	for bone in skeleton.get_bone_count():poses.append(skeleton.get_bone_global_pose(bone))
	for probe in floor_probes:
		var point=Vector3.ZERO
		for i in probe.bones.size():
			point+=(poses[probe.bones[i]]*probe.binds[i]*probe.point)*probe.weights[i]
		low=minf(low,(motion_node.transform*point).y)
	return maxf(0.0,.002-low) if is_finite(low) else 0.0
