# Native studio 004 — functional-only visual review

**Result: one confirmed functional defect in settled-death support.** The sampled idle/walk/cast/recovery images show no additional concrete gross body, shoulder, wrist, or hand deformation failure. This is a review of eleven static samples, not endorsement of continuous movement.

The source art correction sequence remains **closed**: original F1–F3 resolved, original F4 partial, zero additional finding resolutions in correction 2. This functional review neither reopens F4 nor accepts the requested high-quality appearance.

## Confirmed functional finding: settled death is unsupported

In the actual original `death_settled.png`, the torso, clothed legs, and boots are visibly suspended above the studio floor. A clear air gap separates the low body/garment/boot outlines from the floor/shadow. The staff's jewel/end is the only visibly near-floor part. The image does not show the body supported by a hip, torso, shoulder, arm, or boot.

This independently confirms the supplied death-ground-contact concern. A minimum over the complete character plus staff would not establish body support: the staff may supply that minimum while the corpse remains airborne. Pixels establish the visible contact defect; they do not identify the responsible runtime offset or joint. The correction must be verified against actual body/boot support, with corrected original pixels, rather than declaring success from a complete-assembly minimum.

This finding is **open on studio 004 evidence**. A runtime correction being prepared elsewhere is not reviewed or presumed successful here.

## Other sampled functional observations

The source-proportion and idle frames retain a coherent adult body/head relation and recognizable limbs. The walk sample shows a bent/raised foot and a supporting foot without an obvious limb collapse in that pose. Gather/load/launch/recovery samples retain readable torso and arm silhouettes. The launch hand close-up shows a recognizable palm, thumb, and four separated fingers with a continuous wrist/sleeve transition; the head close-up shows no obvious detached facial/head elements. The staff assembly remains visibly coherent through the sampled cast positions.

These are bounded observations of stills. They do not prove interpolation quality, foot sliding, speed, continuity, timing, return-to-idle completion, or a complete walk/death transition. They do not establish mobile acceptance or production readiness. No additional functional finding is opened from these samples.

## Evidence and actual process receipt

All eleven originals below were opened individually with `view_image(detail="original")` before hashes or metadata were read. No engine, renderer, source inspection, image edit, new angle, or appearance correction was performed by this reviewer.

After pixel review, the actual receipt was read: exit code **0**, elapsed **10.585 s**, `inputs_unchanged=true`; its full `inputs_before` and `inputs_after` dictionaries also compare equal. This confirms execution provenance, not pose quality. The preview manifest identifies native source build 004 and a 1500×1200 capture size.

Pinned candidate GLB SHA-256: `78b60e80146a2ee2da6b94f9e013324a4670b8db629cfceb9f15fd2050443584`. Profile SHA-256: `a47fa2a370ef5c367dca193a795574e06bc6a82c4ab31a80f71980fbd311460a`.

Receipt-pinned studio fixture `tests/native_avatar_preview_050_v2.gd`: `d56706f9a751b9e73436408eb15d9107cd01530c0d2595d19ac8796ac13940c4`. Receipt-pinned runtime adapter `scripts/native_avatar_rig.gd`: `c089dcbde6f037f99f1fdd1c3217f7c9f4a2dd7b08bfc1c163fd921c62f0a262`. These identify the run's frozen inputs, not any later working-file revisions.

All image paths are under `/workspace/scratch/emberfall-native-proof-050/native-studio-004/captures/`.

| View order | Actual original | SHA-256 |
|---|---|---|
| 1 | `source_proportion_fullbody.png` | `4d5d6afa0f9601d6ed3933ec1ff7874f0d44166108fb1e31e5d89e513de7825e` |
| 2 | `idle_front.png` | `2eb8b4fe3721155f8b6f22ad18ab31fbc6807c059a31441d8c12d2cf1f14cb3e` |
| 3 | `idle_threequarter.png` | `2b1aaf8add2b9b2f9c20306eb8f849cfe320325089f82cc0acf73a28d4a66eb5` |
| 4 | `walk.png` | `5f470fb447b5392abcd1f606d431b4f20681bd5c0db4bc3f842b41036bc8edd8` |
| 5 | `windup_gather.png` | `2ba6ed4b3f33c314753d2608b950e5182d5b135272979c8a611ee9e400776ad7` |
| 6 | `windup_load.png` | `1953a7e64bcfb4f615a525391729e797486d680fc845404eb32297be19fcc886` |
| 7 | `basic_projectile_launch_0215.png` | `945445cdeabc8e2bd29ea691a85278631fc9f3f71b27cef11cf5b529e9b0557b` |
| 8 | `basic_projectile_launch_0215_hand_closeup.png` | `bb52c42c6e505c1a2490334dba3abd15518fe7ebc536aba9cffa2c7bd9ffea0e` |
| 9 | `basic_projectile_launch_0215_head_closeup.png` | `41aeaa0dd58c57f1fbbe195da79669012b845ecacb9b0b1db256a33f6ab24425` |
| 10 | `recovery.png` | `fdf81dbe049b180b2c0327e81e6da60d454c32a232f73a880942837658b7d5e3` |
| 11 | `death_settled.png` | `b784d6593c28993b6d2fa2812e21634934108cf887a786a756fc9c1f7be30b3e` |

Parent directory `/workspace/scratch/emberfall-native-proof-050/native-studio-004/`:

| Pinned record | SHA-256 |
|---|---|
| `receipt.json` | `f35f91264b55042e636e8ba892c483c9a5f287e51ff0d0936ca2f7233e96a704` |
| `process.log` | `5efffeb2f066506d38816bb5de530003caa83100eb3024670703774a81cc3bde` |
| `captures/preview-manifest.json` | `fc84bfc63037805394d7186dff66651f1f51087a4a5f3307028a4400ff800f80` |
