extends RefCounted
## Exact hero geometry supplies a calm occlusion outline with faint fill. Hostile
## bodies, weapons, shadows, warnings and camera composition stay untouched.
const OCCLUSION_SHADER=preload("res://assets/shaders/hero_occlusion.gdshader")
var hero_reference: WeakRef
var rig_reference: WeakRef
var surfaces: Array[Dictionary]=[]
var material: ShaderMaterial
var enabled:=false
var nearest_depth:=0.0

func bind(hero: Node3D) -> void:
	dispose()
	hero_reference=weakref(hero);rig_reference=weakref(hero.motion_rig)
	material=ShaderMaterial.new();material.shader=OCCLUSION_SHADER
	material.render_priority=8
	# Exclude the hidden compatibility mesh and effects outside CharacterBody.
	# A sibling shares its source's parent transform, skin and named skeleton;
	# the prop therefore follows the actual hand rather than a screen marker.
	var source_parts: Array[MeshInstance3D]=[]
	for source: MeshInstance3D in hero.body.find_children("*","MeshInstance3D",true,false):
		if source.mesh==null or not source.is_visible_in_tree():continue
		if source.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:continue
		source_parts.append(source)
	for source in source_parts:
		var copy:=MeshInstance3D.new();copy.name="OccludedHero_"+String(source.name)
		copy.mesh=source.mesh;copy.skin=source.skin;copy.transform=source.transform
		copy.layers=source.layers;copy.extra_cull_margin=source.extra_cull_margin
		copy.ignore_occlusion_culling=true
		copy.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		copy.material_override=material;copy.visible=false
		source.get_parent().add_child(copy)
		if source.skin!=null:
			var skeleton:=source.get_node_or_null(source.skeleton) as Skeleton3D
			assert(skeleton!=null,"An occlusion surface keeps its actual native skeleton")
			copy.skeleton=copy.get_path_to(skeleton)
		surfaces.append({"source":weakref(source),"copy":weakref(copy)})

func update(hero: Node3D,camera: Camera3D,show: bool) -> void:
	if hero_reference==null or hero_reference.get_ref()!=hero or rig_reference.get_ref()!=hero.motion_rig:
		bind(hero)
	enabled=show and hero.death_time<0.0 and hero.visible
	nearest_depth=INF
	if hero.source_avatar:
		# Project individual bone-space boxes directly into camera space. A
		# merged axis-aligned world box grows artificial foreground corners
		# when the actor turns, hiding genuine occlusions behind that guard.
		var rig: RefCounted=hero.motion_rig
		for bone in rig.skeleton.get_bone_count():
			if rig.populated[bone]:
				_include_bounds(camera,hero.body.global_transform*rig.motion_node.transform*rig.skeleton.get_bone_global_pose(bone),rig.bone_bounds[bone])
		if rig.style!=null and rig.style.get("bone_bounds") is Array and not rig.style.bone_bounds.is_empty():
			for bone in rig.skeleton.get_bone_count():
				if rig.style.populated[bone]:
					_include_bounds(camera,hero.body.global_transform*rig.motion_node.transform*rig.skeleton.get_bone_global_pose(bone),rig.style.bone_bounds[bone])
		for entry in surfaces:
			var source:=entry.source.get_ref() as MeshInstance3D
			if source!=null and source.skin==null and source.is_visible_in_tree():
				_include_bounds(camera,source.global_transform,source.mesh.get_aabb())
	else:_include_bounds(camera,hero.global_transform,hero.pose_bounds())
	material.set_shader_parameter("hero_front_depth",nearest_depth)
	for entry in surfaces:
		var source:=entry.source.get_ref() as MeshInstance3D
		var copy:=entry.copy.get_ref() as MeshInstance3D
		if source==null or copy==null:continue
		copy.transform=source.transform
		copy.visible=enabled and source.is_visible_in_tree()

func _include_bounds(camera: Camera3D,transform: Transform3D,bounds: AABB) -> void:
	for x in [bounds.position.x,bounds.end.x]:
		for y in [bounds.position.y,bounds.end.y]:
			for z in [bounds.position.z,bounds.end.z]:
				nearest_depth=minf(nearest_depth,-camera.to_local(transform*Vector3(x,y,z)).z)

func dispose() -> void:
	for entry in surfaces:
		var copy:=entry.copy.get_ref() as MeshInstance3D
		if copy!=null:copy.free()
	surfaces.clear();material=null;hero_reference=null;rig_reference=null;enabled=false

static func dressing_overlaps(camera: Camera3D,hero_rect: Rect2,hero_far: float,batches: Array[Dictionary]) -> bool:
	# Existing chamber culling already removes decoration behind the camera.
	# This broad phase enables the small hero pass for surviving tall dressing;
	# scene depth decides the exact foreground fragments, never a guessed hole.
	for entry in batches:
		var node:=entry.node as Node3D
		if not node.is_visible_in_tree():continue
		var bounds:=AABB()
		if node is MultiMeshInstance3D:bounds=node.multimesh.get_aabb()
		elif node is MeshInstance3D:bounds=node.get_aabb()
		else:continue
		if bounds.size.y<.65:continue
		var near_depth:=INF;var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
		for x in [bounds.position.x,bounds.end.x]:
			for y in [bounds.position.y,bounds.end.y]:
				for z in [bounds.position.z,bounds.end.z]:
					var point:=node.to_global(Vector3(x,y,z))
					near_depth=minf(near_depth,-camera.to_local(point).z)
					var pixel:=camera.unproject_position(point)
					low=low.min(pixel);high=high.max(pixel)
		if near_depth<hero_far and Rect2(low,high-low).intersects(hero_rect):return true
	return false
