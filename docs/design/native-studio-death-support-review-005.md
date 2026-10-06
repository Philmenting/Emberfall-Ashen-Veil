# Native studio 005 — corrected death-body support review

**Existing functional finding: RESOLVED in the corrected settled static sample.** Narrow finding count: **1 resolved / 0 partial / 0 unresolved**. The former studio 004 failure—an entirely suspended corpse with only the staff visibly near the floor—is no longer present.

The source art sequence stays **closed**: original F1–F3 resolved, F4 partial, correction 2 zero additional resolutions. This review opens no appearance finding and does not approve the overall art finish.

## Pixel verdict, reached before metadata

I opened corrected `death_settled.png` first, then `idle_front.png`, `basic_projectile_launch_0215.png`, and `source_proportion_fullbody.png`, each individually with `view_image(detail="original")`. I then reopened the actual studio 004 death original for direct comparison. All five image views preceded hashes and receipt/manifest metadata.

In corrected studio 005, the hip/lower-body silhouette and boot edges meet the floor/shadow region. The corpse has visible body/boot support rather than hanging completely above its ground shadow. The staff is no longer the sole visibly near-floor component. In studio 004, the torso, legs, and boots had clear air gaps while the staff jewel/end reached the floor region. That specific difference resolves the confirmed functional support finding.

The corrected upper torso and head remain raised above the floor. I am not treating the support finding as a requirement for every body part to lie flat, and I am not endorsing every aspect of the final death pose. The narrow verdict is that the formerly entirely airborne, staff-propped body now has visible lower-body/boot support.

The three controls retain coherent adult body, head, limb, hand, and staff silhouettes with no visible change from their prior reviewed samples. After the visual verdict, their hashes were checked: all three are byte-identical to studio 004. No attack/body-art category is reopened.

This is a **settled static-sample verdict only**. I did not watch a collapse transition or playback, and cannot endorse continuous falling, timing, interpolation, collision throughout the fall, or later recovery. No engine, renderer, source edit, source inspection, new angle, or image transformation was performed by this reviewer.

## Pinned actual evidence

After pixel review, the actual studio 005 receipt was read: exit **0**, elapsed **12.648 s**, not timed out, `inputs_unchanged=true`; full input hash dictionaries also compare equal. The unchanged fixture hash is `d56706f9a751b9e73436408eb15d9107cd01530c0d2595d19ac8796ac13940c4` for `tests/native_avatar_preview_050_v2.gd`. The receipt-pinned corrected runtime adapter hash is `f7e41613af82754a0716414961d5b3fb541aa73bbaddd2b5ccf4fbeafefd09fe` for `scripts/native_avatar_rig.gd`. These identify the actual run inputs, not any future working-file revision.

The manifest retains source build 004 GLB SHA-256 `78b60e80146a2ee2da6b94f9e013324a4670b8db629cfceb9f15fd2050443584`, profile SHA-256 `a47fa2a370ef5c367dca193a795574e06bc6a82c4ab31a80f71980fbd311460a`, and 1500×1200 studio captures. Process success and numerical checks were not used to decide the pixel verdict.

Corrected originals are under `/workspace/scratch/emberfall-native-proof-050/native-studio-005/captures/`.

| View order | Actual original | SHA-256 |
|---|---|---|
| 1 | `death_settled.png` | `d15c544d1b150671dcf69318320268f645d95fc25ef0d8df3ac199c22d5bc56d` |
| 2 | `idle_front.png` | `2eb8b4fe3721155f8b6f22ad18ab31fbc6807c059a31441d8c12d2cf1f14cb3e` |
| 3 | `basic_projectile_launch_0215.png` | `945445cdeabc8e2bd29ea691a85278631fc9f3f71b27cef11cf5b529e9b0557b` |
| 4 | `source_proportion_fullbody.png` | `4d5d6afa0f9601d6ed3933ec1ff7874f0d44166108fb1e31e5d89e513de7825e` |
| 5 | Reference: `native-studio-004/captures/death_settled.png` | `b784d6593c28993b6d2fa2812e21634934108cf887a786a756fc9c1f7be30b3e` |

Parent records under `/workspace/scratch/emberfall-native-proof-050/native-studio-005/`:

| Record | SHA-256 |
|---|---|
| `receipt.json` | `5691cf0f7794c165a52460e50a8ad1b7b6f83f5947b9b86d7389609c6dd29c00` |
| `process.log` | `4eda19a9d1dfb3ae741d6d71db33a60427e28a41ad7a8135d62ed2f119a42ade` |
| `captures/preview-manifest.json` | `6c56201c46aa6609c3a58e1b95c9d32e36c2ea803a0ef0330faff4db098ac9ae` |
