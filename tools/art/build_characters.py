"""Original Emberfall characters. Rebuild: blender -b -t 2 --python tools/art/build_characters.py

All forms, garment patterns, ornaments and weapons are authored here. No downloaded
models. Coordinates below use the game's Y-up space; GLTF converts via Blender.
The runtime binds these volumes to its native 29-bone skeleton. Source parts keep
their anatomical pivots; there are no billboards, pose sheets or downloaded models.
"""
import bpy
import math
import sys
from mathutils import Vector
from pathlib import Path
from collections import defaultdict

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/models'
PI = math.pi
TAU = PI * 2
PARTS = defaultdict(list)
MATS = {}
ACTIVE_MODEL = ''
PALETTE = {
    'iron': ('7b8790', .67, .44), 'silver': ('b4bdc0', .76, .38),
    'bronze': ('938169', .63, .52), 'gold': ('b09c79', .68, .49),
    'patina': ('657f75', .48, .66), 'leather': ('725c4a', .0, .79),
    'wine': ('79434d', .0, .91), 'violet': ('596982', .0, .89),
    'sage': ('586b59', .0, .91), 'linen': ('b1a58f', .0, .94),
    'bone': ('b8b09a', .0, .81), 'skin': ('bea495', .0, .81),
    'ash': ('655f59', .0, .96), 'dark': ('171d23', .06, .89),
    'soul': ('78bfb5', .0, .29), 'ember': ('ef984e', .0, .44),
    'hair': ('c0c4bd', .0, .77), 'hair_shadow': ('686f72', .0, .87),
    'eye': ('c4bbb1', .0, .48), 'iris': ('4c807d', .0, .40),
    'lip': ('9e6d68', .0, .82),
    'lip_shadow': ('674d46', .0, .87),
}

def body_author():
    sys.path.insert(0,str(Path(__file__).parent))
    import build_body_047
    return build_body_047

def xyz(p):
    return Vector((p[0], -p[2], p[1]))

def material(name):
    if name in MATS:
        return MATS[name]
    hx, metal, rough = PALETTE[name]
    # These are the same exported material channels; local pigment/finish
    # choices stop the Queen's shroud and raider skin reading as bright plastic.
    worn = {
        'guardian_2': {'linen':('928978',0,.94),'bone':('b3aa94',0,.87),
            'silver':('8c9390',.64,.58),'gold':('87785d',.57,.64)},
        'raider': {'skin':('8e8c7a',0,.87),'ash':('5f5e55',0,.96),
            'bone':('aaa18e',0,.89)},
    }
    hx,metal,rough=worn.get(ACTIVE_MODEL,{}).get(name,(hx,metal,rough))
    color = tuple(int(hx[i:i+2], 16)/255 for i in (0, 2, 4))
    # Blender stores linear color and glTF preserves it. Godot exposes the
    # imported material as sRGB; the runtime converts it for its vertex channel.
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
    finish=material(mat)
    # Same runtime material categories, with physical garment-piece pigments.
    # Separate sleeve/hand values remain readable before the darker rear cloak.
    role='cape' if part=='Cape' and mat in ('wine','sage','violet','linen','dark') else (
        'sleeve' if part.startswith('Arm') and mat in ('wine','sage','violet','linen','leather') else
        'sole' if part.startswith('Knee') and mat=='leather' else '')
    if role:
        key=mat+'@'+role
        if key not in MATS:
            toned=finish.copy();toned.name=mat+'.'+role
            factor=.57 if role=='cape' else .72 if role=='sole' else 1.28
            color=tuple(min(.85,c*factor) for c in finish.diffuse_color[:3])
            toned.diffuse_color=(*color,1)
            toned.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(*color,1)
            MATS[key]=toned
        finish=MATS[key]
    data.materials.append(finish)
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

def tailored_drape(part, mat, top, bottom, rx0, rx1, rz0, rz1,
                   arc=TAU, folds=9, torn=False, offset=(0,0,0), thickness=.012):
    # Garment-scale folds have a gathered root, broad hanging troughs and a
    # weighted sewn hem. Keep drape() unchanged: Nyra's measured hairline uses it.
    cols, rows = 40, 12
    vertices=[]
    for j in range(rows+1):
        t=j/rows
        for i in range(cols+1):
            a=-arc/2+arc*i/cols
            fold=math.sin(a*folds+.40*t)
            fold+=.24*math.sin(a*folds*2-.65*t)
            depth=(.006+.023*math.sin(t*PI*.64))*fold
            drag=.009*math.sin(a*3+t*2.7)*math.sin(t*PI)
            hem=.018*math.cos(a*folds+.4)
            if torn: hem+=.060*max(0,math.sin(i*1.69))**4
            y=top+(bottom+hem-top)*t
            rx=rx0+(rx1-rx0)*t**.82
            rz=rz0+(rz1-rz0)*t
            vertices.append((offset[0]+math.sin(a)*(rx+depth),offset[1]+y,
                offset[2]+math.cos(a)*(rz+depth)+t*t*.072+drag))
    faces=[]
    for j in range(rows):
        for i in range(cols):
            k=j*(cols+1)+i
            faces.append((k,k+cols+1,k+cols+2,k+1))
    obj=mesh(part,mat,vertices,faces)
    solid=obj.modifiers.new('Turned wool and linen edge','SOLIDIFY')
    solid.thickness=thickness; solid.offset=0
    # The hem is a fold of the same cloth, not a floating metal outline.
    tube(part,mat,vertices[-(cols+1):],thickness*.65,6,1)
    return obj

def coat_panel(part, mat, side, top, bottom, width=.102):
    # A cut and sewn front gore. Cross folds widen beneath the belt; the lower
    # edge remains a broad fabric cut instead of tapering to a leaf point.
    rows,cols=10,10
    vertices=[]
    for j in range(rows+1):
        t=j/rows
        # The gores move outside the patella instead of becoming two broad
        # stiff boards over it. Bias the long overlap toward the outside leg.
        center=.118+(.107 if top-bottom>.60 else .058)*t**.75
        halfwidth=width*(.69+.05*math.sin(t*PI))
        for i in range(cols+1):
            u=i/cols
            x=side*(center+(u-.5)*2*halfwidth)
            y=top+(bottom-top)*t+.052*t*t*(1-u)
            z=-.169-.041*math.sin(t*PI*.64)
            z-=.026*math.sin(u*PI*2.4+.55*t)*(.28+.72*t)
            z-=.014*math.sin(t*PI*2+u*2.1)*math.sin(t*PI)
            vertices.append((x,y,z))
    faces=[]
    for j in range(rows):
        for i in range(cols):
            k=j*(cols+1)+i
            face=(k,k+1,k+cols+2,k+cols+1)
            faces.append(face if side>0 else tuple(reversed(face)))
    obj=mesh(part,mat,vertices,faces)
    solid=obj.modifiers.new('Overlapping sewn front gore','SOLIDIFY')
    solid.thickness=.012; solid.offset=0
    for edge in [0,cols]:
        tube(part,mat,[vertices[j*(cols+1)+edge] for j in range(rows+1)],.007,6,1)
    tube(part,mat,vertices[-(cols+1):],.008,6,1)

def pauldron(part, armor, side, scale=1.0, plates=3):
    # An arched shoulder cap becomes two descending open lames. A continuous
    # silhouette sits over the upper sleeve; these are not stacks of toroids.
    for layer in range(plates):
        top=.110-layer*.060
        rad=(.126-layer*.009)*scale
        rows,cols=5,18
        vertices=[]
        for row in range(rows+1):
            t=row/rows
            for col in range(cols+1):
                a=-PI*.57+PI*1.14*col/cols
                # Cap arches in Y across the front/back shoulder cross-section.
                inner=-.70 if layer==0 else .18
                x=side*rad*(inner+(1.09-inner)*t)
                y=top-.056*(2*t-1)**2-.030*(1-math.cos(a))
                z=math.sin(a)*rad*(.79+.13*t)+.012
                x+=side*.009*math.cos(a*2)*math.sin(t*PI)
                vertices.append((x,y,z))
        faces=[]
        for row in range(rows):
            for col in range(cols):
                k=row*(cols+1)+col
                f=(k,k+cols+1,k+cols+2,k+1)
                faces.append(tuple(reversed(f)) if side>0 else f)
        obj=mesh(part,armor,vertices,faces)
        solid=obj.modifiers.new('Shoulder forged edge','SOLIDIFY')
        solid.thickness=.008;solid.offset=0
        for z in [-rad*.73,rad*.73]:
            ellipsoid(part,'silver' if armor!='bronze' else 'gold',
                (side*(.022+rad*.64),top-.070,z+.012),(.005,.005,.005),8,4)

def formed_plate(part, mat, sections, arc=PI*1.20, ridge=.012):
    # A thin forged front shell: shaped longitudinal sections, central ridge,
    # open side returns and an actual hem. Rear cloth/leather stays visible.
    cols=18
    vertices=[]
    for row,(y,rx,rz,dz) in enumerate(sections):
        for col in range(cols+1):
            a=PI-arc/2+arc*col/cols
            u=(col-cols/2)/(cols/2)
            yy=y
            if row==0: yy-=.015*(1-abs(u))
            if row==len(sections)-1: yy-=.021*(1-abs(u))
            vertices.append((rx*math.sin(a),yy,rz*math.cos(a)+dz-ridge*(1-abs(u))**4))
    faces=[]
    for row in range(len(sections)-1):
        for col in range(cols):
            k=row*(cols+1)+col
            faces.append((k,k+1,k+cols+2,k+cols+1))
    obj=mesh(part,mat,vertices,faces)
    solid=obj.modifiers.new('Forged shell thickness','SOLIDIFY')
    solid.thickness=.008;solid.offset=0
    return obj

def joint_plate(part, mat, y, width, height, z):
    # A shallow pointed cop, not an inflated ellipsoid. The lower flare leaves
    # clearance for the greave/vambrace while the soft joint can still bend.
    outline=[(0,height),(-width*.66,height*.72),(-width,height*.10),
        (-width*.77,-height*.53),(0,-height),
        (width*.77,-height*.53),(width,height*.10),(width*.66,height*.72)]
    vertices=[(x,y+dy,z+.020*abs(x)/width) for x,dy in outline]
    vertices += [(x*.70,y+dy*.70,z-.012) for x,dy in outline]
    vertices.append((0,y,z-.026))
    faces=[]
    for i in range(8):
        n=(i+1)%8
        faces.append((8+i,8+n,n,i));faces.append((16,8+n,8+i))
    obj=mesh(part,mat,vertices,faces)
    solid=obj.modifiers.new('Articulated joint plate','SOLIDIFY');solid.thickness=.009
    return obj

def organic_arm(part, side):
    # Connected deltoid, biceps, elbow, extensor mass and narrow wrist; an
    # asymmetric section and tendon relief remove the straight tube silhouette.
    sections=[(-.565,.037,.039,.014),(-.510,.040,.043,.014),
        (-.455,.053,.050,.005),(-.392,.063,.055,-.003),
        (-.343,.052,.049,.008),(-.307,.045,.049,.021),
        (-.275,.054,.052,.017),(-.210,.070,.061,.008),
        (-.140,.083,.072,-.006),(-.064,.096,.083,-.003),
        (.011,.098,.086,.005),(.059,.052,.052,.008),(.081,.006,.008,.008)]
    vertices=[];cols=24
    for y,rx,rz,dz in sections:
        for col in range(cols):
            a=TAU*col/cols
            offset=-side*.018*math.sin((y+.56)/.62*PI)
            relief=1+.055*math.cos(a*3+.7)+.025*math.sin(a*5+y*8)
            vertices.append((offset+rx*.86*math.sin(a)*relief,y,dz+rz*.92*math.cos(a)*relief))
    faces=[]
    for row in range(len(sections)-1):
        for col in range(cols):
            n=(col+1)%cols
            faces.append((row*cols+col,row*cols+n,(row+1)*cols+n,(row+1)*cols+col))
    faces.extend([tuple(reversed(range(cols))),tuple((len(sections)-1)*cols+i for i in range(cols))])
    mesh(part,'skin',vertices,faces)
    for offset in [-.020,.016]:
        tube(part,'skin',[(offset,-.526,-.026),(offset+side*.008,-.449,-.050),
            (offset+side*.013,-.363,-.030)],[.004,.007,.003],6,3)

def strap(part, mat, points, width=.032):
    path=catmull(points,6);vertices=[]
    for i,p in enumerate(path):
        tangent=(path[min(i+1,len(path)-1)]-path[max(0,i-1)]).normalized()
        across=tangent.cross(Vector((0,0,1))).normalized()*width*.5
        vertices.extend([tuple(p-across),tuple(p+across)])
    obj=mesh(part,mat,vertices,[(i*2,i*2+1,i*2+3,i*2+2) for i in range(len(path)-1)])
    solid=obj.modifiers.new('Cut leather strap','SOLIDIFY');solid.thickness=.005;solid.offset=0

def gripping_hand(part, side, monstrous=False):
    return body_author().hand(sys.modules[__name__],part,side,monstrous)


def fitted_collar(cloth, armor, plated=False):
    # A shaped throat opening seats around the existing anatomical neck. The
    # front descends to a V, preserving the established jaw and face landmarks.
    cols=32
    vertices=[]
    for row in range(4):
        t=row/3
        for col in range(cols):
            a=TAU*col/cols
            front=max(0,-math.cos(a))
            y=(1.485-.025*front)*(1-t)+(1.641-.071*front**3)*t
            rx=.174*(1-t)+.077*t
            rz=.116*(1-t)+.073*t
            vertices.append((rx*math.sin(a),y,rz*math.cos(a)))
    faces=[]
    for row in range(3):
        for col in range(cols):
            n=(col+1)%cols
            faces.append((row*cols+col,row*cols+n,(row+1)*cols+n,(row+1)*cols+col))
    mat=armor if plated else cloth
    obj=mesh('Body',mat,vertices,faces)
    solid=obj.modifiers.new('Lined shaped collar','SOLIDIFY')
    solid.thickness=.008; solid.offset=0
    edge=vertices[-cols:]+[vertices[-cols]]
    tube('Body','leather',edge,.007,6,1)

def gem(part, center, size=.06, mat='soul'):
    return loft(part,mat,[(-size*1.3,.002,.002,0),(-size*.4,size,size*.65,0),(size*.35,size,size*.65,0),(size*1.4,.001,.001,0)],center,6)

def boot(part, armor='iron', nyra=False):
    return body_author().boot(sys.modules[__name__],part,armor,nyra)


def limbs(armor='iron', cloth='wine', monstrous=False, slender=False, nyra=False):
    return body_author().limbs(sys.modules[__name__],armor,cloth,monstrous,slender,nyra)


def torso(armor='iron', cloth='wine', slender=False, nyra=False):
    return body_author().torso(sys.modules[__name__],armor,cloth,slender,nyra)


def cuirass(armor, nyra=False):
    w=.83 if nyra else .95
    body_author().backplate(sys.modules[__name__],armor,nyra)
    formed_plate('Body',armor,[(1.080,.199*w,.163,0),
        (1.155,.226*w,.176,0),(1.260,.253*w,.194,0),
        (1.355,.279*w,.195,0),(1.430,.279*w,.178,0),
        (1.487,.229*w,.132,0),(1.530,.164*w,.112,0)],
        arc=PI*1.21,ridge=.016)
    # Three articulating faulds bridge the torso to the belt. Their upper and
    # lower edges overlap; none becomes a rounded separate abdominal mass.
    for row in range(3):
        y=1.065-row*.052
        formed_plate('Body',armor,[(y-.036,(.208-row*.007)*w,.166,0),
            (y+.020,(.213-row*.007)*w,.172,0)],arc=PI*1.14,ridge=.005)
    for side in [-1,1]:
        tube('Body','gold',[(side*.18*w,1.44,-.148),
            (side*.203*w,1.30,-.145),(side*.157*w,1.12,-.124)],.0045,6,4)

def face(part='Body', skull=False, hood=False, nyra=False):
    if nyra:
        sys.path.insert(0,str(Path(__file__).parent))
        import build_faces
        build_faces.build(sys.modules[__name__],part)
        return
    if skull:
        return body_author().skull(sys.modules[__name__],part)
    skin='bone' if skull else 'skin'
    loft(part,skin,[(1.54,.058,.063,0),(1.65,.062,.068,-.01),(1.71,.065,.070,-.02)],sides=20)
    if nyra:
        # Continuous chin, jaw, cheek and cranial planes. The cheek contour is
        # part of the head, rather than separate inflated spherical pieces.
        loft(part,skin,[(1.654,.030,.037,-.044),(1.679,.054,.057,-.034),
            (1.708,.072,.080,-.023),(1.742,.096,.098,-.025),
            (1.790,.105,.105,-.024),(1.835,.106,.108,-.019),
            (1.883,.101,.101,-.009),(1.924,.075,.072,.008),
            (1.952,.014,.022,.010)],sides=32)
    else:
        ellipsoid(part,skin,(0,1.795,-.015),(.112,.159,.111))
        ellipsoid(part,skin,(0,1.694,-.058),(.072,.049,.064))
    leaf(part,skin,[(0,1.86,-.117),(0,1.80,-.164),(0,1.766,-.13)],.028,.018)
    for side in [-1,1]:
        if not nyra: ellipsoid(part,skin,(side*.074,1.767,-.084),(.027,.028,.032))
        ellipsoid(part,'dark',(side*.047,1.813,-.119),(.026,.020 if skull else .011,.009))
        if nyra:
            ellipsoid(part,'eye',(side*.047,1.813,-.126),(.022,.008,.007),20,8)
            ellipsoid(part,'iris',(side*.047,1.813,-.133),(.008,.0075,.004),16,8)
            ellipsoid(part,'dark',(side*.047,1.813,-.136),(.003,.0045,.002),12,6)
            tube(part,'hair_shadow',[(side*.020,1.849,-.127),(side*.050,1.851,-.137),(side*.080,1.841,-.113)],.0035,6,3)
            ellipsoid(part,skin,(side*.110,1.795,.005),(.017,.035,.024),16,8)
        if skull: gem(part,(side*.051,1.822,-.134),.009)
        tube(part,skin,[(side*.014,1.843,-.117),(side*.052,1.846,-.129),(side*.086,1.831,-.093)],.007,6,3)
    tube(part,'lip' if nyra else 'dark',[(-.030,1.726,-.121),(-.010,1.727,-.130),(0,1.724,-.132),(.010,1.727,-.130),(.030,1.726,-.121)],.0035,8,3)
    if nyra: tube(part,'lip',[(-.023,1.721,-.123),(0,1.718,-.132),(.023,1.721,-.123)],.004,8,3)
    if not skull:
        # Fuse the anatomical forms into one continuous facial surface. Voxel
        # remeshing removes the visible sphere intersections at cheek/jaw/nose.
        objects=PARTS[(part,skin)]
        bpy.ops.object.select_all(action='DESELECT')
        for obj in objects: obj.select_set(True)
        bpy.context.view_layer.objects.active=objects[0]
        bpy.ops.object.join()
        head=objects[0]; head.data.remesh_voxel_size=.003 if nyra else .0045
        bpy.ops.object.voxel_remesh()
        smooth=head.modifiers.new('Facial anatomy smoothing','SMOOTH');smooth.factor=.55;smooth.iterations=5 if nyra else 3
        bpy.ops.object.modifier_apply(modifier=smooth.name)
        decimate=head.modifiers.new('Mobile facial topology','DECIMATE');decimate.ratio=.12 if nyra else .16
        bpy.ops.object.modifier_apply(modifier=decimate.name)
        for poly in head.data.polygons: poly.use_smooth=True
        PARTS[(part,skin)]=[head]
    if skull:
        for i in range(6): ellipsoid(part,'bone',((i-2.5)*.016,1.718,-.125),(.007,.018,.009),12,6)
    elif nyra:
        # A continuous swept cranial cap, fine relief locks and two articulated
        # braids: Nyra stays recognizable in armor, robe and ranger hood.
        drape(part,'hair_shadow',1.949,1.748,.073,.126,.070,.124,arc=PI*1.62,folds=9,offset=(0,0,.010))
        ellipsoid(part,'hair',(0,1.929,.013),(.107,.041,.102),32,10)
        for i in range(15):
            a=-PI*.79+i*PI*1.58/14
            tube(part,'hair',[(math.sin(a)*.040,1.967,math.cos(a)*.044+.015),
                (math.sin(a)*.118,1.911,math.cos(a)*.115+.013),
                (math.sin(a)*.126,1.798,math.cos(a)*.125+.023)], [.016,.014,.004],8,5)
        for side in [-1,1]:
            tube(part,'hair',[(side*.010,1.960,-.050),(side*.065,1.926,-.104),(side*.114,1.846,-.068)], [.017,.021,.006],10,6)
            braid='HairL' if side<0 else 'HairR'
            tube(braid,'hair_shadow',[(side*.116,1.836,.031),(side*.143,1.671,.038),(side*.130,1.494,.054)], [.022,.021,.009],10,6)
            for strand in range(3):
                points=[]
                for j in range(17):
                    t=j/16; a=t*TAU*3+strand*TAU/3
                    points.append((side*(.116+.028*math.sin(t*PI))+.012*math.cos(a),1.836-.342*t,.033+.020*t+.012*math.sin(a)))
                tube(braid,'hair',points,[.008,.007,.003],6,2)
            ring(braid,'gold',(side*.131,1.518,.054),.018,.017,.006)
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
    tailored_drape('Body',cloth,1.98,1.59,.11,.20,.12,.19,arc=PI*1.47,folds=5,offset=(0,0,.025))
    ellipsoid('Body',cloth,(0,1.943,.038),(.146,.095,.133))
    tube('Body','gold',[(-.18,1.60,-.06),(-.16,1.84,-.12),(0,1.996,-.073),(.16,1.84,-.12),(.18,1.60,-.06)],.013,8,6)

def cape(cloth='wine', regal=False):
    return body_author().cape(sys.modules[__name__],cloth,regal)


def skirt(cloth='violet', long=True):
    return body_author().skirt(sys.modules[__name__],cloth,long)


def staff(crozier=False):
    tube('Weapon','leather',[(0,-.53,0),(0,0,0),(.013,.29,.013),(0,1.14,0)], [.024,.028,.030,.025],12,5)
    for y in [-.075,-.030,.015,.060]: ring('Weapon','leather',(0,y,0),.029,.029,.0035)
    for y in [-.43,-.22,.10,.38,.70,1.04]: ring('Weapon','gold',(0,y,0),.042,.042,.009)
    for side in [-1,1]:
        tube('Weapon','bronze' if crozier else 'silver',[(0,1.0,0),(side*.19,1.16,0),(side*.24,1.46,0),(side*.075,1.69,-.005)], [.035,.040,.026,.004],12,7)
    ring('Weapon','gold',(0,1.38,0),.18,.18,.014,'z')
    gem('Weapon',(0,1.4,-.025),.105)
    tube('Weapon','gold',[(.03,1.02,0),(.17,.91,.025),(.14,.76,.04)],.01,6,5)
    gem('Weapon',(.14,.74,.04),.035,'ember')

def sword():
    loft('Weapon','leather',[(-.21,.027,.026,0),(-.13,.031,.027,0),(.10,.030,.026,0),(.12,.028,.026,0)],sides=16,folds=8,amplitude=.05)
    for side in [-1,1]: tube('Weapon','gold',[(0,.1,0),(side*.12,.13,0),(side*.20,.18,-.01)], [.023,.026,.014],10,5)
    gem('Weapon',(0,-.26,0),.052,'ember')
    loft('Weapon','silver',[(.15,.10,.018,0),(.26,.084,.018,0),(1.11,.065,.014,0),(1.39,.001,.001,0)],sides=4)
    tube('Weapon','gold',[(0,.2,-.021),(0,.40,-.021),(0,1.04,-.018)],.007,6,3)

def shield():
    # Convex kite plate, gilded rolled edge, inset heraldic thorn relief.
    outline=[(0,-.93),(-.22,-.65),(-.27,-.28),(-.21,-.13),(0,-.07),(.21,-.13),(.27,-.28),(.22,-.65)]
    vertices=[(-.045,-.4,-.30)]+[(x-.045,y,-.23) for x,y in outline]
    plate=mesh('ArmL','iron',vertices,[(0,i+1,(i+1)%8+1) for i in range(8)])
    solid=plate.modifiers.new('Forged shield plate','SOLIDIFY'); solid.thickness=.018
    tube('ArmL','gold',[(x-.045,y,-.24) for x,y in outline+[outline[0]]],.017,8,3)
    tube('ArmL','silver',[(-.045,-.18,-.275),(-.045,-.43,-.31),(-.045,-.78,-.27)],.018,8,5)
    for side in [-1,1]: tube('ArmL','gold',[(-.045,-.30,-.303),(-.045+side*.12,-.39,-.287),(-.045,-.54,-.30)],.016,8,4)
    for y in [-.36,-.50]:
        tube('ArmL','leather',[(-.13,y,-.23),(-.10,y,-.11),(.015,y,-.095),(.045,y,-.23)],.017,8,4)

def hero(kind):
    cloth={'Vowkeeper':'wine','Arcanist':'violet','Ranger':'sage'}[kind]
    armor='iron' if kind=='Vowkeeper' else 'silver' if kind=='Arcanist' else 'bronze'
    torso(armor,cloth,True,nyra=True); limbs(armor,cloth,slender=True,nyra=True)
    cape(cloth); skirt(cloth,kind=='Arcanist')
    face(hood=kind=='Ranger',nyra=True)
    field_equipment(kind,armor)
    if kind=='Vowkeeper':
        # Open oath circlet and fitted armor preserve the adult heroine's face.
        ring('Body','bronze',(0,1.906,-.010),.123,.126,.010)
        gem('Body',(0,1.905,-.144),.026)
        cuirass('iron',True)
        sword(); shield()
    else:
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
            # The grip is the bone origin. Separate string/arrow geometry binds
            # to draw bones instead of making the right hand pull empty space.
            tube('Weapon','leather',[(0,-.60,.34),(0,-.40,.10),(0,0,0),(0,.40,.10),(0,.60,.34)], [.015,.025,.030,.025,.015],12,8)
            tube('BowString','linen',[(0,-.60,.34),(0,0,.34),(0,.60,.34)],.0035,6,3)
            for side in [-1,1]: tube('Weapon','gold',[(0,side*.43,.13),(.012,side*.54,.25),(0,side*.59,.32)],.007,6,5)
            tube('Arrow','leather',[(0,0,.35),(0,0,-.54)],.005,8,2)
            leaf('Arrow','silver',[(0,0,-.48),(0,0,-.55),(0,0,-.63)],.024,.009)
            for side in [-1,1]: leaf('Arrow','linen',[(0,0,.20),(side*.022,.018,.28),(0,0,.32)],.018,.008)
            loft('Body','leather',[(1.03,.09,.065,0),(1.16,.085,.07,0),(1.58,.10,.075,0)],center=(.18,0,.23),sides=24)
            ring('Body','gold',(.18,1.56,.23),.11,.084,.012)
            for i in range(5):
                x=.13+i*.025
                tube('Body','bone',[(x,1.20,.25),(x,1.74+(i%2)*.045,.25)],.005,6,2)
                leaf('Body','linen',[(x,1.67,.25),(x+.013,1.72,.25),(x,1.79,.25)],.014,.012)

def field_equipment(kind, armor):
    # Layered construction reads at the actual game scale. Rivets and rolled
    # edges belong to the same anatomical part, so every piece follows the rig.
    fitted_collar({'Vowkeeper':'wine','Arcanist':'violet','Ranger':'sage'}[kind],armor,kind=='Vowkeeper')
    for side in [-1,1]:
        arm='ArmL' if side<0 else 'ArmR'
        pauldron(arm,armor if kind!='Ranger' else 'leather',side,
            .89 if kind=='Vowkeeper' else .81,2 if kind=='Vowkeeper' else 1)
        if kind=='Vowkeeper':
            tube('Body','silver',[(side*.07,1.55,-.108),(side*.17,1.52,-.122),(side*.24,1.44,-.139)],.009,8,4)
        elif kind=='Arcanist':
            leaf('Body','iron',[(side*.06,1.61,-.07),(side*.11,1.48,-.133),(side*.15,1.29,-.17)],.034,.016)
        else:
            strap('Body','leather',[(side*.18,1.55,-.116),
                (side*.11,1.455,-.169),(side*.025,1.355,-.197),
                (-side*.07,1.21,-.194),(-side*.12,1.04,-.136)],.034)
            for x,y,z in [(side*.11,1.455,-.172),(-side*.07,1.21,-.197)]:
                ellipsoid('Body','gold',(x,y,z),(.006,.007,.003),8,4)
        # Worn belt pouches and a forged clasp, rather than a single color band.
        ellipsoid('Body','leather',(side*.195,.93,-.048),(.044,.062,.043),16,8)
        for y in [-.43,-.31]:
            ellipsoid(arm,'silver',(side*.07,y,-.063),(.009,.009,.005),8,4)
    leaf('Body','silver',[(0,1.025,-.165),(0,.96,-.181),(0,.906,-.166)],.034,.007)

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
            arm='ArmL' if side<0 else 'ArmR'
            # Smaller bell-shaped shoulder castings repeat the hollow crown's
            # construction without turning the guardian into a winged figure.
            loft(arm,'bronze',[(-.035,.190,.159,0),(-.010,.193,.163,0),
                (.030,.170,.146,0),(.115,.119,.112,0),(.166,.042,.042,0)],
                center=(side*.016,0,.018),sides=24)
            ring(arm,'gold',(side*.016,-.014,.018),.190,.158,.010)
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
        tailored_drape('Body','linen',1.70,.11,.14,.39,.10,.265,PI*1.30,7,True,offset=(0,0,.12),thickness=.008)
        ring('Body','gold',(0,1.94,0),.21,.18,.015)
        for i in range(9):
            a=TAU*i/9
            tube('Body','silver',[(math.sin(a)*.17,1.94,math.cos(a)*.15),
                (math.sin(a)*.25,2.12,math.cos(a)*.22),
                (math.sin(a)*.22,2.30+.08*(i%2),math.cos(a)*.19)], [.018,.026,.002],8,6)
            gem('Body',(math.sin(a)*.235,2.09,math.cos(a)*.20),.025)
        for side in [-1,1]:
            for i in range(4):
                # Burial ribs rise from a connected cowl structure. Their
                # marrow-like taper and open arches replace broad bright leaves.
                tube('Body','bone',[(side*.24,1.44+i*.04,.08),
                    (side*(.42+i*.024),1.59+i*.055,.20),
                    (side*(.56+i*.045),1.78+i*.067,.25),
                    (side*(.55+i*.040),1.93+i*.074,.23),
                    (side*(.42+i*.035),2.00+i*.077,.20)],
                    [.031,.030,.023,.014,.002],10,5)
            tube('Body','bone',[(side*.23,1.43,.085),(side*.27,1.64,.12),
                (side*.35,1.87,.18)],[.041,.033,.009],10,5)
        staff()
    else:
        torso('iron','dark'); skirt('dark',False); cape('dark',True)
        loft('Body','iron',[(1.65,.14,.14,0),(1.77,.18,.17,0),(1.92,.16,.15,0),(2.03,.06,.08,0)],sides=32)
        for side in [-1,1]:
            tube('Body','bronze',[(side*.14,1.91,.045),(side*.32,2.10,.09),(side*.35,2.39,.13),(side*.24,2.59,.18)], [.095,.076,.037,.002],12,8)
            tube('Body','ember',[(side*.055,1.83,-.166),(side*.11,1.86,-.15),(side*.16,1.82,-.10)],.014,8,5)
            arm='ArmL' if side<0 else 'ArmR'
            pauldron(arm,'iron',side,1.48,2)
            # Heavy furnace plates and two short forged studs frame the
            # horned head; the old repeating upward fins are removed.
            for z in [-.065,.075]:
                tube(arm,'iron',[(side*.10,.05,z),(side*.16,.17,z+.025),
                    (side*.18,.205,z+.030)],[.036,.022,.002],8,4)
        gem('Body',(0,1.31,-.22),.13,'ember')
        for side in [-1,1]:
            tube('Body','ember',[(side*.02,1.44,-.19),(side*.13,1.39,-.227),(side*.08,1.18,-.20),(side*.19,1.09,-.15)],.009,6,5)
        tube('Weapon','leather',[(0,-.3,0),(0,.9,0)],.043,12,3)
        for side in [-1,1]:
            leaf('Weapon','iron',[(0,.83,0),(side*.36,.79,0),(side*.44,1.13,0)],.19,.11)
            tube('Weapon','ember',[(side*.02,.9,-.08),(side*.28,.91,-.11),(side*.38,1.10,-.05)],.018,8,5)

def enemy(kind):
    if kind=='raider':
        body_author().raider_body(sys.modules[__name__])
        limbs('bone','ash',True,True); face(skull=True)
        for i in range(3): tube('Weapon','bone',[((i-1)*.044,0,0),((i-1)*.05,-.16,-.04),((i-1)*.06,-.32,-.12)], [.025,.017,.002],8,5)
        skirt('ash',False)
        # The scavenged clasp retains the raider's original gold channel while
        # replacing the old bright trim along both ragged skirt panels.
        leaf('Body','gold',[(0,.995,-.124),(0,.955,-.132),(0,.916,-.124)],.023,.008)
    elif kind=='hexer':
        torso('bronze','sage',True); limbs('bronze','sage',slender=True)
        face(skull=True); hood('sage'); skirt('sage'); cape('sage'); staff()
        fitted_collar('sage','bronze')
    else:
        torso('bronze','wine'); limbs('bronze','wine'); skirt('wine',False); cape('wine')
        loft('Body','bronze',[(1.67,.13,.12,0),(1.8,.15,.14,0),(1.94,.13,.12,0),(2.01,.04,.05,0)],sides=24)
        for side in [-1,1]:
            if kind=='bulwark':
                tube('Body','bone',[(side*.12,1.91,.01),(side*.25,2.03,.02),
                    (side*.27,2.10,-.045)], [.047,.030,.010],8,6)
            else:
                tube('Body','bone',[(side*.12,1.91,.01),(side*.27,2.05,.02),
                    (side*.29,2.27 if side>0 else 2.18,.06)], [.047,.025,.002],8,6)
            tube('Body','ember',[(side*.025,1.82,-.14),(side*.10,1.83,-.112)],.008,6,3)
        if kind=='bulwark':
            # A central forged crest keeps the original standing-height
            # envelope; the low side horns give the shield bearer a different
            # head mass from the elite's tall asymmetric horns.
            leaf('Body','bronze',[(0,1.965,.015),(0,2.18,.05),(0,2.27,.07)],.085,.023)
        sword()
        if kind=='bulwark': shield()

def export(name, build):
    global PARTS, MATS, ACTIVE_MODEL
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    PARTS=defaultdict(list); MATS={};ACTIVE_MODEL=name
    build()
    if name in ('vowkeeper','arcanist','ranger'):
        # Adult proportions: longer anatomical legs and arms, a smaller head,
        # fitted shoulder plates. Rig rests and authored hand targets use the
        # same measurements (see CharacterRig / CharacterAnimation).
        for (part, _), objects in PARTS.items():
            for obj in objects:
                for vertex in obj.data.vertices:
                    x,z,y=vertex.co.x,-vertex.co.y,vertex.co.z
                    if part in ('Body','HairL','HairR'):
                        if y<=.90: y*=1.17
                        elif y<1.60: y+=.153
                        else: y=1.753+(y-1.60)*.86; x*=.95
                    elif part.startswith('Arm'): y*=1.14
                    elif part.startswith('Leg') or part.startswith('Knee'): y*=1.17
                    vertex.co=xyz((x,y,z))
                obj.data.update()
    # Join by animated part and material. Blender evaluates sewn garment
    # thickness before export. Godot bakes these parts into one GPU-skinned surface per actor.
    for (part, mat), objects in PARTS.items():
        bpy.ops.object.select_all(action='DESELECT')
        for obj in objects:
            obj.select_set(True)
            bpy.context.view_layer.objects.active=obj
            for modifier in list(obj.modifiers): bpy.ops.object.modifier_apply(modifier=modifier.name)
        bpy.context.view_layer.objects.active=objects[0]
        if len(objects)>1: bpy.ops.object.join()
        objects[0].name=part+'__'+mat
        if name in ('vowkeeper','arcanist','ranger') and len(objects[0].data.polygons)>150:
            mobile=objects[0].modifiers.new('Mobile silhouette preserving topology','DECIMATE')
            mobile.ratio=.94 if mat in ['skin','lip','lip_shadow','eye','iris'] else (.61 if name=='vowkeeper' else .565)
            bpy.ops.object.modifier_apply(modifier=mobile.name)
    character_names={'vowkeeper','arcanist','ranger','guardian_0','guardian_1',
        'guardian_2','guardian_3','raider','hexer','bulwark','elite'}
    def triangle_count(obj):
        obj.data.calc_loop_triangles()
        return len(obj.data.loop_triangles)
    objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
    triangles=sum(triangle_count(o) for o in objects)
    if name in character_names and triangles>36750:
        # Spend the mobile budget on the face and silhouette, preserving the
        # already calibrated facial/eye/hair meshes exactly. Reduce dense
        # garment interiors and small equipment relief by a measured ratio.
        protected={'skin','lip','lip_shadow','eye','iris','hair','hair_shadow','dark'}
        reducible=[o for o in objects if len(o.data.polygons)>150 and not (
            name in ('vowkeeper','arcanist','ranger') and
            o.name.split('__',1)[1] in protected)]
        movable=sum(triangle_count(o) for o in reducible)
        fixed=triangles-movable
        ratio=(36400-fixed)/movable
        for obj in reducible:
            bpy.context.view_layer.objects.active=obj
            mobile=obj.modifiers.new('Measured mobile garment budget','DECIMATE')
            mobile.ratio=ratio
            bpy.ops.object.modifier_apply(modifier=mobile.name)
        triangles=sum(triangle_count(o) for o in objects)
    if name in character_names:
        assert triangles<=40000, (name,triangles)
    OUT.mkdir(parents=True,exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',
        export_yup=True,export_texcoords=False,export_normals=True,export_materials='EXPORT',
        export_cameras=False,export_lights=False,export_animations=False,export_extras=False)
    print('EMBERFALL_MODEL',name,'triangles',triangles)

if __name__ == '__main__':
    for name in ['Vowkeeper','Arcanist','Ranger']: export(name.lower(),lambda n=name:hero(n))
    for region in range(4): export('guardian_'+str(region),lambda r=region:boss(r))
    for name in ['raider','hexer','bulwark','elite']: export(name,lambda n=name:enemy(n))
