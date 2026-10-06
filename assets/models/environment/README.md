# Native regional construction · 0.49

These are original, lit 3D assets for the real route, not painted environment
plates. Four regions each provide a thin broken bay, alternate broken bay,
narrow wall remnant, low functional return and pierced transverse end wall.
The new feet and end walls carry the aisle through its exposed joins. Archive
bank geometry leaves its native water openings unobstructed.

Rebuild from the repository root with Blender 4.3.2:

```sh
blender -b -t 2 --python tools/art/build_ruin_environment.py
```

This writes the 20 named GLBs and `manifest.json` in this directory. The complete
authoring source is [build_ruin_environment.py](../../../tools/art/build_ruin_environment.py).
Reimport the project with Godot 4.7.2 after generation. Draco compression is not
required; exports are ordinary uncompressed glTF binary meshes.

Coordinates are Godot Y-up metres, front +Z and bay depth -Z. `UVMetres` contains
signed planar coordinates in local metres. Exported tangents support the shared
masonry material's instance-scale compensation. `masonry`, `dressed_stone` and
`paving` are explicit separate material families; paving receives the exact same
court material instance. The remaining native metal/wood families use the
existing material atlas and caches. No new raster or external model is included.

[ruin_architecture.gd](../../../scripts/ruin_architecture.gd) places complete
parts only after the authoritative passage checks. The World retains its normal
static batching and chamber tags. Ground continuations follow the actual court
union, skip basin holes and close only unpaired exposed end profiles. They add
at most two shadowless meshes per chamber; shared internal ends are omitted.

The Guardian court, room 5, has **no camera-near return in any region**. This is
an explicit reserve for the full danger envelope, which can extend past the
walk rectangles. It uses no dynamic disappearance, camera changes or altered
warning shapes. Other room returns and opposite load-bearing ruins remain.

[LICENSE-SOURCE.txt](LICENSE-SOURCE.txt) distinguishes original geometry from
the existing textures' licenses. The manifest records source and model hashes,
exact tool version, rebuild command, bounds, triangles and material surfaces.
Native proof images alone establish neither complete scene acceptance nor
physical-phone performance.
