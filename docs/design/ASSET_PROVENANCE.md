# Redesign asset provenance

The user approved `approved-spire.png`, a generated design illustration. It is a reference, not a substitute gameplay screen. Its exact prompt is retained beside it and in PNG metadata.

`assets/world/region-atlas.png`, `camp-matte.png` and `painted-stone.png` were generated using that reference. Their exact prompts are retained in `.prompt.txt` sidecars and embedded as PNG metadata. The region atlas supplies four distinct distant environments. The live Godot scene supplies the authoritative walking floor, interactive props, combat positions and actual warning geometry. The shared stone albedo dresses the floor and low masonry; it is tinted per region.

`assets/characters/{vowkeeper,arcanist,ranger}.png`, `hostiles.png` and `guardian_0.png` through `guardian_3.png` were generated as native-transparent, painted pose atlases from the same approved reference. Every actor selects actual idle, walking, anticipation, strike and defeat poses from simulation-driven state. These are 2.5D figures in a live 3D world. Camp, portrait and combat use the same class art and saved equipment quality accents. Equipment accents communicate the equipped slot's quality; they do not imply a unique model for every item. Guardian phase state changes the painted metal accents, warning geometry and sound.

`assets/world/camp-stations.png` is a generated, native-transparent three-cell forge/table/portal atlas. Its sprites occupy the same world anchors used by actual camp buttons. Earned seals are constructed from saved guardian trophies; empty slots remain empty. The station prompt is saved as TXT and JSON.

Exact initial and final correction prompts remain in sidecars where a correction was needed. Raster generation and visual edits used image generation; no pixel contents were repainted by scripts. The PNG provenance utility adds ancillary prompt metadata and verifies every IDAT pixel chunk remains byte-identical.

`tools/art/calibrate_pose_atlases.py` reads source alpha with NumPy, Pillow, SciPy and scikit-image, then writes only the eight `.atlas.json` geometry maps. It never writes or edits PNG pixels. The maps trace all 66 authored poses, use a single idle body scale per actor and retain complete weapons across irregular nominal cell boundaries. `docs/audit/2026-10-02/pose-source-mapping.json` records final PNG SHA-256 and exact visible-alpha coverage; runtime geometry was separately instantiated and triangulated without failures.

Original Blender character GLBs, their generator and skinning source remain in the source archive for reproducibility. They are excluded from the 0.40 shipping/QA runtime. Original authored Blender architecture supplies low carved remnants, braziers, medallions, wells and altars. No rejected smooth character mesh is hidden underneath the new figure.

Cinzel and Lora come from Google Fonts' `ofl/cinzel` and `ofl/lora` directories. Their SIL Open Font License files ship in `assets/fonts`. The original generated score and authored bronze UiGlyph icons retain their existing provenance.

The pre-existing project/store icons retain their original pixel chunks. PNG `Origin` metadata identifies baseline commit `f751f9296e625374f89c1e5981a8227fc44c2c8f`; no original generation prompt is archived, so a new prompt is not invented for them.

Marketing screenshots and the trailer are recaptured from the actual game with ordinary starting gear. The deterministic 24 FPS gameplay video is an export, not a phone frame-rate benchmark. Elevated-Life guardian fixtures are used only for the separately labeled renderer/layout review and Android art QA. Human playtest outcomes and physical Pixel performance remain unmeasured.
