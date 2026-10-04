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
  figure-iron: '#657381'
  figure-silver: '#b4bdc0'
  figure-bronze: '#78664f'
  figure-gold: '#b09c79'
  figure-patina: '#50736b'
  figure-leather: '#382b27'
  figure-wine: '#50272f'
  figure-violet: '#343c55'
  figure-sage: '#304039'
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
---

# Design System: Emberfall: Ashen Veil

## Overview

**Creative North Star: "Inhabited dark fantasy ruins"**

The user's complete graphics overhaul and explicit Diablo Immortal reference, recorded in [PRODUCT.md](PRODUCT.md) and the [0.46 direction contract](docs/design/graphics-direction-046.md), establish mature worn materials, spatial adult figures, a grounded isometric fight and localized light. Soot-dark iron, worn silver, oxblood cloth, wet slate and aged ivory surround original Emberfall characters and regional architecture. The reference sets direction and ambition; it does not establish commercial production equivalence. The superseded bright painterly illustration remains historical evidence. No successful concept seed, separate approved 0.46 composition or supplied QUALITY BAR card is inferred.

Live continuous paving, chipped masonry, region-specific construction and eleven lit skeletal figures carry the foreground. Five original generated distant plates provide camp and regional depth. Nyra retains the shared adult face, fitted eyes and lips, pale swept hair and saved equipment identity established in 0.45. The 0.46 construction pass changes armor shells, limbs and garments around that identity; it adds no facial-expression or lip-sync rig. The face remains authored geometry with an original generated diffuse patch attached in rest space.

Attacks are central to this iteration: native sword, directed cast and bow phrases pass through supported body load, contact and a distinct recovery at the existing simulation release. A room shot jointly fits pan and distance around stored actor and warning envelopes, then stays anchored through attacks and target changes. The compact native command dock, short state readouts and reading pause keep operational state available. Camp returns the hero to grouped workstations and a live rear corridor.

**Key Characteristics:**

- Shared adult 3D Nyra identity across class, portrait, camp and combat.
- Distinct supported sword, casting and bow phrases on native skeletal clips.
- Worn shells, shaped cloth and continuous limbs with finish attached to the mesh.
- Live regional masonry, cut channels and continuous ground around the authoritative route.
- A steady room shot, complete danger footprints and a compact native command dock.
- Scaled text, native touch sizing, safe-area offsets and a real reading pause.

This is the source-grounded 0.46 implementation record after the review-directed reconstruction and final camp label relocation. Frontmatter pixels are base Godot logical UI units; runtime font floors, layout and Android density adjustment still apply. The sidecar's `extensions.native` records spatial, material, camera, animation and evidence data that the frontmatter cannot represent. Native code governs the game; the sidecar's HTML controls are documentation samples. Sources include [main.gd](scripts/main.gd), [DungeonWorld](scripts/dungeon_world.gd), [RuinArchitecture](scripts/ruin_architecture.gd), [CampScene](scripts/camp_scene.gd), [CharacterAnimation](scripts/character_animation.gd), [DungeonActor](scripts/dungeon_actor.gd), [character geometry](tools/art/build_characters.py) and the native material shaders.

The [fresh final 0.46 review](docs/design/graphics-review-046-final.md) records **disposition: rebuild**. It requires further work on focal figure and attack silhouettes, connected world construction and material finish, visual separation at actual combat scale, and the disabled Loot state. The preceding review remains preserved in [graphics-review-046-rebuild.md](docs/design/graphics-review-046-rebuild.md). This concrete candidate is frozen for testing and draft PR review; it is not visually accepted.

The complete packet of (31) native stills and (4) MP4s is packaged in [scene-finish/provenance.json](docs/previews/scene-finish/provenance.json): the packaging pass verified hashes and full video decoding, and the final reviewer independently found no source/artifact hash mismatch. The gallery uses longer inspection windups; ordinary combat, effects-hidden QA, and reading/travel retain their separately labelled timing and equipment boundaries. The [local regression](docs/previews/scene-finish/regression.log) records (32) Godot suites, (3580) checks, zero failures and passing server tests. Current measurements are in [character-geometry.json](docs/previews/scene-finish/character-geometry.json), [attack-effort.json](docs/previews/scene-finish/attack-effort.json) and [framing-gain.json](docs/previews/scene-finish/framing-gain.json).

Android CI is complete for [source commit 883d65e](https://github.com/Philmenting/Emberfall-Ashen-Veil/commit/883d65eeb304f18aeb999f8ace53d9f359cbf46f); the [CI summary](docs/audit/2026-10-04/android-046/ci-summary.json), [build/regression checks](docs/audit/2026-10-04/android-046/build-and-regression-checks.txt) and [runtime checks](docs/audit/2026-10-04/android-046/runtime-checks.txt) record three successful runs. Gameplay retains (32) suites, (3580) checks, zero failures and passing server rules; packaging verifies version (0.46.0-beta.1 / 52), ARM64, API (36) and (16 KB) ELF page support. The `graphics_only: true` runtime checks cover first combat, the real skill-reading pause and Back resume, class relic/gear protection/bag filters/combined oaths, cold restart, and four regions in Balanced and Battery. Over (20) simulation steps per region, the probe observed (17/17/12/17) changes in the global pose of guardian bone index (3), with (4) distinct native images per region; these counts are pose changes of one sampled bone, not counts of different bones. AFK reconciliation was not rerun.

The [render measurements](docs/audit/2026-10-04/android-046/render-performance.json) came from the Android 16 Pixel 6-profile x86_64 emulator using swangle software rendering: Balanced regional medians were (1650.917–1878.671 ms/frame), Battery (591.786–634.558 ms/frame). This establishes finite measurements and advancing native rendering/animation, not achievement of the configured (60/30 FPS) caps. The root verification pass decoded all (28) PNGs and inspected four contact sheets, plus full-size first-fight and reading originals; the disabled Loot defect remains visible. No continuous emulator-video test or physical-phone frame pacing, heat, battery or touch acceptance is established. The final visual disposition remains **rebuild**. Artifacts use CI-only ephemeral signing, do not establish update compatibility with earlier signing keys, and are not a Google Play release.

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
- **Combat command**, its **hover/pressed** variants and its **edge/hover edge** supply the compact lower dock. Focus retains the shared focus treatment.
- **Figure iron/silver/bronze/gold/patina**, **wine/violet/sage**, **leather/linen/bone/ash/dark**, and **Nyra skin/hair/eyes/lips** come from the authored material palette. Material properties remain in `extensions.native.materials.figures`.
- Region **stone**, **edge**, **dark**, **metal**, **cloth** and **mineral** dress repeated geometry; **court** tints the shared live paving. Region **ambient**, **moon**, **fog** and **background**, plus camp, portrait and reflection tokens, define separate lighting stages.

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

A court mesh extends through the live rooms. Archive and Citadel channel holes are cut from that mesh using the same rectangles as the fluid geometry; the cut excludes generated walking rectangles with extra clearance. Tall construction is checked against `Layout.floor_rects()` with a clearance margin (0.20 m). Entire obstructing props are removed before static batching. Camp retains fixed world-space workstations, projected labels and overlap/bottom-tray clamping; its rear opening continues along actual paving and masonry into a corridor.

**The Clear Passage Rule.** Derive tall dressing clearance and channel cuts from the generated floor and passage envelope; keep openings full height and remove whole obstructing props before static batching.

**The Steady Shot Rule.** Store the fitted room pan and distance through hits, casts and target changes; follow travel smoothly and widen only to preserve the complete reserved geometry.

## Elevation & Depth

UI depth comes from tonal layering, fine borders and ink grounds. Reusable panels and buttons establish no drop-shadow vocabulary. Cinzel labels retain their subtle native black shadow color. World depth comes from live floor and masonry geometry, lit opaque figures, contact shadows, reflection colors, fog and distant generated plates.

[Weathered stone](assets/shaders/weathered_stone.gdshader) samples retained ambientCG Rock030 color, roughness and normal maps by world-space triplanar projection. Broad runoff crosses joints; footing stains darken lower courses. Compressed normal Z is reconstructed from red/green. [Ruin paving](assets/shaders/ruin_floor.gdshader) uses an original generated diffuse floor image, mirrored in world space, with separately sampled retained mineral/normal detail, regional dampness/ash and quieter perimeter wear. This is neither a photogrammetric floor nor an authored PBR map set. [Crafted surfaces](assets/shaders/crafted_surface.gdshader) sample the original oak/leather/linen/steel atlas within mirrored cell bounds. Character wear uses that atlas and retained Metal063 grain/roughness in rest space; cloth uses restrained color variation, high roughness and lower specular.

Hollow Spire has massive bell piers and a rear load-bearing arch. Drowned Archive has a thick retaining wall, raised library niche and an exposed water channel. Glass Ossuary has deep burial openings with inset tombs and doubled transverse ribs. Cinder Citadel has a furnace shell, battered flue, black-iron cross-bracing and a molten channel with short maintenance grates. These systems share chipped masonry meshes, unequal courses and footing deposits while keeping distinct construction. Fluid surfaces sit below the walking plane with visible banks around actual court openings.

The world, camp and portrait share the authored reflection sky and filmic tone mapping; their practical lights retain separate stage tokens. Battery removes the main shadow, world floor relief and world/camp masonry relief, reduces resolution/MSAA, and suppresses world sanctuary beams, extra sanctuary lights and transient contact dust/light. The camp paving shader retains its default floor relief. These are source-defined presentation settings, not sustained phone-performance results.

## Shapes

Preparation controls retain their established rounded native corners; combat commands and skill tiles use tighter corners. Panel borders are (1), focus borders (2), and shared panel content margins are (11 horizontal, 8 vertical). Frontmatter records reused corner and spacing values; larger gear and overview cards keep their incumbent shapes.

Nyra's continuous adult head, fitted almond eyes, modeled eyelids, lip seam, hairline and swept silver locks are unchanged by the 0.46 figure reconstruction. Armor uses thin forged front shells, open returns, articulated shoulder plates and restrained joint caps over continuous sleeves and shaped boots. Garments use fitted collars, tailored drape and overlapping front gores with actual thickness; narrower cape and cloth forms follow the existing bones. Hostile arms use continuous anatomical sections. These are implementation facts; the final review still requires a rebuild of focal figure and material finish.

**The Shared Face Rule.** Use the same live class/equipment geometry for portrait, camp and combat; inspect the lit head as well as its texture, and preserve the adult face through all three class views.

## Components

### Buttons and navigation

`_button` provides the shared fill, parchment type, corners and focus system. Preparation hover lightens its supplied fill (0.12); press darkens it (0.10), changes type to bronze and emits the UI sound cue. Disabled text uses muted parchment. `_glyph_button` supplies authored vector strokes at a nominal size (24); icon-only controls adjust the inset. Preparation navigation uses the same helpers and selected fill.

Combat commands use `_combat_command` and `_style_combat_command`: tight native corners, separate command/hover/pressed fills, shared focus, and a centered authored vector above the caption at size (20). Skill tiles use the same state treatment with a name, status and cooldown track. Requested command widths are (82), with Auto (90) and Repeat (100); skill tiles request (134). Native content and touch minimums take precedence over these requests.

### Gear and preparation cards

Gear rows and cards use panel fill, rarity-derived borders and the gear-card radius, showing actual slot, protection, temper and comparison state. Overview panels use the broader radius. The hero preview shares `DungeonActor` and saved equipment with combat and camp; six equipped slots alter constrained quality accents. Weapon art changes with class. An item name does not imply its own unique model.

### Oath controls

Three native buttons select zero, one or two oaths. Selection changes fill and adds `ON`; at two, the remaining unselected button is disabled. Start remains disabled with zero. Preparation displays actual selected risks, rewards and class/set synergies. Existing checkpoints retain their frozen rules.

### Meters and fields

Life/mana/guardian bars use a dark native track and softly rounded fill. Backup fields are native wrapping `TextEdit` controls with a minimum height (76), inherited Lora and engine default field chrome. They do not establish a separate branded input treatment.

### Combat readouts and inspection

The dock shows the equipped signature and actual techniques from the frozen expedition, each with its name, CASTING / remaining cooldown / LOW MANA / READY and an actual cooldown track. Class and technique colors identify tracks; words carry state independently of color. Tapping a skill opens its rule in Details and pauses live combat. Close or Back restores the previous active/manual-pause state; Resume explicitly continues. Reading state survives layout rebuilds, and saves retain the underlying active intent.

Activity and chamber/objective strips sit above the dock. Living reinforcements count as foes remaining; guardian completion still requires recovering the reliquary. Guard duration and Mana Ward's active/reserve state appear under Nyra's meters. Lost Life leaves a bronze trace for (0.18 s), then settles over (0.42 s). Healing clears it, inspection pauses it, and Reduced Motion removes its movement. No screen flash or camera impulse accompanies it. The scrollable reading sheet keeps skill selection, Close and Resume reachable in its one- or two-column layout. The final review identifies a disabled Loot defect while reading: its filled surface disappears and its glyph overlaps the caption. This remains an open defect, not a reusable disabled-state treatment.

**The Combat Inspection Rule.** Show automatic skill state in words and cooldown tracks from the frozen expedition. Reading temporarily pauses live time: Close or Back restores the player's prior active/manual-pause intent, while Resume explicitly continues. Layout rebuilds and saves must preserve that intent.

### Actors, phases and motion

Eleven spatial figures comprise three Nyra classes, four hostile kinds and four regional guardians. Each uses twenty-nine native bones, nine AnimationPlayer clips and one cached opaque skinned surface (at most 40,000 triangles), plus a contact shadow. Original geometry comes from `tools/art/build_characters.py`, with Nyra's established head in `tools/art/build_faces.py`; meshes, skin bindings and clip libraries are cached per appearance. The 0.46 attack phrases are newly authored within the existing clip contract. They are not motion capture. Distance-driven alternating steps and leg IK retain supporting soles, including backward travel.

Sword phrases gather, load the rear leg/hip, drive the pelvis before the chest, pass through contact, follow through and return on a distinct path. Casting directs the hand and staff forward with body compression and counter-rotation. Bow motion raises and nocks, draws to the cheek, holds, releases, recoils and lowers; the left hand holds the bow and the right hand follows the actual moving nock. Supported stance targets stay fixed through guard and attack, with runtime leg correction preserving authored knee planes. Delayed cloth follows the body; the head retains the target while torso and hips turn.

Hero windup follows the real pending cast, including the existing basic (0.30 s) clock. Melee release follows the actual hit; ranged visual release begins up to (0.085 s) before the unchanged damage event, and its windup is mapped to that earlier release. Recovery remains (0.34 s), with a later actual cast allowed to interrupt. Guardian preparation follows the full warning countdown, including restored checkpoints; ordinary hostile anticipation follows its real preparation window. Retreat cancels an uncommitted cast. Impact reactions compress the affected body while retaining the attack priority and world stance.

Defeat buckles the knee and turns pelvis, shoulder and head before cloth settles over (0.90 s). Normal nonboss fallen visuals stop displaying at (2.15 s); boss corpses remain until existing world cleanup. This is presentation lifetime, not a change to death or rewards. Floating combat text lasts (0.70 s), rises at (0.65 m/s), and fades from (0.38 s). Contact light/dust are transient details; native movement and pose remain the basis of the attack.

**The Supported Action Rule.** Author leg, pelvis, chest, hand and weapon as one phrase at the actual release; retain supporting soles and the unchanged simulation clock through load, contact and recovery.

The camera has no impact shake in either mode. Reduced Motion freezes decorative idle sway and suppresses displacement reactions while retaining essential steps, windups, contacts, falls, hit flash, countdown and warning information. Battery caps the engine at (30 FPS); Balanced caps it at (60 FPS). Portrait animation samples at up to (24 Hz), rendering once in Battery or Reduced Motion. Reduced Motion freezes camp portal curl and dungeon fluid time. Configured limits are not measured sustained device results.

### Live portrait and face material

HeroArt renders the equipped actor in a transparent orthographic SubViewport. The camera targets the animated Head-bone anchor and uses the established face crop; portrait-only weapon exclusion keeps equipment from crossing it. The sidecar retains crop, render-size clamps, update cadence and lights. Full-body preparation uses its separate formula. The facial diffuse patch uses measured image landmarks on immutable rest coordinates; it is neither a scanned likeness nor a separate painted portrait and adds no expression animation or lip sync.

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
- **Do** identify generated asset origins, renderer fixtures, measured animation/framing data and physical-device evidence by their actual source.

### Don't:

- **Don't** restore the superseded bright painterly world or replace live faces with painted portrait substitutes.
- **Don't** place tall masonry or sliced props across the authoritative passage, or use visibility culling as its repair.
- **Don't** add camera shake, alter simulation attack clocks for a visual phrase, or invent warning footprints that disagree with damage geometry.
- **Don't** show unearned seals, imply a unique model for every item, or claim motion capture, facial-expression or lip-sync animation that is absent.
- **Don't** reduce text or controls to force a compact layout, or infer visual approval, physical-device performance or release acceptance from renderer captures and test counts.
