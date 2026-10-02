extends SceneTree
const Bot = preload("res://tests/balance_survey_bot.gd")
const Store = preload("res://scripts/save_store.gd")
const Forecast = preload("res://scripts/farm_forecast.gd")
const SafeArea = preload("res://scripts/mobile_safe_area.gd")
var checks := 0
var failures := 0

func _initialize() -> void: call_deferred("run_checks")
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("FAIL: "+label)

func model(selected: String="Vowkeeper", stance: String="balanced") -> Node:
	var game := Bot.new()
	game.character_class=selected
	game.combat_stances[selected]=stance
	game.world_seed=1979
	game.floor_number=2
	game.clock_source=func(): return 2000000000
	game.last_saved_at=2000000000
	for slot in game.GEAR_SLOTS: game.equipment[slot]=game._normalize_item(game.equipment[slot],slot)
	return game

func run_checks() -> void:
	for selected in ["Vowkeeper","Arcanist","Ranger"]:
		for stance in ["balanced","assault","bastion"]:
			var expected := model(selected,stance)
			expected._simulate_offline_time(3600)
			var actual := model(selected,stance)
			actual._reconcile_farm_time(3600,true)
			check(actual.offline_job!=null and actual.pending_afk_seconds==3600,"long AFK work begins without blocking")
			actual._select_class("Arcanist" if selected!="Arcanist" else "Ranger")
			actual._start_run(1)
			check(actual.character_class==selected and actual.page=="camp","build and run controls are locked during reconciliation")
			while actual.offline_job!=null: actual._process(0.016)
			check(actual._build_save_payload().encode_to_text()==expected._build_save_payload().encode_to_text(),"cooperative AFK preserves exact rewards, RNG, progression and remainder")
			actual.free(); expected.free()
	var hunt := model("Arcanist")
	hunt.farm_mode="hunt"; hunt.hunt_slot="Boots"
	var hunt_expected := model("Arcanist")
	hunt_expected.farm_mode="hunt"; hunt_expected.hunt_slot="Boots"
	hunt_expected._simulate_offline_time(3600)
	hunt._reconcile_farm_time(3600,true)
	while hunt.offline_job!=null: hunt._process(0.016)
	check(hunt._build_save_payload().encode_to_text()==hunt_expected._build_save_payload().encode_to_text(),"cooperative focused hunts preserve their rules and exact slot-specific loot")
	hunt.free(); hunt_expected.free()
	# Interrupt after some rewards, reload from a real save and finish the ledger.
	var interrupted := model()
	interrupted._reconcile_farm_time(3600,true)
	while interrupted.pending_idle_runs<3: interrupted._process(0.016)
	interrupted.save_store=Store.new("user://beta-afk-resume")
	var payload: ConfigFile=interrupted._build_save_payload()
	check(payload.get_value("idle","reconcile_seconds")>0,"unfinished AFK time is journaled with rewards")
	check(interrupted.save_store.save_game(payload)==OK,"interrupted AFK ledger is saved")
	var resumed := model()
	resumed.save_store=interrupted.save_store
	resumed._load_progress()
	resumed._accrue_offline_time(true)
	while resumed.offline_job!=null: resumed._process(0.016)
	var uninterrupted := model()
	uninterrupted._simulate_offline_time(3600)
	check(resumed._build_save_payload().encode_to_text()==uninterrupted._build_save_payload().encode_to_text(),"reloaded AFK ledger neither loses nor duplicates rewards")
	resumed._accrue_offline_time(true)
	check(resumed.pending_idle_runs==uninterrupted.pending_idle_runs,"duplicate resume notification does not grant extra runs")
	payload.set_value("idle","reconcile_seconds",86401)
	check(not resumed._valid_backup_payload(payload),"out-of-range pending AFK time is rejected in backups")
	interrupted.free(); resumed.free(); uninterrupted.free()
	# Paused expeditions must never start a second offline hero.
	var paused := model()
	paused._start_run(1)
	paused.run_active=false
	paused.last_saved_at-=3600
	paused._accrue_offline_time(true)
	check(paused.offline_job==null and paused.pending_idle_runs==0,"paused expedition remains paused during cooperative startup")
	paused.free()
	var game := model()
	var old: Dictionary=game.equipment.Weapon
	var improvement: Dictionary=old.duplicate(true)
	improvement.slot="Weapon"; improvement.power+=10
	check(game._is_safe_upgrade(improvement),"a strict weapon improvement is marked as an upgrade")
	var tradeoff: Dictionary=improvement.duplicate(true)
	tradeoff.stats={"Intellect":10}
	check(not game._is_safe_upgrade(tradeoff),"an item that loses class stats is not auto-equipped")
	game.inventory=[improvement,tradeoff]
	game.run_loot=[improvement,tradeoff]
	game.page="loot"
	game._equip_recovered_upgrades()
	check(game.equipment.Weapon==improvement and game.inventory.has(old) and game.inventory.has(tradeoff),"quick equip retains displaced items and leaves tradeoffs for manual review")
	game._equip_recovered_upgrades()
	check(game.equipment.Weapon==improvement and game.inventory.size()==2,"quick equip is idempotent")
	game._start_run(1); game._skip_run()
	check(game.run_reward.has("seconds") and game.run_reward.kills==game.expedition.kills,"result metrics come from the actual expedition")
	var unlocked: int=game.floor_number
	game._continue_expedition()
	check(game.page=="run" and game.run_floor==unlocked,"campaign continuation starts the actual unlocked floor")
	game._skip_run(); game._return_to_camp()
	game._start_run(1,game.Contract.hunt("Boots")); game._skip_run()
	game._continue_expedition()
	check(game.expedition.contract()==game.Contract.hunt("Boots") and game.run_floor==1,"hunt continuation preserves its slot and floor")
	game._skip_run(); game._return_to_camp()
	game._start_run(1,game.Contract.trial(1)); game._skip_run()
	game._continue_expedition()
	check(game.run_floor==game.Contract.trial_floor(2) and game.expedition.contract()==game.Contract.trial(2),"trial continuation selects the next separate challenge")
	var coarse := Forecast.new()
	coarse.setup(game.character_class,game._combat_stats(),1,"Guardian")
	coarse.step(256)
	var responsive := Forecast.new()
	responsive.setup(game.character_class,game._combat_stats(),1,"Guardian")
	while not responsive.complete(): responsive.step_budget(500)
	check(responsive.summary()==coarse.summary(),"budgeted forecast matches the original full-pattern assessment")
	game.free()
	check(SafeArea.insets(Vector2i(2400,1080),Rect2i(120,0,2160,1080),Vector2(1200,540))=={"left":60,"top":0,"right":60,"bottom":0},"landscape display cutouts scale to logical insets")
	check(SafeArea.insets(Vector2i(1920,1080),Rect2i(0,0,1920,1032),Vector2(960,540)).bottom==24,"navigation bar inset is preserved")
	check(SafeArea.insets(Vector2i.ZERO,Rect2i(),Vector2(960,540)).left==0,"missing display information has safe defaults")
	await process_frame
	print("BETA FLOW SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
