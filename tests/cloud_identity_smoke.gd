extends SceneTree

const CloudSave = preload("res://scripts/cloud_save.gd")
var checks := 0
var failures := 0
var folder := "user://cloud-identity-" + str(Time.get_ticks_usec())

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)

func run_checks() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var cloud = CloudSave.new()
	cloud.identity_path = folder + "/identity.cfg"
	check(not cloud.local_guest_exists() and cloud.transfer_code().is_empty(), "new install has no local account or transfer key")
	check(not cloud._valid_device_id("short") and not cloud._valid_device_id("z".repeat(32)), "malformed and non-hex device IDs are rejected")
	var first_device := "00112233445566778899aabbccddeeff"
	var transfer_key := "ffeeddccbbaa99887766554433221100"
	var replacement_device := "1234567890abcdef1234567890abcdef"
	check(cloud._valid_device_id(first_device.to_upper()), "hexadecimal IDs accept clipboard case variations")
	check(cloud._store_identity(first_device, transfer_key), "initial guest ID and transfer key are written atomically")
	check(cloud.local_guest_exists() and cloud._load_guest_id(false) == first_device, "saved guest ID reloads from the identity file")
	check(cloud.transfer_code() == transfer_key, "saved transfer key reloads for display or revocation")
	var previous_path: String = cloud.identity_path + ".previous"
	check(DirAccess.rename_absolute(ProjectSettings.globalize_path(cloud.identity_path), ProjectSettings.globalize_path(previous_path)) == OK, "crash-recovery fixture leaves the previous identity between rename steps")
	check(cloud._load_guest_id(false) == first_device and cloud.transfer_code() == transfer_key and FileAccess.file_exists(cloud.identity_path) and not FileAccess.file_exists(previous_path), "interrupted identity replacement restores the previous valid account")
	check(not cloud._store_identity("invalid", "") and cloud._load_guest_id(false) == first_device and cloud.transfer_code() == transfer_key, "invalid replacement cannot overwrite a valid identity")
	check(cloud._store_identity(replacement_device, ""), "rotated guest ID replaces the old identity")
	check(cloud._load_guest_id(false) == replacement_device and cloud.transfer_code().is_empty(), "rotation clears the consumed transfer key")
	check(not FileAccess.file_exists(cloud.identity_path + ".tmp") and not FileAccess.file_exists(cloud.identity_path + ".previous"), "successful identity rotation leaves no staging or recovery file behind")
	cloud.identity_path = folder + "/generated.cfg"
	var generated := cloud._load_guest_id(true)
	check(cloud._valid_device_id(generated) and cloud.local_guest_exists(), "missing guest IDs are generated from 128 random bits and persisted")
	check(cloud._load_guest_id(false) == generated, "generated guest ID survives a cold read")
	cloud.free()
	print("CLOUD IDENTITY SMOKE: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
