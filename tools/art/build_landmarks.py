"""Original region silhouettes. blender -b -t 2 --python tools/art/build_landmarks.py"""
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
from build_characters import *
import build_characters as author
PALETTE.update({'stone':('626b71',0,.88),'edge':('919991',0,.79),'recess':('242e35',0,.96)})

def block(mat,at,size):
    bpy.ops.mesh.primitive_cube_add(size=1,location=xyz(at))
    obj=bpy.context.object
    obj.name='Body__'+mat
    obj.scale=(size[0],size[2],size[1])
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    bevel=obj.modifiers.new('Worn carved edges','BEVEL');bevel.width=.035;bevel.segments=2
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    # export() replaces the registry for every model. Resolve it on the module,
    # otherwise these blocks miss material joining after the first reset.
    obj.data.materials.append(material(mat));author.PARTS[('Body',mat)].append(obj)

def ruined_vault():
    for z in [-.5,.5]:
        for side in [-1,1]:
            loft('Body','stone',[(0,.30,.30,0),(.2,.37,.37,0),(.35,.22,.22,0),(2.9,.22,.22,0),(3.1,.29,.29,0)],(side*2.65,0,z),12)
            end=7 if side<0 else 5
            points=[(side*(2.65-i*.32),3.05+i*.19,z) for i in range(end)]
            tube('Body','edge',points,.15,10,3)
    block('stone',(0,.13,0),(6.4,.26,1.6))
    for i in range(5):
        block('stone',(-1.5+i*.63,.3,.55),( .40,.32,.42))
        ring('Body','bronze',(-1.5+i*.63,.47,.55),.16,.13,.016)

def drowned_library():
    for x in [-2.35,0,2.35]:
        for side in [-1,1]: block('stone',(x+side*.94,1.6,0),(.15,3.2,.68))
        for y in [.25,1.15,2.05,2.95]: block('leather',(x,y,-.06),(1.9,.11,.67))
        for row in range(3):
            for book in range(8):
                h=.42+(book*7+row*3)%5*.07
                bx=x-.77+book*.21
                color=['wine','sage','linen','violet','leather'][(book+row)%5]
                block(color,(bx,.36+row*.9+h*.5,-.08),(.13,h,.36))
                block('gold',(bx,.42+row*.9,-.273),(.135,.016,.008))
                block('gold',(bx,.29+row*.9+h,-.273),(.135,.016,.008))
        tube('Body','bronze',[(x-.9,3.05,-.38),(x,3.52,-.38),(x+.9,3.05,-.38)],.034,8,4)
    block('stone',(0,.06,0),(7.4,.12,1.5))

def reliquary_altar():
    for y,width,depth in [(.10,5.8,1.9),(.28,4.9,1.5),(.46,4.0,1.1)]: block('stone',(0,y,0),(width,.19,depth))
    block('recess',(0,1.02,0),(2.1,.9,.8));block('edge',(0,1.52,0),(2.5,.16,1.05))
    for side in [-1,1]:
        tube('Body','bone',[(side*2.0,.46,0),(side*2.2,2.0,.1),(side*1.7,3.2,0),(side*.5,4.0,0)], [.14,.11,.08,.025],12,6)
        for i in range(4):
            x=side*(1.9-i*.29); y=2.65+i*.28
            tube('Body','bone',[(x,y,0),(x-side*.4,y-.17,-.15),(x-side*.67,y-.45,-.05)], [.07,.045,.018],10,4)
    for i in range(7):
        x=(i-3)*.24
        ellipsoid('Body','bone',(x,1.16,-.44),(.10,.13,.07),16,8)
        for side in [-1,1]: ellipsoid('Body','dark',(x+side*.04,1.19,-.50),(.027,.024,.008),12,6)
    gem('Body',(0,1.79,-.02),.16,'soul')

def furnace_throne():
    block('stone',(0,.14,0),(6.4,.28,1.6))
    for side in [-1,1]:
        loft('Body','stone',[(.25,.7,.5,0),(.5,.6,.44,0),(2.9,.48,.36,0),(3.5,.38,.29,0)],(side*2.3,0,0),8)
        for i in range(4): block('iron',(side*2.3,.75+i*.64,-.40),(1.1,.14,.14))
        leaf('Body','bronze',[(side*2.35,3.25,-.10),(side*2.12,4.0,0),(side*1.55,4.50,.08)],.18,.09)
    block('recess',(0,1.7,.30),(2.9,2.9,.4))
    for i in range(9):
        x=(i-4)*.28
        tube('Body','iron',[(x,.30,-.05),(x,2.9,-.05)],.045,8,1)
        tube('Body','ember',[(x,.7,.12),(x,1.2+(i%3)*.4,.12)],.018,6,1)
    for y in [.55,2.6,3.0]: block('bronze',(0,y,-.15),(3.3,.14,.2))
    tube('Body','bronze',[(-1.75,3.0,0),(0,4.3,0),(1.75,3.0,0)],.16,12,4)

if __name__=='__main__':
    for name,builder in [('ruined_vault',ruined_vault),('drowned_library',drowned_library),('reliquary_altar',reliquary_altar),('furnace_throne',furnace_throne)]: export(name,builder)
