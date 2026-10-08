extends "res://scripts/class_avatar_style.gd"
## Original male cloth is a replacement, never a second coincident tunic.
## Steel shells reuse authored panels and all four original native influences.
const PALETTES: Dictionary={
	"hexer":Color(.36,.41,.32),"bulwark":Color(.46,.20,.18),"elite":Color(.30,.32,.40),
	"guardian_0":Color(.48,.25,.19),"guardian_1":Color(.30,.37,.41),
	"guardian_2":Color(.30,.34,.30),"guardian_3":Color(.48,.27,.19),
}
const METALS: Dictionary={
	"bulwark":Color(.40,.44,.47),"elite":Color(.47,.50,.54),
	"guardian_0":Color(.49,.40,.28),"guardian_1":Color(.43,.43,.40),
	"guardian_2":Color(.39,.46,.40),"guardian_3":Color(.45,.34,.25),
}
static var hands_mesh_cache: ArrayMesh
static var shield_mesh_cache: ArrayMesh
static var shield_skin_cache: Skin
const NativeMeshLods=preload("res://scripts/native_mesh_lods.gd")
var shield_part: MeshInstance3D
var shield_original_bind:=Transform3D.IDENTITY
var shield_source_center:=Vector3.ZERO
var shield_actual_transform:=Transform3D.IDENTITY

func apply_clothing(rig: RefCounted,source: Node3D) -> void:
	rig_ref=weakref(rig)
	var actual: Array[MeshInstance3D]=[]
	for surface: MeshInstance3D in rig.surfaces:
		var name=String(surface.name)
		if name=="Male_Peasant_Arms":
			if hands_mesh_cache==null:
				hands_mesh_cache=ArrayMesh.new()
				for slot in surface.mesh.get_surface_count():
					var material=surface.get_active_material(slot) as StandardMaterial3D
					if material!=null and String(material.resource_name).contains("Regular_Male"):
						hands_mesh_cache.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,surface.mesh.surface_get_arrays(slot),[],NativeMeshLods.lods_for(surface.mesh,slot))
						hands_mesh_cache.surface_set_material(hands_mesh_cache.get_surface_count()-1,material)
			assert(hands_mesh_cache.get_surface_count()==1)
			var material=surface.get_active_material(1)
			surface.mesh=hands_mesh_cache;surface.set_surface_override_material(0,material)
			actual.append(surface)
		elif name=="Male_Peasant_Feet" or not name.begins_with("Male_Peasant_"):actual.append(surface)
		else:surface.free()
	for original: MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
		var name=String(original.name)
		# Casters show a clean hood and cloth sleeve; armored roles expose
		# their original male head and carry the real authored shoulder panels.
		if name.contains("Head_Hood") and rig.key in ["bulwark","elite","guardian_0","guardian_3"]:continue
		if name.contains("Pauldron") and rig.key=="hexer":continue
		if name.contains("Bracer") and rig.key in ["hexer","guardian_1","guardian_2"]:continue
		var part=MeshInstance3D.new();part.name=original.name;part.mesh=original.mesh;part.skin=original.skin
		part.transform=original.transform;part.layers=2;part.ignore_occlusion_culling=true;part.extra_cull_margin=3.0
		rig.motion_node.add_child(part);part.skeleton=part.get_path_to(rig.skeleton)
		for slot in part.mesh.get_surface_count():
			var material=original.get_active_material(slot).duplicate() as StandardMaterial3D
			material.albedo_color=PALETTES[rig.key];material.roughness=.91;material.normal_scale=.58
			part.set_surface_override_material(slot,material)
		actual.append(part)
	rig.surfaces=actual
	for surface in actual:
		if String(surface.name)=="Male_Peasant_Feet":
			for slot in surface.mesh.get_surface_count():
				var material=surface.get_active_material(slot) as StandardMaterial3D
				material.albedo_color=Color(.28,.25,.22);material.roughness=.92

func apply_armor(rig: RefCounted) -> void:
	if not METALS.has(rig.key):return
	for surface: MeshInstance3D in rig.surfaces:
		var name=String(surface.name)
		if name.contains("Pauldron") or name.contains("Bracer"):
			_shell(surface,0,"Hostile057_"+rig.key+"_"+name,METALS[rig.key],.010)
			surface.hide()
		elif name=="Male_Ranger_Body" and rig.key in ["bulwark","elite","guardian_0","guardian_3"]:
			_breastplate(surface)
			var part: MeshInstance3D=accessories.back();part.name="Hostile057_"+rig.key+"_FittedBreastplate"
			var material=part.get_active_material(0) as StandardMaterial3D;material.albedo_color=METALS[rig.key]
	var visible: Array[MeshInstance3D]=[]
	for surface in rig.surfaces:
		if surface.visible:visible.append(surface)
		else:
			for slot in surface.mesh.get_surface_count():rig.triangles-=surface.mesh.surface_get_arrays(slot)[Mesh.ARRAY_INDEX].size()/3
	rig.surfaces=visible
	if rig.key=="bulwark":_forearm_shield(rig)

func _forearm_shield(rig: RefCounted) -> void:
	# A strapped shield belongs to the real forearm. No unclosed off-hand is
	# presented as gripping a detached handle, and no finger fit is invented.
	var bone=rig.skeleton.find_bone("lowerarm_l")
	var bind=rig.skeleton.get_bone_global_rest(bone)
	var hand=rig.skeleton.get_bone_global_rest(rig.skeleton.find_bone("hand_l")).origin
	var center=bind.origin.lerp(hand,.54)+Vector3(0,0,.13)
	var points=PackedVector3Array();var normals=PackedVector3Array();var uv=PackedVector2Array()
	var bones=PackedInt32Array();var weights=PackedFloat32Array();var indices=PackedInt32Array()
	for layer in 2:
		points.append(center+Vector3(0,0,.028 if layer==0 else -.012));normals.append(Vector3.BACK if layer==0 else Vector3.FORWARD);uv.append(Vector2(.5,.5))
		for corner in 12:
			var angle=float(corner)/12.0*TAU
			points.append(center+Vector3(cos(angle)*.215,sin(angle)*.295,0 if layer==0 else -.018))
			normals.append(Vector3.BACK if layer==0 else Vector3.FORWARD);uv.append(Vector2(cos(angle),sin(angle))*.5+Vector2(.5,.5))
	for corner in 12:
		var a=corner+1;var b=(corner+1)%12+1
		indices.append_array(PackedInt32Array([0,b,a,13,a+13,b+13,a,b,b+13,a,b+13,a+13]))
	for point in points:bones.append_array(PackedInt32Array([0,0,0,0]));weights.append_array(PackedFloat32Array([1,0,0,0]))
	var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=points;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_TEX_UV]=uv
	arrays[Mesh.ARRAY_BONES]=bones;arrays[Mesh.ARRAY_WEIGHTS]=weights;arrays[Mesh.ARRAY_INDEX]=indices
	if shield_mesh_cache==null:
		shield_mesh_cache=ArrayMesh.new();shield_mesh_cache.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		shield_skin_cache=Skin.new();shield_skin_cache.add_named_bind("lowerarm_l",bind.affine_inverse())
	var part=MeshInstance3D.new();part.name="Hostile057_StrappedForearmShield";part.mesh=shield_mesh_cache;part.skin=shield_skin_cache.duplicate() as Skin;part.layers=2;part.extra_cull_margin=3.0
	shield_part=part;shield_original_bind=bind.affine_inverse();shield_source_center=center
	rig.motion_node.add_child(part);part.skeleton=part.get_path_to(rig.skeleton)
	var material=StandardMaterial3D.new();material.albedo_color=Color(.28,.33,.36);material.metallic=.78;material.roughness=.58;material.cull_mode=BaseMaterial3D.CULL_DISABLED
	part.set_surface_override_material(0,material);accessories.append(part);triangle_count+=indices.size()/3
	var original_count=rig.triangles;rig._index_surface(part,0);rig.triangles=original_count

func update_death_attachment(rig: RefCounted,clip: String,time: float) -> void:
	if shield_part==null:return
	var bone=rig.skeleton.find_bone("lowerarm_l")
	var forearm=rig.skeleton.get_bone_global_pose(bone)
	var attached=forearm*shield_original_bind
	shield_actual_transform=attached
	if clip=="death":
		var basis=Basis(Vector3.RIGHT,-PI*.5)
		var target=Transform3D(basis,Vector3(-.42,.045-rig.motion_node.position.y,.14)-basis*shield_source_center)
		shield_actual_transform=attached.interpolate_with(target,smoothstep(.20,.82,time))
		var low=INF
		for point in shield_part.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			low=minf(low,(rig.motion_node.transform*(shield_actual_transform*point)).y)
		if low<.003:shield_actual_transform.origin.y+=.003-low
	# Only the generated accessory's owned bind changes. Original source body
	# skins, all65 bones and every shared living shield remain untouched.
	shield_part.skin.set_bind_pose(0,forearm.affine_inverse()*shield_actual_transform)

func current_bounds() -> AABB:
	var rig=rig_ref.get_ref()
	if rig==null or shield_part==null:return AABB()
	return rig.motion_node.transform*(shield_actual_transform*shield_part.mesh.get_aabb())

func _breastplate(source: MeshInstance3D) -> void:
	var rig=rig_ref.get_ref()
	var label="Hostile057_OriginalMale_Breastplate"
	var armor: ArrayMesh=armor_cache.get(label)
	if armor==null:
		var original=source.mesh.surface_get_arrays(0)
		var source_points: PackedVector3Array=original[Mesh.ARRAY_VERTEX]
		var source_indices: PackedInt32Array=original[Mesh.ARRAY_INDEX]
		var points=PackedVector3Array();var normals=PackedVector3Array();var uv=PackedVector2Array()
		var bones=PackedInt32Array();var weights=PackedFloat32Array();var indices=PackedInt32Array()
		var rows=8;var columns=8
		for row in rows:
			var y=lerpf(1.145,1.425,float(row)/(rows-1))
			var width=lerpf(.095,.110,sin(float(row)/(rows-1)*PI))
			for column in columns:
				var x=lerpf(-width,width,float(column)/(columns-1))
				var sample=Vector2(x,y);var fitted=Vector3(x,y,-INF);var influences={};var found=false
				for offset in range(0,source_indices.size(),3):
					var a=source_points[source_indices[offset]];var b=source_points[source_indices[offset+1]];var c=source_points[source_indices[offset+2]]
					if maxf(a.z,maxf(b.z,c.z))<.035:continue
					var bary=_barycentric(sample,Vector2(a.x,a.y),Vector2(b.x,b.y),Vector2(c.x,c.y))
					if bary.x<-.00001 or bary.y<-.00001 or bary.z<-.00001:continue
					var z=a.z*bary.x+b.z*bary.y+c.z*bary.z
					if z<.035:continue
					if found and z<=fitted.z:continue
					fitted.z=z;found=true;influences.clear()
					for corner in 3:
						var vertex=source_indices[offset+corner]
						for influence in 4:
							var bone=int(original[Mesh.ARRAY_BONES][vertex*4+influence])
							influences[bone]=float(influences.get(bone,0.0))+float(original[Mesh.ARRAY_WEIGHTS][vertex*4+influence])*bary[corner]
				assert(found,"Steel breastplate corner must fit an actual indexed source torso triangle: "+str(sample)+" bounds "+str(source.mesh.get_aabb()))
				# Covers raised original garment lacing, rather than cloning its
				# disconnected holes and letting the old straps pierce the plate.
				# The separate original Ranger belt also carries raised torso
				# straps.46mm also clears them during the actual Hit_Chest overlay.
				fitted.z+=.046
				points.append(fitted);normals.append(Vector3.BACK);uv.append(Vector2(float(column)/(columns-1),float(row)/(rows-1)))
				var ordered=influences.keys();ordered.sort_custom(func(a,b):return influences[a]>influences[b])
				var total=0.0
				for influence in mini(4,ordered.size()):total+=influences[ordered[influence]]
				for influence in 4:
					bones.append(ordered[influence] if influence<ordered.size() else 0)
					weights.append(float(influences[ordered[influence]])/total if influence<ordered.size() else 0.0)
		for row in rows-1:
			for column in columns-1:
				var a=row*columns+column;var b=a+1;var c=a+columns;var e=c+1
				# Godot renders clockwise front faces. Keep outward +Z normals
				# while ordering the front sheet clockwise as original imports.
				indices.append_array(PackedInt32Array([a,c,b,b,c,e]))
		for index in normals.size():normals[index]=Vector3.ZERO
		for offset in range(0,indices.size(),3):
			var a=indices[offset];var b=indices[offset+1];var c=indices[offset+2]
			var normal=-(points[b]-points[a]).cross(points[c]-points[a])
			normals[a]+=normal;normals[b]+=normal;normals[c]+=normal
		for index in normals.size():normals[index]=normals[index].normalized()
		var arrays=[];arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX]=points;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_TEX_UV]=uv
		arrays[Mesh.ARRAY_BONES]=bones;arrays[Mesh.ARRAY_WEIGHTS]=weights;arrays[Mesh.ARRAY_INDEX]=indices
		armor=ArrayMesh.new();armor.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);armor_cache[label]=armor
	var material=StandardMaterial3D.new();material.resource_name=label+"_Worn_Steel"
	material.albedo_color=Color(.42,.47,.52);material.metallic=.68;material.roughness=.50;material.cull_mode=BaseMaterial3D.CULL_DISABLED
	var part=MeshInstance3D.new();part.name=label;part.mesh=armor;part.skin=source.skin;part.layers=2
	part.ignore_occlusion_culling=true;part.extra_cull_margin=3.0;part.set_surface_override_material(0,material)
	rig.motion_node.add_child(part);part.skeleton=part.get_path_to(rig.skeleton);accessories.append(part)
	triangle_count+=armor.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size()/3
	var source_count=rig.triangles;rig._index_surface(part,0);rig._append_weighted_probes(part,0);rig.triangles=source_count
