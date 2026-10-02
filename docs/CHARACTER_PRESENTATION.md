# Character motion, compact combat HUD and regional landmarks

This pass improves the existing 0.39 Solo/AFK beta's actual Godot presentation. The primary phone reference is a Google Pixel 9 Pro Fold used closed, in landscape. Desktop GL Compatibility captures at 1200×535 approximate the outside display's 2424×1080 aspect ratio; 1040×1080 covers the almost square inside display. These are rendered game captures, not evidence of physical Pixel performance. Boss fixtures grant extra Life to reach real warning patterns reliably and are not balance or store screenshots.

## Characters and animation

Eleven original Blender figures now have smaller shoulder plates, fitted palms, individually curled fingers and thumbs, refined facial contours and less glossy metals. Fabric, leather, skin and bone have distinct shader material channels. Rebuild source: `tools/art/build_characters.py`.

`scripts/character_rig.gd` bakes each appearance into one shared GPU-skinned surface with 13 bones. Elbows and neck blend across their joints; the mantle tip trails behind the body. Source GLTF part names retain their existing export contract. The weapon follows the right forearm, and shield geometry stays rigid on the left forearm. Each actor has one character surface plus its existing contact shadow, replacing nine independently drawn character parts. Cache sharing and all rest-vertex bind transforms are checked. The animated bounds allow for strikes and falls.

Locomotion blends in and out over approximately 120 ms and follows actual movement speed. Attack anticipation eases in; recovery returns to the rest pose. Hits retain the existing recoil, while death poses also settle elbows, head and mantle. Combat event timing, damage, rewards, collision footprints, RNG and save format remain authoritative in the simulation.

## HUD and regions

Compact combat panels expose Life/Mana, room and pack progress. `DETAILS` expands class, stance, resource/skill status, route map and objective; toggling it preserves the existing arena, camera and combat snapshot. Boss health and countdown warnings occupy the center panel. Android touch heights account for display density and the logical canvas, while safe-area margins remain active. Layout checks cover both panel states with standard and large text at 854×480, 1200×535 and 1040×1080.

Four original rear-wall landmarks add individual silhouettes without blocking the playable floor: broken vault ribs in the Hollow Spire, filled book galleries in the Sunken Archive, a bone reliquary altar in the Crown Ossuary, and a barred furnace throne in the Last Ember Citadel. Rebuild with `blender -b -t 2 --python tools/art/build_landmarks.py`. The four GLTF modules reuse the existing static batching.

## Render budget and performance evidence

Balanced mode initially keeps full resolution and targets 60 FPS. After a six-second warmup, three consecutive two-second windows slower than 24 ms/frame lower only the 3D viewport resolution and disable MSAA. Ten consecutive windows below 18 ms/frame restore full resolution. Paused play and isolated long stalls do not trigger changes. Repeated very slow frames do. Battery remains an explicit half-resolution, 30 FPS mode without shadows or decorative light beams. Adaptive presentation never advances the simulation or changes rewards.

The Android QA fixture now exports `art-performance.json` for all four guardians in Balanced and Battery: 30 rendered frames per scenario, median and 95th-percentile frame time, draw calls, viewport size, platform and renderer. It measures a **frozen guardian render workload**, not live combat responsiveness or sustained thermal behavior. Android CI runs an Android 16 emulator with an outside-display-sized 1080×2424 screen and archives both captures and the report. The shorter probe bounds software-emulator cost; Linux software evidence from the first probe retains its original 90-frame measurements. A `graphics_only` workflow-dispatch option allows repeating art QA after fixture-only changes without repeating already verified AFK/restart behavior. Emulator and software-renderer frame times are not Pixel benchmarks; physical Tensor G4 / ARM64 performance and thermal behavior remain unmeasured.

Latest local checks are recorded in `docs/audit/2026-10-02/presentation-regression.json`. Local software-renderer measurements are in `presentation-software-render.json`, explicitly labeled Linux/llvmpipe. The first Android run passed AFK/restart and rendered three regions without script or shader errors, but its 90-frame probes exceeded the 900-second limit under swangle (roughly 1.8–2.0 seconds per Balanced frame). `presentation-android-partial.json` records this explicitly incomplete evidence. The corrected 30-frame probe is rerun separately; current-head Android evidence is attached to the corresponding GitHub Actions run.

## Actual game captures

| Region | Outside-display aspect | Inside-display aspect |
| --- | --- | --- |
| Hollow Spire | [Guardian](previews/presentation/boss-0-1200x535.png) | [Guardian](previews/presentation/boss-0-1040x1080.png) |
| Sunken Archive | [Guardian](previews/presentation/boss-1-1200x535.png) | [Guardian](previews/presentation/boss-1-1040x1080.png) |
| Crown Ossuary | [Guardian](previews/presentation/boss-2-1200x535.png) | [Guardian](previews/presentation/boss-2-1040x1080.png) |
| Last Ember Citadel | [Guardian](previews/presentation/boss-3-1200x535.png) | [Guardian](previews/presentation/boss-3-1040x1080.png) |

Expanded details: [outside](previews/presentation/details-1200x535.png), [inside](previews/presentation/details-1040x1080.png). Actual hero asset inspections: [Vowkeeper](previews/presentation/vowkeeper.png), [Arcanist](previews/presentation/arcanist.png), [Ranger](previews/presentation/ranger.png).
