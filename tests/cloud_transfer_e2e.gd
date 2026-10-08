extends SceneTree

const CloudSaveScript = preload("res://scripts/cloud_save.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const FellowshipServiceScript = preload("res://scripts/fellowship_service.gd")

class TransferTestClient extends CloudSaveScript:
	func is_available() -> bool:
		return true

var checks := 0
var failures := 0
var test_folder := ""
var clients: Array[Node] = []
var fellowship_services: Array[Node] = []

func _initialize() -> void:
	call_deferred("run_transfer")

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)

func new_install(label: String) -> Node:
	var install := TransferTestClient.new()
	install.identity_path = test_folder + "/" + label + ".cfg"
	clients.append(install)
	root.add_child(install)
	return install

func new_fellowship_service(account: Node) -> Node:
	var service = FellowshipServiceScript.new()
	service.account_source = account
	fellowship_services.append(service)
	root.add_child(service)
	return service

func run_transfer() -> void:
	test_folder = "user://cloud-transfer-e2e-" + str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_folder))
	var old_install = new_install("old-device")
	await old_install.connect_guest()
	check(old_install.guest_connected(), "old installation creates and authenticates a guest account")
	if not old_install.guest_connected():
		finish()
		return
	await verify_server_progression(old_install)

	var payload := ConfigFile.new()
	payload.set_value("hero", "level", 37)
	payload.set_value("idle", "last_claim", 123456)
	var backup_code: String = SaveStore.new().create_backup_code(payload)
	check(not backup_code.is_empty(), "test save produces a valid backup code")
	await old_install.upload_backup(backup_code)
	check(old_install.has_cloud_backup and old_install.cloud_backup_code == backup_code, "old installation uploads its private cloud backup")
	if not old_install.has_cloud_backup:
		finish()
		return

	var original_user_id: String = old_install.session.user_id
	var original_device_id: String = old_install._load_guest_id(false)
	await old_install.create_transfer_code()
	var transfer_key: String = old_install.transfer_code()
	check(old_install._valid_device_id(transfer_key) and transfer_key != original_device_id, "server links a fresh one-time transfer identity")
	if not old_install._valid_device_id(transfer_key):
		finish()
		return

	var new_installation = new_install("new-device")
	check(not new_installation.local_guest_exists(), "receiving installation starts without an account")
	await new_installation.import_transfer_code(transfer_key)
	check(new_installation.guest_connected(), "new installation imports and authenticates the transfer key")
	check(new_installation.guest_connected() and new_installation.session.user_id == original_user_id, "import resolves to the original Nakama account")
	check(new_installation._valid_device_id(new_installation._load_guest_id(false)) and new_installation._load_guest_id(false) != original_device_id, "new installation persists its own replacement device identity")
	check(new_installation.transfer_code().is_empty(), "successful import removes the consumed key from local storage")
	check(new_installation.has_cloud_backup and new_installation.cloud_backup_code == backup_code, "imported account can read the existing private cloud backup")

	var replay_installation = new_install("replay-device")
	await replay_installation.import_transfer_code(transfer_key)
	check(not replay_installation.guest_connected() and not replay_installation.local_guest_exists(), "a consumed transfer key cannot authenticate a third installation")

	var old_cold_start = new_install("old-device-cold-start")
	old_cold_start.identity_path = old_install.identity_path
	await old_cold_start.connect_guest()
	check(old_cold_start.guest_connected() and old_cold_start.session.user_id == original_user_id, "old installation can still reconnect after transfer")
	check(old_cold_start.transfer_code().is_empty(), "old installation clears the key marker after server reconciliation")

	var new_cold_start = new_install("new-device-cold-start")
	new_cold_start.identity_path = new_installation.identity_path
	await new_cold_start.connect_guest()
	check(new_cold_start.guest_connected() and new_cold_start.session.user_id == original_user_id, "new installation survives a cold restart with its replacement identity")
	check(new_cold_start.has_cloud_backup and new_cold_start.cloud_backup_code == backup_code, "cloud backup remains available after a cold restart")
	await verify_fellowship_and_chat()
	finish()

func verify_fellowship_and_chat() -> void:
	var creator = new_install("fellowship-creator")
	await creator.connect_guest()
	check(creator.guest_connected(), "fellowship creator authenticates as a separate player")
	if not creator.guest_connected(): return
	var member = new_install("fellowship-member")
	await member.connect_guest()
	check(member.guest_connected() and member.session.user_id != creator.session.user_id, "second fellowship member has an independent server identity")
	if not member.guest_connected() or member.session.user_id == creator.session.user_id: return
	var name := "Ash" + str(Time.get_ticks_usec()).right(9)
	var creator_service = new_fellowship_service(creator)
	await creator_service.refresh_fellowships()
	await creator_service.create_fellowship(name, "Automated shared-group integration check.")
	var group_id: String = String(creator_service.current_fellowship.get("id", ""))
	check(not group_id.is_empty() and creator_service.current_fellowship.get("name", "") == name, "creator registers an open server-backed fellowship")
	if group_id.is_empty(): return
	var member_service = new_fellowship_service(member)
	await member_service.refresh_fellowships(name)
	var discoverable := false
	for group in member_service.open_fellowships:
		if String(group.get("id", "")) == group_id: discoverable = true
	check(discoverable, "another player discovers the open fellowship through the server board")
	var closed_name := name + "Closed"
	var closed_group = await creator.client.create_group_async(creator.session, closed_name, "Private test group", null, "en", false, 8)
	check(closed_group != null and not closed_group.is_exception(), "test creates a closed group for named-search coverage")
	await member_service.refresh_fellowships(closed_name)
	check(member_service.open_fellowships.is_empty() and member_service.status_text.contains("board ready"), "named search succeeds and excludes closed groups from the open board")
	await member_service.refresh_fellowships()
	discoverable=false
	for group in member_service.open_fellowships:
		if String(group.get("id", ""))==group_id: discoverable=true
	check(discoverable, "unfiltered open board still discovers the same fellowship")
	await member_service.join_fellowship(group_id)
	check(String(member_service.current_fellowship.get("id", "")) == group_id, "second player joins the same server-backed fellowship")
	check(member_service.members.size() == 2, "server roster reports both fellowship members")
	var chat_text := "Shared Emberfall message %d" % Time.get_ticks_usec()
	await creator_service.send_chat(chat_text)
	var received := false
	for attempt in range(40):
		for message in member_service.messages:
			if String(message.get("text", "")) == chat_text: received = true
		if received: break
		await create_timer(0.25).timeout
	check(received, "persistent group chat delivers a message to another connected player")
	member_service.shutdown()
	var reconnect_service = new_fellowship_service(member)
	await reconnect_service.refresh_fellowships(name)
	var restored_chat := false
	for message in reconnect_service.messages:
		if String(message.get("text", "")) == chat_text: restored_chat = true
	check(restored_chat, "a fresh chat connection loads the server-persisted message history")
	await reconnect_service.leave_fellowship()
	check(reconnect_service.current_fellowship.is_empty(), "member can leave a fellowship through the server")

func verify_server_progression(install: Node) -> void:
	var initial = await call_progression_rpc(install, "emberfall_progression_sync", {"gold": 2000000000, "highest_floor": 999999})
	check(bool(initial.get("ok", false)), "server creates a private progression profile for a signed-in account")
	var profile: Dictionary = initial.get("profile", {})
	check(int(profile.get("gold", -1)) == 600 and int(profile.get("highest_floor", -1)) == 1, "client-supplied currency and floor unlocks are ignored")
	check(profile.get("equipment", {}).size() == 6 and int(profile.get("attribute_points", 0)) == 2, "server initializes a complete starter equipment set and attribute points")
	var locked_floor = await call_progression_rpc(install, "emberfall_progression_farm", {"farm_floor": 2, "farm_enabled": true})
	check(not bool(locked_floor.get("ok", true)) and int(locked_floor.get("profile", {}).get("farm_floor", 0)) == 1, "server rejects farming on a locked floor")
	var class_result = await call_progression_rpc(install, "emberfall_progression_class", {"class_name": "Arcanist"})
	check(bool(class_result.get("ok", false)) and class_result.get("profile", {}).get("class_name", "") == "Arcanist", "server accepts a class from its fixed class allowlist")
	var invalid_class = await call_progression_rpc(install, "emberfall_progression_class", {"class_name": "Admin"})
	check(not bool(invalid_class.get("ok", true)), "server rejects an unknown class")
	var allocation = await call_progression_rpc(install, "emberfall_progression_allocate", {"attribute": "Intellect"})
	check(bool(allocation.get("ok", false)) and allocation.get("profile", {}).get("attributes", {}).get("Intellect", 0) == 1, "server spends attribute points without accepting a client-provided amount")
	var storage_read = await install.client.read_storage_objects_async(install.session, [NakamaStorageObjectId.new("emberfall", "server_progression", install.session.user_id)])
	var write_denied := false
	if storage_read != null and not storage_read.is_exception() and not storage_read.objects.is_empty():
		var current = storage_read.objects[0]
		var injected = NakamaWriteStorageObject.new("emberfall", "server_progression", 1, 1, JSON.stringify({"gold": 2000000000}), current.version)
		var write_result = await install.client.write_storage_objects_async(install.session, [injected])
		write_denied = write_result != null and write_result.is_exception()
	check(write_denied, "Nakama blocks direct client writes to the server-owned profile")
	var after_attempt = await call_progression_rpc(install, "emberfall_progression_sync", {})
	check(int(after_attempt.get("profile", {}).get("gold", -1)) == 600 and after_attempt.get("profile", {}).get("class_name", "") == "Arcanist", "rejected direct writes leave server progression unchanged")

func call_progression_rpc(install: Node, rpc_id: String, payload: Dictionary) -> Dictionary:
	var response = await install.client.rpc_async(install.session, rpc_id, JSON.stringify(payload))
	if response == null or response.is_exception():
		if response!=null:
			var error: NakamaException=response.get_exception()
			print("RPC diagnostic: HTTP ",error.status_code," / gRPC ",error.grpc_status_code)
		check(false, "RPC %s reaches the server runtime" % rpc_id)
		return {}
	var parsed: Variant = JSON.parse_string(response.payload)
	if not parsed is Dictionary:
		check(false, "RPC %s returns a JSON object" % rpc_id)
		return {}
	return parsed

func finish() -> void:
	for service in fellowship_services:
		service.shutdown()
		service.queue_free()
	for install in clients:
		var path: String = install.identity_path
		for suffix in ["", ".tmp", ".previous"]:
			install._remove_identity_file(path + suffix)
		install.queue_free()
	var absolute_folder := ProjectSettings.globalize_path(test_folder)
	if DirAccess.dir_exists_absolute(absolute_folder):
		DirAccess.remove_absolute(absolute_folder)
	print("CLOUD TRANSFER E2E: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
