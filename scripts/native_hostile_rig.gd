extends "res://scripts/raider_avatar_rig.gd"
## All remaining hostile roles use the same original native65 male anatomy.
## One compact shared cloth source replaces Peasant cloth; verified hands,
## original head, eyes and skin binds remain untouched and shared.
const Clothing=preload("res://assets/models/hostiles057/male-clothing-native65.glb")
const NativeStyle=preload("res://scripts/native_hostile_style.gd")
const RoleTiming=preload("res://scripts/hostile_style.gd")
const PROPS: Dictionary={
	"hexer":preload("res://assets/models/hostiles057/hexer-fitted.glb"),
	"bulwark":preload("res://assets/models/hostiles057/bulwark-fitted.glb"),
	"elite":preload("res://assets/models/hostiles057/elite-fitted.glb"),
	"guardian_0":preload("res://assets/models/hostiles057/guardian_0-fitted.glb"),
	"guardian_1":preload("res://assets/models/hostiles057/guardian_1-fitted.glb"),
	"guardian_2":preload("res://assets/models/hostiles057/guardian_2-fitted.glb"),
	"guardian_3":preload("res://assets/models/hostiles057/guardian_3-fitted.glb"),
}
static var bound_role_animations: Dictionary={}
var clothing_ready:=false
var role_style: RefCounted
var role_phase:=0
var role_emphasis:=1.0
var role_focus:=0.0
var phase_material_origins: Dictionary={}
var last_material_state:=Vector3(-1,-1,-1)

static func has_appearance(appearance: String) -> bool:return PROPS.has(appearance)
func triangle_budget() -> int:return 40000

func build(parent: Node3D,appearance: String) -> void:
	super.build(parent,appearance)
	motion_node.name="AuthoredNativeHostile_"+appearance
	var original=Clothing.instantiate() as Node3D
	var source_skeleton=original.find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
	var source_player=original.find_children("*","AnimationPlayer",true,false)[0] as AnimationPlayer
	for bone in skeleton.get_bone_count():
		assert(source_skeleton.get_bone_name(bone)==skeleton.get_bone_name(bone))
		assert(source_skeleton.get_bone_global_rest(bone).is_equal_approx(skeleton.get_bone_global_rest(bone)))
	var library=player.get_animation_library("")
	var animation_root=player.get_node(player.root_node)
	var target_skeleton_path=String(animation_root.get_path_to(skeleton))
	for action in source_player.get_animation_list():
		if action=="RESET" or library.has_animation(action):continue
		var cache_key=target_skeleton_path+"/"+String(action)
		var animation: Animation=bound_role_animations.get(cache_key)
		if animation==null:
			animation=source_player.get_animation(action).duplicate() as Animation
			for track in animation.get_track_count():
				var original_path=animation.track_get_path(track)
				assert(original_path.get_subname_count()>0 and String(original_path).contains("Skeleton3D"),"Native hostile source clip contains only actual skeleton tracks")
				animation.track_set_path(track,NodePath(target_skeleton_path+":"+String(original_path.get_concatenated_subnames())))
			bound_role_animations[cache_key]=animation
		library.add_animation(action,animation)
	if not library.has_animation("Spell_Simple_Idle_Loop") and library.has_animation("Spell_Simple_Idle"):
		library.add_animation("Spell_Simple_Idle_Loop",library.get_animation("Spell_Simple_Idle"))
	role_style=NativeStyle.new();role_style.apply_clothing(self,original)
	original.free()
	style=role_style
	# Original obsolete garment bounds must not influence new foot/bounds
	# audits. Index only the final visible original panels and fitted armor.
	triangles=0;floor_probes.clear();bone_bounds.clear();populated.clear()
	for bone in skeleton.get_bone_count():bone_bounds.append(AABB());populated.append(false)
	for surface in surfaces:
		for slot in surface.mesh.get_surface_count():_index_surface(surface,slot)
	role_style.apply_armor(self)
	for surface in role_style.accessories:surfaces.append(surface)
	rendered_triangles=triangles+role_style.triangle_count
	for part: MeshInstance3D in weapon.get_children():
		for slot in part.mesh.get_surface_count():rendered_triangles+=part.mesh.surface_get_arrays(slot)[Mesh.ARRAY_INDEX].size()/3
	assert(rendered_triangles<=triangle_budget())
	material_origins.clear();phase_material_origins.clear()
	for surface in surfaces+weapon.get_children():
		for slot in surface.mesh.get_surface_count():
			var material=surface.get_active_material(slot) as StandardMaterial3D
			if material==null:continue
			material_origins[material]={"albedo":material.albedo_color,"roughness":material.roughness}
			phase_material_origins[material]={"albedo":material.albedo_color,"emission":material.emission,"enabled":material.emission_enabled,"energy":material.emission_energy_multiplier}
	clothing_ready=true;last_sample="";last_time=-1.0
	var grounding=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/hostiles057/death-grounding.json"))
	raider_death_grounding=grounding.roles[key]
	_sample(_guard_action(),_guard_time());sword_idle_pose=_capture_source_pose()
	pose("idle",0.0);refresh_bounds()
	mesh=surfaces[0].mesh;skin=surfaces[0].skin
	# Every role remains the exact adult anatomy size of the manufacturer.
	# The existing actor uniformly sizes guardians; no per-bone scaling occurs.
	source_height=1.810080
	set_boss_phase(0)

func _build_axe() -> void:
	weapon=Node3D.new();weapon.name="HeldNativeRoleProp_"+key;motion_node.add_child(weapon)
	var source=PROPS[key].instantiate() as Node3D;var tip_height=-INF
	for original: MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
		if not String(original.name).begins_with("Weapon__"):continue
		var part=MeshInstance3D.new();part.name="Weapon__Grip_"+String(original.name).trim_prefix("Weapon__")
		part.mesh=original.mesh;part.transform=original.transform;part.layers=2;part.extra_cull_margin=3.0;weapon.add_child(part)
		for slot in part.mesh.get_surface_count():
			var material=original.get_active_material(slot) as StandardMaterial3D
			if material!=null:
				var copy=material.duplicate() as StandardMaterial3D;copy.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
				copy.emission_energy_multiplier=minf(copy.emission_energy_multiplier,.52)
				part.set_surface_override_material(slot,copy)
				material_origins[copy]={"albedo":copy.albedo_color,"roughness":copy.roughness}
			var arrays=part.mesh.surface_get_arrays(slot);rendered_triangles+=arrays[Mesh.ARRAY_INDEX].size()/3
			var referenced: Dictionary={}
			for index in arrays[Mesh.ARRAY_INDEX]:referenced[index]=true
			for index in referenced:
				var point: Vector3=part.transform*arrays[Mesh.ARRAY_VERTEX][index];weapon_points.append(point)
				if point.y>tip_height:tip_height=point.y;weapon_tip_point=point
	source.free()
	assert(weapon.get_child_count()>0 and weapon_points.size()>0)

func _guard_action() -> String:
	return "Spell_Simple_Idle_Loop" if key in ["hexer","guardian_1","guardian_2"] else "Sword_Idle"
func _guard_time() -> float:return .20 if key in ["hexer","guardian_1","guardian_2"] else 0.0
func _action() -> Dictionary:
	if key=="hexer":return {"name":"Spell_Simple_Shoot","release":.50}
	if key=="guardian_1":return {"name":"Spell_Simple_Shoot","release":.64}
	if key=="guardian_2":return {"name":"Spell_Simple_Enter","release":.93}
	if key=="elite":return {"name":"Sword_Regular_B","release":.58}
	if key in ["guardian_0","guardian_3"]:return {"name":"Sword_Regular_C","release":.58}
	return {"name":"Sword_Regular_A","release":.56}

func pose(clip: String,time: float) -> void:
	if not clothing_ready:super.pose(clip,time);return
	last_clip=clip;last_clip_time=time
	if clip=="death":_sample("Death01",clampf(time/.90,0,1)*player.get_animation("Death01").length)
	elif clip=="walk":_sample("Walk_Loop",fposmod(time,1.0)*player.get_animation("Walk_Loop").length)
	elif clip.begins_with("windup") or clip.begins_with("recover"):
		var recovering=clip.begins_with("recover")
		var action_name=clip.trim_prefix("recover_") if recovering else clip.trim_prefix("windup_")
		var phrase=_action();var length=player.get_animation(phrase.name).length
		var release=length*float(phrase.release)
		var duration=RoleTiming.recovery_seconds(key,action_name)
		var phase=clampf(time/duration if recovering else time,0,1)
		_sample(phrase.name,lerpf(release,length,phase) if recovering else release*phase)
		if recovering:
			var settle=smoothstep(.62,1.0,phase)
			for bone in skeleton.get_bone_count():
				skeleton.set_bone_pose_rotation(bone,skeleton.get_bone_pose_rotation(bone).slerp(sword_idle_pose.rotations[bone],settle))
				skeleton.set_bone_pose_position(bone,skeleton.get_bone_pose_position(bone).lerp(sword_idle_pose.positions[bone],settle))
	else:_sample(_guard_action(),fposmod(time+_guard_time(),player.get_animation(_guard_action()).length))
	_fit_fingers();_update_weapon()

func _append_weighted_probes(_surface: MeshInstance3D,_slot: int) -> void:
	# Armor indexing already records every actual native influence in bounds.
	# Hostile casts do not use the player-specific weighted cast-probe list.
	pass

func apply_actor_postprocess(actor: Variant,clip: String,time: float,delta: float,contact: bool) -> void:
	super.apply_actor_postprocess(actor,clip,time,delta,contact)
	if role_style!=null:
		role_style.update_death_attachment(self,clip,time)
		refresh_bounds()

func set_boss_phase(value: int) -> void:
	role_phase=clampi(value,0,2)
	_refresh_materials()
func set_visual_readability(value: float,focus: float) -> void:
	role_emphasis=clampf(value,0,1);role_focus=clampf(focus,0,1)
	_refresh_materials()
func _refresh_materials() -> void:
	var state=Vector3(float(role_phase),role_emphasis,role_focus)
	if state==last_material_state:return
	last_material_state=state
	# All materials are per-actor duplicates. A reset to phase0 and full
	# emphasis restores original role pigment and restrained prop emission.
	for material: StandardMaterial3D in phase_material_origins:
		var origin: Dictionary=phase_material_origins[material]
		var color: Color=origin.albedo
		var phase_mix=.07*float(role_phase) if key.begins_with("guardian_") else 0.0
		color=color.lerp(Color(.70,.40,.22,color.a),phase_mix)
		var gain=lerpf(.40,1.0,role_emphasis);color=Color(color.r*gain,color.g*gain,color.b*gain,color.a)
		material.albedo_color=color.lerp(Color(color.r*1.06,color.g*1.035,color.b,color.a),role_focus*.20)
		material.emission_enabled=bool(origin.enabled)
		material.emission=origin.emission
		material.emission_energy_multiplier=minf(.60,float(origin.energy)+float(role_phase)*.035) if origin.enabled else float(origin.energy)
