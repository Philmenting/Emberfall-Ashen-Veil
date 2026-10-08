# Bounded AI motion review proof

This review compares native ordinary autoplay captures of source `1cc13152a83c6631590d4df32ca298700a417df7` with baseline `86cb1b8ec878b4ae06daba5e6c5a4fa583865dc5`. The [motion report](../MOTION_REVIEW.md) records actual per-class scope, visual findings and remaining presentation limits. Original movies, journals, receipts and selected Godot PNGs are under `../<class>/<before|after>/`; the sheets in this folder are derived review aids.

Each class has a review plan, completed range-decode receipts, explicit AI inspection receipts, a retained coverage inventory and a temporal-review-verification JSON. Decoder exit 0 and media hashes do not by themselves establish that pixels were viewed. The separate AI receipts bind each actually inspected sheet. Historical Arcanist filenames ending `human-review.json` are retained execution labels: their `reviewer_type` explicitly identifies AI inspection, and no human signoff is claimed.

Escape/cancellation/recovery-interruption sheets retain every consecutive frame of the bounded interval. Longer hero phrases retain every second frame plus exact semantic boundaries; scene context retains every fourth frame plus exact transitions and boundaries. Crops keep decoded pixels at 1:1. H264 is lossy even when decoded sheets are stored as PNG. Other sheets add JPEG92 4:4:4 compression. Original native PNGs are separately identified and counted. Crop omissions, occlusion, repeated panels and temporal gaps are explicit limitations.

The supplemental Ranger Guardian 2280–2283 comparison is under `ranger-critical-guardian-idle/`; it is excluded from the main planned sheet counts. Vowkeeper BEFORE-only classification/coverage corrections are preserved under `vowkeeper-review-preparation-history/` and indexed by `vowkeeper-review-scope-correction.json`; those historical plans are not paired visual acceptance. Interrupted older derivative output remains unchanged in scratch and is indexed in the report, rather than presented as a completed review.

The earlier Vowkeeper verifier failed on a nested receipt schema, while the explicit image records already existed. Its failed log and compatibility receipt remain unchanged. The generic verifier now validates both original leaf schemas; all three fresh final byte-verification process exits are 0. This is not a production or missing-inspection regression.

From the repository root, verify finalized proof bytes without rewriting the staged summaries:

```sh
python3 docs/design/reference-057/gameplay/temporal-review/verify_review.py arcanist
python3 docs/design/reference-057/gameplay/temporal-review/verify_review.py ranger
python3 docs/design/reference-057/gameplay/temporal-review/verify_review.py vowkeeper
```

`coverage_inventory.py <class>` prints retained/decoded counts without modifying proof. Rerendering is outside these verification tools: the frozen decode tools retain their original scratch execution paths and original capture layout. No full-movie viewing, human signoff, complete death-clip approval, physical phone performance or beta/release acceptance is inferred.
