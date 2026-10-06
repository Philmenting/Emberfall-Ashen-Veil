extends SceneTree
const ClassRig=preload("res://scripts/class_avatar_rig.gd")
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
	for class_key in ["Vowkeeper","Ranger"]:
		var class_parent := Node3D.new()
		root.add_child(class_parent)
		var class_rig = ClassRig.new()
		class_rig.build(class_parent,class_key)
		class_rig.pose("windup_basic",.7)
		check(class_rig.build_ok and class_rig.skeleton.get_bone_count()==65 and class_rig.surfaces.size()>=8,class_key+": complete native class scene loads from the exported package")
		check(class_rig.rendered_triangles<40000 and class_rig.weapon_grip_position().is_finite(),class_key+": real exported weapon and full figure stay within budget")
		check(class_rig.player.has_animation("Walk_Loop") and class_rig.player.has_animation("Death01"),class_key+": native movement and death clips survive packaging")
		class_rig.dispose()
		class_parent.free()
		class_rig=null
		class_parent=null
	call_deferred("finish")
