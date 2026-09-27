extends Control
## Fullscreen 3D presentation. The game model remains the authority for all damage/rewards.
signal simulation_advanced(events: Array)
var simulation: RefCounted
signal state_changed(description: String)
const DungeonWorld = preload("res://scripts/dungeon_world.gd")
var battery_mode := false
var damage_numbers := true
var render_container: SubViewportContainer
var render_viewport: SubViewport

var character_class := "Vowkeeper"
var region_index := 0
var world: Node3D
var animation_enabled := true:
	set(value):
		animation_enabled = value
		if is_instance_valid(world): world.active = value
var elapsed: float:
	get: return world.elapsed if is_instance_valid(world) else 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var container := SubViewportContainer.new()
	render_container = container
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	var viewport := SubViewport.new()
	render_viewport = viewport
	viewport.size = Vector2i(960,540)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	container.add_child(viewport)
	world = DungeonWorld.new()
	world.character_class = character_class
	world.region_index = region_index
	world.active = animation_enabled
	world.simulation = simulation
	world.simulation_advanced.connect(func(events: Array): simulation_advanced.emit(events))
	world.state_changed.connect(func(value: String): state_changed.emit(value))
	viewport.add_child(world)
	var atmosphere := ColorRect.new()
	atmosphere.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shading := ShaderMaterial.new()
	shading.shader = preload("res://assets/shaders/dungeon_atmosphere.gdshader")
	atmosphere.material = shading
	add_child(atmosphere)
	apply_quality(battery_mode,damage_numbers)


func apply_quality(battery: bool,numbers: bool) -> void:
	battery_mode=battery
	damage_numbers=numbers
	if not is_instance_valid(render_viewport): return
	render_container.stretch_shrink=2 if battery else 1
	render_viewport.msaa_3d=Viewport.MSAA_DISABLED if battery else Viewport.MSAA_2X
	world.damage_numbers=numbers
	world.set_shadows(not battery)
