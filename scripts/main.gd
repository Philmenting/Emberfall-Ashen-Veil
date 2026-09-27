extends Control

const HeroArt = preload("res://scripts/hero_art.gd")
const BattleArt = preload("res://scripts/battle_art.gd")
const Expedition = preload("res://scripts/expedition_simulation.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const Forecast = preload("res://scripts/farm_forecast.gd")
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
		"passive": "Cleave nearby foes; Ember Oath heals 8% Life and grants Guard for 2.8s. Cooldown: 5.5s."
	},
	"Arcanist": {
		"primary": "Intellect", "secondary": "Spirit", "ability": "Veil Nova",
		"base": {"Strength": 5, "Dexterity": 8, "Intellect": 20, "Vitality": 9, "Spirit": 17},
		"color": Color("a58ed4"), "tagline": "Spellcaster • burst and mana",
		"passive": "Nova slows and interrupts groups (6s). Mana Ward absorbs 35% damage for 2 Mana each, reserving one Nova."
	},
	"Ranger": {
		"primary": "Dexterity", "secondary": "Vitality", "ability": "Cinder Volley",
		"base": {"Strength": 9, "Dexterity": 19, "Intellect": 6, "Vitality": 11, "Spirit": 11},
		"color": Color("83b596"), "tagline": "Ranged • precision and criticals",
		"passive": "Prioritizes hexers; retreats in close combat. Volley gains 12% crit and interrupts. Cooldown: 4.5s."
	}
}
const GEAR_NAMES := {
	"Weapon": ["Gloamfang", "Oathsplitter", "Ashwake Edge", "Quietus"],
	"Helmet": ["Cowl of Last Embers", "Hollow-Crowned Hood", "Veilstitch Mask", "Warden's Sight"],
	"Chest": ["Mantle of the Dusk", "Sable Pilgrim's Shroud", "Ashen Vowcoat", "Nightglass Wrap"],
	"Gloves": ["Grips of the Bellkeeper", "Cinderbound Gauntlets", "Pale Knuckle-wraps", "Warden's Grasp"],
	"Boots": ["Pilgrim's Treads", "Steps Between Veils", "Ashwalker Greaves", "Hollowstride"],
	"Amulet": ["Heart of the Spire", "Blackglass Sigil", "Lastlight Reliquary", "Cinder Votive"]
}
const QUALITY_ORDER := ["COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY"]
const QUALITY_COLORS := {
	"COMMON": Color("c2bcb0"), "UNCOMMON": Color("85b497"), "RARE": Color("81a9d9"),
	"EPIC": Color("bb86d4"), "LEGENDARY": Color("e0a35d")
}
const MAX_OFFLINE_SECONDS := 24 * 60 * 60
const MAX_BAG_SIZE := 20
const MAX_TEMPER_RANK := 5

var clock_source: Callable = Time.get_unix_time_from_system

var preferences := Preferences.DEFAULTS.duplicate()
var audio: Node
var menu_resume_run := false
var last_back_frame := -1

var page := "camp"
var gear_tab := "bag"
var character_class := "Vowkeeper"
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
var expedition_serial := 1
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
	_accrue_offline_time()
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
	_accrue_offline_time()
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
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margins.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margins.add_theme_constant_override("margin_left", 18)
	margins.add_theme_constant_override("margin_right", 18)
	margins.add_theme_constant_override("margin_top", 13)
	margins.add_theme_constant_override("margin_bottom", 11)
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
	body.add_child(_build_hero_rail())
	var middle := VBoxContainer.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(middle)
	var scroll := ScrollContainer.new()
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
	body.add_child(_build_stats_rail())
	layout.add_child(_build_navigation())
	_show_save_notice()

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
	options.custom_minimum_size=Vector2(86,34)
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
	class_button.custom_minimum_size.y = 38
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
	if pending_idle_runs>0 or pending_idle_ash>0 or pending_idle_xp>0: _build_idle_report(parent)
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
	var farm_panel := _panel(Color("19241f"),Color("405347"),14)
	parent.add_child(farm_panel)
	var farm_stack := VBoxContainer.new()
	farm_panel.add_child(farm_stack)
	farm_stack.add_child(_label("FARM FLOOR %02d  •  WATCHED + OFFLINE" % farm_floor,12,GREEN,true))
	farm_stack.add_child(_paragraph_label("Choose a cleared floor. Repeat runs collect gear automatically and stop after a defeat. Offline farming uses this same floor and combat rules.",10,MUTED))
	var forecast := _paragraph_label("Assessing this floor with your current gear…",10,MUTED)
	farm_stack.add_child(forecast)
	_update_forecast(forecast,farm_floor,true)
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
	if pending_idle_runs==0 and pending_idle_ash==0 and pending_idle_xp==0:
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
	for tab in [["bag","BAG (%d)" % inventory.size()],["equipment","EQUIPMENT"],["build","CLASS & STATS"]]:
		tabs.add_child(_button(tab[1],Color("493b30") if gear_tab==tab[0] else PANEL_LIGHT,10,_select_gear_tab.bind(String(tab[0]))))
	match gear_tab:
		"build": _build_class_editor(parent)
		"equipment": _build_equipment_list(parent)
		_: _build_inventory_list(parent)

func _build_class_editor(parent: VBoxContainer) -> void:
	var classes := HBoxContainer.new()
	classes.add_theme_constant_override("separation", 6)
	parent.add_child(_section_heading("PLAYABLE CLASSES", "%d ATTRIBUTE POINTS" % attribute_points))
	for class_key in CLASS_DATA.keys():
		var class_button := _button(String(class_key).to_upper(), PANEL_LIGHT if character_class != class_key else Color("493b30"), 10, Callable(self, "_select_class").bind(String(class_key)))
		class_button.custom_minimum_size.y = 42
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
	var region := _region_data()
	var map_card := _panel(PANEL, EDGE, 17)
	parent.add_child(map_card)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 7)
	map_card.add_child(stack)
	stack.add_child(_label(String(region.name).to_upper(), 10, GOLD, true))
	stack.add_child(_label("%s  •  Floor %02d" % [String(region.dungeon), floor_number], 20, PALE, true))
	stack.add_child(_paragraph_label("%s Its guardian is %s. Nyra advances automatically while the expedition is active." % [String(region.description), String(region.boss)], 13, MUTED))
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
	arena.simulation_advanced.connect(_on_combat_advanced)
	arena.state_changed.connect(_on_dungeon_state_changed)
	add_child(arena)
	run_arena = arena
	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]:
		safe.add_theme_constant_override("margin_" + edge, 18)
	safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(safe)
	var overlay := VBoxContainer.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe.add_child(overlay)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation",24)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(top)
	var hero_panel := _panel(Color(0.025,0.035,0.05,0.86),Color("5d6370"),12)
	hero_panel.custom_minimum_size.x = 190
	hero_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	top.add_child(hero_panel)
	var hero_stack := VBoxContainer.new()
	hero_panel.add_child(hero_stack)
	hero_stack.add_child(_label("NYRA  /  LV. %d" % player_level,15,PALE,true))
	hero_stack.add_child(_label(character_class.to_upper(),9,GOLD,true))
	combat_hud.hp = _progress_bar(run_health,int(_combat_stats().max_hp),RED,9)
	hero_stack.add_child(combat_hud.hp)
	combat_hud.mana = _progress_bar(run_mana,int(_combat_stats().max_mana),Color("5f91c4"),5)
	hero_stack.add_child(combat_hud.mana)
	combat_hud.life = _label("",9,MUTED)
	hero_stack.add_child(combat_hud.life)
	combat_hud.skill = _label("",9,GOLD)
	hero_stack.add_child(combat_hud.skill)
	if character_class=="Arcanist" and float(expedition.stats.get("mana_guard",0.0))>0.0:
		combat_hud.ward = _label("",8,Color("ac9bdc"))
		hero_stack.add_child(combat_hud.ward)
	var top_gap := Control.new()
	top_gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(top_gap)
	var objective_panel := _panel(Color(0.025,0.035,0.05,0.80),Color("5a4b37"),12)
	objective_panel.custom_minimum_size.x = 215
	objective_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	top.add_child(objective_panel)
	var objective := VBoxContainer.new()
	objective_panel.add_child(objective)
	objective.add_child(_label(String(_region_data(run_floor).dungeon).to_upper(),13,GOLD,true))
	objective.add_child(_label("FLOOR %02d  •  AUTOMATIC EXPEDITION" % run_floor,8,MUTED,true))
	combat_hud.progress = _progress_bar(0,run_max_stages,GOLD,5)
	objective.add_child(combat_hud.progress)
	combat_hud.encounter = _label("",10,PALE,true)
	objective.add_child(combat_hud.encounter)
	var options:=_button("OPTIONS / PAUSE",PANEL_LIGHT,9,_show_settings)
	options.name="OpenSettings"
	options.custom_minimum_size.y=34
	objective.add_child(options)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(spacer)
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_theme_constant_override("separation",12)
	overlay.add_child(bottom)
	var status_panel := _panel(Color(0.025,0.035,0.05,0.82),Color("4b505a"),12)
	status_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(status_panel)
	var status := VBoxContainer.new()
	status_panel.add_child(status)
	combat_hud.state = _label("AUTO • ENTERING THE DUNGEON",11,GOLD,true)
	status.add_child(combat_hud.state)
	combat_hud.enemy = _label("",10,PALE)
	status.add_child(combat_hud.enemy)
	combat_hud.enemy_hp = _progress_bar(enemy_health,enemy_max_health,RED,5)
	status.add_child(combat_hud.enemy_hp)
	combat_hud.pause = _button("Ⅱ  PAUSE",Color("26323b"),11,Callable(self,"_toggle_run_pause"))
	combat_hud.pause.custom_minimum_size = Vector2(112,48)
	combat_hud.pause.size_flags_horizontal = Control.SIZE_SHRINK_END
	bottom.add_child(combat_hud.pause)
	combat_hud.repeat = _button("",Color("304638"),10,Callable(self,"_toggle_repeat"))
	combat_hud.repeat.custom_minimum_size = Vector2(110,48)
	combat_hud.repeat.size_flags_horizontal = Control.SIZE_SHRINK_END
	bottom.add_child(combat_hud.repeat)
	var skip := _button("SKIP TO LOOT  »",Color("713c32"),11,Callable(self,"_skip_run"))
	skip.custom_minimum_size = Vector2(160,48)
	skip.size_flags_horizontal = Control.SIZE_SHRINK_END
	bottom.add_child(skip)
	_sync_combat_hud()

func _on_dungeon_state_changed(description: String) -> void:
	if combat_hud.has("state"):
		combat_hud.state.text = description

func _sync_combat_hud() -> void:
	if page != "run" or combat_hud.is_empty(): return
	combat_hud.state.text = ("AUTO • " if run_active else "PAUSED • ")+String(expedition.action).to_upper()
	combat_hud.hp.value = run_health
	combat_hud.mana.value = run_mana
	combat_hud.life.text = "%d LIFE   /   %d MANA" % [run_health,run_mana]
	combat_hud.progress.value = run_stage
	combat_hud.encounter.text = "PACK %02d / %02d  •  %d ALIVE" % [mini(run_stage+1,run_max_stages),run_max_stages,expedition.living().size()]
	combat_hud.enemy.text = "%s  •  %d / %d" % [current_enemy,enemy_health,enemy_max_health]
	combat_hud.enemy_hp.max_value = enemy_max_health
	combat_hud.enemy_hp.value = enemy_health
	combat_hud.pause.text = "Ⅱ  PAUSE" if run_active else "▶  RESUME"
	combat_hud.repeat.text = "REPEAT: ON" if auto_repeat else "REPEAT: OFF"
	combat_hud.skill.text = "%s  /  %s" % [String(CLASS_DATA[character_class].ability),"READY" if expedition.skill_cd<=0 else "%.1fs" % expedition.skill_cd]
	if combat_hud.has("ward"):
		combat_hud.ward.text = "WARD • %d MANA AVAILABLE" % maxi(0,expedition.hero_mana-int(expedition.stats.mana_cost))

func _build_loot(parent: VBoxContainer) -> void:
	var victory := _panel(Color("28261f"), Color("796746"), 17)
	parent.add_child(victory)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	victory.add_child(stack)
	stack.add_child(_label("%s" % ("✦  THE BELLS ARE QUIET  ✦" if run_succeeded else "NYRA RETREATS FROM THE SPIRE"), 11, GOLD if run_succeeded else Color("d48166"), true))
	var reward_floor := last_run_floor if last_run_floor > 0 else floor_number
	stack.add_child(_label("Floor %02d  •  +%d XP  •  +%d Gold" % [reward_floor, 420 + reward_floor * 8 if run_succeeded else 100, 186 + reward_floor * 4 if run_succeeded else 55], 16, PALE, true))
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
	parent.add_child(_button("RETURN TO CAMP", RED, 12, Callable(self, "_return_to_camp")))

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
	button.custom_minimum_size = Vector2(0, 40)
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.text = "%s   %s" % [icon, caption]
	button.add_theme_font_size_override("font_size", 11)
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
	top.add_child(identity)
	top.add_child(_label("ITEM %d" % int(item.power),11,GOLD,true))
	stack.add_child(top)
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
	button.custom_minimum_size = Vector2(76, 46)
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
	button.text = caption
	button.custom_minimum_size = Vector2(0, 46)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", font_size)
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
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.25))
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	return label

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
	var attack := 52 + weapon_power + primary_value * 5
	var max_hp := 100 + int(attributes.Vitality) * 14
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
			ability_damage = int(attack * (1.28 + float(rank) * 0.18) + primary_value * 7)
			mana_cost = 19 + rank * 3
		"Ranger":
			ability_damage = int(attack * (1.16 + float(rank) * 0.14) + primary_value * 6)
			mana_cost = 14 + rank * 2
		_: # Vowkeeper trades burst for staying power.
			ability_damage = int(attack * (1.05 + float(rank) * 0.12) + primary_value * 6 + int(attributes.Vitality) * 2)
			mana_cost = 12 + rank * 2
			class_mitigation = int(attributes.Vitality / 18)
	var power := attack + armor * 2 + int(attributes.Intellect) * 3 + int(attributes.Vitality) * 2
	return {"attributes": attributes, "attack": attack, "max_hp": max_hp, "max_mana": max_mana, "armor": armor, "crit": crit, "ability_damage": ability_damage, "mana_cost": mana_cost, "class_mitigation": class_mitigation, "mana_guard":0.35 if character_class=="Arcanist" else 0.0, "power": power, "gear_power": gear_power}

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
	if page == "run" and destination != "run":
		return
	page = destination
	_build_ui()

func _select_class(class_key: String) -> void:
	if not CLASS_DATA.has(class_key):
		return
	if character_class!=class_key: _refund_attributes()
	character_class = class_key
	_save_progress()
	_build_ui()

func _allocate_attribute(attribute: String) -> void:
	if attribute_points <= 0 or not ATTRIBUTES.has(attribute):
		return
	allocated_attributes[attribute] = int(allocated_attributes.get(attribute, 0)) + 1
	attribute_points -= 1
	_save_progress()
	_build_ui()

func _start_run(target_floor: int = -1) -> void:
	onboarding_complete = true
	page = "run"
	run_floor = clampi(floor_number if target_floor<1 else target_floor,1,maxi(1,floor_number))
	run_active = true
	run_stage = 0
	run_succeeded = false
	run_boss_defeated = false
	run_loot.clear()
	run_events = ["Nyra enters %s." % String(_region_data(run_floor).dungeon)]
	expedition = _new_expedition(run_floor,expedition_serial)
	expedition_serial += 1
	_sync_model_state()
	finish_pending = false
	last_combat_save = 0.0
	_save_progress()
	_build_ui()

func _new_expedition(target_floor: int, serial: int) -> RefCounted:
	var simulation := Expedition.new()
	simulation.setup(character_class,_combat_stats(),target_floor,String(_region_data(target_floor).boss),1979+serial*104729)
	return simulation

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
	if finish_pending: return
	auto_repeat = not auto_repeat
	_save_progress()
	_sync_combat_hud()

func _set_farm_floor(change: int) -> void:
	farm_floor = clampi(farm_floor+change,1,maxi(1,floor_number-1))
	_save_progress()
	_build_ui()

func _start_farming() -> void:
	auto_repeat = true
	_start_run(farm_floor)

func _toggle_run_pause() -> void:
	if finish_pending: return
	run_active = not run_active
	if is_instance_valid(run_arena):
		run_arena.animation_enabled = run_active
	combat_hud.state.text = "PAUSED" if not run_active else "AUTO • RESUMING"
	_sync_combat_hud()
	_save_progress()

func _toggle_farm() -> void:
	farm_enabled = not farm_enabled
	if not farm_enabled:
		idle_progress_seconds = 0
	_save_progress()
	_build_ui()

func _grant_expedition_rewards(success: bool, target_floor: int, offline: bool, seed_value: int) -> void:
	var gold := 186+target_floor*4 if success else 55
	var xp := 420+target_floor*8 if success else 100
	if success:
		var loot_rng := RandomNumberGenerator.new()
		loot_rng.seed = seed_value+7919
		var drop_count := 1 if loot_rng.randf()<0.68 else 2
		for i in range(drop_count):
			var item := _generate_item(true,target_floor,loot_rng)
			if inventory.size()<MAX_BAG_SIZE:
				inventory.append(item)
				if offline: pending_idle_gear += 1
				else: run_loot.append(item)
			else:
				gold += int(item.sell)
				if offline: pending_idle_salvaged += 1
		floor_number = maxi(floor_number,target_floor+1)
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
	_grant_expedition_rewards(true,run_floor,false,expedition.run_seed)
	page = "loot"
	_save_progress()
	_finish_run_presentation()

func _fail_run() -> void:
	if page!="run": return
	run_active = false
	auto_repeat = false
	run_succeeded = false
	last_run_floor = run_floor
	run_loot.clear()
	_grant_expedition_rewards(false,run_floor,false,expedition.run_seed)
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
	get_tree().create_timer(1.2).timeout.connect(func():
		finish_pending = false
		if auto_repeat and run_succeeded:
			_start_run(run_floor)
		else: _build_ui()
	)

func _generate_item(boss_bonus: bool = false, target_floor: int = -1, loot_rng: RandomNumberGenerator = null) -> Dictionary:
	if loot_rng==null:
		loot_rng = RandomNumberGenerator.new()
		loot_rng.randomize()
	var slot: String = GEAR_SLOTS[loot_rng.randi() % GEAR_SLOTS.size()]
	var roll := loot_rng.randf()
	var quality := "COMMON"
	if roll > 0.992:
		quality = "LEGENDARY"
	elif roll > 0.955:
		quality = "EPIC"
	elif roll > 0.82:
		quality = "RARE"
	elif roll > 0.53:
		quality = "UNCOMMON"
	if boss_bonus and (quality == "COMMON" or quality == "UNCOMMON"):
		quality = "RARE"
	var quality_bonus: int = int({"COMMON": 0, "UNCOMMON": 5, "RARE": 12, "EPIC": 22, "LEGENDARY": 36}[quality])
	var drop_floor := floor_number if target_floor < 1 else target_floor
	var tier := _gear_tier_at_floor(drop_floor)
	var power: int = tier * 18 + loot_rng.randi_range(7, 17) + quality_bonus
	var armor := int(power * (0.82 if ["Helmet", "Chest", "Gloves", "Boots"].has(slot) else 0.0))
	var stats := {}
	var affixes := 1
	if quality == "RARE": affixes = 2
	if quality == "EPIC": affixes = 3
	if quality == "LEGENDARY": affixes = 4
	var candidates := ATTRIBUTES.duplicate()
	for i in range(affixes):
		var selected: String = candidates.pop_at(loot_rng.randi() % candidates.size())
		stats[selected] = loot_rng.randi_range(1, 3 + tier + int(quality_bonus / 10))
	if quality == "EPIC" or quality == "LEGENDARY":
		stats["Crit"] = loot_rng.randi_range(1, 3 + tier)
	var sell_value: int = 28 + tier * 12 + quality_bonus * 4 + loot_rng.randi_range(0, 16)
	var item_name: String = GEAR_NAMES[slot][loot_rng.randi() % GEAR_NAMES[slot].size()]
	return {"name": item_name, "slot": slot, "power": power, "quality": quality, "tier": tier, "armor": armor, "stats": stats, "sell": sell_value, "temper": 0, "status": ""}

func _equip_item(item: Dictionary) -> void:
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
	# Combat has 64 reproducible critical-roll patterns. During one AFK batch,
	# floor/class/equipment stay fixed, so each pattern is simulated exactly once.
	# Loot keeps its unique run seed. This is a cache, never a success estimate.
	var outcomes: Dictionary = {}
	while remaining>=30:
		var seed_value := 1979+expedition_serial*104729
		var pattern := posmod(seed_value,Expedition.COMBAT_VARIANTS)
		if not outcomes.has(pattern):
			var simulation := _new_expedition(farm_floor,expedition_serial)
			simulation.simulate_to_end()
			outcomes[pattern] = {"duration":maxi(30,ceili(simulation.elapsed)),"won":simulation.won}
		var outcome: Dictionary = outcomes[pattern]
		if outcome.duration>remaining: break
		remaining -= outcome.duration
		expedition_serial += 1
		_grant_expedition_rewards(outcome.won,farm_floor,true,seed_value)
	idle_progress_seconds = remaining

func _accrue_offline_time() -> void:
	var now := int(clock_source.call())
	if last_saved_at<=0:
		last_saved_at = now
		return
	var away := clampi(now-last_saved_at,0,MAX_OFFLINE_SECONDS)
	last_saved_at = maxi(last_saved_at,now)
	if not farm_enabled:
		idle_progress_seconds = 0
		return
	if page=="run" and expedition!=null:
		# Pausing is persistent: no second copy of the same hero farms in parallel.
		if not run_active: return
		expedition.advance(float(away))
		_sync_model_state()
		if not expedition.finished: return
		var remaining := maxi(0,floori(expedition.accumulator+0.00001))
		last_run_floor = run_floor
		_grant_expedition_rewards(expedition.won,run_floor,true,expedition.run_seed)
		if auto_repeat and expedition.won: farm_floor = run_floor
		run_active = false
		auto_repeat = false
		page = "camp"
		expedition = null
		_simulate_offline_time(mini(MAX_OFFLINE_SECONDS,idle_progress_seconds+remaining))
		return
	_simulate_offline_time(mini(MAX_OFFLINE_SECONDS,idle_progress_seconds+away))

func _load_progress() -> void:
	page = "camp"
	expedition = null
	run_active = false
	auto_repeat = false
	finish_pending = false
	last_combat_save = 0.0
	var save: ConfigFile = save_store.load_save()
	save_notice = save_store.notice
	if save==null:
		last_saved_at = int(clock_source.call())
		return
	preferences = Preferences.normalize(save.get_value("settings","preferences",preferences))
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
	farm_floor = clampi(int(save.get_value("idle","farm_floor",1)),1,maxi(1,floor_number-1))
	expedition_serial = maxi(1,int(save.get_value("hero","expedition_serial",1)))
	farm_enabled = bool(save.get_value("idle", "farm_enabled", farm_enabled))
	last_saved_at = int(save.get_value("idle", "saved_at", clock_source.call()))
	var run_data = save.get_value("run","snapshot","")
	if run_data is String and not run_data.is_empty():
		var restored := Expedition.new()
		if restored.restore_encoded(run_data) and not restored.finished and restored.class_key==character_class:
			expedition = restored
			run_floor = restored.floor_id
			run_active = bool(save.get_value("run","active",true))
			auto_repeat = bool(save.get_value("run","repeat",false))
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

func _save_progress() -> void:
	var save := ConfigFile.new()
	save.set_value("settings","preferences",preferences)
	save.set_value("hero","onboarding_complete",onboarding_complete)
	save.set_value("hero", "class", character_class)
	save.set_value("hero","expedition_serial",expedition_serial)
	save.set_value("idle","farm_floor",farm_floor)
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
	save.set_value("idle", "farm_enabled", farm_enabled)
	last_saved_at = maxi(last_saved_at,int(clock_source.call()))
	save.set_value("idle", "saved_at", last_saved_at)
	if page=="run" and expedition!=null and not expedition.finished:
		save.set_value("run","snapshot",expedition.encode_snapshot())
		save.set_value("run","active",run_active)
		save.set_value("run","repeat",auto_repeat)
	var status: Error = save_store.save_game(save)
	last_save_ok = status==OK
	if status!=OK:
		save_notice = save_store.notice if not save_store.notice.is_empty() else "Progress could not be saved. Existing checkpoints are preserved. (%s)" % error_string(status)
		_show_save_notice()


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
	dismiss.custom_minimum_size = Vector2(36,36)
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

func _update_forecast(label: Label,target_floor: int,farming: bool) -> void:
	var revision:=ui_revision
	var values:=_combat_stats()
	var selected_class:=character_class
	var boss:=String(_region_data(target_floor).boss)
	var key:=selected_class+":"+str(target_floor)+":"+var_to_str(values)
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
		if owns_job: assessment.step(2)
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
	if persist: _save_progress()

func _apply_preferences() -> void:
	Engine.max_fps=30 if preferences.battery else 60
	if is_instance_valid(audio): audio.apply_preferences(preferences)
	if page=="run" and is_instance_valid(run_arena):
		run_arena.apply_quality(preferences.battery,preferences.numbers)

func _save_and_exit() -> void:
	# Opening options temporarily pauses; explicit exit preserves the prior intent.
	if menu_resume_run and page=="run": run_active=true
	_save_progress()
	if not last_save_ok:
		if menu_resume_run and page=="run": run_active=false
		_show_save_notice()
		return
	get_tree().quit()
