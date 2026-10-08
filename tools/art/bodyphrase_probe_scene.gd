extends SceneTree
## Use an absolute --script path to probe another isolated project's sources.
func _initialize() -> void: launch.call_deferred()
func launch() -> void:
	var driver_script=load(get_script().resource_path.get_base_dir()+"/bodyphrase_probe.gd")
	var driver:Control=driver_script.new()
	driver.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(driver)
