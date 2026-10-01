extends RefCounted
## Shared floor plan for simulation, scenery and the expedition map.
const VARIANT_COUNT := 256
const LEGACY_VARIANT_COUNT := 64
const PROCEDURAL_SEED_MARKER := 1000000000
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
const PACK_OPTIONS := [
	[
		["raider","raider","raider","raider","raider"],
		["raider","raider","raider","raider","hexer"],
		["raider","raider","hexer","raider","hexer"]
	],
	[
		["raider","hexer","raider","raider"],
		["raider","raider","hexer","raider"],
		["raider","hexer","bulwark","raider"]
	],
	[
		["bulwark","hexer","raider","raider","raider"],
		["bulwark","hexer","raider","hexer","raider"],
		["bulwark","hexer","raider","raider","hexer"]
	],
	[
		["elite","raider","raider","hexer"],
		["elite","raider","raider","raider"],
		["elite","hexer","raider","hexer"]
	],
	[
		["hexer","bulwark","hexer","raider","raider"],
		["hexer","bulwark","raider","raider","raider"],
		["hexer","bulwark","hexer","hexer","raider"]
	],
	[
		["boss","raider","hexer"],
		["boss","raider","raider"],
		["boss","hexer","hexer"]
	]
]
const PACK_OPTIONS_PROCEDURAL := [
	[
		["raider","raider","raider","raider","raider"],
		["raider","raider","raider","raider","hexer"],
		["raider","raider","hexer","raider","hexer"],
		["bulwark","raider","raider","raider","raider"],
		["bulwark","raider","raider","hexer","raider"]
	],
	[
		["raider","hexer","raider","raider"],
		["raider","raider","hexer","raider"],
		["raider","hexer","bulwark","raider"],
		["hexer","hexer","raider","raider"],
		["bulwark","raider","hexer","raider"]
	],
	[
		["bulwark","hexer","raider","raider","raider"],
		["bulwark","hexer","raider","hexer","raider"],
		["bulwark","hexer","raider","raider","hexer"],
		["bulwark","bulwark","raider","hexer","raider"],
		["bulwark","hexer","hexer","raider","raider"]
	],
	[
		["elite","raider","raider","hexer"],
		["elite","raider","raider","raider"],
		["elite","hexer","raider","hexer"],
		["elite","bulwark","raider","raider"],
		["elite","hexer","hexer","raider"]
	],
	[
		["hexer","bulwark","hexer","raider","raider"],
		["hexer","bulwark","raider","raider","raider"],
		["hexer","bulwark","hexer","hexer","raider"],
		["bulwark","bulwark","hexer","raider","raider"],
		["hexer","raider","raider","raider","hexer"]
	],
	[
		["boss","raider","hexer"],
		["boss","raider","raider"],
		["boss","hexer","hexer"],
		["boss","bulwark","raider"],
		["boss","bulwark","hexer"]
	]
]
const SPAWN_OFFSETS := [
	Vector2(-2.8,-1.4),Vector2(-1.2,-2.8),Vector2(0.4,-2.4),Vector2(2.4,-2.5),
	Vector2(2.9,-0.6),Vector2(2.2,1.4),Vector2(0.5,2.7),Vector2(-1.6,2.6),
	Vector2(-2.9,1.0),Vector2(-0.5,0.2),Vector2(1.1,0.1),Vector2(-1.8,-0.2)
]

static func region(floor_value: int) -> int:
	return clampi((floor_value-1)/10,0,3)

static func variant_seed(run_seed: int, floor_id: int) -> int:
	# Retain the original seed mapping for in-progress saves from older builds.
	return posmod(run_seed,LEGACY_VARIANT_COUNT)+maxi(1,floor_id)*4099

static func procedural_seed(run_seed: int, floor_id: int) -> int:
	# A marked 256-pattern bank lets newer runs use richer layouts while old
	# checkpoints continue resolving against their original 64-pattern bank.
	return PROCEDURAL_SEED_MARKER+posmod(run_seed,VARIANT_COUNT)+maxi(1,floor_id)*4099

static func _is_procedural(seed_value: int) -> bool:
	return seed_value>=PROCEDURAL_SEED_MARKER

static func _random(seed_value: int, region_id: int, salt: int) -> RandomNumberGenerator:
	var result := RandomNumberGenerator.new()
	var normalized_seed := seed_value-PROCEDURAL_SEED_MARKER if _is_procedural(seed_value) else seed_value
	result.seed = normalized_seed+(clampi(region_id,0,3)+1)*1000003+salt*9176
	return result

static func route(region_id: int, seed_value: int = 0) -> Array:
	var selected_region := clampi(region_id,0,3)
	var result: Array = ROUTES[selected_region].duplicate()
	if seed_value==0: return result
	var random := _random(seed_value,selected_region,11)
	var procedural := _is_procedural(seed_value)
	var route_style := random.randi_range(0,ROUTES.size()-1) if procedural else selected_region
	for room in range(1,5):
		var anchor: Vector2=ROUTES[selected_region][room]
		if procedural: anchor=anchor.lerp(ROUTES[route_style][room],0.72)
		var x := clampf(anchor.x+random.randf_range(-4.8 if procedural else -4.0,4.8 if procedural else 4.0),-8.5,8.5)
		var y := anchor.y+random.randf_range(-2.6 if procedural else -2.2,2.6 if procedural else 2.2)
		result[room]=Vector2(x,y)
	return result

static func packs(region_id: int, seed_value: int = 0) -> Array:
	if seed_value==0: return PACKS.duplicate(true)
	var random := _random(seed_value,region_id,23)
	var result: Array=[]
	var choices_by_room: Array=PACK_OPTIONS_PROCEDURAL if _is_procedural(seed_value) else PACK_OPTIONS
	for room in range(choices_by_room.size()):
		var choices: Array=choices_by_room[room]
		var selected: Array=choices[random.randi_range(0,choices.size()-1)].duplicate()
		var first := 1 if room==5 else 0
		for i in range(selected.size()-1,first,-1):
			var other := random.randi_range(first,i)
			var saved = selected[i]
			selected[i]=selected[other]
			selected[other]=saved
		result.append(selected)
	return result

static func spawn_points(region_id: int, stage: int, count: int, seed_value: int = 0) -> Array:
	var origin := center(region_id,stage,seed_value)
	var selected: Array=SPAWN_OFFSETS.duplicate()
	var procedural := _is_procedural(seed_value)
	var random := _random(seed_value,region_id,101+stage)
	if seed_value!=0:
		for i in range(selected.size()-1,0,-1):
			var other := random.randi_range(0,i)
			var saved = selected[i]
			selected[i]=selected[other]
			selected[other]=saved
	var formation_angle := random.randf_range(-PI,PI) if procedural else 0.0
	var result: Array=[]
	for slot in range(mini(count,selected.size())):
		var point: Vector2=origin+Vector2(selected[slot])
		if procedural:
			var rotated_point := origin+(point-origin).rotated(formation_angle)
			point=rotated_point
			for attempt in range(8):
				var candidate := rotated_point+Vector2(random.randf_range(-0.32,0.32),random.randf_range(-0.28,0.28))
				var spaced := true
				for placed in result:
					if candidate.distance_to(placed)<0.9:
						spaced=false
						break
				if spaced:
					point=candidate
					break
			point=point.clamp(origin-ROOM_HALF+Vector2.ONE*0.45,origin+ROOM_HALF-Vector2.ONE*0.45)
		result.append(point)
	return result

static func center(region_id: int, stage: int, seed_value: int = 0) -> Vector2:
	var route_points := route(region_id,seed_value)
	return route_points[clampi(stage,0,5)]

static func room_name(region_id: int, stage: int) -> String:
	return NAMES[clampi(region_id,0,3)][clampi(stage,0,5)]

static func travel_points(region_id: int, stage: int, approach: float, seed_value: int = 0, movement_seed: int = 0, wandering_route: bool = false, exploration_route: bool = false, expanded_exploration_route: bool = true) -> Array:
	var target := center(region_id,stage,seed_value)
	if stage==0: return [target+Vector2(0,approach)]
	var previous := center(region_id,stage-1,seed_value)
	var turn_fraction := 0.5
	if movement_seed!=0:
		# The shared pattern seed keeps watched, skipped and AFK paths identical.
		var movement_rng := RandomNumberGenerator.new()
		movement_rng.seed = movement_seed+(clampi(region_id,0,3)+1)*1000003+(211+stage)*9176
		if exploration_route:
			var exploration_end_y := target.y+approach
			var route_style_max := 3 if expanded_exploration_route else 1
			var route_style := movement_rng.randi_range(0,route_style_max)
			if route_style==0:
				# Two changing lanes create a longer, visibly different corridor
				# route while keeping both ends aligned with the generated rooms.
				var wide_first_y := lerpf(previous.y,exploration_end_y,movement_rng.randf_range(0.12,0.26))
				var wide_second_y := lerpf(previous.y,exploration_end_y,movement_rng.randf_range(0.36,0.58))
				var wide_third_y := lerpf(previous.y,exploration_end_y,movement_rng.randf_range(0.68,0.86))
				var lane_a := clampf(lerpf(previous.x,target.x,movement_rng.randf_range(0.22,0.42))+movement_rng.randf_range(-0.7,0.7),-9.5,9.5)
				var lane_b := clampf(lerpf(previous.x,target.x,movement_rng.randf_range(0.58,0.82))+movement_rng.randf_range(-0.7,0.7),-9.5,9.5)
				if absf(lane_b-lane_a)<0.65: lane_b=clampf(lane_a+(1.0 if lane_b>=lane_a else -1.0)*0.9,-9.5,9.5)
				return [previous,Vector2(previous.x,wide_first_y),Vector2(lane_a,wide_first_y),Vector2(lane_a,wide_second_y),Vector2(lane_b,wide_second_y),Vector2(lane_b,wide_third_y),Vector2(target.x,wide_third_y),target+Vector2(0,approach)]
			if route_style==1:
				# Some seeds send the hero through a short side passage before
				# rejoining the main corridor. It is a real walkable detour, not a
				# camera-only flourish.
				var detour_start_y := lerpf(previous.y,exploration_end_y,movement_rng.randf_range(0.18,0.35))
				var detour_end_y := lerpf(previous.y,exploration_end_y,movement_rng.randf_range(0.62,0.82))
				var detour_lane_x := clampf(lerpf(previous.x,target.x,movement_rng.randf_range(0.30,0.70))+movement_rng.randf_range(-0.9,0.9),-9.5,9.5)
				var detour_y := lerpf(detour_start_y,detour_end_y,movement_rng.randf_range(0.35,0.65))
				var detour_side := -1.0 if movement_rng.randf()<0.5 else 1.0
				var detour_x := clampf(detour_lane_x+detour_side*movement_rng.randf_range(1.0,1.55),-10.0,10.0)
				return [previous,Vector2(previous.x,detour_start_y),Vector2(detour_lane_x,detour_start_y),Vector2(detour_lane_x,detour_y),Vector2(detour_x,detour_y),Vector2(detour_lane_x,detour_y),Vector2(detour_lane_x,detour_end_y),Vector2(target.x,detour_end_y),target+Vector2(0,approach)]
			if route_style==2:
				# A broad sweep changes lanes once through the corridor. Both turns
				# remain inside the generated floor and meet the same room anchors.
				var sweep_start_y := lerpf(previous.y,exploration_end_y,movement_rng.randf_range(0.16,0.30))
				var sweep_finish_y := lerpf(previous.y,exploration_end_y,movement_rng.randf_range(0.68,0.84))
				var sweep_fraction := movement_rng.randf_range(0.32,0.68)
				var sweep_side := -1.0 if movement_rng.randf()<0.5 else 1.0
				var sweep_lane_a := clampf(lerpf(previous.x,target.x,sweep_fraction)+sweep_side*movement_rng.randf_range(0.8,1.5),-9.5,9.5)
				var sweep_lane_b := clampf(sweep_lane_a+sweep_side*movement_rng.randf_range(1.0,1.7),-10.0,10.0)
				var sweep_mid_y := lerpf(sweep_start_y,sweep_finish_y,movement_rng.randf_range(0.42,0.58))
				return [previous,Vector2(previous.x,sweep_start_y),Vector2(sweep_lane_a,sweep_start_y),Vector2(sweep_lane_a,sweep_mid_y),Vector2(sweep_lane_b,sweep_mid_y),Vector2(sweep_lane_b,sweep_finish_y),Vector2(target.x,sweep_finish_y),target+Vector2(0,approach)]
			# A three-turn path creates a longer zig-zag with bounded lateral
			# movement. The seed chooses lane positions independently per corridor.
			var zig_start_y := lerpf(previous.y,exploration_end_y,movement_rng.randf_range(0.14,0.27))
			var zig_middle_y := lerpf(previous.y,exploration_end_y,movement_rng.randf_range(0.40,0.57))
			var zig_finish_y := lerpf(previous.y,exploration_end_y,movement_rng.randf_range(0.72,0.86))
			var zig_lane_a := clampf(lerpf(previous.x,target.x,movement_rng.randf_range(0.18,0.36))+movement_rng.randf_range(-1.1,1.1),-9.5,9.5)
			var zig_lane_b := clampf(lerpf(previous.x,target.x,movement_rng.randf_range(0.40,0.62))+movement_rng.randf_range(-1.3,1.3),-9.5,9.5)
			var zig_lane_c := clampf(lerpf(previous.x,target.x,movement_rng.randf_range(0.66,0.84))+movement_rng.randf_range(-1.1,1.1),-9.5,9.5)
			if absf(zig_lane_b-zig_lane_a)<0.7: zig_lane_b=clampf(zig_lane_a+(1.0 if zig_lane_b>=zig_lane_a else -1.0)*1.0,-9.5,9.5)
			if absf(zig_lane_c-zig_lane_b)<0.7: zig_lane_c=clampf(zig_lane_b+(1.0 if zig_lane_c>=zig_lane_b else -1.0)*1.0,-9.5,9.5)
			return [previous,Vector2(previous.x,zig_start_y),Vector2(zig_lane_a,zig_start_y),Vector2(zig_lane_a,zig_middle_y),Vector2(zig_lane_b,zig_middle_y),Vector2(zig_lane_b,zig_finish_y),Vector2(zig_lane_c,zig_finish_y),Vector2(zig_lane_c,lerpf(zig_finish_y,exploration_end_y,0.72)),Vector2(target.x,lerpf(zig_finish_y,exploration_end_y,0.72)),target+Vector2(0,approach)]
		if wandering_route:
			# Two seed-bound turns create a short S-bend inside the same generated
			# passage. The center lane stays between the room anchors, with a small
			# shoulder variation for nearly vertical corridors.
			var s_bend_end_y := target.y+approach
			var s_bend_start_y := lerpf(previous.y,s_bend_end_y,movement_rng.randf_range(0.18,0.35))
			var s_bend_finish_y := lerpf(previous.y,s_bend_end_y,movement_rng.randf_range(0.62,0.82))
			var legacy_lane_x := lerpf(previous.x,target.x,movement_rng.randf_range(0.24,0.76))+movement_rng.randf_range(-0.75,0.75)
			return [previous,Vector2(previous.x,s_bend_start_y),Vector2(legacy_lane_x,s_bend_start_y),Vector2(legacy_lane_x,s_bend_finish_y),Vector2(target.x,s_bend_finish_y),target+Vector2(0,approach)]
		# Version-1 checkpoints retain their original single-bend route.
		var vertical_gap:=maxf(0.1,previous.y-target.y)
		var latest_safe_turn:=clampf(1.0-approach/vertical_gap-0.08,0.22,0.72)
		turn_fraction=movement_rng.randf_range(0.12,latest_safe_turn)
	var middle := lerpf(previous.y,target.y,turn_fraction)
	return [previous,Vector2(previous.x,middle),Vector2(target.x,middle),target+Vector2(0,approach)]

static func floor_rects(region_id: int, seed_value: int = 0, movement_seed: int = 0, wandering_route: bool = false, exploration_route: bool = false, expanded_exploration_route: bool = true) -> Array[Rect2]:
	var result: Array[Rect2]=[Rect2(-2.2,0,4.4,8.5)]
	for stage in range(6):
		var current := center(region_id,stage,seed_value)
		result.append(Rect2(current-ROOM_HALF,ROOM_HALF*2.0))
		if stage==0: continue
		var approaches: Array=[0.0] if movement_seed==0 else [2.1,4.4]
		for approach in approaches:
			var points := travel_points(region_id,stage,float(approach),seed_value,movement_seed,wandering_route,exploration_route,expanded_exploration_route)
			for i in range(points.size()-1):
				var first: Vector2=points[i]
				var last: Vector2=points[i+1]
				result.append(Rect2(first.min(last)-Vector2.ONE*HALL_HALF,abs(last-first)+Vector2.ONE*HALL_HALF*2.0))
	return result

static func contains(region_id: int, point: Vector2, seed_value: int = 0, movement_seed: int = 0, wandering_route: bool = false, exploration_route: bool = false, expanded_exploration_route: bool = true) -> bool:
	for rect in floor_rects(region_id,seed_value,movement_seed,wandering_route,exploration_route,expanded_exploration_route):
		if rect.grow(0.001).has_point(point): return true
	return false

static func combat_point(region_id: int, stage: int, point: Vector2, seed_value: int = 0) -> Vector2:
	var origin := center(region_id,stage,seed_value)
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

static func interact_point(region_id: int, stage: int, seed_value: int = 0) -> Vector2:
	return center(region_id,stage,seed_value)+Vector2(-3.8,-2.5)
