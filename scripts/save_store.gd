extends RefCounted
## Two validated generations. Only the older slot is replaced, by atomic rename.
const VERSION := 1
const MAX_BYTES := 4 * 1024 * 1024
var base_path := "user://emberfall.save"
var revision := 0
var notice := ""
var write_blocked := false

func _init(path: String = "user://emberfall.save") -> void:
	base_path = path

func _read_slot(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var file := FileAccess.open(path,FileAccess.READ)
	if file==null or file.get_length()>MAX_BYTES: return {"invalid":true}
	var envelope := ConfigFile.new()
	if envelope.parse(file.get_as_text())!=OK: return {"invalid":true}
	var version = envelope.get_value("storage","version",0)
	if not version is int: return {"invalid":true}
	if version>VERSION: return {"future":true}
	if version!=VERSION: return {"invalid":true}
	var text_value = envelope.get_value("storage","payload",null)
	var checksum = envelope.get_value("storage","sha256",null)
	var number = envelope.get_value("storage","revision",null)
	if not text_value is String or not checksum is String or not number is int or number<1: return {"invalid":true}
	if (str(number)+"\n"+text_value).sha256_text()!=checksum: return {"invalid":true}
	var payload := ConfigFile.new()
	if payload.parse(text_value)!=OK or not payload.has_section("hero") or not payload.has_section("idle"): return {"invalid":true}
	return {"save":payload,"revision":number,"path":path}

func load_save() -> ConfigFile:
	notice = ""
	write_blocked = false
	var best: Dictionary = {}
	var invalid := false
	var exists := false
	for slot in range(2):
		var candidate := _read_slot(base_path+"."+str(slot))
		if candidate.is_empty(): continue
		exists = true
		if candidate.get("future",false):
			write_blocked = true
			notice = "This save belongs to a newer game version. Update the game to continue saving."
			continue
		if candidate.get("invalid",false):
			invalid = true
			continue
		if best.is_empty() or candidate.revision>best.revision: best = candidate
	if not best.is_empty():
		revision = best.revision
		if invalid and not write_blocked: notice = "A damaged save was recovered from the previous checkpoint."
		return best.save
	if exists:
		write_blocked = true
		if notice.is_empty(): notice = "Your save could not be read. Existing files have been preserved; saving is disabled."
		return null
	# Original 0.1–0.4 save remains untouched after migration.
	if FileAccess.file_exists(base_path):
		var legacy := ConfigFile.new()
		if legacy.load(base_path)==OK and legacy.has_section("hero") and legacy.has_section("idle"):
			notice = "Your previous save has been upgraded."
			return legacy
		write_blocked = true
		notice = "Your previous save could not be read. It has been preserved; saving is disabled."
	return null

func save_game(payload: ConfigFile) -> Error:
	if write_blocked: return ERR_UNAVAILABLE
	if not payload.has_section("hero") or not payload.has_section("idle"): return ERR_INVALID_DATA
	var slots: Array = [_read_slot(base_path+".0"),_read_slot(base_path+".1")]
	for slot in slots:
		if slot.get("future",false):
			write_blocked = true
			return ERR_UNAVAILABLE
	var revisions: Array[int] = [int(slots[0].get("revision",0)),int(slots[1].get("revision",0))]
	var destination := 0 if revisions[0]<=revisions[1] else 1
	var next_revision := maxi(revision,maxi(revisions[0],revisions[1]))+1
	var body := payload.encode_to_text()
	var envelope := ConfigFile.new()
	envelope.set_value("storage","version",VERSION)
	envelope.set_value("storage","revision",next_revision)
	envelope.set_value("storage","payload",body)
	envelope.set_value("storage","sha256",(str(next_revision)+"\n"+body).sha256_text())
	var target := base_path+"."+str(destination)
	var temporary := target+".tmp"
	var file := FileAccess.open(temporary,FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_string(envelope.encode_to_text())
	file.flush()
	var status := file.get_error()
	file.close()
	if status!=OK: return status
	var verified := _read_slot(temporary)
	if not verified.has("save") or verified.revision!=next_revision: return ERR_FILE_CORRUPT
	status = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),ProjectSettings.globalize_path(target))
	if status==OK: revision = next_revision
	return status
