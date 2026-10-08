extends SceneTree
const Bot=preload("res://tests/balance_survey_bot.gd")
const Store=preload("res://scripts/save_store.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run_checks")
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("FAIL: "+label)
func model() -> Node:
	var game:=Bot.new()
	game.character_class="Arcanist"
	game.world_seed=1979
	game.clock_source=func(): return 2000000000
	game.last_saved_at=2000000000
	for slot in game.GEAR_SLOTS: game.equipment[slot]=game._normalize_item(game.equipment[slot],slot)
	return game
func fill_bag(game: Node) -> void:
	for index in game.MAX_BAG_SIZE:
		var item: Dictionary=game.equipment.Weapon.duplicate(true)
		item.name="Kept weapon %d" % index
		item.slot="Weapon"; item.locked=true; item.sell=index+10
		game.inventory.append(item)
func run_checks() -> void:
	var game:=model()
	var item: Dictionary=game.equipment.Weapon.duplicate(true)
	item.slot="Weapon"; item.affinity="Arcanist"; item.power+=40
	game.inventory.append(item)
	var gold: int=game.player_gold
	game._toggle_item_protection(item)
	game._sell_item(item)
	check(game.inventory.has(item) and game.player_gold==gold,"protected item rejects direct sale without changing gold")
	game._equip_item(item)
	check(game.equipment.Weapon.get("locked",false),"protection follows manual equip")
	var upgrade: Dictionary=item.duplicate(true); upgrade.power+=20; upgrade.locked=false
	game.inventory.append(upgrade); game.run_loot=[upgrade]; game.page="loot"
	game._equip_recovered_upgrades()
	check(game.equipment.Weapon==item and not game._is_safe_upgrade(upgrade),"automatic equip preserves protected equipped item")
	game._equip_item(upgrade)
	check(game.inventory.has(item) and item.locked,"manual replacement keeps protected gear in bag")
	game._toggle_item_protection(item); game._sell_item(item)
	check(not game.inventory.has(item) and game.player_gold==gold+item.sell,"unprotect enables a single normal sale")
	game._sell_item(item)
	check(game.player_gold==gold+item.sell,"repeated sale never duplicates gold")
	var other: Dictionary=upgrade.duplicate(true); other.affinity="Ranger"; other.slot="Boots"; other.locked=true
	game.inventory=[upgrade,other]
	game.bag_view="class"
	check(game._filtered_inventory()==[upgrade],"class filter uses current class affinity")
	game.bag_slot="Boots"
	check(game._filtered_inventory().is_empty() and game.inventory.size()==2,"slot and class filters intersect without removing gear")
	game.bag_view="protected"
	check(game._filtered_inventory()==[other],"protected filter finds protected gear")
	game._show_all_gear()
	check(game._filtered_inventory().size()==2,"show all clears both filters")
	game.free()
	for offline in [false,true]:
		game=model(); fill_bag(game)
		var saved_bag: Array=game.inventory.duplicate(true)
		game._grant_expedition_rewards(true,1,offline,23,"Arcanist")
		check(game.inventory==saved_bag and game.first_relic_claimed,"first clear never evicts protected gear, offline="+str(offline))
		check(game.pending_class_relic.get("relic")=="echo_lightning","first class relic is held outside a full protected bag")
		var earned: Dictionary=game.pending_class_relic.duplicate(true)
		game._claim_reserved_relic()
		check(game.pending_class_relic==earned and game.inventory.size()==20,"full bag cannot claim or discard reserved reward")
		game.save_store=Store.new("user://recovery-"+str(Time.get_ticks_usec()))
		var payload: ConfigFile=game._build_save_payload()
		check(game._valid_backup_payload(payload) and game.save_store.save_game(payload)==OK,"protected bag and held reward form a valid save")
		var restored:=model(); restored.save_store=game.save_store; restored._load_progress()
		check(restored.inventory==saved_bag and restored.pending_class_relic==earned,"locks and held reward survive cold reload")
		var backup: ConfigFile=Store.new().parse_backup_code(Store.new().create_backup_code(payload))
		check(backup!=null and restored._valid_backup_payload(backup) and backup.get_value("hero","pending_class_relic")==earned,"manual backup round-trips held reward")
		restored._toggle_item_protection(restored.inventory[0]); restored._sell_item(restored.inventory[0]); restored._claim_reserved_relic()
		check(restored.pending_class_relic.is_empty() and restored.inventory.size()==20 and restored.inventory.has(earned),"freeing one slot allows actual reward collection")
		restored._claim_reserved_relic()
		check(restored.inventory.size()==20,"held reward cannot be collected twice")
		restored._grant_expedition_rewards(true,1,offline,24,"Arcanist")
		check(restored.pending_class_relic.is_empty(),"later clears never recreate the one-time held reward")
		restored.free(); game.free()
	game=model(); fill_bag(game)
	game.inventory[19].locked=false
	var protected: Array=game.inventory.slice(0,19).duplicate(true)
	game._grant_expedition_rewards(true,1,false,23,"Arcanist")
	check(game.pending_class_relic.is_empty() and game.inventory.size()==20 and game.inventory.slice(0,19)==protected,"first relic replaces only unprotected gear even when protected gear is cheaper")
	check(game.inventory.back().get("relic")=="echo_lightning","guaranteed reward takes the freed satchel slot")
	var invalid: Dictionary=game.inventory[0].duplicate(true); invalid.locked="true"
	check(not game._valid_backup_item(invalid,"Weapon"),"backup rejects a malformed protection flag")
	check(not game._normalize_item(invalid,"Weapon").has("locked"),"legacy load removes malformed optional flag")
	var payload: ConfigFile=game._build_save_payload()
	payload.set_value("hero","pending_class_relic",{"slot":"Weapon","relic":"echo_lightning"})
	check(not game._valid_backup_payload(payload),"backup rejects an invalid reserved reward")
	payload.set_value("hero","pending_class_relic",{"slot":"Amulet","relic":"echo_lightning"})
	check(not game._valid_backup_payload(payload),"backup rejects a reserved reward missing display and combat fields")
	payload.set_value("hero","pending_class_relic",game.inventory.back().duplicate(true))
	payload.set_value("hero","first_relic_claimed",false)
	check(not game._valid_backup_payload(payload),"held reward cannot reset the once-only first reward marker")
	payload=game._build_save_payload(); payload.erase_section_key("hero","pending_class_relic")
	for stored in payload.get_value("hero","inventory"): stored.erase("locked")
	check(game._valid_backup_payload(payload),"old saves without optional protection and reserve fields remain valid")
	game.free()
	game=model(); game.page="loot"; game.run_succeeded=false
	check(game._recovery_advice().action=="build" and game._recovery_advice().copy.contains("2 unspent"),"recovery offers actual unspent points first")
	game._open_recovery_advice()
	check(game.page=="gear" and game.gear_tab=="build","recovery action opens attribute controls")
	game.page="loot"; game.attribute_points=0
	item=game.equipment.Weapon.duplicate(true); item.slot="Weapon"; item.power+=40; game.inventory=[item]
	check(game._recovery_advice().action=="upgrades","recovery detects a genuine safe upgrade")
	game._open_recovery_advice()
	check(game.gear_tab=="bag" and game.bag_view=="upgrades" and game._filtered_inventory()==[item],"recovery opens matching bag results")
	game.inventory.clear()
	var rng:=RandomNumberGenerator.new(); rng.seed=42
	game.inventory=[game.Relics.attune(game.ClassLoot.roll("Arcanist",true,1,rng,"Amulet","RARE"),"Arcanist")]
	check(game._recovery_advice().action=="class","unused class relic receives a specific recommendation")
	game.inventory.clear(); game.player_gold=600
	check(game._recovery_advice().action=="equipment","affordable tempering receives a review action")
	game.player_gold=0
	check(game._recovery_advice().action=="build","recovery does not suggest unaffordable tempering")
	game.page="loot"; game.floor_number=8; game.last_run_floor=5; game.farm_floor=7; game.farm_mode="hunt"; game.hunt_slot="Boots"
	game._start_recovery_farm()
	check(game.run_floor==4 and game.auto_repeat and game.expedition.contract().is_empty(),"recovery farm uses a cleared lower floor with no oath or hunt risk")
	check(game.farm_floor==7 and game.farm_mode=="hunt" and game.hunt_slot=="Boots","recovery farm preserves independent offline hunt goal")
	game.page="loot"; game.floor_number=1; game.last_run_floor=1
	game._start_recovery_farm()
	check(game.page=="loot","no cleared floor is invented after an opening defeat")
	game.expedition=null; game.run_reward={"gold":0,"xp":0,"guardian_life":12}
	check(game._defeat_context().contains("no rewards") and game._defeat_context().contains("12%"),"failed trial copy reports zero reward and actual guardian remainder")
	game.run_reward={"gold":55,"xp":100,"reached_room":3}
	check(game._defeat_context().contains("Gold and XP are kept") and game._defeat_context().contains("room 3"),"normal defeat copy reports kept reward and actual reached room")
	game.free()
	await process_frame
	print("RECOVERY SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
