# Same-host render comparison: 0.47 / 0.48

This controlled workload is cheaper in every measured case. Median frame time
fell **44.0–51.1% in Balanced and 11.8–18.1% in Battery**. This is a measured
software-renderer improvement; it does not establish physical-phone FPS.

One sequential baseline/candidate pair used Godot 4.7.2, the same Linux Xvfb
display and Mesa 25.0.7 llvmpipe (LLVM 19.1.7, 256 bits), the same frozen
guardian workload, 30 measured frames per case and no competing capture,
game renderer or test process. Logical rendering was 1212×540 Balanced and
606×270 Battery, with a 2424×1080 native window. Both runs separately passed
all four 29-bone/nine-clip motion checks.

| Region | Mode | 0.47 median ms/frame | 0.48 median ms/frame | Frame-time change | Median draw calls |
| --- | --- | ---: | ---: | ---: | ---: |
| Hollow Spire | balanced | 626.084 | 308.061 | -50.8% | 225 → 229 |
| Hollow Spire | battery | 115.647 | 97.699 | -15.5% | 188 → 191 |
| Drowned Archive | balanced | 457.603 | 256.456 | -44.0% | 231 → 232 |
| Drowned Archive | battery | 105.182 | 90.930 | -13.5% | 199 → 199 |
| Glass Ossuary | balanced | 603.337 | 295.084 | -51.1% | 226 → 230 |
| Glass Ossuary | battery | 119.645 | 105.484 | -11.8% | 192 → 195 |
| Cinder Citadel | balanced | 501.795 | 246.075 | -51.0% | 231 → 227 |
| Cinder Citadel | battery | 109.408 | 89.553 | -18.1% | 208 → 209 |

Lower frame time is better. Draw calls are not the same as rendering cost:
most of these cases retain similar counts while the simpler material path
reduces fragment work. This comparison measures the complete changed room
and material pipeline, not an isolated shader microbenchmark.

The full p95 measurements remain in [baseline](baseline-047-controlled.json)
and [candidate](candidate-048-controlled.json). The
[source manifest](controlled-manifest.json) records commits, run duration and
report hashes. Baseline source is `5fe18facda9a8a8dcbd0b86e8e7eb605ce748154`;
candidate runtime is `850721fd010dd62ddbf1a6c681f73955ffddc8b3`. All 665 copied
baseline source files were verified by SHA256 before the run. The candidate
runtime was committed and unchanged during measurement.

This is one pair of runs, not a statistically repeated benchmark. The frozen
render workload does not measure active-game CPU work. The earlier
[0.46/0.47 regression](../render-047/README.md) remains an accurate historical
result; different measurement sessions must not be joined into a new controlled
0.46/0.48 comparison. Physical Pixel 9 Pro Fold frame pacing, heat, battery and
touch response remain unverified. Use the [device procedure](../../../play/DEVICE_TESTS.md)
for that separate acceptance step.
