extends SceneTree
## Original native images of live production actor phases. These diagnostic
## frames supplement ordinary per-class encounter captures; no overlays.
const Actor = preload("res://scripts/dungeon_actor.gd")
const Lighting = preload("res://scripts/dungeon_lighting.gd")
var output_dir := "/tmp/emberfall-motion057"
var records: Array[Dictionary] = []
var actor: Node3D

func _initialize() -> void: run.call_deferred()

func capture(label: String) -> void:
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw
	var file: String = String(actor.kind).to_lower() + "-" + label + ".png"
	assert(root.get_texture().get_image().save_png(output_dir.path_join(file)) == OK)
	var bones := {}
	for name in ["pelvis", "spine_03", "hand_l", "hand_r", "foot_l", "foot_r"]:
		var point: Vector3 = actor.motion_rig.motion_node.global_transform * actor.motion_rig.skeleton.get_bone_global_pose(actor.motion_rig.skeleton.find_bone(name)).origin
		bones[name] = [point.x, point.y, point.z]
	records.append({"class": actor.kind, "image": file, "actual_actor_clip": actor.last_clip, "attack_time_s": actor.attack_time, "release_time_s": actor.release_time, "actual_evade_phase": actor.evade_phase, "native_motion_transition_amount": actor.motion_rig.motion_transition.amount, "native_bones_world_m": bones})
	print("NATIVE_MOTION_057_CAPTURE ", file)

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): output_dir = argument.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size = Vector2i(1000, 1000)
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("1c242b")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("a8b4c0")
	environment.ambient_light_energy = .34
	environment.sky = Lighting.reflection_sky()
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	var world := WorldEnvironment.new()
	world.environment = environment
	stage.add_child(world)
	for parameters in [[Vector3(-3, 4, -4), 1.2, Color("ffe9d2")], [Vector3(3, 2, -2), .5, Color("b4d0ed")], [Vector3(1, 3, 3), .8, Color("f4d6a5")]]:
		var light := OmniLight3D.new()
		light.position = parameters[0]
		light.light_energy = parameters[1]
		light.light_color = parameters[2]
		light.light_cull_mask = 3
		light.omni_range = 12
		light.shadow_enabled = true
		stage.add_child(light)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 20)
	floor_mesh.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("343d47")
	material.roughness = .95
	floor_mesh.material_override = material
	stage.add_child(floor_mesh)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.position = Vector3(2.3, 1.7, -4)
	camera.size = 3.7
	stage.add_child(camera)
	camera.current = true
	camera.look_at(Vector3(.15, 1.5, .20))
	for class_key in ["Arcanist", "Ranger", "Vowkeeper"]:
		actor = Actor.new()
		actor.kind = class_key
		stage.add_child(actor)
		actor.animate(.20, false)
		actor.strike("signature", .36, true)
		var visual_duration: float = .36 - Actor.PROJECTILE_RELEASE_LEAD if class_key != "Vowkeeper" else .36
		actor.sync_attack(.36 - visual_duration * .34)
		actor.animate(.08, false)
		await capture("signature-load")
		actor.sync_attack(Actor.PROJECTILE_RELEASE_LEAD if class_key != "Vowkeeper" else 0.0)
		actor.animate(0.0, false)
		await capture("signature-release")
		assert(actor.release_attack())
		actor.animate(.065, false)
		await capture("signature-follow")
		actor.animate(.40, false)
		actor.strike("signature", .36, true)
		actor.sync_attack(.36 - visual_duration * .93)
		actor.animate(.08, false)
		await capture("cancel-departure")
		var origin: Vector3 = actor.global_position
		var goal := origin + Vector3(.55, 0, .55)
		actor.begin_evade(origin, goal)
		actor.animate(0.0, false)
		await capture("cancel-entry")
		for frame in range(1, 7):
			actor.global_position = origin.lerp(goal, float(frame) / 10.0)
			actor.animate(1.0 / 60.0, false)
		await capture("evade-low-step")
		actor.free()
	var receipt := FileAccess.open(output_dir.path_join("native-motion-poses.json"), FileAccess.WRITE)
	receipt.store_string(JSON.stringify({"scope": "18 original1000x1000 fixed-camera native production actor diagnostic phase images; ordinary full-class fights are separate", "screenshots": records}, "\t") + "\n")
	print("NATIVE MOTION TRANSITION PREVIEW: 18 original native diagnostic images")
	quit(0)
