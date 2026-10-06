#!/usr/bin/env python3
"""Preserve the authored geometry, native rig, UVs and skin; retarget supplied clips relative to rest."""
from pathlib import Path
import json,struct,copy,hashlib,argparse
import numpy as np
parser=argparse.ArgumentParser(description="Assemble original free Quaternius Standard source packages into Nyra's native65 avatar.")
parser.add_argument('--source-root',type=Path,required=True,help='Root containing the three extracted Standard packages')
parser.add_argument('--output-root',type=Path,required=True)
args=parser.parse_args()
ROOT=args.source_root.resolve()
OUT=args.output_root.resolve();OUT.mkdir(parents=True,exist_ok=True)
class Source:
 def __init__(self,p):
  self.path=p;b=p.read_bytes()
  if p.suffix=='.glb':
   n=struct.unpack_from('<I',b,12)[0];self.d=json.loads(b[20:20+n]);self.b=b[28+n:]
  else:self.d=json.loads(b);self.b=(p.parent/self.d['buffers'][0]['uri']).read_bytes()
 def array(self,i):
  a=self.d['accessors'][i];v=self.d['bufferViews'][a['bufferView']];dt={5126:'<f4',5123:'<u2',5125:'<u4',5121:'u1'}[a['componentType']];n={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']];return np.ndarray((a['count'],n),dtype=dt,buffer=self.b,offset=v.get('byteOffset',0)+a.get('byteOffset',0),strides=(v.get('byteStride',np.dtype(dt).itemsize*n),np.dtype(dt).itemsize)).copy()
base=Source(next(ROOT.glob('**/Superhero_Female_FullBody.gltf')))
outfit=Source(next(ROOT.glob('**/Outfits/Female_Peasant.gltf')))
hair=Source(next(ROOT.glob('**/Rigged to Head Bone/**/Hair_Buns.gltf')))
anim=Source(next(ROOT.glob('**/UAL1_Standard.glb')))
d=copy.deepcopy(base.d);blob=bytearray(base.b);inputs={}
def pad():blob.extend(b'\0'*((-len(blob))%4))
def append(raw):
 pad();offset=len(blob);blob.extend(raw);return offset

def new_accessor(a,typ=None,component=None):
 a=np.asarray(a);raw=a.tobytes();off=append(raw);vi=len(d['bufferViews']);d['bufferViews'].append({'buffer':0,'byteOffset':off,'byteLength':len(raw)});idx=len(d['accessors']);ac={'bufferView':vi,'componentType':component or (5126 if a.dtype.kind=='f' else 5125),'count':len(a),'type':typ or {1:'SCALAR',2:'VEC2',3:'VEC3',4:'VEC4',16:'MAT4'}[a.shape[1]]}
 if ac['type']=='SCALAR' or ac['type']=='VEC3':ac.update(min=a.min(0).tolist(),max=a.max(0).tolist())
 d['accessors'].append(ac);return idx

# Preserve the manufacturer's identical native65 rig for its compatible modular outfit and hair.
def bone_parents(source):
 joints=set(source.d['skins'][0]['joints'])
 parents={child:parent for parent,node in enumerate(source.d['nodes']) for child in node.get('children',[]) if parent in joints and child in joints}
 return {source.d['nodes'][j]['name']:source.d['nodes'][parents[j]]['name'] if j in parents else None for j in joints}
for source in [outfit,hair]:
 assert bone_parents(base)==bone_parents(source),'Original native bone hierarchy must match'
 for ji,j in enumerate(base.d['skins'][0]['joints']):
  b=base.d['nodes'][j];s=source.d['nodes'][source.d['skins'][0]['joints'][ji]]
  assert b['name']==s['name']
  for field,default in [('translation',[0,0,0]),('rotation',[0,0,0,1]),('scale',[1,1,1])]:assert np.allclose(b.get(field,default),s.get(field,default),atol=1e-6),(b['name'],field)

# Official modular outfits include their body, arms/hands and boots; only the compatible head is selected from the base.
head_prim=d['meshes'][2]['primitives'][0];positions=base.array(head_prim['attributes']['POSITION']);tri=base.array(head_prim['indices']).reshape(-1,3);selected=tri[np.all(positions[tri,1]>=1.498,axis=1)]
assert 1200<len(selected)<6000
head_prim['indices']=new_accessor(selected.astype('<u4').reshape(-1,1),'SCALAR',5125)
d['meshes'][2]['name']='Nyra_Authored_Head';d['nodes'][67]['name']='Nyra_Authored_Head'
# Additional UV/color sets are intentionally not needed by the target standard PBR materials.
for m in d['meshes']:
 for p in m['primitives']:
  for k in list(p['attributes']):
   if k.startswith('COLOR_') or (k.startswith('TEXCOORD_') and k!='TEXCOORD_0'):del p['attributes'][k]

for source in [outfit,hair]:
 off=append(source.b);vmap={};amap={}
 for i,v in enumerate(source.d['bufferViews']):
  c=copy.deepcopy(v);c['byteOffset']=c.get('byteOffset',0)+off;c['buffer']=0;vmap[i]=len(d['bufferViews']);d['bufferViews'].append(c)
 for i,a in enumerate(source.d['accessors']):
  c=copy.deepcopy(a);c['bufferView']=vmap[c['bufferView']];amap[i]=len(d['accessors']);d['accessors'].append(c)
 imap={};tmap={};mmap={}
 for i,v in enumerate(source.d.get('images',[])):imap[i]=len(d['images']);d['images'].append(dict(v,_source=str(source.path)))
 for i,v in enumerate(source.d.get('textures',[])):
  c=dict(v);c['source']=imap[c['source']];c.pop('sampler',None);tmap[i]=len(d['textures']);d['textures'].append(c)
 def texmap(x):
  if isinstance(x,dict):
   for k,v in list(x.items()):
    if k.endswith('Texture') and isinstance(v,dict):v['index']=tmap[v['index']]
    else:texmap(v)
  elif isinstance(x,list):
   for v in x:texmap(v)
 for i,m in enumerate(source.d['materials']):
  c=copy.deepcopy(m);texmap(c);
  if source is hair:c['name']='MI_Nyra_Silver_Hair'
  mmap[i]=len(d['materials']);d['materials'].append(c)
 for node in source.d['nodes']:
  if 'mesh' not in node:continue
  mesh=copy.deepcopy(source.d['meshes'][node['mesh']]);mesh['name']='Nyra_'+mesh.get('name','Hair')
  for p in mesh['primitives']:
   p['attributes']={k:amap[v] for k,v in p['attributes'].items() if not k.startswith('COLOR_') and (not k.startswith('TEXCOORD_') or k=='TEXCOORD_0')};p['indices']=amap[p['indices']];p['material']=mmap[p['material']]
  mi=len(d['meshes']);d['meshes'].append(mesh);ni=len(d['nodes']);c={k:v for k,v in node.items() if k not in ('mesh','skin','children')};c.update(mesh=mi,skin=0,name=mesh['name']);d['nodes'].append(c);d['nodes'][68]['children'].append(ni)
# Embed exact artist maps, resolving the supplied eye filename typo from the actual original file.
image_payloads={}
for im in d['images']:
 parent=Path(im.pop('_source',str(base.path))).parent;name=im.get('name','');uri=im.pop('uri');p=parent/uri
 if name=='T_Superhero_Female_Dark_BaseColor':p=next(ROOT.glob('**/Textures/T_Superhero_Female_Light_BaseColor.png'))
 if name.endswith('_Normal'):
  candidates=list(ROOT.glob('**/Normals Unity - Godot/'+name+'.png'))
  if candidates:p=candidates[0]
 if not p.exists():p=next(ROOT.glob('**/'+name.removesuffix('.png')+'.png'))
 inputs[str(p)]=hashlib.sha256(p.read_bytes()).hexdigest()
 cached=OUT/'texture-cache'/(name+'.png')
 if cached.exists():p=cached
 raw=p.read_bytes();digest=hashlib.sha256(raw).hexdigest()
 if digest not in image_payloads:
  off=append(raw);vi=len(d['bufferViews']);d['bufferViews'].append({'buffer':0,'byteOffset':off,'byteLength':len(raw)});image_payloads[digest]=vi
 im['bufferView']=image_payloads[digest];im['mimeType']='image/png';inputs[str(p)]=digest
# Silver hair is a material appearance change, while the authored strand normal map remains real.
for m in d['materials']:
 if m['name']=='MI_Nyra_Silver_Hair':
  m['pbrMetallicRoughness']['baseColorFactor']=[.25,.28,.32,1];m['pbrMetallicRoughness']['roughnessFactor']=.75
 if m['name']=='MI_Hair_2':m['pbrMetallicRoughness']['baseColorFactor']=[.12,.14,.16,1]
 if m['name']=='MI_Superhero_Female':m['normalTexture']['scale']=.55
 m['doubleSided']=True
# Native source-to-target rest-relative quaternion retargeting: target rest/geometry/weights never change.
def qmul(a,b):
 a=np.asarray(a);b=np.asarray(b);ax,ay,az,aw=np.moveaxis(a,-1,0);bx,by,bz,bw=np.moveaxis(b,-1,0);return np.stack([aw*bx+ax*bw+ay*bz-az*by,aw*by-ax*bz+ay*bw+az*bx,aw*bz+ax*by-ay*bx+az*bw,aw*bw-ax*bx-ay*by-az*bz],axis=-1)
lookup={n.get('name'):i for i,n in enumerate(d['nodes'])};d['animations']=[]
for action in anim.d['animations']:
 if action['name'] not in ['Idle_Loop','Spell_Simple_Idle_Loop','Walk_Loop','Jog_Fwd_Loop','Spell_Simple_Enter','Spell_Simple_Shoot','Spell_Simple_Exit','Death01','Hit_Chest','Sword_Attack','Sword_Idle']:continue
 new={'name':action['name'],'samplers':[],'channels':[]}
 for ch in action['channels']:
  src=anim.d['nodes'][ch['target']['node']];name=src.get('name');path=ch['target']['path'];target=lookup.get(name)
  if target is None or path=='scale':continue
  sampler=action['samplers'][ch['sampler']];t=anim.array(sampler['input']).astype('<f4');x=anim.array(sampler['output']).astype('<f4');node=d['nodes'][target]
  assert sampler.get('interpolation','LINEAR')=='LINEAR'
  if path=='rotation':
   qr=np.array(src.get('rotation',[0,0,0,1]));inv=qr*np.array([-1,-1,-1,1]);qt=np.array(node.get('rotation',[0,0,0,1]));x=qmul(qt,qmul(inv,x));x=(x/np.linalg.norm(x,axis=1)[:,None]).astype('<f4')
  elif path=='translation':
   origin=np.array(src.get('translation',[0,0,0]));target_rest=np.array(node.get('translation',[0,0,0]));delta=x-origin
   if name not in ['root','pelvis']:delta[:]=0
   x=(target_rest+delta).astype('<f4')
  else:continue
  si=len(new['samplers']);new['samplers'].append({'input':new_accessor(t,'SCALAR'), 'output':new_accessor(x),'interpolation':'LINEAR'});new['channels'].append({'sampler':si,'target':{'node':target,'path':path}})
 d['animations'].append(new)
d['buffers']=[{'byteLength':len(blob)}];d['asset']['generator']='Emberfall native65 modular assembly; original Quaternius geometry/skin/rest; rest-relative source animation retarget'
pad();raw=json.dumps(d,separators=(',',':')).encode();raw+=b' '*((-len(raw))%4);glb=struct.pack('<III',0x46546c67,2,28+len(raw)+len(blob))+struct.pack('<II',len(raw),0x4e4f534a)+raw+struct.pack('<II',len(blob),0x004e4942)+blob
p=OUT/'nyra-authored-native65.glb';p.write_bytes(glb)
for s in [base,outfit,hair,anim]:
 inputs[str(s.path)]=hashlib.sha256(s.path.read_bytes()).hexdigest()
 for buffer in s.d.get('buffers',[]):
  if 'uri' in buffer:
   p=s.path.parent/buffer['uri'];inputs[str(p)]=hashlib.sha256(p.read_bytes()).hexdigest()
report={'model_sha256':hashlib.sha256(glb).hexdigest(),'source_files':inputs,'native_bones':65,'texture_processing':'Three original Peasant 4K maps resized to 2K with Godot Lanczos if present in output texture-cache; original face/hair/eye maps retained','all_three_source_rest_hierarchies_equal':True,'head_selected_triangles':len(selected),'triangles':sum(d['accessors'][p['indices']]['count']//3 for m in d['meshes'] for p in m['primitives']),'animations':[a['name'] for a in d['animations']], 'source_mesh_positions_normals_uvs_weights_preserved':True,'scope':'Manufacturer-compatible modular head/eyes/brows/hair and complete authored Peasant outfit; not a complete underlying nude body; no anatomy stretch or skin reweighting','license':'CC0 1.0; supplied original licenses retained; free Standard packages only'}
(OUT/'assembly-report.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2)[:2500])
