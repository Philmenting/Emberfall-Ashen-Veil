# Character and material asset provenance

The anatomical meshes in assets/models are derived from MakeHuman's hm08 base mesh and young adult morph data. The original mesh and both morph files explicitly dedicate the assets to CC0. Only asset data is used. No MakeHuman application code, shader code, UI images or GPL/AGPL scripts are incorporated.

The specific asset permission in MakeHuman's LICENSE.ASSETS.md applies to these files. It takes precedence over the separate license for application code. The full CC0 dedication is preserved in assets/models/LICENSE-CC0.txt.

| Input | Frozen Git blob |
| --- | --- |
| makehuman/data/3dobjs/base.obj | d26635e9326e3cca30778fd7b9c00062b03cce09 |
| makehuman/data/targets/macrodetails/caucasian-female-young.target | 9d1f0cbeedc9a6a51abe33f1ebb5fa7c5a7edbf1 |
| makehuman/data/targets/macrodetails/caucasian-male-young.target | c3b82f92c5ced85599199cd184b0faf3b3fc6881 |

Source repository commit: a8bc2d54ff0ac92e78ff71431b1023eda42bf482, https://github.com/makehumancommunity/makehuman

Copyright holders listed by the sources are Data Collection AB, Joel Palmius and Jonas Hauquier. See https://static.makehumancommunity.org/about/license.html and the asset-specific license in the frozen repository.

The original conversion removes helper geometry, changes proportions and the rest pose, builds seven joint skinning weights, preserves anatomical topology and UVs, calculates surface normals and exports glTF 2.0. Nyra and Ashen each have 14,517 vertices and 26,756 triangles before engine LOD generation. The runtime drives their limb bones from the existing combat pose controls. Original curved plate armor, raised scrollwork, open face headwear, robe folds, bow, staff and sword geometry are authored for Emberfall.

Six original bitmap material tiles were generated with the built-in image generation tool. They are steel, leather, linen, skin, bone and limestone. The atlas is split into six 512 by 512 albedo images. The skin normal map is numerically derived from the skin tile. The remaining materials use filtered texture height gradients in the shaders. No Blizzard models, textures or game imagery were imported.

The final image generation prompt is reproduced below.

Use case: stylized-concept. Asset type: production material texture atlas for an original dark fantasy 3D action RPG, direct shader input. Generate a flat orthographic seamless surface atlas, landscape ratio 3:2, exactly THREE columns and TWO rows of equal squares, no gutters, no labels, no text, no borders. Each cell is a close-up neutral physically plausible BASE COLOR material, even diffuse light, no perspective, no dramatic illumination or specular highlights, no objects. Top left: worn cool silver forged steel, fine scratches and subtle hammered grain. Top middle: rich dark brown aged leather, fine pores and scuffs. Top right: muted slate-grey heavy woven linen, clear dense threads, no folds. Bottom left: neutral beige human skin pores, extremely subtle mottling, no hair and no body features. Bottom middle: weathered pale ivory bone surface, fine pitting and aged cracks. Bottom right: dark cool grey medieval limestone, irregular mineral grains and fine fissures, no brick pattern. Each square tiles independently with visually matching opposite edges and uniform distribution. High-frequency tactile realistic detail suitable for real game meshes. Restrained colors, no baked shadows, no emblems or copyrighted game imagery. Output 1536 by 1024 if possible.

Assets consumed by the game are saved in assets/models and assets/textures. The comparison workflow renders real Godot scenes and three front-facing character portraits. It compares them with the frozen original game revision. These images are engine captures, not concept illustrations.

