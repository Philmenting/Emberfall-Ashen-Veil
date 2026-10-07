extends RefCounted
## Exact hero geometry supplies a calm occlusion outline with faint fill. Hostile
## bodies, weapons, shadows, warnings and camera composition stay untouched.
const OCCLUSION_SHADER=preload("res://assets/shaders/hero_occlusion.gdshader")
var hero_reference: WeakRef
var rig_reference: WeakRef
var surfaces: Array[Dictionary]=[]
var latent_props: Array[WeakRef]=[]
var material: ShaderMaterial
var enabled:=false
var nearest_depth:=0.0
var depth_boxes:=0
var depth_transform_count:=0
var camera_inversions:=0
var surface_transform_writes:=0
var surface_visibility_writes:=0
var shader_parameter_writes:=0
var mesh_instances_created:=0
var materials_created:=0
var active_bones: Array[int]=[]
var secondary_boxes: Dictionary={}
var _last_sent_depth:=INF

func bind(hero: Node3D) -> void:
	dispose()
	hero_reference=weakref(hero);rig_reference=weakref(hero.motion_rig)
	material=ShaderMaterial.new();material.shader=OCCLUSION_SHADER
	material.render_priority=8
	materials_created+=1
	if hero.source_avatar:
		var rig: RefCounted=hero.motion_rig
		if rig.style!=null and rig.style.get("attire_motion")!=null:
			# Dynamic garment/hair meshes share the uploaded source resource.
			# Their bounded native influence envelopes also participate in the
			# self-occlusion guard; do not expose an undeformed rear garment.
			for record in rig.style.attire_motion.records:
				for bone in record.boxes:
					if not secondary_boxes.has(bone):secondary_boxes[bone]=[]
					secondary_boxes[bone].append(record.boxes[bone])
		for bone in rig.skeleton.get_bone_count():
			var attire: bool=rig.style!=null and rig.style.get("populated") is Array and rig.style.populated[bone]
			if rig.populated[bone] or attire or secondary_boxes.has(bone):active_bones.append(bone)
	# Exclude the hidden compatibility mesh and effects outside CharacterBody.
	# A sibling shares its source's parent transform, skin and named skeleton;
	# the prop therefore follows the actual hand rather than a screen marker.
	var source_parts: Array[MeshInstance3D]=[]
	for source: MeshInstance3D in hero.body.find_children("*","MeshInstance3D",true,false):
		if source.mesh==null:continue
		if source.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:continue
		if not source.is_visible_in_tree():
			# The Ranger's nocked arrow is genuinely absent in idle. Keep only
			# a weak source candidate until the real cast first shows it; never
			# allocate/draw the hidden proxy or replaced Vowkeeper cloth panels.
			if hero.source_avatar and hero.motion_rig.weapon!=null and hero.motion_rig.weapon.is_ancestor_of(source):latent_props.append(weakref(source))
			continue
		source_parts.append(source)
	for source in source_parts:_append_surface(source)

func _append_surface(source: MeshInstance3D) -> void:
	var copy:=MeshInstance3D.new();copy.name="OccludedHero_"+String(source.name)
	copy.mesh=source.mesh;copy.skin=source.skin;copy.transform=source.transform
	copy.layers=source.layers;copy.extra_cull_margin=source.extra_cull_margin
	copy.lod_bias=source.lod_bias
	copy.custom_aabb=source.custom_aabb
	copy.ignore_occlusion_culling=true
	copy.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	copy.material_override=material;copy.visible=false
	source.get_parent().add_child(copy)
	mesh_instances_created+=1
	if source.skin!=null:
		var skeleton:=source.get_node_or_null(source.skeleton) as Skeleton3D
		assert(skeleton!=null,"An occlusion surface keeps its actual native skeleton")
		copy.skeleton=copy.get_path_to(skeleton)
	surfaces.append({"source":weakref(source),"copy":weakref(copy)})

func update(hero: Node3D,camera: Camera3D,show: bool) -> void:
	depth_boxes=0;depth_transform_count=0;surface_transform_writes=0;camera_inversions=0
	surface_visibility_writes=0;shader_parameter_writes=0
	if hero_reference==null or hero_reference.get_ref()!=hero or rig_reference.get_ref()!=hero.motion_rig:
		# A class/equipment swap invalidates old siblings even while hidden.
		# Merely entering an unobstructed room does not allocate replay meshes.
		dispose();hero_reference=weakref(hero);rig_reference=weakref(hero.motion_rig)
	var reveal: bool=show and hero.death_time<0.0 and hero.is_visible_in_tree()
	nearest_depth=INF
	if not reveal:
		if enabled:
			for entry in surfaces:
				var copy:=entry.copy.get_ref() as MeshInstance3D
				if copy!=null and copy.visible:
					copy.visible=false;surface_visibility_writes+=1
		enabled=false
		return
	if material==null:bind(hero)
	enabled=true
	for index in range(latent_props.size()-1,-1,-1):
		var source:=latent_props[index].get_ref() as MeshInstance3D
		if source==null:latent_props.remove_at(index)
		elif source.is_visible_in_tree():
			_append_surface(source);latent_props.remove_at(index)
	var camera_inverse:=camera.global_transform.affine_inverse()
	camera_inversions+=1
	if hero.source_avatar:
		# Project individual bone-space boxes directly into camera space. A
		# merged axis-aligned world box grows artificial foreground corners
		# when the actor turns, hiding genuine occlusions behind that guard.
		var rig: RefCounted=hero.motion_rig
		var camera_body: Transform3D=camera_inverse*hero.body.global_transform*rig.motion_node.transform
		var has_style_bounds: bool=rig.style!=null and rig.style.get("bone_bounds") is Array and not rig.style.bone_bounds.is_empty()
		for bone in active_bones:
			# Body and attire share this bone transform. Their boxes remain
			# separate: a merged box would invent new foreground corners.
			var camera_bone: Transform3D=camera_body*rig.skeleton.get_bone_global_pose(bone)
			depth_transform_count+=1
			if rig.populated[bone]:
				_include_bounds(camera_bone,rig.bone_bounds[bone])
			if has_style_bounds and rig.style.populated[bone]:
				_include_bounds(camera_bone,rig.style.bone_bounds[bone])
			if secondary_boxes.has(bone):
				for bounds in secondary_boxes[bone]:_include_bounds(camera_bone,bounds)
		for entry in surfaces:
			var source:=entry.source.get_ref() as MeshInstance3D
			if source!=null and source.skin==null and source.is_visible_in_tree():
				depth_transform_count+=1
				_include_bounds(camera_inverse*source.global_transform,source.mesh.get_aabb())
	else:
		depth_transform_count+=1
		_include_bounds(camera_inverse*hero.global_transform,hero.pose_bounds())
	if nearest_depth!=_last_sent_depth:
		material.set_shader_parameter("hero_front_depth",nearest_depth)
		_last_sent_depth=nearest_depth;shader_parameter_writes+=1
	for entry in surfaces:
		var source:=entry.source.get_ref() as MeshInstance3D
		var copy:=entry.copy.get_ref() as MeshInstance3D
		if source==null or copy==null:continue
		# Siblings inherit the same real hand/skeleton parent transform. Most
		# local mesh transforms are constant; avoid redundant RenderingServer
		# notifications without rounding away actual small source movements.
		if copy.transform!=source.transform:
			copy.transform=source.transform;surface_transform_writes+=1
		var visible_source:=source.is_visible_in_tree()
		if copy.visible!=visible_source:
			copy.visible=visible_source;surface_visibility_writes+=1

func _include_bounds(camera_space: Transform3D,bounds: AABB) -> void:
	depth_boxes+=1
	nearest_depth=minf(nearest_depth,front_depth(camera_space,bounds))

static func front_depth(camera_space: Transform3D,bounds: AABB) -> float:
	# Exact support of a transformed AABB along camera -Z. This equals the
	# old minimum of its eight corners, including rotation/nonuniform scale,
	# but needs one center transform and three scalar support terms.
	var center:=camera_space*(bounds.position+bounds.size*.5)
	var half:=bounds.size*.5
	return -center.z-absf(camera_space.basis.x.z)*half.x-absf(camera_space.basis.y.z)*half.y-absf(camera_space.basis.z.z)*half.z

func budget_snapshot() -> Dictionary:
	# Read-only counters for the real-world verification/capture harness. No
	# dictionary or telemetry work is required by ordinary update frames.
	return {"enabled":enabled,"live_replay_meshes":surfaces.size(),
		"unallocated_hidden_props":latent_props.size(),
		"meshes_created":mesh_instances_created,"materials_created":materials_created,
		"depth_boxes":depth_boxes,"bone_or_prop_transforms":depth_transform_count,
		"camera_inversions":camera_inversions,
		"depth_corner_projections":0,"transform_writes":surface_transform_writes,
		"visibility_writes":surface_visibility_writes,"uniform_writes":shader_parameter_writes}

func dispose() -> void:
	for entry in surfaces:
		var copy:=entry.copy.get_ref() as MeshInstance3D
		if copy!=null:copy.free()
	surfaces.clear();latent_props.clear();active_bones.clear();secondary_boxes.clear();material=null;hero_reference=null;rig_reference=null;enabled=false;_last_sent_depth=INF

static func dressing_overlaps(camera: Camera3D,hero_rect: Rect2,hero_far: float,batches: Array[Dictionary],budget: Dictionary={}) -> bool:
	# Existing chamber culling already removes decoration behind the camera.
	# This broad phase enables the small hero pass for surviving tall dressing;
	# scene depth decides the exact foreground fragments, never a guessed hole.
	var measure:=not budget.is_empty()
	if measure:
		budget.candidates=0;budget.depth_rejections=0;budget.projected_corners=0
		budget.cached_batches=0;budget.depth_support_evaluations=0
		budget.camera_inversions=0
	var camera_inverse:=Transform3D.IDENTITY
	var inverse_ready:=false
	var camera_transform:=camera.global_transform
	var unproject_transform:=camera.get_camera_transform()
	var projection:=camera.get_camera_projection()
	var viewport_size:=camera.get_viewport().get_visible_rect().size
	for entry in batches:
		var node:=entry.node as Node3D
		if not node.is_visible_in_tree():continue
		var bounds:=AABB()
		if node is MultiMeshInstance3D:bounds=node.multimesh.get_aabb()
		elif node is MeshInstance3D:bounds=node.get_aabb()
		else:continue
		if bounds.size.y<.65:continue
		if measure:budget.candidates+=1
		var world_transform:=node.global_transform
		var cached: Dictionary=entry.get("_readability_projection",{})
		var current: bool=not cached.is_empty() and cached.world==world_transform and cached.bounds==bounds and cached.camera==camera_transform and cached.unproject_camera==unproject_transform and cached.projection==projection and cached.viewport==viewport_size
		if not current:
			if not inverse_ready:
				camera_inverse=camera_transform.affine_inverse();inverse_ready=true
				if measure:budget.camera_inversions+=1
			cached={"world":world_transform,"bounds":bounds,"camera":camera_transform,
				"unproject_camera":unproject_transform,"projection":projection,"viewport":viewport_size,
				"near":front_depth(camera_inverse*world_transform,bounds)}
			entry["_readability_projection"]=cached
			if measure:budget.depth_support_evaluations+=1
		elif measure:budget.cached_batches+=1
		# Batches entirely behind the hero cannot cover it. Test depth before
		# the eight perspective projections, rather than after doing them all.
		if cached.near>=hero_far:
			if measure:budget.depth_rejections+=1
			continue
		if not cached.has("rect"):
			var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
			for corner in 8:
				var pixel:=camera.unproject_position(world_transform*bounds.get_endpoint(corner))
				low=low.min(pixel);high=high.max(pixel)
			cached.rect=Rect2(low,high-low)
			if measure:budget.projected_corners+=8
		if cached.rect.intersects(hero_rect):return true
	return false
