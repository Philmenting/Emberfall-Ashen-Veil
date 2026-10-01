extends Node
## Local-development-only guest identity and manual Nakama backup storage.
## This is a personal backup service, not authoritative game progression.

signal state_changed

const SaveStore = preload("res://scripts/save_store.gd")
const SERVER_KEY := "defaultkey"
const SERVER_HOST := "127.0.0.1"
const SERVER_PORT := 7350
const COLLECTION := "emberfall"
const STORAGE_KEY := "hero_backup"
const MAX_CLOUD_VALUE_BYTES := 6 * 1024 * 1024

var identity_path := "user://emberfall_online.cfg"
var status_text := "Available only in the local online-test build."
var busy := false
var session: NakamaSession
var client: NakamaClient
var has_cloud_backup := false
var cloud_backup_code := ""
var cloud_version := ""
var cloud_uploaded_at := 0

func is_available() -> bool:
	return OS.has_feature("nakama_local_test")

func guest_connected() -> bool:
	return session != null and session.valid and not session.expired

func local_guest_exists() -> bool:
	return not _load_guest_id(false).is_empty()

func transfer_code() -> String:
	return _load_transfer_id()

func connect_guest() -> void:
	if busy: return
	if not is_available():
		status_text = "Online test is not enabled in this build."
		state_changed.emit()
		return
	busy = true
	status_text = "Connecting guest account …"
	state_changed.emit()
	if not await _ensure_guest_session(true):
		busy = false
		state_changed.emit()
		return
	await _reconcile_transfer_code()
	await _read_cloud_backup()
	busy = false
	state_changed.emit()

func refresh_cloud_backup() -> void:
	if busy: return
	if not is_available():
		status_text = "Online test is not enabled in this build."
		state_changed.emit()
		return
	busy = true
	status_text = "Checking cloud backup …"
	state_changed.emit()
	if not await _ensure_guest_session(false):
		busy = false
		state_changed.emit()
		return
	await _reconcile_transfer_code()
	await _read_cloud_backup()
	busy = false
	state_changed.emit()

func create_transfer_code() -> void:
	if busy: return
	if not is_available():
		status_text = "Account transfer is available only in the local online-test build."
		state_changed.emit()
		return
	if not guest_connected():
		status_text = "Connect this guest account before creating a transfer key."
		state_changed.emit()
		return
	var device_id := _load_guest_id(false)
	if device_id.is_empty():
		status_text = "This installation has no guest identity to protect."
		state_changed.emit()
		return
	var existing_code := _load_transfer_id()
	if not existing_code.is_empty():
		busy = true
		status_text = "Checking the existing transfer key …"
		state_changed.emit()
		var still_linked: Variant = await _account_has_device_id(existing_code)
		if still_linked == null:
			status_text = "The existing transfer key could not be checked. Try again when the test server is available."
			busy = false
			state_changed.emit()
			return
		if still_linked:
			status_text = "A transfer key is already linked. Copy it or revoke it before creating another."
			busy = false
			state_changed.emit()
			return
		_store_identity(device_id, "")
	busy = true
	status_text = "Creating a one-time account transfer key …"
	state_changed.emit()
	var code := _generate_device_id()
	if code.is_empty():
		status_text = "A secure transfer key could not be generated."
		busy = false
		state_changed.emit()
		return
	if not _store_identity(device_id, code):
		status_text = "The transfer key could not be saved securely on this device."
		busy = false
		state_changed.emit()
		return
	var result = await client.link_device_async(session, code)
	if result == null or result.is_exception():
		status_text = "The link could not be confirmed. Keep this key private and check or revoke it before creating another."
		busy = false
		state_changed.emit()
		return
	status_text = "One-time transfer key created. Keep it private; anyone holding it can access this guest account."
	busy = false
	state_changed.emit()

func import_transfer_code(raw_code: String) -> void:
	if busy: return
	if not is_available():
		status_text = "Account transfer is available only in the local online-test build."
		state_changed.emit()
		return
	if local_guest_exists() or guest_connected():
		status_text = "Import is available only before a guest account is created on this installation."
		state_changed.emit()
		return
	var code := raw_code.strip_edges().replace(" ", "").replace("-", "").to_lower()
	if not _valid_device_id(code):
		status_text = "Enter the 32-character account transfer key."
		state_changed.emit()
		return
	busy = true
	status_text = "Connecting this installation to the existing account …"
	state_changed.emit()
	var nakama_api = get_node_or_null("/root/Nakama")
	if nakama_api == null:
		session = null
		status_text = "Nakama is unavailable in this build."
		busy = false
		state_changed.emit()
		return
	client = nakama_api.create_client(SERVER_KEY, SERVER_HOST, SERVER_PORT, "http", 8, NakamaLogger.LOG_LEVEL.ERROR)
	var imported_session: NakamaSession = await client.authenticate_device_async(code, "Veilwalker-" + code.substr(0, 6), false)
	if imported_session == null or imported_session.is_exception() or not imported_session.valid:
		session = null
		status_text = "Transfer key is invalid, expired, or the local test server is unavailable."
		busy = false
		state_changed.emit()
		return
	session = imported_session
	var new_device_id := _generate_device_id()
	if new_device_id.is_empty():
		session = null
		status_text = "The account was reached, but a new installation key could not be generated. The transfer key remains usable."
		busy = false
		state_changed.emit()
		return
	var link_result = await client.link_device_async(session, new_device_id)
	if link_result == null or link_result.is_exception():
		session = null
		status_text = "The account was reached, but this installation could not be linked. The transfer key remains usable."
		busy = false
		state_changed.emit()
		return
	# Save the replacement login before invalidating the one-time key. If persistence
	# fails, the old key remains valid and the player can retry the import safely.
	if not _store_identity(new_device_id, code):
		await client.unlink_device_async(session, new_device_id)
		session = null
		status_text = "This installation could not save its new account key. The transfer key remains usable; retry after freeing local storage."
		busy = false
		state_changed.emit()
		return
	var unlink_result = await client.unlink_device_async(session, code)
	var transfer_key_removed: bool = unlink_result != null and not unlink_result.is_exception()
	if transfer_key_removed:
		_store_identity(new_device_id, "")
	await _read_cloud_backup()
	var backup_status := status_text
	if transfer_key_removed:
		status_text = backup_status + " · one-time transfer key used and disabled"
	else:
		status_text = backup_status + " · revoke the used transfer key here before sharing a new one"
	busy = false
	state_changed.emit()

func revoke_transfer_code() -> void:
	if busy: return
	if not is_available() or not guest_connected():
		status_text = "Connect this guest account before revoking a transfer key."
		state_changed.emit()
		return
	var code := _load_transfer_id()
	var device_id := _load_guest_id(false)
	if code.is_empty() or device_id.is_empty():
		status_text = "There is no saved transfer key to revoke."
		state_changed.emit()
		return
	busy = true
	status_text = "Checking and revoking the account transfer key …"
	state_changed.emit()
	var still_linked: Variant = await _account_has_device_id(code)
	if still_linked == null:
		status_text = "The transfer key could not be checked. Try again when the test server is available."
		busy = false
		state_changed.emit()
		return
	if not still_linked:
		if _store_identity(device_id, ""):
			status_text = "Transfer key was already used or revoked."
		else:
			status_text = "The key is no longer active, but its local marker could not be cleared."
		busy = false
		state_changed.emit()
		return
	var result = await client.unlink_device_async(session, code)
	if result == null or result.is_exception():
		status_text = "The transfer key could not be revoked. It may already have been used; check Cloud and try again."
	else:
		_store_identity(device_id, "")
		status_text = "Transfer key revoked."
	busy = false
	state_changed.emit()

func upload_backup(code: String) -> void:
	if busy: return
	if not is_available():
		status_text = "Online test is not enabled in this build."
		state_changed.emit()
		return
	if code.is_empty() or SaveStore.new().parse_backup_code(code) == null:
		status_text = "The local backup code is invalid. Nothing was uploaded."
		state_changed.emit()
		return
	busy = true
	status_text = "Checking cloud backup version …"
	state_changed.emit()
	if not await _ensure_guest_session(false):
		busy = false
		state_changed.emit()
		return
	var read_result = await client.read_storage_objects_async(session, [NakamaStorageObjectId.new(COLLECTION, STORAGE_KEY, session.user_id)])
	if read_result == null or read_result.is_exception():
		status_text = "Cloud backup could not be read; upload cancelled."
		busy = false
		state_changed.emit()
		return
	cloud_version = ""
	if not read_result.objects.is_empty():
		cloud_version = read_result.objects[0].version
	var value := JSON.stringify({
		"schema": 1,
		"backup_code": code,
		"uploaded_at": int(Time.get_unix_time_from_system())
	})
	if value.to_utf8_buffer().size() > MAX_CLOUD_VALUE_BYTES:
		status_text = "This save is too large for the local cloud test."
		busy = false
		state_changed.emit()
		return
	status_text = "Uploading cloud backup …"
	state_changed.emit()
	var write := NakamaWriteStorageObject.new(COLLECTION, STORAGE_KEY, 1, 1, value, cloud_version)
	var write_result = await client.write_storage_objects_async(session, [write])
	if write_result == null or write_result.is_exception() or write_result.acks.is_empty():
		status_text = "Upload failed. The cloud backup may have changed since it was read."
		busy = false
		state_changed.emit()
		return
	cloud_version = write_result.acks[0].version
	cloud_backup_code = code
	cloud_uploaded_at = int(Time.get_unix_time_from_system())
	has_cloud_backup = true
	status_text = "Cloud backup saved · " + _format_timestamp(cloud_uploaded_at)
	busy = false
	state_changed.emit()

func _read_cloud_backup() -> void:
	if client == null or not guest_connected():
		status_text = "Guest account is not connected."
		return
	var result = await client.read_storage_objects_async(session, [NakamaStorageObjectId.new(COLLECTION, STORAGE_KEY, session.user_id)])
	if result == null or result.is_exception():
		has_cloud_backup = false
		cloud_backup_code = ""
		cloud_version = ""
		cloud_uploaded_at = 0
		status_text = "Cloud backup could not be read."
		return
	if result.objects.is_empty():
		has_cloud_backup = false
		cloud_backup_code = ""
		cloud_version = ""
		cloud_uploaded_at = 0
		status_text = "Guest account connected · no cloud backup yet"
		return
	var item = result.objects[0]
	cloud_version = item.version
	if item.value.to_utf8_buffer().size() > MAX_CLOUD_VALUE_BYTES:
		has_cloud_backup = false
		cloud_backup_code = ""
		status_text = "Cloud record is too large and was not loaded."
		return
	var parsed: Variant = JSON.parse_string(item.value)
	if not parsed is Dictionary or int(parsed.get("schema", 0)) != 1 or not parsed.get("backup_code", "") is String:
		has_cloud_backup = false
		cloud_backup_code = ""
		status_text = "Cloud record is damaged or incompatible."
		return
	var code: String = parsed.backup_code
	if SaveStore.new().parse_backup_code(code) == null:
		has_cloud_backup = false
		cloud_backup_code = ""
		status_text = "Cloud backup failed its integrity check."
		return
	cloud_backup_code = code
	cloud_uploaded_at = int(parsed.get("uploaded_at", 0))
	has_cloud_backup = true
	status_text = "Cloud backup available · " + _format_timestamp(cloud_uploaded_at)

func _ensure_guest_session(allow_create: bool) -> bool:
	if guest_connected(): return true
	var device_id := _load_guest_id(allow_create)
	if device_id.is_empty():
		status_text = "Connect the guest account first."
		return false
	var nakama_api = get_node_or_null("/root/Nakama")
	if nakama_api == null:
		status_text = "Nakama is unavailable in this build."
		return false
	client = nakama_api.create_client(SERVER_KEY, SERVER_HOST, SERVER_PORT, "http", 8, NakamaLogger.LOG_LEVEL.ERROR)
	var result: NakamaSession = await client.authenticate_device_async(device_id, "Veilwalker-" + device_id.substr(0, 6), true)
	if result == null or result.is_exception() or not result.valid:
		status_text = "Connection failed. Is the local Nakama test server running?"
		session = null
		return false
	session = result
	status_text = "Guest account connected · " + _short_user_id(session.user_id)
	return true

func _load_guest_id(create_if_missing: bool) -> String:
	var identity: ConfigFile = _load_identity_config()
	if identity != null:
		var existing: Variant = identity.get_value("guest", "device_id", "")
		if existing is String and _valid_device_id(existing): return existing.to_lower()
	if not create_if_missing: return ""
	var device_id := _generate_device_id()
	if device_id.is_empty() or not _store_identity(device_id, ""): return ""
	return device_id

func _load_transfer_id() -> String:
	var identity: ConfigFile = _load_identity_config()
	if identity == null: return ""
	var stored: Variant = identity.get_value("guest", "transfer_id", "")
	return stored.to_lower() if stored is String and _valid_device_id(stored) else ""

func _load_identity_config() -> ConfigFile:
	var identity := ConfigFile.new()
	if identity.load(identity_path) == OK and _identity_config_has_guest(identity):
		_remove_identity_file(identity_path + ".previous")
		_remove_identity_file(identity_path + ".tmp")
		return identity
	for recovery_path in [identity_path + ".previous", identity_path + ".tmp"]:
		var recovery := ConfigFile.new()
		if recovery.load(recovery_path) != OK or not _identity_config_has_guest(recovery): continue
		if FileAccess.file_exists(identity_path): _remove_identity_file(identity_path)
		if DirAccess.rename_absolute(ProjectSettings.globalize_path(recovery_path), ProjectSettings.globalize_path(identity_path)) == OK:
			_remove_identity_file(identity_path + ".previous")
			_remove_identity_file(identity_path + ".tmp")
		return recovery
	return null

func _identity_config_has_guest(identity: ConfigFile) -> bool:
	var device_id: Variant = identity.get_value("guest", "device_id", "")
	return device_id is String and _valid_device_id(device_id)

func _valid_device_id(value: String) -> bool:
	return value.length() == 32 and value.is_valid_hex_number()

func _generate_device_id() -> String:
	var random_bytes := Crypto.new().generate_random_bytes(16)
	return random_bytes.hex_encode() if random_bytes.size() == 16 else ""

func _account_has_device_id(device_id: String) -> Variant:
	var account = await client.get_account_async(session)
	if account == null or account.is_exception(): return null
	for linked_device in account.devices:
		if linked_device.id == device_id: return true
	return false

func _reconcile_transfer_code() -> void:
	var code := _load_transfer_id()
	var device_id := _load_guest_id(false)
	if code.is_empty() or device_id.is_empty(): return
	var still_linked: Variant = await _account_has_device_id(code)
	if still_linked == false: _store_identity(device_id, "")

func _store_identity(device_id: String, transfer_id: String) -> bool:
	if not _valid_device_id(device_id): return false
	if not transfer_id.is_empty() and not _valid_device_id(transfer_id): return false
	var temporary := identity_path + ".tmp"
	var previous := identity_path + ".previous"
	_remove_identity_file(temporary)
	var identity := ConfigFile.new()
	identity.set_value("guest", "device_id", device_id.to_lower())
	identity.set_value("guest", "transfer_id", transfer_id.to_lower())
	if identity.save(temporary) != OK: return false
	var verified := ConfigFile.new()
	if verified.load(temporary) != OK or verified.get_value("guest", "device_id", "") != device_id.to_lower() or verified.get_value("guest", "transfer_id", "") != transfer_id.to_lower():
		_remove_identity_file(temporary)
		return false
	var had_previous := FileAccess.file_exists(identity_path)
	if had_previous:
		_remove_identity_file(previous)
		if DirAccess.rename_absolute(ProjectSettings.globalize_path(identity_path), ProjectSettings.globalize_path(previous)) != OK:
			_remove_identity_file(temporary)
			return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(identity_path)) != OK:
		if had_previous:
			DirAccess.rename_absolute(ProjectSettings.globalize_path(previous), ProjectSettings.globalize_path(identity_path))
		_remove_identity_file(temporary)
		return false
	if had_previous: _remove_identity_file(previous)
	return true

func _remove_identity_file(path: String) -> void:
	if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _short_user_id(user_id: String) -> String:
	return user_id.substr(0, 8) + "…" if user_id.length() > 8 else user_id

func _format_timestamp(unix_time: int) -> String:
	if unix_time <= 0: return "time unknown"
	var local := Time.get_datetime_dict_from_unix_time(unix_time)
	return "%02d.%02d.%04d %02d:%02d" % [local.day, local.month, local.year, local.hour, local.minute]
