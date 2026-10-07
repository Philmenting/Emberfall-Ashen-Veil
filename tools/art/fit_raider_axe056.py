#!/usr/bin/env python3
"""Normalize the original Quaternius Axe Small and fit only its wooden grip.

Preserve its sharp authored steel shape, original normals and material splits.
The body is not touched. Normalization is a rigid rotation, translation and
uniform scale; the actual handle surface in the native finger span is fitted
radially to an 18 mm circumradius at the rig's .55 uniform prop scale.
"""
from pathlib import Path
import argparse,copy,hashlib,json,struct
import numpy as np
from scipy.spatial.transform import Rotation

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--source',type=Path,default=Path('assets/models/raider056/axe-original.glb'))
parser.add_argument('--output',type=Path,default=Path('assets/models/raider056/axe-fitted.glb'))
args=parser.parse_args();raw=args.source.read_bytes();n=struct.unpack_from('<I',raw,12)[0];source=json.loads(raw[20:20+n]);data=raw[28+n:]
def array(index):
 a=source['accessors'][index];v=source['bufferViews'][a['bufferView']];dtype={5126:'<f4',5123:'<u2',5125:'<u4'}[a['componentType']];width={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']];return np.ndarray((a['count'],width),dtype=dtype,buffer=data,offset=v.get('byteOffset',0)+a.get('byteOffset',0),strides=(v.get('byteStride',np.dtype(dtype).itemsize*width),np.dtype(dtype).itemsize)).copy()
node=next(n for n in source['nodes']if 'mesh'in n);rotation=Rotation.from_quat(node.get('rotation',[0,0,0,1])).as_matrix();basis=rotation@np.diag(node.get('scale',[1,1,1]));primitives=source['meshes'][node['mesh']]['primitives'];parts=[]
for p in primitives:parts.append(array(p['attributes']['POSITION'])@basis.T)
points=np.vstack(parts);uniform=1.25/float(np.ptp(points[:,1]));grip_raw_y=-.14;grip_y=.035
runtime_scale=.55;full_fit_halfspan=.065/runtime_scale;taper_halfspan=.100/runtime_scale
# Source cross-sections are nearly straight around this original wooden grip.
wood=np.vstack([p for p,primitive in zip(parts,primitives)if 'Wood'in source['materials'][primitive['material']]['name']]);near=wood[abs(wood[:,1]-grip_raw_y)<.06];center_x=float((near[:,0].min()+near[:,0].max())*.5);offset=np.asarray([-center_x*uniform,grip_y-grip_raw_y*uniform,0])
d={'asset':{'version':'2.0','generator':'Emberfall056: original CC0 Quaternius Axe Small sharp steel normals/shape; rigid1.25m normalization and fitted18mm wood grip only'},'scene':0,'scenes':[{'nodes':[0]}],'nodes':[{'name':'OriginalAuthoredRaiderAxe','children':[]}],'meshes':[],'materials':[],'accessors':[],'bufferViews':[]};blob=bytearray();records=[]
def access(values,typ,component=5126):
 values=np.ascontiguousarray(values);blob.extend(b'\0'*((-len(blob))%4));off=len(blob);blob.extend(values.tobytes());vi=len(d['bufferViews']);d['bufferViews'].append({'buffer':0,'byteOffset':off,'byteLength':values.nbytes});a={'bufferView':vi,'componentType':component,'count':len(values),'type':typ}
 if typ in ['SCALAR','VEC3']:a.update(min=values.min(0).tolist(),max=values.max(0).tolist())
 ai=len(d['accessors']);d['accessors'].append(a);return ai
def clip_plane(poly,y,less):
 result=[]
 if not len(poly):return result
 previous=poly[-1];pd=previous[1]-y;previous_inside=pd<=0 if less else pd>=0
 for current in poly:
  distance=current[1]-y;inside=distance<=0 if less else distance>=0
  if inside!=previous_inside:result.append(previous+(current-previous)*(pd/(pd-distance)))
  if inside:result.append(current)
  previous=current;pd=distance;previous_inside=inside
 return result

def split_grip(points,normals,indices):
 # A sparse original wooden face can cross the finger band while all its
 # original vertices lie outside. Split the actual indexed faces exactly at
 # full-fit and taper boundaries before fitting; steel faces are untouched.
 boundaries=[grip_y-taper_halfspan,grip_y-full_fit_halfspan,grip_y+full_fit_halfspan,grip_y+taper_halfspan]
 positions=[];directions=[];triangles=[]
 for triangle in indices.reshape(-1,3):
  original=[np.r_[points[i],normals[i]]for i in triangle]
  for lower,upper in zip([-float('inf')]+boundaries,boundaries+[float('inf')]):
   poly=original
   if np.isfinite(lower):poly=clip_plane(poly,lower,False)
   if np.isfinite(upper):poly=clip_plane(poly,upper,True)
   for corner in range(1,len(poly)-1):
    face=[poly[0],poly[corner],poly[corner+1]]
    if np.linalg.norm(np.cross(face[1][:3]-face[0][:3],face[2][:3]-face[0][:3]))<1e-12:continue
    index=len(positions);triangles.extend([index,index+1,index+2])
    for vertex in face:positions.append(vertex[:3]);direction=vertex[3:];directions.append(direction/max(np.linalg.norm(direction),1e-12))
 return np.asarray(positions),np.asarray(directions),np.asarray(triangles,dtype='<u4').reshape(-1,1)

for p,original_points in zip(primitives,parts):
 name=source['materials'][p['material']]['name'];points=original_points*uniform+offset;normals=array(p['attributes']['NORMAL'])@rotation.T;original_normalized=points.copy();indices=array(p['indices']).astype('<u4');original_triangle_count=len(indices)//3;material=copy.deepcopy(source['materials'][p['material']]);material.pop('extras',None);pbr=material['pbrMetallicRoughness'];material['alphaMode']='OPAQUE';material['doubleSided']=False
 if 'Wood'in name:
  assert set(p['attributes'])=={'POSITION','NORMAL'},'Original wood has no extra UV channel to interpolate'
  points,normals,indices=split_grip(points,normals,indices)
  delta=np.abs(points[:,1]-grip_y);amount=np.clip((taper_halfspan-delta)/(taper_halfspan-full_fit_halfspan),0,1);amount=amount*amount*(3-2*amount);radius=np.linalg.norm(points[:,[0,2]],axis=1);factor=np.divide(.018/runtime_scale,np.maximum(radius,1e-12));factor=1+(factor-1)*amount;points[:,0]*=factor;points[:,2]*=factor
  pbr['baseColorFactor']=[.18,.105,.055,1] if name=='DarkWood'else[.27,.16,.075,1];pbr['metallicFactor']=0;pbr['roughnessFactor']=.84
 else:
  assert np.array_equal(points,original_normalized)
  pbr['baseColorFactor']=[.38,.415,.45,1] if name=='Steel'else[.66,.68,.69,1];pbr['metallicFactor']=.86;pbr['roughnessFactor']=.50 if name=='Steel'else .35
 mi=len(d['materials']);d['materials'].append(material);attributes={'POSITION':access(points.astype('<f4'),'VEC3'),'NORMAL':access(normals.astype('<f4'),'VEC3')}
 for field,ai in p['attributes'].items():
  if field in attributes:continue
  original=source['accessors'][ai];attributes[field]=access(array(ai),original['type'],original['componentType'])
 primitive={'attributes':attributes,'indices':access(indices,'SCALAR',5125),'material':mi};mesh_index=len(d['meshes']);d['meshes'].append({'name':'Weapon__'+name,'primitives':[primitive]});ni=len(d['nodes']);d['nodes'].append({'name':'Weapon__'+name,'mesh':mesh_index});d['nodes'][0]['children'].append(ni);records.append({'material':name,'triangles':len(indices)//3,'original_triangles':original_triangle_count,'exact_grip_axial_face_splits':'Wood'in name,'original_sharp_steel_shape_normals_unchanged': 'Wood'not in name,'wood_grip_only_radially_fitted':'Wood'in name})
blob.extend(b'\0'*((-len(blob))%4));d['buffers']=[{'byteLength':len(blob)}];js=json.dumps(d,separators=(',',':')).encode();js+=b' '*((-len(js))%4);glb=struct.pack('<III',0x46546c67,2,28+len(js)+len(blob))+struct.pack('<II',len(js),0x4e4f534a)+js+struct.pack('<II',len(blob),0x004e4942)+blob;args.output.write_bytes(glb)
report={'source_url':'https://poly.pizza/m/o54NXjRI4V','author_source_url':'https://quaternius.com/packs/medievalweapons.html','download_url':'https://static.poly.pizza/654d4ee5-e217-4c23-b8e1-92e16226b21a.glb','author':'Quaternius','license':'CC0 1.0 Public Domain','source_sha256':hashlib.sha256(raw).hexdigest(),'fitted_sha256':hashlib.sha256(glb).hexdigest(),'source_bytes':len(raw),'fitted_bytes':len(glb),'triangles':sum(p['triangles']for p in records),'original_uniform_normalization_scale':uniform,'source_axis_rotation_xyzw':node['rotation'],'normalized_body_independent_height_m':1.25,'runtime_uniform_scale':runtime_scale,'runtime_full_fit_halfspan_m':.065,'runtime_taper_halfspan_m':.100,'runtime_physical_grip_circumradius_m':.018,'grip_source_point':[0,.035,0],'parts':records,'scope':'Source steel outline, sharp authored edge, bevel and hard normals retained under rigid/uniform normalization; only wooden grip narrowed to real native finger span; no soft procedural axe blades'};args.output.with_suffix('.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
