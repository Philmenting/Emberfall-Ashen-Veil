extends SceneTree
const Actor = preload("res://scripts/dungeon_actor.gd")
const Evade = preload("res://scripts/source_avatar_evade.gd")
var records: Array=[]
func _initialize() -> void: run.call_deferred()
func run() -> void:
	for class_key in ["Arcanist","Ranger","Vowkeeper"]:
		var actor=Actor.new();actor.kind=class_key;root.add_child(actor)
		var rig=actor.motion_rig
		for direction_index in 8:
			actor.position=Vector3(2.7,.13,-1.4);actor.rotation.y=.63
			rig.pose("evade",0.0);rig.apply_actor_postprocess(actor,"evade",0.0,0.0,true)
			var transverse: Vector3=rig.motion_node.global_basis.orthonormalized().x
			var forward: Vector3=rig.motion_node.global_basis.orthonormalized().z
			var world_direction: Vector3=(transverse*cos(direction_index*TAU/8.0)+forward*sin(direction_index*TAU/8.0)).normalized()
			var state: Dictionary=Evade.begin(actor,actor.global_position,actor.global_position+world_direction*2.4)
			var rows: Array=[]
			for frame in 121:
				var progress: float=float(frame)/120.0
				var phase: float=progress*.78
				actor.global_position=state.origin+state.direction_world*state.distance_world*progress
				rig.pose("evade",0.0);Evade.apply(rig,actor,phase,state);rig.apply_actor_postprocess(actor,"evade",phase,0.0,true)
				var feet: Array[Vector3]=[]
				for side in ["l","r"]:feet.append(rig.motion_node.global_transform*rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone("foot_"+side)).origin)
				var points: Array[PackedVector3Array]=[PackedVector3Array(),PackedVector3Array()]
				var centers: Array[Vector3]=[Vector3.ZERO,Vector3.ZERO]
				for probe in rig.floor_probes:
					var point:=Vector3.ZERO
					for i in probe.bones.size():point+=(rig.skeleton.get_bone_global_pose(probe.bones[i])*probe.binds[i]*probe.point)*probe.weights[i]
					point=rig.motion_node.global_transform*point
					points[probe.side].append(point);centers[probe.side]+=point
				for side in 2:centers[side]/=points[side].size()
				var ankle: float=(feet[0]-feet[1]).dot(transverse)
				var boot: float=(centers[0]-centers[1]).dot(transverse)
				var boot_gap:=INF
				for left in points[0]:
					for right in points[1]:boot_gap=minf(boot_gap,(left-right).dot(transverse))
				rows.append({"frame":frame,"progress":progress,"phase":phase,"signed_ankle_separation_m":ankle,"signed_weighted_boot_center_separation_m":boot,"signed_weighted_sole_projection_gap_m":boot_gap,"ankles_world":[[feet[0].x,feet[0].y,feet[0].z],[feet[1].x,feet[1].y,feet[1].z]]})
			records.append({"class":class_key,"direction_index":direction_index,"native_transverse_world":[transverse.x,transverse.y,transverse.z],"direction_world":[world_direction.x,world_direction.y,world_direction.z],"lead_side":state.lead_side,"scale_world":state.scale_world,"rows":rows})
		actor.free()
	var output: String=OS.get_cmdline_user_args()[0]
	var file=FileAccess.open(output,FileAccess.WRITE);file.store_string(JSON.stringify({"scope":"actual native65 original-basis signed ankle and indexed weighted sole geometry; 24 actual 2.4m paths, each 121 complete progress samples; production evade phase=.78*travelprogress","paths":records}));file.close()
	print("EVADE SIGNED SEPARATION AUDIT: 24 paths, 2904 actual poses")
	await process_frame;await process_frame;quit(0)
