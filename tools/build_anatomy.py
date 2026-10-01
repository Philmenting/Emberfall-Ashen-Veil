"""Independent asset conversion, using only the CC0 MakeHuman mesh and morph data.
No MakeHuman program source is used. Output is glTF 2.0 with seven weighted joints.
"""
from pathlib import Path
import math, json, struct, collections, tempfile, hashlib, urllib.request
ROOT=Path(__file__).resolve().parents[1]
SRC=Path(tempfile.gettempdir())/'emberfall-cc0-art-a8bc2d54'
SRC.mkdir(parents=True,exist_ok=True)
COMMIT='a8bc2d54ff0ac92e78ff71431b1023eda42bf482'
SOURCES={
 'makehuman/data/3dobjs/base.obj':'d26635e9326e3cca30778fd7b9c00062b03cce09',
 'makehuman/data/targets/macrodetails/caucasian-female-young.target':'9d1f0cbeedc9a6a51abe33f1ebb5fa7c5a7edbf1',
 'makehuman/data/targets/macrodetails/caucasian-male-young.target':'c3b82f92c5ced85599199cd184b0faf3b3fc6881',
}
for source,expected in SOURCES.items():
    local=SRC/Path(source).name
    if not local.exists():
        url=f'https://raw.githubusercontent.com/makehumancommunity/makehuman/{COMMIT}/{source}'
        with urllib.request.urlopen(url,timeout=60) as response:
            local.write_bytes(response.read())
    content=local.read_bytes()
    digest=hashlib.sha1(b'blob '+str(len(content)).encode()+b'\0'+content).hexdigest()
    if digest!=expected:
        raise ValueError('Source hash mismatch: '+source)

def add(a,b): return tuple(x+y for x,y in zip(a,b))
def sub(a,b): return tuple(x-y for x,y in zip(a,b))
def mul(a,s): return tuple(x*s for x in a)
def dot(a,b): return sum(x*y for x,y in zip(a,b))
def cross(a,b): return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def unit(a): return mul(a,1/max(math.sqrt(dot(a,a)),1e-12))
def smooth(x):
    x=max(0,min(1,x))
    return x*x*(3-2*x)
def mix(a,b,t): return add(mul(a,1-t),mul(b,t))
def obj(path):
    verts,uv,faces,groups=[],[],[],collections.defaultdict(list)
    group=''
    for l in path.read_text().splitlines():
        s=l.split()
        if not s: continue
        if s[0]=='v': verts.append(tuple(map(float,s[1:4])))
        elif s[0]=='vt': uv.append(tuple(map(float,s[1:3])))
        elif s[0]=='g': group=s[1]
        elif s[0]=='f':
            face=[tuple(int(t)-1 for t in x.split('/')[:2]) for x in s[1:]]
            groups[group].extend(x[0] for x in face)
            if group=='body': faces.append(face)
    return verts,uv,faces,groups

BASE,UV,FACES,GROUPS=obj(SRC/'base.obj')
def build(gender):
    v=list(BASE)
    for l in (SRC/f'caucasian-{gender}-young.target').read_text().splitlines():
        s=l.split()
        if len(s)==4 and s[0].isdigit():
            i=int(s[0])
            v[i]=add(v[i],tuple(map(float,s[1:])))
    def joint(name):
        pts=[v[i] for i in set(GROUPS['joint-'+name])]
        return tuple(sum(p[k] for p in pts)/len(pts) for k in range(3))
    body_indices=set(i for f in FACES for i,_ in f)
    ground=min(v[i][1] for i in body_indices)
    top=max(v[i][1] for i in body_indices)
    levels=[(ground,0.015),(joint('l-ankle')[1],.12),(joint('l-knee')[1],.50),(joint('l-upper-leg')[1],.89),(joint('l-shoulder')[1],1.47),(joint('neck')[1],1.62),(joint('head')[1],1.83),(top,2.03)]
    def map_y(y):
        for (a,u),(b,w) in zip(levels,levels[1:]):
            if y<=b: return u+(w-u)*(y-a)/(b-a)
        return 2.03
    def body_point(p):
        x,y,z=p
        target_y=map_y(y)
        if y<joint('l-upper-leg')[1]:
            leg_center=joint('l-upper-leg')[0]+(joint('l-ankle')[0]-joint('l-upper-leg')[0])*max(0,min(1,(joint('l-upper-leg')[1]-y)/(joint('l-upper-leg')[1]-joint('l-ankle')[1])))
            target_x=x*.13+math.copysign((.18-leg_center*.13)*smooth(abs(x)/.9),x)
        else: target_x=x*(.16 if y<joint('neck')[1] else .12)
        return (target_x,target_y,-(z-.14)*.12)
    def align(p,a,b,ta,tb):
        source=unit(sub(b,a))
        target=unit(sub(tb,ta))
        axis=cross(source,target)
        c=dot(source,target)
        q=sub(p,a)
        rotated=add(add(mul(q,c),cross(axis,q)),mul(axis,dot(axis,q)/max(1+c,1e-6)))
        return add(ta,mul(rotated,math.sqrt(dot(sub(tb,ta),sub(tb,ta)))/math.sqrt(dot(sub(b,a),sub(b,a)))))
    pos,weights,colors={}, {},{}
    for i in body_indices:
        p=v[i]
        x,y,z=p
        side=1 if x>0 else -1
        side_name='l' if side>0 else 'r'
        shoulder=joint(side_name+'-shoulder')
        elbow=joint(side_name+'-elbow')
        wrist=joint(side_name+'-hand')
        arm_weight=smooth((abs(x)-abs(shoulder[0])+.28)/.65) if y<shoulder[1]+.60 and y>joint('l-upper-leg')[1]+.9 else 0
        out=body_point(p)
        if arm_weight>0:
            a,b,ta,tb=shoulder,elbow,(side*.33,1.47,0),(side*.33,1.16,0)
            upper=align(p,a,b,ta,tb)
            lower=align(p,elbow,wrist,(side*.33,1.16,0),(side*.33,.90,-.035))
            transition=smooth((abs(x)-abs(elbow[0])+.25)/.50)
            arm= mix(upper,lower,transition)
            out=mix(out,arm,arm_weight)
        w=[0.0]*7
        if arm_weight>0:
            w[2 if side>0 else 1]=arm_weight
            w[0]=1-arm_weight
        elif y<joint('l-upper-leg')[1]+.40:
            leg_weight=smooth((joint('l-upper-leg')[1]+.40-y)/.75)
            knee_weight=smooth((joint('l-knee')[1]+.38-y)/.76)
            w[4 if side>0 else 3]=leg_weight*(1-knee_weight)
            w[6 if side>0 else 5]=leg_weight*knee_weight
            w[0]=1-leg_weight
        else: w[0]=1
        pos[i]=out
        weights[i]=w
        skin=y>joint('neck')[1]+.06 or abs(x)>abs(wrist[0])-.35
        color=(1.0,.97,.95,1.0 if skin else 0.0)
        # Pigment follows sculpted facial landmarks, rather than floating decal shapes.
        jaw=joint('jaw')
        if skin and abs(x)<.38 and jaw[1]-.02<y<jaw[1]+.40 and z>jaw[2]-.06:
            color=(.76,.46,.44,1.0)
        eye=joint(side_name+'-eye')
        if abs(abs(x)-abs(eye[0]))<.28 and eye[1]+.10<y<eye[1]+.22 and z>eye[2]-.05:
            color=(.29,.21,.18,1.0)
        colors[i]=color
    triangles=[]
    for f in FACES:
        for n in range(1,len(f)-1): triangles.append((f[0],f[n+1],f[n]))
    normals=collections.defaultdict(lambda:(0,0,0))
    for t in triangles:
        a,b,c=[pos[i] for i,_ in t]
        n=cross(sub(b,a),sub(c,a))
        for i,_ in t: normals[i]=add(normals[i],n)
    points,norm,tex,col,joints,weight,indices=[],[],[],[],[],[],[]
    remap={}
    for t in triangles:
        for pair in t:
            i,u=pair
            if pair not in remap:
                remap[pair]=len(points)
                points.append(pos[i])
                norm.append(unit(normals[i]))
                tex.append((UV[u][0],1-UV[u][1]))
                col.append(colors[i])
                nonzero=[(j,w) for j,w in enumerate(weights[i]) if w>0]
                nonzero+= [(0,0)]*(4-len(nonzero))
                joints.append(tuple(j for j,w in nonzero))
                weight.append(tuple(w for j,w in nonzero))
            indices.append(remap[pair])
    binary=bytearray()
    views=[]
    accessors=[]
    def data(values,fmt,component,kind,target=None):
        while len(binary)%4: binary.append(0)
        start=len(binary)
        width={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[kind]
        for row in values:
            binary.extend(struct.pack('<'+fmt*width,*row) if width>1 else struct.pack('<'+fmt,row))
        view={'buffer':0,'byteOffset':start,'byteLength':len(binary)-start}
        if target: view['target']=target
        views.append(view)
        acc={'bufferView':len(views)-1,'componentType':component,'count':len(values),'type':kind}
        if kind=='VEC3':
            acc['min']=[min(p[k] for p in values) for k in range(3)]
            acc['max']=[max(p[k] for p in values) for k in range(3)]
        accessors.append(acc)
        return len(accessors)-1
    attrs={name:data(values,fmt,component,kind,34962) for name,values,fmt,component,kind in [('POSITION',points,'f',5126,'VEC3'),('NORMAL',norm,'f',5126,'VEC3'),('TEXCOORD_0',tex,'f',5126,'VEC2'),('COLOR_0',col,'f',5126,'VEC4'),('JOINTS_0',joints,'H',5123,'VEC4'),('WEIGHTS_0',weight,'f',5126,'VEC4')]}
    index_acc=data(indices,'I',5125,'SCALAR',34963)
    rest=[(0,0,0),(-.33,1.47,0),(.33,1.47,0),(-.18,.89,0),(.18,.89,0),(-.18,.50,0),(.18,.50,0)]
    inv=[]
    for x,y,z in rest: inv.append((1,0,0,0,0,1,0,0,0,0,1,0,-x,-y,-z,1))
    inv_acc=data(inv,'f',5126,'MAT4')
    nodes=[{'name':'AnatomyRoot','children':[1,2]},{'name':'Anatomy','mesh':0,'skin':0},{'name':'Torso','children':[3,4,5,6]}]
    nodes.extend([{'name':'ArmL','translation':[-.33,1.47,0]},{'name':'ArmR','translation':[.33,1.47,0]},{'name':'LegL','translation':[-.18,.89,0],'children':[7]},{'name':'LegR','translation':[.18,.89,0],'children':[8]},{'name':'KneeL','translation':[0,-.39,0]},{'name':'KneeR','translation':[0,-.39,0]}])
    doc={'asset':{'version':'2.0','generator':'Emberfall original CC0 asset conversion'},'scene':0,'scenes':[{'nodes':[0]}],'nodes':nodes,'meshes':[{'name':'Nyra' if gender=='female' else 'Ashen','primitives':[{'attributes':attrs,'indices':index_acc,'material':0}]}],'materials':[{'name':'AnatomySurface','pbrMetallicRoughness':{'metallicFactor':0,'roughnessFactor':.68}}],'skins':[{'inverseBindMatrices':inv_acc,'joints':[2,3,4,5,6,7,8],'skeleton':2}],'buffers':[{'byteLength':len(binary)}],'bufferViews':views,'accessors':accessors}
    json_bytes=json.dumps(doc,separators=(',',':')).encode()
    json_bytes+=b' '*((-len(json_bytes))%4)
    binary+=b'\0'*((-len(binary))%4)
    glb=struct.pack('<III',0x46546c67,2,12+8+len(json_bytes)+8+len(binary))+struct.pack('<II',len(json_bytes),0x4e4f534a)+json_bytes+struct.pack('<II',len(binary),0x004e4942)+binary
    dest=ROOT/'assets/models'/('nyra-anatomy.glb' if gender=='female' else 'ashen-anatomy.glb')
    dest.parent.mkdir(parents=True,exist_ok=True)
    dest.write_bytes(glb)
    eyes=[body_point(joint(s+'-eye')) for s in ['r','l']]
    print(gender,len(points),'vertices',len(triangles),'triangles',len(glb),'bytes','eyes',eyes)
    return {'vertices':len(points),'triangles':len(triangles),'eyes':eyes}
stats={g:build(g) for g in ['female','male']}
(ROOT/'assets/models/anatomy-metadata.json').write_text(json.dumps(stats,indent=2))
