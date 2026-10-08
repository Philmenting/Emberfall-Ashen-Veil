#!/usr/bin/env python3
"""Pack shared original native65 male clothing and fit existing Emberfall props.

The single clothing GLB contains selected Quaternius Male_Ranger cloth panels,
not seven duplicate bodies. Only the sleeve's overlapping glove ends are cut
at the original wrists and sleeve fabric sits4mm outside the original arm;
and new cut-edge vertices interpolate the original four influences. Runtime retains the verified original
Male_Peasant hands, boots and male head. Source animation rotations are retargeted
relative to the identical male rest; no bone scale, body edit or skin reweighting
is performed. Existing project weapons are clearly identified as project art.
"""
from pathlib import Path
import argparse, copy, hashlib, io, json, shutil, struct
import numpy as np
from PIL import Image
from scipy.spatial.transform import Rotation, Slerp


class Source:
    def __init__(self, path):
        self.path = Path(path)
        raw = self.path.read_bytes()
        if self.path.suffix == '.glb':
            size = struct.unpack_from('<I', raw, 12)[0]
            self.d = json.loads(raw[20:20 + size])
            self.b = raw[28 + size:]
        else:
            self.d = json.loads(raw)
            self.b = (self.path.parent / self.d['buffers'][0]['uri']).read_bytes()

    def array(self, index):
        a = self.d['accessors'][index]
        v = self.d['bufferViews'][a['bufferView']]
        dtype = {5126: '<f4', 5123: '<u2', 5125: '<u4', 5121: 'u1'}[a['componentType']]
        width = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}[a['type']]
        return np.ndarray((a['count'], width), dtype=dtype, buffer=self.b,
                          offset=v.get('byteOffset', 0) + a.get('byteOffset', 0),
                          strides=(v.get('byteStride', np.dtype(dtype).itemsize * width),
                                   np.dtype(dtype).itemsize)).copy()

    def local(self):
        matrices = []
        for node in self.d['nodes']:
            matrix = np.eye(4)
            matrix[:3, :3] = Rotation.from_quat(node.get('rotation', [0, 0, 0, 1])).as_matrix() @ np.diag(node.get('scale', [1, 1, 1]))
            matrix[:3, 3] = node.get('translation', [0, 0, 0])
            matrices.append(matrix)
        return matrices

    def global_pose(self, local):
        parents = {child: i for i, node in enumerate(self.d['nodes']) for child in node.get('children', [])}
        result = [None] * len(local)
        def get(index):
            if result[index] is None:
                result[index] = get(parents[index]) @ local[index] if index in parents else local[index]
            return result[index]
        return np.asarray([get(i) for i in range(len(local))])

    def pose(self, name, time):
        local = self.local()
        action = next(a for a in self.d['animations'] if a['name'] == name)
        for channel in action['channels']:
            sampler = action['samplers'][channel['sampler']]
            ts = self.array(sampler['input'])[:, 0]
            values = self.array(sampler['output'])
            t = float(np.clip(time, ts[0], ts[-1]))
            index = int(np.clip(np.searchsorted(ts, t) - 1, 0, len(ts) - 2))
            blend = (t - ts[index]) / (ts[index + 1] - ts[index])
            target = channel['target']['node']
            kind = channel['target']['path']
            if kind == 'rotation':
                local[target][:3, :3] = Slerp(ts[index:index + 2], Rotation.from_quat(values[index:index + 2]))([t]).as_matrix()[0]
            elif kind == 'translation':
                local[target][:3, 3] = values[index] * (1 - blend) + values[index + 1] * blend
        return local, self.global_pose(local)


class Writer:
    def __init__(self, name):
        self.blob = bytearray()
        self.d = {'asset': {'version': '2.0', 'generator': name}, 'scene': 0,
                  'scenes': [], 'nodes': [], 'meshes': [], 'materials': [],
                  'skins': [], 'accessors': [], 'bufferViews': [], 'animations': [],
                  'images': [], 'textures': []}

    def payload(self, raw):
        self.blob.extend(b'\0' * ((-len(self.blob)) % 4))
        start = len(self.blob)
        self.blob.extend(raw)
        i = len(self.d['bufferViews'])
        self.d['bufferViews'].append({'buffer': 0, 'byteOffset': start, 'byteLength': len(raw)})
        return i

    def accessor(self, array, original):
        array = np.ascontiguousarray(array)
        index = len(self.d['accessors'])
        a = {key: original[key] for key in ['componentType', 'type']}
        a.update(bufferView=self.payload(array.tobytes()), count=len(array))
        if a['type'] in ['SCALAR', 'VEC3']:
            a.update(min=array.min(0).tolist(), max=array.max(0).tolist())
        self.d['accessors'].append(a)
        return index

    def save(self, path):
        self.blob.extend(b'\0' * ((-len(self.blob)) % 4))
        self.d['buffers'] = [{'byteLength': len(self.blob)}]
        encoded = json.dumps(self.d, separators=(',', ':')).encode()
        encoded += b' ' * ((-len(encoded)) % 4)
        raw = (struct.pack('<III', 0x46546c67, 2, 28 + len(encoded) + len(self.blob)) +
               struct.pack('<II', len(encoded), 0x4e4f534a) + encoded +
               struct.pack('<II', len(self.blob), 0x004e4942) + self.blob)
        path.write_bytes(raw)
        return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def qmul(a, b):
    ax, ay, az, aw = np.moveaxis(np.asarray(a), -1, 0)
    bx, by, bz, bw = np.moveaxis(np.asarray(b), -1, 0)
    return np.stack([aw * bx + ax * bw + ay * bz - az * by,
                     aw * by - ax * bz + ay * bw + az * bx,
                     aw * bz + ax * by - ay * bx + az * bw,
                     aw * bw - ax * bx - ay * by - az * bz], axis=-1)


def fitted_prop_arrays(source, primitive):
    """Split actual indexed triangles at both grip and taper boundaries.

    Fitting vertices alone misses long shaft triangles whose endpoints lie
    outside the hand band. Interpolated source normals/UVs remain continuous;
    only the actual geometry in the declared100mm grip/taper region changes.
    """
    fields = [field for field in ['POSITION', 'NORMAL', 'TEXCOORD_0']
              if field in primitive['attributes']]
    widths = [source.array(primitive['attributes'][field]).shape[1] for field in fields]
    original = np.concatenate([source.array(primitive['attributes'][field]) for field in fields], axis=1)
    original[:, 1] += .080
    cuts = [.035 + x / .55 for x in [-.100, -.065, .065, .100]]
    rows, indices, lookup = [], [], {}

    def clip(polygon, cut, above):
        result = []
        for i, a in enumerate(polygon):
            b = polygon[(i + 1) % len(polygon)]
            inside_a = a[1] >= cut if above else a[1] <= cut
            inside_b = b[1] >= cut if above else b[1] <= cut
            if inside_a:
                result.append(a)
            if inside_a != inside_b:
                result.append(a + (b - a) * ((cut - a[1]) / (b[1] - a[1])))
        return result

    for triangle in source.array(primitive['indices']).reshape(-1, 3):
        for low, high in zip([-float('inf')] + cuts, cuts + [float('inf')]):
            polygon = [original[index].copy() for index in triangle]
            if np.isfinite(low):
                polygon = clip(polygon, low, True)
            if polygon and np.isfinite(high):
                polygon = clip(polygon, high, False)
            if len(polygon) < 3:
                continue
            mapped = []
            for value in polygon:
                point = value[:3]
                radial = np.linalg.norm(point[[0, 2]])
                amount = 1 - np.clip((abs((point[1] - .035) * .55) - .065) / .035, 0, 1)
                if radial > 1e-9:
                    scale = ((.018 / .55) / radial - 1) * amount + 1
                    point[0] *= scale
                    point[2] *= scale
                if 'NORMAL' in fields:
                    normal = value[3:6]
                    length = np.linalg.norm(normal)
                    if length > 1e-9:
                        normal /= length
                value = value.astype('<f4')
                key = value.tobytes()
                if key not in lookup:
                    lookup[key] = len(rows)
                    rows.append(value)
                mapped.append(lookup[key])
            for corner in range(1, len(mapped) - 1):
                a, b, c = [rows[index][:3] for index in [mapped[0], mapped[corner], mapped[corner + 1]]]
                if np.linalg.norm(np.cross(b - a, c - a)) > 1e-12:
                    indices.extend([mapped[0], mapped[corner], mapped[corner + 1]])
    values = np.asarray(rows, dtype='<f4')
    arrays = {}
    offset = 0
    for field, width in zip(fields, widths):
        arrays[field] = values[:, offset:offset + width]
        offset += width
    # Reconstruct lighting normals only for vertices in the actual edited
    # band. The outside100mm source normals remain byte-identical.
    if 'NORMAL' in arrays:
        accumulated = np.zeros_like(arrays['NORMAL'])
        vertices = arrays['POSITION']
        for a, b, c in np.asarray(indices).reshape(-1, 3):
            normal = np.cross(vertices[b] - vertices[a], vertices[c] - vertices[a])
            if normal @ (arrays['NORMAL'][a] + arrays['NORMAL'][b] + arrays['NORMAL'][c]) < 0:
                normal *= -1
            accumulated[[a, b, c]] += normal
        length = np.linalg.norm(accumulated, axis=1)
        selected = (np.abs((vertices[:, 1] - .035) * .55) < .100001) & (length > 1e-12)
        arrays['NORMAL'][selected] = accumulated[selected] / length[selected, None]
    return arrays, np.asarray(indices, dtype='<u4').reshape(-1, 1)


def wrist_clipped_sleeves(source, primitive):
    """Remove Ranger gloves that would overlap independently verified hands.

    The wrist plane lies10mm toward the elbow from the original hand rest.
    Original bare forearms already extend underneath the cuff. Sleeve fabric
    needs4mm of separation because the manufacturer's cloth and bare forearm
    positions are coplanar. No original body vertex, bone or bind changes.
    Only new sleeve-boundary vertices need skin/UV interpolation; retained
    sleeve normals, UVs and weights remain byte-identical.
    """
    fields = {name: source.array(ai) for name, ai in primitive['attributes'].items()}
    fields = {name: values for name, values in fields.items()
              if not name.startswith('COLOR_') and (not name.startswith('TEXCOORD_') or name == 'TEXCOORD_0')}
    fields['POSITION'] += fields['NORMAL'] * .004
    rests = source.global_pose(source.local())
    hand = next(i for i, node in enumerate(source.d['nodes']) if node.get('name') == 'hand_l')
    wrist = float(rests[hand, 0, 3]) - .010
    rows, indices, lookup = [], [], {}
    source_triangles = source.array(primitive['indices']).reshape(-1, 3)
    clipped_triangles, discarded_triangles = 0, 0

    def interpolate(a, b, phase):
        point = {name: a[name] + (b[name] - a[name]) * phase
                 for name in fields if name not in ['JOINTS_0', 'WEIGHTS_0']}
        if 'NORMAL' in point:
            point['NORMAL'] /= np.linalg.norm(point['NORMAL'])
        influences = {}
        for value, gain in [(a, 1 - phase), (b, phase)]:
            for joint, weight in zip(value['JOINTS_0'], value['WEIGHTS_0']):
                influences[int(joint)] = influences.get(int(joint), 0.) + float(weight) * gain
        ordered = sorted(influences, key=lambda joint: (-influences[joint], joint))[:4]
        total = sum(influences[joint] for joint in ordered)
        point['JOINTS_0'] = np.asarray(ordered + [0] * (4 - len(ordered)), dtype=fields['JOINTS_0'].dtype)
        point['WEIGHTS_0'] = np.asarray([influences[joint] / total for joint in ordered] + [0.] * (4 - len(ordered)), dtype=fields['WEIGHTS_0'].dtype)
        return point

    for triangle in source_triangles:
        polygon = [{name: values[index].copy() for name, values in fields.items()} for index in triangle]
        # Source left/right sleeves are separate connected components; this
        # sign selects the matching anatomical wrist without spanning space.
        sign = 1. if polygon[0]['POSITION'][0] > 0 else -1.
        result = []
        for index, a in enumerate(polygon):
            b = polygon[(index + 1) % len(polygon)]
            distance_a = sign * float(a['POSITION'][0]) - wrist
            distance_b = sign * float(b['POSITION'][0]) - wrist
            inside_a, inside_b = distance_a <= 0, distance_b <= 0
            if inside_a:
                result.append(a)
            if inside_a != inside_b:
                result.append(interpolate(a, b, distance_a / (distance_a - distance_b)))
        if len(result) < 3:
            discarded_triangles += 1
            continue
        if any(sign * float(value['POSITION'][0]) > wrist for value in polygon):
            clipped_triangles += 1
        mapped = []
        for value in result:
            value = {name: np.asarray(value[name], dtype=fields[name].dtype) for name in fields}
            key = b''.join(value[name].tobytes() for name in fields)
            if key not in lookup:
                lookup[key] = len(rows)
                rows.append(value)
            mapped.append(lookup[key])
        for corner in range(1, len(mapped) - 1):
            a, b, c = [rows[index]['POSITION'] for index in [mapped[0], mapped[corner], mapped[corner + 1]]]
            if np.linalg.norm(np.cross(b - a, c - a)) > 1e-12:
                indices.extend([mapped[0], mapped[corner], mapped[corner + 1]])
    arrays = {name: np.asarray([value[name] for value in rows], dtype=fields[name].dtype) for name in fields}
    return arrays, np.asarray(indices, dtype='<u4').reshape(-1, 1), {
        'wrist_cuff_original_rest_x_m': wrist,
        'source_triangles': len(source_triangles),
        'discarded_overlapping_glove_triangles': discarded_triangles,
        'clipped_boundary_source_triangles': clipped_triangles,
        'retained_source_normals_uvs_skin_weights_unchanged': True,
        'source_sleeve_position_normal_outset_m': .004,
        'cut_edge_attributes_interpolated_from_original': True,
        'original_body_hands_and_binds_unchanged': True,
    }


def death_grounding(body, clothing, grip):
    """Dense actual original skin and fitted panel floor tables.

    The generated forearm shield drops rigidly and settles independently at
    runtime; anchoring body floor to its extended rim would levitate the body.
    """
    roles = ['hexer', 'bulwark', 'elite', 'guardian_0', 'guardian_1', 'guardian_2', 'guardian_3']
    lookup = {n.get('name'): i for i, n in enumerate(body.d['nodes'])}
    rest = body.global_pose(body.local())
    records = {}

    def record(source, node, p, offset=0, selected=None):
        triangles = source.array(p['indices']).reshape(-1, 3)
        if selected is not None:
            triangles = triangles[selected]
        used = np.unique(triangles)
        positions = source.array(p['attributes']['POSITION'])[used].astype(float)
        if offset:
            positions += source.array(p['attributes']['NORMAL'])[used] * offset
        skin = source.d['skins'][node['skin']]
        inverse = source.array(skin['inverseBindMatrices']).reshape(-1, 4, 4).transpose(0, 2, 1)
        ids = source.array(p['attributes']['JOINTS_0'])[used]
        weights = source.array(p['attributes']['WEIGHTS_0'])[used]
        points = np.c_[positions, np.ones(len(positions))]
        bind_points = np.asarray([np.einsum('nij,nj->ni', inverse[ids[:, k]], points) for k in range(4)])
        return (np.asarray(skin['joints'])[ids], weights, bind_points)

    common = []
    for node in body.d['nodes']:
        name = node.get('name', '')
        if 'mesh' not in node or name in ['Male_Peasant_Body', 'Male_Peasant_Legs']:
            continue
        for p in body.d['meshes'][node['mesh']]['primitives']:
            if name == 'Male_Peasant_Arms' and body.d['materials'][p['material']]['name'] != 'MI_Regular_Male':
                continue
            common.append(record(body, node, p))

    def bracer_main(source, p):
        # Same welded connected-component selection as the runtime shell.
        vertices = source.array(p['attributes']['POSITION'])
        triangles = source.array(p['indices']).reshape(-1, 3)
        parent, welded, mapped = [], {}, []
        for point in vertices:
            key = tuple(np.floor(point * 100000 + .5).astype(int))
            if key not in welded:
                welded[key] = len(parent)
                parent.append(len(parent))
            mapped.append(welded[key])
        def root(index):
            while parent[index] != index:
                index = parent[index]
            return index
        for a, b, c in triangles:
            r = root(mapped[a])
            parent[root(mapped[b])] = r
            parent[root(mapped[c])] = r
        counts = {}
        for a, _, _ in triangles:
            r = root(mapped[a])
            counts[r] = counts.get(r, 0) + 1
        return np.asarray([counts[root(mapped[a])] >= 400 for a, _, _ in triangles])

    # Reconstruct the exact64-vertex male fitted breastplate used by runtime.
    node = next(n for n in clothing.d['nodes'] if n.get('name') == 'Male_Ranger_Body')
    p = clothing.d['meshes'][node['mesh']]['primitives'][0]
    source_points = clothing.array(p['attributes']['POSITION'])
    source_triangles = clothing.array(p['indices']).reshape(-1, 3)
    source_ids = clothing.array(p['attributes']['JOINTS_0'])
    source_weights = clothing.array(p['attributes']['WEIGHTS_0'])
    plate_points, plate_ids, plate_weights = [], [], []
    for row in range(8):
        y = 1.145 + (1.425 - 1.145) * row / 7
        width = .095 + (.110 - .095) * np.sin(row / 7 * np.pi)
        for column in range(8):
            x = -width + 2 * width * column / 7
            selected = None
            for triangle in source_triangles:
                points = source_points[triangle]
                if points[:, 2].max() < .035:
                    continue
                matrix = np.r_[points[:, :2].T, np.ones((1, 3))]
                if abs(np.linalg.det(matrix)) < 1e-10:
                    continue
                bary = np.linalg.solve(matrix, [x, y, 1])
                if bary.min() < -.00001:
                    continue
                z = points[:, 2] @ bary
                if z < .035 or (selected is not None and z <= selected[0]):
                    continue
                influences = {}
                for corner, vertex in enumerate(triangle):
                    for bone, weight in zip(source_ids[vertex], source_weights[vertex]):
                        influences[int(bone)] = influences.get(int(bone), 0.) + weight * bary[corner]
                selected = (z, influences)
            assert selected is not None, ('male breastplate vertex must fit actual source torso', x, y)
            ordered = sorted(selected[1], key=lambda bone: selected[1][bone], reverse=True)[:4]
            total = sum(selected[1][bone] for bone in ordered)
            plate_points.append([x, y, selected[0] + .046, 1])
            plate_ids.append(ordered + [0] * (4 - len(ordered)))
            plate_weights.append([selected[1][bone] / total for bone in ordered] + [0.] * (4 - len(ordered)))
    skin = clothing.d['skins'][0]
    inverse = clothing.array(skin['inverseBindMatrices']).reshape(-1, 4, 4).transpose(0, 2, 1)
    ids, weights, points = np.asarray(plate_ids), np.asarray(plate_weights), np.asarray(plate_points)
    plate = (np.asarray(skin['joints'])[ids], weights,
             np.asarray([np.einsum('nij,nj->ni', inverse[ids[:, k]], points) for k in range(4)]))

    for role in roles:
        actual = common.copy()
        for node in clothing.d['nodes']:
            name = node.get('name', '')
            if 'mesh' not in node:
                continue
            if 'Head_Hood' in name and role in ['bulwark', 'elite', 'guardian_0', 'guardian_3']:
                continue
            if 'Pauldron' in name and role == 'hexer':
                continue
            if 'Bracer' in name and role in ['hexer', 'guardian_1', 'guardian_2']:
                continue
            for p in clothing.d['meshes'][node['mesh']]['primitives']:
                armor = ('Pauldron' in name or 'Bracer' in name) and role != 'hexer'
                selected = bracer_main(clothing, p) if armor and 'Bracer' in name else None
                actual.append(record(clothing, node, p, .010 if armor else 0, selected))
        if role in ['bulwark', 'elite', 'guardian_0', 'guardian_3']:
            actual.append(plate)
        records[role] = actual
    length = max(body.array(sa['input'])[-1, 0] for action in body.d['animations']
                 if action['name'] == 'Death01' for sa in action['samplers'])
    profiles = {role: [] for role in roles}
    for frame in range(181):
        local, _ = body.pose('Death01', frame / 180 * length)
        for name, q in grip['bone_local_quaternions_xyzw'].items():
            local[lookup[name]][:3, :3] = Rotation.from_quat(q).as_matrix()
        matrices = body.global_pose(local)
        for role, actual in records.items():
            minimum = float('inf')
            for ids, weights, bind_points in actual:
                points = np.zeros((len(weights), 4))
                for k in range(4):
                    points += np.einsum('nij,nj->ni', matrices[ids[:, k]], bind_points[k]) * weights[:, k, None]
                minimum = min(minimum, float(points[:, 1].min()))
            profiles[role].append(max(.009, .003 - minimum))
    return {'source_clip': 'Death01', 'normalized_samples': 181,
            'actual_indexed_weighted_original_clothing_and_armor_floor': True,
            'runtime_finger_pose_preserved': True, 'roles': profiles,
            'scope': 'Original male body/head/hands/boots and actual role clothing,10mm authored armor-panel shells,64-vertex fitted male breastplate. Held prop and independently dropping26-vertex native forearm shield settle separately at runtime.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-root', type=Path, required=True)
    parser.add_argument('--animation1', type=Path, required=True)
    parser.add_argument('--animation2', type=Path, required=True)
    parser.add_argument('--output-dir', type=Path, default=Path('assets/models/hostiles057'))
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    sources = {}

    def remember(path):
        sources[str(path)] = hashlib.sha256(path.read_bytes()).hexdigest()

    source = Source(next(args.source_root.glob('**/Outfits/Male_Ranger.gltf')))
    peasant = Source(next(args.source_root.glob('**/Outfits/Male_Peasant.gltf')))
    for i in range(65):
        assert source.d['nodes'][i] == peasant.d['nodes'][i], ('native hierarchy/rest', i)
    assert source.d['skins'][0]['joints'] == peasant.d['skins'][0]['joints']
    w = Writer('Emberfall 057: original Quaternius Male_Ranger cloth panels; glove ends cut at wrists to expose verified original hands; native65 rest-relative spell/sword clips')
    w.d['nodes'] = copy.deepcopy(source.d['nodes'][:65])
    parent = {child: i for i, n in enumerate(source.d['nodes']) for child in n.get('children', [])}
    container = 65
    w.d['nodes'].append({'name': 'Hostile057_Original_Male_Clothing',
                         'children': [i for i in range(65) if parent.get(i) not in range(65)]})
    w.d['scenes'] = [{'nodes': [container]}]
    skin = copy.deepcopy(source.d['skins'][0])
    skin['inverseBindMatrices'] = w.accessor(source.array(skin['inverseBindMatrices']),
                                            source.d['accessors'][skin['inverseBindMatrices']])
    skin.pop('skeleton', None)
    w.d['skins'].append(skin)
    material = copy.deepcopy(next(m for m in source.d['materials'] if m['name'] == 'MI_Ranger'))
    material['doubleSided'] = False

    def copy_textures(value):
        if isinstance(value, dict):
            for key, data in value.items():
                if key.endswith('Texture') and isinstance(data, dict):
                    texture = source.d['textures'][data['index']]
                    image = source.d['images'][texture['source']]
                    path = source.path.parent / image['uri']
                    remember(path)
                    im = Image.open(path)
                    im.thumbnail((512, 512), Image.Resampling.LANCZOS)
                    output = io.BytesIO()
                    im.save(output, format='PNG', optimize=False)
                    view = w.payload(output.getvalue())
                    data['index'] = len(w.d['textures'])
                    w.d['textures'].append({'source': len(w.d['images'])})
                    w.d['images'].append({'name': image.get('name', path.stem),
                                           'bufferView': view, 'mimeType': 'image/png'})
                else:
                    copy_textures(data)
        elif isinstance(value, list):
            for data in value:
                copy_textures(data)

    copy_textures(material)
    w.d['materials'].append(material)
    wanted = {'Male_Ranger_Acc_Pauldron', 'Male_Ranger_Arms', 'Male_Ranger_Arms_Bracer',
              'Male_Ranger_Body', 'Male_Ranger_Body_Belt_1', 'Male_Ranger_Head_Hood', 'Male_Ranger_Legs'}
    parts = []
    for n in source.d['nodes']:
        if n.get('name') not in wanted:
            continue
        mesh = {'name': n['name'], 'primitives': []}
        for p in source.d['meshes'][n['mesh']]['primitives']:
            if source.d['materials'][p['material']]['name'] != 'MI_Ranger':
                continue  # Runtime preserves the independently verified original Peasant hands.
            sleeve_clip = None
            if n['name'] == 'Male_Ranger_Arms':
                attributes, indices, sleeve_clip = wrist_clipped_sleeves(source, p)
            else:
                attributes = {field: source.array(ai) for field, ai in p['attributes'].items()}
                indices = source.array(p['indices'])
            used = np.unique(indices)
            remap = np.zeros(len(attributes['POSITION']), dtype='<u4')
            remap[used] = np.arange(len(used), dtype='<u4')
            new = {'material': 0, 'attributes': {},
                   'indices': w.accessor(remap[indices], {'componentType': 5125, 'type': 'SCALAR'})}
            for field, ai in p['attributes'].items():
                if field.startswith('COLOR_') or (field.startswith('TEXCOORD_') and field != 'TEXCOORD_0'):
                    continue
                new['attributes'][field] = w.accessor(attributes[field][used], source.d['accessors'][ai])
            weights = attributes['WEIGHTS_0'][used]
            assert np.max(np.abs(weights.sum(1) - 1)) < 1e-5
            mesh['primitives'].append(new)
            parts.append({'name': n['name'], 'triangles': len(indices) // 3,
                          'used_vertices': len(used), 'geometry_normals_uv_weights_unchanged': sleeve_clip is None,
                          **({'wrist_glove_clip': sleeve_clip} if sleeve_clip else {})})
        if not mesh['primitives']:
            continue
        node = {k: copy.deepcopy(v) for k, v in n.items() if k not in ['mesh', 'children']}
        node['mesh'] = len(w.d['meshes'])
        w.d['meshes'].append(mesh)
        w.d['nodes'][container]['children'].append(len(w.d['nodes']))
        w.d['nodes'].append(node)
    lookup = {n['name']: i for i, n in enumerate(w.d['nodes'][:65])}
    selected = [{'Spell_Simple_Enter', 'Spell_Simple_Idle_Loop', 'Spell_Simple_Shoot'},
                {'Sword_Regular_C', 'Sword_Block'}]
    for filename, actions in zip([args.animation1, args.animation2], selected):
        animation = Source(filename)
        remember(filename)
        for action in animation.d['animations']:
            if action['name'] not in actions:
                continue
            new = {'name': action['name'], 'channels': [], 'samplers': []}
            for ch in action['channels']:
                node = animation.d['nodes'][ch['target']['node']]
                name = node.get('name')
                kind = ch['target']['path']
                if name not in lookup or kind == 'scale':
                    continue
                target = lookup[name]
                sa = action['samplers'][ch['sampler']]
                assert sa.get('interpolation', 'LINEAR') == 'LINEAR'
                times = animation.array(sa['input'])
                values = animation.array(sa['output']).astype('<f4')
                rest = w.d['nodes'][target]
                if kind == 'rotation':
                    qr = np.asarray(node.get('rotation', [0, 0, 0, 1]))
                    qt = np.asarray(rest.get('rotation', [0, 0, 0, 1]))
                    values = qmul(qt, qmul(qr * [-1, -1, -1, 1], values))
                    values = (values / np.linalg.norm(values, axis=1)[:, None]).astype('<f4')
                elif kind == 'translation':
                    delta = values - np.asarray(node.get('translation', [0, 0, 0]))
                    if name != 'pelvis':
                        delta[:] = 0
                    values = (np.asarray(rest.get('translation', [0, 0, 0])) + delta).astype('<f4')
                else:
                    continue
                new['channels'].append({'sampler': len(new['samplers']),
                                         'target': {'node': target, 'path': kind}})
                new['samplers'].append({'input': w.accessor(times, {'componentType': 5126, 'type': 'SCALAR'}),
                                         'output': w.accessor(values, {'componentType': 5126,
                                                                     'type': 'VEC4' if kind == 'rotation' else 'VEC3'}),
                                         'interpolation': 'LINEAR'})
            w.d['animations'].append(new)
    outfit_report = w.save(args.output_dir / 'male-clothing-native65.glb')
    for p in [source.path, source.path.parent / source.d['buffers'][0]['uri'], peasant.path]:
        remember(p)
    raider_path = Path('assets/models/raider056/raider-native65.glb')
    grip_path = Path('assets/models/raider056/axe-grip.json')
    remember(raider_path)
    remember(grip_path)
    grounding = death_grounding(Source(raider_path), Source(args.output_dir / 'male-clothing-native65.glb'),
                                json.loads(grip_path.read_text()))
    (args.output_dir / 'death-grounding.json').write_text(json.dumps(grounding, indent=2) + '\n')
    weapons = {}
    for key in ['hexer', 'bulwark', 'elite', 'guardian_0', 'guardian_1', 'guardian_2', 'guardian_3']:
        filename = Path('assets/models') / (key + '.glb')
        source_weapon = Source(filename)
        remember(filename)
        prop = Writer('Emberfall 057: existing project role weapon; fitted rigid18mm male-hand grip; source body excluded')
        prop.d['materials'] = copy.deepcopy(source_weapon.d['materials'])
        prop.d['nodes'] = [{'name': 'Hostile057_Fitted_Role_Prop', 'children': []}]
        prop.d['scenes'] = [{'nodes': [0]}]
        triangles = 0
        for n in source_weapon.d['nodes']:
            if not n.get('name', '').startswith('Weapon__'):
                continue
            mesh = {'name': n['name'], 'primitives': []}
            for p in source_weapon.d['meshes'][n['mesh']]['primitives']:
                fitted, indices = fitted_prop_arrays(source_weapon, p)
                new = {'material': p['material'], 'attributes': {},
                       'indices': prop.accessor(indices, {'componentType': 5125, 'type': 'SCALAR'})}
                for field, values in fitted.items():
                    ai = p['attributes'][field]
                    new['attributes'][field] = prop.accessor(values, source_weapon.d['accessors'][ai])
                mesh['primitives'].append(new)
                triangles += len(indices) // 3
            node = {k: copy.deepcopy(v) for k, v in n.items() if k not in ['mesh', 'skin', 'children']}
            node['mesh'] = len(prop.d['meshes'])
            prop.d['meshes'].append(mesh)
            prop.d['nodes'][0]['children'].append(len(prop.d['nodes']))
            prop.d['nodes'].append(node)
        report = prop.save(args.output_dir / (key + '-fitted.glb'))
        report.update(triangles=triangles, original_project_model=str(filename),
                      original_project_model_sha256=sources[str(filename)],
                      runtime_uniform_scale=.55, grip_source_point=[0, .035, 0],
                      runtime_grip_circumradius_m=.018, runtime_fit_halfspan_m=.065,
                      runtime_taper_halfspan_m=.100,
                      provenance='Existing Emberfall project-generated role prop; not a newly sourced Quaternius weapon')
        weapons[key] = report
    for source_name, destination in [('OUTFIT-LICENSE.txt', 'OUTFIT-LICENSE.txt'),
                                     ('BASE-LICENSE.txt', 'BASE-LICENSE.txt'),
                                     ('ANIMATION1-LICENSE.txt', 'ANIMATION1-LICENSE.txt'),
                                     ('ANIMATION2-LICENSE.txt', 'ANIMATION2-LICENSE.txt')]:
        path = Path('assets/models/raider056') / source_name
        remember(path)
        shutil.copyfile(path, args.output_dir / destination)
    report = {'outfit': outfit_report, 'native_bones': 65,
              'original_rest_identical_to_raider056': True, 'cloth_parts': parts,
              'cloth_triangles': sum(p['triangles'] for p in parts),
              'outfit_texture_limit': 512, 'weapons': weapons,
              'source_files': sources, 'animations': [a['name'] for a in w.d['animations']],
              'scope': 'One shared original cloth asset; existing verified original male head/hands/boots shared at runtime. Cloth replaces Peasant cloth, not an overlapping second tunic. Ranger glove ends cut10mm before original wrist to expose verified hands; sleeve positions move4mm along original normals to clear coplanar bare forearms. Retained sleeve normals, UVs and skin weights preserve source attributes and new cuff-edge attributes interpolate originals. All other cloth geometry, body anatomy, native rest and binds remain unchanged. Project prop grip fitted separately.'}
    (args.output_dir / 'manifest.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'outfit': outfit_report, 'cloth_triangles': report['cloth_triangles'],
                      'weapons': {k: {'bytes': v['bytes'], 'triangles': v['triangles']} for k, v in weapons.items()}}, indent=2))


if __name__ == '__main__':
    main()
