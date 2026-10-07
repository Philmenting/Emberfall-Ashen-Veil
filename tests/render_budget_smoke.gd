extends SceneTree
## Count actual production-helper work on native figures and real dungeon
## batches. This measures allocations, projections and server writes; it is
## deliberately not an emulator or physical-phone frame-time benchmark.
const Readability=preload("res://scripts/combat_readability.gd")
const Sim=preload("res://scripts/expedition_simulation.gd")
const World=preload("res://scripts/dungeon_world.gd")
const Bot=preload("res://tests/balance_survey_bot.gd")
const NativeMeshLods=preload("res://scripts/native_mesh_lods.gd")
const AttireMotion=preload("res://scripts/avatar_attire_motion.gd")
const Actor=preload("res://scripts/dungeon_actor.gd")
const NativeHostile=preload("res://scripts/native_hostile_rig.gd")
class BudgetWorld:
	extends "res://scripts/dungeon_world.gd"
	var hero_window_calls:=0
	func _hero_occlusion_window() -> Dictionary:
		hero_window_calls+=1
		return super._hero_occlusion_window()
var checks:=0
var failures:=0
var require_native_render:=false
var receipt: Dictionary={"scope":"Actual native meshes, real world batches and exact helper operation counters; no GPU/phone FPS claim","classes":[],"dressing":[],"native_actor_materials":[],"native_render_primitives":[],"hostile_geometry":[],"attire_lod_retention":[]}

func _initialize() -> void:run_checks.call_deferred()

func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures+=1;push_error("FAIL: "+label)

func corner_depth(camera_space: Transform3D,bounds: AABB) -> float:
	# Independent legacy reference: enumerate the eight real corners.
	var nearest:=INF
	for corner in 8:nearest=minf(nearest,-(camera_space*bounds.get_endpoint(corner)).z)
	return nearest

func native_corner_depth(hero: Node3D,camera: Camera3D,observer: RefCounted) -> Dictionary:
	var nearest:=INF
	var boxes:=0
	var rig: RefCounted=hero.motion_rig
	for bone in rig.skeleton.get_bone_count():
		var transform: Transform3D=hero.body.global_transform*rig.motion_node.transform*rig.skeleton.get_bone_global_pose(bone)
		if rig.populated[bone]:
			nearest=minf(nearest,corner_depth(camera.global_transform.affine_inverse()*transform,rig.bone_bounds[bone]));boxes+=1
		if rig.style!=null and rig.style.get("bone_bounds") is Array and not rig.style.bone_bounds.is_empty() and rig.style.populated[bone]:
			nearest=minf(nearest,corner_depth(camera.global_transform.affine_inverse()*transform,rig.style.bone_bounds[bone]));boxes+=1
		if rig.style!=null and rig.style.get("attire_motion")!=null:
			for record in rig.style.attire_motion.records:
				if record.boxes.has(bone):
					nearest=minf(nearest,corner_depth(camera.global_transform.affine_inverse()*transform,record.boxes[bone]));boxes+=1
	for entry in observer.surfaces:
		var source:=entry.source.get_ref() as MeshInstance3D
		if source!=null and source.skin==null and source.is_visible_in_tree():
			nearest=minf(nearest,corner_depth(camera.global_transform.affine_inverse()*source.global_transform,source.mesh.get_aabb()));boxes+=1
	return {"near":nearest,"boxes":boxes,"legacy_corner_transforms":boxes*8}

func native_mesh_inventory(hero: Node3D) -> Dictionary:
	var triangles:=0
	var meshes:=0
	var surface_count:=0
	var materials: Dictionary={}
	var mesh_resources: Dictionary={}
	var lod_surfaces:=0
	var coarsest_triangles:=0
	var lod_meshes: Array=[]
	var native_vertices:=0
	var shadow_vertices:=0
	var shadow_surfaces:=0
	var buffers:=0
	for part: MeshInstance3D in hero.body.find_children("*","MeshInstance3D",true,false):
		if part.mesh==null or not part.is_visible_in_tree():continue
		if part.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:continue
		if String(part.name).begins_with("OccludedHero_"):continue
		meshes+=1
		var new_resource:=not mesh_resources.has(part.mesh.get_instance_id())
		mesh_resources[part.mesh.get_instance_id()]=true
		var lod_inventory:=NativeMeshLods.inventory(part.mesh)
		lod_surfaces+=int(lod_inventory.lod_surface_count)
		coarsest_triangles+=int(lod_inventory.coarsest_triangles)
		native_vertices+=int(lod_inventory.base_vertices)
		shadow_vertices+=int(lod_inventory.shadow_vertices)
		shadow_surfaces+=int(lod_inventory.position_only_shadow_surfaces)
		if new_resource:buffers+=int(lod_inventory.stored_buffer_bytes)
		lod_meshes.append({"name":String(part.name),"inventory":lod_inventory})
		for surface in part.mesh.get_surface_count():
			surface_count+=1
			var arrays:=part.mesh.surface_get_arrays(surface)
			var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			triangles+=indices.size()/3 if not indices.is_empty() else arrays[Mesh.ARRAY_VERTEX].size()/3
			var material:=part.get_active_material(surface)
			if material!=null:materials[material.get_instance_id()]=true
	return {"visible_meshes":meshes,"mesh_surface_slots":surface_count,"triangles":triangles,
		"distinct_mesh_resources":mesh_resources.size(),"distinct_material_resources":materials.size(),
		"lod_surface_count":lod_surfaces,"available_coarsest_triangles":coarsest_triangles,"lod_meshes":lod_meshes,
		"native_vertices":native_vertices,"position_only_shadow_vertices":shadow_vertices,
		"position_only_shadow_surfaces":shadow_surfaces,"stored_native_buffer_bytes":buffers,
		"buffer_scope":"Main/index/attribute/skin/LOD bytes per distinct visible mesh resource within this actor; shared other actors, textures and driver allocations are excluded"}

func legacy_dressing(camera: Camera3D,hero_rect: Rect2,hero_far: float,batches: Array[Dictionary]) -> bool:
	# Original056 broad phase, including its eight depth/projection corners.
	for entry in batches:
		var node:=entry.node as Node3D
		if not node.is_visible_in_tree():continue
		var bounds:=AABB()
		if node is MultiMeshInstance3D:bounds=node.multimesh.get_aabb()
		elif node is MeshInstance3D:bounds=node.get_aabb()
		else:continue
		if bounds.size.y<.65:continue
		var nearest:=INF
		var low:=Vector2(INF,INF)
		var high:=Vector2(-INF,-INF)
		for corner in 8:
			var point:=node.to_global(bounds.get_endpoint(corner))
			nearest=minf(nearest,-camera.to_local(point).z)
			var pixel:=camera.unproject_position(point)
			low=low.min(pixel);high=high.max(pixel)
		if nearest<hero_far and Rect2(low,high-low).intersects(hero_rect):return true
	return false

func check_lod_packing() -> void:
	# Known index patterns verify the native API adapter independently of
	# importing art. Include both sides of the exact uint16/uint32 boundary.
	for count in [8,65536,65537]:
		var points:=PackedVector3Array();points.resize(count)
		points[1]=Vector3.RIGHT;points[count-1]=Vector3.UP
		var expected:=PackedInt32Array([0,1,count-1])
		var base:=expected.duplicate();base.append_array(expected)
		var arrays: Array=[];arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX]=points;arrays[Mesh.ARRAY_INDEX]=base
		var source:=ArrayMesh.new()
		source.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{42.25:expected})
		var decoded:=NativeMeshLods.lods_for(source,0)
		check(decoded.size()==1 and decoded.has(42.25) and decoded[42.25]==expected,"%d vertices: public native LOD reader preserves the independently supplied packed indices" % count)
		var derived:=ArrayMesh.new()
		derived.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],decoded,Mesh.ARRAY_FLAG_USE_DYNAMIC_UPDATE)
		var roundtrip:=NativeMeshLods.lods_for(derived,0)
		check(roundtrip.has(42.25) and roundtrip[42.25]==expected,"%d vertices: derived dynamic mesh preserves exact original LOD distance and complete index numbering" % count)
		var inventory:=NativeMeshLods.inventory(derived)
		check(inventory.base_triangles==2 and inventory.coarsest_triangles==1 and inventory.lod_surface_count==1,"%d vertices: actual server inventory proves two base triangles and one available LOD triangle" % count)
	var unindexed:=ArrayMesh.new()
	var plain: Array=[];plain.resize(Mesh.ARRAY_MAX)
	plain[Mesh.ARRAY_VERTEX]=PackedVector3Array([Vector3.ZERO,Vector3.RIGHT,Vector3.UP])
	unindexed.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,plain)
	check(NativeMeshLods.inventory(unindexed).base_triangles==1,"Unindexed native triangle inventories its vertices when the real server index_count is zero")

func check_attire_retention(hero: Node3D,class_key: String) -> void:
	var motion: RefCounted=hero.motion_rig.style.attire_motion
	var measured: Array=[]
	for record in motion.records:
		var actual: Dictionary=NativeMeshLods.lods_for(record.part.mesh,record.slot)
		var same: bool=actual.size()==record.lods.size()
		for distance in record.lods:same=same and actual.has(distance) and actual[distance]==record.lods[distance]
		check(same,class_key+" "+String(record.part.name)+": actual dynamic garment retains every original packed LOD index and distance")
		check(record.part.mesh.shadow_mesh==null,class_key+" "+String(record.part.name)+": a moving garment shadows its updated main vertices rather than a stale static shadow mesh")
		measured.append({"name":String(record.part.name),"slot":record.slot,"mode":record.mode,"available_lod_levels":actual.size(),"dynamic_shadow":"updated_main_vertex_buffer"})
	var static_finish: Array=[]
	for source_id in AttireMotion.finish_cache:
		var original:=instance_from_id(int(source_id)) as ArrayMesh
		var finished: ArrayMesh=AttireMotion.finish_cache[source_id]
		if original==null or original==finished:continue
		check(finished.shadow_mesh==original.shadow_mesh,"Normal-only textile finish retains the exact original fused shadow resource")
		var retained:=finished.get_surface_count()==original.get_surface_count()
		for slot in original.get_surface_count():
			var before: Dictionary=NativeMeshLods.lods_for(original,slot)
			var after: Dictionary=NativeMeshLods.lods_for(finished,slot)
			retained=retained and before.size()==after.size()
			for distance in before:retained=retained and after.has(distance) and before[distance]==after[distance]
		check(retained,"Normal-only textile finish retains exact original imported LODs")
		static_finish.append({"surfaces":finished.get_surface_count(),"retained_same_shadow_resource":finished.shadow_mesh==original.shadow_mesh,"lods_retained":retained})
	check(not static_finish.is_empty(),class_key+": the actual normal-only derived textile cache has live source meshes for the shadow/LOD comparison")
	receipt.attire_lod_retention.append({"class":class_key,"dynamic_meshes":measured,"normal_only_cache_derivations":static_finish})

func check_hostile_geometry() -> void:
	for role in NativeHostile.PROPS:
		var actor:=Actor.new();actor.hostile=true;actor.boss=String(role).begins_with("guardian_")
		actor.kind="boss" if actor.boss else String(role)
		if actor.boss:actor.region_index=int(String(role).right(1))
		root.add_child(actor)
		var inventory:=native_mesh_inventory(actor)
		check(actor.source_avatar and actor.motion_rig is NativeHostile and actor.surface_material==null,String(role)+": budget inventory uses the actual production native role without a compatibility shader")
		check(inventory.triangles==actor.motion_rig.rendered_triangles and inventory.triangles<=actor.motion_rig.triangle_budget(),String(role)+": actual visible indexed high geometry matches the declared role count and budget")
		check(inventory.lod_surface_count>0 and inventory.available_coarsest_triangles<inventory.triangles,String(role)+": real role surfaces retain available imported LOD reductions")
		receipt.hostile_geometry.append({"role":role,"inventory":inventory,"triangle_budget":actor.motion_rig.triangle_budget()})
		actor.free()

func check_native(hero: Node3D,camera: Camera3D,class_key: String) -> void:
	var inventory:=native_mesh_inventory(hero)
	check_attire_retention(hero,class_key)
	check(inventory.lod_surface_count>0 and inventory.available_coarsest_triangles<inventory.triangles,class_key+": real rendered native meshes retain imported LOD index reductions after garment finishing")
	check(hero.source_avatar and hero.surface_material==null,class_key+": the actual native player allocates no unused compatibility ShaderMaterial")
	var observer:=Readability.new()
	var original_camera:=camera.transform
	var original_hero:=hero.transform
	for frame in 12:observer.update(hero,camera,false)
	var unoccluded: Dictionary=observer.budget_snapshot()
	check(unoccluded.meshes_created==0 and unoccluded.materials_created==0 and unoccluded.live_replay_meshes==0,class_key+": twelve unobstructed real-hero updates allocate no extra mesh or material")
	check(unoccluded.depth_boxes==0 and unoccluded.camera_inversions==0 and unoccluded.transform_writes==0 and unoccluded.uniform_writes==0 and unoccluded.visibility_writes==0,class_key+": steady unobstructed updates do no depth, uniform or mesh-server work")
	observer.update(hero,camera,true)
	var first: Dictionary=observer.budget_snapshot()
	check(first.live_replay_meshes==inventory.visible_meshes and first.materials_created==1,class_key+": first genuine reveal creates only exact native surfaces and one shared accent material")
	if class_key=="Ranger":check(first.unallocated_hidden_props>0,"Ranger: genuinely hidden idle-arrow surfaces keep weak candidates without replay mesh allocation")
	var shared_geometry:=true
	var shared_material:=true
	var original_materials: Dictionary={}
	for source: MeshInstance3D in hero.body.find_children("*","MeshInstance3D",true,false):
		if source.mesh==null:continue
		if String(source.name).begins_with("OccludedHero_"):continue
		var originals: Array=[]
		for slot in source.mesh.get_surface_count():originals.append(source.get_active_material(slot))
		original_materials[source.get_instance_id()]=originals
	for entry in observer.surfaces:
		var source:=entry.source.get_ref() as MeshInstance3D
		var copy:=entry.copy.get_ref() as MeshInstance3D
		shared_geometry=shared_geometry and copy.mesh==source.mesh and copy.skin==source.skin and copy.get_parent()==source.get_parent()
		shared_geometry=shared_geometry and copy.lod_bias==source.lod_bias and copy.custom_aabb==source.custom_aabb
		shared_material=shared_material and copy.material_override==observer.material and copy.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	check(shared_geometry and shared_material,class_key+": reveal duplicates neither native mesh resources nor PBR materials, skeletons or shadows")
	var maximum_error:=0.0
	var active_frames: Array=[]
	for style in ["basic","signature"]:
		hero.cancel_attack();hero.attack_time=-1;hero.release_time=-1
		hero.strike(style,.3,true)
		for left in [.3,.18,.06]:
			hero.sync_attack(left);hero.animate(0,false);observer.update(hero,camera,true)
			var reference:=native_corner_depth(hero,camera,observer)
			var error: float=absf(observer.nearest_depth-float(reference.near))
			maximum_error=maxf(maximum_error,error)
			var budget: Dictionary=observer.budget_snapshot()
			check(error<.0001 and budget.depth_boxes==reference.boxes,class_key+" "+style+": analytic depth agrees with the original corner minimum through the actual native cast")
			check(budget.depth_corner_projections==0 and budget.bone_or_prop_transforms<=reference.boxes,class_key+" "+style+": body/attire share bone transforms and no eight-corner depth loop remains")
			active_frames.append({"style":style,"left":left,"legacy":reference,"current":budget})
	observer.update(hero,camera,true)
	var stationary: Dictionary=observer.budget_snapshot()
	var displayed:=0
	var missing_visible_prop:=false
	for part: MeshInstance3D in hero.motion_rig.weapon.find_children("*","MeshInstance3D",true,false):
		if not part.is_visible_in_tree() or String(part.name).begins_with("OccludedHero_"):continue
		var mirrored:=false
		for entry in observer.surfaces:mirrored=mirrored or entry.source.get_ref()==part
		missing_visible_prop=missing_visible_prop or not mirrored
	for entry in observer.surfaces:
		if entry.copy.get_ref().visible:displayed+=1
	check(not missing_visible_prop,class_key+": every currently visible held prop, including an arrow first shown by the real cast, has an exact replay sibling")
	if class_key=="Ranger":check(stationary.unallocated_hidden_props==0 and stationary.meshes_created>first.meshes_created,"Ranger: the actual nocked cast activates its formerly absent arrow geometry exactly once")
	check(stationary.transform_writes==0 and stationary.visibility_writes==0 and stationary.uniform_writes==0,class_key+": an identical visible pose sends no redundant transform, visibility or uniform writes")
	# Verify exact small transform edits are not rounded away by the write guard.
	var source:=observer.surfaces[0].source.get_ref() as MeshInstance3D
	var copy:=observer.surfaces[0].copy.get_ref() as MeshInstance3D
	var original_transform:=source.transform
	source.position+=Vector3(0,.000001,0)
	observer.update(hero,camera,true)
	check(observer.surface_transform_writes==1 and copy.transform==source.transform,class_key+": a real micrometer source-transform change still reaches its replay sibling")
	source.transform=original_transform;observer.update(hero,camera,true)
	observer.update(hero,camera,false)
	check(observer.surface_visibility_writes==displayed,class_key+": the visible-to-unoccluded transition hides each currently visible extra draw exactly once")
	for frame in 12:observer.update(hero,camera,false)
	var disabled: Dictionary=observer.budget_snapshot()
	check(disabled.depth_boxes==0 and disabled.camera_inversions==0 and disabled.transform_writes==0 and disabled.visibility_writes==0 and disabled.uniform_writes==0,class_key+": subsequent disabled frames require no hidden-skin depth or server updates")
	check(disabled.meshes_created==stationary.meshes_created and disabled.materials_created==1,class_key+": repeated reveals reuse exact meshes after the real held-prop first activation, and one shared material")
	observer.update(hero,camera,true)
	var pbr_unchanged:=true
	for entry in observer.surfaces:
		var part:=entry.source.get_ref() as MeshInstance3D
		for slot in part.mesh.get_surface_count():pbr_unchanged=pbr_unchanged and part.get_active_material(slot)==original_materials[part.get_instance_id()][slot]
	check(pbr_unchanged and camera.transform==original_camera and hero.transform==original_hero,class_key+": budgeting changes no opaque PBR identity, camera or authoritative actor transform")
	receipt.classes.append({"class":class_key,"inventory":inventory,"first_reveal":first,"unoccluded":unoccluded,
		"stationary_reveal":stationary,"disabled_after_reveal":disabled,"active_frames":active_frames,"maximum_depth_error_m":maximum_error})
	observer.dispose()
	check(hero.body.find_children("OccludedHero_*","MeshInstance3D",true,false).is_empty(),class_key+": disposal returns the native hierarchy to its original geometry")

func check_actor_shader_budget(world: Node3D,label: String) -> void:
	var actors: Array=[world.hero]
	actors.append_array(world.enemies)
	for actor: Node3D in actors:
		check(actor.source_avatar and actor.surface_material==null,label+" "+String(actor.kind)+": actual native actor retains no unused compatibility shader instance")
		receipt.native_actor_materials.append({"world":label,"kind":String(actor.kind),"native":bool(actor.source_avatar),
			"compatibility_shader_instances":0 if actor.surface_material==null else 1})
	var original_phase: String=world.phase
	var original_death: float=world.hero.death_time
	var original_camera: Transform3D=world.camera.transform
	world.hero_window_calls=0;world.phase="travel"
	world._update_combat_readability(0)
	check(world.hero_window_calls==0 and not world.combat_readability.enabled,label+": real travel update omits all hero occlusion-window corner projections")
	world.phase="combat";world.hero.death_time=0.0
	world._update_combat_readability(0)
	check(world.hero_window_calls==0 and not world.combat_readability.enabled,label+": defeated-hero update omits the occlusion projection and replay draws")
	world.hero.death_time=original_death
	world._update_combat_readability(0)
	check(world.hero_window_calls==1 and world.camera.transform==original_camera,label+": living combat still constructs its real hero window without moving the camera")
	world.phase=original_phase

func read_render_counts() -> Dictionary:
	return {"visible_primitives":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),
		"shadow_primitives":root.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),
		"visible_draw_calls":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
		"shadow_draw_calls":root.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)}

func settled_render_counts() -> Dictionary:
	for frame in 4:
		await process_frame
		await RenderingServer.frame_post_draw
	RenderingServer.force_sync()
	return read_render_counts()

func check_native_render_lods(world: Node3D,class_key: String) -> void:
	# Diagnostic setting changes only; restore the shipped threshold exactly.
	# Same frozen World, native meshes, pose, camera and viewport throughout.
	var threshold: float=root.mesh_lod_threshold
	var before: String=world.simulation.encode_snapshot()
	var camera_before: Transform3D=world.camera.transform
	var actor_before: Transform3D=world.hero.transform
	var current: Dictionary=await settled_render_counts()
	root.mesh_lod_threshold=0.0
	var full: Dictionary=await settled_render_counts()
	root.mesh_lod_threshold=threshold
	var restored: Dictionary=await settled_render_counts()
	check(current.visible_primitives>0 and full.visible_primitives>0,class_key+": native GL renderer reports actual visible mesh primitives")
	check(current.visible_primitives<=full.visible_primitives and current.shadow_primitives<=full.shadow_primitives,class_key+": shipped automatic LOD uses no more real visible/shadow triangles than the same full-detail world")
	check(current==restored,class_key+": restoring the exact shipped threshold restores every measured primitive and draw-call count")
	check(world.simulation.encode_snapshot()==before and world.camera.transform==camera_before and world.hero.transform==actor_before,class_key+": native geometry assay moves no camera/actor and changes no combat authority")
	receipt.native_render_primitives.append({"class":class_key,"renderer":RenderingServer.get_current_rendering_method(),
		"driver":RenderingServer.get_current_rendering_driver_name(),"window_size":[root.size.x,root.size.y],
		"viewport_rect_size":[root.get_visible_rect().size.x,root.get_visible_rect().size.y],"shipped_threshold":threshold,
		"current":current,"lod_disabled":full,"threshold_restored":restored,
		"visible_primitive_reduction":full.visible_primitives-current.visible_primitives,
		"shadow_primitive_reduction":full.shadow_primitives-current.shadow_primitives,
		"scope":"One frozen real dungeon initial view before diagnostic pose/occlusion checks; GL Compatibility native triangle primitive counters, no frame-time or physical-device claim"})

func check_dressing(world: Node3D,region: int) -> void:
	var shot: Transform3D=world.camera.transform
	var window: Dictionary=world._hero_occlusion_window()
	var initial: Dictionary={"measure":true}
	var overlap: bool=Readability.dressing_overlaps(world.camera,window.rect,window.far,world.occluder_batches,initial)
	check(overlap==legacy_dressing(world.camera,window.rect,window.far,world.occluder_batches),"region %d: real visible chamber batches preserve the original broad-phase result" % region)
	var stable: Dictionary={"measure":true}
	var repeated: bool=Readability.dressing_overlaps(world.camera,window.rect,window.far,world.occluder_batches,stable)
	check(repeated==overlap and stable.projected_corners==0 and stable.depth_support_evaluations==0 and stable.camera_inversions==0,"region %d: identical real camera/batch transforms reuse projection and depth with zero corner projections" % region)
	check(stable.candidates==0 or stable.cached_batches==stable.candidates,"region %d: every visited eligible batch actually uses its existing projection cache" % region)
	var rejected: Dictionary={"measure":true}
	check(not Readability.dressing_overlaps(world.camera,window.rect,-INF,world.occluder_batches,rejected) and rejected.projected_corners==0 and rejected.depth_rejections==rejected.candidates,"region %d: fully rearward candidates reject before all eight perspective projections" % region)
	for shift in [Vector2.ZERO,Vector2(1000,700)]:
		for far in [window.far,window.far+1000.0]:
			var rect: Rect2=Rect2(window.rect.position+shift,window.rect.size)
			check(Readability.dressing_overlaps(world.camera,rect,far,world.occluder_batches)==legacy_dressing(world.camera,rect,far,world.occluder_batches),"region %d: cached batch projections remain correct when hero window/depth changes" % region)
	world.camera.position+=Vector3(.17,.11,-.09)
	var moved: Dictionary={"measure":true}
	check(Readability.dressing_overlaps(world.camera,window.rect,window.far,world.occluder_batches,moved)==legacy_dressing(world.camera,window.rect,window.far,world.occluder_batches),"region %d: actual camera movement invalidates cached world projections" % region)
	check(moved.candidates==0 or moved.depth_support_evaluations>0,"region %d: moved-camera budget demonstrates actual cache invalidation" % region)
	world.camera.transform=shot
	var previous_fov: float=world.camera.fov
	world.camera.fov+=1.0
	check(Readability.dressing_overlaps(world.camera,window.rect,window.far,world.occluder_batches)==legacy_dressing(world.camera,window.rect,window.far,world.occluder_batches),"region %d: a changed lens invalidates screen projections" % region)
	world.camera.fov=previous_fov
	# Source bounds and transforms are part of the cache key, not assumed static.
	var edited: Node3D
	for entry in world.occluder_batches:
		if entry.node.is_visible_in_tree():edited=entry.node;break
	if edited!=null:
		var previous: Transform3D=edited.transform
		edited.position+=Vector3(.31,0,.19)
		check(Readability.dressing_overlaps(world.camera,window.rect,window.far,world.occluder_batches)==legacy_dressing(world.camera,window.rect,window.far,world.occluder_batches),"region %d: a moved real dressing batch cannot reuse stale occlusion coordinates" % region)
		edited.transform=previous
	receipt.dressing.append({"region":region,"actual_batch_count":world.occluder_batches.size(),"overlap":overlap,
		"first":initial,"same_camera_and_batches":stable,"moved_camera":moved,
		"legacy_corner_projections_for_visited_batches":stable.candidates*8,"current_stable_corner_projections":stable.projected_corners})

func run_checks() -> void:
	root.size=Vector2i(960,540)
	await process_frame
	require_native_render=OS.get_cmdline_user_args().has("--require-native-render")
	if require_native_render:
		check(RenderingServer.get_current_rendering_method()=="gl_compatibility" and DisplayServer.get_name()!="headless","native assay uses an actual GL Compatibility display/rendering server")
		if failures>0:
			print("RENDER BUDGET SMOKE: %d checks, %d failures" % [checks,failures]);quit(1);return
	check_lod_packing()
	check_hostile_geometry()
	# Independent transformed-box probes cover rotations and nonuniform scale.
	for index in 48:
		var basis:=Basis.from_euler(Vector3(index*.071,index*.037,index*.113)).scaled_local(Vector3(.4+index*.013,1.7,.6))
		var transform:=Transform3D(basis,Vector3(index*.07,.8,-13-index*.11))
		var bounds:=AABB(Vector3(-.7,-.04,-.38),Vector3(1.3,2.1,.76))
		check(absf(Readability.front_depth(transform,bounds)-corner_depth(transform,bounds))<.0001,"rotated/nonuniform box %d: analytic support equals all eight independent corners" % index)
	var game:=Bot.new()
	for class_key in ["Arcanist","Vowkeeper","Ranger"]:
		game.character_class=class_key
		var sim:=Sim.new();sim.setup(class_key,game._combat_stats(),1,"Guardian",1979)
		var before:=sim.encode_snapshot()
		var world: Node3D=BudgetWorld.new();world.simulation=sim;world.character_class=class_key;world.region_index=0;world.active=false
		root.add_child(world)
		if require_native_render:await check_native_render_lods(world,class_key)
		world.combat_readability.dispose()
		check_native(world.hero,world.camera,class_key)
		if class_key=="Arcanist":check_dressing(world,0)
		check_actor_shader_budget(world,class_key)
		check(sim.encode_snapshot()==before,class_key+": all real-world geometry/depth checks leave the simulation ledger unchanged")
		world.free()
	for region in range(1,4):
		game.character_class="Arcanist"
		var sim:=Sim.new();sim.setup("Arcanist",game._combat_stats(),region*10+1,"Guardian",1979)
		var before:=sim.encode_snapshot()
		var world: Node3D=BudgetWorld.new();world.simulation=sim;world.character_class="Arcanist";world.region_index=region;world.active=false
		root.add_child(world)
		world.combat_readability.dispose()
		check_dressing(world,region)
		check(sim.encode_snapshot()==before,"region %d: cached dressing never changes combat authority" % region)
		world.free()
	game.free()
	receipt.checks=checks;receipt.failures=failures
	print("RENDER_BUDGET_RECEIPT ",JSON.stringify(receipt))
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--budget-report="):
			var file:=FileAccess.open(argument.trim_prefix("--budget-report="),FileAccess.WRITE)
			if file!=null:file.store_string(JSON.stringify(receipt,"\t")+"\n")
	print("RENDER BUDGET SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
