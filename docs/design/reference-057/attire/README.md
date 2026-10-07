# Native attire finish 057

This pass keeps the source GLBs, textures, original UVs, indices, four-weight
native Skin and 65-bone rest hierarchy intact. Textiles and leather receive
cached derived normals across matching smooth seams while edges exceeding
58 degrees stay hard. Exposed skin surfaces are excluded. Original imported
index LODs and normal-only fused shadow meshes remain available.

The Arcanist's coat, leather facing and bronze now have distinct readable
runtime PBR values. Ranger textile, belts, boots and bracers distinguish matte
cloth from worn leather. Vowkeeper retains its independent steel panels.

Secondary motion updates existing native-skinned vertex buffers, without
additional meshes, surfaces or draw passes. Waist, scalp and front hood
attachments stay pinned. Coat tails and their bronze bindings use the same
spatial displacement field. Ranger uses rear hood folds and rear tunic cloth;
Vowkeeper uses loose bun ends and rear tunic cloth. Death and reduced motion
restore the exact rest positions. Repeated poses and held reduced-motion/death
perform zero redundant uploads. Original figure bones, hands and held weapon
transforms are unchanged by this detail layer.

| Class | Dynamic surfaces | Eligible moving vertices | Bytes per dirty vertex upload |
| --- | ---: | ---: | ---: |
| Arcanist | 5 | 1,661 | 50,004 |
| Ranger | 2 | 662 | 48,300 |
| Vowkeeper | 2 | 1,284 | 75,432 |

These are actual native mesh inventories and upload byte counts, not phone
frame-time measurements. No new ArrayMesh is created during an animated pose;
only `surface_update_vertex_region` writes the cached actor-owned buffer.

The dedicated attire test passed **306 headless checks** across **33 poses**.
Godot Dummy storage deliberately ignores vertex-update calls, so the headless
run explicitly checks CPU upload data, native-skin floor/bounds and work budgets
and claims **zero GPU readback poses**. The separate X11 GL run with
`--require-gpu` passed **339 checks** and **33 real GPU readback poses**. It
compares both `RenderingServer.mesh_get_surface(...).vertex_data` and
`ArrayMesh.surface_get_arrays()` against independently computed uploaded
positions after diagnostic `force_sync()`. That synchronization never runs in
ordinary play. All imported LOD distances/indices are checked, bindings stay
within 0.5 mm of the corresponding cloth displacement, and all posed geometry
remains within the current native-skin envelope and above the floor.

The sampled maximum geometric offset is **14.2501 mm** for Arcanist cloth and
**6.5647 mm** for either rear tunic. Declared hard displacement envelopes are
17 mm for cloth, 4 mm for hair ends and 6 mm for the rear hood. Death samples
use zero secondary displacement; the lowest exact posed garment/hair point is
2.99999 mm above the floor for Ranger and Vowkeeper. This is bounded kinematic
secondary animation, not a cloth or hair physics simulation.

The existing source-style test passed **135 checks**, before the final coat
tone correction. Native equipment/portrait finish passed **129 checks** after
fixing the real legacy `HeroArt.configure()` caller which had tried to access
the removed native proxy shader. The initially misleading exit-zero run with
six script errors remains in its original log and the execution receipt; it
is not counted as accepted validation. Final native attire and equipment runs
have no script, shader, parse or compile diagnostics.

[`native/`](native/) contains twelve unedited **1200×1200** production actor
stills: idle front, walk rear, heavy windup front and heavy windup rear for all
three classes. Real layer-2 key/rim lighting is enabled and the staff crown is
inside the camera frame. Audio is explicitly Dummy for studio tests, with no
audio claim. Original first-tone stills are retained in
[`native-first-tone/`](native-first-tone/), including their receipts. Inspecting
those original images revealed overly black caster cloth caused by using
linear GLB color factors as direct runtime sRGB values. The final muted slate
cloth, bronze and leather values fix that visibility problem; the final
native files retain the actual renderer output without image edits.

[`execution-receipt.json`](execution-receipt.json) preserves actual process
exit codes, commands, original log hashes, failed display startup, failed
portrait caller and final successful retries. This proof was produced before
the final shared production commit, so `source_not_frozen` is explicit. It is
diagnostic actor evidence and does not replace the ordinary full combat clips,
final repository checks or physical-phone measurements.

The underlying authored silhouette and bun hairstyle remain stylized. This
pass improves surface finish and controlled motion; it does not replace the
wardrobe topology or claim commercial AAA model quality.

An independent resumed review checked the twelve final original images at full
1200×1200 resolution and verified all 35 receipt-referenced image/log hashes
before copying them into this proof leaf. The exact original logs, first-tone
images and execution receipt are retained.
[`independent-review-receipt.json`](independent-review-receipt.json) records the
reviewed image names and verifies the mirrored bytes. No new Engine execution
was used during this review. Static poses do not establish temporal continuity;
the final ordinary class expeditions and repository checks remain separate.

Read-only source review also checked the derived attire buffers, preserved
LOD indices, named native binds, per-actor shield Skin, phase material ownership,
source pose restoration, lazy replay resources and the removed proxy-shader
callers. No additional actionable regression was identified in that scope.
The inspected source snapshots are recorded separately from historical run
evidence in [`source-review-snapshot.json`](source-review-snapshot.json).
