# Native65 integration and honest regression evidence

The original logs here retain failed attempts as well as accepted individual stages. Final integration status is recorded separately; a zero process exit never overrides an engine error, failed physical assertion, or rejected renderer diagnostic.

## Actual anatomy and contact regression

The first integrated Character3D run was **168 checks / 24 failures / actual exit 1**. Migrating from the legacy procedural model exposed incorrect fixtures and genuine body defects. The original failed receipts remain in `rejected-round1/`, `rejected-round2/`, and `rejected-round3/`.

The stance oracle now uses the actor's actual `plant_active` side. It does not choose whichever postprocessed foot happens to be lowest. Physical checks still reconstruct every referenced boot vertex through its original four native influences and inverse skin binds, separately for loaded and free feet. The unchanged criteria require world stance drift below 8 mm, loaded soles within 40 mm of the floor, free soles above −35 mm, actual free-foot lift above 70 mm, and more than 30 stable contact samples.

The shared production solver initially shifted the pelvis while solving only the stance leg. It now keeps both native Foot transforms and original knee planes, solves both original chains, and preserves the existing native thigh/calf twist through shortest quaternion swings. This removed the real free-foot penetration; it did not yet remove the loaded Toe error.

The remaining **Guardian frame 41** had `plant_active=[true,false]`: loaded sole **−40.1044451 mm**, free sole **+29.5804832 mm**. The Foot was held while the original animated ball bone kept rotating. The independent audit reconstructs original GLB vertex **177**, weighted **100% to ball_l**, to **−40.1044455613 mm** from the historical engine pose, within **4.9125e−10 m** of the actual trace. Its source Toe key change is **25.3063 degrees**. `independent-toe-audit/` is a genuinely later CPU analysis of the old engine trace, not another engine run or a backdated execution.

The production correction captures original ball/ball_leaf local quaternions at an actual new touchdown and retains them only through that active stance. Free-foot Toes keep their authored animation. No source vertices, inverse binds, bone lengths, per-bone scales, or global lifting offsets were changed.

The actual corrected Character3D stage in `diagnosis/toe-lock-validation/` is **168/0, exit 0**. All eleven weighted boot minima are positive: heroes at least **+3.486 mm**, Guardians at least **+7.623 mm**. Guardian free-foot minimum is **+11.703 mm**, maximum stance drift **1.615 mm**, and maximum free lift **285.306 mm**. SourceAvatar **39/0** and SourceAvatarAttackContact **295/0** also exit 0. That combined receipt itself remains rejected because its subsequent Persistence stage exposed an incorrectly guessed diagnostic exception; its successful individual stages are not a successful full run.

## Native source timing and the real bow defect

The unchanged Death01 clip first rises from the preceding guard pose. At `.22 s`, Vowkeeper, Raider and Bulwark/Elite heads drop only **72.771 / 70.814 / 75.754 mm**; at `.30 s` they drop **253.458 / 260.309 / 278.469 mm**. The fixture records the complete original curve and checks the unchanged 100 mm collapse criterion at one third of the actual `.90 s` collapse, rather than forcing the previous procedural `.22 s` phase.

The bow fixture now starts from the actual `PROJECTILE_RELEASE_LEAD=.085` launch phase; its former `.10` setup preceded the real launch. The string/nock continuity criterion remains **0.1 mm**. That correction exposed a genuine **13.064 mm** early recovery aim-hand movement, beyond the unchanged **8 mm** grip criterion. A second recovery hip dip caused the displacement. Production retains the committed draw load and native draw-hand follow-through while removing only that additional recovery dip. The accepted actual bow metric is **0 mm** string-line, nock-join and grip movement, with **114.886 mm** outward draw-hand motion and the arrow no longer visible.

## QA callers and failure handling

Existing presentation, equipment, authored-art, hostile and Guardian suites now inspect real Native65 named bones, actual bound native clips, visible indexed skin and rigid-prop inventories, and fully weighted figure volume. Export checks require the actual shared fitted garment count **13,460 triangles**, all seven role inventories, JSON runtime dependencies and original license files.

The Android art caller uses the actual AnimationPlayer, named Head bone and schema 2 report. It retains the original 20 steps at 0.05 simulation seconds, at least six bone changes, four distinct rendered captures, more than 0.8 simulation seconds advanced, and original capture positions. Its Python observer independently rejects missing regions, missing scenarios, unbound clips, invalid geometry, and false physical-device performance claims.

The official 53-suite runner rejects engine errors and script/shader/rendering warnings for every suite. The only intentional error exception is exactly two actual Persistence corruption lines: `ERROR: ConfigFile parse error at <string>:0: Unexpected EOF while parsing simple tag.` The original backtraces identify the deliberate two-slot corruption read at persistence_smoke.gd:176. Every observed resource/RID shutdown error and parse error is rejected even when Godot returns zero. The named warning regex covers script/shader/rendering categories; the independent combined evidence verifier additionally rejects every WARNING in its accepted headless logs.

The first external PCK caller failed because its new test helper used `res://tests/` while production exports correctly exclude tests. The QA helper now resolves relative to the external absolute-path caller. Production filters remain unchanged. The subsequent genuine **60/0, exit 0** PCK execution still produced shutdown resource/RID errors and remains rejected; the original verbose logs and isolation callers are retained for the lifecycle diagnosis.

The lifetime isolation keeps every original attempt. The previous 056 caller (32 checks) and unused NativeRig preload are clean. A single actual Hexer build (36 checks) triggers precisely the same 333/302 resource graph when the external fixture globally preloads ClassRig. The same Hexer build and all seven roles are clean when that unused global preload is removed. ClassStyle-only, ClassStyle+ClassRig and all six related `@static_unload` annotations were actually exported and tested; none repaired the failure, so none remains in production.

The complete 60-check external caller succeeds with normal local `load(...).new()` ClassRig ownership, just as the Arcanist already uses. Vowkeeper and Ranger are still genuinely instantiated and audited, then their local owners are released before the existing end-of-frame shutdown. It preserves all production caches, armor/skin geometry and criteria. `diagnosis/pck-lifetime-isolation/full_local_class_script_owner.log` records actual exit 0 and 60/0 without any engine warning or error. The subsequent actual fresh package block passes 60/0 with a clean shutdown; its source scope and the later recovery-order correction are distinguished below.

## Actual sword recovery defect and complete contact coverage

The original full round 4 stopped at its 48th suite: AnimationCraft **55/3, actual exit 1** still required the earlier rootless native SwordA two-foot hop from the production actor. The approved 057 combat stance intentionally holds the original SwordIdle feet while retaining the native upper-body cut. The migrated fixture keeps the unchanged artist-hop criteria on a separate Actor sampled directly through the original SwordA source, independent of production selection, transition and IK: both original weighted boots rise over 100 mm, with original left/right foot travel **824.575 / 510.195 mm**.

The production checks retain **2.9 mm weighted sole clearance**, **8 mm world stance**, exact native Foot release continuity, intermediate and final native guard equality, and the existing criteria for final support at 3 mm and both boots below 20 mm. Those real world checks then exposed a genuine **294.373 mm** recovery foot slide. The actor remained at its original position, scale and yaw; the all-bone recovery settle ran after the stance solve and moved the solved thigh/calf/Foot chain again. `diagnosis/final-continuation2/` and `diagnosis/sword-world-diagnostic/` preserve the original rejected execution and transform trace.

The only production correction moves the existing recovery settle before the existing `hold_cast_soles` and `apply_sword_weight`. It changes no timing, source clip, bind, native rest, scale, anatomical segment or simulation travel. All three real player actions are covered: basic → SwordA, signature → skill/SwordB, sunder → heavy/SwordC. Their actual final maximum world stance drifts are **1.066 / 1.422 / 1.309 micrometres**, well below the unchanged 8 mm criterion; every intermediate recovery Foot transform remains at its actual native guard, and all weighted sole/release/return criteria pass.

The added fresh skill/heavy fixtures initially held their entry transition at zero elapsed time throughout a phase sweep; their original rejected **74/6** attempt is retained in `diagnosis/final-affected-and-continuation/`. Real preparation steps restore the actual transition time, while the separate native-transition suite still covers zero-delta held frames. A subsequent **74/2** rejection is retained in `diagnosis/final-affected-and-continuation2/`: the new B/C height check wrongly assumed frame 0 was their highest preload position. The original measured 31-phase curves show actual preparation height ranges **165.146 / 169.173 mm**, with a later chamber-to-trough descent of **83.160 / 75.534 mm**; they start below that trough. The final fixture retains the Basic start-to-low descent criterion (**74.452 mm actual**, with greater than 5 mm required) and requires the actual B/C preparation range to exceed the same 5 mm physical movement criterion. The complete original curve and the rejected fresh diagnostic are preserved; an upward entry excursion is not relabelled as downward loading.

## Accepted local coverage and its exact limits

`combined-local-coverage.json` verifies original log hashes, actual process statuses, all 53 registered suite names and immutable bindings for 905 files. It records **12,980 unique checks, zero failures** as combined local coverage. The original round 4 remains rejected overall; 41 unaffected historical suites contribute 9,285 checks, and 12 affected or previously unexecuted suites contribute 3,695 checks on the final source. These are deliberately separate source stages: only `scripts/class_avatar_rig.gd` and `tests/animation_craft_smoke.gd` changed between them. This receipt does not claim one complete run of all 53 suites on the final source; uploaded CI supplies that fresh exact-source run.

The final actual execution exits 0 in 138.717 s, with no engine errors or warnings in any of its 12 headless suite logs. All 905 bound inputs have identical before/after hashes, including original license bytes and all asset READMEs. The 41 retained historical logs contain no warnings and no unexpected errors; only the two exactly identified intentional Persistence corruption errors are allowed. The original final execution receipt and raw logs are in `final-validation/`, and source stage hashes are in `final-validation/source-binding.json`.

| Final-source suite | Checks | Failures | Actual exit |
| --- | ---: | ---: | ---: |
| AnimationCraft | 74 | 0 | 0 |
| SourceAvatarAttack | 172 | 0 | 0 |
| SourceAvatarAttackContact | 295 | 0 | 0 |
| SourceAvatarEvade | 1,729 | 0 | 0 |
| NativeMotionTransition | 706 | 0 | 0 |
| ClassAvatarQuality | 398 | 0 | 0 |
| Character3D | 168 | 0 | 0 |
| CampHUD | 44 | 0 | 0 |
| CombatReadability | 57 | 0 | 0 |
| FellowshipUI | 11 | 0 | 0 |
| CloudIdentity | 14 | 0 | 0 |
| ManaWard | 27 | 0 | 0 |

All **59 Python contract tests** pass, as do Node syntax and server progression runtime checks, each with actual exit 0. No Git operation or network service is part of these local tests.

`package-native/` preserves the separately completed validation block for a fresh production PCK (88,141,164 bytes): clean external empty-cwd **60/0** runtime, actual SourceStyle renderer checks **135/0 over 32 poses**, and actual schema 2 four-region Android-art Desktop GL caller. All five commands exit 0. The four roles expose 65 bones, actual named Head and bound clips, 20 changing-bone samples, four distinct motion images and 1.0 s simulation advance each. Actual visible triangle counts are 24,494 / 29,392 / 29,070 / 22,138. Its 20 PNG files are original rendered frames. The renderer is Mesa 25.0.7 llvmpipe under Xvfb, with exactly the two disclosed unsupported-VSync warnings, and no other warning/error. This is real OpenGL buffer readback on a software backend, not hardware-GPU or physical-phone performance evidence. This package/native block preceded the isolated ClassRig method-order fix and is bound to the earlier immutable round 4 source; a new package was not claimed or regenerated afterward. Fresh uploaded CI covers packaging on the exact final source.

## Immutable source commit binding

The final source and 83 approved changed paths were committed as `02a3fc905e55a4e64cbece4eb6b07c65c1bf4afb`, tree `ae378f958570263701f4b80a048766c7723ec882`, after accepted local coverage. `final-validation/commit-binding.json` confirms all 905 original final input hashes still match and their paths exist in that commit. Historical and final execution receipts/source snapshots remain unchanged; this later binding does not convert earlier 41-suite evidence into execution on the final commit. Upload and fresh exact-commit CI results are maintained separately by the Root report.
