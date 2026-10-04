# 0.48 character-source assessment

**The full character-art reconstruction remains unfinished.** Two bounded
source proofs were built and inspected in native Godot 4.7.2. Neither costume
justifies replacing the eleven existing figures. No candidate body, material,
texture or runtime import branch was adopted. The 0.48 cast/bow changes animate
the existing 0.47 models.

| Proof | Useful result | Reason for rejecting adoption |
| --- | --- | --- |
| Flare heroine armor | Separate chest and waist plates, articulated overlaps and shaped footwear; source skeleton has a real rib cage and pelvis. | Faceted hands, collar and sabatons; patchy leather; the ordinary rear view still lacks the requested finish. |
| MPFB/MakeHuman anatomy with original fitted costume | Continuous arms, knees, feet and individually modeled fingers; right hand wraps the existing staff. Native 29-bone retarget is feasible. | Shoulder and neck openings, plain cuffs, coarse folds and unfinished garment panels. The anatomy is useful; the costume is not ready for a family. |

Both proofs preserved the existing Nyra head and original Emberfall weapons.
The MPFB proof used the exact ordinary Arcanist camera transform from the
0.48 motion trace, FOV 38, at 1200×536. Its front views are closer construction
inspections. Isolated lighting and a neutral floor do not establish whole-game
appearance. Guard/load/release snapshots establish deformation at those poses,
not complete walk/death/attack/equipment validation or normal-speed finish.

The MPFB sample totals **39,645 triangles**, including 25,846 inherited
head/crown/staff triangles. Body-only counts would conceal its near-40k total.
All 29 native rest positions matched within 1.2e-7 m; source weights were
resolved by joint name, normalized and limited to four influences. Source
fingers are posed offline and assigned to the existing hand channels; this
does not add finger animation. None of these technical results is visual
acceptance.

## Source record

The Flare source is Clint Bellanger's [hero and heroine](https://opengameart.org/content/isometric-hero-and-heroine),
CC-BY 3.0, from [revision 8830c68](https://github.com/flareteam/flare-game-art-src/tree/8830c68b420b631e09a459e5b0bf87c0e068a558).
Only heroine plate cuirass, greaves, gauntlets and boots entered the isolated
proof. No source weapons, shields or heads were selected. The bundle's
distressed leather credit names D. Sharon Pruitt, CC-BY; its linked original
photograph is unavailable and the version is unspecified. It was not adopted
for distribution in the game. Third-party Blender scripts were not executed.

The MPFB data is from [revision d0a32e5](https://github.com/makehumancommunity/mpfb2/tree/d0a32e57a7f915cb2f2b95410e2117648c7bbb7e).
[License section C](https://github.com/makehumancommunity/mpfb2/blob/d0a32e57a7f915cb2f2b95410e2117648c7bbb7e/LICENSE.md)
and [the asset license](https://github.com/makehumancommunity/mpfb2/blob/d0a32e57a7f915cb2f2b95410e2117648c7bbb7e/LICENSE.ASSETS.md)
place graphical data under CC0. The base mesh, adult shape targets, vertex
groups, game-engine rig and weights were used as data; MPFB GPL Python code
was not imported, executed or copied into the independent generator. The
source head was excluded. The sample garment surfaces were derived from
anatomical helper surfaces and cut as original blouse, vest, trousers, boots
and split skirts.

Sample textile maps were Lennart Demes / ambientCG
[Fabric020](https://ambientcg.com/a/Fabric020) and
[Leather037](https://ambientcg.com/a/Leather037), under the
[CC0 license](https://docs.ambientcg.com/license/). Albedo, OpenGL normal and
roughness maps were dyed and rebaked to the sample UVs. These maps and their
derivatives are also unadopted.

Full source hashes, license snapshots, generators and native proofs remain in
the local assessment directories `/workspace/scratch/emberfall-figure-assessment`
and `/workspace/scratch/emberfall-mpfb-assessment`. They are research records,
not exported game assets or a portable build dependency.

## Remaining art work

The next figure construction must solve the actual garment pattern and
silhouette before family production: a joined neck/collar, deliberate cuffs,
credible armor overlaps, exposed support-leg motion, fitted hands and boots,
and restrained wear visible at ordinary camera scale. Preserve Nyra's identity
and the guardian emblems. Validate the whole posed body, including inherited
head and equipment, within the rendering budget. Merely switching a mesh's
source or adding more generated surface detail did not resolve this problem.
