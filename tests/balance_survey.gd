extends SceneTree
const Bot=preload("res://tests/balance_survey_bot.gd")
const Skills=preload("res://scripts/class_skills.gd")
## Deterministic 480-run survey per class; no UI or save writes.
## The equipment score is a simple heuristic, not an optimal build search.
var seed_offset:=0
var loadout_variant:=0
var class_filter: String=""
func _initialize() -> void:
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty() and str(args[0]).is_valid_int(): seed_offset=maxi(0,int(args[0]))
	if args.size()>1 and str(args[1]).is_valid_int(): loadout_variant=clampi(int(args[1]),0,2)
	if args.size()>2: class_filter=str(args[2])
	call_deferred("survey")
func score(game: Node) -> float:
	var s: Dictionary=game._combat_stats()
	var cooldown: float={"Vowkeeper":5.5,"Arcanist":6.0,"Ranger":4.5}[game.character_class]
	var dps: float=s.attack*(1.0+s.crit*0.01)+s.ability_damage/cooldown
	var ehp: float=s.max_hp*(1.0+s.armor/180.0)
	return dps*sqrt(ehp)
func predict(game: Node,target: int) -> float:
	var wins:=0
	for serial in range(16):
		var sim: RefCounted=game._new_expedition(target,serial)
		sim.simulate_to_end()
		if sim.won: wins+=1
	return wins/16.0
func survey() -> void:
	var selected_classes: Array[String]=["Vowkeeper","Arcanist","Ranger"]
	if not class_filter.is_empty():
		if class_filter not in selected_classes:
			push_error("Unknown class filter: "+class_filter)
			quit(2)
			return
		selected_classes=[class_filter]
	for selected in selected_classes:
		var game: Node=Bot.new()
		game.character_class=selected
		var techniques := Skills.choices(selected)
		game.skill_loadouts[selected]=[techniques[loadout_variant],techniques[(loadout_variant+1)%techniques.size()]]
		# Fix the profile seed as well as the serial offset. Without this, offset 0
		# can roll a different full expedition/loot sequence on every process start.
		game.world_seed=1979+seed_offset
		for slot in game.GEAR_SLOTS: game.equipment[slot].slot=slot
		var played:=0.0
		var victories:=0
		var defeats:=0
		var temper_count:=0
		var upgrades:=0
		var target:=1
		var next_check:=0
		var highest_reliable:=1
		for run in range(480):
			if run>=next_check:
				next_check=run+5
				if predict(game,game.floor_number)>=0.95:
					target=game.floor_number
				else:
					target=maxi(1,game.floor_number-1)
					while target>1 and predict(game,target)<0.95: target-=1
				highest_reliable=maxi(highest_reliable,target)
			var sim: RefCounted=game._new_expedition(target,seed_offset+run+1)
			sim.simulate_to_end()
			played+=maxf(30.0,ceilf(sim.elapsed))
			game._grant_expedition_rewards(sim.won,target,false,sim.run_seed)
			if sim.won: victories+=1
			else: defeats+=1
			while game.attribute_points>0:
				game._allocate_attribute(game.CLASS_DATA[selected].primary if game.attribute_points%3!=0 else "Vitality")
			for item in game.inventory.duplicate():
				var old: Dictionary=game.equipment[item.slot]
				var before:=score(game)
				game.equipment[item.slot]=item
				var after:=score(game)
				game.equipment[item.slot]=old
				if after>before:
					game._equip_item(item)
					upgrades+=1
			for item in game.inventory.duplicate(): game._sell_item(item)
			for slot in game.GEAR_SLOTS:
				var item: Dictionary=game.equipment[slot]
				if item.get("temper",0)<3 and game.player_gold>=game._temper_cost(item)*2:
					game._temper_equipment(slot)
					temper_count+=1
			if run in [29,119,239,479]:
				print("SAFE_BALANCE ",JSON.stringify({"seed_offset":seed_offset,"profile_seed":game.world_seed,"loadout_variant":loadout_variant,"class":selected,"runs":run+1,"floor":game.floor_number,"farm":target,"highest_reliable":highest_reliable,"level":game.player_level,"wins":victories,"fails":defeats,"hours":snappedf(played/3600.0,0.01),"tempers":temper_count,"upgrades":upgrades,"gold":game.player_gold,"stats":game._combat_stats()}))
		game.free()
	quit()
