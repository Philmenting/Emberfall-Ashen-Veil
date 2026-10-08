#!/usr/bin/env python3
"""Append immutable derived review proof only after the complete gameplay leaf."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SOURCE = "1cc13152a83c6631590d4df32ca298700a417df7"
BASELINE = "86cb1b8ec878b4ae06daba5e6c5a4fa583865dc5"
CLASSES = ("arcanist", "ranger", "vowkeeper")


def sha(path):
    h = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for block in iter(lambda: stream.read(1048576), b""):
            h.update(block)
    return h.hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path("/workspace/Emberfall-Ashen-Veil"))
    args = parser.parse_args()
    leaf = args.repo / "docs/design/reference-057/gameplay"
    session = json.loads((leaf / "capture-session-receipt.json").read_text())
    assert session["status"] == "six_complete_native_recordings_and_three_verified_full_comparisons"
    assert session["source_commit"] == SOURCE and session["baseline_commit"] == BASELINE
    target = leaf / "temporal-review"
    assert not target.exists(), "Never overwrite a prior staged temporal review"
    assert not (leaf / "MOTION_REVIEW.md").exists(), "Never overwrite a prior final review report"
    from verify_review import verify
    for slug in CLASSES:
        verify(slug)
        comparison = json.loads((leaf / slug / "comparison.json").read_text())
        assert comparison["status"] == "verified_complete_ordinary_expedition"
        assert comparison["current_git_source_audit"]["source_commit"] == SOURCE
        assert comparison["baseline_git_source_audit"]["source_commit"] == BASELINE
    files = []
    for child in ROOT.iterdir():
        if child.name in CLASSES or child.name in ("ranger-critical-guardian-idle", "vowkeeper-review-preparation-history"):
            files.extend(p for p in child.rglob("*") if p.is_file())
        elif child.is_file() and (child.suffix in (".py", ".json", ".log") or child.name == "README.md"):
            files.append(child)
    # Interrupted and provisional review artifacts remain unchanged in scratch.
    # They are indexed in the report and never represented as complete reviews.
    logical_bytes = sum(p.stat().st_size for p in files)
    assert logical_bytes <= 160 * 1048576, "Final three-pair derived review exceeds its160MiB storage allowance"
    report = ROOT / "MOTION_REVIEW.md"
    assert report.is_file() and "All three finalized pairs" in report.read_text()
    linked = []
    target.mkdir()
    for source in sorted(files):
        relative = source.relative_to(ROOT)
        destination = target / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        os.link(source, destination)
        a, b = source.stat(), destination.stat()
        assert (a.st_dev, a.st_ino) == (b.st_dev, b.st_ino)
        linked.append({"path": str(relative), "original_execution_path": str(source),
                       "sha256": sha(source), "bytes": a.st_size, "same_inode": True})
    os.link(report, leaf / "MOTION_REVIEW.md")
    receipt = {
        "schema": 1,
        "status": "three_completed_bounded_ai_temporal_reviews_appended_after_all_six_gameplay_proofs",
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "source_commit": SOURCE,
        "baseline_commit": BASELINE,
        "files": linked,
        "sum_final_review_logical_bytes": logical_bytes,
        "additional_proof_data_bytes": 0,
        "review_report_sha256": sha(report),
        "scope": "Exact original review bytes linked into the completed gameplay leaf. Original native movies/PNGs are in class/before and class/after; derived sheets are expressly H264/JPEG review aids. No source, render, original pixel or prior capture-receipt mutation.",
    }
    (leaf / "temporal-review-staging-receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps({"status": receipt["status"], "files": len(linked), "logical_bytes": logical_bytes}))


if __name__ == "__main__":
    main()
