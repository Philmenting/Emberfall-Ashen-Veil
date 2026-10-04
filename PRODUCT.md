# Emberfall: Ashen Veil

Emberfall is a landscape Android idle action RPG: choose Nyra's class, equip earned gear, set the rules of a descent, watch autonomous combat, and return to prepare the next expedition. The same deterministic simulation governs live play, skipping, repeated farming and offline progress.

## Confirmed direction

The user approved [this new art direction](docs/design/approved-spire.png) on 2 October 2026 and requested implementation across the game. It replaces the previous presentation with painterly dark fantasy: readable adult heroes, monumental region-specific ruins, bronze and plum accents, turquoise arcane magic and a compact HUD. The image is a generated design reference, not a gameplay capture.

On 3 October 2026 the user explicitly requested fully animated spatial 3D characters. This supersedes the painted figure implementation: Nyra, hostile figures and guardians now use lit volumetric models, native skeletons and complete clips. The monumental painted rooms, camp stations, palette and native HUD retain their approved direction. Combat room cameras must stay steady during hits and actions.

The primary device is a Google Pixel 9 Pro Fold, usually closed, in landscape. Design for its 2424×1080 outer display first, then the unfolded near-square display and compact landscape phones. Maintain native safe areas, Android Back, large text, reduced motion and usable touch targets.

Later on 3 October 2026 the user authorized a complete graphics overhaul and specified Diablo Immortal as the visual reference. This supersedes the bright painterly environment treatment: use mature dark fantasy, believable worn materials, a grounded isometric combat view and deliberate localized lighting. Emberfall's own characters, regions and assets remain original; fully animated spatial 3D figures and the steady combat camera remain required.

## Product boundaries

The user's subsequent face critique explicitly adds a facial overhaul. Nyra's
adult face, eyes, lips and hairline must be coherent across the three class
portraits and the actual camp/combat model. Native 3D remains authoritative.

- Three classes: Vowkeeper, Arcanist and Ranger. Four regions: Hollow Spire, Drowned Archive, Glass Ossuary and Cinder Citadel.
- Up to two of three oaths combine real risks and rewards with class and regional-set synergies. Class relics, regional sets and equipped techniques provide earned build choices. All four guardians have three simulation-driven phases. No new currency or mandatory daily tasks are required for this redesign.
- The camp exposes descent, forging and earned guardian trophies. Gear protection, first-descent rewards, AFK claims, hunt and trial rules must remain functional.
- Existing saves and in-progress checkpoints retain their frozen rules and once-only rewards. New combat rules activate only in newly created runs.
- UI and current store metadata are English. User communication is German; do not claim game localisation that does not exist.
- The current solo store export remains offline. Existing optional online development features are outside the redesign's new gameplay requirements.

## Evidence and success

Use screenshots and clips from actual playable scenes with normal equipment for marketing. Label render fixtures, generated references and source-rendered frame sequences honestly. Regression tests and emulator rendering do not establish Pixel frame rate, heat, battery use or player retention. A 12–20-person test package can be prepared here; real participant results require actual sessions.

On 4 October 2026 the user rejected the overall 0.45 presentation as still too conceptual (“Das Spiel funktioniert sieht aber weiterhin noch sehr konzeptmäßig aus.”). The continuing authorized overhaul must improve the actual live rooms, character construction, contact and combat composition; a more detailed distant image alone is insufficient. Retain the Diablo Immortal reference, original Emberfall content, adult shared Nyra, spatial 3D, steady camera and readable warnings. This is visual iteration, not a change to simulation, saves, loot or AFK rules.
