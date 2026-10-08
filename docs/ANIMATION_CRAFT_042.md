# Emberfall 0.42 · Weight, contact and readable combat

Version **0.42.0-beta.1 / Android code 48** builds on `8a52be3` from
`improve/expedition-quality`. The approved painted world and all eleven figure
identities remain the source art. The complete anatomical layers now have
authored whole-body phrasing instead of predominantly arm/weapon motion.

## What changes in play

- Every class, hostile type and guardian has its own loaded/contact body pair.
  Pelvis, chest, head and supporting legs transfer weight together. A restrained
  three-dimensional torso turn adds real foreshortening. Sword, staff and bow
  retain distinct action curves and rigid weapon geometry.
- Windups set a readable pose, hold briefly and accelerate into the real impact.
  Follow-through overshoots slightly and settles into guard. A new simulation
  cast can blend out of the previous recovery without swallowing its next hit.
  The impact itself always releases contact immediately.
- Walking counterbalances pelvis and shoulders and responds to acceleration.
  Stopping first sets down the swing foot, then steps the old support foot into
  guard; both feet do not slide to neutral at once.
- Recoil follows the attack source and distinguishes ordinary, critical and
  heavy damage. Repeated weak hits cannot perpetually restart the reaction.
  On defeat knees give way, shoulders fall and the weapon arm follows. Actual
  skinned contour probes keep the fall on the floor before the original painted
  fallen pose settles. Corpses lose emphasis in the living group.
- Nyra has a restrained silhouette accent and a distinct ground footprint.
  The real target has its own accent. Nearby background fighters recede in
  contrast; targets, guardians and active warnings retain their emphasis.
  Repeated damage rings were removed. A sword ribbon follows the animated blade
  instead of drawing a generic horizontal sector through the floor.

Combatants stay at their actual positions. Presentation never separates them
from collision/warning geometry, changes simulation time, or writes combat stats.
No new currency, save schema or required online connection is introduced.

## Runtime and accessibility

Living figures still use one cached GPU surface, 23 bones and at most 6,000
vertices plus their existing contact shadow. Torso rotations do not rewrite
image pixels or allocate a new mesh every frame. Falling uses shared, bounded
contour probes only during its short articulated phase. Focus uses material
parameters and four bounded alpha samples on the heroine/current target;
there is one extra heroine ground marker, not one shell per enemy.

Reduced Motion keeps idle stationary and suppresses decorative cloth motion,
camera shake and displacement reactions while retaining essential locomotion,
casting, contact, warnings and defeat. Battery retains its existing resolution,
shadow and frame-cap behavior.

## Reviewable evidence

The new `animation_craft_smoke.gd` checks whole-body loading, contact, planted
support during recovery and stopping, stronger directional reactions, floor
contact while falling, rapid-cast transitions and unchanged simulation snapshots
for all three classes. It is registered in the full beta runner.

Native clips and layout captures use the actual Godot 4.7.2 OpenGL compatibility
renderer and Mesa software graphics in this environment. Normal-gear gameplay
and the labeled all-figure stage are separate. Late-region layout fixtures
increase Life solely to reach the guardian warning. Renderer clips and emulator
results do not establish physical Pixel performance.

- [0.41 / 0.42 side-by-side comparison](previews/animation-craft/emberfall-motion-comparison.mp4)
  — 24 seconds, the same labeled all-figure sequence on both sides.
- [0.42 all eleven figures](previews/animation-craft/emberfall-motion-042.mp4)
  — 720 native renderer frames at 30 FPS.
- [0.42 ordinary-gear Vowkeeper gameplay](previews/animation-craft/emberfall-gameplay-042.mp4)
  — 480 native renderer frames at 30 FPS, from encounters to the earned relic.
- [Native layout captures](previews/animation-craft/)
  — 33 PNGs at 2424×1080, 1040×1080 and 854×480. Review media is excluded
  from Godot imports and Android exports.

Local verification covered all 31 beta suites. After fixing the visual-suite
API mismatch, the four affected motion, framing and visual suites passed
**1,179 checks**, with a further **206 timing checks** passing after the final
impact transition fix. The new suite contributes **111 checks**; server
progression checks and all five Android release-verifier unit tests pass.
The expedition simulation source remains byte-identical to the base commit.
The final immediate-contact and defeated-hero focus assertions also pass in
the complete **111-check** craft suite.
GitHub runs the complete suite again on the review branch, together with Android
build and Android 16 graphics/first-session runtime checks; their final status
and downloadable packages are recorded in the pull request.

Reproduce:

```sh
GODOT_BIN=/path/to/Godot_v4.7.2-stable_linux.x86_64 python3 scripts/run_beta_checks.py
godot --path . --script tests/painted_motion_preview.gd -- --capture-dir=/tmp/craft-motion
godot --path . tests/success_gameplay_clip.tscn -- --class=Vowkeeper --capture-dir=/tmp/craft-gameplay
godot --path . tests/animation_layout_preview.tscn -- --capture-dir=/tmp/craft-layout
```

Physical phone measurements of frame rate, heat, battery, touch and perceived
animation quality remain outstanding. CI signing is temporary; this change does
not publish to Google Play. Permanent signing and Play gates in
`PLAY_BETA_039.md` remain applicable.
