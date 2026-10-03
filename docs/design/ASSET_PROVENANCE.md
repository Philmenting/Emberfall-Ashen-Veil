# Redesign asset provenance

## Current figures · 0.43

On 3 October 2026 the user explicitly chose fully animated 3D figures. All eleven
shipping character GLBs in `assets/models/` are original authored geometry from
`tools/art/build_characters.py`, rebuilt with adult Nyra proportions, continuous
facial planes, pale swept hair/braids, fitted armor and class weapons. No external
model or animation pack is used. `character_rig.gd` binds source volumes to a
native 29-bone Skeleton3D and one cached GPU surface; `character_animation.gd`
authors nine native clips per appearance. `character_surface.gdshader` supplies
opaque lighting, material roughness, metal reflection and equipment accents.
Camp, portrait and combat instantiate the same live class/equipment path.

The painted actor source below is historical and excluded from all Android
exports in 0.43. It supplies neither the live figure nor its final corpse.
Monumental world paintings, floors, architecture, camp stations, fonts and UI
retain the provenance below. Figure color conversion is measured from imported
Godot material values; no source PNG pixels were altered in this replacement.
The 0.43 clips use native Godot/Mesa frames at 30 FPS, an export timing rather
than a physical phone benchmark. Their opening preparation segment is Armory.

## Historical painted figures and retained world assets

The user approved `approved-spire.png`, a generated design illustration. It is a reference, not a substitute gameplay screen. Its exact prompt is retained beside it and in PNG metadata.

`assets/world/region-atlas.png`, `camp-matte.png` and `painted-stone.png` were generated using that reference. Their exact prompts are retained in `.prompt.txt` sidecars and embedded as PNG metadata. The region atlas supplies four distinct distant environments. The live Godot scene supplies the authoritative walking floor, interactive props, combat positions and actual warning geometry. The shared stone albedo dresses the floor and low masonry; it is tinted per region.

`assets/characters/{vowkeeper,arcanist,ranger}.png`, `hostiles.png` and `guardian_0.png` through `guardian_3.png` were generated as native-transparent, painted pose atlases from the same approved reference. These original 66 poses remain unchanged and provide the settled fallen figures and source archive. Camp, portrait and combat share the same class identity and saved equipment quality accents. Equipment accents communicate the equipped slot's quality; they do not imply a unique model for every item. Guardian phase state changes the painted metal accents, warning geometry and sound.

In 0.41, `assets/characters/motion/` adds eleven native-transparent paintings, each containing twelve complete anatomical pieces generated with image generation from the approved character identity. One GPU-skinned surface and a native 23-bone skeleton animate each living figure continuously. PNG pixel data is copied unchanged. `tools/art/calibrate_motion_parts.py` reads alpha and writes only `.motion.json` contours/anchors. `provenance.json` records every new PNG hash and its identity source hash; `shared-parts.prompt.txt` retains the shared later-atlas instruction. The initial Vowkeeper/Bell Warden prompts and character-specific suffixes are not fully archived, and are not reconstructed. The Bell torso geometry excludes a duplicate crown already present in that generated piece; the separate full head supplies it. Ranger's straight source string is hidden in the shader while skinned geometry supplies the animated string.

`assets/world/camp-stations.png` is a generated, native-transparent three-cell forge/table/portal atlas. Its sprites occupy the same world anchors used by actual camp buttons. Earned seals are constructed from saved guardian trophies; empty slots remain empty. The station prompt is saved as TXT and JSON.

Exact initial and final correction prompts remain in sidecars where a correction was needed. Raster generation and visual edits used image generation; no pixel contents were repainted by scripts. The PNG provenance utility adds ancillary prompt metadata and verifies every IDAT pixel chunk remains byte-identical.

`tools/art/calibrate_pose_atlases.py` reads source alpha with NumPy, Pillow, SciPy and scikit-image, then writes only the eight `.atlas.json` geometry maps. It never writes or edits PNG pixels. The maps trace all 66 authored poses, use a single idle body scale per actor and retain complete weapons across irregular nominal cell boundaries. `docs/audit/2026-10-02/pose-source-mapping.json` records final PNG SHA-256 and exact visible-alpha coverage; runtime geometry was separately instantiated and triangulated without failures.

Original Blender character GLBs, their generator and skinning source were excluded from the 0.40 shipping/QA runtime. Their authored geometry was revised and made live in 0.43 as documented above. Original authored Blender architecture supplies low carved remnants, braziers, medallions, wells and altars.

Cinzel and Lora come from Google Fonts' `ofl/cinzel` and `ofl/lora` directories. Their SIL Open Font License files ship in `assets/fonts`. The original generated score and authored bronze UiGlyph icons retain their existing provenance.

The pre-existing project/store icons retain their original pixel chunks. PNG `Origin` metadata identifies baseline commit `f751f9296e625374f89c1e5981a8227fc44c2c8f`; no original generation prompt is archived, so a new prompt is not invented for them.

Marketing screenshots and gameplay clips are captured from the actual game with ordinary starting gear. The 0.40 clip is a deterministic 24 FPS export; the 0.41 clip uses 30 FPS. These are exports, not phone frame-rate benchmarks. The separately labeled motion inspection shows actual runtime actors on a diagnostic stage. Elevated-Life guardian fixtures are used only for renderer/layout review and Android art QA. The framing test also raises damage/guardian Life to reach and retain late warning poses; it is not a balance test. Human playtest outcomes and physical Pixel performance remain unmeasured.
