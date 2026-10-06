extends RefCounted
## Class silhouettes on the artist's unchanged native65 complete outfit.
## Armor shells use indexed source positions, normals and all four authored
## influences. They never replace or stretch the figure underneath them.
var accessories: Array[MeshInstance3D]=[]
var triangle_count:=0
var rig_ref: WeakRef
static var armor_cache: Dictionary={}

func apply(source_rig: RefCounted) -> void:
	rig_ref=weakref(source_rig)
	var rig=source_rig
	var skin_material: StandardMaterial3D
	for surface: MeshInstance3D in rig.surfaces:
		for slot in surface.mesh.get_surface_count():
			var material=surface.get_active_material(slot) as StandardMaterial3D
			if material!=null and String(material.resource_name).contains("Regular_Female"):
				skin_material=material
				break
	for surface: MeshInstance3D in rig.surfaces:
		var name=String(surface.name)
		for slot in surface.mesh.get_surface_count():
			var material=surface.get_active_material(slot) as StandardMaterial3D
			if material==null:continue
			if name.contains("Head") and not name.contains("Hood"):
				# Matching manufacturer body/face atlas, rather than a pale face
				# attached to the complete Ranger outfit's darker exposed hands.
				if skin_material!=null:material.albedo_texture=skin_material.albedo_texture
				material.albedo_color=Color(.97,.95,.93)
				material.roughness=.78;material.normal_scale=.42
			elif name.contains("Hair") or name.contains("Eyebrows"):
				material.albedo_color=Color(.35,.27,.20)
				material.roughness=.77
			elif name.contains("Eyes"):
				material.roughness=.23
			elif name.contains("Ranger") and not String(material.resource_name).contains("Regular_Female"):
				material.albedo_color=Color(.39,.46,.36) if rig.key=="Ranger" else Color(.68,.22,.18)
				material.roughness=.85
	if rig.key!="Vowkeeper":return
	for surface: MeshInstance3D in rig.surfaces:
		var name=String(surface.name)
		if name.contains("Pauldrons") or name.contains("Bracer"):
			_shell(surface,0,"Vowkeeper055_"+name,Color(.42,.47,.52),.012)
			# Replacement outer steel occupies the exact authored panel; avoid
			# rendering a second coincident cloth panel below opaque armor.
			surface.hide()
		elif name=="Female_Ranger_Body":
			_breastplate(surface)

func _shell(source: MeshInstance3D,region: int,label: String,color: Color,offset: float) -> void:
	var rig=rig_ref.get_ref()
	for slot in source.mesh.get_surface_count():
		var original=source.mesh.surface_get_arrays(slot)
		var vertices: PackedVector3Array=original[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array=original[Mesh.ARRAY_NORMAL]
		var indices: PackedInt32Array=original[Mesh.ARRAY_INDEX]
		var selected=PackedInt32Array()
		var panels=_main_bracer_panels(vertices,indices) if String(source.name).contains("Bracer") else {}
		for index in range(0,indices.size(),3):
			if not panels.is_empty() and not panels.has(index):continue
			var a=vertices[indices[index]];var b=vertices[indices[index+1]];var c=vertices[indices[index+2]]
			var low=minf(a.y,minf(b.y,c.y));var high=maxf(a.y,maxf(b.y,c.y))
			# Use complete logical source panels at their original edge loops.
			if region==1 and (low<1.12 or high>1.49):continue
			if region==2 and (low<.16 or high>.51):continue
			selected.append_array(PackedInt32Array([indices[index],indices[index+1],indices[index+2]]))
		if selected.is_empty():continue
		var cache_key=label+"/"+str(slot)
		var armor: ArrayMesh=armor_cache.get(cache_key)
		if armor==null:
			var arrays=original.duplicate()
			var positions=vertices.duplicate()
			for index in positions.size():positions[index]+=normals[index]*offset
			arrays[Mesh.ARRAY_VERTEX]=positions;arrays[Mesh.ARRAY_INDEX]=selected
			armor=ArrayMesh.new();armor.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			armor_cache[cache_key]=armor
		var material=StandardMaterial3D.new();material.resource_name=label+"_Worn_Steel"
		material.albedo_color=color;material.metallic=.82;material.roughness=.48
		material.cull_mode=BaseMaterial3D.CULL_DISABLED
		var part=MeshInstance3D.new();part.name=label;part.mesh=armor;part.skin=source.skin
		part.layers=2;part.ignore_occlusion_culling=true;part.extra_cull_margin=3.0
		part.set_surface_override_material(0,material)
		rig.motion_node.add_child(part);part.skeleton=part.get_path_to(rig.skeleton)
		accessories.append(part);triangle_count+=selected.size()/3
		# Index only referenced shell vertices in the inherited conservative
		# native bounds. Its all-source-vertex height remains unchanged.
		var original_triangles=rig.triangles
		rig._index_surface(part,0)
		rig._append_weighted_probes(part,0)
		rig.triangles=original_triangles

func current_bounds() -> AABB:
	# Accessory vertices were indexed directly into the rig's native boxes.
	return AABB()

func hem_floor_offset() -> float:return 0.0

func _main_bracer_panels(points: PackedVector3Array,indices: PackedInt32Array) -> Dictionary:
	# The source bracer contains 26 disconnected sleeve/strap/buckle parts.
	# Only the two continuous outer sleeves become steel; small laces and
	# buckles must not be cloned into intersecting foil on the armor surface.
	var welded={};var mapped=PackedInt32Array();var parents=PackedInt32Array()
	for point in points:
		var key=Vector3i(roundi(point.x*100000),roundi(point.y*100000),roundi(point.z*100000))
		if not welded.has(key):welded[key]=parents.size();parents.append(parents.size())
		mapped.append(welded[key])
	for offset in range(0,indices.size(),3):
		var root=_root(parents,mapped[indices[offset]])
		for corner in [1,2]:parents[_root(parents,mapped[indices[offset+corner]])]=root
	var counts={}
	for offset in range(0,indices.size(),3):
		var root=_root(parents,mapped[indices[offset]]);counts[root]=int(counts.get(root,0))+1
	var selected={}
	for offset in range(0,indices.size(),3):
		if int(counts[_root(parents,mapped[indices[offset]])])>=400:selected[offset]=true
	assert(not selected.is_empty(),"Native bracer needs its real continuous sleeve panels")
	return selected

func _root(parents: PackedInt32Array,index: int) -> int:
	while parents[index]!=index:index=parents[index]
	return index

func _breastplate(source: MeshInstance3D) -> void:
	var rig=rig_ref.get_ref()
	var label="Vowkeeper055_Breastplate"
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
			var width=lerpf(.085,.100,sin(float(row)/(rows-1)*PI))
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
				fitted.z+=.026
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

func _barycentric(p: Vector2,a: Vector2,b: Vector2,c: Vector2) -> Vector3:
	var denominator=(b-a).cross(c-a)
	if absf(denominator)<.0000001:return Vector3(-1,-1,-1)
	var v=(p-a).cross(c-a)/denominator;var w=(b-a).cross(p-a)/denominator
	return Vector3(1-v-w,v,w)
