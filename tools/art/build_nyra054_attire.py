#!/usr/bin/env python3
"""Build separate coat, bindings and shoulder metal from Nyra's native65 source.

No body vertices/rest bones/skin weights/images are changed. Upper cloth and
shoulder details are shells of indexed artist surfaces with inherited weights.
Split tails inherit same-side garment weights; every component uses source bind
matrices. The tiny output contains geometry and native rest only, never images.
"""
from pathlib import Path
import argparse, copy, hashlib, json, math, struct
import numpy as np

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--source',type=Path,default=Path('assets/models/nyra052/arcanist.glb'))
parser.add_argument('--output',type=Path,default=Path('assets/models/nyra054/nyra-attire054.glb'))
args=parser.parse_args()
raw=args.source.read_bytes();size=struct.unpack_from('<I',raw,12)[0]
src=json.loads(raw[20:20+size]);source_blob=raw[28+size:]

def array(index):
    a=src['accessors'][index];v=src['bufferViews'][a['bufferView']]
    dtype={5126:'<f4',5123:'<u2',5125:'<u4',5121:'u1'}[a['componentType']]
    count={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']]
    return np.ndarray((a['count'],count),dtype=dtype,buffer=source_blob,
        offset=v.get('byteOffset',0)+a.get('byteOffset',0),
        strides=(v.get('byteStride',np.dtype(dtype).itemsize*count),np.dtype(dtype).itemsize)).copy()

def source_mesh(name):
    mesh=next(m for m in src['meshes'] if name in m['name'])
    p=mesh['primitives'][0]
    return {k:array(v) for k,v in p['attributes'].items()},array(p['indices']).reshape(-1,3)

body,body_tri=source_mesh('Peasant_Body');arms,arm_tri=source_mesh('Peasant_Arms')
legs,_=source_mesh('Peasant_Legs')
# Keep the original joint node indices/order and inverse bind matrices. Nothing
# from the original image buffers, animations or original full body is copied.
joints=src['skins'][0]['joints'];nodes=copy.deepcopy(src['nodes'][:65])
for node in nodes:
    node['children']=[c for c in node.get('children',[]) if c<65]
    if not node['children']:node.pop('children',None)
nodes.append({'name':'Nyra054_Attire','children':[64]})
d={'asset':{'version':'2.0','generator':'Emberfall native65 fitted attire 054'},
   'scene':0,'scenes':[{'nodes':[65]}],'nodes':nodes,'skins':[],
   'buffers':[],'bufferViews':[],'accessors':[],'meshes':[],'materials':[
   {'name':'Nyra054_Midnight_Cloth','doubleSided':True,'pbrMetallicRoughness':{'baseColorFactor':[.021,.040,.064,1],'metallicFactor':0,'roughnessFactor':.88}},
   {'name':'Nyra054_Worn_Bronze','doubleSided':True,'pbrMetallicRoughness':{'baseColorFactor':[.31,.17,.065,1],'metallicFactor':.72,'roughnessFactor':.47}},
   {'name':'Nyra054_Soot_Leather','doubleSided':True,'pbrMetallicRoughness':{'baseColorFactor':[.028,.018,.017,1],'metallicFactor':0,'roughnessFactor':.66}},
   {'name':'Nyra054_Blue_Gem','pbrMetallicRoughness':{'baseColorFactor':[.035,.25,.32,1],'metallicFactor':.3,'roughnessFactor':.21}}]}
blob=bytearray();reports=[]

def accessor(a,typ=None,component=None):
    a=np.ascontiguousarray(a);blob.extend(b'\0'*((-len(blob))%4));offset=len(blob);payload=a.tobytes();blob.extend(payload)
    view=len(d['bufferViews']);d['bufferViews'].append({'buffer':0,'byteOffset':offset,'byteLength':len(payload)})
    value={'bufferView':view,'componentType':component or (5126 if a.dtype.kind=='f' else 5123),'count':len(a),'type':typ or {1:'SCALAR',2:'VEC2',3:'VEC3',4:'VEC4',16:'MAT4'}[a.shape[1]]}
    if value['type'] in ['VEC3','SCALAR']:value.update(min=a.min(0).tolist(),max=a.max(0).tolist())
    index=len(d['accessors']);d['accessors'].append(value);return index

ibm=array(src['skins'][0]['inverseBindMatrices'])
d['skins'].append({'name':'Armature','joints':joints,'inverseBindMatrices':accessor(ibm.astype('<f4'),'MAT4')})

def normals(points,triangles):
    n=np.zeros_like(points,dtype=float)
    for tri in triangles:
        face=np.cross(points[tri[1]]-points[tri[0]],points[tri[2]]-points[tri[0]])
        n[tri]+=face
    length=np.linalg.norm(n,axis=1);n/=np.maximum(length[:,None],1e-9)
    return n

class Part:
    def __init__(self,name,material):self.name=name;self.material=material;self.p=[];self.n=[];self.uv=[];self.j=[];self.w=[];self.tri=[]
    def vertex(self,point,normal,uv,joints,weights):
        self.p.append(point);self.n.append(normal);self.uv.append(uv);self.j.append(joints);self.w.append(weights);return len(self.p)-1
    def finish(self,recalculate=False):
        if not self.tri:return
        p=np.asarray(self.p,dtype='<f4');tri=np.asarray(self.tri,dtype='<u2')
        n=normals(p,tri) if recalculate else np.asarray(self.n)
        j=np.asarray(self.j,dtype='<u2');w=np.asarray(self.w,dtype='<f4')
        assert np.isfinite(p).all() and np.isfinite(n).all() and np.isfinite(w).all()
        assert np.max(abs(w.sum(1)-1))<1e-5 and j.max()<65
        attributes={'POSITION':accessor(p),'NORMAL':accessor(n.astype('<f4')),'TEXCOORD_0':accessor(np.asarray(self.uv,dtype='<f4')),'JOINTS_0':accessor(j),'WEIGHTS_0':accessor(w)}
        mi=len(d['meshes']);d['meshes'].append({'name':self.name,'primitives':[{'attributes':attributes,'indices':accessor(tri.reshape(-1,1),'SCALAR',5123),'material':self.material}]})
        ni=len(d['nodes']);d['nodes'].append({'name':self.name,'mesh':mi,'skin':0});d['nodes'][65]['children'].append(ni)
        reports.append({'name':self.name,'vertices':len(p),'triangles':len(tri),'material':d['materials'][self.material]['name'],'source_coordinates_bounds':[p.min(0).tolist(),p.max(0).tolist()], 'maximum_weight_sum_error':float(np.max(abs(w.sum(1)-1)))})

def shell(name,data,triangles,selection,offset,material):
    chosen=triangles[selection];used=np.unique(chosen);mapping={int(old):i for i,old in enumerate(used)}
    part=Part(name,material)
    for old in used:
        n=data['NORMAL'][old];p=data['POSITION'][old]+n*offset
        part.vertex(p,n,data['TEXCOORD_0'][old],data['JOINTS_0'][old],data['WEIGHTS_0'][old])
    part.tri=[[mapping[int(v)] for v in t] for t in chosen]
    part.source_points=[data['POSITION'][old] for old in used]
    part.finish()
    return part

def source_vertex(data,index):
    weights=np.zeros(65)
    for bone,weight in zip(data['JOINTS_0'][index],data['WEIGHTS_0'][index]):weights[int(bone)]+=weight
    return {'p':data['POSITION'][index].astype(float),'n':data['NORMAL'][index].astype(float),'uv':data['TEXCOORD_0'][index].astype(float),'weights':weights}

def clip_polygon(polygon,plane):
    # Clip real triangle edges, including native skin and UV interpolation.
    # Selecting a triangle by its centroid made sawtooth front edges. The
    # clipping plane intersects it at the actual continuous panel boundary.
    if not polygon:return []
    result=[]
    previous=polygon[-1];old_distance=float(np.dot(previous['p'],plane[:3])+plane[3])
    for current in polygon:
        distance=float(np.dot(current['p'],plane[:3])+plane[3])
        old_inside=old_distance>=-1e-10;inside=distance>=-1e-10
        if old_inside!=inside:
            fraction=old_distance/(old_distance-distance)
            result.append({key:previous[key]+(current[key]-previous[key])*fraction for key in previous})
        if inside:result.append(current)
        previous=current;old_distance=distance
    return result

def clipped_shell(name,data,triangles,regions,offset,material):
    part=Part(name,material);part.source_points=[];cache={}
    for tri in triangles:
        original=[source_vertex(data,int(i)) for i in tri]
        for planes in regions:
            polygon=original
            for plane in planes:polygon=clip_polygon(polygon,np.asarray(plane,dtype=float))
            if len(polygon)<3:continue
            ids=[]
            for v in polygon:
                n=v['n']/max(np.linalg.norm(v['n']),1e-8)
                # Native target bones are untouched. Only newly intersected
                # boundary vertices interpolate source influences; keep the
                # largest four if a boundary spans two different skin sets.
                j=np.argsort(v['weights'])[-4:][::-1];w=v['weights'][j];w/=w.sum()
                point=v['p']+n*offset
                identity=tuple(np.round(np.r_[point,n,v['uv'],j,w],7))
                if identity not in cache:
                    cache[identity]=part.vertex(point,n,v['uv'],j,w)
                    part.source_points.append(v['p'])
                ids.append(cache[identity])
            for k in range(1,len(ids)-1):
                t=[ids[0],ids[k],ids[k+1]]
                if np.linalg.norm(np.cross(np.asarray(part.p[t[1]])-part.p[t[0]],np.asarray(part.p[t[2]])-part.p[t[0]]))>1e-9:part.tri.append(t)
    part.finish()
    return part

# A clean fitted taper, rather than the original centroid-selected teeth.
# Stop below the source standing collar: duplicating both sides of that
# original folded collar produced floating rings around the actual neck.
knots=[(1.012,.078),(1.16,.063),(1.29,.098),(1.465,.058)]
regions=[]
for (y0,x0),(y1,x1) in zip(knots,knots[1:]):
    slope=(x1-x0)/(y1-y0);intercept=x0-slope*y0
    band=[[0,1,0,-y0],[0,-1,0,y1]]
    regions.append(band+[[0,0,-1,.018]])
    for sign in [-1,1]:regions.append(band+[[0,0,1,-.018],[sign,-slope,0,-intercept]])
coat=clipped_shell('Nyra054_Open_Coat_Bodice',body,body_tri,regions,.010,0)
for side,sign in [('Left',1),('Right',-1)]:
    planes=[[sign,0,0,-.170],[-sign,0,0,.270],[0,1,0,-1.405]]
    clipped_shell('Nyra054_'+side+'_Shoulder_Bronze',arms,arm_tri,[planes],.012,1)

# Narrow bound border around the actual open-coat shell. The edge graph is
# topological; each end keeps its source normal and full four-weight skin.
edges={}
for t in coat.tri:
    for a,b in [(t[0],t[1]),(t[1],t[2]),(t[2],t[0])]:
        # The source has UV-split vertices. Weld the edge identity by
        # original geometric positions so interior UV seams do not grow
        # ornamental metal and turn the coat into a wireframe.
        pa=tuple(np.round(coat.source_points[a],5));pb=tuple(np.round(coat.source_points[b],5))
        pair=tuple(sorted([pa,pb]))
        if pair not in edges:edges[pair]=[a,b,0]
        edges[pair][2]+=1
border=Part('Nyra054_Bodice_Bronze_Binding',1)
lapel=Part('Nyra054_Lapel_Leather_Facing',2)
for a,b,count in edges.values():
    if count!=1:continue
    p=np.asarray(coat.p[a]);q=np.asarray(coat.p[b]);n=np.asarray(coat.n[a]);m=np.asarray(coat.n[b]);axis=q-p
    if np.linalg.norm(axis)<1e-6:continue
    across=np.cross(axis,n+m);across/=max(np.linalg.norm(across),1e-8);across*=.0032
    base=len(border.p)
    for index,point,delta in [(a,p,-across),(a,p,across),(b,q,-across),(b,q,across)]:
        border.vertex(point+delta+np.asarray(coat.n[index])*.0018,coat.n[index],coat.uv[index],coat.j[index],coat.w[index])
    border.tri.extend([[base,base+1,base+2],[base+1,base+3,base+2]])
    if min(p[2],q[2])>.018-1e-6 and min(p[1],q[1])>1.10 and max(abs(p[0]),abs(q[0]))<.118:
        into=np.cross(axis,n+m);into/=max(np.linalg.norm(into),1e-8)
        if into[0]*p[0]<0:into=-into
        base=len(lapel.p)
        for index,point,delta in [(a,p,np.zeros(3)),(a,p,into*.017),(b,q,np.zeros(3)),(b,q,into*.017)]:
            lapel.vertex(point+delta+np.asarray(coat.n[index])*.0014,coat.n[index],coat.uv[index],coat.j[index],coat.w[index])
        t=[base,base+1,base+2]
        face=np.cross(np.asarray(lapel.p[t[1]])-lapel.p[t[0]],np.asarray(lapel.p[t[2]])-lapel.p[t[0]])
        if np.dot(face,n+m)>0:lapel.tri.extend([[base,base+1,base+2],[base+1,base+3,base+2]])
        else:lapel.tri.extend([[base,base+2,base+1],[base+1,base+2,base+3]])
border.finish();lapel.finish()

# Split coat tails are knee length. A separate same-side panel follows the
# original trouser skin, with a 40 mm back vent and open front; there is no
# rigid pelvis-bound skirt bridging walking legs or simulation cloth claim.
for side,sign in [('Left',1),('Right',-1)]:
    part=Part('Nyra054_'+side+'_Split_Tail',0)
    binding=Part('Nyra054_'+side+'_Tail_Binding',1)
    rows=9;columns=21;ring=[]
    for row in range(rows):
        t=row/(rows-1);y=1.032-.444*t;rx=.160+.089*t;rz=.115+.078*t
        front_angle=math.asin(.078/.160)+(.67-math.asin(.078/.160))*t
        center_z=.008-.026*t
        for col in range(columns):
            u=col/(columns-1);angle=front_angle+(math.pi-.10-front_angle)*u
            # Real fine cloth folds, not a painted depth map.
            pleat=.0035*math.sin(u*math.pi*8)*math.sin(t*math.pi/2)
            x=sign*(rx+pleat)*math.sin(angle);z=(rz+pleat)*math.cos(angle)+center_z
            point=np.array([x,y,z]);normal=np.array([sign*math.sin(angle),.04,math.cos(angle)]);normal/=np.linalg.norm(normal)
            candidates=body if row==0 else legs
            same_side=np.where(candidates['POSITION'][:,0]*sign>0)[0]
            distances=np.sum((candidates['POSITION'][same_side]-point)**2,axis=1)
            nearest=same_side[int(np.argmin(distances))]
            part.vertex(point,normal,[u,t],candidates['JOINTS_0'][nearest],candidates['WEIGHTS_0'][nearest])
    for row in range(rows-1):
        for col in range(columns-1):
            a=row*columns+col;b=a+1;c=a+columns;e=c+1
            part.tri.extend([[a,c,b],[b,c,e]] if sign>0 else [[a,b,c],[b,e,c]])
    part.finish(recalculate=True)
    # Bound narrow front and back edges and hem with the same weights.
    for path in [[row*columns for row in range(rows)],[row*columns+columns-1 for row in range(rows)],list(range((rows-1)*columns,rows*columns))]:
        for a,b in zip(path,path[1:]):
            p=np.asarray(part.p[a]);q=np.asarray(part.p[b]);n=np.asarray(part.n[a]);m=np.asarray(part.n[b]);across=np.cross(q-p,n+m);across/=max(np.linalg.norm(across),1e-8);across*=.0025;base=len(binding.p)
            for index,point,delta in [(a,p,-across),(a,p,across),(b,q,-across),(b,q,across)]:
                binding.vertex(point+delta+np.asarray(part.n[index])*.0016,part.n[index],part.uv[index],part.j[index],part.w[index])
            binding.tri.extend([[base,base+1,base+2],[base+1,base+3,base+2]])
    binding.finish()

# A fitted forehead circlet. Head is the original native joint, not a separate
# improvised facial mesh. Its very small jewel stays above the original brows.
head=joints.index(next(i for i,node in enumerate(src['nodes']) if node.get('name')=='Head'))
fixed_j=[head,0,0,0];fixed_w=[1.,0,0,0]
circlet=Part('Nyra054_Forehead_Circlet',1)
for segment in range(24):
    for edge in [-1,1]:
        t=segment/23;angle=-1.14+2.28*t;y=1.714+.009*(1-abs(t*2-1))+edge*.0022
        p=[.084*math.sin(angle),y,.091*math.cos(angle)-.009]
        circlet.vertex(p,[math.sin(angle),0,math.cos(angle)],[t,(edge+1)/2],fixed_j,fixed_w)
for segment in range(23):
    a=segment*2;circlet.tri.extend([[a,a+2,a+1],[a+1,a+2,a+3]])
circlet.finish()
gem=Part('Nyra054_Circlet_Gem',3)
for p in [[0,1.723,.096],[-.0065,1.716,.091],[0,1.708,.091],[.0065,1.716,.091],[0,1.716,.101]]:gem.vertex(p,[0,0,1],[0,0],fixed_j,fixed_w)
gem.tri=[[0,1,4],[1,2,4],[2,3,4],[3,0,4]];gem.finish(recalculate=True)

blob.extend(b'\0'*((-len(blob))%4));d['buffers']=[{'byteLength':len(blob)}]
meta=json.dumps(d,separators=(',',':')).encode();meta+=b' '*((-len(meta))%4)
output=struct.pack('<III',0x46546c67,2,28+len(meta)+len(blob))+struct.pack('<II',len(meta),0x4e4f534a)+meta+struct.pack('<II',len(blob),0x004e4942)+blob
args.output.parent.mkdir(parents=True,exist_ok=True);args.output.write_bytes(output)
report={'source':'../nyra052/arcanist.glb','source_sha256':hashlib.sha256(raw).hexdigest(),'accessory_sha256':hashlib.sha256(output).hexdigest(),'native_bones':65,'source_rest_and_inverse_binds_preserved':True,'original_body_unmodified':True,'textures_included':False,'triangle_count':sum(r['triangles'] for r in reports),'meshes':reports,'scope':'Clipped shells preserve source geometry outside cuts; new continuous cut vertices interpolate native weights and UVs. Split tails inherit nearest same-side source garment four weights; circlet is native Head-bound. Cloth is skinned, not physical simulation. Original eight meshes remain separate and intact.','license':'Upper shell and shoulder surface geometry adapted from Quaternius CC0 Standard source; original licenses in ../nyra052/. New tail/binding/circlet design authored for Emberfall and provided under CC0.'}
args.output.with_suffix('.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'output':str(args.output),'bytes':len(output),'triangles':report['triangle_count'],'meshes':len(reports),'sha256':report['accessory_sha256']},indent=2))
