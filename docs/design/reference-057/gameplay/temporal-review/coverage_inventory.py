#!/usr/bin/env python3
"""Inventory bounded retained samples; never infer visual signoff from decoding."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parent
SOURCE = "1cc13152a83c6631590d4df32ca298700a417df7"
BASELINE = "86cb1b8ec878b4ae06daba5e6c5a4fa583865dc5"
def inventory(slug):
    plan = json.loads((ROOT / f"{slug}-review-plan.json").read_text())
    sides = {}
    for side in ("before", "after"):
        retained, decoded = set(), set()
        panels = sheets = 0
        for segment in plan["ranges"]:
            decoded.update(range(segment["first"], segment["last"] + 1))
            receipt = json.loads((ROOT / slug / side / segment["label"] / "decode-receipt.json").read_text())
            assert receipt["status"] == "complete_consecutive_h264_decoded_range"
            assert receipt["actual_ffmpeg_exit_code"] == 0
            for sheet in receipt["sheets"]:
                sheets += 1
                panels += len(sheet["frames"])
                retained.update(sheet["frames"])
        sides[side] = {
            "range_count": len(plan["ranges"]),
            "decoded_unique_frame_count": len(decoded),
            "decoded_frame_count_with_overlapping_ranges": sum(x["last"] - x["first"] + 1 for x in plan["ranges"]),
            "retained_sheet_file_count": sheets,
            "retained_panel_count_including_overlaps": panels,
            "retained_unique_frame_indices": sorted(retained),
            "retained_unique_frame_count": len(retained),
        }
    return {
        "schema": 1,
        "status": "bounded_retained_coverage_inventory; actual_visual_inspection_bound_by_separate_receipts",
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "character_class": slug, "source_commit": SOURCE, "baseline_commit": BASELINE,
        "sides": sides,
        "note": "Decoded frames are not a human/full-movie viewing count. Retained panels require separate AI inspection receipts; overlapping ranges and repeated role-death samples are not unique visual samples. Original native PNGs and supplemental critical Guardian sheets are counted separately.",
        "inventory_tool_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
    }
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("character_class", choices=("arcanist", "ranger", "vowkeeper"))
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    result = inventory(args.character_class)
    if args.output:
        assert not args.output.exists(), "Never overwrite a prior inventory receipt"
        args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({"class": args.character_class, "sides": {side: {key: value for key, value in facts.items() if key != "retained_unique_frame_indices"} for side, facts in result["sides"].items()}}))
