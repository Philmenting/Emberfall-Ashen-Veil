# Authored native Raider 056

The ordinary Raider uses Quaternius's original complete **Male Peasant** outfit,
including its hands and boots, with the original **Superhero Male** head, eyes,
brows and a compatible rigged beard. The former modular monster body is replaced.
The held short axe uses Quaternius's original **Axe Small** from the CC0 Medieval
Weapons pack. Its genuine authored steel edge, bevel and hard normals replace
the former soft Guardian 3 leaf shape. Its worn PBR finish and actual 18 mm grip
circumradius fit the male hand.

All original positions, normals, UVs, four skin influences and inverse bind
matrices are retained for the indexed geometry. The lower male head is selected
above 1.54 m, leaving the full facial shape and an overlapping neck under the
original cloth collar. Unused vertex records are compacted without changing
referenced vertex values. There is no anatomical scale change or legacy 29-bone
mapping. The native outfit keeps its original 65-bone rest and hierarchy.

The supplied base and modular male art share exact Head, neck and spine rest
transforms. The older base has a roughly 2.3-degree original clavicle difference:
the original head skin is retained, and the largest weighted rest difference at
the lower neck seam is **4.3923 mm**. The builder measures and bounds this source
seam rather than silently rebinding or reshaping the anatomy.

The actual complete figure has **18,560 triangles**, plus **1,098** for the axe:
**19,658 visible triangles** across eight original body parts and four weapon
parts. This exceeds the preferred 15,000 target but stays below the explicit
20,000 cap; the anatomy is preserved. Source body height is **1.81008 m**, excluding
the extended weapon. Original color, normal and roughness/ORM maps are resized to
at most 1,024 pixels and embedded, and cloth receives a worn oxblood material tint.

Real Quaternius Idle, Walk, Sword Idle, Sword Regular A/B, Hit Chest and Death
clips are retargeted relative to native rest. Native bone lengths and scales stay intact, with authored pelvis offsets
retained; actor movement remains owned by simulation. The attack samples one
continuous source phrase and maps the existing contact boundary to phase 0.56,
where the real blade reaches forward near torso height. Recovery continues
through the same source phrase before settling back into guard. Damage overlays the actual authored Hit Chest phrase
on the upper body. Native death floor samples come from all actually indexed,
weighted original body surfaces. The renderer adds no attack or damage events.

The offline fit changes only local finger rotations and the rigid wooden grip.
It preserves the fitted proximal grip first, then independently curls each
native distal phalanx. The largest actual fitted PIP hinge is 102.15 degrees on the original closing
axis; native bone positions, lengths, skin weights and scale remain intact. All eight
distal joints and fingertips must actually wrap within 35 mm of the 18 mm
shaft. Indexed, axial-clipped skin triangles additionally require thumb contact,
at least three touching fingers and one real thumb patch opposing three
distinct real finger patches, with
no more than 3 mm clearance or 1 mm penetration. Socket placement alone is
insufficient. A final 0.4 mm rigid hilt adjustment supplies the third real
opposite-side facet contact. The independent runtime audit computes exact
3D triangle-to-triangle distances between the imported, original-weighted
skin and fitted wood faces, including edge/face intersections; a cylinder
serves only as a conservative penetration bound. It measures indexed original
four-influence hand triangles;
the independent Godot smoke then measures the real imported arm/handle triangles
across windup, release, recovery, walk and damage. Offline fitting alone is not
visual acceptance.

Rebuild with Python, NumPy, SciPy and Pillow:

```bash
python3 tools/art/build_raider056.py \
  --source-root /path/to/extracted-standard-character-packages \
  --animation1 '/path/to/Universal Animation Library[Standard]/Unreal-Godot/UAL1_Standard.glb' \
  --animation2 '/path/to/Universal Animation Library 2[Standard]/Unreal-Godot/UAL2_Standard.glb'
```

`raider-native65.json` records each original input SHA-256, part budget, exact
source skin preservation and seam measurement. `axe-grip.json` stores the fitted
finger quaternions and physical hand opening. `death-grounding.json` contains the
exact weighted floor samples. Original supplied CC0 notices are copied byte for
byte as `BASE-LICENSE.txt`, `OUTFIT-LICENSE.txt`, `ANIMATION1-LICENSE.txt` and
`ANIMATION2-LICENSE.txt`.

Sources: [Universal Base Characters](https://quaternius.com/packs/universalbasecharacters.html),
[Modular Character Outfits — Fantasy](https://quaternius.com/packs/modularcharacteroutfitsfantasy.html),
[Universal Animation Library](https://quaternius.com/packs/universalanimationlibrary.html),
[Universal Animation Library 2](https://quaternius.com/packs/universalanimationlibrary2.html).

`axe-original.glb` retains the public Quaternius model byte for byte (54,604 bytes,
SHA-256 `b4eedc707dabb98883f0e18a096953dbea164b9d2d40a657bd44805886f33b8d`).
`tools/art/fit_raider_axe056.py` applies the original node transform plus rigid,
uniform normalization to a 1.25 m prop height, then narrows only the wooden grip
over an explicit **±65 mm runtime halfspan**, tapering to the original wood by
±100 mm. The builder converts these spans through the .55 prop scale before
splitting and fitting faces. Steel positions/normals, cutting edge, bevel and
four original material splits are retained under that rigid normalization.
`axe-fitted.json` records both hashes, the exact transform and the complete fitted 1,098
triangle budget (original 966 triangles; wooden grip faces split at fit boundaries). The rig applies its uniform .55 prop scale; this is independent
of native body anatomy.

Weapon source and license: [Quaternius Medieval Weapons](https://quaternius.com/packs/medievalweapons.html)
and [Axe Small by Quaternius, Public Domain CC0](https://poly.pizza/m/o54NXjRI4V).
The official public Drive download returned a quota-exceeded page; the author's
public Poly Pizza GLTF was downloaded instead. `WEAPON-LICENSE.txt` is an explicit
Emberfall attribution/source notice based on those public CC0 listings, rather
than a claimed byte copy of the unavailable Drive notice. The four existing
character/animation notices above remain original byte copies.

Rebuild the fitted weapon separately:

```bash
python3 tools/art/fit_raider_axe056.py
```
