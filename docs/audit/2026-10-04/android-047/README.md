# Android 0.47 validation

All three runs passed on implementation source
`2648672c4e7700ed57d223bd3a9fb7bf1e874491`:

- [Gameplay Quality](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37204815585): 34 Godot suites, 3,635 checks, zero failures, plus server checks.
- [Android build](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37204844727): version `0.47.0-beta.1`, code `53`, ARM64, API 36, APK signatures, AAB and 16 KB ELF alignment verified.
- [Android runtime](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37204846316): first fight, real reading pause and Back resumption, relic, protected gear, bag filtering, combined oaths and cold restart. All four regions rendered in Balanced and Battery; separately stepped combat advanced the native 29-bone/nine-clip figures. `graphics_only:true`; unchanged AFK reconciliation was not rerun.

[Download the CI test packages](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37204844727/artifacts/11304004713).
The archive contains `emberfall-debug.apk`, `emberfall-closed-beta-ci.apk`
and `emberfall-beta-ci-release.aab`. These use temporary CI signing keys;
they are not a Google Play release and update compatibility with another
build is not established. Export an existing save before any uninstall.
GitHub currently retains this artifact until 18 October 2026.

[ci-summary.json](ci-summary.json) contains exact run/source relationships,
verified archive and package SHA256 digests, and all 28 decoded native Android
image records. Two originals are archived here with unchanged pixels and
embedded origin metadata: [first fight](android-success-first-fight.png) and
[reading pause](android-success-skill-reading.png). The full native image and
device-log set remains in runtime artifact `11304374038`.

[Render measurements](render-performance.json) come from an Android 16
Pixel 6 profile using the `sdk_gphone64_x86_64` software emulator. Median
frame times were 1665.681–2143.638 ms in Balanced and 657.872–765.087 ms in
Battery. This gate verifies finite measurements and advancing animation;
it does **not** establish the 60/30 FPS targets. A different CI run is not a
controlled before/after performance comparison.

A separate [sequential Linux comparison](../render-047/README.md) recorded
higher frame times for 0.47 in every case. It uses the same host and workload
for both versions and remains distinct from physical Android performance.

No physical Pixel 9 Pro Fold was attached. Sustained FPS, frame pacing,
temperature, battery drain and touch response remain unmeasured. See the
[physical-device procedure](../../../play/DEVICE_TESTS.md).

The filtered [build/regression](build-and-regression-checks.txt) and
[device runtime](runtime-checks.txt) logs retain actual success and metric
lines. Visual quality is assessed separately in the
[0.47 review](../../../design/graphics-review-047.md).
