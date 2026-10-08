#!/usr/bin/env python3
"""Coordinate six unchanged native recordings after root grants the engine slot.

This scratch orchestration is not a game or capture-fixture input. The actual
capture and analysis tools are bound to the exact supplied production commit.
No engine starts without --exclusive-render-slot. Original evidence is retained.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import time

BASELINE_COMMIT = "86cb1b8ec878b4ae06daba5e6c5a4fa583865dc5"
CLASS_ORDER = ("Arcanist", "Ranger", "Vowkeeper")


def write_json(path, value):
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(json.dumps(value, indent=2, allow_nan=False) + "\n")
    temporary.replace(path)


def journal_progress(directory):
    """Progress only: a journal row can precede PNG receipt by one frame."""
    path = directory / "frames.jsonl"
    if not path.is_file():
        return None
    with path.open("rb") as stream:
        stream.seek(0, 2)
        length = stream.tell()
        stream.seek(max(0, length - 262144))
        lines = stream.read().splitlines()
    for line in reversed(lines):
        try:
            row = json.loads(line)
            return {"journal_frame": row["frame"], "stage": row.get("stage"),
                    "phase": row.get("phase"), "finished": row.get("finished")}
        except (ValueError, KeyError):
            continue
    return None


def run_child(command, cwd, environment, log, progress_dir, label, session, session_path, *, wall_timeout=None):
    started = time.monotonic()
    entry = {"label": label, "command": command, "log": str(log),
             "status": "running", "started_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}
    session["processes"].append(entry)
    write_json(session_path, session)
    print("SESSION START", label, flush=True)
    with log.open("wb") as output:
        child = subprocess.Popen(command, cwd=cwd, env=environment,
                                 stdin=subprocess.DEVNULL, stdout=output, stderr=subprocess.STDOUT)
        entry["pid"] = child.pid
        while True:
            try:
                result = child.wait(timeout=30)
                break
            except subprocess.TimeoutExpired:
                entry["wall_seconds_so_far"] = round(time.monotonic() - started, 3)
                if wall_timeout is not None and time.monotonic() - started >= wall_timeout:
                    child.terminate()
                    try:
                        child.wait(timeout=10)
                    except subprocess.TimeoutExpired:
                        child.kill()
                        child.wait(timeout=10)
                    entry.update(status="failed_timeout", actual_process_exit=child.returncode,
                                 wall_seconds=round(time.monotonic() - started, 3),
                                 wall_timeout_seconds=wall_timeout)
                    write_json(session_path, session)
                    raise RuntimeError(f"{label} exceeded {wall_timeout} seconds; preserved {log}")
                if progress_dir:
                    entry["progress_not_final_evidence"] = journal_progress(progress_dir)
                write_json(session_path, session)
                print("SESSION HEARTBEAT", label, entry["wall_seconds_so_far"],
                      "wall seconds; journal only", entry.get("progress_not_final_evidence"), flush=True)
        entry.update(status="passed" if result == 0 else "failed", actual_process_exit=result,
                     wall_seconds=round(time.monotonic() - started, 3))
        write_json(session_path, session)
    print("SESSION EXIT", label, result, entry["wall_seconds"], "wall seconds", flush=True)
    if result:
        raise RuntimeError(f"{label} failed with actual process exit {result}; preserved {log}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-commit", required=True)
    parser.add_argument("--repo", type=Path, default=Path("/workspace/Emberfall-Ashen-Veil"))
    parser.add_argument("--baseline", type=Path, default=Path("/workspace/scratch/emberfall-quality-057/baseline-056"))
    parser.add_argument("--evidence", type=Path, default=Path("/workspace/scratch/emberfall-quality-057/gameplay"))
    parser.add_argument("--session-dir", type=Path, required=True, help="Fresh scratch orchestration directory")
    parser.add_argument("--godot", default="/workspace/scratch/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64")
    parser.add_argument("--display", default=":108")
    parser.add_argument("--exclusive-render-slot", action="store_true")
    args = parser.parse_args()
    if not args.exclusive_render_slot:
        parser.error("Root must grant the exclusive engine slot first")
    if args.session_dir.exists() and any(args.session_dir.iterdir()):
        parser.error("Use a fresh session directory; historical attempts are never overwritten")
    for name in CLASS_ORDER:
        for side in ("before", "after"):
            path = args.evidence / (side + "-" + name.lower())
            if path.exists() and any(path.iterdir()):
                parser.error("Evidence directory is not fresh: " + str(path))
    args.session_dir.mkdir(parents=True, exist_ok=True)
    sys.path.insert(0, str(args.repo / "tools"))
    from capture_arcanist_quality import digest, runtime_hashes
    from analyze_combat_quality import audit_git_sources

    def inputs(root):
        return runtime_hashes(root, (args.repo / "tools/capture_combat_quality.py",
                                     root / "tests/combat_quality_gameplay_preview.gd",
                                     root / "tests/combat_quality_gameplay_preview.tscn"))

    def verify_sources():
        current = audit_git_sources(args.repo, args.source_commit, inputs(args.repo))
        baseline = audit_git_sources(args.repo, BASELINE_COMMIT, inputs(args.baseline),
                                     fixture_commit=args.source_commit)
        analysis = audit_git_sources(args.repo, args.source_commit,
                                    {"tools/analyze_combat_quality.py": digest(args.repo / "tools/analyze_combat_quality.py")})
        return {"current": current, "baseline": baseline, "analysis": analysis}

    def verify_baseline_export():
        export = json.loads((args.evidence.parent / "baseline-export-receipt.json").read_text())
        overlay = json.loads((args.evidence / "baseline-fixture-overlay-receipt-v2.json").read_text())
        fixture_hashes = {row["path"]: row["fixture_sha256"] for row in overlay["files"]}
        changed = []
        for row in export["files"]:
            actual = digest(args.baseline / row["path"])
            expected = fixture_hashes.get(row["path"], row["sha256"])
            if actual != expected:
                raise RuntimeError("Baseline exported bytes changed: " + row["path"])
            if actual != row["sha256"]:
                changed.append(row["path"])
        if changed != sorted(("tests/arcanist_quality_gameplay_preview.gd", "tests/combat_quality_gameplay_preview.gd")):
            raise RuntimeError("Unexpected baseline fixture overlay paths: " + repr(changed))
        return {"verified_exported_files": len(export["files"]), "changed_capture_fixture_paths": changed,
                "production_overlay": False, "overlay_receipt_sha256": digest(args.evidence / "baseline-fixture-overlay-receipt-v2.json")}

    environment = os.environ.copy()
    environment.update(LP_NUM_THREADS="4", DISPLAY=args.display)
    session_path = args.session_dir / "session-receipt.json"
    session = {"schema": 1, "status": "running", "source_commit": args.source_commit,
               "baseline_commit": BASELINE_COMMIT, "class_order": list(CLASS_ORDER),
               "side_order_per_class": ["before", "after"], "LP_NUM_THREADS": "4",
               "display": args.display, "resolution": [1200, 536], "processes": [],
               "godot_binary_path": str(Path(args.godot).resolve()), "godot_binary_sha256": digest(Path(args.godot)),
               "scratch_orchestrator_sha256": digest(Path(__file__)),
               "scope": "Six full original native chronological recordings and independent comparisons; wall time is not game FPS and this is not a physical Android run."}
    write_json(session_path, session)
    try:
        session["initial_baseline_export_audit"] = verify_baseline_export()
        session["initial_source_audit"] = verify_sources()
        write_json(session_path, session)
        if not (args.baseline / ".godot/imported").is_dir():
            run_child([args.godot, "--headless", "--editor", "--path", str(args.baseline), "--import", "--quit"],
                      args.baseline, environment, args.session_dir / "baseline-import.log", None,
                      "baseline-import", session, session_path, wall_timeout=600)
            log = (args.session_dir / "baseline-import.log").read_text(errors="replace")
            if any(marker in log for marker in ("SCRIPT ERROR", "\nERROR:", "SHADER ERROR")):
                raise RuntimeError("The native baseline import reported an engine error")
            session["post_import_baseline_export_audit"] = verify_baseline_export()
            verify_sources()
        for name in CLASS_ORDER:
            slug = name.lower()
            for side, root in (("before", args.baseline), ("after", args.repo)):
                verify_sources()
                output = args.evidence / (side + "-" + slug)
                command = [sys.executable, str(args.repo / "tools/capture_combat_quality.py"),
                           "--root", str(root), "--output", str(output), "--class", name,
                           "--full", "--bone-detail", "none", "--compress-pcm", "--godot", args.godot,
                           "--display", args.display, "--timeout-seconds", "7200", "--exclusive-render-slot"]
                run_child(command, args.repo, environment, args.session_dir / (side + "-" + slug + ".log"),
                          output, side + "-" + slug, session, session_path)
                receipt = json.loads((output / "receipt.json").read_text())
                if receipt.get("status") != "complete" or receipt.get("llvmpipe_thread_environment") != "4":
                    raise RuntimeError("Recording did not verify a full expedition in the declared renderer environment")
                session["processes"][-1]["capture_receipt_sha256"] = digest(output / "receipt.json")
                session["processes"][-1]["verified_frames"] = receipt["frames"]
                write_json(session_path, session)
            comparison = args.evidence / (slug + "-comparison.json")
            if comparison.exists():
                raise RuntimeError("Comparison output already exists and will not be overwritten: " + str(comparison))
            command = [sys.executable, str(args.repo / "tools/analyze_combat_quality.py"),
                       "--before", str(args.evidence / ("before-" + slug)),
                       "--after", str(args.evidence / ("after-" + slug)), "--output", str(comparison),
                       "--repo", str(args.repo), "--source-commit", args.source_commit,
                       "--before-source-commit", BASELINE_COMMIT,
                       "--before-fixture-source-commit", args.source_commit]
            run_child(command, args.repo, environment, args.session_dir / (slug + "-analysis.log"),
                      None, slug + "-comparison", session, session_path)
            session["processes"][-1]["comparison_sha256"] = digest(comparison)
            write_json(session_path, session)
        session.update(status="six_complete_native_recordings_and_three_verified_full_comparisons",
                       final_source_audit=verify_sources(), final_baseline_export_audit=verify_baseline_export())
        write_json(session_path, session)
        print("SIX FULL CLASS CAPTURES VERIFIED", flush=True)
        return 0
    except (OSError, ValueError, RuntimeError, KeyError, subprocess.SubprocessError) as error:
        session.update(status="failed", error=str(error))
        write_json(session_path, session)
        print("SIX FULL CLASS CAPTURES FAILED:", error, file=sys.stderr, flush=True)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
