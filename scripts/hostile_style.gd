extends RefCounted
## One native rest space: role-specific weight, pigments and action phrases.
## These values fit the existing authored volumes. They never resize skin or
## replace an enemy's skeleton with a character from another source.
const KEYS: Array[String]=["raider","hexer","bulwark","elite","guardian_0","guardian_1","guardian_2","guardian_3"]
const FINISHES: Dictionary={
	"iron":["657078",.70,.60],"silver":["929a9b",.73,.52],
	"bronze":["80715b",.65,.64],"gold":["a18c66",.69,.57],
	"patina":["536a61",.44,.76],"leather":["493c32",.0,.86],
	"wine":["56343a",.0,.93],"violet":["454e61",.0,.92],
	"sage":["424f43",.0,.94],"linen":["968c78",.0,.95],
	"bone":["a49b86",.0,.88],"skin":["81806f",.0,.89],
	"ash":["59574e",.0,.96],"dark":["20272c",.05,.91],
	"soul":["75a99f",.0,.48],"ember":["c58452",.0,.57],
}

static func ordinary_action(key: String) -> String:
	if key=="raider": return "basic"
	if key in ["hexer","guardian_1","guardian_2"]: return "skill"
	return "heavy"

static func recovery_seconds(key: String,action: String) -> float:
	if key=="raider": return .30 if action=="basic" else .38
	if key=="hexer": return .36 if action!="heavy" else .44
	if key=="bulwark": return .44 if action!="heavy" else .50
	if key=="elite": return .40 if action!="heavy" else .46
	if key=="guardian_0": return .46 if action!="heavy" else .56
	if key=="guardian_3": return .48 if action!="heavy" else .56
	return .42 if action!="heavy" else .50

static func finish(key: String,name: String,part: String,original: StandardMaterial3D) -> Dictionary:
	var result: Dictionary={"color":original.albedo_color.srgb_to_linear(),"metal":original.metallic,"rough":original.roughness,"emission":1.0 if original.emission_enabled else 0.0}
	if key not in KEYS or not FINISHES.has(name): return result
	var values: Array=FINISHES[name]
	var pigment: Color=Color(String(values[0])).srgb_to_linear()
	# Distinguish the continuous body from its rear drape and sleeve pieces.
	# The same measured linear factors are applied once when baking the mesh.
	var role:=String(original.resource_name)
	if role.contains(".cape"): pigment*=.62
	elif role.contains(".sole"): pigment*=.76
	elif role.contains(".sleeve"): pigment*=1.16
	if key=="guardian_0" and name=="bronze": pigment=Color("857052").srgb_to_linear()
	elif key=="guardian_2" and name=="silver": pigment=Color("87918d").srgb_to_linear()
	# Censer/core inlays remain the only luminous pieces, with restrained
	# intensity. Cloth and cast metal respond to the dungeon's actual lights.
	var glow:=.52 if name=="soul" else (.60 if name=="ember" else 0.0)
	if part=="Weapon": glow*=.85
	return {"color":pigment,"metal":float(values[1]),"rough":float(values[2]),"emission":glow}

static func _change(state: Dictionary,changes: Dictionary) -> Dictionary:
	var result:=state.duplicate(true)
	result.merge(changes,true)
	return result

static func phrase(key: String,action: String,spec: Dictionary) -> Dictionary:
	if key not in KEYS: return spec
	var result:=spec.duplicate(true)
	if key=="raider":
		# Scavenger: low compact chamber, a direct hooked-claw jab and a short
		# elbow catch. The weapon's negative-Y claw points into the target plane.
		result.guard=_change(spec.guard,{"hip":Vector3(0,-.14,.025),"right":Vector3(.37,1.03,-.20),"left":Vector3(-.34,1.00,-.24),"weapon":Vector3(.20,.02,.12)})
		result.gather=_change(result.guard,{"hip":Vector3(.04,-.20,.055),"chest":Vector3(-.08,-.20,-.04),"right":Vector3(.44,1.09,-.12),"left":Vector3(-.31,1.01,-.30),"weapon":Vector3(.36,-.12,.23)})
		result.load=_change(result.gather,{"hip":Vector3(.075,-.265,.075),"pelvis":Vector3(.02,-.26,.035),"chest":Vector3(-.04,-.35,-.07),"right":Vector3(.46,1.11,.015),"weapon":Vector3(.26,-.16,.24)})
		result.drive=_change(result.load,{"hip":Vector3(.01,-.18,-.08),"pelvis":Vector3(-.035,.16,-.035),"chest":Vector3(-.20,.05,.035),"right":Vector3(.24,1.08,-.49),"weapon":Vector3(.91,-.05,.09),"cloth":Vector3(.08,-.045,.025)})
		result.contact=_change(result.drive,{"hip":Vector3(-.05,-.225,-.16),"chest":Vector3(-.23,.17,.04),"right":Vector3(.11,1.02,-.63),"weapon":Vector3(1.15,.04,.07),"left":Vector3(-.38,.98,-.29)})
		result.follow=_change(result.contact,{"hip":Vector3(-.065,-.24,-.145),"right":Vector3(.10,.97,-.64),"weapon":Vector3(1.21,.08,.09),"cloth":Vector3(.12,.02,.015)})
		result["return"]=_change(result.guard,{"hip":Vector3(-.02,-.18,-.025),"chest":Vector3(-.16,.07,.015),"right":Vector3(.28,.99,-.37),"weapon":Vector3(.80,.03,.13)})
	elif key=="bulwark":
		# Shield moves into the line before the shoulder-led descending cut.
		# Its off-hand stays in front of the chest through the full recovery.
		for name in ["guard","gather","load","drive","contact","follow","return"]:
			result[name].left=Vector3(-.33,1.03,-.41)
			result[name].left_pole=Vector3(-.65,-.20,-.50)
		result.load=_change(result.load,{"hip":Vector3(.065,-.255,.07),"chest":Vector3(.14,-.25,-.06),"right":Vector3(.34,1.50,.02),"weapon":Vector3(.53,-.12,-.24)})
		result.contact=_change(result.contact,{"hip":Vector3(-.045,-.235,-.145),"right":Vector3(.20,.98,-.56),"weapon":Vector3(-1.15,.02,-.15),"chest":Vector3(-.28,.15,.025)})
		result.follow=_change(result.contact,{"hip":Vector3(-.06,-.26,-.13),"right":Vector3(.15,.82,-.40),"weapon":Vector3(-1.66,.08,-.19)})
	elif key=="elite":
		# One unshielded counterbalancing arm leaves room for a diagonal blade.
		result.guard.left=Vector3(-.34,1.02,-.16)
		result.load=_change(result.load,{"hip":Vector3(.085,-.245,.075),"right":Vector3(.41,1.46,.03),"left":Vector3(-.44,1.09,.055),"weapon":Vector3(.53,-.24,-.45)})
		result.contact=_change(result.contact,{"right":Vector3(.02,1.05,-.61),"left":Vector3(-.39,1.05,-.09),"weapon":Vector3(-1.18,.19,.27)})
		result.follow=_change(result.follow,{"right":Vector3(-.15,.94,-.40),"left":Vector3(-.37,1.03,-.13),"weapon":Vector3(-1.60,.25,.48)})
	elif key=="guardian_0":
		# The Bell Warden lifts one mace while the censer balances below the
		# other fist. Hip extension precedes the bell drop; the knees catch it.
		result.guard=_change(spec.guard,{"hip":Vector3(0,-.065,0),"chest":Vector3(.015,.035,0),"right":Vector3(.37,1.17,-.16),"left":Vector3(-.35,1.10,-.17),"weapon":Vector3(-.20,.01,-.12)})
		result.gather=_change(result.guard,{"hip":Vector3(.035,-.16,.055),"pelvis":Vector3(.025,-.13,.025),"chest":Vector3(.11,-.13,-.035),"right":Vector3(.38,1.39,.06),"left":Vector3(-.37,1.04,-.12),"weapon":Vector3(.12,-.04,-.19),"cloth":Vector3(-.025,.025,-.025)})
		result.load=_change(result.gather,{"hip":Vector3(.065,-.255,.08),"pelvis":Vector3(.04,-.22,.035),"chest":Vector3(.20,-.21,-.05),"right":Vector3(.32,1.59,.12),"weapon":Vector3(.34,-.08,-.18),"knee_r":Vector3(.40,0,-1),"cloth":Vector3(-.06,.045,-.035)})
		result.drive=_change(result.load,{"hip":Vector3(.005,-.115,-.07),"pelvis":Vector3(-.06,.13,-.035),"chest":Vector3(-.13,-.10,.035),"right":Vector3(.29,1.35,-.35),"left":Vector3(-.39,1.09,-.19),"weapon":Vector3(-.63,-.02,-.11),"cloth":Vector3(.095,-.07,.025)})
		result.contact=_change(result.drive,{"hip":Vector3(-.055,-.245,-.165),"pelvis":Vector3(-.10,.22,-.045),"chest":Vector3(-.30,.14,.035),"right":Vector3(.22,.90,-.61),"left":Vector3(-.39,1.03,-.24),"weapon":Vector3(-1.53,.02,-.13),"cloth":Vector3(.15,-.07,.035)})
		result.follow=_change(result.contact,{"hip":Vector3(-.07,-.28,-.145),"chest":Vector3(-.34,.22,.035),"right":Vector3(.17,.78,-.45),"weapon":Vector3(-1.85,.05,-.19),"cloth":Vector3(.19,.02,.025)})
		result["return"]=_change(result.guard,{"hip":Vector3(-.025,-.135,-.025),"chest":Vector3(-.11,.08,.015),"right":Vector3(.31,1.00,-.28),"weapon":Vector3(-.73,.025,-.16),"cloth":Vector3(.06,.035,-.01)})
		if action!="heavy":
			result.load.right=Vector3(.36,1.44,.07)
			result.load.weapon=Vector3(.19,-.055,-.18)
	# Spell enemies retain the directed native palm/staff phrase. Their
	# individual recovery duration and gait keep the same bones/sockets.
	return result

static func gait(key: String,u: float,state: Dictionary) -> Dictionary:
	if key not in KEYS: return state
	var result:=state.duplicate(true)
	var armored:=key in ["bulwark","elite","guardian_0","guardian_3"]
	var swing:=sin(u*TAU)
	result.chest=Vector3(-.035,.022*swing,.007*swing) if armored else Vector3(-.07,.045*swing,.014*swing)
	result.pelvis=Vector3(0,-Vector3(result.chest).y*.42,0)
	if key=="raider": result.chest.x=-.17; result.hip.y-=.055
	if key=="guardian_0":
		result.right+=Vector3(0,.014*swing,.025*swing)
		result.left+=Vector3(0,-.012*swing,-.02*swing)
	return result
