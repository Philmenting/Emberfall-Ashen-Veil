# Independent final build003 validation

The frozen candidate and profile match the supplied SHA-256 identifiers. No Blender/Godot process was run by this validator, and no source or production artifact was edited.

Protected complete body/head/hands/native facial meshes/staff exported positions, indices, UVs, skin attributes, object transforms, native53 hierarchy/rest and inverse bind matrices match immutable004 exactly: **204 passes**. Original source topology/UV-corner proof: **3 passes**. Full source snapshot and anatomical socket landmarks: **12 passes**. All original positive source influences are retained, including vertices with more than four influences; maximum normalized weight error is **1.246973424517961e-7**, discarded positive influences **0**. New actual003 captured native poses were independently reconstructed from original GLB bytes: **207 passes** for skin extrema, physical outsole support, sockets, unchanged anatomical root and bounds consistency.

The complete GLB/profile audit remains **FAILED: 1,234 passes, 12 failures affecting 10 authored clothing meshes**. This result supersedes neither the real failure nor the visual review. Build001's 314 collapsed hair cap UV triangles are corrected: build003 has zero collapsed UV triangles throughout. Build003 introduces other technical garment problems:

| Mesh | Actual defect |
| --- | --- |
| Authored051_Coat_Side_L:0:nonmanifold_duplicate_winding | `{"welded_vertices":165,"boundary_edges":48,"boundary_components":1,"boundary_branch_vertices":0,"nonmanifold_edges":0,"same_direction_shared_edges":3,"duplicate_triangles":0}` |
| Authored051_Coat_Side_R:0:nonmanifold_duplicate_winding | `{"welded_vertices":165,"boundary_edges":48,"boundary_components":1,"boundary_branch_vertices":0,"nonmanifold_edges":0,"same_direction_shared_edges":3,"duplicate_triangles":0}` |
| Authored051_Fitted_Sleeve_l:0:nonmanifold_duplicate_winding | `{"welded_vertices":200,"boundary_edges":40,"boundary_components":2,"boundary_branch_vertices":0,"nonmanifold_edges":0,"same_direction_shared_edges":5,"duplicate_triangles":0}` |
| Authored051_Fitted_Sleeve_r:0:nonmanifold_duplicate_winding | `{"welded_vertices":200,"boundary_edges":40,"boundary_components":2,"boundary_branch_vertices":0,"nonmanifold_edges":0,"same_direction_shared_edges":5,"duplicate_triangles":0}` |
| Authored051_Lapel_1:0:nonmanifold_duplicate_winding | `{"welded_vertices":55,"boundary_edges":28,"boundary_components":1,"boundary_branch_vertices":0,"nonmanifold_edges":0,"same_direction_shared_edges":4,"duplicate_triangles":0}` |
| Authored051_Pelvic_Crotch:0:zero_area | `4` |
| Authored051_Pelvic_Crotch:0:nonmanifold_duplicate_winding | `{"welded_vertices":271,"boundary_edges":64,"boundary_components":1,"boundary_branch_vertices":0,"nonmanifold_edges":5,"same_direction_shared_edges":75,"duplicate_triangles":0}` |
| Authored051_Pelvic_Crotch:0:TBN | `{"tangent_unit_max_error":6.16312026977539e-05,"normal_tangent_dot_max":0.5088320970535278}` |
| Authored051_Pelvic_Yoke:0:nonmanifold_duplicate_winding | `{"welded_vertices":1216,"boundary_edges":128,"boundary_components":2,"boundary_branch_vertices":0,"nonmanifold_edges":0,"same_direction_shared_edges":144,"duplicate_triangles":0}` |
| Authored051_Trouser_l:0:nonmanifold_duplicate_winding | `{"welded_vertices":260,"boundary_edges":40,"boundary_components":2,"boundary_branch_vertices":0,"nonmanifold_edges":0,"same_direction_shared_edges":4,"duplicate_triangles":0}` |
| Authored051_Trouser_r:0:nonmanifold_duplicate_winding | `{"welded_vertices":260,"boundary_edges":40,"boundary_components":2,"boundary_branch_vertices":0,"nonmanifold_edges":0,"same_direction_shared_edges":6,"duplicate_triangles":0}` |
| Authored051_Undershirt_Continuous:0:nonmanifold_duplicate_winding | `{"welded_vertices":2240,"boundary_edges":128,"boundary_components":2,"boundary_branch_vertices":0,"nonmanifold_edges":0,"same_direction_shared_edges":9,"duplicate_triangles":0}` |

The crotch surface contains four zero-area triangles, five nonmanifold edges and a normal/tangent dot error of 0.508832. Other flagged surfaces have shared edges traversed in the same direction, proving inconsistent adjacent triangle winding. These are observed exported-data defects, not waived intentional seam boundaries. No further model construction was performed by this validator.

Actual inventory: 58,228 triangles, 33,448 exported vertices, one native53 skin. Hair tangent attributes remain absent; current conditional tangent contract permits this because hair has no normal map. That permission is not evidence of authored hair tangent frames or advanced hair shading.

The root's separate visual review remains failed. Technical consistency of the unchanged anatomical source cannot establish garment fit, visual quality, continuous animation smoothness, beta readiness or performance on a physical device. No artistic PASS is inferred.

Exact candidate/profile/capture/report hashes are pinned in `source003-validation-manifest.json`. Historical source001 failure reports remain unchanged.
