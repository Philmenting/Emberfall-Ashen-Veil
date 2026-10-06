extends SceneTree
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
	print("EXPORTED AVATAR SMOKE: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)

func run() -> void:
	var folder := "res://assets/models/nyra052/"
	for filename in ["death-grounding.json", "staff-grip053.json", "BASE-LICENSE.txt", "OUTFIT-LICENSE.txt", "ANIMATION-LICENSE.txt"]:
		check(FileAccess.file_exists(folder + filename), "Missing exported runtime/source file: " + filename)
	if failures:
		finish()
		return
	var grip = JSON.parse_string(FileAccess.get_file_as_string(folder + "staff-grip053.json"))
	var grounding = JSON.parse_string(FileAccess.get_file_as_string(folder + "death-grounding.json"))
	check(typeof(grip) == TYPE_DICTIONARY and typeof(grounding) == TYPE_DICTIONARY, "Exported grip and grounding data parse")
	if failures:
		finish()
		return
	check(grip.get("model_sha256") == grounding.get("model_sha256"), "Exported data refer to the same authored body")
	var parent := Node3D.new()
	root.add_child(parent)
	var rig = load("res://scripts/source_avatar_rig.gd").new()
	rig.build(parent, "Arcanist")
	rig.pose("idle", .4)
	check(rig.build_ok and rig.skeleton.get_bone_count() == 65 and rig.surfaces.size() == 8, "Native avatar loads from the exported package")
	check(rig.grip_pose.size() == 20 and rig.death_grounding.size() == 31, "Production rig uses the exported finger and grounding data")
	check(rig.weapon_grip_position().is_finite(), "Real exported staff grip is finite")
	rig.dispose()
	parent.free()
	finish()
