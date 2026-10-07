extends SceneTree
## Six unchanged native renderer images of the actual production actor API.
## The fixed studio camera exposes full anatomy, boot contact, robe hems and
## grips. These stills are diagnostic evidence, not continuous game playback.
const Actor = preload("res://scripts/dungeon_actor.gd")
const ClassRig = preload("res://scripts/class_avatar_rig.gd")
const SkinAudit = preload("res://tests/source_avatar_skin.gd")
var capture_dir := "/tmp/emberfall-evade-native"
var records: Array = []
var camera: Camera3D

func _initialize() -> void:
	call_deferred("run")

func save_frame(actor: Node3D, label: String) -> void:
	var rig = actor.motion_rig
	var native_bounds: AABB = SkinAudit.actual_bounds(rig, rig.style.accessories)
	assert(native_bounds.position.y >= .0015, "Actually rendered garment and boots must clear the studio floor")
	var minimum_weapon := INF
	for part: MeshInstance3D in rig.weapon.find_children("*", "MeshInstance3D", true, false):
		if not part.is_visible_in_tree() or part.mesh == null:
			continue
		var surfaces: Array = []
		if part.mesh is ArrayMesh:
			for slot in part.mesh.get_surface_count():
				surfaces.append(part.mesh.surface_get_arrays(slot))
		elif part.mesh is PrimitiveMesh:
			surfaces.append(part.mesh.get_mesh_arrays())
		for arrays in surfaces:
			for index in arrays[Mesh.ARRAY_INDEX]:
				var point: Vector3 = actor.body.to_local(part.to_global(arrays[Mesh.ARRAY_VERTEX][index]))
				minimum_weapon = minf(minimum_weapon, point.y)
				native_bounds = native_bounds.expand(point)
	assert(is_finite(minimum_weapon) and minimum_weapon >= .002, "Actual indexed held weapon clears the studio floor")
	for x in 2:
		for y in 2:
			for z in 2:
				var corner := native_bounds.position + native_bounds.size * Vector3(x, y, z)
				var screen := camera.unproject_position(actor.body.to_global(corner)) / Vector2(root.size)
				if not (screen.x > .02 and screen.x < .98 and screen.y > .02 and screen.y < .98):
					push_error("Complete indexed body/garment/weapon must fit the unchanged frame: " + label + " screen=" + str(screen))
					quit(1)
					return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	assert(screenshot.save_png(capture_dir + "/" + label + ".png") == OK)
	records.append({"file": label + ".png", "class": actor.kind, "actor_clip": actor.last_clip, "evade_phase": actor.evade_phase, "world_position": [actor.global_position.x, actor.global_position.y, actor.global_position.z], "minimum_all_weighted_source_and_accessory_y_m": native_bounds.position.y, "minimum_actual_indexed_weapon_source_y_m": minimum_weapon, "complete_actual_body_and_weapon_in_frame": true, "image_width": screenshot.get_width(), "image_height": screenshot.get_height()})

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			capture_dir = argument.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(capture_dir)
	root.size = Vector2i(960, 720)
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("242932")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("a8b0bc")
	environment.environment.ambient_light_energy = .35
	stage.add_child(environment)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 20)
	floor.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("343d47")
	material.roughness = .95
	floor.material_override = material
	stage.add_child(floor)
	for parameters in [[Vector3(-3, 4, -4), 1.15, Color("ffe9d2")], [Vector3(3, 2, -2), .5, Color("b4d0ed")], [Vector3(1, 3, 3), .8, Color("f4d6a5")]]:
		var light := OmniLight3D.new()
		light.position = parameters[0]
		light.light_energy = parameters[1]
		light.light_color = parameters[2]
		light.omni_range = 12
		light.shadow_enabled = true
		stage.add_child(light)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 4.2
	stage.add_child(camera)
	camera.current = true
	camera.position = Vector3(2.8, 2.1, -4.0)
	camera.look_at(Vector3(0.0, 1.50, 0.0))
	var camera_before := camera.transform
	for class_key in ["Arcanist", "Ranger", "Vowkeeper"]:
		var actor = Actor.new()
		actor.kind = class_key
		stage.add_child(actor)
		actor.motion_rig.pose("evade", 0.0)
		actor.motion_rig.apply_actor_postprocess(actor, "evade", 0.0, 0.0, true)
		await save_frame(actor, class_key.to_lower() + "-source-guard")
		var direction := Vector3(.8, 0.0, .6).normalized()
		actor.global_position = -direction * 1.2
		actor.begin_evade(actor.global_position, direction * 1.2)
		actor.global_position = Vector3.ZERO
		actor.sync_evade(true)
		actor.animate(.06, true, 6.8)
		assert(actor.last_clip == "evade" and actor.evade_phase > .30 and actor.evade_phase < .45)
		await save_frame(actor, class_key.to_lower() + "-actual-lowstep")
		assert(camera.transform == camera_before, "The diagnostic camera stays fixed for all six images")
		actor.free()
	var receipt := {"fixture": "source_avatar_evade_preview", "renderer": "actual Godot native frames", "scope": "three production native65 actor APIs, fixed studio camera, original body/skin/attire/materials/weapon; diagnostic stills, not continuous game playback", "records": records}
	if records.size() != 6:
		push_error("Native evade preview requires exactly six actual verified renderer frames")
		quit(1)
		return
	var file := FileAccess.open(capture_dir + "/native-receipt.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(receipt, "\t"))
	file.close()
	print("SOURCE EVADE PREVIEW: six actual native65 production actor frames, complete weighted garment floor and fixed diagnostic camera")
	stage.free()
	await process_frame
	await process_frame
	quit(0)
