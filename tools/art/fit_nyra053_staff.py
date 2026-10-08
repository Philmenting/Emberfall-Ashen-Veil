#!/usr/bin/env python3
"""Retain Emberfall staff ornament; make a real 18-mm-radius grasp region."""
from pathlib import Path
import argparse,copy,hashlib,json,struct
import numpy as np
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--source',type=Path,required=True)
parser.add_argument('--output',type=Path,required=True)
args=parser.parse_args();raw=args.source.read_bytes();length=struct.unpack_from('<I',raw,12)[0]
d=json.loads(raw[20:20+length]);blob=bytearray(raw[28+length:])
def array(index):
 a=d['accessors'][index];v=d['bufferViews'][a['bufferView']];dtype={5126:'<f4',5125:'<u4',5123:'<u2'}[a['componentType']];size={'VEC2':2,'VEC3':3,'VEC4':4,'SCALAR':1}[a['type']]
 return np.ndarray((a['count'],size),dtype=dtype,buffer=blob,offset=v.get('byteOffset',0)+a.get('byteOffset',0),strides=(v.get('byteStride',np.dtype(dtype).itemsize*size),np.dtype(dtype).itemsize)).copy()
def accessor(values,kind,component):
 blob.extend(b'\0'*((-len(blob))%4));offset=len(blob);values=np.ascontiguousarray(values);blob.extend(values.tobytes());view=len(d['bufferViews']);d['bufferViews'].append({'buffer':0,'byteOffset':offset,'byteLength':values.nbytes});idx=len(d['accessors']);d['accessors'].append({'bufferView':view,'componentType':component,'count':len(values),'type':kind,'min':values.min(0).tolist(),'max':values.max(0).tolist()});return idx
nodes=[];meshes=[];removed=0
for original in d['nodes']:
 if not original.get('name','').startswith('Weapon__'):continue
 node=copy.deepcopy(original);mesh=copy.deepcopy(d['meshes'][node['mesh']])
 if node['name']=='Weapon__leather':
  for prim in mesh['primitives']:
   vertices=array(prim['attributes']['POSITION']);normals=array(prim['attributes']['NORMAL']);tri=array(prim['indices']).reshape(-1,3)
   # Weld only for connected-component classification; render attributes remain unchanged.
   keys=np.round(vertices*1e6).astype(np.int64);representatives={};canonical=[]
   for i,key in enumerate(map(tuple,keys)):
    representatives.setdefault(key,i);canonical.append(representatives[key])
   canonical=np.array(canonical);parents=np.arange(len(vertices))
   def find(i):
    while parents[i]!=i:parents[i]=parents[parents[i]];i=parents[i]
    return i
   for face in canonical[tri]:
    for i in face[1:]:parents[find(i)]=find(face[0])
   component=np.array([find(i) for i in canonical]);remove=set()
   for group in np.unique(component[tri]):
    points=vertices[component==group];low,high=points[:,1].min(),points[:,1].max()
    # Remove the old four raised grip wraps. The original ornament/gold stays.
    if high-low<.012 and any(abs((low+high)/2-y)<.001 for y in [-.075,-.030,.015,.060]):remove.add(group)
   keep=np.array([component[face[0]] not in remove for face in tri]);removed+=int((~keep).sum());tri=tri[keep]
   # Insert genuine section boundaries before tapering. Merely moving the
   # sparse original ring vertices leaves wide diagonal faces in the grip.
   attrs={name:array(index) for name,index in prim['attributes'].items()}
   emitted={name:[] for name in attrs}
   new_indices=[]
   def split(poly,height):
    low=[];high=[];previous=poly[-1];pv=previous['POSITION'][1]-height
    for point in poly:
     value=point['POSITION'][1]-height
     if (pv<0 and value>0) or (pv>0 and value<0):
      t=pv/(pv-value);cut={key:previous[key]*(1-t)+point[key]*t for key in attrs}
      low.append(cut);high.append(cut)
     if value<=0:low.append(point)
     if value>=0:high.append(point)
     previous=point;pv=value
    return [side for side in [low,high] if len(side)>=3]
   for face in tri:
    polygons=[[{name:values[index].copy() for name,values in attrs.items()} for index in face]]
    for height in [-.235,-.21,-.065,-.04]:
     next_polys=[]
     for poly in polygons:
      ys=[point['POSITION'][1] for point in poly]
      next_polys.extend(split(poly,height) if min(ys)<height<max(ys) else [poly])
     polygons=next_polys
    for poly in polygons:
     for corner in range(1,len(poly)-1):
      for point in [poly[0],poly[corner],poly[corner+1]]:
       index=len(emitted['POSITION']);new_indices.append(index)
       for name in attrs:emitted[name].append(point[name])
   vertices=np.array(emitted['POSITION']);normals=np.array(emitted['NORMAL'])
   # Constant 24-mm source radius * runtime .75 = real 18-mm grip radius.
   for i,point in enumerate(vertices):
    y=float(point[1]);rad=float(np.linalg.norm(point[[0,2]]))
    if -.210001<=y<=-.064999 and rad>1e-8:
     point[[0,2]]*=.024/rad;normals[i]=[point[0]/.024,0,point[2]/.024]
    elif -.235<y<-.21 or -.065<y<-.04:
     t=(y+.235)/.025 if y<-.21 else (-.04-y)/.025;t=t*t*(3-2*t)
     if rad>1e-8:point[[0,2]]*=1+t*(.024/rad-1)
   # Section cuts interpolate attributes; normalize every resulting normal,
   # including transition vertices outside the constant-radius handle.
   normal_lengths=np.linalg.norm(normals,axis=1)
   assert np.isfinite(normal_lengths).all() and (normal_lengths>1e-8).all()
   normals/=normal_lengths[:,None]
   emitted['POSITION']=vertices;emitted['NORMAL']=normals
   for name,values in emitted.items():
    original=d['accessors'][prim['attributes'][name]]
    prim['attributes'][name]=accessor(np.array(values,dtype='<f4'),original['type'],5126)
   prim['indices']=accessor(np.array(new_indices,dtype='<u4').reshape(-1,1),'SCALAR',5125)
 node['mesh']=len(meshes);nodes.append(node);meshes.append(mesh)
assert removed>0 and len(nodes)==5
for key in ['skins','animations']:d.pop(key,None)
d['nodes']=nodes;d['meshes']=meshes;d['scenes']=[{'name':'Emberfall_Nyra_Staff_053','nodes':list(range(len(nodes)))}];d['scene']=0
blob.extend(b'\0'*((-len(blob))%4));d['buffers']=[{'byteLength':len(blob)}];d['asset']['generator']='Emberfall staff grip053: existing ornament, actual18mm handle, raised grip wraps removed'
d['extras']={'original_staff_sha256':hashlib.sha256(raw).hexdigest(),'runtime_uniform_scale':.75,'grip_source_point':[0,-.147,0],'physical_grip_radius_m':.018,'removed_wrap_triangles':removed}
payload=json.dumps(d,separators=(',',':')).encode();payload+=b' '*((-len(payload))%4);output=struct.pack('<III',0x46546c67,2,28+len(payload)+len(blob))+struct.pack('<II',len(payload),0x4e4f534a)+payload+struct.pack('<II',len(blob),0x004e4942)+blob
args.output.parent.mkdir(parents=True,exist_ok=True);args.output.write_bytes(output);print(json.dumps({'sha256':hashlib.sha256(output).hexdigest(),**d['extras']}))
