"""Original Emberfall characters. Rebuild: blender -b -t 2 --python tools/art/build_characters.py

All forms, garment patterns, ornaments and weapons are authored here. No downloaded
models. Coordinates below use the game's Y-up space; GLTF converts via Blender.
The exported parts use the existing animation pivots, so combat and saves are untouched.
"""
import bpy
import math
from mathutils import Vector
from pathlib import Path
from collections import defaultdict

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/models'
PI = math.pi
TAU = PI * 2
PARTS = defaultdict(list)
MATS = {}
PALETTE = {
    'iron': ('52606b', .74, .43), 'silver': ('b4b8af', .78, .34),
    'bronze': ('997449', .72, .45), 'gold': ('d0ab68', .76, .35),
    'patina': ('487e78', .36, .72), 'leather': ('3e2e28', .0, .87),
    'wine': ('703947', .0, .92), 'violet': ('514267', .0, .89),
    'sage': ('354f46', .0, .91), 'linen': ('aea38b', .0, .93),
    'bone': ('c4b99d', .0, .69), 'skin': ('b99f89', .0, .85),
    'ash': ('655f59', .0, .96), 'dark': ('171d23', .06, .89),
    'soul': ('85e0d7', .0, .33), 'ember': ('ff9a50', .0, .45),
}

def xyz(p):
    return Vector((p[0], -p[2], p[1]))

def material(name):
    if name in MATS:
        return MATS[name]
    hx, metal, rough = PALETTE[name]
    color = tuple(int(hx[i:i+2], 16)/255 for i in (0, 2, 4))
    # Blender stores linear color, glTF preserves it. Godot's material getter
    # returns that color; the game shader uses the same linear vertex channel.
    color = tuple(((c+.055)/1.055)**2.4 if c > .04045 else c/12.92 for c in color)
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    bs = mat.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Base Color'].default_value = (*color, 1)
    bs.inputs['Metallic'].default_value = metal
    bs.inputs['Roughness'].default_value = rough
    if name in ('soul', 'ember'):
        bs.inputs['Emission Color'].default_value = (*color, 1)
        bs.inputs['Emission Strength'].default_value = 1.25
    MATS[name] = mat
    return mat

def mesh(part, mat, vertices, faces, smooth=True):
    data = bpy.data.meshes.new(part+'_'+mat)
    data.from_pydata([xyz(p) for p in vertices], [], faces)
    data.update()
    obj = bpy.data.objects.new(part+'__'+mat, data)
    bpy.context.collection.objects.link(obj)
    data.materials.append(material(mat))
    for poly in data.polygons:
        poly.use_smooth = smooth
    PARTS[(part, mat)].append(obj)
    return obj

def loft(part, mat, rings, center=(0,0,0), sides=32, folds=0, amplitude=0, closed_profile=False):
    # rings: height, radius X, radius Z, Z offset. Dense profiles describe
    # actual bell lips, necklines, breastplates and muscle rather than cones.
    vertices = []
    for row, (y, rx, rz, dz) in enumerate(rings):
        for i in range(sides):
            a = TAU*i/sides
            wave = 1 + amplitude*math.cos(folds*a + row*.10) if folds else 1
            vertices.append((center[0]+rx*math.sin(a)*wave, center[1]+y,
                             center[2]+rz*math.cos(a)*wave+dz))
    faces = []
    for j in range(len(rings)-1):
        for i in range(sides):
            n = (i+1)%sides
            # Converted basis preserves handedness: outward winding.
            faces.append((j*sides+i, j*sides+n, (j+1)*sides+n, (j+1)*sides+i))
    if closed_profile:
        last=(len(rings)-1)*sides
        for i in range(sides):
            n=(i+1)%sides
            faces.append((last+i,last+n,n,i))
    else:
        faces += [tuple(reversed(range(sides))), tuple((len(rings)-1)*sides+i for i in range(sides))]
    return mesh(part, mat, vertices, faces)

def ellipsoid(part, mat, center, size, segments=24, rows=12):
    rings = []
    for j in range(rows+1):
        a = -PI/2 + PI*j/rows
        r = max(.002, math.cos(a))
        rings.append((math.sin(a)*size[1], r*size[0], r*size[2], 0))
    return loft(part, mat, rings, center, segments)

def catmull(points, subdivisions=5):
    points = [Vector(p) for p in points]
    result = []
    for i in range(len(points)-1):
        p0, p1 = points[max(0,i-1)], points[i]
        p2, p3 = points[i+1], points[min(len(points)-1,i+2)]
        for s in range(subdivisions):
            t = s/subdivisions
            result.append(.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t))
    result.append(points[-1])
    return result

def tube(part, mat, points, radii=.015, sides=8, steps=5):
    path = catmull(points, steps)
    vertices = []
    for j,p in enumerate(path):
        tangent = (path[min(j+1,len(path)-1)]-path[max(0,j-1)]).normalized()
        ref = Vector((0,0,1)) if abs(tangent.z)<.92 else Vector((1,0,0))
        x = tangent.cross(ref).normalized()
        z = tangent.cross(x).normalized()
        if isinstance(radii, (int, float)):
            r = radii
        else:
            u = j/(len(path)-1)*(len(radii)-1)
            k = min(int(u),len(radii)-2)
            r = radii[k]*(1-(u-k)) + radii[k+1]*(u-k)
        for i in range(sides):
            v = p + (x*math.cos(TAU*i/sides)+z*math.sin(TAU*i/sides))*max(.001,r)
            vertices.append(tuple(v))
    faces = []
    for j in range(len(path)-1):
        for i in range(sides):
            faces.append((j*sides+i,j*sides+(i+1)%sides,(j+1)*sides+(i+1)%sides,(j+1)*sides+i))
    faces += [tuple(reversed(range(sides))), tuple((len(path)-1)*sides+i for i in range(sides))]
    return mesh(part, mat, vertices, faces)

def ring(part, mat, center, rx, rz, radius=.014, axis='y'):
    points = []
    for i in range(33):
        a = TAU*i/32
        if axis=='y': p=(rx*math.sin(a),0,rz*math.cos(a))
        elif axis=='z': p=(rx*math.sin(a),rz*math.cos(a),0)
        else: p=(0,rx*math.sin(a),rz*math.cos(a))
        points.append(tuple(center[k]+p[k] for k in range(3)))
    return tube(part, mat, points, radius, 8, 1)

def leaf(part, mat, points, width, depth=.055):
    path = catmull(points, 4)
    vertices = []
    for j,p in enumerate(path):
        t = j/(len(path)-1)
        w = max(.002, width*(math.sin(PI*t)**.62))
        tangent = (path[min(j+1,len(path)-1)]-path[max(0,j-1)]).normalized()
        axis = tangent.cross(Vector((0,0,1))).normalized()
        for s in range(12):
            a = TAU*s/12
            v = p+axis*math.sin(a)*w+Vector((0,0,1))*math.cos(a)*depth*math.sin(PI*t)
            vertices.append(tuple(v))
    faces = []
    for j in range(len(path)-1):
        for i in range(12): faces.append((j*12+i,j*12+(i+1)%12,(j+1)*12+(i+1)%12,(j+1)*12+i))
    return mesh(part, mat, vertices, faces)

def drape(part, mat, top, bottom, rx0, rx1, rz0, rz1, arc=TAU, folds=12, torn=False, offset=(0,0,0)):
    # Open coat/cape with sculpted longitudinal folds and uneven trailing hem.
    cols, rows = 64, 12
    vertices=[]
    for j in range(rows+1):
        t=j/rows
        for i in range(cols+1):
            a=-arc/2+arc*i/cols
            hem = (.05+.07*math.sin(i*1.83)**2) if torn else .015*math.cos(a*folds)
            y=top+(bottom+hem-top)*t
            flutter=math.sin(a*folds+.25*t)*(.008+.027*t)
            rx=rx0+(rx1-rx0)*t**.85
            rz=rz0+(rz1-rz0)*t
            vertices.append((offset[0]+math.sin(a)*(rx+flutter),offset[1]+y,
                             offset[2]+math.cos(a)*(rz+flutter)+t*t*.08))
    faces=[]
    for j in range(rows):
        for i in range(cols):
            k=j*(cols+1)+i
            faces.append((k,k+cols+1,k+cols+2,k+1))
    obj=mesh(part,mat,vertices,faces)
    solid=obj.modifiers.new('Sewn thickness','SOLIDIFY'); solid.thickness=.008
    return obj

def gem(part, center, size=.06, mat='soul'):
    return loft(part,mat,[(-size*1.3,.002,.002,0),(-size*.4,size,size*.65,0),(size*.35,size,size*.65,0),(size*1.4,.001,.001,0)],center,6)

def boot(part, armor='iron'):
    ellipsoid(part,'leather',(0,-.38,-.09),(.11,.09,.215))
    loft(part,armor,[(-.32,.092,.095,0),(-.17,.095,.085,0),(-.07,.117,.1,-.015),(.025,.09,.08,0)],sides=24)
    leaf(part,'silver',[(0,.075,-.13),(0,-.045,-.145),(0,-.14,-.11)],.10,.026)
    for y in [-.22,-.15,-.08]:
        leaf(part,armor,[(0,y+.04,-.06),(0,y,-.14),(0,y-.06,-.19)],.10,.028)

def limbs(armor='iron', cloth='wine', monstrous=False, slender=False):
    for side in [-1,1]:
        arm='ArmL' if side<0 else 'ArmR'
        leg='LegL' if side<0 else 'LegR'
        knee='KneeL' if side<0 else 'KneeR'
        width=.82 if slender else 1
        loft(arm,'skin' if monstrous else cloth,[(-.55,.067*width,.07,0),(-.42,.081*width,.083,0),(-.27,.08*width,.09,0),(-.12,.097*width,.105,0),(.025,.12*width,.125,0)])
        if not monstrous:
            for layer in range(2 if slender else 3):
                reach=.17 if slender else .24
                leaf(arm,'bronze' if armor=='bronze' else armor,[(side*.02,.12-layer*.047,.035),(side*.10,.10-layer*.055,-.01),(side*reach,.015-layer*.08,-.03)],(.102 if slender else .15)-layer*.018,.029 if slender else .047)
            loft(arm,armor,[(-.55,.078*width,.075,-.018),(-.50,.10*width,.09,-.018),(-.32,.105*width,.10,-.01),(-.28,.076*width,.078,0)],sides=24)
            for y in [-.48,-.33]: ring(arm,'gold',(0,y,-.015),.102*width,.096,.011)
        ellipsoid(arm,'skin' if monstrous else 'leather',(0,-.59,-.01),(.072,.085,.048))
        for f in range(4):
            x=(f-1.5)*.035
            tube(arm,'bone' if monstrous else 'leather',[(x,-.59,-.035),(x,-.65,-.063),(x,-.68,-.02)], [.018,.016,.006],6,3)
        loft(leg,cloth,[(-.37,.084*width,.08,0),(-.19,.11*width,.11,0),(.045,.14*width,.13,0)])
        boot(knee,armor)

def torso(armor='iron', cloth='wine', slender=False):
    w=.86 if slender else 1
    loft('Body',cloth if slender else armor,[(.89,.18*w,.13,0),(.99,.21*w,.15,0),(1.10,.22*w,.15,0),(1.23,.26*w,.18,0),(1.37,.29*w,.18,0),(1.46,.29*w,.16,0),(1.54,.20*w,.115,0),(1.61,.10,.08,0)],sides=32)
    loft('Body','leather',[(.88,.205*w,.155,0),(.91,.213*w,.16,0),(.96,.21*w,.156,0),(.99,.197*w,.148,0)],sides=32)
    ring('Body','gold',(0,.96,0),.212*w,.16,.012)
    gem('Body',(0,.937,-.172),.036,'ember' if armor=='bronze' else 'soul')
    for side in [-1,1]:
        # Lobed breastplates and chased curved inlays.
        if not slender:
            leaf('Body',armor,[(side*.045,1.12,-.15),(side*.145,1.30,-.22),(side*.10,1.52,-.11)],.12,.035)
        tube('Body','gold',[(side*.12,1.49,-.12),(side*.19,1.38,-.177),(side*.17,1.2,-.17),(side*.035,1.08,-.16)],.009,6,5)
        for i in range(3):
            tube('Body','silver' if armor=='iron' else 'bronze',[(side*.05,1.40-i*.075,-.196),(side*.14,1.42-i*.075,-.204),(side*.24,1.40-i*.075,-.16)],.008,6,4)

def face(part='Body', skull=False, hood=False):
    skin='bone' if skull else 'skin'
    loft(part,skin,[(1.54,.058,.063,0),(1.65,.062,.068,-.01),(1.71,.065,.070,-.02)],sides=20)
    ellipsoid(part,skin,(0,1.795,-.015),(.12,.155,.12))
    ellipsoid(part,skin,(0,1.691,-.064),(.075,.043,.065))
    leaf(part,skin,[(0,1.86,-.117),(0,1.80,-.164),(0,1.766,-.13)],.028,.018)
    for side in [-1,1]:
        ellipsoid(part,skin,(side*.074,1.767,-.084),(.027,.028,.032))
        ellipsoid(part,'dark',(side*.052,1.821,-.122),(.032,.02 if skull else .008,.014))
        if skull: gem(part,(side*.051,1.822,-.134),.009)
        tube(part,skin,[(side*.012,1.853,-.12),(side*.055,1.854,-.132),(side*.092,1.836,-.095)],.010,6,3)
    tube(part,'dark',[(-.039,1.711,-.12),(0,1.704,-.132),(.039,1.711,-.12)],.005,6,4)
    if not skull:
        # Fuse the anatomical forms into one continuous facial surface. Voxel
        # remeshing removes the visible sphere intersections at cheek/jaw/nose.
        objects=PARTS[(part,skin)]
        bpy.ops.object.select_all(action='DESELECT')
        for obj in objects: obj.select_set(True)
        bpy.context.view_layer.objects.active=objects[0]
        bpy.ops.object.join()
        head=objects[0]; head.data.remesh_voxel_size=.006
        bpy.ops.object.voxel_remesh()
        smooth=head.modifiers.new('Facial anatomy smoothing','SMOOTH');smooth.factor=.6;smooth.iterations=3
        bpy.ops.object.modifier_apply(modifier=smooth.name)
        decimate=head.modifiers.new('Mobile facial topology','DECIMATE');decimate.ratio=.20
        bpy.ops.object.modifier_apply(modifier=decimate.name)
        for poly in head.data.polygons: poly.use_smooth=True
        PARTS[(part,skin)]=[head]
    if skull:
        for i in range(6): ellipsoid(part,'bone',((i-2.5)*.016,1.718,-.125),(.007,.018,.009),12,6)
    elif not hood:
        # Swept hair locks and two dangling braids, each built from a continuous curve.
        for i in range(11):
            a=TAU*i/11
            tube(part,'leather',[(math.sin(a)*.045,1.966,math.cos(a)*.05),
                (math.sin(a)*.13,1.908,math.cos(a)*.124),
                (math.sin(a)*.123,1.78,math.cos(a)*.13+.023)], [.033,.025,.008],8,5)
        for side in [-1,1]:
            tube(part,'leather',[(side*.11,1.84,.025),(side*.14,1.67,.015),(side*.12,1.49,.035)], [.031,.025,.012],10,6)
            ring(part,'gold',(side*.123,1.535,.03),.026,.025,.009)

def hood(cloth='sage'):
    # Arched opening, fitted cranial shell, pointed back rather than a cone.
    drape('Body',cloth,1.98,1.59,.11,.20,.12,.19,arc=PI*1.47,folds=5,offset=(0,0,.025))
    ellipsoid('Body',cloth,(0,1.943,.038),(.146,.095,.133))
    tube('Body','gold',[(-.18,1.60,-.06),(-.16,1.84,-.12),(0,1.996,-.073),(.16,1.84,-.12),(.18,1.60,-.06)],.013,8,6)

def cape(cloth='wine', regal=False):
    drape('Cape',cloth,.035,-1.32 if regal else -1.19,.23,.48 if regal else .36,.045,.26,PI*1.08,10,True)
    for side in [-1,1]:
        tube('Cape','gold',[(side*.23,.025,.004),(side*.29,-.55,.17),(side*(.47 if regal else .35),-1.15,.17)],.010,6,5)
    # Embroidered oath emblem on the back, readable in the actual camera.
    tube('Cape','bronze',[(0,-.10,.09),(0,-.57,.175),(0,-.89,.24)],.015,6,5)
    for side in [-1,1]: tube('Cape','bronze',[(0,-.37,.15),(side*.13,-.50,.19),(0,-.69,.225)],.013,6,5)

def skirt(cloth='violet', long=True):
    drape('Body',cloth,.92,.09 if long else .53,.21,.38 if long else .27,.155,.24,PI*1.65,12,False)
    # Overlapping front coat panels have real folded volume, no flat ribbons.
    for side in [-1,1]:
        leaf('Body',cloth,[(side*.12,.97,-.16),(side*.19,.63,-.225),(side*.22,.17 if long else .56,-.22)],.11,.030)
        tube('Body','gold',[(side*.16,.93,-.176),(side*.25,.57,-.246),(side*.24,.18 if long else .55,-.232)],.008,6,5)

def staff(crozier=False):
    tube('Weapon','leather',[(0,-.53,0),(.018,.29,.018),(0,1.14,0)], [.025,.037,.025],12,6)
    for y in [-.43,-.22,.10,.38,.70,1.04]: ring('Weapon','gold',(0,y,0),.042,.042,.009)
    for side in [-1,1]:
        tube('Weapon','bronze' if crozier else 'silver',[(0,1.0,0),(side*.19,1.16,0),(side*.24,1.46,0),(side*.075,1.69,-.005)], [.035,.040,.026,.004],12,7)
    ring('Weapon','gold',(0,1.38,0),.18,.18,.014,'z')
    gem('Weapon',(0,1.4,-.025),.105)
    tube('Weapon','gold',[(.03,1.02,0),(.17,.91,.025),(.14,.76,.04)],.01,6,5)
    gem('Weapon',(.14,.74,.04),.035,'ember')

def sword():
    loft('Weapon','leather',[(-.21,.037,.037,0),(.12,.041,.041,0)],sides=16,folds=8,amplitude=.07)
    for side in [-1,1]: tube('Weapon','gold',[(0,.1,0),(side*.13,.13,0),(side*.24,.20,-.01)], [.03,.032,.017],10,5)
    gem('Weapon',(0,-.26,0),.052,'ember')
    loft('Weapon','silver',[(.15,.10,.018,0),(.26,.084,.018,0),(1.11,.065,.014,0),(1.39,.001,.001,0)],sides=4)
    tube('Weapon','gold',[(0,.2,-.021),(0,.40,-.021),(0,1.04,-.018)],.007,6,3)

def shield():
    # Convex kite plate, gilded rolled edge, inset heraldic thorn relief.
    outline=[(0,-.93),(-.22,-.65),(-.27,-.28),(-.21,-.13),(0,-.07),(.21,-.13),(.27,-.28),(.22,-.65)]
    vertices=[(-.045,-.4,-.30)]+[(x-.045,y,-.23) for x,y in outline]
    mesh('ArmL','iron',vertices,[(0,i+1,(i+1)%8+1) for i in range(8)])
    tube('ArmL','gold',[(x-.045,y,-.24) for x,y in outline+[outline[0]]],.017,8,3)
    tube('ArmL','silver',[(-.045,-.18,-.275),(-.045,-.43,-.31),(-.045,-.78,-.27)],.018,8,5)
    for side in [-1,1]: tube('ArmL','gold',[(-.045,-.30,-.303),(-.045+side*.12,-.39,-.287),(-.045,-.54,-.30)],.016,8,4)

def hero(kind):
    cloth={'Vowkeeper':'wine','Arcanist':'violet','Ranger':'sage'}[kind]
    torso('iron',cloth,kind!='Vowkeeper'); limbs('iron',cloth,slender=kind!='Vowkeeper')
    cape(cloth); skirt(cloth,kind=='Arcanist')
    if kind=='Vowkeeper':
        loft('Body','iron',[(1.68,.135,.13,0),(1.74,.155,.15,0),(1.88,.158,.148,0),(1.98,.086,.085,0),(2.035,.008,.02,0)],sides=32)
        tube('Body','gold',[(0,1.70,-.157),(0,1.84,-.162),(0,2.03,-.035)],.012,8,5)
        for side in [-1,1]: tube('Body','dark',[(0,1.838,-.158),(side*.065,1.838,-.145),(side*.13,1.83,-.10)],.014,8,4)
        sword(); shield()
    else:
        face(hood=kind=='Ranger')
        if kind=='Arcanist':
            ring('Body','gold',(0,1.905,-.015),.139,.13,.012)
            gem('Body',(0,1.905,-.145),.029)
            staff()
            # Spell book and satchel, curved bindings and filigree instead of cubes.
            ellipsoid('Body','leather',(-.245,.82,.005),(.065,.125,.096))
            ring('Body','gold',(-.25,.82,-.096),.05,.105,.01,'z')
            for side in [-1,1]:
                leaf('Body','silver',[(side*.06,1.56,-.1),(side*.24,1.48,-.1),(side*.31,1.41,-.015)],.048,.021)
        else:
            hood()
            tube('Weapon','leather',[(0,-.64,-.04),(0,-.43,-.27),(0,0,-.38),(0,.44,-.26),(0,.64,-.04)], [.016,.03,.041,.03,.016],12,8)
            tube('Weapon','linen',[(0,-.64,-.04),(0,0,-.012),(0,.64,-.04)],.004,6,3)
            for side in [-1,1]: tube('Weapon','gold',[(0,side*.46,-.25),(.012,side*.57,-.16),(0,side*.62,-.08)],.008,6,5)
            loft('Body','leather',[(1.03,.09,.065,0),(1.16,.085,.07,0),(1.58,.10,.075,0)],center=(.18,0,.23),sides=24)
            ring('Body','gold',(.18,1.56,.23),.11,.084,.012)
            for i in range(5):
                x=.13+i*.025
                tube('Body','bone',[(x,1.20,.25),(x,1.74+(i%2)*.045,.25)],.005,6,2)
                leaf('Body','linen',[(x,1.67,.25),(x+.013,1.72,.25),(x,1.79,.25)],.014,.012)

def bell_head(part, base, radius, ornament=True):
    # A real hollow bell: flared rolled lip, shoulder, crown, inner wall.
    rings=[(base,radius,.88*radius,0),(base+.04,radius*1.02,radius*.90,0),
        (base+.08,radius*.93,radius*.82,0),(base+.20,radius*.67,radius*.62,0),
        (base+.36,radius*.54,radius*.51,0),(base+.48,radius*.50,radius*.48,0),
        (base+.55,radius*.38,radius*.37,0),(base+.59,radius*.07,radius*.07,0),
        (base+.565,radius*.045,radius*.045,0),(base+.50,radius*.35,radius*.34,0),
        (base+.35,radius*.46,radius*.43,0),(base+.18,radius*.58,radius*.53,0),
        (base+.065,radius*.86,radius*.75,0),(base,radius*.90,radius*.78,0)]
    loft(part,'bronze',rings,sides=48,closed_profile=True)
    ring(part,'gold',(0,base+.048,0),radius*.98,radius*.865,.018)
    ring(part,'gold',(0,base+.33,0),radius*.55,radius*.52,.013)
    ring(part,'bronze',(0,base+.64,0),radius*.16,radius*.18,.023,'z')
    if ornament:
        for i in range(10):
            a=TAU*i/10
            tube(part,'patina',[(math.sin(a)*radius*.93,base+.09,math.cos(a)*radius*.82),
                (math.sin(a)*radius*.71,base+.19,math.cos(a)*radius*.65),
                (math.sin(a)*radius*.53,base+.39,math.cos(a)*radius*.51)],.012,6,5)
        for side in [-1,1]:
            tube(part,'soul',[(side*.052,base+.228,-radius*.665),(side*.125,base+.248,-radius*.635)],.008,8,3)

def boss(region):
    cloth=['wine','sage','linen','dark'][region]
    armor=['bronze','patina','silver','iron'][region]
    limbs(armor,cloth,slender=region in (1,2))
    if region==0:
        # The Bell Warden: an empty reliquary held together by gilded ribs.
        loft('Body','dark',[(.85,.22,.18,0),(1.04,.28,.18,0),(1.26,.30,.20,0),(1.52,.25,.19,0),(1.64,.15,.12,0)],sides=32)
        ellipsoid('Body','soul',(0,1.30,-.14),(.115,.155,.07))
        for side in [-1,1]:
            for rib in range(5):
                y=1.10+rib*.095
                tube('Body','bronze',[(side*.035,y-.028,-.215),(side*.21,y,-.245),(side*.30,y+.08,-.12),(side*.24,y+.13,.14)], [.021,.032,.037,.020],10,5)
            tube('Body','gold',[(side*.19,.88,-.17),(side*.30,1.17,-.17),(side*.34,1.42,-.05),(side*.17,1.64,0)],.035,10,6)
            for k in range(3):
                arm='ArmL' if side<0 else 'ArmR'
                leaf(arm,'bronze',[(side*.01,.06+k*.06,.08),(side*.22,.24+k*.06,.10),(side*(.46-k*.07),.22+k*.08,.16)],.13,.042)
                tube(arm,'gold',[(side*.03,.10+k*.06,.04),(side*.22,.265+k*.06,.06),(side*(.44-k*.07),.235+k*.08,.12)],.009,6,5)
        bell_head('Body',1.67,.38)
        cape('wine',True); skirt('wine',False)
        tube('Weapon','bronze',[(0,-.39,0),(.015,.26,0),(0,.91,0)],.042,12,5)
        bell_head('Weapon',.62,.29,False)
        # Linked censer chains hang from the off hand.
        for i in range(8): ring('ArmL','bronze',(-.015,-.66-i*.054,.02),.032,.04,.008,'z' if i%2==0 else 'x')
        ellipsoid('ArmL','bronze',(-.015,-1.16,.02),(.10,.12,.10))
        gem('ArmL',(-.015,-1.14,-.085),.04,'ember')
    elif region==1:
        torso('patina','sage',True); skirt('sage'); cape('sage',True)
        face(skull=True); hood('sage')
        for side in [-1,1]:
            # Bent antler mitre, drowned roots and pearls.
            tube('Body','bone',[(side*.10,1.9,.05),(side*.24,2.14,.12),(side*.20,2.39,.17),(side*.33,2.52,.15)], [.045,.032,.02,.002],10,6)
            for i in range(4):
                tube('Body','patina',[(side*.27,1.50,.12),(side*(.38+i*.027),1.22,.16),(side*.25,.71-i*.09,.16)], [.02,.022,.004],8,6)
                ellipsoid('Body','bone',(side*.24,.75-i*.08,.18),(.025,.034,.025),12,6)
        staff(True)
    elif region==2:
        torso('silver','linen',True); skirt('linen'); cape('linen',True); face(skull=True)
        drape('Body','linen',1.70,.11,.14,.51,.10,.31,PI*1.15,16,True,offset=(0,0,.12))
        ring('Body','gold',(0,1.94,0),.21,.18,.015)
        for i in range(9):
            a=TAU*i/9
            tube('Body','silver',[(math.sin(a)*.17,1.94,math.cos(a)*.15),
                (math.sin(a)*.25,2.12,math.cos(a)*.22),
                (math.sin(a)*.22,2.30+.08*(i%2),math.cos(a)*.19)], [.018,.026,.002],8,6)
            gem('Body',(math.sin(a)*.235,2.09,math.cos(a)*.20),.025)
        for side in [-1,1]:
            for i in range(4):
                leaf('Body','bone',[(side*.27,1.45,.05),(side*.55,1.64+i*.08,.12),(side*(.65+i*.07),1.67+i*.13,.18)],.054,.022)
        staff()
    else:
        torso('iron','dark'); skirt('dark',False); cape('dark',True)
        loft('Body','iron',[(1.65,.14,.14,0),(1.77,.18,.17,0),(1.92,.16,.15,0),(2.03,.06,.08,0)],sides=32)
        for side in [-1,1]:
            tube('Body','bronze',[(side*.14,1.91,.045),(side*.32,2.10,.09),(side*.35,2.39,.13),(side*.24,2.59,.18)], [.095,.076,.037,.002],12,8)
            tube('Body','ember',[(side*.055,1.83,-.166),(side*.11,1.86,-.15),(side*.16,1.82,-.10)],.014,8,5)
            for i in range(3):
                arm='ArmL' if side<0 else 'ArmR'
                leaf(arm,'iron',[(side*.01,.10,.03),(side*.22,.24+i*.07,.12),(side*.43,.37+i*.1,.2)],.11,.045)
        gem('Body',(0,1.31,-.22),.13,'ember')
        for side in [-1,1]:
            tube('Body','ember',[(side*.02,1.44,-.19),(side*.13,1.39,-.227),(side*.08,1.18,-.20),(side*.19,1.09,-.15)],.009,6,5)
        tube('Weapon','leather',[(0,-.3,0),(0,.9,0)],.043,12,3)
        for side in [-1,1]:
            leaf('Weapon','iron',[(0,.83,0),(side*.36,.79,0),(side*.44,1.13,0)],.19,.11)
            tube('Weapon','ember',[(side*.02,.9,-.08),(side*.28,.91,-.11),(side*.38,1.10,-.05)],.018,8,5)

def enemy(kind):
    if kind=='raider':
        loft('Body','ash',[(.84,.14,.10,.01),(1.05,.18,.12,0),(1.23,.23,.145,0),(1.45,.25,.14,.03),(1.56,.13,.085,.055)],sides=24)
        limbs('bone','ash',True,True); face(skull=True)
        for side in [-1,1]:
            for i in range(5):
                tube('Body','bone',[(side*.03,1.14+i*.055,-.133),(side*.15,1.16+i*.055,-.16),(side*.22,1.20+i*.055,-.08)], [.008,.014,.009],8,5)
        tube('Body','bone',[(0,.94,.12),(0,1.30,.15),(0,1.57,.075)],.021,8,7)
        for i in range(3): tube('Weapon','bone',[((i-1)*.044,0,0),((i-1)*.05,-.16,-.04),((i-1)*.06,-.32,-.12)], [.025,.017,.002],8,5)
        skirt('ash',False)
    elif kind=='hexer':
        torso('bronze','sage',True); limbs('bronze','sage',slender=True)
        face(skull=True); hood('sage'); skirt('sage'); cape('sage'); staff()
    else:
        torso('bronze','wine'); limbs('bronze','wine'); skirt('wine',False); cape('wine')
        loft('Body','bronze',[(1.67,.13,.12,0),(1.8,.15,.14,0),(1.94,.13,.12,0),(2.01,.04,.05,0)],sides=24)
        for side in [-1,1]:
            tube('Body','bone',[(side*.12,1.91,.01),(side*.27,2.05,.02),(side*.29,2.27,.06)], [.047,.025,.002],8,6)
            tube('Body','ember',[(side*.025,1.82,-.14),(side*.10,1.83,-.112)],.008,6,3)
        sword()
        if kind=='bulwark': shield()

def export(name, build):
    global PARTS, MATS
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    PARTS=defaultdict(list); MATS={}
    build()
    # Join by animated part and material. Blender evaluates sewn garment
    # thickness before export. Godot merges these material surfaces per joint.
    for (part, mat), objects in PARTS.items():
        bpy.ops.object.select_all(action='DESELECT')
        for obj in objects:
            obj.select_set(True)
            bpy.context.view_layer.objects.active=obj
            for modifier in list(obj.modifiers): bpy.ops.object.modifier_apply(modifier=modifier.name)
        bpy.context.view_layer.objects.active=objects[0]
        if len(objects)>1: bpy.ops.object.join()
        objects[0].name=part+'__'+mat
    OUT.mkdir(parents=True,exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',
        export_yup=True,export_texcoords=False,export_normals=True,export_materials='EXPORT',
        export_cameras=False,export_lights=False,export_animations=False,export_extras=False)
    triangles=sum(len(o.data.polygons)*2 for o in bpy.context.scene.objects if o.type=='MESH')
    print('EMBERFALL_MODEL',name,'approx triangles',triangles)

if __name__ == '__main__':
    for name in ['Vowkeeper','Arcanist','Ranger']: export(name.lower(),lambda n=name:hero(n))
    for region in range(4): export('guardian_'+str(region),lambda r=region:boss(r))
    for name in ['raider','hexer','bulwark','elite']: export(name,lambda n=name:enemy(n))
