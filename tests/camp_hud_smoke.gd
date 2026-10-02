extends SceneTree
## Exercise camp stations, real preparation actions and the compact battle controls.
const Store=preload("res://scripts/save_store.gd")
const Contract=preload("res://scripts/expedition_contract.gd")
const Glyph=preload("res://scripts/ui_glyph.gd")
var checks:=0
var failures:=0

func _initialize() -> void: run_checks.call_deferred()

func check(value: bool, description: String) -> void:
	checks+=1
	if value: print("PASS: ",description)
	else: failures+=1; push_error("FAIL: "+description)

func settle() -> void:
	for frame in range(4): await process_frame

func luminance(color: Color) -> float:
	var linear:=color.srgb_to_linear()
	return linear.r*0.2126+linear.g*0.7152+linear.b*0.0722

func contrast(foreground: Color, background: Color) -> float:
	return (maxf(luminance(foreground),luminance(background))+0.05)/(minf(luminance(foreground),luminance(background))+0.05)

func run_checks() -> void:
	var game:Node=load("res://Main.tscn").instantiate()
	game.save_store=Store.new("user://camp-hud-"+str(Time.get_ticks_usec()))
	game.clock_source=func(): return 2000000000.0
	root.add_child(game)
	game.farm_enabled=false
	game.onboarding_complete=true
	game.world_seed=1979
	game._return_to_camp()
	await settle()
	check(game.camp_scene.world.get_node_or_null("CampHeroModel")!=null,"camp renders the real hero model")
	check(game.camp_scene.hero.equipped_items==game.equipment,"camp model uses the actual equipped gear")
	var station_texture:Texture2D=game.camp_scene.STATION_ATLAS
	var atlas_image:Image=station_texture.get_image()
	check(atlas_image.detect_alpha()!=Image.ALPHA_NONE and station_texture.get_width()==station_texture.get_height()*3,"painted station atlas has native transparency and three equal cells")
	var painted_stations:=true
	for station in ["forge","table","portal"]:
		var art:Sprite3D=game.camp_scene.station_art[station]
		painted_stations=painted_stations and art.visible and art.texture is AtlasTexture and art.texture.atlas==station_texture
	check(painted_stations,"forge, table and portal render their shipped painted cutouts at real station anchors")
	check(game.camp_scene.world.get_node("CampStonePlatform").material_override is ShaderMaterial,"hero's physical platform uses the painted stone material")
	check(game.camp_scene.world.find_children("EarnedGuardianSeal*","Node3D",true,false).is_empty(),"unearned guardians have no camp trophies")
	game.find_child("CampForge",true,false).pressed.emit()
	await settle()
	check(game.page=="gear" and game.gear_tab=="equipment","forge opens actual equipment controls in one tap")
	var preview:Control=game.find_child("EquippedHeroPreview",true,false)
	check(preview!=null and preview.actor.equipped_items==game.equipment,"forge preview matches the equipped combat model")
	var glyph_count:=0
	var glyph_consistent:=true
	for slot in game.GEAR_SLOTS:
		var glyph:Control=game.find_child("SlotGlyph_"+slot,true,false)
		glyph_consistent=glyph_consistent and glyph!=null and glyph is Glyph and glyph.key==slot.to_lower() and glyph.ink==game.GOLD
		if glyph!=null: glyph_count+=1
	check(glyph_consistent and glyph_count==6,"each equipment slot uses its authored bronze line glyph")
	var gold:int=game.player_gold
	var power:int=game.equipment.Weapon.power
	game._temper_equipment("Weapon")
	check(game.equipment.Weapon.power>power and game.player_gold<gold,"forge tempering spends real Gold and improves the equipped weapon")
	game._return_to_camp()
	await settle()
	check(game.camp_scene.hero.equipped_items.Weapon.power==game.equipment.Weapon.power,"camp reflects the actual tempered weapon")
	game.find_child("CampHero",true,false).pressed.emit()
	check(game.page=="gear" and game.gear_tab=="build","hero station opens class and attribute preparation")
	var points:int=game.attribute_points
	game._allocate_attribute("Vitality")
	check(game.attribute_points==points-1 and game.allocated_attributes.Vitality==1,"training spends actual attribute points")
	game._grant_expedition_rewards(true,1,false,1979,"Vowkeeper")
	game._return_to_camp()
	await settle()
	check(game.first_relic_claimed and game.guardian_trophies==[0] and game.camp_scene.world.find_child("EarnedGuardianSeal0",true,false)!=null,"an actual first clear creates its earned camp seal")
	game.find_child("CampTable",true,false).pressed.emit()
	check(game.page=="camp_table" and game.find_child("FarmStartButton",true,false)!=null,"expedition table exposes real farming and oaths")
	game.find_child("Oathcinder",true,false).pressed.emit()
	game.find_child("Oathhollow",true,false).pressed.emit()
	check(game.selected_oaths.size()==2 and game.find_child("Oathunmended",true,false).disabled,"two selected oaths prevent a third risk from being added")
	game.find_child("StartOathExpedition",true,false).pressed.emit()
	game.run_active=false
	game.run_arena.animation_enabled=false
	await settle()
	check(game.expedition.contract()==Contract.combine(["cinder","hollow"]) and game.expedition.stats.get("oath_rules")==1,"table starts the real combined oath expedition")
	check(not game.combat_hud.hero_details.visible and not game.combat_hud.route_details.visible,"battle information starts collapsed")
	var snapshot:Dictionary=game.expedition.snapshot()
	var arena_id:int=game.run_arena.get_instance_id()
	game.find_child("CombatDetailsToggle",true,false).pressed.emit()
	check(game.combat_hud.hero_details.visible and game.combat_hud.route_details.visible,"Details reveals oath, technique and route information")
	game.last_back_frame=-1
	game._handle_back()
	check(not game.combat_hud.details_sheet.visible and game.expedition.snapshot()==snapshot and game.run_arena.get_instance_id()==arena_id,"Back closes details while preserving the fight and camera")
	game.find_child("AutoControl",true,false).pressed.emit()
	check(game.run_active,"Auto resumes the paused simulation")
	game.find_child("AutoControl",true,false).pressed.emit()
	check(not game.run_active,"Auto pauses the simulation")
	game.find_child("RepeatControl",true,false).pressed.emit()
	check(game.auto_repeat,"Repeat enables actual repeated expeditions")
	for resolution in [Vector2i(2424,1080),Vector2i(1040,1080),Vector2i(854,480)]:
		root.size=resolution
		await settle()
		for large in [false,true]:
			game.preferences.large_text=large
			game._build_ui()
			game.run_arena.animation_enabled=false
			await settle()
			var bounds:Rect2=game.get_global_rect()
			var controls_fit:=true
			for name in ["OpenSettings","CombatDetailsToggle","AutoControl","RepeatControl","LootControl"]:
				var button:Button=game.find_child(name,true,false)
				controls_fit=controls_fit and button!=null and bounds.encloses(button.get_global_rect()) and button.size.y>=48
			check(controls_fit,"%dx%d battle controls fit with %s text and at least 48-unit targets" % [resolution.x,resolution.y,"large" if large else "standard"])
			var boss_style:StyleBoxFlat=game.combat_hud.boss_panel.get_theme_stylebox("panel")
			var state_style:StyleBoxFlat=game.find_child("CombatStateGround",true,false).get_theme_stylebox("panel")
			var phase_ink:Color=game.combat_hud.boss.get_theme_color("font_color")
			var state_ink:Color=game.combat_hud.state.get_theme_color("font_color")
			check(boss_style.bg_color.a==1.0 and state_style.bg_color.a==1.0 and contrast(phase_ink,boss_style.bg_color)>=4.5 and contrast(state_ink,state_style.bg_color)>=4.5,"%dx%d phase and play-state text have opaque ink grounds with at least 4.5:1 contrast" % [resolution.x,resolution.y])
		game._return_to_camp()
		await settle()
		var camp_fit:=true
		var rectangles:Array[Rect2]=[]
		for name in ["CampForge","CampHero","CampTable","CampTrophies","CampSatchel","BeginButton","OpenSettings"]:
			var button:Button=game.find_child(name,true,false)
			camp_fit=camp_fit and button!=null and game.get_global_rect().encloses(button.get_global_rect()) and button.size.y>=48
			if name.begins_with("Camp") and name!="CampSatchel":
				for previous in rectangles: camp_fit=camp_fit and not previous.grow(4).intersects(button.get_global_rect())
				rectangles.append(button.get_global_rect())
		check(camp_fit,"%dx%d spatial camp stations fit and do not overlap" % [resolution.x,resolution.y])
		var nyra_button:Button=game.find_child("CampHero",true,false)
		check(nyra_button.position.y>=game.camp_scene.station_position("hero").y,"%dx%d Nyra's station label sits below her feet" % [resolution.x,resolution.y])
		game._start_run(2,Contract.combine(["cinder","hollow"]))
		game.run_active=false; game.run_arena.animation_enabled=false
	game._return_to_camp()
	game.pending_idle_fails=1
	game.pending_idle_ash=0
	game.pending_idle_xp=0
	game._build_ui()
	var setback_visible:=false
	for label in game.find_children("*","Label",true,false):
		if "1 setbacks" in label.text: setback_visible=true
	check(setback_visible and game.find_child("ClaimOfflineHaul",true,false)!=null,"camp exposes an offline setback even when no currency was earned")
	game.find_child("ClaimOfflineHaul",true,false).pressed.emit()
	check(game.pending_idle_fails==0,"offline setback report can be acknowledged")
	game._change_preference("reduced_motion",true,false)
	check(game.camp_scene.reduced_motion and not game.camp_scene.is_processing() and game.camp_scene.station_art.portal.visible,"reduced motion stops ambient animation while the painted portal and stations stay visible")
	game.free()
	await process_frame
	print("CAMP HUD SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
