# Native class figures 055

Ranger uses Quaternius' complete Female Ranger Standard outfit: actual hood,
pauldrons, arms/hands, bracers, belts, legs and boots. Vowkeeper uses the same
compatible adult anatomy with the hood removed and separate fitted steel chest,
shoulder and bracer panels. Its original complete leather boots remain. Steel
shoulder/bracer panels retain the real source influences. The continuous chest
plate interpolates all four native influences on actual projected source torso
triangles; no body vertices, bone lengths or anatomical rest are changed.

The accepted original Nyra head, eyes and brows are shared as immutable meshes
at runtime. Vowkeeper keeps the original head-rigged hair; Ranger's hood covers
the crown. The manufacturer's matching female skin atlas is selected for both
the exposed source hands and the face. Each rendered actor owns its material
overrides. The original native65 hierarchy, inverse binds and original outfit
geometry/normals/UVs/weights are retained exactly.

`ranger-native65.glb` is 7,647,684 bytes, SHA-256
`606ec05719144a9bdcfed9283b14117248b00bba65ba1c940d63b555e055363c`.
Its complete original outfit contains 26,966 triangles. Original source maps
are reduced to 1K with Lanczos; no new high-resolution bake is claimed. Both
class renderings, including the visible head/armor/weapon/string/arrow, are
checked against the 40,000-triangle budget.

The outfit is the already legitimately acquired CC0 Standard package documented
in [Nyra's source receipt](../nyra052/README.md). The additional sword actions
come from the already acquired **Universal Animation Library 2 Standard**,
[official author page](https://quaternius.itch.io/universal-animation-library-2),
with its exact supplied `ANIMATION2-LICENSE.txt`. `OUTFIT-LICENSE.txt` is the
exact supplied outfit notice. Artist: **Quaternius**. No paid Source/Pro files,
viewer extraction or inaccessible originals are used.

Vowkeeper uses genuine original Sword Regular A, B and C clips, retargeted
offline by `target_rest * inverse(source_rest) * source_rotation`. Simulation
movement stays authoritative, so root travel is held in place. Each phrase maps
its authored contact to the actual simulation release, then settles into the
real native sword guard. The existing Emberfall sword is physically fitted to
the accepted finger aperture; all original blade/guard ornament remains.

Ranger keeps the original artist idle/walk/death and uses a new two-arm bow
phrase on the unchanged native arm lengths. The original bow's central handle
is narrowed to the measured aperture; original bow limbs and ornaments remain.
The actual rendered string has two segments that meet a real indexed right-hand
finger pad at its physical 2.8 mm radius. The arrow rest is measured above the
actual gripping fingers (60.772 mm above the grip); the 3.75 mm radius shaft
clears them by 2.25 mm. The projectile socket follows the actual arrow tip
through the draw, and the nocked arrow disappears at the simulation-authoritative
release. **The Standard source has no authored bow
draw clip; none is claimed here.** There are no facial blendshape animations.

Rebuild with NumPy and Pillow:

```sh
python3 tools/art/build_class_avatars055.py \
  --source-root ORIGINAL_EXTRACTED_STANDARD_PACKAGES \
  --animation2 ORIGINAL_UAL2_STANDARD/Unreal-Godot/UAL2_Standard.glb
```

The adjacent JSON records the actual source hashes, identical native rest,
texture limit and included clip inventory. The class quality smoke measures
actual weighted skin triangles, physical handle/string placement, native limb
lengths/scales, repeated held phases and the complete weighted death floor.
Runtime studio images and ordinary gameplay remain separate evidence.

Final native class smoke: 398 checks, 0 failures, 50 physically measured grip
poses including real hurt events. Maximum finger gap 2.644 mm; maximum handle
penetration 0.823 mm (source triangle skin, not a socket proxy). Maximum visible
triangle inventories: Ranger 33,294 including arrow/string; Vowkeeper 31,440
including all visible armor and sword. Conservative source bounds additionally
retain hidden covered panels. Godot clockwise front-face winding and outward
normals are checked on the actual continuous steel sheet.

The production Ranger release is additionally checked on all 65 native bone
components for both basic and signature: zero measured position/rotation/scale
change. The full draw/recovery phrase uses the same native idle support phase;
ordinary idle and walking remain animated. Directly after simulation release,
the actual indexed hidden arrow tip matches projectile_origin within 0.00024 mm
and moves below 0.00030 mm at contact. The authoritative class smoke and fourteen
original studio captures use Godot 4.7.2 and each exit 0; owned source hashes
remain frozen during both runs. See docs/design/reference-055/classes/receipt.json.
