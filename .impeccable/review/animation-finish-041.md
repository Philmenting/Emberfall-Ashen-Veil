# Animation finish review · 0.41

Manual native-Godot review using the Impeccable animate/polish guidance. The
official launcher and quality-gate definitions remain unavailable in this
session. This is a scoped manual motion/layout assessment, with no numerical
fidelity score or official gate claim. No independent agent review was run.

The approved painterly direction remains authoritative. The motion thesis is
`docs/design/animation-direction.md`. The requested change replaces discrete
walking/attack paintings with continuous articulated movement, event-synchronized
contacts, planted feet, delayed cloth, drawn bowstrings and staged death.

## Bounded inspection

The native inspection stage rendered 720 frames / 24 seconds. Thirteen selected
frames were opened across all three classes, four hostiles and four guardians,
covering steps, windup, contact and collapse. The initial pass found material
gaps in hostile neck/elbow connections and an excessive rotation during collapse.
One correction batch calibrated the actual painted hostile joint endpoints and
face pivots, fitted their torso necks, and reduced collapse rotation/displacement.
Six affected frames were reopened once to confirm the correction. No further
cosmetic review loop followed.

The real-scene layout fixture generated 33 frames: all three classes plus four
guardian windup/contact pairs at each physical window size, 2424 × 1080,
1040 × 1080 and 854 × 480 with Large Text. All 21 class/contact captures were
opened. Complete figures, their weapons, animation connections and reserved HUD
space were reviewed. Raised-Life guardian fixtures are QA only. Native Godot
logical viewport sizes differ from physical capture sizes due to project scaling.

The 16-second ordinary-gear gameplay export samples actual combat at 30 FPS;
it contains editorial cuts and the game's existing score. The diagnostic stage
and gameplay export are separately identified. Their sampling rates do not
establish a physical-device frame rate.

Separate Android 16 qualification passed on animation commit `2280dc10`: all
four native guardian skins changed over twenty real simulation steps, with four
distinct rendered frames each. Eight actual Android frames (0 and 17 per region)
were opened to confirm native skin movement, connected anatomy/weapon parts and
painted rendering. No cosmetic correction followed. First-session relic/oath
coverage and its cold restart also passed. Subsequent changes affect only the
CI harness, its diagnosed software-emulator AFK deadline and documentation.
Hashes and scope are recorded in
`docs/audit/2026-10-02/animation-android-graphics.json`.

## Verified limits

The automated motion suite passes 98 checks, including rigid weapon geometry,
continuous joint transforms, stance-foot compensation, interruption, pause,
Reduced Motion and 360 unchanged simulation snapshots/RNG states. The animated
camera suite passes 900 checks across classes, regions, phases, warning variants
and three viewport sizes. Those framing fixtures also raise damage and guardian
Life to keep the review independent of late-game progression balance.

Manual disposition: **reviewed for the requested animation scope**. Remaining
acceptance is the current-head full Android CI and physical Pixel 9 Pro Fold playback,
touch, sustained performance, heat and battery measurement. This does not approve
a main-branch merge or Play publication. Previous 0.40 reports remain historical.
