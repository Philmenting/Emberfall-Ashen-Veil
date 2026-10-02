"""Read-only source-alpha calibration of the twelve-piece animation paintings.

PNG pixels are never edited. Connected alpha assigns the actual parts, including
irregular packing and detached cloth fibers, rather than cutting nominal cells.
The emitted UV contours and anchors are consumed by the native skinned actor.
"""
from pathlib import Path
import hashlib
import json
import sys
import numpy as np
from PIL import Image
from scipy import ndimage
from skimage import measure

ASSETS = Path(__file__).resolve().parents[2] / 'assets/characters/motion'
NAMES = ['torso', 'head', 'cape', 'weapon', 'arm', 'forearm',
         'off_arm', 'off_forearm', 'thigh_l', 'shin_l', 'thigh_r', 'shin_r']
HOSTILE_JOINTS = {
    'raider': [[[160,510],[211,638]], [[465,490],[607,654]], [[876,505],[905,627]], [[1130,505],[1214,612]]],
    'bulwark': [[[171,475],[197,601]], [[520,435],[622,637]], [[892,471],[936,585]], [[1153,514],[1213,570]]],
    'hexer': [[[183,502],[245,632]], [[519,515],[590,660]], [[894,526],[913,638]], [[1291,495],[1218,633]]],
    'elite': [[[174,479],[126,630]], [[472,485],[591,663]], [[882,477],[913,601]], [[1177,515],[1241,613]]],
}


def calibrate(path):
    rgba = np.asarray(Image.open(path).convert('RGBA'))
    alpha = rgba[:, :, 3] > 11
    labels, count = ndimage.label(alpha, np.ones((3, 3)))
    areas = np.bincount(labels.ravel())
    ids = np.argsort(areas[1:])[-12:] + 1
    centers = {int(i): ndimage.center_of_mass(labels == i) for i in ids}
    ids = sorted(ids, key=lambda i: centers[int(i)][0])
    ids = [i for row in range(3) for i in sorted(ids[row*4:row*4+4], key=lambda i: centers[int(i)][1])]
    assert len(ids) == 12 and min(areas[ids]) > 1000, f'{path.name}: incomplete parts'
    owners = np.zeros_like(labels)
    for index, label in enumerate(ids): owners[labels == label] = index+1
    # Detached small fibers/ornaments belong to their nearest actual piece.
    nearest = ndimage.distance_transform_edt(owners == 0, return_distances=False, return_indices=True)
    near_owner = owners[nearest[0], nearest[1]]
    for label in range(1, count+1):
        if label in ids: continue
        fragment = labels == label
        owner = int(np.bincount(near_owner[fragment]).argmax())
        owners[fragment] = owner
    parts = []
    for index, name in enumerate(NAMES):
        mask = owners == index+1
        # The first Warden sheet retained a duplicate crown on its torso.
        # Select its fully painted chest/hips below the neck; original pixels
        # remain untouched. The separate crown/head supplies the complete collar.
        if path.stem == 'guardian_0' and name == 'torso': mask[:218] = False
        ys, xs = np.nonzero(mask)
        rect = [int(xs.min()), int(ys.min()), int(xs.max()+1-xs.min()), int(ys.max()+1-ys.min())]
        polygons = []
        for contour in measure.find_contours(np.pad(mask, 1), .5, fully_connected='high', positive_orientation='low'):
            contour = measure.approximate_polygon(contour, tolerance=.65)
            points = [[round(float(p[1]-.5), 3), round(float(p[0]-.5), 3)] for p in contour]
            if len(points) > 3 and points[0] == points[-1]: points.pop()
            if len(points) < 3: continue
            area = sum(points[i][0]*points[(i+1)%len(points)][1]-points[(i+1)%len(points)][0]*points[i][1] for i in range(len(points)))*.5
            if area > 0: polygons.append(points)
        entry = {'name': name, 'region': rect, 'polygons': polygons, 'visible_pixels': int(mask.sum())}
        if path.stem in HOSTILE_JOINTS and name in NAMES[4:8]:
            entry['joints'] = HOSTILE_JOINTS[path.stem][NAMES.index(name)-4]
        if name == 'head' and path.stem in HOSTILE_JOINTS:
            entry['anchor'] = {'raider': [480,234], 'bulwark': [487,163],
                               'hexer': [495,202], 'elite': [481,173]}[path.stem]
        if name == 'head' and path.stem.startswith('guardian_'):
            # Authored face pivots, rather than the center of a long crown or
            # dangling collar, keep the jaw connected to the torso in motion.
            entry['anchor'] = {'guardian_0': [530, 215], 'guardian_1': [520, 240],
                               'guardian_2': [506, 231], 'guardian_3': [493, 173]}[path.stem]
        if name == 'cape':
            top_y, top_x = np.nonzero(mask & (np.arange(mask.shape[0])[:, None] < rect[1]+rect[3]*.08))
            entry['anchor'] = [round(float(np.median(top_x)), 3), round(float(np.median(top_y)), 3)]
        if name == 'head' and path.stem in ['vowkeeper', 'arcanist', 'ranger']:
            rgb = rgba[:, :, :3].astype(float)
            skin = mask & (rgb[:, :, 0]>155) & (rgb[:, :, 1]>105) & (rgb[:, :, 2]>80) & (rgb[:, :, 0]-rgb[:, :, 1]>9) & (rgb[:, :, 1]-rgb[:, :, 2]>5)
            skin_labels, _ = ndimage.label(skin, np.ones((3, 3)))
            sizes = np.bincount(skin_labels.ravel()); sizes[0] = 0
            cy, cx = ndimage.center_of_mass(skin_labels == sizes.argmax())
            entry['anchor'] = [round(float(cx+.5), 3), round(float(cy+.5), 3)]
        parts.append(entry)
    result = {'schema': 1, 'source': path.name, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
              'source_size': list(rgba.shape[1::-1]), 'packing': 'separate_painted_anatomical_parts',
              'alpha_threshold': 11, 'contour_tolerance_source_pixels': .65, 'parts': parts}
    path.with_suffix('.motion.json').write_text(json.dumps(result, separators=(',', ':'))+'\n')
    print(path.name, '12 parts', sum(len(p) for part in parts for p in part['polygons']), 'contour vertices')


if __name__ == '__main__':
    for path in sorted(ASSETS.glob('*.png')):
        if not sys.argv[1:] or path.stem in sys.argv[1:]: calibrate(path)
