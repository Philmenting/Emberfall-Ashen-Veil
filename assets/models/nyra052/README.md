# Nyra native65 — acquired artist source, development integration 052

The authored body is still revision 052. Its current living staff grasp uses the [053 correction and actual contact evidence](../../../docs/design/nyra-staff-grip-correction-053.md), replacing the incorrectly aligned source sword fist.

The ordinary Arcanist now uses an original Quaternius adult female head/eyes/brows, the manufacturer's complete Female Peasant modular outfit (including arms, articulated gloved hands, legs and boots), and the manufacturer's head-rigged buns hairstyle. The outfit manufacturer's instructions explicitly require a head-only base; this is not a complete nude body hidden underneath clothes. Original referenced positions, normals, UV0, four skin influences and all 65 target rest bones are retained. Extra unused UV/color attributes are omitted. There is no 29-bone remapping or anatomical scaling. Appearance uses original light-skin maps, silver-grey hair and darker brows; the legacy Arcanist contributes only its staff geometry.

## Legitimately acquired source

All three free **Standard** ZIPs were downloaded anonymously from the author's official itch.io free-download flow on 2026-10-05. No account, purchase, paid Source/Pro package, Sketchfab original or viewer extraction was used. Each archive includes the CC0 1.0 license, copied verbatim here. Manufacturer page and actual downloaded files agree on the license.

| Package | Official source | ZIP SHA-256 |
| --- | --- | --- |
| Universal Base Characters Standard | https://quaternius.itch.io/universal-base-characters | `fdbf1804c90dfc1ea03e992bff7da2dfd1a79318e13270a660180f9308455f40` |
| Modular Character Outfits Fantasy Standard | https://quaternius.itch.io/modular-character-outfits-fantasy | `c3468b18871cc8c8f05ab14df7712baf22cb9f389cbd870babf130e595187f70` |
| Universal Animation Library Standard | https://quaternius.itch.io/universal-animation-library | `cc73fc4e495b82958207316596317a3f40b9fa38065bde1027937452da537724` |

Base ZIP bytes: 128,968,391; outfit: 294,347,394; animation: 15,904,933. `BASE-LICENSE.txt`, `OUTFIT-LICENSE.txt`, `ANIMATION-LICENSE.txt` and `MANUFACTURER-OUTFIT-README.txt` are exact supplied documents. Artist credit: **Quaternius**. CC0 permits redistribution and commercial modification.

## Runtime and rebuild

`arcanist.glb`: 22,108 avatar triangles, eight rendered source meshes, full native65 skeleton with all five fingers on both hands, eleven real authored animation clips. SHA-256: `d489ad6a55510a5bd36f0215fcb3be1a596cab6094500f19476e3fc172e7e4e1`.

The animation library's mannequin has different rest proportions. Offline retargeting uses `target_rest_rotation * inverse(source_rest_rotation) * source_animation_rotation`, keeps target bone lengths/translations and retains only root/pelvis translation deltas. The runtime uses the actual source idle/walk/enter/shoot/exit/death clips, preserves simulated damage/release timing, blends clips and keeps the staff in the right hand while the left hand casts. Basic/signature/heavy currently share this same authored casting phrase. The source has no facial blendshape animation.

Original 4K Peasant base-color/normal/ORM textures are reduced to 2K using Godot Image Lanczos. Skin/hair 2K and eye maps are original artist files; this is texture resizing, not a new high-poly bake. The supplied glTF eye filename typo is resolved against the actual original eye-normal PNG. `assembly-report.json` records descriptor, external binary geometry, original and resized map hashes.

With the three original Standard ZIPs extracted below SOURCE_ROOT and NumPy installed:

```sh
GODOT --headless --path . --script res://tools/art/prepare_nyra052_textures.gd -- ORIGINAL_OUTFIT_TEXTURE_DIRECTORY BUILD_ROOT/texture-cache
python3 tools/art/assemble_nyra052.py --source-root SOURCE_ROOT --output-root BUILD_ROOT
```

Copy the resulting `nyra-authored-native65.glb` into this directory as `arcanist.glb`, import with Godot, then regenerate measured death support with `tests/source_avatar_grounding_compile.gd`. The grounding JSON is bound to the actual model hash and reconstructs all four weighted influences of every referenced source vertex. No original artist Blender file is included in the free packages. A packed [editable Blender conversion](../../../art-source/nyra052/nyra052-editable-conversion.blend) of the verified runtime GLB is included separately, with `.gdignore` excluding it from game export. It is not an original artist sculpt/bake source.

### Staff grasp — 053

`staff-grip053.json` contains the fitted absolute native finger rotations and hand-local aperture axis/center, bound to the unchanged body hash. `staff-grip053.glb` retains Emberfall's existing staff ornament and materials, with the actual handle narrowed to 18 mm radius at runtime scale 0.75. The old raised leather wraps are removed. The prop has the original plain materials without UVs; no new texture bake is claimed.

With NumPy installed, rebuild this prop independently of the character archives:

```sh
python3 tools/art/fit_nyra053_staff.py --source assets/models/arcanist.glb --output assets/models/nyra052/staff-grip053.glb
```

Final staff SHA-256: `98bd5832256f9a2fdbb68198d1dbf0d2db0b87c9c4d9d28b136cdfe54db0f11c`. Original Emberfall prop-source GLB SHA-256: `2d20d4f79f650383e0370c00c0debf628dad0926509cb79bccff622a8797b749`. The physical handle anchor is source-local `(0, -0.147, 0)`, rather than the prop origin. The runtime support arm solves against original native lengths; left-hand casting and simulation release authority remain intact. The [new grip smoke test](../../../tests/source_avatar_grip_smoke.gd) measures actual indexed skin triangles and actual handle thickness, not an invisible skeleton proxy.

## Scope and limits

This source solves the inaccessible-original dependency independently and replaces the rejected procedural Arcanist construction. Other classes and enemies still use their existing models. This is a coherent, stylized authored starting point; it does not satisfy the detailed midnight-blue coat/bronze shoulder/braid reference, Diablo Immortal surface fidelity, distinct class-specific attack choreography, facial animation or a release-quality verdict. Real-device performance and continuous visual playtesting remain required.
