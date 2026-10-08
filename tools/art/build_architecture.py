"""Original carved cathedral kit. blender -b -t 2 --python tools/art/build_architecture.py"""
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
from build_characters import *

PALETTE.update({'stone':('666a69',0,.94),'edge':('959389',0,.89),'recess':('363e3d',0,.98)})

def block(mat, center, size, bevel=.035):
    bpy.ops.mesh.primitive_cube_add(size=1,location=xyz(center))
    obj=bpy.context.object
    obj.scale=Vector((size[0],size[2],size[1]))
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    modifier=obj.modifiers.new('Chipped rolled edges','BEVEL')
    modifier.width=bevel; modifier.segments=2
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    # Apply transforms: all exported objects use their origin at the root.
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    obj.data.materials.append(material(mat))
    PARTS[('Body',mat)].append(obj)

def pillar(height=4):
    loft('Body','stone',[(0,.57,.57,0),(.10,.57,.57,0),(.16,.50,.50,0),(.24,.49,.49,0),(.31,.43,.43,0),(.36,.44,.44,0)],sides=8)
    loft('Body','edge',[(.36,.44,.44,0),(.40,.44,.44,0),(.45,.35,.35,0),(.49,.33,.33,0)],sides=16)
    loft('Body','stone',[(.45,.29,.29,0),(height+.4,.29,.29,0)],sides=24)
    for i in range(8):
        a=TAU*i/8
        x,z=math.sin(a)*.25,math.cos(a)*.25
        loft('Body','edge',[(.46,.069,.069,0),(.56,.066,.066,0),(height+.30,.066,.066,0),(height+.40,.09,.09,0)],(x,0,z),16)
        if height>2:
            leaf('Body','edge',[(x,height+.30,z),(x*1.4,height+.5,z*1.4),(x*1.5,height+.65,z*1.5)],.075,.025)
    loft('Body','edge',[(height+.40,.34,.34,0),(height+.49,.38,.38,0),(height+.59,.45,.45,0),(height+.67,.45,.45,0)],sides=8)
    block('stone',(0,height+.74,0),(.82,.14,.82),.055)

def arch():
    # Gothic pointed arch, three continuous nested stone ribs.
    for side in [-1,1]:
        block('stone',(side*2.02,1.75,0),(.40,3.5,.50))
        for z in [-.20,.20]:
            tube('Body','edge',[(side*1.83,.12,z),(side*1.83,3.50,z),(side*1.56,4.15,z),
                (side*.94,4.81,z),(0,5.46,z)],.067,12,9)
        for i in range(9):
            # Broad voussoirs follow the actual pointed curve and have softened edges.
            t0=i/9; t1=(i+1)/9
            def point(t,r):
                # circular branches, centres opposite sides, meet in a pointed apex
                angle=math.acos(.5)*t
                return (side*(4.0*math.cos(angle)-2.0)+side*r*math.cos(angle),
                        3.5+2.25*math.sin(angle)+r*math.sin(angle),0)
            p0,p1,p2,p3=point(t0,0),point(t1,0),point(t1,.26),point(t0,.26)
            verts=[(p[0],p[1],z) for z in [-.24,.24] for p in [p0,p1,p2,p3]]
            obj=mesh('Body','stone',verts,[(0,1,2,3),(7,6,5,4),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)],False)
            bevel=obj.modifiers.new('Stone edge wear','BEVEL'); bevel.width=.02; bevel.segments=2
        for a in range(5):
            leaf('Body','edge',[(side*2.0,3.42,-.25),(side*(2.0+(a-2)*.04),3.67,-.33),(side*(2.0+(a-2)*.065),3.74,-.26)],.045,.025)
    gem('Body',(0,5.49,-.31),.10,'soul')

def tomb():
    block('recess',(0,.27,0),(.93,.54,2.16),.10)
    block('stone',(0,.58,0),(1.02,.12,2.29),.075)
    block('edge',(0,.70,0),(1.08,.14,2.36),.055)
    # Recumbent carved effigy. Raised cloak, helmet, hands and ceremonial blade.
    ellipsoid('Body','stone',(0,.79,-.64),(.14,.11,.17),24,12)
    ellipsoid('Body','stone',(0,.81,-.17),(.25,.12,.31),24,12)
    leaf('Body','stone',[(0,.80,-.07),(0,.86,.31),(0,.81,.83)],.28,.07)
    for side in [-1,1]:
        tube('Body','edge',[(side*.22,.84,-.37),(side*.19,.93,-.12),(side*.04,.97,.01)], [.057,.048,.035],10,6)
        for i in range(3): tube('Body','edge',[(side*.04,.88,.18),(side*(.10+i*.05),.87,.46),(side*(.10+i*.06),.79,.89)],.008,6,5)
    tube('Body','edge',[(0,.98,-.03),(0,.94,.33),(0,.87,.71)],.018,8,5)
    for side in [-1,1]: tube('Body','edge',[(0,.97,.06),(side*.12,.97,.1)],.024,8,3)
    for x in [-.39,.39]:
        for z in [-.76,-.25,.25,.76]:
            ring('Body','edge',(x,.32,z),.11,.19,.018,'z')

def hanging_bell():
    bell_head('Body',0,.84,True)
    tube('Body','dark',[(0,.41,0),(0,-.23,0)],.045,12,4)
    ellipsoid('Body','bronze',(0,-.22,0),(.09,.105,.09))

def bone_arch():
    block('recess',(0,.14,0),(1.05,.28,1.65),.07)
    for z in [0,.75]:
        tube('Body','bone',[(0,.25,z),(.04,1.15,z),(.26,2.28,z),(.94,3.35,z),(1.73,4.21,z+.09)], [.23,.20,.145,.088,.005],16,9)
        for i in range(4):
            t=i/4
            x=.1+t*t*.95;y=1.1+t*2.1
            leaf('Body','bone',[(x,y,z),(x-.24,y+.15,z+.025),(x-.30,y+.35,z+.04)],.085,.040)
        ring('Body','bronze',(.015,.58,z),.23,.23,.018)

def furnace():
    loft('Body','recess',[(0,.76,.88,0),(.15,.78,.90,0),(.25,.70,.82,0),(1.6,.70,.82,0),(1.84,.58,.71,0)],sides=24)
    for y in [.20,1.65,1.82]: ring('Body','bronze',(0,y,0),.75,.87,.043)
    # Arched fire mouth has an actual rolled iron rim and bent grate.
    ellipsoid('Body','ember',(0,.84,-.82),(.46,.51,.016))
    tube('Body','bronze',[(-.48,.32,-.80),(-.50,.91,-.81),(-.33,1.31,-.81),(0,1.43,-.81),(.33,1.31,-.81),(.50,.91,-.81),(.48,.32,-.80)],.052,12,7)
    for i in range(7):
        x=(i-3)*.135
        tube('Body','iron',[(x,.36,-.858),(x,.8,-.876),(x,1.36-abs(x)*.48,-.858)],.021,8,4)
    loft('Body','iron',[(1.82,.40,.46,.13),(2.0,.35,.40,.13),(2.90,.25,.29,.13),(3.15,.32,.36,.13),(3.24,.32,.36,.13)],sides=24)
    for i in range(8):
        a=TAU*i/8
        tube('Body','bronze',[(math.sin(a)*.36,1.9,math.cos(a)*.43+.13),(math.sin(a)*.24,2.85,math.cos(a)*.28+.13)],.014,8,3)

def well():
    loft('Body','stone',[(0,.68,.68,0),(.09,.68,.68,0),(.17,.59,.59,0),(.32,.62,.62,0),(.54,.74,.74,0),(.60,.76,.76,0),(.65,.73,.73,0),(.65,.61,.61,0),(.54,.60,.60,0),(.24,.48,.48,0)],sides=32,closed_profile=True)
    for y,r in [(.1,.66),(.57,.75)]: ring('Body','edge',(0,y,0),r,r,.032)
    loft('Body','soul',[(.31,.57,.57,0),(.32,.57,.57,0)],sides=48)
    for i in range(8):
        a=TAU*i/8
        leaf('Body','edge',[(math.sin(a)*.60,.21,math.cos(a)*.60),(math.sin(a)*.69,.37,math.cos(a)*.69),(math.sin(a)*.71,.53,math.cos(a)*.71)],.075,.025)

for name,build in [('pillar',pillar),('broken_pillar',lambda:pillar(1.3)),('gothic_arch',arch),('carved_tomb',tomb),('hanging_bell',hanging_bell),('bone_arch',bone_arch),('furnace',furnace),('pilgrim_well',well)]:
    # build_characters.export resets its PARTS dictionary. Resolve the current
    # dictionary here as well so cube and curved surfaces join into one batch.
    import build_characters as author
    def wrapped(b=build):
        globals()['PARTS']=author.PARTS
        b()
    export(name,wrapped)
