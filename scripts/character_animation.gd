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

static func _spec(key: String) -> Dictionary:
	var ranger:=key=="Ranger"
	var caster:=key in ["Arcanist","hexer","guardian_1","guardian_2"]
	var raider:=key=="raider"
	var guard: Dictionary={"hip":Vector3(0,-.03,0),"chest":Vector3(0,.08,0),"right":Vector3(.32,1.08,-.22),"left":Vector3(-.39,1.22,-.29),"weapon":Vector3(-.18,0,-.12),"draw":0.0,"arrow":0.0}
	if caster:
		guard.right=Vector3(.35,1.10,-.16); guard.left=Vector3(-.25,1.13,-.17)
		guard.chest=Vector3(0,-.10,0); guard.weapon=Vector3(-.12,0,-.12)
	elif ranger:
		guard.left=Vector3(-.35,1.01,-.16); guard.right=Vector3(.24,1.13,-.13)
		guard.chest=Vector3(0,.16,0); guard.weapon=Vector3(0,0,-.13)
	elif raider:
		guard.hip=Vector3(0,-.14,.025); guard.chest=Vector3(-.14,0,0)
		guard.right=Vector3(.39,1.02,-.31); guard.left=Vector3(-.39,1.03,-.28)
		guard.weapon=Vector3.ZERO
	var load: Dictionary=guard.duplicate(true)
	var contact: Dictionary=guard.duplicate(true)
	var follow: Dictionary=guard.duplicate(true)
	load.hip=guard.hip+Vector3(.035,-.025,.025); load.chest=Vector3(.08,-.38,-.025)
	load.right=Vector3(.46,1.66,.085); load.left=Vector3(-.42,1.29,-.30)
	load.weapon=Vector3(.76,-.20,-.25)
	contact.hip=guard.hip+Vector3(-.028,-.035,-.055); contact.chest=Vector3(-.08,.30,.025)
	contact.right=Vector3(.13,1.18,-.43); contact.left=Vector3(-.38,1.25,-.35)
	contact.weapon=Vector3(-1.37,.08,-.25)
	follow.hip=guard.hip+Vector3(-.030,-.04,-.035); follow.chest=Vector3(-.09,.42,.02)
	follow.right=Vector3(-.04,1.02,-.31); follow.left=Vector3(-.37,1.18,-.28)
	follow.weapon=Vector3(-1.53,.25,-.72)
	if caster:
		load.chest=Vector3(.065,-.25,-.025); load.hip=guard.hip+Vector3(.02,-.01,.015)
		load.right=Vector3(.39,1.36,-.20); load.left=Vector3(-.22,1.35,-.38)
		load.weapon=Vector3(.10,-.08,-.30)
		contact.chest=Vector3(-.08,.12,0); contact.hip=guard.hip+Vector3(0,-.025,-.035)
		contact.right=Vector3(.22,1.24,-.34); contact.left=Vector3(-.20,1.36,-.45)
		contact.weapon=Vector3(-.58,.05,-.11)
		follow=contact.duplicate(true); follow.left=Vector3(-.24,1.28,-.39)
		follow.weapon=Vector3(-.65,.05,-.13)
	elif ranger:
		load.hip=guard.hip+Vector3(0,-.035,0); load.chest=Vector3(-.025,.35,0)
		load.left=Vector3(-.25,1.40,-.46); load.right=Vector3(-.23,1.40,.075)
		load.weapon=Vector3.ZERO; load.draw=.19; load.arrow=1.0
		contact=load.duplicate(true); contact.draw=0.0; contact.arrow=0.0
		follow=contact.duplicate(true); follow.right=Vector3(-.20,1.42,.13)
		follow.chest=Vector3(-.025,.38,0)
	elif raider:
		load.chest=Vector3(.02,-.46,-.08); load.right=Vector3(.52,1.31,-.08)
		load.left=Vector3(-.31,1.20,-.34); load.weapon=Vector3(-.8,0,.20)
		contact.chest=Vector3(-.18,.35,.08); contact.right=Vector3(.08,1.20,-.43)
		contact.weapon=Vector3(.80,0,-.25); follow=contact.duplicate(true)
		follow.right=Vector3(-.09,1.13,-.38); follow.chest=Vector3(-.19,.45,.06)
	elif key=="guardian_0":
		load.chest=Vector3(.10,-.25,0); load.right=Vector3(.38,1.74,.16)
		load.weapon=Vector3(.25,0,-.06); contact.weapon=Vector3(-1.47,0,-.10)
		contact.hip=guard.hip+Vector3(0,-.07,-.07)
	elif key=="guardian_3":
		load.weapon=Vector3(.45,-.15,-.35); follow.weapon=Vector3(-1.60,.20,-.50)
	if key in ["Vowkeeper","Arcanist","Ranger"]:
		for state in [guard,load,contact,follow]:
			state.hip.y*=1.17
			state.left.y+=.153; state.right.y+=.153
	return {"guard":guard,"load":load,"contact":contact,"follow":follow}

static func _mix(a: Dictionary,b: Dictionary,t: float) -> Dictionary:
	var result: Dictionary={}
	for name in a: result[name]=a[name].lerp(b[name],t) if a[name] is Vector3 else lerpf(a[name],b[name],t)
	return result

static func _author(key: String,clip: String,u: float,rests: Array[Transform3D]) -> Array[Transform3D]:
	var spec:=_spec(key)
	var state: Dictionary=spec.guard.duplicate(true)
	var walking:=clip=="walk"
	var death:=clip=="death"
	var nyra:=key in ["Vowkeeper","Arcanist","Ranger"]
	var breath:=sin(u*TAU) if clip=="idle" else 0.0
	if clip.begins_with("windup"):
		var heavy:=clip.ends_with("heavy")
		var swing_start:=.90 if heavy else .65
		state=_mix(spec.guard,spec.load,smoothstep(0,.38 if heavy else .48,u))
		if u>swing_start and key!="Ranger":
			state=_mix(spec.load,spec.contact,pow(smoothstep(swing_start,1,u),1.35))
	elif clip.begins_with("recover"):
		state=_mix(spec.contact,spec.follow,smoothstep(0,.24,u)) if u<.24 else _mix(spec.follow,spec.guard,smoothstep(.24,1,u))
	if clip.ends_with("skill"):
		state.hip*=1.10; state.chest*=1.18
		state.weapon+=Vector3(-.08,0,-.04)*sin(u*PI)
	if walking:
		state.hip=Vector3(0,-.105+.012*cos(u*TAU*2),0)
		if nyra: state.hip.y*=1.17
		state.chest=Vector3(-.055,.035*sin(u*TAU),.01*sin(u*TAU))
		state.right+=Vector3(0,.018*sin(u*TAU),.075*sin(u*TAU))
		state.left+=Vector3(0,-.018*sin(u*TAU),-.060*sin(u*TAU))
	if death:
		state=_mix(spec.guard,{"hip":Vector3(0,-.02,0),"chest":Vector3(-.10,0,.035),"right":Vector3(.27,1.153 if nyra else 1.00,.06),"left":Vector3(-.33,1.233 if nyra else 1.08,.08),"weapon":Vector3.ZERO,"draw":0.0,"arrow":0.0},smoothstep(0,.40,u))
	var p: Array[Transform3D]=[]
	p.assign(rests)
	p[1].origin+=Vector3(state.hip)+Vector3(0,breath*.005,0)
	if death: p[1].origin.y-=.23*sin(clampf(u/.46,0,1)*PI)
	p[1].basis=Basis.from_euler(Vector3(0,Vector3(state.chest).y*.30,0))
	p[2].basis=Basis.from_euler(Vector3(state.chest)+Vector3(breath*.007,0,0))
	p[3].basis=Basis.from_euler(Vector3(-Vector3(state.chest).x*.22,-Vector3(state.chest).y*.42,0))
	var left: Vector3=state.left; var right: Vector3=state.right
	solve_two(p,5,6,7,left,Vector3(-1,.15,.35),key)
	solve_two(p,9,10,11,right,Vector3(1,.15,.45),key)
	global_rotation(p,7,Basis.from_euler(Vector3(-.14,0,-.10)),key)
	global_rotation(p,11,Basis.from_euler(Vector3(-.10,0,.10)),key)
	global_rotation(p,20,Basis.from_euler(state.weapon),key)
	p[22].origin.z+=float(state.draw)
	p[21].origin.z-=float(state.draw)*.06; p[23].origin.z-=float(state.draw)*.06
	p[24].basis=Basis.IDENTITY.scaled(Vector3.ONE*float(state.arrow))
	for side in range(2):
		var phase:=fposmod(u+side*.5,1.0)
		var foot:=Vector3(-.13 if side==0 else .13,.117 if nyra else .10,-.04)
		if walking:
			if phase<.5: foot.z+=-.40+phase*1.60
			else:
				var swing:=(phase-.5)*2.0
				foot.z+=.40-.80*smoothstep(0,1,swing)
				foot.y+=sin(swing*PI)*.115
		solve_two(p,12 if side==0 else 15,13 if side==0 else 16,14 if side==0 else 17,foot,Vector3.FORWARD,key)
		global_rotation(p,14 if side==0 else 17,Basis.IDENTITY,key)
		var coat:=25+side
		p[coat].basis=Basis.from_euler(Vector3(.025*sin(u*TAU+side*PI) if walking else breath*.007,0,0))
	p[18].basis=Basis.from_euler(Vector3(.06 if walking else .016+breath*.008,0,.015*sin(u*TAU)))
	p[19].basis=Basis.from_euler(Vector3(.045*sin(u*TAU-.55) if walking else breath*.012,0,0))
	p[27].basis=Basis.from_euler(Vector3(breath*.007,0,.012*sin(u*TAU-.40)))
	p[28].basis=Basis.from_euler(Vector3(breath*.007,0,-.012*sin(u*TAU-.40)))
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
		global_rotation(p,25,Basis.from_euler(Vector3(.22*settle,0,-.86*gather)),key)
		global_rotation(p,26,Basis.from_euler(Vector3(.22*settle,0,.86*gather)),key)
		for coat in [25,26]: p[coat].basis=p[coat].basis.scaled(Vector3(1,1,lerpf(1.0,.25,settle)))
		p[27].basis=Basis.from_euler(Vector3(.18*settle,0,-.11*settle))
		p[28].basis=Basis.from_euler(Vector3(.14*settle,0,.09*settle))
		p[0].origin=Vector3(side*.075*fall,.33*fall+(.06*settle if key=="guardian_0" else 0.0),-.05*fall)
		p[0].basis=Basis.from_euler(Vector3(-PI*.5*fall,0,side*.045*fall))
	return p
