extends Control

const HeroArt = preload("res://scripts/hero_art.gd")
const CampScene = preload("res://scripts/camp_scene.gd")
const UiGlyph = preload("res://scripts/ui_glyph.gd")
const TITLE_FONT = preload("res://assets/fonts/Cinzel.ttf")
const BODY_FONT = preload("res://assets/fonts/Lora.ttf")
const BattleArt = preload("res://scripts/battle_art.gd")
const Expedition = preload("res://scripts/expedition_simulation.gd")
const Contract = preload("res://scripts/expedition_contract.gd")
const Skills = preload("res://scripts/class_skills.gd")
const Stances = preload("res://scripts/combat_stances.gd")
const BossPatterns = preload("res://scripts/boss_patterns.gd")
const RegionalSets = preload("res://scripts/regional_sets.gd")
const GearAdvisor = preload("res://scripts/gear_advisor.gd")
const PlaytestNotes = preload("res://scripts/playtest_notes.gd")
const Relics = preload("res://scripts/class_relics.gd")
const ClassLoot = preload("res://scripts/class_loot.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const Forecast = preload("res://scripts/farm_forecast.gd")
const OfflineFarm = preload("res://scripts/offline_farm.gd")
const MobileSafeArea = preload("res://scripts/mobile_safe_area.gd")
const Preferences = preload("res://scripts/game_preferences.gd")
const AudioDirector = preload("res://scripts/audio_director.gd")
const SettingsPanel = preload("res://scripts/settings_panel.gd")
const CombatReadout = preload("res://scripts/combat_readout.gd")
const CombatHealthBar = preload("res://scripts/combat_health_bar.gd")

const BG_TOP := Color("201c20")
const BG_BOTTOM := Color("090d12")
const PANEL := Color("171b21")
const PANEL_LIGHT := Color("20252c")
const EDGE := Color("41434a")
const GOLD := Color("d2ad70")
const PALE := Color("e7dfd2")
const MUTED := Color("c3b9a8")
const RED := Color("9e4239")
const GREEN := Color("86ad91")

const ATTRIBUTES := ["Strength", "Dexterity", "Intellect", "Vitality", "Spirit"]
const GEAR_SLOTS := ["Weapon", "Helmet", "Chest", "Gloves", "Boots", "Amulet"]
const ARMORED_SLOTS := ["Helmet", "Chest", "Gloves", "Boots"]
const ENEMIES := ["Hollow Stalker", "Ashbound Warden", "Veilborn Shade", "Cinder Knight", "Grave Lantern"]
const REGIONS := [
	{"name": "The Veilworn Marches", "dungeon": "Hollow Spire", "boss": "The Bell Warden", "description": "A broken watchtower where the lost still march.", "route": ["GATE", "GALLERY", "BELL TOWER", "HEART"]},
	{"name": "The Drowned Reaches", "dungeon": "Drowned Archive", "boss": "The Silt Abbot", "description": "A flooded library whose drowned scribes still guard its sealed vaults.", "route": ["SHORE", "CRYPT", "SUNKEN HALL", "VAULT"]},
	{"name": "The Blackglass Frontier", "dungeon": "Glass Ossuary", "boss": "The Mourning Queen", "description": "A glass desert split by old graves and a queen's unfinished lament.", "route": ["WASTES", "MIRROR PASS", "BONE GATE", "THRONE"]},
	{"name": "The Ashen Crown", "dungeon": "Cinder Citadel", "boss": "The Cinder Sovereign", "description": "The final citadel burns above a sea of ash and restless fire.", "route": ["OUTER WALL", "FURNACE", "CROWN ROAD", "CITADEL"]}
]
const CLASS_DATA := {
	"Vowkeeper": {
		"primary": "Strength", "secondary": "Vitality", "ability": "Ember Oath",
		"base": {"Strength": 18, "Dexterity": 8, "Intellect": 6, "Vitality": 16, "Spirit": 10},
		"color": Color("d2ad70"), "tagline": "Front line • oathbound bruiser",
		"passive": "Innate: 20% more Life and Armor. Ember Oath heals 8% Life, guards for 2.8s and cleaves nearby foes (5.5s cooldown)."
	},
	"Arcanist": {
		"primary": "Intellect", "secondary": "Spirit", "ability": "Veil Nova",
		"base": {"Strength": 5, "Dexterity": 8, "Intellect": 20, "Vitality": 9, "Spirit": 17},
		"color": Color("a58ed4"), "tagline": "Spellcaster • burst and mana",
		"passive": "Nova slows and interrupts groups (6s). Repositions between spells. Mana Ward absorbs 35% damage for 2 Mana each."
	},
	"Ranger": {
		"primary": "Dexterity", "secondary": "Vitality", "ability": "Cinder Volley",
		"base": {"Strength": 9, "Dexterity": 19, "Intellect": 6, "Vitality": 11, "Spirit": 11},
		"color": Color("83b596"), "tagline": "Ranged • precision and criticals",
		"passive": "Prioritizes hexers; retreats in close combat. Volley gains 12% crit and interrupts. Cooldown: 4.5s."
	}
}

const QUALITY_ORDER := ["COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY"]
const QUALITY_COLORS := {
	"COMMON": Color("c2bcb0"), "UNCOMMON": Color("85b497"), "RARE": Color("81a9d9"),
	"EPIC": Color("bb86d4"), "LEGENDARY": Color("e0a35d")
}
const MAX_OFFLINE_SECONDS := 24 * 60 * 60
const MAX_BAG_SIZE := 20
const MAX_TEMPER_RANK := 5
const RUN_SEED_MODULUS := 2147483647
const MAX_PROFILE_SEED := 2147483646

var clock_source: Callable = Time.get_unix_time_from_system

var preferences := Preferences.DEFAULTS.duplicate()
var audio: Node
var menu_resume_run := false
var last_back_frame := -1
var camp_scene: Control
var selected_oaths: Array[String] = []
var responsive_refresh_pending := false

var page := "camp"
var gear_tab := "bag"
var bag_slot := "All"
var bag_view := "all"
var bag_region := -1
var cleanup_preview: Array = []
var cleanup_class := ""
var cleanup_notice := ""
var character_class := "Vowkeeper"
var skill_loadouts := Skills.normalize_book({})
var combat_stances := Stances.normalize_book({})
var player_gold := 600
var player_shards := 0
var player_level := 1
var player_xp := 0
var attribute_points := 2
var allocated_attributes := {"Strength": 0, "Dexterity": 0, "Intellect": 0, "Vitality": 0, "Spirit": 0}
var floor_number := 1
var last_run_floor := 0
var run_floor := 1
var farm_floor := 1
var farm_mode := "campaign"
var offline_repeat_rules: Dictionary = {}
var hunt_slot := "Weapon"
var trial_cleared := 0
var world_tab := "campaign"
var run_reward: Dictionary = {}
var expedition_serial := 1
var world_seed := 0
var expedition: RefCounted
var auto_repeat := false
var last_combat_save := 0.0

var equipment := {
	"Weapon": {"name": "Pilgrim's Edge", "power": 54, "quality": "UNCOMMON", "tier": 1, "armor": 0, "stats": {"Strength": 4}, "sell": 62},
	"Helmet": {"name": "Ashen Watch Hood", "power": 31, "quality": "RARE", "tier": 1, "armor": 24, "stats": {"Vitality": 4}, "sell": 110},
	"Chest": {"name": "Veilwalker Mantle", "power": 47, "quality": "COMMON", "tier": 1, "armor": 48, "stats": {"Vitality": 5}, "sell": 52},
	"Gloves": {"name": "Grips of the Bellkeeper", "power": 25, "quality": "UNCOMMON", "tier": 1, "armor": 14, "stats": {"Dexterity": 2}, "sell": 70},
	"Boots": {"name": "Pilgrim's Treads", "power": 25, "quality": "COMMON", "tier": 1, "armor": 18, "stats": {"Vitality": 2}, "sell": 38},
	"Amulet": {"name": "Votive of the First Flame", "power": 35, "quality": "RARE", "tier": 1, "armor": 0, "stats": {"Spirit": 4, "Intellect": 2}, "sell": 92}
}
var inventory: Array = []

var pending_idle_ash := 0
var pending_idle_xp := 0
var pending_idle_runs := 0
var pending_idle_fails := 0
var pending_idle_gear := 0
var pending_idle_salvaged := 0
var idle_progress_seconds := 0
var last_saved_at := 0
var farm_enabled := true

var run_loot: Array = []
var run_stage := 0
var run_max_stages := 6
var run_active := false
var run_health := 100
var run_mana := 0
var enemy_health := 0
var enemy_max_health := 1
var run_succeeded := false
var run_boss_defeated := false
var run_events: Array[String] = []
var current_enemy := ENEMIES[0]
var run_arena: Control
var combat_hud: Dictionary = {}
var combat_details_open := false
var details_resume_run := false
var inspected_skill := "signature"
var finish_pending := false
var skipping_run := false
var backgrounded_at := 0
var save_store := SaveStore.new()
var save_notice := ""
var last_save_ok := true
var initialized := false
var onboarding_complete := false
var first_relic_claimed := false
var pending_class_relic: Dictionary = {}
var guardian_trophies: Array = []
var playtest_notes: Dictionary = {}
var ui_revision := 0
var forecast_cache: Dictionary = {}
var forecast_jobs: Dictionary = {}
var offline_job: RefCounted
var pending_afk_seconds := 0
var offline_checkpoint_clock := 0.0

func _ready() -> void:
	randomize()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	var native_theme := Theme.new()
	native_theme.default_font = BODY_FONT
	native_theme.default_font_size = 14
	theme = native_theme
	native_theme.set_constant("separation","HBoxContainer",8)
	_load_progress()
	get_tree().quit_on_go_back = false
	get_window().go_back_requested.connect(_handle_back)
	audio = AudioDirector.new()
	audio.name = "AudioDirector"
	add_child(audio)
	_apply_preferences()
	initialized = true
	for slot in GEAR_SLOTS:
		equipment[slot]["slot"] = slot
	_accrue_offline_time(OS.has_feature("android"))
	_save_progress()
	_build_ui()
	if not onboarding_complete and not save_store.write_blocked: _show_welcome()

func _draw() -> void:
	for i in range(48):
		var y0 := size.y * float(i) / 48.0
		var y1 := size.y * float(i + 1) / 48.0 + 1.0
		draw_rect(Rect2(0, y0, size.x, y1 - y0), BG_TOP.lerp(BG_BOTTOM, float(i) / 48.0))
	draw_arc(Vector2(size.x * 0.49, size.y * 0.45), size.y * 0.78, PI, TAU, 64, Color(0.71, 0.54, 0.36, 0.065), 2.0, true)
	draw_arc(Vector2(size.x * 0.49, size.y * 0.45), size.y * 0.68, PI, TAU, 64, Color(0.71, 0.54, 0.36, 0.04), 1.0, true)
	for i in range(22):
		var px := fmod(float(i * 97 + 29), maxf(size.x, 1.0))
		var py := fmod(float(i * 137 + 31), maxf(size.y, 1.0))
		draw_circle(Vector2(px, py), 1.2 if i % 3 == 0 else 0.8, Color(0.9, 0.55, 0.30, 0.14))

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
		if initialized and not responsive_refresh_pending:
			responsive_refresh_pending = true
			_refresh_responsive_layout.call_deferred()
	elif initialized and (what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST):
		backgrounded_at = int(clock_source.call())
		if is_instance_valid(audio): audio.set_suspended(true)
		if is_instance_valid(run_arena): run_arena.animation_enabled = false
		_save_progress()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_resume_from_background.call_deferred()

func _resume_from_background() -> void:
	if backgrounded_at == 0: return
	backgrounded_at = 0
	if is_instance_valid(audio): audio.set_suspended(false)
	_accrue_offline_time(OS.has_feature("android"))
	_save_progress()
	if page == "run":
		if is_instance_valid(run_arena):
			run_arena.animation_enabled = run_active
			_sync_combat_hud()
	else:
		_build_ui()

func _region_index(target_floor: int = -1) -> int:
	var selected_floor := floor_number if target_floor < 1 else target_floor
	return clampi(int((maxi(1, selected_floor) - 1) / 10.0), 0, REGIONS.size() - 1)

func _region_data(target_floor: int = -1) -> Dictionary:
	return REGIONS[_region_index(target_floor)]

func _refresh_responsive_layout() -> void:
	responsive_refresh_pending = false
	if has_node("Options") or has_node("Welcome") or finish_pending: return
	_build_ui()

func _build_ui() -> void:
	if page != "run":
		combat_details_open = false
		details_resume_run = false
	ui_revision += 1
	forecast_jobs.clear()
	camp_scene = null
	for child in get_children():
		if child == audio: continue
		remove_child(child)
		child.queue_free()
	if is_instance_valid(audio): audio.set_context(page=="run")
	if page == "run":
		_build_run()
		_show_save_notice()
		return
	if page == "camp":
		_build_spatial_camp()
		_show_save_notice()
		if offline_job!=null: _build_offline_loading()
		return
	var margins := MarginContainer.new()
	var insets := _mobile_insets()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margins.add_theme_constant_override("margin_"+edge, 16+int(insets[edge]))
	add_child(margins)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margins.add_child(layout)
	layout.add_child(_build_header())
	layout.add_child(_build_title_row())
	var scroll := ScrollContainer.new()
	scroll.name="PageScroll"
	scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	match page:
		"gear": _build_gear(content)
		"map": _build_map(content)
		"camp_table": _build_camp_table(content)
		"seals": _build_seals(content)
		"loot": _build_loot(content)
	layout.add_child(_build_navigation())
	_show_save_notice()
	if offline_job!=null: _build_offline_loading()

func _build_spatial_camp() -> void:
	camp_scene = CampScene.new()
	camp_scene.name = "CampScene"
	camp_scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	camp_scene.configure(character_class, equipment, guardian_trophies)
	camp_scene.reduced_motion = preferences.reduced_motion
	camp_scene.battery_mode = preferences.battery
	add_child(camp_scene)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	shade.offset_bottom=112
	shade.color=Color(0.025, 0.025, 0.035, 0.82)
	shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var safe := MarginContainer.new()
	safe.name="CampSafeArea"
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var insets:=_mobile_insets()
	for edge in ["left", "right", "top", "bottom"]:
		safe.add_theme_constant_override("margin_"+edge, 18+int(insets[edge]))
	safe.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(safe)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	layout.mouse_filter=Control.MOUSE_FILTER_IGNORE
	safe.add_child(layout)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	layout.add_child(header)
	var title := VBoxContainer.new()
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	title.add_child(_label("ASHEN CAMP", 22, GOLD, true))
	title.add_child(_label("Nyra · %s · Level %d" % [character_class, player_level], 12, PALE))
	var xp:=_progress_bar(player_xp, player_level*1000, GOLD, 4)
	xp.custom_minimum_size.x=220
	title.add_child(xp)
	header.add_child(title)
	header.add_child(_label("%s Gold" % _short_number(player_gold),14,GOLD,true))
	if player_shards>0: header.add_child(_label("%s Shards" % _short_number(player_shards),12,PALE))
	var options:=_glyph_button("", "settings", PANEL_LIGHT, 12, _show_settings)
	options.name="OpenSettings"
	options.tooltip_text="Options, audio and save backup"
	options.custom_minimum_size=Vector2(_minimum_button_height(48),_minimum_button_height(48))
	options.size_flags_horizontal=Control.SIZE_SHRINK_END
	header.add_child(options)
	var air:=Control.new()
	air.mouse_filter=Control.MOUSE_FILTER_IGNORE
	air.size_flags_vertical=Control.SIZE_EXPAND_FILL
	layout.add_child(air)
	var stations:=Control.new()
	stations.name="CampStations"
	stations.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stations.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(stations)
	for entry in [["forge","FORGE","Equipment", "CampForge"], ["hero","NYRA", "%d points" % attribute_points if attribute_points>0 else "Class & skills", "CampHero"], ["table","OATH FARM" if not offline_repeat_rules.is_empty() else "TABLE","Farms & oaths", "CampTable"], ["seals","SEALS","%d / 4 earned" % guardian_trophies.size(), "CampTrophies"]]:
		var station:=_glyph_button(String(entry[1]),String(entry[0]),Color(0.035,0.042,0.05,0.94),12,_open_camp_station.bind(String(entry[0])))
		station.name=String(entry[3])
		station.set_meta("camp_station_key",String(entry[0]))
		station.tooltip_text=String(entry[2])
		station.custom_minimum_size=Vector2(130,_minimum_button_height(48))
		stations.add_child(station)
	_position_camp_stations.call_deferred()
	var tray:=_panel(Color(0.025,0.025,0.035,0.95),Color("8e744a"),4)
	tray.name="CampActions"
	layout.add_child(tray)
	var actions:=HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	tray.add_child(actions)
	var bag:=_glyph_button("SATCHEL (%d)" % inventory.size(),"bag",PANEL_LIGHT,12,_open_camp_station.bind("bag"))
	bag.name="CampSatchel"
	bag.custom_minimum_size.x=175
	bag.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	actions.add_child(bag)
	var desc:=VBoxContainer.new()
	desc.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	desc.add_child(_label(String(_region_data().dungeon),15,PALE,true))
	desc.add_child(_label("Floor %02d · next descent" % floor_number,12,MUTED))
	var readiness:=_paragraph_label("Assessing your next descent…",11,MUTED)
	readiness.name="CampReadiness"
	desc.add_child(readiness)
	_update_forecast(readiness,floor_number,false)
	actions.add_child(desc)
	var descend:=_glyph_button("DESCEND", "portal", RED, 16, _start_run)
	descend.name="BeginButton"
	descend.custom_minimum_size.x=190
	descend.size_flags_horizontal=Control.SIZE_SHRINK_END
	actions.add_child(descend)
	if pending_idle_runs>0 or pending_idle_fails>0 or pending_idle_ash>0 or pending_idle_xp>0:
		layout.add_child(_label("OFFLINE REPORT · %d cleared · %d setbacks · %d relics kept" % [pending_idle_runs,pending_idle_fails,pending_idle_gear],12,PALE))
		var claim:=_button("CLAIM OFFLINE HAUL · %d Gold · %d XP" % [pending_idle_ash,pending_idle_xp],Color("31443a"),12,_claim_idle_cache)
		claim.name="ClaimOfflineHaul"
		layout.add_child(claim)
	elif not pending_class_relic.is_empty():
		var reserved:=_button("CLASS RELIC WAITING · OPEN SATCHEL",Color("493b30"),12,_open_camp_station.bind("bag"))
		reserved.name="OpenReservedRelic"
		layout.add_child(reserved)

func _position_camp_stations() -> void:
	if page!="camp" or not is_instance_valid(camp_scene): return
	await get_tree().process_frame
	if page!="camp" or not is_instance_valid(camp_scene): return
	var stations:=get_node_or_null("CampStations")
	if stations==null: return
	var bounds:=get_viewport_rect().size
	var insets:=_mobile_insets()
	var action_bar:=find_child("CampActions",true,false) as Control
	var lower_edge:=action_bar.global_position.y-10.0 if action_bar!=null else bounds.y-104.0
	var occupied:Array[Rect2]=[]
	for button in stations.get_children():
		var key:String=button.get_meta("camp_station_key")
		var at:Vector2=camp_scene.station_position(key)
		var target:Vector2=Vector2(at.x-button.size.x*.5,at.y+12.0)
		if key=="forge": target=Vector2(at.x-button.size.x-40.0,at.y-button.size.y*.15)
		if key=="hero": target.y=at.y+8.0
		if key=="table": target.x-=45; target.y+=10
		if key=="seals": target.x+=25; target.y+=10
		target.x=clampf(target.x,20+int(insets.left),maxf(20,bounds.x-button.size.x-20-int(insets.right)))
		target.y=clampf(target.y,118+int(insets.top),maxf(118,lower_edge-button.size.y))
		var rect:=Rect2(target,button.size)
		for previous in occupied:
			if rect.grow(8).intersects(previous):
				target.x=clampf(previous.end.x+10,20+int(insets.left),bounds.x-button.size.x-20-int(insets.right))
				rect=Rect2(target,button.size)
		button.position=target
		occupied.append(rect)

func _open_camp_station(key: String) -> void:
	if offline_job!=null: return
	match key:
		"forge": gear_tab="equipment"; _navigate("gear")
		"hero": gear_tab="build"; _navigate("gear")
		"bag": gear_tab="bag"; _navigate("gear")
		"table": _navigate("camp_table")
		"seals": _navigate("seals")

func _build_camp_table(parent: VBoxContainer) -> void:
	_build_reserved_relic(parent)
	if pending_idle_runs>0 or pending_idle_fails>0 or pending_idle_ash>0 or pending_idle_xp>0: _build_idle_report(parent)
	if floor_number>=2:
		_build_oaths(parent)
		parent.add_child(_small_divider())
	parent.add_child(_label("Offline expeditions", 20, GOLD, true))
	parent.add_child(_paragraph_label("Your chosen floor and farm goal apply while you are away. Up to 24 hours are counted; overflow gear is sold for Gold.",12,PALE))
	parent.add_child(_button("AFK FARM: %s" % ("ON" if farm_enabled else "OFF"),Color("31443a") if farm_enabled else PANEL_LIGHT,12,_toggle_farm))
	var farm_context:=_offline_farm_context()
	parent.add_child(_label("%s · FLOOR %02d" % [Contract.title(farm_context.contract),farm_context.floor],14,GREEN,true))
	if not offline_repeat_rules.is_empty():
		parent.add_child(_paragraph_label("These oaths stay active while you are away. Prepared %s build: %d Life, %d Mana, %d Attack. Changing equipment, attributes, class, skills or your farm goal starts a new preparation." % [farm_context["class"],farm_context.stats.max_hp,farm_context.stats.max_mana,farm_context.stats.attack],12,PALE))
		parent.add_child(_paragraph_label(Contract.describe(farm_context.contract),12,GOLD))
		var clear:=_button("RETURN TO SELECTED FARM",PANEL_LIGHT,12,_clear_offline_repeat)
		clear.name="EndOathFarm"
		parent.add_child(clear)
	parent.add_child(_button("FARM GOAL: "+(hunt_slot.to_upper() if farm_mode=="hunt" else "ALL GEAR"),PANEL_LIGHT,12,_open_hunts))
	var forecast:=_paragraph_label("Assessing this floor with your current gear…",12,MUTED)
	parent.add_child(forecast)
	_update_forecast(forecast,farm_context.floor,true,farm_context.contract,farm_context.stats)
	var farm_actions:=HBoxContainer.new()
	farm_actions.add_theme_constant_override("separation",8)
	parent.add_child(farm_actions)
	var previous:=_button("LOWER FLOOR",PANEL_LIGHT,12,_set_farm_floor.bind(-1))
	previous.disabled=farm_floor<=1
	farm_actions.add_child(previous)
	var farm:=_button("START AUTO FARM",Color("314b3c"),13,_start_farming)
	farm.name="FarmStartButton"
	farm_actions.add_child(farm)
	var next:=_button("HIGHER FLOOR",PANEL_LIGHT,12,_set_farm_floor.bind(1))
	next.disabled=farm_floor>=maxi(1,floor_number-1)
	farm_actions.add_child(next)
	parent.add_child(_small_divider())
	if floor_number<2: parent.add_child(_paragraph_label("Clear the first guardian to unlock expedition oaths, focused hunts and Ash Trials.",12,MUTED))
	_build_journey_goal(parent)
	if floor_number<=3: _build_first_steps(parent)

func _build_seals(parent: VBoxContainer) -> void:
	parent.add_child(_label("Guardian seals",22,GOLD,true))
	parent.add_child(_paragraph_label("Each seal marks a guardian you defeated in a campaign expedition. The seals on the camp altar come from these victories.",12,PALE))
	for region_id in range(REGIONS.size()):
		var earned:=region_id in guardian_trophies
		var row:=HBoxContainer.new()
		row.add_theme_constant_override("separation",16)
		parent.add_child(row)
		var glyph:=UiGlyph.new()
		glyph.key="seals"
		glyph.ink=GOLD if earned else MUTED.darkened(0.35)
		glyph.custom_minimum_size=Vector2(40,48)
		row.add_child(glyph)
		var name_stack:=VBoxContainer.new()
		name_stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		name_stack.add_child(_label(String(REGIONS[region_id].boss),16,PALE if earned else MUTED,true))
		name_stack.add_child(_label(String(REGIONS[region_id].dungeon),12,MUTED))
		row.add_child(name_stack)
		row.add_child(_label("EARNED" if earned else "UNCLAIMED",12,GOLD if earned else MUTED,true))
		parent.add_child(_small_divider())

func _build_header() -> Control:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	var back:=_glyph_button("CAMP","back",PANEL_LIGHT,12,_return_to_camp)
	back.name="ReturnButton"
	back.custom_minimum_size.x=126
	back.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	bar.add_child(back)
	var spacer:=Control.new()
	spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	bar.add_child(_label("%s Gold" % _short_number(player_gold),14,GOLD,true))
	var options:=_glyph_button("OPTIONS","settings",PANEL_LIGHT,12,_show_settings)
	options.name="OpenSettings"
	options.custom_minimum_size.x=146
	options.size_flags_horizontal=Control.SIZE_SHRINK_END
	bar.add_child(options)
	return bar

func _build_title_row() -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 23
	var region := _region_data()
	var title := "ASHEN CAMP"
	var subtitle := "SAFE HAVEN"
	match page:
		"camp_table":
			title = "EXPEDITION TABLE"
			subtitle = "FARMS & OATHS"
		"seals":
			title = "GUARDIAN SEALS"
			subtitle = "%d / 4 EARNED" % guardian_trophies.size()
		"gear":
			title = "ARMORY"
			subtitle = "POWER  %s  •  %s" % [_short_number(_hero_power()), character_class.to_upper()]
		"map":
			title = String(region.name).to_upper()
			subtitle = "REGION %02d  •  WORLD MAP" % (clampi(int((floor_number - 1) / 10.0), 0, REGIONS.size() - 1) + 1)
		"run":
			title = String(region.dungeon).to_upper()
			subtitle = "FLOOR %02d  •  AUTO EXPEDITION" % floor_number
		"loot":
			title = "DUNGEON CLEARED" if run_succeeded else "EXPEDITION ENDED"
			var reward_floor := last_run_floor if last_run_floor > 0 else floor_number
			subtitle = "FLOOR %02d  •  REWARDS" % reward_floor
	var heading := _label(title, 19, GOLD, true)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(heading)
	row.add_child(_label(subtitle, 9, MUTED, true))
	return row

func _build_hero_rail() -> Control:
	var rail := VBoxContainer.new()
	rail.custom_minimum_size.x = 206
	rail.add_theme_constant_override("separation", 7)
	var portrait := _panel(PANEL, EDGE, 17)
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rail.add_child(portrait)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 2)
	portrait.add_child(stack)
	var art := HeroArt.new()
	art.custom_minimum_size = Vector2(0, 218)
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art.configure(character_class, equipment)
	art.set_presentation(preferences.reduced_motion, preferences.battery)
	stack.add_child(art)
	stack.add_child(_centered_label("NYRA", 20, PALE, true))
	stack.add_child(_centered_label("%s  •  LEVEL %02d" % [character_class.to_upper(), player_level], 9, GOLD, true))
	stack.add_child(_centered_label(String(CLASS_DATA[character_class].tagline), 9, MUTED))
	var class_button := _button("CHANGE CLASS",PANEL_LIGHT,10,Callable(self,"_open_build"))
	class_button.custom_minimum_size.y = _minimum_button_height(38)
	rail.add_child(class_button)
	return rail

func _build_stats_rail() -> Control:
	var rail := ScrollContainer.new()
	rail.custom_minimum_size.x = 214
	rail.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 7)
	rail.add_child(content)
	var stats := _combat_stats()
	var card := _panel(PANEL, EDGE, 17)
	content.add_child(card)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	card.add_child(stack)
	stack.add_child(_label("HERO ATTRIBUTES", 10, GOLD, true))
	stack.add_child(_label("COMBAT POWER  %s" % _short_number(int(stats.power)), 16, PALE, true))
	stack.add_child(_progress_bar(player_xp, player_level * 1000, GOLD, 7))
	stack.add_child(_label("%d / %d XP TO NEXT LEVEL" % [player_xp, player_level * 1000], 8, MUTED, true))
	for attribute in ATTRIBUTES:
		var line := HBoxContainer.new()
		line.add_child(_label(_attribute_short(attribute), 10, MUTED, true))
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(spacer)
		line.add_child(_label(str(stats.attributes[attribute]), 12, PALE, true))
		stack.add_child(line)
	stack.add_child(_small_divider())
	stack.add_child(_label("LIFE  %d     MANA  %d" % [stats.max_hp, stats.max_mana], 10, PALE, true))
	stack.add_child(_label("ARMOR  %d     CRIT  %.1f%%" % [stats.armor, stats.crit], 10, MUTED, true))
	var skill := _panel(Color("252127"), Color("594b5d"), 16)
	content.add_child(skill)
	var skill_stack := VBoxContainer.new()
	skill_stack.add_theme_constant_override("separation", 4)
	skill.add_child(skill_stack)
	var ability_rank := _ability_rank(int(stats.attributes[CLASS_DATA[character_class].primary]))
	skill_stack.add_child(_label("CLASS ABILITY  •  RANK %d" % ability_rank, 9, Color("bea0db"), true))
	skill_stack.add_child(_label(String(CLASS_DATA[character_class].ability), 14, PALE, true))
	skill_stack.add_child(_label("%d damage  •  %d mana" % [stats.ability_damage, stats.mana_cost], 10, MUTED))
	skill_stack.add_child(_paragraph_label(String(CLASS_DATA[character_class].passive), 9, MUTED))
	skill_stack.add_child(_label("MAXIMUM RANK" if ability_rank>=10 else "Next rank at %s %d" % [String(CLASS_DATA[character_class].primary),ability_rank*15],9,GOLD))
	content.add_child(_button("AFK FARM: %s" % ("ON" if farm_enabled else "OFF"), Color("31443a") if farm_enabled else PANEL_LIGHT, 9, Callable(self, "_toggle_farm")))
	return rail

func _build_idle_report(parent: VBoxContainer) -> void:
	var report := _panel(Color("19241f"), Color("405347"), 16)
	parent.add_child(report)
	var report_stack := VBoxContainer.new()
	report_stack.add_theme_constant_override("separation", 5)
	report.add_child(report_stack)
	report_stack.add_child(_label("OFFLINE REPORT  •  READY TO CLAIM", 10, GREEN, true))
	report_stack.add_child(_paragraph_label("%d cleared  •  %d setbacks  •  %d relics kept  •  %d auto-salvaged" % [pending_idle_runs, pending_idle_fails, pending_idle_gear, pending_idle_salvaged], 11, PALE))
	report_stack.add_child(_label("+%d Gold  •  +%d XP" % [pending_idle_ash, pending_idle_xp], 12, GOLD, true))
	report_stack.add_child(_button("CLAIM OFFLINE HAUL", Color("31443a"), 11, Callable(self, "_claim_idle_cache")))

func _build_gear(parent: VBoxContainer) -> void:
	var tabs:=HBoxContainer.new()
	tabs.add_theme_constant_override("separation",6)
	parent.add_child(tabs)
	for tab in [["bag","BAG (%d)" % inventory.size()],["equipment","EQUIPMENT"],["build","CLASS & STATS"],["skills","SKILLS"]]:
		var selected: bool=gear_tab==tab[0] or (gear_tab=="sets" and tab[0]=="equipment")
		tabs.add_child(_button(tab[1],Color("493b30") if selected else PANEL_LIGHT,10,_select_gear_tab.bind(String(tab[0]))))
	match gear_tab:
		"build": _build_class_editor(parent)
		"skills": _build_skill_editor(parent)
		"equipment": _build_equipment_list(parent)
		"sets": _build_set_progress(parent)
		_: _build_inventory_list(parent)

func _build_class_editor(parent: VBoxContainer) -> void:
	_build_hero_summary(parent)
	var classes := HBoxContainer.new()
	classes.add_theme_constant_override("separation", 6)
	parent.add_child(_section_heading("PLAYABLE CLASSES", "%d ATTRIBUTE POINTS" % attribute_points))
	for class_key in CLASS_DATA.keys():
		var class_button := _button(String(class_key).to_upper(), PANEL_LIGHT if character_class != class_key else Color("493b30"), 10, Callable(self, "_select_class").bind(String(class_key)))
		class_button.custom_minimum_size.y = _minimum_button_height(42)
		classes.add_child(class_button)
	parent.add_child(classes)
	parent.add_child(_section_heading("ATTRIBUTE ALLOCATION", "ATTRIBUTES ALSO RAISE ABILITY RANK"))
	var combat_snapshot := _combat_stats()
	var attributes: Dictionary = combat_snapshot.get("attributes", {})
	var attr_row := HBoxContainer.new()
	attr_row.add_theme_constant_override("separation", 5)
	for attribute in ATTRIBUTES:
		var attr_button := _button("%s\n%d\n+" % [_attribute_short(attribute), attributes[attribute]], Color("20252c"), 10, Callable(self, "_allocate_attribute").bind(attribute))
		attr_button.custom_minimum_size = Vector2(0, 66)
		attr_button.disabled = attribute_points <= 0
		attr_row.add_child(attr_button)
	parent.add_child(attr_row)
	parent.add_child(_empty_note("Your primary attribute strengthens attacks and abilities. Vitality gives Life; Spirit gives Mana. Changing class refunds allocated points so you can rebuild freely."))
	var reset:=_button("REFUND ALLOCATED POINTS",PANEL_LIGHT,10,_reset_attributes)
	var spent:=0
	for value in allocated_attributes.values(): spent+=int(value)
	reset.disabled=spent==0
	parent.add_child(reset)

func _build_equipment_list(parent: VBoxContainer) -> void:
	_build_hero_summary(parent)
	var sets:=_button("REGIONAL SETS & HUNT GOALS",PANEL_LIGHT,12,_select_gear_tab.bind("sets"))
	sets.name="ReviewRegionalSets"
	parent.add_child(sets)
	parent.add_child(_section_heading("EQUIPPED GEAR", "%d SLOTS  •  TEMPER UP TO +%d" % [GEAR_SLOTS.size(), MAX_TEMPER_RANK]))
	for slot in GEAR_SLOTS:
		parent.add_child(_equipped_row(slot, equipment[slot]))

func _build_hero_summary(parent: VBoxContainer) -> void:
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",20)
	parent.add_child(row)
	var art:=HeroArt.new()
	art.name="EquippedHeroPreview"
	art.portrait=false
	art.custom_minimum_size=Vector2(152,168)
	art.configure(character_class,equipment)
	art.set_presentation(preferences.reduced_motion,preferences.battery)
	row.add_child(art)
	var stats:=_combat_stats()
	var details:=VBoxContainer.new()
	details.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation",6)
	row.add_child(details)
	details.add_child(_label("NYRA · "+character_class.to_upper(),20,PALE,true))
	details.add_child(_label("Level %d · Combat power %s" % [player_level,_short_number(stats.power)],14,GOLD))
	details.add_child(_progress_bar(player_xp,player_level*1000,GOLD,5))
	details.add_child(_label("%d / %d XP" % [player_xp,player_level*1000],12,MUTED))
	details.add_child(_label("Life %d · Mana %d · Armor %d" % [stats.max_hp,stats.max_mana,stats.armor],13,PALE))
	details.add_child(_label("Attack %d · Critical %.1f%%" % [stats.attack,stats.crit],13,PALE))
	var active_set:=RegionalSets.active(equipment)
	if active_set>=0: details.add_child(_paragraph_label(RegionalSets.DEFINITIONS[active_set].name+" · "+RegionalSets.DEFINITIONS[active_set].rule,12,GREEN))
	var relic:=Relics.effect(equipment.Amulet,character_class)
	if not relic.is_empty(): details.add_child(_paragraph_label(Relics.DEFINITIONS[relic].name+" · "+Relics.DEFINITIONS[relic].short,12,GOLD))
	parent.add_child(_small_divider())

func _build_inventory_list(parent: VBoxContainer) -> void:
	parent.add_child(_section_heading("SATCHEL", "%d / %d ITEMS" % [inventory.size(), MAX_BAG_SIZE]))
	_build_reserved_relic(parent)
	if bag_view=="cleanup":
		_build_cleanup_preview(parent)
		return
	if not cleanup_notice.is_empty(): parent.add_child(_paragraph_label(cleanup_notice,11,GOLD))
	if inventory.is_empty():
		parent.add_child(_empty_note("No spare gear. Clear a floor to find new equipment."))
		return
	var obsolete:=_obsolete_gear()
	if not obsolete.is_empty():
		var review:=_button("REVIEW DUPLICATE SALES (%d)" % obsolete.size(),PANEL_LIGHT,11,_review_cleanup)
		review.name="ReviewDuplicateSales"
		parent.add_child(review)
	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation", 6)
	parent.add_child(filters)
	var slots := ["All"] + GEAR_SLOTS
	var slot_filter := _bag_filter("BagSlotFilter", slots.map(func(slot): return "Slot: " + String(slot)), slots.find(bag_slot))
	slot_filter.item_selected.connect(func(index): bag_slot=slots[index]; _build_ui())
	filters.add_child(slot_filter)
	var views := ["all", "class", "upgrades", "protected"]
	var captions := ["Show: All gear", "Show: Class gear", "Show: Safe upgrades", "Show: Protected"]
	if bag_region>=0 and bag_region<RegionalSets.DEFINITIONS.size():
		views.append("set")
		captions.append("Set: "+String(RegionalSets.DEFINITIONS[bag_region].name))
	var view_filter := _bag_filter("BagViewFilter", captions, views.find(bag_view))
	view_filter.item_selected.connect(func(index): bag_view=views[index]; _build_ui())
	filters.add_child(view_filter)
	var shown := _filtered_inventory()
	parent.add_child(_paragraph_label("%d matching items • Protect gear to prevent selling it. Equipped protection also blocks automatic replacement." % shown.size(), 10, MUTED))
	if shown.is_empty():
		parent.add_child(_empty_note("No gear matches these filters. Your other items are still in the satchel."))
		parent.add_child(_button("SHOW ALL GEAR", PANEL_LIGHT, 11, _show_all_gear))
	for item in shown:
		parent.add_child(_item_card(item, true))

func _bag_filter(node_name: String, captions: Array, selected: int) -> OptionButton:
	var control := OptionButton.new()
	control.name=node_name
	control.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	control.custom_minimum_size.y=_minimum_button_height(44)
	control.add_theme_font_size_override("font_size", _scaled_font_size(11))
	control.add_theme_color_override("font_color", PALE)
	for caption in captions: control.add_item(caption)
	control.select(maxi(0, selected))
	control.get_popup().add_theme_font_size_override("font_size", _scaled_font_size(14))
	control.get_popup().add_theme_constant_override("v_separation", maxi(20, _minimum_button_height(44)-_scaled_font_size(14)))
	return control

func _filtered_inventory() -> Array:
	var shown: Array = []
	for item in inventory:
		if bag_slot!="All" and item.slot!=bag_slot: continue
		if bag_view=="class" and item.get("affinity", "")!=character_class: continue
		if bag_view=="upgrades" and not _is_safe_upgrade(item): continue
		if bag_view=="protected" and not item.get("locked", false): continue
		if bag_view=="set" and item.get("region",-1)!=bag_region: continue
		shown.append(item)
	return shown

func _show_all_gear() -> void:
	cleanup_preview.clear()
	bag_slot="All"
	bag_view="all"
	bag_region=-1
	_build_ui()

func _build_map(parent: VBoxContainer) -> void:
	var tabs:=HBoxContainer.new()
	parent.add_child(tabs)
	for entry in [["campaign","CAMPAIGN"],["hunts","HUNTS"],["trials","ASH TRIALS"]]:
		var tab:=_button(entry[1],RED if world_tab==entry[0] else PANEL_LIGHT,11,_select_world_tab.bind(entry[0]))
		tab.name="WorldTab_"+entry[0]
		tabs.add_child(tab)
	if world_tab=="hunts":
		_build_hunts(parent)
		return
	if world_tab=="trials":
		_build_trials(parent)
		return
	var region := _region_data()
	var map_card := _panel(PANEL, EDGE, 17)
	parent.add_child(map_card)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 7)
	map_card.add_child(stack)
	stack.add_child(_label(String(region.name).to_upper(), 10, GOLD, true))
	stack.add_child(_label("%s  •  Floor %02d" % [String(region.dungeon), floor_number], 20, PALE, true))
	stack.add_child(_paragraph_label("%s Its guardian is %s. Nyra advances automatically while the expedition is active." % [String(region.description), String(region.boss)], 13, MUTED))
	stack.add_child(_paragraph_label("%s: %s Below half Life, the guardian awakens with wider, faster attacks. Nyra seeks safety automatically when her dodge is ready." % [BossPatterns.NAMES[_region_index(floor_number)],BossPatterns.DESCRIPTIONS[_region_index(floor_number)]],12,PALE))
	stack.add_child(_map_route())
	var tier_start := int(floor(float(floor_number - 1) / 10.0)) * 10 + 1
	stack.add_child(_label("Tier %d drops are available on floors %d–%d." % [_gear_tier(), tier_start, tier_start + 9], 11, PALE))
	stack.add_child(_button("ENTER DUNGEON   →", RED, 14, Callable(self, "_start_run")))
	parent.add_child(_campaign_atlas())
	var notes := _panel(PANEL_LIGHT, EDGE, 16)
	parent.add_child(notes)
	var notes_stack := VBoxContainer.new()
	notes_stack.add_child(_label("AFK FARMING", 10, GOLD, true))
	notes_stack.add_child(_paragraph_label("When you leave or background the app, the next launch simulates runs on your chosen farm floor from elapsed time, using the same combat rules. Up to 24 hours are counted; overflow gear is sold for Gold.", 12, PALE))
	notes.add_child(notes_stack)

func _build_run() -> void:
	combat_hud.clear()
	var arena:=BattleArt.new()
	arena.name="BattleArena"
	arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena.character_class=character_class
	arena.equipment_visual=equipment.duplicate(true)
	arena.region_index=_region_index(run_floor)
	arena.simulation=expedition
	arena.animation_enabled=run_active
	arena.battery_mode=preferences.battery
	arena.damage_numbers=preferences.numbers
	arena.reduced_motion=preferences.reduced_motion
	arena.simulation_advanced.connect(_on_combat_advanced)
	arena.state_changed.connect(_on_dungeon_state_changed)
	add_child(arena)
	run_arena=arena
	var safe:=MarginContainer.new()
	safe.name="CombatSafeArea"
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var insets:=_mobile_insets()
	for edge in ["left","right","top","bottom"]:
		safe.add_theme_constant_override("margin_"+edge,16+int(insets[edge]))
	safe.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(safe)
	var overlay:=VBoxContainer.new()
	overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
	overlay.add_theme_constant_override("separation",8)
	safe.add_child(overlay)
	var top:=HBoxContainer.new()
	top.add_theme_constant_override("separation",18)
	top.mouse_filter=Control.MOUSE_FILTER_IGNORE
	overlay.add_child(top)
	var hero_panel:=_panel(Color(0.027,0.024,0.027,0.8),Color("9c8053"),4)
	hero_panel.custom_minimum_size.x=226
	hero_panel.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	hero_panel.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	top.add_child(hero_panel)
	var hero_row:=HBoxContainer.new()
	hero_row.add_theme_constant_override("separation",10)
	hero_panel.add_child(hero_row)
	var portrait:=HeroArt.new()
	portrait.name="NyraPortrait"
	portrait.configure(character_class,equipment)
	portrait.set_presentation(preferences.reduced_motion,preferences.battery)
	portrait.custom_minimum_size=Vector2(50,64)
	hero_row.add_child(portrait)
	var hero_stack:=VBoxContainer.new()
	hero_stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	hero_stack.add_theme_constant_override("separation",3)
	hero_row.add_child(hero_stack)
	hero_stack.add_child(_label("NYRA · %d" % player_level,14,PALE,true))
	combat_hud.hp=_progress_bar(run_health,expedition.stats.max_hp,Color("b62c2b"),10,true)
	hero_stack.add_child(combat_hud.hp)
	combat_hud.mana=_progress_bar(run_mana,expedition.stats.max_mana,Color("438e9e"),6)
	hero_stack.add_child(combat_hud.mana)
	combat_hud.life=_label("",10,PALE)
	hero_stack.add_child(combat_hud.life)
	combat_hud.protection=_label("",10,Color("79dbdc"))
	combat_hud.protection.name="ProtectionStatus"
	hero_stack.add_child(combat_hud.protection)
	var boss_stack:=VBoxContainer.new()
	boss_stack.mouse_filter=Control.MOUSE_FILTER_IGNORE
	boss_stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	boss_stack.add_theme_constant_override("separation",3)
	var guardian_space:=VBoxContainer.new()
	guardian_space.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	guardian_space.mouse_filter=Control.MOUSE_FILTER_IGNORE
	top.add_child(guardian_space)
	var boss_ground:=_ink_ground(6,4)
	boss_ground.name="BossTextGround"
	guardian_space.add_child(boss_ground)
	boss_ground.custom_minimum_size.x=280
	boss_ground.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	boss_ground.add_child(boss_stack)
	combat_hud.boss_panel=boss_ground
	combat_hud.boss_panel.name="BossEncounter"
	combat_hud.boss_name=_centered_label("",14,PALE,true)
	combat_hud.boss_name.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	boss_stack.add_child(combat_hud.boss_name)
	combat_hud.boss_hp=_progress_bar(0,1,Color("b9382d"),7,true)
	boss_stack.add_child(combat_hud.boss_hp)
	combat_hud.boss_life=_centered_label("",10,GOLD)
	boss_stack.add_child(combat_hud.boss_life)
	combat_hud.boss=_centered_label("",12,Color("ffd4a1"),true)
	combat_hud.boss.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	boss_stack.add_child(combat_hud.boss)
	var region_panel:=_panel(Color(0.027,0.024,0.027,0.78),Color("9c8053"),4)
	region_panel.size_flags_horizontal=Control.SIZE_SHRINK_END
	region_panel.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	region_panel.custom_minimum_size.x=204
	top.add_child(region_panel)
	var region_row:=HBoxContainer.new()
	region_row.add_theme_constant_override("separation",8)
	region_panel.add_child(region_row)
	var region:=VBoxContainer.new()
	region.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var dungeon_name:=_label(String(_region_data(run_floor).dungeon).replace("The ","").to_upper(),12,GOLD,true)
	dungeon_name.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	dungeon_name.custom_minimum_size.x=132
	region.add_child(dungeon_name)
	region.add_child(_label("FLOOR %02d" % run_floor,12,PALE,true))
	if Contract.mode(expedition.contract())=="trial":
		combat_hud.trial_clock=_label("",12,Color("ddc3f4"),true)
		combat_hud.trial_clock.name="TrialClock"
		region.add_child(combat_hud.trial_clock)
	region_row.add_child(region)
	combat_hud.pause=_glyph_button("","pause",Color("292824"),12,_show_settings)
	combat_hud.pause.name="OpenSettings"
	combat_hud.pause.tooltip_text="Pause and open options"
	combat_hud.pause.custom_minimum_size=Vector2(_minimum_button_height(48),_minimum_button_height(48))
	combat_hud.pause.size_flags_horizontal=Control.SIZE_SHRINK_END
	region_row.add_child(combat_hud.pause)
	var air:=Control.new()
	air.mouse_filter=Control.MOUSE_FILTER_IGNORE
	air.size_flags_vertical=Control.SIZE_EXPAND_FILL
	overlay.add_child(air)
	var dock:=_build_combat_readouts(overlay)
	var dock_gap:=Control.new()
	dock_gap.custom_minimum_size.x=8; dock_gap.mouse_filter=Control.MOUSE_FILTER_IGNORE
	dock.add_child(dock_gap)
	combat_hud.auto=_combat_command("AUTO","auto",_toggle_run_pause)
	combat_hud.auto.name="AutoControl"; combat_hud.auto.custom_minimum_size.x=90
	dock.add_child(combat_hud.auto)
	combat_hud.details=_combat_command("DETAILS","map",_toggle_combat_details)
	combat_hud.details.name="CombatDetailsToggle"
	dock.add_child(combat_hud.details)
	combat_hud.repeat=_combat_command("REPEAT","repeat",_toggle_repeat)
	combat_hud.repeat.name="RepeatControl"; combat_hud.repeat.custom_minimum_size.x=100
	dock.add_child(combat_hud.repeat)
	combat_hud.loot=_combat_command("LOOT","loot",_skip_run)
	combat_hud.loot.name="LootControl"
	combat_hud.loot.tooltip_text="Resolve this expedition with the same combat rules and collect its outcome"
	dock.add_child(combat_hud.loot)
	# A scrollable detail sheet preserves the world and simulation beneath it.
	var detail_sheet:=_panel(Color(0.035,0.037,0.045,0.97),Color("9c8053"),5)
	detail_sheet.name="CombatDetails"
	detail_sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	detail_sheet.offset_left=18+int(insets.left)
	detail_sheet.offset_right=-18-int(insets.right)
	detail_sheet.offset_top=126+int(insets.top)
	detail_sheet.offset_bottom=-84-int(insets.bottom)
	detail_sheet.visible=combat_details_open
	add_child(detail_sheet)
	combat_hud.details_sheet=detail_sheet
	var detail_scroll:=ScrollContainer.new()
	detail_scroll.name="CombatDetailScroll"
	detail_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	detail_sheet.add_child(detail_scroll)
	var columns: BoxContainer=VBoxContainer.new() if _compact_layout() or size.x/size.y<1.35 else HBoxContainer.new()
	columns.name="InspectionContent"
	columns.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation",18)
	detail_scroll.add_child(columns)
	var hero_details:=VBoxContainer.new()
	hero_details.name="HeroDetails"
	hero_details.visible=combat_details_open
	hero_details.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	hero_details.add_theme_constant_override("separation",8)
	columns.add_child(hero_details)
	hero_details.add_child(_label("PAUSED WHILE READING",12,GOLD,true))
	combat_hud.inspected_title=_paragraph_label("",14,PALE,true)
	hero_details.add_child(combat_hud.inspected_title)
	combat_hud.inspected_rule=_paragraph_label("",12,PALE)
	hero_details.add_child(combat_hud.inspected_rule)
	hero_details.add_child(_paragraph_label("Skills cast automatically when their conditions are met. Ready means enough Mana and no cooldown; Nyra still needs a suitable target and range.",11,MUTED))
	hero_details.add_child(_small_divider())
	hero_details.add_child(_label(character_class.to_upper(),16,PALE,true))
	var stance:Dictionary=Stances.definition(expedition.stats)
	hero_details.add_child(_label(String(stance.name).to_upper()+" STANCE",12,Color(stance.color)))
	if expedition.stats.has("class_relic"):
		hero_details.add_child(_paragraph_label(Relics.DEFINITIONS[expedition.stats.class_relic].name,13,GOLD,true))
	var rules:Dictionary=expedition.contract()
	if Contract.mode(rules)=="oath":
		hero_details.add_child(_paragraph_label(Contract.describe(rules),12,GOLD))
		var synergy:=Contract.synergy_description(rules,character_class,expedition.stats)
		if not synergy.is_empty(): hero_details.add_child(_paragraph_label(synergy,12,GREEN))
	combat_hud.skill=_paragraph_label("",12,GOLD)
	hero_details.add_child(combat_hud.skill)
	if character_class=="Arcanist" and float(expedition.stats.get("mana_guard",0.0))>0.0:
		combat_hud.ward=_label("",12,Color("d1bdea"))
		hero_details.add_child(combat_hud.ward)
	if expedition.uses_rotation():
		combat_hud.techniques={}
		for key in expedition.stats.skill_loadout:
			var status:=_label("",12,Color(Skills.DEFINITIONS[key].color))
			status.name="TechniqueStatus_"+key
			hero_details.add_child(status)
			combat_hud.techniques[key]=status
		combat_hud.guard=_label("",12,GREEN)
		hero_details.add_child(combat_hud.guard)
	combat_hud.hero_details=hero_details
	var route_details:=VBoxContainer.new()
	route_details.name="RouteDetails"
	route_details.visible=combat_details_open
	route_details.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	route_details.add_theme_constant_override("separation",8)
	columns.add_child(route_details)
	combat_hud.route_details=route_details
	route_details.add_child(_label("EXPEDITION",16,PALE,true))
	combat_hud.encounter=_label("",12,PALE,true)
	route_details.add_child(combat_hud.encounter)
	combat_hud.progress=_progress_bar(0,run_max_stages,GOLD,5)
	route_details.add_child(combat_hud.progress)
	if expedition.uses_journey():
		var route_map:=preload("res://scripts/expedition_map.gd").new()
		route_map.name="ExpeditionMap"
		route_map.simulation=expedition
		route_details.add_child(route_map)
		combat_hud.room=_label("",12,GOLD,true)
		route_details.add_child(combat_hud.room)
		combat_hud.objective=_paragraph_label("",12,MUTED)
		route_details.add_child(combat_hud.objective)
	combat_hud.enemy=_paragraph_label("",12,PALE)
	route_details.add_child(combat_hud.enemy)
	combat_hud.enemy_hp=_progress_bar(enemy_health,enemy_max_health,RED,6)
	route_details.add_child(combat_hud.enemy_hp)
	_sync_combat_hud()
	_sync_combat_clearance.call_deferred()

func _build_combat_readouts(parent: VBoxContainer) -> HBoxContainer:
	var readouts:=HBoxContainer.new()
	readouts.name="CombatReadouts"
	readouts.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	readouts.add_theme_constant_override("separation",12)
	readouts.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(readouts)
	combat_hud.readouts=readouts
	var state_ground:=_ink_ground(7,3)
	state_ground.name="CombatStateGround"
	state_ground.custom_minimum_size.x=360
	state_ground.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	readouts.add_child(state_ground)
	combat_hud.state=_label("AUTO",10,GOLD,true)
	combat_hud.state.clip_text=true
	combat_hud.state.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	state_ground.add_child(combat_hud.state)
	var route_ground:=_ink_ground(7,3)
	route_ground.name="CombatRouteReadout"
	route_ground.custom_minimum_size.x=302
	readouts.add_child(route_ground)
	var route:=VBoxContainer.new(); route.add_theme_constant_override("separation",1)
	route_ground.add_child(route)
	var route_line:=HBoxContainer.new(); route_line.add_theme_constant_override("separation",12)
	route.add_child(route_line)
	combat_hud.route_summary=_label("",10,GOLD,true)
	route_line.add_child(combat_hud.route_summary)
	combat_hud.route_objective=_label("",10,PALE)
	combat_hud.route_objective.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	combat_hud.route_objective.clip_text=true
	combat_hud.route_objective.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	route_line.add_child(combat_hud.route_objective)
	combat_hud.route_progress=_progress_bar(0,6,GOLD,2)
	route.add_child(combat_hud.route_progress)
	var dock:=HBoxContainer.new()
	dock.name="CombatCommandDock"
	dock.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	dock.add_theme_constant_override("separation",8)
	dock.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(dock)
	combat_hud.skill_tiles={}
	for entry in CombatReadout.skills(expedition):
		var tile:=_button("",Color("151a1e"),10,_inspect_combat_skill.bind(String(entry.key)))
		tile.name="CombatSkill_"+String(entry.key)
		tile.custom_minimum_size=Vector2(134,_minimum_button_height(60))
		tile.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
		tile.tooltip_text="Inspect %s · casts automatically · %d Mana" % [entry.title,entry.cost]
		_style_combat_command(tile)
		dock.add_child(tile)
		var margin:=MarginContainer.new()
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		margin.mouse_filter=Control.MOUSE_FILTER_IGNORE
		for edge in ["left","right"]: margin.add_theme_constant_override("margin_"+edge,7)
		for edge in ["top","bottom"]: margin.add_theme_constant_override("margin_"+edge,5)
		tile.add_child(margin)
		var stack:=VBoxContainer.new()
		stack.add_theme_constant_override("separation",2)
		stack.mouse_filter=Control.MOUSE_FILTER_IGNORE
		margin.add_child(stack)
		var title:=_label(entry.title,10,PALE,true)
		title.mouse_filter=Control.MOUSE_FILTER_IGNORE; stack.add_child(title)
		var status:=_label("",10,PALE)
		status.mouse_filter=Control.MOUSE_FILTER_IGNORE; stack.add_child(status)
		var cooldown:=_progress_bar(0,1,entry.color,3)
		stack.add_child(cooldown)
		combat_hud.skill_tiles[entry.key]={"button":tile,"status":status,"bar":cooldown}
	readouts.item_rect_changed.connect(func(): _sync_combat_clearance.call_deferred())
	return dock

func _style_combat_command(button: Button) -> void:
	for state in ["normal","hover","pressed","focus"]:
		var box:=button.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		box.set_corner_radius_all(2)
		if state!="focus":
			box.border_color=Color("655849") if state=="hover" else Color("49463f")
			box.bg_color=Color("20282b") if state=="hover" else Color("0c1115") if state=="pressed" else Color("151a1e")
		button.add_theme_stylebox_override(state,box)

func _combat_command(caption: String,icon: String,action: Callable) -> Button:
	var button:=_button(caption,Color("151a1e"),10,action)
	button.custom_minimum_size=Vector2(82,_minimum_button_height(60))
	button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	_style_combat_command(button)
	for state in ["normal","hover","pressed","focus"]:
		var box:=button.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		box.content_margin_left=6; box.content_margin_right=6
		box.content_margin_top=27; box.content_margin_bottom=5
		button.add_theme_stylebox_override(state,box)
	var glyph:=UiGlyph.new(); glyph.key=icon; glyph.ink=GOLD
	glyph.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	glyph.offset_left=-10; glyph.offset_right=10; glyph.offset_top=7; glyph.offset_bottom=27
	button.add_child(glyph)
	return button

func _sync_combat_clearance() -> void:
	if page!="run" or not is_instance_valid(run_arena) or not combat_hud.has("readouts"): return
	var top: float=combat_hud.readouts.global_position.y-global_position.y
	# Containers briefly report their unlaid-out origin. Reserving it would
	# permanently widen a monotonic room shot before the first visible frame.
	if top<size.y*0.55 or combat_hud.readouts.size.x<=0.0: return
	var bottom_ratio:=clampf((top-8.0)/maxf(1.0,size.y),0.60,0.90)
	if not is_equal_approx(run_arena.world.hud_bottom_ratio,bottom_ratio):
		run_arena.world.hud_bottom_ratio=bottom_ratio
		run_arena.world.shot_stage=-1
		run_arena.world._position_camera()
	combat_hud.details_sheet.offset_bottom=top-size.y-8.0
	var content:=find_child("InspectionContent",true,false) as BoxContainer
	if combat_details_open and content!=null and content is VBoxContainer:
		var needed:float=content.get_combined_minimum_size().y+26.0
		var bottom:float=minf(top-8.0,combat_hud.details_sheet.offset_top+maxf(300.0,needed))
		combat_hud.details_sheet.offset_bottom=bottom-size.y

func _inspect_combat_skill(key: String) -> void:
	if page!="run" or finish_pending: return
	inspected_skill=key
	if not combat_details_open: _toggle_combat_details()
	else: _sync_combat_hud()
	var scroll:=find_child("CombatDetailScroll",true,false) as ScrollContainer
	if scroll!=null: scroll.scroll_vertical=0

func _toggle_combat_details() -> void:
	if page!="run" or finish_pending: return
	var expanded:bool=not combat_details_open
	if expanded:
		details_resume_run=run_active
		run_active=false
	else:
		run_active=details_resume_run
		details_resume_run=false
	combat_details_open=expanded
	run_arena.animation_enabled=run_active
	combat_hud.hero_details.visible=expanded
	combat_hud.route_details.visible=expanded
	combat_hud.details_sheet.visible=expanded
	_sync_combat_hud()
	_sync_combat_clearance.call_deferred()
	_save_progress()
	if not expanded: combat_hud.details.grab_focus()

func _on_dungeon_state_changed(description: String) -> void:
	if combat_hud.has("state") and not combat_details_open:
		combat_hud.state.text = description

func _sync_combat_readouts() -> void:
	if not combat_hud.has("skill_tiles"): return
	combat_hud.life.add_theme_color_override("font_color",Color("ff6a2e") if run_health<=expedition.stats.max_hp*0.25 else PALE)
	combat_hud.hp.set_feedback_active(run_active)
	combat_hud.boss_hp.set_feedback_active(run_active)
	combat_hud.protection.text=CombatReadout.protection(expedition)
	combat_hud.protection.visible=not combat_hud.protection.text.is_empty()
	combat_hud.details.text="CLOSE" if combat_details_open else "DETAILS"
	combat_hud.details.tooltip_text="Close reading view" if combat_details_open else "Pause and inspect skills, oaths and route map"
	combat_hud.loot.disabled=combat_details_open
	if combat_details_open: combat_hud.state.text="READING · COMBAT PAUSED"
	for entry in CombatReadout.skills(expedition):
		var tile: Dictionary=combat_hud.skill_tiles[entry.key]
		tile.status.text=entry.status
		tile.status.add_theme_color_override("font_color",GOLD if entry.state=="casting" else GREEN if entry.state=="ready" else Color("ff6a2e") if entry.state=="mana" else PALE)
		tile.bar.value=entry.progress
		tile.button.accessibility_name="%s, %s. Inspect automatic skill." % [entry.title,entry.status]
	var route:=CombatReadout.route(expedition)
	combat_hud.route_summary.text=route.label
	combat_hud.route_objective.text=route.objective
	combat_hud.route_objective.tooltip_text=route.objective
	combat_hud.route_progress.max_value=route.total
	combat_hud.route_progress.value=route.completed
	if inspected_skill=="signature" or not Skills.DEFINITIONS.has(inspected_skill):
		combat_hud.inspected_title.text=String(CLASS_DATA[character_class].ability).to_upper()+" · %d MANA" % expedition.signature_cost()
		combat_hud.inspected_rule.text=CLASS_DATA[character_class].passive
	else:
		var definition: Dictionary=Skills.DEFINITIONS[inspected_skill]
		combat_hud.inspected_title.text=String(definition.name).to_upper()+" · %d MANA" % expedition.technique_cost(inspected_skill)
		combat_hud.inspected_rule.text=definition.rule

func _sync_combat_hud() -> void:
	if page != "run" or combat_hud.is_empty(): return
	if combat_hud.has("trial_clock"):
		combat_hud.trial_clock.text="TIME LEFT • %03d s" % maxi(0,ceili(expedition.duration_limit()-expedition.elapsed))
	if combat_hud.has("repeat"):
		combat_hud.repeat.disabled=Contract.mode(expedition.contract())=="trial"
	if page != "run" or combat_hud.is_empty(): return
	combat_hud.state.text = ("AUTO • " if run_active else "PAUSED • ")+String(expedition.action).to_upper()
	combat_hud.hp.value = run_health
	combat_hud.mana.value = run_mana
	combat_hud.life.text = "%d Life · %d Mana" % [run_health,run_mana]
	_sync_combat_readouts()
	combat_hud.progress.value = run_stage
	combat_hud.encounter.text = "PACK %02d / %02d  •  %d ALIVE" % [mini(run_stage+1,run_max_stages),run_max_stages,expedition.living().size()]
	if combat_hud.has("room"):
		combat_hud.room.text=expedition.Layout.room_name(expedition.Layout.region(run_floor),mini(run_stage,5)).to_upper()
		combat_hud.objective.text=expedition.Layout.objective(mini(run_stage,5))
		if expedition.journey.chest_open: combat_hud.objective.text="Reliquary recovered • returning with the spoils"
		elif expedition.stage==5 and expedition.living().is_empty(): combat_hud.objective.text="Guardian defeated • recover the reliquary"
		elif expedition.stage==3 and expedition.journey.seal_broken: combat_hud.objective.text="Sanctum open • follow the passage"
	combat_hud.boss.visible=false
	if combat_hud.has("boss_panel"):
		var guardian: Dictionary=expedition.enemy_by_id(50)
		combat_hud.boss_panel.visible=expedition.stage==5 and guardian.get("hp",0)>0
		if combat_hud.boss_panel.visible:
			combat_hud.boss_name.text=String(guardian.name).to_upper()
			combat_hud.boss_hp.max_value=guardian.max_hp
			combat_hud.boss_hp.value=guardian.hp
			combat_hud.boss_life.text="PHASE %d · %d%% LIFE" % [int(guardian.get("boss_phase",1 if guardian.get("awakened",false) else 0))+1,ceili(100.0*guardian.hp/guardian.max_hp)]
	if expedition.stage==5:
		var boss: Dictionary=expedition.enemy_by_id(50)
		if boss.get("hp",0)>0 and boss.has("awakened"):
			combat_hud.boss.visible=true
			combat_hud.boss.text="PHASE %d · %s" % [int(boss.get("boss_phase",1 if boss.awakened else 0))+1, BossPatterns.phase_name(_region_index(run_floor),int(boss.get("boss_phase",1 if boss.awakened else 0)))]
			if boss.warning.has("zones"):
				combat_hud.boss.text="%s • %.1fs" % [String(boss.warning.name).to_upper(),maxf(0.0,boss.warning.left)]
	combat_hud.enemy.text = "%s  •  %d / %d" % [current_enemy,enemy_health,enemy_max_health]
	combat_hud.enemy_hp.max_value = enemy_max_health
	combat_hud.enemy_hp.value = enemy_health
	if expedition.uses_journey() and expedition.phase in ["interact","loot"]:
		combat_hud.enemy.text=expedition.action
		combat_hud.enemy_hp.max_value=1.2
		combat_hud.enemy_hp.value=expedition.journey.channel
	combat_hud.auto.text = "AUTO" if run_active else "RESUME"
	combat_hud.auto.tooltip_text = "Pause automatic combat" if run_active else "Resume automatic combat"
	combat_hud.repeat.text = "REPEAT ON" if auto_repeat else "REPEAT"
	combat_hud.repeat.tooltip_text = "Disable repeated expeditions" if auto_repeat else "Repeat this floor until defeat"
	var signature_status:= "READY" if expedition.skill_cd<=0 else "%.1fs" % expedition.skill_cd
	if expedition.skill_cd<=0 and expedition.hero_mana<expedition.signature_cost(): signature_status="LOW MANA"
	combat_hud.skill.text = "%s · %s · %d Mana" % [String(CLASS_DATA[character_class].ability),signature_status,expedition.signature_cost()]
	if combat_hud.has("techniques"):
		for key in combat_hud.techniques:
			var definition: Dictionary=Skills.DEFINITIONS[key]
			var cooldown: float=expedition.rotation.cooldowns[key]
			var status: String="READY" if cooldown<=0.0 else "%.1fs" % cooldown
			if cooldown<=0.0 and expedition.hero_mana<expedition.technique_cost(key): status="LOW MANA"
			if expedition.pending_attack.get("ability_id","")==key: status="CASTING"
			combat_hud.techniques[key].text="%s · %s · %d Mana" % [definition.short,status,expedition.technique_cost(key)]
		combat_hud.guard.text="GUARD • %.1fs" % expedition.guard_time if expedition.guard_time>0.0 else "AUTO ROTATION • 3 SKILLS"
	if combat_hud.has("ward"):
		combat_hud.ward.text = "WARD · %d MANA AVAILABLE" % maxi(0,expedition.hero_mana-expedition.signature_cost())

func _build_loot(parent: VBoxContainer) -> void:
	var victory := _panel(Color("28261f"), Color("796746"), 17)
	parent.add_child(victory)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	victory.add_child(stack)
	stack.add_child(_label("%s" % ("✦  EXPEDITION CLEARED  ✦" if run_succeeded else "EXPEDITION ENDED"), 11, GOLD if run_succeeded else Color("d48166"), true))
	var reward_floor := last_run_floor if last_run_floor > 0 else floor_number
	stack.add_child(_label("%s • +%d XP • +%d Gold" % [String(run_reward.get("title","Floor %02d" % reward_floor)),int(run_reward.get("xp",0)),int(run_reward.get("gold",0))],16,PALE,true))
	if not String(run_reward.get("note","")).is_empty(): stack.add_child(_paragraph_label(run_reward.note,11,GOLD,true))
	if run_reward.has("seconds"):
		stack.add_child(_label("%.1fs  •  %d foes defeated  •  %d skills cast  •  %d evasions" % [run_reward.seconds,run_reward.kills,run_reward.casts,run_reward.dodges],12,MUTED))
	if not run_succeeded:
		stack.add_child(_paragraph_label(_defeat_context(),12,PALE))
		stack.add_child(_paragraph_label(_recovery_advice().copy,12,PALE))
	_build_reserved_relic(stack)
	for item in run_loot:
		if inventory.has(item) and not Relics.effect(item,character_class).is_empty() and Relics.effect(equipment.Amulet,character_class).is_empty():
			stack.add_child(_paragraph_label(Relics.DEFINITIONS[item.relic].short,11,GOLD,true))
			var equip_relic:=_button("EQUIP "+String(item.name).to_upper(),Color("314b3c"),11,_equip_item.bind(item))
			equip_relic.name="EquipClassRelic"
			stack.add_child(equip_relic)
			break
	var next := HBoxContainer.new()
	next.add_theme_constant_override("separation",10)
	stack.add_child(next)
	if run_succeeded:
		var mode := Contract.mode(expedition.contract()) if expedition!=null else "campaign"
		var caption := "DESCEND TO FLOOR %02d" % floor_number
		if mode=="hunt": caption="REPEAT "+hunt_slot.to_upper()+" HUNT"
		elif mode=="trial": caption="ENTER TRIAL %02d" % (trial_cleared+1)
		var advance := _button(caption,RED,12,_continue_expedition)
		advance.name="ContinueExpedition"
		advance.disabled=mode=="trial" and trial_cleared>=Contract.MAX_TRIAL
		next.add_child(advance)
	else:
		var review := _button(_recovery_advice().caption,RED,12,_open_recovery_advice)
		review.name="ReviewDefeatedBuild"
		next.add_child(review)
	var camp := _button("RETURN TO CAMP",PANEL_LIGHT,11,_return_to_camp)
	camp.name="ReturnToCamp"
	next.add_child(camp)
	if not run_succeeded and floor_number>1 and last_run_floor>1:
		var recovery_floor := mini(farm_floor, mini(floor_number-1,last_run_floor-1))
		var farm := _button("FARM CLEARED FLOOR %02d" % recovery_floor, Color("314b3c"), 11, _start_recovery_farm)
		farm.name="RecoveryFarm"
		stack.add_child(farm)
		stack.add_child(_paragraph_label("Repeats with standard rules and stops on defeat. Your offline farm goal stays as selected in camp.",10,MUTED))
	var safe_count := 0
	for item in run_loot:
		if inventory.has(item) and _is_safe_upgrade(item): safe_count+=1
	if safe_count>0:
		var equip := _button("EQUIP SAFE UPGRADES (%d)" % safe_count,Color("314b3c"),11,_equip_recovered_upgrades)
		equip.name="EquipRecoveredUpgrades"
		stack.add_child(equip)
		stack.add_child(_paragraph_label("Improves combat stats or activates a set without stat losses, higher Mana cost, or replacing an active set or signature effect. Protected equipment stays equipped; displaced gear stays in your bag.",11,MUTED))
	if run_succeeded and run_boss_defeated:
		var boss_name := String(_region_data(reward_floor).boss)
		stack.add_child(_label("%s's seal guarantees at least a Rare relic." % boss_name, 10, Color("e0a35d")))
	parent.add_child(_section_heading("RECOVERED GEAR", "%d RELICS" % run_loot.size()))
	if run_loot.is_empty():
		parent.add_child(_empty_note("No gear was recovered this run."))
	for item in run_loot:
		if item.get("status", "") == "equipped":
			parent.add_child(_empty_note("%s  •  EQUIPPED" % item.name))
		elif item.get("status", "") == "sold":
			parent.add_child(_empty_note("%s  •  SOLD FOR %d GOLD" % [item.name, item.sell]))
		else:
			parent.add_child(_item_card(item, true))

func _build_navigation() -> Control:
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	for entry in [["camp","CAMP","camp"],["forge","GEAR","gear"],["map","WORLD","map"]]:
		var button:=_glyph_button(String(entry[1]),String(entry[0]),Color("493b30") if page==entry[2] else PANEL_LIGHT,12,_navigate.bind(String(entry[2])))
		button.name="Navigate"+String(entry[1])
		row.add_child(button)
	return row

func _equipped_row(slot: String, item: Dictionary) -> Control:
	var row := _panel(PANEL, _quality_color(item.quality).darkened(0.45), 13)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",6)
	row.add_child(stack)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	stack.add_child(line)
	line.add_child(_slot_glyph(slot))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(_label("%s  •  T%d  •  +%d  •  %s" % [slot.to_upper(), item.tier, int(item.get("temper", 0)), _quality_label(item.quality)], 8, _quality_color(item.quality), true))
	info.add_child(_paragraph_label(String(item.name), 12, PALE, true))
	if CLASS_DATA.has(String(item.get("affinity",""))): info.add_child(_label(String(item.affinity).to_upper()+" ATTUNEMENT",8,MUTED))
	info.add_child(_label(_item_stats_line(item), 9, MUTED))
	if item.get("locked",false): info.add_child(_label("PROTECTED",9,GOLD,true))
	line.add_child(info)
	line.add_child(_label("ITEM %d" % int(item.power),10,GOLD,true))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation",6)
	stack.add_child(actions)
	actions.add_child(_temper_button(slot, item))
	actions.add_child(_protection_button(item))
	return row

func _item_card(item: Dictionary, show_actions: bool) -> Control:
	var rarity := String(item.get("quality", "COMMON"))
	var card := _panel(PANEL, _quality_color(rarity).darkened(0.48), 13)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	card.add_child(stack)
	var top := HBoxContainer.new()
	top.add_child(_slot_glyph(String(item.slot)))
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(_paragraph_label(String(item.name), 12, PALE, true))
	if item.get("locked",false): identity.add_child(_label("PROTECTED",9,GOLD,true))
	identity.add_child(_label("%s  •  T%d  •  +%d  •  %s" % [String(item.slot).to_upper(), int(item.tier), int(item.get("temper", 0)), _quality_label(rarity)], 8, _quality_color(rarity), true))
	if _is_safe_upgrade(item): identity.add_child(_label("UPGRADE • NO BUILD TRADEOFF",9,GREEN,true))
	top.add_child(identity)
	top.add_child(_label("ITEM %d" % int(item.power),11,GOLD,true))
	stack.add_child(top)
	if CLASS_DATA.has(String(item.get("affinity",""))): stack.add_child(_paragraph_label(String(item.affinity).to_upper()+" ATTUNEMENT • Usable by all classes",8,MUTED))
	var region: Variant=item.get("region")
	if region is int and region>=0 and region<4:
		stack.add_child(_paragraph_label(RegionalSets.DEFINITIONS[region].name+" • 3 worn pieces: "+RegionalSets.DEFINITIONS[region].rule,10,GREEN))
	var relic_copy:=Relics.describe(item)
	if not relic_copy.is_empty():
		stack.add_child(_paragraph_label(relic_copy,11,GOLD,true))
		if Relics.effect(item,character_class).is_empty(): stack.add_child(_paragraph_label("Effect inactive for your current class.",10,MUTED))
	stack.add_child(_paragraph_label("%s  •  %d armor" % [_item_stats_line(item),int(item.armor)],9,MUTED))
	for effect_change in _gear_effect_changes(item):
		stack.add_child(_paragraph_label(effect_change.copy,11,Color("dc9683") if effect_change.loss else GREEN))
	stack.add_child(_label("IF EQUIPPED  •  "+character_class.to_upper(),8,GOLD,true))
	var comparison := _compare_item(item)
	var changes := GridContainer.new()
	changes.columns = 3
	changes.add_theme_constant_override("h_separation",12)
	changes.add_theme_constant_override("v_separation",3)
	stack.add_child(changes)
	for key in ["attack","ability_damage","max_hp","armor","max_mana","crit"]:
		var value := float(comparison[key])
		var caption: String = {"attack":"Attack","ability_damage":"Ability","max_hp":"Life","armor":"Armor","max_mana":"Mana","crit":"Crit"}[key]
		var amount := ("+" if value>0 else "")+("%.1f%%" % value if key=="crit" else str(int(value)))
		var label := _label(caption+" "+amount,9,GREEN if value>0 else Color("dc9683") if value<0 else MUTED)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		changes.add_child(label)
	if comparison.mana_cost!=0:
		stack.add_child(_label("Ability cost: %s%d mana per cast" % ["+" if comparison.mana_cost>0 else "",comparison.mana_cost],9,GOLD if comparison.mana_cost>0 else GREEN))
	if show_actions:
		var actions := HBoxContainer.new()
		actions.add_theme_constant_override("separation", 6)
		actions.add_child(_button("EQUIP", PANEL_LIGHT, 10, Callable(self, "_equip_item").bind(item)))
		actions.add_child(_protection_button(item))
		var sell := _button("PROTECTED" if item.get("locked",false) else "SELL  +%d" % int(item.sell), Color("402f2d"), 10, Callable(self, "_sell_item").bind(item))
		sell.disabled=item.get("locked",false)
		actions.add_child(sell)
		stack.add_child(actions)
	return card

func _temper_button(slot: String, item: Dictionary) -> Button:
	var rank := int(item.get("temper", 0))
	var maxed := rank >= MAX_TEMPER_RANK
	var cost := _temper_cost(item)
	var button := _button("MAX" if maxed else "TEMPER\n%d G" % cost, Color("493b30"), 8, Callable(self, "_temper_equipment").bind(slot))
	button.custom_minimum_size = Vector2(76,_minimum_button_height(46))
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	button.disabled = maxed or player_gold < cost
	return button

func _temper_cost(item: Dictionary) -> int:
	return 200 + int(item.get("tier", 1)) * 100 + int(item.get("temper", 0)) * 175

func _map_route() -> Control:
	var route := HBoxContainer.new()
	route.add_theme_constant_override("separation", 0)
	var route_names: Array = _region_data().route
	for i in range(4):
		var stage := VBoxContainer.new()
		stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stage.add_child(_centered_label("◆" if i < 3 else "◇", 17, GOLD if i < 3 else MUTED))
		stage.add_child(_centered_label(String(route_names[i]), 7, MUTED, true))
		route.add_child(stage)
		if i < 3:
			var thread := ColorRect.new()
			thread.color = Color("6f5a43") if i < 2 else Color("41434a")
			thread.custom_minimum_size = Vector2(18, 2)
			thread.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			route.add_child(thread)
	return route

func _campaign_atlas() -> Control:
	var current_region := _region_index()
	var atlas := _panel(PANEL_LIGHT, EDGE, 16)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 6)
	atlas.add_child(stack)
	stack.add_child(_section_heading("CAMPAIGN ATLAS", "%d REGIONS" % REGIONS.size()))
	for i in range(REGIONS.size()):
		var region: Dictionary = REGIONS[i]
		var first_floor := i * 10 + 1
		var last_floor := first_floor + 9
		var status := "CURRENT" if i == current_region else "CLEARED" if i < current_region else "LOCKED  •  FLOOR %02d" % first_floor
		var status_color := GOLD if i == current_region else GREEN if i < current_region else MUTED
		var row := _panel(Color("191d23") if i == current_region else PANEL, Color("514537") if i == current_region else EDGE, 11)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		row.add_child(line)
		line.add_child(_centered_label("◆" if i == current_region else "✓" if i < current_region else "◇", 15, status_color))
		var description := VBoxContainer.new()
		description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		description.add_child(_label(String(region.name), 11, PALE, true))
		description.add_child(_label("%s  •  %s" % [String(region.dungeon), String(region.boss)], 9, MUTED))
		line.add_child(description)
		line.add_child(_label("%02d–%02d" % [first_floor, last_floor] if i < REGIONS.size() - 1 else "%02d+" % first_floor, 9, MUTED, true))
		line.add_child(_label(status, 8, status_color, true))
		stack.add_child(row)
	return atlas

func _section_heading(heading: String, note: String) -> Control:
	var row := HBoxContainer.new()
	var title := _label(heading, 9, GOLD, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	row.add_child(_label(note, 8, MUTED, true))
	return row

func _empty_note(copy: String) -> Control:
	var panel := _panel(Color(0.10, 0.105, 0.12, 0.9), Color("373941"), 12)
	panel.add_child(_paragraph_label(copy, 11, MUTED))
	return panel

func _resource_chip(icon: String, value: String, color: Color) -> Control:
	var chip := HBoxContainer.new()
	chip.add_theme_constant_override("separation", 4)
	chip.add_child(_label(icon, 11, color, true))
	chip.add_child(_label(value, 9, PALE, true))
	return chip

func _button(caption: String, fill: Color, font_size: int, action: Callable) -> Button:
	var button := Button.new()
	button.mouse_filter=Control.MOUSE_FILTER_PASS
	button.text = caption
	button.set_meta("emberfall_base_font_size",font_size)
	button.add_theme_font_size_override("font_size",_scaled_font_size(font_size))
	button.custom_minimum_size = Vector2(_minimum_button_height(48),_minimum_button_height(46))
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_color_override("font_color", PALE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", GOLD)
	button.add_theme_color_override("font_disabled_color", MUTED)
	var normal := StyleBoxFlat.new()
	normal.bg_color = fill
	normal.border_color = fill.lightened(0.12)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(10)
	normal.content_margin_left = 9
	normal.content_margin_right = 9
	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = fill.lightened(0.12)
	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = fill.darkened(0.10)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	var focus: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("ffe2a2")
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)
	button.pressed.connect(func():
		if is_instance_valid(audio): audio.cue("ui")
	)
	button.pressed.connect(action)
	return button

func _glyph_button(caption: String, icon: String, fill: Color, font_size: int, action: Callable) -> Button:
	var button:=_button(caption,fill,font_size,action)
	for state in ["normal","hover","pressed","focus"]:
		var box:=button.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		box.content_margin_left=42 if not caption.is_empty() else 10
		box.content_margin_right=12
		box.set_corner_radius_all(5)
		button.add_theme_stylebox_override(state,box)
	var glyph:=UiGlyph.new()
	glyph.key=icon
	glyph.ink=GOLD
	glyph.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	glyph.offset_left=12 if not caption.is_empty() else 14
	glyph.offset_right=glyph.offset_left+24
	glyph.offset_top=-12
	glyph.offset_bottom=12
	button.add_child(glyph)
	return button

func _panel(fill: Color, edge: Color, radius: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter=Control.MOUSE_FILTER_PASS
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 11
	style.content_margin_right = 11
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _label(copy: String, font_size: int, color: Color, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = copy
	label.set_meta("emberfall_base_font_size",font_size)
	label.add_theme_font_size_override("font_size",_scaled_font_size(font_size))
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_font_override("font", TITLE_FONT)
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	return label

func _compact_layout() -> bool:
	if OS.has_feature("android"):
		var logical_size:=get_viewport_rect().size
		return logical_size.x<=960 or logical_size.y<=600
	var window_size := DisplayServer.window_get_size()
	return window_size.x <= 960 or window_size.y <= 540

func _scaled_font_size(base_size: int) -> int:
	var compact:=_compact_layout()
	var scale := 1.2 if compact else 1.0
	if preferences.get("large_text",false):
		scale=maxf(scale,1.35 if compact else 1.15)
	return maxi(12,roundi(float(base_size)*scale))

func _minimum_button_height(base_size: int) -> int:
	var compact:=_compact_layout()
	var target:=maxi(base_size,48)
	if compact: target=maxi(target,52)
	if preferences.get("large_text",false): target=maxi(target,58 if compact else 48)
	if OS.has_feature("android"):
		var physical_height:=maxi(1,DisplayServer.window_get_size().y)
		var density:=maxf(1.0,float(DisplayServer.screen_get_dpi())/160.0)
		target=maxi(target,ceili(48.0*density*get_viewport_rect().size.y/physical_height))
	return target

func _refresh_font_sizes(node: Node) -> void:
	if node is Control and node.has_meta("emberfall_base_font_size"):
		node.add_theme_font_size_override("font_size",_scaled_font_size(int(node.get_meta("emberfall_base_font_size"))))
	if node is BaseButton:
		node.custom_minimum_size.y=maxf(node.custom_minimum_size.y,_minimum_button_height(48))
	for child in node.get_children(): _refresh_font_sizes(child)

func _paragraph_label(copy: String, font_size: int, color: Color, bold: bool = false) -> Label:
	var label := _label(copy, font_size, color, bold)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _centered_label(copy: String, font_size: int, color: Color, bold: bool = false) -> Label:
	var label := _label(copy, font_size, color, bold)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

func _small_divider() -> Control:
	var divider := ColorRect.new()
	divider.color = Color("41434a")
	divider.custom_minimum_size.y = 1
	return divider

func _progress_bar(value: float, maximum: float, color: Color, height: int, health_feedback: bool=false) -> ProgressBar:
	var bar: ProgressBar = CombatHealthBar.new() if health_feedback else ProgressBar.new()
	if health_feedback: bar.set_presentation(preferences.reduced_motion,preferences.battery)
	bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	bar.custom_minimum_size.y = height
	bar.max_value = maximum
	bar.value = value
	bar.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color("343338")
	background.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("background", background)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _combat_stats(loadout: Dictionary = {}) -> Dictionary:
	var equipped: Dictionary = equipment if loadout.is_empty() else loadout
	var class_info: Dictionary = CLASS_DATA[character_class]
	var base: Dictionary = class_info.base
	var attributes: Dictionary = {}
	var level_gain := maxi(0, player_level - 1)
	for attribute in ATTRIBUTES:
		var value := int(base[attribute]) + level_gain + int(allocated_attributes.get(attribute, 0))
		for item in equipped.values():
			value += int(item.get("stats", {}).get(attribute, 0))
		attributes[attribute] = value
	var primary := String(class_info.primary)
	var primary_value := int(attributes[primary])
	var weapon_power := int(equipped["Weapon"].get("power", 0))
	var armor := 0
	var gear_power := 0
	var gear_crit := 0.0
	for item in equipped.values():
		armor += int(item.get("armor", 0))
		gear_power += int(item.get("power", 0))
		gear_crit += float(item.get("stats", {}).get("Crit", 0))
	if character_class == "Vowkeeper": armor = int(float(armor) * 1.2)
	var attack := 52 + weapon_power + primary_value * 5
	var max_hp := 100 + int(attributes.Vitality) * 14
	if character_class == "Vowkeeper": max_hp = int(float(max_hp) * 1.2)
	var max_mana := 45 + int(attributes.Spirit) * 9 + int(attributes.Intellect) * 3
	var crit_scale := 0.35
	if character_class == "Ranger":
		crit_scale = 0.65
	var crit := clampf(float(attributes.Dexterity) * crit_scale + gear_crit,0.0,100.0)
	var rank := _ability_rank(primary_value)
	var ability_damage := 0
	var mana_cost := 0
	var class_mitigation := 0
	match character_class:
		"Arcanist":
			ability_damage = int((attack * (1.28 + float(rank) * 0.18) + primary_value * 7) * 1.3)
			mana_cost = 19 + rank * 3
		"Ranger":
			ability_damage = int(attack * (1.16 + float(rank) * 0.14) + primary_value * 6)
			mana_cost = 14 + rank * 2
		_: # Vowkeeper trades burst for staying power.
			ability_damage = int(attack * (1.05 + float(rank) * 0.12) + primary_value * 6 + int(attributes.Vitality) * 2)
			mana_cost = 12 + rank * 2
			class_mitigation = int(attributes.Vitality / 18)
	var relic := Relics.effect(equipped.get("Amulet",{}),character_class)
	var power := attack + armor * 2 + int(attributes.Intellect) * 3 + int(attributes.Vitality) * 2
	var values := {"attributes": attributes, "attack": attack, "max_hp": max_hp, "max_mana": max_mana, "armor": armor, "crit": crit, "ability_damage": ability_damage, "mana_cost": mana_cost, "class_mitigation": class_mitigation, "mana_guard":0.35 if character_class=="Arcanist" else 0.0, "combat_stance":Stances.normalize(combat_stances.get(character_class)), "skill_rotation":1, "skill_loadout":Skills.normalize(character_class,skill_loadouts.get(character_class)), "dungeon_journey":1, "dungeon_generation":6, "route_pattern_version":4, "auto_target_variance":1, "boss_patterns":1, "arcane_tactics":1 if character_class=="Arcanist" else 0, "power": power, "gear_power": gear_power}

	if not relic.is_empty(): values.class_relic=relic
	var active_set:=RegionalSets.active(equipped)
	if active_set>=0:
		values.regional_set=active_set
		if active_set==1: values.mana_cost=maxi(1,int(values.mana_cost*0.8))
	return values

func _hero_power() -> int:
	return int(_combat_stats().power)

func _ability_rank(primary_value: int) -> int:
	return clampi(1 + floori(float(primary_value) / 15.0), 1, 10)

func _attribute_short(attribute: String) -> String:
	match attribute:
		"Strength": return "STR"
		"Dexterity": return "DEX"
		"Intellect": return "INT"
		"Vitality": return "VIT"
		_: return "SPI"

func _item_stats_line(item: Dictionary) -> String:
	var parts: Array[String] = []
	var stats: Dictionary = item.get("stats", {})
	for attribute in ATTRIBUTES:
		if int(stats.get(attribute, 0)) > 0:
			parts.append("+%d %s" % [int(stats[attribute]), _attribute_short(attribute)])
	if int(stats.get("Crit", 0)) > 0:
		parts.append("+%d%% CRIT" % int(stats["Crit"]))
	if parts.is_empty():
		return "No attribute bonus"
	var result := ""
	for part in parts:
		result += ("  •  " if not result.is_empty() else "") + part
	return result

func _quality_color(quality: String) -> Color:
	return QUALITY_COLORS.get(quality, QUALITY_COLORS.COMMON)

func _quality_label(quality: String) -> String:
	match quality:
		"UNCOMMON": return "UNCOMMON"
		"RARE": return "RARE"
		"EPIC": return "EPIC"
		"LEGENDARY": return "LEGENDARY"
		_: return "COMMON"

func _gear_tier() -> int:
	return _gear_tier_at_floor(floor_number)

func _gear_tier_at_floor(target_floor: int) -> int:
	return clampi(int(floor(float(target_floor - 1) / 10.0)) + 1, 1, 10)

func _slot_glyph(slot: String) -> Control:
	var glyph:=UiGlyph.new()
	glyph.name="SlotGlyph_"+slot
	glyph.key=slot.to_lower()
	glyph.ink=GOLD
	glyph.custom_minimum_size=Vector2(28,32)
	glyph.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	return glyph

func _ink_ground(horizontal: int, vertical: int) -> PanelContainer:
	var panel:=PanelContainer.new()
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("101318")
	style.content_margin_left=horizontal
	style.content_margin_right=horizontal
	style.content_margin_top=vertical
	style.content_margin_bottom=vertical
	style.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel",style)
	return panel

func _short_number(value: int) -> String:
	if value >= 1000000:
		return "%.1fm" % (float(value) / 1000000.0)
	if value >= 1000:
		return "%.1fk" % (float(value) / 1000.0)
	return str(value)

func _navigate(destination: String) -> void:
	if offline_job!=null: return
	if page == "run" and destination != "run":
		return
	cleanup_preview.clear()
	if bag_view=="cleanup": bag_view="all"
	page = destination
	_build_ui()

func _select_class(class_key: String) -> void:
	if offline_job!=null: return
	if not CLASS_DATA.has(class_key):
		return
	if character_class!=class_key:
		_end_offline_repeat()
		_refund_attributes()
	character_class = class_key
	_save_progress()
	_build_ui()

func _allocate_attribute(attribute: String) -> void:
	if offline_job!=null: return
	if attribute_points <= 0 or not ATTRIBUTES.has(attribute):
		return
	_end_offline_repeat()
	allocated_attributes[attribute] = int(allocated_attributes.get(attribute, 0)) + 1
	attribute_points -= 1
	_save_progress()
	_build_ui()

func _start_run(target_floor: int = -1, rules: Dictionary = {}) -> void:
	if offline_job!=null: return
	if not rules.is_empty() and not Contract.valid(rules,target_floor): return
	_end_offline_repeat()
	if Contract.mode(rules)=="trial": auto_repeat=false
	if Contract.mode(rules)=="oath" and rules.get("version")==2:
		_note_playtest("first_oath_started",0.0)
	onboarding_complete = true
	page = "run"
	combat_details_open=false
	details_resume_run=false
	inspected_skill="signature"
	run_floor = target_floor if Contract.mode(rules)=="trial" else clampi(floor_number if target_floor<1 else target_floor,1,maxi(1,floor_number))
	run_active = true
	run_stage = 0
	run_succeeded = false
	run_boss_defeated = false
	run_loot.clear()
	run_reward.clear()
	run_events = ["Nyra enters %s." % String(_region_data(run_floor).dungeon)]
	expedition = _new_expedition(run_floor,expedition_serial,rules)
	expedition_serial += 1
	_sync_model_state()
	finish_pending = false
	last_combat_save = 0.0
	_save_progress()
	_build_ui()

func _new_expedition(target_floor: int, serial: int, rules: Dictionary = {}) -> RefCounted:
	var simulation := Expedition.new()
	var values:=_expedition_stats(target_floor,rules)
	simulation.setup(character_class,values,target_floor,String(_region_data(target_floor).boss),_run_seed_for_serial(serial))
	return simulation

func _new_profile_seed() -> int:
	return randi_range(1,MAX_PROFILE_SEED)

func _run_seed_for_serial(serial: int) -> int:
	if world_seed<=0 or world_seed>MAX_PROFILE_SEED:
		world_seed=_new_profile_seed()
	# Every save gets its own deterministic sequence. Serial and profile seed both
	# contribute to the full loot seed; layout selection remains a reproducible bank.
	return OfflineFarm.seed_for_serial(world_seed,serial)

func _sync_model_state() -> void:
	run_stage = mini(expedition.stage,run_max_stages)
	run_health = expedition.hero_hp
	run_mana = expedition.hero_mana
	var target: Dictionary = expedition.enemy_by_id(expedition.target_id)
	if target.is_empty() or target.hp<=0:
		var alive: Array = expedition.living()
		target = alive[0] if not alive.is_empty() else {}
	current_enemy = String(target.get("name","Area cleared"))
	enemy_health = int(target.get("hp",0))
	enemy_max_health = int(target.get("max_hp",1))

func _on_combat_advanced(updates: Array) -> void:
	if page!="run" or finish_pending: return
	_sync_model_state()
	if is_instance_valid(audio): audio.combat_events(updates,character_class)
	for event in updates:
		if event.type=="boss_phase":
			_note_playtest("first_boss_phase",expedition.elapsed)
		if event.type=="hit":
			_note_playtest("first_hit",expedition.elapsed)
		if event.type=="hero_attack" and event.get("skill",false) and not event.has("ability_id"):
			_note_playtest("first_signature",expedition.elapsed)
		if event.type=="hit":
			run_events.append("%s hits for %d." % [event.name,event.damage])
			if run_events.size()>8: run_events.pop_front()
	if expedition.finished:
		if expedition.won:
			run_boss_defeated = true
			_complete_run()
		else: _fail_run()
		return
	_sync_combat_hud()
	if expedition.elapsed-last_combat_save>=5.0:
		last_combat_save = expedition.elapsed
		_save_progress()

func _skip_run() -> void:
	if page!="run" or finish_pending: return
	auto_repeat = false
	skipping_run = true
	expedition.simulate_to_end()
	_sync_model_state()
	if expedition.won:
		run_boss_defeated = true
		_complete_run()
	else: _fail_run()
	skipping_run = false

func _toggle_repeat() -> void:
	if finish_pending or (expedition!=null and Contract.mode(expedition.contract())=="trial"): return
	auto_repeat = not auto_repeat
	_save_progress()
	_sync_combat_hud()

func _set_farm_floor(change: int) -> void:
	_accrue_offline_time(OS.has_feature("android"))
	idle_progress_seconds=0
	offline_repeat_rules={}
	farm_floor = clampi(farm_floor+change,1,maxi(1,floor_number-1))
	_save_progress()
	_build_ui()

func _start_farming() -> void:
	auto_repeat = true
	_start_run(farm_floor,_farm_contract())

func _toggle_run_pause() -> void:
	if finish_pending: return
	if combat_details_open:
		details_resume_run=true
		_toggle_combat_details()
		return
	run_active = not run_active
	if is_instance_valid(run_arena):
		run_arena.animation_enabled = run_active
	combat_hud.state.text = "PAUSED" if not run_active else "AUTO • RESUMING"
	_sync_combat_hud()
	_save_progress()

func _toggle_farm() -> void:
	if offline_job!=null: return
	farm_enabled = not farm_enabled
	if not farm_enabled:
		idle_progress_seconds = 0
	_save_progress()
	_build_ui()

func _grant_expedition_rewards(success: bool, target_floor: int, offline: bool, seed_value: int, loot_class: String="", rules: Dictionary={}) -> void:
	var mode:=Contract.mode(rules)
	var first_relic:=success and target_floor==1 and mode in ["campaign","oath"] and not first_relic_claimed
	var first_trial:=success and mode=="trial" and int(rules.tier)==trial_cleared+1
	if mode=="trial" and not first_trial:
		if not offline: run_reward={"gold":0,"xp":0,"title":Contract.title(rules),"note":"No reward: clear the next trial within 150 seconds."}
		if offline and not success: pending_idle_fails+=1
		return
	var gold := 186+target_floor*4 if success else 55
	var xp := 420+target_floor*8 if success else 100
	if first_trial:
		gold+=500+int(rules.tier)*40
		xp+=500+int(rules.tier)*50
	if success and mode=="oath":
		gold=int(gold*Contract.reward_multiplier(rules))
		xp=int(xp*Contract.reward_multiplier(rules))
	if success:
		var loot_rng := RandomNumberGenerator.new()
		loot_rng.seed = seed_value+7919
		var drop_count := 1 if loot_rng.randf()<0.68 else 2
		if first_trial: drop_count=1
		if mode=="oath": drop_count+=Contract.bonus_drop_count(rules)
		for i in range(drop_count):
			var item := _generate_item(true,target_floor,loot_rng,loot_class,String(rules.get("slot","")),"EPIC" if first_trial else "")
			if (first_relic or Contract.guarantees_class_relic(rules)) and i==0:
				var earned_class:=character_class if loot_class.is_empty() else loot_class
				item=ClassLoot.roll(earned_class,true,_gear_tier_at_floor(target_floor),loot_rng,"Amulet","EPIC" if Contract.guarantees_class_relic(rules) else "RARE")
				item=Relics.attune(item,earned_class)
			item.region=_region_index(target_floor)
			if first_relic and i==0 and inventory.size()>=MAX_BAG_SIZE:
				var cheapest: Dictionary={}
				for stored_item in inventory:
					if stored_item.get("locked",false): continue
					if cheapest.is_empty() or int(stored_item.sell)<int(cheapest.sell): cheapest=stored_item
				if cheapest.is_empty():
					pending_class_relic=item
					continue
				inventory.erase(cheapest)
				cheapest.status="sold"
				gold+=int(cheapest.sell)
				if offline: pending_idle_salvaged+=1
			if inventory.size()<MAX_BAG_SIZE:
				inventory.append(item)
				if offline: pending_idle_gear += 1
				else: run_loot.append(item)
			else:
				gold += int(item.sell)
				if offline: pending_idle_salvaged += 1
		if first_relic: first_relic_claimed=true
		if mode in ["campaign","oath"]:
			var region_id:=_region_index(target_floor)
			if region_id not in guardian_trophies: guardian_trophies.append(region_id)
		if mode in ["campaign","oath"]: floor_number = maxi(floor_number,target_floor+1)
		if first_trial: trial_cleared=int(rules.tier)
	if not offline:
		run_reward={"gold":gold,"xp":xp,"title":Contract.title(rules),"note":"First clear • guaranteed Epic relic" if first_trial else "Focused drops • "+String(rules.slot) if mode=="hunt" else ""}
	if not offline and success:
		if first_relic: run_reward.note="Your first class relic • equip it to change your signature skill"
		elif mode=="oath": run_reward.note=Contract.describe(rules)
	if offline:
		pending_idle_ash += gold
		pending_idle_xp += xp
		if success: pending_idle_runs += 1
		else: pending_idle_fails += 1
	else:
		player_gold += gold
		_add_experience(xp)

func _complete_run() -> void:
	if page!="run": return
	run_active = false
	run_stage = run_max_stages
	run_succeeded = true
	last_run_floor = run_floor
	if not skipping_run: _note_playtest("first_clear",expedition.elapsed)
	run_loot.clear()
	_grant_expedition_rewards(true,run_floor,false,expedition.run_seed,expedition.class_key,expedition.contract())
	_stamp_run_report()
	_present_recovered_gear()
	page = "loot"
	_save_progress()
	_finish_run_presentation()

func _present_recovered_gear() -> void:
	if skipping_run or not run_succeeded or run_loot.is_empty() or not is_instance_valid(run_arena): return
	run_arena.world.show_recovered_gear(run_loot)

func _fail_run() -> void:
	if page!="run": return
	run_active = false
	auto_repeat = false
	run_succeeded = false
	last_run_floor = run_floor
	run_loot.clear()
	_grant_expedition_rewards(false,run_floor,false,expedition.run_seed,expedition.class_key,expedition.contract())
	_stamp_run_report()
	page = "loot"
	_save_progress()
	_finish_run_presentation()

func _finish_run_presentation() -> void:
	if is_instance_valid(audio): audio.cue("victory" if run_succeeded else "defeat")
	if skipping_run:
		_build_ui()
		return
	finish_pending = true
	if is_instance_valid(run_arena):
		if not run_succeeded:
			run_arena.world.hero.die()
	combat_hud.state.text = "DUNGEON CLEARED • COLLECTING LOOT" if run_succeeded else "EXPEDITION ENDED"
	get_tree().create_timer(2.2).timeout.connect(func():
		finish_pending = false
		if auto_repeat and run_succeeded:
			_start_run(run_floor,expedition.contract())
		else: _build_ui()
	)

func _generate_item(boss_bonus: bool = false, target_floor: int = -1, loot_rng: RandomNumberGenerator = null, loot_class: String="", focused_slot: String="", minimum_quality: String="") -> Dictionary:
	if loot_rng==null:
		loot_rng = RandomNumberGenerator.new()
		loot_rng.randomize()
	var drop_floor := floor_number if target_floor < 1 else target_floor
	var item:=ClassLoot.roll(character_class if loot_class.is_empty() else loot_class,boss_bonus,_gear_tier_at_floor(drop_floor),loot_rng,focused_slot,minimum_quality)
	item.region=_region_index(drop_floor)
	return item

func _equip_item(item: Dictionary) -> void:
	if offline_job!=null: return
	if not inventory.has(item):
		return
	_end_offline_repeat()
	var slot: String = item.slot
	var displaced: Dictionary = equipment[slot]
	displaced["slot"] = slot
	displaced["status"] = ""
	equipment[slot] = item
	if playtest_notes.has("first_clear") and not Relics.effect(item,character_class).is_empty(): _note_playtest("first_relic_equipped",float(run_reward.get("seconds",playtest_notes.get("first_clear",0.0))))
	item.status = "equipped"
	inventory.erase(item)
	inventory.append(displaced)
	_save_progress()
	_build_ui()

func _temper_equipment(slot: String) -> void:
	if offline_job!=null: return
	if not GEAR_SLOTS.has(slot) or not equipment.has(slot):
		return
	var item: Dictionary = equipment[slot]
	var rank := int(item.get("temper", 0))
	var cost := _temper_cost(item)
	if rank >= MAX_TEMPER_RANK or player_gold < cost:
		return
	_end_offline_repeat()
	player_gold -= cost
	var tier := int(item.get("tier", 1))
	item["temper"] = rank + 1
	item["power"] = int(item.get("power", 0)) + 8 + tier * 2
	var item_stats: Dictionary = item.get("stats", {}).duplicate(true)
	if ARMORED_SLOTS.has(slot):
		item["armor"] = int(item.get("armor", 0)) + 5 + tier * 2
		item_stats["Vitality"] = int(item_stats.get("Vitality", 0)) + 1
	else:
		var primary := String(CLASS_DATA[character_class].primary)
		item_stats[primary] = int(item_stats.get(primary, 0)) + 1
	item["stats"] = item_stats
	item["sell"] = int(item.get("sell", 0)) + int(float(cost) * 0.2)
	equipment[slot] = item
	_save_progress()
	_build_ui()

func _sell_item(item: Dictionary) -> void:
	if offline_job!=null: return
	if not inventory.has(item) or item.get("locked",false):
		return
	inventory.erase(item)
	player_gold += int(item.sell)
	item.status = "sold"
	_save_progress()
	_build_ui()

func _return_to_camp() -> void:
	page = "camp"
	_save_progress()
	_build_ui()

func _claim_idle_cache() -> void:
	player_gold += pending_idle_ash
	_add_experience(pending_idle_xp)
	pending_idle_ash = 0
	pending_idle_xp = 0
	pending_idle_runs = 0
	pending_idle_fails = 0
	pending_idle_gear = 0
	pending_idle_salvaged = 0
	_save_progress()
	_build_ui()

func _add_experience(amount: int) -> void:
	player_xp += amount
	while player_xp >= player_level * 1000:
		player_xp -= player_level * 1000
		player_level += 1
		attribute_points += 2

func _valid_offline_repeat(value: Variant, selected_class: String="") -> bool:
	if not value is Dictionary: return false
	if value.is_empty(): return true
	if value.size()!=2 or value.get("version")!=1 or not value.get("version") is int or not value.get("template") is String: return false
	var frozen:=Expedition.new()
	if not frozen.restore_encoded(value.template) or frozen.finished or frozen.elapsed!=0.0 or frozen.stage!=0: return false
	if not selected_class.is_empty() and frozen.class_key!=selected_class: return false
	if Contract.mode(frozen.contract())!="oath" or frozen.contract().get("version")!=2: return false
	if frozen.stats.get("oath_rules")!=1 or frozen.stats.get("boss_phases")!=1 or frozen.stats.has("relic_charge"): return false
	var fresh:=Expedition.new()
	fresh.setup(frozen.class_key,frozen.stats,frozen.floor_id,String(frozen.waves.back()[0].name),frozen.run_seed)
	return fresh.snapshot()==frozen.snapshot()

func _freeze_offline_repeat(current: RefCounted) -> void:
	var frozen:=Expedition.new()
	var values:Dictionary=current.stats.duplicate(true)
	# This is accumulated in-run state, not an equipped relic property.
	values.erase("relic_charge")
	frozen.setup(current.class_key,values,current.floor_id,String(current.waves.back()[0].name),current.run_seed)
	offline_repeat_rules={"version":1,"template":frozen.encode_snapshot()}

func _end_offline_repeat() -> void:
	if offline_repeat_rules.is_empty(): return
	_accrue_offline_time(false)
	offline_repeat_rules={}
	idle_progress_seconds=0

func _clear_offline_repeat() -> void:
	if offline_job!=null: return
	_end_offline_repeat()
	_save_progress()
	_build_ui()

func _offline_farm_context() -> Dictionary:
	if not offline_repeat_rules.is_empty() and _valid_offline_repeat(offline_repeat_rules,character_class):
		var frozen:=Expedition.new()
		frozen.restore_encoded(offline_repeat_rules.template)
		return {"class":frozen.class_key,"floor":frozen.floor_id,"stats":frozen.stats.duplicate(true),"contract":frozen.contract(),"boss":String(frozen.waves.back()[0].name)}
	return {"class":character_class,"floor":farm_floor,"stats":_expedition_stats(farm_floor,_farm_contract()),"contract":_farm_contract(),"boss":String(_region_data(farm_floor).boss)}

func _simulate_offline_time(available_seconds: int) -> void:
	var remaining:=mini(available_seconds,MAX_OFFLINE_SECONDS)
	var context:=_offline_farm_context()
	# Frozen build and rules share the same deterministic pattern cache as normal AFK.
	var outcomes:Dictionary={}
	while remaining>=30:
		var seed_value:=_run_seed_for_serial(expedition_serial)
		var pattern:=posmod(seed_value,Expedition.COMBAT_VARIANTS)
		if not outcomes.has(pattern):
			var simulation:=Expedition.new()
			simulation.setup(context["class"],context.stats,context.floor,context.boss,seed_value)
			simulation.simulate_to_end()
			outcomes[pattern]={"duration":maxi(30,ceili(simulation.elapsed)),"won":simulation.won}
		var outcome:Dictionary=outcomes[pattern]
		if outcome.duration>remaining: break
		remaining-=outcome.duration
		expedition_serial+=1
		_grant_expedition_rewards(outcome.won,context.floor,true,seed_value,context["class"],context.contract)
	idle_progress_seconds=remaining

func _accrue_offline_time(cooperative: bool=false) -> void:
	var now := int(clock_source.call())
	if last_saved_at<=0:
		last_saved_at = now
		return
	var away := clampi(now-last_saved_at,0,MAX_OFFLINE_SECONDS)
	if preferences.playtest and away>=86400: playtest_notes.returned_next_day=true
	last_saved_at = maxi(last_saved_at,now)
	if offline_job!=null:
		offline_job.remaining=mini(MAX_OFFLINE_SECONDS,offline_job.remaining+away)
		pending_afk_seconds=offline_job.remaining
		return
	if not farm_enabled:
		idle_progress_seconds = 0
		pending_afk_seconds = 0
		return
	if page=="run" and expedition!=null:
		# Pausing is persistent: no second copy of the same hero farms in parallel.
		if not _run_intends_progress(): return
		expedition.advance(float(away))
		_sync_model_state()
		if not expedition.finished: return
		var remaining := maxi(0,floori(expedition.accumulator+0.00001))
		last_run_floor = run_floor
		_grant_expedition_rewards(expedition.won,run_floor,true,expedition.run_seed,expedition.class_key,expedition.contract())
		if auto_repeat and expedition.won and Contract.mode(expedition.contract())!="trial":
			if Contract.mode(expedition.contract())=="oath" and expedition.contract().get("version")==2:
				_freeze_offline_repeat(expedition)
			else:
				farm_floor = run_floor
				farm_mode=Contract.mode(expedition.contract())
				if farm_mode=="hunt": hunt_slot=String(expedition.contract().slot)
		run_active = false
		auto_repeat = false
		page = "camp"
		expedition = null
		_reconcile_farm_time(mini(MAX_OFFLINE_SECONDS,idle_progress_seconds+remaining+pending_afk_seconds),cooperative)
		return
	_reconcile_farm_time(mini(MAX_OFFLINE_SECONDS,idle_progress_seconds+away+pending_afk_seconds),cooperative)

func _load_progress() -> void:
	page = "camp"
	expedition = null
	offline_job = null
	pending_afk_seconds = 0
	offline_repeat_rules = {}
	run_active = false
	auto_repeat = false
	finish_pending = false
	last_combat_save = 0.0
	var save: ConfigFile = save_store.load_save()
	save_notice = save_store.notice
	if save==null:
		world_seed = _new_profile_seed()
		last_saved_at = int(clock_source.call())
		return
	playtest_notes=PlaytestNotes.normalize(save.get_value("testing","notes",{}))
	preferences = Preferences.normalize(save.get_value("settings","preferences",preferences))
	skill_loadouts=Skills.normalize_book(save.get_value("hero","skill_loadouts",{}))
	combat_stances=Stances.normalize_book(save.get_value("hero","combat_stances",{}))
	first_relic_claimed=bool(save.get_value("hero","first_relic_claimed",int(save.get_value("hero","floor",1))>1))
	pending_class_relic={}
	var reserved: Variant=save.get_value("hero","pending_class_relic",{})
	if _valid_reserved_relic(reserved):
		pending_class_relic=_normalize_item(reserved,"Amulet")
		first_relic_claimed=true
	guardian_trophies=[]
	var saved_trophies: Variant=save.get_value("hero","guardian_trophies",[])
	if saved_trophies is Array:
		for trophy in saved_trophies:
			if trophy is int and trophy in range(REGIONS.size()) and trophy not in guardian_trophies: guardian_trophies.append(trophy)
	onboarding_complete = bool(save.get_value("hero","onboarding_complete",true))
	character_class = String(save.get_value("hero", "class", character_class))
	if not CLASS_DATA.has(character_class):
		character_class = "Vowkeeper"
	player_gold = int(save.get_value("hero", "gold", player_gold))
	player_shards = int(save.get_value("hero", "shards", player_shards))
	player_level = int(save.get_value("hero", "level", player_level))
	player_xp = int(save.get_value("hero", "xp", player_xp))
	attribute_points = int(save.get_value("hero", "attribute_points", attribute_points))
	allocated_attributes = save.get_value("hero", "allocated_attributes", allocated_attributes)
	floor_number = int(save.get_value("hero", "floor", floor_number))
	last_run_floor = int(save.get_value("hero", "last_run_floor", 0))
	var old_slot_names := {"Blade": "Weapon", "Cowl": "Helmet", "Mantle": "Chest", "Relic": "Amulet"}
	var saved_equipment: Dictionary = save.get_value("hero", "equipment", {})
	for old_slot in saved_equipment:
		var slot := String(old_slot_names.get(old_slot, old_slot))
		if GEAR_SLOTS.has(slot):
			equipment[slot] = _normalize_item(saved_equipment[old_slot], slot)
	var saved_inventory: Array = save.get_value("hero", "inventory", [])
	inventory.clear()
	for saved_item in saved_inventory:
		if saved_item is Dictionary:
			var normalized := _normalize_item(saved_item, String(old_slot_names.get(saved_item.get("slot", "Weapon"), saved_item.get("slot", "Weapon"))))
			if GEAR_SLOTS.has(normalized.slot) and inventory.size() < MAX_BAG_SIZE:
				inventory.append(normalized)
	pending_idle_ash = int(save.get_value("idle", "ash", 0))
	pending_idle_xp = int(save.get_value("idle", "xp", 0))
	pending_idle_runs = int(save.get_value("idle", "runs", 0))
	pending_idle_fails = int(save.get_value("idle", "fails", 0))
	pending_idle_gear = int(save.get_value("idle", "gear", 0))
	pending_idle_salvaged = int(save.get_value("idle", "salvaged", 0))
	idle_progress_seconds = int(save.get_value("idle", "progress_seconds", 0))
	idle_progress_seconds = clampi(idle_progress_seconds,0,int(Expedition.MAX_DURATION))
	var saved_pending: Variant=save.get_value("idle","reconcile_seconds",0)
	pending_afk_seconds=clampi(saved_pending,0,MAX_OFFLINE_SECONDS) if saved_pending is int else 0
	farm_floor = clampi(int(save.get_value("idle","farm_floor",1)),1,maxi(1,floor_number-1))
	farm_mode=String(save.get_value("idle","farm_mode","campaign"))
	if farm_mode not in ["campaign","hunt"] or floor_number<2: farm_mode="campaign"
	hunt_slot=String(save.get_value("idle","hunt_slot","Weapon"))
	if hunt_slot not in GEAR_SLOTS: hunt_slot="Weapon"
	var saved_repeat:Variant=save.get_value("idle","offline_repeat_rules",{})
	if _valid_offline_repeat(saved_repeat,character_class): offline_repeat_rules=saved_repeat.duplicate(true)
	trial_cleared=clampi(int(save.get_value("hero","trial_cleared",0)),0,Contract.MAX_TRIAL)
	expedition_serial = maxi(1,int(save.get_value("hero","expedition_serial",1)))
	var saved_world_seed: Variant=save.get_value("hero","world_seed") if save.has_section_key("hero","world_seed") else null
	world_seed=int(saved_world_seed) if saved_world_seed is int and saved_world_seed>0 and saved_world_seed<=MAX_PROFILE_SEED else _new_profile_seed()
	farm_enabled = bool(save.get_value("idle", "farm_enabled", farm_enabled))
	last_saved_at = int(save.get_value("idle", "saved_at", clock_source.call()))
	var run_data = save.get_value("run","snapshot","")
	if run_data is String and not run_data.is_empty():
		var restored := Expedition.new()
		if restored.restore_encoded(run_data) and not restored.finished and restored.class_key==character_class:
			expedition = restored
			run_floor = restored.floor_id
			run_active = bool(save.get_value("run","active",true))
			auto_repeat = bool(save.get_value("run","repeat",false)) and Contract.mode(restored.contract())!="trial"
			page = "run"
			_sync_model_state()
		else:
			save_notice = "The expedition checkpoint could not be restored. Your hero and equipment are intact."


func _normalize_item(item: Dictionary, default_slot: String) -> Dictionary:
	var normalized := item.duplicate(true)
	var saved_slot := String(normalized.get("slot", default_slot))
	var slot_aliases := {"Blade": "Weapon", "Cowl": "Helmet", "Mantle": "Chest", "Relic": "Amulet"}
	normalized["slot"] = String(slot_aliases.get(saved_slot, saved_slot))
	normalized["quality"] = String(normalized.get("quality", normalized.get("rarity", "COMMON")))
	normalized["tier"] = int(normalized.get("tier", 1))
	normalized["armor"] = int(normalized.get("armor", 0))
	normalized["stats"] = normalized.get("stats", {})
	normalized["sell"] = int(normalized.get("sell", 35))
	normalized["temper"] = clampi(int(normalized.get("temper", 0)), 0, MAX_TEMPER_RANK)
	if normalized.has("locked") and not normalized.locked is bool: normalized.erase("locked")
	return normalized

func _run_intends_progress() -> bool:
	# Inspection freezes the foreground scene, not an active hero's AFK intent.
	# Use the same intent for warm resume and a freshly loaded checkpoint.
	return run_active or (combat_details_open and details_resume_run)

func _build_save_payload() -> ConfigFile:
	var save := ConfigFile.new()
	save.set_value("settings","preferences",preferences)
	save.set_value("testing","notes",playtest_notes if preferences.playtest else {})
	save.set_value("hero","first_relic_claimed",first_relic_claimed)
	save.set_value("hero","pending_class_relic",pending_class_relic)
	save.set_value("hero","guardian_trophies",guardian_trophies)
	save.set_value("hero","onboarding_complete",onboarding_complete)
	save.set_value("hero", "class", character_class)
	save.set_value("hero","skill_loadouts",skill_loadouts)
	save.set_value("hero","combat_stances",combat_stances)
	save.set_value("hero","expedition_serial",expedition_serial)
	if world_seed<=0 or world_seed>MAX_PROFILE_SEED: world_seed=_new_profile_seed()
	save.set_value("hero","world_seed",world_seed)
	save.set_value("idle","farm_floor",farm_floor)
	save.set_value("idle","farm_mode",farm_mode)
	save.set_value("idle","offline_repeat_rules",offline_repeat_rules)
	save.set_value("idle","hunt_slot",hunt_slot)
	save.set_value("hero","trial_cleared",trial_cleared)
	save.set_value("hero", "gold", player_gold)
	save.set_value("hero", "shards", player_shards)
	save.set_value("hero", "level", player_level)
	save.set_value("hero", "xp", player_xp)
	save.set_value("hero", "attribute_points", attribute_points)
	save.set_value("hero", "allocated_attributes", allocated_attributes)
	save.set_value("hero", "floor", floor_number)
	save.set_value("hero", "last_run_floor", last_run_floor)
	save.set_value("hero", "equipment", equipment)
	save.set_value("hero", "inventory", inventory)
	save.set_value("idle", "ash", pending_idle_ash)
	save.set_value("idle", "xp", pending_idle_xp)
	save.set_value("idle", "runs", pending_idle_runs)
	save.set_value("idle", "fails", pending_idle_fails)
	save.set_value("idle", "gear", pending_idle_gear)
	save.set_value("idle", "salvaged", pending_idle_salvaged)
	save.set_value("idle", "progress_seconds", idle_progress_seconds)
	save.set_value("idle","reconcile_seconds",pending_afk_seconds)
	save.set_value("idle", "farm_enabled", farm_enabled)
	last_saved_at = maxi(last_saved_at,int(clock_source.call()))
	save.set_value("idle", "saved_at", last_saved_at)
	if page=="run" and expedition!=null and not expedition.finished:
		save.set_value("run","snapshot",expedition.encode_snapshot())
		# Reading temporarily stops live time; it preserves the player's run intent.
		save.set_value("run","active",_run_intends_progress())
		save.set_value("run","repeat",auto_repeat)
	return save

func _save_progress() -> void:
	var save:=_build_save_payload()
	var status: Error = save_store.save_game(save)
	last_save_ok = status==OK
	if status!=OK:
		save_notice = save_store.notice if not save_store.notice.is_empty() else "Progress could not be saved. Existing checkpoints are preserved. (%s)" % error_string(status)
		_show_save_notice()

func _create_backup_code() -> String:
	if save_store.write_blocked:
		save_notice="A backup cannot be made because this local save needs recovery."
		return ""
	var payload:=_build_save_payload()
	var status: Error=save_store.save_game(payload)
	if status!=OK:
		last_save_ok=false
		save_notice="Progress could not be saved, so no backup code was created."
		return ""
	last_save_ok=true
	var code:=save_store.create_backup_code(payload)
	if code.is_empty(): save_notice="This save is too large to export as a backup code."
	else: save_notice="Backup code ready. Copy it and keep it private."
	return code

func _restore_backup_code(code: String) -> bool:
	if page!="camp": return false
	var payload: ConfigFile=save_store.parse_backup_code(code)
	if payload==null:
		save_notice="That backup code is invalid, incomplete or damaged."
		return false
	if not _valid_backup_payload(payload):
		save_notice="That backup belongs to an incompatible or damaged save. Your current progress is unchanged."
		return false
	return _install_backup_payload(payload)

func _restore_local_recovery_copy() -> bool:
	if page!="camp" and not (page=="run" and not run_active): return false
	var payload: ConfigFile=save_store.load_recovery_copy()
	if payload==null or not _valid_backup_payload(payload):
		save_notice="No valid local recovery copy is available."
		return false
	return _install_backup_payload(payload)

func _install_backup_payload(payload: ConfigFile) -> bool:
	var status: Error=save_store.restore_backup(payload)
	if status!=OK:
		save_notice="The backup could not be installed. Your current progress is preserved."
		return false
	last_save_ok=true
	save_notice=save_store.notice
	return true

func _valid_backup_payload(save: ConfigFile) -> bool:
	if not save.has_section("hero") or not save.has_section("idle"): return false
	var reserved: Variant=save.get_value("hero","pending_class_relic",{})
	if not reserved is Dictionary: return false
	if not reserved.is_empty() and not _valid_reserved_relic(reserved): return false
	if not reserved.is_empty() and save.get_value("hero","first_relic_claimed",false)!=true: return false
	if save.has_section_key("hero","first_relic_claimed") and not save.get_value("hero","first_relic_claimed") is bool: return false
	if save.has_section_key("hero","guardian_trophies"):
		var trophies: Variant=save.get_value("hero","guardian_trophies")
		if not trophies is Array or trophies.size()>REGIONS.size(): return false
		for trophy in trophies:
			if not trophy is int or trophy not in range(REGIONS.size()): return false
	var saved_class: Variant=save.get_value("hero","class",null)
	if not saved_class is String or not CLASS_DATA.has(saved_class): return false
	var integer_fields: Array=[
		["hero","gold",0,2000000000],["hero","shards",0,2000000000],["hero","level",1,100000],
		["hero","xp",0,2000000000],["hero","attribute_points",0,2000000],["hero","floor",1,100000],
		["hero","last_run_floor",0,100000],["hero","expedition_serial",1,2000000000],["hero","trial_cleared",0,Contract.MAX_TRIAL],
		["idle","saved_at",0,5000000000],["idle","ash",0,2000000000],["idle","xp",0,2000000000],
		["idle","runs",0,2000000],["idle","fails",0,2000000],["idle","gear",0,2000000],
		["idle","salvaged",0,2000000],["idle","progress_seconds",0,int(Expedition.MAX_DURATION)],
		["idle","farm_floor",1,100000]
	]
	for field in integer_fields:
		var value: Variant=save.get_value(field[0],field[1],null)
		if not value is int or value<int(field[2]) or value>int(field[3]): return false
	if save.has_section_key("idle","reconcile_seconds"):
		var pending: Variant=save.get_value("idle","reconcile_seconds")
		if not pending is int or pending<0 or pending>MAX_OFFLINE_SECONDS: return false
	if save.has_section_key("hero","world_seed"):
		var saved_world_seed: Variant=save.get_value("hero","world_seed",null)
		if not saved_world_seed is int or saved_world_seed<1 or saved_world_seed>MAX_PROFILE_SEED: return false
	if not save.get_value("idle","farm_enabled",null) is bool: return false
	var mode: Variant=save.get_value("idle","farm_mode",null)
	var hunt_slot: Variant=save.get_value("idle","hunt_slot",null)
	if not mode is String or not mode in ["campaign","hunt"]: return false
	if not hunt_slot is String or not GEAR_SLOTS.has(hunt_slot): return false
	if not _valid_offline_repeat(save.get_value("idle","offline_repeat_rules",{}),saved_class): return false
	var attributes: Variant=save.get_value("hero","allocated_attributes",null)
	if not attributes is Dictionary: return false
	for key in ATTRIBUTES:
		var amount: Variant=attributes.get(key,0)
		if not amount is int or amount<0 or amount>1000000: return false
	var loadouts: Variant=save.get_value("hero","skill_loadouts",null)
	if not loadouts is Dictionary: return false
	if save.has_section_key("hero","combat_stances"):
		var stances: Variant=save.get_value("hero","combat_stances")
		if not stances is Dictionary: return false
		for key in stances:
			if not CLASS_DATA.has(key) or not Stances.valid(stances[key]): return false
	var preferences: Variant=save.get_value("settings","preferences",null)
	if not preferences is Dictionary: return false
	var equipment: Variant=save.get_value("hero","equipment",null)
	var inventory: Variant=save.get_value("hero","inventory",null)
	if not equipment is Dictionary or not inventory is Array or inventory.size()>MAX_BAG_SIZE: return false
	var aliases: Dictionary={"Blade":"Weapon","Cowl":"Helmet","Mantle":"Chest","Relic":"Amulet"}
	for slot in equipment:
		var normalized_slot: String=String(aliases.get(String(slot),String(slot)))
		if not GEAR_SLOTS.has(normalized_slot) or not _valid_backup_item(equipment[slot],normalized_slot): return false
	for item in inventory:
		if not _valid_backup_item(item,"Weapon"): return false
	if save.has_section("run"):
		var snapshot: Variant=save.get_value("run","snapshot","")
		if not snapshot is String: return false
		if not snapshot.is_empty():
			if not save.get_value("run","active",null) is bool or not save.get_value("run","repeat",null) is bool: return false
			var restored:=Expedition.new()
			if not restored.restore_encoded(snapshot) or restored.finished or restored.class_key!=saved_class: return false
	return true

func _valid_reserved_relic(value: Variant) -> bool:
	if not value is Dictionary or not _valid_backup_item(value,"Amulet"): return false
	if value.get("slot")!="Amulet" or not value.has("relic"): return false
	for key in ["name","quality","power","tier","armor","sell","stats"]:
		if not value.has(key): return false
	return not String(value.name).is_empty() and value.quality in QUALITY_ORDER

func _valid_backup_item(value: Variant,default_slot: String) -> bool:
	if not value is Dictionary: return false
	if value.has("locked") and not value.locked is bool: return false
	var item_slot: Variant=value.get("slot",default_slot)
	if not item_slot is String or not item_slot in GEAR_SLOTS: return false
	for key in ["power","tier","armor","sell","temper"]:
		if not value.has(key): continue
		var amount: Variant=value[key]
		if not (amount is int or amount is float) or not is_finite(float(amount)) or absf(float(amount))>2000000000.0: return false
	var item_stats: Variant=value.get("stats",{})
	if not item_stats is Dictionary: return false
	for key in item_stats:
		var amount: Variant=item_stats[key]
		if not (amount is int or amount is float) or not is_finite(float(amount)) or absf(float(amount))>1000000.0: return false
	if value.has("region") and (not value.region is int or value.region<0 or value.region>=4): return false
	if value.has("relic") and (not value.relic is String or not Relics.DEFINITIONS.has(value.relic) or item_slot!="Amulet"): return false
	for key in ["name","quality","status","affinity"]:
		if value.has(key) and not value[key] is String: return false
	return true


func _show_save_notice() -> void:
	if not is_inside_tree() or save_notice.is_empty(): return
	var previous := get_node_or_null("SaveNotice")
	if previous!=null:
		previous.queue_free()
		remove_child(previous)
	var toast := _panel(Color("171b21"),GOLD,10)
	toast.name = "SaveNotice"
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast.offset_left = -220
	toast.offset_right = 220
	toast.offset_top = 12
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	toast.add_child(row)
	var notice := _paragraph_label(save_notice,12,Color("ffd295"))
	notice.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(notice)
	var dismiss := _button("×",PANEL_LIGHT,18,func():
		save_notice = ""
		toast.queue_free()
	)
	dismiss.custom_minimum_size = Vector2(_minimum_button_height(48),_minimum_button_height(48))
	dismiss.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(dismiss)
	add_child(toast)

func _compare_item(item: Dictionary) -> Dictionary:
	var before:=_combat_stats()
	var proposed:=equipment.duplicate()
	proposed[item.slot]=item
	var after:=_combat_stats(proposed)
	var changes: Dictionary={}
	for key in ["attack","ability_damage","max_hp","armor","max_mana","crit","mana_cost"]:
		changes[key]=after[key]-before[key]
	return changes

func _update_forecast(label: Label,target_floor: int,farming: bool,rules: Dictionary={},stats_override: Dictionary={}) -> void:
	label.custom_minimum_size.y=44 if farming else 24
	var revision:=ui_revision
	var values:=_expedition_stats(target_floor,rules) if stats_override.is_empty() else stats_override.duplicate(true)
	var selected_class:=character_class
	var boss:=String(_region_data(target_floor).boss)
	var key:=selected_class+":"+str(target_floor)+":"+var_to_str(values)
	if offline_job!=null:
		label.text="Updating your offline expedition report…"
		return
	if forecast_cache.has(key):
		_display_forecast(label,forecast_cache[key],farming)
		return
	var owns_job:=not forecast_jobs.has(key)
	var assessment: RefCounted=Forecast.new() if owns_job else forecast_jobs[key]
	if owns_job:
		assessment.setup(selected_class,values,target_floor,boss)
		forecast_jobs[key]=assessment
	while not assessment.complete():
		await get_tree().process_frame
		if not is_inside_tree() or revision!=ui_revision or not is_instance_valid(label): return
		if owns_job: assessment.step_budget(6000)
	var result: Dictionary=assessment.summary()
	if forecast_cache.size()>16: forecast_cache.clear()
	forecast_cache[key]=result
	_display_forecast(label,result,farming)

func _display_forecast(label: Label,result: Dictionary,farming: bool) -> void:
	var percent:=int(round(result.rate*100.0))
	var verdict: String="RELIABLE" if result.rate>=0.95 else "RISKY" if result.rate>=0.5 else "TOO DIFFICULT"
	var shortest: int=result.shortest if farming else result.combat_shortest
	var longest: int=result.longest if farming else result.combat_longest
	var duration:=str(shortest) if shortest==longest else "%d–%d" % [shortest,longest]
	label.text="%s  •  %d%% clear rate  •  %ss / %s" % [verdict,percent,duration,"AFK cycle" if farming else "run"]
	if farming:
		label.text+="\nAbout %.1f clears / hour with your current gear." % result.clears_per_hour
		if result.rate<0.95: label.text+=" Choose a lower floor for steadier farming."
	label.add_theme_color_override("font_color",GREEN if result.rate>=0.95 else GOLD if result.rate>=0.5 else Color("dc9683"))
	if page=="camp": _position_camp_stations.call_deferred()

func _show_welcome() -> void:
	var overlay := Control.new()
	overlay.name="Welcome"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter=Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var shade:=ColorRect.new()
	shade.color=Color(0.015,0.02,0.03,0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var center:=CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var sheet:=_panel(Color("171b21"),GOLD,16)
	sheet.custom_minimum_size.x=710
	center.add_child(sheet)
	var stack:=VBoxContainer.new()
	stack.add_theme_constant_override("separation",12)
	sheet.add_child(stack)
	stack.add_child(_centered_label("CHOOSE YOUR HERO",22,PALE,true))
	stack.add_child(_centered_label("Your hero fights automatically. You choose the gear and the next expedition.",11,MUTED))
	var classes:=HBoxContainer.new()
	classes.add_theme_constant_override("separation",10)
	stack.add_child(classes)
	for key in CLASS_DATA:
		var info: Dictionary=CLASS_DATA[key]
		var card:=_panel(Color("28251f") if key==character_class else PANEL_LIGHT,info.color if key==character_class else EDGE,12)
		card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		card.custom_minimum_size.x=218
		classes.add_child(card)
		var column:=VBoxContainer.new()
		column.add_theme_constant_override("separation",8)
		card.add_child(column)
		column.add_child(_label(key.to_upper(),13,info.color,true))
		column.add_child(_paragraph_label(info.tagline,10,PALE))
		column.add_child(_paragraph_label({"Vowkeeper":"Ember Oath cleaves nearby enemies and restores Life. Guard softens incoming damage.","Arcanist":"Veil Nova bursts through groups. Mana Ward spends Mana to absorb damage.","Ranger":"Cinder Volley hits groups. Backsteps create distance from close enemies."}[key],10,MUTED))
		var space:=Control.new()
		space.size_flags_vertical=Control.SIZE_EXPAND_FILL
		column.add_child(space)
		column.add_child(_label("FOCUS: "+String(info.primary).to_upper(),9,GOLD))
		var choose:=_button("SELECTED" if key==character_class else "CHOOSE",Color("493b30") if key==character_class else PANEL,10,_choose_initial_class.bind(String(key)))
		choose.name="Choose"+String(key)
		column.add_child(choose)
	stack.add_child(_paragraph_label("Defeat the Bell Warden to earn your first class relic. Equip it to change your signature skill; choose tougher oaths after your first clear.",11,PALE))
	var actions:=HBoxContainer.new()
	actions.add_theme_constant_override("separation",12)
	stack.add_child(actions)
	var prepare:=_button("REVIEW GEAR FIRST",PANEL_LIGHT,11,_finish_welcome.bind(false))
	prepare.name="ReviewGear"
	actions.add_child(prepare)
	var begin:=_button("BEGIN FIRST EXPEDITION  →",RED,12,_finish_welcome.bind(true))
	begin.name="BeginExpedition"
	actions.add_child(begin)
	stack.add_child(_centered_label("You can change your class in the Armory. Your save stays on this device.",9,MUTED))

func _choose_initial_class(selected: String) -> void:
	character_class=selected
	_save_progress()
	_build_ui()
	_show_welcome()

func _finish_welcome(begin: bool) -> void:
	onboarding_complete=true
	_save_progress()
	if begin: _start_run(1)
	else:
		gear_tab="build"
		_navigate("gear")

func _select_gear_tab(selected: String) -> void:
	gear_tab=selected
	_build_ui()

func _open_build() -> void:
	gear_tab="build"
	_navigate("gear")

func _refund_attributes() -> void:
	for attribute in ATTRIBUTES:
		attribute_points+=int(allocated_attributes.get(attribute,0))
		allocated_attributes[attribute]=0

func _reset_attributes() -> void:
	if offline_job!=null: return
	_end_offline_repeat()
	_refund_attributes()
	_save_progress()
	_build_ui()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_handle_back()
		get_viewport().set_input_as_handled()

func _handle_back() -> void:
	if offline_job!=null:
		_save_progress()
		if last_save_ok: get_tree().quit()
		return
	# Android can deliver one press as both a key event and a window request.
	var frame:=Engine.get_process_frames()
	if last_back_frame==frame: return
	last_back_frame=frame
	if has_node("Options"):
		_close_settings()
	elif page=="gear" and gear_tab=="bag" and bag_view=="cleanup":
		_show_all_gear()
	elif has_node("Welcome"):
		return
	elif page=="run" and not combat_hud.is_empty() and combat_hud.hero_details.visible:
		_toggle_combat_details()
	elif page=="run" or page=="camp":
		_show_settings()
	else:
		_navigate("camp")

func _show_settings() -> void:
	if offline_job!=null: return
	if has_node("Options") or has_node("Welcome") or finish_pending: return
	menu_resume_run=page=="run" and run_active
	if menu_resume_run: _toggle_run_pause()
	var menu:=SettingsPanel.new()
	menu.name="Options"
	menu.game=self
	add_child(menu)

func _close_settings() -> void:
	var menu:=get_node_or_null("Options")
	if menu==null: return
	remove_child(menu)
	menu.queue_free()
	if menu_resume_run and page=="run" and not run_active: _toggle_run_pause()
	menu_resume_run=false
	_save_progress()

func _change_preference(key: String,value: Variant,persist: bool=true) -> void:
	if not preferences.has(key): return
	preferences[key]=value
	preferences=Preferences.normalize(preferences)
	_apply_preferences()
	if key=="large_text": _refresh_font_sizes(self)
	if persist: _save_progress()

func _apply_preferences() -> void:
	Engine.max_fps=30 if preferences.battery else 60
	if is_instance_valid(audio): audio.apply_preferences(preferences)
	if page=="run" and is_instance_valid(run_arena):
		run_arena.apply_quality(preferences.battery,preferences.numbers,preferences.reduced_motion)
	if is_instance_valid(camp_scene):
		camp_scene.apply_quality(preferences.battery,preferences.reduced_motion)
	for art in find_children("*","Control",true,false):
		if art.has_method("set_presentation"): art.set_presentation(preferences.reduced_motion,preferences.battery)

func _save_and_exit() -> void:
	# Opening options temporarily pauses; explicit exit preserves the prior intent.
	if menu_resume_run and page=="run": run_active=true
	_save_progress()
	if not last_save_ok:
		if menu_resume_run and page=="run": run_active=false
		_show_save_notice()
		return
	get_tree().quit()

func _build_skill_editor(parent: VBoxContainer) -> void:
	_build_stance_editor(parent)
	var loadout := Skills.normalize(character_class,skill_loadouts.get(character_class))
	var stats := _combat_stats()
	parent.add_child(_section_heading("AUTOMATIC SKILL ROTATION","2 TECHNIQUES + SIGNATURE"))
	parent.add_child(_paragraph_label("Equip two techniques for "+character_class+". Protection reacts to danger, while your signature and attacks follow their situation rules. The expedition seed varies eligible techniques and target choices without making the hero switch targets during a cooldown. Mana, range and cooldowns still apply.",11,MUTED))
	parent.add_child(_empty_note("ALWAYS EQUIPPED: "+String(CLASS_DATA[character_class].ability)+" • your class signature"))
	for key in Skills.choices(character_class):
		var definition: Dictionary=Skills.DEFINITIONS[key]
		var card := _panel(PANEL_LIGHT,Color(definition.color).darkened(0.5),12)
		card.name="TechniqueCard_"+key
		parent.add_child(card)
		var stack := VBoxContainer.new()
		stack.add_theme_constant_override("separation",6)
		card.add_child(stack)
		var title := HBoxContainer.new()
		stack.add_child(title)
		var glyph := preload("res://scripts/skill_glyph.gd").new()
		glyph.ability_id=key
		title.add_child(glyph)
		var name_label := _label(String(definition.name).to_upper(),14,Color(definition.color),true)
		name_label.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		title.add_child(name_label)
		var details: String="%s • %d Mana • %.1fs cooldown" % [definition.role,definition.cost,definition.cooldown]
		if float(definition.factor)>0.0: details+=" • %d base damage" % Skills.damage(key,stats)
		stack.add_child(_paragraph_label(details,10,PALE))
		stack.add_child(_paragraph_label(definition.rule,11,MUTED))
		var slots := HBoxContainer.new()
		slots.add_theme_constant_override("separation",8)
		stack.add_child(slots)
		for slot in range(2):
			var selected: bool=loadout[slot]==key
			var button := _button(("✓ SLOT " if selected else "EQUIP SLOT ")+("I" if slot==0 else "II"),Color("3c4c3d") if selected else PANEL,10,_equip_technique.bind(key,slot))
			button.name="EquipTechnique_"+key+"_"+str(slot)
			button.custom_minimum_size.y=_minimum_button_height(38)
			button.disabled=selected
			slots.add_child(button)

func _equip_technique(key: String, slot: int) -> void:
	if offline_job!=null: return
	if page=="run" or slot<0 or slot>1 or not key in Skills.choices(character_class): return
	var loadout := Skills.normalize(character_class,skill_loadouts.get(character_class))
	var old: String=loadout[slot]
	var other:=1-slot
	if loadout[other]==key: loadout[other]=old
	loadout[slot]=key
	_end_offline_repeat()
	skill_loadouts[character_class]=loadout
	_save_progress()
	_build_ui()

func _build_stance_editor(parent: VBoxContainer) -> void:
	parent.add_child(_section_heading("COMBAT STANCE","PREPARE YOUR NEXT RUN"))
	parent.add_child(_paragraph_label("Choose a stance for "+character_class+". It applies to new expeditions, hunts, trials and offline farming. A paused expedition keeps its original stance.",11,MUTED))
	var choices := HBoxContainer.new()
	choices.add_theme_constant_override("separation",8)
	parent.add_child(choices)
	var selected := Stances.normalize(combat_stances.get(character_class))
	for key in Stances.ORDER:
		var definition: Dictionary = Stances.DEFINITIONS[key]
		var button := _button(String(definition.name).to_upper(),Color("3c4c3d") if key==selected else PANEL,10,_select_combat_stance.bind(key))
		button.name = "CombatStance_"+key
		button.focus_mode = Control.FOCUS_ALL
		var focus := StyleBoxFlat.new()
		focus.bg_color = Color.TRANSPARENT
		focus.border_color = GOLD
		focus.set_border_width_all(2)
		focus.set_corner_radius_all(10)
		button.add_theme_stylebox_override("focus",focus)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = key==selected
		button.add_theme_color_override("font_disabled_color",Color(definition.color))
		button.tooltip_text = definition.description
		choices.add_child(button)
	parent.add_child(_paragraph_label(Stances.DEFINITIONS[selected].description,11,Color(Stances.DEFINITIONS[selected].color)))
	parent.add_child(_small_divider())

func _select_combat_stance(key: String) -> void:
	if offline_job!=null: return
	if page=="run" or not Stances.valid(key): return
	_end_offline_repeat()
	combat_stances[character_class] = key
	_save_progress()
	_build_ui()

func _farm_contract() -> Dictionary:
	return Contract.hunt(hunt_slot) if farm_mode=="hunt" else {}

func _select_world_tab(tab: String) -> void:
	world_tab=tab
	_build_ui()

func _open_hunts() -> void:
	world_tab="hunts"
	_navigate("map")

func _choose_farm_goal(slot: String) -> void:
	if page=="run" or (not slot.is_empty() and (floor_number<2 or slot not in GEAR_SLOTS)): return
	_accrue_offline_time(OS.has_feature("android"))
	idle_progress_seconds=0
	offline_repeat_rules={}
	farm_mode="campaign" if slot.is_empty() else "hunt"
	if not slot.is_empty(): hunt_slot=slot
	_save_progress()
	_build_ui()

func _start_trial() -> void:
	if floor_number<2 or trial_cleared>=Contract.MAX_TRIAL or page=="run": return
	var tier:=trial_cleared+1
	_start_run(Contract.trial_floor(tier),Contract.trial(tier))

func _build_hunts(parent: VBoxContainer) -> void:
	parent.add_child(_section_heading("TARGETED HUNTS","WATCHED + AFK"))
	parent.add_child(_paragraph_label("Choose the gear slot your build needs. Every recovered item uses that slot. Hunt enemies have 15% more Life and deal 8% more damage than the same campaign floor. Boss loot remains at least Rare.",12,PALE))
	if floor_number<2:
		parent.add_child(_empty_note("Clear campaign floor 1 to unlock targeted hunts."))
		return
	var grid:=GridContainer.new()
	grid.columns=2
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	parent.add_child(grid)
	for slot in GEAR_SLOTS:
		var selected: bool=farm_mode=="hunt" and hunt_slot==slot
		var choice:=_button(("✓ " if selected else "")+slot.to_upper(),Color("314b3c") if selected else PANEL_LIGHT,12,_choose_farm_goal.bind(slot))
		choice.name="HuntSlot_"+slot
		grid.add_child(choice)
	var broad:=_button("ALL GEAR • CAMPAIGN RULES",PANEL_LIGHT,11,_choose_farm_goal.bind(""))
	broad.name="HuntAllGear"
	parent.add_child(broad)
	parent.add_child(_label("CURRENT FARM: %s • FLOOR %02d" % [Contract.title(_farm_contract()),farm_floor],12,GREEN,true))
	parent.add_child(_paragraph_label(String(_region_data(farm_floor).dungeon)+" • T%d loot • this choice also applies while the app is closed." % _gear_tier_at_floor(farm_floor),11,MUTED))
	var forecast:=_paragraph_label("Assessing your chosen hunt…",11,MUTED)
	parent.add_child(forecast)
	_update_forecast(forecast,farm_floor,true,_farm_contract())
	var actions:=HBoxContainer.new()
	parent.add_child(actions)
	var previous:=_button("−",PANEL_LIGHT,14,_set_farm_floor.bind(-1))
	previous.disabled=farm_floor<=1
	actions.add_child(previous)
	var start:=_button("START SELECTED FARM",Color("314b3c"),12,_start_farming)
	start.name="StartHunt"
	actions.add_child(start)
	var next:=_button("+",PANEL_LIGHT,14,_set_farm_floor.bind(1))
	next.disabled=farm_floor>=maxi(1,floor_number-1)
	actions.add_child(next)

func _build_trials(parent: VBoxContainer) -> void:
	parent.add_child(_section_heading("ASH TRIALS","%d CLEARED" % trial_cleared))
	parent.add_child(_paragraph_label("Defeat the guardian and open the reliquary within 150 seconds. Enemies have 25% more Life and deal 15% more damage. Each trial grants its first-clear reward once. Trials do not advance the campaign or repeat automatically.",12,PALE))
	if floor_number<2:
		parent.add_child(_empty_note("Clear campaign floor 1 to open the trial gate."))
		return
	if trial_cleared>=Contract.MAX_TRIAL:
		parent.add_child(_empty_note("All current Ash Trials cleared."))
		return
	var tier:=trial_cleared+1
	var target:=Contract.trial_floor(tier)
	var card:=_panel(Color("272031"),Color("806393"),16)
	parent.add_child(card)
	var stack:=VBoxContainer.new()
	card.add_child(stack)
	stack.add_child(_label("ASH TRIAL %02d" % tier,22,Color("c5a3e6"),true))
	stack.add_child(_paragraph_label("%s • enemy floor %d • 150 seconds" % [String(_region_data(target).dungeon),target],12,PALE))
	stack.add_child(_paragraph_label("First clear: 1 Epic-or-better T%d relic • %d Gold • %d XP" % [_gear_tier_at_floor(target),186+target*4+500+tier*40,420+target*8+500+tier*50],12,GOLD,true))
	stack.add_child(_paragraph_label("A failed trial grants no loot, Gold or XP. Skip uses the same timer and combat. If you close the app with AFK enabled, this trial finishes once; your selected farm then resumes.",11,MUTED))
	var forecast:=_paragraph_label("Assessing the trial with your build…",11,MUTED)
	stack.add_child(forecast)
	_update_forecast(forecast,target,false,Contract.trial(tier))
	var start:=_button("ENTER ASH TRIAL",Color("614674"),13,_start_trial)
	start.name="StartTrial"
	stack.add_child(start)

func _reconcile_farm_time(seconds: int, cooperative: bool) -> void:
	if cooperative and seconds>=300:
		var context:=_offline_farm_context()
		offline_job=OfflineFarm.new()
		offline_job.setup(context["class"],context.stats,context.floor,context.boss,seconds,expedition_serial,world_seed)
		pending_afk_seconds=seconds
		idle_progress_seconds=0
		offline_checkpoint_clock=0.0
	else:
		pending_afk_seconds=0
		_simulate_offline_time(seconds)

func _process(delta: float) -> void:
	if offline_job==null: return
	var completed: Array=offline_job.step()
	for result in completed:
		_grant_expedition_rewards(result.won,offline_job.floor_id,true,result.seed,offline_job.class_key,offline_job.stats.get("expedition_contract",{}))
	expedition_serial=offline_job.serial
	pending_afk_seconds=offline_job.remaining
	offline_checkpoint_clock+=delta
	var progress := get_node_or_null("OfflineReconcile/Center/Panel/Content/Progress") as ProgressBar
	if progress!=null:
		progress.max_value=maxi(1,offline_job.total_seconds)
		progress.value=maxi(0,offline_job.total_seconds-offline_job.remaining)
	if offline_job.done:
		idle_progress_seconds=offline_job.remaining
		pending_afk_seconds=0
		offline_job=null
		_save_progress()
		_build_ui()
	elif offline_checkpoint_clock>=2.0:
		offline_checkpoint_clock=0.0
		_save_progress()

func _build_offline_loading() -> void:
	var overlay := Control.new()
	overlay.name="OfflineReconcile"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter=Control.MOUSE_FILTER_STOP
	add_child(overlay)
	get_viewport().gui_release_focus()
	var shade := ColorRect.new()
	shade.color=Color(0.02,0.025,0.03,0.94)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var center := CenterContainer.new()
	center.name="Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := _panel(PANEL,GOLD,12)
	panel.name="Panel"
	panel.custom_minimum_size.x=420
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.name="Content"
	content.add_theme_constant_override("separation",12)
	panel.add_child(content)
	content.add_child(_label("NYRA RETURNS FROM THE VEIL",20,PALE,true))
	content.add_child(_paragraph_label("Recovering your expeditions, relics and offline rewards. Your progress is saved as the report is prepared.",12,MUTED))
	var progress := _progress_bar(0,maxi(1,offline_job.total_seconds),GOLD,8)
	progress.name="Progress"
	content.add_child(progress)

func _unhandled_input(_event: InputEvent) -> void:
	if offline_job!=null: get_viewport().set_input_as_handled()

func _is_safe_upgrade(item: Dictionary) -> bool:
	if not item.get("slot","") in GEAR_SLOTS: return false
	if equipment[item.slot].get("locked",false): return false
	var candidate:=equipment.duplicate(true)
	candidate[String(item.get("slot","Weapon"))]=item
	var before_set:=RegionalSets.active(equipment)
	var after_set:=RegionalSets.active(candidate)
	if before_set>=0 and before_set!=after_set: return false
	if item.get("slot")=="Amulet" and Relics.effect(equipment.Amulet,character_class)!=Relics.effect(item,character_class): return false
	var changes := _compare_item(item)
	var before_stats:=_combat_stats()
	var after_stats:=_combat_stats(candidate)
	# Spirit governs Mana recovery on contact; a larger Mana pool alone can hide its loss.
	for attribute in ATTRIBUTES:
		if int(after_stats.attributes[attribute])<int(before_stats.attributes[attribute]): return false
	var improved := before_set<0 and after_set>=0
	for key in ["attack","ability_damage","max_hp","armor","max_mana","crit"]:
		if float(changes[key])<0.0: return false
		if float(changes[key])>0.0: improved=true
	return improved and int(changes.mana_cost)<=0

func _equip_recovered_upgrades() -> void:
	if page!="loot" or offline_job!=null: return
	# Reconcile the frozen oath repeat before changing the equipped build, as manual equip does.
	var has_upgrade:=false
	for item in run_loot:
		if inventory.has(item) and _is_safe_upgrade(item): has_upgrade=true; break
	if not has_upgrade: return
	_end_offline_repeat()
	for item in run_loot.duplicate():
		if not inventory.has(item) or not _is_safe_upgrade(item): continue
		var slot: String=item.slot
		var displaced: Dictionary=equipment[slot]
		displaced["slot"]=slot; displaced["status"]=""
		equipment[slot]=item
		item.status="equipped"
		inventory.erase(item)
		inventory.append(displaced)
	_save_progress()
	_build_ui()

func _stamp_run_report() -> void:
	run_reward.merge({"seconds":expedition.elapsed,"kills":expedition.kills,"casts":expedition.casts,"dodges":expedition.dodges})
	if not run_succeeded:
		run_reward.reached_room=mini(expedition.stage+1,expedition.waves.size())
		if expedition.stage==expedition.waves.size()-1:
			for enemy in expedition.waves.back():
				if enemy.role=="boss": run_reward.guardian_life=int(ceil(100.0*maxi(enemy.hp,0)/maxi(enemy.max_hp,1)))

func _continue_expedition() -> void:
	if page!="loot" or not run_succeeded or offline_job!=null: return
	var rules: Dictionary=expedition.contract() if expedition!=null else {}
	match Contract.mode(rules):
		"trial":
			if trial_cleared<Contract.MAX_TRIAL: _start_run(Contract.trial_floor(trial_cleared+1),Contract.trial(trial_cleared+1))
		"hunt": _start_run(last_run_floor,rules)
		_: _start_run(floor_number)

func _mobile_insets() -> Dictionary:
	if not OS.has_feature("android"): return {"left":0,"top":0,"right":0,"bottom":0}
	return MobileSafeArea.insets(DisplayServer.screen_get_size(),DisplayServer.get_display_safe_area(),get_viewport_rect().size)

func _build_first_steps(parent: VBoxContainer) -> void:
	var card := _panel(PANEL,EDGE,12)
	card.name="FirstSteps"
	parent.add_child(card)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation",6)
	card.add_child(content)
	content.add_child(_label("YOUR NEXT STEP",10,GOLD,true))
	if floor_number==1:
		content.add_child(_paragraph_label("Clear the first guardian above to open focused gear hunts and Ash Trials. Nyra fights and dodges automatically; your equipment decides how far she can go.",11,PALE))
	elif attribute_points>0:
		content.add_child(_paragraph_label("You earned %d attribute points. Spend them in Gear > Build. %s powers your class; Vitality improves survival." % [attribute_points,CLASS_DATA[character_class].primary],11,PALE))
		content.add_child(_button("PREPARE YOUR BUILD",PANEL_LIGHT,11,_open_build))
	else:
		content.add_child(_paragraph_label("Compare recovered gear in the Armory, then choose a reliable farm floor below. Focused Hunts let you work towards a specific gear slot while away.",11,PALE))
		content.add_child(_button("CHOOSE A GEAR HUNT",PANEL_LIGHT,11,_open_hunts))

func _build_oaths(parent: VBoxContainer) -> void:
	parent.add_child(_label("Expedition oaths",22,GOLD,true))
	parent.add_child(_paragraph_label("Choose one or two. Their risks and benefits apply to this expedition and its repeats; your camp farm keeps its chosen goal.",12,PALE))
	var choices:=HBoxContainer.new()
	choices.add_theme_constant_override("separation",8)
	parent.add_child(choices)
	for key in Contract.OATH_ORDER:
		var definition:Dictionary=Contract.OATHS[key]
		var selected:bool=key in selected_oaths
		var short_name:String={"unmended":"UNMENDED","cinder":"CINDERS","hollow":"HOLLOW"}[key]
		var button:=_button(short_name+(" · ON" if selected else ""),Color("493630") if selected else PANEL_LIGHT,14,_toggle_selected_oath.bind(String(key)))
		button.name="Oath"+String(key)
		button.disabled=selected_oaths.size()>=2 and not selected
		button.tooltip_text=String(definition.risk)+" "+String(definition.benefit)+" "+String(definition.reward)
		choices.add_child(button)
	var rules:=Contract.combine(selected_oaths)
	var start:=_button("DESCEND WITH %d OATH%s" % [selected_oaths.size(),"S" if selected_oaths.size()!=1 else ""],RED,14,_start_selected_oath)
	start.name="StartOathExpedition"
	start.disabled=rules.is_empty()
	parent.add_child(start)
	if rules.is_empty():
		parent.add_child(_paragraph_label("Unmended: no healing, Guard boosts damage. Cinders: stronger enemies and skills. Hollow: higher Mana costs, faster skills. Select an oath to review its exact rules.",12,MUTED))
		return
	for key in Contract.oath_keys(rules):
		var definition:Dictionary=Contract.OATHS[key]
		parent.add_child(_label(String(definition.name),15,GOLD,true))
		parent.add_child(_paragraph_label("Risk: "+String(definition.risk)+" "+String(definition.benefit)+" "+String(definition.reward),12,PALE))
	if selected_oaths.size()==2:
		parent.add_child(_paragraph_label("Both risks apply. Gold and XP add to +%d%%; each drop reward is awarded once." % roundi(Contract.gold_xp_bonus(rules)*100),12,GOLD))
	var synergy:=Contract.synergy_description(rules,character_class,_combat_stats())
	if not synergy.is_empty(): parent.add_child(_paragraph_label(synergy,12,GREEN))
	var forecast:=_paragraph_label("Assessing these oaths with your current build…",12,MUTED)
	parent.add_child(forecast)
	_update_forecast(forecast,floor_number,false,rules)

func _toggle_selected_oath(key: String) -> void:
	if offline_job!=null or page=="run" or key not in Contract.OATH_ORDER: return
	if key in selected_oaths: selected_oaths.erase(key)
	elif selected_oaths.size()<2: selected_oaths.append(key)
	_refresh_preserving_scroll()

func _start_selected_oath() -> void:
	if floor_number<2 or offline_job!=null: return
	var rules:=Contract.combine(selected_oaths)
	if rules.is_empty(): return
	_start_run(floor_number,rules)

func _build_journey_goal(parent: VBoxContainer) -> void:
	var target_floor:=(_region_index()+1)*10+1
	var copy:="Defeat the Bell Warden • earn a class relic that changes your signature skill." if not first_relic_claimed else "Next region: "+String(REGIONS[mini(_region_index()+1,REGIONS.size()-1)].dungeon)+" • opens at floor %02d." % target_floor
	if _region_index()==REGIONS.size()-1 and first_relic_claimed: copy="Next challenge: Ash Trial %02d • first clear earns an Epic relic." % mini(trial_cleared+1,Contract.MAX_TRIAL)
	parent.add_child(_paragraph_label(copy,11,GOLD,true))
	var active_set:=RegionalSets.active(equipment)
	if active_set>=0: parent.add_child(_paragraph_label("SET ACTIVE • "+RegionalSets.DEFINITIONS[active_set].name+" • "+RegionalSets.DEFINITIONS[active_set].rule,11,GREEN))
	else:
		var worn:=RegionalSets.counts(equipment)
		var closest:=_region_index()
		for region in range(worn.size()):
			if worn[region]>worn[closest]: closest=region
		parent.add_child(_paragraph_label("SET GOAL • %s • %d/3 worn. Review held pieces and prepare a hunt for a missing slot." % [RegionalSets.DEFINITIONS[closest].name,worn[closest]],11,GOLD))
	var sets:=_button("REVIEW SET GOALS",PANEL_LIGHT,11,_open_set_goals)
	sets.name="OpenSetGoals"
	parent.add_child(sets)
	if not guardian_trophies.is_empty():
		var names: PackedStringArray=[]
		for region_id in guardian_trophies: names.append(String(REGIONS[region_id].boss))
		parent.add_child(_paragraph_label("GUARDIAN SEALS %d/%d • " % [guardian_trophies.size(),REGIONS.size()]+" / ".join(names),10,MUTED))

func _note_playtest(key: String, seconds: float) -> void:
	if preferences.playtest and key in PlaytestNotes.MILESTONES and not playtest_notes.has(key): playtest_notes[key]=seconds

func _expedition_stats(target_floor: int, rules: Dictionary={}) -> Dictionary:
	var values:=_combat_stats()
	values.boss_phases=1
	if rules.get("version")==2 and Contract.mode(rules)=="oath": values.oath_rules=1
	if target_floor==1: values.first_descent=1
	if not rules.is_empty(): values.expedition_contract=rules.duplicate(true)
	return values

func _protection_button(item: Dictionary) -> Button:
	var button := _button("UNPROTECT" if item.get("locked",false) else "PROTECT", PANEL_LIGHT, 10, _toggle_item_protection.bind(item))
	button.name="ProtectItem"
	return button

func _toggle_item_protection(item: Dictionary) -> void:
	if offline_job!=null or (not inventory.has(item) and not equipment.values().has(item)): return
	item.locked=not item.get("locked",false)
	_save_progress()
	_refresh_preserving_scroll()

func _refresh_preserving_scroll() -> void:
	var scroll := find_child("PageScroll",true,false) as ScrollContainer
	var position := scroll.scroll_vertical if scroll!=null else 0
	_build_ui()
	var restored_scroll := find_child("PageScroll",true,false) as ScrollContainer
	if restored_scroll!=null: restored_scroll.set_deferred("scroll_vertical",position)

func _build_reserved_relic(parent: VBoxContainer) -> void:
	if pending_class_relic.is_empty(): return
	parent.add_child(_paragraph_label("Your first class relic is waiting: "+String(pending_class_relic.name)+". All satchel items were protected, so it was kept here for you.",11,GOLD,true))
	var claim := _button("COLLECT CLASS RELIC" if inventory.size()<MAX_BAG_SIZE else "FREE ONE SATCHEL SLOT TO COLLECT",PANEL_LIGHT,11,_claim_reserved_relic)
	claim.name="ClaimReservedRelic"
	claim.disabled=inventory.size()>=MAX_BAG_SIZE
	parent.add_child(claim)

func _claim_reserved_relic() -> void:
	if offline_job!=null or pending_class_relic.is_empty() or inventory.size()>=MAX_BAG_SIZE: return
	inventory.append(pending_class_relic)
	if page=="loot": run_loot.append(pending_class_relic)
	pending_class_relic={}
	_save_progress()
	_build_ui()

func _defeat_context() -> String:
	var copy := "This trial earned no rewards. Your existing equipment and progress are kept." if int(run_reward.get("gold",0))==0 and int(run_reward.get("xp",0))==0 else "Your recovered Gold and XP are kept."
	if run_reward.has("guardian_life"):
		copy+=" Guardian Life remaining: %d%%." % int(run_reward.guardian_life)
	elif run_reward.has("reached_room"):
		copy+=" Reached room %d of %d." % [run_reward.reached_room,run_max_stages]
	if expedition!=null and Contract.mode(expedition.contract())=="oath":
		copy+=" "+Contract.describe(expedition.contract())
	return copy

func _recovery_advice() -> Dictionary:
	if attribute_points>0:
		return {"action":"build", "caption":"SPEND %d ATTRIBUTE POINTS" % attribute_points, "copy":"You have %d unspent points. %s strengthens your class; Vitality adds Life. You can refund points freely." % [attribute_points,CLASS_DATA[character_class].primary]}
	for item in inventory:
		if _is_safe_upgrade(item):
			return {"action":"upgrades", "caption":"REVIEW SAFE UPGRADES", "copy":"Your satchel contains an upgrade with no combat-stat tradeoff. Compare it before the next attempt."}
	if Relics.effect(equipment.Amulet,character_class).is_empty():
		for item in inventory:
			if not Relics.effect(item,character_class).is_empty():
				return {"action":"class", "caption":"REVIEW CLASS RELIC", "copy":"A matching class relic is waiting in your satchel. Equip it to change your signature skill."}
	for slot in GEAR_SLOTS:
		var item: Dictionary=equipment[slot]
		if int(item.get("temper",0))<MAX_TEMPER_RANK and player_gold>=_temper_cost(item):
			return {"action":"equipment", "caption":"REVIEW EQUIPMENT", "copy":"You can temper your %s for %d Gold. Review the improvement in Gear > Equipment." % [slot.to_lower(),_temper_cost(item)]}
	return {"action":"build", "caption":"REVIEW CLASS & BUILD", "copy":"Review your class, attributes and skills before retrying. Changing class refunds allocated points, so you can try a different build."}

func _open_recovery_advice() -> void:
	if page!="loot" or run_succeeded or offline_job!=null: return
	var action: String=_recovery_advice().action
	if action in ["upgrades","class"]:
		gear_tab="bag"
		bag_slot="All"
		bag_view=action
	else: gear_tab=action
	_navigate("gear")

func _start_recovery_farm() -> void:
	if page!="loot" or run_succeeded or offline_job!=null or floor_number<=1 or last_run_floor<=1: return
	auto_repeat=true
	_start_run(mini(farm_floor,mini(floor_number-1,last_run_floor-1)))

func _gear_effect_changes(item: Dictionary) -> Array[Dictionary]:
	var changes: Array[Dictionary]=[]
	if item.get("slot","") not in GEAR_SLOTS: return changes
	var proposed:=equipment.duplicate()
	proposed[item.slot]=item
	var before_set:=RegionalSets.active(equipment)
	var after_set:=RegionalSets.active(proposed)
	if before_set!=after_set:
		if before_set>=0:
			changes.append({"copy":"SET LOST • "+RegionalSets.DEFINITIONS[before_set].name+": "+RegionalSets.DEFINITIONS[before_set].rule,"loss":true})
		if after_set>=0:
			changes.append({"copy":"SET ACTIVATED • "+RegionalSets.DEFINITIONS[after_set].name+": "+RegionalSets.DEFINITIONS[after_set].rule,"loss":false})
	var before_relic:=Relics.effect(equipment.Amulet,character_class)
	var after_relic:=Relics.effect(proposed.Amulet,character_class)
	if before_relic!=after_relic:
		if not before_relic.is_empty():
			changes.append({"copy":"SIGNATURE LOST • "+Relics.DEFINITIONS[before_relic].short,"loss":true})
		if not after_relic.is_empty():
			changes.append({"copy":"SIGNATURE ACTIVATED • "+Relics.DEFINITIONS[after_relic].short,"loss":false})
	return changes

func _open_set_goals() -> void:
	gear_tab="sets"
	_navigate("gear")

func _set_hunt_goal(region: int) -> Dictionary:
	if region<0 or region>=RegionalSets.DEFINITIONS.size(): return {}
	var missing:=RegionalSets.missing_slots(equipment,region)
	var held: Array[String]=[]
	for slot in missing:
		for item in inventory:
			if item.slot==slot and item.get("region",-1)==region:
				held.append(slot)
				break
	var target_slot:=""
	for slot in missing:
		if slot not in held: target_slot=slot; break
	# Start with the easiest cleared floor of the region; the hunt forecast shows its actual risk.
	var target_floor:=region*10+1
	return {"region":region,"worn":RegionalSets.counts(equipment)[region],"held":held,"slot":target_slot,"floor":target_floor,"unlocked":floor_number>target_floor}

func _build_set_progress(parent: VBoxContainer) -> void:
	parent.add_child(_section_heading("REGIONAL SETS","3 WORN PIECES"))
	parent.add_child(_paragraph_label("One set bonus can be active. The set with the most worn pieces wins; equal counts use region order. Bag items count only after equipping them.",12,PALE))
	var worn:=RegionalSets.counts(equipment)
	var active_set:=RegionalSets.active(equipment)
	for region in range(RegionalSets.DEFINITIONS.size()):
		var definition: Dictionary=RegionalSets.DEFINITIONS[region]
		var goal:=_set_hunt_goal(region)
		var card:=_panel(PANEL,Color("405347") if active_set==region else EDGE,13)
		parent.add_child(card)
		var stack:=VBoxContainer.new()
		stack.add_theme_constant_override("separation",6)
		card.add_child(stack)
		stack.add_child(_paragraph_label(String(definition.name)+" • %d/3 worn%s" % [worn[region]," • ACTIVE" if active_set==region else " • READY, OTHER SET ACTIVE" if worn[region]>=3 else ""],15,GREEN if active_set==region else GOLD,true))
		stack.add_child(_progress_bar(mini(3,worn[region]),3,GREEN,6))
		stack.add_child(_paragraph_label(definition.rule,12,PALE))
		stack.add_child(_paragraph_label(String(REGIONS[region].dungeon)+" • region %d" % (region+1),11,MUTED))
		if not goal.held.is_empty():
			stack.add_child(_paragraph_label("Already in your bag: "+", ".join(goal.held)+". Review their stat and effect tradeoffs before equipping.",11,GOLD))
			var review:=_button("REVIEW SET PIECES IN BAG",PANEL_LIGHT,11,_review_set_pieces.bind(region))
			review.name="ReviewSetPieces_"+str(region)
			stack.add_child(review)
		if worn[region]>=3: continue
		if not goal.unlocked:
			stack.add_child(_paragraph_label("Clear campaign floor %02d to unlock this region's hunts." % goal.floor,11,MUTED))
		elif not String(goal.slot).is_empty():
			stack.add_child(_paragraph_label("Next missing slot: %s • focused hunt on cleared floor %02d. Selecting this updates your watched and offline farm goal; review the forecast before starting." % [goal.slot,goal.floor],11,PALE))
			var hunt:=_button("PREPARE "+String(goal.slot).to_upper()+" HUNT",Color("314b3c"),11,_prepare_set_hunt.bind(region))
			hunt.name="PrepareSetHunt_"+str(region)
			stack.add_child(hunt)
	var back:=_button("RETURN TO EQUIPMENT",PANEL_LIGHT,12,_select_gear_tab.bind("equipment"))
	back.name="ReturnToEquipment"
	parent.add_child(back)

func _review_set_pieces(region: int) -> void:
	if offline_job!=null or page=="run" or region<0 or region>=RegionalSets.DEFINITIONS.size(): return
	bag_region=region
	bag_view="set"
	bag_slot="All"
	gear_tab="bag"
	_navigate("gear")

func _prepare_set_hunt(region: int) -> void:
	if offline_job!=null or page=="run": return
	var goal:=_set_hunt_goal(region)
	if goal.is_empty() or not goal.unlocked or goal.worn>=3 or String(goal.slot).is_empty(): return
	# Settle elapsed time under the old farm rules before changing the next farm goal.
	_accrue_offline_time(OS.has_feature("android"))
	while offline_job!=null: await get_tree().process_frame
	if page=="run": return
	goal=_set_hunt_goal(region)
	if goal.is_empty() or not goal.unlocked or goal.worn>=3 or String(goal.slot).is_empty(): return
	idle_progress_seconds=0
	offline_repeat_rules={}
	farm_floor=goal.floor
	farm_mode="hunt"
	hunt_slot=goal.slot
	world_tab="hunts"
	_save_progress()
	_navigate("map")

func _obsolete_gear() -> Array:
	return inventory.filter(func(item): return GearAdvisor.is_obsolete(item,equipment,character_class))

func _review_cleanup() -> void:
	if offline_job!=null or page!="gear" or gear_tab!="bag": return
	cleanup_preview.clear()
	cleanup_notice=""
	cleanup_class=character_class
	for item in _obsolete_gear():
		cleanup_preview.append({"item":item,"snapshot":item.duplicate(true)})
	bag_view="cleanup"
	_refresh_preserving_scroll()

func _build_cleanup_preview(parent: VBoxContainer) -> void:
	parent.add_child(_label("REVIEW DUPLICATE SALES",16,GOLD,true))
	parent.add_child(_paragraph_label("These items match the region of your equipped slot and have no stronger stats, tier or quality. Protected gear, class relics, Epic/Legendary items, tempered gear and other-class items are kept. This review covers the entire bag.",12,PALE))
	var total:=0
	for entry in cleanup_preview:
		var item: Dictionary=entry.snapshot
		total+=int(item.sell)
		parent.add_child(_paragraph_label("%s • %s • %d Gold" % [item.name,item.slot,item.sell],12,PALE))
	if cleanup_preview.is_empty(): parent.add_child(_empty_note("No duplicate gear is eligible for this sale."))
	var actions:=HBoxContainer.new()
	actions.add_theme_constant_override("separation",8)
	parent.add_child(actions)
	var confirm:=_button("SELL %d ITEM%s • +%d GOLD" % [cleanup_preview.size(),"" if cleanup_preview.size()==1 else "S",total],RED,12,_confirm_cleanup)
	confirm.name="ConfirmDuplicateSales"
	confirm.disabled=cleanup_preview.is_empty()
	actions.add_child(confirm)
	var cancel:=_button("KEEP GEAR & RETURN",PANEL_LIGHT,12,_show_all_gear)
	cancel.name="CancelDuplicateSales"
	actions.add_child(cancel)

func _confirm_cleanup() -> void:
	if offline_job!=null or page!="gear" or gear_tab!="bag" or bag_view!="cleanup" or cleanup_preview.is_empty(): return
	# All-or-nothing validation: a changed item or build requires a fresh review.
	var valid:=cleanup_class==character_class
	for entry in cleanup_preview:
		var still_present:=false
		for stored in inventory:
			if is_same(stored,entry.item): still_present=true; break
		valid=valid and still_present and entry.item==entry.snapshot and GearAdvisor.is_obsolete(entry.item,equipment,character_class)
	if not valid:
		cleanup_preview.clear()
		bag_view="all"
		cleanup_notice="Your gear changed. Nothing was sold; review duplicate sales again."
		_refresh_preserving_scroll()
		return
	var count:=cleanup_preview.size()
	var total:=0
	for entry in cleanup_preview:
		inventory.erase(entry.item)
		entry.item.status="sold"
		total+=int(entry.item.sell)
	player_gold+=total
	cleanup_preview.clear()
	bag_view="all"
	cleanup_notice="Sold %d reviewed duplicates for %d Gold. %d/%d satchel slots available." % [count,total,MAX_BAG_SIZE-inventory.size(),MAX_BAG_SIZE]
	_save_progress()
	_refresh_preserving_scroll()
