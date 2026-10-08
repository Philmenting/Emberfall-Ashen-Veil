# Built reliquaries · 0.49

Four original hinged props replace the plain guardian chest boxes: an iron-bound
Spire coffer, a raised Archive records chest with bronze fittings, a carved stone
Ossuary casket and a riveted Citadel coffer. The construction includes joined
corners, actual wall thickness, a visible inner chamber, lid sections, handles,
hinge knuckles and fitted clasps.

Rebuild from the repository root with Blender 4.3.2, after finalizing the shared
environment generator:

```sh
blender -b -t 2 --python tools/art/build_reliquaries_049.py
```

The source is [build_reliquaries_049.py](../../../tools/art/build_reliquaries_049.py).
It imports only the original environment primitive library and writes these
four GLBs plus `manifest.json`. Reimport with Godot 4.7.2. Exports use local metre
UVs and tangents, with no embedded raster images or required Draco compression.

`RuinArchitecture.create_reliquary(world, region=-1)` returns the complete prop.
Its direct children are `Body` and `ChestLid`. The rear lid pivot is exactly
`(0, 0.68, -0.43)` metres; `rotation.x` from zero to `-1.1` opens the lid while
the body stays fixed. Front is +Z. Root and meshes carry `dynamic_reliquary=true`
and must remain outside static batching. The World owns position, `LootBeam`,
interaction and reward state.

Props are approximately 1.50 m wide, 0.98 m deep and 0.92–1.01 m tall. They use
1,948–3,516 triangles and three to five material meshes total. `oak`, `iron`,
`bronze` and `dressed_stone` reuse the existing per-world material families.
The exact bounds, hinge contract, surface counts and SHA256 values are recorded
in the manifest, together with both source hashes and the authoring version.

[LICENSE-SOURCE.txt](LICENSE-SOURCE.txt) records original model provenance and
the existing material sources without claiming a new public asset license.
