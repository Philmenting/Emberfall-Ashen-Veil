---
name: "Emberfall: Ashen Veil"
description: "Monumental dark fantasy with animated 3D figures in a simulation-driven Android expedition world."
colors:
  background-top: "#201c20"
  background-bottom: "#090d12"
  panel: "#171b21"
  panel-light: "#20252c"
  edge: "#41434a"
  bronze: "#d2ad70"
  parchment: "#e7dfd2"
  muted-parchment: "#c3b9a8"
  action-red: "#9e4239"
  positive: "#86ad91"
  selected: "#493b30"
  selected-oath: "#493630"
  focus: "#ffe2a2"
  ink-ground: "#101318"
  combat-control: "rgb(2.7% 2.4% 2.7% / 92%)"
  life: "#b62c2b"
  mana: "#438e9e"
  arcanist: "#a58ed4"
  ranger: "#83b596"
  arcane-effect: "#79dbdc"
  danger: "#ff6a2e"
  danger-understroke: "rgb(4.5% 1.8% 1.2%)"
  common: "#c2bcb0"
  uncommon: "#85b497"
  rare: "#81a9d9"
  epic: "#bb86d4"
  legendary: "#e0a35d"
  figure-plum: "#703947"
  figure-violet: "#514267"
  figure-sage: "#354f46"
  figure-bronze: "#997449"
  nyra-hair: "#c8c9c2"
  nyra-skin: "#c9afa0"
typography:
  display:
    fontFamily: "Cinzel"
    fontSize: "22px"
  title:
    fontFamily: "Cinzel"
    fontSize: "19px"
  combat-title:
    fontFamily: "Cinzel"
    fontSize: "16px"
  body:
    fontFamily: "Lora"
    fontSize: "14px"
  label:
    fontFamily: "Lora"
    fontSize: "12px"
rounded:
  ink-ground: "3px"
  hud: "4px"
  glyph-control: "5px"
  control: "10px"
  compact-card: "12px"
  gear-card: "13px"
  overview-card: "17px"
spacing:
  tight: "4px"
  action-gap: "6px"
  row-gap: "8px"
  control-gap: "10px"
  section-gap: "12px"
  page-inset: "16px"
  detail-columns: "24px"
components:
  button-primary:
    backgroundColor: "{colors.action-red}"
    textColor: "{colors.parchment}"
    rounded: "{rounded.control}"
    padding: "0 9px"
  button-secondary:
    backgroundColor: "{colors.panel-light}"
    textColor: "{colors.parchment}"
    rounded: "{rounded.control}"
    padding: "0 9px"
  button-selected:
    backgroundColor: "{colors.selected}"
    textColor: "{colors.parchment}"
    rounded: "{rounded.control}"
    padding: "0 9px"
  button-oath-selected:
    backgroundColor: "{colors.selected-oath}"
    textColor: "{colors.parchment}"
    rounded: "{rounded.control}"
    padding: "0 9px"
  combat-control:
    backgroundColor: "{colors.combat-control}"
    textColor: "{colors.parchment}"
    rounded: "{rounded.glyph-control}"
    padding: "0 12px 0 42px"
  navigation-control:
    backgroundColor: "{colors.panel-light}"
    textColor: "{colors.parchment}"
    rounded: "{rounded.glyph-control}"
    padding: "0 12px 0 42px"
  gear-card:
    backgroundColor: "{colors.panel}"
    rounded: "{rounded.gear-card}"
    padding: "8px 11px"
  backup-field:
    typography: "{typography.body}"
    height: "76px"
---

# Design System: Emberfall: Ashen Veil

## Overview

**Creative North Star: "Painterly monumental dark fantasy"**

The [user-approved Hollow Spire illustration](docs/design/approved-spire.png) establishes weathered adult figures, monumental ruins, torn plum cloth and bronze against warm stone and cool haze. On 3 October 2026 the user explicitly requested fully animated spatial 3D figures. Eleven authored, lit character volumes now share native skeletal animation across combat, camp and portraits; distant matte paintings, spatial floors, masonry, effects and camp stations retain the established world. No separate 3D composition approval is inferred.

The world remains the main combat surface. Quiet ink grounds carry the portrait, life/mana, guardian phase and warning, region, pause and bottom actions. Preparation uses readable scrollable task panels. The camera holds a reserved combat-room shot, follows the travel anchor between chambers and widens smoothly when a complete warning needs more space. Hits and target changes do not shake or breathe the shot.

**Key Characteristics:**

- Spatial adult silhouettes, fitted armor and class-specific weapon poses.
- Region-specific architecture and warm/cool material contrast.
- Shared class and saved equipment quality across camp, portraits and combat.
- Complete simulation-driven warnings with visible surrounding safe floor.
- Native controls with adaptive text, touch sizing and safe-area offsets.

This file records the current implementation, updated on 3 October 2026. Frontmatter pixels are Godot logical UI units at the base scale. Source authority is [main.gd](scripts/main.gd), [DungeonActor](scripts/dungeon_actor.gd), [CharacterRig](scripts/character_rig.gd), [CharacterAnimation](scripts/character_animation.gd), [HeroArt](scripts/hero_art.gd), [DungeonWorld](scripts/dungeon_world.gd), [CampScene](scripts/camp_scene.gd), [UiGlyph](scripts/ui_glyph.gd) and their shaders. Native behavior takes precedence over the sidecar's illustrative HTML samples. The task's FORM identifier is `native-volumetric-character-animation`.

## Colors

The interface pairs warm bronze and parchment with layered charcoal; class, equipment and combat colors communicate actual state. Character materials use figure plum/violet/sage, figure bronze, Nyra hair and Nyra skin from the original Blender generator. Authored roughness and metallic values distinguish cloth, leather, skin, hair and forged metal under real scene lighting. These figure colors do not replace the interface palette.

### Primary

- **Bronze** marks headings, authored control strokes and active trim.
- **Action red** identifies descent and other consequential actions; **selected** and **selected oath** distinguish current preparation choices.
- **Focus** supplies the brighter keyboard/controller focus border.

### Secondary

- **Arcanist** violet and **Ranger** green identify classes; Vowkeeper uses bronze. **Arcane effect** cyan belongs to the live Arcanist effect path.
- **Common**, **uncommon**, **rare**, **epic** and **legendary** color equipment records. Actor accents and recovered world loot have separate source palettes; record colors must not be substituted into those shaders.
- **Positive** marks favorable stat changes and build synergies. **Life** and **mana** identify the combat meters.

### Tertiary

- **Danger** describes the active warning footprint. Its dark **danger understroke**, orange core and stationary interior hatch maintain separation from warm paving from the earliest countdown state.

### Neutral

- **Background top/bottom** form the preparation screen's vertical tonal field.
- **Panel**, **panel light** and **edge** distinguish containers and divisions.
- **Parchment** and **muted parchment** carry primary and secondary copy.
- **Ink ground** protects important combat text. **Combat control** retains the dark translucent bottom control surface.

**The Shared Geometry Rule.** Draw warnings from the same `BossPatterns` zones used for damage and avoidance; improve separation through material and outline treatment, preserving their active footprint.

## Typography

**Display Font:** locally bundled Cinzel (`assets/fonts/Cinzel.ttf`). **Body Font:** locally bundled Lora (`assets/fonts/Lora.ttf`). Both ship with SIL Open Font License files. The native theme defaults to Lora; the label helper's `bold` flag selects Cinzel rather than setting a font weight. No synthetic weight or letter-spacing scale is established.

The base hierarchy uses display for camp, oaths and seals, title for preparation page names, combat title for hero/guardian labels, body for the native theme and prominent copy, and label for smaller operational copy. Existing callers also use intermediate sizes; frontmatter records representative reused roles, not every call site.

**The Scaled Type Rule.** Route label and button sizes through `_scaled_font_size`: normal scale (1.0), compact scale (1.2), Large Text scale (at least 1.15, or 1.35 when compact), rounded to integers with a minimum (12). Paragraph helpers wrap; short state labels remain concise. Bundled fonts load offline.

## Layout

`project.godot` uses an expanding logical canvas (960 × 540) in landscape. The primary product device is the Pixel 9 Pro Fold closed outer display (2424 × 1080); the current renderer gallery uses that size, unfolded near-square (1040 × 1080) and compact Large Text (854 × 480). Ordinary gameplay clips use an outer-aspect proxy (1200 × 536). These are capture classes, not three hard-coded responsive breakpoints.

Preparation pages use vertical scrolling, page inset plus translated Android safe-area offsets, and persistent navigation. Reused spacing steps are in the frontmatter. Native compact sizing activates when logical width is at most (960) or height at most (600); desktop fixture sizing instead checks window width (960) or height (540). `_minimum_button_height` starts at (48), increases to (52) when compact and (58) with compact Large Text, and applies an Android density correction for the (48 dp) target. Physical touch and system-inset behavior still require device verification.

Combat overlays reserve top information and bottom actions while Details opens the build and route sheet on demand. The perspective camera reserves spatial actor/weapon envelopes and all guardian phase warnings for a steady room shot. Travel uses a relative envelope attached to the current anchor, preventing stale room geometry from pulling the heroine off-screen. A changing aspect ratio refits the shot; warning widening is monotonic within a shot. Camp buttons project from the same world anchors as the forge, expedition table, Nyra and earned seal shelf; their positions are clamped above the bottom tray.

## Elevation & Depth

UI depth comes from tonal layering, fine borders and translucent or opaque ink grounds. Reusable panels and buttons do not establish a drop-shadow vocabulary. Cinzel labels request a subtle native black shadow color; the world uses actual lighting/fog, painted horizons, textured ground and actor contact shadows. Opaque 3D characters have spatial normals, depth, cast shadows and material reflections. They turn continuously around their own vertical axis; no character surface faces the camera automatically.

Hollow Spire uses ash stone, a rose window and suspended bell; Drowned Archive uses stepped galleries, jade waterlight and an astrolabe; Glass Ossuary uses rib vaults, ivory and violet glass; Cinder Citadel uses angular basalt, foundry doors, a crown and molten distance. Regional identity lives in architecture and material as well as color.

## Shapes

Controls have gently rounded native corners; glyph controls and HUD grounds are tighter than equipment and overview cards. Panel border widths are (1), and focus borders are (2). The panel helper applies content margins (11 horizontal, 8 vertical). Authored anatomical volumes, tapered boots, continuous facial planes, fitted armor, swept pale hair and class weapons form Nyra's silhouette. The same GPU-skinned mesh remains visible through the complete articulated fall and settled corpse.

## Components

### Buttons and navigation

`_button` provides the shared fill, parchment type, corner and focus system. Hover lightens the supplied fill (0.12); press darkens it (0.10), changes type to bronze and emits the UI sound cue. Disabled text uses muted parchment. `_glyph_button` supplies the tighter shape and authored vector stroke at a nominal icon size (24). Icon-only controls adjust their inset. Navigation uses these same helpers and marks the current page with the selected fill.

### Gear and preparation cards

Gear rows and cards use the panel fill with rarity-derived borders and a gear-card radius. They show real slot, protection, temper and comparison state. Overview panels use the broader radius. The hero preview shares `DungeonActor` and saved equipment with combat and camp; the six equipped slots alter constrained quality accents. Class weapon art changes with class. An item name does not imply its own unique model.

### Oath controls

Three native buttons select zero, one or two oaths. Selection changes fill and adds `ON`; at two, the remaining unselected button is disabled. Start remains disabled with zero. The task panel displays the selected risks, additive currency reward, once-only drop rewards and actual class/set synergies, followed by a forecast. New runs and repeats carry frozen preparation; existing checkpoints retain their original rules.

### Meters and fields

Life/mana/guardian bars use a dark native track and a softly rounded fill. Backup fields are native wrapping `TextEdit` controls with a minimum height (76), inherited Lora and engine default field chrome. They do not establish an additional branded input treatment.

### Actors, phases and motion

Eleven spatial figures comprise three Nyra classes, four hostile kinds and four region guardians. Each figure uses twenty-nine native bones, nine AnimationPlayer clips and one cached opaque skinned surface (at most 40,000 triangles), plus the contact shadow. Original geometry is rebuilt from `tools/art/build_characters.py`; meshes, skin bindings and clip libraries are shared per appearance. Distance-driven alternating steps use leg IK to hold supporting soles on the floor, including backward travel; chest/head counter-motion and delayed cloth add weight. Older painted actor assets remain historical source archives and are excluded from Android exports.

Sword, staff, bow, shield and guardian actions have separate spatial poses. Hero windup follows the simulation's actual pending cast. Melee contact follows the real hit; a ranged weapon releases when its visible projectile starts, up to (0.085 s) before the unchanged damage event. Guardian windup follows its complete warning duration, including restored checkpoints. The left hand holds the bow and the right hand reaches the real moving nock. Recovery lasts (0.34 s). Retreat cancels an uncommitted cast; defeat buckles the knee, folds one leg and turns pelvis, shoulder and head before cloth settles over (0.90 s). Bone-derived spatial bounds include head, weapon and cloth. Phase state supplies actual warning patterns and restrained emissive cues.

The camera has no impact shake in either mode. Reduced Motion freezes decorative idle sway and suppresses displacement reactions while retaining essential steps, windups, contacts, falls, hit flash, countdown and warning information. Battery mode caps the engine at (30 FPS), reduces render resolution and removes MSAA/shadows; Balanced caps at (60 FPS). Those are configured limits, not measured sustained device results.

**The Earned State Rule.** Camp seals appear only for saved guardian trophies. Class, equipment, guardian phase and warning cues come from real preparation or simulation state.

## Do's and Don'ts

### Do:

- **Do** preserve the monumental world, adult silhouettes, pale-haired Nyra and distinct regional architecture while using the user-requested animated 3D figures.
- **Do** use the shared scaled-font, minimum-control and safe-area helpers when adding native UI.
- **Do** keep the complete active warning and adjacent safe floor legible through the real camera.
- **Do** use the same class and saved equipment path in portraits, camp and combat.
- **Do** label renderer fixtures, generated references and hardware measurements by their actual source.

### Don't:

- **Don't** restore painted billboards or mirror a character to change its direction; maintain authored spatial anatomy, lighting and continuous turns.
- **Don't** add a decorative warning shape that disagrees with collision or avoidance geometry.
- **Don't** show unearned seals or claim a unique model for every equipment item.
- **Don't** reduce controls or text to force a compact layout; retain scrolling and adaptive sizing.
- **Don't** infer device performance, motion quality or player retention from the static renderer gallery.

## Previous animation craft · 0.42

The previous release used painted layers and contour-based fall support. Its archived implementation and captures are documented in [0.42 implementation](docs/ANIMATION_CRAFT_042.md). The user rejected that motion finish and requested the 3D replacement above. Nyra/current-target emphasis, real warning relationships and a blade-aligned ribbon carry forward. See [0.43 implementation and evidence](docs/CHARACTERS_3D_043.md).
