# Constructed rooms and body support · 0.48

Native captures of `0.48.0-beta.1` / code `54`, implementation source
`850721fd010dd62ddbf1a6c681f73955ffddc8b3`. This iteration rebuilds ruined
wall sections, openings and ground joins, lowers stone rendering cost, and
reworks Arcanist and Ranger support, torso load and recovery. Arcanist
projectiles now originate at the animated casting palm. The eleven figure
models remain the 0.47 models: both replacement costume samples were rejected,
and this packet does not claim the character finish is complete.

| Evidence | Content and limits |
| --- | --- |
| [Ordinary attacks](emberfall-attacks-048.mp4) | 24 s / 720 frames. Vowkeeper, Arcanist and Ranger each have a 4 s first fight and 4 s first guardian fight, in that order. Normal equipment and actual attack/release clocks; cuts skip travel only. |
| [Effects-hidden attacks](emberfall-attacks-bare-048.mp4) | 12 s / 360 frames. One 4 s first fight per class at actual speed. Explicit QA hides effects, numbers and markers to expose the bodies; this is not a shipping preference. |
| [Reading and travel](emberfall-graphics-048.mp4) | 15 s / 450 frames. Actual reading pause at 5–8 s, resumption and travel into the Pilgrim’s Well chamber. The last frame is still approaching the healing point; it does not demonstrate healing. |
| [Model gallery](emberfall-motion-048.mp4) | 24 s / 720 frames. Heroes, hostiles and guardians under a controlled camera. Its 650 ms QA windups are not ordinary combat timing. |
| [0.47 / 0.48 comparison](emberfall-attacks-comparison-047-048.mp4) | The two ordinary-attack clips side by side at their original 1200×536 panel dimensions, with a 36 px label strip. No cropping or speed change; re-encoded H.264. |

All clips use 30 fixed simulation steps per second and have no audio. They
are native Godot frames encoded as H.264, not concept renders. Attack and
travel clips are 1200×536; the gallery is 1280×720. Every MP4 passed a complete
decode and declared-frame-count check. The comparison is an editorial
derivative, not another game capture.

The 34 stills include all 11 states at 2424×1080, 1040×1080 and 854×480,
plus the 1000×550 portrait sheet. The smallest layout enables Large Text.
States cover camp, all three class panels, four guardians, reading, Ward
reserve and the real empty performance report. Guardian stills raise Life to
100,000 to reach the warning fixture; ordinary clips retain normal equipment.

Representative originals:

- [Camp](camp-2424x1080.png), [portraits](portraits.png), [Arcanist panel](skills-Arcanist-2424x1080.png).
- [Hollow Spire](guardian-0-2424x1080.png), [Drowned Archive](guardian-1-2424x1080.png), [Glass Ossuary](guardian-2-2424x1080.png), [Cinder Citadel](guardian-3-2424x1080.png).
- [Folded layout](guardian-0-1040x1080.png), [small layout with Large Text](guardian-0-854x480.png), [reading pause](reading-2424x1080.png), [empty performance report](performance-2424x1080.png).

All 34 stills were opened. The build-thread sequence inspection included every
ordinary/bare segment start, sampled load/release/recovery phases, reading
pause/resumption boundaries, final travel frame, and hero/hostile/guardian
gallery samples. This was sampled frame inspection, not continuous playback.
Renderer initialization settles before recording without advancing the
simulation; no blank first frame is accepted as evidence.

[provenance.json](provenance.json) lists every image and clip, exact hashes,
capture fixture hashes, source freeze checks and encoding limits. PNG pixels
are unchanged; only Origin metadata was embedded. Captures use Godot 4.7.2,
Linux Xvfb and Mesa llvmpipe at native viewport sizes. They establish the
rendered layouts and motion, not physical Android FPS, heat or touch response.

[regression.log](regression.log) is the exact Gameplay Quality CI artifact:
34 Godot suites, 3,642 checks, zero failures and both server checks. See the
[Android validation](../../audit/2026-10-04/android-048/README.md),
[controlled render comparison](../../audit/2026-10-04/render-048/README.md),
[construction direction](../../design/graphics-direction-048.md) and
[rejected figure samples](../../design/figure-source-assessment-048.md).
The fresh independent 0.48 finish review is pending. Successful tests and
packaging do not establish visual acceptance or release readiness.
