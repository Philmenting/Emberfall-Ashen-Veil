# Native attack foundations

`vowkeeper_sword_foundation.gd` contains derived animation curves from the free
**Standard** editions of Quaternius's Universal Animation Library 1 and 2.
The source archives include the CC0 1.0 Universal dedication, reproduced in
`LICENSE-Quaternius.txt`. No paid or account-restricted files were used.

Sources, retrieved 4 October 2026:

- [Universal Animation Library](https://quaternius.com/packs/universalanimationlibrary.html),
  [official free download](https://quaternius.itch.io/universal-animation-library).
  `Universal Animation Library[Standard].zip`, SHA256
  `cc73fc4e495b82958207316596317a3f40b9fa38065bde1027937452da537724`.
  `Unreal-Godot/UAL1_Standard.glb`, SHA256
  `69591853d817488edaa8fd9bf8fc1d821eaeaf789f8627b3cd23b41c4ed67997`.
  Used clip: `Sword_Attack` (1.533333 seconds, 47 samples).
- [Universal Animation Library 2](https://quaternius.com/packs/universalanimationlibrary2.html),
  [official free download](https://quaternius.itch.io/universal-animation-library-2).
  `Universal Animation Library 2[Standard].zip`, SHA256
  `4008ea208a604773a2b2177d965f0f5d3195498b5bf838c3f5785d68e95f2a68`.
  `Unreal-Godot/UAL2_Standard.glb`, SHA256
  `8cee20ab1bc55130092447e810e26df22dd2803eccc54f52137a7d54d7ab88a8`.
  Used clips: `Sword_Regular_B` (.533333 seconds, 17 samples) and
  `Sword_Regular_B_Rec` (1.033333 seconds, 32 samples).

Rebuild from the two extracted, unmodified Standard GLBs:

```sh
python3 tools/art/bake_attack_foundation.py \
  --ual1 '/path/to/UAL1_Standard.glb' \
  --ual2 '/path/to/UAL2_Standard.glb'
```

The offline tool requires NumPy. There is no Python, NumPy, imported mannequin,
65-bone skeleton or asset-network dependency in the game.

The bake converts source +Z facing to native −Z, derives pelvis and complete
three-segment chest motion relative to the source's global rest bases, then
fits elbow and hand paths to the existing adult arm lengths and shoulders.
Source hand-local +Z is the blade direction; the native grip/blade use +Y.
The native 29 rest bones and mesh binding are unchanged. Finger/toe animation
is omitted. The shield arm uses an authored forward brace in place of the
source's unencumbered arm swing.

`character_animation.gd` maps the source's chamber, stroke and return separately
onto the existing simulation-driven windup and .34-second recovery. Source
root motion is not applied to the actor. The source's in-place feet slide, so
the native clip supplies explicit step/lift/plant/return curves with a loaded
support foot. Runtime IK follows those same curves after pose blending.

Arcanist and Ranger attacks are original authored native phrases. Neither free
source library contains a bow set. The available `Spell_Simple_Shoot` is a small
recoil from an already raised hand and is not used or represented as a solution
to the requested visible casting effort. No motion-capture provenance is claimed.
