"""Original built reliquaries for Emberfall 0.49; no third-party model input.

Rebuild: blender -b -t 2 --python tools/art/build_reliquaries_049.py
Godot Y-up metres, front +Z. ChestLid is a real rear hinge: rotation.x -1.1
opens it. Materials share RuinArchitecture's cached low-cost material families.
"""
from pathlib import Path
import sys, json, math, hashlib
import bpy

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(Path(__file__).parent))
import build_ruin_environment as e

OUT=ROOT/'assets/models/props049'
HINGE=(0,.68,-.43)
REGIONS=('spire','archive','ossuary','citadel')

def prism_x(mat,section,x0,x1):
 n=len(section)
 verts=[(x,y,z) for x in (x0,x1) for y,z in section]
 faces=[tuple(reversed(range(n))),tuple(range(n,n*2))]
 faces.extend((i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n))
 e.mesh(mat,verts,faces)

def rivet(x,y,z,mat='iron'):
 # Small domed fixing, not a sphere stud enlarged for ornament.
 e.loft(mat,(x,y,z),[(0,.024,.024),(.008,.029,.029),(.017,.023,.023),(.024,.009,.009)],6)

def front_rivet(x,y,z,mat='iron'):
 with e.at(x=x,y=y,z=z,angle=0):
  # Six-sided domed rivet explicitly oriented normal to the front board.
  vv=[]
  for d,rad in [(0,.025),(.017,.025),(.030,.010)]:
   for k in range(6):
    t=k*math.tau/6;vv.append((math.cos(t)*rad,math.sin(t)*rad,d))
  ff=[]
  for row in range(2):
   for k in range(6):ff.append((row*6+k,row*6+(k+1)%6,(row+1)*6+(k+1)%6,(row+1)*6+k))
  ff.append(tuple(12+i for i in range(6)));e.mesh(mat,vv,ff)

def handle(side,y=.43,mat='iron'):
 x=side*.687
 for z in [-.19,.19]:
  e.block(mat,(x,y,z),(.07,.15,.10),.002,4)
 e.tube(mat,[(x,y,-.17),(x+side*.018,y-.02,-.17),(x+side*.039,y-.15,-.10),(x+side*.039,y-.18,.10),(x+side*.018,y-.02,.17),(x,y,.17)],.023,8)

def wooden_body(region):
 oak='oak';metal='bronze' if region==1 else 'iron'
 # Individual boards terminate inside four continuous joined corner posts.
 for side in [-1,1]:
  for z in [-.37,.37]:e.block(oak,(side*.624,.36,z),(.16,.67,.15),.006,region+3)
  for row in range(3):
   e.block(oak,(0,.20+row*.16,side*.369),(1.16,.155,.105),.004,row)
  for row in range(3):
   e.block(oak,(side*.636,.20+row*.16,0),(.105,.155,.65),.004,row+7)
 e.block(oak,(0,.15,0),(1.27,.12,.74),.006,7)
 # Upper rebate is open; a dark internal floor is visible when the lid rises.
 for side in [-1,1]:
  e.block(metal,(0,.653,side*.405),(1.37,.074,.073),.002,7)
  e.block(metal,(side*.664,.653,0),(.073,.074,.77),.002,8)
 for x in [-.49,.49]:
  for z in [-.423,.423]:
   e.block(metal,(x,.397,z),(.10,.51,.042),.002,5)
   for yy in [.205,.586]:front_rivet(x,yy,z if z>0 else z-.025,metal)
  e.block(metal,(x,.049,0),(.135,.13,.86),.004,9)
 for side in [-1,1]:handle(side,.45,metal)
 if region==0:
  # One fitted lock plate and tapered hasp, not a luminous decorative emblem.
  e.block(metal,(0,.485,.439),(.19,.24,.040),.003,4)
  e.block('bronze',(0,.483,.468),(.034,.075,.021),.001,2)
  e.block(metal,(0,.372,.463),(.105,.062,.069),.001,3)
 else:
  # Archive chest stands clear of damp flagging on stone-bearing runners.
  for x in [-.46,.46]:e.block('dressed_stone',(x,.035,0),(.22,.12,.79),.009,8)
  for x in [-.36,.36]:
   e.block(metal,(x,.509,.442),(.09,.22,.046),.002,4)
   e.block(metal,(x,.413,.473),(.14,.068,.043),.001,5)

def curved_lid(region):
 # Lid geometry is already local to the hinge. Its barrel section is made of
 # actual planks/shell strips, so both the open underside and joins are real.
 material='oak' if region in (0,1) else ('dressed_stone' if region==2 else 'iron')
 metal='bronze' if region==1 else 'iron'
 rise=[.24,.15,.19,.20][region]
 depth=.90
 segments=8 if region!=2 else 4
 def upper(t):return .075+rise*math.sin(math.pi*t)
 for k in range(segments):
  a=k/segments;b=(k+1)/segments
  gap=.005 if material=='oak' else .0015
  section=[(.022,a*depth+gap),(.022,b*depth-gap),(upper(b),b*depth-gap),(upper(a),a*depth+gap)]
  prism_x(material,section,-.697,.697)
 # Thin end cheeks and two straps follow the lid section without floating.
 outer=[(upper(k/segments)+.018,k*depth/segments) for k in range(segments+1)]
 inner=[(upper(k/segments)+.003,k*depth/segments) for k in reversed(range(segments+1))]
 for x in [-.493,.493]:prism_x(metal,outer+inner,x-.049,x+.049)
 for x in [-.714,.714]:
  cheek=[(.015,0),(.015,depth)]+[(upper(k/segments),k*depth/segments) for k in reversed(range(segments+1))]
  prism_x(metal if region!=2 else 'dressed_stone',cheek,x-.018,x+.018)
 for z in [0,depth]:e.block(metal,(0,.052,z),(1.455,.09,.051),.002,14)
 for x in [-.36,.36] if region==1 else [0]:
  e.block(metal,(x,-.029,depth+.005),(.085,.18,.044),.002,12)
 # Actual alternating hinge knuckles are centred on this pivot.
 for x in [-.48,.48]:
  e.tube(metal,[(x-.07,0,0),(x+.07,0,0)],.045,10)
  e.block(metal,(x,.060,.083),(.12,.045,.18),.002,2)
 if region==2:
  # Long recessed ridge and bevelled slope identify a carved burial casket.
  e.block('dressed_stone',(0,.251,.45),(1.12,.063,.16),.009,15)

def stone_body():
 # An open inner chamber framed by thick chamfered stone, with a recessed
 # front tablet rather than an albedo painted onto a plain box.
 e.block('dressed_stone',(0,.09,0),(1.42,.22,.93),.014,20)
 for side in [-1,1]:
  e.block('dressed_stone',(side*.63,.411,0),(.17,.46,.81),.012,21)
  e.block('dressed_stone',(0,.415,side*.343),(1.14,.39,.12),.010,22)
  e.block('dressed_stone',(0,.257,side*.421),(1.14,.08,.10),.010,22)
  e.block('dressed_stone',(0,.598,side*.415),(1.20,.075,.11),.008,23)
 # Slightly set-back front slab leaves a dark, real perimeter recess.
 e.block('dressed_stone',(0,.423,.383),(.92,.225,.055),.006,24)
 for side in [-1,1]:handle(side,.46,'iron')
 for x in [-.48,.48]:e.block('iron',(x,.567,-.430),(.125,.22,.05),.003,25)
 e.block('iron',(0,.482,.444),(.115,.16,.055),.002,26)

def iron_body():
 # Heavy coffer: panel skins captured by angle-iron corner joints and a rolled
 # lower frame. A separate recessed front plate makes the construction legible.
 e.block('iron',(0,.125,0),(1.41,.19,.90),.010,30)
 for x in [-.49,.49]:e.block('iron',(x,.032,0),(.18,.104,.81),.007,39)
 for side in [-1,1]:
  e.block('iron',(side*.646,.421,0),(.11,.44,.75),.005,31)
  e.block('iron',(0,.421,side*.367),(1.20,.43,.085),.005,32)
 for x in [-.616,.616]:
  for z in [-.398,.398]:e.block('iron',(x,.420,z),(.12,.54,.10),.005,33)
 for side in [-1,1]:
  e.block('iron',(0,.649,side*.408),(1.43,.075,.077),.003,34)
  e.block('iron',(side*.683,.649,0),(.072,.075,.81),.003,35)
 e.block('iron',(0,.414,.417),(.96,.263,.038),.006,36)
 for x in [-.58,-.34,.34,.58]:
  for yy in [.254,.561]:front_rivet(x,yy,.466,'bronze')
 for side in [-1,1]:handle(side,.48,'iron')
 for x in [-.30,.30]:
  e.block('iron',(x,.482,.461),(.095,.23,.05),.002,37)
  e.block('bronze',(x,.428,.493),(.039,.07,.023),.001,38)

def create_part(name,groups,parent):
 stats={};bounds=[]
 for (family,smooth),(verts,faces) in groups.items():
  data=bpy.data.meshes.new(name+'_'+family);data.from_pydata([e.xyz(v) for v in verts],[],faces);data.update()
  obj=bpy.data.objects.new(name+'_'+family,data);bpy.context.collection.objects.link(obj);obj.parent=parent
  obj.data.materials.append(e.material(family));bpy.context.view_layer.objects.active=obj;obj.select_set(True)
  bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT')
  modifier=obj.modifiers.new('triangulation','TRIANGULATE');bpy.ops.object.modifier_apply(modifier=modifier.name)
  uv=data.uv_layers.new(name='UVMetres')
  for face in data.polygons:
   gx,gy,gz=face.normal.x,face.normal.z,-face.normal.y
   for li in face.loop_indices:
    p=data.vertices[data.loops[li].vertex_index].co;x,y,z=p.x,p.z,-p.y
    if abs(gy)>.70:u,v=x,-z*(1 if gy>=0 else -1)
    elif abs(gx)>abs(gz):u,v=-z*(1 if gx>=0 else -1),y
    else:u,v=x*(1 if gz>=0 else -1),y
    uv.data[li].uv=(u,v)
   face.use_smooth=smooth
  stats[family]=stats.get(family,0)+len(data.polygons);bounds.extend(verts);obj.select_set(False)
 # One mesh per material family in each movable body part.
 for family in stats:
  objs=[o for o in bpy.context.scene.objects if o.parent==parent and o.type=='MESH' and o.data.materials[0].name=='environment_'+family]
  bpy.ops.object.select_all(action='DESELECT')
  for obj in objs:obj.select_set(True)
  bpy.context.view_layer.objects.active=objs[0]
  if len(objs)>1:bpy.ops.object.join()
  objs[0].name=name+'__'+family
 return stats,bounds

def build(region):
 e.reset()
 if region in (0,1):wooden_body(region)
 elif region==2:stone_body()
 else:iron_body()
 body=dict(e.GROUPS);e.GROUPS.clear();curved_lid(region);lid=dict(e.GROUPS);e.GROUPS.clear()
 for x in [-.48,.48]:
  with e.at(x=x,y=HINGE[1],z=HINGE[2]):
   e.tube('bronze' if region==1 else 'iron',[(-.10,0,0),(-.073,0,0)],.048,10)
   e.tube('bronze' if region==1 else 'iron',[(.073,0,0),(.10,0,0)],.048,10)
 for key,(vv,ff) in e.GROUPS.items():
  if key not in body:body[key]=[[],[]]
  v,f=body[key];start=len(v);v.extend(vv);f.extend(tuple(start+i for i in face) for face in ff)
 nodes=[]
 for name in ('Body','ChestLid'):
  node=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(node);nodes.append(node)
 nodes[1].location=e.xyz(HINGE)
 body_stats,body_bounds=create_part('Body',body,nodes[0]);lid_stats,lid_bounds=create_part('ChestLid',lid,nodes[1])
 key=REGIONS[region]+'_reliquary';path=OUT/(key+'.glb')
 bpy.ops.object.select_all(action='SELECT')
 bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_materials='EXPORT',export_tangents=True,export_animations=False,export_cameras=False,export_lights=False)
 bounds=body_bounds+[tuple(v[i]+HINGE[i] for i in range(3)) for v in lid_bounds]
 return {'file':str(path.relative_to(ROOT)),'triangles':sum(body_stats.values())+sum(lid_stats.values()),'body_surfaces':body_stats,'lid_surfaces':lid_stats,'hinge_local_metres':HINGE,'open_rotation_x_radians':-1.1,'bounds_min':[min(p[i] for p in bounds) for i in range(3)],'bounds_max':[max(p[i] for p in bounds) for i in range(3)],'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}

if __name__=='__main__':
 OUT.mkdir(parents=True,exist_ok=True)
 report={}
 for region,key in enumerate(REGIONS):
  report[key]=build(region);print('RELIQUARY',key,report[key]['triangles'],flush=True)
 manifest={'origin':'Original code-authored Blender geometry; no third-party 3D asset or new raster input','version':'0.49','generator':'tools/art/build_reliquaries_049.py','generator_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'authoring_tool':'Blender '+bpy.app.version_string,'rebuild_command':'blender -b -t 2 --python tools/art/build_reliquaries_049.py','source_license_record':'assets/models/props049/LICENSE-SOURCE.txt','geometry_library':'tools/art/build_ruin_environment.py','geometry_library_sha256':hashlib.sha256(Path(e.__file__).read_bytes()).hexdigest(),'coordinates':'Godot Y-up metres; front +Z; Body at origin, ChestLid hinge at (0,0.68,-0.43). UVMetres local metre projection, glTF tangents exported.','materials':'Existing oak/iron/bronze/dressed_stone runtime families and their documented textures; no new texture source or license claim.','models':report}
 (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
