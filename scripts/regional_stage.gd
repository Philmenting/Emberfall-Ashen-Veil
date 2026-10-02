extends RefCounted
## Low live masonry joins the painted horizon to the authoritative walking floor.
## Monumental arches/stacks/ribs/crown are authored in the four region paintings;
## a second set of tall foreground primitives would hide the actual combat.
const Layout=preload("res://scripts/dungeon_layout.gd")

static func build(world) -> void:
	for room in range(6):
		world.dressing_room=room
		var origin: Vector3=world._point(Layout.center(world.region_index,room,world.simulation.layout_seed())) if world.simulation.uses_journey() else Vector3(0,0,4-room*11.2)
		# These lower, unreachable masonry courses are scenery, never extra floor
		# or collision space. Their painted surface shares the visible pavers.
		world._box(origin+Vector3(0,-0.38,0),Vector3(12.0,0.34,10.0),world.floor_materials[3])
		for side in [-1.0,1.0]:
			world._box(origin+Vector3(side*6.15,-0.48,0),Vector3(0.55,0.25,9.8),world.floor_materials[4])
			for fragment in range(6):
				var chip: MeshInstance3D=world._box(origin+Vector3(side*(5.95+float(fragment%2)*0.12),0.04,-3.7+float(fragment)*1.4),Vector3(0.32,0.16,0.50),world.floor_materials[fragment%5])
				chip.rotation.y=float(fragment)*0.71
		if room==5:
			var disc: MeshInstance3D=world._cylinder(origin+Vector3(0,0.005,0),4.7,4.7,0.055,world.floor_materials[1],64)
			disc.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			for radius in [3.3,4.55]:
				world._ring(origin+Vector3(0,0.045,0),radius,world.materials.metal)
			# Permanent bronze inlays remain quiet beside active amber warnings.
			for spoke in range(12):
				var angle: float=spoke*TAU/12.0
				var inlay: MeshInstance3D=world._box(origin+Vector3(sin(angle)*3.95,0.037,cos(angle)*3.95),Vector3(0.04,0.012,0.88),world.materials.metal)
				inlay.rotation.y=angle
				inlay.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.dressing_room=-1
