extends RefCounted
## Geometry shared by combat, avoidance and rendering. No RNG or scene state.
const NAMES := ["Bell Requiem","Drowning Tide","Grave Bloom","Furnace Cross"]
const DESCRIPTIONS := [
	"A ringing shockwave leaves the center and the outside safe.",
	"A long tidal lane locks onto Nyra's position before it breaks.",
	"Three graves erupt together. Gaps beyond their circles remain safe.",
	"Two fire lanes cross. Their diagonal sectors remain safe."
]

static func create(region: int, origin: Vector2, target: Vector2, awakened: bool) -> Dictionary:
	var index:=clampi(region,0,3)
	var aim: Vector2=(target-origin).normalized()
	if aim.length_squared()<0.5: aim=Vector2.DOWN
	var side:=Vector2(-aim.y,aim.x)
	var zones: Array=[]
	match index:
		0:
			zones.append({"shape":"annulus","center":origin,"radius":4.8 if awakened else 4.4,"inner":1.7 if awakened else 2.1})
		1:
			zones.append({"shape":"beam","center":target,"direction":aim,"radius":1.25 if awakened else 0.95,"length":5.5})
		2:
			for offset in [-2.3,0.0,2.3]:
				zones.append({"shape":"circle","center":target+side*offset,"radius":1.35 if awakened else 1.15})
		3:
			for direction in [Vector2.RIGHT,Vector2.DOWN]:
				zones.append({"shape":"beam","center":target,"direction":direction,"radius":1.0 if awakened else 0.75,"length":5.3})
	var duration:=1.25 if awakened else 1.65
	return {"center":target,"radius":5.5,"left":duration,"total":duration,"zones":zones,"pattern":index,"name":NAMES[index],"awakened":awakened,"multiplier":[2.4,2.2,2.2,2.5][index]*(1.1 if awakened else 1.0)}

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
	return true

static func number(value: Variant, low: float, high: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value>=low and value<=high
