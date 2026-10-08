#!/usr/bin/env python3
"""Read-only independent native-skin versus actual wooden facet audit.

No Godot, Blender, fitting, source mutation, or animation-clock changes.
Sword_Idle(0) plus the final fitted local finger rotations is reconstructed
from all original four skin weights and inverse binds. Hand triangles are
clipped to +/-55 mm along the real hand-local grip axis. Actual original wood
triangles supply the central cross section; additional sections establish its
constant extrusion over the entire clipped hand band. Distances are unsigned.
This check does not measure a physical phone or every animation/recoil pose.
"""
from pathlib import Path
import hashlib, json
import numpy as np
from scipy.spatial import ConvexHull
from scipy.spatial.transform import Rotation

HERE = Path(__file__).resolve().parent
REPO = Path('/workspace/Emberfall-Ashen-Veil')
BUILDER = HERE / 'build_raider056.final.py'
BODY = REPO / 'assets/models/raider056/raider-native65.glb'
PROFILE = REPO / 'assets/models/raider056/axe-grip.json'
AXE = REPO / 'assets/models/raider056/axe-fitted.glb'
OUTPUT = HERE / 'independent_faceted_grip_audit.json'
# Read just the source-accessor implementation, never run the builder main.
ns = {'__name__': 'offline_source_accessors'}
exec(compile(BUILDER.read_text().split('parser=argparse.ArgumentParser', 1)[0],
             str(BUILDER), 'exec'), ns)
Source = ns['Source']
model, prop = Source(BODY), Source(AXE)
profile = json.loads(PROFILE.read_text())
local, _ = model.pose('Sword_Idle', 0.0)
names = {n.get('name'): i for i, n in enumerate(model.d['nodes'])}
for name, q in profile['bone_local_quaternions_xyzw'].items():
    i = names[name]
    scale = np.linalg.norm(local[i][:3, :3], axis=0)
    local[i][:3, :3] = Rotation.from_quat(q).as_matrix() @ np.diag(scale)
posed = model.global_pose(local)
hand_inverse = np.linalg.inv(posed[names['hand_r']])
origin = np.asarray(profile['hand_local_origin'])
axis = np.asarray(profile['hand_local_axis']); axis /= np.linalg.norm(axis)
first = np.cross(axis, [1., 0., 0.]); first /= np.linalg.norm(first)
second = np.cross(axis, first)
# Exact SourceAvatarRig._frame(axis, RIGHT) * Ry(pi/2) * AXE_SCALE.
z = np.array([1., 0., 0.]) - axis * axis[0]; z /= np.linalg.norm(z)
frame = np.column_stack((np.cross(axis, z), axis, z))
weapon_basis = frame @ Rotation.from_rotvec([0., np.pi / 2, 0.]).as_matrix() * .55
grip = np.asarray([0., .035, 0.])

def projected(points):
    delta = np.asarray(points) - origin
    return np.column_stack((delta @ first, delta @ second))

def clip(polygon, bound, above):
    out = []
    for p, q in zip(polygon, np.roll(polygon, -1, axis=0)):
        a, b = (p-origin)@axis-bound, (q-origin)@axis-bound
        inside_a, inside_b = (a >= 0, b >= 0) if above else (a <= 0, b <= 0)
        if inside_a: out.append(p)
        if inside_a != inside_b: out.append(p + a / (a-b) * (q-p))
    return np.asarray(out).reshape(-1, 3)

def point_segment(point, a, b):
    d = b-a
    t = np.clip((point-a)@d / max(float(d@d), 1e-30), 0, 1)
    q = a+t*d
    return float(np.linalg.norm(point-q)), q

def point_boundary(point, hull):
    return min(point_segment(point, a, b)[0]
               for a, b in zip(hull, np.roll(hull, -1, axis=0)))

def nearest_axis(polygon):
    return min((point_segment(np.zeros(2), a, b) for a, b in
                zip(polygon, np.roll(polygon, -1, axis=0))), key=lambda x:x[0])

def cross(a, b): return float(a[0]*b[1]-a[1]*b[0])

def segment_distance(a, b, c, d):
    ab, cd = b-a, d-c
    det = cross(ab, cd)
    if abs(det)>1e-16:
        t, u = cross(c-a, cd)/det, cross(c-a, ab)/det
        if 0 <= t <= 1 and 0 <= u <= 1: return 0.0
    return min(point_segment(a,c,d)[0], point_segment(b,c,d)[0],
               point_segment(c,a,b)[0], point_segment(d,a,b)[0])

def boundary_distance(polygon, hull):
    return min(segment_distance(a,b,c,d)
               for a,b in zip(polygon,np.roll(polygon,-1,axis=0))
               for c,d in zip(hull,np.roll(hull,-1,axis=0)))

def point_triangle_distances(point, triangles, return_points=False):
    """Exact point to closed triangle; vectorized over target triangles."""
    a,b,c = triangles[:,0],triangles[:,1],triangles[:,2]
    ab,ac,ap = b-a,c-a,point-a
    normal = np.cross(ab,ac); nn = np.einsum('ni,ni->n',normal,normal)
    plane = ap-normal*(np.einsum('ni,ni->n',ap,normal)/np.maximum(nn,1e-30))[:,None]
    d00=np.einsum('ni,ni->n',ab,ab); d01=np.einsum('ni,ni->n',ab,ac)
    d11=np.einsum('ni,ni->n',ac,ac)
    d20=np.einsum('ni,ni->n',plane,ab); d21=np.einsum('ni,ni->n',plane,ac)
    den=d00*d11-d01*d01
    u=(d11*d20-d01*d21)/np.maximum(den,1e-30)
    v=(d00*d21-d01*d20)/np.maximum(den,1e-30)
    inside=(u>=-1e-10)&(v>=-1e-10)&(u+v<=1+1e-10)&(nn>1e-24)
    out=np.full(len(triangles),np.inf)
    nearest=a.copy()
    out[inside]=np.abs(np.einsum('ni,ni->n',ap,normal)[inside])/np.sqrt(nn[inside])
    nearest[inside]=(a+plane)[inside]
    for start,end in [(a,b),(b,c),(c,a)]:
        edge=end-start
        t=np.clip(np.einsum('ni,ni->n',point-start,edge)/
                  np.maximum(np.einsum('ni,ni->n',edge,edge),1e-30),0,1)
        candidate=start+t[:,None]*edge
        distance=np.linalg.norm(point-candidate,axis=1)
        better=distance<out;nearest[better]=candidate[better]
        out=np.minimum(out,distance)
    return (out,nearest) if return_points else out

def segment_segment_distances(a,b,c,d,return_points=False):
    """Exact closed segment distances; c,d are vectorized target edges."""
    u=b-a;v=d-c;r=a-c
    aa=float(u@u);ee=np.einsum('ni,ni->n',v,v)
    ff=np.einsum('ni,ni->n',v,r);cc=r@u;bb=v@u
    den=aa*ee-bb*bb
    ss=np.zeros(len(c)); good=den>1e-24
    ss[good]=np.clip((bb[good]*ff[good]-cc[good]*ee[good])/den[good],0,1)
    tt=(bb*ss+ff)/np.maximum(ee,1e-30)
    below=tt<0; above=tt>1
    ss[below]=np.clip(-cc[below]/max(aa,1e-30),0,1)
    ss[above]=np.clip((bb[above]-cc[above])/max(aa,1e-30),0,1)
    tt=np.clip(tt,0,1)
    nearest=a+ss[:,None]*u
    distance=np.linalg.norm(nearest-(c+tt[:,None]*v),axis=1)
    return (distance,nearest) if return_points else distance

def triangle_surface_distance(triangle, targets):
    """Closed triangle pair distance including edge-face intersections."""
    best=np.inf;best_point=np.zeros(3)
    for p in triangle:
        distance=float(point_triangle_distances(p,targets).min())
        if distance<best:best=distance;best_point=p
    repeated=np.repeat(triangle[None,:,:],len(targets),axis=0)
    for corner in range(3):
        distances,points=point_triangle_distances(targets[:,corner],repeated,True)
        index=int(distances.argmin())
        if distances[index]<best:best=float(distances[index]);best_point=points[index]
    for a,b in zip(triangle,np.roll(triangle,-1,axis=0)):
        for corner in range(3):
            distances,points=segment_segment_distances(a,b,targets[:,corner],targets[:,(corner+1)%3],True)
            index=int(distances.argmin())
            if distances[index]<best:best=float(distances[index]);best_point=points[index]
        # A segment can pierce a target face away from its edges.
        normal=np.cross(targets[:,1]-targets[:,0],targets[:,2]-targets[:,0])
        denom=normal@(b-a)
        valid=np.abs(denom)>1e-20
        t=np.zeros(len(targets));t[valid]=np.einsum('ni,ni->n',targets[:,0]-a,normal)[valid]/denom[valid]
        valid&=(t>=0)&(t<=1)
        if valid.any():
            points=a+t[valid,None]*(b-a)
            inside=point_triangle_distances(points,targets[valid])<1e-10
            if inside.any(): return 0.0,points[np.flatnonzero(inside)[0]]
    # Target edges can pierce the skin triangle face as well.
    normal=np.cross(triangle[1]-triangle[0],triangle[2]-triangle[0])
    for corner in range(3):
        a=targets[:,corner];b=targets[:,(corner+1)%3];denom=(b-a)@normal
        valid=np.abs(denom)>1e-20;t=np.zeros(len(targets))
        t[valid]=((triangle[0]-a)@normal)[valid]/denom[valid]
        valid&=(t>=0)&(t<=1)
        if valid.any():
            points=a[valid]+t[valid,None]*(b[valid]-a[valid])
            inside=point_triangle_distances(points,repeated[valid])<1e-10
            if inside.any(): return 0.0,points[np.flatnonzero(inside)[0]]
    return best,best_point

# Keep only the actual original wood surfaces, using original node transforms.
wood_triangles = []
prop_pose = prop.global_pose(prop.local())
for i, node in enumerate(prop.d['nodes']):
    if 'mesh' not in node: continue
    for primitive in prop.d['meshes'][node['mesh']]['primitives']:
        material = prop.d['materials'][primitive['material']].get('name','')
        if 'wood' not in material.lower(): continue
        raw = prop.array(primitive['attributes']['POSITION'])
        points = (np.c_[raw,np.ones(len(raw))] @ prop_pose[i].T)[:,:3]
        points = (points-grip) @ weapon_basis.T + origin
        indices = prop.array(primitive['indices']).reshape(-1,3)
        wood_triangles.extend(points[indices])
assert wood_triangles, 'Actual original wood surface missing'
actual_wood_band=[]
for triangle in wood_triangles:
    polygon=clip(triangle,-.055,True)
    if len(polygon):polygon=clip(polygon,.055,False)
    for j in range(1,len(polygon)-1):
        actual_wood_band.append([polygon[0],polygon[j],polygon[j+1]])
actual_wood_band=np.asarray(actual_wood_band)

def section(axial):
    points = []
    for triangle in wood_triangles:
        for p,q in zip(triangle,np.roll(triangle,-1,axis=0)):
            a,b = (p-origin)@axis-axial,(q-origin)@axis-axial
            if abs(a)<1e-10: points.append(p)
            if a*b<0: points.append(p+a/(a-b)*(q-p))
    unique = np.unique(np.round(projected(points),10),axis=0)
    return unique[ConvexHull(unique).vertices]

hull = section(0.)
extrusion_errors = {}
for axial in [-.055,-.0275,.0275,.055]:
    other = section(axial)
    # ConvexHull may retain extra almost-collinear cut points after float32
    # source interpolation. Compare the real boundary, not vertex sets.
    error = max(max(point_boundary(p,hull) for p in other),
                max(point_boundary(p,other) for p in hull))
    extrusion_errors[str(axial)] = float(error)
constant_extrusion = max(extrusion_errors.values())<1e-6

digits = ['hand','thumb','index','middle','ring','pinky']
results = {d:{'axial_clipped_triangles':0,'minimum_axis_radius_m':1e9,
             'actual_facet_distance_at_nearest_axis_patch_m':1e9,
             'minimum_actual_facet_boundary_distance_m':1e9,
             'minimum_actual_3d_wood_surface_distance_m':1e9,
             'nearest_actual_3d_skin_point_hand_local_m':None,
             'actual_3mm_contact_directions':[]} for d in digits}
arm = next(n for n in model.d['nodes'] if n.get('name')=='Male_Peasant_Arms')
skin = model.d['skins'][arm['skin']]
joints = np.asarray(skin['joints'])
ib = model.array(skin['inverseBindMatrices']).reshape(-1,4,4).transpose(0,2,1)
matrices = np.asarray([hand_inverse @ posed[j] @ ib[k] for k,j in enumerate(joints)])
for primitive in model.d['meshes'][arm['mesh']]['primitives']:
    raw = model.array(primitive['attributes']['POSITION'])
    ids = model.array(primitive['attributes']['JOINTS_0'])
    weights = model.array(primitive['attributes']['WEIGHTS_0'])
    v = np.zeros((len(raw),4)); raw4 = np.c_[raw,np.ones(len(raw))]
    for k in range(4):
        v += np.einsum('nij,nj->ni', matrices[ids[:,k]], raw4) * weights[:,k,None]
    dw = np.asarray([np.sum(np.isin(joints[ids], [i for n,i in names.items()
         if n and n.endswith('_r') and n.split('_')[0]==digit])*weights,axis=1)
         for digit in digits]).T
    for triangle in model.array(primitive['indices']).reshape(-1,3):
        score = dw[triangle].mean(axis=0)
        if score.max()<=.45: continue
        polygon = clip(v[triangle,:3],-.055,True)
        if len(polygon): polygon = clip(polygon,.055,False)
        if len(polygon)<3: continue
        result = results[digits[int(score.argmax())]]
        result['axial_clipped_triangles'] += 1
        q = projected(polygon)
        radius, point = nearest_axis(q)
        if radius < result['minimum_axis_radius_m']:
            result['minimum_axis_radius_m'] = radius
            result['actual_facet_distance_at_nearest_axis_patch_m'] = point_boundary(point,hull)
        result['minimum_actual_facet_boundary_distance_m'] = min(
            result['minimum_actual_facet_boundary_distance_m'], boundary_distance(q,hull))
        for j in range(1,len(polygon)-1):
            actual_skin_triangle=np.asarray([polygon[0],polygon[j],polygon[j+1]])
            distance,skin_point=triangle_surface_distance(actual_skin_triangle,actual_wood_band)
            radial=skin_point-origin-axis*((skin_point-origin)@axis)
            direction=radial/max(float(np.linalg.norm(radial)),1e-20)
            if distance<result['minimum_actual_3d_wood_surface_distance_m']:
                result['minimum_actual_3d_wood_surface_distance_m']=distance
                result['nearest_actual_3d_skin_point_hand_local_m']=skin_point.tolist()
                result['nearest_actual_3d_radial_direction']=direction.tolist()
            if distance<=.003:
                result['actual_3mm_contact_directions'].append(direction.tolist())

receipt = {'scope':'Original native Sword_Idle(0) with production fitted local finger rotations and hand-local grip origin; actual indexed weighted skin versus actual 3D indexed wood facets in +/-55mm. The independent central-section proxy is reported separately and is not used for 3D contact/opposition. Unsigned contact distances, not a full animation sweep or signed penetration test.',
    'engine_used':False,'source_mutated':False,'contact_limit_m':.003,
    'production_hand_local_origin_m':origin.tolist(),
    'actual_wood_hull_vertices':len(hull),'actual_wood_hull_cross_section_m':hull.tolist(),
    'constant_extrusion_maximum_deviation_m':max(extrusion_errors.values()),
    'constant_extrusion_section_deviation_m':extrusion_errors,
    'constant_extrusion_hand_band_pass':constant_extrusion,
    'wood_band_clipped_triangles':len(actual_wood_band),
    'digits':results,'final_five_digits_nearest_axis_patch_contact_pass':all(
        results[d]['actual_facet_distance_at_nearest_axis_patch_m']<=.003 for d in digits[1:]),
    'generic_cylinder_audit_limitation':'A circumradius cylinder can produce false-positive contact for other profiles; actual facets are measured here.',
    'inputs_sha256':{str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in
        [BUILDER,BODY,PROFILE,AXE,Path(__file__).resolve()]}}
receipt['complete_hand_band_contact_pass'] = all(
    results[d]['minimum_actual_3d_wood_surface_distance_m']<=.003 for d in digits[1:])
thumb_direction=np.asarray(results['thumb']['nearest_actual_3d_radial_direction'])
receipt['actual_3d_opposition_minimum_dot_by_finger']={d:min(
    (float(thumb_direction@np.asarray(v)) for v in results[d]['actual_3mm_contact_directions']),
    default=1.0) for d in digits[2:]}
receipt['actual_3d_opposition_fingers']=sum(v<-.5 for v in receipt['actual_3d_opposition_minimum_dot_by_finger'].values())
receipt['actual_3d_opposition_pass']=receipt['actual_3d_opposition_fingers']>=3
OUTPUT.write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps({'receipt':str(OUTPUT),'actual_hull_vertices':len(hull),'pass':receipt['complete_hand_band_contact_pass'],
    'five_digit_actual_nearest_axis_patch_gap_mm':{d:results[d]['actual_facet_distance_at_nearest_axis_patch_m']*1000 for d in digits[1:]},
    'five_digit_actual_3d_wood_surface_gap_mm':{d:results[d]['minimum_actual_3d_wood_surface_distance_m']*1000 for d in digits[1:]},
    'opposition_minimum_dot_by_finger':receipt['actual_3d_opposition_minimum_dot_by_finger'],
    'opposition_fingers':receipt['actual_3d_opposition_fingers']},indent=2))
assert receipt['complete_hand_band_contact_pass'] and receipt['actual_3d_opposition_pass'], 'Actual 3D wood contact/opposition does not pass; inspect original receipt'
