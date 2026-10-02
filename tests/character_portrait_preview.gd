extends SceneTree
## Live class/equipment portraits rendered from the game's actual 3D model.
const HeroArt=preload("res://scripts/hero_art.gd")
var output:="/tmp/emberfall-character-portraits.png"

func _initialize() -> void: call_deferred("capture")

func capture() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-file="): output=argument.trim_prefix("--capture-file=")
	root.size=Vector2i(1000,550)
	root.content_scale_size=Vector2i(1000,550)
	var backdrop:=ColorRect.new()
	backdrop.color=Color("111820")
	backdrop.size=Vector2(1000,550)
	root.add_child(backdrop)
	for col in range(3):
		var class_key: String=["Vowkeeper","Arcanist","Ranger"][col]
		for row in range(2):
			var quality: String=["COMMON","RARE"][row]
			var gear: Dictionary={}
			for slot in ["Weapon","Helmet","Chest","Gloves","Boots","Amulet"]:
				gear[slot]={"quality":quality,"tier":1 if row==0 else 4,"temper":0}
			var portrait:=HeroArt.new()
			portrait.position=Vector2(50+col*315,22+row*262)
			portrait.size=Vector2(240,214)
			portrait.configure(class_key,gear)
			portrait.set_presentation(true,false)
			root.add_child(portrait)
			var caption:=Label.new()
			caption.text=class_key.to_upper()+" · "+quality
			caption.position=Vector2(50+col*315,239+row*262)
			caption.add_theme_font_size_override("font_size",18)
			caption.add_theme_color_override("font_color",Color("d0ad73"))
			root.add_child(caption)
	for frame in range(8): await process_frame
	await RenderingServer.frame_post_draw
	var capture_image:=root.get_texture().get_image()
	capture_image.convert(Image.FORMAT_RGB8)
	capture_image.save_png(output)
	quit()
