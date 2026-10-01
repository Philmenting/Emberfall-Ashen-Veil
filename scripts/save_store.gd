extends RefCounted
## Two validated generations. Only the older slot is replaced, by atomic rename.
const VERSION := 1
const MAX_BYTES := 4 * 1024 * 1024
const BACKUP_PREFIX := "EMBERFALL-SAVE-1|"
var base_path := "user://emberfall.save"
var revision := 0
var notice := ""
var write_blocked := false

func _init(path: String = "user://emberfall.save") -> void:
	base_path = path

func create_backup_code(payload: ConfigFile) -> String:
	if not payload.has_section("hero") or not payload.has_section("idle"): return ""
	var body:=payload.encode_to_text()
	var bytes:=body.to_utf8_buffer()
	if bytes.size()>MAX_BYTES: return ""
	return BACKUP_PREFIX+Marshalls.raw_to_base64(bytes)+"|"+body.sha256_text()

func parse_backup_code(code: String) -> ConfigFile:
	var normalized:=code.strip_edges().replace("\n","").replace("\r","").replace(" ","")
	if normalized.length()>MAX_BYTES*2+128: return null
	if not normalized.begins_with(BACKUP_PREFIX): return null
	var digest_separator:=normalized.rfind("|")
	if digest_separator<=BACKUP_PREFIX.length() or digest_separator==normalized.length()-1: return null
	var encoded:=normalized.substr(BACKUP_PREFIX.length(),digest_separator-BACKUP_PREFIX.length())
	var digest:=normalized.substr(digest_separator+1)
	var bytes:=Marshalls.base64_to_raw(encoded)
	if bytes.is_empty() or bytes.size()>MAX_BYTES: return null
	var body:=bytes.get_string_from_utf8()
	if body.sha256_text()!=digest: return null
	var payload:=ConfigFile.new()
	if payload.parse(body)!=OK or not payload.has_section("hero") or not payload.has_section("idle"): return null
	return payload

func load_recovery_copy() -> ConfigFile:
	var best: Dictionary={}
	for index in range(2):
		var candidate:=_read_slot(base_path+"."+str(index)+".pre_restore")
		if candidate.has("save") and (best.is_empty() or candidate.revision>best.revision): best=candidate
	if not best.is_empty(): return best.save
	var legacy_path:=base_path+".pre_restore_legacy"
	if FileAccess.file_exists(legacy_path):
		var legacy:=ConfigFile.new()
		if legacy.load(legacy_path)==OK and legacy.has_section("hero") and legacy.has_section("idle"): return legacy
	return null

func restore_backup(payload: ConfigFile) -> Error:
	if write_blocked:
		for slot in range(2):
			if _read_slot(base_path+"."+str(slot)).get("future",false): return ERR_UNAVAILABLE
	if not payload.has_section("hero") or not payload.has_section("idle"): return ERR_INVALID_DATA
	var slots: Array=[_read_slot(base_path+".0"),_read_slot(base_path+".1")]
	for slot in slots:
		if slot.get("future",false): return ERR_UNAVAILABLE
	var next_revision:=maxi(revision,maxi(int(slots[0].get("revision",0)),int(slots[1].get("revision",0))))+1
	var targets: Array[String]=[base_path+".0",base_path+".1"]
	var temporaries: Array[String]=[base_path+".restore.0",base_path+".restore.1"]
	for temporary in temporaries:
		_remove_file(temporary)
	var status:=_write_slot(temporaries[0],payload,next_revision)
	if status!=OK:
		_remove_file(temporaries[0])
		return status
	status=_write_slot(temporaries[1],payload,next_revision+1)
	if status!=OK:
		_remove_file(temporaries[0]); _remove_file(temporaries[1])
		return status
	var moved_original: Array[bool]=[false,false]
	var installed: Array[bool]=[false,false]
	var legacy_path:=base_path+".pre_restore_legacy"
	var legacy_moved:=false
	if FileAccess.file_exists(base_path):
		_remove_file(legacy_path)
		status=_rename_file(base_path,legacy_path)
		if status!=OK:
			_remove_file(temporaries[0]); _remove_file(temporaries[1])
			return status
		legacy_moved=true
	for index in range(2):
		var previous_path:=targets[index]+".pre_restore"
		if FileAccess.file_exists(targets[index]):
			_remove_file(previous_path)
			status=_rename_file(targets[index],previous_path)
			if status!=OK:
				_rollback_restore(targets,temporaries,moved_original,installed)
				if legacy_moved and not FileAccess.file_exists(base_path): _rename_file(legacy_path,base_path)
				_remove_file(temporaries[0]); _remove_file(temporaries[1])
				return status
			moved_original[index]=true
		status=_rename_file(temporaries[index],targets[index])
		if status!=OK:
			_rollback_restore(targets,temporaries,moved_original,installed)
			if legacy_moved and not FileAccess.file_exists(base_path): _rename_file(legacy_path,base_path)
			_remove_file(temporaries[0]); _remove_file(temporaries[1])
			return status
		installed[index]=true
	revision=next_revision+1
	write_blocked=false
	notice="Backup restored. Your previous local save is preserved in a recovery copy."
	return OK

func _rollback_restore(targets: Array[String],temporaries: Array[String],moved_original: Array[bool],installed: Array[bool]) -> void:
	for index in range(1,-1,-1):
		if installed[index] and FileAccess.file_exists(targets[index]): _rename_file(targets[index],temporaries[index])
		if moved_original[index] and FileAccess.file_exists(targets[index]+".pre_restore"): _rename_file(targets[index]+".pre_restore",targets[index])

func _write_slot(path: String,payload: ConfigFile,next_revision: int) -> Error:
	var body:=payload.encode_to_text()
	var envelope:=ConfigFile.new()
	envelope.set_value("storage","version",VERSION)
	envelope.set_value("storage","revision",next_revision)
	envelope.set_value("storage","payload",body)
	envelope.set_value("storage","sha256",(str(next_revision)+"\n"+body).sha256_text())
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_string(envelope.encode_to_text())
	file.flush()
	var status:=file.get_error()
	file.close()
	if status!=OK: return status
	var verified:=_read_slot(path)
	return OK if verified.has("save") and verified.revision==next_revision else ERR_FILE_CORRUPT

func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _rename_file(source: String,destination: String) -> Error:
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(source),ProjectSettings.globalize_path(destination))

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
	var target := base_path+"."+str(destination)
	var temporary := target+".tmp"
	var status := _write_slot(temporary,payload,next_revision)
	if status!=OK: return status
	status = _rename_file(temporary,target)
	if status==OK: revision = next_revision
	return status
