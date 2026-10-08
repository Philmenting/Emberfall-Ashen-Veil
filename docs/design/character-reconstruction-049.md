# Complete character reconstruction · development 0.49

The user's instruction to continue reaching the quality standard funds this
round after the [0.48 rebuild verdict](graphics-review-048.md). The subsequent
critique of the deformed character specifically makes whole-figure anatomy
the first task. The running release remains 0.48.0-beta.1, code 54; this
document's development number does not identify a built or accepted release.

This is a code-led continuation of the confirmed original Emberfall world:
mature dark fantasy inspired by Diablo Immortal, adult shared Nyra,
spatial 3D figures, steady camera and complete guardian warnings. There is no
new approved comp, decision comp, concept seed or quality-bar image for this
round. The existing painted environment reference is not an approved character
model. Retain identity; the old head topology may be reconstructed.

The first partial source-body sample retained the old procedural head and
remapped anatomical joints inconsistently. In the Arcanist, a 0.3108 m source
shoulder span became 0.640 m, with different torso and limb scale factors.
The independent complete-figure review rejected this construction. That
sample and its identity extracts do not establish an accepted character.

The first complete replacement sample uses one uniformly scaled anatomical source,
29 named native joints, exact inverse binds, source-derived palm and sole
sockets, and nine source-calibrated native clips. Source and runtime now share
the same anatomical origins. These structural checks address the measured
stretching, but are separate from the visual acceptance.

The initial native inspection still finds irregular shirt penetration through
the vest, doll-like face/eyes, an angular hairline, weak garment material finish
and an awkward casting wrist. One cohesive correction targets these defects.
Recapture the same normal, front, close construction and bind-face views,
with source hashes and whole-skin fall/contact checks, before a fresh review.
The correction's confirmation comprises 22 inspected original 1200 × 536
native captures, 175 physical checks with zero failures, and 240 simulation
steps; its 660 source inventory entries match before and after capture.
The fresh [complete-figure review](character-sample-review-049-fix1.md) returns
**rebuild**, because the head/eyes, molded hair, posed shoulder/sleeve contour
and plain costume still contradict the requested figure quality. The corrected
main vest does not have a confirmed current shirt-through-vest defect in those
pixels. Source-rest consistency closes the original nonuniform stretch; it
does not close the visible anatomy and material findings.

The continuing instruction to perform the full quality overhaul and the latest
specific rejection of the deformed character authorize the reconstruction.
A separate producer now owns the six named review directives as one cohesive
complete-asset rebuild, retaining the measured anatomical rest space and Nyra
identity. The rejected candidate stays out of the production body registry.
Only acceptance of the complete figure permits transferring its construction
to the other classes and foes. No sample approval is full-game acceptance.

The second complete source is frozen at GLB SHA256
`a974f41580be2c3f7d82efb35ab9f15ea4077ada12fef6bc917c4765a403dc37`
and profile SHA256
`cf8347da8c705fec1db499c831ce247a51d1535c1c96d6f605866f95db003bb1`.
Its 39,723 triangles include the unchanged 3,426-triangle original staff.
The source has anatomical shoulder surfaces and weights, reconstructed facial
planes, dimensional hair and fitted garment layers. These construction facts
are not a finish verdict. The complete candidate passed the unchanged 175
physical checks. Its 22 original native inspection views, 240 chronological
simulation steps and fully decoded eight-second clip are bound to 737 unchanged
source files before and after capture. This is a desktop development sample
using Godot 4.7.2 and llvmpipe, not a measured gameplay frame rate.

Root inspected all 22 original stills. The clip contains four seconds of the
ordinary first fight followed by four seconds of its first guardian; the
existing fixture skips the travel between them. Inspection views are excluded
from the clip. No continuous video playback was available to the image-viewing
tools, so encode/decode success and sampled poses cannot establish animation
smoothness. Normal guardian views also have natural combat overlap.

The fresh [full-figure review](character-sample-review-049b.md) again returns
**rebuild**. It recognizes coherent adult anatomical proportions and contact
with the original staff in the inspected poses. It rejects the doll-like
face, molded silver cap and rope braids, hard shoulder caps, padded chest and
stacked waist bands, weak cloth/boot construction, and claw-like free hand.
The complete focal material result still fails the mature dark-fantasy brief.
Source-rest and contact correctness do not change that result. The candidate
remains outside production and family transfer; no 0.49 release is built.
The next step is an authored character source with visibly constructed hair,
face and garments, with verified modification and distribution rights. Further
family expansion from this rejected procedural costume is paused. Prior and
current whole-figure rebuild verdicts are preserved rather than reported as
an accepted quality improvement.

The selected replacement input is now **Sintel Lite**, acquired from the
official Blender Foundation demo archive. The exact source Blender file has
SHA256 `749cfa866e79c3db2df3c6d287ebb9526e1d89801725c5f417d8eefd1870eb0f`.
Its original README and release/sharing pages specify CC-BY 3.0. A public-source
derivative requires Blender Foundation attribution, the license/source links
and a change notice. The archived file has all twelve actual images packed and
no external linked libraries. It supplies authored facial, garment, footwear
and hair construction rather than another generated costume.

This is an input choice, not adoption or a new approved Nyra design. The young
source likeness, original colors, film rig, particle hair and legacy materials
must be adapted to adult silver-haired Nyra, the native skeleton and actual
game camera. The source opens in Blender 5.1 with automatic script execution
disabled; original mesh/UV data, weights and four hair systems are available.
The new complete source is being constructed separately. Its authored hair
guides require an albedo coverage mask; the shader now discards source-atlas
coverage below 0.35 while opaque body texels remain alpha 1. The derivative
includes reverse hair faces within the existing triangle budget, preserving
runtime culling. The first authored native capture compiled this feature; visual
acceptance of the corrected complete source remains pending. No new model is in
the production registry.

The authored-source preflight caught an atlas-coordinate export error: Blender's
bottom-origin V coordinates were being used without conversion to glTF's image
coordinates. This mapped clothing and hair to the wrong tiles. The exporter is
being corrected together with the corresponding tangent handedness and fitted
mantle depth before native capture. The source render is a construction check,
not approval of the figure in the game. Native motion must use the new source's
actual palm frames, arm lengths and boot support geometry; the earlier body's
coordinates and posed-mesh bundle are not transferable evidence.

The first actual-source motion preflight passed 72 native clip checks and 69
Actor checks across basic/signature/heavy at 30/60/120 Hz, while retaining all
eleven original fallback animation libraries. The complete-surface suite still
failed six of its 175 checks. Its worst falling vertex was in the boots, bound
entirely to Pelvis, reaching 0.305 m below the floor at 0.183 s. Eighteen low boot
records had that incorrect binding because the source toe group was not mapped
to the native foot. This is a source-export defect, not a reason to raise the
whole figure or weaken the floor limits. Correct the mapping and repeat the
entire-surface proof. Some measured outsole points also have mixed Shin/Foot
weights; their actual skin influences must drive the fall-support calculation,
rather than treating all measured points as rigid Foot attachments. These
preflight results do not establish an accepted final source pair or appearance.

The corrected authored candidate is frozen at GLB SHA256
`3bc615271a244057859135cadb16504ccf1c64df17570a67cb7396dae0e8d318`
and profile SHA256
`c9fd9d026e09a67a45d78c16ab27ad7d6ea5185f472fef2bbf4af928af205401`.
Its self-contained source delivery has 83 read-only files and includes the
exact upstream blend/maps, conversion tools, final atlases, attribution,
actual poses, contact audit and native motion evidence. The final source
mapping has zero silent fallback vertices. All twelve measured outsole
supports retain their actual exported skin influences. Independent static
checks confirm the final atlas bytes, corrected tangent-space normal direction,
source hierarchy and source-package portability.

The repeated actual-source motion proof passes 72 native clip checks, all 175
complete-surface checks, and 78 Actor/weighted-support checks at 30/60/120 Hz.
The full falling surface reaches a minimum of -5.431 mm and settles at +2.117 mm
under the unchanged tolerances; this is not a perfect zero-floor result.
The exact source-calibration patch is now applied at SHA256
`7f58864865e7a3459be394b86bf3900db409d29a54fa6b6ad90996b204e5c2c8`.
It retains all eleven original fallback libraries exactly and keeps the damage,
release, recovery and fall clocks. The source-only fit adjusts the airborne
step landing and staff elbow pole; the fall now skins the actual measured boot
supports. No new model is registered in production.

The source contact audit still records sleeve, mantle and wrap intersections
in the actual poses. Since the body has open concealed surfaces, its local
oriented distances do not certify volumetric penetration depths. These
remaining findings were disclosed for the fresh whole-figure native inspection,
not treated as resolved by the successful motion/floor checks.

The complete native capture contains 240 chronological frames and 12 separate
inspection captures. Root and a fresh reviewer inspected all 22 required
original normal, bind, front and construction views. The independent report
`character-sample-review-049c.md` returns **fixes**, not acceptance: unfinished
silver hair, pale garment openings and flat shoulders, angular fingers, weak
material boundaries, white magic fragments and one truncated route instruction.
The eight-second encoded clip decodes completely; neither encoding nor still
inspection certifies continuous animation quality.

The finger spike is a proved source-export defect. Eight original skin vertices
have active finger-weight sums above 1. The old bake accumulated those weights
without normalizing all actual deformers, including inactive palm weights. This
displaced the worst finger vertex by about 150 mm and incorrectly sent it through
the head adaptation. One frozen rest triangle has a 153.088 mm edge, retained
unchanged by the runtime hand transform. Normalizing the actual source weights
predicts a 10.379 mm edge without deleting the fingertip or changing animation
timing. The correction is being built separately; the initial delivery stays
immutable.

One finite correction addresses that cause together with the review's existing
hair, garment, hand and material findings. Rounded colored magic volumes and a
shorter route label are implemented in the product code, preserving combat
timing, RNG and the existing HUD area. Their native shader compilation and
appearance are pending the corrected-source confirmation. No corrected model
has been accepted, registered or released.

The finite authored correction is now exported at GLB SHA256
`9992b5d9d4b2ff59d0e40d5b158e61bcf7526b3ac0f0ece21de3b9572a32f9aa`
and profile SHA256
`a43a7ac9283902dd49820172cdcb839b9d9c2798e87dee516d549b5f4820a343`.
Its complete figure has 39,710 triangles, including the unchanged 3,426-triangle
staff. The actual corrected spike edge is 8.502 mm, compared with 153.088 mm
before; all eight corrected source predictions match within 1 micrometre.
Neck reduction changes only Chest/Head skin influences, retaining vertex
positions and the complete anatomical rest. The five source preflight images
come from this exact GLB in a fresh empty Blender scene. They still show large
shoulder openings and angular garment boundaries. The initial suggestion that
the upper-Z sleeve cut caused missing shoulder faces was later disproved by
the actual source topology: removing that Z condition adds zero selected faces.
The rootward X cutoff is the cause; the connected source arm patch can be
extended to the measured shoulder tail. That P1 visual finding is explicitly
unresolved in the immutable FIX1 candidate.
Directional garment-attachment fitting is not a watertight containment proof.

The exact corrected pair passes 72 native clip checks, 175 whole-surface checks
and 78 Actor/contact/rate checks. Falling reaches -5.429 mm and settles at
+2.117 mm under unchanged limits. Actual native29 matrices and clocks in the
five inspected poses are identical to V2. The real groom height increases by
0.563 mm and the left casting-surface marker moves by 56.580 micrometres, which
the new Actor scale and markers account for. A failed isolated fixture attempt
with a missing new shader dependency is retained separately; it is not counted
as a successful suite. The finite native confirmation is now being captured
from a read-only exact runtime-pair snapshot. The producer's portable authoring
delivery has a separate inventory; it is not falsely claimed as part of the
runtime-pair capture inventory. Appearance acceptance and production adoption
remain open.

The first finite native confirmation is archived in
`character-sample-review-049c-fix1.md`. All 22 originals and all 666 current
capture source entries were verified. The reviewer returns **fixes**: colored
magic and route fitting substantially meet their requests, while original
items 1–4 remain partial or unresolved. The complete adult anatomy and casting
foundation are retained; no whole-source rebuild is requested. A second finite
correction under the user's continuing quality-overhaul instruction addresses
only those original items, in a separate FIX2 source folder. It does not alter
the immutable FIX1 pair, camera, warnings, combat timing or production registry.

The second finite confirmation is archived in
`character-sample-review-049c-fix2.md`. Its exact GLB/profile pair is
`063e75026cca9b8079136a8e360a6e2ef06f82c321626e275200cc49f60efb40` /
`e53e1471d4de2b9e06f7152f068edaf548a7c18076a355c29a75cb0a0db1f256`.
The final export contains 39,998 triangles, including the unchanged 3,426 staff
triangles. Hidden-face coverage and corresponding opaque clothing account for
the budget reduction; exposed neckline and wrist boundary faces are retained.
All rest joints, physical markers, feet, support skin, motion-fit and source
height fields remain exactly FIX1. The complete portable delivery contains
122 read-only files with a separately verified inventory.

Fresh native motion checks pass 72/0, 175/0 and 78/0. Root's separate capture
passes 175/0 and retains 240 chronological native frames plus 12 inspection
captures, with all 666 source hashes equal before, after and at verification.
Root and the same reviewer individually inspect all 22 required originals.
The eight-second clip is fully decoded, but it is not played continuously.
The fresh five-pose surface audit measures all 39,998 triangles; it retains
cloth-layer intersections and the non-closed body-skin limits rather than
claiming a watertight figure or continuous contact proof.

The second disposition is **fixes**. Hair/skin tonal coherence is met at the
sampled ceiling, and the dominant exposed shoulder wedges are closed. Garment
transitions, visible finger finish, and hip/material boundaries remain partial.
Colored magic and route fitting remain met; natural guardian overlap is still
a visibility ceiling with full sampled warnings preserved. No whole-figure
appearance, production adoption, physical-phone quality or release approval
is inferred. The user's continuing quality-overhaul instruction funds a new
bounded FIX3 batch for only original residual items 2–4; fixed hair values,
anatomy, shoulders, boots, grip and animation contracts are retained.

The third finite confirmation is archived in
`character-sample-review-049c-fix3.md`. Its exact GLB/profile pair is
`e5d4fe47cfaf18d04224d3c0520d53903b96d2720ab06d2f7aa41d398759deba` /
`2dfdc2e710b33265f096bf9d41a4e4a5303bffd319f7129782ff5259110c2d1d`.
Five interrupted torso surfaces are replaced by a continuous fitted bodice,
full lining, closed rims, curved neckline and hem. The complete export contains
37,958 triangles, including the unchanged 3,426 staff triangles. Its separate
130-file read-only portable authoring inventory is verified; the captured pair
is byte-identical to the portable pair.

Fresh native checks pass 72/0, 175/0 and 78/0. Root's unchanged capture passes
175/0 and contains 240 actual chronological frames plus 12 inspection images.
All 666 source entries remain equal before, after and at verification. Root and
the same reviewer individually inspect all 22 required original PNGs. The clip
fully decodes but is not played continuously. The fresh five-pose audit skins
all 37,958 triangles and reports zero body crossings for the sampled bodice,
sleeves, neckline, hem, belt and robe. It retains 712 wrap/skin pairs, sewn-layer
contacts and the open body-skin limits; it is not continuous watertight proof.

The third disposition remains **fixes**, with original garment item 2 visibly
resolved. It is not a zero-resolution round. Hair values, colored magic and
route fitting retain their previous sampled results. Visible finger/joint
finish and coarse loaded/released hip folding remain partial. The complete
guardian warnings remain visible within the same natural combat overlap.
The next authorized bounded FIX4 corrects only those original hand and hip
items, preserving the resolved torso, shoulders, belt, boots, hair values,
source anatomy, staff grip, support and animation contracts. No candidate body
has been adopted or released, and no full-game or physical-phone quality claim
is inferred from these development samples.

The current product animation-craft and combat-readability regression suites
also pass with 50 and 57 checks respectively, plus both server checks. These
107 checks cover the current implemented code, not adoption of a candidate
body or a new full-game regression result.

The rejected procedural builder's graphical inputs have explicit CC0 provenance, including
an adult female legacy diffuse. This is not a supplied measured skin PBR set;
roughness and micro-normal are authored. The source ZIP contains the builder,
helpers, inputs, maps, profile and GLB, but excludes optional Blender stages and
posed OBJs. The textured Blender stage uses absolute atlas paths that need
relinking after relocation. Its historical comparison verifier also requires
the previous rejected GLB; the builder itself does not require that candidate.

Architecture, moving reliquaries and defeat readability are also being revised
within the previously authorized overhaul. Their local proof does not close
the prior full-game findings. Full layout, combat, Android build and performance
evidence must follow the final integrated assets. No physical Pixel 9 Pro Fold
is available; neither desktop software rendering nor emulator success is a
physical-phone performance claim. No Play publication is part of this round.

## FIX4 construction status — blocked build001

The first FIX4 source build contains 39,522 triangles. Its exact GLB SHA256 is
`eb835b23a41165e4d7a769755159da21707be51c5f309a0c71374c78b406b169`
and profile SHA256 is
`2a2e812ef1fe651c4cf0084bebe0787d811b1208072b827dc2a0bbf000be860f`.
Root individually viewed all five original source-preflight images. They
inspect rest geometry only and do not establish native motion or acceptance.

The independent audit found that mesh reassignment lost the original skin
group definitions: all 4,787 `Skin` vertices used cage fallback, and 2,794
retained palettes changed. Checks of the 27 protected meshes and 189 arrays,
original hand-normalization probes, materials/maps, rests and supports passed,
but those results do not establish preservation of the complete skin weights.
This exact pair is blocked; no new native proof or adoption follows from it.

The source owner is staging a technical weight/tangent re-export. The `run001`
evidence is retained. Scope remains the original residual hand and hip finish,
with the previously resolved construction and animation contracts preserved.

## FIX4 construction status — corrected build002

One bounded technical weight/tangent re-export completed with exit code 0.
The corrected pair contains 39,522 triangles, including the unchanged 3,426
staff triangles. Its exact GLB SHA256 is
`329feed7da10b853e212db9a24ef3e2d793750ff9091a5a49a1c1571e61bd88d`
and profile SHA256 is
`791885b79a75eb3bda75853e92a0b5ff9d4bbe7d6140be4712b6e60daff64ef1`.
The 39-input inventory has SHA256
`97709456954ef52560eb0ba72a90318fba58e83b74b12bf88b06b32a99134cf7`.
No second source-preflight render was performed; the five previously inspected
original images remain build001 rest-geometry evidence.

The original 131 skin-group definitions were restored. The reconstruction
assertion covers 5,581 palettes, including 4,573 retained palettes. The
independent actual-array audit reports 13 passed checks, with SHA256
`cdcc370c6029079337678c221a21a07d07d95ee65e09d3e3c30075e2bc547303`.
It records zero retained-palette changes; 3,779 raw positions, 416 cap positions
and 3,193 lower-pants positions match exactly. The eight normalized-source
probes remain within 0.110 micrometres, and the corresponding GLB probes remain
within 0.036 micrometres.

The material/TBN audit JSON has SHA256
`69c8cd03a5853cc31c8ef2c4a4e899511e0cfa5e0a5ac0cf43f8c09d154e56d4`.
All arrays of the 27 protected meshes, all 15 materials, all three maps and the
staff emission match exactly. Only `Skin` and `Pants` tangents received the
technical repair. Their final float32 UV bitangent audit finds zero negative
alignments; two `Skin` and ten `Pants` zero-area UV triangles remain undefined
and are openly recorded. Inherited protected-mesh TBN findings remain
diagnostic and unchanged.

Fresh native motion proof completed with 72/0 native clip checks, 175/0
whole-surface checks and 78/0 Actor/contact/rate checks. All four engine
processes exited 0. The actual five-pose data has SHA256
`4e2486829ea97fe02875235c79a6a6189cd0538213a942342922b370bf78eed5`.
These passing results are retained and do not certify geometry acceptance.
Root's `native-confirm-input` snapshot contains only three read-only runtime-pair
files, not a portable authoring delivery. Scope remains the original residual
hand and hip finish. Appearance acceptance, production adoption, continuous
motion quality, physical-phone quality and release approval remain unclaimed.

A later independent geometry witness has SHA256
`9e1eb4dd0159130cc0a78a828c9524eb47399a50f64fef365cecd46c6a7f7501`.
It records eight exact zero-area `Pants` waist-seam triangles: 6150–6153,
6176–6177 and 6224–6225; duplicate-position pairs 6210/6211 and 6226/6227;
and 13 new nonmanifold edges, all in the appended waist seams. FIX3 had zero
such nonmanifold edges. This exact build002 pair remains **blocked** despite
the completed native checks. Root capture has not started. The source owner
is staging the necessary bounded technical seam cleanup within the original
hand/hip correction, preserving the established art and style.

## FIX4 construction status — seam cleanup build003

One bounded technical export completed with exit code 0, without rendering.
The frozen 40-input inventory has SHA256
`1cdf55333a445ad4eea8b3f54a203f9456450a3ff340642708b578c977806524`.
The actual read-only GLB SHA256 is
`432b9f7e6838041bf3b2a94109291c5c36353059534217efe9c3a4e2fe5b1792`
and profile SHA256 is
`ecb15e92e5905615790196236e8b1d7513a17295aff14334c35adad828bb8c9b`.
The complete figure contains 39,498 triangles: 6,402 in `Pants` and the
unchanged 3,426 in the original staff.

The seam repair uses 12 shared anchors and excludes only the overlapping
artist triangle 4823, the first triangle of original polygon 3016. The appended
waist seams now contain 146 triangles rather than 169. Source-stage and
independent actual-GLB topology checks report zero zero-area triangles,
duplicate-position pairs, nonmanifold edges and winding conflicts, with 92
boundary edges still present. This is not a watertight-containment claim.
Root's own actual-GLB topology check also passes and is recorded in
`notes/root-actual-glb-build003-topology.json`.

The independent audit reports 21 passed checks, with SHA256
`765699274e0fbb5a60d24894d3d05b316b5d00a50fdcba4390b73d80a7e3e8bf`.
It records zero retained skin-palette changes and exact preservation of 3,779
raw positions, 416 cap positions and 3,193 lower-pants positions. All eight
source oracles pass. The 27 protected meshes and 189 arrays, 17 physical
fields, rests, maps, materials and all 12 supports also match exactly.

The material/TBN audit has SHA256
`af4844fd4c0c4144b489ca471fb4a5c68de2a5d15b9e40852a924895fbba3408`.
`Skin` remains exactly build002. The audit finds zero negative bitangent
alignments; two `Skin` and four `Pants` undefined UV triangles are explicitly
excluded from that alignment result.

Root's new `native-confirm-input-build003` snapshot contains three read-only
runtime files; the prior build002 snapshot is untouched. Fresh native motion
proof has started in the new `sintel-049c-fix4-seam` fixture and has not yet
returned a passing result. No final source-preflight render or Root 22-view
capture has been made for this pair. Scope remains the original residual
hand/hip correction. Appearance acceptance, production adoption, continuous
motion quality, physical-phone quality and release approval remain unclaimed.


## FIX4 final native confirmation — visible finish ceiling

The final immutable build003 pair is `432b9f7e6838041bf3b2a94109291c5c36353059534217efe9c3a4e2fe5b1792` / `ecb15e92e5905615790196236e8b1d7513a17295aff14334c35adad828bb8c9b`, with 39,498 complete triangles. The authoring delivery contains 174 payload files / 63,649,448 bytes and 176 files / 63,700,408 bytes including inventory metadata. Its manifest SHA256 is `45c3cce9bf63b850bf57384483c2f2957033d1099e52a751e4f2bb7438531c75`; SHA256SUMS is `2a025e89b7e243a242b3e00c17e404359f824a466364ecf00ca0db6935099457`. The immutable inventory verifier passed again in Root's execution.

Fresh final Motion logs record 72/0, 175/0 and 78/0; the five COMPLETE actual pose dictionaries exactly equal FIX3 and blocked build002. The new actual bundle SHA256 is `f1149b899046312b0e35e9fc8f7856af7b8e786420a519f6599aaad4eca33afa`. Native Motion evidence has 44 read-only files and inventory SHA256 `b46826bd157e36e6ee6f1dc00d27b73570913675b9bfb89c67ae1fc055c9c2b3`. Its shell exit codes remain explicitly unverified; success lines do not fabricate process receipts.

Root's separate process receipt records physical 175/0 with actual exit0 / 19.740s. A first native launch failed before display initialization because Xvfb107 had ended. That exact attempt is preserved in `authored-fix4-display-failure-001`. After restoring the same display resolution, the runner verified unchanged source and physical-log hashes before resuming that complete physical case. The new native process completed with actual exit0 / 187.576s, 240 genuine 1/30s steps and 12 QA captures, totaling 252 original PNGs. The eight-second 240-frame/30fps clip was fully encoded and decoded; SHA256 is `61441491259e728e9886099e22bc3fa3d8930f79d22d8d7782db092008b359d9`. The runner's full verification passed; all 666 source inventory entries remain current and before/after match.

Root individually viewed all22 required originals at original resolution. A fresh ordinary substitute reviewer was used because the prior reviewer thread was unavailable. The exact fourth report is `character-sample-review-049c-fix4.md`, SHA256 `24aa9757b189ff714798fcd9cb004430168ddfa85f7fc72fefb2da2c5bc6bbe2`. Its disposition remains **fixes**: hand/joint finish (original3) and coarse loaded/released hip folding (original4) are still partial; original1/2/5 and route/warnings remain retained, with the real guardian-overlap visibility ceiling preserved. This is a **zero-resolution appearance round**, although necessary source weighting, TBN and seam defects were technically repaired.

The bounded hand/hip micro-correction sequence ends here. No further minor styling pass, extra angle or recapture is funded by this result. The figure is not adopted into the production BODY registries, which remain empty. No 049 release, full-game/class acceptance, physical-phone quality or continuous-video smoothness is claimed. The user's continuing complete-3D-overhaul authorization instead supports a distinct whole-avatar source feasibility assessment; that assessment must not disguise another local pass on the same rejected finish or preserve the incumbent head in a nominal new body.
