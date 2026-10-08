#!/usr/bin/env python3
"""Read-only verification of completed, explicitly sampled AI visual reviews."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
EVIDENCE = ROOT.parent / "gameplay-final-evade"
if not EVIDENCE.is_dir():
    EVIDENCE = ROOT.parent  # Completed repository gameplay leaf uses class/side.
SOURCE = "1cc13152a83c6631590d4df32ca298700a417df7"
BASELINE = "86cb1b8ec878b4ae06daba5e6c5a4fa583865dc5"


def sha(path):
    h = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for block in iter(lambda: stream.read(1048576), b""):
            h.update(block)
    return h.hexdigest()


def verify(slug):
    plan_file = ROOT / f"{slug}-review-plan.json"
    plan = json.loads(plan_file.read_text())
    comparison_file = EVIDENCE / f"{slug}-comparison.json"
    if not comparison_file.is_file():
        comparison_file = EVIDENCE / slug / "comparison.json"
    comparison = json.loads(comparison_file.read_text())
    assert comparison["status"] == "verified_complete_ordinary_expedition"
    assert comparison["current_git_source_audit"]["source_commit"] == SOURCE
    assert comparison["baseline_git_source_audit"]["source_commit"] == BASELINE
    assert sha(comparison_file) == plan["comparison_sha256"]
    valid_tool_hashes = {sha(ROOT / name) for name in ("review_final.py", "review_final_cropped.py", "review_final_vowkeeper.py")}
    sheets = set()
    decode_receipts = []
    for side in ("before", "after"):
        capture_file = EVIDENCE / f"{side}-{slug}" / "receipt.json"
        if not capture_file.is_file():
            capture_file = EVIDENCE / slug / side / "receipt.json"
        capture = json.loads(capture_file.read_text())
        assert capture["status"] == "complete"
        assert all(capture[key] == 0 for key in ("godot_process_exit", "ffmpeg_process_exit", "ffmpeg_full_decode_exit"))
        assert capture["inputs_unchanged"]
        for segment in plan["ranges"]:
            folder = ROOT / slug / side / segment["label"]
            receipt_file = folder / "decode-receipt.json"
            receipt = json.loads(receipt_file.read_text())
            assert receipt["status"] == "complete_consecutive_h264_decoded_range"
            assert receipt["actual_ffmpeg_exit_code"] == 0
            assert receipt["every_consecutive_frame_decoded"]
            assert receipt["source_commit"] == (SOURCE if side == "after" else BASELINE)
            assert receipt["first_frame_zero_based"] == segment["first"]
            assert receipt["last_frame_zero_based_inclusive"] == segment["last"]
            assert receipt["movie_sha256"] == capture["mp4_sha256"]
            assert receipt["capture_receipt_sha256"] == sha(capture_file)
            assert receipt["review_tool_sha256"] in valid_tool_hashes
            command = receipt["actual_ffmpeg_command"]
            assert command[command.index("-threads") + 1] == "1"
            assert command[command.index("-filter_threads") + 1] == "1"
            for sheet in receipt["sheets"]:
                path = folder / sheet["file"]
                assert path.stat().st_size == sheet["bytes"]
                assert sha(path) == sheet["sha256"]
                sheets.add(str(path.relative_to(ROOT)))
            decode_receipts.append({"file": str(receipt_file.relative_to(ROOT)), "sha256": sha(receipt_file)})
    viewed = set()
    reviews = []
    original_pngs = 0
    review_files = set(ROOT.glob(f"{slug}-*-human-review.json")) | set(ROOT.glob(f"{slug}-*-ai-review.json"))
    for review_file in sorted(review_files):
        review = json.loads(review_file.read_text())
        assert review["source_commit"] == SOURCE and review["baseline_commit"] == BASELINE
        assert "AI" in review.get("reviewer_type", "")
        items = review.get("viewed_files")
        if items is None:
            # Preserve the delegated leaf receipts' original nested schemas.
            # Their explicit actually_viewed records are evidence, not merely
            # a summary count or an inference from decoder completion.
            pairs = review.get("pair")
            if pairs is None:
                pairs = [pair for area in review["coverage"] for pair in area["pair"]]
            items = []
            for pair in pairs:
                assert pair["actual_ffmpeg_exit_code"] == 0
                assert pair["every_consecutive_frame_decoded"]
                items.extend(pair["files"])
            assert len(items) == review["viewed_file_count"]
            assert all(item["actually_viewed"] is True for item in items)
        for item in items:
            if "original_native_png" in item:
                path = ROOT.parent / item["original_native_png"]
                if not path.is_file():
                    original = Path(item["original_native_png"])
                    original_side, original_slug = original.parts[1].split("-", 1)
                    path = EVIDENCE / original_slug / original_side / Path(*original.parts[2:])
                original_pngs += 1
            else:
                path = Path(item.get("file", item.get("path", "")))
                if not path.is_absolute():
                    path = ROOT / path
                elif not path.is_relative_to(ROOT):
                    # Preserve absolute original execution labels in receipts,
                    # but verify their immutable staged class/side bytes locally.
                    class_index = path.parts.index(slug)
                    path = ROOT / Path(*path.parts[class_index:])
                viewed.add(str(path.relative_to(ROOT)))
            assert sha(path) == item["sha256"]
            if "bytes" in item:
                assert path.stat().st_size == item["bytes"]
        reviews.append({"file": review_file.name, "sha256": sha(review_file)})
    assert sheets == viewed, {"unreviewed": sorted(sheets - viewed), "extra": sorted(viewed - sheets)}
    result = {
        "schema": 1,
        "status": "all_retained_derived_sheets_have_recorded_ai_visual_inspection; quality_concerns_remain",
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "character_class": slug,
        "source_commit": SOURCE,
        "baseline_commit": BASELINE,
        "comparison_sha256": sha(comparison_file),
        "actual_native_capture_and_full_decode_exits": "Both finalized captures have actual Godot, FFmpeg encoder and complete media decode exit0; this verifier runs no engine.",
        "planned_ranges_per_side": len(plan["ranges"]),
        "actual_successful_range_decode_receipts": len(decode_receipts),
        "all_retained_derived_sheet_files_recorded_as_actually_inspected": len(sheets),
        "separately_inspected_original_native_pngs": original_pngs,
        "decode_receipts": decode_receipts,
        "ai_visual_review_receipts": reviews,
        "human_signoff_claimed": False,
        "release_readiness_claimed": False,
        "limits": [
            "AI inspection of bounded, retained frame samples; neither complete movie was watched frame by frame.",
            "Derived H264 pixels remain lossy, including PNG contact sheets; JPEG92 context sheets add another documented compression step.",
            "Successful capture/result/hash verification does not resolve the recorded Hexer/Guardian release-readability concerns.",
            "No bone-detail-none ankle/anatomy proof, full death-completion approval, physical phone FPS or general beta quality acceptance inferred.",
        ],
        "verifier_sha256": sha(__file__),
    }
    output = ROOT / f"{slug}-temporal-review-verification.json"
    if EVIDENCE != ROOT.parent:
        output.write_text(json.dumps(result, indent=2) + "\n")
    # In the staged repository layout verification is read only: never rewrite
    # a finalized hardlinked summary or invalidate its staging receipt hash.
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("character_class", choices=("arcanist", "ranger", "vowkeeper"))
    args = parser.parse_args()
    result = verify(args.character_class)
    print(json.dumps({key: result[key] for key in ("status", "character_class", "planned_ranges_per_side", "actual_successful_range_decode_receipts", "all_retained_derived_sheet_files_recorded_as_actually_inspected", "separately_inspected_original_native_pngs")}))
