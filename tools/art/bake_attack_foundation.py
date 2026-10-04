#!/usr/bin/env python3
"""Bake the freely distributed CC0 Quaternius sword curves onto Emberfall's body.

Offline only; requires numpy. Pass the two official Standard GLBs. The output
contains no second rig or mesh. Animation timing, support steps and shield guard
are authored in character_animation.gd; this preserves the source's torso,
elbow, wrist and blade paths instead of approximating them with pose gains.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct

import numpy as np


def rotation(q):
    x, y, z, w = np.asarray(q) / np.linalg.norm(q)
    return np.array([[1-2*(y*y+z*z), 2*(x*y-z*w), 2*(x*z+y*w)],
                     [2*(x*y+z*w), 1-2*(x*x+z*z), 2*(y*z-x*w)],
                     [2*(x*z-y*w), 2*(y*z+x*w), 1-2*(x*x+y*y)]])


def quaternion(m):
    # Polar decomposition removes tiny exporter scale errors first.
    u, _, v = np.linalg.svd(m)
    m = u @ v
    w = np.sqrt(max(0, 1 + np.trace(m))) / 2
    if w > 1e-5:
        q = np.array([m[2, 1]-m[1, 2], m[0, 2]-m[2, 0], m[1, 0]-m[0, 1], 4*w*w])/(4*w)
    else:
        k = np.argmax(np.diag(m)); j = (k+1) % 3; l = (k+2) % 3
        q = np.zeros(4); q[k] = np.sqrt(max(0, 1+m[k, k]-m[j, j]-m[l, l])) / 2
        q[j] = (m[j, k]+m[k, j])/(4*q[k]); q[l] = (m[l, k]+m[k, l])/(4*q[k])
        q[3] = (m[l, j]-m[j, l])/(4*q[k])
    return q / np.linalg.norm(q)


def slerp(a, b, amount):
    a = a / np.linalg.norm(a); b = b / np.linalg.norm(b)
    dot = np.dot(a, b)
    if dot < 0: b = -b; dot = -dot
    if dot > .9995:
        q = a+(b-a)*amount
        return q / np.linalg.norm(q)
    angle = np.arccos(np.clip(dot, -1, 1))
    return (a*np.sin((1-amount)*angle)+b*np.sin(amount*angle))/np.sin(angle)


class Source:
    def __init__(self, path):
        self.raw = Path(path).read_bytes()
        size, _ = struct.unpack_from('<II', self.raw, 12)
        self.g = json.loads(self.raw[20:20+size])
        length, _ = struct.unpack_from('<II', self.raw, 20+size)
        self.binary = self.raw[28+size:28+size+length]
        self.nodes = self.g['nodes']; self.names = {n.get('name'): i for i, n in enumerate(self.nodes)}
        self.parents = {c: i for i, n in enumerate(self.nodes) for c in n.get('children', [])}
        self.animations = {a['name']: a for a in self.g['animations']}; self.cache = {}
        self.rest = self.pose()

    def values(self, index):
        if index not in self.cache:
            a = self.g['accessors'][index]; view = self.g['bufferViews'][a['bufferView']]
            assert a['componentType'] == 5126
            width = {'SCALAR': 1, 'VEC3': 3, 'VEC4': 4}[a['type']]
            self.cache[index] = np.ndarray((a['count'], width), dtype='<f4', buffer=self.binary,
                offset=view.get('byteOffset', 0)+a.get('byteOffset', 0),
                strides=(view.get('byteStride', width*4), 4)).copy()
        return self.cache[index]

    def length(self, name):
        return max(float(self.values(s['input'])[-1, 0]) for s in self.animations[name]['samplers'])

    def pose(self, name=None, time=0):
        local = [{'translation': np.array(n.get('translation', [0, 0, 0]), float),
                  'rotation': np.array(n.get('rotation', [0, 0, 0, 1]), float),
                  'scale': np.array(n.get('scale', [1, 1, 1]), float)} for n in self.nodes]
        if name:
            a = self.animations[name]
            for channel in a['channels']:
                sampler = a['samplers'][channel['sampler']]
                assert sampler.get('interpolation', 'LINEAR') == 'LINEAR'
                times = self.values(sampler['input'])[:, 0]; values = self.values(sampler['output'])
                i = int(np.clip(np.searchsorted(times, time, side='right')-1, 0, len(times)-2))
                weight = float(np.clip((time-times[i])/(times[i+1]-times[i]), 0, 1))
                path = channel['target']['path']
                local[channel['target']['node']][path] = slerp(values[i], values[i+1], weight) if path == 'rotation' else values[i]*(1-weight)+values[i+1]*weight
        result = [None]*len(local)
        def global_pose(i):
            if result[i] is None:
                d = local[i]; m = np.eye(4); m[:3, :3] = rotation(d['rotation']) @ np.diag(d['scale']); m[:3, 3] = d['translation']
                result[i] = global_pose(self.parents[i]) @ m if i in self.parents else m
            return result[i]
        return np.stack([global_pose(i) for i in range(len(local))])

    def bake(self, name):
        facing = np.diag([-1., 1., -1.])  # source +Z to the real native -Z target
        hip_scale = 1.053 / .916700005531311
        arm_scale = (.31+.28)*1.14 / (.2744402587413788+.27264055609703064)
        socket = np.array([[1., 0., 0.], [0., 0., -1.], [0., 1., 0.]])
        rows = []
        for frame in range(round(self.length(name)*30)+1):
            time = min(frame/30, self.length(name)); p = self.pose(name, time)
            def matrix(bone): return p[self.names[bone]]
            def delta(bone):
                return facing @ matrix(bone)[:3, :3] @ np.linalg.inv(self.rest[self.names[bone]][:3, :3]) @ facing
            pelvis_rotation = delta('pelvis'); chest_global = delta('spine_03')
            pelvis = facing @ matrix('pelvis')[:3, 3] * hip_scale
            chest_position = pelvis + pelvis_rotation @ np.array([0, .39, 0])
            row = [time, *(pelvis-np.array([0, 1.053, 0])), *quaternion(pelvis_rotation), *quaternion(pelvis_rotation.T @ chest_global)]
            for side, sign in [('r', 1), ('l', -1)]:
                shoulder = chest_position + chest_global @ np.array([sign*.32, .19, 0])
                source_shoulder = matrix('upperarm_'+side)[:3, 3]
                row.extend(shoulder + facing @ (matrix('hand_'+side)[:3, 3]-source_shoulder)*arm_scale)
                row.extend(facing @ (matrix('lowerarm_'+side)[:3, 3]-source_shoulder)*arm_scale)
            row.extend(quaternion(facing @ matrix('hand_r')[:3, :3] @ socket))
            rows.append([round(float(value), 7) for value in row])
        return rows


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--ual1', required=True); parser.add_argument('--ual2', required=True)
    parser.add_argument('--output', default='assets/animations/vowkeeper_sword_foundation.gd')
    args = parser.parse_args(); first = Source(args.ual1); second = Source(args.ual2)
    curves = {'cut': first.bake('Sword_Attack'), 'diagonal': second.bake('Sword_Regular_B'), 'diagonal_return': second.bake('Sword_Regular_B_Rec')}
    header = ('extends RefCounted\n## Generated by tools/art/bake_attack_foundation.py; CC0 Quaternius source.\n'
              '## Rows: time, hip[3], pelvis quaternion[4], chest quaternion[4],\n'
              '## right hand[3], right elbow pole[3], left hand[3], left elbow pole[3], weapon quaternion[4].\n'
              '## Target rest/lengths are the existing adult 29-bone rig. See SOURCE.md.\n')
    lines = [header, 'const CURVES: Dictionary={\n']
    for name, rows in curves.items():
        lines.append('\t"'+name+'": [\n')
        lines.extend('\t\t'+json.dumps(row, separators=(',', ':'))+',\n' for row in rows)
        lines.append('\t],\n')
    lines.append('}\n'); Path(args.output).write_text(''.join(lines))
    print(json.dumps({'curves': {k: len(v) for k, v in curves.items()},
                      'source_sha256': [hashlib.sha256(s.raw).hexdigest() for s in (first, second)],
                      'output': args.output}, indent=2))


if __name__ == '__main__':
    main()
