# Android 0.48 validation

All three workflows passed on implementation source
`850721fd010dd62ddbf1a6c681f73955ffddc8b3`:

- [Gameplay Quality](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37212951293): 34 Godot suites, 3,642 checks, zero failures, plus both server checks.
- [Android build](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37214678280): version `0.48.0-beta.1`, code `54`, ARM64, API 36, APK signatures, AAB and 16 KB ELF alignment verified.
- [Android runtime, attempt 2](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37214680237/attempts/2): first fight, actual reading pause and Back resumption, relic, protected gear, bag filtering, combined oaths and cold restart. All four regions rendered in Balanced and Battery. Separately stepped combat advanced the native 29-bone/nine-clip figures. `graphics_only:true`; unchanged AFK reconciliation was not rerun.

[Download the CI test packages](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37214678280/artifacts/11307604661).
Use **`emberfall-closed-beta-ci.apk`** for the offline test. The archive also
contains `emberfall-debug.apk` (the separate online-test package) and
`emberfall-beta-ci-release.aab`. These use temporary CI signing keys; they are
not a Google Play release and compatibility with another signing key is not
established. Export an existing save before any uninstall. GitHub currently
retains the package artifact until 18 October 2026.

The runtime workflow's first attempt ended before emulator testing: the
exporter exited with code 250 after asset import, with a final ADB daemon
connection-refused message. The second attempt passed with identical source.
The log establishes that sequence, not a definitive cause of the first exit.
The successful emulator run also logged host graphics-context warnings; its
application checks and capture validation completed.

[ci-summary.json](ci-summary.json) records exact source/run relationships,
verified archive and package SHA256 digests, and all 28 decoded native Android
images. All 28 were inspected in labelled contact sets; the
[first fight](android-success-first-fight.png) and
[actual reading pause](android-success-skill-reading.png) were also opened
from their original files. These two archived PNGs have unchanged pixels and
embedded origin metadata. The complete native images and device logs remain
in [runtime artifact 11307984396](https://github.com/Philmenting/Emberfall-Ashen-Veil/actions/runs/37214680237/artifacts/11307984396).
No continuous Android playback is claimed.

[Render measurements](render-performance.json) come from an Android 16/API 36
Pixel 6 profile using the `sdk_gphone64_x86_64` emulator and `swangle` software
renderer. Median frame times were 1299.093–1768.492 ms in Balanced and
549.252–604.609 ms in Battery. This verifies finite measurements and advancing
animation, **not** the 60/30 FPS targets. Different CI runs do not establish a
controlled before/after performance improvement. The separate
[sequential Linux comparison](../render-048/README.md) reduced median frame
time in every case on the same software renderer and workload.

No physical Pixel 9 Pro Fold was attached. Sustained FPS, frame pacing,
temperature, battery drain and touch response remain unmeasured. See the
[physical-device procedure](../../../play/DEVICE_TESTS.md).

Filtered [build/regression](build-and-regression-checks.txt) and
[runtime](runtime-checks.txt) logs retain actual success lines. Technical
validation is separate from the [native visual evidence](../../../previews/constructed-world/README.md)
and the fresh [finish review](../../../design/graphics-review-048.md), which
returns `rebuild`. The existing figure finish remains unresolved.
