extends RefCounted
## Preserve importer-generated native index LODs while deriving only normals
## or vertex buffers. The caller must retain the complete vertex numbering.
## Mesh.surface_get_lods() is not exposed to GDScript in Godot4.7; the public
## RenderingServer surface dictionary supplies the original packed indices.
static var source_cache: Dictionary={}

static func lods_for(source: Mesh,surface: int) -> Dictionary:
	var key:=str(source.get_instance_id())+"/"+str(surface)
	if source_cache.has(key) and source_cache[key].source.get_ref()==source:
		return source_cache[key].lods
	var data:=RenderingServer.mesh_get_surface(source.get_rid(),surface)
	var indices_by_distance: Dictionary={}
	# This is the exact packing used by RenderingServer's native LOD reader:
	# 65536 vertices still fit indices 0..65535 in unsigned16.
	var width:=2 if int(data.vertex_count)<=65536 else 4
	for level: Dictionary in data.get("lods",[]):
		var bytes: PackedByteArray=level.index_data
		assert(bytes.size()%width==0,"Native LOD has complete packed indices")
		var indices:=PackedInt32Array()
		indices.resize(bytes.size()/width)
		for index in indices.size():
			indices[index]=bytes.decode_u16(index*width) if width==2 else bytes.decode_u32(index*width)
		indices_by_distance[float(level.edge_length)]=indices
	source_cache[key]={"source":weakref(source),"lods":indices_by_distance}
	return indices_by_distance

static func inventory(source: Mesh) -> Dictionary:
	# Explicit inspection only, never part of ordinary actor animation.
	var surfaces: Array=[]
	var lod_surface_count:=0
	var base_triangles:=0
	var coarsest_triangles:=0
	var base_vertices:=0
	var stored_buffer_bytes:=0
	for surface in source.get_surface_count():
		var data:=RenderingServer.mesh_get_surface(source.get_rid(),surface)
		var index_count:=int(data.get("index_count",0))
		var base: int=(index_count if index_count>0 else int(data.vertex_count))/3
		var coarsest:=base
		var levels: Array=[]
		var width:=2 if int(data.vertex_count)<=65536 else 4
		base_vertices+=int(data.vertex_count)
		for buffer in ["vertex_data","attribute_data","skin_data","index_data"]:
			stored_buffer_bytes+=int(data.get(buffer,PackedByteArray()).size())
		for level: Dictionary in data.get("lods",[]):
			var triangles:=int(level.index_data.size())/width/3
			coarsest=mini(coarsest,triangles)
			levels.append({"edge_length":float(level.edge_length),"triangles":triangles,
				"packed_index_bytes":level.index_data.size()})
			stored_buffer_bytes+=int(level.index_data.size())
		if not levels.is_empty():lod_surface_count+=1
		base_triangles+=base;coarsest_triangles+=coarsest
		surfaces.append({"surface":surface,"vertices":int(data.vertex_count),"base_triangles":base,
			"lod_levels":levels,"coarsest_triangles":coarsest})
	var shadow_vertices:=0
	var shadow_triangles:=0
	var shadow_surfaces:=0
	if source is ArrayMesh and source.shadow_mesh!=null:
		for surface in source.shadow_mesh.get_surface_count():
			var data:=RenderingServer.mesh_get_surface(source.shadow_mesh.get_rid(),surface)
			shadow_vertices+=int(data.vertex_count)
			var index_count:=int(data.get("index_count",0))
			shadow_triangles+=(index_count if index_count>0 else int(data.vertex_count))/3
			shadow_surfaces+=1
	return {"surfaces":surfaces,"lod_surface_count":lod_surface_count,"base_triangles":base_triangles,
		"base_vertices":base_vertices,"stored_buffer_bytes":stored_buffer_bytes,
		"coarsest_triangles":coarsest_triangles,"position_only_shadow_surfaces":shadow_surfaces,
		"shadow_vertices":shadow_vertices,"shadow_triangles":shadow_triangles,
		"scope":"Available imported index LODs and optional position-only shadow geometry; renderer selection and actual phone frame time are separate measurements"}
