extends SceneTree

const SettingsPanel = preload("res://scripts/settings_panel.gd")
const SaveStore = preload("res://scripts/save_store.gd")

var checks := 0
var failures := 0
var game: Control

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)

func has_label_text(node: Node, fragment: String) -> bool:
	if node is Label and node.text.contains(fragment): return true
	for child in node.get_children():
		if has_label_text(child, fragment): return true
	return false

func run_checks() -> void:
	var cloud = root.get_node("CloudSave")
	var session := NakamaSession.new()
	session._valid = true
	session._expire_time = int(Time.get_unix_time_from_system()) + 3600
	session._user_id = "fellowship-ui-user"
	cloud.session = session
	cloud.busy = false
	cloud.status_text = "Guest account connected · test identity"
	var fellowship = root.get_node("Fellowship")
	fellowship.busy = false
	fellowship.status_text = "Fellowship ready · Ash Lanterns"
	fellowship.current_fellowship = {
		"id": "fellowship-ui-fixture",
		"name": "Ash Lanterns",
		"description": "A test fellowship for the Ashen Veil.",
		"open": true,
		"members": 2,
		"capacity": 40
	}
	fellowship.members = [
		{"username": "Veilwalker-One", "online": true, "role": 0},
		{"username": "Veilwalker-Two", "online": false, "role": 2}
	]
	fellowship.messages = [
		{"id": "first", "username": "Veilwalker-One", "text": "The bell is quiet."}
	]
	var progression = root.get_node("Progression")
	progression.profile = {
		"class_name": "Ranger", "level": 2, "gold": 1200, "xp": 450, "highest_floor": 3,
		"attribute_points": 1, "farm_floor": 2, "farm_enabled": true,
		"equipment": {"Weapon": {"id": "weapon-1", "name": "Ember Edge", "quality": "RARE", "power": 66, "tier": 1, "temper": 0}},
		"inventory": [{"id": "server-loot", "name": "Ash Bow", "slot": "Weapon", "quality": "EPIC", "tier": 2, "power": 112, "sell": 240}]
	}
	progression.settlement = {"runs": 3, "wins": 2, "fails": 1, "gold": 500, "xp": 900}
	progression.status_text = "Server profile ready · test fixture"

	game = load("res://Main.tscn").instantiate()
	game.save_store = SaveStore.new("user://fellowship-ui-" + str(Time.get_ticks_usec()))
	game.clock_source = func(): return 1790512000.0
	root.add_child(game)
	await process_frame
	game._finish_welcome(false)
	var menu = SettingsPanel.new()
	menu.game = game
	menu.online_open = true
	game.add_child(menu)
	await process_frame
	await process_frame

	var status: Label = menu.find_child("FellowshipStatus", true, false)
	var chat_input: LineEdit = menu.find_child("FellowshipChatInput", true, false)
	var send: Button = menu.find_child("SendFellowshipMessage", true, false)
	var leave: Button = menu.find_child("LeaveFellowship", true, false)
	var chat_scroll: ScrollContainer = menu.find_child("FellowshipChatScroll", true, false)
	var chat_log: VBoxContainer = menu.find_child("FellowshipChatMessages", true, false)
	var progression_status: Label = menu.find_child("ProgressionStatus", true, false)
	check(status != null and status.text.contains("Ash Lanterns"), "online options render the active fellowship status")
	check(progression_status != null and has_label_text(menu, "Ranger · Lv 2 · 1200 Gold") and has_label_text(menu, "Last server settlement: 3 runs"), "online options render the separate server-owned test profile and AFK report")
	check(menu.find_child("RefreshServerProgression", true, false) != null and menu.find_child("ServerFarmToggle", true, false) != null and has_label_text(menu, "not yet the local dungeon character"), "server profile exposes bounded farm controls and explains its separation from local gameplay")
	check(menu.find_child("SetServerClass", true, false) != null and menu.find_child("AllocateServerAttribute", true, false) != null and menu.find_child("TemperServerWeapon", true, false) != null and menu.find_child("EquipServerItem", true, false) != null and menu.find_child("SellServerItem", true, false) != null, "server profile exposes validated class, attribute, temper, equip and sell actions")
	check(has_label_text(menu, "Veilwalker-One") and has_label_text(menu, "Veilwalker-Two"), "fellowship roster renders server member names")
	check(chat_input != null and chat_input.max_length == 180 and send != null and leave != null, "chat, send, and leave controls are present with the message limit")
	check(chat_scroll != null and chat_scroll.custom_minimum_size.y >= 110, "persistent chat has a bounded, scrollable landscape panel")
	check(chat_log != null and chat_log.get_child_count() == 1 and chat_log.get_child(0).text.contains("The bell is quiet"), "recent group messages render in the chat history")
	if status != null and chat_log != null:
		fellowship.status_text = "New message received"
		fellowship.messages.append({"id": "second", "username": "Veilwalker-Two", "text": "I see the lanterns."})
		fellowship.state_changed.emit()
		await process_frame
		check(status.text == "New message received" and chat_log.get_child_count() == 2 and chat_log.get_child(1).text.contains("I see the lanterns"), "live chat updates status and message list without rebuilding the panel")
	else:
		check(false, "live chat controls exist before an incoming message")
	if progression_status != null:
		progression.status_text = "Server progression refreshed"
		progression.state_changed.emit()
		await process_frame
		check(progression_status.text == "Server progression refreshed", "server progression status updates live without rebuilding options")
	else:
		check(false, "server progression status exists before a live update")

	fellowship.current_fellowship.clear()
	fellowship.members.clear()
	fellowship.messages.clear()
	fellowship.open_fellowships = [{
		"id": "open-fellowship-fixture",
		"name": "Open Flame",
		"description": "An open test group.",
		"open": true,
		"members": 1,
		"capacity": 40
	}]
	fellowship.status_text = "Fellowship board ready"
	menu._build()
	await process_frame
	check(menu.find_child("CreateFellowship", true, false) != null and menu.find_child("FellowshipSearch", true, false) != null and menu.find_child("JoinFellowship", true, false) != null, "unaffiliated players can create, search, and join open fellowships")

	if game != null and is_instance_valid(game): game.free()
	await process_frame
	print("FELLOWSHIP UI SMOKE: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
