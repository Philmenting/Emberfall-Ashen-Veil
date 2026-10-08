extends SceneTree
## Exercise the actually rendered added cloth/metal with all native influences,
## source texture retention, per-actor overrides, live poses and the death floor.
const Actor=preload("res://scripts/dungeon_actor.gd")
const Original=preload("res://assets/models/nyra052/arcanist.glb")
var checks:=0
var failures: Array[String]=[]
var probes: Array=[]
var poses:=0
var maximum_floor_shift:=0.0
var native_readback:=false

func check(value: bool,message: String) -> void:
	checks+=1
	if not value:failures.append(message);push_error(message)

func _initialize() -> void:call_deferred("run")

func source_materials_preserved(rig: Variant) -> bool:
	var original=Original.instantiate()
	var found=true
	for surface in rig.surfaces:
		var source=original.find_child(String(surface.name),true,false) as MeshInstance3D
		if source==null:found=false;continue
		for slot in surface.mesh.get_surface_count():
			var a=surface.get_active_material(slot) as StandardMaterial3D
			var b=source.get_active_material(slot) as StandardMaterial3D
			found=found and a!=null and b!=null
			if a==null or b==null:continue
			found=found and a!=b and a.albedo_texture==b.albedo_texture and a.normal_texture==b.normal_texture and a.roughness_texture==b.roughness_texture
	original.free()
	return found

func cache_actual_attire(rig: Variant,style: Variant) -> void:
	probes.clear()
	var indexed=0
	var weights_valid=true
	var native_rest_valid=true
	var largest_weight_error=0.0
	var unorm16_valid=true
	# Godot stores each native skin weight as unsigned normalized16 bits.
	# Four independently packed influences can lose at most four LSBs;
	# 4*float32 epsilon covers the readback conversion. Source GLB sums
	# remain accurate to 1.2e-7; this bound describes the actual renderer.
	var packed_sum_budget=4.0/65535.0+4.0*0.000000059605
	var largest_weight_vertex=""
	var minimum_weight_sum=INF
	var maximum_weight_sum=-INF
	var missing_binds=0
	var wrong_stride=0
	for part in style.accessories:
		for slot in part.mesh.get_surface_count():
			var arrays=part.mesh.surface_get_arrays(slot)
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			var binds: PackedInt32Array=arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
			weights_valid=weights_valid and weights.size()==vertices.size()*4
			if weights.size()!=vertices.size()*4:wrong_stride+=1
			var used: Dictionary={}
			for index in indices:used[index]=true
			for index in used:
				indexed+=1
				var influences: Array=[]
				var total=0.0
				for influence in 4:
					var weight=weights[index*4+influence]
					unorm16_valid=unorm16_valid and is_finite(weight) and weight>=0.0 and weight<=1.0 and absf(weight*65535.0-roundf(weight*65535.0))<.004
					total+=weight
					if weight<=0.0:continue
					var bind=binds[index*4+influence]
					var name=part.skin.get_bind_name(bind)
					var bone=rig.skeleton.find_bone(name) if name!=&"" else part.skin.get_bind_bone(bind)
					weights_valid=weights_valid and bone>=0
					if bone<0:missing_binds+=1;continue
					var local=part.skin.get_bind_pose(bind)*vertices[index]
					var restored=rig.skeleton.get_bone_global_rest(bone)*local
					native_rest_valid=native_rest_valid and restored.distance_to(vertices[index])<.0001
					influences.append([bone,part.skin.get_bind_pose(bind),weight])
				if absf(total-1.0)>largest_weight_error:
					largest_weight_error=absf(total-1.0)
					largest_weight_vertex=String(part.name)+" vertex "+str(index)+" sum "+str(total)+" weights "+str([weights[index*4],weights[index*4+1],weights[index*4+2],weights[index*4+3]])
				minimum_weight_sum=minf(minimum_weight_sum,total)
				maximum_weight_sum=maxf(maximum_weight_sum,total)
				weights_valid=weights_valid and absf(total-1.0)<=packed_sum_budget
				probes.append({"mesh":String(part.name),"part":part,"slot":slot,"index":index,"influences":influences})
	print("ACTUAL ATTIRE WEIGHTS: max normalization error=",largest_weight_error,"; missing binds=",missing_binds,"; wrong strides=",wrong_stride,"; minsum=",minimum_weight_sum,"; maxsum=",maximum_weight_sum,"; worst=",largest_weight_vertex)
	check(indexed>1500,"Audit exercises real indexed added geometry, not sockets or proxy bounds")
	check(weights_valid,"All four actual attire influences resolve and normalize within the measured UNORM16 four-influence precision budget")
	check(unorm16_valid,"Actual renderer weight readback conforms to UNORM16 precision without invalid or missing influences")
	check(native_rest_valid,"Original native rest and imported accessory inverse binds agree below 0.1 mm")

func actual_attire_bounds(rig: Variant) -> AABB:
	var first=true
	var result:=AABB()
	var transforms: Array[Transform3D]=[]
	for bone in rig.skeleton.get_bone_count():transforms.append(rig.skeleton.get_bone_global_pose(bone))
	var actual_vertices: Dictionary={}
	for record in probes:
		var key=str(record.part.get_instance_id())+":"+str(record.slot)
		if not actual_vertices.has(key):
			# Read the renderer's current vertex region on every pose. Cached
			# imported positions would omit the new secondary textile uploads.
			var arrays: Array=record.part.mesh.surface_get_arrays(record.slot)
			actual_vertices[key]=arrays[Mesh.ARRAY_VERTEX]
		var vertex: Vector3=actual_vertices[key][record.index]
		var point=Vector3.ZERO
		for influence in record.influences:point+=(transforms[influence[0]]*influence[1]*vertex)*influence[2]
		point=rig.motion_node.transform*point
		if not point.is_finite():return AABB(Vector3(-INF,-INF,-INF),Vector3(INF,INF,INF))
		result=AABB(point,Vector3.ZERO) if first else result.expand(point)
		first=false
	return result

func audit_pose(actor: Node3D,label: String,time: float) -> void:
	var rig=actor.motion_rig
	rig.pose(label,time)
	rig.apply_actor_postprocess(actor,label,time,0.0,true)
	if native_readback:RenderingServer.force_sync()
	var box=actual_attire_bounds(rig)
	check(box.position.is_finite() and box.size.is_finite() and box.size.y<2.8 and box.size.x<3.0,label+": actually weighted attire stays finite and proportional")
	check(box.position.y>=-.001,label+": actual cloth/metal clears the source floor, min_y="+str(box.position.y))
	var envelope: AABB=rig.bounds.grow(.0002)
	check(envelope.encloses(box),label+": live actor bounds include actually rendered attire")
	if label=="death":maximum_floor_shift=maxf(maximum_floor_shift,float(rig.style.hem_floor_offset()))
	poses+=1

func run() -> void:
	native_readback=DisplayServer.get_name()!="headless" and not RenderingServer.get_video_adapter_name().is_empty()
	if "--require-gpu" in OS.get_cmdline_user_args() and not native_readback:
		push_error("Source style GPU verification requires an actual native GL/Vulkan renderer")
		quit(1)
		return
	if not native_readback:
		print("SOURCE AVATAR STYLE ORACLE: imported-surface readback only; Dummy secondary vertex-region updates are no-op")
	else:
		print("SOURCE AVATAR STYLE ORACLE: native renderer readback includes current secondary vertex-region uploads")
	var actor=Actor.new();actor.kind="Arcanist";root.add_child(actor)
	var peer=Actor.new();peer.kind="Arcanist";root.add_child(peer)
	var rig=actor.motion_rig
	var style=rig.get("style")
	check(actor.source_avatar and style!=null,"Ordinary Arcanist instantiates the actual attire finish")
	if style==null:
		actor.free();peer.free();print("SOURCE AVATAR STYLE SMOKE: ",checks," checks, ",failures.size()," failures");quit(1);return
	check(rig.surfaces.size()==8 and rig.skeleton.get_bone_count()==65,"Original eight source meshes and native65 skeleton remain intact")
	check(rig.motion_node.find_children("*","Skeleton3D",true,false).size()==1,"Accessories bind to one original skeleton without a second running rig")
	check(style.accessories.size()==11 and style.triangle_count==3936,"Eleven real fitted accessory meshes retain the measured triangle inventory")
	check(source_materials_preserved(rig),"Original source UV PBR albedo/normal/roughness textures remain on every original mesh")
	var peer_style=peer.motion_rig.style
	for index in style.accessories.size():
		var part: MeshInstance3D=style.accessories[index]
		var other: MeshInstance3D=peer_style.accessories[index]
		check(part.is_visible_in_tree() and part.layers==2 and part.get_node_or_null(part.skeleton)==rig.skeleton and part.skin!=null,String(part.name)+": actual renderer follows native skeleton")
		var dynamic: bool=style.motion_owns(part)
		var peer_dynamic: bool=peer_style.motion_owns(other)
		var mesh_ownership: bool=part.mesh!=other.mesh if dynamic else part.mesh==other.mesh
		check(dynamic==peer_dynamic and mesh_ownership and part.skin==other.skin and part.get_active_material(0)!=other.get_active_material(0),String(part.name)+": immutable static geometry is shared; designated secondary buffers and visible materials remain independent")
		if dynamic:
			var a: Array=part.mesh.surface_get_arrays(0)
			var b: Array=other.mesh.surface_get_arrays(0)
			check(a[Mesh.ARRAY_INDEX]==b[Mesh.ARRAY_INDEX] and a[Mesh.ARRAY_BONES]==b[Mesh.ARRAY_BONES] and a[Mesh.ARRAY_WEIGHTS]==b[Mesh.ARRAY_WEIGHTS] and a[Mesh.ARRAY_TEX_UV]==b[Mesh.ARRAY_TEX_UV],String(part.name)+": independent secondary buffers preserve exact original topology, native weights and UV seams")
	var material: StandardMaterial3D=style.accessories[0].get_active_material(0)
	var peer_material: StandardMaterial3D=peer_style.accessories[0].get_active_material(0)
	var original_color:=material.albedo_color
	var peer_color:=peer_material.albedo_color
	material.albedo_color=Color(.4,.1,.3)
	check(peer_material.albedo_color==peer_color,"Changing an actual coat PBR override leaves the peer unaffected")
	material.albedo_color=original_color
	cache_actual_attire(rig,style)
	for t in [.0,.25,.50,.75]:audit_pose(actor,"walk",t)
	for action in ["basic","skill","heavy"]:
		for t in [.0,.35,.70,1.0]:audit_pose(actor,"windup_"+action,t)
		for t in [.0,.14,.34]:audit_pose(actor,"recover_"+action,t)
	for t in [.0,.18,.36,.54,.72,.90]:audit_pose(actor,"death",t)
	audit_pose(actor,"idle",.40)
	check(rig.skeleton.get_bone_count()==65,"Live poses never alter native rest hierarchy or add guessed bones")
	actor.configure_equipment({},"Ranger")
	var old_attire_released=true
	for accessory in style.accessories:old_attire_released=old_attire_released and not is_instance_valid(accessory)
	check(actor.source_avatar and actor.motion_rig!=rig and actor.motion_rig.style!=style and old_attire_released,"Switching native class releases the Arcanist attire with its owning rig")
	actor.configure_equipment({},"Arcanist")
	check(actor.source_avatar and actor.motion_rig.style.accessories.size()==11,"Switching back rebuilds the actual styled source avatar")
	print("SOURCE AVATAR STYLE POSES: ",poses,"; remaining death garment floor offset: ",maximum_floor_shift)
	print("SOURCE AVATAR STYLE SMOKE: ",checks," checks, ",failures.size()," failures")
	actor.free();peer.free();quit(0 if failures.is_empty() else 1)
