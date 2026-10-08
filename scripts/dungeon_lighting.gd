extends RefCounted
## A room's colored masonry and its neutral-lit actors keep different values.
## All helpers configure existing lights; the sole shadow map stays on the key.
const ACTOR_LAYER := 2
static var sky: Sky

static func configure_environment(environment: Environment,theme: Dictionary) -> void:
	var lighting: Dictionary=theme.lighting
	environment.background_mode=Environment.BG_COLOR
	environment.background_color=Color(theme.background)
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color(theme.ambient)
	environment.ambient_light_energy=float(lighting.ambient_energy)
	environment.sky=reflection_sky()
	environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled=true
	environment.fog_light_color=Color(theme.fog)
	environment.fog_density=float(theme.density)

static func configure_room_lights(key: DirectionalLight3D,rim: DirectionalLight3D,actor: DirectionalLight3D,theme: Dictionary) -> void:
	var lighting: Dictionary=theme.lighting
	key.name="RoomKeyLight"
	key.rotation_degrees=Vector3(-52,-36,0)
	key.light_color=Color(lighting.key)
	key.light_energy=float(lighting.key_energy)
	key.shadow_enabled=true
	key.directional_shadow_max_distance=32.0
	key.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL
	rim.name="CharacterRimLight"
	rim.rotation_degrees=Vector3(-24,145,0)
	rim.light_color=Color(lighting.rim)
	rim.light_energy=0.34
	rim.light_cull_mask=ACTOR_LAYER
	rim.shadow_enabled=false
	actor.name="CharacterKeyLight"
	actor.rotation_degrees=Vector3(-34,32,0)
	actor.light_color=Color(lighting.actor)
	actor.light_energy=float(lighting.actor_energy)
	actor.light_cull_mask=ACTOR_LAYER
	actor.shadow_enabled=false

static func configure_actor_fill(fill: OmniLight3D,theme: Dictionary) -> void:
	# A moving pale puddle would erase the floor's contact shadow and make the
	# figure look pasted on. The existing fill instead reaches actor surfaces.
	fill.name="CharacterLocalFill"
	fill.light_color=Color(theme.lighting.fill)
	fill.light_energy=0.82
	fill.omni_range=4.5
	fill.light_cull_mask=ACTOR_LAYER
	fill.shadow_enabled=false
	fill.position=Vector3(0,2.8,0)

static func reflection_sky() -> Sky:
	if sky!=null: return sky
	var material:=ProceduralSkyMaterial.new()
	material.sky_top_color=Color("354450")
	material.sky_horizon_color=Color("a4aaab")
	material.ground_bottom_color=Color("172029")
	material.ground_horizon_color=Color("535351")
	material.sky_curve=0.3
	material.ground_curve=0.3
	material.sun_angle_max=12.0
	sky=Sky.new()
	sky.sky_material=material
	return sky
