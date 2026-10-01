extends RefCounted
## Shared reflection colors reveal curved metal even inside dark chambers.
static var sky: Sky

static func reflection_sky() -> Sky:
	if sky!=null: return sky
	var material:=ProceduralSkyMaterial.new()
	material.sky_top_color=Color("354652")
	material.sky_horizon_color=Color("b3a591")
	material.ground_bottom_color=Color("172029")
	material.ground_horizon_color=Color("635647")
	material.sky_curve=0.3
	material.ground_curve=0.3
	material.sun_angle_max=12.0
	sky=Sky.new()
	sky.sky_material=material
	return sky
