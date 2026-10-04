# Original character geometry, 0.47

The eleven character GLBs are original numerical mesh constructions generated
with Blender 4.3.2 by `build_characters.py` and `build_body_047.py`. No downloaded
body, scanned surface, mannequin, image-generated mesh or third-party geometry
was used for this rebuild. The existing original Nyra head and hair generator,
`build_faces.py`, and its calibrated face albedo are unchanged.

Rebuild from the repository root:

```sh
/usr/bin/blender -b -t 2 --python tools/art/build_characters.py
```

The source modules author anatomical sections, relief and garment cuts in the
existing Y-up part spaces. The output GLBs contain static source parts; the game
binds them to its existing 29-bone native skeleton and nine animation clips.
This geometry rebuild supplies no animation data. Animation provenance is
documented separately in `assets/animations/SOURCE.md`.

## Construction

The body generator now gives arms a continuous deltoid–elbow–wrist profile,
hands a tapered palm with curled fingers around the existing grip, and boots a
lengthwise toe–ball–instep–heel construction. Open greaves and vambraces follow
the limbs; smaller knee flanges replace the detached round joint masses.
The cuirass has a shaped backplate visible from the normal rear game camera.

Vowkeeper uses a short split surcoat and two fitted shoulder layers. Arcanist
uses separate long side gores, a narrower back drape and a short cape. Ranger
uses a short asymmetrical cape and an open short tunic. Capes are narrower than
the reviewed 0.46 models, allowing the motion rig to place hands beyond them.
The raider thorax is a continuous skin surface with embedded rib, sternum and
clavicle relief. Exposed skulls now share a continuous cranium and jaw with
orbital, brow, cheek and nose planes. Guardian emblems and silhouettes remain.

Metal, leather, cloth and worn bone have distinct physical pigment and roughness
values. The suffix materials `.cape`, `.sleeve` and `.sole` use the existing
material categories: the runtime already strips everything after the first dot.
They require no new vertex attributes, bone weights or shader uniforms. The
surface shader reduces atlas modulation over the quiet main planes; it does
not increase emission. The calibrated face branch is retained.

## Export evidence

Triangle counts are read from the emitted GLB index accessors, not source mesh
estimates. The baseline is commit `2d89d5b`; every output remains below 40,000.

| Asset in `assets/models` | 0.46 triangles | 0.47 triangles |
| --- | ---: | ---: |
| `vowkeeper.glb` | 39,172 | 36,378 |
| `arcanist.glb` | 39,184 | 36,376 |
| `ranger.glb` | 39,182 | 36,380 |
| `guardian_0.glb` | 38,084 | 34,428 |
| `guardian_1.glb` | 39,184 | 36,381 |
| `guardian_2.glb` | 39,178 | 36,379 |
| `guardian_3.glb` | 29,100 | 25,856 |
| `raider.glb` | 20,380 | 20,343 |
| `hexer.glb` | 37,408 | 35,903 |
| `bulwark.glb` | 25,968 | 25,140 |
| `elite.glb` | 24,488 | 23,660 |

All source node pivots remain zero and each model retains its existing runtime
part namespace. All eleven maximum body heights match the baseline. Sole
contact planes remain within 0.3 mm of the established position. `NAMES`,
`PARENTS`, `REST`, `_part_origin` and `_weights` in `character_rig.gd` are unchanged
from the baseline. The POSITION and NORMAL arrays for all three heroes' skin,
lips, lip shadows, eyes, irises, hair, hair shadows, dark facial detail and both
hair sections compare byte-for-byte equal to the baseline.

An isolated Godot 4.7.2 `GLTFDocument` load passed for all eleven outputs, and the
surface shader parsed with its existing 25 uniforms. An isolated material probe
confirmed the albedo chain: GLTF linear factor → Godot sRGB material property →
runtime `srgb_to_linear()` returns the original linear factor. For example,
`wine` becomes `(0.1912, 0.0561, 0.0742)` in the rig, `wine.sleeve` becomes
`(0.2447, 0.0718, 0.0950)`, and `wine.cape` becomes `(0.1090, 0.0320, 0.0423)`.

Source comparisons establish geometry and identity, not posed gameplay quality.
The meshes remain deliberately stylized procedural constructions; skull and
hostile anatomy are simplified, and this batch adds no texture sculpt or custom
normal bake. Native lighting, attack occlusion and deformation are checked in
the shared game capture pass.
