extends RefCounted
## Native PBR rarity accents on existing equipment surfaces. One helper belongs
## to one actor; peers/portraits share meshes and textures, never these overrides.
## A reset always starts from the original styled material, not the last rank.
const TINTS: Array[Color]=[Color("98794c"),Color("a5b393"),Color("93c4c6"),Color("b79ec6"),Color("e7bf79")]
var rig_ref: WeakRef
var records: Array[Dictionary]=[]

func apply(rig: RefCounted,grades: Dictionary) -> void:
	if rig==null: return
	if rig_ref==null or rig_ref.get_ref()!=rig: _bind(rig)
	for record in records:
		var material: StandardMaterial3D=record.material
		var color: Color=record.color
		var roughness: float=record.roughness
		var rank:=clampi(int(grades.get(record.slot,0)),0,4) if not String(record.slot).is_empty() else 0
		# Common/unrepresented parts retain their exact styled values. Texture
		# references, normal/ORM channels, emission, metallic and skin stay put.
		material.albedo_color=color
		material.roughness=roughness
		if rank==0: continue
		var metal:=material.metallic>.30
		var amount:=.028+rank*.021 if metal else .018+rank*.013
		# Multiplicative pigment preserves the lightness of soot cloth and the
		# warmth of old bronze; rank cannot turn a dark garment into pale paint.
		var tint:=TINTS[rank]
		var peak:=maxf(tint.r,maxf(tint.g,tint.b))
		var pigment:=Color(color.r*tint.r/peak,color.g*tint.g/peak,color.b*tint.b/peak,color.a)
		material.albedo_color=color.lerp(pigment,amount)
		material.roughness=maxf(minf(.34,roughness),roughness-(.008 if metal else .0035)*rank)

func _bind(rig: RefCounted) -> void:
	records.clear(); rig_ref=weakref(rig)
	for part: MeshInstance3D in rig.motion_node.find_children("*","MeshInstance3D",true,false):
		if not part.visible or part.mesh==null: continue
		for surface in part.mesh.get_surface_count():
			var original:=part.get_active_material(surface) as StandardMaterial3D
			if original==null: continue
			var own:=original.duplicate(false) as StandardMaterial3D
			# Surface overrides are the existing native render path. In particular
			# the Arcanist's imported staff previously retained shared materials.
			if part.material_override!=null:
				# The current native source uses this only for bowstrings. Preserve
				# the single-pass override rather than hiding it behind a surface.
				part.material_override=own
			else: part.set_surface_override_material(surface,own)
			var slot:=_equipment_slot(String(rig.key),String(part.name),String(original.resource_name))
			records.append({"material":own,"slot":slot,"color":original.albedo_color,"roughness":original.roughness})

static func _equipment_slot(key: String,name: String,material: String) -> String:
	var lower:=name.to_lower()
	# Actual body and facial materials are never a rarity channel. Ranger's
	# arm mesh has a second material for exposed hands; reject that surface.
	if material.contains("Regular_Female") or material.contains("Superhero_Female"): return ""
	if lower.contains("hair") or lower.contains("eyebrow") or lower.contains("eyes"): return ""
	if lower.contains("head") and not lower.contains("hood") and not lower.contains("circlet"): return ""
	if name.begins_with("Weapon__"): return "Weapon"
	if key=="Arcanist":
		if name=="Nyra054_Forehead_Circlet": return "Helmet"
		if name in ["Nyra054_Open_Coat_Bodice","Nyra054_Lapel_Leather_Facing","Nyra054_Left_Split_Tail","Nyra054_Right_Split_Tail"]: return "Chest"
		if name in ["Nyra054_Left_Shoulder_Bronze","Nyra054_Right_Shoulder_Bronze"]: return "Gloves"
		if name=="Nyra_Female_Peasant_Feet": return "Boots"
		if name in ["Nyra054_Circlet_Gem","Nyra054_Bodice_Bronze_Binding","Nyra054_Left_Tail_Binding","Nyra054_Right_Tail_Binding"]: return "Amulet"
	elif key=="Vowkeeper":
		# There is no native helmet on the unhooded Vowkeeper. Its rank is
		# echoed by existing shoulder protection; head and hair stay unchanged.
		if name.contains("Vowkeeper055_") and name.contains("Pauldrons"): return "Helmet"
		if name=="Vowkeeper055_Breastplate" or name=="Female_Ranger_Body": return "Chest"
		if name.contains("Vowkeeper055_") and name.contains("Bracer"): return "Gloves"
		if name=="Female_Ranger_Feet": return "Boots"
		if name.begins_with("Female_Ranger_Body_Belt"): return "Amulet"
	elif key=="Ranger":
		if name=="Female_Ranger_Head_Hood": return "Helmet"
		if name in ["Female_Ranger_Body","Female_Ranger_Acc_Pauldrons"]: return "Chest"
		if name=="Female_Ranger_Arms_Bracer": return "Gloves"
		if name=="Female_Ranger_Feet": return "Boots"
		if name.begins_with("Female_Ranger_Body_Belt"): return "Amulet"
	return ""
