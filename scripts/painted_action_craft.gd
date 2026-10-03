extends RefCounted
## Authored whole-body phrasing in the painting's local plane. Values are
## presentation only: no simulation time, RNG, position or combat values here.
## pelvis roll, chest roll, chest yaw, head yaw, root x/y (height fractions),
## stance width, forward knee load. Contact is sampled on the real hit event.
const PROFILES := {
	"Vowkeeper": [[-.075,.20,-.24,.12,-.048,-.022,.035,.0], [.105,-.26,.25,-.10,.070,-.045,.050,.055]],
	"Arcanist": [[.035,.13,.18,-.09,-.025,-.016,.0,.0], [-.065,-.19,-.20,.10,.038,-.028,.025,.022]],
	"Ranger": [[-.040,-.105,-.17,.08,-.022,-.020,.025,.0], [.030,.075,.10,-.05,.012,-.018,.025,.012]],
	"raider": [[.075,-.20,.22,-.10,.040,-.045,.015,.0], [-.11,.27,-.24,.12,-.065,-.055,.030,.04]],
	"bulwark": [[.05,-.13,.16,-.07,.025,-.050,.025,.0], [-.075,.20,-.18,.08,-.048,-.075,.035,.03]],
	"hexer": [[-.03,-.12,-.17,.08,.022,-.015,.0,.0], [.055,.19,.20,-.09,-.030,-.025,.010,.01]],
	"elite": [[.07,-.18,.20,-.09,.038,-.035,.030,.0], [-.095,.25,-.24,.11,-.058,-.052,.040,.035]],
	"guardian_0": [[.06,-.18,.22,-.08,.032,-.045,.025,.0], [-.09,.27,-.25,.10,-.052,-.067,.04,.035]],
	"guardian_1": [[-.03,-.12,-.17,.09,.023,-.028,.0,.0], [.055,.19,.20,-.08,-.033,-.045,.020,.022]],
	"guardian_2": [[.03,-.13,.19,-.09,.018,-.020,.010,.0], [-.06,.21,-.22,.11,-.035,-.035,.025,.025]],
	"guardian_3": [[.07,-.21,.25,-.12,.035,-.035,.035,.0], [-.105,.29,-.28,.12,-.060,-.064,.05,.04]],
}

static func sample(key: String, style: String, windup: float, release: float, recovery: float) -> PackedFloat32Array:
	var poses: Array=PROFILES[key]
	var result:=PackedFloat32Array(); result.resize(8)
	var strength:=1.12 if style in ["signature","sunder","judgment","starfall","chain","marked","rain","heavy"] else 1.0
	if style in ["guard","aegis"]: strength=.65
	for i in range(8): result[i]=lerpf(float(poses[0][i]),float(poses[1][i]),release)*windup*recovery*strength
	return result

static func phrase(progress: float) -> Vector2:
	# Set the pose, hold the loaded silhouette, then accelerate into contact.
	# The hold makes a .3 s cast legible without extending its actual duration.
	return Vector2(smoothstep(0.0,.48,progress),pow(smoothstep(.76,1.0,progress),2))

static func recovery(released_seconds: float, duration: float) -> float:
	# A brief follow-through overshoot, then a slower settle into the guard.
	if released_seconds<.065: return 1.0+sin(clampf(released_seconds/.065,0,1)*PI)*.10
	return 1.0-smoothstep(0.0,1.0,clampf((released_seconds-.065)/maxf(duration-.065,.001),0,1))
