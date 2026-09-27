extends "res://scripts/main.gd"
## Isolated Android package. Uses unmodified starting equipment and combat rules.
var ward_count:=0
var absorbed_total:=0
var spent_total:=0
var captured:=false
var completed:=false

func _ready() -> void:
	onboarding_complete=true
	super._ready()
	farm_enabled=false
	auto_repeat=false
	character_class="Arcanist"
	floor_number=1
	expedition_serial=0
	_start_run(1)
	print("ANDROID_WARD_START ",JSON.stringify(expedition.stats))

func _on_combat_advanced(updates: Array) -> void:
	for event in updates:
		if event.type=="ward":
			ward_count+=1
			absorbed_total+=event.absorbed
			spent_total+=event.mana_spent
			if not captured:
				captured=true
				capture_ward.call_deferred()
	super._on_combat_advanced(updates)
	if expedition.finished and not completed:
		completed=true
		print("ANDROID_WARD_END ",JSON.stringify({"won":expedition.won,"wards":ward_count,"absorbed":absorbed_total,"spent":spent_total,"casts":expedition.casts,"hp":expedition.hero_hp,"mana":expedition.hero_mana,"elapsed":expedition.elapsed}))

func capture_ward() -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://android-ward.png")
	print("ANDROID_WARD_CAPTURE visible=",run_arena.world.ward_shell.visible," hp=",expedition.hero_hp," mana=",expedition.hero_mana)
