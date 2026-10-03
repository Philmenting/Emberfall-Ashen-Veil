# Native spatial character animation · 0.43

The user explicitly chose fully animated 3D figures on 3 October 2026. The
monumental painted world remains the visual reference for palette, atmosphere
and adult identity. Live figures are original volumetric models with real
lighting, material reflection, depth and a native 29-bone skeleton. FORM task
identifier: `native-volumetric-character-animation`; no new comp approval is
inferred from that identifier.

- **Focal moment:** sword, staff and bow carry distinct load, contact and
  follow-through poses. Melee contact follows the actual hit event; ranged
  release starts visible flight and arrives on the unchanged damage frame.
  A guardian loads over its real warning countdown, including restored saves.
- **Continuity:** nine native AnimationPlayer clips animate each appearance.
  Distance drives the gait; world-space stance support holds the sole while
  the opposite foot clears the floor. The figure turns around its own vertical
  axis. Pose changes blend continuously, including a real cast during recovery.
- **Feedback:** a restrained chest reaction communicates an actual hit.
  Retreat cancels an uncommitted cast. Collapse passes through knee buckling,
  a folded leg, pelvis/shoulder turns, head settling and delayed cape/coat bends.
  The same skinned volume supplies the living figure and its corpse.
- **Camera:** combat reserves its room/action envelope; hits, target swaps and
  weapon poses do not shake or zoom it. Travel follows a relative envelope
  attached to the current anchor. Complete real warning zones may request one
  smooth widening; the shot does not tighten between repeated warnings.
- **Budget:** one immutable cached GPU surface, shared mesh/skin/clip library
  per appearance and at most 40,000 triangles per model. Animation transforms
  bones without rewriting vertices, reading images or creating new meshes.
  Battery preserves its lower resolution, shadow setting and FPS cap.
  Reduced Motion freezes decorative idle and removes displacement reactions
  while preserving steps, casting, impacts, falls and warning information.

Verification checks actual skinned soles, world-space stance locking, real
simulation timing, interruption/resume, rigid weapons, death articulation,
all three class trajectories and complete spatial bounds at closed Fold,
open Fold and compact sizes. Native model/motion inspections are labeled QA;
ordinary-gear gameplay is captured separately, opening in Armory. Renderer and
emulator evidence do not measure physical Pixel performance or certify the
user's perceived animation quality.

The previous painted 0.41/0.42 implementation remains documented in
`ANIMATIONS_041.md` and `ANIMATION_CRAFT_042.md` as release history. Its billboards,
contour meshes and final fallen paintings no longer supply runtime figures.
