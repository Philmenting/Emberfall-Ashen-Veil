extends Control

const HeroArt = preload("res://scripts/hero_art.gd")
const BattleArt = preload("res://scripts/battle_art.gd")

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
		"passive": "Ember Oath restores 8% of max Life on cast."
	},
	"Arcanist": {
		"primary": "Intellect", "secondary": "Spirit", "ability": "Veil Nova",
		"base": {"Strength": 5, "Dexterity": 8, "Intellect": 20, "Vitality": 9, "Spirit": 17},
		"color": Color("a58ed4"), "tagline": "Spellcaster • burst and mana",
		"passive": "Veil Nova refunds 25% of its mana cost."
	},
	"Ranger": {
		"primary": "Dexterity", "secondary": "Vitality", "ability": "Cinder Volley",
		"base": {"Strength": 9, "Dexterity": 19, "Intellect": 6, "Vitality": 11, "Spirit": 11},
		"color": Color("83b596"), "tagline": "Ranged • precision and criticals",
		"passive": "Volley gains 12% crit; criticals hit for 2.15×."
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
const DUNGEON_RUN_SECONDS := 72
const MAX_OFFLINE_SECONDS := 24 * 60 * 60
const MAX_BAG_SIZE := 20
const MAX_TEMPER_RANK := 5

var page := "camp"
var character_class := "Vowkeeper"
var player_gold := 600
var player_shards := 0
var player_level := 1
var player_xp := 0
var attribute_points := 2
var allocated_attributes := {"Strength": 0, "Dexterity": 0, "Intellect": 0, "Vitality": 0, "Spirit": 0}
var floor_number := 1
var last_run_floor := 0

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
var run_timer: Timer

func _ready() -> void:
	randomize()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	run_timer = Timer.new()
	# A usual enemy takes about two combat beats, so a full run still averages close to one minute.
	run_timer.wait_time = float(DUNGEON_RUN_SECONDS) / float(run_max_stages * 2)
	run_timer.timeout.connect(_on_run_tick)
	add_child(run_timer)
	_load_progress()
	for slot in GEAR_SLOTS:
		equipment[slot]["slot"] = slot
	_accrue_offline_time()
	_save_progress()
	_build_ui()

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
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_progress()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_accrue_offline_time()
		_save_progress()
		_build_ui()

func _region_index(target_floor: int = -1) -> int:
	var selected_floor := floor_number if target_floor < 1 else target_floor
	return clampi(int((maxi(1, selected_floor) - 1) / 10.0), 0, REGIONS.size() - 1)

func _region_data(target_floor: int = -1) -> Dictionary:
	return REGIONS[_region_index(target_floor)]

func _build_ui() -> void:
	for child in get_children():
		if child != run_timer:
			remove_child(child)
			child.free()
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
		"run": _build_run(content)
		"loot": _build_loot(content)
	body.add_child(_build_stats_rail())
	layout.add_child(_build_navigation())

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
	var class_button := _button("CHANGE CLASS", PANEL_LIGHT, 10, Callable(self, "_navigate").bind("gear"))
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
	skill_stack.add_child(_label("Next rank at %s %d" % [String(CLASS_DATA[character_class].primary), ability_rank * 15], 9, GOLD))
	content.add_child(_button("AFK FARM: %s" % ("ON" if farm_enabled else "OFF"), Color("31443a") if farm_enabled else PANEL_LIGHT, 9, Callable(self, "_toggle_farm")))
	return rail

func _build_camp(parent: VBoxContainer) -> void:
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
	var recommended := 515 + maxi(0, mini(floor_number, 4) - 1) * 35 + maxi(0, floor_number - 4) * 85
	heading.add_child(_label("RECOMMENDED  %d" % recommended, 9, Color("b2a392"), true))
	stack.add_child(heading)
	stack.add_child(_label(String(region.dungeon).to_upper(), 22, PALE, true))
	stack.add_child(_paragraph_label("%s Nyra will fight through five encounters and face %s for the region's relics." % [String(region.description), String(region.boss)], 13, MUTED))
	stack.add_child(_map_route())
	stack.add_child(_button("DESCEND TO FLOOR %02d   →" % floor_number, RED, 14, Callable(self, "_start_run")))
	if floor_number == 1 and player_level == 1:
		stack.add_child(_empty_note("FIRST DESCENT  •  Set your class and attribute points in the Armory. Equip or temper gear before each run; the dungeon fights automatically."))
	var progress := _panel(PANEL, EDGE, 16)
	parent.add_child(progress)
	var progress_stack := VBoxContainer.new()
	progress_stack.add_theme_constant_override("separation", 4)
	progress.add_child(progress_stack)
	progress_stack.add_child(_label("RUN LOOP", 9, GOLD, true))
	progress_stack.add_child(_paragraph_label("~%d seconds per AFK expedition  •  24-hour limit  •  overflow loot auto-salvaged" % DUNGEON_RUN_SECONDS, 11, PALE))
	if pending_idle_runs > 0 or pending_idle_ash > 0 or pending_idle_xp > 0:
		var report := _panel(Color("19241f"), Color("405347"), 16)
		parent.add_child(report)
		var report_stack := VBoxContainer.new()
		report_stack.add_theme_constant_override("separation", 5)
		report.add_child(report_stack)
		report_stack.add_child(_label("OFFLINE REPORT  •  READY TO CLAIM", 10, GREEN, true))
		report_stack.add_child(_paragraph_label("%d cleared  •  %d setbacks  •  %d relics kept  •  %d auto-salvaged" % [pending_idle_runs, pending_idle_fails, pending_idle_gear, pending_idle_salvaged], 11, PALE))
		report_stack.add_child(_label("+%d Gold  •  +%d XP" % [pending_idle_ash, pending_idle_xp], 12, GOLD, true))
		report_stack.add_child(_button("CLAIM OFFLINE HAUL", Color("31443a"), 11, Callable(self, "_claim_idle_cache")))
	else:
		var status := "ON — expeditions keep progressing while you are away." if farm_enabled else "OFF — offline time will not start dungeon runs."
		parent.add_child(_empty_note("AFK FARM %s" % status))

func _build_gear(parent: VBoxContainer) -> void:
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
	parent.add_child(_section_heading("EQUIPPED GEAR", "%d SLOTS  •  TEMPER UP TO +%d" % [GEAR_SLOTS.size(), MAX_TEMPER_RANK]))
	for slot in GEAR_SLOTS:
		parent.add_child(_equipped_row(slot, equipment[slot]))
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
	notes_stack.add_child(_paragraph_label("When you leave or background the app, the next launch simulates completed runs from elapsed time. Up to 24 hours are counted; overflow gear is salvaged into Gold.", 12, PALE))
	notes.add_child(notes_stack)

func _build_run(parent: VBoxContainer) -> void:
	var region := _region_data()
	var card := _panel(PANEL, Color("59433d"), 17)
	parent.add_child(card)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 7)
	card.add_child(stack)
	var title := HBoxContainer.new()
	title.add_child(_label("ENCOUNTER %02d / %02d" % [mini(run_stage + 1, run_max_stages), run_max_stages], 10, GOLD, true))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_child(spacer)
	title.add_child(_label("%s" % ("AUTO-FIGHTING" if run_active else "PAUSED"), 9, Color("d78b65"), true))
	stack.add_child(title)
	stack.add_child(_progress_bar(run_stage, run_max_stages, GOLD, 11))
	var arena := BattleArt.new()
	arena.custom_minimum_size = Vector2(0, 136)
	arena.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena.character_class = character_class
	arena.enemy_name = current_enemy
	arena.encounter = run_stage + 1
	arena.region_index = _region_index(floor_number)
	stack.add_child(arena)
	var enemy_row := HBoxContainer.new()
	enemy_row.add_theme_constant_override("separation", 10)
	stack.add_child(enemy_row)
	var sigil := _panel(Color("2b2326"), Color("735048"), 14)
	sigil.custom_minimum_size = Vector2(66, 66)
	sigil.add_child(_centered_label("☠", 32, Color("d08c68")))
	enemy_row.add_child(sigil)
	var enemy_info := VBoxContainer.new()
	enemy_info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	enemy_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_info.add_child(_label(current_enemy, 17, PALE, true))
	var is_boss := current_enemy == String(region.boss)
	var threat_label := "BOSS  •  THREAT %d" % int((620 + maxi(0, floor_number - 4) * 85) * 1.55) if is_boss else "ELITE  •  THREAT %d" % (620 + maxi(0, floor_number - 4) * 85)
	enemy_info.add_child(_label(threat_label, 9, Color("e6a16c") if is_boss else Color("d48166"), true))
	enemy_info.add_child(_label("%s deals %d ability damage." % [CLASS_DATA[character_class].ability, _combat_stats().ability_damage], 10, MUTED))
	enemy_row.add_child(enemy_info)
	stack.add_child(_label("ENEMY LIFE  %s / %s" % [_short_number(enemy_health), _short_number(enemy_max_health)], 9, Color("d48166"), true))
	stack.add_child(_progress_bar(enemy_health, enemy_max_health, Color("a64d45"), 8))
	var current_stats := _combat_stats()
	stack.add_child(_label("VITALITY  %s / %s" % [_short_number(run_health), _short_number(int(current_stats.max_hp))], 9, MUTED, true))
	stack.add_child(_progress_bar(run_health, int(current_stats.max_hp), GREEN, 8))
	stack.add_child(_label("MANA  %d / %d" % [run_mana, int(_combat_stats().max_mana)], 9, Color("a58ed4"), true))
	var log := _panel(PANEL, EDGE, 16)
	parent.add_child(log)
	var log_stack := VBoxContainer.new()
	log_stack.add_theme_constant_override("separation", 5)
	log.add_child(log_stack)
	log_stack.add_child(_label("FIELD NOTES", 9, GOLD, true))
	for event in run_events.slice(maxi(0, run_events.size() - 3), run_events.size()):
		log_stack.add_child(_paragraph_label("›  " + event, 11, PALE))
	if run_events.is_empty():
		log_stack.add_child(_paragraph_label("Nyra crosses the threshold. The bells fall silent.", 11, PALE))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 7)
	parent.add_child(actions)
	var pause := _button("%s" % ("PAUSE" if run_active else "RESUME"), PANEL_LIGHT, 11, Callable(self, "_toggle_run_pause"))
	actions.add_child(pause)
	actions.add_child(_button("SKIP TO LOOT  »", RED, 11, Callable(self, "_skip_run")))

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
	line.add_child(_label("+%d" % int(item.power), 13, GOLD, true))
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
	top.add_child(_label("+%d" % int(item.power), 14, GOLD, true))
	stack.add_child(top)
	var current: Dictionary = equipment.get(item.slot, {"power": 0, "stats": {}})
	var delta := int(item.power) - int(current.get("power", 0))
	stack.add_child(_label("%s%d power  •  %s  •  %d armor" % ["+" if delta >= 0 else "", delta, _item_stats_line(item), int(item.armor)], 9, GREEN if delta >= 0 else MUTED))
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

func _combat_stats() -> Dictionary:
	var class_info: Dictionary = CLASS_DATA[character_class]
	var base: Dictionary = class_info.base
	var attributes: Dictionary = {}
	var level_gain := maxi(0, player_level - 1)
	for attribute in ATTRIBUTES:
		var value := int(base[attribute]) + level_gain + int(allocated_attributes.get(attribute, 0))
		for item in equipment.values():
			value += int(item.get("stats", {}).get(attribute, 0))
		attributes[attribute] = value
	var primary := String(class_info.primary)
	var primary_value := int(attributes[primary])
	var weapon_power := int(equipment["Weapon"].get("power", 0))
	var armor := 0
	var gear_power := 0
	var gear_crit := 0.0
	for item in equipment.values():
		armor += int(item.get("armor", 0))
		gear_power += int(item.get("power", 0))
		gear_crit += float(item.get("stats", {}).get("Crit", 0))
	var attack := 52 + weapon_power + primary_value * 5
	var max_hp := 100 + int(attributes.Vitality) * 14
	var max_mana := 45 + int(attributes.Spirit) * 9 + int(attributes.Intellect) * 3
	var crit_scale := 0.35
	if character_class == "Ranger":
		crit_scale = 0.65
	var crit := float(attributes.Dexterity) * crit_scale + gear_crit
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
	return {"attributes": attributes, "attack": attack, "max_hp": max_hp, "max_mana": max_mana, "armor": armor, "crit": crit, "ability_damage": ability_damage, "mana_cost": mana_cost, "class_mitigation": class_mitigation, "power": power, "gear_power": gear_power}

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

func _start_run() -> void:
	page = "run"
	run_active = true
	run_stage = 0
	var stats := _combat_stats()
	run_health = int(stats.max_hp)
	run_mana = int(stats.max_mana)
	run_succeeded = false
	run_boss_defeated = false
	run_loot.clear()
	run_events = ["Nyra enters the Hollow Spire."]
	current_enemy = ENEMIES[randi() % ENEMIES.size()]
	_prepare_enemy()
	run_timer.start()
	_save_progress()
	_build_ui()

func _on_run_tick() -> void:
	if not run_active:
		return
	if _resolve_stage():
		_save_progress()
		_build_ui()

func _resolve_stage() -> bool:
	var stats := _combat_stats()
	var defeated_enemy := current_enemy
	var boss_name := String(_region_data(floor_number).boss)
	var boss_fight := defeated_enemy == boss_name
	var cast_ability := run_mana >= int(stats.mana_cost)
	var damage := int(stats.ability_damage) if cast_ability else int(stats.attack)
	if cast_ability:
		run_mana -= int(stats.mana_cost)
	var crit_chance := float(stats.crit) + (12.0 if character_class == "Ranger" and cast_ability else 0.0)
	var critical := randf() * 100.0 < crit_chance
	if critical:
		damage = int(float(damage) * (2.15 if character_class == "Ranger" else 1.7))
	enemy_health = maxi(0, enemy_health - damage)
	var enemy_fell := enemy_health == 0
	if not enemy_fell:
		var incoming := randi_range(10, 15) + floor_number + maxi(0, floor_number - 4)
		incoming -= clampi(int(stats.armor / 18.0), 1, 12) + int(stats.class_mitigation)
		if boss_fight:
			incoming = int(float(incoming) * 1.55) + 4
			run_mana = maxi(0, run_mana - 7)
		if randf() > _clear_chance(int(stats.power)):
			incoming += 9
			run_events.append("The %s lands a heavy blow." % defeated_enemy.to_lower())
		incoming = maxi(1, incoming)
		run_health = maxi(0, run_health - incoming)
		run_events.append("%s hits Nyra for %d." % [defeated_enemy, incoming])
	run_mana = mini(int(stats.max_mana), run_mana + int(stats.attributes.Spirit / 3))
	if cast_ability and character_class == "Vowkeeper":
		var heal_amount := maxi(1, int(float(stats.max_hp) * 0.08))
		var restored := mini(heal_amount, int(stats.max_hp) - run_health)
		run_health += restored
		if restored > 0:
			run_events.append("Ember Oath restores %d Life." % restored)
	elif cast_ability and character_class == "Arcanist":
		var restored_mana := int(stats.mana_cost / 4)
		run_mana = mini(int(stats.max_mana), run_mana + restored_mana)
		if restored_mana > 0:
			run_events.append("Veil Nova returns %d mana." % restored_mana)
	if run_health <= 0:
		run_events.append("Nyra's ward breaks. She retreats with what she can carry.")
		_fail_run()
		return false
	var action_name := String(CLASS_DATA[character_class].ability) if cast_ability else "Nyra"
	var critical_note := " CRITICAL!" if critical else ""
	run_events.append("%s hits %s for %d%s (%s / %s Life)." % [action_name, defeated_enemy, damage, critical_note, _short_number(enemy_health), _short_number(enemy_max_health)])
	if run_events.size() > 8:
		run_events.pop_front()
	if not enemy_fell:
		return true
	run_events.append("%s falls." % defeated_enemy)
	run_stage += 1
	if run_stage >= run_max_stages:
		run_boss_defeated = boss_fight
		run_events.append("The Spire's heart breaks. Nyra gathers what remains.")
		_complete_run()
		return false
	current_enemy = String(_region_data(floor_number).boss) if run_stage == run_max_stages - 1 else ENEMIES[randi() % ENEMIES.size()]
	_prepare_enemy()
	if current_enemy == String(_region_data(floor_number).boss):
		run_events.append("%s arrives to defend the region." % current_enemy)
	return true

func _prepare_enemy() -> void:
	var threat := 620 + maxi(0, floor_number - 4) * 85
	var health_multiplier := 2.55 if current_enemy == String(_region_data(floor_number).boss) else 1.5
	enemy_max_health = maxi(1, int(float(threat) * health_multiplier + floor_number * 35))
	enemy_health = enemy_max_health

func _clear_chance(power: int) -> float:
	return _clear_chance_for_floor(power, floor_number)

func _clear_chance_for_floor(power: int, target_floor: int) -> float:
	var threat := 620 + maxi(0, target_floor - 4) * 85
	return clampf(0.72 + float(power - threat) / 1100.0, 0.18, 0.985)

func _skip_run() -> void:
	if page != "run":
		return
	while page == "run" and run_stage < run_max_stages:
		if not _resolve_stage():
			break
	if page == "run":
		_complete_run()

func _toggle_run_pause() -> void:
	if run_active:
		run_timer.stop()
		run_active = false
	else:
		run_timer.start()
		run_active = true
	_save_progress()
	_build_ui()

func _toggle_farm() -> void:
	farm_enabled = not farm_enabled
	if not farm_enabled:
		idle_progress_seconds = 0
	_save_progress()
	_build_ui()

func _complete_run() -> void:
	if page != "run":
		return
	run_active = false
	run_timer.stop()
	run_stage = run_max_stages
	run_succeeded = true
	var completed_floor := floor_number
	last_run_floor = completed_floor
	player_gold += 186 + completed_floor * 4
	_add_experience(420 + completed_floor * 8)
	run_loot.clear()
	var drop_count := 1 if randf() < 0.68 else 2
	for i in range(drop_count):
		var item := _generate_item(run_boss_defeated, completed_floor)
		if inventory.size() < MAX_BAG_SIZE:
			inventory.append(item)
			run_loot.append(item)
		else:
			player_gold += int(item.sell)
	floor_number += 1
	page = "loot"
	_save_progress()
	_build_ui()

func _fail_run() -> void:
	run_active = false
	run_timer.stop()
	run_succeeded = false
	last_run_floor = floor_number
	player_gold += 55
	_add_experience(100)
	run_loot.clear()
	page = "loot"
	_save_progress()
	_build_ui()

func _generate_item(boss_bonus: bool = false, target_floor: int = -1) -> Dictionary:
	var slot: String = GEAR_SLOTS[randi() % GEAR_SLOTS.size()]
	var roll := randf()
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
	var power: int = tier * 18 + randi_range(7, 17) + quality_bonus
	var armor := int(power * (0.82 if ["Helmet", "Chest", "Gloves", "Boots"].has(slot) else 0.0))
	var stats := {}
	var affixes := 1
	if quality == "RARE": affixes = 2
	if quality == "EPIC": affixes = 3
	if quality == "LEGENDARY": affixes = 4
	var candidates := ATTRIBUTES.duplicate()
	for i in range(affixes):
		var selected: String = candidates.pop_at(randi() % candidates.size())
		stats[selected] = randi_range(1, 3 + tier + int(quality_bonus / 10))
	if quality == "EPIC" or quality == "LEGENDARY":
		stats["Crit"] = randi_range(1, 3 + tier)
	var sell_value: int = 28 + tier * 12 + quality_bonus * 4 + randi_range(0, 16)
	var item_name: String = GEAR_NAMES[slot][randi() % GEAR_NAMES[slot].size()]
	return {"name": item_name, "slot": slot, "power": power, "quality": quality, "tier": tier, "armor": armor, "stats": stats, "sell": sell_value, "temper": 0, "status": ""}

func _equip_item(item: Dictionary) -> void:
	if not inventory.has(item):
		return
	var slot: String = item.slot
	var displaced: Dictionary = equipment[slot]
	displaced["slot"] = slot
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

func _simulate_offline_runs(run_count: int) -> void:
	for i in range(run_count):
		var completed_floor := floor_number
		var success_chance := clampf(_clear_chance_for_floor(_hero_power(), completed_floor) - 0.08, 0.18, 0.985)
		if randf() <= success_chance:
			pending_idle_runs += 1
			pending_idle_ash += 186 + completed_floor * 4
			pending_idle_xp += 420 + completed_floor * 8
			if randf() < 0.48:
				var item := _generate_item(true, completed_floor)
				if inventory.size() < MAX_BAG_SIZE:
					inventory.append(item)
					pending_idle_gear += 1
				else:
					pending_idle_ash += int(item.sell)
					pending_idle_salvaged += 1
			floor_number += 1
		else:
			pending_idle_fails += 1
			pending_idle_ash += 52 + completed_floor * 2
			pending_idle_xp += 105 + completed_floor * 3

func _accrue_offline_time() -> void:
	var now := int(Time.get_unix_time_from_system())
	if last_saved_at <= 0:
		last_saved_at = now
		return
	if not farm_enabled:
		idle_progress_seconds = 0
		last_saved_at = now
		return
	var elapsed := clampi(now - last_saved_at, 0, MAX_OFFLINE_SECONDS)
	var total_seconds := idle_progress_seconds + elapsed
	var completed_runs := floori(float(total_seconds) / float(DUNGEON_RUN_SECONDS))
	idle_progress_seconds = total_seconds % DUNGEON_RUN_SECONDS
	if completed_runs > 0:
		_simulate_offline_runs(completed_runs)
	last_saved_at = now

func _load_progress() -> void:
	var save := ConfigFile.new()
	if save.load("user://emberfall.save") != OK:
		last_saved_at = int(Time.get_unix_time_from_system())
		return
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
	idle_progress_seconds = idle_progress_seconds % DUNGEON_RUN_SECONDS
	farm_enabled = bool(save.get_value("idle", "farm_enabled", farm_enabled))
	last_saved_at = int(save.get_value("idle", "saved_at", Time.get_unix_time_from_system()))

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
	save.set_value("hero", "class", character_class)
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
	last_saved_at = int(Time.get_unix_time_from_system())
	save.set_value("idle", "saved_at", last_saved_at)
	save.save("user://emberfall.save")
