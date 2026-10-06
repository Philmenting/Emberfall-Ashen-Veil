# Native hostile inspection, quality pass 055

These five original 1200 × 675 PNGs were rendered through the actual Godot
runtime. They are frozen studio fixtures, not ordinary gameplay or a device
performance benchmark. The native capture exited successfully using Godot
4.7.2 and Mesa llvmpipe OpenGL compatibility on Xvfb.

- `hostile-role-guards.png`: scavenger, hexer, shield bearer and elite, from
  left to right, with the revised aged-metal, cloth and restrained-inlay finish.
- `hostile-role-preparations.png`: their ordinary preparation at the same
  native cooldown fraction, using distinct claw, palm and blade phrases.
- `bell-warning-chamber.png`: Bell Warden's asymmetric loaded bell mace and
  hanging censer, through its heavy warning phrase.
- `bell-heavy-contact.png`: the native heavy contact after warning release.
- `bell-heavy-catch.png`: knee catch and early return at 0.16 seconds into
  the Bell Warden's 0.56-second native recovery.

The focused hostile suite passed **81 checks, 0 failures** across all eight
hostile appearances. It measures actual weighted body/weapon/cloth floor
clearance, anatomical chain lengths, unit-scale anatomy, bounded intentional
garment compression, contact continuity, immutable mesh/skin, real hit recoil,
zero-time repeat stability and warning/recovery ownership. The new contact
continuity check exposed and fixed a preexisting cape snap at strike release.
Maximum measured anatomical rest-length error was 0.000000060 model units;
maximum contact/recovery pose-component error was 0.000000653.

The existing character 3D suite also passed **164 checks, 0 failures** before
the independent 055 hero-class factory migration. That result is retained as
an intermediate regression proof; final integrated class validation belongs to
the overall 055 quality pass.

All enemy models retain their original authored modular 29-bone geometry. No
new anatomical body mesh or skeleton mapping is claimed. The source palettes
are baked once into shared native mesh channels; runtime animation never edits
source vertices. `receipt.json` records source/model and original artifact
hashes, exact scope and renderer limitations. These screenshots contain no
audio and were not edited.
