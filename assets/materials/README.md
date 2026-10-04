# Material sources

Rock030 (1K color, OpenGL normal and roughness maps) by ambientCG / Lennart Demes.
Source: https://ambientcg.com/a/Rock030
License: CC0 1.0, https://docs.ambientcg.com/license/
Metal063 (1K color and roughness maps) by ambientCG / Lennart Demes.
Source: https://ambientcg.com/a/Metal063
License: CC0 1.0, https://docs.ambientcg.com/license/

Both downloaded 2026-10-01. The source permits commercial use and redistribution.

All character and architectural geometry is original Emberfall work; its complete
authoring source is in `tools/art`. The maps are used on the game's actual masonry.

`ruin-floor/ruin-floor-albedo.png` is an original generated diffuse/albedo map,
created with image_gen for the live 0.46 floor. Its exact prompt and origin are
embedded and stored in the adjacent `.prompt.txt` / `.json`. The generator
returned 1254×1254; no upsampling or pixel retouching was applied. It is not a
photogrammetric scan or measured PBR material. The native shader mirrors the
tile at its edges and combines it with the existing Rock030 micro-normal.
