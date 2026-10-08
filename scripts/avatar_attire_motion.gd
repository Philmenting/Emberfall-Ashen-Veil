extends RefCounted
## Bounded native-skin secondary detail. Source resources are immutable; only
## per-actor vertex buffers are updated. No new surfaces, bones or draw passes.
## Waist/scalp attachments remain exact. Death and reduced motion restore rest.
const CLOTH_LIMIT:=.017
const HAIR_LIMIT:=.004
const HOOD_LIMIT:=.006
const NativeMeshLods=preload("res://scripts/native_mesh_lods.gd")
static var finish_cache: Dictionary={}
var records: Array[Dictionary]=[]
var rig_ref: WeakRef
var reduced_mode:=false
var last_drive:=Vector2.ZERO
var uploaded_bytes:=0
var upload_calls:=0
var moved_vertex_count:=0
var max_displacement:=0.0

func setup(rig: Variant) -> void:rig_ref=weakref(rig)

static func soften_textile(part: MeshInstance3D) -> void:
	# Normal-only derived finish: identical positions, UV seams, indices and
	# native weights. Preserve intentionally sharp edges exceeding 58 degrees.
	var original=part.mesh
	var cache_key=str(original.get_instance_id())
	if finish_cache.has(cache_key):part.mesh=finish_cache[cache_key];return
	var derived=ArrayMesh.new()
	var changed=false
	for slot in original.get_surface_count():
		var arrays=original.surface_get_arrays(slot).duplicate()
		var points: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL].duplicate()
		var material=original.surface_get_material(slot)
		if material!=null and String(material.resource_name).contains("Regular_Female"):
			derived.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],NativeMeshLods.lods_for(original,slot))
			derived.surface_set_material(slot,material);continue
		var groups: Dictionary={}
		for index in points.size():
			var p=points[index]
			var key=Vector3i(roundi(p.x*100000),roundi(p.y*100000),roundi(p.z*100000))
			if not groups.has(key):groups[key]=[]
			groups[key].append(index)
		var source: PackedVector3Array=normals.duplicate()
		for group in groups.values():
			if group.size()<2:continue
			for index in group:
				var total=Vector3.ZERO
				for peer in group:
					if source[index].dot(source[peer])>=.53:total+=source[peer]
				if total.length_squared()>.00001:
					normals[index]=source[index].lerp(total.normalized(),.70).normalized()
					changed=changed or normals[index].distance_squared_to(source[index])>.000001
		arrays[Mesh.ARRAY_NORMAL]=normals
		derived.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],NativeMeshLods.lods_for(original,slot))
		derived.surface_set_material(slot,original.surface_get_material(slot))
	# Positions and native vertex indices remain exact in normal-only finish,
	# so the imported fused depth/shadow geometry remains correct. Dynamic
	# copies below intentionally use their current main vertex buffer instead.
	if changed:derived.shadow_mesh=original.shadow_mesh
	finish_cache[cache_key]=derived if changed else original
	part.mesh=finish_cache[cache_key]

func add(part: MeshInstance3D,mode: String) -> void:
	var rig=rig_ref.get_ref()
	var original=part.mesh
	var derived=ArrayMesh.new()
	for slot in original.get_surface_count():
		var arrays=original.surface_get_arrays(slot).duplicate()
		var points: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var active=PackedInt32Array();var mask=PackedFloat32Array()
		for index in points.size():
			var weight=_mask(mode,points[index])
			mask.append(weight)
			if weight>0.00001:active.append(index)
		derived.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],NativeMeshLods.lods_for(original,slot),Mesh.ARRAY_FLAG_USE_DYNAMIC_UPDATE)
		derived.surface_set_material(slot,original.surface_get_material(slot))
		# With uncompressed Vector3 positions, the vertex region is exactly a
		# contiguous native-float32 xyz buffer; normals use their own region.
		assert(RenderingServer.mesh_surface_get_format_vertex_stride(derived.surface_get_format(slot),points.size())==12)
		var boxes: Dictionary={}
		var bones: PackedInt32Array=arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
		var probes: Array[Dictionary]=[];var used: Dictionary={}
		for index in arrays[Mesh.ARRAY_INDEX]:used[index]=true
		for index in used:
			var probe={"index":index,"bones":[],"weights":[],"binds":[]}
			for influence in 4:
				var weight=weights[index*4+influence]
				if weight<=0.0:continue
				var bind=bones[index*4+influence]
				var name=part.skin.get_bind_name(bind)
				var bone=rig.skeleton.find_bone(name) if name!=&"" else part.skin.get_bind_bone(bind)
				assert(bone>=0)
				var local=part.skin.get_bind_pose(bind)*points[index]
				boxes[bone]=boxes[bone].expand(local) if boxes.has(bone) else AABB(local,Vector3.ZERO)
				probe.bones.append(bone);probe.weights.append(weight);probe.binds.append(part.skin.get_bind_pose(bind))
			probes.append(probe)
		var limit=_limit(mode)
		for bone in boxes:boxes[bone]=boxes[bone].grow(limit)
		records.append({"part":part,"slot":slot,"mode":mode,"rest":points.duplicate(),"points":points.duplicate(),"active":active,"mask":mask,"boxes":boxes,"probes":probes,"limit":limit,"lods":NativeMeshLods.lods_for(original,slot)})
		moved_vertex_count+=active.size()
	part.mesh=derived
	# Native bones may move skin well outside the rest AABB, so retain the
	# production margin and include the bounded secondary displacement.
	part.custom_aabb=original.get_aabb().grow(_limit(mode))

static func _limit(mode: String) -> float:
	return HAIR_LIMIT if mode=="hair" else (HOOD_LIMIT if mode=="hood" else CLOTH_LIMIT)

static func _mask(mode: String,p: Vector3) -> float:
	if mode=="hair":
		# Side buns / loose ends only. Central scalp and forehead stay fixed.
		return smoothstep(.078,.145,absf(p.x))*(1.0-smoothstep(1.655,1.745,p.y))
	if mode=="hood":
		# Rear hood folds below the head attachment, clear of the face rim.
		return (1.0-smoothstep(1.49,1.65,p.y))*(1.0-smoothstep(-.105,-.035,p.z))
	if mode=="tunic":return (1.0-smoothstep(.92,1.105,p.y))*(1.0-smoothstep(-.06,.025,p.z))
	# Coat tails and matching bronze edge binding share one spatial field,
	# including their slight surface offset, so neither peels away alone.
	return 1.0-smoothstep(.59,1.018,p.y)

static func drive(clip: String,time: float) -> Vector2:
	if clip=="death":return Vector2.ZERO
	if clip=="walk":return Vector2(sin(time*TAU)*.83,sin(time*TAU*2.0)*.27)
	if clip.begins_with("windup"):
		var strength=.90 if clip.contains("heavy") else .70
		return Vector2(smoothstep(0,1,clampf(time,0,1))*strength,sin(clampf(time,0,1)*PI)*.25)
	if clip.begins_with("recover"):
		var strength=.90 if clip.contains("heavy") else .70
		var settle=1.0-smoothstep(0,.34,time)
		return Vector2(strength*settle*cos(time*11),-.25*sin(time*PI/.34)*settle)
	if clip=="evade":return Vector2(sin(clampf(time,0,1)*PI)*.95,sin(clampf(time,0,1)*TAU)*.25)
	return Vector2(sin(time*TAU/3.8)*.09,sin(time*TAU/2.7)*.035)

static func displacement(mode: String,p: Vector3,weight: float,value: Vector2) -> Vector3:
	var side=1.0 if p.x>=0.0 else -1.0
	if mode=="hair":return Vector3(side*absf(value.x)*.0025,0,value.y*.0035)*weight
	if mode=="hood":return Vector3(side*absf(value.x)*.002,0,-absf(value.x)*.005+value.y*.001)*weight
	if mode=="tunic":return Vector3(side*absf(value.x)*.003,0,-absf(value.x)*.008+value.y*.002)*weight
	# Outward-only flare and a small trailing back fold retain the open vent.
	return Vector3(side*absf(value.x)*.009,0,-absf(value.x)*.012+value.y*.004)*weight

func update(clip: String,time: float,disable: Variant=null) -> void:
	if disable!=null:reduced_mode=bool(disable)
	var value=Vector2.ZERO if reduced_mode else drive(clip,time)
	# Canonicalize sine endpoints so death/reduced motion restore exact rest
	# instead of retaining a numerically tiny previous offset at a loop seam.
	if value.length_squared()<.0000000001:value=Vector2.ZERO
	if last_drive.is_equal_approx(value):return
	last_drive=value;max_displacement=0.0
	for record in records:
		var points: PackedVector3Array=record.rest.duplicate()
		for index in record.active:
			var offset=displacement(record.mode,record.rest[index],record.mask[index],value)
			assert(offset.length()<=record.limit)
			max_displacement=maxf(max_displacement,offset.length())
			points[index]+=offset
		record.points=points
		var data=points.to_byte_array()
		record.part.mesh.surface_update_vertex_region(record.slot,0,data)
		upload_calls+=1;uploaded_bytes+=data.size()

func owns(part: MeshInstance3D) -> bool:
	for record in records:
		if record.part==part:return true
	return false

func current_bounds() -> AABB:
	var rig=rig_ref.get_ref()
	var result=AABB();var first=true
	for record in records:
		for bone in record.boxes:
			var box=rig.motion_node.transform*(rig.skeleton.get_bone_global_pose(bone)*record.boxes[bone])
			result=box if first else result.merge(box);first=false
	return result

func actual_bounds() -> AABB:
	# Independent exact floor/bounds oracle for the actually uploaded points.
	var rig=rig_ref.get_ref();var poses: Array[Transform3D]=[]
	for bone in rig.skeleton.get_bone_count():poses.append(rig.skeleton.get_bone_global_pose(bone))
	var result=AABB();var first=true
	for record in records:
		for probe in record.probes:
			var point=Vector3.ZERO
			for index in probe.bones.size():point+=(poses[probe.bones[index]]*probe.binds[index]*record.points[probe.index])*probe.weights[index]
			point=rig.motion_node.transform*point
			result=AABB(point,Vector3.ZERO) if first else result.expand(point);first=false
	return result
