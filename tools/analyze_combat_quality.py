#!/usr/bin/env python3
"""Verify a native ordinary prefix or a complete class expedition against its baseline.

Read-only evidence analysis: simulation, camera, sample chronology, independently
scanned native stereo PCM, source immutability and original selected-frame hashes.
It does not infer animation quality, physical device performance or Beta readiness.
"""
from __future__ import annotations

import argparse
from array import array
from collections import Counter
import gzip
import hashlib
import json
import math
from pathlib import Path
import re
import subprocess
import sys

from capture_arcanist_quality import digest, verify_audio_record, verify_finite_state, verify_full_summary, verify_prefix_summary, verify_record, write_json


AUTHORITY_KEYS = ("frame", "simulation_elapsed", "simulation_accumulator", "stage", "phase",
                  "finished", "won", "hero_hp", "pending_attack", "guardian")
FIXTURE_INPUTS = frozenset(("tools/capture_arcanist_quality.py", "tools/capture_combat_quality.py",
                          "tests/arcanist_quality_gameplay_preview.gd", "tests/arcanist_quality_gameplay_preview.tscn",
                          "tests/combat_quality_gameplay_preview.gd", "tests/combat_quality_gameplay_preview.tscn"))


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), allow_nan=False)


def audit_git_sources(repo, commit, inputs, *, fixture_commit=None):
    if not re.fullmatch(r"[0-9a-f]{40}", commit):
        raise ValueError("Use an exact 40-character Git source commit")
    subprocess.run(["git", "cat-file", "-e", commit + "^{commit}"], cwd=repo,
                   check=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    if fixture_commit:
        if not re.fullmatch(r"[0-9a-f]{40}", fixture_commit):
            raise ValueError("Use an exact 40-character disclosed fixture commit")
        subprocess.run(["git", "cat-file", "-e", fixture_commit + "^{commit}"], cwd=repo,
                       check=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    overlays = []
    for relative, captured in sorted(inputs.items()):
        if "\n" in relative or "\r" in relative:
            raise ValueError("Unexpected newline in a captured source path")
        selected_commit = fixture_commit if fixture_commit and relative in FIXTURE_INPUTS else commit
        with subprocess.Popen(["git", "cat-file", "blob", selected_commit + ":" + relative], cwd=repo,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE) as process:
            value = hashlib.sha256()
            for block in iter(lambda: process.stdout.read(65536), b""):
                value.update(block)
            error = process.stderr.read().decode(errors="replace")
            code = process.wait()
        if code or value.hexdigest() != captured:
            raise ValueError("The capture differs from the claimed Git source commit at " + relative
                             + (": " + error[-160:] if code else ""))
        if selected_commit != commit:
            overlays.append({"path": relative, "fixture_commit": selected_commit, "sha256": captured,
                             "scope": "Disclosed capture fixture only; no production source or asset overlay"})
    return {"status": "all_exact_git_blob_bytes_matched", "source_commit": commit,
            "compared_files": len(inputs), "disclosed_overlays": overlays}


def authority(row):
    trace = {key: row.get(key) for key in AUTHORITY_KEYS}
    trace["authoritative_events"] = [event for event in row["events"] if event["type"] != "hero_release"]
    if "ordinary_full_authority" in row:
        trace["ordinary_full_authority"] = row["ordinary_full_authority"]
    return trace


def compare_rows(before, after):
    """Presentation-only release/pose changes must not disguise simulation changes."""
    if len(before) < len(after):
        raise ValueError("The baseline does not contain the entire requested ordinary prefix")
    differences = []
    camera_differences = []
    audio_event_differences = []
    audio_content_differences = []
    acceptance_walltime_differences = []
    before_hash, after_hash = hashlib.sha256(), hashlib.sha256()
    for index, current in enumerate(after):
        original = before[index]
        left, right = authority(original), authority(current)
        before_hash.update((canonical(left) + "\n").encode())
        after_hash.update((canonical(right) + "\n").encode())
        if left != right:
            differences.append(index)
        if original.get("camera") != current.get("camera"):
            camera_differences.append(index)
        if original.get("audio", {}).get("accepted_state_events") != current.get("audio", {}).get("accepted_state_events"):
            audio_event_differences.append(index)
        left_audio = original.get("audio", {}).get("accepted_state_events", [])
        right_audio = current.get("audio", {}).get("accepted_state_events", [])
        # The actual independent processes accept cues at different wall times.
        # Preserve their original events, report raw inequality, and exclude
        # exactly this single non-simulation field for the additional audit.
        cleaned_left = [{key: value for key, value in event.items() if key != "acceptance_wall_msec"} for event in left_audio]
        cleaned_right = [{key: value for key, value in event.items() if key != "acceptance_wall_msec"} for event in right_audio]
        if cleaned_left != cleaned_right:
            audio_content_differences.append(index)
        elif left_audio != right_audio:
            acceptance_walltime_differences.append(index)
    return {"compared_frames": len(after), "authoritative_trace_equal": not differences,
            "before_authority_sha256": before_hash.hexdigest(), "after_authority_sha256": after_hash.hexdigest(),
            "authoritative_difference_frames": differences,
            "camera_transforms_equal": not camera_differences, "camera_difference_frames": camera_differences,
            "accepted_audio_events_equal": not audio_event_differences, "audio_event_difference_frames": audio_event_differences,
            "accepted_audio_content_equal_excluding_acceptance_wall_msec": not audio_content_differences,
            "audio_content_difference_frames": audio_content_differences,
            "walltime_only_audio_difference_frames": acceptance_walltime_differences,
            "excluded_audio_comparison_fields": ["acceptance_wall_msec"],
            "scope": "Actual clocks, HP, pending attacks, stages, guardian and combat events; hero_release and presentation poses are excluded from the authoritative trace."}


def pcm_stream(directory):
    raw = directory / "native-game-audio.f32le"
    if raw.is_file():
        return raw.open("rb"), raw
    compressed = directory / "native-game-audio.f32le.gz"
    if compressed.is_file():
        return gzip.open(compressed, "rb"), compressed
    raise ValueError("The independent native PCM source is absent: " + str(directory))


def scan_pcm(directory, sample_frames, *, require_exact_length):
    """Read real IEEE float32 samples, not the helper's own finite/peak claim."""
    byte_limit = sample_frames * 2 * 4
    digest_value = hashlib.sha256()
    read_bytes = 0
    peak = sum_squares = 0.0
    nonfinite = 0
    stream, path = pcm_stream(directory)
    with stream:
        while read_bytes < byte_limit:
            block = stream.read(min(65536, byte_limit - read_bytes))
            if not block or len(block) % 4:
                raise ValueError("The native PCM ended early or contains a partial float32 sample")
            digest_value.update(block)
            values = array("f")
            values.frombytes(block)
            if sys.byteorder != "little": values.byteswap()
            for value in values:
                if not math.isfinite(value):
                    nonfinite += 1
                else:
                    peak = max(peak, abs(value))
                    sum_squares += value * value
            read_bytes += len(block)
        full_digest = digest_value.copy()
        full_bytes = read_bytes
        while block := stream.read(65536):
            if require_exact_length:
                raise ValueError("The native PCM contains samples beyond the recorded prefix")
            full_digest.update(block)
            full_bytes += len(block)
    return {"sample_frames": sample_frames, "channels": 2, "format": "IEEE float32 little endian",
            "bytes_scanned": read_bytes, "sha256": digest_value.hexdigest(), "peak": peak,
            "rms": math.sqrt(sum_squares / (sample_frames * 2)), "nonfinite_samples": nonfinite,
            "source_file": path.name, "exact_prefix_length_required": require_exact_length,
            "full_source_sha256": full_digest.hexdigest(), "full_source_bytes": full_bytes}


def analyze(before_dir, after_dir):
    receipt = json.loads((after_dir / "receipt.json").read_text())
    baseline_receipt = json.loads((before_dir / "receipt.json").read_text())
    summary = json.loads((after_dir / "capture-summary.json").read_text())
    full = receipt.get("recording_kind") == "ordinary_expedition" and receipt.get("status") == "complete"
    if not full and (receipt.get("status") != "complete_prefix" or receipt.get("recording_kind") != "ordinary_expedition_prefix"):
        raise ValueError("The current capture is neither a verified ordinary prefix nor a completed expedition")
    if baseline_receipt.get("status") != "complete":
        raise ValueError("The baseline is not a verified completed ordinary expedition")
    for directory, evidence in ((before_dir, baseline_receipt), (after_dir, receipt)):
        if not evidence.get("inputs_unchanged") or evidence["input_sha256_before"] != evidence["input_sha256_after"]:
            raise ValueError("Runtime source changed during one of the two captures")
        if digest(directory / "frames.jsonl") != evidence["frame_log_sha256"]:
            raise ValueError("The chronological frame log does not match its original receipt")
        movie = directory / evidence.get("mp4_file", "ordinary-arcanist-complete.mp4")
        if digest(movie) != evidence["mp4_sha256"]:
            raise ValueError("A source MP4 does not match its original receipt")
        if full and any(evidence.get(key) != 0 for key in ("godot_process_exit", "ffmpeg_process_exit", "ffmpeg_full_decode_exit")):
            raise ValueError("The full recording lacks actual successful native process/encoder/decode exits")
    rows = [json.loads(line) for line in (after_dir / "frames.jsonl").read_text().splitlines() if line.strip()]
    old_rows = [json.loads(line) for line in (before_dir / "frames.jsonl").read_text().splitlines() if line.strip()]
    seconds = len(rows) / 30 if full else receipt["prefix_seconds"]
    if full:
        verify_full_summary(summary, len(rows))
        old_summary = json.loads((before_dir / "capture-summary.json").read_text())
        verify_full_summary(old_summary, len(old_rows))
        if len(old_rows) != len(rows):
            raise ValueError("The complete before/after expeditions have different chronological frame counts")
        old_metadata = json.loads((before_dir / "capture-metadata.json").read_text())
        metadata = json.loads((after_dir / "capture-metadata.json").read_text())
        for key in ("character_class", "world_seed", "run_seed", "initial_stats", "initial_equipment", "selected_skill_loadout"):
            if old_metadata.get(key) is None or old_metadata.get(key) != metadata.get(key):
                raise ValueError("The full baseline/current ordinary expedition input differs: " + key)
        for path in FIXTURE_INPUTS & baseline_receipt["input_sha256_before"].keys() & receipt["input_sha256_before"].keys():
            if baseline_receipt["input_sha256_before"][path] != receipt["input_sha256_before"][path]:
                raise ValueError("The disclosed full before/after capture fixtures differ: " + path)
    else:
        verify_prefix_summary(summary, seconds, len(rows))
    previous_clock, sample, rate = 0.0, 0, None
    counts = Counter()
    for frame, row in enumerate(rows):
        verify_finite_state(row)
        previous_clock = verify_record(row, frame, previous_clock)
        if not row["simulation_advanced"] and (not full or not row["finished"]):
            raise ValueError("The ordinary prefix contains a stopped/settling simulation frame")
        sample, rate = verify_audio_record(row, frame, sample, rate)
        counts.update(event["type"] for event in row["events"])
    selected = []
    for original in receipt["selected_frames"]:
        if digest(after_dir / original["file"]) != original["sha256"]:
            raise ValueError("An original selected native PNG was modified")
        selected.append({"file": original["file"], "frame": original["frame"], "sha256": original["sha256"]})
    current_pcm = scan_pcm(after_dir, sample, require_exact_length=True)
    previous_pcm = scan_pcm(before_dir, sample, require_exact_length=full)
    if current_pcm["nonfinite_samples"] or not 0 < current_pcm["peak"] <= 1:
        raise ValueError("Independent native PCM scan found nonfinite, silent or clipped audio")
    if current_pcm["sha256"] != receipt["native_pcm_sha256"] or current_pcm["sha256"] != summary["native_pcm_sha256"]:
        raise ValueError("The independently scanned PCM digest does not match its native capture receipt")
    if previous_pcm["full_source_sha256"] != baseline_receipt["native_pcm_sha256"]:
        raise ValueError("The full baseline native PCM source does not match its original capture receipt")
    comparison = compare_rows(old_rows, rows)
    if not comparison["authoritative_trace_equal"]:
        raise ValueError("The before/after ordinary prefix changed its actual authoritative gameplay trace")
    if full and (not comparison["camera_transforms_equal"]
                 or not comparison["accepted_audio_content_equal_excluding_acceptance_wall_msec"]
                 or current_pcm["sha256"] != previous_pcm["sha256"]):
        raise ValueError("The complete ordinary comparison changed its camera, accepted-cue content or actual PCM")
    return {"schema": 1, "status": "verified_complete_ordinary_expedition" if full else "verified_ordinary_prefix", "recording_seconds": seconds,
            "frames": len(rows), "actual_expedition_finished": summary["simulation_finished"], "actual_won": summary["won"],
            "chronological_simulation_verified": True, "chronological_native_audio_verified": True,
            "recorded_native_state_finite": True,
            "sample_rate": rate, "event_counts": dict(counts), "comparison": comparison,
            "native_pcm": current_pcm, "baseline_prefix_pcm": previous_pcm,
            "native_pcm_prefix_bitwise_equal": current_pcm["sha256"] == previous_pcm["sha256"],
            "selected_original_pngs": selected, "source_inputs_unchanged": True,
            "source_sha256": receipt["input_sha256_before"],
            "recording_kind": receipt["recording_kind"],
            "character_class": receipt.get("character_class", "Arcanist"),
            "actual_guardian_seen": summary.get("guardian_seen", False),
            "actual_guardian_warning_seen": summary.get("guardian_warning_seen", False),
            "actual_recovered_loot": summary.get("recovered_loot", []),
            "analysis_tool_sha256": digest(Path(__file__)),
            "scope": "Read-only ordinary expedition recording verification and comparison. Native PCM is accepted-cue fixed-step audio, not physical loopback; exported wall time is not game FPS. No visual acceptance or release claim."}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--before", type=Path, required=True,
                        help="Original verified full native expedition evidence directory")
    parser.add_argument("--after", type=Path, required=True,
                        help="Verified current complete_prefix or completed full evidence directory")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--source-commit", help="Optional exact current source commit; require every captured input to match")
    parser.add_argument("--before-source-commit", help="Optional exact baseline source commit; require every captured input to match")
    parser.add_argument("--before-fixture-source-commit", help="Explicit baseline capture-only overlay commit; production files still match --before-source-commit")
    args = parser.parse_args()
    try:
        if args.before_fixture_source_commit and not args.before_source_commit:
            raise ValueError("A disclosed baseline fixture commit requires its exact production baseline commit")
        result = analyze(args.before.resolve(), args.after.resolve())
        if args.source_commit:
            result["current_git_source_audit"] = audit_git_sources(args.repo.resolve(), args.source_commit, result["source_sha256"])
        if args.before_source_commit:
            baseline = json.loads((args.before / "receipt.json").read_text())
            result["baseline_git_source_audit"] = audit_git_sources(args.repo.resolve(), args.before_source_commit,
                                                                    baseline["input_sha256_before"], fixture_commit=args.before_fixture_source_commit)
        write_json(args.output, result)
        print("COMBAT_FULL_ANALYSIS_VERIFIED" if result["recording_kind"] == "ordinary_expedition" else "COMBAT_PREFIX_ANALYSIS_VERIFIED", result["frames"], "frames;",
              result["native_pcm"]["sample_frames"], "native stereo sample frames")
        return 0
    except (OSError, ValueError, RuntimeError, KeyError, subprocess.SubprocessError) as error:
        print("COMBAT_PREFIX_ANALYSIS_FAILED:", error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
