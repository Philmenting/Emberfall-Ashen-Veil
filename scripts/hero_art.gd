extends Control
## Live lit portrait of the same equipped, skinned 3D heroine used in battle.

const Actor = preload("res://scripts/dungeon_actor.gd")
var character_class := "Vowkeeper"
var equipment: Dictionary = {}
var reduced_motion := false
var battery := false
var portrait := true
var viewport: SubViewport
var stage: Node3D
var actor: Node3D
var camera: Camera3D
var display: TextureRect
var _animation_elapsed := 0.0

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	clip_contents=true
	viewport=SubViewport.new()
	viewport.name="HeroPortraitViewport"
	viewport.own_world_3d=true
	viewport.transparent_bg=true
	viewport.msaa_3d=Viewport.MSAA_2X
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	stage=Node3D.new()
	stage.name="EquippedHeroStage"
	viewport.add_child(stage)
	var environment_node:=WorldEnvironment.new()
	var environment:=Environment.new()
	environment.background_mode=Environment.BG_COLOR
	environment.background_color=Color(0.025,0.028,0.037,0.0)
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color("b5c0d0")
	environment.ambient_light_energy=0.28
	environment.sky=preload("res://scripts/dungeon_lighting.gd").reflection_sky()
	environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	environment_node.environment=environment
	stage.add_child(environment_node)
	var key:=DirectionalLight3D.new()
	key.rotation_degrees=Vector3(-32,115,0)
	key.light_color=Color("e5d5bd")
	key.light_energy=1.35
	stage.add_child(key)
	var rim:=DirectionalLight3D.new()
	rim.rotation_degrees=Vector3(-18,-35,0)
	rim.light_color=Color("a2b2bd")
	rim.light_energy=0.32
	stage.add_child(rim)
	camera=Camera3D.new()
	camera.name="PortraitCamera"
	camera.current=true
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	stage.add_child(camera)
	display=TextureRect.new()
	display.name="LivePortraitTexture"
	display.texture=viewport.get_texture()
	display.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode=TextureRect.STRETCH_SCALE
	display.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(display)
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_resize)
	configure(character_class,equipment)
	_resize()
	set_presentation(reduced_motion,battery)

func configure(class_key: String, equipped: Dictionary = {}) -> void:
	character_class=class_key if class_key in ["Vowkeeper","Arcanist","Ranger"] else "Vowkeeper"
	equipment=equipped.duplicate(true)
	if stage==null: return
	if actor==null:
		actor=Actor.new()
		actor.name="LiveEquippedHero"
		actor.kind=character_class
		stage.add_child(actor)
	actor.configure_equipment(equipment,character_class)
	actor.surface_material.set_shader_parameter("portrait_crop",portrait)
	actor.reduced_motion=reduced_motion
	actor.animate(0.0,false)
	_resize()
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE if battery or reduced_motion else SubViewport.UPDATE_ALWAYS

func set_presentation(motion_reduced: bool, battery_mode: bool = false) -> void:
	reduced_motion=motion_reduced
	battery=battery_mode
	if viewport==null: return
	viewport.msaa_3d=Viewport.MSAA_DISABLED if battery else Viewport.MSAA_2X
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE if battery or reduced_motion else SubViewport.UPDATE_ALWAYS
	if actor!=null: actor.reduced_motion=reduced_motion
	set_process(not battery and not reduced_motion)

func _resize() -> void:
	if viewport==null or camera==null: return
	var render_size:=Vector2i(maxi(int(size.x*1.5),64),maxi(int(size.y*1.5),64))
	viewport.size=Vector2i(mini(render_size.x,720),mini(render_size.y,720))
	var aspect:=float(viewport.size.x)/float(viewport.size.y)
	var anchor: Vector3=actor.portrait_anchor() if actor!=null else Vector3(0,1.87,0)
	var target:=anchor+Vector3(0,-.025,0) if portrait else Vector3(0,1.25,0)
	camera.size=maxf(0.50,0.48/aspect) if portrait else maxf(3.20,2.70/aspect)
	camera.position=target+Vector3(-1.5,.2,-12.0)
	camera.look_at(target)
	if battery or reduced_motion: viewport.render_target_update_mode=SubViewport.UPDATE_ONCE

func _process(delta: float) -> void:
	if actor==null or reduced_motion or battery: return
	_animation_elapsed+=delta
	if _animation_elapsed>=1.0/24.0:
		actor.animate(_animation_elapsed,false)
		_animation_elapsed=0.0
