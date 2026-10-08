# Shared native hostile art 057

Hexer, Bulwark, Elite and the four Guardian appearances now use the original
compatible **65-bone male** anatomy, rather than the former modular29 body.
The original male head, eyes, brows, beard, verified exposed hands and boots
are shared from [Raider056](../raider056/README.md). One shared **Male Ranger**
cloth asset supplies original sleeves, tunic, trousers, belt, hood and shoulder
panels. It occupies **2,383,964 bytes**; there are no seven duplicated character
bodies. Every male rest/hierarchy node and original inverse bind exactly matches
the manufacturer's Male Peasant. Original body geometry and bone lengths remain
unchanged; no anatomical scaling or legacy joint mapping is used. The derived
sleeve geometry has the limited garment changes described below. All other
selected clothing positions, normals, UVs and four skin influences are unchanged.

The Ranger tunic and trousers replace the obsolete Peasant tunic/trousers.
Original Peasant cloth sleeve triangles are removed while the independently
verified original exposed hand/arm surface is retained. The manufacturer boots
remain, avoiding 9,172 triangles of a second ornate boot asset. The original
clothing color/normal/ORM maps are resized to 512 pixels; existing shared male
head/hand maps retain the Raider056 1K originals.

The Ranger sleeve material also contained overlapping gloves. Those glove ends
are cut 10 mm before the original wrist so the verified original hands remain
exposed. Retained sleeve positions move 4 mm along their original normals to
separate the fabric from the originally coplanar bare forearm. Existing sleeve
normals, UVs and four skin influences remain unchanged. Newly generated cuff-edge
vertices interpolate the original normals, UVs and skin influences; their weights
are normalized and stored as four influences. Original body vertices, hands,
native rest and inverse binds are not changed by these garment edits. The
[manifest](manifest.json) records the cuff cut and 4 mm fabric offset explicitly.

The Hexer uses a restrained sage hood and cloth sleeve. Armored Bulwark/Elite
and Guardian 0/3 expose the original male face and carry fitted steel/bronze
panels. Guardian 1/2 retain distinct hooded pigments and staff gestures. Armor
shells reuse original authored panels and all four source influences, with a
10 mm garment clearance. The small fitted breastplate interpolates actual source
torso triangles and their weights; it is garment armor, not a replacement body.
The Bulwark shield is strapped to the actual native forearm, rather than
pretending an unclosed off-hand holds a separate handle. Shared immutable armor,
hand and shield meshes and original skin resources are cached; PBR materials
remain owned by each actor. The small generated one-bind shield skin is also
owned by its actor: its rigid death drop changes only that accessory bind,
preserving all original body skins and every other living shield. Actual native
color/normal maps and opaque alpha remain in use.

The seven weapon-only GLBs are fitted **existing Emberfall project art** from
the original role models. They are **not newly sourced Quaternius weapons**.
The original role staff, sword, bell and axe ornaments outside the 100 mm grip
region remain in place, with a common 80 mm source-space grip relocation. The
rigid shaft is fitted to the already verified male 18 mm finger aperture at
runtime scale 0.55. The builder splits actual indexed triangles at the 65 mm grip
and 100 mm taper planes; simply fitting existing vertices would miss long shaft
faces whose endpoints lie beyond the hand. Normals are recalculated in the
edited band. The original body/head geometry and finger fit remain unchanged.
The runtime audit measures actual imported skin and prop triangles, including
opposed thumb/finger patches, under the same 3 mm contact and 1 mm penetration
limits used for Raider056; socket positions alone do not establish hand contact.

Original Spell Simple Enter/Idle/Shoot, Sword Regular A/B/C, Walk, Hit Chest and
Death clips keep the native rest-relative rotations. Source bone scales and
child translations remain untouched. The existing simulation/actor clocks
still determine movement, warning, contact, hit and death. Render clips map
the real contact boundary continuously into source recovery; they create no
additional attack, damage or projectile events. Hit Chest supplies the actual
native upper-body recoil. A new 181-sample role floor table measures original
mixed-weight head, body, hands, boots, clothed panels and fitted armor. The longer
Ranger rear drape needs its own actual floor table; the old Peasant table let it
intersect the floor by approximately 23 mm at the final death pose. The held prop
and shield settle separately on the actual floor, so the Bulwark's protruding
shield cannot lift its dead body. Original animation tracks are bound to the
actual target Skeleton3D path; imported loop names receive the expected alias.
Bossphase changes per-actor visible PBR pigments and
restores the original role finish at phase 0; repeated unchanged phase/readability
values skip redundant material writes.

The roles have an explicit 40,000 visible base-triangle cap, rather than the
Raider's 20,000 cap. This larger cap preserves coherent original anatomy and
clothing; it must not be presented as proof of physical Android performance.
Imported native index LODs are retained on unchanged original surfaces, including
the selected exposed-hand mesh. Armor generated from selected panel triangles
does not blindly reuse incompatible source LOD indices.

Sources are Quaternius's CC0 Standard
[Modular Character Outfits — Fantasy](https://quaternius.com/packs/modularcharacteroutfitsfantasy.html),
[Universal Base Characters](https://quaternius.com/packs/universalbasecharacters.html),
[Universal Animation Library](https://quaternius.com/packs/universalanimationlibrary.html)
and [Universal Animation Library 2](https://quaternius.com/packs/universalanimationlibrary2.html).
The four supplied raw CC0 notices are preserved byte for byte as
OUTFIT-LICENSE.txt, BASE-LICENSE.txt and ANIMATION1/2-LICENSE.txt. The
[manifest](manifest.json) records every original input SHA and every resulting
GLB SHA, actual triangle counts, supported original action names and scope.

Rebuild without Blender or Godot from the authorized extracted CC0 source:

```sh
python3 tools/art/build_hostiles057.py \
  --source-root /workspace/scratch/emberfall-character-source-052 \
  --animation1 '/workspace/scratch/quaternius-uam-inspection/extracted/Universal Animation Library[Standard]/Unreal-Godot/UAL1_Standard.glb' \
  --animation2 '/workspace/scratch/quaternius-uam-inspection/universal-animation-library-2/extracted/Universal Animation Library 2[Standard]/Unreal-Godot/UAL2_Standard.glb'
```

The original native studio inspection script is
[native_hostile_preview.gd](../../../tests/native_hostile_preview.gd); ordinary
combat capture and physical phone measurements are separate evidence.
