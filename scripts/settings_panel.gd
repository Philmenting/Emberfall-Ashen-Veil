extends Control
## Modal options and concise game help. Opening it pauses the current expedition.
var game: Control
var help_open := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()

func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var shade:=ColorRect.new()
	shade.color=Color(0.015,0.02,0.03,0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel: PanelContainer=game._panel(game.PANEL,game.GOLD,14)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left=100
	panel.offset_right=-100
	panel.offset_top=28
	panel.offset_bottom=-28
	add_child(panel)
	var stack:=VBoxContainer.new()
	stack.add_theme_constant_override("separation",10)
	panel.add_child(stack)
	stack.add_child(game._label("EXPEDITION PAUSED" if game.page=="run" else "EMBERFALL  /  OPTIONS",18,game.GOLD,true))
	var tabs:=HBoxContainer.new()
	stack.add_child(tabs)
	tabs.add_child(game._button("SETTINGS",game.PANEL_LIGHT,12,func(): help_open=false; _build()))
	tabs.add_child(game._button("HOW TO PLAY",game.PANEL_LIGHT,12,func(): help_open=true; _build()))
	var scroll:=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	stack.add_child(scroll)
	var content:=VBoxContainer.new()
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",10)
	scroll.add_child(content)
	if help_open: _help(content)
	else: _options(content)
	var actions:=HBoxContainer.new()
	stack.add_child(actions)
	var close: Button=game._button("RESUME" if game.menu_resume_run else "CLOSE",game.PANEL_LIGHT,13,game._close_settings)
	close.name="CloseSettings"
	actions.add_child(close)
	var leave: Button=game._button("SAVE & EXIT",game.RED,13,game._save_and_exit)
	leave.name="SaveAndExit"
	actions.add_child(leave)

func _options(parent: VBoxContainer) -> void:
	for key in ["master","music","effects"]:
		var row:=HBoxContainer.new()
		row.custom_minimum_size.y=44
		parent.add_child(row)
		var label: Label=game._label(String(key).to_upper(),12,game.PALE)
		label.custom_minimum_size.x=88
		row.add_child(label)
		var slider:=HSlider.new()
		slider.name=String(key).capitalize()+"Volume"
		slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		slider.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		slider.custom_minimum_size.y=32
		slider.max_value=100
		slider.step=5
		slider.value=float(game.preferences[key])*100
		row.add_child(slider)
		var amount: Label=game._label("%d%%" % slider.value,12,game.GOLD)
		amount.custom_minimum_size.x=46
		amount.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(amount)
		slider.value_changed.connect(func(value: float):
			amount.text="%d%%" % value
			game._change_preference(key,value/100.0,false)
		)
		slider.drag_ended.connect(func(_changed: bool): game._save_progress())
	var audio_test: Button=game._button("PLAY EFFECT PREVIEW",game.PANEL_LIGHT,11,func(): game.audio.cue("nova"))
	audio_test.name="PreviewAudio"
	parent.add_child(audio_test)
	var modes:=HBoxContainer.new()
	parent.add_child(modes)
	for battery in [false,true]:
		var label: String="BATTERY  /  30 FPS" if battery else "BALANCED  /  60 FPS"
		var button: Button=game._button(label,Color("31443a") if game.preferences.battery==battery else game.PANEL_LIGHT,11,func(): game._change_preference("battery",battery); _build())
		button.name="BatteryMode" if battery else "BalancedMode"
		modes.add_child(button)
	parent.add_child(game._paragraph_label("Battery mode reduces 3D resolution and disables shadows. Combat and offline rewards are unchanged. Frame rates are targets, not guarantees.",11,game.MUTED))
	var numbers: Button=game._button("DAMAGE NUMBERS: "+("ON" if game.preferences.numbers else "OFF"),game.PANEL_LIGHT,11,func(): game._change_preference("numbers",not game.preferences.numbers); _build())
	numbers.name="DamageNumbers"
	parent.add_child(numbers)

func _help(parent: VBoxContainer) -> void:
	for entry in [
		["AUTOMATIC EXPEDITIONS","Nyra walks, targets enemies, casts abilities and dodges on her own. Pause freezes the expedition; Skip to Loot simulates the remaining fight and ends repeat mode."],
		["AUTOMATIC TECHNIQUES","Open Gear > Skills to equip two techniques for each class. Your signature remains equipped. Protection responds to danger; then signature, slot I and slot II have priority when suitable. Each technique spends Mana and starts its cooldown on casting. Dodging can interrupt a cast without a refund. Ground bursts strike their marked position. You can change loadouts between expeditions."],
		["DUNGEON JOURNEYS","Each region has its own connected chambers and passage turns. The map follows your position. Nyra clears enemy packs, uses a healing well, breaks a guarded seal and opens the guardian reliquary automatically. The well restores up to 18% of maximum Life once per expedition. Pausing, skipping and offline farming preserve these steps."],
		["BOSS WARNINGS","Each guardian has a different ground attack: a bell ring, tidal lane, three grave blasts or crossing fire lanes. Unmarked ground is safe from that attack. Below half Life, guardians awaken with wider, faster attacks. Nyra dodges automatically when ready; gear and the dodge cooldown still matter. Skip and offline farming use the same rules."],
		["CHOOSE A BUILD","Strength powers Vowkeeper, Intellect powers Arcanist and Dexterity powers Ranger. Vitality increases Life; Spirit improves Mana and its recovery on hits. Compare the six stat changes before equipping. Class changes refund spent points."],
		["CLASS-ATTUNED LOOT","New finds carry an attunement for the class that earned them and always include its primary attribute. Other affixes vary. All classes can equip every item; attunement is a recommendation, not a restriction. Existing equipment keeps its stats. Compare actual changes before replacing tempered gear."],
		["ARCANIST: MANA WARD","Mana Ward absorbs up to 35% of damage after armor at a cost of 2 Mana per damage absorbed. It always reserves enough Mana for one Nova. When the reserve is reached, incoming hits deal full damage. Nova refunds 25% of its cost. Mana and Spirit therefore support both offense and survival."],
		["ARCANIST: SPELL DISTANCE","Between attacks, the Arcanist walks away from nearby melee enemies when a safe path exists. Casting stays stationary and ground attacks still require a ready dodge. Veil Nova strikes a broad area around its target, slows enemies and interrupts casters. Its violet pulse shows the affected area."],
		["FARM WITH CONFIDENCE","Choose a cleared Farm Floor in camp. Reliable means at least 95% of the current combat patterns succeed. Recheck after changing gear. Repeat stops after a visible defeat."],
		["WHILE YOU ARE AWAY","Offline farming is enabled in the hero attributes rail. Up to 24 hours are calculated when you return. Paused expeditions stay paused. Claim Gold and XP from the report; relics are already in your bag. Overflow gear is sold."],
		["KEEP YOUR PROGRESS","Progress is saved on important actions and every five seconds in combat. This version is solo and local: uninstalling or clearing app data removes the save. Save & Exit resumes farming after closing only when you leave an active, unpaused expedition or are in camp."]
	]:
		parent.add_child(game._label(entry[0],12,game.GOLD,true))
		parent.add_child(game._paragraph_label(entry[1],12,game.PALE))
