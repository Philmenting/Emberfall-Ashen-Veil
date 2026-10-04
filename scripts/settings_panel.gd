extends Control
## Modal options and concise game help. Opening it pauses the current expedition.
var game: Control
var help_open := false
var backup_open := false
var online_open := false
var beta_open := false
var confirm_cloud_restore := false
var confirm_cloud_overwrite := false

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
	var insets: Dictionary=game._mobile_insets()
	panel.offset_left=60+int(insets.left)
	panel.offset_right=-60-int(insets.right)
	panel.offset_top=28+int(insets.top)
	panel.offset_bottom=-28-int(insets.bottom)
	add_child(panel)
	var stack:=VBoxContainer.new()
	stack.add_theme_constant_override("separation",10)
	panel.add_child(stack)
	stack.add_child(game._label("EXPEDITION PAUSED" if game.page=="run" else "EMBERFALL  /  OPTIONS",18,game.GOLD,true))
	var tabs:=HBoxContainer.new()
	stack.add_child(tabs)
	var settings_tab: Button=game._button("SETTINGS",game.PANEL_LIGHT,12,func(): _select_tab("settings"))
	settings_tab.name="SettingsTab"
	tabs.add_child(settings_tab)
	var backup_tab: Button=game._button("SAVE BACKUP",game.PANEL_LIGHT,12,func(): _select_tab("backup"))
	backup_tab.name="SaveBackupTab"
	tabs.add_child(backup_tab)
	if OS.has_feature("nakama_local_test"):
		var online_tab: Button=game._button("ONLINE TEST",game.PANEL_LIGHT,12,func(): _select_tab("online"))
		online_tab.name="OnlineTestTab"
		tabs.add_child(online_tab)
	var help_tab: Button=game._button("HOW TO PLAY",game.PANEL_LIGHT,12,func(): _select_tab("help"))
	help_tab.name="HowToPlayTab"
	tabs.add_child(help_tab)
	var beta_tab: Button=game._button("BETA / PRIVACY",game.PANEL_LIGHT,11,func(): _select_tab("beta"))
	beta_tab.name="BetaInfoTab"
	tabs.add_child(beta_tab)
	var scroll:=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	stack.add_child(scroll)
	var content:=VBoxContainer.new()
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",10)
	scroll.add_child(content)
	if beta_open: _beta(content)
	elif online_open: _online(content)
	elif backup_open: _backup(content)
	elif help_open: _help(content)
	else: _options(content)
	var actions:=HBoxContainer.new()
	stack.add_child(actions)
	var close: Button=game._button("RESUME" if game.menu_resume_run else "CLOSE",game.PANEL_LIGHT,13,game._close_settings)
	close.name="CloseSettings"
	actions.add_child(close)
	var leave: Button=game._button("SAVE & EXIT",game.RED,13,game._save_and_exit)
	leave.name="SaveAndExit"
	actions.add_child(leave)

func _select_tab(tab: String) -> void:
	backup_open=tab=="backup"
	help_open=tab=="help"
	online_open=tab=="online"
	beta_open=tab=="beta"
	confirm_cloud_restore=false
	confirm_cloud_overwrite=false
	_build()

func _online(parent: VBoxContainer) -> void:
	var cloud = get_node_or_null("/root/CloudSave")
	if cloud==null:
		parent.add_child(game._paragraph_label("Local cloud storage is unavailable in this build.",12,game.MUTED))
		return
	var can_manage_account: bool = game.page=="camp" and not cloud.busy
	var has_local_identity: bool = cloud.local_guest_exists()
	var status: Label=game._paragraph_label(cloud.status_text,12,game.GOLD if cloud.guest_connected() else game.MUTED)
	status.name="CloudStatus"
	parent.add_child(status)
	if has_local_identity:
		parent.add_child(game._label("LOCAL GUEST ACCOUNT",12,game.GOLD,true))
		parent.add_child(game._paragraph_label("This installation has a randomly generated guest identity. Clearing app data or reinstalling removes it unless you first create and keep a one-time transfer key.",12,game.PALE))
		var account:=HBoxContainer.new()
		parent.add_child(account)
		var connect_button: Button=game._button("CONNECT GUEST ACCOUNT" if not cloud.guest_connected() else "GUEST ACCOUNT CONNECTED",game.PANEL_LIGHT,11,func(): _connect_online())
		connect_button.name="ConnectGuestAccount"
		connect_button.disabled=not can_manage_account or cloud.guest_connected()
		account.add_child(connect_button)
		var refresh: Button=game._button("CHECK CLOUD",game.PANEL_LIGHT,11,func(): _refresh_cloud())
		refresh.name="RefreshCloudBackup"
		refresh.disabled=cloud.busy or not cloud.guest_connected()
		account.add_child(refresh)
		if cloud.guest_connected():
			var existing_transfer_code: String = cloud.transfer_code()
			if existing_transfer_code.is_empty():
				parent.add_child(game._paragraph_label("Create a one-time transfer key before changing devices. It grants account access to whoever holds it; copy it privately. Importing it on a new installation disables that key.",11,game.PALE))
				var create_transfer: Button=game._button("CREATE ACCOUNT TRANSFER KEY",game.GOLD,11,func(): _create_transfer_key())
				create_transfer.name="CreateAccountTransferKey"
				create_transfer.disabled=not can_manage_account
				parent.add_child(create_transfer)
			else:
				parent.add_child(game._label("ONE-TIME ACCOUNT TRANSFER KEY  /  KEEP PRIVATE",11,game.GOLD,true))
				parent.add_child(game._paragraph_label("Anyone with this key can sign in to the guest account and its cloud backup. Importing it on another installation disables the key.",11,game.RED))
				var transfer_field:=TextEdit.new()
				transfer_field.name="AccountTransferKey"
				transfer_field.custom_minimum_size.y=52
				transfer_field.size_flags_horizontal=Control.SIZE_EXPAND_FILL
				transfer_field.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY
				transfer_field.editable=false
				transfer_field.text=existing_transfer_code
				parent.add_child(transfer_field)
				var transfer_actions:=HBoxContainer.new()
				parent.add_child(transfer_actions)
				var copy_transfer: Button=game._button("COPY TRANSFER KEY",game.PANEL_LIGHT,10,func():
					DisplayServer.clipboard_set(existing_transfer_code)
					status.text="Transfer key copied to clipboard. Remove it from the clipboard after use."
				)
				copy_transfer.name="CopyAccountTransferKey"
				copy_transfer.disabled=not can_manage_account
				transfer_actions.add_child(copy_transfer)
				var revoke_transfer: Button=game._button("REVOKE KEY",game.RED,10,func(): _revoke_transfer_key())
				revoke_transfer.name="RevokeAccountTransferKey"
				revoke_transfer.disabled=not can_manage_account
				transfer_actions.add_child(revoke_transfer)
	else:
		parent.add_child(game._label("ADD AN EXISTING ACCOUNT TO THIS INSTALLATION",12,game.GOLD,true))
		parent.add_child(game._paragraph_label("On the old installation, create a one-time transfer key and copy it here. Import the key before creating a new guest account. This signs in to the same account; the old installation keeps its own login. Restoring the cloud save remains a separate, confirmed action.",11,game.PALE))
		var transfer_input:=TextEdit.new()
		transfer_input.name="AccountTransferKeyInput"
		transfer_input.custom_minimum_size.y=52
		transfer_input.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		transfer_input.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY
		parent.add_child(transfer_input)
		var transfer_actions:=HBoxContainer.new()
		parent.add_child(transfer_actions)
		var import_transfer: Button=game._button("IMPORT ACCOUNT KEY",game.GOLD,11,func(): _import_transfer_key(transfer_input.text))
		import_transfer.name="ImportAccountTransferKey"
		import_transfer.disabled=not can_manage_account
		transfer_actions.add_child(import_transfer)
		var paste_transfer: Button=game._button("PASTE KEY",game.PANEL_LIGHT,11,func(): transfer_input.text=DisplayServer.clipboard_get())
		paste_transfer.name="PasteAccountTransferKey"
		paste_transfer.disabled=not can_manage_account
		transfer_actions.add_child(paste_transfer)
		var create_guest: Button=game._button("START NEW GUEST",game.PANEL_LIGHT,11,func(): _connect_online())
		create_guest.name="CreateGuestAccount"
		create_guest.disabled=not can_manage_account
		transfer_actions.add_child(create_guest)
	_progression(parent, cloud)
	_fellowships(parent, cloud)
	parent.add_child(game._label("MANUAL CLOUD BACKUP",12,game.GOLD,true))
	parent.add_child(game._paragraph_label("This stores the same complete local save as the private backup code. Only this guest account can read or write it. There is no automatic sync. Nyras local currency, loot and progress remain client-side; the separate server test profile below does not replace them.",12,game.PALE))
	if cloud.has_cloud_backup:
		parent.add_child(game._paragraph_label("Saved: %s" % _format_cloud_time(cloud.cloud_uploaded_at),11,game.MUTED))
	var can_change_cloud: bool=game.page=="camp" and not cloud.busy and cloud.guest_connected()
	var upload_label: String="CONFIRM CLOUD REPLACEMENT" if confirm_cloud_overwrite else ("CREATE CLOUD BACKUP" if not cloud.has_cloud_backup else "UPDATE CLOUD BACKUP")
	var upload: Button=game._button(upload_label,game.GOLD,11,func():
		if cloud.has_cloud_backup and not confirm_cloud_overwrite:
			confirm_cloud_overwrite=true
			_build()
		else:
			_upload_online_backup()
	)
	upload.name="UploadCloudBackup"
	upload.disabled=not can_change_cloud
	parent.add_child(upload)
	if confirm_cloud_overwrite:
		parent.add_child(game._paragraph_label("This replaces the existing cloud backup with the current save.",11,game.RED))
		var cancel_upload: Button=game._button("CANCEL",game.PANEL_LIGHT,10,func(): confirm_cloud_overwrite=false; _build())
		parent.add_child(cancel_upload)
	var restore: Button=game._button("RESTORE CLOUD BACKUP",game.RED,11,func(): confirm_cloud_restore=true; _build())
	restore.name="RestoreCloudBackup"
	restore.disabled=not can_change_cloud or not cloud.has_cloud_backup
	parent.add_child(restore)
	if confirm_cloud_restore:
		parent.add_child(game._paragraph_label("Restore this backup? The local save will be replaced. A recovery copy is kept and can be restored under Save Backup.",11,game.RED))
		var confirm: Button=game._button("CONFIRM RESTORE",game.RED,10,func(): _restore_cloud_backup())
		confirm.name="ConfirmCloudRestore"
		confirm.disabled=not can_change_cloud or not cloud.has_cloud_backup
		parent.add_child(confirm)
		var cancel: Button=game._button("CANCEL",game.PANEL_LIGHT,10,func(): confirm_cloud_restore=false; _build())
		parent.add_child(cancel)
	if game.page!="camp": parent.add_child(game._paragraph_label("Uploads and restores are available from camp only.",11,game.MUTED))
	parent.add_child(game._paragraph_label("Local test server: 127.0.0.1:7350. The Android emulator reaches the development machine through adb reverse.",10,game.MUTED))

func _progression(parent: VBoxContainer, cloud) -> void:
	parent.add_child(HSeparator.new())
	parent.add_child(game._label("SERVER PROGRESSION  /  TEST PROFILE",12,game.GOLD,true))
	var service = get_node_or_null("/root/Progression")
	if service == null:
		parent.add_child(game._paragraph_label("Server progression is unavailable in this build.",11,game.MUTED))
		return
	if not service.state_changed.is_connected(_on_progression_state_changed):
		service.state_changed.connect(_on_progression_state_changed)
	var status: Label = game._paragraph_label(service.status_text,11,game.MUTED)
	status.name = "ProgressionStatus"
	parent.add_child(status)
	if not cloud.guest_connected():
		parent.add_child(game._paragraph_label("Connect a guest account to create a server-owned profile. It is separate from the local character and does not import or overwrite the current save.",11,game.PALE))
		return
	var profile: Dictionary = service.profile
	if profile.is_empty():
		parent.add_child(game._paragraph_label("No server profile has been loaded yet.",11,game.PALE))
	else:
		parent.add_child(game._paragraph_label("%s · Lv %d · %d Gold · %d / %d XP\nNext floor %d · farming floor %d · bag %d / 20" % [String(profile.get("class_name", "Vowkeeper")), int(profile.get("level", 1)), int(profile.get("gold", 0)), int(profile.get("xp", 0)), int(profile.get("level", 1)) * 1000, int(profile.get("highest_floor", 1)), int(profile.get("farm_floor", 1)), profile.get("inventory", []).size()],11,game.PALE))
		var report: Dictionary = service.settlement
		if int(report.get("runs", 0)) > 0:
			parent.add_child(game._paragraph_label("Last server settlement: %d runs · %d wins · %d failures · +%d Gold · +%d XP" % [int(report.get("runs", 0)), int(report.get("wins", 0)), int(report.get("fails", 0)), int(report.get("gold", 0)), int(report.get("xp", 0))],10,game.GREEN))
	var actions := HBoxContainer.new()
	parent.add_child(actions)
	var can_manage: bool = game.page == "camp" and not service.busy
	var refresh: Button = game._button("SETTLE / REFRESH",game.PANEL_LIGHT,10,func(): _refresh_server_profile())
	refresh.name = "RefreshServerProgression"
	refresh.disabled = not can_manage
	actions.add_child(refresh)
	if not profile.is_empty():
		var farm_actions := HBoxContainer.new()
		parent.add_child(farm_actions)
		var previous: Button = game._button("FARM −",game.PANEL_LIGHT,10,func(): _set_server_farm(int(profile.get("farm_floor", 1)) - 1, bool(profile.get("farm_enabled", true))))
		previous.disabled = not can_manage or int(profile.get("farm_floor", 1)) <= 1
		farm_actions.add_child(previous)
		var next: Button = game._button("FARM +",game.PANEL_LIGHT,10,func(): _set_server_farm(int(profile.get("farm_floor", 1)) + 1, bool(profile.get("farm_enabled", true))))
		next.disabled = not can_manage or int(profile.get("farm_floor", 1)) >= int(profile.get("highest_floor", 1))
		farm_actions.add_child(next)
		var toggle_label := "PAUSE SERVER FARM" if bool(profile.get("farm_enabled", true)) else "RESUME SERVER FARM"
		var toggle: Button = game._button(toggle_label,game.GOLD,10,func(): _set_server_farm(int(profile.get("farm_floor", 1)), not bool(profile.get("farm_enabled", true))))
		toggle.name = "ServerFarmToggle"
		toggle.disabled = not can_manage
		farm_actions.add_child(toggle)
		var class_actions := HBoxContainer.new()
		parent.add_child(class_actions)
		var class_picker := OptionButton.new()
		class_picker.name = "ServerClassPicker"
		class_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for class_key in ["Vowkeeper", "Arcanist", "Ranger"]: class_picker.add_item(class_key)
		class_picker.select(maxi(0, ["Vowkeeper", "Arcanist", "Ranger"].find(String(profile.get("class_name", "Vowkeeper")))))
		class_actions.add_child(class_picker)
		var choose_class: Button = game._button("SET TEST CLASS",game.PANEL_LIGHT,10,func(): _set_server_class(class_picker.get_item_text(class_picker.selected)))
		choose_class.name = "SetServerClass"
		choose_class.disabled = not can_manage
		class_actions.add_child(choose_class)
		var attribute_actions := HBoxContainer.new()
		parent.add_child(attribute_actions)
		var attribute_picker := OptionButton.new()
		attribute_picker.name = "ServerAttributePicker"
		attribute_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for attribute in ["Strength", "Dexterity", "Intellect", "Vitality", "Spirit"]: attribute_picker.add_item(attribute)
		attribute_actions.add_child(attribute_picker)
		var allocate: Button = game._button("SPEND ATTRIBUTE POINT  ·  %d LEFT" % int(profile.get("attribute_points", 0)),game.PANEL_LIGHT,10,func(): _allocate_server_attribute(attribute_picker.get_item_text(attribute_picker.selected)))
		allocate.name = "AllocateServerAttribute"
		allocate.disabled = not can_manage or int(profile.get("attribute_points", 0)) <= 0
		attribute_actions.add_child(allocate)
		parent.add_child(game._label("SERVER EQUIPMENT",10,game.GOLD,true))
		var equipment: Dictionary = profile.get("equipment", {})
		for slot in ["Weapon", "Helmet", "Chest", "Gloves", "Boots", "Amulet"]:
			var item: Dictionary = equipment.get(slot, {})
			var gear_row := HBoxContainer.new()
			parent.add_child(gear_row)
			var gear_label: Label = game._paragraph_label("%s · %s · %s · PWR %d · +%d" % [slot, String(item.get("quality", "—")), String(item.get("name", "Empty")), int(item.get("power", 0)), int(item.get("temper", 0))],9,game.PALE)
			gear_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			gear_row.add_child(gear_label)
			var temper: Button = game._button("TEMPER",game.PANEL_LIGHT,9,func(): _temper_server_item(slot))
			temper.name = "TemperServer" + slot
			var temper_cost := 90 + int(item.get("tier", 1)) * 80 + int(item.get("temper", 0)) * 120
			temper.disabled = not can_manage or int(item.get("temper", 0)) >= 5 or int(profile.get("gold", 0)) < temper_cost
			gear_row.add_child(temper)
		var server_bag: Array = profile.get("inventory", [])
		parent.add_child(game._label("SERVER BAG  ·  %d / 20" % server_bag.size(),10,game.GOLD,true))
		if server_bag.is_empty():
			parent.add_child(game._paragraph_label("The server bag is empty. AFK loot is generated on the next settlement.",9,game.MUTED))
		else:
			for item_value in server_bag:
				if not item_value is Dictionary: continue
				var bag_row := HBoxContainer.new()
				parent.add_child(bag_row)
				var item_label: Label = game._paragraph_label("%s · %s %s · T%d · PWR %d" % [String(item_value.get("slot", "Gear")), String(item_value.get("quality", "COMMON")), String(item_value.get("name", "Recovered item")), int(item_value.get("tier", 1)), int(item_value.get("power", 0))],9,game.PALE)
				item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				bag_row.add_child(item_label)
				var equip_item: Button = game._button("EQUIP",game.PANEL_LIGHT,9,func(): _equip_server_item(String(item_value.get("id", ""))))
				equip_item.name = "EquipServerItem"
				equip_item.disabled = not can_manage
				bag_row.add_child(equip_item)
				var sell_item: Button = game._button("SELL · %d" % int(item_value.get("sell", 0)),game.PANEL_LIGHT,9,func(): _sell_server_item(String(item_value.get("id", ""))))
				sell_item.name = "SellServerItem"
				sell_item.disabled = not can_manage
				bag_row.add_child(sell_item)
	parent.add_child(game._paragraph_label("The server computes AFK time from its own clock, caps settlement at 24 hours, and owns this profile's currency, levels, inventory and gear actions. This test profile is not yet the local dungeon character.",10,game.MUTED))

func _on_progression_state_changed() -> void:
	if not is_inside_tree(): return
	var service = get_node_or_null("/root/Progression")
	var status := find_child("ProgressionStatus", true, false) as Label
	if service != null and status != null: status.text = service.status_text

func _refresh_server_profile() -> void:
	var service = get_node_or_null("/root/Progression")
	if service == null: return
	await service.refresh_profile()
	if is_inside_tree(): _build()

func _set_server_farm(farm_floor: int, farm_enabled: bool) -> void:
	var service = get_node_or_null("/root/Progression")
	if service == null: return
	await service.set_farm_settings(farm_floor, farm_enabled)
	if is_inside_tree(): _build()

func _set_server_class(class_key: String) -> void:
	var service = get_node_or_null("/root/Progression")
	if service == null: return
	await service.select_class(class_key)
	if is_inside_tree(): _build()

func _allocate_server_attribute(attribute: String) -> void:
	var service = get_node_or_null("/root/Progression")
	if service == null: return
	await service.allocate_attribute(attribute)
	if is_inside_tree(): _build()

func _equip_server_item(item_id: String) -> void:
	var service = get_node_or_null("/root/Progression")
	if service == null: return
	await service.equip_item(item_id)
	if is_inside_tree(): _build()

func _sell_server_item(item_id: String) -> void:
	var service = get_node_or_null("/root/Progression")
	if service == null: return
	await service.sell_item(item_id)
	if is_inside_tree(): _build()

func _temper_server_item(slot: String) -> void:
	var service = get_node_or_null("/root/Progression")
	if service == null: return
	await service.temper_item(slot)
	if is_inside_tree(): _build()

func _fellowships(parent: VBoxContainer, cloud) -> void:
	parent.add_child(HSeparator.new())
	parent.add_child(game._label("FELLOWSHIP BOARD  /  ONLINE TEST",12,game.GOLD,true))
	var service = get_node_or_null("/root/Fellowship")
	if service == null:
		parent.add_child(game._paragraph_label("Fellowship services are unavailable in this build.",11,game.MUTED))
		return
	if not service.state_changed.is_connected(_on_fellowship_state_changed):
		service.state_changed.connect(_on_fellowship_state_changed)
	var status: Label = game._paragraph_label(service.status_text,11,game.MUTED)
	status.name = "FellowshipStatus"
	parent.add_child(status)
	if not cloud.guest_connected():
		parent.add_child(game._paragraph_label("Connect a guest account above to create or browse server-hosted groups and their shared chat.",11,game.PALE))
		return
	var board_actions := HBoxContainer.new()
	parent.add_child(board_actions)
	var refresh: Button = game._button("REFRESH FELLOWSHIPS",game.PANEL_LIGHT,10,func(): _refresh_fellowship_board(""))
	refresh.name = "RefreshFellowships"
	refresh.disabled = service.busy
	board_actions.add_child(refresh)
	if not service.current_fellowship.is_empty():
		var group: Dictionary = service.current_fellowship
		parent.add_child(game._label(String(group.get("name", "Fellowship")).to_upper(),13,game.GOLD,true))
		parent.add_child(game._paragraph_label("%d / %d members · %s" % [int(group.get("members", 0)), int(group.get("capacity", 0)), String(group.get("description", "A fellowship of veilwalkers."))],10,game.PALE))
		var roster_title: Label = game._label("MEMBERS",10,game.GOLD,true)
		parent.add_child(roster_title)
		var roster := HFlowContainer.new()
		roster.add_theme_constant_override("h_separation", 12)
		roster.add_theme_constant_override("v_separation", 4)
		parent.add_child(roster)
		if service.members.is_empty():
			roster.add_child(game._label("Member list unavailable",10,game.MUTED))
		else:
			for member in service.members:
				var online_marker := "● " if bool(member.get("online", false)) else "○ "
				roster.add_child(game._label(online_marker + String(member.get("username", "Veilwalker")),10,game.PALE))
		var leave: Button = game._button("LEAVE FELLOWSHIP",game.RED,10,func(): _leave_fellowship())
		leave.name = "LeaveFellowship"
		leave.disabled = service.busy
		parent.add_child(leave)
		parent.add_child(game._label("PERSISTENT GROUP CHAT",10,game.GOLD,true))
		var chat_scroll := ScrollContainer.new()
		chat_scroll.name = "FellowshipChatScroll"
		chat_scroll.custom_minimum_size = Vector2(0, 118)
		chat_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chat_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		parent.add_child(chat_scroll)
		var chat_log := VBoxContainer.new()
		chat_log.name = "FellowshipChatMessages"
		chat_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chat_log.add_theme_constant_override("separation", 3)
		chat_scroll.add_child(chat_log)
		_render_fellowship_chat(chat_log, service)
		var chat_actions := HBoxContainer.new()
		parent.add_child(chat_actions)
		var chat_input := LineEdit.new()
		chat_input.name = "FellowshipChatInput"
		chat_input.placeholder_text = "Write to your fellowship …"
		chat_input.max_length = 180
		chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chat_actions.add_child(chat_input)
		var send: Button = game._button("SEND",game.GOLD,10,func(): _send_fellowship_message(chat_input))
		send.name = "SendFellowshipMessage"
		send.disabled = service.busy
		chat_actions.add_child(send)
		return
	parent.add_child(game._label("CREATE AN OPEN FELLOWSHIP",10,game.GOLD,true))
	var group_name := LineEdit.new()
	group_name.name = "FellowshipName"
	group_name.placeholder_text = "Name · 3–24 characters"
	group_name.max_length = 24
	parent.add_child(group_name)
	var group_description := LineEdit.new()
	group_description.name = "FellowshipDescription"
	group_description.placeholder_text = "Short description (optional)"
	group_description.max_length = 100
	parent.add_child(group_description)
	var create: Button = game._button("CREATE FELLOWSHIP",game.GOLD,10,func(): _create_fellowship(group_name.text, group_description.text))
	create.name = "CreateFellowship"
	create.disabled = service.busy
	parent.add_child(create)
	parent.add_child(game._label("FIND OPEN FELLOWSHIPS",10,game.GOLD,true))
	var search_actions := HBoxContainer.new()
	parent.add_child(search_actions)
	var search_field := LineEdit.new()
	search_field.name = "FellowshipSearch"
	search_field.placeholder_text = "Optional name filter"
	search_field.max_length = 48
	search_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_actions.add_child(search_field)
	var search: Button = game._button("SEARCH",game.PANEL_LIGHT,10,func(): _refresh_fellowship_board(search_field.text))
	search.name = "SearchFellowships"
	search.disabled = service.busy
	search_actions.add_child(search)
	if service.open_fellowships.is_empty():
		parent.add_child(game._paragraph_label("No open fellowships are loaded yet. Search or refresh the board.",10,game.MUTED))
	else:
		for fellowship in service.open_fellowships:
			var row := HBoxContainer.new()
			parent.add_child(row)
			var summary := VBoxContainer.new()
			summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(summary)
			summary.add_child(game._label(String(fellowship.get("name", "Fellowship")),10,game.PALE,true))
			var detail := "%d / %d members" % [int(fellowship.get("members", 0)), int(fellowship.get("capacity", 0))]
			if not String(fellowship.get("description", "")).is_empty(): detail += " · " + String(fellowship.description)
			summary.add_child(game._paragraph_label(detail,9,game.MUTED))
			var join: Button = game._button("JOIN",game.PANEL_LIGHT,9,func(): _join_fellowship(String(fellowship.get("id", ""))))
			join.name = "JoinFellowship"
			join.disabled = service.busy or int(fellowship.get("members", 0)) >= int(fellowship.get("capacity", 0))
			row.add_child(join)

func _render_fellowship_chat(parent: VBoxContainer, service) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
	if service.messages.is_empty():
		parent.add_child(game._paragraph_label("No messages yet. Say hello to your fellowship.",10,game.MUTED))
		return
	var first := maxi(0, service.messages.size() - 12)
	for index in range(first, service.messages.size()):
		var message: Dictionary = service.messages[index]
		parent.add_child(game._paragraph_label("%s  ·  %s" % [String(message.get("username", "Veilwalker")), String(message.get("text", ""))],10,game.PALE))

func _on_fellowship_state_changed() -> void:
	if not is_inside_tree(): return
	var service = get_node_or_null("/root/Fellowship")
	if service == null: return
	var status := find_child("FellowshipStatus", true, false) as Label
	if status != null: status.text = service.status_text
	var chat_log := find_child("FellowshipChatMessages", true, false) as VBoxContainer
	if chat_log != null: _render_fellowship_chat(chat_log, service)

func _refresh_fellowship_board(filter: String) -> void:
	var service = get_node_or_null("/root/Fellowship")
	if service == null: return
	await service.refresh_fellowships(filter)
	if is_inside_tree(): _build()

func _create_fellowship(name: String, description: String) -> void:
	var service = get_node_or_null("/root/Fellowship")
	if service == null: return
	await service.create_fellowship(name, description)
	if is_inside_tree(): _build()

func _join_fellowship(group_id: String) -> void:
	var service = get_node_or_null("/root/Fellowship")
	if service == null: return
	await service.join_fellowship(group_id)
	if is_inside_tree(): _build()

func _leave_fellowship() -> void:
	var service = get_node_or_null("/root/Fellowship")
	if service == null: return
	await service.leave_fellowship()
	if is_inside_tree(): _build()

func _send_fellowship_message(input: LineEdit) -> void:
	var service = get_node_or_null("/root/Fellowship")
	if service == null: return
	var message := input.text
	await service.send_chat(message)
	if not is_inside_tree(): return
	if service.status_text.begins_with("Message sent"): input.clear()
	_on_fellowship_state_changed()

func _create_transfer_key() -> void:
	var cloud=get_node_or_null("/root/CloudSave")
	if cloud==null: return
	await cloud.create_transfer_code()
	if is_inside_tree(): _build()

func _import_transfer_key(code: String) -> void:
	var cloud=get_node_or_null("/root/CloudSave")
	if cloud==null or game.page!="camp": return
	await cloud.import_transfer_code(code)
	if cloud.guest_connected():
		var progression = get_node_or_null("/root/Progression")
		if progression != null: await progression.refresh_profile()
		var service = get_node_or_null("/root/Fellowship")
		if service != null: await service.refresh_fellowships()
	if is_inside_tree(): _build()

func _revoke_transfer_key() -> void:
	var cloud=get_node_or_null("/root/CloudSave")
	if cloud==null: return
	await cloud.revoke_transfer_code()
	if is_inside_tree(): _build()

func _connect_online() -> void:
	var cloud=get_node_or_null("/root/CloudSave")
	if cloud==null: return
	await cloud.connect_guest()
	if cloud.guest_connected():
		var progression = get_node_or_null("/root/Progression")
		if progression != null: await progression.refresh_profile()
		var service = get_node_or_null("/root/Fellowship")
		if service != null: await service.refresh_fellowships()
	if is_inside_tree(): _build()

func _refresh_cloud() -> void:
	var cloud=get_node_or_null("/root/CloudSave")
	if cloud==null: return
	await cloud.refresh_cloud_backup()
	if cloud.guest_connected():
		var progression = get_node_or_null("/root/Progression")
		if progression != null: await progression.refresh_profile()
		var service = get_node_or_null("/root/Fellowship")
		if service != null: await service.refresh_fellowships()
	if is_inside_tree(): _build()

func _upload_online_backup() -> void:
	if game.page!="camp": return
	var code: String=String(game._create_backup_code())
	if code.is_empty():
		var cloud=get_node_or_null("/root/CloudSave")
		if cloud!=null: cloud.status_text="Could not create a backup: " + game.save_notice
		_build()
		return
	var cloud=get_node_or_null("/root/CloudSave")
	if cloud==null: return
	await cloud.upload_backup(code)
	if is_inside_tree(): _build()

func _restore_cloud_backup() -> void:
	if game.page!="camp": return
	var cloud=get_node_or_null("/root/CloudSave")
	if cloud==null or not cloud.has_cloud_backup: return
	if game._restore_backup_code(cloud.cloud_backup_code):
		get_tree().reload_current_scene()
	else:
		cloud.status_text="Restore failed: " + game.save_notice
		confirm_cloud_restore=false
		_build()

func _format_cloud_time(unix_time: int) -> String:
	if unix_time<=0: return "time unknown"
	var local:=Time.get_datetime_dict_from_unix_time(unix_time)
	return "%02d.%02d.%04d %02d:%02d" % [local.day,local.month,local.year,local.hour,local.minute]

func _backup(parent: VBoxContainer) -> void:
	parent.add_child(game._paragraph_label("Keep this private backup code somewhere safe. It contains your hero, gear and current expedition. Restoring it replaces the current progress; the previous local save is kept as a recovery copy.",12,game.PALE))
	parent.add_child(game._label("BACKUP CODE  •  COPY THIS TO KEEP A BACKUP",11,game.GOLD,true))
	var code: String=String(game._create_backup_code())
	var export_field:=TextEdit.new()
	export_field.name="BackupExportCode"
	export_field.custom_minimum_size.y=76
	export_field.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	export_field.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY
	export_field.editable=false
	export_field.text=code
	parent.add_child(export_field)
	var status: Label=game._paragraph_label(game.save_notice,11,game.MUTED)
	status.name="BackupStatus"
	var copy: Button=game._button("COPY BACKUP CODE",game.PANEL_LIGHT,11,func():
		if code.is_empty():
			status.text=game.save_notice
		else:
			DisplayServer.clipboard_set(code)
			status.text="Backup code copied to clipboard."
	)
	copy.name="CopyBackupCode"
	copy.disabled=code.is_empty()
	parent.add_child(copy)
	parent.add_child(game._label("RESTORE BACKUP CODE",11,game.GOLD,true))
	var restore_field:=TextEdit.new()
	restore_field.name="BackupRestoreCode"
	restore_field.custom_minimum_size.y=76
	restore_field.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	restore_field.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY
	parent.add_child(restore_field)
	parent.add_child(status)
	var actions:=HBoxContainer.new()
	parent.add_child(actions)
	var paste: Button=game._button("PASTE FROM CLIPBOARD",game.PANEL_LIGHT,10,func(): restore_field.text=DisplayServer.clipboard_get())
	paste.name="PasteBackupCode"
	actions.add_child(paste)
	var restore: Button=game._button("RESTORE BACKUP",game.RED,10,func():
		if game.page!="camp":
			status.text="Leave the expedition and return to camp before restoring."
		elif game._restore_backup_code(restore_field.text):
			get_tree().reload_current_scene()
		else:
			status.text=game.save_notice
	)
	restore.name="RestoreBackup"
	restore.disabled=game.page!="camp"
	actions.add_child(restore)
	var undo: Button=game._button("UNDO LAST RESTORE",game.PANEL_LIGHT,10,func():
		if game._restore_local_recovery_copy():
			get_tree().reload_current_scene()
		else:
			status.text=game.save_notice
	)
	undo.name="UndoBackupRestore"
	undo.disabled=(game.page!="camp" and not (game.page=="run" and not game.run_active)) or game.save_store.load_recovery_copy()==null
	parent.add_child(undo)

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
		var label: String="BATTERY  /  30 FPS" if battery else "BALANCED  /  UP TO 60 FPS"
		var button: Button=game._button(label,Color("31443a") if game.preferences.battery==battery else game.PANEL_LIGHT,11,func(): game._change_preference("battery",battery); _build())
		button.name="BatteryMode" if battery else "BalancedMode"
		modes.add_child(button)
	parent.add_child(game._paragraph_label("Balanced mode adjusts 3D resolution after sustained slow frames and restores detail after sustained recovery. Battery mode caps at 30 FPS and disables shadows. Frame rates are targets; combat and rewards remain unchanged.",11,game.MUTED))
	var numbers: Button=game._button("DAMAGE NUMBERS: "+("ON" if game.preferences.numbers else "OFF"),game.PANEL_LIGHT,11,func(): game._change_preference("numbers",not game.preferences.numbers); _build())
	numbers.name="DamageNumbers"
	parent.add_child(numbers)
	var large_text: Button=game._button("LARGE TEXT: "+("ON" if game.preferences.large_text else "OFF"),Color("31443a") if game.preferences.large_text else game.PANEL_LIGHT,11,func(): game._change_preference("large_text",not game.preferences.large_text); _build())
	large_text.name="LargeText"
	parent.add_child(large_text)
	parent.add_child(game._paragraph_label("Compact landscape screens enlarge text and touch targets automatically. Large Text can increase them further on any display.",11,game.MUTED))
	var reduced_motion: Button=game._button("REDUCED MOTION: "+("ON" if game.preferences.reduced_motion else "OFF"),Color("31443a") if game.preferences.reduced_motion else game.PANEL_LIGHT,11,func(): game._change_preference("reduced_motion",not game.preferences.reduced_motion); _build())
	reduced_motion.name="ReducedMotion"
	parent.add_child(reduced_motion)
	parent.add_child(game._paragraph_label("Reduces boss camera zoom and impact shake. Auto-follow and essential combat animation remain active.",11,game.MUTED))
	var haptics: Button=game._button("HAPTICS: "+("ON" if game.preferences.haptics else "OFF"),game.PANEL_LIGHT,11,func(): game._change_preference("haptics",not game.preferences.haptics); _build())
	haptics.name="Haptics"
	parent.add_child(haptics)
	parent.add_child(game._paragraph_label("Brief vibration for warnings, received damage and critical hits. Off by default; available on Android devices with vibration support.",11,game.MUTED))

func _help(parent: VBoxContainer) -> void:
	for entry in [
		["AUTOMATIC EXPEDITIONS","Nyra walks, targets enemies, casts abilities and dodges on her own. Pause freezes the expedition; Skip to Loot simulates the remaining fight and ends repeat mode."],
		["AUTOMATIC TECHNIQUES","Open Gear > Skills to equip two techniques for each class. Your signature remains equipped. Protection responds to danger; attack techniques fire when their conditions fit, with a seeded choice if both are ready. Each technique spends Mana and starts its cooldown on casting. Dodging can interrupt a cast without a refund. Ground bursts strike their marked position. You can change loadouts between expeditions."],
		["HUNTS AND ASH TRIALS","After clearing campaign floor 1, open World > Hunts to choose one gear slot. Hunts repeat and apply to AFK, with tougher enemies and focused Rare-or-better boss loot. World > Ash Trials offers a separate 150-second challenge with a once-only Epic first-clear reward. Trials never repeat or advance the campaign; after an offline trial, your chosen farm resumes."],
		["DUNGEON JOURNEYS","Each expedition varies its connected passages, enemy lineups and spawn positions. The hero picks between similarly important enemies when an attack is ready, then stays focused during its cooldown. During attack cooldowns, Nyra also makes short, seed-bound combat steps: the Vowkeeper circles close in, while Arcanist and Ranger vary their firing position. She checks telegraphed danger before moving. A run seed keeps route, movement, combat and technique choices identical when watched, skipped, resumed or calculated offline. The map follows Nyra as she clears packs, uses a healing well, breaks a guarded seal and opens the guardian reliquary automatically. The well restores up to 18% of maximum Life once per expedition."],
		["BOSS WARNINGS","New expeditions have three guardian phases, changing at two-thirds and one-third Life. Bell Warden adds cleaves and split rings; Silt Abbot splits its currents, then adds a drowning ring; Mourning Queen spreads graves into a triangle, then a ring and eruption; Cinder Sovereign adds central fire, then a ring and narrow cleaves. Each phase alternates two forms. A phase break cancels the old warning. Telegraphs show the actual danger; Nyra dodges when her cooldown is ready. Skip and offline use the same rules. Older saved expeditions keep their original attacks and half-Life awakening."],
		["CHOOSE A BUILD","Strength powers Vowkeeper, Intellect powers Arcanist and Dexterity powers Ranger. Vitality increases Life; Spirit improves Mana and its recovery on hits. Compare the six stat changes before equipping. Class changes refund spent points."],
		["CLASS-ATTUNED LOOT","New finds carry an attunement for the class that earned them and always include its primary attribute. Other affixes vary. All classes can equip every item; attunement is a recommendation, not a restriction. Existing equipment keeps its stats. Compare actual changes before replacing tempered gear."],
		["ARCANIST: MANA WARD","Mana Ward absorbs up to 35% of damage after armor at a cost of 2 Mana per damage absorbed. It always reserves enough Mana for one Nova. When the reserve is reached, incoming hits deal full damage. Nova refunds 25% of its cost. Mana and Spirit therefore support both offense and survival."],
		["ARCANIST: SPELL DISTANCE","Between attacks, the Arcanist walks away from nearby melee enemies when a safe path exists. Casting stays stationary and ground attacks still require a ready dodge. Veil Nova strikes a broad area around its target, slows enemies and interrupts casters. Its violet pulse shows the affected area."],
		["FARM WITH CONFIDENCE","Choose a cleared Farm Floor in camp. Reliable means at least 95% of the current combat patterns succeed. Recheck after changing gear. Repeat stops after a visible defeat."],
		["WHILE YOU ARE AWAY","Offline farming is enabled in the hero attributes rail. Up to 24 hours are calculated when you return. Paused expeditions stay paused. Claim Gold and XP from the report; relics are already in your bag. Overflow gear is sold."],
		["KEEP YOUR PROGRESS","Progress is saved on important actions and every five seconds in combat. Combat and progression are local. Clearing app data or reinstalling removes the on-device save. Use Settings > Save Backup to copy a portable recovery code. Local test builds also offer one manual cloud backup and a private one-time account transfer key; neither is automatic. Create and keep the transfer key before changing devices. Restoring either backup keeps the previous local save; use Undo Last Restore to switch back. Save & Exit resumes farming only when you leave an active, unpaused expedition or are in camp."]
	]:
		parent.add_child(game._label(entry[0],12,game.GOLD,true))
		parent.add_child(game._paragraph_label(entry[1],12,game.PALE))

func _beta(parent: VBoxContainer) -> void:
	var release = preload("res://scripts/release_info.gd")
	parent.add_child(game._label("CLOSED BETA  /  "+release.VERSION,15,game.GOLD,true))
	parent.add_child(game._paragraph_label("Explore four regions, prepare an automatic combat build and recover up to 24 hours of AFK rewards. This beta is a solo experience. Progress is stored on this device; keep a recovery code under Save Backup before reinstalling or changing devices.",12,game.PALE))
	parent.add_child(game._label("PRIVACY",12,game.GOLD,true))
	parent.add_child(game._paragraph_label("The offline beta contains no advertising, analytics, purchases or account registration. Your character, equipment, preferences and expedition checkpoints are saved locally. The game does not upload this progress. A recovery code contains your save: share it privately. Android manages app data and uninstalling removes it.",12,game.PALE))
	parent.add_child(game._paragraph_label("Feedback is optional. Opening the issue tracker launches your browser; GitHub's own privacy policy applies there. Review the copied report before posting. It contains game and display settings, but no recovery code or account key.",11,game.MUTED))
	var notes: Button=game._button("LOCAL PLAYTEST NOTES: "+("ON" if game.preferences.playtest else "OFF"),game.PANEL_LIGHT,11,func():
		game._change_preference("playtest",not game.preferences.playtest)
		if not game.preferences.playtest: game.playtest_notes.clear(); game._save_progress()
		_build()
	)
	notes.name="LocalPlaytestNotes"
	parent.add_child(notes)
	parent.add_child(game._paragraph_label("Optional notes record your first fight, signature, clear, relic equip and return after a day. Kept on this device, added only to a report you copy yourself. Turning this off deletes the notes.",11,game.MUTED))
	var status: Label=game._paragraph_label("Tell us the steps that caused a problem, your device model and what you expected.",11,game.MUTED)
	parent.add_child(status)
	var copy: Button=game._button("COPY FEEDBACK TEMPLATE",game.PANEL_LIGHT,11,func():
		DisplayServer.clipboard_set(release.feedback(game))
		status.text="Feedback template copied. Review it before sending."
	)
	copy.name="CopyBetaFeedback"
	parent.add_child(copy)
	parent.add_child(game._label("DEVICE PERFORMANCE",12,game.GOLD,true))
	var performance: Label=game._paragraph_label(game.frame_metrics.summary(),11,game.PALE)
	performance.name="DevicePerformanceSummary"
	parent.add_child(performance)
	parent.add_child(game._paragraph_label("Frame measurements stay in memory on this device. Copy them to compare Balanced and Battery mode; nothing is uploaded automatically.",11,game.MUTED))
	var copy_performance:Button=game._button("COPY PERFORMANCE REPORT",game.PANEL_LIGHT,11,func():
		var report:Dictionary=game.frame_metrics.report()
		report.version=release.VERSION
		report.version_code=release.VERSION_CODE
		DisplayServer.clipboard_set(JSON.stringify(report,"  "))
		status.text="Performance report copied. Review it before sharing."
	)
	copy_performance.name="CopyPerformanceReport"
	copy_performance.disabled=game.frame_metrics.rows().is_empty()
	parent.add_child(copy_performance)
	var tracker: Button=game._button("OPEN ISSUE TRACKER",game.PANEL_LIGHT,11,func():
		if OS.shell_open(release.FEEDBACK_URL)!=OK: status.text="Open github.com/Philmenting/Emberfall-Ashen-Veil/issues in your browser."
	)
	tracker.name="OpenBetaFeedback"
	parent.add_child(tracker)
