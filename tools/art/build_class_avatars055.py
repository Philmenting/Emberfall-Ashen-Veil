#!/usr/bin/env python3
"""Pack the manufacturer's complete native65 Ranger outfit and sword clips.

The already accepted Nyra head is shared at runtime. No bone mapping, anatomical
scaling or reweighting is performed. Only original outfit textures are reduced
to 1024 pixels; true native65 sword rotations are retargeted relative to rest.
"""
from pathlib import Path
import argparse, copy, hashlib, io, json, struct
import numpy as np
from PIL import Image

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--source-root',type=Path,required=True)
parser.add_argument('--animation2',type=Path,required=True)
parser.add_argument('--accepted',type=Path,default=Path('assets/models/nyra052/arcanist.glb'))
parser.add_argument('--output',type=Path,default=Path('assets/models/classes055/ranger-native65.glb'))
args=parser.parse_args()

class Source:
 def __init__(self,p):
  self.path=p;raw=p.read_bytes()
  if p.suffix=='.glb':
   size=struct.unpack_from('<I',raw,12)[0];self.d=json.loads(raw[20:20+size]);self.b=raw[28+size:]
  else:self.d=json.loads(raw);self.b=(p.parent/self.d['buffers'][0]['uri']).read_bytes()
 def array(self,i):
  a=self.d['accessors'][i];v=self.d['bufferViews'][a['bufferView']]
  dtype={5126:'<f4',5123:'<u2',5125:'<u4',5121:'u1'}[a['componentType']]
  count={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']]
  return np.ndarray((a['count'],count),dtype=dtype,buffer=self.b,
   offset=v.get('byteOffset',0)+a.get('byteOffset',0),
   strides=(v.get('byteStride',np.dtype(dtype).itemsize*count),np.dtype(dtype).itemsize)).copy()

source=Source(next(args.source_root.glob('**/Outfits/Female_Ranger.gltf')))
accepted=Source(args.accepted);animation=Source(args.animation2)
d=copy.deepcopy(source.d);blob=bytearray(source.b);inputs={}
assert d['skins'][0]['joints']==accepted.d['skins'][0]['joints']
for i in range(65):assert d['nodes'][i]==accepted.d['nodes'][i],('native rest/hierarchy differs',i)

def append(raw):
 blob.extend(b'\0'*((-len(blob))%4));offset=len(blob);blob.extend(raw);return offset
def accessor(a,typ):
 a=np.ascontiguousarray(a,dtype='<f4');off=append(a.tobytes());vi=len(d['bufferViews'])
 d['bufferViews'].append({'buffer':0,'byteOffset':off,'byteLength':a.nbytes})
 index=len(d['accessors']);v={'bufferView':vi,'componentType':5126,'count':len(a),'type':typ}
 if typ=='SCALAR':v.update(min=a.min(0).tolist(),max=a.max(0).tolist())
 d['accessors'].append(v);return index

for mesh in d['meshes']:
 for p in mesh['primitives']:
  for key in list(p['attributes']):
   if key.startswith('COLOR_') or (key.startswith('TEXCOORD_') and key!='TEXCOORD_0'):del p['attributes'][key]
  weights=source.array(p['attributes']['WEIGHTS_0'])
  assert np.max(np.abs(weights.sum(1)-1))<1e-5

for image in d['images']:
 name=image.get('name','');filename=name+'.png'
 candidates=list(args.source_root.glob('**/Normals Unity - Godot/'+filename)) if name.endswith('_Normal') else []
 if not candidates:candidates=list(args.source_root.glob('**/'+filename))
 if name=='T_Regular_Female_Dark_BaseColor':
  light=list(args.source_root.glob('**/T_Regular_Female_Light_BaseColor.png'))
  if light:candidates=light
 assert candidates,filename
 path=sorted(candidates)[0];raw=path.read_bytes();inputs[str(path)]=hashlib.sha256(raw).hexdigest()
 texture=Image.open(io.BytesIO(raw));texture.thumbnail((1024,1024),Image.Resampling.LANCZOS)
 output=io.BytesIO();texture.save(output,format='PNG',optimize=False);payload=output.getvalue()
 vi=len(d['bufferViews']);off=append(payload)
 d['bufferViews'].append({'buffer':0,'byteOffset':off,'byteLength':len(payload)})
 image.pop('uri',None);image.update(bufferView=vi,mimeType='image/png')
for material in d['materials']:
 material['doubleSided']=True
 if material['name']=='MI_Regular_Female':material['normalTexture']['scale']=.45

def qmul(a,b):
 ax,ay,az,aw=np.moveaxis(np.asarray(a),-1,0);bx,by,bz,bw=np.moveaxis(np.asarray(b),-1,0)
 return np.stack([aw*bx+ax*bw+ay*bz-az*by,aw*by-ax*bz+ay*bw+az*bx,
  aw*bz+ax*by-ay*bx+az*bw,aw*bw-ax*bx-ay*by-az*bz],axis=-1)
lookup={n.get('name'):i for i,n in enumerate(d['nodes'])};d['animations']=[]
for action in animation.d['animations']:
 if action['name'] not in ['Sword_Regular_A','Sword_Regular_A_Rec','Sword_Regular_B','Sword_Regular_B_Rec','Sword_Regular_C','Sword_Block']:continue
 new={'name':action['name'],'samplers':[],'channels':[]}
 for channel in action['channels']:
  src=animation.d['nodes'][channel['target']['node']];name=src.get('name');kind=channel['target']['path'];target=lookup.get(name)
  if target is None or kind=='scale':continue
  sampler=action['samplers'][channel['sampler']]
  assert sampler.get('interpolation','LINEAR')=='LINEAR'
  t=animation.array(sampler['input']);x=animation.array(sampler['output']);node=d['nodes'][target]
  if kind=='rotation':
   qr=np.asarray(src.get('rotation',[0,0,0,1]));qt=np.asarray(node.get('rotation',[0,0,0,1]))
   x=qmul(qt,qmul(qr*np.asarray([-1,-1,-1,1]),x));x/=np.linalg.norm(x,axis=1)[:,None]
  elif kind=='translation':
   # Keep exact native target bone lengths; sword phrase root travel is
   # deliberately held in place because simulation owns actor movement.
   x=np.repeat(np.asarray(node.get('translation',[0,0,0]))[None],len(x),axis=0)
  else:continue
  si=len(new['samplers']);new['samplers'].append({'input':accessor(t,'SCALAR'),'output':accessor(x,{'rotation':'VEC4','translation':'VEC3'}[kind]),'interpolation':'LINEAR'})
  new['channels'].append({'sampler':si,'target':{'node':target,'path':kind}})
 d['animations'].append(new)
blob.extend(b'\0'*((-len(blob))%4));d['buffers']=[{'byteLength':len(blob)}]
d['asset']['generator']='Emberfall 055: unchanged Quaternius native65 Ranger outfit; rest-relative native sword clips; original maps resized to1K'
raw=json.dumps(d,separators=(',',':')).encode();raw+=b' '*((-len(raw))%4)
glb=struct.pack('<III',0x46546c67,2,28+len(raw)+len(blob))+struct.pack('<II',len(raw),0x4e4f534a)+raw+struct.pack('<II',len(blob),0x004e4942)+blob
args.output.parent.mkdir(parents=True,exist_ok=True);args.output.write_bytes(glb)
for p in [source.path,source.path.parent/source.d['buffers'][0]['uri'],args.animation2,args.accepted]:inputs[str(p)]=hashlib.sha256(p.read_bytes()).hexdigest()
report={'model_sha256':hashlib.sha256(glb).hexdigest(),'bytes':len(glb),'native_bones':65,'identical_accepted_native_rest':True,'outfit_triangles':sum(source.d['accessors'][p['indices']]['count']//3 for m in source.d['meshes'] for p in m['primitives']),'original_geometry_normals_uv_weights_preserved':True,'texture_size_limit':1024,'animations':[a['name'] for a in d['animations']],'source_files':inputs,'license':'CC0 1.0 Quaternius Standard1/Standard2; original supplied notices retained','scope':'Complete compatible artist Ranger outfit, accepted original head shared at runtime; separate fitted armor and weapons; no anatomical scaling/remapping; no authored bow clip claim'}
args.output.with_suffix('.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:v for k,v in report.items() if k!='source_files'},indent=2))
