# Native gameplay 004 — functional-only static attack review

**Result: no additional concrete attack-deformation failure observed in the ten specified originals.** The first-fight frames retain coherent body/head/limb and staff silhouettes through the sampled windup, release, and recovery positions. The guardian frames are smaller and substantially occluded by the boss, limiting what they establish about shoulder, wrist, and finger details. This is **static-sample evidence only**, not continuous-motion or gameplay acceptance.

The source art sequence stays **closed** with original F4 partial and correction 2 yielding zero additional resolutions. This report adds no art categories or proposed appearance changes. The separate [studio functional review](native-studio-functional-review-004.md) confirms an open death-body-support defect; these selected attack frames contain no Nyra settled-death evidence and do not close that defect.

## Actual original observations

Frames 44/47/51/54/59 show Nyra in the first fight at a useful whole-character scale. The silhouettes change from more upright gathering to a lower/wider cast posture and recovery. The head remains attached; torso and legs remain recognizable; there is no obvious exploded shoulder, severed limb, inverted hand mass, or detached staff head in these specific pixels. The samples show a projectile near the target and later damage/combat-state changes, but their spacing does not establish exact projectile launch timing or animation smoothness.

Frames 149/152/156/159/164 show the same character during the first guardian encounter. Some posture/staff changes are visible, but the boss and its telegraph obscure much of Nyra. I see no gross exposed silhouette failure. I cannot approve individual wrist/finger or shoulder deformation from these small, occluded views. This is an evidence limit rather than a request for new camera or render work.

Only these **10 of 240** gameplay originals were personally inspected. I did not watch playback or review the encoded clip. A clip's encoding or successful full-frame decoding does not turn this selected-still review into a continuous movement review. No assertion is made about interpolation, foot sliding, pacing, responsiveness, or complete transition quality.

The manifest also records an editorial progression cut from simulation elapsed 4.0 s to 69.5 s. The sampled first-fight and guardian groups therefore should not be described as one seamless eight-second expedition progression. Within each sampled group, the originals remain chronological.

## Provenance read after pixel review

All ten PNGs below were opened individually with `view_image(detail="original")` before hashes or metadata were read. No engine/renderer, image edit, source-art change, angle generation, or playback tool was used by this reviewer.

The actual game receipt reports exit code **0**, elapsed **171.874 s**, `inputs_unchanged=true`; its complete `inputs_before` and `inputs_after` dictionaries also compare equal. It launched the native gameplay test scene at 1200×536 with the frozen source build 004 GLB/profile. The manifest records 240 frames, 1/30 s per recorded simulation step, inherited game camera/UI/effects, ordinary starting gear, the same expedition's first guardian, and empty production registrations. These are provenance/context facts, not visual quality acceptance.

Manifest group labels after review: frames 44–59 are `first_fight`; frames 149–164 are `first_guardian`. Their listed samples are attack time 0.0, 0.1, then 0.233333 s with release times 0.0, 0.1, and 0.266667 s. The original visual judgment was made before consulting those labels.

Pinned GLB SHA-256: `78b60e80146a2ee2da6b94f9e013324a4670b8db629cfceb9f15fd2050443584`. Profile SHA-256: `a47fa2a370ef5c367dca193a795574e06bc6a82c4ab31a80f71980fbd311460a`.

Receipt-pinned fixture inputs under `runtime-overlay-001/`:

| Frozen input | SHA-256 |
|---|---|
| `tests/native_avatar_gameplay_050.gd` | `7c69dad61753d03950542df5c66d6613aa4407ffe5a3adfea7e97bb1b1a33af1` |
| `tests/native_avatar_gameplay_050.tscn` | `b24f7d38f3a9d3d649267b7cca9e00e0b33e328795441d5ae41f18ea537d83ff` |
| `tests/attack_gameplay_preview.gd` | `12333afd1d7694b13939e48ac67c095f6f832d4eb959d5ef74bf230988748fdc` |
| `scripts/native_avatar_rig.gd` | `c089dcbde6f037f99f1fdd1c3217f7c9f4a2dd7b08bfc1c163fd921c62f0a262` |

These identify the run's frozen inputs, not any later runtime working-file revisions.

All image paths are under `/workspace/scratch/emberfall-native-proof-050/native-gameplay-004/captures/`.

| View order | Actual original | SHA-256 |
|---|---|---|
| 1 | `frame-0044.png` | `cb5e8e6acec50552b8480c1a6b0ebf06a2cc55f1e2ac6a3516880abcbbf644d4` |
| 2 | `frame-0047.png` | `6a6bc5b78df693aab5e8f22c49868ed61671c623b7726c0716d2e29e777d20dd` |
| 3 | `frame-0051.png` | `18989c2c8b210b34c6a1d6457a47adaa6e7c5bd31c52c091c43e5cc5cf7af8df` |
| 4 | `frame-0054.png` | `13042afd502972bc49e38853f3ee120440be61fde30f2b646a72ebe8c97b4d65` |
| 5 | `frame-0059.png` | `68729d0c8299172b9f1a1e0ddd94b3f145ca01b1b9d92b4a9e3022229add0c33` |
| 6 | `frame-0149.png` | `06804d68db1c8fc0671a7cf2b16b1db6055df9b37a57aeba37ee35b0969992b6` |
| 7 | `frame-0152.png` | `df1acacb31d32e71a89f5bf1a112c67db832de710195481e0ddae47b13146db8` |
| 8 | `frame-0156.png` | `a3620902133f248c45ece9b94f0a86963dec18be4f05682572bcea63465638a1` |
| 9 | `frame-0159.png` | `66aaa86c25c155dc066564ad2181e9a2b4e6b12609b2769e453a815abbee1426` |
| 10 | `frame-0164.png` | `64f448001dc1b0fbd32e8c7feea2a541ee624cb616c4b7138e843ed4a33ab9d6` |

Parent directory `/workspace/scratch/emberfall-native-proof-050/native-gameplay-004/`:

| Pinned record | SHA-256 |
|---|---|
| `receipt.json` | `bbeb9951ca054f2b3f6135be3245deb1542a7b6e249ea814d81dded64dbf5e1a` |
| `process.log` | `aba6ee4da8e3befbac7df870b621b28c2c112432e20240ff99c5ce18021cf33d` |
| `captures/native-gameplay-manifest.json` | `e9048bdfc2fb024b520c662020bfc43943b304817f01301f90aadf63cb26d4fe` |
