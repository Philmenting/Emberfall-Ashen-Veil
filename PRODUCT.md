# Emberfall: Ashen Veil

Emberfall is a landscape Android idle action RPG: choose Nyra's class, equip earned gear, set the rules of a descent, watch autonomous combat, and return to prepare the next expedition. The same deterministic simulation governs live play, skipping, repeated farming and offline progress.

## Confirmed direction

The user approved [this new art direction](docs/design/approved-spire.png) on 2 October 2026 and requested implementation across the game. It replaces the previous presentation with painterly dark fantasy: readable adult heroes, monumental region-specific ruins, bronze and plum accents, turquoise arcane magic and a compact HUD. The image is a generated design reference, not a gameplay capture.

The primary device is a Google Pixel 9 Pro Fold, usually closed, in landscape. Design for its 2424×1080 outer display first, then the unfolded near-square display and compact landscape phones. Maintain native safe areas, Android Back, large text, reduced motion and usable touch targets.

## Product boundaries

- Three classes: Vowkeeper, Arcanist and Ranger. Four regions: Hollow Spire, Drowned Archive, Glass Ossuary and Cinder Citadel.
- Up to two of three oaths combine real risks and rewards with class and regional-set synergies. Class relics, regional sets and equipped techniques provide earned build choices. All four guardians have three simulation-driven phases. No new currency or mandatory daily tasks are required for this redesign.
- The camp exposes descent, forging and earned guardian trophies. Gear protection, first-descent rewards, AFK claims, hunt and trial rules must remain functional.
- Existing saves and in-progress checkpoints retain their frozen rules and once-only rewards. New combat rules activate only in newly created runs.
- UI and current store metadata are English. User communication is German; do not claim game localisation that does not exist.
- The current solo store export remains offline. Existing optional online development features are outside the redesign's new gameplay requirements.

## Evidence and success

Use screenshots and clips from actual playable scenes with normal equipment for marketing. Label render fixtures, generated references and source-rendered frame sequences honestly. Regression tests and emulator rendering do not establish Pixel frame rate, heat, battery use or player retention. A 12–20-person test package can be prepared here; real participant results require actual sessions.
