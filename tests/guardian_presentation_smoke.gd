extends SceneTree
## Inspect real four-influence skin projection. This does not certify device FPS.
const Sim=preload("res://scripts/expedition_simulation.gd")
const World=preload("res://scripts/dungeon_world.gd")
const Bot=preload("res://tests/balance_survey_bot.gd")
const SkinAudit=preload("res://tests/source_avatar_skin.gd")
var checks:=0
var failures:=0
func _initialize() -> void: run_checks.call_deferred()
func check(value: bool,label: String) -> void:
	checks+=1
	if value: print("PASS: ",label)
	else: failures+=1; push_error("FAIL: "+label)

func project_bounds(world: Node3D,actor: Node3D,bounds: AABB) -> Dictionary:
	var low:=Vector2(INF,INF); var high:=Vector2(-INF,-INF)
	var far_depth:=0.0
	for x in [bounds.position.x,bounds.end.x]:
		for y in [bounds.position.y,bounds.end.y]:
			for z in [bounds.position.z,bounds.end.z]:
				var point:=actor.to_global(Vector3(x,y,z))
				var screen: Vector2=world.camera.unproject_position(point)
				low=low.min(screen); high=high.max(screen)
				far_depth=maxf(far_depth,-world.camera.to_local(point).z)
	return {"rect":Rect2(low,high-low),"far":far_depth}

func exercise_release_delivery(game: Node) -> void:
	for style in ["basic","signature","chain"]:
		for step_seconds in [1.0/60.0,.6,2.0]:
			var stats: Dictionary=game._combat_stats()
			stats.first_descent=1
			stats.skill_rotation=1 if style=="chain" else 0
			if style=="chain": stats.skill_loadout=["chain","frost_ward"]
			var sim:=Sim.new(); sim.setup("Arcanist",stats,1,"Guardian",1979)
			sim.skill_cd=0.0 if style=="signature" else 9.0
			var baseline:=Sim.new()
			check(baseline.restore(sim.snapshot()),"%s %.3fs: release regression starts from a structurally valid real first-descent checkpoint" % [style,step_seconds])
			var world: Node3D=World.new(); world.simulation=sim; world.character_class="Arcanist"; world.active=false
			root.add_child(world)
			world.set_process(false); world.active=true
			var presented: Array=[]
			var authority: Array=[]
			world.simulation_advanced.connect(func(events: Array): presented.append_array(events))
			var first_hit:=false
			for frame in range(90):
				world._process(step_seconds)
				authority.append_array(baseline.advance(step_seconds))
				for event in presented:
					if event.type=="hit": first_hit=true
				if first_hit: break
			var releases: Array=[]; var attacks: Array=[]; var hit_count:=0
			for event in presented:
				if event.type=="hero_release": releases.append(event)
				elif event.type=="hero_attack": attacks.append(event)
				elif event.type=="hit": hit_count+=1
			# Nova changes enemy slow and Nyra's real repositioning; a two-second
			# frame need not contain the same number of casts as an ordinary bolt.
			# Derive completed casts from the independent simulation's commits and
			# first contacts, rather than imposing a guessed attack count on it.
			var completed: Array=[]; var open_cast: Dictionary={}
			for event in authority:
				if event.type=="hero_attack": open_cast=event
				elif event.type in ["evade","backstep"]: open_cast={}
				elif event.type=="hit" and not open_cast.is_empty():
					completed.append(open_cast); open_cast={}
			var spans_multiple: bool=step_seconds!=2.0 or style=="signature" or completed.size()>=2
			print("RELEASE DELIVERY: %s %.3fs: %d authoritative commits, %d completed casts, %d presented releases" % [style,step_seconds,attacks.size(),completed.size(),releases.size()])
			check(first_hit and not completed.is_empty() and releases.size()==completed.size() and spans_multiple,"%s %.3fs: every authoritative completed cast delivers one release; long basic/chain frames genuinely span multiple casts" % [style,step_seconds])
			var classified:=completed.size()==releases.size() and not completed.is_empty()
			for index in mini(completed.size(),releases.size()):
				classified=classified and bool(releases[index].skill)==bool(completed[index].skill) and String(releases[index].get("ability_id",""))==String(completed[index].get("ability_id",""))
			check(classified,"%s %.3fs: each release retains its own authoritative signature/technique classification" % [style,step_seconds])
			check(style!="signature" or hit_count>1,"%s %.3fs: multi-target signature damage shares the single release" % [style,step_seconds])
			check(sim.encode_snapshot()==baseline.encode_snapshot(),"%s %.3fs: skipped visual lead changes no damage, time, Mana, positions or RNG" % [style,step_seconds])
			var release_total:=releases.size()
			world._process(.10); baseline.advance(.10)
			var after_total:=0
			for event in presented:
				if event.type=="hero_release": after_total+=1
			check(after_total==release_total and sim.encode_snapshot()==baseline.encode_snapshot(),"%s %.3fs: recovery frames deliver no duplicate release and preserve authority" % [style,step_seconds])
			world.free()

func run_checks() -> void:
	root.size=Vector2i(960,540)
	await process_frame
	var game:=Bot.new(); game.character_class="Arcanist"
	for region in range(4):
		var stats: Dictionary=game._combat_stats()
		stats.max_hp=100000; stats.attack=5000; stats.ability_damage=5000; stats.boss_phases=1
		var sim:=Sim.new(); sim.setup("Arcanist",stats,region*10+1,"Guardian",1979)
		var boss: Dictionary=sim.enemy_by_id(50)
		boss.hp=1000000; boss.max_hp=1000000
		while not sim.finished:
			sim.advance(.1)
			if sim.stage==5 and not boss.warning.is_empty(): break
		check(not sim.finished,"region %d: authentic path reaches a committed guardian warning" % region)
		if sim.finished: continue
		var world: Node3D=World.new(); world.simulation=sim; world.region_index=region; world.character_class="Arcanist"; world.active=false
		root.add_child(world)
		var guardian: Node3D=world.actor_by_id[50]
		check(world.hero.source_avatar and not world.hero.model.visible and world.hero.motion_rig.surfaces.size()==8,"region %d: coverage fixture renders the actual eight authored source surfaces" % region)
		world._position_camera()
		var shot: Transform3D=world.camera.transform
		var natural_position: Vector3=world.hero.position
		for offset in [Vector3.ZERO,Vector3(-1.65,0,-1.20),Vector3(1.65,0,-1.20),Vector3(-.15,0,-2.0)]:
			world.hero.position=natural_position if offset==Vector3.ZERO else guardian.position+offset
			for style in ["basic","signature","starfall"]:
				world.hero.cancel_attack(); world.hero.attack_time=-1; world.hero.release_time=-1
				world.hero.strike(style,.3,true); world.hero.sync_attack(.10); world.hero.animate(0,false)
				var before:=sim.encode_snapshot()
				world._update_combat_readability(0)
				# Skin.actual_bounds reconstructs every used vertex and all four
				# original weights, rather than consulting the hidden model AABB.
				var actual: AABB=world.hero.body.transform*SkinAudit.actual_bounds(world.hero.motion_rig,world.hero.motion_rig.style.accessories)
				var actual_screen:=project_bounds(world,world.hero,actual)
				var window: Dictionary=world._hero_occlusion_window()
				check(window.rect.grow(.05).encloses(actual_screen.rect) and window.far+.05>=actual_screen.far,"region %d %s: cutaway encloses the complete actually weighted hero body in this cast" % [region,style])
				var enemy_screen: Dictionary=world._project_body(guardian)
				var overlaps: bool=enemy_screen.rect.intersects(actual_screen.rect) and enemy_screen.near<actual_screen.far
				var amount: float=guardian.surface_material.get_shader_parameter("hero_cutaway")
				check(not overlaps or amount>=.85,"region %d %s: foreground guardian body relinquishes opacity where it conceals Nyra" % [region,style])
				check(is_equal_approx(float(guardian.surface_material.get_shader_parameter("hero_view_depth")),float(window.far)+.025) if amount>0.0 else true,"region %d %s: cutaway is restricted to geometry before the actual hero skin" % [region,style])
				check(sim.encode_snapshot()==before and world.camera.transform==shot,"region %d %s: body visibility changes neither combat authority nor settled camera" % [region,style])
		world.hero.position=natural_position
		var full_shadow: MeshInstance3D=guardian.model.get_parent().get_node_or_null("UnmaskedBodyShadow")
		check(full_shadow!=null and full_shadow.mesh==guardian.model.mesh and full_shadow.skin==guardian.model.skin and full_shadow.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY and float(full_shadow.material_override.get_shader_parameter("hero_cutaway"))==0.0,"region %d: cutaway retains the complete original weighted shadow in its separate shadow-only pass" % region)
		world.hero.cancel_attack()
		world.hero.strike("basic",.3,true); world.hero.sync_attack(.14); world.hero.animate(0,false)
		sim.pending_attack={"target":50,"skill":false,"left":.14}; world._update_cast_focus()
		check(world.cast_focus.visible and world.cast_focus.position.distance_to(world.hero.projectile_origin())<.0001,"region %d: anticipation energy follows the actual animated casting palm" % region)
		world.hero.release_attack(); world._update_cast_focus()
		check(not world.cast_focus.visible,"region %d: anticipation vanishes when the palm actually releases" % region)
		world._launch_projectile(50,Color("79dbdc"),.085)
		var projectile: Dictionary=world.effects.back()
		check(projectile.origin.distance_to(world.hero.projectile_origin())<.0001 and projectile.destination.distance_to(world._contact_position(guardian))<.0001,"region %d: the real projectile travels from the real palm to guardian chest contact" % region)
		world._impact_sparks(world._contact_position(guardian),Color("79dbdc"))
		world._impact_sparks(world._contact_position(guardian),Color("79dbdc"),true)
		var lights:=0
		for effect in world.effects:
			if effect.kind=="contact_light": lights+=1
		check(lights<=1,"region %d: simultaneous contacts cannot stack whole-scene light flashes" % region)
		world.free()
	exercise_release_delivery(game)
	game.free()
	print("GUARDIAN PRESENTATION SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
