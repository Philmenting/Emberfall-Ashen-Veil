extends Control

const HeroArt = preload("res://scripts/hero_art.gd")
const BattleArt = preload("res://scripts/battle_art.gd")
const Expedition = preload("res://scripts/expedition_simulation.gd")
const Contract = preload("res://scripts/expedition_contract.gd")
const Skills = preload("res://scripts/class_skills.gd")
const Stances = preload("res://scripts/combat_stances.gd")
const BossPatterns = preload("res://scripts/boss_patterns.gd")
const ClassLoot = preload("res://scripts/class_loot.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const Forecast = preload("res://scripts/farm_forecast.gd")
const OfflineFarm = preload("res://scripts/offline_farm.gd")
const MobileSafeArea = preload("res://scripts/mobile_safe_area.gd")
const Preferences = preload("res://scripts/game_preferences.gd")
const AudioDirector = preload("res://scripts/audio_director.gd")
const SettingsPanel = preload("res://scripts/settings_panel.gd")

const BG_TOP := Color("201c20")
const BG_BOTTOM := Color("090d12")
const PANEL := Color("171b21")
const PANEL_LIGHT := Color("20252c")
const EDGE := Color("41434a")
const GOLD := Color("d2ad70")
const PALE := Color("e7dfd2")
const MUTED := Color("a09b95")
const RED := Color("9e4239")
const GREEN := Color("86ad91")

const ATTRIBUTES := ["Strength", "Dexterity", "Intellect", "Vitality", "Spirit"]
const GEAR_SLOTS := ["Weapon", "Helmet", "Chest", "Gloves", "Boots", "Amulet"]
const ARMORED_SLOTS := ["Helmet", "Chest", "Gloves", "Boots"]
const ENEMIES := ["Hollow Stalker", "Ashbound Warden", "Veilborn Shade", "Cinder Knight", "Grave Lantern"]
const REGIONS := [
	{"name": "The Veilworn Marches", "dungeon": "The Hollow Spire", "boss": "The Bell Warden", "description": "A broken watchtower where the lost still march.", "route": ["GATE", "GALLERY", "BELL TOWER", "HEART"]},
	{"name": "The Drowned Reaches", "dungeon": "The Sunken Archive", "boss": "The Silt Abbot", "description": "A flooded library whose drowned scribes still guard its sealed vaults.", "route": ["SHORE", "CRYPT", "SUNKEN HALL", "VAULT"]},
	{"name": "The Blackglass Frontier", "dungeon": "The Crow Ossuary", "boss": "The Mourning Queen", "description": "A glass desert split by old graves and a queen's unfinished lament.", "route": ["WASTES", "MIRROR PASS", "BONE GATE", "THRONE"]},
	{"name": "The Ashen Crown", "dungeon": "The Last Ember Citadel", "boss": "The Cinder Sovereign", "description": "The final citadel burns above a sea of ash and restless fire.", "route": ["OUTER WALL", "FURNACE", "CROWN ROAD", "CITADEL"]}
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

var page := "camp"
var gear_tab := "bag"
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
var finish_pending := false
var skipping_run := false
var backgrounded_at := 0
var save_store := SaveStore.new()
var save_notice := ""
var last_save_ok := true
var initialized := false
var onboarding_complete := false
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

func _build_ui() -> void:
	ui_revision += 1
	forecast_jobs.clear()
	for child in get_children():
		if child == audio: continue
		remove_child(child)
		child.queue_free()
	if is_instance_valid(audio): audio.set_context(page=="run")
	if page == "run":
		_build_run()
		_show_save_notice()
		return
	var margins := MarginContainer.new()
	var insets := _mobile_insets()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margins.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margins.add_theme_constant_override("margin_left", 18+int(insets.left))
	margins.add_theme_constant_override("margin_right", 18+int(insets.right))
	margins.add_theme_constant_override("margin_top", 13+int(insets.top))
	margins.add_theme_constant_override("margin_bottom", 11+int(insets.bottom))
	add_child(margins)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 5)
	margins.add_child(layout)
	layout.add_child(_build_header())
	layout.add_child(_build_title_row())
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	layout.add_child(body)
	if page!="loot": body.add_child(_build_hero_rail())
	var middle := VBoxContainer.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(middle)
	var scroll := ScrollContainer.new()
	scroll.name="PageScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	middle.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 9)
	scroll.add_child(content)
	match page:
		"camp": _build_camp(content)
		"gear": _build_gear(content)
		"map": _build_map(content)
		"loot": _build_loot(content)
	if page!="loot": body.add_child(_build_stats_rail())
	layout.add_child(_build_navigation())
	_show_save_notice()
	if offline_job!=null: _build_offline_loading()

func _build_header() -> Control:
	var bar := HBoxContainer.new()
	bar.custom_minimum_size.y = 36
	bar.add_theme_constant_override("separation", 7)
	bar.add_child(_label("✦", 21, GOLD, true))
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 0)
	stack.add_child(_label("EMBERFALL", 16, PALE, true))
	stack.add_child(_label("A S H E N   V E I L", 8, MUTED, true))
	bar.add_child(stack)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	bar.add_child(_resource_chip("◈", "%s GOLD" % _short_number(player_gold), GOLD))
	var options:=_button("OPTIONS",PANEL_LIGHT,10,_show_settings)
	options.name="OpenSettings"
	options.custom_minimum_size=Vector2(86,_minimum_button_height(48))
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
	var heading := _label(title, 13, GOLD, true)
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
	art.character_class = character_class
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

func _build_camp(parent: VBoxContainer) -> void:
	if pending_idle_runs>0 or pending_idle_fails>0 or pending_idle_ash>0 or pending_idle_xp>0: _build_idle_report(parent)
	var region := _region_data()
	var expedition := _panel(PANEL_LIGHT, Color("574039"), 17)
	parent.add_child(expedition)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 7)
	expedition.add_child(stack)
	var heading := HBoxContainer.new()
	heading.add_child(_label("NEXT EXPEDITION", 10, MUTED, true))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(spacer)
	heading.add_child(_label("FLOOR %02d" % floor_number,9,Color("b2a392"),true))
	stack.add_child(heading)
	stack.add_child(_label(String(region.dungeon).to_upper(), 22, PALE, true))
	stack.add_child(_paragraph_label(String(region.description),11,MUTED))
	var challenge := _paragraph_label("Assessing this floor with your current gear…",10,MUTED)
	stack.add_child(challenge)
	_update_forecast(challenge,floor_number,false)
	stack.add_child(_button("DESCEND TO FLOOR %02d   →" % floor_number, RED, 14, Callable(self, "_start_run")))
	if floor_number<=3: _build_first_steps(parent)
	var farm_panel := _panel(Color("19241f"),Color("405347"),14)
	parent.add_child(farm_panel)
	var farm_stack := VBoxContainer.new()
	farm_panel.add_child(farm_stack)
	farm_stack.add_child(_label("%s  •  FLOOR %02d" % [Contract.title(_farm_contract()),farm_floor],12,GREEN,true))
	farm_stack.add_child(_button("FARM GOAL: "+(hunt_slot.to_upper() if farm_mode=="hunt" else "ALL GEAR"),PANEL_LIGHT,11,_open_hunts))
	farm_stack.add_child(_paragraph_label("Choose a cleared floor. Repeat runs collect gear automatically and stop after a defeat. Offline farming uses this same floor and combat rules.",10,MUTED))
	var forecast := _paragraph_label("Assessing this floor with your current gear…",10,MUTED)
	farm_stack.add_child(forecast)
	_update_forecast(forecast,farm_floor,true,_farm_contract())
	var farm_actions := HBoxContainer.new()
	farm_stack.add_child(farm_actions)
	var previous := _button("−",PANEL_LIGHT,14,Callable(self,"_set_farm_floor").bind(-1))
	previous.disabled = farm_floor<=1
	farm_actions.add_child(previous)
	farm_actions.add_child(_button("START AUTO FARM",Color("314b3c"),11,Callable(self,"_start_farming")))
	var next := _button("+",PANEL_LIGHT,14,Callable(self,"_set_farm_floor").bind(1))
	next.disabled = farm_floor>=maxi(1,floor_number-1)
	farm_actions.add_child(next)
	var progress := _panel(PANEL, EDGE, 16)
	parent.add_child(progress)
	var progress_stack := VBoxContainer.new()
	progress_stack.add_theme_constant_override("separation", 4)
	progress.add_child(progress_stack)
	progress_stack.add_child(_label("RUN LOOP", 9, GOLD, true))
	progress_stack.add_child(_paragraph_label("Run duration depends on combat  •  24-hour AFK limit  •  overflow loot auto-sold", 11, PALE))
	if pending_idle_runs==0 and pending_idle_fails==0 and pending_idle_ash==0 and pending_idle_xp==0:
		var status := "ON — expeditions keep progressing while you are away." if farm_enabled else "OFF — offline time will not start dungeon runs."
		parent.add_child(_empty_note("AFK FARM %s" % status))

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
		tabs.add_child(_button(tab[1],Color("493b30") if gear_tab==tab[0] else PANEL_LIGHT,10,_select_gear_tab.bind(String(tab[0]))))
	match gear_tab:
		"build": _build_class_editor(parent)
		"skills": _build_skill_editor(parent)
		"equipment": _build_equipment_list(parent)
		_: _build_inventory_list(parent)

func _build_class_editor(parent: VBoxContainer) -> void:
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
	parent.add_child(_section_heading("EQUIPPED GEAR", "%d SLOTS  •  TEMPER UP TO +%d" % [GEAR_SLOTS.size(), MAX_TEMPER_RANK]))
	for slot in GEAR_SLOTS:
		parent.add_child(_equipped_row(slot, equipment[slot]))

func _build_inventory_list(parent: VBoxContainer) -> void:
	parent.add_child(_section_heading("SATCHEL", "%d / %d ITEMS" % [inventory.size(), MAX_BAG_SIZE]))
	if inventory.is_empty():
		parent.add_child(_empty_note("No spare gear. Clear a floor to find new equipment."))
	else:
		for item in inventory:
			parent.add_child(_item_card(item, true))

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
	var arena := BattleArt.new()
	arena.name = "BattleArena"
	arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena.character_class = character_class
	arena.region_index = _region_index(run_floor)
	arena.simulation = expedition
	arena.animation_enabled = run_active
	arena.battery_mode = preferences.battery
	arena.damage_numbers = preferences.numbers
	arena.reduced_motion = preferences.reduced_motion
	arena.simulation_advanced.connect(_on_combat_advanced)
	arena.state_changed.connect(_on_dungeon_state_changed)
	add_child(arena)
	run_arena = arena
	var safe := MarginContainer.new()
	var insets := _mobile_insets()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]:
		safe.add_theme_constant_override("margin_" + edge, 18+int(insets[edge]))
	safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(safe)
	var overlay := VBoxContainer.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe.add_child(overlay)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation",24)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(top)
	var hero_panel := _panel(Color(0.025,0.028,0.035,0.72),Color("756344"),4)
	hero_panel.custom_minimum_size.x = 160
	hero_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	hero_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.add_child(hero_panel)
	var hero_stack := VBoxContainer.new()
	hero_panel.add_child(hero_stack)
	hero_stack.add_child(_label("NYRA  /  LV. %d" % player_level,15,PALE,true))
	var hero_details := VBoxContainer.new()
	hero_details.name="HeroDetails"
	hero_details.visible=false
	hero_details.add_child(_label(character_class.to_upper(),10,GOLD,true))
	var stance: Dictionary = Stances.definition(expedition.stats)
	hero_details.add_child(_label(String(stance.name).to_upper()+" STANCE",9,Color(stance.color)))
	combat_hud.hp = _progress_bar(run_health,int(_combat_stats().max_hp),RED,9)
	hero_stack.add_child(combat_hud.hp)
	combat_hud.mana = _progress_bar(run_mana,int(_combat_stats().max_mana),Color("5f91c4"),5)
	hero_stack.add_child(combat_hud.mana)
	combat_hud.life = _label("",10,MUTED)
	hero_stack.add_child(combat_hud.life)
	combat_hud.skill = _label("",10,GOLD)
	hero_details.add_child(combat_hud.skill)
	if character_class=="Arcanist" and float(expedition.stats.get("mana_guard",0.0))>0.0:
		combat_hud.ward = _label("",9,Color("ac9bdc"))
		hero_details.add_child(combat_hud.ward)
	if expedition.uses_rotation():
		combat_hud.techniques={}
		for key in expedition.stats.skill_loadout:
			var status := _label("",9,Color(Skills.DEFINITIONS[key].color))
			status.name="TechniqueStatus_"+key
			hero_details.add_child(status)
			combat_hud.techniques[key]=status
		combat_hud.guard=_label("",9,GREEN)
		hero_details.add_child(combat_hud.guard)
	hero_stack.add_child(hero_details)
	combat_hud.hero_details=hero_details
	var top_gap := VBoxContainer.new()
	top_gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(top_gap)
	combat_hud.boss_panel=_panel(Color(0.025,0.028,0.035,0.86),Color("9e6553"),4)
	combat_hud.boss_panel.name="BossEncounter"
	combat_hud.boss_panel.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	combat_hud.boss_panel.custom_minimum_size.x=190
	top_gap.add_child(combat_hud.boss_panel)
	var boss_stack := VBoxContainer.new()
	combat_hud.boss_panel.add_child(boss_stack)
	combat_hud.boss_name=_centered_label("",13,PALE,true)
	boss_stack.add_child(combat_hud.boss_name)
	combat_hud.boss_hp=_progress_bar(0,1,Color("bd6048"),8)
	boss_stack.add_child(combat_hud.boss_hp)
	combat_hud.boss_life=_centered_label("",10,GOLD)
	boss_stack.add_child(combat_hud.boss_life)
	var objective_panel := _panel(Color(0.025,0.028,0.035,0.68),Color("756344"),4)
	objective_panel.custom_minimum_size.x = 200
	objective_panel.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	objective_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	top.add_child(objective_panel)
	var objective := VBoxContainer.new()
	objective_panel.add_child(objective)
	objective.add_child(_label(String(_region_data(run_floor).dungeon).to_upper(),13,GOLD,true))
	objective.add_child(_label("%s • FLOOR %02d" % [Contract.title(expedition.contract()),run_floor],8,MUTED,true))
	if Contract.mode(expedition.contract())=="trial":
		combat_hud.trial_clock=_label("",12,Color("c5a3e6"),true)
		combat_hud.trial_clock.name="TrialClock"
		objective.add_child(combat_hud.trial_clock)
	combat_hud.progress = _progress_bar(0,run_max_stages,GOLD,5)
	objective.add_child(combat_hud.progress)
	var route_details:=VBoxContainer.new()
	route_details.name="RouteDetails"
	route_details.visible=false
	combat_hud.route_details=route_details
	if expedition.uses_journey():
		var route_map := preload("res://scripts/expedition_map.gd").new()
		route_map.name="ExpeditionMap"
		route_map.simulation=expedition
		route_details.add_child(route_map)
		combat_hud.room = _label("",11,GOLD,true)
		objective.add_child(combat_hud.room)
		combat_hud.objective = _label("",10,MUTED)
		combat_hud.objective.custom_minimum_size.x=190
		combat_hud.objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		route_details.add_child(combat_hud.objective)
	combat_hud.encounter = _label("",11,PALE,true)
	objective.add_child(combat_hud.encounter)
	combat_hud.boss = _label("",10,Color("f3aa82"),true)
	boss_stack.add_child(combat_hud.boss)
	combat_hud.boss.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	combat_hud.boss.custom_minimum_size.x=190
	objective.add_child(route_details)
	var details:=_button("DETAILS",PANEL_LIGHT,10,_toggle_combat_details)
	details.name="CombatDetailsToggle"
	details.custom_minimum_size.y=_minimum_button_height(48)
	combat_hud.details=details
	objective.add_child(details)
	var options:=_button("OPTIONS / PAUSE",PANEL_LIGHT,9,_show_settings)
	options.name="OpenSettings"
	options.custom_minimum_size.y=_minimum_button_height(48)
	objective.add_child(options)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(spacer)
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_theme_constant_override("separation",12)
	overlay.add_child(bottom)
	var status_panel := _panel(Color(0.025,0.028,0.035,0.72),Color("756344"),4)
	status_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(status_panel)
	var status := VBoxContainer.new()
	status_panel.add_child(status)
	combat_hud.state = _label("AUTO • ENTERING THE DUNGEON",11,GOLD,true)
	combat_hud.state.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	status.add_child(combat_hud.state)
	combat_hud.enemy = _label("",11,PALE)
	status.add_child(combat_hud.enemy)
	combat_hud.enemy_hp = _progress_bar(enemy_health,enemy_max_health,RED,5)
	status.add_child(combat_hud.enemy_hp)
	combat_hud.pause = _button("Ⅱ  PAUSE",Color("26323b"),11,Callable(self,"_toggle_run_pause"))
	combat_hud.pause.custom_minimum_size = Vector2(112,_minimum_button_height(48))
	combat_hud.pause.size_flags_horizontal = Control.SIZE_SHRINK_END
	bottom.add_child(combat_hud.pause)
	combat_hud.repeat = _button("",Color("304638"),10,Callable(self,"_toggle_repeat"))
	combat_hud.repeat.custom_minimum_size = Vector2(110,_minimum_button_height(48))
	combat_hud.repeat.size_flags_horizontal = Control.SIZE_SHRINK_END
	bottom.add_child(combat_hud.repeat)
	var skip := _button("SKIP TO LOOT  »",Color("713c32"),11,Callable(self,"_skip_run"))
	skip.custom_minimum_size = Vector2(160,_minimum_button_height(48))
	skip.size_flags_horizontal = Control.SIZE_SHRINK_END
	bottom.add_child(skip)
	_sync_combat_hud()

func _toggle_combat_details() -> void:
	var expanded: bool=not combat_hud.hero_details.visible
	combat_hud.hero_details.visible=expanded
	combat_hud.route_details.visible=expanded
	combat_hud.details.text="HIDE DETAILS" if expanded else "DETAILS"
	combat_hud.details.tooltip_text="Hide character skills and route map" if expanded else "Show character skills and route map"

func _on_dungeon_state_changed(description: String) -> void:
	if combat_hud.has("state"):
		combat_hud.state.text = description

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
	combat_hud.life.text = "%d LIFE   /   %d MANA" % [run_health,run_mana]
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
			combat_hud.boss_life.text="%d%% LIFE" % ceili(100.0*guardian.hp/guardian.max_hp)
	if expedition.stage==5:
		var boss: Dictionary=expedition.enemy_by_id(50)
		if boss.get("hp",0)>0 and boss.has("awakened"):
			combat_hud.boss.visible=true
			combat_hud.boss.text="AWAKENED • STRONGER ATTACKS" if boss.awakened else "BOSS • WATCH THE GROUND"
			if boss.warning.has("zones"):
				combat_hud.boss.text="%s • %.1fs" % [String(boss.warning.name).to_upper(),maxf(0.0,boss.warning.left)]
	combat_hud.enemy.text = "%s  •  %d / %d" % [current_enemy,enemy_health,enemy_max_health]
	combat_hud.enemy_hp.max_value = enemy_max_health
	combat_hud.enemy_hp.value = enemy_health
	if expedition.uses_journey() and expedition.phase in ["interact","loot"]:
		combat_hud.enemy.text=expedition.action
		combat_hud.enemy_hp.max_value=1.2
		combat_hud.enemy_hp.value=expedition.journey.channel
	combat_hud.pause.text = "Ⅱ  PAUSE" if run_active else "▶  RESUME"
	combat_hud.repeat.text = "REPEAT: ON" if auto_repeat else "REPEAT: OFF"
	combat_hud.skill.text = "%s  /  %s" % [String(CLASS_DATA[character_class].ability),"READY" if expedition.skill_cd<=0 else "%.1fs" % expedition.skill_cd]
	if combat_hud.has("techniques"):
		for key in combat_hud.techniques:
			var definition: Dictionary=Skills.DEFINITIONS[key]
			var cooldown: float=expedition.rotation.cooldowns[key]
			var status: String="READY" if cooldown<=0.0 else "%.1fs" % cooldown
			if cooldown<=0.0 and expedition.hero_mana<int(definition.cost): status="LOW MANA"
			if expedition.pending_attack.get("ability_id","")==key: status="CASTING"
			combat_hud.techniques[key].text="%s / %s" % [definition.short,status]
		combat_hud.guard.text="GUARD • %.1fs" % expedition.guard_time if expedition.guard_time>0.0 else "AUTO ROTATION • 3 SKILLS"
	if combat_hud.has("ward"):
		combat_hud.ward.text = "WARD • %d MANA AVAILABLE" % maxi(0,expedition.hero_mana-int(expedition.stats.mana_cost))

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
	if not run_succeeded: stack.add_child(_paragraph_label("Your recovered Gold and XP are kept. Review your build or farm a cleared floor before trying again.",12,PALE))
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
		var review := _button("REVIEW CLASS & BUILD",RED,12,_open_build)
		review.name="ReviewDefeatedBuild"
		next.add_child(review)
	var camp := _button("RETURN TO CAMP",PANEL_LIGHT,11,_return_to_camp)
	camp.name="ReturnToCamp"
	next.add_child(camp)
	var safe_count := 0
	for item in run_loot:
		if inventory.has(item) and _is_safe_upgrade(item): safe_count+=1
	if safe_count>0:
		var equip := _button("EQUIP SAFE UPGRADES (%d)" % safe_count,Color("314b3c"),11,_equip_recovered_upgrades)
		equip.name="EquipRecoveredUpgrades"
		stack.add_child(equip)
		stack.add_child(_paragraph_label("Only equips relics that improve a combat stat without lowering another stat or increasing skill Mana cost. Displaced gear stays in your bag.",11,MUTED))
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
	var tray := _panel(Color(0.055, 0.060, 0.072, 0.97), Color("34373d"), 15)
	tray.custom_minimum_size.y = 46
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	tray.add_child(row)
	row.add_child(_nav_button("⌂", "CAMP", "camp"))
	row.add_child(_nav_button("⚒", "GEAR", "gear"))
	row.add_child(_nav_button("✥", "WORLD", "map"))
	return tray

func _nav_button(icon: String, caption: String, destination: String) -> Control:
	var button := Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.set_meta("emberfall_base_font_size",11)
	button.add_theme_font_size_override("font_size",_scaled_font_size(11))
	button.custom_minimum_size = Vector2(0,_minimum_button_height(40))
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.text = "%s   %s" % [icon, caption]
	button.add_theme_color_override("font_color", GOLD if page == destination else MUTED)
	button.pressed.connect(_navigate.bind(destination))
	return button

func _equipped_row(slot: String, item: Dictionary) -> Control:
	var row := _panel(PANEL, _quality_color(item.quality).darkened(0.45), 13)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	row.add_child(line)
	line.add_child(_centered_label(_slot_icon(slot), 19, _quality_color(item.quality)))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(_label("%s  •  T%d  •  +%d  •  %s" % [slot.to_upper(), item.tier, int(item.get("temper", 0)), _quality_label(item.quality)], 8, _quality_color(item.quality), true))
	info.add_child(_label(String(item.name), 12, PALE, true))
	if CLASS_DATA.has(String(item.get("affinity",""))): info.add_child(_label(String(item.affinity).to_upper()+" ATTUNEMENT",8,MUTED))
	info.add_child(_label(_item_stats_line(item), 9, MUTED))
	line.add_child(info)
	line.add_child(_label("ITEM %d" % int(item.power),10,GOLD,true))
	line.add_child(_temper_button(slot, item))
	return row

func _item_card(item: Dictionary, show_actions: bool) -> Control:
	var rarity := String(item.get("quality", "COMMON"))
	var card := _panel(PANEL, _quality_color(rarity).darkened(0.48), 13)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	card.add_child(stack)
	var top := HBoxContainer.new()
	top.add_child(_centered_label(_slot_icon(item.slot), 19, _quality_color(rarity)))
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(_label(String(item.name), 12, PALE, true))
	identity.add_child(_label("%s  •  T%d  •  +%d  •  %s" % [String(item.slot).to_upper(), int(item.tier), int(item.get("temper", 0)), _quality_label(rarity)], 8, _quality_color(rarity), true))
	if _is_safe_upgrade(item): identity.add_child(_label("UPGRADE • NO STAT TRADEOFF",9,GREEN,true))
	top.add_child(identity)
	top.add_child(_label("ITEM %d" % int(item.power),11,GOLD,true))
	stack.add_child(top)
	if CLASS_DATA.has(String(item.get("affinity",""))): stack.add_child(_paragraph_label(String(item.affinity).to_upper()+" ATTUNEMENT • Usable by all classes",8,MUTED))
	stack.add_child(_paragraph_label("%s  •  %d armor" % [_item_stats_line(item),int(item.armor)],9,MUTED))
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
		actions.add_child(_button("SELL  +%d" % int(item.sell), Color("402f2d"), 10, Callable(self, "_sell_item").bind(item)))
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
	button.custom_minimum_size = Vector2(0,_minimum_button_height(46))
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
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
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(func():
		if is_instance_valid(audio): audio.cue("ui")
	)
	button.pressed.connect(action)
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
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.25))
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
	return maxi(1,roundi(float(base_size)*scale))

func _minimum_button_height(base_size: int) -> int:
	var compact:=_compact_layout()
	var target:=base_size
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

func _progress_bar(value: float, maximum: float, color: Color, height: int) -> ProgressBar:
	var bar := ProgressBar.new()
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
	var power := attack + armor * 2 + int(attributes.Intellect) * 3 + int(attributes.Vitality) * 2
	return {"attributes": attributes, "attack": attack, "max_hp": max_hp, "max_mana": max_mana, "armor": armor, "crit": crit, "ability_damage": ability_damage, "mana_cost": mana_cost, "class_mitigation": class_mitigation, "mana_guard":0.35 if character_class=="Arcanist" else 0.0, "combat_stance":Stances.normalize(combat_stances.get(character_class)), "skill_rotation":1, "skill_loadout":Skills.normalize(character_class,skill_loadouts.get(character_class)), "dungeon_journey":1, "dungeon_generation":6, "route_pattern_version":4, "auto_target_variance":1, "boss_patterns":1, "arcane_tactics":1 if character_class=="Arcanist" else 0, "power": power, "gear_power": gear_power}

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

func _slot_icon(slot: String) -> String:
	match slot:
		"Weapon": return "⚔"
		"Helmet": return "◈"
		"Chest": return "◒"
		"Gloves": return "⌑"
		"Boots": return "⌁"
		_: return "✧"

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
	page = destination
	_build_ui()

func _select_class(class_key: String) -> void:
	if offline_job!=null: return
	if not CLASS_DATA.has(class_key):
		return
	if character_class!=class_key: _refund_attributes()
	character_class = class_key
	_save_progress()
	_build_ui()

func _allocate_attribute(attribute: String) -> void:
	if offline_job!=null: return
	if attribute_points <= 0 or not ATTRIBUTES.has(attribute):
		return
	allocated_attributes[attribute] = int(allocated_attributes.get(attribute, 0)) + 1
	attribute_points -= 1
	_save_progress()
	_build_ui()

func _start_run(target_floor: int = -1, rules: Dictionary = {}) -> void:
	if offline_job!=null: return
	if not rules.is_empty() and not Contract.valid(rules,target_floor): return
	if Contract.mode(rules)=="trial": auto_repeat=false
	onboarding_complete = true
	page = "run"
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
	var values:=_combat_stats()
	if not rules.is_empty(): values.expedition_contract=rules.duplicate(true)
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
	farm_floor = clampi(farm_floor+change,1,maxi(1,floor_number-1))
	_save_progress()
	_build_ui()

func _start_farming() -> void:
	auto_repeat = true
	_start_run(farm_floor,_farm_contract())

func _toggle_run_pause() -> void:
	if finish_pending: return
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
	if success:
		var loot_rng := RandomNumberGenerator.new()
		loot_rng.seed = seed_value+7919
		var drop_count := 1 if loot_rng.randf()<0.68 else 2
		if first_trial: drop_count=1
		for i in range(drop_count):
			var item := _generate_item(true,target_floor,loot_rng,loot_class,String(rules.get("slot","")),"EPIC" if first_trial else "")
			if inventory.size()<MAX_BAG_SIZE:
				inventory.append(item)
				if offline: pending_idle_gear += 1
				else: run_loot.append(item)
			else:
				gold += int(item.sell)
				if offline: pending_idle_salvaged += 1
		if mode=="campaign": floor_number = maxi(floor_number,target_floor+1)
		if first_trial: trial_cleared=int(rules.tier)
	if not offline:
		run_reward={"gold":gold,"xp":xp,"title":Contract.title(rules),"note":"First clear • guaranteed Epic relic" if first_trial else "Focused drops • "+String(rules.slot) if mode=="hunt" else ""}
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
	return ClassLoot.roll(character_class if loot_class.is_empty() else loot_class,boss_bonus,_gear_tier_at_floor(drop_floor),loot_rng,focused_slot,minimum_quality)

func _equip_item(item: Dictionary) -> void:
	if offline_job!=null: return
	if not inventory.has(item):
		return
	var slot: String = item.slot
	var displaced: Dictionary = equipment[slot]
	displaced["slot"] = slot
	displaced["status"] = ""
	equipment[slot] = item
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
	if not inventory.has(item):
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

func _simulate_offline_time(available_seconds: int) -> void:
	var remaining := mini(available_seconds,MAX_OFFLINE_SECONDS)
	# Current combat and dungeon layout share 256 reproducible pattern IDs. During one
	# AFK batch, floor/class/equipment stay fixed, so each pattern runs once.
	# Loot keeps its unique run seed. This is a cache, never a success estimate.
	var outcomes: Dictionary = {}
	while remaining>=30:
		var seed_value := _run_seed_for_serial(expedition_serial)
		var pattern := posmod(seed_value,Expedition.COMBAT_VARIANTS)
		if not outcomes.has(pattern):
			var simulation := _new_expedition(farm_floor,expedition_serial,_farm_contract())
			simulation.simulate_to_end()
			outcomes[pattern] = {"duration":maxi(30,ceili(simulation.elapsed)),"won":simulation.won}
		var outcome: Dictionary = outcomes[pattern]
		if outcome.duration>remaining: break
		remaining -= outcome.duration
		expedition_serial += 1
		_grant_expedition_rewards(outcome.won,farm_floor,true,seed_value,"",_farm_contract())
	idle_progress_seconds = remaining

func _accrue_offline_time(cooperative: bool=false) -> void:
	var now := int(clock_source.call())
	if last_saved_at<=0:
		last_saved_at = now
		return
	var away := clampi(now-last_saved_at,0,MAX_OFFLINE_SECONDS)
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
		if not run_active: return
		expedition.advance(float(away))
		_sync_model_state()
		if not expedition.finished: return
		var remaining := maxi(0,floori(expedition.accumulator+0.00001))
		last_run_floor = run_floor
		_grant_expedition_rewards(expedition.won,run_floor,true,expedition.run_seed,expedition.class_key,expedition.contract())
		if auto_repeat and expedition.won and Contract.mode(expedition.contract())!="trial":
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
	preferences = Preferences.normalize(save.get_value("settings","preferences",preferences))
	skill_loadouts=Skills.normalize_book(save.get_value("hero","skill_loadouts",{}))
	combat_stances=Stances.normalize_book(save.get_value("hero","combat_stances",{}))
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
	return normalized

func _build_save_payload() -> ConfigFile:
	var save := ConfigFile.new()
	save.set_value("settings","preferences",preferences)
	save.set_value("hero","onboarding_complete",onboarding_complete)
	save.set_value("hero", "class", character_class)
	save.set_value("hero","skill_loadouts",skill_loadouts)
	save.set_value("hero","combat_stances",combat_stances)
	save.set_value("hero","expedition_serial",expedition_serial)
	if world_seed<=0 or world_seed>MAX_PROFILE_SEED: world_seed=_new_profile_seed()
	save.set_value("hero","world_seed",world_seed)
	save.set_value("idle","farm_floor",farm_floor)
	save.set_value("idle","farm_mode",farm_mode)
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
		save.set_value("run","active",run_active)
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

func _valid_backup_item(value: Variant,default_slot: String) -> bool:
	if not value is Dictionary: return false
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
	dismiss.custom_minimum_size = Vector2(36,_minimum_button_height(36))
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

func _update_forecast(label: Label,target_floor: int,farming: bool,rules: Dictionary={}) -> void:
	label.custom_minimum_size.y=44 if farming else 24
	var revision:=ui_revision
	var values:=_combat_stats()
	if not rules.is_empty(): values.expedition_contract=rules.duplicate(true)
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
		if owns_job: assessment.step_budget()
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
	stack.add_child(_centered_label("CHOOSE YOUR OATH",22,PALE,true))
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
		column.add_child(_paragraph_label(info.passive,10,MUTED))
		var space:=Control.new()
		space.size_flags_vertical=Control.SIZE_EXPAND_FILL
		column.add_child(space)
		column.add_child(_label("FOCUS: "+String(info.primary).to_upper(),9,GOLD))
		var choose:=_button("SELECTED" if key==character_class else "CHOOSE",Color("493b30") if key==character_class else PANEL,10,_choose_initial_class.bind(String(key)))
		choose.name="Choose"+String(key)
		column.add_child(choose)
	stack.add_child(_paragraph_label("Walk, fight and collect automatically. After a run, compare your loot or sell it. Enable AFK farming to continue while the game is closed, for up to 24 hours.",11,PALE))
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
	elif has_node("Welcome"):
		return
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
	if page=="run" or slot<0 or slot>1 or not key in Skills.choices(character_class): return
	var loadout := Skills.normalize(character_class,skill_loadouts.get(character_class))
	var old: String=loadout[slot]
	var other:=1-slot
	if loadout[other]==key: loadout[other]=old
	loadout[slot]=key
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
		var values := _combat_stats()
		values.expedition_contract=_farm_contract()
		offline_job=OfflineFarm.new()
		offline_job.setup(character_class,values,farm_floor,String(_region_data(farm_floor).boss),seconds,expedition_serial,world_seed)
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
		_grant_expedition_rewards(result.won,farm_floor,true,result.seed,character_class,_farm_contract())
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
	var changes := _compare_item(item)
	var improved := false
	for key in ["attack","ability_damage","max_hp","armor","max_mana","crit"]:
		if float(changes[key])<0.0: return false
		if float(changes[key])>0.0: improved=true
	return improved and int(changes.mana_cost)<=0

func _equip_recovered_upgrades() -> void:
	if page!="loot" or offline_job!=null: return
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
