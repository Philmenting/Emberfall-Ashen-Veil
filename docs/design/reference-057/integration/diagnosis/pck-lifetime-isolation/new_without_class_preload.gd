extends SceneTree
const RaiderRig=preload("res://scripts/raider_avatar_rig.gd")
const NativeHostileRig=preload("res://scripts/native_hostile_rig.gd")
const NativeClothing=preload("res://assets/models/hostiles057/male-clothing-native65.glb")
const SkinAudit=preload("/workspace/Emberfall-Ashen-Veil/tests/source_avatar_skin.gd")
const NATIVE_SURFACE_COUNTS={"hexer":11,"bulwark":14,"elite":13,"guardian_0":13,"guardian_1":12,"guardian_2":12,"guardian_3":13}
const NATIVE_ROLE_CLIPS={"hexer":"Spell_Simple_Shoot","bulwark":"Sword_Regular_A","elite":"Sword_Regular_B","guardian_0":"Sword_Regular_C","guardian_1":"Spell_Simple_Shoot","guardian_2":"Spell_Simple_Enter","guardian_3":"Sword_Regular_C"}
## Run outside the checkout with --main-pack and this script's absolute path.
## This exercises exported resources, including FileAccess JSON dependencies.
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func finish() -> void:
	# run() has returned and released every rig owner before this callback.
	# Give packaged native resources their ordinary end-of-frame cleanup.
	await process_frame
	await process_frame
	print("EXPORTED AVATAR SMOKE: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)

func run() -> void:
	var folder := "res://assets/models/nyra052/"
	for filename in ["death-grounding.json", "staff-grip053.json", "BASE-LICENSE.txt", "OUTFIT-LICENSE.txt", "ANIMATION-LICENSE.txt"]:
		check(FileAccess.file_exists(folder + filename), "Missing exported runtime/source file: " + filename)
	check(FileAccess.file_exists("res://assets/models/nyra054/QUATERNIUS-CC0-LICENSE.txt"), "Added native attire source license ships in the package")
	for filename in ["OUTFIT-LICENSE.txt","ANIMATION2-LICENSE.txt"]:
		check(FileAccess.file_exists("res://assets/models/classes055/"+filename),"Native class source license ships: "+filename)
	for filename in ["raider-native65.json","axe-grip.json","death-grounding.json","axe-fitted.json","BASE-LICENSE.txt","OUTFIT-LICENSE.txt","ANIMATION1-LICENSE.txt","ANIMATION2-LICENSE.txt","WEAPON-LICENSE.txt"]:
		check(FileAccess.file_exists("res://assets/models/raider056/"+filename),"Native Raider runtime/source file ships: "+filename)
	for filename in ["manifest.json","death-grounding.json","BASE-LICENSE.txt","OUTFIT-LICENSE.txt","ANIMATION1-LICENSE.txt","ANIMATION2-LICENSE.txt"]:
		check(FileAccess.file_exists("res://assets/models/hostiles057/"+filename),"Complete native role runtime/source file ships: "+filename)
	if failures:
		call_deferred("finish")
		return
	var grip = JSON.parse_string(FileAccess.get_file_as_string(folder + "staff-grip053.json"))
	var grounding = JSON.parse_string(FileAccess.get_file_as_string(folder + "death-grounding.json"))
	check(typeof(grip) == TYPE_DICTIONARY and typeof(grounding) == TYPE_DICTIONARY, "Exported grip and grounding data parse")
	if failures:
		call_deferred("finish")
		return
	check(grip.get("model_sha256") == grounding.get("model_sha256"), "Exported data refer to the same authored body")
	var parent := Node3D.new()
	root.add_child(parent)
	var rig = load("res://scripts/source_avatar_rig.gd").new()
	rig.build(parent, "Arcanist")
	rig.pose("idle", .4)
	check(rig.build_ok and rig.skeleton.get_bone_count() == 65 and rig.surfaces.size() == 8, "Native avatar loads from the exported package")
	check(rig.style!=null and rig.style.accessories.size()==11 and rig.rendered_triangles<40000, "Native cloth and armor load from the exported package within the full rendered triangle budget")
	check(rig.grip_pose.size() == 20 and rig.death_grounding.size() == 31, "Production rig uses the exported finger and grounding data")
	check(rig.weapon_grip_position().is_finite(), "Real exported staff grip is finite")
	rig.dispose()
	parent.free()
	# dispose() frees native nodes; release the RefCounted owner as well.
	# Its script/player/style references must leave this synchronous frame
	# before packaged script caches and autoloads are torn down.
	rig=null
	parent=null
	var raider_parent:=Node3D.new()
	root.add_child(raider_parent)
	var raider:=RaiderRig.new()
	raider.build(raider_parent,"raider")
	raider.pose("windup_jab",.7)
	check(raider.build_ok and raider.skeleton.get_bone_count()==65 and raider.surfaces.size()>=8,"Complete native Raider loads from exported GLB and JSON data")
	check(raider.rendered_triangles<=20000 and raider.weapon_grip_position().is_finite(),"Exported original Raider and held axe retain full visible budget and real grip")
	check(raider.player.has_animation("Walk_Loop") and raider.player.has_animation("Hit_Chest"),"Exported native Raider retains artist movement and damage clips")
	raider.dispose();raider_parent.free()
	raider=null;raider_parent=null
	var role_manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/hostiles057/manifest.json"))
	var outfit: Node3D=NativeClothing.instantiate()
	var outfit_triangles:=0
	for part: MeshInstance3D in outfit.find_children("*","MeshInstance3D",true,false):
		for slot in part.mesh.get_surface_count():outfit_triangles+=part.mesh.surface_get_arrays(slot)[Mesh.ARRAY_INDEX].size()/3
	outfit.free()
	check(typeof(role_manifest)==TYPE_DICTIONARY and int(role_manifest.native_bones)==65 and int(role_manifest.cloth_triangles)==13460 and outfit_triangles==int(role_manifest.cloth_triangles) and role_manifest.weapons.size()==7,"Exported native role manifest matches the actual cuff-fitted shared garment triangle inventory and all seven fitted props")
	for role_key in NATIVE_SURFACE_COUNTS:
		var role_parent:=Node3D.new();root.add_child(role_parent)
		var native:=NativeHostileRig.new();native.build(role_parent,role_key)
		native.pose("windup_heavy",.7)
		check(native.build_ok and native.skeleton.get_bone_count()==65 and native.surfaces.size()==NATIVE_SURFACE_COUNTS[role_key],role_key+": complete native body and exact visible role armor inventory load from the exported resource package")
		var actual_triangles:=0
		for part: MeshInstance3D in native.motion_node.find_children("*","MeshInstance3D",true,false):
			if not part.is_visible_in_tree(): continue
			for slot in part.mesh.get_surface_count():actual_triangles+=part.mesh.surface_get_arrays(slot)[Mesh.ARRAY_INDEX].size()/3
		check(actual_triangles==native.rendered_triangles and actual_triangles<=40000 and native.weapon_grip_position().is_finite() and SkinAudit.actual_figure_bounds(native).size.z>.30,role_key+": every actual weighted body/armor and indexed held prop retains the packaged full render budget and real volume")
		check(native.player.current_animation==NATIVE_ROLE_CLIPS[role_key] and native.player.has_animation("Walk_Loop") and native.player.has_animation("Hit_Chest") and native.player.has_animation("Death01"),role_key+": actual native role action, movement, hit and death clips survive packaging")
		native.dispose();role_parent.free();native=null;role_parent=null
	call_deferred("finish")
