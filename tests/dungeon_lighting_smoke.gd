extends SceneTree
## Inspect the effective light/mesh masks in real worlds. This is not a phone
## performance benchmark or a pixel-quality assertion.
const Sim=preload("res://scripts/expedition_simulation.gd")
const World=preload("res://scripts/dungeon_world.gd")
const Bot=preload("res://tests/balance_survey_bot.gd")
var checks:=0
var failures:=0

func _initialize() -> void: run_checks.call_deferred()

func check(value: bool,label: String) -> void:
	checks+=1
	if value: print("PASS: ",label)
	else: failures+=1; push_error("FAIL: "+label)

func run_checks() -> void:
	root.size=Vector2i(960,540)
	await process_frame
	var game:=Bot.new()
	for class_key in ["Vowkeeper","Arcanist","Ranger"]:
		game.character_class=class_key
		for region in range(4):
			var sim:=Sim.new(); sim.setup(class_key,game._combat_stats(),region*10+1,"Guardian",1979)
			var before: String=sim.encode_snapshot()
			var world: Node3D=World.new()
			world.simulation=sim; world.region_index=region; world.character_class=class_key; world.active=false
			root.add_child(world)
			var key:=world.get_node_or_null("RoomKeyLight") as DirectionalLight3D
			var rim:=world.get_node_or_null("CharacterRimLight") as DirectionalLight3D
			var fill:=world.get_node_or_null("CharacterKeyLight") as DirectionalLight3D
			var local:=world.hero.get_node_or_null("CharacterLocalFill") as OmniLight3D
			check(key!=null and rim!=null and fill!=null and local!=null,"%s region %d: real world contains its existing room key, actor rim, actor key and local fill" % [class_key,region])
			if key==null or rim==null or fill==null or local==null:
				world.free(); continue
			var actor_only:=true; var floor_lit:=true; var body_lit:=true; var visible_meshes:=0
			for light: Light3D in [rim,fill,local]:
				actor_only=actor_only and (light.light_cull_mask&1)==0
			var actors: Array=[world.hero]
			actors.append_array(world.enemies)
			for actor: Node3D in actors:
				# Opaque source surfaces, clothing and the held prop live under
				# CharacterBody. Ward/guard effects live outside this body root.
				for mesh: MeshInstance3D in actor.body.find_children("*","MeshInstance3D",true,false):
					if mesh.mesh==null or not mesh.is_visible_in_tree(): continue
					if mesh.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY: continue
					visible_meshes+=1
					for light: Light3D in [key,rim,fill,local]:
						body_lit=body_lit and (mesh.layers&light.light_cull_mask)!=0
			# Static floor/foundation instances have already entered the real
			# MultiMesh batches, so inspect their surviving material identities.
			var courts:=0; var masonry:=0
			for mesh: GeometryInstance3D in world.find_children("*","GeometryInstance3D",true,false):
				if mesh.material_override==world.court_material: courts+=1
				elif mesh.material_override==world.materials.stone: masonry+=1
				else: continue
				floor_lit=floor_lit and (mesh.layers&key.light_cull_mask)!=0
				for light: Light3D in [rim,fill,local]:
					actor_only=actor_only and (mesh.layers&light.light_cull_mask)==0
			check(visible_meshes>0 and body_lit,"%s region %d: every visible authored body, garment and held weapon is eligible for the same character lights" % [class_key,region])
			check(actor_only and floor_lit and courts>0 and masonry>0,"%s region %d: actual batched court and masonry keep room lighting while character fill and rim cannot wash the floor" % [class_key,region])
			var shadows:=0; var directionals:=0
			for light: Light3D in world.find_children("*","Light3D",true,false):
				if light.shadow_enabled: shadows+=1
				if light is DirectionalLight3D: directionals+=1
			check(shadows==1 and directionals==3 and key.shadow_enabled,"%s region %d: lighting retains the single existing room shadow pass and three existing directional lights" % [class_key,region])
			var shot: Transform3D=world.camera.transform
			world._update_combat_readability(0.0)
			check(sim.encode_snapshot()==before and world.camera.transform==shot,"%s region %d: readability and room-light setup change no combat authority or settled camera" % [class_key,region])
			world.free()
	game.free()
	print("DUNGEON LIGHTING SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
