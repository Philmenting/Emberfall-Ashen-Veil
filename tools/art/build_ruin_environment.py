"""Original connected ruin construction for Emberfall 0.49.
Rebuild: blender -b -t 2 --python tools/art/build_ruin_environment.py
Thin load-bearing walls retain their deep openings; built wall feet, transverse
end walls and regional returns now connect them to immediate depth. UVs/metres
are local, Godot Y-up; TANGENT is
exported. Original code geometry; existing licensed/material provenance retained.
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
 'masonry':('cccccc',0,.94),'dressed_stone':('cccccc',0,.93),'paving':('cccccc',0,.95),'floor':('747774',0,.95),'iron':('535d61',.66,.74),'bronze':('786853',.58,.70),
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

from contextlib import contextmanager
from types import SimpleNamespace
from mathutils import Matrix
g=SimpleNamespace(mesh=mesh,block=block,loft=loft,tube=tube,arch=arch,arc_y=arc_y,vault=vault,xyz=xyz,GROUPS=GROUPS,MATS=MATS,material=material)
BASE_MESH=g.mesh
TX=Matrix.Identity(4)

def mesh(mat,vertices,faces,smooth=False):
 BASE_MESH(mat,[tuple(TX@Vector(v)) for v in vertices],faces,smooth)
g.mesh=mesh

@contextmanager
def at(x=0,y=0,z=0,angle=0):
 global TX
 old=TX.copy();TX=TX@Matrix.Translation(Vector((x,y,z)))@Matrix.Rotation(angle,4,'Y')
 try:yield
 finally:TX=old

def panel(mat,poly,depth=.4):
 # Vertical cross section, extruded backward in local Z; top is broken stone.
 n=len(poly);v=[(x,y,z) for z in (0,-depth) for x,y in poly]
 faces=[tuple(range(n)),tuple(reversed(range(n,n*2)))]
 faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
 mesh(mat,v,faces)

def floor_rect(x0,x1,z0,z1,y=-.02):
 mesh('paving',[(x0,y,z0),(x1,y,z0),(x1,y,z1),(x0,y,z1)],[(0,3,2,1)])

def footing(width=4.2,depth=3.3,basin=False):
 if basin:
  floor_rect(-2.1,-1.66,-4.55,.55)
  floor_rect(1.66,2.1,-4.55,.55)
  floor_rect(-1.66,1.66,-4.55,-4.28)
  floor_rect(-1.66,1.66,.12,.60)
  g.block('masonry',(0,-1.0,-2.08),(3.5,.20,4.65),.018,31)
  for side in (-1,1):
   g.block('masonry',(side*1.84,-.45,-2.08),(.35,.89,4.45),.014,33)
   for k in range(7):g.block('dressed_stone',(side*1.84,.015,.1-k*.65),(.43,.16,.635),.015,k)
 else:
  floor_rect(-width*.5,width*.5,-depth,.58)
  # The aisle stands on a shallow undercroft. Open load-bearing arches and
  # battered feet remain visible at an exposed join, never a paper floor edge.
  with at(y=-1.72,z=-depth+.16):
   g.arch('masonry',1.47,.18,.93,.30,.03,-.46,False,12)
   for side in (-1,1):
    g.block('masonry',(side*1.88,.71,-.12),(.43,1.72,.59),.028,16)
   g.block('dressed_stone',(0,1.61,-.13),(width,.22,.64),.018,16)
  for side in (-1,1):
   g.block('masonry',(side*(width*.5-.22),-.70,-depth*.5),(.45,1.38,depth),.021,17)
   g.block('masonry',(side*(width*.5-.30),-1.47,-depth*.5),(.60,.29,depth),.03,18)
 # One low wall foot; never a full-depth stand or raised paving platform.
 for side in (-1,1):
  g.block('masonry',(side*(width*.5-.20),.12,-depth*.5),(.48,.28,depth),.013,14)

def engaged_pier(x,spring,spire):
 if spire:
  rings=[(-.02,.38,.38),(.16,.39,.39),(.29,.30,.31),(.43,.25,.26),(spring-.32,.25,.26),(spring-.22,.33,.35),(spring,.37,.37)]
  g.loft('dressed_stone',(x,0,.08),rings,10)
  for dx,dz in [(-.23,.03),(.23,.03),(0,.24)]:
   g.loft('dressed_stone',(x+dx,0,dz+.05),[(.24,.075,.075),(.37,.095,.095),(spring-.2,.084,.084),(spring-.05,.13,.12)],8,True)
 else:
  g.block('masonry',(x,spring*.5,-.13),(.58,spring,.65),.018,6)
  g.block('dressed_stone',(x,.13,.03),(.75,.27,.84),.019,3)
  g.block('dressed_stone',(x,spring-.02,.03),(.72,.20,.78),.017,5)

def opening_wall(spire=True,variant=0,back=False,settings=None):
 half=1.65 if spire else 1.58;spring=3.1 if spire else 2.05;rise=2.05 if spire else 1.34
 crest=6.3 if spire else 4.5;depth=.43 if spire else .57
 if settings:
  half=settings['half'];spring=settings['spring'];rise=settings['rise'];crest=settings['crest'];depth=settings['depth']
 # Elevation is a wall, not a capped 5m deep solid. Broken silhouette is authored.
 profile=[crest+.2,crest+.24,crest-.20,crest-.2,crest-.78,crest-.63,crest-.63,crest-.08,crest-.16]
 if variant%2:profile=list(reversed([p-.55 for p in profile]))
 segments=24;xs=[-2.1+4.2*i/segments for i in range(segments+1)]
 def height(x):
  q=(x+2.1)/4.2*(len(profile)-1);a=min(len(profile)-2,int(q));return profile[a]*(1-(q-a))+profile[a+1]*(q-a)
 for i in range(segments):
  a,b=xs[i:i+2]
  def inner(x):return g.arc_y(x,half,spring,rise,spire)+.16 if abs(x)<half+.02 else 0
  lo1,lo2=inner(a),inner(b);hi1,hi2=height(a),height(b)
  if max(lo1,lo2)>=min(hi1,hi2):continue
  panel('masonry',[(a,lo1),(b,lo2),(b,hi2),(a,hi1)],depth)
 # Cut coping blocks follow the true wall thickness and variable crown, .5m scale.
 for i in range(8):
  x=-1.85+i*.53;h=height(x)
  g.block('dressed_stone',(x,h+.025,-depth*.5),(.50,.13,depth+.12),.023,variant*13+i)
 g.arch('dressed_stone',half,spring,rise,.25,.16,-depth-.07,spire,18)
 for side in (-1,1):engaged_pier(side*1.88,spring,spire)
 # Recessed single upper lancet rises with the remaining pier rather than a box cap.
 if spire and variant==0:
  with at(x=-1.84,y=0,z=-.22):
   g.loft('dressed_stone',(0,0,0),[(spring,.16,.21),(crest-.4,.12,.16),(crest+.5,.065,.1),(crest+.62,.018,.022)],8)

def buttress(x,depth,height):
 # Unequal stepped and sloping load-bearing section, 0.65–1m thick.
 with at(x=x,z=-.44):
  for level,(yy,hh,out) in enumerate([(0,.50,.9),(.50,1.35,.72),(1.85,1.75,.49),(3.60,max(.1,height-3.6),.32)]):
   g.block('masonry',(0,yy+hh*.5,-out*.5),(.66,hh,out),.016,level)
  panel('dressed_stone',[(-.39,height-.05),(.39,height-.05),(.26,height+.10),(-.26,height+.14)],.45)

def spire_bay(variant=0,close_end=False):
 footing(depth=3.35)
 opening_wall(True,variant)
 # Back enclosure has a second actual opening; it is not a black wall prop.
 with at(z=-3.35):opening_wall(True,(variant+1)%2,True)
 if close_end:
  with at(x=-2.10,z=-.24,angle=math.pi*.5):
   panel('masonry',[(-3.11,0),(0,0),(0,5.6),(-.62,5.95),(-1.50,5.70),(-3.11,6.2)],.40)
 for x in (-1.94,1.94):buttress(x,3.4,5.35)
 # Broken springing survives over the side aisle; no sheet spans the central path.
 for z in (-.52,-2.92):
  g.arch('dressed_stone',1.57,3.25,2.0,.17,z+.10,z-.11,True,16)
 # Narrow supported walk along rear gallery; open boards/stone coping distinguish it.
 floor_rect(-2.07,2.07,-3.34,-2.48,3.29)
 g.block('dressed_stone',(0,3.20,-2.86),(4.14,.19,.92),.014,3)
 for x in (-1.62,1.52):
  with at(x=x,z=-2.51):panel('dressed_stone',[(-.14,2.58),(.14,2.58),(.31,3.2),(-.31,3.2)],.60)
 if variant==0:
  # One retained bell belongs to the load-bearing bay, not every module.
  g.block('iron',(0,4.15,-1.85),(3.2,.15,.13),.005,1)
  g.tube('iron',[(0,4.10,-1.85),(0,3.53,-1.85)],.025,6)
  g.loft('bronze',(0,2.98,-1.85),[(0,.42,.42),(.07,.44,.44),(.13,.35,.35),(.54,.22,.22),(.62,.16,.16),(.68,.1,.1)],16)

def archive_bay(variant=0,close_end=False):
 footing(depth=4.55,basin=True)
 opening_wall(False,variant)
 # Real water rectangle exactly matches the current basin-hole contract.
 # Animated basin surface is supplied once by RuinArchitecture._basin.
 # Segmental masonry bridge: actual shallow arch, supported by the side banks.
 g.arch('dressed_stone',1.74,-.60,.46,.12,-.63,-1.63,False,14)
 floor_rect(-1.84,1.84,-1.68,-.61,-.02)
 for side in (-1,1):g.block('dressed_stone',(side*1.76,-.25,-1.14),(.25,.50,1.17),.012,2)
 # Deep raised retaining stack wall with masonry shelves, dry above the basin.
 with at(z=-4.43):
  panel('masonry',[(-2.1,-.85),(2.1,-.85),(2.1,5.15),(1.2,5.35),(.4,5.02),(-.4,5.19),(-1.2,5.35),(-2.1,4.95)],.58)
 for x in (-1.85,0,1.85):g.block('dressed_stone',(x,2.48,-4.12),(.22,4.30,.34),.01,4)
 for row in range(4):
  yy=.56+row*.84
  g.block('dressed_stone',(0,yy,-3.93),(3.86,.15,.82),.012,row)
  # Volumes occur in weight-bearing groups and fallen folios, not an even
  # picket fence. Empty gaps expose the true shelf depth at ordinary scale.
  for k in range(10):
   if (k+row*2+variant)%7==0:continue
   x=-1.62+k*.345;h=.32+.18*((k*7+row*3)%5)/4
   simple_block('oak',(x,yy+.09+h*.5,-4.04),(.19,h,.31))
   for dx in [-.104,.104]:simple_block('oak',(x+dx,yy+.09+h*.5,-4.03),(.025,h+.025,.35))
  if row in (0,2):
   for k in range(2):
    simple_block('oak',(-1.60+((row+variant)%3)*.70,yy+.13+k*.075,-3.83),(.49,.065,.43))
 # Wetload buttress and uneven rear coping, not repeated huge blank piers.
 for side in (-1,1):
  with at(x=side*2.02,z=-4.01):panel('masonry',[(-.3,0),(.3,0),(.22,4.6),(-.22,4.7)],.62)
 if close_end:
  with at(x=-2.10,z=-.42,angle=math.pi*.5):panel('masonry',[(-4.06,-.6),(0,-.6),(0,3.8),(-.8,4.2),(-2.2,4.4),(-4.06,4.65)],.51)
 # Sluice bars at basin head belong to the channel structure.
 for x in (-1.1,-.72,-.34,.04,.42,.8,1.18):g.tube('iron',[(x,-.70,-3.18),(x,.15,-3.18)],.026,6)


def simple_block(mat,center,size):
 x,y,z=center;sx,sy,sz=[v*.5 for v in size]
 verts=[(x+a*sx,y+b*sy,z+c*sz) for a,b,c in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
 mesh(mat,verts,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(3,7,6,2),(0,4,7,3),(1,2,6,5)])
def burial_cell(cx,cy,variant):
 # A carved recess with a real back, soffit and lower ledge; no bone-cone proxy.
 with at(x=cx,y=cy,z=-3.30):
  half=.48;spring=.62;rise=.40
  for side in (-1,1):g.block('masonry',(side*.57,.64,-.28),(.20,1.28,.66),.012,variant)
  g.block('masonry',(0,.65,-.65),(1.05,1.30,.14),.008,variant)
  g.arch('dressed_stone',half,spring,rise,.12,.12,-.66,False,10)
  g.block('dressed_stone',(0,.03,-.27),(1.12,.13,.84),.015,3)
  g.loft('dressed_stone',(0,.12,-.30),[(0,.19,.15),(.07,.22,.17),(.34,.21,.16),(.46,.14,.12),(.51,.12,.10),(.55,.17,.14)],12,True)

def ossuary_bay(variant=0,close_end=False):
 footing(depth=3.80)
 opening_wall(False,variant,settings={'half':1.72,'spring':1.70,'rise':1.72,'crest':4.80,'depth':.65})
 # Heavy carved burial walls are the enclosure, rather than a shelf prop.
 for row in range(2):
  for col in range(3):burial_cell(-1.28+col*1.28,.35+row*1.68,row*5+col+variant)
 with at(z=-3.89):panel('masonry',[(-2.1,0),(2.1,0),(2.1,4.45),(1.2,4.68),(.35,4.38),(-.5,4.57),(-1.3,4.47),(-2.1,4.68)],.43)
 for side in (-1,1):
  with at(x=side*1.98,z=-.38):panel('masonry',[(-.19,0),(.19,0),(.14,3.92),(-.14,4.06)],3.28)
 for z in (-.68,-3.20):g.arch('dressed_stone',1.69,1.88,1.75,.20,z+.13,z-.12,False,16)
 # A built burial casket: inset long panel, joined stone corners, pitched lid.
 # The front tablet sits behind its frame, leaving a genuine shallow reveal.
 with at(z=-2.83):
  g.block('dressed_stone',(0,.12,0),(1.67,.23,.95),.018,6)
  for side in (-1,1):
   g.block('dressed_stone',(side*.71,.34,0),(.21,.39,.79),.018,7)
   g.block('dressed_stone',(0,.34,side*.31),(1.25,.32,.13),.012,8)
   g.block('dressed_stone',(0,.49,side*.39),(1.26,.09,.14),.01,9)
  g.block('dressed_stone',(0,.33,.376),(.95,.20,.045),.005,10)
  section=[(-.83,.52),(.83,.52),(.83,.61),(.64,.65),(.35,.79),(-.42,.77),(-.66,.64),(-.83,.61)]
  with at(z=.47):panel('dressed_stone',section,.94)

def chimney(cx,height):
 # Open flue rather than a solid cube or a bright painted roof cap.
 for side in (-1,1):
  g.block('masonry',(cx+side*.43,height*.5,-3.80),(.26,height,1.12),.02,7)
  g.block('masonry',(cx,height*.5,-3.80+side*.43),(.63,height,.26),.02,5)
 for side in (-1,1):
  g.block('dressed_stone',(cx+side*.43,height,-3.80),(.34,.18,1.16),.017,2)
  g.block('dressed_stone',(cx,height,-3.80+side*.43),(.65,.18,.34),.017,3)

def citadel_bay(variant=0,close_end=False):
 footing(depth=4.42)
 opening_wall(False,variant,settings={'half':1.67,'spring':2.06,'rise':.68,'crest':4.34,'depth':.69})
 # Structural furnace chamber recessed behind the load-bearing front arcade.
 with at(z=-2.1):
  for side in (-1,1):g.block('masonry',(side*1.58,1.2,-.93),(.50,2.40,2.28),.028,9)
  g.vault('masonry',1.29,1.35,1.00,.27,.04,-2.17,False)
  g.arch('dressed_stone',1.29,1.35,1.00,.25,.16,-.22,False,16)
  g.block('masonry',(0,1.12,-2.12),(2.80,2.24,.32),.02,6)
  for k in range(12):
   x=-1.15+k*.21;g.tube('iron',[(x,.12,.04),(x,1.45+.57*math.sqrt(max(0,1-(x/1.25)**2)),.04)],.033,6)
  for y in (.42,1.35):g.block('iron',(0,y,.06),(2.47,.065,.07),.006,4)
  for k in range(6):g.block('ember',(-.91+k*.37,.20,-1.18+(k%2)*.2),(.29,.18,.48),.02,k)
 chimney(-1.44,6.13 if variant==0 else 5.64)
 chimney(1.44,5.57 if variant==0 else 6.31)
 # Narrow iron maintenance walk, carried by the kiln sides, stays inside the bay.
 g.block('iron',(0,3.21,-2.97),(3.87,.15,.77),.009,3)
 for side in (-1,1):
  g.block('iron',(side*1.96,2.21,-2.61),(.12,2.14,.12),.003,2)
  g.block('iron',(side*1.96,3.89,-2.61),(.075,1.20,.075),.003,1)
 for y in (3.53,4.03):g.block('iron',(0,y,-2.61),(3.97,.055,.055),.003,7)

def narrow_remnant(region):
 # A narrow interval is a torn wall/pier, never a compressed deep bay-box.
 heights=[4.5,3.4,3.85,4.25];h=heights[region]
 panel('masonry',[(-2.10,0),(2.10,0),(2.10,h-.30),(1.17,h-.22),(.83,h+.08),(.14,h-.08),(-.49,h-.43),(-1.26,h-.12),(-2.1,h-.21)],.68)
 for x in (-1.65,-.8,.06,.92,1.73):g.block('dressed_stone',(x,.16,-.24),(.78,.30,.84),.023,3)
 floor_rect(-2.10,2.10,-.72,.56)

def retaining_return():
 # A common load-bearing section, not the visible identity: a ledge continuing
 # below the aisle with a battered toe and interrupted coping.
 floor_rect(-2.10,2.10,-.74,.58)
 g.block('masonry',(0,-.70,-.43),(4.2,1.39,.67),.027,49)
 g.block('masonry',(0,-1.45,-.56),(4.2,.26,.91),.038,51)
 for x,ww,h in [(-1.64,.88,.12),(-.54,1.19,.09),(.79,1.36,.13),(1.83,.50,.06)]:
  g.block('dressed_stone',(x,h*.5,-.31),(ww,h,.77),.022,31)

def low_return(region):
 retaining_return()
 if region==0:
  # Funeral gallery: broad casket seat, mortised stone standards, iron field.
  for x,h in [(-1.88,1.18),(.72,.86)]:
   g.block('masonry',(x,h*.5,-.34),(.37,h,.53),.025,41)
   g.block('dressed_stone',(x,h+.035,-.33),(.48,.13,.65),.02,43)
  g.block('masonry',(-.51,.17,-.39),(2.15,.33,.68),.02,44)
  g.block('dressed_stone',(-.51,.36,-.39),(2.24,.16,.79),.021,45)
  for x in [-1.56,-1.10,-.64,-.18,.28]:
   g.tube('iron',[(x,.43,-.37),(x,.93-(x+1.56)*.08,-.37)],.027,6)
  g.tube('iron',[(-1.65,.86,-.37),(.49,.69,-.37)],.037,6)
  # The torn end is a real shallow diagonal break, not a row of square blocks.
  panel('masonry',[(.94,0),(2.1,0),(2.1,.21),(1.64,.28),(1.49,.49),(.94,.62)],.66)
 elif region==1:
  # A sluice bank with open culvert, recessed gate guides and an interrupted lip.
  with at(x=-.46,y=-.12,z=.02):
   g.arch('dressed_stone',.76,.13,.47,.18,.13,-.91,False,10)
   for side in (-1,1):g.block('masonry',(side*.94,.24,-.39),(.35,.74,1.00),.022,54)
  for x in [-1.13,-.91,-.69,-.47,-.25,-.03,.19]:
   g.tube('iron',[(x,-.33,-.38),(x,.43,-.38)],.024,6)
  g.block('iron',(-.47,.40,-.38),(1.47,.08,.08),.005,3)
  for x,h in [(1.18,.61),(1.74,.43),(-1.87,.71)]:
   g.block('masonry',(x,h*.5,-.34),(.60,h,.68),.025,55)
   g.block('dressed_stone',(x,h+.02,-.34),(.67,.10,.77),.02,56)
 elif region==2:
  # A burial sill with a recessed long cell and surviving rounded shoulder.
  g.block('masonry',(-.26,.21,-.40),(2.80,.39,.65),.020,61)
  g.block('dressed_stone',(-.26,.47,-.42),(2.92,.19,.80),.025,63)
  for x in [-1.81,1.25]:
   g.block('masonry',(x,.47,-.38),(.32,.91,.70),.023,64)
   g.block('dressed_stone',(x,.97,-.38),(.45,.16,.82),.018,65)
  # Carved recess is backed and deep, a surviving wall, not a floating coffin.
  g.block('masonry',(-.26,.75,-.70),(2.78,.44,.16),.014,66)
  with at(x=-.26,y=.60,z=-.15):
   g.arch('dressed_stone',1.31,.08,.37,.13,.04,-.55,False,12)
  panel('masonry',[(1.51,0),(2.1,0),(2.1,.18),(1.87,.35),(1.51,.39)],.65)
 else:
  # A maintenance trench: the cover is an actual split grate over an open duct.
  for x in [-1.87,1.84]:g.block('masonry',(x,.28,-.36),(.45,.55,.72),.027,72)
  for z in [-.68,-.04]:g.block('iron',(-.05,.27,z),(3.51,.12,.09),.005,73)
  for x in [-1.68,-1.37,-1.06,-.75,-.44,-.13,.18,.80,1.11,1.42,1.71]:
   g.block('iron',(x,.31,-.35),(.075,.10,.65),.004,74)
  for x in [-1.76,1.73]:
   g.block('iron',(x,.72,-.40),(.10,.82,.10),.004,75)
  g.tube('iron',[(-1.76,1.10,-.40),(-.48,1.10,-.40)],.047,8)
  g.tube('iron',[(.52,.83,-.40),(1.73,.83,-.40)],.047,8)

def end_wall(region):
 # The exposed end of an aisle has thickness, a real passage and a broken
 # upper edge. Its narrow footprint joins the last bay without a large end box.
 depth=[3.35,4.55,3.80,4.42][region]
 half=[.87,1.03,.92,.99][region]
 spring=[2.35,1.45,1.64,1.72][region]
 rise=[1.15,.73,.93,.55][region]
 height=[4.60,3.12,3.57,3.04][region]
 bank=region==1
 skin=.20 if bank else .39
 with at(x=.08 if bank else .20,z=-depth*.5,angle=math.pi*.5):
  width=depth*.5
  for side in (-1,1):
   a=side*half;b=side*width
   x0,x1=min(a,b),max(a,b)
   panel('masonry',[(x0,-1.38),(x1,-1.38),(x1,height-.23),(x0,height-.02)],skin)
   g.block('dressed_stone',((a+b)*.5,.12,-.08 if bank else -.15),(abs(b-a)+.07,.24,.28 if bank else .60),.012 if bank else .019,88)
  face_spandrel('masonry',half,spring,rise,height,.0,-skin,region==0)
  g.arch('dressed_stone',half,spring,rise,.21,.03 if bank else .10,-.24 if bank else -.50,region==0,14)
  for i,x in enumerate([-width+.21,-half*.55,half*.34,width-.20]):
   hh=height-.12-.11*math.sin(i*2.9)
   g.block('dressed_stone',(x,hh,-.09 if bank else -.19),(.42,.16,.28 if bank else .49),.018 if bank else .03,i)
  g.block('masonry',(0,-1.32,-.08 if bank else -.17),(depth,.30,.31 if bank else .75),.016 if bank else .026,91)
 # Floor through the service opening shares the exact court shader.
 if bank:
  # The transverse bank never adds a stone sheet across the basin opening.
  floor_rect(-.16,.15,-depth,-4.28)
  floor_rect(-.16,.15,.12,.39)
 else:floor_rect(-.53,.28,-depth,.39)

def reset():
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 g.GROUPS.clear()

def export(name):
 stats={};bounds=[]
 for (family,smooth),(verts,faces) in g.GROUPS.items():
  m=bpy.data.meshes.new(name+'_'+family);m.from_pydata([g.xyz(v) for v in verts],[],faces);m.update()
  obj=bpy.data.objects.new(name+'_'+family,m);bpy.context.collection.objects.link(obj)
  mat=g.material(family)
  obj.data.materials.append(mat)
  bpy.context.view_layer.objects.active=obj;obj.select_set(True)
  bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT')
  if family in ('paving','water'):
   for face in m.polygons:
    if face.normal.z<0:face.flip()
   m.update()
  mod=obj.modifiers.new('triangulation','TRIANGULATE');bpy.ops.object.modifier_apply(modifier=mod.name)
  uv=obj.data.uv_layers.new(name='UVMetres')
  for face in obj.data.polygons:
   n=face.normal;gy=n.z;gx=n.x;gz=-n.y
   # Signed dominant-plane local METRES, never normalized per object bounds.
   for li in face.loop_indices:
    p=obj.data.vertices[obj.data.loops[li].vertex_index].co;x,y,z=p.x,p.z,-p.y
    if abs(gy)>.70:u,v=x,-z*(1 if gy>=0 else -1)
    elif abs(gx)>abs(gz):u,v=-z*(1 if gx>=0 else -1),y
    else:u,v=x*(1 if gz>=0 else -1),y
    uv.data[li].uv=(u,v)
   face.use_smooth=smooth
  stats[family]=stats.get(family,0)+len(m.polygons)
  bounds.extend(verts);obj.select_set(False)
 # Join by family even when some primitives used smooth normals.
 for family in sorted(set(k[0] for k in g.GROUPS)):
  objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.data.materials[0].name=='environment_'+family]
  bpy.ops.object.select_all(action='DESELECT')
  for o in objects:o.select_set(True)
  bpy.context.view_layer.objects.active=objects[0]
  if len(objects)>1:bpy.ops.object.join()
  objects[0].name=name+'__'+family
 bpy.ops.object.select_all(action='SELECT')
 path=OUT/(name+'.glb')
 bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_materials='EXPORT',export_tangents=True,export_animations=False,export_cameras=False,export_lights=False)
 return {'file':str(path.relative_to(ROOT)),'triangles_by_surface':stats,'triangles':sum(stats.values()),'material_meshes':len(stats),'surfaces':list(stats),'uv_units':'local metres','tangents_exported':True,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'bounds_min':[min(p[i] for p in bounds) for i in range(3)],'bounds_max':[max(p[i] for p in bounds) for i in range(3)]}

if __name__=='__main__':
 OUT.mkdir(parents=True,exist_ok=True)
 report={}
 for region,(prefix,fn) in enumerate([('spire',spire_bay),('archive',archive_bay),('ossuary',ossuary_bay),('citadel',citadel_bay)]):
  for kind in ['bay','bay_broken','solid','return','end']:
   reset()
   if kind.startswith('bay'):fn(1 if kind=='bay_broken' else 0,False)
   elif kind=='solid':narrow_remnant(region)
   elif kind=='return':low_return(region)
   else:end_wall(region)
   key=prefix+'_'+kind;report[key]=export(key);print('ENVIRONMENT',key,report[key]['triangles'],report[key]['material_meshes'],flush=True)
 manifest={'origin':'Original code-authored Blender geometry','version':'0.49','generator':'tools/art/build_ruin_environment.py','generator_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'authoring_tool':'Blender '+bpy.app.version_string,'rebuild_command':'blender -b -t 2 --python tools/art/build_ruin_environment.py','source_license_record':'assets/models/environment/LICENSE-SOURCE.txt','runtime_construction':'scripts/ruin_architecture.gd','runtime_construction_sha256':hashlib.sha256((ROOT/'scripts/ruin_architecture.gd').read_bytes()).hexdigest(),'runtime_contract':'Per-part authoritative passage clearance before batching. Union-only stepped ground joins, paired internal end profiles removed, open basin cuts. Guardian room 5 has no camera-near return in any region, reserving the full danger envelope without dynamic culling.','coordinates':'Godot Y-up metres; front +Z; depth -Z. UVMetres uses signed dominant planar axes in local metres, with glTF TANGENT exported.','materials':'Separate masonry and dressed_stone use the shared three-sampler UV shader; paving uses the identical court material. Existing documented CC0 and original textures, no new raster or third-party model.','models':report}
 (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
