extends RefCounted
## Assemble complete painted anatomical layers into ONE native GPU surface.
## Bone anchors are in actor space, UV contours are unmodified source pixels.
static func build(rig: RefCounted,data: Dictionary,figure_height: float) -> Dictionary:
	var vertices:=PackedVector3Array(); var uvs:=PackedVector2Array(); var colors:=PackedColorArray()
	var bones:=PackedInt32Array(); var weights:=PackedFloat32Array(); var indices:=PackedInt32Array()
	var boxes: Array[AABB]=[]; boxes.resize(rig.rest.size())
	var valid: Array[bool]=[]; valid.resize(rig.rest.size()); valid.fill(false)
	var texture_size:=Vector2(float(data.source_size[0]),float(data.source_size[1]))
	var bone_indices: Array[int]=[1,2,16,6,3,4,7,8,10,11,13,14]
	# Rear cloth, far limbs, body, near limbs, face and weapon. All painterly
	# overlaps are real complete source parts rather than stretched body pixels.
	for part_index in [2,10,11,6,7,8,9,0,4,5,1,3]:
		var part: Dictionary=data.parts[part_index]
		var rect: Array=part.region
		var region:=Rect2(float(rect[0]),float(rect[1]),float(rect[2]),float(rect[3]))
		var lookup: Dictionary={}
		var bone:=bone_indices[part_index]
		for polygon: Array in part.polygons:
			var contour:=PackedVector2Array()
			for point: Array in polygon: contour.append(Vector2(float(point[0]),float(point[1])))
			var triangles:=Geometry2D.triangulate_polygon(contour)
			assert(not triangles.is_empty(),"Invalid painted motion part: "+String(part.name))
			for n in range(0,triangles.size(),3):
				var triangle:=PackedVector2Array([contour[triangles[n]],contour[triangles[n+1]],contour[triangles[n+2]]])
				var pieces: Array=[triangle]
				# Only deformable cloth/torso/ankles need interior sampling.
				if part_index in [0,2,9,11]:
					pieces=[]
					for row in range(8):
						var strip:=_clip(_clip(triangle,region.position.y+region.size.y*float(row)/8.0,true),region.position.y+region.size.y*float(row+1)/8.0,false)
						if strip.size()>=3: pieces.append(strip)
				for piece: PackedVector2Array in pieces:
					var fan:=PackedInt32Array()
					for point in piece:
						var quantized:=Vector2(round(point.x*1024.0),round(point.y*1024.0))/1024.0
						if not lookup.has(quantized):
							lookup[quantized]=vertices.size()
							var uv: Vector2=(quantized-region.position)/region.size
							var vertex:=_map(rig,part_index,part,uv,region,figure_height)
							vertices.append(vertex); uvs.append(quantized/texture_size)
							colors.append(Color(clampf(vertex.x/figure_height+.5,0,1),clampf(1.0-vertex.y/figure_height,0,1),0,1))
							var influence:=_weights(rig,part_index,uv,vertex,bone,figure_height)
							for j in range(4):
								var joint:=int(influence[j*2]); var weight:=float(influence[j*2+1])
								bones.append(joint); weights.append(weight)
								if weight>0.0:
									if not valid[joint]: boxes[joint]=AABB(vertex,Vector3.ZERO); valid[joint]=true
									else: boxes[joint]=boxes[joint].expand(vertex)
						fan.append(lookup[quantized])
					for j in range(1,fan.size()-1):
						if fan[0]!=fan[j] and fan[j]!=fan[j+1] and fan[0]!=fan[j+1]: indices.append_array(PackedInt32Array([fan[0],fan[j],fan[j+1]]))
	var arrays:=[]; arrays.resize(Mesh.ARRAY_MAX)
	if rig.key=="Ranger":
		# Two GPU-skinned string segments share the painting's surface. Only
		# their middle bone moves while drawing; no per-frame mesh allocation.
		for segment in [[20,21],[21,22]]:
			var a: Vector3=rig.rest[segment[0]]; var b: Vector3=rig.rest[segment[1]]
			var first:=vertices.size()
			for point in [a,a,b,b]:
				var side: float=-1.0 if vertices.size()%2==0 else 1.0
				var vertex: Vector3=point+Vector3.RIGHT*side*figure_height*.0011
				var joint: int=segment[0] if vertices.size()-first<2 else segment[1]
				vertices.append(vertex); uvs.append(Vector2.ZERO); colors.append(Color(.9,.3,1,1))
				bones.append_array(PackedInt32Array([joint,0,0,0])); weights.append_array(PackedFloat32Array([1,0,0,0]))
				if not valid[joint]: boxes[joint]=AABB(vertex,Vector3.ZERO); valid[joint]=true
				else: boxes[joint]=boxes[joint].expand(vertex)
			indices.append_array(PackedInt32Array([first,first+1,first+2,first+1,first+3,first+2]))
	arrays[Mesh.ARRAY_VERTEX]=vertices; arrays[Mesh.ARRAY_TEX_UV]=uvs; arrays[Mesh.ARRAY_COLOR]=colors
	arrays[Mesh.ARRAY_BONES]=bones; arrays[Mesh.ARRAY_WEIGHTS]=weights; arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new(); mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return {"mesh":mesh,"boxes":boxes,"valid":valid}

static func _map(rig: RefCounted,index: int,part: Dictionary,uv: Vector2,region: Rect2,h: float) -> Vector3:
	var rest: Array=rig.rest
	if index==0:
		var fitted_neck: bool=rig.key in ["raider","bulwark","hexer","elite","guardian_2"]
		var top: Vector3=rest[2]-Vector3.UP*h*(.02 if fitted_neck else .10)
		var bottom: Vector3=rest[0]-Vector3.UP*h*.045
		var t: float=(uv.y-.035)/.88
		return Vector3(lerpf(rest[2].x if fitted_neck else rest[1].x,rest[0].x,uv.y)+(uv.x-.5)*h*.29,lerpf(top.y,bottom.y,t),0)
	if index==1:
		var anchor:=Vector2(float(part.get("anchor",[region.get_center().x,region.position.y+region.size.y*.55])[0]),float(part.get("anchor",[region.get_center().x,region.position.y+region.size.y*.55])[1]))
		var pixels:=region.position+uv*region.size-anchor
		var head_height: float=h*(.29 if String(rig.key) in ["Vowkeeper","Arcanist","Ranger"] else .54 if rig.key=="guardian_0" else .35)
		return rest[2]+Vector3(pixels.x,-pixels.y,0)*head_height/region.size.y
	if index==2:
		var anchor:=Vector2(float(part.anchor[0]),float(part.anchor[1]))
		var pixels:=region.position+uv*region.size-anchor
		var cape: Vector3=rest[16]+Vector3(pixels.x*.8,-pixels.y,0)*h*.64/region.size.y
		cape.y=maxf(.014,cape.y)
		return cape
	if index==3:
		return map_weapon(rig,uv,region)
	var first: int={4:3,5:4,6:7,7:8,8:10,9:11,10:13,11:14}[index]
	if index==7 and rig.key=="Vowkeeper":
		var offset: Vector2=(uv-Vector2(.53,.60))*region.size
		return rest[9]+Vector3(offset.x,-offset.y,0)*h*.31/region.size.y
	var a: Vector3=rest[first]; var b: Vector3=rest[first+1]
	if part.has("joints"):
		var joints: Array=part.joints
		var source_a:=Vector2(float(joints[0][0]),float(joints[0][1]))
		var source_b:=Vector2(float(joints[1][0]),float(joints[1][1]))
		var offset:=region.position+uv*region.size-source_a
		var source_axis:=Vector2(source_b.x-source_a.x,source_a.y-source_b.y)
		var target_axis:=b-a
		var angle:=atan2(target_axis.y,target_axis.x)-source_axis.angle()
		return a+Basis(Vector3.BACK,angle)*Vector3(offset.x,-offset.y,0)*a.distance_to(b)/source_axis.length()
	var upper:=Vector2(.5,.075); var lower:=Vector2(.5,.86 if index in [4,6,8,10] else .80)
	if index in [9,11]:
		lower.y=1.0; b.y=0.0
		# Boots extend toward the source-facing side; mapping the sole, rather
		# than its rectangle center, places a complete sole on the actual floor.
	var relative: Vector2=(uv-upper)*region.size
	var pixel_length: float=((lower-upper)*region.size).length()
	var axis: Vector3=(b-a).normalized()
	var rotation: float=atan2(axis.y,axis.x)+PI*.5
	var units:=a.distance_to(b)/pixel_length
	var mapped:=a+Basis(Vector3.BACK,rotation)*Vector3(relative.x,-relative.y,0)*units
	if index in [9,11]:
		var boot:=Vector3(rig.rest[first+1].x+relative.x*units,(1.0-uv.y)*region.size.y*units,0)
		mapped=mapped.lerp(boot,smoothstep(.65,.82,uv.y))
	return mapped

static func map_weapon(rig: RefCounted,uv: Vector2,region: Rect2) -> Vector3:
	var anchors:=weapon_anchors(String(rig.key))
	var grip: Vector2=anchors[0]; var tip: Vector2=anchors[1]
	var length: float=rig.rest[6].distance_to(rig.rest_weapon_tip)
	var pixels: Vector2=(uv-grip)*region.size
	var axis: Vector3=(rig.rest_weapon_tip-rig.rest[6]).normalized()
	var source_vector: Vector2=(tip-grip)*region.size
	var source_angle: float=atan2(-source_vector.y,source_vector.x)
	var rotation: float=atan2(axis.y,axis.x)-source_angle
	var units: float=length/source_vector.length()
	return rig.rest[6]+Basis(Vector3.BACK,rotation)*Vector3(pixels.x,-pixels.y,0)*units

static func weapon_anchors(key: String) -> Array:
	match key:
		"Vowkeeper": return [Vector2(.5,.87),Vector2(.5,.02)]
		"Arcanist": return [Vector2(.30,.87),Vector2(.55,.12)]
		"Ranger": return [Vector2(.78,.50),Vector2(.15,.07)]
		"guardian_0": return [Vector2(.85,.88),Vector2(.34,.25)]
		"guardian_1": return [Vector2(.75,.77),Vector2(.49,.22)]
		"guardian_2": return [Vector2(.25,.70),Vector2(.74,.18)]
		_: return [Vector2(.5,.87),Vector2(.5,.05)]

static func _weights(rig: RefCounted,index: int,uv: Vector2,vertex: Vector3,bone: int,h: float) -> Array:
	if index==0:
		var t:=clampf((vertex.y-rig.rest[0].y)/maxf(rig.rest[1].y-rig.rest[0].y,.01),0,1)
		return [0,1.0-t,1,t,0,0.0,0,0.0]
	if index==2:
		var t:=clampf(uv.y,0,1)
		if t<.5: return [16,1.0-t*2,17,t*2,0,0.0,0,0.0]
		return [17,2.0-t*2,18,t*2-1.0,0,0.0,0,0.0]
	if index==1 and rig.key in ["Vowkeeper","Arcanist","Ranger"]:
		var hair:=1.0-smoothstep(.25,.52,uv.x)
		return [2,1.0-hair,19,hair,0,0.0,0,0.0]
	if index in [9,11]:
		var t:=smoothstep(.68,.84,uv.y)
		return [bone,1.0-t,bone+1,t,0,0.0,0,0.0]
	return [bone,1.0,0,0.0,0,0.0,0,0.0]

static func _clip(polygon: PackedVector2Array,y: float,greater: bool) -> PackedVector2Array:
	var output:=PackedVector2Array()
	if polygon.is_empty(): return output
	var previous:=polygon[polygon.size()-1]
	var previous_inside:=previous.y>=y-.00001 if greater else previous.y<=y+.00001
	for current in polygon:
		var inside:=current.y>=y-.00001 if greater else current.y<=y+.00001
		if inside!=previous_inside:
			var denominator:=current.y-previous.y
			if absf(denominator)>.000001: output.append(previous.lerp(current,clampf((y-previous.y)/denominator,0,1)))
		if inside: output.append(current)
		previous=current; previous_inside=inside
	return output
