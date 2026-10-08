extends SceneTree
const Bot=preload("res://tests/balance_survey_bot.gd")
const Advisor=preload("res://scripts/gear_advisor.gd")
const Sets=preload("res://scripts/regional_sets.gd")
const Store=preload("res://scripts/save_store.gd")
var checks:=0
var failures:=0

func _initialize() -> void: call_deferred("run_checks")
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("FAIL: "+label)

func model(selected: String="Arcanist") -> Node:
	var game:=Bot.new()
	game.character_class=selected
	game.world_seed=1979
	game.clock_source=func(): return 2000000000
	game.last_saved_at=2000000000
	game.page="gear"; game.gear_tab="bag"
	for slot in game.GEAR_SLOTS: game.equipment[slot]=game._normalize_item(game.equipment[slot],slot)
	return game

func duplicate_item(game: Node, slot: String="Weapon") -> Dictionary:
	var item: Dictionary=game.equipment[slot].duplicate(true)
	item.status=""; item.affinity=game.character_class
	return item

func run_checks() -> void:
	for selected in ["Vowkeeper","Arcanist","Ranger"]:
		var game:=model(selected)
		var item:=duplicate_item(game)
		check(Advisor.is_obsolete(item,game.equipment,selected),selected+": equal mundane duplicate is eligible")
		for key in ["power","armor","tier"]:
			var better:=item.duplicate(true); better[key]+=1
			check(not Advisor.is_obsolete(better,game.equipment,selected),selected+": preserves higher "+key)
		for key in Advisor.ATTRIBUTES:
			var better:=item.duplicate(true); better.stats[key]=int(better.stats.get(key,0))+1
			check(not Advisor.is_obsolete(better,game.equipment,selected),selected+": preserves better "+key+" even outside this class's combat summary")
		for field in [{"locked":true},{"quality":"EPIC"},{"quality":"LEGENDARY"},{"temper":1},{"relic":"echo_lightning"},{"region":0},{"affinity":"Ranger" if selected!="Ranger" else "Arcanist"},{"slot":"Unknown"}]:
			var kept:=item.duplicate(true); kept.merge(field,true)
			check(not Advisor.is_obsolete(kept,game.equipment,selected),selected+": preserves special/build option "+str(field))
		var unknown:=item.duplicate(true); unknown.stats.FutureAffix=1
		check(not Advisor.is_obsolete(unknown,game.equipment,selected),selected+": unknown affixes require individual review")
		game.equipment.Weapon.region=0
		item.region=0; item.power-=1
		check(Advisor.is_obsolete(item,game.equipment,selected),selected+": weaker same-region duplicate is eligible")
		game.inventory=[item]
		var gold: int=game.player_gold
		game._review_cleanup()
		check(game.inventory.size()==1 and game.player_gold==gold and game.cleanup_preview.size()==1,"review never sells gear")
		game._show_all_gear(); game._confirm_cleanup()
		check(game.inventory.size()==1 and game.player_gold==gold,"cancel invalidates the sale")
		game._review_cleanup(); item.locked=true; game._confirm_cleanup()
		check(game.inventory.size()==1 and game.player_gold==gold and game.cleanup_notice.contains("Nothing was sold"),"stale review protects changed gear")
		item.locked=false; game._review_cleanup(); game._confirm_cleanup()
		check(game.inventory.is_empty() and game.player_gold==gold+item.sell and item.status=="sold","confirmed sale pays exact quoted value once")
		game._confirm_cleanup()
		check(game.player_gold==gold+item.sell,"repeated confirmation never duplicates Gold")
		game.free()
	var game:=model()
	var one:=duplicate_item(game); var two:=duplicate_item(game,"Gloves")
	game.inventory=[one,two]; game._review_cleanup(); two.power+=999
	var gold: int=game.player_gold
	game._confirm_cleanup()
	check(game.inventory.size()==2 and game.player_gold==gold,"one stale entry rejects the whole sale without partial payout")
	two.power-=999; game._review_cleanup(); game.character_class="Ranger"; game._confirm_cleanup()
	check(game.inventory.size()==2 and game.player_gold==gold,"class changes invalidate sale review")
	game.character_class="Arcanist"; game._review_cleanup()
	game.inventory[0]=one.duplicate(true); game._confirm_cleanup()
	check(game.inventory.size()==2 and game.player_gold==gold,"equal replacement object is not a reviewed inventory item")
	game.inventory=[one,two]; game._review_cleanup(); game._navigate("camp"); game._confirm_cleanup()
	check(game.inventory.size()==2 and game.cleanup_preview.is_empty(),"leaving the bag cancels an unconfirmed sale")
	game.free()
	game=model()
	game.equipment.Helmet.region=0; game.equipment.Chest.region=0
	var candidate:=duplicate_item(game,"Gloves"); candidate.region=0
	check(Sets.counts(game.equipment)==[2,0,0,0] and Sets.missing_slots(game.equipment,0)==["Weapon","Gloves","Boots","Amulet"],"set progress counts worn pieces and actual missing slots")
	check(game._is_safe_upgrade(candidate),"equal-stat third piece is a safe upgrade because it activates a beneficial set")
	var mana_tradeoff:=duplicate_item(game,"Amulet")
	mana_tradeoff.stats.Spirit=int(mana_tradeoff.stats.Spirit)-1
	mana_tradeoff.stats.Intellect=int(mana_tradeoff.stats.Intellect)+10
	check(game._compare_item(mana_tradeoff).max_mana>0 and not game._is_safe_upgrade(mana_tradeoff),"larger Mana pool cannot hide lost Spirit and slower on-hit recovery")
	var messages: Array=game._gear_effect_changes(candidate)
	check(messages.size()==1 and not messages[0].loss and messages[0].copy.contains("SET ACTIVATED"),"third piece preview describes exact activated set")
	game.equipment.Gloves=candidate
	var breaker:=candidate.duplicate(true); breaker.region=1; breaker.power+=99
	check(not game._is_safe_upgrade(breaker) and game._gear_effect_changes(breaker)[0].copy.contains("SET LOST"),"numerically stronger gear cannot silently remove an active set")
	game.equipment.Weapon.region=1; game.equipment.Boots.region=1
	var switch:=duplicate_item(game,"Helmet"); switch.region=1
	messages=game._gear_effect_changes(switch)
	check(messages.size()==2 and messages[0].loss and not messages[1].loss,"switching regional sets previews both effects")
	game.equipment.Weapon.region=0; game.equipment.Boots.region=0
	check(game._gear_effect_changes(breaker).is_empty(),"replacing one piece keeps a set active when enough pieces remain")
	game.equipment.Amulet.relic="echo_lightning"
	var mundane:=duplicate_item(game,"Amulet"); mundane.erase("relic")
	check(game._gear_effect_changes(mundane)[0].copy.contains("SIGNATURE LOST"),"amulet preview explains loss of the active signature")
	game.equipment.Amulet.erase("relic"); mundane.relic="echo_lightning"
	check(game._gear_effect_changes(mundane)[0].copy.contains("SIGNATURE ACTIVATED"),"class relic preview explains the gained signature")
	game.character_class="Vowkeeper"
	check(game._gear_effect_changes(mundane).is_empty(),"inactive other-class relic does not claim an active effect")
	game.free()
	game=model(); game.floor_number=12
	check(game._set_hunt_goal(1).floor==11 and game._set_hunt_goal(1).unlocked,"set hunt uses easiest cleared floor of that region")
	var held:=duplicate_item(game); held.region=1
	var held_copy:=held.duplicate(true)
	game.inventory=[held,held_copy]
	check(game._set_hunt_goal(1).held==["Weapon"] and game._set_hunt_goal(1).slot=="Helmet","duplicate held pieces count as one slot and guide hunts towards missing slots")
	game._review_set_pieces(1)
	check(game.page=="gear" and game.bag_view=="set" and game._filtered_inventory()==[held,held_copy],"set review filters real inventory without equipping or selling")
	game._prepare_set_hunt(1)
	check(game.page=="map" and game.world_tab=="hunts" and game.farm_floor==11 and game.hunt_slot=="Helmet" and game.farm_mode=="hunt","prepare opens the real hunt forecast without starting a run")
	check(game.expedition==null and game.inventory.size()==2,"preparing a set hunt neither starts combat nor grants loot")
	var context: Array=[game.farm_floor,game.hunt_slot,game.farm_mode]
	game._prepare_set_hunt(2)
	check(context==[game.farm_floor,game.hunt_slot,game.farm_mode],"locked region cannot alter farm settings")
	game._prepare_set_hunt(-1); game._prepare_set_hunt(4)
	check(context==[game.farm_floor,game.hunt_slot,game.farm_mode],"invalid set goals are ignored")
	var hunt: RefCounted=game._new_expedition(game.farm_floor,3,game._farm_contract())
	check(hunt.contract()==game.Contract.hunt("Helmet") and hunt.floor_id==11,"prepared target uses existing watched and AFK hunt rules")
	game.save_store=Store.new("user://gear-goals-"+str(Time.get_ticks_usec()))
	var payload: ConfigFile=game._build_save_payload()
	check(game._valid_backup_payload(payload) and game.save_store.save_game(payload)==OK,"set hunt fits the existing save format")
	var restored:=model(); restored.save_store=game.save_store; restored._load_progress()
	check(restored.farm_floor==11 and restored.hunt_slot=="Helmet" and restored.farm_mode=="hunt","targeted regional farm survives a cold reload")
	game.free(); restored.free()
	game=model(); game.floor_number=2; game.first_relic_claimed=true; game.farm_enabled=true
	game._freeze_offline_repeat(game._new_expedition(1,2,game.Contract.combine(["cinder","hollow"])))
	var expected:=model(); expected.floor_number=2; expected.first_relic_claimed=true; expected.farm_enabled=true
	expected.offline_repeat_rules=game.offline_repeat_rules.duplicate(true)
	expected._simulate_offline_time(300)
	game.last_saved_at-=300
	var upgrade:=duplicate_item(game); upgrade.power+=10
	game.inventory=[upgrade]; game.run_loot=[upgrade]; game.page="loot"
	game._equip_recovered_upgrades()
	check(game.offline_repeat_rules.is_empty() and game.equipment.Weapon==upgrade,"bulk equip ends frozen oath AFK just like manual equip")
	check(game.pending_idle_ash==expected.pending_idle_ash and game.pending_idle_xp==expected.pending_idle_xp and game.expedition_serial==expected.expedition_serial,"bulk equip settles elapsed time using original frozen oath stats before applying gear")
	expected.free()
	game._freeze_offline_repeat(game._new_expedition(1,2,game.Contract.combine(["cinder","hollow"])))
	var frozen: String=game.offline_repeat_rules.template
	game.run_loot=[]; game._equip_recovered_upgrades()
	check(game.offline_repeat_rules.template==frozen,"empty upgrade action preserves the frozen farm context")
	game.free()
	await check_ui()
	print("GEAR GOALS SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func check_ui() -> void:
	var game: Node=load("res://Main.tscn").instantiate()
	game.save_store=Store.new("user://gear-goals-ui-"+str(Time.get_ticks_usec()))
	game.clock_source=func(): return 2000000000
	root.add_child(game)
	game.farm_enabled=false; game.onboarding_complete=true; game.floor_number=12
	game._finish_welcome(false)
	for resolution in [Vector2i(854,480),Vector2i(2424,1080),Vector2i(1040,1080)]:
		root.size=resolution
		game.preferences.large_text=true
		game._select_gear_tab("equipment"); game._navigate("gear")
		for frame in range(5): await process_frame
		game.find_child("ReviewRegionalSets",true,false).pressed.emit()
		for frame in range(5): await process_frame
		var scroll: ScrollContainer=game.find_child("PageScroll",true,false)
		var button: Control=game.find_child("PrepareSetHunt_1",true,false)
		check(button!=null and scroll!=null and scroll.get_global_rect().size.x<=game.get_global_rect().size.x,"set goals fit scrollable native layout "+str(resolution))
		check(game.find_child("PrepareSetHunt_2",true,false)==null,"locked region has no hunt button "+str(resolution))
		game.find_child("ReturnToEquipment",true,false).pressed.emit()
		game._select_gear_tab("bag")
		var item:=duplicate_item(game); item.name="Reviewed duplicate"
		game.inventory=[item]; game._build_ui()
		game.find_child("ReviewDuplicateSales",true,false).pressed.emit()
		for frame in range(5): await process_frame
		var confirm: Control=game.find_child("ConfirmDuplicateSales",true,false)
		var cancel: Control=game.find_child("CancelDuplicateSales",true,false)
		scroll=game.find_child("PageScroll",true,false)
		check(confirm!=null and cancel!=null and scroll.get_global_rect().encloses(confirm.get_global_rect()) and scroll.get_global_rect().encloses(cancel.get_global_rect()),"short native sale preview keeps confirm and cancel visible "+str(resolution))
		game.find_child("CancelDuplicateSales",true,false).pressed.emit()
		check(game.inventory.size()==1 and game.bag_view=="all","actual cancel control keeps inventory "+str(resolution))
	game.free()
	await process_frame
