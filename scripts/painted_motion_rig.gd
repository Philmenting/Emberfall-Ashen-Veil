extends RefCounted
## Native GPU skinning of complete painted anatomy in the approved style.
## Cached source-alpha geometry; no per-frame image or figure vertex rewriting.
const NAMES: Array[String] = ["pelvis","chest","head","arm","forearm","hand","weapon","off_arm","off_forearm","off_hand","thigh_l","shin_l","foot_l","thigh_r","shin_r","foot_r","cape","cape_mid","cape_tip","hair","bow_top","bow_string","bow_bottom"]
const PARENTS: Array[int] = [-1,0,1,1,3,4,5,1,7,8,0,10,11,0,13,14,1,16,17,2,6,6,6]
const Layers=preload("res://scripts/painted_motion_layers.gd")
static var cache: Dictionary = {}
static var layer_data_cache: Dictionary = {}
var key:= ""
var texture: Texture2D
var rest_weapon_tip:=Vector3.ZERO
var layer_data: Dictionary={}
var skeleton: Skeleton3D
var rest: Array[Vector3] = []
var local_rest: Array[Vector3] = []
var bone_boxes: Array[AABB] = []
var bone_box_valid: Array[bool] = []
var mesh: ArrayMesh
var skin: Skin
var profile: Dictionary
var scale_pixels := 1.0
var bounds := AABB()
var floor_probes: Array = []

# pelvis, chest, head, shoulder/elbow/wrist, opposite shoulder/elbow/wrist,
# left hip/knee/ankle, right hip/knee/ankle; polygons keep weapons rigid.
const PROFILES := {
 "Vowkeeper":{"p":[[306,240],[311,159],[329,79],[269,145],[252,192],[233,252],[370,146],[383,197],[389,235],[286,246],[248,342],[218,440],[336,248],[377,346],[404,440]],"tip":[460,382],"trail":-1},
 "Arcanist":{"p":[[374,246],[365,161],[379,81],[401,140],[424,184],[451,172],[322,145],[311,197],[291,259],[349,251],[307,347],[286,446],[399,255],[440,344],[477,447]],"tip":[530,48],"trail":-1},
 "Ranger":{"p":[[331,243],[343,153],[367,74],[378,149],[407,216],[426,258],[310,139],[296,195],[282,257],[316,252],[315,345],[308,438],[348,251],[368,329],[391,439]],"tip":[507,153],"trail":-1},
 "raider":{"p":[[148,142],[142,99],[108,55],[114,94],[94,119],[81,145],[179,98],[195,122],[196,146],[130,149],[110,188],[106,226],[171,148],[195,187],[215,227]],"tip":[61,186],"trail":1},
 "bulwark":{"p":[[1020,145],[1020,98],[1021,51],[993,89],[971,119],[953,142],[1055,93],[1075,130],[1070,160],[1001,151],[983,186],[974,225],[1040,151],[1075,190],[1093,227]],"tip":[912,189],"trail":1},
 "hexer":{"p":[[148,588],[145,540],[144,492],[118,532],[107,550],[94,555],[173,535],[188,560],[175,585],[131,598],[106,624],[93,654],[165,596],[178,631],[191,656]],"tip":[83,486],"trail":1},
 "elite":{"p":[[1030,590],[1032,537],[1035,488],[1007,531],[987,556],[975,577],[1061,533],[1086,563],[1086,590],[1008,599],[978,628],[961,658],[1055,599],[1077,630],[1091,659]],"tip":[936,603],"trail":1},
 "guardian_0":{"p":[[266,300],[258,232],[213,176],[211,247],[178,282],[148,302],[319,195],[369,243],[398,306],[230,311],[186,368],[167,451],[306,314],[335,382],[350,450]],"tip":[86,268],"trail":1},
 "guardian_1":{"p":[[277,324],[266,256],[237,199],[224,238],[193,268],[161,258],[307,251],[321,282],[303,319],[246,340],[224,389],[222,466],[307,340],[330,418],[340,476]],"tip":[122,134],"trail":1},
 "guardian_2":{"p":[[284,292],[280,205],[280,136],[245,204],[240,254],[221,293],[330,203],[379,223],[410,247],[272,309],[279,383],[263,466],[314,309],[337,389],[355,465]],"tip":[89,390],"trail":1},
 "guardian_3":{"p":[[302,310],[292,233],[291,151],[244,226],[236,269],[228,307],[353,208],[403,262],[407,304],[272,330],[260,382],[254,449],[361,331],[390,410],[416,465]],"tip":[62,451],"trail":1},
}

func build(character_key: String, data: Dictionary, pixels_per_unit: float) -> void:
 key=character_key
 profile=PROFILES[key]; scale_pixels=pixels_per_unit
 var path:= "res://assets/characters/motion/"+key.to_lower()
 texture=load(path+".png")
 if not layer_data_cache.has(path): layer_data_cache[path]=JSON.parse_string(FileAccess.get_file_as_string(path+".motion.json"))
 layer_data=layer_data_cache[path]
 assert(layer_data.get("packing","")=="separate_painted_anatomical_parts","Missing complete animation parts: "+key)
 var foot:=Vector2(float(data.foot_anchor[0]),float(data.foot_anchor[1]))
 var points: Array=profile.p
 # New layered figures use the pelvis as their horizontal origin, so turning
 # towards another opponent cannot teleport the whole torso around one heel.
 foot.x=float(points[0][0])
 var anchors: Array = points.slice(0,6)
 anchors.append(points[5]) # rigid weapon, child of hand
 anchors.append_array(points.slice(6,15))
 var torso:=Vector2(points[1][0],points[1][1])
 var height:=float(data.body_height)
 var trail:=float(profile.trail)
 anchors.append([torso.x+trail*height*.11,torso.y])
 anchors.append([torso.x+trail*height*.26,torso.y+height*.27])
 anchors.append([torso.x+trail*height*.36,torso.y+height*.54])
 anchors.append([float(points[2][0])+trail*height*.05,float(points[2][1])+height*.05])
 for i in range(20):
  var p:=Vector2(float(anchors[i][0]),float(anchors[i][1]))
  rest.append(Vector3((p.x-foot.x)/scale_pixels,(foot.y-p.y)/scale_pixels,0))
  if i in [12,15]: rest[i].y=float(data.body_height)/scale_pixels*.085
  local_rest.append(rest[i]-(rest[PARENTS[i]] if PARENTS[i]>=0 else Vector3.ZERO))
 var tip: Array=profile.tip
 rest_weapon_tip=Vector3((float(tip[0])-foot.x)/scale_pixels,(foot.y-float(tip[1]))/scale_pixels,0)
 if key=="guardian_0": rest_weapon_tip=rest[6]+(rest_weapon_tip-rest[6])*1.65
 var extra: Array=[rest[6],rest[6],rest[6]]
 if key=="Ranger":
  var weapon: Dictionary=layer_data.parts[3]
  var rect: Array=weapon.region
  var region:=Rect2(float(rect[0]),float(rect[1]),float(rect[2]),float(rect[3]))
  var top:=Layers.map_weapon(self,(Vector2(1297,60)-region.position)/region.size,region)
  var bottom:=Layers.map_weapon(self,(Vector2(1283,409)-region.position)/region.size,region)
  extra=[top,(top+bottom)*.5,bottom]
 for point: Vector3 in extra:
  rest.append(point); local_rest.append(point-rest[6])
 skeleton=Skeleton3D.new(); skeleton.name="PaintedMotionSkeleton"
 for i in range(NAMES.size()):
  skeleton.add_bone(NAMES[i]); skeleton.set_bone_parent(i,PARENTS[i])
  skeleton.set_bone_rest(i,Transform3D(Basis.IDENTITY,local_rest[i]))
 skeleton.reset_bone_poses()
 var cache_key:=key+":"+str(pixels_per_unit)
 if not cache.has(cache_key):
  var built: Dictionary=Layers.build(self,layer_data,float(data.body_height)/scale_pixels)
  mesh=built.mesh; bone_boxes.assign(built.boxes); bone_box_valid.assign(built.valid)
  skin=Skin.new()
  for i in range(NAMES.size()): skin.add_bind(i,Transform3D(Basis.IDENTITY,-rest[i]))
  cache[cache_key]={"mesh":mesh,"skin":skin,"boxes":bone_boxes,"valid":bone_box_valid}
 else:
  mesh=cache[cache_key].mesh; skin=cache[cache_key].skin
  bone_boxes.assign(cache[cache_key].boxes); bone_box_valid.assign(cache[cache_key].valid)
 bounds=mesh.get_aabb()
 # A bounded set of real silhouette vertices is used ONLY while falling.
 # Bone AABBs are conservative camera bounds, not physical floor contacts.
 if not cache[cache_key].has("floor_probes"):
  var arrays:=mesh.surface_get_arrays(0)
  var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
  var bones: PackedInt32Array=arrays[Mesh.ARRAY_BONES]
  var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
  for i in range(0,vertices.size(),8):
   floor_probes.append([vertices[i],bones.slice(i*4,i*4+4),weights.slice(i*4,i*4+4)])
  cache[cache_key]["floor_probes"]=floor_probes
 else: floor_probes=cache[cache_key].floor_probes

func pose(angles: PackedFloat32Array, pelvis_offset: Vector3=Vector3.ZERO, chest_yaw: float=0.0, head_yaw: float=0.0) -> void:
 for i in range(NAMES.size()):
  skeleton.set_bone_pose_position(i,local_rest[i]+(pelvis_offset if i==0 else Vector3.ZERO))
  var rotation:=Basis(Vector3.BACK,angles[i])
  # A small physical turn foreshortens the complete torso painting. Weapons
  # remain rigid and the head counter-turns to keep its attention on the foe.
  if i==1: rotation=rotation*Basis(Vector3.UP,chest_yaw)
  if i==2: rotation=rotation*Basis(Vector3.UP,head_yaw)
  skeleton.set_bone_pose_rotation(i,rotation.get_rotation_quaternion())
 skeleton.force_update_all_bone_transforms()
 _update_bounds()

func _update_bounds() -> void:
 var first:=true
 for i in range(NAMES.size()):
  if not bone_box_valid[i]: continue
  var transform:=skeleton.get_bone_global_pose(i)*Transform3D(Basis.IDENTITY,-rest[i])
  var box: AABB=transform*bone_boxes[i]
  if first: bounds=box; first=false
  else: bounds=bounds.merge(box)

func bone_point(index: int, point: Vector3) -> Vector3:
 return skeleton.get_bone_global_pose(index)*(point-rest[index])

func contact_floor() -> float:
 var transforms: Array[Transform3D]=[]
 for i in range(NAMES.size()): transforms.append(skeleton.get_bone_global_pose(i)*Transform3D(Basis.IDENTITY,-rest[i]))
 var lowest:=INF
 for probe: Array in floor_probes:
  var point:=Vector3.ZERO
  for n in range(4):
   if probe[2][n]>0.0: point+=(transforms[probe[1][n]]*probe[0])*probe[2][n]
  lowest=minf(lowest,point.y)
 return lowest

func weapon_tip() -> Vector3:
 if key=="Ranger": return skeleton.get_bone_global_pose(6).origin
 return skeleton.get_bone_global_pose(6)*(rest_weapon_tip-rest[6])

func set_bow_draw(pull: float) -> Vector3:
 var weapon:=skeleton.get_bone_global_pose(6)
 skeleton.set_bone_pose_position(21,local_rest[21]+weapon.basis.inverse()*Vector3(-pull,0,0))
 skeleton.force_update_all_bone_transforms()
 _update_bounds()
 return skeleton.get_bone_global_pose(21).origin
