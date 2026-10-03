# Emberfall 0.43 · Spatial figures and a steady camera

Version **0.43.0-beta.1 / Android code 49** implements the user's explicit
3 October request: **“Auf vollständig animierte 3D-Figuren umstellen.”**
It replaces the painted actor runtime from 0.41/0.42. The monumental world,
regional architecture, bronze/plum identity, progression and interface remain
the established game.

## Visible changes

- All eleven appearances are real lit volumes: three Nyra classes, four
  hostile types and four guardians. Nyra has a continuous face, pale hair and
  braids, longer legs, tapered boots and fitted armor. Camp, Armory and portraits
  use the same class model and saved equipment accents as combat.
- Each appearance has a native 29-bone Skeleton3D and nine AnimationPlayer
  clips. Walking lifts the swing boot and holds the stance sole in world
  space. Direction changes turn the volume continuously. Sword, staff and bow
  have separate load/contact/follow-through poses; the bow belongs to the left
  hand and the right hand reaches the real moving nock.
- A melee strike reaches contact on the damage event. Ranged release starts
  the visible projectile, up to 85 ms before its arrival on the original
  damage frame. Cast interruption, rapid following casts and restored guardian
  warning countdowns retain their real simulation timing.
- Defeat buckles the knee, folds one leg, turns pelvis/shoulder/head and settles
  cape, coat and braids. Long robes gather during the crouch to clear the floor.
  The same skinned geometry remains visible through the 0.90-second fall and
  final corpse; no fallen painting replaces it.
- Combat reserves a steady room shot. Hits, weapon poses, short combat
  repositioning and target changes produce no camera shake or zoom breathing.
  Travel fits an envelope relative to the moving anchor so stale room points
  cannot pull Nyra off the unfolded screen. Real wide warning zones can widen
  a shot smoothly while retaining their actual collision shape.

## Runtime

`tools/art/build_characters.py` authors and rebuilds all original geometry.
`character_rig.gd` binds imported parts once per appearance into one cached,
immutable GPU-skinned surface. Models contain **18,508–39,888 triangles**;
mesh, skin and clip libraries are shared. Animation moves bones without CPU
vertex rewrites or image readback. The opaque shader uses actual spatial
normals, roughness and metallic properties. Source material colors were checked
against imported Godot values before converting sRGB into the vertex channel.

All Android presets include the revised GLBs and native rig. The old painted
actor textures and unused painted animation scripts are excluded. World
paintings remain live; this is a character replacement, not a claim that all
background art became geometry. No simulation, save schema, damage, loot or
AFK rule changes were made.

Reduced Motion freezes decorative idle and suppresses displacement reactions
while preserving essential locomotion, casting, defeat and warnings. The
camera remains free of impact shake in both modes. Existing Balanced (60 FPS)
and Battery (30 FPS) configured caps, resolution and shadow settings remain.
These caps are not sustained frame-rate measurements.

## Review evidence

- [Ordinary-gear Vowkeeper gameplay](previews/characters-3d/emberfall-vowkeeper-043.mp4)
- [Ordinary-gear Arcanist gameplay](previews/characters-3d/emberfall-arcanist-043.mp4)
- [Ordinary-gear Ranger gameplay](previews/characters-3d/emberfall-ranger-043.mp4)
- [All eleven runtime figures in motion](previews/characters-3d/emberfall-motion-043.mp4)
- [Matching 0.42/0.43 ordinary-gear comparison](previews/characters-3d/emberfall-042-043-comparison.mp4)
- [Native models, portraits and three layout classes](previews/characters-3d/)

Gameplay starts in **Armory**, then shows first combat, the real guardian,
its last health phase and the earned relic using ordinary starting gear.
Cuts omit intervening travel; playback preserves the 30 FPS simulation speed.
The separate motion stage labels its QA purpose. Thirty-three layout captures
cover 2424×1080 closed Fold, 1040×1080 unfolded and 854×480 with Large Text;
late-region captures elevate Life only to reach warnings. They are not balance
or marketing evidence.

The first finish review found unfolded travel drift, stocky anatomy, cheek
bulges, ranged release mismatch, a rigid collapse and clipped inspection
staffs. The correction batch addressed these findings before native
confirmation. That confirmation found the long settled hem still too upright;
a targeted cloth correction released its body twist, lowered the hem and
flattened its fallen depth. The final review media was regenerated to reflect
that fix. The targeted read-only reviewer confirmed the low folded hems and
reported no material clipping or persistent floating. Its six-fix disposition
is recorded in [the finish review](design/3d-finish-review.md). The world, UI
hierarchy and real warning relationships were preserved.
Native Godot 4.7.2/Mesa captures are exports, not phone frame
rate measurements. No independent 3D comp or QUALITY BAR approval is invented.

All **31 local Godot suites / 3,455 checks** passed, alongside server progression
checks and five Android release-verifier tests. The final cloth correction
passed the affected **210 physical/visual checks** and full skinned-surface
floor probes for all eleven figures. CI repeats the complete suite on the final
commit; Android QA also asserts 29 bones, nine native clips, real model depth,
moving rendered frames, all four guardians, both quality modes and cold restart.

Verification results and the downloadable exact-commit Android packages are
recorded in [draft PR 5](https://github.com/Philmenting/Emberfall-Ashen-Veil/pull/5).
Physical Pixel measurements of frame rate, heat, battery and touch remain
outstanding. Perceived animation quality requires the user's assessment of the
actual footage/build; passing regressions does not certify a high-quality beta.
CI keys are temporary; this change does not publish to Google Play.

Reproduce:

```sh
blender -b -t 2 --python tools/art/build_characters.py
godot --headless --editor --path . --import
GODOT_BIN=/path/to/godot python3 scripts/run_beta_checks.py
godot --path . --script tests/character_motion_preview.gd -- --capture-dir=/tmp/3d-motion
godot --path . tests/success_gameplay_clip.tscn -- --class=Vowkeeper --capture-dir=/tmp/3d-gameplay
godot --path . tests/animation_layout_preview.tscn -- --capture-dir=/tmp/3d-layout
godot --path . --script tests/model_art_preview.gd -- --capture-dir=/tmp/3d-models
```
