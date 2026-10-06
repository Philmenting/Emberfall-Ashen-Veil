extends RefCounted
## Authored spatial action phrases, compiled once into native Animation resources.
## Hand and sole targets are solved when clips are authored. No sinusoidal attack
## rotations, sprite swaps, mutable vertices or simulation timers live here.
const NAMES: Array[String]=["Root","Pelvis","Chest","Head","ClavicleL","UpperArmL","ForearmL","HandL","ClavicleR","UpperArmR","ForearmR","HandR","ThighL","ShinL","FootL","ThighR","ShinR","FootR","Cape","CapeTip","Weapon","BowUpper","BowString","BowLower","Arrow","CoatL","CoatR","HairL","HairR"]
const PARENTS: Array[int]=[-1,0,1,2,2,4,5,6,2,8,9,10,1,12,13,1,15,16,2,18,11,20,20,20,22,1,1,3,3]
const RECOVERY:=.34
const SwordFoundation=preload("res://assets/animations/vowkeeper_sword_foundation.gd")

static func create(key: String,rests: Array[Transform3D],profile: Dictionary={}) -> AnimationLibrary:
	if not profile.is_empty():
		assert(key=="Arcanist" and profile.get("appearance")==key,"Only the complete anatomical Arcanist has a source motion profile")
		assert(profile.get("native_names",[]).size()==NAMES.size() and profile.get("parents",[]).size()==PARENTS.size(),"Source motion needs the native 29-joint hierarchy")
		for i in NAMES.size(): assert(String(profile.native_names[i])==NAMES[i] and int(profile.parents[i])==PARENTS[i],"Source motion joint order must match its rest contract")
		for rest in rests: assert(rest.basis.is_equal_approx(Basis.IDENTITY),"Source motion expects global Identity rest frames")
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
			var poses:=_author(key,name,u,locals,profile)
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

static func stance_foot(key: String,side: int,profile: Dictionary={}) -> Vector3:
	if not profile.is_empty(): return _source_foot(key,stance_foot(key,side),side,profile)
	var foot:=Vector3(-.20 if side==0 else .22,.117 if key in ["Vowkeeper","Arcanist","Ranger"] else .10,0)
	foot.z=(-.25 if side==0 else .20) if key=="Ranger" else (-.235 if side==0 else .19)
	if key in ["guardian_0","guardian_3","bulwark","elite"]: foot.x*=1.18
	return foot

static func action_foot(key: String,clip: String,u: float,side: int,profile: Dictionary={}) -> Vector3:
	if not profile.is_empty():
		var authored:=action_foot(key,clip,u,side)
		var fit: Dictionary=profile.get("motion_fit",{})
		if key=="Arcanist" and side==0 and clip.begins_with("windup") and fit.has("step_landing"):
			# Fit only the unweighted transfer to this source's measured leg.
			# The same destination stays fixed after touchdown and throughout
			# the existing contact/catch. Actor uses this identical curve.
			var start:=stance_foot(key,side)
			var landing: float=fit.step_landing
			assert(landing>=.67 and landing<.79,"Source step must land before the contact phase")
			var t:=smoothstep(.12,landing,u)
			authored=start.lerp(start+Vector3(-.085,0,-.34),t)+Vector3(0,sin(t*PI)*.085,0)
		return _source_foot(key,authored,side,profile)
	# One boot bears the load while the other actually steps. These are sole
	# contact curves, also used after runtime pose blending; they are not a
	# projection of the in-place source's sliding feet.
	var start:=stance_foot(key,side)
	var stepping: int=1 if key=="Vowkeeper" else 0
	if key not in ["Vowkeeper","Arcanist","Ranger"] or side!=stepping: return start
	var finish:=start+Vector3(.025,0,-.64) if key=="Vowkeeper" else start+Vector3(-.085 if key=="Arcanist" else -.145,0,-.34 if key=="Arcanist" else -.28)
	var recovery:=clip.begins_with("recover")
	var lift:=.12 if key=="Vowkeeper" else .085
	if recovery:
		var lift_off:=.40 if key=="Ranger" else .35
		var t:=smoothstep(lift_off,.91,u)
		return finish.lerp(start,t)+Vector3(0,sin(t*PI)*lift,0)
	var takeoff:=.18 if key=="Vowkeeper" else .12
	# The free boot lands after the pelvis can reach that support point.
	# Earlier contact overextended the knee while the body was still loading.
	var landing:=.64 if key=="Vowkeeper" else (.56 if key=="Ranger" else .67)
	var t:=smoothstep(takeoff,landing,u)
	return start.lerp(finish,t)+Vector3(0,sin(t*PI)*lift,0)

static func action_foot_basis(key: String,side: int,profile: Dictionary={}) -> Basis:
	var basis:=Basis(Vector3.UP,-.34 if side==0 else -.62) if key=="Ranger" else Basis.IDENTITY
	if not profile.is_empty(): basis*=_socket_basis(profile,"feet",side,"sole_basis_columns").inverse()
	return basis

static func action_support(key: String,clip: String,u: float,side: int,profile: Dictionary={}) -> bool:
	return action_foot(key,clip,u,side,profile).y<=stance_foot(key,side,profile).y+.0001

static func walk_stride(_key: String,profile: Dictionary={}) -> float:
	return 1.60*_leg_ratio(profile) if not profile.is_empty() else 1.60

static func walk_anchor(key: String,side: int,profile: Dictionary={}) -> Vector3:
	var foot:=Vector3(-.13 if side==0 else .13,.117 if key in ["Vowkeeper","Arcanist","Ranger"] else .10,-.04)
	return _source_foot(key,foot,side,profile) if not profile.is_empty() else foot

static func walk_foot(key: String,u: float,side: int,profile: Dictionary={}) -> Vector3:
	var foot:=walk_anchor(key,side)
	var phase:=fposmod(u+side*.5,1.0)
	if phase<.5: foot.z+=-.40+phase*1.60
	else:
		var swing:=(phase-.5)*2.0
		foot.z+=.40-.80*smoothstep(0,1,swing)
		foot.y+=sin(swing*PI)*.115
	return _source_foot(key,foot,side,profile) if not profile.is_empty() else foot

# Profiles contain measured model-space rests and rigid sockets. The mesh has
# already received its one export scale: these ratios fit motion, never skin.
static func _vector(values: Array) -> Vector3:
	return Vector3(values[0],values[1],values[2])

static func _rest_point(profile: Dictionary,name: String) -> Vector3:
	return _vector(profile.rest_global[name].origin)

static func _socket_vector(profile: Dictionary,group: String,side: int,field: String) -> Vector3:
	return _vector(profile[group]["L" if side==0 else "R"][field])

static func _socket_basis(profile: Dictionary,group: String,side: int,field: String) -> Basis:
	var columns: Array=profile[group]["L" if side==0 else "R"][field]
	return Basis(_vector(columns[0]),_vector(columns[1]),_vector(columns[2]))

static func _leg_ratio(profile: Dictionary) -> float:
	var upper:=_rest_point(profile,"ThighL").distance_to(_rest_point(profile,"ShinL"))
	var lower:=_rest_point(profile,"ShinL").distance_to(_rest_point(profile,"FootL"))
	return (upper+lower)/(.4914+Vector3(0,-.4446,-.04).length())

static func _source_foot(key: String,authored: Vector3,side: int,profile: Dictionary) -> Vector3:
	var ratio:=_leg_ratio(profile)
	var hip:=_rest_point(profile,"ThighL" if side==0 else "ThighR")
	var socket:=action_foot_basis(key,side,profile)*_socket_vector(profile,"feet",side,"sole_local")
	var floor_y:=_socket_vector(profile,"feet",side,"sole_global").y
	# Author horizontal placement relative to each hip and the vertical path
	# at the real sole. Return the anatomical ankle expected by both IK callers.
	var sole:=Vector3(hip.x+(authored.x-(-.13 if side==0 else .13))*ratio+socket.x,floor_y+(authored.y-.117)*ratio,hip.z+authored.z*ratio+socket.z)
	return sole-socket

static func _basis(value: Variant) -> Basis:
	return Basis(value) if value is Quaternion else Basis.from_euler(value)

static func _rotation(value: Variant) -> Quaternion:
	return value if value is Quaternion else Quaternion.from_euler(value)

static func _angles(value: Variant) -> Vector3:
	return Basis(value).get_euler() if value is Quaternion else value

static func _base_state() -> Dictionary:
	return {"hip":Vector3(0,-.075,0),"pelvis":Vector3.ZERO,"chest":Vector3.ZERO,"right":Vector3(.36,1.23,.08),"left":Vector3(-.30,1.41,-.22),"weapon":Vector3.ZERO,"palm":Vector3(-.14,0,-.10),"left_pole":Vector3(-1,-.10,.35),"right_pole":Vector3(1,-.10,.40),"knee_l":Vector3(-.16,0,-1),"knee_r":Vector3(.18,0,-1),"cloth":Vector3(.016,0,0),"draw":0.0,"arrow":0.0,"nock":0.0,"support":0.0}

static func _arcanist_spec(action: String) -> Dictionary:
	# Rear-leg coil, hip-led transfer and front-knee catch form one throw.
	# The staff hand travels with the shoulder; the casting palm stays outside.
	var guard:=_change(_base_state(),{"hip":Vector3(0,-.085,0),"pelvis":Vector3(0,.10,0),"chest":Vector3(0,.12,0),"right":Vector3(.44,1.17,.46),"left":Vector3(-.29,1.43,-.16),"weapon":Vector3(.22,0,-.16)})
	var gather:=_change(guard,{"hip":Vector3(.085,-.23,.10),"pelvis":Vector3(.04,-.13,-.065),"chest":Vector3(.085,.52,.055),"left":Vector3(-.45,1.45,.14),"right":Vector3(.49,.97,.34),"left_pole":Vector3(-1,.08,.40),"right_pole":Vector3(.80,-.18,.50),"knee_r":Vector3(.35,0,-1),"cloth":Vector3(-.035,.045,-.025)})
	var load:=_change(gather,{"hip":Vector3(.15,-.325,.15),"pelvis":Vector3(.075,-.20,-.095),"chest":Vector3(.10,.74,.085),"left":Vector3(-.38,1.48,.22),"right":Vector3(.51,.87,.27),"palm":Vector3(-.25,.20,-.80),"weapon":Vector3(.28,.08,-.18),"knee_r":Vector3(.40,0,-1),"cloth":Vector3(-.07,.07,-.035)})
	var drive:=_change(load,{"hip":Vector3(-.015,-.16,-.16),"pelvis":Vector3(-.07,-.52,.035),"chest":Vector3(-.18,.17,-.065),"left":Vector3(.18,1.54,-.51),"right":Vector3(.47,1.02,.12),"left_pole":Vector3(-.35,.23,-.75),"right_pole":Vector3(.90,-.10,.40),"palm":Vector3(-1.22,-.10,-.20),"weapon":Vector3(.22,0,-.18),"knee_l":Vector3(-.35,0,-1),"cloth":Vector3(.13,-.08,.04)})
	var contact:=_change(drive,{"hip":Vector3(-.14,-.21,-.27),"pelvis":Vector3(-.09,-.32,.065),"chest":Vector3(-.30,-.54,.015),"left":Vector3(.22,1.32,-.86),"right":Vector3(.42,1.03,.02),"palm":Vector3(-1.50,0,-.10),"cloth":Vector3(.17,-.10,.04)})
	var follow:=_change(contact,{"hip":Vector3(-.17,-.25,-.29),"left":Vector3(.22,1.28,-.87),"right":Vector3(.40,.98,.00),"chest":Vector3(-.32,-.48,.025),"cloth":Vector3(.20,-.035,.02)})
	var return_pose:=_change(guard,{"hip":Vector3(-.07,-.17,-.095),"pelvis":Vector3(-.035,-.20,.04),"chest":Vector3(-.08,-.25,.015),"left":Vector3(.12,1.30,-.36),"right":Vector3(.43,1.07,.22),"palm":Vector3(-.65,.10,-.38),"cloth":Vector3(.055,.045,-.015)})
	if action!="basic":
		gather=_change(gather,{"left":Vector3(-.42,1.21,.11),"palm":Vector3(-.20,.10,-.50)})
		load=_change(load,{"left":Vector3(-.41,1.22,.23),"palm":Vector3(.35,.15,-.75)})
		drive=_change(drive,{"left":Vector3(.16,1.38,-.49),"palm":Vector3(-.80,0,-.20)})
		contact=_change(contact,{"hip":Vector3(-.13,-.165,-.27),"left":Vector3(.23,1.54,-.81),"palm":Vector3(-1.75,0,-.10)})
		follow=_change(follow,{"hip":Vector3(-.17,-.205,-.29),"left":Vector3(.24,1.55,-.82),"palm":Vector3(-1.80,0,-.08)})
	return {"guard":guard,"gather":gather,"load":load,"drive":drive,"contact":contact,"follow":follow,"return":return_pose}

static func _ranger_spec(action: String) -> Dictionary:
	# Set the front boot, sit over the rear leg and draw against that support.
	# Hips resist the chest turn; after release the torso rises while aim holds.
	var guard:=_change(_base_state(),{"hip":Vector3(0,-.085,0),"pelvis":Vector3(0,-.24,-.02),"chest":Vector3(.025,-.44,.02),"left":Vector3(-.18,1.23,-.23),"right":Vector3(.30,1.40,-.01),"weapon":Vector3(0,0,-.14),"right_pole":Vector3(1,.20,.65),"left_pole":Vector3(-.65,-.65,-.45)})
	var gather:=_change(guard,{"hip":Vector3(.065,-.19,.08),"pelvis":Vector3(.025,-.36,-.055),"chest":Vector3(.06,-.36,.06),"left":Vector3(.09,1.39,-.56),"weapon":Vector3.ZERO,"draw":.015,"arrow":1.0,"nock":1.0,"knee_r":Vector3(.40,0,-1),"cloth":Vector3(-.035,.05,0)})
	var load:=_change(gather,{"hip":Vector3(.085,-.285,.07),"pelvis":Vector3(.04,-.24,-.075),"chest":Vector3(.085,-.96,.075),"left":Vector3(.15,1.46,-.78),"draw":.42,"right_pole":Vector3(1,.20,.65),"knee_l":Vector3(-.42,0,-1),"knee_r":Vector3(.45,0,-1),"cloth":Vector3(-.025,.085,-.025)})
	if action!="basic": load=_change(load,{"hip":Vector3(.095,-.305,.08),"left":Vector3(.15,1.47,-.79),"draw":.45})
	load.right=Vector3(load.left)+Vector3(0,0,.34+float(load.draw))
	var contact:=_change(load,{"draw":0.0,"arrow":0.0,"nock":0.0})
	var follow:=_change(contact,{"right":Vector3(load.right)+Vector3(.30,.10,.09),"hip":Vector3(.07,Vector3(load.hip).y+.02,.06),"pelvis":Vector3(.015,-.32,-.03),"chest":Vector3(.035,-.69,.035),"cloth":Vector3(.075,-.04,.015)})
	var return_pose:=_change(guard,{"hip":Vector3(.03,-.115,.025),"pelvis":Vector3(0,-.32,-.015),"chest":Vector3(.02,-.42,.025),"left":Vector3(.035,1.26,-.48),"right":Vector3(.40,1.25,.09),"weapon":Vector3(0,0,-.10),"cloth":Vector3(.035,-.035,0)})
	return {"guard":guard,"gather":gather,"load":load,"drive":load,"contact":contact,"follow":follow,"return":return_pose}

static func _foundation_sample(name: String,time: float,guard: Dictionary) -> Dictionary:
	var frames: Array=SwordFoundation.CURVES[name]
	var index:=mini(int(floor(time*30.0)),frames.size()-2)
	index=maxi(index,0)
	var a: Array=frames[index]; var b: Array=frames[index+1]
	var amount:=clampf((time-float(a[0]))/maxf(.001,float(b[0])-float(a[0])),0,1)
	var state:=guard.duplicate(true)
	for field in {"hip":1,"right":12,"right_pole":15,"left":18,"left_pole":21}:
		var offset: int={"hip":1,"right":12,"right_pole":15,"left":18,"left_pole":21}[field]
		state[field]=Vector3(a[offset],a[offset+1],a[offset+2]).lerp(Vector3(b[offset],b[offset+1],b[offset+2]),amount)
	for field in {"pelvis":4,"chest":8,"weapon":24}:
		var offset: int={"pelvis":4,"chest":8,"weapon":24}[field]
		state[field]=Quaternion(a[offset],a[offset+1],a[offset+2],a[offset+3]).slerp(Quaternion(b[offset],b[offset+1],b[offset+2],b[offset+3]),amount)
	# Source is a free off-hand sword fighter. The shield occupies the front
	# guard instead of being whipped behind the body by the free-arm gesture.
	var pelvis_basis:=_basis(state.pelvis)
	var chest_basis:=pelvis_basis*_basis(state.chest)
	var shoulder:=Vector3(0,1.053,0)+Vector3(state.hip)+pelvis_basis*Vector3(0,.39,0)+chest_basis*Vector3(-.32,.19,0)
	var brace:=shoulder+Vector3(-.10,-.43,-.28)
	# The source fighter has no shield. Its deep shoulder roll must still
	# leave room for our shield below the fist, rather than burying the rim.
	brace.y=maxf(brace.y,.70)
	state.left=Vector3(state.left).lerp(brace,.92)
	state.left_pole=Vector3(-.30,.60,-.50)
	return state

static func _vowkeeper_state(spec: Dictionary,clip: String,u: float) -> Dictionary:
	var recovery:=clip.begins_with("recover")
	var diagonal:=clip.ends_with("skill")
	var source:="diagonal" if diagonal else "cut"
	var time:=0.0
	if not recovery:
		if diagonal: time=lerpf(0,.09,smoothstep(0,.60,u)) if u<.60 else lerpf(.09,.28,(u-.60)/.40)
		else:
			var chamber:=.73 if clip.ends_with("heavy") else .61
			time=lerpf(0,.30,smoothstep(0,chamber,u)) if u<chamber else lerpf(.30,.43,(u-chamber)/(1.0-chamber))
	else:
		if diagonal:
			if u<.34: time=lerpf(.28,.533333,u/.34)
			else: source="diagonal_return"; time=lerpf(0,1.033333,smoothstep(.34,1.0,u))
		else: time=lerpf(.43,.82,u/.45) if u<.45 else lerpf(.82,1.533333,smoothstep(.45,1.0,u))
	var state:=_foundation_sample(source,time,spec.guard)
	var drive: float=(1.0-smoothstep(.43,.91,u)) if recovery else smoothstep(.35,.89,u)
	var weight:=Vector3(0,0,-.14*drive)
	for field in ["hip","right","left"]: state[field]+=weight
	state.knee_l=Vector3(-.18,0,-1); state.knee_r=Vector3(.26,0,-1)
	state.cloth=Vector3(.12*drive,-.055*drive,.025*drive)
	if recovery: return _mix(state,spec.guard,smoothstep(.77,1.0,u))
	return _mix(spec.guard,state,smoothstep(0,.22,u))

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

static func solve_two(p: Array[Transform3D],upper: int,lower: int,end: int,target: Vector3,pole: Vector3,key: String,profile: Dictionary={}) -> void:
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
	if profile.is_empty():
		global_rotation(p,upper,Basis(Quaternion(p[lower].origin.normalized(),(elbow-start).normalized())),key)
		global_rotation(p,lower,Basis(Quaternion(p[end].origin.normalized(),(finish-elbow).normalized())),key)
	else:
		# Source A-pose chains carry an anatomical bend plane. Preserve its roll
		# while changing the bend angle; a shortest-arc swing alone discards it.
		var rest_normal:=p[lower].origin.cross(p[end].origin).normalized()
		var posed_normal:=(elbow-start).cross(finish-elbow).normalized()
		assert(rest_normal.length_squared()>.5,"A source IK chain requires an authored bend plane")
		global_rotation(p,upper,_chain_frame(elbow-start,posed_normal)*_chain_frame(p[lower].origin,rest_normal).transposed(),key)
		global_rotation(p,lower,_chain_frame(finish-elbow,posed_normal)*_chain_frame(p[end].origin,rest_normal).transposed(),key)

static func _chain_frame(direction: Vector3,normal: Vector3) -> Basis:
	var y:=direction.normalized()
	var z:=(normal-y*normal.dot(y)).normalized()
	return Basis(y.cross(z),y,z)

static func _spec(key: String,action: String="basic") -> Dictionary:
	if key=="Arcanist": return _arcanist_spec(action)
	if key=="Ranger": return _ranger_spec(action)
	var caster:=key in ["hexer","guardian_1","guardian_2"]
	var raider:=key=="raider"
	var skill:=action=="skill"
	var heavy:=action=="heavy"
	# Each phrase has a gathering pose, a held chamber, a passing pose, contact,
	# follow-through and a separate return path. Skill cuts/casts are authored
	# in their own planes; they are not the basic pose multiplied by a gain.
	var guard: Dictionary={"hip":Vector3(0,-.055,0),"pelvis":Vector3(0,.025,0),"chest":Vector3(0,.08,0),"right":Vector3(.32,1.10,-.20),"left":Vector3(-.38,1.24,-.29),"weapon":Vector3(-.18,0,-.15),"palm":Vector3(-.14,0,-.10),"left_pole":Vector3(-1,-.10,.35),"right_pole":Vector3(1,-.10,.40),"knee_l":Vector3(-.16,0,-1),"knee_r":Vector3(.18,0,-1),"cloth":Vector3(.016,0,0),"draw":0.0,"arrow":0.0,"nock":0.0,"support":0.0}
	if key=="Vowkeeper":
		guard.left=Vector3(-.34,.96,-.33); guard.left_pole=Vector3(-.30,.60,-.50)
	if caster:
		guard.right=Vector3(.34,1.03,-.09); guard.left=Vector3(-.17,1.19,-.22)
		guard.chest=Vector3(0,-.10,0); guard.pelvis=Vector3(0,-.03,0); guard.weapon=Vector3(-.12,0,-.12)
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
	if skill and not caster:
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
	if key=="Vowkeeper": return _vowkeeper_state(spec,clip,u)
	if key in ["Arcanist","Ranger"]:
		if clip.begins_with("windup"):
			if key=="Ranger":
				if u<.24: return _mix(spec.guard,spec.gather,smoothstep(0,.24,u))
				if u<.72: return _mix(spec.gather,spec.load,smoothstep(.24,.72,u))
				return spec.load.duplicate(true)
			if u<.22: return _mix(spec.guard,spec.gather,smoothstep(0,.22,u))
			if u<.38: return _mix(spec.gather,spec.load,smoothstep(.22,.38,u))
			if u<.55: return spec.load.duplicate(true)
			if u<.79: return _mix(spec.load,spec.drive,pow((u-.55)/.24,1.15))
			return _mix(spec.drive,spec.contact,(u-.79)/.21)
		var catch:=.31 if key=="Ranger" else .22
		if u<catch: return _mix(spec.contact,spec.follow,1.0-pow(1.0-u/catch,2.0))
		if key=="Ranger" and u<.40: return spec.follow.duplicate(true)
		if u<.78: return _mix(spec.follow,spec["return"],smoothstep(.40 if key=="Ranger" else catch,.78,u))
		return _mix(spec["return"],spec.guard,smoothstep(.78,1.0,u))
	if clip.begins_with("windup"):
		var heavy:=clip.ends_with("heavy")
		var gather_end:=.14
		var load_end:=.34
		var commit:=.78 if heavy else (.56 if clip.ends_with("skill") else .52)
		if u<gather_end: return _mix(spec.guard,spec.gather,smoothstep(0,gather_end,u))
		if u<load_end: return _mix(spec.gather,spec.load,smoothstep(gather_end,load_end,u))
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
	var overshoot:=.28 if clip.ends_with("heavy") else .24
	if u<overshoot: return _mix(spec.contact,spec.follow,1.0-pow(1.0-clampf(u/overshoot,0,1),2.0))
	if u<.74: return _mix(spec.follow,spec["return"],smoothstep(overshoot+.035,.74,u))
	return _mix(spec["return"],spec.guard,smoothstep(.74,1.0,u))

static func _mix(a: Dictionary,b: Dictionary,t: float) -> Dictionary:
	var result: Dictionary={}
	for name in a:
		if a[name] is Quaternion or b[name] is Quaternion: result[name]=_rotation(a[name]).slerp(_rotation(b[name]),t)
		else: result[name]=a[name].lerp(b[name],t) if a[name] is Vector3 else lerpf(a[name],b[name],t)
	return result

static func _source_hand_target(p: Array[Transform3D],key: String,state: Dictionary,side: int,authored: Vector3,vertical_offset: float) -> Vector3:
	# These are the immutable coordinate references in which the existing
	# phrase was authored, not dimensions imposed on the new skin or skeleton.
	var pelvis:=_basis(state.pelvis)
	var chest:=pelvis*_basis(state.chest)
	var reference:=Vector3(0,1.053+vertical_offset,0)+Vector3(state.hip)+pelvis*Vector3(0,.39,0)+chest*Vector3(-.32 if side==0 else .32,.19,0)
	var upper:=5 if side==0 else 9
	var old_a:=.3534
	var old_b:=Vector3(0,-.3192,-.01).length()
	var offset:=authored-reference
	# Transfer the displayed reference joint, including its existing elbow
	# limit. The old walk/gather inputs sometimes sit inside that limit; using
	# those unsolved points would invent a new, unreachable source wrist path.
	var old_distance:=clampf(offset.length(),sqrt(old_a*old_a+old_b*old_b+2.0*old_a*old_b*cos(2.40)),old_a+old_b-.001)
	var bend_cos:=(old_distance*old_distance-old_a*old_a-old_b*old_b)/(2.0*old_a*old_b)
	var a:=p[upper+1].origin.length()
	var b:=p[upper+2].origin.length()
	var distance:=clampf(sqrt(maxf(0.0,a*a+b*b+2.0*a*b*bend_cos)),sqrt(a*a+b*b+2.0*a*b*cos(2.40))+.0002,a+b-.0012)
	return global_pose(p,upper,key).origin+offset.normalized()*distance

static func _source_walk_hand(p: Array[Transform3D],key: String,u: float) -> Vector3:
	var reach:=p[6].origin.length()+p[7].origin.length()
	# The casting guard is not a locomotion pose. Let the free arm hang from
	# its actual shoulder and swing opposite the front leg, with a soft elbow.
	return global_pose(p,5,key).origin+Vector3(-.08*reach,-.82*reach,(-.065+.205*cos(u*TAU))*reach)

static func _source_cast_state(clip: String,u: float) -> Dictionary:
	# Measured anatomical arm lengths define this shoulder-relative phrase.
	# The old glove's absolute +X contact crossed the left forearm over the
	# entire chest. Keep this palm on its own side while the unchanged body
	# coil carries the shoulder forward; the elbow stays below the reach.
	var guard: Dictionary={"offset":Vector3(-.18,-.38,-.37),"pole":Vector3(-.45,-1,.20),"aim":0.0,"roll":0.0}
	var spec: Dictionary={
		"guard":guard,
		"gather":{"offset":Vector3(-.34,-.18,-.29),"pole":Vector3(-.65,-.70,.25),"aim":.04,"roll":0.0},
		"load":{"offset":Vector3(-.44,.30,-.25),"pole":Vector3(-1,.08,.40),"aim":.08,"roll":-.15},
		"drive":{"offset":Vector3(-.20,.02,-.69),"pole":Vector3(-.25,-1,.05),"aim":.82,"roll":-.15},
		"contact":{"offset":Vector3(-.13,-.075,-.88),"pole":Vector3(-.15,-1,.05),"aim":1.0,"roll":0.0},
		"follow":{"offset":Vector3(-.13,-.11,-.90),"pole":Vector3(-.15,-1,.05),"aim":1.0,"roll":0.0},
		"return":{"offset":Vector3(-.19,-.34,-.48),"pole":Vector3(-.35,-1,.15),"aim":.15,"roll":0.0}}
	return _action_state(spec,"Arcanist",clip,u) if clip.begins_with("windup") or clip.begins_with("recover") else guard

static func _source_cast_target(p: Array[Transform3D],key: String,clip: String,u: float) -> Vector3:
	var state:=_source_cast_state(clip,u)
	return global_pose(p,5,key).origin+Vector3(state.offset)*(p[6].origin.length()+p[7].origin.length())

static func _source_cast_arm(p: Array[Transform3D],key: String,clip: String,u: float,profile: Dictionary) -> void:
	var state:=_source_cast_state(clip,u)
	var wrist:=_source_cast_target(p,key,clip,u)
	solve_two(p,5,6,7,wrist,state.pole,key,profile)
	var forearm:=global_pose(p,6,key).basis
	var frame:=_socket_basis(profile,"hands",0,"palm_basis_columns")
	# Aim both semantic axes: fingers run up/forward, with the open palm
	# tilted toward the target. A normal-only swing permits sideways fingers
	# and transfers forearm pronation into a visibly twisted wrist.
	var directed:=Basis(Vector3.BACK,float(state.roll))*Basis(Vector3.RIGHT,deg_to_rad(-35.0))*frame.inverse()
	var hand:=forearm.slerp(directed,float(state.aim))
	var relative: Quaternion=(forearm.inverse()*hand).get_rotation_quaternion()
	if relative.w<0.0: relative=-relative
	var long_axis:=p[7].origin.normalized()
	var axial:=long_axis*Vector3(relative.x,relative.y,relative.z).dot(long_axis)
	var pronation:=Quaternion(axial.x,axial.y,axial.z,relative.w).normalized()
	# Axial rotation about elbow->wrist leaves both joints fixed. Carry it in
	# the forearm; the anatomical wrist then supplies only the fitted bend.
	global_rotation(p,6,forearm*Basis(pronation),key)
	global_rotation(p,7,hand,key)

static func _source_staff_state(clip: String,u: float) -> Dictionary:
	# Carry the staff beside the lower ribs while the unchanged torso coils.
	# The old glove's rearward absolute target put the source shoulder into
	# extension and asked the wrist to compensate for the shaft orientation.
	var guard: Dictionary={"offset":Vector3(.28,-.56,-.30)}
	var spec: Dictionary={
		"guard":guard,
		"gather":{"offset":Vector3(.31,-.54,-.25)},
		"load":{"offset":Vector3(.32,-.52,-.22)},
		"drive":{"offset":Vector3(.29,-.53,-.28)},
		"contact":{"offset":Vector3(.26,-.54,-.33)},
		"follow":{"offset":Vector3(.27,-.56,-.34)},
		"return":{"offset":Vector3(.29,-.55,-.28)}}
	var state: Dictionary=_action_state(spec,"Arcanist",clip,u) if clip.begins_with("windup") or clip.begins_with("recover") else guard.duplicate()
	if clip=="walk": state.offset+=Vector3(0,.012*sin(u*TAU),.025*sin(u*TAU))
	return state

static func _source_staff_target(p: Array[Transform3D],key: String,clip: String,u: float) -> Vector3:
	var state:=_source_staff_state(clip,u)
	var reach:=p[10].origin.length()+p[11].origin.length()
	return global_pose(p,9,key).origin+global_pose(p,2,key).basis*(Vector3(state.offset)*reach)

static func _source_staff_arm(p: Array[Transform3D],key: String,clip: String,u: float,effector: Basis,profile: Dictionary) -> void:
	var wrist:=_source_staff_target(p,key,clip,u)
	var local_pole:=Vector3(.60,-1,0)
	var fit: Dictionary=profile.get("motion_fit",{})
	if fit.has("staff_elbow_pole_local"): local_pole=_vector(fit.staff_elbow_pole_local)
	var pole:=global_pose(p,2,key).basis*local_pole
	solve_two(p,9,10,11,wrist,pole,key,profile)
	var forearm:=global_pose(p,10,key).basis
	var long_axis:=p[11].origin.normalized()
	var world_axis:=forearm*long_axis
	var tool_frame:=_socket_basis(profile,"hands",1,"tool_basis_columns")
	var shaft:=forearm*tool_frame.y
	var from_axis:=(shaft-world_axis*shaft.dot(world_axis)).normalized()
	var to_axis:=(effector.y-world_axis*effector.y.dot(world_axis)).normalized()
	# Turn around the anatomical forearm axis to carry the measured grip.
	# The staff is allowed its natural inclination; forcing it upright with a
	# capped wrist swing formerly concealed 54 degrees of radial deviation.
	var pronation:=atan2(world_axis.dot(from_axis.cross(to_axis)),from_axis.dot(to_axis))
	var carried:=forearm*Basis(Quaternion(long_axis,pronation))
	global_rotation(p,10,carried,key)
	global_rotation(p,11,carried,key)
	# Source tool frame and palm offset are already baked into the rigid prop.
	global_rotation(p,20,carried,key)

static func _source_hand(p: Array[Transform3D],key: String,side: int,authored_joint: Vector3,effector: Basis,pole: Vector3,profile: Dictionary,tool: bool,palm_angles: Vector3=Vector3.ZERO,relaxed: bool=false,aim_weight: float=1.0) -> void:
	var upper:=5 if side==0 else 9
	var frame:=_socket_basis(profile,"hands",side,"tool_basis_columns" if tool else "palm_basis_columns")
	var socket:=_socket_vector(profile,"hands",side,"grip_local")
	# The legacy Hand joint and grip shared one pivot. Transfer that joint
	# path to an anatomical wrist first; a newly separate palm must not pull
	# the wrist backward into an impossible fold to preserve the old pivot.
	var wrist:=_reachable_wrist(p,upper,authored_joint,key)
	solve_two(p,upper,upper+1,upper+2,wrist,pole,key,profile)
	var neutral:=global_pose(p,upper+1,key).basis*frame
	var swing:=Quaternion(neutral.y if tool else neutral.z,effector.y if tool else effector.z)
	var angle:=swing.get_angle()
	var limit:=deg_to_rad(55.0 if tool else 70.0)
	if angle>limit: swing=Quaternion.IDENTITY.slerp(swing,limit/angle)
	var hand_basis:=Basis(swing)*neutral*frame.inverse()
	if not tool:
		# Gather with a neutral wrist; the authored extension/catch phase turns
		# the actual palmar surface toward -Z. Copying old glove Euler axes
		# would instead face this reconstructed palm across the target plane.
		var extension:=clampf((-palm_angles.x-.14)/1.36,0,1)
		var facing:=Quaternion(neutral.z,Vector3.BACK)
		var amount:=minf(1.0,limit/maxf(.0001,facing.get_angle()))*extension*aim_weight
		# As the forearm folds back past its usable aiming hemisphere, relax
		# the wrist before a shortest-arc normal reaches the opposite direction.
		amount*=smoothstep(-.85,-.30,neutral.z.dot(Vector3.BACK))
		if relaxed: amount=0.0
		hand_basis=Basis(Quaternion.IDENTITY.slerp(facing,amount))*neutral*frame.inverse()
	# The fitted effector has a measured palm offset and the calibrated frame.
	# Recover its wrist with the same socket convention used by runtime Rig.
	var fitted_centre:=wrist+hand_basis*socket
	wrist=fitted_centre-hand_basis*socket
	solve_two(p,upper,upper+1,upper+2,wrist,pole,key,profile)
	global_rotation(p,upper+2,hand_basis,key)
	if tool:
		# Exported staff vertices already contain the source tool frame.
		global_rotation(p,20,hand_basis,key)

static func _reachable_wrist(p: Array[Transform3D],upper: int,target: Vector3,key: String) -> Vector3:
	var shoulder:=global_pose(p,upper,key).origin
	var a:=p[upper+1].origin.length()
	var b:=p[upper+2].origin.length()
	var offset:=target-shoulder
	var distance:=clampf(offset.length(),sqrt(a*a+b*b+2.0*a*b*cos(2.40))+.0002,a+b-.0012)
	return shoulder+(offset.normalized() if offset.length_squared()>.000001 else Vector3.DOWN)*distance

static func _author_source(key: String,clip: String,u: float,rests: Array[Transform3D],profile: Dictionary) -> Array[Transform3D]:
	var action:=clip.get_slice("_",1) if clip.contains("_") else "basic"
	var spec:=_spec(key,action)
	var state: Dictionary=spec.guard.duplicate(true)
	var walking:=clip=="walk"
	var death:=clip=="death"
	var acting:=clip.begins_with("windup") or clip.begins_with("recover")
	var breath:=sin(u*TAU) if clip=="idle" else 0.0
	if acting: state=_action_state(spec,key,clip,u)
	if walking:
		state.hip=Vector3(0,(-.105+.012*cos(u*TAU*2))*1.17,0)
		state.chest=Vector3(-.055,.035*sin(u*TAU),.01*sin(u*TAU))
		state.pelvis=Vector3(0,Vector3(state.chest).y*.30,0)
		state.right+=Vector3(0,.018*sin(u*TAU),.075*sin(u*TAU))
		state.left+=Vector3(0,-.018*sin(u*TAU),-.060*sin(u*TAU))
	if death:
		state=_mix(spec.guard,_change(spec.guard,{"hip":Vector3(0,-.02,0),"pelvis":Vector3.ZERO,"chest":Vector3(-.10,0,.035),"right":Vector3(.27,1.153,.06),"left":Vector3(-.33,1.233,.08),"weapon":Vector3.ZERO,"draw":0.0,"arrow":0.0,"nock":0.0,"support":0.0}),smoothstep(0,.40,u))
	var ratio:=_leg_ratio(profile)
	var vertical_offset:=breath*.005-(.23*sin(clampf(u/.46,0,1)*PI) if death else 0.0)
	var p: Array[Transform3D]=[]
	p.assign(rests)
	p[1].origin+=(Vector3(state.hip)+Vector3(0,vertical_offset,0))*ratio
	p[1].basis=_basis(state.pelvis)
	var chest_angles:=_angles(state.chest)
	p[2].basis=_basis(state.chest)*Basis.from_euler(Vector3(breath*.007,0,0))
	p[3].basis=Basis.from_euler(Vector3(-chest_angles.x*.22,-chest_angles.y*.42,0))
	if acting: global_rotation(p,3,Basis.from_euler(Vector3(-.015+chest_angles.x*.08,chest_angles.y*.10,-chest_angles.z*.15)),key)
	var left:=_source_hand_target(p,key,state,0,state.left,vertical_offset)
	var right:=_source_hand_target(p,key,state,1,state.right,vertical_offset)
	if walking: left=_source_walk_hand(p,key,u)
	var weapon_basis:=_basis(state.weapon)
	# In the semantic palm frame +Y follows the fingers and -Z faces out of
	# the casting palm. The old glove frame was offset by a quarter turn.
	var palm_basis:=Basis.from_euler(state.palm)*Basis(Vector3.RIGHT,PI*.5)
	if death: palm_basis=Basis.from_euler(Vector3(PI*.5-.14,0,-.10))
	if key=="Arcanist" and not death:
		_source_staff_arm(p,key,clip,u,weapon_basis,profile)
	else:
		_source_hand(p,key,1,right,weapon_basis,Vector3(1,.15,.45) if death else Vector3(state.right_pole),profile,true)
	# Release the aiming wrist during the existing catch, before the returning
	# elbow reverses its bend plane. The body and recovery clock are unchanged.
	var aim_weight:=1.0-smoothstep(.22,.52,u) if clip.begins_with("recover") else 1.0
	if walking or death:
		_source_hand(p,key,0,left,palm_basis,Vector3(-1,.15,.35) if death else Vector3(state.left_pole),profile,false,state.palm,walking,aim_weight)
	else:
		_source_cast_arm(p,key,clip,u,profile)
	p[24].basis=Basis.IDENTITY.scaled(Vector3.ZERO)
	var cloth: Vector3=state.cloth
	var cloth_lag: Vector3=_action_state(spec,key,clip,maxf(0.0,u-.085)).cloth if acting else cloth
	for side in range(2):
		var foot:=walk_foot(key,u,side,profile) if walking else (action_foot(key,clip,u,side,profile) if acting else stance_foot(key,side,profile))
		if death: foot=walk_anchor(key,side,profile)
		var knee_pole: Vector3=state.knee_l if side==0 else state.knee_r
		solve_two(p,12 if side==0 else 15,13 if side==0 else 16,14 if side==0 else 17,foot,Vector3.FORWARD if walking or death else knee_pole,key,profile)
		global_rotation(p,14 if side==0 else 17,action_foot_basis(key,side,profile),key)
		p[25+side].basis=Basis.from_euler(cloth*.28+Vector3(0,0,(-.012 if side==0 else .012)*cloth.x) if acting else Vector3(.025*sin(u*TAU+side*PI) if walking else breath*.007,0,0))
	# Imported body weights are never compressed to fit a garment. The actual
	# cloth attachment bones receive the restrained angular follow-through.
	p[18].basis=Basis.from_euler(cloth if acting else Vector3(.06 if walking else .016+breath*.008,0,.015*sin(u*TAU)))
	p[19].basis=Basis.from_euler(cloth_lag*.60 if acting else Vector3(.045*sin(u*TAU-.55) if walking else breath*.012,0,0))
	p[27].basis=Basis.from_euler(cloth_lag*.12 if acting else Vector3(breath*.007,0,.012*sin(u*TAU-.40)))
	p[28].basis=Basis.from_euler(cloth_lag*.10 if acting else Vector3(breath*.007,0,-.012*sin(u*TAU-.40)))
	if death: _source_fall(p,key,u,ratio,profile)
	return p

static func _source_fall(p: Array[Transform3D],key: String,u: float,ratio: float,profile: Dictionary) -> void:
	var fall:=smoothstep(.16,.94,u)
	var fold:=smoothstep(.31,.87,u)
	var settle:=smoothstep(.58,1.0,u)
	var gather:=sin(clampf(u/.46,0,1)*PI)
	p[1].basis=Basis.from_euler(Vector3(.08*fold,.28*fold,.055*fold))
	p[2].basis=Basis.from_euler(Vector3(-.20*fold,-.18*fold,.045*fold))
	p[3].basis=Basis.from_euler(Vector3(.12*settle,.40*settle,-.12*settle))
	p[15].basis=p[15].basis.slerp(Basis.from_euler(Vector3(-.58,.08,.18)),fold)
	p[16].basis=p[16].basis.slerp(Basis.from_euler(Vector3(.87,0,0)),fold)
	p[17].basis=p[17].basis.slerp(Basis.from_euler(Vector3(-.12,0,0)),settle)
	global_rotation(p,18,Basis.from_euler(Vector3(.14*settle,0,.025*settle)),key)
	p[19].basis=Basis.from_euler(Vector3(.12*settle,0,-.025*settle))
	p[19].origin.y+=.09*gather*ratio
	global_rotation(p,25,Basis.from_euler(Vector3(.22*settle,0,-.86*gather)),key)
	global_rotation(p,26,Basis.from_euler(Vector3(.22*settle,0,.86*gather)),key)
	p[27].basis=Basis.from_euler(Vector3(.18*settle,0,-.11*settle))
	p[28].basis=Basis.from_euler(Vector3(.14*settle,0,.09*settle))
	p[0].origin=Vector3(.075*fall,.33*fall-.035*smoothstep(.92,1.0,u),-.05*fall)*ratio
	p[0].basis=Basis.from_euler(Vector3(-PI*.5*fall,0,.045*fall))
	# A source's actual boots supply their own support envelope. Never use
	# the earlier body's vertices to fit this anatomical source to the floor.
	# This contact offset affects only the falling root, never a standing or
	# action root. Complete skinned-floor verification is still required.
	var support_y:=INF
	for side in range(2):
		var foot:=global_pose(p,14 if side==0 else 17,key)
		var foot_data: Dictionary=profile.feet["L" if side==0 else "R"]
		var measured_skin: Array=foot_data.get("support_skin",[])
		var measured: Array=foot_data.get("support_points_local",[])
		if not measured_skin.is_empty():
			assert(measured_skin.size()>=4,"Source fall requires a measured skinned outsole envelope")
			for support in measured_skin:
				var bind_point:=_vector(support.position)
				var posed:=Vector3.ZERO
				var total:=0.0
				assert(support.joints.size()==4 and support.weights.size()==4,"Outsole vertices retain their actual four skin influences")
				for influence in range(4):
					var weight: float=support.weights[influence]
					var bone: int=int(support.joints[influence])
					assert(bone>=0 and bone<NAMES.size() and weight>=0.0,"Invalid source support influence")
					if weight>0.0: posed+=(global_pose(p,bone,key)*(bind_point-_rest_point(profile,NAMES[bone])))*weight
					total+=weight
				assert(absf(total-1.0)<.0001,"Outsole skin weights must be normalized")
				support_y=minf(support_y,posed.y)
		elif not measured.is_empty():
			assert(not profile.has("source"),"An authored source must supply actual outsole skin weights")
			for support in measured: support_y=minf(support_y,(foot*_vector(support)).y)
		else:
			# Historical MPFB profile compatibility only. Newly identified
			# authored sources must export their real support measurements.
			assert(not profile.has("source"),"An authored source cannot inherit another body's floor supports")
			for support in [Vector3(.018804753,-.098581,-.221338304),Vector3(.029812181,-.098581,-.218608262),Vector3(.067068973,-.098581,-.106236832),Vector3(-.042864001,-.098581,-.077341998),Vector3(.004507238,-.098581,.066654311),Vector3(-.004749393,-.098581,.063928697)]:
				if side==0: support.x=-support.x
				support_y=minf(support_y,(foot*support).y)
	p[0].origin.y+=maxf(0.0,.002*fall-support_y)

static func _author(key: String,clip: String,u: float,rests: Array[Transform3D],profile: Dictionary={}) -> Array[Transform3D]:
	if not profile.is_empty(): return _author_source(key,clip,u,rests,profile)
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
	p[1].basis=_basis(state.pelvis)
	var chest_angles:=_angles(state.chest)
	p[2].basis=_basis(state.chest)*Basis.from_euler(Vector3(breath*.007,0,0))
	p[3].basis=Basis.from_euler(Vector3(-chest_angles.x*.22,-chest_angles.y*.42,0))
	if acting:
		# Eyes retain the target while shoulders and hips turn underneath.
		global_rotation(p,3,Basis.from_euler(Vector3(-.015+chest_angles.x*.08,chest_angles.y*.10,-chest_angles.z*.15)),key)
	var left: Vector3=state.left; var right: Vector3=state.right
	var weapon_basis:=_basis(state.weapon)
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
		if key=="Vowkeeper" and acting:
			# Fit the transferred blade arc to native floor clearance at the
			# solved wrist. A smooth elevation blend rotates fist and blade
			# together without changing the hand path or the contact phase.
			var wrist_y:=global_pose(p,11,key).origin.y
			var blade:=weapon_basis.y
			var gap:=wrist_y+blade.y*1.39-.075
			if gap<.060:
				var tip_y:=.075 if gap<=-.060 else .075+pow(gap+.060,2.0)/.240
				var elevation:=clampf((tip_y-wrist_y)/1.39,-.999,.999)
				var horizontal:=Vector3(blade.x,0,blade.z).normalized()
				if horizontal.length_squared()<.5: horizontal=Vector3.FORWARD
				var direction:=horizontal*sqrt(1.0-elevation*elevation)+Vector3.UP*elevation
				weapon_basis=Basis(Quaternion(blade,direction))*weapon_basis
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
			foot=action_foot(key,clip,u,side) if acting else stance_foot(key,side)
		if walking:
			if phase<.5: foot.z+=-.40+phase*1.60
			else:
				var swing:=(phase-.5)*2.0
				foot.z+=.40-.80*smoothstep(0,1,swing)
				foot.y+=sin(swing*PI)*.115
		var knee_pole: Vector3=state.knee_l if side==0 else state.knee_r
		solve_two(p,12 if side==0 else 15,13 if side==0 else 16,14 if side==0 else 17,foot,Vector3.FORWARD if walking or death else knee_pole,key)
		global_rotation(p,14 if side==0 else 17,action_foot_basis(key,side) if not walking and not death else Basis.IDENTITY,key)
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
