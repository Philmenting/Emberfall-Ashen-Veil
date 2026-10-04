# Emberfall 0.47 · Visible combat

Captured implementation: `2648672c4e7700ed57d223bd3a9fb7bf1e874491`,
version `0.47.0-beta.1` / Android code `53`.

[0.46 / 0.47 attack comparison](emberfall-attacks-comparison-046-047.mp4)
places the original gameplay views side by side. Each panel retains its
1200×536 dimensions and 24-second clock; the labels occupy a separate strip.
The source recordings are re-encoded, with no crop or speed change.

| Evidence | Contents |
| --- | --- |
| [Ordinary attacks](emberfall-attacks-047.mp4) | 24 seconds: each class has four seconds of its first fight and four seconds of its first guardian, ordinary gear and actual combat timing. Cuts skip travel only. |
| [Bodies without effects](emberfall-attacks-bare-047.mp4) | 12 seconds: four seconds per class at actual attack speed. Explicit QA fixture hides effects, numbers and markers; this is not a shipping visual setting. |
| [Reading and travel](emberfall-graphics-047.mp4) | 15 seconds: ordinary Arcanist, actual reading pause at 5–8 seconds, resumption, travel and arrival at Pilgrim’s Well. |
| [Model gallery](emberfall-motion-047.mp4) | 24 seconds: native heroes, hostiles and guardians. The gallery uses 650 ms QA windups and does not prove ordinary attack timing. |
| [Portraits](portraits.png) | Live equipped 3D models, including the preserved Nyra face. |

The 33 layout stills cover camp, all three classes, reading, Ward reserve,
four guardians and the performance-report empty state at 2424×1080,
1040×1080 and 854×480. The smallest layout uses Large Text. Guardian stills
raise Life to reach a warning fixture. Performance stills contain no invented
FPS: deterministic capture fixtures disable ordinary wall-clock sampling.

Godot 4.7.2 rendered the native layouts and frame sequences on Linux with
Mesa software rendering. The MP4 files use 30 fixed simulation steps per
second; they are animation evidence, not recordings of physical-phone frame
pacing. Viewing timestamped frames or filmstrips is not continuous playback.

[Provenance](provenance.json) records source and artifact hashes, fixture
limits, dimensions, frame counts and full video decode checks. Still-image
pixels are unchanged; only source-origin PNG metadata was embedded.
[Regression results](regression.log): 34 Godot suites, 3,635 checks, zero
failures, plus server checks.

The initial [evidence check](../../design/graphics-review-047-recapture.md)
found empty initialization frames. The three affected sequences were fully
recaptured after initializing rendering while combat remained frozen. All
ten affected segment starts are now populated. Provenance retains the old
clip hashes and distinguishes the retained still fixtures from the two
corrected capture helpers; game code and assets are unchanged.

The [Android audit](../../audit/2026-10-04/android-047/README.md) records the
exact-source APK/AAB and emulator evidence. The
[same-host comparison](../../audit/2026-10-04/render-047/README.md) records
higher software-renderer frame times for 0.47; it is not a speedup claim.
The
[independent review](../../design/graphics-review-047.md) is the visual
assessment; passing functional checks alone does not establish visual finish
or release readiness.

The complete visual disposition is **`rebuild`**. The reviewer accepts the
corrected evidence and identifies readable sword commitment, stable camera,
complete warnings and repaired UI states. Focal character/material finish,
foreground room joins and ordinary-view cast/bow effort remain insufficient.
This is a reproducible test snapshot without visual beta approval.
