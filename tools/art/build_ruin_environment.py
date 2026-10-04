"""Original joined regional room architecture for Emberfall 0.47.

Rebuild: blender -b -t 2 --python tools/art/build_ruin_environment.py
Coordinates are Godot Y-up metres. No downloaded model, generated picture,
character builder or baked screenshot is used. Each GLB is joined by material;
floor/foundation surfaces are separate from standing-height wall surfaces.
"""
from pathlib import Path
from collections import defaultdict
import bpy, math, json, hashlib, random
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets/models/environment'
TAU=math.tau
GROUPS={}
MATS={}
REPORT={}
PALETTE={
 'stone':('747774',0,.94),'edge':('aaa79b',0,.91),'dark':('353d3c',0,.98),
 'floor':('747774',0,.95),'iron':('535d61',.66,.74),'bronze':('786853',.58,.70),
 'oak':('3d3128',0,.95),'leather':('494331',0,.98),'ember':('ac4c20',0,.85),
}

def xyz(p): return (p[0],-p[2],p[1])
def material(name):
 if name in MATS: return MATS[name]
 hx,metal,rough=PALETTE[name]
 rgb=[int(hx[i:i+2],16)/255 for i in (0,2,4)]
 linear=[((v+.055)/1.055)**2.4 if v>.04045 else v/12.92 for v in rgb]
 m=bpy.data.materials.new('environment_'+name);m.use_nodes=True
 bs=m.node_tree.nodes.get('Principled BSDF')
 bs.inputs['Base Color'].default_value=(*linear,1);bs.inputs['Metallic'].default_value=metal;bs.inputs['Roughness'].default_value=rough
 if name=='stone':
  tint=m.node_tree.nodes.new('ShaderNodeVertexColor');tint.layer_name='MasonryTint'
  m.node_tree.links.new(tint.outputs['Color'],bs.inputs['Base Color'])
 if name=='ember':
  bs.inputs['Emission Color'].default_value=(*linear,1);bs.inputs['Emission Strength'].default_value=.4
 MATS[name]=m;return m

def mesh(mat,verts,faces,smooth=False):
 key=(mat,smooth)
 if key not in GROUPS: GROUPS[key]=[[],[]]
 v,f=GROUPS[key];base=len(v);v.extend(verts);f.extend(tuple(base+i for i in face) for face in faces)

def block(mat,center,size,chip=.025,seed=0):
 # Connected clipped-corner prism, with subdued hand-cut bedding, not a cube.
 x,y,z=center;sx,sy,sz=size;r=random.Random(seed)
 outline=[(-.40,-.5),(.41,-.5),(.5,-.39),(.5,.40),(.40,.5),(-.41,.5),(-.5,.38),(-.5,-.40)]
 v=[]
 for row,(level,scale) in enumerate([(-.5,.95),(-.43,1),(.42,1),(.5,.94)]):
  for i,(a,b) in enumerate(outline):
   wear=r.uniform(-chip,chip) if row in (1,2) else 0
   v.append((x+a*sx*scale+wear,y+level*sy-(r.uniform(0,chip) if row==3 else 0),z+b*sz*scale+wear))
 f=[]
 for j in range(3):
  for i in range(8): f.append((j*8+i,j*8+(i+1)%8,(j+1)*8+(i+1)%8,(j+1)*8+i))
 f.extend([tuple(reversed(range(8))),tuple(24+i for i in range(8))]);mesh(mat,v,f)

def loft(mat,center,rings,sides=16,smooth=False,closed=False):
 x,y,z=center;v=[]
 for yy,rx,rz in rings:
  for i in range(sides):
   a=TAU*i/sides;v.append((x+rx*math.sin(a),y+yy,z+rz*math.cos(a)))
 f=[]
 for row in range(len(rings)-1):
  for i in range(sides):f.append((row*sides+i,row*sides+(i+1)%sides,(row+1)*sides+(i+1)%sides,(row+1)*sides+i))
 if closed:
  last=(len(rings)-1)*sides
  for i in range(sides): f.append((last+i,last+(i+1)%sides,(i+1)%sides,i))
 else:f += [tuple(reversed(range(sides))),tuple((len(rings)-1)*sides+i for i in range(sides))]
 mesh(mat,v,f,smooth)

def tube(mat,path,radius=.05,sides=10):
 v=[]
 for j,p in enumerate(path):
  point=Vector(p);t=(Vector(path[min(j+1,len(path)-1)])-Vector(path[max(0,j-1)])).normalized()
  ref=Vector((0,0,1)) if abs(t.z)<.95 else Vector((1,0,0))
  ax=t.cross(ref).normalized();az=t.cross(ax).normalized()
  rad=radius[j] if isinstance(radius,list) else radius
  for i in range(sides):v.append(tuple(point+(ax*math.cos(TAU*i/sides)+az*math.sin(TAU*i/sides))*rad))
 f=[]
 for j in range(len(path)-1):
  for i in range(sides): f.append((j*sides+i,j*sides+(i+1)%sides,(j+1)*sides+(i+1)%sides,(j+1)*sides+i))
 f += [tuple(reversed(range(sides))),tuple((len(path)-1)*sides+i for i in range(sides))];mesh(mat,v,f,True)

def arc_y(x,half,spring,rise,pointed=False):
 t=min(1,abs(x/half))
 return spring+rise*((1-t)**.68 if pointed else math.sqrt(max(0,1-t*t)))

def arch(mat,half,spring,rise,thick,z_front,z_back,pointed=False,segments=24):
 # Continuous voussoir bands close around genuine openings and deep reveals.
 for i in range(segments):
  t0=-1+2*i/segments;t1=-1+2*(i+1)/segments
  a0=math.asin(max(-1,min(1,t0)));a1=math.asin(max(-1,min(1,t1)))
  x0=math.sin(a0)*half;x1=math.sin(a1)*half
  y0=arc_y(x0,half,spring,rise,pointed);y1=arc_y(x1,half,spring,rise,pointed)
  outer0=(x0+thick*t0,y0+thick*(1-abs(t0))+.10)
  outer1=(x1+thick*t1,y1+thick*(1-abs(t1))+.10)
  # Fine joint is physical, not a texture grid or disconnected cube stack.
  q=.012
  polygon=[(x0+q,y0),(x1-q,y1),outer1,outer0]
  verts=[(x,y,z) for z in (z_front,z_back) for x,y in polygon]
  mesh(mat,verts,[(0,1,2,3),(7,6,5,4),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)])

def vault(mat,half,spring,rise,thick,z_front,z_back,pointed=False):
 # Barrel shell: its visible underside belongs to the room's actual volume.
 n=28;v=[]
 for z in (z_front,z_back):
  for shell in (0,1):
   for i in range(n+1):
    t=-1+2*i/n;x=t*(half+shell*thick)
    y=arc_y(t*half,half,spring,rise,pointed)+shell*thick
    v.append((x,y,z))
 count=n+1;f=[]
 for i in range(n):
  f.extend([(i,i+1,2*count+i+1,2*count+i),(count+i,3*count+i,3*count+i+1,count+i+1),
            (i,count+i,count+i+1,i+1),(2*count+i,2*count+i+1,3*count+i+1,3*count+i)])
 f.extend([(0,2*count,3*count,count),(n,count+n,3*count+n,2*count+n)])
 mesh(mat,v,f)

def face_spandrel(mat,half,spring,rise,height,z_front,z_back,pointed=False,openings=()):
 # Filled wall above the arch, not a detached outline.
 n=24
 for i in range(n):
  a=-half+2*half*i/n;b=-half+2*half*(i+1)/n
  ya=arc_y(a,half,spring,rise,pointed)+.22;yb=arc_y(b,half,spring,rise,pointed)+.22
  crest=height-.09*max(0,math.sin((a+b)*1.8))
  if max(ya,yb)>=crest:continue
  pieces=[(ya,yb,crest)]
  for x,width,low,high in openings:
   if abs((a+b)*.5-x)>width*.5:continue
   next_pieces=[]
   for aa,bb,top in pieces:
    if max(aa,bb)<low:next_pieces.append((aa,bb,min(low,top)))
    if top>high:next_pieces.append((max(aa,high),max(bb,high),top))
   pieces=next_pieces
  for aa,bb,top in pieces:
   if min(aa,bb)>=top:continue
   verts=[(x,y,z) for z in (z_front,z_back) for x,y in [(a,aa),(b,bb),(b,top),(a,top)]]
   mesh(mat,verts,[(0,1,2,3),(7,6,5,4),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)])

def base(depth=5.2,basin=False):
 # Structural 0.85m foundation with paved threshold projecting into the court.
 if basin:
  block('floor',(-2.05,-.43,-depth/2+.3),(.76,.86,depth+2.05),.035,17)
  block('floor',(2.05,-.43,-depth/2+.3),(.76,.86,depth+2.05),.035,21)
  block('floor',(0,-.47,-depth+.25),(4.8,.94,.85),.035,3)
  block('floor',(0,-.13,.81),(4.8,.25,.83),.026,4)
  block('floor',(0,-1.0,-2.25),(3.5,.24,4.65),.03,5)
 else:
  block('floor',(0,-.46,-depth/2+.35),(4.82,.91,depth+1.72),.038,7)
  # Finer flush flags have unequal lengths and narrow physical joints.
  for row in range(math.ceil(depth/1.15)):
   for col in range(4):
    x=-1.82+col*1.22;z=.57-row*1.15
    block('floor',(x,-.023,z),(1.205,.07,1.13),.013,row*7+col)

def pier(x,height,front=.03,style=0):
 rings=[(0,.48,.48),(.18,.52,.51),(.32,.43,.45),(.48,.35,.39),(height-.55,.31,.35),(height-.34,.40,.43),(height-.15,.45,.48),(height,.48,.49)]
 if style==1:rings=[(0,.53,.62),(.25,.57,.65),(.42,.50,.56),(height-.35,.36,.45),(height-.17,.46,.53),(height,.49,.56)]
 loft('stone',(x,0,front),rings,12)
 if style in (0,2):
  for a in (-.9,0,.9):
   dx=math.sin(a)*.29;dz=math.cos(a)*.32
   loft('edge',(x+dx,0,front+dz),[(.40,.063,.063),(.56,.071,.071),(height-.43,.071,.071),(height-.28,.097,.087)],10,True)

# Complete side/rear bay, with region-built surfaces behind its front opening.
def bay_shell(region):
 spring=[3.3,2.45,1.63,2.0][region];rise=[2.85,1.8,2.15,1.65][region]
 height=[8.1,6.65,7.7,8.5][region];depth=[5.3,5.65,5.3,6.0][region]
 half=[1.77,1.83,1.86,1.64][region];pointed=region==0
 base(depth,region==1)
 # Return walls and rear wall are the enclosure, not a separate backdrop.
 for side in (-1,1):
  block('stone',(side*2.14,height*.48,-depth*.5),(.52,height*.96,depth),.028,region*10+side)
  pier(side*1.87,[6.65,4.68,4.14,4.05][region],.05,region)
 block('dark',(0,height*.42,-depth+.16),(3.92,height*.84,.40),.024,13)
 arch('edge',half,spring,rise,.38,.22,-.6,pointed)
 slots=[]
 if region==0:slots=[(x,.68,6.54,7.53) for x in (-1.12,0,1.12)]
 if region==2:slots=[(x,.83,4.62,6.62) for x in (-1.05,0,1.05)]
 if region==3:slots=[(x,.50,4.86,7.04) for x in (-1.07,0,1.07)]
 face_spandrel('stone',half+.13,spring+.08,rise+.07,height,-.08,-1.02,pointed,slots)
 vault('dark',half+.08,spring,rise,.28,-.62,-depth+.35,pointed)
 for z in (-1.8,-3.50):arch('stone',half+.06,spring,rise,.20,z+.12,z-.12,pointed)
 # Deep top coping and cornice connect adjacent modules without a shelf grid.
 for y,thickness,projection in [(height-.46,.20,.05),(height-.18,.20,.12)]:
  block('edge',(0,y,-.18),(4.80,thickness,1.25+projection),.022,region+int(y*3))
 if region==0:spire_interior(depth)
 elif region==1:archive_interior(depth)
 elif region==2:ossuary_interior(depth)
 else:citadel_interior(depth)
 if region==2:
  # Cinerary niches cut through the upper front wall, with real inner sills
  # and separate lidded vessels at depth. They replace a second nave portal.
  for x in (-1.05,0,1.05):
   block('dark',(x,5.61,-1.16),(.83,2.06,.20),.006,2)
   for y in (4.70,5.72):
    block('edge',(x,y,-.57),(.87,.12,1.12),.014,3)
    loft('stone',(x,y+.08,-.62),[(0,.24,.21),(.09,.28,.24),(.38,.25,.22),(.49,.19,.19),(.56,.27,.24),(.63,.17,.16)],16)
  block('edge',(0,4.29,.16),(4.54,.26,.65),.035,3)
 if region==3:
  for y in (4.39,7.21):block('iron',(0,y,.21),(4.70,.23,.41),.010,1)
  for x in (-1.70,1.70):
   tube('iron',[(x,3.43,.32),(x,6.76,.33),(x*.70,7.52,.21)],.095,12)
  for x in (-1.07,0,1.07):
   for row in range(5):block('iron',(x,5.12+row*.37,-.12),(.55,.10,.45),.007,row)
 return depth,height

def bell(center,radius=.71):
 rings=[(0,radius,.9*radius),(.09,radius*1.03,.93*radius),(.16,radius*.88,.80*radius),(.43,radius*.62,.58*radius),(.83,radius*.49,.47*radius),(1.03,radius*.26,.25*radius),(1.12,.075,.07),(1.01,.07,.06),(.84,radius*.40,.39*radius),(.39,radius*.53,.5*radius),(.14,radius*.82,.74*radius),(0,radius*.90,.80*radius)]
 loft('bronze',center,rings,36,True,True)
 x,y,z=center;tube('iron',[(x,y+.9,z),(x,y-.16,z)],.042,10)
 loft('bronze',(x,y-.28,z),[(0,.085,.085),(.08,.11,.11),(.17,.07,.07)],12,True)

def spire_interior(depth):
 # Bell is hung from a connected gallery; the shrine rests against its rear wall.
 block('iron',(0,5.75,-2.65),(3.75,.21,.34),.008,2)
 tube('iron',[(0,5.65,-2.65),(0,4.1,-2.65)],.035,10)
 bell((0,2.99,-2.65),.81)
 for side in (-1,1):
  tube('iron',[(side*1.75,5.7,-2.65),(side*.75,6.4,-2.65),(0,6.45,-2.65)],.045,10)
  block('stone',(side*1.52,.34,-3.85),(.57,.67,1.22),.035,7)
 # Funeral chest with a curved lid and carved panels; its scale is architectural.
 reliquary((0,.12,-4.0),1.0)
 for i in range(4):
  x=(i-1.5)*.71
  block('dark',(x,6.22,-depth+.42),(.31,1.42,.10),.0)
  arch('edge',.23,6.68,.62,.10,-depth+.52,-depth+.39,True,12)

def books(center,width=3.3,height=2.3):
 x,y,z=center
 for side in (-1,1):block('oak',(x+side*width*.5,y+height*.5,z),(.15,height,.61),.009,4)
 for row in range(4):
  yy=y+row*(height/3)
  block('oak',(x,yy,z),(width+.13,.12,.68),.009,row)
  if row==3:continue
  for i in range(12):
   xx=x-width*.45+i*(width*.90/12);h=.40+((i*7+row*3)%5)*.039
   block('leather',(xx,yy+.10+h*.5,z+.08),(.16,h,.37),.006,i+row*11)
   for dy in [-.10,.10]:block('bronze',(xx,yy+.10+h*.5+dy,z+.275),(.161,.022,.014),0)

def archive_interior(depth):
 # Raised archive stack on the far bank. Full stone basin, supported bridge.
 block('stone',(0,.36,-4.65),(3.78,.75,1.15),.025,3)
 books((0,.79,-4.61),3.32,2.5)
 for side in (-1,1):
  block('edge',(side*1.83,-.05,-2.30),(.28,.42,4.56),.018,4)
  block('dark',(side*1.84,-.58,-2.30),(.33,.78,4.56),.015,5)
 # A small genuine masonry bridge spans the water: deck, haunches and soffit.
 block('floor',(0,-.065,-1.32),(3.74,.18,1.08),.015,9)
 for side in (-1,1):block('stone',(side*1.39,-.34,-1.32),(.85,.54,1.08),.018,4)
 arch('stone',1.15,-.68,.48,.13,-.79,-1.86,False,18)
 # Face of the water-control sluice remains part of the bay's construction.
 for x in (-.55,-.28,0,.28,.55):tube('iron',[(x,.18,-3.82),(x,1.22,-3.82)],.026,8)
 block('iron',(0,1.16,-3.82),(1.42,.12,.13),.007,4)


def reliquary(center,scale=1):
 x,y,z=center
 def p(a,b,c):return (x+a*scale,y+b*scale,z+c*scale)
 block('stone',p(0,.14,0),(2.02*scale,.28*scale,1.07*scale),.027,12)
 block('dark',p(0,.44,0),(1.75*scale,.45*scale,.87*scale),.031,4)
 # Many profile stations make a carved barrel lid, not a plain box/cone.
 n=18;verts=[]
 for zz in (-.47,.47):
  for i in range(n+1):
   angle=math.pi*i/n;verts.append(p(math.cos(angle)*.93,.67+math.sin(angle)*.24,zz))
 faces=[]
 for i in range(n):faces.append((i,i+1,n+2+i,n+1+i))
 faces.extend([tuple(reversed(range(n+1))),tuple(n+1+i for i in range(n+1))]);mesh('stone',verts,faces)
 for xx in (-.62,0,.62):
  tube('bronze',[p(xx,.65,-.49),p(xx,.83,-.31),p(xx,.91,0),p(xx,.83,.31),p(xx,.65,.49)],.022*scale,8)
 for xx in (-.53,0,.53):
  block('edge',p(xx,.45,.452),(.30*scale,.26*scale,.035*scale),.009,7)
  tube('bronze',[p(xx-.08,.48,.482),p(xx,.36,.486),p(xx+.08,.48,.482)],.012*scale,8)


def ossuary_interior(depth):
 # Deep, carved burial shelves; the recesses hold actual lidded reliquaries.
 for row in range(2):
  yy=.16+row*1.53
  block('stone',(0,yy,-4.37),(3.76,.20,1.35),.020,row)
  for x in (-.98,.98):
   reliquary((x,yy+.14,-4.32),.82)
   block('dark',(x,yy+.82,-4.91),(1.67,1.05,.10),.0)
   # Nested carved reveals and vertical fluting, separate from pale bone props.
   for side in (-1,1):tube('edge',[(x+side*.87,yy+.13,-3.68),(x+side*.87,yy+1.15,-3.68),(x+side*.45,yy+1.45,-3.68),(x,yy+1.60,-3.68)],.04,8)
 for side in (-1,1):
  for i in range(4):
   zz=-.85-i*.96
   block('edge',(side*1.90,2.03,zz),(.15,2.86,.16),.009,i)
   block('stone',(side*1.90,.55,zz),(.27,.19,.29),.010,i)
 # A central stone shrine belongs to the bay floor, outside combat geometry.
 reliquary((0,.05,-1.30),1.22)


def citadel_interior(depth):
 # Fire is recessed more than two metres behind the heavy throat and iron grate.
 for z in (-.7,-1.0):arch('iron',1.57,1.48,1.43,.12,z+.05,z-.07,False,22)
 for i in range(9):
  x=(i-4)*.32
  top=2.77-abs(x)*.17
  tube('iron',[(x,.14,-1.20),(x,1.26,-1.29),(x,top,-1.24)],.044,10)
 for y in (.31,1.53,2.28):block('iron',(0,y,-1.26),(3.06,.13,.16),.008,1)
 for i in range(14):
  x=((i*7)%11-5)*.23;z=-3.45+(i%3)*.19
  block('ember',(x,.09+(i%4)*.045,z),(.33,.18,.30),.012,i)
 # Ducts and forged ties visually join the upper mass to the throat.
 for side in (-1,1):
  tube('iron',[(side*1.88,.40,-2.9),(side*1.88,3.45,-2.9),(side*.98,4.72,-3.3),(side*.98,6.54,-3.3)],.19,14)
  for y in (1.0,2.75,4.65):
   block('iron',(side*1.88,y,-2.9),(.50,.14,.49),.009,int(y))
 # Tall connected chimney shoulders and a visibly open flue crown.
 for side in (-1,1):
  block('stone',(side*1.28,7.75,-2.1),(.75,2.3,3.15),.027,7)
  block('stone',(0,7.75,-2.1+side*1.17),(1.85,2.3,.62),.022,3)
 block('dark',(0,7.75,-2.1),(1.8,.20,1.8),.020,1)


def crown(region):
 # High structural gallery links bays and crosses actual passages without
 # placing a low beam or any jamb into the walking / warning envelope.
 low=3.70;half=2.4;rise=[1.7,1.20,1.9,1.3][region];top=[8.1,6.65,7.7,8.5][region]
 arch('stone',half,low,rise,.43,.08,-1.10,region in (0,2))
 face_spandrel('stone',half,low+.05,rise+.05,top,-.10,-1.13,region in (0,2))
 vault('dark',half,low,rise,.22,-1.0,-4.80,region in (0,2))
 block('stone',(0,top-.25,-2.64),(4.80,.42,4.50),.022,region)
 block('edge',(0,top-.12,.02),(4.84,.18,.43),.015,4)
 if region==0:
  # Gallery arcading is carved into a deep, solid upper facade.
  for x in (-1.5,0,1.5):
   block('dark',(x,6.51,.145),(.99,1.0,.10),.004,2)
   for side in (-1,1):loft('edge',(x+side*.52,5.92,.21),[(0,.07,.07),(.70,.07,.07),(.79,.095,.095)],10,True)
   # individual arch transform is authored directly in the vertex buffer
   start={key:len(value[0]) for key,value in GROUPS.items()}
   arch('edge',.49,6.57,.61,.10,.23,.10,True,12)
   for key,(v,f) in GROUPS.items():
    for i in range(start.get(key,0),len(v)):v[i]=(v[i][0]+x,v[i][1],v[i][2])
 elif region==3:
  for y in (5.65,7.45):block('iron',(0,y,.17),(4.79,.21,.32),.006,1)
  for x in (-1.8,-.9,0,.9,1.8):tube('iron',[(x,5.6,.28),(x+.75,7.5,.28)],.075,10)
 elif region==2:
  for x in (-1.5,0,1.5):
   loft('edge',(x,5.55,.22),[(0,.14,.12),(.18,.20,.14),(.40,.20,.13),(.64,.14,.12)],12)


def solid(region):
 # Blind thick buttress used only for narrow safe intervals between passages.
 height=[7.6,6.1,7.3,8.1][region];depth=[5.3,5.65,5.3,6.0][region]
 base(depth,False)
 block('stone',(0,height*.5,-depth*.5),(4.79,height,depth),.040,region)
 for x in (-1.5,0,1.5):
  block('dark',(x,height*.46,.045),(.64,height*.55,.06),.015,2)
  for side in (-1,1):tube('edge',[(x+side*.38,.6,.14),(x+side*.38,height*.72,.14),(x,height*.81,.14)],.045,8)
 for y in (.34,height-.49,height-.18):block('edge',(0,y,.13),(4.80,.18,.48),.013,4)


def low_return(region):
 # Low camera-side construction with a real paved foundation and broken edge.
 depth=2.25;base(depth,False)
 height=[.95,.72,1.08,.84][region]
 block('stone',(0,height*.43,-.36),(4.8,height*.86,.87),.035,12)
 for i in range(5):
  x=-1.96+i*.97;h=height+(.10 if i in (0,3) else -.04)
  block('edge',(x,h,-.36),(.96,.18,1.07),.025,i)
 if region==3:
  for x in (-1.85,0,1.85):block('iron',(x,.55,.12),(.14,.83,.17),.007,2)


def export(name,build):
 global GROUPS
 GROUPS={};bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 build()
 total=0;bounds=[];surfaces=[]
 for (mat,smooth),(verts,faces) in GROUPS.items():
  if not verts:continue
  data=bpy.data.meshes.new(name+'_'+mat);data.from_pydata([xyz(p) for p in verts],[],faces);data.update()
  obj=bpy.data.objects.new(name+'__'+mat+('_curved' if smooth else ''),data);bpy.context.collection.objects.link(obj)
  target='stone' if mat in ('stone','edge','dark') else mat
  data.materials.append(material(target))
  if target=='stone':
   tint={'stone':.88,'edge':1.0,'dark':.56}[mat]
   colors=data.color_attributes.new(name='MasonryTint',type='FLOAT_COLOR',domain='CORNER')
   for color in colors.data:color.color=(tint,tint,tint,1)
  for face in data.polygons:face.use_smooth=smooth
  # Correct every closed/component surface normal before triangulation.
  bpy.context.view_layer.objects.active=obj;obj.select_set(True)
  bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT')
  obj.select_set(False)
 # Join hard and curved subparts per material into one draw surface.
 for mat in PALETTE:
  objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.data.materials[0].name=='environment_'+mat]
  if not objects:continue
  bpy.ops.object.select_all(action='DESELECT')
  for obj in objects:obj.select_set(True)
  bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();obj=bpy.context.object;obj.name=name+'__'+mat
  modifier=obj.modifiers.new('triangulated_surface','TRIANGULATE');bpy.ops.object.modifier_apply(modifier=modifier.name)
  total+=len(obj.data.polygons);surfaces.append(mat)
  # World-space texture materials use triplanar coordinates at runtime; include
  # regular UVs for the existing crafted wood/iron material as well.
  if not obj.data.uv_layers:obj.data.uv_layers.new(name='UVMap')
  uv=obj.data.uv_layers.active.data
  for face in obj.data.polygons:
   n=face.normal
   for li in face.loop_indices:
    p=obj.data.vertices[obj.data.loops[li].vertex_index].co
    uv[li].uv=(p.x,p.z) if abs(n.y)>=max(abs(n.x),abs(n.z)) else ((p.y,p.z) if abs(n.x)>abs(n.z) else (p.x,p.y))
  for v in obj.data.vertices:bounds.append((v.co.x,v.co.z,-v.co.y))
  obj.select_set(False)
 bpy.ops.object.select_all(action='SELECT')
 path=OUT/(name+'.glb')
 bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_materials='EXPORT',export_yup=True,export_animations=False,export_cameras=False,export_lights=False)
 mins=[min(p[i] for p in bounds) for i in range(3)];maxs=[max(p[i] for p in bounds) for i in range(3)]
 REPORT[name]={'triangles':total,'material_meshes':len(surfaces),'surfaces':surfaces,'bounds_min':mins,'bounds_max':maxs,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
 print('ENVIRONMENT',name,total,len(surfaces),mins,maxs,flush=True)

if __name__=='__main__':
 OUT.mkdir(parents=True,exist_ok=True)
 for region,prefix in enumerate(['spire','archive','ossuary','citadel']):
  for kind,fn in [('bay',bay_shell),('crown',crown),('solid',solid),('return',low_return)]:export(prefix+'_'+kind,lambda r=region,f=fn:f(r))
 manifest={'origin':'Original code-authored Blender geometry','generator':'tools/art/build_ruin_environment.py','generator_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'coordinates':'Godot Y-up metres; front faces +Z, bay depth extends -Z','textures':'Runtime uses existing documented stone maps and material-atlas textures; no new raster','models':REPORT}
 (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
