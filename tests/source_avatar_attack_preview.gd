extends SceneTree
## Six original native stills of the production Arcanist load/catch poses.
## Diagnostic direct posing; no simulation playback or visual acceptance claim.
const Actor = preload("res://scripts/dungeon_actor.gd")
const Combat = preload("res://scripts/source_avatar_combat.gd")
const SkinAudit = preload("res://tests/source_avatar_skin.gd")
const Lighting = preload("res://scripts/dungeon_lighting.gd")
var capture_dir := "/tmp/emberfall-attack-studio056"
var actor: Node3D
var camera: Camera3D
var checks := 0
var failures: Array[String] = []
var records: Array[Dictionary] = []

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func vector_record(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

func bounds_record(value: AABB) -> Dictionary:
	return {"position": vector_record(value.position), "size": vector_record(value.size)}

func prop_bounds(rig: RefCounted) -> Dictionary:
	var result := AABB()
	var first := true
	var count := 0
	var finite := true
	for part: MeshInstance3D in rig.weapon.get_children():
		for slot in part.mesh.get_surface_count():
			var arrays: Array = part.mesh.surface_get_arrays(slot)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var used := {}
			for index in arrays[Mesh.ARRAY_INDEX]:
				used[index] = true
			for index in used:
				var point: Vector3 = actor.body.global_transform * rig.motion_node.transform * rig.weapon.transform * part.transform * vertices[index]
				finite = finite and point.is_finite()
				result = AABB(point, Vector3.ZERO) if first else result.expand(point)
				first = false
				count += 1
	return {"bounds": result, "indexed_vertices": count, "finite": finite}

func native_anatomy(rig: RefCounted) -> bool:
	for bone in rig.skeleton.get_bone_count():
		if not rig.skeleton.get_bone_global_rest(bone).is_equal_approx(rig.rest[bone]):
			return false
		if rig.skeleton.get_bone_pose_scale(bone).distance_to(Vector3.ONE) > .00001:
			return false
		var parent: int = rig.skeleton.get_bone_parent(bone)
		if parent >= 0 and String(rig.skeleton.get_bone_name(bone)) not in ["root", "pelvis"]:
			var actual: float = rig.skeleton.get_bone_global_pose(bone).origin.distance_to(rig.skeleton.get_bone_global_pose(parent).origin)
			var original: float = rig.rest[bone].origin.distance_to(rig.rest[parent].origin)
			if absf(actual - original) > .00001:
				return false
	return true

func inside_frame(bounds: AABB) -> bool:
	var image_rect := Rect2(Vector2.ZERO, Vector2(root.size))
	for corner in 8:
		var point := bounds.position + bounds.size * Vector3(float(corner & 1), float((corner >> 1) & 1), float((corner >> 2) & 1))
		if camera.is_position_behind(point) or not image_rect.has_point(camera.unproject_position(point)):
			return false
	return true

func capture(action: String, section: String, phase: float) -> void:
	var clip := ("windup_" if section == "load" else "recover_") + action
	var time := phase if section == "load" else phase * Combat.RECOVERY
	var rig: RefCounted = actor.motion_rig
	rig.pose(clip, time)
	rig.apply_actor_postprocess(actor, clip, time, 0.0, true)
	var additional: Array = rig.style.accessories
	# Every indexed vertex of all original skin surfaces and separate attire,
	# reconstructed with the actual four bone * inverse-bind skin weights.
	var skin: AABB = actor.body.global_transform * SkinAudit.actual_bounds(rig, additional)
	var prop := prop_bounds(rig)
	var staff: AABB = prop.bounds
	var complete := skin.merge(staff)
	check(native_anatomy(rig), action + section + ": all native rest, scales and original segment lengths preserved")
	check(skin.position.y >= .0029, action + section + ": complete weighted body and garment stay above the real floor")
	check(staff.position.y >= .0029, action + section + ": all indexed actual staff geometry stays above the real floor")
	check(bool(prop.finite), action + section + ": all actual indexed prop vertices remain finite")
	check(int(prop.indexed_vertices) > 100, action + section + ": held prop uses its actual indexed vertices")
	check(inside_frame(complete), action + section + ": whole weighted outfit and complete staff fit the fixed camera")
	var bones := {}
	for name in ["pelvis", "spine_03", "Head", "thigh_l", "calf_l", "foot_l", "thigh_r", "calf_r", "foot_r", "hand_l", "hand_r"]:
		var bone: int = rig.skeleton.find_bone(name)
		bones[name] = vector_record(actor.body.global_transform * rig.motion_node.transform * rig.skeleton.get_bone_global_pose(bone).origin)
	for frame in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var filename := action + "-" + section + ".png"
	var image: Image = root.get_texture().get_image()
	check(image.get_size() == Vector2i(1200, 1200), "Original native screenshot retains exact viewport dimensions")
	check(image.save_png(capture_dir + "/" + filename) == OK, "Original native screenshot was written without pixel edits")
	records.append({
		"file": filename, "sha256": FileAccess.get_sha256(capture_dir + "/" + filename),
		"clip": clip, "phase": phase, "time": time, "original_native_png": true,
		"body_and_garment_world_bounds": bounds_record(skin),
		"staff_world_bounds": bounds_record(staff), "prop_indexed_vertices": prop.indexed_vertices,
		"main_surfaces": rig.surfaces.size(), "separate_attire_surfaces": additional.size(),
		"native_bone_positions_world": bones,
	})
	print("ATTACK_NATIVE_CAPTURE ", filename, ": skin/garment floor ", skin.position.y, "; actual prop floor ", staff.position.y)

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			capture_dir = argument.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(capture_dir)
	root.size = Vector2i(1200, 1200)
	root.content_scale_size = Vector2i(1200, 1200)
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("242932")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("a8b0bc")
	environment.ambient_light_energy = .35
	environment.sky = Lighting.reflection_sky()
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	var world := WorldEnvironment.new()
	world.environment = environment
	stage.add_child(world)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 20)
	floor.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("343d47")
	material.roughness = .95
	floor.material_override = material
	stage.add_child(floor)
	for params in [[Vector3(-3,4,-4),1.15,Color("ffe9d2")], [Vector3(3,2,-2),.5,Color("b4d0ed")], [Vector3(1,3,3),.8,Color("f4d6a5")]]:
		var light := OmniLight3D.new()
		light.position = params[0]
		light.light_energy = params[1]
		light.light_color = params[2]
		light.omni_range = 12
		light.shadow_enabled = true
		stage.add_child(light)
	actor = Actor.new()
	actor.kind = "Arcanist"
	stage.add_child(actor)
	check(actor.source_avatar and actor.motion_rig.skeleton.get_bone_count() == 65, "Studio uses the production native65 Arcanist with its original outfit and prop")
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	stage.add_child(camera)
	camera.current = true
	camera.position = Vector3(2.8, 1.4, -4)
	camera.size = 3.6
	camera.look_at(Vector3(0, 1.45, 0))
	for spec in [["basic", .33, .14], ["skill", .34, .16], ["heavy", .32, .18]]:
		await capture(spec[0], "load", spec[1])
		await capture(spec[0], "catch", spec[2])
	var receipt := {
		"scope": "Six diagnostic original native stills of directly posed production Actor skin, attire and staff. No World simulation, ordinary HUD, continuous motion, game FPS or visual acceptance claim.",
		"engine": Engine.get_version_info().string, "resolution": [1200,1200],
		"source_sha256": {
			"scripts/source_avatar_combat.gd": FileAccess.get_sha256("res://scripts/source_avatar_combat.gd"),
			"tests/source_avatar_attack_preview.gd": FileAccess.get_sha256("res://tests/source_avatar_attack_preview.gd"),
		},
		"camera_position": vector_record(camera.position), "camera_target": [0,1.45,0], "camera_size": camera.size,
		"checks": checks, "failures": failures, "images": records,
		"floor_audit_scope": "All indexed original main-skin and separate garment vertices, each with every original skin influence; all indexed live prop vertices. World units after actual production Actor.body scaling.",
		"motion_limits": "Still poses can show knee direction and body silhouette; continuous attack/cancel quality still requires the ordinary game capture. Hair remains native Head skin with no added secondary dynamics.",
	}
	var output := FileAccess.open(capture_dir + "/receipt.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(receipt, "  ") + "\n")
	output.close()
	stage.free()
	actor = null
	camera = null
	await process_frame
	print("SOURCE AVATAR ATTACK PREVIEW: ", checks, " checks, ", records.size(), " original native stills, ", failures.size(), " failures; diagnostic only")
	quit(0 if failures.is_empty() else 1)
