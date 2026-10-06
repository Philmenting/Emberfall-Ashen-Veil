# Whole-body support and contact · 0.49

The existing 0.48 cast and bow bodyphrases are retained. Their depth is already
substantial; increasing it again would not address the covered knees and
small, low-contrast rear silhouette identified in the
[0.48 review](../../../docs/design/graphics-review-048.md). This pass corrects
the free boot's landing time so the body's existing load can actually support
that contact. It does not claim the combined visual finish is accepted.

Work was performed by an ordinary-agent fallback for the Impeccable asset
producer. Cast and bow remain project-authored native poses. No external
animation or motion-capture source was added. The Vowkeeper's separately
[documented foundation](../SOURCE.md), phrase and floor correction are unchanged.

## Diagnosis at ordinary scale

Original 0.48 bare frames 128/136/148, 248/256/268 and the dense basic sequences
164–173 and 282–291 were inspected, followed by ordinary guardian frames
392/396 and 649/651. The cast and draw change the body, but the old garment
covers the knees and bright fallen bodies overlap the first-fight support.
The guardian body is still small beside the complete warning footprint.
These observations agree with the review; the slow gallery is not acceptance.

A read-only Godot 4.7.2 trace then replayed the real ordinary simulation and
camera: 720 ordinary frames plus 360 effects-hidden first-fight frames. It
recorded actual release events, bone positions, palms, foot targets, target
error, camera transforms and projection. The frozen source was commit
`6890b7e636c3e7964bfb1bc226db6c562f5b2404`; its animation hash matches the
reviewed 0.48 runtime. No renderer, native capture or frame-time measurement
was used for these logical traces.

| Existing body effort, guard → load | Arcanist | Ranger |
| --- | --- | --- |
| Pelvis height in rig metres, first fight | 0.969 → 0.728 | 0.969 → 0.768 |
| Rear knee geometric bend | 40.5° → 100.3° | 43.7° → 92.6° |
| Loaded pelvis / chest local yaw | −11.5° / +42.4° | −13.8° / −55.0° |
| Pelvis displacement in first-fight image | 15.9 px | 11.4 px |
| Pelvis displacement in guardian image | 9.3 px | 6.2 px |

Knee bend here is computed from the actual hip–knee and knee–ankle vectors,
not a single Euler component. The yaw columns describe local joint rotations;
the Ranger's pelvis turns back during the draw while the chest continues
winding. Pixel figures include the recorded ordinary actor/camera state and
are not isolated silhouette or quality scores. The raw game image is
1200×536; the internal stretched SubViewport is 1208×540, so projected points
were converted to native output pixels. Full source coordinates and camera
transforms are retained in [proof.json](proof.json).

## Corrected contact coordination

Both old step curves declared a landed left foot before the pelvis could
reach that point. At finer sampling, IK consequently left the supposedly
landed ankle above and behind its intended contact. The right support remained
exact. This was a coordination defect, not a need for a wider lunge.

| At the unchanged 215-ms visual preparation | Previous landing | Corrected landing |
| --- | --- | --- |
| Arcanist | 124.7 ms | 144.05 ms |
| Ranger | 81.7 ms | 120.4 ms |

Arcanist's touchdown now occurs during its existing hip-led transfer. Ranger's
foot finishes setting after its pelvis lowers and before the draw completes
at 154.8 ms. Both preserve the original step endpoints and 85-mm free-foot
lift, loading poses, hand/weapon paths and return. The 300-ms attack, 85-ms
projectile lead, actual 215-ms release threshold and 340-ms recovery are
unchanged. No simulation movement, damage, cooldown, projectile or camera
code was edited.

## Contact verification

A controlled runtime Actor comparison covers both classes, basic/signature,
and 30/60/120 Hz: 24 source/candidate cases. It uses `strike`, `sync_attack`,
`animate` and the real `release_attack` API at the existing 215-ms threshold;
it is not a slow direct-gallery seek. The separate ordinary-world trace above
establishes the actual event clock and projected context.

| Maximum supported-foot target error | Previous 30 Hz | Previous 60 Hz | Previous 120 Hz | Corrected, all rates |
| --- | --- | --- | --- | --- |
| Arcanist | 3.90 mm | 3.90 mm | 30.55 mm | <0.001 mm |
| Ranger | 19.32 mm | 33.37 mm | 33.37 mm | <0.001 mm |

The largest old height errors were 20.14 mm for Arcanist and 25.19 mm for
Ranger. Afterward every declared contact, the unchanged rear support and the
release emitter are continuous to less than 0.001 mm in this float-precision
measurement. Actor world positions remain fixed. No test tolerance was
relaxed. Every animation-source function except `action_foot` was compared
byte-for-byte with 0.48; all body/hand poses, native clip construction, sword
sampling and floor fit remain unchanged. This verifies the contact correction,
not the new MPFB mesh's floor clearance or visual finish.

## Shared normal-camera review indices

These are per-fight source frame indices from the 30-FPS ordinary fixture;
each real basic attack has a 300-ms damage clock. Release is first sampled at
233.333 ms at 30 Hz, or 216.667 ms at 60/120 Hz, without changing the threshold.

| Case | Guard | Load | Release | Catch | Return |
| --- | --- | --- | --- | --- | --- |
| Arcanist first | 44 | 47 | 51 | 54 | 59 |
| Arcanist guardian | 29 | 32 | 36 | 39 | 44 |
| Ranger first | 41 | 46 | 48 | 51 | 56 |
| Ranger guardian | 44 | 49 | 51 | 54 | 59 |

The new figures need the existing native 29 rest bones and nine clips, with
continuous skinning that exposes the right supporting knee and the left
stepping leg in these poses. No new rest/bind assumption was introduced.
Fitted garments, corpse visibility, lighting and focal framing are separate
root/figure work. Their combined first-fight and guardian sequences, with and
without effects, remain the visual acceptance gate. No further amplitude or
camera adjustment is justified by these contact measurements alone.

## Reproduce the logical contact probe

The compact manifest embeds a self-contained GDScript probe. Extract it to a
temporary file and run against an imported, isolated source project:

```sh
python3 - <<'PY'
import json
from pathlib import Path
proof = json.loads(Path('assets/animations/bodyphrase-049/proof.json').read_text())
Path('/tmp/bodyphrase-049-contact.gd').write_text(proof['reproduction_script_gd'])
PY
XDG_DATA_HOME=/tmp/emberfall-bodyphrase-049 \
  /path/to/Godot_v4.7.2-stable_linux.x86_64 --headless \
  --path /path/to/isolated-source --script /tmp/bodyphrase-049-contact.gd \
  -- --output=/tmp/bodyphrase-049-contact.json
```

It emits 12 cases for that source. Run once on the recorded 0.48 source and
once on the corrected source to reproduce the 24-case comparison. Samples
retain actual foot targets and positions, support flags, clocks and release
continuity. The existing `tools/art/bodyphrase_probe_scene.gd` remains the
bounded ordinary-camera visual fixture; root coordinates its native captures
with final figure integration. Raw frame trees are not duplicated here.
