extends SceneTree
const Store=preload("res://scripts/save_store.gd")
var checks:=0
var failures:=0
var prefix: String="user://onboarding-"+str(Time.get_ticks_usec())
func _initialize() -> void:
	call_deferred("run_checks")
func check(value: bool,description: String) -> void:
	checks+=1
	if value: print("PASS: ",description)
	else:
		failures+=1
		push_error("FAIL: "+description)
func create_game(path: String) -> Node:
	var game: Node=load("res://Main.tscn").instantiate()
	game.save_store=Store.new(path)
	root.add_child(game)
	return game
func run_checks() -> void:
	var game:=create_game(prefix+"-choice")
	await process_frame
	await process_frame
	check(game.has_node("Welcome") and not game.onboarding_complete,"new save opens class selection")
	for name_value in ["ChooseVowkeeper","ChooseArcanist","ChooseRanger","ReviewGear","BeginExpedition"]:
		var button: Control=game.find_child(name_value,true,false)
		check(button!=null and game.get_global_rect().encloses(button.get_global_rect()),name_value+" fits within landscape viewport")
	game.find_child("ChooseRanger",true,false).pressed.emit()
	check(game.character_class=="Ranger" and game.has_node("Welcome"),"class choice updates selection and keeps the introduction open")
	game.free()
	await process_frame
	game=create_game(prefix+"-choice")
	check(game.character_class=="Ranger" and game.has_node("Welcome"),"unfinished selection survives closing the game")
	game.find_child("BeginExpedition",true,false).pressed.emit()
	check(game.onboarding_complete and game.page=="run" and game.expedition.class_key=="Ranger" and not game.has_node("Welcome"),"first expedition uses selected class and closes introduction")
	game._toggle_run_pause()
	game.free()
	await process_frame
	game=create_game(prefix+"-choice")
	check(game.page=="run" and not game.run_active and not game.has_node("Welcome"),"returning to a saved expedition never reopens onboarding")
	game.free()
	await process_frame
	game=create_game(prefix+"-prepare")
	game.find_child("ReviewGear",true,false).pressed.emit()
	check(game.onboarding_complete and game.page=="gear" and game.gear_tab=="build","preparation opens class and attribute editor")
	var points: int=game.attribute_points
	game._allocate_attribute("Strength")
	check(game.allocated_attributes.Strength==1 and game.attribute_points==points-1,"spending a point updates the build")
	game._select_class("Arcanist")
	check(game.allocated_attributes.Strength==0 and game.attribute_points==points,"switching classes refunds allocated points exactly")
	game._select_class("Vowkeeper")
	check(game.attribute_points==points,"repeated class changes cannot create attribute points")
	game._allocate_attribute("Vitality")
	game._reset_attributes()
	game._reset_attributes()
	check(game.attribute_points==points and game.allocated_attributes.Vitality==0,"manual refund is idempotent")
	game._select_gear_tab("equipment")
	check(game.gear_tab=="equipment" and game.page=="gear","equipment tab is available without scrolling past the class editor")
	var item: Dictionary=game.equipment.Weapon.duplicate(true)
	item.name="Onboarding Test Blade"
	item.power+=10
	item.status=""
	game.inventory.append(item)
	var old: Dictionary=game.equipment.Weapon
	old.status="equipped"
	game._equip_item(item)
	check(game.equipment.Weapon==item and game.inventory.has(old) and old.status=="","equipment swap returns old item to bag with actionable status")
	game._select_gear_tab("bag")
	check(game.gear_tab=="bag","bag tab opens directly")
	game.free()
	await process_frame
	game=create_game(prefix+"-prepare")
	check(game.onboarding_complete and not game.has_node("Welcome") and game.attribute_points==points,"finished introduction and refunded points persist")
	game.free()
	await process_frame
	print("ONBOARDING SMOKE: ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
