# Raider 056 native verification

The ordinary Raider now uses the complete original Quaternius Male Peasant
outfit, native hands and boots, with an authored male head, eyes, brows and beard.
Native 65-bone anatomy, original skin weights, bind matrices and indexed body
geometry remain intact. The sharp original CC0 Axe Small replaces the rejected
soft Guardian prop; the held wood grip is fitted to the actual male hand.

The final production test completed with **324 checks, 0 failures, actual exit
0** across 15 poses. It clips actual imported skin and wood triangles to the
same ±55 mm native hand band and computes exact 3D triangle-to-triangle distance,
including edge/face intersections. Maximum actual finger clearance is
**1.209 mm**, thumb clearance **2.825 mm**; the conservative circular penetration
bound is **0.769 mm**. One actual touching thumb patch opposes at least three
actual touching finger patches. Limits remain 3 mm / 1 mm; all eight distal
joints/tips remain within 35 mm of the shaft. A final **0.4 mm rigid hilt shift**
supplies the third actual opposing contact, with no anatomical scaling.

The independent offline reviewer also passed exact skin/wood 3D contact and
three-finger opposition against the frozen body, axe and grip hashes. It does
not assume a constant eight-corner extrusion: original split/triangulated wood
faces vary slightly within the hand band. The apparent ±80 mm fit previously
meant only ±44 mm after the .55 prop scale; the actual fitter now explicitly
fits **±65 mm at runtime**, tapering to original wood at ±100 mm.

Original source-relative closing axes remain positive; the largest actual hinge
is **102.149°**. All 65 native bones stay continuous across attack contact at
source phase 0.56; authored Hit Chest and weighted death floor are included in
the production smoke. The axe's four local PBR materials now lower and restore
with body readability; alpha and roughness remain intact.

The complete visible model is **18,560 body + 1,098 weapon = 19,658 triangles**.
It preserves anatomy and remains below the explicit 20,000 cap, while exceeding
the preferred 15,000 target. Four supplied character/animation license notices
remain byte copies; the public original axe is retained byte for byte. The
separate weapon attribution notice accurately explains its public CC0 source.

The six files in `native/` are original unedited 1000 × 1000 Godot studio PNGs,
rendered on Linux/Mesa with Dummy audio. Capture actual exit is 0, with no script,
shader or ALSA errors; the virtual renderer reports an unsupported V-Sync warning.
Guard, load, release, followthrough, actual grip and face were viewed. These
studio images verify anatomy/grip and do not substitute for real combat capture
or phone GPU measurement. Source and image hashes are bound in `receipt.json`.

Failed preliminary fits and false constant-extrusion/nearest-patch assumptions
are preserved under `rejected/`; they are not final acceptance results. The
frozen builder was also run to actual exit 0: it reproduces the body GLB byte
for byte, all final grip JSON values exactly, and 19,658 actual visible triangles.
The rebuild log and receipt are included. Canonical asset sources, rebuilding
instructions and original notices are in the
[canonical asset README](../../../../assets/models/raider056/README.md).
