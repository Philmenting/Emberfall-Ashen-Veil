# Continuous painted character animation

The approved paintings remain the visual authority. Motion makes the painted
figures feel alive and gives each combat action a readable beginning, contact,
and recovery, without changing simulation timing or outcomes.

- **Focal moment:** the weapon accelerates out of a deliberate windup and reaches
  its contact pose on the simulation's hit/impact event. Nyra's sword, staff and
  bow have separate action curves; guardians carry more weight and recover slowly.
- **Continuity:** native bone transforms move limbs continuously, with grounded
  alternating steps, counter-moving shoulders/head and trailing cloth. Twelve
  complete painted pieces per figure follow the approved identity; a cached
  alpha-contour mesh and 23 native bones move them without raster repainting.
- **Feedback:** hit recoil, interrupted casts, retreats and a staged collapse
  communicate actual events. Presentation never changes damage, RNG or warning
  geometry. Facing and camera bounds follow the visible animation.
- **Budget:** one skinned painting surface plus the existing contact shadow per
  living actor, shared meshes/textures and bounded bone/vertex counts. No image
  readback, CPU vertex rewrite or additional particle system per animation frame.
  Reduced Motion removes ambient sway and impact displacement while preserving
  essential movement, windups, contact and death states. Battery retains its
  existing lower render resolution and frame cap.

Verification includes continuous pose sampling, simulation-event timing,
interruption/resume, source UV and rigid weapon checks, native moving captures,
and complete animated figure bounds at closed Fold, open Fold and compact sizes.
Renderer/emulator evidence is not a measurement of physical Pixel performance.

## 0.42 whole-body craft

The focal action transfers force through pelvis, chest, head and planted legs.
Each figure has a loaded/contact body pair with a restrained torso turn;
preparation holds before acceleration, and follow-through settles into guard.
Continuity includes swing-foot-first stopping and recovery interrupted by a real
following cast. Direction and strength govern recoil; knees, shoulder and weapon
fall in stages. Bounded source-contour probes catch the fall on the floor.
Nyra and her actual target receive a restrained semantic silhouette accent;
nearby background fighters recede without moving their real floor positions.
Original paintings, shared GPU geometry and Reduced Motion remain intact.
