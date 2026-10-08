extends SceneTree
const Actor=preload("res://scripts/dungeon_actor.gd")
var checks:=0
var failures: Array[String]=[]
func check(value: bool,message: String) -> void:
	checks+=1
	if not value:failures.append(message);push_error(message)
func _initialize() -> void:call_deferred("run")
func actual_bounds(rig: RefCounted) -> AABB:
	var result=AABB();var first=true
	for surface in rig.surfaces:
		for slot in surface.mesh.get_surface_count():
			var a=surface.mesh.surface_get_arrays(slot)
			var v: PackedVector3Array=a[Mesh.ARRAY_VERTEX];var j: PackedInt32Array=a[Mesh.ARRAY_BONES];var w: PackedFloat32Array=a[Mesh.ARRAY_WEIGHTS]
			var used={}
			for index in a[Mesh.ARRAY_INDEX]:used[index]=true
			for index in used:
				var point=Vector3.ZERO
				for influence in 4:
					var bind=j[index*4+influence];var name=surface.skin.get_bind_name(bind)
					var bone=rig.skeleton.find_bone(name) if name!=&"" else surface.skin.get_bind_bone(bind)
					point+=(rig.skeleton.get_bone_global_pose(bone)*surface.skin.get_bind_pose(bind)*v[index])*w[index*4+influence]
				point=rig.motion_node.transform*point
				check(point.is_finite(),"Actual skinned vertex must stay finite")
				result=AABB(point,Vector3.ZERO) if first else result.expand(point);first=false
	return result
func run() -> void:
	var actor=Actor.new();actor.kind="Arcanist";root.add_child(actor)
	var points=[]
	for i in 31:
		var t=float(i)/30.0*.9
		actor.motion_rig.pose("death",t)
		actor.motion_rig.motion_node.position.y=0.0
		var box=actual_bounds(actor.motion_rig)
		points.append(maxf(0.0,.003-box.position.y))
	var file=FileAccess.open("res://assets/models/nyra052/death-grounding.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"duration":.9,"samples":points,"model_sha256":FileAccess.get_sha256("res://assets/models/nyra052/arcanist.glb"),"method":"31 actually imported whole-skin source65 samples; source body vertices only; no staff substitution"},"\t"))
	print("DEATH GROUNDING: ", points)
	actor.free();quit(0)
