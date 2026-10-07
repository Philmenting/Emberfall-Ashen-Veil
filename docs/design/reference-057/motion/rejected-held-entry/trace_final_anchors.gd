extends SceneTree
const Actor=preload("res://scripts/dungeon_actor.gd")
func _initialize():run.call_deferred()
func run():
	for class_key in ["Arcanist","Ranger","Vowkeeper"]:
		var actor=Actor.new();actor.kind=class_key;root.add_child(actor)
		actor.animate(.20,false);actor.strike("signature",.36,true)
		var duration=.36-Actor.PROJECTILE_RELEASE_LEAD if class_key!="Vowkeeper" else .36
		actor.sync_attack(.36-duration*.67);actor.animate(.08,false)
		actor.begin_evade(actor.global_position,actor.global_position+Vector3(0,0,.9));actor.animate(0,false)
		var first=actor.motion_rig._capture_source_pose();var wy=actor.motion_rig.motion_node.position.y
		for repeat in 4:
			actor._apply_motion(0)
			var fresh=actor.motion_rig._capture_source_pose();var differences=[]
			for i in 65:
				if fresh.positions[i]!=first.positions[i] or fresh.rotations[i]!=first.rotations[i]:differences.append([actor.motion_rig.skeleton.get_bone_name(i),first.positions[i].distance_to(fresh.positions[i]),str(first.rotations[i]),str(fresh.rotations[i])])
			print(class_key," repeat ",repeat," motionY ",wy," -> ",actor.motion_rig.motion_node.position.y," differences=",differences)
		actor.free()
	quit()
