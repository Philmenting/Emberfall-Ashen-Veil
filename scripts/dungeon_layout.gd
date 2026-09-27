extends RefCounted
## Shared floor plan for simulation, scenery and the expedition map.
const ROOM_HALF := Vector2(5.8,5.0)
const HALL_HALF := 2.2
const ROUTES := [
	[Vector2(0,-4),Vector2(8,-17),Vector2(8,-30),Vector2(-6,-43),Vector2(-6,-56),Vector2(0,-69)],
	[Vector2(0,-4),Vector2(-8,-17),Vector2(4,-30),Vector2(9,-43),Vector2(-4,-56),Vector2(-4,-69)],
	[Vector2(0,-4),Vector2(7,-17),Vector2(-7,-30),Vector2(-7,-43),Vector2(7,-56),Vector2(0,-69)],
	[Vector2(0,-4),Vector2(-8,-17),Vector2(-8,-30),Vector2(8,-43),Vector2(8,-56),Vector2(0,-69)]
]
const NAMES := [
	["Broken Vestibule","Pilgrim's Well","Bell Causeway","Warden's Seal","Silent Choir","Belfry Sanctum"],
	["Drowned Landing","Scribe's Font","Sunken Stacks","Keeper's Seal","Flooded Gallery","Tidal Vault"],
	["Glassmouth","Moonwell","Shattered Crossing","Thornbound Seal","Bone Garden","Graveheart"],
	["Cinder Gate","Ashen Font","Chainwalk","Iron Seal","Furnace Court","Crown of Embers"]
]
const PACKS := [
	["raider","raider","raider","raider","raider"],
	["raider","hexer","raider","raider"],
	["bulwark","hexer","raider","raider","raider"],
	["elite","raider","raider","hexer"],
	["hexer","bulwark","hexer","raider","raider"],
	["boss","raider","hexer"]
]

static func region(floor_value: int) -> int:
	return clampi((floor_value-1)/10,0,3)

static func center(region_id: int, stage: int) -> Vector2:
	return ROUTES[clampi(region_id,0,3)][clampi(stage,0,5)]

static func room_name(region_id: int, stage: int) -> String:
	return NAMES[clampi(region_id,0,3)][clampi(stage,0,5)]

static func travel_points(region_id: int, stage: int, approach: float) -> Array:
	var target := center(region_id,stage)
	if stage==0: return [target+Vector2(0,approach)]
	var previous := center(region_id,stage-1)
	var middle := (previous.y+target.y)*0.5
	return [previous,Vector2(previous.x,middle),Vector2(target.x,middle),target+Vector2(0,approach)]

static func floor_rects(region_id: int) -> Array[Rect2]:
	var result: Array[Rect2]=[Rect2(-2.2,0,4.4,8.5)]
	for stage in range(6):
		var current := center(region_id,stage)
		result.append(Rect2(current-ROOM_HALF,ROOM_HALF*2.0))
		if stage==0: continue
		var points := travel_points(region_id,stage,0.0)
		for i in range(points.size()-1):
			var first: Vector2=points[i]
			var last: Vector2=points[i+1]
			result.append(Rect2(first.min(last)-Vector2.ONE*HALL_HALF,abs(last-first)+Vector2.ONE*HALL_HALF*2.0))
	return result

static func contains(region_id: int, point: Vector2) -> bool:
	for rect in floor_rects(region_id):
		if rect.grow(0.001).has_point(point): return true
	return false

static func combat_point(region_id: int, stage: int, point: Vector2) -> Vector2:
	var origin := center(region_id,stage)
	return point.clamp(origin-ROOM_HALF+Vector2.ONE*0.3,origin+ROOM_HALF-Vector2.ONE*0.3)

static func objective(stage: int) -> String:
	match stage:
		1: return "Restore Life at the well"
		3: return "Break the seal to open the sanctum"
		5: return "Defeat the guardian • claim the reliquary"
		_: return "Clear the chamber and follow the passage"

static func interact_name(stage: int) -> String:
	match stage:
		1: return "Drinking from the well"
		3: return "Breaking the sanctum seal"
		5: return "Opening the guardian's reliquary"
		_: return "Collecting spoils"

static func interact_point(region_id: int, stage: int) -> Vector2:
	return center(region_id,stage)+Vector2(-3.8,-2.5)
