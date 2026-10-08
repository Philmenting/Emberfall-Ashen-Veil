# Same-host render comparison: 0.46 / 0.47

The new geometry and materials increase the measured cost of this software-rendered workload, despite fewer draw calls. This result does **not** support a performance-improvement claim. It remains a limitation of the current test candidate.

One sequential baseline/candidate pair used Godot 4.7.2, the same Linux Xvfb display and Mesa llvmpipe (LLVM 19.1.7, 256 bits), the same guardian fixture, 30 measured frames per case and no competing game capture/test renderer. Both revisions used logical 1212×540 Balanced rendering and 606×270 Battery rendering, with a 2424×1080 native window. The manifest fixes both source commits and raw report hashes.

| Region | Mode | 0.46 median ms/frame | 0.47 median ms/frame | Frame-time change | Median draw calls |
| --- | --- | ---: | ---: | ---: | ---: |
| Hollow Spire | balanced | 388.913 | 637.343 | +63.9% | 267 → 225 |
| Hollow Spire | battery | 96.392 | 113.991 | +18.3% | 207 → 188 |
| Drowned Archive | balanced | 291.994 | 429.121 | +47.0% | 244 → 231 |
| Drowned Archive | battery | 94.882 | 105.326 | +11.0% | 205 → 199 |
| Ossuary | balanced | 336.623 | 602.267 | +78.9% | 269 → 226 |
| Ossuary | battery | 95.521 | 124.484 | +30.3% | 221 → 192 |
| Cinder Citadel | balanced | 271.985 | 493.093 | +81.3% | 231 → 231 |
| Cinder Citadel | battery | 88.471 | 106.991 | +20.9% | 210 → 208 |

Lower frame time is better. These are software-GPU measurements from one pair of runs, not statistically repeated benchmarks, game-loop averages or physical Android frame pacing. Both runs separately passed all four native skeleton/motion checks. The frozen render workload does not measure active gameplay CPU work or the savings from skipping hidden previews.

The complete p95 measurements and case metadata remain in [baseline](baseline-046-controlled.json), [candidate](candidate-047-controlled.json) and [source manifest](controlled-manifest.json). Baseline source is `2d89d5be1070f069645d46c63c98f3d347ddce2d`; candidate runtime source is `2648672c4e7700ed57d223bd3a9fb7bf1e874491`. No sustained phone FPS, thermals, battery or touch test was possible. The local performance-report UI and [device test procedure](../../../play/DEVICE_TESTS.md) prepare that next measurement; they do not replace it.
