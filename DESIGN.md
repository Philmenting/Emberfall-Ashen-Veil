---
name: 'Emberfall: Ashen Veil'
description: 'Grounded dark fantasy: worn spatial materials, animated adult figures and a steady isometric
  combat view.'
colors:
  background-top: '#201c20'
  background-bottom: '#090d12'
  panel: '#171b21'
  panel-light: '#20252c'
  edge: '#41434a'
  bronze: '#d2ad70'
  parchment: '#e7dfd2'
  muted-parchment: '#c3b9a8'
  action-red: '#9e4239'
  positive: '#86ad91'
  selected: '#493b30'
  selected-oath: '#493630'
  focus: '#ffe2a2'
  ink-ground: '#101318'
  life: '#b62c2b'
  mana: '#438e9e'
  arcanist: '#a58ed4'
  ranger: '#83b596'
  arcane-effect: '#79dbdc'
  danger: '#ff6a2e'
  danger-understroke: rgb(4.5% 1.8% 1.2%)
  common: '#c2bcb0'
  uncommon: '#85b497'
  rare: '#81a9d9'
  epic: '#bb86d4'
  legendary: '#e0a35d'
  figure-iron: '#7b8790'
  figure-silver: '#b4bdc0'
  figure-bronze: '#938169'
  figure-gold: '#b09c79'
  figure-patina: '#657f75'
  figure-leather: '#725c4a'
  figure-wine: '#79434d'
  figure-violet: '#596982'
  figure-sage: '#586b59'
  figure-linen: '#b1a58f'
  figure-bone: '#b8b09a'
  nyra-skin: '#bea495'
  figure-ash: '#655f59'
  figure-dark: '#171d23'
  figure-soul: '#78bfb5'
  figure-ember: '#ef984e'
  nyra-hair: '#c0c4bd'
  nyra-hair-shadow: '#686f72'
  nyra-eye: '#c4bbb1'
  nyra-iris: '#4c807d'
  nyra-lip: '#9e6d68'
  nyra-lip-shadow: '#674d46'
  spire-stone: '#747a80'
  spire-edge: '#9d9990'
  spire-dark: '#20272d'
  spire-metal: '#82715a'
  spire-cloth: '#40262b'
  spire-fire: '#ec843b'
  spire-light: '#eaa36c'
  spire-moon: '#cad4de'
  spire-ambient: '#9aaeba'
  spire-fog: '#15212a'
  spire-background: '#080f15'
  spire-mineral: '#384746'
  archive-stone: '#697f78'
  archive-edge: '#8e9d92'
  archive-dark: '#192c2d'
  archive-metal: '#708276'
  archive-cloth: '#243d3c'
  archive-fire: '#6bbfad'
  archive-light: '#83c8b7'
  archive-moon: '#abc8c4'
  archive-ambient: '#72988f'
  archive-fog: '#122728'
  archive-background: '#071316'
  archive-mineral: '#294d40'
  ossuary-stone: '#807d7e'
  ossuary-edge: '#b5ae9e'
  ossuary-dark: '#27242b'
  ossuary-metal: '#9b917c'
  ossuary-cloth: '#452d3c'
  ossuary-fire: '#a99ab9'
  ossuary-light: '#c1afcb'
  ossuary-moon: '#c8c3d5'
  ossuary-ambient: '#958e9d'
  ossuary-fog: '#202029'
  ossuary-background: '#101017'
  ossuary-mineral: '#52435f'
  citadel-stone: '#666464'
  citadel-edge: '#968576'
  citadel-dark: '#272324'
  citadel-metal: '#88705a'
  citadel-cloth: '#472820'
  citadel-fire: '#e47732'
  citadel-light: '#e89553'
  citadel-moon: '#cdbdae'
  citadel-ambient: '#988f8b'
  citadel-fog: '#251b18'
  citadel-background: '#110d0c'
  citadel-mineral: '#503a2c'
  camp-stone: '#727575'
  camp-background: '#29333e'
  camp-ambient: '#b7c4c9'
  camp-fog: '#344047'
  camp-key: '#d6c3a7'
  camp-fill: '#87a2c2'
  camp-hearth-light: '#e2a16a'
  camp-table-light: '#ead0a5'
  portrait-ambient: '#b5c0d0'
  portrait-key: '#e5d5bd'
  portrait-rim: '#a2b2bd'
  world-rim: '#82bed4'
  hero-lantern: '#cad8e5'
  reflection-sky-top: '#354450'
  reflection-sky-horizon: '#a4aaab'
  reflection-ground-bottom: '#172029'
  reflection-ground-horizon: '#535351'
  combat-command: '#151a1e'
  combat-command-hover: '#20282b'
  combat-command-pressed: '#0c1115'
  combat-command-edge: '#49463f'
  combat-command-hover-edge: '#655849'
  spire-court: '#929b9e'
  archive-court: '#84998d'
  ossuary-court: '#b0aaa0'
  citadel-court: '#91867c'
  camp-court: '#a39a8b'
  combat-command-disabled: '#11171a'
  combat-command-disabled-edge: '#343b40'
  combat-command-disabled-text: '#8e969b'
  spire-masonry: '#dddcd7'
  archive-masonry: '#d1ddd4'
  ossuary-masonry: '#e2dbd0'
  citadel-masonry: '#d4c7b9'
  actor-key: '#e0e7e9'
  target-marker: '#9c8763'
  hero-marker: '#6f9892'
typography:
  display:
    fontFamily: Cinzel
    fontSize: 22px
  title:
    fontFamily: Cinzel
    fontSize: 19px
  combat-title:
    fontFamily: Cinzel
    fontSize: 14px
  body:
    fontFamily: Lora
    fontSize: 14px
  label:
    fontFamily: Lora
    fontSize: 12px
rounded:
  ink-ground: 3px
  hud: 4px
  glyph-control: 5px
  control: 10px
  compact-card: 12px
  gear-card: 13px
  overview-card: 17px
  combat-command: 2px
spacing:
  tight: 4px
  action-gap: 6px
  row-gap: 8px
  control-gap: 10px
  section-gap: 12px
  page-inset: 16px
  detail-columns: 18px
components:
  button-primary:
    backgroundColor: '{colors.action-red}'
    textColor: '{colors.parchment}'
    rounded: '{rounded.control}'
    padding: 0 9px
  button-secondary:
    backgroundColor: '{colors.panel-light}'
    textColor: '{colors.parchment}'
    rounded: '{rounded.control}'
    padding: 0 9px
  button-selected:
    backgroundColor: '{colors.selected}'
    textColor: '{colors.parchment}'
    rounded: '{rounded.control}'
    padding: 0 9px
  button-oath-selected:
    backgroundColor: '{colors.selected-oath}'
    textColor: '{colors.parchment}'
    rounded: '{rounded.control}'
    padding: 0 9px
  navigation-control:
    backgroundColor: '{colors.panel-light}'
    textColor: '{colors.parchment}'
    rounded: '{rounded.glyph-control}'
    padding: 0 12px 0 42px
  gear-card:
    backgroundColor: '{colors.panel}'
    rounded: '{rounded.gear-card}'
    padding: 8px 11px
  backup-field:
    typography: '{typography.body}'
    height: 76px
  combat-command:
    backgroundColor: '{colors.combat-command}'
    textColor: '{colors.parchment}'
    rounded: '{rounded.combat-command}'
    padding: 27px 6px 5px
    width: 82px
    height: 60px
  combat-command-hover:
    backgroundColor: '{colors.combat-command-hover}'
    rounded: '{rounded.combat-command}'
  combat-command-pressed:
    backgroundColor: '{colors.combat-command-pressed}'
    textColor: '{colors.bronze}'
    rounded: '{rounded.combat-command}'
  combat-skill:
    backgroundColor: '{colors.combat-command}'
    textColor: '{colors.parchment}'
    rounded: '{rounded.combat-command}'
    padding: 5px 7px
    width: 134px
    height: 60px
  combat-command-disabled:
    backgroundColor: '{colors.combat-command-disabled}'
    textColor: '{colors.combat-command-disabled-text}'
    rounded: '{rounded.combat-command}'
    padding: 27px 6px 5px
    width: 82px
    height: 60px
---

# Design System: Emberfall: Ashen Veil

## Overview

**Creative North Star: "Inhabited dark fantasy ruins"**

The user's complete graphics overhaul and explicit Diablo Immortal reference, recorded in [PRODUCT.md](PRODUCT.md) and the [0.48 continuation contract](docs/design/graphics-direction-048.md), establish mature worn materials, spatial adult figures, a grounded isometric fight and localized light. Soot-dark iron, worn silver, oxblood cloth, wet slate and aged ivory surround original Emberfall characters and regional architecture. The reference sets direction and ambition; it does not establish commercial production equivalence. The superseded bright painterly illustration remains historical evidence. No successful concept seed, separate approved 0.48 composition or supplied QUALITY BAR card is inferred.

Live route-shaped paving, thin deep regional bays with broken tops and eleven lit skeletal figures carry the foreground. Five original generated distant plates provide camp and regional depth. Nyra retains the shared adult face, fitted eyes and lips, pale swept hair and saved equipment identity established in 0.45. The eleven 0.47 figures, their rig, material shader and shared head remain unchanged in 0.48. Both isolated Flare and MPFB/MakeHuman costume proofs were rejected; neither geometry nor textures entered the product. Focal figure reconstruction remains unfinished. The face remains authored geometry with an original generated diffuse patch attached in rest space.

Attacks remain central: the retained CC0 sword foundation is unchanged, while original native cast and bow poses deepen supporting-leg load, pelvis/chest counter-rotation and recovery at the existing release. Arcanist projectiles now originate at the animated left casting palm. The complete 0.48 review observes articulated new poses but still finds ordinary-view whole-body commitment insufficient. A room shot jointly fits pan and distance around stored actor and warning envelopes, then stays anchored through attacks and target changes. The compact native command dock, short state readouts and reading pause keep operational state available. Camp returns the hero to grouped workstations and a live rear corridor.

**Key Characteristics:**

- Shared adult 3D Nyra identity across class, portrait, camp and combat.
- Retained sword commitment and revised native cast/bow support, transfer and recovery at real release timing.
- Shared 0.47 figure geometry and mesh-attached finish, with the unfinished focal-art requirement explicit.
- Thin deep regional bays, broken crests, retained Archive basins and court-aligned paving across the actual route perimeter.
- A steady room shot, complete danger footprints and a compact native command dock.
- Scaled text, native touch sizing, safe-area offsets and a real reading pause.

This is the source-grounded 0.48 implementation record frozen at [850721f](https://github.com/Philmenting/Emberfall-Ashen-Veil/commit/850721fd010dd62ddbf1a6c681f73955ffddc8b3), tree `39f6094bf4db9e481c1ec460d0c3176e9708d1bb`, with release identity (0.48.0-beta.1 / 54). Frontmatter pixels remain base Godot logical UI units; runtime font floors, layout and Android density adjustment still apply. The sidecar's `extensions.native` records spatial, material, animation and evidence data beyond the frontmatter. Native code governs the game; HTML samples remain documentation only. Current sources include [room construction](scripts/ruin_architecture.gd), [room geometry](tools/art/build_ruin_environment.py), [court boundaries](scripts/room_ground.gd), [masonry shader](assets/shaders/masonry_surface.gdshader), [native animation](scripts/character_animation.gd), [bodyphrase provenance](assets/animations/bodyphrase-048/README.md) and the [rejected figure-source assessment](docs/design/figure-source-assessment-048.md).

The [fresh complete 0.48 review](docs/design/graphics-review-048.md) records **disposition: rebuild**. All supplied evidence is valid: persistence and capture checks pass, with no required recapture. The visual ceiling is not reached. Five findings remain: finish the focal skinned bodies and material/texture assets for all eleven figures; rebuild foreground-to-surround transitions and reliquary/prop finish; make cast and bow readable as whole-body phrases on reconstructed figures at the ordinary rear camera; rebalance focal value and material detail so moving bodies read before distant architecture; and obtain sustained frame-time, thermal, battery, touch/Back and inset acceptance on the actual Pixel 9 Pro Fold. Smooth armor/cloth and simplified anatomy remain visibly unfinished, the playable court still reads as a separate cutaway assembly, and cast/bow support remains weak at ordinary size despite distinct new poses.

The review confirms visible improvements in thin broken regional bays, continuous paving through clear openings, visible basin cuts and lower cost in the controlled software-renderer workload. Retain the shared adult Nyra and original guardian emblems, readable sword phrase, native spatial animation, stable camera, complete warnings, restrained class-aware HUD, real reading pause, usable disabled controls and explicit evidence limits. The software result closes only the narrow same-host cost claim. This is the second consecutive rebuild directive after the valid 0.47 review. Under the coordinating Impeccable new-work workflow (§7), a further reconstruction round requires consultation with the user once this result is concrete in commits and the PR; no further round is recorded as begun or completed. The frozen 0.48 result is not finish or release acceptance.

The complete [native packet](docs/previews/constructed-world/README.md) now contains (34) PNGs, (4) fully decoded clips and one derived (24 s) 0.47/0.48 comparison. The [provenance](docs/previews/constructed-world/provenance.json) records (153) frozen source hashes, per-artifact fixture hashes, full-decode/frame-count results and renderer settling without simulation-time advance. The documenter checked those source hashes and all (40) packaged artifact hashes, including the regression log; no rendering or decoding was repeated. Root inspection opened all stills and sampled segment starts, load/release/recovery, reading/resume and gallery frames. This is sampled inspection, not continuous playback. The (15 s / 450 frame) travel clip ends inside the Pilgrim’s Well chamber while still approaching its healing point; it demonstrates neither arrival at that point nor healing. The figure-source rejection leaves focal reconstruction unfinished, with no finish or release acceptance inferred from this package.

All three workflows passed on `850721f`: Gameplay CI [37212951293](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37212951293), Android build [37214678280](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37214678280) and runtime [37214680237, attempt 2](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37214680237/attempts/2). The packaged [regression log](docs/previews/constructed-world/regression.log) records (34) suites, (3642) checks, zero failures and both server checks. The [Android audit](docs/audit/2026-10-04/android-048/README.md) verifies (0.48.0-beta.1 / 54), ARM64, API (36), APK signatures, AAB and (16 KB) ELF alignment. The [test-package archive](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37214678280/artifacts/11307604661) expires on 18 October 2026; `emberfall-closed-beta-ci.apk` is the offline test package, while `emberfall-debug.apk` is the separate online-test build. Signing is CI-only and ephemeral, with no established compatibility with another key or Google Play release.

Runtime attempt (1) ended before emulator testing: the exporter exited (250) after asset import, followed by an ADB daemon connection-refused message. The log establishes that sequence, not its definitive cause. Attempt (2) passed on identical source. The `graphics_only: true` checks cover first fight, real reading pause and Back resume, class relic, protected gear, bag filters, combined oaths, cold restart and all four regions in Balanced/Battery; unchanged AFK reconciliation was not rerun. The probe observed (17/17/12/17) global-pose changes of guardian bone index (3) across (20) steps per region, with four distinct images each; it does not count different changed bones. The root audit decoded and contact-inspected all (28) Android PNGs and opened first-fight and reading originals at full size. Two originals are archived; the rest remain in [runtime artifact 11307984396](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37214680237/artifacts/11307984396). No continuous Android playback is claimed.

The [0.48 Android render report](docs/audit/2026-10-04/android-048/render-performance.json) measures an Android 16/API 36 Pixel 6-profile x86_64 emulator using swangle. Balanced regional medians are (1299.093–1768.492 ms/frame), Battery (549.252–604.609 ms/frame). These establish finite software rendering and advancing animation, not the configured (60/30 FPS) caps. Different CI runs are not a controlled performance comparison; the separate Linux result below supports only its stated same-host workload. Physical phone frame pacing, thermal, battery and input acceptance remain absent.

The completed [same-host 0.47/0.48 comparison](docs/audit/2026-10-04/render-048/README.md) measured lower median frame time in all eight cases: Balanced **44.0–51.1% lower**, Battery **11.8–18.1% lower**. One sequential pair used Godot (4.7.2), Linux Xvfb, Mesa (25.0.7) llvmpipe, the same frozen guardian workload, (30) frames per case and no competing renderer. The [manifest](docs/audit/2026-10-04/render-048/controlled-manifest.json) pins baseline `5fe18fa` and candidate `850721f`. Draw-call counts remain similar; this measures the complete changed room/material pipeline, not an isolated shader microbenchmark. It is a bounded software-renderer improvement, not physical-phone FPS or sustained active-game performance. Do not combine this session with the historical 0.46/0.47 run to invent a controlled 0.46/0.48 result. Pixel 9 Pro Fold frame pacing, heat, battery, touch and system-inset acceptance remain unverified.

The [figure-source assessment](docs/design/figure-source-assessment-048.md) rejects both tested costumes. Flare improved plate separation but retained faceted hands/collar/footwear and patchy leather. MPFB/MakeHuman supplied useful continuous anatomy but left shoulder/neck openings, plain cuffs, coarse folds and unfinished garment panels. Both were isolated native proofs preserving Nyra's head and Emberfall weapons; neither body, texture, shader, rig or runtime import branch was adopted. The eleven existing figures remain production assets. Prototype licenses, triangle counts and successful retargeting do not establish family readiness or final visual quality.

**Historical 0.47 evidence.** The [complete 0.47 review](docs/design/graphics-review-047.md) remains **rebuild** for focal figure/material construction, foreground room joins, ordinary-view cast/bow effort and missing physical-phone performance evidence. It retains the shared face, readable sword, stable camera, complete warnings, real reading pause and corrected disabled UI. The [visible-combat packet](docs/previews/visible-combat/provenance.json) is complete with (34) stills, (4) fully decoded clips and a derived (24 s) 0.46/0.47 comparison. Its three corrected sequences preserve simulation time; the initial [recapture report](docs/design/graphics-review-047-recapture.md) remains archived. All three [Android/gameplay CI runs](docs/audit/2026-10-04/android-047/ci-summary.json) passed on source `2648672`, including (34 / 3635 / 0) regression and server checks. The [controlled 0.46/0.47 workload](docs/audit/2026-10-04/render-047/README.md) was slower in every case: Balanced +47.0–81.3%, Battery +11.0–30.3%. The 0.47 Android software emulator and sampled one-bone pose changes establish only finite rendering/activity, not phone performance. Complete source, CI, signing, pose-counter and performance details remain preserved in the sidecar's historical evidence.

**Historical 0.46 evidence.** The [final 0.46 review](docs/design/graphics-review-046-final.md) remains **rebuild**, following the preserved [earlier review](docs/design/graphics-review-046-rebuild.md). Its open scope was focal figures and attack silhouettes, connected world/material finish, actual-combat separation and disabled Loot. The [scene-finish packet](docs/previews/scene-finish/provenance.json) contains (31) hash-verified native stills and (4) fully decoded MP4s; its regression was (32) suites, (3580) checks, zero failures and passing server checks. Gallery inspection windups and ordinary-speed gameplay remain separately labelled in that archive.

For historical [source 883d65e](https://github.com/Philmenting/Emberfall-Ashen-Veil/commit/883d65eeb304f18aeb999f8ace53d9f359cbf46f), the [0.46 Android CI summary](docs/audit/2026-10-04/android-046/ci-summary.json) records three successful runs and (0.46.0-beta.1 / 52), ARM64, API (36), (16 KB) ELF support. Its `graphics_only: true` runtime covers first fight, reading/Back, relic/equipment/oaths, cold start and four regions in Balanced/Battery; AFK reconciliation was not rerun. The (17/17/12/17) motion counts are changes in the global pose of guardian bone index (3) across (20) steps, with four distinct captured frames per region, not counts of different bones. The root pass decoded (28) PNGs and inspected four contact sheets plus full-size first-fight/reading originals; the old disabled Loot defect remained visible.

The historical [0.46 software-emulator measurements](docs/audit/2026-10-04/android-046/render-performance.json) report Balanced medians (1650.917–1878.671 ms/frame) and Battery (591.786–634.558 ms/frame) on Android 16 / Pixel 6 profile / x86_64 swangle. They establish finite rendering and pose progression, not the configured (60/30 FPS) target. No continuous emulator-video test or physical-phone frame pacing, heat, battery or touch acceptance is established by those checks. New in-memory frame metrics provide a way to collect actual play evidence; their presence is not a measured result. The archived signing is CI-only and ephemeral, with no assumed update compatibility or Google Play publication. Historical 0.47 technical Android results remain separately recorded and do not change this 0.46 visual disposition.

## Colors

The retained interface pairs warm bronze and parchment with layered charcoal. Character materials, regional stages, action state and equipment rarity keep separate roles. Frontmatter colors are extracted source values; light and texture sampling determine their rendered appearance.

### Primary

- **Bronze** marks headings, authored vector strokes and active trim; **action red** marks consequential actions.
- **Selected**, **selected oath** and **focus** distinguish preparation choices and keyboard/controller focus.

### Secondary

- **Arcanist** violet and **Ranger** green identify classes; Vowkeeper uses bronze. **Arcane effect** belongs to the live spell path.
- **Common** through **legendary** color equipment records. Actor accents and recovered world loot retain their own source palettes.
- **Positive**, **life** and **mana** identify actual stat and meter state.

### Tertiary

- **Danger** and **danger understroke** separate the complete active warning from textured ground; the stationary interior hatch remains visible from the earliest countdown.
- Region **fire** and **light** tokens color practical sources. Spire uses warm ember against cold slate, Archive jade against damp stone, Ossuary subdued mauve against aged ivory, and Citadel furnace warmth against ash.

### Neutral

- **Background top/bottom**, **panel**, **panel light**, **edge**, **parchment**, **muted parchment** and **ink ground** retain the native UI roles.
- **Combat command**, its **hover/pressed/disabled** variants and their edge/text tokens supply the compact lower dock. Disabled controls retain the same glyph and caption geometry; focus retains the shared focus treatment.
- **Figure iron/silver/bronze/gold/patina**, **wine/violet/sage**, **leather/linen/bone/ash/dark**, and **Nyra skin/hair/eyes/lips** come from the authored material palette. Material properties remain in `extensions.native.materials.figures`.
- Region **stone**, **edge**, **dark**, **metal**, **cloth** and **mineral** dress geometry; **masonry** tints the architecture-only wall material and **court** tints live paving. Region **ambient**, **moon**, **fog** and **background**, plus camp, portrait, actor-key and reflection tokens, define separate lighting stages. **Target marker** and **hero marker** are quiet nonemissive ground cues.

**The Shared Geometry Rule.** Draw warnings from the same BossPatterns zones used for damage and avoidance; improve separation through material and outline treatment while preserving their active footprint.

**The Material Attachment Rule.** Sample character finish and Nyra's facial patch in immutable mesh rest coordinates; the material must stay attached to the animated surface.

## Typography

**Display Font:** locally bundled Cinzel (`assets/fonts/Cinzel.ttf`). **Body Font:** locally bundled Lora (`assets/fonts/Lora.ttf`). Both ship with SIL Open Font License files. The native theme defaults to Lora; the label helper's `bold` flag selects Cinzel rather than setting a font weight. No synthetic weight or letter-spacing scale is established.

Display serves camp, oaths and seals; title serves preparation page names; combat title serves the compact hero and guardian names; body serves the native theme and prominent copy; label serves smaller operational copy. The compact dock requests smaller base labels through the same scaling helper and minimum, rather than establishing an unscaled text exception. Existing callers use intermediate sizes; frontmatter records representative reused roles.

**The Scaled Type Rule.** Route label and button sizes through `_scaled_font_size`: normal scale (1.0), compact scale (1.2), Large Text scale (at least 1.15, or 1.35 when compact), rounded to integers with a minimum (12). Paragraph helpers wrap; short state labels remain concise. Bundled fonts load offline.

## Layout

The expanding logical canvas is (960 × 540) in landscape. The primary product device is the Pixel 9 Pro Fold closed outer display (2424 × 1080). Native capture classes are that size, unfolded near-square (1040 × 1080), and compact Large Text (854 × 480). Moving evidence uses an outer-aspect proxy (1200 × 536). These are capture classes, not three hard-coded layout breakpoints.

Preparation pages use vertical scrolling, page inset plus translated Android safe-area offsets, and persistent navigation. Native compact sizing activates at logical width at most (960) or height at most (600); desktop fixtures use window width (960) or height (540). The shared minimum-button helper starts at (48), increases to (52) when compact and (58) with compact Large Text, and applies Android density correction for the (48 dp) target. Physical touch and system-inset acceptance remain unmeasured.

Combat groups the actual signature/technique tiles and Auto, Details, Repeat and Loot in one centered command dock. Two short centered strips above it carry activity and chamber/objective state. The renderer reserves their actual laid-out top edge; unlaid-out container origins never drive framing. Skill tiles and commands use a requested minimum height (60), then the shared native minimum helper. The reading sheet stacks into one column when compact or when aspect is below (1.35), and uses two columns otherwise.

The perspective room shot jointly searches pan and distance against the usable HUD rectangle. It reserves room-floor corners, hero/weapon space, hostile volumes and all three guardian phases with both warning variants. The initial envelope, pan and distance are stored for the shot; an unexpected real warning can only widen it. Room/travel transitions, an aspect change over (0.01), or a HUD bottom-reserve change over (0.003) trigger refitting. Travel uses an envelope relative to the current route anchor. Detailed solver values belong in `extensions.native.camera`.

The court retains a disjoint rectangular cover of the route envelope grown by (0.72 m) and a (0.86 m) foundation. `RoomGround.boundary_edges()` now removes shared edge portions, including T-junctions, so internal rectangle seams generate no foundation sides. Low paving/masonry joins follow the exposed outer union, skip Archive basin boundaries and stop before overlapping a re-entrant court. Bay paving uses the identical court material at the threshold. Only actual Archive basins cut the court; Citadel fire remains inside raised structures. New room placement forms a (26.20 m) rear run, an (11.50 m) left aisle and an (8.70 m) low camera-side return. Each bay carries its own rear gallery; crowns no longer span route crossings. Actual transformed standing-height bounds preserve the route, and final dressing clearance remains (0.20 m). Camp retains fixed world-space workstations, projected labels and overlap/bottom-tray clamping, with its existing rear corridor.

**The Clear Passage Rule.** Derive tall dressing clearance and channel cuts from the generated floor and passage envelope; keep openings full height and remove whole obstructing props before static batching.

**The Steady Shot Rule.** Store the fitted room pan and distance through hits, casts and target changes; follow travel smoothly and widen only to preserve the complete reserved geometry.

## Elevation & Depth

UI depth comes from tonal layering, fine borders and ink grounds. Reusable panels and buttons establish no drop-shadow vocabulary. Cinzel labels retain their subtle native black shadow color. World depth comes from live floor and masonry geometry, lit opaque figures, contact shadows, reflection colors, fog and distant generated plates.

[Architecture masonry](assets/shaders/masonry_surface.gdshader) now binds one color/normal/roughness texture stack per material family. Bricks096 supplies `masonry`; retained Rock030 supplies `dressed_stone`. Exported signed planar UVs are measured in local metres, and glTF tangents let the vertex stage compensate for module stretch. The repeat remains (2.8 × 1.4 m) for masonry and (1.4 × 1.4 m) for dressed stone. One family no longer samples and blends separate wall/cap stacks in each fragment. Both use chroma mix (0.35), dampness (0.32), roughness bias (0.08) and specular (0.28); relief is (0.80 / 0.38) respectively and zero in Battery. The normal lookup is skipped when relief is at most (0.01). Bricks096 remains external CC0 height-field photogrammetry with an art-directed repeat, not a measured physical scale. The [source manifest](assets/materials/masonry/manifest.json) preserves its original pixels and license; current runtime mapping is defined by the shader and architecture source.

[Weathered stone](assets/shaders/weathered_stone.gdshader) retains Rock030 for camp and other stone surfaces, now sampling the dominant world axis rather than blending three projections. Broad runoff, footing stains and vertex tint remain. Both stone shaders reconstruct compressed normal Z from red/green. [Ruin paving](assets/shaders/ruin_floor.gdshader) keeps the original generated diffuse floor with separate retained mineral/normal detail and regional weathering. [Crafted surfaces](assets/shaders/crafted_surface.gdshader) keep the original oak/leather/linen/steel atlas. Character finish remains attached to immutable rest coordinates; cloth, leather and bone use restrained color variation with separate roughness/specular limits. This material separation is intentional: the new masonry maps do not replace the floor, camp or character palette.

Sixteen original Blender room modules now provide `bay`, `bay_broken`, narrow remnant and low return for each region. Thin enclosing walls, deep reveals and surviving uneven crests replace the capped bay boxes. Spire retains a bell bay and rear gallery; Archive has raised book banks, a retained basin, bridge and sluice; Ossuary uses two levels of deep burial cells and attached funerary construction; Citadel recesses a grated furnace below narrow maintenance walks and open flues. Alternating broken bays vary the surviving edge. Individual modules contain (334–5262) triangles across at most (5) material meshes; these counts describe construction, not finish acceptance. Archive water remains (0.39 m) below module origin, Citadel fire (0.13 m) above it. Existing textures and original geometry remain the material provenance; no source-proof figure or new raster material enters these modules.

World, camp and portrait retain the reflection sky and filmic tone mapping. Dungeon plates now receive explicit regional haze at `1 - exp(-fog_density * 75)` while the camp plate retains zero added haze. A directional character key at energy (0.62), rotation (−34°, 32°, 0°) and cull mask (2) lights actor models on layer (2). The world moon uses one orthogonal room shadow. Battery removes that shadow, world floor relief and world/camp masonry relief, reduces resolution/MSAA, and suppresses sanctuary beams, extra lights and transient contact dust/light; camp paving retains its default relief. These are source-defined presentation settings, not sustained phone-performance results.

## Shapes

Preparation controls retain their established rounded native corners; combat commands and skill tiles use tighter corners. Panel borders are (1), focus borders (2), and shared panel content margins are (11 horizontal, 8 vertical). Frontmatter records reused corner and spacing values; larger gear and overview cards keep their incumbent shapes.

Nyra's continuous adult head, fitted almond eyes, modeled eyelids, lip seam, hairline and swept silver locks retain their established geometry and albedo. The retained 0.47 [body construction](tools/art/CHARACTER_ASSETS_047.md), unchanged in 0.48, uses continuous shoulder-to-wrist limbs, tapered palms with curled fingers, longitudinal toe/ball/instep/heel boots, open greaves and vambraces, small knee flanges and shaped cuirass/backplates. Vowkeeper has a short split surcoat and fitted shoulder layers; Arcanist has separate long side gores, a narrow rear drape and short cape; Ranger has a short asymmetric cape and open tunic. Raider's continuous thorax carries embedded ribs, sternum and clavicles; hostile skulls use continuous cranium/jaw geometry with facial planes. These remain original numerical Blender constructions with simplified stylized surfaces. The complete 0.47 review found their anatomy, garment construction and worn finish insufficient, and 0.48 has not replaced those assets. Both external costume proofs were rejected; none of their anatomy, weights, textile maps or material derivatives is shipped. The unchanged shared Nyra face is not a new class-specific identity.

**The Shared Face Rule.** Use the same live class/equipment geometry for portrait, camp and combat; inspect the lit head as well as its texture, and preserve the adult face through all three class views.

## Components

### Buttons and navigation

`_button` provides the shared fill, parchment type, corners and focus system. Preparation hover lightens its supplied fill (0.12); press darkens it (0.10), changes type to bronze and emits the UI sound cue. Disabled text uses muted parchment. `_glyph_button` supplies authored vector strokes at a nominal size (24); icon-only controls adjust the inset. Preparation navigation uses the same helpers and selected fill.

Combat commands use `_combat_command` and `_style_combat_command`: tight native corners, separate command/hover/pressed fills, shared focus, and a centered authored vector above the caption at size (20). Skill tiles use the same state treatment with a name, status and cooldown track. Requested command widths are (82), with Auto (90) and Repeat (100); skill tiles request (134). Native content and touch minimums take precedence over these requests. Disabled command styles now duplicate the complete normal style before applying their own fill, border and text colors, retaining the (27 top / 6 horizontal / 5 bottom) margins and glyph position. The complete 0.48 review confirms understandable disabled Loot state, focus and command geometry; the overall finish disposition remains rebuild.

### Gear and preparation cards

Gear rows and cards use panel fill, rarity-derived borders and the gear-card radius, showing actual slot, protection, temper and comparison state. Overview panels use the broader radius. The hero preview shares `DungeonActor` and saved equipment with combat and camp; six equipped slots alter constrained quality accents. Weapon art changes with class. An item name does not imply its own unique model.

### Oath controls

Three native buttons select zero, one or two oaths. Selection changes fill and adds `ON`; at two, the remaining unselected button is disabled. Start remains disabled with zero. Preparation displays actual selected risks, rewards and class/set synergies. Existing checkpoints retain their frozen rules.

### Meters and fields

Life/mana/guardian bars use a dark native track and softly rounded fill. Backup fields are native wrapping `TextEdit` controls with a minimum height (76), inherited Lora and engine default field chrome. They do not establish a separate branded input treatment.

### Combat readouts and inspection

The dock shows the equipped signature and actual techniques from the frozen expedition, each with its name, CASTING / remaining cooldown / LOW MANA / READY and an actual cooldown track. Class and technique colors identify tracks; words carry state independently of color. Tapping a skill opens its rule in Details and pauses live combat. Close or Back restores the previous active/manual-pause state; Resume explicitly continues. Reading state survives layout rebuilds, and saves retain the underlying active intent.

Activity and chamber/objective strips sit above the dock. Living reinforcements count as foes remaining; guardian completion still requires recovering the reliquary. Guard duration and Mana Ward's active/reserve state appear under Nyra's meters. Lost Life leaves a bronze trace for (0.18 s), then settles over (0.42 s). Healing clears it, inspection pauses it, and Reduced Motion removes its movement. No screen flash or camera impulse accompanies it. The scrollable reading sheet keeps skill selection, Close and Resume reachable in its one- or two-column layout.

**The Combat Inspection Rule.** Show automatic skill state in words and cooldown tracks from the frozen expedition. Reading temporarily pauses live time: Close or Back restores the player's prior active/manual-pause intent, while Resume explicitly continues. Layout rebuilds and saves must preserve that intent.

### Actors, phases and motion

Eleven spatial figures comprise three Nyra classes, four hostile kinds and four regional guardians. Each uses twenty-nine native bones, nine AnimationPlayer clips and one cached opaque skinned surface (at most 40,000 triangles), plus a contact shadow. Original geometry comes from `tools/art/build_characters.py` and `tools/art/build_body_047.py`, with Nyra's established head in `tools/art/build_faces.py`; meshes, skin bindings and clip libraries are cached per appearance. Vowkeeper now uses selected CC0 Quaternius Standard Universal Animation Library 1/2 sword curves baked and retargeted offline into the existing native rig. The source mannequin is not shipped as a runtime actor, and no motion-capture provenance is claimed. Arcanist, Ranger and hostile phrases remain authored native animation. Distance-driven alternating steps and leg IK retain supporting soles, including backward travel.

Vowkeeper retains its existing source chamber/stroke/return mapping, shield brace and blade-floor wrist correction. Arcanist opens the left step while loading the right leg, coils the chest against the pelvis, turns the hips into a forward palm throw and catches it on the front knee; signature delivery is higher. Ranger widens the left step, sinks over rear support, resists the chest draw with the hips and holds support briefly after release before returning. The right hand still follows the moving nock. Forward free-foot travel is (0.64 m) on Vowkeeper’s right, (0.34 m) on Arcanist’s left and (0.28 m) on Ranger’s left, with lateral offsets retained in the sidecar. The opposite foot remains planted; runtime leg IK follows the same action-foot curve and sole basis. Local articulation does not move the actor’s simulation root. Delayed cloth and target-facing head behavior remain unchanged.

Hero windup follows the real pending cast, including the existing basic (0.30 s) clock. Melee release follows the actual hit; ranged visual release begins up to (0.085 s) before the unchanged damage event, and its windup is mapped to that earlier release. Arcanist now takes the launch point from the animated left-hand bone (index 7) on the actual release frame; Ranger retains its bow origin. A normal ranged preparation therefore reaches release at (0.215 s), although a (30 FPS) proof first samples that threshold at (0.233333 s). Recovery remains (0.34 s), with a later actual cast allowed to interrupt. Guardian preparation follows the full warning countdown, including restored checkpoints; ordinary hostile anticipation follows its real preparation window. Retreat cancels an uncommitted cast. Impact reactions compress the affected body while retaining the attack priority and world stance.

Defeat buckles the knee and turns pelvis, shoulder and head before cloth settles over (0.90 s). Normal nonboss fallen visuals stop displaying at (2.15 s); boss corpses remain until existing world cleanup. This is presentation lifetime, not a change to death or rewards. Floating combat text lasts (0.70 s), rises at (0.65 m/s), and fades from (0.38 s). Contact light/dust are transient details; native movement and pose remain the basis of the attack.

**The Supported Action Rule.** Author leg, pelvis, chest, hand and weapon as one phrase at the actual release; coordinate the planted support foot and explicit free-foot curve through load, contact and recovery without changing the simulation clock.

The camera has no impact shake in either mode. Reduced Motion freezes decorative idle sway and suppresses displacement reactions while retaining essential steps, windups, contacts, falls, hit flash, countdown and warning information. Battery caps the engine at (30 FPS); Balanced caps it at (60 FPS). Visible portrait animation samples at up to (24 Hz), requesting a single viewport redraw for each new pose and retaining the texture between samples; Battery or Reduced Motion render once on setup or change. Reduced Motion freezes camp portal curl and dungeon fluid time. Configured limits are not measured sustained device results.

### Live portrait and face material

HeroArt renders the equipped actor in a transparent orthographic SubViewport. The camera targets the animated Head-bone anchor and uses the established face crop; portrait-only weapon exclusion keeps equipment from crossing it. The sidecar retains crop, render-size clamps, update cadence and lights. Full-body preparation uses its separate formula. Setup, quality changes and resize request `UPDATE_ONCE`; hidden previews do no animation work, and ordinary visible previews request another single render only when their (1/24 s) pose sample advances. The facial diffuse patch uses measured image landmarks on immutable rest coordinates; it is neither a scanned likeness nor a separate painted portrait and adds no expression animation or lip sync.

### Device performance readout

The beta settings page exposes DEVICE PERFORMANCE and an explicit COPY PERFORMANCE REPORT action. `FrameMetrics` samples monotonic wall-clock frame intervals only while the battle renderer is active, visible and unpaused, with a (2 s) warmup after entry, context change or resume. Each class/region/quality/resolution case keeps a ring of at most (1800) frames; at most (8) recent cases remain in memory. Reports include median, p95, worst frame, mean FPS and counts above (33.334 ms) and (50 ms). The clipboard action adds release identity and is disabled without data; no automatic upload or persistence is introduced. Battle rendering uses `UPDATE_WHEN_VISIBLE`. These helpers collect evidence during actual play and do not certify a configured FPS cap.

### Camp and protective surfaces

The forge's hearth, anvil, tools and bellows, the table's map, folio and candle, and four carved seal mounts remain authored 3D objects. Added rubble, bundles, deposits and light connect these station groupings to the paving. Repeated arches and wall courses continue behind the rear opening; the portal's original Gothic arch is joined to masonry and carries its native additive veil. Station actions project from fixed world anchors. Guard segments and the Mana Ward shell appear only for their actual simulation state.

**The Earned State Rule.** Camp seals appear only for saved guardian trophies. Class, equipment, guardian phase and warning cues come from real preparation or simulation state.

## Do's and Don'ts

### Do:

- **Do** use the authorized worn dark-fantasy material world, original regional construction and shared adult 3D Nyra identity.
- **Do** carry native attack effort through the legs, hips, torso and weapon while preserving actual release timing and supported feet.
- **Do** derive complete warning geometry, tall-dressing clearance and fluid cuts from the authoritative simulation and generated route.
- **Do** keep camera, portrait, stage-light and material values aligned with their native source tokens.
- **Do** use shared scaled-font, minimum-control and safe-area helpers while preserving the real reading-pause intent.
- **Do** distinguish original geometry and generated diffuse assets from licensed external materials/animation, and label renderer fixtures and physical-device evidence by their actual source.

### Don't:

- **Don't** restore the superseded bright painterly world or replace live faces with painted portrait substitutes.
- **Don't** place tall masonry or sliced props across the authoritative passage, or use visibility culling as its repair.
- **Don't** add camera shake, alter simulation attack clocks for a visual phrase, or invent warning footprints that disagree with damage geometry.
- **Don't** show unearned seals, imply a unique model for every item, or claim motion capture, facial-expression or lip-sync animation that is absent.
- **Don't** reduce text or controls to force a compact layout, or infer visual approval, physical-device performance or release acceptance from renderer captures and test counts.
