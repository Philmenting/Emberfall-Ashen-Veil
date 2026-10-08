extends SceneTree
func _initialize() -> void:
	var args=OS.get_cmdline_user_args()
	assert(args.size()==2,"Pass original outfit texture directory and output texture-cache directory")
	var source=args[0].trim_suffix("/")+"/"
	DirAccess.make_dir_recursive_absolute(args[1])
	for name in ["T_Peasant_Normal","T_Peasant_BaseColor","T_Peasant_ORM"]:
		var image=Image.load_from_file(source+name+".png")
		assert(image!=null and image.get_width()==4096)
		image.resize(2048,2048,Image.INTERPOLATE_LANCZOS)
		assert(image.save_png(args[1].trim_suffix("/")+"/"+name+".png")==OK)
	print("SOURCE TEXTURES: three artist 4K maps reduced to 2K; originals retained")
	quit(0)
