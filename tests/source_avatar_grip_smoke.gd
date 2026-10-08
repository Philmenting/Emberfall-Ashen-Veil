extends SceneTree
## Test the visible hand and handle, rather than the continuity of a socket.
## Every used arm vertex keeps all four original skin influences. Contact is
## measured against indexed, actually posed triangles in the hand's frame.
const Actor = preload("res://scripts/dungeon_actor.gd")
const SourceRig = preload("res://scripts/source_avatar_rig.gd")
const DIGITS = ["hand", "thumb", "index", "middle", "ring", "pinky"]
const AXIAL_BAND = .055
const CONTACT_GAP = .003
const MAX_PENETRATION = .001
var checks = 0
var poses = 0
var failures: Array[String] = []
var arm_surfaces: Array[Dictionary] = []
var worst_penetration = 0.0
var widest_finger_gap = 0.0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func digit_for(name: String) -> int:
	if name == "hand_r":
		return 0
	if not name.ends_with("_r"):
		return -1
	return DIGITS.find(name.split("_")[0])

func cache_actual_arm(rig: RefCounted) -> void:
	arm_surfaces.clear()
	for surface in rig.surfaces:
		if not String(surface.name).contains("Arms"):
			continue
		for slot in surface.mesh.get_surface_count():
			var arrays = surface.mesh.surface_get_arrays(slot)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var binds: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			check(weights.size() == vertices.size() * 4, "Actual arm retains four skin influences")
			var used = {}
			for index in indices:
				used[index] = true
			var probes: Array = []
			probes.resize(vertices.size())
			var scores: Array = []
			scores.resize(vertices.size())
			for index in used:
				var influences: Array = []
				var digit_weights: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
				for influence in 4:
					var weight = weights[index * 4 + influence]
					if weight <= 0.0:
						continue
					var bind = binds[index * 4 + influence]
					var name = surface.skin.get_bind_name(bind)
					var bone = rig.skeleton.find_bone(name) if name != &"" else surface.skin.get_bind_bone(bind)
					assert(bone >= 0, "An actual source skin bind must resolve")
					influences.append([bone, surface.skin.get_bind_pose(bind) * vertices[index], weight])
					var digit = digit_for(String(rig.skeleton.get_bone_name(bone)))
					if digit >= 0:
						digit_weights[digit] += weight
				probes[index] = influences
				scores[index] = digit_weights
			var triangle_digits = PackedInt32Array()
			for offset in range(0, indices.size(), 3):
				var best_digit = -1
				var best_weight = .45
				for digit in 6:
					var average = (scores[indices[offset]][digit] + scores[indices[offset + 1]][digit] + scores[indices[offset + 2]][digit]) / 3.0
					if average > best_weight:
						best_weight = average
						best_digit = digit
				triangle_digits.append(best_digit)
			arm_surfaces.append({"indices": indices, "probes": probes, "used": used, "triangle_digits": triangle_digits})
	check(not arm_surfaces.is_empty(), "Contact audit exercises the rendered source arm mesh")

func closest_projected_triangle(a: Vector2, b: Vector2, c: Vector2) -> Vector2:
	# Projected origin is the actual shaft axis. A triangle containing it means
	# the shaft traverses glove geometry, even if all its vertices miss the axis.
	var first = a.cross(b)
	var second = b.cross(c)
	var third = c.cross(a)
	var has_area = absf((b - a).cross(c - a)) > 1e-12
	if has_area and ((first >= 0.0 and second >= 0.0 and third >= 0.0) or (first <= 0.0 and second <= 0.0 and third <= 0.0)):
		return Vector2.ZERO
	var points: Array[Vector2] = [a, b, c]
	var closest = a
	for edge in 3:
		var start = points[edge]
		var direction = points[(edge + 1) % 3] - start
		var amount = clampf(-start.dot(direction) / maxf(direction.length_squared(), 1e-18), 0.0, 1.0)
		var candidate = start + direction * amount
		if candidate.length_squared() < closest.length_squared():
			closest = candidate
	return closest

func audit_pose(actor: Node3D, label: String) -> void:
	poses += 1
	var rig = actor.motion_rig
	var skeleton: Skeleton3D = rig.skeleton
	var hand = skeleton.get_bone_global_pose(skeleton.find_bone("hand_r"))
	var hand_inverse = hand.affine_inverse()
	var origin: Vector3 = hand_inverse * (rig.weapon.transform * SourceRig.STAFF_GRIP)
	var axis: Vector3 = (hand_inverse.basis * (rig.weapon.basis * Vector3.UP)).normalized()
	var world_axis: Vector3 = (actor.body.global_basis * rig.motion_node.basis * rig.weapon.basis * Vector3.UP).normalized()
	check(world_axis.dot(Vector3.UP) >= .98, label + ": staff remains upright in the actual support hand")
	var horizontal = axis.cross(Vector3.RIGHT).normalized()
	var vertical = axis.cross(horizontal).normalized()
	var minima: Array[float] = [INF, INF, INF, INF, INF, INF]
	var directions: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
	var all_arm_minimum = INF
	var considered_triangles = 0
	for record in arm_surfaces:
		var vertices = PackedVector3Array()
		vertices.resize(record.probes.size())
		for index in record.used:
			var point = Vector3.ZERO
			for influence in record.probes[index]:
				point += (skeleton.get_bone_global_pose(influence[0]) * influence[1]) * influence[2]
			assert(point.is_finite(), "Actually weighted grip geometry remains finite")
			vertices[index] = hand_inverse * point
		var indices: PackedInt32Array = record.indices
		for offset in range(0, indices.size(), 3):
			var a = vertices[indices[offset]] - origin
			var b = vertices[indices[offset + 1]] - origin
			var c = vertices[indices[offset + 2]] - origin
			var axial_a = a.dot(axis)
			var axial_b = b.dot(axis)
			var axial_c = c.dot(axis)
			if minf(axial_a, minf(axial_b, axial_c)) > AXIAL_BAND or maxf(axial_a, maxf(axial_b, axial_c)) < -AXIAL_BAND:
				continue
			var polygon: Array[Vector3] = [a, b, c]
			polygon = clip_axial_polygon(polygon, Vector3.ZERO, axis, AXIAL_BAND, true)
			polygon = clip_axial_polygon(polygon, Vector3.ZERO, axis, -AXIAL_BAND, false)
			if polygon.size() < 3:
				continue
			considered_triangles += 1
			var closest = Vector2(INF, INF)
			for corner in range(1, polygon.size() - 1):
				var first = polygon[0]
				var second = polygon[corner]
				var third = polygon[corner + 1]
				var candidate = closest_projected_triangle(Vector2(first.dot(horizontal), first.dot(vertical)), Vector2(second.dot(horizontal), second.dot(vertical)), Vector2(third.dot(horizontal), third.dot(vertical)))
				if candidate.length_squared() < closest.length_squared():
					closest = candidate
			var distance = closest.length()
			# Every arm triangle contributes to clearance, including mixed-bind
			# triangles that cannot be assigned to one dominant digit.
			all_arm_minimum = minf(all_arm_minimum, distance)
			var digit: int = record.triangle_digits[offset / 3]
			if digit >= 0 and distance < minima[digit]:
				minima[digit] = distance
				directions[digit] = (horizontal * closest.x + vertical * closest.y).normalized()
	var penetration = maxf(0.0, SourceRig.GRIP_RADIUS - all_arm_minimum)
	worst_penetration = maxf(worst_penetration, penetration)
	check(considered_triangles > 100 and is_finite(all_arm_minimum), label + ": clearance uses actual indexed arm triangles")
	check(penetration <= MAX_PENETRATION, label + ": whole arm avoids shaft penetration beyond 1 mm; measured " + str(penetration))
	check(is_finite(minima[1]) and minima[1] <= SourceRig.GRIP_RADIUS + CONTACT_GAP, label + ": actual thumb touches the handle within 3 mm")
	var finger_contacts = 0
	var opposed_contacts = 0
	for digit in range(2, 6):
		var gap = maxf(0.0, minima[digit] - SourceRig.GRIP_RADIUS)
		widest_finger_gap = maxf(widest_finger_gap, gap)
		if is_finite(minima[digit]) and gap <= CONTACT_GAP:
			finger_contacts += 1
			if directions[1].dot(directions[digit]) < -.5:
				opposed_contacts += 1
	check(finger_contacts >= 3, label + ": at least three actual fingers contact the handle within 3 mm")
	check(opposed_contacts >= 3, label + ": thumb opposes at least three finger contacts around the shaft")
	check(is_finite(minima[0]) and minima[0] >= SourceRig.GRIP_RADIUS - MAX_PENETRATION and minima[0] <= SourceRig.GRIP_RADIUS + .014, label + ": palm stays clear and within 14 mm of the supported shaft")

func clip_axial_polygon(points: Array[Vector3], origin: Vector3, axis: Vector3, limit: float, keep_less: bool) -> Array[Vector3]:
	var result: Array[Vector3] = []
	if points.is_empty():
		return result
	var previous = points[-1]
	var previous_distance = (previous - origin).dot(axis) - limit
	var previous_inside = previous_distance <= 0.0 if keep_less else previous_distance >= 0.0
	for point in points:
		var distance = (point - origin).dot(axis) - limit
		var inside = distance <= 0.0 if keep_less else distance >= 0.0
		if inside != previous_inside:
			result.append(previous.lerp(point, previous_distance / (previous_distance - distance)))
		if inside:
			result.append(point)
		previous = point
		previous_distance = distance
		previous_inside = inside
	return result

func audit_actual_handle_mesh(rig: RefCounted) -> void:
	# Audit the real prop in the span occupied by the fingers. This prevents a
	# nominal 18 mm constant from concealing a thicker rendered handle or rings.
	var origin: Vector3 = rig.weapon.transform * SourceRig.STAFF_GRIP
	var axis: Vector3 = (rig.weapon.basis * Vector3.UP).normalized()
	var minimum_radius = INF
	var maximum_radius = 0.0
	var points_checked = 0
	for part in rig.weapon.get_children():
		if not part is MeshInstance3D:
			continue
		for slot in part.mesh.get_surface_count():
			var arrays = part.mesh.surface_get_arrays(slot)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			for offset in range(0, indices.size(), 3):
				var polygon: Array[Vector3] = []
				for corner in 3:
					polygon.append(rig.weapon.transform * (part.transform * vertices[indices[offset + corner]]))
				polygon = clip_axial_polygon(polygon, origin, axis, .045, true)
				polygon = clip_axial_polygon(polygon, origin, axis, -.045, false)
				for point in polygon:
					var displacement = point - origin
					var radius = (displacement - axis * displacement.dot(axis)).length()
					minimum_radius = minf(minimum_radius, radius)
					maximum_radius = maxf(maximum_radius, radius)
					points_checked += 1
	check(points_checked >= 24, "Radius audit intersects the rendered handle mesh across the finger span")
	check(minimum_radius >= SourceRig.GRIP_RADIUS - .001 and maximum_radius <= SourceRig.GRIP_RADIUS + .0005, "Actual handle geometry fits the 18 mm contact cylinder; radii " + str(minimum_radius) + " to " + str(maximum_radius))
	check(is_equal_approx(rig.weapon.basis.get_scale().y, SourceRig.STAFF_SCALE), "Staff preserves its intended longitudinal scale")

func make_actor() -> Node3D:
	var actor = Actor.new()
	actor.kind = "Arcanist"
	root.add_child(actor)
	check(actor.source_avatar and actor.motion_rig.build_ok, "Grip fixture uses the production authored Arcanist")
	cache_actual_arm(actor.motion_rig)
	return actor

func actual_grip_world(actor: Node3D) -> Vector3:
	return actor.body.to_global(actor.motion_rig.motion_node.transform * (actor.motion_rig.weapon.transform * SourceRig.STAFF_GRIP))

func run() -> void:
	var actor = make_actor()
	audit_actual_handle_mesh(actor.motion_rig)
	var phases = [["idle", 0.0], ["idle", .7], ["walk", 0.0], ["walk", .25], ["walk", .5], ["walk", .75], ["windup_basic", .25], ["windup_basic", .65], ["windup_basic", 1.0], ["recover_basic", 0.0], ["recover_basic", .14], ["recover_basic", .34], ["windup_heavy", .65], ["recover_heavy", .14]]
	for phase in phases:
		actor.motion_rig.pose(phase[0], phase[1])
		actor.motion_rig.apply_actor_postprocess(actor, phase[0], phase[1], 0.0, true)
		audit_pose(actor, "Direct " + phase[0] + " " + str(phase[1]))
	actor.free()
	# A fresh production actor exercises the actual _apply_motion transitions,
	# not only the final pose. Every step remains at the ordinary 60 Hz delta.
	actor = make_actor()
	for frame in range(1, 13):
		var displacement = Vector3(0, 0, -2.0 / 60.0)
		actor.position += displacement
		actor.follow_travel(displacement)
		actor.animate(1.0 / 60.0, true, 2.0)
		if frame in [1, 2, 4, 6, 9, 12]:
			audit_pose(actor, "Actual walk blend frame " + str(frame))
	for frame in range(1, 13):
		actor.animate(1.0 / 60.0, false)
		if frame in [1, 3, 6, 12]:
			audit_pose(actor, "Actual stop blend frame " + str(frame))
	actor.animate(.4, false)
	for style in ["basic", "signature"]:
		actor.strike(style, .30, true)
		for frame in range(1, 14):
			actor.sync_attack(.30 - float(frame) / 60.0)
			actor.animate(1.0 / 60.0, false)
			if (style == "basic" and frame in [1, 3, 6, 9, 13]) or (style == "signature" and frame in [1, 6, 13]):
				audit_pose(actor, "Actual " + style + " windup frame " + str(frame))
		var tip_before: Vector3 = actor.weapon_world_position()
		var grip_before = actual_grip_world(actor)
		check(actor.release_time < 0.0, style + ": renderer preserves simulation authority before release")
		check(actor.release_attack(), style + ": real simulation release is accepted")
		check(grip_before.distance_to(actual_grip_world(actor)) < .025 and tip_before.distance_to(actor.weapon_world_position()) < .025, style + ": actual handle and staff tip remain continuous at early release")
		audit_pose(actor, "Actual " + style + " release contact")
		for frame in range(1, 25):
			actor.animate(1.0 / 60.0, false)
			if style == "basic" and frame in [1, 2, 5, 9, 15, 21]:
				audit_pose(actor, "Actual recovery blend frame " + str(frame))
	check(poses == 40, "Exactly 40 direct and actual transition poses exercise visible grip geometry")
	print("SOURCE AVATAR GRIP: ", checks, " checks, ", poses, " actual poses, ", failures.size(), " failures")
	print("Maximum actual arm/shaft penetration: ", worst_penetration, " m; maximum finger gap: ", widest_finger_gap, " m")
	actor.free()
	quit(0 if failures.is_empty() else 1)
