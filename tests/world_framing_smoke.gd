extends SceneTree
## Project real phase outlines through the native camera at all shipped layouts.
## These are geometry/layout fixtures, not phone performance measurements.
const Sim=preload("res://scripts/expedition_simulation.gd")
const World=preload("res://scripts/dungeon_world.gd")
const Bot=preload("res://tests/balance_survey_bot.gd")
const Patterns=preload("res://scripts/boss_patterns.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run_checks")
func check(value: bool, label: String) -> void:
	checks+=1
	if value: print("PASS: ",label)
	else: failures+=1; push_error("FAIL: "+label)
func run_checks() -> void:
	var game:=Bot.new()
	game.character_class="Arcanist"
	for size in [Vector2i(2424,1080),Vector2i(1040,1080),Vector2i(854,480)]:
		root.size=size
		await process_frame
		var logical_size:=root.get_visible_rect().size
		# Include the permanent skill row plus controls and large-text spacing.
		var readout_edge:=1.0-146.0/logical_size.y
		for class_key in ["Vowkeeper","Arcanist","Ranger"]:
			game.character_class=class_key
			for region in range(4):
				var stats: Dictionary=game._combat_stats()
				stats.max_hp=100000
				# Late-region geometry fixture, never a balance/marketing capture.
				stats.attack=5000; stats.ability_damage=5000
				stats.boss_phases=1
				var sim:=Sim.new()
				sim.setup(class_key,stats,region*10+1,"Guardian",1979)
				# Keep the guardian alive long enough to inspect every real warning.
				var fixture_guardian: Dictionary=sim.enemy_by_id(50)
				fixture_guardian.hp=1000000; fixture_guardian.max_hp=1000000
				while not sim.finished:
					sim.advance(0.1)
					if sim.stage==5 and not sim.enemy_by_id(50).warning.is_empty(): break
				check(not sim.finished,"region %d: framing fixture reaches a real guardian" % region)
				if sim.finished: continue
				var boss: Dictionary=sim.enemy_by_id(50)
				var world:=World.new()
				world.simulation=sim; world.region_index=region
				world.character_class=class_key; world.active=false
				world.hud_bottom_ratio=readout_edge-0.02
				root.add_child(world)
				for phase in range(3):
					for variant in range(2):
						boss.warning=Patterns.create_phased(region,boss.pos,sim.hero_pos,phase,variant)
						var guardian: Node3D=world.actor_by_id[50]
						guardian.set_telegraph(1.5); guardian.set_telegraph(.3); guardian.animate(0,false)
						world.hero.cancel_attack(); world.hero.attack_time=-1; world.hero.release_time=-1
						world.hero.strike("basic",.3,true); world.hero.sync_attack(.09); world.hero.animate(0,false)
						var before:=sim.encode_snapshot()
						world._position_camera()
						var visible:=true
						for zone in boss.warning.zones:
							for outline in Patterns.outlines(zone):
								for point in outline:
									var screen: Vector2=world.camera.unproject_position(Vector3(point.x,0,point.y))/logical_size
									visible=visible and screen.x>=0.065 and screen.x<=0.935 and screen.y>=0.15 and screen.y<=readout_edge
						check(visible,"%dx%d region %d phase %d variant %d: complete collision outline stays inside the quiet play area" % [size.x,size.y,region,phase,variant])
						var figures_clear:=true
						var top_margin:=0.235 if logical_size.x/logical_size.y>1.3 else 0.145
						for point in world._framing_points():
							var screen: Vector2=world.camera.unproject_position(point)/logical_size
							figures_clear=figures_clear and screen.x>=0.065 and screen.x<=0.935 and screen.y>=top_margin and screen.y<=readout_edge
						check(figures_clear,"actual complete figure and raised weapon bounds clear the HUD as well as the warning" )
						check(sim.encode_snapshot()==before,"camera framing never changes simulation, warning geometry or RNG")
						guardian.strike("heavy"); world.hero.release_attack(); world._position_camera()
						var contact_clear:=true
						for point in world._framing_points():
							var screen: Vector2=world.camera.unproject_position(point)/logical_size
							contact_clear=contact_clear and screen.x>=.065 and screen.x<=.935 and screen.y>=top_margin and screen.y<=readout_edge
						check(contact_clear,class_key+": fully extended contact poses remain inside the quiet play area")
				world.free()
	game.free()
	print("WORLD FRAMING SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
