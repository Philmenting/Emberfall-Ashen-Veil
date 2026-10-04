extends "res://tests/attack_gameplay_preview.gd"
## Bounded ordinary-clock proof. Run this same fixture against isolated source snapshots.
var proof_label:="SOURCE SNAPSHOT"
var evidence: Array=[]
func _ready() -> void:
	get_window().size=Vector2i(1200,536)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--proof-label="): proof_label=arg.trim_prefix("--proof-label=")
	bare_inspection=true
	super._ready()
func _record() -> void:
	for key in ["Vowkeeper","Arcanist","Ranger"]:
		character_class=key; floor_number=1; _start_run(); _manual()
		await _settle_renderer()
		for part in ["first","guardian"]:
			if part=="guardian":
				while not expedition.finished:
					if expedition.stage==5 and not expedition.enemy_by_id(50).warning.is_empty(): break
					expedition.advance(.1)
				assert(not expedition.finished)
				_sync_model_state(); _build_ui(); _manual()
				await _settle_renderer()
			var first_frame:=42 if key=="Arcanist" and part=="first" else (39 if key=="Ranger" and part=="first" else (27 if key=="Arcanist" else 42))
			for frame in range(120):
				var world: Node3D=run_arena.world
				world._process(1.0/30.0)
				for effect in world.effects: effect.node.visible=false
				world.target_ring.visible=false; world.hero_marker.visible=false; world.guard_visual.visible=false
				if is_instance_valid(world.ward_shell): world.ward_shell.visible=false
				for bar in world.bars.values(): bar.visible=false
				if key!="Vowkeeper" and frame>=first_frame and frame<first_frame+24:
					var hero: Node3D=world.hero
					get_node("InspectionLabel").text="QA · "+proof_label+" · REAL CLOCK / CAMERA · EFFECTS HIDDEN"
					await RenderingServer.frame_post_draw
					var filename: String="%s-%s-%03d.png" % [key.to_lower(),part,frame]
					get_viewport().get_texture().get_image().save_png(capture_dir+"/"+filename)
					evidence.append({"file":filename,"class":key,"part":part,"frame":frame,"elapsed":expedition.elapsed,"attack":hero.attack_time,"release":hero.release_time,"style":hero.attack_style,"position":hero.position,"yaw":hero.rotation.y,"camera":world.camera.transform,"life":expedition.hero_hp,"mana":expedition.hero_mana})
				elif frame%12==0: await get_tree().process_frame
	var file:=FileAccess.open(capture_dir+"/trace.json",FileAccess.WRITE); file.store_string(JSON.stringify(evidence,"  "))
	print("BOUNDED_BODY_PHRASE_AB ",evidence.size()," native frames; source=",proof_label)
	get_tree().quit()
