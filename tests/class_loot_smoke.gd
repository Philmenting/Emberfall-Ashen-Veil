extends SceneTree
const Loot=preload("res://scripts/class_loot.gd")
const Bot=preload("res://tests/balance_survey_bot.gd")
const Store=preload("res://scripts/save_store.gd")
var checks:=0
var failures:=0

func _initialize() -> void: call_deferred("run_checks")
func check(value: bool, description: String) -> void:
	checks+=1
	if value: print("PASS: ",description)
	else:
		failures+=1
		push_error("FAIL: "+description)

func seeded(seed_value: int) -> RandomNumberGenerator:
	var rng:=RandomNumberGenerator.new()
	rng.seed=seed_value
	return rng

func run_checks() -> void:
	for selected in Loot.PRIMARY:
		var rng:=seeded(1790521000)
		var qualities: Dictionary={}
		var slots: Dictionary={}
		var primary_ok:=true
		var affixes_ok:=true
		var values_ok:=true
		var names_ok:=true
		var boss_ok:=true
		for i in range(5000):
			var item:=Loot.roll(selected,false,i%10+1,rng)
			qualities[item.quality]=true
			slots[item.slot]=true
			primary_ok=primary_ok and item.affinity==selected and item.stats.has(Loot.PRIMARY[selected])
			var count: int={"COMMON":1,"UNCOMMON":1,"RARE":2,"EPIC":4,"LEGENDARY":5}[item.quality]
			affixes_ok=affixes_ok and item.stats.size()==count
			values_ok=values_ok and item.tier==i%10+1 and item.power>0 and item.sell>0 and item.temper==0
			for attribute in item.stats: values_ok=values_ok and item.stats[attribute]>0 and item.stats[attribute]<=3+item.tier+3
			names_ok=names_ok and Loot.NAMES[selected][item.slot].has(item.name)
			var boss_item:=Loot.roll(selected,true,i%10+1,rng)
			boss_ok=boss_ok and boss_item.quality in ["RARE","EPIC","LEGENDARY"]
		check(primary_ok,selected+": all 5000 finds include the class primary attribute")
		check(affixes_ok,selected+": quality controls affix count without duplicates")
		check(values_ok,selected+": item values and all ten tiers stay valid")
		check(names_ok,selected+": every item has a name from its class and slot")
		check(qualities.size()==5 and slots.size()==6,selected+": all qualities and slots remain obtainable")
		check(boss_ok,selected+": boss loot is always rare or better")
		check(Loot.roll(selected,true,6,seeded(82))==Loot.roll(selected,true,6,seeded(82)),selected+": same seed reproduces the entire item")
	check(Loot.roll("Arcanist",true,-10,seeded(1)).tier==1 and Loot.roll("Arcanist",true,999,seeded(1)).tier==10,"tier input stays within T1–T10")
	var money: Array=[]
	for selected in Loot.PRIMARY:
		var item:=Loot.roll(selected,false,7,seeded(122))
		money.append([item.slot,item.quality,item.power,item.armor,item.sell])
	check(money[0]==money[1] and money[1]==money[2],"class changes affixes and names without changing quality or sell value")
	var watched:=Bot.new()
	var offline:=Bot.new()
	for game in [watched,offline]:
		game.character_class="Ranger"
		game.inventory.clear()
		game.run_loot.clear()
		game.player_gold=0
		game.player_xp=0
	watched._grant_expedition_rewards(true,11,false,31415,"Arcanist")
	offline._grant_expedition_rewards(true,11,true,31415,"Arcanist")
	check(watched.inventory==offline.inventory,"watched and offline rewards produce identical gear")
	check(watched.player_gold==offline.pending_idle_ash and watched.player_xp==offline.pending_idle_xp,"watched and offline Gold and XP remain identical")
	var earned_class:=true
	for item in watched.inventory: earned_class=earned_class and item.affinity=="Arcanist"
	check(earned_class and not watched.inventory.is_empty(),"completed expedition class determines the drops")
	for game in [watched,offline]: game.free()
	var game: Node=load("res://Main.tscn").instantiate()
	game.save_store=Store.new("user://class-loot-"+str(Time.get_ticks_usec()))
	game.clock_source=func(): return 1790521000.0
	root.add_child(game)
	game.farm_enabled=false
	game._finish_welcome(false)
	game.character_class="Vowkeeper"
	var mage_item:=Loot.roll("Arcanist",true,4,seeded(18))
	game.inventory.append(mage_item)
	game._equip_item(mage_item)
	check(game.equipment[mage_item.slot]==mage_item,"attunement never prevents another class from equipping an item")
	var before: Dictionary=game.equipment.duplicate(true)
	for slot in before: before[slot]=game._normalize_item(before[slot],slot)
	game._save_progress()
	game._load_progress()
	check(game.equipment==before and game.equipment[mage_item.slot].affinity=="Arcanist","class metadata and existing equipment survive save/load without rerolling")
	var card: Control=game._item_card(mage_item,true)
	var labels:=[]
	for child in card.find_children("*","Label",true,false): labels.append(child.text)
	check(" ".join(labels).contains("ARCANIST ATTUNEMENT") and " ".join(labels).contains("Usable by all classes"),"item card explains attunement and cross-class use")
	card.free()
	game.free()
	await process_frame
	print("CLASS LOOT SMOKE: ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
