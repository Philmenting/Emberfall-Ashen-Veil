extends RefCounted
## Geometry shared by combat, avoidance and rendering. No RNG or scene state.
const NAMES := ["Bell Requiem","Drowning Tide","Grave Bloom","Furnace Cross"]
const DESCRIPTIONS := [
	"A ring blast leaves a safe center; its alternate fills more of the chamber.",
	"A long tide lane alternates with a cross-current through the passage.",
	"Three grave blasts land side by side or in a line.",
	"The fire cross alternates between straight and diagonal lanes."
]
const PHASE_NAMES := [
	["Crowned Vigil","Crown Break","Final Toll"],
	["Low Water","Broken Levee","Black Undertow"],
	["Dormant Roots","Grief in Bloom","Grave Convergence"],
	["Banked Furnace","Riven Forge","Ashen Overload"]
]
const PHASE_DESCRIPTIONS := [
	["The bell's ring leaves its center safe.","The crown shatters. A cleaving lane now cuts through the ring's safe center.","Split bell rings overlap a final cleaving lane. Escape between their edges."],
	["A tide lane sweeps the chamber.","The levee breaks into two parallel currents. Hold the gap between them.","A drowning ring surrounds a crossing current. Find a dry pocket away from the lane."],
	["Three graves bloom in a straight row.","The roots spread into a triangular bloom. Read the gaps between the graves.","The graves converge into an outer ring and a central eruption. Move between them."],
	["A furnace cross leaves open sectors.","The forge splits; a central fireball closes the crossing's center.","A furnace ring joins two narrow cleaves. Follow the open sectors beyond their ends."]
]

static func create(region: int, origin: Vector2, target: Vector2, awakened: bool, variant: int = 0) -> Dictionary:
	var index:=clampi(region,0,3)
	var selected_variant:=clampi(variant,0,1)
	var aim: Vector2=(target-origin).normalized()
	if aim.length_squared()<0.5: aim=Vector2.DOWN
	var side:=Vector2(-aim.y,aim.x)
	var zones: Array=[]
	match index:
		0:
			if selected_variant==0:
				zones.append({"shape":"annulus","center":origin,"radius":4.8 if awakened else 4.4,"inner":1.7 if awakened else 2.1})
			else:
				zones.append({"shape":"circle","center":origin,"radius":4.8 if awakened else 4.4})
		1:
			if selected_variant==0:
				zones.append({"shape":"beam","center":target,"direction":aim,"radius":1.25 if awakened else 0.95,"length":5.5})
			else:
				zones.append({"shape":"beam","center":origin.lerp(target,0.5),"direction":side,"radius":1.0 if awakened else 0.8,"length":4.8})
		2:
			var row_direction:=side if selected_variant==0 else aim
			for offset in [-2.3,0.0,2.3]:
				zones.append({"shape":"circle","center":target+row_direction*offset,"radius":1.35 if awakened else 1.15})
		3:
			var diagonal:=Vector2.from_angle(aim.angle()+PI*0.25)
			var directions: Array=[Vector2.RIGHT,Vector2.DOWN] if selected_variant==0 else [diagonal,diagonal.rotated(PI*0.5)]
			for direction in directions:
				zones.append({"shape":"beam","center":target,"direction":direction,"radius":1.0 if awakened else 0.75,"length":5.3})
	var duration:=1.25 if awakened else 1.65
	return {"center":target,"radius":5.5,"left":duration,"total":duration,"zones":zones,"pattern":index,"variant":selected_variant,"name":NAMES[index],"awakened":awakened,"multiplier":[2.4,2.2,2.2,2.5][index]*(1.1 if awakened else 1.0)}

static func phase_for_health(hp: int, maximum: int) -> int:
	if hp*3<=maximum: return 2
	return 1 if hp*3<=maximum*2 else 0

static func phase_name(region: int, phase: int) -> String:
	return PHASE_NAMES[clampi(region,0,3)][clampi(phase,0,2)]

static func phase_description(region: int, phase: int) -> String:
	return PHASE_DESCRIPTIONS[clampi(region,0,3)][clampi(phase,0,2)]

static func create_phased(region: int, origin: Vector2, target: Vector2, phase: int, variant: int=0) -> Dictionary:
	var index:=clampi(region,0,3)
	var selected_phase:=clampi(phase,0,2)
	var selected_variant:=clampi(variant,0,1)
	# Phase zero deliberately uses the original sealed guardian geometry.
	var warning:=create(index,origin,target,false,selected_variant)
	if selected_phase>0:
		var aim: Vector2=(target-origin).normalized()
		if aim.length_squared()<0.5: aim=Vector2.DOWN
		var side:=Vector2(-aim.y,aim.x)
		var zones: Array=[]
		match index:
			0:
				if selected_phase==1:
					zones.append({"shape":"annulus","center":origin,"radius":4.8,"inner":1.65})
					zones.append({"shape":"beam","center":origin,"direction":aim if selected_variant==0 else side,"radius":0.65,"length":5.2})
				else:
					var split_axis:=side if selected_variant==0 else aim
					for offset in [-1.45,1.45]: zones.append({"shape":"annulus","center":origin+split_axis*offset,"radius":3.3,"inner":1.2})
					zones.append({"shape":"beam","center":origin,"direction":aim if selected_variant==0 else side,"radius":0.55,"length":5.4})
			1:
				if selected_phase==1:
					var lane_axis:=aim if selected_variant==0 else side
					var split_axis:=Vector2(-lane_axis.y,lane_axis.x)
					for offset in [-1.55,1.55]: zones.append({"shape":"beam","center":target+split_axis*offset,"direction":lane_axis,"radius":0.7,"length":5.6})
				else:
					zones.append({"shape":"annulus","center":target,"radius":3.8,"inner":1.45})
					zones.append({"shape":"beam","center":target,"direction":aim if selected_variant==0 else side,"radius":0.65,"length":5.8})
			2:
				if selected_phase==1:
					var start:=aim.angle()+(PI/3.0 if selected_variant==1 else 0.0)
					for petal in range(3): zones.append({"shape":"circle","center":target+Vector2.from_angle(start+TAU*petal/3.0)*1.8,"radius":1.35})
				else:
					var center:=target+side*(0.8 if selected_variant==1 else -0.8)
					zones.append({"shape":"annulus","center":center,"radius":4.0,"inner":1.65})
					zones.append({"shape":"circle","center":center,"radius":0.9})
			3:
				var diagonal:=Vector2.from_angle(aim.angle()+PI*0.25)
				if selected_phase==1:
					var directions: Array=[diagonal,diagonal.rotated(PI*0.5)] if selected_variant==0 else [aim,side]
					for direction in directions: zones.append({"shape":"beam","center":target,"direction":direction,"radius":0.85,"length":5.4})
					zones.append({"shape":"circle","center":target,"radius":1.45})
				else:
					zones.append({"shape":"annulus","center":origin,"radius":4.65,"inner":2.0})
					var directions: Array=[aim,side] if selected_variant==0 else [diagonal,diagonal.rotated(PI*0.5)]
					for direction in directions: zones.append({"shape":"beam","center":target,"direction":direction,"radius":0.6,"length":5.6})
		warning.zones=zones
		warning.total=1.45 if selected_phase==1 else 1.3
		warning.left=warning.total
		warning.multiplier=[2.4,2.2,2.2,2.5][index]*(1.08 if selected_phase==1 else 1.18)
	warning.awakened=selected_phase>0
	warning["geometry_version"]=2
	warning["phase"]=selected_phase
	warning["phase_name"]=phase_name(index,selected_phase)
	warning["origin"]=origin
	warning["aim_target"]=target
	return warning

static func contains(zone: Dictionary, point: Vector2, margin: float=0.0) -> bool:
	var delta: Vector2=point-Vector2(zone.center)
	match String(zone.shape):
		"circle": return delta.length()<=float(zone.radius)+margin
		"annulus": return delta.length()<=float(zone.radius)+margin and delta.length()>=maxf(0.0,float(zone.inner)-margin)
		"beam":
			var axis: Vector2=zone.direction
			return absf(delta.dot(axis))<=float(zone.length)+margin and absf(delta.dot(Vector2(-axis.y,axis.x)))<=float(zone.radius)+margin
	return false

static func threatens(warning: Dictionary, point: Vector2, margin: float=0.0) -> bool:
	if not warning.has("zones"): return point.distance_to(warning.center)<=float(warning.radius)+margin
	for zone in warning.zones:
		if contains(zone,point,margin): return true
	return false

static func outlines(zone: Dictionary) -> Array:
	var result: Array=[]
	var center: Vector2=zone.center
	if zone.shape=="beam":
		var axis: Vector2=zone.direction
		var side:=Vector2(-axis.y,axis.x)
		result.append(PackedVector2Array([center-axis*zone.length-side*zone.radius,center+axis*zone.length-side*zone.radius,center+axis*zone.length+side*zone.radius,center-axis*zone.length+side*zone.radius]))
	else:
		var radii: Array=[zone.radius]
		if zone.shape=="annulus": radii.append(zone.inner)
		for radius in radii:
			var ring:=PackedVector2Array()
			for i in range(64): ring.append(center+Vector2.from_angle(TAU*i/64.0)*float(radius))
			result.append(ring)
	return result

static func triangles(zone: Dictionary) -> PackedVector2Array:
	var rings:=outlines(zone)
	var outer: PackedVector2Array=rings[0]
	var result:=PackedVector2Array()
	for i in range(outer.size()):
		var next: int=(i+1)%outer.size()
		if zone.shape=="annulus":
			var inner: PackedVector2Array=rings[1]
			result.append_array(PackedVector2Array([outer[i],outer[next],inner[i],outer[next],inner[next],inner[i]]))
		else:
			result.append_array(PackedVector2Array([Vector2(zone.center),outer[i],outer[next]]))
	return result

static func valid(warning: Dictionary) -> bool:
	if not warning.get("zones") is Array or warning.zones.is_empty() or warning.zones.size()>3: return false
	if not warning.get("pattern") is int or warning.pattern<0 or warning.pattern>3: return false
	if warning.has("variant") and (not warning.variant is int or warning.variant not in [0,1]): return false
	if warning.get("name")!=NAMES[warning.pattern] or not warning.get("awakened") is bool: return false
	if not number(warning.get("multiplier"),1.0,4.0): return false
	for zone in warning.zones:
		if not zone is Dictionary or not zone.get("shape") in ["circle","annulus","beam"]: return false
		var center=zone.get("center")
		if not center is Vector2 or not center.is_finite() or absf(center.x)>20 or center.y < -80 or center.y>20: return false
		if not number(zone.get("radius"),0.1,8.0): return false
		if zone.shape=="annulus" and not number(zone.get("inner"),0.1,float(zone.radius)-0.1): return false
		if zone.shape=="beam":
			var direction=zone.get("direction")
			if not direction is Vector2 or not direction.is_finite() or absf(direction.length()-1.0)>0.001: return false
			if not number(zone.get("length"),0.1,12.0): return false
	if warning.has("geometry_version") or warning.has("phase") or warning.has("phase_name") or warning.has("origin") or warning.has("aim_target"):
		if not _valid_phased(warning): return false
	return true

static func _valid_phased(warning: Dictionary) -> bool:
	if not warning.get("geometry_version") is int or warning.geometry_version!=2: return false
	if not warning.get("phase") is int or warning.phase not in [0,1,2]: return false
	if not warning.get("variant") is int or warning.variant not in [0,1]: return false
	for key in ["origin","aim_target"]:
		var point: Variant=warning.get(key)
		if not point is Vector2 or not point.is_finite() or absf(point.x)>20 or point.y < -80 or point.y>20: return false
	var expected:=create_phased(warning.pattern,warning.origin,warning.aim_target,warning.phase,warning.variant)
	if warning.size()!=expected.size(): return false
	for key in expected:
		if key=="left": continue
		if not warning.has(key) or warning[key]!=expected[key]: return false
	return number(warning.get("left"),0.0,float(expected.total))

static func number(value: Variant, low: float, high: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value>=low and value<=high
