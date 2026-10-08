"""Read-only PNG analysis for source-calibrated painterly pose meshes.

The generator's equal-cell packing is imperfect. Keep every original RGBA pixel
untouched and trace each authored figure's connected alpha into UV polygons.
These polygons, source regions and actual foot anchors let Godot render complete
poses without sampling neighboring figures or clipping a weapon at a grid seam.
"""
from pathlib import Path
import json
import numpy as np
from PIL import Image
from scipy import ndimage
from skimage import measure, segmentation

ROOT=Path(__file__).resolve().parents[2]
ASSETS=ROOT/'assets/characters'
ALPHA_THRESHOLD=11  # shader alpha scissors at .045; 8-bit nearest integer


def remove_collinear(points):
    points=[tuple(float(x) for x in p) for p in points]
    if points[0]==points[-1]: points.pop()
    keep=[]
    for i,p in enumerate(points):
        a=points[i-1];b=points[(i+1)%len(points)]
        if abs((p[0]-a[0])*(b[1]-p[1])-(p[1]-a[1])*(b[0]-p[0]))>1e-8: keep.append(p)
    return keep


def calibrate(name):
    image=Image.open(ASSETS/(name+'.png')).convert('RGBA')
    rgba=np.asarray(image)
    alpha=rgba[:,:,3]
    h,w=alpha.shape
    cols,rows=(6,4) if name=='hostiles' else (3,2)
    cell_w=w/cols;cell_h=h/rows
    visible=alpha>ALPHA_THRESHOLD
    labels,count=ndimage.label(visible,np.ones((3,3),dtype=np.uint8))
    areas=np.bincount(labels.ravel())
    slices=ndimage.find_objects(labels)
    ids=np.arange(1,count+1)
    centers=np.asarray(ndimage.center_of_mass(visible,labels,ids))
    seeds=np.zeros_like(labels,dtype=np.int32)
    density=ndimage.uniform_filter((alpha>=128).astype(float),size=11)
    for index in range(cols*rows):
        row,col=divmod(index,cols)
        pose=(row%2)*3+col%3
        preferred_y=(.83 if pose==5 else .48)*cell_h+row*cell_h
        preferred_x=(.52 if pose!=4 else .58)*cell_w+col*cell_w
        y0,y1=int(row*cell_h),int((row+1)*cell_h)
        x0,x1=int(col*cell_w),int((col+1)*cell_w)
        candidate=(density[y0:y1,x0:x1]>.72)&(alpha[y0:y1,x0:x1]>=180)
        cy,cx=np.nonzero(candidate)
        if not len(cx): raise RuntimeError(f'{name}: frame {index} has no opaque body seed')
        nearest=np.argmin(((cx+x0-preferred_x)/cell_w)**2+((cy+y0-preferred_y)/cell_h)**2)
        seeds[cy[nearest]+y0,cx[nearest]+x0]=index+1
    # Body cores seed a distance watershed. A thin touching wisp cannot merge
    # two authored actors; the divider follows the alpha bridge rather than a
    # nominal grid seam which would cut a complete staff or hammer in half.
    owners=segmentation.watershed(-ndimage.distance_transform_edt(visible),seeds,mask=visible,connectivity=np.ones((3,3)))
    nearest=ndimage.distance_transform_edt(owners==0,return_distances=False,return_indices=True)
    nearest_owner=owners[nearest[0],nearest[1]]
    missing_labels,missing_count=ndimage.label(visible&(owners==0),np.ones((3,3)))
    missing_slices=ndimage.find_objects(missing_labels)
    for label in range(1,missing_count+1):
        sy,sx=missing_slices[label-1]
        fragment=missing_labels[sy,sx]==label
        fragment_owner=int(np.bincount(nearest_owner[sy,sx][fragment]).argmax())
        owners[sy,sx][fragment]=fragment_owner
    assert np.all(owners[visible]>0)
    components=[]
    for label,(y,x) in enumerate(centers,1):
        sy,sx=slices[label-1]
        assignments=np.unique(owners[sy,sx][labels[sy,sx]==label])-1
        components.append({'area':int(areas[label]),'bbox':[sx.start,sy.start,sx.stop,sy.stop],'frames':[int(i) for i in assignments]})
    frames=[]
    max_vertices=0
    for index in range(cols*rows):
        mask=owners==index+1
        ys,xs=np.nonzero(mask)
        if xs.size<100: raise RuntimeError(f'{name}: frame {index} missing authored figure')
        x0,x1=int(xs.min()),int(xs.max()+1)
        y0,y1=int(ys.min()),int(ys.max()+1)
        foot_y=y1
        lower_x=xs[ys>=y1-max(4,int(cell_h*.022))]
        foot_x=float(np.median(lower_x))+0.5
        # Marching contours use pixel-center coordinates. Padding closes source
        # contours which reach the image boundary; exact collinear removal
        # reduces mesh size without shaving off painted hair or weapon tips.
        contours=measure.find_contours(np.pad(mask,1),.5,fully_connected='high',positive_orientation='low')
        polygons=[]
        vertices=0
        for contour in contours:
            if len(contour)<4: continue
            points=remove_collinear([(p[1]-.5,p[0]-.5) for p in contour])
            if len(points)<3: continue
            area=sum(points[i][0]*points[(i+1)%len(points)][1]-points[(i+1)%len(points)][0]*points[i][1] for i in range(len(points)))*.5
            if area<=0: continue  # Inner alpha holes remain transparent in PNG.
            polygons.append([[round(x,2),round(y,2)] for x,y in points])
            vertices+=len(points)
        if not polygons: raise RuntimeError(f'{name}: frame {index} has no outer contours')
        max_vertices=max(max_vertices,vertices)
        frames.append({'region':[x0,y0,x1-x0,y1-y0],'foot_anchor':[round(foot_x,2),foot_y],
                       'polygons':polygons,'visible_pixels':int(xs.size),'vertices':vertices})
    # One reference BODY height per class, never a per-pose stretch. Raised
    # weapons may exceed it and a fallen pose remains naturally low.
    for index,frame in enumerate(frames):
        row,col=divmod(index,cols)
        idle_index=(row//2*2)*cols+(col//3*3)
        idle=frames[idle_index]
        mask=owners==idle_index+1
        band=np.abs(np.arange(w)-idle['foot_anchor'][0])<cell_w*.18
        body_ys=np.nonzero(mask&band[None,:])[0]
        body_top=int(body_ys.min())
        body_height=idle['foot_anchor'][1]-body_top
        frame['body_height']=body_height
        frame['body_top']=body_top
        rgb=rgba[:,:,:3].astype(float)
        skin=(rgb[:,:,0]>155)&(rgb[:,:,1]>105)&(rgb[:,:,2]>80)&(rgb[:,:,0]-rgb[:,:,1]>9)&(rgb[:,:,1]-rgb[:,:,2]>5)&(rgb[:,:,2]/np.maximum(rgb[:,:,0],1)>.53)&(rgb[:,:,1]/np.maximum(rgb[:,:,0],1)>.67)
        head_zone=(np.arange(h)[:,None]<body_top+body_height*.29)&(np.arange(h)[:,None]>=body_top)
        skin_labels,skin_count=ndimage.label(skin&mask&head_zone,np.ones((3,3)))
        if skin_count:
            sizes=np.bincount(skin_labels.ravel()); sizes[0]=0
            fy,fx=ndimage.center_of_mass(skin_labels==sizes.argmax())
            idle['portrait_anchor']=[round(fx+.5,2),round(fy+.5,2)]
        else: idle['portrait_anchor']=[idle['foot_anchor'][0],body_top+body_height*.14]
    payload={'schema':1,'source':name+'.png','source_size':[w,h],'declared_grid':[cols,rows],
             'packing':'calibrated_source_uv_polygons','reference_cell_height':cell_h,
             'alpha_threshold':ALPHA_THRESHOLD,'assignment':'opaque_body_seeded_alpha_watershed','visible_pixels':int(visible.sum()),'frames':frames}
    (ASSETS/(name+'.atlas.json')).write_text(json.dumps(payload,separators=(',',':'))+'\n')
    print(name,'frames',len(frames),'max vertices',max_vertices,'alpha pixels',int(visible.sum()),'native zero alpha',int((alpha==0).sum()))
    return payload,components


if __name__=='__main__':
    summary={}
    for name in ['vowkeeper','arcanist','ranger','hostiles','guardian_0','guardian_1','guardian_2','guardian_3']:
        data,components=calibrate(name)
        summary[name]={'frames':[{'region':f['region'],'foot_anchor':f['foot_anchor'],'visible_pixels':f['visible_pixels'],'vertices':f['vertices']} for f in data['frames']],
                       'primary_components':[c for c in components if c['area']>1000]}
    (ASSETS/'atlas-calibration-audit.json').write_text(json.dumps(summary,indent=2)+'\n')
