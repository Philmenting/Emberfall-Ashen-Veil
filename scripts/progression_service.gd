extends Node
## Server-owned progression test profile. This profile is separate from Main's local save.

signal state_changed

const RPC_SYNC := "emberfall_progression_sync"
const RPC_FARM := "emberfall_progression_farm"
const RPC_CLASS := "emberfall_progression_class"
const RPC_ALLOCATE := "emberfall_progression_allocate"
const RPC_EQUIP := "emberfall_progression_equip"
const RPC_SELL := "emberfall_progression_sell"
const RPC_TEMPER := "emberfall_progression_temper"

var busy := false
var status_text := "Connect a guest account to create a server-owned progression profile."
var profile: Dictionary = {}
var settlement: Dictionary = {}
var account_source: Node
var _client
var _session

func is_available() -> bool:
	return OS.has_feature("nakama_local_test")

func refresh_profile() -> void:
	await _call_rpc(RPC_SYNC, {})

func set_farm_settings(farm_floor: int, farm_enabled: bool) -> void:
	await _call_rpc(RPC_FARM, {"farm_floor": farm_floor, "farm_enabled": farm_enabled})

func select_class(class_key: String) -> void:
	await _call_rpc(RPC_CLASS, {"class_name": class_key})

func allocate_attribute(attribute: String) -> void:
	await _call_rpc(RPC_ALLOCATE, {"attribute": attribute})

func equip_item(item_id: String) -> void:
	await _call_rpc(RPC_EQUIP, {"item_id": item_id})

func sell_item(item_id: String) -> void:
	await _call_rpc(RPC_SELL, {"item_id": item_id})

func temper_item(slot: String) -> void:
	await _call_rpc(RPC_TEMPER, {"slot": slot})

func _call_rpc(rpc_id: String, payload: Dictionary) -> void:
	if busy: return
	if not is_available():
		status_text = "Server progression is enabled only in the local online-test build."
		state_changed.emit()
		return
	if not _resolve_account():
		status_text = "Connect a guest account before using server progression."
		state_changed.emit()
		return
	busy = true
	status_text = "Contacting the server-owned progression profile …"
	state_changed.emit()
	var response = await _client.rpc_async(_session, rpc_id, JSON.stringify(payload))
	if response == null or response.is_exception():
		status_text = "The progression server could not be reached. Your local character has not changed."
		busy = false
		state_changed.emit()
		return
	var parsed: Variant = JSON.parse_string(response.payload)
	if not parsed is Dictionary:
		status_text = "The progression server returned an invalid response."
		busy = false
		state_changed.emit()
		return
	if parsed.get("profile", null) is Dictionary:
		profile = parsed.profile
	if parsed.get("settlement", null) is Dictionary:
		settlement = parsed.settlement
	if bool(parsed.get("ok", false)):
		status_text = _success_message(parsed)
	else:
		status_text = String(parsed.get("error", "The server rejected that progression action."))
	busy = false
	state_changed.emit()

func _resolve_account() -> bool:
	var cloud: Node = account_source if account_source != null else get_node_or_null("/root/CloudSave")
	if cloud == null or not cloud.guest_connected(): return false
	_client = cloud.client
	_session = cloud.session
	return _client != null and _session != null

func _success_message(response: Dictionary) -> String:
	var report: Dictionary = response.get("settlement", {})
	var runs := int(report.get("runs", 0))
	if runs <= 0: return "Server profile ready · no AFK runs to settle."
	return "Server settled %d AFK runs · %d wins · +%d Gold · +%d XP." % [runs, int(report.get("wins", 0)), int(report.get("gold", 0)), int(report.get("xp", 0))]
