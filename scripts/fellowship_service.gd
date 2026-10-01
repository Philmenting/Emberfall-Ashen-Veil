extends Node
## Nakama-backed public fellowships and persistent group chat for online test builds.

signal state_changed

const GROUP_LIMIT := 20
const MEMBER_LIMIT := 40
const MESSAGE_LIMIT := 180
const HISTORY_LIMIT := 40
const CHAT_CHANNEL_TYPE := 3 # NakamaSocket.ChannelType.Group

var busy := false
var status_text := "Connect a guest account to browse fellowships."
var open_fellowships: Array = []
var current_fellowship: Dictionary = {}
var members: Array = []
var messages: Array = []

## Defaults to the game's CloudSave autoload. E2E fixtures can inject isolated accounts.
var account_source: Node

var _client
var _session
var _socket
var _channel
var _channel_group_id := ""
var _seen_message_ids: Dictionary = {}
var _last_chat_send_msec := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func is_available() -> bool:
	return OS.has_feature("nakama_local_test")

func refresh_fellowships(name_filter: String = "") -> void:
	if busy: return
	if not _resolve_account():
		status_text = "Connect a guest account before opening the fellowship board."
		state_changed.emit()
		return
	busy = true
	status_text = "Loading open fellowships …"
	state_changed.emit()
	var filter := name_filter.strip_edges().substr(0, 48)
	var query: Variant = filter if not filter.is_empty() else null
	var directory = await _client.list_groups_async(_session, query, GROUP_LIMIT, null, null, null, true)
	if directory == null or directory.is_exception():
		status_text = "The fellowship board could not be reached. Try again when the test server is available."
		busy = false
		state_changed.emit()
		return
	open_fellowships.clear()
	for group in directory.groups:
		if group == null or group.id.is_empty(): continue
		open_fellowships.append(_group_record(group))
	var membership = await _client.list_user_groups_async(_session, _session.user_id, null, 20, null)
	if membership == null or membership.is_exception():
		status_text = "Open fellowships loaded, but your membership could not be checked."
		busy = false
		state_changed.emit()
		return
	var previous_id: String = String(current_fellowship.get("id", ""))
	var next_fellowship: Dictionary = {}
	for entry in membership.user_groups:
		if entry == null or entry.group == null or entry.group.id.is_empty(): continue
		next_fellowship = _group_record(entry.group)
		break
	var next_id: String = String(next_fellowship.get("id", ""))
	if previous_id != next_id:
		await _leave_chat_channel()
		messages.clear()
		_seen_message_ids.clear()
		members.clear()
	current_fellowship = next_fellowship
	if not current_fellowship.is_empty():
		var members_ready: bool = await _load_members()
		var chat_ready: bool = await _join_fellowship_chat()
		if not chat_ready:
			status_text = "Fellowship ready · chat is disconnected; refresh to retry."
		elif not members_ready:
			status_text = "Fellowship ready · member list could not be loaded."
		else:
			status_text = "Fellowship ready · %s" % current_fellowship.name
	else:
		status_text = "Fellowship board ready · choose an open group or create one."
	busy = false
	state_changed.emit()

func create_fellowship(raw_name: String, raw_description: String) -> void:
	if busy: return
	if not _resolve_account():
		status_text = "Connect a guest account before creating a fellowship."
		state_changed.emit()
		return
	if not current_fellowship.is_empty():
		status_text = "Leave your current fellowship before creating another."
		state_changed.emit()
		return
	var fellowship_name := _clean_single_line(raw_name, 24)
	if fellowship_name.length() < 3:
		status_text = "Fellowship names must be between 3 and 24 characters."
		state_changed.emit()
		return
	var description := _clean_single_line(raw_description, 100)
	busy = true
	status_text = "Creating open fellowship …"
	state_changed.emit()
	var result = await _client.create_group_async(_session, fellowship_name, description, null, "en", true, MEMBER_LIMIT)
	if result == null or result.is_exception() or result.id.is_empty():
		status_text = "The fellowship could not be created. The name may already be in use."
		busy = false
		state_changed.emit()
		return
	status_text = "Fellowship created · loading members and chat …"
	busy = false
	state_changed.emit()
	await refresh_fellowships(fellowship_name)

func join_fellowship(group_id: String) -> void:
	if busy: return
	if not _resolve_account():
		status_text = "Connect a guest account before joining a fellowship."
		state_changed.emit()
		return
	if not current_fellowship.is_empty():
		status_text = "Leave your current fellowship before joining another."
		state_changed.emit()
		return
	var selected: Dictionary = {}
	for item in open_fellowships:
		if String(item.get("id", "")) == group_id:
			selected = item
			break
	if selected.is_empty() or not bool(selected.get("open", false)):
		status_text = "That fellowship is no longer open. Refresh the board and try again."
		state_changed.emit()
		return
	busy = true
	status_text = "Joining %s …" % selected.name
	state_changed.emit()
	var result = await _client.join_group_async(_session, group_id)
	if result == null or result.is_exception():
		status_text = "Could not join the fellowship. It may be full or have closed."
		busy = false
		state_changed.emit()
		return
	status_text = "Joined %s · loading members and chat …" % selected.name
	busy = false
	state_changed.emit()
	await refresh_fellowships()

func leave_fellowship() -> void:
	if busy or current_fellowship.is_empty(): return
	if not _resolve_account():
		status_text = "Reconnect the guest account before leaving the fellowship."
		state_changed.emit()
		return
	var group_id: String = String(current_fellowship.get("id", ""))
	busy = true
	status_text = "Leaving %s …" % current_fellowship.get("name", "fellowship")
	state_changed.emit()
	await _leave_chat_channel()
	var result = await _client.leave_group_async(_session, group_id)
	if result == null or result.is_exception():
		status_text = "Could not leave the fellowship. Refresh and try again."
		busy = false
		state_changed.emit()
		return
	current_fellowship.clear()
	members.clear()
	messages.clear()
	_seen_message_ids.clear()
	status_text = "You left the fellowship."
	busy = false
	state_changed.emit()
	await refresh_fellowships()

func send_chat(raw_text: String) -> void:
	if current_fellowship.is_empty() or _channel == null:
		status_text = "Join a fellowship to use its chat."
		state_changed.emit()
		return
	if not _resolve_account() or _socket == null or not _socket.is_connected_to_host():
		status_text = "Fellowship chat is disconnected. Refresh the board to reconnect."
		state_changed.emit()
		return
	var message_text := _clean_single_line(raw_text, MESSAGE_LIMIT)
	if message_text.is_empty(): return
	var now_msec := Time.get_ticks_msec()
	if now_msec - _last_chat_send_msec < 900:
		status_text = "Please wait a moment before sending another message."
		state_changed.emit()
		return
	_last_chat_send_msec = now_msec
	var result = await _socket.write_chat_message_async(_channel.id, {"text": message_text})
	if result == null or result.is_exception():
		status_text = "Message not sent. Check the connection and try again."
	else:
		status_text = "Message sent to %s." % current_fellowship.get("name", "fellowship")
	state_changed.emit()

func _resolve_account() -> bool:
	var cloud = account_source if account_source != null else get_node_or_null("/root/CloudSave")
	if cloud == null or not cloud.guest_connected(): return false
	_client = cloud.client
	_session = cloud.session
	return _client != null and _session != null

func _group_record(group) -> Dictionary:
	return {
		"id": String(group.id),
		"name": String(group.name),
		"description": String(group.description),
		"open": bool(group.open),
		"members": int(group.edge_count),
		"capacity": int(group.max_count)
	}

func _load_members() -> bool:
	if current_fellowship.is_empty(): return false
	var result = await _client.list_group_users_async(_session, String(current_fellowship.id), null, MEMBER_LIMIT, null)
	if result == null or result.is_exception():
		members.clear()
		return false
	members.clear()
	for entry in result.group_users:
		if entry == null or entry.user == null: continue
		members.append({
			"username": String(entry.user.username),
			"online": bool(entry.user.online),
			"role": int(entry.state)
		})
	return true

func _join_fellowship_chat() -> bool:
	if current_fellowship.is_empty(): return false
	var group_id: String = String(current_fellowship.id)
	if _channel != null and _channel_group_id == group_id and _socket != null and _socket.is_connected_to_host():
		return true
	if _socket == null or not _socket.is_connected_to_host():
		var nakama_api = get_node_or_null("/root/Nakama")
		if nakama_api == null:
			status_text = "Nakama realtime chat is unavailable in this build."
			return false
		if _socket != null:
			_socket.close()
		_socket = nakama_api.create_socket_from(_client)
		_socket.received_channel_message.connect(_on_channel_message)
		var connected = await _socket.connect_async(_session, true, 8)
		if connected == null or connected.is_exception():
			status_text = "Could not connect to fellowship chat. The group remains available."
			_socket.close()
			_socket = null
			return false
	if _channel != null:
		await _leave_chat_channel()
	var joined = await _socket.join_chat_async(group_id, CHAT_CHANNEL_TYPE, true, false)
	if joined == null or joined.is_exception():
		_channel = null
		_channel_group_id = ""
		status_text = "Could not open fellowship chat. Refresh to retry."
		return false
	_channel = joined
	_channel_group_id = group_id
	await _load_chat_history()
	return true

func _load_chat_history() -> void:
	if _channel == null: return
	var result = await _client.list_channel_messages_async(_session, _channel.id, HISTORY_LIMIT, false)
	if result == null or result.is_exception():
		messages.clear()
		_seen_message_ids.clear()
		status_text = "Chat is live, but message history could not be loaded."
		return
	messages.clear()
	_seen_message_ids.clear()	
	for index in range(result.messages.size() - 1, -1, -1):
		_record_message(result.messages[index])

func _on_channel_message(message) -> void:
	if message == null or _channel == null: return
	if String(message.channel_id) != String(_channel.id): return
	_record_message(message)
	state_changed.emit()

func _record_message(message) -> void:
	var raw_content := String(message.content)
	var parsed: Variant = JSON.parse_string(raw_content)
	if not parsed is Dictionary: return
	var text_value := _clean_single_line(String(parsed.get("text", "")), MESSAGE_LIMIT)
	if text_value.is_empty(): return
	var id := String(message.message_id)
	if id.is_empty(): id = String(message.username) + ":" + String(message.create_time) + ":" + text_value
	if _seen_message_ids.has(id): return
	_seen_message_ids[id] = true
	messages.append({
		"id": id,
		"username": _clean_single_line(String(message.username), 24),
		"text": text_value,
		"time": String(message.create_time)
	})
	while messages.size() > HISTORY_LIMIT:
		var removed: Dictionary = messages.pop_front()
		_seen_message_ids.erase(String(removed.get("id", "")))

func _leave_chat_channel() -> void:
	if _socket != null and _channel != null and _socket.is_connected_to_host():
		await _socket.leave_chat_async(_channel.id)
	_channel = null
	_channel_group_id = ""

func _clean_single_line(value: String, max_length: int) -> String:
	var result := value.strip_edges().replace("\n", " ").replace("\r", " ").replace("\t", " ")
	while result.contains("  "):
		result = result.replace("  ", " ")
	return result.substr(0, max_length)

func _exit_tree() -> void:
	shutdown()

func shutdown() -> void:
	if _socket != null:
		_socket.close()
		_socket = null
	_channel = null
	_channel_group_id = ""
