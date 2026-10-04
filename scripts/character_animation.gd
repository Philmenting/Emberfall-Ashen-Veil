extends RefCounted
## Authored spatial action phrases, compiled once into native Animation resources.
## Hand and sole targets are solved when clips are authored. No sinusoidal attack
## rotations, sprite swaps, mutable vertices or simulation timers live here.
const NAMES: Array[String]=["Root","Pelvis","Chest","Head","ClavicleL","UpperArmL","ForearmL","HandL","ClavicleR","UpperArmR","ForearmR","HandR","ThighL","ShinL","FootL","ThighR","ShinR","FootR","Cape","CapeTip","Weapon","BowUpper","BowString","BowLower","Arrow","CoatL","CoatR","HairL","HairR"]
const PARENTS: Array[int]=[-1,0,1,2,2,4,5,6,2,8,9,10,1,12,13,1,15,16,2,18,11,20,20,20,22,1,1,3,3]
const RECOVERY:=.34

static func create(key: String,rests: Array[Transform3D]) -> AnimationLibrary:
	var locals: Array[Transform3D]=[]
	for i in NAMES.size():
		var parent:=_parent(i,key)
		locals.append(rests[i] if parent<0 else rests[parent].affine_inverse()*rests[i])
	var library:=AnimationLibrary.new()
	for name in ["idle","walk","windup_basic","windup_skill","windup_heavy","recover_basic","recover_skill","recover_heavy","death"]:
		var animation:=Animation.new()
		animation.resource_name=key+"/"+name
		animation.length=4.2 if name=="idle" else (RECOVERY if name.begins_with("recover") else (.90 if name=="death" else 1.0))
		animation.loop_mode=Animation.LOOP_LINEAR if name in ["idle","walk"] else Animation.LOOP_NONE
		var tracks: Array[Vector3i]=[]
		for bone in NAMES.size():
			var pos:=animation.add_track(Animation.TYPE_POSITION_3D)
			var rot:=animation.add_track(Animation.TYPE_ROTATION_3D)
			var scale:=animation.add_track(Animation.TYPE_SCALE_3D)
			for track in [pos,rot,scale]: animation.track_set_path(track,NodePath("CharacterSkeleton:"+NAMES[bone]))
			tracks.append(Vector3i(pos,rot,scale))
		var frames:=48 if name=="walk" else (60 if name=="idle" else 36)
		for sample in range(frames+1):
			var u:=float(sample)/frames
			var poses:=_author(key,name,u,locals)
			for bone in NAMES.size():
				var time:=u*animation.length
				animation.position_track_insert_key(tracks[bone].x,time,poses[bone].origin)
				var basis:=poses[bone].basis
				var arrow_visible:=basis.get_scale().length_squared()>.01
				animation.rotation_track_insert_key(tracks[bone].y,time,basis.get_rotation_quaternion() if arrow_visible else Quaternion.IDENTITY)
				animation.scale_track_insert_key(tracks[bone].z,time,basis.get_scale())
		library.add_animation(name,animation)
	return library

static func _parent(bone: int,key: String) -> int:
	return 7 if bone==20 and key=="Ranger" else PARENTS[bone]

static func stance_foot(key: String,side: int) -> Vector3:
	var foot:=Vector3(-.20 if side==0 else .22,.117 if key in ["Vowkeeper","Arcanist","Ranger"] else .10,0)
	foot.z=(-.25 if side==0 else .20) if key=="Ranger" else (-.235 if side==0 else .19)
	if key in ["guardian_0","guardian_3","bulwark","elite"]: foot.x*=1.18
	return foot

static func global_pose(p: Array[Transform3D],bone: int,key: String) -> Transform3D:
	var transform:=p[bone]
	var parent:=_parent(bone,key)
	while parent>=0:
		transform=p[parent]*transform
		parent=_parent(parent,key)
	return transform

static func global_rotation(p: Array[Transform3D],bone: int,basis: Basis,key: String) -> void:
	var parent:=_parent(bone,key)
	p[bone].basis=basis if parent<0 else global_pose(p,parent,key).basis.inverse()*basis

static func solve_two(p: Array[Transform3D],upper: int,lower: int,end: int,target: Vector3,pole: Vector3,key: String) -> void:
	var start:=global_pose(p,upper,key).origin
	var a:=p[lower].origin.length(); var b:=p[end].origin.length()
	var direction:=target-start
	var distance:=clampf(direction.length(),sqrt(a*a+b*b+2.0*a*b*cos(2.40)),a+b-.001)
	direction=direction.normalized() if direction.length()>.001 else Vector3.DOWN
	var bend:=pole-direction*pole.dot(direction)
	if bend.length_squared()<.0001: bend=Vector3.RIGHT-direction*direction.x
	bend=bend.normalized()
	var along:=(a*a-b*b+distance*distance)/(2.0*distance)
	var elbow:=start+direction*along+bend*sqrt(maxf(0.0,a*a-along*along))
	var finish:=start+direction*distance
	global_rotation(p,upper,Basis(Quaternion(p[lower].origin.normalized(),(elbow-start).normalized())),key)
	global_rotation(p,lower,Basis(Quaternion(p[end].origin.normalized(),(finish-elbow).normalized())),key)

static func _spec(key: String,action: String="basic") -> Dictionary:
	var ranger:=key=="Ranger"
	var caster:=key in ["Arcanist","hexer","guardian_1","guardian_2"]
	var raider:=key=="raider"
	var skill:=action=="skill"
	var heavy:=action=="heavy"
	# Each phrase has a gathering pose, a held chamber, a passing pose, contact,
	# follow-through and a separate return path. Skill cuts/casts are authored
	# in their own planes; they are not the basic pose multiplied by a gain.
	var guard: Dictionary={"hip":Vector3(0,-.055,0),"pelvis":Vector3(0,.025,0),"chest":Vector3(0,.08,0),"right":Vector3(.32,1.10,-.20),"left":Vector3(-.38,1.24,-.29),"weapon":Vector3(-.18,0,-.15),"palm":Vector3(-.14,0,-.10),"left_pole":Vector3(-1,-.10,.35),"right_pole":Vector3(1,-.10,.40),"knee_l":Vector3(-.16,0,-1),"knee_r":Vector3(.18,0,-1),"cloth":Vector3(.016,0,0),"draw":0.0,"arrow":0.0,"nock":0.0,"support":0.0}
	if caster:
		guard.right=Vector3(.34,1.03,-.09); guard.left=Vector3(-.17,1.19,-.22)
		guard.chest=Vector3(0,-.10,0); guard.pelvis=Vector3(0,-.03,0); guard.weapon=Vector3(-.12,0,-.12)
	elif ranger:
		guard.left=Vector3(-.35,1.01,-.16); guard.right=Vector3(.24,1.13,-.13)
		guard.chest=Vector3(-.02,-.18,0); guard.pelvis=Vector3(0,-.06,0); guard.weapon=Vector3(0,0,-.13)
	elif raider:
		guard.hip=Vector3(0,-.14,.025); guard.chest=Vector3(-.14,0,0)
		guard.right=Vector3(.39,1.02,-.31); guard.left=Vector3(-.39,1.03,-.28)
		guard.weapon=Vector3.ZERO
	# The rear knee receives the load; its extension drives the pelvis ahead
	# of the rib cage. The front knee then absorbs contact, still on its sole.
	var gather:=_change(guard,{"hip":Vector3(.065,-.15,.06),"pelvis":Vector3(.015,-.18,.055),"chest":Vector3(.10,-.20,-.065),"right":Vector3(.44,1.30,.13),"left":Vector3(-.35,1.23,-.35),"weapon":Vector3(.42,-.12,-.48),"knee_r":Vector3(.36,0,-1),"cloth":Vector3(-.025,.02,-.035)})
	var load:=_change(gather,{"hip":Vector3(.10,-.235,.085),"pelvis":Vector3(.025,-.30,.065),"chest":Vector3(.14,-.40,-.11),"right":Vector3(.46,1.47,.09),"left":Vector3(-.33,1.20,-.36),"weapon":Vector3(.62,-.32,-.66),"knee_l":Vector3(-.10,0,-1),"knee_r":Vector3(.43,0,-1),"cloth":Vector3(-.055,.04,-.035)})
	var drive:=_change(load,{"hip":Vector3(.015,-.14,-.065),"pelvis":Vector3(-.035,.22,-.065),"chest":Vector3(-.13,-.31,.04),"right":Vector3(.40,1.36,-.35),"left":Vector3(-.35,1.19,-.47),"weapon":Vector3(-.48,-.18,-.48),"knee_l":Vector3(-.26,0,-1),"knee_r":Vector3(.18,0,-1),"cloth":Vector3(.085,-.09,.045)})
	var contact:=_change(drive,{"hip":Vector3(-.075,-.19,-.175),"pelvis":Vector3(-.08,.32,-.06),"chest":Vector3(-.24,.18,.08),"right":Vector3(.035,.99,-.65),"left":Vector3(-.35,1.12,-.46),"weapon":Vector3(-1.31,.16,.12),"knee_l":Vector3(-.30,0,-1),"cloth":Vector3(.13,-.085,.055)})
	var follow:=_change(contact,{"hip":Vector3(-.105,-.235,-.17),"pelvis":Vector3(-.09,.38,-.035),"chest":Vector3(-.28,.32,.065),"right":Vector3(-.17,.80,-.42),"left":Vector3(-.34,1.05,-.40),"weapon":Vector3(-1.78,.30,.54),"cloth":Vector3(.19,-.02,.025)})
	var return_pose:=_change(guard,{"hip":Vector3(-.045,-.13,-.065),"pelvis":Vector3(-.015,.17,.01),"chest":Vector3(-.10,.035,.025),"right":Vector3(.25,.88,-.29),"left":Vector3(-.35,1.17,-.34),"weapon":Vector3(-.81,.10,.20),"cloth":Vector3(.065,.035,-.02)})
	if skill and not caster and not ranger:
		# Shield closes before a committed descending cut. Recovery lifts the
		# blade back beside the hip instead of replaying the strike backwards.
		gather=_change(gather,{"left":Vector3(-.29,1.20,-.40),"right":Vector3(.30,1.39,.12),"weapon":Vector3(.58,-.08,-.22)})
		load=_change(load,{"hip":Vector3(.08,-.25,.095),"pelvis":Vector3(.035,-.24,.055),"chest":Vector3(.17,-.32,-.09),"right":Vector3(.27,1.60,.07),"left":Vector3(-.30,1.22,-.39),"weapon":Vector3(.66,-.08,-.14)})
		drive=_change(drive,{"hip":Vector3(.015,-.14,-.06),"pelvis":Vector3(-.03,.16,-.05),"chest":Vector3(-.13,-.22,.04),"right":Vector3(.29,1.38,-.35),"weapon":Vector3(-.55,-.04,-.12),"left":Vector3(-.34,1.19,-.48)})
		contact=_change(contact,{"hip":Vector3(-.06,-.225,-.19),"pelvis":Vector3(-.105,.23,-.05),"chest":Vector3(-.32,.14,.06),"right":Vector3(.21,.91,-.67),"weapon":Vector3(-1.47,.02,-.12)})
		follow=_change(follow,{"hip":Vector3(-.08,-.255,-.18),"pelvis":Vector3(-.12,.27,-.035),"chest":Vector3(-.34,.20,.04),"right":Vector3(.10,.74,-.46),"weapon":Vector3(-1.91,.07,-.18)})
		return_pose=_change(return_pose,{"right":Vector3(.33,.89,-.26),"weapon":Vector3(-.78,.02,-.28)})
	if caster:
		# Gather close to the sternum with the staff beside the rear hip. The
		# front knee and pelvis carry one directed palm/staff thrust at the
		# target; the off hand never opens into a symmetrical raised tableau.
		gather=_change(guard,{"hip":Vector3(.055,-.13,.06),"pelvis":Vector3(.015,-.15,.03),"chest":Vector3(.065,-.16,-.04),"right":Vector3(.36,.96,.11),"left":Vector3(-.08,1.20,-.035),"weapon":Vector3(.30,.06,-.18),"palm":Vector3(-.30,.25,-.15),"left_pole":Vector3(-.65,-.40,.35),"right_pole":Vector3(1,-.35,.25),"knee_r":Vector3(.30,0,-1),"cloth":Vector3(-.025,.025,-.02)})
		load=_change(gather,{"hip":Vector3(.075,-.19,.08),"pelvis":Vector3(.025,-.22,.045),"chest":Vector3(.10,-.32,-.06),"right":Vector3(.37,1.01,.14),"left":Vector3(.045,1.17,-.13),"weapon":Vector3(.27,.05,-.16),"palm":Vector3(-.62,.23,-.10),"knee_r":Vector3(.38,0,-1),"cloth":Vector3(-.035,.04,-.03)})
		drive=_change(load,{"hip":Vector3(.01,-.10,-.075),"pelvis":Vector3(-.055,.18,-.035),"chest":Vector3(-.18,-.11,.03),"right":Vector3(.36,1.02,-.17),"left":Vector3(-.13,1.22,-.45),"weapon":Vector3(-.75,.02,-.15),"palm":Vector3(-1.18,.03,-.08),"knee_l":Vector3(-.24,0,-1),"knee_r":Vector3(.16,0,-1),"cloth":Vector3(.08,-.04,.025)})
		contact=_change(drive,{"hip":Vector3(-.025,-.145,-.185),"pelvis":Vector3(-.08,.19,-.035),"chest":Vector3(-.26,.11,.025),"right":Vector3(.30,1.08,-.33),"left":Vector3(-.18,1.10,-.64),"weapon":Vector3(-1.00,.04,-.12),"palm":Vector3(-1.40,.02,0),"cloth":Vector3(.125,-.05,.03)})
		follow=_change(contact,{"hip":Vector3(-.035,-.18,-.18),"pelvis":Vector3(-.095,.23,-.025),"chest":Vector3(-.27,.20,.04),"right":Vector3(.29,1.02,-.37),"left":Vector3(-.19,1.035,-.66),"weapon":Vector3(-1.10,.05,-.10),"cloth":Vector3(.17,.01,.01)})
		return_pose=_change(guard,{"hip":Vector3(-.02,-.115,-.055),"pelvis":Vector3(-.025,.09,-.015),"chest":Vector3(-.10,-.045,.015),"right":Vector3(.35,.94,-.16),"left":Vector3(-.22,1.05,-.36),"weapon":Vector3(-.55,0,-.15),"palm":Vector3(-.65,.10,-.10),"cloth":Vector3(.065,.03,-.015)})
		if skill or heavy:
			# The stronger cast coils across the body and drives down through the
			# forward contact plane, with an asymmetric low staff counterweight.
			load=_change(load,{"hip":Vector3(.08,-.225,.09),"pelvis":Vector3(.025,-.27,.045),"chest":Vector3(.12,-.35,-.07),"right":Vector3(.39,1.08,.06),"left":Vector3(.045,1.21,-.16),"weapon":Vector3(.30,-.20,-.45),"palm":Vector3(-.58,-.12,-.16)})
			drive=_change(drive,{"hip":Vector3(.015,-.105,-.08),"right":Vector3(.36,1.10,-.18),"left":Vector3(-.17,1.20,-.48),"weapon":Vector3(-.64,.10,-.25)})
			contact=_change(contact,{"hip":Vector3(-.05,-.20,-.20),"pelvis":Vector3(-.09,.24,-.045),"chest":Vector3(-.34,.13,.045),"right":Vector3(.30,1.15,-.30),"left":Vector3(-.20,1.04,-.66),"weapon":Vector3(-.90,.12,-.18),"palm":Vector3(-1.58,.05,-.10)})
			follow=_change(follow,{"hip":Vector3(-.055,-.225,-.18),"chest":Vector3(-.35,.21,.035),"right":Vector3(.30,1.05,-.35),"left":Vector3(-.22,.94,-.59),"weapon":Vector3(-1.02,.08,-.15)})
	elif ranger:
		# Raise/nock, draw to the cheek, aim, release, hold the bow arm, lower.
		# The right-hand target is solved against the real nock during draw.
		gather=_change(guard,{"hip":Vector3(.02,-.105,.025),"pelvis":Vector3(0,-.10,-.015),"chest":Vector3(-.025,-.30,.015),"left":Vector3(-.19,1.34,-.56),"weapon":Vector3(-.015,.025,-.015),"draw":.035,"arrow":1.0,"nock":1.0,"right_pole":Vector3(1,.35,.95),"left_pole":Vector3(-1,-.15,.15),"knee_l":Vector3(-.24,0,-1),"knee_r":Vector3(.30,0,-1),"cloth":Vector3(-.02,.025,0)})
		load=_change(gather,{"hip":Vector3(.045,-.17,.015),"pelvis":Vector3(0,-.20,-.035),"chest":Vector3(-.035,-.56,.025),"left":Vector3(-.17,1.46,-.64),"draw":.34,"cloth":Vector3(.008,.04,-.01)})
		if skill:
			load=_change(load,{"hip":Vector3(.05,-.205,.025),"chest":Vector3(-.07,-.61,.025),"left":Vector3(-.17,1.45,-.64),"weapon":Vector3(-.07,-.045,-.025),"draw":.36})
		load.right=Vector3(load.left)+Basis.from_euler(load.weapon)*Vector3(0,0,.34+float(load.draw))
		drive=load.duplicate(true)
		contact=_change(load,{"draw":0.0,"arrow":0.0,"nock":0.0})
		follow=_change(contact,{"hip":Vector3(.045,-.145,.025),"right":Vector3(load.right)+Vector3(.25,.015,.145),"chest":Vector3(-.025,-.43,.025),"cloth":Vector3(.045,-.02,0)})
		return_pose=_change(guard,{"hip":Vector3(.025,-.105,.01),"pelvis":Vector3(0,-.12,-.015),"chest":Vector3(-.02,-.28,.015),"left":Vector3(-.25,1.20,-.40),"right":Vector3(.18,1.20,.13),"weapon":Vector3(-.035,0,-.085),"cloth":Vector3(.025,-.025,0)})
	elif raider:
		gather=_change(gather,{"hip":Vector3(.065,-.235,.06),"chest":Vector3(-.03,-.23,-.08),"right":Vector3(.49,1.07,.015),"left":Vector3(-.36,1.03,-.34),"weapon":Vector3(-.38,0,.18)})
		load=_change(load,{"hip":Vector3(.10,-.315,.09),"chest":Vector3(.03,-.43,-.10),"right":Vector3(.50,1.15,.03),"left":Vector3(-.30,1.06,-.34),"weapon":Vector3(-.78,-.10,.26)})
		drive=_change(drive,{"hip":Vector3(.015,-.18,-.075),"right":Vector3(.38,1.17,-.45),"weapon":Vector3(.12,-.08,.02)})
		contact=_change(contact,{"hip":Vector3(-.065,-.255,-.19),"chest":Vector3(-.27,.25,.09),"right":Vector3(.05,.96,-.67),"left":Vector3(-.36,.97,-.37),"weapon":Vector3(.80,.08,-.30)})
		follow=_change(follow,{"hip":Vector3(-.09,-.29,-.15),"chest":Vector3(-.31,.38,.08),"right":Vector3(-.16,.84,-.47),"left":Vector3(-.35,.93,-.29),"weapon":Vector3(.92,.25,-.48)})
		return_pose=_change(guard,{"hip":Vector3(-.025,-.20,-.04),"chest":Vector3(-.19,.09,.025),"right":Vector3(.26,.90,-.38),"weapon":Vector3(.35,.07,-.10),"cloth":Vector3(.05,.03,-.015)})
	elif key=="guardian_0":
		load=_change(load,{"hip":Vector3(.07,-.275,.095),"pelvis":Vector3(.055,-.22,.035),"chest":Vector3(.20,-.20,-.05),"right":Vector3(.32,1.57,.14),"left":Vector3(-.34,1.04,-.24),"weapon":Vector3(.28,0,-.14)})
		drive=_change(drive,{"hip":Vector3(.01,-.13,-.075),"right":Vector3(.29,1.41,-.35),"weapon":Vector3(-.63,0,-.10)})
		contact=_change(contact,{"hip":Vector3(-.055,-.255,-.195),"pelvis":Vector3(-.12,.23,-.05),"chest":Vector3(-.33,.12,.035),"right":Vector3(.20,.84,-.63),"weapon":Vector3(-1.63,0,-.12)})
		follow=_change(follow,{"hip":Vector3(-.075,-.285,-.18),"chest":Vector3(-.36,.21,.04),"right":Vector3(.14,.69,-.47),"weapon":Vector3(-1.92,.06,-.20)})
	elif key=="guardian_3":
		# The furnace axe is carried by both hands, including the passing poses.
		guard=_change(guard,{"right":Vector3(.06,1.30,-.26),"weapon":Vector3(-.24,-.10,-.24),"support":1.0})
		gather=_change(gather,{"right":Vector3(.24,1.48,.06),"weapon":Vector3(.28,-.18,-.48)})
		load=_change(load,{"hip":Vector3(.085,-.265,.095),"chest":Vector3(.16,-.40,-.09),"right":Vector3(.24,1.51,.06),"weapon":Vector3(.46,-.23,-.47)})
		drive=_change(drive,{"right":Vector3(.23,1.35,-.31),"weapon":Vector3(-.57,-.12,-.28)})
		contact=_change(contact,{"hip":Vector3(-.07,-.245,-.18),"right":Vector3(.025,1.01,-.49),"weapon":Vector3(-1.48,.17,.12)})
		follow=_change(follow,{"hip":Vector3(-.09,-.27,-.165),"right":Vector3(-.08,.91,-.36),"weapon":Vector3(-1.89,.25,.38)})
		return_pose=_change(return_pose,{"right":Vector3(.06,1.10,-.32),"weapon":Vector3(-.78,-.06,-.12)})
		for state in [gather,load,drive,contact,follow,return_pose]: state.support=1.0
	elif heavy:
		# The armored hostile commits from a lower chamber than Nyra, then
		# carries the mass beyond contact before rebuilding its guard.
		load.hip+=Vector3(.01,-.025,.015); load.chest+=Vector3(.04,-.07,0)
		contact.hip+=Vector3(0,-.025,-.015); follow.hip.y-=.025
	if key in ["Vowkeeper","Arcanist","Ranger"]:
		for state in [guard,gather,load,drive,contact,follow,return_pose]:
			state.hip.y*=1.17
			state.left.y+=.153; state.right.y+=.153
	return {"guard":guard,"gather":gather,"load":load,"drive":drive,"contact":contact,"follow":follow,"return":return_pose}

static func _change(state: Dictionary,changes: Dictionary) -> Dictionary:
	var result:=state.duplicate(true)
	result.merge(changes,true)
	return result

static func _action_state(spec: Dictionary,key: String,clip: String,u: float) -> Dictionary:
	if clip.begins_with("windup"):
		var heavy:=clip.ends_with("heavy")
		var gather_end:=.18 if key=="Ranger" else .14
		var load_end:=.72 if key=="Ranger" else .34
		var commit:=.78 if heavy else (.56 if clip.ends_with("skill") else .52)
		if u<gather_end: return _mix(spec.guard,spec.gather,smoothstep(0,gather_end,u))
		if u<load_end: return _mix(spec.gather,spec.load,smoothstep(gather_end,load_end,u))
		if key=="Ranger": return spec.load.duplicate(true)
		# The supporting leg drives first, before the weapon leaves its chamber.
		# This is visible even in a .30 s cast (.215 s for the ranged launch).
		var passing:=lerpf(commit,1.0,.58)
		if u<passing:
			var phrase:=_mix(spec.load,spec.drive,pow(clampf((u-commit)/(passing-commit),0,1),1.45))
			var weight:=smoothstep(commit-.15,passing,u)
			for channel in ["hip","pelvis","knee_l","knee_r"]: phrase[channel]=Vector3(spec.load[channel]).lerp(spec.drive[channel],weight)
			phrase.chest=Vector3(spec.load.chest).lerp(spec.drive.chest,smoothstep(commit-.035,passing,u))
			return phrase
		return _mix(spec.drive,spec.contact,clampf((u-passing)/(1.0-passing),0,1))
	var overshoot:=.30 if key=="Ranger" else (.28 if clip.ends_with("heavy") else .24)
	if u<overshoot: return _mix(spec.contact,spec.follow,1.0-pow(1.0-clampf(u/overshoot,0,1),2.0))
	if u<.74: return _mix(spec.follow,spec["return"],smoothstep(overshoot+.035,.74,u))
	return _mix(spec["return"],spec.guard,smoothstep(.74,1.0,u))

static func _mix(a: Dictionary,b: Dictionary,t: float) -> Dictionary:
	var result: Dictionary={}
	for name in a: result[name]=a[name].lerp(b[name],t) if a[name] is Vector3 else lerpf(a[name],b[name],t)
	return result

static func _author(key: String,clip: String,u: float,rests: Array[Transform3D]) -> Array[Transform3D]:
	var action:=clip.get_slice("_",1) if clip.contains("_") else "basic"
	var spec:=_spec(key,action)
	var state: Dictionary=spec.guard.duplicate(true)
	var walking:=clip=="walk"
	var death:=clip=="death"
	var nyra:=key in ["Vowkeeper","Arcanist","Ranger"]
	var acting:=clip.begins_with("windup") or clip.begins_with("recover")
	var breath:=sin(u*TAU) if clip=="idle" else 0.0
	if acting: state=_action_state(spec,key,clip,u)
	if walking:
		state.hip=Vector3(0,-.105+.012*cos(u*TAU*2),0)
		if nyra: state.hip.y*=1.17
		state.chest=Vector3(-.055,.035*sin(u*TAU),.01*sin(u*TAU))
		state.pelvis=Vector3(0,Vector3(state.chest).y*.30,0)
		state.right+=Vector3(0,.018*sin(u*TAU),.075*sin(u*TAU))
		state.left+=Vector3(0,-.018*sin(u*TAU),-.060*sin(u*TAU))
	if death:
		state=_mix(spec.guard,_change(spec.guard,{"hip":Vector3(0,-.02,0),"pelvis":Vector3.ZERO,"chest":Vector3(-.10,0,.035),"right":Vector3(.27,1.153 if nyra else 1.00,.06),"left":Vector3(-.33,1.233 if nyra else 1.08,.08),"weapon":Vector3.ZERO,"draw":0.0,"arrow":0.0,"nock":0.0,"support":0.0}),smoothstep(0,.40,u))
	var p: Array[Transform3D]=[]
	p.assign(rests)
	p[1].origin+=Vector3(state.hip)+Vector3(0,breath*.005,0)
	if death: p[1].origin.y-=.23*sin(clampf(u/.46,0,1)*PI)
	p[1].basis=Basis.from_euler(state.pelvis)
	p[2].basis=Basis.from_euler(Vector3(state.chest)+Vector3(breath*.007,0,0))
	p[3].basis=Basis.from_euler(Vector3(-Vector3(state.chest).x*.22,-Vector3(state.chest).y*.42,0))
	if acting:
		# Eyes retain the target while shoulders and hips turn underneath.
		global_rotation(p,3,Basis.from_euler(Vector3(-.015+Vector3(state.chest).x*.08,Vector3(state.chest).y*.10,-Vector3(state.chest).z*.15)),key)
	var left: Vector3=state.left; var right: Vector3=state.right
	var weapon_basis:=Basis.from_euler(state.weapon)
	p[22].origin.z+=float(state.draw)
	p[21].origin.z-=float(state.draw)*.06; p[23].origin.z-=float(state.draw)*.06
	p[24].basis=Basis.IDENTITY.scaled(Vector3.ONE*float(state.arrow))
	if death:
		# Keep the established falling surface and its floor envelope intact.
		solve_two(p,5,6,7,left,Vector3(-1,.15,.35),key)
		solve_two(p,9,10,11,right,Vector3(1,.15,.45),key)
		global_rotation(p,7,Basis.from_euler(Vector3(-.14,0,-.10)),key)
		global_rotation(p,11,Basis.from_euler(Vector3(-.10,0,.10)),key)
		global_rotation(p,20,weapon_basis,key)
	elif key=="Ranger":
		solve_two(p,5,6,7,left,state.left_pole,key)
		global_rotation(p,7,weapon_basis,key)
		global_rotation(p,20,weapon_basis,key)
		right=right.lerp(global_pose(p,22,key).origin,float(state.nock))
		solve_two(p,9,10,11,right,state.right_pole,key)
		global_rotation(p,11,Basis.from_euler(Vector3(-.12,-.08,.10)),key)
	else:
		solve_two(p,9,10,11,right,state.right_pole,key)
		# Grip and weapon share an orientation; the blade/staff no longer
		# rotates through a separately upright fist during its fastest arc.
		global_rotation(p,11,weapon_basis,key)
		global_rotation(p,20,weapon_basis,key)
		left=left.lerp(global_pose(p,20,key)*Vector3(0,-.20,0),float(state.support))
		solve_two(p,5,6,7,left,state.left_pole,key)
		global_rotation(p,7,Basis.from_euler(state.palm).slerp(weapon_basis,float(state.support)),key)
	var cloth: Vector3=state.cloth
	var cloth_lag: Vector3=_action_state(spec,key,clip,maxf(0.0,u-.085)).cloth if acting else cloth
	var cloth_compression:=clampf(-Vector3(state.hip).y-.025,0,.22)
	for side in range(2):
		var phase:=fposmod(u+side*.5,1.0)
		var foot:=Vector3(-.13 if side==0 else .13,.117 if nyra else .10,-.04)
		if not walking and not death:
			# A staggered support polygon carries the forward weight transfer.
			# Targets are identical throughout guard and every attack phrase.
			foot=stance_foot(key,side)
		if walking:
			if phase<.5: foot.z+=-.40+phase*1.60
			else:
				var swing:=(phase-.5)*2.0
				foot.z+=.40-.80*smoothstep(0,1,swing)
				foot.y+=sin(swing*PI)*.115
		var knee_pole: Vector3=state.knee_l if side==0 else state.knee_r
		solve_two(p,12 if side==0 else 15,13 if side==0 else 16,14 if side==0 else 17,foot,Vector3.FORWARD if walking or death else knee_pole,key)
		global_rotation(p,14 if side==0 else 17,Basis.IDENTITY,key)
		var coat:=25+side
		p[coat].basis=Basis.from_euler(cloth*.28+Vector3(0,0,(-.012 if side==0 else .012)*cloth.x) if acting else Vector3(.025*sin(u*TAU+side*PI) if walking else breath*.007,0,0))
		if not death: p[coat].basis=p[coat].basis.scaled(Vector3(1,1.0-cloth_compression/.75,1))
	p[18].basis=Basis.from_euler(cloth if acting else Vector3(.06 if walking else .016+breath*.008,0,.015*sin(u*TAU)))
	p[19].basis=Basis.from_euler(cloth_lag*.60 if acting else Vector3(.045*sin(u*TAU-.55) if walking else breath*.012,0,0))
	if not death: p[19].origin.y+=cloth_compression*.90
	p[27].basis=Basis.from_euler(cloth_lag*.12 if acting else Vector3(breath*.007,0,.012*sin(u*TAU-.40)))
	p[28].basis=Basis.from_euler(cloth_lag*.10 if acting else Vector3(breath*.007,0,-.012*sin(u*TAU-.40)))
	if death:
		# Weight gives way at the knee before the shoulder, hip and head settle.
		# One leg stays extended while the other folds; cloth follows the body
		# with a delayed second bend instead of retaining an upright fan shape.
		var fall:=smoothstep(.16,.94,u)
		var fold:=smoothstep(.31,.87,u)
		var settle:=smoothstep(.58,1.0,u)
		var gather:=sin(clampf(u/.46,0,1)*PI)
		var side:=-1.0 if key in ["Vowkeeper","guardian_0","bulwark","elite"] else 1.0
		var folded:=12 if side<0.0 else 15
		p[1].basis=Basis.from_euler(Vector3(.08*fold,side*.28*fold,side*.055*fold))
		p[2].basis=Basis.from_euler(Vector3(-.20*fold,-side*.18*fold,side*.045*fold))
		p[3].basis=Basis.from_euler(Vector3(.12*settle,side*.40*settle,-side*.12*settle))
		p[folded].basis=p[folded].basis.slerp(Basis.from_euler(Vector3(-.58,side*.08,side*.18)),fold)
		p[folded+1].basis=p[folded+1].basis.slerp(Basis.from_euler(Vector3(.87,0,0)),fold)
		p[folded+2].basis=p[folded+2].basis.slerp(Basis.from_euler(Vector3(-.12,0,0)),settle)
		# Settled fabric flattens in the fallen body's depth direction (world
		# height after the root turn). It no longer retains a circular standing
		# hem. Global cloth orientation releases the pelvis/shoulder twist.
		global_rotation(p,18,Basis.from_euler(Vector3(.14*settle,0,side*.025*settle)),key)
		p[18].basis=p[18].basis.scaled(Vector3(1,1,lerpf(1.0,.30,settle)))
		p[19].basis=Basis.from_euler(Vector3(.12*settle,0,-side*.025*settle))
		# The renewed long guardian capes gather as the knees give way; their
		# lower panel must not travel down through the standing floor.
		p[19].origin.y+=.09*gather
		global_rotation(p,25,Basis.from_euler(Vector3(.22*settle,0,-.86*gather)),key)
		global_rotation(p,26,Basis.from_euler(Vector3(.22*settle,0,.86*gather)),key)
		for coat in [25,26]:
			# The inner edges of the new overlapping gores gather upward while
			# the knee buckles; merely fanning them outward lowers those edges.
			p[coat].basis=p[coat].basis.scaled(Vector3(1,1.0-.18*gather,lerpf(1.0,.25,settle)))
		p[27].basis=Basis.from_euler(Vector3(.18*settle,0,-.11*settle))
		p[28].basis=Basis.from_euler(Vector3(.14*settle,0,.09*settle))
		# The articulated, slimmer boots/armor leave the old rounded-cuff
		# support envelope. Settle only after the body has finished its fall.
		var grounding:=smoothstep(.92,1.0,u)
		var support_drop:=.035 if nyra else (.015 if key=="guardian_0" else .040)
		p[0].origin=Vector3(side*.075*fall,.33*fall+(.06*settle if key=="guardian_0" else 0.0)-support_drop*grounding,-.05*fall)
		p[0].basis=Basis.from_euler(Vector3(-PI*.5*fall,0,side*.045*fall))
	return p
