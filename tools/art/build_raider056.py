#!/usr/bin/env python3
"""Assemble a clothed, bearded Raider from original CC0 Quaternius Standard art.

Native Male_Peasant rest, positions, normals, UVs and four skin weights remain
unchanged. The compatible authored head, eyes/brows and beard keep their own
original inverse bind matrices. Source sword/hit/death clips are retargeted
relative to target rest; the offline finger fit changes rotations only.
Requires numpy, scipy and Pillow; no Blender, network or Godot runtime.
"""
from pathlib import Path
import argparse, copy, hashlib, io, json, struct, shutil
import numpy as np
from PIL import Image
from scipy.spatial.transform import Rotation, Slerp
from scipy.optimize import minimize

class Source:
 def __init__(self,path):
  self.path=Path(path);raw=self.path.read_bytes()
  if self.path.suffix=='.glb':
   n=struct.unpack_from('<I',raw,12)[0];self.d=json.loads(raw[20:20+n]);self.b=raw[28+n:]
  else:self.d=json.loads(raw);self.b=(self.path.parent/self.d['buffers'][0]['uri']).read_bytes()
  self.parent={c:p for p,n in enumerate(self.d['nodes']) for c in n.get('children',[])}
 def array(self,index):
  a=self.d['accessors'][index];v=self.d['bufferViews'][a['bufferView']]
  dtype={5126:'<f4',5123:'<u2',5125:'<u4',5121:'u1'}[a['componentType']]
  size={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']]
  return np.ndarray((a['count'],size),dtype=dtype,buffer=self.b,offset=v.get('byteOffset',0)+a.get('byteOffset',0),strides=(v.get('byteStride',np.dtype(dtype).itemsize*size),np.dtype(dtype).itemsize)).copy()
 def local(self):
  out=[]
  for n in self.d['nodes']:
   m=np.eye(4);m[:3,:3]=Rotation.from_quat(n.get('rotation',[0,0,0,1])).as_matrix()@np.diag(n.get('scale',[1,1,1]));m[:3,3]=n.get('translation',[0,0,0]);out.append(m)
  return out
 def global_pose(self,local):
  out=[None]*len(local)
  def get(i):
   if out[i] is None:out[i]=get(self.parent[i])@local[i] if i in self.parent else local[i]
   return out[i]
  return np.asarray([get(i) for i in range(len(local))])
 def pose(self,name,t):
  local=self.local();action=next(a for a in self.d['animations'] if a['name']==name)
  for ch in action['channels']:
   sa=action['samplers'][ch['sampler']];ts=self.array(sa['input'])[:,0];vs=self.array(sa['output']);tt=float(np.clip(t,ts[0],ts[-1]));i=int(np.clip(np.searchsorted(ts,tt)-1,0,len(ts)-2));f=(tt-ts[i])/(ts[i+1]-ts[i]);target=ch['target']['node'];kind=ch['target']['path']
   if kind=='rotation':local[target][:3,:3]=Slerp(ts[i:i+2],Rotation.from_quat(vs[i:i+2]))([tt]).as_matrix()[0]
   elif kind=='translation':local[target][:3,3]=vs[i]*(1-f)+vs[i+1]*f
  return local,self.global_pose(local)

def qmul(a,b):
 ax,ay,az,aw=np.moveaxis(np.asarray(a),-1,0);bx,by,bz,bw=np.moveaxis(np.asarray(b),-1,0)
 return np.stack([aw*bx+ax*bw+ay*bz-az*by,aw*by-ax*bz+ay*bw+az*bx,aw*bz+ax*by-ay*bx+az*bw,aw*bw-ax*bx-ay*by-az*bz],axis=-1)

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--source-root',type=Path,required=True)
parser.add_argument('--animation1',type=Path,required=True)
parser.add_argument('--animation2',type=Path,required=True)
parser.add_argument('--output',type=Path,default=Path('assets/models/raider056/raider-native65.glb'))
args=parser.parse_args();root=args.source_root
outfit=Source(next(root.glob('**/Outfits/Male_Peasant.gltf')))
head=Source(next(root.glob('**/Superhero_Male_FullBody.gltf')))
beard=Source(next(root.glob('**/Rigged to Head Bone/**/Hair_Beard.gltf')))
animations=[Source(args.animation1),Source(args.animation2)]
d={'asset':{'version':'2.0','generator':'Emberfall 056: original Quaternius native65 Male_Peasant, compatible authored male head/eyes/brows/beard, rest-relative source sword/hit/death clips'},'scene':0,'scenes':[],'nodes':copy.deepcopy(outfit.d['nodes'][:65]),'skins':[],'meshes':[],'materials':[],'textures':[],'images':[],'bufferViews':[],'accessors':[],'animations':[]}
blob=bytearray();inputs={};geometry_records=[];image_cache={};bone_names=[outfit.d['nodes'][i]['name'] for i in outfit.d['skins'][0]['joints']]
container=65;d['nodes'].append({'name':'Raider_Authored_Native65','children':[i for i in range(65) if outfit.parent.get(i) not in range(65)]});d['scenes']=[{'nodes':[container]}]

def remember(path):inputs[str(path)]=hashlib.sha256(path.read_bytes()).hexdigest()
def accessor(array,typ=None,component=None):
 array=np.ascontiguousarray(array);blob.extend(b'\0'*((-len(blob))%4));off=len(blob);blob.extend(array.tobytes());vi=len(d['bufferViews']);d['bufferViews'].append({'buffer':0,'byteOffset':off,'byteLength':array.nbytes});index=len(d['accessors']);ac={'bufferView':vi,'componentType':component or {'f':5126,'u':5125}[array.dtype.kind],'count':len(array),'type':typ or {1:'SCALAR',2:'VEC2',3:'VEC3',4:'VEC4',16:'MAT4'}[array.shape[1]]}
 if ac['type'] in ['SCALAR','VEC3']:ac.update(min=array.min(0).tolist(),max=array.max(0).tolist())
 d['accessors'].append(ac);return index

def image(path):
 remember(path);raw=path.read_bytes();digest=hashlib.sha256(raw).hexdigest()
 if digest in image_cache:return image_cache[digest]
 im=Image.open(io.BytesIO(raw));im.thumbnail((1024,1024),Image.Resampling.LANCZOS);output=io.BytesIO();im.save(output,format='PNG',optimize=False);payload=output.getvalue();blob.extend(b'\0'*((-len(blob))%4));off=len(blob);blob.extend(payload);vi=len(d['bufferViews']);d['bufferViews'].append({'buffer':0,'byteOffset':off,'byteLength':len(payload)});ii=len(d['images']);d['images'].append({'name':path.stem,'bufferView':vi,'mimeType':'image/png'});ti=len(d['textures']);d['textures'].append({'source':ii});image_cache[digest]=ti;return ti

def add_source(source,selection=None):
 remember(source.path)
 if source.path.suffix!='.glb':remember(source.path.parent/source.d['buffers'][0]['uri'])
 target_lookup={n['name']:i for i,n in enumerate(d['nodes'][:65])}
 source_joints=source.d['skins'][0]['joints'];target_joints=[target_lookup[source.d['nodes'][j]['name']] for j in source_joints]
 assert [source.d['nodes'][j]['name'] for j in source_joints]==bone_names
 skin=copy.deepcopy(source.d['skins'][0]);skin['joints']=target_joints;skin['inverseBindMatrices']=accessor(source.array(skin['inverseBindMatrices']).astype('<f4'),'MAT4');skin.pop('skeleton',None);si=len(d['skins']);d['skins'].append(skin)
 source_rest=source.global_pose(source.local());target_rest=outfit.global_pose(outfit.local())
 mmap={}
 for mi,m in enumerate(source.d['materials']):
  material=copy.deepcopy(m)
  def map_textures(value):
   if isinstance(value,dict):
    for k,v in value.items():
     if k.endswith('Texture') and isinstance(v,dict):
      tex=source.d['textures'][v['index']];im=source.d['images'][tex['source']];name=im.get('name','').removesuffix('.png');path=source.path.parent/im['uri']
      normals=list(root.glob('**/Normals Unity - Godot/'+name+'.png'))
      if name.endswith('_Normal') and normals:path=normals[0]
      if not path.exists():
       candidates=sorted(root.glob('**/'+name+'.png'));assert candidates,name;path=candidates[0]
      v['index']=image(path)
     else:map_textures(v)
   elif isinstance(value,list):
    for v in value:map_textures(v)
  map_textures(material);material['doubleSided']=False
  if material['name'] in ['MI_Superhero_Male','MI_Regular_Male']:
   material.get('normalTexture',{})['scale']=.45
   # Common original dark skin maps keep a consistent head/hand complexion.
   material['pbrMetallicRoughness']['baseColorFactor']=[.89,.85,.80,1]
  if material['name']=='MI_Peasant':
   material['name']='MI_Raider_Worn_Oxblood_Cloth';material['pbrMetallicRoughness']['baseColorFactor']=[.47,.27,.23,1];material['pbrMetallicRoughness']['roughnessFactor']=1.0
  if material['name']=='MI_Hair_1':material['pbrMetallicRoughness']['baseColorFactor']=[.32,.29,.25,1]
  mmap[mi]=len(d['materials']);d['materials'].append(material)
 for sn in source.d['nodes']:
  if 'mesh' not in sn:continue
  name=sn['name']
  if selection is not None and name not in selection:continue
  sm=source.d['meshes'][sn['mesh']];mesh={'name':('Raider_Authored_Head' if name=='SuperHero_Male' else name),'primitives':[]};mi=len(d['meshes'])
  for p in sm['primitives']:
   tri=source.array(p['indices']).reshape(-1,3)
   if name=='SuperHero_Male':
    points=source.array(p['attributes']['POSITION']);tri=tri[np.all(points[tri,1]>=1.54,axis=1)];assert len(tri)==2880
   used=np.unique(tri);remap=np.zeros(source.d['accessors'][p['attributes']['POSITION']]['count'],dtype='<u4');remap[used]=np.arange(len(used),dtype='<u4')
   primitive={'attributes':{},'indices':accessor(remap[tri].reshape(-1,1),'SCALAR',5125),'material':mmap[p['material']]}
   arrays={}
   for field,ai in p['attributes'].items():
    if field.startswith('COLOR_') or (field.startswith('TEXCOORD_') and field!='TEXCOORD_0'):continue
    original=source.array(ai)[used];arrays[field]=original
    component=source.d['accessors'][ai]['componentType'];primitive['attributes'][field]=accessor(original,source.d['accessors'][ai]['type'],component)
   assert np.max(np.abs(arrays['WEIGHTS_0'].sum(1)-1))<1e-5
   # Compare only joints actually influencing the selected original geometry.
   referenced=set(arrays['JOINTS_0'][arrays['WEIGHTS_0']>0].astype(int).tolist())
   for ji in referenced:
    sj=source_joints[ji];tj=target_joints[ji];label=source.d['nodes'][sj]['name']
    if source is head and label in ['clavicle_l','clavicle_r']:
     # Original modular male source has a two-degree clavicle rest change.
     # The selected head/neck keep their original inverse binds; only a few
     # low neck seam vertices receive these small original clavicle weights.
     assert np.max(np.abs(source_rest[sj]-target_rest[tj]))<.040
    else:assert np.allclose(source_rest[sj],target_rest[tj],atol=2e-5),(name,label,'native rest differs')
   invbind=source.array(source.d['skins'][0]['inverseBindMatrices']).reshape(-1,4,4).transpose(0,2,1);points4=np.c_[arrays['POSITION'],np.ones(len(used))];restposed=np.zeros_like(points4)
   for influence in range(4):
    ids=arrays['JOINTS_0'][:,influence];mats=np.asarray([target_rest[target_joints[int(j)]]@invbind[int(j)] for j in ids]);restposed+=np.einsum('nij,nj->ni',mats,points4)*arrays['WEIGHTS_0'][:,influence,None]
   seam_error=float(np.linalg.norm(restposed[:,:3]-arrays['POSITION'],axis=1).max())
   assert seam_error<.005,(name,'original modular seam rest error',seam_error)
   mesh['primitives'].append(primitive);geometry_records.append({'part':mesh['name'],'triangles':len(tri),'used_vertices':len(used),'original_source':str(source.path),'unchanged_positions_normals_uvs_skin_weights':True,'native_source_inverse_bind_matrices_preserved':True,'maximum_original_modular_rest_seam_delta_m':seam_error})
  d['meshes'].append(mesh);ni=len(d['nodes']);node={k:copy.deepcopy(v) for k,v in sn.items() if k not in ['mesh','skin','children']};node.update(name=mesh['name'],mesh=mi,skin=si);d['nodes'].append(node);d['nodes'][container]['children'].append(ni)

add_source(outfit)
add_source(head,{'Eyebrows','Eyes','SuperHero_Male'})
add_source(beard)
lookup={n['name']:i for i,n in enumerate(d['nodes'][:65])}
actions=[{'Idle_Loop','Walk_Loop','Death01','Hit_Chest','Sword_Idle'},{'Sword_Regular_A','Sword_Regular_A_Rec','Sword_Regular_B'}]
for source,selected in zip(animations,actions):
 remember(source.path)
 for action in source.d['animations']:
  if action['name'] not in selected:continue
  new={'name':action['name'],'samplers':[],'channels':[]}
  for ch in action['channels']:
   node=source.d['nodes'][ch['target']['node']];name=node.get('name');kind=ch['target']['path'];target=lookup.get(name)
   if target is None or kind=='scale':continue
   sa=action['samplers'][ch['sampler']];assert sa.get('interpolation','LINEAR')=='LINEAR';ts=source.array(sa['input']).astype('<f4');x=source.array(sa['output']).astype('<f4');tn=d['nodes'][target]
   if kind=='rotation':
    qr=np.asarray(node.get('rotation',[0,0,0,1]));qt=np.asarray(tn.get('rotation',[0,0,0,1]));x=qmul(qt,qmul(qr*np.asarray([-1,-1,-1,1]),x));x=(x/np.linalg.norm(x,axis=1)[:,None]).astype('<f4')
   elif kind=='translation':
    delta=x-np.asarray(node.get('translation',[0,0,0]));delta[:]=0 if name!='pelvis' else delta
    x=(np.asarray(tn.get('translation',[0,0,0]))+delta).astype('<f4')
   else:continue
   si=len(new['samplers']);new['samplers'].append({'input':accessor(ts,'SCALAR'),'output':accessor(x,{'rotation':'VEC4','translation':'VEC3'}[kind]),'interpolation':'LINEAR'});new['channels'].append({'sampler':si,'target':{'node':target,'path':kind}})
  d['animations'].append(new)

def save_glb():
 blob.extend(b'\0'*((-len(blob))%4));d['buffers']=[{'byteLength':len(blob)}];raw=json.dumps(d,separators=(',',':')).encode();raw+=b' '*((-len(raw))%4)
 result=struct.pack('<III',0x46546c67,2,28+len(raw)+len(blob))+struct.pack('<II',len(raw),0x4e4f534a)+raw+struct.pack('<II',len(blob),0x004e4942)+blob
 args.output.parent.mkdir(parents=True,exist_ok=True);args.output.write_bytes(result);return result
payload=save_glb();model=Source(args.output)
# Original native Sword_Idle finger closure is fitted against the real indexed
# four-influence hand triangles. The rig/body never scale or reweight a bone.
local,base=model.pose('Sword_Idle',0);native=model.local();names={n['name']:i for i,n in enumerate(model.d['nodes'])};hand=names['hand_r'];hi=np.linalg.inv(base[hand]);glob=np.asarray([hi@m for m in base]);digits=['hand','thumb','index','middle','ring','pinky']
arm=next(n for n in model.d['nodes'] if n.get('name')=='Male_Peasant_Arms');skin=model.d['skins'][arm['skin']];joints=np.asarray(skin['joints']);ib=model.array(skin['inverseBindMatrices']).reshape(-1,4,4).transpose(0,2,1);hand_joint=skin['joints'].index(names['hand_r']);primitives=model.d['meshes'][arm['mesh']]['primitives'];p=max(primitives,key=lambda primitive:int(np.count_nonzero(model.array(primitive['attributes']['JOINTS_0'])[np.unique(model.array(primitive['indices']))]==hand_joint)));raw=model.array(p['attributes']['POSITION']);ids=model.array(p['attributes']['JOINTS_0']);weights=model.array(p['attributes']['WEIGHTS_0']);tri=model.array(p['indices']).reshape(-1,3);dw=np.asarray([np.sum(np.isin(joints[ids],[i for n,i in names.items() if n.endswith('_r') and n.split('_')[0]==digit])*weights,axis=1) for digit in digits]).T;score=dw[tri].mean(1);which=score.argmax(1);selected=score.max(1)>.45;tri=tri[selected];which=which[selected];used=np.unique(tri);remap=np.zeros(len(raw),int);remap[used]=np.arange(len(used));tri=remap[tri];raw=raw[used];ids=ids[used];weights=weights[used];raw4=np.c_[raw,np.ones(len(raw))];bindpoints=np.asarray([np.einsum('nij,nj->ni',ib[ids[:,k]],raw4) for k in range(4)]);boneid=joints[ids]
controlled={i:(n,digits.index(n.split('_')[0])-1,native[i][:3,:3],Rotation.from_matrix(native[i][:3,:3].T@local[i][:3,:3]).as_rotvec()) for n,i in names.items() if n.endswith('_r') and n.split('_')[0] in digits[1:]}
def depth(i):return 1+depth(model.parent[i]) if i in model.parent else 0
order=sorted(controlled,key=depth)
def geometry(closure,detail=False):
 posed=glob.copy()
 for i in order:
  n,di,rb,rv=controlled[i];m=local[i].copy();m[:3,:3]=rb@Rotation.from_rotvec(rv*closure[di]).as_matrix();posed[i]=posed[model.parent[i]]@m
 v=np.zeros((len(raw),4))
 for k in range(4):v+=np.einsum('nij,nj->ni',posed[boneid[:,k]],bindpoints[k])*weights[:,k,None]
 return (v[:,:3],posed) if detail else v[:,:3]
def finger_wrap(x):
 _,posed=geometry(x[:5],True);origin=np.asarray([x[5],x[6],0]);axis=np.asarray([x[7],x[8],1]);axis/=np.linalg.norm(axis);values=[]
 for digit in digits[2:]:
  for suffix in ['_03_r','_04_leaf_r']:
   point=posed[names[digit+suffix]][:3,3]-origin;axial=float(point@axis);radius=float(np.linalg.norm(point-axis*axial));values.append([radius,axial])
 return np.asarray(values)
def metrics(x,detail=False):
 v=geometry(x[:5]);origin=np.asarray([x[5],x[6],0]);axis=np.asarray([x[7],x[8],1]);axis/=np.linalg.norm(axis);a=np.cross(axis,[1,0,0]);a/=np.linalg.norm(a);b=np.cross(axis,a);v-=origin;ax=v@axis;q=np.c_[v@a,v@b][tri];cross=q[:,:,0]*np.roll(q[:,:,1],-1,1)-q[:,:,1]*np.roll(q[:,:,0],-1,1);inside=(cross.min(1)>=0)|(cross.max(1)<=0);edges=np.roll(q,-1,1)-q;length=np.sum(edges*edges,2);f=np.clip(-np.sum(q*edges,2)/np.maximum(length,1e-18),0,1);projected=q+f[:,:,None]*edges;lengths=np.linalg.norm(projected,axis=2);nearest=lengths.argmin(1);rad=lengths.min(1);rad[inside]=0;sel=(ax[tri].min(1)<.055)&(ax[tri].max(1)>-.055);mins=[];directions=[]
 for di in range(6):
  chosen=np.flatnonzero(sel&(which==di))
  if len(chosen):
   best=chosen[np.argmin(rad[chosen])];mins.append(rad[best]);point=projected[best,nearest[best]];directions.append(point/max(np.linalg.norm(point),1e-12))
  else:mins.append(1.0);directions.append(np.zeros(2))
 return (np.asarray(mins),np.asarray(directions)) if detail else np.asarray(mins)
def proximal_cost(x):
 m=metrics(x);return float(300*np.sum(np.maximum(0,.0175-m)**2)+4*np.sum(np.maximum(0,m[1:]-.0205)**2)+.1*max(0,m[0]-.028)**2)
bounds=[(.7,1.12),(.30,.80),(.30,.85),(.30,.85),(.30,.80),(-.07,-.01),(.035,.11),(-.5,.5),(-.5,.6)]
x0=np.asarray([1,.5,.58,.58,.5,-.035,.076,-.027,.209]);initial=minimize(proximal_cost,x0,bounds=bounds,method='Powell',options={'maxiter':80,'xtol':1e-6,'ftol':1e-9,'maxfev':10000});fixed=initial.x;print('PROXIMAL',initial.fun,fixed.tolist(),metrics(fixed).tolist(),flush=True)
assert initial.fun<1e-6
selected=[i for digit in digits[2:] for i in [names[digit+'_02_r'],names[digit+'_03_r']]]
variables=np.asarray([fixed[controlled[i][1]] for i in selected]);parameters=dict(zip(selected,variables))
def geometry(closures,detail=False):
 posed=glob.copy()
 for i in order:
  name,di,rb,rv=controlled[i];m=local[i].copy();factor=parameters.get(i,closures[di]);m[:3,:3]=rb@Rotation.from_rotvec(rv*factor).as_matrix();posed[i]=posed[model.parent[i]]@m
 v=np.zeros((len(raw),4))
 for k in range(4):v+=np.einsum('nij,nj->ni',posed[boneid[:,k]],bindpoints[k])*weights[:,k,None]
 return (v[:,:3],posed)if detail else v[:,:3]
def contact_opposition():
 v=geometry(fixed[:5]);origin=np.asarray([fixed[5],fixed[6],0]);axis=np.asarray([fixed[7],fixed[8],1]);axis/=np.linalg.norm(axis);a=np.cross(axis,[1,0,0]);a/=np.linalg.norm(a);b=np.cross(axis,a);v-=origin;ax=v@axis;q=np.c_[v@a,v@b][tri];edges=np.roll(q,-1,1)-q;length=np.sum(edges*edges,2);f=np.clip(-np.sum(q*edges,2)/np.maximum(length,1e-18),0,1);projected=q+f[:,:,None]*edges;distance=np.linalg.norm(projected,axis=2);edge=distance.argmin(1);rad=distance.min(1);points=projected[np.arange(len(q)),edge];directions=points/np.maximum(np.linalg.norm(points,axis=1)[:,None],1e-12);sel=(ax[tri].min(1)<.055)&(ax[tri].max(1)>-.055);thumbs=np.flatnonzero(sel&(which==1));thumb=directions[thumbs[np.argmin(rad[thumbs])]];values=[]
 for di in range(2,6):
  chosen=np.flatnonzero(sel&(which==di)&(rad<=.021))
  values.append(float(np.min(directions[chosen]@thumb))if len(chosen)else 1)
 return np.asarray(values)
def distal_cost(x):
 global parameters
 parameters=dict(zip(selected,x));m=metrics(fixed);wrap=finger_wrap(fixed);opposition=np.sort(contact_opposition())[:3]
 return float(300*np.sum(np.maximum(0,.0172-m)**2)+4*np.sum(np.maximum(0,m[1:]-.0205)**2)+.1*max(0,m[0]-.028)**2+8*np.sum(np.maximum(0,wrap[:,0]-.0348)**2)+4*np.sum(np.maximum(0,np.abs(wrap[:,1])-.065)**2)+.0002*np.sum(np.maximum(0,opposition+.55)**2))
bounds=[(.25,1.42) if i%2==0 else (.25,1.20) for i in range(8)];best=None
for seed in range(6):
 start=variables if seed==0 else np.maximum(np.asarray([v[0]for v in bounds]),np.minimum(np.asarray([v[1]for v in bounds]),best.x+np.random.default_rng(seed).normal(0,.06,8)))
 result=minimize(distal_cost,start,bounds=bounds,method='Powell',options={'maxiter':100,'xtol':1e-6,'ftol':1e-9,'maxfev':15000})
 if best is None or result.fun<best.fun:best=result
 distal_cost(best.x);print('DISTAL',seed,best.fun,best.x.tolist(),'mins',metrics(fixed).tolist(),'wrap',finger_wrap(fixed).tolist(),'opposed',contact_opposition().tolist(),flush=True)
 if best.fun<1e-8:break
distal_cost(best.x);assert best.fun<1e-6,('Failed physical distal-wrap fit',best.fun)
# Rigid 0.4 mm hilt adjustment supplies the third opposed real wood-face
# contact, independently verified after native import; no anatomy is changed.
pre_adjustment_projected_opposition=contact_opposition().tolist()
fixed[5]+=.0004
axis=np.asarray([fixed[7],fixed[8],1]);axis/=np.linalg.norm(axis)
profile={'method':'Original indexed male hands with unchanged native skeleton; native proximal source grip fitted first, independent distal02/03 phalanx curl closes visible fingertips while retaining proximal contact; runtime smoke independently audits real indexed contact/opposition and distal wrap','model_sha256':hashlib.sha256(payload).hexdigest(),'physical_grip_radius_m':.018,'hand_local_origin':[float(fixed[5]),float(fixed[6]),0],'hand_local_axis':axis.tolist(),'bone_local_quaternions_xyzw':{name:Rotation.from_matrix(rb@Rotation.from_rotvec(rv*parameters.get(i,fixed[di])).as_matrix()).as_quat().tolist()for i,(name,di,rb,rv)in controlled.items()},'offline_digit_axis_minimum_m':dict(zip(digits,metrics(fixed).tolist())),'fit_cost':float(best.fun),'actual_prop_contact_adjustment_m':[.0004,0,0],'native_proximal_factors':fixed[:5].tolist(),'native_distal_factors':best.x.tolist(),'maximum_fitted_hinge_degrees':max(float(np.linalg.norm(rv)*parameters.get(i,fixed[di])*180/np.pi)for i,(name,di,rb,rv)in controlled.items()),'pre_adjustment_projected_contact_opposition_dot':pre_adjustment_projected_opposition,'distal_joint_radial_and_axial_m':dict(zip([digit+suffix for digit in digits[2:]for suffix in ['_03_r','_04_leaf_r']],finger_wrap(fixed).tolist()))}
args.output.with_name('axe-grip.json').write_text(json.dumps(profile,indent=2)+'\n')

# Exact native weighted death floor samples avoid per-frame full-body CPU skinning.
probes=[]
for node in model.d['nodes']:
 if 'mesh' not in node:continue
 skin=model.d['skins'][node['skin']];js=np.asarray(skin['joints']);ib=model.array(skin['inverseBindMatrices']).reshape(-1,4,4).transpose(0,2,1)
 for p in model.d['meshes'][node['mesh']]['primitives']:
  used=np.unique(model.array(p['indices']));v=model.array(p['attributes']['POSITION'])[used];ids=model.array(p['attributes']['JOINTS_0'])[used];w=model.array(p['attributes']['WEIGHTS_0'])[used];v4=np.c_[v,np.ones(len(v))];bp=np.asarray([np.einsum('nij,nj->ni',ib[ids[:,k]],v4) for k in range(4)]);probes.append((js[ids],w,bp))
death=next(a for a in model.d['animations'] if a['name']=='Death01');length=max(float(model.array(s['input'])[-1,0]) for s in death['samplers']);floor=[]
for t in np.linspace(0,length,91):
 _,pose=model.pose('Death01',float(t));minimum=float('inf')
 for bid,w,bp in probes:
  y=np.zeros(len(w))
  for k in range(4):y+=np.einsum('nij,nj->ni',pose[bid[:,k]],bp[k])[:,1]*w[:,k]
  minimum=min(minimum,float(y.min()))
 floor.append(max(.009,.003-minimum))
args.output.with_name('death-grounding.json').write_text(json.dumps({'source_clip':'Death01','normalized_samples':91,'samples':floor,'actual_indexed_weighted_surface_floor':True},indent=2)+'\n')
# Brackets in manufacturer directory names are literals: use known parent roots.
licenses=[(head.path.parents[2]/'License_Standard.txt','BASE-LICENSE.txt'),(outfit.path.parents[3]/'License_Standard.txt','OUTFIT-LICENSE.txt'),(args.animation1.parents[1]/'License.txt','ANIMATION1-LICENSE.txt'),(args.animation2.parents[1]/'License.txt','ANIMATION2-LICENSE.txt')]
for source,name in licenses:assert source.exists(),source;shutil.copyfile(source,args.output.parent/name);remember(source)
for weapon_file in [Path('assets/models/raider056/axe-original.glb'),Path('assets/models/raider056/axe-fitted.glb'),Path('assets/models/raider056/WEAPON-LICENSE.txt')]:
 if weapon_file.exists():remember(weapon_file.resolve())
weapon_meta=json.loads(Path('assets/models/raider056/axe-fitted.json').read_text())
report={'model_sha256':hashlib.sha256(payload).hexdigest(),'bytes':len(payload),'native_bones':65,'source_height_m':float(max(model.array(p['attributes']['POSITION'])[:,1].max() for m in model.d['meshes'] for p in m['primitives'])),'body_triangles':sum(x['triangles'] for x in geometry_records),'weapon_source':'Original Quaternius Axe Small, CC0; sharp original steel edge/bevel/normal data preserved, only wooden grip fitted','weapon_triangles':weapon_meta['triangles'],'total_visible_triangles':sum(x['triangles'] for x in geometry_records)+weapon_meta['triangles'],'budget':'Actual original clothed body/head/eyes/brows/beard kept below20k including axe; exceeds preferred15k budget, no damaged anatomical decimation','texture_size_limit':1024,'parts':geometry_records,'animations':[a['name'] for a in d['animations']],'original_native_rest_preserved':True,'source_files':inputs,'license':'CC0 1.0 Quaternius free Standard source notices preserved byte for byte; original CC0 Quaternius Axe Small attribution/source license in WEAPON-LICENSE.txt'}
args.output.with_suffix('.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:v for k,v in report.items() if k not in ['source_files','parts']},indent=2))
