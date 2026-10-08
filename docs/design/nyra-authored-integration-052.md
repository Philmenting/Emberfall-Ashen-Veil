# Independently acquired Nyra source and actual game integration — 052

**Staff-grip correction:** the user correctly identified a visible grip defect in this revision. The earlier socket/continuity checks did not establish finger contact. The 052 images below are historical evidence of that state. [Correction 053, actual hand-surface checks and new renders](nyra-staff-grip-correction-053.md) supersede this document's staff-grasp claim; the authored body source remains unchanged.

The user cannot supply a model archive. That dependency is resolved: three original free CC0 Quaternius Standard packages were acquired anonymously through the manufacturer's official itch.io download flow. The actual Arcanist in Main combat and portraits now uses that authored source. No authenticated Sketchfab original, viewer extraction, paid package, account or purchase is involved. Earlier rejected procedural clothing/hair prototypes remain unregistered.

## Actual implementation

[Source/license/rebuild record](../../assets/models/nyra052/README.md), [source assembly inventory](../../assets/models/nyra052/assembly-report.json), [portable assembly script](../../tools/art/assemble_nyra052.py), [native source avatar renderer](../../scripts/source_avatar_rig.gd).

The actual imported avatar has eight rendered source meshes and 22,108 triangles: original adult head/eyes/brows, manufacturer-shaped silver buns hair, and the complete manufacturer Female Peasant outfit with arms, articulated gloved hands, trousers and boots. Its native65 hierarchy/rest matrices, referenced geometry, UV0 and original four skin influences remain intact. The manufacturer explicitly recommends retaining only the base head with these outfits; this composition has no full hidden nude base. No anatomy is stretched or reweighted onto the old29 rig. Only the existing staff is retained from Emberfall's older Arcanist.

Eleven artist animation clips are rest-relative retargeted offline from the supplied mannequin onto the unchanged female target skeleton. Runtime idle/walk/cast/recovery/death use those clips and preserve actual simulation contact, early projectile launch and gear statistics. Revision 052 attached the staff to the right hand, but its finger aperture and shaft were misaligned; revision 053 corrects this. The left palm is the projectile socket. A native two-link leg solver locks the stance ankle during real world movement; when the retargeted stance would exceed native leg reach, the pelvis height adapts without stretching bones. The measured test drift is below 0.001 mm over the 120-frame straight-travel fixture. A 31-sample measured whole-skin grounding curve fixes the source death clip's approximately 3 cm floor penetration; the staff settles separately above the same floor.

Original cloth 4K albedo/normal/ORM maps are resized to 2K using the real Godot Image operation; face/hair/eye maps remain genuine source files. The supplied eye-normal filename typo is resolved to its actual original PNG. Silver hair/darker eyebrows and reduced face-normal strength are material changes, not new sculpts or bakes. Original ZIPs, the resized build cache and acquired-source evidence remain in `/workspace/scratch/emberfall-character-source-052` and `/workspace/scratch/emberfall-authored-avatar-052`.

The portable script regenerated the model byte-for-byte: SHA-256 `d489ad6a55510a5bd36f0215fcb3be1a596cab6094500f19476e3fc172e7e4e1`. Target hierarchy equality was checked against the actual base/outfit/hair bones and local transforms. A packed, editable Blender conversion is included as [nyra052-editable-conversion.blend](../../art-source/nyra052/nyra052-editable-conversion.blend); this is an actual import of the verified GLB, not the original paid artist Blender source or a high-poly sculpt/bake source. All eight actual source meshes and 65 bones were checked. Blender's imported bone-display Icosphere is an editor helper, not extra avatar geometry.

## Actual rendering evidence

Godot 4.7.2, OpenGL Compatibility, software Mesa llvmpipe. Actual engine imports and production-actor studio execution returned zero with unchanged recorded inputs. Native screenshots are copied byte-for-byte; no generated beauty reference or image editing is used as model evidence. [Complete figure and staff](reference-052/idle-front.png), [face](reference-052/face.png), [cast contact](reference-052/cast-contact.png), [walk](reference-052/walk.png), [settled death](reference-052/death.png). These are diagnostic stills under studio lights, not the ordinary game camera or continuous movement acceptance.

The normal Main recording is 240 chronological PNG frames at a fixed 1/30 simulation second per recorded frame, using ordinary Arcanist gear, the existing HUD, camera and effects. It contains four seconds of the first fight and four seconds of the first guardian in the **same** expedition, with the exact intervening simulation advance recorded in the [manifest](reference-052/gameplay-manifest.json). [First-fight release](reference-052/gameplay-frame-0051.png), [guardian release](reference-052/gameplay-frame-0156.png). The engine returned zero in 158.396 seconds, without script/runtime errors and with all recorded inputs unchanged: [actual receipt](reference-052/gameplay-001-receipt.json), [log](reference-052/gameplay-001-process.log). A software-driver V-Sync warning remains; this is not a phone benchmark.

The eight-second MP4 `/workspace/scratch/emberfall-authored-avatar-052/gameplay-001/nyra052-gameplay.mp4` encodes all 240 frames at 1200×536/30 FPS; ffprobe counted all 240 frames. Encoding/decoding and selected frame inspection do not establish continuous visual playback acceptance. The guardian segment's camera origin and basis are constant in all 120 frames. The first segment includes the existing entrance pan; camera motion during that pan is not labeled zero. [Artifact hashes and scope](reference-052/artifact-manifest.json).

## Verification

[Actual regression receipts and summary](reference-052/checks-summary.json): seven completed suites, 1,476 checks, zero failures and no script/runtime errors in the passing logs. All recorded inputs remain unchanged.

| Suite | Checks | Result |
| --- | ---: | --- |
| Source avatar (all actually skinned surfaces, world foot lock, contact, class switch) | 39 | Pass |
| Character 3D (native65 plus all legacy actors) | 164 | Pass |
| Authored art and route dressing | 105 | Pass |
| World camera framing, all classes/regions/layouts | 900 | Pass |
| Visual effects and real spell socket | 73 | Pass |
| Complete dungeon, loot, replay and AFK (3× engine clock) | 55 | Pass |
| Combat stances and profile behavior | 140 | Pass |

 Logs were scanned for Script Error, Parse Error and ERROR in addition to process exit; a Godot zero exit by itself is insufficient. Native65 tests reconstruct every referenced source vertex with all original skin influences; the invisible legacy API proxy is not used as body evidence.

Existing legacy29 geometry/locomotion/contact/death checks remain for all other actors. New Arcanist checks use native bone names and real source surfaces. The authored cast reaches forward on its anatomical side, rather than asserting the former procedural wide side-step choreography. Projectile and material tests now use the semantic palm socket and source PBR contract rather than legacy indices/shader uniforms. Original contact, grip continuity, floor and simulation thresholds remain where they apply. Basic/signature/heavy still share the same source casting phrase; separate choreography is not claimed.

Earlier development checks exposed a scaled-basis staff interpolation error and a typed-array assignment error even when their test summary printed zero failures; those executions are not counted as passing. Both implementation errors were fixed and final logs were checked. The first complete-dungeon attempt was administratively terminated after 195.447 seconds: its three fixed 110-second timer waits exceed the selected 240-second runner budget. It produced no script errors but is not a passing complete-run result. The repeat uses Godot's declared 3× engine time scale with the same unmodified test assertions, permitting its timer-driven end-to-end checks to finish inside the budget. This accelerated functional check does not establish normal-speed visual quality; the separate recorded game frames use the ordinary 1/30 simulation step.

## Honest quality scope

This is a working authored foundation and a substantial replacement of the rejected malformed Arcanist. It remains visibly stylized: chunky buns/fringe, angular face/cloth edges and the stock brown/ivory outfit do not match the requested detailed dark-blue coat, bronze armor and braid or Diablo Immortal's character-art fidelity. Source facial blendshapes/blinking and separate attack choreography are absent. The source PBR outfit currently keeps its stock appearance; the former legacy shader equipment tints and cosmetic damage flash are not applied to these imported materials. Equipment statistics and world combat effects remain functional. Other heroes/enemies/guardians retain their existing assets; shared Nyra identity across all classes is not complete. The actual ordinary camera sometimes obscures the small heroine behind the much larger guardian. Those visible limitations remain; passing deformation tests does not erase them.

No APK/store release/version bump, phone profiling or Beta/publication-quality verdict is claimed. Original release identifiers remain unchanged. No further user-provided source archive is needed for this selected source route.
