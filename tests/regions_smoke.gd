extends SceneTree
const ThemeData = preload("res://scripts/dungeon_theme.gd")
var failures:=0
var checks:=0
func _initialize() -> void:
	call_deferred("run_checks")
func check(value: bool,description: String) -> void:
	checks+=1
	if value: print("PASS: ",description)
	else:
		failures+=1
		push_error("FAIL: "+description)
func run_checks() -> void:
	var colors: Array=[]
	for region in range(4):
		var game: Node=load("res://Main.tscn").instantiate()
		root.add_child(game)
		game.farm_enabled=false
		game.floor_number=region*10+1
		game._start_run()
		game.run_arena.animation_enabled=false
		var world: Node=game.run_arena.world
		check(world.region_index==region and world.theme==ThemeData.definition(region),"correct world theme for region %d" % region)
		check(not colors.has(world.theme.stone),"distinct stone palette for region %d" % region)
		colors.append(world.theme.stone)
		check(game.expedition.waves[0][0].name==ThemeData.enemy_name(region,"raider"),"regional enemy names %d" % region)
		check(game.expedition.waves[5][0].name==game.REGIONS[region].boss,"regional boss name %d" % region)
		check(world.actor_by_id[0].region_index==region,"enemy appearance receives region %d" % region)
		check(world.get_node_or_null("FloodedArchive")!=null if region==1 else world.get_node_or_null("FloodedArchive")==null,"water belongs only to the archive %d" % region)
		check(world.get_node_or_null("LavaBasin")!=null if region==3 else world.get_node_or_null("LavaBasin")==null,"lava belongs only to the citadel %d" % region)
		world._ensure_wave(5)
		check(world.actor_by_id[50].boss and world.actor_by_id[50].region_index==region,"boss regalia creates without runtime errors %d" % region)
		var snapshot: Dictionary=game.expedition.snapshot()
		world._build_regional_details()
		check(game.expedition.snapshot()==snapshot,"scenery does not alter combat state %d" % region)
		game.free()
		await process_frame
	print("REGIONS SMOKE: ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
