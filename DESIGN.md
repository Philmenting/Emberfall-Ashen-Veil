---
name: 'Emberfall: Ashen Veil'
description: 'Grounded dark fantasy: worn spatial materials, animated adult figures and a steady isometric combat
  view.'
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
  combat-control: rgb(2.7% 2.4% 2.7% / 92%)
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
typography:
  display:
    fontFamily: Cinzel
    fontSize: 22px
  title:
    fontFamily: Cinzel
    fontSize: 19px
  combat-title:
    fontFamily: Cinzel
    fontSize: 16px
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
spacing:
  tight: 4px
  action-gap: 6px
  row-gap: 8px
  control-gap: 10px
  section-gap: 12px
  page-inset: 16px
  detail-columns: 24px
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
  combat-control:
    backgroundColor: '{colors.combat-control}'
    textColor: '{colors.parchment}'
    rounded: '{rounded.glyph-control}'
    padding: 0 12px 0 42px
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
---

# Design System: Emberfall: Ashen Veil

## Overview

**Creative North Star: "Inhabited dark fantasy ruins"**

The user's complete graphics overhaul and explicit Diablo Immortal reference, recorded in [PRODUCT.md](PRODUCT.md) and the [0.45 direction contract](docs/design/graphics-direction-045.md), establish mature worn materials, a grounded isometric fight and localized light. Soot-dark iron, worn silver, oxblood cloth, wet slate and aged ivory surround original Emberfall characters and regional architecture. The earlier bright painterly illustration is historical authority; it no longer governs this world. No separate approved 0.45 composition or successful concept seed is inferred.

Live floors, masonry, props and eleven lit skeletal figures carry the foreground. Five original generated distant plates supply camp and regional depth. Nyra's rebuilt continuous adult face, fitted eyes and lips, and pale swept hair use the same class/equipment model in portrait, camp and combat. The facial albedo is a generated diffuse patch on authored geometry; the Head bone and existing body clips animate it, with no separate facial-expression or lip-sync rig.

The fight owns the image. Quiet native ink grounds carry readable state, preparation remains scrollable, and the combat-room camera stays anchored through hits and target changes. Travel follows the actual route; widening preserves complete simulation-driven warning geometry. Warm hearths, jade waterlight and muted spectral accents reveal worn surfaces without turning all armor into polished bronze.

**Key Characteristics:**

- Original spatial adult figures with shared class, face and saved equipment identity.
- Worn metal, cloth, leather and stone tied to the moving geometry.
- Regional live masonry and props joined to quiet distant environment plates.
- Clear authoritative passages, complete danger footprints and a steady room camera.
- Native scaled text, touch sizing, safe-area offsets and a real reading pause.

This is the source-grounded 0.45 record, updated after the passage-clearance and landmark-export corrections. Frontmatter pixels are base Godot logical UI units; the sidecar's extensions.native carries spatial, material, camera, lighting, portrait and quality tokens that the frontmatter schema cannot represent. Native code takes precedence over the sidecar's illustrative HTML controls. Sources include [main.gd](scripts/main.gd), [DungeonWorld](scripts/dungeon_world.gd), [DungeonTheme](scripts/dungeon_theme.gd), [CampScene](scripts/camp_scene.gd), [HeroArt](scripts/hero_art.gd), [CharacterRig](scripts/character_rig.gd), [CharacterAnimation](scripts/character_animation.gd), [character materials](assets/shaders/character_surface.gdshader), [character geometry](tools/art/build_characters.py) and [face geometry](tools/art/build_faces.py).

The initial independent full review recorded a fix disposition against the preceding capture packet. Its passage and workload corrections are implemented in source and the corrected native capture packet is complete. See [graphics-review-045-final.md](docs/design/graphics-review-045-final.md) for the authoritative scored verdict; this design record does not assert acceptance. The [overhaul report](docs/GRAPHICS_OVERHAUL_045.md) and [asset provenance](docs/design/ASSET_PROVENANCE.md) describe implementation and origins; final capture hashes belong beside the captures.

## Colors

The retained interface pairs warm bronze and parchment with layered charcoal. The world uses a quieter worn-material palette: figure and region tokens are separate from class, rarity and action colors. Frontmatter colors are extracted source values; lighting and texture sampling determine their rendered appearance.

### Primary

- **Bronze** marks headings, control strokes and active trim; **action red** marks consequential actions.
- **Selected**, **selected oath** and **focus** distinguish preparation choices and keyboard/controller focus.

### Secondary

- **Arcanist** violet and **Ranger** green identify classes; Vowkeeper uses bronze. **Arcane effect** belongs to the live spell path.
- **Common** through **legendary** color equipment records. Actor accents and recovered world loot retain their own source palettes.
- **Positive**, **life** and **mana** identify actual stat and meter state.

### Tertiary

- **Danger** and **danger understroke** separate the complete active warning from textured ground; the stationary interior hatch remains visible from the earliest countdown.
- Region **fire** and **light** tokens color practical sources. Spire uses warm ember against cold slate, Archive jade against damp stone, Ossuary subdued mauve against aged ivory, and Citadel furnace warmth against ash.

### Neutral

- **Background top/bottom**, **panel**, **panel light**, **edge**, **parchment**, **muted parchment**, **ink ground** and **combat control** retain the established native UI roles.
- **Figure iron/silver/bronze/gold/patina**, **wine/violet/sage**, **leather/linen/bone/ash/dark**, and **Nyra skin/hair/eyes/lips** come from the authored material palette. Metallic and roughness values are in extensions.native.materials.figures.
- Region **stone**, **edge**, **dark**, **metal**, **cloth** and **mineral** tokens dress repeated geometry. Region **ambient**, **moon**, **fog** and **background**, plus camp, portrait and reflection tokens, define the actual lighting stages.

**The Shared Geometry Rule.** Draw warnings from the same BossPatterns zones used for damage and avoidance; improve separation through material and outline treatment, preserving their active footprint.

**The Material Attachment Rule.** Sample character finish and Nyra's facial patch in immutable mesh rest coordinates; the material must stay attached to the animated surface.

## Typography

**Display Font:** locally bundled Cinzel (`assets/fonts/Cinzel.ttf`). **Body Font:** locally bundled Lora (`assets/fonts/Lora.ttf`). Both ship with SIL Open Font License files. The native theme defaults to Lora; the label helper's `bold` flag selects Cinzel rather than setting a font weight. No synthetic weight or letter-spacing scale is established.

The base hierarchy uses display for camp, oaths and seals, title for preparation page names, combat title for hero/guardian labels, body for the native theme and prominent copy, and label for smaller operational copy. Existing callers also use intermediate sizes; frontmatter records representative reused roles, not every call site.

**The Scaled Type Rule.** Route label and button sizes through `_scaled_font_size`: normal scale (1.0), compact scale (1.2), Large Text scale (at least 1.15, or 1.35 when compact), rounded to integers with a minimum (12). Paragraph helpers wrap; short state labels remain concise. Bundled fonts load offline.

## Layout

The project uses an expanding logical canvas (960 × 540) in landscape. The primary product device is the Pixel 9 Pro Fold closed outer display (2424 × 1080). Native capture classes are that size, unfolded near-square (1040 × 1080), and compact Large Text (854 × 480). The normal-equipment moving sequence uses an outer-aspect proxy (1200 × 536). These are capture classes rather than three hard-coded layout breakpoints.

Preparation pages use vertical scrolling, page inset plus translated Android safe-area offsets, and persistent navigation. Native compact sizing activates when logical width is at most (960) or height at most (600); desktop fixtures use window width (960) or height (540). The shared minimum-button helper starts at (48), increases to (52) when compact and (58) with compact Large Text, and applies Android density correction for the (48 dp) target. Physical touch and system-inset acceptance remain unmeasured.

Combat reserves the actual laid-out HUD and readout height. The perspective shot uses the steeper camera boom, narrower field of view and aspect-dependent aiming recorded in the sidecar. It reserves actor/weapon envelopes and all guardian-phase warning bounds once per room; warning expansion can widen the shot but cannot zoom it back in between repeated attacks. Travel uses a relative envelope on the current route anchor. Camp buttons project from the forge, expedition table, Nyra and seal anchors, with station spread adapting to aspect and labels clamped above the bottom tray.

The continuous stone court and lower paving aprons support the active floor beyond its former edge. Rear courses, buttresses and complete regional fixtures are checked against Layout.floor_rects() with a clearance margin (0.20 m). Full-height wall columns are omitted where their footprints enter that envelope; a complete prop is omitted when its transformed exported standing-height bounds intrude. Lower paving remains available beneath warnings. Chamber visibility manages foreground occlusion after placement; it is not the passage-clearance mechanism.

**The Clear Passage Rule.** Derive tall dressing clearance from the generated floor and passage envelope, including its margin; keep openings full height and remove whole obstructing props before static batching.

**The Steady Shot Rule.** Hold the combat-room anchor through hits, casts and target changes; follow travel smoothly and widen only to preserve the complete reserved geometry.

## Elevation & Depth

UI depth comes from tonal layering, fine borders and ink grounds. Reusable panels and buttons establish no drop-shadow vocabulary. Cinzel labels retain their subtle native black shadow color. World depth comes from real floor and masonry geometry, lit opaque figures, contact shadows, reflection colors, fog and distant generated plates.

[Weathered stone](assets/shaders/weathered_stone.gdshader) samples the retained ambientCG Rock030 color, roughness and normal maps by world-space triplanar projection. Compressed normal Z is reconstructed from red/green; regional roughness and mineral weathering distinguish damp Archive surfaces from dry ash and stone. [Crafted surfaces](assets/shaders/crafted_surface.gdshader) sample the original oak/leather/linen/steel atlas within mirrored cell bounds. Character wear uses that atlas with retained ambientCG Metal063 grain and roughness in rest space. The atlas supplies color-derived roughness variation, not a separately authored normal map.

Hollow Spire uses broken funerary masonry, a vaulted landmark and bell forms; Drowned Archive uses damp shelves, books and jade light; Glass Ossuary uses bone ribs, reliquary geometry and muted mauve; Cinder Citadel uses furnace/iron construction and warm ash. Rear walls and return courses join their footing and lower apron. The repeated vault, library, altar and throne exports are joined by material before runtime batching.

The world, camp and portrait share the authored reflection sky and filmic tone mapping. World moon/rim/hero lantern, camp sun/fill/hearth/table lights and portrait key/rim have separate extracted stage tokens in the sidecar. Battery removes the main shadow and stone relief, reduces resolution/MSAA, and suppresses world sanctuary beams and extra sanctuary lights. These are configured presentation changes; they do not establish sustained phone frame rate.

## Shapes

Controls retain gently rounded native corners; glyph controls and HUD grounds are tighter than equipment and overview cards. Panel borders are (1), focus borders (2), and panel content margins (11 horizontal, 8 vertical). Frontmatter records the reused corner and spacing scales.

Nyra's continuous head surface joins cheeks, jaw and nasal relief. Fitted almond eyes, modeled eyelids, restrained lip surfaces, a closed seam, a coherent hairline and fine swept silver locks support an adult identity. Class-specific layered shoulders, collars, straps, pouches and rivets sit on the same spatial body. The GPU-skinned mesh remains visible through the articulated fall and settled corpse. Camp's authored forge has a hearth, anvil, tools and bellows; the trestle table carries a map, folio and candle; the shrine has four empty carved mounts until their seals are earned.

**The Shared Face Rule.** Use the same live class/equipment geometry for portrait, camp and combat; inspect the lit head as well as its texture, and preserve the adult face through all three class views.

## Components

### Buttons and navigation

`_button` provides the shared fill, parchment type, corner and focus system. Hover lightens the supplied fill (0.12); press darkens it (0.10), changes type to bronze and emits the UI sound cue. Disabled text uses muted parchment. `_glyph_button` supplies the tighter shape and authored vector stroke at a nominal icon size (24). Icon-only controls adjust their inset. Navigation uses these same helpers and marks the current page with the selected fill.

### Gear and preparation cards

Gear rows and cards use the panel fill with rarity-derived borders and a gear-card radius. They show real slot, protection, temper and comparison state. Overview panels use the broader radius. The hero preview shares `DungeonActor` and saved equipment with combat and camp; the six equipped slots alter constrained quality accents. Class weapon art changes with class. An item name does not imply its own unique model.

### Oath controls

Three native buttons select zero, one or two oaths. Selection changes fill and adds `ON`; at two, the remaining unselected button is disabled. Start remains disabled with zero. The task panel displays the selected risks, additive currency reward, once-only drop rewards and actual class/set synergies, followed by a forecast. New runs and repeats carry frozen preparation; existing checkpoints retain their original rules.

### Meters and fields

Life/mana/guardian bars use a dark native track and a softly rounded fill. Backup fields are native wrapping `TextEdit` controls with a minimum height (76), inherited Lora and engine default field chrome. They do not establish an additional branded input treatment.

### Combat readouts and inspection

The permanent lower row exposes the equipped signature and actual techniques from the frozen expedition. Each skill shows its name, CASTING / remaining cooldown / LOW MANA / READY and an actual cooldown track. Existing class and technique colors identify the tracks; words carry state independently of color. The same 48-unit minimum touch and scaled-font helpers apply. Tapping a skill opens its rule in Details and pauses live combat. Closing or Back restores the prior active/manual-pause state. Resume explicitly continues. The reading state survives layout rebuilds; a save preserves the underlying active intent, so cold restart cannot accidentally turn a manual pause into play.

Chamber progress and its current objective remain visible alongside the skills. Living reinforcements count as foes remaining, and completing the guardian still requires recovering the reliquary. Guard duration and Mana Ward's active/reserve state appear under Nyra's meters. Life values update immediately; lost Life leaves a bronze trace for 0.18 seconds and settles over 0.42 seconds. Healing clears the trace, inspection pauses it, and Reduced Motion removes its movement. No screen flash or camera impulse accompanies it.

The renderer reserves the actual laid-out readout height. Unlaid-out container positions never participate in framing; the fixed-height objective avoids camera changes between status strings. All room and warning geometry must remain above that reserved edge. Reading opens the existing scrollable two-column sheet and keeps skill selection, Close and Resume reachable.

**The Combat Inspection Rule.** Show automatic skill state in words and cooldown tracks from the frozen expedition. Reading temporarily pauses live time: Close or Back restores the player's prior active/manual-pause intent, while Resume explicitly continues. Layout rebuilds and saves must preserve that intent.

### Actors, phases and motion

Eleven spatial figures comprise three Nyra classes, four hostile kinds and four region guardians. Each figure uses twenty-nine native bones, nine AnimationPlayer clips and one cached opaque skinned surface (at most 40,000 triangles), plus the contact shadow. Original geometry is rebuilt from tools/art/build_characters.py, with Nyra's head authored in tools/art/build_faces.py; meshes, skin bindings and clip libraries are shared per appearance. The existing native clips are reused, rather than represented as newly captured motion. Distance-driven alternating steps use leg IK to hold supporting soles on the floor, including backward travel; chest/head counter-motion and delayed cloth add weight. Older painted actor assets remain historical source archives and are excluded from Android exports.

Sword, staff, bow, shield and guardian actions have separate spatial poses. Hero windup follows the simulation's actual pending cast. Melee contact follows the real hit; a ranged weapon releases when its visible projectile starts, up to (0.085 s) before the unchanged damage event. Guardian windup follows its complete warning duration, including restored checkpoints. The left hand holds the bow and the right hand reaches the real moving nock. Recovery lasts (0.34 s). Retreat cancels an uncommitted cast; defeat buckles the knee, folds one leg and turns pelvis, shoulder and head before cloth settles over (0.90 s). Bone-derived spatial bounds include head, weapon and cloth. Phase state supplies actual warning patterns and restrained emissive cues.

The camera has no impact shake in either mode. Reduced Motion freezes decorative idle sway and suppresses displacement reactions while retaining essential steps, windups, contacts, falls, hit flash, countdown and warning information. Battery mode caps the engine at (30 FPS), reduces render resolution and removes MSAA/shadows and stone relief; Balanced caps at (60 FPS). Portrait animation samples at up to (24 Hz) and renders once in Battery or Reduced Motion. Reduced Motion also freezes the camp portal curl. Those are configured limits and behaviors, not measured sustained device results.

### Live portrait and face material

HeroArt renders the actual equipped actor in a transparent orthographic SubViewport. The camera targets the animated Head-bone anchor and uses a closer face crop; portrait-only weapon exclusion keeps equipment from crossing the face. The sidecar records the exact crop, render-size clamps, update cadence and key/rim lights. Full-body preparation uses its separate size formula. Skin projection uses measured image landmarks on immutable rest coordinates, and the generated patch retains subtle anatomical shading. It is not a scanned likeness or independent painted portrait, and adds no separate expression animation or lip sync.

### Camp and protective surfaces

The portal is the original Gothic arch with an additive native veil shader. Guard segments and the Arcanist Mana Ward shell use the native additive rim surface only while their actual simulation state is active. The working forge, expedition table and empty seal mounts are authored 3D objects. World-space station anchors supply their actionable native labels.

**The Earned State Rule.** Camp seals appear only for saved guardian trophies. Class, equipment, guardian phase and warning cues come from real preparation or simulation state.

## Do's and Don'ts

### Do:

- **Do** use the authorized worn dark-fantasy material world, original regional assets and shared adult 3D Nyra identity.
- **Do** derive complete warning geometry and tall-dressing clearance from the authoritative simulation and generated route.
- **Do** keep camera, portrait, stage-light and material values aligned with their native source tokens.
- **Do** use shared scaled-font, minimum-control and safe-area helpers, preserving the real reading-pause intent.
- **Do** record generated asset origins, native renderer fixtures and measured device evidence by their actual source.

### Don't:

- **Don't** restore the superseded bright painterly world or replace live faces with painted portrait substitutes.
- **Don't** place tall masonry or sliced props across the authoritative passage, or use visibility culling as its repair.
- **Don't** add camera shake or a decorative warning footprint that disagrees with damage and avoidance geometry.
- **Don't** show unearned seals, imply a unique model for every item, or claim facial-expression/lip-sync animation that is absent.
- **Don't** reduce text or controls to force a compact layout, or infer physical-device performance or release acceptance from renderer captures.
